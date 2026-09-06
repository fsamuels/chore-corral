# Chore Corral

A mobile-first web app for tracking maintenance and upkeep tasks across farm/homestead properties — built for the day-to-day "stuff that needs fixing" reality of running a property, not crop planning or compliance reporting.

**[See it live →](https://chore-corral.vercel.app/landing)**

Built as a hands-on agentic AI development project, with a deliberate frontend stack shift (Nuxt/Vue instead of Next/React) to broaden framework depth for portfolio purposes.

## Stack

Nuxt · Vuetify · Supabase (Postgres, Auth, Storage) · Vercel · VeeValidate + Zod · Leaflet + Mapbox Satellite

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full stack breakdown and rationale.

## Documentation

| Doc                                     | Purpose                                                                                                    | Changes               |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------- | --------------------- |
| [SPEC.md](docs/SPEC.md)                 | Functional specification — what the app does, screen-by-screen behavior, field definitions, and edge cases | Rarely                |
| [DATA_MODEL.md](docs/DATA_MODEL.md)     | Database schema, table relationships, and Row Level Security policy intent                                 | With schema changes   |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technical stack, rationale, and how the major pieces fit together                                          | Occasionally          |
| [ROADMAP.md](docs/ROADMAP.md)           | Lightweight, directional list of future features beyond MVP                                                | Occasionally          |
| [MILESTONES.md](docs/MILESTONES.md)     | Ordered, scoped build plan to reach MVP, with concrete done-states per milestone                           | Rarely                |
| [STATUS.md](docs/STATUS.md)             | Current build state — what's done, in progress, and known issues                                           | Every merged PR       |
| [DECISIONS.md](docs/DECISIONS.md)       | Running log of the reasoning behind non-obvious project decisions                                          | As decisions are made |

## Getting Started

```
pnpm install
cp .env.example .env   # fill in Supabase URL/publishable key from Project Settings → API;
                       # optionally a Mapbox token for satellite tiles (OSM-only without it)
pnpm dev
```

Other scripts: `pnpm lint`, `pnpm typecheck`, `pnpm test`, `pnpm build`.

### Database migrations

The schema lives in versioned migration files under `supabase/migrations/`, managed with the Supabase CLI. To apply pending migrations to the hosted project (one-time `link`, then `push` as needed):

```
npx supabase link --project-ref <project-ref>   # ref from the Supabase dashboard URL
npx supabase db push
```

Automating this in the deploy pipeline is a planned improvement — see [ROADMAP.md](docs/ROADMAP.md).

### Running against local Supabase

For work that shouldn't touch the hosted project (schema experiments, load/perf testing, seeding
throwaway data), the Supabase CLI can run the full stack locally via Docker:

```
supabase start                          # applies supabase/migrations/ automatically
```

Point `.env` (or inline env vars) at the printed `API_URL`/`ANON_KEY` instead of the hosted
project's. **Gotcha:** a bare `supabase start` does not grant the `anon`/`authenticated` roles the
standard table privileges that the hosted project has set up automatically since creation — this
repo's migrations never grant them explicitly (by design: they rely on the platform doing it, then
RLS policies filtering rows on top). Without this, every query from the app's normal auth role
fails with `42501 permission denied`, but the app doesn't surface it loudly — pages still render
(session/auth checks pass), just with everything silently empty, which can look like "it's just
slow" or "there's no data" rather than a permissions error. Fix once per fresh local instance:

```sql
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO anon, authenticated;
```

(e.g. via `docker exec -i supabase_db_chore-corral psql -U postgres -d postgres < grants.sql`). The
same applies to `service_role` (`GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;`) for
any admin-client seeding script. Verify it actually worked by confirming a real authenticated query
returns rows — not just that the page loads without an error.
