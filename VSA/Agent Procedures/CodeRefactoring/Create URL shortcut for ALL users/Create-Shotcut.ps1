# Outputs
$ShortcutName = "Google"
$ShortcutURL = "https://google.com"
$Path = "$env:SystemDrive\Users\Public\Desktop\$ShortcutName.url"

$Source = @"
[InternetShortcut]
URL=$ShortcutURL
IDList=
"@

$Source | Out-File -FilePath $Path
