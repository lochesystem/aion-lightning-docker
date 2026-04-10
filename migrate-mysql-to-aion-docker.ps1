# Copia al_server_ls + al_server_gs de outro MySQL/MariaDB para o aion-mariadb (Docker).
#
# Modo A — a partir de um servidor remoto ou outra instância:
#   .\migrate-mysql-to-aion-docker.ps1 -SourceHost "192.168.1.10" -SourceUser "root" -SourcePassword "segredo"
#
# Modo B — só importar um .sql já gerado (mysqldump com --databases al_server_ls al_server_gs):
#   .\migrate-mysql-to-aion-docker.ps1 -SqlDumpPath "C:\backups\aion.sql"
#
# MySQL/MariaDB no mesmo PC que o Docker (fora do contentor): usa -SourceHost "host.docker.internal"
#
# Requer: Docker em execução, contentor aion-mariadb; compose.env com MYSQL_ROOT_PASSWORD.
# O dump usa a imagem mariadb:10.11 (cliente); --column-statistics=0 evita erro ao importar no MariaDB.

param(
    [string] $SourceHost,
    [int] $SourcePort = 3306,
    [string] $SourceUser,
    [string] $SourcePassword,
    [string] $SqlDumpPath,
    [switch] $SkipGrants
)

$ErrorActionPreference = "Stop"
$Root = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$envFile = Join-Path $Root "compose.env"
if (-not (Test-Path -LiteralPath $envFile)) { Write-Error "compose.env em falta em $Root" }

$kv = @{}
Get-Content -LiteralPath $envFile -Encoding UTF8 | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '=' } | ForEach-Object {
    $i = $_.IndexOf('=')
    if ($i -ge 1) { $kv[$_.Substring(0, $i).Trim()] = $_.Substring($i + 1).Trim() }
}
if (-not $kv.ContainsKey("MYSQL_ROOT_PASSWORD")) { Write-Error "MYSQL_ROOT_PASSWORD em compose.env" }
$rootPw = $kv["MYSQL_ROOT_PASSWORD"]

$docker = if (Test-Path "C:\Program Files\Docker\Docker\resources\bin\docker.exe") {
    "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
} else { "docker" }

$running = & $docker ps --filter "name=aion-mariadb" --format "{{.Names}}" 2>&1
if ($running -ne "aion-mariadb") { Write-Error "aion-mariadb não está Up. Corre: docker compose --env-file compose.env up -d" }

function Import-SqlFile([string] $path) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Ficheiro em falta: $path" }
    Write-Host "A importar para o MariaDB Docker: $path" -ForegroundColor Cyan
    $fs = [System.IO.File]::OpenRead((Resolve-Path -LiteralPath $path).Path)
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $docker
        $psi.Arguments = "exec -i -e MYSQL_PWD=$rootPw aion-mariadb mysql -uroot"
        $psi.UseShellExecute = $false
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardError = $true
        $psi.RedirectStandardOutput = $true
        $psi.CreateNoWindow = $true
        $p = [System.Diagnostics.Process]::Start($psi)
        $fs.CopyTo($p.StandardInput.BaseStream)
        $p.StandardInput.Close()
        $err = $p.StandardError.ReadToEnd()
        $out = $p.StandardOutput.ReadToEnd()
        $p.WaitForExit()
        if ($p.ExitCode -ne 0) { throw "mysql import falhou (exit $($p.ExitCode)): $err" }
    } finally {
        $fs.Dispose()
    }
}

if ($SqlDumpPath) {
    if ($SourceHost -or $SourceUser -or $SourcePassword) {
        Write-Warning "SqlDumpPath definido — ignorando parâmetros de origem."
    }
    Import-SqlFile $SqlDumpPath
} else {
    if (-not $SourceHost -or -not $SourceUser -or $null -eq $SourcePassword) {
        Write-Error "Define SqlDumpPath OU (-SourceHost, -SourceUser, -SourcePassword)."
    }

    $tmp = Join-Path $env:TEMP ("aion-migrate-" + [Guid]::NewGuid().ToString() + ".sql")
    $tmpErr = "$tmp.stderr.txt"
    Write-Host "A fazer dump em $tmp ..." -ForegroundColor Cyan
    try {
        $dumpArgs = @(
            "run", "--rm",
            "-e", "MYSQL_PWD=$SourcePassword",
            "mariadb:10.11",
            "mariadb-dump",
            "-h", $SourceHost,
            "-P", "$SourcePort",
            "-u", $SourceUser,
            "--databases", "al_server_ls", "al_server_gs",
            "--single-transaction",
            "--quick",
            "--column-statistics=0"
        )
        $p = Start-Process -FilePath $docker -ArgumentList $dumpArgs -Wait -NoNewWindow -PassThru `
            -RedirectStandardOutput $tmp -RedirectStandardError $tmpErr
        if ($p.ExitCode -ne 0) {
            $errText = if (Test-Path $tmpErr) { Get-Content -LiteralPath $tmpErr -Raw } else { "" }
            throw "mariadb-dump falhou (exit $($p.ExitCode)): $errText"
        }
        $info = Get-Item -LiteralPath $tmp
        if ($info.Length -lt 500) {
            throw "Dump muito pequeno ($($info.Length) bytes) — verifica host/user/password e se as bases existem na origem."
        }
        Import-SqlFile $tmp
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpErr -Force -ErrorAction SilentlyContinue
    }
}

if (-not $SkipGrants) {
    Write-Host "A garantir utilizador emu aion..." -ForegroundColor Cyan
    $bootstrap = @"
CREATE USER IF NOT EXISTS 'aion'@'%' IDENTIFIED VIA mysql_native_password USING PASSWORD('aionlocal');
GRANT ALL PRIVILEGES ON al_server_ls.* TO 'aion'@'%';
GRANT ALL PRIVILEGES ON al_server_gs.* TO 'aion'@'%';
FLUSH PRIVILEGES;
"@
    $bootstrap | & $docker exec -i -e "MYSQL_PWD=$rootPw" aion-mariadb mysql -uroot
    if ($LASTEXITCODE -ne 0) { throw "GRANT aion falhou" }
}

Write-Host ""
Write-Host "Migrado. Contagem de tabelas:" -ForegroundColor Green
& $docker exec -e "MYSQL_PWD=$rootPw" aion-mariadb mysql -uroot -N -e "SELECT table_schema, COUNT(*) FROM information_schema.tables WHERE table_schema IN ('al_server_ls','al_server_gs') GROUP BY table_schema;"
