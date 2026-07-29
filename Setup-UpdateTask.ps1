#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Registers (or updates) the AutoUpdate-DevTools scheduled task.
.DESCRIPTION
    Sets up a weekly silent winget upgrade task for all tools. VS Code is upgraded last
    so other tools update even if VS Code is running and its installer fails.

    The task resolves the winget path at runtime so DesktopAppInstaller version updates
    do not break the task (a hardcoded version path becomes invalid after each update).
#>

$taskName = "AutoUpdate-DevTools"

$packages = @(
    "Microsoft.PowerShell",
    "Git.Git",
    "Microsoft.AzureCLI",
    "Hashicorp.Terraform",
    "OpenTofu.Tofu",
    "ShiningLight.OpenSSL.Light",
    "GNU.nano",
    "cURL.cURL",
    "SecretsOPerationS.SOPS",
    "GitHub.cli",
    # VS Code last — installer fails if it's running, so other tools update regardless
    "Microsoft.VisualStudioCode"
)

$ArgString = "upgrade --silent --accept-source-agreements --accept-package-agreements " + ($packages -join " ")

# Resolve winget at task run time (not registration time) so the task survives
# DesktopAppInstaller self-updates that change the versioned directory name.
# Single-quoted string prevents $WingetPath from expanding at registration time.
$Command = '$WingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*\winget.exe" | Sort-Object Path | Select-Object -Last 1 -ExpandProperty Path; & $WingetPath ' + $ArgString
$EncodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Command))

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NonInteractive -EncodedCommand $EncodedCommand"

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

# Wait for task to complete (max 2 minutes)
$timeout = 120
$elapsed = 0
while ($elapsed -lt $timeout) {
    Start-Sleep -Seconds 5
    $elapsed += 5
    $task = Get-ScheduledTask -TaskName $taskName
    if ($task.State -ne 'Running') {
        break
    }
    Write-Host "  Still running... ($elapsed seconds)" -ForegroundColor Gray
}

$info = Get-ScheduledTaskInfo -TaskName $taskName
$result = $info.LastTaskResult

if ($result -eq 0) {
    Write-Host "Task ran successfully." -ForegroundColor Green
} elseif ($result -eq 267009) {
    Write-Host "Task is still running (timed out waiting). Check Task Scheduler for final result." -ForegroundColor Yellow
} else {
    Write-Warning "Task returned code $result — check Task Scheduler for details."
}
