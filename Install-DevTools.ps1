#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs dev tools via winget on a new machine.
.DESCRIPTION
    Installs PowerShell, VS Code (system), Git, Azure CLI, Terraform, OpenTofu, OpenSSL, nano, cURL, and SOPS.
    Run this once on a new machine, then run Setup-UpdateTask.ps1 to register
    the weekly auto-update scheduled task.
#>

$tools = @(
    @{ Name = "PowerShell";      Id = "Microsoft.PowerShell" },
    @{ Name = "VS Code";         Id = "Microsoft.VisualStudioCode" },
    @{ Name = "Git";             Id = "Git.Git" },
    @{ Name = "Azure CLI";       Id = "Microsoft.AzureCLI" },
    @{ Name = "Terraform";       Id = "Hashicorp.Terraform" },
    @{ Name = "OpenTofu";        Id = "OpenTofu.Tofu" },
    @{ Name = "OpenSSL";         Id = "ShiningLight.OpenSSL.Light" },
    @{ Name = "nano";            Id = "GNU.nano" },
    @{ Name = "cURL";            Id = "cURL.cURL" },
    @{ Name = "SOPS";            Id = "SecretsOPerationS.SOPS" }
)

$commonArgs = "--silent --accept-source-agreements --accept-package-agreements"

foreach ($tool in $tools) {
    Write-Host "`nInstalling $($tool.Name)..." -ForegroundColor Cyan

    # VS Code gets --scope machine to ensure system install
    $scopeArg = if ($tool.Id -eq "Microsoft.VisualStudioCode") { "--scope machine" } else { "" }

    $expression = "winget install $($tool.Id) $commonArgs $scopeArg".Trim()
    Invoke-Expression $expression

    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
        # -1978335189 = already installed, still a success
        Write-Host "$($tool.Name) OK" -ForegroundColor Green
    } else {
        Write-Warning "$($tool.Name) may have failed (exit code $LASTEXITCODE)"
    }
}

# Fix OpenSSL PATH - prepend to avoid conflicts with bundled versions (e.g., ServiceNow agent)
$openSslBin = "C:\Program Files\OpenSSL-Win64\bin"
if (Test-Path $openSslBin) {
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
    if ($machinePath -notlike "*$openSslBin*") {
        Write-Host "`nPrepending OpenSSL to system PATH..." -ForegroundColor Cyan
        $newPath = "$openSslBin;$machinePath"
        [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::Machine)
        Write-Host "OpenSSL PATH updated." -ForegroundColor Green
    }
}

Write-Host "`nAll tools installed. Run Setup-UpdateTask.ps1 to register the weekly update task." -ForegroundColor Yellow
