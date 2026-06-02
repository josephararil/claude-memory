---
name: feedback_git_push
description: User has authorized pushing directly to main and merging without asking for confirmation in the storybooks repo
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3273b528-4f51-4c39-9afb-9d2ef865ad56
---

Push directly to `main` and merge without asking for confirmation — no PR required.

**Why:** User explicitly granted this authorization for the storybooks repo.

**How to apply:** After committing changes, run `git push` without pausing to ask permission. Do not create PRs unless the user requests one.
