;' $Header:   P:/PVCS/MAX/386LOAD/TSRHIGH.ASV   1.1   30 May 1997 10:38:14   BOB  $
	 title	 TSRHIGH -- 386LOAD/MOVE'EM TSR High Loader
	 page	 58,122
	 name	 TSRHIGH

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Program segment DATZ,	para-aligned,  public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Program segment DTAIL,	para-aligned,  public, class 'zdata'
	       Program segment ACODE,	byte-aligned,  public, class 'zdata'
	       Data    segment ADATA,	dword-aligned, public, class 'zdata'
	       Program segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Program derived from:  None.

Original code by:  Bob Smith, March 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include DOSERR.INC
	 include EXE.INC
	 include MAC.INC
	 include PTR.INC
	 include OPEN.INC
	 include IOCTL.INC
	 include OPCODES.INC
	 include EMMCALL.INC

	 include LOAD_OEM.INC
	 include QMAX_FMT.INC
.list

PGROUP	 group	 CODE,DATZ,NCODE,NDATA,DTAIL,ACODE,ADATA,ZZTAIL


DATZ	 segment para public 'data' ; Start DATZ segment
	 assume  ds:PGROUP

	 extrn	 INT_NPAR:word
	 extrn	 DMAC:word
	 extrn	 LSEGSEG:word
	 extrn	 CFGFLAGS:word
	 extrn	 @CFG_CLOSELOW:abs

DATZ	 ends			; End DATZ segment


ADATA	 segment dword public 'zdata' ; Start ADATA segment
	 assume  ds:PGROUP

	 extrn	 AZS_EXEC:byte
	 extrn	 AZS_ERRMEM:byte
	 extrn	 AZS_UGHROOM:byte

ADATA	 ends			; End ADATA segment


NDATA	 segment dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 AZS_XRES:byte
	 extrn	 AZS_UGHMAC:byte
	 extrn	 AZS_ERRMAC:byte
AZS_UGHUGH equ	 AZS_ERRMAC

	 extrn	 EXEC_BLK:word
	 extrn	 LCL_PATH:byte
	 extrn	 FILE_HEAD:byte
	 extrn	 EXEC_PRGMAC:word
	 extrn	 EXEC_PRGNPAR:word
	 extrn	 EXEC_ENVMAC:word
	 extrn	 EXEC_INTMAC:word
	 extrn	 EXEC_PSP:word
	 extrn	 END_RET:byte
	 extrn	 ENV_HEAD:word
	 extrn	 ENV_TAIL:word
	 extrn	 OLDDTA_VEC:dword
	 extrn	 PARG_OFF:word
	 extrn	 PARG_LEN:word
	 extrn	 CURPSP:word
	 extrn	 MACLOC:byte
	 extrn	 STKSIZE:dword
	 extrn	 EXE_NPAR:word
	 extrn	 DOSVER:word

	 public  END_VEC
END_VEC  dd	 ?		; Ending pointer if resident

	 public  STD_FILES
STD_FILES dw	 @STD_INP,@STD_OUT,@STD_ERR,@STD_AUX,@STD_PRT

	 public  STD_ERR
STD_ERR  dw	 @STD_ERR	; Standard error handle

	 public  OLDENDMAC
OLDENDMAC dw	 ?		; Previous ending MAC para #

	 public  CURSTK_OFF
CURSTK_OFF dw	 ?		; Current stack offset at execution in LOADHI

	 public  DRV_FCB1,DRV_FCB2
DRV_FCB1 db	 -1		; FCB #1 drive specifier status:  00 = valid,
DRV_FCB2 db	 -1		;     #2 ...			  FF = invalid

	 public  JMACOLD
JMACOLD  MAC_STR <>		; Save area for joined MAC data

NDATA	 ends			; End NDATA segment


DTAIL	 segment para public 'zdata' ; Start DTAIL segment
	 assume  ds:PGROUP

	 extrn	 POVR_MAC:word
	 extrn	 MGRINT21_VEC:dword

DTAIL	 ends			; End DTAIL segment


ZZTAIL	 segment dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 extrn	 ZTAIL:byte

ZZTAIL	 ends			; End ZZTAIL segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 LCL_FLAG:word
	 include LOAD_LCL.INC

	 extrn	 LC2_FLAG:word
	 include LOAD_LC2.INC

	 extrn	 OPT_FLAG:word
	 include LOAD_OPT.INC

	 extrn	 LSEG:tbyte
	 include LOAD_SEG.INC

	 extrn	 PSP_CTRL_PSP:word
	 extrn	 PSP_STOR_MAX:word
	 extrn	 PSP_BYTES_INSEG:word
	 extrn	 PSP_TERMINATE:dword
	 extrn	 PSP_ENVIR_PTR:word
	 extrn	 PSP_FILE_TAB_SIZ:word
	 extrn	 PSP_FILE_TAB_PTR:dword
	 extrn	 PSP_PARM_COUNT:byte
	 extrn	 PSP_DTA:byte
	 extrn	 PSP_FCB1:byte
	 extrn	 PSP_FCB2:byte
	 extrn	 PSP_LCL_STACK:dword

	 extrn	 @INT_SIZE:abs

CODE	 ends			; End CODE segment


ACODE	 segment byte public 'zdata' ; Start ACODE segment
	 assume  cs:PGROUP

	 extrn	 WAITFF:near
if @OEM_FLEX
	 extrn	 REST_EMS:near
endif				; IF @OEM_FLEX
	 extrn	 FMT_CHG:near

	 NPPROC  JOIN_MAC -- Join Low and High MACs
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Join low and high MACs

If MAX is in the system, there will always be a spanning entry.
This is not the case with Move'EM.  We play it safe and construct
our own spanning entry.

OLDENDMAC contains the segment of the final empty MAC entry at
9FFF only in the @LC2_ZMAC case.  Otherwise, it's the segment of
the spanning entry we've created.

If DOS 5 is present, we'll use 5803 to link and unlink the arenas.
Some programs (like the Logitech MOUSE.COM with VESA support)
exhibit inconsistent behavior if they're A. loaded high and B. they
can allocate low memory and C. the arenas weren't linked with the
strategy set to high first.  Specifically, they don't free the low
memory they temporarily allocate.

On exit:

CF	 =	 0 if all went well
	 =	 1 if MAC error

|

	 REGSAVE <ax,bx,cx,es>	; Save registers

; If it's DOS 5, try making a 5803h call to link the arenas.
; If it succeeds, that's the method we'll use.
	 cmp	 DOSVER,0500h	; Izit DOS 5?
	 jb	 short @F	; Jump if not

	 mov	 ax,@MACALG*256+03h ; Set link state to BX
	 mov	 bx,1		; Link arenas
	 DOSCALL		; CF=0 if it succeeded
	 jc	 short @F	; Jump if not

	 or	 LC2_FLAG,@LC2_LINK58 ; Mark as using 5800 services

; Get strategy and set it to high first
	 mov	 ax,@MACALG*256+00h ; Get current strategy
	 DOSCALL		; AX contains strategy
	 mov	 bx,ax		; Copy old strategy
	 and	 bx,(@STRA_LAST or @STRA_BEST) ; Save low order bits
	 or	 bx,@STRA_HI	; High DOS first, then low DOS
	 mov	 ax,@MACALG*256+01h ; Set strategy
	 DOSCALL		; ...to BX
	 jmp	 JOIN_MAC_OK	; Join common exit

@@:
; Search for end of the memory allocation chain

	 mov	 ax,cs		; Copy segment of our PSP
	 dec	 ax		; Back off to MAC entry
JOIN_MAC_NEXT:
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Ensure valid
	 je	 short JOIN_MAC_END ; Jump if so

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Ensure valid
	MJ ne	 JOIN_MAC_ERR	; Jump if not

	 add	 ax,es:[0].MAC_NPAR ; Plus # paras in MAC entry
	 inc	 ax		; Skip over MAC entry

	 jmp	 short JOIN_MAC_NEXT ; Go around again

JOIN_MAC_END:

; In case the last entry is at 9FFF and is of zero length,
; flag it and handle specially

	 cmp	 es:[0].MAC_NPAR,0 ; Izit empty?
	 jne	 short JOIN_MAC_XMT ; Jump if not

	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Izit available?
	 jne	 short JOIN_MAC_XMT ; Jump if not

	 int	 12h		; Get top of DOS in 1KB
	 mov	 cl,10-4	; Shift amount between paras and 1KB
	 shl	 ax,cl		; Convert from 1KB to paras
	 dec	 ax		; Back off to preceding para

	 mov	 bx,es		; Copy current segment

	 cmp	 ax,bx		; Same value?
	 jne	 short JOIN_MAC_XMT ; Jump if not

	 mov	 OLDENDMAC,ax	; Save for later use
	 or	 LC2_FLAG,@LC2_ZMAC ; Mark as special ending MAC entry

	 jmp	 short JOIN_MAC_ZMAC ; Join common code

JOIN_MAC_XMT:

; Save data we're replacing wth a new MAC entry

	 REGSAVE <si,di,ds,es>	; Save for a moment

	 mov	 ax,es		; Get current MAC segment
	 add	 ax,es:[0].MAC_NPAR ; Plus # paras in MAC entry
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it
	 xor	 si,si		; DS:SI ==> data we're replacing

	 push	 cs		; Get data segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,JMACOLD	; ES:DI ==> save area
	 mov	 cx,size MAC_STR ; Get # bytes in MAC entry
     rep movsb			; Save it to restore later

	 REGREST <es,ds,di,si>	; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 mov	 bx,es:[0].MAC_NPAR ; Get # paras in MAC entry
	 dec	 bx		; Less one for spanning entry
	 call	 MODMEM 	; Modify memory block ES:0 to BX paras
	 jc	 short JOIN_MAC_ERR ; Jump if something went wrong

	 mov	 ax,es		; Copy segment
	 add	 ax,es:[0].MAC_NPAR ; Plus # paras in MAC entry
	 inc	 ax		; Skip over MAC entry
	 mov	 OLDENDMAC,ax	; Save for later use
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

; Validity checks

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit the end?
	 jne	 short JOIN_MAC_ERR ; Jump if not

	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Izit free?
	 jne	 short JOIN_MAC_ERR ; Jump if not

	 cmp	 es:[0].MAC_NPAR,0 ; Izit empty?
	 jne	 short JOIN_MAC_ERR ; Jump if not

; Insert spanning entry

JOIN_MAC_ZMAC:
	 mov	 es:[0].MAC_TYPE,@MAC_MID ; Mark as a middle MAC entry
	 mov	 es:[0].MAC_OWNR,@MAC_SPAN ; Mark as spanning entry

	 mov	 ax,POVR_MAC	; Get segment of first MAC in high DOS memory
	 mov	 bx,es		; Get segment of spanning MAC entry
	 sub	 ax,bx		; Less that segment
	 dec	 ax		; Less MAC entry
	 mov	 es:[0].MAC_NPAR,ax ; Save as # paras in spanning MAC entry

JOIN_MAC_OK:
	 or	 LC2_FLAG,@LC2_JMAC ; Mark as joined
	 clc			; Indicate success
	 jmp	 short JOIN_MAC_EXIT ; Join common exit code

JOIN_MAC_ERR:
	 stc			; Indicate we had a problem
JOIN_MAC_EXIT:
	 REGREST <es,cx,bx,ax>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

JOIN_MAC endp			; End JOIN_MAC procedure

ACODE	 ends			; End ACODE segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 SET_EES:near
	 extrn	 DISP_ERRMSG:near
	 extrn	 KEYWAIT:near
	 extrn	 MAC_MERGE:near
	 extrn	 MAC_FREE:near
	 extrn	 GETMEM_SUB:near
	 extrn	 GETMEM_REG:near
	 extrn	 GETMEM_SRCH:near
	 extrn	 GETSIZE:near
	 extrn	 PAR2BYT:near
	 extrn	 MODMEM:near
	 extrn	 FILL_MEM:near
	 extrn	 CHECK_MEM:near
	 extrn	 LINK_LSEG:near
	 extrn	 LINK_TLSEG:near
	 extrn	 UNLINK_TLSEG:near
	 extrn	 SKIP_WHITE:near
	 extrn	 CHECK_PATCH:near
if @OEM_FLEX
	 extrn	 REST67:near
	 extrn	 CLEAR_EMSPTE:near
endif				; IF @OEM_FLEX

	 NPPROC  BUILD_PSP -- Build The PSP
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Build the PSP in high DOS memory.
Ensure @STD_xxx files are closed in case the PRG frees those handles.
Blast our return address into the terminate vector.

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

	 DOSCALL @GETPSP	; Return with BX = current PSP
	 mov	 CURPSP,bx	; Save to restore later

; First duplicate the initial file handles

	 mov	 cx,5		; # default file handles
	 xor	 bx,bx		; Initialize handle #
@@:
	 DOSCALL @FHCOPY	; Copy the file handle
;;;;;;;; jc	 ???		; Ignore error condition

	 shl	 bx,1		; Times two to index table of words
	 mov	 STD_FILES[bx],ax ; Save new file handle
	 shr	 bx,1		; Restore

	 inc	 bx		; Skip to next file handle

	 loop	 @B		; Jump if more handles to duplicate

; Create the PSP

COMMENT|

Thanks for Novell's EMSNET3/4, we can't use an ordinary INT21h
call.  It seems that they introduced a bug in their programs
which causes the @BLDPSP call to fail.	Because the PSP is very
much DOS's provence, we can't afford to build it on our own.
In particular, I would expect that future versions of DOS might
change the format of some of the reserved fields.  Instead, we
rely upon 386MAX passing to us (through the QMAXINFO structure)
the address of the INT 21h handler at the time it was installed.
That way we can still use DOS to build the PSP and not have to
trip over Novell's bug.

|

; DR-DOS 6.0 bug in the BLDPSP code. So we always copy our
; Control PSP segment to the one we are creating

	 mov	 es,CURPSP	; Set segment to access PSP
	 assume  es:nothing	; Tell the assembler about it

	 assume  ds:nothing,es:PGROUP ; Lie to the assembler
	 push	 es:PSP_CTRL_PSP ; Get our Control PSP segment
	 assume  ds:PGROUP,es:nothing ; Now tell the truth

	 mov	 dx,EXEC_PSP	; Get segment of program PSP
;;;;;;;; DOSCALL @BLDPSP	; Build a new PSP
	 mov	 ah,@BLDPSP	; Build a new PSP
	 pushf			; Simulate INT environment
	 cli			; ...
	 call	 MGRINT21_VEC	; Request DOS service

	 mov	 es,dx		; Get segment of program PSP
	 assume  es:nothing	; Tell the assembler about it

	 assume  ds:nothing,es:PGROUP ; Lie to the assembler
	 pop	 es:PSP_CTRL_PSP ; Store our Control PSP segment
	 assume  ds:PGROUP,es:nothing ; Now tell the truth

; Setup the TSR's file handles

; At this point, there are ten valid file handles (L0-4, L5-9)
; The 386LOAD PSP maps L0-4, L5-9, the TSR PSP maps L0-4, L5-9.

	 assume  ds:nothing,es:PGROUP ; Lie to the assembler
	 les	 di,es:PSP_FILE_TAB_PTR ; ES:DI ==> file table indices
	 assume  ds:PGROUP,es:nothing ; Now tell the truth

	 mov	 cx,5		; # default file handles
	 mov	 al,0FFh	; Marker for unused file handle
     rep stosb			; Mark as unused

; At this point, there are ten valid file handles (L0-4, L5-9)
; The 386LOAD PSP maps L0-4, L5-9, the TSR PSP maps L5-9.

	 mov	 bx,EXEC_PSP	; Get segment of program PSP
	 DOSCALL @SETPSP	; Set PSP to BX

	 mov	 cx,5		; # default file handles
	 xor	 si,si		; Initialize index into STD_FILES
@@:
	 shl	 si,1		; Times two to index table of words
	 mov	 bx,STD_FILES[si] ; Get next file handle
	 shr	 si,1		; Restore

	 push	 cx		; Save for a moment
	 mov	 cx,si		; Copy value 0-4
	 DOSCALL @FHCREA	; Create a new file handle (should be 0-4)
	 pop	 cx		; Restore
;;;;;;;; jc	 ???		; Ignore error return

	 inc	 si		; Skip to next file handle

	 loop	 @B		; Jump if more handles to force duplicate

; At this point, there are 15 valid file handles (L0-4, L5-9, T0-4)
; The 386LOAD PSP maps L0-4, L5-9, the TSR PSP maps T0-4, L5-9.

	 mov	 cx,5		; # default file handles
	 xor	 si,si		; Initialize index into STD_FILES
	 mov	 al,0FFh	; Marker for unused file handle
@@:
	 shl	 si,1		; Times two to index table of words
	 mov	 di,STD_FILES[si] ; Get next file handle
	 shr	 si,1		; Restore
	 assume  ds:nothing,es:PGROUP ; Lie to the assembler
	 add	 di,PSP_FILE_TAB_PTR.VOFF ; ES:DI ==> file table indices
	 assume  ds:PGROUP,es:nothing ; Now tell the truth
	 stosb			; Clear the file handle

	 inc	 si		; Skip to next file handle

	 loop	 @B		; Jump if more handles to force duplicate

; At this point, there are 15 valid file handles (L0-4, L5-9, T0-4)
; The 386LOAD PSP maps L0-4, L5-9, the TSR PSP maps T0-4.

	 mov	 bx,CURPSP	; Get value of previous PSP
	 DOSCALL @SETPSP	; Restore PSP to ourselves

	 mov	 cx,5		; # default file handles
	 xor	 si,si		; Initialize index into STD_FILES
@@:
	 shl	 si,1		; Times two to index table of words
	 mov	 bx,STD_FILES[si] ; Get next file handle
	 shr	 si,1		; Restore

	 DOSCALL @CLOSF2	; Close the file handle
;;;;;;;; jc	 ???		; Ignore error return

	 inc	 si		; Skip to next file handle

	 loop	 @B		; Jump if more handles to force duplicate

; At this point, there are 10 valid file handles (L0-4, T0-4)
; The 386LOAD PSP maps L0-4, the TSR PSP maps T0-4.

	 or	 LC2_FLAG,@LC2_FHCOPY ; Mark as file handles copied

; Adjust the PSP environment

	 mov	 es,EXEC_PSP	; Get segment of program PSP
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,EXEC_ENVMAC ; Get segment of environment MAC
	 inc	 ax		; Count in MAC paragraph

	 assume  ds:nothing,es:PGROUP ; Lie to the assembler
	 mov	 PSP_ENVIR_PTR,ax ; Save as new environment
	 assume  ds:PGROUP,es:nothing ; Now tell the truth

; Adjust the top of memory and mark this region as owned by the program

	 push	 es		; Save for a moment

	 mov	 es,EXEC_PRGMAC ; Get program MAC segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,dx		; Get segment of program PSP
	 mov	 es:[0].MAC_OWNR,ax ; Mark as the new owner
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 assume  ds:nothing,es:PGROUP ; Lie to the assembler
	 mov	 PSP_STOR_MAX,ax ; Save as top of memory
	 assume  ds:PGROUP,es:nothing ; Now tell the truth

; Adjust # bytes in memory above the loaded program

	 sub	 ax,EXEC_PRGMAC ; Less program MAC segment

	 cmp	 ax,1000h	; Check against 64 KB limit
	 jbe	 short BUILD_PSP1 ; It's smaller

	 mov	 ax,1000h	; Use maximum
BUILD_PSP1:
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shl	 ax,cl		; Convert from paras to bytes
	 sub	 ax,2		; Less word of zeros at top of stack
	 and	 ax,not (16-1)	; Round down to para boundary
	 sub	 ax,100h	; Less size of PSP

	 assume  ds:nothing,es:PGROUP ; Lie to the assembler
	 mov	 PSP_BYTES_INSEG.VOFF,ax ; Save as # bytes remaining in this segment
	 assume  ds:PGROUP,es:nothing ; Now tell the truth

	 shr	 ax,cl		; Convert from bytes to paras

	 sub	 ax,00C0h/16	; Less offset to INT 31.4
	 neg	 ax		; Negate to get segment

	 assume  ds:nothing,es:PGROUP ; Lie to the assembler
	 mov	 PSP_BYTES_INSEG.VSEG,ax ; Save as # bytes remaining in this segment
	 mov	 PSP_TERMINATE.VSEG,cs ; Segment of return address
	 mov	 PSP_TERMINATE.VOFF,offset PGROUP:INT22_RET ; Offset to return to
	 assume  ds:PGROUP,es:nothing ; Now tell the truth

	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

BUILD_PSP endp			; End BUILD_PSP procedure
	 NPPROC  INST_INTS -- Install Interrupt Handlers
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Install our interrupt handlers.  Note that the interrupt jump vectors
are changed in the LSEG at EXEC_INTMAC, *not* in the copy we have at
PGROUP:LSEG.

|

	 REGSAVE <ax,bx,dx,es>	; Save registers

	 mov	 es,EXEC_INTMAC ; Get interrupt handler MAC segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[0].MAC_OWNR,@MAC_TEMP ; Save as owner

	 REGSAVE <cx,si,di>	; Save for a moment

	 lea	 di,es:[size MAC_STR] ; ES:DI ==> save area
	 lea	 si,LSEG	; DS:SI ==> start of interrupt handlers
	 mov	 cx,@INT_SIZE	; CX = # bytes in interrupt handlers
     rep movsb			; Copy to high DOS memory

; Zero the remainder of the para

	 mov	 cx,16		; # bytes in para
	 sub	 cx,@INT_SIZE	; Less size of LSEG
	 and	 cx,(1 shl 4)-1 ; Modulo 16
	 mov	 al,0		; Clear to this value
     rep stosb			; Zero the tail

INST_INTS_XFLEX1:
	 REGREST <di,si,cx>	; Restore

	 REGREST <es,dx,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INST_INTS endp			; End INST_INTS procedure
	 NPPROC  INST_DTA -- Install New DTA
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Install a new DTA pointing to high DOS memory.

|

	 REGSAVE <ax,bx,dx,es>	; Save registers

	 DOSCALL @GETDTA	; Return with ES:BX ==> current DTA
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDDTA_VEC.VOFF,bx ; Save to restore later
	 mov	 OLDDTA_VEC.VSEG,es

	 push	 ds		; Save for a moment

	 mov	 ds,EXEC_PSP	; Get segment of program PSP
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETDTA,PSP_DTA ; Set DTA to DS:DX

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 or	 LCL_FLAG,@LCL_DTA ; Mark as intercepted

	 REGREST <es,dx,bx,ax>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INST_DTA endp			; End INST_DTA procedure
	 NPPROC  INST_PSP -- Set New PSP
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Set new PSP to high DOS memory.

|

	 REGSAVE <ax,bx>	; Save registers

	 mov	 bx,EXEC_PSP	; Get segment of program PSP
	 DOSCALL @SETPSP	; Set PSP to BX

	 or	 LCL_FLAG,@LCL_PSP ; Mark as intercepted

	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INST_PSP endp			; End INST_PSP procedure
;;;	     NPPROC  INST_FILES -- Install Initial Files
;;;	     assume  ds:PGROUP,es:PGROUP,ss:nothing
;;; COMMENT|
;;;
;;; Install initial file handles (@STDxxx)
;;; We're assuming here that the handle numbers assigned
;;; are 0 through 4.
;;;
;;; |
;;;
;;;	     REGSAVE <ax,bx,cx,si>  ; Save registers
;;;
;;;	     mov     cx,5	    ; # file handles to copy
;;;	     xor     si,si	    ; Initialize index into STD_FILES
;;; INST_FILES_NEXT:
;;;	     shl     si,1	    ; Times two to index table of words
;;;	     mov     bx,STD_FILES[si] ; Get next file handle
;;;	     shr     si,1	    ; Restore
;;;
;;; ; Thanks to a bug in DR DOS 5.0, we get an error from the
;;; ; following function which we must then ignore
;;;
;;;	     DOSCALL @FHCOPY	    ; Make a copy of the handle
;;; ;;;;;;;; jc      short INST_FILES_ERR ; Jump if something went wrong
;;; ;;;;;;;;
;;; ;;;;;;;; cmp     ax,si	    ; Ensure the same
;;; ;;;;;;;; je      short @F	    ; Jump if so
;;; INST_FILES_ERR:
;;; ;;;;;;;; int     03h	    ; Call debugger
;;; @@:
;;;	     inc     si 	    ; Skip to next index
;;;
;;;	     loop    INST_FILES_NEXT ; Jump if more handles to copy
;;;
;;;	     REGREST <si,cx,bx,ax>  ; Restore
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,ss:nothing
;;;
;;; INST_FILES endp		    ; End INST_FILES procedure
	 NPPROC  INST_CMDLINE -- Copy Command Line
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Copy command line to high DOS memory PSP.

|

	 REGSAVE <ax,cx,di,ds,es> ; Save registers

	 mov	 es,EXEC_PSP	; Get segment of program PSP
	 assume  es:nothing	; Tell the assembler about it

	 lea	 di,PSP_PARM_COUNT ; ES:DI ==> PSP count in high DOS memory
	 mov	 al,PARG_LEN.LO ; Get argument length
	 stosb			; Save in high DOS memory PSP

	 mov	 si,PARG_OFF	; DS:SI ==> argument line
	 mov	 cx,PARG_LEN	; Get argument length
     rep movsb			; Copy to high DOS memory PSP

	 mov	 al,CR		; Command line terminator
	 stosb			; Save in high DOS memory PSP

; Because of a bug in some 10NET drivers, we must zero the remainder
; of the command line

	 mov	 cx,0100h	; Get the length of the PSP
	 sub	 cx,di		; Less our current position
	 mov	 al,0		; Fill value
     rep stosb			; Clear the rest of the command line

	 REGREST <es,ds,di,cx,ax> ; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INST_CMDLINE endp		; End INST_CMDLINE procedure
	 NPPROC  INST_FCBS -- Setup FCBs
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Setup FCBs in high DOS memory.

|

	 REGSAVE <ax,si,di,es>	; Save registers

	 mov	 si,PARG_OFF	; DS:SI ==> argument

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 mov	 es,EXEC_PSP	; Get segment of program PSP
	 assume  es:nothing	; Tell the assembler about it
	 lea	 di,PSP_FCB1	; ES:DI ==> FCB #1
	 mov	 al,00h 	; Function code
	 DOSCALL @PARSF 	; Parse the filename at DS:SI into ES:DI
				; Return with AL set, DS:SI ==> next char

	 cmp	 al,-1		; Check for invalid drive specifier
	 je	 short INST_FCBS1 ; Jump if it's invalid

	 mov	 al,0		; Mark as valid
INST_FCBS1:
	 mov	 DRV_FCB1,al	; Save as drive specifier status flag

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 lea	 di,PSP_FCB2	; ES:DI ==> FCB #2
	 mov	 al,00h 	; Function code
	 DOSCALL @PARSF 	; Parse the filename at DS:SI into ES:DI
				; Return with AL set, DS:SI ==> next char

	 cmp	 al,-1		; Check for invalid drive specifier
	 je	 short INST_FCBS2 ; Jump if it's invalid

	 mov	 al,0		; Mark as valid
INST_FCBS2:
	 mov	 DRV_FCB2,al	; Save as drive specifier status flag

	 REGREST <es,di,si,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INST_FCBS endp			; End INST_FCBS procedure
	 NPPROC  INST_NAME -- Install Program Name in MACs
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Install the program name in various MACs

|

	 REGSAVE <es>		; Save register

	 mov	 es,EXEC_ENVMAC ; Get environment MAC segment
	 assume  es:nothing	; Tell the assembler about it
	 call	 INST_NAMESUB	; Copy program name to MAC at ES:0

	 mov	 es,EXEC_INTMAC ; Get interrupt handler MAC segment
	 assume  es:nothing	; Tell the assembler about it
	 call	 INST_NAMESUB	; Copy program name to MAC at ES:0

	 mov	 es,EXEC_PRGMAC ; Get program MAC segment
	 assume  es:nothing	; Tell the assembler about it
	 call	 INST_NAMESUB	; Copy program name to MAC at ES:0

	 REGREST <es>		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INST_NAME endp			; End INST_NAME procedure
	 NPPROC  INST_NAMESUB -- Subroutine to INST_NAME
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Copy program name to MAC entry at ES:0 a la DOS 4.00

|

	 REGSAVE <ax,cx,si,di>	; Save registers

	 lea	 di,es:[0].MAC_NAME ; ES:DI ==> place for name in MAC entry
	 lea	 si,LSEG.LSEG_FNE ; DS:SI ==> "filename.ext" in LSEG save area
	 mov	 cx,8		; Maximum length of name
@@:
	 lodsb			; Get the next character

	 cmp	 al,'.'         ; Izit the extension?
	 je	 short INST_NAMESUB_EXIT ; Yes

	 stosb			; Save in the MAC entry

	 loop	 @B		; Jump if more characters to check

INST_NAMESUB_EXIT:
	 mov	 al,' '         ; Filler
     rep stosb			; Save in the MAC entry

	 REGREST <di,si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INST_NAMESUB endp		; End INST_NAMESUB procedure

	 NPPROC  LOADHI -- Load File Into High DOS Memory
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Load the file into high DOS memory.  Note that MAC entries have already
been blasted in above GTAIL for the environment, interrupt block, and
PSP, so we must be careful where we're calling.

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save segment registers

; We need to reduce our size now so some low DOS memory is free
; for programs such as the Logitech MOUSE.COM driver which tries
; to allocate low DOS memory (temporarily) when it's loaded high.
; We need to do this while we're still on our own PSP.

; We'll reduce our size so that ZTAIL is the first address we can
; write to for scratch purposes.  In other words, ZTAIL[0] is guaranteed
; to be in the free segment (not in its MAC entry).  Note that we've
; also declared 2 paragraphs of dead space immediately before ZTAIL,
; so we're assured of not destroying anything here.
	 test	 OPT_FLAG,@OPT_GSIZE ; Are we loading low?
	 jnz	 short @F	; Jump if so

	 test	 CFGFLAGS,@CFG_CLOSELOW ; Are we loading bozo SMARTDRV?
	 jnz	 short @F	; Jump if so

	 lea	 bx,ZTAIL	; Address end of memory
	 mov	 cl,4-0 	; Convert bytes to paras
	 shr	 bx,cl		; Get length we need to keep in paras
	 dec	 bx		; Create MAC entry before ZTAIL
	 DOSCALL @MODMEM	; Reduce memory block at ES:0 to BX paras
				; (Ignore error)

@@:
; Build the PSP

	 call	 BUILD_PSP	; Build it

; Copy the environment to the MAC

	 call	 INST_ENV	; Install it

; Install our interrupt handlers

	 call	 INST_INTS	; Install 'em

; Set the default DTA to high DOS memory

	 call	 INST_DTA	; Install it

; Change to the high DOS memory PSP

	 call	 INST_PSP	; Install it

;;; ; Setup initial file handles
;;;
;;;	     call    INST_FILES     ; Install 'em
;;;
; Copy command line

	 call	 INST_CMDLINE	; Install it

; Setup FCBs

	 call	 INST_FCBS	; Install 'em

; Setup program names in MAC entries

	 call	 INST_NAME	; Install 'em

; Fill memory with a pattern following EXEC_PRGMAC

	 call	 FILL_MEM	; Fill it up

; From this point on, the memory above GTAIL is invalid.

; If we're loading via GETSIZE, go ahead.  Otherwise,
; skip it and catch the load in CHECK_MEM because of FLEXFRAME
; and disk caches.

	 test	 OPT_FLAG,@OPT_GSIZE ; Izit specified?
	 jz	 short LOADHI_OK ; Jump if not

; Load the program into low DOS memory

	 lea	 bx,EXEC_BLK	; ES:BX ==> EXEC call parameter block
	 mov	 al,03h 	; Code to load but not execute
	 DOSCALL @EXEC,LCL_PATH ; Load into low DOS memory
	 jnc	 short LOADHI_OK ; Jump if it loaded correctly

	 lea	 ax,AZS_EXEC	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 jmp	 LOADHI_ERR	; Join common error code

LOADHI_ERRMEM:
	 lea	 ax,AZS_ERRMEM	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 jmp	 LOADHI_ERR	; Join common error code

LOADHI_OK:

; Plug holes in high and low MACs
	 call	 PLUG_MAC	; Plug 'em

; Check on valid memory in high DOS

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short @F	; Yes, no checking to do

	 call	 CHECK_MEM	; Check it out
	 jc	 short LOADHI_ERRMEM ; Jump if memory error

; Join low and high memory allocation chains

	 call	 JOIN_MAC	; Join 'em
	 jc	 short LOADHI_ERRMAC ; Jump if MAC error
@@:

; Apply any patches indicated by Fn flag in 386LOAD.CFG
	 call	 CHECK_PATCH	; Patch code at EXEC_LOD

; Execute the high DOS memory program

	 test	 LCL_FLAG,@LCL_EXE ; Izit an .EXE file?
	 jnz	 short LOADHI_EXE ; Jump if so

	 push	 es		; Save for a moment

	 mov	 es,EXEC_PRGMAC ; Get program MAC segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 bx,es:[0].MAC_NPAR ; Get # paragraphs

	 cmp	 bx,1000h	; Use smaller of 64KB
	 jb	 short LOADHI_COM1 ; Jump if smaller

	 mov	 bx,1000h	; Use 64KB
	 mov	 STKSIZE.EHI,0001h ; Set high-order word
LOADHI_COM1:
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shl	 bx,cl		; Convert from paras to bytes
	 mov	 STKSIZE.ELO,bx ; Save as stack size in bytes
	 sub	 bx,2		; Back off by one word
	 mov	 FILE_HEAD.EXE_SP,bx ; Save as new SP

	 mov	 es,EXEC_PSP	; Get segment of program PSP
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[bx].ELO,0	; Put word of zeros on top of stack

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 jmp	 short LOADHI_COM2 ; Join common code

LOADHI_ERRMAC:
	 lea	 ax,AZS_ERRMAC	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 jmp	 LOADHI_ERR	; Join common error code

; Re-allocate memory to # paras needed

LOADHI_EXE:
	 mov	 bx,EXE_NPAR	; Get # paras for re-allocate

	 test	 LC2_FLAG,@LC2_ENDLOAD ; Does it load at the high end?
	 jz	 short @F	; Jump if not

	 mov	 bx,EXEC_PRGNPAR ; Use maximum allocation
@@:
	 cmp	 bx,-1		; Izit valid?
	 je	 short LOADHI_COM2 ; Jump if not

	 push	 es		; Save for a moment

	 mov	 es,EXEC_PRGMAC ; Get program MAC segment
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 bx,es:[0].MAC_NPAR ; Izit more than we have?
	 jae	 short LOADHI_EXE1 ; Jump if so (note CF=0)

	 push	 es		; Save for a moment

	 mov	 ax,EXEC_PSP	; Get segment of program PSP

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 add	 ax,bx		; Plus # paras in this block

	 assume  ds:nothing,es:PGROUP ; Lie to the assembler
	 mov	 PSP_STOR_MAX,ax ; Save as top of memory
	 assume  ds:PGROUP,es:nothing ; Now tell the truth

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 call	 MODMEM 	; Modify memory block ES:0 to BX paras
LOADHI_EXE1:
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it
	 jc	 short LOADHI_ERRMAC ; Jump if MAC error
LOADHI_COM2:

; Temporarily link the LSEG at PGROUP:LSEG into the chain with the
; 386LOAD in progress bit set.	We needn't worry about interrupt
; redirection since we no longer do this.
	 call	 LINK_TLSEG	; Temporarily link into LSEG chain

; If we're running under DOS 5.x, call the EnterExecState API
; to setup the DOS state

	 call	 SET_EES	; Set Enter Exec State for DOS 5.x

if @OEM_FLEX
	 call	 CLEAR_EMSPTE	; Clear accessed bit in page frame PTEs
;;;;;;;  and	 LCL_FLAG,not @LCL_XFLEX ; Clear Int 67h called flag
endif				; IF @OEM_FLEX

	 mov	 CURSTK_OFF,sp	; Save stack offset

	 mov	 al,DRV_FCB1	; Get FCB1 drive specifier status
	 mov	 ah,DRV_FCB2	; Get FCB2 ...

	 mov	 ss,FILE_HEAD.EXE_SS ; Get new SS
	 mov	 sp,FILE_HEAD.EXE_SP ; and SP

	 mov	 es,EXEC_PSP	; Get segment of program PSP
	 assume  es:nothing	; Tell the assembler about it
	 mov	 ds,EXEC_PSP	; Get segment of program PSP
	 assume  ds:nothing	; Tell the assembler about it

; Some programs (certain 10NET drivers) expect the BX register to be zero
; Let's clear all the GP registers except for AX (whose value is defined
; upon entry)

	 xor	 bx,bx		; Clear it
	 xor	 cx,cx		; ...
	 xor	 dx,dx		; ...
	 xor	 si,si		; ...
	 xor	 di,di		; ...

	 jmp	 FILE_HEAD.EXE_IP.EDD ; Jump to it

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it

; This entry point is reached by blasting CS:INT22_RET into the terminate
; vector in the PSP of the program being loaded.  Note that although DOS
; returns control to us here, the PSP is that of our owner.
	 public  INT22_RET
INT22_RET:
	 cli			; Nobody move
	 mov	 ax,cs		; Restore stack segment:offset
	 mov	 ss,ax
	 mov	 sp,CURSTK_OFF
	 and	 LCL_FLAG,not @LCL_PSP ; Mark as no longer intercepted
	 ; To handle a bug in IBM Networks printer sharing code, we
	 ; need to save and restore the SS:SP in our control PSP around
	 ; the DOS Set PSP call.  They make numerous Int 21 calls within
	 ; their own Int 21 handler, and assume that DOS will set
	 ; PSP_LCL_STACK to a sane value on all calls.	This doesn't
	 ; work for the handful of functions that don't switch stacks
	 ; (33, 50, 51, 62 and 64)
	 mov	 es,PSP_CTRL_PSP ; Get control PSP
	 assume  es:PGROUP	; Tell a little white lie
	 push	 PSP_LCL_STACK.VOFF ; Save SP
	 push	 PSP_LCL_STACK.VSEG ; ...and SS
	 assume  es:nothing	; Retract nose

	 mov	 bx,cs		; Get our PSP
	 DOSCALL @SETPSP	; Set current PSP

	 cli			; Nobody move
	 assume  es:PGROUP	; Tell a little white lie
	 pop	 PSP_LCL_STACK.VSEG ; Restore
	 pop	 PSP_LCL_STACK.VOFF
	 assume  es:nothing	; Retract nose
	 sti			; Enable interrupts

	 push	 cs		; Restore DS
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 DOSCALL @GETRC 	; Get return code of subprocess in AH,AL
	 mov	 END_RET,al	; Save return code (AH=terminate type)

	 ; Whether or not the program goes resident matters not.
	 ; It may have invoked subprograms which went resident,
	 ; so we have to scout through the MAC entries that were
	 ; available to it.

	 cld			; Ensure pointing up

	 push	 cs		; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

; Free all the holes in the MAC we previously plugged

	 call	 UNPLUG_MAC	; Unplug 'em

	 push	 es		; Save for a moment

	 mov	 es,EXEC_PRGMAC ; Get program MAC segment
	 assume  es:nothing	; Tell the assembler about it

; Skip over all allocated entries starting at EXEC_PRGMAC for EXEC_PRGNPAR+1
; paragraphs

	 mov	 ax,es		; Save segment # for comparison
	 mov	 bx,ax		; Copy MAC entry segment #
	 inc	 bx		; Skip over MAC entry to get owner segment #
	 mov	 di,EXEC_PRGNPAR ; Get maximum possible allocation - 1
	 add	 di,bx		; Ending value for region to check
	 mov	 cx,bx		; Copy to check later
	 sub	 dx,dx		; DX = last allocated entry or 0 if non-res
	 mov	 bx,es:[0].MAC_OWNR ; Get new owner entry

LOADHI_RES_NEXTMAC:
COMMENT|

Since PLUG_MAC ensure that no free entries exist outside of the region
we initially allocated to EXEC_PRGMAC, all that we're doing is looking
to see if it shrunk its allocated size then reallocated it.  We want
to know how big it reallocated itself to...

  ES:0 ==> MAC entry to test
  AX = ES
  BX = ES:[0].MAC_OWNR
  DX = Segment of last allocated entry, or 0
  DI = End of possible segment range

|
	 cmp	 ax,di		; Are we within range?
	 jnb	 short LOADHI_RES_XCONT ; Jump if not

	 add	 ax,es:[0].MAC_NPAR ; Plus # paras in MAC
	 inc	 ax		; Count in MAC para for ES

	 cmp	 bx,@MAC_FREE	; Izit free?
	 je	 short @F	; Jump if so

	 mov	 dx,ax		; Save as last allocated entry
@@:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit the end?
	 je	 short LOADHI_RES_XCONT ; Jump if so

	 cmp	 es:[0].MAC_OWNR,@MAC_SPAN ; Izit a spanning entry?
	 je	 short LOADHI_RES_XCONT ; Jump if so

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 bx,es:[0].MAC_OWNR ; Get new owner entry

	 jmp	 short LOADHI_RES_NEXTMAC ; Go around again

LOADHI_RES_XCONT:

	 mov	 END_VEC.VSEG,dx ; Save ending point as DX:0
	 mov	 END_VEC.VOFF,0

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 or	 dx,dx		; Did the program go resident?
	 jnz	 short LOADHI_RES_XNULL ; Jump if so

; Check for 386LOAD GETSIZE with UMBs allocated.  We may need to force
; a 0-length LSEG for Maximize...
	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jz	 short @F	; No, so treat it as an error

	 call	 UNLINK_TLSEG	; Unlink temporary LSEG and check for UMBs

	 test	 LSEG.LSEG_FLAG,@LSEG_UMB ; Izit a UMB loader?
	 jz	 short @F	; Jump if not

	 call	 CLEANUP	; Turn off load state

	 or	 LSEG.LSEG_FLAG,@LSEG_XRES ; Mark as non-resident
	 mov	 LSEG.LSEG_RPARA,dx ; No paras requested including INT block
	 jmp	 LOADHI_EXIT2	; Join common exit

@@:
	 jmp	 ERR_NONRES2	; Join common error code

LOADHI_RES_XNULL:
	 or	 LCL_FLAG,@LCL_RES ; Mark as resident request

	 sub	 dx,EXEC_INTMAC ; Less int handler MAC segment
	 dec	 dx		; Count out MAC paragraph
	 mov	 LSEG.LSEG_RPARA,dx ; Save as # paras requested including INT block

; See how much initialization room the driver used
; Note we do this before the re-allocate in case the program
; freed its environment.  If we merged that into the program
; MAC entry, we would calculate the wrong value in GETSIZE.

	 mov	 es,EXEC_PRGMAC ; Get program MAC segment
	 assume  es:nothing	; Tell the assembler about it

; For some reason, some TSRs free themselves before going resident

	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Has it been freed?
	 jne	 short @F	; Jump if not

	 mov	 ax,EXEC_PSP	; Get segment of program PSP
	 mov	 es:[0].MAC_OWNR,ax ; Mark as owned
@@:
	 call	 GETSIZE	; Get the initialization size

; In case we're tight on room in this region and the program shares the
; region with its environment, release the environment now
; Note we must save the value of EXEC_ENVMAC before we free it

	 mov	 cx,EXEC_ENVMAC ; Get segment of environment MAC

	 test	 OPT_FLAG,@OPT_ENAME ; Name-only in the environment?
	 jz	 short @F	; Not this time

	 call	 ENVFREE	; Free it first
@@:
	 mov	 es,EXEC_PRGMAC ; Get program MAC segment
	 assume  es:nothing	; Tell the assembler about it

; Re-allocate to resident size, merging free blocks above EXEC_PRGMAC
; into itself unless length of MAC entry at ES:0 is less than resident
; size.

	 mov	 ax,LSEG.LSEG_RPARA ; Get # paras requested including INT block
	 sub	 ax,INT_NPAR	; Less # paras for INT block
	 dec	 ax		; Count out MAC paragraph

	 cmp	 ax,es:[0].MAC_NPAR ; Izit already less than resident size?
	 ja	 short LOADHI_DONE ; Jump if so (multiple blocks or holes)

	 push	 ax		; Save # paras
	 mov	 bx,-1		; Get largest size
	 call	 MODMEM 	; Modify memory block ES:0 to BX paras
	 call	 MODMEM 	; Modify memory block ES:0 to BX paras
	 pop	 ax		; Restore

	 cmp	 ax,es:[0].MAC_NPAR ; Izit within range?
	 ja	 short LOADHI_NOROOM ; No, now what !!!
	 je	 short LOADHI_DONE ; That's all folks

	 xchg	 ax,es:[0].MAC_NPAR ; Save as new MAC length
	 sub	 ax,es:[0].MAC_NPAR ; Subtract to get size of remaining MAC
	 dec	 ax		; Account for MAC paragraph
	 mov	 cl,@MAC_MID	; Mark as middle entry
	 xchg	 cl,es:[0].MAC_TYPE ; Save as new type

	 mov	 dx,es		; Copy current segment
	 inc	 dx		; Count in MAC paragraph
	 add	 dx,es:[0].MAC_NPAR ; Add in # paragraphs in this entry
	 mov	 es,dx		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[0].MAC_TYPE,cl ; Save as new type
	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Entry is unallocated
	 mov	 es:[0].MAC_NPAR,ax ; Save as new # paragraphs
LOADHI_DONE:
	 clc			; Indicate all went well

	 jmp	 short LOADHI_EXIT ; Join common exit code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it


; AX has the # paras needed

LOADHI_NOROOM:
	 assume  ds:PGROUP,es:nothing,ss:nothing ; Tell the assembler about it

	 push	 cs		; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it
if @OEM_FLEX

; Restore INT 67h if intercepted

	 call	 REST67 	; Restore it
endif				; IF @OEM_FLEX

; De-allocate any EMS memory

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short LOADHI_ERR ; Yes, then none of the below used

if @OEM_FLEX
	 call	 REST_EMS	; Restore it
endif				; IF @OEM_FLEX

	 lea	 bx,AZS_UGHROOM ; Tell 'em the very bad news
	 push	 bx		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 call	 FMT_CHG	; Format the change line for "SIZE=nnn,nnn" w/AX

	 call	 WAITFF 	; Wait until hell freezes over
				; (or the user presses Alt-255)

	 jmp	 short LOADHI_ERR ; Join common error code

	 assume  ds:nothing,es:nothing,ss:nothing ; Tell the assembler about it

ERR_NONRES2:
	 and	 LCL_FLAG,not @LCL_PSP ; Mark as no longer intercepted

	 test	 OPT_FLAG,@OPT_QUIET ; Skip error message?
	 jnz	 short @F	; Yes

	 lea	 ax,AZS_XRES	; Tell user we're not resident
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message
@@:
LOADHI_ERR:
	 stc			; Indicate something went wrong
LOADHI_EXIT:
	 pushf			; Save flags
	 call	 CLEANUP	; Restore previously set values
	 popf			; Restore flags
LOADHI_EXIT2:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LOADHI	 endp			; End LOADHI procedure
	 NPPROC  INST_ENV -- Install The Environment
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Install the environment in high DOS memory.

|

	 REGSAVE <cx,si,di,es>	; Save registers

	 mov	 es,EXEC_ENVMAC ; Get segment of environment MAC
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,EXEC_PSP	; Get segment of program PSP
	 mov	 es:[0].MAC_OWNR,cx ; Save as owner

	 mov	 di,size MAC_STR ; ES:DI ==> environment destination

; Because of a difference in DOS 5.x, we must handle the case where
; our environment segment # is zero.

	 mov	 cx,PSP_ENVIR_PTR ; Get segment # of our environment
	 jcxz	 INST_ENV_XENV	; Jump if not present

	 push	 ds		; Save for a moment

	 mov	 ds,cx		; Address it
	 assume  ds:nothing	; Tell the assembler about it
	 xor	 si,si		; DS:SI ==> our own environment

	 mov	 cx,ENV_HEAD	; Get size of environment head
     rep movsb			; Move it into place

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 jmp	 short INST_ENV_TAIL ; Join common code

INST_ENV_XENV:
	 mov	 ax,0000h	; Leading separator
	 stosw			; Save in "environment"
	 mov	 ax,0001h	; Leading separator
	 stosw			; Save in "environment"
INST_ENV_TAIL:
	 lea	 si,LCL_PATH	; DS:SI ==> local copy of FID
	 mov	 cx,ENV_TAIL	; Get size of environment tail
     rep movsb			; Move it into place

	 REGREST <es,di,si,cx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INST_ENV endp			; End INST_ENV procedure
	 NPPROC  CLEANUP -- Restore Previously Set Values
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Turn off load state.
Mark as inactive.
Mark our interrupt handlers as inactive.
Free memory if no resident request
Restore above INTs if not intercepted.
Restore old PSP.
Restore old DTA.
Clear environment segment in PSP if free.
Split low and high memory allocation chains.
De-allocate any EMS memory
Free the TSRs file handles if it didn't go resident

|

	 REGSAVE <ax,bx,cx,dx,si,ds,es> ; Save registers

; Set owner of the INTMAC to the loaded program and unlink the LSEG
; at PGROUP:LSEG from the chain.  We'll also check for UMBs which may
; have gotten allocated during GETSIZE.

	 push	 es		; Save for a moment

	 mov	 es,EXEC_INTMAC ; Get interrupt handler MAC segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,EXEC_PSP	; Get segment of program PSP
	 mov	 es:[0].MAC_OWNR,ax ; Save as owner

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 call	 UNLINK_TLSEG	; Unlink the temporary LSEG entry from the chain

	 mov	 ax,LSEG.LSEG_EPAR0 ; Get # environment paras (before)
	 mov	 LSEG.LSEG_EPAR1,ax ; Save as ...	      (after)

; See if the program freed its environment

	 mov	 cx,EXEC_ENVMAC ; Get segment of environment
	 jcxz	 CLEANUP_ENVFREE ; Jump if it's been freed

	 mov	 es,cx		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Izit free?
	 jne	 short @F	; Jump if not
CLEANUP_ENVFREE:
	 mov	 LSEG.LSEG_EPAR1,0 ; Save as # paras (after)
@@:

; If requested to do so, leave the program name only in the environment

	 test	 OPT_FLAG,@OPT_ENAME ; Name-only in the environment?
	 jz	 short CLEANUP_XNAME ; Not this time

	 test	 LCL_FLAG,@LCL_RES ; Izit resident?
	 jz	 short CLEANUP_XNAME ; No, so don't free environment

	 call	 ENVNAME	; Allocate a minimal environment with name only
	 jnc	 short CLEANUP_XNAME ; Join common code
				; Return with AX = error code

	 cmp	 ax,@DOSERR_XMEM ; Izit insufficient memory?
	 je	 short CLEANUP_XNAME ; Yes, just ignore it

	 cmp	 ax,@DOSERR_XMAC ; Izit MAC error?
	 je	 short CLEANUP_ERRMAC ; Yes

	 lea	 ax,AZS_UGHUGH	; Tell 'em the very bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 jmp	 short CLEANUP_ERRCOM ; Join common error code

CLEANUP_ERRMAC:
	 lea	 ax,AZS_UGHMAC	; Tell 'em the very bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message
CLEANUP_ERRCOM:
	 call	 KEYWAIT	; Wait for an acknowledgement
				; Return with key in AX

	 cmp	 ax,00FFh	; Wait for Alt-255
	 jne	 short CLEANUP_ERRCOM ; We go no further until then

	 jmp	 short CLEANUP_REST ; Join common restore code

CLEANUP_XNAME:
	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short CLEANUP_REST ; Yes, just restore the interrupts

; If not resident, mark as free any MAC entries whose owner is EXEC_PSP

	 mov	 es,POVR_MAC	; Get segment of first MAC in high DOS memory
	 assume  es:nothing	; Tell the assembler about it

	 test	 LCL_FLAG,@LCL_RES ; Request residency?
	 jnz	 short CLEANUP_MERGE ; Yes, just merge adjacent entries

	 mov	 bx,EXEC_PSP	; Get segment of program PSP (owner)
	 call	 MAC_FREE	; Free all MACs owned by BX starting at ES:0
	 jc	 short CLEANUP_ERRMAC ; Jump if MAC error
CLEANUP_MERGE:
	 push	 es		; Merge starting at this segment
	 call	 MAC_MERGE	; Merge adjacent free MACs starting at ES:0
	 jc	 short CLEANUP_ERRMAC ; Jump if MAC error
CLEANUP_REST:

; Split low and high memory allocation chains

	 call	 SPLIT_MAC	; Split 'em

if @OEM_FLEX

; Restore INT 67h if intercepted

	 call	 REST67 	; Restore it

; De-allocate any EMS memory

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short @F	; Yes, so INST_EMS was not called

	 call	 REST_EMS	; Restore it
@@:
endif				; IF @OEM_FLEX

CLEANUP_XCOPY:
	 REGREST <es,ds,si,dx,cx,bx,ax> ; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CLEANUP  endp			; End CLEANUP procedure
	 NPPROC  ENVFREE -- Free The Program's Environment
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Free the program's environment

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,es>	; Save registers

	 mov	 es,EXEC_ENVMAC ; Get segment of environment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,EXEC_PSP	; Get segment of program PSP

	 cmp	 ax,es:[0].MAC_OWNR ; Izit still owned by us?
	 jne	 short ENVFREE_XENV ; No, just don't free it

	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Free it
ENVFREE_XENV:
	 push	 POVR_MAC	; Get segment of first MAC in high DOS memory
	 call	 MAC_MERGE	; Merge adjacent free MACs starting at ES:0
	 jc	 short ENVFREE_EXIT ; Jump if MAC error (note CF=1)

	 mov	 es,EXEC_PSP	; Get segment of program PSP
	 assume  es:nothing	; Tell the assembler about it

	 assume  ds:nothing,es:PGROUP ; Lie to the assembler
	 mov	 PSP_ENVIR_PTR,0 ; Zero it
	 assume  ds:PGROUP,es:nothing ; Now tell the truth

	 mov	 EXEC_ENVMAC,0	; Zero the local pointer

	 clc			; Indicate all went well
ENVFREE_EXIT:
	 REGREST <es,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ENVFREE  endp			; End ENVFREE procedure
	 NPPROC  ENVNAME -- Allocate Environment Name Only
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Allocate room for environment name only.
Attempt to put it into the same region as before
if possible.  Otherwise, allocate it into any region.
Allocate it at the bottom of the region.

On exit:

CF	 =	 0 all went OK

CF	 =	 1 something went wrong
AX	 =	 error code

|

	 REGSAVE <bx,cx,si,di,es> ; Save registers

	 mov	 MACLOC,@MACLOC_LO ; Use low fit algorithm in environment block

	 mov	 bx,ENV_TAIL	; Get byte size of "d:\path\filename.ext",0
	 add	 bx,1+1+2+(16-1) ; Plus 00, 00, 0001, and rounded up to a
				; para boundary
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 bx,cl		; Convert from bytes to paras
	 mov	 LSEG.LSEG_EPAR1,bx ; Save as size of environment (after)
	 inc	 LSEG.LSEG_EPAR1 ; Count in the MAC para

; If we're loading low, load the environment there, too
; BX has the # paras to allocate

	 test	 OPT_FLAG,@OPT_GSIZE ; Izit specifed?
	 jnz	 short ENVNAME_GSIZE ; Jump if so

	 xor	 ch,ch		; Zero to use as word
	 mov	 cl,LSEG.LSEG_EREG ; Get environment region #

	 cmp	 cl,@NOTSPEC	; Izit specified?
	 jne	 short @F	; Jump if it is

	 mov	 cl,LSEG.LSEG_PREG ; Use same region as program
@@:
	 call	 GETMEM_REG	; Search for BX paras from region CX
				; returning AX=MAC entry
	 jnc	 short @F	; Join common code

	 call	 GETMEM_SRCH	; Search for BX paras from any region
				; returning AX = MAC entry, CX = region #
	 jc	 short ENVNAME_EXIT ; Jump if error, code in AX (note CF=1)

	 mov	 LSEG.LSEG_EREG,cl ; Save region #
@@:
	 mov	 es,ax		; Get segment of environment MAC
	 assume  es:nothing	; Tell the assembler about it

	 call	 GETMEM_SUB	; Allocate BX paras from MAC at ES:0
				; returning AX = MAC entry
	 jc	 short ENVNAME_EXIT ; Jump if error, code in AX (note CF=1)

	 jmp	 short ENVNAME_COM ; Join common code

ENVNAME_GSIZE:
	 DOSCALL @GETMEM	; Allocate BX paras, return with AX = segment
	 jc	 short ENVNAME_EXIT ; Jump if error, code in AX (note CF=1)

	 dec	 ax		; Back off to MAC entry
ENVNAME_COM:
	 mov	 EXEC_ENVMAC,ax ; Save as actual segment of environment MAC

	 mov	 es,ax		; Get segment of environment MAC
	 assume  es:nothing	; Tell the assembler about it

	 mov	 di,size MAC_STR ; Skip over MAC structure
	 xor	 ax,ax		; End of environment is 00 00
	 stosw			; Save in environment
	 mov	 ax,1		; Separator
	 stosw			; Save in environment
	 mov	 ax,di		; Copy current offset
	 sub	 ax,size MAC_STR ; Reduce by MAC structure
	 mov	 ENV_HEAD,ax	; Save as end of environment header

	 lea	 si,LCL_PATH	; DS:SI ==> local copy of FID
	 mov	 cx,ENV_TAIL	; Get size of environment tail
     rep movsb			; Move it into place

	 mov	 ax,EXEC_PSP	; Get segment of program PSP
	 mov	 es:[0].MAC_OWNR,ax ; Save as owner

	 mov	 es:[0].MAC_BACK,0 ; Clear LSEG back link field

	 mov	 ax,es		; Get segment of environment MAC
	 inc	 ax		; Skip over MAC paragraph

	 mov	 es,EXEC_PSP	; Get segment of program PSP
	 assume  es:nothing	; Tell the assembler about it

	 assume  ds:nothing,es:PGROUP ; Lie to the assembler
	 mov	 PSP_ENVIR_PTR,ax ; Save as new environment
	 assume  ds:PGROUP,es:nothing ; Now tell the truth

	 clc			; Indicate all went well
ENVNAME_EXIT:
	 REGREST <es,di,si,cx,bx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ENVNAME  endp			; End ENVNAME procedure
	 NPPROC  SPLIT_MAC -- Split Low and High MACs
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Split low and high MACs

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

	 test	 LC2_FLAG,@LC2_JMAC ; Izit joined?
	MJ z	 SPLIT_MAC_EXIT ; No, skip this

	 mov	 es,OLDENDMAC	; Get para of previous ending MAC
	 assume  es:nothing	; Tell the assembler about it

	 test	 LC2_FLAG,@LC2_ZMAC ; Special ending MAC entry?
	 jz	 short @F	; Jump if not

	 mov	 es:[0].MAC_TYPE,@MAC_END ; Mark as ending MAC entry
	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Mark as free again
	 mov	 es:[0].MAC_NPAR,0 ; Mark as empty

	 jmp	 short SPLIT_MAC_EXIT ; Join common exit code

@@:
	 test	 LC2_FLAG,@LC2_LINK58 ; Are we using DOS 5 services?
	 jz	 short @F	; Jump if so

	 mov	 ax,@MACALG*256+03h ; Set link state to BX
	 sub	 bx,bx		; Unlink arenas
	 DOSCALL		; CF=0 if OK

; Turn off high DOS bits in strategy
	 mov	 ax,@MACALG*256+00h ; Get current strategy
	 DOSCALL		; AX contains strategy
	 mov	 bx,ax		; Copy old strategy
	 and	 bx,(@STRA_LAST or @STRA_BEST) ; Save low order bits
	 mov	 ax,@MACALG*256+01h ; Set strategy
	 DOSCALL		; ...to BX
	 jmp	 short SPLIT_MAC_EXIT ; Join common exit

@@:
; Walk the MAC chain to find the new ending entry.  It's not
; necessarily OLDENDMAC; low DOS may have been allocated by
; the program we loaded high.

	 mov	 ax,cs		; Start with our PSP
	 dec	 ax		; Back off to MAC
@@:
	 mov	 es,ax		; Address MAC entry
	 assume  es:nothing	; Tell the assembler

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit the end?
	 je	 short @F	; Jump if so

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Izit a normal MAC entry?
	 jne	 short SPLIT_MAC_EXIT ; Jump if not (???)

	 inc	 ax		; Skip MAC entry
	 add	 ax,es:[0].MAC_NPAR ; Point to next MAC
	 cmp	 ax,OLDENDMAC	; Izit our boy?
	 jne	 short @B	; Go around again if not

@@:
; ES:0 ==> Entry preceding our spanning entry.
; Delete spanning entry

	 mov	 es:[0].MAC_TYPE,@MAC_END ; Mark as ending MAC entry
	 inc	 es:[0].MAC_NPAR ; Add back in spanning MAC entry

; Restore previous data

	 mov	 ax,es		; Get current MAC segment
	 add	 ax,es:[0].MAC_NPAR ; Plus # paras in MAC entry
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it
	 xor	 di,di		; ES:DI ==> data we're replacing

	 lea	 si,JMACOLD	; DS:SI ==> save area
	 mov	 cx,size MAC_STR ; Get # bytes in MAC entry
     rep movsb			; Restore it
SPLIT_MAC_EXIT:
	 and	 LC2_FLAG,not (@LC2_JMAC or @LC2_ZMAC) ; Clear flags

	 REGREST <es,di,si,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SPLIT_MAC endp			; End SPLIT_MAC procedure
	 NPPROC  PLUG_MAC -- Plug holes in MAC
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Traverse MAC chain from beginning of low DOS until end.  Since
this is called before JOIN_MAC, low and high DOS chains may not
be linked.

We allocate all free entries (this never includes EXEC_PRGMAC,
as this has long since been allocated) as @MAC_PLUG.  We'll
free them in UNPLUG_MAC.

In the 386LOAD GETSIZE case, we don't want to plug high DOS.
If it's INSTALL=, we might have a UMB allocator on our hands.
If it's from the command processor, we've already determined
via BATPROC that it's not a UMB allocator.  However, we might
have a UMB allocator (like SMARTDRV.EXE) loaded high via 386load
and toggled low in Phase II of Maximize.

On entry:
nothing

On exit:
nothing

|

	 REGSAVE <ax,bx,es>	; Save

	 mov	 ax,DMAC	; Get starting MAC entry
PLUG_MAC_NEXT:
	 mov	 es,ax		; Address MAC entry
	 assume  es:nothing	; Tell the assembler

	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Izit a hole we should plug?
	 jne	 short @F	; Jump if not

	 mov	 es:[0].MAC_OWNR,@MAC_PLUG ; Insert plug
@@:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit the end?
	 je	 short PLUG_MAC_EXIT0 ; We're done if so

	 add	 ax,es:[0].MAC_NPAR ; Add paras in region
	 inc	 ax		; Plus MAC entry

	 jmp	 short PLUG_MAC_NEXT ; Go around again

PLUG_MAC_EXIT0:
	 cmp	 ax,POVR_MAC	; Did we do high DOS yet?
	 jae	 short PLUG_MAC_EXIT1 ; Jump if so

	 test	 OPT_FLAG,@OPT_GSIZE ; Izit specified?
	 jnz	 short PLUG_MAC_EXIT1 ; Jump if so (leave high DOS alone)

	 mov	 ax,POVR_MAC	; Get starting segment in high DOS
	 cmp	 ax,-1		; Does it exist?
	 jne	 short PLUG_MAC_NEXT ; Process high DOS MAC if so

PLUG_MAC_EXIT1:
	 REGREST <es,bx,ax>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

PLUG_MAC endp			; End PLUG_MAC procedure
	 NPPROC  UNPLUG_MAC -- Free holes in MAC
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Traverse MAC chain from beginning of low DOS until end, freeing
blocks previously grabbed by PLUG_MAC.	Note that if we're not
running GETSIZE, we'll traverse the high DOS MAC twice, but there's
no harm done.

On entry:
nothing

On exit:
nothing

|

	 REGSAVE <ax,bx,es>	; Save

	 mov	 ax,DMAC	; Get starting MAC entry
UNPLUG_MAC_NEXT:
	 mov	 es,ax		; Address MAC entry
	 assume  es:nothing	; Tell the assembler

	 cmp	 es:[0].MAC_OWNR,@MAC_PLUG ; Did we plug it previously?
	 jne	 short @F	; Jump if not

	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Free it
@@:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit the end?
	 je	 short UNPLUG_MAC_EXIT0 ; Jump if so

	 add	 ax,es:[0].MAC_NPAR ; Add paras in region
	 inc	 ax		; Add MAC entry
	 jmp	 short UNPLUG_MAC_NEXT ; Go around again

UNPLUG_MAC_EXIT0:
	 cmp	 ax,POVR_MAC	; Did we do high DOS yet?
	 jae	 short UNPLUG_MAC_EXIT1 ; Jump if so

	 mov	 ax,POVR_MAC	; Get starting segment in high DOS
	 cmp	 ax,-1		; Does it exist?
	 jne	 short UNPLUG_MAC_NEXT ; Process high DOS MAC if so

UNPLUG_MAC_EXIT1:
	 REGREST <es,bx,ax>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

UNPLUG_MAC endp 		; End UNPLUG_MAC procedure

NCODE	 ends			; End NCODE segment

	 MEND			; End TSRHIGH module
