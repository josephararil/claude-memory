---
name: ship
description: Ship a feature — branch, implement, verify in browser, update CLAUDE.md, open PR
argument-hint: [feature description]
allowed-tools: [Read, Edit, Write, Bash, Glob, Grep]
---

# ship

Ship a feature: branch → implement → verify → update CLAUDE.md → PR.

## Steps

1. **Branch** — create a feature branch from main. Never commit directly to main.
2. **Implement** — make the requested change.
3. **Verify** — start the dev server if needed, hard-refresh to bust PWA cache, confirm the change looks correct in the browser preview.
4. **Update CLAUDE.md** — if the change affects architecture, conventions, or new screens/services, update CLAUDE.md in the same commit or as a follow-up commit on the same branch.
5. **PR** — commit all changes and open a pull request with a clear title and description of what changed and why.
6. **Merge** — where the repo's CLAUDE.md authorizes auto-merge, merge to main yourself once CI is green. Otherwise leave the PR open and say so.

## Rules

- If no feature description was given, ask before starting.
- Never skip the CLAUDE.md update step — even a one-line note counts.
- Never skip cache-busting during verification (hard-refresh or service worker update).
- Always open a PR at the end; do not leave work on a branch without a PR.
- Get the title and body right on `gh pr create`. Do not spend turns amending PR metadata afterwards — `gh pr edit` often fails on the deprecated `projectCards` field, and the commit messages are the record that actually gets read. If scope grows after the PR is open, add a commit rather than editing the body.
