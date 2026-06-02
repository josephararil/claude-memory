# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

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

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

## 5. Git Workflow

- Never commit directly to main. Always create a feature branch.
- After completing a feature or fix, open a PR — do not leave work on a branch without one.
- Auto-create a PR after completing a feature or fix (auto-PR preference is enabled).

## 6. Documentation

After any feature change or multi-file edit, update the project's CLAUDE.md in the same session before considering the task done.

## 7. Verification & Caching

When a change doesn't appear in the preview, assume stale cache first. Hard-refresh and confirm the service worker updated before investigating the code. Don't debug logic until cache has been ruled out.

## 8. Planning vs Implementation

When asked for a plan, produce a plan only — do not read files to edit or begin implementation until explicitly told to proceed. Before writing a plan, restate the full scope you understand to be in scope and ask for confirmation.

## 9. Preserving Implicit Behavior

Before editing code, call out any existing behavior (logic, cooldowns, helpers) that the change might silently remove or alter. State what you plan to keep vs. remove and get confirmation before proceeding.
