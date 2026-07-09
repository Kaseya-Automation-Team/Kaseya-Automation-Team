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

    # Retrieve existing organizations already present in the destination
    [array] $DestinationOrgs = Get-VSAOrganization @DestinationParams

    #region message
            "Organizations to be created: [$($OrgsToTransfer.OrgRef -join '; ')]" | Write-Debug
        "Organizations already present in the destination: [$($DestinationOrgs.OrgRef -join '; ')]" | Write-Debug
    
            "Organizations to be created: [$($OrgsToTransfer.OrgRef -join '; ')]" | Write-Verbose
        "Organizations already present in the destination: [$($DestinationOrgs.OrgRef -join '; ')]" | Write-Verbose
    
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
         Write-Debug $Info 
         Write-Verbose $Info 
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

            $DestinationParentOrgId =  Get-VSAOrganization @DestinationParams -Filter "OrgRef eq '$(ConvertTo-ODataString $ParentOrgRef)'" | Select-Object -ExpandProperty OrgId

            #region message
                            Write-Debug "Parent Organization for '$($Organization.OrgRef)' : '$ParentOrgRef'. Destination ParentOrgId: '$DestinationParentOrgId'."
            
                            Write-Verbose "Parent Organization for '$($Organization.OrgRef)' : '$ParentOrgRef'. Destination ParentOrgId: '$DestinationParentOrgId'."
            
            #endregion message

            #Replace source's ParentOrgId with the destination's counterpart
            $Organization.ParentOrgId = $DestinationParentOrgId
        }

        #region message
                    Write-Debug   "Look up the Destination for '$($Organization.OrgRef)'"
        
                    Write-Verbose "Look up the Destination for '$($Organization.OrgRef)'"
        
        #endregion message

        $CheckDestination = Get-VSAOrganization @DestinationParams -Filter "OrgRef eq '$(ConvertTo-ODataString $OwnOrgRef)'"

        if ( $null -eq $CheckDestination ) {
            # The Organization does not exist in the Destination. Create

            $NewOrgParams = $DestinationParams.Clone()
            $NewOrgParams.Add('ExtendedOutput',  $true)

            if ($PSCmdlet.MyInvocation.BoundParameters['Debug'])   { $NewOrgParams.Add('Debug', $true) }
            if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) { $NewOrgParams.Add('Verbose', $true) }

            #region message
            $Info = "Organization with OrgRef '$($Organization.OrgRef)' was not found in the destination. Will attempt to create it."
             Write-Debug $Info 
             Write-Verbose $Info 

                            "Organization will be created with the following data:`n'$($Organization | ConvertTo-Json -Depth 3 | Out-String)'" | Write-Debug
            
            #endregion message

            $NewOrgId = try {
                $Organization | New-VSAOrganization @NewOrgParams
            } catch {
                Write-Information "Error creating organization '$($Organization.OrgRef)': $($_.Exception.Message)"
                $null  # Ensure $NewOrgId is null on failure
            }

            if ($null -ne $NewOrgId -and $NewOrgId -match "^\d+$") {
                #region message
                $Info = "Successfully created organization '$($Organization.OrgRef)' with ID '$NewOrgId'."
                Write-Verbose $Info
                Write-Debug $Info
                #endregion message

                #Make the REST API wait while the BackEnd updates the information
                [int]$WaitSec = 0
                [int]$StopWait = 60
                [string]$CheckNewOrgId = try {Get-VSAOrganization @DestinationParams -OrgId $NewOrgId -ErrorAction Stop | Select-Object -ExpandProperty OrgId } catch { $null }
                while ( [string]::IsNullOrEmpty($CheckNewOrgId) ) {
                    $WaitSec++
                    Start-Sleep -Seconds 1
                    $CheckNewOrgId = try {Get-VSAOrganization @DestinationParams -OrgId $NewOrgId -ErrorAction Stop | Select-Object -ExpandProperty OrgId } catch { $null }
                    if ($WaitSec -ge $StopWait) { break}
                }
            } else {
                #region message
                $Info = "Something went wrong while creating '$($Organization.OrgRef)'. Returned ID: '$NewOrgId'"
                Write-Information $Info
                Write-Debug $Info
                Write-Debug "JSON data:`n$($Organization | ConvertTo-Json -Depth 3 | Out-String)"
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