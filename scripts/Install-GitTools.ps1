# GitTools One-Liner Installer
# Run this script from anywhere to install GitTools from GitHub

param(
    [switch]$Force
)

$modulePath = Join-Path ($env:PSModulePath -split ';' | Select-Object -First 1) "GitTools"
$repoUrl = "https://github.com/albertoadent/GitTools.git"

Write-Host "Installing GitTools to: $modulePath" -ForegroundColor Green

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
    Write-Host "GitTools already exists at: $modulePath" -ForegroundColor Yellow
    Write-Host "Use -Force to reinstall." -ForegroundColor Yellow
    exit 0
}

if(Test-Path $modulePath -and $Force) {
    Write-Host "Removing existing GitTools installation..." -ForegroundColor Yellow
    Remove-Item $modulePath -Recurse -Force
}

Write-Host "Cloning GitTools from GitHub..." -ForegroundColor Cyan
try {
    git clone $repoUrl $modulePath
    Write-Host "GitTools cloned successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to clone GitTools repository. Please check your internet connection and try again."
    exit 1
}

Write-Host ""
Write-Host "GitTools installed successfully!" -ForegroundColor Green
Write-Host "You can now import it with: Import-Module -Name 'GitTools'" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available commands:" -ForegroundColor Yellow
Write-Host "  New-Git -User 'username' -Name 'Your Name' -Email 'your@email.com' -Token 'your_token'" -ForegroundColor White
Write-Host "  Get-Git" -ForegroundColor White
Write-Host "  Set-Git -User 'username'" -ForegroundColor White
Write-Host "  Create-Repo -Name 'MyRepo' -Description 'My repository'" -ForegroundColor White
Write-Host ""
Write-Host "Note: You'll need to set up a Git profile first using New-Git command." -ForegroundColor Yellow 