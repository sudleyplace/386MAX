;' $Header:   P:/PVCS/MAX/QMT/MEM_EPM.ASV   1.1   05 Jun 1998 14:04:32   BOB  $
	 title	 MEM_EPM -- MEMCHK Enter Protected Mode Routines
	 page	 58,122
	 name	 MEM_EPM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.

Segmentation:  See MEM_SEGS.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include ASCII.INC
	 include DOSCALL.INC
	 include VIDCALL.INC
	 include 386.INC
	 include PTR.INC
	 include 8255.INC
	 include 8259.INC
	 include CMOS.INC
	 include OPEN.INC
	 include IOCTL.INC
	 include HMA.INC
	 include INTVEC.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include MAXDEV.INC
	 include MASM5.MAC
	 include VDS.INC
	 include DPMI.INC
	 include VCPI.INC
	 include OPCODES.INC
	 include ALLMEM.INC
	 include WINDEVID.INC
	 include VMAXAPI.INC
	 include VMVSAPI.INC
	 include MAC.INC
	 include BIOSDATA.INC
	 include VLSI.INC

	 include MEM_DTE.INC
	 include MEM_MSGS.INC
	 include MEM_OEM.INC
	include MEM_SEGS.INC
	 include MEM_TIME.INC
	 include EMM2CALL.INC
	 include QMAX_CTL.INC
	 include QMAX_VCP.INC
.list

@DEBUGMSG equ	 0		; Display debugging messages

DEBUGMSG macro	 txt
if @DEBUGMSG
local	 L1

DATA	 segment

L1	 db	 <txt>
	 db	 CR,LF,EOS

DATA	 ends

	 REGSAVE <ax,dx>

	 DOSCALL @STROUT,ds:L1

	 REGREST <dx,ax>
endif				; IF @DEBUGMSG

	 endm			; DEBUGMSG

	 extrn	 @KEY_HALT:abs

PSP_SEG  segment use16 at 0	; Start PSP_SEG segment
	 assume  cs:PSPGRP,ds:PSPGRP

	 extrn	 PSP_TERMINATE:dword

PSP_SEG  ends			; End PSP_SEG segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	extrn	CMD_FLAG:dword
	include MEM_CMD.INC
ifdef @BETA
	 extrn	 DBG_FLAG:word
	 include MEM_DBG.INC
endif				; IFDEF @BETA
	 extrn	 GLB_FLAG:word
	 include MEM_GLB.INC

	 extrn	 GL2_FLAG:word
	 include MEM_GL2.INC

	 extrn	 GL3_FLAG:word
	 include MEM_GL3.INC

	 extrn	 CNT_FLAG:word
	 include MEM_CNT.INC

	 extrn	 SYS_FLAG:word
	 include MEM_SYS.INC

	 extrn	 CPUTYPE:byte

	 extrn	 MAPSEG_NXT:word
	 extrn	 MAXSIZE:dword

	 extrn	 DECTIMER:qword

	 extrn	 TIMECNT:word
	 extrn	 TIMETAB:tbyte

	 extrn	 SHDTAB:tbyte
	 extrn	 XSHDTAB:tbyte
	 include MEM_SHD.INC

	 extrn	 SHDCNT:word
	 extrn	 XSHDCNT:word
	 extrn	 SHDIND:word
	 extrn	 XSHDIND:word

;;;;;;;; extrn	 SCRBTAB:tbyte
;;;;;;;; extrn	 SCRBIND:word
;;;;;;;; extrn	 SCRBCNT:word
;;;;;;;;
;;;;;;;; extrn	 AT386_R09:byte
;;;;;;;; extrn	 AT386_R0D:byte
;;;;;;;; extrn	 AT386_R0E:byte
;;;;;;;; extrn	 AT386_R0F:byte
;;;;;;;;
	 extrn	 VIDMODE1:byte
	 extrn	 VIDMODE2:byte

	 extrn	 CON4K:dword
	 extrn	 CON64K:dword
	 extrn	 CON1M:dword

	 extrn	 CODESEG:word
	 extrn	 PSPSEG:word
	 extrn	 ZAPOFF:word

	 extrn	 VIDBASE_FVEC:fword

	 extrn	 HPDASEG:word
	 extrn	 DPMIDRV_VEC:dword
	 extrn	 DPMITERM:byte
	 extrn	 PMSTKZ:word

	 extrn	 HELP_STATE:word
	 extrn	 @HELP_NONE:abs
	 extrn	 MAXNAME:byte

	 public  MEMTIMER
MEMTIMER dq	 0		; Memory timer in units of timer ticks

	 public  LCLGDT
LCLGDT	 XDTE_STR <>		; Protected mode DTE structure

IDT_MAC  macro	 NCNT
	 IDT_STR <PGROUP:INTPROC&NCNT,DTE_CS,,CPL0_INTR3 or CPL3,0>
	 endm			; IDT_MAC

	 public  LCLIDT
LCLIDT	 label	 qword		; Interrupt descriptor table

CNT	 =	 0
.xlist
	 rept	 100h		; Define all interrupts

	 IDT_MAC %CNT
CNT	 =	 CNT+1

	 endm			; REPT 100h
.list
	 public  LCLIDT_LEN
LCLIDT_LEN equ	 $-LCLIDT	; Length of the IDT

	 public  VMVSAPI_VEC
VMVSAPI_VEC dd	 ?		; Seg:Off of VM VSAPI entry point

	 public  VMINT_VEC
VMINT_VEC dd	 ?		; VM interrupt vector

	 public  OLDCR0
OLDCR0	 dd	 ?		; Original CR0 when starting from RM

	 public  DDS
DDS	 DDS_STR <>		; DMA descriptor struc

	 public  EPMTAB
EPMTAB	 EPM_STR <>		; Enter Protected Mode structure

	 public  LCLTSS
LCLTSS	 TSS_STR <>		; Local TSS

	 public  DPMI_FMI
DPMI_FMI DPMIFMI_STR <> 	; DPMI Free Memory Information structure

	 public  DPMI_PS
DPMI_PS  dd	 ?		; Size of a DPMI page

	 public  P2L_SIZE,P2L_HNDL,P2L_ADDR
P2L_SIZE dd	 0		; Amount of extra DPMI memory to
				; allocate for P2L
P2L_HNDL dd	 ?		; Corresponding handle
P2L_ADDR dd	 ?		; Corresponding handle

	 public  LaCODE,LaDATA,LaCR3,LaPTE,PaCR3,NEXTPTE
LaCODE	 dd	 ?		; Linear address of our code segment
LaDATA	 dd	 ?		; ...			data
LaCR3	 dd	 ?		; ...			CR3
LaPTE	 dd	 ?		; ...			PTEs
PaCR3	 dd	 ?		; Physical		CR3
NEXTPTE  dd	 ?		; Offset of next available PTE in PDT

ifdef @BETA
	 public  LaSWAT
LaSWAT	 dd	 -1		; Linear address of SWAT's code/data (-1=none)
endif				; IFDEF @BETA

	 public  VMHANDLE,CB_VM_FLAGS
VMHANDLE dd	 ?		; Save area for VM handle under Windows
CB_VM_FLAGS dd	 ?		; Callback VM flags

	 public  MAXDEV_FVEC
MAXDEV_FVEC df	 ?		; Sel:Off of MAX device entry point

	 public  PMI_FVEC
PMI_FVEC df	 ?		; Sel:Off to PMI code

	 public  PMONSTK_FVEC
PMONSTK_FVEC label fword
	 dd	 ?		; Stack ending offset
	 dw	 DTE_SS 	; Stack selector

	 public  PMINT08_FVEC,PMINT09_FVEC
PMINT08_FVEC df  ?		; Save area for PM INT 08h handler
PMINT09_FVEC df  ?		; ...		       09h ...

	 public  IDT_REAL
IDT_REAL df	 ?		; IDT for real mode

	 public  NMIADDR,NMIOFF
NMIADDR  dd	 ?		; Address for external NMI
NMIOFF	 dw	 0		; Offset of NMI error routine (0=none)

	 public  ERR_FLAG
ERR_FLAG dw	 0		; Error flags
@ERR_INT equ	 8000h		; Unexpected interrupt
@ERR_PRO equ	 4000h		; Unable to enter protected mode

	 public  OLDCUR,OLDTYP
OLDCUR	 dw	 ?		; Original cursor position
OLDTYP	 dw	 ?		; ...		  type

	 public  SEL_4GB,SEL_ALIAS
SEL_4GB  dw	 DTE_4GB	; 4GB  selector (AGROUP)
SEL_ALIAS dw	 DTE_ALIAS	; Alias ...	(PGROUP)

	 public  DPMIMSG
DPMIMSG  dw	 ?		; DPMI message

	 public  DEBOUNCE_FVEC,DEBOUNCE_ARB
DEBOUNCE_FVEC label fword	; Address of debouncing NMI handler
	 dw	 PGROUP:DEBOUNCE,0 ; Offset of ...
	 dw	 DTE_CS 	; Selector of ...
DEBOUNCE_ARB  db CPL0_INTR3 or CPL3 ; Access rights byte of ...

	 public  IBV0,IBV0Z,IBV1,IBV1Z
IBV0	 db	 08h		; Master PIC base
IBV0Z	 db	 08h+8		; ...		  top
IBV1	 db	 70h		; Slave ...
IBV1Z	 db	 70h+8		; ...		  top

	 public  ERR_CODE
ERR_CODE db	 ?		; Error code

	 public  OLDSWAP_CNT
OLDSWAP_CNT dw	 ?		; Old value for swapfile count

	 public  BRKSTATE
BRKSTATE db	 ?		; Previous Ctrl-break state

	 public  SECTIMER
SECTIMER db	 ?		; Tick timer for one second

	 public  EMMNAME
EMMNAME  db	 'EMMXXXX0',0   ; EMM device name

	 public  EMMNAM2,EMMNAM3,EMMNAM4,EMMNAM5
EMMNAM2  db	 '$MMXXXX0',0   ; EMM386.EXE device name if NOEMS
EMMNAM3  db	 'EMMXXXQ0',0   ; QEMM386.SYS device name if NOEMS
EMMNAM4  db	 'EMMQXXX0',0   ; RM386.EXE device name if NOFRAME
EMMNAM5  db	 'QMMXXXX0',0   ; 386MAX.SYS device name if EMS=0

	 public  SWTNAME
SWTNAME  db	 '386SWAT$',0   ; 386SWAT.SYS device name

	 public  CPQ_CACHE
CPQ_CACHE db	 -1		; COMPAQ cache status (-1=none)

	 public  DPMIMAX
DPMIMAX  db	 '386MAX',0     ; DPMI host name for 386MAX

	 public  VLSI_CSIZE
VLSI_CSIZE db	 ?		; VLSI 82C480 L2 cache controller size

	 public  OLDINT24,OLDINT67
	 align	 4		; Ensure dword alignment
OLDINT24 dd	 ?		; Previous critical error handler
OLDINT67 dd	 ?		; Previous Int 67h handler

	 public  INFO_CTL,INFO,INFOSIZE
	 include QMAXINFO.INC
	 db	 ?		; Force even alignment for INFO_STR
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
INFOSIZE equ	 size INFO_STR

	 public  VCPIDBG_VER
VCPIDBG_VER dw	 ?		; VCPI debugger interface version number

	 public  PORT67
PORT67	 equ	 INFO.INFO_P67	; 14 = I/O port for INT 67h communications

DATA	 ends			; End DATA segment


DPMIERR  macro	 MSG
	 local	 L1,L2

DATAMSG  segment use16 byte public 'data' ; Start DATA segment

L1	 db	 L2-L1-1,BEL,'袴> ',MSG,CR,LF
L2	 label	 byte		; Mark end of message for length byte

DATAMSG  ends			; End DATAMSG segment

	 mov	 DPMIMSG,offset DGROUP:L1

	 endm			; DPMIERR


DATAMSG  segment use16 byte public 'data' ; Start DATA segment
DATAMSG  ends			; End DATAMSG segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 GATEA20:near
	 extrn	 DEGATEA20:near

	 extrn	 CHECK_DEV:near
	 extrn	 CHECK_KEYS:near
	 extrn	 CHECK_TIME:near
	 extrn	 CHECK_FAULT:near
	 extrn	 CHKNDKEY:near
	 extrn	 DISP_SCRN:near
	 extrn	 DISP_ALLOC:near
	 extrn	 DISP_PROGSCR:near
	 extrn	 CLEAR_STATUS:near
	 extrn	 CLEAR_CONT:near

	 extrn	 SAVE_IMR:near
	 extrn	 REST_IMR:near

	 extrn	 ENABLE_IRQS:near

	 extrn	 DRAINPIQ:near

	 extrn	 SAVE_SCR:near
	 extrn	 REST_SCR:near
ifndef @RAMDEMO
	 extrn	 SAVE_XSHADOW:near
endif
	 extrn	 DISP_ELAP:near
	 extrn	 DISP_ETA:near

;;;;;;;  extrn	 OLDINT21_VEC:dword
	 extrn	 OLDINT22_VEC:dword
	 extrn	 DATASEG:word
	 extrn	 MD_FLAG:dword

ifdef @RAMEXAM

	 extrn	 OPEN_LOG:near
	 extrn	 APPEND_LOG:near

endif ; @RAMEXAM

	 public  OLDSTK_VEC
OLDSTK_VEC dd	 ?		; Save area for SS:SP for termination

	 public  OLDTMPINT15_VEC
OLDTMPINT15_VEC dd ?		; Save area for original INT 15h handler

	 public  SEL_DATA
SEL_DATA dw	 DTE_DS 	; Data selector (DGROUP)

	 public  VMINTFN
VMINTFN  dw	 ?		; Save area for VM interrupt function

	 FPPROC  INT02 -- NMI Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Non-maskable interrupt (02h) with no error code on stack.

This routine is used when starting from RM or VCPI.

|

	 call	 INT02_COM	; Call common subroutine

	 iretd			; Return to caller
				; Note that this IRETD allows another NMI

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT02	 endp			; End INT02 procedure
	 FPPROC  INT08 -- PM Hardware Timer Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PM Hardware timer interrupt handler

This routine is used when starting from RM or VCPI.

|

; Call INT 08h handler and then check the keyboard buffer

	 FINTD	 PGROUP:INTPROC8 ; Call interrupt handler

	 push	 ds		; Save for a moment

	 call	 INT08_COM	; Call common subroutine
	 assume  ds:DGROUP	; Tell the assembler about it

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT08	 endp			; End INT08 procedure
	 FPPROC  INT09 -- PM Hardware Keyboard Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PM Hardware keyboard interrupt handler

This routine is used when starting from RM or VCPI.

|

; Call INT 09h handler and then check the keyboard buffer

	 FINTD	 PGROUP:INTPROC9 ; Call interrupt handler

	 push	 ds		; Save for a moment

	 call	 INT09_COM	; Call common subroutine
	 assume  ds:DGROUP	; Tell the assembler about it

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT09	 endp			; End INT09 procedure
	 FPPROC  INT24 -- V86 Mode Critical Error Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

V86 mode critical error handler

We only hook Int 24h in V86 mode; we'll fail any critical errors that
occur, since this can only happen when printing to a file.

On entry:
AH	 flags
AL	 Drive number if (AL&80h) == 80h
BP:SI ==> Device header
DI	 Error type in low byte

On exit:
AL	 3 (Fail)

|

	 push	 ds		; Save for a moment

	 push	 seg DGROUP	; Prepare to address DGROUP in V86 mode
	 pop	 ds		; Address it
	 assume  ds:DGROUP	; Tell the assembler

	 or	 GL3_FLAG,@GL3_CRITERR ; Critical error occurred

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler

	 mov	 al,03h 	; Fail operation

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT24	 endp			; End INT24 procedure
	 NPPROC  ENTER_PM -- Enter Protected Mode
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enter protected mode to check memory.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers

	 REGSAVE <fs,gs>	; Save segment registers

	 mov	 fs,CODESEG	; Setup alias to code segment
	 assume  fs:PGROUP	; Tell the assembler about it

	 mov	 OLDSTK_VEC.VOFF,sp ; Save for later use
	 mov	 OLDSTK_VEC.VSEG,ss ; ...

	 xor	 ax,ax		; Zero register
	 mov	 fs,ax		; Initialize FS and GS
	 assume  fs:nothing	; Tell the assembler about it
	 mov	 gs,ax
	 assume  gs:nothing	; Tell the assembler about it

; Install our critical error handler

	 mov	 ax,@GETINT*100h + 24h ; Get Int 24h vector in ES:BX
	 DOSCALL		; ES:BX ==> current Int 24h holder
	 assume  es:nothing	; Tell the assembler

	 mov	 OLDINT24.VOFF,bx ; Save offset
	 mov	 OLDINT24.VSEG,es ; ...  segment

	 push	 ds		; Get DGROUP segment
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler

	 push	 cs		; Get PGROUP segment
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 ax,@SETINT*100h + 24h ; Set Int 24h vector to DS:DX
	 lea	 dx,PGROUP:INT24 ; Our handler
	 DOSCALL		; Install handler

	 push	 es		; Get DGROUP segment
	 pop	 ds		; Address it
	 assume  ds:DGROUP	; Tell the assembler

; Read and save A20 state

	 call	 READA20	; Return the state of the A20 line in @LCL_X1MB

; Save current IDT value to restore later

	 SIDTD	 IDT_REAL	; Save the current IDT

; Save the cursor position

	 mov	 bh,0		; Display page #0
	 VIDCALL @GETPOS	; Return with (DH,DL)=(Row,Col)
				;	      (CH,CL)=(Start,End)
	 mov	 OLDCUR,dx	; Save to restore later
	 mov	 OLDTYP,cx	; ...

; Save the screen

	 call	 SAVE_SCR	; Save it

ifdef @RAMEXAM

; Write log file entry date, time and active options

	 call	 OPEN_LOG	; Write first part of log file entry

endif

; Clear the screen

	 mov	 al,VIDMODE2	; Get new video mode
	 VIDCALL @SETMOD	; Set default video mode

; If this video system supports toggling the intensity/blinking bit,
; do so now

	 test	 GL2_FLAG,@GL2_EGA ; Duzit support it?
	 jz	 short @F	; Jump if not

	 mov	 al,03h 	; Subfunction to toggle the bit
	 mov	 bl,00h 	; Code to enable background intensity
	 VIDCALL @SETPA2	; Request video service
@@:

; Hide the cursor

	 mov	 dx,8000h	; Put cursor row off the screen
	 VIDCALL @SETPOS	; Set position to (DH,DL)=(Row,Col)

ifdef @BETA

; If SWAT is present, create its PTEs

	 call	 SETUP_PTE	; Setup SWAT's PTEs
endif				; IFDEF @BETA

; Setup the GDT entries

	 call	 SETUP_GDT	; Setup the GDT entries

; Install our own handlers in the new IDT

	 call	 SETUP_IDT	; Setup the IDT entries

; Save master and slave interrupt masks to restore later

	 call	 SAVE_IMR	; Save and disable 'em

; If we're on a COMPAQ system, disable (and flush) the cache controller

	 test	 SYS_FLAG,@SYS_CPQ ; Izit a COMPAQ Deskpro 386?
	 jz	 short ENTER_PMSUB_XCPQ1 ; Not this time

	 cmp	 CPQ_CACHE,-1	; Izit valid?
	 jne	 short ENTER_PMSUB_XCPQ1 ; Jump if so (no need to do it again)

	 call	 INST_TMPINT15	; Install temporary INT 15h handler

	 mov	 ax,0F400h	; Get cache controller status
	 int	 16h		; Request keyboard service
				; Return with AL = 01 if enabled
				;		 = 02 if disabled

	 mov	 CPQ_CACHE,al	; Save status

	 cmp	 ah,0E2h	; Check for valid data
	 jne	 short @F	; Not this time

	 mov	 ax,0F402h	; Disable cache contoller
	 int	 16h		; Request keyboard service
@@:
	 call	 REST_TMPINT15	; Restore original INT 15h handler
ENTER_PMSUB_XCPQ1:

; If we're entering PM from RM, enable it now unless it's already enabled.

	 test	 GL2_FLAG,@GL2_DPMI or @GL2_VCPI ; Is either host available?
	 jnz	 short @F	; Jump if so (not from RM)

	 test	 GLB_FLAG,@GLB_X1MB ; Check initial logical state
	 jnz	 short @F	; Jump if it's ON (enabled)

	 call	 GATEA20	; Enable address line A20
;;;;;;;; jc	 ???		; Ignore return code
@@:

; Enter PM

	 call	 ENTER_PMSUB	; Enter or fail
	 assume  ds:DGROUP	; Tell the assembler about it
	 assume  gs:AGROUP	; Tell the assembler about it
	 jc	 near ptr ENTER_PM_EXIT ; Jump if something went wrong

	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jnz	 short ENTER_PM_DPMI1 ; Jump if so

	 push	 dword ptr 0	; Ensure IOPL=NT=DF=0
	 popfd

	 xor	 ebp,ebp	; Ensure the high-order word is zero
				; as there is code which references the
				; stack with EBP.

	 call	 ENABLE_NMI	; Allow NMI to occur

; Ensure the keyboard and timer are installed and enabled

	 call	 ENABLE_IRQS	; Enable the IRQs we need

	 sti			; Allow interrupts

;;;;;;;; call	 SHADOW_ENABLE	; Ensure all shadow RAM available
;;;;;;;; call	 SCRUB_SHADOW	; Initialize certain shadow RAM
;;;;;;;;
	 call	 DISP_SCRN	; Display the initial screen
	 call	 DISP_PROGSCR	; Display the progress screen
ENTER_PM_DPMI1:
	 call	 CLEAR_STATUS	; Clear the screen of previous status data
ENTER_PM_TIME:
	 call	 CHECK_TIME	; Determine the speed of extended memory
	 jnc	 short @F	; Jump if all went well

; We failed on a P2L:  try again allocating less memory than before

	 call	 DPMI_FREE	; Unlock and free all DPMI/VCPI memory

	 add	 P2L_SIZE,4*1024 ; Allocate an extra 4KB
ifndef @RAMDEMO
	 call	 DPMI_ALLOC	; Allocate and lock all DPMI memory
	 jc	 short ENTER_PMERR ; Jump if something went wrong
endif
	 jmp	 short ENTER_PM_TIME ; Go around again

@@:
	 call	 CHECK_FAULT	; Check the memory for faults
ENTER_PMERR:
	 test	 GL2_FLAG,@GL2_VCPI ; Is there a VCPI host?
	 jnz	 short @F	; Jump if so (wait to unlock in VM)

	 call	 DPMI_FREE	; Unlock and free all DPMI/VCPI memory
	 call	 DPMI_RESET	; Reset MAX/Windows flags
@@:
;;;;;;;; call	 SHADOW_DISABLE ; Ensure shadow RAM not in effect
;;;;;;;;
	 cli			; Disallow interrupts

	 or	 GL3_FLAG,@GL3_XPM1 ; Tell GOREAL to perform one-time exit actions

	 call	 GOREAL 	; Return to real mode

; If we just exited PM to RM, perform exit tasks

	 test	 GL2_FLAG,@GL2_DPMI or @GL2_VCPI ; Is either host available?
	 jnz	 short ENTER_PM_XRM ; Jump if so (not from RM)

	 call	 REST_IMR	; Restore original IMR
	 call	 ENABLE_NMI	; Allow NMI to occur

; Restore address line A20 to the state as marked by @GLB_X1MB

	 test	 GLB_FLAG,@GLB_X1MB ; Check initial logical state
	 jnz	 short @F	; Jump if it's ON (enabled)

	 call	 DEGATEA20	; Disable address line A20
;;;;;;;; jc	 ???		; Ignore return code
@@:
ENTER_PM_XRM:
	 test	 GL2_FLAG,@GL2_VCPI ; Is there a VCPI host?
	 jz	 short @F	; Jump if not

	 call	 DPMI_FREE	; Unlock and free all DPMI/VCPI memory
@@:
	 clc			; Indicate we succeeded
ENTER_PM_EXIT:
	 pushf			; Save flags

	 test	 SYS_FLAG,@SYS_CPQ ; Izit a COMPAQ Deskpro 386?
	 jz	 short ENTER_PM_XCPQ2 ; Not this time

	 call	 INST_TMPINT15	; Install temporary INT 15h handler

	 mov	 al,CPQ_CACHE	; Restore status

	 mov	 ah,0F4h	; Set cache controller status
	 int	 16h		; Request keyboard service

	 call	 REST_TMPINT15	; Restore original INT 15h handler
ENTER_PM_XCPQ2:

; Restore the original video mode

	 mov	 al,VIDMODE1	; Get original video mode
	 VIDCALL @SETMOD	; Set that mode

; Restore the original screen

	 call	 REST_SCR	; Restore it

; Restore the cursor position

	 mov	 bh,0		; Display page #0
	 mov	 dx,OLDCUR	; Get previous cursor position
	 VIDCALL @SETPOS	; Set position to (DH,DL)=(Row,Col)

; Restore the cursor type

	 mov	 bh,0		; Display page #0
	 mov	 cx,OLDTYP	; Get previous cursor type
	 VIDCALL @SETTYP	; Set type to (CH,CL)=(Start,End)

; Restore the old swapfile count (if we changed it)

	 call	 ENABLE_SWAP	; Re-enable the old swapfile count

ifdef @RAMEXAM

; Now write the results of the test and the ranges tested.  We can't
; do this in protected mode since we might be VCPI or real mode based.

	 call	 APPEND_LOG	; Write results to log file

endif

; Restore original critical error handler
	 push	 ds		; Save

	 mov	 ax,@SETINT*100h + 24h ; Set Int 24h vector
	 lds	 dx,OLDINT24	; DS:DX ==> previous critical error handler
	 DOSCALL		; Set Int 24h vector to DS:DX

	 assume  ds:nothing	; Tell the assembler

	 pop	 ds		; Restore
	 assume  ds:DGROUP	; Tell the assembler

	 popf			; Restore flags

	 REGREST <gs,fs>	; Restore segment registers
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENTER_PM endp			; End ENTER_PM procedure
	 NPPROC  ENTER_PMSUB -- Subroutine To ENTER_PM
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Subroutine to ENTER_PM

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise
IF	 =	 0 if entered from RM

|

	 pushad 		; Save all EGP registers

	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jz	 near ptr ENTER_PMSUB_NODPMI ; Jump if not

; Disable Ctrl-Break handling

	 mov	 al,0		; Function code to get current state
	 DOSCALL @CHKBRK	; Return with state in DL
	 mov	 BRKSTATE,dl	; Save to restore upon exit

	 mov	 al,1		; Function code to set current state
	 mov	 dl,0		; Set state to OFF
	 DOSCALL @CHKBRK	; Return with state in DL

; Catch termination via Int 22 vector in PSP

	 mov	 es,PSPSEG	; Address PSP
	 assume  es:PSPGRP	; Tell the assembler

	 mov	 PSP_TERMINATE.VOFF,offset PGROUP:INT22 ; Offset of our handler
	 mov	 PSP_TERMINATE.VSEG,seg PGROUP		; Segment ...

; Address the HPDA

	 mov	 es,HPDASEG	; Get segment of HPDA
	 assume  es:nothing	; Tell the assembler about it

	 or	 GLB_FLAG,@GLB_DPMIERR ; Assume we get an error
;;;;;;;; DPMIERR <'Unable to enter Protected Mode through DPMI host.'>
	 DPMIERR @MSG_DPMI1

; Check for 386MAX as the DPMI host:  if present, tell it to
; disable the swapfile.

	 call	 DISABLE_SWAP	; Disable the swapfile

	 mov	 DPMITERM,1	; Mark as DPMI terminate time in case we fail

	 mov	 ax,1		; We're a 32-bit client
	 call	 DPMIDRV_VEC	; Request entry into PM
	 mov	 DPMITERM,0	; Mark as no longer DPMI terminate time
	 jc	 near ptr ENTER_PMSUB_DPMIERR0 ; Jump if something went wrong

	 assume  ds:DGROUP	; Tell the assembler about it

	 and	 GLB_FLAG,not @GLB_DPMIERR ; No longer in error

; Get a Read-Write code alias to save SEL_DATA

	 mov	 bx,cs		; Get our code selector
	 DPMICALL @DPMI_GETALIAS ; Return with AX = alias selector
;;;;;;;; DPMIERR <'Unable to map segment to selector.'>
	 DPMIERR @MSG_DPMI2
	 jc	 near ptr ENTER_PMSUB_DPMIERR ; Jump if something went wrong

	 mov	 es,ax		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 SEL_DATA,ds	; Save as data selector
	 mov	 SEL_ALIAS,es	; ...	  code alias

	 mov	 ax,ds		; Get data selector
	 mov	 es,ax		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 DEBOUNCE_FVEC.FSEL,cs ; Save selector

; If MAX is present and we're running under Windows, make the 1684h
; API call to get and save the state of the exclusive bit and set it.

	 test	 GLB_FLAG,@GLB_WIN3 ; Running under Windows?
	 jz	 short ENTER_PMSUB_XWIN ; Jump if not

	 test	 GL2_FLAG,@GL2_MAX ; Running under 386MAX?
	 jz	 short ENTER_PMSUB_XWIN ; Jump if not

	 mov	 ax,1684h	; Code to get Device API Entry Point
	 mov	 bx,LoadHi_Device_ID ; Get our device ID
	 int	 2Fh		; Request multiplexor service
	 assume  es:nothing	; Tell the assembler about it
				; Returns ES:DI = 0:0 on error,
				; otherwise ES:DI ==> entry point
	 mov	 ax,es		; Izit valid?
	 or	 ax,di		; ...
	 jz	 short ENTER_PMSUB_XWIN ; Jump if not

	 movzx	 edi,di 	; Zero to use as dword
	 mov	 MAXDEV_FVEC.FOFF,edi ; Save for later use
	 mov	 MAXDEV_FVEC.FSEL,es ; ...

	 xor	 ebx,ebx	; Zero to see if this function works
	 mov	 ax,VMAX_GetVMHandle ; Code to get VM handle
	 call	 MAXDEV_FVEC	; Request MAX device services
				; Returns EBX = VM handle

	 and	 ebx,ebx	; Izit valid?
	 jz	 short ENTER_PMSUB_XWIN ; Jump if not

	 mov	 VMHANDLE,ebx	; Save for later use

	 mov	 ax,VMAX_GetTimeSliceInfo ; Code to get time slice info
	 call	 MAXDEV_FVEC	; Request MAX device services
	 jc	 short ENTER_PMSUB_XWIN ; Jump if not successful
				; Returns  EAX = % of CPU time	     (O)
				;	   ECX = Foreground priority (I/O)
				;	   EDX = Background priority (I/O)
				;	   ESI = CB_VM_Status flags  (I/O)
	 mov	 CB_VM_FLAGS,esi ; Save to restore later

	 or	 esi,VMStat_Exclusive ; Set the exclusive bit

	 mov	 ax,VMAX_SetTimeSliceInfo ; Code to set time slice info
	 call	 MAXDEV_FVEC	; Request MAX device services
;;;;;;;; jc	 short ???	; Ignore error return
ENTER_PMSUB_XWIN:
	 mov	 es,SEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

; Before we install PM interrupt handlers, we need to lock
; our linear memory

	 mov	 eax,LaCODE	; Get our code linear address
	 movzx	 edx,MAPSEG_NXT ; Get next available paragraph
	 shl	 edx,4-0	; Convert from paras to bytes
	 sub	 edx,eax	; Subtract to get size in bytes

	 mov	 ebx,eax	; Copy linear address to lock
	 shr	 ebx,16 	; Shift down high-order word
	 mov	 cx,ax		; BX:CX = # linear address to lock

	 mov	 esi,edx	; Copy size in bytes
	 shr	 esi,16 	; Shift down high-order word
	 mov	 di,dx		; SI:DI = size of block in bytes

	 DPMICALL @DPMI_LOCKLINREG ; Local linear region
;;;;;;;; DPMIERR <'Unable to lock local linear region.'>
	 DPMIERR @MSG_DPMI3
	 jc	 near ptr ENTER_PMSUB_DPMIERR ; Jump if something went wrong

; Hook INT 23h in VM and PM

	 mov	 bl,23h 	; Intercept this one
	 mov	 cx,CODESEG	; Get our code segment
	 lea	 dx,VMINT23	; CX:DX ==> our VM handler
	 DPMICALL @DPMI_SETVMIV ; Setup our VM handler
				; This function always succeeds

	 mov	 bl,23h 	; Intercept this one
	 mov	 cx,cs		; Get our code selector
	 lea	 edx,PMINT23	; CX:EDX ==> our PM handler
	 DPMICALL @DPMI_SETPMIV ; Setup our PM handler
				; This function always succeeds unless
				; you mess up CX

; Setup our all memory selector

	 mov	 cx,1		; Allocate one descriptor
	 DPMICALL @DPMI_GETLDT	; Request DPMI services
;;;;;;;; DPMIERR <'Unable to allocate one DPMI selector.'>
	 DPMIERR @MSG_DPMI4
	 jc	 near ptr ENTER_PMSUB_DPMIERR ; Jump if something went wrong

	 mov	 SEL_4GB,ax	; Save as all memory selector
	 mov	 VIDBASE_FVEC.FSEL,ax ; ...
	 mov	 bx,ax		; Copy to selector register

	 lea	 edi,LCLGDT.DTE_4GB ; ES:EDI ==> DTE
	 DPMICALL @DPMI_GETLDTE ; Function code to get LDT descriptor
;;;;;;;; DPMIERR <'Unable to get DPMI descriptor.'>
	 DPMIERR @MSG_DPMI5
	 jc	 near ptr ENTER_PMSUB_DPMIERR ; Jump if something went wrong

	 mov	 LCLGDT.DTE_4GB.DESC_SEGLM0,-1 ; Limit is 4GB
	 or	 LCLGDT.DTE_4GB.DESC_SEGLM1,((mask $DTE_G) or (mask $DTE_B) or (mask $SEGLM1)) ; G=B=1

	 lea	 edi,LCLGDT.DTE_4GB ; ES:EDI ==> DTE
	 DPMICALL @DPMI_SETLDTE ; Function code to set LDT descriptor
;;;;;;;; DPMIERR <'Unable to set DPMI descriptor.'>
	 DPMIERR @MSG_DPMI6
	 jc	 near ptr ENTER_PMSUB_DPMIERR ; Jump if something went wrong

	 mov	 gs,SEL_4GB	; Get AGROUP data selector
	 assume  gs:AGROUP	; Tell the assembler about it

; If we're running under an unbundled DPMI host (such as QEMM or Netroom)
; VDS services may no longer be present.
	 sub	 ebx,ebx	; Clear high order word
	 mov	 bx,seg BIOSDATA ; Address BIOS data area
	 shl	 ebx,4-0	; Convert paras to bytes

	 assume  gs:BIOSDATA	; Tell a little white lie
	 test	 VDS[ebx],@VDS_ENA ; Are VDS services still present?
	 assume  gs:AGROUP	; Retract nose

	 jnz	 short @F	; Jump if so

	 and	 GLB_FLAG,not @GLB_VDS ; No VDS services
@@:
; Hook NMI to handle exceptions
; We hook it as both an interrupt and exception because
; the DPMI spec isn't clear on which is which.

	 mov	 bl,02h 	; Intercept this one
	 mov	 cx,cs		; Get our code selector
	 lea	 edx,PMINT02	; CX:EDX ==> our PM interrupt handler
	 DPMICALL @DPMI_SETPMIV ; Setup our PM handler
				; This function always succeeds unless
				; you mess up CX

	 mov	 bl,02h 	; Intercept this one
	 mov	 cx,cs		; Get our code selector
	 lea	 edx,PMEXC02	; CX:EDX ==> our PM exception handler
	 DPMICALL @DPMI_SETPEHV ; Setup our PM handler
				; This function always succeeds unless
				; you mess up CX or BL

; Hook hardware timer interrupt handler

	 mov	 bl,08h 	; Intercept this one
	 DPMICALL @DPMI_GETPMIV ; Return with CX:EDX ==> handler
				; This function always succeeds
	 mov	 PMINT08_FVEC.FOFF,edx ; Save for later use
	 mov	 PMINT08_FVEC.FSEL,cx ; ...

	 mov	 bl,08h 	; Intercept this one
	 mov	 cx,cs		; Get our code selector
	 lea	 edx,PMINT08	; CX:EDX ==> our PM interrupt handler
	 DPMICALL @DPMI_SETPMIV ; Setup our PM handler
				; This function always succeeds unless
				; you mess up CX

; Hook hardware keyboard interrupt handler

	 mov	 bl,09h 	; Intercept this one
	 DPMICALL @DPMI_GETPMIV ; Return with CX:EDX ==> handler
				; This function always succeeds
	 mov	 PMINT09_FVEC.FOFF,edx ; Save for later use
	 mov	 PMINT09_FVEC.FSEL,cx ; ...

	 mov	 bl,09h 	; Intercept this one
	 mov	 cx,cs		; Get our code selector
	 lea	 edx,PMINT09	; CX:EDX ==> our PM interrupt handler
	 DPMICALL @DPMI_SETPMIV ; Setup our PM handler
				; This function always succeeds unless
				; you mess up CX

; Get page size for memory sizing

	 DPMICALL @DPMI_GETPAGESIZ ; Return with BX:CX = page size
;;;;;;;; DPMIERR <'Unable to get DPMI page size.'>
	 DPMIERR @MSG_DPMI7
	 jc	 near ptr ENTER_PMSUB_DPMIERR ; Jump if something went wrong

	 mov	 DPMI_PS.ELO,cx ; Save for later use
	 mov	 DPMI_PS.EHI,bx ; ...

; Because the next steps might take a while (under Windows, at least),
; display the screen

	 call	 DISP_SCRN	; Display the initial screen
	 call	 DISP_PROGSCR	; Display the progress screen
	 call	 CLEAR_STATUS	; Clear the screen of previous status data
	 call	 DISP_ALLOC	; Display allocating memory message
ifndef @RAMDEMO
	 call	 DPMI_ALLOC	; Allocate and lock all DPMI memory
	 jc	 short ENTER_PMSUB_DPMIERR ; Jump if something went wrong
endif
	 cmp	 SHDCNT,0	; Is there any memory to test?
	 jne	 near ptr ENTER_PMSUB_CLC ; Jump if so

;;;;;;;; DPMIERR <'No memory to test.'>
	 DPMIERR @MSG_DPMI8
ENTER_PMSUB_DPMIERR:
	 or	 GLB_FLAG,@GLB_DPMIERR ; DPMI error occurred, DPMIERR is valid

	 call	 GOREAL 	; Return to real mode

	 jmp	 ENTER_PMSUB_ERR1 ; Join common error code

; The DPMI switch from VM to PM failed:  restore the INT 22h handler

	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENTER_PMSUB_DPMIERR0:

; If the DPMI host was 386MAX, there's an error code in AX

	 cmp	 ax,8012h	; Izit insufficient memory?
	 jne	 short @F	; Jump if not

;;;;;;;; DPMIERR <'Insufficient memory to enter Protected Mode through DPMI host.'>
	 DPMIERR @MSG_DPMI1A
@@:
	 push	 es		; Save for a moment

	 mov	 es,PSPSEG	; Address PSP
	 assume  es:PSPGRP	; Tell the assembler

	 mov	 eax,OLDINT22_VEC ; Old terminate vector
	 mov	 PSP_TERMINATE,eax ; Restore old terminate vector

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 ENTER_PMSUB_ERR1 ; Join common error code

	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing

ENTER_PMSUB_NODPMI:
	 test	 GL2_FLAG,@GL2_VCPI ; Is there a VCPI host?
	 jz	 short ENTER_PMSUB_NOVCPI ; Jump if not

	 mov	 PMONSTK_FVEC.FOFF,esp ; Save current ESP

	 cli			; Enter with IF=0

	 lea	 esi,EPMTAB	; Get offset of system tables
	 add	 esi,LaDATA	; Plus base linear address
	 VCPIBACK @VCPI_EPM	; Enter Protected Mode
ENTER_PMSUB_PMON:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

	 cli			; Some VCPI hosts (RM386 comes to mind)
				; start us off with IF=1

; Ensure no interrupts between above VCPICALL and the following LSS

	 mov	 ds,SEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 es,SEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 lss	 esp,PMONSTK_FVEC ; SS:ESP ==> PM stack
	 assume  ss:nothing	; Tell the assembler about it

	 xor	 ax,ax		; A convenient zero
	 mov	 fs,ax		; Clear selector
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 gs,SEL_4GB	; Get AGROUP data selector
	 assume  gs:AGROUP	; Tell the assembler about it

	 jmp	 ENTER_PMSUB_INRM ; Join common OK code

ENTER_PMSUB_NOVCPI:
	 assume  ds:DGROUP,es:DGROUP ; Tell the assembler about it

; Ensure FS and GS are valid

	 xor	 ax,ax		; A convenient zero
	 mov	 fs,ax		; Ensure valid
	 mov	 gs,ax		; ...

; Enter protected mode

	 lea	 si,LCLGDT	; ES:SI ==> descriptor table
	 mov	 bl,IBV1	; Initialize hardware interrupts here
	 mov	 bh,IBV0	; ...
	 mov	 ah,89h 	; Function code to enter protected mode

	 test	 CMD_FLAG,@CMD_EPM ; Izit roll our own EPM time?
	 jnz	 short ENTER_PMSUB_EPM ; Jump if so

	 int	 15h		; Request BIOS service
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it
	 cli			; Disable interrupts

; Ensure FS and GS are valid

	 xor	 cx,cx		; A convenient zero
	 mov	 fs,cx		; Ensure valid
	 mov	 gs,cx		; ...

; Because some stupid BIOS vendors don't correctly set either
; the CPU flags or AH, we just test the $PE bit in the MSW to
; determine whether or not we are in protected mode

	 smsw	 cx		; Get machine status word

	 test	 cx,mask $PE	; Check the Protect Enable bit
	 jnz	 short ENTER_PMSUB2 ; Jump if we are in protected mode

	 cmp	 ah,80h 	; Check for function not supported
	 je	 short ENTER_PMSUB_EMU ; Yes, so we must emulate it

	 cmp	 ah,86h 	; Check for function not supported
	 je	 short ENTER_PMSUB_EMU ; Yes, so we must emulate it
ENTER_PMSUB_ERR:
	 mov	 ERR_CODE,ah	; Save error code
	 or	 ERR_FLAG,@ERR_PRO ; Mark as in error
ENTER_PMSUB_ERR1:
	 stc			; Indicate something went wrong

	 jmp	 ENTER_PMSUB_EXIT ; Join common exit code

ENTER_PMSUB_EMU:
	 smsw	 cx		; Get machine status word

	 test	 cx,mask $PE	; Already in protected mode?
	 jnz	 short ENTER_PMSUB_ERR ; Yes, so that's an error
ENTER_PMSUB_EPM:
	 call	 near ptr INT15PROT ; Enter protected mode
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 jmp	 short ENTER_PMSUB3 ; Join common code

; Return in protected mode with interrupts and NMI disabled

	 public  ENTER_PMSUB2
ENTER_PMSUB2:
	 call	 REST_IMR	; Restore original IMR
	 call	 ENABLE_NMI	; Allow NMI to occur
ENTER_PMSUB3:
	 mov	 ds,SEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 gs,SEL_4GB	; Get AGROUP data selector
	 assume  gs:AGROUP	; Tell the assembler about it

; Enable paging

	mov	eax,PaCR3	; Get physical address of CR3
	mov	cr3,eax 	; Tell the CPU about it

	mov	eax,cr0 	; Get current contents
	or	eax,mask $PG	; Enable paging
	mov	cr0,eax 	; Tell the CPU about it

	 and	 LCLGDT.DTE_TSS.DESC_ACCESS,not (mask $DS_BUSY) ; Clear the busy bit
	 mov	 ax,DTE_TSS	; Get our TSS selector
	 ltr	 ax		; Put it into effect

; We're entering PM (for the first time)  -- perform one time actions

ENTER_PMSUB_INRM:
	 bts	 GL3_FLAG,$GL3_EPM1 ; Have we already done this?
	 jc	 short ENTER_PMSUB_CLC ; Jump if so

; Save the original CR0 to restore later

	 mov	 eax,cr0	; Get original CR0
	 mov	 OLDCR0,eax	; Save for later use
ENTER_PMSUB_CLC:
	 clc			; Indicate we're successful
ENTER_PMSUB_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENTER_PMSUB endp		; End ENTER_PMSUB procedure
	 NPPROC  DISABLE_SWAP -- Disable The DPMI Host Swapfile
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable the DPMI host swapfile so we come up faster.

|

	 REGSAVE <ax,bx,si,di,es> ; Save registers

	 lea	 si,DPMIMAX	; DS:SI ==> DPMI host name for 386MAX
	 mov	 ax,@DPMI_API2F ; Get VSAPI function #
	 int	 2Fh		; request multiplexor service
	 assume  es:nothing	; Tell the assembler about it
				; Returning ES:DI ==> VSAPI entry point
	 and	 ax,ax		; Did it succeed?
	 jnz	 short DISABLE_SWAP_EXIT ; Jump if not

	 mov	 VMVSAPI_VEC.VOFF,di ; Save for later use
	 mov	 VMVSAPI_VEC.VSEG,es ; ...

	 mov	 ax,@VMVSAPI_NOSWAP ; Function code to disable swapping
	 mov	 bx,1		; Disable swapping once
	 call	 VMVSAPI_VEC	; Request VSAPI service
				; returning old count in BX
	 mov	 OLDSWAP_CNT,bx ; Save to restore later
DISABLE_SWAP_EXIT:
	 REGREST <es,di,si,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISABLE_SWAP endp		; End DISABLE_SWAP procedure
	 NPPROC  ENABLE_SWAP -- Re-Enable The Old DPMI Host Swapfile Count
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Re-enable the old DPMI host swapfile count as we're terminating.

|

	 REGSAVE <ax,bx>	; Save registers

	 cmp	 VMVSAPI_VEC,0	; izit valid?
	 je	 short ENABLE_SWAP_EXIT ; Jump if not

	 mov	 ax,@VMVSAPI_NOSWAP ; Function code to disable swapping
	 mov	 bx,OLDSWAP_CNT ; Restore the old count
	 call	 VMVSAPI_VEC	; Request VSAPI service
				; returning old count in BX (should be zero)
ENABLE_SWAP_EXIT:
	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_SWAP endp		; End ENABLE_SWAP procedure
	 NPPROC  SETUP_GDT -- Setup the GDT
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup the GDT entries

|

	 REGSAVE <eax,ebx,ecx>	; Save registers

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,cs		; Get our data segment
	 shl	 eax,4-0	; Convert to paras to bytes
	 mov	 LaCODE,eax	; Save as our code's linear base address

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,ds		; Get our data segment
	 shl	 eax,4-0	; Convert to paras to bytes
	 mov	 LaDATA,eax	; Save as our data's linear base address

	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jnz	 near ptr SETUP_GDT_EXIT ; Jump if so (no GDT setup needed)

; Setup DTE_CS descriptor to our code segment

	 push	 LaCODE 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_CODE	; Pass access rights byte
	 push	 DTE_CS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup DTE_DS, DTE_ES, and DTE_SS descriptors to our data segment

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_DS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_ES 	; Pass selector
	 call	 SET_GDT	; Set the GDT

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 ((mask $DTE_B) shl 8) or CPL0_DATA ; Pass access rights byte
	 push	 DTE_SS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local code alias descriptor

	 push	 LaCODE 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_ALIAS	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local all memory descriptor

	 push	 dword ptr 0	; Pass base
	 push	 dword ptr 0	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_4GB	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup DTE_GDT

	 lea	 ebx,LCLGDT	; Get the GDT offset to linear address
	 add	 ebx,LaDATA	; Plus our 32-bit linear address of DGROUP
	 mov	 LCLGDT.DTE_GDT.DTR_BASE,ebx ; Save base
	 mov	 LCLGDT.DTE_GDT.DTR_LIM,(size XDTE_STR)-1 ; Save limit

; Setup DTE_IDT

	 lea	 ebx,LCLIDT	; Get the IDT offset to linear address
	 add	 ebx,LaDATA	; Plus our 32-bit linear address of DGROUP
	 mov	 LCLGDT.DTE_IDT.DTR_BASE,ebx ; Save base
	 mov	 LCLGDT.DTE_IDT.DTR_LIM,LCLIDT_LEN-1 ; Save limit

	 mov	 VIDBASE_FVEC.FSEL,DTE_4GB; Save as 4GB descriptor

	 call	 SETUP_TSS	; Setup the TSS

; Split cases between VCPI and RM entry into PM

	 test	 GL2_FLAG,@GL2_VCPI ; Is there a VCPI host?
	 jz	 short SETUP_GDT_EXIT ; Jump if not

; Setup the structures for PM entry via VCPI
; Setup to Enter and Exit Protected Mode

	 call	 SETUP_EPM	; Set it up
SETUP_GDT_EXIT:
	 REGREST <ecx,ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_GDT endp			; End SETUP_GDT procedure
	 NPPROC  SET_GDT -- Set Global Descriptor Table
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set the global descriptor table.

|

SET_GDT_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
SET_GDT_DTE dw	 ?		; DTE to set
SET_GDT_ARB db	 ?		; Access rights byte
SET_GDT_FLG db	 ?		; DTE flags
SET_GDT_LEN dd	 ?		; Segment length
SET_GDT_BAS dd	 ?		; Segment base

SET_GDT_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,bx,ecx>	; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 eax,[bp].SET_GDT_BAS ; Get segment base
	 mov	 ecx,[bp].SET_GDT_LEN ; Get segment length
	 dec	 ecx		; Convert from length to limit

	 cmp	 ecx,CON1M	; Check against limit limit
	 jb	 short @F	; Jump if within range

	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 or	 ecx,(mask $DTE_G) shl 16 ; Set G-bit
@@:
	 mov	 bx,[bp].SET_GDT_DTE ; Get the DTE to set

	 mov	 LCLGDT.DESC_BASE01.EDD[bx],eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 LCLGDT.DESC_BASE3[bx],al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 LCLGDT.DESC_SEGLM0[bx],cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 or	 cl,[bp].SET_GDT_FLG ; Include any flags
	 mov	 LCLGDT.DESC_SEGLM1[bx],cl ; Save as data limit
;;;;;;;; ror	 ecx,16 	; Swap back

; Set access rights byte

	 mov	 al,[bp].SET_GDT_ARB ; Get it
	 mov	 LCLGDT.DESC_ACCESS[bx],al ; Set it

	 popf			; Restore flags

	 REGREST <ecx,bx,eax>	; Restore

	 pop	 bp		; Restore

	 ret	 2*2+2*4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_GDT  endp			; End SET_GDT procedure
	 NPPROC  SETUP_TSS --  Setup The TSS
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup the TSS for EPM

|

	 REGSAVE <eax>		; Save register

; Setup local TSS descriptor

	 lea	 eax,LCLTSS	; Get local TSS address
	 add	 eax,LaDATA	; Convert from relative to absolute

	 push	 eax		; Pass base
	 push	 dword ptr (size TSS_STR) ; Pass length
	 push	 CPL0_IDLE3	; Pass access rights byte
	 push	 DTE_TSS	; Pass selector
	 call	 SET_GDT	; Set the GDT

; We should never use the PL0 stack, but let's set it up anyway

	 mov	 LCLTSS.TSS_ESP0,offset ds:PMSTKZ
	 mov	 LCLTSS.TSS_SS0,DTE_SS

	 mov	 eax,PaCR3	; Get CR3 physical address
	 mov	 LCLTSS.TSS_CR3,eax ; Save in TSS

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_TSS endp			; End SETUP_TSS procedure
	 NPPROC  SETUP_EPM -- Setup to Enter and Exit Protected Mode
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup to enter and exit protected mode.

|

	 REGSAVE <eax>		; Save register

; Setup our own CR3

	 mov	 eax,PaCR3	; Get CR3 physical address
	 mov	 EPMTAB.EPM_CR3,eax ; Save in EPMTAB

; Setup pointer to local GDT

	 lea	 eax,LCLGDT.DTE_GDT ; Get pointer
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 EPMTAB.EPM_GDTP,eax ; Save it

; Setup pointer to local IDT

	 lea	 eax,LCLGDT.DTE_IDT ; Get pointer
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 EPMTAB.EPM_IDTP,eax ; Save it

; Setup local LDT and TR

	 mov	 EPMTAB.EPM_LDTR,0 ; Don't use one
	 mov	 EPMTAB.EPM_TR,DTE_TSS ; Use local one

; Setup return address

	 mov	 EPMTAB.EPM_EXIT.FOFF,offset cs:ENTER_PMSUB_PMON
	 mov	 EPMTAB.EPM_EXIT.FSEL,DTE_CS ; Save our code selector

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_EPM endp			; End SETUP_EPM procedure
	 NPPROC  SETUP_IDT -- Setup IDT Entries
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup IDT entries

|

	 pushad 		; Save all EGP registers

	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jnz	 near ptr SETUP_IDT_EXIT ; Jump if so

	 movzx	 eax,IBV0	; Get the master PIC base
	 mov	 LCLIDT.IDT_OFFLO[02h*type IDT_STR],offset cs:INT02
	 mov	 LCLIDT.IDT_OFFLO[eax*type IDT_STR],offset cs:INT08
	 inc	 eax		; Skip to IRQ1
	 mov	 LCLIDT.IDT_OFFLO[eax*type IDT_STR],offset cs:INT09

ifdef @BETA
	 test	 GL2_FLAG,@GL2_SWAT ; Is SWAT present?
	 jz	 short SETUP_IDT_XDBG ; Jump if not

; Tell SWAT about our new CR3 and linear address
; if we're entering PM via VCPI
; Note that we don't want to use the VCPIBACK macro here, as
; SWAT hooks Int 67h out of the IDT.

	 mov	 edx,LaSWAT	; Get new linear address
	 mov	 ebx,PaCR3	; Get new CR3 physical address
	 VCPICALL @VCPI_DBGLIN	; Set new CR3 and linear address

	 or	 ah,ah		; Check for presence
;;;;;;;; SETMSG  "Error on debugger set CR3 and linear address",ERR
	 jnz	 near ptr SETUP_IDT_ERR ; Jump if in error
@@:

; Initialize debugger GDT entries

	 lea	 di,LCLGDT.DTE_SWAT ; ES:DI ==> 1st debugger GDT entry
	 mov	 bx,DTE_SWAT	; Get initial selector
	 VCPICALL @VCPI_DBGINI	; Initialize the GDT entries

	 or	 ah,ah		; Check for presence
;;;;;;;; SETMSG  "Error on debugger GDT initialization",ERR
	 jnz	 near ptr SETUP_IDT_ERR ; Jump if in error

; Initialize the debugger's IDT entries

	 xor	 bx,bx		; Initial interrupt #
	 mov	 cx,20h 	; # interrupt #s
	 lea	 di,LCLIDT	; ES:DI ==> initial IDT entry
	 mov	 edx,PaCR3	; Get physical address of CR3
SETUP_IDT_DBGNEXT:
	 VCPICALL @VCPI_DBGIDT	; Initialize an IDT entry

	 cmp	 ah,83h 	; Check for invalid interrupt #
	 je	 short @F	; Jump if so

	 or	 ah,ah		; Check for presence
;;;;;;;; SETMSG  "Error on debugger GDT initialization",ERR
	 jnz	 near ptr SETUP_IDT_ERR ; Jump if in error
@@:
	 inc	 bx		; Skip to next interrupt #
	 add	 di,size IDT_STR ; Skip to next IDT entry

	 loop	 SETUP_IDT_DBGNEXT ; Jump if more interrupt #s
SETUP_IDT_XDBG:
endif				; IFDEF @BETA
SETUP_IDT_ERR:
SETUP_IDT_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_IDT endp			; End SETUP_IDT procedure
ifdef @BETA
	 NPPROC  SETUP_PTE -- Setup SWAT PTEs
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup SWAT PTEs if the debugger interface version is 4.0 or higher.

|

	 pushad 		; Save all EGP registers
	 REGSAVE <es>		; Save register

	 test	 GL2_FLAG,@GL2_SWAT ; Is SWAT present?
	 jz	 short SETUP_PTE_EXIT ; Jump if not

; If we're entering PM via DPMI, we don't have our own PTEs.

	test	GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	jnz	short SETUP_PTE_EXIT ; Jump if so

; If we can't setup old SWAT's PTEs, turn off all debugging support

	 cmp	 VCPIDBG_VER,0400h ; Does it support function F9?
	 jb	 short SETUP_PTE_NOSWAT ; Jump if not

; Get and round down the base address to a 4KB boundary

	 mov	 edi,LaSWAT	; Get linear address of SWAT
	 and	 di,not (4*1024-1) ; Round down to 4KB boundary

; Convert the linear address to offset into the PDIR

	 shr	 edi,(12-2)-0	; Convert from bytes to 4KB in dwords
	 add	 edi,LaPTE	; Plus linear address of the PTEs (/4KB)

	 xor	 ax,ax		; A convenient zero
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

; Request that SWAT fill in the PTEs

	 mov	 ecx,-1 	; Fill in as many as it wants
	 VCPICALL @VCPI_FILLPTE ; Fill in ECX PTEs into ES:EDI

	 or	 ah,ah		; Check for presence
;;;;;;;; SETMSG  "Error on debugger fill PTE",ERR
	 jz	 short SETUP_PTE_EXIT ; Jump if all went well

SETUP_PTE_NOSWAT:
	 and	 GL2_FLAG,not @GL2_SWAT ; No SWAT today
	 mov	 DBG_FLAG,0	; Ensure we don't do anything untoward
SETUP_PTE_EXIT:
	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_PTE endp			; End SETUP_PTE procedure
endif				; IFDEF @BETA
	 FPPROC  INT15PROT -- Enter Protected Mode
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enter protected mode on systems that doesn't support
INT 15h BIOS function 89h or on systems for which we
force it.

* Disable NMI (no need to disable as we'll re-enable shortly)
* Disable interrupts
* Gate A20 on (note we don't do this anymore to avoid A20 hardware problems)
* Setup DTE_BIOS entry
* Load GDTR
* Load IDTR
* Setup 8259 (note we don't do this anymore to avoid keyboard lockups)
* Enter protected mode
* Setup segment registers
* Return to caller

On entry:

ES:SI	 ==>	 descriptor table
BH	 =	 8259 origin for master
BL	 =	 8259 origin for slave

|

; * Disable interrupts

	 cli

; * Setup DTE_BIOS entry

	 movzx	 eax,CODESEG	; Get current code segment
	 shl	 eax,4-0	; Convert from paras to bytes

	 mov	 es:[si].DTE_BIOS.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 es:[si].DTE_BIOS.DESC_BASE3,al
;;;;;;;; ror	 eax,8		; Rotate back
	 mov	 es:[si].DTE_BIOS.DESC_SEGLM0,0FFFFh ; 64KB of code
	 mov	 es:[si].DTE_BIOS.DESC_SEGLM1,0
	 mov	 es:[si].DTE_BIOS.DESC_ACCESS,CPL0_CODE

; * Load GDTR from low memory

	 LGDTD	 es:[si].DTE_GDT.EDF

; * Load IDTR

	 LIDTD	 es:[si].DTE_IDT.EDF

; * Enter protected mode

	 mov	 eax,cr0	; Get current CR0
	 or	 ax,mask $PE	; Mark as enabling protected mode
	 mov	 cr0,eax	; Enter protected mode

	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 FIJMP	 PGROUP:@F,DTE_BIOS ; Flush prefetch instruction queue
@@:

; * Setup segment registers

	 mov	 ax,DTE_DS	; Get DS selector
	 mov	 ds,ax
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 ax,DTE_ES	; Get ES selector
	 mov	 es,ax
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 ax,DTE_SS	; Get SS selector
	 mov	 ss,ax
	 assume  ss:nothing	; Tell the assembler about it

; Ensure FS and GS are valid

	 xor	 ax,ax		; A convenient zero
	 mov	 fs,ax		; Ensure valid
	 mov	 gs,ax		; ...

; * Return to caller

	 pop	 ax		; Get return offset
	 push	 DTE_CS 	; Put return selector on stack
	 push	 ax		; Followed by offset

	 xor	 ax,ax		; Successful return code (AH=0, CF=0, ZF=1)

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT15PROT endp			; End INT15PROT procedure
	 NPPROC  VMINTFN1 -- VM Interrupt Function #1
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VM interrupt function #1 (SW INTs)

|

	 db	 @OPCOD_INT
VMINTNO1 db	 ?		; Interrupt #

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMINTFN1 endp			; End VMINTFN1 procedure
	 NPPROC  VMINTFN2 -- VM Interrupt Function #2
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VM interrupt function #2 (HW INTs)

|

	 pushad 		; Save all EGP registers

	 db	 @OPCOD_INT
VMINTNO2 db	 ?		; Interrupt #

	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMINTFN2 endp			; End VMINTFN2 procedure
	 NPPROC  STOREINT -- Store The INT #
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Store the INT # from [bp].INT_ERR into VMINTNO.

On entry:

SS:BP	 ==>	 INT_STR

|

	 REGSAVE <ax,es>	; Save for a moment

	 mov	 es,CODESEG	; Get segment of PGROUP
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 al,[bp].INT_ERR ; Get the interrupt #

	 cmp	 al,IBV0	; Izit at or above master PIC base?
	 jb	 short STOREINT1 ; Jump if not

	 cmp	 al,IBV0Z	; Izit below master PIC top?
	 jb	 short STOREINT_HW ; Jump if so (it's a HW INT)

	 cmp	 al,IBV1	; Izit at or above slave PIC base?
	 jb	 short STOREINT1 ; Jump if not

	 cmp	 al,IBV1Z	; Izit below slave PIC top?
	 jb	 short STOREINT_HW ; Jump if so (it's a HW INT)
STOREINT1:
	 mov	 PGROUP:VMINTNO1,al ; Save in INT instruction
	 mov	 VMINTFN,offset PGROUP:VMINTFN1 ; Save routine addr

	 jmp	 short STOREINT_EXIT ; Join common exit code

STOREINT_HW:
	 mov	 PGROUP:VMINTNO2,al ; Save in INT instruction
	 mov	 VMINTFN,offset PGROUP:VMINTFN2 ; Save routine addr
STOREINT_EXIT:
	 REGREST <es,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STOREINT endp			; End STOREINT procedure
	 FPPROC  INTPROC -- IDT Entries
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

IDT entries.

|

INT_STR  struc

INT_BP	 dw	 ?		; Caller's BP
	 dw	 4 dup (?)	; DS, ES, FS, GS
INT_ERR  db	 ?,?		; Interrupt #
INT_EIP  dd	 ?		; ...	   EIP
INT_CS	 dw	 ?,?		; ...	   CS w/filler
INT_EFL  dd	 ?		; ...	   EFL

INT_STR  ends

	 public  INTPROC_COM
INTPROC_COM:
	 REGSAVE <ds,es,fs,gs>	; Save for a moment

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 mov	 ds,SEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 call	 GOREAL 	; Return to real mode

; Reflect the interrupt to the appropriate handler

	 call	 STOREINT	; Store the INT # from [bp].INT_ERR into VMINTNO

	 push	 ax		; Save for a moment

	 mov	 ds,DATASEG	; Get segment of DGROUP
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 es,DATASEG	; Get segment of DGROUP
	 assume  es:DGROUP	; Tell the assembler about it

; Get caller's flags
; SS:BP  ==>	 INT_STR

FLMASKLO =	 ((mask $NT) or (mask $IOPL) or (mask $TF) or (mask $IF))

	 mov	 ax,[bp].INT_EFL.ELO ; Get caller's flags
	 and	 ax,not FLMASKLO ; NT=IOPL=TF=IF=0
	 push	 ax		; Put into effect
	 popf			; ...

	 pop	 ax		; Restore

	 pop	 bp		; Restore

	 call	 VMINTFN	; Call the appropriate function

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

FLMASKHI =	 ((mask $VMHI) or (mask $RFHI) or FLMASKLO)

	 push	 eax		; Save for a moment

	 pushfd 		; Get the return flags
	 pop	 eax		; ...
	 and	 eax,not FLMASKHI ; VM=RF=NT=IOPL=TF=IF=0
	 and	 [bp].INT_EFL,FLMASKHI ; Isolate
	 or	 [bp].INT_EFL,eax ; Include

	 pop	 eax		; Restore

	 pop	 bp		; Restore

	 mov	 ds,DATASEG	; Get segment of DGROUP
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 es,DATASEG	; Get segment of DGROUP
	 assume  es:DGROUP	; Tell the assembler about it

	 call	 ENTER_PMSUB	; Enter or fail
	 assume  ds:DGROUP	; Tell the assembler about it
	 assume  gs:AGROUP	; Tell the assembler about it
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger

	 jmp	 short $	; March in place
@@:
	 REGREST <gs,fs,es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

	 add	 sp,2		; Strip error code from stack

	 iretd			; Return to caller

LBL	 macro	 NUM
INTPROC&NUM:
	 endm			; LBL

CNT	 =	 0

	 rept	 100h		; Define all entries
	 LBL	 %CNT
	 push	 CNT
	 jmp	 INTPROC_COM	; Join common code
CNT	 =	 CNT+1

	 endm

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INTPROC  endp			; End INTPROC procedure
	 NPPROC  ENABLE_NMI -- Enable NMI
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable NMI

|

	 pushf			; Save flags
	 cli			; Ensure interrupts disabled

	 push	 ax		; Save for a moment

	 call	 CLR_PARITY	; Clear the parity latches

	 test	 MD_FLAG,@MD_XT ; Running on an XT?
	 jz	 short ENABLE_NMI1    ; Not this time

	 mov	 al,80h 	; High-order bit set to enable NMI
	 out	 0A0h,al	; Enable it on an XT
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 jmp	 short ENABLE_NMI2 ; Join common code

ENABLE_NMI1:
	 mov	 al,@CMOS_ENANMI ; Enable NMI
	 out	 @CMOS_CMD,al
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@CMOS_DATA	; Ensure OUT is followed by IN
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

; If we're on an MCA, reset arbitration mask bit

	 test	 MD_FLAG,@MD_MCA ; Izit an MCA?
	 jz	 short @F	; Jump if not

	 in	 al,90h 	; Get arbitration register
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

; Clear the arbitration mask bit (Bit 6) as well as everything else
; except for enable system microprocessor cycles (Bit 7)

	 and	 al,@BIT7	; Clear everything except Bit 7
	 out	 90h,al 	; Send it back
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue
@@:
ENABLE_NMI2:
	 call	 CLR_PARITY	; Clear the parity latches

	 pop	 ax		; Restore
	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_NMI endp 		; End ENABLE_NMI procedure
	 NPPROC  CLR_PARITY -- Clear Parity Latches
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear the parity latches

|

	 REGSAVE <ax>		; Save register

	 test	 GL2_FLAG,@GL2_NOPARITY ; Was NOPARITY specified?
	 jnz	 short CLR_PARITY_EXIT ; Jump if so

	 test	 MD_FLAG,@MD_XT ; Running on an XT?
	 jz	 short CLR_PARITY1    ; Not this time

	 mov	 ah,mask $XTPAR ; Get parity mask for XT

	 jmp	 short CLR_PARITY2 ; Join common code

CLR_PARITY1:
	 mov	 ah,mask $ATPAR ; Get parity mask for AT
CLR_PARITY2:
	 in	 al,@8255_B	; Get the parity latches
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 or	 al,ah		; Toggle parity check latches off
	 out	 @8255_B,al	; Tell the system about it
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 xor	 al,ah		; Toggle parity check latches on
	 out	 @8255_B,al	; Tell the system about it
;;;;;;;; call	 DRAINPIQ	; Drain the Prefetch Instruction Queue
CLR_PARITY_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLR_PARITY endp 		; End CLR_PARITY procedure
	 NPPROC  READA20 -- Read A20 Status
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read the A20 line status.

On exit:

@LCL_X1MB =	 0 if A20 is OFF (disabled)
	  =	 1 ...	     ON  (enabled)

|

	 pushf			; Save flags

	 cli			; Disallow interrupts

	 REGSAVE <ax,es,fs>	; Save registers

	 mov	 ax,seg HMASEG	; Get HMA segment #
	 mov	 es,ax		; Address it
	 assume  es:HMASEG	; Tell the assembler about it

	 and	 GLB_FLAG,not @GLB_X1MB ; Assume OFF (disabled)

	 mov	 ax,seg INTVEC	; Get interrupt vector segment
	 mov	 fs,ax		; Address it
	 assume  fs:INTVEC	; Tell the assembler about it

	 mov	 ax,INT00_VEC.ELO ; Get first word

	 cmp	 ax,HMASTART.ELO ; Compare 'em
	 jne	 short READA20_ON ; If they're unequal, A20 is ON

; Assume A20 is ON:		 � Assume A20 is OFF:
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; AX	 INT00_VEC	HMASTART � AX	  INT00_VEC	 HMASTART
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
; xxxx	   xxxx 	  xxxx	 � xxxx     xxxx	   xxxx

	 not	 HMASTART.ELO	; Complement and retest
	 not	 ax

; yyyy	   xxxx 	  yyyy	 � yyyy     yyyy	   yyyy

	 cmp	 ax,INT00_VEC.ELO ; Compare 'em
	 not	 HMASTART.ELO	; Restore
	 je	 short READA20_EXIT ; If they're equal, A20 is OFF
READA20_ON:
	 or	 GLB_FLAG,@GLB_X1MB ; Mark as ON (enabled)
READA20_EXIT:
	 REGREST <fs,es,ax>	; Restore
	 assume  es:nothing,fs:nothing ; Tell the assembler about it

	 popf			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READA20  endp			; End READA20 procedure
	 NPPROC  GOREAL -- Switch Into Real Mode
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Switch into real mode and continue with the interrupted instruction.

|

	 REGSAVE <eax,bx>	; Save registers

	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jz	 short GOREAL_NODPMI ; Jump if not

; We need to fool DOS into not freeing our code and data.  We'll regain
; control via INT22, where we'll restore ownership of our code and data
; to the original value (so it'll get freed when we finally terminate).
	 mov	 DPMITERM,1	; Mark as DPMI terminate time

	 push	 gs		; Save for a moment

	 mov	 gs,SEL_4GB	; Get AGROUP data selector
	 assume  gs:AGROUP	; Tell the assembler about it

	 movzx	 eax,PSPSEG	; Address PSP segment
	 dec	 ax		; Back off to MAC entry
	 shl	 eax,4-0	; Convert paras to bytes

	 inc	 AGROUP:[eax].MAC_OWNR ; Fudge the owner field

	 pop	 gs		; Restore
	 assume  gs:nothing	; Tell the assembler

	 DOSCALL @EXITRC	; Terminate through DOS
GOREAL_NODPMI:
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 test	 GL2_FLAG,@GL2_VCPI ; Is there a VCPI host?
	 jz	 short GOREAL_NOVCPI ; Jump if not

	 call	 ACT_XPM	; Call one-time exit PM actions

; Return to Virtual Mode

	 mov	 es,SEL_DATA	; Get DGROUP data selector
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 eax,esp	; Copy current ESP

	 PUSHD	 gs		; GS with filler
	 PUSHD	 fs		; FS ...
	 push	 DATASEG.EDD	; DS ...
	 push	 DATASEG.EDD	; ES ...
	 push	 DATASEG.EDD	; SS ...
	 push	 eax		; ESP
	 PUSHD	 0		; EFL
	 push	 CODESEG.EDD	; Real mode CS with filler
	 lea	 eax,GOREAL_PMOFF ; Get return address
	 push	 eax		; EIP

	 push	 DTE_4GB	; Get all memory selector
	 pop	 ds		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 cli			; Exit with IF=0

	 mov	 ah,@VCPI	; Get major VCPI function code
	 mov	 al,@VCPI_EPM	; Return to VM86 mode
	 call	 PMI_FVEC	; Call PMI code
GOREAL_PMOFF:
	 assume  ds:DGROUP,es:DGROUP ; Tell the assembler about it

	 jmp	 short GOREAL_EXIT ; Join common exit code

GOREAL_NOVCPI:
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 call	 ACT_XPM	; Call one-time exit PM actions

; It must be true that the linear and physical address for
; this page are identical

	 mov	 ax,DTE_DS	; Use low memory data selector, not the
				; stack selector as that one has the B-bit set.

; Reset SS:SP to avoid stack fault

	 mov	 ss,ax
	 assume  ss:nothing	; Tell the assembler about it
	 mov	 sp,sp		; Just for the fun of it

; Load all data segment registers with 64KB selector in low memory

	 mov	 ds,ax
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 es,ax
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 fs,ax
	 assume  fs:DGROUP	; Tell the assembler about it

	 mov	 gs,ax
	 assume  gs:DGROUP	; Tell the assembler about it

; Load base and limit of IDT for real mode
; Note that we do it here in case the FAR JMP below signals
; an error.

	 LIDTD	 IDT_REAL	; Reset IDT for real mode

; Exit protected mode

	 mov	 eax,cr0	; Get current CR0
	 and	 eax,not ((mask $PG) or (mask $PE)) ; Turn off PG & PE bits
	 mov	 cr0,eax	; Exit protected mode

; Jump to real mode code

	 FIJMP	 PGROUP:@F,<seg PGROUP> ; Far jump to set access rights
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
@@:

; Re-initialize segment registers

	 mov	 ax,DATASEG	; Get segment of DGROUP
	 mov	 ds,ax
	 assume  ds:DGROUP	; Tell the assembler about it
	 mov	 es,ax
	 assume  es:DGROUP	; Tell the assembler about it
	 mov	 ss,ax
	 assume  ss:nothing	; Tell the assembler about it
	 mov	 sp,sp		; Just for the fun of it

	 mov	 fs,ax
	 assume  fs:DGROUP	; Tell the assembler about it

	 mov	 gs,ax
	 assume  gs:DGROUP	; Tell the assembler about it
GOREAL_EXIT:
	 REGREST <bx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GOREAL	 endp			; End GOREAL procedure
	 NPPROC  ACT_XPM -- One-time Exit PM Actions
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

One-time exit PM actions.

|

	 REGSAVE <eax,ecx,esi,es> ; Save registers

	 btr	 GL3_FLAG,$GL3_XPM1 ; Is this the last time?
	 jnc	 short ACT_XPM_EXIT ; Jump if not

; We're exiting PM (for the last time) -- perform one time actions
; If we're on a 486 or later, restore the original CR0

	 cmp	 CPUTYPE,04h	; Izit 486 or later?
	 jb	 short ACT_XPM_X486 ; Jump if not

	 mov	 eax,OLDCR0	; Get the original value
	 mov	 cr0,eax	; Restore
ACT_XPM_X486:
ACT_XPM_EXIT:
	 REGREST <es,esi,ecx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_XPM  endp			; End ACT_XPM procedure
;;;	     NPPROC  READ_82C302 -- Read Command/Data from 82C302
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Read data into AH from command register in AL in the 82C302.
;;;
;;; |
;;;
;;;	     out     22h,al	    ; Send command to 82C302
;;;	     call    DRAINPIQ	    ; Drain the Prefetch Instruction Queue
;;;
;;;	     mov     ah,al	    ; Copy value
;;;
;;;	     in      al,23h	    ; Read data from 82C302
;;; ;;;;;;;; call    DRAINPIQ	    ; Drain the Prefetch Instruction Queue
;;;
;;;	     xchg    al,ah	    ; Return in data in AH, original command in AL
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; READ_82C302 endp		    ; End READ_82C302 procedure
;;;	     NPPROC  SEND_82C302 -- Send Command/Data to 82C302
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Send data in AH to command register in AL in the 82C302.
;;;
;;; |
;;;
;;;	     REGSAVE <ax>	    ; Save register
;;;
;;;	     out     22h,al	    ; Send command to 82C302
;;;	     call    DRAINPIQ	    ; Drain the Prefetch Instruction Queue
;;;
;;;	     mov     al,ah	    ; Put data into AL
;;;	     out     23h,al	    ; Send data to 82C302
;;; ;;;;;;;; call    DRAINPIQ	    ; Drain the Prefetch Instruction Queue
;;;
;;;	     REGREST <ax>	    ; Restore
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; SEND_82C302 endp		    ; End SEND_82C302 procedure
;;;	     NPPROC  SHADOW_ENABLE -- Enable Shadow RAM
;;;	     assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Enable shadow RAM on HP Vectra RS/16 and /20.
;;;
;;; |
;;;
;;;	     REGSAVE <ax>	    ; Save register
;;;
;;;	     test    GL2_FLAG,@GL2_DPMI or @GL2_VCPI ; Is there a DPMI/VCPI host?
;;;	     jnz     short SHADOW_ENABLE_EXIT ; Jump if so
;;;
;;;	     test    GLB_FLAG,@GLB_AT386 ; Izit AT/386 shadow RAM?
;;;	     jz      short SHADOW_ENABLE_EXIT ; Not this time
;;;
;;;	     pushf		    ; Save flags
;;;	     cli		    ; Nobody move
;;;
;;; ; Put EGA back into ROM
;;;
;;;	     mov     ah,AT386_R09[1] ; Get new register value
;;;	     mov     al,09h	    ; Register #
;;;	     call    SEND_82C302    ; Send AL=command/AH=data to 82C302
;;;
;;; ; Handle Address Map registers 0Dh to 0Fh
;;;
;;;	     mov     ah,AT386_R0D[1] ; Get new register value
;;;	     mov     al,0Dh	    ; Register #
;;;	     call    SEND_82C302    ; Send AL=command/AH=data to 82C302
;;;
;;;	     mov     ah,AT386_R0E[1] ; Get new register value
;;;	     mov     al,0Eh	    ; Register #
;;;	     call    SEND_82C302    ; Send AL=command/AH=data to 82C302
;;;
;;;	     mov     ah,AT386_R0F[1] ; Get new register value
;;;	     mov     al,0Fh	    ; Register #
;;;	     call    SEND_82C302    ; Send AL=command/AH=data to 82C302
;;;
;;;	     popf		    ; Restore
;;; SHADOW_ENABLE_EXIT:
;;;	     REGREST <ax>	    ; Restore
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; SHADOW_ENABLE endp		    ; End SHADOW_ENABLE procedure
;;;	     NPPROC  SHADOW_DISABLE -- Unshadow RAM
;;;	     assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Disable shadow RAM on HP Vectra RS/16 and /20.
;;;
;;; |
;;;
;;;	     REGSAVE <ax>	    ; Save register
;;;
;;;	     test    GL2_FLAG,@GL2_DPMI or @GL2_VCPI ; Is there a DPMI/VCPI host?
;;;	     jnz     short SHADOW_DISABLE_EXIT ; Jump if so
;;;
;;;	     test    GLB_FLAG,@GLB_AT386 ; Izit AT/386 shadow RAM?
;;;	     jz      short SHADOW_DISABLE_EXIT ; Not this time
;;;
;;;	     pushf		    ; Save flags
;;;	     cli		    ; Nobody move
;;;
;;;	     mov     ah,AT386_R0F[0] ; Get old register value
;;;	     mov     al,0Fh	    ; Register #
;;;	     call    SEND_82C302    ; Send AL=command/AH=data to 82C302
;;;
;;;	     mov     ah,AT386_R0E[0] ; Get old register value
;;;	     mov     al,0Eh	    ; Register #
;;;	     call    SEND_82C302    ; Send AL=command/AH=data to 82C302
;;;
;;;	     mov     ah,AT386_R0D[0] ; Get old register value
;;;	     mov     al,0Dh	    ; Register #
;;;	     call    SEND_82C302    ; Send AL=command/AH=data to 82C302
;;;
;;;	     mov     ah,AT386_R09[0] ; Get old register value
;;;	     mov     al,09h	    ; Register #
;;;	     call    SEND_82C302    ; Send AL=command/AH=data to 82C302
;;;
;;;	     popf		    ; Restore
;;; SHADOW_DISABLE_EXIT:
;;;	     REGREST <ax>	    ; Restore
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; SHADOW_DISABLE endp 	    ; End SHADOW_DISABLE procedure
;;;	     NPPROC  SCRUB_SHADOW -- Initialize Certain Shadow RAM
;;;	     assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Initialize certain shadow RAM.
;;;
;;; This routine runs in protected mode.
;;;
;;; |
;;;
;;;	     REGSAVE <eax,ecx,si,edi> ; Save registers
;;;
;;;	     mov     cx,SCRBCNT     ; Get count of scrub RAM entries
;;;	     jcxz    SCRUB_SHADOW_EXIT ; Jump if nothing to initialize
;;;
;;;	     test    CMD_FLAG,@CMD_XSCRB ; NOSCRUB specified?
;;;	     jnz     short SCRUB_SHADOW_EXIT ; Yes, skip all this
;;;
;;;	     xor     si,si	    ; Initialize index into SCRTAB
;;; SCRUB_SHADOW_NEXT:
;;;	     push    cx 	    ; Save for a moment
;;;
;;;	     mov     edi,SCRBTAB.SCRB_EBASE[si] ; Get base of RAM
;;;	     mov     ecx,SCRBTAB.SCRB_ESIZE[si] ; Get size of block in bytes
;;;	     shr     ecx,2-0	    ; Convert from bytes to dwords
;;;
;;;	     xor     eax,eax	    ; Set to zero in case some programs expect it
;;;
;;;	     REGSAVE <ecx,edi>	    ; Save for a moment
;;;	 rep stos    es:[edi].EDD   ; Store a value there (any value)
;;;	     REGREST <edi,ecx>	    ; Restore
;;;
;;;	     REGSAVE <ecx,edi>	    ; Save for a moment
;;;	 rep stos    es:[edi].EDD   ; Store a value there (any value)
;;;	     REGREST <edi,ecx>	    ; Restore
;;;
;;;	     REGSAVE <ecx,edi>	    ; Save for a moment
;;;	 rep stos    es:[edi].EDD   ; Store a value there (any value)
;;;	     REGREST <edi,ecx>	    ; Restore
;;;
;;;	     pop     cx 	    ; Restore
;;;
;;;	     add     si,size SCRB_STR ; Skip to next entry
;;;
;;;	     loop    SCRUB_SHADOW_NEXT ; Jump if more entries
;;; SCRUB_SHADOW_EXIT:
;;;	     REGREST <edi,si,ecx,eax> ; Restore
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; SCRUB_SHADOW endp		    ; End SCRUB_SHADOW procedure
	 NPPROC  INST_TMPINT15 -- Install Temporary INT 15h Handler
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Install a temporary INT 15 handler.

This handler is necessary to overcome a hardware and software
bug in the COMPAQ 386 products.

The hardware bug is a spurious parity error when reading the
configuration register.  The software bug is a mishandle of
the parity error (AH=01, CF=1) within the INT 16h BIOS code.

The solution is to install an INT 15 handler which traps
block move calls, checks for a parity error and ignores it.

|

	 REGSAVE <ax,bx,dx,ds,es> ; Save registers

	 mov	 ds,CODESEG	; Setup alias to code segment
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 al,15h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> current handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDTMPINT15_VEC.VOFF,bx ; Save for later use
	 mov	 OLDTMPINT15_VEC.VSEG,es

	 mov	 al,15h 	; Intercept this one
	 DOSCALL @SETINT,TMPINT15 ; Install our own handler (DS:DX ==> TMPINT15)

	 REGREST <es,ds,dx,bx,ax>  ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_TMPINT15 endp		; End INST_TMPINT15 procedure
	 NPPROC  REST_TMPINT15 -- Restore From Temporary INT 15h Handler
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore original INT 15 handler after INST_TMPINT15.

|

	 REGSAVE <ax,dx,ds>	; Save registers

	 lds	 dx,OLDTMPINT15_VEC ; DS:DX ==> original INT 15h handler
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 al,15h 	; Intercept this one
	 DOSCALL @SETINT	; Restore

	 REGREST <ds,dx,ax>	; Restore
	 assume  ds:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_TMPINT15 endp		; End REST_TMPINT15 procedure
	 FPPROC  TMPINT15 -- Temporary INT 15h Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Temporary INT 15h handler.

Convret parity errors into normal return.

|

ARG_STR  struc

	 dw	 ?		; Caller's BP
ARG_CSIP dd	 ?		; Caller's return address
ARG_FLG  dw	 ?		; Caller's flags

ARG_STR  ends

	 pushf			; Save flags

	 cmp	 ah,87h 	; Check for block move
	 jne	 short TMPINT15_ORIG ; Not this time, continue on

	 popf			; Restore

; Set flags to caller's value (IF is the only important one)

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack
	 push	 [bp].ARG_FLG	; Put flags onto stack
	 popf			; Restore caller's IF
	 pop	 bp		; Restore

	 pushf			; Simulate INT calling environment
	 cli
	 call	 OLDTMPINT15_VEC ; Call original handler
	 jnc	 short TMPINT15_RETF ; No problem, return to caller

	 pushf			; Save flags

	 cmp	 ah,01h 	; Check for parity error
	 jne	 short TMPINT15_RETF0 ; Not this time

	 popf			; Restore

	 xor	 ah,ah		; Normal return code, CF=0, ZF=1

	 jmp	 short TMPINT15_RETF ; Join common exit code

TMPINT15_RETF0:
	 popf			; Restore
TMPINT15_RETF:
	 ret	 2		; Return to caller, popping flags

TMPINT15_ORIG:
	 popf			; Restore flags

	 jmp	 OLDTMPINT15_VEC ; Continue on

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TMPINT15 endp			; End TMPINT15 procedure
	 NPPROC  INT22 -- Return address for DPMI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

We terminate via Int 21h function 4Ch after changing the ownership of
our PSP MAC entry so it won't get freed.  We've put this address in
as the Int 22h vector in the PSP (PSP_TERMINATE_VEC) before entering
protected mode via DPMI.

We can then reload our PSP, restore the original MAC ownership, clean
up in virtual mode, and terminate for real via Int 21h fn 4Ch.

|

	 lss	 sp,OLDSTK_VEC	; Address the stack for termination
	 assume  ss:nothing	; Tell the assembler about it

	 push	 seg DGROUP	; Get V86 mode segment of DGROUP
	 pop	 ds		; Address it
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 es,PSPSEG	; Address PSP segment
	 assume  es:PSPGRP	; Tell the assembler about it

; Restore previous terminate vector (presumably, COMMAND.COM)
	 mov	 ax,OLDINT22_VEC.VOFF ; Old terminate offset
	 mov	 dx,OLDINT22_VEC.VSEG ; ...	      segment

	 mov	 PSP_TERMINATE.VOFF,ax ; Restore old terminate vector
	 mov	 PSP_TERMINATE.VSEG,dx ; ...

; Make it our current PSP
	 mov	 bx,es		; Get PSP segment
	 dec	 bx		; Back off to MAC segment
	 mov	 es,bx		; Address it
	 assume  es:nothing	; Tell the assembler

	 dec	 es:[0].MAC_OWNR ; Restore owner to normal

	 inc	 bx		; Get PSP segment
	 DOSCALL @SETPSP	; Set current PSP to BX

	 push	 seg DGROUP	; Get V86 mode segment of DGROUP
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

; Restore previous Ctrl-Break state

	 mov	 al,1		; Function code to set current state
	 mov	 dl,BRKSTATE	; Restore previous state
	 DOSCALL @CHKBRK	; Return with state in DL

	 clc			; Indicate we succeeded

	 jmp	 ENTER_PM_EXIT	; Join common exit

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT22	 endp			; End INT22 procedure
ifndef @RAMDEMO
	 NPPROC  DPMI_ALLOC -- Allocate And Lock All DPMI Memory
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate and lock all DPMI memory

On exit:

CF	 =	 0 if all went well
	 =	 otherwise

|

	 pushad 		; Save all EGP registers

; In case we previously came through here and allocated too much
; DPMI physical memory, allocate some memory up front and deallocate
; upon exit from this subroutine.  This extra allocated memory might
; be needed by the DPMI host to perform Phys-to-Lins for us later on.

	 mov	 eax,P2L_SIZE	; Get amount of extra memory to allocate in bytes

	 and	 eax,eax	; Any extra memory to allocate?
	 jz	 short DPMI_ALLOC_NEXTBLK ; Jump if not

	 mov	 ebx,eax	; Copy # bytes to allocate
	 shr	 ebx,16 	; Shift down high-order word
	 mov	 cx,ax		; BX:CX = # bytes to allocate
	 DEBUGMSG 'Allocating memory'
	 DPMICALL @DPMI_GETMEM	; Allocate BX:CX bytes of memory
;;;;;;;; DPMIERR <'Unable to allocate DPMI P2L memory.'>
	 DPMIERR @MSG_DPMI9
	 jc	 near ptr DPMI_ALLOC_EXIT ; Jump if something went wrong (note CF=1)
				; Return with BX:CX = linear address of the block
				;	      SI:DI = memory handle
	 mov	 P2L_ADDR.ELO,cx ; Save to de-allocate later
	 mov	 P2L_ADDR.EHI,bx ; ...
	 mov	 P2L_HNDL.ELO,di ; Save to de-allocate later
	 mov	 P2L_HNDL.EHI,si ; ...

	 mov	 esi,edx	; Copy size in bytes
	 shr	 esi,16 	; Shift down high-order word
	 mov	 di,dx		; SI:DI = size of block in bytes
	 DPMICALL @DPMI_LOCKLINREG ; Lock the block at BX:CX for SI:DI bytes
;;;;;;;; DPMIERR <'Unable to lock DPMI P2L memory.'>
	 DPMIERR @MSG_DPMI10
	 jc	 near ptr DPMI_ALLOC_EXIT ; Jump if something went wrong (note CF=1)

; Allocate and lock all memory

DPMI_ALLOC_NEXTBLK:
	 lea	 edi,DPMI_FMI	; ES:EDI ==> Free Memory Information struc
	 DPMICALL @DPMI_GETFMI	; Get free memory information
;;;;;;;; DPMIERR <'Unable to get DPMI free memory information.'>
	 DPMIERR @MSG_DPMI11
	 jc	 near ptr DPMI_ALLOC_EXIT ; Jump if something went wrong (note CF=1)

	 mov	 eax,DPMI_FMI.DPMIFMI_LPLOCK ; Get remaining lockable pages

	 and	 eax,eax	; Any left?
	 jz	 short DPMI_ALLOC_END ; Jump if not

	 mul	 DPMI_PS	; Times page size to get byte size

	 cmp	 eax,DPMI_FMI.DPMIFMI_LBFREE ; Use smaller of largest free block
	 jb	 short @F	; Jump if

	 mov	 eax,DPMI_FMI.DPMIFMI_LBFREE ; Use largest free block
@@:
	 mov	 edx,eax	; Save for later use
DPMI_ALLOC1:
	 mov	 ebx,edx	; Copy # bytes to allocate
	 shr	 ebx,16 	; Shift down high-order word
	 mov	 cx,dx		; BX:CX = # bytes to allocate
	 DPMICALL @DPMI_GETMEM	; Allocate BX:CX bytes of memory
;;;;;;;; DPMIERR <'Unable to allocate DPMI memory.'>
	 DPMIERR @MSG_DPMI12
				; Return with BX:CX = linear address of the block
				;	      SI:DI = memory handle
	 jnc	 short DPMI_ALLOC2 ; Jump if it worked

	 cmp	 edx,DPMI_PS	; Izit already too small?
	 jb	 short DPMI_ALLOC_END ; Jump if so

	 shr	 edx,1		; Halve the request and try again

	 jmp	 short DPMI_ALLOC1 ; Go around again

DPMI_ALLOC2:
	 push	 si		; Save the memory handle
	 push	 di

	 mov	 esi,edx	; Copy size in bytes
	 shr	 esi,16 	; Shift down high-order word
	 mov	 di,dx		; SI:DI = size of block in bytes
	 DPMICALL @DPMI_LOCKLINREG ; Lock the block at BX:CX for SI:DI bytes
;;;;;;;; DPMIERR <'Unable to lock DPMI memory.'>
	 DPMIERR @MSG_DPMI13
	 pop	 esi		; Restore the memory handle to ESI
	 jc	 short DPMI_ALLOC_EXIT ; Jump if something went wrong (note CF=1)

	 push	 @TT_L2P or @TT_DPMI ; Pass flags (DPMI memory needs translation
				; if VDS present)
	 push	 esi		; Pass DPMI handle #
	 push	 edx		; Amount of shadow RAM in bytes
	 push	 bx		; ...at this physical location
	 push	 cx		; ...
	 push	 bx		; ...at this linear location
	 push	 cx		; ...
	 call	 SAVE_XSHADOW	; Append to shadow RAM structures

	 jmp	 DPMI_ALLOC_NEXTBLK ; Go around again

DPMI_ALLOC_END:

; If we allocated some memory at the start,
; unlock it and de-allocate it now

	 mov	 eax,P2L_SIZE	; Get amount of extra memory to allocate in bytes

	 and	 eax,eax	; Any extra memory to allocate?
	 jz	 short DPMI_ALLOC_CLC ; Jump if not

; First unlock the linear addresses

	 mov	 esi,eax	; Copy size in bytes
	 shr	 esi,16 	; Shift down high-order word
	 mov	 di,ax		; SI:DI = size of block in bytes
	 mov	 cx,P2L_ADDR.ELO ; BX:CX ==> linear address
	 mov	 bx,P2L_ADDR.EHI ; ...
	 DPMICALL @DPMI_UNLKLINREG ; Unlock the block at BX:CX for SI:DI bytes
;;;;;;;; DPMIERR <'Unable to unlock DPMI P2L memory.'>
	 DPMIERR @MSG_DPMI14
	 jc	 short DPMI_ALLOC_EXIT ; Jump if something went wrong (note CF=1)

; Now free the memory

	 mov	 di,P2L_HNDL.ELO ; SI:DI ==> memory handle
	 mov	 si,P2L_HNDL.EHI ; ...
	 DPMICALL @DPMI_RELMEM	; Free the memory with handle SI:DI
;;;;;;;; DPMIERR <'Unable to free DPMI P2L memory.'>
	 DPMIERR @MSG_DPMI15
	 jc	 short DPMI_ALLOC_EXIT ; Jump if something went wrong (note CF=1)
DPMI_ALLOC_CLC:
	 clc			; Indicate all went well
DPMI_ALLOC_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_ALLOC endp 		; End DPMI_ALLOC procedure
endif
	 NPPROC  DPMI_FREE -- Unlock and Free All DPMI/VCPI Memory
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Unlock and free all DPMI/VCPI memory

|

	 pushad 		; Save all EGP registers

	 push	 es		; Save register

	 push	 ds		; Setup ES for VDSCALL
	 pop	 es		; ...
	 assume  es:DGROUP	; Tell the assembler about it

; If there are entries in XSHDTAB which have been locked (via VDS),
; unlock them now.

	 mov	 cx,XSHDCNT	; Get # current entries

	 and	 cx,cx		; Is there anything to do?
	 jz	 near ptr DPMI_FREE_COPY ; Jump if not

	 xor	 si,si		; Initialize index into SHDTAB
	 mov	 DDS.DDS_FVEC.FSEL,0 ; Save as segment/selector
DPMI_FREE_NEXT:
	 test	 XSHDTAB[si].SHD_FLAG,@TT_L2P ; Izit to be unlocked?
	 jz	 near ptr DPMI_FREE_LOOP ; Jump if not

	 test	 GLB_FLAG,@GLB_VDS ; VDS server present?
	 jz	 short DPMI_FREE_XVDS ; Jump if not

	 mov	 eax,XSHDTAB[si].SHD_OLBASE ; Get the original linear base address
	 mov	 DDS.DDS_FVEC.FOFF,eax ; Save as linear offset

	 mov	 eax,XSHDTAB[si].SHD_ESIZE ; Get the size in bytes
	 mov	 DDS.DDS_SIZE,eax ; Save in struc

; We unlocked it immediately after locking it and getting physical addresses
;;;;;;;  lea	 edi,DDS	; ES:EDI ==> DDS struc
;;;;;;;  xor	 dx,dx		; Clear flags
;;;;;;;  VDSCALL @VDS_UNLK	; Unlock the DMA region
;;;;;;;  jnc	 short DPMI_FREE_XVDS ; Jump if all went well
;;;;;;;
;;;;;;;  int	 03h		; Call our debugger
DPMI_FREE_XVDS:
	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jz	 short DPMI_FREE_LOOP ; Jump if not

; Unlock the DPMI memory and free it

	 REGSAVE <cx,si>	; Save as we need it below

	 mov	 eax,XSHDTAB[si].SHD_OLBASE ; Get the linear address
	 mov	 ebx,eax	; Copy size in bytes
	 shr	 ebx,16 	; Shift down high-order word
	 mov	 cx,ax		; BX:CX = linear address

	 mov	 eax,XSHDTAB[si].SHD_ESIZE ; Get the size in bytes
	 mov	 esi,eax	; Copy size in bytes
	 shr	 esi,16 	; Shift down high-order word
	 mov	 di,ax		; SI:DI = size of block in bytes
	 DPMICALL @DPMI_UNLKLINREG ; Unlock the block at BX:CX for SI:DI bytes
;;;;;;;; DPMIERR <'Unable to unlock DPMI memory.'>
	 DPMIERR @MSG_DPMI16
	 REGREST <si,cx>	; Restore
;;;;;;;; jc	 short DPMI_FREE_EXIT ; Jump if something went wrong (note CF=1)
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger
@@:

; Now free the memory

	 mov	 eax,XSHDTAB[si].SHD_HNDL ; Get the memory handle

	 cmp	 eax,-1 	; Izit valid?
	 je	 short @F	; Jump if not

	 push	 esi		; Save as we need it below

	 mov	 esi,eax	; Copy size in bytes
	 shr	 esi,16 	; Shift down high-order word
	 mov	 di,ax		; SI:DI = memory handle
	 DPMICALL @DPMI_RELMEM	; Free the memory with handle SI:DI
;;;;;;;; DPMIERR <'Unable to free DPMI memory.'>
	 DPMIERR @MSG_DPMI17
	 pop	 esi		; Restore
;;;;;;;; jc	 short DPMI_FREE_EXIT ; Jump if something went wrong (note CF=1)
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger
@@:
DPMI_FREE_LOOP:
	 add	 si,size SHD_STR ; Skip to the next entry

;;;;;;;; loop	 DPMI_FREE_NEXT ; Jump if more entries to check

	 dec	 cx		; Account for one fewer
	 jnz	 near ptr DPMI_FREE_NEXT ; Jump if more entries to check
DPMI_FREE_COPY:

; Copy XSHDTAB to SHDTAB so we can start afresh but don't
; copy DPMI-allocated memory as we'll allocated them again.

	 mov	 ax,XSHDIND	; Get the index into XSHDTAB
	 sub	 ax,offset DGROUP:XSHDTAB ; Convert to origin-0
	 add	 ax,offset DGROUP:SHDTAB ; Convert to origin-SHDTAB
	 mov	 SHDIND,ax	; Restore

	 mov	 cx,XSHDCNT	; Get the original count
	 mov	 SHDCNT,cx	; Restore

	 lea	 si,XSHDTAB	; DS:SI ==> source
	 lea	 di,SHDTAB	; ES:DI ==> destin
DPMI_FREE_COPY1:
	 test	 DGROUP:[si].SHD_FLAG,@TT_DPMI ; Izit DPMI-allocated?
	 jnz	 short DPMI_FREE_COPY2 ; Jump if so

	 push	 cx		; Save entry count

	 mov	 cx,type SHD_STR ; Get # bytes to copy
S16  rep movs	 <SHDTAB[di].LO,XSHDTAB[si].LO> ; Copy to old table

	 pop	 cx		; Restore entry count

	 jmp	 short DPMI_FREE_COPY3 ; Join common code

DPMI_FREE_COPY2:
	 dec	 SHDCNT 	; Count it out
	 sub	 SHDIND,type SHD_STR ; ...

; Delete from XSHDTAB as well by copying the tail down over the
; entry-to-be-deleted.

	 REGSAVE <cx,si,di>	; Save for a moment

	 mov	 di,si		; ES:DI ==> destin
	 lea	 si,DGROUP:[si+(type SHD_STR)] ; DS:SI ==> source
	 mov	 cx,XSHDIND	; Get next available index
	 sub	 cx,si		; Less source to get length in bytes
S16  rep movs	 <SHDTAB[di].LO,SHDTAB[si].LO> ; Delete the entry

	 REGREST <di,si,cx>	; Restore

	 dec	 XSHDCNT	; Count it out
	 sub	 XSHDIND,type SHD_STR ; ...
DPMI_FREE_COPY3:
	 loop	 DPMI_FREE_COPY1 ; Jump if more entries to copy
DPMI_FREE_EXIT:
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_FREE endp			; End DPMI_FREE procedure
	 NPPROC  DPMI_RESET -- Reset MAX/Windows Flags
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Reset MAX/Windows flags

|

	 pushad 		; Save all EGP registers

	 cmp	 MAXDEV_FVEC.FSEL,0 ; Izit valid?
	 je	 short DPMI_RESET_EXIT ; Jump if not

	 mov	 ebx,VMHANDLE	; Get the VM handle

	 mov	 ax,VMAX_GetTimeSliceInfo ; Code to get time slice info
	 call	 MAXDEV_FVEC	; Request MAX device services
	 jc	 short DPMI_RESET_EXIT ; Jump if not successful
				; Returns  EAX = % of CPU time	     (O)
				;	   ECX = Foreground priority (I/O)
				;	   EDX = Background priority (I/O)
				;	   ESI = CB_VM_Status flags  (I/O)
	 mov	 eax,CB_VM_FLAGS ; Get original flags
	 and	 eax,VMStat_Exclusive ; Isolate the exclusive bit
	 and	 esi,not VMStat_Exclusive ; Clear it
	 or	 esi,eax	; Set to previous state

	 mov	 ax,VMAX_SetTimeSliceInfo ; Code to set time slice info
	 call	 MAXDEV_FVEC	; Request MAX device services
;;;;;;;; jc	 short ???	; Ignore error return
DPMI_RESET_EXIT:
	 popad			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_RESET endp 		; End DPMI_RESET procedure
	 NPPROC  VMINT23 -- VM Ctrl-Brk Termination Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VM Ctrl-Break termination interrupt handler.

Note the action and otherwise ignore it.

|

	 push	 ds		; Save for a moment

	 mov	 ds,DATASEG	; Get segment of DGROUP
	 assume  ds:DGROUP	; Tell the assembler about it

	 call	 CLEAR_CONT	; Mark as no longer continuous
	 or	 CNT_FLAG,@CNT_HALT ; Mark as interrupted

	 mov	 bx,ZAPOFF	; Get offset of repeat prefix to zap

	 and	 bx,bx		; Izit valid?
	 jz	 short @F	; Jump if not

	 mov	 ds,CODESEG	; Get PGROUP code segment
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 PGROUP:[bx].LO,@OPCOD_NOP ; Zap it to stop REP instruction
@@:
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMINT23  endp			; End VMINT23 procedure
	 FPPROC  PMINT23 -- PM Ctrl-Brk Termination Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PM Ctrl-Break termination interrupt handler.

Note the action and otherwise ignore it.

|

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 call	 PMHALT 	; Mark as halting

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PMINT23  endp			; End PMINT23 procedure
	 NPPROC  PMHALT -- PM Routine To Halt Testing
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PM routine to halt testing

|

	 call	 CLEAR_CONT	; Mark as no longer continuous
	 or	 CNT_FLAG,@CNT_HALT ; Mark as interrupted

	 call	 PMZAP		; Zap repeat prefix if appropriate

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PMHALT	 endp			; End PMHALT procedure
	 NPPROC  PMZAP -- PM Routine To Zap Repeat Prefix
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PM routine to zap repeat prefix if appropriate

|

	 REGSAVE <bx>		; Save register

	 mov	 bx,ZAPOFF	; Get offset of repeat prefix to zap

	 and	 bx,bx		; Izit valid?
	 jz	 short PMZAP_EXIT ; Jump if not

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_ALIAS	; Get PGROUP data segment
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 PGROUP:[bx].LO,@OPCOD_NOP ; Zap it to stop REP instruction

	 pop	 ds		; Restore
	 assume  ds:DGROUP	; Tell the assembler about it
PMZAP_EXIT:
	 REGREST <bx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PMZAP	 endp			; End PMZAP procedure
	 FPPROC  PMINT02 -- PM Parity Error Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PM parity error interrupt handler.

|

	 call	 INT02_COM	; Call common subroutine

	 iretd			; Return to caller
				; Note that this IRETD allows another NMI

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PMINT02  endp			; End PMINT02 procedure
	 FPPROC  PMEXC02 -- PM Parity Error Exception Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PM parity error exception handler.

|

	 call	 INT02_COM	; Call common subroutine

	 RETFD			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PMEXC02  endp			; End PMEXC02 procedure
	 NPPROC  INT02_COM -- Common Subroutine to NMI Handlers
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common subroutine to NMI handlers.

On entry:

EDI	 =	 linear address of NMI (we hope)

|

	 REGSAVE <ds,gs>	; Save for a moment

	 mov	 ds,SEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 gs,SEL_4GB	; Get AGROUP data selector
	 assume  gs:AGROUP	; Tell the assembler about it

; Install our debouncing NMI handler into the IDT

	 call	 SWAP_NMI	; Swap NMI handlers

	 call	 ENABLE_NMI	; Enable NMI, clear the parity latches

	 mov	 NMIADDR,edi	; Save as NMI address

; Check EDI for range within allocated memory.	If found, use it
; directly.  If not, it's a spurious NMI perhaps within
; conventional memory.

	 REGSAVE <eax,cx,si>	; Save registers

	 mov	 cx,TIMECNT	; Get # entries in structure
	 xor	 si,si		; Initialize index into TIMETAB
INT02_COM_NEXT:
	 test	 TIMETAB[si].TT_FLAG,@TT_UNALL ; Izit unallocated?
	 jnz	 short INT02_COM_LOOP ; Jump if so

	 mov	 eax,TIMETAB[si].TT_LBASE ; Get starting linear address

	 cmp	 eax,edi	; Izit within range?
	 ja	 short INT02_COM_LOOP ; Jump if not

	 add	 eax,TIMETAB[si].TT_LEN ; Plus the size in bytes

	 cmp	 edi,eax	; Izit within range?
	 jb	 short INT02_COM_OK ; Jump if so
INT02_COM_LOOP:
	 add	 si,size TT_STR ; Skip to next entry

	 loop	 INT02_COM_NEXT ; Jump if more entries to check

	 mov	 NMIADDR,-1	; No match:  use spurious address
INT02_COM_OK:
	 REGREST <si,cx,eax>	; Restore

	 or	 CNT_FLAG,@CNT_NMI ; Mark as NMI has occurred

	 call	 PMZAP		; Zap repeat prefix if appropriate

	 call	 SWAP_NMI	; Swap NMI handlers

	 REGREST <gs,ds>	; Restore
	 assume  ds:nothing,gs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT02_COM endp			; End INT02_COM procedure
	 NPPROC  SWAP_NMI -- Swap NMI Handlers
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:AGROUP,ss:nothing
COMMENT|

Swap NMI handlers

|

	 REGSAVE <eax,ebx>	; Save registers

; Establish addressibility to IDT

IDT	 equ	 <AGROUP:[ebx+02h*(type IDT_STR)]>

	 sub	 esp,size DTR_STR ; Make room on stack
	 SIDTD	 [esp].EDF	; Save IDTR on stack
	 mov	 ebx,[esp].DTR_BASE ; ES:EBX ==> IDT
	 add	 esp,size DTR_STR ; Strip from the stack

; Swap our debouncing INT 02h TSS with the current one

	 mov	 eax,DEBOUNCE_FVEC.FOFF ; Get our offset

	 and	 eax,eax	; Izit valid?
	 jz	 short SWAP_NMI_EXIT ; Jump if not

	 xchg	 ax,IDT.IDT_OFFLO ; Swap with IDT
	 mov	 DEBOUNCE_FVEC.FOFF.ELO,ax ; Save to restore later
	 shr	 eax,16 	; Shift to low-order
	 xchg	 ax,IDT.IDT_OFFHI ; Swap with IDT
	 mov	 DEBOUNCE_FVEC.FOFF.EHI,ax ; Save to restore later

	 mov	 ax,DEBOUNCE_FVEC.FSEL ; Get our selector
	 xchg	 ax,IDT.IDT_SELECT ; Swap with IDT
	 mov	 DEBOUNCE_FVEC.FSEL,ax ; Save to restore later

	 mov	 al,DEBOUNCE_ARB ; Get our access rights byte
	 xchg	 al,IDT.IDT_ACCESS ; Swap with IDT
	 mov	 DEBOUNCE_ARB,al ; Save to restore later
SWAP_NMI_EXIT:
	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SWAP_NMI endp			; End SWAP_NMI procedure
	 FPPROC  DEBOUNCE -- Debouncing NMI Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Debouncing NMI handler

|

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEBOUNCE endp			; End DEBOUNCE procedure
	 FPPROC  PMINT08 -- PM Hardware Timer Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PM hardware timer interrupt handler.

|

	 push	 ds		; Save register

	 mov	 ds,SEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

; Call INT 08h handler and then check the keyboard buffer

	 pushfd 		; Pass EFL
	 call	 PMINT08_FVEC	; Call interrupt handler

	 call	 INT08_COM	; Call common subroutine
	 assume  ds:DGROUP	; Tell the assembler about it

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PMINT08  endp			; End PMINT08 procedure
	 FPPROC  PMINT09 -- PM Hardware Keyboard Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

PM hardware keyboard interrupt handler.

|

	 push	 ds		; Save register

	 mov	 ds,SEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

; Call INT 09h handler and then check the keyboard buffer

	 pushfd 		; Pass EFL
	 call	 PMINT09_FVEC	; Call interrupt handler

	 call	 INT09_COM	; Call common subroutine
	 assume  ds:DGROUP	; Tell the assembler about it

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 iretd			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PMINT09  endp			; End PMINT09 procedure
	 NPPROC  INT08_COM -- Common Subroutine For Hardware Timer Interrupts
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common subroutine for hardware timer interrupts

|

	 mov	 ds,SEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 pushf			; Save flags

	 cld			; String ops fowardly

	 test	 GL2_FLAG,@GL2_ACTIV ; Izit active?
	 jz	 short INT08_COM_XSEC ; Jump if not

	 add	 MEMTIMER.EDQLO,1 ; Count in another tick
	 adc	 MEMTIMER.EDQHI,0 ; In case of overflow

; Count in another tick to decrement ETA time

	 add	 DECTIMER.EDQLO,1 ; Count in another tick
	 adc	 DECTIMER.EDQHI,0 ; In case of overflow

	 inc	 SECTIMER	; Count in another tick

	 cmp	 SECTIMER,18	; Izit near a second as yet?
	 jb	 short INT08_COM_XSEC ; Jump if not

	 mov	 SECTIMER,0	; Clear for next time

	 call	 DISP_ELAP	; Display elapsed time

	 call	 DISP_ETA	; Display estimated time to complete
INT08_COM_XSEC:
	 btr	 CNT_FLAG,$CNT_NEWKEY ; Is a new key available?
	 jnc	 short INT08_COM_EXIT ; Jump if not

	 test	 GL2_FLAG,@GL2_ACTIV ; Izit active?
	 jz	 short INT08_COM_EXIT ; Jump if not

	 bts	 GL3_FLAG,$GL3_RUNHELP ; Are we already in help?
	 jc	 short INT08_COM_EXIT ; Jump if so

; If IRQ1 is in-service, skip this as we don't want to interfere
; with the IRQ1 processing

	 push	 ax		; Save for a moment

	 mov	 al,@GETISR	; Code to request ISR from 8259
	 out	 @ICR,al	; Tell the master PIC about it
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 in	 al,@ICR	; Read the master ISR
	 call	 DRAINPIQ	; Drain the Prefetch Instruction Queue

	 test	 al,mask $IRQ1	; Check for IRQ1 in-service
	 pop	 ax		; Restore
	 jnz	 short @F	; Jump if so

	 call	 CHECK_KEYS	; See if any interesting keys were pressed
;;;;;;;; jne	 short ???	; Jump if we're to halt
@@:
	 and	 GL3_FLAG,not @GL3_RUNHELP ; Clear recursion flag
INT08_COM_EXIT:
	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT08_COM endp			; End INT08_COM procedure
	 NPPROC  INT09_COM -- Common Subroutine For Hardware Keyboard Interrupts
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Common subroutine for hardware keyboard interrupts

On exit:

DS	 =	 DGROUP

|

	 mov	 ds,SEL_DATA	; Get DGROUP data selector
	 assume  ds:DGROUP	; Tell the assembler about it

	 push	 ax		; Save for a moment

	 test	 GL2_FLAG,@GL2_ACTIV ; Izit active?
	 jz	 short INT09_COM_EXIT ; Jump if not

	 call	 CHKNDKEY	; Is there a keystroke available?
				; Return with AX = keystroke, ZF significant
	 jz	 short INT09_COM_EXIT ; Jump if nothing available

	 cmp	 HELP_STATE,@HELP_NONE ; Are we running help?
	 jne	 short INT09_COM_KEY ; Jump if so

	 cmp	 ax,@KEY_HALT	; Izit halt key?
	 jne	 short INT09_COM_KEY ; Jump if not

	 or	 CNT_FLAG,@CNT_KFLUSH ; Flush keystroke from buffer
	 call	 PMHALT 	; Mark as halting

	 jmp	 short INT09_COM_EXIT ; Join common exit code

INT09_COM_KEY:
	 or	 CNT_FLAG,@CNT_NEWKEY ; Mark as new key available
INT09_COM_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT09_COM endp			; End INT09_COM procedure
	 FPPROC  TMPINT67 -- Temporary Int 67h handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Before checking for load module SWAT, we need to catch Int 67h
in case we're running an older version of 386MAX with EMS=0.

|

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TMPINT67 endp			; End TMPINT67
	 NPPROC  CHECK_SWAT -- Check On SWAT
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on SWAT

|

	 pusha			; Save all GP registers
	 REGSAVE <es>		; Save

; If the device name for device 386SWAT is present,
; we can safely make the debugger presence call.

	 lea	 dx,SWTNAME	; Device name for 386SWAT
	 call	 CHECK_DEV	; Does it exist?
	 jc	 short CHECK_SWAT1 ; Jump if so

; If 386MAX is present, it could be an older version (pre-7.01.033)
; with EMS=0, where Int 67h is not hooked at all.  If it's load
; module SWAT, we're hooking it in the IDT anyway.

	 lea	 dx,MAXNAME	; Device name for 386MAX
	 call	 CHECK_DEV	; Does it exist?
	 jnc	 short CHECK_SWAT_EXIT ; Jump if not present

	 mov	 ax,@GETINT*100h + 0067h ; Get current Int 67 vector
	 DOSCALL		; ES:BX ==> vector
	 assume  es:nothing	; Tell the assembler

	 mov	 OLDINT67.VSEG,es ; Save previous handler's vector
	 mov	 OLDINT67.VOFF,bx ; ...

	 push	 ds		; Save

	 push	 cs		; Get PGROUP
	 pop	 ds		; Address for set vector
	 assume  ds:PGROUP	; Tell the assembler

	 lea	 dx,PGROUP:TMPINT67 ; Address our temporary handler
	 mov	 ax,@SETINT*100h + 0067h ; Set Int 67h vector
	 DOSCALL		; Set vector for Int AL to DS:DX

; Determine whether or not load module SWAT is present

	 VCPICALL @VCPI_DPRES	; Izit present?

	 pop	 ds		; Restore
	 assume  ds:DGROUP	; Tell the assembler

	 REGSAVE <ax,ds>	; Save return value in AH

	 lds	 dx,OLDINT67	; DS:DX ==> Previous handler
	 assume  ds:nothing	; Tell the assembler

	 mov	 ax,@SETINT*100h + 0067h ; Set Int 67h vector
	 DOSCALL		; Set vector for Int AL to DS:DX

	 REGREST <ds,ax>	; Restore
	 assume  ds:DGROUP	; Tell the assembler

	 jmp	 short CHECK_SWAT2 ; Join common code

CHECK_SWAT1:

; Determine whether or not a resident debugger is present

	 VCPICALL @VCPI_DPRES	; Izit present?

CHECK_SWAT2:
	 or	 ah,ah		; Check for presence
	 jnz	 short @F	; Jump if not

	 mov	 VCPIDBG_VER,bx ; BH = major, BL = minor
	 or	 GL2_FLAG,@GL2_SWAT ; Mark as present
@@:
CHECK_SWAT_EXIT:
	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler

	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SWAT endp 		; End CHECK_SWAT procedure
	 NPPROC  CHECK_VCPI -- Check On VCPI Host
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on VCPI host

On exit:

CF	 =	 0 if VCPI host is available
	 =	 1 otherwise.

|

	 pushad 		; Save all EGP registers
	 REGSAVE <es>		; Save register

; First, there must be an EMS provider

	 lea	 dx,EMMNAME	; Attempt to open the EMS device
	 call	 CHECK_DEV	; Does it exist?
	 jc	 short CHECK_VCPI1 ; Jump if present

	 lea	 dx,EMMNAM2	; Attempt to open the EMS device
	 call	 CHECK_DEV	; Does it exist?
	 jc	 short CHECK_VCPI1 ; Jump if present

	 lea	 dx,EMMNAM3	; Attempt to open the EMS device
	 call	 CHECK_DEV	; Does it exist?
	 jc	 short CHECK_VCPI1 ; Jump if present

	 lea	 dx,EMMNAM4	; Attempt to open the EMS device
	 call	 CHECK_DEV	; Does it exist?
	 jc	 short CHECK_VCPI1 ; Jump if present

	 lea	 dx,EMMNAM5	; Attempt to open the EMS device
	 call	 CHECK_DEV	; Does it exist?
	 jnc	 short CHECK_VCPI_ERR0 ; Jump if not

; Versions of MAX prior to 7.01.033 did not handle VCPI calls if
; EMS services are not available.  This will only present a problem
; if NODPMI is present.  We'll try to open 386MAX$$; if it's present
; (along with QMMXXXX0, which we just checked for) we need to get
; the PORT67 value for back-door access to VCPI.

	 lea	 dx,MAXNAME	; 386MAX device driver
	 call	 CHECK_DEV	; Does it exist?
	 jnc	 short CHECK_VCPI_ERR0 ; Jump if not - it's another program

	 mov	 al,02h 	; Access code for read/write
	 DOSCALL @OPENF2	; Attempt to open 386MAX device driver
	 jc	 short CHECK_VCPI_ERR0 ; Jump if not present

	 mov	 bx,ax		; Copy to handle register

; From this point we need to exit via CHECK_VCPI_ERRCLOSE
; CHECK_DEV has already ensured that this is an IOCTL device.  Read the
; info structure.

	 mov	 al,02h 	; Read from device
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO
;;;;;;;  jc	 ???		; Ignore error

	 cmp	 INFO.INFO_SIGN.ELO[0],'83' ; Our signature?
	 jne	 short CHECK_VCPI_ERRCLOSE ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[2],'M6' ; Our signature?
	 jne	 short CHECK_VCPI_ERRCLOSE ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[4],'XA' ; Our signature?
	 jne	 short CHECK_VCPI_ERRCLOSE ; Not this time

	 or	 GL3_FLAG,@GL3_BACKVCPI ; Use back door to VCPI services

CHECK_VCPI_ERRCLOSE:
	 DOSCALL @CLOSF2	; Close file handle BX

	 test	 GL3_FLAG,@GL3_BACKVCPI ; Did we succeed?
	 jnz	 short CHECK_VCPI1 ; Jump if so

CHECK_VCPI_ERR0:
	 jmp	 CHECK_VCPI_ERR ; Join common error code

CHECK_VCPI1:

; See if there's a VCPI host present

	 VCPIBACK @VCPI_PRES	; Check on VCPI host
				; Return with AH = 0 if present
				;	 (BH,BL) = version #
	 cmp	 ah,0		; Izit present?
	 jne	 near ptr CHECK_VCPI_ERR ; Jump if not

; Read the master and slave IRQ bases

	 VCPIBACK @VCPI_GIBV	; Return with BX = master base
				; ...	      CX = slave base
	 mov	 IBV0,bl	; Save for later use
	 mov	 IBV1,cl	; ...
	 add	 bl,8		; Calculate top value
	 add	 cl,8		; ...
	 mov	 IBV0Z,bl	; Save for later use
	 mov	 IBV1Z,cl	; ...

; Setup for VCPI calls

	 movzx	 eax,MAPSEG_NXT ; Get next available segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 eax,4*1024-1	; Round up to 4KB in paras
	 and	 eax,not (4*1024-1) ; ...
	 mov	 LaCR3,eax	; Save as linear address of CR3 (/4KB)
	 add	 eax,4*1024	; Skip over CR3
	 mov	 LaPTE,eax	; Save as linear address of PTEs
	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 MAPSEG_NXT,ax	; Protect the CR3

; Get the physical address of the CR3

	 mov	 ecx,LaCR3	; Get linear address of CR3 (/4KB)

	 push	 ecx		; Pass linear address as argument
	 call	 ZERO_PAGE	; Zero the contents of the 4KB page

	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 VCPIBACK @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX
	 and	 dx,mask $PTE_FRM ; Isolate the 4KB frame
	 mov	 PaCR3,edx	; Save for later use

; Setup PMI

	 mov	 eax,LaPTE	; Get linear address of PTEs (/4KB)

	 push	 eax		; Pass linear address as argument
	 call	 ZERO_PAGE	; Zero the contents of the 4KB page

	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 lea	 si,LCLGDT.DTE_PMCS ; DS:SI ==> three DTEs for PMI
	 xor	 di,di		; ES:DI ==> PTEs
	 VCPIBACK @VCPI_GPMI	; Return with EBX=offset, DI=advanced

	 cmp	 ah,0		; Check for error
;;;;;;;; SETMSG  "Unable to read Protected Mode Interface data",ERR
	 jne	 near ptr CHECK_VCPI_ERR ; Jump if not OK

	 mov	 PMI_FVEC.FOFF,ebx ; Save offset of PMI
	 mov	 PMI_FVEC.FSEL,DTE_PMCS ; Save selector of PMI

	 mov	 NEXTPTE.ELO,di ; Save offset of next available PTE

; Make room for PTEs sufficient for MAXSIZE + 384KB

	 mov	 eax,MAXSIZE	; Get size of physical memory (including the
				; 1st megabyte)
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 add	 eax,384*1024	; Plus maximum amount of shadow memory we
				; might recover
	 shr	 eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	 add	 eax,NEXTPTE	; Skip over existing PTEs

ifdef @BETA

; If SWAT is present, reserve space for it

	 test	 GL2_FLAG,@GL2_SWAT ; Is SWAT present?
	 jz	 short @F	; Jump if not

	 mov	 ecx,eax	; Copy as maximum size of PTEs
	 shl	 ecx,(12-2)-0	; Convert from 4KB in dwords to bytes
	 mov	 LaSWAT,ecx	; Save as new linear address
	 add	 ecx,4*1024*1024 ; Reserve 4MB for it (we don't know how
				; big it is until much later)
	 shr	 ecx,(12-2)-0	; Convert from bytes to 4KB in dwords
	 mov	 eax,ecx	; Copy as next PTE offset
@@:
endif				; IFDEF @BETA

; This is the next available offset in bytes after all PTEs

	 mov	 ecx,eax	; Copy as maximum size of PTEs
	 add	 eax,16-1	; Round up to next para
	 shr	 eax,4-0	; Convert from bytes to paras
	 add	 MAPSEG_NXT,ax	; Protect the memory

; Calculate the # PDIRs

	 add	 ecx,4*1024-1	; Round up to 4KB bonudary
	 shr	 ecx,12-0	; Convert from bytes to 4KB (# PDIRs)

; Fill in the PDIRs

	 mov	 eax,LaCR3	; Get linear address of CR3 (/4KB)
	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> PDEs

	 mov	 ebx,LaPTE	; Get its linear address (/4KB)
	 shr	 ebx,12-0	; Convert from bytes to 4KB
	 push	 ecx		; Save for a moment
CHECK_VCPI_NEXT:
	 push	 ecx		; Save for a moment

	 mov	 ecx,ebx	; Copy linear address in 4KB
	 VCPIBACK @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX

	 pop	 ecx		; Restore

	 mov	 eax,edx	; Copy to output register
	 and	 ax,mask $PTE_FRM ; Isolate the 4KB frame
	 or	 eax,@PTE_URP	; Mark as User/Read-Write/Present
	 stos	 es:[di].EDD	; Save as next PDE

	 inc	 ebx		; Skip to next PDE

	 loop	 CHECK_VCPI_NEXT ; Jump if more PDIRs to fill in

	 pop	 ecx		; Restore

; Zero the second and subsequent PDIRs

	 dec	 ecx		; Less the first PDIR (already filled in)
	 jz	 short CHECK_VCPI_DONE ; Jump if there's only one

	 mov	 eax,LaPTE	; Get its linear address (/4KB)
	 add	 eax,4*1024	; Skip over the first PDIR
@@:
	 push	 eax		; Pass linear address as argument
	 call	 ZERO_PAGE	; Zero the contents of the 4KB page

	 add	 eax,4*1024	; Skip to the next PDIR

	 loop	 @B		; Jump if more PDIRs to zero
CHECK_VCPI_DONE:
	 or	 GL2_FLAG,@GL2_VCPI ; Mark as using VCPI services to enter PM

	 jmp	 short CHECK_VCPI_EXIT ; Join common exit code

CHECK_VCPI_ERR:
	 stc			; Indicate something went wrong
CHECK_VCPI_EXIT:
	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VCPI endp 		; End CHECK_VCPI procedure
	 NPPROC  ZERO_PAGE -- Zero A 4KB Page
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Zero a 4KB page

|

ZP_STR	 struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
ZP_LA	 dd	 ?		; Linear address of page to zero

ZP_STR	 ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,cx,di,es> ; Save registers

	 mov	 eax,[bp].ZP_LA ; Get the linear address
	 shr	 eax,4-0	; Convert from bytes to paras

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> 4KB page to zero
	 xor	 eax,eax	; Set to this value
	 mov	 cx,(4*1024)/4	; # dwords in a 4KB page
     rep stos	 es:[di].EDD	; Zero the 4KB page

	 REGREST <es,di,cx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ZERO_PAGE endp			; End ZERO_PAGE procedure
	NPPROC	RMPAGE -- Setup Real Mode Page Tables
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup real mode pages tables

|

	pushad			; Save all EGP registers
	REGSAVE <es>		; Save register

; Setup for RM calls

	movzx	eax,MAPSEG_NXT	; Get next available segment
	shl	eax,4-0 	; Convert from paras to bytes
	add	eax,4*1024-1	; Round up to 4KB in paras
	and	eax,not (4*1024-1) ; ...
	mov	LaCR3,eax	; Save as linear address of CR3 (/4KB)
	add	eax,4*1024	; Skip over CR3
	mov	LaPTE,eax	; Save as linear address of PTEs
	shr	eax,4-0 	; Convert from bytes to paras
	mov	MAPSEG_NXT,ax	; Protect the CR3

; Get the physical address of the CR3

	mov	ecx,LaCR3	; Get linear address of CR3 (/4KB)

	push	ecx		; Pass linear address as argument
	call	ZERO_PAGE	; Zero the contents of the 4KB page

	mov	PaCR3,ecx	; Save for later use

; Setup PMI

	mov	eax,LaPTE	; Get linear address of PTEs (/4KB)

	push	eax		; Pass linear address as argument
	call	ZERO_PAGE	; Zero the contents of the 4KB page

	shr	eax,4-0 	; Convert from bytes to paras
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	mov	eax,@PTE_URP	; Initial PTE
	mov	cx,1024/4	; # PTEs in 1MB
	xor	di,di		; ES:DI ==> PTEs
@@:
	stos	es:[di].EDD	; Save in PTE table
	add	eax,CON4K	; Skip to next PTE
	loop	@B		; Jump if more PTEs to fill in

	mov	NEXTPTE.ELO,di	; Save offset of next available PTE

; Make room for PTEs sufficient for MAXSIZE + 384KB

	mov	eax,MAXSIZE	; Get size of physical memory (including the
				; 1st megabyte)
	shl	eax,10-0	; Convert from 1KB to bytes
	add	eax,384*1024	; Plus maximum amount of shadow memory we
				; might recover
	shr	eax,(12-2)-0	; Convert from bytes to 4KB in dwords
	add	eax,NEXTPTE	; Skip over existing PTEs

ifdef @BETA

; If SWAT is present, reserve space for it

	test	GL2_FLAG,@GL2_SWAT ; Is SWAT present?
	jz	short @F	; Jump if not

	mov	ecx,eax 	; Copy as maximum size of PTEs
	shl	ecx,(12-2)-0	; Convert from 4KB in dwords to bytes
	mov	LaSWAT,ecx	; Save as new linear address
	add	ecx,4*1024*1024 ; Reserve 4MB for it (we don't know how
				; big it is until much later)
	shr	ecx,(12-2)-0	; Convert from bytes to 4KB in dwords
	mov	eax,ecx 	; Copy as next PTE offset
@@:
endif				; IFDEF @BETA

; This is the next available offset in bytes after all PTEs

	mov	ecx,eax 	; Copy as maximum size of PTEs
	add	eax,16-1	; Round up to next para
	shr	eax,4-0 	; Convert from bytes to paras
	add	MAPSEG_NXT,ax	; Protect the memory

; Calculate the # PDIRs

	add	ecx,4*1024-1	; Round up to 4KB bonudary
	shr	ecx,12-0	; Convert from bytes to 4KB (# PDIRs)

; Fill in the PDIRs

	mov	eax,LaCR3	; Get linear address of CR3 (/4KB)
	shr	eax,4-0 	; Convert from bytes to paras
	mov	es,ax		; Address it
	assume	es:nothing	; Tell the assembler about it

	xor	di,di		; ES:DI ==> PDEs

	mov	ebx,LaPTE	; Get its linear address (/4KB)
	shr	ebx,12-0	; Convert from bytes to 4KB
	push	ecx		; Save for a moment
RMPAGE_NEXT:
	mov	eax,ebx 	; Copy linear address in 4KB
	shl	eax,12-0	; Convert from 4KB to bytes
	and	ax,mask $PTE_FRM ; Isolate the 4KB frame
	or	eax,@PTE_URP	; Mark as User/Read-Write/Present
	stos	es:[di].EDD	; Save as next PDE

	inc	ebx		; Skip to next PDE

	loop	RMPAGE_NEXT	; Jump if more PDIRs to fill in

	pop	ecx		; Restore

; Zero the second and subsequent PDIRs

	dec	ecx		; Less the first PDIR (already filled in)
	jz	short RMPAGE_DONE ; Jump if there's only one

	mov	eax,LaPTE	; Get its linear address (/4KB)
	add	eax,4*1024	; Skip over the first PDIR
@@:
	push	eax		; Pass linear address as argument
	call	ZERO_PAGE	; Zero the contents of the 4KB page

	add	eax,4*1024	; Skip to the next PDIR

	loop	@B		; Jump if more PDIRs to zero
RMPAGE_DONE:
	REGREST <es>		; Restore
	assume	es:nothing	; Tell the assembler about it
	popad			; Restore all EGP registers

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RMPAGE	endp			; End RMPAGE procedure

CODE	ends			; End CODE segment

	MEND			; End MEM_EPM module
