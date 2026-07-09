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
            
            ParameterSetName = 'ByName')]
        [parameter(DontShow, Mandatory=$false,
            
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
        [string] $UserId,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ByName')]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            try {
                $CompleterParams = @{}
                if ($fakeBoundParameters['VSAConnection']) { $CompleterParams['VSAConnection'] = $fakeBoundParameters['VSAConnection'] }
                Get-VSAUser @CompleterParams -ErrorAction Stop |
                    Select-Object -ExpandProperty AdminName |
                    Where-Object { $_ -like "$wordToComplete*" } |
                    ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
            } catch { }
        })]
        [ValidateNotNullOrEmpty()]
        [string] $AdminName
    )

    Begin {
        # A single targeted call resolves AdminName to UserId (F-44: no network calls during
        # parameter/command discovery; this only runs when the cmdlet actually executes).
        if ($PSCmdlet.ParameterSetName -eq 'ByName') {
            [hashtable]$LookupParams = @{}
            if ($VSAConnection) { $LookupParams['VSAConnection'] = $VSAConnection }
            [array]$Users = Get-VSAUser @LookupParams
            $UserId = $Users | Where-Object { $_.AdminName -eq $AdminName } | Select-Object -First 1 -ExpandProperty UserId
            if ([string]::IsNullOrEmpty($UserId)) {
                throw "Enable-VSAUser: No user found with AdminName '$AdminName'."
            }
        }
    }# Begin
    Process {

        return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($($URISuffix -f $UserId)) -VSAConnection $VSAConnection
    }
}
Export-ModuleMember -Function Enable-VSAUser