<script setup lang="ts">
import type { Database } from '~/types/database.types'
import {
  getAppStats,
  getPublicTaskCount,
  type AppStats,
} from '~/services/stats'
import { formatElapsedDuration } from '~/utils/task-display'
import type { BuildInfo } from '../../scripts/build-info'

useHead({ title: 'About — Chore Corral' })

const REPO_URL = 'https://github.com/fsamuels/chore-corral'

const supabase = useSupabaseClient<Database>()
const build = useRuntimeConfig().public.buildInfo as unknown as BuildInfo

// Decorative, like the landing page's stat: a failed fetch never breaks the
// page. If `get_app_stats` isn't there yet (its migration not applied), fall
// back to the older `get_public_task_count` so the section still shows a
// chore total; if that fails too, it shows just a note. useAsyncData hands
// the server's result to the client instead of refetching during hydration.
const { data: statsData } = await useAsyncData('about-stats', async () => {
  let stats: AppStats | null = null
  try {
    stats = await getAppStats(supabase)
  } catch {
    stats = null
  }
  if (stats) return { stats, fallbackChores: null }
  let fallbackChores: number | null = null
  try {
    fallbackChores = await getPublicTaskCount(supabase)
  } catch {
    fallbackChores = null
  }
  return { stats: null, fallbackChores }
})
const stats = computed(() => statsData.value?.stats ?? null)
const fallbackChores = computed(() => statsData.value?.fallbackChores ?? null)

const number = new Intl.NumberFormat('en-US')
const fmt = (n: number | null | undefined) => number.format(n ?? 0)

const DAY_MS = 24 * 60 * 60 * 1000

// Dates are formatted in the viewer's locale/timezone, which the server
// doesn't know — so they render as plain UTC dates during SSR and switch to
// local formatting once mounted, avoiding a hydration mismatch.
const mounted = ref(false)
onMounted(() => (mounted.value = true))

function formatDateTime(iso: string | null): string {
  if (!iso) return 'unknown'
  if (!mounted.value) return iso.slice(0, 10)
  return new Date(iso).toLocaleString(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  })
}

function relative(iso: string | null): string | null {
  if (!iso || !mounted.value) return null
  const days = Math.floor((Date.now() - new Date(iso).getTime()) / DAY_MS)
  if (days <= 0) return 'today'
  if (days === 1) return 'yesterday'
  return `${days} days ago`
}

const dataTiles = computed(() => {
  const s = stats.value
  if (!s) {
    return fallbackChores.value === null
      ? []
      : [
          {
            icon: 'mdi-clipboard-list-outline',
            label: 'Chores',
            value: fmt(fallbackChores.value),
          },
        ]
  }
  return [
    { icon: 'mdi-barn', label: 'Farms', value: fmt(s.farms) },
    {
      icon: 'mdi-account-group-outline',
      label: 'Accounts',
      value: fmt(s.accounts),
    },
    {
      icon: 'mdi-clipboard-list-outline',
      label: 'Chores',
      value: fmt(s.chores),
    },
    {
      icon: 'mdi-check-circle-outline',
      label: 'Chores done',
      value: fmt(s.chores_done),
    },
    { icon: 'mdi-camera-outline', label: 'Photos', value: fmt(s.photos) },
    {
      icon: 'mdi-timer-outline',
      label: 'Time tracked',
      value: formatElapsedDuration(s.tracked_seconds * 1000),
    },
    {
      icon: 'mdi-shape-outline',
      label: 'Categories',
      value: fmt(s.categories),
    },
    {
      icon: 'mdi-map-marker-outline',
      label: 'Locations',
      value: fmt(s.locations),
    },
    { icon: 'mdi-tag-outline', label: 'Tags', value: fmt(s.tags) },
    {
      icon: 'mdi-cart-outline',
      label: 'Shopping items',
      value: fmt(s.shopping_items),
    },
    { icon: 'mdi-hammer-wrench', label: 'Tools listed', value: fmt(s.tools) },
    {
      icon: 'mdi-history',
      label: 'Activity events',
      value: fmt(s.activity_events),
    },
  ]
})

const funFacts = computed(() => {
  const facts: string[] = []
  const s = stats.value
  if (s && s.chores > 0) {
    const pct = Math.round((s.chores_done / s.chores) * 100)
    facts.push(`${pct}% of every chore ever created has been finished.`)
  }
  if (s && s.farms > 0) {
    const perFarm = (s.chores / s.farms).toFixed(1)
    facts.push(`The average farm has ${perFarm} chores on the books.`)
  }
  if (s?.first_chore_at && mounted.value) {
    const days = Math.max(
      1,
      Math.ceil((Date.now() - new Date(s.first_chore_at).getTime()) / DAY_MS),
    )
    facts.push(
      `The first chore was created ${fmt(days)} days ago — that's about ${(
        s.chores / days
      ).toFixed(1)} new chores a day since.`,
    )
  }
  const code = build.code
  // ~50 lines to a printed page.
  facts.push(
    `Printed out, the source code would fill roughly ${fmt(
      Math.round(code.totalLines / 50),
    )} pages.`,
  )
  // ~230 words a minute for technical prose.
  facts.push(
    `The docs run ${fmt(code.docsWords)} words — about ${fmt(
      Math.round(code.docsWords / 230),
    )} minutes of reading.`,
  )
  if (code.longestFile) {
    facts.push(
      `The longest file is ${code.longestFile.path} at ${fmt(
        code.longestFile.lines,
      )} lines.`,
    )
  }
  if (code.testCases > 0 && code.services > 0) {
    facts.push(
      `${fmt(code.testCases)} test cases guard ${code.services} services — about ${Math.round(
        code.testCases / code.services,
      )} per service.`,
    )
  }
  return facts
})

const codeTiles = computed(() => {
  const c = build.code
  return [
    { label: 'Lines of code', value: fmt(c.totalLines) },
    { label: 'Source files', value: fmt(c.totalFiles) },
    { label: 'Pages', value: fmt(c.pages) },
    { label: 'Components', value: fmt(c.components) },
    { label: 'Composables', value: fmt(c.composables) },
    { label: 'Services', value: fmt(c.services) },
    { label: 'DB migrations', value: fmt(c.migrations) },
    { label: 'Test files', value: fmt(c.testFiles) },
    { label: 'Test cases', value: fmt(c.testCases) },
    {
      label: 'Dependencies',
      value: `${build.dependencies} + ${build.devDependencies} dev`,
    },
  ]
})

const maxLanguageLines = computed(() =>
  Math.max(1, ...build.code.languages.map((l) => l.lines)),
)

const coverage = computed(() => build.coverage)
const coverageMetrics = computed(() => {
  const c = coverage.value
  if (!c) return []
  return [
    { label: 'Statements', value: c.statements },
    { label: 'Branches', value: c.branches },
    { label: 'Functions', value: c.functions },
  ]
})
// `services` → `Services`; `app` is the handful of files directly in app/.
const areaLabel = (area: string) =>
  area === 'app' ? 'App root' : area[0]!.toUpperCase() + area.slice(1)

const stack = computed(() =>
  [
    ['Nuxt', build.nuxtVersion],
    ['Vue', build.vueVersion],
    ['Vuetify', build.vuetifyVersion],
  ].filter((entry): entry is [string, string] => !!entry[1]),
)
</script>

<template>
  <div class="cc-page cc-page--narrow">
    <PageHeader title="About">
      Chore Corral is a mobile-first chore tracker for the farm. Created by
      <strong>Forrest Samuels</strong> and <strong>Claude</strong>.
    </PageHeader>

    <section class="cc-card mb-6">
      <h2 class="cc-section-title mb-3">This build</h2>
      <dl class="about-defs">
        <dt>Commit</dt>
        <dd>
          <a
            v-if="build.commitSha"
            :href="`${REPO_URL}/commit/${build.commitSha}`"
            target="_blank"
            rel="noopener"
            class="cc-text-link about-mono"
            >{{ build.commitShortSha }}</a
          >
          <span v-else>unknown</span>
          <span
            v-if="build.commitMessage"
            class="d-block text-body-2 cc-muted"
            >{{ build.commitMessage }}</span
          >
        </dd>
        <template v-if="build.branch && build.branch !== 'HEAD'">
          <dt>Branch</dt>
          <dd class="about-mono">{{ build.branch }}</dd>
        </template>
        <dt>Built</dt>
        <dd>
          {{ formatDateTime(build.builtAt) }}
          <span v-if="relative(build.builtAt)" class="cc-muted">
            ({{ relative(build.builtAt) }})</span
          >
        </dd>
        <template v-if="build.commitDate">
          <dt>Committed</dt>
          <dd>{{ formatDateTime(build.commitDate) }}</dd>
        </template>
        <template v-if="build.commitCount">
          <dt>Commits</dt>
          <dd>{{ fmt(build.commitCount) }}</dd>
        </template>
        <template v-if="build.firstCommitDate">
          <dt>First commit</dt>
          <dd>
            {{ formatDateTime(build.firstCommitDate) }}
            <span v-if="relative(build.firstCommitDate)" class="cc-muted">
              ({{ relative(build.firstCommitDate) }})</span
            >
          </dd>
        </template>
        <template v-if="stack.length">
          <dt>Stack</dt>
          <dd>
            <span
              v-for="[name, version] in stack"
              :key="name"
              class="cc-pill cc-pill--muted mr-2 mb-1"
              >{{ name }} {{ version }}</span
            >
            <span class="cc-pill cc-pill--muted mr-2 mb-1">Supabase</span>
            <span class="cc-pill cc-pill--muted mb-1">Vercel</span>
          </dd>
        </template>
      </dl>
    </section>

    <section class="mb-6">
      <h2 class="cc-section-title mb-3">By the numbers</h2>
      <v-alert
        v-if="!stats"
        type="info"
        variant="tonal"
        density="compact"
        class="mb-3"
      >
        More app-wide totals are on the way.
      </v-alert>
      <div v-if="dataTiles.length" class="about-tiles">
        <div
          v-for="tile in dataTiles"
          :key="tile.label"
          class="cc-card cc-card--row"
        >
          <v-icon :icon="tile.icon" size="20" color="primary" />
          <div class="about-tile__value cc-slab">{{ tile.value }}</div>
          <div class="cc-eyebrow">{{ tile.label }}</div>
        </div>
      </div>
    </section>

    <section class="mb-6">
      <h2 class="cc-section-title mb-3">Under the hood</h2>
      <div class="about-tiles mb-4">
        <div
          v-for="tile in codeTiles"
          :key="tile.label"
          class="cc-card cc-card--row"
        >
          <div class="about-tile__value cc-slab">{{ tile.value }}</div>
          <div class="cc-eyebrow">{{ tile.label }}</div>
        </div>
      </div>
      <div class="cc-card">
        <div class="cc-eyebrow mb-3">Lines by language</div>
        <div
          v-for="lang in build.code.languages"
          :key="lang.language"
          class="about-bar"
        >
          <span class="about-bar__label">{{ lang.language }}</span>
          <span class="about-bar__track">
            <span
              class="about-bar__fill"
              :style="{ width: `${(lang.lines / maxLanguageLines) * 100}%` }"
            />
          </span>
          <span class="about-bar__value">{{ fmt(lang.lines) }}</span>
        </div>
      </div>
      <div class="cc-card mt-4">
        <div class="cc-eyebrow mb-2">Test coverage</div>
        <template v-if="coverage">
          <div class="d-flex align-baseline flex-wrap ga-2">
            <span class="about-coverage__headline cc-slab"
              >{{ coverage.lines }}%</span
            >
            <span class="text-body-2 cc-muted">
              of lines ({{ fmt(coverage.coveredLines) }} of
              {{ fmt(coverage.totalLines) }})
            </span>
          </div>
          <div class="d-flex flex-wrap ga-2 mt-2 mb-4">
            <span
              v-for="metric in coverageMetrics"
              :key="metric.label"
              class="cc-pill cc-pill--muted"
              >{{ metric.label }} {{ metric.value }}%</span
            >
          </div>
          <div
            v-for="area in coverage.areas"
            :key="area.area"
            class="about-bar"
          >
            <span class="about-bar__label">{{ areaLabel(area.area) }}</span>
            <span class="about-bar__track">
              <span
                class="about-bar__fill"
                :style="{ width: `${area.pct}%` }"
              />
            </span>
            <span class="about-bar__value">{{ Math.round(area.pct) }}%</span>
          </div>
          <p class="text-caption cc-muted mt-3 mb-0">
            Unit tests (Vitest) across every file in app/ and server/; files no
            test loads count as 0%. The Playwright end-to-end suite isn't
            included.
          </p>
        </template>
        <p v-else class="text-body-2 cc-muted mb-0">
          Coverage wasn't measured for this build.
        </p>
      </div>
    </section>

    <section class="cc-card mb-6">
      <h2 class="cc-section-title mb-3">Fun facts</h2>
      <ul class="about-facts">
        <li v-for="fact in funFacts" :key="fact">{{ fact }}</li>
      </ul>
    </section>

    <p class="text-body-2 cc-muted text-center mb-8">
      <a :href="REPO_URL" target="_blank" rel="noopener" class="cc-text-link"
        >View the source on GitHub</a
      >
    </p>
  </div>
</template>

<style scoped>
.about-defs {
  display: grid;
  grid-template-columns: max-content 1fr;
  gap: 8px 16px;
}
.about-defs dt {
  font-weight: 600;
  color: var(--cc-ink-muted);
}
.about-defs dd {
  margin: 0;
  min-width: 0;
  overflow-wrap: anywhere;
}
.about-mono {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
}
.about-tiles {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 12px;
}
.about-tile__value {
  font-size: 1.5rem;
  font-weight: 700;
  line-height: 1.2;
  margin: 4px 0 2px;
}
.about-bar {
  display: grid;
  grid-template-columns: 100px 1fr max-content;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
  font-size: 0.875rem;
}
.about-bar__track {
  height: 10px;
  border-radius: 999px;
  background: var(--cc-border);
  overflow: hidden;
}
.about-bar__fill {
  display: block;
  height: 100%;
  border-radius: 999px;
  background: var(--cc-accent);
}
.about-bar__value {
  min-width: 52px;
  text-align: right;
  font-variant-numeric: tabular-nums;
  color: var(--cc-ink-muted);
}
.about-coverage__headline {
  font-size: 2rem;
  font-weight: 700;
  line-height: 1.1;
}
.about-facts {
  padding-left: 1.2em;
}
.about-facts li + li {
  margin-top: 6px;
}
</style>
