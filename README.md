# Chore Corral

A mobile-first web app for tracking maintenance and upkeep tasks across farm/homestead properties — built for the day-to-day "stuff that needs fixing" reality of running a property, not crop planning or compliance reporting.

Built as a hands-on agentic AI development project, with a deliberate frontend stack shift (Nuxt/Vue instead of Next/React) to broaden framework depth for portfolio purposes.

## Stack

Nuxt · Vuetify · Supabase (Postgres, Auth, Storage) · Vercel · VeeValidate + Zod · Leaflet + Mapbox Satellite

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for the full stack breakdown and rationale.

## Documentation

| Doc                                     | Purpose                                                                                                    |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| [SPEC.md](docs/SPEC.md)                 | Functional specification — what the app does, screen-by-screen behavior, field definitions, and edge cases |
| [DATA_MODEL.md](docs/DATA_MODEL.md)     | Database schema, table relationships, and Row Level Security policy intent                                 |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technical stack, rationale, and how the major pieces fit together                                          |
| [ROADMAP.md](docs/ROADMAP.md)           | Lightweight, directional list of future features beyond MVP                                                |
| [MILESTONES.md](docs/MILESTONES.md)     | Ordered, scoped build plan to reach MVP, with concrete done-states per milestone                           |
| [STATUS.md](docs/STATUS.md)             | Current build state — what's done, in progress, and known issues                                           |
| [DECISIONS.md](docs/DECISIONS.md)       | Running log of the reasoning behind non-obvious project decisions                                          |

## Getting Started

```
pnpm install
cp .env.example .env   # fill in Supabase URL/publishable key from Project Settings → API
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
