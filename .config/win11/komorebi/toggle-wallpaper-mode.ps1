# Wallpaper mode: hide the bar and minimise every window; run again to restore both.
# The marker only says which way to go next; a stale one costs one extra press.
$marker = Join-Path $env:TEMP 'wallpaper-mode'
$shell = New-Object -ComObject Shell.Application
$yasbc = "$env:ProgramFiles\YASB\yasbc.exe"

if (Test-Path $marker) {
    Remove-Item $marker
    $shell.UndoMinimizeAll()
    & $yasbc show-bar
} else {
    New-Item -ItemType File $marker | Out-Null
    & $yasbc hide-bar
    $shell.MinimizeAll()
}
