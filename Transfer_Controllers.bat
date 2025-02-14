@echo off
setlocal

:: Check if files are dragged onto the batch file
if "%~1"=="" (
	echo.
    echo Drag your stripped DMX file, controller source, or both onto this batch file.
	echo.
    pause
    exit /b
)

:: Check if more than two files are provided
if not "%~2"=="" if not "%~3"=="" (
	echo.
    echo ERROR: Too many files! Please provide only 1 or 2 files.
	echo.
    pause
    exit /b
)

powershell -ExecutionPolicy Bypass -File "Transfer_Controllers.ps1" "%~1" "%~2"
pause