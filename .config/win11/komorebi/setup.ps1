#Requires -RunAsAdministrator
# One-time Windows setup, run from an elevated PowerShell after install.sh has deployed the
# configs. It points komorebi at them and sets up the two things that start the desktop:
#   komorebi.lnk  in the Startup folder, not elevated: start-komorebi.cmd (komorebi, whkd, masir,
#                 YASB, then kanata) in a headless conhost so that no console window appears.
#                 Explorer starts it, so komorebi gets the foreground rights it needs; started by
#                 Task Scheduler it fails with "failed call to AllowSetForegroundWindow".
#   kanata task   no trigger, elevated, which a hook-based (winIOv2) kanata needs to remap admin
#                 windows. A second start stops the running instance first, so starting the task
#                 is how kanata is restarted after whkd.
# Two entry points because they need different privileges: anything whkd launches must not be
# elevated.
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

# The komorebi logon task that this shortcut replaced.
Unregister-ScheduledTask -TaskName komorebi -Confirm:$false -ErrorAction SilentlyContinue

$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut(
    "$([Environment]::GetFolderPath('Startup'))\komorebi.lnk")
$lnk.TargetPath = "$env:SystemRoot\System32\conhost.exe"
$lnk.Arguments = "--headless cmd.exe /d /c `"$config\komorebi\start-komorebi.cmd`""
$lnk.WorkingDirectory = "$config\komorebi"
$lnk.WindowStyle = 7
$lnk.Save()

Get-ScheduledTask -TaskName kanata | Format-Table TaskName, State, @{ n = 'RunLevel'; e = { $_.Principal.RunLevel } }
Write-Output "Startup: $($lnk.FullName)"
