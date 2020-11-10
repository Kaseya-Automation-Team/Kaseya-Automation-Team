$folder = $args[0]
$sz = $args[1]
"{0}" -f [math]::Round(((Get-ChildItem $folder -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / $sz),2)