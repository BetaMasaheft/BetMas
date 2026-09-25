#!/usr/bin/env python3
"""Lightweight tests for place-labels scripts (fixtures only)."""
from __future__ import annotations

import subprocess
import sys
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

DIR = Path(__file__).resolve().parent
ROOT = DIR.parent.parent
FIXTURES = DIR / 'fixtures'


class PlaceLabelsTests(unittest.TestCase):
    def test_seed_from_lists(self) -> None:
        out = FIXTURES / 'out-place-labels.xml'
        if out.exists():
            out.unlink()
        subprocess.check_call([
            sys.executable,
            str(DIR / 'seed_from_lists.py'),
            '--lists', str(FIXTURES / 'mini-lists.xml'),
            '--out', str(out),
        ])
        root = ET.parse(out).getroot()
        items = root.findall('.//{http://www.tei-c.org/ns/1.0}item')
        self.assertEqual(len(items), 2)
        corresps = {el.get('corresp') for el in items}
        self.assertEqual(corresps, {'wd:Q1', 'pleiades:99'})

    def test_scan_missing(self) -> None:
        proc = subprocess.run([
            sys.executable,
            str(DIR / 'scan_missing.py'),
            '--expanded', str(FIXTURES / 'mini-expanded'),
            '--artifact', str(FIXTURES / 'mini-artifact.xml'),
        ], check=True, capture_output=True, text=True)
        missing = proc.stdout.strip().splitlines()
        self.assertEqual(missing, ['wd:Q9'])


if __name__ == '__main__':
    unittest.main()
