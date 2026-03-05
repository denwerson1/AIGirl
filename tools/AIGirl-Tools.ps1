function Send-AIGirlEvent {
  param(
    [Parameter(Mandatory=$true)][string]$Text,
    [string]$CharacterKey = "nika",
    [double]$Sentiment = 0.3,
    [double]$Engagement = 0.6,
    [int]$AdminScore = $null,
    [string]$Lang = "ru",
    [string]$Uri = "http://127.0.0.1:8001/events"
  )

  $payload = [ordered]@{
    platform      = "admin"
    channel       = "dm"
    character_key = $CharacterKey
    event_type    = "inbound_message"
    lang          = $Lang
    text          = $Text
    sentiment     = $Sentiment
    engagement    = $Engagement
  }
  if ($null -ne $AdminScore) { $payload.admin_score = $AdminScore }

  $json  = $payload | ConvertTo-Json -Depth 10 -Compress
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

  try {
    $r = Invoke-WebRequest -Method Post -Uri $Uri `
      -ContentType "application/json; charset=utf-8" `
      -Body $bytes -ErrorAction Stop

    [pscustomobject]@{ StatusCode = $r.StatusCode; Body = $r.Content }
  } catch {
    $status = $null
    try { $status = $_.Exception.Response.StatusCode.value__ } catch {}

    $body = $null
    try {
      $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
      $body = $sr.ReadToEnd()
    } catch {}

    [pscustomobject]@{
      StatusCode = $status
      Body       = $body
      Error      = $_.Exception.Message
    }
  }
}

function Get-AIGirlUnprocessed {
  param(
    [int]$Limit = 50,
    [string]$CharacterKey = $null,
    [string]$Base = "http://127.0.0.1:8001"
  )
  $url = if ($CharacterKey) { "$Base/events/unprocessed?limit=$Limit&character_key=$CharacterKey" } else { "$Base/events/unprocessed?limit=$Limit" }
  Invoke-RestMethod -Method Get -Uri $url
}

function Invoke-AIGirlProcess {
  param(
    [int]$Limit = 100,
    [int]$DryRun = 0,
    [string]$CharacterKey = $null,
    [string]$Base = "http://127.0.0.1:8001"
  )
  $url = "$Base/events/process?limit=$Limit&dry_run=$DryRun"
  if ($CharacterKey) { $url = "$url&character_key=$CharacterKey" }
  Invoke-RestMethod -Method Post -Uri $url -ContentType "application/json" -Body "{}"
}

function Get-AIGirlPolicy {
  param(
    [string]$Prefix = "",
    [string]$Base = "http://127.0.0.1:8001"
  )
  $url = if ($Prefix) { "$Base/autotune/policy?prefix=$Prefix" } else { "$Base/autotune/policy" }
  Invoke-RestMethod -Method Get -Uri $url
}

function Set-AIGirlPolicy {
  param(
    [Parameter(Mandatory=$true)][string]$ParameterKey,
    [bool]$Enabled = $true,
    [int]$MinAllowed = 0,
    [int]$MaxAllowed = 100,
    [double]$LearnRate = 0.3,
    [hashtable]$Signals = $null,
    [string]$Base = "http://127.0.0.1:8001"
  )

  $obj = [ordered]@{
    parameter_key = $ParameterKey
    enabled       = $Enabled
    min_allowed   = $MinAllowed
    max_allowed   = $MaxAllowed
    learn_rate    = $LearnRate
  }
  if ($null -ne $Signals) { $obj.signals = $Signals }

  $body = ($obj | ConvertTo-Json -Depth 10 -Compress)
  Invoke-RestMethod -Method Post -Uri "$Base/autotune/policy/set" -ContentType "application/json; charset=utf-8" -Body $body
}
