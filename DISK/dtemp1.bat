@echo off
if "%3" == "386MAX%2.1" goto nopause
echo Insert disk for %3 and
pause
:nopause
volfilt x:\apps\release\vl %1 386MAX  >dtemp2.bat
call dtemp2
echo on
x:\apps\release\xc /r/v %3 %1:386MAX.*
x:\apps\release\ntouch %1:*.* 
x:\apps\release\fmode %1:*.* /n
x:\apps\release\ff %1:
