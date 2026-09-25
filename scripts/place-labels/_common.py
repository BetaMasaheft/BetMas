"""Shared helpers for place-labels catalog scripts (HP6)."""
from __future__ import annotations

import re
import xml.etree.ElementTree as ET
from pathlib import Path
from xml.sax.saxutils import escape

TEI_NS = 'http://www.tei-c.org/ns/1.0'
TEI = f'{{{TEI_NS}}}'
EXTERNAL_REF_PREFIXES = ('wd:', 'gn:', 'pleiades:')
EXTERNAL_REF_RE = re.compile(
    r'(?:ref|sameAs)="((?:wd:|gn:|pleiades:)[^"]+)"'
)


def is_external_ref(corresp: str | None) -> bool:
    return bool(corresp and corresp.startswith(EXTERNAL_REF_PREFIXES))


def artifact_corresps(artifact_path: Path) -> set[str]:
    root = ET.parse(artifact_path).getroot()
    out: set[str] = set()
    for item in root.findall(f'.//{TEI}item'):
        corresp = item.get('corresp')
        if is_external_ref(corresp):
            out.add(corresp)
    return out


def artifact_is_populated(artifact_path: Path) -> bool:
    return len(artifact_corresps(artifact_path)) > 0


def scan_expanded_refs(expanded_root: Path) -> set[str]:
    refs: set[str] = set()
    for path in expanded_root.rglob('*.xml'):
        if not path.is_file():
            continue
        try:
            text = path.read_text(encoding='utf-8', errors='replace')
        except OSError:
            continue
        refs.update(EXTERNAL_REF_RE.findall(text))
    return refs


def missing_refs(expanded_root: Path, artifact_path: Path) -> list[str]:
    have = artifact_corresps(artifact_path)
    need = scan_expanded_refs(expanded_root)
    return sorted(need - have)


def read_artifact_items(artifact_path: Path) -> list[tuple[str, str]]:
    root = ET.parse(artifact_path).getroot()
    items: list[tuple[str, str]] = []
    for item in root.findall(f'.//{TEI}item'):
        corresp = item.get('corresp')
        if not corresp:
            continue
        label = ''.join(item.itertext()).strip()
        items.append((corresp, label))
    return items


def write_artifact(path: Path, items: list[tuple[str, str]], *, source_note: str) -> None:
    sorted_items = sorted(items, key=lambda row: row[0].lower())
    body_lines = []
    for corresp, label in sorted_items:
        if not is_external_ref(corresp):
            continue
        text = escape(label or corresp)
        body_lines.append(f'      <item corresp="{corresp}">{text}</item>')

    xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<TEI xmlns="http://www.tei-c.org/ns/1.0">
  <teiHeader>
    <fileDesc>
      <titleStmt><title>Place labels (catalog artifact)</title></titleStmt>
      <publicationStmt><p>HP6 place-labels workflow; resolve in CI only.</p></publicationStmt>
      <sourceDesc><p>{escape(source_note)}</p></sourceDesc>
    </fileDesc>
  </teiHeader>
  <text><body><list xml:id="placeLabels">
{chr(10).join(body_lines)}
  </list></body></text>
</TEI>
'''
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(xml, encoding='utf-8')


def load_exceptions(path: Path) -> set[str]:
    if not path.is_file():
        return set()
    out: set[str] = set()
    for line in path.read_text(encoding='utf-8').splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        out.add(line)
    return out
