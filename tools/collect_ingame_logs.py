"""Compare BugGrabber errors before and after an in-game validation session.

This reads SavedVariables saved by WoW after /reload or logout. Nothing is
injected into the running game and no diagnostic data is sent over the network.
"""

import argparse
import hashlib
import json
import re
from datetime import datetime
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_GAME_ROOT = Path(r"D:\World of Warcraft\_forever_")
DEFAULT_OUTPUT = PROJECT_ROOT / ".release" / "ingame-diagnostics"

RECORD = re.compile(
    r'^\s*\{\s*\n(?=\s*\["message"\]\s*=)(?P<body>.*?)(?=^\s*\},\s*$)',
    re.MULTILINE | re.DOTALL,
)
FIELD = re.compile(
    r'^\s*\["(?P<key>\w+)"\]\s*=\s*(?P<value>"(?:[^"\\]|\\.)*"|[^,\r\n]+),?\s*$',
    re.MULTILINE,
)


def unescape_lua(value):
    if not value.startswith('"'):
        return value

    def decode(match):
        token = match.group(1)
        if token.isdigit():
            return chr(int(token))
        return {"n": "\n", "r": "\r", "t": "\t", '"': '"', "\\": "\\"}.get(token, token)

    return re.sub(r'\\(\d{1,3}|[nrt"\\])', decode, value[1:-1])


def parse_buggrabber(source):
    content = source.read_text(encoding="utf-8", errors="replace")
    session_match = re.search(r'^\["session"\]\s*=\s*(\d+)', content, re.MULTILINE)
    session = int(session_match.group(1)) if session_match else None
    errors = []
    for record in RECORD.finditer(content):
        data = {
            match.group("key"): unescape_lua(match.group("value")) for match in FIELD.finditer(record.group("body"))
        }
        if "message" not in data:
            continue
        signature = "\x00".join((data.get("session", ""), data["message"], data.get("stack", "")))
        errors.append(
            {
                "key": hashlib.sha256(signature.encode("utf-8")).hexdigest(),
                "message": data["message"],
                "stack": data.get("stack", ""),
                "session": data.get("session", ""),
                "count": int(data.get("counter", "1")),
                "time": data.get("time", ""),
            }
        )
    return session, errors


def snapshot(game_root):
    accounts = game_root / "WTF" / "Account"
    sources = sorted(accounts.glob("*/SavedVariables/!BugGrabber.lua"))
    if not sources:
        raise FileNotFoundError(f"Não encontrei !BugGrabber.lua em {accounts}")

    errors = []
    sessions = []
    mtimes = []
    for source in sources:
        session, records = parse_buggrabber(source)
        sessions.append(session)
        mtimes.append(source.stat().st_mtime)
        errors.extend(records)

    versions = {}
    for addon in ("ProfessionPlanner", "ForeverCore", "!BugGrabber", "BugSack"):
        toc = game_root / "Interface" / "AddOns" / addon / f"{addon}.toc"
        if not toc.exists():
            versions[addon] = "ausente"
            continue
        match = re.search(r"^## Version:\s*(.+)$", toc.read_text(encoding="utf-8", errors="replace"), re.MULTILINE)
        versions[addon] = match.group(1) if match else "instalado (versão não informada)"

    frame_xml = game_root / "Logs" / "FrameXML.log"
    return {
        "captured_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "sessions": sessions,
        "last_buggrabber_write": max(mtimes),
        "errors": errors,
        "versions": versions,
        "frame_xml_size": frame_xml.stat().st_size if frame_xml.exists() else 0,
    }


def as_markdown(baseline, current, new_errors, frame_lines):
    lines = [
        "# Diagnóstico da Etapa 1 — WoW Forever",
        "",
        f"Coleta inicial — {baseline['captured_at']}",
        f"Coleta final — {current['captured_at']}",
        f"Erros Lua novos — {sum(error['new_count'] for error in new_errors)} ({len(new_errors)} registros)",
        "",
        "## Versões instaladas ao final",
        "",
    ]
    lines.extend(f"- {name} — {version}" for name, version in current["versions"].items())
    lines.extend(["", "## Erros novos capturados pelo BugGrabber", ""])
    if new_errors:
        for index, error in enumerate(new_errors[:100], start=1):
            lines.append(f"### Erro {index} — {error['new_count']} ocorrência(s)")
            lines.extend(["", "```text", error["message"], error["stack"], "```", ""])
        if len(new_errors) > 100:
            lines.append(f"Mais {len(new_errors) - 100} registros disponíveis em errors.json.")
    else:
        lines.append("Nenhum erro novo registrado.")
    if frame_lines:
        lines.extend(["", "## Novas linhas de FrameXML.log", "", "```text"])
        lines.extend(frame_lines[-150:])
        lines.extend(["```", ""])
    if current["last_buggrabber_write"] <= baseline["last_buggrabber_write"]:
        lines.extend(
            ["", "**Atenção:** o arquivo do BugGrabber não mudou. Use `/reload` no jogo e execute `finish` novamente."]
        )
    lines.extend(
        [
            "",
            "## Resultado manual",
            "",
            "Preencha os testes em `docs/TESTES_ETAPA1_WOW.md` e informe quais passaram ou falharam.",
            "",
        ]
    )
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("start", "finish"))
    parser.add_argument("--game-root", type=Path, default=DEFAULT_GAME_ROOT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    baseline_path = output / "baseline.json"
    current = snapshot(args.game_root)

    if args.action == "start":
        baseline_path.write_text(json.dumps(current, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Linha de base salva em {baseline_path}")
        print(f"Registros existentes: {len(current['errors'])}. Versões: {current['versions']}")
        return

    if not baseline_path.exists():
        raise FileNotFoundError("Execute primeiro: python tools/collect_ingame_logs.py start")
    baseline = json.loads(baseline_path.read_text(encoding="utf-8"))
    previous_counts = {error["key"]: error["count"] for error in baseline["errors"]}
    new_errors = []
    for error in current["errors"]:
        increase = error["count"] - previous_counts.get(error["key"], 0)
        if increase > 0:
            new_errors.append({**error, "new_count": increase})

    frame_log = args.game_root / "Logs" / "FrameXML.log"
    frame_lines = []
    if frame_log.exists():
        with frame_log.open("rb") as logfile:
            logfile.seek(min(baseline.get("frame_xml_size", 0), frame_log.stat().st_size))
            frame_lines = logfile.read(131072).decode("utf-8", errors="replace").splitlines()

    (output / "errors.json").write_text(json.dumps(new_errors, ensure_ascii=False, indent=2), encoding="utf-8")
    report = output / "relatorio.md"
    report.write_text(as_markdown(baseline, current, new_errors, frame_lines), encoding="utf-8")
    print(f"Relatório gerado em {report}")
    print(f"Novos erros Lua: {sum(error['new_count'] for error in new_errors)}")
    if current["last_buggrabber_write"] <= baseline["last_buggrabber_write"]:
        print("ATENÇÃO: dados ainda não salvos pelo WoW. Faça /reload e execute finish novamente.")


if __name__ == "__main__":
    main()
