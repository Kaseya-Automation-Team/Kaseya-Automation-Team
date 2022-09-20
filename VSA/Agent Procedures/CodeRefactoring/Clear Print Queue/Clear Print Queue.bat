::=================================================================================
::Script Name:        Management: Clear printer queue
::Description:        Clear printer queue
::Lastest version:    2022-07-22
::=================================================================================
::
::
::
::Required variable inputs:
::None
::
::
::
::Required variable outputs:
::None
Rem clear the print spooler
@echo off
net stop spooler
ping localhost -n 4 > nul
del %SYSTEMROOT%\system32\spool\PRINTERS\*.* /q
ping localhost -n 4 > nul
net start spooler