#!/usr/bin/env python3
"""Marketing Orchestrator — Live Dashboard

Monitors the audit directory and displays real-time progress.
Launched automatically by the orchestrator in a new terminal window.

Usage: python3 dashboard.py /tmp/marketing-audit-example.com
"""

import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

# ANSI colors
class C:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN = "\033[96m"
    WHITE = "\033[97m"
    BG_RED = "\033[41m"
    BG_GREEN = "\033[42m"
    BG_YELLOW = "\033[43m"
    BG_BLUE = "\033[44m"
    BG_MAGENTA = "\033[45m"

BATCH_LABELS = {
    1: "FOUNDATION",
    2: "CORE",
    3: "GROWTH",
    4: "ADVANCED",
}

# Skills that run on haiku
HAIKU_SKILLS = {
    "analytics-tracking", "schema-markup", "form-cro",
    "popup-cro", "product-feed", "geo-audit",
}

PHASE_NAMES = {
    "reconnaissance": "RECONNAISSANCE",
    "collectors": "COLLECTORS",
    "skill_selection": "SKILL SELECTION",
    "batch1": "BATCH 1 — FOUNDATION",
    "warm_handoff": "WARM HANDOFF",
    "batch2": "BATCH 2 — CORE",
    "batch3": "BATCH 3 — GROWTH",
    "batch4": "BATCH 4 — ADVANCED",
    "quality_gate": "QUALITY GATE",
    "remediation": "REMEDIATION",
    "synthesis": "SYNTHESIS",
    "complete": "COMPLETE",
}


def clear_screen():
    print("\033[2J\033[H", end="")


def read_json(path):
    try:
        with open(path) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return None


def detect_phase(audit_dir):
    """Detect current phase from filesystem state."""
    d = Path(audit_dir)

    if (d / "FULL-REPORT.md").exists():
        return "complete"
    if (d / "review" / "cmo-review.md").exists():
        # Check if remediation is happening
        agents = list((d / "agents").glob("*.md")) if (d / "agents").exists() else []
        review_time = (d / "review" / "cmo-review.md").stat().st_mtime
        newer_agents = [a for a in agents if a.stat().st_mtime > review_time]
        if newer_agents:
            return "remediation"
        return "quality_gate"

    agents = list((d / "agents").glob("*.md")) if (d / "agents").exists() else []
    handoff2 = (d / "handoffs" / "batch23-summary.md").exists()
    handoff1 = (d / "handoffs" / "batch1-summary.md").exists()

    if handoff2 and agents:
        return "batch4"
    if handoff1 and len(agents) > 5:
        return "batch3"  # or batch2, they run in parallel
    if handoff1:
        return "warm_handoff"
    if agents:
        return "batch1"
    if (d / "context.md").exists():
        if not (d / "collectors-data.md").exists():
            return "collectors"
        return "skill_selection"
    if (d / "crawl-data.md").exists():
        return "reconnaissance"
    return "reconnaissance"


def parse_agent_report(path):
    """Extract score from an agent report file."""
    try:
        text = path.read_text()
        # Look for ## Score: XX/100 or ## Score: XX/80
        match = re.search(r"## Score:\s*(\d+)\s*/\s*(\d+)", text)
        if match:
            return int(match.group(1)), int(match.group(2))
        return None, None
    except Exception:
        return None, None


def parse_cmo_review(path):
    """Extract pass/fail verdicts from CMO review."""
    results = {}
    try:
        text = path.read_text()
        # Look for table rows with PASS/FAIL
        for line in text.split("\n"):
            if "PASS" in line or "FAIL" in line:
                parts = [p.strip() for p in line.split("|") if p.strip()]
                if len(parts) >= 8:
                    name = parts[0].strip()
                    verdict = parts[-1].strip()
                    try:
                        total = int(parts[-2].strip().split("/")[0])
                    except (ValueError, IndexError):
                        total = 0
                    results[name] = {"verdict": verdict, "total": total}
    except Exception:
        pass
    return results


def get_agent_status(audit_dir):
    """Get status of all agents."""
    agents_dir = Path(audit_dir) / "agents"
    if not agents_dir.exists():
        return []

    agents = []
    for f in sorted(agents_dir.glob("*.md")):
        name = f.stem
        score, max_score = parse_agent_report(f)
        size = f.stat().st_size
        mtime = datetime.fromtimestamp(f.stat().st_mtime)

        # Detect if report is truncated/empty
        status = "complete"
        if size < 200:
            status = "truncated"

        agents.append({
            "name": name,
            "score": score,
            "max_score": max_score,
            "status": status,
            "size": size,
            "time": mtime,
            "model": "haiku" if name in HAIKU_SKILLS else "sonnet",
        })

    return agents


def format_bar(value, max_val, width=20):
    """Create a progress bar."""
    if max_val == 0:
        return " " * width
    filled = int((value / max_val) * width)
    bar = "█" * filled + "░" * (width - filled)
    return bar


def format_score_color(score, max_score):
    """Color a score based on percentage."""
    if score is None:
        return f"{C.DIM}--{C.RESET}"
    pct = (score / max_score) * 100 if max_score > 0 else 0
    if pct >= 75:
        color = C.GREEN
    elif pct >= 50:
        color = C.YELLOW
    else:
        color = C.RED
    return f"{color}{score}/{max_score}{C.RESET}"


def render(audit_dir, start_time):
    clear_screen()
    d = Path(audit_dir)
    domain = d.name.replace("marketing-audit-", "")
    elapsed = time.time() - start_time
    mins, secs = divmod(int(elapsed), 60)

    # Header
    print(f"{C.BOLD}{C.CYAN}╔{'═' * 68}╗{C.RESET}")
    print(f"{C.BOLD}{C.CYAN}║{C.RESET}  {C.BOLD}MARKETING ORCHESTRATOR{C.RESET} — {C.WHITE}{domain}{C.RESET}{' ' * max(0, 43 - len(domain) - 1)}{C.CYAN}║{C.RESET}")
    print(f"{C.BOLD}{C.CYAN}╚{'═' * 68}╝{C.RESET}")
    print()

    # Phase + timing
    phase = detect_phase(audit_dir)
    phase_label = PHASE_NAMES.get(phase, phase.upper())

    if phase == "complete":
        phase_display = f"{C.BG_GREEN}{C.WHITE} {phase_label} {C.RESET}"
    elif phase == "collectors":
        phase_display = f"{C.BG_MAGENTA}{C.WHITE} {phase_label} {C.RESET}"
    elif "batch" in phase:
        phase_display = f"{C.BG_BLUE}{C.WHITE} {phase_label} {C.RESET}"
    elif phase == "quality_gate":
        phase_display = f"{C.BG_MAGENTA}{C.WHITE} {phase_label} {C.RESET}"
    elif phase == "remediation":
        phase_display = f"{C.BG_YELLOW}{C.WHITE} {phase_label} {C.RESET}"
    else:
        phase_display = f"{C.BG_BLUE}{C.WHITE} {phase_label} {C.RESET}"

    print(f"  {C.DIM}Phase:{C.RESET}   {phase_display}")
    print(f"  {C.DIM}Elapsed:{C.RESET} {C.WHITE}{mins:02d}:{secs:02d}{C.RESET}")

    # Context info
    context_path = d / "context.md"
    if context_path.exists():
        ctx = context_path.read_text()
        btype_match = re.search(r"Type:\s*(.+)", ctx)
        industry_match = re.search(r"Industry:\s*(.+)", ctx)
        if btype_match:
            print(f"  {C.DIM}Type:{C.RESET}    {C.WHITE}{btype_match.group(1).strip()}{C.RESET}")
        if industry_match:
            print(f"  {C.DIM}Industry:{C.RESET}{C.WHITE} {industry_match.group(1).strip()}{C.RESET}")

    # Crawl status
    crawl_path = d / "crawl-data.md"
    if crawl_path.exists():
        crawl_text = crawl_path.read_text()
        page_count = crawl_text.count("## PAGE:")
        crawl_lines = len(crawl_text.splitlines())
        print(f"  {C.DIM}Crawled:{C.RESET} {C.GREEN}{page_count} pages{C.RESET} ({crawl_lines:,} lines)")

    # Collectors status
    collectors_path = d / "collectors-data.md"
    if collectors_path.exists():
        collectors_lines = len(collectors_path.read_text().splitlines())
        print(f"  {C.DIM}Collect:{C.RESET} {C.GREEN}10 collectors{C.RESET} ({collectors_lines:,} lines)")
    elif phase == "collectors":
        print(f"  {C.DIM}Collect:{C.RESET} {C.YELLOW}running...{C.RESET}")

    print()

    # Agent status table
    agents = get_agent_status(audit_dir)
    cmo_results = {}
    cmo_path = d / "review" / "cmo-review.md"
    if cmo_path.exists():
        cmo_results = parse_cmo_review(cmo_path)

    if agents:
        print(f"  {C.BOLD}{'Agent':<28} {'Model':<8} {'Score':<12} {'Size':<10} {'Gate':<8}{C.RESET}")
        print(f"  {C.DIM}{'─' * 66}{C.RESET}")

        for agent in agents:
            name = agent["name"]
            model = agent["model"]
            model_display = f"{C.CYAN}{model}{C.RESET}" if model == "haiku" else f"{C.MAGENTA}{model}{C.RESET}"

            score_display = format_score_color(agent["score"], agent["max_score"])

            size_kb = agent["size"] / 1024
            if agent["status"] == "truncated":
                size_display = f"{C.RED}{size_kb:.1f}KB ⚠{C.RESET}"
            else:
                size_display = f"{C.GREEN}{size_kb:.1f}KB{C.RESET}"

            # CMO gate result
            gate = ""
            if name in cmo_results:
                v = cmo_results[name]
                if v["verdict"] == "PASS":
                    gate = f"{C.GREEN}PASS {v['total']}/25{C.RESET}"
                else:
                    gate = f"{C.RED}FAIL {v['total']}/25{C.RESET}"

            # Status icon
            if agent["status"] == "complete":
                icon = f"{C.GREEN}●{C.RESET}"
            elif agent["status"] == "truncated":
                icon = f"{C.RED}●{C.RESET}"
            else:
                icon = f"{C.YELLOW}●{C.RESET}"

            print(f"  {icon} {name:<26} {model_display:<17} {score_display:<21} {size_display:<19} {gate}")

        print(f"  {C.DIM}{'─' * 66}{C.RESET}")

        # Summary stats
        complete = sum(1 for a in agents if a["status"] == "complete")
        truncated = sum(1 for a in agents if a["status"] == "truncated")
        scores = [a["score"] for a in agents if a["score"] is not None]
        avg = sum(scores) / len(scores) if scores else 0

        print(f"  {C.DIM}Agents:{C.RESET} {C.GREEN}{complete} complete{C.RESET}", end="")
        if truncated:
            print(f" {C.RED}{truncated} truncated{C.RESET}", end="")
        print(f"  {C.DIM}|{C.RESET}  {C.DIM}Avg Score:{C.RESET} {C.WHITE}{avg:.0f}{C.RESET}")

    else:
        print(f"  {C.DIM}No agent reports yet...{C.RESET}")

    print()

    # Handoff status
    h1 = d / "handoffs" / "batch1-summary.md"
    h23 = d / "handoffs" / "batch23-summary.md"
    if h1.exists() or h23.exists():
        print(f"  {C.BOLD}Warm Handoffs{C.RESET}")
        if h1.exists():
            print(f"  {C.GREEN}●{C.RESET} Batch 1 → 2+3 handoff ready")
        if h23.exists():
            print(f"  {C.GREEN}●{C.RESET} Batch 2+3 → 4 handoff ready")
        print()

    # Quality gate
    if cmo_path.exists():
        passed = sum(1 for v in cmo_results.values() if v.get("verdict") == "PASS")
        failed = sum(1 for v in cmo_results.values() if v.get("verdict") == "FAIL")
        total = passed + failed
        print(f"  {C.BOLD}Quality Gate{C.RESET}")
        if total > 0:
            print(f"  {C.GREEN}PASS: {passed}{C.RESET}  {C.RED}FAIL: {failed}{C.RESET}  ({passed}/{total} = {passed/total*100:.0f}%)")
        print()

    # Final report
    report_path = d / "FULL-REPORT.md"
    if report_path.exists():
        report_size = report_path.stat().st_size / 1024
        print(f"  {C.BG_GREEN}{C.WHITE} REPORT READY {C.RESET}")
        print(f"  {C.GREEN}{report_path} ({report_size:.1f}KB){C.RESET}")
        print()

    # Footer
    print(f"  {C.DIM}Watching: {audit_dir}{C.RESET}")
    print(f"  {C.DIM}Ctrl+C to close dashboard (orchestrator keeps running){C.RESET}")


def main():
    if len(sys.argv) < 2:
        print(f"Usage: python3 {sys.argv[0]} /tmp/marketing-audit-<domain>")
        sys.exit(1)

    audit_dir = sys.argv[1]

    # Wait for directory to exist
    print(f"Waiting for {audit_dir}...")
    while not os.path.isdir(audit_dir):
        time.sleep(0.5)

    start_time = time.time()

    # Check if session started earlier
    context_path = os.path.join(audit_dir, "context.md")
    if os.path.exists(context_path):
        start_time = os.path.getmtime(context_path)

    try:
        while True:
            render(audit_dir, start_time)
            time.sleep(2)
    except KeyboardInterrupt:
        clear_screen()
        print(f"{C.CYAN}Dashboard closed.{C.RESET}")


if __name__ == "__main__":
    main()
