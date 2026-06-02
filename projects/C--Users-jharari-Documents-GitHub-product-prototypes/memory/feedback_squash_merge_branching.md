---
name: Always branch from main after a squash merge
description: Creating a new branch from a worktree that was squash-merged causes conflicts in the next PR
type: feedback
originSessionId: 070fb5d4-b33c-4a20-a9bb-d2aca4f220c2
---
After a PR is **squash-merged**, always fetch and branch from the updated `main` before starting new changes:

```bash
git fetch origin
git checkout main && git pull
git checkout -b update/<slug>-<feature>
```

**Why:** Squash merge rewrites history — the original commits no longer exist in `main`. If you branch from the old worktree instead, GitHub sees those commits as divergent and marks the new PR as conflicted, requiring manual resolution.

**How to apply:** Every time the user says "merged" or "PR merged", treat the current worktree branch as stale. Always run the three commands above before touching any file for the next change.
