---
name: utop-dealing prototype
description: UTOP Dealing UI MVP — dealer view for house risk monitoring, current feature state
type: project
originSessionId: 070fb5d4-b33c-4a20-a9bb-d2aca4f220c2
---
Live at https://prototypes.tradu.fun/utop-dealing/ (last updated 2026-04-29).

**What it is:** Dealer-facing UI for Tradu's dealing desk. A dealer searches for a customer account and views their open positions and account summary in real time (simulated WebSocket ticking every 650ms).

## Current features (as of 2026-04-29)

**Open Positions blotter (FR-OPS-001)**
- Default columns: ID, Instrument, Side, Open Price, Current Price, Qty (lots), Unr. P&L, Close button
- Expandable columns toggle ("More columns" button with ISliders icon): Opened, Stop Loss, Take Profit, Used Margin, Rollover
  - SL/TP show `—` when null; SL in rose, TP in emerald, Rollover in amber
  - Used Margin per row = `qty × $2,000`; sum equals account-level Used Margin
  - Table has `overflow-x-auto` for horizontal scroll when expanded
- Cell flash animation: `@keyframes cellFlash` (filter brightness 2.4→1, 0.9s ease-out) triggered by React `key` remounting on each value change. Applies to Current Price and Unr. P&L cells only. NOT a CSS transition (transitions don't fire reliably when transition+color change in the same render).

**Account summary panel**
- Balance, Equity, Used Margin, Free Margin, Margin Level
- Margin Level formula: `1 - (Free Margin / Equity)` as %. 0% = safe, 100% = fully leveraged. Green <50%, amber 50–80%, red >80%. Fill bar.

**Sidebar footer**
- Build 2026-04-29
- PRD ↗ (links to Confluence PRD page)
- Feedback ↗ (links to Jira feedback form: https://tradu.atlassian.net/jira/core/projects/TPD/form/67)
- Colors: gray-500 (#6b7280) at rest, gray-400 (#9ca3af) on hover — must be this light to be visible on #080c12 background

**Other tabs**
- Customers tab: account picker (search by ID/label), currently one account AC-12345 (House Account)
- Instruments tab: G10 FX pairs, inline edit + bulk update, validation
- Audit Log tab: immutable log, CSV download via `data:` URI
- ARM status pill: cycles Connected → Reconnecting → Disconnected on click
- WS toggle: simulates connection loss banner

**PRD:** https://tradu.atlassian.net/wiki/spaces/TPD/pages/207388686/PRD+Dealing+UI+MVP (requires Atlassian auth)

**How to apply:** When making changes, read the current `script.js` on main first — it is the source of truth. Don't re-derive architecture from scratch.
