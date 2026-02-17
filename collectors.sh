#!/usr/bin/env bash
# Marketing Orchestrator — Collector Phase
# Runs between crawl and agent spawning. Extracts raw technical data
# that WebFetch strips (HTML tags, headers, SSL, DNS, PageSpeed, etc.)
#
# Usage: bash collectors.sh <domain> <audit_dir>
# Output: ${AUDIT_DIR}/collectors-data.md
#
# Requirements: macOS standard tools (curl, dig, openssl, grep, sed, awk)
# Optional: jq (for cleaner PageSpeed parsing — falls back to grep)

set -euo pipefail

DOMAIN="${1:?Usage: collectors.sh <domain> <audit_dir>}"
AUDIT_DIR="${2:?Usage: collectors.sh <domain> <audit_dir>}"
TMP=$(mktemp -d)
OUTPUT="${AUDIT_DIR}/collectors-data.md"
CRAWL_DATA="${AUDIT_DIR}/crawl-data.md"

# Strip protocol and trailing slash
DOMAIN=$(echo "$DOMAIN" | sed 's|https\?://||;s|/.*||;s|www\.||')
BASE_URL="https://${DOMAIN}"

# Timing
TOTAL_START=$(date +%s)

# ─── Shared Setup ────────────────────────────────────────────────────────────

echo "[collectors] Starting 10 collectors for ${DOMAIN}..."

# Fetch homepage raw HTML (shared by tech-stack, structured-data, html-structure, social-links)
curl -sL --max-time 15 -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  "${BASE_URL}" -o "${TMP}/homepage.html" 2>/dev/null || true

# Fetch response headers + cookies (shared by security-headers, cookies)
curl -sL --max-time 10 -D "${TMP}/response-headers.txt" -o /dev/null \
  -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  -c "${TMP}/cookies-raw.txt" \
  "${BASE_URL}" 2>/dev/null || true

# Fetch up to 3 additional pages from crawl-data.md for broader detection
if [[ -f "$CRAWL_DATA" ]]; then
  EXTRA_URLS=$(grep -oE '## PAGE: https?://[^ ]+' "$CRAWL_DATA" | sed 's/## PAGE: //' | head -3)
  PAGE_IDX=1
  for url in $EXTRA_URLS; do
    curl -sL --max-time 10 -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
      "$url" -o "${TMP}/page${PAGE_IDX}.html" 2>/dev/null || true
    PAGE_IDX=$((PAGE_IDX + 1))
  done
fi

# Combine all HTML for multi-page scanning
cat "${TMP}"/homepage.html "${TMP}"/page*.html 2>/dev/null > "${TMP}/all-pages.html" || \
  cp "${TMP}/homepage.html" "${TMP}/all-pages.html" 2>/dev/null || true

# ─── Collector Runner ────────────────────────────────────────────────────────

COLLECTOR_RESULTS=()

run_collector() {
  local name="$1"
  local func="$2"
  local start end duration result
  start=$(date +%s)

  result=$($func 2>/dev/null) || result="**${name}: Collection failed** — site may block automated requests or resource unavailable."

  end=$(date +%s)
  duration=$((end - start))
  echo "[collectors] ${name} done (${duration}s)"
  COLLECTOR_RESULTS+=("$result")
}

# ─── Collector 1: Technology Stack ───────────────────────────────────────────

collect_tech_stack() {
  local html="${TMP}/all-pages.html"
  [[ ! -s "$html" ]] && echo "**Technology Stack: No HTML available**" && return

  echo "## 1. Technology Stack"
  echo ""
  echo "Detected technologies from raw HTML analysis:"
  echo ""

  # CMS / Frameworks
  echo "### CMS & Frameworks"
  grep -qiE 'Shopify|cdn\.shopify\.com' "$html" && echo "- Shopify [COLLECTED]"
  grep -qiE 'wp-content|wp-includes|wordpress' "$html" && echo "- WordPress [COLLECTED]"
  grep -qiE 'woocommerce|wc-block' "$html" && echo "- WooCommerce [COLLECTED]"
  grep -qiE 'Squarespace|squarespace-cdn' "$html" && echo "- Squarespace [COLLECTED]"
  grep -qiE 'wix\.com|wixsite' "$html" && echo "- Wix [COLLECTED]"
  grep -qiE 'webflow\.com|webflow\.io' "$html" && echo "- Webflow [COLLECTED]"
  grep -qiE '__next|_next/static|next\.js' "$html" && echo "- Next.js [COLLECTED]"
  grep -qiE 'gatsby|\/static\/[a-f0-9]*\/|gatsby-image' "$html" && echo "- Gatsby [COLLECTED]"
  grep -qiE '__nuxt|nuxt\.js' "$html" && echo "- Nuxt.js [COLLECTED]"
  grep -qiE 'ng-version|angular' "$html" && echo "- Angular [COLLECTED]"
  grep -qiE 'data-reactroot|react\.production' "$html" && echo "- React [COLLECTED]"
  grep -qiE 'svelte|__svelte' "$html" && echo "- Svelte [COLLECTED]"
  grep -qiE 'vue\.js|data-v-|vue\.runtime' "$html" && echo "- Vue.js [COLLECTED]"
  grep -qiE 'drupal|sites\/all|sites\/default' "$html" && echo "- Drupal [COLLECTED]"
  grep -qiE 'joomla|\/media\/system' "$html" && echo "- Joomla [COLLECTED]"
  grep -qiE 'ghost\.org|ghost-theme' "$html" && echo "- Ghost [COLLECTED]"
  grep -qiE 'magento|mage\/cookies' "$html" && echo "- Magento [COLLECTED]"
  grep -qiE 'bigcommerce|cdn\.bigcommerce' "$html" && echo "- BigCommerce [COLLECTED]"
  grep -qiE 'prestashop' "$html" && echo "- PrestaShop [COLLECTED]"
  grep -qiE 'hubspot\.com|hs-scripts' "$html" && echo "- HubSpot CMS [COLLECTED]"
  echo ""

  # Analytics & Tracking
  echo "### Analytics & Tracking"
  grep -qiE 'gtag|google-analytics|googletagmanager|G-[A-Z0-9]+' "$html" && echo "- Google Analytics 4 [COLLECTED]"
  grep -qiE 'GTM-[A-Z0-9]+|googletagmanager\.com\/gtm' "$html" && echo "- Google Tag Manager [COLLECTED]"
  grep -qiE 'fbq\(|connect\.facebook\.net\/.*fbevents|facebook-pixel' "$html" && echo "- Meta Pixel (Facebook) [COLLECTED]"
  grep -qiE 'snap\.licdn|linkedin\.com\/px|_linkedin_partner_id' "$html" && echo "- LinkedIn Insight Tag [COLLECTED]"
  grep -qiE 'analytics\.tiktok|ttq\.load' "$html" && echo "- TikTok Pixel [COLLECTED]"
  grep -qiE 'pintrk|pinterest\.com\/ct' "$html" && echo "- Pinterest Tag [COLLECTED]"
  grep -qiE 'twq\(|twitter\.com\/.*oct' "$html" && echo "- Twitter/X Pixel [COLLECTED]"
  grep -qiE 'hotjar\.com|_hjSettings' "$html" && echo "- Hotjar [COLLECTED]"
  grep -qiE 'clarity\.ms|microsoft-clarity' "$html" && echo "- Microsoft Clarity [COLLECTED]"
  grep -qiE 'mixpanel\.com|mixpanel\.init' "$html" && echo "- Mixpanel [COLLECTED]"
  grep -qiE 'segment\.com|analytics\.js|cdn\.segment' "$html" && echo "- Segment [COLLECTED]"
  grep -qiE 'amplitude\.com|amplitude\.init' "$html" && echo "- Amplitude [COLLECTED]"
  grep -qiE 'plausible\.io' "$html" && echo "- Plausible Analytics [COLLECTED]"
  grep -qiE 'fathom\.com|usefathom' "$html" && echo "- Fathom Analytics [COLLECTED]"
  grep -qiE 'heap\.io|heapanalytics' "$html" && echo "- Heap [COLLECTED]"
  grep -qiE 'posthog\.com|posthog\.init' "$html" && echo "- PostHog [COLLECTED]"
  grep -qiE 'matomo|piwik' "$html" && echo "- Matomo/Piwik [COLLECTED]"
  echo ""

  # Email & Marketing
  echo "### Email & Marketing Platforms"
  grep -qiE 'klaviyo\.com|klaviyo\.js' "$html" && echo "- Klaviyo [COLLECTED]"
  grep -qiE 'mailchimp\.com|mc\.js|chimpstatic' "$html" && echo "- Mailchimp [COLLECTED]"
  grep -qiE 'convertkit\.com|ck\.page' "$html" && echo "- ConvertKit [COLLECTED]"
  grep -qiE 'activecampaign\.com' "$html" && echo "- ActiveCampaign [COLLECTED]"
  grep -qiE 'drip\.com|getdrip' "$html" && echo "- Drip [COLLECTED]"
  grep -qiE 'sendgrid\.com|sendgrid\.net' "$html" && echo "- SendGrid [COLLECTED]"
  grep -qiE 'hubspot\.com\/.*forms|hsforms' "$html" && echo "- HubSpot Forms [COLLECTED]"
  grep -qiE 'intercom\.com|intercomSettings' "$html" && echo "- Intercom [COLLECTED]"
  grep -qiE 'drift\.com|driftt' "$html" && echo "- Drift [COLLECTED]"
  grep -qiE 'crisp\.chat|crisp\.im' "$html" && echo "- Crisp [COLLECTED]"
  grep -qiE 'zendesk\.com|zopim' "$html" && echo "- Zendesk [COLLECTED]"
  grep -qiE 'tawk\.to' "$html" && echo "- Tawk.to [COLLECTED]"
  grep -qiE 'livechat|livechatinc' "$html" && echo "- LiveChat [COLLECTED]"
  grep -qiE 'omnisend\.com' "$html" && echo "- Omnisend [COLLECTED]"
  grep -qiE 'brevo\.com|sendinblue' "$html" && echo "- Brevo (Sendinblue) [COLLECTED]"
  echo ""

  # Payment & E-commerce
  echo "### Payment & E-commerce"
  grep -qiE 'stripe\.com|stripe\.js|Stripe\(' "$html" && echo "- Stripe [COLLECTED]"
  grep -qiE 'paypal\.com|paypalobjects' "$html" && echo "- PayPal [COLLECTED]"
  grep -qiE 'klarna\.com|klarna-payments' "$html" && echo "- Klarna [COLLECTED]"
  grep -qiE 'afterpay\.com|afterpay-js' "$html" && echo "- Afterpay [COLLECTED]"
  grep -qiE 'affirm\.com|affirm\.js' "$html" && echo "- Affirm [COLLECTED]"
  grep -qiE 'recharge\.com|rechargepayments' "$html" && echo "- ReCharge [COLLECTED]"
  grep -qiE 'swell\.is|swellrewards' "$html" && echo "- Swell Rewards [COLLECTED]"
  grep -qiE 'yotpo\.com' "$html" && echo "- Yotpo [COLLECTED]"
  grep -qiE 'judge\.me|judgeme' "$html" && echo "- Judge.me [COLLECTED]"
  grep -qiE 'stamped\.io' "$html" && echo "- Stamped.io [COLLECTED]"
  grep -qiE 'loox\.io' "$html" && echo "- Loox Reviews [COLLECTED]"
  echo ""

  # A/B Testing & Personalization
  echo "### A/B Testing & Personalization"
  grep -qiE 'optimizely\.com' "$html" && echo "- Optimizely [COLLECTED]"
  grep -qiE 'vwo\.com|visualwebsiteoptimizer' "$html" && echo "- VWO [COLLECTED]"
  grep -qiE 'abtasty\.com' "$html" && echo "- AB Tasty [COLLECTED]"
  grep -qiE 'convert\.com' "$html" && echo "- Convert [COLLECTED]"
  grep -qiE 'google_optimize|optimize\.google' "$html" && echo "- Google Optimize [COLLECTED]"
  grep -qiE 'launchdarkly\.com' "$html" && echo "- LaunchDarkly [COLLECTED]"
  echo ""

  # Cookie Consent / GDPR
  echo "### Cookie Consent & Compliance"
  grep -qiE 'cookiebot|cookieconsent|onetrust|osano|iubenda|complianz|termly|quantcast' "$html" && {
    grep -qiE 'cookiebot' "$html" && echo "- Cookiebot [COLLECTED]"
    grep -qiE 'onetrust' "$html" && echo "- OneTrust [COLLECTED]"
    grep -qiE 'osano' "$html" && echo "- Osano [COLLECTED]"
    grep -qiE 'iubenda' "$html" && echo "- Iubenda [COLLECTED]"
    grep -qiE 'complianz' "$html" && echo "- Complianz [COLLECTED]"
    grep -qiE 'termly' "$html" && echo "- Termly [COLLECTED]"
    grep -qiE 'quantcast' "$html" && echo "- Quantcast Choice [COLLECTED]"
    grep -qiE 'cookieconsent' "$html" && echo "- CookieConsent [COLLECTED]"
  } || echo "- No cookie consent platform detected [COLLECTED]"
  echo ""
}

# ─── Collector 2: Structured Data (JSON-LD) ─────────────────────────────────

collect_structured_data() {
  local html="${TMP}/all-pages.html"
  [[ ! -s "$html" ]] && echo "**Structured Data: No HTML available**" && return

  echo "## 2. Structured Data (JSON-LD)"
  echo ""

  # Extract JSON-LD blocks
  local jsonld_blocks
  jsonld_blocks=$(awk '
    /<script[^>]*type="application\/ld\+json"[^>]*>/,/<\/script>/ {
      if (/<script/) { block=""; next }
      if (/<\/script>/) { print block; print "---BLOCK_SEP---"; next }
      block = block $0
    }
  ' "$html" 2>/dev/null)

  if [[ -z "$jsonld_blocks" ]]; then
    echo "**No JSON-LD structured data found.** [COLLECTED]"
    echo ""
    echo "This is a critical gap — WebFetch cannot detect structured data"
    echo "because it strips \`<script>\` tags. Without this collector,"
    echo "agents would have zero visibility into schema markup."
    return
  fi

  # Count blocks
  local block_count
  block_count=$(echo "$jsonld_blocks" | grep -c "BLOCK_SEP" || echo "0")
  echo "Found **${block_count} JSON-LD block(s)** [COLLECTED]"
  echo ""

  # Extract @type values
  echo "### Schema Types Detected"
  local types
  types=$(echo "$jsonld_blocks" | grep -oE '"@type"\s*:\s*"[^"]*"' | sed 's/"@type"\s*:\s*"//;s/"//' | sort -u)
  if [[ -n "$types" ]]; then
    while IFS= read -r t; do
      echo "- \`${t}\` [COLLECTED]"
    done <<< "$types"
  else
    echo "- No @type detected [COLLECTED]"
  fi
  echo ""

  # Print raw blocks (truncated for readability)
  echo "### Raw JSON-LD Blocks"
  echo ""
  local block_num=1
  while IFS= read -r line; do
    if [[ "$line" == "---BLOCK_SEP---" ]]; then
      echo '```'
      echo ""
      block_num=$((block_num + 1))
      continue
    fi
    if [[ $block_num -le 5 ]]; then
      if [[ "$line" != "---BLOCK_SEP---" ]]; then
        [[ "$line" == *"@type"* ]] && echo "\`\`\`json" && echo "Block ${block_num}:"
        echo "$line"
      fi
    fi
  done <<< "$jsonld_blocks"
  # Close any open code block
  echo '```'
  echo ""
}

# ─── Collector 3: HTML Structure ─────────────────────────────────────────────

collect_html_structure() {
  local html="${TMP}/homepage.html"
  [[ ! -s "$html" ]] && echo "**HTML Structure: No HTML available**" && return

  echo "## 3. HTML Structure Analysis"
  echo ""

  # Title tag
  echo "### Title Tag"
  local title
  title=$(grep -oiE '<title[^>]*>[^<]*</title>' "$html" | head -1 | sed 's/<[^>]*>//g')
  if [[ -n "$title" ]]; then
    local title_len=${#title}
    echo "- Title: \`${title}\` (${title_len} chars) [COLLECTED]"
    if [[ $title_len -gt 60 ]]; then
      echo "- Warning: Title exceeds 60 char recommendation [COLLECTED]"
    fi
  else
    echo "- No title tag found [COLLECTED]"
  fi
  echo ""

  # Meta tags
  echo "### Meta Tags"
  grep -oiE '<meta[^>]*(name|property)="[^"]*"[^>]*content="[^"]*"[^>]*>' "$html" | head -20 | while IFS= read -r meta; do
    local name val
    name=$(echo "$meta" | grep -oE '(name|property)="[^"]*"' | head -1 | sed 's/.*="//;s/"//')
    val=$(echo "$meta" | grep -oE 'content="[^"]*"' | head -1 | sed 's/content="//;s/"//')
    [[ -n "$name" ]] && echo "- \`${name}\`: ${val:0:120} [COLLECTED]"
  done
  echo ""

  # Heading hierarchy
  echo "### Heading Hierarchy"
  for level in 1 2 3 4 5 6; do
    local count
    count=$(grep -oiE "<h${level}[^>]*>" "$html" | wc -l | tr -d ' ')
    if [[ "$count" -gt 0 ]]; then
      echo "- **H${level}:** ${count} found [COLLECTED]"
      if [[ $level -le 3 ]]; then
        grep -oiE "<h${level}[^>]*>[^<]*<" "$html" | head -5 | sed "s/<h${level}[^>]*>//i;s/<$//" | while IFS= read -r h; do
          local trimmed
          trimmed=$(echo "$h" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          [[ -n "$trimmed" ]] && echo "  - \"${trimmed:0:80}\" [COLLECTED]"
        done
      fi
    fi
  done
  echo ""

  # Images
  echo "### Images"
  local total_imgs missing_alt
  total_imgs=$(grep -oiE '<img[^>]*>' "$html" | wc -l | tr -d ' ')
  missing_alt=$(grep -oiE '<img[^>]*>' "$html" | grep -viE 'alt="[^"]+' | wc -l | tr -d ' ')
  echo "- Total images: ${total_imgs} [COLLECTED]"
  echo "- Missing/empty alt text: ${missing_alt} [COLLECTED]"
  if [[ "$missing_alt" -gt 0 ]]; then
    echo "- Images without alt text:"
    grep -oiE '<img[^>]*>' "$html" | grep -viE 'alt="[^"]+' | head -5 | while IFS= read -r img; do
      local src
      src=$(echo "$img" | grep -oE 'src="[^"]*"' | head -1 | sed 's/src="//;s/"//')
      [[ -n "$src" ]] && echo "  - \`${src:0:100}\` [COLLECTED]"
    done
  fi
  echo ""

  # Forms
  echo "### Forms"
  local form_count
  form_count=$(grep -oiE '<form[^>]*>' "$html" | wc -l | tr -d ' ')
  echo "- Total forms: ${form_count} [COLLECTED]"
  if [[ "$form_count" -gt 0 ]]; then
    grep -oiE '<form[^>]*>' "$html" | head -5 | while IFS= read -r form; do
      local action method
      action=$(echo "$form" | grep -oE 'action="[^"]*"' | head -1 | sed 's/action="//;s/"//')
      method=$(echo "$form" | grep -oE 'method="[^"]*"' | head -1 | sed 's/method="//;s/"//')
      echo "  - action=\`${action:-none}\` method=\`${method:-GET}\` [COLLECTED]"
    done

    # Input fields
    local input_types
    input_types=$(grep -oiE '<input[^>]*type="[^"]*"' "$html" | grep -oE 'type="[^"]*"' | sed 's/type="//;s/"//' | sort | uniq -c | sort -rn)
    if [[ -n "$input_types" ]]; then
      echo "- Input field types:"
      echo "$input_types" | head -10 | while IFS= read -r line; do
        echo "  - ${line} [COLLECTED]"
      done
    fi

    # Password fields (for signup detection)
    local pw_count
    pw_count=$(grep -oiE 'type="password"' "$html" | wc -l | tr -d ' ')
    [[ "$pw_count" -gt 0 ]] && echo "- Password fields detected: ${pw_count} (signup/login flow present) [COLLECTED]"
  fi
  echo ""

  # Word count
  echo "### Content Metrics"
  local word_count
  word_count=$(sed 's/<[^>]*>//g' "$html" | tr -s '[:space:]' '\n' | wc -l | tr -d ' ')
  echo "- Approximate word count (homepage): ${word_count} [COLLECTED]"
  echo ""
}

# ─── Collector 4: Social Links ───────────────────────────────────────────────

collect_social_links() {
  local html="${TMP}/all-pages.html"
  [[ ! -s "$html" ]] && echo "**Social Links: No HTML available**" && return

  echo "## 4. Social Links & Profiles"
  echo ""

  local found=0

  # Platform detection
  local -A platforms=(
    ["Facebook"]='facebook\.com\/[^"'\'']*'
    ["Twitter/X"]='(twitter\.com|x\.com)\/[^"'\'']*'
    ["Instagram"]='instagram\.com\/[^"'\'']*'
    ["LinkedIn"]='linkedin\.com\/(company|in)\/[^"'\'']*'
    ["YouTube"]='youtube\.com\/(channel|c|@)[^"'\'']*'
    ["TikTok"]='tiktok\.com\/@[^"'\'']*'
    ["Pinterest"]='pinterest\.com\/[^"'\'']*'
    ["GitHub"]='github\.com\/[^"'\'']*'
    ["Discord"]='discord\.(gg|com)\/[^"'\'']*'
    ["Slack"]='slack\.com\/[^"'\'']*'
    ["Reddit"]='reddit\.com\/r\/[^"'\'']*'
    ["Threads"]='threads\.net\/@[^"'\'']*'
  )

  echo "### Social Profiles Found"
  for platform in Facebook "Twitter/X" Instagram LinkedIn YouTube TikTok Pinterest GitHub Discord Slack Reddit Threads; do
    local pattern="${platforms[$platform]}"
    local url
    url=$(grep -oiE "href=\"https?://(www\.)?${pattern}" "$html" | head -1 | sed 's/href="//;s/"$//')
    if [[ -n "$url" ]]; then
      echo "- **${platform}:** ${url} [COLLECTED]"
      found=$((found + 1))
    fi
  done

  [[ $found -eq 0 ]] && echo "- No social profile links detected [COLLECTED]"
  echo ""

  # RSS Feed
  echo "### RSS / Feeds"
  local rss
  rss=$(grep -oiE 'type="application/(rss|atom)\+xml"[^>]*href="[^"]*"' "$html" | head -3)
  if [[ -n "$rss" ]]; then
    echo "$rss" | while IFS= read -r r; do
      local href
      href=$(echo "$r" | grep -oE 'href="[^"]*"' | sed 's/href="//;s/"//')
      echo "- RSS/Atom: ${href} [COLLECTED]"
    done
  else
    echo "- No RSS/Atom feed detected [COLLECTED]"
  fi
  echo ""

  # Social sharing buttons
  echo "### Social Sharing"
  local sharing=0
  grep -qiE 'addthis|sharethis|addtoany|share-btn|social-share|sharing-button' "$html" && {
    echo "- Social sharing widget detected [COLLECTED]"
    sharing=1
  }
  grep -qiE 'share.*facebook|share.*twitter|share.*linkedin|share.*whatsapp' "$html" && {
    echo "- Share buttons found in HTML [COLLECTED]"
    sharing=1
  }
  [[ $sharing -eq 0 ]] && echo "- No social sharing buttons detected [COLLECTED]"
  echo ""
}

# ─── Collector 5: Security Headers ──────────────────────────────────────────

collect_security_headers() {
  local headers="${TMP}/response-headers.txt"
  [[ ! -s "$headers" ]] && echo "**Security Headers: No response headers available**" && return

  echo "## 5. Security Headers"
  echo ""

  local -A sec_headers=(
    ["Strict-Transport-Security"]="HSTS — enforces HTTPS"
    ["Content-Security-Policy"]="CSP — prevents XSS/injection"
    ["X-Content-Type-Options"]="Prevents MIME sniffing"
    ["X-Frame-Options"]="Prevents clickjacking"
    ["Referrer-Policy"]="Controls referrer information"
    ["Permissions-Policy"]="Controls browser features (camera, mic, etc.)"
  )

  local present=0 missing=0

  echo "### Header Analysis"
  for header in "Strict-Transport-Security" "Content-Security-Policy" "X-Content-Type-Options" "X-Frame-Options" "Referrer-Policy" "Permissions-Policy"; do
    local desc="${sec_headers[$header]}"
    local val
    val=$(grep -i "^${header}:" "$headers" | head -1 | sed "s/^${header}:\s*//i" | tr -d '\r')
    if [[ -n "$val" ]]; then
      echo "- **${header}:** \`${val:0:120}\` [COLLECTED]"
      present=$((present + 1))
    else
      echo "- **${header}:** MISSING — ${desc} [COLLECTED]"
      missing=$((missing + 1))
    fi
  done
  echo ""
  echo "**Score: ${present}/6 security headers present** [COLLECTED]"
  echo ""

  # Server information disclosure
  echo "### Server Information Disclosure"
  local server
  server=$(grep -i "^server:" "$headers" | head -1 | sed 's/^server:\s*//i' | tr -d '\r')
  local powered
  powered=$(grep -i "^x-powered-by:" "$headers" | head -1 | sed 's/^x-powered-by:\s*//i' | tr -d '\r')

  [[ -n "$server" ]] && echo "- Server: \`${server}\` [COLLECTED]" || echo "- Server header: hidden [COLLECTED]"
  [[ -n "$powered" ]] && echo "- X-Powered-By: \`${powered}\` (should be removed) [COLLECTED]" || echo "- X-Powered-By: hidden [COLLECTED]"
  echo ""
}

# ─── Collector 6: SSL Certificate ───────────────────────────────────────────

collect_ssl() {
  echo "## 6. SSL Certificate & HTTPS"
  echo ""

  # SSL certificate info
  local ssl_output
  ssl_output=$(echo | openssl s_client -servername "$DOMAIN" -connect "${DOMAIN}:443" 2>/dev/null)

  if [[ -n "$ssl_output" ]]; then
    # Issuer
    local issuer
    issuer=$(echo "$ssl_output" | openssl x509 -noout -issuer 2>/dev/null | sed 's/issuer=//')
    [[ -n "$issuer" ]] && echo "- **Issuer:** ${issuer} [COLLECTED]"

    # Expiry
    local expiry
    expiry=$(echo "$ssl_output" | openssl x509 -noout -enddate 2>/dev/null | sed 's/notAfter=//')
    if [[ -n "$expiry" ]]; then
      echo "- **Expires:** ${expiry} [COLLECTED]"
      # Check if expiring within 30 days
      local expiry_epoch now_epoch
      expiry_epoch=$(date -j -f "%b %d %T %Y %Z" "$expiry" +%s 2>/dev/null || date -d "$expiry" +%s 2>/dev/null || echo "0")
      now_epoch=$(date +%s)
      if [[ "$expiry_epoch" -gt 0 ]]; then
        local days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
        echo "- **Days until expiry:** ${days_left} [COLLECTED]"
        [[ $days_left -lt 30 ]] && echo "- **WARNING: Certificate expiring within 30 days!** [COLLECTED]"
      fi
    fi

    # Protocol
    local protocol
    protocol=$(echo "$ssl_output" | grep -oE 'Protocol\s*:\s*\S+' | head -1 | sed 's/Protocol\s*:\s*//')
    [[ -n "$protocol" ]] && echo "- **Protocol:** ${protocol} [COLLECTED]"

    # Subject
    local subject
    subject=$(echo "$ssl_output" | openssl x509 -noout -subject 2>/dev/null | sed 's/subject=//')
    [[ -n "$subject" ]] && echo "- **Subject:** ${subject} [COLLECTED]"
  else
    echo "- **SSL connection failed** — site may not support HTTPS [COLLECTED]"
  fi
  echo ""

  # HTTP → HTTPS redirect check
  echo "### HTTP to HTTPS Redirect"
  local http_status
  http_status=$(curl -sI --max-time 5 "http://${DOMAIN}" 2>/dev/null | head -5)
  if echo "$http_status" | grep -qiE '301|302|307|308'; then
    local redirect_target
    redirect_target=$(echo "$http_status" | grep -i "location:" | head -1 | sed 's/location:\s*//i' | tr -d '\r')
    if echo "$redirect_target" | grep -qi "https://"; then
      echo "- HTTP redirects to HTTPS [COLLECTED]"
    else
      echo "- HTTP redirects but NOT to HTTPS (target: ${redirect_target}) [COLLECTED]"
    fi
  else
    echo "- No HTTP to HTTPS redirect detected [COLLECTED]"
  fi
  echo ""
}

# ─── Collector 7: DNS & Email Authentication ────────────────────────────────

collect_dns_email() {
  echo "## 7. DNS & Email Authentication"
  echo ""

  # MX Records
  echo "### MX Records"
  local mx
  mx=$(dig +short MX "$DOMAIN" 2>/dev/null)
  if [[ -n "$mx" ]]; then
    echo "$mx" | while IFS= read -r record; do
      echo "- ${record} [COLLECTED]"
    done

    # Detect provider
    if echo "$mx" | grep -qi "google\|gmail\|googlemail"; then
      echo "- **Provider:** Google Workspace [COLLECTED]"
    elif echo "$mx" | grep -qi "outlook\|microsoft\|office365"; then
      echo "- **Provider:** Microsoft 365 [COLLECTED]"
    elif echo "$mx" | grep -qi "zoho"; then
      echo "- **Provider:** Zoho Mail [COLLECTED]"
    elif echo "$mx" | grep -qi "protonmail\|proton"; then
      echo "- **Provider:** ProtonMail [COLLECTED]"
    elif echo "$mx" | grep -qi "mimecast"; then
      echo "- **Provider:** Mimecast [COLLECTED]"
    elif echo "$mx" | grep -qi "barracuda"; then
      echo "- **Provider:** Barracuda [COLLECTED]"
    fi
  else
    echo "- No MX records found [COLLECTED]"
  fi
  echo ""

  # SPF
  echo "### SPF Record"
  local spf
  spf=$(dig +short TXT "$DOMAIN" 2>/dev/null | grep -i "v=spf1" | head -1)
  if [[ -n "$spf" ]]; then
    echo "- \`${spf}\` [COLLECTED]"
    echo "$spf" | grep -qi "~all" && echo "- Policy: soft fail (~all) — emails from unauthorized senders may still deliver [COLLECTED]"
    echo "$spf" | grep -qi "\-all" && echo "- Policy: hard fail (-all) — strict, best practice [COLLECTED]"
    echo "$spf" | grep -qi "?all" && echo "- Policy: neutral (?all) — weak, not recommended [COLLECTED]"
  else
    echo "- **No SPF record found** — email spoofing risk [COLLECTED]"
  fi
  echo ""

  # DMARC
  echo "### DMARC Record"
  local dmarc
  dmarc=$(dig +short TXT "_dmarc.${DOMAIN}" 2>/dev/null | head -1)
  if [[ -n "$dmarc" ]]; then
    echo "- \`${dmarc}\` [COLLECTED]"
    echo "$dmarc" | grep -qi "p=reject" && echo "- Policy: **reject** — strongest protection [COLLECTED]"
    echo "$dmarc" | grep -qi "p=quarantine" && echo "- Policy: **quarantine** — moderate protection [COLLECTED]"
    echo "$dmarc" | grep -qi "p=none" && echo "- Policy: **none** — monitoring only, no protection [COLLECTED]"
  else
    echo "- **No DMARC record found** — email authentication gap [COLLECTED]"
  fi
  echo ""

  # NS Records
  echo "### Name Servers"
  local ns
  ns=$(dig +short NS "$DOMAIN" 2>/dev/null)
  if [[ -n "$ns" ]]; then
    echo "$ns" | head -4 | while IFS= read -r record; do
      echo "- ${record} [COLLECTED]"
    done

    # Detect provider
    if echo "$ns" | grep -qi "cloudflare"; then
      echo "- **DNS Provider:** Cloudflare [COLLECTED]"
    elif echo "$ns" | grep -qi "awsdns\|amazonaws"; then
      echo "- **DNS Provider:** AWS Route 53 [COLLECTED]"
    elif echo "$ns" | grep -qi "google\|googledomains"; then
      echo "- **DNS Provider:** Google Cloud DNS [COLLECTED]"
    elif echo "$ns" | grep -qi "domaincontrol\|godaddy"; then
      echo "- **DNS Provider:** GoDaddy [COLLECTED]"
    elif echo "$ns" | grep -qi "namecheap\|registrar-servers"; then
      echo "- **DNS Provider:** Namecheap [COLLECTED]"
    elif echo "$ns" | grep -qi "digitalocean"; then
      echo "- **DNS Provider:** DigitalOcean [COLLECTED]"
    elif echo "$ns" | grep -qi "vercel"; then
      echo "- **DNS Provider:** Vercel DNS [COLLECTED]"
    fi
  else
    echo "- Could not resolve NS records [COLLECTED]"
  fi
  echo ""
}

# ─── Collector 8: PageSpeed / Core Web Vitals ───────────────────────────────

collect_pagespeed() {
  echo "## 8. PageSpeed & Core Web Vitals"
  echo ""

  local api_url="https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=${BASE_URL}&category=performance&category=seo&category=accessibility&category=best-practices&strategy=mobile"
  local psi_json="${TMP}/pagespeed.json"

  curl -sL --max-time 30 "$api_url" -o "$psi_json" 2>/dev/null

  if [[ ! -s "$psi_json" ]]; then
    echo "**PageSpeed API unavailable** — could not fetch Lighthouse scores [COLLECTED]"
    echo ""
    echo "Note: The PageSpeed Insights API is free and requires no API key for"
    echo "basic usage, but may rate-limit or be temporarily unavailable."
    return
  fi

  # Check if jq is available for clean parsing
  if command -v jq &>/dev/null; then
    # jq path — clean parsing
    local perf seo access bp
    perf=$(jq -r '.lighthouseResult.categories.performance.score // empty' "$psi_json" 2>/dev/null)
    seo=$(jq -r '.lighthouseResult.categories.seo.score // empty' "$psi_json" 2>/dev/null)
    access=$(jq -r '.lighthouseResult.categories.accessibility.score // empty' "$psi_json" 2>/dev/null)
    bp=$(jq -r '.lighthouseResult.categories["best-practices"].score // empty' "$psi_json" 2>/dev/null)

    echo "### Lighthouse Scores (Mobile)"
    [[ -n "$perf" ]] && echo "- **Performance:** $(echo "$perf * 100" | bc | cut -d. -f1)/100 [COLLECTED]"
    [[ -n "$seo" ]] && echo "- **SEO:** $(echo "$seo * 100" | bc | cut -d. -f1)/100 [COLLECTED]"
    [[ -n "$access" ]] && echo "- **Accessibility:** $(echo "$access * 100" | bc | cut -d. -f1)/100 [COLLECTED]"
    [[ -n "$bp" ]] && echo "- **Best Practices:** $(echo "$bp * 100" | bc | cut -d. -f1)/100 [COLLECTED]"
    echo ""

    # Core Web Vitals from field data (CrUX)
    echo "### Core Web Vitals (Field Data)"
    local lcp fid cls inp
    lcp=$(jq -r '.loadingExperience.metrics.LARGEST_CONTENTFUL_PAINT_MS.percentile // empty' "$psi_json" 2>/dev/null)
    fid=$(jq -r '.loadingExperience.metrics.FIRST_INPUT_DELAY_MS.percentile // empty' "$psi_json" 2>/dev/null)
    cls=$(jq -r '.loadingExperience.metrics.CUMULATIVE_LAYOUT_SHIFT_SCORE.percentile // empty' "$psi_json" 2>/dev/null)
    inp=$(jq -r '.loadingExperience.metrics.INTERACTION_TO_NEXT_PAINT.percentile // empty' "$psi_json" 2>/dev/null)

    local has_field=0
    [[ -n "$lcp" ]] && echo "- **LCP:** ${lcp}ms $([ "$lcp" -le 2500 ] && echo '(good)' || echo '(needs improvement)') [COLLECTED]" && has_field=1
    [[ -n "$fid" ]] && echo "- **FID:** ${fid}ms $([ "$fid" -le 100 ] && echo '(good)' || echo '(needs improvement)') [COLLECTED]" && has_field=1
    [[ -n "$inp" ]] && echo "- **INP:** ${inp}ms $([ "$inp" -le 200 ] && echo '(good)' || echo '(needs improvement)') [COLLECTED]" && has_field=1
    [[ -n "$cls" ]] && echo "- **CLS:** $(echo "scale=2; $cls / 100" | bc) $([ "$cls" -le 10 ] && echo '(good)' || echo '(needs improvement)') [COLLECTED]" && has_field=1

    [[ $has_field -eq 0 ]] && echo "- No CrUX field data available (site may have insufficient traffic) [COLLECTED]"
    echo ""

    # Lab metrics
    echo "### Lab Metrics"
    local fcp si tbt
    fcp=$(jq -r '.lighthouseResult.audits["first-contentful-paint"].displayValue // empty' "$psi_json" 2>/dev/null)
    si=$(jq -r '.lighthouseResult.audits["speed-index"].displayValue // empty' "$psi_json" 2>/dev/null)
    tbt=$(jq -r '.lighthouseResult.audits["total-blocking-time"].displayValue // empty' "$psi_json" 2>/dev/null)

    [[ -n "$fcp" ]] && echo "- **FCP:** ${fcp} [COLLECTED]"
    [[ -n "$si" ]] && echo "- **Speed Index:** ${si} [COLLECTED]"
    [[ -n "$tbt" ]] && echo "- **TBT:** ${tbt} [COLLECTED]"
    echo ""

  else
    # Fallback: grep-based parsing (no jq)
    echo "### Lighthouse Scores (Mobile) — parsed without jq"

    local perf_score
    perf_score=$(grep -oE '"performance":\{"id":"performance","title":"Performance","score":[0-9.]+' "$psi_json" | grep -oE 'score:[0-9.]+' | cut -d: -f2)
    [[ -n "$perf_score" ]] && echo "- **Performance:** $(echo "$perf_score * 100" | bc 2>/dev/null || echo "$perf_score")/100 [COLLECTED]"

    local seo_score
    seo_score=$(grep -oE '"seo":\{"id":"seo","title":"SEO","score":[0-9.]+' "$psi_json" | grep -oE 'score:[0-9.]+' | cut -d: -f2)
    [[ -n "$seo_score" ]] && echo "- **SEO:** $(echo "$seo_score * 100" | bc 2>/dev/null || echo "$seo_score")/100 [COLLECTED]"

    echo ""
    echo "Install \`jq\` for detailed Core Web Vitals parsing: \`brew install jq\`"
    echo ""
  fi
}

# ─── Collector 9: Cookies ───────────────────────────────────────────────────

collect_cookies() {
  local headers="${TMP}/response-headers.txt"
  [[ ! -s "$headers" ]] && echo "**Cookies: No response headers available**" && return

  echo "## 9. Cookies"
  echo ""

  # Parse Set-Cookie headers
  local cookies
  cookies=$(grep -i "^set-cookie:" "$headers" | sed 's/^set-cookie:\s*//i')

  if [[ -z "$cookies" ]]; then
    echo "No cookies set on initial page load [COLLECTED]"
    echo ""
    echo "Note: Cookies may be set by JavaScript after page load (e.g., GA4,"
    echo "consent tools). This collector only sees server-set cookies."
    return
  fi

  local cookie_count
  cookie_count=$(echo "$cookies" | wc -l | tr -d ' ')
  echo "**${cookie_count} cookies set on initial page load** [COLLECTED]"
  echo ""

  echo "### Cookie Details"
  echo "$cookies" | while IFS= read -r cookie; do
    local name value flags
    name=$(echo "$cookie" | cut -d= -f1 | tr -d ' ')
    flags=$(echo "$cookie" | tr ';' '\n' | tail -n +2 | tr '\n' '; ' | sed 's/; $//')

    # Categorize
    local category="other"
    case "$name" in
      _ga*|_gid|_gat|__utm*) category="analytics (Google)" ;;
      _fbp|_fbc|fr) category="marketing (Meta)" ;;
      _gcl*) category="marketing (Google Ads)" ;;
      _pin*) category="marketing (Pinterest)" ;;
      _tt_*|tt_*) category="marketing (TikTok)" ;;
      *consent*|*cookie*|*gdpr*|*ccpa*) category="consent" ;;
      *session*|*sess*|*sid*|PHPSESSID|connect.sid) category="session" ;;
      __cf*|cf_*) category="infrastructure (Cloudflare)" ;;
      __stripe*) category="payment (Stripe)" ;;
      _shopify*|cart*) category="e-commerce (Shopify)" ;;
    esac

    # Check security flags
    local secure="" httponly="" samesite=""
    echo "$flags" | grep -qi "secure" && secure="Secure"
    echo "$flags" | grep -qi "httponly" && httponly="HttpOnly"
    samesite=$(echo "$flags" | grep -oiE 'samesite=[a-z]+' | head -1)

    echo "- **\`${name}\`** — ${category} [COLLECTED]"
    echo "  - Flags: ${secure:-no-Secure} ${httponly:-no-HttpOnly} ${samesite:-no-SameSite}"
  done
  echo ""

  # Summary
  echo "### Cookie Summary"
  local analytics_count marketing_count consent_count session_count
  analytics_count=$(echo "$cookies" | grep -ciE '_ga|_gid|_gat|__utm' || echo "0")
  marketing_count=$(echo "$cookies" | grep -ciE '_fbp|_fbc|_gcl|_pin|_tt_' || echo "0")
  consent_count=$(echo "$cookies" | grep -ciE 'consent|cookie|gdpr|ccpa' || echo "0")
  echo "- Analytics cookies: ${analytics_count} [COLLECTED]"
  echo "- Marketing cookies: ${marketing_count} [COLLECTED]"
  echo "- Consent cookies: ${consent_count} [COLLECTED]"
  echo "- Total cookies: ${cookie_count} [COLLECTED]"
  echo ""
}

# ─── Collector 10: robots.txt & Sitemap ─────────────────────────────────────

collect_robots_sitemap() {
  echo "## 10. robots.txt & Sitemap"
  echo ""

  # robots.txt
  echo "### robots.txt"
  local robots
  robots=$(curl -sL --max-time 10 "${BASE_URL}/robots.txt" 2>/dev/null)

  if [[ -n "$robots" ]] && ! echo "$robots" | head -1 | grep -qiE '<html|<!DOCTYPE|404|not found'; then
    echo "robots.txt found [COLLECTED]"
    echo ""

    # Disallow rules
    local disallow_count
    disallow_count=$(echo "$robots" | grep -ciE '^Disallow:' || echo "0")
    echo "- Disallow rules: ${disallow_count} [COLLECTED]"

    echo "$robots" | grep -iE '^Disallow:' | head -10 | while IFS= read -r rule; do
      echo "  - \`${rule}\` [COLLECTED]"
    done

    # Allow rules
    local allow_count
    allow_count=$(echo "$robots" | grep -ciE '^Allow:' || echo "0")
    [[ "$allow_count" -gt 0 ]] && echo "- Allow rules: ${allow_count} [COLLECTED]"

    # Crawl-delay
    local crawl_delay
    crawl_delay=$(echo "$robots" | grep -iE '^Crawl-delay:' | head -1)
    [[ -n "$crawl_delay" ]] && echo "- ${crawl_delay} [COLLECTED]"

    # Sitemap references in robots.txt
    local sitemap_refs
    sitemap_refs=$(echo "$robots" | grep -iE '^Sitemap:' | sed 's/Sitemap:\s*//i')
    if [[ -n "$sitemap_refs" ]]; then
      echo ""
      echo "Sitemaps declared in robots.txt:"
      echo "$sitemap_refs" | while IFS= read -r sm; do
        echo "- \`${sm}\` [COLLECTED]"
      done
    fi
  else
    echo "**No robots.txt found or returned HTML** [COLLECTED]"
  fi
  echo ""

  # Sitemap
  echo "### Sitemap"
  local sitemap_url="${BASE_URL}/sitemap.xml"
  # Use sitemap from robots.txt if available
  if [[ -n "${sitemap_refs:-}" ]]; then
    sitemap_url=$(echo "$sitemap_refs" | head -1 | tr -d ' \r')
  fi

  local sitemap
  sitemap=$(curl -sL --max-time 10 "$sitemap_url" 2>/dev/null)

  if [[ -n "$sitemap" ]] && echo "$sitemap" | grep -qiE '<urlset\|<sitemapindex'; then
    # Is it a sitemap index?
    if echo "$sitemap" | grep -qi '<sitemapindex'; then
      local index_count
      index_count=$(echo "$sitemap" | grep -c '<sitemap>' || echo "0")
      echo "- **Sitemap index found** with ${index_count} child sitemaps [COLLECTED]"

      echo "$sitemap" | grep -oE '<loc>[^<]*</loc>' | sed 's/<[^>]*>//g' | head -5 | while IFS= read -r loc; do
        echo "  - \`${loc}\` [COLLECTED]"
      done
    else
      local url_count
      url_count=$(echo "$sitemap" | grep -c '<url>' || echo "0")
      echo "- **Sitemap found** with ${url_count} URLs [COLLECTED]"
    fi

    # Last modified dates
    local lastmod
    lastmod=$(echo "$sitemap" | grep -oE '<lastmod>[^<]*</lastmod>' | sed 's/<[^>]*>//g' | sort -r | head -1)
    [[ -n "$lastmod" ]] && echo "- Most recent lastmod: ${lastmod} [COLLECTED]"

    # Check for common sub-sitemaps
    local has_images has_video has_news
    echo "$sitemap" | grep -qi 'image:image' && echo "- Image sitemap entries present [COLLECTED]"
    echo "$sitemap" | grep -qi 'video:video' && echo "- Video sitemap entries present [COLLECTED]"
    echo "$sitemap" | grep -qi 'news:news' && echo "- News sitemap entries present [COLLECTED]"
  else
    echo "- **No sitemap.xml found** at ${sitemap_url} [COLLECTED]"
  fi
  echo ""
}

# ─── Run All Collectors ─────────────────────────────────────────────────────

{
  echo "# Collector Data: ${DOMAIN}"
  echo "Collected: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "Source: bash collectors.sh (raw HTML + headers + DNS + API)"
  echo ""
  echo "---"
  echo ""
  echo "This data supplements crawl-data.md with technical details that"
  echo "WebFetch strips: raw HTML tags, response headers, SSL certificates,"
  echo "DNS records, PageSpeed scores, cookies, and robots/sitemap data."
  echo ""
  echo "Every finding is tagged \`[COLLECTED]\` — use this tag in your report"
  echo "to distinguish collector data from crawl observations."
  echo ""
  echo "---"
  echo ""
} > "$OUTPUT"

run_collector "Technology Stack" collect_tech_stack
run_collector "Structured Data" collect_structured_data
run_collector "HTML Structure" collect_html_structure
run_collector "Social Links" collect_social_links
run_collector "Security Headers" collect_security_headers
run_collector "SSL Certificate" collect_ssl
run_collector "DNS & Email Auth" collect_dns_email
run_collector "PageSpeed" collect_pagespeed
run_collector "Cookies" collect_cookies
run_collector "robots.txt & Sitemap" collect_robots_sitemap

# Write results
for result in "${COLLECTOR_RESULTS[@]}"; do
  echo "$result" >> "$OUTPUT"
  echo "" >> "$OUTPUT"
  echo "---" >> "$OUTPUT"
  echo "" >> "$OUTPUT"
done

# Summary footer
TOTAL_END=$(date +%s)
TOTAL_DURATION=$((TOTAL_END - TOTAL_START))
LINE_COUNT=$(wc -l < "$OUTPUT" | tr -d ' ')

{
  echo "---"
  echo ""
  echo "## Collection Summary"
  echo "- Domain: ${DOMAIN}"
  echo "- Collectors run: 10"
  echo "- Total time: ${TOTAL_DURATION}s"
  echo "- Output lines: ${LINE_COUNT}"
  echo "- File: ${OUTPUT}"
} >> "$OUTPUT"

echo "[collectors] Complete! ${LINE_COUNT} lines written to ${OUTPUT} (${TOTAL_DURATION}s)"

# Cleanup
rm -rf "$TMP"
