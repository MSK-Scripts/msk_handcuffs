# Changelogs

## v3.1.1

### Requires msk_core 4.1.0

Uses the table forms that msk_core 4.1.0 introduced, so the deprecation warnings in the server console are gone. The notifications are sent as a table, which an older msk_core takes as the title. Update msk_core along with this script.

### Added

- **The msk_core version is checked on start.** `MSK.Check.Dependency('msk_core', '4.1.0', true)` logs an error in the server console when msk_core is older, instead of leaving you to wonder why the notifications look wrong. *(server/versionchecker.lua)*

### Changed

- **`Config.Notification` passes a table to `MSK.Notification`.** The form with title, message, type and duration is deprecated since msk_core 4.1.0 and logs a warning once per resource. If you keep your own config, change the two `MSK.Notification` lines the same way. Leaving them works too, the old form is still accepted for now. *(config/static.lua)*

- The escort hint uses the table form of `MSK.TextUI.Show`. *(client/main.lua)*

### Changed files

```text
fxmanifest.lua
config/static.lua
client/main.lua
server/versionchecker.lua
```

## v3.1.0

### Requires msk_core 4.0.0

This release reads the player and the job list through the rewritten bridge. On
msk_core 3.x the group lookup returns nothing and the job dropdown stays empty.
Update msk_core along with this script.

### Security

- **`msk_core:playerLogout` was registered as a net event on the server.** The
  event is server-local, so registering it as a net event let any client fire it
  with an arbitrary player id, and here that means clearing somebody else's
  handcuff state. It is an `AddEventHandler` now.

### Fixed

- **The logout handler had never run once.** Nothing in msk_core 3.x ever
  triggered `msk_core:playerLogout`, so a character switch left the handcuff
  state behind. Since msk_core 4.0.0 the event actually fires. A disconnect was
  always covered by `playerDropped` and is unaffected.

- **On Qbox every player counted as unemployed** in the client-side pre-checks.
  The job lookup covered ESX and QBCore only. It went through the framework
  directly because `MSK.Bridge` resolved to a function in a consumer resource and
  could not be read; `MSK.GetPlayerJob()` answers in one shape on all three now.

- **The job dropdown in the dashboard stayed empty on Qbox**, for the same
  reason. `MSK.GetJobs()` covers ESX, QBCore and Qbox.

- **The framework group was only ever resolved on ESX.** It went through
  `xPlayer.getGroup()`, a method QBCore and Qbox do not have, so an admin without
  the matching `add_principal` line was refused there. `player.group` is a plain
  string on all three frameworks since msk_core 4.0.0.

- **The QBCore-only fallback ran on every framework.** `GetQbPermission` starts
  with a check that leaves the function unless QBCore is running, and that check
  could never pass, because reading `MSK.Bridge.Framework` raised
  `attempt to index a function value`. msk_core 4.0.0 makes `MSK.Bridge` a real
  table.

### Changed

- **The client restore listens to one event instead of three.**
  `esx:playerLoaded` and `QBCore:Client:OnPlayerLoaded` are gone. They were a
  workaround for msk_core 3.x, where `msk_core:playerLoaded` never fired, and
  they also triggered the restore up to three times per spawn.

### Changed files

```text
fxmanifest.lua
client/main.lua
client/actions.lua
server/main.lua
server/admin/api.lua
server/admin/permissions.lua
```

## v3.0.1

### Fixed

- **Your team could not open the admin dashboard, even though the group was set in your `server.cfg`.** Two things were stacked here. First, FiveM keeps principals and ace objects apart: a line like `add_principal identifier.license:xxx group.admin` only makes that player a member of the group, it does not create the ace object of the same name that the check was looking for. Unless someone had also written `add_ace group.admin group.admin allow` by hand, the check came back empty. Second, the frameworks do not even agree on how a group principal is named. ESX uses `group.admin`, QBCore uses `qbcore.admin`, and that is not something you can configure away, it is what `/addpermission` and `QBCore.Functions.AddPermission` write. QBCore also only ever links `qbcore.god` to `group.admin`, so anyone below god level was a member of no `group.*` principal at all. On ESX this often stayed invisible because the group from the `users` table caught it, and that fallback does not exist on QBCore. The script now registers its own ace object per group on start and points both spellings at it, for `admin`, for every group in `Config.dashboardGroups` and for every group in the permission matrix. A plain `add_principal ... group.mod` and a `/addpermission 1 mod` both get you in now, and groups you add on the Permissions tab are covered right away without a restart.
- **Checking a group name on the Permissions tab reported "not found" for brand new groups.** The check ran before the group existed as an ace object, so it could never find anyone in it. The group is registered first now.

- **`Access denied for command add_ace` spam on every server start.** FiveM checks
  `add_ace` against the resource that runs it, and no resource holds that right by
  default, so the ace objects were never actually created. Every attempt was refused
  and only printed an error. On ESX this went unnoticed because the framework group
  caught it. The aces are registered through msk_core now, which is the one resource
  your server.cfg already grants that right, and the script checks up front whether it
  is allowed instead of spamming the console.
  *(server/admin/permissions.lua)*

### Requires msk_core 3.3.0

This release uses `MSK.AddRawAce` and `MSK.CanAddAce`, both added in msk_core 3.3.0.
Update msk_core along with this script, and make sure your server.cfg has the msk_core
ace lines. They are the ones the msk_core documentation has always listed and they
cover every MSK script at once:

```cfg
add_ace resource.msk_core command.add_ace allow
add_ace resource.msk_core command.remove_ace allow
add_ace resource.msk_core command.add_principal allow
add_ace resource.msk_core command.remove_principal allow
```

If they are missing nothing breaks, the script says so on start and group access falls
back to your framework group.

There is nothing to rebuild and no database change. Replace the resource files and restart it.

### Changed files

- `fxmanifest.lua` (version bump)
- `server/admin/permissions.lua` (own ace object per group, both principal spellings, QBCore permission fallback)
- `server/admin/boot.lua` (registers the ace objects on start)
- `server/admin/api.lua` (covers groups added or changed while the server is running)

## v3.0.0

This is a big one. Handcuffs was rebuilt from the ground up. It runs on QBCore now as well as ESX, it stores everything in MySQL, it got a real target menu, and it comes with its own in-game admin dashboard. Most of the config moves into the database, so you can manage everything while the server is running.

### New

- **QBCore support.** Next to ESX Legacy the script now runs on QBCore. msk_core detects the framework on its own, you don't set anything.
- **Target menu.** In v2 `Config.Target` only registered the undrag key, there were no target options at all. You now get a real target integration for **ox_target** (recommended) and **qb-target**: cuff, hardcuff, uncuff, ankletracker, headbag, tape, drag, put in car and put out of car, each one switchable in `Config.Target.options`. `Config.Target.system` is set to `auto` by default, which picks ox_target when it is running and falls back to qb-target. The entries are translated into the dashboard language and the label follows the current state, so the same option reads "Put on headbag" or "Remove headbag" depending on what is going on. Change the language in the dashboard and the text updates live.
- **Admin dashboard.** Type `/handcuffadmin` in-game to open it. The Players tab lists everyone online with their current status and lets you cuff, hardcuff and uncuff them and toggle the ankletracker, headbag and tape with one click. On top of that there are tabs for your items, the job restrictions, all the settings and who is allowed in. You can rename the command with `Config.adminCommand`.
- **Permission system.** You can give your team access to the dashboard without handing them everything. The rights are split per action, so you can let a moderator cuff and uncuff people without also giving them the settings. `group.admin` can always do it all and `group.user` can never get in. You manage the groups from the Permissions tab, and `Config.dashboardGroups` decides which groups may open the dashboard at all.
- **Theme editor.** You can recolor the dashboard live from the Settings tab.
- **Discord webhook in the dashboard.** The webhook is a normal setting now, so you can paste it in from the Settings tab instead of opening a file.
- **No item needed to remove (optional).** New toggles for the headbag and the tape. By default you no longer need an item to take them off. Turn the toggle on if you want a remove item to be required again.
- **Keep the remove items (optional).** New toggles so the item you use to remove something is not taken out of the inventory. This covers every remove item now, the ankletracker key, the headbag key, the tape key and the uncuff item (cuff_keys / scissors). Off by default, so keys stay reusable.
- **Escort hint.** While you drag a cuffed person around, a small TextUI tells you which key lets them go again. It shows the key you actually have bound, so if you rebind the undrag key in the FiveM settings the hint follows along. Translated into every language.
- **luxu_admin support.** luxu_admin v2 keeps its staff groups to itself instead of registering them as ACE principals, so the dashboard could not see them. It now asks luxu_admin directly. You configure it in `config/static.lua` under `Config.LuxuAdmin`: turn it on or leave it on auto, rename the resource, require the staff member to be on duty, and map luxu_admin group names onto your dashboard groups.

### Changed

- **MySQL instead of database.json.** The cuff status, the ankletracker and everything else now live in a `msk_handcuffs` table through oxmysql. You do not import an `.sql` file, the table is created on the first start. If you still have an old `database.json` lying around it gets imported once, automatically, and the original is kept as a backup.
- **Status is readable through statebags.** Every status sits in a replicated statebag, so any other resource can read whether someone is cuffed without asking through a callback. `Config.MaxDistance` is new and every action is measured against it on the server.
- **Everything runs off the database now.** The config is imported once on the first start, and after that the database is the source of truth and you edit things from the dashboard. Two tables are created automatically for this: `msk_handcuffs_settings` and `msk_handcuffs_permissions`. Your existing `msk_handcuffs` table with the cuff status stays exactly as it is.
- **Config was split into two files.** `config/settings.lua` holds all the values you can also change in the dashboard, and `config/static.lua` holds the code parts like the notification, the voice and mute handling, the control blacklist and the prop list.
- **New interface.** The headbag blackscreen and the cuff sounds now run through a rebuilt interface that shares one page with the dashboard. Nothing changes for the player.
- **The Discord webhook moved.** It used to sit in `server/discord.lua` and now lives in the config and the dashboard.
- **Default items always work.** With `Config.RestrictItems` on, the default items and options are always usable no matter the job, and the job just adds its own on top.
- **The right key for the right cuffs.** Uncuffing only works with the item that matches how the person was cuffed. Cable ties open with scissors, handcuffs open with the cuff keys, nothing else.
- **Clearer messages.** When you are missing an item, the notification now names the item's in-game label instead of the internal item name.
- **Items register without a restart.** Items you add or change in the dashboard become usable right away, no server restart needed, on ESX, QBCore, ox_inventory and jaksam_inventory.

### Security

- The whole script is server-sided. The client only asks and the server decides everything: the distance between the two players, whether you really carry the right item, your job and the current status. Players can no longer set their own cuff status.
- The old trick where a cuffed player could free themselves is gone. The auto-uncuff timer and the uncuff on death both run on the server now.

### Breaking

- `config.lua` is gone and replaced by the `config/` folder. Please give your config a quick look after updating and move any custom values over to `config/settings.lua`, or to `config/static.lua` for the code parts like the props and the mute function.
- After the first start the dashboard and the database are in charge. If you change a value in the file later, it will not do anything unless you change it in the dashboard as well.
- oxmysql is a requirement now.
- Some exports and events were renamed, and the self-cuff exports (`Cuff`, `Hardcuff`, `Uncuff`) and the admin exports were removed. If another resource hooks into Handcuffs, read the migration page in the documentation before you update.

### Changed files

This release is a full rewrite, so replace the entire resource.

New: `config/settings.lua`, `config/static.lua`, `shared/admin_perms.lua`, `shared/utils.lua`, `client/actions.lua`, `client/ankletracker.lua`, `client/props.lua`, `client/admin/` (main, nui, sync), `server/database.lua`, `server/discord.lua`, `server/versionchecker.lua`, `server/admin/` (store, permissions, seed, api, command, boot) and the React NUI in `web/`, built into `html/`.

Gone: `config.lua`, `database.json`, `client/functions.lua`, `client/encrypted.lua`, `server/functions.lua`, `server/encrypted.lua`, `server/discordlog.lua`, `html/script.js` and `html/style.css`.

Rewritten: `fxmanifest.lua`, `client/main.lua`, `client/target.lua`, `server/main.lua`, `server/commands.lua`, `translation.lua` and `html/index.html`.
