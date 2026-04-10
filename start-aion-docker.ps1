# Arranca Docker Desktop se necessario e sobe MariaDB + LS + GS + Chat.
# Uso (PowerShell): .\start-aion-docker.ps1
# Requer compose.env (gerado a partir de compose.env.example se em falta).

$ErrorActionPreference = "Stop"
$Root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$DockerExe = $null
foreach ($cand in @(
        "C:\Program Files\Docker\Docker\resources\bin\docker.exe",
        (Get-Command docker -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
    )) {
    if ($cand -and (Test-Path -LiteralPath $cand)) {
        $DockerExe = $cand
        break
    }
}
if (-not $DockerExe) {
    Write-Error "Docker CLI nao encontrado. Instala Docker Desktop e reinicia o terminal."
}

$null = & wsl.exe -l -v 2>&1
if ($LASTEXITCODE -ne 0) {
    $fixCmd = Join-Path $Root "install-wsl-for-docker.cmd"
    $fixPs1 = Join-Path $Root "install-wsl-for-docker.ps1"
    Write-Host ""
    Write-Host "WSL nao esta disponivel (wsl -l -v falhou). Sem WSL, o motor Linux do Docker Desktop devolve erro 500."
    Write-Host "Passos (escolhe um):"
    Write-Host "  A) Clique direito em install-wsl-for-docker.cmd > Executar como administrador"
    Write-Host "  B) PowerShell ADMIN:  powershell -NoProfile -ExecutionPolicy Bypass -File '$fixPs1'"
    Write-Host "  Depois: reinicia o PC se pedido; abre Docker Desktop; corre de novo start-aion-docker.ps1"
    Write-Host "Doc: aion-lightning-work\docs\cursor-handoff-runbook\DOCKER-STACK.md"
    Write-Host ""
    exit 1
}

function Test-DockerEngine {
    $null = & $DockerExe info 2>&1
    return ($LASTEXITCODE -eq 0)
}

if (-not (Test-DockerEngine)) {
    $dd = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path -LiteralPath $dd) {
        Write-Host "A iniciar Docker Desktop..."
        Start-Process -FilePath $dd
    }
    Write-Host "A aguardar Docker Engine (ate 6 min). Aceita os termos na janela do Docker se aparecerem."
    $deadline = (Get-Date).AddMinutes(6)
    $ready = $false
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 5
        if (Test-DockerEngine) {
            $ready = $true
            break
        }
    }
    if (-not $ready) {
        Write-Error "Docker Engine nao ficou online. Abre Docker Desktop manualmente, espera o icone ficar verde e volta a correr este script."
    }
}

$envFile = Join-Path $Root "compose.env"
if (-not (Test-Path -LiteralPath $envFile)) {
    $ex = Join-Path $Root "compose.env.example"
    if (Test-Path -LiteralPath $ex) {
        Copy-Item -LiteralPath $ex -Destination $envFile
        Write-Host "Criei compose.env a partir de compose.env.example - edita AION_WORK_ROOT e MYSQL_ROOT_PASSWORD se precisares."
    }
    else {
        Write-Error "compose.env em falta e compose.env.example tambem."
    }
}

Write-Host "docker compose up -d --build (pasta: $Root)"
Set-Location -LiteralPath $Root
$composeOut = & $DockerExe compose --env-file compose.env up -d --build 2>&1
$composeOut | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
    $txt = $composeOut | Out-String
    if ($txt -match "500 Internal Server Error|dockerDesktopLinuxEngine") {
        Write-Host ""
        Write-Host "Se viste erro 500 no engine: instala WSL com install-wsl-for-docker.ps1 (admin) + reinicio. Ver DOCKER-STACK.md."
    }
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "OK. Estado: docker compose --env-file compose.env ps"
& $DockerExe compose --env-file compose.env ps
Write-Host ""
Write-Host "Login 2107 / Game 7780 / Chat 10241 (mapeados no host). Cliente no mesmo PC: 127.0.0.1; remoto/Tailscale: IP em compose.env (AION_PUBLIC_ADDRESS) e no launcher."
Write-Host "Logs exemplo: docker compose --env-file compose.env logs -f game"
