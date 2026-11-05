import { useMemo, useState } from 'react'
import { Link2, Lock, RefreshCw, Unlock, UserRound } from 'lucide-react'
import { fetchNui } from '../lib/nui'
import type { AdminStrings } from './i18n'
import { errText } from './i18n'
import type { AdminBootstrap, CallResult, PlayerEntry } from './types'
import { Btn, Section, StatusText } from './ui'

type Notify = (msg: string, ok: boolean) => void

function Badge({ label, on }: { label: string; on: boolean }) {
  if (!on) return null
  return (
    <span className="rounded-sm bg-accent/15 px-2 py-0.5 font-mono text-[10px] uppercase tracking-[0.06em] text-accent">
      {label}
    </span>
  )
}

export function PlayersTab({
  t,
  players,
  perms,
  notify,
  toast,
  setD,
}: {
  t: AdminStrings
  players: PlayerEntry[]
  perms: Record<string, boolean>
  notify: Notify
  toast: { msg: string; ok: boolean } | null
  setD: React.Dispatch<React.SetStateAction<AdminBootstrap>>
}) {
  const [selectedId, setSelectedId] = useState<number | null>(players[0]?.serverId ?? null)
  const [filter, setFilter] = useState('')

  const selected = useMemo(
    () => players.find((p) => p.serverId === selectedId) ?? null,
    [players, selectedId],
  )

  const shown = useMemo(() => {
    const q = filter.trim().toLowerCase()
    if (!q) return players
    return players.filter(
      (p) => p.name.toLowerCase().includes(q) || String(p.serverId).includes(q) || p.job.toLowerCase().includes(q),
    )
  }, [players, filter])

  const refresh = async () => {
    const res = await fetchNui<CallResult>('admin:players:list')
    if (res?.ok && res.players) setD((prev) => ({ ...prev, players: res.players! }))
    else if (res) notify(errText(t, res.err), false)
  }

  const runAction = async (action: string) => {
    if (!selected) return
    const res = await fetchNui<CallResult>('admin:player:action', { serverId: selected.serverId, action })
    if (res?.ok && res.players) {
      setD((prev) => ({ ...prev, players: res.players! }))
      notify(t.saved, true)
    } else {
      notify(errText(t, res?.err), false)
    }
  }

  const canCuff = Boolean(perms['players.cuff'])
  const canUncuff = Boolean(perms['players.uncuff'])
  const canTracker = Boolean(perms['players.tracker'])
  const canHeadbag = Boolean(perms['players.headbag'])
  const canTape = Boolean(perms['players.tape'])

  const inputCls = 'w-full rounded-sm border border-border bg-input px-3 py-2 text-[13px] text-text-primary outline-none focus:border-border-accent'

  return (
    <div className="flex flex-col gap-4">
      <div className="flex min-h-[18px] items-center justify-end">
        <StatusText toast={toast} />
      </div>

      <div className="grid grid-cols-[340px_1fr] gap-4">
        {/* Left: online list */}
        <Section title={t.players_online}>
          <div className="flex gap-2">
            <input value={filter} onChange={(e) => setFilter(e.target.value)} placeholder={`${t.players_online}…`} className={inputCls} />
            <Btn onClick={refresh}><RefreshCw size={13} /> {t.refresh_list}</Btn>
          </div>
          {shown.length === 0 ? (
            <p className="font-sans text-[12px] text-text-muted">{t.no_players}</p>
          ) : (
            <div className="msk-scroll flex max-h-[52vh] flex-col gap-1 overflow-y-auto pr-1">
              {shown.map((pl) => (
                <button
                  key={pl.serverId}
                  onClick={() => setSelectedId(pl.serverId)}
                  className={`flex items-center justify-between rounded-sm border px-3 py-2 text-left transition-colors ${
                    selectedId === pl.serverId ? 'border-border-accent bg-accent/10' : 'border-border bg-input hover:border-border-accent'
                  }`}
                >
                  <span className="flex items-center gap-2">
                    <UserRound size={14} className={pl.status.cuffed ? 'text-accent' : 'text-text-muted'} />
                    <span className="font-sans text-[13px] text-text-primary">{pl.name}</span>
                  </span>
                  <span className="font-mono text-[11px] text-text-muted">[{pl.serverId}]</span>
                </button>
              ))}
            </div>
          )}
        </Section>

        {/* Right: detail + actions */}
        <div className="flex flex-col gap-4">
          {!selected ? (
            <Section title={t.status}>
              <p className="font-sans text-[12px] text-text-muted">{t.select_player}</p>
            </Section>
          ) : (
            <>
              <Section title={selected.name}>
                <div className="flex flex-wrap items-center gap-2">
                  <span className="font-mono text-[11px] text-text-muted">[{selected.serverId}]</span>
                  <span className="font-mono text-[11px] text-text-muted">{selected.identifier}</span>
                  <span className="rounded-sm bg-white/10 px-2 py-0.5 font-mono text-[10px] uppercase text-text-secondary">
                    {t.job}: {selected.job}
                  </span>
                </div>
                <div className="flex flex-wrap items-center gap-1.5 pt-1">
                  <Badge label={selected.status.adminCuffed ? t.st_admincuffed : t.st_cuffed} on={selected.status.cuffed} />
                  <Badge label={t.st_hardcuffed} on={selected.status.hardcuffed} />
                  <Badge label={t.st_ankletracker} on={selected.status.ankletracker} />
                  <Badge label={t.st_headbag} on={selected.status.headbag} />
                  <Badge label={t.st_tape} on={selected.status.tape} />
                  {!selected.status.cuffed && !selected.status.ankletracker && !selected.status.headbag && !selected.status.tape && (
                    <span className="font-sans text-[12px] text-text-muted">—</span>
                  )}
                </div>
              </Section>

              <Section title={t.actions}>
                <div className="flex flex-wrap gap-2">
                  <Btn variant="accent" onClick={() => runAction('cuff')} disabled={!canCuff || selected.status.cuffed}>
                    <Lock size={13} /> {t.act_cuff}
                  </Btn>
                  <Btn onClick={() => runAction('hardcuff')} disabled={!canCuff || !selected.status.cuffed || selected.status.hardcuffed}>
                    <Link2 size={13} /> {t.act_hardcuff}
                  </Btn>
                  <Btn variant="danger" onClick={() => runAction('uncuff')} disabled={!canUncuff || !selected.status.cuffed}>
                    <Unlock size={13} /> {t.act_uncuff}
                  </Btn>
                </div>
                <div className="flex flex-wrap gap-2">
                  <Btn onClick={() => runAction('ankletracker')} disabled={!canTracker}>
                    {t.act_tracker}: {selected.status.ankletracker ? 'ON' : 'OFF'}
                  </Btn>
                  <Btn onClick={() => runAction('headbag')} disabled={!canHeadbag}>
                    {t.act_headbag}: {selected.status.headbag ? 'ON' : 'OFF'}
                  </Btn>
                  <Btn onClick={() => runAction('tape')} disabled={!canTape}>
                    {t.act_tape}: {selected.status.tape ? 'ON' : 'OFF'}
                  </Btn>
                </div>
              </Section>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
