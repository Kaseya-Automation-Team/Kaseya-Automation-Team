function Update-VSAAgentCheckinCtl
{
    <#
    .Synopsis
       Updates checkin control settings for an agent.
    .DESCRIPTION
       Updates checkin control settings for an agent.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies numeric id of agent machine
    .PARAMETER PrimaryKServer
        Specifies ip address or hostname of primary VSA server
    .PARAMETER PrimaryKServerPort
        Specifies tcp port of VSA server
    .PARAMETER SecondaryKServer
        Specifies ip address or hostname of secondary VSA server
    .PARAMETER SecondaryKServerPort
        Specifies tcp port of secondary VSA server
    .PARAMETER QuickCheckInTimeInSeconds
        Specifies period of checkin in seconds
    .PARAMETER BandwidthThrottle
        Specifies bandwidth throttle of agent
    .EXAMPLE
       Update-VSAAgentCheckinCtl -AgentId 323232323 -PrimaryKServer "192.168.100.1" -PrimaryKServerPort "5721" -QuickCheckInTimeInSeconds 30
    .EXAMPLE
       Update-VSAAgentCheckinCtl -VSAConnection $VSAConnection -AgentId 323232323 -PrimaryKServer "192.168.100.1" -PrimaryKServerPort "5721" -SecondaryKServer "192.168.100.2" -SecondaryKServerPort "5720" -QuickCheckInTimeInSeconds 30
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NonPersistent')]
        [VSAConnection] $VSAConnection,
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/assetmgmt/agent/{0}/settings/checkincontrol",
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $PrimaryKServer,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $PrimaryKServerPort,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $SecondaryKServer,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $SecondaryKServerPort,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $QuickCheckInTimeInSeconds,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $BandwidthThrottle
)
    $URISuffix = $URISuffix -f $AgentId
	
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
    }

    $BodyHT = @{"PrimaryKServer"="$PrimaryKServer"; "PrimaryKServerPort"="$PrimaryKServerPort"; "QuickCheckInTimeInSeconds"="$QuickCheckInTimeInSeconds";}

    if ( -not [string]::IsNullOrEmpty($BandwidthThrottle) )                 { $BodyHT.Add('BandwidthThrottle', $BandwidthThrottle) }
    
    if ( [string]::IsNullOrEmpty($SecondaryKServer) ) {
        $BodyHT.Add('SecondaryKServer', $PrimaryKServer)
    } else {
        $BodyHT.Add('SecondaryKServer', $SecondaryKServer)
    }

    if ( [string]::IsNullOrEmpty($SecondaryKServerPort) ) {
        $BodyHT.Add('SecondaryKServerPort', $PrimaryKServerPort)
    } else {
        $BodyHT.Add('SecondaryKServerPort', $SecondaryKServerPort)
    }

    $Body = $BodyHT | ConvertTo-Json
    	
    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Update-VSAAgentCheckinCtl