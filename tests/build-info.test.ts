import { describe, expect, it } from 'vitest'
import { summarizeCodebase } from '../scripts/build-info'

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
