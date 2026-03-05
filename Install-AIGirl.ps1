<# =====================================================================
Install-AIGirl.ps1
- Подготовка ПК под учебный проект "AI Girl" (локально, Windows)
- Установка зависимостей (через winget), SQL Server Express 2016, создание БД
- Разворачивание ComfyUI + ComfyUI-Manager (без скачивания весов моделей)
- Разворачивание backend-скелета (FastAPI) и сервисов (NSSM)
- Установка Piper (движок) + RU голос (ru_RU-irina-medium) для офлайн TTS
Проект: C:\AIGirl\

ВАЖНО:
- Скрипт не скачивает SD/видео модели (SDXL/ControlNet/LoRA) — из-за размеров/лицензий.
- Instagram/TikTok ключи/токены скрипт не создаёт (это делается в кабинетах разработчика).
===================================================================== #>

[CmdletBinding()]
param(
  [string]$Root = "C:\AIGirl",

  [string]$SqlInstance = "SQLEXPRESS",
  [string]$DbName      = "AIGirl",

  # По вашему требованию:
  [string]$AdminLogin    = "admin",
  [string]$AdminPassword = "mag046zat2",

  # Водяной знак (текст в углу каждого фото/видео)
  [Parameter(Mandatory=$true)]
  [string]$WatermarkText,

  # Опционально
  [switch]$InstallSSMS,
  [switch]$InstallOllama
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Admin {
  $p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Запустите PowerShell от имени Администратора."
  }
}

function Write-Step([string]$msg) {
  Write-Host ""
  Write-Host ("== " + $msg + " ==") -ForegroundColor Cyan
}

function Ensure-Dir([string]$path) {
  if (-not (Test-Path $path)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
  }
}

function Refresh-EnvPath {
  $machine = [Environment]::GetEnvironmentVariable("Path","Machine")
  $user    = [Environment]::GetEnvironmentVariable("Path","User")
  $env:Path = ($machine + ";" + $user)
}

function Download-File([string]$Uri, [string]$OutFile) {
  if (Test-Path $OutFile) { return }
  Write-Host ("Скачивание: " + $Uri)
  Ensure-Dir (Split-Path -Parent $OutFile)

  # TLS 1.2/1.3
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288
  } catch {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  }

  try {
    Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing
  } catch {
    throw "Не удалось скачать $Uri -> $OutFile. Ошибка: $($_.Exception.Message)"
  }
}

function Require-WinGet {
  if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    throw @"
winget не найден.
Установите/обновите 'App Installer' (Microsoft Store) и перелогиньтесь в систему.
Справка Microsoft: winget доступен как часть App Installer и появляется после первого входа пользователя.
"@
  }
}

function Winget-Install([string]$Id) {
  Write-Host ("winget install: " + $Id)
  & winget install -e --id $Id --accept-package-agreements --accept-source-agreements --silent
  Refresh-EnvPath
}

function New-StrongPassword([int]$Length = 24) {
  $lower = "abcdefghijkmnopqrstuvwxyz"
  $upper = "ABCDEFGHJKLMNPQRSTUVWXYZ"
  $digits = "23456789"
  $special = "!@#$%^&*-_=+"
  $all = ($lower + $upper + $digits + $special)

  $chars = New-Object System.Collections.Generic.List[char]
  $chars.Add($lower[(Get-Random -Maximum $lower.Length)])
  $chars.Add($upper[(Get-Random -Maximum $upper.Length)])
  $chars.Add($digits[(Get-Random -Maximum $digits.Length)])
  $chars.Add($special[(Get-Random -Maximum $special.Length)])

  for ($i = $chars.Count; $i -lt $Length; $i++) {
    $chars.Add($all[(Get-Random -Maximum $all.Length)])
  }

  # shuffle
  $shuffled = $chars | Sort-Object {Get-Random}
  return (-join $shuffled)
}

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

function Wait-SqlReady {
  param(
    [Parameter(Mandatory=$true)][string]$Server,
    [int]$Seconds = 120
  )
  Add-Type -AssemblyName "System.Data"
  $deadline = (Get-Date).AddSeconds($Seconds)
  while ((Get-Date) -lt $deadline) {
    try {
      $cs = "Server=$Server;Database=master;Integrated Security=True;TrustServerCertificate=True;"
      $cn = New-Object System.Data.SqlClient.SqlConnection($cs)
      $cn.Open()
      $cn.Close()
      return
    } catch {
      Start-Sleep -Seconds 2
    }
  }
  throw "SQL Server не поднялся за отведённое время. Проверьте службу MSSQL`$$SqlInstance."
}

# -------------------- MAIN --------------------
Assert-Admin

Ensure-Dir $Root
$Installers = Join-Path $Root "installers"
$Logs       = Join-Path $Root "logs"
$Secrets    = Join-Path $Root "secrets"
$Repos      = Join-Path $Root "repos"
$Data       = Join-Path $Root "data"
$Services   = Join-Path $Root "services"

Ensure-Dir $Installers
Ensure-Dir $Logs
Ensure-Dir $Secrets
Ensure-Dir $Repos
Ensure-Dir $Data
Ensure-Dir $Services
Ensure-Dir (Join-Path $Data "content")
Ensure-Dir (Join-Path $Data "models")
Ensure-Dir (Join-Path $Data "jobs")

Start-Transcript -Path (Join-Path $Logs ("install_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")) | Out-Null

Write-Step "Проверка winget"
Require-WinGet

Write-Step "Установка базовых пакетов"
Winget-Install "Microsoft.VCRedist.2015+.x64"
Winget-Install "Git.Git"
Winget-Install "Python.Python.3.11"
Winget-Install "Microsoft.DotNet.SDK.8"
Winget-Install "Gyan.FFmpeg"
Winget-Install "BlenderFoundation.Blender"
Winget-Install "NSSM.NSSM"
Winget-Install "Microsoft.msodbcsql.17"

if ($InstallOllama) {
  Winget-Install "Ollama.Ollama"
}

if ($InstallSSMS) {
  # Современные SSMS ставятся через bootstrapper/VS Installer; winget поддерживается.
  # Пакетная версия может отличаться, но winget подберёт актуальную.
  Winget-Install "Microsoft.SQLServerManagementStudio.22"
}

Write-Step "Установка SQL Server Express 2016 (если ещё не установлен)"
$SqlServiceName = "MSSQL`$$SqlInstance"
$SqlServer = "$env:COMPUTERNAME\$SqlInstance"

$already = Get-Service -Name $SqlServiceName -ErrorAction SilentlyContinue
if (-not $already) {
  $SqlDir = Join-Path $Installers "sql2016"
  $SqlMedia = Join-Path $SqlDir "media"
  $SqlExtract = Join-Path $SqlDir "extract"
  Ensure-Dir $SqlDir
  Ensure-Dir $SqlMedia
  Ensure-Dir $SqlExtract

  # Официальный bootstrapper Microsoft (Download Center)
  $SseiUrl = "https://download.microsoft.com/download/3/7/6/3767d272-76a1-4f31-8849-260bd37924e4/SQLServer2016-SSEI-Expr.exe"
  $SseiExe = Join-Path $SqlDir "SQLServer2016-SSEI-Expr.exe"
  Download-File $SseiUrl $SseiExe

  Write-Host "Скачиваем установочные файлы SQL Express 2016 в $SqlMedia ..."
  & $SseiExe /ACTION=Download /MEDIAPATH="$SqlMedia" /MEDIATYPE=Core /QUIET /IACCEPTSQLSERVERLICENSETERMS | Out-Null

  $sqlexpr = Get-ChildItem -Path $SqlMedia -Recurse -Filter "SQLEXPR*_x64_ENU.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $sqlexpr) {
    throw "Не найден SQLEXPR*_x64_ENU.exe в $SqlMedia. Проверьте интернет/прокси."
  }

  Write-Host ("Распаковка: " + $sqlexpr.FullName)
  & $sqlexpr.FullName /q /x:"$SqlExtract" | Out-Null

  $setupExe = Join-Path $SqlExtract "setup.exe"
  if (-not (Test-Path $setupExe)) {
    $setupExe = (Get-ChildItem -Path $SqlExtract -Recurse -Filter "setup.exe" | Select-Object -First 1).FullName
  }
  if (-not (Test-Path $setupExe)) {
    throw "setup.exe не найден после распаковки SQL Express."
  }

  $saPassword = New-StrongPassword 24
  $saFile = Join-Path $Secrets "sa_password.txt"
  $saPassword | Out-File -FilePath $saFile -Encoding ascii -Force
  & icacls $saFile /inheritance:r /grant:r "Administrators:(F)" "SYSTEM:(F)" | Out-Null

  $ini = Join-Path $SqlDir "ConfigurationFile.ini"
  @"
[OPTIONS]
ACTION="Install"
FEATURES=SQLEngine
INSTANCENAME="$SqlInstance"
SECURITYMODE=SQL
SAPWD="$saPassword"
SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS"
TCPENABLED=1
NPENABLED=0
IACCEPTSQLSERVERLICENSETERMS="True"
QUIET="True"
INDICATEPROGRESS="False"
"@ | Out-File -FilePath $ini -Encoding ascii -Force

  Write-Host "Запуск тихой установки SQL Express 2016 (инстанс $SqlInstance) ..."
  Start-Process -FilePath $setupExe -ArgumentList "/ConfigurationFile=`"$ini`"" -Wait -NoNewWindow

} else {
  Write-Host "SQL Express уже установлен: $SqlServiceName"
}

Write-Step "Запуск службы SQL и ожидание готовности"
Start-Service -Name $SqlServiceName -ErrorAction SilentlyContinue
Wait-SqlReady -Server $SqlServer -Seconds 180

Write-Step "Создание БД + логина администратора + схема"
# 1) Создать БД
Invoke-SqlNonQuery -Server $SqlServer -Database "master" -Query @"
IF DB_ID(N'$DbName') IS NULL
BEGIN
  DECLARE @sql nvarchar(max) = N'CREATE DATABASE [$DbName]';
  EXEC(@sql);
END
"@

# 2) Создать/обновить SQL логин admin (с отключенной проверкой политики, чтобы ваш пароль точно применился)
Invoke-SqlNonQuery -Server $SqlServer -Database "master" -Query @"
IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'$AdminLogin')
BEGIN
  EXEC(N'CREATE LOGIN [$AdminLogin] WITH PASSWORD = ''$AdminPassword'', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;');
END
ELSE
BEGIN
  EXEC(N'ALTER LOGIN [$AdminLogin] WITH PASSWORD = ''$AdminPassword'', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;');
END

IF IS_SRVROLEMEMBER('sysadmin', N'$AdminLogin') = 0
BEGIN
  ALTER SERVER ROLE [sysadmin] ADD MEMBER [$AdminLogin];
END
"@

# 3) Таблицы проекта (минимальный старт)
Invoke-SqlNonQuery -Server $SqlServer -Database $DbName -Query @"
IF OBJECT_ID('dbo.ParameterDefinitions','U') IS NULL
BEGIN
  CREATE TABLE dbo.ParameterDefinitions(
    Id int IDENTITY(1,1) PRIMARY KEY,
    [Key] nvarchar(128) NOT NULL UNIQUE,
    NameRu nvarchar(256) NOT NULL,
    GroupRu nvarchar(128) NOT NULL,
    MinValue int NOT NULL DEFAULT(0),
    MaxValue int NOT NULL DEFAULT(100),
    DefaultValue int NOT NULL DEFAULT(50),
    HintRu nvarchar(512) NULL,
    MappingJson nvarchar(max) NULL
  );
END

IF OBJECT_ID('dbo.Settings','U') IS NULL
BEGIN
  CREATE TABLE dbo.Settings(
    [Key] nvarchar(128) NOT NULL PRIMARY KEY,
    [Value] nvarchar(max) NULL,
    UpdatedAt datetime2 NOT NULL DEFAULT(sysdatetime())
  );
END

IF OBJECT_ID('dbo.PlatformAccounts','U') IS NULL
BEGIN
  CREATE TABLE dbo.PlatformAccounts(
    Id int IDENTITY(1,1) PRIMARY KEY,
    Platform nvarchar(32) NOT NULL, -- telegram/instagram/tiktok
    DisplayName nvarchar(128) NULL,
    AccessToken nvarchar(max) NULL,
    RefreshToken nvarchar(max) NULL,
    TokenExpiresAt datetime2 NULL,
    MetaJson nvarchar(max) NULL,
    CreatedAt datetime2 NOT NULL DEFAULT(sysdatetime())
  );
END

IF OBJECT_ID('dbo.Users','U') IS NULL
BEGIN
  CREATE TABLE dbo.Users(
    Id bigint IDENTITY(1,1) PRIMARY KEY,
    Platform nvarchar(32) NOT NULL,
    PlatformUserId nvarchar(128) NOT NULL,
    Username nvarchar(128) NULL,
    DisplayName nvarchar(128) NULL,
    MetaJson nvarchar(max) NULL,
    CreatedAt datetime2 NOT NULL DEFAULT(sysdatetime()),
    CONSTRAINT UQ_Users_Platform UNIQUE(Platform, PlatformUserId)
  );
END

IF OBJECT_ID('dbo.Messages','U') IS NULL
BEGIN
  CREATE TABLE dbo.Messages(
    Id bigint IDENTITY(1,1) PRIMARY KEY,
    Platform nvarchar(32) NOT NULL,
    PlatformThreadId nvarchar(128) NULL,
    UserId bigint NULL FOREIGN KEY REFERENCES dbo.Users(Id),
    Direction nvarchar(16) NOT NULL, -- in/out/system
    Text nvarchar(max) NOT NULL,
    CreatedAt datetime2 NOT NULL DEFAULT(sysdatetime())
  );
END

IF OBJECT_ID('dbo.ContentAssets','U') IS NULL
BEGIN
  CREATE TABLE dbo.ContentAssets(
    Id bigint IDENTITY(1,1) PRIMARY KEY,
    AssetType nvarchar(16) NOT NULL, -- image/video/audio
    FilePath nvarchar(512) NOT NULL,
    Watermarked bit NOT NULL DEFAULT(0),
    MetaJson nvarchar(max) NULL,
    CreatedAt datetime2 NOT NULL DEFAULT(sysdatetime())
  );
END

IF OBJECT_ID('dbo.GenerationJobs','U') IS NULL
BEGIN
  CREATE TABLE dbo.GenerationJobs(
    Id bigint IDENTITY(1,1) PRIMARY KEY,
    JobType nvarchar(32) NOT NULL, -- photo/video/voice
    Status nvarchar(16) NOT NULL DEFAULT('queued'), -- queued/running/done/error
    ParamsJson nvarchar(max) NULL,
    OutputAssetId bigint NULL,
    ErrorText nvarchar(max) NULL,
    CreatedAt datetime2 NOT NULL DEFAULT(sysdatetime()),
    StartedAt datetime2 NULL,
    FinishedAt datetime2 NULL
  );
END

-- Базовые настройки
MERGE dbo.Settings AS t
USING (VALUES
  (N'watermark_text', N'$WatermarkText'),
  (N'project_root', N'$Root'),
  (N'comfyui_url', N'http://127.0.0.1:8188'),
  (N'backend_url', N'http://127.0.0.1:8001')
) AS s([Key],[Value])
ON t.[Key]=s.[Key]
WHEN MATCHED THEN UPDATE SET t.[Value]=s.[Value], t.UpdatedAt=sysdatetime()
WHEN NOT MATCHED THEN INSERT([Key],[Value]) VALUES(s.[Key],s.[Value]);

"@

Write-Step "Заполнение стартового набора параметров (ползунки 0..100)"
Invoke-SqlNonQuery -Server $SqlServer -Database $DbName -Query @"
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterDefinitions)
BEGIN
  INSERT INTO dbo.ParameterDefinitions([Key],NameRu,GroupRu,DefaultValue,HintRu)
  VALUES
   (N'persona.warmth',N'Теплота общения',N'Характер/Речь',60,N'0=холодно, 100=очень тепло'),
   (N'persona.flirt',N'Флирт',N'Характер/Речь',30,N'0=нет, 100=максимум'),
   (N'persona.humor',N'Юмор',N'Характер/Речь',45,N'0=сухо, 100=много шуток'),
   (N'persona.formality',N'Официальность',N'Характер/Речь',35,N'0=разговорно, 100=официально'),
   (N'persona.verbosity',N'Длина ответов',N'Характер/Речь',45,N'0=коротко, 100=развёрнуто'),
   (N'persona.emojis',N'Эмодзи',N'Характер/Речь',20,N'0=без эмодзи, 100=много'),

   (N'visual.makeup',N'Интенсивность макияжа',N'Визуал',40,N'0=натурально, 100=ярко'),
   (N'visual.gloss',N'Глянец/ретушь',N'Визуал',35,N'0=натуральная кожа, 100=глянец'),
   (N'visual.hair_style',N'Стабильность прически',N'Визуал',70,N'0=часто менять, 100=почти фикс'),
   (N'visual.identity_lock',N'Жёсткость идентичности',N'Визуал',85,N'0=может меняться, 100=максимально одна и та же'),

   (N'outfit.formality',N'Формальность одежды',N'Одежда',40,N'0=спорт/дом, 100=вечернее/офис'),
   (N'outfit.seasonality',N'Сезонность одежды',N'Одежда',60,N'0=игнор, 100=строго по сезону'),
   (N'outfit.colorfulness',N'Цветность одежды',N'Одежда',45,N'0=монохром, 100=ярко'),
   (N'outfit.accessories',N'Аксессуары',N'Одежда',35,N'0=минимум, 100=много'),

   (N'camera.shot_size',N'Крупность плана',N'Камера',45,N'0=общий, 100=крупный'),
   (N'camera.angle',N'Угол камеры',N'Камера',50,N'0=сверху, 50=ровно, 100=снизу'),
   (N'camera.cinematic',N'Кинематографичность',N'Камера',55,N'0=просто, 100=киношно'),
   (N'light.softness',N'Мягкость света',N'Свет',60,N'0=жёсткий, 100=мягкий'),

   (N'scene.location_variety',N'Разнообразие локаций',N'Сцена',55,N'0=однотипно, 100=часто менять'),
   (N'scene.crowd',N'Людность',N'Сцена',25,N'0=без людей, 100=много людей'),
   (N'scene.time_of_day',N'Время суток',N'Сцена',50,N'0=ночь, 50=день, 100=закат'),

   (N'video.motion',N'Динамика движения',N'Видео',40,N'0=статично, 100=очень динамично'),
   (N'video.stabilization',N'Стабилизация',N'Видео',70,N'0=ручная камера, 100=стабильно'),

   (N'automation.post_rate',N'Частота постинга',N'Автоматизация',30,N'0=редко, 100=часто'),
   (N'automation.reply_rate',N'Частота ответов на комменты',N'Автоматизация',40,N'0=редко, 100=часто');
END
"@

Write-Step "Установка Piper (офлайн TTS) + RU голос"
$piperDir = Join-Path $Root "piper"
$piperModels = Join-Path $piperDir "models"
Ensure-Dir $piperDir
Ensure-Dir $piperModels

$piperZip = Join-Path $Installers "piper_windows_amd64.zip"
# Сначала пробуем GitHub asset, если отвалится — можно вручную заменить на SourceForge.
$piperUrl = "https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_windows_amd64.zip"
try {
  Download-File $piperUrl $piperZip
} catch {
  $fallback = "https://sourceforge.net/projects/piper-tts.mirror/files/2023.11.14-2/piper_windows_amd64.zip/download"
  Download-File $fallback $piperZip
}

Expand-Archive -Path $piperZip -DestinationPath $piperDir -Force

# RU voice: ru_RU-irina-medium (onnx + json)
$voiceOnnx = Join-Path $piperModels "ru_RU-irina-medium.onnx"
$voiceJson = Join-Path $piperModels "ru_RU-irina-medium.onnx.json"
Download-File "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/ru/ru_RU/irina/medium/ru_RU-irina-medium.onnx?download=true" $voiceOnnx
Download-File "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/ru/ru_RU/irina/medium/ru_RU-irina-medium.onnx.json?download=true" $voiceJson

Write-Step "Разворачивание ComfyUI"
$comfyDir = Join-Path $Root "comfyui"
if (-not (Test-Path $comfyDir)) {
  & git clone "https://github.com/Comfy-Org/ComfyUI.git" $comfyDir
}

$comfyVenv = Join-Path $comfyDir "venv"
if (-not (Test-Path $comfyVenv)) {
  Push-Location $comfyDir
  & py -3.11 -m venv $comfyVenv
  Pop-Location
}

$comfyPy  = Join-Path $comfyVenv "Scripts\python.exe"
$comfyPip = Join-Path $comfyVenv "Scripts\pip.exe"

# torch: ставим CUDA если есть nvidia-smi, иначе CPU
$hasNvidia = $false
if (Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue) { $hasNvidia = $true }

& $comfyPip install --upgrade pip wheel | Out-Null
if ($hasNvidia) {
  & $comfyPip install --upgrade torch torchvision torchaudio --index-url "https://download.pytorch.org/whl/cu121"
} else {
  & $comfyPip install --upgrade torch torchvision torchaudio --index-url "https://download.pytorch.org/whl/cpu"
}
Push-Location $comfyDir
& $comfyPip install -r "requirements.txt"
Pop-Location

# ComfyUI-Manager
$customNodes = Join-Path $comfyDir "custom_nodes"
Ensure-Dir $customNodes
$managerDir = Join-Path $customNodes "ComfyUI-Manager"
if (-not (Test-Path $managerDir)) {
  & git clone "https://github.com/Comfy-Org/ComfyUI-Manager" $managerDir
}

Write-Step "Backend (FastAPI) — скелет + venv"
$backendDir = Join-Path $Root "backend"
Ensure-Dir $backendDir

$backendReq = Join-Path $backendDir "requirements.txt"
@"
fastapi
uvicorn[standard]
python-dotenv
requests
pyodbc
Pillow
"@ | Out-File -FilePath $backendReq -Encoding utf8 -Force

$backendVenv = Join-Path $backendDir "venv"
if (-not (Test-Path $backendVenv)) {
  Push-Location $backendDir
  & py -3.11 -m venv $backendVenv
  Pop-Location
}
$backendPy  = Join-Path $backendVenv "Scripts\python.exe"
$backendPip = Join-Path $backendVenv "Scripts\pip.exe"
& $backendPip install --upgrade pip wheel | Out-Null
& $backendPip install -r $backendReq | Out-Null

# .env
$envFile = Join-Path $backendDir ".env"
@"
DB_SERVER=$SqlServer
DB_NAME=$DbName
DB_USER=$AdminLogin
DB_PASSWORD=$AdminPassword

WATERMARK_TEXT=$WatermarkText

COMFYUI_URL=http://127.0.0.1:8188
PIPER_EXE=$piperDir\piper.exe
PIPER_MODEL=$voiceOnnx
"@ | Out-File -FilePath $envFile -Encoding utf8 -Force

# app.py (минимальный API)
$appPy = Join-Path $backendDir "app.py"
@"
import os
from dotenv import load_dotenv
from fastapi import FastAPI
import pyodbc

load_dotenv()

app = FastAPI(title="AIGirl Backend (local)")

def get_cnx():
    # ODBC 17; шифрование выключаем (локальная Express без сертификата)
    server = os.getenv("DB_SERVER")
    db = os.getenv("DB_NAME")
    user = os.getenv("DB_USER")
    pwd = os.getenv("DB_PASSWORD")
    cs = (
        "Driver={ODBC Driver 17 for SQL Server};"
        f"Server={server};Database={db};"
        f"UID={user};PWD={pwd};"
        "Encrypt=no;TrustServerCertificate=yes;"
    )
    return pyodbc.connect(cs, timeout=5)

@app.get("/health")
def health():
    return {"ok": True}

@app.get("/settings")
def settings():
    cn = get_cnx()
    try:
        cur = cn.cursor()
        rows = cur.execute("SELECT [Key],[Value] FROM dbo.Settings").fetchall()
        return {r[0]: r[1] for r in rows}
    finally:
        cn.close()

@app.get("/parameters")
def parameters():
    cn = get_cnx()
    try:
        cur = cn.cursor()
        rows = cur.execute(
            "SELECT [Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu "
            "FROM dbo.ParameterDefinitions ORDER BY GroupRu, NameRu"
        ).fetchall()
        return [
            {
                "key": r[0],
                "nameRu": r[1],
                "groupRu": r[2],
                "min": int(r[3]),
                "max": int(r[4]),
                "default": int(r[5]),
                "hintRu": r[6],
            }
            for r in rows
        ]
    finally:
        cn.close()
"@ | Out-File -FilePath $appPy -Encoding utf8 -Force

Write-Step "Скрипты запуска сервисов"
$startComfy = Join-Path $Services "start_comfyui.ps1"
@"
Set-Location "$comfyDir"
& "$comfyPy" main.py --listen 127.0.0.1 --port 8188
"@ | Out-File -FilePath $startComfy -Encoding utf8 -Force

$startBackend = Join-Path $Services "start_backend.ps1"
@"
Set-Location "$backendDir"
& "$backendPy" -m uvicorn app:app --host 127.0.0.1 --port 8001
"@ | Out-File -FilePath $startBackend -Encoding utf8 -Force

Write-Step "Установка/обновление Windows Services через NSSM"
function Ensure-NssmService {
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$ScriptPath,
    [Parameter(Mandatory=$true)][string]$StdOut,
    [Parameter(Mandatory=$true)][string]$StdErr
  )

  $ps = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
  if (Get-Service -Name $Name -ErrorAction SilentlyContinue) {
    & nssm stop $Name | Out-Null
    & nssm remove $Name confirm | Out-Null
  }

  & nssm install $Name $ps "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" | Out-Null
  & nssm set $Name AppStdout $StdOut | Out-Null
  & nssm set $Name AppStderr $StdErr | Out-Null
  & nssm set $Name Start SERVICE_AUTO_START | Out-Null
  & nssm start $Name | Out-Null
}

Ensure-Dir $Logs
Ensure-NssmService -Name "AIGirl-ComfyUI" -ScriptPath $startComfy `
  -StdOut (Join-Path $Logs "comfyui_stdout.log") -StdErr (Join-Path $Logs "comfyui_stderr.log")

Ensure-NssmService -Name "AIGirl-Backend" -ScriptPath $startBackend `
  -StdOut (Join-Path $Logs "backend_stdout.log") -StdErr (Join-Path $Logs "backend_stderr.log")

Write-Step "Готово (база/сервисы/скелеты установлены)"
Write-Host "Проект:        $Root"
Write-Host "SQL Server:    $SqlServer"
Write-Host "DB:            $DbName"
Write-Host "Admin login:   $AdminLogin"
Write-Host "Admin password:$AdminPassword"
Write-Host ""
Write-Host "Проверка:"
Write-Host "  Backend health:  http://127.0.0.1:8001/health"
Write-Host "  Backend params:  http://127.0.0.1:8001/parameters"
Write-Host "  ComfyUI:         http://127.0.0.1:8188"
Write-Host ""
Write-Host "Следующий шаг: положить веса SD/ControlNet/LoRA в C:\AIGirl\data\models и собрать workflow в ComfyUI."

Stop-Transcript | Out-Null