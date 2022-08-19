:: WARNING: be sure to safe this file with UTF-8 encoding, e.g. using
:: notepad++
:: Usage: you can optionally call this script with --values_file and/or 
:: --controlboard:
::
::      delete_jupyter.cmd --values_file=<PATH TO myvalues.yaml> --controlboard
::
:: --controlboard will delete the helm chart named "controlboard"


@echo off
:: ensure that environment variables will be deleted after programm termination
setlocal

:: Read command line parameters
:: If an option is set, the string value will be used. Otherwise left empty
set OPTIONS=values_file
:: Any values here will be set to the string "Y" (without quotes) if passed as command
:: line argument, otherwise left empty
set SWITCHES=controlboard
call :readoptions %*
for %%i in (%OPTIONS% %SWITCHES% BADOPTIONS) do if defined %%i (
    set %%i >nul
)



if not "%BADOPTIONS%"=="" (
    echo.
    echo     WARNING: unknown command line arguments: %BADOPTIONS%
    echo     Aborting!
    echo.
    pause
    goto end_of_file
)
set HELM_PATH=.\lab\jupyter
if "%values_file%"=="" (
    set values_file=.\lab\myvalues.yaml
)
echo Using values file %values_file%
if not exist %values_file% (
    echo ERROR: file %values_file% not found!
    echo Please edit myvalues.yaml.EXAMPLE and save it e.g. as %values_file%
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
echo Using Kubernetes namespace/project name: %NAMESPACE%

:: Same ugly hack for "jupyterReleaseName:"
:::::::::::::::::::::::::::::::::::::::::::
if "%CONTROLBOARD%"=="Y" (
    set JUPYTERRELEASENAME=controlboard
) else (
    for /f "tokens=*" %%i in ('"FINDSTR /B jupyterReleaseName: %values_file%"') do set root=%%i
    :: Switch codepage back. In the author's case, codepage 850 was used
    chcp %CHCP_CURRENT% >nul
    :: Remove any ' from the string
    set root=%root:'=%
    :: Remove any " from the string
    set root=%root:"=%
    if "%root%"=="" (
        echo ERROR: You must provide a value for jupyterReleaseName in myvalues.yaml!
        echo Please edit %values_file% and add a string value for jupyterReleaseName
        pause
        goto end_of_file
    )
    :: Mind the additional space after jupyterReleaseName: !!!
    set divider=jupyterReleaseName: 
    call set JUPYTERRELEASENAME=%%root:*%divider%=%%
)
echo Using jupyterReleaseName (helm release name): %JUPYTERRELEASENAME%


:: helm might still fail due to a variety of reasons - but should say why
echo.
helm delete -n %NAMESPACE% %JUPYTERRELEASENAME%

if not "%NAMESPACE%"=="default" (
    echo.
    echo Almost all Kubernetes resources have been deleted
    echo If you want to also delete Secrets and PVCs to e.g.
    echo really start from scratch, type:
    echo.
    echo    kubectl delete namespace %NAMESPACE%
    echo.
)
goto :end_of_file

::::::::::::
:readoptions
::::::::::::
: This reads any options --option1 value 1 --option2 value 2
: and any switch ("toggling on") --switch1 --switch2
: passed to this *.cmd batch file
: See https://stackoverflow.com/questions/15420004/write-batch-file-with-hyphenated-parameters
for %%i in (%OPTIONS% %SWITCHES% BADOPTIONS) do (set %%i=)
:optlp
set _parm1=%1
:: TRICKY BIT, we need :EOF here as we have spawned multiple threads, apparently!
if not defined _parm1 goto :eof
for %%i in (%SWITCHES%) do if %_parm1%==--%%i set %%i=Y&(set _parm1=)
if not defined _parm1 shift&goto :optlp
for %%i in (%OPTIONS%) do if %_parm1%==--%%i (
    set %%i=%2
    if defined %%i shift&shift&(set _parm1=)
)
if defined _parm1 set BADOPTIONS=%BADOPTIONS% %1&shift
goto :optlp



::::::::::::
:end_of_file
::::::::::::
if not "%CHCP_CURRENT%"=="" (
    :: Switch codepage back. In the author's case, codepage 850 was used
    chcp %CHCP_CURRENT% >nul
)

