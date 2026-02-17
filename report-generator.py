#!/usr/bin/env python3
"""Marketing Orchestrator — Professional PDF Report Generator

Reads all agent reports, context, brand DNA, CMO review, and the synthesis
report, then generates a professional HTML document and converts it to PDF
via Chrome headless.

Usage: python3 report-generator.py /tmp/marketing-audit-example.com

Output:
  /tmp/marketing-audit-example.com/FULL-REPORT.html
  /tmp/marketing-audit-example.com/FULL-REPORT.pdf

Dependencies: Python 3.8+ (stdlib only), Google Chrome
"""

import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path


# ---------------------------------------------------------------------------
# Lightweight Markdown → HTML converter (stdlib only)
# ---------------------------------------------------------------------------

def md_to_html(md_text: str) -> str:
    """Convert markdown text to HTML. Handles the subset we actually use."""
    lines = md_text.split("\n")
    html_parts: list[str] = []
    in_table = False
    in_code = False
    in_list = False
    list_type = None  # "ul" or "ol"
    in_paragraph = False
    buffer: list[str] = []

    def flush_paragraph():
        nonlocal in_paragraph, buffer
        if in_paragraph and buffer:
            html_parts.append("<p>" + " ".join(buffer) + "</p>")
            buffer = []
            in_paragraph = False

    def flush_list():
        nonlocal in_list, list_type
        if in_list:
            html_parts.append(f"</{list_type}>")
            in_list = False
            list_type = None

    def inline_format(text: str) -> str:
        """Handle inline formatting: bold, italic, code, links."""
        # Code spans first (so bold/italic inside code aren't processed)
        text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
        # Bold + italic
        text = re.sub(r"\*\*\*(.+?)\*\*\*", r"<strong><em>\1</em></strong>", text)
        # Bold
        text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
        # Italic
        text = re.sub(r"\*(.+?)\*", r"<em>\1</em>", text)
        # Links
        text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', text)
        return text

    for line in lines:
        # Code blocks
        if line.strip().startswith("```"):
            if in_code:
                html_parts.append("</code></pre>")
                in_code = False
            else:
                flush_paragraph()
                flush_list()
                lang = line.strip()[3:].strip()
                cls = f' class="language-{lang}"' if lang else ""
                html_parts.append(f"<pre><code{cls}>")
                in_code = True
            continue

        if in_code:
            html_parts.append(line.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))
            continue

        stripped = line.strip()

        # Horizontal rule
        if stripped in ("---", "***", "___") and not in_table:
            flush_paragraph()
            flush_list()
            html_parts.append("<hr>")
            continue

        # Headers
        header_match = re.match(r"^(#{1,6})\s+(.+)$", stripped)
        if header_match:
            flush_paragraph()
            flush_list()
            level = len(header_match.group(1))
            text = inline_format(header_match.group(2))
            slug = re.sub(r"[^a-z0-9]+", "-", text.lower().replace("<strong>", "").replace("</strong>", "").replace("<em>", "").replace("</em>", ""))
            slug = re.sub(r"<[^>]+>", "", slug).strip("-")
            html_parts.append(f'<h{level} id="{slug}">{text}</h{level}>')
            continue

        # Table rows
        if "|" in stripped and stripped.startswith("|"):
            flush_paragraph()
            flush_list()
            # Check if separator row
            cells = [c.strip() for c in stripped.split("|")[1:-1]]
            if all(re.match(r"^[-:]+$", c) for c in cells if c):
                continue  # Skip separator row

            if not in_table:
                html_parts.append('<div class="table-wrapper"><table>')
                in_table = True
                # First row = header
                html_parts.append("<thead><tr>")
                for cell in cells:
                    html_parts.append(f"<th>{inline_format(cell)}</th>")
                html_parts.append("</tr></thead><tbody>")
                continue

            html_parts.append("<tr>")
            for cell in cells:
                html_parts.append(f"<td>{inline_format(cell)}</td>")
            html_parts.append("</tr>")
            continue

        if in_table and "|" not in stripped:
            html_parts.append("</tbody></table></div>")
            in_table = False

        # Unordered list
        ul_match = re.match(r"^[-*+]\s+(.+)$", stripped)
        if ul_match:
            flush_paragraph()
            if not in_list or list_type != "ul":
                flush_list()
                html_parts.append("<ul>")
                in_list = True
                list_type = "ul"
            html_parts.append(f"<li>{inline_format(ul_match.group(1))}</li>")
            continue

        # Ordered list
        ol_match = re.match(r"^\d+\.\s+(.+)$", stripped)
        if ol_match:
            flush_paragraph()
            if not in_list or list_type != "ol":
                flush_list()
                html_parts.append("<ol>")
                in_list = True
                list_type = "ol"
            html_parts.append(f"<li>{inline_format(ol_match.group(1))}</li>")
            continue

        # End list if not a list item
        if in_list and stripped:
            flush_list()

        # Empty line
        if not stripped:
            flush_paragraph()
            continue

        # Regular paragraph text
        if not in_paragraph:
            in_paragraph = True
            buffer = []
        buffer.append(inline_format(stripped))

    # Flush remaining state
    flush_paragraph()
    flush_list()
    if in_table:
        html_parts.append("</tbody></table></div>")
    if in_code:
        html_parts.append("</code></pre>")

    return "\n".join(html_parts)


# ---------------------------------------------------------------------------
# CSS Stylesheet — professional, print-optimized, lightweight
# ---------------------------------------------------------------------------

CSS = """
:root {
    --primary: #1a365d;
    --primary-light: #2a4a7f;
    --accent: #e63946;
    --success: #2d6a4f;
    --warning: #f77f00;
    --bg: #ffffff;
    --text: #1a1a2e;
    --text-light: #4a5568;
    --border: #e2e8f0;
    --border-dark: #cbd5e0;
    --bg-light: #f7fafc;
    --bg-accent: #ebf4ff;
}

@page {
    size: A4;
    margin: 2cm 2.2cm 2.5cm 2.2cm;
}

@page :first {
    margin-top: 0;
}

* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
    font-size: 10.5pt;
    line-height: 1.6;
    color: var(--text);
    background: var(--bg);
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
}

/* ---- Cover Page ---- */
.cover-page {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    text-align: center;
    page-break-after: always;
    background: var(--primary);
    color: white;
    margin: -2cm -2.2cm 0 -2.2cm;
    padding: 3cm 2.5cm;
}

.cover-page h1 {
    font-size: 32pt;
    font-weight: 700;
    letter-spacing: -0.5pt;
    margin-bottom: 0.3em;
    border: none;
    color: white;
}

.cover-page .subtitle {
    font-size: 16pt;
    font-weight: 300;
    opacity: 0.9;
    margin-bottom: 2em;
}

.cover-page .meta-table {
    background: rgba(255,255,255,0.1);
    border-radius: 8px;
    padding: 1.5em 2.5em;
    text-align: left;
    font-size: 11pt;
    line-height: 2;
}

.cover-page .meta-table strong {
    color: rgba(255,255,255,0.7);
    display: inline-block;
    width: 140px;
    font-weight: 400;
}

.cover-page .maturity-score {
    margin-top: 2em;
    font-size: 56pt;
    font-weight: 800;
    letter-spacing: -2pt;
}

.cover-page .maturity-label {
    font-size: 12pt;
    text-transform: uppercase;
    letter-spacing: 3pt;
    opacity: 0.8;
    margin-top: 0.2em;
}

.cover-page .generated-by {
    margin-top: 3em;
    font-size: 9pt;
    opacity: 0.5;
}

/* ---- Table of Contents ---- */
.toc {
    page-break-after: always;
    padding-top: 1cm;
}

.toc h2 {
    font-size: 20pt;
    color: var(--primary);
    border-bottom: 3px solid var(--primary);
    padding-bottom: 0.3em;
    margin-bottom: 1em;
}

.toc-section {
    margin-bottom: 1.5em;
}

.toc-section-title {
    font-size: 10pt;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1.5pt;
    color: var(--primary);
    margin-bottom: 0.4em;
    padding-bottom: 0.2em;
    border-bottom: 1px solid var(--border);
}

.toc-item {
    display: flex;
    align-items: baseline;
    padding: 0.25em 0;
    font-size: 10.5pt;
    text-decoration: none;
    color: var(--text);
}

.toc-item:hover {
    color: var(--primary);
}

.toc-item .toc-num {
    color: var(--primary);
    font-weight: 700;
    min-width: 2em;
}

.toc-item .toc-label {
    flex: 1;
}

.toc-item .toc-dots {
    flex: 1;
    border-bottom: 1px dotted var(--border-dark);
    margin: 0 0.5em;
    min-width: 2em;
}

/* ---- Main Content ---- */
.content {
    padding-top: 0.5cm;
}

h1 {
    font-size: 22pt;
    color: var(--primary);
    border-bottom: 3px solid var(--primary);
    padding-bottom: 0.3em;
    margin: 0 0 0.8em 0;
}

h2 {
    font-size: 16pt;
    color: var(--primary);
    border-bottom: 2px solid var(--border);
    padding-bottom: 0.2em;
    margin: 1.5em 0 0.6em 0;
}

h3 {
    font-size: 13pt;
    color: var(--primary-light);
    margin: 1.2em 0 0.4em 0;
}

h4 {
    font-size: 11pt;
    color: var(--text);
    margin: 1em 0 0.3em 0;
}

p {
    margin: 0.5em 0;
}

strong {
    color: var(--text);
}

a {
    color: var(--primary);
    text-decoration: none;
}

hr {
    border: none;
    border-top: 1px solid var(--border);
    margin: 1.5em 0;
}

/* ---- Tables ---- */
.table-wrapper {
    overflow-x: auto;
    margin: 0.8em 0;
}

table {
    width: 100%;
    border-collapse: collapse;
    font-size: 9.5pt;
    line-height: 1.4;
}

thead {
    background: var(--primary);
    color: white;
}

th {
    padding: 0.5em 0.7em;
    text-align: left;
    font-weight: 600;
    font-size: 9pt;
    text-transform: uppercase;
    letter-spacing: 0.5pt;
    white-space: nowrap;
}

td {
    padding: 0.45em 0.7em;
    border-bottom: 1px solid var(--border);
    vertical-align: top;
}

tbody tr:nth-child(even) {
    background: #f9fafb;
}

/* ---- Lists ---- */
ul, ol {
    margin: 0.4em 0 0.4em 1.5em;
}

li {
    margin: 0.2em 0;
}

/* ---- Code ---- */
code {
    font-family: 'SF Mono', 'Fira Code', Consolas, monospace;
    font-size: 9pt;
    background: var(--bg-light);
    padding: 0.15em 0.4em;
    border-radius: 3px;
    border: 1px solid var(--border);
}

pre {
    background: #1e293b;
    color: #e2e8f0;
    padding: 1em 1.2em;
    border-radius: 6px;
    overflow-x: auto;
    font-size: 9pt;
    line-height: 1.5;
    margin: 0.8em 0;
}

pre code {
    background: none;
    border: none;
    padding: 0;
    color: inherit;
}

/* ---- Chapter breaks ---- */
.chapter {
    page-break-before: always;
    padding-top: 0.5cm;
}

.chapter:first-of-type {
    page-break-before: avoid;
}

.chapter-header {
    background: var(--bg-light);
    border-left: 4px solid var(--primary);
    padding: 0.8em 1.2em;
    margin-bottom: 1.2em;
}

.chapter-header h2 {
    border: none;
    margin: 0;
    padding: 0;
    font-size: 18pt;
}

.chapter-header .chapter-meta {
    font-size: 9pt;
    color: var(--text-light);
    margin-top: 0.3em;
}

/* ---- Score badges ---- */
.score-badge {
    display: inline-block;
    padding: 0.15em 0.6em;
    border-radius: 4px;
    font-weight: 700;
    font-size: 9pt;
    color: white;
}

.score-high { background: var(--success); }
.score-mid { background: var(--warning); }
.score-low { background: var(--accent); }

.grade-A, .grade-B { color: var(--success); font-weight: 700; }
.grade-C { color: var(--warning); font-weight: 700; }
.grade-D, .grade-F { color: var(--accent); font-weight: 700; }

/* ---- Alert boxes ---- */
.alert {
    padding: 0.8em 1em;
    border-radius: 6px;
    margin: 0.8em 0;
    font-size: 10pt;
}

.alert-critical {
    background: #fff5f5;
    border-left: 4px solid var(--accent);
}

.alert-info {
    background: var(--bg-accent);
    border-left: 4px solid var(--primary);
}

.alert-success {
    background: #f0fff4;
    border-left: 4px solid var(--success);
}

/* ---- Quality Gate ---- */
.gate-pass {
    color: var(--success);
    font-weight: 700;
}

.gate-fail {
    color: var(--accent);
    font-weight: 700;
}

/* ---- Page footer (rendered in HTML since Chrome headless ignores @page) ---- */
.page-footer {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    text-align: center;
    font-size: 8pt;
    color: #a0aec0;
    padding: 0.5em 0;
}

/* ---- Print-specific ---- */
@media print {
    body { font-size: 10pt; }

    .cover-page {
        margin: -2cm -2.2cm 0 -2.2cm;
    }

    h1, h2, h3, h4 {
        page-break-after: avoid;
    }

    table, pre, .alert {
        page-break-inside: avoid;
    }

    .chapter {
        page-break-before: always;
    }

    a[href]:after {
        content: none;
    }
}
"""


# ---------------------------------------------------------------------------
# Report Builder
# ---------------------------------------------------------------------------

class ReportBuilder:
    """Builds the full HTML report from audit directory contents."""

    def __init__(self, audit_dir: str):
        self.d = Path(audit_dir)
        self.domain = self.d.name.replace("marketing-audit-", "")
        self.agents: list[dict] = []
        self.context: dict = {}
        self.brand_dna: str = ""
        self.synthesis: str = ""
        self.cmo_review: str = ""
        self.maturity_score: int = 0

    def load(self):
        """Load all data from the audit directory."""
        self._load_context()
        self._load_brand_dna()
        self._load_agents()
        self._load_synthesis()
        self._load_cmo_review()

    def _load_context(self):
        p = self.d / "context.md"
        if not p.exists():
            return
        text = p.read_text()
        for line in text.splitlines():
            m = re.match(r"^-\s+(.+?):\s+(.+)$", line)
            if m:
                key = m.group(1).strip().lower()
                self.context[key] = m.group(2).strip()

    def _load_brand_dna(self):
        p = self.d / "brand-dna.md"
        if p.exists():
            self.brand_dna = p.read_text()

    def _load_agents(self):
        agents_dir = self.d / "agents"
        if not agents_dir.exists():
            return
        for f in sorted(agents_dir.glob("*.md")):
            text = f.read_text()
            score_match = re.search(r"##\s*Score:\s*(\d+)\s*/\s*(\d+)", text)
            score = int(score_match.group(1)) if score_match else None
            max_score = int(score_match.group(2)) if score_match else None
            self.agents.append({
                "name": f.stem,
                "title": f.stem.replace("-", " ").title(),
                "score": score,
                "max_score": max_score,
                "content": text,
                "size_kb": f.stat().st_size / 1024,
            })

    def _load_synthesis(self):
        p = self.d / "FULL-REPORT.md"
        if p.exists():
            self.synthesis = p.read_text()
            # Try multiple formats for maturity score
            for pattern in [
                r"Overall Maturity Score:\s*(\d+)/100",
                r"Marketing Maturity Score:\s*(\d+)/100",
                r"maturity.*?(\d+)/100",
                r"\*\*(\d+)/100 overall maturity",
                r"scores a \*\*(\d+)/100",
            ]:
                m = re.search(pattern, self.synthesis, re.IGNORECASE)
                if m:
                    self.maturity_score = int(m.group(1))
                    break

    def _load_cmo_review(self):
        p = self.d / "review" / "cmo-review.md"
        if p.exists():
            self.cmo_review = p.read_text()

    # ------- HTML Generation -------

    def build_html(self) -> str:
        parts = [
            "<!DOCTYPE html>",
            '<html lang="en">',
            "<head>",
            '<meta charset="UTF-8">',
            '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
            f"<title>Marketing Audit: {self._business_name()}</title>",
            f"<style>{CSS}</style>",
            "</head>",
            "<body>",
            self._cover_page(),
            self._methodology_section(),
            self._table_of_contents(),
            '<div class="content">',
            self._exec_summary_section(),
            self._score_breakdown_section(),
            self._quick_wins_section(),
            self._critical_issues_section(),
            self._roadmap_section(),
            self._agent_deepdives(),
            self._quality_gate_section(),
            self._competitive_section(),
            self._scoring_methodology_section(),
            self._audit_log_section(),
            "</div>",
            '<div class="page-footer">Confidential</div>',
            "</body>",
            "</html>",
        ]
        return "\n".join(parts)

    def _business_name(self) -> str:
        return self.context.get("business", self.domain)

    def _cover_page(self) -> str:
        biz = self._business_name()
        url = self.context.get("url", self.domain)
        btype = self.context.get("type", "")
        industry = self.context.get("industry", "")
        now = datetime.now().strftime("%B %d, %Y")
        agent_count = len(self.agents)

        grade = self._score_grade(self.maturity_score)

        return f"""
<div class="cover-page">
    <h1>Marketing Audit</h1>
    <div class="subtitle">{biz}</div>
    <div class="meta-table">
        <strong>URL</strong> {url}<br>
        <strong>Business Type</strong> {btype}<br>
        <strong>Industry</strong> {industry}<br>
        <strong>Date</strong> {now}<br>
        <strong>Specialists</strong> {agent_count} agents deployed<br>
    </div>
    <div class="maturity-score">{self.maturity_score}<span style="font-size:24pt;opacity:0.7">/100</span></div>
    <div class="maturity-label">Marketing Maturity Score &mdash; Grade {grade}</div>
    <div class="generated-by">Generated by Marketing Orchestrator &mdash; AI-Powered Multi-Agent Audit</div>
</div>"""

    def _score_grade(self, score: int) -> str:
        if score >= 80: return "A"
        if score >= 65: return "B"
        if score >= 45: return "C"
        if score >= 25: return "D"
        return "F"

    def _methodology_section(self) -> str:
        """Add methodology and limitations page right after cover."""
        content = self._extract_section("Audit Methodology")
        if not content:
            now = datetime.now().strftime("%B %d, %Y")
            agent_count = len(self.agents)
            content = f"""
<div class="chapter">
<div class="alert alert-info">
<strong>About This Audit</strong><br>
This is an automated external assessment conducted on {now} using {agent_count} specialist AI agents.
It evaluates marketing infrastructure maturity based on publicly available data — site crawl content,
search results, and industry benchmarks.<br><br>
<strong>What this audit did NOT have access to:</strong> analytics data, conversion rates, revenue by channel,
customer data, internal business metrics, or user research.<br><br>
<strong>Revenue estimates are modeled, not measured.</strong> They should be validated with internal data before
being used for budgeting or planning decisions. All estimates include confidence levels (HIGH/MEDIUM/LOW)
indicating the reliability of the underlying data.
</div>
</div>"""
        else:
            content = f'<div class="chapter">\n{md_to_html(content)}\n</div>'
        return content

    def _scoring_methodology_section(self) -> str:
        """Add scoring methodology appendix."""
        content = self._extract_section("Scoring Methodology")
        if not content:
            content = """
<div class="chapter" id="scoring-methodology">
<h2>Appendix: Scoring Methodology</h2>
<h3>How Individual Area Scores Work</h3>
<table>
<thead><tr><th>Score Range</th><th>Meaning</th><th>Description</th></tr></thead>
<tbody>
<tr><td>0-15</td><td>Not Implemented</td><td>The capability does not exist. This is different from "broken."</td></tr>
<tr><td>16-35</td><td>Partially Implemented</td><td>Exists but has fundamental gaps or is actively broken.</td></tr>
<tr><td>36-55</td><td>Functional with Gaps</td><td>Working but missing significant optimization opportunities.</td></tr>
<tr><td>56-75</td><td>Solid Implementation</td><td>Well-executed with room for optimization.</td></tr>
<tr><td>76-100</td><td>Best-in-Class</td><td>Industry-leading execution in this area.</td></tr>
</tbody>
</table>
<h3>Overall Maturity Score</h3>
<p>The overall score uses weighted averaging. Core operational areas (SEO, CRO, Analytics, Email, Checkout)
are weighted 2x because they affect all traffic and revenue. Growth and advanced areas (Referral, Programmatic SEO,
GEO, Social Commerce) are weighted 1x because they represent incremental channels.</p>
<p><strong>Important:</strong> A low maturity score does NOT mean the business is failing. It means the marketing
<em>infrastructure</em> has room for improvement. A business with strong product-market fit, brand loyalty, and
organic demand can be highly successful despite low infrastructure scores.</p>
<h3>Confidence Levels</h3>
<table>
<thead><tr><th>Level</th><th>Meaning</th><th>When Applied</th></tr></thead>
<tbody>
<tr><td><strong>HIGH</strong></td><td>Directly verified</td><td>Observed in crawl data or confirmed via multiple independent sources</td></tr>
<tr><td><strong>MEDIUM</strong></td><td>Reasonably supported</td><td>Based on industry benchmarks applied to estimated business metrics</td></tr>
<tr><td><strong>LOW</strong></td><td>Directional only</td><td>General patterns with no business-specific data; verify before acting</td></tr>
</tbody>
</table>
</div>"""
        else:
            content = f'<div class="chapter" id="scoring-methodology">\n{md_to_html(content)}\n</div>'
        return content

    def _table_of_contents(self) -> str:
        toc = ['<div class="toc">', "<h2>Table of Contents</h2>"]

        # Part 1: Executive Overview
        toc.append('<div class="toc-section">')
        toc.append('<div class="toc-section-title">Part I &mdash; Executive Overview</div>')
        items = [
            ("1", "Executive Summary"),
            ("2", "Score Breakdown"),
            ("3", "Top Quick Wins"),
            ("4", "Critical Issues"),
            ("5", "90-Day Roadmap"),
        ]
        for num, label in items:
            slug = re.sub(r"[^a-z0-9]+", "-", label.lower()).strip("-")
            toc.append(f'<a class="toc-item" href="#{slug}"><span class="toc-num">{num}</span><span class="toc-label">{label}</span><span class="toc-dots"></span></a>')
        toc.append("</div>")

        # Part 2: Agent Deep-Dives
        toc.append('<div class="toc-section">')
        toc.append('<div class="toc-section-title">Part II &mdash; Specialist Deep-Dives</div>')
        for i, agent in enumerate(self.agents, 6):
            slug = f"agent-{agent['name']}"
            score_text = f" ({agent['score']}/{agent['max_score']})" if agent['score'] is not None else ""
            toc.append(f'<a class="toc-item" href="#{slug}"><span class="toc-num">{i}</span><span class="toc-label">{agent["title"]}{score_text}</span><span class="toc-dots"></span></a>')
        toc.append("</div>")

        # Part 3: Appendix
        next_num = 6 + len(self.agents)
        toc.append('<div class="toc-section">')
        toc.append('<div class="toc-section-title">Part III &mdash; Appendix</div>')
        appendix_items = [
            ("Quality Gate Results",),
            ("Competitive Position",),
            ("Audit Log",),
        ]
        for j, (label,) in enumerate(appendix_items, next_num):
            slug = re.sub(r"[^a-z0-9]+", "-", label.lower()).strip("-")
            toc.append(f'<a class="toc-item" href="#{slug}"><span class="toc-num">{j}</span><span class="toc-label">{label}</span><span class="toc-dots"></span></a>')
        toc.append("</div>")

        toc.append("</div>")
        return "\n".join(toc)

    def _extract_section(self, header_pattern: str) -> str:
        """Extract a section from the synthesis report by header pattern."""
        pattern = rf"(##\s*{header_pattern}.*?)(?=\n##\s|\Z)"
        m = re.search(pattern, self.synthesis, re.DOTALL | re.IGNORECASE)
        return m.group(1).strip() if m else ""

    def _exec_summary_section(self) -> str:
        content = self._extract_section("Executive Summary")
        if not content:
            content = "## Executive Summary\n\nNo executive summary available."
        return f'<div class="chapter" id="executive-summary">\n{md_to_html(content)}\n</div>'

    def _score_breakdown_section(self) -> str:
        content = self._extract_section("Score Breakdown")
        if not content:
            content = self._build_score_table()
        return f'<div class="chapter" id="score-breakdown">\n<h2>Score Breakdown</h2>\n{md_to_html(content)}\n</div>'

    def _build_score_table(self) -> str:
        """Build score table from agent data if synthesis doesn't have one."""
        rows = []
        for a in self.agents:
            if a["score"] is not None:
                pct = (a["score"] / a["max_score"] * 100) if a["max_score"] else 0
                grade = self._score_grade(int(pct))
                rows.append(f"| {a['title']} | {a['score']}/{a['max_score']} | {grade} |")
        if rows:
            return "| Area | Score | Grade |\n|------|-------|-------|\n" + "\n".join(rows)
        return ""

    def _quick_wins_section(self) -> str:
        content = self._extract_section("Top 10 Quick Wins")
        if not content:
            content = self._extract_section("Quick Wins")
        if not content:
            content = "## Top Quick Wins\n\nSee individual agent reports for specific recommendations."
        return f'<div class="chapter" id="top-quick-wins">\n{md_to_html(content)}\n</div>'

    def _critical_issues_section(self) -> str:
        content = self._extract_section("Critical Issues")
        if not content:
            content = "## Critical Issues\n\nSee individual agent reports for critical findings."
        return f'<div class="chapter" id="critical-issues">\n{md_to_html(content)}\n</div>'

    def _roadmap_section(self) -> str:
        content = self._extract_section("90-Day Roadmap")
        if not content:
            content = self._extract_section("Roadmap")
        if not content:
            content = "## 90-Day Roadmap\n\nSee individual agent reports for implementation timelines."
        return f'<div class="chapter" id="90-day-roadmap">\n{md_to_html(content)}\n</div>'

    def _agent_deepdives(self) -> str:
        """Generate one chapter per agent with full report content."""
        chapters = []
        for agent in self.agents:
            score_text = ""
            score_class = ""
            if agent["score"] is not None:
                pct = (agent["score"] / agent["max_score"] * 100) if agent["max_score"] else 0
                if pct >= 70:
                    score_class = "score-high"
                elif pct >= 50:
                    score_class = "score-mid"
                else:
                    score_class = "score-low"
                score_text = f'<span class="score-badge {score_class}">{agent["score"]}/{agent["max_score"]}</span>'

            # Parse the CMO review verdict for this agent
            gate_html = ""
            if self.cmo_review:
                for line in self.cmo_review.splitlines():
                    name_variants = [agent["name"], agent["title"].lower()]
                    if any(v in line.lower() for v in name_variants):
                        if "PASS" in line:
                            gate_html = '<span class="gate-pass">PASS</span>'
                        elif "FAIL" in line:
                            gate_html = '<span class="gate-fail">FAIL</span>'

            meta_parts = [f"{agent['size_kb']:.1f} KB report"]
            if gate_html:
                meta_parts.append(f"Quality Gate: {gate_html}")

            chapter = f"""
<div class="chapter" id="agent-{agent['name']}">
    <div class="chapter-header">
        <h2>{agent['title']} {score_text}</h2>
        <div class="chapter-meta">{' &bull; '.join(meta_parts)}</div>
    </div>
    {md_to_html(agent['content'])}
</div>"""
            chapters.append(chapter)

        return "\n".join(chapters)

    def _quality_gate_section(self) -> str:
        if not self.cmo_review:
            return f'<div class="chapter" id="quality-gate-results">\n<h2>Quality Gate Results</h2>\n<p>No CMO review available.</p>\n</div>'
        return f'<div class="chapter" id="quality-gate-results">\n{md_to_html(self.cmo_review)}\n</div>'

    def _competitive_section(self) -> str:
        content = self._extract_section("Competitive Position")
        if not content:
            competitors = self.context.get("competitors", "")
            content = f"## Competitive Position\n\nCompetitors identified: {competitors}" if competitors else "## Competitive Position\n\nNo competitive data available."
        return f'<div class="chapter" id="competitive-position">\n{md_to_html(content)}\n</div>'

    def _audit_log_section(self) -> str:
        content = self._extract_section("Audit Log")
        if not content:
            content = self._build_audit_log()
        return f'<div class="chapter" id="audit-log">\n<h2>Audit Log</h2>\n{md_to_html(content)}\n</div>'

    def _build_audit_log(self) -> str:
        """Build audit log from agent data."""
        haiku_skills = {
            "analytics-tracking", "schema-markup", "form-cro",
            "popup-cro", "product-feed", "geo-audit",
        }
        rows = []
        for a in self.agents:
            model = "haiku" if a["name"] in haiku_skills else "sonnet"
            score = f"{a['score']}/{a['max_score']}" if a["score"] is not None else "--"
            rows.append(f"| {a['title']} | {model} | {score} | {a['size_kb']:.1f} KB |")
        header = "| Specialist | Model | Score | Report Size |\n|-----------|-------|-------|------------|"
        return header + "\n" + "\n".join(rows) if rows else ""


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) < 2:
        print(f"Usage: python3 {sys.argv[0]} /tmp/marketing-audit-<domain>")
        sys.exit(1)

    audit_dir = sys.argv[1]

    if not os.path.isdir(audit_dir):
        print(f"Error: directory not found: {audit_dir}")
        sys.exit(1)

    print(f"Building report for: {audit_dir}")

    # Build report
    builder = ReportBuilder(audit_dir)
    builder.load()
    html = builder.build_html()

    # Write HTML
    html_path = os.path.join(audit_dir, "FULL-REPORT.html")
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"HTML report: {html_path} ({os.path.getsize(html_path) / 1024:.1f} KB)")

    # Convert to PDF via Chrome headless
    pdf_path = os.path.join(audit_dir, "FULL-REPORT.pdf")
    chrome = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

    if not os.path.exists(chrome):
        print(f"Warning: Chrome not found at {chrome}")
        print("HTML report generated. Convert manually or install Chrome.")
        return

    print("Converting to PDF via Chrome headless...")
    try:
        result = subprocess.run(
            [
                chrome,
                "--headless",
                "--disable-gpu",
                "--no-sandbox",
                "--run-all-compositor-stages-before-draw",
                "--virtual-time-budget=3000",
                f"--print-to-pdf={pdf_path}",
                "--no-pdf-header-footer",
                html_path,
            ],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if os.path.exists(pdf_path):
            size_mb = os.path.getsize(pdf_path) / (1024 * 1024)
            print(f"PDF report:  {pdf_path} ({size_mb:.2f} MB)")
            print("Done.")
        else:
            print(f"PDF conversion may have failed. stderr: {result.stderr[:500]}")
    except subprocess.TimeoutExpired:
        print("Chrome timed out. HTML report is still available.")
    except Exception as e:
        print(f"PDF conversion error: {e}")
        print("HTML report is still available.")


if __name__ == "__main__":
    main()
