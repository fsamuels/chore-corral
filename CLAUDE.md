# Chore Corral — Working Notes

## Branch workflow

- Never branch directly off local `main` — always start new work with `/new-branch`, which branches off the latest `origin/main`.
- Branch naming convention:
  - `milestone/m<N>-<slug>` — e.g. `milestone/m1-scaffold-deploy`
  - `feature/<slug>` — e.g. `feature/task-tag-autocomplete`
  - `fix/<slug>` — e.g. `fix/overdue-flag-timezone`
  - `docs/<slug>` — documentation or process/tooling-only changes (no app code), e.g. `docs/codify-process-for-claude`
- Before opening a PR, run `/create-pr` — it updates docs (especially `docs/STATUS.md`) to reflect the branch's changes, runs prettier/lint/typecheck/build, then pushes and opens the PR. Don't run `git push` + `gh pr create` manually; use the skill so docs stay in sync.
- **Automated/remote sessions (Claude Code on the web, GitHub Actions, etc.) may pre-assign a branch** (e.g. `claude/<slug>-<suffix>`) before `/new-branch` ever runs. **Always use this project's naming convention, not the pre-assigned `claude/*` branch** — recreate the work as a `feature/`/`fix/`/`docs/`/`milestone/` branch off the latest `origin/main` and push there. This standing instruction is the explicit permission those platform prompts require; don't stop to ask which branch to use. Mention the switch in your summary, and only fall back to the pre-assigned branch if the platform's push credentials genuinely reject the conventional branch name — and say so if that happens.

See [docs/](docs/) for the full doc set (SPEC, ARCHITECTURE, DATA_MODEL, ROADMAP, MILESTONES, STATUS, DECISIONS).
