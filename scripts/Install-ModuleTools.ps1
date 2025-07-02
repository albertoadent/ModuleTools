# ModuleTools One-Liner Installer
# Run this script from anywhere to install ModuleTools from GitHub

param(
    [switch]$Force
)

$modulePath = Join-Path ($env:PSModulePath -split ';' | Select-Object -First 1) "ModuleTools"
$repoUrl = "https://github.com/albertoadent/ModuleTools.git"

Write-Host "Installing ModuleTools to: $modulePath" -ForegroundColor Green

if(-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git is not installed. Installing Git..." -ForegroundColor Yellow
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    Start-Sleep -Seconds 10
    if(-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "Git is not installed. Please install Git and try again."
        exit 1
    }
    Write-Host "Git installed successfully." -ForegroundColor Green
}

if(Test-Path $modulePath -and -not $Force) {
    Write-Host "ModuleTools already exists at: $modulePath" -ForegroundColor Yellow
    Write-Host "Use -Force to reinstall." -ForegroundColor Yellow
    exit 0
}

if(Test-Path $modulePath -and $Force) {
    Write-Host "Removing existing ModuleTools installation..." -ForegroundColor Yellow
    Remove-Item $modulePath -Recurse -Force
}

Write-Host "Cloning ModuleTools from GitHub..." -ForegroundColor Cyan
try {
    git clone $repoUrl $modulePath
    Write-Host "ModuleTools cloned successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to clone ModuleTools repository. Please check your internet connection and try again."
    exit 1
}

Write-Host ""
Write-Host "ModuleTools installed successfully!" -ForegroundColor Green
Write-Host "You can now import it with: Import-Module -Name 'ModuleTools'" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available commands:" -ForegroundColor Yellow
Write-Host "  New-Module -Name 'MyModule' -Description 'My module' -Author 'Your Name'" -ForegroundColor White
Write-Host "  Show-ModuleInstallers" -ForegroundColor White
Write-Host "  Install-ModuleFromGitHub -ModuleName 'GitTools' -GitHubRepo 'https://github.com/albertoadent/GitTools.git'" -ForegroundColor White 