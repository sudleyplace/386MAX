@echo off
REM $Header:   P:/PVCS/MAX/INSTALL/UDBIN2.BAV   1.2   11 Nov 1995 13:10:12   BOB  $
REM
REM Copy binary batch file for install
REM

xc /vn /va	MAXIB\MAXIB.EXE 	x:\apps\386max\setupdos.ovl
xc /vn /va	MAXIB\MAXIB.SSF 	x:\apps\386max\setupdos.ssf

xc /vn /va	COMN\QBRAND.EXE 	x:\apps\386max\.
xc /vn /va	COMN\QBRAND.SSF 	x:\apps\386max\.

delay 10
if errorlevel 1 goto end

xc /n/a 	MAXIB\MAXIB.EXE 	x:\apps\386max\setupdos.ovl
xc /n/a 	MAXIB\MAXIB.SSF 	x:\apps\386max\setupdos.ssf

xc /n/a 	COMN\QBRAND.EXE 	x:\apps\386max\.
xc /n/a 	COMN\QBRAND.SSF 	x:\apps\386max\.

:end
