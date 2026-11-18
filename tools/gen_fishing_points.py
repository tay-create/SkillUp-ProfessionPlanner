#!/usr/bin/env python3
"""Generate compact, offline fishing points from GatherLite's WoW Forever reports.

Run from the repository root with ``python tools/gen_fishing_points.py``.
Pass ``--input fish.json`` to regenerate from a previously downloaded source.
"""

import argparse
import json
import re
from pathlib import Path
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parent.parent
GATHERLITE_COMMIT = "4ace5b625a1ee724ca912262509f641b4f35992a"
SOURCE_URL = f"https://raw.githubusercontent.com/Wuild/GatherLite/{GATHERLITE_COMMIT}/tools/wowhead/fish.json"


def fishing_reagents():
    sources = (ROOT / "Data/Sources.lua").read_text(encoding="utf-8")
    section = sources.split("ns.FishingZones = {", 1)[1].split("\n}", 1)[0]
    return {str(item) for item in re.findall(r"^\s*\[(\d+)\] = \{", section, re.M)}


def generate(data):
    lines = [
        "-- Reported catches from WoW Forever item pages, as collected by GatherLite.",
        "-- These points are historical catch reports, not guaranteed active fishing pools.",
        f"-- Source revision: Wuild/GatherLite {GATHERLITE_COMMIT} (MIT; see THIRD_PARTY.md).",
        "local _, ns = ...",
        "-- [fish item] = { [uiMapID] = { x, y, ... } }, in thousandths of a map.",
        "-- stylua: ignore",
        "ns.FishingPoints = {",
    ]
    total_points = 0
    total_fish = 0
    for item in sorted(fishing_reagents(), key=int):
        entry = data["items"].get(item, {})
        maps = entry.get("maps", {})
        written = []
        for map_id in sorted(maps, key=int):
            coords = maps[map_id]
            if len(coords) % 2 or any(
                not isinstance(value, int) or value < 0 or value > 1_000_000 or value % 1000
                for value in coords
            ):
                raise ValueError(f"Invalid coordinates for fish {item} on map {map_id}")
            if coords:
                compact = [str(value // 1000) for value in coords]
                written.append(f"        [{map_id}] = {{ {', '.join(compact)} }},")
                total_points += len(coords) // 2
        if written:
            total_fish += 1
            lines.append(f"    [{item}] = {{")
            lines.extend(written)
            lines.append("    },")
    lines.append("}")
    output = ROOT / "Data/FishingPoints.lua"
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {total_points} fishing reports for {total_fish} fish to {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, help="Use a local GatherLite fish.json file")
    args = parser.parse_args()
    if args.input:
        source = args.input.read_text(encoding="utf-8")
    else:
        with urlopen(SOURCE_URL, timeout=30) as response:
            source = response.read().decode("utf-8")
    generate(json.loads(source))
