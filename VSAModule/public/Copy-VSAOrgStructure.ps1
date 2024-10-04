function Copy-VSAOrgStructure {
    <#
    .SYNOPSIS
        Creates organization structure.
    .DESCRIPTION
        Creates organization structure in an organization based on the given array of organizations.
    .PARAMETER SourceVSA
        Specifies established VSAConnection to the Source environment.
    .PARAMETER DestinationVSA
        Specifies established VSAConnection to the Destination environment.
    .PARAMETER OrgsToTransfer
        Specifies source array of Organizations.
    .PARAMETER ParentOrgId
        Optional parameter, specifies numeric id of the parent organization, if needed to transfer a specific organization and its sub-organizations.
    .EXAMPLE
        Copy-VSAOrgStructure -OrgsToTransfer $OrgsToTransfer -SourceVSA $SourceVSAConnection -DestinationVSA $DestinationVSAConnection
    .INPUTS
        Accepts piped parameters.
    .OUTPUTS
        No output.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $SourceVSA,

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $DestinationVSA,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [array] $OrgsToTransfer
    )

    if ( $SourceVSA -eq $DestinationVSA ) {
        throw "The Source and the Destionation is the same VSA Environment!"
    }

    [hashtable]$DestinationParams = @{VSAConnection = $DestinationVSA}
    [hashtable]$SourceParams      = @{VSAConnection = $SourceVSA}

    # Retrieve existing organizations in the source and the destination
    [array] $SourceOrgs      = Get-VSAOrganization @SourceParams
    [array] $DestinationOrgs = Get-VSAOrganization @DestinationParams

    #region message
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "Organizations to be created: [$($OrgsToTransfer.OrgRef -join '; ')]" | Write-Debug
        "Organizations already present in the destination: [$($DestinationOrgs.OrgRef -join '; ')]" | Write-Debug
    }
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        "Organizations to be created: [$($OrgsToTransfer.OrgRef -join '; ')]" | Write-Verbose
        "Organizations already present in the destination: [$($DestinationOrgs.OrgRef -join '; ')]" | Write-Verbose
    }
    #endregion message

    Foreach ($Organization in $OrgsToTransfer | Sort-Object -Property @{
                Expression = { $_.Orgref.Split('.').Count }
            }, @{
                Expression = {$_.OrgRef}
                Ascending = $false
            }) {

        [hashtable]$DestinationParams = @{VSAConnection = $DestinationVSA}

        [string]$Info = "Processing Organization: '$($Organization.OrgRef)'"
        #region message
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { Write-Debug $Info }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { Write-Verbose $Info }
        #endregion message

        #region Define the current Organiztion's own OrgRef and the parent organization OrgRef (if exists)

        [string] $OwnOrgRef = ($Organization.OrgRef.split('.'))[-1]

        $ParentOrgRef = [string]::Empty
        [int] $strLength = $organization.OrgRef.LastIndexOf('.')
        if (0 -lt $strLength ) {
            [string] $ParentOrgRef = $organization.OrgRef.Substring( 0, $strLength )
        }
        
        $Organization.OrgRef = $OwnOrgRef
        
        #endregion Define the current Organization's own OrgRef and the parent organization OrgRef (if exists)


        # Check if the Parent Organization already exists in the destination.
        if ( -not [string]::IsNullOrEmpty($ParentOrgRef) ) {

            $DestinationParentOrgId =  Get-VSAOrganization @DestinationParams -Filter "OrgRef eq '$ParentOrgRef'" | Select-Object -ExpandProperty OrgId

            #region message
            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                Write-Debug "Parent Organization for '$($Organization.OrgRef)' : '$ParentOrgRef'. Destination ParentOrgId: '$DestinationParentOrgId'."
            }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                Write-Verbose "Parent Organization for '$($Organization.OrgRef)' : '$ParentOrgRef'. Destination ParentOrgId: '$DestinationParentOrgId'."
            }
            #endregion message

            #Replace source's ParentOrgId with the destination's counterpart
            $Organization.ParentOrgId = $DestinationParentOrgId
        }

        #region message
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug   "Look up the Destination for '$($Organization.OrgRef)'"
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            Write-Verbose "Look up the Destination for '$($Organization.OrgRef)'"
        }
        #endregion message

        $CheckDestination = Get-VSAOrganization @DestinationParams -Filter "OrgRef eq '$OwnOrgRef'"

        if ( $null -eq $CheckDestination ) {
            # The Organization does not exist in the Destination. Create

            $NewOrgParams = $DestinationParams.Clone()
            $NewOrgParams.Add('ExtendedOutput',  $true)

            if ($PSCmdlet.MyInvocation.BoundParameters['Debug'])   { $NewOrgParams.Add('Debug', $true) }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { $NewOrgParams.Add('Verbose', $true) }

            #region message
            $Info = "Organization with OrgRef '$($Organization.OrgRef)' was not found in the destination. Will attempt to create it."
            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { Write-Debug $Info }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { Write-Verbose $Info }

            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                "Organization will be created with the following data:`n'$($Organization | ConvertTo-Json -Depth 3 | Out-String)'" | Write-Debug
            }
            #endregion message

            $NewOrgId = try {
                $Organization | New-VSAOrganization @NewOrgParams
            } catch {
                Write-Host "Error creating organization: $_.Exception.Message" -ForegroundColor Red
                $null  # Ensure $NewOrgId is null on failure
            }


            if ($null -ne $NewOrgId -and $NewOrgId -match "^\d+$") {
                #region message
                $Info = "Successfully created organization '$($Organization.OrgRef)' with ID '$NewOrgId'."
                Write-Host $Info
                if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { Write-Verbose $Info }
                if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { Write-Debug $Info }
                #endregion message

                #Make the REST API wait while the BackEnd updates the information
                [int]$WaitSec = 0
                [int]$StopWait = 60
                [string]$CheckNewOrgId = try {Get-VSAOrganization @DestinationParams -OrgID $NewOrgId -ErrorAction Stop | Select-Object -ExpandProperty OrgID } catch { $null }
                while ( [string]::IsNullOrEmpty($CheckNewOrgId) ) {
                    $WaitSec++
                    Start-Sleep -Seconds 1
                    $CheckNewOrgId = try {Get-VSAOrganization @DestinationParams -OrgID $NewOrgId -ErrorAction Stop | Select-Object -ExpandProperty OrgID } catch { $null }
                    if ($WaitSec -ge $StopWait) { break}
                }
            } else {
                #region message
                $Info = "Something went wrong while creating '$($Organization.OrgRef)'. Returned ID: '$NewOrgId'"
                Write-Host $Info -ForegroundColor Red
                if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { Write-Verbose $Info }
                if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                    Write-Debug $Info
                    Write-Debug "JSON data:`n$($Organization | ConvertTo-Json -Depth 3 | Out-String)"
                }
                #endregion message
            } 
        }
        else {
            #$CheckDestination is not null
            continue
        }
    } # Foreach
}

Export-ModuleMember -Function Copy-VSAOrgStructure