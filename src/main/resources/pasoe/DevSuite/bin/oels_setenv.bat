@echo off

rem Custom environment variables for OELS testing.

rem Append a lightweight marker each time this script is loaded.
set OELS_SETENV_LOG=%~dp0oels_setenv.log
>> "%OELS_SETENV_LOG%" echo [%date% %time%] oels_setenv.bat executed ^(computer=%COMPUTERNAME% user=%USERNAME%^)

rem Provides sanity-checks via the /catalog/ping endpoint that custom environment variables are being loaded as expected:
set OELS_USE_CUSTOM_PING=true
set "OELS_PING_HOST=%COMPUTERNAME%"

rem Comma-delimited list of ABL application names that should use the context manager:
set "CONTEXT_MANAGED_ABLAPPS=DevSuite"

rem Force use of the original context logic from customer application code:
set "USE_ORIGINAL_CONTEXT_LOGIC=true"

rem Force an explicit delete of the user context object rather than dereferencing:
rem set "USE_EXPLICIT_CONTEXT_DELETE=true"

exit /b 0
