---
name: build
description: Implement a locked plan from /plan — orchestrate Sonnet subagents one session at a time on a feature branch, review the whole branch, and open a PR. Spawns subagents and changes state, so it runs only after the plan is approved.
argument-hint: [optional: plan name or path — defaults to the newest plan]
allowed-tools: [Read, Glob, Grep, Edit, Write, Bash, Task, AskUserQuestion]
---

# build

Implement a plan written by `/plan`. You are the **orchestrator**: build the feature by spawning
Sonnet subagents one session at a time, review as you go, and open the PR at the end.

This works whether you run it in the **same session as `/plan`** (you still have the planning context —
ideal) or in a **fresh session** (you don't — so treat the plan file as the single source of truth and
read it in full before doing anything).

---

## Phase A — Load the plan and confirm

1. **Locate the plan.** If `$ARGUMENTS` names a plan (slug or path), use it. Otherwise pick the most
   recently modified `*.md` in `~/.claude/plans/`.

2. **Read it fully**, then tell the user what you're about to do: the feature, the branch name, and
   how many sessions there are. If you auto-picked the newest plan, confirm it's the right one before
   continuing — the wrong plan is the one mistake worth a question.

3. **Preflight and branch.** Confirm the working tree is clean and you're on `main`, then create the
   feature branch the plan names. You own the branch; the subagents own the commits onto it. Get the
   user's go before spawning the first session.

---

## Phase B — Orchestrate the build (Sonnet subagents, one at a time)

1. **Pin the worker model.** Set `CLAUDE_CODE_SUBAGENT_MODEL` (e.g. `sonnet`, or whatever the user
   asked for) before spawning. Tell the user plainly: the subagent mechanism pins the *model* but not
   the *reasoning-effort* tier, so effort follows the session default rather than an explicit "medium."
   It won't affect correctness on tightly-scoped prompts — don't imply otherwise.

2. **Spawn one subagent per session, in strict order**, via the `Task` tool
   (`subagent_type: general-purpose`), feeding it that session's self-contained prompt from the plan.
   **Never spawn sessions in parallel** — they stack commits on one shared branch and would collide.
   Spawn session N, wait for it to return, then spawn N+1.

3. **Keep the checkpoint light.** Read the returned summary; confirm it reports success against that
   session's stated criteria and that a commit landed. Only if the summary is ambiguous or signals
   trouble should you inspect further (`git log` / `git diff`, or read a file). Don't re-review clean
   work — the light checkpoint is what keeps orchestration cheap.

4. **Stop on any failure.** If a session reports failure, a commit is missing, or a spot-check finds
   the base is broken, halt and report to the user. Do not build the next session on a broken base.

5. **Don't widen scope.** The plan is locked. If a session reveals the plan itself is wrong, stop and
   bring it back to the user — don't let a subagent improvise around it.

---

## Phase C — Final review, then PR

After the last session commits:

1. **Diff the whole branch vs main** (`git diff main...HEAD`) and review as a senior engineer would:
   correctness, cross-session integration, leftover TODOs, invariant violations, fidelity to the plan.
   Small fixes you can make directly; for anything larger, spawn one more focused Sonnet subagent.
   Commit the fixes.

2. **Test what you can in the sandbox** — run the plan's Verification section: test harnesses, builds,
   linters, whatever you have access to.

3. **Delegate what you can't.** For checks you cannot run yourself (visual/UI behavior,
   production-only paths, external services — the plan flagged these), stop and give the user a short
   **numbered list of specific test cases**, each with its expected result, and wait for confirmation
   before moving on.

4. **Confirm the housekeeping** the plan calls for (CLAUDE.md notes, version/cache bumps).

5. **Open the PR — the one publishing step, and the last.** Only after the review passes and any
   user-delegated tests come back green, push the branch and open a PR against `main`. Summarize what
   shipped, the per-session breakdown, what you verified, and what the user tested by hand.

---

## Rules

- Read the plan in full before acting — it's the source of truth, especially in a fresh session.
- One feature branch off `main`. Subagents **commit but never push**. Only Phase C pushes and PRs.
- Subagents run **one at a time, in order** — never in parallel, because they share the branch.
- Every subagent prompt is fully self-contained: it reads the plan by absolute path and sees only its
  own prompt string.
- Keep inter-session review light; escalate to inspection only on a red flag. You're coordinating, not
  re-doing the work.
- Never exceed the locked scope. A session that can't be done as planned is a stop-and-ask, not an
  improvisation.
- Worker model is pinned via `CLAUDE_CODE_SUBAGENT_MODEL`; effort tier can't be pinned and inherits
  the default — say so, don't imply "medium."
- The PR push is the only irreversible, outward action here — gate it behind a passing review and any
  confirmed manual tests.
