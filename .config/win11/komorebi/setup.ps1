#Requires -RunAsAdministrator
# One-time Windows setup, run from an elevated PowerShell after install.sh has deployed the
# configs. It points komorebi at them and sets up the two things that start the desktop:
#   komorebi.lnk  in the Startup folder, not elevated: start-desktop.exe (komorebi, whkd, masir,
#                 YASB, then kanata), which takes the foreground rights komorebi needs itself;
#                 see start-desktop.cs. A copy on the Desktop starts what is missing by hand.
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

# The same launcher on the Desktop, to start whatever is missing by hand.
foreach ($folder in 'Startup', 'Desktop') {
    $lnk = (New-Object -ComObject WScript.Shell).CreateShortcut(
        "$([Environment]::GetFolderPath($folder))\komorebi.lnk")
    $lnk.TargetPath = "$config\komorebi\start-desktop.exe"
    $lnk.Arguments = ''
    $lnk.WorkingDirectory = "$config\komorebi"
    $lnk.IconLocation = "$((Get-Command komorebi.exe).Source),0"
    $lnk.Save()
    Write-Output "$($folder): $($lnk.FullName)"
}

Get-ScheduledTask -TaskName kanata | Format-Table TaskName, State, @{ n = 'RunLevel'; e = { $_.Principal.RunLevel } }
