<#
=================================================================================
Script Name:        Software Management: Install Citrix Receiver.
Description:        Downloads and silently installs Citrix Receiver.
Lastest version:    2022-05-10
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
$PageUri = 'https://www.citrix.com/downloads/workspace-app/windows/workspace-app-for-windows-latest.html'
$AppName = 'CitrixWorkspaceApp.exe'
$LogIt = 'TRUE'
$OutputFilePath = "$env:TEMP\Citrix-installer.exe"

#Check to see if windows is 64 bit or 32 bit
     if ($env:PROCESSOR_ARCHITECTURE -match "64") {

        $DetectFile = "${env:ProgramFiles(x86)}\Citrix\ICA Client\Receiver\Receiver.exe"
     }

     else {

        $DetectFile = "$env:ProgramFiles\Citrix\ICA Client\Receiver\Receiver.exe"
    }

if(Test-Path -Path $DetectFile -PathType Leaf){
    Write-Host "Citrix Receiver app is already installed on this machine!"
}

else{

    try
    {
        $WebResponse = Invoke-WebRequest -Uri $PageUri -UseBasicParsing -ErrorAction Stop
    }
    catch
    {
        "$PageUri response: [$($_.Exception.Response.StatusCode.Value__)]" | Write-Output
    }
    if ($null -ne $WebResponse) #URL responded
    {
        #Look for actual download URL
        [string]$DownloadUri = $WebResponse.Links | Where-Object outerHTML -Match 'Download File' | Where-Object rel -Match $AppName | Select-Object -ExpandProperty rel
        if ( -Not [string]::IsNullOrEmpty($DownloadUri))
        {
            try
            {
                $DownloadResult = Invoke-WebRequest -Uri "https:$DownloadUri" -OutFile $OutputFilePath -TimeoutSec 600
                #Status is 200 for SUCCESS
                $DownloadResult.StatusCode | Write-Output

                #Run the installation
                & $OutputFilePath /silent /noreboot /includeSSON /FORCE_LAA=1 EnableCEIP=false /AutoUpdateCheck=disabled

                Start-Sleep -Seconds 180
                
                if(Test-Path -Path $DetectFile -PathType Leaf){
                    Write-Host "Installation completed successfully!"
                }
                else{
                    Write-Host "Installation couldn't be completed, please try again later!"
                }

                Remove-Item $OutputFilePath

            }
            catch
            {
                "$DownloadUri response: [$($_.Exception.Response.StatusCode.Value__)]" | Write-Output
            }
        }
        else
        {
            "Didn't get download Uri for $AppName" | Write-Output
        }
    }

}


