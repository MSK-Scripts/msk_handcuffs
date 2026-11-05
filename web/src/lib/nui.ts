const resourceName = (): string => {
  try {
    return GetParentResourceName()
  } catch {
    return 'msk_handcuffs'
  }
}

const isBrowser = (): boolean => {
  try {
    GetParentResourceName()
    return false
  } catch {
    return true
  }
}

export async function fetchNui<T = unknown>(
  endpoint: string,
  data: unknown = {},
): Promise<T | null> {
  if (isBrowser()) {
    // Dev mode: the devMock (loaded in main.tsx) answers via nui:dev-reply.
    return new Promise<T | null>((resolve) => {
      const id = Math.random().toString(36).slice(2)
      const handler = (e: Event) => {
        const detail = (e as CustomEvent).detail
        if (!detail || detail.id !== id) return
        window.removeEventListener('nui:dev-reply', handler)
        resolve((detail.result ?? null) as T | null)
      }
      window.addEventListener('nui:dev-reply', handler)
      window.dispatchEvent(new CustomEvent('nui:dev-call', { detail: { id, endpoint, data } }))
      window.setTimeout(() => {
        window.removeEventListener('nui:dev-reply', handler)
        resolve(null)
      }, 1000)
    })
  }

  try {
    const resp = await fetch(`https://${resourceName()}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    })
    if (!resp.ok) return null
    const text = await resp.text()
    return text ? (JSON.parse(text) as T) : null
  } catch {
    return null
  }
}
