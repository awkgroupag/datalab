@echo off
set PORT=12334
set DOCKER_NETWORK=datalab-network

echo Starting controlboard
docker network create %DOCKER_NETWORK% >nul 2>nul
docker-compose -f controlboard.yml up -d

echo Waiting for the controlboard to spin up on port %PORT%

::
:: Wait until Jupyter is really ready
::
set COUNTER=0
:wait_for_token
:: Wait for another second so the notebook is indeed listening
timeout /t 1 /nobreak >nul 2>nul
::Grab the Jupyter token
setlocal
for /F "tokens=* USEBACKQ" %%F IN (`"docker logs controlboard 2>&1 | findstr "http://127.0.0.1:8888/?token=""`) DO (
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
echo Use the following URL to access your controlboard:
echo http://localhost:%PORT%/?token=%TOKEN%

start chrome http://localhost:%PORT%/?token=%TOKEN%
goto end_of_file


:error_empty_token
echo.
echo ERROR: no token found for your Jupyter Notebook :-(
echo.

:end_of_file
