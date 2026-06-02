---
name: feedback-create-pr
description: Always run /create-pr automatically at end of a session; never wait for the user to click it
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4404df6e-d43d-48d1-a144-a06008867fdd
---

Always run `/create-pr` automatically when a session's work is complete and committed. Do not prompt the user to click it or suggest they run it themselves.

**Why:** User finds it unnecessary friction to have to trigger the PR step manually.

**How to apply:** After the final commit of any work session, immediately push the branch and open the PR without asking. If a PR already exists for the branch, just push and report the existing URL.
