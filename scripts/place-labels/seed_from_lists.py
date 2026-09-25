#!/usr/bin/env python3
"""Seed db/apps/catalogs/place-labels.xml from lists/placeNamesLabels.xml."""
from __future__ import annotations

import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import TEI, is_external_ref, write_artifact


def external_items_from_lists(lists_path: Path) -> list[tuple[str, str]]:
    root = ET.parse(lists_path).getroot()
    items: list[tuple[str, str]] = []
    seen: set[str] = set()
    for item in root.findall(f'.//{TEI}item'):
        corresp = item.get('corresp')
        if not is_external_ref(corresp) or corresp in seen:
            continue
        seen.add(corresp)
        label = ''.join(item.itertext()).strip()
        items.append((corresp, label))
    return items


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lists', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()

    if not args.lists.is_file():
        print(f'lists file not found: {args.lists}', file=sys.stderr)
        return 1

    items = external_items_from_lists(args.lists)
    write_artifact(
        args.out,
        items,
        source_note=f'Seeded from {args.lists} ({len(items)} external refs).',
    )
    print(f'Wrote {len(items)} items to {args.out}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
