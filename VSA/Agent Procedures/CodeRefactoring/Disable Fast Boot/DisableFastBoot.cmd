::=================================================================================
::Script Name:        Disable Fast Boot
::Description:        Disables Fast Boot for Windows 10 & above.
::Lastest version:    2022-09-20
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
@echo off
setlocal
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%version%" == "10.0" (
    powercfg -h off
    eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "Windows Fast Boot disabled" > nul
) else (
    eventcreate /L Application /T ERROR /SO VSAX /ID 400 /D "Designed for Windows 10 & above" > nul
)