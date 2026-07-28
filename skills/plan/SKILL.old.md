---
name: plan
description: Produce a scoped implementation plan only — no code changes until explicitly told to proceed
argument-hint: [feature or task description]
allowed-tools: [Read, Glob, Grep, AskUserQuestion, Write]
---

# plan

Produce an implementation plan. Do NOT edit or create any files **other than the plan file itself**. Do NOT run any commands that change state.

## Instructions

1. **Restate scope** — in bullet form, list every distinct feature or change you understand to be in scope based on the user's request and `$ARGUMENTS`. Ask the user to confirm before continuing. If multiple design decisions are open (default values, UX direction, scope tradeoffs), use `AskUserQuestion` with concrete multi-choice options rather than open chat questions — it surfaces tradeoffs faster.

2. **Wait for confirmation** — do not proceed until the user explicitly confirms the scope is correct.

3. **Write the plan** to `~/.claude/plans/<short-slug>.md`. Structure it as:
   - **Context** — why this change, what prompted it, intended outcome
   - **Changes** — grouped by feature area; for each, name the file(s) and what to do. Include verify lines for each group, or a dedicated Verification section at the end
   - **Critical files** — bulleted list of every file that will be modified or created
   - **Existing utilities to reuse** — functions/components the implementer should call instead of reinventing (with file paths)
   - **Out of scope** — what is explicitly NOT being done this pass
   - **Verification** — end-to-end checks the implementer should run before opening a PR
   - **Implementation prompts (for Sonnet)** — see step 4

4. **Write implementation prompts** — append a final section to the plan file titled `## Implementation prompts (for Sonnet)`. Break the work into sequentially-ordered, independently-shippable sessions (build new before removing old; never leave the tree broken between sessions). For each session write a **complete, self-contained prompt** the user can paste into a fresh Sonnet session. Each prompt MUST:
   - State up front that it's one step of a larger plan and point to the plan file by absolute path (`Read <path> first`)
   - Name the exact files to create/modify and what to do in each (lifted from the plan, not just referenced — assume Sonnet may not re-read the whole plan)
   - List the prior sessions it depends on (what must already be merged)
   - Restate the relevant constraints from CLAUDE.md (branch off main, open a PR, no build step, match existing patterns, update CLAUDE.md)
   - End with explicit verification steps and the success criteria for that session
   - Be wrapped in a fenced code block so it's copy-pasteable verbatim
   Present the same prompts in the chat reply too, not only in the file.

5. **Stop** — end with: "Plan written to `<path>`. Say **go** when you want me to start, or paste an implementation prompt into a fresh session."

## Rules

- No file edits or creation except the plan file in `~/.claude/plans/`
- No shell commands that modify state
- Read tools are allowed to understand the codebase
- Do not begin implementation until the user says "go" or equivalent
- Always finish by writing the implementation prompts (step 4) — a plan without copy-pasteable Sonnet prompts is incomplete
- If the user says "go" in the same message as invoking this skill, still confirm scope first
- If scope is large enough that you'd want to fan out parallel research, this skill is too thin — recommend the user switch to Claude Code's plan mode (which provides Explore/Plan subagents and a structured 5-phase workflow)
