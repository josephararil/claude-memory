---
name: plan
description: Produce a scoped implementation plan only — no code changes. Plan a feature with the user, write it to ~/.claude/plans, and hand off to /build to implement it.
argument-hint: [feature or task description]
allowed-tools: [Read, Glob, Grep, Write, AskUserQuestion]
---

# plan

Produce an implementation plan. Do NOT edit or create any files **other than the plan file itself**,
and do NOT run any state-changing commands. Implementation happens later, in `/build`.

## Instructions

1. **Restate scope** — in bullets, list every distinct feature or change you understand to be in
   scope from the user's request and `$ARGUMENTS`. If design decisions are open (defaults, UX
   direction, scope tradeoffs), use `AskUserQuestion` with concrete multi-choice options rather than
   open chat questions — it surfaces tradeoffs faster. Read tools are allowed to understand the
   codebase.

2. **Wait for confirmation** — do not proceed until the user explicitly confirms the scope. If the
   user said "go" in the same message that invoked this skill, still confirm scope first.

3. **Write the plan** to `~/.claude/plans/<short-slug>.md`, structured as:
   - **Context** — why this change, what prompted it, intended outcome
   - **Changes** — grouped by feature area; for each, name the file(s) and what to do
   - **Critical files** — every file to be created or modified
   - **Existing utilities to reuse** — functions/components to call instead of reinventing, with paths
   - **Out of scope** — what is explicitly not being done this pass
   - **Branch** — the feature branch name `/build` should create off main (e.g. `feat/<slug>`)
   - **Verification** — end-to-end checks to run before the PR; mark which ones need a human (visual
     or UI behavior, production-only paths, external services) so `/build` knows to delegate them
   - **Implementation sessions** — see step 4

4. **Write the implementation sessions** — append a section titled `## Implementation sessions`.
   Break the work into sequentially-ordered, independently-shippable sessions (build new before
   removing old; never leave the tree broken between sessions). `/build` will feed each of these to a
   fresh Sonnet subagent that **starts from an empty context and sees only its own prompt string** —
   it does not inherit the planning conversation or the other sessions. So every session prompt MUST
   be fully self-contained:
   - Open with: this is one step of a larger plan; `Read ~/.claude/plans/<slug>.md first`
   - Name the exact files to create/modify and what to do in each — lifted from the plan, not just
     referenced (assume the subagent won't infer it)
   - State which prior sessions must already be committed
   - Restate the relevant constraints (match existing patterns, no build step if applicable, update
     CLAUDE.md, commit but do not push — the branch already exists, `/build` created it)
   - End with explicit verification steps and the success criteria for that session
   Number them (Session 1, Session 2, …). Present them in the chat reply too, not only in the file.

5. **Stop** — end with: "Plan written to `<path>`. Run **/build** when you want me to implement it —
   in this session or a fresh one — or paste a session into a Sonnet tab to drive it yourself."

## Rules

- No file edits or creation except the plan file in `~/.claude/plans/`.
- No shell commands that modify state.
- Read tools are allowed, to understand the codebase.
- Do not begin implementation here; that is `/build`'s job.
- Always finish by writing the implementation sessions (step 4) — a plan without self-contained
  session prompts is incomplete, because `/build` has nothing to feed the subagents.
- If the feature is large enough that you'd want to fan out *parallel research* to understand it,
  this skill is too thin for that — tell the user and offer Claude Code's plan mode (Explore/Plan
  subagents, structured 5-phase workflow) for the investigation, then come back here to write the plan.
