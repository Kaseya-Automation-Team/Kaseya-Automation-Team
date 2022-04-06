function Copy-VSAMachineGroupStructure {
    <#
    .Synopsis
       Creates machine group structure.
    .DESCRIPTION
       Creates machine group structure in an organization based on given array of Machine groups.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER SourceMGs
        Specifies cource array of Machine groups
    .PARAMETER OrgId
        Specifies numeric id of organization
    .PARAMETER ParentMachineGroupId
        Optional parameter, specifies numeric id of parent machine group
    .EXAMPLE
        Copy-VSAMachineGroupStructure -SourceMGs $SourceMGs -OrgId $DestinationOrgId
    .EXAMPLE
        Copy-VSAMachineGroupStructure -SourceMGs $SourceMGs -OrgId $DestinationOrgId -VSAConnection $connection
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
        [array] $SourceMGs,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $OrgId,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $ParentMachineGroupId
    )
    $SourceMGs = $SourceMGs | Where-Object { -not [string]::IsNullOrEmpty($_.MachineGroupId) }

    [hashtable]$CommonParams = @{ 'OrganizationId' = $OrgId }        
    if($VSAConnection) {$CommonParams.Add('VSAConnection', $VSAConnection)}
    $OrgRef = $(Get-VSAOrganization @CommonParams | Select-Object -ExpandProperty OrgRef) -replace '\.', '\.'

    Foreach ($MachineGroup in $($SourceMGs | Sort-Object -Property MachineGroupName, ParentMachineGroupId) )
    {
        [hashtable]$CommonParams = @{ 'OrgId' = $OrgId }        
        if($VSAConnection) {$CommonParams.Add('VSAConnection', $VSAConnection)}

        $DestinationMGs = Get-VSAMachineGroup @CommonParams
        #$SplitName = ($MachineGroup.MachineGroupName | Select-String -Pattern "(?:\.root).*$").Matches.Value
        $SplitName = ($MachineGroup.MachineGroupName | Select-String -Pattern "(?<=$OrgRef).*$").Matches.Value

        [array]$CheckDestination = $DestinationMGs | Where-Object {$_.MachineGroupName -match "$SplitName`$"}

        $Info = "CheckDestination <$SplitName>  $($CheckDestination.Count)"
        $Info | Write-Debug
        $Info | Write-Verbose

        $NameToCreate = ($SplitName.split('.'))[-1]
    
        if( 0 -eq $CheckDestination.Count) #No MG with this name in the destination
        {
            $AddMGParams = $CommonParams.Clone()

            $AddMGParams.Add('ExtendedOutput',       $true)
            $AddMGParams.Add('MachineGroupName',     $NameToCreate)
            $AddMGParams.Add('ParentMachineGroupId', $ParentMachineGroupId)

            $AddMGParams | Out-String | Write-Debug
            #Create a new MG
            $GroupId = Add-VSAMachineGroup @AddMGParams
        }
        else # An MG with this name already exists in the destination
        { 
            $GroupId  = $CheckDestination.MachineGroupId
        }

        $Info = "GroupId: $GroupId"
        $Info | Write-Debug
        $Info | Write-Verbose

        [array]$DirectChildren = $SourceMGs | Where-Object {$_.ParentMachineGroupId -eq $MachineGroup.MachineGroupId }

        $Info = "DirectChildren for <$NameToCreate> $($DirectChildren.Count)"
        $Info | Write-Debug
        $Info | Write-Verbose
        $DirectChildren | Select-Object -ExpandProperty MachineGroupName | Out-String | Write-Debug

        if ( 0 -lt $DirectChildren.Count)
        {

            [hashtable]$CreateMGParams = $CommonParams.Clone()

            $CreateMGParams.Add('SourceMGs',            $DirectChildren)
            $CreateMGParams.Add('ParentMachineGroupId', $GroupId)

            $CreateMGParams | Out-String | Write-Debug

            Copy-VSAMachineGroupStructure @CreateMGParams
        }

    } # Foreach ($MachineGroup in $SourceMGs)
}
Export-ModuleMember -Function Copy-VSAMachineGroupStructure