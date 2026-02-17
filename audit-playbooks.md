# Condensed Audit Playbooks

These are stripped-down audit instructions for batch execution. Each playbook is ~50-80 lines — just the scoring criteria, key checks, and output format. No educational content, no examples, no optional sections.

The orchestrator INJECTS these directly into agent prompts. Agents never read the full SKILL.md files.

---

## UNIVERSAL RULES (inject into EVERY agent prompt)

These rules apply to ALL audit agents regardless of specialty:

### Evidence Standards
- Every finding MUST cite its source: `[OBSERVED]` (seen in crawl data), `[COLLECTED]` (from collectors-data.md — raw HTML, headers, SSL, DNS, PageSpeed), `[SEARCHED]` (found via WebSearch), or `[INFERRED]` (logical deduction from available data)
- `[COLLECTED]` data is HIGH confidence — it comes from raw HTML analysis, HTTP headers, SSL certificates, DNS records, and the PageSpeed API. Prefer `[COLLECTED]` over `[INFERRED]` when both could apply.
- If you cannot verify something from the crawl data, collector data, or search results, say so explicitly. Never present assumptions as facts.
- When the crawl data is incomplete (e.g., site blocked crawling, page didn't load), state this limitation upfront.

### Recommendation Classification
Tag every recommendation with exactly one of:
- `[HYGIENE]` — Industry standard best practice. Every business in this category should have this. Not a unique insight.
- `[INSIGHT]` — Specific to THIS business based on evidence found. Something a generic checklist wouldn't catch.
- `[STRATEGIC]` — Competitive advantage opportunity unique to this business's position, assets, or market.

### Revenue & Impact Estimation
- NEVER present revenue estimates as facts. Always use: "Estimated impact: EUR X-Y/yr (confidence: HIGH/MEDIUM/LOW)"
- HIGH confidence = based on published benchmarks + verified business data (e.g., known traffic, known conversion rates)
- MEDIUM confidence = based on industry benchmarks applied to estimated business metrics
- LOW confidence = directional estimate based on general patterns, no business-specific data available
- When you don't have conversion data, traffic data, or revenue data, your confidence is LOW by default
- Prefer ranges over point estimates. Make the range honest — 2x spread minimum for LOW confidence.
- Show your math: "Assuming X visitors/mo (from SimilarWeb/site:search) x Y% conversion uplift (industry benchmark) = Z"

### Scoring Philosophy
- Score what EXISTS, not what's missing. A score of 0 means "actively broken/harmful." A score of 5-15 means "not implemented."
- Don't conflate "not implemented" with "poorly implemented." A company that has no referral program scores 10-15 (not implemented), not 0 (broken). A company with a broken referral program scores lower.
- Your score should answer: "How well does this business execute in this area?" not "Does this feature exist?"

### Depth Over Breadth
- If you discover a CRITICAL issue (something actively costing significant revenue or creating legal/compliance risk), spend 60%+ of your report analyzing that issue deeply — root cause, full impact, step-by-step fix.
- It's better to go deep on 2-3 important findings than to surface-skim 10 items.
- A "critical" finding is one where: (a) the business is actively losing money/customers due to this, (b) there's legal/compliance risk, OR (c) competitors all do this and the business doesn't, creating a measurable competitive disadvantage.

### What Makes an Agent Report Valuable
The difference between a generic audit and a valuable one:
- **Generic:** "You should add schema markup to your pages" (any checklist tool can say this)
- **Valuable:** "Your deal pages contain priceValidUntil data (countdown timers) but don't expose it as schema. Your 3 main competitors all have Offer+AggregateRating schema. This means their search results show star ratings, prices, and availability while yours show plain blue links. Based on published CTR studies, rich results get 20-30% higher CTR. With your estimated [X] organic impressions/month, this gap costs approximately [Y] clicks/month." [OBSERVED: countdown timers in crawl] [SEARCHED: competitor schema confirmed] [INFERRED: CTR impact from industry studies]
- The **specific evidence**, the **competitive comparison**, and the **math** are what make it an insight rather than a checkbox.

### Data Request Section
At the END of every report, include a section:
## Data Needed for Deeper Analysis
[List the 3-5 specific data points that would let you upgrade your findings from LOW/MEDIUM confidence to HIGH. Be specific about what you need and why.]
Example: "To validate the cart abandonment estimate, I would need: (1) actual cart abandonment rate from your e-commerce platform, (2) current cart recovery email performance, (3) monthly cart value. Without this, my EUR 500K-1M estimate is based on industry averages and should be treated as directional only."

---

## page-cro

Score the page 0-100 across these 10 dimensions (10 pts each):
1. Value proposition clarity (above fold, <8 words ideal)
2. Primary CTA (visible, contrast, action verb, single focus)
3. Social proof (testimonials, logos, stats, reviews - present + quality)
4. Visual hierarchy (F-pattern/Z-pattern, whitespace, scannable)
5. Trust signals (security badges, guarantees, certifications)
6. Page speed — use collector Section 8 "PageSpeed" for actual Lighthouse Performance score + Core Web Vitals [COLLECTED]
7. Mobile experience (responsive, touch targets, thumb zones)
8. Content structure — use collector Section 3 "Heading Hierarchy" for exact heading counts + text [COLLECTED]
9. Objection handling (FAQ, guarantees, risk reversal)
10. Secondary CTAs (alternative actions for non-ready visitors)

Also use collector Section 3 "Images" for images with missing alt text and Section 3 "Forms" for form details [COLLECTED].

Output: Score + top 3 issues with fixes + 3 rewritten sections (headline, CTA, social proof).

---

## seo-audit

Check these 8 areas, score each 0-10:
1. Title tags (unique, <60 chars, keyword-first, compelling) — use collector Section 3 "HTML Structure" for exact title tag + length
2. Meta descriptions (unique, <155 chars, CTA, keyword present) — use collector Section 3 "Meta Tags" for exact meta descriptions
3. H1 structure (single H1 per page, keyword-rich, matches intent) — use collector Section 3 "Heading Hierarchy" for exact H1-H6 counts + text
4. URL structure (short, descriptive, no parameters, lowercase)
5. Internal linking (orphan pages, anchor text, link depth)
6. Image optimization (alt text, file size, format, lazy loading) — use collector Section 3 "Images" for exact missing alt text count + URLs
7. Core Web Vitals (LCP, FID/INP, CLS) — use collector Section 8 "PageSpeed & Core Web Vitals" for actual Lighthouse scores + CWV metrics (HIGH confidence, no need for WebSearch)
8. Indexation (search "site:[domain]" for page count) — use collector Section 10 "robots.txt & Sitemap" for exact sitemap URL count, lastmod, disallow rules

Also check collector Section 6 "SSL Certificate" for HTTPS status and redirect behavior.

Output: Score/80 + top 3 technical issues + 5 keyword opportunities found via WebSearch.

---

## analytics-tracking

**CRITICAL: Use collector data for this audit.** Collector Section 1 "Technology Stack" has already detected all analytics/tracking tools from raw HTML (60+ regex signatures). Collector Section 9 "Cookies" shows analytics cookies set. Collector Section 1 "Cookie Consent & Compliance" shows consent tools detected.

Check for these signals using collector data (HIGH confidence) + crawl data:
1. GA4 installed? — check collector Section 1 "Analytics & Tracking" for GA4/GTM detection [COLLECTED]
2. GTM present? — check collector Section 1 for GTM-XXXXXX [COLLECTED]
3. Meta Pixel? — check collector Section 1 for Meta Pixel detection [COLLECTED]
4. Conversion tracking? — check collector Section 1 for ad pixels (LinkedIn, TikTok, Pinterest, Twitter) [COLLECTED]
5. UTM usage? (check if links use utm_ parameters from crawl data)
6. Cookie consent? — check collector Section 1 "Cookie Consent & Compliance" for consent tools [COLLECTED] + collector Section 9 "Cookies" for consent cookies [COLLECTED]
7. Search Console likely connected? (meta verification tag — check collector Section 3 "Meta Tags")
8. Other tools? — check collector Section 1 for Hotjar, Clarity, Mixpanel, Amplitude, Segment, PostHog, etc. [COLLECTED]

Build a **capability matrix** from collector data showing: tool name, category, detected [yes/no].

Score: 0-100 based on completeness.
Output: What's installed [COLLECTED], what's missing, top 3 tracking gaps, recommended GA4 event taxonomy (5-10 key events for this business type).

---

## schema-markup

**CRITICAL: This audit depends entirely on collector data.** WebFetch strips `<script>` tags, making JSON-LD invisible in crawl data. Collector Section 2 "Structured Data" has already extracted all JSON-LD blocks and @type inventory from raw HTML.

Use collector Section 2 for:
- Number of JSON-LD blocks found [COLLECTED]
- All @type values detected (Organization, Product, BreadcrumbList, FAQPage, etc.) [COLLECTED]
- Raw JSON-LD content for analysis [COLLECTED]

Score based on:
1. Any schema present? (+20 if yes) — check collector Section 2 block count [COLLECTED]
2. Organization/LocalBusiness schema? (+15) — check collector @type list [COLLECTED]
3. Breadcrumb schema? (+10) — check for BreadcrumbList type [COLLECTED]
4. FAQ schema on relevant pages? (+10) — check for FAQPage type [COLLECTED]
5. Product/Service schema? (+15) — check for Product/Service/Offer types [COLLECTED]
6. Review/Rating schema? (+15) — check for AggregateRating/Review types [COLLECTED]
7. Correct implementation (no errors)? (+15) — review raw JSON-LD blocks for structural issues [COLLECTED]

Output: Score/100 + what's missing + ready-to-use JSON-LD code for top 3 missing schemas.

---

## copywriting

Evaluate these 6 copy elements:
1. Headline: clarity (1-5), specificity (1-5), emotional pull (1-5)
2. Value proposition: unique (1-5), believable (1-5), clear (1-5)
3. CTA copy: action-oriented (1-5), urgency (1-5), low-friction (1-5)
4. Body copy: scannable (1-5), benefit-focused (1-5), objection-handling (1-5)
5. Tone consistency: matches brand across pages (1-5)
6. Proof elements: specificity of claims (1-5), data-backed (1-5)

Output: Score/100 + top 3 weakest copy elements + rewritten versions matching brand voice. Include the ACTUAL current text you're replacing.

---

## marketing-psychology

Score persuasion across these 8 triggers (0-12.5 each):
1. Social proof (reviews, numbers, logos, testimonials)
2. Authority (credentials, press, certifications, expert content)
3. Scarcity/Urgency (limited time, limited stock, countdown)
4. Reciprocity (free content, tools, value before ask)
5. Loss aversion (what they miss without product)
6. Anchoring (price anchoring, comparison to alternatives)
7. Cognitive ease (simple language, familiar patterns, clear next steps)
8. Commitment/Consistency (small yes before big yes, progressive engagement)

Output: Persuasion Score/100 + top 3 missing triggers + specific implementation for each.

---

## signup-flow-cro

Use collector Section 3 "Forms" for form inventory — especially password field detection (indicates signup/login flow exists) and input field type counts [COLLECTED]. Use collector Section 1 "CMS & Frameworks" to understand the tech stack for implementation recommendations [COLLECTED].

If signup/trial/demo flow exists, evaluate:
1. Number of fields — use collector Section 3 form field counts [COLLECTED] (benchmark: 3-5)
2. Social login available? (Google, GitHub, SSO) — look for social login buttons in crawl data + check collector for auth-related scripts [COLLECTED]
3. Password requirements shown upfront? — collector detects password fields [COLLECTED]
4. Error handling (inline validation, clear messages)
5. Progress indication (if multi-step)
6. Value reminder (why sign up, what they get)
7. Trust signals near form (privacy, no credit card, etc.)
8. Post-signup: immediate value or empty state?

Output: Score/100 + top 3 friction points + recommended flow redesign.

---

## checkout-cro

If checkout/cart exists, evaluate:
1. Cart clarity (product details, images, easy edit)
2. Shipping transparency (costs shown early, free threshold?)
3. Guest checkout available?
4. Payment options (cards, PayPal, Apple Pay, etc.)
5. Trust badges (SSL, secure payment, guarantees)
6. Form field count (benchmark: <12 for checkout)
7. Order summary visible throughout?
8. Urgency/scarcity elements (stock levels, cart timer)
9. Abandoned cart recovery likely? (email capture early)

Output: Score/100 + top 3 abandonment risks + fixes.

---

## product-page-cro

If product pages exist, evaluate:
1. Product images (quantity, quality, zoom, lifestyle vs product)
2. Buy box clarity (price, ATC button, availability)
3. Product description (benefits vs features, scannable)
4. Reviews/ratings (present, count, recency, distribution)
5. Cross-sell/upsell (related products, "bought together")
6. Shipping/return info (visible near buy box?)
7. Size/variant selector (UX, availability indication)
8. Mobile buy experience (sticky ATC, swipeable images)

Output: Score/100 + top 3 PDP issues + fixes.

---

## form-cro

Use collector Section 3 "Forms" for exact form inventory: count, action URLs, methods, input field types, and password field detection [COLLECTED]. This gives you the structural foundation — then evaluate UX from crawl data.

Evaluate any lead capture/contact forms:
1. Field count — use collector form field type counts [COLLECTED] (benchmark: 3-5 for lead gen, 7-10 for detailed)
2. Labels and placeholders (clear, not just placeholder-only)
3. Required vs optional indication
4. Inline validation present?
5. Error messages (helpful, specific, near the field)
6. CTA button text (specific > generic, "Get My Quote" > "Submit") — check collector for submit button details [COLLECTED]
7. Privacy/trust near form?
8. Confirmation/thank you experience

Output: Score/100 + top 3 friction points + optimized form HTML.

---

## local-seo

Check via WebSearch:
1. Search "[business name]" — does GBP appear? Rating? Review count?
2. Search "[business name] [city]" — position?
3. Search "[service] near [city]" — does business appear?
4. NAP consistency (name, address, phone same across sources?)
5. GBP completeness (photos, hours, categories, description, posts)
6. Citations on major directories (Yelp, YP, industry-specific)
7. Review velocity (recent reviews in last 30 days?)

Output: Local SEO score/100 + GBP optimization checklist + top 5 missing citations.

---

## review-reputation

Check via WebSearch:
1. Google review count and rating
2. Industry-specific platforms (G2, Capterra, Yelp, Trustpilot, etc.)
3. Review recency (any in last 30 days?)
4. Review response rate (does business reply?)
5. Testimonials on website (present, specific, with photos/names?)
6. Negative review handling (professional responses?)

Output: Reputation score/100 + review generation strategy + 3 response templates (positive, negative, fake).

---

## competitor-alternatives

Use collector Section 1 "Technology Stack" for the target's full tech stack [COLLECTED] — this enables concrete feature comparisons. Use collector Section 8 "PageSpeed" for performance benchmarks to compare against competitors [COLLECTED].

Via collector data [COLLECTED] + WebSearch:
1. Search "[brand] alternative" — what pages exist?
2. Search "[brand] vs [competitor]" — who owns these pages?
3. Identify top 3 competitors from search results
4. Compare: pricing transparency, feature listing, social proof, content depth
5. Tech stack comparison — use collector Section 1 for this brand's stack [COLLECTED], compare to competitors
6. Performance comparison — use collector Section 8 PageSpeed scores as baseline [COLLECTED]

Output: Competitive position assessment + recommended comparison page structure + keyword opportunities.

---

## pricing-strategy

If pricing page exists:
1. Pricing transparency (prices shown vs "contact us")
2. Tier structure (good/better/best pattern?)
3. Recommended tier highlighted?
4. Annual vs monthly toggle?
5. Feature comparison clarity
6. Free tier/trial available?
7. Social proof on pricing page?
8. FAQ/objection handling?

Output: Score/100 + pricing page critique + recommended tier structure.

---

## paid-ads

Use collector Section 1 "Analytics & Tracking" for ad pixel detection — Meta Pixel, LinkedIn Insight Tag, TikTok Pixel, Pinterest Tag, Twitter Pixel [COLLECTED]. This is HIGH confidence vs. inferring from crawl data.

Via collector data [COLLECTED] + WebSearch:
1. Google Ads likely running? (branded search results via WebSearch)
2. Meta Pixel detected? — check collector Section 1 [COLLECTED]
3. LinkedIn pixel detected? — check collector Section 1 [COLLECTED]
4. TikTok/Pinterest/Twitter pixels? — check collector Section 1 [COLLECTED]
5. Landing page quality for ads (if separate from main site)
6. Ad copy quality (if visible in search)
7. Retargeting likely active? (based on pixel presence [COLLECTED])

Output: Paid ads readiness score/100 + recommended channel mix + budget allocation + 3 ad copy variants.

---

## social-content

Use collector Section 4 "Social Links & Profiles" for detected social profile URLs (12 platforms), RSS feeds, and sharing buttons [COLLECTED]. This gives you the exact platform list to audit — no guessing.

Via collector data [COLLECTED] + WebSearch:
1. Active platforms — check collector Section 4 for linked profiles [COLLECTED], then verify posting activity via WebSearch
2. Posting frequency (last post date per platform — via WebSearch)
3. Follower count (where visible)
4. Content quality (types: text, image, video, carousel)
5. Engagement visible? (likes, comments, shares)
6. Bio/profile optimization (clear value prop, link, CTA)
7. RSS feed present? — check collector Section 4 "RSS / Feeds" [COLLECTED]
8. Social sharing buttons on site? — check collector Section 4 "Social Sharing" [COLLECTED]

Output: Social presence score/100 + platform priority recommendation + content calendar (4 weeks, 3 posts/week).

---

## email-sequence

Use collector Section 1 "Email & Marketing Platforms" for detected email platform (Klaviyo, Mailchimp, ConvertKit, ActiveCampaign, etc.) [COLLECTED]. Use collector Section 7 "DNS & Email Auth" for SPF/DMARC status [COLLECTED] — deliverability infrastructure. Use collector Section 3 "Forms" for email capture form details [COLLECTED].

Check for:
1. Email capture on site (popup, inline form, footer, content upgrade) — use collector Section 3 "Forms" for form inventory [COLLECTED]
2. Email platform detected — check collector Section 1 [COLLECTED]
3. Lead magnet offered? (what type — from crawl data)
4. Incentive for signup? (discount, free resource, etc.)
5. SPF/DMARC configured? — check collector Section 7 [COLLECTED] (deliverability risk if missing)
6. Email provider detected via MX? — check collector Section 7 "MX Records" [COLLECTED]

Output: Email readiness score/100 + recommended welcome sequence (5 emails with subject lines and purpose).

---

## ecommerce-email

Use collector Section 1 "Email & Marketing Platforms" for detected email/marketing platform (Klaviyo, Omnisend, Mailchimp, etc.) [COLLECTED]. Use collector Section 1 "Payment & E-commerce" for detected payment processor and e-commerce platform [COLLECTED]. Use collector Section 7 "DNS & Email Auth" for SPF/DMARC [COLLECTED].

Check for:
1. Email platform detected — check collector Section 1 "Email & Marketing Platforms" [COLLECTED]
2. E-commerce platform detected — check collector Section 1 "Payment & E-commerce" (Shopify, WooCommerce, etc.) [COLLECTED]
3. Cart abandonment recovery likely? (email capture before checkout — from crawl data)
4. Transactional emails (order confirm, shipping, delivery)
5. Post-purchase follow-up (review request, cross-sell)
6. Win-back campaigns likely?
7. Email capture mechanisms (popup, footer, account creation) — use collector Section 3 "Forms" [COLLECTED]
8. SPF/DMARC configured? — check collector Section 7 [COLLECTED] (critical for deliverability)

Output: Email maturity score/100 + recommended 7-flow setup with trigger, timing, and purpose for each.

---

## popup-cro

Check for:
1. Popup present? (what type: modal, slide-in, banner, exit intent)
2. Timing (immediate, delayed, scroll-based, exit intent)
3. Offer (discount, content, newsletter — what's the value?)
4. Design quality (on-brand, clear CTA, easy dismiss)
5. Mobile popup experience (compliant, usable, not intrusive)

Output: Score/100 + recommended popup strategy + popup HTML/CSS if none exists.

---

## referral-program

Check for:
1. Referral program exists? (link in footer, account area, etc.)
2. Incentive structure visible? (what both parties get)
3. Ease of sharing (link, email, social buttons)
4. Referral tracking likely?

Output: Score/100 + recommended referral program design with incentive structure.

---

## free-tool-strategy

Evaluate opportunity:
1. Does a free tool exist? (calculator, analyzer, generator, checker)
2. If yes: quality, SEO value, lead capture, virality
3. If no: what tool would work for this business? (based on industry + audience)
4. Competitor free tools? (via WebSearch)

Output: Opportunity score/100 + top 2 free tool concepts with brief specs.

---

## programmatic-seo

Use collector Section 10 "robots.txt & Sitemap" for sitemap URL count, lastmod dates, and disallow rules [COLLECTED]. Use collector Section 1 "CMS & Frameworks" for CMS detection (important for implementation approach) [COLLECTED].

Evaluate opportunity:
1. Category/location pages exist? (search "site:[domain] [city]" or similar)
2. Sitemap URL count — use collector Section 10 for exact count [COLLECTED] (reveals current page volume)
3. Sitemap freshness — check lastmod dates from collector [COLLECTED]
4. robots.txt rules — check collector Section 10 for disallow rules that might block pSEO pages [COLLECTED]
5. CMS platform — check collector Section 1 [COLLECTED] (determines implementation complexity)
6. Data available for templatization? (products, locations, integrations, use cases)
7. Competitors doing pSEO? (search competitor + permutation patterns)

Output: Opportunity score/100 + top 2 pSEO template opportunities with estimated page count.

---

## geo-audit

Via research:
1. Search "[brand] + [category]" on ChatGPT/Perplexity-style queries mentally
2. Does the brand appear in AI-generated answers for their category?
3. Brand mentioned in authoritative sources AI would reference?
4. Structured data that helps AI understand the business?
5. Content depth on key topics (comprehensive enough to be cited?)

Output: GEO readiness score/100 + top 3 actions to improve AI visibility.

---

## retention-loyalty

If e-commerce:
1. Loyalty/rewards program exists?
2. Post-purchase experience (follow-up, review request, cross-sell)
3. Subscription/replenishment option?
4. Customer account area (order history, wishlists, saved items)
5. Re-engagement visible? (we miss you emails, reactivation offers)

Output: Retention score/100 + recommended loyalty program structure.

---

## product-feed

If e-commerce:
1. Google Shopping presence? (search product name, check Shopping tab)
2. Product data quality (titles, descriptions, images, GTINs)
3. Pricing competitive? (vs Shopping results)
4. Product reviews in Shopping results?
5. Meta/Facebook catalog likely? (pixel + product pages)

Output: Feed readiness score/100 + top 5 feed optimization actions.

---

## launch-strategy

General assessment:
1. Recent launches visible? (blog posts, changelogs, announcements)
2. Launch infrastructure (email list, social following, blog)
3. Press/media mentions? (via WebSearch)
4. Community presence? (forums, Discord, Slack, social engagement)

Output: Launch readiness score/100 + recommended launch playbook outline.

---

## onboarding-cro

If SaaS with product:
1. Signup-to-value path (how many steps to "aha moment"?)
2. Onboarding checklist/wizard present?
3. Empty states handled? (helpful vs blank)
4. Activation metric likely? (what constitutes "activated"?)
5. Help/support accessible during onboarding?

Output: Score/100 + recommended onboarding flow + activation metric suggestion.

---

## paywall-upgrade-cro

If freemium/free tier exists:
1. Upgrade prompts present? (in-app, feature gates, usage limits)
2. Value communication (what premium adds)
3. Pricing visibility in-app
4. Upgrade friction (how many clicks to upgrade?)

Output: Score/100 + recommended upgrade prompt strategy + 2 paywall copy variants.

---

## market-analyst

Quick competitive overview:
1. Market size signals (via WebSearch for industry reports)
2. Competitor count and quality
3. Differentiation clarity
4. Growth trajectory signals

Output: Market position summary + 3 competitive advantages + 3 risks.

---

## daily-deals-cro

If applicable:
1. Sale/deal pages exist?
2. Urgency mechanics (countdown, stock, limited time)
3. Deal presentation (savings shown, original price, percentage off)
4. Deal email/notification system?

Output: Score/100 + recommended deal page structure.

---

## copy-editing

Quick copy quality check:
1. Grammar/spelling errors
2. Readability (grade level, sentence length)
3. Consistency (tone, terminology, style)
4. Jargon level appropriate for audience?
5. CTA clarity and strength

Output: Copy quality score/100 + top 5 copy fixes with before/after.

---

## marketing-ideas

Based on business type and current state, generate:
1. Top 5 marketing tactics for this specific business (not generic)
2. Quick win ideas (implementable in <1 week)
3. Growth experiment ideas (testable in 30 days)

Output: Prioritized list of 10 marketing ideas with effort/impact rating.
