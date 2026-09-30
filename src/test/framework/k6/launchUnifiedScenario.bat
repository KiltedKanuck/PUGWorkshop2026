@echo off
rem Convenience script to execute launchUnifiedScenario.js with k6.
rem Usage:   launchUnifiedScenario.bat [config-file]
rem Example: launchUnifiedScenario.bat configs\smoke-local.json
rem Defaults to configs\smoke-local.json if no config file is supplied.
rem Paths are resolved relative to this script's directory for consistency.
rem For full functionality please run the .sh script on Linux, WSL, or Cygwin.

setlocal

set "SCRIPT_DIR=%~dp0"
if "%~1"=="" (
    set "CONFIG_FILE=%SCRIPT_DIR%configs\smoke-local.json"
) else (
    set "CONFIG_FILE=%SCRIPT_DIR%%~1"
)

echo Using Config: %CONFIG_FILE%

set "SUMMARY_DIR=%SCRIPT_DIR%logs"
if not exist "%SUMMARY_DIR%\" mkdir "%SUMMARY_DIR%"

rem Pre-test PASOE status snapshot
k6 run --log-format raw ^
    --env "SUMMARY_DIR=%SUMMARY_DIR%" ^
    "%SCRIPT_DIR%scripts\monitor\status.js"

rem Pre-test database stats snapshot
k6 run --log-format raw ^
    --env "SUMMARY_DIR=%SUMMARY_DIR%" ^
    "%SCRIPT_DIR%scripts\monitor\database.js"

rem Main test run
k6 run --log-format raw ^
    --console-output="%SUMMARY_DIR%\console.log" ^
    --env "SUMMARY_DIR=%SUMMARY_DIR%" ^
    --env "CONFIG_FILE=%CONFIG_FILE%" ^
    "%SCRIPT_DIR%scripts\launchUnifiedScenario.js"
set MAIN_EXIT=%errorlevel%

rem Post-test PASOE status snapshot (always runs, even if the main test failed)
k6 run --log-format raw ^
    --env "SUMMARY_DIR=%SUMMARY_DIR%" ^
    "%SCRIPT_DIR%scripts\monitor\status.js"

rem Post-test database stats snapshot (always runs, even if the main test failed)
k6 run --log-format raw ^
    --env "SUMMARY_DIR=%SUMMARY_DIR%" ^
    "%SCRIPT_DIR%scripts\monitor\database.js"

exit /b %MAIN_EXIT%
