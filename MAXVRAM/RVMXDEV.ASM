	TITLE	RVMX	R:base Virtual Memory eXtender.
	SUBTTL Device driver (.SYS) version
	PAGE	60,132
;
;	Device driver (.SYS) version
;
DEV_DRIV EQU	1		; Enables device driver code
	INCLUDE RVMX.ASM
;
;	By the way, the reason for having two different cover programs
; is so that the .COM version can say "END MAIN" and the .SYS version
; can say 'END'
;
	END
