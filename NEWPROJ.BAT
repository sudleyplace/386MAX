@echo off
REM $Header:   P:/PVCS/MAX/NEWPROJ.BAV   1.0   07 Aug 1995 14:25:12   HENRY  $
REM
REM NEWPROJ.BAT - Create a new project.
REM
REM This batch file creates skeleton UDBIN2.BAT and UDLOCAL2.BAT files,
REM creates all the required directories on P: and creates PVCS.CFG files.
REM

echo NEWPROJ - Create a new project on P:
if "%1" == "" goto synterr

set _D=$
if "%_D%" == "$" goto ENVOK

echo Not enough environment space - try %COMSPEC% /e:1200 /c %0
goto end

:ENVOK
echo This batch file will create P:\MAX\%1, P:\PVCS\MAX\%1, and create
echo various files needed for the %1 project.  Press Esc to quit if this
echo is NOT what you want to do...
x:\apps\pvcs\delay 600
if errorlevel 1 goto end

echo Checking directory structure...
vdir -c p:\max\%1 p:\pvcs\max\%1

p:
cd \max\%1

echo Checking for PVCS.CFG file...
if exist pvcs.cfg goto XPVCS
echo REFERENCEDIR=WRITEPROTECT P:\MAX\%1\*> pvcs.cfg
echo VCSDIR = P:\PVCS\MAX\%1\*>> pvcs.cfg
echo ALIAS ALL P:\PVCS\MAX\%1\*.*,p:\pvcs\max\%1\udlocal2.bav>> pvcs.cfg

:XPVCS
echo Checking for required batch files...
if exist udlocal2.bat goto XUDLOCAL
cl /nologo /E /C /DPRJ=%1 /DPHDR=%_D%Header$ p:\max\udlocal2.src |batcpp >udlocal2.bat
call wput -t"Copy source files to local system" udlocal2.bat

:XUDLOCAL
if exist udbin2.bat goto XUDBIN
cl /nologo /E /C /DPRJ=%1 /DPHDR=%_D%Header$ p:\max\udbin2.src |batcpp >udbin2.bat
call wput -t"Copy binary output to network" udbin2.bat

:XUDBIN

echo Done.
goto end

:synterr
echo Syntax:
echo %0 projname
echo where projname is a project name of up to 8 letters.

:end
set _D=
