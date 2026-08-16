[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$taskName = "kanata"
$expectedExe = "D:\opt\windows-binaries-x64\kanata_windows_gui_winIOv2_cmd_allowed_x64.exe"
$knownExecutables = @(
    $expectedExe,
    "D:\opt\windows-binaries-x64\kanata_windows_gui_wintercept_cmd_allowed_x64.exe",
    "D:\opt\windows-binaries-x64\kanata_windows_tty_wintercept_cmd_allowed_x64.exe"
)

function Get-OwnedKanataProcesses {
    @(Get-CimInstance Win32_Process | Where-Object {
        $knownExecutables -contains $_.ExecutablePath
    })
}

Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
foreach ($process in @(Get-OwnedKanataProcesses)) {
    Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
}

$stopDeadline = (Get-Date).AddSeconds(15)
while (@(Get-OwnedKanataProcesses).Count -gt 0) {
    if ((Get-Date) -ge $stopDeadline) {
        throw "Timed out waiting for the previous Kanata generation to stop"
    }
    Start-Sleep -Milliseconds 200
}

$requestedAt = Get-Date
Start-ScheduledTask -TaskName $taskName
$startDeadline = (Get-Date).AddSeconds(30)
do {
    $task = Get-ScheduledTask -TaskName $taskName
    $matching = @(Get-OwnedKanataProcesses | Where-Object {
        $_.ExecutablePath -eq $expectedExe -and $_.CreationDate -ge $requestedAt
    })
    if ($task.State -eq "Running" -and $matching.Count -eq 1) {
        Write-Output "kanata_ready pid=$($matching[0].ProcessId)"
        exit 0
    }
    Start-Sleep -Milliseconds 250
} while ((Get-Date) -lt $startDeadline)

throw "Kanata did not reach Running state after whkd"
