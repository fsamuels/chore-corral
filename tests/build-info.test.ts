import { describe, expect, it } from 'vitest'
import { summarizeCodebase, summarizeCoverage } from '../scripts/build-info'

describe('summarizeCodebase', () => {
  const files = [
    { path: 'app/pages/index.vue', content: 'a\nb\nc\n' },
    { path: 'app/pages/about.vue', content: 'a\nb' },
    { path: 'app/components/Card.vue', content: 'x\n' },
    { path: 'app/composables/useThing.ts', content: 'x\ny\n' },
    { path: 'app/services/things.ts', content: '1\n2\n3\n4\n5\n' },
    {
      path: 'supabase/migrations/001_init.sql',
      content: 'create table t();\n',
    },
    {
      path: 'tests/things.test.ts',
      content:
        "it('a', () => {})\n  test('b', () => {})\nit.each([1])('c', () => {})\n",
    },
    { path: 'README.txt', content: 'ignored\n' },
  ]

  const stats = summarizeCodebase(files, ['one two three', 'four\nfive'])

  it('totals lines per language, sorted largest first', () => {
    expect(stats.languages).toEqual([
      { language: 'TypeScript', files: 3, lines: 10 },
      { language: 'Vue', files: 3, lines: 6 },
      { language: 'SQL', files: 1, lines: 1 },
    ])
    expect(stats.totalLines).toBe(17)
    expect(stats.totalFiles).toBe(7)
  })

  it('counts files by area', () => {
    expect(stats.pages).toBe(2)
    expect(stats.components).toBe(1)
    expect(stats.composables).toBe(1)
    expect(stats.services).toBe(1)
    expect(stats.migrations).toBe(1)
    expect(stats.testFiles).toBe(1)
  })

  it('counts test cases, docs words and the longest file', () => {
    expect(stats.testCases).toBe(3)
    expect(stats.docsWords).toBe(5)
    expect(stats.longestFile).toEqual({
      path: 'app/services/things.ts',
      lines: 5,
    })
  })

  it('handles an empty codebase', () => {
    const empty = summarizeCodebase([], [])
    expect(empty.totalLines).toBe(0)
    expect(empty.longestFile).toBeNull()
  })
})

describe('summarizeCoverage', () => {
  const m = (covered: number, total: number) => ({
    covered,
    total,
    pct: total ? (covered / total) * 100 : 100,
  })
  const file = (covered: number, total: number) => ({
    lines: m(covered, total),
    statements: m(covered, total),
    branches: m(0, 0),
    functions: m(0, 0),
  })

  it('totals and groups line coverage by area, best-covered first', () => {
    const stats = summarizeCoverage(
      {
        total: {
          lines: m(30, 120),
          statements: m(31, 130),
          branches: m(1, 3),
          functions: m(2, 3),
        },
        '/repo/app/services/a.ts': file(18, 20),
        '/repo/app/services/b.ts': file(9, 10),
        '/repo/app/pages/index.vue': file(3, 80),
        '/repo/app/app.vue': file(0, 4),
        '/repo/server/api/x.post.ts': file(0, 6),
      },
      '/repo/',
    )
    expect(stats).toMatchObject({
      lines: 25,
      statements: 23.8,
      branches: 33.3,
      functions: 66.7,
      coveredLines: 30,
      totalLines: 120,
    })
    expect(stats?.areas).toEqual([
      { area: 'services', files: 2, covered: 27, total: 30, pct: 90 },
      { area: 'pages', files: 1, covered: 3, total: 80, pct: 3.8 },
      { area: 'server', files: 1, covered: 0, total: 6, pct: 0 },
      { area: 'app', files: 1, covered: 0, total: 4, pct: 0 },
    ])
  })

  it('returns null for a report with no total', () => {
    expect(summarizeCoverage({}, '/repo')).toBeNull()
  })
})
