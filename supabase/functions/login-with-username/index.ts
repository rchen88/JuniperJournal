import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const { username, password } = await req.json()

  if (!username || !password) {
    return new Response(
      JSON.stringify({ error: 'Invalid username or password.' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  // Service-role client — can read auth.users, never sent to the client
  const adminClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  // Look up the user's UUID by username
  const { data: profile, error: profileError } = await adminClient
    .from('profiles')
    .select('id')
    .eq('username', username.trim().toLowerCase())
    .maybeSingle()

  if (profileError || !profile) {
    return new Response(
      JSON.stringify({ error: 'Invalid username or password.' }),
      { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  // Resolve UUID → email via admin API (never leaves the server)
  const { data: { user }, error: userError } = await adminClient.auth.admin.getUserById(profile.id)

  if (userError || !user?.email) {
    return new Response(
      JSON.stringify({ error: 'Invalid username or password.' }),
      { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  // Sign in with the resolved email — uses anon key so auth rules apply normally
  const anonClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
  )

  const { data, error: signInError } = await anonClient.auth.signInWithPassword({
    email: user.email,
    password,
  })

  if (signInError || !data.session) {
    return new Response(
      JSON.stringify({ error: 'Invalid username or password.' }),
      { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  }

  return new Response(
    JSON.stringify({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
    }),
    { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
  )
})
