DECLARE @MYDISK table (RowID INT, aguid DECIMAL(26, 0), DriveLetter VARCHAR(10), dSpace VARCHAR(10)) --Temp Talbe
DECLARE @MYDISK2 table (aguid DECIMAL(26, 0), dSpace VARCHAR(100)) --Final Table
DECLARE @CursorTestID INT = 1; --CursorID for iteration
DECLARE @RowCnt BIGINT = 0; --Rows count
DECLARE @aguidCnt INT = 0; --Count of each agentguid
DECLARE @dspacetemp INT = 0; --Number of BADs per agentGuid
DECLARE @ALARMS table (aguid DECIMAL(26, 0), Alarms VARCHAR(100))

-- Inserting records from audit table into temp table for iteration
INSERT INTO @MYDISK (RowID, aguid, DriveLetter, dSpace)
(SELECT ROW_NUMBER() OVER (ORDER BY (SELECT '1')) AS RowID, agentGuid, DriveLetter, [Disk Space] = (CASE WHEN freeMBytes > (totalMBytes) * 0.1 THEN 'GOOD' ELSE 'BAD' END)
FROM auditRsltDisks)

-- get a count of total rows from temp table to process 
SELECT @RowCnt = COUNT(0) FROM @MYDISK;
--While loop begins
WHILE @CursorTestID <= @RowCnt
BEGIN
    SELECT @aguidCnt = COUNT(aguid) FROM @MYDISK2 WHERE aguid = (SELECT aguid FROM @MYDISK WHERE RowID = @CursorTestID) --Count per agentguid 
    SELECT @dspacetemp = COUNT(dspace) FROM @MYDISK WHERE dspace = 'BAD' AND aguid = (SELECT aguid FROM @MYDISK WHERE RowID = @CursorTestID) --Number of bads per agentGuid

    
    IF (@aguidCnt >= 1) AND (@dspacetemp >= 1)
        BEGIN
            --Updating the existing record to BAD since there is one BAD record.
            UPDATE @MYDISK2 SET dSpace = 'BAD'
            WHERE aguid = (SELECT aguid FROM @MYDISK WHERE RowID = @CursorTestID)
        END 
    ELSE IF (@aguidCnt < 1)
        BEGIN
            --Insert into the final table since the agentguid doesn't exist already     
            INSERT INTO @MYDISK2(aguid, dSpace)
            (SELECT TOP 1 aguid,dspace FROM @MYDISK
            WHERE aguid = (SELECT aguid FROM @MYDISK WHERE RowID = @CursorTestID))
        END
    SET @CursorTestID = @CursorTestID + 1 
      
END

--While loop ends
-- SELECT * FROM @MYDISK2 ORDER BY aguid
--SELECT DISTINCT ramMbytes,agentGuid INTO #Temp FROM auditRsltCPU

SELECT DISTINCT(agentGuid), max(ramMbytes) as Ram INTO #Temp FROM auditRsltCPU
GROUP BY agentGuid

SELECT agentGuid, COUNT(AgentGuid) AS Patches INTO #TEMP2 FROM SM.UnappliedPatch
GROUP BY agentGUid

-- Inster data about alarms into virtual table
INSERT INTO @ALARMS (aguid, Alarms)
(select u.agentGuid, CASE WHEN count(ma.message) >=1 THEN 'BAD' ELSE 'GOOD' END from dbo.userIpInfo u
FULL OUTER JOIN monitorAlarm ma ON u.agentGuid = ma.agentGuid
GROUP BY u.agentGuid)


SELECT u.computerName,u.agentguid, u.OsName + ' ' + u.osType as 'OS Name',u.osInfo, m.dSpace AS 'Disk Space', a.ram, s.ComplianceMessage AS Compliant,ua.Patches,
[Type] = CASE WHEN u.IsServer = 1 THEN 'Server' ELSE 'WorkStation'  END,
[Online last 30 days] = CASE WHEN ps.offlinetime > dateAdd(DAY, -30, getDate()) THEN 'GOOD' ELSE 'BAD' END,
al.Alarms

FROM userIpInfo u
LEFT OUTER JOIN @MYDISK2 m ON m.aguid = u.agentGuid
JOIN #Temp a ON a.agentGuid = u.agentGuid
LEFT OUTER JOIN SM.vOutOfCompliance s ON s.AgentGuid = u.agentGuid
LEFT OUTER JOIN #TEMP2 ua ON ua.AgentGuid = u.agentGuid
LEFT OUTER JOIN agentstate ps ON ps.agentguid = u.agentGuid
INNER JOIN @ALARMS al ON al.aguid = u.agentGuid

DROP TABLE #Temp,#TEMP2
