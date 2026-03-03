const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { email } = await req.json()

    if (!email || typeof email !== 'string') {
      return new Response(
        JSON.stringify({ available: true }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const normalizedEmail = email.trim().toLowerCase()
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    // Query the GoTrue admin REST API directly — more reliable than the JS client wrapper
    const resp = await fetch(
      `${supabaseUrl}/auth/v1/admin/users?filter=${encodeURIComponent(normalizedEmail)}&per_page=5`,
      {
        headers: {
          'Authorization': `Bearer ${serviceRoleKey}`,
          'apikey': serviceRoleKey,
        },
      },
    )

    if (!resp.ok) {
      // Fail open — never block signup due to a check error
      return new Response(
        JSON.stringify({ available: true }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    const { users = [] }: { users: Array<{ email?: string }> } = await resp.json()

    // Exact-match check (GoTrue `filter` may return prefix/contains matches)
    const taken = users.some((u) => u.email?.toLowerCase() === normalizedEmail)

    return new Response(
      JSON.stringify({ available: !taken }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (_) {
    // Fail open
    return new Response(
      JSON.stringify({ available: true }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }
})
