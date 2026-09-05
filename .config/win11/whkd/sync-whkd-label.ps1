[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$barConfigDir = "E:\Projects\eva_arch\.config\win11\komorebi"
$logPath = Join-Path $env:LOCALAPPDATA "komorebi\toggle-whkd.log"

# Derive the bar label from the actual whkd process state so the label heals
# no matter which path started or killed whkd (toggle button, komorebi
# restart, manual launch). komorebi-bar hot-reloads the config files.
$running = @(Get-Process -Name "whkd" -ErrorAction SilentlyContinue).Count -gt 0
$label = if ($running) { "WHKD ON" } else { "WHKD OFF" }

# Write UTF-8 without BOM so the Rust JSON parser stays happy.
$encoding = New-Object System.Text.UTF8Encoding($false)
$changed = @()
foreach ($file in Get-ChildItem -Path (Join-Path $barConfigDir "komorebi.bar*.json")) {
    $text = [System.IO.File]::ReadAllText($file.FullName)
    $updated = $text -replace '"name": "WHKD[^"]*"', ('"name": "' + $label + '"')
    if ($updated -ne $text) {
        [System.IO.File]::WriteAllText($file.FullName, $updated, $encoding)
        $changed += $file.Name
    }
}

$record = "$(Get-Date -Format o) label_synced label=`"$label`" changed=$($changed -join ',')"
Add-Content -LiteralPath $logPath -Value $record
Write-Output $record
