---
name: feedback-verification
description: "Don't over-invest in preview debugging; trust on-disk code; user prefers pragmatic over perfect"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d368c5bf-48fe-475c-8245-99a55ed90487
---

Don't spiral on preview/browser cache issues. If the code is correct on disk and logic is sound, trust it and move on rather than spending multiple rounds fighting the browser cache.

**Why:** User said "don't stress too hard mate" when I kept fighting a service worker cache issue during verification. They value pragmatism over exhaustive in-browser proof.

**How to apply:** One or two verification attempts is enough. If the preview is being stubborn (cache, SW, etc.), note it briefly and trust the code. Don't keep retrying.

**Related gotcha:** The preview tool only serves **committed** files — uncommitted edits are invisible to the browser. Always commit before trying to verify in the browser preview.
