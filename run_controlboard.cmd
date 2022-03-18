:: WARNING: be sure to safe this file with UTF-8 encoding, e.g. using notepad++
@echo off
:: ensure that environment variables will be deleted after programm termination
setlocal

:: You might want to customize these
set ENVIRONMENT_FILE_PATH=.\datalab-stacks\environment.env

:: use argument as ENVIRONMENT_FILE_PATH if available
if "%~1"=="" (
    echo no arguments given ..
) else (
    set ENVIRONMENT_FILE_PATH=%1
)
echo using environment file %ENVIRONMENT_FILE_PATH%

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
:: file. The environment variables will be used/referenced for the configuration
:: of k3s and the Jupyter Notebook.
:: Set environment variables from file. Skip lines starting with #
FOR /F "tokens=*" %%i in ('findstr /v /c:"#" %ENVIRONMENT_FILE_PATH%') do SET %%i

:: Switch codepage back
chcp %CHCP_CURRENT% >nul

:: check if configured file paths exist
if not exist "%DATALAB_SOURCECODE_DIR%" (
    echo ERROR: variable DATALAB_SOURCECODE_DIR is set to "%DATALAB_SOURCECODE_DIR%", but path does not exist!
    echo Please edit %ENVIRONMENT_FILE_PATH% to correct the path
    echo.
    pause
    goto end_of_file
)
if not exist "%DATALAB_DATA_DIR%" (
    echo ERROR: variable DATALAB_DATA_DIR is set to "%DATALAB_DATA_DIR%", but path does not exist!
    echo Please edit %ENVIRONMENT_FILE_PATH% to correct the path
    echo.
    pause
    goto end_of_file
)

:: convert paths from Windows to Linux/Unix resp. WSL
FOR /F "tokens=* USEBACKQ" %%F IN (`wsl -e wslpath "%DATALAB_SOURCECODE_DIR%"`) DO (
    SET DATALAB_SOURCECODE_DIR_UX=%%F
)
FOR /F "tokens=* USEBACKQ" %%F IN (`wsl -e wslpath "%DATALAB_DATA_DIR%"`) DO (
    SET DATALAB_DATA_DIR_UX=%%F
)

:: set the necessary configuration for our project, using templates to write the config files to DATALAB_DATA_DIR
echo Writing config files to %DATALAB_DATA_DIR%
:: controlboard.jupyter_notebook_config.py: set base_url
powershell -Command "(gc '%DATALAB_SOURCECODE_DIR%\datalab-stacks\controlboard\controlboard.jupyter_notebook_config.tmpl.py') -replace 'PROJECT_NAME', '%PROJECT_NAME%' | Out-File -encoding ASCII '%DATALAB_DATA_DIR%\%PROJECT_NAME%.jnc.py'"
:: controlboard.yml: path for volumes (data, work, config) and projectname for URLs, labels etc.
powershell -Command "(gc '%DATALAB_SOURCECODE_DIR%\datalab-stacks\controlboard\controlboard.tmpl.yml') -replace 'DATALAB_SOURCECODE_DIR', '%DATALAB_SOURCECODE_DIR_UX%' | ForEach-Object { $_ -replace 'PROJECT_NAME', '%PROJECT_NAME%' } | ForEach-Object { $_ -replace 'DATALAB_DATA_DIR', '%DATALAB_DATA_DIR_UX%' } | Out-File -encoding ASCII '%DATALAB_DATA_DIR%\%PROJECT_NAME%.yml'"

:: start controlboard with given configuration
kubectl apply -f "%DATALAB_DATA_DIR%\%PROJECT_NAME%.yml"

echo Waiting for pod %PROJECT_NAME% to spin up

::
:: Wait until Jupyter is really ready
::
set COUNTER=0
:wait_for_token
:: Wait for another second so the notebook is indeed listening
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
