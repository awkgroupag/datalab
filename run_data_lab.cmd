:: WARNING: be sure to safe this file with UTF-8 encoding, e.g. using notepad++
:: Usage: you can optionally call this script with the path to myvalues.yaml


@echo off
:: ensure that environment variables will be deleted after programm termination
setlocal

set VALUES_PATH=.\lab\myvalues.yaml

:: Use command line argument as VALUES_PATH if available
if not "%~1"=="" (set VALUES_PATH=%1)
echo Using values file %VALUES_PATH%

if not exist %VALUES_PATH% (
    echo ERROR: file %VALUES_PATH% not found!
    echo Please edit %VALUES_PATH%.EXAMPLE and save it as %VALUES_PATH%
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

:: Ugly hack: find the line(s) starting with "namespace:", then
:: safe the value in environment variable
:::::::::::::::::::::::::::::::::::::::::
:: Loop through all the lines of the myvalues.yaml file that start with
:: the string "namespace:" (lines starting with spaces are ignored)
for /f "tokens=*" %%i in ('"FINDSTR /B namespace: %VALUES_PATH%"') do set root=%%i
:: A "string" on YAML side could come along like this:
::      namespace: my-namespace
::      namespace: 'my-namespace'
::      namespace: "my-namespace"
:: Remove any ' from the string
set root=%root:'=%
:: Remove any " from the string
set root=%root:"=%
if "%root%"=="" (
    echo ERROR: You must provide a value for namespace in myvalues.yaml!
    echo Please edit %VALUES_PATH% and add a string value for namespace
    pause
    goto end_of_file
)
:: Extract the actual value for the key
:: Mind the additional space after namespace: !!!
SET divider=namespace: 
:: Get only the part of the string AFTER the divider
CALL SET NAMESPACE=%%root:*%divider%=%%
if "%NAMESPACE%"=="default" (
    echo ERROR: do NOT use the default Kubernetes namespace "default"!
    echo Please edit %VALUES_PATH% and change the namespace
    pause
    goto end_of_file
)
echo Using Kubernetes namespace: %NAMESPACE%

:: Same ugly hack for "projectname:"
::::::::::::::::::::::::::::::::
for /f "tokens=*" %%i in ('"FINDSTR /B projectname: %VALUES_PATH%"') do set root=%%i
:: Switch codepage back. In the author's case, codepage 850 was used
chcp %CHCP_CURRENT% >nul
:: Remove any ' from the string
set root=%root:'=%
:: Remove any " from the string
set root=%root:"=%
if "%root%"=="" (
    echo ERROR: You must provide a value for projectname in myvalues.yaml!
    echo Please edit %VALUES_PATH% and add a string value for projectname
    pause
    goto end_of_file
)
:: Mind the additional space after projectname: !!!
SET divider=projectname: 
CALL SET PROJECTNAME=%%root:*%divider%=%%
echo Using projectname (helm release): %PROJECTNAME% 

:: Fire up helm & Kubernetes
echo.
echo Firing up Kubernetes with helm
echo If you haven't downloaded any images yet, this could take a while (need to download a couple of GB)
echo.

:: This command will display helm's NOTES.txt
:: helm might still fail due to a variety of reasons - but should say why
helm upgrade --install -n %NAMESPACE% --create-namespace -f %VALUES_PATH% --wait %PROJECTNAME% .\lab\jupyter

echo.
echo.
echo ....waiting for the Kubernetes secret to be deployed....
echo.
echo.

::
:: Wait until the Kubernetes secret is really ready (--wait above is not enough)
::
set COUNTER=0
:wait_for_token
:: Wait for a second
timeout /t 1 /nobreak >nul 2>nul
:: Try to grab the Jupyter URL (output of exactly the same "helm upgrade..." command above)
:: We look for any line containing the string "Jupyterlab:"
for /F "tokens=* USEBACKQ" %%F IN (`"helm upgrade --install -n %NAMESPACE% --create-namespace -f %VALUES_PATH% --wait %PROJECTNAME% .\lab\jupyter | findstr "Jupyterlab:""`) DO (
    set URL=%%F
)
:: Mind the extra space after Jupyterlab: !!!
SET divider=Jupyterlab: 
:: Get the URL piece only
CALL SET URL=%%URL:*%divider%=%%

set /A COUNTER=COUNTER+1
if "%URL%" == "" if %COUNTER% LSS 30 goto wait_for_token
:: Once counter is reached, we did not get a token
if "%URL%" == "" goto error_empty_url

:: output the full URL for access with ingress on k3s
echo Use the following URL to access %PROJECTNAME%'s Jupyter Notebook:
echo.
echo    %URL%
echo.
echo If you get an error "bad gateway", just refresh the page after a couple
echo of seconds
echo.
:: Start Chrome
start chrome %URL%
goto end_of_file


:error_empty_url
echo.
echo ERROR: Something went wront: no URL found for %PROJECTNAME% :-(
echo.
pause

:end_of_file
IF NOT %CHCP_CURRENT%=="" (
    :: Switch codepage back. In the author's case, codepage 850 was used
    chcp %CHCP_CURRENT% >nul
)
