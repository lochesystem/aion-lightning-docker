# Importa al_server_ls.sql e al_server_gs.sql para o MariaDB do Docker (schema + dados do repo Aion).
# Usa os ficheiros já montados em /mnt/aion-import/ (mesmos binds do docker-compose.yml).
#
# Uso (PowerShell, na pasta deste repo):
#   .\import-aion-databases.ps1
#   .\import-aion-databases.ps1 -FromHostPaths   # se a montagem no contentor falhar, lê do AION_WORK_ROOT no disco
#
# Requer: contentor aion-mariadb em execução; compose.env com MYSQL_ROOT_PASSWORD.

param(
    [switch] $FromHostPaths
)

$ErrorActionPreference = "Stop"
$Root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$envFile = Join-Path $Root "compose.env"
if (-not (Test-Path -LiteralPath $envFile)) {
    Write-Error "compose.env em falta em $Root"
}

$envLines = Get-Content -LiteralPath $envFile -Encoding UTF8 | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '=' }
$kv = @{}
foreach ($line in $envLines) {
    $i = $line.IndexOf('=')
    if ($i -lt 1) { continue }
    $k = $line.Substring(0, $i).Trim()
    $v = $line.Substring($i + 1).Trim()
    $kv[$k] = $v
}

if (-not $kv.ContainsKey("MYSQL_ROOT_PASSWORD")) {
    Write-Error "MYSQL_ROOT_PASSWORD não definido em compose.env"
}
$rootPw = $kv["MYSQL_ROOT_PASSWORD"]

$workRoot = $kv["AION_WORK_ROOT"]
if (-not $workRoot) {
    $workRoot = "C:/Users/adria/Documents/aion-lightning-work"
}

$docker = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
if (-not (Test-Path -LiteralPath $docker)) {
    $docker = "docker"
}

& $docker ps --filter "name=aion-mariadb" --format "{{.Names}}" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "Docker CLI falhou." }
$running = & $docker ps --filter "name=aion-mariadb" --format "{{.Names}}"
if ($running -ne "aion-mariadb") {
    Write-Error "Contentor aion-mariadb não está em execução. Corre: docker compose --env-file compose.env up -d"
}

$sqlBootstrap = @"
CREATE DATABASE IF NOT EXISTS al_server_ls CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS al_server_gs CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER IF NOT EXISTS 'aion'@'%' IDENTIFIED VIA mysql_native_password USING PASSWORD('aionlocal');
GRANT ALL PRIVILEGES ON al_server_ls.* TO 'aion'@'%';
GRANT ALL PRIVILEGES ON al_server_gs.* TO 'aion'@'%';
FLUSH PRIVILEGES;
"@

Write-Host "A preparar bases e utilizador aion..."
$sqlBootstrap | & $docker exec -i -e "MYSQL_PWD=$rootPw" aion-mariadb mysql -uroot
if ($LASTEXITCODE -ne 0) { throw "bootstrap SQL falhou" }

function Import-ViaContainerMount([string] $dbName, [string] $containerPath) {
    Write-Host "A importar $dbName <- $containerPath (dentro do contentor)..."
    $inner = "mysql -uroot $dbName < $containerPath"
    & $docker exec -e "MYSQL_PWD=$rootPw" aion-mariadb sh -c $inner
    if ($LASTEXITCODE -ne 0) { throw "Import falhou: $dbName" }
}

function Import-ViaHostFile([string] $dbName, [string] $hostPath) {
    if (-not (Test-Path -LiteralPath $hostPath)) {
        throw "Ficheiro em falta: $hostPath"
    }
    Write-Host "A importar $dbName <- $hostPath (stream a partir do Windows)..."
    $fs = [System.IO.File]::OpenRead((Resolve-Path -LiteralPath $hostPath).Path)
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $docker
        $psi.Arguments = "exec -i -e MYSQL_PWD=$rootPw aion-mariadb mysql -uroot $dbName"
        $psi.UseShellExecute = $false
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        $p = [System.Diagnostics.Process]::Start($psi)
        $fs.CopyTo($p.StandardInput.BaseStream)
        $p.StandardInput.Close()
        $err = $p.StandardError.ReadToEnd()
        $out = $p.StandardOutput.ReadToEnd()
        $p.WaitForExit()
        if ($p.ExitCode -ne 0) {
            throw "mysql import exit $($p.ExitCode): $err"
        }
    } finally {
        $fs.Dispose()
    }
}

$lsContainer = "/mnt/aion-import/al_server_ls.sql"
$gsContainer = "/mnt/aion-import/al_server_gs.sql"

if (-not $FromHostPaths) {
    $hasLs = & $docker exec aion-mariadb test -f $lsContainer; $okLs = ($LASTEXITCODE -eq 0)
    $hasGs = & $docker exec aion-mariadb test -f $gsContainer; $okGs = ($LASTEXITCODE -eq 0)
    if (-not $okLs -or -not $okGs) {
        Write-Warning "Ficheiros em /mnt/aion-import em falta no contentor. Usa -FromHostPaths ou verifica AION_WORK_ROOT no compose."
        $FromHostPaths = $true
    }
}

if (-not $FromHostPaths) {
    Import-ViaContainerMount "al_server_ls" $lsContainer
    Import-ViaContainerMount "al_server_gs" $gsContainer
} else {
    $base = $workRoot -replace '/', '\'
    $lsHost = Join-Path $base "aion-lightning-2.7\AL-Login\sql\al_server_ls.sql"
    $gsHost = Join-Path $base "aion-lightning-2.7\AL-Game\sql\al_server_gs.sql"
    Import-ViaHostFile "al_server_ls" $lsHost
    Import-ViaHostFile "al_server_gs" $gsHost
}

Write-Host ""
Write-Host "Concluído. Verificação rápida:" -ForegroundColor Green
& $docker exec -e "MYSQL_PWD=$rootPw" aion-mariadb mysql -uroot -N -e "SELECT table_schema, COUNT(*) FROM information_schema.tables WHERE table_schema IN ('al_server_ls','al_server_gs') GROUP BY table_schema;"
