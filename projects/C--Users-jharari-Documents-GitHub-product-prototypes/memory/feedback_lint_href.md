---
name: CI lint — href/src in JavaScript files
description: The broken-ref lint scans .js files too; dynamic href values cause CI failures
type: feedback
originSessionId: 0936da68-eed2-49a1-8795-9a9a4fa19471
---
The CI `Check broken relative references` lint uses grep to find `href`, `src`, or `url(` in ALL files under `prototypes/`, including `.js`. It extracts the value after the keyword and checks if it exists as a file.

**Patterns that fail:**
- `a.href = url` — extracts `url` as a relative path, file not found
- `Object.assign(a, { href: url, download: '...' })` — extracts a multi-word string
- `a.setAttribute('href', url)` — still matches `href` and extracts `, url`

**Pattern that passes:**
```js
a.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(content);
a.download = `export_${Date.now()}.csv`;
a.click();
```
`data:` is explicitly whitelisted in the lint rule.

**Why:** The lint regex is `(src|href|url\()\s*=?\s*["'(]?[^"'()]+` — greedy, scans every file.

**How to apply:** Never write bare `href` or `src` in JavaScript with a dynamic variable value. Always use `data:` URIs for programmatic download links.
