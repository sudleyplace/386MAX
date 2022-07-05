;' $Header:   P:/PVCS/MAX/VXD/BREAK.INV   1.0   05 Sep 1995 17:20:58   HENRY  $
;
; (C) Copyright 1990-93 Qualitas, Inc.	GNU General Public License version 3.
;
; BREAK.INC
;
; BREAK macro
;
; BREAK macro usage cases:
; 1 - BREAK			; Unconditional breakpoint
; 2 - BREAK LBL 		; Unconditional breakpoint, define public label
; 3 - BREAK FLG,MSK		; Conditional breakpoint
; 4 - BREAK FLG,MSK,LBL 	; Conditional breakpoint, define public label

BREAK	 macro	 FLG,MSK,LBL
	 local	 L2
ifnb	 <FLG>			; Case 2, 3, or 4
 ifnb	 <MSK>			; Case 3 or 4
	 test	 FLG,MSK	; Test option bit
	 jz	 short L2	; Skip breakpoint if bit is not set
	 int	 01h		; Trigger the debugger
 else				; Case 2

  ifdef @DEBUG
    if1
% %OUT FIXME - Unguarded INT 1 in BREAK macro in procedure @CurProc
    endif			; IF1
	 int	 01h		; Call the debugger
  else
    if1
% %OUT Debugging disabled - Unguarded BREAK macro in procedure @CurProc ignored
    endif			; IF1
  endif 			; IFDEF @DEBUG

 endif				; IFNB <MSK>
else				; Case 1

  ifdef @DEBUG
    if1
% %OUT FIXME - Unguarded INT 1 in BREAK macro in procedure @CurProc
    endif			; IF1
	 int	 01h		; Call the debugger
  else
    if1
% %OUT Debugging disabled - Unguarded BREAK macro in procedure @CurProc ignored
    endif			; IF1
  endif 			; IFDEF @DEBUG

endif				; IFNB <FLG>
L2:

ifnb	 <FLG>			; FLG present -- case 2, 3, or 4
 ifnb	 <MSK>			; FLG, and MSK present -- case 3 or 4
  ifnb	 <LBL>			; FLG, MSK, and LBL present -- case 4
	 public  LBL
LBL	 label	 near
  endif 			; IFNB <LBL>
 else				; <MSK> not present -- case 2
	 public  FLG
FLG	 label	 near
 endif				; IFNB <MSK>
endif				; IFNB <FLG>

	 endm			; BREAK macro

