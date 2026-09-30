@echo off
REM Batch Management Tool

REM Utility must be run with DLC environment variable set
if exist "%DLC%"\ant goto BIN
   echo.
   echo Progress DLC path may not be set correctly.
   echo Please run from within a PROENV session.
   echo.
   pause
   goto END

:BIN
if "%ANTSCRIPT%"=="" set ANTSCRIPT="%DLC%"\ant\bin\ant.bat
if exist "%ANTSCRIPT%" goto START
   cls
   echo AppServer %0 Messages:
   echo.
   echo The OpenEdge Apache Ant launch script could not be found.
   echo.
   echo Progress DLC path may not be set correctly.
   echo Please run from within a PROENV session.
   echo.
   echo Progress DLC setting: %DLC%
   echo Script not found: %ANTSCRIPT%
   echo.
   pause
   goto END

:START
REM Set JAVA_HOME by calling java_env
if exist "%DLC%\bin\java_env.bat" (
    call "%DLC%\bin\java_env.bat"
)

REM Use the PowerShell utility to execute the Ant utility with all given parameters
PowerShell.exe -executionpolicy bypass -File "%~dpn0.ps1" %*

goto END

:END
