Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$bars = @(Get-Process -Name 'komorebi-bar' -ErrorAction SilentlyContinue)
$shell = New-Object -ComObject Shell.Application

if ($bars.Count -gt 0) {
    # Enter wallpaper mode: hide all komorebi bars and minimize open windows.
    $bars | Stop-Process -Force
    $shell.MinimizeAll()
    exit 0
}

# Leave wallpaper mode: restore windows and start one bar per configured monitor.
$shell.UndoMinimizeAll()

if ([string]::IsNullOrWhiteSpace($env:KOMOREBI_CONFIG_HOME)) {
    throw 'KOMOREBI_CONFIG_HOME is not set'
}

$configs = @(
    (Join-Path $env:KOMOREBI_CONFIG_HOME 'komorebi.bar.json'),
    (Join-Path $env:KOMOREBI_CONFIG_HOME 'komorebi.bar.monitor1.json'),
    (Join-Path $env:KOMOREBI_CONFIG_HOME 'komorebi.bar.monitor2.json')
)

foreach ($config in $configs) {
    if (-not (Test-Path -LiteralPath $config)) {
        throw "Missing bar configuration: $config"
    }
    Start-Process -FilePath 'komorebi-bar.exe' -ArgumentList @('--config', $config) -WindowStyle Hidden
}
