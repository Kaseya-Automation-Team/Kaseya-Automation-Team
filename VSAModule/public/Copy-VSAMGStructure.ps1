function Copy-VSAMGStructure {
    <#
    .Synopsis
       Creates machine group structure.
    .DESCRIPTION
       Creates machine group structure in an organization based on given array of Machine groups.
    .PARAMETER SourceVSA
        Specifies established VSAConnection to the Source environment.
    .PARAMETER DestinationVSA
        Specifies established VSAConnection to the Destination environment.
    .PARAMETER SourceMGs
        Specifies cource array of Machine groups
    .PARAMETER OrgRef
        Specifies Unique Reference (OrgRef) of organization
    .EXAMPLE
        Copy-VSAMGStructure -SourceMGs $SourceMGs -OrgRef $OrgRef -SourceVSA $SourceVSA -DestinationVSA $DestinationVSA
    .INPUTS
       Accepts piped parameters 
    .OUTPUTS
       No output
    #>
    [alias("Copy-VSAMachineGroupStructure")]
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
        [array] $SourceMGs,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( [string]::IsNullOrEmpty($_) ) {
                throw "Empty value"
            }
            return $true
        })]
        [string] $OrgRef
    )

    [hashtable]$SourceParams = @{
        VSAConnection = $SourceVSA
        Filter = "OrgRef eq '$OrgRef'"
    }

    $SourceOrg = Get-VSAOrganization @SourceParams
    if ( $null -eq $SourceOrg) {
        throw "Organization $OrgRef not found in the Source VSA"
    } else {
        $SourceParams.Add('OrgId', $SourceOrg.OrgId)
        $SourceParams.Remove('Filter')
    }

    [array]$global:ExistingSourceMGs = Get-VSAMachineGroup @SourceParams | Where-Object { -not [string]::IsNullOrEmpty($_.MachineGroupId) }

    #region message
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "Source Machine Groups:`n>$($global:ExistingSourceMGs.MachineGroupName -join "`n>" )" | Write-Debug
    }
    #endregion message

    [hashtable]$DestinationParams = @{
        VSAConnection = $DestinationVSA
        Filter = "OrgRef eq '$OrgRef'"
    }

    $DestinationOrg = Get-VSAOrganization @DestinationParams
    if ( $null -eq $DestinationOrg ) {
        throw "Organization '$OrgRef' not found in the Destination VSA"
    } else {
        $DestinationParams.Add('OrgId', $DestinationOrg.OrgId)
        $DestinationParams.Remove('Filter')
    }

    [array]$global:DestinationMGs = Get-VSAMachineGroup @DestinationParams

    Foreach ($MachineGroup in $($SourceMGs | Sort-Object -Property @{Expression = { $_.MachineGroupName.Split('.').Count }}, @{Expression = {$_.ParentMachineGroupId}; Ascending = $false} , @{Expression = {$_.MachineGroupName}; Ascending = $false}) )
    {
        [hashtable]$DestinationParams = @{
            VSAConnection = $DestinationVSA
            OrgID         = $DestinationOrg.OrgId
        }
        
        #$SplitName = ($MachineGroup.MachineGroupName | Select-String -Pattern "(?:\.root).*$").Matches.Value
        #$SplitName = ($MachineGroup.MachineGroupName | Select-String -Pattern "(?<=$OrgRef).*$").Matches.Value
        $global:DestinationMGs = Get-VSAMachineGroup @DestinationParams
        [array]$CheckDestination = $global:DestinationMGs | Where-Object { $_.MachineGroupName -eq $MachineGroup.MachineGroupName }

        #region message
        $Info = "Look up Destination for Machine Group '$($MachineGroup.MachineGroupName)'. Found: [$($CheckDestination.Count)] object(s)."
        Write-Host $Info
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { Write-Debug $Info }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { Write-Verbose $Info }
        #endregion message

        $NewMGObj = $MachineGroup
        
        #region Check if there's Parent Machine Group and the Parent Machine Group already exists in the destination.
        if( -not [string]::IsNullOrEmpty( $MachineGroup.ParentMachineGroupId ) ) {
            #region message
            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                Write-Debug "Looking for parent of the Machine Group of '$($MachineGroup.MachineGroupName)' in [$($global:ExistingSourceMGs.MachineGroupName -join '; ')]"
            }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                Write-Verbose "Looking for parent of the Machine Group of '$($MachineGroup.MachineGroupName)'"
            }
            #endregion message
            #obtain ParentMachineGroupId by MachineGroupName
            $ParentMachineGroupName = $global:ExistingSourceMGs | Where-Object { $_.MachineGroupId -eq $MachineGroup.ParentMachineGroupId } | Select-Object -ExpandProperty MachineGroupName
            if ( [string]::IsNullOrEmpty($ParentMachineGroupName) ) {
                #region message
                if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                    Write-Debug "Parent Machine Group for '$($MachineGroup.MachineGroupName)' not found in the source. Skip"
                }
                if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                    Write-Verbose "Parent Machine Group for '$($MachineGroup.MachineGroupName)' not found in the source. Skip"
                }
                #endregion message
                continue
            } else {
                $ParentMachineGroupId = $global:DestinationMGs | Where-Object { $_.MachineGroupName -eq $ParentMachineGroupName } | Select-Object -ExpandProperty MachineGroupId

                #region message
                if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                    Write-Debug "Parent Machine Group for '$($MachineGroup.MachineGroupName)' is '$ParentMachineGroupName'. Destination ParentMachineGroupId is: '$ParentMachineGroupId'."
                }
                if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                    Write-Verbose "Parent Machine Group for '$($MachineGroup.MachineGroupName)' is '$ParentMachineGroupName'. Destination ParentMachineGroupId is: '$ParentMachineGroupId'."
                }
                #endregion message

                $NewMGObj.ParentMachineGroupId = $ParentMachineGroupId 
            }
        }
        #endregion Check if there's Parent Machine Group and the Parent Machine Group already exists in the destination.
    
        if( 0 -eq $CheckDestination.Count) #No MG with this name in the destination
        {
            $NewMGParams = $DestinationParams.Clone()
            $NewMGParams.Add('ExtendedOutput', $true)

            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { $NewMGParams.Add('Debug', $true) }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { $NewMGParams.Add('Verbose', $true) }

            #New MG Params
            $NameToCreate = ($($MachineGroup.MachineGroupName).split('.'))[-1]
            $NewMGObj.MachineGroupName = $NameToCreate

            #region message
            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                Write-Debug "Machine Group '$($MachineGroup.MachineGroupName)' not found in the destination. Attempting to create it."
            }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                Write-Verbose "Machine Group '$($MachineGroup.MachineGroupName)' not found in the destination. Attempting to create it."
            }
            #endregion message

            $GroupId = $NewMGObj | New-VSAMachineGroup @NewMGParams
            $global:DestinationMGs = Get-VSAMachineGroup @DestinationParams
        } else  { # A MG with this name already exists in the destination
            $GroupId  = $CheckDestination.MachineGroupId
        }
        #region message
        $Info = "GroupId of the destination Machine Group '$($MachineGroup.MachineGroupName)' is: '$GroupId'"
        $Info | Write-Host
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { Write-Debug $Info }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { Write-Verbose $Info }
        #endregion message

        [array]$DirectChildren = $global:ExistingSourceMGs | Where-Object {$_.ParentMachineGroupId -eq $MachineGroup.MachineGroupId }

        #region message
        $Info = "Amount of Direct Children of Machine Group '$($MachineGroup.MachineGroupName)' is [$($DirectChildren.Count)]"
        $Info | Write-Host
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { Write-Verbose $Info }
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug $Info
            $DirectChildren | Select-Object -ExpandProperty MachineGroupName | Out-String | Write-Debug
        }
        #endregion message

        if ( 0 -lt $DirectChildren.Count)
        {
            #region message
            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                Write-Debug "Direct children of <$($MachineGroup.MachineGroupName)> : [$(($DirectChildren | Select-Object -ExpandProperty MachineGroupName) -join '; ')]"
            }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                Write-Verbose "Direct children of <$($MachineGroup.MachineGroupName)> : [$(($DirectChildren | Select-Object -ExpandProperty MachineGroupName) -join '; ')]"
            }
            #endregion message

            [hashtable]$CreateMGParams = @{
                OrgRef = $OrgRef
                SourceVSA = $SourceVSA
                DestinationVSA = $DestinationVSA
                SourceMGs = $DirectChildren
            }

            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { $CreateMGParams.Add('Debug', $true) }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { $CreateMGParams.Add('Verbose', $true) }

            #region message
            $Info = "--- Processing Direct children of the '$($MachineGroup.MachineGroupName)' Machine Group ---`n[$($DirectChildren.Count)] Direct children of '$($MachineGroup.MachineGroupName)' to be created:`n[$($DirectChildren.MachineGroupName -join '; ')]`n==============="
            Write-Host $Info
            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { 
                $Info += "`nRecursive call of Copy-VSAMGStructure with parameters:`n'$($CreateMGParams | Out-String)'"
                Write-Debug $Info
            }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                $Info += "`nRecursive call of Copy-VSAMGStructure"
                Write-Verbose $Info
            }
            #endregion message

            Copy-VSAMachineGroupStructure @CreateMGParams
        }

    } # Foreach ($MachineGroup in $SourceMGs)
}
Export-ModuleMember -Function Copy-VSAMGStructure