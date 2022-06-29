@echo off
:NEXT
if "%1" == "" goto END
c:\bin\fmode/n %1
shift
goto NEXT

:END
