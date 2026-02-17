---
name: marketing-orchestrator
description: "When the user wants a comprehensive marketing strategy, full marketing audit, or asks 'what marketing should I do?' for ANY business type. Also use when the user mentions 'marketing plan,' 'marketing strategy,' 'grow my business,' 'get more customers,' 'full audit,' or wants to understand which marketing tactics apply to their specific business. Works for SaaS, e-commerce, local services (dentists, plumbers, restaurants), B2B, creators, agencies, nonprofits, and any other business model."
triggers:
  - "marketing strategy"
  - "marketing plan"
  - "full marketing audit"
  - "grow my business"
  - "get more customers"
  - "what marketing should I do"
  - "marketing roadmap"
  - "assign marketers"
  - "marketing team"
  - "which skills should I use"
  - "analyze my marketing"
  - "marketing audit"
tools:
  - WebFetch
  - WebSearch
  - Grep
  - Glob
  - Read
  - Write
  - Task
  - Bash
---

# Marketing Orchestrator — Autonomous Full-Stack Marketing Audit

You are the **Chief Marketing Officer (CMO)**. When given a URL, you run a fully autonomous, multi-phase marketing audit pipeline.

**CRITICAL ARCHITECTURE RULE:** Agents NEVER read SKILL.md files. You inject condensed playbooks directly into their prompts. You pre-crawl the site ONCE and share the data. This prevents context blowout.

---

## PIPELINE OVERVIEW

```
PHASE 0.5: DATA COLLECTION → Ask user what internal data they can share
PHASE 1:   RECONNAISSANCE  → YOU crawl site, classify business, extract brand DNA
PHASE 1.5: COLLECTORS      → Bash script extracts raw HTML, headers, SSL, DNS, PageSpeed, cookies
PHASE 2:   SKILL SELECTION → Choose skills based on business type
PHASE 3:   BATCH 1 AGENTS → Foundation audits (parallel, haiku-eligible)
PHASE 4:   WARM HANDOFF   → Extract Batch 1 findings for downstream context
PHASE 5:   BATCH 2+3 AGENTS → Specialist + growth audits (parallel)
PHASE 6:   QUALITY GATE   → CMO Review (depth, honesty, insight-vs-hygiene ratio)
PHASE 7:   REMEDIATION    → Re-run weak reports (if needed)
PHASE 8:   SYNTHESIS       → Executive brief + full report with confidence levels
PHASE 9:   PDF REPORT     → Professional shareable PDF with methodology disclosure
```

---

## PHASE 0: LAUNCH DASHBOARD (first thing you do)

Before anything else, launch the live dashboard in a new terminal window:

```bash
DOMAIN=$(echo "[url]" | sed 's|https\?://||;s|/.*||;s|www\.||')
AUDIT_DIR="/tmp/marketing-audit-${DOMAIN}"
mkdir -p "${AUDIT_DIR}"/{agents,review,handoffs}
```

Then immediately open the dashboard:

```bash
osascript -e "tell application \"Terminal\" to do script \"python3 $HOME/.claude/skills/marketing-orchestrator/dashboard.py ${AUDIT_DIR}\""
```

This opens a **separate Terminal window** with a live-updating dashboard that shows:
- Current phase and elapsed time
- Business type and industry detected
- Every agent's status, score, model (haiku/sonnet), and report size
- Quality gate pass/fail results
- Warm handoff status
- Final report link when complete

The dashboard polls every 2 seconds and requires zero interaction. Tell the user: "Dashboard launched — check the new Terminal window to track progress."

---

## PHASE 0.5: DATA SOURCE COLLECTION (ask user BEFORE crawling)

Before starting the audit, ask the user what data they can provide. More data = higher confidence findings = more trustworthy report.

**HOW TO ASK:** Present a short explanation of what this phase is, then use AskUserQuestion. Frame it as: "I can run this audit using only public data, but sharing even a few numbers from your analytics will dramatically improve accuracy. Here's what helps most — share whatever's easy, skip the rest."

Use AskUserQuestion with these questions:

**Question 1: "Do you have access to Google Analytics or Search Console?"**
Options:
- "Yes, I can share GA4 data" — I'll tell you exactly what to export next
- "Yes, I can share Search Console data" — I'll tell you exactly what to export next
- "I have both" — I'll walk you through both exports
- "No / Skip" — totally fine, I'll use public estimates (just lower confidence on traffic and conversion numbers)

**Question 2: "Do you have access to any of these marketing tools?"**
(multiSelect: true)
Options:
- "Email platform (Klaviyo, Mailchimp, etc.)" — I'll need 3 numbers: list size, avg open rate, avg click rate
- "Ad platform (Google Ads, Meta Ads, etc.)" — I'll need 3 numbers: monthly spend, ROAS, and top campaign
- "E-commerce dashboard (Shopify, WooCommerce, etc.)" — I'll need 3 numbers: conversion rate, AOV, cart abandonment rate
- "None / Skip"

**Question 3: "Any of these bonus data points available?"**
(multiSelect: true)
Options:
- "Review data (Trustpilot, Google Reviews, etc.)" — I just need your star rating and review count
- "Heatmaps (Hotjar, Microsoft Clarity)" — screenshot of your homepage heatmap is enough
- "Customer/CRM data" — I'll need: avg customer lifetime value, churn rate, or repeat purchase rate
- "None / Skip"

### Follow-Up: Tell the User EXACTLY What to Provide

Based on their answers, give specific instructions. Don't just say "share your GA4 data" — tell them what buttons to click.

**IMPORTANT — Screenshots:** Users can paste or drag screenshots directly into this chat. I can read them (Claude is multimodal). Always tell users this option exists — it's faster than typing numbers. Say: **"You can drag/paste a screenshot right here in the chat — I'll read the numbers from it."**

**If they said GA4:**
> Here's what I need from GA4 (takes ~2 minutes):
> 1. Go to **Reports → Acquisition → Traffic acquisition**
> 2. Set date range to **last 30 days**
> 3. Screenshot the table showing channels + sessions + conversions — **drag or paste it right here in the chat**, I'll extract the numbers. Or just type them:
>    - Total monthly sessions: ___
>    - Top 3 traffic sources and their %: ___
>    - Conversion rate (if tracked): ___
>    - Bounce rate: ___
>
> **Minimum viable:** Even just "we get about 50K sessions/month, mostly organic" is useful. It upgrades all revenue estimates from LOW to HIGH confidence.

**If they said Search Console:**
> Here's what I need from Search Console (takes ~2 minutes):
> 1. Go to **Performance → Search results**
> 2. Set date range to **last 3 months**
> 3. Screenshot the top queries table — **drag or paste it right here**, I'll read it. Or just type:
>    - Total clicks/month: ___
>    - Total impressions/month: ___
>    - Average CTR: ___
>    - Top 5 keywords driving traffic: ___
> 4. Also check **Pages → Indexing** and tell me: how many pages indexed vs. not indexed?
>
> **Minimum viable:** "We rank for about 200 keywords, 10K clicks/month" is enough. This upgrades SEO findings from guesswork to HIGH confidence.

**If they said Email platform:**
> I just need 3 numbers from your email dashboard (screenshot works too — **paste it here**):
> 1. **List size** (total subscribers): ___
> 2. **Average open rate** (last 30 days): ___
> 3. **Average click rate** (last 30 days): ___
> 4. **Bonus:** How many automated flows do you have running? (e.g., welcome, abandoned cart, post-purchase)
>
> **Minimum viable:** "12K subscribers, 42% open rate, 3 flows running" — that's plenty.

**If they said Ad platform:**
> I just need 3 numbers from your ads dashboard (screenshot works too — **paste it here**):
> 1. **Monthly ad spend** (approximate): ___
> 2. **ROAS** (return on ad spend) or **CPA** (cost per acquisition): ___
> 3. **Which platforms** are you running on? (Google, Meta, TikTok, etc.)
>
> **Minimum viable:** "We spend about EUR 5K/month on Google Ads, ROAS around 4x" is enough.

**If they said E-commerce dashboard:**
> I just need 3 numbers from your Shopify/WooCommerce dashboard (screenshot of your analytics page works — **paste it here**):
> 1. **Conversion rate** (visitors → orders): ___
> 2. **Average order value (AOV)**: ___
> 3. **Cart abandonment rate**: ___
> 4. **Bonus:** Repeat purchase rate if you know it: ___
>
> **Minimum viable:** "2.1% conversion rate, EUR 85 AOV" — that alone makes CRO recommendations 10x more accurate.

**If they said Review data:**
> I just need 2 numbers (or screenshot your review dashboard — **paste it here**):
> 1. **Average star rating**: ___
> 2. **Total number of reviews**: ___
> 3. **Bonus:** How many new reviews/month? Do you respond to reviews?

**If they said Heatmaps:**
> **Drag or paste your heatmap screenshot right here in the chat** — I can read it directly. If you have Hotjar/Clarity:
> 1. Open the heatmap for your homepage (click map or scroll map)
> 2. Take a screenshot
> 3. Paste or drag it into this chat
>
> This tells me exactly where users click and where they drop off — massively upgrades CRO findings.

**If they said CRM/Customer data:**
> I need any of these you have (screenshot of your CRM dashboard works too — **paste it here**):
> 1. **Average customer lifetime value (LTV)**: ___
> 2. **Churn rate** (monthly or annual): ___
> 3. **Repeat purchase rate**: ___
> 4. **Customer segments** you use (e.g., VIP, at-risk, new): ___
>
> **Minimum viable:** Even just "our average customer is worth about EUR 400 over their lifetime" helps enormously.

### Processing Screenshots

When a user pastes a screenshot:
1. Read the image and extract all visible numbers, labels, and data points
2. Confirm what you extracted: "I can see from your screenshot: 45K sessions, 62% organic, 2.3% conversion rate — is that right?"
3. Let them correct anything before proceeding
4. Save extracted data to `${AUDIT_DIR}/internal-data.md` with source tagged as `[SCREENSHOT]`

### If the User Gives Partial or Informal Answers

Users may not follow the exact format. That's fine. If they say "we get like 100K visits and our conversion rate is trash, maybe 1%", extract:
- Monthly sessions: ~100K
- Conversion rate: ~1%
- Confidence: MEDIUM (self-reported estimate)

Accept whatever they give. Don't push for more. Partial data > no data.

### Processing User Data

If the user provides data files or screenshots:
1. Read them and save key metrics to `${AUDIT_DIR}/internal-data.md`:

```markdown
# Internal Data: [Business Name]
Source: Provided by client on [date]

## Analytics (from GA4/GSC)
- Monthly sessions: [X]
- Organic traffic: [X]% ([Y] sessions/mo)
- Direct traffic: [X]%
- Conversion rate: [X]%
- Top landing pages: [list]
- Bounce rate: [X]%

## Email (from [platform])
- List size: [X]
- Open rate: [X]%
- Click rate: [X]%
- Active flows: [list]
- Revenue attribution: [X]%

## Ads (from [platform])
- Monthly spend: [X]
- ROAS: [X]
- CPA: [X]
- Top campaigns: [list]

## E-commerce
- Conversion rate: [X]%
- AOV: [X]
- Cart abandonment rate: [X]%
- Repeat purchase rate: [X]%

## Reviews
- Rating: [X]/5
- Total reviews: [X]
- Monthly new reviews: [X]
- Response rate: [X]%
```

2. Add this file to every agent's data sources:
```
- Internal business data (PROVIDED BY CLIENT — treat as HIGH confidence):
  Read file: [AUDIT_DIR]/internal-data.md
```

3. When internal data exists, agent confidence levels upgrade:
   - Revenue estimates based on real conversion rates → HIGH confidence
   - Channel recommendations based on real traffic data → HIGH confidence
   - Email improvements based on real open/click rates → HIGH confidence

### No Data? That's OK

If the user says "None/Skip" to everything, proceed with the external-only audit but:
- Flag ALL revenue estimates as LOW confidence
- State explicitly in the report: "This audit was conducted without access to internal analytics. All estimates are based on public data and industry benchmarks."
- Recommend specific data the client should gather for a follow-up deep-dive

### Data Source → Agent Mapping

| Data Source | Agents That Benefit | Confidence Upgrade |
|---|---|---|
| GA4 | ALL agents (baseline traffic) | Revenue estimates: LOW→HIGH |
| Search Console | seo-audit, programmatic-seo, schema-markup | Keyword findings: LOW→HIGH |
| Email platform | ecommerce-email, email-sequence | Flow recommendations: LOW→HIGH |
| Ad platforms | paid-ads | Channel/budget recs: LOW→HIGH |
| E-commerce data | checkout-cro, product-page-cro, pricing-strategy | Conversion analysis: LOW→HIGH |
| Heatmaps | page-cro, product-page-cro, checkout-cro | UX findings: MEDIUM→HIGH |
| Review data | review-reputation | Review strategy: MEDIUM→HIGH |
| CRM/customer data | retention-loyalty, referral-program, pricing-strategy | LTV/churn analysis: LOW→HIGH |

---

## PHASE 1: RECONNAISSANCE (you do this yourself — no agents)

### Step 1.2: Pre-Crawl (THE CRITICAL STEP)

YOU crawl the site and save ALL page content to a shared file that every agent reads. No agent ever calls WebFetch on the site itself.

Crawl these pages with WebFetch:
- Homepage
- /pricing OR /products OR /services (based on nav)
- /about
- 2-3 more pages relevant to business type

Write ALL crawled content to `${AUDIT_DIR}/crawl-data.md`:

```markdown
# Crawl Data: [domain]
Crawled: [ISO-8601]
Pages: [N]

---

## PAGE: [url1]
[full page text extracted from WebFetch]

---

## PAGE: [url2]
[full page text extracted from WebFetch]

---
[repeat for all pages]
```

This file is the SINGLE SOURCE OF TRUTH for all agents. Target: 5-8 pages, ~2000-4000 lines total.

### Step 1.3: Classify Business Type

Using the crawl data you already have, classify:

```
IF has_shopping_cart OR product_catalog OR shopify/woocommerce → ECOMMERCE
ELIF pricing_tiers AND (free_trial OR demo_button OR signup_flow) → SAAS
ELIF physical_address AND (service_area OR hours OR phone_prominent) → LOCAL_SERVICE
ELIF portfolio AND case_studies → AGENCY
ELIF enterprise_language AND (demo_request OR compliance_pages) → B2B
ELIF personal_name_branding AND (courses OR newsletter OR coaching) → CREATOR
ELIF two_sided_users AND listings → MARKETPLACE
ELIF donate_button AND mission_statement → NONPROFIT
ELIF articles_primary AND (paywall OR newsletter) → MEDIA
```

### Step 1.4: Extract Brand DNA

Write to `${AUDIT_DIR}/brand-dna.md`:

```markdown
# Brand DNA: [business name]

## Voice
- Tone: [formal/casual/playful/technical/warm/bold]
- Personality: [2 sentences]
- Sentence style: [short-punchy/flowing/technical]

## Language
- Power words they use: [comma-separated]
- CTA style: [direct/soft/question-based]
- Jargon level: [none/light/moderate/heavy]
- Example headline: "[actual headline]"
- Example CTA: "[actual CTA text]"

## Positioning
- Value prop: [their stated value proposition]
- Target audience: [how they describe their customer]
- Competitor stance: [premium/value/challenger/niche]
```

### Step 1.5: Quick Competitive Scan

3 WebSearches:
1. `"[brand]" alternatives`
2. `[primary keyword] best [product/service]`
3. `site:[domain]`

Write top 3 competitors + indexed page count to `${AUDIT_DIR}/context.md`:

```markdown
# Audit Context

- URL: [url]
- Domain: [domain]
- Business: [name]
- Type: [SAAS/ECOMMERCE/LOCAL_SERVICE/etc]
- Sub-type: [specific]
- Industry: [specific vertical]
- Tech stack: [detected]
- Indexed pages: [N]
- Competitors: [name1], [name2], [name3]
```

---

## PHASE 1.5: COLLECTORS (automated — runs between reconnaissance and skill selection)

After crawling the site and writing context.md, run the collectors script. This extracts technical data that WebFetch strips: raw HTML tags (script, meta, link), response headers, SSL certificates, DNS records, PageSpeed scores, cookies, and robots/sitemap data.

```bash
bash "$HOME/.claude/skills/marketing-orchestrator/collectors.sh" "${DOMAIN}" "${AUDIT_DIR}"
```

This produces `${AUDIT_DIR}/collectors-data.md` (~500-1500 lines) with 10 sections:

| # | Collector | What It Provides | Which Agents Use It |
|---|-----------|------------------|---------------------|
| 1 | Technology Stack | CMS, frameworks, analytics, email platforms, payment, A/B testing, consent tools (60+ signatures) | analytics-tracking, paid-ads, ecommerce-email, email-sequence, competitor-alternatives |
| 2 | Structured Data | JSON-LD blocks + @type inventory | schema-markup (CRITICAL — WebFetch strips `<script>` tags) |
| 3 | HTML Structure | Headings (H1-H6), images (alt text), forms (fields), meta tags, word counts | seo-audit, page-cro, form-cro |
| 4 | Social Links | Social profile URLs (12 platforms), RSS feeds, sharing buttons | social-content |
| 5 | Security Headers | 6 security headers + Server/X-Powered-By disclosure | (security context for all agents) |
| 6 | SSL Certificate | Issuer, expiry, protocol, HTTP→HTTPS redirect | seo-audit, (security context) |
| 7 | DNS & Email Auth | MX records, SPF, DMARC, NS records + provider detection | email-sequence, ecommerce-email |
| 8 | PageSpeed | Lighthouse scores (perf/seo/a11y/BP), Core Web Vitals (LCP/FID/INP/CLS) | seo-audit, page-cro, competitor-alternatives |
| 9 | Cookies | Cookie inventory, categorization (analytics/marketing/consent/session), security flags | analytics-tracking, (GDPR context) |
| 10 | robots.txt & Sitemap | Disallow rules, sitemap URL count, lastmod dates | seo-audit, programmatic-seo |

**Error handling:** Each collector is wrapped in `run_collector()` — failures produce an inline note but don't block other collectors. Target runtime: <60 seconds (PageSpeed API is the bottleneck at ~20s).

**Zero dependencies:** Uses only macOS standard tools (curl, dig, openssl, grep, sed, awk). Optionally uses `jq` for cleaner PageSpeed parsing if available.

---

## PHASE 2: SKILL SELECTION

### Assignment Matrix

```
                            SaaS  Ecom  Local  Agency  B2B  Creator  Market  NonP  Media
ALWAYS RUN (Batch 1):
page-cro                     P     P     P      P      P     P       P       P      P
seo-audit                    P     P     P      P      P     S       P       S      P
analytics-tracking           P     P     P      P      P     S       P       S      P
copywriting                  P     P     P      P      P     P       P       P      P
marketing-psychology         S     P     S      S      S     P       S       S      P

CONDITIONAL (Batch 2):
schema-markup                P     P     P      P      P     S       P       S      P
signup-flow-cro              P     -     -      S      P     S       P       -      S
checkout-cro                 -     P     -      -      -     -       P       -      -
product-page-cro             -     P     -      -      -     -       P       -      -
form-cro                     S     S     P      P      P     S       S       P      S
local-seo                    -     -     P      S      -     -       -       S      -
review-reputation            S     P     P      S      S     S       P       S      -
competitor-alternatives      P     P     S      P      P     -       S       -      -

GROWTH (Batch 3):
paid-ads                     S     P     P      S      S     S       S       S      S
social-content               S     P     P      P      S     P       S       S      P
email-sequence               P     S     S      P      P     P       S       S      P
ecommerce-email              -     P     -      -      -     -       S       -      -
pricing-strategy             P     P     S      P      P     P       P       -      -
referral-program             S     P     S      S      S     P       P       -      S

ADVANCED (Batch 4):
popup-cro                    S     P     S      S      S     S       S       S      S
free-tool-strategy           P     S     -      P      P     S       -       -      -
programmatic-seo             S     P     -      S      S     -       P       -      P
geo-audit                    S     S     S      S      S     S       S       -      S
onboarding-cro               P     -     -      -      P     S       P       -      S
paywall-upgrade-cro          P     -     -      -      S     S       S       -      P
retention-loyalty            -     P     -      -      -     S       S       -      -
product-feed                 -     P     -      -      -     -       P       -      -
```

Select all P and S skills for the detected business type. Organize into batches.

---

## PHASE 3: BATCH 1 — FOUNDATION AUDITS

### How Agent Prompts Work (CRITICAL)

Every agent gets a prompt with these 4 sections — NOTHING ELSE:

1. **Role + playbook** (~60-80 lines) — injected from `audit-playbooks.md`
2. **File paths** — where to read crawl data, where to write report
3. **Brand DNA summary** (~10 lines) — key voice attributes
4. **Output format** (~30 lines) — the standard report structure

Total agent prompt: **~150-200 lines**. No SKILL.md reading. No WebFetch on the site.

### Reading the Playbooks

Before spawning agents, read the playbooks file:
```
Read ~/.claude/skills/marketing-orchestrator/audit-playbooks.md
```

Then for each agent, extract the relevant playbook section (the text between `## [skill-name]` headers).

### Agent Prompt Template

```
Task(
  subagent_type: "general-purpose",
  model: "[haiku|sonnet]",     ← see model selection below
  description: "[skill-name] audit",
  run_in_background: true,
  prompt: """
You are a senior [skill-name] specialist. Conduct this audit.

## AUDIT INSTRUCTIONS
[INJECT THE CONDENSED PLAYBOOK HERE — the ~60-80 lines from audit-playbooks.md for this skill]

## DATA SOURCES
- Site crawl data (DO NOT use WebFetch on the site — all page content is here):
  Read file: [AUDIT_DIR]/crawl-data.md
- Collector data (raw HTML analysis, headers, SSL, DNS, PageSpeed, cookies — data WebFetch strips):
  Read file: [AUDIT_DIR]/collectors-data.md
- Business context:
  Read file: [AUDIT_DIR]/context.md
- Brand voice (match this in all copy recommendations):
  Read file: [AUDIT_DIR]/brand-dna.md

You MAY use WebSearch for external data (competitor research, industry benchmarks, search results). Keep searches to 2-3 max.

## OUTPUT FORMAT
Write your report to: [AUDIT_DIR]/agents/[skill-name].md

Use this exact structure:

# [Skill Name] Audit: [Business Name]

## Score: [X]/100
[1-2 sentence justification explaining what the score represents]

**Scoring basis:** [Explain what you scored — what exists and how well it works, not just what's missing]

## Data Limitations
[State explicitly what data you DID and DID NOT have access to. E.g., "No access to analytics, conversion rates, or revenue data. Findings based on crawl data and public search results only."]

## Current State
[What exists now — factual observations from crawl data and collector data. Every claim tagged [OBSERVED], [SEARCHED], [COLLECTED], or [INFERRED]]

## Critical Issues (Top 3)
### Issue 1: [title]
- **What:** [specific observation with evidence source tag]
- **Impact:** [estimated impact with confidence level: HIGH/MEDIUM/LOW + show your math]
- **Fix:** [implementation-ready action]
- **Effort:** [hours]
- **Classification:** [HYGIENE/INSIGHT/STRATEGIC]

### Issue 2: [title]
[same format]

### Issue 3: [title]
[same format]

## Top 5 Recommendations (Priority Order)
### 1. [title] — [HYGIENE/INSIGHT/STRATEGIC]
- **What:** [action]
- **Why:** [data-backed reason with evidence source tag]
- **How:** [step-by-step or ready-to-use code/copy]
- **Impact:** [estimated improvement with confidence level + methodology]

[Repeat 2-5]

## Ready-to-Use Implementation
[HTML, CSS, JS, schema, email copy, ad copy, etc. — substantial, not placeholder]

## Connections
[Findings relevant to other marketing areas]
"""
)
```

### Model Selection

Use **haiku** for detection/checklist agents (fast, cheap, context-light):
- `analytics-tracking` — checklist: is GA4 installed? GTM? Pixel?
- `schema-markup` — checklist: what structured data exists?
- `form-cro` — evaluate visible form elements
- `popup-cro` — check if popups exist
- `product-feed` — check Shopping presence

Use **sonnet** for analysis/creative agents (needs judgment):
- `page-cro` — deep conversion analysis
- `seo-audit` — technical analysis + keyword research
- `copywriting` — creative rewriting
- `marketing-psychology` — behavioral analysis
- `competitor-alternatives` — strategic comparison
- `pricing-strategy` — strategic pricing analysis
- `paid-ads` — channel strategy
- `social-content` — content strategy
- `email-sequence` / `ecommerce-email` — sequence design
- `geo-audit` — full 8-phase AI visibility audit + implementation artifacts (uses full playbook from `agents/geo-audit.md`)
- Everything else not listed as haiku

### Spawning Batch 1

Spawn all Batch 1 agents in parallel using a SINGLE message with multiple Task calls:

```
# In one message, spawn ALL Batch 1 agents:
Task(description: "page-cro audit", model: "sonnet", run_in_background: true, ...)
Task(description: "seo-audit", model: "sonnet", run_in_background: true, ...)
Task(description: "analytics-tracking audit", model: "haiku", run_in_background: true, ...)
Task(description: "copywriting audit", model: "sonnet", run_in_background: true, ...)
Task(description: "marketing-psychology audit", model: "sonnet", run_in_background: true, ...)
```

### Wait for Batch 1 Completion

Poll agent output files. Once all Batch 1 reports exist in `${AUDIT_DIR}/agents/`, proceed.

Quick-verify each report has: Score section, Issues section, Recommendations section. If a report is empty or truncated, flag for remediation.

---

## PHASE 4: WARM HANDOFF

Read all Batch 1 reports. Extract key findings into `${AUDIT_DIR}/handoffs/batch1-summary.md`:

```markdown
# Batch 1 Key Findings

## Analytics: [installed/missing/partial]
- GA4: [yes/no], GTM: [yes/no], Pixel: [yes/no]
- Key gaps: [list]

## SEO: Score [X]/80
- Indexed pages: [N]
- Critical issues: [top 2]
- Keyword opportunities: [top 3]

## Page CRO: Score [X]/100
- CTA effectiveness: [assessment]
- Social proof: [present/absent]
- Mobile: [good/poor]
- Top issue: [#1 problem]

## Copy: Score [X]/100
- Voice match: [on-brand/off-brand]
- Headline strength: [assessment]
- Top weakness: [#1 issue]

## Psychology: Score [X]/100
- Missing triggers: [list top 3]
- Strongest trigger present: [which one]

## Technical Infrastructure (from collectors)
- PageSpeed: Performance [X]/100, SEO [X]/100, Accessibility [X]/100
- Core Web Vitals: LCP [X]ms, INP [X]ms, CLS [X]
- SSL: [issuer], expires [date], HTTP→HTTPS redirect [yes/no]
- Security headers: [X]/6 present, missing: [list]
- Email auth: SPF [yes/no/policy], DMARC [yes/no/policy]
- Tech stack: [top 5-8 detected technologies]
- Schema: [X] JSON-LD blocks, types: [list]
- Cookies: [X] total ([analytics] analytics, [marketing] marketing)

## Cross-Cutting Pattern
[Your 2-3 sentence synthesis — the big picture insight]
```

This file gets injected into Batch 2+3 agent prompts as additional context (adds ~40 lines to their prompt).

---

## PHASE 5: BATCH 2+3+4 AGENTS

Same prompt template as Batch 1, but add this section before the output format:

```
## UPSTREAM FINDINGS (from earlier audits — build on these, don't contradict)
Read file: [AUDIT_DIR]/handoffs/batch1-summary.md
```

Spawn Batch 2 and Batch 3 in parallel (they're independent of each other). After they complete, spawn Batch 4 if applicable.

For Batch 4, also write a `batch23-summary.md` handoff with key findings from Batch 2+3.

---

## PHASE 6: QUALITY GATE — CMO REVIEW

Spawn ONE review agent that reads ALL reports:

```
Task(
  subagent_type: "general-purpose",
  model: "sonnet",
  description: "CMO quality review",
  prompt: """
You are a CMO reviewing audit reports from your marketing team.

## YOUR TASK
Read ALL reports in: [AUDIT_DIR]/agents/
Read brand DNA: [AUDIT_DIR]/brand-dna.md

Score each report on 7 dimensions (1-5 each):
1. DEPTH — Senior analysis or generic advice? Did they go deep on critical findings?
2. EVIDENCE — References actual site content from crawl? Every claim tagged [OBSERVED]/[SEARCHED]/[INFERRED]/[COLLECTED]?
3. ACTIONABILITY — Someone can implement today?
4. BRAND ALIGNMENT — Copy recs match the brand voice?
5. CONSISTENCY — No contradictions between reports?
6. HONESTY — Are revenue estimates realistic with confidence levels? Are limitations stated? Or does it oversell?
7. INSIGHT vs HYGIENE — Does the report mostly flag standard best practices as if they're discoveries, or does it surface business-specific insights? Reports that are 80%+ [HYGIENE] items should score low here.

PASS = 25+/35. FAIL = below 25.

## OUTPUT
Write to: [AUDIT_DIR]/review/cmo-review.md

# CMO Quality Review

## Report Scores
| Report | Depth | Evidence | Action | Brand | Consist | Honesty | Insight | Total | Verdict |
[one row per report]

## Revenue Reality Check
[Review ALL revenue/impact estimates across reports. Flag any that seem inflated, lack methodology, or claim HIGH confidence without supporting data. Recalculate a realistic total recoverable range.]

## Hygiene vs Insight Ratio
[For each report, what % of recommendations are HYGIENE vs INSIGHT/STRATEGIC? Flag reports that are mostly generic checklists.]

## Contradictions Found
[list any conflicting recommendations]

## Weak Reports (FAIL)
| Report | Score | Problem | Fix Instruction |
[only reports below 25/35]

## Cross-Report Insights
[Patterns visible only when looking across all reports]
"""
)
```

---

## PHASE 7: REMEDIATION

If CMO flags reports as FAIL:

1. Read the CMO's fix instructions for each failed report
2. Re-spawn ONLY failed agents with their original playbook PLUS:
   ```
   YOUR PREVIOUS REPORT SCORED [X]/25. THE REVIEWER FOUND:
   [specific CMO feedback]
   ADDRESS THESE ISSUES. Be more specific, cite evidence from the crawl data, and provide implementation-ready recommendations.
   ```
3. Max 2 remediation cycles. After that, ship as-is with a note.

---

## PHASE 8: SYNTHESIS

Read ALL agent reports + CMO review. Write TWO files:

### File 1: `${AUDIT_DIR}/EXECUTIVE-BRIEF.md` (3-5 pages max — standalone document for leadership)

```markdown
# Marketing Audit Brief: [Business Name]
**Date:** [date] | **Maturity Score:** [X]/100

## What We Found
[3-4 sentences. Lead with strengths, then gaps. Be honest about what the score means.]

## Scoring Methodology
This score reflects marketing infrastructure maturity across [N] areas. It measures "how much of the standard marketing toolkit is deployed AND executing well" — NOT overall business health. A company can be highly successful with a low infrastructure score (as [Business] demonstrates with [cite specific strength: revenue, traffic, brand equity, etc.]).

**What the score includes:** [list areas scored]
**What the score does NOT include:** Product quality, brand strength, customer loyalty, operational excellence — areas where [Business] may perform strongly.

## What This Audit Could NOT Assess
- No access to analytics data (conversion rates, traffic sources, revenue by channel)
- No access to internal business metrics (CAC, LTV, margin data)
- No user testing or customer interviews conducted
- Findings based on: public crawl data, search results, and industry benchmarks
- Revenue estimates are MODELED, not measured — treat as directional only

## Top 3 Findings (Verify These First)
### 1. [title] — Confidence: [HIGH/MEDIUM/LOW]
[2-3 sentences with evidence. If confidence is LOW, say why.]

### 2. [title] — Confidence: [HIGH/MEDIUM/LOW]
[2-3 sentences]

### 3. [title] — Confidence: [HIGH/MEDIUM/LOW]
[2-3 sentences]

## Recommended Next Steps
1. [Verify finding #1 — specific action]
2. [Verify finding #2 — specific action]
3. [If verified, start with X]

## Where to Read More
- Full report: FULL-REPORT.pdf ([N] pages, [N] specialist deep-dives)
- Quick wins: Pages [X-Y]
- 90-day roadmap: Pages [X-Y]
- [Lowest scoring area]: Pages [X-Y]
```

### File 2: `${AUDIT_DIR}/FULL-REPORT.md` (complete report)

```markdown
# Marketing Audit: [Business Name]
**URL:** [url] | **Date:** [date] | **Type:** [business_type]
**Specialists Deployed:** [N] agents | **Quality Gate:** [X]% pass rate

---

## How to Use This Report

**If you're a CMO/VP Marketing:** Read the Executive Summary and Top 10 Quick Wins (pages 1-5). Use the 90-Day Roadmap to plan sprints.
**If you're a developer/engineer:** Jump to the specific agent deep-dive chapters for implementation code and technical specs.
**If you're evaluating this audit:** Read the Audit Methodology section first to understand what data was and wasn't available.

---

## Audit Methodology & Limitations

### What This Audit IS
An automated external assessment of marketing infrastructure across [N] areas, using public crawl data, search results, and industry benchmarks. It identifies gaps and opportunities visible from outside the organization.

### What This Audit IS NOT
- A substitute for analytics-driven analysis (we had no access to GA4, conversion funnels, or revenue data)
- Based on user testing or customer research
- A definitive revenue forecast (all revenue estimates are modeled, not measured)

### Data Sources
- Site crawl: [N] pages fetched on [date] ([note any pages that blocked/failed])
- Search data: Google search results, site: index count
- Third-party: [list sources used — Trustpilot, SimilarWeb estimates, etc.]

### Confidence Framework
Every finding is tagged with a confidence level:
- **HIGH** — Directly observed in crawl data, collected from raw HTML/headers/DNS, or verified via multiple sources
- **MEDIUM** — Supported by industry benchmarks applied to estimated metrics
- **LOW** — Directional estimate based on general patterns; verify before acting

### Revenue Estimate Methodology
All revenue figures use conservative-to-optimistic ranges. The "conservative" number assumes below-average execution; the "optimistic" assumes above-average execution of the recommendation. Neither should be treated as a commitment or prediction. **Always verify with internal data before using these numbers for budgeting.**

---

## Executive Summary

### Overall Maturity Score: [X]/100

[3-4 sentences: lead with what's working well, then identify gaps. Be balanced — don't present the score as doom if the business has clear strengths.]

**What this score means:** [Business] scores [X]/100 on marketing infrastructure deployment. This measures the breadth and quality of marketing systems in place. Businesses with strong products, brands, or organic demand (like [Business]) can succeed despite lower infrastructure scores — but investing in infrastructure unlocks additional growth.

### Score Breakdown by Area
| # | Area | Score | Grade | Key Finding | Confidence |
|---|------|-------|-------|-------------|------------|
| 1 | [area] | /100 | [A-F] | [one-line] | [H/M/L] |
[sorted lowest to highest]

**Weighted Score Note:** Core operations (SEO, CRO, Analytics, Email) are weighted 2x vs. growth/advanced features (Referral, pSEO, GEO, Social Commerce) in the overall maturity calculation. A missing referral program impacts the score less than broken SEO fundamentals.

---

## Top 10 Quick Wins (Highest ROI, Lowest Effort)
| # | Action | Type | Effort | Impact (confidence) | How |
|---|--------|------|--------|---------------------|-----|
| 1-10 sorted by impact/effort ratio |

**Type column:** [HYGIENE] = standard best practice, [INSIGHT] = business-specific, [STRATEGIC] = competitive advantage

---

## Critical Issues (Must-Fix)
### 1. [title]
**Found by:** [skill] | **Severity:** CRITICAL | **Confidence:** [HIGH/MEDIUM/LOW]
**Evidence:** [what was observed, with source tag]
**Estimated impact:** [range] (confidence: [level] — [brief methodology])
**Fix:** [implementation-ready]
**Effort:** [hours/days]

---

## 90-Day Roadmap
### Days 1-14: Verify & Foundation
| # | Action | Owner | Deliverable | Success Metric |
[Start with VERIFYING the critical findings, then fix confirmed issues]

### Days 15-45: Remove Friction
| # | Action | Owner | Deliverable | Success Metric |

### Days 46-90: Build Growth
| # | Action | Owner | Deliverable | Success Metric |

---

## Revenue Recovery Summary
| Category | Conservative | Optimistic | Confidence | Methodology |
|----------|-------------|-----------|------------|-------------|
[Each row MUST include confidence level and brief methodology note]
| **Total** | **EUR X** | **EUR Y** | | **Modeled — verify with internal data** |

⚠️ **These are directional estimates, not forecasts.** They assume successful implementation and are based on industry benchmarks applied to estimated business metrics. Actual results will vary based on execution quality, market conditions, and factors not visible in this external audit.

---

## Detailed Findings by Area
[Synthesize agent reports into cohesive sections — not copy-paste]
[For each area, lead with: what's working, then what's not, then what to do]

### Website & Conversion ([X]/10)
[From: page-cro, signup-flow-cro/checkout-cro, popup-cro, form-cro]

### SEO & Search ([X]/10)
[From: seo-audit, schema-markup, local-seo, programmatic-seo, geo-audit]

### Content & Copy ([X]/10)
[From: copywriting, social-content, competitor-alternatives]

### Email & Lifecycle ([X]/10)
[From: email-sequence/ecommerce-email, retention-loyalty]

### Paid Acquisition ([X]/10)
[From: paid-ads]

### Analytics ([X]/10)
[From: analytics-tracking]

### Pricing ([X]/10)
[From: pricing-strategy, paywall-upgrade-cro]

### Reputation ([X]/10)
[From: review-reputation]

### Growth Loops ([X]/10)
[From: referral-program, free-tool-strategy, marketing-psychology]

---

## Implementation Priority Matrix
| # | Action | Impact | Effort | Confidence | Type | Source | Dependencies |
Top 20 actions sorted by ROI — each tagged [HYGIENE/INSIGHT/STRATEGIC]

---

## Competitive Position
| Factor | [Business] | [Comp 1] | [Comp 2] | [Comp 3] |
|--------|-----------|----------|----------|----------|
[key metrics compared]

---

## Audit Log
| Skill | Batch | Model | Score | Quality Gate | Confidence |
[one row per agent]

---

## Appendix: Scoring Methodology

### How Scores Work
Each area is scored 0-100 based on specific criteria in the specialist playbook:
- **0-15:** Not implemented (the capability doesn't exist)
- **16-35:** Partially implemented or fundamentally broken
- **36-55:** Implemented with significant gaps
- **56-75:** Solid implementation with optimization opportunities
- **76-100:** Best-in-class execution

**Important:** A score of 10-15 for a missing feature (e.g., no referral program) is NOT the same as a score of 10-15 for a broken feature (e.g., a checkout that errors out). The report distinguishes between "not built" and "built badly."

### Overall Maturity Score Weighting
Core areas (SEO, CRO, Analytics, Email, Checkout) are weighted 2x in the overall score because they affect all traffic, not just a growth channel. Advanced/growth areas (Referral, pSEO, GEO, Social Commerce) are weighted 1x.
```

---

## PHASE 9: GENERATE SHAREABLE PDF

After writing EXECUTIVE-BRIEF.md and FULL-REPORT.md, generate the professional PDF that combines ALL agent deep-dives into one shareable document.

```bash
python3 $HOME/.claude/skills/marketing-orchestrator/report-generator.py ${AUDIT_DIR}
```

This produces:
- `${AUDIT_DIR}/FULL-REPORT.html` — styled HTML with print CSS
- `${AUDIT_DIR}/FULL-REPORT.pdf` — professional PDF via Chrome headless

The PDF includes:
1. **Cover page** — business name, URL, maturity score, date, agent count
2. **Audit Methodology & Limitations** — what data was/wasn't available, confidence framework
3. **Table of contents** — three parts: Executive Overview, Specialist Deep-Dives, Appendix
4. **Executive summary** — maturity score with weighted explanation, grade breakdown
5. **Score breakdown** — all areas scored and graded A-F, with confidence levels
6. **Quick wins** — top 10 actions sorted by impact/effort, tagged HYGIENE/INSIGHT/STRATEGIC
7. **Critical issues** — top 5 with revenue impact estimates AND confidence levels
8. **90-Day roadmap** — starts with "verify findings" phase, then foundation, then growth
9. **Revenue recovery summary** — with explicit methodology and confidence per line item
10. **Agent deep-dive chapters** — ONE FULL CHAPTER PER AGENT with complete report content, score badge, quality gate verdict, and page break between each
11. **Scoring methodology appendix** — transparent rubric explaining how scores work
12. **Quality gate results** — CMO review scores and verdicts
13. **Competitive position** — competitor comparison
14. **Audit log** — all agents, models used, scores, report sizes

Design: professional A4 layout, navy blue headers, clean tables, color-coded scores, page numbers, "Confidential" footer. Text-only (no images) keeps file size under 2MB while allowing 50-100+ pages of content.

If Chrome is not available, the HTML file is still generated and can be opened in any browser and printed to PDF.

---

## PRESENT TO USER

After writing the report and generating the PDF, present in chat:

1. **Maturity score** + what it means (explain it's infrastructure maturity, not business health)
2. **Limitations disclaimer** — "This is an external automated audit. Findings should be verified with internal data before acting."
3. **Top 3 findings to verify** — the highest-confidence critical issues (not revenue estimates)
4. **Top 3 quick wins** — things they can do today, tagged [HYGIENE/INSIGHT/STRATEGIC]
5. **File paths:**
   - `EXECUTIVE-BRIEF.md` — 3-5 page standalone summary for leadership
   - `FULL-REPORT.pdf` — complete report with deep-dives
   - `FULL-REPORT.html` — same content, browser-viewable
6. **Honest framing**: "The most valuable thing in this report is [specific finding]. If you verify that's accurate, it should be your first priority. The revenue estimates are directional — discount them heavily until validated with your actual data."
7. **Offer**: "Want me to deep-dive on [lowest scoring area] or [highest-confidence critical issue]?"

---

## INDUSTRY-SPECIFIC CONTEXT

When spawning agents, append 1-2 lines of industry context to their prompt:

**Healthcare:** Note HIPAA for forms/email. Reviews: check Healthgrades, Zocdoc. Schema: MedicalBusiness.
**Legal:** Note ethical ad rules. Reviews: Avvo, Martindale. High CPCs ($50-200). E-E-A-T critical.
**Home Services:** Google Local Service Ads. Reviews are #1 factor. Before/after photos for social.
**Restaurant:** GBP is primary channel. Restaurant schema with menu. Yelp/TripAdvisor reviews.
**Real Estate:** Neighborhood pages for pSEO. RealEstateAgent schema. Market reports for content.
**Fitness:** Transformation content for social. January/pre-summer surges. Re-engagement for lapsed members.
**Professional Services:** LinkedIn primary. Thought leadership. Long nurture sequences.

---

## PERMISSION SETUP (run once)

The orchestrator spawns 15-25 agents that use WebFetch, WebSearch, Read, Write, and Bash. To prevent permission prompts from blocking the autonomous pipeline, launch Claude Code with:

```bash
claude --dangerously-skip-permissions
```

Or add to `~/.claude/settings.json`:
```json
{
  "permissions": {
    "allow": ["WebFetch", "WebSearch", "Bash(mkdir:*)", "Bash(python3:*)"]
  }
}
```

Without this, every agent will prompt "Allow Claude to..." and the pipeline stalls.

---

## ERROR HANDLING

- **Agent returns empty/truncated report:** Re-run with same prompt (don't count as remediation)
- **WebFetch blocked on crawl:** Try alternative pages. If <3 pages crawled, note limitations in report
- **Pre-launch site (no URL):** Skip crawl. Run: market-analyst, copywriting, pricing-strategy, launch-strategy, marketing-ideas only
- **Rate limit:** Wait 30 seconds, retry. Don't skip agents
- **Ambiguous business type:** Pick closest match, note assumption

---

## CONTEXT BUDGET

This is why the architecture works:

| Component | Lines | Notes |
|-----------|-------|-------|
| Agent role + playbook | ~80 | From audit-playbooks.md |
| File read instructions | ~15 | 4 file paths (crawl + collectors + context + brand) |
| Brand DNA summary | ~15 | Key voice attributes |
| Output format | ~40 | Standard structure |
| Upstream findings (B2+) | ~30 | Warm handoff summary |
| Industry context | ~5 | 1-2 lines |
| **Total agent prompt** | **~185** | **Well within limits** |

Agents then read:
- `crawl-data.md`: ~2000-4000 lines (site content from WebFetch)
- `collectors-data.md`: ~500-1500 lines (raw HTML, headers, SSL, DNS, PageSpeed, cookies)
- `context.md`: ~15 lines
- `brand-dna.md`: ~20 lines
- `batch1-summary.md`: ~30 lines (Batch 2+ only)

Total context per agent: **~3,000-6,000 lines** — safely within limits vs. the old approach of 1,500-line SKILL.md + WebFetch + WebSearch = blown context. The collector data adds ~500-1500 lines but provides HIGH confidence technical findings that previously required agents to guess.

---

## KEY PRINCIPLES

1. **Pre-crawl once, share everywhere.** No agent calls WebFetch on the target site.
2. **Inject playbooks, don't read SKILL.md.** Agents get ~80 lines of instructions, not 1,500.
3. **Haiku for checklists, Sonnet for analysis.** Right model for the task.
4. **Warm handoffs between batches.** Downstream agents know upstream findings.
5. **Quality gate catches weak work.** CMO Review ensures depth, consistency, AND honesty.
6. **Remediation loop.** Weak reports get specific feedback and a re-run.
7. **Brand DNA in every recommendation.** Copy sounds like THEM.
8. **One command, full report.** Zero human intervention.
9. **Business-type aware.** A dentist and a SaaS get different skill mixes.
10. **Implementation-ready.** Every recommendation has a specific action.
11. **Honest over impressive.** State limitations. Tag confidence levels. Don't dress up hygiene as insight. A CMO should trust this report, not discount it by 70%.
12. **Depth over breadth.** A critical finding explored deeply is worth more than 10 surface observations. Agents should go deep on what matters.
13. **Score what exists, not what's missing.** Infrastructure maturity != business health. Explain this distinction clearly. A company with 4M monthly visits and 46% email open rates isn't failing just because it lacks a referral program.
14. **Two outputs: brief + full.** Leadership gets a 3-5 page executive brief. Implementers get the full 50+ page report. Don't force one format on both audiences.
15. **Verify before act.** The 90-day roadmap starts with "verify these findings" — not "implement these changes." External audits need validation.
