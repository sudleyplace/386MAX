@echo off
REM $Header:   P:/PVCS/MAX/386MAX/UDBIN2.BAV   1.3   18 Mar 1996 12:37:18   BOB  $
REM
REM Copy binary batch file for 386max
REM

xc /vn /va 386max.	   x:\apps\386max
xc /vn /va bcf\386max.sys  x:\apps\386max
xc /vn /va bcf\386max.ssf  x:\apps\386max
xc /vn /va bcf\386util.com x:\apps\386max
xc /vn /va bcf\386util.ssf x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a    386max.	   x:\apps\386max
xc /n/a    bcf\386max.sys  x:\apps\386max
xc /n/a    bcf\386max.ssf  x:\apps\386max
xc /n/a    bcf\386util.com x:\apps\386max
xc /n/a    bcf\386util.ssf x:\apps\386max

:end
