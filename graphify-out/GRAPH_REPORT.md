# Graph Report - msk_handcuffs  (2026-08-01)

## Corpus Check
- 47 files · ~89,479 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 476 nodes · 829 edges · 36 communities (35 shown, 1 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 66 edges (avg confidence: 0.75)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f3df9c40`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Admin Dashboard UI Tabs
- Server Cuff State & Persistence
- Web Build Dependencies
- Client Actions & Target Defs
- Admin API Input Sanitization
- Client Restraint Props & Threads
- Restraint Items & Player Actions
- TypeScript Compiler Config
- Admin Permissions & Seeding
- NUI Theme & Dev Mocks
- v3.0.0 Server Authority Rewrite
- Target Integration & Escort
- NUI Message Bridge
- Config Split & DB Truth
- Dashboard Access Control
- Framework & Inventory Bridges
- MySQL Migration & Versioning
- Discord Webhook Logging
- Ankle Tracker Blips
- Admin Settings Store
- Job Item Restrictions
- v3.0.1

## God Nodes (most connected - your core abstractions)
1. `v3.0.0` - 31 edges
2. `buildDefs()` - 18 edges
3. `compilerOptions` - 16 edges
4. `In-game admin dashboard` - 15 edges
5. `AdminApi.SanitizeSettings()` - 14 edges
6. `tbl()` - 13 edges
7. `T()` - 12 edges
8. `errText()` - 11 edges
9. `Actions.Uncuff()` - 10 edges
10. `Config.Target.options` - 10 edges

## Surprising Connections (you probably didn't know these)
- `applyTape()` --calls--> `T()`  [INFERRED]
  client/main.lua → shared/utils.lua
- `removeTape()` --calls--> `T()`  [INFERRED]
  client/main.lua → shared/utils.lua
- `addTargets()` --calls--> `logging()`  [INFERRED]
  client/target.lua → shared/utils.lua
- `AdminCommand.Register()` --calls--> `T()`  [INFERRED]
  server/admin/command.lua → shared/utils.lua
- `validate()` --calls--> `T()`  [INFERRED]
  server/main.lua → shared/utils.lua

## Import Cycles
- None detected.

## Communities (36 total, 1 thin omitted)

### Community 0 - "Admin Dashboard UI Tabs"
Cohesion: 0.06
Nodes (65): AdminApp(), TabId, AdminLocale, AdminStrings, de, en, ERR_KEYS, errText() (+57 more)

### Community 1 - "Server Cuff State & Persistence"
Cohesion: 0.09
Nodes (38): AdminApi.OnlinePlayers(), Database.Ensure(), Database.Save(), isEmpty(), loadAll(), rowToState(), activateTracker(), applyCuff() (+30 more)

### Community 2 - "Web Build Dependencies"
Cohesion: 0.05
Nodes (36): autoprefixer, @fontsource/open-sans, @fontsource/work-sans, lucide-react, postcss, react, react-dom, tailwindcss (+28 more)

### Community 3 - "Client Actions & Target Defs"
Cohesion: 0.15
Nodes (32): Actions.Ankletracker(), Actions.Cuff(), Actions.Drag(), Actions.Hardcuff(), Actions.Headbag(), Actions.PutInCar(), Actions.PutOutOfCar(), Actions.Tape() (+24 more)

### Community 4 - "Admin API Input Sanitization"
Cohesion: 0.13
Nodes (29): AdminApi.Broadcast(), AdminApi.BuildBootstrap(), AdminApi.JobsList(), AdminApi.SanitizeItems(), AdminApi.SanitizeRestrictions(), AdminApi.SanitizeSettings(), AdminApi.SettingsPayload(), boolKeyMap() (+21 more)

### Community 5 - "Client Restraint Props & Threads"
Cohesion: 0.11
Nodes (26): applyAnkletracker(), applyCuff(), applyHeadbag(), applyTape(), dragThread(), isHandcuffed(), isHardcuffed(), removeAnkletracker() (+18 more)

### Community 6 - "Restraint Items & Player Actions"
Cohesion: 0.21
Nodes (14): Config.Target.options, Cuff, Hardcuff, Headbag, Put in car, Put out of car, Tape, Uncuff (+6 more)

### Community 7 - "TypeScript Compiler Config"
Cohesion: 0.09
Nodes (21): DOM, DOM.Iterable, ES2020, src, compilerOptions, allowImportingTsExtensions, isolatedModules, jsx (+13 more)

### Community 8 - "Admin Permissions & Seeding"
Cohesion: 0.15
Nodes (18): AdminApi.GroupsArray(), AdminCommand.Register(), AdminPerms.CanOpen(), AdminPerms.EnsureAce(), AdminPerms.EnsureAces(), AdminPerms.GetFrameworkGroup(), AdminPerms.GetLuxuGroup(), AdminPerms.GetPlayerPerms() (+10 more)

### Community 9 - "NUI Theme & Dev Mocks"
Cohesion: 0.18
Nodes (14): allPerms, bootstrap, players, settings, PlayerEntry, applyTheme(), clamp(), DEFAULT_THEME (+6 more)

### Community 10 - "v3.0.0 Server Authority Rewrite"
Cohesion: 0.12
Nodes (17): Breaking, Changed, Changed files, Changelogs, New, Security, v3.0.0, Migration page (documentation) (+9 more)

### Community 11 - "Target Integration & Escort"
Cohesion: 0.18
Nodes (13): Config.Target, Config.Target.system, Drag / escort, Settings tab, Discord webhook setting, Escort hint (TextUI), Live language switching, Target menu integration (+5 more)

### Community 12 - "NUI Message Bridge"
Cohesion: 0.23
Nodes (9): AdminBootstrap, App(), BlackscreenMessage, NuiMessage, OpenAdminMessage, PlaySoundMessage, fetchNui(), isBrowser() (+1 more)

### Community 13 - "Config Split & DB Truth"
Cohesion: 0.17
Nodes (12): Config.LuxuAdmin, File config becomes inert after first start, Config split into settings and static, Database as source of truth, Item label in missing-item notification, luxu_admin support, config.lua (removed), config/settings.lua (+4 more)

### Community 14 - "Dashboard Access Control"
Cohesion: 0.18
Nodes (12): Config.adminCommand, Config.dashboardGroups, Admin exports (removed), shared/admin_perms.lua, client/admin/ (main, nui, sync), /handcuffadmin, Permissions tab, In-game admin dashboard (+4 more)

### Community 15 - "Framework & Inventory Bridges"
Cohesion: 0.32
Nodes (8): Items tab, ESX Legacy, Items register without a restart, QBCore support, jaksam_inventory, msk_core, ox_inventory, QBCore

### Community 16 - "MySQL Migration & Versioning"
Cohesion: 0.17
Nodes (13): Ankletracker, Automatic database.json import, Keep the remove items (optional), MySQL storage instead of database.json, database.json (removed), Ankletracker key, cuff_keys, scissors (+5 more)

### Community 17 - "Discord Webhook Logging"
Cohesion: 0.60
Nodes (5): DiscordLog.Action(), DiscordLog.AnkleTracker(), DiscordLog.Headbag(), DiscordLog.Tape(), send()

### Community 19 - "Admin Settings Store"
Cohesion: 0.80
Nodes (4): AdminStore.LoadAll(), AdminStore.LoadPermissions(), AdminStore.LoadSettings(), jdecode()

### Community 20 - "Job Item Restrictions"
Cohesion: 0.18
Nodes (11): Config.MaxDistance, Config.RestrictItems, Jobs tab (job restrictions), Cuff (removed export), Server-side auto-uncuff timer, Default items always work, Self-free exploit removed, Fully server-sided authority (+3 more)

### Community 35 - "v3.0.1"
Cohesion: 0.67
Nodes (3): Changed files, Fixed, v3.0.1

## Knowledge Gaps
- **110 isolated node(s):** `name`, `private`, `version`, `type`, `dev` (+105 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `T()` connect `Client Actions & Target Defs` to `Admin Permissions & Seeding`, `Server Cuff State & Persistence`, `Client Restraint Props & Threads`?**
  _High betweenness centrality (0.072) - this node is a cross-community bridge._
- **Why does `AdminCommand.Register()` connect `Admin Permissions & Seeding` to `Client Actions & Target Defs`, `Admin API Input Sanitization`?**
  _High betweenness centrality (0.039) - this node is a cross-community bridge._
- **Why does `AdminApi.BuildBootstrap()` connect `Admin API Input Sanitization` to `Admin Permissions & Seeding`, `Server Cuff State & Persistence`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **Are the 10 inferred relationships involving `buildDefs()` (e.g. with `Actions.Ankletracker()` and `Actions.Cuff()`) actually correct?**
  _`buildDefs()` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `name`, `private`, `version` to the rest of the system?**
  _110 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Admin Dashboard UI Tabs` be split into smaller, more focused modules?**
  _Cohesion score 0.05561105561105561 - nodes in this community are weakly interconnected._
- **Should `Server Cuff State & Persistence` be split into smaller, more focused modules?**
  _Cohesion score 0.09082125603864734 - nodes in this community are weakly interconnected._