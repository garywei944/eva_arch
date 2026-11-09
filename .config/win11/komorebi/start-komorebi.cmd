@echo off
rem Logon entry point, run by the komorebi.lnk Startup shortcut through `conhost.exe --headless`
rem (see setup.ps1), so no console window ever appears. It replaces `komorebic start --whkd
rem --masir`, which runs one PowerShell per program and then sleeps 3 seconds.
rem `start /b` keeps the console programs in the headless console; YASB is a GUI program.
rem
rem komorebi can exit when it starts this early in a logon, so it is started again until it
rem answers, as `komorebic start` does. Its stderr, which only carries panics, is kept in
rem komorebi.err; its log on stdout is too chatty to keep.
set err=%LOCALAPPDATA%\komorebi\komorebi.err
set tries=0
:komorebi
start "" /b komorebi.exe 2>>"%err%"
ping -n 2 127.0.0.1 >nul
komorebic.exe state >nul 2>&1 && goto started
set /a tries+=1
>>"%err%" echo %date% %time% komorebi did not start, attempt %tries%
if %tries% lss 15 goto komorebi
:started
start "" /b whkd.exe
start "" /b masir.exe
start "" "%ProgramFiles%\YASB\yasb.exe"
schtasks.exe /run /tn kanata >nul
