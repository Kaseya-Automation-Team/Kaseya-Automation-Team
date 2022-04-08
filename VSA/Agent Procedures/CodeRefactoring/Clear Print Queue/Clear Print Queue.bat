Rem clear the print spooler
@echo off
net stop spooler
ping localhost -n 4 > nul
del C:\WINDOWS\system32\spool\PRINTERS\*.* /q
ping localhost -n 4 > nul
net start spooler