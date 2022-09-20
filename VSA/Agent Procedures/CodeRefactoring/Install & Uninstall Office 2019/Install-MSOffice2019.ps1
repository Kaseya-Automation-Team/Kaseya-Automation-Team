<#
=================================================================================
Script Name:        Software Management: Install MS Office 2019.
Description:        Install MS Office 2019.
Lastest version:    2022-06-29
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>

[string] $ActivationKey = ''#                    Set MS Office product key in format 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX'
[string] $OfficeEdition = 'Standard2019Volume' # Set Product ID (Supported Product IDs listed on https://docs.microsoft.com/en-us/office365/troubleshoot/installation/product-ids-supported-office-deployment-click-to-run)

[string] $BitVersion = '64' #                    Set MS Office bit version for 64-bit Windows
[string] $ODTPath = "C:\ODT" #                   Path to download & store installer
[string] $PageUri = 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117'

#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

[int] $FreeSpace = (Get-Volume -DriveLetter C | Select-Object -ExpandProperty SizeRemaining)/1gb
[bool]$HasEnoughSpace = $FreeSpace -gt 10
[bool] $IsInstallerObtained = $false

 if ( -not (Test-Path $ODTPath)) {New-Item -Path $ODTPath -ItemType Directory }


#region function Get-FileFromURI
function Get-FileFromURI {
    [OutputType([bool])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DownloadUrl,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SaveTo,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [int] $TimeoutSec = 600
    )
    [bool] $Result = $false

    Set-Variable ProgressPreference SilentlyContinue
    $ResponseCode = try {
        (Invoke-WebRequest -Uri $DownloadUrl -OutFile $SaveTo -UseBasicParsing -TimeoutSec $TimeoutSec -PassThru -ErrorAction Stop).StatusCode
    } catch {
        $_.Exception.Response.StatusCode.value__
    }

    if (200 -eq $ResponseCode) {
        if (Test-Path -Path $SaveTo ) {
            Unblock-File -Path $SaveTo
            $Result = $true
        } else {
            [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Unable to find downloaded file at <$SaveTo>", "Error", 400)
        }
    } else {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Unable to download from <$DownloadUrl> to <$SaveTo>. Response: [$ResponseCode]", "Error", 400)
    }
    return $Result
}
#endregion function Get-FileFromURI


if( -not $HasEnoughSpace) {
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$($FreeSpace)GB of free space is available on Drive C, which is not enough for the installation", "Error", 400)
} else { #There's enough space on the drive C
    if ( -not [Environment]::Is64BitOperatingSystem ) {
        $BitVersion = 32
    }
    
    try {
        $WebResponse = Invoke-WebRequest -Uri $PageUri -UseBasicParsing -ErrorAction Stop
    } catch {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$PageUri response: [$($_.Exception.Response.StatusCode.Value__)]", "Error", 400)
    }

    if ($null -ne $WebResponse) { #URL responded
        #Look for actual download URL
        [string]$DownloadUri = $WebResponse.Links | Where-Object outerHTML -Match 'click here to download manually' | Select-Object -ExpandProperty href -Unique
        if ( [string]::IsNullOrEmpty($DownloadUri) ) {
            [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Couldn't get ODT dowload URL", "Error", 400)
        } else {
            
            #Download URI obtained
            $DownloadPath = "$ODTPath\officedeploymenttool.exe"
            
            #Download the office deployment tool
            $IsInstallerObtained = Get-FileFromURI -DownloadUrl $DownloadUri -SaveTo $DownloadPath
        }
    }
}

#region Office installation
if ( $IsInstallerObtained ) {
    Start-Process -Wait -FilePath $DownloadPath -ArgumentList "/extract:`"$ODTPath`" /quiet" -Verb RunAs

    if ( -not (Test-Path -Path "$ODTPath\setup.exe") ) {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "setup.exe not found in <$ODTPath>", "Error", 400)
    } else {
    #region set ODT config file content
        [string] $AutoActivate = "0"

        if ( -not [string]::IsNullOrEmpty($ActivationKey) ) {
            [string] $ProductKey = "PIDKEY=`"$ActivationKey`""
            $AutoActivate = "1"
        }

        [string] $ConfigContent = @"
<Configuration>
  <Add SourcePath="{0}" OfficeClientEdition="{1}">
    <Product ID="{2}" {3}>
      <Language ID="MatchOS" />
    </Product>
  </Add>
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/>
  <!--  <Updates Enabled="TRUE" Branch="Current" /> -->
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="{4}" />
</Configuration>
"@ -f @($ODTLocationFolder, $BitVersion, $OfficeEdition, $ProductKey, $AutoActivate) | Out-File -FilePath "$ODTPath\Configuration.xml" -Force
    #endregion set ODT config file content

        Start-Process -Wait -FilePath "$ODTPath\setup.exe" -ArgumentList "/configure $("$ODTPath\Configuration.xml")" -Verb RunAs
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "MS Office setup started", "Information", 200)
    }
}
#endregion Office installation