::Sets number of passwords to be remembered. The value must be between 0 and 24 passwords.
::
::Custom Number of passwords to remember
SET PWD_NUM=24
::Minimum and maximum allowed number of passwords. For double-checking
SET MAX_NUM=24
SET MIN_NUM=0
::
IF %PWD_NUM% GTR %MAX_NUM% (
    SET PWD_NUM=%MAX_NUM%
) ELSE IF %PWD_NUM% LSS %MIN_NUM% (
    SET PWD_NUM=%MIN_NUM%
)
::Set the number
net accounts /uniquepw:%PWD_NUM%
eventcreate /L Application /T INFORMATION /SO "VSA X" /ID 200 /D "Numbers of passwords to be remembered set to %PWD_NUM%" > nul