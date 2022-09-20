<#
=================================================================================
Script Name:        Management: Create URL shortcut for ALL users
Description:        This script creates URL shortcut on desktop for ALL users. Customize the script by editing the ShortcutURL variable
Lastest version:    2022-09-20
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
# Outputs
$ShortcutName = "Google"
$ShortcutURL = "https://google.com"
$Path = "%PUBLIC%\Desktop\$ShortcutName.url"

$Source = @"
[InternetShortcut]
URL=$ShortcutURL
IDList=
"@

$Source | Out-File -FilePath $Path