#!/usr/bin/env python3
"""Print external place refs in expanded TEI missing from place-labels.xml."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import missing_refs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--expanded', type=Path, required=True)
    parser.add_argument('--artifact', type=Path, required=True)
    args = parser.parse_args()

    if not args.expanded.is_dir():
        print(f'expanded root not found: {args.expanded}', file=sys.stderr)
        return 1
    if not args.artifact.is_file():
        print(f'artifact not found: {args.artifact}', file=sys.stderr)
        return 1

    for ref in missing_refs(args.expanded, args.artifact):
        print(ref)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
