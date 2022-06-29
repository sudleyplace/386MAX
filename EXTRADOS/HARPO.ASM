;'$Header:   P:/PVCS/MAX/EXTRADOS/HARPO.ASV   1.1   30 May 1997 11:13:08   BOB  $
	 title	 HARPO -- Relocate portions of CONFIG.SYS to High DOS
	 page	 58,122
	 name	 HARPO

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
	 include IOCTL.INC
	 include OPCODES.INC
	 include DEVDRV.INC
	 include INTVEC.INC

	 include LOAD_SEG.INC
	 include EMM2CALL.INC
	 include QMAXINFO.INC
	 include QMAX_MSC.INC
	 include SEGS.INC
	 include HARPO.INC
.list

;***************************************************************************


	 public  @GSIZE_PAT1,@GSIZE_PAT2
@GSIZE_PAT1 equ  0F1CCh 	; GETSIZE pattern #1 (Int 03, ICE Int 01)
@GSIZE_PAT2 equ  09066h 	; GETSIZE pattern #2 (NOPD)

PSP_SEG  segment at 0 ; Start PSP segment

	 public  PSP_ENVIR_PTR,PSP_TERMINATE,PSP_CTRL_BREAK,PSP_CRIT_ERROR
	 public  PSP_FILE_TAB_PTR,PSP_CTRL_PSP
	 include PSP.INC	; This structure must be within a segment

PSP_SEG  ends			; End PSP segment


;***************************************************************************

HTAIL	 segment		; End of Resident Code segment

COMMENT |

This is the divisor betwwen Resident Code and Non-Resident Code

|

	 public  LAST_BYTE
LAST_BYTE::			; Last byte of resident code (for UMB)


HTAIL	 ends			; End Tail Segment


;***************************************************************************
HCODE	 segment		; Start Resident Code segment

; These variables are all resident !!!

	 public  FIRST_BYTE
FIRST_BYTE::				; First byte of resident code

	 public  DEVDRV
DEVDRV	 DD_STR  <-1,			  \	; Far pointer to next DD
		  DRV_ATTR_CHAR,	  \	; Attributes
		  offset PGROUP:DEV_STRA, \	; Strategy routine offset
		  offset PGROUP:DEV_INTR, \	; Action routine offset
		  @DEVNAME>			; Device name

	 public  RH_VEC
RH_VEC	 dd	 ?		; Ptr to device driver request header

	 public  OLDSTK_VEC,NEWSTK_VEC
OLDSTK_VEC dd	 ?		; Save area for old stack pointer
NEWSTK_VEC dd	 PGROUP:NEWSTKZ ; Ptr to top of new ...

	 public  FLOAT_SEG
FLOAT_SEG  dw	 ?		; Segment of our floater (if needed)


;------------- Non-Resident routines -----------------------

extern	 CHECK_ALTKEY:near	; Abort if the Alt key is pressed at startup
extern	 PRESSANY:near		; Press any Key to Continue
extern	 CHECK_DOSVER:near	; Get the DOS vesion number
extern	 GET_FIRST_MAC:near	; Get segment of first MAC entry
extern	 MAX_PRESENT:near	; Determine if 386MAX is present
extern	 CHECK_HIGH:near	; Determine if we are being 386LOADed
extern	 GET_PROFILE:near	; Find (and read) the profile


;------------- Resident variables -----------------------

extern	 DOSVER:word		; DOS version number
extern	 FIRST_MAC:word 	; Segment of first MAC entry

extern	 HOOK_OFFSET:word	; Offset of HOOK rouitne   (DOS3)
extern	 UNHOOK_OFFSET:word	; Offset of UNHOOK rouitne (DOS3)
extern	 DOS_ALLOC_CNT:dword	; Address to return to after DOS4 patch

extern	 CODE1_SAVE:byte	; Save area for DOS3 Hook patch
extern	 CODE2_SAVE:byte	; Save area for DOS3 UnHook patch

extern	 CONFIG_SEGMENT:word	; DOS' transient code/data segment
extern	 CONFIG_OFFSET:word	; ...			   offset
extern	 CONFIG_LOCAL:word	; Offset of local allocate handler
extern	 LOCAL1_ALLOC:near	; Local allocate handler #1
extern	 LOCAL2_ALLOC:near	; ...			 #2
extern	 MODELNO:byte		; Model #

extern	 DEAD_DEV:byte		; DeadMan switch for DEVICE=
extern	 DEAD_INS:byte		; DeadMan switch for INSTALL=
extern	 DEAD_OFLOW:byte	; DeadMan switch for subseg overflow
extern	 DEAD_NAME:word 	; Ptr to name of applicable DeadMan switch

extern	 INSERT_DEAD:near	; Insert the appropriate DeadMan switch
extern	 INFO_READ:near 	; Read in MAX's INFO structure
extern	 INFO_WRITE:near	; Write out MAX's INFO structure

extern	 DISP_COPY:near 	; Display Copyright message

extern	 TRANSFER_BOOT:near	; Move our bootstrap code
extern	 CURR_REG:byte		; Region of current request
extern	 CODE_REG:byte		; Region of our transient code/data
extern	 FILES_REG:byte 	; FILES= region

extern	 CFG_NEXTPARA:word	; DOS' next free paragraph marker
extern	 CFG_HIGHWATER:word	; DOS' High water mark
extern	 CFG_FIRSTPARA:word	; DOS' first sub-segment para
extern	 CFG_SUBSEGLEN:word	; DOS' Length of all sub-segments (in Low DOS)

extern	 LSEG:LSEG_STR		; COMMAND.COM's LSEG structure

extern	 CURR_PASS:byte 	; Current Pass variable (0,1,2,-1)
extern	 @PASS_INS:abs		; We're invoked from INSTALL=
extern	 @PASS_CMD:abs		; We're invoked from the command line

;---------------------------------------------------

HCODE	 ends			; End Resident Code segment


;****************************************************************************

HDATA	 segment		; Start non-Resident Data segment

; These variables are all non-resident !!!

	 public  SUBMAC_LEN
SUBMAC_LEN	 dw	 0	; Size of UMB needed (dynamically tallied)
				; Used for the Command Line version only

;--------------- Messages --------------------------

	 extern  MSG_SUCCESS_DEV:byte
	 extern  MSG_SUCCESS_INS:byte

;--------------- Error messages ----------------------------

	 extern  MSG_ERR_XDOS:byte
	 extern  MSG_XCCOM:byte

;--------------- Debugging messages ----------------------

if @STATISTICS
	 public  MSG_DBG_CODE, MSG_DBG_CS,MSG_DBG_IP
	 public  MSG_DBG_NEXTPARA,MSG_DBG_HIGHWATER
MSG_DBG_CODE	  db	CR,LF
		  db	@HNAME,': Allocation Code is at '
MSG_DBG_CS	  db	'____:'
MSG_DBG_IP	  db	'____',CR,LF,@HNAME,': Next_Para is at offset '
MSG_DBG_NEXTPARA  db	'____',CR,LF,@HNAME,': HighWater is at offset '
MSG_DBG_HIGHWATER db	'____',CR,LF,EOS

	 public  MSG_DBG_CCOM
MSG_DBG_CCOM	 db	@HNAME,': COMMAND.COM loader is at offset '
MSG_DBG_CCOM1	 db	'____',CR,LF,EOS

	 public  MSG_DBG_UNHOOK
MSG_DBG_UNHOOK	  db	@HNAME,': Unhook code is at offset '
MSG_DBG_UH1	  db	'____',CR,LF,EOS

endif			; If @STATISTICS


;--------------- CONFIG.SYS Models (MS-DOS 7) -----------------------


	 public  GENERIC2_MODEL
GENERIC2_MODEL	 label byte			; Generic model #2
	 db	 05Ah				; POP DX
GM2A	 db	 08Bh, 00Eh,   -1,  -1		; MOV CX,[0EAD]
GM2B	 db	 0E8h,	 -1,   -1		; CALL 8254
GM2C	 db	 001h, 016h,   -1,  -1		; ADD [0EAD],DX
GM2D	 db	 0FFh, 006h,   -1,  -1		; INC WORD PTR [0EAD]
@GENMODEL2_LEN equ $-GENERIC2_MODEL		; Length of above

MODEL2_NEXTPARA equ (GM2A-GENERIC2_MODEL)+2	; Address of CFG_NEXTPARA
MODEL2_RESTART	equ (GM2B-GENERIC2_MODEL)	; ...	     restart point
MODEL2_NP2	equ (GM2C-GENERIC2_MODEL)+2	; ...	     next para check #1
MODEL2_NP3	equ (GM2D-GENERIC2_MODEL)+2	; ...	     ...	     #2


	 public  UPDATE2_NEXTPARA_MODEL
UPDATE2_NEXTPARA_MODEL label byte		; [Add_Len_To_NextPara] model
	 db	050h				; PUSH AX
	 db	02Eh, 0A1h, -1, -1		; MOV AX,CS:[CFG_NEXTPARA]
UM2	 db	02Eh, 039h, 006h, -1, -1	; CMP CS:[CFG_HIGHWATER],AX
	 db	076h, -1			; JBE [IP+02h]
	 db	058h				; POP AX
	 db	0C3h				; RET
@UPDATE2_MODEL_LEN equ $-UPDATE2_NEXTPARA_MODEL ; Length of above

MODEL2_HIGHWATER equ (UM2-UPDATE2_NEXTPARA_MODEL)+3 ; Address of CFG_HIGHWATER


;--------------- CONFIG.SYS Models (DOS 4,5,6) -----------------------


	 public  GENERIC1_MODEL
GENERIC1_MODEL	 label byte			; Generic model #1
	 db	 006h, 051h			; PUSH ES, PUSH CX
GM1A	 db	 02Eh, 08Bh, 00Eh,  -1,   -1	; MOV CX,CS:[CFG_NEXTPARA]
GM1B	 db	 02Eh, 089h, 00Eh,  -1,   -1	; MOV CS:[1679],CX
	 db	 08Eh, 0C1h			; MOV ES,CX
	 db	 026h, 0A2h, 000h, 000h 	; MOV ES:[0000],AL
	 db	 041h				; INC CX
	 db	 026h, 089h, 00Eh, 001h, 000h	; MOV ES:[0001],CX
	 db	 059h, 007h			; POP CX, POP ES
	 db	 02Eh, 0FFh, 006h,  -1,   -1	; INC CS:[CFG_NEXTPARA]
	 db	 0C3h				; RET
@GENMODEL1_LEN equ $-GENERIC1_MODEL		; Length of above

MODEL1_NEXTPARA equ (GM1A-GENERIC1_MODEL)+3	; Address of CFG_NEXTPARA
MODEL1_RESTART	equ (GM1B-GENERIC1_MODEL)	; ...	     restart point


	 public  UPDATE1_NEXTPARA_MODEL
UPDATE1_NEXTPARA_MODEL label byte		; [Add_Len_To_NextPara] model
	 db	050h				; PUSH AX
	 db	02Eh, 0A1h, -1, -1		; MOV AX,CS:[NEXT_BYTE]
	 db	0E8h, -1,   -1			; CALL BYTE_TO_PARA
	 db	02Eh, 001h, 006h, -1, -1	; ADD CS:[CFG_NEXTPARA],AX
	 db	02Eh, 0C7h, 006h,-1,-1, 0h, 0h	; MOV WPTR CS:[NEXT_BYTE],0
	 db	02Eh, 0A1h, -1, -1		; MOV AX,CS:[CFG_NEXTPARA]
UM1	 db	02Eh, 03Bh, 006h, -1, -1	; CMP AX,CS:[CFG_HIGHWATER]
	 db	073h, -1			; JNC [IP+23h]
	 db	02Eh, 0F6h, 006h, -1, -1, -1	; TEST BPTR CS:[165B],02
	 db	074h, -1			; JNZ [IP+18h]
@UPDATE1_MODEL_LEN equ $-UPDATE1_NEXTPARA_MODEL ; Length of above

MODEL1_HIGHWATER equ (UM1-UPDATE1_NEXTPARA_MODEL)+3 ; Address of CFG_HIGHWATER

	 public  SUBSEGLEN_MODEL
SUBSEGLEN_MODEL label byte			; Get subseg length
SM1	 db	 0A1h,	 -1,   -1		; MOV AX,[0EAD]
	 db	 02Bh, 006h,   -1,   -1 	; SUB AX,[0EA9]
SM2	 db	 0A3h,	 -1,   -1		; MOV [0EA7],AX
@SUBSEGLEN_LEN equ $-SUBSEGLEN_MODEL		; Length of above

SUBSEGLEN_OFF equ (SM2-SUBSEGLEN_MODEL)+1	; Address of SUBSEGLEN
SUBSEGLEN_NP1 equ (SM1-SUBSEGLEN_MODEL)+1	; Address of CFG_NEXTPARA

;--------------- CONFIG.SYS Models (DOS 3.30) -----------------------

	 public  HOOK_MODEL
HOOK_MODEL label byte			; DOS 3.30, Hook model
	 db	 036h, 0A1h, -1, -1	; MOV AX,SS:[????]
HW3	 db	 036h, 0A3h, -1, -1	; MOV SS:[HIGHWATER],AX
HOOK1	 db	 00Eh, 01Fh		; PUSH CS, POP DS
	 db	 0E8h, -1,   -1 	; CALL [NORMALIZE_NEXT_BYTE]
	 db	 036h, 0A0h, -1, -1	; MOV AL,SS:[FILES_VALUE]
	 db	 02Ch, 005h		; SUB AL,05
	 db	 076h, -1		; JBE [PROCESS_FILES_END]
	 db	 032h, 0E4h		; XOR AH,AH
	 db	 036h, 8Bh, 01Eh, -1,-1 ; MOV BX,SS:[NEXT_PARA_VOFF]
NP3	 db	 036h, 8Bh, 016h, -1,-1 ; MOV DX,SS:[NEXT_PARA_VSEG]
@HOOK_MODEL_LEN equ $-HOOK_MODEL	; Length of above

MODEL_NEXTPARA3  equ ((NP3-HOOK_MODEL)+3) ; Address of CFG_NEXTPARA  (DOS3)
MODEL_HIGHWATER3 equ ((HW3-HOOK_MODEL)+2) ; Address of CFG_HIGHWATER (DOS3)
MODEL_HOOK_PROC  equ (HOOK1-HOOK_MODEL)   ; Address of HOOK routine  (DOS3)


	 public  UNHOOK_MODEL
UNHOOK_MODEL label byte 		; DOS 3.30, UnHook model
	 db	 00Eh, 01Fh		; PUSH CS, POP DS
	 db	 0E8h, -1,  -1		; CALL [NORMALIZE_NEXT_BYTE]
	 db	 08Bh, 1Eh, -1, -1	; MOV BX,[????]
	 db	 0A1h, -1,  -1		; MOV AX,[????]
	 db	 08Eh, 0C0h		; MOV ES,AX
	 db	 02Bh, 0D8h		; SUB BX,AX
	 db	 0B4h, 04Ah		; MOV AH,4Ah
	 db	 0CDh, 021h		; INT 21
	 db	 006h			; PUSH ES
	 db	 08Ch, 0C0h		; MOV AX,ES
	 db	 048h			; DEC AX
	 db	 08Eh, 0C0h		; MOV ES,AX
	 db	 026h, 0C7h, 06h, 01h	; MOV WPTR ES:[0001],0008
	 db	 00h, 08h, 00h		; ...
	 db	 007h, 0C3h		; POP ES, RET
@UNHOOK_MODEL_LEN equ $-UNHOOK_MODEL	; Length of above


;------------------ COMMAND.COM Loader Models ---------------------

	 public  CCOM_MODEL
CCOM_MODEL label byte			; COMMAND.COM loader model
	 db	 08Ch, 04Fh, 004h	; MOV [BX+4],CS
	 db	 08Ch, 04Fh, 008h	; MOV [BX+8],CS
	 db	 08Ch, 04Fh, 00Ch	; MOV [BX+C],CS
	 db	 033h, 0C0h		; XOR AX,AX
	 db	 0B4h, 04Bh		; MOV AH,4B
	 db	 0F9h			; STC
CCOM1	 db	 0CDh, 021h		; INT 21
	 db	 0BAh, -1, -1		; MOV DX,[MSG_CANT_LOAD_COMMANDCOM]
	 db	 0E8h, -1, -1		; CALL [MSG_DISP_ROUTINE]
	 db	 0EBh, 0FEh		; JUMP $
@CCOM_MODEL_LEN equ $-CCOM_MODEL	; Length of above

MODEL_CCOM_PATCH equ (CCOM1-CCOM_MODEL) ; Address of INT 21h (patch point)


;------------ Misc variables ---------------------

	 public  PROT_NAME
PROT_NAME db	 'PROTMAN$',0   ; Name of PROTMAN device

;---------------------------------------------------

HDATA	 ends			; End Non-Resident Data segment


;****************************************************************************

HCODE	 segment		; Start Resident Code segment
	 assume  cs:PGROUP

	 public  DATASEG
DATASEG  dw	 seg DGROUP	; Addressible from PGROUP

	 public  PSPSEG
PSPSEG	 dw	 0		; Segment of PSP (if INSTALL= or CMD Line)


	 public  LCL_FLAG,CMD_FLAG
LCL_FLAG	 dw	0	; Local flags
CMD_FLAG	 dw	0	; Command Flags

	 public  CONFIG_NEXT,CONFIG_TOP,UMB_SEGMENT
CONFIG_NEXT	 dw	 ?	; Storage for DOS next-para pointer
CONFIG_TOP	 dw	 ?	; Storage for DOS High water mark
UMB_SEGMENT	 dw	 0	; Segment of our primary UMB

extern	 NEXT_HIGHPARA:word	; Top of UMB (tallied by DOS)
extern	 ENV_REGION:byte	; Region of master environment
extern	 CCOM_REGION:byte	; Region of CCOM
extern	 PORT67:word		; MAX's backdoor port (usually F084)

	 public  RES_PARA
RES_PARA	 dw	 0	; Resident size of HARPO in paras

	 public  BOOT_OFF,BOOT_LEN
BOOT_OFF	 dw	 ?	; Offset of resident code
BOOT_LEN	 dw	 ?	; Length of resident code

	 public  OLDINT21_VEC
OLDINT21_VEC	 dd	 ?	; Original interrupt 21 handler


;--------------- Resident Stack ---------------------

	 public  NEWSTK
NEWSTK	 dw	 80h dup (?)	; Resident stack space

	 public  NEWSTKZ
NEWSTKZ  label	 word		; Top of resident stack


;****************************************************************************

	 FPPROC  DEV_STRA -- Device Strategy Routine
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Device strategy routine.

On entry:

ES:BX	 ==>	 request header

|

	 mov	 RH_VEC.VVOFF,bx ; Save for later use
	 mov	 RH_VEC.VVSEG,es ; ...

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DEV_STRA endp			; End DEV_STRA procedure


;****************************************************************************

	 FPPROC  DEV_INTR -- Device Interrupt Routine
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Device interrupt routine

On entry:

RH_VEC	 ==>	 request header

|

	 mov	 OLDSTK_VEC.VVSEG,ss ; Save current stack pointer
	 mov	 OLDSTK_VEC.VVOFF,sp

	 cli			; In case we're on buggy 8088
	 mov	 ss,NEWSTK_VEC.VVSEG ; SS:SP ==> new stack
	 mov	 sp,NEWSTK_VEC.VVOFF ; ...
	 sti			; Restore

	 REGSAVE <bx,ds,es>	; Save registers

	 or	 LCL_FLAG,@LCL_DD ; Mark as coming from Device Driver load

; Filter out all valid commands

	 les	 bx,RH_VEC	; ES:BX ==> request header
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[bx].SRH_STR.SRH_CCD,0 ; Izit initialization?
	 je	 DEV_INIT	; Jump if so

	 jmp	 DEV_UNK_ERR	; Unknow command code

DEV_INIT:
	 mov	 CONFIG_SEGMENT,es ; Save CONFIG.SYS segment

	 mov	 DEAD_NAME,offset PGROUP:DEAD_OFLOW ; Affix a DeadMan name

	 call	 CHECK_ALTKEY	; Is the Alt-key pressed?
	 jc	 DEV_INTR_ERR	; Jump if so

	 call	 MAX_PRESENT	; Get PORT67 value
	 jc	 DEV_INTR_ERR	; Jump if MAX is not present

	 call	 CHECK_HIGH	; See if we are being 386LOADed
	 jc	 DEV_INTR_ERR	; Jump if so

	 call	 CHECK_DOSVER	; Check on DOS version number
	 jc	 DEV_INTR_ERR	; Jump if error

	 call	 DD_PARSE	; Parse the device driver line
	 jc	 short DEV_INTR_ERR ; Jump if something went wrong

	 SWATTER		; Call debugger if requested

	 mov	 ds,DATASEG	; Setup addressibility to DGROUP
	 assume  ds:DGROUP	; Tell the assembler about it

	 test	 CMD_FLAG,@CMD_VERBOSE ; Are we talkative?
	 jz	 short @F	; Jump if not

	 lea	 di,MSG_SUCCESS_DEV ; DEVICE= message
	 call	 DISP_COPY	; Display copyright line (and extra message)

@@:
	 test	 CMD_FLAG,@CMD_DEAD_DEV ; Is the deadman switch active?
	 jnz	 DEV_INIT_EXIT	; Jump if so

	 mov	 es,DATASEG	; Setup addressibility to DGROUP
	 assume  es:DGROUP	; Tell the assembler about it

	 call	 GET_FIRST_MAC	; Find the address of the first MAC entry

	 call	 WIPE_TOKENS	; If in GETSIZE mode, force everything low
				; This will prevent "You've been flexxed" msg

;--------------------

	 call	 HOOK_DOS3	; Hook CONFIG.SYS's memory allocation routine
	 jc	 DEV_INTR_ERR	; Jump if error

	 call	 HOOK_DOS4	; Hook CONFIG.SYS's memory allocation routine
	 jc	 DEV_INTR_ERR	; Jump if error

;--------------------

	 call	 FIND_DOSTOP	; Find the Top of Conventional memory

	 call	 INSERT_DEAD	; Insert the DeadMan switch

; Allocate a MAC entry upstairs for the transient code

	 mov	 CURR_REG,-1	; Use all possible regions
	 mov	 CODE_REG,-1	; Same as above...
	 call	 TRANSFER_BOOT	; Move transient code to High DOS

;--------------------

if @STATISTICS
	 call	 DISP_DBG_CODE	; Display all known patch addresses
endif				; If @STATISTICS

;--------------------

DEV_INTR_ERR:
DEV_INIT_EXIT:
	 les	 bx,RH_VEC	; ES:BX ==> request header
	 assume  es:nothing	; Tell the assembler about it

; Device Driver ==> Not going resident

	 mov	 (DD_STR ptr DEVDRV).DD_ATTR,0 ; Fail as block device since bug in DOS
				; doesn't allow character devices to fail

	 mov	 es:[bx].INIT_STR.INIT_UNITS,0 ; No units defined
	 mov	 es:[bx].INIT_STR.INIT_END_VEC.VVOFF,0	; Ending offset
	 mov	 es:[bx].INIT_STR.INIT_END_VEC.VVSEG,cs ; Ending address

	 or	 es:[bx].SRH_STR.SRH_STA,(8000h or	\ ; Error exists
					0100h or	\ ; Done condition
					ERR_UNK_CMD)	  ; Unknown command err
				; Use the MASM 6.0 approved method

	 jmp	 EXIT		; Join common exit code

DEV_UNK_ERR:
;;;;;;;; STATUS  DONE,ERROR,ERR_UNK_CMD ; Mark as unknown command
	 or	 es:[bx].SRH_STR.SRH_STA,(8000h or	\ ; Error exists
					  0100h or	\ ; Done condition
					  ERR_UNK_CMD)	\ ; Unknown command err
				; Use the MASM 6.0 approved method

EXIT:
	 REGREST <es,ds,bx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 cli			; In case we're on buggy 8088
	 mov	 ss,OLDSTK_VEC.VVSEG ; Restore old stack pointer
	 mov	 sp,OLDSTK_VEC.VVOFF ; ...
	 sti			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DEV_INTR endp			; End DEV_INTR procedure


;****************************************************************************

	 NPPROC  SRCHSTR_ -- SRCHSTR_ Procedure
	 assume  ds:nothing,es:nothing,ss:nothing

COMMENT |

Search for a particular code model (with Don't Care bytes)
Note: We should verify that there aren't two matches

This code is resident in PGROUP.  This is so we can find the
environment loader after we have loaded COMMAND.COM.

On entry:
AX	=	Segment to search through
CX	=	Length of model code
DS:SI	=	Model code address

On exit:
CF	=	0 if no match was found
		  DI = destroyed
		1 if match was found
		  DI = Offset of match

|

	 REGSAVE <ax,cx,si,bp,es> ; Save registers

; Check for expected code

	 mov	 es,ax		; Address search segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 bp,cx		; Save length of model code

	 neg	 cx		; Calculate search area length
	 dec	 cx		; ...

; Check for expected code (Check against the Generic model)
; This model uses don't care bytes

	 xor	 di,di		; Search offset (within CONFIG.SYS)

SRCHSTR_NEXT:
	 mov	 al,ds:[si]	; Get the first byte (from model)
	 jcxz	 EXIT_STC	; Jump if no more bytes to check
   repne scas	 BPTR es:[di]	; Search for the 1st byte (in CONFIG.SYS)
	 jne	 EXIT_STC	; Jump if no match

	 REGSAVE <cx,si,di>	; Save registers
	 inc	 si		; Plus one to account for the first match
	 mov	 cx,bp		; Length of model code
	 dec	 cx		; ...

SRCHSTR_NEXT_CHAR:
    repe cmps	 BPTR ds:[si],ES:[di] ; Compare bytes till mismatch
	 je	 SRCHSTR_LOOP	; Jump if entire string matched (ZF=1)

	 cmp	 BPTR ds:[si-1],-1 ; Izit a don't-care byte?
	 je	 SRCHSTR_NEXT_CHAR ; Jump if so (continue cmpsb)
				; Jump with ZF=1 (in case CX=0)
				; Fall through with ZF=0

SRCHSTR_LOOP:
	 REGREST <di,si,cx>	; Restore registers
	 jne	 SRCHSTR_NEXT	; Jump if no match (scan for next match)

	 dec	 di		; Back off to start of match

	 clc			; Indicate we found a match

	 jmp	 EXIT		; Join common exit code

EXIT_STC:
	 stc			; Indicate no match was found
EXIT:
	 REGREST <es,bp,si,cx,ax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SRCHSTR_  endp			; End SRCHSTR_ procedure


;****************************************************************************

HCODE	 ends			; End Resident CODE segment

;****************************************************************************

HNCODE	 segment		; Start Non-Resident Code Segment

extern	 DD_PARSE:near		; Parse DEVICE= arguments

extern	 FMT_WORD:near		; Foramt AX => ES:DI

	 public  CONFIG_RESTART
CONFIG_RESTART dw MODEL1_RESTART ; Offset to restart point

;****************************************************************************

	 FPPROC  HARPO_EXE -- EXE file entry point
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

EXE file entry point.

|

	 mov	 PSPSEG,ds	; Save segment of PSP

;;;;;;;  REGSAVE <ds,es>	; Save segment registers

	 call	 GET_PASS	; Determine if it's INSTALL= or CMD Line

	 cmp	 CURR_PASS,@PASS_INS ; INSTALL= time?
	 jne	 HARPO_EXIT2	; Jump if not

	 mov	 es,DATASEG	; Setup addressibility to DGROUP
	 assume  es:DGROUP	; Tell the assembler about it

	 call	 CHECK_ALTKEY	; Is the Alt-key pressed?
	 jc	 HARPO_ERR	; Jump if so

	 call	 MAX_PRESENT	; Get PORT67 value
	 jc	 HARPO_ERR	; Jump if MAX is not present

	 call	 CHECK_HIGH	; See if we are being 386LOADed
	 jc	 HARPO_ERR	; Jump if so

	 call	 CHECK_DOSVER	; Check on DOS version number
	 jc	 HARPO_ERR	; Jump if error

	 mov	 DEAD_NAME,offset PGROUP:DEAD_INS ; Affix a DeadMan name

;;;;;;;; call	 GET_PASS	; Determine if it's INSTALL= or CMD Line

	 mov	 ds,DATASEG	; Setup addressibility to DGROUP
	 assume  ds:DGROUP	; Tell the assembler about it

	 call	 FIND_DOSTOP	; Find the Top of Conventional memory

	 call	 GET_PROFILE	; Find (and read) the profile
;;;;;;;; jc	 HARPO_ERR	; Jump if something went wrong

	 SWATTER		; Call debugger if requested

	 test	 CMD_FLAG,@CMD_VERBOSE ; Are we talkative?
	 jz	 short @F	; Jump if not

	 lea	 di,MSG_SUCCESS_INS ; INSTALL= message
	 call	 DISP_COPY	; Display copyright line (and extra message)

@@:
	 test	 CMD_FLAG,@CMD_DEAD_DEV ; Is the deadman switch active?
	 jnz	 HARPO_ERR	; Jump if so

	 call	 GET_FIRST_MAC	; Find the address of the first MAC entry

	 call	 WIPE_TOKENS	; If in GETSIZE mode, force everything low
				; This will prevent "You've been flexxed" msg

	 call	 INST_CCOM	; Move CCOM to High DOS (from INSTALL=)
	 jc	 HARPO_ERR	; Jump if we loader not found

; Allocate a MAC entry upstairs for the transient code

	 test	 LCL_FLAG,(@LCL_CCOM or @LCL_ENVIRON or @LCL_CMD_SHARE)
	 jz	 HARPO_EXIT	; Jump if nothing going High

	 call	 INSERT_DEAD	; Insert the DeadMan switch

	 mov	 CURR_REG,-1	; Use all possible regions
	 mov	 CODE_REG,-1	; Same as above...
	 call	 TRANSFER_BOOT	; Move transient code to High DOS

HARPO_ERR:
HARPO_EXIT:
	 call	 SET_MSC_GETRC	; Have MAX lie on next GET_Return_Code call

HARPO_EXIT2:
;;;;;;;  REGREST <es,ds>	; Restore segment registers
;;;;;;;  assume  ds:nothing	; Tell the assembler about it
;;;;;;;  assume  es:nothing	; Tell the assembler about it

	 mov	 ax,4C00h	; DOS: Quit with exit code 00 function
	 int	 21h		; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

HARPO_EXE endp			; End HARPO_EXE procedure


;***************************************************************************

	 NPPROC  GET_PASS -- GET_PASS procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Determine if this is the INSTALL= pass or we're at the command line

On entry:
DS	=	Segment of PSP

On exit:
CURR_PASS will be updated

How to tell if we're at INSTALL= time...
* DR-DOS does not have a valid environment pointer at INSTALL= time
* MS-DOS (except for DOS 6 with Multiboot) has a valid environment,
  and the first word of that environment will be 0000 at INSTALL= time.
* MS-DOS 6.00 (with Multiboot) will have a valid environemnt, with valid
  environment strings in it at INSTALL= time.  However, it will also
  have a NULL value in the Ctrl-PSP value of the Controller's PSP.  That
  is, its owner will NOT have an owner.

|

	 REGSAVE <ax,ds>	; Save registers

; Check for DR-DOS INSTALL= time

	 mov	 CURR_PASS,@PASS_INS ; Assume it is INSTALL= time

	 cmp	 ds:[PSP_ENVIR_PTR],0 ; Is there an environment?
	 je	 EXIT		; Jump if not (DR-DOS INSTALL= time)

; Check for MS-DOS INSTALL= time (DOS 4.00 - 5.00, & DOS 6.00 w/o Multi-boot)

	 mov	 ax,ds:[PSP_CTRL_PSP] ; Save address of our controller

	 mov	 ds,ds:[PSP_ENVIR_PTR] ; Address current environment
	 assume  ds:nothing	; Tell the assembler about it

	 cmp	 WPTR ds:[0],0	; Is the first word a zero?
	 je	 EXIT		; Jump if so (MS-DOS INSTALL= time)

; Check for MS-DOS INSTALL= time (DOS 6.00 with Multiboot)

	 mov	 ds,ax		; Address our controller
	 assume  ds:nothing	; Tell the assembler about it

	 cmp	 ds:[PSP_CTRL_PSP],0 ; Does our controller have a controller?
	 je	 EXIT		; Jump if no controller (INSTALL= time)

	 mov	 CURR_PASS,@PASS_CMD ; Must be called from the command line

EXIT:
	 REGREST <ds,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
GET_PASS	 endp		; End GET_PASS procedure


;***************************************************************************

	 NPPROC  WIPE_TOKENS -- WIPE_TOKENS procedure
	 assume  ds:DGROUP,es:DGROUP,ss:nothing
COMMENT |

Wipe out all tokens so that we do NOT move any of the CONFIG.SYS
sub-segments into High DOS.

If we are in GETSIZE mode, then we have to ensure that all
sub-segments go into Low memory.  This will avoid 'You've been Flexxed'
error messages.

There are many reasons why we are in GETSIZE mode...
1) The user has requested it via the command line
2) There is an OVERFLOW condition

|

	 REGSAVE <cx,di>	; Save registers

	 test	 LCL_FLAG,@LCL_TEST ; Are we in GETSIZE mode?
	 jz	 EXIT		; Jump if not

; Load all sub-segments into Low memory

	 mov	 cx,@TOKEN_CNT	; Number of tokens
	 lea	 di,TOKEN_LIST	; Address the list of tokens

NEXT_TOKEN:
	 mov	 BPTR PGROUP:[di].TOKEN_STR.REG,0 ; Region 0 ==> Load it low
	 add	 di,type TOKEN_STR ; Bump to next region

	 loop	 NEXT_TOKEN	; Wipe next token

	 mov	 FILES_REG,0	; Ensure FILES= are loaded Low

; Load CCOM and the master environment into Low DOS memory

	 mov	 CCOM_REGION,0	; COMMAND.COM loads low
	 mov	 ENV_REGION,0	; Environment ...

	 mov	 LSEG.LSEG_PREG,0 ; COMMAND.COM loads low
	 mov	 LSEG.LSEG_EREG,0 ; Environment ...

EXIT:
	 REGREST <di,cx>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
WIPE_TOKENS	 endp			; End WIPE_TOKENS procedure


;***************************************************************************

	 NPPROC  INST_CCOM -- INST_CCOM procedure
	 assume  ds:DGROUP,es:DGROUP,ss:nothing
COMMENT |

Prepare to move CCOM into High DOS (from INSTALL=)

On exit:
CF	=	0 If all went well
	=	1 If CCOM Loader not found

Problem:
	We can't patch DOS during INSTALL= time because DOS will perform
	a checksum on segment 9087 and let you know that there is a
	"Memory Allocation Error" when it scans our patch, oh well.

Solution:
	The only other thing to do is to hook interrupt 21, function 4Bh,
	and hope no one else hooks it.	This is an acceptable assumption
	since we should be the last INSTALL= program to load.

|

	 REGSAVE <ax,bx,cx,dx,di,ds,es> ; Save registers

	 test	 LCL_FLAG,(@LCL_CCOM or @LCL_ENVIRON or @LCL_CMD_SHARE)
	 jz	 EXIT_CLC	; Jump if not moving anything High

	 cmp	 CURR_PASS,@PASS_INS ; Is it INSTALL= time?
	 jne	 EXIT_CLC	; Jump if not

; Address our PSP

	 mov	 ah,@GETPS0	; DOS: Find address of PSP (51h)
	 int	 21h		; Get current PSP into BX

	 mov	 ds,bx		; Address the PSP
	 assume  ds:nothing	; Tell the assembler about it

; Get owner of Critical Error Handler

	 mov	 ax,ds:[PSP_CRIT_ERROR].VVSEG ; Get the Critical Error segment

; Find our owner (from the Control_PSP value)

	 mov	 bx,ds:[PSP_CTRL_PSP] ; Get our owner
	 mov	 cx,bx		; Get owner into different register
	 add	 cx,10h 	; Add in size of PSP (in paras)

; See if Control_PSP = Critical_Err_Handler

	 cmp	 cx,ax		; Compare PSP owner to Crit_Err_hndlr
	 je	 CONFIG_FOUND	; Jump if they are equal (we found a winner)

; Address the Owner's PSP (and get the last SS value)

	 mov	 ds,bx		; Address the owner's PSP
	 assume  ds:nothing	; Tell the assembler about it

; See if INT21_SS = Critical_Err_Handler

	 cmp	 ax,ds:[2Eh]+2	; Compare with SS of the last int 21 caller
	 je	 CONFIG_FOUND	; Jump if we have a winner

; See if INT21_SS = Ctrl_PSP_Value

	 mov	 ax,cx		; Get the
	 cmp	 ax,ds:[2Eh]+2	; Compare with SS of the last int 21 caller
	 jne	 ERR_XCONFIG	; Jump if CONFIG.SYS not found

CONFIG_FOUND:
	 assume  ds:nothing	; Tell the assembler

; AX = Segment of CONFIG.SYS processor

	 mov	 CONFIG_SEGMENT,ax ; Save CONFIG.SYS address

	 mov	 ds,DATASEG	; Address our data
	 assume  ds:DGROUP	; Tell the assembler about it

; Find (and save) the current interrupt 21h handler
; This has to be done BEFORE we bootstrap ourselves into High DOS

	 REGSAVE <ax,bx,es>	; Save registers

	 mov	 ah,@GETINT	; DOS: Get interrupt vector function
	 mov	 al,21h 	; We are hooking interrupt 21h
	 int	 21h		; Get interrupt vector in AL to ES:BX
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT21_VEC.VVSEG,es ; Save interrupt 21h value
	 mov	 OLDINT21_VEC.VVOFF,bx ; ...

	 REGREST <es,bx,ax>	; Restore registers
	 assume  es:nothing	; Tell the assembler about it

; Prepare bootstrap variables

	 mov	 BOOT_OFF,offset PGROUP:FIRST_BYTE ; Start of resident code
	 mov	 BOOT_LEN,offset PGROUP:LAST_BYTE ; Size of resident code

	 jmp	 EXIT_CLC	; Join common exit code

ERR_XCONFIG:
	 lea	 di,MSG_XCCOM	; Tell 'em "we couldn't find CCOM loader"
	 call	 DISP_COPY	; Display copyright and message

	 call	 PRESSANY	; Wait for keystroke

	 stc			; Indicate error

	 jmp	 EXIT		; Join common error code

EXIT_CLC:
	 clc			; Indicate success

EXIT:
	 REGREST <es,ds,di,dx,cx,bx,ax> ; Restore registers
	 assume  ds:DGROUP	; Tell the assembler about it
	 assume  es:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
INST_CCOM	 endp		; End INST_CCOM procedure


;***************************************************************************

	 NPPROC  HOOK_DOS3 -- HOOK_DOS3 procedure
	 assume  ds:DGROUP,es:DGROUP,ss:nothing
COMMENT |

Root around DOS 3.30 code
Find the subsegment allocations hooks.

On exit:
CF	=	0 Success
		1 Failure

|

	 REGSAVE <ax,si,di,es>	; Save registers

	 cmp	 DOSVER.HILO_STR.HI,3h ; Isit DOS 3.x
	 jne	 EXIT_CLC	; Exit if not, but without error

	 call	 CHECK_MODEL_3	; Check for DOS 3.30 model code
	 jc	 ERR_XDOS	; Jump if not found

; Save the code underneath the patch (for later unhooking)
; We are patching PROCESS_FILES,
; which is the first sub-segment allocation routine

	 mov	 di,HOOK_OFFSET ; Address the patch point

	 mov	 es,CONFIG_SEGMENT ; Address CONFIG.SYS
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es:[di]+0 ; Get word at PROCESS_STACKS code
	 mov	 WPTR CODE1_SAVE[0],ax ; Save for later

	 mov	 ax,es:[di]+2 ; Get word at PROCESS_STACKS code
	 mov	 WPTR CODE1_SAVE[2],ax ; Save for later

	 mov	 al,es:[di]+4 ; Get byte at PROCESS_STACKS code
	 mov	 BPTR CODE1_SAVE[4],al ; Save for later

; Save the SUBSEMENTS_COMPLETE code (for later unhooking)

	 mov	 di,UNHOOK_OFFSET	; Address the patch point

	 mov	 es,CONFIG_SEGMENT ; Address CONFIG.SYS
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es:[di]+0 ; Get word at SUBSEMENTS_COMPLETE code
	 mov	 WPTR CODE2_SAVE[0],ax ; Save for later

	 mov	 ax,es:[di]+2 ; Get word at SUBSEMENTS_COMPLETE code
	 mov	 WPTR CODE2_SAVE[2],ax ; Save for later

	 mov	 al,es:[di]+4 ; Get byte at SUBSEMENTS_COMPLETE code
	 mov	 BPTR CODE2_SAVE[4],al ; Save for later


; Prepare bootstrap variables

	 mov	 BOOT_OFF,offset PGROUP:FIRST_BYTE ; Start of resident code
	 mov	 BOOT_LEN,offset PGROUP:LAST_BYTE ; Size of resident code


EXIT_CLC:
	 clc			; Indicate success

	 jmp	 EXIT		; Join common exit code

ERR_XDOS:
	 lea	 di,MSG_ERR_XDOS ; Tell 'em we couldn't find the patch
	 call	 DISP_COPY	; Display copyright and message

	 call	 PRESSANY	; Wait for keystroke

EXIT_STC:
	 stc			; Indicate error

EXIT:
	 REGREST <es,di,si,ax>	; Restore registers
	 assume  es:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
HOOK_DOS3	 endp		; End HOOK_DOS3 procedure


;***************************************************************************

	 NPPROC  HOOK_DOS4 -- HOOK_DOS4 Procedure
	 assume  ds:DGROUP,es:DGROUP,ss:nothing

COMMENT |

Hook CONFIG.SYS's sub-segment memory allocation routines
This will only work for DOS 4 (or above)

On exit:
CF	=	0 if we succedded
		1 if not

|

	 REGSAVE <ax,cx,dx,si,di,ds,es> ; Save registers

	 cmp	 DOSVER,400h	; Is it DOS 4.00 (or above)?
	 jb	 HOOK_DOS4_CLC	; Exit if not, but without error

; Check to see if we're runing on a supported version of DOS

	 call	 CHECK_MODEL	; Check against generic DOS model
	 jc	 HOOK_DOS4_ERR_XDOS ; Jump if not found

; Patch Far Jump immediate in our local handler (return to DOS address)

	 mov	 ax,CONFIG_SEGMENT ; Patch in segment of CONFIG.SYS
	 mov	 DOS_ALLOC_CNT.VVSEG,ax ; Patch it

	 mov	 ax,CONFIG_OFFSET ; Patch in offset of CONFIG.SYS
	 add	 ax,CONFIG_RESTART ; Skip over simulated code
	 mov	 DOS_ALLOC_CNT.VVOFF,ax ; Patch it

;--------------------

; Prepare bootstrap variables

	 mov	 BOOT_OFF,offset PGROUP:FIRST_BYTE ; Start of resident code
	 mov	 BOOT_LEN,offset PGROUP:LAST_BYTE ; Size of resident code

HOOK_DOS4_CLC:
	 clc			; Indicate success

	 jmp	 HOOK_DOS4_EXIT ; Join common exit code

HOOK_DOS4_ERR_XDOS:
	 lea	 di,MSG_ERR_XDOS ; Tell 'em we couldn't find the patch
	 call	 DISP_COPY	; Display copyright and message

	 call	 PRESSANY	; Wait for keystroke

HOOK_DOS4_STC:
	 stc			; Indicate failure

HOOK_DOS4_EXIT:
	 REGREST <es,ds,di,si,dx,cx,ax> ; Restore registers
	 assume  ds:DGROUP	; Tell the assembler about it
	 assume  es:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

HOOK_DOS4 endp			; End HOOK_DOS4 procedure


;***************************************************************************

	 NPPROC  CHECK_MODEL_3 -- CHECK_MODEL_3 procedure
	 assume  ds:DGROUP,es:DGROUP,ss:nothing
COMMENT |

Check for DOS 3.0 model code
Try to match current DOS with the code model.

			       ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ HOOK
			       ³     ÚÄÄÄÄÄÄÄ UNHOOK
			       ³     ³	   ÚÄ NEXT_PARA
			       ³     ³	   ³  HIGH_WATER   UMB SIZE
Version      Date     Time          	   	 	      
-------      ----     ----   ----- ----- ----- -----	   --------
MSDOS  3.30  02/02/88 12:02a 0BA0h 0DEDh 0857h 0817h	   11,568
NECDOS 3.30  *(1)	     0BA0h 0DEDh 0857h 0817h	   11,568
PCDOS  3.30  03/17/87 12:00p 0BAEh 0DFBh 0857h 0817h	   11,568
CPQDOS 3.31  09/16/87 12:00p 0BA1h 0DEEh 0858h 0818h	   11,568

*(1): IO.SYS->07/18/88 (9:48a) MSDOS.SYS->07/24/87 (12:00a)

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

; Try to match with generic DOS 3.30 code model


; Check for expected code (Check against DOS 3 HOOK_MODEL)
; This model uses don't care bytes

	 mov	 es,CONFIG_SEGMENT ; Address DOS's transient segment
	 assume  es:nothing	; Tell the assembler about it

; Find the first code model (HOOK_MODEL)

	 mov	 ax,CONFIG_SEGMENT ; Address DOS's transient segment
	 lea	 si,HOOK_MODEL	; Address of our model code
	 mov	 cx,@HOOK_MODEL_LEN ; Length of search string
	 call	 SRCHSTR_	  ; Search for the code (Return in DI)
	 jc	 EXIT_STC	; Jump if code not found

	 mov	 HOOK_OFFSET,di ; Get start of code model
	 add	 HOOK_OFFSET,MODEL_HOOK_PROC ; Add to get offset for patch

	 mov	 ax,es:[di]+MODEL_NEXTPARA3 ; Get DOS address of next_para
	 mov	 CFG_NEXTPARA,ax ; Save for later

;;;;;;;; mov	 CONFIG_RESTART,MODEL1_RESTART ; Save offset to restart point
;;;;;;;; mov	 CONFIG_LOCAL,offset PGROUP:LOCAL1_ALLOC ; Save offset of handler

	 mov	 ax,es:[di]+MODEL_HIGHWATER3 ; Get DOS address of HighWater merk
	 mov	 CFG_HIGHWATER,ax ; Save for later

; Find the second code model (UNHOOK_MODEL)

	 mov	 ax,CONFIG_SEGMENT ; Address DOS's transient segment
	 lea	 si,UNHOOK_MODEL ; Address of our model code
	 mov	 cx,@UNHOOK_MODEL_LEN ; Length of search string
	 call	 SRCHSTR_	  ; Search for the code (Return in DI)
	 jc	 EXIT_STC	; Jump if code not found

	 mov	 UNHOOK_OFFSET,di ; Get start of unhook code model

; As an extra insanity check, we could verify that (NEXT_PARA == CS)

	 clc			; Indicate success

	 jmp	 EXIT		; Join common exit code

EXIT_STC:
	 stc			; Indicate no code match

EXIT:
	 REGREST <es,di,si,cx,ax> ; Restore registers
	 assume  es:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
CHECK_MODEL_3	 endp		; End CHECK_MODEL_3 procedure


;***************************************************************************

	 NPPROC  CHECK_MODEL -- CHECK_MODEL Procedure
	 assume  ds:DGROUP,es:DGROUP,ss:nothing

COMMENT |

Verify the DOS variables by matching it with our generic model
This routine is for DOS 4 (or above)


			       ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ ALLOC_ROUTINE	UMB SIZE
			       ³    ÚÄÄÄÄÄÄÄÄ NEXT_PARA       ------------
			       ³    ³	   ÚÄ HIGH_WATER      DOS=    DOS=
			       ³    ³	   ³  SUBSEGLEN       LOW     HIGH
Version      Date    Time          	   		       	
-------      ----    ----    ----- ----- ----- -----	      -------------
MSDOS  5.00  04/09/91  5:00a 1637h 03E0h 02A3h 03DCh	      10,896  3,424
PCDOS  5.00  05/09/91 12:00a 1658h 03E0h 02A3h 03DCh	      10,896  3,424
CPQDOS 5.00  07/12/91  5:00a 163Fh 03E0h 02A3h 03DCh	      10,896  3,424
TOSHIB 5.00  12/12/91  6:00p 1668h 03E0h 02A3h 03DCh	      10,896  3,424
CPQDOS 4.01  04/05/89 12:00a 1BD1h 0B6Eh 083Ch 0B6Ah	      12,336
MSDOS  4.01  04/07/89 12:00a 1BC3h 0B6Fh 083Dh 0B6Bh	      12,336
ZENITH 4.01  *(1)	     1BBBh 0B6Fh 083Dh 0B6Bh	      12,336
AST    4.01  08/24/89  1:00a 1BC3h 0B6Fh 083Dh 0B6Bh	      12,336
TOSHIB 4.01  *(2)      9:00a 1BEDh 0B6Fh 083Dh 0B6Bh	      12,336
PCDOS  4.00  08/03/88 12:00p 18E9h 09B8h 0826h 09B4h	      12,336

*(1): IBMBIO->05/09/90 (12:22p)  IBMDOS->01/11/90 (1:21p)
*(2): IBMBIO->01/08/90		 IBMDOS->02/27/90

On exit:
CF	=	0 if we found a match
		1 if not

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

	 mov	 es,CONFIG_SEGMENT ; Address DOS's transient segment
	 assume  es:nothing	; Tell the assembler about it

; Find the first code model

	 mov	 ax,CONFIG_SEGMENT ; Address DOS's transient segment
	 lea	 si,GENERIC1_MODEL ; Address of our model code
	 mov	 cx,@GENMODEL1_LEN ; Length of search string
	 call	 SRCHSTR_	  ; Search for the code (Return in DI)
	 jc	 CHECK_MODEL1	  ; Jump if code not found

	 mov	 CONFIG_OFFSET,di ; Save as start of CONFIG.SYS alloc routine
	 mov	 ax,es:[di+MODEL1_NEXTPARA] ; Get DOS address of next_para
	 mov	 CFG_NEXTPARA,ax ; Save for later

;;;;;;;; mov	 CONFIG_RESTART,MODEL1_RESTART ; Save offset to restart point
;;;;;;;; mov	 CONFIG_LOCAL,offset PGROUP:LOCAL1_ALLOC ; Save offset of handler

; Find the second code model

	 mov	 ax,CONFIG_SEGMENT ; Address DOS's transient segment
	 lea	 si,UPDATE1_NEXTPARA_MODEL ; Address of our model code
	 mov	 cx,@UPDATE1_MODEL_LEN ; Length of search string
	 call	 SRCHSTR_	  ; Search for the code (Return in DI)
	 jc	 CHECK_MODEL_STC  ; Jump if code not found

	 add	 di,MODEL1_HIGHWATER ; Bump up to HIGHWATER variable
	 mov	 ax,es:[di]	; Get DOS address of next_para
	 mov	 CFG_HIGHWATER,ax ; Save for later

	 mov	 MODELNO,1	; Mark as model #1

	 jmp	 CHECK_MODEL2	; Join common code

CHECK_MODEL1:
	 mov	 ax,CONFIG_SEGMENT ; Address DOS's transient segment
	 lea	 si,GENERIC2_MODEL ; Address of our model code
	 mov	 cx,@GENMODEL2_LEN ; Length of search string
	 call	 SRCHSTR_	  ; Search for the code (Return in DI)
	 jc	 CHECK_MODEL_STC  ; Jump if code not found

	 mov	 CONFIG_OFFSET,di ; Save as start of CONFIG.SYS alloc routine
	 mov	 ax,es:[di+MODEL2_NEXTPARA] ; Get DOS address of next_para
	 mov	 CFG_NEXTPARA,ax ; Save for later

	 cmp	 ax,es:[di+MODEL2_NP2] ; Check address #2
	 jne	 CHECK_MODEL_STC ; Jump if no match

	 cmp	 ax,es:[di+MODEL2_NP3] ; Check address #3
	 jne	 CHECK_MODEL_STC ; Jump if no match

	 mov	 CONFIG_RESTART,MODEL2_RESTART ; Save offset to restart point
	 mov	 CONFIG_LOCAL,offset PGROUP:LOCAL2_ALLOC ; Save offset of handler

; Find the second code model

	 mov	 ax,CONFIG_SEGMENT ; Address DOS's transient segment
	 lea	 si,UPDATE2_NEXTPARA_MODEL ; Address of our model code
	 mov	 cx,@UPDATE2_MODEL_LEN ; Length of search string
	 call	 SRCHSTR_	  ; Search for the code (Return in DI)
	 jc	 CHECK_MODEL_STC  ; Jump if code not found

	 add	 di,MODEL2_HIGHWATER ; Bump up to HIGHWATER variable
	 mov	 ax,es:[di]	; Get DOS address of next_para
	 mov	 CFG_HIGHWATER,ax ; Save for later

; Find the third code model

	 mov	 ax,CONFIG_SEGMENT ; Address DOS's transient segment
	 lea	 si,SUBSEGLEN_MODEL ; Address of our model code
	 mov	 cx,@SUBSEGLEN_LEN ; Length of search string
	 call	 SRCHSTR_	  ; Search for the code (Return in DI)
	 jc	 CHECK_MODEL_STC  ; Jump if code not found

	 mov	 ax,CFG_NEXTPARA  ; Get offset of next para

	 cmp	 ax,es:[di+SUBSEGLEN_NP1] ; Check address #2
	 jne	 CHECK_MODEL_STC ; Jump if no match

	 mov	 ax,es:[di+SUBSEGLEN_OFF] ; Get subsegment length offset
	 mov	 CFG_SUBSEGLEN,ax ; Save for later use

	 mov	 MODELNO,2	; Mark as model #2

; Because this is MS-DOS 7, we need to handle COMMAND.COM
; even if we load it low as that prevents fragmentation of low DOS

	 or	 LCL_FLAG,@LCL_CCOM ; Mark as analyzing CCOM
CHECK_MODEL2:
CHECK_MODEL_CLC:
	 clc			; Indicate we found a match

	 jmp	 EXIT		; Join common exit code

CHECK_MODEL_STC:
	 stc			; Indicate no match
EXIT:
	 REGREST <es,di,si,cx,ax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_MODEL endp		; End CHECK_MODEL procedure


;***************************************************************************

	 NPPROC  FIND_DOSTOP -- FIND_DOSTOP procedure
	 assume  ds:DGROUP,es:DGROUP,ss:nothing
COMMENT |

Find the highest available para (in case we need to supply a floater)

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

; Calculate out own resident size (in paras)

	 lea	 ax,LAST_BYTE+0Fh ; Resident bytes needed (rounded to para)
	 mov	 cl,4		; Convert from bytes to paras
	 shr	 ax,cl		; ...
	 mov	 RES_PARA,ax	; Save as resident para size

; Get interrupt 12's version of the Top of DOS

	 int	 12h		; Get amount of extended memory in AX
	 mov	 cl,(10-4)	; Convert from KB to paras
	 shl	 ax,cl		; ...

	 mov	 cx,ax		; Save as current Top of DOS limit

; Find DOS's version of the High Water Mark

	 REGSAVE <ds>		; Save registers

	 mov	 ds,CONFIG_SEGMENT ; Address DOS' code/data segment
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 bx,CFG_HIGHWATER ; Get DOS' TOP_OF_DOS
	 mov	 ax,ds:[bx]	; ...

	 REGREST <ds>		; Restore registers
	 assume  ds:DGROUP	; Tell the assembler about it

; If this is INSTALL= time,
; Use the word at PSP:[0002] instead of CFG_HIGHWATER

	 cmp	 CURR_PASS,@PASS_INS ; Install= time?
	 jne	 NO_PSP 	; Jump if not

	 REGSAVE <ds>		; Save registers

	 mov	 ds,PSPSEG	; Addess the PSP
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ax,ds:[0002]	; Get memory size in paras

	 REGREST <ds>		; Restore registers
	 assume  ds:DGROUP	; Tell the assembler about it
NO_PSP:

; Use the lesser of (int12_value) vs. (HighWater/MemSize)

	 cmp	 cx,ax		; Comapre two values
	 jb	 @F		; Jump if int12_value the lesser

	 mov	 cx,ax		; Use the HighWater value
@@:

; Check for PROTMAN (this evil driver has a floater that we must avoid)

	 mov	 al,01h 	; Access code for read
	 lea	 dx,PROT_NAME	; "PROTMAN$" device
	 DOSCALL @OPENF2	; Try to open this device
	 jc	 NO_PROT	; Jump if not present

	 mov	 bx,ax		; Save file handle

	 mov	 al,0		; Function code to get device information
	 DOSCALL @IOCTL2	; Return info in DX

	 pushf			; Save read status (in CF)
	 DOSCALL @CLOSF2	; Close the device
	 popf			; Restore read status
	 jc	 NO_PROT	; Protman not active

	 test	 dx,@IOCTL_DEV	; Is it a device?
	 jz	 NO_PROT	; Jump if not

	 sub	 cx,2000h	; Subtract 128 KB for protman

; CX = The upper limit for our floater

NO_PROT:

	 sub	 cx,RES_PARA	; Minus our resident size in paras
	 sub	 cx,800h	; Minus arbitrary amount (32 KB)
				; (DOS might need more transient space)
	 mov	 FLOAT_SEG,cx	; Save as floater address

	 REGREST <dx,cx,bx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
FIND_DOSTOP	 endp		; End FIND_DOSTOP procedure


;***************************************************************************

	 NPPROC  SET_MSC_GETRC -- Set MAXs MSC_GETRC bit
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Set MAX's MSC_GETRC bit

This will allow MAX to reap Interrupt 21h, function 4Dh,
so that DOS will not print an "Error in line XX" message

|

	 REGSAVE <ax,bx,ds>	; Save registers

; Find some free memory for the info structure

	 mov	 ax,PROFILE_START+0Fh ; End of the entire program
	 shr	 ax,1		; Convert bytes to paras
	 shr	 ax,1		; ...
	 shr	 ax,1		; ...
	 shr	 ax,1		; ...
	 add	 ax,seg XGROUP	; Get next available para

	 mov	 ds,ax		; Address DOS' next available segment
	 assume  ds:nothing	; Tell the assembler about it

; Open and Read in the INFO structure

	 call	 INFO_READ	; Read in the INFO structure
				; Return BX = Device handle

; Set the MSC_GERC bit in the info structure

	 or	 ds:[@INFO_OFFSET+INFO_STR.INFO_MISC],mask $MSC_GETRC ; Set bit

; Write out (and close) the INFO structure

	 call	 INFO_WRITE	; Modify MAX's info structure

	 REGREST <ds,bx,ax>	; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
SET_MSC_GETRC	 endp		; End SET_MSC_GETRC procedure


;***************************************************************************
if @STATISTICS
	 NPPROC  DISP_DBG_CODE -- DISP_DBG_CODE Procedure
	 assume  ds:nothing,es:nothing,ss:nothing

COMMENT |

Display the following variables:

* CONFIG_SEGMENT
* CONFIG_OFFSET
* CFG_NEXTPARA
* CFG_FIRSTPARA
* CFG_HIGHWATER

(used for debugging only)

|

	 REGSAVE <ax,dx,di,ds,es> ; Save registers

	 mov	 ds,DATASEG	; Setup addressibility to DGROUP
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 es,DATASEG	; Setup addressibility to DGROUP
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 ax,CONFIG_SEGMENT ; Segment of code model
	 lea	 di,MSG_DBG_CS	; Address of message
	 call	 FMT_WORD	; Format the code segment

	 mov	 ax,CONFIG_OFFSET ; Offset of code model
	 lea	 di,MSG_DBG_IP	; Address of message
	 call	 FMT_WORD	; Format the code offset

	 cmp	 DOSVER.HILO_STR.HI,3h ; Isit DOS 3.x
	 jne	 @F		; Jump if not

	 mov	 ax,HOOK_OFFSET ; Offset of hook code
	 lea	 di,MSG_DBG_IP	; Address of message
	 call	 FMT_WORD	; Format the code offset
@@:

	 mov	 ax,CFG_NEXTPARA ; Address of next_para variable
	 lea	 di,MSG_DBG_NEXTPARA ; Address of message
	 call	 FMT_WORD	; Format the code offset

	 mov	 ax,CFG_HIGHWATER ; Address of high_water variable
	 lea	 di,MSG_DBG_HIGHWATER ; Address of message
	 call	 FMT_WORD	; Format the code offset

	 DOSCALL @STROUT,MSG_DBG_CODE ; Display the message

;--------

	 cmp	 DOSVER.HILO_STR.HI,3h ; Isit DOS 3.x
	 jne	 @F		; Jump if not

	 mov	 ax,UNHOOK_OFFSET ; Offset of unhook code
	 lea	 di,MSG_DBG_UH1 ; Address of message
	 call	 FMT_WORD	; Format the code offset

	 DOSCALL @STROUT,MSG_DBG_UNHOOK ; Display the message
@@:

;--------

EXIT:
	 REGREST <es,ds,di,dx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_DBG_CODE	 endp			; End DISP_DBG_CODE procedure
endif				; If @STATISTICS


;***************************************************************************

HNCODE	 ends			; End Non-Resident CODE segment


;***************************************************************************

STACK	 segment		; Start STACK segment
	 assume  ss:STACK

STACK	 ends			; End STACK segment

;***************************************************************************

HZZTAIL  segment		; End of Non-Res Data	(HARPO)

; This is the last byte of HARPO
; This is also the start of the profile buffer

	 public  HEADER_START
HEADER_START	 label byte	; Start of profile header (for DeadMan switch)
	 db	 @DEAD_DEV	; Acutal keyword
	 db	 '           '  ; Space before comment
	 db	 '; ',@HNAME
ifdef LANG_GR
	 db	 ' ==> Toter-Mann Schalter automatisch angewandt.'
else
	 db	 ' ==> DeadMan switch automatically applied.'
endif				; IFDEF LANG_GR
	 db	 CR,LF		; ...

	 public  PROFILE_START
PROFILE_START:: 		; Start of actual profile

HZZTAIL  ends			; End of Non-Resident Data


;***************************************************************************

	 END	 HARPO_EXE	; End HARPO_EXE module


