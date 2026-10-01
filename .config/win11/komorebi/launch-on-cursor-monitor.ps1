# Open Arch WSL in WezTerm, or a new Chrome window, on the monitor under the mouse.
# komorebi tiles a new window on the monitor where it first appears. WezTerm is told to appear
# there; a running Chrome reuses its last window position instead, so its new window is moved
# once komorebi manages it.
param([Parameter(Mandatory = $true)][ValidateSet('Arch', 'Chrome')][string]$App)

# komorebic prints UTF-8; Windows PowerShell would garble CJK window titles and break the JSON.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-State { komorebic state | Out-String | ConvertFrom-Json }

function Get-Windows($State, $Exe) {
    $monitors = $State.monitors.elements
    for ($m = 0; $m -lt $monitors.Count; $m++) {
        foreach ($workspace in $monitors[$m].workspaces.elements) {
            foreach ($container in $workspace.containers.elements) {
                foreach ($window in $container.windows.elements) {
                    if ($window.exe -eq $Exe) { [pscustomobject]@{ Hwnd = $window.hwnd; Monitor = $m } }
                }
            }
        }
    }
}

function Get-FocusedHwnd($State) {
    $monitor = $State.monitors.elements[$State.monitors.focused]
    $workspace = $monitor.workspaces.elements[$monitor.workspaces.focused]
    $container = $workspace.containers.elements[$workspace.containers.focused]
    $container.windows.elements[$container.windows.focused].hwnd
}

komorebic focus-monitor-at-cursor
$state = Get-State
$target = $state.monitors.focused
$exe = @{ Arch = 'wezterm-gui.exe'; Chrome = 'chrome.exe' }[$App]
$known = @(Get-Windows $state $exe | ForEach-Object { $_.Hwnd })

if ($App -eq 'Arch') {
    $area = $state.monitors.elements[$target].work_area_size
    Start-Process 'C:\Program Files\WezTerm\wezterm-gui.exe' "start --always-new-process --position screen:$($area.left + 100),$($area.top + 100) --domain WSL:Arch"
} else {
    Start-Process 'C:\Program Files\Google\Chrome\Application\chrome.exe' '--new-window'
}

# Give komorebi up to 5 s to manage the new window, then move it if it landed elsewhere.
# komorebi focuses a window it has just tiled, and move-to-monitor acts on the focused one.
for ($i = 0; $i -lt 50; $i++) {
    Start-Sleep -Milliseconds 100
    $state = Get-State
    $new = @(Get-Windows $state $exe | Where-Object { $known -notcontains $_.Hwnd })
    if ($new.Count -eq 0) { continue }
    if ($new.Count -eq 1 -and $new[0].Monitor -ne $target -and (Get-FocusedHwnd $state) -eq $new[0].Hwnd) {
        komorebic move-to-monitor $target
        # komorebi skips re-laying out a window whose resize animation (for the brief arrival
        # above) has not moved it yet, so the monitor the new window left can keep its windows
        # half-sized. Retile once that animation (220 ms in komorebi.json) is over.
        Start-Sleep -Milliseconds 500
        komorebic retile
    }
    break
}
