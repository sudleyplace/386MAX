@echo off
:NEXT
if "%1" == "" goto END
c:\bin\fmode/r %1
shift
goto NEXT

:END
