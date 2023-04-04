<#
.Synopsis
   Creates a new AD user.
.DESCRIPTION
   Creates a new AD user. Used by Agent Procedure
.NOTES
   Version 0.2
   Author: Proserv Team - VS
#>
Param
(
    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=0)]
    [string] $GivenName,

    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=1)]
    [string] $Surname,

    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=2)]
    [string] $CompanyName,

    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=3)]
    [string] $Department,

    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=4)]
    [string] $JobTitle,

    [Parameter(Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                Position=5)]
    [string] $Manager,

    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=6)]
    [string] $EmployeeID,

    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=7)]
    [string] $City,

    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=8)]
    [string] $State,

    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=9)]
    [string] $Password,

    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=10)]
    [string] $Domain
)

[bool]      $script:ParamsOK = $true
[string]    $script:Result = 'ERROR: '
[Hashtable] $script:UserAttributes = @{ Accountpassword = $($Password | ConvertTo-SecureString -AsPlainText -Force)
                                        Enabled = $true
                                        PassThru = $true
                                        ChangePasswordAtLogon = $true
}

function Add-Attribute {
    Param(
        [Parameter()]    
        [System.Object]
        $Attribute
    )
    $Line = @(Get-PSCallStack)[1].Position.Text
    if ($Line -match '(.*)(Add-Attribute)([ ]+)(-Attribute[ ]+)*\$(?<varName>([\w]+:)*[\w]*)(.*)') {
        if ( -not [string]::IsNullOrEmpty( $Attribute) ) {
            $UserAttributes.Add( $($Matches['varName']) ,$Attribute)
        } else {
            $script:Result += "Please provide $($Matches['varName']). Can't proceed without it!"
            $script:ParamsOK = $false
        }
    }
    
}

if ( $ParamsOK) {
    $script:Result = ''
    $SamAccountName = "$($GivenName.Substring(0,1))$Surname"

    $NameSake = $(try {Get-ADUser -Identity $SamAccountName -Properties EmployeeID -ErrorAction Stop} catch {$null})

    if ( $null -eq $NameSake ){
        #user does not exist
        
        $Name = "$GivenName $Surname"
        $DisplayName = $Name
        $EmailAddress = "$SamAccountName@$Domain"
        $UserPrincipalName = $EmailAddress
        $Office = "$State - $City"
        Add-Attribute -Attribute $GivenName
        Add-Attribute -Attribute $Surname
        Add-Attribute -Attribute $Name
        Add-Attribute -Attribute $SamAccountName
        Add-Attribute -Attribute $EmailAddress
        Add-Attribute -Attribute $UserPrincipalName
        Add-Attribute -Attribute $DisplayName
        Add-Attribute -Attribute $State
        Add-Attribute -Attribute $City
        Add-Attribute -Attribute $Office
        Add-Attribute -Attribute $EmployeeID

        $Manager = $(try {Get-ADUser $Manager -ErrorAction Stop | Select-Object -ExpandProperty SamAccountName} catch {$null})
        if ($null -ne $Manager) {
            Add-Attribute -Attribute $Manager
        }

        try {
            $DistinguishedName = New-ADUser @UserAttributes -ErrorAction Stop | Select-Object -ExpandProperty DistinguishedName
            $script:Result = "SUCCESS: New AD user was created <$DistinguishedName>"
        } catch {
            $message = $_
            $script:Result = "ERROR: $message"
        }
    } else {
        #user already exists
        $script:Result = "WARNING: The user <$($NameSake.DistinguishedName)> "
        if ( $EmployeeID -eq $NameSake.EmployeeID) {
            $script:Result += "with the same ID <$EmployeeID>"
        } else {
            $script:Result += "with ID <$($NameSake.EmployeeID)>"
        }
        $script:Result += " already exists. No user was created."
    }
}
$script:Result | Write-Output