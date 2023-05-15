# Set the download URL
$downloadUrl = "https://binaries.webex.com/WebexTeamsDesktop-Windows-Gold/Webex.msi"

# Set the output file path
$outputFilePath = "$env:TEMP\Webex.msi"

if (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*Webex*" }) {
    

}else {
    
    
    # Download the installer
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputFilePath

    # Install Webex Meetings
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$outputFilePath`" ACCEPT_EULA=TRUE ALLUSERS=1 /qn" -Wait -NoNewWindow

    # Delete the installer
    Remove-Item -Path $outputFilePath
}