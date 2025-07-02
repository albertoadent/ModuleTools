@{
    RootModule = 'ModuleTools.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'ModuleTools'
    CompanyName = 'ModuleTools'
    Copyright = '(c) 2024 ModuleTools. All rights reserved.'
    Description = 'PowerShell module for creating and managing other modules'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'New-Module',
        'Setup-ModuleTools', 
        'Remove-Module',
        'Get-ModuleInfo',
        'Update-ModuleTools',
        'Install-ModuleFromGitHub',
        'Get-ModuleInstallers',
        'Add-ModuleInstaller',
        'Show-ModuleInstallers'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('PowerShell', 'Module', 'Development', 'Automation')
            ProjectUri = 'https://github.com/albertoadent/ModuleTools'
            LicenseUri = 'https://github.com/albertoadent/ModuleTools/blob/main/LICENSE'
            ReleaseNotes = 'Initial release of ModuleTools'
        }
    }
} 