@echo off
rem $Header:   P:/PVCS/MAX/BLDSRV.BAV   1.0   15 Sep 1995 17:42:22   HENRY  $

Rem Check for required environment variables
echo Check for required environment variables
set __BSERR=0
if "%__BSERR%" == "0" goto envOK1
echo Not enough environment space.  Increase /E:xxxx in CONFIG.SYS SHELL line.

:envOK1
if not "%MBLDOUT%" == "" goto envOK2
echo Required environment variable MBLDOUT not set.
echo Example: SET MBLDOUT=x:\apps\release\max8.out
set __BSERR=1

:envOK2
if not "%MBLDREQ%" == "" goto envOK3
echo Required environment variable MBLDREQ not set.
echo Example: SET MBLDREQ=x:\apps\release\max8\buildreq\
set __BSERR=1

:envOK3
if "%__BSERR%" == "0" goto envOK4
set __BSERR=
echo.
echo Once you've set the required environment variables, restart %0
goto end2

:envOK4
set __BSERR=
goto checkfirst

:checkagain
echo Checking again
%MAXROOT%
cd %MAXROOT%.
echo Qualitas Build services batch file for MAX 8
echo Checking for activity...
systime
delay 30
if errorlevel 1 goto end

:checkfirst
if exist %MBLDREQ%semaphor goto locked
for %%f in (%MBLDREQ%*.*) do if not exist %MAXROOT%makeit.err call %MAXROOT%bldsrv2 %%f
if exist %MAXROOT%makeit.err %MAXROOT%makeit WAITERR
Rem On exit from makeit.bat we'll delete makeit.err and restart bldsrv
goto checkagain

:locked
type %MBLDREQ%semaphor
echo has the build request queue locked.
goto checkagain

:end
echo Escape pressed, exiting...

:end2
