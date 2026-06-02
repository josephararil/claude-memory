---
name: feedback-git-push
description: "Git workflow: all work via feature branches + PR merged to main; never push directly to main"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cadcb1a6-e44d-4ba7-90e9-d9ce725d602e
---

All work MUST go through a feature branch. Never push directly to `main`.

Workflow: create feature branch → commit → push branch → `gh pr create` → `gh pr merge` (no approval needed).

**Why:** User explicitly requires this — direct pushes to main are not acceptable even when no approval is required for the merge.

**How to apply:** Always start from main with `git checkout -b <branch-name>`. After finishing, push the branch, open a PR, and merge it immediately with `gh pr merge <number> --merge`. Do not use `git push origin main` or `--force` anything to main directly. See also [[feedback-create-pr]].
