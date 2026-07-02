# Chore Corral — Working Notes

## Branch workflow

- Never branch directly off local `main` — always start new work with `/new-branch`, which branches off the latest `origin/main`.
- Branch naming convention:
  - `milestone/m<N>-<slug>` — e.g. `milestone/m1-scaffold-deploy`
  - `feature/<slug>` — e.g. `feature/task-tag-autocomplete`
  - `fix/<slug>` — e.g. `fix/overdue-flag-timezone`
- Before opening a PR, run `/create-pr` — it updates docs (especially `docs/STATUS.md`) to reflect the branch's changes, runs prettier/lint/typecheck/build, then pushes and opens the PR. Don't run `git push` + `gh pr create` manually; use the skill so docs stay in sync.

See [docs/](docs/) for the full doc set (SPEC, ARCHITECTURE, DATA_MODEL, ROADMAP, MILESTONES, STATUS, DECISIONS).
