@echo off
setlocal

set ARCHIVE=installer.zip
set TARGET_DIR=/home/ubuntu

for %%H in (load-dbteam) do (
    echo ==============================
    echo Uploading to %%H...

    scp %ARCHIVE% %%H:%TARGET_DIR%/

    if errorlevel 1 (
        echo Failed to upload to %%H
    ) else (
        echo Successfully uploaded to %%H:%TARGET_DIR%/
    )
)

pause
