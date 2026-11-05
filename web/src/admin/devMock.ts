// Browser-only dev mock. Loaded exclusively via `import.meta.env.DEV` in main.tsx
// so it never ships in the production build. Answers fetchNui dev-calls and posts
// an initial openAdmin message so the dashboard renders in `npm run dev`.
import { DEFAULT_THEME } from '../lib/theme'
import type { AdminBootstrap, PlayerEntry, SettingsPayload } from './types'

const allPerms: Record<string, boolean> = {
  'players.view': true, 'players.cuff': true, 'players.uncuff': true,
  'players.tracker': true, 'players.headbag': true, 'players.tape': true,
  'items.manage': true, 'restrictions.manage': true,
  'settings.manage': true, 'permissions.manage': true,
}

const players: PlayerEntry[] = [
  { serverId: 1, identifier: 'char1:abc', name: 'John Doe', job: 'police', status: { cuffed: true, adminCuffed: false, hardcuffed: false, ankletracker: true, headbag: false, tape: false } },
  { serverId: 2, identifier: 'char1:def', name: 'Jane Roe', job: 'unemployed', status: { cuffed: false, adminCuffed: false, hardcuffed: false, ankletracker: false, headbag: false, tape: false } },
]

const settings: SettingsPayload = {
  Locale: 'de',
  Debug: false,
  VersionChecker: true,
  MaxDistance: 3.0,
  DiscordLog: true,
  DiscordWebhook: '',
  botColor: '6205745',
  botName: 'MSK Scripts',
  botAvatar: 'https://i.imgur.com/PizJGsh.png',
  Target: {
    enable: true,
    system: 'auto',
    undragHotkey: 'X',
    options: { cuff: true, hardcuff: true, uncuff: true, ankletracker: true, headbag: true, tape: true, drag: true, putInCar: true, putOutOfCar: true },
  },
  cuffItems: ['cuffs', 'cable_ties'],
  hardcuffItems: ['hardcuff'],
  uncuffItems: ['cuff_keys', 'scissors'],
  ItemSettings: { cuffs: ['cuff_keys'], cable_ties: ['scissors'] },
  GiveCuffItemBack: { cuffs: true, cable_ties: false, hardcuff: true, ankletracker: true, headbag: true, tape: true },
  consumeUncuffItem: false,
  RestrictItems: {
    enable: true,
    defaultItems: { cuffItem: 'cable_ties', hardcuffItem: 'hardcuff', uncuffItem: 'scissors', enableAnkletracker: false, enableHeadbag: true, enableTape: true },
    jobItems: {
      police: { cuffItem: 'cuffs', hardcuffItem: 'hardcuff', uncuffItem: 'cuff_keys', enableAnkletracker: true, enableHeadbag: true, enableTape: true },
    },
  },
  Commands: {
    cuff: { enable: true, command: 'cuff', item: 'cable_ties', jobs: { police: 'cuffs', doj: 'cuffs' } },
    hardcuff: { enable: true, command: 'hardcuff', item: 'hardcuff', jobs: { police: 'hardcuff' } },
    uncuff: { enable: true, command: 'uncuff', item: 'scissors', jobs: { police: 'cuff_keys' } },
  },
  AnkleTracker: {
    enable: true, refreshTime: 5.0, item: 'ankletracker', removeItem: 'ankletracker_key', consumeRemoveItem: false, command: 'ankletracker',
    blip: { id: 1, color: 15, scale: 0.8, prefix: 'Track' }, jobs: ['police', 'fib', 'sheriff', 'doj'],
  },
  HeadBag: { enable: true, item: 'headbag', removeItem: 'headbag_key', needItemToRemove: false, consumeRemoveItem: false, command: 'headbag' },
  Tape: { enable: true, item: 'tape', removeItem: 'tape_key', needItemToRemove: false, consumeRemoveItem: false, command: 'tape' },
  UncuffOnPlayerDied: true,
  checkOnPlayerLoaded: { cuff: true, hardcuff: false, ankleTracker: true, headbag: false, tape: false },
  playSound: { enable: true, cuff: 'cuff.ogg', hardcuff: 'cuff.ogg', uncuff: 'uncuff.ogg', ankleTracker: 'cuff.ogg', headBag: false, tape: false },
  Timer: { enable: true, time: 30 },
  EnableProps: true,
  Voice: { enable: false, voice: 'pma' },
  AdminGroups: ['superadmin', 'admin'],
  AdminCommands: {
    cuff: { enable: true, command: 'adcuff', playAnimation: false },
    hardcuff: { enable: true, command: 'adhardcuff' },
    uncuff: { enable: true, command: 'aduncuff' },
    ankleTracker: { enable: true, command: 'adankletracker' },
    headbag: { enable: true, command: 'adheadbag' },
    tape: { enable: true, command: 'adtape' },
  },
  adminCommand: 'handcuffadmin',
  BrandTag: 'MSK',
  Theme: DEFAULT_THEME,
  dashboardGroups: ['mod'],
}

let bootstrap: AdminBootstrap = {
  locale: 'de',
  perms: allPerms,
  permKeys: Object.keys(allPerms),
  settings,
  groups: [
    { name: 'admin', protected: true, perms: allPerms },
    { name: 'mod', protected: false, perms: { 'players.view': true } },
  ],
  suggestedGroups: ['admin', 'mod', 'dev'],
  jobsList: [
    { name: 'police', label: 'Police' },
    { name: 'ambulance', label: 'EMS' },
    { name: 'doj', label: 'DOJ' },
  ],
  players,
  meta: { locales: ['de', 'en', 'hu'], targetSystems: ['auto', 'ox_target', 'qb-target'], voiceScripts: ['pma', 'salty'] },
}

window.addEventListener('nui:dev-call', (e: Event) => {
  const detail = (e as CustomEvent).detail as { id: string; endpoint: string; data: unknown }
  const ep = detail.endpoint
  let result: unknown = { ok: true, data: bootstrap }

  if (ep === 'admin:players:list') result = { ok: true, players: bootstrap.players }
  else if (ep === 'admin:player:action') result = { ok: true, players: bootstrap.players }
  else if (ep === 'admin:perms:validateGroup') result = { ok: true, valid: true, exists: false }
  else if (ep === 'admin:close') result = 'ok'
  else if (ep === 'admin:settings:save') {
    const patch = (detail.data as { settings?: Partial<SettingsPayload> } | undefined)?.settings
    if (patch && typeof patch === 'object') {
      const merged = { ...bootstrap.settings, ...patch }
      bootstrap = { ...bootstrap, settings: merged, locale: typeof patch.Locale === 'string' ? patch.Locale : bootstrap.locale }
    }
    result = { ok: true, data: bootstrap }
  } else if (ep === 'admin:items:save') {
    const items = (detail.data as { items?: Partial<SettingsPayload> } | undefined)?.items
    if (items && typeof items === 'object') bootstrap = { ...bootstrap, settings: { ...bootstrap.settings, ...items } }
    result = { ok: true, data: bootstrap }
  } else if (ep === 'admin:restrictions:save') {
    const restrictions = (detail.data as { restrictions?: SettingsPayload['RestrictItems'] } | undefined)?.restrictions
    if (restrictions) bootstrap = { ...bootstrap, settings: { ...bootstrap.settings, RestrictItems: restrictions } }
    result = { ok: true, data: bootstrap }
  }

  window.dispatchEvent(new CustomEvent('nui:dev-reply', { detail: { id: detail.id, result } }))
})

window.setTimeout(() => {
  window.postMessage({ action: 'openAdmin', data: bootstrap }, '*')
}, 100)
