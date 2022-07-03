;' $Header:   P:/PVCS/MAX/386LOAD/DRVCOM.ASV   1.2   30 May 1997 10:38:02   BOB  $
	 page	 70,132
	 title	 DRVCOM -- Common MOVEIT Device Driver Loader For CONFIG.SYS
	 name	 DRVCOM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:

Group RGROUP:
	       Program segment RCODE,	para-aligned,  public, class 'rcode'
	       Data    segment RDATA,	dword-aligned, public, class 'rdata'
Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Program segment DATZ,	para-aligned,  public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Data    segment DTAIL,	para-aligned,  public, class 'zdata'
	       Program segment ACODE,	byte-aligned,  public, class 'zdata'
	       Data    segment ADATA,	dword-aligned, public, class 'zdata'
	       Data    segment SEG_TXT, byte-aligned,  public, class 'zdata'
	       Data    segment SEG_LEN, word-aligned,  public, class 'zdata'
	       Data    segment SEG_TAB, word-aligned,  public, class 'zdata'
	       Data    segment SEG_ACT, word-aligned,  public, class 'zdata'
	       Data    segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Program derived from:  None.

Original code by:  Bob Smith, February 1988.

Modifications by:  None.

Notes:
	In this version we have included segment ACODE in our
	relocatable code many of the routines are used only in
	initialization.  We should look into moving the routines
	that we need into another segment in an effort to reduce
	the amount of code before the GTAIL cut off point.

	Whether loading driver low or high in memory we need to
	install int 23 and 24 handlers.  When GETSIZE is executed,
	we put our LSEG entry in low memory.

	When installing low via INSTALL_LOW proc the strategy routine is
	called with the stack allocated when we moved to the top of DOS.
	Should we return the stack to the one we were called with and
	jump to the target driver strategy?

	There is no need for RES_STRA_COM and RES_INTR_COM they never
	get called.  We should really get rid of them.	This would
	reduce our high DOS footprint by 128 bytes to about 64 bytes.
|

.xlist
	 include MASM.INC
	 include DOS.INC
	 include DEVDRV.INC
	 include EXE.INC
	 include MAC.INC
	 include INTVEC.INC
	 include VIDATTR.INC
	 include BITFLAGS.INC
	 include BIOSDATA.INC
	 include DEVMAC.INC
	 include PTR.INC
	 include OPCODES.INC
	 include LSTLST.INC
	 include EXEC.INC
	 include DPB.INC
	 include DOSERR.INC

	 include LOAD_OEM.INC
	 include QMAX_FMT.INC
.list
;
;
;
ARG_STR  struc

	 dw	 ?		; Caller's BP
ARG_CSIP dd	 ?		; Caller's return address
ARG_FLG  dw	 ?		; Caller's flags

ARG_STR  ends
;
; Number of nested drivers to support
;
; Apparently, Banyan uses 6 nested drivers, and a certain GPIB drive is..
; command line configurable and we have customer that is using 36 devices.
;
@NEST	 equ	 70
;
; Device driver header and target data structure
;
DH_STR	 struc			; Device driver header & parameter table

DH_NEXT  dd	 -1		; 00: Pointer to next device drive in chain
DH_ATTR  dw	 ?		; 04: Attributes
DH_STRA  dw	 ?		; 06: Offset of strategy routine
DH_INTR  dw	 ?		; 08: Offset of interrupt routine
DH_NAME  db	 '        '     ; 0A: Char device name, block device # units
; End of normal device header
DH_THDR  dw	 ?		; 12: Offset of target header
DH_TFLG  db	 ?		; 14: Target device flags

DH_STR	 ends			; End DH_STR

; DH_ element values
@DH_NAME_LEN equ 8		; Length of DH_NAME

; Flags for DH_TFLG
@STRA_FLG equ	 1		; Init strat called
@INTR_FLG equ	 2		; Init int called
@RLOC_FLG equ	 4		; Target has been linked direct to chain
@STUB_FLG equ	 8		; Header is a stub to be removed
;
; Structure used to reference far jmp data
;
FJMP_STR struc			; Far jump code

FJ_OPCODE  db	 ?		; Opcode for jump
FJ_ADDR    dd	 ?		; Address for far jump

FJMP_STR ends			; End FJMP_STR
;
; Structure used to referenced stack information
; for the resident common strategy and interrupt handlers
;
RSI_STR struc		      ;

	 dw   ? 	      ; Pushed BP
RSI_OSI  dw   ? 	      ; Pushed SI / far return offset
RSI_HREF dw   ? 	      ; Header ref via near return / far return segment

RSI_STR ends		      ; End RSI_STR
;
; Structure used to referenced stack information
; for the relocatable common strategy and interrupt handlers
;
CSI_STR struc		      ;

	 dw   ? 	      ; Pushed BP
CSI_ODS  dw   ? 	      ; Pushed DS / far return offset
CSI_HREF dw   ? 	      ; Header ref via near return / far return segment
CSI_DOSRET dd ? 	      ; Far return to DOS

CSI_STR ends		      ; End CSI_STR

PGROUP	 group	 CODE,DATZ,NCODE,NDATA,DTAIL,ACODE,ADATA,SEG_TXT,SEG_LEN,SEG_TAB,SEG_ACT

DATZ	 segment para public 'data' ; Start DATZ segment
	 assume  ds:PGROUP

	 extrn	 EXEC_PSP:word
	 extrn	 CFGFLAGS:word
	 extrn	 PATCHFLAGS:word
	 extrn	 @CFG_TOPF:abs
	 extrn	 @CFG_PROTMAN:abs
	 extrn	 @CFG_PTOPF:abs
	 extrn	 @CFG_CLOSEHI:abs
	 extrn	 @CFG_DRVSPC:abs
if @OEM_FLEX
	 extrn	 OLDINT67_PATCH:dword
endif				; IF @OEM_FLEX

	public	OLDINT2F_VEC,INT2F_TEMP
OLDINT2F_VEC dd ?		; Save area for old INT 2Fh handler
INT2F_TEMP dw	?		; Temporary storage for LCL_INT2F routine

DATZ	 ends			; End DATZ segment


DTAIL	 segment para public 'zdata' ; Start DTAIL segment
	 assume  ds:PGROUP

	 extrn	 POVR_MAC:word
	 extrn	 OLDDOS:word
	 extrn	 LOADSEG:word
	 extrn	 GTAIL:byte

DTAIL	 ends			; End DTAIL segment


ZZTAIL	 segment dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 extrn	 ZTAIL:byte

ZZTAIL	 ends			; End ZZTAIL segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 KEYWAIT:near
	 extrn	 REST_2324:near
	 extrn	 NEWLINE:near
	 extrn	 MAC_MERGE:near
if @OEM_FLEX
	 extrn	 REST67:near
	 extrn	 CLEAR_EMSPTE:near
endif				; IF @OEM_FLEX
	 extrn	 TOPFILL_CHECK:near
	 extrn	 GETMEM_REG:near
	 extrn	 GETMEM_SRCH:near

NCODE	 ends			; End NCODE segment


NDATA	 segment dword public 'ndata' ; Start NDATA segment
	 assume  cs:PGROUP

	 extrn	 DOSVER:word
	 extrn	 XDOSVER:word
	 extrn	 TOPFILL:word
	 extrn	 PROT_NAME:byte
	 extrn	 RESPARA:word

NDATA	 ends			; End NDATA segment


RGROUP	 group	 RCODE,RDATA

RCODE	 segment para public 'rcode' ; Start RCODE segment
RCODE	 ends			; End RCODE segment

RDATA	 segment dword public 'rdata' ; Start RDATA segment
RDATA	 ends			; End RDATA segment


CODE	 segment para public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 public  DRVSTART
DRVSTART label	 near

COMMENT|

	Please note that the LSEG must be the first item in this segment

|
	 include LOAD_SEG.INC
	 public  LSEG
LSEG	 LSEG_STR <-1,-1,,0,0,0,0,0,0,0,@NOTSPEC,@NOTSPEC,@LSEG_DRV,0,0,?,?,?,0>

	 NPPROC  RES_INTR_COM -- Device Driver Resident Interrupt Routine
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Common interrupt routine.
Note that we use self-modifying code, so this is completely non-reentrant.

Entry:
	 offset of device header + @INTR_BACK

|

	 push	 si		; Save
	 push	 bp		; for far return/call to target device
	 mov	 bp,sp		; Set up BP to index stack data

	 push	 ds		; Save ds
	 mov	 si,seg RGROUP	; Set up DS to reference header data
	 mov	 ds,si		;
	 assume  ds:RGROUP	; Tell assembler

	 mov	 si,[bp].RSI_HREF ; Get header reference offset

	 mov	 si,RGROUP:[si-1].ELO ; Force a signed byte offset
	 public  SBO_THOFF
	 org	 $-1		; Back off to signed byte offset
SBO_THOFF db	 ?		; Signed byte offset to target header offset

	 public  TARG_SEG
	 mov	 ax,1234h	; Force a word argument
	 org	 $-2		; Back off to word argument
TARG_SEG dw	 0		; Segment of the target driver
	 mov	 ds,ax		; Set up DS to reference target header
	 assume  ds:nothing	; Tell assembler

	 mov	 si,ds:[si+1].ELO ; Force a signed byte offset
	 public  SBO_HPTR
	 org	 $-1		; Back off to signed byte offset
SBO_HPTR db	 ?		; Signed byte offset to handler pointer

	 mov	 [bp].RSI_HREF,ds ; Put target driver addr on stack for far ret
	 xchg	 [bp].RSI_OSI,si  ; Get back original SI and set return offset

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler

	 pop	 bp		; Restore

	 xor	 ax,ax		; Clear because some DDs expect it

; In case we came here from RES_STRA_COM, restore the defaults.
	 public  RES_INTR_DEF
RES_INTR_DEF label far
	 mov	 SBO_THOFF,DH_THDR-@INTR_BACK ; Signed displacement for intr
	 mov	 SBO_HPTR,DH_INTR ; Signed displacement for handler pointer

	 retf			; Transfer control to target
				; We don't expect to return

	 assume  ds:nothing,es:nothing,ss:nothing

RES_INTR_COM endp		; End DEV_INTR_COM procedure
	 NPPROC  RES_STRA_COM -- Device Driver Resident Strategy Routine
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Common strategy routine.
Note that we use self-modifying code, so this is completely non-reentrant.
Note also that we jump backwards to handle long prefetch queues.

Entry:
	 offset of device header + @STRA_BACK
|
	 mov	 SBO_THOFF,DH_THDR-@STRA_BACK ; Signed displacement for strategy
	 mov	 SBO_HPTR,DH_STRA ; Signed displacement for handler pointer
	 jmp	 short RES_INTR_COM ; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing

RES_STRA_COM endp		; End DEV_STRA_COM procedure
	 public LSEG_TAIL
LSEG_TAIL label byte		; Marker for size of normal LSEG

; Under DOS 5 and up, this data is not only unneeded, it's probably
; been smeared with MAC entry...
	 public  OLDINT21_VEC
OLDINT21_VEC dd  ?		; Save area for old INT 21h interrupt handler
	 public  UDDPB_CNT
UDDPB_CNT db	 0		; Number of DPBs with driver addr not set
;
; Special flag for UDDPB_CNT signifying the DPB should be searched
;
@UDDPB_FLG equ	 80h		; Flag

	 public  INT21,TMPINT21_VEC
INT21:
	 db	 @OPCOD_JMPF	; Opcode for far jump immediate
TMPINT21_VEC dd  PGROUP:NR_INT21 ; Far address for NR_INT21

	 NPPROC  RES_INT21 -- Device Driver Resident Interrupt 21 Routine
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Interrupt 21 laundering routine.

Note this routine will only get called if we are running on DOS versions
prior to 5.0 and we did not patch all of the DPB for block devices.

Entry:

|
	 test	 UDDPB_CNT,@UDDPB_FLG ; Has a function 53 taken place?
	 jz	 short RES_INT21_EXIT ; No, go

	 REGSAVE <ax,bx,si,ds,es> ; Save what we are going to use

	 mov	 ah,@GETLST	; Function to Get LOL
	 pushf			;
	 call	 OLDINT21_VEC	; Call real Int 21 handler
	 assume  es:nothing	; Tell assembler

	 les	 bx,es:[bx].LSTLST_DPB ; Get pointer to first DPB

RES_INT21_NEXT:
	 les	 bx,es:[bx].DPB3_DPP ; Get the next DPB pointer
	 assume  es:nothing	; Tell assembler

	 cmp	 bx,-1		; Is this the last one
	 je	 RES_INT21_DONE ; Yea, exit

	 cmp	 es:[bx].DPB3_DDP.VSEG,seg RGROUP ; Is this DPB for our target?
	 jne	 short RES_INT21_NEXT ; No, try again

	 lds	 si,es:[bx].DPB3_DDP ; Get pointer to header for device
	 assume  ds:nothing	; Tell assembler

	 mov	 ax,ds:[si].DH_THDR ; Get the target header offset
	 mov	 es:[bx].DPB3_DDP.VOFF,ax ; Set the device driver offset
	 mov	 ax,TARG_SEG	; Get the segment of the target header
	 mov	 es:[bx].DPB3_DDP.VSEG,ax ; Set the device driver segment

	 and	 UDDPB_CNT,not @UDDPB_FLG ; Reset our magic flag

	 dec	 UDDPB_CNT	; Bump counter down
	 jnz	 short RES_INT21_NEXT ; Any left? Yes go

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 ax,OLDINT21_VEC.VSEG ; Get old segment
	 mov	 TMPINT21_VEC.VSEG,ax ; Save as intermediate value

	 mov	 ax,OLDINT21_VEC.VOFF ; Get old offset
	 mov	 TMPINT21_VEC.VOFF,ax ; Save as intermediate value

	 popf			; Restore flags

RES_INT21_DONE:
	 REGREST <es,ds,si,bx,ax> ; Restore used

RES_INT21_EXIT:
	 cmp	 ah,@BP2DPB	; Is this a build DPB request?
	 jne	 short @F	; No, exit

	 or	 UDDPB_CNT,@UDDPB_FLG ; Set our magic flag
@@:
	 jmp	 OLDINT21_VEC	; Continue with previous handler
	 assume  ds:nothing,es:nothing,ss:nothing

RES_INT21 endp			; End RES_INT21
	 public LSEG_TAIL4
LSEG_TAIL4 label byte		; Marker for size of DOS 4 LSEG

; I don't understand why this is necessary.
;;;;;;;;
;;;;;;;; MAC marking the end of the LSEG allocation
;;;;;;;;
;;;;;;;  public  LSEG_MAC
;;;;;;;  ALIGN	 16
;;;;;;;LSEG_MAC MAC_STR <@MAC_MID,@MAC_FREE,0,0,0,'LSEGTAIL'>
;;;;;;;
CODE	 ends			; End CODE segment
;
;
;
DWMAC	 macro	 NAME,NUM
	 dw	 NAME&NUM
	 endm			; DWMAC
;
;
;
PUBMAC	 macro	 NAME,NUM
	 public  NAME&NUM
NAME&NUM label	 byte		; Next available byte if nested drivers
	 endm			; PUBMAC
page
NDATA	 segment dword public 'ndata' ; Start NDATA segment
	 assume  cs:PGROUP

	 extrn	 LC2_FLAG:word
	 include LOAD_LC2.INC

	 extrn	 PRGREG:byte
	 extrn	 CON10:word
	 extrn	 MSG_COPY:byte
	 extrn	 EXEC_PRGNPAR:word

	 extrn	 AZS_ERRMAC:byte
	 extrn	 AZS_ERRMEM:byte
	 extrn	 AZS_NOLOAD:byte
	 extrn	 AZS_LOADLO:byte
	 extrn	 AZS_ARGS:byte
	 extrn	 AZS_XHILOAD:byte
	 extrn	 AZS_XMAXLOW:byte

	 extrn	 EXEC_PRGMAC:word
	 extrn	 FILE_HEAD:byte

	 public  LCL_FLAG
	 include LOAD_LCL.INC
LCL_FLAG dw	 0		; Local flags

	 public  OPT_FLAG
	 include LOAD_OPT.INC
OPT_FLAG dw	 @OPT_DRVDEF	; Option flags with defaults

	 public  PDEVEND
PDEVEND  label	 word		; Pointer to ending offset

	 public  EXEC_INTMAC
EXEC_INTMAC dw	 0		; Pseudo-interrupt handler MAC segment

	 public  EXEC_BLK,EXEC_LOD,EXEC_REL
EXEC_BLK label	 word		; EXEC call parameter block
EXEC_LOD dw	 0		; Pointer to high DOS memory
EXEC_REL dw	 0		; Relocation factor

	 public  PDEV_VEC,PATH_END,PCURDEV
PDEV_VEC dd	 ?		; Pointer to Device= argument
PATH_END dw	 ?		; Offset in PDEV_VEC.VSEG of end of path
PCURDEV  dw	 0		; Offset in EXEC_LOD of current driver

	 public  PFID_OFF,PFID_NAM,PFID_LEN,PFID_ROOM
PFID_OFF dw	 ?		; Offset of PROG= argument
PFID_NAM dw	 ?		; Offset of "filename.ext"
PFID_LEN dw	 ?		; Length of ...
PFID_ROOM dd	 ?		; Room needed for ...

	 public  PARG_VEC
PARG_VEC dd	 ?		; Pointer to PROG= argument's arguments


	 public  LSEGSEG
LSEGSEG  dw	 PGROUP 	; Segment of LSEG

	 public  MSG_DEVICE
MSG_DEVICE db	 'Device=',CR


	 public  LCLINT24_VEC
LCLINT24_VEC dd  ?		; Save area for old INT 24h handler

	 public  LCL_FID,LCL_PATH
LCL_PATH label	 byte
LCL_FID  db	 80 dup (0)	; Local copy of FID

	 public  OLDSTK_VEC
OLDSTK_VEC dd	  ?		; Save area for old stack pointer #1

	 public  TEMPSTK,TEMPSTKZ
TEMPSTK dw	 100h dup (0CDEFh) ; Temporary stack
TEMPSTKZ label	word		; End of temporary stack #1

	 public  I12_DELTA
I12_DELTA dw	 64+2		; Value in K to reduce Int 12h by for PROTMAN$

NDATA	 ends			; End NDATA segment


CODE	 segment para public 'prog' ; Start CODE segment
	 assume  cs:PGROUP	; Tell assembler

	 public  RH_VEC
RH_VEC	 dd	 ?		; Request header vector

	 public  DH_PTR
DH_PTR	 dd	 ?		; Ptr to current DH_ struc

	 public  DRVEND_VEC
DRVEND_VEC dd	 0		; Last INIT_END_VEC returned by driver

	 public END_SEG
END_SEG  dw	 0		; Ending low DOS paragraph

	 public  DRV_FLAG
DRV_FLAG dw	 00h		; Driver flags for post initialization tests
@DF_CHAR equ	 20h		; Current target is a character device
@DF_FAIL equ	 40h		; Getsize was specified on a failing device
@DF_LAST equ	 80h		; Last target device found

	 public  DSBACK_PTR,lpbDBLSPACE_MOVED,lpbLOCAL_DRIVECOUNT,cBLOCKDEV
DSBACK_PTR dd	 0		; Far call to DBLSPACE.BIN back door
lpbDBLSPACE_MOVED dd ?		; Far pointer to DBLSPACE_MOVED flag
lpbLOCAL_DRIVECOUNT dd ?	; Far pointer to LOCAL_DRIVECOUNT
cBLOCKDEV db	 0		; Total number of block devices processed

RES_HDRS equ	 2		; Number of headers used to De-chain...
				; loader headers
MIN_HDRS equ	 4		; Minimum number of headers to have...
				; to De-chain loader
	public DEVDRVTBL
DEVDRVTBL label word		; Table of device header offsets
CNT	 =	 0		;
	 rept	 @NEST		;
	 DWMAC	 RGROUP:DEVDRV,%CNT ;
CNT	 =	 CNT+1		;
	 endm			; REPT @NEST

	 FPPROC  DEV_STRA_COM -- Device Driver Strategy Routine Common
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Common strategy routine.

On entry:
	The header reference offset pushed onto the stack
	This is actually a near return pointer from the header
	macro, where we make a near call to RES_INTR_COM which
	in turn jumps here.
On exit:

|
	 push	 ds		; Save
	 push	 bp		;
	 mov	 bp,sp		; Set up BP to index stack data
	 push	 ax		;

	 xchg	 si,[bp].CSI_HREF ; Save the SI on the stack and get reference ptr

	 mov	 ax,seg RGROUP	; Get the segment of RGROUP...
	 mov	 ds,ax		; and set DS for data references to it
	 assume  ds:RGROUP	; Tell assembler

	 sub	 si,@STRA_BACK	; Adjust si to point to start of header

	 test	 RGROUP:[si].DH_TFLG,@STRA_FLG ; Have we called loader?
	 jz	 short DSC_010	; No, go

	 mov	 si,RGROUP:[si].DH_THDR ; Get target header offset
	 mov	 ds,TARG_SEG	; Get the segment of the target header
	 assume  ds:nothing	; Tell assembler

	 mov	 si,ds:[si].DH_STRA ; Get strategy pointer

	 mov	 ax,ds		; Get handler segment

	 xchg	 ax,[bp].CSI_HREF ; Get original SI value and set return segment

	 xchg	 ax,si		; Return SI to original value

	 xchg	 [bp].CSI_ODS,ax ; Get back original DS and set return offset

	 mov	 ds,ax		; Restore DS to original value
	 assume  ds:nothing	; Tell assembler

	 pop	 ax		; Restore AX...
	 pop	 bp		; and BP

	 xor	 ax,ax		; Clear because some DDs expect it

	 retf			; Transfer control to target driver
				; We don't expect to return
DSC_010:
	 assume  ds:RGROUP	; Tell assembler

; If it's DOS 6, do a code model search for the magic cookie call to
; DBLSPACE.BIN.
	 mov	 ax,[bp].CSI_DOSRET.VSEG ; Get segment of caller
	 call	 CHK_DBLSPBACK	; Find DBLSPACE.BIN's back door...

	 pop	 ax		; Restore registers we aren't going to use anymore
	 pop	 bp		;

	 or	 RGROUP:[si].DH_TFLG,@STRA_FLG ; Set flag to avoid re-entrancy

	 mov	 RH_VEC.VSEG,es ; Save segment of request header pointer
	 mov	 RH_VEC.VOFF,bx ; ...  offset

	 mov	 DH_PTR.VOFF,si ; Save current device header pointer
	 mov	 DH_PTR.VSEG,ds ; ...

; DR DOS purposely zeros the segment portion of next driver pointer
; of the driver, probably to be compatible with MS-DOS.
; In our case, we've put a relocatable segment value there and we'd
; like it to remain that way, thank you very much.

	 mov	 RGROUP:[si].DD_NEXT.VSEG,ds ; Put it there again

	 test	 DRV_FLAG,@DF_LAST ; Any target drivers to install?
	 jnz	 short DSC_080	; No, Goto common exit

	 test	 LCL_FLAG,@LCL_INST ; Are we already installed?
	 jnz	 short @F	; Yes, bypass installation

; The following CALL is mimicked in the INSTALL_LOW code below.
; Changes here to saved data on the stack should be reflected there.
; At the moment, INSTALL_LOW strips off the return address from the stack.

	 call	 INSTALL	; Load the driver into memory
	 jc	 short DSC_080	; Something went wrong. Exit stage right

@@:
	 call	 SAVE_INT12	; Set memsize back to pre-MAX time
	 call	 REST_INIT_END_VEC ; Restore to last value
	 call	 COMSEG 	; Copy target driver information
	 call	 DRVSPC_HOOK	; If appropriate, hook INT 2F/4A11/FFFC to lie

	 REGSAVE <bp,si,ds>	; Save header pointer

	 mov	 si,RGROUP:[si].DH_THDR ; Get target header offset
	 mov	 ds,TARG_SEG	; Get the segment of the target header
	 assume  ds:nothing	; Tell assembler

	 mov	 si,ds:[si].DH_STRA ; Get strategy pointer

	 push	 ds		; Push target interrupt ..
	 push	 si		; address onto stack
	 mov	 bp,sp		; Set up index for call

	 xor	 ax,ax		; Clear because some DDs expect it

	 call	 [bp].EDD	; Call target strategy

	 add	 sp,4		; Remove target call from stack

	 REGREST <ds,si,bp>	; Restore pointer
	 assume  ds:RGROUP	; Tell assembler

	 call	 DRVSPC_UNHOOK	; If appropriate, unhook INT 2F/4A11/FFFC
	 call	 COMSEG 	; Copy again, just in case it changed
	 call	 SAVE_INIT_END_VEC ; Save driver's ending value
	 call	 REST_INT12	; Restore mem size
DSC_080:
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell assembler

	 pop	 si		; Restore

	 ret			; Return to caller
	 assume  ds:nothing,es:nothing,ss:nothing

DEV_STRA_COM endp		; End DEV_STRA_COM procedure
	 FPPROC  DEV_INTR_COM -- Device Driver Interrupt Routine Common
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Common interrupt routine.

On entry:
	  The header reference offset pushed onto the stack

On exit:

|
	 push	 ds		; Save
	 push	 bp		;
	 mov	 bp,sp		; Set up BP to index stack data
	 push	 ax		;

	 xchg	 si,[bp].CSI_HREF ; Save the SI on the stack and get reference ptr

	 mov	 ax,seg RGROUP	; Get the segment of RGROUP...
	 mov	 ds,ax		; and set DS for data references to it
	 assume  ds:RGROUP	; Tell assembler

	 sub	 si,@INTR_BACK	; Adjust si to point to start of header

	 test	 RGROUP:[si].DH_TFLG,@INTR_FLG ; Have we called loader?
	 jz	 short DIC_010	; No, go

	 mov	 si,RGROUP:[si].DH_THDR ; Get target header offset
	 mov	 ds,TARG_SEG	; Get the segment of the target header
	 assume  ds:nothing	; Tell assembler

	 mov	 si,ds:[si].DH_INTR ; Get interrupt pointer

	 mov	 ax,ds		; Get handler segment

	 xchg	 ax,[bp].CSI_HREF ; Get orginal SI value and set return segment

	 xchg	 ax,si		; Return SI to orginal value

	 xchg	 [bp].CSI_ODS,ax ; Get back orginal DS and set return offset

	 mov	 ds,ax		; Restore DS to orginal value
	 assume  ds:nothing	; Tell assembler

	 pop	 ax		; Restore AX...
	 pop	 bp		; and BP

	 xor	 ax,ax		; Clear because some DDs expect it

	 retf			; Transfer control to target
				; We don't expect to return
DIC_010:
	 assume  ds:RGROUP	; Tell assembler

	 pop	 ax		; Restore registers we aren't going to use anymore
	 pop	 bp		;

	 or	 RGROUP:[si].DH_TFLG,@INTR_FLG ; Set flag to avoid re-entrancy

	 mov	 DH_PTR.VOFF,si ; Save current device header pointer
	 mov	 DH_PTR.VSEG,ds ; ...

	 test	 DRV_FLAG,@DF_LAST ; Any target drivers to install?
	 jz	 short @F	; Yes, go
DIC_020:
	 call	 DECHAIN_LOADER ; Cut loader headers out of device chain

	 call	 DEV_CLEANUP	; Attempt device header cleanup

	 jmp	 DIC_EXIT	; Goto common exit
@@:
	 test	 LCL_FLAG,@LCL_INST ; Are we already installed?
	 jz	 short DIC_ERR	; No, go fail installation

	 call	 SAVE_INT12	; Set memsize back to pre-MAX time
	 call	 REST_INIT_END_VEC ; Restore to last value
	 call	 COMSEG 	; Copy target driver information
	 call	 DRVSPC_HOOK	; If appropriate, hook INT 2F/4A11/FFFC to lie

	 REGSAVE <bx,si,ds,bp>	; Save header pointer

; If the B2 flag was specified, we need to close high DOS.  The default
; state is to leave high DOS linked until INSTALL= time.
	 mov	 ax,5802h	; Get link state in AL
	 DOSCALL		; AL = link state
	 cbw			; Clear high byte
	 push	 ax		; Save for later

	 test	 CFGFLAGS,@CFG_CLOSEHI ; Should we close high DOS?
	 jz	 short @F	; Jump if not

	 sub	 bx,bx		; Close high DOS arena link
	 mov	 ax,@MACALG*100h + 03h ; Set link state to BX
	 DOSCALL		; Ignore error
@@:
	 mov	 si,RGROUP:[si].DH_THDR ; Get target header offset
	 mov	 ds,TARG_SEG	; Get the segment of the target header
	 assume  ds:nothing	; Tell assembler

	 push	 ds		; Push target interrupt handler ...
	 push	 ds:[si].DH_INTR ; address onto stack

	 mov	 bp,sp		; Set up index for call

	 xor	 ax,ax		; Clear because some DDs expect it

	 call	 [bp].EDD	; Call target interrupt

	 add	 sp,4		; Remove target call from stack

	 pop	 bx		; Get previous link state

	 push	 ax		; Save return value from interrupt procedure
	 mov	 ax,5803h	; Set link state to BX
	 DOSCALL		; Ignore error return
	 pop	 ax		; Restore return value

	 REGREST <bp,ds,si,bx>	; Restore pointer
	 assume  ds:RGROUP	; Tell assembler

	 call	 DRVSPC_UNHOOK	; If appropriate, unhook INT 2F/4A11/FFFC
	 call	 COMSEG 	; Copy again, just in case it changed
	 call	 SAVE_INIT_END_VEC ; Save driver's ending value
	 call	 REST_INT12	; Restore mem size

	 call	 INITIAL	; Go check the status of target driver init

	 jmp	 short DIC_EXIT ; Exit
DIC_ERR:
	 assume  ds:RGROUP	; Tell assembler

	 and	 RGROUP:[si].DH_ATTR,not DRV_ATTR_CHAR ; Ensure block device

	 mov	 RGROUP:[si].DH_NEXT.VOFF,-1 ; Last device in chain
	 mov	 RGROUP:[si].DH_NEXT.VSEG,-1 ; ...

	 lds	 si,RH_VEC	; Get request header pointer
	 assume  ds:nothing	; Tell assembler

	 xor	 ax,ax		; A convenient zero
	 mov	 ds:[si].INIT_END_VEC.VOFF,ax ; Set ending address
	 mov	 ds:[si].INIT_END_VEC.VSEG,RGROUP ; ...
	 mov	 ds:[si].INIT_UNITS,al ; No units defined
DIC_EXIT:
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell assembler

	 pop	 si		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DEV_INTR_COM endp		; End DEV_INTR_COM procedure
	NPPROC	DRVSPC_HOOK -- If Appropriate, Hook INT 2Fh/4A11/FFFC To Lie
	assume	ds:nothing,es:nothing,ss:nothing
COMMENT|

If appropriate, hook INT 2Fh/4A11/FFFC and lie

Appropriate means that

1.  @CFG_DRVSPC is specified, and
2.  GETSIZE

|

	REGSAVE <ax,bx,dx,ds,es> ; Save registers

	test	CFGFLAGS,@CFG_DRVSPC ; Time to lie?
	jz	short DRVSPC_HOOK_EXIT ; Jump if not

	test	OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	jz	short DRVSPC_HOOK_EXIT ; Jump if not

	push	cs		; Get our code segment
	pop	ds		; Address it for @SETINT
	assume	ds:PGROUP	; Tell the assembler about it

	mov	al,2Fh		; Intercept this one
	DOSCALL @GETINT 	; Return with ES:BX ==> old handler
	assume	es:nothing	; Tell the assembler about it

;;;;;;; mov	al,2Fh		; Intercept this one
	mov	OLDINT2F_VEC.VOFF,bx ; Save to restore later
	mov	OLDINT2F_VEC.VSEG,es ; ...

	DOSCALL @SETINT,LCL_INT2F ; Install our local handler
DRVSPC_HOOK_EXIT:
	REGREST <es,ds,dx,bx,ax> ; Restore
	assume	ds:nothing,es:nothing ; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,ss:nothing

DRVSPC_HOOK endp		; End DRVSPC_HOOK procedure
	NPPROC	DRVSPC_UNHOOK -- If Appropriate, Unhook INT 2Fh
	assume	ds:nothing,es:nothing,ss:nothing
COMMENT|

If appropriate, unhook INT 2Fh.

Appropriate means that

1.  @CFG_DRVSPC is specified, and
2.  GETSIZE

|

	REGSAVE <ax,dx,ds>	; Save registers

	test	CFGFLAGS,@CFG_DRVSPC ; Time to lie?
	jz	short DRVSPC_UNHOOK_EXIT ; Jump if not

	test	OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	jz	short DRVSPC_UNHOOK_EXIT ; Jump if not

	mov	al,2Fh		; Intercept this one
	lds	dx,OLDINT2F_VEC  ; Get original handler
	assume	ds:nothing	; Tell the assembler about it

	DOSCALL @SETINT 	 ; Restore original handler
DRVSPC_UNHOOK_EXIT:
	REGREST <ds,dx,ax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,ss:nothing

DRVSPC_UNHOOK endp		; End DRVSPC_UNHOOK procedure
	FPPROC	LCL_INT2F -- Local INT 2Fh Handler
	assume	ds:nothing,es:nothing,ss:nothing
COMMENT|

Local INT 2Fh handler.

Look for 4A11/FFFC/0000 and lie.

This is DRVSPACE.SYS loading low and checking for the resident
DBLSPACE.BIN's memory requirements to move it into high DOS memory.

If we find this to be the case, then

On entry to the next INT 2Fh handler

1.  Set CX to contain the # paras in this segment (from INIT_CMD_VEC
    tail), and

2.  Save DX in Temp, and

3.  Set DX to the caller's CS+4 (the constant 4 comes from the
    resident code size of DRVSPACE.SYS).

Upon return from the INT 2Fh handler,

1.  Set CX to CX+4+CS-Temp.  This has the effect of setting the
    resident size of DRVSPACE.SYS to its CS+4+resident size of
    DBLSPACE.BIN because the INT 2Fh caller has saved the incoming DX
    on the stack and adds the resulting CX to it to get the total
    resident size.

|

@DRVSPC_SIZ equ 4		; Size of DRVSPACE.SYS resident w/o DBLSPAC.BIN

	pushf			; Save flags in case someone does STC/INT 2Fh
				; to check for presence
	cmp	ax,4A11h	; Izit our function?
	jne	short INT2F_ORIG ; Jump if not

	cmp	bx,0FFFCh	; Izit our subfunction?
	jne	short INT2F_ORIG ; Jump if not

	cmp	cx,0		; Izit loading in low DOS?
	jne	short INT2F_ORIG ; Jump if not

	popf			; Restore

; Setup CX and DX as above

	mov	INT2F_TEMP,dx	; Save for later use

	mov	cx,DRVEND_VEC.VSEG ; Get the last segment
	sub	cx,TARG_SEG	; Less the segment of the target header
	sub	cx,@DRVSPC_SIZ	; Less resident size of DRVSPACE.SYS

	mov	dx,TARG_SEG	; Get the segment of the target header
	add	dx,@DRVSPC_SIZ	; Less resident size of DRVSPACE.SYS

; Put the caller's flags into effect

INT2F_STR struc

	dw	?		; Caller's BP
	dd	?		; ...	   CS:IP
INT2F_FL dw	?		; ...	   FL

INT2F_STR ends

	push	bp		; Prepare to address the stack
	mov	bp,sp		; Hello, Mr. Stack

	push	[bp].INT2F_FL	; Put flags onto stack
	popf			; Restore caller's IF

	pop	bp		; Restore

	pushf			; Simulate INT environment
	cli			; ...
	call	OLDINT2F_VEC	; Pass the request on down

; On return, setup CX as above

	add	cx,@DRVSPC_SIZ	; Less resident size of DRVSPACE.SYS
	add	cx,TARG_SEG	; Plus the segment of the target header
	sub	cx,INT2F_TEMP	; Less the original DX

	ret	2		; Return to caller, popping flags

INT2F_ORIG:
	popf			; Restore

	jmp	OLDINT2F_VEC	; Continue with next handler in sequence

	assume	ds:nothing,es:nothing,ss:nothing

LCL_INT2F endp			; End LCL_INT2F procedure
	 NPPROC  REST_INIT_END_VEC -- Restore Last INIT_END_VEC
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Restore last INIT_END_VEC before calling the driver.

|

	 REGSAVE <ax,bx,es>	; Save registers

	 les	 bx,RH_VEC	; Get request header pointer
	 assume  es:nothing	; Tell assembler

	 mov	 ax,DRVEND_VEC.VSEG ; Get the last segment
	 mov	 es:[bx].INIT_END_VEC.VSEG,ax ; Pass to the driver

	 mov	 ax,DRVEND_VEC.VOFF ; Get the last offset
	 mov	 es:[bx].INIT_END_VEC.VOFF,ax ; Pass to the driver

	 REGREST <es,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REST_INIT_END_VEC endp		; End REST_INIT_END_VEC procedure
	 NPPROC  SAVE_INIT_END_VEC -- Save INIT_END_VEC
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Save INIT_END_VEC after calling the driver.

|

	 REGSAVE <ax,bx,es>	; Save registers

	 les	 bx,RH_VEC	; Get request header pointer
	 assume  es:nothing	; Tell assembler

	 mov	 ax,es:[bx].INIT_END_VEC.VSEG ; Get the ending segment
	 mov	 DRVEND_VEC.VSEG,ax ; Save for the next time

	 mov	 ax,es:[bx].INIT_END_VEC.VOFF ; Get the ending offset
	 mov	 DRVEND_VEC.VOFF,ax ; Save for the next time

	 REGREST <es,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SAVE_INIT_END_VEC endp		; End SAVE_INIT_END_VEC procedure
	 NPPROC  DEV_CLEANUP -- Perform resident size reduction
	 assume  ds:RGROUP,es:nothing,ss:nothing
COMMENT|
	In an effort to reduce the resident size of the loader
	we are going to reuse the first header. To do this we must
	ensure that it is free and the target device is linked into
	the device chain.

Entry: DS:SI points to the current loader device header

|

	 REGSAVE <ax,bx,si,di,ds,es>  ;

	 lea	 di,DEVDRV0	; Get pointer to device header 0

	 test	 DRV_FLAG,@DF_FAIL ; Check for failed target driver -w- GETSIZE
	 jnz	 short DCU_070	; Target failed get out of here

	 test	 RGROUP:[di].DH_TFLG,@RLOC_FLG ; Is first header free?
	 jz	 short DCU_050	; No, go - we can't use it yet

	 cmp	 si,di		; Acting on the first device?
	 je	 short DCU_050	; Yea, go install this baby

	 cmp	 RGROUP:[si].DH_NEXT.VOFF,-1 ; Is last device flag set?
	 je	 short DCU_070	; Yes, we should be all done go

	 mov	 ax,di		; Get first device header offset
	 xchg	 ax,RGROUP:[si].DH_NEXT.VOFF ; Set/Get next device pointer

	 mov	 RGROUP:[di].DH_NEXT.VOFF,ax ; Set first header next offset
	 mov	 RGROUP:[di].DH_NEXT.VSEG,ds ; Set first header next segment
	 and	 RGROUP:[di].DH_TFLG,not (@STRA_FLG+@INTR_FLG) ; Clear flags
	 mov	 RGROUP:[di].DH_ATTR,DRV_ATTR_CHAR ; Mark as character device
	 mov	 RGROUP:[di+0].DH_NAME.ELO,'83' ; Set first two bytes of name
	 mov	 RGROUP:[di+2].DH_NAME.ELO,'L6' ;  "  next   "    "    "  "
	 mov	 RGROUP:[di+4].DH_NAME.ELO,'AO' ;  "  next   "    "    "  "
	 mov	 RGROUP:[di+6].DH_NAME.ELO,'$D' ;  "  last   "    "    "  "

	 mov	 di,ax		; Make addressable pointer to next device header
	 mov	 RGROUP:[di].DH_NEXT.VOFF,-1 ; Flag last device in chain
	 mov	 RGROUP:[di].DH_NEXT.VSEG,-1 ; ...

; Install a bogus unit so we can free/re-use header 0
DCU_050:
	 or	 RGROUP:[si].DH_TFLG,@STUB_FLG ; Set flag to bypass de-chain

	 les	 bx,RH_VEC	; Get request header pointer
	 assume  es:nothing	; Tell assembler

	 mov	 es:[bx].INIT_END_VEC.VOFF,0 ; Set ending offset in RH
	 mov	 ax,END_SEG	; Get ending segment
	 mov	 es:[bx].INIT_END_VEC.VSEG,ax ; Set ending segment in RH

	 cmp	 DOSVER,031Fh	; Izit DOS 3.31 or higher?
	 jnb	 short @F	; Jump if so

; Note:
; MS-Dos 3.3 for the AT&T 6300 has a bug that does not allow us to set the
; offset to 0 in the request header ending address field.  We set the
; offset to 10 and decrement the ending segment by one.
	 mov	 es:[bx].INIT_END_VEC.VOFF,10h ; Set ending offset in RH
	 dec	 ax		;
	 mov	 es:[bx].INIT_END_VEC.VSEG,ax ; Set ending segment in RH
@@:
	 jmp	 DCU_090  ; Join common exit

DCU_070:
	 and	 RGROUP:[si].DH_ATTR,not DRV_ATTR_CHAR ; Mark as block device

	 mov	 ax,EXEC_INTMAC ; Get pseudo-interrupt MAC segment
	 inc	 ax		; Account for MAC

; Fixup header strategy jump vector to point to the resident handler
	 lea	 si,LOW_STRA_COM ; Get pointer to resident jump vector
	 mov	 RGROUP:[si].FJ_ADDR.VSEG,ax
	 mov	 RGROUP:[si].FJ_ADDR.VOFF,offset PGROUP:RES_STRA_COM

; Fixup header interrupt jump vector to point to the resident handler
	 lea	 si,LOW_INTR_COM ; Get pointer to resident jump vector
	 mov	 RGROUP:[si].FJ_ADDR.VSEG,ax
	 mov	 RGROUP:[si].FJ_ADDR.VOFF,offset PGROUP:RES_INTR_COM

; Set device header so this device won't install

	 les	 bx,RH_VEC	; Get request header pointer
	 assume  es:nothing	; Tell assembler

	 xor	 ax,ax		; A convenient zero
	 mov	 es:[bx].INIT_UNITS,al ; No units defined

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jz	 short DCU_090	; No, exit

; Free our high dos allocation.  GETSIZE always puts the LSEG in low DOS.
	 mov	 ax,cs		; Get current PGROUP
	 dec	 ax		; Back off to MAC entry
	 cmp	 ax,POVR_MAC	; Izit in low DOS, or no high DOS at all?
	 jb	 short DCU_090	; Yes, so exit

	 mov	 es,ax		; Set up ES for MAC references
	 assume  es:nothing	; Tell assembler

	 mov	 es:[0].MAC_BACK,0 ; Clear previous entry
	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Mark as free
DCU_090:
	 REGREST <es,ds,di,si,bx,ax>  ;
	 assume  ds:nothing,es:nothing ; Tell assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DEV_CLEANUP endp		; End DEV_CLEANUP
	 NPPROC  CHKLSTLST -- Check the List Of List
	 assume  ds:RGROUP,es:nothing,ss:nothing
COMMENT|

 Check the List Of List to see if this driver has special meaning to DOS

Entry:
	DS:SI - points to driver we are working on
	ES:DI - points to target driver we are adding to device chain

Exit:
	List of Lists may be modified

 Note:
 The Console, Clock, and Block devices are treated in special
 ways by DOS.

 Console and Clock devices;
   The console and clock devices have magic pointers to there device
   drivers kept in the List Of Lists

 Block devices;
   DOS places a magic DPB at the end address that is reported by
   the device driver as the ending address after initialization.
   The placement of DPBs for nested devices is determined by the end
   address for the driver MAC.	As DOS installs devices it bumps the
   size of the driver by 32 bytes for ver 4 and below and 48 bytes for
   version 4 and above.
|
	 REGSAVE <ax,bx,cx,dx,si,di,es,ds> ; Save used registers

	 mov	 dx,es		; Save target driver segment for later

	 DOSCALL @GETLST	; Get List of List pointer in ES:BX
	 assume  es:nothing	; Notify assembler

	 mov	 ax,ds		; Get segment of current driver in AX

	 test	 ds:[si].DH_ATTR,DRV_ATTR_CHAR ; Is this a block device?
	 jz	 short CLL_ISBLOCK ; Yea, go handle it as such

; Handle LOL modification needed for clock device

	 cmp	 ax,es:[bx].LSTLST_CLK.VSEG ; Is it the same as the current clock?
	 jne	 short CLL_010	; Nope, go check console

	 cmp	 si,es:[bx].LSTLST_CLK.VOFF ; Is it the same as the current clock?
	 jne	 short CLL_010	; Nope, go check console

	 mov	 es:[bx].LSTLST_CLK.VSEG,dx ; Set the clock pointer ..
	 mov	 es:[bx].LSTLST_CLK.VOFF,di ; to the target address

	 jmp	 short CLL_015	; Goto common exit
CLL_010:
; Handle LOL modification needed for console device

	 cmp	 ax,es:[bx].LSTLST_CON.VSEG ; Is it the same as the current console?
	 jne	 short CLL_015	; Nope, go

	 cmp	 si,es:[bx].LSTLST_CON.VOFF ; Is it the same as the current console?
	 jne	 short CLL_015	; Nope, go

	 mov	 es:[bx].LSTLST_CON.VSEG,dx ; Set the console pointer ..
	 mov	 es:[bx].LSTLST_CON.VOFF,di ; to the target address
CLL_015:
	 jmp	 CLL_EXIT	; Goto common exit

CLL_ISBLOCK:
; Update our running total of block devices
	 mov	 al,ds:[si].DD_NAME[0] ; Get number of drives
	 add	 cBLOCKDEV,al	; Update total

; Handle DPB modification needed for block devices

	 les	 bx,es:[bx].LSTLST_DPB ; Get pointer to first DPB
CLL_NEXTDPB:
	 mov	 ax,ds		; Get driver segment in AX for later comparison

	 cmp	 DOSVER,0400h	; Izit DOS 4.x or later?
	 jae	 short CLL_DOS4DPB ; Yes, use the other DPB data structure

	 cmp	 es:[bx].DPB3_DDP.VOFF,si ; Is this DPB pointing to our offset?
	 jne	 short CLL_XDPB3 ; No, go

	 cmp	 es:[bx].DPB3_DDP.VSEG,ax ; Is this DPB pointing to our segment?
	 jne	 short CLL_XDPB3 ; No, go

	 mov	 ax,ds:[si].DH_THDR ; Get the target header offset
	 mov	 es:[bx].DPB3_DDP.VOFF,ax ; Set the device driver offset
	 mov	 ax,TARG_SEG	; Get the segment of the target header
	 mov	 es:[bx].DPB3_DDP.VSEG,ax ; Set the device driver segment

	 jmp	 CLL_DPBALLOC	; We are done patching this DPB; go around again

CLL_XDPB3:
	 les	 bx,es:[bx].DPB3_DPP ; Get the next DPB pointer
	 assume  es:nothing	; Tell assembler

	 jmp	 short CLL_DPBLOOP ; Go look at the new DPB

; We need to find our DPB and fix up the device pointer in it.
CLL_DOS4DPB:
	 cmp	 es:[bx].DPB4_DDP.VOFF,si ; Is this DPB pointing to our offset?
	 jne	 short CLL_XDPB4 ; Jump if not

	 cmp	 es:[bx].DPB4_DDP.VSEG,ax ; Is this DPB pointing to our segment?
	 jne	 short CLL_XDPB4 ; No, go

	 mov	 ax,ds:[si].DH_THDR ; Get the target header offset
	 mov	 es:[bx].DPB4_DDP.VOFF,ax ; Set the device driver offset
	 mov	 ax,TARG_SEG	; Get the segment of the target header
	 mov	 es:[bx].DPB4_DDP.VSEG,ax ; Set the device driver segment

	 jmp	 short CLL_DPBALLOC ; We are done patching this DPB; go around again

CLL_XDPB4:
	 les	 bx,es:[bx].DPB4_DPP ; Get the next DPB pointer
	 assume  es:nothing	; Tell assembler

CLL_DPBLOOP:
	 cmp	 bx,-1		; Is this the last DPB?
	 jne	 short CLL_NEXTDPB ; No, go test this one

; End of DPB chain.
	 pushf			; Save flags
	 cli			; Disallow interrupts

	 cmp	 DOSVER,0500h	; Izit DOS 5?
	 jae	 short CLL_XINT21 ; Jump if so - we aren't hooking Int 21

	 push	 ds		; Save

	 mov	 ax,EXEC_INTMAC ; Get the Int MAC segment
	 inc	 ax		; Bump to next paragraph
	 mov	 ds,ax		; Point DS to the relocatable segment
	 assume  ds:PGROUP	; Tell assembler a lie

	 lea	 ax,RES_INT21	; Get the offset of resident Int 21 handler
	 mov	 TMPINT21_VEC.VOFF,ax ; Set to launder Interrupt 21 calls
	 mov	 TMPINT21_VEC.VSEG,ds ;

	 inc	 UDDPB_CNT	; Increment unpatched DPB counter

	 pop	 ds		; Restore
	 assume  ds:RGROUP	; Tell assembler

CLL_XINT21:
	 popf			; Restore flags
	 jmp	 short CLL_EXIT ; Goto common exit

CLL_DPBALLOC:
	 REGSAVE <bx>		; Save DPB offset

	 add	 bx,16-1	; Round up to para boundary
	 mov	 cl,4-0 	; Paragraph to byte conversion factor
	 shr	 bx,cl		; Convert from bytes to paras
	 mov	 dx,es		; Get DPB segment
	 add	 dx,bx		; Add to it the para offset...
	 add	 dx,(size DPB4_STR+15) shr 4 ; and the size of the DPB

	 REGREST <bx>		; Restore DPB offset

	 UMAX	 END_SEG,dx	; Ensure we included the DPB in our size

	 jmp	 CLL_NEXTDPB	; Continue checking DPBs

CLL_EXIT:
	 REGREST <ds,es,di,si,dx,cx,bx,ax> ; Restore registers we used
	 assume  ds:nothing,es:nothing

	 ret
	 assume  ds:nothing,es:nothing,ss:nothing

CHKLSTLST endp			; End CHKLSTLST
	 NPPROC  DECHAIN_LOADER -- Cut loader headers out of device chain
	 assume  ds:RGROUP,es:nothing,ss:nothing
COMMENT|

 Search our internal device chain and remove initialized
 target devices.

Entry: DS:SI points to the current loader device header

|
	 REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save till exit

	 mov	 cx,@NEST	; Set loop count

	 xor	 bx,bx		; Zero index for header table
	 sub	 dx,dx		; Clear fixup counter
	 mov	 cBLOCKDEV,0	; Initialize total block count
DCL_010:
	 REGSAVE <bx>		; Save table index
	 mov	 si,DEVDRVTBL[bx] ; Get address of header from table

	 mov	 ax,ds		; Get loader header segment
	 cmp	 RGROUP:[si].DH_NEXT.VSEG,ax ; Is the previous driver in...
	 jne	 short DCL_070	; the same segment? No, go

	 cmp	 si,offset RGROUP:DEVDRV0 ; Is it the first header (a special case)
	 jne	 short DCL_020	; No, continue

	 test	 RGROUP:[si].DH_TFLG,@STUB_FLG ; Is this a stub?
	 jz	 short DCL_020	; No, continue

	 push	 ds		; Save header segment
	 pop	 es		; Get header segment in ES
	 mov	 di,si		; Get header offset in DI
@@:
	 les	 di,es:[di].DH_NEXT ; Get previous driver pointer
	 assume  es:nothing	; Tell assembler

	 mov	 bx,es		; Get segment of next device
	 cmp	 ax,bx		; Is this device in our segment?
	 je	 @B		; Yes, get another

	 mov	 RGROUP:[si].DH_NEXT.VOFF,di ; Set the DH_NEXT pointer ...
	 mov	 RGROUP:[si].DH_NEXT.VSEG,es ; to the dechained header

	 jmp	 short DCL_070	; Goto end of the loop
DCL_020:

	 test	 RGROUP:[si].DH_TFLG,@RLOC_FLG ; Have we done this before
	 jnz	 short DCL_070	; Yes, go

	 cmp	 RGROUP:[si].DH_NEXT.VOFF,si ; Is it before us?
	 ja	 short DCL_070	; No, go

	 REGSAVE <ds,si>	;

	 lds	 si,RGROUP:[si].DH_NEXT ; Get previous driver pointer
	 assume  ds:nothing	; Tell assembler

	 test	 ds:[si].DH_TFLG,@STUB_FLG ; Is this a stub header?
	 jnz	 short DCL_030	; Jump if so (note CF=0).  No need to link
				; driver into device chain.

	 or	 ds:[si].DH_TFLG,@RLOC_FLG ; Set flag so we don't do this again

	 mov	 di,ds:[si].DH_THDR ; Get target header address
	 mov	 es,TARG_SEG	; Get target device segment
	 assume  es:nothing	; Tell assembler

	 mov	 ax,ds:[si].DH_NEXT.VOFF ; Get the DH_NEXT pointer ...
	 mov	 es:[di].DH_NEXT.VOFF,ax ; from our ...
	 mov	 ax,ds:[si].DH_NEXT.VSEG ; local header and ...
	 mov	 es:[di].DH_NEXT.VSEG,ax ; put it in the targets.

	 call	 CHKLSTLST	; Check the List Of List to see if this..
				; driver has special meaning to DOS

	 inc	 dx		; Update count of drivers we fixed up

	 stc			; Set flag to cause internal header update
DCL_030:
	 REGREST <si,ds>	; Restore pointer to loader header
	 assume  ds:RGROUP	; Tell assembler

	 jnc	 short DCL_070	; If magic flag set goto the end of the loop

	 mov	 RGROUP:[si].DH_NEXT.VSEG,es ; Replace DH_NEXT in current device..
	 mov	 RGROUP:[si].DH_NEXT.VOFF,di ; with the target device header

DCL_070:
	 REGREST <bx>		; Restore index to driver table

	 add	 bx,type DEVDRVTBL ; Bump pointer

	 loop	 DCL_010	; Loop through the table

; Now that we've updated cBLOCKDEV with the total number of block devices
; we're adding, go looking for trouble...
	 or	 dx,dx		; Did we fix up any drivers?
	 jz	 short DCL_EXIT ; Jump if not

; Check for DOUBLESPACE.  Note that this is identical to the code
; in MSDOS.SYS we searched to get the offsets of DSBACK and friends,
; and that it's invoked for all resident drivers (character
; devices as well as block devices).  DOS 6 doesn't do this for us,
; as our last device terminates as a block device with 0 units.

	 push	 cs		; Get data segment
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 ax,DOSVER	; Get DOS version for comparison
	 cmp	 ax,0600h	; Izit DOS 6 with DoubleSpace?
	 jb	 short DCL_EXIT ; Jump if not

	 cmp	 ax,0602h	; Izit DOS 6.02 (which handles it properly)?
	 jnb	 short DCL_EXIT ; Jump if so

; Check for DoubleSpace in a state prior to "device=dblspace.sys /move"
; DoubleSpace may not be in CONFIG.SYS at all.	Both cases look the
; same, and we need to handle 'em both because DOS sure as hell won't.
	 mov	 ax,DSBACK_PTR.VSEG ; Get segment of back door call
	 or	 ax,DSBACK_PTR.VOFF ; Combine with offset
	 jz	 short DCL_EXIT ; Jump if we don't have the address

	 mov	 ax,4A11h	; DoubleSpace API
	 mov	 bx,0		; Function 0: get version
	 int	 2fh		; AX=0, CH=number of drives, DX=ver/flags
				; CL=drive letter (origin:'A')
	 or	 ax,ax		; Did it succeed?
	 jnz	 short DCL_EXIT ; Jump if not

;;;;;				; Stacker returns 'MD'
;;;;;	 cmp	 bx,'DM'        ; Izit Microsoft Dblspace?
;;;;;	 jne	 short DCL_EXIT ; Jump if not

	 cmp	 ch,1		; Izit using a drive letter?
	 jb	 short DCL_EXIT ; Jump if not

	 test	 dx,8000h	; Izit in its final location?
	 jnz	 short DCL_SWAPBLOCK ; Jump if not

; If the DBLSPACE_MOVED flag has already been set, do nothing.
; Otherwise, we need to update DOS's local logical drive count.
	 les	 bx,lpbDBLSPACE_MOVED ; Address DBLSPACE_MOVED flag in MSDOS.SYS
	 assume  es:nothing	; Tell the assembler

	 mov	 al,es:[bx].LO	; Get DBLSPACE_MOVED (0 if not moved yet)
	 inc	 al		; Was it FF?
	 jz	 short DCL_EXIT ; Jump if so (nothing to do)

	 mov	 es:[bx].LO,0ffh ; Set it so DOS doesn't do this again
	 les	 bx,lpbLOCAL_DRIVECOUNT ; Address local number of logical drives
	 assume  es:nothing	; Tell the assembler

	 add	 es:[bx].LO,ch	; Update it

	 jmp	 short DCL_EXIT ; Join common code

; To swap our block device with the temporary DBLSPACE designation,
; we need to call the far entry point at DSBACK_PTR with
; AH=55h
; AL=total number of block devices we've added (may be 0)
; BX=2
; CX=starting paragraph of free arena
; DX=number of paragraphs available

; I figured this out by tracing through the DOS 6 CONFIG.SYS
; device loader code.  It was later confirmed by talking to
; Chuck Strouss at Microsoft (206-936-3456).  They really
; don't expect anyone to need this call, but we don't have
; much choice...
DCL_SWAPBLOCK:
; Assume we're loading high
	 lea	 bx,GTAIL[(type DPB4_STR)+256+16-1] ; Address end, allowing
				; for DPB and some slop.
	 mov	 cl,4-0 	; Convert bytes to paras
	 shr	 bx,cl		; BX = additional paragraphs
	 add	 bx,seg PGROUP	; BX = Next available paragraph in low DOS

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jz	 short @F	; Jump if not

; Find the next paragraph not used by the client program
	 mov	 bx,EXEC_PRGMAC ; Get program MAC segment
	 add	 bx,RESPARA	; Plus # resident paras
	 add	 bx,1+1 	; Skip leading and trailing MAC entries
@@:
	 mov	 ah,55h 	; Magic cookie for this call
	 mov	 al,cBLOCKDEV	; Get total number of block devices
	 mov	 cx,bx		; Put in register for call
	 mov	 bx,2		; Function number (no range checking is done)
	 mov	 dx,TOPFILL	; End of arena (for all practical purposes)
	 sub	 dx,cx		; Get number of paras available for scratch
	 jc	 short DCL_EXIT ; Jump if no room (?)

	 call	 DSBACK_PTR	; Far call to DBLSPACE.BIN
				; Everything but BP is trashed

DCL_EXIT:
	 REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore used registers
	 assume  es:nothing	; Tell assembler

	 ret			; Back to caller
	 assume  ds:nothing,es:nothing,ss:nothing

DECHAIN_LOADER endp		; End DECHAIN_LOADER

CODE	 ends			; End CODE segment

CMDARG_MAC macro TXT,ACT
	 local	 LCL_TXT,LCL_LEN

SEG_TXT  segment byte public 'zdata' ; Start SEG_TXT segment
	 assume  ds:PGROUP

LCL_TXT  db	 TXT
LCL_LEN  equ	 $-LCL_TXT

SEG_TXT  ends			; End SEG_TXT segment


SEG_LEN  segment word public 'zdata' ; Start SEG_LEN segment
	 assume  ds:PGROUP

	 dw	 LCL_LEN

SEG_LEN  ends			; End SEG_LEN segment


SEG_TAB  segment word public 'zdata' ; Start SEG_TAB segment
	 assume  ds:PGROUP

	 dw	 PGROUP:LCL_TXT

SEG_TAB  ends			; End SEG_TAB segment


SEG_ACT  segment word public 'zdata' ; Start SEG_ACT segment
	 assume  ds:PGROUP

	 dw	 PGROUP:ACT

SEG_ACT  ends			; End SEG_ACT segment

	 endm			; CMDARG_MAC


SEG_TAB  segment word public 'zdata' ; Start SEG_TAB segment
	 assume  ds:PGROUP

	 public  CMDARG_TAB
CMDARG_TAB label word

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment word public 'zdata' ; Start SEG_LEN segment
	 assume  ds:PGROUP

	 public  CMDARG_LEN
CMDARG_LEN label word

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment word public 'zdata' ; Start SEG_ACT segment
	 assume  ds:PGROUP

	 public  CMDARG_ACT
CMDARG_ACT label word

SEG_ACT  ends			; End SEG_ACT segment


; All keywords in this table *MUST* be in uppercase

	 CMDARG_MAC 'DISPLAY', CMDCHK_DISPLAY
	 CMDARG_MAC 'GETSIZE', CMDCHK_GETSIZE
	 CMDARG_MAC 'GROUP',   CMDCHK_GROUP
	 CMDARG_MAC 'INT',     CMDCHK_INT
	 CMDARG_MAC 'DEVCNT',  CMDCHK_DEVS
if @OEM_SYS eq @OEMSYS_3COM
	 CMDARG_MAC 'PAUSE',   CMDCHK_PAUSE
else
	 CMDARG_MAC 'NOPAUSE', CMDCHK_NOPAUSE
endif				; IF @OEM_SYS eq @OEMSYS_3COM
	 CMDARG_MAC 'PRGREG',  CMDCHK_PRGREG
	 CMDARG_MAC 'PROG',    CMDCHK_PROG
	 CMDARG_MAC 'QUIET',   CMDCHK_QUIET
	 CMDARG_MAC 'SIZE',    CMDCHK_SIZE
if @OEM_FLEX
	 CMDARG_MAC 'FLEXFRAME',CMDCHK_FLEXFRAME
endif				; IF @OEM_FLEX
	 CMDARG_MAC 'VDS',     CMDCHK_VDS
	 CMDARG_MAC 'TERSE',   CMDCHK_TERSE
	 CMDARG_MAC 'VERBOSE', CMDCHK_VERBOSE

SEG_TAB  segment word public 'zdata' ; Start SEG_TAB segment
	 assume  ds:PGROUP

	 public  NCMDARGS
NCMDARGS equ	 ($-CMDARG_TAB)/(type CMDARG_TAB) ; Its length

SEG_TAB  ends			; End SEG_TAB segment

ADATA	 segment dword public 'zdata' ; Start ADATA segment
	 assume  ds:PGROUP

	 extrn	 AZS_XHI:byte
	 extrn	 AZS_UGHROOM:byte
	 extrn	 AZS_NOROOM:byte
	 extrn	 AZS_FILE:byte
	 extrn	 AZS_EXEC:byte
	 extrn	 @DCBYTE:abs

	 public  NEXTAVL
NEXTAVL  dw	 PGROUP:ZTAIL	; Next available byte

@MOD1_START equ  1000h		; Where to start searching MSDOS.SYS code
@MOD1_SEARCHLEN equ 4000h	; How far to search
	 public  DBLSP_MOD1
DBLSP_MOD1 label byte		; Start of DBLSPACE_MOVED search model
	 db	 2Eh,80h,3Eh	; CMP BYTE PTR CS:...
@DBLSP_MOVOFF equ $-DBLSP_MOD1	; Offset of offset of DBLSPACE_MOVED
	 db	 @DCBYTE,@DCBYTE,00h ; ... [DBLSPACE_MOVED],0
	 db	 75h,@DCBYTE	; JNE EXIT
	 db	 0B8h,11h,4Ah	; MOV AX,4A11h
	 db	 0BBh,00h,00h	; MOV BX,0
	 db	 0CDh,2Fh	; INT 2Fh
@DBLSP_MOD1LEN equ $-DBLSP_MOD1 ; Number of bytes to compare

				; OR AX,AX
				; JNZ EXIT
				; TEST DX,8000h
				; JNZ CALL_BACKDOOR

@MOD2_SEARCHLEN equ 200h	; How far to go past end of model 1
	 public  DBLSP_MOD2
DBLSP_MOD2 label byte		; Start of LOCAL_DRIVECOUNT search model
	 db	 2Eh,0C6h,06h,@DCBYTE,@DCBYTE,0FFh
				; MOV BYTE PTR CS:[DBLSPACE_MOVED],0FFh
	 db	 2Eh,00h,2Eh	; ADD BYTE PTR CS:...,
@DBLSP_COUNTOFF equ $-DBLSP_MOD2 ; Offset of offset of LOCAL_DRIVECOUNT
	 db	 @DCBYTE,@DCBYTE ; ... [LOCAL_DRIVECOUNT],CH
@DBLSP_MOD2LEN equ $-DBLSP_MOD2 ; Number of bytes to compare

; PC-DOS version:
	 public  DBLSP_MOD1B
DBLSP_MOD1B label byte		; Start of DBLSPACE_MOVED search model (PC-DOS)
	 db	 2Eh,0F6h,06h	; CMP BYTE PTR CS:...
@DBLSP_MOVOFFB equ $-DBLSP_MOD1B ; Offset of offset of DBLSPACE_MOVED
	 db	 @DCBYTE,@DCBYTE,01h ; ... [DBLSPACE_MOVED],01
	 db	 75h,@DCBYTE	; JNZ LABEL1
	 db	 0E8h,@DCBYTE,@DCBYTE ; CALLN xxxx
	 db	 75h,@DCBYTE	; JNZ LABEL2
	 db	 0F7h,0C2h,00h,80h ; TEST DX,8000h
	 db	 75h,@DCBYTE	; JNZ LABEL3
@DBLSP_MOD1BLEN equ $-DBLSP_MOD1B ; Number of bytes to compare

	 public  DBLSP_MOD2B
DBLSP_MOD2B label byte		; Start of LOCAL_DRIVECOUNT search model
	 db	 2Eh,00h,2Eh	; ADD BYTE PTR CS:
@DBLSP_COUNTOFFB equ $-DBLSP_MOD2B ; Offset of offset of LOCAL_DRIVECOUNT
	 db	 @DCBYTE,@DCBYTE ; ... [LOCAL_DRIVECOUNT],CH (383h in both)
	 db	 2Eh,0C6h,06h,@DCBYTE,@DCBYTE,01h
				; MOV BYTE PTR CS:[DBLSPACE_MOVED],01h
@DBLSP_MOD2BLEN equ $-DBLSP_MOD2B ; Bytes to compare

; From here on, they're identical...
				; JMP SHORT EXIT
				; PUSH ES
				; PUSH SI
				; MOV CX,CS:[364]
				; MOV DX,CS:[2A5]
				; SUB DX,CX

@MOD3_SEARCHLEN equ 200h	; How far to go past end of model 2
	 public  DBLSP_MOD3
DBLSP_MOD3 label byte		; DOS 6 DBLSPACE.BIN back door search model
	 db	 0BBh,02h,00h	; MOV BX,2
	 db	 2Eh,0A0h,@DCBYTE,@DCBYTE ; MOV AL,CS:[xxxx]
	 db	 0B4h,55h	; MOV AH,55
	 db	 2Eh,0FFh,1Eh	; CALL FAR DWORD PTR CS:...
@DBLSP_MOD3LEN equ $-DBLSP_MOD3 ; Number of bytes to compare

				; ... [387]
				; POP SI
				; POP ES
				; RET

ADATA	 ends			; End ADATA segment


ACODE	 segment byte public 'zdata' ; Start ACODE segment
	 assume  cs:PGROUP

	 extrn	 SKIP_WHITE:near
	 extrn	 FIND_BASE:near
	 extrn	 SKIP_FID:near
	 extrn	 CHECK_MEM:near
	 extrn	 SAVE_2324:near
	 extrn	 LOADSIZE:near
if @OEM_FLEX
	 extrn	 INST_EMS:near
	 extrn	 REST_EMS:near
	 extrn	 INST67:near
endif				; IF @OEM_FLEX
	 extrn	 FMT_CHG:near
	 extrn	 WAITFF:near

	 extrn	 FORCE_GETSIZE:near
	 extrn	 FCN_GETSIZE:near
	 extrn	 FCN_GROUP:near
	 extrn	 FCN_INT:near
	 extrn	 FCN_PRGREG:near
if @OEM_SYS ne @OEMSYS_3COM
	 extrn	 FCN_NOPAUSE:near
else
	 extrn	 FCN_PAUSE:near
endif				; IF @OEM_SYS ne @OEMSYS_3COM
	 extrn	 FCN_QUIET:near
	 extrn	 FCN_SIZE:near
if @OEM_FLEX
	 extrn	 FCN_FLEXFRAME:near
endif				; IF @OEM_FLEX
	 extrn	 DEC2BIN:near
	 extrn	 FCN_VDS:near
	 extrn	 CHECK_SETVER:near
	 extrn	 READCFG:near

	 NPPROC  FCN_DEVS -- Function to Handle DEVS=
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Function to handle DEVCNT=

On entry:

DS:SI	 ==>	 argument line

On exit:

DS:SI	 ==>	 (updated)
CF	 =	 1 if error
	 =	 0 otherwise

|

	 REGSAVE <ax,bx,dx>	; Save registers

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 lodsb			; Get next character

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_DEVS_ERR ; Too bad

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 call	 DEC2BIN	; Convert ASCII decimal digits at DS:SI to (DX,AX)
	 jc	 short FCN_DEVS_ERR ; Too large, so that's an error

; Ensure the value is within range

	 and	 dx,dx		; Ensure zero
	 jnz	 short FCN_DEVS_ERR ; Not so, so that's an error

	 cmp	 ax,@NEST-3	; Check against (abritrary) upper limit
	 jae	 short FCN_DEVS_ERR ; Too large, so that's an error

	 add	 ax,RES_HDRS	; Reserve some extra headers for De-chaining
	 cmp	 ax,MIN_HDRS	; This is the least number of header we can..
				; have for block devices
	 jae	 short @F	; We have enough go
	 mov	 ax,MIN_HDRS	; Set to min we can accept
@@:
	 mov	 bx,ax		; Move for table index
	 shl	 bx,1		; Set up for word access
	 mov	 ax,DEVDRVTBL[bx] ; Get the offset if the device headers
	 add	 ax,(16-1)	;
	 shr	 ax,1		;
	 shr	 ax,1		;
	 shr	 ax,1		;
	 shr	 ax,1		;
	 add	 ax,seg RGROUP	;
	 mov	 END_SEG,ax	;

	 clc			; Indicate all went well

	 jmp	 short FCN_DEVS_EXIT ; Join common exit code

FCN_DEVS_ERR:
	 stc			; Indicate something went wrong
FCN_DEVS_EXIT:
	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_DEVS endp		; End FCN_DEVS procedure
	 NPPROC  INIT_PARMS -- Initialize Parameters
	 assume  ds:PGROUP,es:nothing,ss:nothing

	 REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save registers

	 cld			; String ops forwardly

if @OEM_SYS eq @OEMSYS_3COM
	 or	 OPT_FLAG,@OPT_NOPAUSE ; No pause requested
endif				; IF @OEM_SYS eq @OEMSYS_3COM

	 push	 cs		; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP

; Check for arguments

	 lds	 si,PDEV_VEC	; DS:SI ==> argument line
	 assume  ds:nothing	; Tell the assembler about it

	 call	 SKIP_WHITE	; Skip over any intervening white space
	 mov	 PDEV_VEC.VOFF,si ; Save as start of device name
	 call	 SKIP_FID	; Skip over FID
				; returning DS:BX ==> filename.ext
				;	    DS:SI ==> next character after FID
				;	    AL = character after FID
	 mov	 PATH_END,bx	; Save as end of path

	 and	 al,al		; Check for zero
	 jnz	 short IP_ARGS_WHITE ; Not this time

	 inc	 si		; Skip over it
IP_ARGS_WHITE:
	 call	 SKIP_WHITE	; Skip over any intervening white space

	 lodsb			; Get next character

	 cmp	 al,CR		; Check for ending
	MJ e	 IP_ARGS_EXIT	; That's all folks

	 cmp	 al,LF		; Check for ending
	MJ e	 IP_ARGS_EXIT	; That's all folks

	 cmp	 al,EOF 	; Check for ending
	MJ e	 IP_ARGS_EXIT	; That's all folks

	 dec	 si		; Back off to last character

; Search for the argument text

	 xor	 bx,bx		; Zero index register
	 mov	 cx,NCMDARGS	; # arguments to check
CHECK_ARGS_NEXT:
	 mov	 di,CMDARG_TAB[bx] ; Get location of text

	 REGSAVE <cx,si>	; Save for a moment
	 mov	 cx,CMDARG_LEN[bx] ; Get length
    repe cmpsb			; Compare 'em

	 lodsb
	 REGREST <si,cx>	; Restore
	 jne	 short CHECK_ARGS_NEXT1 ; No match, get next one

	 cmp	 al,'/'         ; Check for valid separator
	 je	 short CHECK_ARGS_FOUND ; A match

	 cmp	 al,'='         ; Check for valid separator
	 je	 short CHECK_ARGS_FOUND ; A match

	 cmp	 al,';'         ; Check for a semicolon
	 je	 short CHECK_ARGS_FOUND ; A match

	 cmp	 al,' '         ; Check for blank or below
	 jbe	 short CHECK_ARGS_FOUND ; A match

CHECK_ARGS_NEXT1:
	 add	 bx,type CMDARG_TAB ; Skip to next entry

	 loop	 CHECK_ARGS_NEXT ; Jump if more entries to check

; Keyword not found

IP_ARGS_ERR0:
	 jmp	 IP_ARGS_ERR	; Join common error code

CHECK_ARGS_FOUND:
	 add	 si,CMDARG_LEN[bx] ; Skip over the keyword

	 jmp	 CMDARG_ACT[bx] ; Take appropriate action


	 public  CMDCHK_DISPLAY
CMDCHK_DISPLAY:
	 call	 DISP_COPY	; Display copyright notice
	 call	 FCN_DISPLAY	  ; Display the argument line

	 jmp	 short IP_ARGS_WHITE ; Go around again


	 public  CMDCHK_GETSIZE
CMDCHK_GETSIZE:
	 call	 FCN_GETSIZE	; Mark as GETSIZE specified

	 jmp	 short IP_ARGS_WHITE ; Go around again


	 public  CMDCHK_GROUP
CMDCHK_GROUP:
	 call	 FCN_GROUP	; Mark as GROUP= specified
	 jc	 short IP_ARGS_ERR0 ; Jump if error

	 jmp	 short IP_ARGS_WHITE ; Go around again


	 public  CMDCHK_INT
CMDCHK_INT:
	 call	 FCN_INT	; Mark as INT specified

	 jmp	 short IP_ARGS_WHITE ; Go around again


if @OEM_SYS ne @OEMSYS_3COM
	 public  CMDCHK_NOPAUSE
CMDCHK_NOPAUSE:
	 call	 FCN_NOPAUSE	; Mark as NOPAUSE specified

	 jmp	 short IP_ARGS_WHITE ; Go around again
else
	 public  CMDCHK_PAUSE
CMDCHK_PAUSE:
	 call	 FCN_PAUSE	; Mark as PAUSE specified

	 jmp	 short IP_ARGS_WHITE ; Go around again
endif				; IF @OEM_SYS ne @OEMSYS_3COM

	 public  CMDCHK_DEVS
CMDCHK_DEVS:
	 call	 FCN_DEVS	; Mark as DEVS= specified
	 jc	 short IP_ARGS_ERR0 ; Jump if error

	 jmp	 short IP_ARGS_WHITE ; Go around again


	 public  CMDCHK_PRGREG
CMDCHK_PRGREG:
	 call	 FCN_PRGREG	; Mark as PRGREG= specified
	 jc	 short IP_ARGS_ERR0 ; Jump if error

	 jmp	 short IP_ARGS_WHITE ; Go around again


	 public  CMDCHK_QUIET
CMDCHK_QUIET:
	 call	 FCN_QUIET	; Mark as QUIET specified

	 jmp	 IP_ARGS_WHITE ; Go around again


if @OEM_FLEX
	 public  CMDCHK_FLEXFRAME
CMDCHK_FLEXFRAME:
	 call	 FCN_FLEXFRAME	; Mark as FLEXFRAME specified

	 jmp	 IP_ARGS_WHITE	; Go around again
endif				; IF @OEM_FLEX


	 public  CMDCHK_SIZE
CMDCHK_SIZE:
	 call	 FCN_SIZE	; Mark as SIZE= specified
	 jc	 short IP_ARGS_ERR0 ; Jump if something went wrong

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_VDS
CMDCHK_VDS:
	 call	 FCN_VDS	; Mark as VDS specified
	 jc	 short IP_ARGS_ERR0 ; Jump if something went wrong

	 jmp	 IP_ARGS_WHITE	; Go around again

	 public  CMDCHK_TERSE
CMDCHK_TERSE:
	 mov	 MSG_COPY,0	; Ensure copyright notice won't get displayed
	 jmp	 IP_ARGS_WHITE	; Go around again

CMDCHK_VERBOSE:
	 call	 DISP_COPY	; Display copyright message
	 jmp	 IP_ARGS_WHITE	; Go around again

	 public  CMDCHK_PROG
CMDCHK_PROG:
	 or	 OPT_FLAG,@OPT_PROG ; Mark as specified

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 lodsb			; Get next character

	 cmp	 al,'='         ; Must be
	 jne	 short IP_ARGS_ERR0 ; Too bad

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 mov	 PFID_OFF,si	; Save address of PROG= argument

	 call	 SKIP_FID	; Skip over FID
				; returning DS:BX ==> filename.ext
				;	    DS:SI ==> next character after FID
				;	    AL = character after FID
	 mov	 PFID_NAM,bx	; Save for later use
	 mov	 cx,si		; Copy ending offset

	 sub	 cx,PFID_OFF	; AX = length of FID
	 jz	 short IP_ARGS_ERR ; Gotta specify something

	 mov	 PFID_LEN,cx	; Save for later use

; Copy the FID to local storage

	 lea	 di,LCL_FID	; ES:DI ==> local FID

	 push	 si		; Save for a moment
	 mov	 si,PFID_OFF	; DS:SI ==> start of FID
     rep movsb			; Copy to local storage
	 pop	 si		; Restore

	 mov	 PARG_VEC.VOFF,si ; Save address of arguments (if any)
	 mov	 PARG_VEC.VSEG,ds

	 call	 COPY_LSEG	; Copy device name/drive to LSEG.LSEG_FNE
IP_ARGS_P1:
	 lodsb			; Get next character

	 cmp	 al,LF		; Stop on LF
	 je	 short IP_ARGS_P2 ; That's all folks

	 cmp	 al,CR		; Stop on CR
	 jne	 short IP_ARGS_P1 ; Not yet
IP_ARGS_P2:
	 mov	 ax,si		; Copy offset
	 dec	 ax		; Back off to CR
	 sub	 ax,PARG_VEC.VOFF ; AX = length of ARG
	 jnz	 short IP_ARGS_EXIT ; Jump if something's there

; No arguments to the device driver to be loaded
; In order to be compatible with DOS 4.x, we *MUST* append a blank to
; the argument list as some programs (such as the IBM LAN Support Manager)
; expect it to be there.

	 push	 ds		; Get argument segment
	 pop	 es		; Address it here for MOVSB
	 assume  es:nothing	; Tell the assembler about it

	 lea	 cx,[si-1]	; CX = last char+1
	 mov	 si,PFID_OFF	; DS:SI ==> old start of argument
	 lea	 di,[si-1]	; ES:DI ==> new ...
	 sub	 cx,si		; CX = length of list
     rep movsb			; Move it down one
	 mov	 al,' '         ; Get a blank
	 stosb			; Insert it

; Account for the insertion

	 dec	 PFID_OFF	; Account for it
	 dec	 PARG_VEC.VOFF	; ...
	 dec	 PFID_NAM	; ...

	 jmp	 short IP_ARGS_EXIT ; Join common exit code

; All arguments processed -- ensure at least PROG= specified

IP_ARGS_EXIT:
	 test	 OPT_FLAG,@OPT_PROG ; Specified?
	 jz	 short IP_ARGS_ERR ; No, so that's an error

	 clc			; Indicate all went well

	 jmp	 short INIT_PARMS_EXIT ; Join common exit code

IP_ARGS_ERR:
	 call	 DISP_COPY	; Display copyright message
	 lea	 ax,AZS_ARGS	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 stc			; Indicate something went wrong

	 assume  ds:nothing	; Tell the assembler about it
INIT_PARMS_EXIT:
	 REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INIT_PARMS endp 		; End INIT_PARMS procedure
	 NPPROC  OPEN_FILE -- Open The File
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Open the file and save its handle and load size.  If it's a character
device and the name is PROTMAN$, set the @CFG_PROTMAN flag.  Also
set @CFG_TOPF and blast in a TOPFILL of 470.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

	 call	 SAVE_2324	; Save INTs 23h 24h and install our own handler

; Calculate the offset in LCL_FID of "filename.ext",0

	 call	 INST24 	; Install local INT 24h handler

; Check this "filename.ext",0 for presence in DOS 4.xx SETVER table

	 lea	 bx,LCL_FID	; Get offset of "d:\path\filename.ext",0

	 push	 bx		; Pass as argument
	 call	 CHECK_SETVER	; Check it, fill in XDOSVER if found

	 mov	 ax,PATH_END	; Get end of path in PDEV_VEC
	 sub	 ax,PDEV_VEC.VOFF ; Less start to get length

	 push	 PDEV_VEC.VSEG	; Pass segment of load path
	 push	 PDEV_VEC.VOFF	; Pass offset ...
	 push	 ax		; Pass length of ...
	 push	 bx		; Pass as argument
	 call	 READCFG	; Read configuration file,
				; look for a match with the specified file,
				; and set flags as appropriate

	 call	 REST24 	; Restore INT 24h handler

; If the file should be forced to be loaded low, tell the user not to
; use 386LOAD.

	 test	 LC2_FLAG,@LC2_XHILOAD ; Izit not to be loaded high?
	MJ nz	 OPEN_FILE_XHILOAD ; Jump if so

	 mov	 al,0		; Code for read-only access
	 DOSCALL @OPENF2,LCL_FID ; Open it
	MJ c	 OPEN_FILE_ERRMSG ; Something went wrong

	 mov	 bx,ax		; Copy to handle register

; Read in the file's header in case it's an .EXE file

	 mov	 cx,type EXE_STR ; # bytes to read in
	 DOSCALL @READF2,FILE_HEAD ; Read into local buffer
	MJ c	 OPEN_FILE_ERRCLOS ; Jump if something went wrong

; Seek to device header
	 sub	 ax,ax		; Assume it's a .COM format file
	 sub	 dx,dx		; ...

	 cmp	 FILE_HEAD.EXE_SIGN,@EXE_SIGN ; Izit an .EXE file?
	 je	 short @F	; Jump if so

	 cmp	 FILE_HEAD.EXE_SIGN,@EXE_SIG2 ; Izit an .EXE file?
	 jne	 short OPEN_FILE_XEXE ; Jump if it's a .COM file
@@:
	 mov	 ax,FILE_HEAD.EXE_HSIZ ; Get header size in paras
	 call	 PAR2BYT	; Convert to (DX,AX) in bytes
	 mov	 cx,dx		; High word
	 mov	 dx,ax		; Low word

OPEN_FILE_XEXE:
	 mov	 cx,ax		; CX:DX = offset of device header within file
	 mov	 al,0		; Code to move file pointer to offset
	 DOSCALL @MOVFP2	; Move file pointer by CX:DX as per AL
	 jc	 short OPEN_FILE_ERRCLOS ; Jump if something went wrong

; Read device header
	 push	 ds		; Get PGROUP segment
	 pop	 es		; Prepare to address PGROUP
	 assume  es:PGROUP	; Tell the assembler

	 mov	 cx,type DD_STR ; # bytes to read in
	 DOSCALL @READF2,TEMPSTK	; Read into local buffer
	 jc	 short OPEN_FILE_ERRCLOS ; Jump if something went wrong

	 test	 TEMPSTK.DD_ATTR,DRV_ATTR_CHAR ; Izit a character device?
	 jz	 short OPEN_FILE_XPROT ; Jump if not

	 lea	 si,PGROUP:TEMPSTK.DD_NAME ; Address name in device header
	 lea	 di,PGROUP:PROT_NAME ; Name to compare against

	 mov	 cx,8		; Number of bytes to compare
  repe	 cmps	 TEMPSTK[si].LO,PROT_NAME[di] ; Compare names
	 jne	 short OPEN_FILE_XPROT ; Jump if mismatch

;;;;;;;  or	 CFGFLAGS,(@CFG_TOPF or @CFG_PROTMAN) ; Mark as PROTMAN.DOS
	 or	 CFGFLAGS,@CFG_PTOPF ; Mark as PROTMAN.DOS
	 UMIN	 TOPFILL,<470*(1024/16)> ; Blast in TOPFILL 470
OPEN_FILE_XPROT:
; Determine the load size in bytes

	 xor	 cx,cx		; Set CX:DX to 0:0
	 xor	 dx,dx
	 mov	 al,2		; Code to move file pointer to EOF
	 DOSCALL @MOVFP2	; Move file pointer by CX:DX as per AL
	 jc	 short OPEN_FILE_ERRCLOS ; Jump if something went wrong

	 call	 LOADSIZE	; Get the load size

; If SIZE= not already specified, use load size as the amount of room

	 test	 OPT_FLAG,@OPT_SIZE ; Wuzit specified?
	 jnz	 short OPEN_FILE_SIZE ; Jump if so

	 mov	 ax,LSEG.LSEG_LSIZE.ELO ; Get the load size
	 mov	 dx,LSEG.LSEG_LSIZE.EHI

	 cmp	 dx,PFID_ROOM.EHI ; Check against room needed
	 jb	 short OPEN_FILE_SIZE ; Jump if within range
	 ja	 short @F	; Jump if SIZ is larger

	 cmp	 ax,PFID_ROOM.ELO ; Check against room needed
	 jbe	 short OPEN_FILE_SIZE ; Jump if within range
@@:
	 mov	 PFID_ROOM.ELO,ax ; Save as amount of room needed
	 mov	 PFID_ROOM.EHI,dx
OPEN_FILE_SIZE:
	 DOSCALL @CLOSF2	; Close it up, ignore error

	 clc			; Indicate all went well

	 jmp	 short OPEN_FILE_EXIT ; Join common exit code

OPEN_FILE_XHILOAD:
	 lea	 ax,AZS_XHILOAD ; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 jmp	 short OPEN_FILE_ERR ; Join common error code

OPEN_FILE_ERRCLOS:
	 DOSCALL @CLOSF2	; Close it up, ignore error
OPEN_FILE_ERRMSG:
	 lea	 ax,AZS_FILE	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message
OPEN_FILE_ERR:
	 stc			; Indicate something went wrong
OPEN_FILE_EXIT:
	 pushf			; Save CF
	 call	 REST_2324	; Restore old INTs 23h 24h
	 popf			; Restore

	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

OPEN_FILE endp			; End OPEN_FILE procedure
	 NPPROC HMALLOC -- Allocate High DOS memory
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

 Allocate High DOS memory

 Entry:
	BX allocation request (not counting the MAC)
 Exit:
	If carry set - allocation failed

	If no carry -
	AX = MAC segment of allocation


|
	 REGSAVE <bx,cx,dx,ds,es> ; Save

	 mov	 ax,POVR_MAC	; Get segment of first MAC in high DOS memory
	 cmp	 ax,-1		; Any high DOS memory?
	 jne	 short @F	; Yes, keep going

	 jmp	 short HMA_ERR	; Go to common error exit
@@:
	 mov	 es,ax		; Point to next entry
	 assume  es:nothing	; Tell the assembler about it

	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Add in # paragraphs in this entry

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Maybe it's a middle entry
	 jne	 short @F	; It isn't, so it must the last

	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Izit free?
	 jne	 short @B	; No, try again

	 cmp	 bx,es:[0].MAC_NPAR ; See if there's enough room
	 ja	 short @B	; Jump if not enough

	 jmp	 short HMA_COM	; Goto common
@@:
	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Izit free?
	 jne	 short HMA_ERR	; No, exit with error

	 cmp	 bx,es:[0].MAC_NPAR ; See if there's enough room
	 ja	 short HMA_ERR	; There isn't enough room

HMA_COM:
	 je	 short HMA_COM2 ; Jump if an exact fit (note CF=0)

; We need to split the block at ES:0 with the allocated portion at the
; high end of the region.  If UMBs do get allocated during GETSIZE, we
; want to ensure 386LOAD doesn't leave a hole beneath them.
	 mov	 cl,@MAC_MID	; Create a middle block
	 xchg	 cl,es:[0].MAC_TYPE ; Set it and get previous type
	 mov	 dx,es:[0].MAC_NPAR ; Get previous size
	 sub	 dx,bx		; DX = difference
	 dec	 dx		; Subtract MAC entry
	 mov	 es:[0].MAC_NPAR,dx ; Save length of free entry
	 mov	 ax,es		; Get starting segment
	 add	 dx,ax		; Skip to end of block
	 inc	 dx		; Skip MAC
	 mov	 es,dx		; Address new MAC entry
	 assume  es:nothing	; Tell the assembler

	 mov	 es:[0].MAC_TYPE,cl ; Mark as previous type
	 mov	 es:[0].MAC_NPAR,bx ; Size of our entry
	 mov	 es:[0].MAC_BACK,0 ; No LSEG back link

HMA_COM2:
	 mov	 ax,es		; Copy current segment
	 mov	 es:[0].MAC_OWNR,@MAC_TEMP ; Allocate an entry

	 clc			; Set no error flag

	 jmp	 short HMA_EXIT ; Goto common exit
HMA_ERR:
	 stc			; Set error flag
HMA_EXIT:
	 REGREST <es,ds,dx,cx,bx> ; Restore
	 assume  es:nothing	; Tell assembler

	 ret
	 assume  ds:nothing,es:nothing,ss:nothing

HMALLOC  endp			; End HMALLOC
	 NPPROC  MOVE_PRG -- Move the program to high DOS memory
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

	Copy the program into high DOS memory
Entry:
	AX - Destination MAC entry
	BX - Number of paragraphs to copy
	DS:0 - Program source

Exit:

|

	 REGSAVE <ax,bx,cx,di,si,es> ; Save used

	 cld			; Direction up

	 inc	 ax		; Account for MAC
	 mov	 es,ax		; Set ES to destination
	 assume  es:nothing	; Tell assembler

	 mov	 cl,4-1 	; Para to word conversion
	 shl	 bx,cl		; Convert BX to words
	 mov	 cx,bx		; Use it as a count

	 xor	 di,di		; Destination start at 0
	 xor	 si,si		; Source start at 0

	 rep movsw		; Move the program

	 REGREST <es,si,di,cx,bx,ax> ; Restore used

	 ret			; Return to caller
	 assume  ds:nothing,es:nothing,ss:nothing

MOVE_PRG endp			; End MOVE_PRG
	 NPPROC  FIND_MEM -- Find High DOS Memory
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Find high DOS memory into which we can fit the file.

If GETSIZE and high DOS is available, return to a copy
of 386LOAD in high DOS, leaving strategy and interrupt
stubs and LSEG low.

Note that we need to call REST2324 and REST67 on exit if
a (severe) error causes the low memory GETSIZE to fail,
since INST2324 and INST67 need to be called before moving
code high.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,es> ; Save registers

	 call	 RES_INTR_DEF	; Initialize defaults for RES_INTR_COM

	 lea	 ax,LSEG_TAIL[16-1] ; Get rounded offset of last byte in LSEG
	 cmp	 DOSVER,0500h	; Izit DOS 5?
	 jae	 short @F	; Jump if so

	 lea	 ax,LSEG_TAIL4[16-1] ; Get DOS 4 LSEG including Int 21 handler
@@:
	 mov	 cl,4		;
	 shr	 ax,cl		; Convert to paragraphs
	 inc	 ax		; Count in its MAC para
	 mov	 LSEG.LSEG_NPARA,ax ; Initialize LSEG allocation size
				; (including MAC para)

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	MJ nz	 FM_GETSIZE	; Yes

	 cmp	 POVR_MAC,-1	; Any high DOS memory?
	 jne	 short FM_HI	; Yea, keep going

	 test	 OPT_FLAG,@OPT_QUIET ; Should we be quiet?
	 jnz	 short @F	; Yes

	 lea	 ax,AZS_XHI	; Tell 'em the bad news
	 push	 ax		; Pass as argument
	 call	 DISP_ERRMSG	; Display an error message
@@:
	 call	 FORCE_GETSIZE	; Mark as if GETSIZE were specified

	 jmp	 FM_GETSIZE	; Join common GETSIZE code
FM_HI:
if @OEM_FLEX

; Allocate and map EMS memory so we have maximum amounts to find

	 call	 INST_EMS	; Install it
endif				; IF @OEM_FLEX
	 mov	 ax,PFID_ROOM.ELO ; Get the amount of room needed
	 mov	 dx,PFID_ROOM.EHI ; Get the amount of room needed
	 call	 BYT2PAR	; Convert (DX,AX) in bytes to AX in paras

	 mov	 bx,ax		; Copy to common register

; Find larger of BX and LSEG.LSEG_RPAR2

	 cmp	 bx,LSEG.LSEG_RPAR2 ; Is BX larger?
	 jae	 short @F	; Jump if so

	 mov	 bx,LSEG.LSEG_RPAR2 ; Use RPAR2
@@:

	 add	 bx,LSEG.LSEG_NPARA ; Add in the LSEG allocation including MAC

; Distinguish whether or not a region was specified

	 test	 OPT_FLAG,@OPT_PREG ; Program region specified?
	 jz	 short @F	; No

	 xor	 ch,ch		; Zero to use as word
	 mov	 cl,PRGREG	; Get program region #
	 call	 GETMEM_REG	; Ensure region CX has at least BX paras
				; returning AX=MAC entry
	MJ c	 FM_NOROOM	; Jump if error, code in AX

	 jmp	 short FM_ROOM	; There's enough room

@@:
	 call	 GETMEM_SRCH	; Find region with at least BX paras
				; returning AX = MAC entry, CX = region #
	MJ c	 FM_NOROOM	; Jump if error, code in AX

	 mov	 PRGREG,cl	; Save region #
FM_ROOM:
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 EXEC_INTMAC,ax ; Save as pseudo-interrupt MAC segment

	 mov	 bx,LSEG.LSEG_NPARA ; Get LSEG allocation size (including MAC)

	 call	 MOVE_PRG	; Move the LSEG into high memory

	 add	 ax,bx		; Add in the LSEG allocation

	 mov	 EXEC_PRGMAC,ax ; Save as program MAC segment
	 inc	 ax		; Count in MAC paragraph
	 mov	 EXEC_LOD,ax	; Save as load point...
	 mov	 EXEC_REL,ax	; and as relocation factor
	 mov	 TARG_SEG,ax	; Save segment of the target driver

	 mov	 es:[0].MAC_OWNR,ax ; Set the owner field for INT MAC

	 REGSAVE <ds>		; Save

	 mov	 ds,EXEC_PRGMAC ; Set DS to program MAC
	 assume  ds:nothing	; Tell assembler

	 mov	 bl,es:[0].MAC_TYPE ; Get 1st alloc mack type
	 mov	 ds:[0].MAC_TYPE,bl ; Copy it to second

	 mov	 es:[0].MAC_TYPE,@MAC_MID ; Mark 1st alloc as a mid entry

	 mov	 bx,LSEG.LSEG_NPARA ; Get LSEG allocation size (including MAC)
	 dec	 bx		; Count out its MAC para

	 xchg	 bx,es:[0].MAC_NPAR ; Set/Get block size
	 sub	 bx,es:[0].MAC_NPAR ; Subtract it from the total
	 dec	 bx		; Account for new MAC

	 mov	 ds:[0].MAC_NPAR,bx ; Save the amount free in 2nd alloc
	 mov	 EXEC_PRGNPAR,bx ; Save for later use

	 mov	 ds:[0].MAC_OWNR,ax ; Set ownership of program
	 mov	 ax,es		; Get LSEG MAC segment
	 inc	 ax		; Skip MAC to LSEG
	 mov	 ds:[0].MAC_BACK,ax ; Set back link in program MAC
	 xor	 ax,ax		;
	 mov	 es:[0].MAC_NAME[0].ELO,ax ; Clear name field
	 mov	 es:[0].MAC_NAME[2].ELO,ax ;
	 mov	 es:[0].MAC_NAME[4].ELO,ax ;
	 mov	 es:[0].MAC_NAME[6].ELO,ax ;
	 mov	 es:[0].MAC_BACK,ax    ; Clear LSEG back link
	 mov	 es:[0].MAC_DRV,al     ; Clear drive field

	 mov	 ds:[0].MAC_NAME[0].ELO,ax ; Clear name field
	 mov	 ds:[0].MAC_NAME[2].ELO,ax ;
	 mov	 ds:[0].MAC_NAME[4].ELO,ax ;
	 mov	 ds:[0].MAC_NAME[6].ELO,ax ;
	 mov	 ds:[0].MAC_DRV,al     ; Clear drive field

; The next few lines are to patch the variable used to transfer control
; to the target driver after the loader is out of the picture.
; Unfortunately we determined the segment address after we have already
; moved the information into high DOS so we fix it up now.
	 mov	 ax,EXEC_INTMAC ; Get the MAC segment of LSEG and stuff
	 inc	 ax		; Bypass MAC
	 push	 ax		; Save the high DOS LSEG segment

	 mov	 ax,TARG_SEG	; Get the segment of the target driver

	 pop	 es		; Set ES to touch LSEG data
	 assume  es:PGROUP	; Lie to assembler so we can touch..
				; the data we have mirrored in high DOS
	 mov	 es:TARG_SEG,ax ; Save segment of the target driver in ..
				; the LSEG segment variable TARG_SEG
	 assume  es:nothing	; Tell the assembler ES isn't really PGROUP

	 REGREST <ds>		; Restore data segment
	 assume  ds:PGROUP	; Tell assembler

	 clc			; Indicate all went well

	 jmp	 FM_EXIT	; Join common exit code

FM_NOROOM:
if @OEM_SYS ne @OEMSYS_3COM
	 test	 OPT_FLAG,@OPT_QUIET ; Should we be quiet?
	 jnz	 short @F	; Yes

	 cmp	 ax,@DOSERR_XMAC ; Izit a MAC error?
	 lea	 ax,AZS_ERRMAC	; Tell 'em the bad news
	 je	 short FM_NOROOM1 ; Jump if so

	 lea	 ax,AZS_NOROOM	; Tell 'em the bad news
FM_NOROOM1:
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message
@@:
endif				; IF @OEM_SYS ne @OEMSYS_3COM

if @OEM_FLEX
	 call	 REST_EMS	; De-allocate any EMS memory
endif				; IF @OEM_FLEX

	 call	 FORCE_GETSIZE	; Mark as if GETSIZE were specified

	 push	 POVR_MAC	; Get segment of first MAC in high DOS memory
	 call	 MAC_MERGE	; Merge adjacent free MACs
	 jnc	 short FM_GETSIZE ; Jump if there's no problem

	 lea	 ax,AZS_ERRMAC	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 jmp	 FM_ERRCOM	; Join common error code

FM_GETSIZE:
	 lea	 bx,GTAIL[16-1] ; Get offset beyond our program
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 bx,cl		; Convert from bytes to paras

	 mov	 EXEC_INTMAC,cs ; Save as pseudo-interrupt MAC segment
	 dec	 EXEC_INTMAC	; Bump it back as if there were a MAC

	 call	 HMALLOC	; Allocate program memory
	MJ c	 FM_ALL_LOW	; If we failed go

; Note that we don't want to put an LSEG in high DOS for GETSIZE, as
; this may force GETSIZE or (*gasp*) FLEXFRAME errors on subsequent programs...

	 mov	 dx,cs		; Get start of interrupt block
	 dec	 dx		; Back off to MAC entry
	 add	 dx,LSEG.LSEG_NPARA ; Add in interrupt block & its MAC entry
	 mov	 EXEC_PRGMAC,dx ; Save as program load segment

	 call	 MOVE_PRG	; Move program

	 inc	 ax		; Account for MAC

	 mov	 TMPINT21_VEC.VSEG,ax ; Fixup Int 21 handler segment

if @OEM_FLEX
	 REGSAVE <bx,es>	; Save

	 les	 bx,OLDINT67_PATCH ; Get patch address for previous handler
	 assume  es:nothing	; Tell the assembler

	 mov	 es:[bx+1].VSEG,ax ; Fix up segment of far jump immediate

	 REGREST <es,bx>	; Restore
	 assume  es:nothing	; Tell the assembler

endif				; if @OEM_FLEX
	 dec	 ax		;

	 REGSAVE <ds>		;

	 mov	 ds,DH_PTR.VSEG ; Get the segment of our headers
	 assume  ds:RGROUP	; Tell assembler

	 inc	 ax		; Account for MAC

	 mov	 LOW_STRA_COM.FJ_ADDR.VSEG,ax ; Fixup common strategy jump vector
	 mov	 LOW_INTR_COM.FJ_ADDR.VSEG,ax ; 	     interrupt

	 REGREST <ds>		; Restore
	 assume  ds:PGROUP	; Tell assembler

	 push	 ax		; Put our destination segment on stack
	 lea	 ax,FM_JMP_HI	;
	 push	 ax		; Put the offset of where we want to go on stack

	 retf			; Run code moved into high DOS memory
	 public FM_JMP_HI
FM_JMP_HI:
; We don't need to set up a MAC entry at EXEC_INTMAC, since that is
; within our own resident code.  We do set up a MAC entry at EXEC_PRGMAC...

	 mov	 ax,cs		; Change stack to reflect the new segment...
	 mov	 ss,ax		; that we are running in
	 assume  ss:nothing	; Tell assembler

	 mov	 ds,ax		; Reload DS to reflect new PGROUP addr
	 assume  ds:PGROUP	; Tell assembler

	 mov	 LSEGSEG,ax	; Fix up temporary LSEG segment
	 jmp	 short @F	; Join common code

FM_ALL_LOW:
;	 We depend on the fact that BX has the number of paragraphs
;	 needed by the loader

	 mov	 ax,cs		; Get our program segment
	 add	 ax,bx		; Add to it how much code we use
	 mov	 es,ax		; Save it as the program load point
	 assume  es:nothing	; Tell assembler

	 mov	 EXEC_PRGMAC,es ; Save as program MAC segment as our PGROUP

@@:
	 mov	 ax,LSEG.LSEG_LSIZE.ELO ; Get the load size
	 mov	 dx,LSEG.LSEG_LSIZE.EHI ; ...

	 mov	 PFID_ROOM.ELO,ax ; Ignore any SIZE= parameter
	 mov	 PFID_ROOM.EHI,dx ; ...

	 mov	 es,EXEC_PRGMAC ; Get our exec program MAC segment
	 assume  es:nothing	; Tell assembler

; Setup a pseudo-MAC entry for program to load in low DOS
	 mov	 ax,TOPFILL	; Get the last segment in this region

	 sub	 ax,EXEC_PRGMAC ; Subtract the MAC start segment
	 dec	 ax		; One less to account for MAC

	 mov	 es:[0].MAC_NPAR,ax ; Save as # available paras
	 mov	 EXEC_PRGNPAR,ax ; Save for later use

	 mov	 es:[0].MAC_TYPE,@MAC_END ; Mark as tail entry
	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Mark as available

	 and	 OPT_FLAG,not @OPT_PREG ; Mark as not specified

	 mov	 LSEG.LSEG_PREG,@NOTSPEC ; Mark as not specified

	 mov	 ax,es		; Copy current segment
	 inc	 ax		; Count in MAC paragraph
	 mov	 EXEC_LOD,ax	; Save as load point
	 mov	 EXEC_REL,ax	; and as relocation factor
	 mov	 TARG_SEG,ax	; Save segment of the target driver

	 clc			; Indicate all went well

	 jmp	 short FM_EXIT	; Join common exit code

FM_ERRCOM:
	 call	 REST_2324	; Restore old INTs 23h 24h
if @OEM_FLEX
; Restore INT 67h if intercepted

	 call	 REST67 	; Restore it

	 call	 REST_EMS	; De-allocate any EMS memory
endif				; IF @OEM_FLEX
	 stc			; Indicate something went wrong

FM_EXIT:
	 jc	 short FM_EXIT1 ; Jump if we failed

	 test	 LC2_FLAG,@LC2_XMAX ; Are we loading without MAX?
	 jnz	 short FM_EXIT1 ; Jump if so (note CF=0)

	 call	 LINK_TLSEG	; Link temporary LSEG at PGROUP:LSEG

	 clc			; Indicate success

FM_EXIT1:
	 REGREST <es,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FIND_MEM endp			; End FIND_MEM procedure
	 NPPROC  COPY_LSEG -- Copy Device Name to LSEG
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Copy device driver's filename.ext to LSEG and fill with trailing blanks.

|

	 REGSAVE <ax,cx,si,di,ds,es> ; Save registers

	 mov	 es,LSEGSEG	; Make LSEG addressable
	 assume  es:nothing	; Tell the assembler about it

	 lea	 di,LSEG.LSEG_FNE ; ES:DI ==> LSEG save area

	 lds	 cx,PARG_VEC	; DS:CX ==> end of "filename.ext"
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 si,PFID_NAM	; DS:SI ==> start of ...
	 sub	 cx,si		; Subtract to get length of ...

	 cmp	 cx,size LSEG_FNE ; Ensure no larger than the field
	 jbe	 short @F	; Jump if within range

	 mov	 cx,size LSEG_FNE ; Set to maximum size
@@:
	 push	 cx		; Save for a moment
     rep movsb			; Copy to LSEG
	 pop	 cx		; Restore

; Fill with trailing blanks

	 sub	 cx,size LSEG_FNE ; Less size of region
	 neg	 cx		; Negate to get size of tail
	 mov	 al,' '         ; Trailing filler
     rep stosb			; Fill it up

	 REGREST <es,ds,di,si,cx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

COPY_LSEG endp			; End COPY_LSEG procedure

	 NPPROC  CHK_DBLSPBACK -- Find back door to DBLSPACE.BIN
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

We need to search the caller's CS (presumably DOS's CONFIG.SYS code)
for a far call to DBLSPACE.BIN.  This call uses an undocumented API
to relocate the temporary unit used by DBLSPACE.SYS /Move.

We need it because DOS 6 doesn't handle nested devices where the
last one is not a block device.

On entry:
AX	 Caller's CS

|

	 REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save

	 mov	 es,ax		; Address target segment
	 assume  es:nothing	; Tell the assembler

	 push	 cs		; Prepare to address data
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler

	 cmp	 DOSVER,0600h	; Izit DOS 6?
	MJ b	 CDSB_EXIT	; Jump if not

	 mov	 ax,DSBACK_PTR.VSEG ; Get segment of back door call
	 or	 ax,DSBACK_PTR.VOFF ; Combine with offset
	MJ nz	 CDSB_EXIT	; Jump if we already have it

	 cld			; String ops forwardly

	 mov	 dx,@MOD1_SEARCHLEN ; Maximum bytes to search
	 mov	 cx,@DBLSP_MOD1LEN ; Length to match
	 mov	 di,@MOD1_START ; Starting offset
	 lea	 si,DBLSP_MOD1	; What to look for
	 call	 SEARCH_MODEL	; Check for code at ES:DI for CX bytes
	 jne	 short CDSB_PCDOS ; Jump if we didn't find it

; ES:DI ==> next byte after actual code.  Get offset of DBLSPACE_MOVED.
	 mov	 ax,es:[di-@DBLSP_MOD1LEN+@DBLSP_MOVOFF].ELO ; Get offset
	 mov	 lpbDBLSPACE_MOVED.VOFF,ax ; Save for later
	 mov	 lpbDBLSPACE_MOVED.VSEG,es ; ...

	 mov	 dx,@MOD2_SEARCHLEN ; Maximum bytes to search
	 mov	 cx,@DBLSP_MOD2LEN ; Length to match
	 lea	 si,DBLSP_MOD2	; What to look for
	 call	 SEARCH_MODEL	; Check for code at ES:DI for CX bytes
	 jne	 short CDSB_PCDOS ; Jump if no match

; ES:DI ==> next byte.	Get offset of LOCAL_DRIVECOUNT.
	 mov	 ax,es:[di-@DBLSP_MOD2LEN+@DBLSP_COUNTOFF].ELO ; Get offset
	 mov	 lpbLOCAL_DRIVECOUNT.VOFF,ax ; Save for later
	 mov	 lpbLOCAL_DRIVECOUNT.VSEG,es ; ...

CDSB_SRCH3:
	 mov	 dx,@MOD3_SEARCHLEN ; Maximum bytes to search
	 mov	 cx,@DBLSP_MOD3LEN ; Length to match
	 lea	 si,DBLSP_MOD3	; What to look for
	 call	 SEARCH_MODEL	; Check for code at ES:DI for CX bytes
	 jne	 short CDSB_EXIT ; Jump if no match

; ES:DI ==> next byte.	Get entry point for DBLSPACE.BIN's back door.
	 mov	 di,es:[di-@DBLSP_MOD3LEN+@DBLSP_MOD3LEN].ELO ; Get offset of far entry point
	 mov	 ax,es:[di].VOFF ; Get offset
	 mov	 DSBACK_PTR.VOFF,ax ; Save for later
	 mov	 ax,es:[di].VSEG ; Get segment
	 mov	 DSBACK_PTR.VSEG,ax ; Save
	 jmp	 short CDSB_EXIT ; Join common exit

CDSB_PCDOS:
; PC-DOS 6.10 uses the same DBLSPACE API for STACKER 3.1 (bundled) but
; the calling sequence is quite different.
	 mov	 dx,@MOD1_SEARCHLEN ; Maximum bytes to search
	 mov	 cx,@DBLSP_MOD1BLEN ; Length to match
	 mov	 di,@MOD1_START ; Starting offset
	 lea	 si,DBLSP_MOD1B ; What to look for
	 call	 SEARCH_MODEL	; Check for code at ES:DI for CX bytes
	 jne	 short CDSB_EXIT ; Jump if we didn't find it

; ES:DI ==> next byte after actual code.  Get offset of DBLSPACE_MOVED.
	 mov	 ax,es:[di-@DBLSP_MOD1BLEN+@DBLSP_MOVOFFB].ELO ; Get offset
	 mov	 lpbDBLSPACE_MOVED.VOFF,ax ; Save for later
	 mov	 lpbDBLSPACE_MOVED.VSEG,es ; ...

	 mov	 dx,@MOD2_SEARCHLEN ; Maximum bytes to search
	 mov	 cx,@DBLSP_MOD2BLEN ; Length to match
	 lea	 si,DBLSP_MOD2B ; What to look for
	 call	 SEARCH_MODEL	; Check for code at ES:DI for CX bytes
	 jne	 short CDSB_EXIT ; Jump if no match

; ES:DI ==> next byte.	Get offset of LOCAL_DRIVECOUNT.
	 mov	 ax,es:[di-@DBLSP_MOD2BLEN+@DBLSP_COUNTOFFB].ELO ; Get offset
	 mov	 lpbLOCAL_DRIVECOUNT.VOFF,ax ; Save for later
	 mov	 lpbLOCAL_DRIVECOUNT.VSEG,es ; ...

	 jmp	short CDSB_SRCH3 ; Search for part 3

CDSB_EXIT:
	 REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHK_DBLSPBACK endp		; End CHK_DBLSPBACK procedure

ACODE	 ends			; End ACODE segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 FILL_MEM:near
	 extrn	 LINK_LSEG:near
	 extrn	 GETSIZE:near
	 extrn	 PAR2BYT:near
	 extrn	 BYT2PAR:near
	 extrn	 NOLOAD_PRESS:near
	 extrn	 SET_EES:near
	 extrn	 LINK_TLSEG:near
	 extrn	 UNLINK_TLSEG:near
	 extrn	 SEARCH_MODEL:near
	 extrn	 CHECK_PATCH:near

	 public  OLDINT12
OLDINT12 dw	 ?		; Save area for old INT 12h value

	 NPPROC  SAVE_INT12 -- Save Current INT 12h and Restore Original
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Save current INT 12h value and restore

The transient portion of CONFIG.SYS lies below the original top
of DOS (prior to 386MAX/MOVE'EM being installed).  Some drivers
also use a transient area which they calculate as a fixed amount
below the current top of DOS (from INT 12h).  The two may conflict
if 386MAX/MOVE'EM has backfilled thus changing the current top of DOS
to 704KB or higher.  In order to avoid this conflict, during the
driver's initialization only, we force the DOS memory size value
back to the original value.

Also, some device drivers (such as DXMG0MOD.SYS) use INT 12h as
a upper limit for their storage and fail to install if they think
that their storage needs exceed that of DOS.

|

	 REGSAVE <ax,cx,ds>	; Save registers

	 mov	 ax,OLDDOS	; Get original memory size in paras

	 test	 LC2_FLAG,@LC2_I12 ; Izit top of DOS trick?
	 jz	 short @F	; Jump if not

	 mov	 ax,EXEC_PRGMAC ; Get program MAC segment
	 add	 ax,EXEC_PRGNPAR ; Plus # paras in the region
	 add	 ax,1+((1 shl (10-4))-1) ; Count in MAC entry and
				; round up to next 1KB
@@:
	 mov	 cl,10-4	; Shift amount between
	 shr	 ax,cl		; Convert from paras to 1KB

	 mov	 cx,seg BIOSDATA ; Get BIOS data segment
	 mov	 ds,cx		; Address it
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 test	 LC2_FLAG,@LC2_I12 ; Izit top of DOS trick?
	 jnz	 short SAVE_I12_SWAP ; Jump if so

	 cmp	 ax,MEMORY_SIZE ; Check against current value
	 jbe	 short @F	; Go if old value is lower or the same

	 mov	 ax,MEMORY_SIZE ; Get the current value it is lower than..
				; the original one we saved

@@:
	 test	 CFGFLAGS,@CFG_PROTMAN ; Izit PROTMAN or a kindred spirit?
	 jz	 short SAVE_I12_SWAP ; Jump if not

	 sub	 ax,I12_DELTA	; Back off to give PROTMAN space
	 jnc	 short SAVE_I12_SWAP ; Jump if underflow didn't occur

	 add	 ax,I12_DELTA	; Add it back in (this shouldn't happen!)
SAVE_I12_SWAP:
	 xchg	 ax,MEMORY_SIZE ; Swap with current memory size
	 mov	 OLDINT12,ax	; Save to restore later

	 REGREST <ds,cx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SAVE_INT12 endp 		; End SAVE_INT12 procedure
	 NPPROC  REST_INT12 -- Restore Previous INT 12h
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Restore previous value of INT 12h saved by SAVE_INT12.

|

	 REGSAVE <ax,ds>	; Save registers

	 mov	 ax,seg BIOSDATA ; Get BIOS data segment
	 mov	 ds,ax		; Address it
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 mov	 ax,OLDINT12	; Get previous memory size
	 mov	 MEMORY_SIZE,ax ; Swap with current memory size

	 REGREST <ds,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REST_INT12 endp 		; End REST_INT12 procedure
	 NPPROC  COMSEG -- Routine Common to ADDSEG & SUBSEG
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Copy the other device driver's header into our local area.

Entry:	 DS:SI points to our local extended header DH_STR

|
	 assume  ds:RGROUP,es:nothing,ss:nothing

	 REGSAVE <ax,bx,cx,si,di,ds,es> ; Save registers

	 cld			; String ops forwardly

	 mov	 di,RGROUP:[si].DH_THDR ; Get pointer to target header
	 mov	 es,TARG_SEG	; Get the segment of the target header
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es:[di].DH_ATTR ; Get target attribute word
	 mov	 RGROUP:[si].DH_ATTR,ax ; Copy attribute word

	 mov	 cx,@DH_NAME_LEN ; Length of the Dev Drv name field
	 xor	 bx,bx		; Index start at zero
@@:
	 mov	 al,es:[di+bx].DH_NAME ; Get character of target name
	 mov	 RGROUP:[si+bx].DH_NAME,al ; Copy character to our header
	 inc	 bx		; Bump index
	 loop	 @B		; Do next char of name

	 mov	 bx,es:[di].DH_NEXT.VOFF ; Get pointer to next target header
	 assume  es:nothing	; Tell assembler

	 lds	 si,RGROUP:[si].DH_NEXT ; Get pointer to next driver header
	 assume  ds:RGROUP	; Tell assembler

	 mov	 RGROUP:[si].DH_THDR,bx ; Save offset of next device

	 REGREST <es,ds,di,si,cx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

COMSEG	 endp			; End COMSEG procedure
	 NPPROC  INSTALL -- Device Driver Installation
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Installation routines.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

; Switch to local stack for INT 21h calls as the caller's might not
; be big enough

	 REGSAVE <ax,bp,ds>	; Save registers

	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 OLDSTK_VEC.VSEG,ss ; Save current stack segment
	 mov	 OLDSTK_VEC.VOFF,sp ;			& pointer

	 cli			; No interruptions

	 push	 cs		; Move CS
	 pop	 ss		; ... to SS
	 lea	 sp,TEMPSTKZ	; Address new stack

	 sti			; Restore interrupts

	 REGSAVE <bx,cx,dx,si,di,es> ; Save registers

	 and	 LCL_FLAG,not @LCL_TSR ; This is DRVLOAD, not TSRLOAD

; Save the address of the command line in case of error
; and clear the error bit in the status word

	 les	 di,RH_VEC	; ES:DI ==> request header
	 assume  es:nothing	; Tell the assembler about it

	 and	 es:[di].SRH_STA,not @BIT15 ; Clear error bit in status word

	 les	 di,es:[di].INIT_CMD_VEC ; ES:DI ==> argument line
	 assume  es:nothing	; Tell the assembler about it

	 mov	 PDEV_VEC.VOFF,di ; Save for later use
	 mov	 PDEV_VEC.VSEG,es

	 call	 INIT_PARMS	; Initialize parameters
	MJ c	 ERR_EXIT	; Exit on error

	 test	 OPT_FLAG,@OPT_INTR ; INT specified?
	 jz	 short INSTALL_XINT ; Not this time

	 int	 03h		; Call debugger
INSTALL_XINT:
	 call	 FIND_BASE	; Ensure base program is loaded
	 jnc	 short @F	; Keep going if no error

	 or	 LC2_FLAG,@LC2_XMAX ; Install target in low DOS
@@:
	 cmp	 DOSVER,0500h	; Izit DOS 5.00 or above?
	 jb	 short INS_030	; Nope, go

	 les	 bx,RH_VEC	; Get command packet pointer
	 assume  es:nothing	; Tell assembler

	 mov	 ax,es:[bx].INIT_END_VEC.VSEG ; Get ending segment

	 UMIN	 TOPFILL,ax	; Set New TOPFILL value
	 mov	 cl,10-4	; Convert from paras to K
	 shr	 ax,cl		; AX = Int 12h value to set
	 mov	 bx,ax		; Save
	 int	 12h		; AX = current Int 12h value
	 sub	 ax,bx		; AX = amount to subtract
	 jc	 short INS_060	; Underflow occurred - bail out & use default

	 mov	 I12_DELTA,ax	; Save for use in SAVE_INT12
	 jmp	 short INS_060	; Go do installation

INS_030:
	 cmp	 DOSVER,031Fh	; Izit DOS 3.31?
	 jne	 short INS_050	; Nope, bypass DR DOS check

	 mov	 al,52h 	; DR DOS version subfunction
	 DOSCALL @IOCTL2	; Perform an IO CTL call
	 jc	 short INS_050	; Did it work? Nope, bypass DR DOS check

	 and	 ax,@NIB3 or @NIB2 or @NIB1 ; Mask off unwanted lower nybble
	 cmp	 ax,01060h	; Is it a version of DRDOS?
	 jne	 short INS_050	; No, go

	 UMIN	 TOPFILL,08000h ; Set New TOPFILL value for DRDOS.
	 jmp	 short INS_060	; Go do installation

;----------------------------------------------------------------------------
;
; The code below was suggested by Digital Research, but
; when I traced through the code there were no MAC entries
; where they said there were.  I left this in for reference. RAD 6-11-92
;
;	  mov	  bx,seg RGROUP-1 ; Get our program MAC segment
;
;	 cmp	 ax,@DRVER6	; Is it DRDOS 6?
;	 jne	 short @F	; No, go
;
;	  dec	  bx		 ; DRDOS 6 the MAC is two paras back
;	 jmp	 short INS_040	; Go check MAC
;@@:
;	 cmp	 ax,@DRVER5	; Is it DRDOS 5?
;	 jne	 short INS_050	; No, go
;INS_040:
;	  mov	  es,bx 	 ; Set up ES to address MAC
;	  assume  es:nothing	 ; Tell assembler
;
;	  cmp	  es:[0].MAC_TYPE,@MAC_MID ; Is it a mid MAC?
;	 jne	 short @F	; Yes, go
;
;	  cmp	  es:[0].MAC_TYPE,@MAC_END ; Is it an end MAC?
;	 jne	 short INS_050	; No, go
;@@:
;	  mov	  ax,ds 	 ; Get region base segment
;	  add	  ax,es:[0].MAC_NPAR ; Add in the size of region
;
;	 UMIN	 TOPFILL,ax	; Set New TOPFILL value
;
;	 jmp	 short INS_060	; Go do installation
;----------------------------------------------------------------------------
INS_050:
	 mov	 ax,PDEV_VEC.VSEG ; Get segment of caller's transient code

	 sub	 ax,1800h	; Less 96KB for good measure

	 UMIN	 TOPFILL,ax	; Set default TOPFILL value
INS_060:
	 call	 TOPFILL_CHECK	; Do common TOPFILL size check

	 mov	 ax,POVR_MAC	; Get segment of first MAC in high DOS memory

	 cmp	 ax,-1		; Check for high DOS memory
	 je	 short @F	; None this time, maybe in low DOS memory

	 push	 ax		; Merge starting at this segment
	 call	 MAC_MERGE	; Merge adjacent free MACs
	 jc	 ERRMAC_EXIT	; Exit on error
@@:
	 call	 OPEN_FILE	; Open the PROG= file
	 jc	 ERR_EXIT	; Exit on error

	 call	 INSTALL_LOW	; If we're installing without MAX and it's
				; not PROTMAN  we're loading, don't return

if @OEM_FLEX

; Install INT 67h handler if appropriate

	 call	 INST67 	; Install it
endif				; IF @OEM_FLEX

; Install our own INT 23h and 24h handlers

	 call	 SAVE_2324	; Save INTs 23h 24h and install our own handler

	 call	 FIND_MEM	; Find high DOS memory
	 jc	 ERR_EXIT2	; Exit on error

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jz	 short @F	; No, load the program into high DOS

	 call	 LOADLOW	; Attempt to load in low memory
	 jnc	 NORM_EXIT	; All went well

	 jmp	 short ERR_EXIT ; Exit on error
@@:
	 call	 LOADHI 	; Load the file into memory
	 jnc	 NORM_EXIT	; All went well

	 jmp	 short ERR_EXIT ; Exit on error

ERRMAC_EXIT:
	 lea	 ax,AZS_ERRMAC	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message
ERR_EXIT:
; Our temporary LSEG may have been hooked up in FIND_MEM.  Unhook it now.

	 test	 LC2_FLAG,@LC2_XMAX ; Is MAX present?
	 jnz	 short ERR_EXIT2 ; Jump if not

	 call	 UNLINK_TLSEG	; Unlink temporary LSEG

ERR_EXIT2:
	 lea	 ax,AZS_NOLOAD	; The load failed, no hope
	 call	 NOLOAD_PRESS	; Call common NOLOAD and PRESS routines

	 stc			; Indicate something went wrong

	 jmp	 short EXIT	; Join common exit code

NORM_EXIT:
	 or	 LCL_FLAG,@LCL_INST ; Mark as installed
if @OEM_FLEX
	 call	 CLEAR_EMSPTE	; Clear accessed bit in page frame PTEs
;;;;;;;  and	 LCL_FLAG,not @LCL_XFLEX ; Clear Int 67h called flag
endif				; IF @OEM_FLEX

	 les	 di,RH_VEC	; ES:DI ==> request header
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,PFID_OFF	; Get offset of file id
	 mov	 es:[di].INIT_CMD_VEC.VOFF,ax ; Place it in command offset

	 clc			; Indicate all went well
EXIT:
	 REGREST <es,di,si,dx,cx,bx> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

; Switch back to caller's stack

	 mov	 ax,OLDSTK_VEC.VOFF ; Get & save old stack offset
	 mov	 ss,OLDSTK_VEC.VSEG ; Restore old stack segment
	 assume  ss:nothing	; Tell the assembler about it
	 mov	 sp,ax		; Restore old stack offset

	 REGREST <ds,bp,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INSTALL  endp			; End INSTALL procedure
	 NPPROC  LOADLOW - Load File Into Low DOS Memory
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Load the file into low DOS memory.

|

	 REGSAVE <ax,bx,dx,es>	; Save registers

	 push	 cs		; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

; Fill memory with a pattern following EXEC_PRGMAC

	 call	 FILL_MEM	; Fill it up

; From this point on, the memory above GTAIL is invalid.

	 lea	 bx,EXEC_BLK	; ES:BX ==> EXEC call parameter block
	 mov	 al,03h 	; Code to load but not execute
	 DOSCALL @EXEC,LCL_FID	; Load into high DOS memory
	 pushf			; Save flags for a moment
	 call	 REST_2324	; Restore old INTs 23h 24h
	 popf			; Restore flags
	 jnc	 short LOADLOW_OK ; Jump if it loaded correctly

	 lea	 ax,AZS_EXEC	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 stc			; Indicate something went wrong
	 jmp	 short LOADLOW_EXIT ; Join common error code

LOADLOW_OK:
; Apply any patches indicated by Fn flag in 386LOAD.CFG
	 call	 CHECK_PATCH	; Patch code at EXEC_LOD

	 cmp	 DOSVER,0500h	; Izit DOS 5.x or later?
	 jae	 short LOADLOW_DOS5 ; Jump if so

	 mov	 al,21h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT21_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT21_VEC.VSEG,es ; ...

	 push	 ds		; Save
	 mov	 ax,EXEC_INTMAC ; Get the Int MAC segment
	 inc	 ax		; Bump to next paragraph
	 mov	 ds,ax		; Point DS to the relocatable segment
	 assume  ds:nothing	; Tell assembler

	 mov	 al,21h 	; Intercept this one
	 DOSCALL @SETINT,INT21	; Install our local handler

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell assembler
LOADLOW_DOS5:

; Fill in EXEC_PSP for DOS 5.x SET_EES call

	 DOSCALL @GETPS0	; Return with segment # of PSP in BX
	 mov	 EXEC_PSP,bx	; Save for later use

; Set ending address

	 mov	 ax,EXEC_PRGMAC ; Get program MAC segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,EXEC_PRGNPAR ; Plus # paras in the region

	 les	 bx,RH_VEC	; ES:BX ==> request header
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[bx].INIT_END_VEC.VSEG,ax ; Save ending segment
	 mov	 es:[bx].INIT_END_VEC.VOFF,0  ; ...	    offset

	 mov	 DRVEND_VEC.VSEG,ax ; Save for later use
;;;;;;;; mov	 DRVEND_VEC.VOFF,0 ; ... (already done)

	 clc			; Indicate all went well

LOADLOW_EXIT:
	 REGREST <es,dx,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LOADLOW  endp			; End LOADLOW procedure
	 NPPROC INSTALL_LOW - Load target driver on top of loader
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

 This routine is always called.  If 386MAX driver was not found,
 it will load the target driver into low DOS over top of the loader.
 This is accomplished by moving to the top of low DOS (-64K)
 reading the target driver into the segment of RGROUP, and calling
 the target strategy routine before returning to DOS.

 To further complicate matters, if the program we're loading
 is flagged as a 'P' driver (PROTMAN.DOS), we need to act as
 if GETSIZE were specified, then return to the caller.	This
 is needed so we can doctor the Int 12h value around PROTMAN.

 We'll also do this if any patches are specified with the
 386LOAD.CFG Fn flag.  One patch in particular is needed for
 the TNDIS.DOS driver in precisely this case (loading it low
 without MAX in the system).

|
DR_STK_STR struc

	 dw	 ?		; Saved AX
	 dw	 ?		; Saved BP
	 dw	 ?		; Saved DS
	 dw	 ?		; Call to INSTALL_LOW
	 dw	 ?		; Saved DS
	 dw	 ?		; Saved SI
RETADDR  dd	 ?		; DOS Return address

DR_STK_STR ends 		; End DR_STK_STR

DR_CALL_STR struc

DR_OVER  db	 ?		; CS overide
DR_FCALL dw	 ?		; Far call DWord
DR_CVEC  dw	 ?		; Address of Dword

DR_CALL_STR ends		; End DR_CALL_STR

LCL_STR  struc			; Stack orientation for INSTALL_LOW

LEXEC_BLK    dd  ?		; Exec block
LRH_VEC      dd  ?		; Request header
LOLDSTK1_VEC dd  ?		; Old stack pointer
LDD_STRA_VEC dd  ?		; Low memory strategy routine
LHICODE_VEC  dd  ?		; High memory code vector

LCL_STR  ends			; End LCL_STR

	 test	 LC2_FLAG,@LC2_XMAX ; Are we loading without MAX?
	 jz	 short LOW_END0 ; Return to caller if not

if @OEM_SYS eq @OEMSYS_3COM
	 or	 LCL_FLAG,@LCL_DISP ; Mark as displayed
endif				; IF @OEM_SYS eq @OEMSYS_3COM

	 lea	 ax,AZS_XMAXLOW ; The load failed, no hope
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

; If the Int 12h value needs doctoring, we need to join the
; code for loading a driver low without high DOS available
	 test	 CFGFLAGS,@CFG_PROTMAN ; Izit PROTMAN.DOS?
	 jnz	 short @F	; Continue if not

	 test	 PATCHFLAGS,0FFFFh ; Are any patches specified?
	 jz	 short LOW_OVERLAY ; Jump if not

@@:
	 int	 12h		; Return memory size in AX
	 mov	 cl,10-4	; Kbytes to paras
	 shl	 ax,cl		; Size of low DOS in paras
	 mov	 OLDDOS,ax	; This is normally filled in by MAX
LOW_END0:
	 jmp	 LOW_END	; Return to caller

LOW_OVERLAY:
; Calculate new stack segment

	 mov	 ax,RH_VEC.VSEG ; Get segment of request header
	 sub	 ax,128*(1024 shr (4-0)) ; Back off by 128 KB in paras

	 mov	 bx,sp		; Copy old stack pointer

	 cli			; We can't affort an interrupt right now
	 mov	 ss,ax		; Set as new stack segment
	 mov	 sp,0		; Use top of stack
	 sti			; Restore interrupts; the stack is vaild

; Make room for local variables on the stack

	 sub	 sp,size LCL_STR ; Make room
	 mov	 bp,sp		; Address it via BP

; Save local variables in the stack

	 mov	 ax,OLDSTK_VEC.VOFF ; Get old stack offset
	 mov	 [bp].LOLDSTK1_VEC.VOFF,ax ; Save as local variable

	 mov	 ax,OLDSTK_VEC.VSEG ; Get old stack segment
	 mov	 [bp].LOLDSTK1_VEC.VSEG,ax ; Save as local variable

	 mov	 ax,seg RGROUP	; Get the segment of the device headers
	 mov	 [bp].LEXEC_BLK.LOADOVL_SEG,ax ; Load point is on top of us
	 mov	 [bp].LEXEC_BLK.LOADOVL_REL,ax ; Same as load point

; Adjust the command line offset

	 les	 di,RH_VEC	; Get pointer to request header
	 assume  es:nothing	; Tell the assembler about it

	 mov	 [bp].LRH_VEC.VOFF,di ; Save as local variable
	 mov	 [bp].LRH_VEC.VSEG,es

	 mov	 ax,PFID_OFF	; Get PROG= offset
	 mov	 es:[di].INIT_CMD_VEC.VOFF,ax ; Save in request header

; Make room for code in the stack

	 push	 ss		; Setup ES for stack references
	 pop	 es		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 lea	 cx,LOW_END	; Get ending offset
	 lea	 si,LOW_START	; DS:SI ==> source
	 sub	 cx,si		; Less start = # bytes to move
	 sub	 sp,cx		; Make room on stack
	 mov	 di,sp		; ES:DI ==> destination

	 mov	 [bp].LHICODE_VEC.VSEG,ss ; Save high memory code segment
	 mov	 [bp].LHICODE_VEC.VOFF,di ; ... 		  offset

	 cld			; Direction up

     rep movs	 es:[di].LO,ds:[si].LO ; Copy code to stack

; Copy old stack to new stack

	 mov	 si,bx		; DS:SI ==> start of old stack
	 lea	 cx,TEMPSTKZ	; Address end of old stack
	 sub	 cx,si		; Less start = # bytes to move
	 sub	 sp,cx		; Make room on stack
	 mov	 di,sp		; ES:DI ==> destination
     rep movs	 es:[di].LO,ds:[si].LO ; Copy old stack to new stack

	 jmp	 [bp].LHICODE_VEC ; Jump to code in the stack

LOW_START:

; Load the file into low memory

	 lea	 bx,[bp].LEXEC_BLK ; ES:BX ==> EXEC call parameter block
	 mov	 al,03h 	; Code to load but not execute
	 DOSCALL @EXEC,LCL_FID	; Load into low DOS memory
	 jc	 short LOW_ERR	; Jump if error

; Note we use the strategy obtained from the original file

	 mov	 ds,[bp].LEXEC_BLK.VSEG ; Get segment of device headers
	 assume  ds:RGROUP	; Tell assembler

	 mov	 ax,DEVDRV0.DH_STRA ; Get strategy offset
	 mov	 [bp].LDD_STRA_VEC.VSEG,ds ; Save low memory segment
	 mov	 [bp].LDD_STRA_VEC.VOFF,ax ; ...and offset

	 les	 bx,[bp].LRH_VEC ; ES:BX ==> request header
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ds,[bp].LDD_STRA_VEC.VSEG ; Setup DS for strategy routine
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 ax,ax		; Clear because some DDs expect it
	 call	 [bp].LDD_STRA_VEC ; Call strategy routine

	 jmp	 short LOW_EXIT ; Join common exit code

	 assume  ds:PGROUP	; Tell assembler
LOW_ERR:
	 les	 bx,[bp].LRH_VEC ; ES:BX ==> request header
	 assume  es:nothing	; Tell the assembler about it

	 STATUS  DONE,ERROR,ERR_UGH ; Mark as general failure

	 xor	 ax,ax		; A convenient zero
	 mov	 es:[bx].INIT_END_VEC.VOFF,ax
	 mov	 es:[bx].INIT_END_VEC.VSEG,cs
	 mov	 es:[bx].INIT_UNITS,al ; No units defined

	 les	 si,DH_PTR	; Get driver header pointer
	 assume  es:RGROUP	; Tell assembler

				; Mark as block device because a bug
				; in DOS won't let char devices fail
				; initialization
	 and	 RGROUP:[si].DH_ATTR,not DRV_ATTR_CHAR
LOW_EXIT:
	 les	 bx,[bp].LOLDSTK1_VEC ; Get a pointer to the orginal stack
	 assume  es:nothing	; Tell assembler

	 les	 bx,es:[bx].RETADDR ; Get a pointer to the return code
	 assume  es:nothing	; Tell assembler
;
; Note:
;	The next several lines are for DR DOS because it reads the
;	DH_INTR, and DH_STRA fields and then call the routines
;	successively.
;	To handle this we are going to patch the jump vector stored
;	by DR DOS to reflect the value in the target driver that
;	we have overlaid on top of the loader. (Thanks guys!)
;
	 cmp	 es:[bx].DR_OVER,@OPCOD_CS ; Is it a CS: override?
	 jne	 short @F	; No, exit

	 cmp	 es:[bx].DR_FCALL,@OPCOD_CALLFDD ; Is it a far call CS:[DWORD]?
	 jne	 short @F	; No, exit

	 mov	 bx,es:[bx].DR_CVEC ; Get the offset of the jump vector

	 mov	 ax,seg RGROUP	; Get segment of the device headers
	 mov	 ds,ax		; Make addressable via DS
	 assume  ds:RGROUP	; Tell assembler

	 mov	 ax,DEVDRV0.DH_INTR ; Get the new interrupt handler offset

	 mov	 es:[bx].VOFF,ax ; Set the DOS jump vector to new interrupt addr
@@:
	 REGREST <es,di,si,dx,cx,bx> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

; Reload pointer to request header, since the WFW drivers assume it's valid
; on entry to their interrupt routines (they don't save it in the strategy
; routine) and DOS doesn't reload the segment of the header, only the
; offset.

	 les	 bx,[bp].LRH_VEC ; ES:BX ==> request header
	 assume  es:nothing	; Tell the assembler about it

; Switch back to caller's stack

	 mov	 ax,[bp].LOLDSTK1_VEC.VOFF ; Get & save old stack offset
	 mov	 ss,[bp].LOLDSTK1_VEC.VSEG ; Restore old stack segment
	 assume  ss:nothing	; Tell the assembler about it
	 mov	 sp,ax		; Restore old stack offset

	 REGREST <ds,bp,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 add	 sp,2		; Strip off return offset of INSTALL

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell assembler

	 pop	 si		; Restore

	 retf			; Return to DOS
LOW_END:
	 ret			; Return to caller

INSTALL_LOW endp		; End INSTALL_LOW

	 NPPROC  LOADHI - Load File Into High DOS Memory
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Load the file into high DOS memory.

|

	 REGSAVE <ax,bx,dx,es>	; Save registers

	 push	 cs		; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

; Fill memory with a pattern following EXEC_PRGMAC

	 call	 FILL_MEM	; Fill it up

; From this point on, the memory above GTAIL is invalid.

; If we're loading via GETSIZE, go ahead.  Otherwise,
; skip it and catch the load in CHECK_MEM because of FLEXFRAME
; and disk caches

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jz	 short LOADHI_OK ; Jump if not

	 lea	 bx,EXEC_BLK	; ES:BX ==> EXEC call parameter block
	 mov	 al,03h 	; Code to load but not execute
	 DOSCALL @EXEC,LCL_FID	; Load into high DOS memory
	 pushf			; Save flags for a moment
	 call	 REST_2324	; Restore old INTs 23h 24h
	 popf			; Restore flags
	 jnc	 short LOADHI_OK ; Jump if it loaded correctly

	 lea	 ax,AZS_EXEC	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 jmp	 short LOADHI_ERR ; Join common error code

LOADHI_ERRMEM:
	 lea	 ax,AZS_ERRMEM	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 jmp	 short LOADHI_ERR ; Join common error code

LOADHI_OK:

; Check on valid memory in high DOS

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short @F	; Yes, no checking to do

	 call	 CHECK_MEM	; Check it out
	 pushf			; Save flags for a moment
	 call	 REST_2324	; Restore old INTs 23h 24h
	 popf			; Restore flags
	 jc	 short LOADHI_ERRMEM ; Jump if memory error
@@:

; Apply any patches indicated by Fn flag in 386LOAD.CFG
	 call	 CHECK_PATCH	; Patch code at EXEC_LOD

; Install local INT 21h handler to launder DOS version calls
; if we're running under a version of DOS earlier than 5.x

	 cmp	 DOSVER,0500h	; Izit DOS 5.x or later?
	 jae	 short @F	; Jump if so

	 mov	 al,21h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT21_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT21_VEC.VSEG,es ; ...

	 push	 ds		; Save
	 mov	 ax,EXEC_INTMAC ; Get the Int MAC segment
	 inc	 ax		; Bump to next paragraph
	 mov	 ds,ax		; Point DS to the relocatable segment
	 assume  ds:nothing	; Tell assembler

	 mov	 al,21h 	; Intercept this one
	 DOSCALL @SETINT,INT21	; Install our local handler

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell assembler
@@:

; Fill in EXEC_PSP for DOS 5.x SET_EES call

	 DOSCALL @GETPS0	; Return with segment # of PSP in BX
	 mov	 EXEC_PSP,bx	; Save for later use

; Set ending address for DOS 5.x programs

	 mov	 ax,EXEC_PRGMAC ; Get program MAC segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,EXEC_PRGNPAR ; Plus # paras in the region

	 les	 bx,RH_VEC	; ES:BX ==> request header
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[bx].INIT_END_VEC.VSEG,ax ; Save ending segment
	 mov	 es:[bx].INIT_END_VEC.VOFF,0  ; ...	    offset

	 mov	 DRVEND_VEC.VSEG,ax ; Save for later use
;;;;;;;; mov	 DRVEND_VEC.VOFF,0 ; ... (already done)

	 clc			; Indicate all went well

	 jmp	 short LOADHI_EXIT ; Join common exit code

LOADHI_ERR:
	 stc			; Indicate something went wrong
LOADHI_EXIT:
	 REGREST <es,dx,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LOADHI	 endp			; End LOADHI procedure
	 NPPROC  FCN_DISPLAY -- Display The Argument Line
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Display the device driver line

|

	 REGSAVE <ax,si,ds>	; Save registers

	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 test	 LCL_FLAG,@LCL_DISP ; Already displayed?
	 jnz	 short FCN_DISPLAY_EXIT ; Yes, don't do it again

	 or	 LCL_FLAG,@LCL_DISP ; Mark as displayed

	 call	 NEWLINE	; Ensure we're starting on a new line

	 lea	 si,MSG_DEVICE	; DS:SI ==> "Device="
	 call	 DISP_TEXT	; Display text up to but not including CR or LF

	 lds	 si,PDEV_VEC	; DS:SI ==> argument line
	 assume  ds:nothing	; Tell the assembler about it

	 call	 DISP_TEXT	; Display text up to but not including CR or LF

	 mov	 al,CR		; Back to column 1
	 VIDCALL @SETTTY	; Write it out

	 mov	 al,LF		; Down one line
	 VIDCALL @SETTTY	; Write it out
FCN_DISPLAY_EXIT:
	 REGREST <ds,si,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_DISPLAY endp		; End FCN_DISPLAY procedure
	 NPPROC  DISP_ERRMSG -- Display Error Message
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Display an error message.

|

DISP_ERR_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
DISP_ERR_OFF dw  ?		; Offset of error message

DISP_ERR_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,cx,dx,di,ds,es> ; Save registers

	 call	 DISP_COPY	; Display copyright

	 call	 FCN_DISPLAY	; Display the argument line

	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 cs		; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 di,[bp].DISP_ERR_OFF; ES:DI ==> error message
	 mov	 al,0		; ASCIIZ string terminator
	 mov	 cx,-1		; We know it's there
   repne scasb			; Search for it
	 dec	 di		; Back up to trailing zero

	 mov	 al,EOS 	; Get @STROUT string terminator
	 xchg	 al,es:[di]	; Swap 'em

	 mov	 dx,[bp].DISP_ERR_OFF; DS:DX ==> error message
	 DOSCALL @STROUT	; Display it

	 xchg	 al,es:[di]	; Swap 'em back

	 REGREST <es,ds,di,dx,cx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_ERRMSG endp		; End DISP_ERRMSG procedure
	 NPPROC  DISP_TEXT -- Display Text at DS:SI
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Display text at DS:SI up to but not including CR or LF.

On entry:

DS:SI	 ==>	 text to display

|

	 REGSAVE <ax,bx,si>	; Save registers

	 cld			; String ops forwardly

	 mov	 bl,@ATBWnorm	; Use normal attributes in case in graphics
DISP_TEXT_NEXT:
	 lodsb			; Get next character

	 cmp	 al,CR		; Line ending?
	 je	 short DISP_TEXT_EXIT ; Yes, so that's all folks

	 cmp	 al,LF		; Line ending?
	 je	 short DISP_TEXT_EXIT ; Yes, so that's all folks

	 VIDCALL @SETTTY	; Write it out

	 jmp	 short DISP_TEXT_NEXT ; Go around again

DISP_TEXT_EXIT:
	 REGREST <si,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_TEXT endp			; End DISP_TEXT procedure
	 NPPROC  SET_END_SEG -- Set END_SEG variable
	 assume  ds:RGROUP,es:nothing,ss:nothing
COMMENT|

If END_SEG is set to 0 on entry then the target driver chain is
processed to determine the number of headers used and if
any are block devices.	If no block devices are present then
the end address of the driver is set to just after the first header,
otherwise it is set to an offset just after the number of headers in the
target device driver plus 2.

|
	 REGSAVE <ax,bx,cx,si,ds> ; Save

	 test	 END_SEG,-1	; Has it been set already?
	 jnz	 SES_090	; Yes, get out of here

	 lds	 si,DH_PTR	; Get pointer to header
	 assume  ds:RGROUP	; Tell assembler

	 lea	 si,DEVDRV0	; We want information from the first device
	 mov	 si,RGROUP:[si].DH_THDR ; Get the target driver offset
	 mov	 ds,TARG_SEG	; Get the segment of the target driver
	 assume  ds:nothing	; Tell assembler

	 xor	 bx,bx		; Zero device counter and attribute flag
SES_010:
	 inc	 bl		; Bump device counter

	 test	 ds:[si].DH_ATTR,DRV_ATTR_CHAR ; Is this a block device?
	 jnz	 short SES_020	; No

	 inc	 bh		; Bump block device counter
SES_020:
	 mov	 si,ds:[si].DH_NEXT.VOFF ; Get next device addr
	 assume  ds:nothing	; Tell assembler

	 cmp	 si,-1		; Any more devices?
	 jne	 SES_010	; Yea, go check them

	 lea	 ax,RGROUP:DEVDRV1+(16-1) ; Get the offset of header 1

	 or	 bh,bh		; Any block devices?
	 jz	 SES_050	; Nope, go

	 xor	 bh,bh		; Clear MSB of index
	 add	 bx,RES_HDRS	; Reserve more headers for dechaining

	 cmp	 bx,MIN_HDRS	; It takes at some headers to do our magic
	 jae	 short SES_040	; We have enough go

	 mov	 bx,MIN_HDRS	; Set to min we can accept
SES_040:
	 shl	 bx,1		; Make into a word index for table look up

	 mov	 ax,DEVDRVTBL[bx] ; Get header offset from table
SES_050:
	 add	 ax,16-1	; Make sure we round up during conversion
	 mov	 cl,4		; Byte to paragraph conversion factor
	 shr	 ax,cl		; Convert offset to paragraphs
	 add	 ax,seg RGROUP	; Add in the header segment
	 mov	 END_SEG,ax	; Save new end segment
SES_090:
	 REGREST <ds,si,cx,bx,ax> ; Restore
	 assume  ds:PGROUP	; Tell assembler
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SET_END_SEG endp		; End SET_END_SEG
	 NPPROC  INITIAL -- Device Driver Initialization
	 assume  ds:RGROUP,es:nothing,ss:nothing
COMMENT|

Handle end of device driver initialization call.

Entry:
	DS:SI - point to loader device header

|

; Switch to local stack for INT 21h calls as the caller's might not
; be big enough

	 mov	 OLDSTK_VEC.VSEG,ss ; Save current stack segment
	 mov	 OLDSTK_VEC.VOFF,sp ;			& pointer

	 cli			; No interruptions

	 push	 cs		; Move CS
	 pop	 ss		; ... to SS
	 lea	 sp,TEMPSTKZ	; Address new stack

	 sti			; Restore interrupts

	 REGSAVE <ax,bx,cx,dx,si,di,es,ds> ; Save registers

	 and	 DRV_FLAG,not @DF_CHAR ; Assume its a block device

	 test	 RGROUP:[si].DH_ATTR,DRV_ATTR_CHAR ; Izit a block device?
	 jz	 short @F	; Jump if not

	 or	 DRV_FLAG,@DF_CHAR ; Flag its a character device
@@:
	 mov	 si,RGROUP:[si].DH_THDR ; Get pointer to target driver
	 mov	 ds,TARG_SEG	; Get target device segment
	 assume  ds:nothing	; Tell assembler

	 cmp	 ds:[si].DH_NEXT.VOFF,-1 ; Is there a next time?
	 jne	 short @F	; Yep, keep going

	 or	 DRV_FLAG,@DF_LAST ; Flag its the last device to install
@@:
	 push	 cs		; Set DS to ..
	 pop	 ds		; point to PGROUP for get size
	 assume  ds:PGROUP	; Tell assembler

	 test	 LC2_FLAG,@LC2_XMAX ; Is MAX present?
	 jnz	 short INITIAL_XLSEG ; Jump if not

	 call	 UNLINK_TLSEG	; Unlink temporary LSEG

INITIAL_XLSEG:
	 les	 bx,RH_VEC	; Get pointer to request header
	 assume  es:nothing	; Tell assembler

	 test	 LCL_FLAG,@LCL_RES ; Did the program go resident?
	 jnz	 short INITIAL_ISRES ; Yes, then no one else can really fail init

; If any device returns an ending address of zero, it doesn't
; go resident, so we need to check for that case here.

	 mov	 ax,es:[bx].INIT_END_VEC.VOFF ; Get ending offset
	 add	 ax,16-1	; Round up to next para boundary
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 ax,cl		; Round down to para boundary
	 add	 ax,es:[bx].INIT_END_VEC.VSEG ; Plus ending segment

	 cmp	 ax,TARG_SEG	; Izit bigger than the starting segment?
	 jbe	 short INITIAL_ERR ; Jump if not (not going resident)

; If it's a block device, ensure there is no error and there
; are some units defined, otherwise DOS won't return back to us.

	 test	 DRV_FLAG,@DF_CHAR ; Izit a block device?
	 jnz	 short INITIAL_ISRES ; No, keep going

	 test	 es:[bx].SRH_STA,8000h ; Check for error flag
	 jnz	 short INITIAL_ERR ; It's in error

	 cmp	 es:[bx].INIT_UNITS,0 ; Any units defined?
	 je	 short INITIAL_ERR ; No, It's in error
INITIAL_ISRES:
	 or	 LCL_FLAG,@LCL_RES ; Mark that the program went resident

	 jmp	 INITIAL1	; Join common code

INITIAL_ERR:

; Because MAXIMIZE expects 386LOAD GETSIZE to generate an LSEG entry
; for all programs (unless we can't decipher the command line), we
; check for that here and continue on with a zero ending address.

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short INITIAL0 ; Jump if so
INITIAL_ERR1:
	 push	 ds		; Save for a moment

	 mov	 ds,EXEC_INTMAC ; Set DS to LSEG MAC paragraph
	 assume  ds:nothing	; Tell assembler

	 mov	 ds:[0].MAC_OWNR,@MAC_FREE ; Mark as free

	 mov	 ds,EXEC_PRGMAC ; Set DS to program's MAC paragraph
	 assume  ds:nothing	; Tell assembler

	 mov	 ds:[0].MAC_OWNR,@MAC_FREE ; Mark as free

	 lds	 si,DH_PTR	; Get pointer to header
	 assume  ds:RGROUP	; Tell assembler

	 and	 RGROUP:[si].DH_ATTR,not DRV_ATTR_CHAR ; Mark as block device as bug
				; in DOS won't let char devices fail
				; initialization
	 mov	 RGROUP:[si].DH_NEXT.VOFF,-1 ; Last device in chain
	 mov	 RGROUP:[si].DH_NEXT.VSEG,-1 ; ...

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell assembler

	 xor	 ax,ax		; A convenient zero
	 mov	 es:[bx].INIT_END_VEC.VOFF,ax
	 mov	 es:[bx].INIT_END_VEC.VSEG,seg RGROUP
	 mov	 es:[bx].INIT_UNITS,al ; No units defined

; Restore original INT 21h handler if not DOS 5.x or later

	 cmp	 DOSVER,0500h	; Izit DOS 5.x or later?
	 jae	 short @F	; Jump if so

	 push	 ds		; Save for a moment

	 mov	 al,21h 	; Restore this one
	 lds	 dx,OLDINT21_VEC ; Get address of previous handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT	; Restore original handler

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
@@:

if @OEM_FLEX

	 test	 DRV_FLAG,@DF_LAST ; Is there a next time?
	 jz	 short @F	; Yes, we'll be back

; De-allocate any EMS memory

	 call	 REST_EMS	; Restore it
@@:
endif				; IF @OEM_FLEX
	 jmp	 INITIAL_EXIT	; Join common exit code

COMMENT|

On entry:

ES:BX	 ==>	 request header

|

INITIAL0:
	 ; Set flag driver failed to install with GETSIZE
	 ; and don't try to install any more devices
	 or	 DRV_FLAG,@DF_FAIL or @DF_LAST

	 xor	 ax,ax		; A convenient zero
	 mov	 LSEG.LSEG_LSIZE.ELO,ax ; Clear the load size
	 mov	 LSEG.LSEG_LSIZE.EHI,ax ; ...

; Clear error flag in request header to avoid DOS aborting,
; although DOS doesn't look at this flag during initialization

	 and	 es:[bx].SRH_STA,not 8000h ; Clear it

; Because the device failed, the ending address may be bogus
; so we are going to set it to the EXEC address

	 mov	 ax,EXEC_LOD	; Get the device load segment
	 mov	 es:[bx].INIT_END_VEC.VSEG,ax ; Set the request header ending ..
	 mov	 es:[bx].INIT_END_VEC.VOFF,0 ; address to the load point (0 used)

; Set character device bit in attribute word to force DOS install

	 REGSAVE <ds>		; Save

	 lds	 si,DH_PTR	; Get pointer to header
	 assume  ds:RGROUP	; Tell assembler

	 mov	 RGROUP:[si].DH_ATTR,DRV_ATTR_CHAR ; Mark it as a character device

; Change the device name to something we can recognize <LoadErr$>

	 mov	 RGROUP:[si+0].DH_NAME.ELO,'oL' ; Set first two bytes of name
	 mov	 RGROUP:[si+2].DH_NAME.ELO,'da' ;  "  next   "    "    "  "
	 mov	 RGROUP:[si+4].DH_NAME.ELO,'rE' ;  "  next   "    "    "  "
	 mov	 RGROUP:[si+6].DH_NAME.ELO,'$r' ;  "  next   "    "    "  "

	 REGREST <ds>		; Restore
	 assume  ds:PGROUP	; Tell assembler

; Convert the device driver ending address to a MAC entry
; and return our own ending address

INITIAL1:
	 mov	 ax,es:[bx].INIT_END_VEC.VOFF ; Get ending offset
	 add	 ax,16-1	; Round up to next para boundary
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 ax,cl		; Round down to para boundary
	 add	 ax,es:[bx].INIT_END_VEC.VSEG ; Plus ending segment

	 sub	 ax,EXEC_LOD	; Less load point = # paras requested

	 add	 ax,LSEG.LSEG_NPARA ; Account for the Int block (including MAC)

	 cmp	 ax,LSEG.LSEG_RPARA ; Check against maximum so far
	 jae	 short @F	; It's bigger

	 mov	 ax,LSEG.LSEG_RPARA ; Get largest so far
@@:
	 cmp	 ax,LSEG.LSEG_RPAR2 ; Check against forced resident size
	 jae	 short @F	; It's bigger

	 mov	 ax,LSEG.LSEG_RPAR2 ; Use forced resident size
@@:
	 mov	 LSEG.LSEG_RPARA,ax ; Save as new maximum

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jz	 short @F	; No, go

	 add	 ax,EXEC_LOD	; Compute ending segment
	 mov	 END_SEG,ax	; Set ending segment

	 jmp	 short INITIAL_CHK ; Continue
@@:
	 call	 SET_END_SEG	; Set the END_SEG variable
; Note:
; MS-Dos 3.3 for the AT&T 6300 has a bug that does not allow us to set the
; offset to 0 in the request header ending address field.  We set the
; offset to 10 and decrement the ending segment by one.
	 mov	 cx,END_SEG	; Get the ending segment
	 dec	 cx		;
	 mov	 es:[bx].INIT_END_VEC.VSEG,cx ; Set ending segment
	 mov	 es:[bx].INIT_END_VEC.VOFF,10h ; Set ending offset in Req Header
INITIAL_CHK:
	 mov	 ch,es:[bx].INIT_DRIV ; Get drive letter if block device

; Note CH is used below

	 mov	 es,EXEC_PRGMAC ; Get program MAC segment
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 ax,es:[0].MAC_NPAR ; Izit within range?
	MJ a	 INITIAL_NOROOM ; No, now what !!!

	 test	 DRV_FLAG,@DF_LAST ; Is there a next time?
	MJ z	 INITIAL_EXIT	; Yes, we'll be back

; See how much initialization room the driver used if it went resident

	 test	 LCL_FLAG,@LCL_RES ; Izit resident?
	 jz	 short INITIAL_XRESIZE ; Jump if not

	 test	 LC2_FLAG,@LC2_XMAX ; Is MAX or Move'EM present?
	 jnz	 short @F	; Jump if not (don't display message)

	 call	 GETSIZE	; Get the initialization size

@@:
; Reduce MAC entry to resident size now before calling REST_EMS.
; REST_EMS checks to see if the block abutting the mappable page
; is free.
;;;;;;;; Wait until we have restored EMS memory to its previous state
;;;;;;;; before marking the owner -- otherwise, REST_EMS might fail
;;;;;;;; because the block contiguous with the mappable page isn't free

	 mov	 es:[0].MAC_OWNR,@MAC_DRV ; Save as owner

; Reduce the program block to just the resident size

	 mov	 ax,LSEG.LSEG_RPARA ; Get maximum resident size

	 cmp	 ax,LSEG.LSEG_RPAR2 ; Check against forced resident size
	 jae	 short @F	; It's bigger

	 mov	 ax,LSEG.LSEG_RPAR2 ; Use forced resident size
@@:
	 sub	 ax,LSEG.LSEG_NPARA ; Don't count the Int MAC

	 cmp	 ax,es:[0].MAC_NPAR ; Izit within range?
	 je	 short INITIAL_XRESIZE ; Jump if it just fits

	 xchg	 ax,es:[0].MAC_NPAR ; Save as new MAC length
	 sub	 ax,es:[0].MAC_NPAR ; Subtract to get size of remaining MAC
	 dec	 ax		; Account for MAC paragraph for next MAC entry

	 mov	 cl,@MAC_MID	; Mark as middle entry
	 xchg	 cl,es:[0].MAC_TYPE ; Save as new type
	 mov	 es:[0].MAC_DRV,ch ; Save for later use

	 mov	 dx,es		; Copy current segment
	 inc	 dx		; Count in MAC paragraph
	 add	 dx,es:[0].MAC_NPAR ; Add in # paragraphs in this entry
	 mov	 es,dx		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[0].MAC_TYPE,cl ; Save as new type
	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Entry is unallocated
	 mov	 es:[0].MAC_NPAR,ax ; Save as new # paragraphs

INITIAL_XRESIZE:
if @OEM_FLEX
; Restore INT 67h if intercepted

	 call	 REST67 	; Restore it

; If we're not going resident and GETSIZE is not specified,
; exit at this point

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short @F	; Jump if so

	 test	 LCL_FLAG,@LCL_RES ; Izit resident?
	 MJ z	 INITIAL_ERR1	; Jump if not

; De-allocate any EMS memory after checking for pattern breaks

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short @F	; Yes, then INST_EMS not called

	 call	 REST_EMS	; Restore it
@@:
endif				; IF @OEM_FLEX

INITIAL_DONE:
	 or	 LCL_FLAG,@LCL_INIT ; Mark as initialized

; Strip out our INT 21h handler

	 push	 ds		; Save

	 mov	 ax,EXEC_INTMAC ; Get the Int MAC segment
	 inc	 ax		; Bump to next paragraph
	 mov	 ds,ax		; Point DS to the relocatable segment
	 assume  ds:nothing	; Tell assembler

	 lea	 bx,TARG_SEG	; Get offset in BX of the target segment
	 mov	 ax,PGROUP:[bx] ; Get the local copy
	 mov	 ds:[bx],ax	; Transfer to resident copy

	 cmp	 DOSVER,0500h	; Izit DOS 5 or higher?
	 jae	 short @F	; Jump if so

	 lea	 bx,UDDPB_CNT	; Get offset in BX of the number of DPBs to fix
	 mov	 al,PGROUP:[bx] ; Get the local copy
	 mov	 ds:[bx],al	; Transfer to resident copy

	 lea	 bx,OLDINT21_VEC ; Get offset of old int 21 pointer

	 mov	 ax,OLDINT21_VEC.VSEG ; Get old segment
	 mov	 ds:[bx].VSEG,ax ; Transfer to resident copy

	 mov	 ax,OLDINT21_VEC.VOFF ; Get old offset
	 mov	 ds:[bx].VOFF,ax ; Transfer to resident copy

	 lea	 bx,TMPINT21_VEC ; Get offset of TMPINT21_VEC

	 mov	 ax,OLDINT21_VEC.VSEG ; Get old segment

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 ds:[bx].VSEG,ax ; Save as intermediate value

	 mov	 ax,OLDINT21_VEC.VOFF ; Get old offset
	 mov	 ds:[bx].VOFF,ax ; Save as intermediate value

	 popf			; Restore flags
@@:
	 pop	 ds		; Set DS back to normal
	 assume  ds:PGROUP	; Tell assembler

	 mov	 ax,EXEC_INTMAC ; Get pseudo-interrupt MAC segment
	 inc	 ax		; Bump to final destination segment
	 mov	 LSEGSEG,ax	; Save to link the LSEG

	 test	 LC2_FLAG,@LC2_XMAX ; Is MAX present?
	 jnz	 short INITIAL_EXIT ; Jump if not

	 and	 LSEG.LSEG_FLAG,not @LSEG_INPRO ; Clear 386LOAD in progress bit

	 call	 LINK_LSEG	; Link into the LSEG chain

	 jmp	 short INITIAL_EXIT ; Join common exit code

INITIAL_NOROOM:
if @OEM_FLEX

; Restore INT 67h if intercepted

	 call	 REST67 	; Restore it
endif				; IF @OEM_FLEX

; De-allocate any EMS memory

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short INITIAL_ERR0 ; Yes, then none of the below used

	 push	 es		; Save for a moment

	 push	 cs		; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

if @OEM_FLEX
	 call	 REST_EMS	; Restore it
endif				; IF @OEM_FLEX

	 lea	 ax,AZS_UGHROOM ; Tell 'em the very bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 mov	 ax,LSEG.LSEG_RPARA ; Get maximum # paras requested

	 cmp	 ax,LSEG.LSEG_RPAR2 ; Check against forced resident size
	 jae	 short @F	; It's bigger

	 mov	 ax,LSEG.LSEG_RPAR2 ; Use forced resident size
@@:
	 call	 FMT_CHG	; Format the change line for "SIZE=nnn,nnn" w/AX

	 call	 WAITFF 	; Wait until hell freezes over
				; (or the user presses Alt-255)

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
INITIAL_ERR0:
	 jmp	 INITIAL_ERR	; Join common error code

INITIAL_EXIT:
	 REGREST <ds,es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing,ds:nothing	; Tell the assembler about it

; Switch back to caller's stack

	 cli			; No interruptions

	 mov	 ss,OLDSTK_VEC.VSEG ; Restore old stack segment
	 assume  ss:nothing	; Tell the assembler about it
	 mov	 sp,OLDSTK_VEC.VOFF ; Restore old stack offset

	 sti			; Restore interrupts

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INITIAL  endp			; End INITIAL procedure
	 FPPROC  LCL_INT24 -- Critical Error Interrupt Handler
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Critical error interrupt handler.

Cut back the stack to the INT 21h caller,
set CF, and RETF 2.

|

	 add	 sp,3*2 	; Strip off IP, CS, FL from INT 24h caller

	 REGREST <ax,bx,cx,dx,si,di,bp,ds,es> ; Restore INT 21h caller's regs
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

; Set caller's flags (IF is the only significant one)

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack
	 push	 [bp].ARG_FLG	; Put flags onto stack
	 popf			; Restore caller's IF
	 pop	 bp		; Restore

	 stc			; Ensure set to indicate error

	 ret	 2		; Return to INT 21h caller, popping flags

	 assume  ds:nothing,es:nothing,ss:nothing

LCL_INT24 endp			; End LCL_INT24 procedure
	 NPPROC  INST24 -- Install INT 24h Handler
	 assume  ds:nothing,es:nothing,ss:nothing

	 REGSAVE <ax,ds,es>	; Save registers

	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ax,seg INTVEC	; Prepare to address segment zero
	 mov	 es,ax		; Hello, segment zero
	 assume  es:INTVEC	; Tell the assembler about it

	 pushf			; Save state
	 cli			; Nobody move

	 lea	 ax,LCL_INT24	; Get & set offset
	 xchg	 ax,INT00_VEC.VOFF[24h*type INT00_VEC]
	 mov	 LCLINT24_VEC.VOFF,ax ; Save to restore later

	 mov	 ax,cs		; Get & set segment
	 xchg	 ax,INT00_VEC.VSEG[24h*type INT00_VEC]
	 mov	 LCLINT24_VEC.VSEG,ax ; Save to restore later

	 popf			; Restore interrupts

	 REGREST <es,ds,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INST24	 endp			; End INST24 procedure
	 NPPROC  REST24 -- Restore INT 24h Handler
	 assume  ds:nothing,es:nothing,ss:nothing

	 REGSAVE <ax,ds,es>	; Save registers

	 mov	 ax,seg INTVEC	; Prepare to address segment zero
	 mov	 es,ax		; Hello, segment zero
	 assume  es:INTVEC	; Tell the assembler about it

	 lds	 ax,LCLINT24_VEC ; DS:AX ==> old interrupt handler
	 assume  ds:nothing	; Tell the assembler about it

	 pushf			; Save state
	 cli			; Nobody move
	 mov	 INT00_VEC.VOFF[24h*type INT00_VEC],ax ; Restore offset
	 mov	 INT00_VEC.VSEG[24h*type INT00_VEC],ds ; ...	segment

	 popf			; Restore interrupts

	 REGREST <es,ds,ax>	; Restore
	 assume  ds:nothing,es:nothing

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REST24	 endp			; End REST24 procedure
	 FPPROC  NR_INT21 -- DOS Function Interrupt Handler
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

DOS function interrupt handler

We need this function only to lie about the DOS version #
if we're running under DOS 4.xx

|

	 pushf			; Save caller's flags

	 cmp	 ah,@DOSVER	; Izit get DOS version #?
	 jne	 short NR_INT21_ORIG ; Jump if not

	 popf			; Restore

; Set current flags to caller's flags (IF is the only significant one)

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack
	 push	 [bp].ARG_FLG	; Put flags onto stack
	 popf			; Restore caller's IF
	 pop	 bp		; Restore

	 OLDINT  21		; Call previous INT 21h handler

	 mov	 ax,XDOSVER	; Get local version # in non-comparison order

	 ret	 2		; Return to caller, popping old flags

NR_INT21_ORIG:
	 popf			; Restore

	 jmp	 OLDINT21_VEC	; Continue with previous handler

	 assume  ds:nothing,es:nothing,ss:nothing

NR_INT21 endp			; End NR_INT21 procedure
	 NPPROC  DISP_COPY -- Display copyright notice and ID info
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

If copyright notice and ID info have not yet been displayed, do it.
Set the first byte of MSG_COPY to 0 so we don't do it twice.

|

	 cmp	 MSG_COPY,0	; Izit already displayed?
	 jz	 short DISP_COPY_EXIT ; Jump if so

	 REGSAVE <ax,bx,cx,dx,ds> ; Save registers

	 push	 cs		; Get PGROUP
	 pop	 ds		; DS: needed for STROUT
	 assume  ds:PGROUP	; Tell the assembler

	 DOSCALL @STROUT,MSG_COPY ; Display copyright message

	 mov	 MSG_COPY,0	; Clear it

	 REGREST <ds,dx,cx,bx,ax> ; Restore registers
	 assume  ds:nothing

DISP_COPY_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_COPY endp			; End DISP_COPY procedure

NCODE	 ends			; End NCODE segment
subttl -- Resident code Device Driver headers
page
;
; Macro used to build device headers
;
DEVHMAC  macro	 NUM,NUM1

	 public  DEVDRV&NUM
ife (@NEST-NUM-1)
DEVDRV&NUM DH_STR <-1,DRV_ATTR_CHAR,RGROUP:DEV_LSTRA&NUM,RGROUP:DEV_LINTR&NUM,'Loader$$'>
else
DEVDRV&NUM DH_STR <RGROUP:DEVDRV&NUM1,DRV_ATTR_CHAR,RGROUP:DEV_LSTRA&NUM,RGROUP:DEV_LINTR&NUM,'Loader$$'>
endif
	 public  DEV_LSTRA&NUM
DEV_LSTRA&NUM:
	 assume  ds:nothing,es:nothing,ss:nothing

	 call	 LOW_STRA_COM	; This places a reference point on the stack..
				; for this device header we do not expect..
				; to return
DEV_LSREF&NUM:
	 assume  ds:nothing,es:nothing,ss:nothing

	 public  DEV_LINTR&NUM
DEV_LINTR&NUM:
	 assume  ds:nothing,es:nothing,ss:nothing

	 call	 LOW_INTR_COM	; This places a reference point on the stack..
				; for this device header we do not expect..
				; to return
DEV_LIREF&NUM:
	 assume  ds:nothing,es:nothing,ss:nothing

	 endm			; End DEVHMAC
page
RCODE	 segment		; Start RCODE segment
	 assume  cs:RGROUP, ds:nothing,es:nothing,ss:nothing
	 DEVHMAC 0,1		; Define device header
;
; The two following jumps will be patched in the final
; stages of initialization to point into our high DOS
; resident handlers
;
	public LOW_STRA_COM
LOW_STRA_COM:
	 jmp	 DEV_STRA_COM	; Goto high DOS handler

	public LOW_INTR_COM
LOW_INTR_COM:
	 jmp	 DEV_INTR_COM	; Goto high DOS handler

CNT	 =	 1		;
	 rept	 @NEST-1	;
	 DEVHMAC %CNT,%CNT+1	; Define nested device headers
CNT	 =	 CNT+1		;
	 endm			; REPT @NEST
;
; The two values below are used to determine offset of the device
; headers from the value put on the stack by the call to LOW_INTR_COM
; or LOW_STRA_COM.
;
@STRA_BACK equ DEV_LSREF1 - DEVDRV1
@INTR_BACK equ DEV_LIREF1 - DEVDRV1

RCODE	 ends			; End RCODE segment

	 MEND	 DRVSTART	; End DRVCOM module
