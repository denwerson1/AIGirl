# Patch 001 HF1: fixes PowerShell parsing on Windows PowerShell 5.1
# - renamed variable $env -> $dotenv
# - file is UTF-8 with BOM to display Russian text correctly

[CmdletBinding()]
param(
  [string]$Root = "C:\AIGirl"
)

$ErrorActionPreference = "Stop"

function Require-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Запусти PowerShell ОТ ИМЕНИ АДМИНИСТРАТОРА и повтори."
  }
}

function Info($m){ Write-Host $m -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }

function Parse-EnvFile([string]$Path) {
  $h = @{}
  if (-not (Test-Path $Path)) { return $h }
  foreach($line in Get-Content $Path) {
    $t = $line.Trim()
    if ($t -eq "" -or $t.StartsWith("#")) { continue }
    $idx = $t.IndexOf("=")
    if ($idx -lt 1) { continue }
    $k = $t.Substring(0,$idx).Trim()
    $v = $t.Substring($idx+1).Trim()
    if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1,$v.Length-2) }
    $h[$k] = $v
  }
  return $h
}

function Sql-Exec([string]$ConnectionString, [string]$SqlText) {
  Add-Type -AssemblyName "System.Data"
  $cn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
  $cn.Open()
  try {
    $cmd = $cn.CreateCommand()
    $cmd.CommandTimeout = 0
    $cmd.CommandText = $SqlText
    [void]$cmd.ExecuteNonQuery()
  } finally {
    $cn.Close()
  }
}

Require-Admin

$patchDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $Root "backend"
$comfyDir   = Join-Path $Root "comfyui"
$envFile    = Join-Path $backendDir ".env"

Info "== Patch 001: Traits + Thoughts + Autotune Policy =="
Info "Root: $Root"
Info "PatchDir: $patchDir"

if (-not (Test-Path $Root))    { throw "Не найден Root: $Root" }
if (-not (Test-Path $backendDir)) { throw "Не найден backend: $backendDir" }
if (-not (Test-Path $envFile)) { throw "Не найден .env: $envFile (ожидается $backendDir\.env)" }

$dotenv = Parse-EnvFile $envFile
$dbServer = $dotenv["DB_SERVER"]
$dbName   = $dotenv["DB_NAME"]
$dbUser   = $dotenv["DB_USER"]
$dbPass   = $dotenv["DB_PASSWORD"]

if (-not $dbServer) { throw "DB_SERVER не найден в $envFile" }
if (-not $dbName)   { $dbName = "AIGirl" }

# SQL auth preferred (у вас уже создан admin)
$cs = $null
if ($dbUser -and $dbPass) {
  $cs = "Server=$dbServer;Database=$dbName;User ID=$dbUser;Password=$dbPass;TrustServerCertificate=True;"
} else {
  $cs = "Server=$dbServer;Database=$dbName;Integrated Security=True;TrustServerCertificate=True;"
}

Info "== 1) DB migrate/seed =="
$sqlFile = Join-Path $patchDir "sql\patch1_traits.sql"
if (-not (Test-Path $sqlFile)) { throw "Не найден SQL файл патча: $sqlFile" }

$sqlText = Get-Content $sqlFile -Raw -Encoding UTF8
Sql-Exec -ConnectionString $cs -SqlText $sqlText
Ok "DB: OK (таблицы/параметры/мысли/политики внесены)"

Info "== 2) Backend update =="
$srcApp1 = Join-Path $patchDir "backend\app.py"
$srcMain = Join-Path $patchDir "backend\main.py"
if (-not (Test-Path $srcApp1)) { throw "Не найден файл backend\\app.py в патче" }
if (-not (Test-Path $srcMain)) { throw "Не найден файл backend\\main.py в патче" }

$dstApp  = Join-Path $backendDir "app.py"
$dstMain = Join-Path $backendDir "main.py"

$ts = Get-Date -Format "yyyyMMdd_HHmmss"

if (Test-Path $dstApp)  { Copy-Item $dstApp  "$dstApp.bak_$ts"  -Force }
if (Test-Path $dstMain) { Copy-Item $dstMain "$dstMain.bak_$ts" -Force }

Copy-Item $srcApp1 $dstApp -Force
Copy-Item $srcMain $dstMain -Force
Ok "Backend files updated: app.py / main.py (backup: *.bak_$ts)"

Info "== 3) Backend python deps refresh =="
$backendPy = Join-Path $backendDir "venv\Scripts\python.exe"
if (-not (Test-Path $backendPy)) { throw "Не найден python backend venv: $backendPy" }

& $backendPy -m pip install --upgrade pip wheel
& $backendPy -m pip install -r (Join-Path $backendDir "requirements.txt")
Ok "Backend deps: OK"

Info "== 4) Restart backend service =="
if (Get-Command nssm.exe -ErrorAction SilentlyContinue) {
  & nssm restart AIGirl-Backend | Out-Null
  Ok "Service restarted: AIGirl-Backend"
} else {
  Warn "nssm.exe не найден в PATH. Перезапусти сервис AIGirl-Backend вручную."
}

Info "== 5) Quick checks =="
try {
  $h = Invoke-RestMethod -TimeoutSec 10 "http://127.0.0.1:8001/health"
  Ok ("Health: " + ($h | ConvertTo-Json -Compress))
} catch {
  Warn "Не удалось проверить /health. Если сервис стартует дольше — подожди и проверь вручную: http://127.0.0.1:8001/health"
}

Ok "PATCH 001: DONE"

Write-Host ""
Write-Host "Новые endpoints:" -ForegroundColor Cyan
Write-Host "  GET  http://127.0.0.1:8001/characters" -ForegroundColor Gray
Write-Host "  GET  http://127.0.0.1:8001/characters/nika/traits" -ForegroundColor Gray
Write-Host "  GET  http://127.0.0.1:8001/characters/isha/traits" -ForegroundColor Gray
Write-Host "  POST http://127.0.0.1:8001/characters/nika/traits/set" -ForegroundColor Gray
Write-Host "  GET  http://127.0.0.1:8001/thought_templates/trait.social.empathy" -ForegroundColor Gray
