function Update-VSAConnection {
<#
.SYNOPSIS
    Updates the token and session expiration for a VSAConnection object.
.DESCRIPTION
    The Update-VSAConnection function updates the authentication token and session expiration for a given VSAConnection object.
    If no explicit VSAConnection object is provided, it attempts to update the persistent VSAConnection object stored in the environment variable.
    The function checks if the session is about to expire and renews it by making a new request to the authentication endpoint.

.PARAMETER VSAConnection
    Specifies the VSAConnection object to be updated. If not provided, the function attempts to use the persistent VSAConnection object.
.INPUTS
    VSAConnection
.OUTPUTS
    None.
.NOTES
    This function is part of the Kaseya VSA 9 REST API Wrapper PowerShell module.
    Ensure that the VSAConnection object or a persistent connection is available before calling this function.

.EXAMPLE
    # Example 1: Update an existing VSAConnection object
    $vsaConnection = New-VSAConnection -VSAServer "https://vsaserver.example.com" -Credential (Get-Credential)
    Update-VSAConnection -VSAConnection $vsaConnection

    # Example 2: Update the persistent VSAConnection object
    Update-VSAConnection

    # Example 3: Update the VSAConnection object using the pipeline
    $vsaConnection | Update-VSAConnection
#>
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $AuthSuffix = 'API/v1.0/Auth'
    )

    if ($VSAConnection) {
        # Non-persistent connection
        $SessionExpiration = $($VSAConnection.SessionExpiration.AddMinutes(-1))
    } else {
        # Persistent connection
        if (-not [string]::IsNullOrEmpty([VSAConnection]::GetPersistentToken())) {
            $SessionExpiration = $([VSAConnection]::GetPersistentSessionExpiration()).AddMinutes(-1)
        } else {
            Throw "Update-VSAConnection: Neither explicit VSAConnection provided nor persistent VSAConnection found!"
        }
    }

    # Renew the session if it is about to expire
    if ($SessionExpiration -le [datetime]::Now) {

        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug "The REST API Token is about to expire ($SessionExpiration)."
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            Write-Verbose "The REST API Token is about to expire ($SessionExpiration)."
        }

        # Extract the data needed for repeat Token request
        if ($null -eq $VSAConnection) {
            # The Connection is persistent
            $VSAUserPAT = [VSAConnection]::GetPersistentPAT()
            $VSAUserName = [VSAConnection]::GetPersistentUserName()
            $VSAServer = [VSAConnection]::GetPersistentURI()
            $IgnoreCertificateErrors = [VSAConnection]::GetIgnoreCertErrors()
        } else {
            $VSAUserPAT = $VSAConnection.PAT
            $VSAUserName = $VSAConnection.UserName
            $VSAServer = $VSAConnection.URI
            $IgnoreCertificateErrors = $VSAConnection.IgnoreCertificateErrors
        }

        if ([string]::IsNullOrEmpty($VSAUserPAT)) {
            Throw "Update-VSAConnection: No PAT retrieved from the VSAConnection object. Unable to update VSAConnection!"
        }

        $Encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$VSAUserName`:$VSAUserPAT"))
        $AuthString = "Basic $Encoded"

        $VSAServerUri = New-Object System.Uri -ArgumentList $VSAServer
        $AuthEndpoint = [System.Uri]::new($VSAServerUri, $AuthSuffix) | Select-Object -ExpandProperty AbsoluteUri

        $AuthParams = @{
            URI                     = $AuthEndpoint
            AuthString              = $AuthString
            IgnoreCertificateErrors = $IgnoreCertificateErrors
            ErrorAction             = 'Stop'
        }

        $result = try {
            Get-RequestData @AuthParams | Select-Object -ExpandProperty Result
        } catch {
            $errorMessage = $_.Exception.Message
            Throw "Server '$VSAServer' returned error`nUser '$VSAUserName'`n$errorMessage"
        }

        # Check if Session token was obtained
        if ([string]::IsNullOrEmpty($result.Token)) {
            Throw "Update-VSAConnection: Unable to update VSAConnection object!"
        }

        # Extract data from the request result & update the Connection properties
        $SessionExpiration = [DateTime]::ParseExact($result.SessionExpiration, "yyyy-MM-ddTHH:mm:ssZ", [System.Globalization.CultureInfo]::InvariantCulture)

        if ($null -eq $VSAConnection) {
            # The Connection is persistent
            [VSAConnection]::UpdatePersistentToken($result.Token)
            [VSAConnection]::UpdatePersistentSessionExpiration($SessionExpiration)
        } else {
            $VSAConnection.UpdateToken($result.Token)
            $VSAConnection.UpdateSessionExpiration($SessionExpiration)
        }

        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            Write-Verbose "`nUpdate-VSAConnection: Session token renewed.`n`tSession token expiration: $SessionExpiration (UTC).`nContinue working..."
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug "`nUpdate-VSAConnection: Session token renewed.`n`tSession token expiration: $SessionExpiration (UTC).`nContinue working..."
        }

    } # the session is about to expire
}
