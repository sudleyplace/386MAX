;' $Header:   P:/PVCS/MAX/386MAX/UTIL_STK.ASV   1.2   30 May 1997 10:46:40   BOB  $
	 title	 UTIL_STK -- 386MAX Utility Program -- STACKS
	 page	 58,122
	 name	 UTIL_STK

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-7 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'

Program derived from:  None.

Original code by:  Bob Smith, May, 1992.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include EMM2CALL.INC
	 include PTR.INC
	 include 8259.INC

	 include QMAX_CFG.INC
	 include QMAX_STK.INC
	 include QMAX_OEM.INC
.list

PGROUP	 group	 CODE,DATA,NCODE,NDATA


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

if @OEM_WIN3
	 extrn	 MSG_WINERR:byte
	 extrn	 WINRUN:byte
endif				; IF @OEM_WIN3

	 extrn	 PORT67:word

	 extrn	 CNTBUF:byte
	 extrn	 CNTBUF_CNT:byte
	 extrn	 CNTBUF_ISIZ:byte
	 extrn	 CNTBUF_MPIC:byte
	 extrn	 CNTBUF_SPIC:byte
	 extrn	 CNTBUF_TAIL:byte
	 extrn	 CNTBUF_STATE:byte
	 extrn	 CNTBUF_STATE_ON:byte
	 extrn	 CNTBUF_STATE_ON_LEN:abs
	 extrn	 CNTBUF_STATE_OFF:byte
	 extrn	 CNTBUF_STATE_OFF_LEN:abs

	 extrn	 MSG_DSTKS_ON:byte
	 extrn	 MSG_DSTKS_OFF:byte

DATA	 ends			; End DATA segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 public  DSTK_CNT,DSTK_ISIZ,DSTK_OVF,DSTK_INTS,DSTK_STAT
DSTK_CNT dw	 ?		; # DOS stacks
DSTK_ISIZ dw	 ?		; Size of each DOS stack
DSTK_OVF dw	 0		; Overflow from previous stack(s)
DSTK_INTS dw	 ?		; HW interrupts intercepted (bitmap)
DSTK_STAT dw	 ?		; DOS stacks state:  see DSTK_REC

	 public  LCLBUF
LCLBUF	 db	 '³ '
LCLBUF_SEG db	 '____:'
LCLBUF_OFF db	 '____ ³ '
LCLBUF_STA db	 '________ ³ '
LCLBUF_TOPSEG db '____:'
LCLBUF_TOPOFF db '____ ³     '
LCLBUF_DEPTH db  '_ ³',CR,LF,EOS

NDATA	 ends			; End NDATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 STROUT:near

NCODE	 ends			; End NCODE segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 CHECK_STATE:near
	 extrn	 BIN2BASE:near
	 extrn	 DB2HEX:near
	 extrn	 DW2HEX:near
	 extrn	 DD2HEX:near

	 NPPROC  ACT_STACKS_ON -- Action To Enable Stacks Usage
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable stacks usage

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,dx,bp>	; Save registers

if @OEM_WIN3
	 cmp	 WINRUN,1	; Are we running under Windows?
	 je	 short ACT_STACKS_ON_WINERR ; Jump if so
endif				; IF @OEM_WIN3

	 call	 CHECK_STATE	; Attempt to go ON or AUTO active
	 jc	 short ACT_STACKS_ON_ERR ; Jump if not successful

	 mov	 bp,sp		; Save stack pointer
	 mov	 al,@DSTKS_SETSTATE ; Function code to set DOS stacks state
	 mov	 bl,0		; Enabling value
	 EMMOUT  @EMM2_DSTKS	; Enable 'em

	 mov	 sp,bp		; Restore

	 or	 ah,ah		; Check return code
	 jnz	 short ACT_STACKS_ON_ERR ; Something went wrong

	 lea	 dx,MSG_DSTKS_ON ; DS:DX ==> message
	 call	 STROUT 	; Display the string at DS:DX

	 clc			; Indicate all went well

	 jmp	 short ACT_STACKS_ON_EXIT ; Join common exit code

if @OEM_WIN3
ACT_STACKS_ON_WINERR:
	 lea	 dx,MSG_WINERR	; DS:DX ==> error message
	 call	 STROUT 	; Display the string at DS:DX
endif				; IF @OEM_WIN3
ACT_STACKS_ON_ERR:
	 stc			; Indicate something went wrong
ACT_STACKS_ON_EXIT:
	 REGREST <bp,dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_STACKS_ON endp		; End ACT_STACKS_ON procedure
	 NPPROC  ACT_STACKS_OFF -- Action To Disable Stacks Usage
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable stacks usage

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,dx,bp>	; Save registers

if @OEM_WIN3
	 cmp	 WINRUN,1	; Are we running under Windows?
	 je	 short ACT_STACKS_OFF_WINERR ; Jump if so
endif				; IF @OEM_WIN3

	 call	 CHECK_STATE	; Attempt to go ON or AUTO active
	 jc	 short ACT_STACKS_OFF_ERR ; Jump if not successful

	 mov	 bp,sp		; Save stack pointer
	 mov	 al,@DSTKS_SETSTATE ; Function code to set DOS stacks state
	 mov	 bl,mask $DSTK_GLBOFF ; Disabling value
	 EMMOUT  @EMM2_DSTKS	; Enable 'em

	 mov	 sp,bp		; Restore

	 or	 ah,ah		; Check return code
	 jnz	 short ACT_STACKS_OFF_ERR ; Something went wrong

	 lea	 dx,MSG_DSTKS_OFF ; DS:DX ==> message
	 call	 STROUT 	; Display the string at DS:DX

	 clc			; Indicate all went well

	 jmp	 short ACT_STACKS_OFF_EXIT ; Join common exit code

if @OEM_WIN3
ACT_STACKS_OFF_WINERR:
	 lea	 dx,MSG_WINERR	; DS:DX ==> error message
	 call	 STROUT 	; Display the string at DS:DX
endif				; IF @OEM_WIN3
ACT_STACKS_OFF_ERR:
	 stc			; Indicate something went wrong
ACT_STACKS_OFF_EXIT:
	 REGREST <bp,dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_STACKS_OFF endp		; End ACT_STACKS_OFF procedure
	 NPPROC  ACT_STACKS -- Action To Display Stacks Usage
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display stacks usage

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,bx,cx,dx,si,bp,fs> ; Save registers

if @OEM_WIN3
	 cmp	 WINRUN,1	; Are we running under Windows?
	 je	 short ACT_STACKS_WINERR ; Jump if so
endif				; IF @OEM_WIN3

	 call	 CHECK_STATE	; Attempt to go ON or AUTO active
	 jc	 short ACT_STACKS_ERR ; Jump if not successful

	 push	 es		; Save for a moment

	 mov	 bp,sp		; Save stack pointer
	 mov	 al,@DSTKS_GETINFO ; Function code to read DOS stacks info
	 EMMOUT  @EMM2_DSTKS	; Return with ES:BX ==> DSTK_TAB
	 assume  es:nothing	; Tell the assembler about it
				;	      CX = DSTK_CNT
				;	      DX = DSTK_ISIZ
				;	      SI.LO = master PIC intercepts
				;	      SI.HI = slave ...
				;	      DI.LO = state (see DSTK_REC)
	 mov	 sp,bp		; Restore
	 mov	 DSTK_CNT,cx	; Save for later use
	 mov	 DSTK_ISIZ,dx	; ...
	 mov	 DSTK_INTS,si	; ...
	 and	 di,0FFh	; Isolate low-order byte
	 mov	 DSTK_STAT,di	; ...

	 push	 es		; Copy ES to FS for later use
	 pop	 fs		; Address it
	 assume  fs:nothing	; Tell the assembler about it

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 or	 ah,ah		; Check return code
	 jnz	 short ACT_STACKS_ERR ; Something went wrong

	 call	 DISP_DCNT	; Display count information

	 jcxz	 ACT_STACKS_TAIL ; Jump if no DOS stack defined

	 call	 CHECK_DSTKOVF	; Check for stack overflow
ACT_STACKS_NEXT:
	 call	 DISP_DSTKS	; Display the DOS stacks table at FS:BX

	 add	 bx,type DSTK_TAB_STR ; Skip to next entry

	 loop	 ACT_STACKS_NEXT ; Jump if more stacks
ACT_STACKS_TAIL:
	 lea	 dx,CNTBUF_TAIL ; DS:DX ==> tail
	 call	 STROUT 	; Display the string at DS:DX

	 clc			; Indicate all went well

	 jmp	 short ACT_STACKS_EXIT ; Join common exit code

if @OEM_WIN3
ACT_STACKS_WINERR:
	 lea	 dx,MSG_WINERR	; DS:DX ==> error message
	 call	 STROUT 	; Display the string at DS:DX

	 jmp	 short ACT_STACKS_ERR ; Join common error code
endif				; IF @OEM_WIN3

ACT_STACKS_ERR:
	 stc			; Indicate something went wrong
ACT_STACKS_EXIT:
	 REGREST <fs,bp,si,dx,cx,bx,eax> ; Restore
	 assume  fs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_STACKS endp 		; End ACT_STACKS procedure
	 NPPROC  DISP_DCNT -- Display DOS Stacks Count Information
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display DOS stacks count information

|

	 REGSAVE <ax,cx,dx,si,di> ; Save registers

	 lea	 di,CNTBUF_CNT	; ES:DI ==> output save area
	 mov	 ax,DSTK_CNT	; Get the # DOS stacks
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to hex at ES:DI

	 lea	 di,CNTBUF_ISIZ ; ES:DI ==> output save area
	 mov	 ax,DSTK_ISIZ	; Get the size of each DOS stack
;;;;;;;; mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to hex at ES:DI

	 mov	 dl,DSTK_INTS.LO ; Get master PIC interrupt bits
	 mov	 al,@IMRBASE	; Get base interrupt # of master PIC
	 lea	 di,CNTBUF_MPIC ; ES:DI ==> output save area
	 call	 DISP_DPIC	; Display PIC values

	 mov	 dl,DSTK_INTS.HI ; Get slave PIC interrupt bits
	 mov	 al,@IMR2BASE	; Get base interrupt # of slave PIC
	 lea	 di,CNTBUF_SPIC ; ES:DI ==> output save area
	 call	 DISP_DPIC	; Display PIC values

; Copy appropriate state message

	 mov	 cx,CNTBUF_STATE_ON_LEN ; Assume enabled
	 lea	 si,CNTBUF_STATE_ON ; ...

	 test	 DSTK_STAT,(mask $DSTK_GLBOFF) or (mask $DSTK_LCLOFF) ; Izit disabled?
	 jz	 short @F	; Jump if not

	 mov	 cx,CNTBUF_STATE_OFF_LEN ; Assume disabled
	 lea	 si,CNTBUF_STATE_OFF ; ...
@@:
	 lea	 di,CNTBUF_STATE ; ES:DI ==> appropriate message
     rep movs	 CNTBUF_STATE[di],CNTBUF_STATE_ON[si] ; Copy to buffer

	 lea	 dx,CNTBUF	; DS:DX ==> message
	 call	 STROUT 	; Display the string at DS:DX

	 REGREST <di,si,dx,cx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DCNT endp			; End DISP_DCNT procedure
	 NPPROC  DISP_DPIC -- Display DOS Stacks PIC Information
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display DOS stacks PIC information

On entry:

AL	 =	 starting interrupt # for this PIC
DL	 =	 bitmap for the PIC
ES:DI	 ==>	 output save area

|

	 REGSAVE <ax,cx,dx,di>	; Save registers

	 mov	 cx,8		; Get # interrupts per PIC
	 mov	 ah,0		; Initialize display count
DISP_DPIC_NEXT:
	 shr	 dl,1		; Check next interrupt #
	 jnc	 short DISP_DPIC_LOOP ; Jump if not intercepted

	 cmp	 ah,0		; Izit the first interrupt # to display?
	 je	 short @F	; Jump if so

	 mov	 PGROUP:[di].LO,',' ; Store a separator
	 inc	 di		; Skip over it
@@:
	 call	 DB2HEX 	; Convert AL to hex at ES:DI

	 inc	 ah		; Count in another interrupt displayed
DISP_DPIC_LOOP:
	 inc	 al		; Skip to next interrupt #

	 loop	 DISP_DPIC_NEXT ; Jump if more interrupts to check

	 REGREST <di,dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DPIC endp			; End DISP_DPIC procedure
	 NPPROC  CHECK_DSTKOVF -- Check For DOS Stacks Overflow
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

In case a DOS stack has overflowed into another DOS stack
and we haven't attempted to allocate the lower stack, we
won't have marked that stack as overflowed.  In order to
properly report that status, check for that condition now.

On entry:

CX	 =	 DSTK_CNT
FS:BX	 ==>	 DSTK_TAB_STR to display

|

	 REGSAVE <bx,cx,di,es>	; Save registers

	 mov	 DSTK_OVF,0	; Initialize overflow size
CHECK_DSTKOVF_NEXT:
	 les	 di,fs:[bx].DSTK_TAB_DOSSTKVEC ; ES:DI ==> top of the stack
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[di-4].EDD,@STKSIG ; Izit still there?
	 je	 short CHECK_DSTKOVF_LOOP ; Jump if so

	 mov	 fs:[bx].DSTK_TAB_OLDSTKVEC,@STKOVF ; Mark as overflowed
CHECK_DSTKOVF_LOOP:
	 add	 bx,type DSTK_TAB_STR ; Skip to next entry

	 loop	 CHECK_DSTKOVF_NEXT ; Jump if more stacks to check

	 REGREST <es,di,cx,bx>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DSTKOVF endp		; End CHECK_DSTKOVF procedure
	 NPPROC  DISP_DSTKS -- Display DOS Stacks Table Information
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display DOS stacks table information at FS:BX

On entry:

CX	 =	 loop counter for DSTK_TAB
FS:BX	 ==>	 DSTK_TAB_STR to display

|

	 REGSAVE <eax,cx,dx,di,es> ; Save registers

; Format various values

	 lea	 di,LCLBUF_OFF	; ES:DI ==> output save area
	 mov	 ax,bx		; Get the offset
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 lea	 di,LCLBUF_SEG	; ES:DI ==> output save area
	 mov	 ax,fs		; Get the segment
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 lea	 di,LCLBUF_STA	; ES:DI ==> output save area
	 mov	 eax,fs:[bx].DSTK_TAB_OLDSTKVEC ; Get the status
	 call	 DD2HEX 	; Convert AX to hex at ES:DI

	 lea	 di,LCLBUF_TOPOFF ; ES:DI ==> output save area
	 mov	 ax,fs:[bx].DSTK_TAB_DOSSTKVEC.VOFF ; Get the offset
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 lea	 di,LCLBUF_TOPSEG ; ES:DI ==> output save area
	 mov	 ax,fs:[bx].DSTK_TAB_DOSSTKVEC.VSEG ; Get the segment
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

; Calculate the stack depth

	 les	 di,fs:[bx].DSTK_TAB_DOSSTKVEC ; ES:DI ==> top of the stack
	 assume  es:nothing	; Tell the assembler about it

	 push	 cx		; Save outer loop counter

	 mov	 dx,di		; Copy offset of top of the stack
	 mov	 cx,DSTK_ISIZ	; Get the size of the stack in bytes
	 sub	 di,cx		; Back off to the bottom
	 shr	 cx,2-0 	; Convert from bytes to dwords
	 mov	 eax,@STKFILL	; Get the fill pattern
    repe scas	 es:[di].EDD	; Search for it
	 sub	 di,4		; Back off to last match
	 sub	 dx,di		; Subtract to get depth (including @STKSIG)

	 pop	 cx		; Restore outer loop counter

; If the next DSTK_TAB entry is marked as overflowed
; (meaning that this stack overflowed into it), save
; the current depth to be included in the next entry's
; display, mark this one's depth as merged and exit

	 cmp	 cx,1		; Is there a next DSTK_TAB entry?
	 je	 short DISP_DSTKS_XOVF ; Jump if not

	 cmp	 fs:[bx+(type DSTK_TAB_STR)].DSTK_TAB_OLDSTKVEC,@STKOVF ; Is the next entry overflowed?
	 jne	 short DISP_DSTKS_XOVF ; Jump if not

	 add	 DSTK_OVF,dx	; Add into overflow counter
	 mov	 LCLBUF_DEPTH[-3].EDD,'-   ' ; Mark as merged

	 jmp	 short DISP_DSTKS_END ; Join common ending code

DISP_DSTKS_XOVF:
	 xor	 ax,ax		; Prepare to zero DSTK_OVF
	 xchg	 ax,DSTK_OVF	; Clear it for next time, get previous value
	 add	 dx,ax		; Add into current depth
	 sub	 dx,4		; Subtract out @STKSIG
	 mov	 LCLBUF_DEPTH[-3].EDD,'    ' ; Clear the field from last time

	 lea	 di,LCLBUF_DEPTH ; ES:DI ==> output save area
	 mov	 ax,dx		; Copy to output register
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to hex at ES:DI

; Display the entire buffer

DISP_DSTKS_END:
	 lea	 dx,LCLBUF	; DS:DX ==> message
	 call	 STROUT 	; Display the string at DS:DX

	 REGREST <es,di,dx,cx,eax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_DSTKS endp 		; End DISP_DSTKS procedure

CODE	 ends			; End CODE segment

	 MEND			; End UTIL_STK module
