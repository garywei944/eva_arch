[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$komorebic = "C:\Program Files\komorebi\bin\komorebic-no-console.exe"
$syncLabelScript = "E:\Projects\eva_arch\.config\win11\whkd\sync-whkd-label.ps1"
$logPath = Join-Path $env:LOCALAPPDATA "komorebi\start-komorebi.log"

Add-Content -LiteralPath $logPath -Value "$(Get-Date -Format o) start_requested"
& $komorebic start --bar --whkd --masir

# whkd is spawned asynchronously by komorebic; wait for it before syncing the
# bar label so a startup race cannot leave a stale "WHKD OFF" from a previous
# session.
$deadline = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline) {
    if (@(Get-Process -Name "whkd" -ErrorAction SilentlyContinue).Count -gt 0) {
        break
    }
    Start-Sleep -Milliseconds 250
}

$record = & $syncLabelScript
Add-Content -LiteralPath $logPath -Value "$(Get-Date -Format o) start_finished $record"
