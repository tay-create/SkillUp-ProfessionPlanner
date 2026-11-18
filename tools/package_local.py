#!/usr/bin/env python3
"""Create a local, installable package for a specific development stage.

Run from anywhere with ``python tools/package_local.py --stage 3``. The staging tree stays
in the system temp folder, and the finished zip stays in ``.release``.
"""

import argparse
from pathlib import Path
from shutil import copy2, rmtree
from tempfile import gettempdir
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parent.parent
CORE = ROOT.parent / "forever-core"
# OneDrive may prevent deleting staged directories. Keep the disposable tree
# outside the synced workspace while writing the finished zip into .release.
RUNTIME_DIRS = ("Core", "Data", "Integrations", "Locales", "UI", "media")
SUPPORT_FILES = {"LICENSE", "README.md", "THIRD_PARTY.md", "CHANGELOG.md"}
EXCLUDE_FILES = {
    "Locales/README.md",
    "Locales/phrases.txt",
    "media/icon.svg",
    "media/icon-400.png",
}


def copy_addon(source: Path, destination: Path, version: str) -> None:
    destination.mkdir(parents=True)

    for directory in RUNTIME_DIRS:
        runtime = source / directory
        if not runtime.is_dir():
            continue
        for file in sorted(runtime.rglob("*")):
            if not file.is_file():
                continue
            relative = file.relative_to(source)
            if any(part.startswith(".") or part == "__pycache__" for part in relative.parts):
                continue
            if relative.as_posix() in EXCLUDE_FILES or file.suffix == ".pyc":
                continue
            target = destination / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            copy2(file, target)

    for file in sorted(source.iterdir()):
        if not file.is_file():
            continue
        if file.name not in SUPPORT_FILES and file.suffix not in {".toc", ".lua", ".xml"}:
            continue
        target = destination / file.name
        if file.suffix == ".toc":
            target.write_text(
                file.read_text(encoding="utf-8-sig").replace("@project-version@", version),
                encoding="utf-8",
            )
        else:
            copy2(file, target)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stage", type=int, choices=(1, 2, 3), default=1)
    stage = parser.parse_args().stage
    release = Path(gettempdir()) / f"ProfessionPlanner-stage{stage}"
    zip_path = ROOT / ".release" / f"ProfessionPlanner-etapa{stage}.zip"

    if not (CORE / "ForeverCore.toc").is_file():
        raise SystemExit("ForeverCore not found beside this project. See docs/PROJETO_PTBR.md.")

    if release.is_dir():
        rmtree(release)

    version = "1.10.1" if stage == 1 else f"1.10.1-etapa{stage}"
    copy_addon(ROOT, release / "ProfessionPlanner", version)
    copy_addon(CORE, release / "ForeverCore", "1.12.1")

    zip_path.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(zip_path, "w") as archive:
        for path in sorted(release.rglob("*")):
            if not path.is_file():
                continue
            info = ZipInfo(path.relative_to(release).as_posix(), date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, path.read_bytes(), compress_type=ZIP_DEFLATED, compresslevel=9)

    print(f"Local package ready: {zip_path}")


if __name__ == "__main__":
    main()
