[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$whkdExe = "C:\Program Files\whkd\bin\whkd.exe"
$whkdConfig = "E:\Projects\eva_arch\.config\win11\whkd\whkdrc"
$helperTask = "kanata-restart-after-whkd"
$barConfigDir = "E:\Projects\eva_arch\.config\win11\komorebi"
$logPath = Join-Path $env:LOCALAPPDATA "komorebi\toggle-whkd.log"

# Rewrites the bar button label in every bar config; komorebi-bar hot-reloads
# the file. Write UTF-8 without BOM so the Rust JSON parser stays happy.
function Set-BarLabel {
    param([Parameter(Mandatory = $true)][string]$Label)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    foreach ($file in Get-ChildItem -Path (Join-Path $barConfigDir "komorebi.bar*.json")) {
        $text = [System.IO.File]::ReadAllText($file.FullName)
        $updated = $text -replace '"name": "WHKD[^"]*"', ('"name": "' + $Label + '"')
        if ($updated -ne $text) {
            [System.IO.File]::WriteAllText($file.FullName, $updated, $encoding)
        }
    }
}

$whkd = @(Get-Process -Name "whkd" -ErrorAction SilentlyContinue)
if ($whkd.Count -gt 0) {
    $whkd | Stop-Process -Force
    Set-BarLabel "WHKD OFF"
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
        Set-BarLabel "WHKD ON"
        Add-Content -LiteralPath $logPath -Value "$(Get-Date -Format o) whkd_resumed whkd=$($newWhkd.Id) kanata=$($kanata[0].Id)"
        Write-Output "whkd_resumed whkd=$($newWhkd.Id) kanata=$($kanata[0].Id)"
        exit 0
    }
    Start-Sleep -Milliseconds 250
} while ((Get-Date) -lt $helperDeadline)

throw "Timed out waiting for the Kanata restart helper"
