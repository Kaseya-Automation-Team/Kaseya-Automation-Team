<#
.Synopsis
   Gathers SQL Server Information and saves repot as an HTML-file.
.DESCRIPTION
   Gathers SQL Server Information

   General SQL Server properties
        -SQL Server Name
        -SQL Server Version
        -Edition
        -Machine Name
        -Node on which SQL Server is running.
    SQL Server Hardware Information
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
    SQL Server  Software Information
        - Operating System
        - Operating System Version
        - Hot Fixes
        - Roles And Features
        - Software
    SQL Server CPU information
        - logical, physical CPUs
        - hyperthread ratio
        - CPU Pressure
    SQL Server Memory Information
        - Memory allocated
        - Memory utilization
        - Memory Issues
    SQL Server Storage Info
    SQL Server Latency Info
    SQL Agent Service Status.
    Database State Information.
    Database Index Fragmentation
    SQL jobs failed in the last 24 hours.
    Database BackUps.
    SQL Server errors in the last 24 hours.
    Top 10 Memory Consuming SQL Objects
    Top 10 CPU Consuming Queries
    Top 10 IO Consuming Queries
    
.PARAMETERS
    [string] AgentName
        - ID of the VSA agent
    [string] OutputFilePath
        - Output HTML file name
    [string] SQLUser
        - User name. SQL User by default. In combination with the UseWindowsAuthentication key specifies Windows user
    [string] SQLPwd
        - User password. SQL User password by default. In combination with the UseWindowsAuthentication key specifies Windows user's password
    [string] SQLServer
        - Specifies SQL Server Name, Instance Name And Port: SERVER_NAME\INSTANCE_NAME,PORT_NUMBER. By default: localhost, default instance & default 1433 port are used.
    [switch] UseWindowsAuthentication
        - Enables Windows Authentication
    [switch] LogIt
        - Enables execution transcript		 
.EXAMPLE
    .\Gather-SQLServerInfo.ps1 -AgentName '12345' -SQLUser 'sa' -SQLPwd 'Your_Password' -OutputFilePath 'C:\TEMP\sql_info.html' -LogIt
    .\Gather-SQLServerInfo.ps1 -AgentName '12345' -SQLUser 'windows_user' -SQLPwd 'Your_Password' -UseWindowsAuthentication -OutputFilePath 'C:\TEMP\sql_info.html'
.NOTES
    Version 0.1
    Requires:
        SQL Server 2012 R2+
        Proper permissions to execute the script on SQL Server
   
    Author: Proserv Team - VS

#>
param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $AgentName,
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputFilePath,
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
            @{Name = 'FS Block Size'; Expression = { ($_.BlockSize / 1kb).ToString("0."+" KB") } },
            @{Name ='Size'; Expression = { [math]::Round($_.Capacity / 1gb, 1).ToString("0.0"+" GB")}},
            @{Name = 'Free'; Expression = { [math]::Round( $_.FreeSpace / $_.Capacity, 3 ).ToString("0.0"+" %")  } } | 
            ConvertTo-Html -Fragment
        $HTMLOutput += "<tr>
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

    foreach($server in $ComputerNames)
    {
        $array = @()
        $UninstallKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"

        #Create an instance of the Registry Object and open the HKLM base key

        $reg = [microsoft.win32.registrykey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $server)

        #Drill down into the Uninstall key using the OpenSubKey Method

        $regkey = $reg.OpenSubKey($UninstallKey) 

        #Retrieve an array of string that contain all the subkey names

        $subkeys = $regkey.GetSubKeyNames() 

        #Open each Subkey and use GetValue Method to return the required values for each

        foreach($key in $subkeys)
        {
            $thisKey = $UninstallKey+"\\"+$key
            $thisSubKey = $reg.OpenSubKey($thisKey)
            $hash = [ordered] @{
                    'Publisher'         = $($thisSubKey.GetValue("Publisher"))
                    'Display Name'      = $($thisSubKey.GetValue("DisplayName"))
                    'Display Version'   = $($thisSubKey.GetValue("DisplayVersion"))
                    'Install Location'  = $($thisSubKey.GetValue("InstallLocation"))
                    }
            $array += New-Object PSObject -Property $hash
        }
        $RolesFeatures = Get-CimInstance -query "select Caption from win32_optionalfeature where installstate= 1" | `
                            Select-Object @{Name = 'Display Name'; Expression = {$_.Caption}} | ConvertTo-Html -Fragment
        $SoftwareInstalled = $array | Where-Object { $_.'Display Name' } | ConvertTo-Html -Fragment

        $HotFixes = (Get-CimInstance -ComputerName $server -ClassName Win32_QuickFixEngineering -Property HotFixID | Select-Object -ExpandProperty HotFixID) -join '<br/>'
        $OSInfo = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption

        $HTMLOutput += "<tr>
    <td>$OSInfo</td>
    <td>$HotFixes</td>
    <td>$RolesFeatures</td>
    <td>$SoftwareInstalled</td>
    </tr>"
    #
    }
    return $HTMLOutput
}
#endregion Software Info

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

[string] $HardwareInfo = Get-HardwareInfoAsHTML -ComputerNames $env:COMPUTERNAME

[string] $SoftwareInfo = Get-SoftwareInfoAsHTML -ComputerNames $env:COMPUTERNAME

[string] $ConnectionString = $ConnectionParameters -join ';'

[scriptblock] $ScriptBlock = {

#region Sql Server Info
[string] $QuerySqlServerInfo = @'
SELECT @@servername as [SQLNetworkName], 
CAST( SERVERPROPERTY('MachineName') AS NVARCHAR(128)) AS [Machine Name],
CAST( SERVERPROPERTY('ServerName')AS NVARCHAR(128)) AS [SQL Server Name],
CASE
    WHEN 
        SERVERPROPERTY('IsClustered') = 0
            THEN 'Not Clustered'
            ELSE 'Clustered'
END AS [Is Clustered],
CAST( SERVERPROPERTY('ComputerNamePhysicalNetBIOS')AS NVARCHAR(128)) AS [SQL Service Current Node],
serverproperty('edition') as [Edition],
serverproperty('productlevel') as [Service Pack],
CAST( SERVERPROPERTY('InstanceName') AS NVARCHAR(128)) AS [Instance Name],
SERVERPROPERTY('Productversion') AS [Product Version],@@version as [Server Version]
'@
#endregion Sql Server Info

#region Server CPU Info
[string] $QueryCPUInformation = @'
SELECT cpu_count AS [Logical CPU Count], 
hyperthread_ratio AS [Hyperthread Ratio],
            cpu_count/hyperthread_ratio AS [Physical CPU Count],
            physical_memory_kb/1024/1024 AS [Physical Memory, MB]
            FROM sys.dm_os_sys_info
'@
#endregion Server CPU Info

#region Server CPU Pressure
[string] $QueryCPUPressure = @'
SELECT CAST(100.0 * SUM(signal_wait_time_ms) / 
SUM (wait_time_ms) AS NUMERIC(20,2)) AS [Signal CPU Waits, %],
'Signal CPU Waits > 15% means CPU pressure' as Comment,
CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / 
SUM (wait_time_ms) AS NUMERIC(20,2)) AS [Resource Waits, %]
FROM sys.dm_os_wait_stats
'@
#endregion Server CPU Pressure

#region SQL Memory Allocated
[string] $QueryMemoryAllocated = @'
SELECT --object_name,
counter_name as Counter, cntr_value/1024 as [Memory Limit Set, Mb]
FROM sys.dm_os_performance_counters
WHERE counter_name IN ('Total Server Memory (KB)', 'Target Server Memory (KB)');
'@
#endregion SQL Memory Allocated

#region SQL Memory Utilization by Database
[string] $QueryMemoryUtilization = @'
DECLARE @total_buffer INT;

SELECT @total_buffer = cntr_value
FROM sys.dm_os_performance_counters 
WHERE RTRIM([object_name]) LIKE '%Buffer Manager'
AND counter_name = 'Database Pages';

;WITH src AS
(
  SELECT 
  database_id, db_buffer_pages = COUNT_BIG(*)
  FROM sys.dm_os_buffer_descriptors
  --WHERE database_id BETWEEN 5 AND 32766
  GROUP BY database_id
)
SELECT
[Database Name] = CASE [database_id] WHEN 32767 
THEN 'Resource DB' 
ELSE DB_NAME([database_id]) END,
db_buffer_pages AS [Database Buffer Pages],
[Database Buffer, MB] = db_buffer_pages / 128,
[Database Buffer, %]  = CONVERT(DECIMAL(6,3), 
db_buffer_pages * 100.0 / @total_buffer)
FROM src
ORDER BY [Database Buffer, MB] DESC;
'@
#endregion SQL Memory Utilization by Database

#region SQL Memory Issues
[string] $QueryMemoryIssues = @'
DECLARE @bufferpool_allocated BIGINT;
DECLARE @totalmemoryused BIGINT;

SELECT @totalmemoryused = SUM(pages_kb+virtual_memory_committed_kb+awe_allocated_kb)/1024 FROM sys.dm_os_memory_clerks

SELECT @bufferpool_allocated = cntr_value/1024
FROM sys.dm_os_performance_counters
WHERE counter_name IN ('Target Server Memory (KB)')

IF (@bufferpool_allocated > @totalmemoryused)
    BEGIN
        SELECT 'No Memory Issues Detected' as Comments
    END 
ELSE 
    BEGIN 
        SELECT 'Server Might Have Memory Issues' as Comments
    END
'@
#endregion SQL Memory Issues

#region Database Storage Info
[string] $QueryDBStorage = @'
DECLARE @SQL VARCHAR(5000) 
SELECT @SQL =    
'USE [?]    
SELECT DB_NAME(),   
[name] AS [File Name],    
physical_name AS [Physical Name],    
[File Type] =    
CASE type   
WHEN 0 THEN ''Data'''    
+   
           'WHEN 1 THEN ''Log'''   
+   
       'END,   
[Total Size in Mb] =   
CASE ceiling([size]/128)    
WHEN 0 THEN 1   
ELSE ceiling([size]/128)   
END,   
[Available Space in Mb] =    
CASE ceiling([size]/128)   
WHEN 0 THEN (1 - CAST(FILEPROPERTY([name], ''SpaceUsed''' + ') as int) /128)   
ELSE (([size]/128) - CAST(FILEPROPERTY([name], ''SpaceUsed''' + ') as int) /128)   
END,   
[Growth Units]  =    
CASE [is_percent_growth]    
WHEN 1 THEN CAST(growth AS varchar(20)) + ''%'''   
+   
           'ELSE CAST(growth*8/1024 AS varchar(20)) + ''Mb'''   
+   
       'END,   
[Max File Size in Mb] =    
CASE [max_size]   
WHEN -1 THEN NULL   
WHEN 268435456 THEN NULL   
ELSE [max_size]   
END   
FROM sys.database_files   
ORDER BY [File Type], [file_id]'   

--Run the command against each database
DECLARE @DbInfo TABLE ([Database Name] sysname, 
[File Name] sysname, 
[Physical Name] NVARCHAR(260),
[File Type] VARCHAR(4), 
[Total Size in Mb] INT, 
[Available Space in Mb] INT, 
[Growth Units] VARCHAR(15), 
[Max File Size in Mb] INT)

INSERT INTO @DbInfo EXEC sp_MSforeachdb @SQL

--Return the Results   
SELECT [Database Name],   
    [File Name],
    [Physical Name],
    [File Type],
    [Total Size in Mb] AS [DB Size (Mb)],
    [Available Space in Mb] AS [DB Free (Mb)],
    CEILING(CAST([Available Space in Mb] AS decimal(10,1)) / [Total Size in Mb]*100) AS [Free Space %],
    [Growth Units],   
    [Max File Size in Mb] AS [Grow Max Size (Mb)]    
FROM @DbInfo
'@
#endregion Database Storage Info

#region Database Latency Info
[string] $QueryDBLatency = @'
SELECT
DB_NAME ([vfs].[database_id]) AS [Database Name],
[mf].[physical_name] AS [Physical Name],
[Read Latency] =
CASE WHEN [num_of_reads] = 0
THEN 0 ELSE ([io_stall_read_ms] / [num_of_reads]) END,
[Write Latency] =
CASE WHEN [num_of_writes] = 0
THEN 0 ELSE ([io_stall_write_ms] / [num_of_writes]) END,
[Latency] =
CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
THEN 0 ELSE ([io_stall] / ([num_of_reads] + [num_of_writes])) END,
[Avg Bytes Per Read] =
CASE WHEN [num_of_reads] = 0
THEN 0 ELSE ([num_of_bytes_read] / [num_of_reads]) END,
[Avg Bytes Per Write] =
CASE WHEN [num_of_writes] = 0
THEN 0 ELSE ([num_of_bytes_written] / [num_of_writes]) END,
[Avg Bytes Per Transfer] =
CASE WHEN ([num_of_reads] = 0 AND [num_of_writes] = 0)
THEN 0 ELSE
(([num_of_bytes_read] + [num_of_bytes_written]) /
([num_of_reads] + [num_of_writes])) END
FROM
sys.dm_io_virtual_file_stats (NULL,NULL) AS [vfs]
JOIN sys.master_files AS [mf]
ON [vfs].[database_id] = [mf].[database_id]
AND [vfs].[file_id] = [mf].[file_id]
-- WHERE [vfs].[file_id] = 2 -- log files
-- ORDER BY [Latency] DESC
-- ORDER BY [Read Latency] DESC
ORDER BY [Write Latency] DESC;
'@
#endregion Database Latency Info

#region Query Index Fragmentation
[string] $QueryIndexFragmentation= @'
DECLARE @INDEXFRAGINFO TABLE (
DatabaseName nvarchar(128),
DatabaseID smallint,
TableName nvarchar(384),
IndexID INT, 
IndexName nvarchar(128), 
IndexType nvarchar(60), 
IndexDepth tinyint,
IndexLevel tinyint,
[Fragmentation, %] tinyint, 
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
ROUND(i.avg_fragmentation_in_percent, 0) AS [Fragmentation, %], 
i.fragment_count AS FragmentCount
FROM (
SELECT *, DENSE_RANK() OVER(PARTITION by database_id ORDER BY avg_fragmentation_in_percent DESC) as rnk
from sys.dm_db_index_physical_stats(DB_ID(), default, default, default,'+ '''' + 'limited' + '''' +')
where avg_fragmentation_in_percent >0 AND 
INDEX_ID > 0 AND 
Page_Count > 500 
) as i
join sys.indexes o on o.object_id = i.object_id and o.index_id = i.index_id
order by i.database_id, [Fragmentation, %];'

INSERT @INDEXFRAGINFO EXEC sp_MSForEachDB @command 

SELECT * FROM @INDEXFRAGINFO
WHERE DatabaseID > 4 AND [Fragmentation, %] > 20
ORDER BY [Fragmentation, %] DESC;
'@
#endregion Query Index Fragmentation

#region Query Agent Status
[string]$QueryServerAgent = @'
DECLARE @sql_agent_service varchar(128),@state_sql_agent varchar(20)
DECLARE @SQL_AGENT_STATE AS TABLE (service_name varchar(128) default 'SQLAgent ', state varchar(20))
INSERT INTO  @SQL_AGENT_STATE(state) EXEC xp_servicecontrol N'querystate',N'SQLServerAGENT'
SELECT service_name AS [Service Name], replace(state,'.','') AS [Status] from  @SQL_AGENT_STATE
'@
#endregion Query Agent Status

#region Query Database State
[string] $QueryDatabaseState = @'
DECLARE @count int
DECLARE @dbname varchar(128)
DECLARE @state_desc varchar(128)

DECLARE @TMP_DATABASE AS TABLE (dbname nvarchar(128),state_desc nvarchar(128))
DECLARE Cur1 cursor FOR
	SELECT name,state_desc
	FROM sys.databases
OPEN Cur1
    FETCH NEXT FROM Cur1 INTO @dbname,@state_desc
    WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO @TMP_DATABASE values(@dbname,@state_desc)
        FETCH NEXT FROM Cur1 INTO @dbname,@state_desc
        END
    CLOSE Cur1
    DEALLOCATE Cur1

SELECT dbname AS [Database] ,state_desc AS [State] FROM @TMP_DATABASE
'@
#endregion Query Database State

#region Query Database Backup
[string] $QueryDatabaseBackup = @'
SELECT db.Name AS [Database Name],
COALESCE(CONVERT(VARCHAR(19), MAX(bs.backup_finish_date), 120),'Never') AS [The Last BackUp]
FROM sys.sysdatabases db
        LEFT OUTER JOIN msdb.dbo.backupset bs 
     ON bs.database_name = db.name
GROUP BY db.Name
ORDER BY [The Last BackUp]
'@
#endregion Query Database Backup

#region SQL Failed Jobs
[string] $QueryFailedJobs = @'
DECLARE @count int
SELECT @count = count(1) FROM msdb.dbo.sysjobs AS sj 
JOIN msdb.dbo.sysjobhistory AS sjh ON sj.job_id = sjh.job_id 
WHERE sj.enabled != 0 
AND sjh.sql_message_id > 0 
AND sjh.run_date > CONVERT(char(8), (SELECT dateadd (day,(-1), getdate())), 112)
AND sjh.Step_id <= 1

IF (@count >= 1)
BEGIN
    SELECT DISTINCT sj.name AS [SQL Job Name]
    FROM msdb.dbo.sysjobs AS sj 
    JOIN msdb.dbo.sysjobhistory AS sjh ON sj.job_id = sjh.job_id 
    WHERE sj.enabled != 0 
    AND sjh.sql_message_id > 0 
    AND sjh.run_date > CONVERT(char(8), (SELECT dateadd (day,(-1), getdate())), 112)
    AND sjh.Step_id <= 1
    ORDER BY name
END
ELSE 
BEGIN
    SELECT 'No Job Failed In The Last 24 Hours' AS [SQL Job Name]
END
'@
#endregion SQL Failed Jobs

#region SQL Server Errors
[string] $QuerySQLErrors = @'
DECLARE @errorlogcount INT
DECLARE @errorlog AS TABLE (date_time datetime,processinfo varchar(123),Comments varchar(max))
INSERT INTO @errorlog EXEC sp_readerrorlog

SELECT @errorlogcount = count(*) FROM @errorlog 
WHERE date_time > (CONVERT(datetime,getdate()) - 0.5)
AND Comments LIKE '%fail%' 
AND Comments LIKE '%error%'
AND processinfo not in ('Server','Logon')

IF(@errorlogcount >= 1)
	BEGIN
		SELECT date_time AS [Date], processinfo AS [Process Info], Comments
		FROM @errorlog
		WHERE date_time > (CONVERT(datetime,getdate()) - 0.5)
		AND Comments LIKE '%fail%' 
		AND Comments LIKE '%error%'
		AND processinfo NOT IN ('Server','Logon')
	END
ELSE
	BEGIN
		SELECT 'Error Log' AS [Source], 'Major Issues Not Detected' 
		AS [Info], 'Please Consider Manual Verification' AS Comments
	END
'@
#endregion SQL Server Errors

#region Top 10 Memory Consuming Objects
[string] $QueryTopMemoryObjects = @'
SELECT top 10 type as Object,
SUM(pages_kb+virtual_memory_committed_kb+awe_allocated_kb)/1024 AS [Memory Used, MB]
FROM sys.dm_os_memory_clerks 
GROUP BY type
ORDER BY 2 desc
'@
#endregion Top 10 Memory Consuming Objects

#region Top 10 CPU Consuming Queries
[string] $QueryTopCPUQueries = @'
SELECT TOP 10 DB_NAME(qt.dbid) AS [Database Name],
    o.name AS ObjectName,
    qs.total_worker_time / 1000000 / qs.execution_count AS [Avg MultiCore CPU time, sec],
    qs.total_worker_time / 1000000 AS [Total MultiCore CPU time, sec],
    qs.total_elapsed_time / 1000000 / qs.execution_count AS [Average, sec],
    qs.total_elapsed_time / 1000000 AS [Total, sec],
    (total_logical_reads + total_logical_writes) / qs.execution_count AS [Average IO],
    total_logical_reads + total_logical_writes AS [Total IO],    
    qs.execution_count AS Count,
    qs.last_execution_time AS Time,
    SUBSTRING(qt.[text], (qs.statement_start_offset / 2) + 1,
        (
            (
                CASE qs.statement_end_offset
                    WHEN -1 THEN DATALENGTH(qt.[text])
                    ELSE qs.statement_end_offset
                END - qs.statement_start_offset
            ) / 2
        ) + 1
    ) AS Query
    --,qt.text
    --,qp.query_plan
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.[sql_handle]) AS qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
LEFT OUTER JOIN sys.objects o ON qt.objectid = o.object_id
WHERE qs.execution_count > 5    --more than 5 occurrences
ORDER BY [Total MultiCore CPU time, sec] DESC
'@
#endregion Top 10 CPU Consuming Queries

#region Top 10 IO Consuming Queries
[string] $QueryTopIOQueries = @'
SELECT TOP 10 DB_NAME(qt.dbid) AS DBName,
o.name AS [Object Name],
qs.total_elapsed_time / 1000000 / qs.execution_count AS [Average, sec],
qs.total_elapsed_time / 1000000 AS [Total, sec],
(total_logical_reads + total_logical_writes ) / qs.execution_count AS [Average IO],
(total_logical_reads + total_logical_writes ) AS [Total IO],
qs.execution_count AS Count,
last_execution_time AS Time,
SUBSTRING (qt.text,qs.statement_start_offset/2,
(CASE
	WHEN qs.statement_end_offset = -1
		THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
	ELSE qs.statement_end_offset
	END - qs.statement_start_offset)/2) AS Query
--,qt.text
--,qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
LEFT OUTER JOIN sys.objects o ON qt.objectid = o.object_id
WHERE last_execution_time > getdate()-1
ORDER BY [Average IO] DESC
'@
#endregion Top 10 IO Consuming Queries

#region Get-QueryResultAsHtml    
    function Get-QueryResultAsHtml
    {
        [CmdletBinding()]
        [OutputType([string])]
        Param
        (
            [Parameter(Mandatory=$true,
                       ValueFromPipelineByPropertyName=$true,
                       Position=0)]
            [System.Data.SqlClient.SqlConnection]
            $Connection,
            [Parameter(Mandatory=$true,
                       ValueFromPipelineByPropertyName=$true,
                       Position=1)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Query
        )
    
        #creating command object
        [System.Data.SqlClient.SqlCommand] $SqlCmd = $SqlConnection.CreateCommand()
        $SqlCmd.CommandText = $Query
        $SqlCmd.Connection = $SqlConnection  
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
            $DataSet.Tables[0] | `
            Select-Object * -ExcludeProperty RowError,RowState,Table,ItemArray,HasErrors | ConvertTo-Html | Write-Output
        }
        $DataSet.Dispose()
        $SqlAdapter.Dispose()
        $SqlCmd.Dispose()
    }
#endregion Get-QueryResultAsHtml

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
        [string] $SqlServerInfo = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QuerySqlServerInfo        
        [string] $AgentStatus = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryServerAgent
        [string] $DatabaseState = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryDatabaseState
        [string] $CPUInformation = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryCPUInformation
        [string] $CPUPressure = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryCPUPressure
        [string] $MemoryAllocated = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryMemoryAllocated
        [string] $MemoryUtilization = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryMemoryUtilization 
        [string] $MemoryIssues = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryMemoryIssues
        [string] $DBStorage = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryDBStorage
        [string] $DBLatency = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryDBLatency
        [string] $IndexFragmentation = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryIndexFragmentation
        
        [string] $FailedJobs = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryFailedJobs
        [string] $DatabaseBackup = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryDatabaseBackup
        [string] $SQLErrors = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QuerySQLErrors
        [string] $TopMemoryObjects = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryTopMemoryObjects
        [string] $TopCPUQueries = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryTopCPUQueries
        [string] $TopIOQueries = Get-QueryResultAsHtml -Connection $SqlConnection -Query $QueryTopIOQueries

        ## Close the connection when work done
        $SqlConnection.Close()
        $SqlConnection.State | Write-Verbose
    }
#Output HTML
@"
<!DOCTYPE html>
  <head>
  <title>SQL Server Information</title>
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
  <h1>SQL Server Information: $env:COMPUTERNAME </h1>
  <h3>Collected on $(Get-Date -UFormat "%m/%d/%Y %T")</h3>
  <h2>SQL Server properties</h2> 
  $SqlServerInfo
  <br/>
  <h2>SQL Server Hardware Information</h2> 
  <table>
  <tr>
    <td><h3>Manufacturer</h3></td>
    <td><h3>Model</h3></td>
    <td><h3>RAM</h3></td>
    <td><h3>CPU</h3></td>
    <td><h3>Drives</h3></td>
  </tr>
  $($args[1])
  </table>
    <h2>SQL Server Software Information</h2> 
  <table>
  <tr>
    <td><h3>OperatingSystem</h3></td>
    <td><h3>Hot Fixes</h3></td>
    <td><h3>Roles And Features</h3></td>
    <td><h3>Software</h3></td>
  </tr>
  $($args[2])
  </table>
  <h2>SQL Server CPU Info</h2> 
  <table>
  $CPUInformation
  </table>
  <h2>SQL Server CPU Pressure</h2> 
  <table>
  $CPUPressure
  </table>
  <h2>SQL Server Memory Info</h2> 
  <table>
  $MemoryAllocated
  </table>
  <h2>SQL Server Memory Utilization By Database</h2> 
  <table>
  $MemoryUtilization
  </table>
  <h2>SQL Server Memory Issues</h2> 
  <table>
  $MemoryIssues
  </table>
  <h2>Database Storage Info</h2> 
  <table>
  $DBStorage
  </table>
  <h2>Database Latency Info</h2> 
  <table>
  $DBLatency
  </table>
  <h2>Agent Status</h2> 
  <table>
  $AgentStatus
  </table>
  <h2>Database State</h2> 
  <table>
  $DatabaseState
  </table>

  <h2>Index Fragmentation</h2> 
  <table>
  $IndexFragmentation
  </table>

  <h2>Failed Jobs In The Last 24 Hours</h2> 
  <table>
  $FailedJobs
  </table>
  <h2>Database BackUp</h2> 
  <table>
  $DatabaseBackup
  </table>
  <h2>SQL Server Errors In The Last 24 Hours</h2> 
  <table>
  $SQLErrors
  </table>
  <h2>SQL Server Top 10 Memory Consuming Objects</h2> 
  <table>
  $TopMemoryObjects
  </table>
  <h2>SQL Server Top 10 CPU Consuming Queries</h2> 
  <table>
  $TopCPUQueries
  </table>
  <h2>SQL Server Top 10 IO Consuming Queries</h2> 
  <table>
  $TopIOQueries
  </table>
"@ | Write-Output
}

$InvokeParameters = @{
ScriptBlock = $ScriptBlock
Args = @($ConnectionString, $HardwareInfo, $SoftwareInfo)
}

if ($UseWindowsAuthentication)
{
    'Windows Athentication' | Write-Debug
    [securestring] $SecurePassword = ConvertTo-SecureString $SQLPwd -AsPlainText -Force
    [pscredential] $Credential = New-Object System.Management.Automation.PSCredential ($SQLUser, $SecurePassword)

    $InvokeParameters.Add('Credential', $Credential)
    $InvokeParameters.Add('ComputerName', $env:COMPUTERNAME)
}

[string] $Create_HTML_doc = Invoke-Command @InvokeParameters

$Create_HTML_doc | Out-File -FilePath "FileSystem::$OutputFilePath" -Force -Encoding UTF8

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