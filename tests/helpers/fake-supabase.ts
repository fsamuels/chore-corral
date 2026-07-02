import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '../../app/types/database.types'

// Minimal in-memory fake of the Supabase client, covering only the query
// chains app/services/categories.ts actually uses:
//
//   from('categories').select(...).eq(...).is(...).order(...)
//   from('categories').insert(row).select(...).single()
//   from('tasks').select('id', { count: 'exact', head: true }).eq(...).eq(...).in(...)
//   from('categories').update(row).eq(...).eq(...).is(...).select(...)
//   from('activity_log').insert(row)                       // awaited with no .select()
//
// It is not a general PostgREST emulator: no joins, no or(), no partial
// filter operators beyond eq/is/in. Keep it that way — generalizing further
// belongs in a real integration test against Supabase, not here.

type TableName = 'categories' | 'tasks' | 'activity_log'
type Row = Record<string, unknown>

export interface FakeSupabaseSeed {
  categories?: Database['public']['Tables']['categories']['Row'][]
  tasks?: Database['public']['Tables']['tasks']['Row'][]
  activity_log?: Database['public']['Tables']['activity_log']['Row'][]
}

export interface FailSpec {
  table: TableName
  op: 'select' | 'insert' | 'update'
  message?: string
}

interface FailSpecInternal {
  table: TableName
  op: 'select' | 'insert' | 'update'
  message: string
}

type QueryResult = {
  data?: unknown
  error: { message: string } | null
  count?: number | null
}

class FakeQueryBuilder implements PromiseLike<QueryResult> {
  private opType: 'select' | 'insert' | 'update' = 'select'
  private readonly filters: Array<(row: Row) => boolean> = []
  private insertPayload?: Row
  private updatePayload?: Row
  private singleMode = false
  private countMode = false
  private orderCol?: string
  private selectCols?: string[]

  constructor(
    private readonly table: TableName,
    private readonly store: Record<TableName, Row[]>,
    private readonly failSpecs: FailSpecInternal[],
    private readonly nextId: (table: TableName) => string,
  ) {}

  select(columns: string, options?: { count?: 'exact'; head?: boolean }): this {
    if (options?.head) this.countMode = true
    this.selectCols = columns.split(',').map((c) => c.trim())
    return this
  }

  insert(row: Row): this {
    this.opType = 'insert'
    this.insertPayload = row
    return this
  }

  update(row: Row): this {
    this.opType = 'update'
    this.updatePayload = row
    return this
  }

  eq(column: string, value: unknown): this {
    this.filters.push((row) => row[column] === value)
    return this
  }

  is(column: string, value: unknown): this {
    this.filters.push((row) => row[column] === value)
    return this
  }

  in(column: string, values: unknown[]): this {
    this.filters.push((row) => values.includes(row[column]))
    return this
  }

  order(column: string): this {
    this.orderCol = column
    return this
  }

  single(): this {
    this.singleMode = true
    return this
  }

  // Makes the builder itself awaitable, matching supabase-js's
  // PostgrestBuilder — code can `await` a chain whether or not it ends in
  // .select()/.single()/.order().
  then<TResult1 = QueryResult, TResult2 = never>(
    onfulfilled?:
      ((value: QueryResult) => TResult1 | PromiseLike<TResult1>) | null,
    onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null,
  ): PromiseLike<TResult1 | TResult2> {
    return this.execute().then(onfulfilled, onrejected)
  }

  private project(row: Row): Row {
    if (!this.selectCols || this.selectCols.length === 0) return row
    const result: Row = {}
    for (const col of this.selectCols) result[col] = row[col]
    return result
  }

  private matchingFailure(): FailSpecInternal | undefined {
    return this.failSpecs.find(
      (f) => f.table === this.table && f.op === this.opType,
    )
  }

  private async execute(): Promise<QueryResult> {
    const failure = this.matchingFailure()
    if (failure) {
      return this.countMode
        ? { count: null, error: { message: failure.message } }
        : { data: null, error: { message: failure.message } }
    }

    const rows = this.store[this.table]

    if (this.opType === 'insert') {
      const created: Row = {
        id: this.nextId(this.table),
        created_at: new Date().toISOString(),
        ...this.insertPayload,
      }
      rows.push(created)
      if (!this.selectCols) return { data: null, error: null }
      const projected = this.project(created)
      return this.singleMode
        ? { data: projected, error: null }
        : { data: [projected], error: null }
    }

    if (this.opType === 'update') {
      const matches = rows.filter((row) => this.filters.every((f) => f(row)))
      for (const row of matches) Object.assign(row, this.updatePayload)
      return { data: matches.map((row) => this.project(row)), error: null }
    }

    // select
    let matches = rows.filter((row) => this.filters.every((f) => f(row)))
    if (this.countMode) {
      return { count: matches.length, error: null, data: null }
    }
    if (this.orderCol) {
      const col = this.orderCol
      matches = [...matches].sort((a, b) =>
        String(a[col]).localeCompare(String(b[col])),
      )
    }
    return { data: matches.map((row) => this.project(row)), error: null }
  }
}

export class FakeSupabaseClient {
  private readonly store: Record<TableName, Row[]>
  private readonly failSpecs: FailSpecInternal[]
  private readonly counters: Record<TableName, number> = {
    categories: 0,
    tasks: 0,
    activity_log: 0,
  }

  constructor(seed: FakeSupabaseSeed = {}, failOn?: FailSpec | FailSpec[]) {
    this.store = {
      categories: cloneRows(seed.categories as unknown as Row[] | undefined),
      tasks: cloneRows(seed.tasks as unknown as Row[] | undefined),
      activity_log: cloneRows(
        seed.activity_log as unknown as Row[] | undefined,
      ),
    }
    const specs = failOn ? (Array.isArray(failOn) ? failOn : [failOn]) : []
    this.failSpecs = specs.map((s) => ({
      table: s.table,
      op: s.op,
      message: s.message ?? `Simulated ${s.op} error on ${s.table}`,
    }))
  }

  from(table: TableName): FakeQueryBuilder {
    return new FakeQueryBuilder(table, this.store, this.failSpecs, (t) =>
      this.nextId(t),
    )
  }

  /** Test-only escape hatch for asserting on the fake's internal state. */
  getTable(table: TableName): Row[] {
    return this.store[table]
  }

  private nextId(table: TableName): string {
    this.counters[table] += 1
    return `${table}-${this.counters[table]}`
  }
}

function cloneRows(rows: Row[] | undefined): Row[] {
  return (rows ?? []).map((row) => ({ ...row }))
}

/** Cast the fake to the real client type at the call site. */
export function asSupabaseClient(
  client: FakeSupabaseClient,
): SupabaseClient<Database> {
  return client as unknown as SupabaseClient<Database>
}
