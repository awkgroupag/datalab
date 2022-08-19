:: WARNING: be sure to safe this file with UTF-8 encoding, e.g. using
:: notepad++
:: Usage: you can optionally call this script with --values_file and/or 
:: --controlboard:
::
::      run_jupyter.cmd --values_file=<PATH TO myvalues.yaml> --controlboard
::
:: --controlboard will grant the Jupyter Notebook Kubernetes priviledges
:: to e.g. run any Kubernetes helm chart

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
    echo     Ignoring them!
    echo.
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
if "%controlboard%"=="Y" (
    echo This Jupyter Notebook can function as "Controlboard". It will be
    echo granted special Kubernetes priviledges for your Kubernetes namespace.
    echo The Jupyter Notebook's GUI will be black to remind you of that fact.
    echo.
    :: Mind the extra space after Controlboard: !!!
    set URL_DIVIDER=Controlboard: 
) else (
    echo This Jupyter Notebook will NOT function as controlboard.
    :: Mind the extra space after Jupyterlab: !!!
    set URL_DIVIDER=Jupyterlab: 
)


:: Switch the windows codepage to utf-8 to let us read files correctly
:: Do this temporarily to not mess with other programs - safe the current value
for /F "tokens=2 delims=:" %%i in ('chcp') do set "CHCP_CURRENT=%%i"
:: Get rid of the period. at the end
set CHCP_CURRENT=%CHCP_CURRENT:~0,-1%
:: Change codepage to utf-8
chcp 65001 >nul

:: Ugly hack: find the line(s) starting with "namespace:", then
:: safe the value in environment variable
:::::::::::::::::::::::::::::::::::::::::
:: Loop through all the lines of the myvalues.yaml file that start with
:: the string "namespace:" (lines starting with spaces are ignored)
for /f "tokens=*" %%i in ('"FINDSTR /B namespace: %values_file%"') do set root=%%i
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
    echo Please edit %values_file% and add a string value for namespace
    pause
    goto end_of_file
)
:: Extract the actual value for the key
:: Mind the additional space after namespace: !!!
set divider=namespace: 
:: Get only the part of the string AFTER the divider
call set NAMESPACE=%%root:*%divider%=%%
if "%NAMESPACE%"=="default" (
    echo ERROR: do NOT use the default Kubernetes namespace "default"!
    echo Please edit %values_file% and change the namespace
    pause
    goto end_of_file
)
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
echo Using jupyterReleaseName helm release name: %JUPYTERRELEASENAME%

:: Fire up helm & Kubernetes
echo.
echo Firing up Kubernetes with helm
echo If you haven't downloaded any images yet, this could take a while (need to download a couple of GB)
echo.

set CMD=helm upgrade --install -n %NAMESPACE% --create-namespace -f %values_file% --wait %JUPYTERRELEASENAME% %HELM_PATH%
if "%controlboard%"=="Y" (
    set "CMD=%CMD% --set controlboard=true"
)
echo.
echo ======================================================================================
echo.

:: This command will display helm's NOTES.txt
:: helm might still fail due to a variety of reasons - but should say why
%CMD%

echo.
echo ======================================================================================
echo.
echo.
echo ....waiting for the Kubernetes secret to be deployed....
echo.
echo.

::
:: Wait until the Kubernetes secret is really ready (--wait above is not enough)
::
set COUNTER=0
:::::::::::::::
:wait_for_token
:::::::::::::::
:: Wait for a second
timeout /t 1 /nobreak >nul 2>nul
:: Try to grab the Jupyter URL (output of exactly the same "helm upgrade..." command above)
:: We look for any line containing the string "Jupyterlab:"
for /F "tokens=* USEBACKQ" %%F IN (`"%CMD% | findstr "%URL_DIVIDER%""`) DO (
    set URL=%%F
)
:: Get the URL piece only
call set URL=%%URL:*%URL_DIVIDER%=%%

set /A COUNTER=COUNTER+1
if "%URL%" == "" if %COUNTER% LSS 30 goto wait_for_token
:: Once counter is reached, we did not get a token
if "%URL%" == "" goto error_empty_url

:: output the full URL for access with ingress on k3s
echo.
echo Use the following URL to access %NAMESPACE% / %JUPYTERRELEASENAME%'s Jupyter Notebook:
echo.
echo    %URL%
echo.
echo If you get an error "bad gateway", just refresh the page after a couple of seconds
echo.
:: Start Chrome
start chrome %URL%
goto end_of_file



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



::::::::::::::::
:error_empty_url
::::::::::::::::
echo.
echo ERROR: Something went wront: no URL found for %NAMESPACE% / %JUPYTERRELEASENAME% :-(
echo.
pause
goto :end_of_file


::::::::::::
:end_of_file
::::::::::::
if not "%CHCP_CURRENT%"=="" (
    :: Switch codepage back. In the author's case, codepage 850 was used
    chcp %CHCP_CURRENT% >nul
)
