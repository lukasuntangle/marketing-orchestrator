# PRD: GEO Audit Agent for napkin.wtf

**Author:** Claude + Lukas
**Date:** 2026-02-17
**Status:** Draft
**Project:** [napkin-wtf](https://github.com/lukasuntangle/napkin-wtf)
**Source skill:** [`agents/geo-audit.md`](https://github.com/lukasuntangle/marketing-orchestrator/blob/master/agents/geo-audit.md)

---

## Problem

napkin.wtf runs 20 marketing audit agents but has zero coverage for **AI search visibility** — the fastest-growing discovery channel. ChatGPT Search (800M+ weekly users), Perplexity (125M+ weekly queries), Google AI Overviews (1.5B+ monthly users), and Copilot are replacing Google for buying decisions. Brands that aren't optimized for AI citations are invisible to a growing share of their market.

The geo-audit skill already exists in the marketing-orchestrator repo with a full 8-phase methodology. It needs to be ported into the napkin.wtf TypeScript codebase as the 21st agent.

---

## Goal

Add a `geo-audit` agent that:
1. Audits a website's AI visibility using existing crawl + collector data
2. Checks technical GEO readiness (robots.txt AI crawlers, schema, merchant centers, entity presence)
3. Applies the 9 Princeton GEO methods to assess content citability
4. Generates ready-to-deploy implementation artifacts (JSON-LD, meta tags, FAQ sections, robots.txt)
5. Fits cleanly into the existing agent pipeline (same `AgentOutput` interface, Batch 2, sonnet model)

---

## Non-Goals

- **Live AI platform testing** (Phases 1-2 of the full skill). The full geo-audit queries ChatGPT/Gemini/Perplexity directly to measure mention rates. This requires API access or scraping that napkin.wtf doesn't have. The agent will assess GEO *readiness* from crawl + collector data, not measure live *visibility*.
- **GA4 AI traffic channel setup** (Phase 7 of the full skill). This requires GA4 admin access. The agent will *recommend* the setup and provide the regex, but can't configure it.
- **Merchant Center verification**. The agent can detect whether feeds likely exist (via technology detection) but can't verify account status.

---

## Architecture

### Where it fits in the existing pipeline

```
Batch 1 (10 agents) → warm handoff → Batch 2 (10 agents + geo-audit)
                                                    ↑
                                          NEW: 21st agent
```

Geo-audit runs in **Batch 2** because it benefits from Batch 1 findings:
- `technical-seo` → indexation status, schema findings, robots.txt
- `on-page-seo` → meta tags, heading structure, content quality
- `analytics-tracking` → what tracking is installed
- `content-strategy` → content depth and format assessment

### Files to modify

| File | Change |
|------|--------|
| `src/lib/audit/constants/agent-playbooks.ts` | Add `'geo-audit'` to `AgentName` union + add `AgentPlaybook` entry |
| `src/lib/audit/constants/business-types.ts` | Add `'geo-audit'` to `relevantAgents` for applicable business types |
| `src/lib/audit/ai/agent-runner.ts` | Extend `AgentOutput` with optional `implementationArtifacts` field |
| `src/components/audit/report/AgentDetailCard.tsx` | Render implementation artifacts (code blocks) when present |

### Files unchanged

- `src/lib/audit/orchestrator.ts` — already iterates `AGENT_PLAYBOOKS` dynamically, no hardcoded agent names
- `src/lib/audit/ai/quality-gate.ts` — already reviews all agents generically
- `src/lib/audit/ai/synthesizer.ts` — already synthesizes all agent reports
- `src/lib/audit/collectors/*` — all needed collectors already exist
- DB migrations — `audit_agents` table is agent-name-agnostic

---

## Detailed Changes

### 1. `AgentName` union type

```typescript
// Add to existing union in agent-playbooks.ts
export type AgentName =
  | 'technical-seo'
  | 'on-page-seo'
  // ... existing 20 ...
  | 'geo-audit';  // NEW
```

### 2. `AgentPlaybook` entry

```typescript
{
  id: 'geo-audit',
  name: 'AI Visibility & GEO Auditor',
  category: 'seo',
  model: 'claude-sonnet-4-5',
  batch: 2,
  maxTokens: 8192,  // Higher than typical — generates code artifacts
  systemPrompt: `You are a senior GEO (Generative Engine Optimization) specialist. You audit websites for visibility in AI-powered search engines: ChatGPT Search, Google AI Overviews, Perplexity, Claude, and Microsoft Copilot.

AI search is fundamentally different from traditional SEO. Traditional SEO = rank on Google. GEO = get cited in AI answers. Only 3-5 brands get mentioned when someone asks ChatGPT "where should I buy X?" — if you're not one of them, you don't exist for that customer.

## AUDIT METHODOLOGY

### 1. AI Crawler Access (from robots.txt collector data)
Check if these AI crawlers are allowed or blocked:
- GPTBot (OpenAI/ChatGPT)
- ChatGPT-User (ChatGPT browsing)
- Google-Extended (Gemini training)
- PerplexityBot
- anthropic-ai / ClaudeBot
- Bytespider (ByteDance AI)
- CCBot (Common Crawl — used by many AI systems)
Score: Each blocked crawler = -10 points. All allowed = full marks.

### 2. Structured Data for AI (from structured data collector)
Check for schema types that directly feed AI responses:
- Organization (with sameAs linking to Wikipedia, Wikidata, social profiles)
- FAQPage (directly feeds AI Q&A responses)
- Product (with offers, aggregateRating)
- Speakable (indicates content suitable for voice/AI reading)
- WebSite (with SearchAction)
- BreadcrumbList
- dateModified on all schemas (freshness signal — 76.4% of ChatGPT's most-cited pages updated within last month)

### 3. Content Citability — Apply the 9 Princeton GEO Methods
Evaluate each crawled page against the research-backed methods:
| Method | Impact | What to Look For |
|--------|--------|-----------------|
| Statistics Addition | +37-40% | Specific numbers, percentages, data points in claims |
| Cite Sources | +40% | References to studies, reports, named experts |
| Quotation Addition | +30% | Direct quotes from experts or customers |
| Authoritative Tone | +25% | Confident expertise, no hedging language |
| Simplification | +20% | Complex topics made accessible |
| Technical Terms | +18% | Precise domain terminology alongside plain language |
| Vocabulary Diversity | +15% | Varied word choices, not repetitive |
| Fluency | +15-30% | Clear structure, logical flow, no filler |
| Keyword Stuffing | -10% penalty | Penalize if found |

### 4. Answer Capsule Pattern
72.4% of blog posts cited by ChatGPT contain an "answer capsule" — a 20-25 word direct answer immediately after a question-formatted heading.
Check: Do any pages use this pattern? Do H2s use question format?

### 5. Entity & Knowledge Graph Signals
From crawl data, assess:
- Does schema include sameAs links to Wikipedia, Wikidata, social profiles?
- Is there an about page with founding date, location, team?
- Are there trust signals AI would reference? (review counts, years in business, certifications)

### 6. AI Commerce Readiness (from technology collector)
Detect presence of:
- Google Merchant Center indicators (gtag config, merchant ID)
- Shopify (ChatGPT has direct Shopify data access)
- Product feeds / shopping markup
- Payment processing (indicates transaction capability)

### 7. Freshness Signals
- dateModified in schema?
- Visible "last updated" dates?
- Blog/content publishing recency?

## IMPLEMENTATION ARTIFACTS

After analysis, generate these ready-to-deploy code blocks:

1. **robots.txt additions** — Allow all AI crawlers (generate the exact User-agent/Allow blocks)
2. **Organization JSON-LD** — Complete schema with sameAs, foundingDate, description using Princeton methods
3. **FAQPage JSON-LD** — Generate 5-8 FAQ entries based on likely customer queries for this business type, using answer capsule format
4. **Meta tag improvements** — Rewritten title and description for homepage applying statistics, authoritative tone, and technical terms
5. **Content rewrite example** — Take the homepage hero text, rewrite applying all 9 Princeton methods, annotate which methods were applied

Put all implementation artifacts in the reportMarkdown field under a "## Implementation Artifacts" heading with each artifact in a fenced code block.`,
  dataDependencies: [],
  collectorDependencies: [
    'structuredData',
    'robotsSitemap',
    'technologyStack',
    'htmlAnalysis',
    'pageSpeed',
  ],
  outputSchema: {
    score: 'AI visibility readiness score 0-100',
    findings: 'Array of findings covering crawler access, schema, content citability, entity signals, commerce readiness',
    recommendations: 'Prioritized actions with implementation artifacts (JSON-LD, robots.txt, meta tags, content rewrites)',
  },
},
```

### 3. Business type mapping

Add `'geo-audit'` to `relevantAgents` for these business types:

| Business Type | Include? | Why |
|---------------|----------|-----|
| ECOMMERCE | Yes | ChatGPT Shopping, Perplexity Merchant Program, product citations |
| SAAS | Yes | Developer/product queries heavily use AI search |
| LOCAL_SERVICE | Yes | "Best [service] near me" queries shifting to AI |
| B2B_SERVICE | Yes | Professional service discovery moving to AI |
| CONTENT_PUBLISHER | Yes | Citation and AI visibility is their core business |
| MARKETPLACE | Yes | Product discovery and comparison queries |
| AGENCY | Yes | "Best [type] agency" queries in AI |
| NONPROFIT | No | Lower AI search impact, limited budget |
| OTHER | Yes | Default inclusion |

### 4. `AgentOutput` extension (optional)

The current `AgentOutput` interface puts everything in `reportMarkdown: string`. The implementation artifacts (JSON-LD, robots.txt, meta tags) can go here as fenced code blocks — no interface change needed.

**However**, if we want the UI to render artifacts specially (copy button, syntax highlighting, collapsible sections), add an optional field:

```typescript
export interface ImplementationArtifact {
  readonly type: 'json-ld' | 'robots-txt' | 'meta-tags' | 'content-rewrite' | 'faq-section';
  readonly title: string;
  readonly language: 'json' | 'html' | 'text';
  readonly code: string;
  readonly description: string;
}

export interface AgentOutput {
  // ... existing fields ...
  readonly implementationArtifacts?: readonly ImplementationArtifact[];  // NEW
}
```

**Recommendation:** Start with artifacts in `reportMarkdown` only (zero interface changes). Add the typed field in a follow-up once we validate the output quality.

### 5. UI: `AgentDetailCard.tsx`

No changes required for v1. The `MarkdownRenderer` already renders fenced code blocks. The artifacts will display as syntax-highlighted code in the report.

**Follow-up:** Add a "Copy to clipboard" button on code blocks in the report viewer. This is a generic improvement that benefits all agents, not just geo-audit.

---

## Collector Dependencies

All data the geo-audit agent needs is already collected:

| Need | Collector | Field |
|------|-----------|-------|
| AI crawler rules | `robotsSitemap` | `robots.disallowRules`, `robots.sitemapReferences` |
| JSON-LD schemas | `structuredData` | `jsonLdBlocks`, `schemaTypes`, `hasOrganization`, `hasFAQ`, etc. |
| Tech stack (merchant centers, Shopify) | `technologyStack` | `detected[]`, `hasPaymentProcessor`, `categories` |
| Heading structure, forms, meta | `htmlAnalysis` | `headings`, `wordCountByPage`, `languageTag` |
| Page speed / Core Web Vitals | `pageSpeed` | `performanceScore`, `coreWebVitals` |

**No new collectors needed.**

---

## Token Budget

The geo-audit agent has a larger output than typical agents because it generates code artifacts. Budget:

| Section | Est. Tokens |
|---------|-------------|
| Analysis + findings | ~1,500 |
| Recommendations | ~800 |
| robots.txt block | ~200 |
| Organization JSON-LD | ~400 |
| FAQPage JSON-LD (5-8 Qs) | ~800 |
| Meta tag rewrites | ~300 |
| Content rewrite example | ~500 |
| **Total output** | **~4,500** |

Set `maxTokens: 8192` to give headroom. Input is the same as other Batch 2 agents (~3,000-5,000 tokens of crawl + collector + batch 1 summary).

**Cost per audit:** ~$0.04-0.06 at Sonnet 4.5 pricing (est. 5K input + 5K output tokens).

---

## Quality Gate Considerations

The existing quality gate reviews all 7 dimensions generically. For geo-audit, the most relevant dimensions are:

- **Accuracy & Evidence:** Are AI crawler allow/block findings based on actual robots.txt data? (`OBSERVED` tag)
- **Actionability:** Are the JSON-LD and robots.txt blocks valid and copy-pasteable?
- **Specificity:** Does the FAQ content use actual business data, not generic placeholders?
- **Completeness:** Are all 9 Princeton methods assessed?

No quality gate changes needed — the existing dimensions cover this.

---

## Migration

No database migration needed. The `audit_agents` table stores `agent_name` as a `text` column, not an enum. A new agent name is automatically supported.

---

## Testing Plan

1. **Unit test:** Verify `'geo-audit'` is in `AGENT_PLAYBOOKS` and has correct batch/model/dependencies
2. **Unit test:** Verify all target business types include `'geo-audit'` in `relevantAgents`
3. **Integration test:** Run a full audit on a test URL and verify:
   - geo-audit agent runs in Batch 2
   - Output contains valid JSON with score, findings, recommendations
   - `reportMarkdown` contains implementation artifacts with valid JSON-LD
   - Quality gate doesn't flag it as failed
4. **Manual test:** Verify the generated JSON-LD passes [Google Rich Results Test](https://search.google.com/test/rich-results)
5. **Manual test:** Verify the robots.txt output is valid syntax

---

## Rollout

1. **Phase 1 (this PR):** Add agent + business type mapping. Artifacts in `reportMarkdown` only.
2. **Phase 2 (follow-up):** Add `ImplementationArtifact` typed interface + copy-to-clipboard UI.
3. **Phase 3 (future):** Add live AI visibility testing via API (ChatGPT, Perplexity) when API access is available.

---

## Files Changed (Summary)

| File | Lines Changed (est.) | Type |
|------|---------------------|------|
| `src/lib/audit/constants/agent-playbooks.ts` | +80 | New playbook entry + type union |
| `src/lib/audit/constants/business-types.ts` | +8 | Add to relevantAgents arrays |
| **Total** | **~88** | |

---

## Open Questions

1. **Should geo-audit run for free-tier audits?** It's a Sonnet agent with ~$0.05 cost. Current paywall logic in `src/lib/audit/paywall.ts` determines which agents are free vs paid. Geo-audit could be a strong upsell motivator — show the score for free, gate the implementation artifacts behind payment.

2. **Should we validate the generated JSON-LD?** We could add a post-processing step that parses the JSON-LD blocks and validates they're valid JSON + valid schema.org types. This prevents the agent from generating broken code. Could be a shared utility for any agent that generates code.

3. **Naming:** The agent is called `geo-audit` in the skill system. In the UI, should it display as "AI Visibility Audit", "GEO Audit", or "AI Search Readiness"? "AI Visibility" is probably clearest for non-technical users.
