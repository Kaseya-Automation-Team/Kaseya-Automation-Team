::Sets password age in days.
::
::Custom Number of passwords age
SET PWD_AGE=90

SET MIN_AGE=1
::
IF %PWD_AGE% LSS %MIN_AGE% (
    SET PWD_AGE=%MIN_AGE%
)
::Set the number
net accounts /maxpwage:PWD_AGE

eventcreate /L Application /T INFORMATION /SO VSAX /ID 200 /D "Password Age set to %PWD_AGE% days" > nul