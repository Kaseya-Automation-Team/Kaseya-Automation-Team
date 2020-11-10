$folder = $args[0]
$sz = $args[1]
if ($sz.ToLower() -eq "gb") {
    "{0}" -f [math]::Round(((Get-ChildItem $folder -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / GB),2)
} else {
	"{0}" -f [math]::Round(((Get-ChildItem $folder -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum / MB),2)
}