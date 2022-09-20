::
::=================================================================================
::Script Name:        Management: Enable Password Complexity
::Description:        Enable Password Complexity requirement
::Lastest version:    2022-05-25
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
SETLOCAL ENABLEDELAYEDEXPANSION
::Export current security parameters to file
SecEdit.exe /export /cfg "%TEMP%\GetSecParams.cfg" >nul 2>&1

::List of parameters to change. Divided by space if more than one
SET names=PasswordComplexity
::Parameters values to set. One value per line
::Enable password complexity
SET values[PasswordComplexity]=1

::parse exported security parameters
FOR /F "delims== tokens=1,*" %%X in ('type "%TEMP%\GetSecParams.cfg"') do (
    CALL :trim "%%X"
    SET cur_name=!result!
    FOR %%I in (%names%) do (
        IF "!cur_name!" equ "%%I" (
            SET value== !values[%%I]!       
        )
    )

    IF not defined value IF "%%Y" neq "" (
        CALL :trim "%%Y"
        SET value== !result!        
    )
::Export modified security parameters to file to be applied
    ECHO !cur_name! !value! >> "%TEMP%\SetSecParams.cfg"
    SET value=
)
::Apply modified security parameters
SecEdit.exe /configure /db secedit.sdb /cfg "%TEMP%\SetSecParams.cfg" >nul 2>&1
eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "Password Complexity Enabled" > nul

::Cleanup
DEL /q "%TEMP%\?etSecParams.cfg" >nul 2>&1
IF exist "%~dp0secedit.sdb" DEL "%~dp0secedit.sdb" >nul 2>&1

GOTO :eof

:trim 
SET result=%~1

SET "f=!result:~0,1!" & SET "l=!result:~-1!"

IF "!f!" neq " " IF "!l!" neq " " GOTO :eof
IF "!f!" equ " " SET result=!result:~1!
IF "!l!" equ " " SET result=!result:~0,-1!

CALL :trim "!result!"
GOTO :eof