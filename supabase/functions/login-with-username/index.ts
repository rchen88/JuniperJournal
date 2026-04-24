import { createClient } from 'jsr:@supabase/supabase-js@2'
import { checkRateLimit, getClientIp } from '../_shared/rateLimiter.ts'
import { unexpectedFields, validatePassword, validateUsername } from '../_shared/validate.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const ALLOWED_FIELDS = ['username', 'password']
const MAX_BODY_BYTES = 4_096

function json(body: unknown, status: number, extra?: Record<string, string>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json', ...extra },
  })
}

function tooManyRequests(retryAfterSecs: number): Response {
  return json(
    { error: 'Too many requests. Please try again later.' },
    429,
    { 'Retry-After': String(retryAfterSecs) },
  )
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // ── IP-level rate limit (10 req / min) ────────────────────────────────────
  const ip = getClientIp(req)
  const ipCheck = checkRateLimit(`ip:${ip}:login`, 10, 60_000)
  if (ipCheck.limited) return tooManyRequests(ipCheck.retryAfterSecs)

  // ── Body size guard ───────────────────────────────────────────────────────
  const contentLength = Number(req.headers.get('content-length') ?? 0)
  if (contentLength > MAX_BODY_BYTES) {
    return json({ error: 'Request body too large.' }, 413)
  }

  // ── Parse JSON ────────────────────────────────────────────────────────────
  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return json({ error: 'Invalid JSON.' }, 400)
  }

  // ── Reject unexpected fields ──────────────────────────────────────────────
  if (unexpectedFields(body, ALLOWED_FIELDS).length > 0) {
    return json({ error: 'Invalid request.' }, 400)
  }

  // ── Schema validation ─────────────────────────────────────────────────────
  const usernameResult = validateUsername(body.username)
  if (!usernameResult.ok) {
    // Return generic message to avoid leaking valid username formats
    return json({ error: 'Invalid username or password.' }, 400)
  }

  const passwordResult = validatePassword(body.password)
  if (!passwordResult.ok) {
    return json({ error: 'Invalid username or password.' }, 400)
  }

  const username = (body.username as string).trim().toLowerCase()
  const password = body.password as string

  // ── Per-username rate limit (5 req / min) — prevents targeted brute-force ─
  const userCheck = checkRateLimit(`user:${username}:login`, 5, 60_000)
  if (userCheck.limited) return tooManyRequests(userCheck.retryAfterSecs)

  // ── Resolve username → UUID → email (server-side only) ────────────────────
  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  const { data: profile, error: profileError } = await adminClient
    .from('profiles')
    .select('id')
    .eq('username', username)
    .maybeSingle()

  if (profileError || !profile) {
    return json({ error: 'Invalid username or password.' }, 401)
  }

  const { data: { user }, error: userError } = await adminClient.auth.admin.getUserById(profile.id)

  if (userError || !user?.email) {
    return json({ error: 'Invalid username or password.' }, 401)
  }

  // ── Sign in via anon key so normal auth rules apply ───────────────────────
  const anonClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
  )

  const { data, error: signInError } = await anonClient.auth.signInWithPassword({
    email: user.email,
    password,
  })

  if (signInError || !data.session) {
    return json({ error: 'Invalid username or password.' }, 401)
  }

  return json(
    { access_token: data.session.access_token, refresh_token: data.session.refresh_token },
    200,
  )
})
