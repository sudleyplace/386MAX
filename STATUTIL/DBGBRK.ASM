; '$Header:   P:/PVCS/MAX/STATUTIL/DBGBRK.ASV   1.0   25 Sep 1996 10:14:50   BOB  $
	TITLE	DBGBRK.ASM
	.386
	OPTION READONLY
	OPTION OLDSTRUCTS
	include CPUFLAGS.INC

IFNDEF IS_16
IFNDEF IS_32
%out command line error: specify one of -DIS_16, -DIS_32
.err
ENDIF  ;IS_32
ENDIF  ;IS_16


IFDEF IS_32
IFDEF IS_16
%out command line error: you can't specify both -DIS_16 and -DIS_32
.err
ENDIF ;IS_16

;************************* START OF 32-BIT CODE *************************

	.model FLAT,C
	.code

	public	DbgBrk
DbgBrk	proc	near		; Start DbgBrk procedure

COMMENT |

Signal a debug breakpoint

|

DB_STR	struc

	dd	?		; Caller's EBP
DB_FL	dd	?		; ...	   EFL

DB_STR	ends

	pushfd			; Save the flags
	push	ebp		; Prepare to address the stack
	mov	ebp,esp 	; Hello, Mr. Stack
	or	[ebp].DB_FL,mask $TF ; TF=1
	pop	ebp		; Restore
	popfd			; Put TF into effect

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DbgBrk	endp			; End DbgBrk procedure

	public	DbgStop
DbgStop proc	near		; Start DbgStop procedure

COMMENT |

Signal a debug stoppoint

|

	int	03h		; Stop here

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DbgStop endp			; End DbgStop procedure

ELSE

;************************* START OF 16-BIT CODE *************************

	OPTION SEGMENT:USE16
	.model LARGE,PASCAL

	.code

	public	_DbgBrk
_DbgBrk proc	far		; Start _DbgBrk procedure

COMMENT |

Signal a debug breakpoint

|

DB_STR	struc

	dw	?		; Caller's BP
DB_FL	dw	?		; ...	   FL

DB_STR	ends

	pushf			; Save the flags
	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack
	or	[bp].DB_FL,mask $TF ; TF=1
	pop	bp		; Restore
	popf			; Put TF into effect

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

_DbgBrk endp			; End _DbgBrk procedure

	public	_DbgStop
_DbgStop proc	far		; Start _DbgStop procedure

COMMENT |

Signal a debug stoppoint

|

	int	03h		; Stop here

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

_DbgStop endp			; End _DbgStop procedure

ENDIF
	END
