@echo off
REM Executar este ficheiro com clique direito > Executar como administrador
REM (nao depende da ExecutionPolicy do PowerShell)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-wsl-for-docker.ps1"
echo.
pause
