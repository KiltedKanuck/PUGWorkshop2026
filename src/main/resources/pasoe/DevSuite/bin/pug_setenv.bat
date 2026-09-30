@echo off

rem Custom environment variables for OELS testing.

rem Append a lightweight marker each time this script is loaded.
set OELS_SETENV_LOG=%~dp0pug_setenv.log
>> "%OELS_SETENV_LOG%" echo [%date% %time%] pug_setenv.bat executed ^(computer=%COMPUTERNAME% user=%USERNAME%^)

rem Provides sanity-checks via the /catalog/ping endpoint that custom environment variables are being loaded as expected:
set OELS_USE_CUSTOM_PING=true
set "OELS_PING_HOST=%COMPUTERNAME%"

exit /b 0
