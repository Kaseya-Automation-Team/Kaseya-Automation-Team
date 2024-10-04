# About

This module is designed to make it easier to use the Kaseya VSA API in your PowerShell scripts. By handling all the hard work, it allows you to develop your scripts faster and more efficiently. There's no need for a steep learning curve; simply load the module, enter your API keys, and get results within minutes!

**Note:** While this PowerShell module simplifies interaction with the Kaseya VSA REST API, it does not modify or impact the behavior of the API itself. Any issues or glitches that arise within the REST API are unrelated to the module and should be addressed to Kaseya directly.

## Basics

You can install the module from the [PowerShell Gallery](https://www.powershellgallery.com/packages/VSAModule). Use the example below to get started.

```powershell
begin {
    # Load the VSAModule
    $ModuleName = 'VSAModule'

    $CurrentVersion = try {
        Get-Module -Name $ModuleName -ListAvailable -ErrorAction Stop | Select-Object -ExpandProperty Version | Sort-Object -Descending | Select-Object -First 1
    } catch {
        $null
    }

    if (-not $CurrentVersion) {
        Install-Module -Name $ModuleName -Force
    } else {
        $latestVersion = Find-Module -Name $ModuleName | Select-Object -ExpandProperty Version | Sort-Object -Descending | Select-Object -First 1
        if ($CurrentVersion -lt $latestVersion) {
            Update-Module -Name $ModuleName -Force
        }
    }

    Import-Module -Name $ModuleName -Force

    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        throw "Failed to load module '$ModuleName'."
    }

    $VSAUserName = '<Kaseya VSA REST API User Name>'
    $VSAUserPAT =  '<Kaseya VSA REST API User PAT>'

    [securestring]$secStringPassword = ConvertTo-SecureString $VSAUserPAT -AsPlainText -Force
    [pscredential]$VSACred = New-Object System.Management.Automation.PSCredential ($VSAUserName, $secStringPassword)

    # Specify your Kaseya Environment Connection Parameters
    $VSAConnParams = @{
        VSAServer               = '<Kaseya API URL>'
        Credential              = $VSACred
        IgnoreCertificateErrors = $true  # or $false depending on your Certificate Error Policy
    }

    # Establish connection to the VSA Environment
    $VSAConnection = New-VSAConnection @VSAConnParams
}

process {
    # Get VSA Organizations Information
    $VSAOrganizations = Get-VSAOrganization -VSAConnection $VSAConnection
}
```

## Kaseya VSA API

Visit the [online help](http://help.kaseya.com/webhelp/EN/RESTAPI/9050000/index.asp#home.htm) to find out more about the Kaseya API. Or use your VSA swagger https://[your vsa url]/api/v1.0/swagger/ui/index to see and test the API.

## Release notes

### Version 0.1.4

- Updated Copy-VSAMGStructure Function

### Version 0.1.5

- Reduced the number of cmdlets while maintaining functionality

## Sponsored

Stay secure and compliant with Kaseya's comprehensive IT management solutions. Visit Kaseya today!
