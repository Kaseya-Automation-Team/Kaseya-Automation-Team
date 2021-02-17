<#
.Synopsis
   Gathers SQL Server index fragmentation information. By default it checks default SQL instance on the local host.
.DESCRIPTION
   Used by Agent Procedure
   Gathers SQL Server index fragmentation information from all non-system databases on the computer and saves information to a CSV-file.
.EXAMPLE
   .\Gather-DBIndexFragmentation.ps1 -FileName 'frag_indexes.csv' -Path 'C:\TEMP' -SQLUser 'sa' -SQLPwd '12345'
.EXAMPLE
   .\Gather-DBIndexFragmentation.ps1 -FileName 'frag_indexes.csv' -Path 'C:\TEMP' -SQLServer 'RemoteHostName' -SQLUser 'sa' -SQLPwd '12345' -SQLInstance 'AnotherSQLInstance' -LogIt 0
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>
param (
    [parameter(Mandatory=$true)]
    [string] $FileName,
    [parameter(Mandatory=$true)]
    [string] $Path,
    [parameter(Mandatory=$true)]
    [string] $SQLUser,
    [parameter(Mandatory=$true)]
    [string] $SQLPwd,
    [parameter(Mandatory=$false)]
    [string] $SQLServer = 'localhost',
    [parameter(Mandatory=$false)]
    [string] $SQLInstance = 'MSSQLSERVER',
    [parameter(Mandatory=$false)]
    [int] $LogIt = 1
)

#region check/start transcript
[string]$Pref = 'Continue'
if ( 1 -eq $LogIt )
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
#region SQL query
[string] $SQLQuery= @"
DECLARE @INDEXFRAGINFO TABLE (
DatabaseName nvarchar(128),
DatabaseID smallint,
TableName nvarchar(384),
IndexID INT, 
IndexName nvarchar(128), 
IndexType nvarchar(60), 
IndexDepth tinyint,
IndexLevel tinyint,
[Fragmentation, %] float, 
fragment_count bigint
)

DECLARE @command VARCHAR(1000) 
SELECT @command = 'Use [' + '?' + '] select ' + '''' + '?' + '''' + ' AS DatabaseName,
DB_ID() AS DatabaseID,
QUOTENAME(DB_NAME(i.database_id), '+ '''' + '"' + '''' +')+ N'+ '''' + '.' + '''' +'+ QUOTENAME(OBJECT_SCHEMA_NAME(i.object_id, i.database_id), '+ '''' + '"' + '''' +')+ N'+ '''' + '.' + '''' +'+ QUOTENAME(OBJECT_NAME(i.object_id, i.database_id), '+ '''' + '"' + '''' +') AS TableName, 
i.index_id AS IndexID,
o.name AS IndexName, 
i.index_type_desc AS IndexType, 
i.index_depth AS IndexDepth,
i.index_level AS IndexLevel,
i.avg_fragmentation_in_percent AS [Fragmentation, %], 
i.fragment_count AS FragmentCount
from (
select *, DENSE_RANK() OVER(PARTITION by database_id ORDER BY avg_fragmentation_in_percent DESC) as rnk
from sys.dm_db_index_physical_stats(DB_ID(), default, default, default,'+ '''' + 'limited' + '''' +')
where avg_fragmentation_in_percent >0 AND 
INDEX_ID > 0 AND 
Page_Count > 500 
) as i
join sys.indexes o on o.object_id = i.object_id and o.index_id = i.index_id
order by i.database_id, [Fragmentation, %];'

INSERT @INDEXFRAGINFO EXEC sp_MSForEachDB @command 

SELECT * FROM @INDEXFRAGINFO
WHERE DatabaseID > 4
ORDER BY [Fragmentation, %] DESC;
"@
#endregion SQL query

if ( 'Running' -ne (Get-Service -Name $SQLInstance).Status)
{
    Write-Warning "MS SQL Server is not running"
}
else
{
#region Connection settings
[string] $ConnectionString = @"
Server = {0}; User ID = {1}; Password = {2};
"@ -f @($SQLServer, $SQLUser, $SQLPwd)
#endregion Connection settings

    if ( $FileName -notmatch '\.csv$') { $FileName += '.csv' }
    if (-not [string]::IsNullOrEmpty( $Path) ) { $FileName = "$Path\$FileName" }

    try {
        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection  
        $SqlConnection.ConnectionString = $ConnectionString
        $SqlConnection.Open()
        #creating command object
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand  
        $SqlCmd.CommandText = $SQLQuery  
        $SqlCmd.Connection = $SqlConnection  
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter  
        $SqlAdapter.SelectCommand = $SqlCmd
        #Creating Dataset  
        $DataSet = New-Object System.Data.DataSet  
        $SqlAdapter.Fill($DataSet)
        $DataSet.Tables[0] | `
        Select-Object @{Name = 'Hostname'; Expression= {$env:COMPUTERNAME}}, * -ExcludeProperty RowError,RowState,Table,ItemArray,HasErrors | `
        Export-Csv -Path "FileSystem::$FileName" -Force -Encoding UTF8 -NoTypeInformation
    } catch {
        $_.Exception.Message
    } finally {
        ## Close the connection when work done
        $DataSet.Dispose()
        $SqlAdapter.Dispose()
        $SqlCmd.Dispose()
        $SqlConnection.Close()
    }
}

#region check/stop transcript
if ( 1 -eq $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript