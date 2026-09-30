@echo off
setlocal

set ARCHIVE=k6-tests.zip
set SMOKE=smoke*.json
set CONFIGS=stress-*.json
set TARGET_DIR=/home/ubuntu

for %%H in (k6-1 k6-2 k6-3 k6-4 k6-5) do (
    echo ==============================
    echo Uploading to %%H...

    scp %ARCHIVE% %SMOKE% %CONFIGS% %%H:%TARGET_DIR%/

    if errorlevel 1 (
        echo Failed to upload to %%H
    ) else (
        echo Successfully uploaded to %%H:%TARGET_DIR%/
    )
)

pause
