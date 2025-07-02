function New-Module {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Description = "",
        [string]$Author = "",
        [string]$Version = "1.0.0",
        [switch]$Force
    )
    
    # Get the modules directory path
    $modulesPath = Join-Path ($env:PSModulePath -split ';' | Select-Object -First 1) "ModuleTools"
    $targetModulePath = Join-Path ($env:PSModulePath -split ';' | Select-Object -First 1) $Name
    
    if(-not (Test-Path $modulesPath)) {
        Write-Error "ModuleTools not found. Run Setup-ModuleTools first."
        return
    }
    
    if(Test-Path $targetModulePath -and -not $Force) {
        Write-Error "Module $Name already exists. Use -Force to overwrite."
        return
    }
    
    if(Test-Path $targetModulePath -and $Force) {
        Remove-Item $targetModulePath -Recurse -Force
    }
    
    # Ensure GitTools is available
    if(-not (Get-Module -Name "GitTools" -ListAvailable)) {
        Write-Host "GitTools is required but not installed." -ForegroundColor Yellow
        $installGitTools = Read-Host "Would you like to install GitTools now? (y/n)"
        if($installGitTools -eq "y" -or $installGitTools -eq "yes") {
            Write-Host "Installing GitTools..." -ForegroundColor Cyan
            try {
                $gitToolsPath = Join-Path ($env:PSModulePath -split ';' | Select-Object -First 1) "GitTools"
                git clone "https://github.com/albertoadent/GitTools.git" $gitToolsPath
                Import-Module -Name "GitTools" -Force
                Write-Host "GitTools installed and imported successfully!" -ForegroundColor Green
            } catch {
                Write-Error "Failed to install GitTools. Please install it manually and try again."
                return
            }
        } else {
            Write-Error "GitTools is required to create modules with automatic GitHub repository creation."
            return
        }
    } elseif(-not (Get-Module -Name "GitTools")) {
        Import-Module -Name "GitTools" -Force
    }
    
    # Create module directory structure
    New-Item -ItemType Directory -Path $targetModulePath -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $targetModulePath "scripts") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $targetModulePath "docs") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $targetModulePath "tests") -Force | Out-Null
    
    # Create module manifest
    $manifestParams = @{
        Path = Join-Path $targetModulePath "$Name.psd1"
        RootModule = "$Name.psm1"
        ModuleVersion = $Version
        Author = $Author
        Description = $Description
        PowerShellVersion = "5.1"
        FunctionsToExport = @("Get-$Name", "Update-$Name", "Upload-$Name")
        CmdletsToExport = @()
        VariablesToExport = @()
        AliasesToExport = @()
    }
    
    New-ModuleManifest @manifestParams
    
    # Create main module file
    $moduleContent = @"
# $Name Module
# Created by ModuleTools

function Get-$Name {
    [CmdletBinding()]
    param()
    
    Write-Host "Hello from $Name module!"
}

Export-ModuleMember -Function Get-$Name
"@
    
    Set-Content -Path (Join-Path $targetModulePath "$Name.psm1") -Value $moduleContent
    
    # Create README
    $readmeContent = @"
# $Name

$Description

## Installation

```powershell
Import-Module -Name $Name
```

## Usage

```powershell
Get-$Name
```

## Functions

- `Get-$Name` - Basic function template
"@
    
    Set-Content -Path (Join-Path $targetModulePath "README.md") -Value $readmeContent
    
    # Create basic test file
    $testContent = @"
Describe '$Name Module Tests' {
    BeforeAll {
        Import-Module -Name '$targetModulePath' -Force
    }
    
    It 'Should import successfully' {
        Get-Module -Name '$Name' | Should -Not -BeNullOrEmpty
    }
    
    It 'Should have Get-$Name function' {
        Get-Command -Name 'Get-$Name' -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}
"@
    
    Set-Content -Path (Join-Path $targetModulePath "tests/$Name.Tests.ps1") -Value $testContent
    
    # Create Install script for the new module
    $installScriptContent = @"
# $Name One-Liner Installer
# Run this script from anywhere to install $Name from GitHub

param(
    [switch]`$Force
)

`$modulePath = Join-Path (`$env:PSModulePath -split ';' | Select-Object -First 1) "$Name"
`$repoUrl = "https://github.com/albertoadent/$Name.git"

Write-Host "Installing $Name to: `$modulePath" -ForegroundColor Green

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

if(Test-Path `$modulePath -and -not `$Force) {
    Write-Host "$Name already exists at: `$modulePath" -ForegroundColor Yellow
    Write-Host "Use -Force to reinstall." -ForegroundColor Yellow
    exit 0
}

if(Test-Path `$modulePath -and `$Force) {
    Write-Host "Removing existing $Name installation..." -ForegroundColor Yellow
    Remove-Item `$modulePath -Recurse -Force
}

Write-Host "Cloning $Name from GitHub..." -ForegroundColor Cyan
try {
    git clone `$repoUrl `$modulePath
    Write-Host "$Name cloned successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to clone $Name repository. Please check your internet connection and try again."
    exit 1
}

Write-Host ""
Write-Host "$Name installed successfully!" -ForegroundColor Green
Write-Host "You can now import it with: Import-Module -Name '$Name'" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available commands:" -ForegroundColor Yellow
Write-Host "  Get-$Name" -ForegroundColor White
Write-Host "  Update-$Name" -ForegroundColor White
Write-Host "  Upload-$Name -Message 'Your commit message'" -ForegroundColor White
"@
    
    Set-Content -Path (Join-Path $targetModulePath "scripts/Install-$Name.ps1") -Value $installScriptContent
    
    # Add Update and Upload functions to the main module file
    $updateFunctionContent = @"

function Update-$Name {
    [CmdletBinding()]
    param()
    
    `$modulePath = Join-Path (`$env:PSModulePath -split ';' | Select-Object -First 1) "$Name"
    
    if(-not (Test-Path `$modulePath)) {
        Write-Error "$Name not found. Run Install-$Name first."
        return
    }
    
    # Check if this is a git repository
    `$gitPath = Join-Path `$modulePath ".git"
    if(Test-Path `$gitPath) {
        if(-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Error "Git is not installed. Please install Git and try again."
            return
        }
        
        try {
            Write-Host "Updating $Name from git repository..." -ForegroundColor Cyan
            git -C `$modulePath pull
            Write-Host "$Name updated successfully!" -ForegroundColor Green
        } catch {
            Write-Error "Failed to update $Name from git repository."
            return
        }
    } else {
        Write-Host "$Name is not a git repository. Manual update required." -ForegroundColor Yellow
    }
}

function Upload-$Name {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$Message,
        [switch]`$Force
    )
    
    `$modulePath = Join-Path (`$env:PSModulePath -split ';' | Select-Object -First 1) "$Name"
    
    if(-not (Test-Path `$modulePath)) {
        Write-Error "$Name not found."
        return
    }
    
    # Check if this is a git repository
    `$gitPath = Join-Path `$modulePath ".git"
    if(-not (Test-Path `$gitPath)) {
        Write-Error "$Name is not a git repository."
        return
    }
    
    if(-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "Git is not installed. Please install Git and try again."
        return
    }
    
    try {
        Write-Host "Uploading changes to $Name repository..." -ForegroundColor Cyan
        
        # Change to module directory
        Push-Location `$modulePath
        
        # Add all changes
        git add -A
        
        # Commit with custom message
        git commit -m `$Message
        
        # Push to remote
        git push
        
        # Return to original location
        Pop-Location
        
        Write-Host "$Name uploaded successfully!" -ForegroundColor Green
        Write-Host "Commit message: `$Message" -ForegroundColor Yellow
    } catch {
        Write-Error "Failed to upload $Name to git repository."
        Pop-Location -ErrorAction SilentlyContinue
        return
    }
}
"@
    
    # Update the module content to include the Update and Upload functions
    $moduleContent = @"
# $Name Module
# Created by ModuleTools

function Get-$Name {
    [CmdletBinding()]
    param()
    
    Write-Host "Hello from $Name module!"
}

$updateFunctionContent

Export-ModuleMember -Function Get-$Name, Update-$Name, Upload-$Name
"@
    
    Set-Content -Path (Join-Path $targetModulePath "$Name.psm1") -Value $moduleContent
    
    Write-Host "Module '$Name' created successfully at: $targetModulePath" -ForegroundColor Green
    
    # Create GitHub repository using GitTools
    Write-Host "Creating GitHub repository for $Name..." -ForegroundColor Cyan
    try {
        Create-Repo -Name $Name -Description $Description -Path $targetModulePath -Visibility "public"
        Write-Host "GitHub repository created successfully!" -ForegroundColor Green
        
        # Add to ModuleTools installers list
        $gitHubRepo = "https://github.com/albertoadent/$Name.git"
        Add-ModuleInstaller -ModuleName $Name -Description $Description -GitHubRepo $gitHubRepo
        
        # Update ModuleTools repository
        Push-Location $modulesPath
        git add .
        git commit -m "Add $Name to module installers list"
        git push
        Pop-Location
        
        Write-Host "Module '$Name' added to installers list and ModuleTools updated!" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to create GitHub repository or update installers list. You may need to do this manually."
        Write-Host "Repository URL would be: https://github.com/albertoadent/$Name.git" -ForegroundColor Yellow
    }
    
    Write-Host "You can now import it with: Import-Module -Name '$Name'" -ForegroundColor Cyan
}

function Setup-ModuleTools {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    $modulePath = Join-Path ($env:PSModulePath -split ';' | Select-Object -First 1) "ModuleTools"
    
    if(Test-Path $modulePath -and -not $Force) {
        Write-Host "ModuleTools already exists at: $modulePath"
        Write-Host "Use -Force to recreate the directory structure."
        return
    }
    
    if(Test-Path $modulePath -and $Force) {
        Remove-Item $modulePath -Recurse -Force
    }
    
    # Create ModuleTools directory structure
    New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $modulePath "scripts") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $modulePath "templates") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $modulePath "docs") -Force | Out-Null
    
    # Create module manifest
    $manifestParams = @{
        Path = Join-Path $modulePath "ModuleTools.psd1"
        RootModule = "ModuleTools.psm1"
        ModuleVersion = "1.0.0"
        Author = "ModuleTools"
        Description = "PowerShell module for creating and managing other modules"
        PowerShellVersion = "5.1"
        FunctionsToExport = @("New-Module", "Setup-ModuleTools", "Remove-Module", "Get-ModuleInfo", "Update-ModuleTools")
        CmdletsToExport = @()
        VariablesToExport = @()
        AliasesToExport = @()
    }
    
    New-ModuleManifest @manifestParams
    
    # Create basic template
    $templateContent = @"
# Module Template
# Replace with your module name

function Get-ModuleTemplate {
    [CmdletBinding()]
    param()
    
    Write-Host "This is a template function. Replace with your actual functionality."
}

Export-ModuleMember -Function Get-ModuleTemplate
"@
    
    Set-Content -Path (Join-Path $modulePath "templates/basic.psm1") -Value $templateContent
    
    Write-Host "ModuleTools setup completed successfully at: $modulePath"
    Write-Host "You can now use New-Module to create new modules."
}

function Remove-Module {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [switch]$Force
    )
    
    $targetModulePath = Join-Path ($env:PSModulePath -split ';' | Select-Object -First 1) $Name
    
    if(-not (Test-Path $targetModulePath)) {
        Write-Error "Module '$Name' not found at: $targetModulePath"
        return
    }
    
    $confirmationMessage = "Are you sure you want to remove the module '$Name' from '$targetModulePath'?"
    
    if($Force -or $PSCmdlet.ShouldProcess($targetModulePath, $confirmationMessage)) {
        Remove-Item $targetModulePath -Recurse -Force
        Write-Host "Module '$Name' removed successfully."
    }
}

function Get-ModuleInfo {
    [CmdletBinding()]
    param(
        [string]$Name = "*"
    )
    
    $modulesPath = Join-Path ($env:PSModulePath -split ';' | Select-Object -First 1) $Name
    
    if(-not (Test-Path $modulesPath)) {
        Write-Error "No modules found matching pattern: $Name"
        return
    }
    
    Get-ChildItem -Path $modulesPath -Directory | ForEach-Object {
        $moduleName = $_.Name
        $modulePath = $_.FullName
        $manifestPath = Join-Path $modulePath "$moduleName.psd1"
        $moduleFile = Join-Path $modulePath "$moduleName.psm1"
        
        $info = [PSCustomObject]@{
            Name = $moduleName
            Path = $modulePath
            HasManifest = Test-Path $manifestPath
            HasModuleFile = Test-Path $moduleFile
            Created = $_.CreationTime
            LastModified = $_.LastWriteTime
        }
        
        if(Test-Path $manifestPath) {
            try {
                $manifest = Import-PowerShellDataFile -Path $manifestPath
                $info.Version = $manifest.ModuleVersion
                $info.Description = $manifest.Description
                $info.Author = $manifest.Author
            } catch {
                $info.Version = "Error reading manifest"
                $info.Description = "Error reading manifest"
                $info.Author = "Error reading manifest"
            }
        }
        
        $info
    }
}

function Update-ModuleTools {
    [CmdletBinding()]
    param()
    
    $modulePath = Join-Path ($env:PSModulePath -split ';' | Select-Object -First 1) "ModuleTools"
    
    if(-not (Test-Path $modulePath)) {
        Write-Error "ModuleTools not found. Run Setup-ModuleTools first."
        return
    }
    
    # Check if this is a git repository
    $gitPath = Join-Path $modulePath ".git"
    if(Test-Path $gitPath) {
        if(-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Error "Git is not installed. Please install Git and try again."
            return
        }
        
        try {
            Write-Host "Updating ModuleTools from git repository..."
            git -C $modulePath pull
            Write-Host "ModuleTools updated successfully."
        } catch {
            Write-Error "Failed to update ModuleTools from git repository."
            return
        }
    } else {
        Write-Host "ModuleTools is not a git repository. Manual update required."
    }
}

function Install-ModuleFromGitHub {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        [Parameter(Mandatory = $true)]
        [string]$GitHubRepo,
        [switch]$Force
    )
    
    $modulePath = Join-Path ($env:PSModulePath -split ';' | Select-Object -First 1) $ModuleName
    
    if(-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "Git is not installed. Please install Git and try again."
        return
    }
    
    if(Test-Path $modulePath -and -not $Force) {
        Write-Host "Module $ModuleName already exists at: $modulePath"
        Write-Host "Use -Force to reinstall."
        return
    }
    
    if(Test-Path $modulePath -and $Force) {
        Write-Host "Removing existing $ModuleName installation..."
        Remove-Item $modulePath -Recurse -Force
    }
    
    Write-Host "Installing $ModuleName from GitHub..."
    try {
        git clone $GitHubRepo $modulePath
        Write-Host "$ModuleName installed successfully!"
        Write-Host "You can now import it with: Import-Module -Name '$ModuleName'"
    } catch {
        Write-Error "Failed to install $ModuleName from GitHub. Please check the repository URL and try again."
    }
}

function Get-ModuleInstallers {
    [CmdletBinding()]
    param()
    
    $modulePath = Join-Path ($env:PSModulePath -split ';' | Select-Object -First 1) "ModuleTools"
    $installersPath = Join-Path $modulePath "module-installers.json"
    
    if(Test-Path $installersPath) {
        try {
            $installers = Get-Content $installersPath | ConvertFrom-Json
            return $installers
        } catch {
            Write-Error "Failed to read module installers file."
            return @()
        }
    } else {
        Write-Host "No module installers file found. Creating default list..."
        $defaultInstallers = @(
            @{
                Name = "GitTools"
                Description = "Git profile and repository management tools"
                GitHubRepo = "https://github.com/albertoadent/GitTools.git"
                InstallCommand = "Install-ModuleFromGitHub -ModuleName 'GitTools' -GitHubRepo 'https://github.com/albertoadent/GitTools.git'"
            },
            @{
                Name = "ModuleTools"
                Description = "PowerShell module creation and management tools"
                GitHubRepo = "https://github.com/albertoadent/ModuleTools.git"
                InstallCommand = "Install-ModuleFromGitHub -ModuleName 'ModuleTools' -GitHubRepo 'https://github.com/albertoadent/ModuleTools.git'"
            }
        )
        
        $defaultInstallers | ConvertTo-Json -Depth 3 | Set-Content $installersPath
        return $defaultInstallers
    }
}

function Add-ModuleInstaller {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        [Parameter(Mandatory = $true)]
        [string]$Description,
        [Parameter(Mandatory = $true)]
        [string]$GitHubRepo
    )
    
    $modulePath = Join-Path ($env:PSModulePath -split ';' | Select-Object -First 1) "ModuleTools"
    $installersPath = Join-Path $modulePath "module-installers.json"
    
    $installers = Get-ModuleInstallers
    
    # Check if module already exists
    $existingModule = $installers | Where-Object { $_.Name -eq $ModuleName }
    if($existingModule) {
        Write-Warning "Module $ModuleName already exists in installers list. Updating..."
        $installers = $installers | Where-Object { $_.Name -ne $ModuleName }
    }
    
    # Add new module
    $newModule = @{
        Name = $ModuleName
        Description = $Description
        GitHubRepo = $GitHubRepo
        InstallCommand = "Install-ModuleFromGitHub -ModuleName '$ModuleName' -GitHubRepo '$GitHubRepo'"
    }
    
    $installers += $newModule
    
    # Save updated list
    $installers | ConvertTo-Json -Depth 3 | Set-Content $installersPath
    
    Write-Host "Module $ModuleName added to installers list."
    Write-Host "Install command: $($newModule.InstallCommand)"
}

function Show-ModuleInstallers {
    [CmdletBinding()]
    param()
    
    $installers = Get-ModuleInstallers
    
    Write-Host "Available Module Installers:" -ForegroundColor Green
    Write-Host "=============================" -ForegroundColor Green
    
    foreach($installer in $installers) {
        Write-Host ""
        Write-Host "Module: $($installer.Name)" -ForegroundColor Yellow
        Write-Host "Description: $($installer.Description)"
        Write-Host "Repository: $($installer.GitHubRepo)"
        Write-Host "Install Command: $($installer.InstallCommand)" -ForegroundColor Cyan
    }
}

Export-ModuleMember -Function New-Module, Setup-ModuleTools, Remove-Module, Get-ModuleInfo, Update-ModuleTools, Install-ModuleFromGitHub, Get-ModuleInstallers, Add-ModuleInstaller, Show-ModuleInstallers 