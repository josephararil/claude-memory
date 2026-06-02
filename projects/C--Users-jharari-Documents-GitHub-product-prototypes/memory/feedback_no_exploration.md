---
name: Do not explore the repo
description: Reading Dockerfile, CI files, and other prototype dirs wastes tokens; CLAUDE.md has everything needed
type: feedback
originSessionId: 0936da68-eed2-49a1-8795-9a9a4fa19471
---
Do NOT read these files — everything needed to write a prototype is in CLAUDE.md:
- `Dockerfile`, `nginx.conf`, `package.json`, `package-lock.json`
- `.github/` CI workflow files
- Any `prototypes/*/` directory other than the one being worked on

**Why:** The user explicitly flagged this as unnecessary token burn. One session read the Dockerfile, omnius-ai-mobile files, and multiple CI workflow files before writing a single line of prototype code — all wasted context.

**How to apply:** On any new prototype task, go directly to writing the three files (`index.html`, `script.js`, `manifest.json`), run the two lint commands from CLAUDE.md §10, commit, and push. No exploration needed.
