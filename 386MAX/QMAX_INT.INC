
; QMAX_INT.INC

NRM_STR  struc			; Stack when no error code present

NRM_EIP   dd	 ?		; Caller's EIP
NRM_CS	  dw	 ?		;	   CS
NRM_INTNO dw	 ?		;	   INT # times 4 + offset PGROUP:INTPROC0Z
NRM_EFL   dd	 ?		;	   EFL

NRM_STR  ends

