#Requires -RunAsAdministrator
# One-time Windows setup, run from an elevated PowerShell after install.sh has deployed the
# configs. It points komorebi at them and registers the two scheduled tasks that start the desktop:
#   komorebi  at logon, not elevated: start-komorebi.ps1 (komorebi, bars, whkd, masir, then kanata)
#   kanata    no trigger, elevated, which a hook-based (winIOv2) kanata needs to remap admin windows.
#             A second start stops the running instance first, so starting the task is how kanata
#             is restarted after whkd.
# Two tasks because they need different privileges: anything whkd launches must not be elevated.
# The default kanata is the patched Interception build from ~/.config/kanata/windows/build.sh.
param(
    [string]$Kanata = 'D:\opt\kanata-1.12.0-outdev\kanata_windows_gui_wintercept_cmd_allowed_x64.exe'
)
$ErrorActionPreference = 'Stop'
$config = "$env:USERPROFILE\.config"
$user = "$env:USERDOMAIN\$env:USERNAME"

# komorebi reads komorebi.json from here; whkd uses its default, %USERPROFILE%\.config\whkdrc.
[Environment]::SetEnvironmentVariable('KOMOREBI_CONFIG_HOME', "$config\komorebi", 'User')
[Environment]::SetEnvironmentVariable('WHKD_CONFIG_HOME', $null, 'User')

$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit 0 -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
# StopExisting (3) is valid in Task Scheduler but missing from the cmdlet's enum.
$settings.CimInstanceProperties.Item('MultipleInstances').Value = 3
Register-ScheduledTask -Force -TaskName kanata -Settings $settings `
    -Action (New-ScheduledTaskAction -Execute $Kanata -Argument "-c `"$config\kanata\gallium.kbd`"") `
    -Principal (New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest) | Out-Null

Register-ScheduledTask -Force -TaskName komorebi `
    -Action (New-ScheduledTaskAction -Execute powershell.exe -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$config\komorebi\start-komorebi.ps1`"") `
    -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $user) `
    -Principal (New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited) `
    -Settings (New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries) | Out-Null

Get-ScheduledTask -TaskName kanata, komorebi | Format-Table TaskName, State, @{ n = 'RunLevel'; e = { $_.Principal.RunLevel } }
