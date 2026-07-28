---
name: html-presentation
description: >-
  Turn any document, notes, spec, report, transcript, or set of talking points into a polished,
  presentation-ready HTML slide deck — a single self-contained .html file with a dark, modern,
  animated "keynote" aesthetic (full-viewport slides, staggered rise-in animations, keyboard +
  click navigation, dot nav, progress bar). Use this whenever someone wants to present, pitch, or
  visually communicate something in the browser: "make a presentation", "turn this into slides",
  "build a pitch/sales/capability/investor/exec deck", "slide deck from this doc", "I'm presenting
  X next week", "create a deck for [audience]". A ready-made design system + template is bundled so
  there is NO need to design from scratch or re-derive any CSS. Prefer this over building slides
  ad-hoc. Use the pptx skill instead only when the user specifically needs an editable PowerPoint
  (.pptx) file rather than a beautiful browser/web deck.
---

# HTML Presentation Deck

This skill produces gorgeous, self-contained HTML presentations: one `.html` file, opens in any
browser, no build step, no external files. The look is a dark, high-contrast "keynote" style with a
single accent color, monospace eyebrow labels, big confident headlines, and a staggered rise-in
animation on every slide.

**The core efficiency rule:** a complete, working scaffold already exists at
`~\.claude\skills\html-presentation\template.html` — all the CSS, all the JavaScript, and one worked example of every
component. **Copy that file and edit only the slide content.** Do not regenerate or re-derive the
CSS, and do not invent a new design. Re-deriving the styling wastes thousands of tokens and drifts
off-brand; the whole point of this skill is that the design is already solved.

## Workflow

1. **Understand the source + the audience.** Read the material you're turning into a deck. Then get
   clear on three things — ask the user briefly if any are unknown, because they change every copy
   decision:
   - **Who is the audience?** (execs, engineers, customers, investors, a class…)
   - **How technical are they, and about what?** Pitch depth to *what it means for them*, not how it
     works internally — unless a slide is explicitly about architecture.
   - **What is the deck for?** (sell, inform, teach, update, get a decision.)

2. **Outline the narrative as a slide list before writing any HTML.** Decide the arc and pick one
   component (see the catalog below) for each slide. One idea per slide. See "Structuring the
   narrative" for a default arc — adapt it to the content; don't force it.

3. **Copy the template.** `cp assets/template.html <output>.html` into a writable working dir. Then:
   - Set the `<title>`, the `.brandmark` (top-left wordmark · audience), and the cover slide.
   - Leave the `<style>` block and the `<script>` at the bottom **untouched**.

4. **Replace the example slides with real ones.** Each slide is one
   `<section class="slide" data-i="N">`. Keep `data-i` sequential starting at `0` (slide 0 is the
   cover). Reuse the template's example markup for whichever component each slide needs — duplicate,
   delete, and edit copy. The dot nav, the `NN / NN` counter, and the progress bar are built
   automatically from however many slides exist, so you never hand-maintain them.

5. **Write the copy in the deck's voice** (see "Copy & tone" — this is what makes it good or
   mediocre). Translate features into audience-relevant meaning as you go.

6. **Validate and deliver** (see "Validation checklist"), then present the single `.html` file.

## Structuring the narrative

The components are general-purpose, but most persuasive decks follow a shape like this. Use section
**dividers** to chapter anything longer than ~8 slides.

```
Cover  →  Thesis / the opportunity  →  [Divider A: Why & How]  →  why-this / how-built slides
       →  [Divider B: What's inside]  →  capability / feature / proof slides
       →  [Divider C: Demo]  →  full capability map  →  Close (recap + thank you)
```

Adapt to the genre:
- **Sell / pitch:** problem → your thesis → proof (compare, stats) → what's inside → close on the ask.
- **Teach:** concept → mechanism (aflow/arch) → worked examples (cards) → recap.
- **Status update:** where we are → progress (stats) → what's next (fromto) → risks/asks.

End every *content* slide with a `.punch` — the one-sentence "so what." It's the line the audience
should remember; it carries the slide.

## Component catalog

Every component below is already styled and shown once in `assets/template.html`. Read that file
when you're ready to write slides and copy the exact markup. Pick by what the slide needs to *do*:

| Component | Use it for | Key classes |
|---|---|---|
| **Cover** | Slide 0 only. Title + one-line positioning. | `.cover-meta` `.cover-title` (`.eng` colors part of the name) `.cover-tag` `.cover-foot` |
| **Divider** | Chapter breaks (A / B / C). | `.slide.divider` `.dnum` `.sub` |
| **Cards** (workhorse) | "Here are the N things." 2- or 3-up. | `.cards` (`.cards.two`) · `.card` (+`.hl` to spotlight one) · `.lbl` `h3` `p` |
| **From → To** | Two-part value: "what you keep" + "what we add", or today→tomorrow. | `.fromto` · `.b` (+`.next` for the accent box) · `.arr` |
| **Compare** | Head-to-head proof (vendor vs us, cost/time). | `.compare` · `.side.them` / `.side.us` · `.big` `.row` |
| **Col-pair** | "Two ways to do X" with a router between. | `.colpair` · `.col` `.mtag` · `.mid` `.router` `.pulse` |
| **Process / flow** | Pipelines, lifecycles, an assembly line of steps. | `.aflow` · `.node` `.tg` (`.tg.rd`) `.nm` `.ds` · `.pair` `.ar` |
| **Stats strip** | Headline numbers. Proof beats adjectives. | `.stats` · `.s` `.n` (+`.lime`) `.c` |
| **Status chips** | "What's true today" checklists / confirmations. | `.status` · `.chip.done` / `.chip.alt` |
| **Principles** | Numbered tenets with one "keystone" idea. | `.prin` · `.p` `.pn` · `.p.key` (full-width spotlight) |
| **Capability map** | Dense "everything it does" overview. | `.capgrid` · `.cap` / `.cap.alt` |
| **Architecture** | Layered system diagram, pure CSS (preferred). | `.arch` · `.tier` (+`.core`) `.tlbl` `.box2` `.down` |
| **Image** | A real diagram/screenshot. Embed as base64. | `.archimg` (see note below) |
| **Pills / Seq** | Small badges / a horizontal step sequence. | `.pills` `.pill` · `.seq` `.st` `.ar` (bonus block in template) |

Every content slide also uses the shared building blocks: `.kicker` (mono eyebrow), `h1` (with one
`<em>` accent phrase), `.lede` (intro paragraph), `.note` (small caveat), and `.punch` (the
takeaway). The `.pills` and `.seq` components aren't shown as live slides — their markup is in the
commented "bonus" block at the bottom of the template body.

## The slide rhythm

Almost every content slide follows the same four-beat rhythm. Internalize this — it's the backbone:

```
kicker   →  a 2–4 word mono eyebrow naming the slide's theme
h1       →  the claim, with ONE key phrase wrapped in <em> for the accent color
component →  the evidence/detail (cards, stats, flow, …) — pick from the catalog
punch    →  the single "so what" takeaway, with 1–2 load-bearing words in <strong>
```

Put `data-r="1"`, `"2"`, `"3"`… on each top-level child to stagger its rise-in. Delays are only
defined for `1`–`6`, so **keep each slide to at most ~6 animated groups.**

## Copy & tone — this is what makes it good

The design is solved; the *writing* is where decks live or die. Hold to these:

- **One idea per slide.** If a slide has two arguments, it's two slides.
- **Lead with benefit, not feature.** Translate every technical fact into what it means for *this
  audience*. "Raft consensus with automatic failover" → "stays up 24/7, no maintenance windows."
  A slide explicitly about architecture is the only place to show the mechanism itself.
- **Headlines make a claim.** Not "Performance" but "Built for speed — and built to stay up." Wrap
  the one emotional/benefit word in `<em>` so it catches the accent color.
- **The punch is mandatory on content slides.** One sentence. It's the line they'll repeat.
- **Numbers over adjectives.** Reach for the stats strip with real, defensible figures rather than
  "blazing fast." If a figure is a target or design estimate, say so honestly in a `.note` —
  overclaiming to a sophisticated audience destroys trust.
- **Bold sparingly.** `<strong>` is for the 1–2 words that carry the sentence, not whole clauses.
- **Confident and concrete, never breathless.** Short sentences. Cut filler. No "leverage",
  "synergy", "revolutionary."
- **Tailor the cover line and brandmark to the actual audience** (e.g. "FOR ACME CORP"). A deck that
  names its reader feels made for them — because it is.

## Theming (only if asked, or to match a brand)

The palette lives in the `:root` CSS variables at the top of the template. To rebrand, change the
**variables only** — never the rules that use them. The signature is a dark background with a single
bright accent; keep that structure even when recoloring.

- `--accent` / `--accent-2` — the signature color (default teal). Swap both to match a brand color;
  `--accent-2` is a slightly brighter sibling used for emphasis.
- `--bg` / `--bg-2` / `--surface` — the dark background layers.
- `--blue`, `--danger` — secondary accents (the `.alt` chips, the `.them` compare side).
- Fonts: `Inter` (display/body) + `Roboto Mono` (eyebrow labels). Keep the display/mono pairing.

## Technical notes & gotchas

- **Self-contained, always.** One `.html` file. Embed images as `data:` URIs (base64) — never link
  external files — so the deck travels as a single attachment. The `.archimg` class is for this.
- **`data-i` must be sequential from `0`.** Slide 0 is the cover; it auto-hides the brandmark and
  counter via the `on-cover` body class. Renumber if you insert/remove slides.
- **Don't touch the `<script>` or the structural wrappers** (`.bg-fx`, `.progress`, `.brandmark`,
  `.counter`, `#deck`, `.dots`, `.hint`). Navigation, dots, counter and progress are all derived
  automatically from the slides.
- **Mind vertical overflow.** Slides are full-viewport, centered, `overflow:hidden`. Cramming too
  much clips it. Prefer fewer, denser components over an overstuffed slide; split instead.
- **Fonts load from Google Fonts**, so rendering with Inter needs a network connection; it falls
  back to system sans offline. For a guaranteed-offline deck, embed the fonts as base64 too.
- **Navigation the audience gets for free:** → / Space / PageDown = next; ← / PageUp = prev; click
  right or left half of the screen; Home / End; click any dot. A print stylesheet renders one slide
  per page.

## Validation checklist

Before delivering, confirm:
- `data-i` is sequential `0…N` with no gaps; slide 0 is the cover.
- Every content slide has a `.kicker`, an `h1` with one `<em>`, and a `.punch`.
- No slide exceeds ~6 `data-r` groups.
- `<section>` open/close counts match; the file opens standalone with no console errors.
- All images are embedded data URIs; no external file references remain.
- The `:root` variables, the `<script>`, and the structural wrappers are unchanged.
