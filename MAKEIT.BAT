@echo off
rem $Header:   P:/PVCS/MAX/MAKEIT.BAV   1.3   10 Nov 1995 17:15:50   HENRY  $

for %%f in (waiterr WaitErr WAITERR) do if "%1" == "%%f" goto waiterr

echo Building Max 8...
echo MAKEIT %1 %2 %3 %4 %5 %6 %7 %8 %9 in progress >%MAXROOT%makeit.err

rem Check for required environment variable
if "%MBLDOUT%" == "" goto nobldout
goto bldoutOK

:nobldout
echo MBLDOUT not set.
echo Example: SET MBLDOUT=x:\apps\release\max.out
goto end2

:bldoutOK
rem Invoke with default args if none specified
if "%1" == "" %0 GET BUILD

rem Set current drive and directory
%MAXROOT%
cd %MAXROOT%.

rem Set up output log
if exist %MBLDOUT% goto LOGEXIST

%COMSPEC% /c >%MBLDOUT%
flag %MBLDOUT% +srw

:LOGEXIST
rem Set up get command.  NMAKE has trouble with $(ALL) and also with
rem the quotes we'll need around labels.
if exist getcmd.bat goto BATEXIST
echo get -u -y $(ALL) >getcmd.bat

:BATEXIST
rem Make sure we've got the latest makefile
xc /n/a/t p:\max\max.mak %MAXROOT%*.*
xc /n/a/t p:\max\include\*.mak %MAXROOT%include\*.*
if exist %MAXROOT%maxtop.mrf goto nexttarg
echo BINDIR=x:\apps\release\max8\ DEBUG=1 ALPHA=%ALPHA% GETCMD="$(MAXROOT)getcmd" >%MAXROOT%maxtop.mrf

:nexttarg
rem Invoke makefile
echo Invoking %0 %1 >>%MBLDOUT%
systime >>%MBLDOUT%
if "%1" == "DISK" goto DISK
if "%1" == "DELALL" goto DELALL
@echo on
nmake /f max.mak TARGETS=%1 DALL=0 /x - @maxtop.mrf >>%MBLDOUT%
@echo off
if errorlevel 1 goto buildfail
goto COMMON
:DISK
nmake /f max.mak /x - %1 @maxtop.mrf >>%MBLDOUT%
if errorlevel 1 goto buildfail
goto COMMON
:DELALL
nmake /f max.mak TARGETS=%1 DALL=1 /x - @maxtop.mrf >>%MBLDOUT%
if errorlevel 1 goto buildfail
goto COMMON
:COMMON
shift
if "%1" == "" goto end
goto nexttarg

:end
echo Build complete.
echo Build completed. >>%MBLDOUT%
systime >>%MBLDOUT%
:end1
del %MAXROOT%makeit.err
goto end2

:buildfail
echo %1 failed.
echo %1 failed. >>%MBLDOUT%
goto end2

:waiterr
REM Build is stopped.  Wait until we can resume.
mydelay 10 Build stopped; waiting for RESET or FLUSH.  Esc to abort.
if errorlevel 1 goto end2
if exist %MBLDREQ%flush goto errflush
if exist %MBLDREQ%reset goto errreset
goto waiterr

:errflush
echo Flushing all pending requests >>%MBLDOUT%
ff %MBLDREQ%*.* >>%MBLDOUT%
rm %MBLDREQ%*.* %MAXROOT%makeit.err
%MAXROOT%bldsrv
goto end1

:errreset
echo Restarting pending requests after error >>%MBLDOUT%
rm %MBLDREQ%reset %MAXROOT%makeit.err
ff %MBLDREQ%*.* >>%MBLDOUT%
%MAXROOT%bldsrv
goto end1

:end2

