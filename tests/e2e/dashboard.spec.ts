import { expect, test } from '@playwright/test'

// Smoke test: confirms the storage-state session minted in global-setup.ts
// is actually accepted by the app (real Supabase auth, real RLS) rather than
// bouncing to /login, and that the signed-in shell renders.
test('signed-in user lands on the dashboard, not the login page', async ({
  page,
}) => {
  await page.goto('/')

  await expect(page).not.toHaveURL(/\/login/)
  await expect(page.getByRole('button', { name: /menu/i })).toBeVisible()
})
