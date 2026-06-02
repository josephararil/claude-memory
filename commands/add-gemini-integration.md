# /add-gemini-integration

Add Gemini AI integration to the current project. This skill provides the complete technical blueprint for calling the Gemini API — endpoints, payload formats, error handling, retry logic, timeout patterns, and common pitfalls. It covers text generation, image generation, and TTS audio generation.

**This skill is context-driven.** The user's invocation tells you what to build. Only implement what was asked. If the user asks for a "Generate" button that calls a text model, implement text generation only. Do not add image or audio generation unless explicitly requested.

The `$ARGUMENTS` field contains the user's description of what they want. Read it carefully before doing anything.

## Step 1 — Read the project first

Before writing code:
- Read CLAUDE.md if present
- Find the persistence/store file and the relevant screen/component
- Understand how the project makes API calls today (if at all)
- Identify the app's localStorage key prefix for storing the API key and model settings
- Understand what the user wants the integration to do, based on `$ARGUMENTS`

## Step 2 — API key management

The user provides their own Gemini API key. Store it in localStorage.

```js
function getApiKey()  { return localStorage.getItem('APP_gemini_key') || ''; }
function setApiKey(k) { localStorage.setItem('APP_gemini_key', k); }
function hasApiKey()  { return !!localStorage.getItem('APP_gemini_key'); }
```

**Validate the key** before saving, by calling the models list endpoint:

```js
async function validateApiKey(k) {
  try {
    const r = await fetch('https://generativelanguage.googleapis.com/v1beta/models', {
      headers: { 'x-goog-api-key': k },
    });
    return r.ok;
  } catch { return false; }
}
```

Add a Settings entry where the user can input, validate, and save their API key. Show clear feedback: "Valid key saved" or "Invalid key — check and try again."

## Step 3 — Base URL and authentication

**Base URL:** `https://generativelanguage.googleapis.com/v1beta/models/{model}:{method}`

**Auth header:** `x-goog-api-key: {key}` — this is the correct header. Do not use `Authorization: Bearer`.

**Always use `v1beta`** — not `v1`. The `v1` endpoint rejects newer `generationConfig` fields like `responseModalities` silently or with a 400.

## Step 4 — Text generation

Use this when the user wants to generate text, structured data, or JSON from a prompt.

**Endpoint:** `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`

**Default model:** `gemini-2.5-flash` — fast, reliable, good at following JSON schemas.

**Basic payload:**
```js
{
  systemInstruction: { parts: [{ text: systemPrompt }] },  // omit if no system prompt
  contents: [{
    role: 'user',
    parts: [{ text: userMessage }],
  }],
  generationConfig: {
    // For structured JSON output:
    responseMimeType: 'application/json',
    responseSchema: YOUR_SCHEMA,  // omit if not using structured output
  },
}
```

**Calling the API:**
```js
async function callTextApi(prompt, systemPrompt, signal) {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${getTextModel()}:generateContent`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': getApiKey() },
      signal,
      body: JSON.stringify({
        ...(systemPrompt ? { systemInstruction: { parts: [{ text: systemPrompt }] } } : {}),
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: 'application/json', responseSchema: YOUR_SCHEMA },
      }),
    }
  );

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(`Gemini error ${res.status}: ${body?.error?.message || 'Unknown error'}`);
  }

  const data = await res.json();

  if (data.promptFeedback?.blockReason) {
    throw new Error('The request was blocked by Gemini — try rephrasing.');
  }

  try {
    return JSON.parse(data.candidates[0].content.parts[0].text);
  } catch {
    throw new Error('Gemini returned an unexpected response format. Please try again.');
  }
}
```

**Structured output schema format** (Gemini uses uppercase type names):
```js
const MY_SCHEMA = {
  type: 'OBJECT',
  properties: {
    title:   { type: 'STRING' },
    count:   { type: 'INTEGER' },
    items:   { type: 'ARRAY', items: { type: 'STRING' } },
    enabled: { type: 'BOOLEAN' },
  },
  required: ['title', 'items'],
  propertyOrdering: ['title', 'count', 'items', 'enabled'],  // controls output order
};
```

## Step 5 — Image generation (only if requested)

Use this when the user explicitly asks for AI-generated images.

**Endpoint:** `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`

**Default model:** `gemini-2.5-flash-image`

### Critical payload requirements (breaking if omitted)

```js
{
  contents: [{ role: 'user', parts: [{ text: prompt }] }],
  generationConfig: { responseModalities: ['TEXT', 'IMAGE'] },
}
```

Both `role: 'user'` and `generationConfig: { responseModalities: ['TEXT', 'IMAGE'] }` are **required**. Omitting either causes a 400 or a response with no image part. This must be on `v1beta` — `v1` rejects `responseModalities`.

### Timeout and abort

Always wrap image calls with a hard timeout. Image generation can hang indefinitely without one:

```js
async function callImageApiOnce(prompt, signal, timeoutMs) {
  const ctrl    = new AbortController();
  const timerId = setTimeout(() => ctrl.abort(), timeoutMs);
  if (signal) signal.addEventListener('abort', () => ctrl.abort(), { once: true });

  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${getImageModel()}:generateContent`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': getApiKey() },
        signal: ctrl.signal,
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: { responseModalities: ['TEXT', 'IMAGE'] },
        }),
      }
    );

    if (!res.ok) {
      const errBody = await res.json().catch(() => ({}));
      throw new Error(`Gemini error ${res.status}: ${errBody?.error?.message || 'Unknown error'}`);
    }

    const data      = await res.json();
    const candidate = data?.candidates?.[0];

    if (candidate?.finishReason === 'PROHIBITED_CONTENT') {
      throw new Error('PROHIBITED_CONTENT');
    }

    const imgPart = (candidate?.content?.parts || [])
      .find(p => p.inlineData || p.inline_data);

    if (!imgPart) throw new Error('No image in response.');

    const inlineData = imgPart.inlineData || imgPart.inline_data;
    return compressToWebp(inlineData.data);  // see image compression helper below
  } finally {
    clearTimeout(timerId);
  }
}
```

### Retry wrapper

Never expose `callImageApiOnce` directly. Always wrap with retry logic:

```js
async function callImageApi(prompt, signal, onRetry) {
  if (signal?.aborted) return null;

  // Attempt 1 (45s)
  try { return await callImageApiOnce(prompt, signal, 45000); }
  catch (e) {
    if (e.message === 'PROHIBITED_CONTENT')
      throw new Error('Gemini rejected this image prompt — please try different wording.');
    if (signal?.aborted) return null;
  }

  // Attempt 2 (30s) — notify UI
  onRetry?.('retrying');
  try { return await callImageApiOnce(prompt, signal, 30000); }
  catch (e) {
    if (e.message === 'PROHIBITED_CONTENT')
      throw new Error('Gemini rejected this image prompt — please try different wording.');
    if (signal?.aborted) return null;
  }

  // All attempts failed — return null, caller decides whether to surface this
  return null;
}
```

**PROHIBITED_CONTENT:** throw immediately and surface to the user. Do not retry. The prompt won't pass on a subsequent attempt.

**Other failures after all retries:** return `null`. For non-critical images (e.g. a cover that the app can work without), the caller should handle null gracefully — save the item without the image and show a non-blocking notification. For critical images, surface an error.

### Image compression helper (WebP via canvas)

```js
function compressToWebp(base64Png) {
  return new Promise((resolve) => {
    const img = new Image();
    img.onload = () => {
      try {
        const canvas = document.createElement('canvas');
        canvas.width  = img.naturalWidth;
        canvas.height = img.naturalHeight;
        canvas.getContext('2d').drawImage(img, 0, 0);
        const result = canvas.toDataURL('image/webp', 0.6);
        resolve(result.startsWith('data:image/webp') ? result : `data:image/png;base64,${base64Png}`);
      } catch { resolve(`data:image/png;base64,${base64Png}`); }
    };
    img.onerror = () => resolve(`data:image/png;base64,${base64Png}`);
    img.src = `data:image/png;base64,${base64Png}`;
  });
}
```

## Step 6 — TTS / audio generation (only if requested)

Use this when the user explicitly asks for text-to-speech or narration audio.

**Endpoint:** `POST https://generativelanguage.googleapis.com/v1beta/models/{model}:streamGenerateContent`

Note: uses `streamGenerateContent`, not `generateContent`.

**Default model:** `gemini-2.5-flash-preview-tts`

**Default voice:** `Zephyr` — others available: `Aoede`, `Charon`, `Fenrir`, `Kore`, `Puck`

```js
async function generateAudio(text, signal) {
  if (signal?.aborted) return null;

  const ctrl    = new AbortController();
  const timerId = setTimeout(() => ctrl.abort(), 60000);  // 60s hard timeout
  if (signal) signal.addEventListener('abort', () => ctrl.abort(), { once: true });

  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${getAudioModel()}:streamGenerateContent`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': getApiKey() },
        signal: ctrl.signal,
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{ text }] }],
          generationConfig: {
            responseModalities: ['audio'],
            temperature: 0.5,
            speech_config: {
              voice_config: {
                prebuilt_voice_config: { voice_name: getAudioVoice() },
              },
            },
          },
        }),
      }
    );

    if (!res.ok) {
      const errBody = await res.json().catch(() => ({}));
      throw new Error(`TTS error ${res.status}: ${errBody?.error?.message || 'Unknown error'}`);
    }

    // streamGenerateContent returns a JSON array of chunks
    const chunks   = await res.json();
    const pcmParts = [];

    for (const chunk of (Array.isArray(chunks) ? chunks : [chunks])) {
      for (const part of (chunk?.candidates?.[0]?.content?.parts || [])) {
        const inlineData = part.inlineData || part.inline_data;
        if (inlineData?.data) pcmParts.push(inlineData.data);
      }
    }

    if (!pcmParts.length) return null;

    // Decode and assemble PCM chunks
    const decoded = pcmParts.map(b64 => Uint8Array.from(atob(b64), c => c.charCodeAt(0)));
    const total   = decoded.reduce((n, a) => n + a.length, 0);
    const combined = new Uint8Array(total);
    let off = 0;
    for (const arr of decoded) { combined.set(arr, off); off += arr.length; }

    const wavBuf    = pcmToWav(combined, 24000, 1, 16);
    const wavBase64 = uint8ArrayToBase64(new Uint8Array(wavBuf));
    return `data:audio/wav;base64,${wavBase64}`;
  } catch (e) {
    if (e.name !== 'AbortError') console.warn('TTS failed:', e.message);
    return null;  // TTS is non-critical — return null and let the caller handle
  } finally {
    clearTimeout(timerId);
  }
}
```

### PCM → WAV conversion

The Gemini TTS response is raw PCM audio. You must wrap it in a WAV header before it can be played:

```js
function pcmToWav(pcmBytes, sampleRate, numChannels, bitsPerSample) {
  const dataLen = pcmBytes.byteLength || pcmBytes.length;
  const buf  = new ArrayBuffer(44 + dataLen);
  const view = new DataView(buf);
  const writeStr = (off, s) => { for (let i = 0; i < s.length; i++) view.setUint8(off + i, s.charCodeAt(i)); };
  writeStr(0, 'RIFF');
  view.setUint32(4,  36 + dataLen, true);
  writeStr(8, 'WAVE');
  writeStr(12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);  // PCM
  view.setUint16(22, numChannels, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate * numChannels * (bitsPerSample / 8), true);
  view.setUint16(32, numChannels * (bitsPerSample / 8), true);
  view.setUint16(34, bitsPerSample, true);
  writeStr(36, 'data');
  view.setUint32(40, dataLen, true);
  new Uint8Array(buf, 44).set(pcmBytes);
  return buf;
}

function uint8ArrayToBase64(bytes) {
  let binary = '';
  const CHUNK = 8192;
  for (let i = 0; i < bytes.length; i += CHUNK) {
    binary += String.fromCharCode.apply(null, bytes.subarray(i, Math.min(i + CHUNK, bytes.length)));
  }
  return btoa(binary);
}
```

**Parameters:** 24000 Hz sample rate, 1 channel (mono), 16-bit — these match the Gemini TTS output format exactly.

## Step 7 — Loading states and error handling (non-negotiable)

**Every Gemini operation must have a finite lifecycle.** This means:

1. **Before call:** show a loading/spinner state, disable the trigger button
2. **On success:** show the result, clear loading state
3. **On error:** show the error message, clear loading state, re-enable the button
4. **On cancel:** clear loading state, re-enable the button

**Every operation must have a Cancel button** (or equivalent escape) if it takes more than ~2 seconds. Wire up an `AbortController` and pass its `signal` to all fetch calls.

```js
// Pattern for a button-triggered Gemini call
let abortCtrl = null;

async function handleGenerate() {
  if (abortCtrl) return;  // already in progress
  abortCtrl = new AbortController();
  setLoading(true);
  setError(null);

  try {
    const result = await callGeminiFunction(input, abortCtrl.signal);
    if (result !== null) setResult(result);
    else setError('Generation failed — please try again.');
  } catch (e) {
    if (e.name !== 'AbortError') setError(e.message);
  } finally {
    abortCtrl = null;
    setLoading(false);
  }
}

function handleCancel() {
  abortCtrl?.abort();
}
```

**Specific rules:**
- `promptFeedback.blockReason` or `PROHIBITED_CONTENT` → show the error, never retry silently
- HTTP 4xx → parse `error.message` from the response body and show it (it's usually descriptive)
- HTTP 5xx → "Gemini is currently unavailable — please try again in a moment."
- Timeout (AbortError from the inner timer) → "Request timed out — please try again."
- User cancel (AbortError from the outer signal) → clear loading state silently
- API key missing → "Please add your Gemini API key in Settings before using this feature."

**Never:** leave a spinner running after the operation has settled. Never retry silently without the user knowing. Never swallow errors without surfacing them.

## Step 8 — Model configuration (optional but recommended)

If the project has a Settings screen, add inputs for the model names so the user can update them without code changes:

```js
function getTextModel()  { return localStorage.getItem('APP_text_model')  || 'gemini-2.5-flash'; }
function setTextModel(m) { localStorage.setItem('APP_text_model', m); }

function getImageModel() { return localStorage.getItem('APP_image_model') || 'gemini-2.5-flash-image'; }
function setImageModel(m){ localStorage.setItem('APP_image_model', m); }

function getAudioModel() { return localStorage.getItem('APP_audio_model') || 'gemini-2.5-flash-preview-tts'; }
function setAudioModel(m){ localStorage.setItem('APP_audio_model', m); }

function getAudioVoice() { return localStorage.getItem('APP_audio_voice') || 'Zephyr'; }
function setAudioVoice(v){ localStorage.setItem('APP_audio_voice', v); }
```

Only add the helpers for the model types actually used by the project.

## Step 9 — Update CLAUDE.md

Document in the project's CLAUDE.md:
- Which Gemini features were added (text / image / audio)
- The localStorage keys for API key and model settings
- The API endpoint structure and authentication method
- Any project-specific prompt or schema details
