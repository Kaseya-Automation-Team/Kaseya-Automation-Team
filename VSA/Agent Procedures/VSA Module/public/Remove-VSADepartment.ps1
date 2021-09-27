function Remove-VSADepartment
{
    <#
    .Synopsis
       Removes a department.
    .DESCRIPTION
       Removes a department.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER DepartmentId
        Specifies the Department Id.
    .EXAMPLE
       Remove-VSADepartment -DepartmentId 10001
    .EXAMPLE
       Remove-VSADepartment -DepartmentId 10001 -VSAConnection $connection
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
        [string] $URISuffix = 'api/v1.0/system/departments/{0}',

        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $DepartmentId
    )

    [hashtable]$Params = @{
                            'URISuffix' = $($URISuffix -f $DepartmentId)
                            'Method'    = 'DELETE'
                            }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Remove-VSADepartment