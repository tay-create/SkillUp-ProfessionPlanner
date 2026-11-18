@echo off
chcp 65001 >nul
cd /d "%~dp0.."
python tools\collect_ingame_logs.py finish
if errorlevel 1 (
    echo Falha ao gerar o relatorio. Verifique se iniciou a coleta antes.
) else (
    echo Relatorio disponivel em .release\ingame-diagnostics\relatorio.md.
)
pause
