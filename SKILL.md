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
PHASE 1: RECONNAISSANCE    → YOU crawl site, classify business, extract brand DNA
PHASE 2: SKILL SELECTION   → Choose skills based on business type
PHASE 3: BATCH 1 AGENTS    → Foundation audits (parallel, haiku-eligible)
PHASE 4: WARM HANDOFF      → Extract Batch 1 findings for downstream context
PHASE 5: BATCH 2+3 AGENTS  → Specialist + growth audits (parallel)
PHASE 6: QUALITY GATE      → CMO Review of all reports
PHASE 7: REMEDIATION       → Re-run weak reports (if needed)
PHASE 8: SYNTHESIS          → Unified report with scores, roadmap, quick wins
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
[1-2 sentence justification]

## Current State
[What exists now — factual observations from crawl data]

## Critical Issues (Top 3)
### Issue 1: [title]
- **What:** [specific observation with evidence from crawl]
- **Impact:** [what this costs them]
- **Fix:** [implementation-ready action]
- **Effort:** [hours]

### Issue 2: [title]
[same format]

### Issue 3: [title]
[same format]

## Top 5 Recommendations (Priority Order)
### 1. [title] — P1
- **What:** [action]
- **Why:** [data-backed reason]
- **How:** [step-by-step or ready-to-use code/copy]
- **Impact:** [expected improvement]

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
- `geo-audit` — quick assessment

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

## Cross-Cutting Pattern
[Your 2-3 sentence synthesis — the big picture insight]
```

This file gets injected into Batch 2+3 agent prompts as additional context (adds ~30 lines to their prompt).

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

Score each report on 5 dimensions (1-5 each):
1. DEPTH — Senior analysis or generic advice?
2. EVIDENCE — References actual site content from crawl?
3. ACTIONABILITY — Someone can implement today?
4. BRAND ALIGNMENT — Copy recs match the brand voice?
5. CONSISTENCY — No contradictions between reports?

PASS = 18+/25. FAIL = below 18.

## OUTPUT
Write to: [AUDIT_DIR]/review/cmo-review.md

# CMO Quality Review

## Report Scores
| Report | Depth | Evidence | Action | Brand | Consist | Total | Verdict |
[one row per report]

## Contradictions Found
[list any conflicting recommendations]

## Weak Reports (FAIL)
| Report | Score | Problem | Fix Instruction |
[only reports below 18/25]

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

Read ALL agent reports + CMO review. Write `${AUDIT_DIR}/FULL-REPORT.md`:

```markdown
# Marketing Audit: [Business Name]
**URL:** [url] | **Date:** [date] | **Type:** [business_type]
**Specialists Deployed:** [N] agents | **Quality Gate:** [X]% pass rate

---

## Executive Summary
**Marketing Maturity Score: [X]/100**
[3-4 sentences: current state, biggest gaps, top opportunities, estimated impact]

### Score Breakdown
| Area | Score | Grade | Key Finding |
|------|-------|-------|-------------|
| Website & CRO | /10 | [A-F] | [one-line] |
| SEO & Search | /10 | [A-F] | [one-line] |
| Content & Copy | /10 | [A-F] | [one-line] |
| Analytics | /10 | [A-F] | [one-line] |
| Email & Lifecycle | /10 | [A-F] | [one-line] |
| Social & Community | /10 | [A-F] | [one-line] |
| Paid Acquisition | /10 | [A-F] | [one-line] |
| Reputation & Trust | /10 | [A-F] | [one-line] |
| Pricing & Monetization | /10 | [A-F] | [one-line] |
| Technical Foundation | /10 | [A-F] | [one-line] |

---

## Top 10 Quick Wins (Do This Week)
| # | Action | Source | Effort | Impact | How |
|---|--------|--------|--------|--------|-----|
| 1-10 sorted by impact/effort ratio |

---

## Critical Issues (Top 5)
### 1. [title]
**Found by:** [skill] | **Severity:** CRITICAL
**What:** [evidence-based]
**Revenue impact:** [estimate]
**Fix:** [implementation-ready]
**Effort:** [hours]

---

## 90-Day Roadmap
### Month 1: Fix the Foundation
| Week | Action | Deliverable | Metric |
### Month 2: Build Growth Channels
| Week | Action | Deliverable | Metric |
### Month 3: Optimize & Scale
| Week | Action | Deliverable | Metric |

---

## Detailed Findings by Area
[Synthesize agent reports into cohesive sections — not copy-paste]

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
| # | Action | Impact | Effort | ROI | Source | Dependencies |
Top 20 actions sorted by ROI

---

## Competitive Position
| Factor | [Business] | [Comp 1] | [Comp 2] | [Comp 3] |
|--------|-----------|----------|----------|----------|
[key metrics compared]

---

## Audit Log
| Skill | Batch | Model | Score | Quality Gate |
[one row per agent]
```

---

## PRESENT TO USER

After writing the report, present in chat:

1. **Maturity score** + grade breakdown table
2. **Top 3 quick wins** — things they can do today
3. **#1 critical issue** — what to fix first
4. **File path** to full report
5. **Offer**: "Your lowest score is [area] at [X]/10. Want me to deep-dive on that?"

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
| File read instructions | ~10 | 3 file paths |
| Brand DNA summary | ~15 | Key voice attributes |
| Output format | ~40 | Standard structure |
| Upstream findings (B2+) | ~30 | Warm handoff summary |
| Industry context | ~5 | 1-2 lines |
| **Total agent prompt** | **~180** | **Well within limits** |

Agents then read:
- `crawl-data.md`: ~2000-4000 lines (site content)
- `context.md`: ~15 lines
- `brand-dna.md`: ~20 lines
- `batch1-summary.md`: ~30 lines (Batch 2+ only)

Total context per agent: **~2,500-4,500 lines** — safely within limits vs. the old approach of 1,500-line SKILL.md + WebFetch + WebSearch = blown context.

---

## KEY PRINCIPLES

1. **Pre-crawl once, share everywhere.** No agent calls WebFetch on the target site.
2. **Inject playbooks, don't read SKILL.md.** Agents get ~80 lines of instructions, not 1,500.
3. **Haiku for checklists, Sonnet for analysis.** Right model for the task.
4. **Warm handoffs between batches.** Downstream agents know upstream findings.
5. **Quality gate catches weak work.** CMO Review ensures depth and consistency.
6. **Remediation loop.** Weak reports get specific feedback and a re-run.
7. **Brand DNA in every recommendation.** Copy sounds like THEM.
8. **One command, full report.** Zero human intervention.
9. **Business-type aware.** A dentist and a SaaS get different skill mixes.
10. **Implementation-ready.** Every recommendation has a specific action.
