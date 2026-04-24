import { checkRateLimit, getClientIp } from '../_shared/rateLimiter.ts'
import { validateEmail } from '../_shared/validate.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const MAX_BODY_BYTES = 1_024

function json(body: unknown, status: number, extra?: Record<string, string>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json', ...extra },
  })
}

// Fail-open helper — never blocks signup due to a check error
const availableOk = () => json({ available: true }, 200)

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // ── IP-level rate limit (30 req / min) ────────────────────────────────────
  const ip = getClientIp(req)
  const ipCheck = checkRateLimit(`ip:${ip}:email-check`, 30, 60_000)
  if (ipCheck.limited) {
    return json(
      { error: 'Too many requests. Please try again later.' },
      429,
      { 'Retry-After': String(ipCheck.retryAfterSecs) },
    )
  }

  // ── Body size guard ───────────────────────────────────────────────────────
  const contentLength = Number(req.headers.get('content-length') ?? 0)
  if (contentLength > MAX_BODY_BYTES) return availableOk()

  // ── Parse JSON ────────────────────────────────────────────────────────────
  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return availableOk()
  }

  // ── Validate email ────────────────────────────────────────────────────────
  const emailResult = validateEmail(body.email)
  if (!emailResult.ok) return availableOk()

  const normalizedEmail = (body.email as string).trim().toLowerCase()
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

  try {
    const resp = await fetch(
      `${supabaseUrl}/auth/v1/admin/users?filter=${encodeURIComponent(normalizedEmail)}&per_page=5`,
      {
        headers: {
          'Authorization': `Bearer ${serviceRoleKey}`,
          'apikey': serviceRoleKey,
        },
      },
    )

    if (!resp.ok) return availableOk()

    const { users = [] }: { users: Array<{ email?: string }> } = await resp.json()
    const taken = users.some((u) => u.email?.toLowerCase() === normalizedEmail)

    return json({ available: !taken }, 200)
  } catch {
    return availableOk()
  }
})
