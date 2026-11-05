import { useCallback, useEffect, useRef, useState } from 'react'
import { fetchNui } from './lib/nui'
import { AdminApp } from './admin/AdminApp'
import type { AdminBootstrap } from './admin/types'

// The gameplay NUI (headbag blackscreen + cuff sounds) and the admin dashboard
// share this single ui_page. The Lua message contract is unchanged from the old
// vanilla NUI:
//   { action: 'playSound',  sound: 'cuff.ogg', volume: 0.6 }
//   { action: 'blackscreen', toggle: 'On' | 'Off' }
//   { action: 'openAdmin',   data: AdminBootstrap }
interface OpenAdminMessage { action: 'openAdmin'; data: AdminBootstrap }
interface PlaySoundMessage { action: 'playSound'; sound: string; volume?: number }
interface BlackscreenMessage { action: 'blackscreen'; toggle: 'On' | 'Off' | boolean }
type NuiMessage = OpenAdminMessage | PlaySoundMessage | BlackscreenMessage | { action?: string }

const BASE = import.meta.env.BASE_URL

// Fabric "sack" texture + inner vignette. The image lives in html/images/ (from
// web/public/images/) and is referenced relative to the built index.html.
const BLACKSCREEN_BG =
  `radial-gradient(ellipse at center, rgba(0,0,0,0) 35%, rgba(0,0,0,0.9) 100%), url("${BASE}images/blackscreen.png")`

export default function App() {
  const [adminData, setAdminData] = useState<AdminBootstrap | null>(null)
  const [blackscreen, setBlackscreen] = useState(false)

  // One cached Audio element per sound file so repeated plays are instant.
  const soundCache = useRef<Record<string, HTMLAudioElement>>({})

  const playSound = useCallback((sound: string, volume?: number) => {
    if (!sound) return
    let audio = soundCache.current[sound]
    if (!audio) {
      audio = new Audio(`${BASE}sounds/${sound}`)
      audio.preload = 'auto'
      soundCache.current[sound] = audio
    }
    const vol = Number(volume)
    audio.volume = Number.isFinite(vol) ? Math.min(1, Math.max(0, vol)) : 0.5
    try {
      audio.currentTime = 0
    } catch {
      /* metadata may not be ready yet — ignore */
    }
    void audio.play().catch(() => {
      /* autoplay/availability errors are non-fatal */
    })
  }, [])

  useEffect(() => {
    const listener = (event: MessageEvent) => {
      const msg = event.data as NuiMessage
      if (!msg || !msg.action) return
      switch (msg.action) {
        case 'openAdmin':
          setAdminData((msg as OpenAdminMessage).data)
          break
        case 'playSound': {
          const m = msg as PlaySoundMessage
          playSound(m.sound, m.volume)
          break
        }
        case 'blackscreen': {
          const t = (msg as BlackscreenMessage).toggle
          setBlackscreen(t === 'On' || t === true)
          break
        }
        default:
          break
      }
    }
    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }, [playSound])

  const closeAdmin = useCallback(() => {
    setAdminData(null)
    fetchNui('admin:close')
  }, [])

  return (
    <>
      <div
        className={`blackscreen${blackscreen ? ' visible' : ''}`}
        aria-hidden={!blackscreen}
        style={{ backgroundImage: BLACKSCREEN_BG }}
      />
      {adminData && <AdminApp data={adminData} onClose={closeAdmin} />}
    </>
  )
}
