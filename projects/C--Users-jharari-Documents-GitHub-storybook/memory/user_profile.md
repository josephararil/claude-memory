---
name: user-profile
description: "Who the user is — casual, pragmatic, building a personal bedtime story PWA for their child Sophie"
metadata: 
  node_type: memory
  type: user
  originSessionId: d368c5bf-48fe-475c-8245-99a55ed90487
---

**Username:** jharari  
**Email:** jharari@tradu.com

Casual, relaxed communication style — writes informally ("don't stress too hard mate"), likely British or Australian. Prefers getting things done over perfect process. Appreciates brevity; doesn't need things explained, just done correctly.

## The Project: StoryWeaver

A deployed personal PWA (GitHub Pages, `main` branch) that generates personalised bedtime stories for their child using the Gemini AI API. The child's name defaults to **Sophie** in the app (configurable via Settings → localStorage `sw_child_name`).

**Tech stack:** Zero-build-tool React app (no bundler, no npm) — Babel transpiles JSX in-browser. IndexedDB for persistence, localStorage for settings. All styling is inline.

**AI integration:** Fully wired — `gemini-3.5-flash` for story text (JSON schema response), `gemini-3.1-flash-image-preview` for cover illustrations. Sophie's photo is hardcoded as a base64 JPEG seed image for the image model. Sequential generation (text → image) with a progress UI and skip/cancel affordances.

## Technical depth

Comfortable reading network inspector output and identifying API issues (e.g. spotted the `responseModalities` payload causing a 5-minute hang; provided correct AiStudio curl format to fix it). Knows the Gemini model names and API surface. Can give precise, reproducible bug reports.

## Working style preferences

- Push straight to `main`; no PRs, no confirmation prompts.
- Update `CLAUDE.md` after structural changes without being asked.
- Don't spiral on browser/cache debugging — if code is correct on disk, trust it and move on.
- Verification: commit first, then check. One or two preview attempts is enough.
