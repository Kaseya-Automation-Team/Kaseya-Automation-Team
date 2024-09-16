function Enable-VSAUser
{
    <#
    .Synopsis
       Enables a single user account record.
    .DESCRIPTION
       Enables a single user account record.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER UserId
        Specifies a user account Id.
    .PARAMETER AdminName
        Specifies a user account name.
    .EXAMPLE
       Enable-VSAUser UserId 10001
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if addition was successful.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ById')]
    #[CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/users/{0}/enable',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $UserId
    )

    DynamicParam {

            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            
            [hashtable] $AuxParameters = @{}
            if($VSAConnection) {$AuxParameters.Add('VSAConnection', $VSAConnection)}

            [array] $script:Users = Get-VSAUser @AuxParameters | Select UserId, AdminName

            $ParameterName = 'AdminName' 
            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.ParameterSetName = 'ByName'
            $AttributesCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = $script:Users | Select-Object -ExpandProperty AdminName
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributesCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributesCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

            return $RuntimeParameterDictionary
        #}
    }# DynamicParam
    Begin {
        if ( -not $UserId ) {
            $UserId = $script:Users | Where-Object {$_.AdminName -eq $($PSBoundParameters.AdminName ) } | Select-Object -ExpandProperty UserId
        }
    }# Begin
    Process {
        
        [hashtable]$Params = @{
            'URISuffix' = $($URISuffix -f $UserId)
            'Method'    = 'PUT'
        }
        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
        
        #region messages to verbose and debug streams
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            "Enable-VSAUser: $($Params | Out-String)" | Write-Debug
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            "Enable-VSAUser: $($Params | Out-String)" | Write-Verbose
        }
        #endregion messages to verbose and debug streams

        return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Enable-VSAUser