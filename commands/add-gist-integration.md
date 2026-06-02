# /add-gist-integration

Add GitHub Gist integration to the current project for lightweight cloud sync of app settings and preferences. This is the right choice for projects where all meaningful state fits in localStorage (key:value string pairs). If the project stores large binary data (images, audio, video) or IndexedDB records that are too large for a JSON file, use `/add-drive-integration` instead.

## What this integration does

- User enters a GitHub Personal Access Token (PAT) in Settings
- "Save to Cloud" serializes selected localStorage keys to a private GitHub Gist as JSON
- "Load from Cloud" downloads the Gist, restores localStorage, and reloads the page
- One Gist per app, one file inside it, always overwritten on save

## Step 1 — Read the project first

Before writing code:
- Read CLAUDE.md if present
- Find the persistence/store file and Settings screen
- Identify the app's localStorage key prefix (e.g. `app_`, `sw_`, `myapp_`)
- Identify which localStorage keys contain user settings worth syncing
- Identify which localStorage keys should be EXCLUDED from sync (API keys, tokens, passwords, large base64 blobs)
- Understand the project name — it will be used as the Gist description and filename

## Step 2 — PAT storage and validation

Store the GitHub PAT in localStorage. It is a credential, so exclude it from sync.

```js
function getGistPat()  { return localStorage.getItem('APP_gist_pat') || ''; }
function setGistPat(p) {
  if (p) localStorage.setItem('APP_gist_pat', p);
  else   localStorage.removeItem('APP_gist_pat');
}
function hasGistPat()  { return !!localStorage.getItem('APP_gist_pat'); }
function getGistId()   { return localStorage.getItem('APP_gist_id') || ''; }
function setGistId(id) { localStorage.setItem('APP_gist_id', id); }
```

**Validate the PAT** before saving, by calling the GitHub user endpoint:

```js
async function validateGistPat(pat) {
  try {
    const res = await fetch('https://api.github.com/user', {
      headers: {
        'Authorization': 'token ' + pat,
        'Accept': 'application/vnd.github.v3+json',
      },
    });
    return res.ok;
  } catch { return false; }
}
```

Show clear feedback after validation: "Connected to GitHub as @username" (parse the `login` field from `/user` response) or "Invalid token — check and try again."

## Step 3 — Determine what to sync

Look at the project's localStorage usage and propose a sensible `SYNC_KEYS` list. General rules:

**Include in sync:**
- User preferences (theme, language, display settings)
- App configuration (custom prompts, feature flags the user set)
- User-created lightweight data (names, birthdays, small text fields)
- IDs referencing external resources (but not the resources themselves)

**Exclude from sync:**
- API keys and tokens (`APP_gemini_key`, `APP_gist_pat`, `APP_drive_*`, etc.)
- Large base64 blobs (images, audio stored as data URLs — these belong in Drive)
- Ephemeral state (current page, scroll position, temporary flags)
- Migration markers (e.g. `sw_v2_migrated`)

Define as a constant:
```js
const GIST_SYNC_EXCLUDED = new Set([
  'APP_gemini_key',
  'APP_gist_pat',
  'APP_gist_id',
  'APP_drive_email',
  'APP_drive_root_id',
  // ... add any large blobs or sensitive keys specific to this project
]);
```

## Step 4 — Save to Cloud

```js
const GIST_FILENAME = '{app-name}-settings.json';  // e.g. 'myapp-settings.json'
const GIST_DESCRIPTION = '{App Name} Settings';

async function gistPush() {
  const pat = getGistPat();
  if (!pat) throw new Error('No GitHub token — add one in Settings first.');

  // Collect all non-excluded localStorage keys
  const data = {};
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (!GIST_SYNC_EXCLUDED.has(key)) data[key] = localStorage.getItem(key);
  }

  const content = JSON.stringify(data, null, 2);
  const body = {
    description: GIST_DESCRIPTION,
    public: false,
    files: { [GIST_FILENAME]: { content } },
  };

  const existingId = getGistId();
  const url    = existingId
    ? `https://api.github.com/gists/${existingId}`
    : 'https://api.github.com/gists';
  const method = existingId ? 'PATCH' : 'POST';

  const res = await fetch(url, {
    method,
    headers: {
      'Authorization': 'token ' + pat,
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (res.status === 404 && existingId) {
    // Gist was deleted externally — clear the stored ID and create a new one
    setGistId('');
    return gistPush();
  }

  if (!res.ok) {
    const e = await res.json().catch(() => ({}));
    throw new Error(e.message || ('GitHub error ' + res.status));
  }

  const result = await res.json();
  setGistId(result.id);
  return result.id;
}
```

## Step 5 — Load from Cloud

```js
async function gistPull() {
  const pat = getGistPat();
  if (!pat) throw new Error('No GitHub token — add one in Settings first.');

  const gistId = getGistId();
  if (!gistId) throw new Error('No saved data found. Use "Save to Cloud" first.');

  const res = await fetch(`https://api.github.com/gists/${gistId}`, {
    headers: {
      'Authorization': 'token ' + pat,
      'Accept': 'application/vnd.github.v3+json',
    },
  });

  if (res.status === 404) {
    setGistId('');  // stale ID — clear it
    throw new Error('Saved data not found (Gist may have been deleted). Save to Cloud to create a fresh one.');
  }

  if (!res.ok) {
    const e = await res.json().catch(() => ({}));
    throw new Error(e.message || ('GitHub error ' + res.status));
  }

  const gist = await res.json();
  const fileContent = gist.files?.[GIST_FILENAME]?.content;

  if (!fileContent) {
    throw new Error(`Expected file "${GIST_FILENAME}" not found in Gist. The saved data may be from a different app.`);
  }

  let parsed;
  try { parsed = JSON.parse(fileContent); }
  catch { throw new Error('Saved data is corrupted — cannot restore. Save to Cloud to overwrite with current settings.'); }

  // Restore each key, skipping excluded ones
  for (const [key, value] of Object.entries(parsed)) {
    if (!GIST_SYNC_EXCLUDED.has(key) && typeof value === 'string') {
      localStorage.setItem(key, value);
    }
  }

  window.location.reload();
}
```

## Step 6 — UI integration

Add a "Cloud Sync" section to the Settings screen:

**When no PAT is set:**
- Input field: "GitHub Personal Access Token"
- Helper text: "Create a token at github.com/settings/tokens with 'gist' scope"
- "Connect" button — calls `validateGistPat()`, on success saves PAT and shows connected state

**When PAT is set:**
- Status line: "Connected to GitHub as @{username}" (or just "Connected to GitHub")
- "Save to Cloud" button — calls `gistPush()`, shows "Saved" confirmation or error
- "Load from Cloud" button — calls `gistPull()`, shows loading state (page reloads on success)
- "Disconnect" link — clears PAT and Gist ID from localStorage

**All async operations must:**
- Show a loading state while in-flight
- Surface success or error when they settle
- Never leave the UI in a permanent spinner state

## Step 7 — Error handling summary

| Scenario | Response |
|---|---|
| 401 on any API call | "Invalid or expired token — re-enter your GitHub token in Settings." Then clear the stored PAT. |
| 403 (rate limit or insufficient scope) | "GitHub rate limit exceeded, or your token is missing 'gist' scope. Check your token permissions." |
| 404 on pull | "Saved data not found — the Gist may have been deleted. Save to Cloud to create a fresh one." Clear stored Gist ID. |
| Parse error on load | "Saved data is corrupted and cannot be restored." Offer to overwrite with current settings. |
| Network error | "Could not reach GitHub — check your internet connection." |
| Gist ID missing on pull | "No saved data found. Use Save to Cloud first." |

## Step 8 — How to create a PAT (user-facing instructions)

Include this helper text in the UI near the PAT input:

> Create a token at **github.com/settings/tokens** → "Generate new token (classic)" → tick the **`gist`** scope only → copy the token and paste it here. The token is stored only in your browser.

## Step 9 — Update CLAUDE.md

Document in the project's CLAUDE.md:
- The Gist filename and what it contains
- Which localStorage keys are included vs excluded from sync
- The localStorage keys for PAT and Gist ID storage
- A note that Gist sync is for lightweight settings only — large data requires Drive
