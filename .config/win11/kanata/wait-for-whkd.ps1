[CmdletBinding()]
param(
    [ValidateRange(1, 600)]
    [int]$TimeoutSeconds = 120,
    [ValidateRange(100, 10000)]
    [int]$StabilityMilliseconds = 1000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)

while ((Get-Date) -lt $deadline) {
    $processes = @(Get-Process -Name "whkd" -ErrorAction SilentlyContinue)
    if ($processes.Count -gt 1) {
        throw "Expected at most one whkd process, found $($processes.Count)"
    }
    if ($processes.Count -eq 1) {
        $candidateId = $processes[0].Id
        $stableUntil = (Get-Date).AddMilliseconds($StabilityMilliseconds)
        $stable = $true
        while ((Get-Date) -lt $stableUntil) {
            Start-Sleep -Milliseconds 100
            if (-not (Get-Process -Id $candidateId -ErrorAction SilentlyContinue)) {
                $stable = $false
                break
            }
        }
        if ($stable) {
            Write-Output "whkd_ready pid=$candidateId"
            exit 0
        }
    }
    Start-Sleep -Milliseconds 200
}

throw "whkd did not become stable within $TimeoutSeconds seconds"
