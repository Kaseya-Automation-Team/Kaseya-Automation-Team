<#
.Synopsis
   Creates a new AD user.
.DESCRIPTION
   Creates a new AD user. Used by Agent Procedure
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
Param
(
    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=0)]
    [ValidateNotNullOrEmpty()] 
    [string] $Name,

    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=1)]
    [ValidateNotNullOrEmpty()] 
    [string] $Password,

    [Parameter(Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                Position=1)]
    [string] $PackedParams
)

if ( $null -eq $(try {Get-ADUser -Identity $Name -ErrorAction Stop} catch {$null}) ){
    #user does not exist
    [string[]] $ParameterList = @('City', 'Country', 'Department', 'EmployeeID', 'MobilePhone', 'Office', 'OfficePhone', 'StreetAddres', 'Title', 'Description', 'Company', 'DisplayName', 'EmailAddress')
    if ( -not [string]::IsNullOrEmpty($PackedParams) ) {
        #Optional parameters were provided
        [string[]]$ParamPairs = $PackedParams.Split(';')

        [Hashtable]$UserAttributes = @{ Name = $Name
                                        Accountpassword = $($Password | ConvertTo-SecureString -AsPlainText -Force)
                                        Enabled = $true
                                        PassThru = $true
                                        ChangePasswordAtLogon = $true
                                        }

        foreach( $pair in $ParamPairs) {
            [string[]]$KeyValue = $pair.Split('=')
            if (2 -eq $KeyValue.Length) {
                [string]$Key = $KeyValue[0].Trim()
                if ( $ParameterList.Contains($Key) ) {
                    [string]$Value = $KeyValue[1].Trim()
                    $UserAttributes.Add( $Key,$Value)
                }
            }
        }
    }
    try {
        $DistinguishedName = New-ADUser @UserAttributes -ErrorAction Stop | Select-Object -ExpandProperty DistinguishedName
        $Result = "INFO: New AD user was created <$DistinguishedName>"
    } catch {
        $message = $_
        $Result = "ERROR: $message"
    }
} else {
    #user already exists
    $Result = "WARNING: The user <$Name> already exists. No user is created"
}

$Result | Write-Output