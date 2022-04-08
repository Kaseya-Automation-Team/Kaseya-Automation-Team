function Copy-VSAOrgStructure {
    <#
    .Synopsis
       Creates organization structure.
    .DESCRIPTION
       Creates organization structure in an organization based on given array of Machine groups.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER SourceOrgs
        Specifies cource array of Organizations
    .PARAMETER ParentOrgId
        Optional parameter, specifies numeric id of the parent organization
    .EXAMPLE
        Copy-VSAOrgStructure -SourceOrgs $SourceOrgs
    .EXAMPLE
        Copy-VSAOrgStructure -SourceOrgs $SourceOrgs -VSAConnection $connection
    .INPUTS
       Accepts piped parameters 
    .OUTPUTS
       No output
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [array] $SourceOrgs,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $ParentOrgId
    )

    #Sort Source Organizations So Parent Organizations Come First
    $SourceOrgs = $SourceOrgs | Where-Object { -not [string]::IsNullOrEmpty($_.OrgId) } | Sort-Object -Property ParentOrgId, OrgRef

    [hashtable]$CommonParams = @{}        
    if($VSAConnection) {$CommonParams.Add('VSAConnection', $VSAConnection)}

    $Info = "Processing [$($SourceOrgs | Select-Object -ExpandProperty OrgRef | Out-String)], Parent <$ParentOrgId>"

    $Info | Write-Host -ForegroundColor Magenta
    $Info | Write-Verbose
    $Info | Write-Debug

    [array] $global:DestinationOrgs = Get-VSAOrganization @CommonParams

    [hashtable] $CompareParams = @{
                                        ReferenceObject  = $SourceOrgs.OrgRef
                                        DifferenceObject = $global:DestinationOrgs.OrgRef
                                    }
    [string[]] $OrgRefsToTransfer = Compare-Object @CompareParams | Where-Object {$_.SideIndicator -eq '<='} | Select-Object -ExpandProperty InputObject

    $Info = "To be created: [ $($OrgRefsToTransfer | Out-String) ]"
    $Info | Write-Host
    $Info | Write-Verbose
    $Info | Write-Debug


    Foreach ( $Organization in $( $SourceOrgs | Sort-Object -Property ParentOrgId, OrgRef ) ) {

        [hashtable]$CommonParams = @{}        
        if($VSAConnection) {$CommonParams.Add('VSAConnection', $VSAConnection)}

        $Info = "Processing <$($Organization.OrgRef)>"
        $Info | Write-Host -ForegroundColor Black -BackgroundColor White
        $Info | Write-Verbose
        $Info | Write-Debug

        #Check if the parent Organization already exists when provided.
        if( -not [string]::IsNullOrEmpty( $Organization.ParentOrgId ) ) {
            if ( [string]::IsNullOrEmpty( $ParentOrgId ) ) {
                #obtain ParentOrgId by orgref
                $ParentRef = $SourceOrgs | Where-Object { $_.OrgId -eq $Organization.ParentOrgId } | Select-Object -ExpandProperty OrgRef
                if ( [string]::IsNullOrEmpty($ParentRef) ) {
                    $Info = "Organization Can't be created. ParentOrgId not provided"
                    $Info | Write-Host -ForegroundColor Red
                    continue
                }
                $Info = "Parent Ref : <$ParentRef>"
                $Info | Write-Host -ForegroundColor Black -BackgroundColor White
                $Info | Write-Verbose
                $Info | Write-Debug
                $ParentOrgId = $global:DestinationOrgs | Where-Object { $_.OrgRef.split('.')[-1] -eq $ParentRef.split('.')[-1] } | Select-Object -ExpandProperty OrgId
                    
            }
            if ( $($global:DestinationOrgs | Select-Object -ExpandProperty OrgId) -notcontains $ParentOrgId ) {
                $Info = "Organization Can't be created. Parent <$ParentOrgId> doesn't exist"
                $Info | Write-Host -ForegroundColor Red
                $Info | Write-Verbose
                $Info | Write-Debug
                continue
            }
            $Info = "Parent <$ParentOrgId> exists, can create <$($Organization.OrgRef)>"
            $Info | Write-Host -ForegroundColor Green
            $Info | Write-Verbose
            $Info | Write-Debug
        }

        $OrgRefCandidate = ($Organization.OrgRef.split('.'))[-1]

        $Info = "Orgranizations already created: $( $global:DestinationOrgs | Select-Object -ExpandProperty OrgRef | Out-String)"
        $Info | Write-Host -ForegroundColor Cyan
        $Info | Write-Verbose
        $Info | Write-Debug

        $CheckDestination = $global:DestinationOrgs | Where-Object { $( ($_.OrgRef.split('.'))[-1] ) -eq $OrgRefCandidate }

        $Info = "CheckDestination <$($Organization.OrgRef)>  $($CheckDestination.Count)"
        $Info | Write-Host
        $Info | Write-Verbose
        $Info | Write-Debug


        if( $( $( ($global:DestinationOrgs | Select-Object -ExpandProperty OrgRef).split('.') ) ).Contains( $OrgRefCandidate ) ) {
            #Organization with this OrgRef already exists
            $ParentOrgIdCandidate  = $CheckDestination.OrgId
        } else {
            if ( -not [string]::IsNullOrEmpty( $ParentOrgId ) ) { $Organization.ParentOrgId = $ParentOrgId }
            $Organization.OrgRef = $OrgRefCandidate

            $AddOrgParams = $CommonParams.Clone()
            $AddOrgParams.Add('ExtendedOutput',  $true)

            $Info = "No organization with OrgRef <$($Organization.OrgRef)>. Create $($Organization | Out-String)"
            $Info | Write-Host
            $Info | Write-Verbose
            $Info | Write-Debug

            $ParentOrgIdCandidate = $Organization | Add-VSAOrganization @AddOrgParams

            $Info = "Created Organization <$ParentOrgIdCandidate>"
            $Info | Write-Host -ForegroundColor Green
            $Info | Write-Verbose
            $Info | Write-Debug
        }

        $global:DestinationOrgs = Get-VSAOrganization @CommonParams

        $Info = "Orgranizations that are in the destination: $($global:DestinationOrgs | Select-Object -ExpandProperty OrgRef | Out-String)"
        $Info | Write-Host -ForegroundColor Yellow
        $Info | Write-Verbose
        $Info | Write-Debug

        [array]$DirectChildren = $SourceOrgs | Where-Object {$_.ParentOrgId -eq $Organization.OrgId }

        $Info = "Source Parent Org IDs: [$($SourceOrgs | Select-Object -ExpandProperty ParentOrgId | Out-String)]`nCurrent Org Id <$($Organization.OrgId)>`n$SourceOrgs Direct children of <$($Organization.OrgRef)> : []"
        $Info | Write-Host -ForegroundColor Yellow
        $Info | Write-Verbose
        $Info | Write-Debug

        if ( 0 -lt $DirectChildren.Count) {
            $Info = "--- Processing Direct children of <$($Organization.OrgRef)> ---"
            $Info | Write-Host
            $Info | Write-Verbose
            $Info | Write-Debug
            $Info = "<$($DirectChildren.Count)> Direct children of <$($Organization.OrgRef)>. Create $($DirectChildren | Select-Object -ExpandProperty OrgRef | Out-String)"
            $Info | Write-Host
            $Info | Write-Verbose
            $Info | Write-Debug

            [hashtable]$CreateOrgParams = $CommonParams.Clone()

            $CreateOrgParams.Add('SourceOrgs',  $DirectChildren)
            $CreateOrgParams.Add('ParentOrgId', $ParentOrgIdCandidate)

            $Info = $CreateOrgParams | Out-String
            $Info | Write-Host -ForegroundColor Cyan
            $Info | Write-Verbose
            $Info | Write-Debug

            Copy-VSAOrgStructure @CreateOrgParams
        }
    }#Foreach
}
Export-ModuleMember -Function Copy-VSAOrgStructure