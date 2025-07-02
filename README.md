# ModuleTools

A PowerShell module for creating and managing other PowerShell modules. This tool makes it easy to create new modules with proper directory structure, manifests, and basic templates.

## Features

### Core Module Management
- **New-Module**: Create new PowerShell modules with proper structure
- **Setup-ModuleTools**: Initialize the ModuleTools directory structure
- **Remove-Module**: Safely remove modules from your modules directory
- **Get-ModuleInfo**: Get information about installed modules
- **Update-ModuleTools**: Update ModuleTools from git repository

### GitHub Module Installation
- **Install-ModuleFromGitHub**: Install any module directly from GitHub
- **Get-ModuleInstallers**: Get the list of available module installers
- **Add-ModuleInstaller**: Add a new module to the installers list
- **Show-ModuleInstallers**: Display all available module installers

## Installation

### One-liner installation from GitHub
```powershell
# Download and run the installer
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/albertoadent/ModuleTools/main/scripts/Install-ModuleTools.ps1" -OutFile "Install-ModuleTools.ps1"; .\Install-ModuleTools.ps1
```

Or if you have the repository cloned:
```powershell
.\scripts\Install-ModuleTools.ps1
```

This will:
1. Check if Git is installed (install it if needed)
2. Clone the ModuleTools repository from GitHub
3. Install it to your PowerShell modules directory

### Manual installation
```powershell
# Clone directly from GitHub
$modulePath = Join-Path ($env:PSModulePath -split ';' | Select-Object -First 1) "ModuleTools"
git clone https://github.com/albertoadent/ModuleTools.git $modulePath

# Import the module
Import-Module -Name "ModuleTools"
```

### Installing GitTools (Required for New-Module)
```powershell
# One-liner installation of GitTools
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/albertoadent/ModuleTools/main/scripts/Install-GitTools.ps1" -OutFile "Install-GitTools.ps1"; .\Install-GitTools.ps1
```

## Usage

### Create a new module
```powershell
New-Module -Name "MyAwesomeModule" -Description "A module for awesome things" -Author "Your Name"
```

This will create:
- A new module directory in your PowerShell modules path
- A module manifest (.psd1) file
- A main module file (.psm1) with basic functions including `Update-$Name`
- A README.md file
- A basic test file
- Standard directories (scripts, docs, tests)
- **Auto-generated `Install-$Name.ps1` script** for one-liner installation
- **Auto-generated `Update-$Name` function** for easy updates

### Remove a module
```powershell
Remove-Module -Name "MyAwesomeModule"
```

### Get information about modules
```powershell
# Get info about all modules
Get-ModuleInfo

# Get info about a specific module
Get-ModuleInfo -Name "MyAwesomeModule"
```

### Update ModuleTools
```powershell
Update-ModuleTools
```

### Install modules from GitHub
```powershell
# Install any module from GitHub
Install-ModuleFromGitHub -ModuleName "MyModule" -GitHubRepo "https://github.com/username/MyModule.git"

# Show available module installers
Show-ModuleInstallers

# Add a new module to the installers list
Add-ModuleInstaller -ModuleName "MyNewModule" -Description "My new module" -GitHubRepo "https://github.com/username/MyNewModule.git"
```

### Using auto-generated install scripts
Every module created with `New-Module` comes with its own installer script:

```powershell
# Download and run the module's installer
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/albertoadent/MyModule/main/scripts/Install-MyModule.ps1" -OutFile "Install-MyModule.ps1"; .\Install-MyModule.ps1

# Or if you have the module locally
.\MyModule\scripts\Install-MyModule.ps1
```

### Updating modules
Every module includes an auto-generated update function:

```powershell
Import-Module -Name "MyModule"
Update-MyModule  # Pulls latest version from GitHub
```

## Module Structure

When you create a new module with `New-Module`, it creates the following structure:

```
MyModule/
├── MyModule.psd1          # Module manifest
├── MyModule.psm1          # Main module file
├── README.md              # Documentation
├── scripts/               # Scripts directory
├── docs/                  # Documentation directory
└── tests/                 # Test files directory
    └── MyModule.Tests.ps1 # Basic Pester test file
```

## Integration with GitTools

ModuleTools is designed to work well with your existing GitTools module. After creating a module, you can:

1. Use GitTools to create a repository for your new module
2. Push your module to GitHub
3. Use GitTools to manage git profiles and repositories

Example workflow:
```powershell
# Create a new module
New-Module -Name "MyNewModule" -Description "My new module" -Author "Your Name"

# Create a git repository for it
Create-Repo -Name "MyNewModule" -Description "My new module" -Path "path\to\MyNewModule"
```

## Requirements

- PowerShell 5.1 or later
- Git (for Update-ModuleTools functionality)

## Contributing

Feel free to extend ModuleTools with additional functionality. The module is designed to be easily extensible. 