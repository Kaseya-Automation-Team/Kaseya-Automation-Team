    
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
        $UninstallStrings += Get-ChildItem -Path $UninstallKey -ErrorAction SilentlyContinue | `
            Where-Object {$_.GetValue("DisplayName") -match $SoftwareName} | `
            Select-Object @{n="UninstallString"; e={$_.GetValue("UninstallString")}} | `
            Select-Object -ExpandProperty "UninstallString"
    }# foreach ($UninstallKey in $UninstallKeys)
    Remove-PSDrive HKU
    return $UninstallStrings