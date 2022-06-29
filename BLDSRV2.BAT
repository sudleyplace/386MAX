@echo off
rem $Header:   P:/PVCS/MAX/BLDSRV2.BAV   1.0   15 Sep 1995 17:42:24   HENRY  $
if "%1" == "" goto end
%MAXROOT%
cd %MAXROOT%.
copy %1 tempbat.bat
rm makeit.err
call tempbat
REM If an error exists, let 'em restart...
if exist %MAXROOT%makeit.err goto SEVERE_ERROR
del %1
goto end

:SEVERE_ERROR
echo !!! Build server stopped.	Use REQ RESET to try again or REQ FLUSH >>%BLDOUT%
echo !!! to clear all requests. >>%MBLDOUT%

:end
