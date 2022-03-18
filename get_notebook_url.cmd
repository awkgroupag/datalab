:: WARNING: be sure to safe this file with UTF-8 encoding, e.g. using notepad++
@echo off
:: ensure that environment variables will be deleted after programm termination
setlocal

:: use argument as project name if available .. no need to read environment file in this case
if ["%~1"]==[""] (
    echo "no arguments given"
) else (
    set PROJECT_NAME=%1
    goto start_get_token
)

:: You might want to customize these
set ENVIRONMENT_FILE_PATH=.\datalab-stacks\environment.env

if not exist %ENVIRONMENT_FILE_PATH% (
    echo ERROR: Environment file %ENVIRONMENT_FILE_PATH% not found!
    echo Please edit %ENVIRONMENT_FILE_PATH%.EXAMPLE and save it as %ENVIRONMENT_FILE_PATH%
    echo.
    pause
    goto end_of_file
)

:: Switch the windows codepage to utf-8 to let us read files correctly
:: Do this temporarily to not mess with other programs - safe the current value
FOR /F "tokens=2 delims=:" %%i IN ('chcp') DO SET "CHCP_CURRENT=%%i"
:: Get rid of the period. at the end
SET CHCP_CURRENT=%CHCP_CURRENT:~0,-1%
:: Change codepage to utf-8
CHCP 65001 >nul

:: Need to set the Windows environment variables from a dedicated environment
:: file. The environmnent variables will be used/referenced within the
:: docker-compose.yml
:: Set environment variables from file. Skip lines starting with #
FOR /F "tokens=*" %%i in ('findstr /v /c:"#" %ENVIRONMENT_FILE_PATH%') do SET %%i

:: Switch codepage back
chcp %CHCP_CURRENT% >nul

:start_get_token
::
:: Wait until Jupyter is really ready
::
set COUNTER=0
:wait_for_token
:: Wait for another second so the notebook is indeed listening (could be Juypter Lab or Controlboard)
timeout /t 1 /nobreak >nul 2>nul
::Grab the Jupyter token
for /F "tokens=* USEBACKQ" %%F IN (`"kubectl logs %PROJECT_NAME% | findstr "http://127.0.0.1""`) DO (
    set TOKENSTRING=%%F
)
:: TOKENSTRING equals to e.g. (without quotes!)
:: "or http://127.0.0.1:8888/lab?token=12731f22eb89f18eac573c92989411bcdf7e22f0bc8f4ec3"
for /F "tokens=1-2 delims==" %%i in ("%TOKENSTRING%") do (  
    set TOKEN=%%j
)
set /A COUNTER=COUNTER+1
if "%TOKEN%" == "" if %COUNTER% LSS 30 goto wait_for_token
:: Once counter is reached, we did not get a token
if "%TOKEN%" == "" goto error_empty_token

:: output the full URL for access with ingress on k3s
echo Use the following URL to access your controlboard:
echo https://localhost/%PROJECT_NAME%/lab?token=%TOKEN%

:: Start Chrome
start chrome https://localhost/%PROJECT_NAME%/lab?token=%TOKEN%
goto end_of_file


:error_empty_token
echo.
echo ERROR: no token found for controlboard %PROJECT_NAME% :-(
echo.

:end_of_file
