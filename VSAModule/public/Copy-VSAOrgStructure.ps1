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

    # Sort Source Organizations So Parent Organizations Come First
    $OrgsToTransfer = $OrgsToTransfer | Where-Object { -not [string]::IsNullOrEmpty($_.OrgId) }

    [hashtable]$DestinationParams = @{VSAConnection = $DestinationVSA}
    [hashtable]$SourceParams      = @{VSAConnection = $SourceVSA}

    # Retrieve existing organizations in the destination
    [array] $global:DestinationOrgs = Get-VSAOrganization @DestinationParams
    [array] $SourceOrgs             = Get-VSAOrganization @SourceParams

    #region message
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "Organizations to be created: [$($OrgsToTransfer.OrgRef -join '; ')]" | Write-Debug
        "Organizations already present in the destination: [$($global:DestinationOrgs.OrgRef -join '; ')]" | Write-Debug
    }
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        "Organizations to be created: [$($OrgsToTransfer.OrgRef -join '; ')]" | Write-Verbose
        "Organizations already present in the destination: [$($global:DestinationOrgs.OrgRef -join '; ')]" | Write-Verbose
    }
    #endregion message

    Foreach ($Organization in $OrgsToTransfer | Sort-Object -Property @{
                Expression = { $_.Orgref.Split('.').Count }
            }, @{
                Expression = {$_.ParentOrgId}
                Ascending = $false
            }, @{
                Expression = {$_.OrgRef}
                Ascending = $false
            }) {

        [hashtable]$DestinationParams = @{VSAConnection = $DestinationVSA}

        [string]$Info = "Processing Organization: '$($Organization.OrgRef)'"
        #region message
        Write-Host $Info -ForegroundColor Cyan
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { Write-Debug $Info }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { Write-Verbose $Info }
        #endregion message
        [string] $ParentOrgId = [string]::Empty

        # Check if the Parent Organization already exists in the destination.
        if (-not [string]::IsNullOrEmpty($Organization.ParentOrgId)) {

            # Obtain ParentOrgId by orgref
            $ParentRef = $SourceOrgs | Where-Object { $_.OrgId -eq $Organization.ParentOrgId } | Select-Object -ExpandProperty OrgRef

            if ([string]::IsNullOrEmpty($ParentRef)) {
                #region message
                if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                    Write-Debug "Parent Organization for '$($Organization.OrgRef)' not found in the source. Skip now"
                }
                if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                    Write-Verbose "Parent Organization for '$($Organization.OrgRef)' not found in the source. Skip now"
                }
                #endregion message
                continue

            } else {
                $ParentOrgId = $global:DestinationOrgs | Where-Object { $_.OrgRef -eq $ParentRef } | Select-Object -ExpandProperty OrgId
                #region message
                if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                    Write-Debug "Parent Organization for '$($Organization.OrgRef)' : '$ParentRef'. Destination ParentOrgId: '$ParentOrgId'. Will try to create"
                }
                if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                    Write-Verbose "Parent Organization for '$($Organization.OrgRef)' : '$ParentRef'. Destination ParentOrgId: '$ParentOrgId'. Will try to create"
                }
                #endregion message
                $Organization.ParentOrgId = $ParentOrgId 
            }
        }

        [array]$CheckDestination = $global:DestinationOrgs | Where-Object { $_.OrgRef -eq $Organization.OrgRef }

        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug   "Look up the Destination for <$($Organization.OrgRef)>: found [$($CheckDestination.Count)]"
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            Write-Verbose "Look up the Destination for <$($Organization.OrgRef)>: found [$($CheckDestination.Count)]"
        }

        if (0 -eq $CheckDestination.Count) {
            # The Organization does not exist in the Destination. Create

            [string]$OrgRef = ($Organization.OrgRef.split('.'))[-1]
            $Organization.OrgRef = $OrgRef

            $NewOrgParams = $DestinationParams.Clone()
            $NewOrgParams.Add('ExtendedOutput',  $true)

            #region message
            $Info = "Organization with OrgRef '$($Organization.OrgRef)' was not found in the destination. Attempting to create it."
            Write-Host $Info -ForegroundColor Cyan
            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { Write-Debug $Info }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { Write-Verbose $Info }

            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                "Organization will be created with the following data:`n'$($Organization | ConvertTo-Json -Depth 3 | Out-String)'" | Write-Debug
            }
            #endregion message
            $NewOrgId = try {
                $Organization | New-VSAOrganization @NewOrgParams
            } catch {
                $_.Exception.Message
            }

            if ($NewOrgId -match "^\d+$") {
                #region message
                $Info = "Successfully created organization '$($Organization.OrgRef)' with ID '$NewOrgId'."
                Write-Host $Info -ForegroundColor Green
                if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { Write-Debug $Info }
                if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { Write-Verbose $Info }
                #endregion message
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

        $global:DestinationOrgs = Get-VSAOrganization @DestinationParams

        [array]$DirectChildren = $SourceOrgs | Where-Object { $_.ParentOrgId -eq $Organization.OrgId }

        if (0 -lt $DirectChildren.Count) {

            $CreateOrgParams = [ordered]@{
                SourceVSA      = $SourceVSA
                DestinationVSA = $DestinationVSA
                OrgsToTransfer = $DirectChildren
            }

            #region message
            $Info = "--- Processing Direct children of <$($Organization.OrgRef)> ---`n[$($DirectChildren.Count)] Direct children of '$($Organization.OrgRef)' to be created:`n[$($DirectChildren.OrgRef -join '; ')]`n==============="
            Write-Host $Info
            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { 
                $Info += "`nRecursive call of Copy-VSAOrgStructure with parameters:`n$($CreateOrgParams | Out-String)"
                Write-Debug $Info
            }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                $Info += "`nRecursive call of Copy-VSAOrgStructure with parameters:`n$($CreateOrgParams | Out-String)"
                Write-Verbose $Info
            }
            #endregion message

            Copy-VSAOrgStructure @CreateOrgParams
        }
    } # Foreach
}

Export-ModuleMember -Function Copy-VSAOrgStructure