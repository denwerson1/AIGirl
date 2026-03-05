[CmdletBinding()]
param(
  [string]$SqlServer = "$env:COMPUTERNAME\SQLEXPRESS",
  [string]$DbName    = "AIGirl",
  [string]$Root      = "C:\AIGirl"
)

$ErrorActionPreference = "Stop"

function Invoke-SqlNonQuery {
  param(
    [Parameter(Mandatory=$true)][string]$Server,
    [Parameter(Mandatory=$true)][string]$Database,
    [Parameter(Mandatory=$true)][string]$Query
  )
  Add-Type -AssemblyName "System.Data"
  $cs = "Server=$Server;Database=$Database;Integrated Security=True;TrustServerCertificate=True;"
  $cn = New-Object System.Data.SqlClient.SqlConnection($cs)
  $cn.Open()
  try {
    $cmd = $cn.CreateCommand()
    $cmd.CommandTimeout = 0
    $cmd.CommandText = $Query
    [void]$cmd.ExecuteNonQuery()
  } finally {
    $cn.Close()
  }
}

Write-Host "== DB migrate: add ValueType/Unit/Step to ParameterDefinitions (если нет) =="
Invoke-SqlNonQuery -Server $SqlServer -Database $DbName -Query @"
IF COL_LENGTH('dbo.ParameterDefinitions','ValueType') IS NULL
BEGIN
  ALTER TABLE dbo.ParameterDefinitions
    ADD ValueType nvarchar(32) NOT NULL
      CONSTRAINT DF_ParameterDefinitions_ValueType DEFAULT('slider_int');
END

IF COL_LENGTH('dbo.ParameterDefinitions','UnitRu') IS NULL
BEGIN
  ALTER TABLE dbo.ParameterDefinitions
    ADD UnitRu nvarchar(32) NULL;
END

IF COL_LENGTH('dbo.ParameterDefinitions','StepValue') IS NULL
BEGIN
  ALTER TABLE dbo.ParameterDefinitions
    ADD StepValue int NULL;
END
"@

Write-Host "== DB migrate: Characters / CharacterParameterValues / Locations / CharacterState =="
Invoke-SqlNonQuery -Server $SqlServer -Database $DbName -Query @"
IF OBJECT_ID('dbo.Characters','U') IS NULL
BEGIN
  CREATE TABLE dbo.Characters(
    Id int IDENTITY(1,1) PRIMARY KEY,
    [Key] nvarchar(32) NOT NULL UNIQUE,      -- isha / nika
    Surname nvarchar(64) NOT NULL,           -- AI
    [Name] nvarchar(64) NOT NULL,            -- Иша / Ника
    DisplayName nvarchar(128) NOT NULL,      -- AI.Иша
    DistinctiveMarksJson nvarchar(max) NULL, -- например { "mole": "upper_right_lip" }
    NotesRu nvarchar(512) NULL,
    CreatedAt datetime2 NOT NULL DEFAULT(sysdatetime())
  );
END

IF OBJECT_ID('dbo.CharacterParameterValues','U') IS NULL
BEGIN
  CREATE TABLE dbo.CharacterParameterValues(
    CharacterId int NOT NULL FOREIGN KEY REFERENCES dbo.Characters(Id),
    ParameterKey nvarchar(128) NOT NULL,
    ValueInt int NULL,
    ValueText nvarchar(max) NULL,
    UpdatedAt datetime2 NOT NULL DEFAULT(sysdatetime()),
    CONSTRAINT PK_CharacterParameterValues PRIMARY KEY(CharacterId, ParameterKey)
  );
END

IF OBJECT_ID('dbo.Locations','U') IS NULL
BEGIN
  CREATE TABLE dbo.Locations(
    Id int IDENTITY(1,1) PRIMARY KEY,
    [Key] nvarchar(64) NOT NULL UNIQUE,   -- например "swiss_lake_01"
    CountryRu nvarchar(128) NULL,
    CityRu nvarchar(128) NULL,
    PrettyNameRu nvarchar(256) NOT NULL,  -- "Швейцария, озеро в горах"
    AssetFolder nvarchar(512) NULL,       -- путь к ассетам/Blender сцене/HDRI
    MetaJson nvarchar(max) NULL,
    CreatedAt datetime2 NOT NULL DEFAULT(sysdatetime())
  );
END

IF OBJECT_ID('dbo.CharacterState','U') IS NULL
BEGIN
  CREATE TABLE dbo.CharacterState(
    CharacterId int PRIMARY KEY FOREIGN KEY REFERENCES dbo.Characters(Id),
    CurrentLocationId int NULL FOREIGN KEY REFERENCES dbo.Locations(Id),
    StateJson nvarchar(max) NULL,
    UpdatedAt datetime2 NOT NULL DEFAULT(sysdatetime())
  );
END
"@

Write-Host "== Insert twins (если ещё нет) =="
Invoke-SqlNonQuery -Server $SqlServer -Database $DbName -Query @"
IF NOT EXISTS (SELECT 1 FROM dbo.Characters WHERE [Key]=N'isha')
BEGIN
  INSERT INTO dbo.Characters([Key],Surname,[Name],DisplayName,DistinctiveMarksJson,NotesRu)
  VALUES(N'isha',N'AI',N'Иша',N'AI.Иша',N'{""mole"":""upper_right_lip""}',N'Близняшка с родинкой над верхней губой справа');
END

IF NOT EXISTS (SELECT 1 FROM dbo.Characters WHERE [Key]=N'nika')
BEGIN
  INSERT INTO dbo.Characters([Key],Surname,[Name],DisplayName,DistinctiveMarksJson,NotesRu)
  VALUES(N'nika',N'AI',N'Ника',N'AI.Ника',NULL,N'Близняшка без родинки');
END

-- state rows
INSERT INTO dbo.CharacterState(CharacterId)
SELECT c.Id
FROM dbo.Characters c
WHERE NOT EXISTS (SELECT 1 FROM dbo.CharacterState s WHERE s.CharacterId=c.Id);
"@

Write-Host "== Add video duration parameter in seconds (client numeric) =="
Invoke-SqlNonQuery -Server $SqlServer -Database $DbName -Query @"
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterDefinitions WHERE [Key]=N'video.duration_sec')
BEGIN
  INSERT INTO dbo.ParameterDefinitions([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(
    N'video.duration_sec',
    N'Длительность ролика (сек)',
    N'Видео',
    1, 3600, 60,
    N'Точное число в секундах. Для длинных роликов система будет резать на сегменты при необходимости.',
    N'int_seconds',
    N'сек',
    1
  );
END

IF NOT EXISTS (SELECT 1 FROM dbo.ParameterDefinitions WHERE [Key]=N'video.fps')
BEGIN
  INSERT INTO dbo.ParameterDefinitions([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(
    N'video.fps',
    N'FPS',
    N'Видео',
    12, 60, 30,
    N'Кадров в секунду. Frames = duration_sec * fps.',
    N'int',
    N'fps',
    1
  );
END

IF NOT EXISTS (SELECT 1 FROM dbo.ParameterDefinitions WHERE [Key]=N'video.segment_sec')
BEGIN
  INSERT INTO dbo.ParameterDefinitions([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(
    N'video.segment_sec',
    N'Длина сегмента для рендера (сек)',
    N'Видео',
    5, 60, 15,
    N'Практика: длинные ролики рендерить кусками (10–30 сек) и склеивать.',
    N'int_seconds',
    N'сек',
    1
  );
END
"@

Write-Host ""
Write-Host "OK: БД обновлена под близняшек + добавлены параметры длительности видео."
Write-Host "SQL: $SqlServer, DB: $DbName"