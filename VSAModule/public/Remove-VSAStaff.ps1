function Remove-VSAStaff
{
    <#
    .Synopsis
       Updates a staff record.
    .DESCRIPTION
       Updates a staff record.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default..
    .PARAMETER StaffId
        Specifies Staff Id.
    .EXAMPLE
       Remove-VSAStaff -OrgStaffId 10001
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if removing was successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/staff/{0}',

        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $OrgStaffId
    )

    $URISuffix = $URISuffix -f $OrgStaffId
    $URISuffix | Write-Verbose
    $URISuffix | Write-Debug

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    $Params.Add('Method', 'DELETE')

    $Params | Out-String | Write-Debug

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Remove-VSAStaff