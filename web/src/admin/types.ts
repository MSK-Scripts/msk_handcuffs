import type { Theme } from '../lib/theme'

// A command / sound value may be `false` to disable it.
export type OptString = string | false

export interface TargetOptions {
  cuff: boolean
  hardcuff: boolean
  uncuff: boolean
  ankletracker: boolean
  headbag: boolean
  tape: boolean
  drag: boolean
  putInCar: boolean
  putOutOfCar: boolean
}

export interface TargetDef {
  enable: boolean
  system: string
  undragHotkey: string
  options: TargetOptions
}

export interface CmdDef {
  enable: boolean
  command: string
  item: string
  jobs: Record<string, string>
}

export interface Commands {
  cuff: CmdDef
  hardcuff: CmdDef
  uncuff: CmdDef
}

export interface AnkleBlip {
  id: number
  color: number
  scale: number
  prefix: string
}

export interface AnkleTrackerDef {
  enable: boolean
  refreshTime: number
  item: string
  removeItem: string
  consumeRemoveItem: boolean
  command: OptString
  blip: AnkleBlip
  jobs: string[]
}

export interface BagTapeDef {
  enable: boolean
  item: string
  removeItem: string
  needItemToRemove: boolean
  consumeRemoveItem: boolean
  command: OptString
}

export interface CheckOnLoaded {
  cuff: boolean
  hardcuff: boolean
  ankleTracker: boolean
  headbag: boolean
  tape: boolean
}

export interface PlaySound {
  enable: boolean
  cuff: OptString
  hardcuff: OptString
  uncuff: OptString
  ankleTracker: OptString
  headBag: OptString
  tape: OptString
}

export interface TimerDef {
  enable: boolean
  time: number
}

export interface VoiceDef {
  enable: boolean
  voice: string
}

export interface AdminCmdSimple {
  enable: boolean
  command: string
}

export interface AdminCommands {
  cuff: { enable: boolean; command: string; playAnimation: boolean }
  hardcuff: AdminCmdSimple
  uncuff: AdminCmdSimple
  ankleTracker: AdminCmdSimple
  headbag: AdminCmdSimple
  tape: AdminCmdSimple
}

export interface ItemSet {
  cuffItem: string
  hardcuffItem: string
  uncuffItem: string
  enableAnkletracker: boolean
  enableHeadbag: boolean
  enableTape: boolean
}

export interface RestrictItems {
  enable: boolean
  defaultItems: ItemSet
  jobItems: Record<string, ItemSet>
}

export interface SettingsPayload {
  Locale: string
  Debug: boolean
  VersionChecker: boolean
  MaxDistance: number
  DiscordLog: boolean
  DiscordWebhook: string
  botColor: string
  botName: string
  botAvatar: string
  Target: TargetDef
  cuffItems: string[]
  hardcuffItems: string[]
  uncuffItems: string[]
  ItemSettings: Record<string, string[]>
  GiveCuffItemBack: Record<string, boolean>
  consumeUncuffItem: boolean
  RestrictItems: RestrictItems
  Commands: Commands
  AnkleTracker: AnkleTrackerDef
  HeadBag: BagTapeDef
  Tape: BagTapeDef
  UncuffOnPlayerDied: boolean
  checkOnPlayerLoaded: CheckOnLoaded
  playSound: PlaySound
  Timer: TimerDef
  EnableProps: boolean
  Voice: VoiceDef
  AdminGroups: string[]
  AdminCommands: AdminCommands
  adminCommand: string
  BrandTag: string
  Theme: Theme
  dashboardGroups: string[]
}

export interface PlayerStatus {
  cuffed: boolean
  adminCuffed: boolean
  hardcuffed: boolean
  ankletracker: boolean
  headbag: boolean
  tape: boolean
}

export interface PlayerEntry {
  serverId: number
  identifier: string
  name: string
  job: string
  status: PlayerStatus
}

export interface JobInfo {
  name: string
  label: string
}

export interface GroupDef {
  name: string
  protected: boolean
  perms: Record<string, boolean>
}

export interface BootstrapMeta {
  locales: string[]
  targetSystems: string[]
  voiceScripts: string[]
}

export interface AdminBootstrap {
  locale: string
  perms: Record<string, boolean>
  permKeys: string[]
  settings: SettingsPayload
  groups: GroupDef[]
  suggestedGroups: string[]
  jobsList: JobInfo[]
  players: PlayerEntry[]
  meta: BootstrapMeta
}

export interface CallResult {
  ok: boolean
  err?: string
  data?: AdminBootstrap
  players?: PlayerEntry[]
  valid?: boolean
  exists?: boolean
  blacklisted?: boolean
}
