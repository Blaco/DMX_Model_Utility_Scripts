@echo off
:: Ensure at least one file is passed
if "%~1"=="" (
    echo.
    echo Drag and drop DMX files onto this script to process.
    echo.
    pause
    exit /b
)

:: Build a quoted list of arguments for PowerShell
set args=
for %%A in (%*) do set args=%args% "%%~A"

:: Pass the quoted arguments to PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File "DMXConvert_Controllers.ps1" -Files %args%
pause
