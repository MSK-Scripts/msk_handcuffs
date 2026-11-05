import { useState } from 'react'
import { Plus, Trash2 } from 'lucide-react'
import type { AdminStrings } from './i18n'
import { errText } from './i18n'
import type { CallResult, SettingsPayload } from './types'
import { Btn, Field, Section, StatusText, StringListEditor, Switch, TextInput, ToggleRow } from './ui'

type Call = (endpoint: string, payload?: unknown) => Promise<CallResult | null>

interface MappingRow { key: string; values: string[] }
interface GiveRow { key: string; value: boolean }

export function ItemsTab({
  t,
  settings,
  call,
  notify,
  toast,
}: {
  t: AdminStrings
  settings: SettingsPayload
  call: Call
  notify: (msg: string, ok: boolean) => void
  toast: { msg: string; ok: boolean } | null
}) {
  const [cuffItems, setCuffItems] = useState<string[]>(settings.cuffItems)
  const [hardcuffItems, setHardcuffItems] = useState<string[]>(settings.hardcuffItems)
  const [uncuffItems, setUncuffItems] = useState<string[]>(settings.uncuffItems)
  const [mapping, setMapping] = useState<MappingRow[]>(
    Object.entries(settings.ItemSettings || {}).map(([key, values]) => ({ key, values })),
  )
  const [give, setGive] = useState<GiveRow[]>(
    Object.entries(settings.GiveCuffItemBack || {}).map(([key, value]) => ({ key, value })),
  )
  const [consumeUncuff, setConsumeUncuff] = useState<boolean>(settings.consumeUncuffItem)

  const save = async () => {
    const ItemSettings: Record<string, string[]> = {}
    for (const row of mapping) {
      const k = row.key.trim()
      if (k) ItemSettings[k] = row.values.map((v) => v.trim()).filter(Boolean)
    }
    const GiveCuffItemBack: Record<string, boolean> = {}
    for (const row of give) {
      const k = row.key.trim()
      if (k) GiveCuffItemBack[k] = row.value
    }
    const res = await call('admin:items:save', {
      items: {
        cuffItems: cuffItems.map((v) => v.trim()).filter(Boolean),
        hardcuffItems: hardcuffItems.map((v) => v.trim()).filter(Boolean),
        uncuffItems: uncuffItems.map((v) => v.trim()).filter(Boolean),
        ItemSettings,
        GiveCuffItemBack,
        consumeUncuffItem: consumeUncuff,
      },
    })
    notify(res?.ok ? t.saved : errText(t, res?.err), Boolean(res?.ok))
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex min-h-[18px] items-center justify-between">
        <span className="font-sans text-[11px] text-text-muted">{t.restart_hint}</span>
        <StatusText toast={toast} />
      </div>

      <div className="grid grid-cols-3 gap-4">
        <Section title={t.cuff_items}>
          <StringListEditor values={cuffItems} placeholder={t.item_placeholder} addLabel={t.add_item} onChange={setCuffItems} />
        </Section>
        <Section title={t.hardcuff_items}>
          <StringListEditor values={hardcuffItems} placeholder={t.item_placeholder} addLabel={t.add_item} onChange={setHardcuffItems} />
        </Section>
        <Section title={t.uncuff_items}>
          <StringListEditor values={uncuffItems} placeholder={t.item_placeholder} addLabel={t.add_item} onChange={setUncuffItems} />
          <ToggleRow label={t.consume_remove_item} checked={consumeUncuff} onChange={setConsumeUncuff} />
        </Section>
      </div>

      <Section title={t.item_settings} hint={t.item_settings_hint}>
        <div className="flex flex-col gap-3">
          {mapping.map((row, i) => (
            <div key={i} className="rounded-sm border border-border bg-input p-3">
              <div className="mb-2 flex items-center gap-2">
                <div className="flex-1">
                  <Field label={t.mapping_cuff_item}>
                    <TextInput
                      value={row.key}
                      placeholder={t.item_placeholder}
                      onChange={(v) => setMapping((m) => m.map((r, idx) => (idx === i ? { ...r, key: v } : r)))}
                    />
                  </Field>
                </div>
                <button
                  onClick={() => setMapping((m) => m.filter((_, idx) => idx !== i))}
                  className="mt-5 shrink-0 rounded-sm border border-border p-2 text-text-muted hover:text-red-400"
                >
                  <Trash2 size={14} />
                </button>
              </div>
              <span className="msk-label text-[10px] font-bold">{t.mapping_uncuff_items}</span>
              <div className="mt-1.5">
                <StringListEditor
                  values={row.values}
                  placeholder={t.item_placeholder}
                  addLabel={t.add_item}
                  onChange={(vals) => setMapping((m) => m.map((r, idx) => (idx === i ? { ...r, values: vals } : r)))}
                />
              </div>
            </div>
          ))}
          <Btn onClick={() => setMapping((m) => [...m, { key: '', values: [] }])}>
            <Plus size={13} /> {t.add_mapping}
          </Btn>
        </div>
      </Section>

      <Section title={t.give_item_back} hint={t.give_item_back_hint}>
        <div className="flex flex-col gap-2">
          {give.map((row, i) => (
            <div key={i} className="flex items-center gap-2">
              <input
                value={row.key}
                placeholder={t.item_placeholder}
                onChange={(e) => setGive((g) => g.map((r, idx) => (idx === i ? { ...r, key: e.target.value } : r)))}
                className="flex-1 rounded-sm border border-border bg-input px-3 py-1.5 font-mono text-[12px] text-text-primary outline-none focus:border-border-accent"
              />
              <Switch
                checked={row.value}
                onChange={(v) => setGive((g) => g.map((r, idx) => (idx === i ? { ...r, value: v } : r)))}
              />
              <button
                onClick={() => setGive((g) => g.filter((_, idx) => idx !== i))}
                className="shrink-0 rounded-sm border border-border p-1.5 text-text-muted hover:text-red-400"
              >
                <Trash2 size={14} />
              </button>
            </div>
          ))}
          <Btn onClick={() => setGive((g) => [...g, { key: '', value: true }])}>
            <Plus size={13} /> {t.add_giveback}
          </Btn>
        </div>
      </Section>

      <div className="flex justify-end">
        <Btn variant="accent" onClick={save}>{t.save_items}</Btn>
      </div>
    </div>
  )
}
