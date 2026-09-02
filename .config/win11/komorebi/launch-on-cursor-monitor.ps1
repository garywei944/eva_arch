[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Arch", "Chrome")]
    [string]$Application
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
# komorebic emits UTF-8; without this, CJK window titles are decoded via the
# OEM codepage and can swallow closing quotes, breaking ConvertFrom-Json.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$wezTermPath = "C:\Program Files\WezTerm\wezterm-gui.exe"
$windowTimeoutSeconds = 10
$logPath = Join-Path $env:LOCALAPPDATA "komorebi\launch-on-cursor-monitor.log"
Add-Content -LiteralPath $logPath -Value "$(Get-Date -Format o) launch_requested application=$Application"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class EvaCursorLaunchWindow {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
}
"@

function Get-ManagedWindows {
    param([Parameter(Mandatory = $true)][string]$ExecutableName)

    $state = (& komorebic state | Out-String | ConvertFrom-Json)
    $result = @()
    for ($monitorIndex = 0; $monitorIndex -lt $state.monitors.elements.Count; $monitorIndex++) {
        $monitor = $state.monitors.elements[$monitorIndex]
        for ($workspaceIndex = 0; $workspaceIndex -lt $monitor.workspaces.elements.Count; $workspaceIndex++) {
            $workspace = $monitor.workspaces.elements[$workspaceIndex]
            foreach ($container in @($workspace.containers.elements)) {
                foreach ($window in @($container.windows.elements)) {
                    if ($window.exe -eq $ExecutableName) {
                        $result += [pscustomobject]@{
                            Hwnd = [int64]$window.hwnd
                            Monitor = $monitorIndex
                            Workspace = $workspaceIndex
                            Title = [string]$window.title
                        }
                    }
                }
            }
        }
    }
    @($result)
}

$cursor = [System.Windows.Forms.Cursor]::Position
& komorebic focus-monitor-at-cursor | Out-Null
$targetMonitor = [int]((& komorebic query focused-monitor-index | Out-String).Trim())

switch ($Application) {
    "Arch" {
        if (-not (Test-Path -LiteralPath $wezTermPath)) {
            throw "WezTerm executable not found at $wezTermPath"
        }
        $executableName = "wezterm-gui.exe"
        $launch = {
            Start-Process -FilePath $wezTermPath -ArgumentList @(
                "start",
                "--always-new-process",
                "--position",
                "screen:$($cursor.X),$($cursor.Y)",
                "--domain",
                "WSL:Arch"
            )
        }
    }
    "Chrome" {
        if (-not (Test-Path -LiteralPath $chromePath)) {
            throw "Chrome executable not found at $chromePath"
        }
        $executableName = "chrome.exe"
        $launch = {
            Start-Process -FilePath $chromePath -ArgumentList @(
                "--new-window",
                "--window-position=$($cursor.X),$($cursor.Y)"
            )
        }
    }
}

$before = @{}
foreach ($window in @(Get-ManagedWindows -ExecutableName $executableName)) {
    $before[$window.Hwnd] = $true
}

& $launch
$deadline = (Get-Date).AddSeconds($windowTimeoutSeconds)
$newWindow = $null
do {
    $candidates = @(Get-ManagedWindows -ExecutableName $executableName | Where-Object {
        -not $before.ContainsKey($_.Hwnd)
    })
    if ($candidates.Count -gt 1) {
        throw "Expected one new $Application window, found $($candidates.Count)"
    }
    if ($candidates.Count -eq 1) {
        $newWindow = $candidates[0]
        break
    }
    Start-Sleep -Milliseconds 100
} while ((Get-Date) -lt $deadline)

if ($null -eq $newWindow) {
    throw "Timed out waiting for the new $Application window"
}

if ($newWindow.Monitor -ne $targetMonitor) {
    $null = [EvaCursorLaunchWindow]::SetForegroundWindow([IntPtr]$newWindow.Hwnd)
    Start-Sleep -Milliseconds 200
    $foreground = [EvaCursorLaunchWindow]::GetForegroundWindow().ToInt64()
    if ($foreground -ne $newWindow.Hwnd) {
        throw "Could not focus the new $Application window before moving it"
    }

    & komorebic move-to-monitor $targetMonitor | Out-Null
    do {
        $moved = @(Get-ManagedWindows -ExecutableName $executableName | Where-Object {
            $_.Hwnd -eq $newWindow.Hwnd -and $_.Monitor -eq $targetMonitor
        })
        if ($moved.Count -eq 1) {
            $newWindow = $moved[0]
            break
        }
        Start-Sleep -Milliseconds 100
    } while ((Get-Date) -lt $deadline)

    if ($newWindow.Monitor -ne $targetMonitor) {
        throw "The new $Application window did not reach monitor $targetMonitor"
    }
}

$record = "$(Get-Date -Format o) launch_ready application=$Application hwnd=$($newWindow.Hwnd) monitor=$targetMonitor"
Add-Content -LiteralPath $logPath -Value $record
Write-Output $record
