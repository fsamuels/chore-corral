# Chore Corral — Working Notes

## Branch workflow

- Never branch directly off local `main` — always start new work with `/new-branch`, which branches off the latest `origin/main`.
- Branch naming convention:
  - `milestone/m<N>-<slug>` — e.g. `milestone/m1-scaffold-deploy`
  - `feature/<slug>` — e.g. `feature/task-tag-autocomplete`
  - `fix/<slug>` — e.g. `fix/overdue-flag-timezone`
  - `docs/<slug>` — documentation or process/tooling-only changes (no app code), e.g. `docs/codify-process-for-claude`
- Before opening a PR, run `/create-pr` — it updates docs (especially `docs/STATUS.md`) to reflect the branch's changes, runs prettier/lint/typecheck/build, then pushes and opens the PR. Don't run `git push` + `gh pr create` manually; use the skill so docs stay in sync.
- **Automated/remote sessions (Claude Code on the web, GitHub Actions, etc.) may pre-assign a branch** (e.g. `claude/<slug>-<suffix>`) before `/new-branch` ever runs, along with a system-level instruction not to push elsewhere without explicit permission. That platform instruction takes precedence over the naming convention above — don't fight it silently. If it happens, say so out loud and ask whether to proceed on the pre-assigned branch or rename/recreate under the convention; don't just pick one and stay quiet about the mismatch.

See [docs/](docs/) for the full doc set (SPEC, ARCHITECTURE, DATA_MODEL, ROADMAP, MILESTONES, STATUS, DECISIONS).
