const THEME_COOKIE = 'cc-theme'

export const THEME_BRANDS = [
  { id: 'classic', label: 'Classic', swatch: '#1867C0' },
  { id: 'deere', label: 'John Deere', swatch: '#367C2B' },
  { id: 'kubota', label: 'Kubota', swatch: '#DF5C2A' },
  { id: 'massey', label: 'Massey Ferguson', swatch: '#A6192E' },
] as const

export type ThemeBrand = (typeof THEME_BRANDS)[number]['id']

export interface ThemePreference {
  brand: ThemeBrand
  dark: boolean
}

const DEFAULT_PREFERENCE: ThemePreference = { brand: 'classic', dark: false }

function isThemeBrand(value: unknown): value is ThemeBrand {
  return THEME_BRANDS.some((brand) => brand.id === value)
}

function parsePreference(value: unknown): ThemePreference | null {
  if (typeof value !== 'object' || value === null) return null
  const candidate = value as Record<string, unknown>
  if (!isThemeBrand(candidate.brand)) return null
  return { brand: candidate.brand, dark: candidate.dark === true }
}

/**
 * Per-user Vuetify theme selection. The preference lives in Supabase user
 * metadata (so it follows the user across devices) with a cookie copy so the
 * theme applies during SSR without a flash of the default theme.
 */
export function useThemePreference() {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()
  const theme = useTheme()
  const cookie = useCookie<ThemePreference | null>(THEME_COOKIE, {
    default: () => null,
  })

  const preference = computed<ThemePreference>(
    () =>
      parsePreference(cookie.value) ??
      parsePreference(user.value?.user_metadata?.theme) ??
      DEFAULT_PREFERENCE,
  )

  function themeName(pref: ThemePreference): string {
    return `${pref.brand}-${pref.dark ? 'dark' : 'light'}`
  }

  function applyTheme() {
    theme.global.name.value = themeName(preference.value)
  }

  async function setPreference(pref: ThemePreference) {
    cookie.value = pref
    theme.global.name.value = themeName(pref)
    // Best-effort sync to the user's account; the cookie already covers this
    // device, so a metadata failure only affects other devices.
    if (user.value) {
      await supabase.auth.updateUser({ data: { theme: pref } })
    }
  }

  async function setBrand(brand: ThemeBrand) {
    await setPreference({ ...preference.value, brand })
  }

  async function setDark(dark: boolean) {
    await setPreference({ ...preference.value, dark })
  }

  return { preference, applyTheme, setBrand, setDark }
}
