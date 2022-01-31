param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $SQLUser,
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $SQLPwd,
    [parameter(Mandatory=$false)]
    [string] $SQLServer = 'localhost',
    [parameter(Mandatory=$false)]
    [switch] $UseWindowsAuthentication,
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


if([string]::IsNullOrEmpty($SQLServer)) {$SQLServer = 'localhost'}
"Host\Instance: $SQLServer" | Write-Debug

[string[]] $ConnectionParameters = @("Server = $SQLServer", 'ApplicationIntent=ReadOnly')

if ($UseWindowsAuthentication)
{
    $ConnectionParameters += 'Integrated Security=true'
}
else
{
    $ConnectionParameters += "User ID = ""$SQLUser"""
    $ConnectionParameters += "Password = ""$SQLPwd"""
}

[string] $ConnectionString = $ConnectionParameters -join ';'

[scriptblock] $ScriptBlock = {

    [string] $Query = 'USE ksubscribers; SELECT agentGuid, uninstallPassword FROM sec.SecurityAsset WHERE uninstallPassword IS NOT NULL'

    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection  
    $SqlConnection.ConnectionString = $args[0]

    try
    {
        $SqlConnection.Open()
    }
    catch
    {
        $_.Exception.Message | Write-Error
    }
    
    if ([System.Data.ConnectionState]::Open -eq $SqlConnection.State)
    {
        #creating command object
        [System.Data.SqlClient.SqlCommand] $SqlCmd = $SqlConnection.CreateCommand()
        $SqlCmd.CommandText = $Query
        #$SqlCmd.Connection = $SqlConnection  
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter  
        $SqlAdapter.SelectCommand = $SqlCmd
        #Creating Dataset  
        $DataSet = New-Object System.Data.DataSet
   
        try
        {
            $SqlAdapter.Fill($DataSet) | Out-Null
        }
        catch
        {
            $_.Exception.Message | Write-Error
        }
        if(0 -lt $DataSet.Tables.Count)
        {
            $DataSet.Tables[0] | Select-Object agentGuid,uninstallPassword | Write-Output
        }
        $DataSet.Dispose()
        $SqlAdapter.Dispose()
        $SqlCmd.Dispose()

        ## Close the connection when work done
        $SqlConnection.Close()
        $SqlConnection.State | Write-Verbose
    }
}

$InvokeParameters = @{
ScriptBlock = $ScriptBlock
Args = @($ConnectionString)
ConfigurationName = "Microsoft.PowerShell32"
}

if ($UseWindowsAuthentication)
{
    'Windows Athentication' | Write-Debug
    [securestring] $SecurePassword = ConvertTo-SecureString $SQLPwd -AsPlainText -Force
    [pscredential] $Credential = New-Object System.Management.Automation.PSCredential ($SQLUser, $SecurePassword)

    $InvokeParameters.Add('Credential', $Credential)
    $InvokeParameters.Add('ComputerName', $env:COMPUTERNAME)
}

[Array] $KAVPwd = Invoke-Command @InvokeParameters

if(0 -lt $KAVPwd.Count)
{
    $assembly = [System.Reflection.Assembly]::LoadFrom("C:\Users\vladislav.semko\OneDrive - Kaseya\Documents\Scripts\Work\PathFinder\Decrypt\Kaseya.AppFoundation.dll")
    foreach($item in $KAVPwd)
    {
        $item.uninstallPassword
        $item.uninstallPassword = [Hermes.shared.MaskData]::HashAndUnmaskDataStringForDb($($item.uninstallPassword), $($item.agentGuid))
    }
}

$KAVPwd  | Write-Output


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