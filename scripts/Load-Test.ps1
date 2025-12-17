# PowerShell Load Test Script for Audit Platform
# Simple concurrent request testing

param(
    [int]$Concurrency = 10,
    [int]$Requests = 100,
    [string]$QueryApiUrl = "http://localhost:8091",
    [string]$EventGatewayUrl = "http://localhost:8090"
)

Write-Host "=== Audit Platform Load Test ===" -ForegroundColor Cyan
Write-Host "Query API: $QueryApiUrl"
Write-Host "Event Gateway: $EventGatewayUrl"
Write-Host "Concurrency: $Concurrency"
Write-Host "Requests: $Requests"
Write-Host ""

# Test 1: Query API - List Events
Write-Host "=== Test 1: GET /v1/events (List) ===" -ForegroundColor Yellow
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$jobs = @()
for ($i = 1; $i -le $Requests; $i++) {
    $jobs += Start-Job -ScriptBlock {
        param($url)
        try {
            Invoke-RestMethod -Uri "$url/v1/events?limit=10" -Headers @{"X-Consumer-Name" = "audit-producer" } -TimeoutSec 30 | Out-Null
            return "OK"
        }
        catch {
            return "FAIL"
        }
    } -ArgumentList $QueryApiUrl
    
    if ($jobs.Count -ge $Concurrency) {
        $jobs | Wait-Job | Out-Null
        $jobs | Remove-Job
        $jobs = @()
    }
}
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job
$stopwatch.Stop()
$duration = $stopwatch.Elapsed.TotalSeconds
$rps = [math]::Round($Requests / $duration, 2)
Write-Host "Duration: $([math]::Round($duration,2))s | RPS: $rps" -ForegroundColor Green

# Test 2: Query API - Aggregations
Write-Host ""
Write-Host "=== Test 2: GET /v1/events/aggregations ===" -ForegroundColor Yellow
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$jobs = @()
for ($i = 1; $i -le $Requests; $i++) {
    $jobs += Start-Job -ScriptBlock {
        param($url)
        try {
            Invoke-RestMethod -Uri "$url/v1/events/aggregations" -Headers @{"X-Consumer-Name" = "audit-producer" } -TimeoutSec 30 | Out-Null
            return "OK"
        }
        catch {
            return "FAIL"
        }
    } -ArgumentList $QueryApiUrl
    
    if ($jobs.Count -ge $Concurrency) {
        $jobs | Wait-Job | Out-Null
        $jobs | Remove-Job
        $jobs = @()
    }
}
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job
$stopwatch.Stop()
$duration = $stopwatch.Elapsed.TotalSeconds
$rps = [math]::Round($Requests / $duration, 2)
Write-Host "Duration: $([math]::Round($duration,2))s | RPS: $rps" -ForegroundColor Green

# Test 3: Event Ingestion
Write-Host ""
Write-Host "=== Test 3: POST /v1/events (Ingestion) ===" -ForegroundColor Yellow
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$jobs = @()
for ($i = 1; $i -le $Requests; $i++) {
    $jobs += Start-Job -ScriptBlock {
        param($url, $idx)
        $body = @{
            event_id   = "load-test-$idx"
            event_date = (Get-Date).ToString("yyyy-MM-dd")
            actor      = @{ id = "load-tester" }
            action     = @{ name = "load-test" }
            resource   = @{ type = "test"; id = "$idx" }
            result     = @{ success = $true }
        } | ConvertTo-Json -Depth 3
        try {
            Invoke-RestMethod -Uri "$url/v1/events" -Method Post -Body $body -ContentType "application/json" -Headers @{"X-Consumer-Name" = "audit-producer" } -TimeoutSec 30 | Out-Null
            return "OK"
        }
        catch {
            return "FAIL"
        }
    } -ArgumentList $EventGatewayUrl, $i
    
    if ($jobs.Count -ge $Concurrency) {
        $jobs | Wait-Job | Out-Null
        $jobs | Remove-Job
        $jobs = @()
    }
}
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job
$stopwatch.Stop()
$duration = $stopwatch.Elapsed.TotalSeconds
$rps = [math]::Round($Requests / $duration, 2)
Write-Host "Duration: $([math]::Round($duration,2))s | RPS: $rps" -ForegroundColor Green

Write-Host ""
Write-Host "=== Load Test Complete ===" -ForegroundColor Cyan
