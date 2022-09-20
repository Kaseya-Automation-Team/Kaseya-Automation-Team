::
::=================================================================================
::Script Name:        Management: Set Password age
::Description:        Sets Password age in days
::Lastest version:    2022-04-11
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


::Custom Number of passwords age
SET PWD_AGE=42

SET MIN_AGE=1
::
IF %PWD_AGE% LSS %MIN_AGE% (
    SET PWD_AGE=%MIN_AGE%
)
::Set the number
net accounts /maxpwage:PWD_AGE

eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "Password Age set to %PWD_AGE% days" > nul