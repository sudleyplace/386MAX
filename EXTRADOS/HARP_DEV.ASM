;'$Header:   P:/PVCS/MAX/EXTRADOS/HARP_DEV.ASV   1.2   30 May 1997 11:13:08   BOB  $
	 title	 HARP_DEV -- DEVICE= routines for HARPO
	 page	 58,122
	 name	 HARP_DEV

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-7 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  dword-aligned,public, class 'data'
	       Stack   segment STACK, para-aligned, stack,  class 'stack'

|
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include KEYCALL.INC
	 include ASCII.INC
	 include PTR.INC
	 include XMS.INC
	 include MAC.INC
	 include OPCODES.INC

	 include SEGS.INC
	 include HARPO.INC
	 include EMM2CALL.INC
	 include QMAX_CTL.INC
	 include LOAD_SEG.INC
	 include QMAXINFO.INC
	 include QMAX_CMD.INC
.list


;*******************************************************************


HCODE	 segment		; Start Resident Code segment

extern	 FIRST_MAC:word 	; Segmenty of DOS' first MAC entry
extern	 RES_PARA:word		; Resident size in paras
extern	 PORT67:word		; MAX's backdoor port (usually F084)
extern	 DOSVER:word		; DOS version number

extern	 GETMEM_REG:near	; Allocate Memory From Specified Region
extern	 REMOVE_DEAD:near	; Remove DeadMan switch from the profile
extern	 FMT_WORD:near		; Format AX => ES:DI (in hex)
if @MAX6
extern	 FMT_BASE10:near	; Format AX => ES:DI (in base 10)
endif				; IF @MAX6
extern	 PRESSANY:near		; Press any key to continue
extern	 DISP_COPY:near 	; Display copyright and optional message

extern	 BOOT_OFF:word		; Offset of resident code
extern	 BOOT_LEN:word		; Length fo resident code
extern	 FLOAT_SEG:word 	; Segment of our floater (if needed)

extern	 FILESPEC:byte		; Profile filespec
extern	 LOAD_CCOM_HI:far	; Entry point of CCOM patch

extern	 CURR_PASS:byte 	; Current Pass variable (0,1,2,-1)
extern	 @PASS_DEV:abs		; We're invoked from DEVICE=
extern	 @PASS_INS:abs		; We're invoked from ISNTALL=

;------------------ Resident data -------------------------

	 public  CFG_NEXTPARA,CFG_HIGHWATER
	 public  CFG_FIRSTPARA,CFG_SUBSEGLEN
CFG_NEXTPARA	 dw	0	; DOS' next free paragraph marker
CFG_HIGHWATER	 dw	0	; DOS' High water mark
CFG_FIRSTPARA	 dw	0	; DOS' first sub-segment para
CFG_SUBSEGLEN	 dw	0	; DOS' Length of all sub-segments (in Low DOS)

extern	 CONFIG_NEXT:word	 ; Storage for DOS next-para pointer
extern	 CONFIG_TOP:word	 ; Storage for DOS High water mark
extern	 UMB_SEGMENT:word	 ; Segment of our primary UMB


	 public  NEXT_HIGHPARA
NEXT_HIGHPARA	 dw	 ?	; Top of UMB (tallied by DOS)

	 public  CONFIG_SEGMENT,CONFIG_OFFSET
CONFIG_SEGMENT	dw	?	; Segment of sub-segment allocation routine
CONFIG_OFFSET	dw	1637h	; Offset ...

	 public  CONFIG_LOCAL
CONFIG_LOCAL	dw	offset PGROUP:LOCAL1_ALLOC ; Offset of local allocate routine

	 public  MODELNO
MODELNO  db	 0		; Model # (1=DOS 3-6, 2 = MS-DOS 7, a.k.a. Win95)

	 public  LAST_SUBSEG,LAST_ALLOC
LAST_SUBSEG db	 0		; Last sub-segment letter
LAST_ALLOC dw	 0		; Segment of last alloc
				; (Both used for size determination)

	 public  CONFIG_UMB_MAX
CONFIG_UMB_MAX	 dw	 0	; Ending para of sub-segment region


;---------------- Transient code variables -----------------

	 public  TRANSFER_VEC
TRANSFER_VEC label dword
	 dw	 PGROUP:TRANSFER_LOC ; Offset of transfer
	 dw	 ?		     ; Segment ...

	 public  CURR_REG,CURR_NPAR,CURR_NAME,CURR_TOKEN
CURR_REG     db  ?		; Region of current request
CURR_NPAR    dw  ?		; Para count of current request
CURR_NAME    dw  ?		; MAC name of current request
CURR_TOKEN   db  ?		; Curretn token (F,X,B,L,S)

	 public  LAST_NPAR,CODE_REG
LAST_NPAR    dw  ?		; Para count of last allocation
CODE_REG     db  ?		; Region for transient code/data

extern	 CCOM_XREG:byte 	; Region of COMMAND.COM that is off limits
				; to the env. due to CCOM bug


;--------------- High FILES variables --------------------

	 public  SFT_STRLEN,FILES_REG,FILES_SEG,FILES_PARA
SFT_STRLEN	 db	 03Bh	; Size of one SFT structure (in bytes)
FILES_PARA	 dw	 ?	; Size of entire High FILES (in paras)
FILES_REG	 db	 0	; Region for High FILES
FILES_SEG	 dw	 ?	; Segment of Low FILES


;-------------- Token structure variables -----------------

	 extern  MSG_FILES:byte
	 extern  MSG_FCB:byte
	 extern  MSG_BUFFERS:byte
	 extern  MSG_LASTDRV:byte
	 extern  MSG_STACKS:byte
	 extern  MSG_SUBSEG3:byte
	 extern  MSG_BATCH:byte
	 extern  MSG_IFS_G:byte
	 extern  MSG_IFS_H:byte
	 extern  MSG_IFS_R:byte
	 extern  MSG_IFS_Y:byte

	 public  TOKEN_LIST
TOKEN_LIST label TOKEN_STR	; List of all possible tokens
	 TOKEN_STR <@TOKEN_FILES,  0,0,MSG_FILES,  MAC_NAME_F> ; FILES=
	 TOKEN_STR <@TOKEN_FCB,    0,0,MSG_FCB,    MAC_NAME_X> ; FCB=
	 TOKEN_STR <@TOKEN_BUFFERS,0,0,MSG_BUFFERS,MAC_NAME_B> ; BUFFERS=
	 TOKEN_STR <@TOKEN_LASTDRV,0,0,MSG_LASTDRV,MAC_NAME_L> ; LASTDRV=
	 TOKEN_STR <@TOKEN_STACKS, 0,0,MSG_STACKS, MAC_NAME_S> ; STACKS=
	 TOKEN_STR <@TOKEN_DOS3,   0,0,MSG_SUBSEG3,MAC_NAME_A> ; DOS3 data
	 TOKEN_STR <@TOKEN_BATCH,  0,0,MSG_BATCH,  MAC_NAME_Q> ; Temporary data
	 TOKEN_STR <@TOKEN_IFS_G,  0,0,MSG_IFS_G,  MAC_NAME_G> ; IFS-G
	 TOKEN_STR <@TOKEN_IFS_H,  0,0,MSG_IFS_H,  MAC_NAME_H> ; IFS-H
	 TOKEN_STR <@TOKEN_IFS_R,  0,0,MSG_IFS_R,  MAC_NAME_R> ; IFS-R
	 TOKEN_STR <@TOKEN_IFS_Y,  0,0,MSG_IFS_Y,  MAC_NAME_Y> ; IFS-Y
	 TOKEN_STR <'C',0,0,0,          0         >     ; CCOM pseudo-token
	 TOKEN_STR <'E',0,0,0,          0         >     ; Env  pseudo-token
@TOKEN_END equ $		; End-of-List
@TOKEN_CNT equ (($-TOKEN_LIST)/(type TOKEN_STR)) ; Number of entries

	 public  MAC_NAME_F,MAC_NAME_X,MAC_NAME_B
	 public  MAC_NAME_L,MAC_NAME_S,MAC_NAME_A,MAC_NAME_Q
MAC_NAME_F db	 '>files  '             ; MAC entry name
MAC_NAME_X db	 '>fcb    '             ; ...
MAC_NAME_B db	 '>buffer '             ; ...
MAC_NAME_L db	 '>lastdrv'             ; ...
MAC_NAME_S db	 '>stack  '             ; ...
MAC_NAME_A db	 '>DOSdata'             ; ...
MAC_NAME_Q db	 '>tmpdata'             ; ... (normally freed before the
					;      user would ever see it)
	 public  MAC_NAME_G,MAC_NAME_H,MAC_NAME_R,MAC_NAME_Y
MAC_NAME_G db	 '>IFS-G  '             ; IFS-G
MAC_NAME_H db	 '>IFS-H  '             ; IFS-H
MAC_NAME_R db	 '>IFS-R  '             ; IFS-R
MAC_NAME_Y db	 '>IFS-Y  '             ; IFS-Y


;--------------- DOS 3.3 variables -------------------

	 public  HOOK_OFFSET,UNHOOK_OFFSET
HOOK_OFFSET	 dw	 ?	; Offset of HOOK rouitne
UNHOOK_OFFSET	 dw	 ?	; Offset of unhook routine

	 public  CODE1_SAVE
CODE1_SAVE db	 5 dup (?)	; Save area for code underneath patch

	 public  CODE2_SAVE
CODE2_SAVE db	 5 dup (?)	; Save area for code underneath patch


;-----------------------------------------------------


	 public  DOS_ALLOC_CNT
DOS_ALLOC_CNT	 dd	?	; Original DOS alloc routine

; N.B. This does not need to get translated since it's not in any shipping
;      version.
if @MAX6
	 public  MSG_BOA
MSG_BOA      db  'GETSIZE Information => Type = '
MSG_BOA_TYPE db  '_   Size =     '
MSG_BOA_NPAR db  '_'
	     db  CR,LF,EOS
endif				; IF @MAX6

	 extern  MSG_XSUBSEGLEN:byte
	 extern  MSG_MAXIMIZE1:byte
	 extern  MSG_MAXIMIZE2:byte
	 extern  MSG_MAXIMIZE3:byte
	 extern  MSG_REGION_OFLOW:byte

;--------------- 386MAX variables --------------------------

extern	 DEVNAME_MAX:byte	; MAX's device name
extern	 DEV_HNDL:word		; Handle used to open MAX
extern	 INFOSIZE:abs		; Size of info structure


;****************************************************************************

	 NPPROC  LOCAL_ALLOC -- Local CONFIG.SYS memory allocation handler
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Common routine to LOCALx_ALLOC

On entry:
AL	=	MAC sub-segment Type

On exit:
CX	=	Segment allocated for request (High or Low)

|

	 mov	 CURR_TOKEN,al	; Save current token

	 call	 MOVE_SFT_HIGH	; Move the SFT structures up high

	 call	 INIT_SUBSEG	; Initilaization code

; Fill in MAX's GETSIZE table (even if we're not doing getsize)
; If sub-segment loaded High, ensure that its size was OK
; Also, fill in the details of the last MAC entry we created

	 cmp	 LAST_SUBSEG,0	; First time around?
	 je	 @F		; Jump if so

	 call	 FILL_GETSIZE	; Fill in MAX's GETSIZE table

	 call	 CHECK_OVERFLOW ; See if we have an overflowed region

	 call	 VALIDATE_SIZE	; Ensure the size requested is correct

	 call	 SHRINK_SUBSEG	; Fill in the size of the last alloc
@@:
	 mov	 LAST_SUBSEG,al ; Save current subsegment for next pass

; Determine if this request is to be in High DOS or Conventional memory

; AL = MAC Type

	 REGSAVE <ax,di>	; Save registers

	 mov	 CURR_REG,0	; Assume this token is going low
	 mov	 CURR_NPAR,0	; Assume this token is going low

	 call	 GET_TOKEN	; Returns DI ==> TOKEN_STR of token 'AL'
	 jc	 @F		; Jump if token not found (CF significant)

	 mov	 ax,PGROUP:[di].TOKEN_STR.NPAR ; Get requested size
	 mov	 CURR_NPAR,ax	; ... and save for later

	 mov	 al,PGROUP:[di].TOKEN_STR.REG ; Get requested region
	 mov	 CURR_REG,al	; ... and save for later

	 mov	 ax,PGROUP:[di].TOKEN_STR.MACNAME ; Get MAC name address
	 mov	 CURR_NAME,ax	; ... and save for later
@@:
	 REGREST <di,ax>	; Restore registers

	 call	 TRANSFER_BOOT	; Move transient code out of the way
	 nop			; Make debugging easier

; Jump to appropriate code for High/Low memory request

	 cmp	 CURR_REG,1	; Is this a High DOS request?
	 jae	 LCL_ALLOC_UMB	; Jump if it's going in a UMB


;----------------
; This subsegment is loading in Conventional memory
;----------------

LCL_ALLOC_LOW:
	 call	 SUBSEG_LOW	; Load this subsegment into Conventional mem.

; Clean up the 'mess' if this is the last sub-segment

	 cmp	 al,@TOKEN_ENDCHAIN ; Is it End_Of_Sub_Segments?
	 jne	 @F		; Jump if not

	 call	 SUBSEG_T	; Special cleanup processing if "T" subseg
@@:
	 jmp	 LCL_ALLOC_CONT ; Continue with our local handler


;----------------
; This subsegment is loading in High DOS memory
;----------------

LCL_ALLOC_UMB:
	 call	 SUBSEG_HIGH	; Load this subsegment into High DOS
	 jc	 LCL_ALLOC_LOW	; Jump if no room in High DOS


;----------------
; Common code to High and Low sub-segments
;----------------

; AL = MAC Type

LCL_ALLOC_CONT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LOCAL_ALLOC endp		; End LOCAL1_ALLOC procedure
	 FPPROC  LOCAL1_ALLOC -- Local CONFIG.SYS memory allocation handler
	 assume  ds:nothing,es:nothing,ss:nothing

COMMENT |

Local CONFIG.SYS allocation handler (resident portion)

On entry:
AL	=	MAC sub-segment Type

On exit:
CX	=	Segment allocated for request (High or Low)

|

STACK_N1 struc
	   dw	 ?	; Caller's BP
  T_RET_IP dw	 ?	; Caller's return IP (from near call)
STACK_N1 ends

	 push	 bp		; Save Base pointer
	 mov	 bp,sp		; Address the stack

	 SWATTER		; Call debugger if requested

; AL = MAC Type

	 call	 LOCAL_ALLOC	; Call common routine

	 pop	 bp		; Restore the Base pointer

; Simulate instructions that the patch covered up

	 push	 es		; Simulate first instruction
	 push	 cx		; Simulate second instruction

	 REGSAVE <bx,ds>	; Save temporary variables

	 mov	 ds,CONFIG_SEGMENT ; Address CONFIG.SYS's code segment
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 bx,CFG_NEXTPARA ; Find DOS' next-para variable
	 mov	 cx,ds:[bx]	; Simulate third instruction

	 mov	 LAST_ALLOC,cx	; Save for getsize calculations

	 REGREST <ds,bx>	; Restore temp variables
	 assume  ds:nothing	; Tell the assembler about it

; Return to original handler in CONFIG.SYS

	 jmp	 DOS_ALLOC_CNT	; Jump to OLD alloc routine (back to DOS)
				; Good-bye!

	 assume  ds:nothing,es:nothing,ss:nothing

LOCAL1_ALLOC endp		; End LOCAL1_ALLOC procedure
	 FPPROC  LOCAL2_ALLOC -- Local CONFIG.SYS memory allocation handler
	 assume  ds:nothing,es:nothing,ss:nothing

COMMENT |

Local CONFIG.SYS allocation handler (resident portion)

On entry:
BH	=	MAC sub-segment Type
BL	=	0 or 1 (I'm not sure what this means)

On exit:
CX	=	Segment allocated for request (High or Low)

|

STACK_N2 struc
	   dw	 ?	; Caller's BP
  T_RET_DX dw	 ?	; Caller's DX (instruction overwritten)
STACK_N2 ends

	 push	 bp		; Save Base pointer
	 mov	 bp,sp		; Address the stack

	 SWATTER		; Call debugger if requested

; BH = MAC Type

	 mov	 al,bh		; Copy to common register

	 cmp	 bx,'B' shl 8   ; Izit 4200?
	 jne	 short @F	; Jump if not

	 mov	 al,'b'         ; Use alternate form
				; (currently not handled)
@@:
	 call	 LOCAL_ALLOC	; Call common routine

	 pop	 bp		; Restore the Base pointer

; Simulate instructions that the patch covered up

	 pop	 dx		; Simulate first instruction

	 REGSAVE <bx,ds>	; Save temporary variables

	 mov	 ds,CONFIG_SEGMENT ; Address CONFIG.SYS's code segment
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 bx,CFG_NEXTPARA ; Find DOS' next-para variable
	 mov	 cx,ds:[bx]	; Simulate third instruction

	 mov	 LAST_ALLOC,cx	; Save for getsize calculations

	 REGREST <ds,bx>	; Restore temp variables
	 assume  ds:nothing	; Tell the assembler about it

; Return to original handler in CONFIG.SYS

	 jmp	 DOS_ALLOC_CNT	; Jump to OLD alloc routine (back to DOS)
				; Good-bye!

	 assume  ds:nothing,es:nothing,ss:nothing

LOCAL2_ALLOC endp		; End LOCAL2_ALLOC procedure


;***************************************************************************

	 NPPROC  INIT_SUBSEG -- INIT_SUBSEG procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

DEVICE= initilaization that must be performed from resident code

* Determine the next_para of conventional memory

|

	 REGSAVE <ax,bx,ds>	; Save registers

; Address DOS'code/data

	 mov	 ds,CONFIG_SEGMENT ; Address DOS' code/data
	 assume  ds:nothing	; Tell the assembler about it

; Save next sub-segment pointer (if it points to DOS)

	 mov	 bx,CFG_NEXTPARA ; Find DOS' next-para variable
	 mov	 ax,ds:[bx]	; Get next CONFIG sub-segment

	 cmp	 ax,0A000h	; Is this DOS' pointer?
	 jae	 @F		; Jump if not

	 mov	 CONFIG_NEXT,ax ; Save next Low DOS pointer
@@:

EXIT:
	 REGREST <ds,bx,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
INIT_SUBSEG	 endp		; End INIT_SUBSEG procedure


;***************************************************************************

	 NPPROC  FILL_GETSIZE -- FILL_GETSIZE procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Use the EMM2 calls to inform MAX as to the characteristics of
the last sub-segment.  This information will then be passed
to MAXIMIZE.

Note: This routine must be first because it initializes in LAST_NAPR

|

	 REGSAVE <ax,bx,cx,dx,di,ds> ; Save registers

; Address DOS'code/data

	 mov	 ds,CONFIG_SEGMENT ; Address DOS' code/data
	 assume  ds:nothing	; Tell the assembler about it

; Find size of last sub-segment
; If this is High FILES, then we already know the size

	 mov	 cx,LAST_NPAR	; Assume it's the High FILES entry

	 cmp	 LAST_SUBSEG,@TOKEN_FILES ; Is this the FILES= entry?
	 je	 @F		; Jump if so (LAST_NPAR already set)

	 mov	 bx,CFG_NEXTPARA ; Address DOS' next_para
	 mov	 cx,ds:[bx]	; Get DOS's version of next_para
	 sub	 cx,LAST_ALLOC	; Minus the start of it all

	 mov	 LAST_NPAR,cx	; Save as size of actual allocation
@@:

; Address the appropriate token record

	mov	 al,LAST_SUBSEG ; Sub-segment type
	call	 GET_TOKEN	; Returns DI ==> TOKEN_STR of token 'AL'
	jc	 EXIT		; Jump if token not found

; Get region number and sub-segment type

	 mov	 bh,PGROUP:[di].TOKEN_STR.REG ; Get region number
	 mov	 bl,LAST_SUBSEG ; Sub-segment type (F,X,B,L,S)
	 mov	 dx,00h 	; Misc Flags

if @MAX6
	 call	 DISP_BOA	; Display GETSIZE info for BOA
endif				; IF @MAX6

; Pass the GESIZE information to MAX via the EMM2 interface

	 call	 EMM2_OUT	; Send the info upstairs

EXIT:
	 REGREST <ds,di,dx,cx,bx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
FILL_GETSIZE	 endp		; End FILL_GETSIZE procedure


;***************************************************************************

	 NPPROC  EMM2_OUT -- EMM2_OUT procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Send the HARPO infostructure to MAX

On entry:
BL	=	Subsegment type (F,X,B,L,S)
BH	=	Region number (0-9)
CX	=	Size of subsegment (in paras)
DX	=	Misc flags

|

	 REGSAVE <ax>		; Save registers

	 push	 bp		; Save BP
	 mov	 bp,sp		; Save SP (in case MAX trashes it)

	 mov	 al,@HARPO_SET_SUBSEG ; Send sub-segment info to HARPO
	 EMMOUT  @EMM2_HARPOINFO ; Pass subsegment information to MAX

	 mov	 sp,bp		; Restore SP
	 pop	 bp		; Restore BP

;;;;;;;; cmp	 ah,8Fh 	; Was the table full?
;;;;;;;; je	 ??		; Jump if so

	 REGREST <ax>		; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
EMM2_OUT	 endp		; End EMM2_OUT procedure


;***************************************************************************

if @MAX6
	 NPPROC  DISP_BOA -- DISP_BOA procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Display subsegment GETSIZE information for "Bank Of America"

On entry:
BL	=	Subsegment type (F,X,B,L,S)
BH	=	Region number (0-9)
CX	=	Size of subsegment (in paras)
DX	=	Misc flags

|

	 REGSAVE <ax,dx,di,ds,es> ; Save registers

	 test	 LCL_FLAG,@LCL_TEST ; Are we doing the GETSIZE thing?
	 jz	 EXIT		; Jump if not

; Address our data

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 cs		; Address our resident data
	 pop	 es		; ... via ES
	 assume  es:PGROUP	; Tell the assembler about it

; Format subsegment type

	 mov	 MSG_BOA_TYPE,bl ; Format subsegment type

; Format subsegment size

	 mov	 ax,cx		; Get subsegment size
	 lea	 di,MSG_BOA_NPAR ; Address of string

	 mov	 WPTR [di-2],'  ' ; Clear the size field
	 mov	 WPTR [di-4],'  ' ; ...

	 shl	 ax,1		; Convert form paras to bytes
	 shl	 ax,1		; ...
	 shl	 ax,1		; ...
	 shl	 ax,1		; ...
	 call	 FMT_BASE10	; Format subsegment size (in bytes)

; Display the GETSIZE string

	 lea	 di,MSG_BOA	; Address of GETSIZE information
	 call	 DISP_COPY	; Display copyright and GETSIZE info

EXIT:
	 REGREST <es,ds,di,dx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
DISP_BOA	 endp		; End DISP_BOA procedure
endif				; IF @MAX6


;***************************************************************************

	 NPPROC  VALIDATE_SIZE -- VALIDATE_SIZE procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Validate the requested size of a sub-segment

We have to determine if the MAXIMIZE size is different from the size
that was actually needed to store the sub-segment.  If the requested
size is different from the actual size, then we have to alert the user.

|

	 REGSAVE <ax,di>	; Save registers

; Get token entry for last sub-segment

	 mov	 al,LAST_SUBSEG ; Get previous MAC type
	 call	 GET_TOKEN	; Returns DI ==> TOKEN_STR of token 'AL'
	 jc	 EXIT		; Jump if token not found

; Determine the actual size of the last sub-segment

	 mov	 ax,LAST_NPAR	; Actual size of last allocation (use instead of above)

; Determine if the sizes differ (or not)

	 cmp	 PGROUP:[di].TOKEN_STR.REG,0 ; Skip if subsegment loading Low
	 je	 EXIT		; No error if loading in Low memory

	 cmp	 PGROUP:[di].TOKEN_STR.NPAR,-1 ; User ask us to skip check?
	 je	 EXIT		; Jump if so (no error message)

	 cmp	 PGROUP:[di].TOKEN_STR.NPAR,ax ; Compare to requested size
	 je	 EXIT		; Jump if equal

; Set MAX's IGNORE_FLEXFRAME bit to avoid any future problems
; We'll do this if the requested subsegment size is greater or smaller
; than the actual size needed

	 call	 SET_IGNFLEX	; Turn off any future FLEXFRAME requests
@@:
; Tell 'em the requested size and actual size are different

	 REGSAVE <dx,ds>	; Save registers

	 push	 cs		; Address our warning tet
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 dx,PGROUP:[di].TOKEN_STR.MESSAGE ; Save name address

	 lea	 di,MSG_MAXIMIZE1 ; "The size of "
	 call	 DISP_COPY	; Display message and copyright

	 DOSCALL @STROUT	; Display name

	 DOSCALL @STROUT,MSG_MAXIMIZE2 ; " has changed..."

	 call	 PRESSANY	; Make sure they see the error message

	 REGREST <ds,dx>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

EXIT:
	 REGREST <di,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
VALIDATE_SIZE	 endp		; End VALIDATE_SIZE procedure


;***************************************************************************

	 NPPROC  GET_TOKEN -- GET_TOKEN procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Find the record for a particular token

On entry:
AL	=	Token (F,X,B,L,S)

On exit:
CF	=	1 if token not found
	=	0 if token was found

DI	=	Points to entry within TOKEN_LIST for Token 'AL'

|

	 REGSAVE <ax,cx>	; Save registers

	 mov	 cx,@TOKEN_CNT	; Number of possible tokens
	 lea	 di,TOKEN_LIST	; Address the token list

NEXT_TOKEN:
	 cmp	 PGROUP:[di].TOKEN_STR.VALUE,al ; Is this our token?
	 je	 EXIT		; Jump if we found our token (Note:CF=0)

	 add	 di,type TOKEN_STR ; Bump to next structure
	 loop	 NEXT_TOKEN	; Try next entry

	 stc			; Indicate token not found

EXIT:
	 REGREST <cx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
GET_TOKEN	 endp		; End GET_TOKEN procedure


;***************************************************************************

	 NPPROC  CHECK_OVERFLOW -- CHECK_OVERFLOW procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Check to see if the last sub-segment alloc has overflowed the region

|

	 REGSAVE <ax,bx,ds>	; Save register

; Address DOS' code/data segment

	 mov	 ds,CONFIG_SEGMENT ; Address CONFIG.SYS's code segment
	 assume  ds:nothing	; Tell the assembler about it

; Check for region overflow

	 mov	 bx,CFG_NEXTPARA ; Find DOS' next-para variable
	 mov	 ax,WPTR ds:[bx] ; ...

	 cmp	 ax,0A000h	; Was the last request from Low DOS?
	 jbe	 EXIT		; Jump if so (it's no concern of ours)

	 cmp	 ax,CONFIG_UMB_MAX ; Compare to MAX top of region
	 jbe	 EXIT		; Jump if all is well

; Overflow has ocurred, tell the user

	 REGSAVE <dx,di,ds>	; Save registers

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 lea	 di,MSG_MAXIMIZE1 ; "The size of "
	 call	 DISP_COPY	; Display copyright and message

; Get token entry for last sub-segment

	 mov	 al,LAST_SUBSEG ; Get previous MAC type
	 call	 GET_TOKEN	; Returns DI ==> TOKEN_STR of token 'AL'
;;;;;;;; jc	 ??		; Jump if token not found

	 mov	 dx,PGROUP:[di].TOKEN_STR.MESSAGE ; Address particular name
	 DOSCALL @STROUT	; Display it

	 DOSCALL @STROUT,MSG_REGION_OFLOW ; " has busted the dam..."

	 jmp	 $		; Loop here till eterninty (oh well)

	 REGREST <ds,di,dx>	; Restore registers (if debugging w/SWAT)
	 assume  ds:nothing	; Tell the assembler about it

EXIT:
	 REGREST <ds,bx,ax>	; Restore register
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
CHECK_OVERFLOW	 endp		; End CHECK_OVERFLOW procedure


;***************************************************************************

	 NPPROC  SUBSEG_LOW -- SUBSEG_LOW procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

This subsegment is to remain in conventional memory.
This will be a low DOS request (restore any applied patches).

|

	 REGSAVE <ax,bx,ds>	; Save temporary variables

;---------------

; Address DOS' code/data segment

	 mov	 ds,CONFIG_SEGMENT ; Address CONFIG.SYS's code segment

;---------------

; If this is FILES=, then we should find the SFT structure size

	 REGSAVE <di>		; Save register

	 cmp	 al,@TOKEN_FILES ; Is this a FILES= entry?
	 jne	 @F		; Jump if not

	 mov	 di,[bp].STACK_N1.T_RET_IP ; Get caller's return IP
	 call	 GET_FILE_LEN	; If this is 'F' entry, then we have to
				; determine the length of each file entry
@@:
	 REGREST <di>		; Restore register

;---------------

; Restore sub-segment pointer (if it points to High DOS)

	 mov	 bx,CFG_NEXTPARA ; Find DOS' next-para variable
	 cmp	 WPTR ds:[bx],0A000h ; Compare with High DOS
	 jb	 short @F	; Jump if already pointing to DOS

	 mov	 ax,CONFIG_NEXT ; Restore sub-segment pointer
	 mov	 ds:[bx],ax	; ...
@@:

;---------------

; Restore High Water Mark (if it is modified)

	 mov	 bx,CFG_HIGHWATER ; Find DOS' High Water mark

	 cmp	 WPTR ds:[bx],-1 ; Have we modified it?
	 jne	 short @F	; Jump if not

	 mov	 ax,CONFIG_TOP	; Restore high water mark
	 mov	 ds:[bx],ax	; ...
@@:

;---------------

	 REGREST <ds,bx,ax>	; Restore temp variables
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
SUBSEG_LOW	 endp		; End SUBSEG_LOW procedure


;***************************************************************************

	 NPPROC  SUBSEG_HIGH -- SUBSEG_HIGH procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

This subsegment is to be loaded into High DOS
* If it is FILES=, then pass the structure size to MAX (for WIndows)
* Allocate space for sub-segment
* Apply the MAC name for this sub-segment
* Modify DOS' variables (to trick it)

On entry:
AL	=	MAC Type

On exit:
CF	=	0 Sub-segment to be loaded High
	=	1 No room in specified region

|

;---------------

; Allocate space for this sub-segment

	 call	 ALLOC_SUBSEG	; Alloc space for this subseg
	 jc	 EXIT		; Jump if no space found
				; Note (CF is significant)

;---------------

; Apply the appropriate name to this entry

	 REGSAVE <ax,bx,cx,si>	; Save registers

	 mov	 cl,al		; Get MAC type
	 mov	 ax,NEXT_HIGHPARA ; Point to sub-segs segment
	 mov	 bx,@MAC_SUBSEG_DOS ; Special owner for MAXIMIZE's sake
	 mov	 si,CURR_NAME	; Get MAC name of current token
	 call	 APPLY_MAC_NAME ; Label the sub-segment MAC entry

	 REGREST <si,cx,bx,ax>	; Restore registers

;---------------

; Trick DOS into loading this sub-segment into High DOS

	 REGSAVE <ax,bx,ds>	; Save temporary variables

	 mov	 ds,CONFIG_SEGMENT ; Address CONFIG.SYS's code segment
	 assume  ds:nothing	; Tell the assembler about it

; Save (and modify) next sub-segment pointer (only if it points to DOS)

	 mov	 bx,CFG_NEXTPARA ; Find DOS' next-para variable
	 mov	 ax,ds:[bx]	; Get next CONFIG sub-segment

	 cmp	 ax,0A000h	; Compare with High DOS start
	 ja	 short @F	; Jump if already a High DOS segment

	 mov	 CONFIG_NEXT,ax ; ... and save for later
@@:
	 mov	 ax,NEXT_HIGHPARA ; Stuff new sub-segment allocation pointer
	 mov	 ds:[bx],ax	; ...

; Save (and modify) High Water mark (only if we haven't already tampered with it)

	 mov	 bx,CFG_HIGHWATER ; Find DOS' next-para variable
	 mov	 ax,ds:[bx]	; Get TOP of DOS

	 cmp	 ax,-1		; Have we already stuffed this one?
	 je	 short @F	; Jump if so

	 mov	 CONFIG_TOP,ax	; ... and save for later

	 mov	 ax,-1		; Stuff high water mark
	 mov	 ds:[bx],ax	; ...
@@:
	 clc			; Indicate subsegment to be loaded High

	 REGREST <ds,bx,ax>	; Restore temp variables
	 assume  ds:nothing	; Tell the assembler about it

;---------------

EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
SUBSEG_HIGH	 endp		; End SUBSEG_HIGH procedure


;***************************************************************************

	 NPPROC  ALLOC_SUBSEG -- ALLOC_SUBSEG procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Allocate space for a sub-segment

On entry:
CURR_NAPR =	Requested para count
CURR_REG  =	Requested Region

On exit:
CF	=	0 If allocation was successful
		1 if not

|

	 REGSAVE <ax,bx,cx,di,ds> ; Save registers

; Find a place to put this request

	 xor	 cx,cx		; Extend region number to 16 bits

	 mov	 bx,CURR_NPAR	; Number of paras that we need
	 mov	 cl,CURR_REG	; Region number of request
	 call	 GETMEM_REG	; Find space in specified region
	 jc	 NO_ROOM	; Jump if no room
				; Returns AX = MAC entry of free space

; Address the MAC entry

	 mov	 ds,ax		; Address the MAC entry
	 assume  ds:nothing	; Tell the assembler about it

; Store the address of this sub-segment

	 inc	 ax		; Skip over MAC entry
	 mov	 NEXT_HIGHPARA,ax ; Set as new High DOS allocation segment

; Find the top of the region (for CHECK_OVERFLOW)

	 add	 ax,ds:[MAC_STR.MAC_NPAR] ; Get top of region
	 mov	 CONFIG_UMB_MAX,ax ; ... and store for later

	 clc			; Indicate success (High DOS)

	 jmp	 EXIT		; Join common exit code

;----------------

; There is no room in the specified region
; So, this allocation will have to be in conventional memory

NO_ROOM:
	 mov	 CURR_REG,0	; This token is going low
	 mov	 CURR_NPAR,0	; ...

; GETSIZE should also report that this token is going into region 0

	 mov	 al,CURR_TOKEN	; Get current token
	 call	 GET_TOKEN	; Returns DI ==> TOKEN_STR of token 'AL'
	 jc	 @F		; Jump if token not found

	 mov	 PGROUP:[di].TOKEN_STR.REG,0 ; Set new region
@@:
	 stc			; Indicate we're going in Low DOS (failure)

EXIT:
	 REGREST <ds,di,cx,bx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
ALLOC_SUBSEG	 endp		; End ALLOC_SUBSEG procedure


;***************************************************************************

	 NPPROC  SHRINK_SUBSEG -- SHRINK_SUBSEG procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Modify the MAC entry to indicate the length of the last sub-segment
Create a new MAC entry following this one

|

	 REGSAVE <ax,cx>	; Save registers

	 cmp	 CURR_REG,0	; Was the last region "0"?
	 je	 EXIT		; Jump if so (No fixup in Low DOS)

; Shrink down the last MAC entry (to its correct size)

	 mov	 ax,NEXT_HIGHPARA ; Get last allocation address
	 dec	 ax		; Address the MAC entry
	 mov	 cx,LAST_NPAR	; Size in paras
	 call	 ALLOC_MAC	; Allocate the block (with exact size)

EXIT:
	 REGREST <cx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
SHRINK_SUBSEG endp		; End SHRINK_SUBSEG procedure


;***************************************************************************

	 NPPROC  SUBSEG_T -- SUBSEG_T procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

If the MAC entry is a "T", then perform the clean up code

* Find the location of DOS' CFG_SUBSEGLEN
* If BOA and GETSIZE version, wait for keystroke
* Display last statistic (if statistics are on)
* Calculate length of all Low DOS subsegments)
* Resize the sub-segments UMB
* Uninstall the transient UMB code/data
* Remove the Deadman switch

|

	 REGSAVE <ax,bx,dx,ds>	; Save temporary variables

;----------------

; Look for the CFG_SUBSEGLEN variable (scan DOS for this)
; This is the fourth 'magical' address that we need.

	 mov	 ds,CONFIG_SEGMENT ; Address CONFIG.SYS's code segment
	 assume  ds:nothing	; Tell the assembler about it

	 cmp	 MODELNO,2	; Izit model #2?
	 je	 SUBSEG_T1	; Jump if so (CFG_SUBSEGLEN already found)

	 mov	 bx,[bp].STACK_N1.T_RET_IP ; Get return IP

	 cmp	 WPTR ds:[bx-5],54B0h ; Do we see a <<<MOV AL,'T'>>>
	 jne	 X_SUBSEGLEN	; Jump if not, use default value

	 cmp	 BPTR ds:[bx-8],0A3h ; Do we see a <<<MOV [????],AX>>>
	 jne	 X_SUBSEGLEN	; Jump if not, use default value

	 mov	 ax,ds:[bx-7]	; Get address of sub-segment length variable
	 mov	 CFG_SUBSEGLEN,ax ; .. and save for later
SUBSEG_T1:

;----------------

if @MAX6
	 test	 LCL_FLAG,@LCL_TEST ; Are we doing the GETSIZE thing?
	 jz	 @F		; Jump if not

	 call	 PRESSANY	; Press any key to continue
@@:
endif				; IF @MAX6
;----------------

if @STATISTICS
	 call	 DISP_DBG_SUBSEGLEN ; Display address of CFG_SUBSEGLEN
endif				; If @STATISTICS

;----------------

COMMENT |

Calculate the length of all Low DOS sub-segments

We are doing this because DOS has already done this, but did it incorrectly
because it was using High DOS values for its calculation.

Note: We have to perform this code after we have restored DOS' other
      variables to their low DOS values.

|

	 mov	 ax,CONFIG_SEGMENT ; Address CONFIG.SYS's code segment
	 mov	 ds,ax		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

; Calculate length of 'Device Drivers' MAC entry

	 mov	 bx,CFG_NEXTPARA ; Find DOS' next-para variable
	 mov	 ax,ds:[bx]	; Get next sub-segment para

	 sub	 ax,FIRST_MAC	; Minus start of sub-segments
	 dec	 ax		; Don't include initial 'M' MAC entry in count

	 mov	 bx,CFG_SUBSEGLEN ; Find DOS' next-para variable
	 mov	 ds:[bx],ax	; Store as sub-segments length

;----------------

; Uninstall the transient code/data
; Note: Even if the code/data is in conventional memory, we can still free it

	 call	 REL_UMB	; Be free!

;----------------

; Remove the Deadman switch

	 REGSAVE <cx>		; Save registers

	 mov	 cx,CONFIG_NEXT ; Segment we can use for Read Buffer
	 call	 REMOVE_DEAD	; Remove the Deadman switch

	 REGREST <cx>		; Restore registers

;----------------

	 jmp	 EXIT		; Join common exit code


;-----------------
; Error conditions
;-----------------

; Error: We couldn't find the CFG_SUBSEGLEN variable within DOS
; Note: The stack is not aligned at this point

X_SUBSEGLEN:
	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:nothing	; Tell the assembler about it

	 lea	 dx,MSG_XSUBSEGLEN ; All we can do here is reboot
	 mov	 ah,09h 	; DOS: Print String function
	 int	 21h		; Tell 'em the bad news

	 jmp	 $		; Loop here till eterninty (oh well)

EXIT:
	 REGREST <ds,dx,bx,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
SUBSEG_T	 endp		; End SUBSEG_T procedure


;***************************************************************************

	 NPPROC  REL_UMB -- REL_UMB procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Release our UMB (which is really not a UMB, just a MAC entry)

|

	 REGSAVE <ax,es>	; Save registers

	 test	 LCL_FLAG,@LCL_XREMOVE ; Skip uninstall?
	 jnz	 EXIT		; Jump if user said so

	 mov	 ax,cs		; Address our own code
	 dec	 ax		; Address the MAC entry
	 mov	 es,ax		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[MAC_STR.MAC_OWNR],0 ; Free our own MAC entry

EXIT:
	 REGREST <es,ax>	; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
REL_UMB  endp			; End REL_UMB procedure


;***************************************************************************

	 NPPROC  TRANSFER_BOOT -- TRANSFER_BOOT procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Move our transient code/data to a different memory region

Note that during GETSIZE code, we can (and should) still use High DOS
to hold our transient code/data

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

; Is this request from the region that we're standing in?

	 mov	 al,CURR_REG	; Get current requested region
				; (the one to avoid)

	 cmp	 CODE_REG,al	; Is code/data in same region?
	 jne	 EXIT		; Jump if not (nothing to move)

; Start scanning the High DOS memory regions

	 xor	 ah,ah		; Extend region to 16 bits
	 mov	 si,ax		; Save 'off limits' region
	 mov	 dx,0		; Start scan at region number 1

; Determine if this region is 'off limits'

NEXT_REGION:
	 inc	 dx		; Next region

	 cmp	 dx,si		; Is this the 'off limits' region?
	 jne	 @F		; Jump if this region is fine

	 inc	 dx		; Skip this region
@@:

	 cmp	 dl,CCOM_XREG	; Is this one the CCOM region?
	 jne	 @F		; Jump if this region is fine

	 inc	 dx		; Skip this region (due to CCOM bug)
@@:

; Determine if we have run out of regions

	 cmp	 dx,10		; Is this region too high?
	 jae	 USE_LOW_DOS	; Jump if so (no memory found)

; Find a resting spot in this region

	 mov	 bx,RES_PARA	; Number of paras that we need
	 mov	 cx,dx		; Region number of request
	 call	 GETMEM_REG	; Find space in specified region
	 jc	 NEXT_REGION	; Jump if no room in region
				; Returns AX = MAC entry of free space

	 jmp	 USE_HIGH_DOS	; We have a valid High DOS segment

; This request will be from Conventional memory

USE_LOW_DOS:

	 mov	 ax,cs		; Get our current segment
	 dec	 ax		; Point to pseudo MAC entry

	 cmp	 ax,FLOAT_SEG	; Are we already in the floater?
	 je	 EXIT		; Jump if so (no reason to move)

	 mov	 ax,FLOAT_SEG	; This is the region 0 destination
	 mov	 dx,0		; Specify region 0 for code/data


; Modify the old MAC so that it is free again
; We can do this even if the old MAC was in Low DOS
; AX = MAC segment

USE_HIGH_DOS:

	 cmp	 CODE_REG,-1	; First time around?
	 je	 @F		; Jump if so

	 mov	 bx,cs		; Address old code/data
	 dec	 bx		; Address the MAC entry
	 mov	 es,bx		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[MAC_STR.MAC_OWNR],0 ; Free the entry
@@:

; Modify the new MAC so that we 'own' it
; We can do this even if loading into conventional memory

	 mov	 es,ax		; Address our transient destination
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[MAC_STR.MAC_OWNR],1234h ; Set owner field

; Save new code/data region for next time around

	 xchg	 CODE_REG,dl	; Save new region for code/data in memory
				; Get old transient region in DL

; Bootstrap our resident code to the UMB

	 inc	 ax		; Skip over MAC entry
	 mov	 es,ax		; Address our transient destination
	 assume  es:nothing	; Tell the assembler about it

	 mov	 TRANSFER_VEC.VVSEG,es ; Save new code/data segment

	 mov	 si,BOOT_OFF	; Start of resident code
	 xor	 di,di		; Destination offset

	 mov	 cx,BOOT_LEN	; Size of resident code
     rep movs	 BPTR es:[di],cs:[si] ; Move the code to our UMB
	 nop			; To allow for easier debugging

POST_BOOT:

; AX = New code segment

;--------

; Patch the CONFIG.SYS sub-segment memory allocation handler

	 cmp	 CURR_PASS,@PASS_DEV ; Izit DEVICE= time?
	 jne	 LCL_XDEV	; Jump if not

	 mov	 es,CONFIG_SEGMENT ; Address CONFIG.SYS
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 DOSVER.HILO_STR.HI,3 ; Is this DOS 3?
	 je	 BOOT3		; Jump if so

; Patch the CONFIG.SYS sub-segment memory allocation handler (DOS4+)

	 mov	 di,CONFIG_OFFSET ; Address the patch point

	 push	 dx		; Save for a moment

	 mov	 dx,CONFIG_LOCAL ; Get offset of local allocate routine

	 mov	 BPTR es:[di],@OPCOD_JMPF	 ; Patch in the Far JMP
	 mov	 WPTR es:[di+1],dx		 ; ...		Offset
	 mov	 WPTR es:[di+3],ax		 ; ...		Segment

	 pop	 dx		; Restore

	 jmp	 LCL_XDEV	; Join common code

BOOT3:

; Patch the PROCESS_FILES code in CONFIG.SYS (DOS3)

	 mov	 di,HOOK_OFFSET ; Address the patch point

	 mov	 BPTR es:[di],@OPCOD_CALLF	 ; Patch in the Far CALL
	 mov	 WPTR es:[di+1],LOCAL_DOS3_HOOK  ;		Offset
	 mov	 WPTR es:[di+3],ax		 ; ...		Segment

; Patch the DOS3 SUBSEGS_COMPLETE code (DOS3)

	 mov	 di,UNHOOK_OFFSET ; Address the patch point

	 mov	 BPTR es:[di],@OPCOD_CALLF	 ; Patch in the Far CALL
	 mov	 WPTR es:[di+1],LOCAL_DOS3_UNHOOK ;		Offset
	 mov	 WPTR es:[di+3],ax		 ; ...		Segment

LCL_XDEV:

;--------

; Hook interrupt 21h, with the intention of finding
; Interrupt 21h, function 4Bh

	 cmp	 CURR_PASS,@PASS_INS ; Izit INSTALL= time?
	 jne	 short @F	; Jump if not

	 test	 LCL_FLAG,@LCL_REL21 ; Did we already release int21?
	 jnz	 short @F	; Jump if so (don't adjust the vector)

	 REGSAVE <dx,ds>	; Save registers

	 mov	 ds,ax		; Address the new handler (in our UMB)
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ah,@SETINT	; DOS: Set interrupt vector function
	 mov	 al,21h 	; We are hooking interrupt 21h
	 lea	 dx,LOAD_CCOM_HI ; Resident offset of handler
	 int	 21h		; Set interrupt vector in AL to DS:DX

	 REGREST <ds,dx>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it
@@:
;--------

; Jump to the new segment

	 cmp	 dl,-1		; First time around?
	 je	 TRANSFER_LOC	; Jump if so (don't switch CS) yet

	 jmp	 TRANSFER_VEC	; Jump to new segment

	 public  TRANSFER_LOC
TRANSFER_LOC::

EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
TRANSFER_BOOT	 endp		; End TRANSFER_BOOT procedure


;***************************************************************************

	 NPPROC  SET_IGNFLEX -- Set MAXs IGNFLEX bit
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Set MAX's IGNORE_FLEXFRAME bit

|

	 REGSAVE <bx,ds>	; Save registers

; Find some free memory for the info structure

	 mov	 ds,CONFIG_NEXT ; Address DOS' next available segment
	 assume  ds:nothing	; Tell the assembler about it

; Open and Read in the INFO structure

	 call	 INFO_READ	; Read in the INFO structure
				; Return BX = Device handle

; Set the IGNORE_FLEXFRAME bit in the info structure

	 or	 ds:[@INFO_OFFSET+INFO_STR.INFO_CMD],@CMD_IGNFLEX ; Set bit

; Write out (and close) the INFO structure

	 call	 INFO_WRITE	; Modify MAX's info structure

	 REGREST <ds,bx>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
SET_IGNFLEX	 endp		; End SET_IGNFLEX procedure


;***************************************************************************

	 NPPROC  INFO_READ -- INFO_READ procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Read in the MAX info structure

On entry:
DS	=	Segment of INFO structure buffer

On exit:
BX	=	File handle

|

	 REGSAVE <ax,cx,dx>	; Save registers

; Address our resident data

	 REGSAVE <ds>		; Save buffer pointer

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

; Open the MAX device driver

	 mov	 al,02h 	; Access code for read/write
	 mov	 ah,@OPENF2	; DOS: Attempt to open device driver (3Dh)
	 lea	 dx,DEVNAME_MAX ; DS:DX ==> 386MAX$$ Device name
	 int	 21h		; Open the file 	      <----\
				;				   |
	 REGREST <ds>		; Restore buffer pointer	   |
	 assume  ds:nothing	; Tell the assembler about it	   |
				;				   |
	 jc	 EXIT		; Jump if device not found  <------/

	 mov	 bx,ax		; Copy to handle register

; Ensure it's a device
; (we've already done that during initialization)

; Read in the info structure

	 mov	 BPTR ds:[@CTL_OFFSET],@CTL_XFER ; Mark as Info transfer

	 mov	 al,02h 	; Read from device
	 mov	 ah,@IOCTL2	; DOS: Read IOCTL information (44h)
;;;;;;;; mov	 bx,??		; Get device handle (already set)
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 dx,@CTL_OFFSET ; Offset for info structure buffer
	 int	 21h		; Get IOCTL info into INFO
	 jc	 READ_ERR	; Jump if error

READ_ERR:
EXIT:
	 REGREST <dx,cx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
INFO_READ	 endp		; End INFO_READ procedure

;***************************************************************************

	 NPPROC  INFO_WRITE -- INFO_WRITE procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Write out the INFO structure

On entry:
BX	=	File handle
DS	=	Segment of INFO structure buffer

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

; Write out the info structure

	 mov	 al,03h 	; Write to device
	 mov	 ah,@IOCTL2	; Set IOCTL info from INFO (44h)
;;;;;;;; mov	 bx,??		; Get device handle (already set)
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 dx,@CTL_OFFSET ; Offset for info structure buffer
	 int	 21h		; Write the new info structure to MAX

; Close the device driver

READ_ERR:
	 mov	 ah,@CLOSF2	; Close the 386MAX device (3Eh)
	 int	 21h		; Close the device driver

EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
INFO_WRITE	 endp		; End INFO_WRITE procedure


;***************************************************************************

	 NPPROC  GET_FILE_LEN -- GET_FILE_LEN procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Find the length of DOS' file structure.
Pass this information to MAX for the VxD to use.

We're doing this here because Windows only searches within the first
512 KB for the FILEs structures.

On entry:
AL	=	MAC Type 'F'
DI	=	Caller's return IP (within CONFIG.SYS)

Note: Even if FILES are going in region 0, we still need to
      determine the size of one SFT entry so that GETSIZE can
      determine the size of High FILES (one SFT will stay low)

|

	 REGSAVE <ax,bx,cx,di,ds,es> ; Save registers
	 pushf			; Save direction flag

	 cmp	 PORT67,0	; Did we find MAX?
	 je	 EXIT		; Jump if not

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 es,CONFIG_SEGMENT ; Address DOS's transient segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 bl,SFT_STRLEN	; Get size of one file

	 cmp	 MODELNO,2	; Izit model #2?
	 je	 FILE1		; Jump if so (SFT_STRLEN already found)

; Find the model code that will allow us to find the size of each FILE entry

	 mov	 cx,50h 	; Length of search area
	 mov	 al,0B3h	; First opcode
	 cld			; String ops forward
FILE_NEXT:
   repne scasb			; Search for first opcode byte
	 jnz	 EXIT		; Jump if not found

	 cmp	 WPTR es:[di+1],0E3F6h ; Look for <<<MUL BL>>>
	 jne	 FILE_LOOP	; Jump if not

	 cmp	 WPTR es:[di+3],0C88Bh ; Look for <<<MOV CX,AX>>>
FILE_LOOP:
	 loopne  FILE_NEXT	; Jump if not

; Send the size of one FILE entry to MAX (via EMM2)

	 mov	 bl,es:[di]	; Get size of file entry
	 mov	 SFT_STRLEN,bl	; Save for MOVE_SFT_HIGH
FILE1:
	 cmp	 FILES_REG,0	; Are the remainder of the FILEs going High?
	 je	 EXIT		; Jump if all FILES are going Low

	 push	 bp		; Save BP
	 mov	 bp,sp		; Save SP (in case MAX trashes it)

	 mov	 al,@HARPO_SET_INFO ; Send FILES= info to HARPO
	 EMMOUT  @EMM2_HARPOINFO ; Pass FILES= information to MAX

	 mov	 sp,bp		; Restore SP
	 pop	 bp		; Restore BP

EXIT:
	 popf			; Restore direction flag
	 REGREST <es,ds,di,cx,bx,ax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
GET_FILE_LEN	 endp		; End GET_FILE_LEN procedure


;***************************************************************************

	 NPPROC  MOVE_SFT_HIGH -- MOVE_SFT_HIGH procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Move all but one SFT from Low DOS to High DOS

This is done because Windows instances the FILE_ATTRIBUTE word from
the first SFT (not including the 5 internal SFTs).  Windows also uses
the address of this instance item as a breakpoint in calculating the
lengths of other instance items.  If this SFT is in High DOS, then
Windows will incorrectly calculate the instance length of the last
device driver in the device driver chain.

Phase I:  Calculate all the information (for GETSIZE)
Phase II: Move the Files into High DOS (if requested)

On entry:
AL	=	Subsegment type (F,X,B,L,S)

|

	 REGSAVE <ax,bx,cx,dx,di,es> ; Save registers

	 cmp	 al,@TOKEN_FCB	; Is it FCBs=
	 jne	 EXIT		; Jump if not

;--------------;
;   PHASE I    ;
;--------------;

; Address the correct SFT table

	 mov	 ah,@GETLST	; DOS: List of Lists function (52h)
	 int	 21h		; DOS Services (Return in ES:BX)
	 assume  es:nothing	; Tell the assembler about it

	 les	 bx,es:[bx+4]	; Address the internal SFTs
	 assume  es:nothing	; Tell the assembler about it

	 les	 bx,es:[bx]	; Address the subsegment SFTs
	 assume  es:nothing	; Tell the assembler about it

	 mov	 FILES_SEG,es	; Save segment of Low FILES

; ES:BX = Pointer to Low FILES

;---------------

; Calculate the size of the High FILES

	 mov	 ax,es:[bx+4]	; Get the number of SFTs in this block

	 dec	 ax		; Number of SFTs to be moved High
	 mul	 SFT_STRLEN	; Multiply (AL*3B ==> AX)
	 mov	 di,ax		; Save size for later STOSB
	 add	 ax,6+0Fh	; Add size of header (and round up)
	 shr	 ax,1		; Convert from bytes to paras
	 shr	 ax,1		; ...
	 shr	 ax,1		; ...
	 shr	 ax,1		; ...
	 inc	 ax		; Include subsegment MAC entry

	 mov	 FILES_PARA,ax	; Save for this routine
	 mov	 LAST_NPAR,ax	; Save for VALIDATE_SIZE

; DI = Size of High FILES in bytes

;---------------

; Are we actually moving the FILES to High DOS memory?

	 cmp	 FILES_REG,0	; FILES to be loaded low?
	 je	 EXIT		; Jump if so

;--------------;
;   PHASE II   ;
;--------------;

; Move our transient code out of the way

	 mov	 al,CURR_REG	; Save the requested region

	 mov	 ah,FILES_REG	; Get the FILES= region
	 mov	 CURR_REG,ah	; ... and store for TRANSFER_BOOT

	 call	 TRANSFER_BOOT	; Move transient code out of the way
	 nop			; Make debugging easier

	 mov	 CURR_REG,al	; Restore the requested region

;---------------

; Find High DOS memory for the High FILES

	 REGSAVE <bx>		; Save SFT table pointer

	 mov	 cl,FILES_REG	; Region of High FILES=
	 mov	 bx,FILES_PARA	; Size of High FILES= (in paras)
	 call	 GETMEM_REG	; Find space in specified region
				; Returns AX = MAC entry of free space

	 mov	 cx,bx		; Save Size of High FILES (for ALLOC_MEM)

	 REGREST <bx>		; Restore SFT table pointer
	 jc	 NO_ROOM	; Jump if no room

; AX = MAC entry of free space

;---------------

; Allocate High DOS memory for the High FILES

	 REGSAVE <ax>		; Save segment of MAC entry

;;;;;;;; mov	 ax,??		; Segment of MAC entry (already set)
;;;;;;;; mov	 cx,??		; Size in paras (already set)
	 call	 ALLOC_MAC	; Allocate a MAC at this address

	 REGREST <ax>		; Restore segment of MAC entry

	 inc	 ax		; Skip over MAC entry

;---------------

; Apply the appropriate name to the High Files entry

	REGSAVE <ax,bx,cx,si>	; Save registers

	 mov	 cl,@TOKEN_FILES ; Identify as a FILES subsegment MAC
;;;;;;;; mov	 ax,NEXT_HIGHPARA ; Subsegment address (already set)
	 mov	 bx,@MAC_SUBSEG_DOS ; Special owner for MAXIMIZE's sake
	 lea	 si,MAC_NAME_F	; Get MAC name FILES= entry
	 call	 APPLY_MAC_NAME ; Label the sub-segment MAC entry

	REGREST <si,cx,bx,ax>	; Restore registers

;---------------

; AX	= Segment of High FILES
; ES:BX = Ptr to SFTs

; Initialize Low DOS SFTs

	 mov	 es:[bx].VVOFF,0  ; Point to High DOS SFTs
	 mov	 es:[bx].VVSEG,ax ; ...
	 inc	 es:[bx].VVSEG	  ; Skip over subsegment MAC entry

	 mov	 cx,1		; New number of Low SFTs
	 xchg	 es:[bx+4],cx	; Only leave 1 SFT in Low memory
				; Get original number of SFTs

;---------------

; Resize the NEXT_PARA pointer (Adjust size of Low FILES)

	 REGSAVE <ax,bx,ds>	; Save registers

; Address DOS'code/data

	 mov	 ds,CONFIG_SEGMENT ; Address DOS' code/data
	 assume  ds:nothing	; Tell the assembler about it

; Save next sub-segment pointer (if it points to DOS)

	 mov	 ax,di		; Size of High FILES
	 and	 ax,0FFF0h	; Round down to para
	 shr	 ax,1		; Convert from bytes to paras
	 shr	 ax,1		; ...
	 shr	 ax,1		; ...
	 shr	 ax,1		; ...

	 mov	 bx,CFG_NEXTPARA ; Find DOS' next-para variable
	 sub	 ds:[bx],ax	; Set next CONFIG sub-segment

; Reset the subseg size (of the Low Files portion)

	 mov	 bx,FILES_SEG	; Segment of Low FILES
	 dec	 bx		; Address the MAC
	 mov	 es,bx		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

	 sub	 es:[MAC_STR.MAC_NPAR],ax ; Save as new Low FILES size

	 REGREST <ds,bx,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

;---------------

; Create the subsegment MAC entry for High FILES

	 mov	 es,ax		; Address the High SFTs
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[MAC_STR.MAC_TYPE],@TOKEN_FILES ; This is a FILES= entry

	 mov	 es:[MAC_STR.MAC_OWNR],es  ; This entry should own itself
	 inc	 es:[MAC_STR.MAC_OWNR]	   ; ...

	 mov	 dx,FILES_PARA	; Get size of subsegment
	 dec	 dx		; Don't include subsegment MAC entry
	 mov	 es:[MAC_STR.MAC_NPAR],dx  ; Store in subsegment MAC

;---------------

; Initialize High DOS SFTs

	 inc	 ax		; Skip over the subsegment MAC entry
	 mov	 es,ax		; Address the High files
	 assume  es:nothing	; Tell the assembler about it

	 dec	 cx		; Number of High SFTs
	 mov	 es:[bx+4],cx	; ...

	 mov	 es:[bx].VVOFF,-1 ; End of SFT chain
	 mov	 es:[bx].VVSEG,-1 ; ...

	 xor	 ax,ax		; A handy zero
	 mov	 cx,di		; Size of High SFT table (in bytes)
	 sub	 cx,6		; Minus link and count fields
	 mov	 di,6		; New SFT table, skip over link and count fields
     rep stosb			; Clear High table

;---------------

; Pass the correct region information to the token structure

	 mov	 al,@TOKEN_FILES ; We are looking for the FILES= entry
	 call	 GET_TOKEN	; Returns DI ==> TOKEN_STR of token 'AL'
	 jc	 @F		; Jump if token not found (CF significant)

	 mov	 al,FILES_REG	; Get region of High FILES
	 mov	 PGROUP:[di].TOKEN_STR.REG,al ; Set requested region
@@:

	 jmp	 EXIT		; Join common exit code

;---------------

; There is no room to move the FILES= into High DOS
; Tell the user about this situation here

NO_ROOM:
	 REGSAVE <ds>		; Save register

	 push	 cs		; Address our warning text
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 lea	 di,MSG_MAXIMIZE1 ; Tell 'em to run MAXIMIZE
	 call	 DISP_COPY	; Display copyright and message

	 DOSCALL @STROUT,MSG_FILES ; Display the FILES= message
	 DOSCALL @STROUT,MSG_MAXIMIZE2 ; Display end of message

	 call	 PRESSANY	; Make sure they see the error message

	 REGREST <ds>		; Restore
	 assume  ds:nothing	; Tell the assembler about it

;---------------

EXIT:
	 REGREST <es,di,dx,cx,bx,ax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
MOVE_SFT_HIGH	 endp		; End MOVE_SFT_HIGH procedure


;***************************************************************************

	 NPPROC  ALLOC_MAC -- ALLOC_MAC procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Allocate a MAC at the specified address

On entry:
AX	=	Segment of MAC entry
CX	=	Size of Allocation

|

	 REGSAVE <ax,bx,cx,dx,es> ; Save registers

	 mov	 es,ax		; Address the MAC entry
	 assume  es:nothing	; Tell the assembler about it

; Get/Set MAC1 Type

	 mov	 dl,es:[MAC_STR.MAC_TYPE]  ; Get current MAC type

; Set MAC1 Owner

	 mov	 es:[MAC_STR.MAC_OWNR],@MAC_SUBSEG_DOS ; Set MAC1 Owner

; Get/Set MAC1 Size

	 mov	 bx,es:[MAC_STR.MAC_NPAR] ; Get MAC1 Size
	 mov	 es:[MAC_STR.MAC_NPAR],cx ; Set MAC1 Size

; Clear back link field.  Name and drive / subseg type may already be set
	 mov	 es:[MAC_STR.MAC_BACK],0 ; Clear LSEG back link

; Calculate new size

	 inc	 cx		; Include MAC entry

	 sub	 bx,cx		; Get size of MAC2
	 jb	 EXIT		; Jump if snug fit

	 mov	 es:[MAC_STR.MAC_TYPE],@MAC_MID ; Mark as middle entry

	 add	 ax,cx		; Address MAC2
	 mov	 es,ax		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

; Set MAC2 Type, Owner, Size

	 mov	 es:[MAC_STR.MAC_TYPE],dl ; Set MAC2 Type
	 mov	 es:[MAC_STR.MAC_OWNR],0  ; Set MAC2 Owner
	 mov	 es:[MAC_STR.MAC_NPAR],bx ; Set MAC2 Size

; Clear name, back link, and drive fields
	 mov	 es:[MAC_STR.MAC_BACK],0 ; Clear LSEG back link
	 mov	 es:[MAC_STR.MAC_DRV],0 ; Clear drive / subseg type
	 mov	 es:[MAC_STR.MAC_NAME],0 ; Clear start of name

EXIT:
	 REGREST <es,dx,cx,bx,ax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
ALLOC_MAC	 endp		; End ALLOC_MAC procedure

;***************************************************************************

	 NPPROC  APPLY_MAC_NAME -- APPLY_MAC_NAME Procedure
	 assume  ds:nothing,es:nothing,ss:nothing

COMMENT |

Place name in the MAC field for MAPMEM's benefit
Also fill in the MAC owner with correct value

Note: This routine applies a name to the MAC entry (not an LSEG)

On entry:
AX	=	Segment to change MAC entry
BX	=	New MAC owner
CL	=	Token type to save in MAC_DRV field
SI	=	Offset (within resident code) of new 8 byte MAC name

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

; Address the MAC entry

	 dec	 ax		; Address the UMB's MAC entry
	 mov	 es,ax		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

; Set the owner field

	 mov	 es:[MAC_STR.MAC_OWNR],bx ; Set new owner

; Clear the LSEG back link

	 mov	 WPTR es:[MAC_STR.MAC_BACK],0 ; Not associated with an LSEG

; Save token type in drive field to simplify display code

	 mov	 es:[MAC_STR.MAC_DRV],cl ; Save token

; Set the name field

	 mov	 di,MAC_STR.MAC_NAME ; Offset within MAC structure (destin)
	 mov	 cx,8/2 	; Word count of name field

     rep movs	 WPTR es:[di],PGROUP:[si] ; Fill in the name field

	 REGREST <es,di,si,cx,ax> ; Restore registers
	 assume  es:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

APPLY_MAC_NAME	 endp		; End APPLY_MAC_NAME procedure


;****************************************************************************

	 FPPROC  LOCAL_DOS3_HOOK -- LOCAL_DOS3_HOOK procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Local hook for DOS 3.30

|

; DS = Code/Data Segment of CONFIG.SYS

	 push	 bp		; Save register
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,ds>	; Save registers

	 SWATTER		; Call debugger if requested

	 mov	 ds,CONFIG_SEGMENT ; Address CONFIG.SYS (already set)
	 assume  ds:nothing	; Tell the assembler about it

;---------------

; Find a region for this sub-segment allocation

	 REGSAVE <ax,di>	; Save registers

	 mov	 CURR_REG,0	; Assume this token is going low
	 mov	 CURR_NPAR,0	; ...

	 mov	 al,@TOKEN_DOS3 ; Look for the 'All subsegs' token
	 call	 GET_TOKEN	; Returns DI ==> TOKEN_STR of token 'AL'
	 jc	 @F		; Jump if token not found (CF significant)

	 mov	 ax,PGROUP:[di].TOKEN_STR.NPAR ; Get requested size
	 mov	 CURR_NPAR,ax	; ... and save for later

	 mov	 al,PGROUP:[di].TOKEN_STR.REG ; Get requested region
	 mov	 CURR_REG,al	; ... and save for later

	 mov	 ax,PGROUP:[di].TOKEN_STR.MACNAME ; Get MAC name address
	 mov	 CURR_NAME,ax	; ... and save for later

@@:
	 REGREST <di,ax>	; Restore registers

;---------------

	 call	 TRANSFER_BOOT	; Move transient code out of the way
	 nop			; Make debugging easier

;---------------

; Allocate space for this sub-segment

	 cmp	 CURR_REG,0	; Going Low?
	 je	 @F		; Jump if so

	 call	 ALLOC_SUBSEG	; Alloc space for this subseg
				; If CY, then we're already set for Low DOS load
@@:

;---------------

; Apply the appropriate name to this entry

	 REGSAVE <ax,bx,si>	; Save registers

	 cmp	 CURR_REG,0	; Are the subsegs going low?
	 je	 @F		; Jump if so

	 mov	 ax,NEXT_HIGHPARA ; Point to sub-segs segment
	 mov	 bx,@MAC_SUBSEG_DOS ; Special owner for MAXIMIZE's sake
	 mov	 cl,@TOKEN_DOS3 ; Get token for this entry
	 mov	 si,CURR_NAME	; Get MAC name of current token
	 call	 APPLY_MAC_NAME ; Label the sub-segment MAC entry

@@:
	 REGREST <si,bx,ax>	; Restore registers

;---------------

; Save (and modify) the High Water marker

	 mov	 bx,CFG_HIGHWATER ; Address High Water marker

	 mov	 ax,ds:[bx]	; Get High Water marker
	 mov	 CONFIG_TOP,ax	; Save for later

	 mov	 WPTR ds:[bx],-1 ; Set new high Water as 0FFFFh

;---------------

; Save (and modify) next_para

	 mov	 bx,CFG_NEXTPARA ; Address Next avail para

	 mov	 ax,ds:[bx]	; Get Next avail para
	 mov	 CONFIG_NEXT,ax ; Save for later

	 cmp	 CURR_REG,0	; Are the subsegs going low?
	 je	 @F		; Jump if so

	 mov	 ax,NEXT_HIGHPARA ; Get segment of our UMB
	 mov	 WPTR ds:[bx],ax ; ... and save as next_para
@@:

	 mov	 LAST_ALLOC,ax	; Save for getsize calculations

;---------------

; Remove patch in PROCESS_FILES code

	 mov	 bx,HOOK_OFFSET ; Address our patch

	 mov	 ax,WPTR CODE1_SAVE	;
	 mov	 ds:[bx]+0,ax	; Restore patch

	 mov	 ax,WPTR CODE1_SAVE+2 ;
	 mov	 ds:[bx]+2,ax ; Restore patch

	 mov	 al,CODE1_SAVE+4 ;
	 mov	 ds:[bx]+4,al ; Restore patch

;---------------

; Patch the return IP so that we can repeat the (now unpatched) instruction

	 sub	 [bp].STACK_F.RET_IP,5 ; Repeat the last instruction

	 REGREST <ds,cx,bx,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore register

	 retf			; Return to CONFIG.SYS processor

	 assume  ds:nothing,es:nothing,ss:nothing
LOCAL_DOS3_HOOK  endp		; End LOCAL_DOS3_HOOK procedure


;****************************************************************************

	 FPPROC  LOCAL_DOS3_UNHOOK -- LOCAL_DOS3_UNHOOK procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Local UNHOOK for DOS 3.30

|

; DS = Code/Data Segment of CONFIG.SYS

	 push	 bp		; Save register
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,ds>	; Save registers

	 SWATTER		; Call debugger if requested

	 mov	 ds,CONFIG_SEGMENT ; Address CONFIG.SYS (already set)
	 assume  ds:nothing	; Tell the assembler about it

;----------------

	 mov	 LAST_SUBSEG,@TOKEN_DOS3 ; The only valid subseg under DOS 3.3

;----------------

; Perform all the size-related routines first

	 call	 FILL_GETSIZE	; Fill in MAX's GETSIZE table

	 call	 VALIDATE_SIZE	; Ensure the size requested is correct

	 call	 CHECK_OVERFLOW ; See if we have an overflowed region

;----------------

; Restore High Water marker

	 mov	 bx,CFG_HIGHWATER ; Address High Water marker

	 mov	 ax,CONFIG_TOP ; Get High Water marker
	 mov	 WPTR ds:[bx],ax ; .. and restore it

;----------------

; Restore next_para marker

	 mov	 bx,CFG_NEXTPARA ; Address next_para marker

	 mov	 ax,ds:[bx]	; Get top of UMB marker
	 mov	 NEXT_HIGHPARA,ax ; ... and save for later

	 cmp	 CURR_REG,0	; Going Low?
	 je	 @F		; Jump if so

	 mov	 ax,CONFIG_NEXT ; Get next_para marker
	 mov	 ds:[bx],ax ; .. and restore it
@@:


;----------------

; Remove patch in SUBSEGMENTS_COMPLETE code

	 mov	 bx,UNHOOK_OFFSET ; Address our patch

	 mov	 ax,WPTR CODE2_SAVE ;
	 mov	 ds:[bx]+0,ax	; Restore patch

	 mov	 ax,WPTR CODE2_SAVE+2 ;
	 mov	 ds:[bx]+2,ax	; Restore patch

	 mov	 al,CODE2_SAVE+4 ;
	 mov	 ds:[bx]+4,al	; Restore patch

;----------------

; Resize the sub-segment (create new MAC entry if needed)

	 REGSAVE <bx,cx,dx,es>	; Save registers

	 cmp	 CURR_REG,0	; Going Low?
	 je	 NO_SUBMAC	; Jump if so (no MAC diddling)

	 mov	 ax,NEXT_HIGHPARA ; Get DOS' version of Top of sub-segments
	 sub	 ax,LAST_ALLOC	; Minus the start of it all

	 mov	 bx,LAST_ALLOC	; Address the subseg start
	 dec	 bx		; Address the subseg MAC entry
	 mov	 es,bx		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[MAC_STR.MAC_OWNR],@MAC_SUBSEG_DOS ; Set MAC type

	 cmp	 es:[MAC_STR.MAC_NPAR],ax ; Do the subsegs fit snuggly?
	 je	 NO_SECOND_MAC	; Jump if so

	 xchg	 es:[MAC_STR.MAC_NPAR],ax ; Get/Set length of sub-segs

	 sub	 ax,es:[MAC_STR.MAC_NPAR] ; Calcualte second MAC length
	 dec	 ax		; Minus the MAC entry

	 mov	 dl,'M'         ; Middle entry
	 xchg	 es:[MAC_STR.MAC_TYPE],dl ; Get/Set MAC type

	 mov	 cx,es		; Get MAC address
	 add	 cx,es:[MAC_STR.MAC_NPAR] ; Plus size of MAC entry
	 inc	 cx		; Include MAC entry
	 mov	 es,cx		; Address new MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[MAC_STR.MAC_TYPE],dl ; Set new type
	 mov	 es:[MAC_STR.MAC_OWNR],0 ;  Set new length
	 mov	 es:[MAC_STR.MAC_NPAR],ax ; Set knew owner
NO_SECOND_MAC:
NO_SUBMAC:

	 REGREST <es,dx,cx,bx>	; Restore registers
	 assume  es:nothing	; Tell the assembler about it

;----------------

; Remove the Deadman switch

	 REGSAVE <bx,cx>	; Save registers

	 mov	 bx,CFG_NEXTPARA ; Get next_para marker
	 mov	 cx,ds:[bx]	; ... and use for Read/Write buffer
	 call	 REMOVE_DEAD	; Remove the Deadman switch

	 REGREST <cx,bx>	; Restore registers

;----------------

; If special version for BOA, wait for user input so that the
; GETSIZE information can be read from the screen

if @MAX6
	 test	 LCL_FLAG,@LCL_TEST ; Are we doing the GETSIZE thing?
	 jz	 @F		; Jump if not

	 call	 PRESSANY	; Press any key to continue
@@:
endif				; IF @MAX6

;----------------

; Uninstall the transient UMB code/data

	 call	 REL_UMB	; Be free!


;----------------

; Patch the return IP so that we can repeat the (now unpatched) instruction

	 sub	 [bp].STACK_F.RET_IP,5 ; Repeat the last instruction

	 REGREST <ds,bx,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore register

	 retf			; Return to CONFIG.SYS processor

	 assume  ds:nothing,es:nothing,ss:nothing
LOCAL_DOS3_UNHOOK endp		; End LOCAL_DOS3_UNHOOK procedure


;***************************************************************************

if @STATISTICS
	 NPPROC  DISP_DBG_SUBSEGLEN -- DISP_DBG_SUBSEGLEN Procedure
	 assume  ds:nothing,es:nothing,ss:nothing

COMMENT |

Display CFG_SUBSEGLEN (this is tricky because we have to do this from
the UMB.  That means all of our displaying support code has to be
resident too).

|

	 REGSAVE <ax,dx,di,ds,es> ; Save registers

	 push	 cs		; Address our data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 cs		; Address our resident data
	 pop	 es		; ... via ES
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 ax,CFG_SUBSEGLEN ; Address of DOS' sub_segment_len variable
	 lea	 di,offset PGROUP:MSG_DBG_SUBSEGLEN1 ; Address of message
;;;;;;;; call	 FMT_WORD	; Format the variable into string (see below)

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 lea	 bx,HEXTABLE2	; CS:BX ==> translate table
	 mov	 cx,4		; # hex digits in a word
	 mov	 dx,ax		; Copy to test
@@:
	 rol	 dx,1		; Copy the high-order digit
	 rol	 dx,1		; Copy the high-order digit
	 rol	 dx,1		; Copy the high-order digit
	 rol	 dx,1		; Copy the high-order digit
	 mov	 al,dl		; Copy to XLAT register
	 and	 al,0Fh 	; Isolate hex digit
	 xlat	 HEXTABLE2	; Translate to ASCII
	 stosb			; Save into output area

	 loop	  @B		; Jump if more digits to convert

	 REGREST <dx,cx,bx,ax>	; Restore

	 mov	 ah,09h 	; DOS: Print String function
	 lea	 dx,MSG_DBG_SUBSEGLEN ; Address of string
	 int	 21h		; Display the message

EXIT:
	 REGREST <es,ds,di,dx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

	 public  MSG_DBG_SUBSEGLEN
MSG_DBG_SUBSEGLEN  db	@HNAME,': Sub-Segment Length is at offset '
MSG_DBG_SUBSEGLEN1 db	'____'
		   db	CR,LF,LF,EOS

	 public  HEXTABLE2
HEXTABLE2 db	 '0123456789ABCDEF' ; Used for resident debugging

DISP_DBG_SUBSEGLEN endp 	; End DISP_DBG_SUBSEGLEN procedure
endif				; If @STATISTICS


;****************************************************************************

HCODE	 ends			; End Resident Code segment


;****************************************************************************

HDATA	 segment		; Start Non-Resident Data segment



HDATA	 ends			; End non-Resident Data segment

;****************************************************************************

HNCODE	 segment		; Start Non-Resident Code Segment



;*************************************************************************

HNCODE	 ends			; End Non-Resident Code Segment


	 END			; End HARP_DEV module




