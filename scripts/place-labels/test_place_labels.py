#!/usr/bin/env python3
"""Lightweight tests for place-labels scripts (fixtures only)."""
from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path
from unittest.mock import patch

DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(DIR))
import bump_manifest_pin  # noqa: E402
import resolve_and_update  # noqa: E402
ROOT = DIR.parent.parent
FIXTURES = DIR / 'fixtures'


class PlaceLabelsTests(unittest.TestCase):
    def test_bump_manifest_pin_place_labels_only(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            manifest = Path(tmp) / 'manifest.xml'
            manifest.write_text(
                FIXTURES.joinpath('mini-manifest.xml').read_text(encoding='utf-8'),
                encoding='utf-8',
            )
            new_sha = 'ccc3333333333333333333333333333333333333333'
            changed = bump_manifest_pin.bump_place_labels_manifest_pin(manifest, new_sha)
            self.assertTrue(changed)
            text = manifest.read_text(encoding='utf-8')
            self.assertIn(f'expanded-sha="{new_sha}"', text)
            self.assertIn('expanded-sha="aaa1111111111111111111111111111111111111111"', text)
            self.assertNotIn('expanded-sha="bbb2222222222222222222222222222222222222222"', text)
            changed_again = bump_manifest_pin.bump_place_labels_manifest_pin(
                manifest,
                f'  {new_sha}  ',
            )
            self.assertFalse(changed_again)

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

    def test_resolve_and_update_partial_failure_exits_zero(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            missing = tmp_path / 'missing.txt'
            artifact = tmp_path / 'artifact.xml'
            missing.write_text('wd:Q9\nwd:Qbad\n', encoding='utf-8')
            artifact.write_text(FIXTURES.joinpath('mini-artifact.xml').read_text(encoding='utf-8'))

            def fake_resolve(ref: str) -> str:
                if ref == 'wd:Q9':
                    return 'Resolved Nine'
                raise LookupError('mock failure')

            failures_file = DIR / 'failures.txt'
            if failures_file.exists():
                failures_file.unlink()

            with patch.object(resolve_and_update, 'resolve_ref', side_effect=fake_resolve):
                with patch.object(
                    sys,
                    'argv',
                    [
                        'resolve_and_update.py',
                        '--missing', str(missing),
                        '--artifact', str(artifact),
                        '--delay', '0',
                    ],
                ):
                    code = resolve_and_update.main()

            self.assertEqual(code, 0)
            root = ET.parse(artifact).getroot()
            labels = {
                el.get('corresp'): ''.join(el.itertext()).strip()
                for el in root.findall('.//{http://www.tei-c.org/ns/1.0}item')
            }
            self.assertEqual(labels.get('wd:Q9'), 'Resolved Nine')
            self.assertTrue(failures_file.is_file())
            self.assertIn('wd:Qbad', failures_file.read_text(encoding='utf-8'))
            failures_file.unlink()


if __name__ == '__main__':
    unittest.main()
