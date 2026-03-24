#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs dev tools via winget on a new machine.
.DESCRIPTION
    Installs PowerShell, VS Code (system), Terraform, cURL, and SOPS.
    Run this once on a new machine, then run Setup-UpdateTask.ps1 to register
    the weekly auto-update scheduled task.
#>

$tools = @(
    @{ Name = "PowerShell";      Id = "Microsoft.PowerShell" },
    @{ Name = "VS Code";         Id = "Microsoft.VisualStudioCode" },
    @{ Name = "Terraform";       Id = "Hashicorp.Terraform" },
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

Write-Host "`nAll tools installed. Run Setup-UpdateTask.ps1 to register the weekly update task." -ForegroundColor Yellow
