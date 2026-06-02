---
name: Tennis coach PWA overview
description: Quick orientation for the tennis project before starting any work
type: project
originSessionId: 4d611510-21fa-44b8-a706-2f10f9f846e6
---
PWA for tennis coach Martina Gledacheva — court-side CRM and lesson planner. Deployed at https://jharari.github.io/tennis/ (base URL `/tennis/`).

**CLAUDE.md is the source of truth.** It is comprehensive — read it first on every session start. No need to explore Dockerfiles, CI files, or other infrastructure.

## Tech stack (quick ref)
- React + TypeScript, Vite, vite-plugin-pwa (generateSW mode), Zustand, Dexie/IndexedDB
- All CSS in `src/styles.css` — no CSS modules, no Tailwind, no styled-components
- All domain types centralised in `src/types.ts`
- All shared UI in `src/components/ui/index.ts` barrel

## Hard constraints (do not break)
- Lesson duration is hardcoded to **60 minutes** everywhere — no duration selector exists or should be added
- Client model uses `ntrp` (1.0–7.0 scale), `hasRacket` (boolean), `ballType` ('red'|'orange'|'green'|'yellow') — never reintroduce a `gear` string field
- `archetypeId` is auto-derived from playerType + NTRP; never set it manually in UI

## User context
- User tests on iPhone — iOS PWA installability matters (IosInstallHint component in Settings shows install steps)
- After making significant architectural or convention changes, update CLAUDE.md to reflect them

## Key files
- `src/App.tsx` — router + sheet orchestration
- `src/store/index.ts` — Zustand store (six slices; never split)
- `src/services/db.ts` — Dexie/IndexedDB (clients, notes, lessons, settings)
- `src/screens/AddClient.tsx` — add-client form with NTRP slider and equipment chips
- `src/screens/Profile.tsx` — client profile with delete flow (Dexie transaction)
- `src/services/lessonAi.ts` — Gemini 2.0 Flash integration with fallback
