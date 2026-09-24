---
name: plan
description: Plan a feature with the user and write an orchestration-ready implementation plan to ~/.claude/plans for /build to execute. Triages first — small work is sent straight to /build with no plan — and declares which model tier must orchestrate the build. No code changes.
argument-hint: [feature or task description]
allowed-tools: [Read, Glob, Grep, Write, AskUserQuestion, Bash]
---

# plan

Produce an implementation plan. Do NOT edit or create any file **other than the plan file**, and do
NOT run state-changing commands against the repo. Implementation happens later, in `/build`.

## Who reads this plan

**Not a human implementer. An orchestrator.** `/build` reads the plan, freezes its contract, and
farms the mechanical work to Sonnet subagents that each start from an empty context and see **only
their own brief** — no planning conversation, no sibling tasks, no sight of each other's edits.

Three consequences shape everything below:

1. **A subagent cannot derive.** Every value, string, signature and expected number it needs must be
   written down. A subagent inventing a number is the main way builds go wrong, and it happens
   precisely where the plan left a gap.
2. **Bugs collect in the seams.** What breaks is never inside one file — it's the contract *between*
   files, where no subagent can see both sides. Your job is to specify those contracts so they can't
   be independently guessed two different ways.
3. **The orchestrator might be Sonnet.** Most plans don't need an Opus orchestrator, and running one
   anyway is a straight waste. But some plans are only safe under Opus, and a Sonnet orchestrator
   cannot know which kind it has been handed. **You decide the tier** (§4b below) and write it into
   the plan. Getting this wrong in the cheap direction produces a build that compiles, reports
   green, and is wrong.

A plan that reads beautifully but leaves a prop shape, a unit, or a registry owner unstated will
produce a build that compiles and is wrong.

---

## Instructions

### 0. Triage — does this need a plan at all?

Planning has a fixed cost: this session, a plan file, then a fresh `/build` session that re-reads it.
For small work that cost exceeds the work itself. **Before restating scope, decide whether a plan is
warranted at all.**

Skip the plan and hand the work straight to `/build` when **all** of these hold:

- **Small edit surface** — roughly one or two files, and you can name the exact edit sites without
  exploring the repo.
- **No new cross-file contract** — no new or changed exported signature, prop shape, stored field, or
  registry id that something else consumes.
- **No arithmetic to verify** — no derived numbers, no units or divisors, no expected values a
  subagent could get plausibly wrong.
- **No migration, no destructive operation, no generated-artifact question**, and nothing the user
  would have to repair by hand afterwards.
- **Verification is one existing command** (the project's test or build), or a single obvious check.

The underlying test is the same one `/build` applies to its own small edits: **if briefing the work
costs more than doing it, don't brief it.** Any single failure above and you continue to §1.

If it qualifies, don't write a plan file. Output only:

> **No plan needed.** This is <one line on why: N files, additive, no cross-file contract>.
> Run this in a fresh **Sonnet** session:
> `/build <one-paragraph brief: exact files, exact change, verbatim strings/values, verify command>`
> I can also just do it here if you'd rather not switch sessions — say the word and I'll drop the
> read-only rule for this one change.

Two notes on that. The brief must be self-contained for the same reason subagent briefs are — the
`/build` session starts empty. And the read-only rule exists so a planning session can't
half-implement its own plan; offering to break it for a two-line change is a deliberate exception,
not a default. Prefer the fresh Sonnet session; this session's context is expensive per turn.

> These criteria are duplicated verbatim in `/build` §Direct mode. Keep the two in sync.

### 1. Restate scope, and get confirmation

List in bullets every distinct change you understand to be in scope. Where design decisions are open
(defaults, UX direction, scope tradeoffs), use `AskUserQuestion` with concrete options — it surfaces
tradeoffs faster than open chat. **Wait for explicit confirmation.** If the user said "go" in the same
message that invoked this skill, still confirm scope first.

### 2. Investigate before you specify

Read the actual code for every site you intend to change. You cannot pre-compute values or name a
contract you haven't read. Specifically, find and note:

- every call site of anything you plan to rename, change, or delete — in **both** directions
  (references to it, and things it references);
- the real signature and prop shape of any component or function crossing a file boundary;
- any shared registry (copy/tooltip ids, enums, event names) your change touches;
- whether generated/build artifacts sit in the paths you're editing.

### 3. Check your own arithmetic

If the plan asserts numbers — expected test values, derived figures, worked examples — **verify them**
before writing them down. You may use `Bash` for a throwaway Node/Python probe **in the scratchpad or
system temp only**; never write to the repo and never run its build or tests. A wrong expected value
costs a subagent a full session and an orchestrator an adjudication.

State every expected number **with the inputs that produce it**. `balance −453.97 at €6.58/day →
2026-08-16` is unverifiable and will be wrong; `from 2026-06-07, balance −453.97, €6.5753/day → 70
days → 2026-08-16` can be checked. Where a change will move numbers you haven't enumerated, **say
so** rather than implying the list is exhaustive.

### 3b. Validate any *observational* claim, not just the arithmetic

A plan that says "N rows are already damaged" or "this fires in production today" will send the user
to do expensive, sometimes irreversible manual work. So for every claim of observed damage, write down
the query or command that produced it **and one sentence on why it is a valid proxy for the thing
being claimed** — then check it against a case whose answer you already know.

The failure this exists to prevent: a diagnostic that counts something real but *different* from the
defect. `WHERE merchant_logo IS NULL` counts rows with no logo; it does not count rows whose logo was
destroyed, because the upstream source legitimately supplies no logo for many rows. The number was
correct and the conclusion was wrong, and it cost a re-import that wasn't needed.

Keep the two apart in the plan's prose:

- **A defect found by reading the code** is a latent defect. Say so. Fixing it is still worth doing.
- **A defect observed in data** needs a detector whose negative case you have checked.

If you can only show "consistent with", write "consistent with" — never a count.

### 4. Decide the execution tier

You have just read the code and pre-computed the numbers, so you are the only participant in a
position to judge this cheaply. Decide it explicitly and record it in §Execution.

**Opus orchestrator if ANY of these is true:**

| # | Trigger | Why Sonnet isn't enough |
|---|---|---|
| 1 | The plan asserts derived numbers, formulas, or units that `/build` must reconcile in its arithmetic probe | Deciding whether the *plan* or the *reading* is wrong is a judgement call, and the wrong answer is invisible |
| 2 | A data migration, destructive operation, or manual repair step for the user | Irreversible; the cost of a wrong call is unbounded |
| 3 | An invariant whose violation produces a plausible wrong value rather than an error | Nothing goes red, so review is the only detector |
| 4 | Three or more concurrent subagents, **or** any prop/signature/registry contract written by one task and consumed by another | Seam review across many sides is the hardest thing in the build |
| 5 | A known-unresolved question, a "consistent with" claim, or a latent defect left for the builder to adjudicate | You have explicitly deferred a judgement call to the orchestrator |
| 6 | Any task you have marked **[OPUS]** in §Tasks | Same reason you marked it |

**Otherwise: Sonnet orchestrator.** The typical Sonnet-tier plan is up to two subagents on disjoint
files, additive-only, contract fully frozen with no unit ambiguity, verification machine-checkable
with pre-computed expected values, no migration and no user repair step.

Three rules on top of the table:

- **A single [OPUS] task makes the whole build Opus.** Don't try to pin an Opus subagent under a
  Sonnet orchestrator — the orchestrator still has to adjudicate that task's output, which is the
  part that needed Opus in the first place.
- **The tier is a floor, not a ceiling.** The user may run a Sonnet-tier plan on Opus; `/build` will
  notice and offer to downgrade. Nothing is unsafe in that direction.
- **Never mark a plan Sonnet-tier to save tokens.** If a trigger fires, it fires. The saving is
  ~50–70% of orchestrator cost; the exposure is a green build that's wrong.

### 5. Write the plan

To `~/.claude/plans/<short-slug>.md`, using the template in the appendix. Every section there exists
because its absence broke a real build. Then do step 6 before you hand it over.

### 6. Run a consistency pass — the plan is a spec, and specs contradict themselves

Re-read what you wrote, hunting for two sections that disagree. The specific failure to look for:
**a "delete these" list versus a content table that still uses one of them.** Two different subagents
will implement both halves, and the result is a dangling reference no test catches. Check in
particular:

- deletion lists vs. copy/content tables, fixture tables, and example output;
- a renamed field vs. every place the old name still appears in your own prose;
- a task's file set vs. the edit sites you described for it;
- the completion checklist vs. the task table — every actionable item in exactly one task;
- **§Execution vs. §Tasks and §Verification** — a Sonnet tier alongside an [OPUS] task, a migration,
  three concurrent agents, or a cross-task contract is a contradiction. Resolve it toward Opus.

### 7. Stop

End with: "Plan written to `<path>`. **Run /build in a <Sonnet|Opus> session** (<reason in six
words>). It specifies **N tasks** (**M** parallelisable), roughly **<estimate>** of subagent work."

Naming the session model in the closing line is the whole point of the tier decision — it's the last
thing the user reads before opening the next session.

---

## Rules

- No file edits except the plan file in `~/.claude/plans/`. No state-changing commands against the
  repo. `Bash` is for read-only inspection and scratchpad arithmetic probes only.
- Do not begin implementation; that is `/build`'s job.
- **Triage before planning.** Work that fails no §0 criterion doesn't get a plan file.
- **Pre-compute everything.** Exact strings verbatim, exact numbers with their inputs, exact
  signatures. If you find yourself writing "the implementer should determine", stop and determine it.
- **Specify every cross-file contract.** If two tasks touch the same interface, its shape belongs in
  the Contract section, not in prose inside one task.
- **Declare the execution tier, with the triggers that decided it.** `/build` honours it and does not
  re-derive it — a Sonnet orchestrator has no way to notice what it can't handle.
- **Every actionable item goes in the task table.** Items that live only in a "Flags", "Risks" or
  "Cleanups" appendix get silently dropped, because no task owns them.
- **Identify edit sites by symbol plus a unique anchor string**, with line numbers as a hint only.
  Line numbers go stale the moment an earlier task edits the same file.
- Don't write full pasteable subagent prompts. `/build` assembles briefs from the Contract plus each
  task's detail block; duplicating them here doubles the text and drifts out of sync. Make each task's
  detail block complete enough to be wrapped, not prose that needs interpreting.
- If the feature needs *parallel research* to understand before you can specify it, this skill is too
  thin — say so and offer Claude Code's plan mode for the investigation, then come back here.

---

## Appendix — plan template

````markdown
# <Feature name>

> **Handoff note.** Executed by `/build`. **Run /build in a <Sonnet|Opus> session — see §Execution.**
> **§Tasks is the work contract** — read it before starting. Every value, string and expected number
> here is pre-computed so subagents implement rather than derive. Tasks marked **[ORCHESTRATOR]** must
> not be delegated; tasks marked **[OPUS]** additionally require an Opus orchestrator.

## Execution  ← read before opening the /build session
| | |
|---|---|
| **Orchestrator** | Sonnet / Opus |
| **Reasoning effort** | default (Sonnet tier) / high (Opus tier) |
| **Subagents** | Sonnet, N of them, M parallel |
| **Tier decided by** | trigger(s) fired, or "no triggers — mechanical, additive, 2 disjoint files" |

If the tier is **Sonnet**, state in one line what would flip it to Opus, so the orchestrator knows
which discovery means stop-and-escalate: e.g. *"flip to Opus if the arithmetic probe disagrees with
§Verification, or if any subagent reports an off-spec change."*

## Context
Why this change, what prompted it, the intended outcome. Name the design principle that should settle
micro-decisions a subagent hits and the plan didn't anticipate — that one sentence is worth more than
another page of instruction.

## Locked decisions
| Question | Decision | Why |
|---|---|---|
Decisions already settled with the user. Prevents mid-build re-litigation.

## Contract  ← /build lifts this verbatim into every subagent brief
The single most load-bearing section. Anything two tasks could guess differently:

- **Stored/data shapes** — field names with **units**, and the exact divisor or constant where one
  exists. Unit ambiguity is how two files end up disagreeing by 12×.
- **Function signatures** — every new or changed export, with argument order and return shape.
- **Component contracts** — the full prop list for anything a sibling task binds to, including which
  props may arrive undefined mid-build, and the render condition for each conditional slot. *Spell the
  condition out:* "renders at any sign" is a requirement; an example showing a zero value is not.
- **Shared registries** — for each id/key: who **adds** it and who **references** it. A referencing
  task that runs before the adding task, or references one being deleted, produces a dead link.
- **Lockstep lists, marked loud or silent.** Enumerate every list that must be updated together —
  module registries, test-file manifests, verifier allowlists, enum mirrors — and for each, say
  **whether omitting an entry fails loudly or silently**. Silent ones are the whole reason this bullet
  exists: a test suite missing one module still runs, on a partial engine, and reports green. List them
  explicitly and assign an owner, or the green run will be believed.
- **Generated artifacts** — which paths are build output, whether subagents rebuild, and whether they
  commit or discard. Decide once here so no subagent improvises.
- **Invariants, as named prohibitions with reasons.** Name them (`Invariant <X>`), say what must never
  be done, say *why the wrong thing will look correct*, and say how it is enforced — a test row, a
  comment at the definition, a doc line. An invariant with no enforcement is a wish.

## Tasks
| # | Task | Owner | Files (exact) | Depends on | Additive-only? |
|---|---|---|---|---|---|
| 1 | … | Orchestrator / Orchestrator [OPUS] / Subagent | `y/calc.jsx` | — | — |

- **Files** must be exact and complete — `/build` schedules concurrency by **file exclusivity**, so a
  missing path causes two agents to collide and a spurious one serialises work needlessly.
- **Owner** has two independent axes, and conflating them is how plans over-order Opus:
  - *Who does it* — `Orchestrator` for anything where a wrong guess is expensive and invisible, or
    too small to be worth briefing. `Subagent` for everything mechanical, which is most of it.
  - *What capability it needs* — add **[OPUS]** only where the work needs frontier reasoning: core
    algorithms, data migrations, invariant enforcement, anything whose failure mode is a plausible
    wrong number. An orchestrator task is not automatically an [OPUS] task; a three-line config edit
    kept in-house is `Orchestrator` and nothing more.
- **Additive-only** means the tree still compiles mid-task; flag it so ordering is safe.
- Name the **contended files** explicitly: "`y/ui.jsx` has three tasks — serialise them."

### Task N — <title>
For each task, a block `/build` can wrap into a brief:
- **Files**, and files it must NOT touch (name the sibling tasks that own them).
- **Edit sites** by symbol + unique anchor string (line numbers as a hint only).
- **What to do**, with every string verbatim and every number pre-computed.
- **What not to change** — the protected invariants, by name.
- **Verification command** and commit scope.

## Verification
Per check: what to assert, **how to reach that state**, and who can run it.

Reaching the state is the part plans omit. If a check needs a negative balance, an error path or an
empty list that the seed data never produces, say how to synthesise it (patch storage, seed a
fixture, temporary transaction) and to restore afterwards. Otherwise it silently becomes a
"please check by hand" that could have been verified.

Mark each: **machine-checkable** (tests, build, lint, DOM assertions) or **needs a human**
(production-only paths, external services, real devices, genuine aesthetic judgement). Be strict —
most "needs a human" checks are machine-checkable once state can be synthesised.

**Prove the verification channel exists before you rely on it.** If a check depends on a capability —
screenshotting a browser pane, running a device emulator, reaching a service — confirm that capability
works *now*, with one throwaway call, before writing the check into the plan. A plan that specifies
twenty visual checks against a tool that cannot produce an image has silently converted its own
verification section into a to-do list for the user, and nobody notices until the PR is already open.
Where the capability doesn't work, mark the check **needs a human** up front and count that cost in
§Cost — don't leave it looking automated.

**Also state what a passing check does *not* cover.** If the test suite proves arithmetic and nothing
proves rendering, say that in one line. It's the single most useful sentence for whoever decides how
much to trust a green run.

Give exact expected values with their inputs, and include the project's own mandated gates.

**Manual data-repair steps get their own trigger condition.** If the plan asks the user to re-import,
re-download, migrate or delete anything, state (a) the check that establishes the repair is *needed*,
(b) the check that establishes it *worked*, and (c) what is lost if it's run unnecessarily. (a) is the
one that gets skipped, and it is the one that makes the request legitimate. Note that any such step
forces the **Opus** tier.

## Out of scope
What is deliberately not being done, **and why** — so `/build` doesn't helpfully fold it in. Flag
anything real found along the way that should become its own piece of work.

## Cost
Orchestrator tier and why. N tasks, M parallelisable, rough token estimate. If it implies more than
about six subagents, say so plainly so the user can scale it down before spending.

## Completion checklist
- [ ] Every actionable item, flat, cross-referenced to its task (`→ Task 3`).

Includes items whose only home is a Flags or Cleanups section — those are exactly the ones that get
dropped. `/build` ticks this off before opening the PR.
````
