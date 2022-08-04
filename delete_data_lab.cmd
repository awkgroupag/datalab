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
:: echo Using Kubernetes namespace: %NAMESPACE%

:: Same ugly hack for "projectname:"
::::::::::::::::::::::::::::::::
for /f "tokens=*" %%i in ('"FINDSTR /B projectname: %VALUES_PATH%"') do set root=%%i
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
:: echo Using projectname (Kubernetes release): %PROJECTNAME% 

:: helm might still fail due to a variety of reasons - but should say why
helm delete -n %NAMESPACE% %PROJECTNAME%

if not "%NAMESPACE%"=="default" (
    echo.
    echo Almost all Kubernetes resources have been deleted
    echo If you want to also delete Secrets and PVCs, e.g.
    echo to really start from scratch, type:
    echo.
    echo    kubectl delete namespace %NAMESPACE%
    echo.
)

:end_of_file
IF NOT %CHCP_CURRENT%=="" (
    :: Switch codepage back. In the author's case, codepage 850 was used
    chcp %CHCP_CURRENT% >nul
)
