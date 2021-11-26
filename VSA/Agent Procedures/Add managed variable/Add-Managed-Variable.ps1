    <#
    .Synopsis
       Inserts new managed varible into VSA DB
    .DESCRIPTION
       Script establishes connection to VSA DB and creates new managed variable in it, according to the specified input.
    .PARAMETER VarName
        Specifies name of the new managed variable
    .PARAMETER VarValue
        Specifies value of the new managed variable
    .PARAMETER Owner
        Specifies owner of variable. If not specified, variable will be PUBLIC.
    .EXAMPLE
       Add-Managed-Variable.ps1 -VarName "AdminEmail" -VarValue "admin@yourcompany.com"
    .EXAMPLE
       Add-Managed-Variable.ps1 -VarName "AdminEmail" -VarValue "admin@yourcompany.com" -Owner "admin"
    .OUTPUTS
       Success or error message
    #>

    [CmdletBinding()]
    param ( 

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()] 
        #Get name of the variable from the input parameter
        [string] $VarName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()] 
        #Get value of the variable from the input parameter
        [string] $VarValue,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        #If owner is not specified, variable will be public and will no belong to any user
        [string] $Owner = '********'
    )

$DBAddress = "localhost"
$DBName = "ksubscribers"

[string] $Query = @"

--Creating temporary DB table for INSERT cycle
DECLARE @tempdb TABLE (id int IDENTITY(1,1), guid numeric(26));

INSERT INTO @tempdb (guid)
--Fetch list of all top level organizations
SELECT id FROM [ksubscribers].[kasadmin].[org]

DECLARE @Counter INT, @MaxId INT, @row NUMERIC(26);
--Prepate for INSERT cycle - count amount of organizations
SELECT @Counter = min(id) , @MaxId = max(id)
FROM @tempdb

--Begin cycle
WHILE (@Counter <= @MaxId)
    BEGIN
        SELECT @row = guid from @tempdb WHERE id = @Counter
        --Insert data into VSA DB
        INSERT INTO [ksubscribers].[dbo].[scriptVar] (groupId, varName, varValue, itemGuid, partitionId)
        VALUES ('obsolete', '$VarName.$Owner', '$VarValue', @row, 1);

        SET @Counter  = @Counter  + 1 
    END
"@

try {
    
    $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $SqlConnection.ConnectionString = "Server=$DBAddress;Database=$DBName;Integrated Security=True"

    $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
    
    $SqlCmd.CommandText = $Query
    $SqlCmd.Connection = $SqlConnection

    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    $SqlAdapter.Fill($DataSet)|Out-Null

    Write-Host "New managed variable has been successfully created."
}
catch {
    $_.Exception.Message | Write-Error
}

finally {

$SqlConnection.Close()
$SqlConnection.State | Write-Verbose

}
