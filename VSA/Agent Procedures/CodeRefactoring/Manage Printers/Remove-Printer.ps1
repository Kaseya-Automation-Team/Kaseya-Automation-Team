<#
=================================================================================
Script Name:        Management: Remove printer.
Description:        Remove printer.
Lastest version:    2022-07-29
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
$PrinterName = ''
Remove-Printer -Name $PrinterName -ErrorAction Continue