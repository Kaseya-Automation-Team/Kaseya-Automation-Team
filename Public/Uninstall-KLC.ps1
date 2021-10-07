$KlcPath = Get-ChildItem -Path "C:\ProgramData\Package Cache" -Filter bundle.exe -Recurse | %{$_.FullName}
& "$KlcPath" /uninstall /quiet