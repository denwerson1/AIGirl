#requires -Version 5.1
[CmdletBinding()]
param(
  [ValidateSet("Preview","Apply")]
  [string]$Mode = "Preview",

  [string]$ServiceName = "AIGirl-Backend",

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

function Get-NssmEnvExtra([string]$SvcName) {
  $nssm = Join-Path $env:WINDIR "System32\nssm.exe"
  if (-not (Test-Path -LiteralPath $nssm)) { throw "nssm.exe not found: $nssm" }

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
  $t = $s -replace "`0","" -replace "`r","" -replace "`n",""
  if (-not $NoTrim) { $t = $t.Trim() }
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
  try { [void]$cmd.ExecuteNonQuery() }
  finally {
    $cmd.Dispose()
    $conn.Close()
    $conn.Dispose()
  }
}

function Invoke-SqlScalar {
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
  try { return $cmd.ExecuteScalar() }
  finally {
    $cmd.Dispose()
    $conn.Close()
    $conn.Dispose()
  }
}

function Invoke-SqlQuery {
  <#
    IMPORTANT:
    Return ALWAYS DataRow[] as a single object (NoEnumerate),
    so .Length works for 0/1/N rows.
  #>
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
  $dt = New-Object System.Data.DataTable
  try { [void]$da.Fill($dt) }
  finally {
    $da.Dispose()
    $cmd.Dispose()
    $conn.Close()
    $conn.Dispose()
  }

  $rows = $dt.Select()
  Write-Output -NoEnumerate $rows
}

# --- transcript ---
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$dir = Join-Path $env:TEMP "AIGirlMigrations"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$transcript = Join-Path $dir "patch003_conversation_logging_$ts.txt"

Start-Transcript -Path $transcript | Out-Null

try {
  Print-Section "Patch003: InteractionEvents -> Users + ConversationMessages (trigger-based)"

  Print-Section "0) Read DB_* from NSSM (password not shown)"
  $cfg = Get-NssmEnvExtra -SvcName $ServiceName
  $server = Normalize-EnvValue $cfg["DB_SERVER"]
  $db     = Normalize-EnvValue $cfg["DB_NAME"]
  $user   = Normalize-EnvValue $cfg["DB_USER"]
  $pass   = Normalize-EnvValue $cfg["DB_PASSWORD"] -NoTrim

  if ([string]::IsNullOrWhiteSpace($server) -or
      [string]::IsNullOrWhiteSpace($db) -or
      [string]::IsNullOrWhiteSpace($user) -or
      [string]::IsNullOrWhiteSpace($pass)) {
    throw "Cannot read DB_SERVER/DB_NAME/DB_USER/DB_PASSWORD from NSSM AppEnvironmentExtra for service '$ServiceName'."
  }

  $cs = New-SqlConnectionString -Server $server -Database $db -User $user -Password $pass
  Write-Host "Target SQL: $server  DB: $db  User: $user"
  Write-Host "Mode: $Mode"

  Print-Section "1) Pre-checks"

  $compatObj = Invoke-SqlScalar -ConnectionString $cs -Sql "SELECT compatibility_level FROM sys.databases WHERE name = DB_NAME();"
  if ($null -eq $compatObj) { throw "Cannot read compatibility_level." }
  $compatLevel = [int]$compatObj
  Write-Host "DB compatibility_level: $compatLevel"
  if ($compatLevel -lt 130) { throw "Need compatibility_level >= 130 (JSON_*). Current: $compatLevel" }

  if (-not (Invoke-SqlScalar -ConnectionString $cs -Sql "SELECT OBJECT_ID('dbo.Users','U');")) { throw "dbo.Users not found." }
  if (-not (Invoke-SqlScalar -ConnectionString $cs -Sql "SELECT OBJECT_ID('dbo.Characters','U');")) { throw "dbo.Characters not found." }
  if (-not (Invoke-SqlScalar -ConnectionString $cs -Sql "SELECT OBJECT_ID('dbo.InteractionEvents','U');")) { throw "dbo.InteractionEvents not found." }

  if ($null -eq (Invoke-SqlScalar -ConnectionString $cs -Sql "SELECT COL_LENGTH('dbo.Users','Id');")) { throw "dbo.Users.Id missing." }
  if ($null -eq (Invoke-SqlScalar -ConnectionString $cs -Sql "SELECT COL_LENGTH('dbo.Users','Platform');")) { throw "dbo.Users.Platform missing." }
  if ($null -eq (Invoke-SqlScalar -ConnectionString $cs -Sql "SELECT COL_LENGTH('dbo.Users','PlatformUserId');")) { throw "dbo.Users.PlatformUserId missing." }

  $ieCols = Invoke-SqlQuery -ConnectionString $cs -Sql @"
SELECT c.name, c.column_id, c.is_identity, c.is_computed, t.name AS type_name
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id AND c.system_type_id = t.system_type_id
WHERE c.object_id = OBJECT_ID('dbo.InteractionEvents')
  AND c.name IN ('EventId','Id')
ORDER BY c.column_id;
"@
  Write-Host ""
  Write-Host "dbo.InteractionEvents (Id/EventId):"
  if ($ieCols.Length -gt 0) { $ieCols | Format-Table -AutoSize } else { throw "Cannot find EventId/Id columns in dbo.InteractionEvents." }

  $eventIdRow = $ieCols | Where-Object { $_["name"] -eq "EventId" } | Select-Object -First 1
  if (-not $eventIdRow) { throw "dbo.InteractionEvents.EventId missing." }
  if (-not [bool]$eventIdRow["is_identity"]) { throw "dbo.InteractionEvents.EventId must be IDENTITY." }

  $dupUsers = Invoke-SqlQuery -ConnectionString $cs -Sql @"
SELECT TOP (50) Platform, PlatformUserId, COUNT(*) AS Cnt
FROM dbo.Users
GROUP BY Platform, PlatformUserId
HAVING COUNT(*) > 1
ORDER BY Cnt DESC, Platform, PlatformUserId;
"@
  if ($dupUsers.Length -gt 0) {
    Write-Host ""
    Write-Host "FATAL: duplicates in dbo.Users (Platform, PlatformUserId):"
    $dupUsers | Format-Table -AutoSize
    throw "Deduplicate dbo.Users first, then re-run."
  }

  $charCols = Invoke-SqlQuery -ConnectionString $cs -Sql @"
SELECT name
FROM sys.columns
WHERE object_id = OBJECT_ID('dbo.Characters')
  AND name IN ('CharacterKey','Key');
"@
  $charKeyCol = $null
  foreach ($r in $charCols) { if ($r["name"] -eq "CharacterKey") { $charKeyCol = "CharacterKey"; break } }
  if (-not $charKeyCol) {
    foreach ($r in $charCols) { if ($r["name"] -eq "Key") { $charKeyCol = "Key"; break } }
  }
  if (-not $charKeyCol) { throw "Cannot find dbo.Characters.CharacterKey or dbo.Characters.Key column." }
  Write-Host "Characters key column detected: $charKeyCol"

  $cmObj = Invoke-SqlScalar -ConnectionString $cs -Sql "SELECT OBJECT_ID('dbo.ConversationMessages','U');"
  if ($null -eq $cmObj) { Write-Host "NOTE: dbo.ConversationMessages missing - will be created in Apply." }
  else { Write-Host "OK: dbo.ConversationMessages exists." }

  Print-Section "2) Preview plan"
  Write-Host "Plan (Apply):"
  Write-Host "  A) Ensure dbo.Users columns"
  Write-Host "  B) Ensure dbo.ConversationMessages exists"
  Write-Host "  C) Ensure dbo.IngestionWarnings exists"
  Write-Host "  D) Ensure UNIQUE index on Users(Platform, PlatformUserId)"
  Write-Host "  E) Create trigger dbo.trg_InteractionEvents_ToConversationMessages"
  Write-Host ""

  if ($Mode -eq "Preview") { return }

  Print-Section "3) APPLY: stop service (avoid DDL races)"
  $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
  if ($svc -and $svc.Status -ne "Stopped") {
    Stop-Service -Name $ServiceName -Force -ErrorAction Stop
    $svc.WaitForStatus("Stopped", [TimeSpan]::FromSeconds(60)) | Out-Null
  }
  if ($svc) { Write-Host "Service stopped." } else { Write-Host "WARN: service '$ServiceName' not found. Continue." }

  Print-Section "4) APPLY: DDL + trigger"

  $ddl = @"
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Users (idempotent)
IF COL_LENGTH('dbo.Users','Username') IS NULL
  ALTER TABLE dbo.Users ADD Username NVARCHAR(256) NULL;

IF COL_LENGTH('dbo.Users','DisplayName') IS NULL
  ALTER TABLE dbo.Users ADD DisplayName NVARCHAR(256) NULL;

IF COL_LENGTH('dbo.Users','MetaJson') IS NULL
  ALTER TABLE dbo.Users ADD MetaJson NVARCHAR(MAX) NULL;

IF COL_LENGTH('dbo.Users','CreatedAt') IS NULL
  ALTER TABLE dbo.Users ADD CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT SYSUTCDATETIME();

IF COL_LENGTH('dbo.Users','PreferredLang') IS NULL
  ALTER TABLE dbo.Users ADD PreferredLang NVARCHAR(16) NULL;

IF COL_LENGTH('dbo.Users','AgeVerificationLevel') IS NULL
  ALTER TABLE dbo.Users ADD AgeVerificationLevel TINYINT NOT NULL CONSTRAINT DF_Users_AgeLevel DEFAULT (0);

IF COL_LENGTH('dbo.Users','AgeVerifiedAt') IS NULL
  ALTER TABLE dbo.Users ADD AgeVerifiedAt DATETIME2(7) NULL;

IF COL_LENGTH('dbo.Users','IsBanned') IS NULL
  ALTER TABLE dbo.Users ADD IsBanned BIT NOT NULL CONSTRAINT DF_Users_IsBanned DEFAULT (0);

IF COL_LENGTH('dbo.Users','NotesRu') IS NULL
  ALTER TABLE dbo.Users ADD NotesRu NVARCHAR(2000) NULL;

IF COL_LENGTH('dbo.Users','LastSeenAt') IS NULL
  ALTER TABLE dbo.Users ADD LastSeenAt DATETIME2(7) NULL;

-- ConversationMessages
IF OBJECT_ID('dbo.ConversationMessages','U') IS NULL
BEGIN
  CREATE TABLE dbo.ConversationMessages (
    MessageId        BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ConversationMessages PRIMARY KEY,
    UserId           BIGINT NOT NULL,
    CharacterId      INT NOT NULL,
    ProjectId        BIGINT NULL,
    Platform         NVARCHAR(32) NOT NULL,
    ConversationKey  NVARCHAR(200) NULL,
    Ts               DATETIME2(7) NOT NULL CONSTRAINT DF_ConvMsg_Ts DEFAULT SYSUTCDATETIME(),
    Role             NVARCHAR(16) NOT NULL,
    TextOriginal     NVARCHAR(MAX) NULL,
    LangOriginal     NVARCHAR(16) NULL,
    TextRu           NVARCHAR(MAX) NULL,
    MetaJson         NVARCHAR(MAX) NULL,
    EventId          BIGINT NULL,
    CONSTRAINT FK_ConvMsg_Users      FOREIGN KEY (UserId)      REFERENCES dbo.Users(Id),
    CONSTRAINT FK_ConvMsg_Characters FOREIGN KEY (CharacterId) REFERENCES dbo.Characters(Id),
    CONSTRAINT CK_ConvMsg_Role CHECK (Role IN ('user','assistant','system'))
  );
  CREATE INDEX IX_ConvMsg_UserCharTs ON dbo.ConversationMessages(UserId, CharacterId, Ts DESC);
END;

-- IngestionWarnings
IF OBJECT_ID('dbo.IngestionWarnings','U') IS NULL
BEGIN
  CREATE TABLE dbo.IngestionWarnings (
    WarningId   BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_IngestionWarnings PRIMARY KEY,
    CreatedAt   DATETIME2(7) NOT NULL CONSTRAINT DF_IngestionWarnings_CreatedAt DEFAULT SYSUTCDATETIME(),
    EventId     BIGINT NULL,
    WarningCode NVARCHAR(64) NOT NULL,
    Message     NVARCHAR(2000) NOT NULL,
    Details     NVARCHAR(MAX) NULL
  );
  CREATE INDEX IX_IngestionWarnings_EventId ON dbo.IngestionWarnings(EventId);
END;

-- UNIQUE index on Users
IF NOT EXISTS (
  SELECT 1 FROM sys.indexes
  WHERE object_id = OBJECT_ID('dbo.Users') AND name = 'UX_Users_Platform_PlatformUserId'
)
BEGIN
  CREATE UNIQUE INDEX UX_Users_Platform_PlatformUserId ON dbo.Users(Platform, PlatformUserId);
END;
"@
  Invoke-SqlNonQuery -ConnectionString $cs -Sql $ddl
  Write-Host "DDL OK."

  $dropTrig = @"
IF OBJECT_ID('dbo.trg_InteractionEvents_ToConversationMessages','TR') IS NOT NULL
  DROP TRIGGER dbo.trg_InteractionEvents_ToConversationMessages;
"@
  Invoke-SqlNonQuery -ConnectionString $cs -Sql $dropTrig
  Write-Host "Old trigger (if any) dropped."

  $createTrigTemplate = @"
CREATE TRIGGER dbo.trg_InteractionEvents_ToConversationMessages
ON dbo.InteractionEvents
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    DECLARE @n TABLE (
      EventId              BIGINT       NOT NULL,
      CreatedAt            DATETIME2(7)  NOT NULL,
      PlatformNorm         NVARCHAR(32)  NOT NULL,
      Channel              NVARCHAR(64)  NULL,
      ConversationKey      NVARCHAR(256) NULL,
      CharacterKey         NVARCHAR(64)  NULL,
      EventType            NVARCHAR(128) NULL,
      Lang                 NVARCHAR(32)  NULL,
      PayloadJson          NVARCHAR(MAX) NULL,
      TextOriginal         NVARCHAR(MAX) NULL,
      Username             NVARCHAR(256) NULL,
      DisplayName          NVARCHAR(256) NULL,
      PlatformUserIdNorm   NVARCHAR(256) NULL,
      UpsertPlatformUserId NVARCHAR(256) NOT NULL
    );

    INSERT INTO @n(
      EventId, CreatedAt, PlatformNorm, Channel, ConversationKey, CharacterKey, EventType, Lang, PayloadJson,
      TextOriginal, Username, DisplayName,
      PlatformUserIdNorm, UpsertPlatformUserId
    )
    SELECT
      i.EventId,
      i.CreatedAt,
      ISNULL(NULLIF(LTRIM(RTRIM(i.Platform)),''),'unknown') AS PlatformNorm,
      i.Channel,
      COALESCE(
        NULLIF(LTRIM(RTRIM(i.ConversationKey)),''),
        CONCAT(
          ISNULL(NULLIF(LTRIM(RTRIM(i.Platform)),''),'unknown'),
          ':',
          ISNULL(NULLIF(LTRIM(RTRIM(i.Channel)),''),'?'),
          ':',
          ISNULL(NULLIF(LTRIM(RTRIM(i.CharacterKey)),''),'?')
        )
      ) AS ConversationKey,
      i.CharacterKey,
      i.EventType,
      i.Lang,
      i.PayloadJson,
      j.TextOriginal,
      j.Username,
      j.DisplayName,
      CASE
        WHEN ISNULL(NULLIF(LTRIM(RTRIM(i.Platform)),''),'unknown') = 'admin' THEN N'admin'
        ELSE j.PlatformUserIdRaw
      END AS PlatformUserIdNorm,
      CASE
        WHEN ISNULL(NULLIF(LTRIM(RTRIM(i.Platform)),''),'unknown') = 'admin' THEN N'admin'
        ELSE COALESCE(
          j.PlatformUserIdRaw,
          NULLIF(LTRIM(RTRIM(i.ConversationKey)),''),  -- weak fallback
          CONCAT(N'unknown:', CONVERT(nvarchar(32), i.EventId))
        )
      END AS UpsertPlatformUserId
    FROM inserted i
    CROSS APPLY (
      SELECT
        COALESCE(
          JSON_VALUE(i.PayloadJson,'`$.text'),
          JSON_VALUE(i.PayloadJson,'`$.payload.text')
        ) AS TextOriginal,

        COALESCE(
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.platform_user_key'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.payload.platform_user_key'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.platform_user_id'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.payload.platform_user_id'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.user_id'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.payload.user_id'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.telegram_user_id'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.payload.telegram_user_id'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.payload.tg_user_id'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.payload.chat_id'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.payload.from_id'))),'')
        ) AS PlatformUserIdRaw,

        COALESCE(
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.username'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.payload.username'))),'')
        ) AS Username,

        COALESCE(
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.display_name'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.payload.display_name'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.displayName'))),''),
          NULLIF(LTRIM(RTRIM(JSON_VALUE(i.PayloadJson,'`$.payload.displayName'))),'')
        ) AS DisplayName
    ) j;

    INSERT INTO dbo.IngestionWarnings(EventId, WarningCode, Message, Details)
    SELECT
      n.EventId,
      'MISSING_PLATFORM_USER',
      CONCAT('platform_user_key missing; fallback userId=', n.UpsertPlatformUserId),
      CONCAT('platform=', n.PlatformNorm, '; conversation_key=', COALESCE(n.ConversationKey,'(null)'))
    FROM @n n
    WHERE n.PlatformNorm <> 'admin'
      AND (n.PlatformUserIdNorm IS NULL OR LTRIM(RTRIM(n.PlatformUserIdNorm)) = '');

    INSERT INTO dbo.IngestionWarnings(EventId, WarningCode, Message, Details)
    SELECT
      n.EventId,
      'UNKNOWN_CHARACTER',
      CONCAT('CharacterKey not found: ', COALESCE(n.CharacterKey,'(null)')),
      CONCAT('platform=', n.PlatformNorm, '; conversation_key=', COALESCE(n.ConversationKey,'(null)'))
    FROM @n n
    WHERE n.CharacterKey IS NULL
       OR NOT EXISTS (SELECT 1 FROM dbo.Characters c WHERE c.[__CHARKEYCOL__] = n.CharacterKey);

    ;MERGE dbo.Users WITH (HOLDLOCK) AS tgt
    USING (
      SELECT DISTINCT
        n.PlatformNorm AS Platform,
        n.UpsertPlatformUserId AS PlatformUserId,
        n.Username,
        n.DisplayName
      FROM @n n
    ) AS srcu
    ON tgt.Platform = srcu.Platform AND tgt.PlatformUserId = srcu.PlatformUserId
    WHEN MATCHED THEN
      UPDATE SET
        tgt.Username    = COALESCE(srcu.Username, tgt.Username),
        tgt.DisplayName = COALESCE(srcu.DisplayName, tgt.DisplayName),
        tgt.LastSeenAt  = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
      INSERT (Platform, PlatformUserId, Username, DisplayName, MetaJson, CreatedAt, LastSeenAt)
      VALUES (srcu.Platform, srcu.PlatformUserId, srcu.Username, srcu.DisplayName, NULL, SYSUTCDATETIME(), SYSUTCDATETIME());

    INSERT INTO dbo.ConversationMessages(
      UserId, CharacterId, ProjectId, Platform, ConversationKey,
      Ts, Role,
      TextOriginal, LangOriginal, TextRu,
      MetaJson, EventId
    )
    SELECT
      u.Id AS UserId,
      c.Id AS CharacterId,
      NULL AS ProjectId,
      n.PlatformNorm AS Platform,
      n.ConversationKey,
      n.CreatedAt AS Ts,
      CASE
        WHEN n.EventType IN ('inbound_message','user_message','inbound') THEN 'user'
        WHEN n.EventType IN ('assistant_message','outbound_message','assistant') THEN 'assistant'
        ELSE 'system'
      END AS Role,
      n.TextOriginal,
      n.Lang,
      CASE WHEN n.Lang = 'ru' OR n.Lang IS NULL THEN n.TextOriginal ELSE NULL END AS TextRu,
      n.PayloadJson,
      n.EventId
    FROM @n n
    JOIN dbo.Users u
      ON u.Platform = n.PlatformNorm AND u.PlatformUserId = n.UpsertPlatformUserId
    JOIN dbo.Characters c
      ON c.[__CHARKEYCOL__] = n.CharacterKey
    WHERE n.EventType IN ('inbound_message','assistant_message','outbound_message')
      AND n.TextOriginal IS NOT NULL
      AND LTRIM(RTRIM(n.TextOriginal)) <> '';

  END TRY
  BEGIN CATCH
    DECLARE @msg  nvarchar(2048) = ERROR_MESSAGE();
    DECLARE @proc nvarchar(128)  = ERROR_PROCEDURE();
    DECLARE @line int            = ERROR_LINE();

    IF OBJECT_ID('dbo.IngestionWarnings','U') IS NOT NULL
    BEGIN
      INSERT INTO dbo.IngestionWarnings(EventId, WarningCode, Message, Details)
      SELECT TOP (1)
        i.EventId,
        'TRIGGER_ERROR',
        @msg,
        CONCAT('proc=', COALESCE(@proc,'(null)'), '; line=', @line)
      FROM inserted i;
    END
  END CATCH
END
"@

  $createTrig = $createTrigTemplate.Replace("__CHARKEYCOL__", $charKeyCol)
  Invoke-SqlNonQuery -ConnectionString $cs -Sql $createTrig
  Write-Host "Trigger created: dbo.trg_InteractionEvents_ToConversationMessages"

  Print-Section "5) APPLY: start service"
  if ($svc) {
    Start-Service -Name $ServiceName -ErrorAction Stop
    (Get-Service -Name $ServiceName).WaitForStatus("Running", [TimeSpan]::FromSeconds(60)) | Out-Null
    Write-Host "Service running."
  }

  Print-Section "6) AFTER quick checks"
  $tr = Invoke-SqlQuery -ConnectionString $cs -Sql @"
SELECT name, is_disabled, create_date, modify_date
FROM sys.triggers
WHERE parent_id = OBJECT_ID('dbo.InteractionEvents')
ORDER BY name;
"@
  Write-Host "Triggers on dbo.InteractionEvents:"
  if ($tr.Length -gt 0) { $tr | Format-Table -AutoSize } else { Write-Host "NO triggers found (this is NOT ok for Patch003)." }

  $w = Invoke-SqlQuery -ConnectionString $cs -Sql "SELECT TOP (10) WarningId, CreatedAt, EventId, WarningCode, Message FROM dbo.IngestionWarnings ORDER BY WarningId DESC;"
  Write-Host ""
  Write-Host "Recent IngestionWarnings (top 10):"
  if ($w.Length -gt 0) { $w | Format-Table -AutoSize } else { Write-Host "(empty)" }

  Print-Section "DONE: Patch003 applied"
}
catch {
  Write-Host ""
  Write-Host ("FATAL: " + $_.Exception.Message)
  throw
}
finally {
  try { Stop-Transcript | Out-Null } catch {}
  Write-Host ""
  Write-Host "Transcript saved: $transcript"
  if ($Pause) { Read-Host "Press Enter to exit" | Out-Null }
}
