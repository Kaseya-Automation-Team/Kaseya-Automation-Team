<#
.Synopsis
    The script creates new VSA organizations and their nested groups for the top-level groups of the specified VSA organization.
.DESCRIPTION
    The script will check if the VSAModule PowerShell module folder exists in the user's environment Module folder. If it's not found, the script will download the module from Github and install it in the appropriate folder.
    The script reads the machine groups within a given organization and creats new VSA organizations for the top-level machine groups.
    Within the newly created organizations the machine group structures that were read from the source organization are recreated.
.PARAMETER VSAAddress
    The address of the source VSA server.
.PARAMETER VSAUserName
    The VSA User name. The user must have permissions to create VSA Organizations & Machine Groups.
.PARAMETER UserPAT
    The source VSA User access token. (VSA->System->User Security->Users->Access Tokens)
.PARAMETER OrgRef
    (Optional) Substring to filter out source Organizations by the symbolyc ID (VSA->System->Orgs/Groups/Depts/Staff->Manage->ID).
.PARAMETER OverwriteExistingModule
    (Optional) Downloads the VSAModule module from github and overwrites the existing one in the user's environment Module folder.
.PARAMETER LogIt
    (Optional) Logs execution transcript to a file.
.EXAMPLE
    .\Convert-MachineGroups.ps1 -VSAAddress 'https://source.example' -VSAUserName 'user1' -UserPAT '01e0e010-1010-1010-b101-ca1beec10efc' -OverwriteExistingModule
.NOTES
    Version 0.1
    Requires:
        Internet connection to download VSAModule from GitHub if the module was not installed beforehand.
        Proper permissions to install module VSAModule and execute the script.
   
    Author: Proserv Team - VS

#>
param (
    [parameter(Mandatory=$true, 
        ValueFromPipelineByPropertyName = $true)]
    [ValidateScript(
            {if ($_ -match '^http(s)?:\/\/([\w.-]+(?:\.[\w\.-]+)+|localhost)$') {$true}
            else {Throw "$_ seems to be an invalid address. Enter a valid address that begins with https://"}}
            )]
    [string] $VSAAddress,


    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $VSAUserName,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $UserPAT,


    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string] $OrgRef,

    [parameter(Mandatory=$false)]
    [switch] $OverwriteExistingModule,

    [parameter(Mandatory=$false)]
    [switch] $LogIt
)
#region check/start transcript
[string]$Pref = 'Continue'
if ( $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
    $LogFile = "$ScriptPath\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

#region Checking & installing VSA Module
function Get-ModuleToFolder {
    param (
        [string] $URL,
        [string] $ArchiveName,
        [string] $ModuleInstallFolder
    )

    Write-Host "Downloading from GitHub: $URL" -ForegroundColor Cyan
    $TempArchiveFile = Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $ArchiveName

    Invoke-WebRequest $URL -OutFile $TempArchiveFile
    Unblock-File -Path $TempArchiveFile

    [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory( $TempArchiveFile, $ModuleInstallFolder )

    #perform cleanup
    Remove-Item -Path $TempArchiveFile -Force -ErrorAction SilentlyContinue

    Write-Host "Module" -NoNewline
    Write-Host "`t$moduleName" -ForegroundColor Green -NoNewline
    Write-Host "`tinstalled into`t" -NoNewline
    Write-Host $ModuleInstallFolder -ForegroundColor Green -NoNewline
    Write-Host "`tFolder"
}

function Install-GithubModule
{
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $ArchiveName,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ModuleFolder,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [uri] $URIBase = 'https://github.com/Kaseya-Automation-Team/Kaseya-Automation-Team/raw/main/Public/archive',

        [Parameter(Mandatory=$false)]
        [Switch] $OverwriteExistingModule
    )
    
    # Name for the folder where the module is installed
    if ( [string]::IsNullOrEmpty($ModuleFolder) ) {
        $ModuleFolder = $([io.path]::GetFileNameWithoutExtension($ArchiveName))
    }

    $ModuleName = Split-Path $ModuleFolder -leaf

    $URL = $URIBase, $ArchiveName -join '/' 
     
    #region check if module exists
        #region check if module folder already created
    $separator = [IO.Path]::PathSeparator
    $ProfileModulePath = $env:PSModulePath.Split($separator)[0]
    if ( -not (Test-Path $ProfileModulePath) ) {
        New-Item -ItemType Directory -Path $ProfileModulePath
    }
        #endregion check if module folder already created
    $ModuleInstallFolder = Join-Path -Path $ProfileModulePath -ChildPath $ModuleName
    [bool] $FolderExists = Test-Path $ModuleInstallFolder

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if ($OverwriteExistingModule) {
        $Ovr = '1'
    } else {$Ovr = '0'}
    [int] $State = [convert]::ToInt32( $([string]([int]$FolderExists) + $Ovr  ), 2 )
    switch ($State)
    {
        {$_ -le 1} { #The module folder does not exist
            Get-ModuleToFolder -URL $URL -ArchiveName $ArchiveName -ModuleInstallFolder $ModuleInstallFolder
        }
        2 { #The module folder exists. Not overwrite
            break
        }
        3 { #The module folder exists. Overwrite
            Write-Host "The module folder" -NoNewline
            Write-Host "`t$ModuleInstallFolder" -ForegroundColor Yellow  -NoNewline
            Write-Host "`texists." -NoNewline
            Write-Host "`t Removing" -ForegroundColor Red
            Remove-Item -Path $ModuleInstallFolder -Recurse -Force
            Get-ModuleToFolder -URL $URL -ArchiveName $ArchiveName -ModuleInstallFolder $ModuleInstallFolder
        }
    }
    #endregion check if module exists
    return $ModuleInstallFolder
}
#endregion Checking & installing VSA Module

#region Load VSA Module
#Clear-Host
Write-host "One moment, please`n"
$ModuleName  = "VSAModule"
$ArchiveName = "$ModuleName.zip"

$InstallModuleParams = @{ ArchiveName = $ArchiveName }
if($OverwriteExistingModule) {
    $InstallModuleParams.Add('OverwriteExistingModule', $true)
}
$ModulePath  = Install-GithubModule @InstallModuleParams

Import-Module "$ModulePath\$ModuleName.psm1" -Force
#endregion Load VSA Module

#region function Get-StringTail
function Get-StringTail
<#
.Synopsis
   Extracts string after Nth occurence of a symbol#>
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateScript({
            if( [string]::IsNullOrEmpty($_) ) {
                throw "Empty value"
            }
            return $true
        })]
        [string] $InputString,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string] $Delimiter = '.',

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [int] $Occurence = 2
    )

    Begin {
        $Delimiter = [Regex]::Escape($Delimiter)
    }
    Process {
        [string] $RegExPattern = "^((?:[^$Delimiter]*$Delimiter){$Occurence})(.*$)"
        [string] $Result = try {[regex]::Matches( $InputString, $RegExPattern ).Groups[2].Value} catch {$null}
    }
    End {
        return $Result
    }
}
#endregion function Get-StringTail


# region function Copy-MGStructure
function Copy-MGStructure {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,
        
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string[]] $MGNames,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( [string]::IsNullOrEmpty($_) ) {
                throw "Empty value"
            }
            return $true
        })]
        [string] $OrgId
    )
    
    [hashtable] $DestParams = @{
        OrgID = $OrgId
        VSAConnection = $VSAConnection
    }

    $MGNames = $MGNames | Sort-Object -Property MachineGroupName

    [array] $DestMGs = @()
    $DestMGs += Get-VSAMachineGroup  @DestParams | Sort-Object -Property MachineGroupName
    $DestDefaultMG = $DestMGs | Where-Object { $_.ParentMachineGroupId -notmatch "^\d+$"}
    [string] $ParentMGId = $DestDefaultMG | Select-Object -ExpandProperty MachineGroupId

    Foreach ( $GroupName in $MGNames )
    {
        [string] $EscapedMGName = [Regex]::Escape($GroupName)
        [string] $RightMostMGName = $GroupName.Split('.')[-1]
        [array]$DirectChildren = @()

        # region Check if the Machine Group already exists in the destination
        $Info = "Checking if there's <$GroupName> group in the Destination "      
        $Info | Write-Host
        $Info | Write-Debug
        $Info | Write-Verbose

        $CheckDestination = $(Get-VSAMachineGroup  @DestParams) | Where-Object { $_.MachineGroupName -eq $GroupName }
        if ( $null -eq  $CheckDestination ) {
            
            $Info = "Creating Machine Group <$GroupName>."      
            $Info | Write-Host
            $Info | Write-Debug
            $Info | Write-Verbose

            #region define Parent Machine Group and check if the Parent Machine Group already exists.
            [string] $RegExPattern = "(^.*)(\.$RightMostMGName$)"
            [string] $ParentMGName = $( try {[regex]::Matches( $GroupName, $RegExPattern ).Groups[1].Value} catch {$null} )
            $Info = "Parent MG Name for the Group <$GroupName> is: <$ParentMGName>"
            $Info | Write-Host
            $Info | Write-Debug
            $Info | Write-Verbose
            if ( -not [string]::IsNullOrEmpty($ParentMGName) ) {
                [string] $FoundMGId = $(Get-VSAMachineGroup  @DestParams) | Where-Object { $_.MachineGroupName  -eq $ParentMGName } | Select-Object -ExpandProperty MachineGroupId
                if ( -not [string]::IsNullOrEmpty($FoundMGId) ) {
                    $ParentMGId = $FoundMGId

                    $Info = "For the parent Machine Group <$ParentMGName> found ID: <$FoundMGId>"      
                    $Info | Write-Host -ForegroundColor Gray
                    $Info | Write-Debug
                    $Info | Write-Verbose
                } else {
                    $Info = "Not found ID for the parent Group <$ParentMGName>. Default group will be used as the parent"      
                    $Info | Write-Host -ForegroundColor Gray
                    $Info | Write-Debug
                    $Info | Write-Verbose
                }
            }
            $AddMGParams = $DestParams.Clone()
            $AddMGParams.Add('MachineGroupName', $RightMostMGName)
            $AddMGParams.Add('ParentMachineGroupId', $ParentMGId)
            Add-VSAMachineGroup @AddMGParams
            #endregion define Parent Machine Group and check if the Parent Machine Group already exists.
        } else  { # A MG with this name already exists in the destination
            
            $GroupId  = $CheckDestination.MachineGroupId
            $Info = "The Machine group <$GroupName> with ID <$GroupId> already exists."
            $Info | Write-Host -ForegroundColor Yellow
            $Info | Write-Debug
            $Info | Write-Verbose

        }
        # endregion Check if the Machine Group already exists in the destination
        
        # region Find direct children
        $DirectChildren += $MGNames | Where-Object { $_ -match "^$EscapedMGName\..[^\.]*$" }
        if ( 0 -lt $DirectChildren.Count) {
            [hashtable]$CopyMGParams = @{ VSAConnection = $VSAConnection
                                            OrgId = $OrgId
                                            MGNames = $DirectChildren
                                        }
            $Info = "Recursive call Copy-MGStructure for <$($DirectChildren.Count)> direct children"
            $Info | Write-Host
            $Info | Write-Debug
            $Info | Write-Verbose

            $Info = $CopyMGParams | Out-String | Write-Debug
            $Info | Write-Host
            $Info | Write-Debug
            $Info | Write-Verbose

            Copy-MGStructure @CopyMGParams
        }
        # endregion Find direct children
    } # Foreach ( $GroupName in $MGNames )
}
#endregion function Copy-MGStructure

#region Process
if ( Get-Module -ListAvailable -Name $ModuleName) {
    [array] $SourceOrganizations = @()
    [array] $SourceTopGroups = @()
    [array] $SourceNestedGroups = @()

    [securestring]$secStringPassword = ConvertTo-SecureString $UserPAT -AsPlainText -Force
    [pscredential]$VSACred = New-Object System.Management.Automation.PSCredential ($VSAUserName, $secStringPassword)
    $SourceConnParams       = @{
                                VSAServer     = $VSAAddress
                                Credential    = $VSACred
                            }
    $VSAConnection     = New-VSAConnection @SourceConnParams

    $SourceOrganizations += Get-VSAOrganization -VSAConnection $VSAConnection

    $TheOrg = $SourceOrganizations | Where-Object {$_.OrgRef -eq $OrgRef}


    $SourceMGs += Get-VSAMachineGroup -VSAConnection $VSAConnection -OrgID $($TheOrg.OrgID) | `
                    Where-Object { "$OrgRef.root" -ne $_.MachineGroupName }<#Workaround for the name 'root'#> |`
                    Sort-Object -Property MachineGroupName, ParentMachineGroupId

    #For each of the top groups
    $SourceTopGroups += $SourceMGs | Where-Object { $_.ParentMachineGroupId -notmatch "^\d+$"}
    $SourceNestedGroups += $SourceMGs | Where-Object { $_.ParentMachineGroupId -match "^\d+$"}

    foreach ( $TopGroup in $SourceTopGroups) {

        [string] $OrgWouldBeName = $TopGroup.MachineGroupName.Split('.')[-1]  

        #region Check if the organization for current Top-level Machine group already created
        [string] $OrgId # The ID for an Organization which will contain migrated Machine Groups

        $ExistingOrg = $SourceOrganizations | Where-Object { $_.Orgname -eq $OrgWouldBeName }
        if ( $null -eq $ExistingOrg) {
            $Info = "Creating new Organization <$OrgWouldBeName>"
            $Info | Write-Host -ForegroundColor Green
            $Info | Write-Debug
            $Info | Write-Verbose

            $OrgId = Add-VSAOrganization -VSAConnection $VSAConnection -OrgName $OrgWouldBeName -OrgRef $OrgWouldBeName -ExtendedOutput
            Start-Sleep -Seconds 5
            $SourceOrganizations += Get-VSAOrganization -VSAConnection $VSAConnection -OrganizationID $OrgId
        } else {
            $Info = "The Organization <$OrgWouldBeName> already exists"
            $Info | Write-Host -ForegroundColor Yellow
            $Info | Write-Debug
            $Info | Write-Verbose

            $OrgId = $ExistingOrg.OrgId
        }

        #endregion Check if the organization for current Top-level Machine group already created

        [array]$SourceGroups4TheOrg = @()
        $SourceGroups4TheOrg += $SourceNestedGroups | Where-Object { $_.MachineGroupName -match "^$($TheOrg.OrgRef).$OrgWouldBeName"}

        [string] $DestDefaultMGName = Get-VSAMachineGroup -VSAConnection $VSAConnection -OrgID $OrgId | Where-Object { $_.ParentMachineGroupId -notmatch "^\d+$"} | Select-Object -ExpandProperty MachineGroupName

        [string[]]$WouldBeMGNames = @()
        $WouldBeMGNames += $SourceGroups4TheOrg | Select-Object -ExpandProperty MachineGroupName | ForEach-Object { 
                                    [string] $ShiftedMGName = Get-StringTail -InputString $_
                                    if ( -not [string]::IsNullOrEmpty($ShiftedMGName) ) {
                                        $ShiftedMGName = ".$ShiftedMGName"}
                                    "$DestDefaultMGName$ShiftedMGName"}

        if ( 0 -lt $WouldBeMGNames.Count) {
            $Info = "Machine Group names to be created for the Organization <$OrgWouldBeName> are:"
            $Info | Write-Host
            $Info | Write-Debug
            $Info | Write-Verbose

            $Info = $WouldBeMGNames | Out-String
            $Info | Write-Host -ForegroundColor Gray
            $Info | Write-Debug
            $Info | Write-Verbose
            Copy-MGStructure -VSAConnection $VSAConnection -MGNames $WouldBeMGNames -OrgId $OrgId
        }
    }
} else {
    #The VSA Module unavailable
    Write-Host "Module" -ForegroundColor Yellow -NoNewline
    Write-Host "`t$ModuleName" -ForegroundColor Red -BackgroundColor White -NoNewline
    Write-Host "`tis not available" -ForegroundColor Yellow
}
#endregion Process

#region check/stop transcript
if ( $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript