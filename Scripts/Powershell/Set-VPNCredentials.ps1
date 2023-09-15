param (
[parameter(Mandatory=$true, 
        ParameterSetName = 'Add')]
[parameter(Mandatory=$true, 
        ParameterSetName = 'Remove')]
[ValidateNotNullOrEmpty()]
    [string]$VpnConnectionName,

[parameter(Mandatory=$true, 
    ParameterSetName = 'Add')]
    [ValidateScript(
        {if ($_ -match '^([\w.-]+(?:\.[\w\.-]+)+|((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}|((([0-9a-fA-F]){1,4})\:){7}([0-9a-fA-F]){1,4}|localhost)$') {$true}
        else {Throw "`"$_`" is an invalid address."}}
        )]
    [string]$ServerAddress,

[parameter(Mandatory=$false, 
    ParameterSetName = 'Add')]
    [ValidateSet('Pptp',' L2tp',' Sstp',' Ikev2',' Automatic')]
    [string]$TunnelType,

[parameter(Mandatory=$false, 
    ParameterSetName = 'Add')]
    [ValidateSet('NoEncryption',' Optional',' Required',' Maximum',' Custom')]
    [string]$EncryptionLevel,

[parameter(Mandatory=$false, 
    ParameterSetName = 'Add')]
    [ValidateSet('Pap',' Chap',' MSChapv2',' Eap',' MachineCertificate')]
    [string]$AuthenticationMethod,

[parameter(Mandatory=$false, 
        ParameterSetName = 'Add')]
[ValidateNotNullOrEmpty()]
    [string]$L2tpPsk,

[parameter(Mandatory=$false,
        ParameterSetName = 'Add')]
    [switch]$UseWinlogonCredential,

[parameter(Mandatory=$false,
        ParameterSetName = 'Add')]
    [switch]$RememberCredential,

[parameter(Mandatory=$true, 
        ParameterSetName = 'Remove')]
    [switch]$Remove,

[parameter(Mandatory=$true, 
        ParameterSetName = 'Add')]
[parameter(Mandatory=$true, 
        ParameterSetName = 'Remove')]
[ValidateNotNullOrEmpty()]
    [switch]$AllUserConnection
)

#region Checking & installing VpnClient Module
[string] $ModuleName = 'VpnClient'
[string] $PkgProvider = 'NuGet'

if ( -not ((Get-Module -ListAvailable | Select-Object -ExpandProperty Name) -contains $ModuleName) ) {
    Write-Debug "Please wait for the necessary modules to install."
    if ( -not ((Get-PackageProvider -ListAvailable | Select-Object -ExpandProperty Name) -contains $PkgProvider) ) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Install-PackageProvider -Name $PkgProvider -Force -Confirm:$false
    }
    Install-Module -Name $ModuleName -Force -Confirm:$false
}
Import-Module $ModuleName
if ( -Not (Get-Module -ListAvailable -Name $ModuleName) ) {
    throw "ERROR: the PowerShell module <$ModuleName> is not available"
}  else {
    Write-Debug "INFO: The Module <$ModuleName> imported successfully."
}
#endregion Checking & installing VpnClient Module

[scriptblock] $Scriptblock = {

    [hashtable]$Parameters = @{
        Name  = $VpnConnectionName
        Force = $true
    }
    if ($AllUserConnection) {{$Parameters.Add('AllUserConnection', $true)}}

    if ($Remove) {
        try {
            Remove-VpnConnection @Parameters
        } catch {
            Throw "Failed to remove VPN credentials. Error: $($_.Exception.Message)"
        }
    } else {
    
        $Parameters.Add('ServerAddress', $ServerAddress)
        $Parameters.Add('PassThru', $true)
    
        if ($RememberCredential) {$Parameters.Add('RememberCredential', $true)}
    
        if ( -not [string]::IsNullOrEmpty($TunnelType) ) {$Parameters.Add('TunnelType', $TunnelType)}

        if ( -not [string]::IsNullOrEmpty($EncryptionLevel) ) {$Parameters.Add('EncryptionLevel', $EncryptionLevel)}
    
        if ( -not [string]::IsNullOrEmpty($AuthenticationMethod) ) {$Parameters.Add('AuthenticationMethod', $AuthenticationMethod)}

        if ( -not [string]::IsNullOrEmpty($L2tpPsk) ) {$Parameters.Add('L2tpPsk', $L2tpPsk)}

        if ($UseWinlogonCredential) {$Parameters.Add('UseWinlogonCredential', $true)}

        try {
            $vpnConnection = Add-VpnConnection @Parameters
        } catch {
            Write-Host "Failed to add VPN credentials. Error: $($_.Exception.Message)"
        }
    }
}

if ($AllUserConnection) {
    Invoke-Command -ScriptBlock $Scriptblock
} else {
    #Add VPN connection to the logged-in users via scheduled task
    $str = $ScriptBlock.ToString()
    $EncodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($str))

    #region Get logged in users
    [string] $SIDPattern = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'

    $LoggedInUsers = @()

    $LoggedInUsersSIDs = Get-ChildItem Registry::HKEY_USERS | `
        Where-Object {$_.PSChildname -match $SIDPattern} | `
        Select-Object -ExpandProperty PSChildName

    if ( 0 -ne $LoggedInUsersSIDs.Length )
    {
        Foreach ( $SID in $LoggedInUsersSIDs )
        {
            $Account = New-Object Security.Principal.SecurityIdentifier("$SID")
            $NetbiosName = $(  try { $Account.Translate([Security.Principal.NTAccount]) | Select-Object -ExpandProperty Value } catch { $_.Exception.Message } )

            if ( $NetbiosName -notmatch 'Exception' )
            {
                $LoggedInUsers += $NetbiosName
            }
        }
    }
    #endregion Get logged in users

    if ( 0 -ne $LoggedInUsers.Length )
    {
    
        Foreach ( $UserPrincipal in $LoggedInUsers )
        {
            $At = $( (Get-Date).AddSeconds($DelaySeconds) )
            $TaskName = "RunOnce-SetVPN"
            "PowerShell.exe $ScheduledTaskAction" | Write-Debug
            $TaskParameters = @{
                TaskName = $TaskName
                Trigger = New-ScheduledTaskTrigger -Once -At $At
                Principal = New-ScheduledTaskPrincipal -UserId $UserPrincipal
                Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $EncodedCommand"
            }

            if ( $null -eq $(try {Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop} Catch {$null}) )
            {
                Register-ScheduledTask @TaskParameters
            }
            else
            {
                Set-ScheduledTask @TaskParameters
            }
        }
    }
}