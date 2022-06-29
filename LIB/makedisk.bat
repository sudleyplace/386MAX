		@echo off
		for %%f in (a,A,b,B) do if "%%f" == "%1" goto diskok
		if not "%2" == "" goto diskok
		echo No disk or invalid drive specified.
		echo Example: %0 a
		goto end
		:diskok
		REM %2 may be a directory stem, like \clip\henry\max8\disk
		REM If so, the copy procedure is slightly different.
		if not "%2" == "" goto disk1b
		echo Put disk 1 in drive %1 and
		pause
		x:\apps\release\rm -r %1:\*.*
		xc /r disk1 %1:\.
		x:\apps\release\vl %1:"QMAX8 1"
		echo Put disk 2 in drive %1 and
		pause
		xc /r disk2 %1:
		md %1:BCF
		xc /r disk2\BCF\@*.BCF %1:BCF\.
		x:\apps\release\vl %1:"QMAX8 2"
		goto disk3

:disk1b
		x:\apps\release\rm -r %1:%21\*.*
		vdir -c %1:%21
		xc /r disk1 %1:%21
		x:\apps\release\rm -r %1:%22\*.*
		x:\apps\release\rm -r %1:%22\BCF\*.*
		vdir -c %1:%22\BCF\*.*
		xc /r disk2 %1:%22
		xc /r disk2\BCF\@*.BCF %1:%22\BCF\.
		goto disk3

:disk3



:end
