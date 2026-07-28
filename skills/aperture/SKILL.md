---
name: aperture
description: Scaffold a new project using the Aperture design system. Use when the user types /aperture, says "scaffold with Aperture", "start a new app with Aperture", "apply the Aperture design system", or "create a new project in the Aperture design language".
version: 1.0.0
---

# Aperture — Scaffold New Project

Scaffolds a clean new single-page app using the Aperture design system.

## Design system location

All canonical assets live at `C:\Users\jharari\Documents\GitHub\aperture\` - `https://github.com/josephararil/aperture`

The core stylesheet is `colors_and_type.css` — all tokens (light + dark), the type scale, and ready-made `.btn` / `.chip` / `.card` / `.tile` / `.t-*` classes.

## Steps

1. **Ask the user** (in a single message, not one at a time):
   - App name?
   - One-line tagline (sentence case, no emoji, under ~60 chars)?
   - Accent color? Options: blue `#0071e3` (default), indigo `#5e5ce6`, green `#1d9d57`, orange `#f5731f`, pink `#e0489a`, graphite `#3a3a3c`

2. Clone `https://github.com/josephararil/aperture`

2. **Read** `~\aperture\colors_and_type.css`

3. **Copy** `colors_and_type.css` into the current project root (via Write tool — full content verbatim)

4. **Generate `index.html`** — a minimal Aperture-branded starter:

   ```html
   <!DOCTYPE html>
   <html lang="en" data-theme="light">
   <head>
     <meta charset="UTF-8" />
     <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
     <meta name="description" content="[tagline]" />
     <title>[App name]</title>
     <link rel="stylesheet" href="colors_and_type.css" />
     <style>
       /* Page-specific layout — tokens come from colors_and_type.css */
       * , *::before, *::after { box-sizing: border-box; }
       html, body { margin: 0; padding: 0; min-height: 100vh; }
       html { -webkit-text-size-adjust: 100%; }
       a { color: inherit; text-decoration: none; }
       button { font: inherit; color: inherit; background: none; border: 0; cursor: pointer; }

       .shell { max-width: 1180px; margin: 0 auto; padding: 0 24px 120px; }

       /* Top bar */
       .topbar {
         position: sticky; top: 0; z-index: 50;
         backdrop-filter: saturate(180%) blur(20px);
         -webkit-backdrop-filter: saturate(180%) blur(20px);
         background: var(--topbar-bg);
         border-bottom: 1px solid transparent;
         transition: border-color 0.3s var(--ease);
       }
       .topbar.scrolled { border-bottom-color: var(--hairline); }
       .topbar-inner {
         max-width: 1180px; margin: 0 auto;
         height: 54px; padding: 0 24px;
         display: flex; align-items: center; justify-content: space-between;
       }
       .wordmark { font-weight: 600; font-size: 15px; letter-spacing: -0.02em; }
       .seg { display: flex; background: var(--surface-sunk); border-radius: 11px; padding: 3px; gap: 2px; }
       .seg button {
         padding: 6px 10px; border-radius: 8px; font-size: 12px; font-weight: 500;
         color: var(--text-2); transition: all 0.18s var(--ease);
       }
       .seg button[aria-pressed="true"] { background: var(--surface); color: var(--text); box-shadow: var(--shadow-rest); }

       /* Hero */
       .hero { padding: 80px 0 52px; }
       .hero .eyebrow { font-size: 13px; font-weight: 600; letter-spacing: 0.02em; color: var(--accent); margin: 0 0 18px; }

       /* Footer */
       .footer {
         margin-top: 40px; padding-top: 28px; border-top: 1px solid var(--hairline);
         font-size: 13px; color: var(--text-3);
         display: flex; justify-content: space-between;
       }
     </style>
   </head>
   <body>

     <header class="topbar" id="topbar">
       <div class="topbar-inner">
         <span class="wordmark">[App name]</span>
         <div class="seg" id="seg-theme">
           <button data-val="light">Light</button>
           <button data-val="dark">Dark</button>
           <button data-val="auto">Auto</button>
         </div>
       </div>
     </header>

     <main class="shell" id="top">
       <section class="hero">
         <p class="eyebrow">[EYEBROW LABEL]</p>
         <h1 class="t-hero">[App name], <span class="soft">[soft tail of the headline].</span></h1>
         <p class="t-lede" style="max-width:52ch;margin-top:18px;">[tagline — one sentence, first-person, sentence case, no period stacking]</p>
       </section>

       <!-- Main content goes here -->

       <footer class="footer">
         <span>© <span id="year"></span> Joseph Harari</span>
       </footer>
     </main>

     <script>
       // Year
       document.getElementById("year").textContent = new Date().getFullYear();

       // Theme
       const root = document.documentElement;
       const seg = document.getElementById("seg-theme");
       function applyTheme(val) {
         const t = val === "auto"
           ? (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
           : val;
         root.setAttribute("data-theme", t);
         seg.querySelectorAll("button").forEach(b => b.setAttribute("aria-pressed", b.dataset.val === val));
         localStorage.setItem("theme", val);
       }
       seg.addEventListener("click", e => { if (e.target.dataset.val) applyTheme(e.target.dataset.val); });
       applyTheme(localStorage.getItem("theme") || "auto");

       // Sticky topbar border
       const topbar = document.getElementById("topbar");
       window.addEventListener("scroll", () => topbar.classList.toggle("scrolled", window.scrollY > 4), { passive: true });
     </script>
   </body>
   </html>
   ```

   Replace all `[...]` placeholders with the user's answers. Set `--accent` in a `:root` override if they chose a non-default accent.

5. **Suggest 3 next steps** tailored to what they said they're building (e.g. data table, settings popover, card grid, modal).

## Design rules (always apply)

- **No emoji** — ever. Identity comes from gradient + glyph, not emoji.
- **First-person, sentence case** copy. Quiet confidence. Never hype.
- **One accent** throughout — set via `--accent: #hex;` in `:root`.
- **App identity**: each app earns a 2–3 stop diagonal (140°) gradient + one white rounded-line SVG glyph. Don't skip this.
- **UI chrome icons**: recommend Lucide (closest match to the rounded-line style). Keep bespoke glyphs for app identity.
- **Buttons, chips, cards**: use the ready-made classes in `colors_and_type.css` — don't reinvent.

## Full reference

- `README.md` — full design system doc
- `preview/` — design system specimens (colors, type, spacing, components)
- `ui_kits/app-index/` — the canonical reference implementation (app-index UI kit)
