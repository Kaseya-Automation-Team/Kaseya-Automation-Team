param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $SoftwareName,
    [parameter(Mandatory=$False)]
    [ValidateNotNullOrEmpty()]
    [string] $SilentSwitch
)
$SoftwareName = [Regex]::Escape($SoftwareName)


#region function Get-SoftwareInstalled
function Get-SoftwareInstalled {
    [OutputType([String[]])]
    Param (
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        [string] $SoftwareName
    )

    [OutputType([string[]])]
    [string[]]$UninstallKeys=@("HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall")
    [string]$UserGUIDPattern="S-\d-\d+-(\d+-){1,14}\d+$"
    $null = New-PSDrive -Name HKU -PSProvider Registry -Root Registry::HKEY_USERS
    $UninstallKeys += Get-ChildItem HKU: -ErrorAction SilentlyContinue | `
        Where-Object { $_.Name -match $UserGUIDPattern } | `
        ForEach-Object { "HKU:\$($_.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Uninstall" }
    
    [string[]] $UninstallStrings = @()
    foreach ($UninstallKey in $UninstallKeys) {
        [string]$UninstallStr = Get-ChildItem -Path $UninstallKey -ErrorAction SilentlyContinue | `
            Where-Object {$_.GetValue("DisplayName") -match $SoftwareName} | `
            Select-Object @{n="QuietUninstallString"; e={$_.GetValue("QuietUninstallString")}} | `
            Select-Object -ExpandProperty "QuietUninstallString"
        if ([string]::IsNullOrEmpty($UninstallStr) ){
            $UninstallStr = Get-ChildItem -Path $UninstallKey -ErrorAction SilentlyContinue | `
            Where-Object {$_.GetValue("DisplayName") -match $SoftwareName} | `
            Select-Object @{n="UninstallString"; e={$_.GetValue("UninstallString")}} | `
            Select-Object -ExpandProperty "UninstallString"
        }
        if ( -Not [string]::IsNullOrEmpty($UninstallStr) ) {
            $UninstallStrings += $UninstallStr
        }
    }# foreach ($UninstallKey in $UninstallKeys)
    Remove-PSDrive HKU
    return $UninstallStrings
}
#endregion function Get-SoftwareInstalled

[string[]]$Found = Get-SoftwareInstalled -SoftwareName $SoftwareName



if ( 0 -lt $Found.Count) {
    foreach ($RegistryString in $Found) {
        #
        [hashtable] $HT = [hashtable]::new()
        #MSI uninstall string
        if ($RegistryString -imatch 'msiexec') {
            $HT.Add( 'FilePath', 'MSiExec.exe')
            [string]$ProdCode = [regex]::Matches($RegistryString, '(?<=\{).+?(?=\})').Value
            $HT.Add( 'ArgumentList', "/X {$ProdCode} /qn")
        } else {
        #EXE uninstall string
            [string]$FilePath = [regex]::Matches($RegistryString, '(?<=\").+?(?=\")').Value

            if ( Test-Path -Path $FilePath ) {
                $HT.Add( 'FilePath', $FilePath)
                [string]$ArgumentList = $([regex]::Matches($RegistryString, '([^\"]+$)').Value).Trim()
                if ( -Not [string]::IsNullOrEmpty($SilentSwitch) ){
                    $ArgumentList = $SilentSwitch
                }
                if ( -Not [string]::IsNullOrEmpty($ArgumentList) ) {
                    $HT.Add( 'ArgumentList', $ArgumentList)
                }
                
            }
            
        }
        if (0 -lt $HT.Count) {
            Start-Process @HT -PassThru -Wait
        }
    }
}