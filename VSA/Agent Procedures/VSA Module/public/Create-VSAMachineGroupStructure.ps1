function Create-VSAMachineGroupStructure {
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
     
    Foreach ($MachineGroup in $($SourceMGs | Sort-Object -Property MachineGroupName, ParentMachineGroupId) )
    {
        [hashtable]$CommonParams = @{ 'OrgId' = $OrgId }        
        if($VSAConnection) {$CommonParams.Add('VSAConnection', $VSAConnection)}

        $DestinationMGs = Get-VSAMachineGroup @CommonParams
        $SplitName = ($MachineGroup.MachineGroupName | Select-String -Pattern "(?:\.root).*$").Matches.Value

        [array]$CheckDestination = $DestinationMGs | Where-Object {$_.MachineGroupName -match "$SplitName`$"}

        $Info = "CheckDestination <$SplitName>  $($CheckDestination.Count)"
        $Info | Write-Debug
        $Info | Write-Verbose

        $NameToCreate = ($SplitName.split('.'))[-1]
    
        if( 0 -eq $CheckDestination.Count) #No such MG in the destination
        {
            $AddMGParams = $CommonParams.Clone()
            $AddMGParams.Add('ExtendedOutput',       $true)
            $AddMGParams.Add('MachineGroupName',     $NameToCreate)
            $AddMGParams.Add('ParentMachineGroupId', $ParentMachineGroupId)

            $AddMGParams | Out-String | Write-Debug
            $GroupId = Add-VSAMachineGroup @AddMGParams

        }
        else # The MG already exists in the destination
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
            $CreateMGParams.Add('SourceMGs', $DirectChildren)
            $CreateMGParams.Add('ParentMachineGroupId', $GroupId)
            $CreateMGParams | Out-String | Write-Debug
            Create-MachineGroup @CreateMGParams
        }

    } # Foreach ($MachineGroup in $SourceMGs)
}
Export-ModuleMember -Function Create-VSAMachineGroupStructure