@echo off
rem Convenience script to execute launchAnomalies.js with k6.
rem Usage:   launchAnomalies.bat [config-file]
rem Example: launchAnomalies.bat configs\smoke-local.json
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

k6 run --log-format raw ^
    --console-output="%SCRIPT_DIR%logs\console.log" ^
    --env "SUMMARY_DIR=%SCRIPT_DIR%logs" ^
    --env "CONFIG_FILE=%CONFIG_FILE%" ^
    "%SCRIPT_DIR%scripts\launchAnomalies.js"
