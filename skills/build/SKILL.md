---
name: build
description: Implement a locked plan from /plan — or a small change directly, with no plan. Honours the plan's declared orchestrator tier, freezes its contract, orchestrates Sonnet subagents under file exclusivity on a feature branch, reviews the seams between them, and opens a PR. Spawns subagents and changes state, so it runs only after the plan is approved.
argument-hint: [plan name or path, or a self-contained brief for a small direct change]
allowed-tools: [Read, Glob, Grep, Edit, Write, Bash, PowerShell, Agent, AskUserQuestion, mcp__Claude_Browser__preview_start, mcp__Claude_Browser__navigate, mcp__Claude_Browser__read_page, mcp__Claude_Browser__computer, mcp__Claude_Browser__javascript_tool, mcp__Claude_Browser__read_console_messages, mcp__Claude_Browser__resize_window, mcp__Claude_Browser__form_input, mcp__ccd_session__spawn_task]
---

# build

Implement a plan written by `/plan`. You are the **orchestrator**: freeze the plan's contract, farm
the mechanical work to Sonnet subagents, review the seams they cannot see, and open the PR.

Works whether you run it in the **same session as `/plan`** (you still have the planning context —
ideal) or in a **fresh session** (you don't — so the plan file is the single source of truth and you
read it in full before doing anything). It also runs **without a plan at all** for small changes —
see §Direct mode.

**The three failure modes this skill exists to prevent.** Everything below serves one of them:

1. **Seam breakage.** Each subagent sees only its own file. Bugs collect in the contracts *between*
   files — prop shapes, registry ids, assumed fields — where no agent's self-report and no unit test
   will find them. Phase C hunts these deliberately.
2. **Cost blowup.** A vague brief makes a subagent explore the repo instead of editing it, and
   exploration is where the tokens go. Phase B's briefs give answers, not search problems. An Opus
   orchestrator on a mechanical plan is the same waste one level up. Phase 0 catches it.
3. **Mis-tiered orchestration.** A Sonnet orchestrator running a plan that needed Opus doesn't fail
   loudly — it adjudicates something it shouldn't have and ships a green, wrong build. Phase 0 gates
   this, and §Running as a Sonnet orchestrator says what to do when the plan's edges show.

---

## Phase 0 — Triage the invocation (before anything else)

**0.1 — Plan or direct?** If `$ARGUMENTS` names a plan (slug or path), or names nothing and
`~/.claude/plans/` has a recent candidate, this is a plan build: continue to 0.2. If `$ARGUMENTS` is a
task description rather than a plan reference, and no plan matches it, go to **§Direct mode** — don't
invent a plan file for a two-file change.

**0.2 — Check the tier you're running at.** Read the plan's **§Execution** section (and its handoff
note) first — before reading the rest of the plan, so you spend nothing if you're the wrong model.
Then state, in one line, the plan's required orchestrator and the model you believe this session is
running as. If you can't determine your own model with confidence, **say so and ask** rather than
assuming; a wrong assumption here is the failure this step exists to prevent.

- **Plan says Opus, you are Sonnet → stop.** Do not read further, do not branch. Say: *"This plan is
  Opus-tier (<triggers>). Restart `/build` in an Opus session."* Do not offer to try anyway. The
  triggers exist because the failure mode is invisible.
- **Plan says Sonnet, you are Opus → offer the downgrade once.** One line: *"This plan is Sonnet-tier;
  restarting in Sonnet saves roughly half the orchestration cost. Continue on Opus, or restart?"* Use
  `AskUserQuestion` and wait. Continuing is safe, just expensive — the build, not the plan-reading, is
  where the money goes, so it's still worth asking at this point.
- **Match → proceed**, and if you are Sonnet, read §Running as a Sonnet orchestrator now.
- **No §Execution section** (an older plan) → derive the tier yourself from `/plan`'s triggers:
  derived numbers to reconcile, a migration or manual repair step, an invariant whose violation looks
  correct, three or more concurrent subagents, any cross-task prop/signature/registry contract, or any
  deferred judgement call. Any one of those means Opus. State which way you read it before continuing.

Subagents are Sonnet in either tier. The tier is about *your* seat, not theirs.

---

## Direct mode — small change, no plan

Confirm the work actually qualifies. All of these must hold:

- **Small edit surface** — roughly one or two files, and you can name the exact edit sites without
  exploring the repo.
- **No new cross-file contract** — no new or changed exported signature, prop shape, stored field, or
  registry id that something else consumes.
- **No arithmetic to verify** — no derived numbers, no units or divisors, no expected values that
  could be plausibly wrong.
- **No migration, no destructive operation, no generated-artifact question**, and nothing the user
  would have to repair by hand afterwards.
- **Verification is one existing command**, or a single obvious check.

> These criteria are duplicated verbatim in `/plan` §0. Keep the two in sync.

If any fails — or if it fails *once you start reading the code* — **stop and say so**: *"This is
larger than it looked (<which criterion broke>). Run `/plan` first."* Widening a direct build into an
undocumented multi-file change is exactly the improvisation the plan/build split exists to prevent.

If it qualifies: clean tree on `main` → branch → make the edits **yourself** (no subagents; briefing
costs more than typing at this size) → run the verification command → commit → push and
open a short PR, merging it yourself only where the project's CLAUDE.md authorizes that. The PR body
carries a **Not verified** line if anything went unchecked. Skip Phases
A2–C entirely; there are no seams to review when one agent wrote everything.

---

## Running as a Sonnet orchestrator

You have a plan whose author judged it mechanical. That judgement is only valid while the plan holds.
**When the plan's edges show, you escalate rather than adjudicate.** Stop, report to the user in one
short block, and recommend a fresh Opus `/build` session on the same branch. Specifically:

- The Phase A arithmetic probe **disagrees** with the plan's stated expected values.
- A verification capability the plan assumed **doesn't work** (Phase A2 smoke test fails).
- A subagent reports an **off-spec change**, a **flagged workaround**, or **contract drift**.
- Seam review turns up an ambiguity the Contract doesn't settle, and settling it means choosing a
  number, a unit, or an invariant's meaning.
- The plan asserts something the build **disproves**.
- Anything that would require **widening scope** to complete.

Escalating is cheap and the right outcome; the branch and commits survive the session. What is
expensive is a plausible guess that passes review. Everything else in this skill you execute normally
— the mechanics of briefing, file exclusivity, and grep-both-ways seam checking do not need Opus.

---

## Phase A — Load the plan, budget it, branch

1. **Locate the plan.** If `$ARGUMENTS` names one (slug or path), use it. Otherwise take the most
   recently modified `*.md` in `~/.claude/plans/`. If you auto-picked, confirm it's the right one —
   the wrong plan is the one mistake worth a question.

1b. **Look for a checkpoint before anything else.** If `~/.claude/plans/<plan-slug>.checkpoint.md`
   exists and is not marked `COMPLETE`, a previous session died mid-build — usually on a usage limit.
   **Resume from it; do not restart.** Check out its branch, confirm each task it lists as done has
   its commit on that branch (`git log --oneline`), re-read the frozen contract it carries, and pick
   up at the first task not marked done. A task marked `dispatched` but with no commit died with its
   agent: re-dispatch it from the same brief. Tell the user in one line what you are resuming from.

2. **Read it in full.** Then build a **completion checklist of every actionable item**, not just the
   ones in the plan's task or wave table. Items in appendices — "Flags", "Opportunistic cleanups",
   "Out of scope" — are the ones that silently get dropped, because no task owns them. Keep the
   checklist where you can tick it off in Phase C.

3. **Probe the plan's own arithmetic before you delegate any of it.** Write a throwaway Node script
   (in your scratchpad, never the repo) and check the plan's stated expected values against a quick
   implementation of its formulas. Finding that a plan's number is inconsistent is cheap now and
   expensive once a subagent has built assertions on it. If one doesn't reconcile, work out whether
   the plan or your reading is wrong; raise it with the user if it changes scope. **On Sonnet tier, a
   mismatch here is an escalation, not a call to make.**

4. **State the cost before spending it.** Count the subagents the plan implies and tell the user, in
   one line: the orchestrator tier you're running at, how many agents, which are parallel, and that
   each typically runs 50–150k tokens. If it implies more than about six, say so explicitly and let
   them scale it down. **Do the small files yourself** — a one-paragraph doc edit or a two-line config
   change costs less to make than to brief.

4b. **Smoke-test the verification channel now, not in Phase C.** For every capability the plan's
   verification section depends on — a browser pane that must produce an image, a preview server, a
   device viewport, an external service — make one throwaway call to prove it works *before* any code
   is written. Then tell the user which checks are actually runnable and which have just become manual.

4c. **Validate the trigger for any manual repair step the plan asks of the user** — a re-import, a
   migration, a deletion. Run the plan's own "is this needed?" check yourself and confirm it means what
   the plan says it means. If the evidence doesn't hold up, say so before the user spends an afternoon
   on it; a code fix for a latent bug is still worth shipping without the repair. (A plan containing
   such a step should be Opus-tier; if you're on Sonnet and one appears, that's a mis-tiered plan —
   escalate.)

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

Everything here should already be in the plan's §Contract — you are transcribing and pinning, not
inventing. **If you find yourself deciding one of these rather than copying it, the plan has a gap:**
on Opus, decide it and say so explicitly; on Sonnet, escalate.

Write it to your scratchpad and hand every subagent **both** the path *and* the parts it needs
inline — a path alone gets skimmed. Also record it in the code itself (a comment at the primitive, a
line in the project's CLAUDE.md), because the scratchpad note dies with the session.

---

## Phase B — Orchestrate

### Size the fan-out before writing a single brief

A subagent costs 50–150k tokens whether its task is 400 lines or 40. **The brief, not the task, is
the floor on the price.** So the plan's task table is a proposal, not a schedule — re-price it:

- **Delegate** a task that is genuinely large (a new module, a wide interlocking edit, a file you'd
  otherwise have to read in full), or that would force *you* to load a big file into your own context
  to do it.
- **Do it yourself** when the plan has already specified it completely and it lands in one or two
  files at a scale you can type. A fully-specified ~40-line edit across one file is faster to make
  than to brief, and you were going to read the anchors anyway during seam review.

Say the re-pricing out loud in the cost line: *"the plan implies 4 agents; task 4 is ~40 lines in one
file, so I'll do that one myself — 3 agents."* Dropping the smallest task from a wave is usually the
single biggest saving available, and it costs nothing in quality because you review that seam anyway.

Don't over-correct. Doing a large task yourself to "save tokens" just moves the same work into the
context you need for seam review, which is the expensive place to run out.

### Fill the wait

Once the wave is running you are idle, and idle orchestrator turns are pure overhead. Do the
dependency-free work now, not after:

- Tasks you kept in-house whose files no running agent touches.
- Docs the plan calls for — the contract is frozen, so this rarely needs rework.
- Anything you can prepare but not yet apply (a registry edit that needs a not-yet-created file).

Don't speculatively re-read files the agents are rewriting, and don't poll them. Their reports arrive
on their own.

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
- **A hard ban on nesting.** A subagent that spawns its own subagents multiplies the bill invisibly
  and produces work no brief governed. State it flatly: *"Do not launch subagents of your own (the
  Agent tool). Each one multiplies cost and does work no brief governs."*
- **What its verification will get wrong, and why.** In a parallel wave an agent's `npm test` may
  legitimately fail on another agent's half-landed work. Say so, and give it a narrower command that
  isolates its own scope — otherwise it spends turns debugging someone else's tree, or worse,
  "fixes" it.
- **This instruction, verbatim:** *"Do not change [the protected invariants]. If the spec seems wrong
  or incomplete, stop and report rather than improvising."*

Do **not** hand a subagent the whole plan and ask it to find its part.

Pin `model: sonnet` on every subagent regardless of your own tier. If a task in the plan is marked
**[OPUS]**, you are on Opus and you do that task yourself — don't pin an Opus subagent, because the
part that needed Opus is the adjudication of the result, which lands back on you either way.

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

All three are escalation triggers on Sonnet tier. Adjudicating an off-spec change is precisely the
judgement the plan's tier decision was about.

Halt on failure, on a missing commit, or on a broken base. Never build the next wave on a broken one.
Never widen scope: a task that can't be done as planned is a stop-and-ask, not an improvisation.

### Checkpoint after every task

Long builds hit usage limits, and a limit kills the running agents and the session with them. The
scratchpad dies too. So keep **`~/.claude/plans/<plan-slug>.checkpoint.md`** — next to the plan,
never in the repo — and rewrite it at three moments:

1. **After Phase A2**, before any dispatch: create it.
2. **When you dispatch a task**: mark it `dispatched`.
3. **When a task's commit lands** (agent or in-house): mark it `done` with the short SHA, plus any
   accepted workaround or off-spec decision from "Reading what comes back".

It holds exactly what a fresh session needs to carry on from this file alone:

```markdown
# Checkpoint — <plan-slug>
branch: <branch>   base: <sha>   tier: <opus|sonnet>   updated: <ISO timestamp>

## Frozen contract
<the Phase A2 note, inline — not a scratchpad path>

## Tasks
| # | Task | State | Commit | Notes |
|---|---|---|---|---|
| 1 | … | done | abc1234 | accepted local compute of X, see seam review |
| 2 | … | dispatched | — | brief: <one line> |
| 3 | … | pending | — | |

## Phase C checklist
<the Phase A completion checklist, ticked as you go>
```

Cost is one small write per task, and it replaces re-deriving a half-finished build from `git log`.
When the PR is open, set the header's first line to `# Checkpoint — <plan-slug> — COMPLETE (PR #N)`
so a later `/build` doesn't try to resume it.

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

The mechanics above are grep-and-read work at any tier. What differs: on Sonnet, a seam whose correct
resolution isn't already written in the Contract is a stop-and-escalate, not a judgement call.

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

**Prove your new guard actually fires.** Any test, assertion or conformance check added by this build
must be shown to fail when the thing it guards is broken — break it deliberately, watch it go red,
revert. A check whose pattern matched nothing passes for the same reason a correct one does, and it
will be trusted for years. Do this for at least the assertions the plan called load-bearing.

**Never let an unrun check pass silently into "verified".** Keep an explicit list of checks you could
not run and why. It goes in the PR body under its own heading, not folded into the summary. "8 of 9
charts unverified — the pane cannot screenshot; needs a look on the device" is a useful handoff;
silence reads as a pass and the gap is never closed.

### 4. Confirm housekeeping, then open the PR

Docs the plan calls for, version/cache bumps, final build + verify. Then — and only then, after
review passes and any delegated tests come back green — push and open the PR against `main`. Where
the project's CLAUDE.md authorizes auto-merge, wait for CI and merge it; otherwise stop at the open PR.

Put the **why** in the commit messages: the problem, the design principle, concrete verified
numbers, and the judgement calls. Commits are the record that gets read. Keep the PR body thin: a
title, a one-line summary, the orchestrator tier in one line, and the two sections below. Get it
right on `gh pr create`; if scope grows afterwards, add a commit rather than editing the body.

Include a **"Not verified"** section whenever one applies, and a **"Follow-up not in this PR"** section
listing what the reviewer now owns — each with enough context to act on without this session. Both are
short. Both are the difference between a handoff and a hope.

If the plan asserted something the build disproved — a number, a count, a claim of observed damage —
**say so in the PR body in plain terms.** The plan is not the customer; the user is, and they may have
already acted on the wrong claim.

---

## Rules

- Check the tier before reading the plan. Sonnet on an Opus plan is a hard stop; Opus on a Sonnet plan
  is one offer to downgrade, then proceed.
- Small change with no plan → §Direct mode. Discovering mid-way that it isn't small → stop, run
  `/plan`. Never grow a direct build into an undocumented multi-file change.
- Read the plan in full before acting. It's the source of truth, especially in a fresh session.
- One feature branch off `main`. Subagents **commit but never push**. Only Phase C pushes and PRs.
- Concurrency is bounded by **file exclusivity**, not by a one-at-a-time rule.
- Freeze the contract before any code, and put it somewhere that outlives the session. Transcribe it
  from the plan; deciding it yourself means the plan has a gap.
- Every brief is self-contained: exact files, exact line ranges, verbatim values, and an explicit
  list of what not to read.
- Seam review is not optional and not light — it's the only place cross-file bugs are findable.
- Never exceed the locked scope. Can't-be-done-as-planned is a stop-and-ask.
- Re-price the plan's task table before delegating: a subagent costs 50–150k tokens regardless of
  task size, so a fully-specified one-or-two-file edit is cheaper to type than to brief. Say the
  re-pricing in the cost line.
- Subagents **may not spawn subagents**. Put the ban in every brief, verbatim.
- While a wave runs, do dependency-free work (in-house tasks, docs) rather than idling or polling.
- Worker model is always Sonnet, pinned via the subagent's `model`; reasoning-effort tier can't be
  pinned and inherits the session default — say so plainly, don't imply "medium".
- On Sonnet tier, escalate on the §Running as a Sonnet orchestrator triggers instead of adjudicating.
- Pushing, opening the PR and merging are the irreversible outward actions. Gate them behind a
  passing review.

---

## Appendix — subagent brief template

```
You are implementing ONE narrowly-scoped task on branch <branch> in <repo>.
Do not switch branches. Do not push.

HARD LIMITS
- Do not launch subagents of your own (the Agent tool). Each one multiplies cost
  and does work no brief governs.
- Do not run <the expensive/global commands this task has no business running>.

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

VERIFY: <exact command>. <what a legitimate failure from a CONCURRENT agent's
work looks like, and the narrower command that isolates your own scope>.
<exact artifact policy afterwards>

Commit ONLY <paths>, message body describing the change, ending with:
Co-Authored-By: <coauthor line>

REPORT BACK: each spec item and how you satisfied it; any value that did not match
reality (give both numbers); anything you worked around rather than solved; the
commit hash.
```
