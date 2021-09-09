
function New-VSAUser
{
    $URISuffix = 'api/v1.0/system/users'

    if ([VSAConnection]::IsPersistent)
    {
        $CombinedURL = "$([VSAConnection]::GetPersistentURI())/$URISuffix"
        $UsersToken = "Bearer $( [VSAConnection]::GetPersistentToken() )"
    }
    else
    {
        $ConnectionStatus = $VSAConnection.GetStatus()

        if ( 'Open' -eq $ConnectionStatus )
        {
            $CombinedURL = "$($VSAConnection.URI)/$URISuffix"
            $UsersToken = "Bearer $($VSAConnection.GetToken())"
        }
        else
        {
            throw "Connection status: $ConnectionStatus"
        }
    }

    $AllUsers = Get-VSAUsers
    [int]$NewId = ( $AllUsers| Measure-Object -Property UserId -Maximum).Maximum + $(Get-Random -Minimum 1 -Maximum 100)

    Write-Output "New ID $NewId"
    Write-Output $CombinedURL

    [int[]] $AdminScopeIds = @(2)
    [int[]] $AdminRoleIds = @(2)

    $Body = [ordered]@{
        AdminName = 'DeleteMe'
        AdminPassword = 'A#@s3KJTj?6xjmQ#wQQ0rd'
        Admintype = 2
        AdminScopeIds = $AdminScopeIds
        AdminRoleIds = $AdminRoleIds
        FirstName = 'TestUser'
        LastName = 'DeleteMe'
        DefaultStaffOrgId = 7631998713719223144216
        DefaultStaffDepartmentId = 42125214345225126322922171
        Email = 'bill.gates@microsoft.com'
    } | ConvertTo-Json

     $authHeader = @{
        Authorization = $UsersToken
    }

    $requestParameters = @{
        Uri = $CombinedURL
        Method = 'Post'
        Headers = $authHeader
        Body = $Body
        ContentType = "application/json"
        Verbose = $true
        Debug = $true
    }
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertificatesPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertificatesPolicy
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

$requestParameters

Invoke-WebRequest @requestParameters

}

Export-ModuleMember -Function New-VSAUser