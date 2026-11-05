import { useCallback, useEffect, useMemo, useState } from 'react'
import { X } from 'lucide-react'
import { fetchNui } from '../lib/nui'
import { applyTheme } from '../lib/theme'
import { strings } from './i18n'
import type { AdminBootstrap, CallResult } from './types'
import { PlayersTab } from './PlayersTab'
import { ItemsTab } from './ItemsTab'
import { RestrictionsTab } from './RestrictionsTab'
import { SettingsTab } from './SettingsTab'
import { PermissionsTab } from './PermissionsTab'

type TabId = 'players' | 'items' | 'restrictions' | 'settings' | 'permissions'

export function AdminApp({ data, onClose }: { data: AdminBootstrap; onClose: () => void }) {
  const [d, setD] = useState<AdminBootstrap>(data)
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null)
  const t = strings(d.locale)

  useEffect(() => {
    applyTheme(d.settings?.Theme)
  }, [d.settings?.Theme])

  const notify = useCallback((msg: string, ok: boolean) => {
    setToast({ msg, ok })
    window.setTimeout(() => setToast(null), 2600)
  }, [])

  // Global mutations (items/restrictions/settings/perms) return a fresh bootstrap.
  const call = useCallback(async (endpoint: string, payload?: unknown): Promise<CallResult | null> => {
    const res = await fetchNui<CallResult>(endpoint, payload)
    if (res?.ok && res.data) setD(res.data)
    return res
  }, [])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keyup', onKey)
    return () => window.removeEventListener('keyup', onKey)
  }, [onClose])

  const p = d.perms
  const tabs = useMemo(() => {
    const list: { id: TabId; label: string }[] = []
    if (p['players.view'] || p['players.cuff'] || p['players.uncuff'] || p['players.tracker'] || p['players.headbag'] || p['players.tape'])
      list.push({ id: 'players', label: t.tab_players })
    if (p['items.manage']) list.push({ id: 'items', label: t.tab_items })
    if (p['restrictions.manage']) list.push({ id: 'restrictions', label: t.tab_restrictions })
    if (p['settings.manage']) list.push({ id: 'settings', label: t.tab_settings })
    if (p['permissions.manage']) list.push({ id: 'permissions', label: t.tab_permissions })
    return list
  }, [p, t])

  const [tab, setTab] = useState<TabId>(tabs[0]?.id ?? 'players')

  return (
    <div className="flex h-full w-full items-center justify-center font-sans">
      <div className="msk-panel relative flex h-[88vh] w-[1180px] max-w-[96vw] flex-col animate-slide-up">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <div className="flex items-center gap-3">
            <span className="font-display text-[18px] font-bold text-text-primary">{t.title}</span>
            {d.settings.BrandTag ? (
              <span className="rounded-sm bg-accent/15 px-2 py-0.5 font-mono text-[10px] uppercase tracking-[0.1em] text-accent">
                {d.settings.BrandTag}
              </span>
            ) : null}
          </div>
          <button
            onClick={onClose}
            className="flex items-center gap-2 rounded-sm px-3 py-2 font-mono text-[11px] uppercase tracking-[0.08em] text-text-muted transition-colors hover:bg-input hover:text-text-primary"
          >
            {t.close} <X size={16} />
          </button>
        </div>

        {/* Tabs */}
        <div className="flex gap-1 border-b border-border px-6">
          {tabs.map((tb) => (
            <button
              key={tb.id}
              onClick={() => setTab(tb.id)}
              className={`-mb-px border-b-2 px-4 py-3 font-mono text-[12px] font-bold uppercase tracking-[0.08em] transition-colors ${
                tab === tb.id ? 'border-accent text-accent' : 'border-transparent text-text-muted hover:text-text-secondary'
              }`}
            >
              {tb.label}
            </button>
          ))}
        </div>

        {/* Content */}
        <div className="msk-scroll flex-1 overflow-y-auto p-6">
          {tab === 'players' && <PlayersTab t={t} players={d.players} perms={p} notify={notify} toast={toast} setD={setD} />}
          {tab === 'items' && <ItemsTab t={t} settings={d.settings} call={call} notify={notify} toast={toast} />}
          {tab === 'restrictions' && (
            <RestrictionsTab t={t} settings={d.settings} jobsList={d.jobsList} call={call} notify={notify} toast={toast} />
          )}
          {tab === 'settings' && (
            <SettingsTab t={t} settings={d.settings} meta={d.meta} call={call} notify={notify} toast={toast} />
          )}
          {tab === 'permissions' && (
            <PermissionsTab
              t={t}
              groups={d.groups}
              permKeys={d.permKeys}
              suggestedGroups={d.suggestedGroups}
              dashboardGroups={d.settings.dashboardGroups}
              call={call}
              notify={notify}
              toast={toast}
            />
          )}
        </div>
      </div>
    </div>
  )
}
