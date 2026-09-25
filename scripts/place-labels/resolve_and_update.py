#!/usr/bin/env python3
"""Resolve missing external place refs via HTTP APIs (CI only)."""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import read_artifact_items, write_artifact

USER_AGENT = 'BetMas-place-labels-bot/1.0 (BetaMasaheft catalog workflow)'
DEFAULT_DELAY_SEC = 0.35


def http_get_json(url: str) -> dict:
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode('utf-8'))


def resolve_wikidata(ref: str) -> str:
    qid = ref.split(':', 1)[1]
    params = urllib.parse.urlencode({
        'action': 'wbgetentities',
        'ids': qid,
        'props': 'labels',
        'languages': 'en|am|de',
        'format': 'json',
    })
    data = http_get_json(f'https://www.wikidata.org/w/api.php?{params}')
    entity = data.get('entities', {}).get(qid, {})
    labels = entity.get('labels') or {}
    for lang in ('en', 'am', 'de'):
        if lang in labels:
            return labels[lang]['value']
    for label in labels.values():
        return label['value']
    raise LookupError(f'no label for {ref}')


def resolve_pleiades(ref: str) -> str:
    place_id = ref.split(':', 1)[1]
    data = http_get_json(f'https://pleiades.stoa.org/places/{place_id}/json')
    title = (data.get('title') or '').strip()
    if title:
        return title
    names = data.get('names') or []
    if names and names[0].get('romanized'):
        return names[0]['romanized']
    raise LookupError(f'no title for {ref}')


def resolve_geonames(ref: str) -> str:
    username = os.environ.get('GEONAMES_USERNAME', '').strip()
    if not username:
        raise LookupError('GEONAMES_USERNAME not set')
    geoname_id = ref.split(':', 1)[1]
    params = urllib.parse.urlencode({
        'geonameId': geoname_id,
        'username': username,
    })
    data = http_get_json(f'https://secure.geonames.org/getJSON?{params}')
    name = (data.get('name') or data.get('toponymName') or '').strip()
    if name:
        return name
    if data.get('status', {}).get('message'):
        raise LookupError(data['status']['message'])
    raise LookupError(f'no name for {ref}')


def resolve_ref(ref: str) -> str:
    if ref.startswith('wd:'):
        return resolve_wikidata(ref)
    if ref.startswith('pleiades:'):
        return resolve_pleiades(ref)
    if ref.startswith('gn:'):
        return resolve_geonames(ref)
    raise ValueError(f'unsupported ref: {ref}')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--missing', type=Path, required=True)
    parser.add_argument('--artifact', type=Path, required=True)
    parser.add_argument('--delay', type=float, default=DEFAULT_DELAY_SEC)
    args = parser.parse_args()

    if not args.missing.is_file():
        print(f'missing file not found: {args.missing}', file=sys.stderr)
        return 1
    if not args.artifact.is_file():
        print(f'artifact not found: {args.artifact}', file=sys.stderr)
        return 1

    missing = [
        line.strip()
        for line in args.missing.read_text(encoding='utf-8').splitlines()
        if line.strip() and not line.strip().startswith('#')
    ]
    if not missing:
        print('nothing to resolve')
        return 0

    items = read_artifact_items(args.artifact)
    have = {corresp for corresp, _ in items}
    failures: list[str] = []
    successes = 0
    failures_path = Path(__file__).resolve().parent / 'failures.txt'

    for ref in missing:
        if ref in have:
            continue
        try:
            label = resolve_ref(ref)
        except (LookupError, urllib.error.HTTPError, urllib.error.URLError, ValueError) as err:
            failures.append(f'{ref}: {err}')
            continue
        items.append((ref, label))
        have.add(ref)
        successes += 1
        print(f'resolved {ref} -> {label}')
        if args.delay > 0:
            time.sleep(args.delay)

    if successes > 0:
        write_artifact(
            args.artifact,
            items,
            source_note='Updated by resolve_and_update.py (CI network resolve).',
        )
        print(f'artifact updated ({successes} new label(s))')

    if failures:
        print('resolve failures (non-fatal for CI PR):', file=sys.stderr)
        for line in failures:
            print(f'  {line}', file=sys.stderr)
        failures_path.write_text('\n'.join(failures) + '\n', encoding='utf-8')
        print(f'wrote {len(failures)} failure(s) to {failures_path}', file=sys.stderr)
        if successes == 0:
            print(
                'WARN: no refs resolved; artifact unchanged (create-pull-request may skip).',
                file=sys.stderr,
            )
        return 0

    if successes == 0:
        print('no new refs to resolve (already in artifact or empty after filter)')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
