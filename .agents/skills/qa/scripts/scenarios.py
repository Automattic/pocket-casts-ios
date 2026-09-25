#!/usr/bin/env python3
"""Lists QA scenarios from .agents/qa/scenarios/*.md and groups them into shards.

    list [--tags smoke] [--exclude destructive] [--area up-next,player] [--json]
    show <id>...                  print scenarios, e.g. up-next#clear-from-the-mini-player
    shards [filters] [--size 6]   JSON shards for the qa-run workflow: one account each, areas kept together

A scenario file has flat frontmatter with defaults (area, account, tags), an optional
context paragraph under the `# Title`, and one `## Scenario` per scenario. Lines right
under a scenario heading can override `account`, add `tags`, or give `setup` and `settings`.
"""
import argparse
import json
import os
import re
import subprocess
import sys

META_KEYS = ("tags", "account", "setup", "settings")
MINUTES_PER_SCENARIO = 4


def scenarios_dir():
    here = os.path.dirname(os.path.abspath(__file__))
    try:
        root = subprocess.check_output(["git", "-C", here, "rev-parse", "--show-toplevel"], text=True).strip()
    except subprocess.CalledProcessError:
        root = os.path.abspath(os.path.join(here, "../../../.."))
    return os.path.join(root, ".agents", "qa", "scenarios")


def slugify(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def split_tags(value):
    return [t.strip() for t in value.split(",") if t.strip()]


def parse_file(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    defaults = {}
    match = re.match(r"---\n(.*?)\n---\n?", text, re.S)
    if match:
        for line in match.group(1).splitlines():
            key, sep, value = line.partition(":")
            if sep:
                defaults[key.strip()] = value.strip()
        text = text[match.end():]
    stem = os.path.splitext(os.path.basename(path))[0]
    parts = re.split(r"^## +(.+?)\s*$", text, flags=re.M)
    context = re.sub(r"^# .*$", "", parts[0], count=1, flags=re.M).strip()
    items = []
    for title, block in zip(parts[1::2], parts[2::2]):
        lines = block.strip("\n").splitlines()
        meta = {}
        while lines and re.match(rf"({'|'.join(META_KEYS)}):", lines[0]):
            key, _, value = lines.pop(0).partition(":")
            meta[key] = value.strip()
        items.append({
            "id": f"{stem}#{slugify(title)}",
            "file": os.path.relpath(path, os.path.dirname(os.path.dirname(os.path.dirname(scenarios_dir())))),
            "area": defaults.get("area", stem),
            "title": title,
            "account": meta.get("account") or defaults.get("account", "signed-out"),
            "tags": sorted(set(split_tags(defaults.get("tags", "")) + split_tags(meta.get("tags", "")))),
            "setup": meta.get("setup", ""),
            "settings": meta.get("settings", ""),
            "body": "\n".join(lines).strip(),
            "context": context,
        })
    return items


def load(args):
    root = scenarios_dir()
    items = []
    for name in sorted(os.listdir(root)):
        if name.endswith(".md") and not name.startswith(("_", "README")):
            items += parse_file(os.path.join(root, name))
    if getattr(args, "area", None):
        areas = set(split_tags(args.area))
        items = [i for i in items if i["id"].split("#")[0] in areas]
    if getattr(args, "tags", None):
        wanted = set(split_tags(args.tags))
        items = [i for i in items if wanted & set(i["tags"])]
    if getattr(args, "exclude", None):
        unwanted = set(split_tags(args.exclude))
        items = [i for i in items if not unwanted & set(i["tags"])]
    return items


def render(item, keys=("account", "setup", "settings")):
    lines = [f"### {item['title']} ({item['id']})"]
    for key in keys:
        if item[key]:
            lines.append(f"{key}: {item[key]}")
    lines.append(item["body"])
    return "\n".join(lines)


def cmd_list(args):
    items = load(args)
    if args.json:
        print(json.dumps(items, indent=2, ensure_ascii=False))
        return
    for i in items:
        print(f"{i['id']:<60} {i['account']:<11} {','.join(i['tags'])}")
    print(f"{len(items)} scenarios", file=sys.stderr)


def cmd_show(args):
    by_id = {i["id"]: i for i in load(args)}
    for scenario_id in args.ids:
        if scenario_id not in by_id:
            sys.exit(f"error: no scenario {scenario_id}")
        print(render(by_id[scenario_id]) + "\n")


def cmd_shards(args):
    groups = {}
    for item in load(args):
        groups.setdefault((item["account"], item["settings"], item["id"].split("#")[0]), []).append(item)
    chunks = []
    for (account, settings, _), items in groups.items():
        chunks += [((account, settings), items[i:i + args.size]) for i in range(0, len(items), args.size)]
    bins = []
    for key, chunk in sorted(chunks, key=lambda c: -len(c[1])):
        target = next((b for b in bins if b[0] == key and len(b[1]) + len(chunk) <= args.size), None)
        if target:
            target[1].extend(chunk)
        else:
            bins.append((key, list(chunk)))
    shards, seen = [], {}
    for (account, settings), items in bins:
        areas = list(dict.fromkeys(i["area"] for i in items))
        stems = list(dict.fromkeys(i["id"].split("#")[0] for i in items))
        base = "-".join(stems[:2]) + ("-etc" if len(stems) > 2 else "") + f"-{account}" + (f"-{slugify(settings)}" if settings else "")
        seen[base] = seen.get(base, 0) + 1
        briefs = []
        for stem in stems:
            group = [i for i in items if i["id"].startswith(stem + "#")]
            context = group[0]["context"]
            briefs.append(f"## {group[0]['area']}\n\n" + (f"{context}\n\n" if context else "") + "\n\n".join(render(i, keys=("setup",)) for i in group))
        shards.append({
            "id": base + (f"-{seen[base]}" if seen[base] > 1 else ""),
            "title": f"{', '.join(areas)} ({account}{', ' + settings if settings else ''})",
            "account": account,
            "settings": settings or "default",
            "minutes": MINUTES_PER_SCENARIO * len(items) + 5,
            "destructive": any("destructive" in i["tags"] for i in items),
            "scenarios": [i["id"] for i in items],
            "brief": "\n\n".join(briefs),
        })
    print(json.dumps(shards, indent=2, ensure_ascii=False))
    print(f"{len(shards)} shards, {sum(len(s['scenarios']) for s in shards)} scenarios, ~{sum(s['minutes'] for s in shards)} agent-minutes", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    def filters(p):
        p.add_argument("--tags", help="any of these, comma-separated")
        p.add_argument("--exclude", help="none of these, comma-separated")
        p.add_argument("--area", help="file names without .md, comma-separated")

    p = sub.add_parser("list")
    filters(p)
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_list)

    p = sub.add_parser("show")
    p.add_argument("ids", nargs="+")
    p.set_defaults(func=cmd_show)

    p = sub.add_parser("shards")
    filters(p)
    p.add_argument("--size", type=int, default=6, help="max scenarios per shard (default 6)")
    p.set_defaults(func=cmd_shards)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
