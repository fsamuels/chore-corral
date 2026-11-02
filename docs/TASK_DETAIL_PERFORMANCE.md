# Chore detail page — load performance

Investigation of `/tasks/:id` (`app/pages/tasks/[id]/index.vue`), done 2026-11-02. The case the user reported as slow is **tapping a chore in the app** (client-side navigation), not a direct load or refresh, so this write-up focuses on that case.

The counts below are **database round trips (RTT)**, read from the code. Nothing was timed against a live Supabase project. One RTT from a phone is typically 50–200 ms, so each step removed from the critical path is a noticeable gain.

## Before

On an in-app tap, `farms` is already cached (`useFarms` keeps it in `useState`), so neither the membership middleware nor the page's `fetchFarms()` costs a round trip. Everything else ran in this order, and **the previous page stayed on screen the whole time** because the page `await`ed it all in `<script setup>`:

| Step                                                               | Queries                                                                                 | RTT on the critical path |
| ------------------------------------------------------------------ | --------------------------------------------------------------------------------------- | ------------------------ |
| 1. `Promise.all` of task + categories + tags + locations + members | `getTask` = task row, then tags, then completers, then assignees, **one after another** | 4                        |
| 2. `fetchActivity()`, started only after step 1                    | activity rows, then member profiles                                                     | 2                        |
| — page renders —                                                   |                                                                                         | **6**                    |
| 3. Section components mount and fetch                              | photos (list, then signed URLs), shopping, tools, reminders, timer (all in parallel)    | 2                        |
| — fully loaded —                                                   |                                                                                         | **8**                    |

## Changed in this branch

1. **Render first, load second** (see DECISIONS.md D-5). On in-app navigation the page renders immediately with `TaskDetailSkeleton`, a placeholder shaped like the page. The await stays for SSR and hydration.
2. **`getTask` runs its three lookups in parallel** (tags, completers, assignees), the same way `listTasks` already did. This saves 2 RTT.
3. **Activity starts with the initial load** instead of after it. It needs only the task id, not the loaded task. This saves 2 RTT.
4. **Section skeletons.** Photos, shopping list, tools, reminders, timer and activity show `SectionSkeleton` placeholders instead of a spinner, so the cards hold roughly their final height while loading.
5. **Overlapping fetches can't overwrite newer data.** `fetchTask`, `fetchActivity` and `fetchMembers` only accept the reply to the most recently started request. Requests overlap when a `?farm=` link switches farms during the initial load, and after inline saves.

Moving from one chore to another needs no special handling. Nuxt keys pages by their path with params filled in (`/tasks/<id>`), so each chore gets a fresh page instance and starts on the skeleton.

**Kept on purpose:** activity is fetched alongside the task even though the chore might not exist. That wastes two queries on a "Chore not found" link (rare) and saves two round trips on every normal open.

After:

| Milestone                       | RTT                                     |
| ------------------------------- | --------------------------------------- |
| Something on screen (skeleton)  | **0** (was 6, with the old page frozen) |
| Chore content visible           | **2** (was 6)                           |
| Fully loaded, sections included | **4** (was 8)                           |

## Not done: follow-ups worth considering

Ordered by expected payoff relative to risk.

1. **Start the section fetches with the page instead of after it** (−2 RTT to fully loaded). Photos, shopping, tools, reminders and the timer each fetch from their own composable, and those composables only run once their components mount, which happens after the task loads. The page knows the task id from the route, so it could call those composables itself and pass the state down, or mount the sections inside the skeleton. Cost: those five components change from owning their state to receiving it. Moderate refactor.
2. **Seed the page from the list's data** (content shows at 0 RTT). The chores and home lists already hold a full `TaskSummary` for the tapped chore. Caching it (for example `useState('task-<id>')`) would let the detail page render instantly and refresh in the background. Cost: a shared cache and its invalidation rules, plus the possibility of briefly showing slightly stale data. Worth it if (1) isn't enough.
3. **Cache categories, tags, locations and members per farm** (−1 query each per visit). They're plain `ref`s, refetched on every visit to the page. Holding them in `useState` per farm, the way `useFarms` already does, would skip four queries on repeat visits. They're small and rarely change, but other pages edit them, so those edits would need to refresh the cache.
4. **Activity: reuse the page's member list** (−1 RTT on activity). `listActivityForTask` fetches `farm_member_profiles` again after the activity rows, but the page already loads the same profiles. Passing them in would turn activity into a single query. Small service signature change.
5. **Photo signed URLs** (−1 RTT on photos). `useTaskPhotos` lists the photos and then requests signed URLs, which takes two round trips. This one is inherent unless the bucket goes public or the list is cached. Low priority.
6. **Bundle size (not measured).** The page is about 1,900 lines and pulls in Vuetify's date picker, timeline and dialogs. `TaskLocationPreview` (Leaflet) is already client-only. `NuxtLink` prefetches the page chunk when a card scrolls into view, so JS download is probably not the bottleneck on repeat use. Run `nuxi analyze` before spending time here.

## Behaviour changes to note

- **Members:** a failed `fetchMembers()` used to reject the page's top-level `Promise.all`, which crashed the page. Now `fetchMembers` catches its own error into `membersError`. The page shows a warning above the Assigned-to picker and loads everything else. The farm-switch refetch is covered the same way.
- **Initial load:** on the client nothing awaits the initial load, so it has a backstop `catch`. If a fetch that doesn't catch its own errors is ever added, the page shows "Couldn't load chore" with "Try again" instead of failing silently.
