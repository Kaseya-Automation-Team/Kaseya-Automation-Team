function Copy-VSADepartmentStructure {
    <#
    .Synopsis
       Creates departments structure.
    .DESCRIPTION
       Creates departments structure in an organization based on given array of departments.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER SourceDepartments
        Specifies cource array of Departments
    .PARAMETER OrgId
        Specifies numeric id of organization
    .PARAMETER ParentDepartmentId
        Optional parameter, specifies numeric id of parent Department
    .EXAMPLE
        Create-MachineGroup -SourceDepartments $SourceDepartments -OrgId $DestinationOrgId
    .EXAMPLE
        Create-MachineGroup -SourceDepartments $SourceDepartments -OrgId $DestinationOrgId -VSAConnection $connection
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
        [array] $SourceDepartments,

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
        [string] $ParentDepartmentId,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string[]] $RootDepartmetRefs
    )

    $SourceDepartments = $SourceDepartments | Where-Object { -not [string]::IsNullOrEmpty($_.DepartmentId) } #Filter out $null objects
    
    #For DirectChildren $RootDepartmetRefs is $null
    if (0 -eq $RootDepartmetRefs.count) {
        $RootDepartmetRefs = $SourceDepartments | Where-Object { [string]::IsNullOrEmpty($_.ParentDepartmentId) } | Select-Object -ExpandProperty DepartmentRef
    }    

    Foreach ($RootRef in $RootDepartmetRefs)
    {
        #Get parent departments
        [string] $Root = ($RootRef.split('.'))[-1]
        [string] $Pattern = "(?:\.$Root).*$"

        #for each of the parent departments create own structure
        Foreach ($Department in $( $SourceDepartments | Where-Object { $_.DepartmentRef -match $Root } | Sort-Object -Property ParentDepartmentId, DepartmentRef ) )
        {
            [hashtable]$CommonParams = @{ 'OrgId' = $OrgId }        
            if($VSAConnection) {$CommonParams.Add('VSAConnection', $VSAConnection)}

            $SplitRef = ($Department.DepartmentRef | Select-String -Pattern $Pattern).Matches.Value
            $DestinationDepartments = Get-VSADepartment @CommonParams
            
            [array]$CheckDestination = $DestinationDepartments | Where-Object {$_.DepartmentRef -match "$SplitRef`$"}

            $Info = "CheckDestination <$SplitRef>  $($CheckDestination.Count)"
            $Info | Write-Debug
            $Info | Write-Verbose

            $DepartmentRefToCreate = "$($RootRef.Split('.')[0])$SplitRef"
    
            if( 0 -eq $CheckDestination.Count) #No MG with this name in the destination
            {
                $AddDepartmentParams = $CommonParams.Clone()

                $AddDepartmentParams.Add('ExtendedOutput',     $true)
                $AddDepartmentParams.Add('DepartmentName',     $Department.DepartmentName)
                $AddDepartmentParams.Add('DepartmentRef',      $DepartmentRefToCreate)
                $AddDepartmentParams.Add('ParentDepartmentId', $ParentDepartmentId)

                $AddDepartmentParams | Out-String | Write-Debug
                #Create a new Department
                $DepartmentId = Add-VSADepartment @AddDepartmentParams
            }
            else # An MG with this name already exists in the destination
            { 
                $DepartmentId  = $CheckDestination.DepartmentId
            }

            $Info = "DepartmentId: $DepartmentId"
            $Info | Write-Debug
            $Info | Write-Verbose

            $Info | Write-Host

            [array]$DirectChildren = $SourceDepartments | Where-Object {$_.ParentDepartmentId -eq $Department.DepartmentId }

            $Info = "DirectChildren for <$DepartmentRefToCreate> $($DirectChildren.Count)"
            $Info | Write-Debug
            $Info | Write-Verbose

            $Info | Write-Host
            $DirectChildren | Select-Object -ExpandProperty DepartmentName | Out-String | Write-Debug

            $DirectChildren | Write-Host

            if ( 0 -lt $DirectChildren.Count)
            {

                [hashtable]$CreateDepartmentParams = $CommonParams.Clone()

                $CreateDepartmentParams.Add('SourceDepartments',  $DirectChildren)
                $CreateDepartmentParams.Add('ParentDepartmentId', $DepartmentId)
                $CreateDepartmentParams.Add('RootDepartmetRefs',  $RootRef)

                $CreateDepartmentParams | Out-String | Write-Debug

                Copy-VSADepartmentStructure @CreateDepartmentParams
            }

        } # Foreach ($Department in $SourceDepartments)

    } #Foreach ($RootRef in $RootDepartmetRefs)
     
    
}
Export-ModuleMember -Function Copy-VSADepartmentStructure