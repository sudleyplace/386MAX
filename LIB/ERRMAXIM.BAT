echo off
if not "%1" == "" goto %1
echo For some reason, Qualitas MAX did not install.  Please check for
echo error messages in CONFIG.SYS and rerun MAXIMIZE
pause
call C:\D\SOURCE\MAX\LIB\PREMAXIM.BAT C:\D\SOURCE\MAX\LIB\
autoexec
:PREMAXIM
echo Restoring files...
echo on
call R:\MAX\LIB\PREMAXIM.BAT
