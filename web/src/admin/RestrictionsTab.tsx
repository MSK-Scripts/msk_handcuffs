import { useState } from 'react'
import { Plus, Trash2 } from 'lucide-react'
import type { AdminStrings } from './i18n'
import { errText } from './i18n'
import type { CallResult, ItemSet, JobInfo, SettingsPayload } from './types'
import { Btn, Field, Section, StatusText, Switch, TextInput, ToggleRow } from './ui'

type Call = (endpoint: string, payload?: unknown) => Promise<CallResult | null>

const EMPTY_SET: ItemSet = {
  cuffItem: '',
  hardcuffItem: '',
  uncuffItem: '',
  enableAnkletracker: false,
  enableHeadbag: false,
  enableTape: false,
}

function ItemSetEditor({ t, set, onChange }: { t: AdminStrings; set: ItemSet; onChange: (s: ItemSet) => void }) {
  const upd = (patch: Partial<ItemSet>) => onChange({ ...set, ...patch })
  return (
    <div className="flex flex-col gap-3">
      <div className="grid grid-cols-3 gap-2">
        <Field label={t.cuff_item}>
          <TextInput value={set.cuffItem} onChange={(v) => upd({ cuffItem: v })} />
        </Field>
        <Field label={t.hardcuff_item}>
          <TextInput value={set.hardcuffItem} onChange={(v) => upd({ hardcuffItem: v })} />
        </Field>
        <Field label={t.uncuff_item}>
          <TextInput value={set.uncuffItem} onChange={(v) => upd({ uncuffItem: v })} />
        </Field>
      </div>
      <div className="grid grid-cols-3 gap-2">
        <ToggleRow label={t.allow_ankletracker} checked={set.enableAnkletracker} onChange={(v) => upd({ enableAnkletracker: v })} />
        <ToggleRow label={t.allow_headbag} checked={set.enableHeadbag} onChange={(v) => upd({ enableHeadbag: v })} />
        <ToggleRow label={t.allow_tape} checked={set.enableTape} onChange={(v) => upd({ enableTape: v })} />
      </div>
    </div>
  )
}

interface JobRow { job: string; set: ItemSet }

export function RestrictionsTab({
  t,
  settings,
  jobsList,
  call,
  notify,
  toast,
}: {
  t: AdminStrings
  settings: SettingsPayload
  jobsList: JobInfo[]
  call: Call
  notify: (msg: string, ok: boolean) => void
  toast: { msg: string; ok: boolean } | null
}) {
  const r = settings.RestrictItems
  const [enable, setEnable] = useState<boolean>(r.enable)
  const [defaultItems, setDefaultItems] = useState<ItemSet>({ ...EMPTY_SET, ...r.defaultItems })
  const [jobs, setJobs] = useState<JobRow[]>(
    Object.entries(r.jobItems || {}).map(([job, set]) => ({ job, set: { ...EMPTY_SET, ...set } })),
  )
  const [newJob, setNewJob] = useState('')

  const addJob = () => {
    const job = newJob.trim().toLowerCase()
    if (!job || jobs.some((j) => j.job === job)) { setNewJob(''); return }
    setJobs((j) => [...j, { job, set: { ...EMPTY_SET } }])
    setNewJob('')
  }

  const save = async () => {
    const jobItems: Record<string, ItemSet> = {}
    for (const row of jobs) {
      const job = row.job.trim().toLowerCase()
      if (job) jobItems[job] = row.set
    }
    const res = await call('admin:restrictions:save', {
      restrictions: { enable, defaultItems, jobItems },
    })
    notify(res?.ok ? t.saved : errText(t, res?.err), Boolean(res?.ok))
  }

  const inputCls = 'rounded-sm border border-border bg-input px-3 py-2 text-[13px] text-text-primary outline-none focus:border-border-accent'

  return (
    <div className="flex flex-col gap-4">
      <div className="flex min-h-[18px] items-center justify-between">
        <span className="font-sans text-[11px] text-text-muted">{t.restrict_hint}</span>
        <StatusText toast={toast} />
      </div>

      <div className="flex items-center justify-between rounded-sm border border-border bg-panel-raised px-4 py-3">
        <span className="msk-label text-[11px] font-bold text-accent">{t.restrict_enable}</span>
        <Switch checked={enable} onChange={setEnable} />
      </div>

      <Section title={t.default_items}>
        <ItemSetEditor t={t} set={defaultItems} onChange={setDefaultItems} />
      </Section>

      <Section title={t.job_items}>
        <div className="flex flex-col gap-3">
          {jobs.map((row, i) => (
            <div key={i} className="rounded-sm border border-border bg-input p-3">
              <div className="mb-3 flex items-center justify-between">
                <span className="font-mono text-[13px] uppercase tracking-[0.06em] text-text-primary">{row.job}</span>
                <button
                  onClick={() => setJobs((j) => j.filter((_, idx) => idx !== i))}
                  className="rounded-sm border border-border p-1.5 text-text-muted hover:text-red-400"
                >
                  <Trash2 size={14} />
                </button>
              </div>
              <ItemSetEditor t={t} set={row.set} onChange={(s) => setJobs((j) => j.map((r, idx) => (idx === i ? { ...r, set: s } : r)))} />
            </div>
          ))}
          <div className="flex gap-2">
            <input
              value={newJob}
              onChange={(e) => setNewJob(e.target.value)}
              placeholder={t.job_name}
              list="restrict-jobs"
              className={`${inputCls} flex-1`}
            />
            <datalist id="restrict-jobs">
              {jobsList.map((j) => (
                <option key={j.name} value={j.name}>{j.label}</option>
              ))}
            </datalist>
            <Btn onClick={addJob}><Plus size={13} /> {t.add_job}</Btn>
          </div>
        </div>
      </Section>

      <div className="flex justify-end">
        <Btn variant="accent" onClick={save}>{t.save_restrictions}</Btn>
      </div>
    </div>
  )
}
