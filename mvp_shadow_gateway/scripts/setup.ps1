param(
  [string]$Org = "retrofit4",
  [string]$User = "admin",
  [string]$Pass = $( -join ((48..57 + 65..90 + 97..122) | Get-Random -Count 16 | ForEach-Object {[char]$_}) )
)

$ErrorActionPreference = "Stop"
$envPath = Join-Path $PSScriptRoot "..\.env"
$envExample = Join-Path $PSScriptRoot "..\.env.example"

if (!(Test-Path $envPath)) {
  Copy-Item $envExample $envPath
  (Get-Content $envPath) -replace "<definir-no-setup>", $Pass | Set-Content $envPath
  (Get-Content $envPath) -replace "<preencher-pelo-setup>", "will_be_set" | Set-Content $envPath
  Write-Host ".env criado" -ForegroundColor Green
}

Push-Location (Join-Path $PSScriptRoot "..")
docker compose up -d influxdb grafana
Start-Sleep -Seconds 15

docker exec mvp_influxdb influx setup --bucket mvp --org $Org --username $User --password $Pass --force --retention 30d | Out-Null

$Token = docker exec mvp_influxdb influx auth create --all-access --json | ConvertFrom-Json | Select-Object -ExpandProperty token
Write-Host ("Token gerado: " + $Token.Substring(0,8) + "...")

docker exec mvp_influxdb influx bucket create -n mvp_raw -o $Org -r 2160h | Out-Null
docker exec mvp_influxdb influx bucket create -n mvp_agg -o $Org -r 17520h | Out-Null

(Get-Content $envPath) -replace "INFLUX_TOKEN=.*", "INFLUX_TOKEN=$Token" | Set-Content $envPath

$taskFile = "/mnt/influx/tasks/oee_agg_15m.flux"
docker cp (Join-Path $PSScriptRoot "..\influx\tasks\oee_agg_15m.flux") mvp_influxdb:$taskFile
docker exec mvp_influxdb influx task create -f $taskFile -o $Org -t $Token | Out-Null

Pop-Location
Write-Host "Setup concluído." -ForegroundColor Green
