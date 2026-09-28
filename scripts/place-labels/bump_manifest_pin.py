#!/usr/bin/env python3
"""Bump place-labels.xml expanded-sha in catalog manifest (bot / CI)."""
from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from pathlib import Path

PLACE_LABELS_ARTIFACT_RE = re.compile(
    r'(<artifact\s+name="place-labels\.xml"[\s\S]*?\sexpanded-sha=")([^"]+)(")',
)


def normalize_expanded_sha(expanded_sha: str) -> str:
    return unicodedata.normalize('NFC', expanded_sha.strip())


def bump_place_labels_manifest_pin(manifest_path: Path, expanded_sha: str) -> bool:
    """Set place-labels.xml @expanded-sha; leave other artifacts unchanged."""
    sha = normalize_expanded_sha(expanded_sha)
    text = manifest_path.read_text(encoding='utf-8')
    match = PLACE_LABELS_ARTIFACT_RE.search(text)
    if not match:
        raise ValueError(
            f'artifact name="place-labels.xml" not found in {manifest_path}',
        )
    if match.group(2) == sha:
        return False
    updated = PLACE_LABELS_ARTIFACT_RE.sub(rf'\1{re.escape(sha)}\3', text, count=1)
    manifest_path.write_text(updated, encoding='utf-8')
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--manifest',
        type=Path,
        required=True,
        help='Path to db/apps/catalogs/manifest.xml',
    )
    parser.add_argument(
        '--sha',
        required=True,
        help='Expanded commit SHA to pin (NFC-trimmed)',
    )
    args = parser.parse_args()
    if not args.manifest.is_file():
        print(f'ERROR: manifest missing: {args.manifest}', file=sys.stderr)
        return 1
    try:
        changed = bump_place_labels_manifest_pin(args.manifest, args.sha)
    except ValueError as err:
        print(f'ERROR: {err}', file=sys.stderr)
        return 1
    if changed:
        print(f'Updated place-labels.xml expanded-sha in {args.manifest}')
    else:
        print('place-labels.xml expanded-sha already matches; no change')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
