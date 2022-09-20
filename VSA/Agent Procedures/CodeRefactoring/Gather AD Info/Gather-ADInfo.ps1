<#
=================================================================================
Script Name:        Audit: Gather AD Info.
Description:        Gathers Active Directory Information and saves repot as an HTML-file.
Lastest version:    2022-07-28
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>

<#
.Synopsis
   Gathers Active Directory Information and saves repot as an HTML-file.
.DESCRIPTION
    Gathers Active Directory Information

    Forest Information
        - Forest Root Domain
        - Forest Functional Level
        - Domains in the forest
        - AD Recycle BIN status
        - FSMO Roles
            - Domain Naming Master
            - Schema Master
    Domain Information
        - NETBIOS name
        - Domain Functional Level
        - FSMO Roles
            - PDC Emulator
            - RID Master
            - Infrastructure Master
        - Number of
            - Users
            - Groups
            - Computers
    Active Directory Schema Information
        - AD Schema Version
        - Exchange Schema Version
        - Lync Schema Version
    Trust Information
        - Trusted Domain
        - Trusted DC Name
        - Trusts Status
        - Trusts Is OK
        - Trusts Type
        - Trusts Direction
        - Trusts Attributes
    Domain Controller Information
        - Domain
        - Computer Name
        - Global Catalog
        - Read Only
        - Operating System
        - Operating System Version
        - Site
        - IPv4 Address
        - IPv6 Address
    Domain Controller Hardware Information
        - Name
        - Manufacturer
        - Model
        - RAM
        - CPU
            - DeviceID
            - Caption
            - MaxClockSpeed
        - Drives
            - Drive
            - Size
            - Free
    AD Database Information
        - Database Path
        - Database Size
        - Sysvol Path
        - Sysvol Folder Size
    Domain Controller Software Information
        - Operating System
        - Operating System Version
        - Hot Fixes
        - Roles And Features
        - Software
    DNS Information
        - Primary Zones
        - NS Records
        - MX Records
        - Forwards
        - Scavenging Enabled
        - Aging Enabled
    Site Information
        - Site Names
        - Intersite Links
            - Name
            - Site Included
            - Site Cost
            - Site Replication Frequency
    Replication Information
        - Replication Partners
        - Last Replication
        - First Failure
        - Failure Count
        - Failure Type
    GPO Information
        - Domain Name
        - GPO Display Name
        - Creation Time
        - Modification Time
        - Linked To (OU)
    OU Structure Information
        - OU Distinguished Name
        - OU Description
    User Information
        - Enterprise Admin Group Members
        - Domain Admin Group Members
        - Schema Admin Group Members
        - Group Policy Creator Owners
        - Accounts with Passwords Never Expires
        - Accounts with No Passwords
        - Accounts with Kerberos Not Required
    Exchange Information
        - Organization Management Group Members
        - Exchange Server 
.PARAMETERS
    [string] AgentName
        - ID of the VSA agent
    [string] OutputFilePath
        - Output HTML file name
    [switch] LogIt
        - Enables execution transcript
		 
.NOTES
    Version 0.1
    Requires: 
        Proper permissions to execute the script in the forest
        Privilege Elevation is required
        Execute the script from a forest's root domain Domain Controller, or the preferred
        method, on a client with the RSAT installed
    Tested: Windows Server 2012 R2, Windows Server 2016, Windows 10, PowerShell v3-5
   
    Author: Proserv Team - VS

#>

$OutputFile = "$Env:Temp\GatheredADInfo.html"

#Create VSA Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

if (2 -ne $(Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty ProductType) ) {
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", " $env:COMPUTERNAME is not a Domain Controller", "Warning", 300)    
}

######################################
#region Functions
######################################

#region Get-TrustAttributes
Function Get-TrustAttributes
{
    [cmdletbinding()]
    Param(
    [parameter(Mandatory=$false,
    ValueFromPipeline=$True)]
    [int32]$Value
    )
    If ($value){
    $TrustValue = $value
    }
    [String[]]$TrustAttributes=@() 
    Foreach ( $key in $TrustValue )
    {
        if([int32]$key -band 0x00000001){$TrustAttributes += 'Non Transitive'} 
        if([int32]$key -band 0x00000002){$TrustAttributes += 'UpLevel'} 
        if([int32]$key -band 0x00000004){$TrustAttributes += 'Quarantaine (SID Filtering enabled)'}
        if([int32]$key -band 0x00000008){$TrustAttributes += 'Forest Transitive'} 
        if([int32]$key -band 0x00000010){$TrustAttributes += 'Cross Organization (Selective Authentication enabled)'}
        if([int32]$key -band 0x00000020){$TrustAttributes += 'Within Forest'} 
        if([int32]$key -band 0x00000040){$TrustAttributes += 'Treat as External'} 
        if([int32]$key -band 0x00000080){$TrustAttributes += 'Uses RC4 Encryption'}
    } 
    return $TrustAttributes
}
#endregion Get-TrustAttributes

#region Get Trust Information
function Get-TrustInfoAsHtml
{
    Try {$TheDC = (Get-ADDomainController -Discover).Name}
      Catch { [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Error in Get-ADDomainController Cmdlet: $($_.Exception.Message)", 400)}

    # Query trust status on $TheDC discovered domain controller
    $AllTrusts = Try { Get-WmiObject -Class Microsoft_DomainTrustStatus -Namespace root\microsoftactivedirectory -ComputerName $TheDC -ErrorAction Stop
    } Catch { $null }

    If ($AllTrusts)
    {
        $TrustOutputObj = $AllTrusts | Select-Object -Property @{L="Trusted Domain";e={$_.TrustedDomain}},
        @{L="Trusted DC Name";e={$_.TrustedDCName-replace "\\",""}},
        @{L="Trusts Status";e={$_.TrustStatusString}},
        @{L="Trusts Is OK";e={$_.TrustIsOK}},
        @{L="Trusts Type";e={
            switch ($_.TrustType)
            {
                "1" {"Windows NT (Downlevel 2000)"}
                "2" {"Active Directory (2003 and Upperlevel)"}
                "3" {"Kerberos v5 REALM (Non-Windows environment)"}
                "4" {"DCE"}
                Default {"N/A"}
            }
        }
        },
        @{L="Trusts Direction";e={
            switch ($_.TrustDirection)
            {
                "1" {"Inbound"}
                "2" {"Outbound"}
                "3" {"Bi-directional"}
                Default {"N/A"}
            }
        }
        },
        @{L="Trusts Attributes";e={($_.TrustAttributes | Get-TrustAttributes)}}
    }
    else
    {
        $TrustOutputObj  = New-Object -TypeName PSObject -Property @{ 'Trust' = 'No trust information obtained'}
    }
    return ($TrustOutputObj | ConvertTo-Html -Fragment)
}
#endregion Get Trust Information

#region Gather Hardware Information
function Get-HardwareInfoAsHTML
{
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true,
                       ValueFromPipeline=$true,
                       ValueFromPipelineByPropertyName=$true,
                       Position=0)]
            [string[]] $ComputerNames
        )

    [string]$HTMLOutput = ''

    foreach( $ComputerName in $ComputerNames )
    {
        $BaseSysInfo = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem | Select-Object  Manufacturer, Model, @{Name = 'RAM'; Expression = { [math]::Round($_.TotalPhysicalMemory / 1gb, 1).ToString("0.0"+" GB")}}
        [string]$CPUInfo = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_Processor | Select-Object DeviceID, Caption, MaxClockSpeed | ConvertTo-Html -Fragment
        [string]$DriveInfo = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_Volume -Filter "DriveType = 3 AND DriveLetter != NULL" | 
            Select-Object -Property `
            @{Name = 'Drive'; Expression = {$_.DriveLetter} },
            @{Name = 'File System'; Expression = {$_.FileSystem} },
            @{Name ='Size'; Expression = { [math]::Round($_.Capacity / 1gb, 1).ToString("0.0"+" GB")}},
            @{Name = 'Free'; Expression = { [math]::Round( $_.FreeSpace / $_.Capacity, 3 ).ToString("0.0"+" %")  } },
            @{Name = 'Block Size'; Expression = { ($_.BlockSize / 1kb).ToString("0."+" KB") } } | 
            ConvertTo-Html -Fragment
        $HTMLOutput += "<tr>
    <td>$($ComputerName)</td>
    <td>$($BaseSysInfo.Manufacturer)</td>
    <td>$($BaseSysInfo.Model)</td>
    <td>$($BaseSysInfo.RAM)</td>
    <td>$CPUInfo</td>
    <td>$DriveInfo</td>
    </tr>"
    }
    return $HTMLOutput
}
#endregion Gather Hardware Information

#region Software Info
function Get-SoftwareInfoAsHTML
{
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true,
                       ValueFromPipeline=$true,
                       ValueFromPipelineByPropertyName=$true,
                       Position=0)]
            [string[]] $ComputerNames
        )

    [string]$HTMLOutput = ''

    foreach($server in $DCs)
    {
        $array = @()
        $ControllerName = $server.Name
        $UninstallKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"

        #Create an instance of the Registry Object and open the HKLM base key

        $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$ControllerName)

        #Drill down into the Uninstall key using the OpenSubKey Method

        $regkey=$reg.OpenSubKey($UninstallKey) 

        #Retrieve an array of string that contain all the subkey names

        $subkeys = $regkey.GetSubKeyNames() 

        #Open each Subkey and use GetValue Method to return the required values for each

        foreach($key in $subkeys)
        {
            $thisKey = $UninstallKey+"\\"+$key
            $thisSubKey = $reg.OpenSubKey($thisKey)
            $hash = [ordered] @{
                    'Publisher' = $($thisSubKey.GetValue("Publisher"))
                    'Display Name' = $($thisSubKey.GetValue("DisplayName"))
                    'Display Version' = $($thisSubKey.GetValue("DisplayVersion"))
                    'Install Location' = $($thisSubKey.GetValue("InstallLocation"))
                    }
            $array += New-Object PSObject -Property $hash
        } 

        $RolesFeatures = Get-WindowsFeature -ComputerName $ControllerName | Where-Object Installed | `
                            Select-Object -Property `
                            @{Name = 'Display Name'; Expression = {$_.DisplayName} },
                            @{Name = 'Type'; Expression = {$_.FeatureType} } | ConvertTo-Html -Fragment
        $SoftwareInstalled = $array | Where-Object { $_.'Display Name' } | ConvertTo-Html -Fragment

        $HotFixes = (Get-CimInstance -ComputerName $server.Name -ClassName Win32_QuickFixEngineering -Property HotFixID | Select-Object -ExpandProperty HotFixID) -join '<br/>'

        $HTMLOutput += "<tr>
    <td>$ControllerName</td>
    <td>$($server.OperatingSystem)</td>
    <td>$($server.OperatingSystemVersion)</td>
    <td>$HotFixes</td>
    <td>$RolesFeatures</td>
    <td>$SoftwareInstalled</td>
    </tr>"
    #
    }
    return $HTMLOutput
}
#endregion Software Info

#region Forest Info
Function Get-ForestInfoAsHtml
{
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true,
                       ValueFromPipeline=$true,
                       ValueFromPipelineByPropertyName=$true,
                       Position=0)]
            $TheForest
        )
    $RecycleBINStaus = if ( $null -eq $(Get-ADOptionalFeature -filter {Name -eq 'Recycle Bin Feature'} | Select-Object -ExpandProperty EnabledScopes) )
                            { 'Disabled'} 
                            else
                            {'Enabled'}
    return $(New-Object -TypeName PSObject -Property @{
    'Forest Root Domain' = $TheForest.RootDomain
    'Forest Functional Level' = $TheForest.ForestMode
    'Forest Domains' = $( ($TheForest | Select-Object -ExpandProperty Domains) -join "`n")
    'AD Recycle BIN' = $RecycleBINStaus
    'Domain Naming Master' = $TheForest.DomainNamingMaster
    'Schema Master' = $TheForest.SchemaMaster
    'Global Catalogs' = $( ($TheForest | Select-Object -ExpandProperty GlobalCatalogs) -join "`n")
    } | ConvertTo-Html)
}
#endregion Forest Info

#region Schema Info
Function Get-SchemaInfoAsHtml
{
    [Hashtable] $SchemaHashExchange = @{
    '4397'="Exchange Server 2000 RTM";
    '4406'="Exchange Server 2000 SP3";
    '6870'="Exchange Server 2003 RTM";
    '6936'="Exchange Server 2003 SP3";
    '10628'="Exchange Server 2007 RTM";
    '10637'="Exchange Server 2007 RTM";
    '11116'="Exchange 2007 SP1";
    '14622'="Exchange 2007 SP2 or Exchange 2010 RTM";
    '14625'="Exchange 2007 SP3";
    '14726'="Exchange 2010 SP1";
    '14732'="Exchange 2010 SP2";
    '14734'="Exchange 2010 SP3";
    '15137'="Exchange 2013 RTM";
    '15254'="Exchange 2013 CU1";
    '15281'="Exchange 2013 CU2";
    '15283'="Exchange 2013 CU3";
    '15292'="Exchange 2013 SP1";
    '15300'="Exchange 2013 CU5";
    '15303'="Exchange 2013 CU6";
    '15312'="Exchange 2013 CU7-CU9";
    '153121613013236'="Exchange 2013 CU10-CU21";
    '153121613113236'="Exchange 2013 CU22";
    '153121613313237'="Exchange 2013 CU23";
    '153171323616041'="Exchange 2016 Preview";
    '153171323616210'='Exchange 2016 RTM';
    '153231323616211'='Exchange 2016 CU1';
    '153251323616212'='Exchange 2016 CU2';
    '153261323616212'='Exchange 2016 CU3';
    '153261323616213'='Exchange 2016 CU4-CU5';
    '153301323616213'='Exchange 2016 CU6';
    '153321323616213'='Exchange 2016 CU7-CU10 / Exchange 2019 Preview';
    '153321323616214'='Exchange 2016 CU11';
    '153321323616215'='Exchange 2016 CU12';
    '153321323716217'='Exchange 2016 CU13 Or Newer';
    '170001323616751'='Exchange 2019 RTM';
    '170001323616752'='Exchange 2019 CU1';
    '170011323716754'='Exchange 2019 CU2 Or Newer'
    }

    [Hashtable] $SchemaHashAD = @{
    13="Windows 2000 Server";
    30="Windows Server 2003 RTM";
    31="Windows Server 2003 R2";
    44="Windows Server 2008 RTM";
    47="Windows Server 2008 R2";
    56="Windows Server 2012 RTM";
    69="Windows Server 2012 R2";
    87="Windows Server 2016";
    88="Windows Server 2019"
    }

    [Hashtable] $SchemaHashLync = @{
    1006="LCS 2005";
    1007="OCS 2007 R1";
    1008="OCS 2007 R2";
    1100="Lync Server 2010";
    1150="Lync Server 2013 Or Newer"
    }


    #AD Schema version
    $SchemaPartition = (Get-ADRootDSE).NamingContexts | Where-Object { $_.SubString(0, 9).ToLower() -eq 'cn=schema' }
    $SchemaVersionAD = (Get-ADObject $SchemaPartition -Property objectVersion).objectVersion
    $SchemaOutputObj  = New-Object -TypeName PSObject -Property @{'AD Schema Version' = $( $SchemaHashAD.Item($SchemaVersionAD)) }

    #Exchange Schema version
    $SchemaPathExchange = "CN=ms-Exch-Schema-Version-Pt,$SchemaPartition"
    If (Test-Path "AD:$SchemaPathExchange")
    {
        [Int]$rangeUpper = (Get-ADObject $SchemaPathExchange -Property rangeUpper).rangeUpper
        if( $rangeUpper -ge 15312 )
        {
            $objVersionDefault = (Get-ADObject "CN=Microsoft Exchange System Objects,$((Get-ADRootDSE).DefaultNamingContext)" -Property objectVersion).objectVersion
            $objectVersionConfiguration = (Get-ADObject -LDAPFilter "(objectClass=msExchOrganizationContainer)" -SearchBase "$((Get-ADRootDSE).ConfigurationNamingContext)" -Property objectVersion).objectVersion
            [String]$SchemaVersionExchange = "$rangeUpper$objVersionDefault$objectVersionConfiguration"
        }
        else {[String]$SchemaVersionExchange = $rangeUpper.ToString()}
        $SchemaHashExchange.Item($SchemaVersionExchange)
        $SchemaOutputObj | Add-Member -MemberType NoteProperty -Name 'Exchange Schema Version' -Value $( $SchemaHashExchange.Item($SchemaVersionExchange) )
    }

    #Lync Schema version
    $SchemaPathLync = "CN=ms-RTC-SIP-SchemaVersion,$SchemaPartition"
    If (Test-Path "AD:$SchemaPathLync")
    {
        $SchemaVersionLync = (Get-ADObject $SchemaPathLync -Property rangeUpper).rangeUpper
        $SchemaOutputObj | Add-Member -MemberType NoteProperty -Name 'Lync Schema Version' -Value $( $SchemaHashLync.Item($SchemaVersionLync) )
    }

    return $( $SchemaOutputObj | ConvertTo-Html -Fragment)
}
#endregion Schema Info

#region Domain Info
Function Get-DomainInfoAsHtml
{
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true,
                       ValueFromPipeline=$true,
                       ValueFromPipelineByPropertyName=$true,
                       Position=0)]
            $TheForest
        )

    return $($TheForest.Domains | ForEach-Object { Get-ADDomain -Identity $_ | 
                  Select-Object  @{Name='Domain NetBIOS Name'; Expression={ $_.netBIOSName }},
                  @{Name='Domain Functional Level'; Expression={ $_.DomainMode }},
                  @{Name='PDC Emulator'; Expression={ $_.PDCEmulator }},
                  @{Name='RID Master'; Expression={ $_.RIDMaster }},
                  @{Name='Infrastructure Master'; Expression={ $_.InfrastructureMaster }},
                  @{Name='Number Of Users'; Expression={ ( Get-ADObject -LDAPFilter '(&(objectclass=user)(objectcategory=person))' ).Count }},
                  @{Name='Number Of Groups'; Expression={ ( Get-ADObject -LDAPFilter '(objectCategory=group)' ).Count }},
                  @{Name='Number Of Computers'; Expression={ ( Get-ADObject -LDAPFilter '(objectCategory=computer)' ).Count }} } | 
                  ConvertTo-Html -Fragment)
}
#endregion Domain Info

#region Site Info
function Get-SiteInfoAsHtml
{
    return $(New-Object -TypeName PSObject -Property @{
                      'Site Name' = $ADSiteLinks.Name
                      'Sites Included' = $(($ADSiteLinks | Select-Object -ExpandProperty SitesIncluded) -join '<br/>' )
                      'Site Cost' = $( ($ADSiteLinks | Select-Object -ExpandProperty Cost) -join '<br/>' )
                      'Site Replication Frequency, Minutes' = $( ($ADSiteLinks | Select-Object -ExpandProperty ReplicationFrequencyInMinutes) -join '<br/>' )
                      } | ConvertTo-Html)
}

#endregion Site Info

#region DC Info
Function Get-DCInfoAsHtml
{
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true,
                       ValueFromPipeline=$true,
                       ValueFromPipelineByPropertyName=$true,
                       Position=0)]
            $TheForest
        )
    [string []]$Props = @('Domain', 'Name', 'IsGlobalCatalog', 'OperatingSystem', 'OperatingSystemVersion', 'IsReadOnly', 'Site', 'IPv4Address', 'IPv6Address')
    return $($TheForest.Domains | ForEach-Object { Get-ADDomain -Identity $_ | 
                                ForEach-Object {Get-ADDomainController -Filter * |
                                        Select-Object -Property $Props}} |
                                        ConvertTo-Html )
}
#endregion DC Info

#region Replication Info
function Get-ReplicationInfoAsHTML
{
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true,
                       ValueFromPipeline=$true,
                       ValueFromPipelineByPropertyName=$true,
                       Position=0)]
            [string[]] $ComputerNames
        )
    [array]$ReplicationInfoArray = @()
    foreach($server in $ComputerNames)
    {
        $ReplPartner = (Get-ADReplicationPartnerMetadata -Target $server) -join "`n"
        $ReplFailure = Get-ADReplicationFailure -Target $server      
        $hash = [ordered] @{
                'Name' = $server
                'Replication Partners' = $ReplPartner.Partner
                'Last Replication' = $ReplPartner.LastReplicationSuccess
                'First Failure' = $ReplFailure.FirstFailureTime
                'Failure Count' = $ReplFailure.FailureCount
                'Failure Type' = $ReplFailure.FailureType
                }
        $ReplicationInfoArray += New-Object PSObject -Property $hash 
    }
    return $($ReplicationInfoArray | ConvertTo-Html -Fragment)
}
#endregion Replication Info

#region AD Database Info
function Get-ADDatabaseInfoAsHTML
{
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true,
                       ValueFromPipeline=$true,
                       ValueFromPipelineByPropertyName=$true,
                       Position=0)]
            [string[]] $ComputerNames
        )
    [array]$NTDSArray = @()
    foreach($server in $ComputerNames)
    {
        $Reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$server)
        [string]$SearchKey="SYSTEM\\CurrentControlSet\\services\\NTDS\\Parameters"

        $RegKey=$reg.OpenSubKey($SearchKey) 
        $DataBasePath = $RegKey.GetValue("DSA Database file")
        $NTDSREMOTEPath =  "\\$server\$DataBasePath" -replace ":","$"
        $NTDSSize = ( $( Get-item $NTDSREMOTEPath | Select-Object -ExpandProperty Length ) /1MB).ToString("0.00"+" MB")

        $SearchKey="SYSTEM\\CurrentControlSet\\services\\Netlogon\\Parameters"
        $RegKey = $Reg.OpenSubKey($SearchKey)  
        $SysVolPath = $RegKey.GetValue("SysVol")
        $SysVolSize = ((Get-Item $([system.io.path]::GetDirectoryName($SysVolPath)) | Get-ChildItem -Recurse | Measure-Object -Sum Length | Select-Object -ExpandProperty Sum) /1MB).ToString("0.00"+" MB")
    
        $hash = [ordered] @{
                'Name' = $server
                'Database Path' = $DataBasePath
                'Database Size' = $NTDSSize
                'Sysvol Path' = $SysVolPath
                'Sysvol Folder Size' = $SysVolSize
                }
        $NTDSArray += New-Object PSObject -Property $hash 
    }
     return $($NTDSArray | ConvertTo-Html -Fragment)
}
#endregion AD Database Info

#region Get User Info
function Get-UserInfoAsHtml
{
    $EnterpriseAdmins = $(Get-ADGroupMember -Identity "$($domainInfo.DomainSID.Value)-519" | 
                            Select-Object -ExpandProperty SamAccountName) | ConvertTo-Html -Property @{ l='Enterprise Admin Group Members'; e={ $_ } } -Fragment
    $DomainAdmins = $(Get-ADGroupMember -Identity "$($domainInfo.DomainSID.Value)-512" | 
                            Select-Object -ExpandProperty SamAccountName) | ConvertTo-Html -Property @{ l='Domain Admin Group Members'; e={ $_ } } -Fragment
    $SchemaAdmins = $(Get-ADGroupMember -Identity "$($domainInfo.DomainSID.Value)-518" | 
                            Select-Object -ExpandProperty SamAccountName) | ConvertTo-Html -Property @{ l='Schema Admin Group Members'; e={ $_ } } -Fragment
    $GPCreatorOwners = $(Get-ADGroupMember -Identity "$($domainInfo.DomainSID.Value)-520" | 
                            Select-Object -ExpandProperty SamAccountName) | ConvertTo-Html -Property @{ l='Group Policy Creator Owners'; e={ $_ } } -Fragment
    $PasswordNeverExpires = $(Get-ADUser -LDAPFilter "(&(sAMAccountType=805306368)(userAccountControl:1.2.840.113556.1.4.803:=65536))" | 
                            Select-Object -ExpandProperty SamAccountName) | ConvertTo-Html -Property @{ l='Password Never Expires'; e={ $_ } } -Fragment
    $PasswordNotRequired = $(Get-ADUser -LDAPFilter "(&(sAMAccountType=805306368)(userAccountControl:1.2.840.113556.1.4.803:=32))" | 
                            Select-Object -ExpandProperty SamAccountName) | ConvertTo-Html -Property @{ l='Password Not Required'; e={ $_ } } -Fragment
    $KerberosNotRequired = $(Get-ADUser -LDAPFilter "(&(sAMAccountType=805306368)(userAccountControl:1.2.840.113556.1.4.803:=4194304))" | 
                            Select-Object -ExpandProperty SamAccountName) | ConvertTo-Html -Property @{ l='Kerbereos Not Required'; e={ $_ } } -Fragment
    
    $HTMLOutput = "<tr>
    <td>$EnterpriseAdmins</td>
    <td>$DomainAdmins</td>
    <td>$SchemaAdmins</td>
    <td>$GPCreatorOwners</td>
    <td>$PasswordNeverExpires</td>
    <td>$PasswordNotRequired</td>
    <td>$KerberosNotRequired</td>
    </tr>"
    return $HTMLOutput
}
#endregion Get User Info

#region DNS Info
function Get-DNSInfoAsHtml
{
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true,
                       ValueFromPipeline=$true,
                       ValueFromPipelineByPropertyName=$true,
                       Position=0)]
            $PDCEmulator
        )
    $PrimaryZones = $(Get-DnsServerZone -ComputerName $PDCEmulator | 
                        Where-Object {$_.IsReverseLookupZone -eq $False} | 
                        Select-Object -ExpandProperty ZoneName) | ConvertTo-Html -Property @{ l='Primary Zones'; e={ $_ } } -Fragment
    $NSRecords =  (Resolve-DnsName -Name $DNSRoot -type ns | 
                        Where-Object {$_.QueryType -eq 'NS'} | 
                        Select-Object -ExpandProperty Server) | ConvertTo-Html -Property @{ l='NS Records'; e={ $_ } } -Fragment
    $MXRecords =  (Resolve-DnsName -Name $DNSRoot -type MX | 
                        Where-Object {$_.QueryType -eq 'MX'} | 
                        Select-Object -ExpandProperty Exchange) | ConvertTo-Html -Property @{ l='MX Records'; e={ $_ } } -Fragment
    $DNSForwarders = (Get-DnsServerForwarder -ComputerName $PDCEmulator | 
                        Select-Object -ExpandProperty IPAddress) | ConvertTo-Html -Property @{ l='DNS Forwarders'; e={ $_ } } -Fragment
    $DNSScavenging = (Get-DnsServerScavenging -ComputerName $PDCEmulator).scavengingState | 
                        ConvertTo-Html -Property @{ l='Scavenging Is Enabled'; e={ $_ } } -Fragment
    $DNSAging = (Get-DnsServerZoneAging -Name $DNSRoot -ComputerName $PDCEmulator).AgingEnabled | 
                        ConvertTo-Html -Property @{ l='Aging Is Enabled'; e={ $_ } } -Fragment
  
    [string] $HTMLOutput = "<tr>
    <td>$PrimaryZones</td>
    <td>$NSRecords</td>
    <td>$MXRecords</td>
    <td>$DNSForwarders</td>
    <td>$DNSScavenging</td>
    <td>$DNSAging</td>
    </tr>"
    return $HTMLOutput
}
#endregion DNS Info

#region Exchange Info
function Get-ExchangeInfoAsHtml
{
######################################
# Exchange Information
######################################
# Get all Org Management Users
    $OrgManagement = $(try {Get-ADGroupMember -Identity 'Organization Management' | 
                        Select-Object -ExpandProperty SamAccountName} catch{$null}) | ConvertTo-Html -Property @{ l='Organization Management Group Members'; e={ $_ } } -Fragment
# Get all Exchange Servers
    $ExchangeSVRs = $(try {Get-ADGroupMember -Identity 'Exchange Servers' | 
                        Select-Object -ExpandProperty SamAccountName} catch{$null}) | ConvertTo-Html -Property @{ l='Exchange Servers'; e={ $_ } } -Fragment
    [string] $HTMLOutput = "<tr>
    <td>$OrgManagement</td>
    <td>$HTMLOutput</td>
    </tr>"
    return $HTMLOutput
}
#endregion Exchange Info

#region GPO Info
function Get-GPOAsHtml
{
    $DomainGPOs = @()
    foreach($GPO in (Get-GPO -all) )
    {
        $DomainGPOs += $GPO | Select-Object -Property  @{Name = 'Domain Name'; Expression = {$_.DomainName}},
                                        @{Name = 'GPO Name'; Expression = {$_.DisplayName}},
                                        @{Name = 'Creation Time'; Expression = {$_.CreationTime}},
                                        @{Name = 'Modification Time'; Expression = {$_.ModificationTime}},
                                        @{Name='Linked To'; Expression={ Get-ADOrganizationalUnit -filter * | 
                                                Select-Object -ExpandProperty DistinguishedName | 
                                                    ForEach-Object { (Get-GPInheritance -Target $_).GPOlinks } | 
                                                        Where-Object {$_.DisplayName -eq $GPO.DisplayName } | 
                                                            Select-Object -ExpandProperty Target }} |
                Sort-Object -Property 'Linked To' -Descending

    }
    return ($DomainGPOs| ConvertTo-Html)
}
#endregion GPO Info

#region OU Info
function Get-OUInfoAsHtml
{
    return $(Get-ADOrganizationalUnit -filter * -Properties CanonicalName, Description | Sort-Object -Property CanonicalName | Select-Object distinguishedName, Description | ConvertTo-Html)
}
#endregionOU Info

####################
#endregion Functions

#region Variables
# Get the date for the filename 
[string] $date = Get-Date -UFormat "%m/%d/%Y %T"

$TheForest = Get-ADForest
$domainInfo = Get-ADDomain
$PDCEmulator = $domainInfo.PDCEmulator
$DNSRoot = $domainInfo.dnsroot
$ADsiteLinks = Get-ADReplicationSiteLink -Filter *
$DCs = Get-ADDomainController -Filter * | 
        Select-Object -Property Domain, Forest, Name, IPv4Address, IPv6Address, IsGlobalCatalog, OperatingSystem, OperatingSystemVersion, IsReadOnly, Site
$Sites = ($TheForest | 
         Select-Object -ExpandProperty Sites) -join '<br/>'
#endregion Variables

######################################
# HTML Output
######################################
$Create_HTML_doc = "<!DOCTYPE html>
  <head>
  <title>Active Directory Information</title>
  <style>

  BODY{
    font-family: Arial, Verdana;
    background-color:#F3F4F4;
  }
  TABLE{
    border=1; 
    border-color:black; 
    border-width:1px; 
    border-style:solid;
    border-collapse: collapse; 
    empty-cells:show
  }
  TH{
    font-size: 12px;
    color:white;
    border-width:1px; 
    padding:5px; 
    border-style:solid; 
    font-weight:bold; 
    text-align:left;
    border-color:black;
    background-color:#1488ca;
    empty-cells:show
  }
  TD{
    font-size: 10px;
    color:black; 
    colspan=1; 
    border-width:1px; 
    padding:5px; 
    font-weight:normal; 
    border-style:solid;
    border-color:black;
    background-color:#ffffff;
    vertical-align: top;
    empty-cells:show
  }
  h1{
    font-size: 24px;
    text-align: center;
    color: #0277bd;
  }
  h2{
    font-size: 20px;    
  }
  h3{
    font-size: 12px;
  }
  </style>
  </head>
  <h1>Active Directory Information for: $DNSRoot </h1>
  <h3>Collected on $date</h3>

  <h2>Forest Information</h2> 
  $($TheForest | Get-ForestInfoAsHtml)
  <br/>

  <h2>Domain Information</h2> 
  <table>
  $($TheForest | Get-DomainInfoAsHtml)
  </table>

  <h2>AD Schema Information</h2> 
  $(Get-SchemaInfoAsHtml)
  <br/>

  <h2> Trust Information </h2> 
  $(Get-TrustInfoAsHtml)
  <br/>

  <h2> Domain Controller Information </h2>
  $($TheForest | Get-DCInfoAsHtml)
  <br/>

  <h2>Domain Controller Hardware Information</h2> 
  <table>
  <tr>
    <td><h3>Name</h3></td>
    <td><h3>Manufacturer</h3></td>
    <td><h3>Model</h3></td>
    <td><h3>RAM</h3></td>
    <td><h3>CPU</h3></td>
    <td><h3>Drives</h3></td>
  </tr>
  $($DCs.Name | Get-HardwareInfoAsHTML)
  </table>

  <h2>AD Database Information</h2>
  $($DCs.Name | Get-ADDatabaseInfoAsHTML)
  <br/>

  <h2>Domain Controller Software Information</h2> 
  <table>
  <tr>
    <td><h3>Name</h3></td>
    <td><h3>OperatingSystem</h3></td>
    <td><h3>OperatingSystemVersion</h3></td>
    <td><h3>Hot Fixes</h3></td>
    <td><h3>Roles And Features</h3></td>
    <td><h3>Software</h3></td>
  </tr>
  $($DCs.Name | Get-SoftwareInfoAsHTML)
  </table>

  <h2>DNS Information</h2>
  <table>
  $($PDCEmulator | Get-DNSInfoAsHtml)
  </table>

  <h2>AD Site Information</h2>
  <table>
  <tr>
    <td><h3>Forest Wide Sites</h3></td>
    <td><h3>Site Links</h3></td>
  </tr>
  <tr>
    <td>$Sites</td>
    <td>$(Get-SiteInfoAsHtml)</td>
  </tr>
  </table>

  <h2>Replication Information</h2>
  $($DCs.Name | Get-ReplicationInfoAsHTML)
  <br/>

  <h2>GPO Information</h2> 
  $(Get-GPOAsHtml)
  
  <h2>OU Structure Information</h2> 
  $(Get-OUInfoAsHtml)

  <h2>User Accounts</h2>
  <table>
  $(Get-UserInfoAsHtml)
  </table> 

  <h2>Exchange Information</h2>
  <table>
  $(Get-ExchangeInfoAsHtml)
  </table>
"

$Create_HTML_doc | Out-File -FilePath "FileSystem::$OutputFile" -Force -Encoding UTF8