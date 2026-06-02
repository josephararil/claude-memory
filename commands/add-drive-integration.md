# /add-drive-integration

Add full Google Drive integration to the current project. This skill carries the complete implementation blueprint — architecture decisions, API details, error handling patterns, and UI conventions — extracted from a production PWA that uses Drive for file upload, file download, and full push/pull sync.

## Step 0 — Require OAuth Client ID

Check `$ARGUMENTS` for a Client ID string. A valid Google OAuth Client ID ends in `.apps.googleusercontent.com`.

If not provided, **stop immediately** and ask the user:
> "To add Google Drive integration I need your OAuth Client ID from Google Cloud Console. It looks like `XXXXXXXXXXXX-xxxx.apps.googleusercontent.com`. Please share it and I'll proceed."

Do not generate a placeholder. Do not proceed without a real Client ID. Once provided, hardcode it as a constant at the top of the store/persistence file.

## Step 1 — Read the project first

Before writing any code:
- Read the project's CLAUDE.md (if it exists) for architecture notes
- Find the main persistence/store file (e.g. `store.js`, `store.ts`, a Redux slice, a Zustand store, etc.)
- Find the Settings screen/component
- Identify the app's localStorage key prefix (e.g. `sw_`, `app_`, `myapp_`) — use it for all Drive localStorage keys
- Identify what data should be synced (localStorage settings + any IndexedDB / persistent store items)
- Identify what file types the app creates that would benefit from Drive backup (images, audio, etc.)

Adapt the implementation to the project's architecture. In a vanilla JS app, add Drive functions to the store file. In a React/TypeScript app, create a `drive.ts` module.

## Step 2 — Load Google Identity Services

Add to the HTML entry point (before the closing `</body>` or in the `<head>`):

```html
<script src="https://accounts.google.com/gsi/client" async></script>
```

This loads the Google Identity Services library (`google.accounts.oauth2`). The `async` attribute is intentional — the Drive functions check for its presence at call time and surface a user-readable error if not yet loaded.

## Step 3 — Core Drive module

Implement the following. Use the app's localStorage key prefix in place of `APP_` below.

### Constants

```js
const DRIVE_CLIENT_ID   = '<CLIENT_ID_FROM_USER>';  // hardcoded from Step 0
const DRIVE_SCOPE       = 'https://www.googleapis.com/auth/drive.file';
const DRIVE_ROOT_FOLDER = '<AppName>';              // derive from project name
// Add subfolders only if the project actually stores typed files (images, audio, etc.)
// e.g. const DRIVE_SUB_IMAGES = 'images';
```

`drive.file` scope is intentional — it only grants access to files the app itself created. Do not use a broader scope.

### Token management (in-memory only)

```js
let _driveTokClient = null;
let _driveToken     = null;
let _driveExpiry    = 0;

function _driveInitClient() {
  if (_driveTokClient) return _driveTokClient;
  if (!window.google?.accounts?.oauth2)
    throw new Error('Google Sign-In library not loaded yet — try again in a moment.');
  _driveTokClient = google.accounts.oauth2.initTokenClient({
    client_id: DRIVE_CLIENT_ID,
    scope: DRIVE_SCOPE,
    callback: () => {},
  });
  return _driveTokClient;
}

function _driveGetToken(forcePrompt) {
  if (!forcePrompt && _driveToken && Date.now() < _driveExpiry - 60000)
    return Promise.resolve(_driveToken);
  const client = _driveInitClient();
  return new Promise((resolve, reject) => {
    const tid = setTimeout(() => reject(new Error('Google auth timed out.')), 90000);
    client.callback = (r) => {
      clearTimeout(tid);
      if (r.error) return reject(new Error(r.error_description || r.error));
      _driveToken  = r.access_token;
      _driveExpiry = Date.now() + (r.expires_in || 3600) * 1000;
      resolve(_driveToken);
    };
    client.requestAccessToken(forcePrompt ? { prompt: 'select_account' } : {});
  });
}
```

**Critical:** The access token lives in `_driveToken` (in-memory) ONLY. Never write it to localStorage, sessionStorage, or IndexedDB. It expires in ~1 hour; `_driveGetToken(false)` silently refreshes via a non-prompting popup when it's close to expiry.

### Authenticated fetch helper

```js
async function _driveJsonFetch(path, opts) {
  const token = await _driveGetToken(false);
  const url   = path.startsWith('https://') ? path : 'https://www.googleapis.com/drive/v3' + path;
  const res   = await fetch(url, {
    ...opts,
    headers: { 'Authorization': 'Bearer ' + token, ...(opts?.headers || {}) },
  });
  if (!res.ok) {
    const e = await res.json().catch(() => ({}));
    throw new Error(e?.error?.message || ('Drive API error ' + res.status));
  }
  return res.json();
}
```

### Folder helpers (find-or-create, idempotent)

```js
async function _driveFindFolder(name, parentId) {
  const q = `name='${name}' and mimeType='application/vnd.google-apps.folder' and '${parentId || 'root'}' in parents and trashed=false`;
  const d = await _driveJsonFetch('/files?q=' + encodeURIComponent(q) + '&fields=files(id)');
  return d.files?.[0]?.id || null;
}

async function _driveCreateFolder(name, parentId) {
  const body = { name, mimeType: 'application/vnd.google-apps.folder' };
  if (parentId) body.parents = [parentId];
  const d = await _driveJsonFetch('/files', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return d.id;
}

async function _driveEnsureFolders() {
  // Skip if all folder IDs are already cached in localStorage
  // Adapt this check to whichever subfolders the project actually needs
  if (localStorage.getItem('APP_drive_root_id')) return;

  let rootId = localStorage.getItem('APP_drive_root_id');
  if (!rootId) {
    rootId = (await _driveFindFolder(DRIVE_ROOT_FOLDER, null))
          || (await _driveCreateFolder(DRIVE_ROOT_FOLDER, null));
    localStorage.setItem('APP_drive_root_id', rootId);
  }
  // Create subfolders here if needed — same pattern as root
}
```

### Data URL → Blob helper

```js
function _dataUrlToBlob(dataUrl) {
  const comma = dataUrl.indexOf(',');
  const mime  = dataUrl.slice(5, dataUrl.indexOf(';'));
  const bytes = Uint8Array.from(atob(dataUrl.slice(comma + 1)), c => c.charCodeAt(0));
  return new Blob([bytes], { type: mime });
}
```

### Multipart file upload

This is the exact format Google's API requires. Do not simplify it.

```js
async function _driveMultipartUpload(filename, blob, folderId) {
  const BOUND = 'sw' + Date.now();
  const enc   = new TextEncoder();
  const meta  = JSON.stringify({ name: filename, parents: [folderId] });
  const parts = [
    enc.encode('--' + BOUND + '\r\nContent-Type: application/json\r\n\r\n' + meta + '\r\n'),
    enc.encode('--' + BOUND + '\r\nContent-Type: ' + blob.type + '\r\n\r\n'),
    new Uint8Array(await blob.arrayBuffer()),
    enc.encode('\r\n--' + BOUND + '--'),
  ];
  const body = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
  let off = 0;
  for (const p of parts) { body.set(p, off); off += p.length; }

  const token = await _driveGetToken(false);
  const res   = await fetch(
    'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
    {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'multipart/related; boundary=' + BOUND,
      },
      body,
    }
  );
  if (!res.ok) {
    const e = await res.json().catch(() => ({}));
    throw new Error(e?.error?.message || ('Drive upload error ' + res.status));
  }
  return (await res.json()).id;
}
```

**Why multipart/related:** This lets you send metadata (filename, parent folder) and the file content in a single HTTP request. Sending them separately requires two requests and risks orphaned files.

### Public API

Implement and export these functions (adapt naming to project conventions):

**`driveIsConnected()`** — `return !!localStorage.getItem('APP_drive_email')`

**`driveGetEmail()`** — `return localStorage.getItem('APP_drive_email') || ''`

**`driveConnect()`** — trigger OAuth popup (`forcePrompt: true` so account picker shows), fetch user email via `/about?fields=user`, store email in localStorage, call `_driveEnsureFolders()`

**`driveDisconnect()`** — call `google.accounts.oauth2.revoke(token, () => {})`, clear `_driveToken`/`_driveExpiry`, remove all `APP_drive_*` localStorage keys

**`driveUploadFile(itemId, dataUrl, subfolderKey, filenamePrefix, extension)`** — calls `_driveEnsureFolders()`, gets folder ID from localStorage, calls `_driveMultipartUpload`. Returns the Drive file ID.

**`driveFetchFile(fileId)`** — fetches `https://www.googleapis.com/drive/v3/files/{fileId}?alt=media` with Bearer token, reads blob, returns data URL.

**`driveGetStorageInfo()`** — calls `/about?fields=storageQuota`, returns quota object `{limit, usage, usageInDrive}`.

**`drivePushSync()`** — serialize all localStorage keys (EXCLUDE API keys, passwords, tokens) + all persistent data → JSON → upload as `{app-name}-sync.json` in the root Drive folder. If the file already exists, use PATCH to update it:
```js
// Update existing file (no metadata change needed, just content):
fetch('https://www.googleapis.com/upload/drive/v3/files/' + fileId + '?uploadType=media', {
  method: 'PATCH',
  headers: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' },
  body: payload,
})
```

**`drivePullSync()`** — find `{app-name}-sync.json` in root Drive folder, download it, restore localStorage keys (EXCLUDE secrets) + persistent data, then `window.location.reload()`. If file not found, throw a user-readable error: "No sync data found in Google Drive. Save to Drive first."

## Step 4 — localStorage keys

Use the app's existing prefix consistently:

| Key | Contents |
|---|---|
| `APP_drive_email` | Connected Google account email; presence = connected |
| `APP_drive_root_id` | Drive folder ID for the root `{AppName}/` folder |
| `APP_drive_{subfolder}_id` | Drive folder ID for each subfolder (if used) |

These keys are safe to include in push/pull sync (they're not secrets).

## Step 5 — UI integration

Add to the Settings screen/page:

1. **Google Drive section** with Connect / Disconnect button
   - Connected state: show the email address returned by `driveGetEmail()`
   - Disconnected state: "Connect Google Drive" button
   - All buttons show a loading state while async operations are in-flight

2. **Push to Drive** button — calls `drivePushSync()`, shows success confirmation or error message

3. **Load from Drive** button — calls `drivePullSync()`, shows loading state (page will reload on success)

4. Every Drive operation must have a visible outcome: success message, error message, or cancel. **No operation should leave the UI in a permanent loading state.**

## Step 6 — Error handling rules

- **Every thrown error** must surface to the user with a readable message — never swallow Drive errors silently
- **Token expiry mid-session:** `_driveGetToken(false)` triggers a silent re-auth popup. If that fails, rethrow with "Google Drive session expired — please reconnect."
- **Folder missing on sync:** catch the "folder ID not found" case in `drivePullSync()` and surface: "Drive folders not found — try disconnecting and reconnecting Drive."
- **No sync file:** surface "No saved data found in Drive. Use 'Save to Drive' first."
- **Upload failure:** surface the Drive API error message directly — it's usually informative (quota exceeded, invalid token, etc.)
- **Network error (fetch failed):** surface "Could not reach Google Drive — check your internet connection."

## Step 7 — Update CLAUDE.md

Document the Drive integration in the project's CLAUDE.md:
- The Drive localStorage key prefix and what each key holds
- What is included vs excluded from push/pull sync
- Folder structure in Drive
- Token behavior (in-memory, 1hr TTL)
