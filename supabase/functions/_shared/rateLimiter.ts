interface RateLimitEntry {
  count: number
  resetAt: number
}

const _store = new Map<string, RateLimitEntry>()
let _checksSinceLastPrune = 0

function _pruneExpired(): void {
  const now = Date.now()
  for (const [key, entry] of _store) {
    if (now >= entry.resetAt) _store.delete(key)
  }
}

/**
 * Checks whether a key has exceeded the rate limit.
 *
 * Uses an in-memory fixed window per Edge Function instance. Effective against
 * most brute-force and spam patterns within a single instance. For distributed
 * enforcement across instances, replace with a Redis/KV-backed store.
 */
export function checkRateLimit(
  key: string,
  limit: number,
  windowMs: number,
): { limited: boolean; retryAfterSecs: number } {
  if (++_checksSinceLastPrune >= 200) {
    _checksSinceLastPrune = 0
    _pruneExpired()
  }

  const now = Date.now()
  const entry = _store.get(key)

  if (!entry || now >= entry.resetAt) {
    _store.set(key, { count: 1, resetAt: now + windowMs })
    return { limited: false, retryAfterSecs: 0 }
  }

  if (entry.count >= limit) {
    return { limited: true, retryAfterSecs: Math.ceil((entry.resetAt - now) / 1000) }
  }

  entry.count++
  return { limited: false, retryAfterSecs: 0 }
}

/** Extracts the real client IP from Supabase proxy headers. */
export function getClientIp(req: Request): string {
  return (
    req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ??
    req.headers.get('x-real-ip') ??
    'unknown'
  )
}
