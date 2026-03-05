#requires -Version 5.1
[CmdletBinding()]
param(
  [string]$ServiceName = "AIGirl-Backend",

  # Preview = только показать, Apply = применить изменения
  [ValidateSet("Preview","Apply")]
  [string]$Mode = "Preview",

  # Пауза в конце (удобно если запускаешь двойным кликом)
  [switch]$Pause
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-NssmEnvExtra([string]$SvcName) {
  $nssm = Join-Path $env:WINDIR "System32\nssm.exe"
  if (-not (Test-Path -LiteralPath $nssm)) {
    throw "nssm.exe не найден по пути: $nssm"
  }

  $raw = & $nssm get $SvcName AppEnvironmentExtra 2>$null
  if (-not $raw) { return @{} }

  $lines = if ($raw -is [System.Array]) { $raw } else { ($raw -split "`r?`n") }

  $h = @{}
  foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -match "^\s*([^=]+?)\s*=\s*(.*)\s*$") {
      $key = $matches[1].Trim()
      $val = $matches[2]
      $h[$key] = $val
    }
  }
  return $h
}

function Normalize-EnvValue([string]$s, [switch]$NoTrim) {
  if ($null -eq $s) { return $null }

  # Убираем NUL и CR/LF (важно для connection string)
  $t = $s -replace "`0", "" -replace "`r", "" -replace "`n", ""
  if (-not $NoTrim) { $t = $t.Trim() }

  # Снимаем внешние кавычки, если кто-то записал в env
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

function Invoke-SqlDataSet {
  param(
    [Parameter(Mandatory=$true)][string]$ConnectionString,
    [Parameter(Mandatory=$true)][string]$Sql
  )

  Add-Type -AssemblyName System.Data | Out-Null
  $conn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
  $cmd  = $conn.CreateCommand()
  $cmd.CommandTimeout = 0
  $cmd.CommandText = $Sql

  $da = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
  $ds = New-Object System.Data.DataSet

  $conn.Open()
  try {
    [void]$da.Fill($ds)
  }
  finally {
    $da.Dispose()
    $cmd.Dispose()
    $conn.Close()
    $conn.Dispose()
  }

  return $ds
}

function Invoke-SqlNonQuery {
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
    [void]$cmd.ExecuteNonQuery()
  }
  finally {
    $cmd.Dispose()
    $conn.Close()
    $conn.Dispose()
  }
}

function Print-Section([string]$Title) {
  Write-Host ""
  Write-Host ("=" * 90)
  Write-Host $Title
  Write-Host ("=" * 90)
}

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$dir = Join-Path $env:TEMP "AIGirlMigrations"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$transcript = Join-Path $dir "migrate_interactionevents_eventid_$ts.txt"

Start-Transcript -Path $transcript | Out-Null

try {
  Print-Section "0) Читаем DB_* из NSSM (пароль не выводим)"
  $cfg = Get-NssmEnvExtra -SvcName $ServiceName

  $server = Normalize-EnvValue $cfg["DB_SERVER"]
  $db     = Normalize-EnvValue $cfg["DB_NAME"]
  $user   = Normalize-EnvValue $cfg["DB_USER"]
  $pass   = Normalize-EnvValue $cfg["DB_PASSWORD"] -NoTrim

  if ([string]::IsNullOrWhiteSpace($server) -or
      [string]::IsNullOrWhiteSpace($db) -or
      [string]::IsNullOrWhiteSpace($user) -or
      [string]::IsNullOrWhiteSpace($pass)) {
    throw "Не смог прочитать DB_SERVER/DB_NAME/DB_USER/DB_PASSWORD из NSSM AppEnvironmentExtra сервиса '$ServiceName'."
  }

  $cs = New-SqlConnectionString -Server $server -Database $db -User $user -Password $pass
  Write-Host ("Target SQL: {0}  DB: {1}  User: {2}" -f $server, $db, $user)
  Write-Host ("Mode: {0}" -f $Mode)

  Print-Section "1) BEFORE: Id/EventId в dbo.InteractionEvents"
  $reportSql = @"
SET NOCOUNT ON;

IF OBJECT_ID('dbo.InteractionEvents','U') IS NULL
BEGIN
  SELECT 'dbo.InteractionEvents not found' AS Error;
  RETURN;
END;

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
  cc.name,
  cc.definition,
  cc.is_persisted
FROM sys.computed_columns cc
WHERE cc.object_id = OBJECT_ID('dbo.InteractionEvents')
  AND cc.name IN ('Id','EventId')
ORDER BY cc.name;

SELECT TOP (5)
  Id,
  CASE WHEN COL_LENGTH('dbo.InteractionEvents','EventId') IS NULL THEN NULL ELSE EventId END AS EventId
FROM dbo.InteractionEvents
ORDER BY Id DESC;
"@

  $ds = Invoke-SqlDataSet -ConnectionString $cs -Sql $reportSql
  if ($ds.Tables.Count -ge 1) { $ds.Tables[0] | Format-Table -AutoSize }
  if ($ds.Tables.Count -ge 2) { $ds.Tables[1] | Format-Table -AutoSize }
  if ($ds.Tables.Count -ge 3) { $ds.Tables[2] | Format-Table -AutoSize }

  if ($Mode -eq "Preview") {
    Print-Section "2) PREVIEW: что будет сделано"
    Write-Host @"
План миграции (канон):
  A) Если EventId существует как computed (AS (Id)) — удалим его.
  B) Переименуем физический Id (IDENTITY) -> EventId.
  C) Добавим computed-алиас обратно: Id AS (EventId) для обратной совместимости.

Это решает твой конфликт sp_rename и не ломает текущий Python-код, который использует Id.
Запуск с применением:
  .\migrate_interactionevents_eventid.ps1 -Mode Apply
"@
    return
  }

  Print-Section "2) APPLY: останавливаем сервис (чтобы не было гонок при DDL)"
  try {
    $svc = Get-Service -Name $ServiceName -ErrorAction Stop
    if ($svc.Status -eq "Running") {
      Stop-Service -Name $ServiceName -Force
      Start-Sleep -Seconds 2
    }
    Get-Service -Name $ServiceName | Format-List Status, Name, DisplayName
  }
  catch {
    throw "Не смог остановить сервис '$ServiceName'. Ошибка: $($_.Exception.Message)"
  }

  Print-Section "3) APPLY: миграция dbo.InteractionEvents (Id <-> EventId)"
  $migrateSql = @"
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID('dbo.InteractionEvents','U') IS NULL
BEGIN
  RAISERROR('dbo.InteractionEvents not found', 16, 1);
  RETURN;
END;

DECLARE @hasId BIT = CASE WHEN COL_LENGTH('dbo.InteractionEvents','Id') IS NOT NULL THEN 1 ELSE 0 END;
DECLARE @hasEventId BIT = CASE WHEN COL_LENGTH('dbo.InteractionEvents','EventId') IS NOT NULL THEN 1 ELSE 0 END;

DECLARE @idIsIdentity BIT = 0, @idIsComputed BIT = 0;
DECLARE @eventIsIdentity BIT = 0, @eventIsComputed BIT = 0;

SELECT
  @idIsIdentity    = MAX(CASE WHEN name='Id'      THEN is_identity ELSE 0 END),
  @idIsComputed    = MAX(CASE WHEN name='Id'      THEN is_computed ELSE 0 END),
  @eventIsIdentity = MAX(CASE WHEN name='EventId' THEN is_identity ELSE 0 END),
  @eventIsComputed = MAX(CASE WHEN name='EventId' THEN is_computed ELSE 0 END)
FROM sys.columns
WHERE object_id = OBJECT_ID('dbo.InteractionEvents')
  AND name IN ('Id','EventId');

-- 0) Если уже есть физический EventId (IDENTITY) — просто гарантируем алиас Id
IF @hasEventId = 1 AND @eventIsIdentity = 1
BEGIN
  IF COL_LENGTH('dbo.InteractionEvents','Id') IS NULL
    ALTER TABLE dbo.InteractionEvents ADD Id AS (EventId);
  RETURN;
END;

-- 1) Если EventId существует как computed — удаляем, чтобы освободить имя
IF @hasEventId = 1 AND @eventIsComputed = 1
BEGIN
  ALTER TABLE dbo.InteractionEvents DROP COLUMN EventId;
END
ELSE IF @hasEventId = 1 AND @eventIsComputed = 0
BEGIN
  RAISERROR('EventId существует, но НЕ computed/identity. Скрипт отказывается перетирать неизвестную схему.', 16, 1);
  RETURN;
END;

-- 2) Переименовать физический Id -> EventId
IF COL_LENGTH('dbo.InteractionEvents','Id') IS NOT NULL
   AND COL_LENGTH('dbo.InteractionEvents','EventId') IS NULL
BEGIN
  EXEC sp_rename 'dbo.InteractionEvents.Id', 'EventId', 'COLUMN';
END;

-- 3) Вернуть алиас Id для обратной совместимости
IF COL_LENGTH('dbo.InteractionEvents','Id') IS NULL
BEGIN
  ALTER TABLE dbo.InteractionEvents ADD Id AS (EventId);
END;
"@

  Invoke-SqlNonQuery -ConnectionString $cs -Sql $migrateSql
  Write-Host "OK: миграция выполнена."

  Print-Section "4) AFTER: проверяем результат"
  $ds2 = Invoke-SqlDataSet -ConnectionString $cs -Sql $reportSql
  if ($ds2.Tables.Count -ge 1) { $ds2.Tables[0] | Format-Table -AutoSize }
  if ($ds2.Tables.Count -ge 2) { $ds2.Tables[1] | Format-Table -AutoSize }
  if ($ds2.Tables.Count -ge 3) { $ds2.Tables[2] | Format-Table -AutoSize }

  Print-Section "5) Поднимаем сервис обратно"
  Start-Service -Name $ServiceName
  Start-Sleep -Seconds 2
  Get-Service -Name $ServiceName | Format-List Status, Name, DisplayName

  Print-Section "ГОТОВО"
  Write-Host "Дальше: проверь POST /events (должен вернуть event_id и не ронять backend)."
}
catch {
  Write-Host ""
  Write-Host ("FATAL: {0}" -f $_.Exception.Message)
  Write-Host $_.Exception.ToString()
}
finally {
  try { Stop-Transcript | Out-Null } catch {}
  Write-Host ""
  Write-Host ("Лог скрипта сохранён: {0}" -f $transcript)
  if ($Pause) {
    Read-Host "Press Enter to exit"
  }
}