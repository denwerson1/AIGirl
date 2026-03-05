#requires -Version 5.1
[CmdletBinding()]
param(
  [string]$ServiceName  = "AIGirl-Backend",
  [string]$Root         = "C:\AIGirl",
  [string]$BaseUrl      = "http://127.0.0.1:8001",
  [ValidateSet("nika","isha")]
  [string]$CharacterKey = "nika",
  [switch]$Pause
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Print-Section([string]$Title) {
  Write-Host ""
  Write-Host ("=" * 90)
  Write-Host $Title
  Write-Host ("=" * 90)
}

function New-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

function Get-NssmEnvExtra([string]$SvcName) {
  $nssm = Join-Path $env:WINDIR "System32\nssm.exe"
  if (-not (Test-Path -LiteralPath $nssm)) { throw "nssm.exe не найден: $nssm" }

  $raw = & $nssm get $SvcName AppEnvironmentExtra 2>$null
  if (-not $raw) { return @{} }

  $lines = if ($raw -is [System.Array]) { $raw } else { ($raw -split "`r?`n") }

  $h = @{}
  foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -match "^\s*([^=]+?)\s*=\s*(.*)\s*$") {
      $h[$matches[1].Trim()] = $matches[2]
    }
  }
  return $h
}

function Normalize-EnvValue([string]$s, [switch]$NoTrim) {
  if ($null -eq $s) { return $null }

  # критично: вычищаем NUL и CR/LF (ломают connection string)
  $t = $s -replace "`0","" -replace "`r","" -replace "`n",""

  if (-not $NoTrim) { $t = $t.Trim() }

  # снимаем внешние кавычки, если кто-то записал их в env
  if ($t.Length -ge 2) {
    if (($t.StartsWith('"') -and $t.EndsWith('"')) -or ($t.StartsWith("'") -and $t.EndsWith("'"))) {
      $t = $t.Substring(1, $t.Length - 2)
    }
  }
  return $t
}

function New-SqlConnectionString {
  param(
    [Parameter(Mandatory=$true)][string]$Server,
    [Parameter(Mandatory=$true)][string]$Database,
    [Parameter(Mandatory=$true)][string]$User,
    [Parameter(Mandatory=$true)][string]$Password
  )

  Add-Type -AssemblyName System.Data | Out-Null
  $b = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
  $b["Data Source"] = $Server
  $b["Initial Catalog"] = $Database
  $b["User ID"] = $User
  $b["Password"] = $Password

  $b["Encrypt"] = $false
  $b["TrustServerCertificate"] = $true
  $b["Persist Security Info"] = $false

  return $b.ConnectionString
}

function Invoke-SqlQuery {
  param(
    [Parameter(Mandatory=$true)][string]$ConnectionString,
    [Parameter(Mandatory=$true)][string]$Sql
  )

  Add-Type -AssemblyName System.Data | Out-Null
  $conn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
  $cmd  = $conn.CreateCommand()
  $cmd.CommandTimeout = 0
  $cmd.CommandText = $Sql

  $conn.Open()
  try {
    $da = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
    $ds = New-Object System.Data.DataSet
    [void]$da.Fill($ds)
    return $ds.Tables
  }
  finally {
    $cmd.Dispose()
    $conn.Close()
    $conn.Dispose()
  }
}

function Invoke-HttpJsonPostUtf8 {
  param(
    [Parameter(Mandatory=$true)][string]$Uri,
    [Parameter(Mandatory=$true)][object]$BodyObject
  )

  $json  = ($BodyObject | ConvertTo-Json -Depth 10 -Compress)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

  try {
    $resp = Invoke-WebRequest -Method Post -Uri $Uri `
      -ContentType "application/json; charset=utf-8" `
      -Body $bytes -UseBasicParsing -TimeoutSec 15
    return @{
      StatusCode = [int]$resp.StatusCode
      Raw        = $resp.Content
      Json       = ($resp.Content | ConvertFrom-Json)
    }
  }
  catch {
    $r = $_.Exception.Response
    $code = $null
    $body = $null

    if ($r) {
      try { $code = [int]$r.StatusCode } catch {}
      try {
        if ($r.GetResponseStream()) {
          $sr = New-Object System.IO.StreamReader($r.GetResponseStream())
          $body = $sr.ReadToEnd()
          $sr.Close()
        }
      } catch {}
    }

    Write-Host ""
    Write-Host "HTTP ERROR: $($code)"
    if ($body) {
      Write-Host "--- response body ---"
      Write-Host $body
      Write-Host "---------------------"
    } else {
      Write-Host "(нет тела ответа; см. backend_stderr.log)"
    }

    throw
  }
}

# -------------------- main --------------------
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$dir = Join-Path $env:TEMP "AIGirlSmoke"
New-Dir $dir
$transcript = Join-Path $dir "smoke_events_$ts.txt"

Start-Transcript -Path $transcript | Out-Null

try {
  Print-Section "0) Service status"
  $svc = Get-Service -Name $ServiceName -ErrorAction Stop
  $svc | Format-List Name, Status, StartType, ServiceType

  Print-Section "1) Read DB_* from NSSM (password not shown)"
  $cfg = Get-NssmEnvExtra -SvcName $ServiceName

  $server = Normalize-EnvValue $cfg["DB_SERVER"]
  $db     = Normalize-EnvValue $cfg["DB_NAME"]
  $user   = Normalize-EnvValue $cfg["DB_USER"]
  $pass   = Normalize-EnvValue $cfg["DB_PASSWORD"] -NoTrim

  if ([string]::IsNullOrWhiteSpace($server) -or
      [string]::IsNullOrWhiteSpace($db)     -or
      [string]::IsNullOrWhiteSpace($user)   -or
      [string]::IsNullOrWhiteSpace($pass)) {
    throw "Не смог прочитать DB_SERVER/DB_NAME/DB_USER/DB_PASSWORD из NSSM AppEnvironmentExtra сервиса '$ServiceName'."
  }

  Write-Host ("Target SQL: {0}  DB: {1}  User: {2}" -f $server, $db, $user)

  $cs = New-SqlConnectionString -Server $server -Database $db -User $user -Password $pass

  Print-Section "2) DB check: dbo.InteractionEvents (Id/EventId identity/computed)"
  $sqlSchema = @"
SET NOCOUNT ON;

SELECT
  c.name,
  c.column_id,
  c.is_identity,
  c.is_computed,
  t.name AS type_name
FROM sys.columns c
JOIN sys.types t
  ON c.user_type_id = t.user_type_id AND c.system_type_id = t.system_type_id
WHERE c.object_id = OBJECT_ID('dbo.InteractionEvents')
  AND c.name IN ('Id','EventId')
ORDER BY c.column_id;

SELECT
  c.name,
  cc.definition,
  cc.is_persisted
FROM sys.columns c
JOIN sys.computed_columns cc
  ON cc.object_id = c.object_id AND cc.column_id = c.column_id
WHERE c.object_id = OBJECT_ID('dbo.InteractionEvents')
  AND c.name IN ('Id','EventId')
ORDER BY c.name;

SELECT TOP (5)
  Id, EventId, CreatedAt, Platform, Channel, ConversationKey, CharacterKey, EventType, Lang
FROM dbo.InteractionEvents
ORDER BY EventId DESC;
"@

  $tables = Invoke-SqlQuery -ConnectionString $cs -Sql $sqlSchema
  $i = 0
  foreach ($t in $tables) {
    $i++
    Write-Host ""
    Write-Host ("--- Result set #{0} ---" -f $i)
    $t | Format-Table -AutoSize
  }

  Print-Section "3) API check: GET /health"
  $h = Invoke-WebRequest -Method Get -Uri "$BaseUrl/health" -UseBasicParsing -TimeoutSec 10
  Write-Host $h.Content

  Print-Section "4) API check: POST /events (UTF-8)"
  $payload = [ordered]@{
    platform      = "admin"
    channel       = "dm"
    character_key = $CharacterKey
    event_type    = "inbound_message"
    lang          = "ru"
    text          = "Smoke test $(Get-Date -Format s)"
    sentiment     = 0.3
    engagement    = 0.6
  }

  $post = Invoke-HttpJsonPostUtf8 -Uri "$BaseUrl/events" -BodyObject $payload
  Write-Host ("HTTP {0}" -f $post.StatusCode)
  Write-Host $post.Raw

  Print-Section "5) DB verify: last inserted event"
  $sqlLast = @"
SET NOCOUNT ON;

SELECT TOP (10)
  EventId, Id, CreatedAt, Platform, Channel, CharacterKey, EventType, Lang, PayloadJson
FROM dbo.InteractionEvents
ORDER BY EventId DESC;
"@
  $t2 = Invoke-SqlQuery -ConnectionString $cs -Sql $sqlLast
  $t2[0] | Format-Table -AutoSize

  Print-Section "6) Tail logs (stdout/stderr/api)"
  $logDir = Join-Path $Root "logs"
  $paths = @(
    (Join-Path $logDir "backend_stderr.log"),
    (Join-Path $logDir "backend_stdout.log"),
    (Join-Path $logDir "backend_api.log")
  )

  foreach ($p in $paths) {
    Write-Host ""
    Write-Host ("--- {0} ---" -f $p)
    if (Test-Path -LiteralPath $p) {
      Get-Item -LiteralPath $p | Format-List FullName, Length, LastWriteTime
      Get-Content -LiteralPath $p -Tail 60 -ErrorAction SilentlyContinue
    } else {
      Write-Host "NOT FOUND"
    }
  }

  Print-Section "DONE"
  Write-Host "Если POST /events снова даст 500 — в этом выводе будет тело ошибки + хвост stderr."
}
catch {
  Write-Host ""
  Write-Host "FATAL: $($_.Exception.Message)"
  Write-Host $_.Exception.ToString()
}
finally {
  try { Stop-Transcript | Out-Null } catch {}
  Write-Host ""
  Write-Host "Transcript saved: $transcript"
  if ($Pause) { Read-Host "Press Enter to exit" | Out-Null }
}