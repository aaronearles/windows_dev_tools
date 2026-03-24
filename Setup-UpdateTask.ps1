#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Registers (or updates) the AutoUpdate-DevTools scheduled task.
.DESCRIPTION
    Sets up a weekly silent winget upgrade task for PowerShell, VS Code,
    Terraform, cURL, and SOPS. Safe to re-run — will update the task if it
    already exists.
#>

$taskName = "AutoUpdate-DevTools"

# Resolve full winget path so the task works without PATH in its environment
$wingetPath = (Get-Command winget -ErrorAction Stop | Select-Object -ExpandProperty Source)
Write-Host "Using winget at: $wingetPath" -ForegroundColor Cyan

$packages = @(
    "Microsoft.PowerShell",
    "Microsoft.VisualStudioCode",
    "Hashicorp.Terraform",
    "cURL.cURL",
    "SecretsOPerationS.SOPS"
)

$argString = "upgrade --silent --accept-source-agreements --accept-package-agreements " + ($packages -join " ")

$action = New-ScheduledTaskAction -Execute $wingetPath -Argument $argString

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 9am

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 15) `
    -RunOnlyIfNetworkAvailable `
    -StartWhenAvailable

# Update if exists, register if not
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Write-Host "Task already exists — updating..." -ForegroundColor Yellow
    Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings
} else {
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -RunLevel Highest `
        -Description "Silently upgrades dev tools via winget every Monday at 9am"
}

Write-Host "`nTask '$taskName' is registered. Testing now..." -ForegroundColor Cyan
Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 5
$info = Get-ScheduledTaskInfo -TaskName $taskName
$result = $info.LastTaskResult

if ($result -eq 0) {
    Write-Host "Task ran successfully." -ForegroundColor Green
} else {
    Write-Warning "Task returned code $result — check Task Scheduler for details."
}
