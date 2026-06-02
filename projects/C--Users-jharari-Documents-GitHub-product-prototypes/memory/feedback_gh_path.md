---
name: gh CLI full path in bash
description: gh is not in bash PATH on this machine; must use full Windows path
type: feedback
originSessionId: 0936da68-eed2-49a1-8795-9a9a4fa19471
---
`gh` is not on the bash PATH. Use the full path: `/c/Program Files/GitHub CLI/gh.exe`

**Why:** Discovered when `gh pr create` returned command-not-found in bash even though gh is installed system-wide.

**How to apply:** Any time a bash command needs gh, prefix with the full path. PowerShell also doesn't find it via `gh` alone (`where.exe gh` returns nothing in the normal session).
