;' $Header:   P:/PVCS/MAX/386MAX/QMAX_I21.ASV   1.3   30 May 1997 10:44:42   BOB  $
	 title	 QMAX_I21 -- 386MAX INT 21h Handler
	 page	 58,122
	 name	 QMAX_I21

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment HICODE,	dword-aligned, public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'
	       Data    segment JDATA, dword-aligned, public, class 'jcode'
	       Group DLGROUP:
	       Program segment DLCODE,	para-aligned, public, class 'dlcode'
	       Data    segment DLDATA,	word-aligned, public, class 'dlcode'
	       Data    segment DLDATZ,	dword-aligned, public, class 'dlcode'
	       Group XGROUP:
	       Data    segment XDATA,	dword-aligned, public, class 'xdata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ALLMEM.INC
	 include MAC.INC
	 include 386.INC
	 include PTR.INC
	 include OPCODES.INC
	 include CPUFLAGS.INC
	 include DOSERR.INC
	 include ALLMEM.INC
	 include MASM5.MAC
	 include EXE.INC
	 include EXEC.INC
	 include OPEN.INC
	 include EMM2CALL.INC

	 include QMAX_CFG.INC
	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
	 include LOAD_SEG.INC
	 include UTIL_OPT.INC
.list

PGROUP	 group	 CODE,HICODE,ECODE,EDATA
IGROUP	 group	 ICODE
JGROUP	 group	 JCODE,JDATA
DLGROUP  group	 DLCODE,DLDATA,DLDATZ
XGROUP	 group	 XDATA
PSPGRP	 group	 PSPSEG


PSPSEG	 segment use16 at 0	; Start PSPSEG segment
	 assume  ds:PSPGRP

	 extrn	 PSP_ENVIR_PTR:word
	 extrn	 PSP_TERMINATE:dword
;;;;;;;; extrn	 PSP_LCL_STACK:dword

PSPSEG	 ends			; End PSPSEG segment



CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 OLDINT21_VEC:dword

if @OEM_HIFILL
	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

;;;;;;;; extrn	 CM2_FLAG:word
;;;;;;;; include QMAX_CM2.INC
;;;;;;;;
	 extrn	 MSC_FLAG:word
	 include QMAX_MSC.INC

	 extrn	 QMAX_VER:byte
	 include QMAX_HDM.INC

	 extrn	 XMS_FLAG:word	; **BOTH** high and low memory
	 include QMAX_XMS.INC

;;;;;;;; extrn	 OLDDOS:word
;;;;;;;; extrn	 LOWSIZE:word
	 extrn	 P1ST_MAC:dword
	 extrn	 POVR_MAC:word
	 extrn	 LOADSEG:word
endif				; IF @OEM_HIFILL
	 extrn	 PORT67:word

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  ds:PGROUP

	 extrn	 EXTMAC_ORIG:byte

HICODE	 ends			; End HICODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

	 extrn	 PDC_FLAG:word
	 include QMAX_I31.INC

MSG_APPLNAME_LEN equ 78 	; Maximum length of last application
LENTXT2 MSG_APPLNAME,<MSG_APPLNAME_LEN dup (?)> ; Name of last application

if @OEM_HIFILL
	 extrn	 HIMEM_CS:word
endif				; IF @OEM_HIFILL

	 extrn	 DSTK_FLAG:byte

	 extrn	 SEL_DS3:word
	 extrn	 SEL_DSJG3:word
	 extrn	 SEL_4GB3:word

	 extrn	 DOSVER:word

	 public  POVR_LIE	; Value to lie about POVR_MAC
POVR_LIE dw	 ?		; Segment of EMPTY_HIMAC

	 public  PBAPPBASE
PBAPPBASE label dword
	 dw	 PGROUP:MSG_APPLNAME[size LENTXT_LEN],0 ; Offset in PGROUP of basename from last EXEC

; Define the list of roots to LFLG_STR lists.  Each list is terminated
; with -1.
	 public  CFGLIST,@CFGLIST_LEN
CFGLIST label tbyte
	LLST_STR <'M',0,PGROUP:INT21_EXEC_M0> ; Lie about POVR_MAC
	LLST_STR <'M',1,PGROUP:INT21_EXEC_M1> ; Return physical addr on XMS lock
	LLST_STR <'M',2,PGROUP:INT21_EXEC_M2> ; Deny XMS UMB requests
	LLST_STR <'M',3,PGROUP:INT21_EXEC_M3> ; Locally disable 5800 support
	LLST_STR <'K',0,PGROUP:INT21_EXEC_K> ; Disable SOP
	LLST_STR <'X',0,PGROUP:INT21_EXEC_X> ; Disable 4B support
	LLST_STR <'B',0,PGROUP:INT21_EXEC_B> ; Restrict allocate to one region
	LLST_STR <'H',2,PGROUP:INT21_EXEC_H2> ; Force rounding up (/256 + 256)
	LLST_STR <'U',1,PGROUP:INT21_EXEC_U1> ; Enforce descriptor usage rules
	 public  CFGLIST_XMEI
CFGLIST_XMEI label tbyte
	LLST_STR <'U',2,PGROUP:INT21_EXEC_U2> ; Disallow Mouse Event Interrupts
	LLST_STR <'U',3,PGROUP:INT21_EXEC_U3> ; Zero demand-allocated pages
	LLST_STR <'U',4,PGROUP:INT21_EXEC_U4> ; Limit lockable page count to 15MB
	LLST_STR <'U',5,PGROUP:INT21_EXEC_U5> ; Lie about the DPMI version # (say it's 0.90)
	LLST_STR <'U',6,PGROUP:INT21_EXEC_U6> ; Skip swapfile for this DPMI client
	LLST_STR <'U',7,PGROUP:INT21_EXEC_U7> ; Lie about availability of DPMI services
@CFGLIST_LEN equ ($-CFGLIST)/(size LLST_STR)

EDATA	 ends			; End EDATA segment


JDATA	 segment use16 dword public 'jcode' ; Start JDATA segment
	 assume  ds:JGROUP

	 extrn	 JSEL_DS3:word
	 extrn	 FILLPAT:dword

if @OEM_HIFILL
	 public  MAC_STRA,LaLINKFLG,LaLINKSEG,BFLG_IDX,BFLG_BASE,BFLG_LIM
	 public  TEMP_PSP,CUR_PSP
MAC_STRA dw	 0		; Initialized from DOS at startup time
LaLINKFLG dd	 89h		; Linear address of link flag
LaLINKSEG dd	 8Ch		; Linear address of link segment
BFLG_IDX dw	 ?		; Index of high DOS region to restrict
				; allocations to for 386LOAD.CFG B flag (base:1)
BFLG_BASE dw	 ?		; Starting para for PSPs to restrict for B flag
BFLG_LIM dw	 ?		; Highest para for PSPs to restrict
TEMP_PSP dw	 ?		; Temporary PSP during device processing
CUR_PSP  dw	 ?		; Current PSP at INT21_MACFNS time

	 public  I21MAC_TAB
I21MAC_TAB dw	 JGROUP:I21MAC_48xx ; Allocate block for BX paras
	 dw	 JGROUP:I21MAC_49xx ; Free block at ES:0
	 dw	 JGROUP:I21MAC_4Axx ; Resize block ES:0 to BX paras
	 dw	 JGROUP:I21MAC_DOS ; Load for EXEC or EXEC
	 dw	 JGROUP:I21MAC_4Cxx ; Exit or exit with return code
	 dw	 JGROUP:I21MAC_5800 ; Return strategy in BX
	 dw	 JGROUP:I21MAC_5801 ; Set strategy to BX
	 dw	 JGROUP:I21MAC_5802 ; Return high DOS link state in AL
	 dw	 JGROUP:I21MAC_5803 ; Set high DOS link state to BX
@I21MAC_TABMAX equ ($-I21MAC_TAB)/(type I21MAC_TAB) ; Limit for index into above table

RINFO_STR struc

RINFO_LSEG1 dw	 ?		; First LSEG in region
RINFO_LSEG2 dw	 ?		; Second LSEG in region
RINFO_LAST dw	 ?		; Last paragraph in region

RINFO_STR ends

	 public  RINFO,LAST_RINFO,MNAME,LOADSIZE,MAXPARA
	 align	 4		; Ensure it's dword aligned
RINFO	 RINFO_STR @NREGS dup (<0,0,0>) ; Region info structure
LAST_RINFO dw	 JGROUP:RINFO	; Last RINFO_STR offset
@MNAME_LEN equ (size MAC_STR)-MAC_NAME ; Length of MAC_NAME field
MNAME  db	 @MNAME_LEN dup (?) ; Value for MAC_NAME field in LSEG
LOADSIZE dd	 ?		; Minimum load size
MAXPARA dw	 ?		; Maximum paras to allocate for PSP
				; This value is saved in LSEG_EPAR0 for PSPs.
				; We'll try to allocate a block of this
				; size using the strategy saved in $LSEG_STRA.
				; If this fails, we'll use the largest.

endif				; IF @OEM_HIFILL

XSTACK_STR struc
XSTACK_RES dw	 ?		; Linear address of resource (IVT entry)
XSTACK_OFF dw	 ?		; Offset of signature data within interrupt
XSTACK_SIG dw	 ?		; Offset within JGROUP of signature data
XSTACK_SIGLEN dw ?		; Length of signature
XSTACK_STR ends

	 public  XSDAT_2523,XSTACK
XSDAT_2523 db	 8Ch,0D0h	; MOV AX,SS
	 db	 2Eh,3Bh,06h	; CMP AX,CS:xxxx
@XSDAT_2523LEN equ $-XSDAT_2523
XSTACK	 label word		; Table of XSTACK_STR entries
	 XSTACK_STR <08h*4,03Dh,JGROUP:XSDAT_2523,@XSDAT_2523LEN> ; Int 21 AX=2523h- NFOLIO.EXE
@XSTACK_CNT equ ($-XSTACK)/(size XSTACK_STR) ; Number of entries

JDATA	 ends			; End JDATA segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

; The following bitmap and count are used during READ_CFG only, but it's
; more convenient to define it here.

	 public  CFGBITCNT,CFGBITMAP
CFGBITCNT db	 ?		; Count of valid bit entries
CFGBITMAP db	 ((@CFGLIST_LEN+(8-1))/8) dup (?) ; Bitmap for CFGLIST matches
				; in case of multiple matches

XDATA	 ends			; End XDATA segment


DLDATA	 segment use16 word public 'dlcode' ; Start DLDATA segment
	 assume  ds:DLGROUP

	 public  DLMAC_STRA,DLPORT67
DLMAC_STRA dw	 ?		; Local copy of MAC_STRA
DLPORT67 dw	 ?		; Port for back door Int 67h (EMM2CALL)

	 public  DLDOSVEC
DLDOSVEC dd	 ?		; OLDINT21_VEC for calls to DOS

	 public  ORIGAX,DLEXEHDR,DLSSSP,DLOLDPSP
ORIGAX	 dw	 ?		; AX on entry (AL=00/01)
DLEXEHDR EXE_STR <>		; EXE header data
DLSSSP	 dd	 ?		; Saved stack across 4B01 call
DLOLDPSP dw	 ?		; PSP on entry to EMU4B

	 public  LDBG
LDBG	 LOADDBG_STR <> 	; ES:BX structure for 4B01 call

DLDATA	 ends			; End DLDATA segment


DLCODE	 segment use16 para public 'dlcode' ; Start DLCODE segment
	 assume  cs:DLGROUP

if @OEM_HIFILL
	 NPPROC  EMU4B -- Emulate 4B00/4B01 with high DOS open
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

This code executes in V86 mode after it is copied down to a block
allocated in low DOS.  Note that there are no calls and no data
references, as the starting offset will become 0.

Entry is gained via an IRETD from INT21_MACFNS with the registers
from the original Int 21 4B00/4B01 call.  If the call is successful,
we'll return directly to the caller.  Otherwise, we pass the call
down to DOS.

Note that all high DOS allocation calls are made via XMS UMB services.
Use of any Int 21 calls handled by EXT_MACFNS in QMAX_OVR will clear
the temporary closure of high DOS, which we'll still need if we pass
the call on down to DOS.

The IP, CS, and flags on the stack on entry are the original values
from entry to QMAX_OVR.

- Read the EXE header and calculate the minimum load size.
- Pass any errors on to original handler (pre-MAX) after freeing emulation
  code segment.
- Plug all low DOS MAC entries.  Always unplug 'em on exit.
- Create 2 LSEG entries in each high DOS region.  Plug the remaining
  space in any region without sufficient space for 2 LSEG entries.
- Execute a 4B01 using the old Int 21 vector (pushf/cli/far call).
- If the call failed and strategy is high only, return error to caller.
- If the call failed and strategy is high first, pass it on to DOS.
- Each high DOS region will have one of the following configurations:
    1		  2		  3		  4
  Free		[Free]		[Free]		[Free]
  LSEG2 	PSP		PSP		Environment
  LSEG1 	Environment	LSEG2		LSEG2
		LSEG2		LSEG1		LSEG1
		LSEG1
  For #1, free both LSEG entries.
  For #2, fixup the environment pointer in the PSP.  Link both LSEG entries.
  For #3 (#4 implied), convert LSEG2 to a block owned by PSP.  Link LSEG1.
  For #4, free LSEG2, relocate the environment downward, fixup the
  PSP environment pointer, and link LSEG1.  Note that in this case,
  the free space may come before the environment (strategy=last fit).
  This can happen with case #s 2 and 3 as well but we don't care since we're
  not moving anything around.
Exit:
- Free emulation code.	If success, load SS:SP, set PSP, and jump to first
  instruction of code in high DOS.  Otherwise, pass original 4B00
  request on to pre-MAX Int 21 handler (which should be DOS).

|

EMU4B_STR struc
EMU4B_BP dw	 ?		; BP on entry

EMU4B_ES dw	 ?		; ES on entry
EMU4B_DS dw	 ?		; DS on entry
EMU4B_DX dw	 ?		; DX on entry
EMU4B_ECX dd	 ?		; ECX on entry
EMU4B_BX dw	 ?		; BX on entry
EMU4B_EAX dd	 ?		; EAX on entry
;--------- End registers saved in EMU4B -----
EMU4B_IRET dd	 ?		; Return CS:IP
EMU4B_FLAGS dw	 ?		; Caller's flags

EMU4B_STR ends

	 REGSAVE <eax,bx,ecx,dx,ds,es> ; Save (must match EMU4B_STR)

	 push	 bp		; Prepare to address stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 cld			; Ensure string ops go forward
.8086
	 mov	 ORIGAX,ax	; Save AX on entry (AL=00/01)
DOT386 p

; Read the EXE header and calculate the minimum load size
	 mov	 al,@OPEN_R	; File sharing mode (read-only, compatibility)
	 DOSCALL @OPENF2	; Open file DS:DX, return handle in AX

	 push	 cs		; Get code segment
	 pop	 ds		; Address for data references
	 assume  ds:DLGROUP	; Tell the assembler

	 jc	 short EMU4B_XHEADER ; Jump if open failed

	 mov	 bx,ax		; Copy to handle register
	 lea	 dx,DLEXEHDR	; Address EXE header
	 mov	 cx,size EXE_STR ; Maximum bytes to read
	 DOSCALL @READF2	; Read CX bytes from BX into DS:DX
	 jc	 short EMU4B_CLOSEHDR ; Jump if read failed

; If it's a .COM file, we need the physical file size.
	 xor	 cx,cx		; Set CX:DX to 0:0
	 xor	 dx,dx
	 mov	 al,2		; Code to move file pointer to EOF
	 DOSCALL @MOVFP2	; Move file pointer by CX:DX as per AL
				; Return with DX:AX == file size in bytes
	 jc	 short EMU4B_CLOSEHDR ; Jump if something went wrong

	 push	 dx		; High word of file size
	 mov	 cx,ax		; Low word ...
	 mov	 dx,DLPORT67	; Address INT 67h through the back door
	 mov	 ax,@EMM2_DLGROUP*256 + 03h ; DLGROUP subfunction 3: calculate
				; load size
	 out	 dx,al		; Request EMM service; ignore return

EMU4B_CLOSEHDR:
	 DOSCALL @CLOSF2	; Close file BX
EMU4B_XHEADER:

; Now do the 4B01 call using the old Int 21 vector.  Note that this
; is perfectly valid since we've gained control in QMAX_OVR.  The
; only thing we're doing is changing (possibly) a 4B00 to a 4B01.
; Since the structure used for 4B01 has two additional fields for
; output, we've copied the 4B00 structure to a local copy in protected mode.

	 DOSCALL @GETPS0	; Return current PSP in BX
	 mov	 DLOLDPSP,bx	; Save for later

; Normally, the Enter Exec State call (4B05) would be made at this
; point.  We can assume the caller has already done this if necessary.
; To be safe, save BP and SS:SP across call
	 push	 bp		; Save addressibility to EMU4B_STR

	 mov	 DLSSSP.VSEG,ss ; Save segment
	 mov	 DLSSSP.VOFF,sp ; ... offset

	 mov	 ax,(@EXEC shl 8) or 01h ; Load for execution
	 mov	 cx,[bp].EMU4B_ECX.ELO ; Value on entry (undefined)
	 mov	 dx,[bp].EMU4B_DX ; Offset of pathname
	 mov	 ds,[bp].EMU4B_DS ; Segment of pathname
	 assume  ds:nothing	; Tell the assembler

	 mov	 bx,[bp].EMU4B_BX ; Offset of 4B01 block
	 mov	 es,[bp].EMU4B_ES ; Segment ...
	 assume  es:nothing	; Tell the assembler

; If we're converting 4B00 to 4B01, we need to use the copy of the EXEC_STR
; with space for output fields.
	 cmp	 [bp].EMU4B_EAX.ELO.LO,0 ; Are we converting?
	 jne	 short @F	; Jump if not

	 push	 cs		; Use code segment
	 pop	 es		; Segment of LOADDBG_STR
	 assume  es:nothing	; Tell the assembler

	 lea	 bx,DLGROUP:LDBG ; Offset of LOADDBG_STR
@@:
	 mov	 bp,[bp].EMU4B_BP ; Reload original BP

; N.B. We shouldn't have any trouble with recursive calls to 4B00/01.
; This code and data aren't freed until after we return from this call,
; so other 4B calls will get their own unique code and data stubs.
; This could be a problem if there's no low DOS free.  If this proves
; to be the case (so far it hasn't) we may need to avoid creating
; duplicate stubs, which means this code will need to push and pop
; various values around this call.
	 pushf			; Simulate interrupt
	 cli			; Nobody move
	 call	 DLDOSVEC	; Call previous Int 21 handler (DOS)
	 assume  ds:nothing,es:nothing,ss:nothing
				; Return with CF significant
				; Note CF is tested after we've restored
				; the stack, BP, and DS.

	 lss	 sp,DLSSSP	; Reload stack
	 assume  ss:nothing	; Tell the assembler

	 pop	 bp		; Restore addressibility to EMU4B_STR

;;;;;;;; On entry to the 4B01 call, SS:SP was saved in the old PSP.  This is the
;;;;;;;; SS:SP that will be restored when coming back via function 4C.	We need
;;;;;;;; to adjust this value to account for our interception of the call...
;;;;;;;  mov	 ds,DLOLDPSP	; Address original PSP
;;;;;;;  assume  ds:PSPGRP	; Tell the assembler
;;;;;;;
;;;;;;;  pushf			; Save CF
;;;;;;;  add	 PSP_LCL_STACK.VOFF,(size EMU4B_STR) + 2 ; Add local saves,
;;;;;;; 			; variables, IRET frame and saved BP
;;;;;;;  popf			; Restore

	 push	 cs		; Get code segment
	 pop	 ds		; Address for data references
	 assume  ds:DLGROUP	; Tell the assembler

	 jnc	 short EMU4B_LOADOK ; Jump if call succeeded

; The call failed; free all the high DOS LSEG entries now.
	 push	 dx		; Save
	 mov	 dx,DLPORT67	; Address INT 67h through the back door
	 mov	 ax,@EMM2_DLGROUP*256 + 02h ; DLGROUP subfunction 2: free RINFO
	 out	 dx,al		; Request EMM service; ignore return

; If the call failed and strategy is high first, pass it on to DOS.
	 bt	 DLMAC_STRA,$STRA_HIONLY ; Izit high only?
	 jnc	 short @F	; Jump if not

; If the call failed and strategy is high only, return error to caller.
	 or	 [bp].EMU4B_FLAGS,mask $CF ; Indicate error
	 mov	 [bp].EMU4B_EAX.ELO,ax ; Save return error code
	 mov	 [bp].EMU4B_BX,bx ; Return register values
	 mov	 [bp].EMU4B_ECX.ELO,cx
	 mov	 [bp].EMU4B_DX,dx
@@:
	 stc			; Indicate failure
	 jmp	 EMU4B_EXIT	; Join common exit

EMU4B_LOADOK:
; Call was successful.	We need to adjust the Int 22 value in the PSP.
; If it's a 4B01 call, we'll return to the caller.  Otherwise, set up
; the stack and jump.  Note that the PSP is now set to the program we're
; about to execute.
	 mov	 [bp].EMU4B_EAX.ELO,ax ; Save return AX (parsed FCB flags)
	 mov	 [bp].EMU4B_BX,bx ; Save (undefined)
	 mov	 [bp].EMU4B_ECX.ELO,cx
	 mov	 [bp].EMU4B_DX,dx

	 and	 [bp].EMU4B_FLAGS,not (mask $CF) ; Clear CF for return

	 DOSCALL @GETPS0	; Return PSP in BX
	 mov	 dx,bx		; Save for later
	 mov	 es,bx		; Address it
	 assume  es:PSPGRP	; Tell the assembler

; Default Int 22 value should be the original Int 21 return address
	 mov	 eax,[bp].EMU4B_IRET ; Get return address
	 mov	 PSP_TERMINATE,eax ; Set return from program being loaded

	 cmp	 ORIGAX.LO,0	; Do we need to regain control?
	 jne	 short @F	; Jump if not

	 mov	 PSP_TERMINATE.VOFF,offset DLGROUP:EMU4B_I22RET ; Blast in return offset
	 mov	 PSP_TERMINATE.VSEG,cs ; Return segment

@@:
; We'll handle the RINFO correlation upstairs in extended memory.
; We've already got the PSP in BX to pass up.  The load size and
; maximum allocation are already upstairs.
; We also need to re-write the resize filler pattern over whatever's
; past the load size, since some programs (like NETBEUI) calculate
; their load size dynamically, and we need the filler pattern scan.
	 push	 dx		; Save
	 mov	 dx,DLPORT67	; Address INT 67h through the back door
	 mov	 ax,@EMM2_DLGROUP*256 + 01h ; DLGROUP subfunction 1: process
				; RINFO
	 out	 dx,al		; Request EMM service; ignore return

	 clc			; Indicate success

EMU4B_EXIT:
	 pop	 bp		; Restore

	 REGREST <es,ds,dx,ecx,bx,eax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler

EMU4B_FREE:
	 jnc	 short EMU4B_NOERR ; Jump if no error

; If the strategy is high only, we need to fail and return to the caller.
	 bt	 DLMAC_STRA,$STRA_HIONLY ; Izit high only?
EMU4B_FREECS:
	 pushf			; Save flags
	 REGSAVE <ax,es>	; Save

	 mov	 ax,cs		; Get code segment
	 dec	 ax		; Back off to MAC entry
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

; If we have an LSEG (if we allocated from high DOS, for example) it will
; get freed in CHECK_ORPHAN.
	 cli			; We can't let an interrupt handler come
				; along and catch us with our pants down...
	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Free it

	 REGREST <es,ax>	; Restore
	 assume  es:nothing	; Tell the assembler

	 popf			; Restore

	 jnc	 short @F	; Jump if not high only

	 iret			; Return to caller

@@:
; We're passing it on to DOS.  It won't fit high anyway, so we'll let
; DOS try to load it low.  First, we need to ensure DOS can't allocate
; the environment high.
	 push	 ax		; Save

	 push	 dx		; Push register for OUT "call"
	 mov	 dx,DLPORT67	; Address INT 67h through the back door
	 mov	 ah,@EMM2_TMPCLOSE ; Close arenas and flag next INT21_MACFNS
	 out	 dx,al		; Request EMM service

	 pop	 ax		; Restore

	 jmp	 DLDOSVEC	; Jump to original DOS entry point

; If 4B01, return to caller.  If 4B00, begin execution.
EMU4B_NOERR:
	 cmp	 ORIGAX.LO,01	; Izit load only?
	 cmc			; CF=1 if 4B01
	 jb	 short EMU4B_FREECS ; Join common code to free CS and IRET

; Set up stack and begin execution.  Note that all registers have been
; returned from the 4B01 call.	We need to load DS [and ES] with the
; new PSP.
	 REGSAVE <si,di,bp,ds,es> ; Save essential registers

	 REGSAVE <ax,bx,cx,dx>	; Save

	 DOSCALL @GETPS0	; Return PSP in BX
	 mov	 ds,bx		; Address PSP via DS
	 assume  ds:nothing	; Tell the assembler

	 mov	 es,bx		; Address PSP via ES
	 assume  es:nothing	; Tell the assembler

	 REGREST <dx,cx,bx,ax>	; Restore

.8086
	 mov	 DLSSSP.VSEG,ss ; Save segment
	 mov	 DLSSSP.VOFF,sp ; ... offset
DOT386 p

	 lss	 sp,LDBG.LOADDBG_SSSP ; Set up stack
	 assume  ss:nothing	; Tell the assembler

	 jmp	 LDBG.LOADDBG_CSIP ; Start execution of child program

	 assume  ds:nothing,es:nothing,ss:nothing

; We'll return directly to the caller from here.  Note that we should have
; the same registers we went into the 4B01 call with.  We've already cleared
; CF in the caller's flags.
	 public  EMU4B_I22RET
EMU4B_I22RET:
	 cli			; Nobody move

	 lss	 sp,DLSSSP	; Restore caller's stack
	 assume  ss:nothing	; Tell the assembler

	 REGSAVE <ax>		; Save

	 mov	 ax,cs		; Get code segment
	 dec	 ax		; Back off to MAC entry
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 REGREST <ax>		; Restore

; If we have an LSEG (if we allocated from high DOS, for example) it will
; get freed in CHECK_ORPHAN.
	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Free it

	 REGREST <es,ds,bp,di,si> ; Restore essential registers
	 assume  ds:nothing,es:nothing ; Tell the assembler

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

EMU4B	 endp			; End EMU4B procedure
endif				; IF @OEM_HIFILL
DLCODE	 ends			; End DLCODE segment


DLDATZ	 segment use16 dword public 'dlcode' ; Start DLDATZ segment
	 assume  ds:DLGROUP

	 extrn	 DLGROUP_END:word

DLDATZ	 ends			; End DLDATZ segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

if @OEM_DPMI
	 extrn	 INT21_DPMI:near
endif				; IF @OEM_DPMI

ICODE	 ends			; End ICODE segment


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP,ds:JGROUP

if @OEM_HIFILL
	 extrn	 MAC_ALLOC:far
	 extrn	 MAC_REALLOC:far
	 extrn	 MAC_FREE:far
	 extrn	 LOAD_INPRO:near
endif				; IF @OEM_HIFILL
	 extrn	 FMAC_MERGESUB:far

if @OEM_HIFILL
	 NPPROC  LOADSUB -- Convert DX,AX to EAX
	 assume  ds:JGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Round EAX up to a paragraph boundary and add 100h bytes for a PSP.

On entry:
EAX	 File size in bytes

On exit:
EAX	 Adjusted size in bytes + PSP (rounded up to paragraph boundary)

|

	 add	 eax,16-1	; Round up to paragraph boundary
	 and	 eax,not (16-1) ; Knock of extra bits
	 add	 eax,100h	; Add size of PSP

	 mov	 LOADSIZE,eax ; Save for later

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOADSUB endp			; End LOADSUB procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 NPPROC  CALC_EXEHDR -- Determine load size
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Calculate load size for program and save it upstairs.  We'll use it
in DO_RINFO.

On entry:
EBX	 Address of DLGROUP
DX,AX	 File size in bytes

On exit:
MAXPARA and LOADSIZE calculated.

|

	 REGSAVE <eax,ebx,ecx,ds> ; Save

	 mov	 ds,SEL_DSJG3	; Address JGROUP
	 assume  ds:JGROUP	; Tell the assembler

	 mov	 MAXPARA,-1	; Assume maximum size for .COM file

	 shl	 eax,16 	; Move low order word out of the way
	 mov	 ax,dx		; Get high order word
	 ror	 eax,16 	; EAX = file size in bytes
	 call	 LOADSUB	; Call common code

	 add	 ebx,offset DLGROUP:DLEXEHDR ; Get offset within AGROUP

; Account for .EXE header if any

	 cmp	 AGROUP:[ebx].EXE_SIGN,@EXE_SIGN ; Izit an .EXE file?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[ebx].EXE_SIGN,@EXE_SIG2 ; Izit an .EXE file?
	 jne	 near ptr CEH_EXIT ; Jump if it's a .COM file
@@:

; Calculate file size based upon EXE header values

	 movzx	 eax,AGROUP:[ebx].EXE_Q512 ; Get image size/512 quotient
	 movzx	 ecx,AGROUP:[ebx].EXE_R512 ; Get image size/512  remainder

; Adjust the file size Q512 down by one if R512 not zero

	 cmp	 cx,1		; Iff R512 != 0, CF=0
	 cmc			; Iff R512 != 0, CF=1
	 sbb	 ax,0		; Subtract 1 iff R512 != 0

	 imul	 eax,eax,512	; EAX *= 512
	 add	 eax,ecx	; Add remainder to product
	 call	 LOADSUB	; Call common code

; DOS apparently adds EXE_MIN to the image size when checking for available
; space.  The commented-out code below causes NETPOPUP.EXE to fail in the
; LanMan environment when the fit is very close to our calculated load size.
; SMARTDRV isn't a good candidate for testing this because its EXE_MIN is 0.
;;;;;;;; If the EXE header size is larger than EXE_MIN, we need to leave it
;;;;;;;; in the load size requirement.	Otherwise, DOS can't load it.
;;;;;;;  movzx	 eax,AGROUP:[ebx].EXE_HSIZ ; Get size of header in paras
;;;;;;;  shl	 eax,4-0	; Convert paras to bytes
;;;;;;;  sub	 LOADSIZE,eax	; Subtract out of load size
;;;;;;;
	 push	 LOADSIZE	; Save image size

	 movzx	 eax,AGROUP:[ebx].EXE_MIN ; Get minimum # paras needed above
;;;;;;;  cmp	 ax,AGROUP:[ebx].EXE_HSIZ ; Izit larger than the header size?
;;;;;;;  ja	 short @F	; Jump if so
;;;;;;;
;;;;;;;  mov	 ax,AGROUP:[ebx].EXE_HSIZ ; Use the larger value
;;;;;;;@@:
	 shl	 eax,4-0	; Convert paras to bytes
	 add	 LOADSIZE,eax	; Add into load size

	 pop	 eax		; Get image size

; Calculate the maximum allocation
	 shr	 eax,4-0	; Convert bytes to paras
	 sub	 ax,AGROUP:[ebx].EXE_HSIZ ; Subtract header
	 add	 ax,AGROUP:[ebx].EXE_MAX ; Add maximum paras needed above
	 jc	 short @F	; Jump if overflow - use default of -1

	 mov	 MAXPARA,ax	; Save for later
@@:
; Ensure the stack fits into memory

	 movzx	 eax,AGROUP:[ebx].EXE_SS ; Get initial SS in paras
	 shl	 eax,4-0	; Convert paras to bytes
	 movzx	 ecx,AGROUP:[ebx].EXE_SP ; Get initial SP (high word of ECX=0)
	 add	 eax,ecx	; Top of initial stack in bytes
	 add	 eax,100h	; Add PSP

	 cmp	 eax,LOADSIZE	; Izit bigger?
	 jbe	 short @F	; Jump if not

	 mov	 LOADSIZE,eax	; Save as load size
@@:
CEH_EXIT:
	 REGREST <ds,ecx,ebx,eax> ; Restore
	 assume  ds:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_EXEHDR endp		; End CALC_EXEHDR procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 NPPROC  UNPLUG_MAC -- Unplug low and high DOS MAC entries
	 assume  ds:JGROUP,es:PGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Find any MAC entries with owner @MAC_PLUG, and convert 'em to @MAC_FREE.

|

	 REGSAVE <eax,ebx>	; Save

	 pushf			; Save IF state

; Unplug high and low DOS
	 cli			; Nobody move
	 mov	 ax,P1ST_MAC.VSEG ; Get starting MAC in low DOS
UNPLUG_NEXT:
	 movzx	 ebx,ax 	; Get MAC para
	 shl	 ebx,4-0	; Convert paras to bytes
	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_PLUG ; Izit a plug?
	 jne	 short @F	; Jump if not

	 mov	 AGROUP:[ebx].MAC_OWNR,@MAC_FREE ; Free it
@@:
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit the end?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit valid?
	 jne	 short @F	; Jump if not

	 add	 ax,AGROUP:[ebx].MAC_NPAR ; Add length of block
	 inc	 ax		; Skip MAC entry
	 jmp	 short UNPLUG_NEXT ; Go around again

@@:
; We've reached the end of a chain.  If it's below POVR_MAC, go around again.
	 cmp	 ax,POVR_MAC	; Did we do high DOS yet?
	 jnb	 short @F	; Jump if so

	 mov	 ax,POVR_MAC	; Get starting high DOS MAC entry
	 cmp	 ax,-1		; Is there any high DOS?
	 jne	 short UNPLUG_NEXT ; Jump if not

@@:
	 popf			; Restore (IF significant)

	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UNPLUG_MAC endp 		; End UNPLUG_MAC procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 NPPROC  FREE_RINFO -- Free RINFO entries
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

If the 4B01 call we made to DOS failed, free all the LSEG entries
we previously allocated in DO_RINFO.

|

	 REGSAVE <bx,ecx,ds>	; Save

	 mov	 ds,SEL_DSJG3	; Address JGROUP
	 assume  ds:JGROUP	; Tell the assembler

	 mov	 bx,LAST_RINFO	; Get last LSEGs allocated
FREER_NEXT:
	 sub	 ecx,ecx	; Get a zero value
	 xchg	 cx,JGROUP:[bx].RINFO_LSEG1 ; Get first LSEG MAC and clear it
	 jcxz	 @F		; Jump if not allocated

	 shl	 ecx,4-0	; Convert paras to bytes
	 mov	 AGROUP:[ecx].MAC_OWNR,@MAC_FREE ; Set your chickens FREE!
@@:
	 sub	 ecx,ecx	; Get a zero value
	 xchg	 cx,JGROUP:[bx].RINFO_LSEG2 ; Get second LSEG MAC and clear it
	 jcxz	 @F		; Jump if not allocated

	 shl	 ecx,4-0	; Convert paras to bytes
	 mov	 AGROUP:[ecx].MAC_OWNR,@MAC_FREE ; Set your chickens FREE!
@@:
	 sub	 bx,size RINFO_STR ; Back off to previous region
	 cmp	 bx,offset JGROUP:RINFO ; Have we reached the beginning?
	 jnb	 short FREER_NEXT ; Go around again if not

	 call	 UNPLUG_MAC	; Pull out the plugs

	 REGREST <ds,ecx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FREE_RINFO endp 		; End FREE_RINFO procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 NPPROC  ADD_LSEG -- Add LSEG to chain
	 assume  ds:JGROUP,es:PGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Link LSEG into chain.

On entry:

Arguments passed on stack.

|

ADDL_ARGSTR struc

ADDL_CS  dw	 ?		; Caller's CS
ADDL_MAXPARA dw  ?		; Maximum paragraph request
ADDL_LaOWNRMAC dd ?		; Linear address of MAC entry associated with
				; LSEG
ADDL_RPARA dw	 ?		; Resident paras (not including interrupt block
				; and its MAC)
ADDL_LSEG dw	 ?		; Segment of new LSEG MAC
ADDL_PSP dw	 ?		; Owner's PSP
ADDL_LOADSIZE dd ?		; Load size in bytes (0 for environment)

ADDL_ARGSTR ends

ADDL_STACK struc

	 db	 (size PUSHAD_STR) dup (?) ; Saved registers

	 dw	 ?		; Near return

ADDL_ARGS db	 (size ADDL_ARGSTR) dup (?) ; Arguments

ADDL_STACK ends

	 pushad 		; Save

	 mov	 ebp,esp	; Address ADDL_STACK

	 movzx	 edi,[ebp].ADDL_ARGS.ADDL_LSEG ; Get segment of new LSEG MAC
	 mov	 esi,[ebp].ADDL_ARGS.ADDL_LaOWNRMAC ; Address owner's MAC entry
	 mov	 AGROUP:[esi].MAC_BACK,di ; Save as back link for MAC_FREE

; Find the end of the LSEG chain
	 movzx	 eax,LOADSEG	; Get starting LSEG (always valid)
@@:
	 shl	 eax,4-0	; Convert paras to bytes
	 mov	 ebx,eax	; Save address
	 movzx	 eax,AGROUP:[ebx].LSEG_NEXT ; Get pointer to next entry
	 cmp	 ax,-1		; Izit the end?
	 jne	 short @B	; Go around again if not

; AGROUP:EBX ==> last LSEG in chain
	 inc	 di		; Skip LSEG MAC entry
	 mov	 AGROUP:[ebx].LSEG_NEXT,di ; Hook into end of LSEG chain
	 dec	 di		; Back off to LSEG MAC entry
	 shl	 edi,4-0	; Convert paras to bytes
	 shr	 ebx,4-0	; Get segment of previous LSEG
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_PREV,bx ; Save backward link
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_NEXT,-1 ; Mark as end of chain

	 mov	 ax,[ebp].ADDL_ARGS.ADDL_PSP ; Get PSP
;;;;;;;  mov	 AGROUP:[edi].MAC_OWNR,ax ; Set ownership
	 mov	 AGROUP:[edi].MAC_OWNR,@MAC_LSEG ; Set ownership

	 REGSAVE <esi,edi,es>	; Save

	 lea	 esi,JGROUP:MNAME ; Name value to copy
	 lea	 edi,AGROUP:[edi].MAC_NAME[0] ; Destination for copy
	 mov	 ecx,@MNAME_LEN ; Bytes to move

	 push	 gs		; Get AGROUP selector
	 pop	 es		; Address for string move
	 assume  es:AGROUP	; Tell the assembler

S32 rep  movs	 <AGROUP:[edi].LO,MNAME[esi]> ; Initialize name field

	 REGREST <es,edi,esi>	; Restore
	 assume  es:PGROUP	; Tell the assembler

	 mov	 ax,[ebp].ADDL_ARGS.ADDL_MAXPARA ; Maximum paras for allocation
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_EPAR0,ax ; Save it
	 mov	 bx,mask $LSEG_EP1UPSP ; Assume it's a PSP
	 mov	 eax,[ebp].ADDL_ARGS.ADDL_LOADSIZE ; Get load size
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_LSIZE,eax ; Save it

	 or	 eax,eax	; Izit a PSP?
	 mov	 eax,')PSP'     ; Assume it is
	 jnz	 short @F	; Good guess

	 mov	 eax,')vne'     ; Mark as 'env)'
	 sub	 bx,bx		; No ancestor bitmap
				; The environment always gets placed first,
				; so we needn't worry about ancestors.

@@:
	 mov	 dx,[ebp].ADDL_ARGS.ADDL_CS ; Get caller's CS
	 cmp	 dx,POVR_MAC	; Izit in high DOS?
	 jb	 short @F	; Jump if not

	 or	 bx,mask $LSEG_EP1UDLGHI ; DLGROUP was allocated high
@@:
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_EPAR1,bx ; Save ancestor bitmap
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_FNE.EDD[0],' BMU' ; Mark as 'UMB '
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_FNE.EDD[4],' B4(' ; Mark as '(4B '
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_FNE.EDD[8],eax ; Mark as 'PSP)' or 'env)'

	 mov	 ax,AGROUP:[edi].MAC_NPAR ; Get length of interrupt block
	 inc	 ax		; Add its MAC para
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_NPARA,ax ; INT block
				; Including MAC para
	 add	 ax,[ebp].ADDL_ARGS.ADDL_RPARA ; Add resident size
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_RPARA,ax ; Resident size in paras
				; (Does not include the PSP or environment MAC)
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_RPAR2,0 ; No forced SIZE=

	 movzx	 eax,[ebp].ADDL_ARGS.ADDL_RPARA ; Get resident size in paras
	 shl	 eax,4-0	; Convert paras to bytes
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_ASIZE,eax
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_ISIZE,eax

	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_PREG,@NOTSPEC ; Not specified
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_EREG,@NOTSPEC ; Not specified
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_GRP,@GRPUMB

; We need to fill in LSEG_OWNRHI with the correct MAC entry so CHECK_ORPHSUB
; can toss out LSEGs when their associated entries have been freed via
; the back door (mov es:[0].MAC_OWNR,@MAC_FREE...).
	 mov	 eax,[ebp].ADDL_ARGS.ADDL_LaOWNRMAC ; Get MAC entry associated with LSEG
	 shr	 eax,4-0	; Convert bytes to paras
	 inc	 ax		; Skip to PSP or environment
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_OWNRHI,ax ; Mark as owner
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_INSTLO,0 ; Mark as no low DOS to instance
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_INSTLEN,0 ; Mark as no low DOS to instance

	 mov	 ax,MAC_STRA	; Get current allocation strategy
	 and	 ax,(mask $STRA_LAST) or (mask $STRA_BEST) ; Isolate bits to save
	 shl	 ax,$LSEG_STRA	; Move into position for LSEG_FLAG

	 cmp	 AGROUP:[esi].MAC_TYPE,@MAC_END ; Izit the final entry?
	 je	 short ADD_MAX	; Jump if so

	 movzx	 ebx,AGROUP:[esi].MAC_NPAR ; Get length of environment / PSP
	 inc	 bx		; Skip MAC entry
	 shl	 ebx,4-0	; Convert paras to bytes
	 add	 ebx,esi	; Address next MAC entry

	 push	 ebx		; Pass MAC entry address
	 FCALL	 IZIT_MACLINK	; Is AGROUP:EBX a DOS 5 spanning entry?
	 je	 short ADD_MAX	; Jump if so

	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_SPAN ; Was maximum allocated?
	 je	 short ADD_MAX	; Jump if so

; Finally, if our CS is the next MAC in line, it's a maximum allocation.
; This may happen for LOADHIGH, where there's nothing in high DOS, so
; we allocate our stub at the high end of high DOS.
	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_TEMP ; Izit DLGROUP?
	 jne	 short @F	; Jump if not

	 mov	 dx,[ebp].ADDL_ARGS.ADDL_CS ; Get caller's CS
	 dec	 dx		; Back off to MAC entry
	 shr	 ebx,4-0	; Get segment of MAC
	 cmp	 bx,dx		; Izit ours?
	 jne	 short @F	; Jump if not

ADD_MAX:
	 or	 ax,@LSEG_IMAX	; Initial allocation is for maximum space
@@:
	 or	 ax,@LSEG_UMB	; Mark as a UMB
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG_FLAG,ax ; Save flags

; We don't act on the @I15_FROUND flag now, since the initialization size
; can't be larger than the first allocation.  When (if) we resize downwards
; and scan for filler pattern, we'll test (and reset) @LSEG2_NOV.  It tells
; us to round the initialization size up to a 256 byte boundary and add an
; extra 256 bytes.
	 test	 I15_FLAG,@I15_FROUND ; Force rounding via H2 flag?
	 setnz	 al		; AL=1 if so, 0 if not
	 shl	 al,$LSEG2_NOV	; Move into position for LSEG2_FLAG
	 mov	 AGROUP:[edi+(size MAC_STR)].LSEG2_FLAG,al ; Save for later
				; (Note @LSEG2_NOV is clear)

	 popad			; Restore

	 ret	(size ADDL_ARGSTR) ; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ADD_LSEG endp			; End ADD_LSEG procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 NPPROC  DO_RINFO -- Process RINFO entries
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Process RINFO and link LSEG entries for PSP at BX:0.

On entry:
AX	 Caller's CS
BX	 PSP
RINFO	 Initialized in CPY_DLGROUP
LAST_RINFO JGROUP offset of last valid entry in RINFO
LOADSIZE,MAXPARA Initialized in CALC_EXEHDR

On exit:
None.

|

	 pushad 		; Save

	 cld			; Ensure string ops forwardly

	 mov	 ebp,esp	; Address PUSHAD_STR

	 REGSAVE <ds>		; Save

	 mov	 ds,SEL_DSJG3	; Address JGROUP
	 assume  ds:JGROUP	; Tell the assembler

; Each high DOS region will have one of the following configurations:
;   1		  2		  3		  4
; Free		[Free]		[Free]		[Free]
; LSEG2 	PSP		PSP		Environment
; LSEG1 	Environment	LSEG2		LSEG2
;		LSEG2		LSEG1		LSEG1
;		LSEG1
; For #1, free both LSEG entries.
; For #2, fixup the environment pointer in the PSP.  Link both LSEG entries.
; For #3 (#4 implied), convert LSEG2 to a block owned by PSP.  Link LSEG1.
; For #4, free LSEG2, relocate the environment downward, fixup the
; PSP environment pointer, and link LSEG1.  Note that in this case,
; the free space may come before the environment (strategy=last fit).
; This can happen with case #s 2 and 3 as well but we don't care since we're
; not moving anything around.

	 movzx	 ebx,bx 	; Clear high order word
	 shl	 ebx,4-0	; Convert paras to bytes
	 sub	 ecx,ecx	; Clear high word
	 assume  gs:PSPGRP	; Tell a lie
	 mov	 cx,PSP_ENVIR_PTR[ebx] ; Get environment segment
	 assume  gs:AGROUP	; Retract nose

	 mov	 bx,LAST_RINFO	; Get offset of last RINFO_STR

; If the 386LOAD.CFG 'B' flag is in effect (@I15_XSPLIT), we need to
; set BFLG_BASE and BFLG_LIM to the PSP, and BFLG_IDX to the region
; (base:1) the PSP appears in.
	 mov	 ax,[ebp].PUSHAD_EBX.ELO ; Get PSP segment
	 test	 I15_FLAG,@I15_XSPLIT ; Is the 386LOAD 'B' flag in effect?
	 jz	 short DORI_NOXSPLIT ; Jump if not

	 mov	 BFLG_BASE,ax	; Starting PSP to restrict
	 mov	 BFLG_LIM,ax	; Highest PSP to restrict
	 dec	 ax		; Segment of PSP MAC
	 mov	 BFLG_IDX,1	; Starting region
; Walk through the high DOS MAC until we find our PSP.	Bump index for every
; spanning entry we find.
	 mov	 di,POVR_MAC	; Start of high DOS
DORI_NEXTRIDX:
	 movzx	 esi,di 	; Get segment value
	 shl	 esi,4-0	; Convert paras to bytes
	 cmp	 di,ax		; Izit what we're looking for?
	 je	 short DORI_NOXSPLIT ; Jump if so

	 cmp	 AGROUP:[esi].MAC_TYPE,@MAC_END ; Izit the end of the line?
	 je	 short DORI_NOXSPLIT ; Jump if so

	 cmp	 AGROUP:[esi].MAC_TYPE,@MAC_MID ; Izit a valid entry?
	 jne	 short DORI_NOXSPLIT ; Jump if not

	 add	 di,AGROUP:[esi].MAC_NPAR ; Get segment of next MAC
	 inc	 di		; Skip this MAC entry

	 push	 esi		; Pass address of MAC entry
	 FCALL	 IZIT_MACLINK	; Izit a DOS-5 style spanning entry?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[esi].MAC_OWNR,@MAC_SPAN ; Izit a spanning entry?
	 jne	 short DORI_NEXTRIDX ; Go around again if not

@@:
	 inc	 BFLG_IDX	; Bump region index
	 jmp	 short DORI_NEXTRIDX ; Go around again

DORI_NOXSPLIT:
; JGROUP:BX ==> Last RINFO_STR
; ECX = Environment segment
; [ebp].PUSHAD_EBX.ELO = PSP segment

	 cli			; Nobody move
DORI_FINDLSEG:
; Check for case 3/2
	 mov	 ax,[ebp].PUSHAD_EBX.ELO ; Get PSP segment for compare
	 cmp	 ax,JGROUP:[bx].RINFO_LSEG1 ; Is the PSP below this region?
	 jb	 short @F	; Jump if so

	 cmp	 ax,JGROUP:[bx].RINFO_LAST ; Is the PSP above this region?
	 jbe	 near ptr DORI_XCASE4 ; Jump if not

@@:
	 cmp	 cx,JGROUP:[bx].RINFO_LSEG1 ; Is the environment in this region?
	 jbe	 short @F	; Jump if not (Case 1)

	 cmp	 cx,JGROUP:[bx].RINFO_LAST ; Is it in a region above this one?
	 jbe	 short DORI_CASE4 ; Jump if not

@@:
	 jmp	 DORI_FLSFREE	; Join common code to free LSEGs

DORI_CASE4:
; Case 4 (environment only)
; For #4, free LSEG2, relocate the environment downward only if it's
; contiguous to LSEG2, fixup the PSP environment pointer, and link LSEG1.
	 REGSAVE <cx>		; Save

	 movzx	 eax,JGROUP:[bx].RINFO_LSEG2 ; Get destination for environment

	 mov	 edx,eax	; Get segment of LSEG2 MAC
	 shl	 edx,4-0	; Convert paras to bytes

	 inc	 ax		; Skip LSEG2 MAC entry
	 add	 ax,AGROUP:[edx].MAC_NPAR ; Skip to environment MAC

	 dec	 cx		; Back off to environment MAC
;;;;;;;  mov	 ds,cx		; Address environment MAC
;;;;;;;  assume  ds:nothing	; Tell the assembler

	 movzx	 esi,cx 	; Source in paras
	 shl	 esi,4-0	; Convert to bytes

	 cmp	 ax,cx		; Was environment contiguous to LSEG2?
	 mov	 ecx,edx	; Address of MAC to free
	 jne	 short DORI_CASE4B ; Jump if not

	 mov	 edi,edx	; Destination is MAC of old LSEG2

	 movzx	 ecx,AGROUP:[esi].MAC_NPAR ; Get length to move in paras
	 inc	 cx		; Add MAC para
	 shl	 ecx,4-2	; Convert paras to dwords

	 push	 es		; Save
	 push	 gs		; Get AGROUP selector
	 pop	 es		; Address for string move
	 assume  es:AGROUP	; Tell the assembler

S32 rep  movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy environment down
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler

	 mov	 al,@MAC_MID	; New MAC type for environment
	 xchg	 al,AGROUP:[edx].MAC_TYPE ; Get previous MAC type

;;;;;;;  mov	 cx,es		; Get new environment MAC
;;;;;;;  mov	 es,dx		; Address PSP
;;;;;;;  assume  es:PSPSEG	; Tell the assembler
;;;;;;;
;;;;;;;  mov	 ds,cx		; Address environment MAC
;;;;;;;  assume  ds:nothing	; Tell the assembler
;;;;;;;
	 mov	 ecx,edx	; Copy address of new environment MAC
	 shr	 ecx,4-0	; Convert to paras
	 inc	 cx		; Skip environment's MAC entry
	 movzx	 esi,[ebp].PUSHAD_EBX.ELO ; Get PSP segment
	 shl	 esi,4-0	; Convert paras to bytes
	 assume  gs:PSPGRP	; Tell a lie
	 mov	 PSP_ENVIR_PTR[esi],cx ; Save new environment segment in PSP
	 assume  gs:AGROUP	; Retract nose

	 add	 cx,AGROUP:[edx].MAC_NPAR ; Skip environment contents
	 shl	 ecx,4-0	; Convert to bytes

;;;;;;;  mov	 es,cx		; Address next MAC entry
;;;;;;;  assume  es:nothing	; Tell the assembler

	 mov	 AGROUP:[ecx].MAC_TYPE,al ; Save previous type from environment segment
	 mov	 AGROUP:[ecx].MAC_NPAR,@LSEGPARA ; Length (previous size of LSEG2)
	 mov	 AGROUP:[ecx].MAC_BACK,0 ; Clear LSEG back link

	 mov	 esi,edx	; Get address of new environment MAC
DORI_CASE4B:
; ECX = linear address of LSEG2 (if not contiguous) or entry following new
; environment MAC.
; ESI = address of (new) environment MAC
	 mov	 AGROUP:[ecx].MAC_OWNR,@MAC_FREE ; Free it

	 PUSHD	 0		; No load size for environment
	 push	 [ebp].PUSHAD_EBX.ELO ; PSP
	 push	 JGROUP:[bx].RINFO_LSEG1 ; Segment of LSEG MAC
	 push	 AGROUP:[esi].MAC_NPAR ; Length of environment in paras
	 push	 esi		; Environment MAC entry
	 push	 0		; No maximum paragraph request for environment
	 push	 [ebp].PUSHAD_EAX.ELO ; Caller's CS
	 call	 ADD_LSEG	; Add LSEG to chain

	 REGREST <cx>		; Restore

	 jmp	 near ptr DORI_FLSLOOP ; Join common code

DORI_XCASE4:
; Cases 1 and 4 have already been eliminated.  Check for case 2.
	 cmp	 cx,JGROUP:[bx].RINFO_LSEG1 ; Is environment also in this region?
	 jb	 short @F	; Jump if not

	 cmp	 cx,JGROUP:[bx].RINFO_LAST ; Is environment above the end?
	 jbe	 near ptr DORI_XCASE3 ; Jump if not

@@:
; Case 3 (PSP only)
; For #3, add length of LSEG2 to LSEG1's MAC entry.
	 movzx	 esi,JGROUP:[bx].RINFO_LSEG1 ; Get segment of 1st LSEG
	 shl	 esi,4-0	; Convert paras to bytes
	 add	 AGROUP:[esi].MAC_NPAR,1+@LSEGPARA ; Eat second LSEG and its MAC para

; Link LSEG1 into LSEG chain
	 push	 LOADSIZE	; Load size in bytes
	 movzx	 edi,[ebp].PUSHAD_EBX.ELO ; Get PSP
	 push	 di		; Pass it unchanged
	 push	 JGROUP:[bx].RINFO_LSEG1 ; Pass MAC segment of first LSEG
; We're really saving the initialization size here.  We'll set the
; @LSEG_IMAX flag if the initial allocation is for the entire region.
	 dec	 di		; Back off to PSP MAC entry
	 shl	 edi,4-0	; Convert paras to bytes
	 push	 AGROUP:[edi].MAC_NPAR ; Pass it as resident size
	 push	 edi		; Pass address of PSP MAC entry
	 push	 MAXPARA	; Maximum paragraph request (usually -1)
	 push	 [ebp].PUSHAD_EAX.ELO ; Caller's CS
	 call	 ADD_LSEG	; Add LSEG to chain

	 jmp	 near ptr DORI_FLSLOOP ; Join common code

DORI_XCASE3:
; Case 2 (PSP and environment)
; Link both LSEG entries.
	 movzx	 esi,cx 	; Get segment of environment
	 dec	 si		; Back off to environment MAC entry
	 shl	 esi,4-0	; Convert paras to bytes

	 PUSHD	 0		; No load size for environment
	 push	 [ebp].PUSHAD_EBX.ELO ; PSP segment
	 push	 JGROUP:[bx].RINFO_LSEG1 ; MAC entry of environment LSEG
	 push	 AGROUP:[esi].MAC_NPAR ; Size of environment in paras
	 push	 esi		; Address of environment MAC
	 push	 0		; No maximum paragraph request for environment
	 push	 [ebp].PUSHAD_EAX.ELO ; Caller's CS
	 call	 ADD_LSEG	; Add LSEG to chain

; Link LSEG2 into LSEG chain
	 push	 LOADSIZE	; Load size in bytes
	 movzx	 edi,[ebp].PUSHAD_EBX.ELO ; Get PSP
	 push	 di		; Pass it unchanged
	 push	 JGROUP:[bx].RINFO_LSEG2 ; Pass MAC segment of PSP LSEG
; We're really saving the initialization size here.  We'll set the
; @LSEG_IMAX flag if the initial allocation is for the entire region.
	 dec	 di		; Back off to PSP MAC entry
	 shl	 edi,4-0	; Convert paras to bytes
	 push	 AGROUP:[edi].MAC_NPAR ; Pass it as resident size
	 push	 edi		; Pass address of PSP MAC entry
	 push	 MAXPARA	; Maximum paragraph request (usually -1)
	 push	 [ebp].PUSHAD_EAX.ELO ; Caller's CS
	 call	 ADD_LSEG	; Add LSEG to chain

	 jmp	 short DORI_FLSLOOP ; Join common code

DORI_FLSFREE:
; Case 1 (Free both LSEG entries)
	 movzx	 esi,JGROUP:[bx].RINFO_LSEG1 ; Get 1st LSEG MAC
	 shl	 esi,4-0	; Convert paras to bytes
	 mov	 AGROUP:[esi].MAC_OWNR,@MAC_FREE ; Free it

DORI_FLSFREE2:
	 movzx	 esi,JGROUP:[bx].RINFO_LSEG2 ; Get 2nd LSEG MAC
	 shl	 esi,4-0	; Convert paras to bytes
	 mov	 AGROUP:[esi].MAC_OWNR,@MAC_FREE ; Free it

DORI_FLSLOOP:
	 sub	 bx,size RINFO_STR ; Back off to previous entry
	 cmp	 bx,offset JGROUP:RINFO ; Are we at the beginning?
	 jnb	 near ptr DORI_FINDLSEG ; Go around again if not

DORI_EXIT:
; We need to re-write our filler pattern from PSP+LOADSIZE to the
; end of the PSP region.
	 REGSAVE <es>		; Save

	 mov	 edi,LOADSIZE	; Get load size in bytes
;;;;;;;  add	 edi,16-1	; Round up to para boundary
;;;;;;;  and	 edi,not (16-1) ; Round off

	 movzx	 ebx,[ebp].PUSHAD_EBX.ELO ; Get PSP segment
	 mov	 ecx,ebx	; Save a copy
	 shl	 ebx,4-0	; Convert paras to bytes
	 add	 edi,ebx	; Address first byte after image
	 sub	 ebx,size MAC_STR ; Back off to MAC entry
	 add	 cx,AGROUP:[ebx].MAC_NPAR ; Address next MAC entry
	 shl	 ecx,4-0	; Convert paras to bytes
	 sub	 ecx,edi	; Get length to fill in bytes
	 jbe	 short @F	; Jump if nothing left

	 shr	 ecx,4-2	; Convert bytes to dwords
	 push	 gs		; Address all memory selector
	 pop	 es		; ...for string store
	 assume  es:AGROUP	; Tell the assembler

	 mov	 eax,FILLPAT	; Get filler pattern ('386M')
    rep  stos	 AGROUP:[edi].EDD ; Blow in filler pattern
@@:
	 REGREST <es>		; Restore
	 assume  es:PGROUP	; Tell the assembler

	 call	 UNPLUG_MAC	; Pull out the plugs

	 REGREST <ds>		; Restore
	 assume  ds:nothing	; Tell the assembler

	 popad			; Restore

	 sti			; Enable interrupts

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DO_RINFO endp			; End DO_RINFO procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 NPPROC  CPY_DLGROUP -- Set up code and data downstairs for 4B support
	 assume  ds:PGROUP,es:JGROUP,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Copy code and data in DLGROUP downstairs.  We'll also set up the
array of LSEG filler entries now to save some space down there.
This also permits us to handle SMARTDRV, which we need to force
into the single largest available region.  This is necessary for
pre-DOS 6 beta versions of SMARTDRV, which would needlessly split
the allocation for the 16K track buffer, but we do it for all versions
since it doesn't change the behavior of the newer versions.

Besides, we don't have a mechanism to check file dates up here.

If we can't allocate at least 2 LSEG entries upstairs, don't
bother with it.

On entry:
SS:EBP ==>	Caller's INTXX_STR

On exit:
AX		DLGROUP segment if successful
CF=0		DLGROUP set up successfully, segment in AX
CF=1		Couldn't set up DLGROUP, or no room to load program

|

	 pushad 		; Save

; Check to see if we can allocate 2 LSEG entries somewhere in high
; DOS.	If we can't, no program is going to load with its environment
; in 128 bytes...
	 mov	 ax,@MAC_TEMP	; Temporary owner
	 mov	 bx,(mask $STRA_HIONLY) or (mask $STRA_NOLSEG) ; High DOS only
	 mov	 dx,@LSEGPARA	; First LSEG size (MAC not included)
	 mov	 di,@NOTSPEC	; No specific region
	 FCALL	 MAC_ALLOC	; AX=segment if CF=0
	 jc	 near ptr CDL_EXIT ; Jump if we failed (note CF=1)

	 push	 ax		; Save segment
;;;;;;;  mov	 ax,@MAC_TEMP	; Owner doesn't matter- we're going to free it
	 mov	 dx,@LSEGPARA	; Second LSEG size (not including MAC)
	 FCALL	 MAC_ALLOC	; AX=segment if CF=0

	 pop	 dx		; Get first LSEG
	 pushf			; Save result
	 push	 ax		; Save segment (if call succeeded)
	 FCALL	 MAC_FREE	; Free segment at DX:0
	 pop	 dx		; Get second LSEG (if MAC_ALLOC succeeded)
	 popf			; Restore
	 jc	 near ptr CDL_EXIT ; Jump if we failed (note CF=1)

	 FCALL	 MAC_FREE	; Free second LSEG at DX:0

; 1. Allocate space in low DOS for DLGROUP.  If we can't do that,
; find the best fit and allocate at the high end of that region.
	 mov	 ax,@MAC_TEMP	; Temporary owner
	 mov	 bx,mask $STRA_NOLSEG ; First fit low, no LSEG
	 lea	 dx,DLGROUP:DLGROUP_END[16-1] ; Length of DLGROUP in bytes
	 shr	 dx,4-0 	; Convert to paras
	 mov	 di,@NOTSPEC	; No specific region
	 push	 dx		; Save
	 FCALL	 MAC_ALLOC	; AX=segment or AL=errcode and DX=largest
	 pop	 dx		; Restore
	 jnc	 short @F	; Jump if OK

	 mov	 ax,@MAC_TEMP	; Temporary owner
	 or	 bx,@STRA_HIONLY or @STRA_BEST or @STRA_END ; Best fit high at
				; high end of region
	 FCALL	 MAC_ALLOC	; AX=segment or AL=errcode and DX=largest
	 jc	 near ptr CDL_EXIT ; Jump if we failed (note CF=1)

@@:
; 2. Copy DLGROUP downstairs
	 REGSAVE <es,gs>	; Save

	 push	 es		; JGROUP selector
	 push	 gs		; AGROUP selector
	 pop	 es		; Destination for move
	 pop	 gs		; Source ...
	 assume  es:AGROUP,gs:JGROUP ; Tell the assembler

	 movzx	 edi,ax 	; Segment to copy to
	 shl	 edi,4-0	; Convert paras to bytes
	 sub	 esi,esi	; Clear high word
	 mov	 si,seg DLGROUP ; Get DLGROUP segment relative to PGROUP
	 sub	 si,seg JGROUP	; Get offset of DLGROUP from JGROUP in paras
	 shl	 esi,4-0	; Convert paras to bytes
	 lea	 ecx,DLGROUP:DLGROUP_END[4-1] ; Length of DLGROUP in bytes
	 shr	 ecx,2-0	; Convert bytes to dwords
S32 rep  movs	 <AGROUP:[edi].EDD,JGROUP:[esi].EDD> ; Move it

	 REGREST <gs,es>	; Restore
	 assume  es:JGROUP,gs:AGROUP ; Tell the assembler

; 3. Make a copy of the caller's EXEC structure at ES:BX in case it's a
;    4B00 call we need to convert to 4B01.  We also need to initialize
;    a default MAC_NAME value for LSEG entries.
	 movzx	 ebx,ax 	; Destination segment for DLGROUP
	 shl	 ebx,4-0	; Convert paras to bytes

	 REGSAVE <ax,es>	; Save

	 lea	 edi,JGROUP:MNAME ; Address default MAC_NAME
	 mov	 esi,PBAPPBASE	; Get PGROUP offset of basename
	 mov	 ecx,esi	; Copy it
	 sub	 ecx,offset PGROUP:MSG_APPLNAME[size LENTXT_LEN] ; Get offset of basename from path
	 sub	 cx,MSG_APPLNAME.LENTXT_LEN ; Get -(length of basename)
	 neg	 cx		; Make it positive
	 mov	 ax,@MNAME_LEN	; Maximum size for MAC_NAME
	 cmp	 cx,ax		; Does it fit?
	 jbe	 short @F	; Jump if so

	 mov	 cx,ax		; Maximum MAC_NAME length
@@:
	 lods	 PGROUP:[esi].LO ; Get next character
	 cmp	 al,'.'         ; Izit the end of the basename?
	 je	 short @F	; Jump if so

S32	 stos	 MNAME[edi]	; Save it
	 loop	 @B		; Go around again
@@:
	 jcxz	 @F		; Jump if finished

	 sub	 al,al		; Get a convenient 0
  rep	 stos	 MNAME[edi]	; Fill with trailing 0's
@@:
	 push	 gs		; Get AGROUP
	 pop	 es		; Address for string move
	 assume  es:AGROUP	; Tell the assembler

	 movzx	 esi,[ebp].INTXX_ES ; Get caller's ES
	 shl	 esi,4-0	; Convert paras to bytes
	 movzx	 ecx,[ebp].INTXX_EBX.ELO ; Get caller's BX
	 add	 esi,ecx	; AGROUP:[esi] ==> EXEC_STR

	 lea	 edi,DLGROUP:LDBG[ebx] ; Address our copy of EXEC structure
	 mov	 ecx,size LOADDBG_STR ; Bytes to move
S32 rep  movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Copy it

	 REGREST <es,ax>	; Restore
	 assume  es:JGROUP	; Tell the assembler

; 4. Initialize data in DLGROUP and JGROUP.
	 mov	 edi,ebx	; Get address of DLGROUP
	 movzx	 ebx,HIMEM_CS	; Address QMAX_OVR
	 shl	 ebx,4-0	; Convert paras to bytes

	 assume  gs:PGROUP	; Tell a white lie
	 mov	 ecx,gs:OLDINT21_VEC[ebx] ; Get old Int 21 vector
	 assume  gs:AGROUP	; Retract nose
	 assume  gs:DLGROUP	; Tell a lie
	 mov	 DLDOSVEC[edi],ecx ; Save in DLGROUP
	 assume  gs:AGROUP	; Retract nose

	 assume  gs:PGROUP	; Tell a white lie
	 mov	 cx,gs:LOADSEG[ebx] ; Get start of LSEG chain
	 assume  gs:AGROUP	; Retract nose
	 mov	 LOADSEG,cx	; Save it in extended memory
;;;;;;;  assume  gs:DLGROUP	; Tell a lie
;;;;;;;  mov	 DLLOADSEG[edi],cx ; Save in DLGROUP
;;;;;;;  assume  gs:AGROUP	; Retract nose
;;;;;;;
	 assume  gs:PGROUP	; Tell a white lie
	 mov	 cx,gs:POVR_MAC[ebx] ; Get start of high DOS
	 assume  gs:AGROUP	; Retract nose
	 mov	 POVR_MAC,cx	; Save it in extended memory
;;;;;;;  assume  gs:DLGROUP	; Tell a lie
;;;;;;;  mov	 DLPOVR_MAC[edi],cx ; Save in DLGROUP
;;;;;;;  assume  gs:AGROUP	; Retract nose
;;;;;;;
;;;;;;;  mov	 cx,gs:P1ST_MAC[ebx].VSEG ; Get start of low DOS
;;;;;;;  assume  gs:DLGROUP	; Tell a lie
;;;;;;;  mov	 DLP1ST_MAC[edi],cx ; Save for later
;;;;;;;  assume  gs:AGROUP	; Retract nose
;;;;;;;
	 mov	 cx,PORT67	; Get EMM2CALL back door value
	 assume  gs:DLGROUP	; Tell a lie
	 mov	 DLPORT67[edi],cx ; Save for later
	 assume  gs:AGROUP	; Retract nose

	 mov	 cx,MAC_STRA	; Get current strategy
	 assume  gs:DLGROUP	; Tell a lie
	 mov	 DLMAC_STRA[edi],cx ; Save for later
	 assume  gs:AGROUP	; Retract nose

	 mov	 MAXPARA,-1	; Default value for maximum allocation
	 mov	 LOADSIZE,0	; Default load size

; AX contains the new DLGROUP segment.	Set up LSEG entries
; in high DOS.	Note that we don't care about a failure here,
; since we'll detect that downstairs and take the appropriate
; cleanup action.

; If the 386LOAD.CFG 'B' flag has been specified (SMARTDRV.EXE),
; we need to ensure we only allocate from the largest high DOS
; region.
	 push	 ax		; Save DLGROUP segment

; Plug all low DOS MAC entries
	 cli			; Nobody move
	 movzx	 ebx,P1ST_MAC.VSEG ; Get starting MAC in low DOS
	 shl	 ebx,4-0	; Convert paras to bytes
CDL_PLUG:
	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_FREE ; Izit free?
	 jne	 short @F	; Jump if not

	 mov	 AGROUP:[ebx].MAC_OWNR,@MAC_PLUG ; Plug it
@@:
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit the end?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit valid?
	 jne	 short @F	; Jump if not

	 movzx	 eax,AGROUP:[ebx].MAC_NPAR ; Add length of block
	 inc	 ax		; Skip MAC entry
	 shl	 eax,4-0	; Convert paras to bytes
	 add	 ebx,eax	; Get new address
	 jmp	 short CDL_PLUG ; Go around again

@@:
	 sti			; Enable interrupts
; Create 2 LSEG entries in each high DOS region.  If a region doesn't have
; sufficient space for 2 LSEGs, plug it.
; *** FIXME *** We should also be able to handle 1 LSEG with the environment,
; which is possible if the environment is <= the LSEG size.

	 btr	 I15_FLAG,$I15_HI4B ; Did we temporarily close high DOS?
	 jnc	 short @F	; Jump if not

	 FIXICALL PGROUP:FOPENHIGHDOS,DTE_CS2 ; Link low and high DOS arenas
;;;;;;;  jc	 ???		; Ignore error

@@:
; If the 386LOAD.CFG 'B' flag is in effect, we'll set BFLG_IDX, _BASE, and
; _LIM when we come back upstairs for DO_RINFO.
; The environment must be allowed to work as a normal fit according
; to the current strategy, otherwise the optimization algorithm won't work.

	 lea	 edi,JGROUP:RINFO ; Address RINFO_STR for first high DOS region
	 mov	 edx,edi	; Save starting address
	 cld			; Ensure string ops go forward
	 sub	 ax,ax		; Get a convenient zero
	 mov	 ecx,(size RINFO)/2 ; Number of words to fill
   rep	 stos	 RINFO[edi].ELO ; Initialize RINFO

	 movzx	 eax,POVR_MAC	; Get start of high DOS

	 cli			; Nobody move
CDL_GLSEG:
	 mov	 ebx,eax	; Get starting paragraph
	 shl	 ebx,4-0	; Convert paras to bytes

	 push	 ebx		; Pass MAC entry address
	 FCALL	 IZIT_MACLINK	; Is AGROUP:EBX a DOS 5 spanning entry?
	 je	 short CDL_GLSEG1 ; Jump if so

	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_SPAN ; Izit a spanning entry?
	 jne	 short CDL_GLSEG2 ; Jump if not
CDL_GLSEG1:
	 add	 dx,size RINFO_STR ; Skip to next

	 jmp	 near ptr CDL_LOOP ; Join common code

CDL_GLSEG2:
	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_FREE ; Izit available?
	 jne	 near ptr CDL_LOOP ; Join common code if not

	 cmp	 AGROUP:[ebx].MAC_NPAR,2*(1+@LSEGPARA) ; Enough for 2 LSEGs and MACs?
	 ja	 short @F	; Jump if so

; Not enough room, so plug it
	 mov	 AGROUP:[ebx].MAC_OWNR,@MAC_PLUG ; Make it unavailable
	 jmp	 near ptr CDL_LOOP ; Join common code

@@:
; Create 2 LSEG entries.  We don't need to fill in anything now, since they
; don't get linked into the chain yet.  We've already ensured that there's
; at least one paragraph free besides the two LSEGs, so we don't need to
; handle the split vs. fully allocated case - it's always split.
	 mov	 LAST_RINFO,dx	; Save offset of last RINFO_STR

	 mov	 si,@LSEGPARA	; Size of LSEG entry in paras
	 mov	 cl,@MAC_MID	; Make current entry a middle entry
	 xchg	 si,AGROUP:[ebx].MAC_NPAR ; Set new size
	 xchg	 cl,AGROUP:[ebx].MAC_TYPE ; Set new type
	 mov	 AGROUP:[ebx].MAC_OWNR,@MAC_LSEG ; Set owner to LSEG
	 mov	 AGROUP:[ebx].MAC_BACK,0 ; Clear LSEG back link

	 mov	 JGROUP:[edx].RINFO_LSEG1,ax ; Save segment of first LSEG MAC

	 sub	 si,2*(@LSEGPARA+1) ; Subtract both LSEGs and their MAC entries
	 add	 ax,@LSEGPARA+1 ; Skip to next MAC

	 mov	 ebx,eax	; Copy segment value
	 shl	 ebx,4-0	; Convert paras to bytes

	 mov	 AGROUP:[ebx].MAC_NPAR,@LSEGPARA ; Set size of second LSEG
	 mov	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; There's always an entry following it
	 mov	 AGROUP:[ebx].MAC_OWNR,@MAC_LSEG ; Set owner to LSEG
	 mov	 AGROUP:[ebx].MAC_BACK,0 ; Clear LSEG back link

	 mov	 JGROUP:[edx].RINFO_LSEG2,ax ; Save segment of second LSEG MAC

	 add	 ax,@LSEGPARA+1 ; Skip to next MAC

	 mov	 ebx,eax	; Copy segment value
	 shl	 ebx,4-0	; Convert paras to bytes

	 mov	 AGROUP:[ebx].MAC_NPAR,si ; Save remaining size
	 mov	 AGROUP:[ebx].MAC_TYPE,cl ; Save original type
	 mov	 AGROUP:[ebx].MAC_OWNR,@MAC_FREE ; It's still a free entry
	 mov	 AGROUP:[ebx].MAC_BACK,0 ; Clear LSEG back link

	 add	 si,ax		; Skip to end of region

	 mov	 JGROUP:[edx].RINFO_LAST,si ; Save last para in region

CDL_LOOP:
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit the end?
	 je	 short CDL_CLC	; Jump if so

	 add	 ax,AGROUP:[ebx].MAC_NPAR ; Add size of block
	 inc	 ax		; Skip MAC entry

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a valid entry?
	 je	 near ptr CDL_GLSEG ; Go around again if so

CDL_CLC:
	 sti			; Enable interrupts
	 pop	 ax		; Restore DLGROUP segment
	 clc			; Indicate success

CDL_EXIT:
	 mov	 [esp].PUSHAD_EAX.ELO,ax ; Save return value
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CPY_DLGROUP endp		; End CPY_DLGROUP procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 FPPROC  INT21_MACFNS -- Handle Int 21h MAC services
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

To emulate DOS=UMB, we need to handle the following DOS functions:

00h	(@PTERM - also Int 20h)
48h	(@GETMEM)
49h	(@RELMEM)
4ah	(@MODMEM)
4b00, 4b01 (@EXEC)
4ch	(@EXITRC)
58h	(@MACALG)

On entry:
All registers from entry to DOS call (function in AH).
IRETD frame points to code in QMAX_OVR to return to the
original Int 21 handler on the stack saved in I21MAC2_SSSP.

DX in INTXX_STR is the caller's PSP (needed for MAC_ALLOC).

On exit:
SS:SP in IRETD frame restored to SS:SP from high DOS PGROUP:I21MAC2_SSSP.
DX in IRETD frame restored to value saved on stack at INT 21h time
unless changed by call.
IRETD return address left alone (let DOS handle it) or modified to return
directly to caller.

Note that 5801 (Set strategy) is a special case.  We handle this one
AND pass it on to DOS.

We check for @I15_X58 in QMAX_OVR; if it's set, we'll never make it
up here.

|

; QMAX_OVR PGROUP:I21MAC2_SSSP addresses the original stack from the INT 21h:
I21MAC_STR struc

I21MAC_NRET	 dw	 ?	; Near return from EXTMAC_FNS
I21MAC_RVEC	 dd	 ?	; Return address from original INT 21/INT 20
I21MAC_IFLAGS	 dw	 ?	; Flags from original INT

I21MAC_STR ends

; The SS:SP from the IRETD frame addresses the DX saved on the stack
; before calling @GETPS0:
I21MAC2_STR struc

I21MAC2_DX	 dw	 ?	; Caller's DX
I21MAC2_SSSP	 dd	 ?	; ...	   SS:SP

I21MAC2_STR ends

	 PUSHD	 0		; Put pseudo-error code on the stack

	 pushad 		; All GP registers

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 mov	 ds,JSEL_DS3	; Get PL3 data selector for PGROUP
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 es,SEL_DSJG3	; Get PL3 data selector for JGROUP
	 assume  es:JGROUP	; Tell the assembler about it

	 mov	 gs,SEL_4GB3	; Get our all memory selector
	 assume  gs:AGROUP	; Tell the assembler about it

	 push	 ax		; Save function code

	 mov	 ax,[ebp].INTXX_EDX.ELO ; Get current PSP
	 mov	 CUR_PSP,ax	; Save globally

	 cmp	 TEMP_PSP,0	; Are we past processing DEVICE= statements?
	 je	 short @F	; Jump if so

	 cmp	 ax,TEMP_PSP	; Are we still processing drivers?
	 je	 short @F	; Jump if so

	 mov	 TEMP_PSP,0	; Mark as done processing drivers
	 and	 I15_FLAG,not @I15_LINK58 ; Clear link flag
	 FIXICALL PGROUP:FCLOSEHIGHDOS,DTE_CS2 ; Unlink low and high DOS arenas
;;;;;;;  jc	 ???		; Ignore error

@@:
	 pop	 ax		; Restore function

; Restore caller's DX.
	 movzx	 ebx,[ebp].INTXX_ESP.ELO ; SS:SP ==> I21MAC2_STR
	 movzx	 edx,[ebp].INTXX_SS ; Get stack segment
	 shl	 edx,4-0	; Convert to bytes
	 add	 ebx,edx	; Get linear address
	 mov	 dx,AGROUP:[ebx].I21MAC2_DX ; Get original DX
	 mov	 [ebp].INTXX_EDX.ELO,dx ; Save in IRETD frame

; Restore caller's stack.

	cli			; Ensure no interruptions

	 mov	 ebx,AGROUP:[ebx].I21MAC2_SSSP ; Get stack saved in low memory
	 mov	 [ebp].INTXX_ESP.ELO,bx ; Save original SP
	 shr	 ebx,16-0	; Get original SS
	 mov	 [ebp].INTXX_SS,bx ; Save it

	 sti			; Enable interrupts

; If it's 4B00 or 4B01 with high DOS open and last fit, best fit,
; high or high only, we need to set @I15_HI4B and close off high
; DOS.	On all other calls, we need to check @I15_HI4B; if set,
; clear it and re-link high DOS, then proceed.	This keeps programs
; like SMARTDRV.EXE from loading into high DOS by osmosis.
	 cmp	 ah,@EXEC	; Izit function 4Bh?
	 jne	 near ptr I21MAC_XEXEC ; Jump if not

	 cmp	 al,01h 	; Izit anything other than 4B00/4B01?
	 ja	 near ptr I21MAC_XEXEC ; Jump if so

	 and	 I15_FLAG,not @I15_NOVELL ; NETX isn't in the picture

	 call	 LOAD_INPRO	; Is 386LOAD currently running?
	 jc	 near ptr I21MAC_DOS ; Jump if so - let DOS handle it

	 test	 I15_FLAG,@I15_LINK58 ; Is high DOS open for business?
	 jz	 near ptr I21MAC_XEXEC ; Jump if not

	 cmp	 MAC_STRA,0	; Izit first fit low?
	 je	 near ptr I21MAC_XEXEC ; Jump if so - it's OK

	 or	 I15_FLAG,@I15_HI4B ; Set flag for next call to MACFNS
	 FIXICALL PGROUP:FCLOSEHIGHDOS,DTE_CS2 ; Unlink low and high DOS arenas
;;;;;;;  jc	 ???		; Ignore error

	 bt	 I15_FLAG,$I15_X4B ; Is 4B00 support globally disabled?
	 jc	 near ptr I21MAC_DOS ; Jump if so - let DOS handle it

	 btr	 I15_FLAG,$I15_XEXEC ; Are we supposed to keep this one from
				; loading high via 4B00/4B01?
	 jc	 near ptr I21MAC_DOS ; Jump if so - let DOS handle it

	 call	 CPY_DLGROUP	; Set up DLGROUP downstairs
	 jc	 near ptr I21MAC_DOS ; Jump if we failed (pass call on to DOS)

; IRETD to EMU4B in low DOS DLGROUP at AX:0
	 mov	 [ebp].INTXX_EIP.ELO,offset DLGROUP:EMU4B ; Save in INTXX_STR
	 mov	 [ebp].INTXX_CS,ax ; Save in INTXX_STR

	 movzx	 ebx,[ebp].INTXX_ESP.ELO ; SS:SP ==> I21MAC_STR
	 movzx	 edx,[ebp].INTXX_SS ; Get stack segment
	 shl	 edx,4-0	; Convert to bytes
	 add	 edx,ebx	; Get linear address

	 add	 bx,(size I21MAC_NRET) ; Strip near return

	 jmp	 I21MAC_CALLER2 ; Join common IRETD code

I21MAC_XEXEC:
	 btr	 I15_FLAG,$I15_HI4B ; Did we temporarily shut down the waterworks?
	 jnc	 short @F	; Jump if not

	 FIXICALL PGROUP:FOPENHIGHDOS,DTE_CS2 ; Link low and high DOS arenas
;;;;;;;  jc	 ???		; Ignore error

@@:
	 or	 ah,ah		; Izit function 0?
	 jnz	 short @F	; Jump if not

	 mov	 ah,@EXITRC	; Convert to 4Ch
@@:
	 cmp	 ah,@MACALG	; Izit function 58h?
	 jne	 short @F	; Jump if not

	 cmp	 al,03h 	; Izit a valid subfunction?
	 ja	 near ptr I21MAC_DOS ; Pass on to DOS if not

	 sub	 ah,(58h-4Ch-1) ; Put 5800h in jump table after 4Cxx
	 add	 ah,al		; Combine with subfunction
@@:
	 sub	 ah,48h 	; Convert to 0-based value for jump table
	 cmp	 ah,@I21MAC_TABMAX ; Izit within our jump table?
	 jnb	 near ptr I21MAC_DOS ; Pass on to DOS if not

	 movzx	 eax,ah 	; Get byte index into jump table

	 jmp	 I21MAC_TAB[eax*(type I21MAC_TAB)] ; Join function processing code

	 public  I21MAC_48xx
I21MAC_48xx:
; Function 48: Get memory block of BX paras
; Possible returns:
; Success: AX:0 ==> block, CF=0
; If CF=1, AX=error code (@DOSERR_XMAC,_XMEM) and BX=largest available block
	 mov	 ax,CUR_PSP	; Get current PSP
	 mov	 bx,MAC_STRA	; Current allocation strategy
	 test	 I15_FLAG,@I15_LINK58 ; Is high DOS hooked up?
	 jnz	 short @F	; Jump if so (high DOS strategies OK)

	 and	 bx,not @STRA_WANTHI ; Mask off high DOS strategies
@@:
	 mov	 dx,[ebp].INTXX_EBX.ELO ; Number of paragraphs to allocate
	 mov	 di,@NOTSPEC	; No specific region in high DOS
	 FCALL	 MAC_ALLOC	; AX=segment or AL=errcode and DX=largest
	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save return segment
	 jnc	 I21MAC_OK	; Jump if OK

	 mov	 [ebp].INTXX_EBX.ELO,dx ; Save size of largest available block
	 jmp	 I21MAC_XERR	; Translate XMS error

	 public  I21MAC_49xx
I21MAC_49xx:
; Function 49: Free memory block at ES
; Return CF=0 or CF=1 with error code in AX (@DOSERR_XMAC,_MNF)
	 mov	 dx,[ebp].INTXX_ES ; Get segment to free
	 FCALL	 MAC_FREE	; Return error code in AL
	 jc	 near ptr I21MAC_DOS ; Pass the call on to DOS

	 jmp	 I21MAC_OK	; Join common exit

	 public  I21MAC_4Axx
I21MAC_4Axx:
; Function 4A: Resize block at ES:0 to BX paras
; Return CF=0 or CF=1 with error code in AX (@DOSERR_XMAC,_XMEM,_MNF) and
; BX = maximum possible size
	 mov	 ax,CUR_PSP	; Get current PSP
	 mov	 dx,[ebp].INTXX_ES ; Get segment to resize
	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get new size in paras
	 FCALL	 MAC_REALLOC	; Return error code in AL
	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save return segment
	 jnc	 near ptr I21MAC_OK ; Jump if OK

; Only if it's Insufficient Memory, should we save a new BX

	 cmp	 al,0B2h	; Izit Invalid MAC Entry?
	 je	 short @F	; Jump if so

	 cmp	 al,0B0h	; Izit Insufficient memory?
	 jb	 short @F	; Jump if not

	 mov	 [ebp].INTXX_EBX.ELO,dx ; Save largest possible size
@@:
	 jmp	 I21MAC_XERR	; Translate XMS error

	 public  I21MAC_4Cxx
I21MAC_4Cxx:
; Functions 0 and 4C, Int 20: terminate process
; Free any non-LSEG MAC entries in high DOS owned by current PSP.
; Since we use MAC_FREE to free them, the LSEG will get freed and
; unlinked there.
	 mov	 ax,CUR_PSP	; Get current PSP
	 movzx	 ebx,POVR_MAC	; Get segment of high DOS memory
	 shl	 ebx,4-0	; Convert from paras to bytes

I21MAC_4CNEXT:
; Check for valid MAC entry
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short @F	; Yes

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 jne	 short I21MAC_4CEXIT ; No, ignore the error
@@:
	 cmp	 AGROUP:[ebx].MAC_OWNR,ax ; Izit one of ours?
	 jne	 short @F	; Jump if not

;;;;;;;  mov	 AGROUP:[ebx].MAC_OWNR,0 ; Free it
	 lea	 edx,[ebx+16]	; Address first para past MAC entry
	 shr	 edx,4-0	; Convert bytes to paras
	 push	 ax		; Save PSP
	 mov	 ax,dx		; AX:0 ==> start of block
	 call	 IZITLSEG	; Return CF=1 if LSEG
	 pop	 ax		; Restore PSP
	 jc	 short @F	; If so, don't free it

	 push	 ax		; Save PSP
	 FCALL	 MAC_FREE	; Free DX:0, return error code in AL
	 pop	 ax		; Restore
;;;;;;;  jc	 ???		; Ignore error

@@:
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Check for the end-of-the-line
	 je	 short I21MAC_4CEXIT ; Exit if so

	 movzx	 edx,AGROUP:[ebx].MAC_NPAR ; Get number of paragraphs
	 inc	 dx		; Add in MAC para
	 shl	 edx,4-0	; Convert from paras to bytes
	 add	 ebx,edx	; Skip to the next entry

	 jmp	 short I21MAC_4CNEXT ; Go around again

I21MAC_4CEXIT:
	 jmp	 near ptr I21MAC_DOS ; Continue with DOS code

	 public  I21MAC_5800
I21MAC_5800:
; Function 58, subfn 0: Get allocation strategy
; Return CF=0 and AX = MAC_STRA
	 mov	 ax,MAC_STRA	; Get current strategy
	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save return value
	 jmp	 I21MAC_OK	; Join common exit code (CF=0)

	 public  I21MAC_5801
I21MAC_5801:
; Function 58, subfn 1: Set allocation strategy to BX
; Return CF=0 or CF=1 with error code in AX (@DOSERR_XFN)
	 mov	 ax,@DOSERR_XFN ; Only possible error code
	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get caller's BX

	 test	 bx,@STRA_INVAL ; Any invalid bits specified?
	 jnz	 near ptr I21MAC_ERR ; Jump if so

	 test	 bx,mask $STRA_HI ; Is high DOS bit set?
	 jz	 short @F	; Jump if not

	 test	 bx,mask $STRA_HIONLY ; Is high DOS only bit also set?
	 jnz	 near ptr I21MAC_ERR ; Jump if so - invalid combination

@@:
	 test	 bx,mask $STRA_LAST ; Is last fit bit set?
	 jz	 short @F	; Jump if not

	 test	 bx,mask $STRA_BEST ; Is best fit also set?
	 jnz	 near ptr I21MAC_ERR ; Jump if so - another invalid combination

@@:
; DOS 6 doesn't seem to care about the strategy - it just doesn't take effect
;;;;;;;  test	 bx,@STRA_NEEDHI ; Is high DOS needed for this strategy?
;;;;;;;  jz	 short @F	; Jump if so
;;;;;;;
;;;;;;;  test	 I15_FLAG,@I15_LINK58 ; Is high DOS arena linked via 5802h?
;;;;;;;  jz	 short I21MAC_ERR ; Jump if so
;;;;;;;
;;;;;;;@@:
	 mov	 MAC_STRA,bx	; Set new strategy

; Note that we need to pass the strategy on to DOS, as there are cases
; where DOS does its own MAC allocation (such as EXEC calls).
; We don't want to do this with pre-DOS 5 versions.
	 cmp	 DOSVER,0500h	; Izit DOS 5?
	 jb	 near ptr I21MAC_OK ; Jump if not

	 jmp	 I21MAC_DOS	; Pass the call on to DOS

	 public  I21MAC_5802
I21MAC_5802:
; Function 58, subfn 2: Get high DOS link status
; Return CF=0 and AL=	1 if high DOS arena linked
;			0 if not
	 test	 I15_FLAG,@I15_LINK58 ; Did we link 'em?
	 setnz	 [ebp].INTXX_EAX.ELO.LO ; AL=1 if so, AL=0 if not
	 jmp	 I21MAC_OK	; Join common exit code

	 public  I21MAC_5803
I21MAC_5803:
; Function 58, subfn 3: Set high DOS link status to BX
; Return CF=0 or CF=1 with error code in AX (@DOSERR_XFN,_XMAC)
	 mov	 ax,@DOSERR_XFN ; Invalid function return code
	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get caller's BX

	 cmp	 bx,1		; Izit out of range?
	 ja	 short I21MAC_ERR ; Jump if so

	 mov	 ax,@DOSERR_XMAC ; MAC trashed
	 jb	 short I21MAC_5803_CLOSE ; Unlink arenas

; If the M3 flag was specified (locally disable 5800 UMBs) we need to
; handle all other business as usual to keep DOS' dirty hands off
; high DOS, but 5803 BX=1 calls need to be quietly ignored.
	 test	 MSC_FLAG,@MSC_LCLX58 ; Was the M3 flag specified?
	 jnz	 short I21MAC_OK ; Jump if so (note CF=0)

	 FIXICALL PGROUP:FOPENHIGHDOS,DTE_CS2 ; Link low and high DOS arenas
	 jc	 short I21MAC_ERR ; Jump if link failed

	 or	 I15_FLAG,@I15_LINK58 ; Mark as linked
	 jmp	 short I21MAC_OK ; Join common exit (note CF=0)

I21MAC_5803_CLOSE:
	 test	 I15_FLAG,@I15_LINK58 ; Are they linked?
	 jz	 short I21MAC_OK ; Jump if not (note CF=0)

	 FIXICALL PGROUP:FCLOSEHIGHDOS,DTE_CS2 ; Unlink low and high DOS arenas
	 jc	 short I21MAC_ERR ; Jump if unlink failed

	 and	 I15_FLAG,not @I15_LINK58 ; Clear linked flag
	 jmp	 short I21MAC_OK ; Join common exit (note CF=0)

I21MAC_XERR:
; XMS error code is in AL.  Translate to DOS error code in AX.
	 mov	 bl,al		; Save XMS error code
	 mov	 ax,@DOSERR_XMAC ; Arena trashed
	 cmp	 bl,8Fh 	; Izit our boy?
	 je	 short I21MAC_ERR ; Good guess

	 mov	 ax,@DOSERR_MNF ; Invalid MAC entry specified
	 cmp	 bl,0B2h	; Izit our boy?
	 je	 short I21MAC_ERR ; Good guess

	 ja	 short @F	; All error codes > B2h are invalid

	 mov	 ax,@DOSERR_XMEM ; Insufficient memory
	 cmp	 bl,0B0h	; Izit B0 or B1?
	 jae	 short I21MAC_ERR ; Jump if so

@@:
	 mov	 ax,@DOSERR_XFN ; Invalid function
I21MAC_ERR:
; Error code is in AX.	Set CF and save error code for return.
	 or	 [ebp].INTXX_EFL.ELO,mask $CF ; Set error flag
	 mov	 [ebp].INTXX_EAX.ELO,ax ; Save return error code
	 stc			; Indicate error
	 jmp	 short I21MAC_CALLER ; Join common code to return to caller

I21MAC_OK:
	 clc			; Indicate success

I21MAC_CALLER:
; Return directly to caller.  We need to get the stack from INTXX_STR,
; calculate its linear address, skip the saved flags and get the caller's
; CS:IP, put that in our IRETD frame, and set the SP in INTXX_STR to
; INTXX_STR.ESP.ELO - (size I21MAC_STR).  Then we can return via IRETD.
	 pushf			; Save flags (CF significant)
	 pop	 cx		; Get flags
	 and	 cx,mask $CF	; Isolate CF

	 movzx	 ebx,[ebp].INTXX_ESP.ELO ; SS:SP ==> I21MAC_STR
	 movzx	 edx,[ebp].INTXX_SS ; Get stack segment
	 shl	 edx,4-0	; Convert to bytes
	 add	 edx,ebx	; Get linear address

; AGROUP:[edx] ==> I21MAC_STR
	 mov	 ax,AGROUP:[edx].I21MAC_IFLAGS ; Get flags from Int 21
	 and	 ax,not (mask $CF) ; Clear CF
	 or	 ax,cx		; Combine with CF value to return
	 and	 ax,not (mask $IOPL) ; Clear the IOPL bits
	 or	 ax,@VMIOPL shl $IOPL ; Ensure IOPL=@VMIOPL
	 mov	 [ebp].INTXX_EFL.ELO,ax ; Save in INTXX_STR

	 mov	 ax,AGROUP:[edx].I21MAC_RVEC.VOFF ; Get IP
	 mov	 [ebp].INTXX_EIP.ELO,ax ; Save in INTXX_STR
	 mov	 ax,AGROUP:[edx].I21MAC_RVEC.VSEG ; Get CS
	 mov	 [ebp].INTXX_CS,ax ; Save in INTXX_STR

	 add	 bx,size I21MAC_STR ; Strip all the saved detritus
I21MAC_CALLER2:
; AGROUP:[edx] ==> I21MAC_STR
; BX = Return SP to set (with I21MAC_STR stripped)

; Now we need to set the return SP.  BX contains the stripped SP.
	 mov	 [ebp].INTXX_ESP.ELO,bx ; Save as return SP

I21MAC_DOS:
	 popad			; Restore

	 add	 sp,size INTXX_ERR ; Strip off error code

	 iretd			; Return to QMAX_OVR (pop flags and continue)

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT21_MACFNS endp		; End INT21_MACFNS procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 FPPROC  FIZITLSEG -- Far call to IZITLSEG
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Same as IZITLSEG with a far return.

|

	 call	 IZITLSEG	; Return CF=1 if AX:0 is an LSEG entry

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIZITLSEG endp			; End FIZITLSEG procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 NPPROC  IZITLSEG -- Is AX:0 An LSEG Entry?
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Is AX:0 an LSEG entry?

On entry:

AX	 ==>	 current MAC entry + 1

On exit:

CF	 =	 1 if so
	 =	 0 if not

|

	 REGSAVE <ebx>		; Save register

; Search through the LSEG chain looking for a match with AX

	 movzx	 ebx,HIMEM_CS	; Get segment of high DOS memory
	 shl	 ebx,4-0	; Convert from paras to bytes
	 assume  gs:PGROUP	; Tell a white lie
	 movzx	 ebx,gs:LOADSEG[ebx] ; Get low memory LOADSEG
	 assume  gs:AGROUP	; Retract nose
IZITLSEG_NEXT:
	 cmp	 bx,-1		; Izit the end?
	 je	 short IZITLSEG_EXIT ; Jump if so (note CF=0)

	 cmp	 ax,bx		; Same segment?
	 je	 short IZITLSEG_FOUND ; Jump if it's a match

	 shl	 ebx,4-0	; Convert from paras to bytes
	 movzx	 ebx,AGROUP:[ebx].LSEG_NEXT ; Get segment of next entry

	 jmp	 short IZITLSEG_NEXT ; Go around again

IZITLSEG_FOUND:
	 stc			; Mark as a match
IZITLSEG_EXIT:
	 REGREST <ebx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITLSEG endp			; End IZITLSEG procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL or @OEM_XMS
	 FPPROC  FUNLINK_LSEG -- Far call to UNLINK_LSEG
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Same as UNLINK_LSEG with a far return.

|

	 call	 UNLINK_LSEG	; Unlink LSEG at AGROUP:ESI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FUNLINK_LSEG endp		; End FUNLINK_LSEG procedure
endif				; IF @OEM_HIFILL or @OEM_XMS
if @OEM_HIFILL or @OEM_XMS
	 NPPROC  UNLINK_LSEG -- Unlink An LSEG Entry
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Unlink an LSEG entry.

On entry:

AGROUP:ESI ==>	 LSEG entry to unlink

|

	 REGSAVE <eax,ebx>	; Save registers

	 movzx	 eax,AGROUP:[esi].LSEG_NEXT ; Get this one's next
	 movzx	 ebx,AGROUP:[esi].LSEG_PREV ; Address previous
	 shl	 ebx,4-0	; Convert from paras to bytes
	 mov	 AGROUP:[ebx].LSEG_NEXT,ax ; De-link the previous LSEG

	 cmp	 ax,-1		; Is there a next LSEG?
	 je	 short @F	; Jump if not

	 shl	 eax,4-0	; Convert from paras to bytes
	 shr	 ebx,4-0	; Convert from bytes to paras
	 mov	 AGROUP:[eax].LSEG_PREV,bx ; De-link from next LSEG
@@:
	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UNLINK_LSEG endp		; End UNLINK_LSEG procedure
	 FPPROC  IZIT_MACLINK -- Is It a MAC Linking Entry
	 assume  ds:nothing,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Izit a MAC linking entry?

On exit:

ZF	 =	 1 if so
	 =	 0 if not

|

MACLINK_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; ...	   CS:IP
MACLINK_LA dd	 ?		; Linear address of MAC

MACLINK_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax>		; Save register

	 mov	 eax,[ebp].MACLINK_LA ; Get the linear address

	 cmp	 eax,90000h	; Izit well above the DOS owner entries?
	 jb	 short IZIT_MACLINK_EXIT ; Jump if not (hence not a linking entry)
				; Note ZF=0
	 cmp	 AGROUP:[eax].MAC_OWNR,@MAC_LINK ; Izit a MAC linking entry?
				; Return with ZF significant
IZIT_MACLINK_EXIT:
	 REGREST <eax>		; Restore

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT_MACLINK endp		; End IZIT_MACLINK procedure
endif				; IF @OEM_HIFILL or @OEM_XMS
	 FPPROC  CHECK_XSTACK -- Check for local stack disable
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check our table of special conditions for a case where we need to
locally disable stack switching.  This is needed in some cases,
like the Folio Infobase that Novell ships to support their help,
where we'll never see the 4B.

On entry:
nothing

On exit:
DSTK_FLAG	 Updated if a condition is true

|

	 REGSAVE <bx,cx,esi,edi,es,gs> ; Save

	 mov	 es,JSEL_DS3	; Get PL3 data selector for PGROUP
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 gs,SEL_4GB3	; Address all memory selector
	 assume  gs:AGROUP	; Tell the assembler about it

	 mov	 es,SEL_DSJG3	; Get PL3 data selector for JGROUP
	 assume  es:JGROUP	; Tell the assembler about it

	 sub	 bx,bx		; Index first XSTACK record
	 mov	 cx,@XSTACK_CNT ; Number of records
CXS_NEXT:
	 movzx	 esi,XSTACK[bx].XSTACK_RES ; Get linear address of IVT entry
	 movzx	 edi,AGROUP:[esi].VSEG ; Get segment of IVT entry
	 shl	 edi,4-0	; Convert paras to bytes
	 mov	 si,AGROUP:[esi].VOFF ; Get offset of IVT entry
	 add	 si,XSTACK[bx].XSTACK_OFF ; Add offset within interrupt handler
	 add	 esi,edi	; AGROUP:ESI ==> signature code
	 movzx	 edi,XSTACK[bx].XSTACK_SIG ; Get offset to compare within JGROUP

	 push	 ecx		; Save loop counter

	 movzx	 ecx,XSTACK[bx].XSTACK_SIGLEN ; Get number of bytes to compare
	 cld			; String ops forwardly
   repe  cmps	 AGROUP:[esi].LO,JGROUP:[edi].LO ; Compare

	 pop	 ecx		; Restore
	 je	 short @F	; Jump if it's our boy

	 add	 bx,size XSTACK_STR ; Skip to next record

	 loop	 CXS_NEXT	; Go around again

	 jmp	 short CXS_EXIT ; Join common exit

@@:
	 mov	 es,JSEL_DS3	; Get PL3 data selector for PGROUP
	 assume  es:PGROUP	; Tell the assembler about it

	 or	 DSTK_FLAG,mask $DSTK_LCLOFF ; Mark as locally disabled
CXS_EXIT:
	 REGREST <gs,es,edi,esi,cx,bx> ; Restore
	 assume  es:nothing,gs:nothing ; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_XSTACK endp		; End CHECK_XSTACK procedure

JCODE	 ends			; End JCODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

if @OEM_HIFILL or @OEM_XMS
	 public  @QMAX_I21_ECODE
@QMAX_I21_ECODE:		; Mark module start in .MAP file
endif				; IF @OEM_HIFILL or @OEM_XMS

if @OEM_HIFILL
	 extrn	 INTPROC21:near

	 FPPROC  FOPENHIGHDOS -- Far call to OPENHIGH for DOS
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

For DOS 5 and above, we need to update the link status flag and
the arena link segment.  These values are used by the DOS MEM command.

|

	 REGSAVE <ax,ebx,es>	; Save

	 mov	 es,SEL_DSJG3	; Address JGROUP
	 assume  es:JGROUP	; Tell the assembler about it

	 call	 OPENHIGH	; Link low and high DOS arenas
	 jc	 short FOHD_EXIT ; If an error occurred, return it to caller

; For DOS 5+, we need to bung our values into DOS so MEM will work.
	 cmp	 DOSVER,0500h	; Izit DOS 5?
	 jb	 short OHD_XDOS5 ; Jump if not

	 call	 TOPDOS 	; Return top of DOS in AX
	 shl	 ax,10-4	; Convert from 1KB to paras
	 dec	 ax		; Back off to previous entry
	 mov	 ebx,LaLINKSEG	; Address segment of spanning entry
	 mov	 AGROUP:[ebx].ELO,ax ; Save link segment

	 cmp	 TEMP_PSP,0	; Are we still processing DEVICE= statements?
	 jne	 short OHD_XDOS5 ; Jump if not

	 mov	 ebx,LaLINKFLG	; Address DOS link status flag
	 or	 AGROUP:[ebx].LO,mask $LINK_HIGH ; Mark as linked

OHD_XDOS5:
	 clc			; Indicate success
FOHD_EXIT:
	 REGREST <es,ebx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FOPENHIGHDOS endp		; End FOPENHIGHDOS procedure
	 FPPROC  FCLOSEHIGHDOS -- Far call to CLOSEHIGH for DOS
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

For DOS 5 and above, we need to update the link status flag.

|

	 REGSAVE <ebx,es>	; Save

	 mov	 es,SEL_DSJG3	; Address JGROUP
	 assume  es:JGROUP	; Tell the assembler about it

	 call	 CLOSEHIGH	; Unlink low and high DOS arenas
	 jc	 short FCHD_EXIT ; If an error occurred, return it to caller

; For DOS 5+, we need to bung our values into DOS so MEM will work.
; We don't care if it's DEVICE= processing or not when clearing the flag.
	 cmp	 DOSVER,0500h	; Izit DOS 5?
	 jb	 short @F	; Jump if not

	 mov	 ebx,LaLINKFLG	; Address DOS link status flag
	 and	 AGROUP:[ebx].LO,not (mask $LINK_HIGH) ; Clear it (note CF=0)

@@:
	 clc			; Indicate success
FCHD_EXIT:
	 REGREST <es,ebx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCLOSEHIGHDOS endp		; End FCLOSEHIGHDOS procedure
	 NPPROC  SET_POVR -- Set POVR_MAC in device info structure
	 assume  ds:AGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set the info structure POVR_MAC to the real thing or a deliberate
falsehood to protect us from MS LanMan TCP/IP's perfidies.

On entry:
AX	 Segment to set (usually POVR_MAC or POVR_LIE)

|

	 REGSAVE <ebx>		; Save

	 movzx	 ebx,HIMEM_CS	; Get segment of QMAX_OVR
	 shl	 ebx,4-0	; Convert to AGROUP: offset
	 add	 ebx,offset PGROUP:POVR_MAC ; Add offset of POVR_MAC

	 mov	 AGROUP:[ebx].ELO,ax ; Blast into info structure POVR_MAC

	 REGREST <ebx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_POVR endp			; End SET_POVR procedure
	 FPPROC  INT21 -- INT 21h Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DOS function interrupt handler.
Note that this procedure will get called under 3 conditions:
1. In V86 mode through our IDT (so it can't be under Windows).  Hook
@RELMEM calls and check for LSEGs we should free.  Hook @EXEC calls
(subfunctions 0 and 1) and squirrel away the filename.	Return to
the Int 21 handler in the real mode IDT.
2. In protected mode.  We transfer control to our DPMI translation
services, which handle the call and return to the caller.
3. In V86 mode through our IDT with the caller's CS == HIMEM_CS and
flags on the stack.  Trap @GETMEM, @RELMEM, @MODMEM, and @MACALG calls
for emulation of DOS=UMB.  If we need to handle the call ourselves
(arenas linked) modify the return address and stack in the IRETD frame.

On entry:

AH	 =	 DOS function code
ES	 =	 para # to free (if AH = @RELMEM)

Caller's IP has been incremented past the instruction.

|

if @OEM_DPMI
	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit from VM86 mode?
	 jnz	 short @F	; Jump if so

; Ensure IGROUP is present

	 test	 CMD_FLAG,@CMD_XDPMI ; Izit disabled?
	 jnz	 near ptr INTPROC21 ; Jump if so (call as VM INT 21h)

	 FIXIJMP IGROUP:INT21_DPMI,DTE_CSIG ; Run through our translator

@@:
endif				; IF @OEM_DPMI
if @OEM_HIFILL
	 push	 ax		; Save for a moment
	 mov	 ax,HIMEM_CS	; Get segment of high DOS code
	 cmp	 ax,[esp+2].NRM_CS ; Are we calling from QMAX_OVR?
	 pop	 ax		; Restore
	 jne	 short @F	; Jump if not

	 cmp	 [esp].NRM_EIP.ELO,offset PGROUP:EXTMAC_ORIG ; Does the return offset match?
	 jne	 short @F	; Jump if not

	 FIXIJMP JGROUP:INT21_MACFNS,DTE_CSJG ; Handle MAC services ourselves

@@:
endif				; IF @OEM_HIFILL
; Trapping 4B01 calls means we get the application's name before it has
; really started running.  It is probably a safe assumption, however,
; that it will start executing Real Soon Now.
	 cmp	 ax,(@EXEC shl 8) or 00h ; Izit load and execute?
	 je	 near ptr INT21_EXEC ; Jump if so

	 cmp	 ax,(@EXEC shl 8) or 01h ; Izit load for execution?
	 je	 near ptr INT21_EXEC ; Jump if so

	 cmp	 ax,(@SETINT shl 8) or 23h ; Izit set int 23 vector?
	 jne	 short @F	; Jump if not

	 FIXICALL JGROUP:CHECK_XSTACK,DTE_CSJG ; Check for local stack disable
@@:
	 cmp	 ah,@RELMEM	; Free memory?
	 je	 short INT21_REL ; Jump if so

; Because the M3 flag disables 5800 support for an individual program,
; we need to look for termination.  DOS may need 5800 services for a
; subsequent LH.
	 test	 MSC_FLAG,@MSC_LCLX58 ; Have we temporarily shut down high DOS?
	 jz	 short INT21_XTERM ; Jump if not

	 or	 ah,ah		; Function 0 (terminate)?
	 jz	 short INT21_TERMINATE ; Jump if so

	 cmp	 ah,@KEEPRC	; Function 31h (stay resident)?
	 je	 short INT21_TERMINATE ; Jump if so

	 cmp	 ah,@EXITRC	; Function 4Ch (terminate w/ errorlevel)?
	 jne	 short INT21_XTERM ; No, continue on with original handler

INT21_TERMINATE:
	 REGSAVE <ds>		; Save

	 mov	 ds,SEL_DS3	; Address PGROUP
	 assume  ds:PGROUP	; Tell the assembler

	 and	 MSC_FLAG,not @MSC_LCLX58 ; Enable 5800 support

	 REGREST <ds>		; Restore
	 assume  ds:nothing	; Tell the assembler

INT21_XTERM:
	 jmp	 INT21_ORIG	; Continue on with original handler

INT21_REL:
	 PUSHD	 0		; Put pseudo-error code on the stack

	 pushad 		; All GP registers

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 mov	 dx,[ebp].INTXX_ES ; Get caller's segment # to free

	 mov	 ds,SEL_DS3	; Address our data selector
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 gs,SEL_4GB3	; Address all memory selector
	 assume  gs:AGROUP	; Tell the assembler about it

; Get start of chain.  Note that LSEG entries may be in low or high DOS,
; but we should NEVER have an entry in one arena with the LSEG in another.

	 sub	 ecx,ecx	; Clear high word
	 mov	 cx,POVR_MAC	; Assume it's in high DOS
	 cmp	 dx,cx		; Izit in high DOS memory?
	 jnb	 short @F	; Good guess

	 mov	 cx,P1ST_MAC.VSEG ; It's in low DOS
@@:
	 shl	 ecx,4-0	; Convert paras to bytes

; Ensure this is a valid MAC entry

	 movzx	 ebx,dx 	; Copy segment #

	 sub	 ebx,1		; Back off to MAC entry
	 jc	 near ptr INT21_CHAIN ; Jump if not valid

	 shl	 ebx,4-0	; Convert from paras to bytes

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 jne	 near ptr INT21_CHAIN ; Jump if not
@@:
	 mov	 ebx,ecx	; Address first MAC entry
	 mov	 edi,size MAC_STR ; Get offset to data

; See if the entry to free is the owner of another block

INT21_NEXTMAC:
	 REGSAVE <dx>		; Save owner

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 jne	 near ptr INT21_ERRMAC0 ; Jump if not
@@:
	 cmp	 dx,AGROUP:[ebx].MAC_OWNR ; Izit the same?
	 jne	 near ptr INT21_LOOPMAC ; Jump if not

	 mov	 eax,ebx	; Copy the offset
	 shr	 eax,4-0	; Convert from bytes to paras
	 inc	 ax		; Convert from MAC to PSP

	 cmp	 ax,dx		; Same as original block?
	 je	 near ptr INT21_FREEMAC ; Yes, we'll free it in MAC_FREE

; If AX:0 is an LSEG entry, free interrupts and delink it from the chain

	 FIXICALL JGROUP:FIZITLSEG,DTE_CSJG ; Is AX an LSEG entry?
	 jc	 short INT21_LSEG ; Jump if so

; If not an LSEG, it's owned by the entry we're freeing, and the entry
; we're freeing has an LSEG, we can assume we need to free it.  This
; commonly occurs when lazy programs like Lantastic free their PSPs but
; not their environments.
	 REGSAVE <ebx>		; Save

	 movzx	 ebx,dx 	; Get owner's segment
	 dec	 bx		; Back off to MAC
	 shl	 ebx,4-0	; Convert paras to bytes

	 cmp	 AGROUP:[ebx].MAC_BACK,0 ; Does LSEG back link exist?

	 REGREST <ebx>		; Restore
	 jne	 short INT21_FREEMAC ; Jump if so (owner is a PSP)

	 jmp	 short INT21_LOOPMAC ; Join common code

INT21_LSEG:
; If this is 386LOAD in progress, don't free this entry

	 test	 AGROUP:[ebx+edi].LSEG_FLAG,@LSEG_INPRO ; Izit in progress?
	 jnz	 short INT21_LOOPMAC ; Jump if so

; We only want to free the LSEG if it's THE LSEG for this MAC entry.
; With 5802/5803 support, it's easy to have a program allocate some memory
; in low DOS, allocate segments in high DOS, then jump to high DOS and
; free the low DOS part.  The ownership on all the high DOS segments will
; be the PSP at the time of allocation, which may be the low DOS segment.
	 add	 ax,AGROUP:[ebx].MAC_NPAR ; Skip to next MAC entry
	 inc	 ax		; Skip to next PSP

	 cmp	 ax,dx		; Izit our boy?
	 jne	 short INT21_LOOPMAC ; Jump if not

; If freeing this segment will leave a hole, we need to convert it to
; a hole NOW so CHECK_ORPHAN doesn't clobber the LSEG.  If it turns out
; that the hole bubbles to the surface later, CHECK_ORPHAN will delink
; the LSEG and free the entry for real.
	 movzx	 edx,dx 	; Clear high word
	 dec	 dx		; Back off to MAC entry
	 shl	 edx,4-0	; Convert paras to bytes
	 cmp	 AGROUP:[edx].MAC_TYPE,@MAC_END ; Izit the end of the chain?
	 je	 short INT21_XHOLE ; Jump if so

	 movzx	 eax,AGROUP:[edx].MAC_NPAR ; Get length of block
	 inc	 ax		; Skip MAC para
	 shl	 eax,4-0	; Convert paras to bytes
	 add	 edx,eax	; Address next MAC

	 push	 edx		; Pass linear address
	 FIXICALL JGROUP:IZIT_MACLINK,DTE_CSJG ; Is GS:EDX a MAC linking entry?
	 je	 short INT21_XHOLE ; Jump if so

	 cmp	 AGROUP:[edx].MAC_OWNR,@MAC_SPAN ; Izit a spanning entry?
	 je	 short INT21_XHOLE ; Jump if so

	 cmp	 AGROUP:[edx].MAC_OWNR,@MAC_FREE ; Izit free?
	 je	 short INT21_XHOLE ; Jump if so

	 sub	 edx,eax	; Back off to original MAC entry
	 mov	 AGROUP:[edx].MAC_OWNR,@MAC_HOLE ; Make it a hole

	 REGSAVE <ebx>		; Save for a moment

	 mov	 ebx,ecx	; Get start of chain
	 FIXICALL JGROUP:FMAC_MERGESUB,DTE_CSJG ; Merge adjacent free MACs starting at 0:EBX

	 REGREST <ebx>		; Restore

	 jc	 short INT21_ERRMAC0 ; Jump if an error occurred

	 jmp	 short INT21_LOOPMAC ; Join common code

INT21_XHOLE:
	 lea	 esi,[ebx+edi] ; Point to LSEG linear address
	 FIXICALL JGROUP:FUNLINK_LSEG,DTE_CSJG ; Unlink the LSEG at GS:ESI
INT21_FREEMAC:
	 mov	 AGROUP:[ebx].MAC_OWNR,@MAC_FREE ; Mark LSEG as free
INT21_LOOPMAC:
	 REGREST <dx>		; Restore

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 je	 short INT21_EXIT ; Jump if it is

	 movzx	 eax,AGROUP:[ebx].MAC_NPAR ; Get # paras in this entry
	 inc	 eax		; Account for MAC para
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 ebx,eax	; Skip to next MAC entry

	 jmp	 INT21_NEXTMAC	; Go around again

INT21_ERRMAC0:
	 REGREST <dx>		; Restore
INT21_ERRMAC:
	 mov	 [ebp].INTXX_EAX.ELO,@DOSERR_XMAC ; Set "memory control blocks destroyed" code
INT21_ERR:
	 or	 [ebp].INTXX_EFL.ELO,mask $CF ; Set error flag
INT21_IRET:
	 popad			; Restore

	 add	 sp,size INTXX_ERR ; Strip off error code

	 iretd			; Return directly to caller with error code

INT21_EXIT:
INT21_CHAIN:
	 popad			; Restore

	 add	 sp,size INTXX_ERR ; Strip off error code
INT21_ORIG:
	 jmp	 INTPROC21	; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT|

Load and execute
Save the program name in case we abort.
Also check for programs flagged 'M' in 386LOAD.CFG, and lie
to them about POVR_MAC.

On entry in PL3 stack

DS:DX	 ==>	 program to load

|

	 public  INT21_EXEC
INT21_EXEC:
	 PUSHD	 0		; Put pseudo-error code on the stack

	 pushad 		; All GP registers

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR

	 push	 DTE_DS 	; Get our data selector
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 push	 DTE_D4GB	; Get our all memory selector
	 pop	 ds		; Address it
	 assume  ds:AGROUP	; Tell the assembler about it

	 mov	 fs,SEL_DSJG3	; Address JGROUP
	 assume  fs:JGROUP	; Tell the assembler

; Clear the @I15_XSPLIT flag.  It's only set when we detect a B-flagged program.
; Clear the @I15_FROUND flag (force rounding /256 + 256 a la NETX).
	 and	 I15_FLAG,not (@I15_XSPLIT or @I15_FROUND) ; Don't restrict
				; high DOS regions, and don't force rounding.

; Set the @I15_NOVELL flag.  It gets cleared by all 4B00/4B01 calls that
; make it down to QMAX_OVR (and back upstairs to INT21_MACFNS).  All UMBs
; will get this bit copied to @LSEG2_NOV in LSEG2_FLAG, where it tells
; us to make sure we round up the initialization modulo 256 bytes and add 256.
	 or	 I15_FLAG,@I15_NOVELL ; Assume we won't make it back

; As a safety valve on @GETRC calls, clear the @MSC_GETRC bit now

	 movzx	 eax,HIMEM_CS	; Get segment of QMAX_OVR
	 shl	 eax,4-0	; Convert to AGROUP: offset
	 add	 eax,offset PGROUP:MSC_FLAG ; Add offset of MSC_FLAG
	 and	 AGROUP:[eax].ELO,not @MSC_GETRC ; Clear the bit

	 movzx	 eax,[ebp].INTXX_DS ; Get caller's DS
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 esi,[ebp].INTXX_EDX.ELO ; Get caller's DX
	 add	 esi,eax	; Add to get 32-bit linear address

	 lea	 edi,MSG_APPLNAME[size LENTXT_LEN] ; ES:EDI ==> local save area

	 mov	 ecx,MSG_APPLNAME_LEN ; Get maximum size
	 mov	 edx,edi	; Save start of file basename
INT21_EXEC_NEXT:
	 lods	 AGROUP:[esi].LO ; Get one character
	 or	 al,al		; Izit EOL?
	 jz	 short INT21_EXEC_EOL ; Jump if so

;;;;;;;  call	 UPPERCASE	; Convert AL to uppercase
	 cmp	 al,'a'         ; Check lower limit
	 jb	 short @F	; Too small for us

	 cmp	 al,'z'         ; Check upper limit
	 ja	 short @F	; Too big for us

	 add	 al,'A'-'a'     ; Convert alpha to upper case
@@:
S32	 stos	 <PGROUP:[edi].LO> ; Copy one character

	 cmp	 al,':'         ; Izit a possible drive separator?
	 je	 short @F	; Jump if so

	 cmp	 al,'\'         ; Izit a path separator?
	 je	 short @F	; Jump if so

	 cmp	 al,'/'         ; Izit an alternate path separator?
	 jne	 short INT21_EXEC_LOOP ; Go around again if not

@@:
	 mov	 edx,edi	; Save start of file basename
INT21_EXEC_LOOP:
	 loop	 INT21_EXEC_NEXT ; Jump if more characters to check
INT21_EXEC_EOL:
	 sub	 cx,MSG_APPLNAME_LEN ; Subtract from maximum length
	 neg	 cx		; Negate to get actual length
	 mov	 MSG_APPLNAME.LENTXT_LEN,cx ; Save text length

; POVR_MAC in extended memory is OK.  The one in high DOS may be bogus...

	 sub	 edi,edx	; Calculate length of program basename
	 mov	 PBAPPBASE,edx	; Save offset in PGROUP of program basename

; Check for programs flagged in 386LOAD.CFG.  Assume no matches.

	 mov	 ax,POVR_MAC	; Assume we want to use the real POVR_MAC
	 call	 SET_POVR	; Set POVR_MAC in info structure to AX

	 and	 XMS_FLAG,not (mask $XMS_LCKPHYS) ; Assume linear address on
				; XMS_LCKXMB call
	 and	 XMS_FLAG,not (mask $XMS_NOXMSUMB) ; Allow allocation of
				; UMBs via XMS service 10h

	 and	 DSTK_FLAG,not (mask $DSTK_LCLOFF) ; Assume locally enabled

	 and	 I15_FLAG,not @I15_XSPLIT ; Assume no forcing of largest region
	 and	 I15_FLAG,not @I15_XEXEC ; Clear from the last time

	 and	 MSC_FLAG,not @MSC_NODPMI ; Retract nose
	 and	 MSC_FLAG,not @MSC_LCLX58 ; Enable 5800 support

	 mov	 PDC_FLAG,0	; Clear all DPMI Per-Client flags

	 sub	 bx,bx		; Index first entry in CFGLIST[]
	 mov	 cx,@CFGLIST_LEN ; Number of lists to check
INT21_EXEC_NEXTFLG:
	 push	 edi		; Pass length of program basename
	 push	 edx		; Pass offset in PGROUP of program basename
	 push	 CFGLIST[bx].LLST_DAT.LFLG_NEXT ; Pass pointer to linked lists
	 call	 CHECK_CFG_LINK ; Check the linked list
	 jnc	 near ptr INT21_EXEC_LOOPFLG ; Continue if not a match

	 jmp	 CFGLIST[bx].LLST_ACT ; Jump to action code for flag

INT21_EXEC_M0:
	 mov	 ax,POVR_LIE	; Don't tell the truth
	 call	 SET_POVR	; Set new POVR_MAC value in info structure

	 jmp	 INT21_EXEC_LOOPFLG ; Join common code

INT21_EXEC_M1:
	 or	 XMS_FLAG,mask $XMS_LCKPHYS ; Return physical address on LCKXMB

	 jmp	 INT21_EXEC_LOOPFLG ; Join common code

INT21_EXEC_M2:
	 or	 XMS_FLAG,mask $XMS_NOXMSUMB ; Disable XMS UMB allocation

	 jmp	 INT21_EXEC_LOOPFLG ; Join common code

INT21_EXEC_M3:
	 or	 MSC_FLAG,mask $MSC_LCLX58 ; Locally disable 5800 support

; We'll close off high DOS now, and quietly ignore any 5803 link calls
; until the next program loads (and $MSC_LCLX58 is cleared).
	 test	 I15_FLAG,@I15_LINK58 ; Are they linked?
	 jz	 short @F	; Jump if not

	 REGSAVE <ds,gs>	; Save

	 mov	 ds,SEL_DS3	; Address PGROUP
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 gs,SEL_4GB3	; Address all memory selector
	 assume  gs:AGROUP	; Tell the assembler

	 FIXICALL PGROUP:FCLOSEHIGHDOS,DTE_CS2 ; Unlink low and high DOS arenas

	 REGREST <gs,ds>	; Restore
	 assume  ds:AGROUP,gs:nothing ; Tell the assembler

;;;;;;;  jc	 short ???	; Ignore error

	 and	 I15_FLAG,not @I15_LINK58 ; Clear linked flag
@@:
	 jmp	 short INT21_EXEC_LOOPFLG ; Join common code

INT21_EXEC_K:
	 or	 DSTK_FLAG,mask $DSTK_LCLOFF ; Mark as locally disabled

	 jmp	 short INT21_EXEC_LOOPFLG ; Join common code

INT21_EXEC_X:
	 or	 I15_FLAG,@I15_XEXEC ; Don't let it load itself high

	 jmp	 short INT21_EXEC_LOOPFLG ; Join common code

INT21_EXEC_B:
; We need to defer setting the region to restrict ourselves to until
; we've fielded the first allocation we can't grant.
	 or	 I15_FLAG,@I15_XSPLIT ; Force allocations from largest region
	 mov	 BFLG_IDX,0	; Initialize index to unset value

	 jmp	 short INT21_EXEC_LOOPFLG ; Join common code


INT21_EXEC_H2:
; Force rounding up for NETBEUI and other programs that want more memory
; than they need.
	 or	 I15_FLAG,@I15_FROUND ; Force rounding (/256 + 256)

	 jmp	 short INT21_EXEC_LOOPFLG ; Join common code


; Enforce descriptor usage rules

INT21_EXEC_U1:
	 or	 PDC_FLAG,mask $I31_DUSE ; Enforce descriptor usage rules

	 jmp	 short INT21_EXEC_LOOPFLG ; Join common code


; Disallow Mouse Event Interrupts if in DOS

INT21_EXEC_U2:
	 or	 PDC_FLAG,mask $I31_XMEI ; Don't let MEIs through

	 jmp	 short INT21_EXEC_LOOPFLG ; Join common code


; Zero demand-allocated pages

INT21_EXEC_U3:
	 or	 PDC_FLAG,mask $I31_ZPD ; Zero demand-allocated pages

	 jmp	 short INT21_EXEC_LOOPFLG ; Join common code


; Limit lockable page count to 15MB

INT21_EXEC_U4:
	 or	 PDC_FLAG,mask $I31_L15 ; Limit lockable page count to 15MB

	 jmp	 short INT21_EXEC_LOOPFLG ; Join common code


; Lie about the DPMI version # (say it's 0.90)

INT21_EXEC_U5:
	 or	 PDC_FLAG,mask $I31_VER090 ; Lie about the DPMI version # (say it's 0.90)

	 jmp	 short INT21_EXEC_LOOPFLG ; Join common code


; Skip swapfile for this DPMI client

INT21_EXEC_U6:
	 or	 PDC_FLAG,mask $I31_NOSWAP ; Skip swapfile for this DPMI client

	 jmp	 short INT21_EXEC_LOOPFLG ; Join common code


; Lie about availability of DPMI services to this client

INT21_EXEC_U7:
	 or	 MSC_FLAG,@MSC_NODPMI ; Tell a lie

;;;;;;;; jmp	 short INT21_EXEC_LOOPFLG ; Join common code


INT21_EXEC_LOOPFLG:
	 add	 bx,size LLST_STR ; Skip to next flag list

;;;;;;;; loop	 INT21_EXEC_NEXTFLG ; Go around again
	 dec	 cx		; One fewer iteration
	 jnz	 near ptr INT21_EXEC_NEXTFLG ; Go around again

	 jmp	 INT21_CHAIN	; Continue with the original handler

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT21	 endp			; End INT21 procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 NPPROC  CHECK_CFG_LINK -- Check CFG File Linked List
	 assume  ds:AGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check CFG file linked list

On exit:

CF	 =	 0 if no match
	 =	 1 if it matches

|

CHECK_CFG_LSTR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
CHECK_CFG_LOFF dd ?		; Offset in PGROUP of start of linked list
CHECK_CFG_FNAM dd ?		; Offset in PGROUP of program basename
CHECK_CFG_LEN dd ?		; Length of program basename

CHECK_CFG_LSTR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,edx,esi,edi> ; Save registers

	 mov	 edx,[ebp].CHECK_CFG_LOFF ; Get pointer to untruth list
CHECK_CFG_LINK_NEXT:
	 cmp	 edx,-1 	; Izit the end of the line?
	 je	 short CHECK_CFG_LINK_EXIT ; Jump if not (note CF=0)

	 mov	 esi,PGROUP:[edx].LFLG_FNAM ; Get offset of program name
	 mov	 edi,[ebp].CHECK_CFG_FNAM ; Get offset of program basename
	 mov	 ecx,[ebp].CHECK_CFG_LEN ; Get length of program basename

    repe cmps	 PGROUP:[esi].LO,PGROUP:[edi].LO ; Izit a match?
	 jne	 short CHECK_CFG_LINK_LOOP ; Jump if not

	 cmp	 PGROUP:[esi].LO,' ' ; Izit the end of the name?
	 je	 short @F	; Jump if matched
CHECK_CFG_LINK_LOOP:
	 mov	 edx,PGROUP:[edx].LFLG_NEXT ; Point to next offset

	 jmp	 short CHECK_CFG_LINK_NEXT ; Go around again

@@:
	 stc			; Mark as a match
CHECK_CFG_LINK_EXIT:
	 REGREST <edi,esi,edx,ecx> ; Restore

	 pop	 ebp		; Restore

	 ret	 4+4+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CFG_LINK endp		; End CHECK_CFG_LINK procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 NPPROC  CLOSEHIGH -- Close Off High DOS Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Close off high DOS memory

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax,ebx,dx,esi> ; Save registers

	 movzx	 esi,HIMEM_CS	; Address QMAX_OVR
	 shl	 esi,4-0	; Convert paras to bytes

	 assume  gs:PGROUP	; Tell a white lie
	 cmp	 gs:HDM_FLAG[esi],@HDM_CLOS ; Izit already closed off?
	 assume  gs:AGROUP	; Retract nose
	 je	 short CLOSEHIGH_CLC ; Jump if so (nothing to do)

; The two arenas are linked together:  unlink them

; Follow the memory allocation chain to the last entry below the
; video buffers and mark the one before that as the last entry

	 movzx	 eax,P1ST_MAC.VSEG ; Get segment of head of MAC entries
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,P1ST_MAC.VOFF ; Get offset ...
	 add	 ebx,eax	; AGROUP:EBX ==> linear address

	 call	 TOPDOS 	; Get top of contiguous DOS memory into AX
	 shl	 ax,10-4	; Convert from 1KB to paras
	 dec	 ax		; Back off to previous entry
	 mov	 dx,ax		; Save for later use

; Point to next MAC entry (if not the last)

CLOSEHIGH_NEXT:
	 mov	 eax,ebx	; Copy current address
	 shr	 eax,4-0	; Convert from bytes to paras
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,AGROUP:[ebx].MAC_NPAR ; Add in # paragraphs in this entry

; Ensure we are where we think we should be

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Maybe it's the last entry
	 je	 short CLOSEHIGH_ERR ; It is, so that's an error

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Maybe it's a middle entry
	 jne	 short CLOSEHIGH_ERR ; Not this time

	 cmp	 ax,dx		; Found it as yet?
	 jae	 short CLOSEHIGH_FOUND ; Yes

	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 ebx,eax	; Point to next entry

	 jmp	 CLOSEHIGH_NEXT ; Go around again

CLOSEHIGH_FOUND:
	 mov	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Mark as the last entry

; Leave the spanning entry in place a la DOS 5
;;;;;;;; If we're told to emulate DOS 5, leave the spanning entry there
;;;;;;;
;;;;;;;  test	 CM2_FLAG,@CM2_DOS5 ; Emulating DOS 5's warts?
;;;;;;;  jnz	 short @F	; Jump if so
;;;;;;;
;;;;;;;  inc	 AGROUP:[ebx].MAC_NPAR ; Add the MAC entry back into the chain
;;;;;;;@@:
	 assume  gs:PGROUP	; Tell a white lie
	 mov	 gs:HDM_FLAG[esi],@HDM_CLOS ; Mark as closed off
	 assume  gs:AGROUP	; Retract nose
CLOSEHIGH_CLC:
	 clc			; Indicate

	 jmp	 short CLOSEHIGH_EXIT ; Join common exit code

CLOSEHIGH_ERR:
	 stc			; Indicate something went wrong
CLOSEHIGH_EXIT:
	 REGREST <esi,dx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLOSEHIGH endp			; End CLOSEHIGH procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 NPPROC  OPENHIGH -- Open Up High DOS Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Open up high DOS memory

On exit:

CF	 =	 0 if successful
	 =	 1 if not

|

	 REGSAVE <eax,ebx,dx,esi> ; Save registers

	 movzx	 esi,HIMEM_CS	; Address QMAX_OVR
	 shl	 esi,4-0	; Convert paras to bytes

	 assume  gs:PGROUP	; Tell a white lie
	 cmp	 gs:HDM_FLAG[esi],@HDM_CLOS ; Izit already closed off?
	 assume  gs:AGROUP	; Retract nose
	 jne	 near ptr OPENHIGH_CLC ; Jump if not (nothing to do)

; The two arenas are not linked together:  link them

; Follow the memory allocation chain to the last entry below the
; space allocated for a spanning entry and mark that one as a middle entry

	 movzx	 eax,P1ST_MAC.VSEG ; Get segment of head of MAC entries
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,P1ST_MAC.VOFF ; Get offset ...
	 add	 ebx,eax	; AGROUP:EBX ==> linear address

	 call	 TOPDOS 	; Get top of contiguous DOS memory into AX
	 shl	 ax,10-4	; Convert from 1KB to paras
	 dec	 ax		; Back off to spanning entry
	 mov	 dx,ax		; Save for later use

; Point to next MAC entry (if not the last)

OPENHIGH_NEXT:
	 mov	 eax,ebx	; Copy current address
	 shr	 eax,4-0	; Convert from bytes to paras
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,AGROUP:[ebx].MAC_NPAR ; Add in # paragraphs in this entry

; Ensure we are where we think we should be

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Maybe it's the last entry
	 je	 short OPENHIGH_LAST1 ; It is, check for validity

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Maybe it's a middle entry
	 jne	 short OPENHIGH_ERR ; Not this time

	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 ebx,eax	; Point to next entry

	 jmp	 OPENHIGH_NEXT	; Go around again

OPENHIGH_LAST1:
	 cmp	 ax,dx		; Found it as yet?
	 jne	 short OPENHIGH_ERR ; No, so that's an error
;;;;;;;  je	 short OPENHIGH_LAST2 ; Jump if so
;;;;;;;
;;;;;;;; If we're told to emulate DOS 5, the spanning MAC entry
;;;;;;;; might already be present
;;;;;;;
;;;;;;;  test	 CM2_FLAG,@CM2_DOS5 ; Emulating DOS 5's warts?
;;;;;;;  jz	 short OPENHIGH_ERR ; No, so that's an error
;;;;;;;
;;;;;;;  dec	 dx		; Decrement expected top para
;;;;;;;
;;;;;;;  cmp	 ax,dx		; Found it as yet?
;;;;;;;  jne	 short OPENHIGH_ERR ; No, so that's an error
;;;;;;;
;;;;;;;; At this point, it appears that there is room for the spanning
;;;;;;;; MAC entry, but it might not actually be present.
;;;;;;;
;;;;;;;  jmp	 short OPENHIGH_LAST3 ; Join common code
;;;;;;;
;;;;;;;; The end of the load DOS MAC entry chain points to top of DOS
;;;;;;;; at (say) 9FFF.  We've already set aside one paragraph for the
;;;;;;;; spanning entry in FINDZMAC.
;;;;;;;
;;;;;;;OPENHIGH_LAST2:
;;;;;;;; DX=AX and AX:0 ==> last para in low DOS (9FFF).  Blast in a spanning
;;;;;;;; entry.
;;;;;;;  dec	 AGROUP:[ebx].MAC_NPAR ; Delete the MAC entry from the chain
;;;;;;;  dec	 dx		; Back off to previous para
;;;;;;;  mov	 ax,dx		; Back off to spanning entry
;;;;;;;OPENHIGH_LAST3:

; Mark it as a middle entry

	 mov	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Mark as a middle entry

; Fill in new MAC entry just below video buffers

	 shl	 eax,4-0	; Convert from paras to bytes
	 mov	 ebx,eax	; Point to next entry

	 mov	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Mark as a middle entry
	 mov	 AGROUP:[ebx].MAC_OWNR,@MAC_LINK ; Mark as a linking entry
	 mov	 AGROUP:[ebx].MAC_NAME[0].EDD,'CS' ; Blast in a name MEM knows
				; with trailing zero(s)
	 mov	 ax,POVR_MAC	; Get segment of first MAC entry in high DOS
	 sub	 ax,dx		; Less top of low DOS memory
	 dec	 ax		; Less the MAC entry
	 mov	 AGROUP:[ebx].MAC_NPAR,ax ; Save as # paras in MAC entry

	 assume  gs:PGROUP	; Tell a white lie
	 mov	 gs:HDM_FLAG[esi],@HDM_OPEN ; Mark as opened up
	 assume  gs:AGROUP	; Retract nose
OPENHIGH_CLC:
	 clc			; Indicate

	 jmp	 short OPENHIGH_EXIT ; Join common exit code

OPENHIGH_ERR:
	 stc			; Indicate something went wrong
OPENHIGH_EXIT:
	 REGREST <esi,dx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OPENHIGH endp			; End OPENHIGH procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 NPPROC  TOPDOS -- Get Top of DOS Memory into AX
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

On exit:

AX	 =	 top of DOS memory in 1KB

|

;;;;;;;  mov	 ax,OLDDOS	; Get top of original DOS in paras
;;;;;;;  add	 ax,(1024/16)-1 ; Round up to 1KB in paras
;;;;;;;  shr	 ax,10-4	; Convert from paras to 1KB
;;;;;;;  add	 ax,LOWSIZE	; Plus size of added low memory

	 mov	 ax,AGROUP:[0413h].ELO ; Get Int 12h value for low DOS size

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TOPDOS	 endp			; End TOPDOS procedure
endif				; IF @OEM_HIFILL
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment

	 MEND			; End QMAX_I21 module
