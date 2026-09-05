[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$whkdExe = "C:\Program Files\whkd\bin\whkd.exe"
$whkdConfig = "E:\Projects\eva_arch\.config\win11\whkd\whkdrc"
$helperTask = "kanata-restart-after-whkd"
$logPath = Join-Path $env:LOCALAPPDATA "komorebi\toggle-whkd.log"

# The bar label is derived from process state so it stays truthful across
# every start/stop path, not just this toggle.
$syncLabelScript = "E:\Projects\eva_arch\.config\win11\whkd\sync-whkd-label.ps1"

$whkd = @(Get-Process -Name "whkd" -ErrorAction SilentlyContinue)
if ($whkd.Count -gt 0) {
    $whkd | Stop-Process -Force
    & $syncLabelScript | Out-Null
    Add-Content -LiteralPath $logPath -Value "$(Get-Date -Format o) whkd_paused pids=$($whkd.Id -join ',')"
    Write-Output "whkd_paused"
    exit 0
}

$newWhkd = Start-Process -FilePath $whkdExe -ArgumentList @("--config", $whkdConfig) -WindowStyle Hidden -PassThru
$stableUntil = (Get-Date).AddSeconds(1)
while ((Get-Date) -lt $stableUntil) {
    Start-Sleep -Milliseconds 100
    if (-not (Get-Process -Id $newWhkd.Id -ErrorAction SilentlyContinue)) {
        throw "Replacement whkd exited before becoming stable"
    }
}

# Keep the repository invariant: kanata restarts after whkd starts.
$before = Get-ScheduledTaskInfo -TaskName $helperTask
Start-ScheduledTask -TaskName $helperTask
$helperDeadline = (Get-Date).AddSeconds(45)
do {
    $task = Get-ScheduledTask -TaskName $helperTask
    $info = Get-ScheduledTaskInfo -TaskName $helperTask
    if ($info.LastRunTime -gt $before.LastRunTime -and $task.State -eq "Ready") {
        if ($info.LastTaskResult -ne 0) {
            throw "Kanata restart helper failed with Task Scheduler result $($info.LastTaskResult)"
        }
        $kanata = @(Get-Process -Name "kanata_windows_gui_winIOv2_cmd_allowed_x64" -ErrorAction SilentlyContinue)
        if ($kanata.Count -ne 1 -or $kanata[0].StartTime -le $newWhkd.StartTime) {
            throw "Kanata did not start after replacement whkd"
        }
        & $syncLabelScript | Out-Null
        Add-Content -LiteralPath $logPath -Value "$(Get-Date -Format o) whkd_resumed whkd=$($newWhkd.Id) kanata=$($kanata[0].Id)"
        Write-Output "whkd_resumed whkd=$($newWhkd.Id) kanata=$($kanata[0].Id)"
        exit 0
    }
    Start-Sleep -Milliseconds 250
} while ((Get-Date) -lt $helperDeadline)

throw "Timed out waiting for the Kanata restart helper"
