@echo off
set PORT=12334

docker-compose -f controlboard.yml up -d

echo Waiting for the controlboard to spin up on port %PORT%

:loop
timeout /t 1 /nobreak >nul 2>nul
:: Beware: netstat output depends on Windows locale. Also, Umlaute are a pain
netstat -nao | findstr "0:%PORT%" | findstr "LISTENING ABH" >nul 2>nul
if not %ERRORLEVEL% equ 0 goto loop

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

:: Start Chrome
echo.
echo Use the following URL to access your controlboard:
echo http://localhost:%PORT%/?token=%TOKEN%

start chrome http://localhost:%PORT%/?token=%TOKEN%
