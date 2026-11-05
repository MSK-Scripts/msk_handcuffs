import { useState } from 'react'
import { Plus, Trash2 } from 'lucide-react'
import type { AdminStrings } from './i18n'
import { errText } from './i18n'
import type { BootstrapMeta, CallResult, OptString, SettingsPayload } from './types'
import { Btn, ColorInput, Field, NumInput, Section, Select, StatusText, StringListEditor, TextInput, ToggleRow } from './ui'

type Call = (endpoint: string, payload?: unknown) => Promise<CallResult | null>
type CmdKey = 'cuff' | 'hardcuff' | 'uncuff'
interface JobItem { job: string; item: string }

// OptString (string | false) -> string for a text input; empty stays empty.
const os = (v: OptString): string => (typeof v === 'string' ? v : '')

const clone = <T,>(v: T): T => JSON.parse(JSON.stringify(v))

export function SettingsTab({
  t,
  settings,
  meta,
  call,
  notify,
  toast,
}: {
  t: AdminStrings
  settings: SettingsPayload
  meta: BootstrapMeta
  call: Call
  notify: (msg: string, ok: boolean) => void
  toast: { msg: string; ok: boolean } | null
}) {
  const [s, setS] = useState<SettingsPayload>(() => clone(settings))
  const [cmdJobs, setCmdJobs] = useState<Record<CmdKey, JobItem[]>>(() => ({
    cuff: Object.entries(settings.Commands.cuff.jobs).map(([job, item]) => ({ job, item })),
    hardcuff: Object.entries(settings.Commands.hardcuff.jobs).map(([job, item]) => ({ job, item })),
    uncuff: Object.entries(settings.Commands.uncuff.jobs).map(([job, item]) => ({ job, item })),
  }))

  const upd = (mut: (d: SettingsPayload) => void) => setS((prev) => { const d = clone(prev); mut(d); return d })

  const save = async () => {
    const out = clone(s)
    // Fold command job maps back in.
    for (const key of ['cuff', 'hardcuff', 'uncuff'] as CmdKey[]) {
      const map: Record<string, string> = {}
      for (const row of cmdJobs[key]) {
        const j = row.job.trim().toLowerCase()
        if (j && row.item.trim()) map[j] = row.item.trim()
      }
      out.Commands[key].jobs = map
    }
    // Empty OptString command/sound fields disable the feature (-> false).
    const blankToFalse = (v: OptString): OptString => (typeof v === 'string' && v.trim() === '' ? false : v)
    out.AnkleTracker.command = blankToFalse(out.AnkleTracker.command)
    out.HeadBag.command = blankToFalse(out.HeadBag.command)
    out.Tape.command = blankToFalse(out.Tape.command)
    for (const k of ['cuff', 'hardcuff', 'uncuff', 'ankleTracker', 'headBag', 'tape'] as const) {
      out.playSound[k] = blankToFalse(out.playSound[k])
    }

    const res = await call('admin:settings:save', { settings: out })
    notify(res?.ok ? t.saved : errText(t, res?.err), Boolean(res?.ok))
  }

  const localeOpts = meta.locales.map((l) => ({ value: l, label: l.toUpperCase() }))
  const targetOpts = meta.targetSystems.map((v) => ({ value: v, label: v }))
  const voiceOpts = meta.voiceScripts.map((v) => ({ value: v, label: v }))

  const targetOptionKeys = [
    ['cuff', t.opt_cuff], ['hardcuff', t.opt_hardcuff], ['uncuff', t.opt_uncuff],
    ['ankletracker', t.opt_ankletracker], ['headbag', t.opt_headbag], ['tape', t.opt_tape],
    ['drag', t.opt_drag], ['putInCar', t.opt_putInCar], ['putOutOfCar', t.opt_putOutOfCar],
  ] as const

  const soundKeys = [
    ['cuff', t.snd_cuff], ['hardcuff', t.snd_hardcuff], ['uncuff', t.snd_uncuff],
    ['ankleTracker', t.snd_tracker], ['headBag', t.snd_headbag], ['tape', t.snd_tape],
  ] as const

  return (
    <div className="flex flex-col gap-4">
      <div className="flex min-h-[18px] items-center justify-between">
        <span className="font-sans text-[11px] text-text-muted">{t.restart_hint}</span>
        <StatusText toast={toast} />
      </div>

      {/* General */}
      <Section title={t.general}>
        <div className="grid grid-cols-3 gap-3">
          <Field label={t.locale}><Select value={s.Locale} onChange={(v) => upd((d) => { d.Locale = v })} options={localeOpts} /></Field>
          <Field label={t.brand_tag}><TextInput value={s.BrandTag} onChange={(v) => upd((d) => { d.BrandTag = v })} /></Field>
          <Field label={t.admin_command}><TextInput value={s.adminCommand} onChange={(v) => upd((d) => { d.adminCommand = v })} /></Field>
          <Field label={t.max_distance}><NumInput value={s.MaxDistance} step={0.5} onChange={(v) => upd((d) => { d.MaxDistance = v })} /></Field>
        </div>
        <div className="grid grid-cols-3 gap-3">
          <ToggleRow label={t.debug} checked={s.Debug} onChange={(v) => upd((d) => { d.Debug = v })} />
          <ToggleRow label={t.versionchecker} checked={s.VersionChecker} onChange={(v) => upd((d) => { d.VersionChecker = v })} />
          <ToggleRow label={t.enable_props} checked={s.EnableProps} onChange={(v) => upd((d) => { d.EnableProps = v })} />
        </div>
      </Section>

      {/* Theme */}
      <Section title={t.theme}>
        <div className="grid grid-cols-5 gap-3">
          <ColorInput label={t.color_accent} value={s.Theme.accent} onChange={(v) => upd((d) => { d.Theme.accent = v })} />
          <ColorInput label={t.color_bg} value={s.Theme.bg} onChange={(v) => upd((d) => { d.Theme.bg = v })} />
          <ColorInput label={t.color_panel} value={s.Theme.panel} onChange={(v) => upd((d) => { d.Theme.panel = v })} />
          <ColorInput label={t.color_text_primary} value={s.Theme.textPrimary} onChange={(v) => upd((d) => { d.Theme.textPrimary = v })} />
          <ColorInput label={t.color_text_secondary} value={s.Theme.textSecondary} onChange={(v) => upd((d) => { d.Theme.textSecondary = v })} />
        </div>
      </Section>

      {/* Timer & death & restore */}
      <div className="grid grid-cols-2 gap-4">
        <Section title={t.timer_settings}>
          <ToggleRow label={t.timer_enable} checked={s.Timer.enable} onChange={(v) => upd((d) => { d.Timer.enable = v })} />
          <Field label={t.timer_time}><NumInput value={s.Timer.time} onChange={(v) => upd((d) => { d.Timer.time = v })} /></Field>
          <ToggleRow label={t.uncuff_on_death} checked={s.UncuffOnPlayerDied} onChange={(v) => upd((d) => { d.UncuffOnPlayerDied = v })} />
        </Section>
        <Section title={t.restore_on_load}>
          <ToggleRow label={t.restore_cuff} checked={s.checkOnPlayerLoaded.cuff} onChange={(v) => upd((d) => { d.checkOnPlayerLoaded.cuff = v })} />
          <ToggleRow label={t.restore_hardcuff} checked={s.checkOnPlayerLoaded.hardcuff} onChange={(v) => upd((d) => { d.checkOnPlayerLoaded.hardcuff = v })} />
          <ToggleRow label={t.restore_tracker} checked={s.checkOnPlayerLoaded.ankleTracker} onChange={(v) => upd((d) => { d.checkOnPlayerLoaded.ankleTracker = v })} />
          <ToggleRow label={t.restore_headbag} checked={s.checkOnPlayerLoaded.headbag} onChange={(v) => upd((d) => { d.checkOnPlayerLoaded.headbag = v })} />
          <ToggleRow label={t.restore_tape} checked={s.checkOnPlayerLoaded.tape} onChange={(v) => upd((d) => { d.checkOnPlayerLoaded.tape = v })} />
        </Section>
      </div>

      {/* AnkleTracker */}
      <Section title={t.ankletracker_settings}>
        <ToggleRow label={t.enable} checked={s.AnkleTracker.enable} onChange={(v) => upd((d) => { d.AnkleTracker.enable = v })} />
        <div className="grid grid-cols-3 gap-3">
          <Field label={t.feat_item}><TextInput value={s.AnkleTracker.item} onChange={(v) => upd((d) => { d.AnkleTracker.item = v })} /></Field>
          <Field label={t.feat_remove_item}><TextInput value={s.AnkleTracker.removeItem} onChange={(v) => upd((d) => { d.AnkleTracker.removeItem = v })} /></Field>
          <Field label={t.feat_command}><TextInput value={os(s.AnkleTracker.command)} onChange={(v) => upd((d) => { d.AnkleTracker.command = v })} /></Field>
          <Field label={t.refresh_time}><NumInput value={s.AnkleTracker.refreshTime} step={0.5} onChange={(v) => upd((d) => { d.AnkleTracker.refreshTime = v })} /></Field>
        </div>
        <ToggleRow label={t.consume_remove_item} checked={s.AnkleTracker.consumeRemoveItem} onChange={(v) => upd((d) => { d.AnkleTracker.consumeRemoveItem = v })} />
        <div className="grid grid-cols-4 gap-3">
          <Field label={t.blip_id}><NumInput value={s.AnkleTracker.blip.id} onChange={(v) => upd((d) => { d.AnkleTracker.blip.id = v })} /></Field>
          <Field label={t.blip_color}><NumInput value={s.AnkleTracker.blip.color} onChange={(v) => upd((d) => { d.AnkleTracker.blip.color = v })} /></Field>
          <Field label={t.blip_scale}><NumInput value={s.AnkleTracker.blip.scale} step={0.1} onChange={(v) => upd((d) => { d.AnkleTracker.blip.scale = v })} /></Field>
          <Field label={t.blip_prefix}><TextInput value={s.AnkleTracker.blip.prefix} onChange={(v) => upd((d) => { d.AnkleTracker.blip.prefix = v })} /></Field>
        </div>
        <span className="msk-label text-[10px] font-bold">{t.tracker_jobs}</span>
        <StringListEditor
          values={s.AnkleTracker.jobs}
          placeholder="police"
          addLabel={t.add_job_name}
          onChange={(vals) => upd((d) => { d.AnkleTracker.jobs = vals })}
        />
      </Section>

      {/* HeadBag & Tape */}
      <div className="grid grid-cols-2 gap-4">
        <Section title={t.headbag_settings}>
          <ToggleRow label={t.enable} checked={s.HeadBag.enable} onChange={(v) => upd((d) => { d.HeadBag.enable = v })} />
          <Field label={t.feat_item}><TextInput value={s.HeadBag.item} onChange={(v) => upd((d) => { d.HeadBag.item = v })} /></Field>
          <ToggleRow label={t.need_item_to_remove} checked={s.HeadBag.needItemToRemove} onChange={(v) => upd((d) => { d.HeadBag.needItemToRemove = v })} />
          <Field label={t.feat_remove_item}><TextInput value={s.HeadBag.removeItem} onChange={(v) => upd((d) => { d.HeadBag.removeItem = v })} disabled={!s.HeadBag.needItemToRemove} /></Field>
          <ToggleRow label={t.consume_remove_item} checked={s.HeadBag.consumeRemoveItem} onChange={(v) => upd((d) => { d.HeadBag.consumeRemoveItem = v })} disabled={!s.HeadBag.needItemToRemove} />
          <Field label={t.feat_command}><TextInput value={os(s.HeadBag.command)} onChange={(v) => upd((d) => { d.HeadBag.command = v })} /></Field>
        </Section>
        <Section title={t.tape_settings}>
          <ToggleRow label={t.enable} checked={s.Tape.enable} onChange={(v) => upd((d) => { d.Tape.enable = v })} />
          <Field label={t.feat_item}><TextInput value={s.Tape.item} onChange={(v) => upd((d) => { d.Tape.item = v })} /></Field>
          <ToggleRow label={t.need_item_to_remove} checked={s.Tape.needItemToRemove} onChange={(v) => upd((d) => { d.Tape.needItemToRemove = v })} />
          <Field label={t.feat_remove_item}><TextInput value={s.Tape.removeItem} onChange={(v) => upd((d) => { d.Tape.removeItem = v })} disabled={!s.Tape.needItemToRemove} /></Field>
          <ToggleRow label={t.consume_remove_item} checked={s.Tape.consumeRemoveItem} onChange={(v) => upd((d) => { d.Tape.consumeRemoveItem = v })} disabled={!s.Tape.needItemToRemove} />
          <Field label={t.feat_command}><TextInput value={os(s.Tape.command)} onChange={(v) => upd((d) => { d.Tape.command = v })} /></Field>
        </Section>
      </div>

      {/* Voice & Sounds */}
      <div className="grid grid-cols-2 gap-4">
        <Section title={t.voice_settings}>
          <ToggleRow label={t.voice_enable} checked={s.Voice.enable} onChange={(v) => upd((d) => { d.Voice.enable = v })} />
          <Field label={t.voice_script}><Select value={s.Voice.voice} onChange={(v) => upd((d) => { d.Voice.voice = v })} options={voiceOpts} /></Field>
        </Section>
        <Section title={t.sound_settings} hint={t.sound_hint}>
          <ToggleRow label={t.sound_enable} checked={s.playSound.enable} onChange={(v) => upd((d) => { d.playSound.enable = v })} />
          <div className="grid grid-cols-2 gap-2">
            {soundKeys.map(([k, label]) => (
              <Field key={k} label={label}>
                <TextInput value={os(s.playSound[k])} onChange={(v) => upd((d) => { d.playSound[k] = v })} />
              </Field>
            ))}
          </div>
        </Section>
      </div>

      {/* Target */}
      <Section title={t.target_settings}>
        <div className="grid grid-cols-3 gap-3">
          <ToggleRow label={t.target_enable} checked={s.Target.enable} onChange={(v) => upd((d) => { d.Target.enable = v })} />
          <Field label={t.target_system}><Select value={s.Target.system} onChange={(v) => upd((d) => { d.Target.system = v })} options={targetOpts} /></Field>
          <Field label={t.undrag_hotkey}><TextInput value={s.Target.undragHotkey} onChange={(v) => upd((d) => { d.Target.undragHotkey = v })} /></Field>
        </div>
        <span className="msk-label text-[10px] font-bold">{t.target_options}</span>
        <div className="grid grid-cols-3 gap-2">
          {targetOptionKeys.map(([k, label]) => (
            <ToggleRow key={k} label={label} checked={s.Target.options[k]} onChange={(v) => upd((d) => { d.Target.options[k] = v })} />
          ))}
        </div>
      </Section>

      {/* Commands */}
      <Section title={t.commands_settings}>
        <div className="grid grid-cols-3 gap-4">
          {(['cuff', 'hardcuff', 'uncuff'] as CmdKey[]).map((key) => (
            <div key={key} className="flex flex-col gap-2 rounded-sm border border-border bg-input p-3">
              <span className="font-mono text-[12px] uppercase tracking-[0.06em] text-accent">{key}</span>
              <ToggleRow label={t.enable} checked={s.Commands[key].enable} onChange={(v) => upd((d) => { d.Commands[key].enable = v })} />
              <Field label={t.cmd_command}><TextInput value={s.Commands[key].command} onChange={(v) => upd((d) => { d.Commands[key].command = v })} /></Field>
              <Field label={t.cmd_item}><TextInput value={s.Commands[key].item} onChange={(v) => upd((d) => { d.Commands[key].item = v })} /></Field>
              <span className="msk-label text-[10px] font-bold">{t.cmd_jobs}</span>
              {cmdJobs[key].map((row, i) => (
                <div key={i} className="flex items-center gap-1.5">
                  <input
                    value={row.job}
                    placeholder="job"
                    onChange={(e) => setCmdJobs((c) => ({ ...c, [key]: c[key].map((r, idx) => (idx === i ? { ...r, job: e.target.value } : r)) }))}
                    className="w-1/2 rounded-sm border border-border bg-panel px-2 py-1.5 font-mono text-[11px] text-text-primary outline-none focus:border-border-accent"
                  />
                  <input
                    value={row.item}
                    placeholder="item"
                    onChange={(e) => setCmdJobs((c) => ({ ...c, [key]: c[key].map((r, idx) => (idx === i ? { ...r, item: e.target.value } : r)) }))}
                    className="w-1/2 rounded-sm border border-border bg-panel px-2 py-1.5 font-mono text-[11px] text-text-primary outline-none focus:border-border-accent"
                  />
                  <button
                    onClick={() => setCmdJobs((c) => ({ ...c, [key]: c[key].filter((_, idx) => idx !== i) }))}
                    className="shrink-0 rounded-sm border border-border p-1.5 text-text-muted hover:text-red-400"
                  >
                    <Trash2 size={13} />
                  </button>
                </div>
              ))}
              <Btn onClick={() => setCmdJobs((c) => ({ ...c, [key]: [...c[key], { job: '', item: '' }] }))}>
                <Plus size={12} /> {t.add_cmd_job}
              </Btn>
            </div>
          ))}
        </div>
      </Section>

      {/* Admin commands */}
      <Section title={t.admin_commands_settings}>
        <div className="grid grid-cols-3 gap-3">
          <div className="col-span-3 flex flex-col gap-2 rounded-sm border border-border bg-input p-3">
            <span className="font-mono text-[12px] uppercase tracking-[0.06em] text-accent">cuff</span>
            <div className="grid grid-cols-3 gap-2">
              <ToggleRow label={t.enable} checked={s.AdminCommands.cuff.enable} onChange={(v) => upd((d) => { d.AdminCommands.cuff.enable = v })} />
              <Field label={t.cmd_command}><TextInput value={s.AdminCommands.cuff.command} onChange={(v) => upd((d) => { d.AdminCommands.cuff.command = v })} /></Field>
              <ToggleRow label={t.play_animation} checked={s.AdminCommands.cuff.playAnimation} onChange={(v) => upd((d) => { d.AdminCommands.cuff.playAnimation = v })} />
            </div>
          </div>
          {(['hardcuff', 'uncuff', 'ankleTracker', 'headbag', 'tape'] as const).map((key) => (
            <div key={key} className="flex flex-col gap-2 rounded-sm border border-border bg-input p-3">
              <span className="font-mono text-[12px] uppercase tracking-[0.06em] text-accent">{key}</span>
              <ToggleRow label={t.enable} checked={s.AdminCommands[key].enable} onChange={(v) => upd((d) => { d.AdminCommands[key].enable = v })} />
              <Field label={t.cmd_command}><TextInput value={s.AdminCommands[key].command} onChange={(v) => upd((d) => { d.AdminCommands[key].command = v })} /></Field>
            </div>
          ))}
        </div>
        <span className="msk-label text-[10px] font-bold">{t.admin_groups}</span>
        <StringListEditor values={s.AdminGroups} placeholder="admin" addLabel={t.add} onChange={(vals) => upd((d) => { d.AdminGroups = vals })} />
      </Section>

      {/* Discord */}
      <Section title={t.discord_settings}>
        <ToggleRow label={t.discord_log} checked={s.DiscordLog} onChange={(v) => upd((d) => { d.DiscordLog = v })} />
        <Field label={t.discord_webhook}><TextInput value={s.DiscordWebhook} onChange={(v) => upd((d) => { d.DiscordWebhook = v })} placeholder="https://discord.com/api/webhooks/…" /></Field>
        <div className="grid grid-cols-3 gap-3">
          <Field label={t.bot_name}><TextInput value={s.botName} onChange={(v) => upd((d) => { d.botName = v })} /></Field>
          <Field label={t.bot_avatar}><TextInput value={s.botAvatar} onChange={(v) => upd((d) => { d.botAvatar = v })} /></Field>
          <Field label={t.bot_color}><TextInput value={s.botColor} onChange={(v) => upd((d) => { d.botColor = v })} /></Field>
        </div>
      </Section>

      <div className="sticky bottom-0 flex justify-end bg-panel/80 py-2 backdrop-blur">
        <Btn variant="accent" onClick={save}>{t.save_settings}</Btn>
      </div>
    </div>
  )
}
