@echo off

rem Execute the PowerShell script to stop the batch import watcher and shut down the database
set SCRIPT_DIR=%~dp0
set SCRIPT_PATH=%SCRIPT_DIR%instance_shutdown.ps1
set LOGFILE=%SCRIPT_DIR%instance_shutdown.log

rem Run the PowerShell script in the background
powershell.exe -NoProfile -ExecutionPolicy Bypass -File %SCRIPT_PATH% > "%LOGFILE%" 2>&1

rem Explicitly exit, gracefully
exit /b 0
