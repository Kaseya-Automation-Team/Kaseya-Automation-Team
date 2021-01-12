#Version 0.1
#Description: This script will initially create role "remoteaccess" (if it doesn't exist) which can be configured via VSA. After that, script will create separted scope
#(if doesn't exist) based on the computername and create a new user (if doesn't exist) based on the computer name as well and generated secure password. This user will be
#assigned "remoteaccess" role and will stay in it's sepated scope. The only thing to do manually will be to add corresponding machine to the scope. Username and password
#will be stored in a custom fields for machine.
#Author: Aliaksandr Serzhankou
#Email: a.serzhankou@kaseya.com


 param (
    [parameter(Mandatory=$true)]
    [string]$Url = "",
    [parameter(Mandatory=$true)]
    [string]$Username = "",
    [parameter(Mandatory=$true)]
    [string]$Password = "",
    [parameter(Mandatory=$true)]
    [string]$Log = ""
 )

#Ignore self-signed SSL certificate
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }

[ServerCertificateValidationCallback]::Ignore()

$Url = "https://" + $Url

#Unique correlation identificator of run
$CorrelationId = New-Guid
$CorrelationId = $CorrelationId.Guid

#Encode username and password to a base64 string to obtain auth token
Function Get-StringHash([String] $String,$HashName = "SHA256") 
{ 
    $StringBuilder = New-Object System.Text.StringBuilder

    [System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{ 
        [Void]$StringBuilder.Append($_.ToString("x2")) 
    }

    $StringBuilder.ToString() 
}

#This function implements logging to file
Function Log {
    param(
        [Parameter(Mandatory=$true)][String]$msg
    )
    $DateTime = Get-Date -Format "dd.mm.yyyy hh:mm:ss.ms"
    Add-Content $Log ($DateTime + " " + $msg)

    #Uncomment line below, if you also want log entries to be displayed under Procedure History log, not only recorded to log file
    #Write-Host $msg
}

#Generate secure password for new user
Function GeneratePassword {
    $GeneratedPassword = New-Object -TypeName PSObject
    $GeneratedPassword | Add-Member -MemberType ScriptProperty -Name "Password" -Value { ("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz".tochararray() | sort {Get-Random})[0..8] -join '' }
    return $GeneratedPassword.Password
}

#Get id of "remoteaccess" role
Function GetRoleId {
    $RoleId = $Request.Result | Where-Object {$_.RoleName -eq 'remoteaccess'}
    $global:RoleId = $RoleId.RoleId
}

#Get id of a separated scope created for new user
Function GetScopeId {
    $ScopeId = $Request.Result | Where-Object {$_.ScopeName -eq $ComputerName} | Select-Object -Property ScopeId
    $global:ScopeId = $ScopeId.ScopeId
    #echo $ScopeId
}

#Get id of admin user provided in the beginning
Function GetAdminId {
    $AdminID = $Request.Result | Where-Object {$_.AdminName -eq $Username} | Select-Object -Property UserId
    $global:AdminId = $AdminID.UserId
    #echo $AdminID
}

Log("========= " + $CorrelationId + " =========")
Log("Started")

$Random = Get-Random
$RawSHA256Hash = Get-StringHash $Password "SHA256"
$CoveredSHA256HashTemp = Get-StringHash ($Password+$Username) "SHA256"
$CoveredSHA256Hash = Get-StringHash ($CoveredSHA256HashTemp+$Random) "SHA256"
$RawSHA1Hash = Get-StringHash $Password "SHA1"
$CoveredSHA1HashTemp = Get-StringHash ($Password+$Username) "SHA1"
$CoveredSHA1Hash = Get-StringHash ($CoveredSHA1HashTemp+$Random) "SHA1"
$Text = "user=$Username,pass2=$CoveredSHA256Hash,pass1=$CoveredSHA1Hash,rpass2=$RawSHA256Hash,rpass1=$RawSHA1Hash,rand2=$Random"
$Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Text))

$Headers = @{
    'Authorization' = 'Basic ' + $Encoded
}

#Obtain auth token via API
try {
    $Request = Invoke-Restmethod -Uri ($Url + "/API/v1.0/Auth") -Method GET -Headers $Headers

    if ($Request.Error -eq "None") {
        Log("Authorization token has been obtained.")
    }

    else {
        Log("Unable to obtain authorization token.")
    }
}

catch {
    Log($_.Exception.Message)
    Log("Oops, unable to get token.")
}

#Extract token from response
$Token = $Request.Result.Token

#Combine new header with auth string which contains token
$Headers = @{
    'Authorization' = 'Bearer ' + $Token
}

#Checking if "remoteaccess" role already exists. If not - create it
try {
    $Request = Invoke-Restmethod -Uri ($Url + "/API/v1.0/system/roles") -Method GET -Headers $Headers
    
    if ($Request.Result.RoleName -eq "remoteaccess")
    {
        GetRoleId

        Log("User role `"remoteacess`" already exists on server. Skipping this step.")

    } else
    {
        $Body = @{
        'Rolename' = 'remoteaccess'
        'RoleTypeIds' = '6'
    }
    
    $Request = Invoke-Restmethod -Uri ($Url + "/API/v1.0/system/roles") -Method POST -Headers $Headers -Body $Body

    Log("User role `"remoteaccess`" has been created.")

    $Request = Invoke-Restmethod -Uri ($Url + "/API/v1.0/system/roles") -Method GET -Headers $Headers

    GetRoleId
    }

}
catch {
    Log($_.Exception.Message)
    Log("Oops, unable to create user role.")
}

#Generate username using computername
$ComputerName = $env:COMPUTERNAME.ToLower()

Log("Generated username is: " + $ComputerName + ".")

#Check if scope with name equal to username already exists. If not, create one.
try {
    $Request = Invoke-Restmethod -Uri ($Url + "/API/v1.0/system/scopes") -Method GET -Headers $Headers
    
    if ($Request.Result.ScopeName -eq $ComputerName) {
    GetScopeId

    Log("Scope $ComputerName already exists.")
    } else {

            $Body = @{
            'ScopeName' = $ComputerName
            }

            $Request = Invoke-Restmethod -Uri ($Url + "/API/v1.0/system/scopes") -Method POST -Headers $Headers -Body  $Body
            Log("Scope $ComputerName has been successfully created.")

            $Request = Invoke-Restmethod -Uri ($Url + "/API/v1.0/system/scopes") -Method GET -Headers $Headers
            GetScopeId
         }
            }

catch {
    Log($_.Exception.Message)
    Log("Oops, unable to create scope")
}

#Obtain default organization id
try {
    $Request = Invoke-Restmethod -Uri ($Url + "/API/v1.0/system/orgs") -Method GET -Headers $Headers
    $OrgId = $Request.Result.OrgId[0]

    try {
    $Request = Invoke-Restmethod -Uri ($Url + "/API/v1.0/system/orgs/$OrgId/departments") -Method GET -Headers $Headers

    if ($Request.Result.DepartmentName -eq "default")
    {
        $DepId = $Request.Result.DepartmentId
    } else {
        Log("Unable to obtain default DepartmentId")
     }
    }

    catch {
        Log($_.Exception.Message)
        Log("Oops, unable to obtain DepartmentId")
    }

    }
catch {
    Log($_.Exception.Message)
    Log("Oops, unable to obtain OrganizationId")
}

#Generate secure password for user
$UserPassword = GeneratePassword

#Get id of admin's account and check if user for this machine already exists. If not, add admin's account to "remoteaccess" role and separate scope
try {
    $Request = Invoke-Restmethod -Uri ($Url + "/API/v1.0/system/users") -Method GET -Headers $Headers

    GetAdminId

    if ($Request.Result.AdminName -eq $ComputerName) {
        Log("User already exists. No actions required.")
    }
    
    else {

        Log("User doesn't exist, let's try to create it.")

        $Headers = $Headers + @{'Content-type' = 'application/json'}

        $Request = Invoke-Restmethod -Uri ($Url + "/API/v1.0/system/roles/" + $global:RoleID + "/users/" + $AdminId) -Method PUT -Headers $Headers

        Log("`"remoteaccess`" role has been temporary assigned to admin user.")

        $Request = Invoke-Restmethod -Uri ($Url + "/API/v1.0/system/scopes/" + $global:ScopeID + "/users/" + $AdminId) -Method PUT -Headers $Headers

        Log("Scope $ComputerName has been temporary assigned to admin user.")

        try {
        $Body = @{
        'AdminName' = $ComputerName
        'AdminPassword' = $UserPassword
        'Admintype' = 1
        'AdminScopeIds' = @($global:ScopeId)
        'AdminRoleIds' = @($global:RoleId)
        'FirstName' = 'Remote'
        'LastName' = 'Access'
        'Email' = 'info@test.com'
        'DefaultStaffOrgId' = $OrgId
        'DefaultStaffDepartmentId' = $DepId
         }

         

         $Body = ConvertTo-Json($Body)

         $Request = Invoke-Restmethod -Uri ($Url + "/API/v1.0/system/users") -Method POST -Headers $Headers -Body $Body

         Log("User $ComputerName has been successfully created within scope $global:ScopeId and Role $global:RoleId")
         Write-Host "Access details:"
         Write-Host "Username: " $ComputerName
         Write-Host "Password: " $UserPassword
         }

        catch {
            Log($_.Exception.Message)
            Log("Oops, unable to create user $ComputerName")
        }
    
    }

}

catch {
    Log($_.Exception.Message)
    Log("Oops, unable to assign role or scope to admin user.")
}



Write-Host "Successfully completed."

Log("Finished.")
