@echo off

:: Check if any files were dragged onto the batch script
if "%~1"=="" (
	echo.
    echo Drag a KeyValues2 DMX file onto this batch file to remove its embedded controllers.
	echo.
    pause
    exit /b
)

:: Check if more than two files are provided
if not "%~1"=="" if not "%~2"=="" (
	echo.
    echo ERROR: Too many files! Please provide only 1 file.
	echo.
    pause
    exit /b
)

powershell -ExecutionPolicy Bypass -File "Remove_Controllers.ps1" "%~1"
pause