# Logon entry point, run by the "komorebi" scheduled task (see setup.ps1): start komorebi with
# whkd and masir, the YASB bar, then kanata. The order only matters for a hook-based (winIOv2)
# kanata, whose keyboard hook must be installed after whkd's (see README.md).
komorebic start --whkd --masir
& "$env:ProgramFiles\YASB\yasbc.exe" start --silent
Start-Sleep -Seconds 1
Start-ScheduledTask -TaskName kanata
