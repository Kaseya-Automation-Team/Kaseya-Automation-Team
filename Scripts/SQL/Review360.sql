-- THE REVIEW 360 QUERY LIST

-- VSA Out of Date
SELECT CASE WHEN (SELECT tempValue as Installed_Patch_Level FROM dbo.tempData WHERE tempName = 'KaseyaSystemPatch') != (SELECT tempValue as Available_Patch_Level FROM dbo.tempData WHERE tempName = 'KaseyaPatchLevel') THEN CONCAT('PROBLEM: Out of date (Current: ',(SELECT tempValue as Installed_Patch_Level FROM dbo.tempData WHERE tempName = 'KaseyaSystemPatch')) ELSE CONCAT('GOOD: Up to date (',(SELECT tempValue as Installed_Patch_Level FROM dbo.tempData WHERE tempName = 'KaseyaSystemPatch'),')') END AS 'VSA Patch Level'

-- Unread System Notifications Older Than 7 Days
SELECT CASE WHEN COUNT(*) = 0 THEN 'GOOD: None' ELSE CONCAT('PROBLEM: ',COUNT(*),' unread notifications') END AS 'Unread System Notifications' FROM [kcache].[fn_GetNotificationsForUser](
	(
		SELECT TOP 1 a.adminId FROM appSession a
		INNER JOIN adminIdTab b ON a.adminId = b.adminId
		INNER JOIN roleToAdmin c ON b.adminId = c.adminId
		WHERE (c.RoleName = 'Master' or c.RoleName = 'System')
		AND a.partitionid = 1
		ORDER BY b.adminId
	)
)
WHERE CreationDate <  DATEADD(DAY, -7, getDate()) AND Isread != 1

-- TODO: Unread Message Notifications Older Than 7 Days -- DONE
-- Sarath Notes: The query you provided is wrong, we need to find just messages that are unread here (basically the info center messages that get sent into the  "MESSAGE" section

SELECT	CASE WHEN COUNT(*) = 0 THEN 'GOOD: None' ELSE CONCAT('PROBLEM: ',COUNT(*),' unread messages') END AS 'Unread Messages'
FROM dbo.Messages ms 
	INNER JOIN dbo.MessageRecipient mr ON ms.ID = mr.MessageFK 
	INNER JOIN dbo.PartnerUser p2 ON mr.TOFK = p2.ID 
	INNER JOIN dbo.PartnerUser p1 ON mr.FROMFK = p1.ID
WHERE mr.unRead = 'Y' AND ms.created < DATEADD(DAY, -7, getDate())

-- Database/Log Size
SELECT a.name AS 'Database Info', CONCAT(CAST(b.size/128.0 AS DECIMAL(10,1)),' MB') AS 'Size'
FROM sys.master_files a 
LEFT OUTER JOIN sys.database_files b ON a.name = b.name 
WHERE DB_NAME(a.database_id) like 'ksubscribers%'

-- Database Settings 
SELECT name as Setting, value as Value 
FROM sys.configurations  
WHERE name LIKE '%server memory%' OR configuration_id = 1539 OR configuration_id=1548 

-- DB Backup Misconfigured
SELECT CASE WHEN dbBackupPath IS NULL THEN 'PROBLEM: Missing path' ELSE CONCAT('GOOD: ',dbBackupPath) END AS 'DB Backup Path'
FROM siteParams

-- DB Backup Frequency
SELECT CASE WHEN ISNULL(dbMaintPeriod,7) = 0 THEN 'PROBLEM: Disabled' WHEN ISNULL(dbMaintPeriod,7) > 7 THEN CONCAT('PROBLEM: Length(', ISNULL(dbMaintPeriod,7),' days) too long') ELSE CONCAT('GOOD: ',CAST(ISNULL(dbMaintPeriod,7) AS VARCHAR(max)),' days') END AS 'DB Backup Frequency (days)'
FROM serverInfo 
WHERE servername IN (SELECT servername FROM siteparams) 

-- Log Archiving Misconfigured
SELECT CASE WHEN logFileArchPath IS NULL THEN 'PROBLEM: Missing path' ELSE CONCAT('GOOD: ',logFileArchPath) END AS 'Log Archive Path'
FROM siteparams

-- Multiple Databases
SELECT CASE WHEN COUNT(*) = 0 THEN CAST(COUNT(*) AS VARCHAR(max)) ELSE CONCAT('PROBLEM: ',COUNT(*),' additional databases') END AS 'Additional Databases'
FROM sys.databases 
WHERE name NOT IN ('kapps','KLCAuditReporting','ksubscribers','master','model','msdb','ReportServer','ReportServerTempDB','tempdb')

-- AD User Percentage
SELECT CASE WHEN CAST(count(adminName) * 100 / (select count(*) from administrators WHERE partitionStr = 1) AS DECIMAL(10,0)) < 50 THEN CONCAT('PROBLEM: ',CAST(count(adminName) * 100.0 / (select count(*) from administrators) AS DECIMAL(10,0)),'% AD users') ELSE CONCAT(CAST(count(adminName) * 100.0 / (select count(*) from administrators WHERE partitionStr = 1) AS DECIMAL(10,0)),'% AD users') END AS 'Percentage of AD Users' 
FROM administrators 
WHERE adminName LIKE '%/%' 
AND partitionStr = 1

-- Disabled Users
select CASE WHEN COUNT(*) = 0 THEN CONCAT('GOOD: ',COUNT(*),' Disabled users') ELSE CONCAT('PROBLEM: ',COUNT(*),' Disabled users') END AS 'Disabled Users'
FROM administrators 
WHERE disableUntil = '2100-01-01 00:00:00.000' 
AND partitionStr = 1

-- TODO: Logon Policy Query -- DONE
-- Sarath Notes: We basically need queries for each of the settings on the page, then I can combine them.

SELECT failedLoginCount,(disableAcctTime/60) as disableAcctTime,(sessionPeriod/60) as sessionPeriod , blockNameChange,noDomainLogon,
		noRememberme,Passchange, minPassLength, passReuseCnt,mixedCase,alphaNum,nonAlphaNum,MFARMDays
FROM dbo.siteParams

SELECT FORMAT(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM administrators WHERE partitionStr = '1'),'N2') AS 'Enrollment Participation'
FROM MultiFactorAuthentication

SELECT a.adminName, m.Enrolled FROM administrators a
JOIN MultiFactorAuthentication m ON a.adminName = m.AdminName
WHERE partitionStr = '1'

SELECT adminName,RememberDevice FROM MultiFactorAuthenticationDevice
WHERE partitionId = 1 AND RememberDevice = 1


-- Master Role Percentage
select CASE WHEN CAST(COUNT(adminName) * 100 / (select count(*) from administrators where partitionStr = '1') AS DECIMAL(10,0)) > 50 THEN CONCAT('PROBLEM: ',CAST(COUNT(adminName) * 100 / (select count(*) from administrators where partitionStr = '1') AS DECIMAL(10,0)),'%') ELSE CONCAT('GOOD: ',CAST(COUNT(adminName) * 100 / (select count(*) from administrators where partitionStr = '1') AS DECIMAL(10,0)),'%') END AS 'Percentage of Master Users' 
from administrators a 
join adminGroup b on a.defaultAdminGroupId = b.adminGroupId 
where (b.adminGroupName = 'Master' or b.adminGroupName = 'System')
and a.partitionStr = 1

-- TODO: Naming Policy Query -- DONE
-- Sarath Notes: We basically need a query to check % of machine groups that have ANYHTING configured. Basically if a machine group has naming policy configured, it SHOULDNT have discovery scans happening

SELECT FORMAT(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM machGroup WHERE partitionId = 1),'N2') FROM namePolicy

SELECT groupID, connectionGatewayIp,minIp,maxIp,forceCompName FROM namePolicy

-- Organization Review
SELECT a.ref AS 'Organization',(SELECT COUNT(*) FROM machNameTab b LEFT JOIN machGroup c ON b.machGroupGuid = c.machGroupGuid WHERE c.orgFK = a.orgRootFK AND b.partitionId = 1 AND c.partitionId = 1) AS 'Agents'
FROM kasadmin.org a
WHERE a.partitionid = 1

-- SSRS Config
SELECT CASE WHEN UseKReportingServer = 1 THEN 'PROBLEM: Kaseya Reporting Services enabled' WHEN reportServicesUrl IS NOT NULL THEN 'GOOD: SSRS configured' ELSE 'PROBLEM: Reporting not configured' END AS 'SSRS Configuration'
FROM SiteParams

-- TODO: License Review Query
-- Sarath Notes: 

-- TODO: Admin Log Retention Query  -- DONE
SELECT CASE WHEN Count(*) = 0 THEN 'PROBLEM: Admin log retention not set' WHEN tempValue = 0 THEN 'PROBLEM: Admin log retention not set' ELSE CONCAT('GOOD: Admin log retention set to ',tempValue,' days') END AS 'Admin Log Retention Settings'
FROM tempData 
WHERE tempName = 'sysLogMaxAge'
GROUP BY tempValue

-- TODO: Application Log Enablement Query
-- Sarath Notes: Let's ask support?

-- Outbound Email Status
SELECT CASE WHEN count(eventid) = 0 THEN 'PROBLEM: Outbound email disabled' ELSE 'GOOD: Outbound email enabled' END AS 'Outbound Email Configuration'
FROM Hermes.Event WHERE EventDesc='Mail Sender Daemon'

-- Outbound Email Queue
SELECT CASE WHEN count(*) > 0 THEN CONCAT('PROBLEM: ',COUNT(*), ' pending emails') ELSE CONCAT('GOOD: ',COUNT(*), ' pending emails') END AS 'Outbound Email Queue'
FROM email 
WHERE sendStatus = 0 and created < dateAdd(DAY, -1, getDate()) 

-- Longtime Offline Agents
SELECT CASE WHEN CAST(count(m.machName) * 100 / (select count(*) from agentState b INNER JOIN machnametab c ON b.agentGuid = c.agentGuid WHERE c.partitionId = 1) AS DECIMAL(10,0)) = 0 THEN 'GOOD: No agents offline for more than 7 days' ELSE CONCAT('PROBLEM: ',CAST(count(m.machName) * 100 / (select count(*) from agentState b INNER JOIN machnametab c ON b.agentGuid = c.agentGuid WHERE c.partitionId = 1) AS DECIMAL(10,0)),'% of agents offline for over 7 days') END AS 'Offline Agents Over 7 Days'
FROM machNameTab m 
JOIN agentState a ON a.agentGuid = m.agentGuid 
WHERE a.online = 0 AND a.offlineTime < DATEADD (day,-7,getDate())
AND partitionId = 1

-- Column Sets Configured
SELECT CASE WHEN count(columnSetName) = 0 THEN 'PROBLEM: No column sets configured' ELSE CONCAT('GOOD: ',count(columnSetName),' column sets configured' ) END AS 'Column Sets Configured'
FROM columnSet 

-- Credential Tests Pending/Failed
SELECT CASE WHEN COUNT(*) * 100 / (SELECT count(*) FROM machnameTab c WHERE c.partitionid = 1) > 0 THEN CONCAT('PROBLEM: ',COUNT(*) * 100 / (SELECT count(*) FROM machnameTab c WHERE c.partitionid = 1),'% of agents have failed/ending credential tests') ELSE 'GOOD: No pending/failed credential tests' END AS 'Credential Test Pending/Failed'
FROM credential a
LEFT JOIN machnametab b ON a.agentguid = b.agentGuid 
WHERE (testStatus = 1 or testStatus = 0)
AND b.partitionid = 1

-- TODO: Percentage of Credentials Set By Policy  -- DONE
-- Sarath Notes: the query you submitted seems wrong, i see no check that validates that the setting you are looking at is credentials, can you confirm?

--policyObjectTypeFK = 1 indicates the Credentials object.

--we can join another table called policy.policyObjectType. But it is not neccessary as we know what '1' stands for.

-- Out-Of-Date Agents
SELECT CASE WHEN CAST(count(u.agentVersion) * 100 / (SELECT count(*) FROM machnameTab c WHERE c.partitionId = 1) AS DECIMAL(10,0)) = 0 THEN 'GOOD: No Agents Out of Date' ELSE CONCAT('PROBLEM: ',CAST(count(u.agentVersion) * 100 / (SELECT count(*) FROM machnameTab c WHERE c.partitionId = 1) AS DECIMAL(10,0)),'% of agents are out of date') END AS 'Agents Out of Date'
FROM users u 
JOIN agentState a ON a.agentGuid = u.agentGuid 
JOIN machnametab d ON a.agentGuid = d.agentGuid
WHERE u.agentVersion < (SELECT agentVersion FROM siteParams)
AND d.partitionId = 1

-- Automatic Update Enabled
SELECT CASE WHEN [isAutomaticUpdate] = 1 THEN 'GOOD: Automatic update enabled' ELSE 'PROBLEM: Automatic update disabled' END AS 'Automatic Update'
FROM [Agents].[AutoUpdateAgents] 

-- TODO: Log History Query -- DONE
-- Sarath Notes: the query should be returning the % of agents that have settings enabled, doesnt matcher which.
-- I didn't understand this fully. By default, every agent has some settings applied. So I wrote this query that pulls up all the settings that you see in Log History page.

SELECT ErrorLog, configLog, firewallLog, NetStatsLog, MaxLogAge, rcLogAge, krcLogAge, monitorActionLogAge, sysLogAge,  errorLogArchive, configLogArchive, alarmLogArchive, netStatsLogArchive, 
	scriptLogArchive, rcLogArchive, krcLogArchive, monitorActionLogArchive, sysLogArchive, agentSettingChange,doFullCheckin
FROM USERS

-- Event Log Collection
SELECT CASE WHEN count(distinct a.agentGuid) * 100 / (select count(*) from agentState c JOIN machnametab d ON c.agentGuid = d.agentGuid WHERE d.partitionId = 1) = 0 THEN 'GOOD: No event log collection occurring' ELSE CONCAT('PROBLEM: ',CAST(count(distinct a.agentGuid) * 100 / (select count(*) from agentState c JOIN machnametab d ON c.agentGuid = d.agentGuid WHERE d.partitionId = 1) AS DECIMAL(10,0)),'% of agents collecting event logs') END AS 'Agents Collecting Event Logs'
FROM [eventLogMachAssign] a 
JOIN machnametab b ON a.agentGuid = b.agentGuid
WHERE b.partitionId = 1

-- Shared Agent Packages
SELECT CAST((SELECT COUNT(*) FROM packageParams where showOnDl = 1 AND partitionId = 1) * 100 / count(*) AS DECIMAL(10,0))
FROM packageParams 
WHERE partitionId = 1

-- TODO: Agent Menu Configuration -- DONE
-- Sarath Notes: we just need a query that confirms how many agents are misconfigured (aka have different settings from majority) if you find me the table, i can do this.

SELECT agentGUID,contactUrl,urlMenuName,userWebServer,tooltipTitle,contactMenuItemName,enableMenuItems,agentSettingChange,dofullcheckin FROM users

-- TODO: CheckIn Control -- DONE
-- Sarath Notes: the checkin control servers should match the server settings (ip, domain) that are set in the serverinfo table, again if you find me the table, i can do this.

SELECT primaryKServer,KServerPort as PrimaryPort,secondaryKServer,secondaryKServerPort, kserverfastrevisit as CheckInPeriod,bwLimitKbytesPerSec,kserverBind FROM users

-- TODO: Script Distribution
-- Sarath Notes: if you look in the statistics.asp page, you could find the query for this.

-- TODO: Audit Credential Distribution -- DONE
-- Sarath Notes: we just need to confirm if there are credentials in these tables.

 SELECT [ManageCredentialsUsage] = CASE 
		WHEN COUNT(*) != 0 THEN CONCAT('Good: ',COUNT(*),' credetnails are set!')
		ELSE 'BAD: NO Credentials Set!' END
FROM assetCredential

-- Audit Schedule Distribution
SELECT CASE WHEN COUNT(DISTINCT agentguid) * 100 / (SELECT COUNT(*) FROM machNameTab WHERE partitionid = 1) < 100 THEN CONCAT('PROBLEM: Only ',COUNT(DISTINCT agentguid) * 100 / (SELECT COUNT(*) FROM machNameTab WHERE partitionid = 1),'% of agents have audits scheduled') ELSE 'GOOD: 100% of agents have audits scheduled' END AS 'Audit Schedule Distribution'
FROM (
	SELECT b.agentguid 
	FROM orgCalendarSchedule b
	WHERE b.scriptID in (135,136,137) 
	UNION
	SELECT c.agentguid
	FROM scriptassignment c
	WHERE c.scriptId in (135,136,137) 
) a

-- Audit via Policy
SELECT CASE WHEN count(distinct a.agentGuid) * 100 / (SELECT count(agentGuid) FROM machnametab WHERE partitionid = 1) < 100 THEN CONCAT('PROBLEM: Only ',count(distinct a.agentGuid) * 100 / (SELECT count(agentGuid) FROM machnametab WHERE partitionid = 1),'% of audits scheduled via policy.') ELSE 'GOOD: 100% of audits scheduled via policy' END AS 'Audit via Policy'
FROM policy.agentObject a 
join policy.policyObjectType b on a.policyObjectTypeFK = b.policyTypeFK 
WHERE b.ref = 'Audit Schedule' AND a.partitionid = 1

-- Discovery Scan Check
SELECT CASE WHEN COUNT(b.id) * 100 / (SELECT COUNT(*) FROM kasadmin.orgNetwork a WHERE a.partitionid = 1) < 100 THEN CONCAT('PROBLEM: ',COUNT(*) * 100 / (SELECT COUNT(*) FROM kasadmin.orgNetwork a WHERE a.partitionid = 1),'% of networks dont have scans scheduled') ELSE 'GOOD: 100% of networks have scans scheduled' END AS 'Network Scan Schedules'
FROM  kasadmin.orgNetworkSchedule b
WHERE b.scheduleFK != 0

-- Domain Watch Check
SELECT CASE WHEN count(*) = 0 THEN 'PROBLEM: No domains configured' ELSE CONCAT('GOOD: ',COUNT(*),' domains configured') END AS 'Domain Watch Config'
FROM kdsManagedDomains
WHERE partitionid = 1

-- Info Center Report Check
SELECT CASE WHEN COUNT(*) = 0 THEN 'PROBLEM: No reports scheduled' ELSE CONCAT('GOOD: ',COUNT(*),' reports configured') END AS 'Info Center Scheduling'
FROM ReportCenter.ScheduledItem 
WHERE partitionid = 1

-- TODO: Suspend Alarm Check -- DONE
-- Sarath Notes: we need a query that checks the # of agents with suspended alarms set

SELECT COUNT(*) AS #_Machines_Suspend_alarms FROM monitorSuspend

-- Unread Alarms
SELECT CASE WHEN COUNT(*) = 0 THEN 'GOOD: No alarms open older than 7 days' ELSE CONCAT('PROBLEM: ',COUNT(*),' alarms are open and older than 7 days') END AS 'Unread Alarms'
FROM [dbo].[monitorAlarm] a 
LEFT JOIN machnametab b ON a.agentguid = b.agentGuid
WHERE eventDateTime > DATEADD (DAY,7,GETDATE()) and monitorAlarmId = 1 AND b.partitionid = 1


-- Update List By Scan
SELECT CASE WHEN COUNT(*) = 0 THEN 'GOOD: Update list by scan not scheduled' ELSE CONCAT('PROBLEM: ',COUNT(*),' agents have update list by scan scheduled') END AS 'ULBS Scheduled'
FROM OrgCalendarSchedule 
WHERE scriptId = 199 AND partitionid = 1

-- TODO: Monitor Set Review -- DONE
-- Sarath Notes:  We basically need a query that determines the % of agents that have ANY monitor sets applied

SELECT FORMAT(COUNT(DISTINCT agentGuid) * 100.0 / (SELECT COUNT(*) FROM agentState),'N2') AS Machines_with_MonitorSets FROM monitorMachineParam

-- TODO: Agent Monitoring Review -- DONE
-- Sarath Notes: We basically need a query that determines the % of agents that have ANY monitor sets applied
-- Assuming it is Monitor > Alerts page settings. Can't help it that the query is too big as it checks from several tables. Couldn't find a view for it.

SELECT FORMAT(COUNT(distinct agentGUID) * 100.0 / (SELECT COUNT(*) FROM machNameTab),'N2') AS '%AgentsWithAlertsAssigned' FROM machNameTab
WHERE partitionid = 1 AND agentGuid in
(SELECT distinct agentGUID FROM alertAgentOffline
UNION
SELECT distinct agentGUID FROM alertNewApp
UNION
SELECT distinct agentGUID FROM alertAppExclude
UNION
SELECT distinct agentGUID FROM alertGetFile
UNION
SELECT distinct agentGUID FROM alertHwChange
UNION
SELECT distinct agentGUID FROM alertLowDisk
UNION
SELECT distinct agentGUID FROM alertNtEvent
UNION
SELECT distinct agentGUID FROM eventLogMachAssign
UNION
SELECT distinct agentGUID FROM alertLanWatch
UNION
SELECT distinct agentGUID FROM alertScriptFailed
UNION
SELECT distinct agentGUID FROM alertProtectViolation
UNION
SELECT distinct agentGUID FROM alertPatch
UNION
SELECT distinct agentGUID FROM alertBackup
)

-- New Agent Alert Check
SELECT CASE WHEN COUNT(groupId) * 100 / (SELECT COUNT(*) FROM machGroup WHERE partitionid = 1) < 100 THEN CONCAT('PROBLEM: Only ',COUNT(groupId) * 100 / (SELECT COUNT(*) FROM machGroup WHERE partitionid = 1)  ,'% of agents have new agent alert configured') ELSE 'GOOD: 100% of agents have new agent alerts configured' END AS 'New Agent Alerts'
FROM alertNewAgent 
WHERE partitionid = 1

-- TODO: System Alert Check -- DONE
-- Sarath Notes: we need to check if this is configured
--Assuming it is Monitor > Alerts > System

SELECT TOP 1 alertEmail,adminDisabled,kserverStopped, dbBackupFailed,emailReaderStopped FROM alertSystem

-- TODO: Event Log Monitoring Review -- DONE
-- Sarath Notes: We basically need a query that determines the % of agents that have ANY monitor sets applied

SELECT FORMAT(COUNT(DISTINCT agentGuid) * 100.0 / (SELECT COUNT(*) FROM machNameTab), 'N2') AS '%AgentsWithEventMonitoring' FROM alertNtEvent

-- Policy Deployment Interval
SELECT CASE WHEN COUNT(settingValue) = 0 THEN 'PROBLEM: Policy deployment interval not configured' WHEN settingValue = -1 THEN 'PROBLEM: Policy deployment interval set to MANUAL' ELSE CONCAT('GOOD: Policy deployment interval set to ',settingValue) END AS 'Policy Deployment Interval'
FROM policy.settings 
WHERE settingName = 'deploymentWindow' AND partitionid = 1
GROUP BY settingValue

-- TODO: Policy Management Application -- DONE
-- Sarath Notes: we need a query that determines % of agents that have policies applied to them

 SELECT FORMAT(COUNT(DISTINCT agentGuid) * 100.0 / (SELECT COUNT(*) FROM machNameTab),'N2') AS '%AgentsWithPolicies' 
  FROM policy.VpolicyAgentStatus

-- TODO: Policy Object Distribution -- DONE
-- Sarath Notes: we need a query that returns the # of policy objects that are applied in groups like 'agent menu','credentials','agent procedures'

  SELECT policyObjectType, COUNT(policyObjectType) AS Count FROM policy.VagentActivePolicyObjects
  GROUP BY policyObjectType
  ORDER BY Count desc

-- TODO: Policy Assignment Folder Check
-- Sarath Notes: We need a query to determine the % of policies that are applied are applied as a FOLDER instead of a direct policy.

-- TODO: Policy Machine Assignment -- DONE
-- Sarath Notes: We need a query that determines the % of agents that are applying policies directly to a machine and not mg/org
-- http://kbothell01.kaseya.net/wiki/index.php/Policy.policyViewAgent

  SELECT FORMAT(COUNT(DISTINCT agentGuid) * 100.0 / (SELECT COUNT(*) FROM machNameTab), 'N2') FROM policy.policyViewAgent
  WHERE assocType = 0 AND agentGuid NOT IN (SELECT agentGuid FROM policy.policyViewAgent
  WHERE assocType = 1)


-- Remote Control Machine Policy
SELECT CASE WHEN (COUNT(*) * 100 / (SELECT COUNT(*) FROM machnametab WHERE partitionid = 1)) < 100 THEN CONCAT('PROBLEM: Only ',COUNT(*) * 100 / (SELECT COUNT(*) FROM machnametab WHERE partitionid = 1),'% of agents have RC machine policy configured') ELSE 'GOOD: 100% of agents have RC machine policy configured' END AS 'RC Machine Policy'
FROM rcNotifyPolicy a 
JOIN machNameTab b ON a.agentGuid = b.agentGuid 
WHERE b.partitionid = 1

-- SM Compliance Check
DECLARE  @days nVARCHAR(10), @time nVARCHAR(10), @scan nVARCHAR(10), @Deploy nVARCHAR(10), @Patch nVARCHAR(10) 
SELECT @days=[Value] FROM [SM].[Defaults] WHERE RelatedObjectId = 11 AND PartitionId = 1 
SELECT @time =[value] FROM [SM].[Defaults] WHERE RelatedObjectId = 12 AND PartitionId = 1 
SELECT @scan = [value] FROM [SM].[Defaults] WHERE RelatedObjectId = 13 AND PartitionId = 1 
SELECT @Deploy = [value] FROM [SM].[Defaults] WHERE RelatedObjectId = 14 AND PartitionId = 1 
SELECT @Patch = [value] FROM [SM].[Defaults] WHERE RelatedObjectId = 15 AND PartitionId = 1 
SELECT 'Compliance check runs every' AS 'SM Setting',@days + ' days' AS 'Value'
UNION
SELECT 'Compliance check runs every',@time + ' hours'
UNION
SELECT 'Scan grace period',@scan + ' hours'
UNION
SELECT 'Deploy grace period',@Deploy + ' hours'
UNION
SELECT 'Patch tolerance percentage',@Patch + '%'
GO 

-- SM Vulnerability Check
SELECT CASE WHEN (COUNT(distinct a.agentGuid) * 100 / (SELECT count(*) FROM machnametab c WHERE c.partitionid = 1)) != 0 THEN CONCAT('PROBLEM: ',(COUNT(distinct a.agentGuid) * 100 / (SELECT count(*) FROM machnametab c WHERE c.partitionid = 1)),'% of agents are vulnerable') ELSE 'GOOD: No machines are vulnerable' END AS 'SM Vulnerabilities'
FROM sm.unappliedPatch a 
LEFT JOIN machnametab b ON a.agentGuid = b.agentGuid
WHERE b.partitionid = 1

-- TODO: SM Patch Approval Check -- DONE
-- Sarath Notes: we need a query that determines how many patches are pending approval

SELECT COUNT(DISTINCT id) AS UnApprovedPatches FROM SM.UnappliedPatch
WHERE ApprovalStatus = 2


-- TODO: SM Scan and Analysis Profile Review -- DONE
-- Sarath Notes: Hard one. Lets do a query that gathers the # of machines per profile. If we can include the settings applied, thatd be great, but might be too hard.

SELECT pap.Name AS Profile_Name, COUNT(m.PatchAnalysisProfileId) Machines_Assigned FROM sm.PatchAnalysisProfile pap
LEFT OUTER JOIN sm.machine m ON m.PatchAnalysisProfileId = pap.id
WHERE pap.PartitionId = 1
GROUP BY m.PatchAnalysisProfileId,pap.Name

-- TODO: SM Deployment Profile Review -- DONE
-- Sarath Notes: Hard one. Lets do a query that gathers the # of machines per profile. If we can include the settings applied, thatd be great, but might be too hard.

SELECT pdp.Name AS Profile_Name, COUNT(m.PatchDeploymentProfileId) Machines_Assigned FROM sm.PatchDeploymentProfile pdp
LEFT OUTER JOIN sm.machine m ON m.PatchDeploymentProfileId = pdp.id
WHERE pdp.PartitionId = 1
GROUP BY m.PatchDeploymentProfileId,pdp.Name

-- TODO: Alert Profile Review -- DONE
-- Sarath Notes: Hard one. Lets do a query that gathers the # of machines per profile. If we can include the settings applied, thatd be great, but might be too hard.

SELECT ap.name AS Profile_Name,COUNT(apa.AlertProfileId) AS Machines_Assigned FROM sm.AlertProfile ap
LEFT OUTER JOIN sm.AlertProfileAsset apa ON ap.id = apa.AlertProfileId
WHERE ap.PartitionId = 1
GROUP BY ap.name,apa.AlertProfileId