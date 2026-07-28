---
name: build
description: Implement a locked plan from /plan — freeze its contract, orchestrate Sonnet subagents under file exclusivity on a feature branch, review the seams between them, and open a PR. Spawns subagents and changes state, so it runs only after the plan is approved.
argument-hint: [optional: plan name or path — defaults to the newest plan]
allowed-tools: [Read, Glob, Grep, Edit, Write, Bash, PowerShell, Agent, AskUserQuestion, mcp__Claude_Browser__preview_start, mcp__Claude_Browser__navigate, mcp__Claude_Browser__read_page, mcp__Claude_Browser__computer, mcp__Claude_Browser__javascript_tool, mcp__Claude_Browser__read_console_messages, mcp__Claude_Browser__resize_window, mcp__Claude_Browser__form_input, mcp__ccd_session__spawn_task]
---

# build

Implement a plan written by `/plan`. You are the **orchestrator**: freeze the plan's contract, farm
the mechanical work to Sonnet subagents, review the seams they cannot see, and open the PR.

Works whether you run it in the **same session as `/plan`** (you still have the planning context —
ideal) or in a **fresh session** (you don't — so the plan file is the single source of truth and you
read it in full before doing anything).

**The two failure modes this skill exists to prevent.** Everything below serves one or the other:

1. **Seam breakage.** Each subagent sees only its own file. Bugs collect in the contracts *between*
   files — prop shapes, registry ids, assumed fields — where no agent's self-report and no unit test
   will find them. Phase C hunts these deliberately.
2. **Cost blowup.** A vague brief makes a subagent explore the repo instead of editing it, and
   exploration is where the tokens go. Phase B's briefs give answers, not search problems.

---

## Phase A — Load the plan, budget it, branch

1. **Locate the plan.** If `$ARGUMENTS` names one (slug or path), use it. Otherwise take the most
   recently modified `*.md` in `~/.claude/plans/`. If you auto-picked, confirm it's the right one —
   the wrong plan is the one mistake worth a question.

2. **Read it in full.** Then build a **completion checklist of every actionable item**, not just the
   ones in the plan's task or wave table. Items in appendices — "Flags", "Opportunistic cleanups",
   "Out of scope" — are the ones that silently get dropped, because no task owns them. Keep the
   checklist where you can tick it off in Phase C.

3. **Probe the plan's own arithmetic before you delegate any of it.** Write a throwaway Node script
   (in your scratchpad, never the repo) and check the plan's stated expected values against a quick
   implementation of its formulas. Finding that a plan's number is inconsistent is cheap now and
   expensive once a subagent has built assertions on it. If one doesn't reconcile, work out whether
   the plan or your reading is wrong; raise it with the user if it changes scope.

4. **State the cost before spending it.** Count the subagents the plan implies and tell the user, in
   one line: how many agents, which are parallel, and that each typically runs 50–150k tokens. If it
   implies more than about six, say so explicitly and let them scale it down. **Do the small files
   yourself** — a one-paragraph doc edit or a two-line config change costs less to make than to brief.

5. **Preflight and branch.** Confirm a clean tree on `main`, then create the branch the plan names
   (or a sensible `feat/<slug>`). You own the branch; subagents commit onto it and never push.

---

## Phase A2 — Freeze the contract (do this before any code)

This is the step that makes parallel work safe. Write a short note pinning everything two agents
could disagree about:

- **Field and function names**, with **units** — and the exact divisor or constant where one exists.
  Ambiguity here is what produces two files that each look right and disagree by 12×.
- **Signatures and prop contracts** for anything crossing a file boundary.
- **Shared registries** — tooltip/copy ids, enum values, event names — and which agent owns adding
  vs. referencing them.
- **Generated artifacts: one policy, decided once.** Which paths are build output, whether agents
  rebuild, and whether they commit or discard the result. Do not let each agent improvise; and if the
  policy is "discard", make sure discarding can't leave the working tree internally inconsistent
  (a restored template pointing at a rebuilt bundle, or vice versa).
- **The invariants that must not be "helpfully" fixed**, stated as prohibitions with the reason.

Write it to your scratchpad and hand every subagent **both** the path *and* the parts it needs
inline — a path alone gets skimmed. Also record it in the code itself (a comment at the primitive, a
line in the project's CLAUDE.md), because the scratchpad note dies with the session.

---

## Phase B — Orchestrate

### The scheduling rule

**File exclusivity, not serialization.** Two subagents may run concurrently **if and only if their
file sets are disjoint**. Sharing a feature branch is not a conflict — each agent stages only its own
paths. Serialize only on a genuinely contended file, and when you do, order the jobs so each starts
from a compiling tree.

Consequence worth stating in every brief: **other files will show as modified in `git status`** by
concurrent agents. Tell them so, and tell them to stage only their own paths. Otherwise they waste a
turn investigating, or worse, commit someone else's half-finished work.

### Writing a brief that doesn't burn tokens

Give the subagent the **answer**, not the search:

- **Exact files, and exact line ranges** to read. Then say what **not** to read: "do not explore the
  repo", "do not read the tests", "do not grep for call sites — here they are."
- **The relevant plan section verbatim**, plus every value, string, and expected number it needs.
  A subagent inventing a number is the main failure mode, and it happens when the brief omits one.
- **The frozen contract**, inline.
- **A verification command** that proves its work compiles, and the exact commit scope.
- **This instruction, verbatim:** *"Do not change [the protected invariants]. If the spec seems wrong
  or incomplete, stop and report rather than improvising."*

Do **not** hand a subagent the whole plan and ask it to find its part.

### Reading what comes back

Confirm success against the stated criteria and that a commit landed. Then read the report for the
things that matter more than pass/fail:

- **Flagged workarounds.** "The prop I needed isn't threaded through, so I computed it locally" is a
  defect report wearing a success hat. Decide whether to accept it; note it for Phase C either way.
- **Off-spec changes.** An agent that changed a number the plan didn't list has either found a real
  consequence of the design or broken something. Adjudicate it yourself — don't take either the
  agent's confidence or its apology at face value.
- **Contract drift.** Any agent that changed a shared shape has just invalidated another agent's
  brief. Fix the other side yourself, or re-brief.

Halt on failure, on a missing commit, or on a broken base. Never build the next wave on a broken one.
Never widen scope: a task that can't be done as planned is a stop-and-ask, not an improvisation.

---

## Phase C — Seam review, verification, PR

### 1. Seam review (mandatory, and not light)

The subagents' self-reports cannot cover this, so it's yours. For **every contract shared across
agents**, check *both* sides:

- **Prop and signature contracts** — does each consumer pass what the component now destructures?
  Are new props actually reachable, or written-but-never-wired?
- **Shared registries, in both directions** — dead references to deleted ids, *and* orphan entries no
  one references. Grep each way; both are bugs.
- **Assumed fields** — every object handed across a boundary, including synthetic or aggregate ones.
  A field that's missing often renders as a plausible zero rather than an error, so read the
  construction site, don't just trust that it works.
- **Conditional rendering around new state** — a slot gated on the old condition may never appear in
  the case that motivated it.
- **Orphans your changes created** — constants, imports, helpers left unused. Remove those; leave
  pre-existing dead code alone.

Then diff the whole branch (`git diff main...HEAD`) and read it as a senior engineer: correctness,
fidelity to the plan, leftover TODOs, invariant violations. Sweep for the patterns the plan forbade.
Small fixes yourself; anything larger, one more focused subagent.

### 2. Tick off the Phase A checklist

Every item, including the ones no task owned. This is where plan appendices get honoured.

### 3. Verify — and prove you're testing what you built

Run the plan's verification section: test harnesses, builds, linters.

For anything running in a browser or long-lived process: **before concluding a change didn't work,
prove the artifact you're looking at is the one you just built.** Assert a version hash, or the
presence of a symbol that exists only in the new code. Stale service workers, HTTP caches and
watch processes will otherwise have you debugging code that isn't running. This is a specific,
repeated, expensive mistake.

**Prefer synthesizing state over delegating to the user.** If a state is hard to reach — an error
path, a negative balance, an empty list — inject it (patch storage, seed a fixture), verify, then
restore. This converts most of what looks like "the user must check this by hand" into a verified
fact. Back up what you mutate and restore it.

Only for what you genuinely cannot reach (production-only paths, external services, real devices):
give the user a short **numbered list of test cases with expected results**, and wait.

### 4. Confirm housekeeping, then open the PR

Docs the plan calls for, version/cache bumps, final build + verify. Then — and only then, after
review passes and any delegated tests come back green — push and open the PR against `main`.

Write the PR body to explain **why**, not to list commits. Lead with the problem, state the design
principle, then the evidence: concrete verified numbers, not "tested and working". Call out
judgement calls you made, anything you deliberately left out of scope, and any pre-existing issue you
found and chose not to fold in (flag those separately rather than growing the diff).

---

## Rules

- Read the plan in full before acting. It's the source of truth, especially in a fresh session.
- One feature branch off `main`. Subagents **commit but never push**. Only Phase C pushes and PRs.
- Concurrency is bounded by **file exclusivity**, not by a one-at-a-time rule.
- Freeze the contract before any code, and put it somewhere that outlives the session.
- Every brief is self-contained: exact files, exact line ranges, verbatim values, and an explicit
  list of what not to read.
- Seam review is not optional and not light — it's the only place cross-file bugs are findable.
- Never exceed the locked scope. Can't-be-done-as-planned is a stop-and-ask.
- Do small edits yourself. Briefing costs more than typing for anything under a few lines.
- Worker model is pinned via the subagent's `model`; reasoning-effort tier can't be pinned and
  inherits the session default — say so plainly, don't imply "medium".
- The PR push is the only irreversible outward action. Gate it behind a passing review.

---

## Appendix — subagent brief template

```
You are implementing ONE narrowly-scoped task on branch <branch> in <repo>.
Do not switch branches. Do not push.

READ FIRST (and nothing else — do not explore the repo):
  1. <contract note path>  — authoritative on names, units, divisors
  2. <file:line-range>     — <what it is and why you need it>

YOUR TASK. Edit exactly these files: <paths>. Touch nothing else.
Other agents are concurrently editing <paths>; do NOT touch them. Other files WILL
show as modified in `git status` — stage only your own.

BACKGROUND: <why this change exists, in 2-4 sentences — an agent that understands
the intent makes better micro-decisions than one following a checklist>

SPEC (verbatim from the approved plan):
  <paste the section, with every value, string and expected number>

CONTRACT (frozen — bind to exactly this):
  <inline the relevant field names, signatures, units, divisors>

RULES
- Do not change <protected invariants: the math, the migration, expected test values>.
- <project-specific gotchas: generated paths, forbidden APIs, copy conventions>
- If the spec seems wrong or incomplete, STOP and report rather than improvising.
  Every number you need is written above.

VERIFY: <exact command>. <exact artifact policy afterwards>

Commit ONLY <paths>, message body describing the change, ending with:
Co-Authored-By: <coauthor line>

REPORT BACK: each spec item and how you satisfied it; any value that did not match
reality (give both numbers); anything you worked around rather than solved; the
commit hash.
```
