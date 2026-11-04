#!/usr/bin/env python3
"""QA run folders and findings.

A run is a folder with a plan (run.md), one folder per finding (finding.md plus
its screenshots) and a generated README.md that indexes everything:

    artifacts/qa-runs/2026-09-25-regression/
      run.md
      README.md
      findings/search-no-results-blank/finding.md
      findings/search-no-results-blank/1.jpg

Commands:
    new <mode> [--slug s]          create a run folder, print its path
    add <run> <title> [options]    create a finding (screenshots included), print its folder
    shot <finding> <png> [caption] add a screenshot to a finding
    section <finding> <heading> <text>  replace (or --append to) a section, e.g. Cause
    set <finding> key=value ...    update a finding's frontmatter
    list <run> [filters] [--json]  list findings
    check <run>                    validate every finding
    index <run>                    regenerate README.md (add/shot/set do it for you)

Runs live in $QA_RUNS_DIR, or artifacts/qa-runs/ in the repo (gitignored).
Frontmatter is flat `key: value` pairs, one per line.
"""
import argparse
import datetime
import json
import os
import re
import subprocess
import sys
import tempfile

SEVERITIES = ["critical", "major", "minor", "note"]
CATEGORIES = ["crash", "bug", "ux", "a11y", "visual", "copy", "perf"]
STATUSES = ["candidate", "verified", "rejected", "reported"]
FINDING_KEYS = ["title", "status", "severity", "category", "area", "scenario", "account", "device",
                "settings", "build", "found", "fingerprint", "linear"]
REQUIRED_SECTIONS = ["Steps", "Actual", "Expected"]
SEVERITY_ICONS = {"critical": "🟥", "major": "🟧", "minor": "🟨", "note": "⬜️"}


# Documents

def parse_value(value):
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] == '"':
        return value[1:-1].replace('\\"', '"').replace("\\\\", "\\")
    return value


def format_value(value):
    value = str(value)
    if value and (value[0] in "[]{}*&!|>'\"%@`#,?:-" or ": " in value or " #" in value or value != value.strip()):
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'
    return value


def read_doc(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    match = re.match(r"---\n(.*?)\n---\n?", text, re.S)
    if not match:
        return {}, text
    meta = {}
    for line in match.group(1).splitlines():
        key, sep, value = line.partition(":")
        if sep and key.strip() and not key.startswith("#"):
            meta[key.strip()] = parse_value(value)
    return meta, text[match.end():]


def write_text(path, text):
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".tmp-")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(text)
    os.chmod(tmp, 0o644)
    os.replace(tmp, path)


def write_doc(path, meta, body):
    head = "\n".join(f"{k}: {format_value(v)}".rstrip() for k, v in meta.items())
    write_text(path, f"---\n{head}\n---\n\n{body.lstrip(chr(10))}")


def sections(body):
    """Maps each `## Heading` to its text."""
    result, current = {}, None
    for line in body.splitlines():
        heading = re.match(r"##\s+(.+?)\s*$", line)
        if heading:
            current = heading.group(1)
            result[current] = []
        elif current:
            result[current].append(line)
    return {k: "\n".join(v).strip() for k, v in result.items()}


def slugify(text, limit=50):
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    if len(slug) > limit:
        cut = slug[:limit + 1]
        slug = cut[:cut.rfind("-")] if "-" in cut else slug[:limit]
    return slug or "finding"


# Runs

def repo_root():
    try:
        return subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True, stderr=subprocess.DEVNULL).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return os.getcwd()


def runs_root():
    return os.environ.get("QA_RUNS_DIR") or os.path.join(repo_root(), "artifacts", "qa-runs")


def git(*args):
    try:
        return subprocess.check_output(["git", *args], text=True, stderr=subprocess.DEVNULL).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def resolve_run(path):
    path = os.path.abspath(path)
    if os.path.isfile(os.path.join(path, "run.md")):
        return path
    candidate = os.path.join(runs_root(), os.path.basename(path))
    if os.path.isfile(os.path.join(candidate, "run.md")):
        return candidate
    sys.exit(f"error: no run.md in {path}")


def run_of(finding_dir):
    return os.path.dirname(os.path.dirname(os.path.abspath(finding_dir)))


def load_findings(run_dir):
    root = os.path.join(run_dir, "findings")
    items = []
    for slug in sorted(os.listdir(root)) if os.path.isdir(root) else []:
        path = os.path.join(root, slug, "finding.md")
        if not os.path.isfile(path):
            continue
        meta, body = read_doc(path)
        shots = re.findall(r"!\[([^\]]*)\]\(([^)\s]+)\)", body)
        items.append({
            "slug": slug,
            "path": path,
            "dir": os.path.dirname(path),
            **meta,
            "shots": [{"caption": c, "file": os.path.join(os.path.dirname(path), f)} for c, f in shots],
            "sections": sections(body),
        })
    return items


def sort_key(item):
    status_order = {"verified": 0, "candidate": 1, "reported": 2, "rejected": 3}
    return (
        status_order.get(item.get("status"), 9),
        SEVERITIES.index(item["severity"]) if item.get("severity") in SEVERITIES else 9,
        item.get("found", ""),
    )


# Commands

def cmd_new(args):
    date = datetime.date.today().isoformat()
    name = "-".join(filter(None, [date, slugify(args.mode), slugify(args.slug) if args.slug else ""]))
    root = runs_root()
    run_dir, n = os.path.join(root, name), 2
    while os.path.exists(run_dir):
        run_dir, n = os.path.join(root, f"{name}-{n}"), n + 1
    os.makedirs(os.path.join(run_dir, "findings"))
    commit = git("rev-parse", "--short", "HEAD")
    branch = git("branch", "--show-current")
    meta = {
        "run": os.path.basename(run_dir),
        "mode": args.mode,
        "scope": args.scope or "",
        "build": "",
        "commit": f"{commit} ({branch})" if branch else commit,
        "devices": "",
        "accounts": "",
        "rules": args.rules,
        "started": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
        "status": "planning",
    }
    body = (
        "## Plan\n\n"
        "## Coverage\n\n"
        "| Scenario | Device | Account | Status | Notes |\n"
        "|---|---|---|---|---|\n\n"
        "## State changes\n\n"
        "## Not covered\n"
    )
    write_doc(os.path.join(run_dir, "run.md"), meta, body)
    regenerate_index(run_dir)
    print(run_dir)


def convert_shot(png, finding_dir, caption):
    existing = [f for f in os.listdir(finding_dir) if re.match(r"\d+\.jpg$", f)]
    name = f"{len(existing) + 1}.jpg"
    subprocess.run(
        ["sips", "-s", "format", "jpeg", "-s", "formatOptions", "70", "-Z", "1600", png, "--out", os.path.join(finding_dir, name)],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    caption = caption.replace("[", "(").replace("]", ")") or "Screenshot"
    return f"![{caption}]({name})"


def split_shot(spec):
    png, _, caption = spec.partition("::")
    return os.path.expanduser(png), caption.strip()


def cmd_add(args):
    run_dir = resolve_run(args.run)
    if args.severity not in SEVERITIES:
        sys.exit(f"error: severity must be one of {', '.join(SEVERITIES)}")
    if args.category not in CATEGORIES:
        sys.exit(f"error: category must be one of {', '.join(CATEGORIES)}")
    slug = slugify(f"{args.area.split('›')[0]} {args.title}", 60)
    finding_dir, n = os.path.join(run_dir, "findings", slug), 2
    while os.path.exists(finding_dir):
        finding_dir, n = os.path.join(run_dir, "findings", f"{slug}-{n}"), n + 1
    os.makedirs(finding_dir)
    run_meta, _ = read_doc(os.path.join(run_dir, "run.md"))
    meta = {
        "title": args.title,
        "status": "candidate",
        "severity": args.severity,
        "category": args.category,
        "area": args.area,
        "scenario": args.scenario or "",
        "account": args.account or "",
        "device": args.device or "",
        "settings": args.settings or "default",
        "build": args.build or run_meta.get("build", ""),
        "found": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
        "fingerprint": f"{slugify(args.area, 30)}/{slugify(args.title)}",
        "linear": "",
    }
    shots = []
    for spec in args.shot or []:
        png, caption = split_shot(spec)
        shots.append(convert_shot(png, finding_dir, caption))
    steps = "\n".join(f"{i}. {s}" for i, s in enumerate(args.step or [], 1)) or "1. TODO"
    body = (
        f"## Steps\n\n{steps}\n\n"
        f"## Actual\n\n{args.actual or 'TODO'}\n\n"
        f"## Expected\n\n{args.expected or 'TODO'}\n\n"
        f"## Screenshots\n\n{chr(10).join(shots)}\n\n"
        f"## Cause\n\n{args.cause or ''}\n\n"
        f"## Notes\n\n{args.notes or ''}\n"
    )
    write_doc(os.path.join(finding_dir, "finding.md"), meta, body)
    regenerate_index(run_dir)
    print(finding_dir)


def edit_section(body, heading, text, append):
    lines = body.rstrip("\n").split("\n")
    marker = f"## {heading}"
    stripped = [line.strip() for line in lines]
    if marker not in stripped:
        return "\n".join(lines) + f"\n\n{marker}\n\n{text}\n"
    start = stripped.index(marker)
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("## ")), len(lines))
    content = lines[start + 1:end] if append else []
    while content and not content[-1].strip():
        content.pop()
    while content and not content[0].strip():
        content.pop(0)
    content.append(text)
    rest = lines[end:]
    return "\n".join(lines[:start + 1] + [""] + content + ([""] + rest if rest else [])) + "\n"


def cmd_shot(args):
    finding_dir = os.path.abspath(args.finding)
    path = os.path.join(finding_dir, "finding.md")
    meta, body = read_doc(path)
    image = convert_shot(os.path.expanduser(args.png), finding_dir, args.caption or "")
    write_doc(path, meta, edit_section(body, "Screenshots", image, append=True))
    regenerate_index(run_of(finding_dir))
    print(image)


def cmd_section(args):
    finding_dir = os.path.abspath(args.finding)
    path = os.path.join(finding_dir, "finding.md")
    meta, body = read_doc(path)
    text = sys.stdin.read().strip() if args.text == "-" else args.text
    write_doc(path, meta, edit_section(body, args.heading, text, append=args.append))
    regenerate_index(run_of(finding_dir))


def cmd_set(args):
    finding_dir = os.path.abspath(args.finding)
    path = os.path.join(finding_dir, "finding.md")
    meta, body = read_doc(path)
    for pair in args.pairs:
        key, sep, value = pair.partition("=")
        if not sep:
            sys.exit(f"error: expected key=value, got {pair}")
        if key == "status" and value not in STATUSES:
            sys.exit(f"error: status must be one of {', '.join(STATUSES)}")
        if key == "severity" and value not in SEVERITIES:
            sys.exit(f"error: severity must be one of {', '.join(SEVERITIES)}")
        if key == "category" and value not in CATEGORIES:
            sys.exit(f"error: category must be one of {', '.join(CATEGORIES)}")
        meta[key] = value
    write_doc(path, meta, body)
    regenerate_index(run_of(finding_dir))


def cmd_list(args):
    items = load_findings(resolve_run(args.run))
    if args.status:
        items = [i for i in items if i.get("status") in args.status.split(",")]
    if args.min_severity:
        limit = SEVERITIES.index(args.min_severity)
        items = [i for i in items if i.get("severity") in SEVERITIES[:limit + 1]]
    items.sort(key=sort_key)
    if args.json:
        print(json.dumps(items, indent=2, ensure_ascii=False))
        return
    for i in items:
        print(f"{i['slug']:<50} {i.get('status', ''):<10} {i.get('severity', ''):<9} {i.get('category', ''):<7} {i.get('title', '')}")


def cmd_check(args):
    problems = []
    for i in load_findings(resolve_run(args.run)):
        where = i["slug"]
        if i.get("status") == "rejected":
            if not i["sections"].get("Verdict"):
                problems.append(f"{where}: rejected without a `## Verdict`")
            continue
        for key in ["title", "status", "severity", "category", "area"]:
            if not i.get(key):
                problems.append(f"{where}: missing `{key}`")
        for key, allowed in [("status", STATUSES), ("severity", SEVERITIES), ("category", CATEGORIES)]:
            if i.get(key) and i[key] not in allowed:
                problems.append(f"{where}: `{key}: {i[key]}` is not one of {', '.join(allowed)}")
        for name in REQUIRED_SECTIONS:
            text = i["sections"].get(name, "")
            if not text or text in ("TODO", "1. TODO"):
                problems.append(f"{where}: `## {name}` is empty")
        if not i["shots"] and i.get("category") != "perf":
            problems.append(f"{where}: no screenshots")
        for shot in i["shots"]:
            if not os.path.isfile(shot["file"]):
                problems.append(f"{where}: missing {os.path.basename(shot['file'])}")
        if i.get("status") == "reported" and not i.get("linear"):
            problems.append(f"{where}: reported without `linear`")
    print("\n".join(problems) or "OK")
    sys.exit(1 if problems else 0)


def cmd_index(args):
    print(regenerate_index(resolve_run(args.run)))


# README

def cell(text):
    return str(text or "").replace("|", "\\|").replace("\n", " ")


def coverage_counts(run_body):
    rows = sections(run_body).get("Coverage", "").splitlines()
    table = [r for r in rows if r.startswith("|")]
    if len(table) < 3:
        return {}
    header = [c.strip().lower() for c in table[0].strip("|").split("|")]
    if "status" not in header:
        return {}
    index, counts = header.index("status"), {}
    for row in table[2:]:
        cells = [c.strip() for c in row.strip("|").split("|")]
        if index < len(cells) and cells[index]:
            counts[cells[index]] = counts.get(cells[index], 0) + 1
    return counts


def regenerate_index(run_dir):
    run_meta, run_body = read_doc(os.path.join(run_dir, "run.md"))
    items = sorted(load_findings(run_dir), key=sort_key)
    active = [i for i in items if i.get("status") != "rejected"]
    rejected = [i for i in items if i.get("status") == "rejected"]

    def count(values, key, order):
        return " · ".join(f"{sum(1 for v in values if v.get(key) == o)} {o}" for o in order if any(v.get(key) == o for v in values))

    info = " · ".join(filter(None, [run_meta.get(k) for k in ["mode", "scope", "build", "commit", "devices", "accounts"]]))
    lines = [f"# QA run {run_meta.get('run', os.path.basename(run_dir))}", ""]
    if info:
        lines += [info, ""]
    lines += [f"**Status:** {run_meta.get('status', '')} · started {run_meta.get('started', '')} · [plan and coverage](run.md)", ""]
    coverage = coverage_counts(run_body)
    if coverage:
        lines += ["**Coverage:** " + " · ".join(f"{n} {s}" for s, n in coverage.items()), ""]
    noun = "finding" if len(active) == 1 else "findings"
    lines += [f"**{len(active)} {noun}:** {count(active, 'severity', SEVERITIES) or 'none yet'}", ""]
    if active:
        lines += [f"By status: {count(active, 'status', STATUSES)}. Rejected: {len(rejected)}.", ""]
        lines += ["| # | | Finding | Area | Category | Status | Screenshot |", "|---|---|---|---|---|---|---|"]
        for n, i in enumerate(active, 1):
            rel = os.path.relpath(i["path"], run_dir)
            shot = i["shots"][0] if i["shots"] else None
            thumb = f'<img src="{os.path.relpath(shot["file"], run_dir)}" width="90">' if shot else ""
            status = i.get("status", "")
            if i.get("linear"):
                status += f" ({i['linear']})"
            icon = SEVERITY_ICONS.get(i.get("severity"), "")
            lines.append(f"| {n} | {icon} {i.get('severity', '')} | [{cell(i.get('title'))}]({rel}) | {cell(i.get('area'))} | {i.get('category', '')} | {cell(status)} | {thumb} |")
        lines.append("")
    if rejected:
        lines += ["## Rejected", ""]
        for i in rejected:
            verdict = i["sections"].get("Verdict", "").split("\n")[0]
            lines.append(f"- [{i.get('title')}]({os.path.relpath(i['path'], run_dir)}): {verdict}")
        lines.append("")
    path = os.path.join(run_dir, "README.md")
    write_text(path, "\n".join(lines))
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("new", help="create a run folder")
    p.add_argument("mode", help="smoke, regression, explore, verify or sweep")
    p.add_argument("--slug", help="short name, e.g. the feature under test")
    p.add_argument("--scope", help="tags, spec or PR the run covers")
    p.add_argument("--rules", choices=["test", "real"], default="test", help="test accounts (default) or a real account")
    p.set_defaults(func=cmd_new)

    p = sub.add_parser("add", help="create a finding")
    p.add_argument("run")
    p.add_argument("title", help="the claim, e.g. 'Search with no matches shows a blank screen'")
    p.add_argument("--severity", required=True, help=" | ".join(SEVERITIES))
    p.add_argument("--category", required=True, help=" | ".join(CATEGORIES))
    p.add_argument("--area", required=True, help="e.g. 'Discover › Search'")
    p.add_argument("--scenario", help="scenario file#heading, if any")
    p.add_argument("--account", help="account profile, 'signed-out' or 'real'")
    p.add_argument("--device", help="e.g. 'iPhone 17 Pro, iOS 27.0'")
    p.add_argument("--settings", help="non-default settings in effect, e.g. 'dark, AX5'")
    p.add_argument("--build")
    p.add_argument("--step", action="append", help="one per step, in order")
    p.add_argument("--actual")
    p.add_argument("--expected")
    p.add_argument("--cause", help="path:line and why, if known")
    p.add_argument("--notes")
    p.add_argument("--shot", action="append", help="screenshot PNG, optionally 'path::caption'")
    p.set_defaults(func=cmd_add)

    p = sub.add_parser("shot", help="add a screenshot to a finding")
    p.add_argument("finding", help="finding folder")
    p.add_argument("png")
    p.add_argument("caption", nargs="?")
    p.set_defaults(func=cmd_shot)

    p = sub.add_parser("section", help="replace (or --append to) a `## Heading` section")
    p.add_argument("finding", help="finding folder")
    p.add_argument("heading", help="e.g. Cause or Verdict")
    p.add_argument("text", help="Markdown, or - to read stdin")
    p.add_argument("--append", action="store_true")
    p.set_defaults(func=cmd_section)

    p = sub.add_parser("set", help="update frontmatter, e.g. status=verified")
    p.add_argument("finding", help="finding folder")
    p.add_argument("pairs", nargs="+", metavar="key=value")
    p.set_defaults(func=cmd_set)

    p = sub.add_parser("list", help="list findings")
    p.add_argument("run")
    p.add_argument("--status", help="comma-separated, e.g. verified")
    p.add_argument("--min-severity", choices=SEVERITIES)
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_list)

    p = sub.add_parser("check", help="validate findings")
    p.add_argument("run")
    p.set_defaults(func=cmd_check)

    p = sub.add_parser("index", help="regenerate README.md")
    p.add_argument("run")
    p.set_defaults(func=cmd_index)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
