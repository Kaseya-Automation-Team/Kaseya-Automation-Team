## The script installs fonts from a folder. By default, the folder containing the fonts to install is C:\Fonts.
param (
    [parameter(Mandatory=$false)]
    $Path="C:\Fonts"
)
$objShell = New-Object -ComObject Shell.Application
$objFolder = $objShell.Namespace($FONTS)
$Fontdir = dir $Path
foreach($File in $Fontdir) {
    if( -not ($file.name -match "pfb$") ) {
        $try = $true
        $installedFonts = @(Get-ChildItem "$env:SystemRoot\fonts" | Where-Object {$_.PSIsContainer -eq $false} | Select-Object basename)
        $name = $File.baseName

        foreach($font in $installedFonts) {
            $font = $font -replace "_", "" 
            $name = $name -replace "_", "" 
            if($font -match $name) {
                $try = $false
            }
        }
        if($try) {
            $objFolder.CopyHere($File.fullname)
        }
    }
}