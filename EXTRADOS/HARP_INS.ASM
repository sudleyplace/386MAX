;'$Header:   P:/PVCS/MAX/EXTRADOS/HARP_INS.ASV   1.2   30 May 1997 11:13:10   BOB  $
	 title	 HARP_INS -- INSTALL= routines for HARPO
	 page	 58,122
	 name	 HARP_INS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  dword-aligned,public, class 'data'
	       Stack   segment STACK, para-aligned, stack,  class 'stack'

|
.286
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include KEYCALL.INC
	 include ASCII.INC
	 include PTR.INC
	 include XMS.INC
	 include MAC.INC
	 include EXE.INC
	 include EXEC.INC
	 include OPCODES.INC
	 include INTVEC.INC

	 include SEGS.INC
	 include HARPO.INC
	 include QMAXINFO.INC
	 include LOAD_SEG.INC
.list



;*******************************************************************

PSP_SEG  segment at 0			; Start PSP segment

	 extrn	 PSP_TERMINATE:VECTOR
	 extrn	 PSP_CTRL_BREAK:VECTOR
	 extrn	 PSP_CRIT_ERROR:VECTOR
	 extrn	 PSP_FILE_TAB_PTR:VECTOR
	 extrn	 PSP_CTRL_PSP:word

PSP_SEG  ends				; End	PSP segment


HCODE	 segment		; Start Resident Code segment

extern	 OLDINT21_VEC:dword	; Original interrutp 21 entry point

extern	 CONFIG_SEGMENT:word	; DOS' transient code/data segment
extern	 UMB_SEGMENT:word	; Segment of our primary (data) UMB
extern	 FIRST_MAC:word 	; Segmenty of DOS' first MAC entry
extern	 LOADSEG:word		; Segment of LSEG chain head

extern	 MSG_MAXIMIZE1:byte	; Tell 'em ths environment
extern	 MSG_MAXIMIZE2:byte	; ... has changed size

extern	 REL_UMB:near		; Release our transient UMB
extern	 REMOVE_DEAD:near	; Remove DeadMan switch from the profile
extern	 GETMEM_REG:near	; Allocate Memory From Specified Region
extern	 ALLOC_MAC:near 	; Allocate a MAC at the specified address
extern	 SRCHSTR_:near		; Search for model code
extern	 PRESSANY:near		; Press any key to continue
extern	 FMT_WORD:near		; Format AX => ES:DI
extern	 INFO_READ:near 	; Read	MAX's info structure
extern	 INFO_WRITE:near	; Write MAX's info structure
extern	 DISP_COPY:near 	; Display copyright and message at DI

extern	 FILL_MEM:near		; Apply the getsize pattern
extern	 LOADSIZE:near		; Calculate the file's load size
extern	 GETSIZE:near		; Calculate the file's init size
extern	 FILE_HEAD:EXE_STR	; Room for EXE header
extern	 EXEC_PRGMAC:word	; Segment of program MAC
extern	 EXEC_PRGNPAR:word	; Original # paras allocated to program
extern	 TOPFILL:word		; Highest para # for fill/search of GETSIZE
extern	 STKSIZE:dword		; Size of stack in bytes

extern	 FLOAT_SEG:word 	; Segment of our floater (if needed)
extern	 CURR_REG:byte		; Current region (region of next request)
extern	 TRANSFER_BOOT:near	; Move our code to different region

extern	 DOSVER:word		; DOS version number in comparison order
extern	 MODELNO:byte		; 0=DOS 3/4/5/6/7, 1=MS-DOS 7.00

;-------------- Environment Loader Models (resident) --------------------
;----------------------MSDOS 4, 5, 6-------------------------------------

	 public  ENV_MODEL1
ENV_MODEL1 label byte			; Environment alloc routine
	 db	 059h, 05Bh, 05Dh	; POP CX, POP BX, POP BP
	 db	 0B4h, 048h		; MOV AH,48
EM1	 db	 0CDh, 021h		; INT 21
	 db	 072h, -1		; JC [????]
	 db	 0A3h, -1, -1		; MOV [????],AX
	 db	 0A3h, -1, -1		; MOV [????],AX
	 db	 08Eh, 0C0h		; MOV ES,AX
	 db	 01Eh			; PUSH DS
	 db	 08Eh, 0DDh		; MOV DS,BP
	 db	 033h, 0F6h		; XOR SI,SI
	 db	 08Bh, 0FEh		; MOV DI,SI
	 db	 0FCh			; CLD
	 db	 0F3h, 0A4h		; REP MOVSB
	 db	 01Fh			; POP DS
@ENV_MODEL1_LEN equ $-ENV_MODEL1 ; Length of above

@MODEL1_ENV_PATCH equ (EM1-ENV_MODEL1) ; Address of INT 21h (patch point)

;----------------------PCDOS 7-------------------------------------------

	 public  ENV_MODEL2
ENV_MODEL2 label byte			; Environment alloc routine
	 db	 059h, 05Bh, 05Dh	; POP CX, POP BX, POP BP
	 db	 0B4h, 048h		; MOV AH,48
EM2	 db	 0CDh, 021h		; INT 21
	 db	 072h, -1		; JC [????]
	 db	 2Eh,0A3h, -1, -1	; MOV CS:[????],AX
	 db	 2Eh,0A3h, -1, -1	; MOV CS:[????],AX
	 db	 08Eh, 0C0h		; MOV ES,AX
	 db	 01Eh			; PUSH DS
	 db	 08Eh, 0DDh		; MOV DS,BP
	 db	 033h, 0F6h		; XOR SI,SI
	 db	 08Bh, 0FEh		; MOV DI,SI
	 db	 0FCh			; CLD
	 db	 0F3h, 0A4h		; REP MOVSB
	 db	 01Fh			; POP DS
@ENV_MODEL2_LEN equ $-ENV_MODEL2 ; Length of above

@MODEL2_ENV_PATCH equ (EM2-ENV_MODEL2) ; Address of INT 21h (patch point)

;----------------------MSDOS 7-------------------------------------------

	 public  ENV_MODEL3
ENV_MODEL3 label byte			; Environment alloc routine
	 db	 08Bh, 0CBh		; MOV CX,BX
	 db	 083h, 0C3h, 00Fh	; ADD BX,+0F
	 db	 0D1h, 0EBh		; SHR BX,1
	 db	 0D1h, 0EBh		; SHR BX,1
	 db	 0D1h, 0EBh		; SHR BX,1
	 db	 0D1h, 0EBh		; SHR BX,1
	 db	 0B4h, 048h		; MOV AH,48
EM3	 db	 0CDh, 021h		; INT 21
	 db	 073h,	 -1		; JNC [????]
@ENV_MODEL3_LEN equ $-ENV_MODEL3 ; Length of above

@MODEL3_ENV_PATCH equ (EM3-ENV_MODEL3) ; Address of INT 21h (patch point)


;----------------------MSDOS 7-------------------------------------------

	 public  ALLOCCMD_MODEL
ALLOCCMD_MODEL label byte		; [Allocate COMMAND.COM] model
	 db	050h			; PUSH AX
	 db	0B4h, 048h		; MOV AH,48
	 db	08Bh, 01Eh, -1, -1	; MOV BX,[07FB]
	 db	003h, 0D9h		; ADD BX,CX
AM1	 db	0CDh, 021h		; INT 21
	 db	05Bh			; POP BX
	 db	09Ch			; PUSHF
	 db	050h			; PUSH AX
	 db	006h			; PUSH ES
	 db	08Eh, 0C3h		; MOV ES,BX
	 db	0B4h, 049h		; MOV AH,49
	 db	0CDh, 021h		; INT 21
	 db	007h			; POP ES
	 db	058h			; POP AX
	 db	09Dh			; POPF
	 db	072h, -1		; JC 3141
@ALLOCCMD_LEN equ $-ALLOCCMD_MODEL	; Length of above

MODEL2_ALLOCATOR equ (AM1-ALLOCCMD_MODEL) ; Address of INT 21h

	 public  ALLOCCMD_MODEL2
ALLOCCMD_MODEL2 label byte		; [Allocate COMMAND.COM] model #2
	 db	 0B8h, 003h, 058h	; MOV AX,5803
	 db	 0BBh, 001h, 000h	; MOV BX,0001
	 db	 0CDh, 021h		; INT 21
	 db	 073h, 003h		; JNC 314E
	 db	 0E9h, -1,   -1 	; JMP 3206
	 db	 0B4h, 058h		; MOV AH,58
	 db	 0B0h, 001h		; MOV AL,01
	 db	 0BBh, 041h, 000h	; MOV BX,0041
	 db	 0CDh, 021h		; INT 21
	 db	 072h, 00Ch		; JC  3165
	 db	 0B4h, 048h		; MOV AH,48
	 db	 08Bh, 01Eh, -1,  -1	; MOV BX,[07FB]
AM2	 db	 0CDh, 021h		; INT 21
	 db	 08Ch, 0DBh		; MOV BX,DS
	 db	 073h, 003h		; JC  3168
@ALLOCCMD2_LEN equ $-ALLOCCMD_MODEL2	; Length of above

MODEL2_ALLOCATOR2 equ (AM2-ALLOCCMD_MODEL2) ; Address of INT 21h

;---------------

@MSINT	 equ	 04		; ALLOC_CCOM_HI interrupt
@MSINTX  equ	 04h		; ...			  as hex #

	 public  OLDINT04_VEC
OLDINT04_VEC VECTOR <>		; Save area for old INT @MSINTX

	 public  CCOM_LOWSEG
CCOM_LOWSEG dw	 0		; Segment for low COMMAND.COM w/MS-DOS 7 (0=none)

	 public  ENV_REGION
ENV_REGION   db  0		; Region for master environment

	 public  SHARE_REGION
SHARE_REGION db  0		; Region for DOS 4 implicit SHARE

	 public  CCOM_REGION,CCOM_XREG
CCOM_REGION  db   0		; Region to place CCOM
CCOM_XREG    db  -1		; Region of COMMAND.COM that is off limits
				; to the env. due to CCOM bug

	 public  CCOM_LEN,ENV_LEN
CCOM_LEN     dw  ?		; Length of CCOM in paras
ENV_LEN      dw  ?		; Length of the master environment

	 public  LSEG_SEG
LSEG_SEG     dw  ?		; Segment of COMMAND.COM's LSEG entry

	 public  EXEC_BLOCK_ADDR,EXEC_PROG_NAME
EXEC_BLOCK_ADDR dw	 ?	; Pointer to EXEC block for COMMAND.COM
EXEC_PROG_NAME	dw	 ?	; Pointer to program name for CMOMAND.COM

	 public  SAVED_FIRST_LEN
SAVED_FIRST_LEN dw	 ?	; Saved length value from FIRST_MAC

	 public  ACH_VEC
ACH_VEC  VECTOR  <>		; Return point for ALLOC_CCOM_HI

;;;	     public  SAVED_LAST_MAC,SAVED_LAST_TYPE
;;; SAVED_LAST_MAC  dw	     ?	    ; Saved segment  of   ...
;;; SAVED_LAST_TYPE db	     ?	    ; Saved MAC_TYPE from last MAC in low DOS
;;;
	 public  CCOM_SAVE
CCOM_SAVE db	 5 dup (?)	; Save area for code underneath patch

	 public  SAVE_SSSP
SAVE_SSSP	 dd	 ?	; Save area for SS:SP across 4B call
SAVE_DS 	 dw	 ?	; ...		DS    ...
SAVE_ES 	 dw	 ?	; ...		ES    ...

;-------------- SHARE variables --------------------------

	 public  SHARE_NAME
SHARE_NAME db	'SHARE.EXE'     ; Name of implicit INSTALL= program
@SHARE_LEN equ	 $-SHARE_NAME

;--------------- Error messages ---------------------------

	 extern  MSG_XENV:byte
	 extern  MSG_XI21:byte
	 extern  MSG_XMEM:byte
	 extern  MSG_XLOAD:byte
	 extern  MSG_XLOAD1:byte
	 extern  MSG_XFIRST:byte
	 extern  MSG_LOWMEM:byte
	 extern  MSG_LOWMEM_ENV:byte
	 extern  MSG_LOWMEM_CCOM:byte
	 extern  MSG_ENV_SIZE:byte


;--------------- Environment loader variables -----------------

	 public  ENV_ADDR,ENV_SAVE
ENV_ADDR	 dw	 ?	; Address of patch point
ENV_SAVE db	 5 dup (?)	; Save area for code underneath patch

	 public  ENV_SEGMENT
ENV_SEGMENT	 dw	 0	; Segment of master environment

	 public  FAKE_PSP
FAKE_PSP	 dw	 0	; Segment of our fake PSP
				; (needed so NETX and others can
				; find the master environment)


;--------------- GETSIZE variables ---------------------------

	 public  EXE_NPAR,EXEC_LOD
EXE_NPAR dw	 ?		; # paras to allocate to EXE file (getsize)
EXEC_LOD dw	 ?		; Pointer to high DOS memory
				; Used for GETSIZE pattern

	 public  LINKSTATE
LINKSTATE dw	 ?		; Save area for DOS link state

	 public  LSEG

LSEG	 LSEG_STR <-1,-1,,0,0,0,0,0,0,0,0,0,0,@LSEGPARA+1,@GRP_HIPROG,0,?,?,0>

	 public  LOADDBG
LOADDBG  LOADDBG_STR <> 	; Copy of EXEC_STR for 4B01h command


;***************************************************************************

	 NPPROC  LOAD_CCOM_HI -- LOAD_CCOM_HI Procedure
	 assume  ds:nothing,es:nothing,ss:nothing

COMMENT |

This is the interrupt 21h handler that is used to
load COMMAND.COM into High DOS

On entry:
AH	=	Interrupt 21 function number

|

	 test	 LCL_FLAG,@LCL_OFF ; Are we off?
	 jnz	 LOAD_CCOM_CONT ; Jump if we're turned off

	 cmp	 ah,04Dh	; Is it "Get Return Code" function?
	 je	 LOAD_CCOM_4D	; Jump if so

	 cmp	 ax,04B00h	; Is it "Exec Program" function?
	 je	 LOAD_CCOM_4B	; Jump if so

LOAD_CCOM_CONT:
	 jmp	 OLDINT21_VEC	; Continue with next handler

;---------

LOAD_CCOM_4D:

COMMENT |

DOS will make a funtion 4D call after HARPO returns control.  If DOS
sees a 03, it thinks the program went resident and continues on.
Otherwise, it prints an error message before continuing on.  By hooking
this function call, and stuffing an exit code of 03, we can avoid any
unsightly DOS error messages.
Note that 386LOAD does something similar for its own programs, but that
doesn't cover HARPO since we aren't loaded by 386LOAD.

|

	 pushf			; Simulate interrupt
	 cli			; ...
	 call	 OLDINT21_VEC	; Call next handler

	 mov	 ah,03h 	; Tell 'em HARPO went resident
				; A little white lie never hurt anybody

LOAD_CCOM_4D_IRET:

	 iret			; Return to caller

;---------

LOAD_CCOM_4B:

COMMENT |

After we hook interrupt 21h, the first 4B00 call should be to load
the command processor.	This will not be true if we are not the last
INSTALL= program in CONFIG.SYS.  This will also not be true if DOS 4
implicitly loads SHARE.EXE

|

	 SWATTER		; Call debugger if requested

	 call	 CHECK_SHARE	; Check on SHARE.EXE being loaded
	 jc	 LOAD_CCOM_CONT ; Jump if it's one of the following ...
				; SHARE (& we're loading it low)
				; Not SHARE ( & we're only loading SHARE High)

; See if the program being loaded is COMMAND.COM

	 call	 CHECK_CCOM_NAME ; Check name for CCOM
	 jc	 LOAD_CCOM_CONT ; If not CCOM, continue with next handler

	 or	 LCL_FLAG,@LCL_OFF ; Turn us off

; Because MS-DOS 7.00 loads COMMAND.COM differently, we need to
; create the fake PSP now in low DOS memory while there's still
; some to allocate.

	 cmp	 MODELNO,2	; Izit MS-DOS 7.00?
	 jne	 short @F	; Jump if not

	 call	 CREATE_FAKE_PSP ; Create phony MAC & PSP entry for CCOM
@@:

; Save the function 4Bh input parameters

	 mov	 EXEC_BLOCK_ADDR,bx ; Save for later
	 mov	 EXEC_PROG_NAME,dx ; ...

; Set the name in the LSEG entry

	 call	 APPLY_LSEG_NAME ; Apply the name to the LSEG entry

; Remove the function 4Bh hook (restore interrupt 21h vector)

	 call	 RESTORE_INT21	; Remove our interrupt 21 hook

; If this is MS-DOS 7 and we're loading COMMAND.COM low, we need
; to reserve a place for it in low DOS so it doesn't fragment memory.
; What happens is COMMAND.COM loads in low DOS, then reallocates itself
; in a context in which it expects it to go into high DOS, but we don't
; want it to go there (because our optimization algorithm says that's not
; optimal).  Thus, in this context, we allocate a suitable size chunk
; before the following 4B01h call, and then free the chunk in ALLOC_CCOM_HI.

	 call	 ALLOC_LOWSEG	; Allocate it if necessary

; Allocate memory for COMMAND.COM

	 call	 ALLOC_CCOM	; Allocate memory for COMMAND.COM
	 nop			; Make debugging easy

; Apply the GETSIZE pattern

	 cmp	 MODELNO,2	; Izit MS-DOS 7.00?
	 je	 short @F	; Jump if so

	 call	 APPLY_PATTERN	; Apply the '386M' getsize pattern
@@:

; Find the load size of this file

	 call	 GET_LSIZE	; Determine the program's loading size

; Patch both MAC entries (to trick DOS to load CCOM into High DOS)

	 call	 LINK_MAC	; Link in our MAC to the Low DOS chain

; Simulate interrupt 4B01h
; Load the program in memory

	 mov	 SAVE_SSSP.VVSEG,ss ; Save across 4B call
	 mov	 SAVE_SSSP.VVOFF,sp ; ...
	 mov	 SAVE_DS,ds	; ...
	 mov	 SAVE_ES,es	;

; Copy the contents of ES:BX to local memory and point to our own
; EXEC block as there are two more dwords in the block to which ES:BX
; points for 4B01h than there is in the 4B00h call

	 mov	 ax,es:[bx][EXEC_STR.EXEC_ENV] ; Get the environment
	 mov	 LOADDBG.LOADDBG_ENV,ax ; Save for later use
	 mov	 ax,es:[bx][EXEC_STR.EXEC_CMD][VVOFF] ; Get the command line offset
	 mov	 LOADDBG.LOADDBG_CMD.VVOFF,ax ; Save for later use
	 mov	 ax,es:[bx][EXEC_STR.EXEC_CMD][VVSEG] ; Get the command line segment
	 mov	 LOADDBG.LOADDBG_CMD.VVSEG,ax ; Save for later use
	 mov	 ax,es:[bx][EXEC_STR.EXEC_FCB1][VVOFF] ; Get the FCB #1 offset
	 mov	 LOADDBG.LOADDBG_FCB1.VVOFF,ax ; Save for later use
	 mov	 ax,es:[bx][EXEC_STR.EXEC_FCB1][VVSEG] ; Get the FCB #1 segment
	 mov	 LOADDBG.LOADDBG_FCB1.VVSEG,ax ; Save for later use
	 mov	 ax,es:[bx][EXEC_STR.EXEC_FCB2][VVOFF] ; Get the FCB #2 offset
	 mov	 LOADDBG.LOADDBG_FCB2.VVOFF,ax ; Save for later use
	 mov	 ax,es:[bx][EXEC_STR.EXEC_FCB2][VVSEG] ; Get the FCB #2 segment
	 mov	 LOADDBG.LOADDBG_FCB2.VVSEG,ax ; Save for later use

	 lea	 bx,LOADDBG	; Get offset of LOADDBG
	 mov	 ax,cs		; Get segment of LOADDBG
	 mov	 es,ax		; ES:BX ==> LOADDBG

	 mov	 ax,4B01h	; Load program (but don't execute it yet)
	 int	 21h		; Simulate interrupt (CF = significant)
				; Return error code in AX
FCN4B_RET:
	 mov	 ss,SAVE_SSSP.VVSEG ; Reload SS:SP
	 mov	 sp,SAVE_SSSP.VVOFF ; ...
	 mov	 ds,SAVE_DS	; ...
	 mov	 es,SAVE_ES	; ...

	 jc	 CCOM_LOAD_ERR	; Jump if there was an error loading COMMAND.COM
				; Error code will be in AX

; The following code is no longer needed as I can't get OnTrack's DDO
; driver to work with ExtraDOS's attempt to load COMMAND.COM high,
; but if we ever need it later, it might be useful.

;;; ; So other programs can allocate memory in high DOS after COMMAND.COM
;;; ; terminates, set its MAC_NPAR now
;;;
;;;	     REGSAVE <ax,bx,cx,ds>  ; Save for a moment
;;;
;;;	     mov     ax,UMB_SEGMENT ; Get starting MAC entry + 1 for COMMAND.COM
;;;	     dec     ax 	    ; Back off to MAC entry
;;;	     mov     ds,ax	    ; Address it
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;;
;;; ; DOS might have allocated the environment below COMMAND.COM itself,
;;; ; so we get this block's owner and back off to its MAC entry
;;;
;;;	     mov     ax,ds:[MAC_STR.MAC_OWNR] ; Get the owner segment
;;;	     dec     ax 	    ; Back off to MAC entry
;;;	     mov     ds,ax	    ; Address it
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;;
;;;	     mov     bl,@MAC_MID    ; Get middling MAC type
;;;	     xchg    bl,ds:[MAC_STR.MAC_TYPE] ; Swap 'em
;;;
;;;	     mov     ax,CCOM_LEN    ; Get length of CCOM in paras
;;;	     xchg    ds:[MAC_STR.MAC_NPAR],ax ; Save as new length
;;;	     sub     ax,CCOM_LEN    ; Less original length
;;;	     dec     ax 	    ; Less MAC para
;;;
;;;	     mov     cx,ds	    ; Copy current segment
;;;	     add     cx,ds:[MAC_STR.MAC_NPAR] ; Plus # paras
;;;	     inc     cx 	    ; Skip over the MAC para
;;;	     mov     ds,cx	    ; Address it
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;;
;;;	     mov     ds:[MAC_STR.MAC_TYPE],bl ; Save old type
;;;	     mov     ds:[MAC_STR.MAC_NPAR],ax ; Save as new length
;;;	     mov     ds:[MAC_STR.MAC_OWNR],@MAC_FREE ; Mark as free
;;;
;;;	     REGREST <ds,cx,bx,ax>  ; Restore
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;;
COMMENT |

If we are loading CCOM into Low DOS, and the Environment into High DOS,
then we have to set UMB_SEGMENT to the segment of COMMAND.COM in Low DOS.
This way, when we set the owner of the environment, it'll point to the
Low DOS version of COMAND.COM

Note: This won't work for an EXE program whose starting CS is not
      the loading segment.

|

	 REGSAVE <bx>		; Save register

	 test	 LCL_FLAG,@LCL_CCOM ; Moving CCOM high?
	 jnz	 @F		; Jump if COMMAND.COM high

	 test	 LCL_FLAG,@LCL_ENVIRON ; Moving ENV high?
	 jz	 @F		; Jump if environment low

	 mov	 bx,LOADDBG.LOADDBG_CSIP.VVSEG ; Get initial CS of COMMAND.COM
	 mov	 UMB_SEGMENT,bx ; Set for later MAC owner
@@:
	 REGREST <bx>		; Restore register

	 call	 PATCH_ENV_LOADER ; Patch the environment loader
	 jc	 CCOM_PATCH_ERR ; Jump if we couldn't patch it

; Set the program's Terminate address just in case it really does terminate

	 call	 SET_PSP_TERM	; Set PSP Terminate Address

; Prepare COMMAND.COM's initial segment registers

	 mov	 ax,LOADDBG.LOADDBG_CSIP.VVOFF ; Get initial IP
	 mov	 FJI_OFF1,ax	; Set IP for far jump

	 mov	 ax,LOADDBG.LOADDBG_CSIP.VVSEG ; Get initial CS
	 mov	 FJI_SEG1,ax	; Set CS for far jump

	 jmp	 $+2		; Flush the Pre-Fetch Queue

	 mov	 ss,LOADDBG.LOADDBG_SSSP.VVSEG ; Get initial SS
	 mov	 sp,LOADDBG.LOADDBG_SSSP.VVOFF ; ...	     SP

	 cmp	 FILE_HEAD.EXE_SIGN,@EXE_SIGN ; Izit an EXE file?
	 jne	 short @F	; Jump if not

	 sub	 ax,10h 	; Back off to PSP for EXE file
@@:
	 mov	 ds,ax		; Load COMMAND.COM's initial registers
	 mov	 es,ax		; ...

; Note: We can't release the UMB yet, we need it for the environment patch
;	which will be called regardless of whether we're moving the master
;	environment ot a UMB or not.


; Transfer control to COMMAND.COM

	 db	 @OPCOD_JMPF	; Return to original code
FJI_OFF1 dw	 ?		; Offset to return to
FJI_SEG1 dw	 ?		; Segment ...


; [[----------------------------------------------------]]

; This is the emergency return address in case COMMAND.COM (or whatever
; we load into the UMB) decides to return to its caller.  This will
; happen if COMMAND.COM fails to load, or the program being loaded is
; not COMMAND.COM, but some INSTALL= TSR that slipped by us.

; What we do here is to turn ourselves back on again, re-install our
; interrupt 21h handler, and then IRET back to the caller, whom we hope
; will call us again with the real command processor load request.

; Note: We'll have to RESIZE the SHARE UMB, then allocate a new
; UMB for COMMAND.COM

FCN4B_NEWRET::
	 mov	 ss,SAVE_SSSP.VVSEG ; Reload SS:SP
	 mov	 sp,SAVE_SSSP.VVOFF ; ...
	 mov	 ds,SAVE_DS	; ...
	 mov	 es,SAVE_ES	; ...

	 call	 UNLINK_MAC	; Un-Link CCOM from the Low DOS chain

	 test	 LCL_FLAG,@LCL_PROG_SHARE ; Did we just load SHARE?
	 jnz	 LOAD_CCOM_4D_IRET ; Jump if so (HARPO is all done)

	 REGSAVE <ax,bx,dx,ds,es> ; Save registers

	 and	 LCL_FLAG,not (@LCL_OFF) ; Turn us back on again

	 mov	 ax,3521h	; DOS: Get interrupt 21h vector
	 int	 21h		; Get the vector (into ES:BX)

	 mov	 OLDINT21_VEC.VVOFF,bx ; Save original handler
	 mov	 OLDINT21_VEC.VVSEG,es ; ...

	 push	 cs		; Address our own code segment
	 pop	 ds		; ... via DS

	 mov	 ax,2521h	; DOS: Set interrupt vector function
	 lea	 dx,LOAD_CCOM_HI ; Resident offset of handler
	 int	 21h		; Set interrupt vector in AL to DS:DX

	 and	 LCL_FLAG,not (@LCL_REL21) ; Mark as rehooking this interrupt

	 REGREST <es,ds,dx,bx,ax> ; Restore registers

	 jmp	 LOAD_CCOM_4D_IRET ; Return to caller (CONFIG.SYS parser)


; [[----------------------------------------------------]]

CCOM_PATCH_ERR:

COMMENT |

If we get to here, we can not load COMMAND.COM high becuase we can not
find COMMAND.COM's environment loader.
We'll have to unpatch the COMMAND.COM loader and then let DOS
load COMMAND.COM where it likes (in Low memory).

|

	 REGSAVE <ax,dx,ds>	; Save registers

	 test	 LCL_FLAG,@LCL_TEST ; Are we doing the GETSIZE thing?
	 jnz	 @F		; Jump if so (skip complaint message)

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ah,09h 	; DOS: Print String function
	 lea	 dx,MSG_XENV	; Can't find environment message
	 int	 21h		; Tell 'em we couldn't find enviroment loader

@@:
	 REGREST <ds,dx,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

; Remove CCOM from High DOS (it'll be loaded low in a minute)

	 REGSAVE <ax,bx,ds>	; Save registers

	 mov	 ah,@GETPS0	; DOS: Get current PSP function (51h)
	 int	 21h		; Get current PSP into BX

	 dec	 bx		; Address the MAC entry
	 mov	 ds,bx		; ... via DS

	 mov	 ds:[MAC_STR.MAC_OWNR],0 ; CCOM, be free!

	 REGREST <ds,bx,ax>	; Restore registers


	 jmp	 CCOM_ERR_XMSG	; Continue on with error code


; [[----------------------------------------------------]]

CCOM_LOAD_ERR:

COMMENT |

If we got here, COMMAND.COM failed to load in the place that we
provided for it.  Print a message and load it in convenitonal memory.

This possible function 4B error codes in AX are ...
* (01) Function number invalid
* (02) File not found
* (05) Access denied - NAV could cause this error
* (08) Insufficient memory
* (0A) Environment invalid
* (0B) Format invalid

|

	 REGSAVE <ax,dx,di,ds,es> ; Save registers

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

	 cmp	 ax,8		; Izit "Insufficient memory error"
	 je	 DISP_ERR8	; Jump if so

	 push	 cs		; Address our resident data
	 pop	 es		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

	 lea	 di,MSG_XLOAD1	; Error code address (in error string)
	 call	 FMT_WORD	; Format error code

	 mov	 ah,09h 	; DOS: Print String function
	 lea	 dx,MSG_XLOAD	; Couldn't load CCOM message
	 int	 21h		; Tell 'em we couldn't load COMMAND.COM

	 jmp	 @F		; Join common code

DISP_ERR8:
	 mov	 ah,09h 	; DOS: Print String function
	 lea	 dx,MSG_XMEM	; Not enough memory message
	 int	 21h		; Tell 'em we couldn't load COMMAND.COM
@@:

	 REGREST <es,ds,di,dx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it
	 assume  es:nothing	; Tell the assembler about it

CCOM_ERR_XMSG:

COMMENT |

If we get to here, we have already printed an appropriate error message.
We'll have to unpatch the COMMAND.COM loader and then let DOS load
COMMAND.COM where it likes.

|

; Release CCOM's LSEG entry
; It is not linked in the LSEG chain, but is still in memory.

	 REGSAVE <ax,ds>	; Save registers

	 mov	 ax,LSEG_SEG	; Address the LSEG entry
	 dec	 ax		; Address the MAC entry
	 mov	 ds,ax		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ds:[MAC_STR.MAC_OWNR],0 ; LSEG, be free!

	 REGREST <ds,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

; Restore the MAC chain to its pre-HARPO state

	 call	 UNLINK_MAC	; Un-Link CCOM from the Low DOS chain

; Uninstall the transient UMB code/data

	 call	 REL_UMB	; Release our own code/data

	 mov	 ax,4B00h	; Prepare for normal COMMAND.COM load
	 mov	 bx,EXEC_BLOCK_ADDR ; Address EXEC block
	 mov	 dx,EXEC_PROG_NAME ; Address program name

	 jmp	 LOAD_CCOM_CONT ; Continue with Low memory load

	 assume  ds:nothing,es:nothing,ss:nothing

LOAD_CCOM_HI	 endp		; End LOAD_CCOM_HI procedure


;***************************************************************************

	 NPPROC  ALLOC_LOWSEG -- Allocate Low Segment For COMMAND.COM
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

If this is MS-DOS 7 and we're loading COMMAND.COM low, we need to
reserve a place for it in low DOS so it doesn't fragment memory.  What
happens is COMMAND.COM loads in low DOS, then reallocates itself in a
context in which it expects it to go into high DOS, but we don't want
it to go there (because our optimization algorithm says that's not
optimal).  Thus, in this context, we allocate a suitable size chunk
before the following 4B01h call, and then free the chunk immediately
afterwards.

|

	 REGSAVE <ax,bx>	; Save for a moment

	 cmp	 MODELNO,2	; Izit MS-DOS 7.00?
	 jne	 short @F	; Jump if not

	 cmp	 CCOM_REGION,0	; Is this a Low DOS request?
	 jne	 short @F	; Jump if not

	 mov	 bx,16*1024/16	; Arbitrary but big enough size chunk
	 DOSCALL @GETMEM	; Request DOS service, AX = segment
	 jc	 short @F	; Jump if it failed???

	 mov	 CCOM_LOWSEG,ax ; Save for later use
@@:
	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ALLOC_LOWSEG endp		; End ALLOC_LOWSEG procedure

;***************************************************************************

	 NPPROC  FREE_LOWSEG -- Free Low Segment For COMMAND.COM
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Free low segment for COMMAND.COM

|

	 REGSAVE <ax,es>	; Save for a moment

	 cmp	 CCOM_LOWSEG,0	; Izit allocated?
	 je	 short @F	; Jump if not

	 mov	 es,CCOM_LOWSEG ; Get the segment to free
	 assume  es:nothing	; Tell the assembler about it
	 DOSCALL @RELMEM	; Free the block
				; Ignore return code
@@:
	 REGREST <es,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FREE_LOWSEG endp		; End FREE_LOWSEG procedure

;***************************************************************************

	 NPPROC  LOAD_ENV_HI -- LOAD_ENV_HI Procedure
	 assume  ds:nothing,es:nothing,ss:nothing

COMMENT |

Load the master environment into a UMB (or low DOS)
* Patch the environment pointer in the fake PSP
* Remove the DeadMan switch

|

	 SWATTER		; Call debugger if requested

; Restore the MAC chain (before we do any memory requests)

	 call	 UNLINK_MAC	; Unlink CCOM from the Low DOS chain

; Allocate a conventional memory block for the fake PSP to reside
; unless we're running under MS-DOS 7.00 (a.k.a. Win95) as they
; haven't released their low DOS memory as yet.  We'll do this in
; ALLOC_CCOM_HI.

	 cmp	 MODELNO,2	; Izit MS-DOS 7.00?
	 je	 short @F	; Jump if so (we'll do it later)

	 call	 CREATE_FAKE_PSP ; Create phony MAC & PSP entry for CCOM
@@:

; Find the resident size of program

	 call	 GET_RSIZE	; Get the program's resident size

; Find the initialization size of this file

	 call	 GET_ISIZE	; Determine the program's initialization size

	 push	 bp		; Save register
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,ds>	; Save registers

	 call	 VALIDATE_ENVLEN ; Ensure the length is OK

; Allocate High DOS memory for the environment

	 call	 ALLOC_ENV	; Allocate memory for the environment
	 nop			; Make debugging easy

; Link in COMMAND.COM's LSEG entry

	 cmp	 MODELNO,2	; Izit MS-DOS 7.00?
	 je	 short @F	; Jump if so (we'll do it later)

	 call	 LINK_LSEG	; Link in COMMAND.COM's LSEG entry
				; after all LSEG fields are filled in
@@:

; Remove environment loader patch in COMMAND.COM
; DS is assumed to point to the environment loader code (9087)

	 mov	 bx,ENV_ADDR	; Address the patch

	 mov	 ax,WPTR ENV_SAVE ;
	 mov	 ds:[bx]+0,ax ; Restore patch

	 mov	 ax,WPTR ENV_SAVE+2 ;
	 mov	 ds:[bx]+2,ax ; Restore patch

	 mov	 al,BPTR ENV_SAVE+4 ;
	 mov	 ds:[bx]+4,al ; Restore patch

; Remove the DeadMan switch from the profile

	 REGSAVE <ax,bx,cx,es>	; Save registers

	 mov	 ah,48h 	; DOS: Allocate memory
	 mov	 bx,1000h	; Request 64 KB
	 int	 21h		; Allocate the memory for profile buffer
	 jc	 @F		; Jump if error

	 mov	 cx,ax		; Segment we can use for Read Buffer
	 call	 REMOVE_DEAD	; Remove the DeadMan switch

	 mov	 es,ax		; Segment to release
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ah,49h 	; DOS: Release memory
	 int	 21h		; Release the Read buffer memory

@@:
	 REGREST <es,cx,bx,ax>	; Restore registers
	 assume  es:nothing	; Tell the assembler about it


; Uninstall the transient code/data
; unless we're running under MS-DOS 7.00 (a.k.a. Win95) as there's
; more to do.  We'll do this in ALLOC_CCOM_HI.

	 cmp	 MODELNO,2	; Izit MS-DOS 7.00?
	 je	 short @F	; Jump if so (we'll do it later)

	 call	 REL_UMB	; Release ourselves (be free!)
@@:

; Patch the return IP so that we can repeat the (now unpatched) instructions
; (except for the interrupt 21 instruction which we just simulated)

	 sub	 [bp].STACK_F.RET_IP,3 ; Skip the Int 21 (alloc) instruction

	 REGREST <ds,bx,ax>	; Restore registers

	 pop	 bp		; Restore register

	 mov	 ax,ENV_SEGMENT ; Segment for environment

	 clc			; Simulate interrupt 21 (alloc) success

	 retf			; Return to CONFIG.SYS processor

	 assume  ds:nothing,es:nothing,ss:nothing

LOAD_ENV_HI	 endp		; End LOAD_ENV_HI procedure


;****************************************************************************

	 NPPROC  VALIDATE_ENVLEN -- VALIDATE_ENVLEN procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Make sure that the ENV length is OK

On entry:
BX	=	Para size of the environment

|

	 REGSAVE <ax,dx,di,ds>	; Save registers

	 cmp	 ENV_REGION,0	; Is the environment loading High?
	 je	 EXIT		; Jump if not

; Note that Maximize has to save the environment value in a manner
; consistent with everything else- the MAC paragraph isn't included.
; The EPAR0 and EPAR1 values, however, DO include the MAC paragraph.
;;;;;;;  inc	 bx		; Add MAC paragraph for comparison
	 cmp	 bx,ENV_LEN	; Is the requested size correct?
	 je	 EXIT		; Jump if so

; Display error message

	 push	 cs		; Get data segment
	 pop	 ds		; Address for STROUT
	 assume  ds:nothing	; Tell the assembler

	 lea	 di,MSG_MAXIMIZE1 ; Environment size is different
	 call	 DISP_COPY	; Display copyright and message

	 DOSCALL @STROUT,MSG_ENV_SIZE ; Display second part of message
	 DOSCALL @STROUT,MSG_MAXIMIZE2 ; Third part

	 call	 PRESSANY	; Wait for acknowledgement

EXIT:
	 REGREST <ds,di,dx,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
VALIDATE_ENVLEN  endp		; End VALIDATE_ENVLEN procedure


;****************************************************************************

	 NPPROC  ALLOC_CCOM -- ALLOC_CCOM procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Allocate space for COMMAND.COM (or SHARE.EXE)

Note: If no region was specified, we should try to allocate from the
      biggest region.

|

	 REGSAVE <ax,bx,cx,dx,ds> ; Save registers

; If this is MS-DOS 7.00 (a.k.a. Win95), we use another mechanism
; to load COMMAND.COM high

	 cmp	 MODELNO,2	; Izit MS-DOS 7.00?
	 jne	 short @F	; Jump if not

	 call	 CREATE_FAKE_PSP ; Create phony MAC & PSP entry for CCOM

	 jmp	 EXIT		; Join common exit code

@@:
	 cmp	 CCOM_REGION,0	; Is this a Low DOS request?
	 je	 CCOM_LOW	; Jump if so

; Make sure our code/data is out of the way

	 mov	 al,CCOM_REGION ; Requested region (for CCOM)
	 mov	 CURR_REG,al	; ...

	 call	 TRANSFER_BOOT	; Move transient code out of the way
	 nop			; Make debugging easy

; Find the largest hole in particular region
; Note: This loop is time consuming and can be optimized for Reg0, etc...

	 mov	 bx,((384*1024)/16) ; Start loop with largest possible hole
NEXT_HOLE:
	 mov	 cl,CCOM_REGION ; Region number of request
	 xor	 ch,ch		; Extend region number to 16 bits

	 call	 GETMEM_REG	; Find space in specified region
	 jnc	 CCOM_HIGH	; Jump if we found a big hole
				; Returns AX = MAC entry of free space

	 dec	 bx		; Try one smaller paragraph
	 jnz	 NEXT_HOLE	; Jump if hole size is not zero

; Tell 'em we couldn't find room in High DOS

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

	 REGSAVE <di>		; Save registers

	 lea	 di,MSG_XMEM	; Not enough memory message
	 call	 DISP_COPY	; Display copyright and message

	 REGREST <di>		; Restore registers

;----------------
; Low DOS request
;----------------

CCOM_LOW:

; Allocate Low DOS memory for the LSEG entry

	 mov	 ah,@GETMEM	; DOS: Allocate memory (48h)
	 mov	 bx,@LSEGPARA	; Number of paragraphs
	 int	 21h		; Allocate LSEG emmory
	 jnc	 CCOM_LOW1	; Jump if success
				; Returns AX = Segment of new memory

; Print error message if no available memory in Low DOS

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

	 REGSAVE <di>		; Save

	 lea	 di,MSG_LOWMEM	; Low Memory message
	 call	 DISP_COPY	; Display copyright and message

	 REGREST <di>		; Restore

	 DOSCALL @STROUT,MSG_LOWMEM_CCOM ; CCOM failure message

	 jmp	 $		; Wait for Hell to freeze over

CCOM_LOW1:
	 mov	 LSEG_SEG,ax	; Save as LSEG segment (in Low DOS)

; Determine where DOS will load COMMAND.COM (needed for GETSIZE pattern)

	 mov	 ah,@GETMEM	; DOS: Allocate memory (48h)
	 mov	 bx,-1		; Number of paragraphs
	 int	 21h		; Allocate all of memory

	 mov	 ah,@GETMEM	; DOS: Allocate memory (48h)
;;;;;;;; mov	 bx,??		; Number of paragraphs (already set)
	 int	 21h		; Allocate all of memory

	 mov	 UMB_SEGMENT,ax ; Save as CCOM segment (in Low DOS)

	 REGSAVE <es>		; Save registers

	 mov	 bx,ax		; Save free segment for later
	 mov	 es,ax		; Segment to free
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ah,@RELMEM	; DOS: Release memory (49h)
	 int	 21h		; Release the memory

	 REGREST <es>		; Restore registers
	 assume  es:nothing	; Tell the assembler about it

; Save the FILL_MEM para count

	 mov	 ax,FLOAT_SEG	; Get Top of DOS segment
	 dec	 ax		; Minus one (don't overwrite transient code)
	 sub	 ax,bx		; Minus free segment location

	 mov	 EXEC_PRGNPAR,ax ; Save number of paragraphs

; Turn off High DOS loading
; Note: This flag is needed to be set for ENV loader poatching
;	even if CCOM goes low

;;;;;;;; and	 LCL_FLAG,not (@LCL_CCOM) ; Move CCOM to Low DOS

	 jmp	 EXIT		; Join common exit code

;----------------
; High DOS request
;----------------

CCOM_HIGH:

; Ensure that CCOM can fit in this High DOS memory region

	 mov	 ds,ax		; Address MAC of avail segment
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 dx,ds:[MAC_STR.MAC_NPAR] ; Get size of region

	 cmp	 dx,CCOM_LEN	; Is the region big enough?
	 jae	 @F		; Jump if so

; Make sure our code/data is out of the way

	 mov	 CCOM_REGION,0	; New requested region (for CCOM)
	 mov	 CURR_REG,0	; ...

	 call	 TRANSFER_BOOT	; Move transient code out of the way
	 nop			; Make debugging easy

	 or	 LSEG.LSEG_FLAG,@LSEG_GSIZE ; Mark as forced GESIZE

	 jmp	 CCOM_LOW	; Join common low memory request code

@@:
	 call	 FINI_CCOM	; Finish allocation of COMMAND.COM
EXIT:
	 REGREST <ds,dx,cx,bx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
ALLOC_CCOM	 endp		; End ALLOC_CCOM procedure


;****************************************************************************

	 NPPROC  FINI_CCOM -- Finish Allocation For COMMAND.COM
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

On entry:

AX	 =	 segment of MAC entry

On exit:

AX	 =	 segment of COMMAND.COM

|

	 REGSAVE <bx,cx,dx,ds>	; Save registers

; Setup LSEG's MAC entry

	 mov	 ds,ax		; Address the LSEG's MAC entry
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 dl,ds:[MAC_STR.MAC_TYPE] ; Get the MAC type
	 mov	 ds:[MAC_STR.MAC_TYPE],'M' ; Another MAC will follow

	 mov	 cx,@MAC_LSEG	; Get LSEG owner entry
	 xchg	 cx,ds:[MAC_STR.MAC_OWNR] ; Mark as LSEG entry

	 mov	 bx,ds:[MAC_STR.MAC_NPAR] ; Get the old length
	 mov	 ds:[MAC_STR.MAC_NPAR],@LSEGPARA ; New length

; Save the segment of the LSEG (for later)

	 inc	 ax		; Skip over MAC entry
	 mov	 LSEG_SEG,ax	; Save as address of LSEG

; Setup the program's MAC entry

	 add	 ax,@LSEGPARA	; Skip over LSEG entry

	 mov	 ds,ax		; Address the LSEG's MAC entry
	 assume  ds:nothing	; Tell the assembler about it

	 sub	 bx,@LSEGPARA	; Minus the LSEG entry
	 dec	 bx		; Minus the MAC entry

	 mov	 ds:[MAC_STR.MAC_TYPE],dl ; The new type (same as old one)
	 mov	 ds:[MAC_STR.MAC_OWNR],cx ; Same owner as before
	 mov	 ds:[MAC_STR.MAC_NPAR],bx ; The new MAC length (old-5)

; Save the segment of the program (for later)

	 inc	 ax		; Skip over MAC entry
	 mov	 UMB_SEGMENT,ax ; Save for later

; Save the FILL_MEM para count

	 mov	 EXEC_PRGNPAR,bx ; Save number of paragraphs

	 REGREST <ds,dx,cx,bx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FINI_CCOM endp			; End FINI_CCOM procedure


;****************************************************************************

	 FPPROC  ALLOC_CCOM_HI -- Allocate COMMAND.COM High
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Allocate COMMAND.COM high for MS-DOS 7.00 (a.k.a. Win95)

On entry:

BX	 =	 # paras to allocate
SS:SP	 ==>	 return address

On exit:

CF	 =	 0 if the allocation succeeded
	 =	 1 if not

|

	 sti			; Allow interrupts

	 call	 FREE_LOWSEG	; Free low DOS segment if necessary

	 add	 bx,@LSEGPARA+1 ; Add in size of LSEG entry

	 cmp	 CCOM_REGION,0	; Is this a Low DOS request?
	 je	 CCOM_HI_LOW	; Jump if so

; Make sure our code/data is out of the way

	 mov	 al,CCOM_REGION ; Requested region (for CCOM)
	 mov	 CURR_REG,al	; ...

	 call	 TRANSFER_BOOT	; Move transient code out of the way
	 nop			; Make debugging easy

	 push	 cx		; Save registers
	 mov	 cl,CCOM_REGION ; Region number of request
	 xor	 ch,ch		; Extend region number to 16 bits

	 call	 GETMEM_REG	; Find space in specified region
	 pop	 cx		; Restore
	 jnc	 CCOM_HIGH	; Jump if we found a hole
				; Returns AX = MAC entry of free space
; Tell 'em we couldn't find room in High DOS

	 REGSAVE <di,ds>	; Save registers

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

	 lea	 di,MSG_XMEM	; Not enough memory message
	 call	 DISP_COPY	; Display copyright and message

	 REGREST <ds,di>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it
CCOM_HI_LOW:

; Because the MAC algorithm might be set to allocate high, we need
; to save it and reset it to low

	 mov	 al,@MACALG_GETSTR ; Return allocation strategy in AX
	 DOSCALL @MACALG	; Request DOS service
	 mov	 cx,ax		; Save the strategy to restore later

	 push	 bx		; Save for a moment

	 mov	 bx,@MACALG_FFLO ; First fit low only
	 mov	 al,@MACALG_SETSTR ; Set allocation strategy to BX
	 DOSCALL @MACALG	; Request DOS service

	 pop	 bx		; Restore

; Allocate Low DOS memory for CCOM and the LSEG entry

	 DOSCALL @GETMEM	; Request DOS service
				; Returns AX = Segment of new memory
	 pushf			; Save flags (CF in particular)
	 REGSAVE <ax,bx>	; Save for a moment
	 mov	 bx,cx		; Get the original strategy
	 mov	 al,@MACALG_SETSTR ; Set allocation strategy to BX
	 DOSCALL @MACALG	; Request DOS service
	 REGREST <bx,ax>	; Restore
	 popf			; Restore CF
	 jnc	 CCOM_HIGH0	; Jump if success

; Print error message if no available memory in Low DOS

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

	 REGSAVE <di>		; Save

	 lea	 di,MSG_LOWMEM	; Low Memory message
	 call	 DISP_COPY	; Display copyright and message

	 REGREST <di>		; Restore

	 DOSCALL @STROUT,MSG_LOWMEM_CCOM ; CCOM failure message

	 jmp	 $		; Wait for Hell to freeze over

CCOM_HIGH0:
	 dec	 ax		; Back off to MAC entry
CCOM_HIGH:
	 call	 FINI_CCOM	; Finish allocation of COMMAND.COM

; Note RPARA does not count in its MAC para, but does count in
; the LSEG (and its MAC para)

	 mov	 LSEG.LSEG_RPARA,bx ; Save in LSEG

	 sub	 bx,@LSEGPARA+1 ; Subtract out size of LSEG entry

; Note LSEG_ASIZE, LSEG_ISIZE, and LSEG_LSIZE do not count
; in the size of the LSEG

	 REGSAVE <ax,cx,dx>	; Save for a moment

	 xor	 dx,dx		; Zero to use DX:AX as dword
	 mov	 ax,bx		; Copy size in paras
	 mov	 cx,4		; # bits in a nibble
@@:
	 shl	 ax,1		; Shift upper nibble into DX
	 rcl	 dx,1		; ...
	 loop	 @B		; Jump if more bits to shift

; Round up initialization size to a para boundary

	 add	 ax,16-1	; Add in slop
	 adc	 dx,0		; In case of overflow
	 and	 ax,not (16-1)	; Round to boundary

	 mov	 LSEG.LSEG_ASIZE.EGP_STR.ELO,ax ; Save as actual SIZE= size
	 mov	 LSEG.LSEG_ASIZE.EGP_STR.EHI,dx ; ...

	 mov	 LSEG.LSEG_ISIZE.EGP_STR.ELO,ax ; Save as initialization size
	 mov	 LSEG.LSEG_ISIZE.EGP_STR.EHI,dx ; ...

	 mov	 LSEG.LSEG_LSIZE.EGP_STR.ELO,ax ; Save as load size
	 mov	 LSEG.LSEG_LSIZE.EGP_STR.EHI,dx ; ...

	 REGREST <dx,cx,ax>	; Restore

; Split the allocated segment into the allocated part and above

	 pusha			; Save all GP registers
	 REGSAVE <ds,es>	; Save for a moment

; Move the LSEG to its new home

	 mov	 es,ax		; Address the segment
	 assume  es:nothing	; Tell the assembler about it

	 push	 cs		; Get current segment
	 pop	 ds		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 cx,(size LSEG_STR) ; Size of LSEG structure (in bytes)
	 lea	 si,LSEG	; Source offset
	 xor	 di,di		; Destin ...

     rep movsb			; Move the LSEG to its new home

	 mov	 cx,ax		; Save segment
	 dec	 ax		; Back up to MAC entry

	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 dl,ds:[MAC_STR.MAC_TYPE] ; Get the MAC type
	 mov	 ax,ds:[MAC_STR.MAC_NPAR] ; Get # paras in segment
	 dec	 ax		; Less MAC para
	 mov	 ds:[MAC_STR.MAC_NPAR],bx ; Save actual # paras requested

	 sub	 ax,bx		; Less actual # paras requested
	 jbe	 short @F	; Jump if it came out even

	 mov	 ds:[MAC_STR.MAC_TYPE],@MAC_MID ; Mark as middle entry
	 add	 cx,bx		; Plus actual # paras requested
	 mov	 ds,cx		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ds:[MAC_STR.MAC_TYPE],dl ; Copy preceding type
	 mov	 ds:[MAC_STR.MAC_OWNR],@MAC_FREE ; Mark as free
	 mov	 ds:[MAC_STR.MAC_NPAR],ax ; Save as # paras
@@:
	 REGREST <es,ds>	; Restore
	 assume  ds:nothing	; Tell the assembler about it
	 popa			; ...

	 call	 LINK_LSEG	; Link in COMMAND.COM's LSEG entry
				; after all LSEG fields are filled in
	 call	 COPY_PSP	; Copy COMMAND.COM's PSP to FAKE_PSP

	 clc			; Mark as successful
EXIT:

; Uninstall the transient code/data

	 pushf			; Save flags (CF is significant)
	 call	 REL_UMB	; Release ourselves (be free!)

; Restore the original holder of this interrupt

	 REGSAVE <ax,ds>	; Save for a moment

	 mov	 ax,seg INTVEC	; Get segment of IVT
	 mov	 ds,ax		; Address it
	 assume  ds:INTVEC	; Tell the assembler about it

	 pushf			; Save flags
	 cli			; Nobody move while we change the IVT

	 mov	 ax,OLDINT04_VEC.VOFF ; Get the offset
	 mov	 INT00_VEC.VECTOR.VOFF[@MSINTX*(type INT00_VEC)],ax

	 mov	 ax,OLDINT04_VEC.VSEG ; Get the segment
	 mov	 INT00_VEC.VECTOR.VSEG[@MSINTX*(type INT00_VEC)],ax

	 popf			; Restore

; Because we have allocated new space for COMMAND.COM, we need
; to setup the appropriate fields in the low PSP.

	 cmp	 FAKE_PSP,0	; Has it been initialized?
	 je	 short @F	; Jump if not

	 mov	 ax,UMB_SEGMENT ; Get segment of COMMAND.COM

	 mov	 ds,FAKE_PSP	; Get segment of fake PSP
	 assume  ds:PSPGRP	; Tell the assembler about it

	 mov	 PSP_TERMINATE.VSEG,ax ; Save in low PSP
	 mov	 PSP_CTRL_BREAK.VSEG,ax ; ...
	 mov	 PSP_CRIT_ERROR.VSEG,ax ; ...
	 mov	 PSP_CTRL_PSP,ax ; ...
	 mov	 PSP_FILE_TAB_PTR.VSEG,ax ; ...
@@:
	 REGREST <ds,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 popf			; Restore

	 retf	 2		; Return to caller, popping flags

	 assume  ds:nothing,es:nothing,ss:nothing

ALLOC_CCOM_HI endp		; End ALLOC_CCOM_HI procedure

;****************************************************************************

	 NPPROC  ALLOC_ENV -- ALLOC_ENV procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Allocate space for the master environment

On entry:
BX	=	Environment size in paras

On exit:

|

	 REGSAVE <ax,bx,cx,dx,si,di,bp,es> ; Save registers

; Decide from which memory pool we should honor this request

	 mov	 bp,bx		; Save environment size (in paras)

	 test	 LCL_FLAG,@LCL_ENVIRON ; Moving the environment?
	 jz	 ENV_LO 	; Jump if environment to be Low

	 cmp	 ENV_REGION,0	; Region zero?
	 je	 ENV_LO 	; Jump if so (load it low)

;--------------------------------
; High DOS request
;--------------------------------

; Move our transient code out of the way

	 mov	 al,ENV_REGION	; Requested region (for environment)
	 mov	 CURR_REG,al	; ...

	 mov	 al,CCOM_REGION ; Region of COMMAND.COM is off limits to
	 mov	 CCOM_XREG,al	; ... our transient code (due to CCOM bug)

	 call	 TRANSFER_BOOT	; Move transient code out of the way
	 nop			; Make debugging easy

; Allocate region specific High DOS memory

;;;;;;;; mov	 bx,??		; Size of environment needed (already set)
	 mov	 cl,ENV_REGION	; Region number of request
	 xor	 ch,ch		; Extend region number to 16 bits

	 call	 GETMEM_REG	; Find space in specified region
	 jc	 ENV_LO 	; Jump if no room (try Low DOS)
				; Returns AX = MAC entry of free space

; Save info on segment of environment

	 mov	 ENV_SEGMENT,ax ; Save UMB segment
	 inc	 ENV_SEGMENT	; Skip over the MAC entry

;;;;;;;; mov	 ax,??		; Segment of MAC entry (already set)
	 mov	 cx,bp		; Size in paras
	 call	 ALLOC_MAC	; Allocate a MAC at this address

; COMMAND.COM should own the master environment.  In DOS 6, we need to
; hunt for the first self-owned MAC.  That'll be the actual PSP.
; UMB_SEGMENT:0 MAC
; Temporary environment (CONFIG=, c:\command.com)
; PSP MAC (created by DOS)
; COMMAND.COM PSP, etc.

	 mov	 ax,UMB_SEGMENT ; Address starting MAC entry + 1 for COMMAND.COM
	 dec	 ax		; Back off to MAC entry
AENV_FINDPSP:
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 mov	 bl,es:[MAC_STR.MAC_NAME][0] ; Get first byte of name
	 cmp	 ax,UMB_SEGMENT ; Is this the UMB_SEGMENT?
	 je	 short @F	; Jump if so

	 sub	 bl,bl		; Invalidate name

	 mov	 es:[MAC_STR.MAC_BACK],0 ; Clear back link
	 mov	 es:[MAC_STR.MAC_DRV],0 ; Clear drives
@@:
	 inc	 ax		; Skip to alleged PSP
	 cmp	 ax,es:[MAC_STR.MAC_OWNR] ; Does it own itself?
	 je	 short @F	; Jump if so (it's the PSP)

	 mov	 es:[MAC_STR.MAC_NAME][0],bl ; Clear name
	 add	 ax,es:[MAC_STR.MAC_NPAR] ; Skip to next MAC entry

	 cmp	 es:[MAC_STR.MAC_TYPE],@MAC_END ; Izit the end of the chain?
	 jne	 short AENV_FINDPSP ; Keep looking if not

@@:
	 mov	 bx,ENV_SEGMENT ; Get environment segment
	 dec	 bx		; Back off to MAC entry
	 mov	 es,bx		; Address the environment's MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[MAC_STR.MAC_OWNR],ax ; Set owner to COMMAND.COM PSP

; Set back link to COMMAND.COM's LSEG entry.  Note we don't also set
; the OWNRHI field in the LSEG because the LSEG already belongs to
; COMMAND.COM's PSP.  We're just setting the back link here so we can
; display something for the util/m output.
	 mov	 ax,LSEG_SEG	; Segment of LSEG entry
	 mov	 es:[MAC_STR.MAC_BACK],ax ; Set back link
	 mov	 es:[MAC_STR.MAC_DRV],0 ; Clear drive field
	 mov	 es:[MAC_STR.MAC_NAME],0 ; Clear name field

	 jmp	 ENV_COMMON	; Join common code

;--------------------------------
; Low DOS request
;--------------------------------

; Allocate Low DOS memory for the environment

ENV_LO:
	 mov	 ah,48h 	; DOS: Allocate memory function
;;;;;;;; mov	 bx,????	; Amount of memory needed (already set)
	 int	 21h		; Simulate the conventional memory alloc
	 jnc	 @F		; Jump if success
				; Return AX = Allocated Memory block
				;	 BX = largest block (if error)

; Print error message if no available memory in Low DOS

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

	 lea	 di,MSG_LOWMEM	; Low Memory message
	 call	 DISP_COPY	; Display copyright and message

	 DOSCALL @STROUT,MSG_LOWMEM_ENV ; ENV failure message

	 jmp	 $		; Wait for Hell to freeze over

@@:
	 mov	 ENV_SEGMENT,ax ; Save Low memory segment

;---------------------------------------
; Common code to High or Low environment
;---------------------------------------

ENV_COMMON:

; Fill in the environment size in COMMAND.COM's LSEG entry
; Skip this if MAXIMIZE is never to know about the environment

	 test	 LCL_FLAG,@LCL_XENV ; Never move the environment High?
	 jnz	 @F		; Jump if so (E=NOLOADHI)

	 inc	 bp		; Add MAC paragraph for EPAR0 and EPAR1
	 mov	 LSEG.LSEG_EPAR0,bp ; Set environment size
	 mov	 LSEG.LSEG_EPAR1,bp ; ...
@@:


; Fill in the environment pointer in our fake PSP (environment in High DOS)

	 test	 LCL_FLAG,@LCL_NOPSP ; Jump if ...
	 jnz	 @F	; ... we don't need to create a fake PSP

	 cmp	 FAKE_PSP,0	; Has it been initialized?
	 je	 @F		; Jump if not

	 mov	 es,FAKE_PSP	; Get segment of fake PSP
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,ENV_SEGMENT ; Get environment segment
	 mov	 es:[002Ch],ax	; ...
@@:


	 REGREST <es,bp,di,si,dx,cx,bx,ax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
ALLOC_ENV	 endp		; End ALLOC_ENV procedure


;****************************************************************************

	 NPPROC  CHECK_SHARE -- CHECK_SHARE procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Check on SHARE.EXE being loaded

On entry:
DS:DX	=>	Program name being loaded

On exit:
CF	=	0 Load this program High (even if it is SHARE)
		1 This is SHARE, load it in Low DOS

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

	 and	 LCL_FLAG,not (@LCL_PROG_SHARE) ; Assume this is not SHARE

; Address DOS' data segment

	 mov	 ax,ds		; Address DOS' data segment
	 mov	 es,ax		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

; Find start of filename

	 xor	 al,al		; The name should be null terminated
	 mov	 cx,-1		; Look this far
	 mov	 di,dx		; Address start of pathname
   repne scasb			; Look for the end of the file

; Comapre filename to SHARE.EXE

	 sub	 di,@SHARE_LEN+1 ; Skip back past name and NUL
	 lea	 si,SHARE_NAME	; Address our copy of the name
	 mov	 cx,@SHARE_LEN	; Length of name
    repe cmps	 BPTR PGROUP:[si],es:[di] ; Comapre 'em
	 jnz	 NOT_SHARE	; Jump if not SHARE

; The current program being loaded is SHARE

	 test	 LCL_FLAG,@LCL_CMD_SHARE ; Moving SHARE to High DOS?
	 jz	 EXIT_STC	; Jump if not

	 or	 LCL_FLAG,@LCL_PROG_SHARE ; Set flag if this is SHARE
				; ... and we're moving it High

	 jmp	 EXIT_CLC	; Join common exit code

; The current program being loaded is not SHARE

NOT_SHARE:
	 test	 LCL_FLAG,(@LCL_CCOM or @LCL_ENVIRON) ; Loading either High?
	 jz	 EXIT_STC	; Jump if not

EXIT_CLC:
	 clc			; Indicate this program goes High

	 jmp	 EXIT		; Join common exit code

EXIT_STC:
	 stc			; Indicate that this program goes low

EXIT:
	 REGREST <es,di,si,cx,ax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
CHECK_SHARE	 endp		; End CHECK_SHARE procedure


;****************************************************************************

	 NPPROC  LINK_LSEG -- LINK_LSEG procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Copy the LSEG to its real home
Link the LSEG into the LSEG chain
Set the LSEG back link in COMMAND.COM's MAC entry
Set LSEG_OWNRHI in the LSEG entry

|

	 REGSAVE <ax,bx,cx,si,di,ds,es> ; Save registers

; Address the proper segments

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 es,LSEG_SEG	; Address the LSEG destination
	 assume  es:nothing	; Tell the assembler about it

; Move the LSEG to its new home

	 mov	 cx,(size LSEG_STR) ; Size of LSEG structure (in bytes)

	 lea	 si,LSEG	; Source offset
	 xor	 di,di		; Destin ...

     rep movsb			; Move the LSEG to its new home

; Calculate the segment of LSEG and link into the chain

	 mov	 ax,LOADSEG	; Get first LSEG pointer (if any)
	 mov	 bx,es		; Segment of our LSEG entry

; Search through the chain for the end and link into it

@@:
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es:[LSEG_STR.LSEG_NEXT] ; Get next segment

	 cmp	 ax,-1		; Check for end-of-the-chain
	 jne	 @B		; Jump if there's more

; We have found the end of the LSEG chain

	 mov	 es:[LSEG_STR.LSEG_NEXT],bx ; Save as pointer to next
	 mov	 ax,es		; Save segment of previous LSEG

	 mov	 es,bx		; Address our LSEG entry
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[LSEG_STR.LSEG_PREV],ax ; Save as segment of previous LSEG

; Set the back link to the LSEG segment (not its MAC) in COMMAND.COM's MAC

	 mov	 ax,LSEG_SEG	; Get LSEG segment
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 mov	 bx,UMB_SEGMENT ; Get final location of COMMAND.COM
	 mov	 es:[LSEG_STR.LSEG_OWNRHI],bx ; Save

	 dec	 bx		; Back off to COMMAND.COM's MAC entry
	 mov	 es,bx		; Address it
	 assume  es:nothing	; Tell the assembler

	 mov	 es:[MAC_STR.MAC_BACK],ax ; Set back link to LSEG segment

EXIT:
	 REGREST <es,ds,di,si,cx,bx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
LINK_LSEG	 endp		; End LINK_LSEG procedure


;****************************************************************************

	 NPPROC  RESTORE_INT21 -- RESTORE_INT21 procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Restore the interrupt 21 value to its orignal (pre HARPO) state

If we can't do this, tell the user via a screen message

|

	 REGSAVE <ax,dx,ds>	; Save registers

	 xor	 ax,ax		; Address the IDT
	 mov	 ds,ax		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ax,cs		; Get the current segment
	 cmp	 ax,ds:[0084h]+2 ; Did it change?
	 jne	 X_REMOVE	; Jump if we can't uninstall

	 mov	 ax,ds:[0084h] ; Get the current offset
	 cmp	 ax,offset PGROUP:LOAD_CCOM_HI ; Did it change?
	 jne	 X_REMOVE	; Jump if we can't uninstall

	 lds	 dx,OLDINT21_VEC ; Original vector
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ah,@SETINT	; DOS: Set interrupt vector
	 mov	 al,21h 	; Restore interrupt 21 vector
	 int	 21h		; Set interrupt vector in AL to DS:DX

	 or	 LCL_FLAG,@LCL_REL21 ; Mark as releasing this interrupt

	 jmp	 REST_I21_OK	; Join common code (we're done restoring I21)

X_REMOVE:
	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ah,09h 	; DOS: Print String function
	 lea	 dx,MSG_XI21	; Can't restore interrupt 21h message
	 int	 21h		; Tell 'em we couldn't restore interrupt 21h

	 or	 LCL_FLAG,@LCL_XREMOVE ; We can't release our UMB now

REST_I21_OK:
	 REGREST <ds,dx,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
RESTORE_INT21	 endp		; End RESTORE_INT21 procedure


;****************************************************************************

	 NPPROC  CHECK_CCOM_NAME -- CHECK_CCOM_NAME procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Determine if this is the 4Bh call that loads the command processor
The first 4B call should be for COMMAND.COM unless HARPO is not the
last INSTALL= program.	To differentiate between COMMAND.COM and
other cases, we have to look at the segment of the filespec that
is passed in DS:DX.  Supposedly, DS will point to CONFIG_SEGMENT if
DOS is loading COMMNAND.COM, or it will point into the tokenized
CONFIG.SYS file if it is loading another INSTALL= program.

On exit:
CF	=	0 if this program is COMMAND.COM
		1 if not

Note: This check fails on DOS 4.00 without SHARE because it will
      automatically load SHARE (from DOS's DS).  We check for
      an implicit SHARE by name.

|

	 REGSAVE <ax,bx,dx,ds>	; Save registers

	 mov	 ax,ds		; Get segment of filespec

	 cmp	 ax,CONFIG_SEGMENT ; Is the file name in DOS' data?
	 je	 EXIT_CLC	; Jump if filespec is command processor
				; If so, HARPO is the last INSTALL= program

; We are not the last INSTALL= program
; Display the error message (Tell 'em to rerun MAXIMIZE)

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ah,09h 	; DOS: Print String function
	 lea	 dx,MSG_XFIRST	; Not the last INSTALL= program message
	 int	 21h		; Tell 'em we need to be the last program

	 stc			; Indicate this program is not CCOM

	 jmp	 EXIT		; Jump to common exit code

EXIT_CLC:
	 clc			; Indicate this program is CCOM

EXIT:
	 REGREST <ds,dx,bx,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
CHECK_CCOM_NAME  endp		; End CHECK_CCOM_NAME procedure


;****************************************************************************

	 NPPROC  APPLY_LSEG_NAME -- APPLY_LSEG_NAME procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Apply a name to the LSEG entry

On entry:
DS:DX	=>	Program name being loaded

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

; Find the end of the filespec

	 mov	 si,dx		; DS:SI ==> Filename
@@:
	 lodsb			; Get next character

	 cmp	 al,0		; End of the string?
	 jne	 @B		; Jump if not


; Search back to the beginning of the filename portion of filespec

	 dec	 si		; Skip back to NULL
	 dec	 si		; Skip back to last valid character
@@:
	 mov	 al,[si]	; Get current character
	 dec	 si		; Skip to previous character

	 cmp	 al,':'         ; Is it drive specifier?
	 je	 LCL1		; Jump if so

	 cmp	 al,'/'         ; Is it path separator?
	 je	 LCL1		; Jump if so

	 cmp	 al,'\'         ; Is it other path separator?
	 je	 LCL1		; Jump if so

	 cmp	 si,dx		; Beginning of filename? (no separators)
	 je	 LCL2		; Jump if so

	 jmp	 @B		; Look at next character

; Skip to beginning of filename

LCL1:
	 inc	 si		; Skip to NULL
	 inc	 si		; Skip to first character in filename

; Move the filename to the LSEG entry

LCL2:
	 push	 cs		; Address the LSEG entry
	 pop	 es		; ... via ES
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,LSEG.LSEG_FNE ; Address the LSEG entry

@@:
	 cmp	 BPTR ds:[si],0 ; Is the next character valid?
	 je	 EXIT		; Jump if end of string

	 movsb			; Move character to LSEG entry

	 jmp	 @B		; Try to move anothier character

EXIT:
	 REGREST <es,di,si,cx,ax> ; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
APPLY_LSEG_NAME  endp		; End APPLY_LSEG_NAME procedure


;****************************************************************************

	 NPPROC  LINK_MAC -- LINK_MAC procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Patch both MAC entries
This will allow DOS to load COMMAND.COM into High DOS

Note: We free the UMB block by ZEROing out the owner field, not by
calling DOS' release_mem.  If we called release_mem, MAX would also
release the LSEG entry, and the rest isn't happy.

|

	 REGSAVE <ax,ds>	; Save registers

	 test	 LCL_FLAG,(@LCL_CCOM or @LCL_PROG_SHARE) ; Moving CCOM high?
	 jz	 EXIT		; Jump if not (no need to patch any MACs)

; Patch the FIRST MAC entry (new length)

	 mov	 ds,FIRST_MAC	; Address FIRST MAC entry
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ax,ds:[MAC_STR.MAC_NPAR] ; Get the length value
	 mov	 SAVED_FIRST_LEN,ax ; ... save for later

; Skip this if we're running under MS-DOS 7.00 as we load COMMAND.COM
; high very differently.

	 mov	 al,02h 	; Code to get link state
	 DOSCALL @MACALG	; Set link state from BX
	 mov	 BPTR LINKSTATE,al ; Save to restore later

	 push	 bx		; Save for a moment

	 mov	 bx,mask $LINK_HIGH ; Set state to linked
	 mov	 al,03h 	; Code to set link state
	 DOSCALL @MACALG	; Set link state from BX

	 pop	 bx		; Restore

	 cmp	 MODELNO,2	; Izit MS-DOS 7.00?
	 je	 short @F	; Jump if so

	 mov	 ax,UMB_SEGMENT ; Address of our UMB
	 dec	 ax		; Address MAC entry of UMB
	 sub	 ax,FIRST_MAC	; Calculate (UMB - FIRST_MAC)
	 dec	 ax		; Plus MAC entry (to get size of region)

	 mov	 ds:[MAC_STR.MAC_NPAR],ax ; Set length (point to our UMB)
@@:

; The following code is no longer needed as I can't get OnTrack's DDO
; driver to work with ExtraDOS's attempt to load COMMAND.COM high,
; but if we ever need it later, it might be useful.

;;; COMMENT|
;;;
;;; Previously we patched the FIRST_MAC entry to have a size which looks
;;; like it reaches into high DOS.  The purpose of this patch is so when
;;; DOS allocates memory for COMMAND.COM, it allocates it in high DOS.
;;;
;;; Alas, some programs such as OnTrack's DDO (Dynamic Drive Overlay)
;;; modify the MAC chain between the time we applied the patch and when we
;;; restored the patch.  This causes the DDO code not to find itself and
;;; leave a 6KB block at the top of low DOS.
;;;
;;; The new scheme is to allocate all of low DOS to us (by changing the
;;; owner field) and ensure that the last MAC entry points into high DOS
;;; (by changing the type field to 'M').
;;;
;;; |
;;;
;;; ; Find and allocates to us (@MAC_PLUG) all free entries in low DOS
;;;
;;;	     push    bx 	    ; Save for a moment
;;;
;;;	     mov     ax,FIRST_MAC   ; Address FIRST MAC entry
;;; LINK_MAC_NEXT:
;;;	     mov     ds,ax	    ; Address the next MAC entry
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;;
;;;	     cmp     ax,0A000h	    ; Izit in high DOS?
;;;	     jae     short LINK_MAC_DONE ; Jump if so
;;;
;;;	     mov     bl,ds:[MAC_STR.MAC_TYPE] ; Get the current type
;;;	     mov     SAVED_LAST_TYPE,bl ; Save for later use
;;;	     mov     SAVED_LAST_MAC,ax ; ...
;;;
;;;	     add     ax,ds:[MAC_STR.MAC_NPAR] ; Plus the length
;;;	     inc     ax 	    ; Skip over the MAC para
;;;
;;;	     cmp     ds:[MAC_STR.MAC_OWNR],@MAC_FREE ; Izit free?
;;;	     jne     short LINK_MAC_LOOP ; Jump if not
;;;
;;;	     mov     ds:[MAC_STR.MAC_OWNR],@MAC_PLUG ; Mark as to be freed later
;;; LINK_MAC_LOOP:
;;;	     cmp     ds:[MAC_STR.MAC_TYPE],@MAC_END ; Izit the end?
;;;	     jne     short LINK_MAC_NEXT ; Jump if not
;;;
;;; ; Mark the last MAC entry in low DOS as a middle entry
;;; ; so DOS can allocate COMMAND.COM into high DOS
;;;
;;;	     mov     ds:[MAC_STR.MAC_TYPE],@MAC_MID ; Mark as middling
;;; LINK_MAC_DONE:
;;;	     pop     bx
EXIT:
	 REGREST <ds,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
LINK_MAC	 endp		; End LINK_MAC procedure


;****************************************************************************

	 NPPROC  UNLINK_MAC -- UNLINK the first MAC entry
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Un-patch the first MAC entry now that CCOM has been loaded

|

	 REGSAVE <ax,ds>	; Save segment register

	 test	 LCL_FLAG,(@LCL_CCOM or @LCL_PROG_SHARE) ; Moving CCOM high?
	 jz	 EXIT		; Jump if not

; Restore length of first MAC entry

	 mov	 ds,FIRST_MAC	; Address FIRST MAC entry
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ax,SAVED_FIRST_LEN ; Get saved length
	 mov	 ds:[MAC_STR.MAC_NPAR],ax ; ... and restore

	 push	 bx		; Save for a moment

	 mov	 bx,LINKSTATE	; Restore link state
	 mov	 al,03h 	; Code to set link state
	 DOSCALL @MACALG	; Set link state from BX

	 pop	 bx		; Restore

; The following code is no longer needed as I can't get OnTrack's DDO
; driver to work with ExtraDOS's attempt to load COMMAND.COM high,
; but if we ever need it later, it might be useful.

;;; ; De-allocate MACs we allocated to us in low DOS and
;;; ; restore the MAC type saved in SAVED_LAST_TYPE
;;;
;;;	     mov     ds,FIRST_MAC   ; Address FIRST MAC entry
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;; UNLINK_MAC_NEXT:
;;;	     mov     ax,ds	    ; Get the segment
;;;
;;;	     cmp     ax,0A000h	    ; Izit in high DOS?
;;;	     jae     short UNLINK_MAC_DONE ; Jump if so
;;;
;;;	     add     ax,ds:[MAC_STR.MAC_NPAR] ; Plus the length
;;;	     inc     ax 	    ; Skip over the MAC para
;;;
;;;	     cmp     ds:[MAC_STR.MAC_OWNR],@MAC_PLUG ; Izit to be freed?
;;;	     jne     short UNLINK_MAC_LOOP ; Jump if not
;;;
;;;	     mov     ds:[MAC_STR.MAC_OWNR],@MAC_FREE ; Mark as free
;;; UNLINK_MAC_LOOP:
;;;	     cmp     ds:[MAC_STR.MAC_TYPE],@MAC_END ; Izit the end?
;;;	     je      short UNLINK_MAC_DONE1 ; Jump if so
;;;
;;;	     mov     ds,ax	    ; Address the next MAC entry
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;;
;;;	     jmp     UNLINK_MAC_NEXT ; Go around again
;;;
;;; UNLINK_MAC_DONE:
;;;	     mov     ds,SAVED_LAST_MAC ; Get the segment of the last MAC
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;;
;;;	     mov     al,SAVED_LAST_TYPE ; Get the last MAC type
;;;	     mov     ds:[MAC_STR.MAC_TYPE],al ; Restore the type
;;; UNLINK_MAC_DONE1:
EXIT:
	 REGREST <ds,ax>	; Restore register

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
UNLINK_MAC	 endp		; End UNLINK_MAC procedure


;****************************************************************************

	 NPPROC  PATCH_ENV_LOADER -- Patch the Environment loader
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Apply the patches so that we'll regain control when COMMAND.COM tries
to allocate memory for the environment.  We have to do this even if
the environment is staying in Conventional memory so that we can fill
in the environment pointer in our fake PSP.

The environment loader is at offset ...
DOS 5.00 =	381h
DOS 6.00 =	441h

On exit:
CF	=	0 We patched ENVIRONMENT loader
		1 if we did not

|

	 REGSAVE <ax,bx,cx,si,di,ds,es> ; Save registers

; If we aren't moving CCOM or the env High, then there is no reason to
; apply this patch

	 test	 LCL_FLAG,(@LCL_CCOM or @LCL_ENVIRON) ; Moving either to High DOS?
	 jz	 EXIT_CLC	; Jump if not (must be moving SHARE only)

; Address the COMMAND.COM image

	 mov	 es,LOADDBG.LOADDBG_CSIP.VVSEG ; Get initial CS of COMMAND.COM
	 assume  es:nothing	; Tell the assembler about it

; Find the Environment loader

	 push	 cs		; Address our own resident data (model code)
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ax,es		; Segment to search for
	 lea	 si,ENV_MODEL1	; Address of our model code
	 mov	 cx,@ENV_MODEL1_LEN ; Length of search string
	 call	 SRCHSTR_	; Search for the environment loader code
	 jc	 @F		; Jump if code not found

	 add	 di,@MODEL1_ENV_PATCH ; Add constant to get patch offset
	 mov	 ENV_ADDR,di	; Save Loader address (for un-patch)

	 jmp	 short COM	; Join common code

@@:
	 mov	 ax,es		; Segment to search for
	 lea	 si,ENV_MODEL2	; Address of our model code
	 mov	 cx,@ENV_MODEL2_LEN ; Length of search string
	 call	 SRCHSTR_	; Search for the environment loader code
	 jc	 @F		; Jump if code not found

	 add	 di,@MODEL2_ENV_PATCH ; Add constant to get patch offset
	 mov	 ENV_ADDR,di	; Save Loader address (for un-patch)

	 jmp	 short COM	; Join common code

@@:
	 mov	 ax,es		; Segment to search for
	 lea	 si,ENV_MODEL3	; Address of our model code
	 mov	 cx,@ENV_MODEL3_LEN ; Length of search string
	 call	 SRCHSTR_	; Search for the environment loader code
	 jc	 EXIT_STC	; Jump if code not found

	 add	 di,@MODEL3_ENV_PATCH ; Add constant to get patch offset
	 mov	 ENV_ADDR,di	; Save Loader address (for un-patch)
COM:

; Save the environment loader code (underneath the patch)

	 mov	 ax,es:[di]+0	; Get word at ?? code
	 mov	 WPTR ENV_SAVE[0],ax ; Save for later

	 mov	 ax,es:[di]+2	; Get word at ?? code
	 mov	 WPTR ENV_SAVE[2],ax ; Save for later

	 mov	 al,es:[di]+4	; Get byte at ?? code
	 mov	 BPTR ENV_SAVE[4],al ; Save for later

; Apply the patch (to move the environment loader code)

	 mov	 BPTR es:[di],@OPCOD_CALLF	 ; Patch in the Far CALL
	 mov	 WPTR es:[di+1],offset PGROUP:LOAD_ENV_HI ;	Offset
	 mov	 WPTR es:[di+3],cs		 ; ...		Segment

; Find the allocate code model if MS-DOS 7.00

	 cmp	 MODELNO,2	; Izit MS-DOS 7.00?
	 jne	 short EXIT_CLC ; Jump if not

	 mov	 ax,es		; Segment to search for
	 lea	 si,ALLOCCMD_MODEL ; Address of our model code
	 mov	 cx,@ALLOCCMD_LEN ; Length of search string
	 call	 SRCHSTR_	; Search for the code (Return in DI)
	 jc	 EXIT_STC	; Jump if code not found

	 mov	 bx,di		; Save offset

	 mov	 ax,es		; Segment to search for
	 lea	 si,ALLOCCMD_MODEL2 ; Address of our model code
	 mov	 cx,@ALLOCCMD2_LEN ; Length of search string
	 call	 SRCHSTR_	; Search for the code (Return in DI)
	 jc	 EXIT_STC	; Jump if code not found

	 mov	 BPTR es:[bx+MODEL2_ALLOCATOR+1],@MSINTX ; Switch interrupt #s
	 mov	 BPTR es:[di+MODEL2_ALLOCATOR2+1],@MSINTX ; ...

; Intercept INT @MSINTX

	 mov	 ax,seg INTVEC	; Get segment of IVT
	 mov	 ds,ax		; Address it
	 assume  ds:INTVEC	; Tell the assembler about it

	 pushf			; Save flags
	 cli			; Nobody move while we change the IVT

	 lea	 ax,ALLOC_CCOM_HI ; Get offset of local handler
	 xchg	 ax,INT00_VEC.VECTOR.VOFF[@MSINTX*(type INT00_VEC)] ; Swap 'em
	 mov	 OLDINT04_VEC.VOFF,ax ; Save to restore later

	 mov	 ax,cs		; Get segment of local handler
	 xchg	 ax,INT00_VEC.VECTOR.VSEG[@MSINTX*(type INT00_VEC)] ; Swap 'em
	 mov	 OLDINT04_VEC.VSEG,ax ; Save to restore later

	 popf			; Restore
EXIT_CLC:
	 clc			; Indicate we patched environment loader

	 jmp	 EXIT		; Join common exit code

EXIT_STC:
	 stc			; Indicate we couldn't patch it

EXIT:
	 REGREST <es,ds,di,si,cx,bx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
PATCH_ENV_LOADER endp		; End PATCH_ENV_LOADER procedure


;****************************************************************************

	 NPPROC  CREATE_FAKE_PSP -- CREATE_FAKE_PSP procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

If we are moving COMMAND.COM, then we have to create a phony PSP
so that programs like NETX can find the master environment.

|

	 REGSAVE <ax,bx,cx,si,di,ds,es> ; Save registers

	 test	 LCL_FLAG,@LCL_NOPSP ; Jump if ...
	 jnz	 EXIT		; ... we don't need to create a fake PSP

	 test	 LCL_FLAG,@LCL_CCOM ; Moving CCOM high?
	 jz	 EXIT		; Jump if CCOM not in High DOS

	 cmp	 CCOM_REGION,0	; Loading CCOM into Low DOS memory?
	 je	 EXIT		; Jump if so

	 cmp	 FAKE_PSP,0	; Izit already allocated?
	 jne	 EXIT0		; Jump if so

; Allocate some conventional memory for the PSP

	 mov	 ah,48h 	; DOS: Allocate memory
	 mov	 bx,6		; Number of paragraphs (minimal PSP)
	 int	 21h		; Allocate one memory block
	 jc	 EXIT		; Jump if error (Note: CF=1)

	 mov	 FAKE_PSP,ax	; Save for later (when we alloc the environ)
EXIT0:
	 call	 COPY_PSP	; Copy COMMAND.COM's PSP to FAKE_PSP

; Note: NETX.EXE looks for these fields at 038C:B3CD in its code
;	This might be helpful if debugging NETX

EXIT:
	 REGREST <es,ds,di,si,cx,bx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
CREATE_FAKE_PSP  endp		; End CREATE_FAKE_PSP procedure


;****************************************************************************

	 NPPROC  COPY_PSP -- Copy COMMAND.COM PSP To FAKE_PSP
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Copy COMMAND.COM's PSP to FAKE_PSP

|

	 pusha			; Save all GP registers
	 REGSAVE <es>		; Save register

; Copy the PSP from the real COMMAND.COM

	 cmp	 FAKE_PSP,0	; Izit allocated as yet?
	 je	 short COPY_PSP_EXIT ; Jump if not

	 mov	 es,FAKE_PSP	; Address our new block
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ah,@GETPSP	; DOS: Get current PSP int BX (62h)
	 int	 21h		; Get CCOM's PSP
	 mov	 ds,bx		; Address CCOM's UMB
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; Start at offset 0
	 xor	 di,di		; ...
	 mov	 cx,(60h/2)	; Size of minimal PSP (in words)

     rep movsw			; Create the new PSP

; Fill in all the important PSP fields

	 mov	 es:[0016h],es	; Fill in Control PSP segment

; Address the MAC entry

	 mov	 ax,es		; Get segment of memory block
	 dec	 ax		; Point to MAC entry
	 mov	 es,ax		; Address MAC entry
	 assume  es:nothing	; Tell the assembler about it

; Fill in all the important MAC fields

	 mov	 es:[0001],es	; Fill in MAC owner block
	 inc	 WPTR es:[0001] ; This program owns itself

; Fill in name field of MAC entry (Low_PSP)

	 mov	 WPTR es:[0008+0],'oL'
	 mov	 WPTR es:[0008+2],'_w'
	 mov	 WPTR es:[0008+4],'SP'
	 mov	 WPTR es:[0008+6], 'P'
COPY_PSP_EXIT:
	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it
	 popa			; ...

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

COPY_PSP endp			; End COPY_PSP procedure


;****************************************************************************

	 NPPROC  SET_PSP_TERM -- SET_PSP_TERM procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

In case this program returns to us, we need to set the interrupt
22 vector in the PSP to return to our code.  We can then return to
our calling program, if this happens.

|

	 REGSAVE <ax,ds>	; Save registers

	 mov	 ah,@GETPS0	; DOS: Get current PSP function (51h)
	 int	 21h		; Get current PSP into BX

	 mov	 ds,bx		; Address COMMAND.COM's PSP
	 assume  ds:nothing	; Tell the assembler about it

;;;;;;;; Note: If we validate the address, we'll have to push/pop BX
;;;;;;;;
;;;;;;;; mov	 bx,cs		; Get our own code segment
;;;;;;;;
;;;;;;;; cmp	 WPTR ds:[0Ah]+2,bx ; Terminating to ourselves?
;;;;;;;; jne	 ??		; Jump if not (huh)?
;;;;;;;;
;;;;;;;; cmp	 WPTR ds:[0Ah]+0,offset FCN4B_RET ; Terminating to ourselves?
;;;;;;;; jne	 ??		; Jump if not (huh)?

	 mov	 WPTR ds:[0Ah]+2,cs		     ; Set new return address
	 mov	 WPTR ds:[0Ah]+0,offset FCN4B_NEWRET ; ...

	 REGREST <ds,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
SET_PSP_TERM	 endp		; End SET_PSP_TERM procedure

;****************************************************************************

	 NPPROC  APPLY_PATTERN -- APPLY_PATTERN procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Apply the '386M' pattern (in preparation for GETSIZE)

|

	 REGSAVE <ax,ds,es>	; Save registers

; Address our own data

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

; Fill in variables used by GETSIZE code

	 mov	 TOPFILL,-1	; Don't limit our pattern search

	 mov	 ax,UMB_SEGMENT ; Get segment of COMMAND.COM
	 mov	 EXEC_LOD,ax	; Start of GETSIZE pattern

	 dec	 ax		; Address the MAC entry
	 mov	 EXEC_PRGMAC,ax ; ...

; Apply the filler pattern

	 mov	 es,ax		; Address the MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 call	 FILL_MEM	; Fill memory with '386M' pattern

	 REGREST <es,ds,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
APPLY_PATTERN	 endp		; End APPLY_PATTERN procedure


;****************************************************************************

	 NPPROC  GET_LSIZE  -- GET_LSIZE procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Determine Loading size of COMMAND.COM

On entry:
DS:DX	=>	ASCIIZ file name

On exit:
CF	=	0 Success
		1 Failure

|

	 REGSAVE <ax,bx,cx,dx,ds,es> ; Save registers

; Open the file

	 mov	 al,0		; Access code for read-only
	 DOSCALL @OPENF2	; Open it
	 jc	 OPEN_FILE_ERRMSG ; Something went wrong

	 mov	 bx,ax		; Copy to handle register

; Address our own data

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

; Read in the file's header in case it's an .EXE file

	 mov	 cx,type EXE_STR ; # bytes to read in
	 DOSCALL @READF2,FILE_HEAD ; Read into local buffer
	 jc	 OPEN_FILE_ERRCLOS ; Jump if something went wrong

; Determine the load size in bytes

	 xor	 cx,cx		; Set CX:DX to 0:0
	 xor	 dx,dx
	 mov	 al,2		; Code to move file pointer to EOF
	 DOSCALL @MOVFP2	; Move file pointer by CX:DX as per AL
				; Return with DX:AX == file size in bytes
	 jc	 OPEN_FILE_ERRCLOS ; Jump if something went wrong

; Address the real LSEG entry

	 REGSAVE <ax>		; Save registers

	 mov	 ax,UMB_SEGMENT ; Address the UMB
	 dec	 ax		; Address the MAC entry
	 sub	 ax,@LSEGPARA	; Address the LSEG entry
	 mov	 es,ax		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

	 REGREST <ax>		; Restore registers

; DX,AX = Files size in bytes
; BX	= File handle

	 call	 LOADSIZE	; Get the load size

; Cloase the file, we're all done with the preliminaries

	 DOSCALL @CLOSF2	; Close it up, ignore error

; Set up the stack variables for GET_ISIZE
; (this must be done before the program goes resident)

; Set up the stack variables

	 mov	 ax,UMB_SEGMENT ; Address the UMB
	 dec	 ax		; Address the MAC entry
	 mov	 es,ax		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es:[MAC_STR.MAC_NPAR] ; Get # paragraphs

	 cmp	 ax,1000h	; Use smaller of 64KB
	 jb	 @F		; Jump if smaller

	 mov	 ax,1000h	; Use 64KB
	 mov	 WPTR STKSIZE+2,0001h ; Set high-order word
@@:
	 mov	 cl,(4-0)	; Shift amount between bytes and paras
	 shl	 ax,cl		; Convert from paras to bytes
	 mov	 WPTR STKSIZE+0,ax ; Save as stack size in bytes

; Fill in the ASIZE variables

	 mov	 ax,CCOM_LEN	; Get length of CCOM in paras
	 mov	 dx,ax		; ...

	 mov	 cl,(16-4)	; Save upper 4 bits
	 shr	 dx,cl		; ...
	 mov	 cl,(4-0)	; Convert from paras to bytes
	 shl	 ax,cl		; ...

	 mov	 LSEG.LSEG_ASIZE.EGP_STR.EHI,dx ; Save upper wqord
	 mov	 LSEG.LSEG_ASIZE.EGP_STR.ELO,ax ; Save lower word

	 clc			; Indicate success

	 jmp	 EXIT		; Join common exit code

OPEN_FILE_ERRMSG:
OPEN_FILE_ERRCLOS:
	 DOSCALL @CLOSF2	; Close it up, ignore error

	 stc			; Indicate failure

EXIT:
	 REGREST <es,ds,dx,cx,bx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
GET_LSIZE endp			; End GET_LSIZE procedure


;****************************************************************************

	 NPPROC  GET_RSIZE -- GET_RSIZE procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Calculate a program's Resident size

Note: You must find the resident size BEFORE you find the initialization
size.  This is because GETSIZE uses the resident size as the starting
point for the pattern match

RPARA does not include its own MAC entry, but does include the LSEG
entry and the LSEG's MAC entry.  It does include the MAC entries of
any subsequent MACs (if applicable)

|

	 REGSAVE <ax,bx,es>	; Save registers

; Address the first MAC entry

	 mov	 ax,UMB_SEGMENT ; Address the UMB
	 dec	 ax		; Address the MAC entry
	 mov	 es,ax		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

; Find the resident size of the first MAC entry (plus LSEG size)

	 mov	 bx,es:[MAC_STR.MAC_NPAR] ; Get resident request (in paras)
	 mov	 ax,bx		; Save MAC size
	 add	 bx,@LSEGPARA+1 ; Include LSEG & MAC entry
	 mov	 LSEG.LSEG_RPARA,bx ; Tell em about resident request

NEXT_MAC:

; Is this MAC entry within our range?

; AX = MAC_NPAR
; ES = Segment of current MAC

	 inc	 ax		; Include MAC entry in length
	 mov	 bx,es		; Get current segment
	 add	 ax,bx		; Address the next MAC entry

	 cmp	 ax,FJI_SEG1	; Within spitting distance?
	 ja	 RPARA_FOUND	; Jump if not (this MAC not part of CCOM)

; Is this MAC entry available?

	 mov	 es,ax		; Address the MAC entry
	 assume  es:nothing	; Tell the assembler about it

; Include this MAC entry in our RPARA size

	 mov	 ax,es:[MAC_STR.MAC_NPAR] ; Get size of this MAC

	 add	 LSEG.LSEG_RPARA,ax ; Include this MAC in tally
	 inc	 LSEG.LSEG_RPARA ; Include its MAC entry

	 cmp	 es:[MAC_STR.MAC_TYPE],'M' ; Is there another MAC entry?
	 je	 NEXT_MAC	; Look at next MAC entry if so

; We have found the size of RPARA

RPARA_FOUND:

; Include the size of the .BAT processor for pre-DOS 6 versions.
; This memory block is always 4 paras (+1 for the MAC entry itself)
; and contains information to track the progress of AUTOEXEC.BAT
; execution.  Even though it's not always left resident, we still
; need to set aside space for it.

; Future enhancements include allocating this memory block in a
; different region, thus avoiding the 4 para hole that will exist
; when AUTOEXEC.BAT finishes completion.  The 'Q' keyword is
; reserved for this purpose.

@BAT_PROCESSOR equ (4 + 1)	; 4 paras + 1 MAC entry

	 add	 LSEG.LSEG_RPARA,@BAT_PROCESSOR ; Include .BAT processor

	 REGREST <es,bx,ax>	; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
GET_RSIZE	 endp		; End GET_RSIZE procedure


;****************************************************************************

	 NPPROC  GET_ISIZE -- GET_ISIZE procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Determine the program's initialization size

|

	 REGSAVE <ax,dx,ds,es>	; Save registers

; Address our own data

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

; Address the MAC entry of COMMAND.COM

	 mov	 es,EXEC_PRGMAC ; Address MAC entry of COMMAND.COM
	 assume  es:nothing	; Tell the assembler about it

; Get the program's initialization size

	 call	 GETSIZE	; Dtermine the program's initialization size

	 REGREST <es,ds,dx,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
GET_ISIZE	 endp		; End GET_ISIZE procedure


;****************************************************************************

HCODE	 ends			; End Resident Code segment


;****************************************************************************

HDATA	 segment		; Start Non-Resident Data segment



HDATA	 ends			; End non-Resident Data segment

;****************************************************************************

HNCODE	 segment		; Start Non-Resident Code Segment



;*************************************************************************

HNCODE	 ends			; End Non-Resident Code Segment


	 END			; End HARP_INS module




