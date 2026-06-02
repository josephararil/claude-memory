---
name: Prototypes platform overview
description: How the product-prototypes repo works — build pipeline, file structure, deploy path
type: project
originSessionId: 0936da68-eed2-49a1-8795-9a9a4fa19471
---
Static React prototypes served at https://prototypes.tradu.fun/. Each prototype lives at `prototypes/<slug>/` with three files: `index.html`, `script.js`, `manifest.json`.

Build pipeline (CI/Docker):
- `esbuild` bundles each `script.js` in-place: `--bundle --loader:.js=jsx --jsx=automatic --format=iife --minify --allow-overwrite`
- Only `react` and `react-dom` are in `package.json` — no other npm imports allowed
- nginx serves the built files; deploy takes ~3-5 min after merge to main

**Why:** Branch protection requires the `lint` CI job to pass before merge. Squash-merge is the only merge strategy allowed.

**How to apply:** Write only the three files. Run local validation (§10 of CLAUDE.md) before committing. No local dev server is needed or useful.
