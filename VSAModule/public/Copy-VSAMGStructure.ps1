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

    if ( $SourceVSA -eq $DestinationVSA ) {
        throw "The Source and the Destionation is the same VSA Environment!"
    }

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

    Foreach ($MachineGroup in $SourceMGs | Sort-Object -Property @{
                    Expression = { $_.MachineGroupName.Split('.').Count }
                    }, @{
                    Expression = {$_.MachineGroupName}; Ascending = $false} ) {

        [hashtable]$DestinationParams = @{
            VSAConnection = $DestinationVSA
            OrgID         = $DestinationOrg.OrgId
        }
        
        #region Define the current Machine Group's own MachineGroupName and the parent Machine Group's MachineGroupName (if exists)
        #$SplitName = ($MachineGroup.MachineGroupName | Select-String -Pattern "(?<=$OrgRef\.).*$").Matches.Value

        [string] $MGName = $MachineGroup.MachineGroupName
        [string[]] $MGNameAsArray =  $MGName.split('.')
        [string] $OwnMGName = $MGNameAsArray[-1]
        $ParentMGName = [string]::Empty
        if ($MGNameAsArray.Count -gt 2) {
            [int] $strLength =  $MGName.LastIndexOf('.')
            if (0 -lt $strLength ) {
                [string] $ParentMGName =  $MGName.Substring( 0, $strLength )
            }
        }

        $MachineGroup.MachineGroupName = $OwnMGName
        #endregion Define the current Machine Group's own MachineGroupName and the parent Machine Group's MachineGroupName (if exists)

        # Check if the Parent Organization already exists in the destination.
        if ( -not [string]::IsNullOrEmpty($ParentMGName) ) {

            $DestinationParentMGId =  Get-VSAMachineGroup @DestinationParams -Filter "MachineGroupName eq '$ParentMGName'" | Select-Object -ExpandProperty MachineGroupId

            #region message
            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                Write-Debug "Parent Machine Group for '$MGName' : '$ParentMGName'. Destination ParentMachineGroupId: '$DestinationParentMGId'."
            }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                Write-Debug "Parent Machine Group for '$MGName' : '$ParentMGName'. Destination ParentMachineGroupId: '$DestinationParentMGId'."
            }
            #endregion message
            
            #Replace source's ParentMachineGroupId with the destination's counterpart
            $MachineGroup.ParentMachineGroupId = $DestinationParentMGId
        }

        $CheckDestination = Get-VSAMachineGroup @DestinationParams -Filter "MachineGroupName eq '$MGName'"
    
        if( $null -eq $CheckDestination ) #No MG with this name in the destination
        {
            $NewMGParams = $DestinationParams.Clone()
            $NewMGParams.Add('ExtendedOutput', $true)

            if ($PSCmdlet.MyInvocation.BoundParameters['Debug'])   { $NewMGParams.Add('Debug', $true) }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { $NewMGParams.Add('Verbose', $true) }

            #region message
            if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                Write-Debug "Machine Group with name '$MGName' was not found in the destination. Will attempt to create it."
            }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
                Write-Debug "Machine Group with name '$MGName' was not found in the destination. Will attempt to create it."
            }
            #endregion message

            $NewGroupId = try {
                $MachineGroup | New-VSAMachineGroup @NewMGParams
            } catch {
                $_.Exception.Message
            }

            if ($NewGroupId -match "^\d+$") {
                #region message
                $Info = "Successfully created Machine Group '$MGName' with ID '$NewGroupId'."
                Write-Host $Info
                if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { Write-Verbose $Info }
                if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) { Write-Debug $Info }
                #endregion message

                #Make the REST API wait while the BackEnd updates the information
                $GetMGParams = $DestinationParams.Clone()
                $GetMGParams.Remove('OrgId')
                $GetMGParams.Add('MachineGroupId', $NewGroupId)
                $null = Get-VSAMachineGroup @GetMGParams

                #Make the REST API wait while the BackEnd updates the information
                [int]$WaitSec = 0
                [int]$StopWait = 60
                [string]$CheckNewMGId = try {Get-VSAMachineGroup @GetMGParams -ErrorAction Stop | Select-Object -ExpandProperty MachineGroupId } catch { $null }
                while ( [string]::IsNullOrEmpty($CheckNewMGId) ) {
                    $WaitSec++
                    Start-Sleep -Seconds 1
                    $CheckNewMGId = try {Get-VSAMachineGroup @GetMGParams -ErrorAction Stop | Select-Object -ExpandProperty MachineGroupId } catch { $null }
                    if ($WaitSec -ge $StopWait) { break}
                }

            } else {
                #region message
                $Info = "Something went wrong while creating '$MGName'. Returned ID: '$NewGroupId'"
                Write-Host $Info -ForegroundColor Red
                if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { Write-Verbose $Info }
                if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
                    Write-Debug $Info
                    Write-Debug "JSON data:`n$($MachineGroup | ConvertTo-Json -Depth 5 | Out-String)"
                }
                #endregion message
            } 
        }
        else {
            #$CheckDestination is not null
            continue
        }

    } # Foreach ($MachineGroup in $SourceMGs)
}

New-Alias -Name Copy-VSAMachineGroupStructure -Value Copy-VSAMGStructure
Export-ModuleMember -Function Copy-VSAMGStructure -Alias Copy-VSAMachineGroupStructure