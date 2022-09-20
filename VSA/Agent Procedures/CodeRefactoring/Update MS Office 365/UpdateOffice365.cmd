::
::=================================================================================
::Script Name:        Management: Update MS Office 365
::Description:        Switches the Office 365 update to the monthly update channel and triggers update. All the Office 365 applications will be forced to shutdown.
::Lastest version:    2022-05-17
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
SET C2RC="%PROGRAMFILES%\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe"
if exist "%C2RC%" (
    "%C2RC%" /changesetting Channel=Current
    "%C2RC%" /update user updatepromptuser=false forceappshutdown=true displaylevel=false
    eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "Office update channel was switched them to the monthly update. Update was triggered" > nul
) else (
    eventcreate /L Application /T ERROR /SO VSAX /ID 400 /D "Could not locate the %C2RC% file" > nul
)