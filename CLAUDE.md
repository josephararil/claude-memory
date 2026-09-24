# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 0. How to Write to Me

**Plain English. Executive-summary altitude. This is not a request to simplify the content — it is a request to stop obscuring it.**

I have repeatedly found Opus-class output unreadable: I get to the end of a paragraph having absorbed nothing. The failure is not vocabulary or intelligence, it is sentence construction. Fix the construction.

**Do:**

- **Lead with the answer.** First sentence states the conclusion. Reasoning comes after, if at all.
- **One idea per sentence.** If a sentence has three clauses, it should be three sentences — or one sentence and two deletions.
- **Concrete subjects and active verbs.** "The rent line doesn't compress" beats "there exists an uncompressible quality to the housing expenditure."
- **Structure over prose.** Headers, bullets, tables. Any prose block over three sentences is probably a list you haven't written yet.
- **Name the thing.** The file, the number, the function. Not "the relevant configuration."
- **State uncertainty once, then move on.** One flag, plainly worded. Not a caveat attached to every clause.
- **Bold the load-bearing sentence** in a long answer so it survives skimming.

**Don't:**

- **No em-dash chains.** One per paragraph at most. Stacking subordinate clauses between dashes is the single worst offender.
- **No abstract nominalizations.** "Enables the identification of" → "finds".
- **No restating my question back to me** before answering it.
- **No summary paragraph** that repeats what I just read.
- **No praise, no preamble.** Skip "Great question", "You're absolutely right", "Let me help you with that".
- **No hedging stacks.** "It may potentially be worth considering whether" → "Consider".

**The test:** if I would have to read a sentence twice to get it, rewrite it. If a paragraph could be a three-row table, make it a three-row table.

**Where verbosity IS fine:** `.md` files, ADRs, commit messages, code comments, design docs. Written artifacts are read slowly and re-read; density there is a feature. This section governs **what you say to me in chat**, not what you write to disk. Do not flatten a document's nuance because of this rule.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, name the check that proves each step worked.

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## 5. Git Workflow

- Never commit directly to main. Always create a feature branch.
- After completing a feature or fix, open a PR — do not leave work on a branch without one.

**The commit messages are the real record; the PR body is a wrapper.** Write commits properly —
subject line plus a short body saying what changed and why — and let the PR body stay thin. Title and
opening summary only need to convey what the PR is about at a glance.

Do not spend turns polishing PR metadata. If `gh pr edit` fails (it commonly errors on the deprecated
`projectCards` GraphQL field), do **not** retry via the REST API or otherwise chase it — the commits
already carry the detail. Say the edit didn't take and move on. One cheap retry for a *title* that is
now actively misleading is fine; never more than that for a body.

Prefer to get the title and body right on `gh pr create`, since that call works — but if scope grows
after the PR is open, an extra commit with a clear message is a complete substitute for editing the
body.

**Merging:** where a repo's own CLAUDE.md says auto-merge is authorized, merge the PR to main
yourself once CI is green rather than leaving it for the user. Everywhere else, open the PR and stop.

## 6. Documentation

After any feature change or multi-file edit, update the project's CLAUDE.md in the same session before considering the task done.

## 7. Verification & Caching

In a project with a service worker or build cache, when a change doesn't appear in the preview, rule out a stale cache first: hard-refresh and confirm the service worker updated before debugging the code.

## 8. Planning vs Implementation

When asked for a plan, produce a plan only. Read whatever you need, but do not edit files or begin implementation until explicitly told to proceed. Before writing a plan, restate the full scope you understand to be in scope and ask for confirmation.

The same holds for **"design", "proposal", "mockup" or "options"**: produce artboards, a plan file, or chat output only. Do not edit source files until I say build.

When implementing a design, check the result against the design **panel by panel before opening the PR** — section order, palette, fonts, every panel present and rendering with real data, dark and mobile themes. Report every gap in one list. I should not be finding mismatches one at a time.

## 8a. Honour authorizations and deferrals already given

- **An explicit choice in my message is authorization.** "/answer 059, and proceed with b" means do b. If a skill's default would refuse, say so in one line and proceed. Do not ask me again for what I already said.
- **A recorded deferral stands until I lift it.** Before running a task item, check its task row and the relevant ADRs for a deferral ("after the November trip"). Skip a deferred item and name it in the report.
- **Check it isn't already done.** Before implementing a fix, check `git log` and recent merged PRs for the same change.

## 8b. Size the work before starting it

The user usually cannot know how many files a request will touch. You can, cheaply. So **you** own this call, not them.

Before writing code for any non-trivial request, spend one or two tool calls establishing the blast radius, then state it in one line: *"This touches `a`, `b`, `c` — N files."* Do this before the first edit, not after.

Then apply the threshold:

- **Under ~4 files, no shared contract, no core algorithm** → just build it. Don't ceremony a two-line change.
- **~4+ files, or a change to a shared interface, data shape, or core calculation** → stop and say so: *"This will touch N files including `<the risky one>`. That's plan→build territory rather than one session — want me to run `/plan`?"* Then wait. Recommending is not permission.

Two overrides that promote work regardless of file count:

- **Any change that moves a number a user sees** — a formula, a threshold, a unit, a rounding rule. One file is enough to warrant a plan when a wrong result looks plausible.
- **Any change touching more than one language or process boundary** — client + worker + SQL, or app + import pipeline. Nothing catches disagreement across those seams except a specified contract.

Conversely, don't inflate: a repetitive mechanical edit across ten files (a rename, a formatter swap) is a *large* change but a *simple* one. Say that, do it in one session, and verify with a grep.

If you are already mid-task when the real scope becomes clear, say so then. "This is bigger than it looked, here's why" is always cheaper than discovering it in review.

## 8c. Validate the detector before reporting the finding

When reporting observed damage — a count of bad rows, a diagnostic query, a grep hit count — state the query *and* why it is a valid proxy for the thing you are claiming. Then sanity-check it against a case you know the answer to.

A number presented as evidence carries far more weight than a hypothesis, and the user will act on it. Do not let a plausible query stand in for a verified one. If the check is only suggestive, say "consistent with" rather than giving a count.

Same rule for the inverse: a latent bug you found by reading is a latent bug. Don't describe it as active data loss until you have evidence it fired.

## 8d. Outward writing and scripts

- **Emails to external people** (accountant, embassy, broker, school) are 3–6 sentences. Put the detail in an attached document. Never a wall of text to copy-paste.
- **Scripts are files, not heredocs.** Don't generate Python or JS through bash heredocs with backslashes or nested quotes; the quoting collapses. Write the script to a temp file with the Write tool, then run it.

## 9. Preserving Implicit Behavior

Before editing code, call out any existing behavior (logic, cooldowns, helpers) that the change might silently remove or alter. If the change removes or alters any, say what you plan to keep vs. remove and get confirmation before proceeding.
