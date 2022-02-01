param (
    [Alias("User","UserName")]
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $SQLUser,
    [Alias("Password", "Pwd")]
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $SQLPwd,
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
	[string]$OutputFilePath,
    [Alias("Host","Server")]
    [parameter(Mandatory=$false)]
    [string] $SQLServer = 'localhost',
    [parameter(Mandatory=$false)]
    [switch] $UseWindowsAuthentication,
    [parameter(Mandatory=$false)]
    [switch] $LogIt
)

$ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path

#region check/start transcript
[string]$Pref = 'Continue'
if ( $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
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
[string[]] $Fields = @( 'partitionId', 'agentGuid', 'uninstallPassword' )

[scriptblock] $ScriptBlock = {
    
    [string] $Query = "USE ksubscribers; SELECT $($using:Fields -join ',') FROM sec.SecurityAsset WHERE uninstallPassword LIKE 'CoveredData2::%'"
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
            [Array] $KAVPwd = $DataSet.Tables[0]
            $DllPath = Join-Path -Path $using:ScriptPath -ChildPath "Kaseya.AppFoundation.dll"
            [System.Reflection.Assembly]::LoadFrom( $DllPath )
            foreach($item in $KAVPwd)
            {
                $item.uninstallPassword = [Hermes.shared.MaskData]::HashAndUnmaskDataStringForDb($($item.uninstallPassword), $($item.agentGuid))
            }
            $KAVPwd | Write-Output
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
ComputerName = $SQLServer
}

Invoke-Command @InvokeParameters | Select-Object $Fields | Where-Object {$_.uninstallPassword} | Export-Csv -Path $OutputFilePath -Encoding UTF8 -NoTypeInformation -Force 

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