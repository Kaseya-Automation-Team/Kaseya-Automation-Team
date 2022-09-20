::=================================================================================
::Script Name:        Management: Empty Recycle Bin
::Description:        Empty Recycle Bin for users.
::Lastest version:    2022-04-21
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
rd /s /q %systemdrive%\$Recycle.Bin
eventcreate /L Application /T INFORMATION /SO "VSA X" /ID 200 /D "Recycle Bin cleared" > nul