@echo off
REM $Header:   P:/PVCS/MAX/QMT/UDBIN2.BAV   1.2   25 Jan 1996 14:19:44   BOB  $
REM
REM Copy binary batch file for qmt/ramexam
REM

xc /vn /va qmb\*.exe	 x:\apps\386max
xc /vn /va qmt\*.exe	 x:\apps\386max
xc /vn /va reb\*.exe	 x:\apps\386max
xc /vn /va ret\*.exe	 x:\apps\386max
xc /vn /va qmb\*.ssf	 x:\apps\386max
xc /vn /va qmt\*.ssf	 x:\apps\386max
xc /vn /va reb\*.ssf	 x:\apps\386max
xc /vn /va ret\*.ssf	 x:\apps\386max

delay 10
if errorlevel 1 goto end

xc /n/a    qmb\*.exe	 x:\apps\386max
xc /n/a    qmt\*.exe	 x:\apps\386max
xc /n/a    reb\*.exe	 x:\apps\386max
xc /n/a    ret\*.exe	 x:\apps\386max
xc /n/a    qmb\*.ssf	 x:\apps\386max
xc /n/a    qmt\*.ssf	 x:\apps\386max
xc /n/a    reb\*.ssf	 x:\apps\386max
xc /n/a    ret\*.ssf	 x:\apps\386max

:end
