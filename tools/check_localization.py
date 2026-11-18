#!/usr/bin/env python3
"""Check packaged Lua files for unsupported localization export keywords."""

from pathlib import Path

from forever_tools.pkgmeta import localization_toc_files
from forever_tools.visual_proof import packaged_runtime_files


def main() -> None:
    root = Path.cwd()
    files = {path for path in packaged_runtime_files(root).values() if path.suffix == ".lua"}
    files.update(localization_toc_files(root))

    for path in sorted(files):
        if "@" + "localization" in path.read_text(encoding="utf-8-sig"):
            print(path.relative_to(root))

    print("scan-ok")


if __name__ == "__main__":
    main()
