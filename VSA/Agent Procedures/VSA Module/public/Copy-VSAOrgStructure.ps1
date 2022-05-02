function Copy-VSAOrgStructure {
    <#
    .Synopsis
       Creates organization structure.
    .DESCRIPTION
       Creates organization structure in an organization based on given array of Machine groups.
       Takes either persistent or non-persistent connection information.
    .PARAMETER SourceVSA
        Specifies existing non-persistent VSAConnection to the Source environment.
    .PARAMETER DestinationVSA
        Specifies existing non-persistent VSAConnection to the Destination environment.
    .PARAMETER OrgsToTransfer
        Specifies cource array of Organizations
    .PARAMETER ParentOrgId
        Optional parameter, specifies numeric id of the parent organization
    .EXAMPLE
        Copy-VSAOrgStructure -OrgsToTransfer $OrgsToTransfer -SourceVSA $SourceVSAConnection -DestinationVSA $DestinationVSAConnection
    .INPUTS
       Accepts piped parameters 
    .OUTPUTS
       No output
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $SourceVSA,

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $DestinationVSA,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [array] $OrgsToTransfer
    )

    #Sort Source Organizations So Parent Organizations Come First
    $OrgsToTransfer = $OrgsToTransfer | Where-Object { -not [string]::IsNullOrEmpty($_.OrgId) }

    [hashtable]$DestinationParams = @{VSAConnection = $DestinationVSA}
    [hashtable]$SourceParams = @{}
    if($SourceVSA) {$SourceParams.Add('VSAConnection', $SourceVSA)}

    $Info = "Organizations to create: [$(($OrgsToTransfer | Select-Object -ExpandProperty OrgRef) -join '; ') ]"

    $Info | Write-Host -ForegroundColor Cyan
    $Info | Write-Verbose
    $Info | Write-Debug

    [array] $global:DestinationOrgs = Get-VSAOrganization @DestinationParams
    [array] $SourceOrgs = Get-VSAOrganization @SourceParams

    Foreach ( $Organization in $( $OrgsToTransfer | Sort-Object -Property @{Expression = { $_.Orgref.Split('.').Count }}, @{Expression = {$_.ParentOrgId}; Ascending = $false} , @{Expression = {$_.OrgRef}; Ascending = $false} ) ) {

        [hashtable]$DestinationParams = @{VSAConnection = $DestinationVSA}

        $Info = "Orgranizations already created: [ $( $global:DestinationOrgs | Select-Object -ExpandProperty OrgRef | Out-String) ]"
        $Info | Write-Host
        $Info | Write-Verbose
        $Info | Write-Debug

        $Info = "Processing <$($Organization.OrgRef)>"
        $Info | Write-Host -ForegroundColor Cyan
        $Info | Write-Verbose
        $Info | Write-Debug

        [string] $ParentOrgId = ''

        #Check if the Parent Organization already exists in the destination.
        if( -not [string]::IsNullOrEmpty( $Organization.ParentOrgId ) ) {

            #obtain ParentOrgId by orgref
            $ParentRef = $SourceOrgs | Where-Object { $_.OrgId -eq $Organization.ParentOrgId } | Select-Object -ExpandProperty OrgRef
            if ( [string]::IsNullOrEmpty($ParentRef) ) {
                $Info = "Parent Organazation for <$($Organization.OrgRef)> not found in the source. Skip now"
                $Info | Write-Host -ForegroundColor DarkRed -BackgroundColor White
                $Info | Write-Verbose
                $Info | Write-Debug
                continue
            } else {
                $ParentOrgId = $global:DestinationOrgs | Where-Object { $_.OrgRef -eq $ParentRef } | Select-Object -ExpandProperty OrgId

                $Info = "Parent Organazation for <$($Organization.OrgRef)> : <$ParentRef>. Destination ParentOrgId <$ParentOrgId>. Can be created"
                $Info | Write-Host -ForegroundColor DarkGreen -BackgroundColor White
                $Info | Write-Verbose
                $Info | Write-Debug

                $Organization.ParentOrgId = $ParentOrgId 
            }
        }

        $CheckDestination = $global:DestinationOrgs | Where-Object { $_.OrgRef -eq $Organization.OrgRef }

        $Info = "CheckDestination for <$($Organization.OrgRef)>: found [$($CheckDestination.Count)]"
        $Info | Write-Host
        $Info | Write-Verbose
        $Info | Write-Debug


        if( 0 -eq $CheckDestination.Count ) {
            #Organization does not exis in the Destination. Create
            
            [string]$OrgRef = ($Organization.OrgRef.split('.'))[-1]
            $Organization.OrgRef = $OrgRef


            $AddOrgParams = $DestinationParams.Clone()
            $AddOrgParams.Add('ExtendedOutput',  $true)

            $Info = "No organization with OrgRef <$($Organization.OrgRef)>. Create."
            $Info | Write-Host -ForegroundColor Cyan
            $Info | Write-Verbose
            $Info | Write-Debug

            $Info = "Organization data:`n$($Organization | ConvertTo-Json -Depth 3 | Out-String)"
            $Info | Write-Verbose
            $Info | Write-Debug

            $NewOrgId = try { $Organization | Add-VSAOrganization @AddOrgParams } catch { $_.Exception.Message }
            if ( $NewOrgId -match "^\d+$" ) {
                $Info = "Created Organization <$($Organization.OrgRef)> with ID <$NewOrgId>"
                $Info | Write-Host -ForegroundColor Green
                $Info | Write-Verbose
                $Info | Write-Debug
            } else {
                $Info = "Something went wrong: <$NewOrgId>"
                $Info | Write-Host -ForegroundColor Red
                $Info | Write-Verbose
                $Info | Write-Debug
            } 
        }

        $global:DestinationOrgs = Get-VSAOrganization @DestinationParams

        $Info = "Orgranizations that are in the destination: $($global:DestinationOrgs | Select-Object -ExpandProperty OrgRef | Out-String)"
        $Info | Write-Host -ForegroundColor Cyan
        $Info | Write-Verbose
        $Info | Write-Debug

        [array]$DirectChildren = $SourceOrgs | Where-Object {$_.ParentOrgId -eq $Organization.OrgId }

        $Info = "[$($Organization.OrgRef)] `nDirect children: [$(($DirectChildren | Select-Object -ExpandProperty OrgRef) -join '; ' )]"
        $Info | Write-Host -ForegroundColor Yellow
        $Info | Write-Verbose
        $Info | Write-Debug

        if ( 0 -lt $DirectChildren.Count) {
            $Info = "--- Processing Direct children of <$($Organization.OrgRef)> ---`n[$($DirectChildren.Count)] Direct children of <$($Organization.OrgRef)>.`nCreate`n[$($DirectChildren | Select-Object -ExpandProperty OrgRef | Out-String)]`n==============="
            $Info | Write-Host
            $Info | Write-Verbose
            $Info | Write-Debug

            [hashtable]$CreateOrgParams = @{
                                            'OrgsToTransfer' = $DirectChildren
                                            'DestinationVSA' = $DestinationVSA
                                            }

            if($SourceVSA) {$CreateOrgParams.Add('SourceVSA', $SourceVSA)}

            $Info = $CreateOrgParams | Out-String
            $Info | Write-Verbose
            $Info | Write-Debug

            Copy-VSAOrgStructure @CreateOrgParams
        }
    }#Foreach
}
Export-ModuleMember -Function Copy-VSAOrgStructure