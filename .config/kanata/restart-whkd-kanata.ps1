[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$whkdExe = "C:\Program Files\whkd\bin\whkd.exe"
$helperTask = "kanata-restart-after-whkd"

$existing = @(Get-Process -Name "whkd" -ErrorAction SilentlyContinue)
if ($existing.Count -ne 1) {
    throw "Expected exactly one whkd process before restart, found $($existing.Count)"
}
$oldWhkdId = $existing[0].Id
Stop-Process -Id $oldWhkdId -Force

$stopDeadline = (Get-Date).AddSeconds(10)
while (Get-Process -Id $oldWhkdId -ErrorAction SilentlyContinue) {
    if ((Get-Date) -ge $stopDeadline) {
        throw "Timed out waiting for whkd PID $oldWhkdId to stop"
    }
    Start-Sleep -Milliseconds 100
}

$newWhkd = Start-Process -FilePath $whkdExe -WindowStyle Hidden -PassThru
$stableUntil = (Get-Date).AddSeconds(1)
while ((Get-Date) -lt $stableUntil) {
    Start-Sleep -Milliseconds 100
    if (-not (Get-Process -Id $newWhkd.Id -ErrorAction SilentlyContinue)) {
        throw "Replacement whkd exited before becoming stable"
    }
}

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
        # The elevated helper already verifies the exact executable path. A non-elevated
        # caller cannot reliably read ExecutablePath for the elevated Kanata process,
        # so verify the resulting process generation by its unique image name and time.
        $kanata = @(Get-Process -Name "kanata_windows_gui_winIOv2_cmd_allowed_x64" -ErrorAction SilentlyContinue)
        if ($kanata.Count -ne 1 -or $kanata[0].StartTime -le $newWhkd.StartTime) {
            throw "Kanata did not start after replacement whkd"
        }
        Write-Output "keyboard_stack_ready whkd=$($newWhkd.Id) kanata=$($kanata[0].Id)"
        exit 0
    }
    Start-Sleep -Milliseconds 250
} while ((Get-Date) -lt $helperDeadline)

throw "Timed out waiting for the Kanata restart helper"
