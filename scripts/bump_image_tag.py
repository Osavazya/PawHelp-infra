#!/usr/bin/env python3
import argparse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--file", required=True)
parser.add_argument("--component", required=True, choices=["backend", "frontend"])
parser.add_argument("--tag")
parser.add_argument("--repository")
args = parser.parse_args()

if not args.tag and not args.repository:
    raise SystemExit("Provide --tag, --repository, or both")

path = Path(args.file)
lines = path.read_text().splitlines()
section = "pawhelp-backend:" if args.component == "backend" else "pawhelp-frontend:"
inside_section = False
inside_image = False
changed = False
out = []

for line in lines:
    stripped = line.strip()
    if line.startswith(section):
        inside_section = True
        inside_image = False
    elif inside_section and line and not line.startswith(" "):
        inside_section = False
        inside_image = False

    if inside_section and stripped == "image:":
        inside_image = True
    elif inside_section and inside_image and args.repository and stripped.startswith("repository:"):
        indent = line[: len(line) - len(line.lstrip())]
        line = f"{indent}repository: {args.repository}"
        changed = True
    elif inside_section and inside_image and args.tag and stripped.startswith("tag:"):
        indent = line[: len(line) - len(line.lstrip())]
        line = f"{indent}tag: {args.tag}"
        changed = True
        if not args.repository:
            inside_image = False

    out.append(line)

if not changed:
    raise SystemExit(f"Could not update image fields for {args.component} in {path}")

path.write_text("\n".join(out) + "\n")
