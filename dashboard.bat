@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"

REM Default port
set PORT=8420

REM Check for --port argument
:parse_args
if "%~1"=="" goto run
if "%~1"=="--port" (
    set PORT=%~2
    shift
    shift
    goto parse_args
)
shift
goto parse_args

:run
REM Start server in background
set PY_EXE=%~dp0.venv\Scripts\python.exe
if exist "%PY_EXE%" (
    start "" "%PY_EXE%" -m harness --web --port %PORT%
) else (
    start "" python -m harness --web --port %PORT%
)

REM Wait for server to be ready (max 30 seconds)
set /a WAIT_COUNT=0
:wait_loop
curl -s http://localhost:%PORT%/ >nul 2>&1
if %errorlevel% equ 0 goto open_browser
if %WAIT_COUNT% geq 30 goto timeout
timeout /t 1 /nobreak >nul
set /a WAIT_COUNT+=1
goto wait_loop

:open_browser
echo Opening dashboard at http://localhost:%PORT%/
start http://localhost:%PORT%/
goto end

:timeout
echo Timeout waiting for server. Check if port %PORT% is in use.
goto end

:end
endlocal
