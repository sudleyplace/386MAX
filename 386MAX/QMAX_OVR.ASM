;' $Header:   P:/PVCS/MAX/386MAX/QMAX_OVR.ASV   1.6   30 May 1997 10:45:50   BOB  $
	 title	 QMAX_OVR -- 386MAX High DOS Resident Routines
	 page	 58,122
	 name	 QMAX_OVR

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Program segment HICODE,	dword-aligned, public, class 'prog'
	       Program segment ZCODE,	para-aligned,  public, class 'zcode'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

ARG_STR  struc

ARG_BP	 dw	 ?		; Caller's BP
ARG_CSIP dd	 ?		; Caller's return address
ARG_FLG  dw	 ?		; Caller's flags

ARG_STR  ends

.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include EMMCALL.INC
	 include EMM2CALL.INC
	 include CPUFLAGS.INC
	 include BITFLAGS.INC
	 include BIOSDATA.INC
	 include CPUID.INC
	 include DEVDRV.INC
	 include 8255.INC
	 include 8259.INC
	 include 386.INC
	 include PTR.INC
	 include INTVEC.INC
	 include MASM5.MAC
	 include OPCODES.INC
	 include WIN3PAGE.INC
	 include DPMI.INC
	 include MAC.INC
	include PNP.INC
	include OPEN.INC
	include ASCII.INC

	 include LOAD_SEG.INC
	 include QMAX_CTL.INC
	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
	 include QMAX_VCP.INC
	 include QMAXDPMI.INC
	 include QMAXWIN3.INC
.list

PGROUP	 group	 CODE,HICODE,ZCODE
PDTGRP	 group	 PDTSEG


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 STATE_PM:near
	 extrn	 GATEA20:near
	 extrn	 SEND_CHIPSET:near
	 extrn	 ACTA20_COM:near

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

if @OEM_HIFILL
	 extrn	 QMAX_VER:byte
	 include QMAX_HDM.INC
endif				; IF @OEM_HIFILL

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 MSC_FLAG:word
	 include QMAX_MSC.INC

	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC

	 extrn	 DEVDRV:tbyte

	 extrn	 INFO_CTL:byte
	 extrn	 INFO:tbyte
	 include QMAXINFO.INC

	 extrn	 OFFSIZE:word
	 extrn	 EXTSIZE:dword
	 extrn	 PORT67:word
	 extrn	 OLDINT21_VEC:dword
if @OEM_WIN3
	 extrn	 LOWWIN3_CB:byte
endif				; IF @OEM_WIN3
	 extrn	 PLOWSTKZ:word
	 extrn	 LOWSTKZ:word
	 extrn	 STKPTR:dword

	 extrn	 SAVE_AH:byte

	 extrn	 AT386_CFG:byte
	 extrn	 AT386_RAB:byte
	 extrn	 AT386_RCD:byte
	 extrn	 AT386_REF:byte

	 extrn	 CT_ROMCFG:byte
	 extrn	 CT_RAM_AB:byte
	 extrn	 CT_RAM_CD:byte
	 extrn	 CT_RAM_EF:byte

if @OEM_WIN3
	extrn	LO_WINVXD_VEC:dword
	extrn	VIRT_DEV_DPFE:byte
endif				; IF @OEM_WIN3

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 public  @QMAX_OVR_HICODE
@QMAX_OVR_HICODE:		; Mark module start in .MAP file

	 public  PRESINT_XMS
PRESINT_XMS dd	 PGROUP:RESINT_XMS ; Address of low DOS memory handler

ife @OEM_HIFILL or @OEM_WIN3
	 public  OLDINT40_VEC
OLDINT40_VEC dd  ?		; Save area for old INT 40h interrupt handler
endif				; IFE @OEM_HIFILL or @OEM_WIN3

	 public  XBIOS_SRC
XBIOS_SRC dd	 0		; XBIOS source pointer

if @OEM_XMS
	 public  EX2SIZE
EX2SIZE  dd	 0		; Extended memory size before XMS INT 15h installed
				; (can be used as dword)
endif				; IF @OEM_XMS

	 public  I15_FLAG
	 include QMAX_I15.INC
I15_FLAG dw	 0		; Flags for INT 15h block move

	 public  INTA01,INTB01
INTA01	 db	 ?		; Save area for master IMR
INTB01	 db	 ?		; ...		slave

	 public  RH_VEC
RH_VEC	 dd	 ?		; Request header vector

if @OEM_XMS
	 public  XMS_FLAG
	 include QMAX_XMS.INC
XMS_FLAG dw	 0		; XMS flags
endif				; IF @OEM_XMS

if @OEM_WIN3
	 public  EMM_Import_Ptr,WIN3_VERSION
WIN3_VERSION dw  ?		; Windows 3 version #
EMM_Import_Ptr dd ?		; Physical address of EMM Import data

	public	HI_WINVXD_VEC,HI_PGET_WINVXD_VEC
HI_WINVXD_VEC dd ?		; Pointer to Windows VxD API Entry Point
HI_PGET_WINVXD_VEC dd PGROUP:GET_WINVXD_VEC ; Pointer to GET_WINVXD_VEC

	 public  IIS_MAX
IIS_MAX  INSTANCE_ITEM_STR <PGROUP:HDM_FLAG,1> ; Instance data for HDM_FLAG
	 dd	 0		; With list terminator
endif				; IF @OEM_WIN3

	 public  SBIOSDATA
SBIOSDATA dw	 seg BIOSDATA	; Segment of BIOS data area

	 public  I13CNT
I13CNT	 dw	 0		; Count of active INT 13h calls

	 public  EXITRCHI
EXITRCHI dw	 (@GETRC_RES shl 8) or 0 ; Default return code

	public	MSG_VXDGONE
MSG_VXDGONE db	@OEM_TEXT,' VxD not found',CR,LF,EOS

HICODE	 ends			; End HICODE segment

; The linker will position ZCODE after HICODE per
; the order specified in QMAX.ASM.  We can put
; some code and/or data after EMPTY_HIMAC to take advantage
; of paragraph alignment.  This also lets us lop off part
; of WARMBOOT_SUB on non-Inboard/AT systems.

ZCODE	 segment use16 para public 'zcode' ; Start ZCODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 public  EMPTY_HIMAC
EMPTY_HIMAC db	 @MAC_END	; Bogus owned ending MAC entry
	 dw	 @MAC_UMB,1	; Make it look like a UMB with length of 1

;----------- Data used in this module only can go here
;----------- to take advantage of paragraph alignment.

	 public  LCL_EFL
LCL_EFL  dw	 ?		; Save area for local flags

	 FPPROC  RESINT06 -- Resident Invalid Opcode Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

To catch a spurious invalid opcode interrupt during reboot,
we need a handler which simply IRETs to the failing instruction.
The invalid opcode error is due to the far jump being within 16
bytes of the end of the segment and the next page isn't cached.

|

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT06 endp			; End RESINT06 procedure

	 NPPROC  WARMBOOT_SUB -- Subroutine to WARMBOOT
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Handle special warm boot circumstances.

As we're rebooting the system, there's no need to
preserve any registers.

|

; If we've relocated the XBIOS, put it back in case someone
; is depending upon it.  In fact, the IBM PS/2 Model 90/95
; does to tell it the state of the last boot.  Without this code,
; you can't call up the reference diskette on the hard disk
; via Ctrl-Alt-Ins at boot time.

; Note that while we could recover the code between here and
; WARMBOOT_NOXBIOS as well, it could vary depending on whether
; NOXBIOS is in the profile.  An Inboard/AT is always an Inboard/AT...

	 test	 I15_FLAG,@I15_XBREL ; Izit present and relocated?
	 jz	 short WARMBOOT_NOXBIOS ; Jump if not

	 mov	 ds,SBIOSDATA	; Get BIOS data segment
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 mov	 ax,XBIOS_SRC.VSEG ; Get segment of original XBIOS

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xchg	 ax,XBDA_SEG	; Swap 'em (restore old, AX = new)

	 mov	 ds,ax		; Address segment of current XBIOS
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; DS:SI ==> relocated XBIOS source
	 xor	 di,di		; ES:DI ==> original ...

	 movzx	 cx,ds:[0].LO	; Get size of XBIOS in 1KB
	 shl	 cx,10-2	; Convert from 1KB to dwords

	 cld			; String ops forwardly
     rep movsd			; Copy back to where it used to be

	 assume  ds:nothing,es:nothing ; Tell the assembler about it

WARMBOOT_NOXBIOS:
	 test	 SYS_FLAG,@SYS_INBRDAT ; Izit an Inboard/AT?
	 jnz	 short @F	; Jump if so

	 ret			; Return to caller

	 public  ZLOCODE_XINB
ZLOCODE_XINB label byte 	; End high DOS for non-Inboard systems

@@:
	 mov	 al,@EOI1	; Get specific EOI for IRQ1
	 out	 @ICR,al	; Ensure it's clear so GATEA20 won't enter
				; an infinite loop around READ_IRR

	 call	 GATEA20	; Enable address line A20
;;;;;;;; jc	 ???		; Ignore return code

	 mov	 al,0		; Value for high speed (80h = slow)
	 mov	 dx,674h	; I/O port for speed
	 out	 dx,al		; Tell the board to run at high speed
	 jmp	 short $+2	; Drain PIQ
	 jmp	 short $+2	; Drain PIQ
	 jmp	 short $+2	; Drain PIQ

	 mov	 al,0		; Value to disable cache (1 = enable)
	 mov	 dx,670h	; I/O port for cache
	 out	 dx,al		; Tell the board to stop caching
	 jmp	 short $+2	; Drain PIQ
	 jmp	 short $+2	; Drain PIQ
	 jmp	 short $+2	; Drain PIQ

; Install Invalid Opcode Handler

	 push	 seg INTVEC	; Prepare to address segment 0
	 pop	 ds		; Address it
	 assume  ds:INTVEC	; Tell the assembler about it

	 mov	 INT00_VEC.VSEG[06h*type INT00_VEC],cs
	 mov	 INT00_VEC.VOFF[06h*type INT00_VEC],offset cs:RESINT06

; Put magic constant into RESET_FLAG

	 mov	 ds,SBIOSDATA	; Get BIOS data segment
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 mov	 RESET_FLAG,1234h ; Set magic constant

; Note $NT already clear

; Pulse 8042 reset line low

	 mov	 al,@S2C_SHUT	; Pulse reset bit low
	 out	 @8042_ST,al	; Tell it to the 8042
	 hlt
	 jmp	 short $	; We're not going anywhere

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WARMBOOT_SUB endp		; End WARMBOOT_SUB procedure
;----------- End paragraph alignment space

	 DPALIGN EMPTY_HIMAC	; Ensure LSEG is paragraph aligned

	 public  ZLOCODE
ZLOCODE  label	 byte

ZCODE	 ends			; End ZCODE segment

HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 FPPROC  DEV_STRA -- Device Strategy Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save ES:BX for later use.

|

.8086
	 mov	 RH_VEC.VSEG,es ; Save segment of request header pointer
	 mov	 RH_VEC.VOFF,bx ; ...  offset
DOT386 p
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_STRA endp			; End DEV_STRA procedure
	 FPPROC  DEV_INTR -- Second And Subsequent Interrupt Requests
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Handle IOCTL and Input/Output status -- all other requests are
treated as unknown commands.

|

	 pusha			; Save all GP registers
	 REGSAVE <ds,es>	; Save segment registers

	 les	 bx,RH_VEC	; Get stored SRH offset & segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,es:[bx].RW_COUNT ; Get move length in bytes
	 mov	 al,es:[bx].SRH_CCD ; Get the function code

	 cmp	 al,03h 	; IOCTL read from device call (4402)?
	 je	 short DEV_INTR_INP ; Yes, handle separately

	 cmp	 al,0Ch 	; IOCTL write into device call (4403)?
	 je	 short DEV_INTR_OUT ; Yes, handle separately

	 cmp	 al,06h 	; Input status call?
	 je	 near ptr DEV_INTR_STAT ; Yes, handle separately

	 cmp	 al,0Ah 	; Output status call?
	 je	 near ptr DEV_INTR_STAT ; Yes, handle separately
DEV_INTR_ERR:
	 les	 bx,RH_VEC	; Get stored SRH offset & segment
	 assume  es:nothing	; Tell the assembler about it

	 STATUS  DONE,ERROR,ERR_UNK_CMD ; Mark as unknown command

	 jmp	 DEV_INTR_EXIT	; Join common exit code

DEV_INTR_OFF:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

	 call	 STATE_OFF	; Change state to OFF

	 mov	 al,INFO_CTL	; Get error code
	 mov	 ds:[si],al	; Put back into user's area

	 cmp	 al,0		; Check for error
	 jne	 short DEV_INTR_ERR ; Mark as in error

	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 and	 GLB_FLAG,not @GLB_ON ; Mark as not ON

	 jmp	 DEV_INTR_STAT	; Join common status code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

DEV_INTR_ON:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

	 call	 STATE_PM	; Change state to Protected Mode

	 mov	 al,INFO_CTL	; Get error code
	 mov	 ds:[si],al	; Put back into user's area

	 cmp	 al,0		; Check for error
	 jne	 short DEV_INTR_ERR ; Mark as in error

	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 or	 GLB_FLAG,@GLB_ON ; Mark as ON

	 jmp	 short DEV_INTR_STAT ; Join common status code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

DEV_INTR_INP:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 les	 di,es:[bx].RW_DTA_VEC ; ES:DI ==> user's buffer
	 assume  es:nothing	; Tell the assembler about it

	 push	 cs		; Setup for MOVSB
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 lea	 si,INFO	; DS:SI ==> source area

	 cmp	 es:[di].LO,@CTL_XFER ; Izit transfer INFO?
	 jne	 short DEV_INTR_ERR ; Unknown command

	 inc	 di		; Skip over the command byte

	 jmp	 short DEV_INTR_MOVE ; Join common move code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

DEV_INTR_OUT:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

	 lds	 si,es:[bx].RW_DTA_VEC ; DS:SI ==> user's buffer
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 al,ds:[si]	; Get command byte

	 cmp	 al,@CTL_OFF	; Izit state OFF?
	 je	 short DEV_INTR_OFF ; Yes

	 cmp	 al,@CTL_ON	; Izit state ON?
	 je	 short DEV_INTR_ON ; Yes

	 cmp	 al,@CTL_XFER	; Izit INFO transfer?
	 je	 short DEV_INTR_XFER ; Yes

if @OEM_XMS and @OEM_HIFILL
;;;;;;;; cmp	 al,@CTL_LON	; Izit 386LOAD on?
;;;;;;;; je	 short DEV_INTR_LON ; Yes
;;;;;;;;
;;;;;;;; cmp	 al,@CTL_LOFF	; Izit 386LOAD off?
;;;;;;;; je	 short DEV_INTR_LOFF ; Yes
endif				; IF @OEM_XMS and @OEM_HIFILL

	 cmp	 al,@CTL_EMSOFF ; Izit fail all Int 67h calls?
	 je	 short DEV_INTR_EMSOFF ; Yes

	 cmp	 al,@CTL_EMSON	; Izit resume handling Int 67h calls?
	 je	 short DEV_INTR_EMSON ; Yes

	 jmp	 short DEV_INTR_ERR ; Not this time

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

if @OEM_XMS and @OEM_HIFILL
;;;_INTR_LON:
;;;;;;;; EMMOUT  @EMM2_LON	; Tell the PM program about it
;;;;;;;;
;;;;;;;; jmp	 short DEV_INTR_STAT ; Join common status code
;;;;;;;;
;;;;;;;; assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it
endif				; IF @OEM_XMS and @OEM_HIFILL
if @OEM_XMS and @OEM_HIFILL
;;;_INTR_LOFF:
;;;;;;;; EMMOUT  @EMM2_LOFF	; Tell the PM program about it
;;;;;;;;
;;;;;;;; jmp	 short DEV_INTR_STAT ; Join common status code
;;;;;;;;
;;;;;;;; assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it
endif				; IF @OEM_XMS and @OEM_HIFILL

DEV_INTR_EMSOFF:
	 assume  ds:PGROUP	; Tell a white lie
CSOVR	 or	 <I15_FLAG,@I15_FLEXFRAME> ; Fail all Int 67h requests
	 assume  ds:nothing	; Retract nose

	 jmp	 short DEV_INTR_STAT ; Join common status code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

DEV_INTR_EMSON:
	 assume  ds:PGROUP	; Tell a white lie
CSOVR	 and	 <I15_FLAG,not @I15_FLEXFRAME> ; Process Int 67h as before
	 assume  ds:nothing	; Retract nose

	 jmp	 short DEV_INTR_STAT ; Join common status code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

DEV_INTR_XFER:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

	 inc	 si		; Skip over command byte

	 push	 cs		; Setup for MOVSB
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,INFO	; ES:DI ==> destination area

if @OEM_EMS
	 mov	 al,'Q'         ; Assume no EMS or OFF

	 test	 ds:[si].INFO_GLB,@GLB_AUTO or @GLB_ON ; Setting to ON or AUTO state?
	 jz	 short @F	; Not this time

	 test	 ds:[si].INFO_GLB,@GLB_I67 ; Are we managing EMS memory?
	 jz	 short @F	; Not this time

	 mov	 al,'E'         ; Restore device name
@@:
	 mov	 DEVDRV.DD_NAME[0],al ; Set in device driver name
endif				; IF @OEM_EMS
DEV_INTR_MOVE:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

	 cmp	 cx,type INFO_STR ; Use the smaller
	 jbe	 short @F	; Jump if caller's value is smaller

	 mov	 cx,type INFO_STR ; Move no more than we have
@@:
	 cld			; String ops forwardly
S16  rep movsb			; Give data to user

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

DEV_INTR_STAT:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

	 les	 bx,RH_VEC	; Get stored SRH offset & segment
	 assume  es:nothing	; Tell the assembler about it

	 STATUS  DONE,NOERROR	; Set status word (done, no error)
DEV_INTR_EXIT:
	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_INTR endp			; End DEV_INTR procedure
if @OEM_WIN3
	 FPPROC  DEV_INTR3 -- Second And Subsequent Interrupt Requests for WIN3
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Handle IOCTL requests for Windows 3 -- all other requests are
treated as unknown commands.

|

	 REGSAVE <eax,bx,es>	; Save registers

	 les	 bx,RH_VEC	; Get stored SRH offset & segment
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[bx].SRH_CCD,0Ah ; Output status call?
	 je	 short DEV_INTR3_DONE ; Yes, to that's OK

	 cmp	 es:[bx].SRH_CCD,03h ; IOCTL read from device call (4402)?
	 jne	 short DEV_INTR3_ERR ; No, so that's an error

	 les	 bx,es:[bx].RW_DTA_VEC ; ES:DI ==> user's buffer
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[bx].LO,1	; Izit proper function?
	 jne	 short DEV_INTR3_ERR0 ; Jump if not

	 mov	 eax,EMM_Import_Ptr ; Get physical address of EMM Import struc
	 mov	 es:[bx].EMM_Import_Data_Phys_Ptr,eax ; Save in caller's data area

COMMENT|

Note the unusual way in which the V86MMGR Paging Import Spec works
Two IOCTL calls are made.

The first is from WIN.COM.
Windows 3.0 must see a spec 1.00 or enhanced mode will not work.
Windows 3.1 doesn't care about the version at this point.

The second IOCTL is made from the real mode init of the V86MMGR.
It should see a version 1.00 spec for Windows 3.0 and 1.11 spec for Windows 3.1.
The appropriate import spec version is set based on the WIN3_VERSION variable.
WIN3_VERSION is 0 via assembly and is reset to 0 during the re-enable callback
processing.  It is set to the correct Windows version during the 1605h.

Any questions?

|

	 mov	 ax,WIN3_VERSION ; Get version #

	 cmp	 ax,0300h	; Izit Windows 3.00 or earlier?
	 mov	 ax,0100h	; Assume so, use paging import spec 1.00
	 jbe	 short @F	; Jump if so

	 mov	 ax,010Bh	; We're using paging import spec 1.11
@@:
	 mov	 es:[bx].EMM_Import_API_Version_Maj,ah ; Save in struc
	 mov	 es:[bx].EMM_Import_API_Version_Min,al ; ...

	 les	 bx,RH_VEC	; Get stored SRH offset & segment
	 assume  es:nothing	; Tell the assembler about it
DEV_INTR3_DONE:
	 STATUS  DONE,NOERROR	; Set status word (done, no error)

	 jmp	 short DEV_INTR3_EXIT ; Join common exit code

DEV_INTR3_ERR0:
	 les	 bx,RH_VEC	; Get stored SRH offset & segment
	 assume  es:nothing	; Tell the assembler about it
DEV_INTR3_ERR:
	 STATUS  DONE,ERROR,ERR_UNK_CMD ; Mark as unknown command
DEV_INTR3_EXIT:
	 REGREST <es,bx,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_INTR3 endp			; End DEV_INTR3 procedure
endif				; IF @OEM_WIN3
if @OEM_WTK
	 FPPROC  RESINT11 -- Resident Equipment Flags Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Equipment flags interrupt handler.
This handler is installed only if a Weitek coprocessor is
present in the system.	In that case, we set or clear bit 23
depending upon whether or not we're providing access to the
Weitek coprocessor address space at the 1MB wrap.

|


;;;;;;;; OLDINT  11		; Call previous handler
	 pushf			; Pass flags as in INT call
	 cli			; Duplicate INT calling environment
	 db	 @OPCOD_CALLF	; Opcode for far call immediate
	 assume  ds:PGROUP	; Tell the assembler about it
	 public  OLDINT11_VEC
OLDINT11_VEC dd  ?		; Save area for old INT 11h interrupt handler
	 assume  ds:nothing	; Tell the assembler about it

if @OEM_WIN3
	 cmp	 LOWWIN3_CB,2	; Izit under control of Windows' GDT/IDT/CR3?
	 je	 short RESINT11_EXIT ; Yes, continue on
endif				; IF @OEM_WIN3

	 and	 eax,not @BIT23 ; Assume not active

; On the AT&T/Olivetti machines, the system ROM is cached **AND** patched
; in the process to reflect the presence of a Weitek co-processor.
; Because we disable the ROM caching before capturing its contents, we
; cache the unpatched version.	To make a long story short (too late),
; the following instruction ensures that we have the Weitek presence bit
; set in case it was cached out of existence.  Note that this interrupt
; handler is not installed unless we detect a Weitek before we disable
; the system's ROM caching.

	 or	 eax,@BIT24	; Ensure present (otherwise we'd not be called)

	 test	 GLB_FLAG,@GLB_WTK ; Izit active?
	 jz	 short RESINT11_EXIT ; No, so 1167 is not available

	 test	 GLB_FLAG,@GLB_ON ; Are we ON or AUTO active?
	 jz	 short RESINT11_EXIT ; No, so 1167 is not available

	 or	 eax,@BIT23	; Mark as active
RESINT11_EXIT:
	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT11 endp			; End RESINT11 procedure
endif				; IF @OEM_WTK
	 NPPROC  GOVM86_LOW -- Switch Into Real Mode in Low Memory
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Switch into real mode and continue with the interrupted instruction.

|

; Restore caller's segment registers

	 mov	 ds,[bp].INTXX_DS ; Restore segment registers
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 es,[bp].INTXX_ES ; ...
	 assume  es:nothing	; Tell the assembler about it

	 mov	 fs,[bp].INTXX_FS ; Ensure no segment override
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 gs,[bp].INTXX_GS ; Ensure no segment override
	 assume  gs:nothing	; Tell the assembler about it

	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 test	 GLB_FLAG,@GLB_ERR or @GLB_RC ; Error or reason code present?
	 jnz	 short GOVM86_LOW_ERR ; Yes, display message and then reboot
GOVM86_RANGE:

; Are we loaded into high DOS memory or rebooting?

	 test	 LCL_FLAG,@LCL_RBT or @LCL_LODHI ; Check the options
	 jnz	 short SYSREBOOT ; Jump if we should reboot the system

	 push	 LCL_EFL	; Setup caller's flags
	 popf

	 lss	 sp,STKPTR	; Restore caller's stack pointer
	 assume  ss:nothing	; Tell the assembler about it

	 public  FARJMP_VEC
	 assume  ds:PGROUP	; Tell the assembler about it
	 db	 @OPCOD_JMPF	; Far jump to failing CS:IP
FARJMP_VEC dd	 ?
	 assume  ds:nothing	; Tell the assembler about it

SYSREBOOT:
	 call	 WARMBOOT_SUB	; See if there's anything special to do

	 test	 GLB_FLAG,@GLB_ON ; Are we ON or AUTO active?
	 jz	 short @F	; Jump if not

	 EMMOUT  @EMM2_REBOOT	; Reboot the system
@@:
	 jmp	 near ptr WARMBOOT ; Just warm boot the system

GOVM86_LOW_ERR:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

; If error code exit,
;    restore original master and slave interrupt masks,
;    reboot the system.

; Restore original master and slave interrupt masks

	 call	 ENABLE_IMR	; Enable the 8259 interrupt mask register

	 sti			; Enable interrupts

	 test	 GLB_FLAG,@GLB_RC ; Reason code on termination message?
	 jnz	 near ptr GOVM86_RANGE ; Yes, just restart the instruction
GOVM86_REBOOT:
	 cli			; Nobody move
	 xor	 ax,ax		; Mark as valid self-test

	 jmp	 REBOOT 	; Reboot the system

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GOVM86_LOW endp 		; End GOVM86_LOW procedure
	 NPPROC  ENABLE_IMR -- Enable the 8259 Interrupt Mask Register
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable the 8259 interrupt mask register

|

	 REGSAVE <ax>		; Save register

	 mov	 al,INTA01	; Get original master interrupt mask
	 out	 @IMR,al	; Reset in master 8259

	 test	 LCL_FLAG,@LCL_XT ; Running on an XT?
	 jnz	 short ENABLE_IMR_EXIT ; Yes, so there's no slave controller

	 jmp	 short $+2	; Drain PIQ
;;;;;;;; jmp	 short $+2	; Drain PIQ
;;;;;;;; jmp	 short $+2	; Drain PIQ

	 mov	 al,INTB01	; Get original slave interrupt mask
	 out	 @IMR2,al	; Reset in slave 8259
;;;;;;;; jmp	 short $+2	; Drain PIQ
;;;;;;;; jmp	 short $+2	; Drain PIQ
;;;;;;;; jmp	 short $+2	; Drain PIQ
ENABLE_IMR_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ENABLE_IMR endp 		; End ENABLE_IMR procedure
	 FPPROC  RESINT13A -- Resident Disk/Diskette Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

To distinguish CPU physical from bus physical VDS translation calls,
we need to keep track of whether or not we're inside an INT 13h call.

This handler comes from the INT 2Fh/AH=13h/DS:DX return.

|

.8086
	 inc	 I13CNT 	; Count in another one
DOT386 p
	 call	 SET_FLAGS	; Set caller's flags

;;;;;;;; OLDINT  13A		; Call previous handler
	 pushf			; Pass flags as in INT call
	 cli			; Duplicate INT calling environment
	 db	 @OPCOD_CALLF	; Opcode for far call immediate
	 public  OLDINT13A_VEC
	 assume  ds:PGROUP	; Tell the assembler about it
OLDINT13A_VEC dd  ?		; Save area for old INT 13h interrupt handler
	 assume  ds:nothing	; Tell the assembler about it

RESINT13A_EXIT:
.8086
	 pushf			; Save flags
	 dec	 I13CNT 	; Count out another one
	 popf			; Restore flags
DOT386 p
	 retf	 2		; Return to caller, popping flags

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT13A endp			; End RESINT13A procedure
	 FPPROC  RESINT13B -- Resident Disk/Diskette Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

To distinguish CPU physical from bus physical VDS translation calls,
we need to keep track of whether or not we're inside an INT 13h call.

This handler comes from the INT 2Fh/AH=13h/ES:BX return.

|

.8086
	 inc	 I13CNT 	; Count in another one
DOT386 p
	 call	 SET_FLAGS	; Set caller's flags

;;;;;;;; OLDINT  13B		; Call previous handler
	 pushf			; Pass flags as in INT call
	 cli			; Duplicate INT calling environment
	 db	 @OPCOD_CALLF	; Opcode for far call immediate
	 public  OLDINT13B_VEC
	 assume  ds:PGROUP	; Tell the assembler about it
OLDINT13B_VEC dd  ?		; Save area for old INT 13h interrupt handler
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 short RESINT13A_EXIT ; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT13B endp			; End RESINT13B procedure
if @OEM_XMS
	 FPPROC  RESINT2F -- Resident Redirector Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Resident redirector interrupt handler.

Troll for XMS calls 4300h and 4310h
as well as WIN3 call 1605h to disable us
and 1606h to enable us.

We also need to service function 13h if we've hooked the disk vector.
This keeps us at the top of the disk vector chain, but invisible.
Doubtless this will cause problems for some bozo anti-virus programs,
but you can't win 'em all.  Invisibility serves two purposes:

1. It prevents Windows 32-bit disk access from bitching about viruses.
2. It allows Xtradrive to work properly (otherwise it sees we've hooked
   the disk vector after it, and refuses to relocate itself).

|

	 pushf			; Save flags

	 test	 GLB_FLAG,@GLB_ON or @GLB_AUTO ; Are we ON or AUTO?
	 jz	 short RESINT2F_ORIG ; No, continue on

if @OEM_WIN3
	 test	 CM3_FLAG,@CM3_NOWIN3 ; Disabling support for WIN3?
	 jnz	 short @F	; Jump if so

	 cmp	 ax,1605h	; Izit WIN3 begin initialization broadcast?
	 je	 short RESINT2F_WIN3_BEGINIT ; Jump if so

;;;;;;;  cmp	 ax,1606h	; Izit WIN3 end exit broadcast?
;;;;;;;  je	 near ptr RESINT2F_WIN3_ENDEXIT ; Jump if so
;;;;;;;
;;;;;;;; cmp	 ax,1608h	; Izit WIN3 end initialization broadcast?
;;;;;;;; je	 near ptr RESINT2F_WIN3_ENDINIT ; Jump if so
;;;;;;;;
;;;;;;;; cmp	 ax,1609h	; Izit WIN3 begin exit broadcast?
;;;;;;;; je	 near ptr RESINT2F_WIN3_BEGEXIT ; Jump if so
@@:
endif				; IF @OEM_WIN3
if @OEM_DPMI
	 cmp	 ax,@DPMI_GPME ; Izit DPMI presence detection?
	 je	 short RESINT2F_GPME ; Jump if so
endif				; IF @OEM_DPMI
	 cmp	 ah,13h 	; Swap disk vectors?
	 je	 short RESINT2F_SWAPVEC ; Jump if so

	 cmp	 ax,4300h	; Checking on already installed?
	 je	 short RESINT2F_INST ; Yup

	 cmp	 ax,4310h	; Requesting our address?
	 jne	 short RESINT2F_ORIG ; Not this time

	 popf			; Restore flags

	 les	 bx,PRESINT_XMS ; Get address of handler
	 assume  es:nothing	; Tell the assembler about it

	 iret			; Return to caller

RESINT2F_INST:
	 popf			; Restore flags

	 mov	 al,80h 	; Return already-installed flag

	 iret			; Return to caller

	 public  HOOK13,@HOOK13_OFF,@HOOK13_ACTIV,@HOOK13_INACT
HOOK13	 db	 @HOOK13_OFF	; Marks whether or not we've hooked INT 13h
				; via INT 2Fh/AH=13h
@HOOK13_OFF   equ 0		; Not hooked
@HOOK13_ACTIV equ 1		; Hooked and active
@HOOK13_INACT equ 2		; Hooked and inactive (after our VxD's RM init
				; and before next 4B00 with LOWWIN3_CN=0)

RESINT2F_SWAPVEC:
; DS:DX ==> New disk handler
; ES:BX ==> New boot disk handler
; IF=0

	 cmp	 HOOK13,@HOOK13_ACTIV ; Did we hook the disk vector and are active?
	 jne	 short RESINT2F_ORIG ; Jump if not (let DOS handle it)

	 push	 OLDINT13A_VEC.VSEG ; Save old segment
	 push	 OLDINT13B_VEC.VSEG ; ...

.8086
	 xchg	 OLDINT13A_VEC.VOFF,dx ; Set and get offset
	 mov	 OLDINT13A_VEC.VSEG,ds ; Save new segment
	 xchg	 OLDINT13B_VEC.VOFF,bx ; ...
	 mov	 OLDINT13B_VEC.VSEG,es ; ...
DOT386 p

	 pop	 es		; Return segment for previous handler
	 pop	 ds		; ...
	 assume  ds:nothing,es:nothing ; Tell the assembler

	 popf			; Restore flags

	 iret			; Return to caller

RESINT2F_ORIG:
	 popf			; Restore flags

	 db	 @OPCOD_JMPF	; Opcode for far jump immediate
	 public  OLDINT2F_VEC
	 assume  ds:PGROUP	; Tell the assembler about it
OLDINT2F_VEC dd  ?		; Save area for old INT 2Fh interrupt handler
	 assume  ds:nothing	; Tell the assembler about it

if @OEM_DPMI

; Check for DPMI presence

	 public  RESINT2F_GPME
RESINT2F_GPME:
	 test	 GLB_FLAG,@GLB_ON ; Are we ON or AUTO active?
	 jz	 short RESINT2F_ORIG ; Jump if not

	 popf			; Restore flags

	 EMMOUT  @EMM2_DPMIPRES ; Do DPMI presence

	 iret			; Return to caller
endif				; IF @OEM_DPMI

if @OEM_WIN3
COMMENT|

On entry:

ES:BX	 ==	 0:0
DS:SI	 ==	 0:0
DI	 =	 version # (major,minor)
CX	 =	 0
DX	 =	 flags
		 Bit 0 = 1 if Windows 286 DOS extender (standard mode)
		       = 0 if ...     386	       (enhanced mode)

|

	 public  RESINT2F_WIN3_BEGINIT
RESINT2F_WIN3_BEGINIT:		; AX = 1605h
	 popf			; Restore flags

; Due to a bug in our code or in Windows, if our VxD is not present
; (it's been erased), somebody hoses the hard disk.
; Our bandaid fix of the moment is to check for the VxD here and now
; and fail Windows initialization if not found.

	call	FIND_VXD	; Is our VxD file present?
	jc	 short RESINT2F_WIN3_BEGINIT_STD ; Jump if not with CX <> 0

	 OLDINT  2F		; Call previous INT 2Fh handler
	 assume  es:nothing	; Tell the assembler about it
				; Return with ES:BX ==> previous handler's SIS

	 test	 dl,@BIT0	; Izit standard mode?
	 jnz	 short RESINT2F_WIN3_BEGINIT_STD ; Jump if so

	 push	 ax		; Save for a moment

	 mov	 al,0		; Mark as start of ending
RESINT2F_WIN3_BEGINIT1:
	 test	 GLB_FLAG,@GLB_ON ; Are we ON or AUTO active?
	 jnz	 short @F	; Jump if so

	 call	 STATE_PM	; Change state to Protected Mode
@@:
	 EMMOUT  @EMM2_INITWIN3 ; Initialize for Windows

	 pop	 ax		; Restore
RESINT2F_WIN3_BEGINIT_STD:
	 iret			; Return to caller

	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 public  RESINT2F_WIN3_BEGINIT_TAIL
RESINT2F_WIN3_BEGINIT_TAIL:
	 push	 ax		; Save for a moment

	 mov	 al,1		; Mark as end of ending

	 jmp	 RESINT2F_WIN3_BEGINIT1 ; Join common code

;;;
;;;	     public  RESINT2F_WIN3_ENDINIT
;;; RESINT2F_WIN3_ENDINIT:	    ; AX = 1608h
;;;	     push    ds 	    ; Save for a moment
;;;
;;;	     mov     ds,FARCS1	    ; Get segment of low DOS memory
;;;	     assume  ds:PGROUP	    ; Tell the assembler about it
;;;
;;; ; Set flag for OFF from Windows 3 callback in both high and low DOS memory
;;;
;;;	     mov     LOWWIN3_CB,1   ; Mark as OFF from Windows 3 callback
;;; CSOVR    mov     <LOWWIN3_CB,1> ; ...
;;;
;;;	     pop     ds 	    ; Restore
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;;
;;;	     jmp     RESINT2F_ORIG  ; Continue on
;;;
;;;	     assume  ds:nothing,es:nothing ; Tell the assembler about it
;;;
;;;
;;;	     public  RESINT2F_WIN3_BEGEXIT
;;; RESINT2F_WIN3_BEGEXIT:	   ; AX = 1609h
;;;	     jmp     short @F
;;;

COMMENT|
AX	 =	 1606h
DX	 =	 flags
		 Bit 0 = 1 if Windows 286 DOS extender (standard mode)
		       = 0 if ...     386	       (enhanced mode)

|
;;;;;;;      public  RESINT2F_WIN3_ENDEXIT
;;;;;;;RESINT2F_WIN3_ENDEXIT:	   ; AX = 1606h
;;;	     nop
;;; @@:
;;;
;;; ; Set flag for ON from Windows 3 callback in both high and low DOS memory
;;;
;;;	     push    ds 	    ; Save for a moment
;;;
;;;	     mov     ds,FARCS1	    ; Get segment of low DOS memory
;;;	     assume  ds:PGROUP	    ; Tell the assembler about it
;;;
;;;	     mov     LOWWIN3_CB,0   ; Mark as no longer OFF from Windows 3 callback
;;; CSOVR    mov     <LOWWIN3_CB,0> ; ...
;;;
;;;	     pop     ds 	    ; Restore
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;;
endif				; IF @OEM_WIN3

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT2F endp			; End RESINT2F procedure
endif				; IF @OEM_XMS
if @OEM_WIN3
	NPPROC	FIND_VXD -- Find Our VxD File
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure our VxD file is present on disk

On entry:

CX	=	0 if normal
	<>	0 if some other handler is failing

On exit:

CF	=	0 if found
	=	1 if not found
CX	=	unchanged if found
	=	non-zero if not found

|

	REGSAVE <ax,bx,dx,ds>	; Save registers

	push	seg PGROUP	; Get segment of VIRT_DEV_DPFE
	pop	ds		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

	mov	al,@OPEN_R	; Function code for read-only access
	DOSCALL @OPENF2,VIRT_DEV_DPFE ; Attempt to open it
	jc	short @F	; Jump if not found

	mov	bx,ax		; Copy to handle register
	DOSCALL @CLOSF2 	; Close it up
				; Return with CF significant
	jmp	short FIND_VXD_EXIT ; Join common exit code

@@:
	mov	ax,cs		; Get our code/data segment
	mov	ds,ax		; Address it
	assume	ds:PGROUP	; Tell the assembler about it

	DOSCALL @STROUT,MSG_VXDGONE ; Tell 'em there's a problem

	mov	cx,1		; Tell Windows to fail

	stc			; Assume not
FIND_VXD_EXIT:
	REGREST <ds,dx,bx,ax>	; Restore
	assume	ds:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_VXD endp			; End FIND_VXD procedure
endif				; IF @OEM_XMS
if @OEM_WIN3
	FPPROC	GET_WINVXD_VEC -- Fill In LO_and HI_WINVXD_VEC
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in LO_ and HI_WINVXD_VEC

On exit:

CF	=	0 if successful
	=	1 if not

|

	REGSAVE <ax,bx,di,es>	; Save registers

	xor	di,di		; In case we're not running Windows 3???
	mov	es,di		; ES:DI == 0:0
	assume	es:nothing	; Tell the assembler about it

	mov	ax,1684h	; Function code for Get Device Entry Point
	mov	bx,@VXD_ID	; Our device ID
	int	2Fh		; Request multiplexor support
	assume	es:nothing	; Tell the assembler about it
				; Return with ES:DI ==> Device API Entry Point

	mov	ax,es		; Check for error
	or	ax,di		; ...
	jz	short @F	; Jump if something went wrong (note CF=0)
.8086
	mov	ax,es		; Save segment
	mov	HI_WINVXD_VEC.VOFF,di ; Save for later use
	mov	HI_WINVXD_VEC.VSEG,ax ; ...

	mov	bx,seg PGROUP	; Get low memory segment
	mov	es,bx		; Address it
	assume	es:PGROUP	; Tell the assembler about it

	mov	LO_WINVXD_VEC.VOFF,di ; Save for later use
	mov	LO_WINVXD_VEC.VSEG,ax ; ...
DOT386 p
	stc			; Indicate it worked
@@:
	REGREST <es,di,bx,ax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_WINVXD_VEC endp		; End GET_WINVXD_VEC procedure
endif				; IF @OEM_WIN3
if @OEM_XMS
	 FPPROC  RESINT_XMS -- Resident XMS Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Resident XMS interrupt handler.

If we're ON, call extended memory code.
If we're AUTO inactive, attempt to go ON.
Otherwise, return universal error code.

The XMS spec requires us to start with a short jump
with enough patch space to put in a far immediate jump.

|

	 jmp	 short @F	; Short jump over patch area
	 nop			; Patch area (including the short jump)
	 nop			; sufficient for JMP oooo:ssss
	 nop
@@:
	 test	 GLB_FLAG,@GLB_ON ; Are we ON or AUTO active?
	 jz	 short RESINT_XMS_ASLEEP ; No, check for AUTO inactive
RESINT_XMS_AGAIN:
	 call	 FILL_EX2SIZE	; Fill in EX2SIZE as necessary
if @OEM_WIN3
	 cmp	 LOWWIN3_CB,2	; Izit under control of Windows' GDT/IDT/CR3?
	 jne	 short RESINT_XMS_INT ; Jump if not

	call	HI_PGET_WINVXD_VEC ; Fill in WINVXD_VEC
	jnc	short RESINT_XMS_ERR ; Jump if something went wrong

	 push	 @VXDAPI_XMS	; Code to request XMS service
	call	HI_WINVXD_VEC	; Request Windows Virtual Device API service

	 ret			; Return to caller
endif				; IF @OEM_WIN3

	 public  RESINT_XMS_INT
RESINT_XMS_INT:
	 int	 2Fh		; Call the extended memory code

	 ret			; Return to caller

RESINT_XMS_ASLEEP:
	 test	 GLB_FLAG,@GLB_AUTO ; In automatic mode?
	 jz	 short RESINT_XMS_ERR ; No, join common error exit code

	 call	 STATE_PM	; Change state to Protected Mode

	 cmp	 INFO_CTL,0	; Check for error
	 je	 short RESINT_XMS_AGAIN ; If at first you don't succeed, ...
RESINT_XMS_ERR:
	 xor	 ax,ax		; Return universal error code
	 mov	 bl,80h 	; Indicate function not implemented

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT_XMS endp 		; End RESINT_XMS procedure
endif				; IF @OEM_XMS
	 NPPROC  FILL_EX2SIZE -- Fill In EX2SIZE As Necessary
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in EX2SIZE as necessary

|

	 test	 XMS_FLAG,mask $XMS_I15 ; Is XMS INT 15h installed as yet?
	 jnz	 short FILL_EX2SIZE_EXIT ; Yes, no need to fill in EX2SIZE

	 push	 eax		; Save for a moment

	 mov	 ah,88h 	; Function code to get extended memory size
	 int	 15h		; Request BIOS service
	 movzx	 eax,ax 	; Zero to use as dword

	 assume  ds:PGROUP	; Tell a white lie
CSOVR	 mov	 <EX2SIZE,eax>	; Save for later use
	 assume  ds:nothing	; Retract nose

	 pop	 eax		; Restore
FILL_EX2SIZE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_EX2SIZE endp		; End FILL_EX2SIZE procedure
	 NPPROC  SET_FLAGS -- Set Caller's Flags
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set caller's flags

On entry:

SS:SP	 ==>	 ARG_STR

On exit:

FL	 =	 caller's flags from stack

|

SETFL_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
SETFL_CSIP dd	 ?		; INT caller's CS:IP
SETFL_FL dw	 ?		; ...	       FL

SETFL_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack
	 push	 [bp].SETFL_FL	; Put flags onto stack
	 and	 [bp-2].ELO,not (mask $TF) ; Turn off Trap Flag
	 popf			; Restore caller's IF
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_FLAGS endp			; End SET_FLAGS procedure
	 FPPROC  RESINT40 -- Resident Diskette Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

For compatibility with other INT 40h handlers in the chain, we don't
trap INT 40h calls in the IDT.

This handler swaps out/in the system ROM around the diskette call.
It also handles COMPAQ system ROM compression by ensuring that
functions 08h (Get Drive Parameters) and 18h (Set Media Type for
Format) return values in ES:DI point into the second half of the ROM.

|

if @OEM_HIFILL
	 test	 LCL_FLAG,@LCL_CROM ; Did we compress the system ROM?
	 jz	 short RESINT40_XCROM ; Jump if not

	 cmp	 ah,08h 	; Izit get drive parameters?
	 je	 short @F	; Jump if so

	 cmp	 ah,18h 	; Izit set media type for format?
	 jne	 short RESINT40_XCROM ; Jump if not
@@:

; Set caller's flags (IF and CF are the only significant ones)

	 call	 SET_FLAGS	; Set caller's flags

;;;;;;;; OLDINT  40		; Call previous handler
	 pushf			; Pass flags as in INT call
	 cli			; Duplicate INT calling environment
	 db	 @OPCOD_CALLF	; Opcode for far call immediate
	 public  OLDINT40_VEC
	 assume  ds:PGROUP	; Tell the assembler about it
OLDINT40_VEC dd  ?		; Save area for old INT 40h interrupt handler
	 assume  ds:nothing	; Tell the assembler about it
	 jc	 short RESINT40_EXIT ; Jump if error

	 pushf			; Save flags
	 push	 ax		; Save for a moment

	 mov	 ax,es		; Copy segment for testing

	 cmp	 ax,0F000h	; Izit in ROM?
	 jne	 short @F	; Jump if not

	 or	 di,8000h	; Ensure pointing into second half
@@:
	 pop	 ax		; Restore
	 popf			; Restore flags

	 jmp	 short RESINT40_EXIT ; Join common exit code

RESINT40_XCROM:
endif				; IF @OEM_HIFILL

if @OEM_WIN3
	 cmp	 LOWWIN3_CB,2	; Izit under control of Windows' GDT/IDT/CR3?
	 jne	 short @F	; Jump if not

if @OEM_HIFILL
	 jmp	 OLDINT40_VEC	; Continue with next handler in sequence
else
	 db	 @OPCOD_JMPF	; Opcode for far jump immediate
	 public  OLDINT40_VEC
OLDINT40_VEC dd  ?		; Save area for old INT 40h interrupt handler
endif				; IF @OEM_HIFILL

@@:
endif				; IF @OEM_WIN3
	 test	 GLB_FLAG,@GLB_ON ; Are we ON or AUTO active?
	 jz	 short @F	; Jump if not

	 push	 ax		; Save for a moment
	 mov	 al,0		; Function code to swap out
	 EMMOUT  @EMM2_ROMSWAP	; Swap it out
	 pop	 ax		; Restore
@@:

; Set caller's flags (IF and CF are the only significant ones)

	 call	 SET_FLAGS	; Set caller's flags

	 OLDINT  40		; Request original diskette service
				; Return with flags significant

	 pushf			; Save flags

	 test	 GLB_FLAG,@GLB_ON ; Are we ON or AUTO active?
	 jz	 short @F	; Jump if not

	 push	 ax		; Save for a moment
	 mov	 al,1		; Function code to swap in
	 EMMOUT  @EMM2_ROMSWAP	; Swap it in
	 pop	 ax		; Restore
@@:
	 popf			; Restore flags
RESINT40_EXIT:
	 ret	 2		; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT40 endp			; End RESINT40 procedure
	 FPPROC  RESINT15 -- Resident System Request Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

For compatibility with other INT 15h handlers in the chain, we don't
directly trap INT 15h calls in the IDT.  Instead, this handler bottoms
out the INT 15h chain and communicates with the program via an INT 15h
whose return address is recognized specially in the INT15 program in
high memory.

We trap AH=04h, 05h, 24h, AX=4F53h, AH=87h, 88h, and 89h calls only.
All other calls are passed on to the next handler in sequence.

|

	 pushf			; Save flags for a moment

	 sti			; Allow interrupts

	 test	 GLB_FLAG,@GLB_ON ; Are we ON or AUTO active?
	 jz	 short RESINT15_OFF ; No

if @OEM_BCF

; Strip off ABIOS calls if BCF is in effect before checking for
; Windows support because we need to return 86h in any case.

	 test	 LCL_FLAG,@LCL_BCF ; Izit BCF compressed?
	 jz	 short RESINT15_XABIOS ; Jump if not

	 cmp	 ah,04h 	; Izit ABIOS call?
	 je	 short @F	; Jump if so

	 cmp	 ah,05h 	; Izit ABIOS call?
	 jne	 short RESINT15_XABIOS ; Jump if not
@@:
if @OEM_WIN3 and @OEM_DEBUG

; In our retail version, allow DEBUG=ABIOS to take effect if we're not
; running under Windows

	 cmp	 LOWWIN3_CB,1	; Izit under control of Windows' GDT/IDT/CR3?
	 jbe	 short RESINT15_XMEM ; Jump if not
endif				; IF @OEM_WIN3 and @OEM_DEBUG

; Note we're using the ARG_STR as if the PUSHF were a PUSH BP

	 or	 [esp].ARG_FLG,mask $CF ; Set carry flag
	 popf			; Restore flags

	 mov	 ah,86h 	; Return universal error code

	 iret			; Return to caller

RESINT15_XABIOS:
endif				; IF @OEM_BCF

if @OEM_WIN3
	 cmp	 LOWWIN3_CB,1	; Izit under control of Windows' GDT/IDT/CR3?
	 jb	 short RESINT15_NORM ; Jump if normal
	 ja	 short RESINT15_ORIG ; Yes, continue on

	 cmp	 ah,0C1h	; Izit get XBIOS segment?
	 je	 short RESINT15_XMEM ; Jump if so

	 cmp	 ah,0C0h	; Izit get BIOS configuration data?
	 jne	 short RESINT15_NORM ; Jump if not

	 popf			; Restore flags

; First set caller's flags (IF is the only one which changed)

	 call	 SET_FLAGS	; Set caller's flags

	 push	 ax		; Save function code
;;;;;;;; OLDINT 15		; Call previous handler
	 pushf			; Pass flags as in INT call
	 cli			; Duplicate INT calling environment
	 db	 @OPCOD_CALLF	; Opcode for far call immediate
	 public  OLDINT15_VEC
	 assume  ds:PGROUP	; Tell the assembler about it
OLDINT15_VEC dd  ?		; Save area for old INT 15h interrupt handler
	 assume  ds:nothing	; Tell the assembler about it
	 pop	 ax		; Restore

	 jmp	 short RESINT15_INT ; Join common code

RESINT15_NORM:
endif				; IF @OEM_WIN3
	 cmp	 ah,24h 	; Check for A20 functions
	 je	 short RESINT15_XMEM ; Jump if so

	 cmp	 ax,4F53h	; Check for the Del part of Ctrl-Alt-Del
	 je	 short RESINT15_XMEM ; Jump if so

	 cmp	 ah,87h 	; Check against the low end
	 jb	 short RESINT15_ORIG ; Too small for us

	 cmp	 ah,89h 	; Check against the high end
	 ja	 short RESINT15_ORIG ; Too large for us
RESINT15_XMEM:
	 popf			; Restore flags

; First set caller's flags (IF is the only one which changed)

	 call	 SET_FLAGS	; Set caller's flags

	 public  RESINT15_INT
RESINT15_INT:
	 int	 15h		; Call PM routine

	 ret	 2		; Return to caller

RESINT15_OFF:
	 cmp	 ah,88h 	; Check for Get Extended Memory Size function
	 jne	 short RESINT15_ORIG ; Not this time

; Note that even if we're OFF from Windows 3 callback, we still must return
; the proper value for extended memory size

	 popf			; Restore flags

; Restore caller's flags (we're interested in IF only)

	 call	 SET_FLAGS	; Set caller's flags

	 xor	 ax,ax		; Mark as no extended memory

	 test	 XMS_FLAG,mask $XMS_I15 ; Is XMS INT 15h installed as yet?
	 jnz	 short RESINT15_OFFEXIT ; Yes, use zero length

	 mov	 ax,EXTSIZE.ELO ; Get size of extended memory

	 cmp	 EXTSIZE,0FFFFh ; Izit bigger than 16-bits?
	 jbe	 short @F	; Jump if not

	 mov	 ax,0FFFFh	; Use maximum
@@:
if @OEM_WIN3
	 cmp	 LOWWIN3_CB,0	; Izit Windows 3 init time or later?
	 ja	 short RESINT15_OFFEXIT ; Yes, use EXTSIZE
endif				; IF @OEM_WIN3

	 test	 GLB_FLAG,@GLB_ON or @GLB_AUTO ; Are we ON or AUTO?
	 jnz	 short RESINT15_OFFEXIT ; Yes, use EXTSIZE

	 mov	 ax,OFFSIZE	; Get size of extended memory if OFF
RESINT15_OFFEXIT:

; Clear the carry flag and set the zero flag

	 cmp	 ax,ax		; All in one instruction

	 ret	 2		; Return to caller

RESINT15_ORIG:
	 popf			; Restore flags

	 public  RESINT15_OLD
RESINT15_OLD:
if @OEM_WIN3
	 jmp	 OLDINT15_VEC	; Continue with previous handler
else
	 db	 @OPCOD_JMPF	; Opcode for far jump immediate
	 public  OLDINT15_VEC
OLDINT15_VEC dd  ?		; Save area for old INT 15h interrupt handler
endif				; IF @OEM_WIN3

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT15 endp			; End RESINT15 procedure
if @OEM_HILOAD
	 NPPROC  EXT_MACFNS -- Get PSP and call MAC functions in extended memory
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Call OLDINT21_VEC to get current PSP and call Int 21h for MAC functions
and high DOS scavenging.  If it's a function we emulate directly, we'll
return directly to the previous caller.

On entry:
AH	 =	DOS function (Int 20h is made to look like function 0)
SS:SP	 ==>	I21MAC_STR (defined in QMAX_I21.ASM)

Note that the caller's stack may be so fragile we can't breathe on it
(Lotus 123 calls NetX to exec 123DOS.EXE with a 32-byte stack right
above the program path).

|

; If we're not running under Windows, check for services we may need to
; handle specially.  We'll do the checking and servicing in QMAX_I21,
; and will change the return address of the IRETD if we don't want to
; pass control to DOS.
	 cmp	 LOWWIN3_CB,1	; Izit under control of Windows' GDT/IDT/CR3?
	 ja	 short EXTMAC_ORIG ; Yes, so we can't do anything with it

	 test	 I15_FLAG,@I15_X58 ; Are we ignoring 58xx support?
	 jnz	 short EXTMAC_ORIG ; Pass it on to DOS if so

	 or	 ah,ah		; Izit function 0 (Terminate) or Int 20h?
	 jz	 short @F	; Jump if so

	 cmp	 ah,@MACALG	; Izit get/set mem. alloc. strategy?
	 je	 short @F	; Jump if so

	 cmp	 ah,@EXITRC	; Izit function 4Ch (Exit with return code)?
	 ja	 short EXTMAC_ORIG ; Pass it on to DOS if greater

	 cmp	 ah,@GETMEM	; Izit function 48h, 49h, 4Ah, 4Bh or 4Ch?
	 jb	 short EXTMAC_ORIG ; Jump if not

@@:
; Switch stacks.  The caller's stack may be too small (as mentioned above).
; Note that our code in INT21_MACFNS needs to restore the original stack
; and restore the DX saved on our temporary stack regardless of whether
; or not we process the call.

; Although we should be called with interrupts disabled (this is,
; after all, called from within an interrupt handler), such is not
; always the case.  A customer reported a problem where using a
; Periscope Model IV board he saw a HW interrupt occur between the
; save of SS and the save of SP.

	cli			; Nobody move
.8086
	 mov	 STKPTR.VSEG,ss ; Save current stack segment
	 mov	 STKPTR.VOFF,sp ; ...and offset
DOT386 p
	 push	 cs		; Address PGROUP
	 pop	 ss		; Address stack
	 assume  ss:nothing	; Tell the assembler

	 lea	 sp,PGROUP:LOWSTKZ ; Address top of new stack

; We'll check the return EIP against EXTMAC_ORIG.  If we need to handle
; the call (i.e. arenas are linked) we'll change the IRETD return CS:EIP
; in protected mode and return to the caller directly.

	push	STKPTR		; Save in case the next handler re-enters us
	 sti			; Enable interrupts
	 push	 dx		; Save caller's DX

	 REGSAVE <ax,bx>	; Save for a moment

	 mov	 ah,@GETPS0	; Get PSP into BX

	 pushf			; Simulate interrupt
	 cli			; Disable interrupts
	 call	 OLDINT21_VEC	; Call old DOS entry point

	 mov	 dx,bx		; Put current PSP in DX

	 REGREST <bx,ax>	; Restore

; Note that we handle this call in protected mode specially-
; we know where it's from by checking the return address
	 int	 21h		; Handle it through the IDT

; SS:SP reloaded and original DX restored before IRETD

	 public  EXTMAC_ORIG
EXTMAC_ORIG:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EXT_MACFNS endp 		; End EXT_MACFNS procedure
endif				; IF @OEM_HILOAD
if @OEM_HILOAD
	 FPPROC  RESINT20 -- Resident DOS Terminate Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Intercept DOS terminate interrupt so we can free MAC entries in high DOS.

|

; Note that we must call EXT_MACFNS with SS:SP ==> IRET frame and that we
; may return directly to the caller.
.8086
	 mov	 SAVE_AH,ah	; Save input AH
DOT386 p
	 sub	 ah,ah		; Simulate Int 21h fn 0
	 call	 EXT_MACFNS	; If it's a MAC function, return directly to caller
	 mov	 ah,SAVE_AH	; Restore input AH

	 db	 @OPCOD_JMPF	; Opcode for far jump immediate
	 public  OLDINT20_VEC
	 assume  ds:PGROUP	; Tell the assembler about it
OLDINT20_VEC dd  ?		; Save area for old INT 15h interrupt handler
	 assume  ds:nothing	; Tell the assembler about it

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT20 endp			; End RESINT20 procedure
endif				; IF @OEM_HILOAD
if @OEM_HILOAD
	 FPPROC  RESINT21 -- Resident DOS Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Intercept DOS calls.

On entry:

AH	 =	 DOS function code
DX	 =	 # paras to keep (if AH = @KEEPRC)

|

; We need to preserve flags on entry for any call we're not going to handle
; in case someone's doing something like this:
; STC	 ; Assume failure
; MOV AX,D34Ch ; XYZ API call
; INT 21h ; See if we're installed
; JC ??? ; Jump if not
; We'll just grab the flags from the IRET frame before passing calls down to DOS

	 cmp	 ah,@GETRC	; Izit Get Return Code?
	 jne	 short @F	; Jump if not

	 btr	 MSC_FLAG,$MSC_GETRC ; Should we lie?
	 jnc	 short @F	; Jump if not

;;;;;;;; cli			; Simulate INT environment
	 pushf			; Pass a copy of the current flags
	 call	 OLDINT21_VEC	; Pass the call on down to DOS to zero the field

	 mov	 ax,EXITRCHI	; Get the return code
.8086
	 mov	 EXITRCHI,(@GETRC_RES shl 8) or 0 ; Mark as resident for next time
DOT386 p
	 iret			; Return to caller

@@:
	 cmp	 ah,@KEEPRC	; TSR call?
	 jne	 short @F	; Jump if not

	 call	 CHECK_ROOM	; Ensure there's enough room for COMMAND.COM
@@:
if @OEM_VIRTUALMEM
	 cmp	 ah,@CLOSF2	; Izit file close?
	 jne	 short @F	; Jump if not

	 call	 CHECK_CLOSF	; See if we're trying to close our swapfile
	 jnc	 short @F	; Jump if it's OK

	 call	 SET_FLAGS	; Set caller's flags from IRET frame

	 clc			; Hey, look at that -- it worked!

	 retf	 2		; Return to caller, popping flags

@@:
endif				; IF @OEM_VIRTUALMEM

; SS:SP ==> IRET frame.

	 call	 EXT_MACFNS	; If it's a MAC function, return directly to caller

RESINT21_ORIG:
	 call	 SET_FLAGS	; Set caller's flags from IRET frame

	 jmp	 OLDINT21_VEC	; Continue on

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT21 endp			; End RESINT21 procedure
endif				; IF @OEM_HILOAD
if @OEM_VIRTUALMEM
	 NPPROC  CHECK_CLOSF -- Check On Closing Swapfile
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if someone is trying to close our swapfile.  If so,
disallow it.

On entry:

BX	 =	 handle of file to close

On exit:

CF	 =	 1 if closing swapfile
	 =	 0 if not

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

; If Windows is running, ignore all this

if @OEM_WIN3
	 cmp	 LOWWIN3_CB,2	; Izit under control of Windows' GDT/IDT/CR3?
	 je	 short CHECK_CLOSF_EXIT ; Yes, continue on (note CF=0)
endif				; IF @OEM_WIN3

; Get the current PSP and swapfile handle

	 EMMOUT  @EMM2_SWAPFILE ; Return with CX = file handle, DX = PSP

	 cmp	 ah,0		; Did it succeed?
	 ja	 short CHECK_CLOSF_EXIT ; Jump if not (note CF=0)

; Is this the file handle of our swapfile for the current client

	 cmp	 bx,cx		; Izit our boy?
	 clc			; Assume not
	 jne	 short CHECK_CLOSF_EXIT ; Jump if not (note CF=0)

; Get the current PSP to test against DX

	 mov	 ah,@GETPS0	; Function code to get current PSP
	 OLDINT  21		; Call previous handler, return with
				; BX = PSP
	 cmp	 bx,dx		; Izit our boy?
	 clc			; Assume not
	 jne	 short CHECK_CLOSF_EXIT ; Jump if not (note CF=0)

	 stc			; Mark as not allowed
CHECK_CLOSF_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CLOSF endp		; End CHECK_CLOSF procedure
endif				; IF @OEM_VIRTUALMEM
if @OEM_HILOAD
	 FPPROC  RESINT27 -- Resident DOS TSR Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Intercept TSR calls from high memory.
Ensure there's enough room for COMMAND.COM.
Ensure video buffer MAC entry valid.

On entry:

DS:DX	 ==>	 next available byte after resident program

|

	 pushf			; Save flags

	 sti			; Allow interrupts

	 push	 dx		; Save for a moment

	 add	 dx,16-1	; Round up to para boundary
	 rcr	 dx,1		; Handle overflow to 1000h
	 shr	 dx,4-1 	; Convert from words to paras

	 call	 CHECK_ROOM	; Ensure there's enough room for COMMAND.COM

	 pop	 dx		; Restore

	 popf			; Restore

	 db	 @OPCOD_JMPF	; Opcode for far jump immediate
	 public  OLDINT27_VEC
	 assume  ds:PGROUP	; Tell the assembler about it
OLDINT27_VEC dd  ?		; Save area for old INT 27h interrupt handler
	 assume  ds:nothing	; Tell the assembler about it

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT27 endp			; End RESINT27 procedure
endif				; IF @OEM_HILOAD
if @OEM_HILOAD
	 NPPROC  CHECK_ROOM -- Ensure Enough Room For COMMAND.COM
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

This routine is used to ensure that programs
going resident in high DOS (via DOS 5 LOADHIGH) have their
LSEG entries updated.  This also applies to programs that attempt
to allocate a UMB and end up with an LSEG in low DOS.

On entry:

DX	 =	 # paras to keep

|

	REGSAVE <ax,bx,es>	; Save registers

; Attempt to modify MAC blocks for current task (just as DOS would do)
; If that succeeds, determine how much memory is available in high memory
; If that's not enough, release low memory and flag it

; Note that we can't issue an Int 21 call here, since some environments
; (like DECNET) assume that since DOS calls aren't reentrant, they don't
; have to support reentrancy...  The problem manifests itself in TFA.EXE.
; If we come down here on the function 31h call it goes resident with, then
; make an Int 21 call without switching stacks, TFA's resident Int 21
; handler will switch to the stack with our return address and blow it
; away.

; DOS calls made here need to use the previous handler or make sure
; they're on a safe stack.
	 mov	 ah,@GETPS0	; Get PSP into BX

	 pushf			; Simulate interrupt
	 cli			; Disable interrupts
	 call	 OLDINT21_VEC	; Call old DOS entry point

	 mov	 es,bx		; Copy to @MODMEM register
	 assume  es:nothing	; Tell the assembler about it

	 test	 I15_FLAG,@I15_X58 ; Are we supporting 5800 calls?
	 jnz	 short CHECK_ROOM_EXIT ; Jump if not

	 mov	 ah,@MODMEM	; Modify MAC block
	 mov	 bx,dx		; Copy to @MODMEM register

; We'll make sure it's an LSEG before we try modifying it upstairs
	 FINT	 RESINT21	; Call upstairs via EXT_MACFNS
				; Note that we'll return directly here
				; via IRETD
CHECK_ROOM_EXIT:
	REGREST <es,bx,ax>	; Restore
	assume	es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ROOM endp 		; End CHECK_ROOM procedure
endif				; IF @OEM_HILOAD
;;;	     NPPROC  READA20 -- Read A20 Status
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Read the A20 line status.
;;;
;;; On exit:
;;;
;;; @GLB_X1MB =      0 if A20 is OFF (disabled)
;;;	      =      1 ...	 ON  (enabled)
;;;
;;; |
;;;
;;;	     pushf		    ; Save flags
;;;
;;;	     cli		    ; Disallow interrupts
;;;
;;;	     REGSAVE <ax,ds,es>     ; Save registers
;;;
;;;	     assume  ds:PGROUP	    ; Tell a white lie
;;; CSOVR    and     <GLB_FLAG,not @GLB_X1MB> ; Assume OFF (disabled)
;;;	     assume  ds:nothing     ; Retract nose
;;;
;;;	     push    seg HMASEG     ; Get HMA segment #
;;;	     pop     es 	    ; Address it
;;;	     assume  es:HMASEG	    ; Tell the assembler about it
;;;
;;;	     push    seg INTVEC     ; Get interrupt vector segment
;;;	     pop     ds 	    ; Address it
;;;	     assume  ds:INTVEC	    ; Tell the assembler about it
;;;
;;;	     mov     ax,INT00_VEC.ELO ; Get first word
;;;
;;;	     cmp     ax,HMASTART.ELO ; Compare 'em
;;;	     jne     short READA20_ON ; If they're unequal, A20 is ON
;;;
;;; ; Assume A20 is ON: 	     � Assume A20 is OFF:
;;; ;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
;;; ; AX     INT00_VEC	    HMASTART � AX     INT00_VEC      HMASTART
;;; ;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
;;; ; xxxx     xxxx	      xxxx   � xxxx	xxxx	       xxxx
;;;
;;;	     not     HMASTART.ELO   ; Complement and retest
;;;	     not     ax
;;;
;;; ; yyyy     xxxx	      yyyy   � yyyy	yyyy	       yyyy
;;;
;;;	     cmp     ax,INT00_VEC.ELO ; Compare 'em
;;;	     not     HMASTART.ELO   ; Restore
;;;	     je      short READA20_EXIT ; If they're equal, A20 is OFF
;;; READA20_ON:
;;;	     assume  ds:PGROUP	    ; Tell a white lie
;;; CSOVR    or      <GLB_FLAG,@GLB_X1MB> ; Mark as ON (enabled)
;;;	     assume  ds:nothing     ; Retract nose
;;; READA20_EXIT:
;;;	     REGREST <es,ds,ax>     ; Restore
;;;	     assume  ds:nothing,es:nothing ; Tell the assembler about it
;;;
;;;	     popf		    ; Restore flags
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; READA20  endp		    ; End READA20 procedure
if @OEM_EMS
	 FPPROC  PGMAPRET -- Return From PGMAPCALL
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return from PGMAPCALL function.

|

	 EMMOUT  @EMM2_PGMAPRET ; Mark as return from PGMAPCALL

	 ret	 2		; Return from INT 67h, function 23 (AH=56h)

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PGMAPRET endp			; End PGMAPRET procedure
endif				; IF @OEM_EMS
	 FPPROC  HARDRET -- Return From Hardware Interrupt
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 public  RESINTFF_INT
RESINTFF_INT:
	 int	 0FFh		; Call via obscure interrupt

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

HARDRET  endp			; End HARDRET procedure
	 FPPROC  WARMBOOT -- Low Memory Warm Boot Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Low memory warm boot routine.

|

	 cli			; Disallow interrupts

	 test	 GLB_FLAG,@GLB_ON ; Are we ON or AUTO active?
	 jz	 short WARMBOOT_OFF ; No, skip warm boot
.8086
	 and	 GLB_FLAG,not @GLB_ERR ; Clear error flag to avoid recursion
DOT386 p
	 EMMOUT  @EMM_BOOT	; Reset the EMS system
	 mov	 al,0		; Function code to exit unconditionally
	 EMMOUT  @EMM2_GOREAL	; Exit from protected mode
WARMBOOT_OFF:
	 call	 WARMBOOT_SUB	; See if there's anything special to do

	 mov	 ds,SBIOSDATA	; Address the BIOS data area
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 mov	 RESET_FLAG,1234h ; Mark as warm boot

	 jmp	 GOVM86_REBOOT	; Reboot the system

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WARMBOOT endp			; End WARMBOOT procedure
	 NPPROC  STATE_OFF -- Change Current State To OFF
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Change current state to OFF.

|

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 REGSAVE <ax>		; Save register

.8086
	 mov	 INFO_CTL,0	; Assume successful
DOT386 p
	 push	 bp		; Save to store SP
	 mov	 bp,sp		; Save in case EMMOUT from real mode

	 mov	 al,1		; Function code to exit if not in use
	 EMMOUT  @EMM2_GOREAL	; Exit protected mode

	 mov	 sp,bp		; Restore stack pointer
	 pop	 bp		; Restore

.8086
	 mov	 INFO_CTL,ah	; Save return code
DOT386 p

	 REGREST <ax>		; Restore

	 popf			; Restore flags

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STATE_OFF endp			; End STATE_OFF procedure
if @OEM_VCPI and @VCP_OLD
	 FPPROC  OLDVCPI -- Old VCPI Entry Point
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Old VCPI entry point

|

	 public  RESINTFE_INT
RESINTFE_INT:
	 int	 0FEh		; Use an interrupt

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OLDVCPI  endp			; End OLDVCPI procedure
endif				; IF @OEM_VCPI and @VCP_OLD
if @OEM_EMS
	 FPPROC  RESINT67 -- Resident EMS Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

For compatibility with other INT 67h handlers in the chain, we don't
directly trap INT 67h calls in the IDT.  Instead, this handler bottoms
out the INT 67h chain and communicates with the program via an INT 67h
whose return address is recognized specially in the INT67 program in
high memory.

Note that if we're OFF from Windows 3 callback,
Windows has intercepted INT 67h.

|

; We need the following patch area for our VxD

	 jmp	 short @F	; Short jump over patch area
	 nop			; Patch area (including the short jump)
	 nop			; sufficient for JMP oooo:ssss
	 nop
@@:
	 pushf			; Save flags for a moment

if @OEM_VCPI
; We may not have picked up VCPI calls from the IDT to allow MEMLIMIT
; to do its thing.
	 cmp	 ah,0DEh	; Izit a VCPI call?
	 je	 short @F	; Jump if so

endif				; IF @OEM_VCPI

	 test	 GLB_FLAG,@GLB_I67 ; INT 67h installed?
	 jz	 short RESINT67_ORIG ; No
if @OEM_VCPI and @VCP_OLD
	 cmp	 ah,3Fh 	; Izit old VCPI call?
	 je	 short RESINT67_VCPI ; Yes
RESINT67_XVCPI:
endif				; IF @OEM_VCPI and @VCP_OLD
	 test	 I15_FLAG,@I15_FLEXFRAME ; Izit 386LOAD FLEXFRAME?
	 jz	 short @F	; Jump if not

; If it's an EMS (not VCPI) function, we must fail it.

	 cmp	 ah,@EMM_GETSTAT ; Izit below lowest numbered EMS function?
	 jb	 short @F	; Jump if so

	 cmp	 ah,@EMM_OSE	; Izit above highest numbered EMS function?
	 jbe	 short RESINT67_SOFTERR ; Jump if not

@@:
	 test	 GLB_FLAG,@GLB_ON ; Are we ON or AUTO active?
	 jnz	 short RESINT67_AGAIN ; Yes, continue on

	 test	 GLB_FLAG,@GLB_AUTO ; Are we AUTO inactive?
	 jz	 short RESINT67_ORIG ; No, continue on

	 call	 STATE_PM	; Change state to Protected Mode

	 cmp	 INFO_CTL,0	; Check for error
	 jne	 short RESINT67_SOFTERR ; Jump if software error
RESINT67_AGAIN:
	 popf			; Restore flags

; Restore caller's flags (mostly we're interested in IF)

	 call	 SET_FLAGS	; Set caller's flags

	 public  RESINT67_INT
RESINT67_INT:
	 int	 67h		; Call high memory routine

RESINT67_EXIT:
	 iret			; Return to caller

RESINT67_ORIG:
	 popf			; Restore flags

	 db	 @OPCOD_JMPF	; Opcode for far jump immediate
	 public  OLDINT67_VEC
	 assume  ds:PGROUP	; Tell the assembler about it
OLDINT67_VEC dd  ?		; Save area for old INT 67h interrupt handler
	 assume  ds:nothing	; Tell the assembler about it

RESINT67_SOFTERR:
	 popf			; Restore flags

	 public  RESINT67_IRET
RESINT67_IRET:
	 mov	 ah,80h 	; Something went wrong

	 iret			; Return to caller

if @OEM_VCPI and @VCP_OLD
RESINT67_VCPI:
	 cmp	 cx,'QE'        ; Ensure valid
	 jne	 short RESINT67_XVCPI ; Not this time

	 cmp	 dx,'MM'        ; Ensure valid
	 jne	 short RESINT67_XVCPI ; Not this time

	 popf			; Restore flags

	 mov	 ah,00h 	; Return code OK

	 push	 cs		; Setup ES as return segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it
	 lea	 di,OLDVCPI	; ES:DI ==> old VCPI handler

	 iret			; Return to caller
endif				; IF @OEM_VCPI and @VCP_OLD

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT67 endp			; End RESINT67 procedure
endif				; IF @OEM_EMS
	 FPPROC  RESINT19 -- Resident Bootstrap Loader Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Bootstrap loader interrupt handler.

Give back the intercepted interrupts:
11h, 15h, 19h, 20h, 21h, 27h, 29h, 2Fh, 40h, and 67h.

|

	 sti			; Allow interrupts
if @OEM_WTK
	 mov	 al,11h 	; Give back this one
	 lds	 dx,OLDINT11_VEC ; DS:DX ==> previous handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT
endif				; IF @OEM_WTK
	 mov	 al,15h 	; Give back this one
	 lds	 dx,OLDINT15_VEC ; DS:DX ==> previous handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT

	 mov	 al,19h 	; Give back this one
	 lds	 dx,cs:OLDINT19_VEC ; DS:DX ==> previous handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT
;;; if @OEM_HILOAD
;;;;;;;; mov	 al,21h 	; Give back this one
;;;;;;;; lds	 dx,OLDINT21_VEC ; DS:DX ==> previous handler
;;;;;;;; assume  ds:nothing	; Tell the assembler about it
;;;;;;;; DOSCALL @SETINT
;;;;;;;;
;;;;;;;; mov	 al,27h 	; Give back this one
;;;;;;;; lds	 dx,OLDINT27_VEC ; DS:DX ==> previous handler
;;;;;;;; assume  ds:nothing	; Tell the assembler about it
;;;;;;;; DOSCALL @SETINT
;;; endif			    ; IF @OEM_HILOAD
;;; if @OEM_XMS
;;;;;;;; mov	 al,2Fh 	; Give back this one
;;;;;;;; lds	 dx,OLDINT2F_VEC ; DS:DX ==> previous handler
;;;;;;;; assume  ds:nothing	; Tell the assembler about it
;;;;;;;; DOSCALL @SETINT
;;; endif			    ; IF @OEM_XMS
;;; if @OEM_WIN3 or @OEM_HIFILL
;;;;;;;; mov	 al,40h 	; Give back this one
;;;;;;;; lds	 dx,OLDINT40_VEC ; DS:DX ==> previous handler
;;;;;;;; assume  ds:nothing	; Tell the assembler about it
;;;;;;;; DOSCALL @SETINT
;;; endif			    ; IF @OEM_WIN3 or @OEM_HIFILL

	 test	 GLB_FLAG,@GLB_ON ; Are we ON or AUTO active?
	 jz	 short @F	; No, skip warm boot

	 EMMOUT  @EMM_BOOT	; Prepare the EMS system for a warm boot
@@:
;;; if @OEM_EMS
;;;;;;;; test	 GLB_FLAG,@GLB_I67 ; INT 67h installed?
;;;;;;;; jz	 short @F	; No
;;;;;;;;
;;;;;;;; mov	 al,67h 	; Give back this one
;;;;;;;; lds	 dx,OLDINT67_VEC ; DS:DX ==> previous handler
;;;;;;;; assume  ds:nothing	; Tell the assembler about it
;;;;;;;; DOSCALL @SETINT
;;; @@:
;;; endif			    ; IF @OEM_EMS
	 cli			; Disable interrupts

	 test	 GLB_FLAG,@GLB_ON ; Are we ON or AUTO active?
	 jz	 short @F	; No, skip GOREAL

	 mov	 al,0		; Exit unconditionally
	 EMMOUT  @EMM2_GOREAL	; Reboot the system
@@:
	 db	 @OPCOD_JMPF	; Opcode for far jump immediate
	 public  OLDINT19_VEC
	 assume  ds:PGROUP	; Tell the assembler about it
OLDINT19_VEC dd  ?		; Save area for old INT 19h interrupt handler
	 assume  ds:nothing	; Tell the assembler about it

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESINT19 endp			; End RESINT19 procedure
if @OEM_DPMI
	 FPPROC  DPMI_VM2PM -- DPMI Virtual to Protected Mode Switch
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI Virtual to Protected mode switch

On entry:

AX	 =	 1 if it's a 32-bit application
ES:0	 ==>	 DPMI private host data area

|

; We need to know where the caller's PSP is so we can address it
; via a selector as well as convert its environment segment to a
; selector.  Also, we need to know where the DTA points for DOS
; translation services.

	 REGSAVE <ax,bx,cx,es>	; Save registers

; Note that the above REGSAVE *MUST* match VM2PM_STR in INT31_VM2PM.

	 call	 FILL_EX2SIZE	; Fill in EX2SIZE as necessary

	 DOSCALL @GETPS0	; Return with BX = current PSP
	 mov	 cx,bx		; Save for later use

	 DOSCALL @GETDTA	; Return wih ES:BX ==> current DTA
	 assume  es:nothing	; Tell the assembler about it

	 public  DPMI_VM2PM_INT
DPMI_VM2PM_INT:
	 int	 31h		; Switch to PM

; The PM routine pops the registers from the stack and does the RETF
; even if we fail the INT 31h

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_VM2PM endp 		; End DPMI_VM2PM procedure
endif				; IF @OEM_DPMI
	 FPPROC  VM_VSAPI -- VM Vendor-Specific API Entry Point
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

VM vendor-specific entry point

On entry:

AX	 =	 function #

On exit:

As per the function #.

|

if @OEM_WIN3
	 cmp	 LOWWIN3_CB,2	; Izit under control of Windows' GDT/IDT/CR3?
	 je	 short VM_VSAPI_EXIT ; Yes, ignore this call (leave AH <> 0)
endif				; IF @OEM_WIN3

	 push	 bp		; Save to store SP
	 mov	 bp,sp		; Save in case EMMOUT fails

	 push	 ax		; Pass function # (stripped by PM code)
	 EMMOUT  @EMM2_VMVSAPI	; Ask PM code to handle it

	 mov	 sp,bp		; Restore stack pointer
	 pop	 bp		; Restore
VM_VSAPI_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VM_VSAPI endp			; End VM_VSAPI procedure

HICODE	 ends			; End HICODE segment


ZCODE	 segment use16 para public 'zcode' ; Start ZCODE segment
	 assume  cs:PGROUP,ds:PGROUP

if @OEM_DPMI
	 public  OVR_HPDA,@OVR_HPDALENP,@OVR_HPDALEND
OVR_HPDA HPDA_STR <>		; Pseudo-HPDA w/o dynamic areas
@OVR_HPDALENP equ (($-OVR_HPDA) + 16-1) / 16 ; Size of short HPDA in paras
@OVR_HPDALEND equ (($-OVR_HPDA) +  4-1) /  4 ; Size of short HPDA in dwords

	 public  ZLODPMI
ZLODPMI  label	 byte
endif				; IF @OEM_DPMI

	 public  @QMAX_OVR_ZCODE
@QMAX_OVR_ZCODE:		; Mark module start in .MAP file

	 public  IDT_REAL
	 align	 2
IDT_REAL df	 4*256-1	; Pointer to real mode IDT

	 public  ACTA20_DIS
	 include QMAX_A20.INC
ACTA20_DIS ACTA20_STR <PGROUP:A20DIS_I92,PGROUP:A20DIS_QUD,PGROUP:A20DIS_XT,PGROUP:A20DIS_ISA,PGROUP:A20DIS_I78>

	 NPPROC  A20DIS_I92 -- A20 Disable for I/O Port 92h Systems
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for I/O port 92h systems

On entry:

AL	 =	 @PS2_A port value

On exit:

AL	 =	 (updated to disable A20)

|

	 and	 al,not (mask $PS2_GATE) ; Disable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_I92 endp 		; End A20DIS_I92 procedure
	 NPPROC  A20DIS_QUD -- A20 Disable for Quadram 386/XT
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for Quadram 386/XT

On entry:

AL	 =	 1F8h port value

On exit:

AL	 =	 (updated to disable A20)

|

	 and	 al,not @BIT0	; Martk as disabling

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_QUD endp 		; End A20DIS_QUD procedure
	 NPPROC  A20DIS_XT -- A20 Disable for Inboard/PC
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for Inboard/PC

On exit:

AL	 =	 value to disable A20

|

	 mov	 al,@S2O_D20	; Tell it to disable A20

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_XT endp			; End A20DIS_XT procedure
	 NPPROC  A20DIS_I78 -- A20 Disable for I78 Systems
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for I78 systems

On entry:

AL	 =	 port 78h byte

On exit:

AL	 =	 (updated to disable A20)

|

	 and	 al,not @BIT2	; Disable A20 gate

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_I78 endp 		; End A20DIS_I78 procedure
	 NPPROC  A20DIS_ISA -- A20 Disable for ISA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

A20 disable for ISA

On entry:

AL	 =	 output port byte

On exit:

AL	 =	 (updated to disable A20)

|

;;;;;;;; or	 al,(mask $S2O_DATA ) or \
;;;;;;;;	    (mask $S2O_OBFUL) or \
;;;;;;;;	    (mask $S2O_IBFMT)
;;;;;;;;			; Ensure 6805 data line high,
;;;;;;;;			; output buffer full,
;;;;;;;;			; input buffer empty
	 or	 al,mask $S2O_OBFUL ; Ensure output buffer marked as full
	 and	 al,not (mask $S2O_GATE) ; Disable A20 gate

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

A20DIS_ISA endp 		; End A20DIS_ISA procedure
	 NPPROC  DEGATEA20 -- Disable Address Line A20
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable address line A20.

On exit:

CF	 =	 0 if all went well
	 =	 1 if we couldn't disable A20

|

	 push	 bx		; Save register

	 lea	 bx,ACTA20_DIS	; CS:BX ==> disable A20 actions

	 jmp	 ACTA20_COM	; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEGATEA20 endp			; End DEGATEA20 procedure
	 NPPROC  GOREAL_SUB -- Subroutine To Goreal
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

We're in protected mode and all selectors are in
one-to-one memory and are 64KB in length.

On exit:

We're in real mode

|

	 push	 eax		; Save register

; Load base and limit of IDT for real mode
; Note that we do it here in case the FAR JMP below signals
; an error.

	 LIDTD	 IDT_REAL	; Reset IDT for real mode

; Exit protected mode

	 mov	 eax,cr0	; Get current CR0
	 and	 ax,not (mask $PE) ; Turn off PE bit
	 mov	 cr0,eax	; Exit protected mode

; Jump to real mode code

	 FIJMP	 PGROUP:@F,<seg PGROUP> ; Far jump to set access rights
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it
@@:

; Re-initialize segment registers

	 mov	 ax,cs
	 mov	 ds,ax
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 es,ax
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 fs,ax
	 assume  fs:PGROUP	; Tell the assembler about it

	 mov	 gs,ax
	 assume  gs:PGROUP	; Tell the assembler about it

	 mov	 ss,ax
	 assume  ss:nothing	; Tell the assembler about it
	 mov	 sp,sp		; Just for the fun of it

; As we return to real mode, we must restore address line A20
; to the state as marked by @GLB_X1MB.
; Because we just exited from protected mode,
; the current physical state is ON.

	 test	 GLB_FLAG,@GLB_X1MB ; Check current logical state
	 jnz	 short GOREAL_SUB_EXIT ; Jump if it's ON (enabled)

if @OEM_WIN3
	 cmp	 LOWWIN3_CB,0	; Izit Windows 3 init time or later?
	 ja	 short GOREAL_SUB_EXIT ; Jump if so (leave A20 alone)
endif				; IF @OEM_WIN3

	 test	 LCL_FLAG,@LCL_RBT ; Are we rebooting?
	 jnz	 short GOREAL_SUB_EXIT ; Jump if so (ignore A20 state)

	 call	 DEGATEA20	; Disable address line A20
;;;;;;;; jnc	 short GOREAL_SUB_EXIT ; Jump if no error
;;;;;;;;
;;;;;;;; int	 03h		; Call our debugger
GOREAL_SUB_EXIT:
	 pop	 eax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GOREAL_SUB endp 		; End GOREAL_SUB procedure
	 NPPROC  GOREAL_LOW -- Switch Into Real Mode in Low Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Switch into real mode and continue with the interrupted instruction.

On entry:

We're in protected mode and all selectors are in
one-to-one memory and are 64KB in length.

On exit:

We're in real mode

|

; It must be true that the linear and physical address for
; this page are identical

; Turn off paging

	 mov	 eax,cr0	; Get current CR0
	 and	 eax,not (mask $PG) ; Turn off PG
	 mov	 cr0,eax	; No more paging

; Flush the pre-fetch instruction queue after setting paging off

	 jmp	 short $+2	; Flush it

; Clear the PDBR

	 xor	 eax,eax	; Zero EAX to clear CR3
	 mov	 cr3,eax	; Flush paging translation cache

; Flush the pre-fetch instruction queue after flushing page translation cache

	 jmp	 short $+2	; Flush it

	 call	 GOREAL_SUB	; Enter real mode
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing ; Tell the assembler about it

; Relocate the GDT from linear to physical addresses

;;;;;;;; mov	 eax,PRGBASE	; Get linear program base address
;;;;;;;; sub	 eax,PaPRGBASE	; Less physical one
;;;;;;;;
;;;;;;;; call	 RELOC_GDT	; Relocate 'em
;;;;;;;;
	 call	 SHADOW_DISABLE ; Set shadow RAM on CHIPSets to original values

if @OEM_EMS

; Mark EMS handler in low memory as no longer resident unless AUTO

	 test	 GLB_FLAG,@GLB_AUTO ; Izit AUTO state?
	 jnz	 short @F	; Yes, skip name clear

	 mov	 DEVDRV.DD_NAME[0],'Q' ; Zap device driver name
@@:
endif				; IF @OEM_EMS

; Restore caller's flags with IOPL=0 and NT=0 and IF=0

	 mov	 ax,[bp].INTXX_EFL.ELO ; Get caller's flags
	 and	 ax,not ((mask $IOPL) or (mask $NT) or (mask $IF))
	 mov	 LCL_EFL,ax	; Save to restore later
	 mov	 PLOWSTKZ,offset ds:LOWSTKZ ; Reset top of stack pointer

	 jmp	 GOVM86_LOW	; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GOREAL_LOW endp 		; End GOREAL_LOW procedure
	 NPPROC  SHADOW_DISABLE -- Unshadow RAM
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set shadow RAM on C&T CHIPSet machines to original values.

|

	 REGSAVE <ax>		; Save register

	 test	 CM2_FLAG,@CM2_SHD ; Izit AT386 or NEAT shadow RAM?
	 jz	 short SHADOW_DISABLE_EXIT ; Not this time

	 pushf			; Save flags
	 cli			; Nobody move

	 mov	 ah,AT386_CFG[0] ; Get old register value
	 mov	 al,CT_ROMCFG	; Register #
	 call	 SEND_CHIPSET	; Send AL=command/AH=data to CHIPSet

	 mov	 ah,AT386_RAB[0] ; Get old register value
	 mov	 al,CT_RAM_AB	; Register #
	 call	 SEND_CHIPSET	; Send AL=command/AH=data to CHIPSet

	 mov	 ah,AT386_RCD[0] ; Get old register value
	 mov	 al,CT_RAM_CD	; Register #
	 call	 SEND_CHIPSET	; Send AL=command/AH=data to CHIPSet

	 mov	 ah,AT386_REF[0] ; Get old register value
	 mov	 al,CT_RAM_EF	; Register #
	 call	 SEND_CHIPSET	; Send AL=command/AH=data to CHIPSet

	 popf			; Restore
SHADOW_DISABLE_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SHADOW_DISABLE endp		; End SHADOW_DISABLE procedure

	 assume  ds:PGROUP	; Tell the assembler about it

	 public  ZCODE_XLHI
ZCODE_XLHI label byte		; Ending address if MAX is not loaded high


if @OEM_HIFILL
	 DPALIGN ZLOCODE

; The following data area is a temporary home for LSEG
; It is moved from here to the actual home by CREA_LSEG

	 public  LSEG,LSEGZ
LSEG	 LSEG_STR <-1>		; Load segment structure
LSEGZ	 label	 byte		; Next available byte
	 org	 LSEG.LSEG_FNE
	 db	 @OEM_FILE,'.SYS' ; Device name (padded w/blanks in LSEG_STR)
	 org	 LSEGZ		; Restore IP
endif				; IF @OEM_HIFILL

ZCODE	 ends			; End ZCODE segment


PDTSEG	 segment use16 para public 'pdtgrp' ; Start PDTSEG segment
	 assume  ds:PDTGRP

	 public  OFFPDT
OFFPDT	 label	 dword

PDTSEG	 ends			; End PDTSEG segment

	 MEND			; End QMAX_OVR module

