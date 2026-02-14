# Condensed Audit Playbooks

These are stripped-down audit instructions for batch execution. Each playbook is ~50-80 lines — just the scoring criteria, key checks, and output format. No educational content, no examples, no optional sections.

The orchestrator INJECTS these directly into agent prompts. Agents never read the full SKILL.md files.

---

## page-cro

Score the page 0-100 across these 10 dimensions (10 pts each):
1. Value proposition clarity (above fold, <8 words ideal)
2. Primary CTA (visible, contrast, action verb, single focus)
3. Social proof (testimonials, logos, stats, reviews - present + quality)
4. Visual hierarchy (F-pattern/Z-pattern, whitespace, scannable)
5. Trust signals (security badges, guarantees, certifications)
6. Page speed (perceived load time)
7. Mobile experience (responsive, touch targets, thumb zones)
8. Content structure (headings, bullet points, scannable)
9. Objection handling (FAQ, guarantees, risk reversal)
10. Secondary CTAs (alternative actions for non-ready visitors)

Output: Score + top 3 issues with fixes + 3 rewritten sections (headline, CTA, social proof).

---

## seo-audit

Check these 8 areas, score each 0-10:
1. Title tags (unique, <60 chars, keyword-first, compelling)
2. Meta descriptions (unique, <155 chars, CTA, keyword present)
3. H1 structure (single H1 per page, keyword-rich, matches intent)
4. URL structure (short, descriptive, no parameters, lowercase)
5. Internal linking (orphan pages, anchor text, link depth)
6. Image optimization (alt text, file size, format, lazy loading)
7. Core Web Vitals (LCP, FID/INP, CLS — check via WebSearch "[domain] pagespeed")
8. Indexation (search "site:[domain]" for page count, check robots.txt mention)

Output: Score/80 + top 3 technical issues + 5 keyword opportunities found via WebSearch.

---

## analytics-tracking

Check for these signals in the page source/behavior:
1. GA4 installed? (look for gtag.js, G-XXXXXXX, or GTM container)
2. GTM present? (look for GTM-XXXXXX)
3. Meta Pixel? (look for fbq, Facebook pixel)
4. Conversion tracking? (any event-based tracking visible)
5. UTM usage? (check if links use utm_ parameters)
6. Cookie consent? (banner present, GDPR/CCPA compliant)
7. Search Console likely connected? (meta verification tag)
8. Other tools? (Hotjar, Clarity, Mixpanel, Amplitude, etc.)

Score: 0-100 based on completeness.
Output: What's installed, what's missing, top 3 tracking gaps, recommended GA4 event taxonomy (5-10 key events for this business type).

---

## schema-markup

Check page source for existing structured data (JSON-LD, microdata, RDFa).
Score based on:
1. Any schema present? (+20 if yes)
2. Organization/LocalBusiness schema? (+15)
3. Breadcrumb schema? (+10)
4. FAQ schema on relevant pages? (+10)
5. Product/Service schema? (+15)
6. Review/Rating schema? (+15)
7. Correct implementation (no errors)? (+15)

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

If signup/trial/demo flow exists, evaluate:
1. Number of fields (fewer = better, benchmark: 3-5)
2. Social login available? (Google, GitHub, SSO)
3. Password requirements shown upfront?
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

Evaluate any lead capture/contact forms:
1. Field count (benchmark: 3-5 for lead gen, 7-10 for detailed)
2. Labels and placeholders (clear, not just placeholder-only)
3. Required vs optional indication
4. Inline validation present?
5. Error messages (helpful, specific, near the field)
6. CTA button text (specific > generic, "Get My Quote" > "Submit")
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

Via WebSearch:
1. Search "[brand] alternative" — what pages exist?
2. Search "[brand] vs [competitor]" — who owns these pages?
3. Identify top 3 competitors from search results
4. Compare: pricing transparency, feature listing, social proof, content depth

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

Via WebSearch for "[brand] ads" or checking for pixels:
1. Google Ads likely running? (branded search results)
2. Meta Pixel detected?
3. LinkedIn pixel detected?
4. Landing page quality for ads (if separate from main site)
5. Ad copy quality (if visible in search)
6. Retargeting likely active?

Output: Paid ads readiness score/100 + recommended channel mix + budget allocation + 3 ad copy variants.

---

## social-content

Via WebSearch:
1. Active platforms (LinkedIn, Twitter/X, Instagram, TikTok, Facebook, YouTube)
2. Posting frequency (last post date per platform)
3. Follower count (where visible)
4. Content quality (types: text, image, video, carousel)
5. Engagement visible? (likes, comments, shares)
6. Bio/profile optimization (clear value prop, link, CTA)

Output: Social presence score/100 + platform priority recommendation + content calendar (4 weeks, 3 posts/week).

---

## email-sequence

Check for:
1. Email capture on site (popup, inline form, footer, content upgrade)
2. Lead magnet offered? (what type)
3. Incentive for signup? (discount, free resource, etc.)
4. Double opt-in or single?
5. Welcome email likely? (sign up and check if immediate response)

Output: Email readiness score/100 + recommended welcome sequence (5 emails with subject lines and purpose).

---

## ecommerce-email

Check for:
1. Cart abandonment recovery likely? (email capture before checkout)
2. Transactional emails (order confirm, shipping, delivery)
3. Post-purchase follow-up (review request, cross-sell)
4. Win-back campaigns likely?
5. Email capture mechanisms (popup, footer, account creation)

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

Evaluate opportunity:
1. Category/location pages exist? (search "site:[domain] [city]" or similar)
2. Data available for templatization? (products, locations, integrations, use cases)
3. Competitors doing pSEO? (search competitor + permutation patterns)
4. Current indexed page count (via site: search)

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
