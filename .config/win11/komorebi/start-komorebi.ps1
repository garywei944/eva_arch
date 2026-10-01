# Logon entry point, run by the "komorebi" scheduled task (see setup.ps1): start komorebi with
# whkd and masir, the YASB bar, then kanata. kanata's keyboard hook must be installed after whkd's,
# otherwise whkd sees physical keys instead of the Gallium layout.
komorebic start --whkd --masir
& "$env:ProgramFiles\YASB\yasbc.exe" start --silent
Start-Sleep -Seconds 1
Start-ScheduledTask -TaskName kanata
