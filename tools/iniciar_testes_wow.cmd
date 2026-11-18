@echo off
chcp 65001 >nul
cd /d "%~dp0.."
python tools\collect_ingame_logs.py start
if errorlevel 1 (
    echo Falha ao iniciar o coletor. Verifique se Python esta instalado.
) else (
    echo Coleta iniciada. Agora abra o WoW e siga o roteiro da etapa atual na pasta docs.
)
pause
