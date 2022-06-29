@echo off
REM $Header:   P:/PVCS/MAX/INCLUDE/UDLOCAL2.BAV   1.1   08 Aug 1995 16:25:04   HENRY  $
REM
REM Update batch file for include
REM
REM Check required environment variables.

set _PROJ=%PROJ%
set PROJ=include
REM This is redundant if invoked by UDLOCAL.EXE.
if "%MAXROOT%" == "" goto badvars

REM Needed by dependencies in include.MAK
if "%MSVC%" == "" goto badvars

REM Check for required directories.
echo Checking directories...
vdir -c %MAXROOT%
vdir -c %MAXROOT%lib %MAXROOT%%PROJ%

REM Get files in MAXROOT
echo Getting updated files in %MAXROOT%
delay 8
if errorlevel 1 goto end
%MAXROOT%
cd %MAXROOT%.
xc /n/a p:\max\pvcs.cfg
xc /n/a p:\max\lib %MAXROOT%lib
get -u $(ALL)

REM Get project files
echo Getting updated files in %MAXROOT%%PROJ%
cd %MAXROOT%%PROJ%
xc /n/a p:\max\%PROJ%\pvcs.cfg
get -u $(ALL)

echo Done.
goto end

:badvars
echo The following environment variables are not defined:
if "%MAXROOT%" == "" echo MAXROOT (ex: c:\MAX\)
if "%MSVC%" == "" echo MSVC (ex: c:\msvc\)
echo.

:end
set PROJ=%_PROJ%
set _PROJ=
