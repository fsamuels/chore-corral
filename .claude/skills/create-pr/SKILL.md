---
name: create-pr
description: Bring project docs up to date with the current branch's changes, run prettier and other repo checks, then push and open a PR against main.
argument-hint: [optional extra context for the PR description]
disable-model-invocation: true
allowed-tools: Bash(git *) Bash(gh pr create *) Bash(gh pr view *) Bash(npx prettier *) Bash(npm run *) Bash(npm ci *) Bash(cat *)
---

# Create PR

Prepare the current branch for review: bring documentation up to date, run checks, then push and open a PR. The goal is that once this PR merges, `docs/STATUS.md` and the other docs are **already accurate** — no separate doc-catchup pass needed later.

## Steps

1. **Sanity check.** Confirm the current branch isn't `main` (`git branch --show-current`); if it is, stop and tell the user to run `/new-branch` first.

2. **Fetch and diff against main:**

   ```
   git fetch origin main
   git log origin/main..HEAD --oneline
   git diff origin/main...HEAD --stat
   git diff origin/main...HEAD
   ```

   Read the actual diff, not just the file list — doc updates need to reflect what really changed.

3. **Update documentation to match the changes.** Check each of these and edit only what's actually stale:
   - **[docs/STATUS.md](../../../docs/STATUS.md)** — always review this one. Update "Last updated" to today's date, "Current Phase", the Milestone Progress table (mark a milestone row "In Progress" or "Done" if this branch's work matches its done-state in MILESTONES.md), "Known Issues", and "Next Steps". This file must reflect reality _after_ merge, not before.
   - **[docs/MILESTONES.md](../../../docs/MILESTONES.md)** — only if scope for a milestone actually changed (rare; this is the plan, not a progress tracker).
   - **[docs/DECISIONS.md](../../../docs/DECISIONS.md)** — append a new entry only if a genuinely non-obvious choice was made during implementation (not for routine/expected work). Follow the existing entries' format: heading, then the reasoning and tradeoffs.
   - **[docs/DATA_MODEL.md](../../../docs/DATA_MODEL.md)** — update if the schema changed.
   - **[docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md)** — update if the stack or how pieces fit together changed.
   - **[README.md](../../../README.md)** — update "Getting Started" if setup/run steps changed.
     Don't pad these with restating the diff — only change what's now inaccurate or missing.

4. **Run repo checks**, adapting to whatever's actually configured (the project may still be pre-scaffold with no `package.json` — skip gracefully and note that in the summary rather than failing):
   - If `package.json` exists: check its `scripts` for `format`/`format:fix` and run it; otherwise if `prettier` is a dependency, run `npx prettier --write .`.
   - Run `lint` script if present.
   - Run `typecheck` script if present.
   - Run `build` script if present.
   - **If any check fails, stop.** Report the failure to the user and do not push or open a PR with a broken build.

5. **Commit.** Stage the doc updates and any files prettier/lint auto-fixed, and create a new commit (never amend). Use a HEREDOC commit message describing what was brought up to date, per standard commit conventions.

6. **Push:** `git push -u origin HEAD`.

7. **Open the PR:**

   ```
   gh pr create --base main --title "<title>" --body "$(cat <<'EOF'
   ## Summary
   <bullets>

   ## Docs updated
   <list files touched in step 3, or "None needed">

   ## Checks
   <list what ran and passed, or "Skipped — no package.json yet">
   EOF
   )"
   ```

   Derive the title from the branch name/commits. Fold in any extra context from `$ARGUMENTS` if provided.

8. **Report the PR URL** back to the user.
