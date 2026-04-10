# Ativa o WSL e a Plataforma de Máquina Virtual (requisito habitual do Docker Desktop com motor Linux).
#
# Como correr (se a ExecutionPolicy bloquear .ps1, usa o .cmd):
#   - Clique direito em install-wsl-for-docker.cmd > Executar como administrador
#   - OU PowerShell admin: powershell -NoProfile -ExecutionPolicy Bypass -File "...\install-wsl-for-docker.ps1"
#
# Depois REINICIAR o Windows se o DISM ou o Windows pedirem.

$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Corre este script como Administrador (clique direito no PowerShell > Executar como administrador)."
}

Write-Host "A ativar Microsoft-Windows-Subsystem-Linux..."
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "A ativar VirtualMachinePlatform..."
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Opcional: definir WSL2 como predefinicao (apos reiniciar): wsl --set-default-version 2"
Write-Host "REINICIA o PC se o Windows o solicitar; depois abre Docker Desktop e corre start-aion-docker.ps1"
Write-Host ""
