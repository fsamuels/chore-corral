import { chromium } from '@playwright/test'
import { createClient } from '@supabase/supabase-js'
import { randomUUID } from 'node:crypto'

// Mints a real Supabase session for a seeded test user out-of-band (no app
// code involved) and writes it to disk as Playwright storage state, so every
// e2e test starts already signed in. See docs/ARCHITECTURE.md — Testing
// Strategy for the full rationale — this exercises real RLS/session behavior
// instead of adding a dev-only auth bypass to the app itself.

const SUPABASE_URL = process.env.NUXT_PUBLIC_SUPABASE_URL
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY
const ANON_KEY = process.env.NUXT_PUBLIC_SUPABASE_KEY
const TEST_EMAIL =
  process.env.E2E_TEST_USER_EMAIL ?? 'e2e-test@chore-corral.test'
const TEST_PASSWORD =
  process.env.E2E_TEST_USER_PASSWORD ?? 'e2e-test-password-do-not-use-in-prod'
const TEST_FARM_NAME = process.env.E2E_TEST_FARM_NAME ?? 'E2E Test Farm'
const BASE_URL = process.env.E2E_BASE_URL ?? 'http://localhost:3000'
const STORAGE_STATE_PATH = 'tests/e2e/.auth/user.json'

// Mirrors @supabase/ssr's createChunks (utils/chunker.ts): cookies over
// MAX_CHUNK_SIZE encoded chars get split across `${name}.0`, `${name}.1`, ...
// so the client's chunk-combining reader finds them. Sessions are usually
// small enough to fit a single cookie, but user_metadata/identities can push
// a payload over the limit, so chunking needs to be replicated faithfully
// rather than assumed away.
const MAX_CHUNK_SIZE = 3180

function createCookieChunks(
  name: string,
  value: string,
): { name: string; value: string }[] {
  const encodedValue = encodeURIComponent(value)
  if (encodedValue.length <= MAX_CHUNK_SIZE) {
    return [{ name, value }]
  }

  const chunks: string[] = []
  let remaining = encodedValue
  while (remaining.length > 0) {
    let head = remaining.slice(0, MAX_CHUNK_SIZE)
    const lastEscapePos = head.lastIndexOf('%')
    if (lastEscapePos > MAX_CHUNK_SIZE - 3) {
      head = head.slice(0, lastEscapePos)
    }
    chunks.push(decodeURIComponent(head))
    remaining = remaining.slice(head.length)
  }
  return chunks.map((chunkValue, i) => ({
    name: `${name}.${i}`,
    value: chunkValue,
  }))
}

async function findUserByEmail(
  admin: ReturnType<typeof createClient>,
  email: string,
) {
  // The admin API has no get-by-email lookup; page through listUsers instead.
  // The e2e suite runs against a project with a handful of users, so a single
  // page is always enough.
  const { data, error } = await admin.auth.admin.listUsers()
  if (error) throw error
  return data.users.find((user) => user.email === email) ?? null
}

async function ensureTestUser(admin: ReturnType<typeof createClient>) {
  const existing = await findUserByEmail(admin, TEST_EMAIL)
  if (existing) {
    // Re-assert the password in case it drifted from a previous manual change.
    const { error } = await admin.auth.admin.updateUserById(existing.id, {
      password: TEST_PASSWORD,
    })
    if (error) throw error
    return existing.id
  }

  const { data, error } = await admin.auth.admin.createUser({
    email: TEST_EMAIL,
    password: TEST_PASSWORD,
    email_confirm: true,
  })
  if (error) throw error
  return data.user.id
}

async function ensureFarmMembership(
  admin: ReturnType<typeof createClient>,
  userId: string,
) {
  const { data: existingMembership, error: membershipLookupError } = await admin
    .from('farm_memberships')
    .select('farm_id')
    .eq('user_id', userId)
    .maybeSingle()
  if (membershipLookupError) throw membershipLookupError
  if (existingMembership) return existingMembership.farm_id

  const { data: farm, error: farmError } = await admin
    .from('farms')
    .insert({ id: randomUUID(), name: TEST_FARM_NAME })
    .select('id')
    .single()
  if (farmError) throw farmError

  const { error: membershipError } = await admin
    .from('farm_memberships')
    .insert({ id: randomUUID(), farm_id: farm.id, user_id: userId })
  if (membershipError) throw membershipError

  return farm.id
}

export default async function globalSetup() {
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY || !ANON_KEY) {
    throw new Error(
      'e2e tests require NUXT_PUBLIC_SUPABASE_URL, NUXT_PUBLIC_SUPABASE_KEY, and ' +
        'SUPABASE_SERVICE_ROLE_KEY to be set (service role key: Supabase dashboard → ' +
        'Project Settings → API — keep it out of client-side code, it is only used here).',
    )
  }

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  })

  const userId = await ensureTestUser(admin)
  await ensureFarmMembership(admin, userId)

  const anon = createClient(SUPABASE_URL, ANON_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  })
  const { data: signInData, error: signInError } =
    await anon.auth.signInWithPassword({
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
    })
  if (signInError || !signInData.session) {
    throw new Error(
      `Failed to mint a session for the e2e test user: ${signInError?.message}`,
    )
  }

  const cookieName = `sb-${new URL(SUPABASE_URL).hostname.split('.')[0]}-auth-token`
  const cookieValue =
    'base64-' +
    Buffer.from(JSON.stringify(signInData.session)).toString('base64url')

  const browser = await chromium.launch()
  const context = await browser.newContext()
  const url = new URL(BASE_URL)
  await context.addCookies(
    createCookieChunks(cookieName, cookieValue).map(({ name, value }) => ({
      name,
      value,
      domain: url.hostname,
      path: '/',
      httpOnly: false,
      secure: url.protocol === 'https:',
      sameSite: 'Lax' as const,
    })),
  )
  await context.storageState({ path: STORAGE_STATE_PATH })
  await browser.close()
}
