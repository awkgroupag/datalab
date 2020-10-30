@echo off
:: ensure that environment variables will be deleted after programm termination
setlocal
:: You might want to customize these
set APPNAME=Jupyterlab Notebook
set ENVIRONMENT_FILE_PATH=.\datalab-stacks\environment.env

if not exist %ENVIRONMENT_FILE_PATH% (
    echo ERROR: Environment file %ENVIRONMENT_FILE_PATH% not found!
    echo Please edit %ENVIRONMENT_FILE_PATH%.EXAMPLE and save it as %ENVIRONMENT_FILE_PATH%
    echo.
    goto end_of_file
)

:: Need to set the Windows environment variables from a dedicated environment
:: file. The environmnent variables will be used/referenced within the
:: docker-compose.yml
:: Set environment variables from file. Skip lines starting with #
FOR /F "tokens=*" %%i in ('findstr /v /c:"#" %ENVIRONMENT_FILE_PATH%') do SET %%i
:: set Docker's environemtn variable COMPOSE_FILE - this way we can deal with
:: SEVERAL docker-composes in ONE environment.env
set COMPOSE_FILE=.\datalab-stacks\%DATALAB_JUPYTER_COMPOSE_PATH%

:: Make sure that the Docker network exists
docker network create %DATALAB_DOCKER_NETWORK% >nul 2>nul
:: Use env files for docker-compose
docker-compose up -d


echo Waiting for %APPNAME% to spin up on port %DATALAB_JUPYTER_PORT%

::
:: Wait until Jupyter is really ready
::
set COUNTER=0
:wait_for_token
:: Wait for another second so the notebook is indeed listening
timeout /t 1 /nobreak >nul 2>nul
::Grab the Jupyter token
for /F "tokens=* USEBACKQ" %%F IN (`"docker-compose logs jupyter 2>&1 | findstr "http://127.0.0.1:8888/?token=""`) DO (
    set TOKENSTRING=%%F
)
:: TOKENSTRING equals to e.g. (without quotes!)
:: "or http://127.0.0.1:8888/?token=12731f22eb89f18eac573c92989411bcdf7e22f0bc8f4ec3"
for /F "tokens=1-2 delims==" %%i in ("%TOKENSTRING%") do (  
    set TOKEN=%%j
)
set /A COUNTER=COUNTER+1
if "%TOKEN%" == "" if %COUNTER% LSS 30 goto wait_for_token
:: Once counter is reached, we did not get a token
if "%TOKEN%" == "" goto error_empty_token


:: Start Chrome
echo.
echo Use the following URL to access the %APPNAME%:
echo http://localhost:%DATALAB_JUPYTER_PORT%/?token=%TOKEN%

start chrome http://localhost:%DATALAB_JUPYTER_PORT%/?token=%TOKEN%
goto end_of_file


:error_empty_token
echo.
echo ERROR: no token found for %APPNAME% :-(
echo.

:end_of_file
