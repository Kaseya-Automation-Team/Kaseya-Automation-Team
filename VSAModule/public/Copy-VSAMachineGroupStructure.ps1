function Copy-VSAMachineGroupStructure {
    <#
    .Synopsis
       Creates machine group structure.
    .DESCRIPTION
       Creates machine group structure in an organization based on given array of Machine groups.
       Takes either persistent or non-persistent connection information.
    .PARAMETER SourceVSA
        Specifies existing non-persistent connection to the Source Environment.
    .PARAMETER DestinationVSA
        Specifies existing non-persistent connection to the Destination Environment.
    .PARAMETER SourceMGs
        Specifies cource array of Machine groups
    .PARAMETER OrgRef
        Specifies Reference (ID) of organization
    .EXAMPLE
        Copy-VSAMachineGroupStructure -SourceMGs $SourceMGs -OrgRef $OrgRef -SourceVSA $SourceVSA -DestinationVSA $DestinationVSA
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

    [hashtable]$SourceParams = @{}
    if($SourceVSA) {$SourceParams.Add('VSAConnection', $SourceVSA) }
    $SourceOrg = Get-VSAOrganization @SourceParams | Where-Object {$_.OrgRef -eq $OrgRef}
    if ( $null -eq $SourceOrg) {
        throw "Organization $OrgRef not found in the Source VSA"
    }
    $SourceOrgId = $SourceOrg | Select-Object -ExpandProperty OrgId
    $SourceParams.Add('OrgID', $SourceOrgId)

    [array]$global:ExistingSourceMGs = Get-VSAMachineGroup @SourceParams | Where-Object { -not [string]::IsNullOrEmpty($_.MachineGroupId) }
    $Info = "Source: [$($global:ExistingSourceMGs | Select-Object -ExpandProperty MachineGroupName | Out-String )]"
    $Info | Write-Host -ForegroundColor Cyan
    $Info | Write-Debug
    $Info | Write-Verbose

    [hashtable]$DestinationParams = @{ 'VSAConnection' = $DestinationVSA }
    $DestinationOrg = Get-VSAOrganization @DestinationParams | Where-Object {$_.OrgRef -eq $OrgRef}
    if ( $null -eq $SourceOrg) {
        throw "Organization $OrgRef not found in the Destination VSA"
    }
    $DestinationOrgId = $DestinationOrg | Select-Object -ExpandProperty OrgId
    $DestinationParams.Add('OrgID', $DestinationOrgId)

    [array]$global:DestinationMGs = @()
    $global:DestinationMGs += Get-VSAMachineGroup @DestinationParams

    Foreach ($MachineGroup in $($SourceMGs | Sort-Object -Property @{Expression = { $_.MachineGroupName.Split('.').Count }}, @{Expression = {$_.ParentMachineGroupId}; Ascending = $false} , @{Expression = {$_.MachineGroupName}; Ascending = $false}) )
    {
        [hashtable]$DestinationParams = @{ VSAConnection =$DestinationVSA
                                           OrgID = $DestinationOrgId
                                         }

        
        #$SplitName = ($MachineGroup.MachineGroupName | Select-String -Pattern "(?:\.root).*$").Matches.Value
        #$SplitName = ($MachineGroup.MachineGroupName | Select-String -Pattern "(?<=$OrgRef).*$").Matches.Value
        $global:DestinationMGs = Get-VSAMachineGroup @DestinationParams
        [array]$CheckDestination = $global:DestinationMGs | Where-Object { $_.MachineGroupName -eq $MachineGroup.MachineGroupName }

        $Info = "CheckDestination <$($MachineGroup.MachineGroupName)>  $($CheckDestination.Count)"
        $Info | Write-Host
        $Info | Write-Debug
        $Info | Write-Verbose

        $NewMGObj = $MachineGroup
        
        #region Check if there's Parent Machine Group and the Parent Machine Group already exists in the destination.
        if( -not [string]::IsNullOrEmpty( $MachineGroup.ParentMachineGroupId ) ) {
            $Info = "Look for parent of <$($MachineGroup.MachineGroupName)> in [$($global:ExistingSourceMGs | Select-Object -ExpandProperty MachineGroupName | Out-String )]"
            $Info | Write-Host -ForegroundColor Yellow
            $Info | Write-Verbose
            $Info | Write-Debug
            #obtain ParentMachineGroupId by MachineGroupName
            $ParentMachineGroupName = $global:ExistingSourceMGs | Where-Object { $_.MachineGroupId -eq $MachineGroup.ParentMachineGroupId } | Select-Object -ExpandProperty MachineGroupName
            if ( [string]::IsNullOrEmpty($ParentMachineGroupName) ) {
                $Info = "Parent Organazation for <$($MachineGroup.MachineGroupName)> not found in the source. Skip now"
                $Info | Write-Host -ForegroundColor DarkRed -BackgroundColor White
                $Info | Write-Verbose
                $Info | Write-Debug
                continue
            } else {
                $ParentMachineGroupId = $global:DestinationMGs | Where-Object { $_.MachineGroupName -eq $ParentMachineGroupName } | Select-Object -ExpandProperty MachineGroupId

                $Info = "Parent Organazation for <$($MachineGroup.MachineGroupName)> : <$ParentMachineGroupName>. Destination ParentMachineGroupId <$ParentMachineGroupId>. Can be created"
                $Info | Write-Host -ForegroundColor DarkGreen -BackgroundColor White
                $Info | Write-Verbose
                $Info | Write-Debug

                $NewMGObj.ParentMachineGroupId = $ParentMachineGroupId 
            }
        }
        #endregion Check if there's Parent Machine Group and the Parent Machine Group already exists in the destination.
    
        if( 0 -eq $CheckDestination.Count) #No MG with this name in the destination
        {
            $AddMGParams = $DestinationParams.Clone()
            $AddMGParams.Add('ExtendedOutput', $true)

            #New MG Params
            $NameToCreate = ($($MachineGroup.MachineGroupName).split('.'))[-1]
            $NewMGObj.MachineGroupName = $NameToCreate

            

            $GroupId = $NewMGObj | Add-VSAMachineGroup @AddMGParams
            $global:DestinationMGs = Get-VSAMachineGroup @DestinationParams
        } else  { # A MG with this name already exists in the destination
            $GroupId  = $CheckDestination.MachineGroupId
        }

        $Info = "GroupId: $GroupId"
        $Info | Write-Host
        $Info | Write-Debug
        $Info | Write-Verbose

        [array]$DirectChildren = $global:ExistingSourceMGs | Where-Object {$_.ParentMachineGroupId -eq $MachineGroup.MachineGroupId }

        $Info = "Count Direct Children <$($MachineGroup.MachineGroupName)> $($DirectChildren.Count)"
        $Info | Write-Host
        $Info | Write-Debug
        $Info | Write-Verbose
        $DirectChildren | Select-Object -ExpandProperty MachineGroupName | Out-String | Write-Debug

        if ( 0 -lt $DirectChildren.Count)
        {
            $Info = "Direct children of <$($MachineGroup.MachineGroupName)> : [$(($DirectChildren | Select-Object -ExpandProperty MachineGroupName) -join '; ')]"
            $Info | Write-Host
            $Info | Write-Debug
            $Info | Write-Verbose

            [hashtable]$CreateMGParams = @{ OrgRef = $OrgRef
                                            SourceVSA = $SourceVSA
                                            DestinationVSA = $DestinationVSA
                                            SourceMGs = $DirectChildren
                                            }

            $CreateMGParams | Out-String | Write-Debug

            Copy-VSAMachineGroupStructure @CreateMGParams
        }

    } # Foreach ($MachineGroup in $SourceMGs)
}
Export-ModuleMember  -Function Copy-VSAMachineGroupStructure