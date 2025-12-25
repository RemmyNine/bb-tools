
# Table Of Content
- [[#1) Top parameters used in list|1) Top parameters used in list]]
	- [[#1) Top parameters used in list#A) Classic URL query parameters (reflected & DOM-based)|A) Classic URL query parameters (reflected & DOM-based)]]
	- [[#1) Top parameters used in list#B) POST/body parameters (often stored or reflected in admin panels)|B) POST/body parameters (often stored or reflected in admin panels)]]
	- [[#1) Top parameters used in list#C) Location hash parameters (DOM XSS / parameter smuggling)|C) Location hash parameters (DOM XSS / parameter smuggling)]]
	- [[#1) Top parameters used in list#D) Cookies as input vectors (less expected, high impact)|D) Cookies as input vectors (less expected, high impact)]]
	- [[#1) Top parameters used in list#E) File-upload metadata vectors (stored & blind)|E) File-upload metadata vectors (stored & blind)]]
- [[#2) Payloads|2) Payloads]]
	- [[#2) Payloads#A) Minimal, high-success “smoke tests” ✅|A) Minimal, high-success “smoke tests” ✅]]
	- [[#2) Payloads#B) Attribute injection (stored XSS in profile fields / bios)|B) Attribute injection (stored XSS in profile fields / bios)]]
	- [[#2) Payloads#C) `javascript:` URI payloads (redirect/link vectors)|C) `javascript:` URI payloads (redirect/link vectors)]]
	- [[#2) Payloads#D) Markdown / renderer quirks|D) Markdown / renderer quirks]]
	- [[#2) Payloads#E) Script-context breakouts (templated into JS strings)|E) Script-context breakouts (templated into JS strings)]]
	- [[#2) Payloads#F) HTML-entity style payloads (filter bypass)|F) HTML-entity style payloads (filter bypass)]]
	- [[#2) Payloads#G) Long “blind XSS” style payloads (beacons / exfil)|G) Long “blind XSS” style payloads (beacons / exfil)]]
- [[#3) How To Test XSS? (based on the file)|3) How To Test XSS? (based on the file)]]
	- [[#3) How To Test XSS? (based on the file)#Step 0 — Confirm scope & pick the right XSS type 🧭|Step 0 — Confirm scope & pick the right XSS type 🧭]]
	- [[#3) How To Test XSS? (based on the file)#Step 1 — Find the reflection / sink|Step 1 — Find the reflection / sink]]
		- [[#Step 1 — Find the reflection / sink#Reflected|Reflected]]
		- [[#Step 1 — Find the reflection / sink#DOM|DOM]]
	- [[#3) How To Test XSS? (based on the file)#Step 2 — Identify context and choose the right payload|Step 2 — Identify context and choose the right payload]]
	- [[#3) How To Test XSS? (based on the file)#Step 3 — Reproduce like the reports do (high-confidence flows)|Step 3 — Reproduce like the reports do (high-confidence flows)]]
		- [[#Step 3 — Reproduce like the reports do (high-confidence flows)#A) Reflected XSS in URL params|A) Reflected XSS in URL params]]
		- [[#Step 3 — Reproduce like the reports do (high-confidence flows)#B) Stored XSS in “admin panels / content editors”|B) Stored XSS in “admin panels / content editors”]]
		- [[#Step 3 — Reproduce like the reports do (high-confidence flows)#C) DOM XSS|C) DOM XSS]]
		- [[#Step 3 — Reproduce like the reports do (high-confidence flows)#D) Blind XSS on uploads / support chats|D) Blind XSS on uploads / support chats]]
	- [[#3) How To Test XSS? (based on the file)#Step 4 — Capture evidence 📸|Step 4 — Capture evidence 📸]]
- [[#4) Tips and Tricks|4) Tips and Tricks]]
	- [[#4) Tips and Tricks#A) Always map **source → sink → context**|A) Always map **source → sink → context**]]
	- [[#4) Tips and Tricks#B) When payload length is limited 📏|B) When payload length is limited 📏]]
	- [[#4) Tips and Tricks#C) Look for “non-obvious” fields|C) Look for “non-obvious” fields]]
	- [[#4) Tips and Tricks#D) If it’s “intermittent”|D) If it’s “intermittent”]]
	- [[#4) Tips and Tricks#E) If `<script>` doesn’t run|E) If `<script>` doesn’t run]]
- [[#5) WAF / Filter Bypass (from the file)|5) WAF / Filter Bypass (from the file)]]
	- [[#5) WAF / Filter Bypass (from the file)#A) URL encoding to bypass a WAF|A) URL encoding to bypass a WAF]]
	- [[#5) WAF / Filter Bypass (from the file)#B) HTML entities for `<` and `>`|B) HTML entities for `<` and `>`]]
	- [[#5) WAF / Filter Bypass (from the file)#C) Unicode / escape sequences for parameter smuggling|C) Unicode / escape sequences for parameter smuggling]]
	- [[#5) WAF / Filter Bypass (from the file)#D) Content-Type behavior changes|D) Content-Type behavior changes]]
- [[#6) A Complete Booklet on XSS (based on the file)|6) A Complete Booklet on XSS (based on the file)]]
	- [[#6) A Complete Booklet on XSS (based on the file)#6.1 What XSS is (in one line)|6.1 What XSS is (in one line)]]
	- [[#6) A Complete Booklet on XSS (based on the file)#6.2 XSS types and how they show up in real programs|6.2 XSS types and how they show up in real programs]]
		- [[#6.2 XSS types and how they show up in real programs#Reflected XSS|Reflected XSS]]
		- [[#6.2 XSS types and how they show up in real programs#Stored XSS|Stored XSS]]
		- [[#6.2 XSS types and how they show up in real programs#DOM XSS|DOM XSS]]
		- [[#6.2 XSS types and how they show up in real programs#Blind XSS|Blind XSS]]
	- [[#6) A Complete Booklet on XSS (based on the file)#6.3 Where XSS actually happens: contexts|6.3 Where XSS actually happens: contexts]]
		- [[#6.3 Where XSS actually happens: contexts#A) HTML body context|A) HTML body context]]
		- [[#6.3 Where XSS actually happens: contexts#B) HTML attribute context|B) HTML attribute context]]
		- [[#6.3 Where XSS actually happens: contexts#C) JavaScript string context|C) JavaScript string context]]
		- [[#6.3 Where XSS actually happens: contexts#D) URL/href context|D) URL/href context]]
		- [[#6.3 Where XSS actually happens: contexts#E) Markdown renderers|E) Markdown renderers]]
	- [[#6) A Complete Booklet on XSS (based on the file)#6.4 Impact (realistic outcomes seen across reports)|6.4 Impact (realistic outcomes seen across reports)]]
	- [[#6) A Complete Booklet on XSS (based on the file)#6.5 Mitigation (what actually prevents the examples in this file)|6.5 Mitigation (what actually prevents the examples in this file)]]
	- [[#6) A Complete Booklet on XSS (based on the file)#Quick checklist (copy/paste)|Quick checklist (copy/paste)]]

---

## 1) Top parameters used in list


Below are the **highest-signal parameter patterns** that repeatedly show up in the dataset (query, body, hash, cookies, upload metadata). Use this as a **starting recon checklist**.

### A) Classic URL query parameters (reflected & DOM-based)

- `utm_source`, `utm_campaign` (marketing parameters → often reflected into script/HTML)
- `dest` (redirect/return destination → can become `href` or navigation sink)
- `redirect`, `return_to` (login redirects; can become navigation sinks or template output)
- `miniUrl`, `miniTitle`, `miniColor`, `miniBg` (embed widgets; often templated into HTML/JS)
- `norw`, `atb`, `e` (search/feature flags; can reach DOM sinks like `innerHTML`)
- `lf-content` (3rd-party widgets loading remote content/JSON)
- `refresh`, generic **query string** usage (dangerous when inserted into JS string contexts)

### B) POST/body parameters (often stored or reflected in admin panels)

- `u` (direct injection into output)
- `message[content]` (email/message rendering pipelines; often HTML-sanitizer edge cases)
- `email[]` (array-style parameters; servers sometimes stringify unexpectedly)
- `banned_word[]`, `msCountry` (admin/dashboard forms; stored admin-facing XSS)

### C) Location hash parameters (DOM XSS / parameter smuggling)

- `cvo_sid1` (hash-based params → used to build script requests; can be abused to **inject additional params** like `typ`)

### D) Cookies as input vectors (less expected, high impact)

- Cookie values reflected into HTML (e.g., a cookie like `guvo` reflected into page output)
- Cookie smuggling via parsing quirks (a cookie embedded inside another cookie value)

### E) File-upload metadata vectors (stored & blind)

- `filename` (stored/blind XSS in support/chat tools when filenames get rendered)
- Content-Disposition / inline rendering issues (uploaded file served “inline”)

---

## 2) Payloads

### A) Minimal, high-success “smoke tests” ✅

Use these to detect **context + escaping** quickly.

```html
"><img src=x onerror=alert(1)>
```

```html
"><svg/onload=alert(document.domain)>
```

```html
</script><svg onload=confirm(document.domain)>
```

### B) Attribute injection (stored XSS in profile fields / bios)

```html
<a href="#" title=" target='abc' rel= onmouseover=alert(/XSS/) ">hover me</a>
```

### C) `javascript:` URI payloads (redirect/link vectors)

```text
javascript:alert(document.domain)
```

> These are especially relevant when a parameter becomes `href`, `location`, or a redirect target.

### D) Markdown / renderer quirks

```md
![xss" onload=alert(1);//](a)
```

```md
[XSS](.alert(1);)
```

### E) Script-context breakouts (templated into JS strings)

When a value is inserted inside a JS string, you often need to **close the string/function**, run code, then repair parsing.

Example pattern (conceptual):

```text
<close string> ; <close callback> ; alert(1) ; </script>
```

### F) HTML-entity style payloads (filter bypass)

If `<` and `>` are filtered, try entity variants (example format seen in reports):

```text
... &lt;script>alert(1)&lt;/script&gt ...
```

### G) Long “blind XSS” style payloads (beacons / exfil)

For blind XSS, payloads often encode URLs and then send data out. A common style is **ASCII via `String.fromCharCode(...)`** + `XMLHttpRequest`.

> Keep these in a controlled test environment (your own endpoint, your own data).

---

## 3) How To Test XSS? (based on the file)

### Step 0 — Confirm scope & pick the right XSS type 🧭

- **Reflected XSS**: input appears in response immediately.
- **Stored XSS**: input saved and later rendered to you/admin/other users.
- **DOM XSS**: source is client-side (`location.search`, `location.hash`, `window.name`, localStorage) and sink is DOM (`innerHTML`, `document.write`, dangerous templating).
- **Blind XSS**: payload triggers in a different user’s context (support agent, admin tool, log viewer).

### Step 1 — Find the reflection / sink

#### Reflected

1. Pick a candidate param (from the list above).
2. Inject a **marker**: `xss12345`
3. Search the response for the marker:
    - Raw HTML
    - Inside attributes
    - Inside `<script>` blocks
    - Inside JSON or JS strings

#### DOM

1. Open DevTools → **Sources** and **Search** for:
    - `innerHTML`, `outerHTML`, `document.write`
    - `insertAdjacentHTML`, `eval`, `new Function`
2. Track **sources**:
    - `location.search`, `location.hash`, `window.name`
    - `localStorage`, `postMessage` data
3. Reproduce with a PoC URL and verify the sink executes.

### Step 2 — Identify context and choose the right payload

**Context drives payload.** Don’t brute force blindly.

|Context|What it looks like|Good first payload|
|---|---|---|
|HTML body|`... YOUR_INPUT ...`|`"><img src=x onerror=alert(1)>`|
|HTML attribute|`attr="YOUR_INPUT"`|`" onmouseover=alert(1) x="`|
|Script string|`var a="YOUR_INPUT";`|`";alert(1);//`|
|URL/href|`<a href="YOUR_INPUT">`|`javascript:alert(1)`|
|Markdown render|`[x](...)` / `![](...)`|`![x" onload=alert(1);//](a)`|
|DOM sink|`innerHTML = ...`|`"><svg/onload=alert(1)>`|

### Step 3 — Reproduce like the reports do (high-confidence flows)

#### A) Reflected XSS in URL params

- Use Burp/Repeater to inject payloads.
- If blocked, try **encoding** variations (see bypass section).

#### B) Stored XSS in “admin panels / content editors”

- Identify fields that get rendered later:
    - Titles, bios, names, alt text, “custom message” strings, wiki markdown, etc.
- Save payload, then revisit the page that renders it (often list views or detail pages).

#### C) DOM XSS

- Use the PoC style:
    - `?param="><img src=/ onerror=alert(1)>`
- Confirm the sink is client-side by viewing page source vs. runtime DOM.

#### D) Blind XSS on uploads / support chats

- Upload a file and intercept request.
- Modify `filename` in transit.
- Trigger rendering in the back-office UI (support queue, ticket view, attachment list).

### Step 4 — Capture evidence 📸

- Screenshots of payload in request + alert.
- Exact URL and parameter.
- Browser/version (some reports explicitly note Firefox vs Chromium).
- Explain context (“inside script string”, “inside href”, “innerHTML sink”, etc).

---

## 4) Tips and Tricks

### A) Always map **source → sink → context**

You’re not “testing XSS”, you’re testing a **specific injection point**.

- Source: where input comes from (URL, hash, cookie, file name, form field)
- Sink: where it lands (template HTML, JS string, DOM innerHTML, markdown renderer)
- Context: HTML body vs attribute vs JS vs URL vs CSS

### B) When payload length is limited 📏

- Use very short triggers: `<svg/onload=alert(1)>`
- Use _“eval the URL”_ style patterns if the sink allows it (a trick shown in Cloud Save context).

### C) Look for “non-obvious” fields

Real reports commonly hit:

- **Hidden input** values (e.g., redirect fields)
- **Array parameters** (`param[]=`)
- **Cookie values**
- **Filename metadata**
- **Admin search/report pages** (logs, filters, dashboards)

### D) If it’s “intermittent”

- Try different browsers / clean session / VPN off
- Check caching behavior (some embeds vary by cookie)
- Remove tracking protections / strict blockers temporarily (for reproduction)

### E) If `<script>` doesn’t run

- Use event handlers (`onerror`, `onload`, `onmouseover`)
- Try `svg` payloads
- If CSP blocks inline JS, pivot to framework gadgets (forms/controllers) or non-script injections (phishing UI)

---

## 5) WAF / Filter Bypass (from the file)

These are bypass patterns explicitly demonstrated in the dataset (not theoretical).

### A) URL encoding to bypass a WAF

- Encode breaking characters and tag closers.
- Typical goal: **end the current string / function**, run code, then close `</script>`.

### B) HTML entities for `<` and `>`

- If a filter blocks literal `< >`, try `&lt;` / `&gt;` (or similar entity tricks).

### C) Unicode / escape sequences for parameter smuggling

- Use escaped `&` equivalents (e.g., `\u0026`) to inject extra parameters through a single “trusted” parameter.
- Replace blocked semicolons with `%3b` where needed.

### D) Content-Type behavior changes

- A `callback` parameter can flip endpoints to JavaScript responses (`application/javascript`), changing how the browser parses content.
- The inverse is also dangerous: missing Content-Type can be treated as `text/html` by the browser.

---

## 6) A Complete Booklet on XSS (based on the file)

### 6.1 What XSS is (in one line)

**XSS happens when untrusted input reaches an executable browser context without correct, context-aware encoding/sanitization.**

### 6.2 XSS types and how they show up in real programs

#### Reflected XSS

- Fast to find: `?param=PAYLOAD`
- Often lives in:
    - marketing/tracking params (`utm_*`)
    - embed widgets (`miniUrl`)
    - redirect flows (`dest`, `redirect`)

#### Stored XSS

- Highest business impact (affects other users/admins).
- Often lives in:
    - titles, bios, descriptions, wiki pages
    - dashboards and admin forms
    - uploaded metadata (filenames), issue trackers

#### DOM XSS

- Often missed by backend-focused reviews.
- Classic pattern:
    - **source** = `location.search` / `location.hash`
    - **sink** = `innerHTML` / templating
- Also can chain through:
    - localStorage (saved settings), window.name, postMessage

#### Blind XSS

- Common in:
    - support software
    - moderation tools
    - ticketing systems
    - attachment viewers
- Testing pattern:
    - inject payload that calls back to your controlled endpoint
    - wait for a staff/admin view event

### 6.3 Where XSS actually happens: contexts

#### A) HTML body context

- Best payload: `"><img src=x onerror=alert(1)>`

#### B) HTML attribute context

- Inject new attributes/events: `" onmouseover=alert(1) x="`

#### C) JavaScript string context

- Break out: `";alert(1);//`
- Sometimes you must close nested callbacks/functions (as seen in some reports).

#### D) URL/href context

- `javascript:` payloads (watch for sanitizers that block schemes)

#### E) Markdown renderers

- Image/link syntaxes can create attribute injection (`onload`, etc.)

### 6.4 Impact (realistic outcomes seen across reports)

- Session/token compromise (when readable / accessible)
- Phishing UI inside trusted origin (render fake login)
- Account takeover via chained flows (e.g., token leakage + XSS)
- Administrative actions (CSRF-like actions via JS if privileged user executes)
- Wormable stored XSS (payload spreads via user-generated content)

### 6.5 Mitigation (what actually prevents the examples in this file)

✅ **Output encode by context**

- HTML: escape `< > & " '`
- Attributes: strict attribute encoding + quoted attributes
- JS: JS-string escaping or JSON-safe encoding; avoid concatenating untrusted strings
- URLs: allowlist `https://` and safe paths; block `javascript:` / `data:` where not needed

✅ **Use a proven sanitizer for rich text**

- Apply correct policies for HTML, SVG, MathML (SVG is a common bypass vector)

✅ **Reduce dangerous sinks**

- Prefer `textContent` over `innerHTML`
- Avoid `document.write`, `eval`, `new Function`

✅ **CSP**

- Nonce-based CSP blocks many inline payloads
- Still validate/sanitize: CSP is defense-in-depth, not a fix

✅ **Safer redirects**

- Validate redirect targets against an allowlist
- Never allow arbitrary schemes (`javascript:`)

✅ **File handling**

- Force safe `Content-Disposition` for user uploads (avoid rendering attacker-controlled content inline)
- Sanitize/escape filenames at render time

✅ **Headers**

- Modern best practice: rely on proper encoding & CSP (legacy `X-XSS-Protection` exists in reports but is not a primary defense today)

---

### Quick checklist (copy/paste)

- [ ] Identify input source: query / body / hash / cookie / filename
- [ ] Find sink: template HTML / attribute / JS string / innerHTML / href
- [ ] Choose context-correct payload (don’t brute force)
- [ ] Try encode/entity/unicode bypass only after you confirm reflection
- [ ] Verify stored vs reflected vs DOM (view-source vs runtime DOM)
- [ ] Document exact URL, param, payload, browser, and impact narrative

---
