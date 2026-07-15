import type { SupabaseClient } from '@supabase/supabase-js'
import type { Database } from '../../app/types/database.types'

// Minimal in-memory fake of the Supabase client, covering only the query
// chains app/services/categories.ts, app/services/tasks.ts, and
// app/services/tags.ts actually use:
//
//   from('categories').select(...).eq(...).is(...).order(...)
//   from('categories').insert(row).select(...).single()
//   from('locations').select(...).eq(...).is(...).order(...)
//   from('locations').insert(row).select(...).single()
//   from('tasks').select('id', { count: 'exact', head: true }).eq(...).eq(...).in(...)
//   from('categories').update(row).eq(...).eq(...).is(...).select(...)
//   from('activity_log').insert(row)                       // awaited with no .select()
//   from('tasks').select(cols).eq('farm_id', ...).in('category_id', [...])
//   from('tasks').select(cols).eq('farm_id', ...).in('location_id', [...])
//   from('tasks').select(cols).eq('farm_id', ...)
//   from('tasks').select(cols).eq('farm_id', ...).eq('status', 'done')
//   from('tasks').select(cols).eq('id', ...).eq('farm_id', ...)
//   from('tasks').insert(row).select(cols).single()
//   from('tasks').update(row).eq('id', ...).eq('farm_id', ...).select(cols)
//   from('tasks').delete().eq('id', ...).eq('farm_id', ...).select('id, title')
//   from('tags').select(...).eq('farm_id', ...).order('name')
//   from('tags').select(...).eq('farm_id', ...).in('name', [...])
//   from('tags').insert(row).select(...).single()
//   from('task_tags').insert([row, ...])                   // bulk insert, no .select()
//   from('task_tags').select(...).eq('task_id', ...)
//   from('task_tags').select(...).in('task_id', [...])
//   from('task_tags').select(...).in('tag_id', [...])
//   from('task_tags').delete().eq('task_id', ...)
//   from('task_completers').insert([row, ...])            // bulk insert, no .select()
//   from('task_completers').select(...).in('task_id', [...])
//   from('task_completers').delete().eq('task_id', ...)
//   from('task_photos').select(...)/insert(...)/delete()... (M8, mirrors task_tags)
//   from('task_shopping_items').select(...).eq('task_id', ...).order(...).order(...)
//   from('task_shopping_items').insert(row).select(...).single()
//   from('task_shopping_items').update(row).eq('id', ...).select(...)
//   from('task_shopping_items').delete().eq('id', ...)
//   from('task_tools').select(...).eq('task_id', ...).order(...).order(...)
//   from('task_tools').insert(row).select(...).single()
//   from('task_tools').update(row).eq('id', ...).select(...)
//   from('task_tools').delete().eq('id', ...)
//   from('task_time_entries').select(...).eq('task_id', ...).order(...).order(...)
//   from('task_time_entries').select(...).eq('user_id', ...).is('ended_at', null)
//   from('task_time_entries').select(...).in('task_id', [...])
//   from('task_time_entries').insert(row).select(...).single()
//   from('task_time_entries').update(row).eq('id', ...).is('ended_at', null).select(...)
//   from('task_time_entries').update(row).eq('id', ...).not('ended_at', 'is', null).select(...)
//   from('task_time_entries').delete().eq('id', ...).not('ended_at', 'is', null).select(...)
//   from('activity_log').select(...).eq('farm_id',...).eq('task_id',...).order('created_at',{ascending:false})
//   from('farm_member_profiles').select(...).eq('farm_id',...).in('user_id',[...])
//
// It is not a general PostgREST emulator: no joins, no or(), no partial
// filter operators beyond eq/is/in. Keep it that way — generalizing further
// belongs in a real integration test against Supabase, not here.
//
// Storage is a similarly minimal fake: `.storage.from(bucketId)` returns an
// object supporting `.upload()`, `.remove()`, and `.createSignedUrl()`,
// backed by an in-memory Set of "uploaded" paths (see getStorageObjects()).
// No real file bytes, encoding, or signing — just enough to let service-layer
// tests assert on what got uploaded/removed and to fail on demand.

type TableName =
  | 'categories'
  | 'locations'
  | 'tasks'
  | 'activity_log'
  | 'tags'
  | 'task_tags'
  | 'task_completers'
  | 'task_photos'
  | 'task_shopping_items'
  | 'task_tools'
  | 'task_time_entries'
  | 'farm_member_profiles'
type Row = Record<string, unknown>

export interface FakeSupabaseSeed {
  categories?: Database['public']['Tables']['categories']['Row'][]
  locations?: Database['public']['Tables']['locations']['Row'][]
  tasks?: Database['public']['Tables']['tasks']['Row'][]
  activity_log?: Database['public']['Tables']['activity_log']['Row'][]
  tags?: Database['public']['Tables']['tags']['Row'][]
  task_tags?: Database['public']['Tables']['task_tags']['Row'][]
  task_completers?: Database['public']['Tables']['task_completers']['Row'][]
  task_photos?: Database['public']['Tables']['task_photos']['Row'][]
  task_shopping_items?: Database['public']['Tables']['task_shopping_items']['Row'][]
  task_tools?: Database['public']['Tables']['task_tools']['Row'][]
  task_time_entries?: Database['public']['Tables']['task_time_entries']['Row'][]
  // Not a real table (it's a view), but the fake doesn't need to model that
  // distinction — it just needs queryable rows.
  farm_member_profiles?: Database['public']['Views']['farm_member_profiles']['Row'][]
}

export interface FailSpec {
  table: TableName
  op: 'select' | 'insert' | 'update' | 'delete'
  message?: string
}

// Fail-injection for the storage fake, parallel to FailSpec but keyed by
// storage operation instead of table/op — storage isn't a Postgres table so
// it doesn't fit FailSpec's shape.
export interface StorageFailSpec {
  op: 'upload' | 'remove' | 'createSignedUrl'
  message?: string
}

interface StorageFailSpecInternal {
  op: 'upload' | 'remove' | 'createSignedUrl'
  message: string
}

interface FailSpecInternal {
  table: TableName
  op: 'select' | 'insert' | 'update' | 'delete'
  message: string
}

type QueryResult = {
  data?: unknown
  error: { message: string } | null
  count?: number | null
}

class FakeQueryBuilder implements PromiseLike<QueryResult> {
  private opType: 'select' | 'insert' | 'update' | 'delete' = 'select'
  private readonly filters: Array<(row: Row) => boolean> = []
  private insertPayload?: Row | Row[]
  private updatePayload?: Row
  private singleMode = false
  private countMode = false
  // Chained .order() calls accumulate as primary, secondary, ... sort keys,
  // matching PostgREST's multi-column ordering.
  private readonly orderKeys: Array<{ col: string; ascending: boolean }> = []
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

  insert(row: Row | Row[]): this {
    this.opType = 'insert'
    this.insertPayload = row
    return this
  }

  update(row: Row): this {
    this.opType = 'update'
    this.updatePayload = row
    return this
  }

  delete(): this {
    this.opType = 'delete'
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

  // Only the negated-is form is needed (`.not('ended_at', 'is', null)`,
  // time-entries.ts's running-entry guard) — no other `.not()` usage exists
  // in the services, so no other operator is implemented.
  not(column: string, operator: string, value: unknown): this {
    if (operator !== 'is') {
      throw new Error(
        `FakeSupabaseClient.not() only supports the 'is' operator (got '${operator}')`,
      )
    }
    this.filters.push((row) => row[column] !== value)
    return this
  }

  in(column: string, values: unknown[]): this {
    this.filters.push((row) => values.includes(row[column]))
    return this
  }

  order(column: string, options?: { ascending?: boolean }): this {
    this.orderKeys.push({ col: column, ascending: options?.ascending ?? true })
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
      const payloads = Array.isArray(this.insertPayload)
        ? this.insertPayload
        : [this.insertPayload ?? {}]
      const created = payloads.map((payload) => ({
        id: this.nextId(this.table),
        created_at: new Date().toISOString(),
        ...payload,
      }))
      rows.push(...created)
      if (!this.selectCols) return { data: null, error: null }
      const projected = created.map((row) => this.project(row))
      return this.singleMode
        ? { data: projected[0], error: null }
        : { data: projected, error: null }
    }

    if (this.opType === 'update') {
      const matches = rows.filter((row) => this.filters.every((f) => f(row)))
      for (const row of matches) Object.assign(row, this.updatePayload)
      return { data: matches.map((row) => this.project(row)), error: null }
    }

    if (this.opType === 'delete') {
      const matches = rows.filter((row) => this.filters.every((f) => f(row)))
      this.store[this.table] = rows.filter(
        (row) => !this.filters.every((f) => f(row)),
      )
      if (!this.selectCols) return { data: null, error: null }
      return { data: matches.map((row) => this.project(row)), error: null }
    }

    // select
    let matches = rows.filter((row) => this.filters.every((f) => f(row)))
    if (this.countMode) {
      return { count: matches.length, error: null, data: null }
    }
    if (this.orderKeys.length > 0) {
      matches = [...matches].sort((a, b) => {
        for (const { col, ascending } of this.orderKeys) {
          const cmp = String(a[col]).localeCompare(String(b[col]))
          if (cmp !== 0) return ascending ? cmp : -cmp
        }
        return 0
      })
    }
    return { data: matches.map((row) => this.project(row)), error: null }
  }
}

export class FakeSupabaseClient {
  private readonly store: Record<TableName, Row[]>
  private readonly failSpecs: FailSpecInternal[]
  private readonly storageFailSpecs: StorageFailSpecInternal[]
  private readonly storageObjects = new Set<string>()
  private readonly counters: Record<TableName, number> = {
    categories: 0,
    locations: 0,
    tasks: 0,
    activity_log: 0,
    tags: 0,
    task_tags: 0,
    task_completers: 0,
    task_photos: 0,
    task_shopping_items: 0,
    task_tools: 0,
    task_time_entries: 0,
    farm_member_profiles: 0,
  }

  constructor(
    seed: FakeSupabaseSeed = {},
    failOn?: FailSpec | FailSpec[],
    storageFailOn?: StorageFailSpec | StorageFailSpec[],
  ) {
    this.store = {
      categories: cloneRows(seed.categories as unknown as Row[] | undefined),
      locations: cloneRows(seed.locations as unknown as Row[] | undefined),
      tasks: cloneRows(seed.tasks as unknown as Row[] | undefined),
      activity_log: cloneRows(
        seed.activity_log as unknown as Row[] | undefined,
      ),
      tags: cloneRows(seed.tags as unknown as Row[] | undefined),
      task_tags: cloneRows(seed.task_tags as unknown as Row[] | undefined),
      task_completers: cloneRows(
        seed.task_completers as unknown as Row[] | undefined,
      ),
      task_photos: cloneRows(seed.task_photos as unknown as Row[] | undefined),
      task_shopping_items: cloneRows(
        seed.task_shopping_items as unknown as Row[] | undefined,
      ),
      task_tools: cloneRows(seed.task_tools as unknown as Row[] | undefined),
      task_time_entries: cloneRows(
        seed.task_time_entries as unknown as Row[] | undefined,
      ),
      farm_member_profiles: cloneRows(
        seed.farm_member_profiles as unknown as Row[] | undefined,
      ),
    }
    const specs = failOn ? (Array.isArray(failOn) ? failOn : [failOn]) : []
    this.failSpecs = specs.map((s) => ({
      table: s.table,
      op: s.op,
      message: s.message ?? `Simulated ${s.op} error on ${s.table}`,
    }))

    const storageSpecs = storageFailOn
      ? Array.isArray(storageFailOn)
        ? storageFailOn
        : [storageFailOn]
      : []
    this.storageFailSpecs = storageSpecs.map((s) => ({
      op: s.op,
      message: s.message ?? `Simulated ${s.op} error on storage`,
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

  /** Test-only escape hatch: paths currently "uploaded" in the fake bucket. */
  getStorageObjects(): string[] {
    return [...this.storageObjects]
  }

  get storage(): { from: (bucketId: string) => FakeStorageBucket } {
    return {
      from: (bucketId: string) =>
        new FakeStorageBucket(
          bucketId,
          this.storageObjects,
          this.storageFailSpecs,
        ),
    }
  }

  private nextId(table: TableName): string {
    this.counters[table] += 1
    return `${table}-${this.counters[table]}`
  }
}

class FakeStorageBucket {
  constructor(
    private readonly bucketId: string,
    private readonly objects: Set<string>,
    private readonly failSpecs: StorageFailSpecInternal[],
  ) {}

  private matchingFailure(
    op: StorageFailSpecInternal['op'],
  ): StorageFailSpecInternal | undefined {
    return this.failSpecs.find((f) => f.op === op)
  }

  async upload(
    path: string,
    _body: unknown,
    _options?: { contentType?: string },
  ): Promise<{
    data: { path: string } | null
    error: { message: string } | null
  }> {
    const failure = this.matchingFailure('upload')
    if (failure) return { data: null, error: { message: failure.message } }
    this.objects.add(path)
    return { data: { path }, error: null }
  }

  async remove(
    paths: string[],
  ): Promise<{ data: unknown; error: { message: string } | null }> {
    const failure = this.matchingFailure('remove')
    if (failure) return { data: null, error: { message: failure.message } }
    for (const path of paths) this.objects.delete(path)
    return { data: paths.map((path) => ({ name: path })), error: null }
  }

  async createSignedUrl(
    path: string,
    expiresIn: number,
  ): Promise<{
    data: { signedUrl: string } | null
    error: { message: string } | null
  }> {
    const failure = this.matchingFailure('createSignedUrl')
    if (failure) return { data: null, error: { message: failure.message } }
    return {
      data: {
        signedUrl: `https://fake-storage.test/${this.bucketId}/${path}?expires=${expiresIn}`,
      },
      error: null,
    }
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
