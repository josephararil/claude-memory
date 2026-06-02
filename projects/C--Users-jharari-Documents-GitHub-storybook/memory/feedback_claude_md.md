---
name: feedback-claude-md
description: Always update CLAUDE.md after structural changes without waiting to be asked
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d368c5bf-48fe-475c-8245-99a55ed90487
---

Update CLAUDE.md whenever you make structural changes — new files, new state, new API methods, new routing, changed data shapes — without waiting to be asked.

**Why:** The user explicitly asked for a reminder line in CLAUDE.md itself ("always remind you to update it without being prompted"). This is a standing instruction, not a one-off.

**How to apply:** At the end of any PR/commit that changes architecture, wiring, or data shapes, also commit an updated CLAUDE.md. If the change is minor (a bug fix, style tweak), skip it. When in doubt, update.
