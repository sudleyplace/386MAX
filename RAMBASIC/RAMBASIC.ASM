;' $Header:   P:/PVCS/MAX/RAMBASIC/RAMBASIC.ASV   1.3   30 May 1997 12:13:38   BOB  $
	 title	 RAMBASIC -- RAM Resident BASIC
	 page	 58,122
	 name	 RAMBASIC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned,  stack,  class 'prog'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment DATAZ, para-aligned,  public, class 'data'
	       Tail    segment DTAIL, dword-aligned, public, class 'data'

Program derived from:  None.

Original code by:  Bob Smith, April, 1991.

Modifications by:  None.

|
.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include DEVDRV.INC
	 include EMMCALL.INC
	 include EMM2CALL.INC
	 include VCPI.INC
	 include 386.INC
	 include PTR.INC
	 include I11.INC
	 include IOCTL.INC
	 include ALLMEM.INC
	 include OPEN.INC
	 include LSTLST.INC
	 include INTVEC.INC
	 include DPMI.INC

	 include QMAX_CTL.INC
	 include QMAX_LCL.INC
	 include QMAX_VCP.INC
	 include QMAX_DB2.INC
.list

PGROUP	 group	 STACK,CODE,DATA,DATAZ,NCODE,NDATA,DTAIL


VCPICALL2 macro  FUNC		; Use except for @VCPI_DBGxxx functions
	 local	 L1,L2

ifnb	<FUNC>
	 mov	 al,FUNC	; Get subfunction
endif				; IFNB <FUNC>
	 cmp	 EMS_PRES,1	; If EMS services are present,
	 je	 short L1	; ...use INT 67h entry

	 EMMOUT  @VCPI		; Call through the back door

	 jmp	 short L2	; Join common code
L1:
	 mov	 ah,@VCPI	; VCPI major function
	 int	 67h		; Request VCPI service
L2:
	 endm			; VCPICALL2


; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment use16 byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

; The following variables are accessed by the second instance of RAMBASIC,
; if we are trying to uninstall the first instance of RAMBASIC.

; RAMBASIC_SIGN = Signature used to verify resident instance.
; OLDINT15_VEC	= Address of original INT 15h handler.
; RB_LCL	= Resident copy's local flags.
; EMMHNDL	= EMS Handle used by resident program.
; BASIC_DEST	= Destination of BASIC (Either page frame or ZTAIL)

SIGNATURE	equ	'RAMBASIC 8.02   ' ; MUST be an exact multiple 16 bytes
				; This will ensure RAMBASIC_TSR is para aligned

	 public  RAMBASIC_SIGN
RAMBASIC_SIGN	db	SIGNATURE	; Our signature
@RAMBASIC_SIGNLEN	equ	 $-RAMBASIC_SIGN

	 public  OLDINT15_VEC
OLDINT15_VEC dd  ?		; Address of previous INT 15h handler

	 public  RB_LCL
	 include RB_LCL.INC
RB_LCL	 dw	 ?		; RAMBASIC Local Flags

	 public  EMMHNDL,BASIC_DEST
EMMHNDL  dw	 ?		; EMS handle
BASIC_DEST  dw	 ?		; Segment of BASIC destination

	 public  LPN_PPN	; LPN PPN
LPN_PPN  dw	 0,0		;  0   0	; Used for 1st 16KB entry
@LPN_PPN_16LEN equ ($-LPN_PPN)/4 ; Default # entries in LPN_PPN (16KB)

	 dw	 1,1		;  1   1	; Used for 2nd 16KB entry
@LPN_PPN_32LEN equ ($-LPN_PPN)/4 ; Default # entries in LPN_PPN (32KB)

	 public  LPN_PPN_LEN
LPN_PPN_LEN dw	 @LPN_PPN_16LEN ; Actual # entries in LPN_PPN
				; and # 16KB pages allocated

DATA	 ends			; End DATA segment


DATAZ	 segment use16 para public 'data' ; Start DATAZ segment
	 assume  ds:PGROUP

; Note: RAMBASIC_TSR must be on a para boundary.  This is enforced by
;	ensuring that this segment is para aligned and SIGNATURE will
;	always be a multiple of 16 bytes.

	 db	SIGNATURE	; Our signature (must be 16 bytes)

	 public  RAMBASIC_TSR
RAMBASIC_TSR   db  5*1024 DUP (?) ; RAM BASIC depository (if EMS not avail.)

DATAZ	 ends			; End DATAZ segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP
.xlist
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list
INITIAL:
	 jmp	 EMSBASIC	; Join common code, skipping over resident part

	 FPPROC  INT15 -- BIOS Servicec Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIOS services interrupt handler

|

ARG_STR  struc

ARG_BP	 dw	 ?		; Caller's BP
ARG_CSIP dd	 ?		; Caller's return address
ARG_FLG  dw	 ?		; Caller's flags

ARG_STR  ends

	 pushf			; Save flags

	 cmp	 ah,22h 	; Izit get ROM BASIC segment?
	 jne	 short INT15_ORIG ; Jump if not

	 test	 RB_LCL,@LCL_EMS ; Has ROM BASIC been copied to EMS?
	 jz	 short INT15_RAM ; Jump if not

; Ensure the ROM BASIC memory is mapped into the EMS page frame

	 push	 ax		; Save for a moment

	 REGSAVE <cx,dx,si,ds>	; Save for a moment

	 push	 cs		; Setup DS for EMMCALL
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 lea	 si,LPN_PPN	; DS:SI ==> (LPN, PPN) array
	 mov	 dx,EMMHNDL	; DX = EMS handle
	 mov	 cx,LPN_PPN_LEN ; CX = # entries in DS:SI
	 mov	 al,00h 	; Use (LPN, PPN) format
	 EMMCALL @EMM_MULPGMAP	; Map the pages

	 REGREST <ds,si,dx,cx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 cmp	 ah,0		; Did it work?
	 pop	 ax		; Restore
	 jne	 short INT15_ORIG ; Jump if not

INT15_RAM:
	 popf			; Restore flags

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack
	 push	 [bp].ARG_FLG	; Put flags onto stack
	 popf			; Restore caller's IF
	 pop	 bp		; Restore

	 mov	 es,BASIC_DEST	; Return segment of ROM BASIC
	 assume  es:nothing	; Tell the assembler about it

	 xor	 ax,ax		; Return universal OK code (note CF=0)

	 ret	 2		; Return to caller

INT15_ORIG:
	 popf			; Restore flags

	 jmp	 OLDINT15_VEC	; Contnue on with next handler

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT15	 endp			; End INT15 procedure

CODE	 ends			; End CODE segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

IRETD_MAC macro  NN
	 public  PM_IRETD&NN
PM_IRETD&NN&:
	 push	 &NN
	 int	 01h		; Call our debugger
	 iretd			; Return to caller
	 endm			; IRETD_MAC

CNT	 =	 0
	 rept	 32
	 IRETD_MAC %CNT
CNT	 =	 CNT+1
	 endm			; REPT 32

NCODE	 ends			; End NCODE segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

;---------------- DPMI variables -----------------------

	 public  DPMI_ENTRY,DOSINT_TEMP,DPMI_STACK
DPMI_ENTRY	 dd	 ?	; DPMI entry point
DOSINT_TEMP	 dd	 ?	; Temp holder for INT 21h
DPMI_STACK	 dd	 ?	; Temp holder of SS:SP while we're in PM
DPMI_LIN_BASIC	 dd	 ?	; Linear address of ROM Basic

;----------------- VCPI variables ----------------------

	 public  CON4K,CON64K,CON1M
CON4K	 dd	    4*1024	;  4K
CON64K	 dd	   64*1024	; 64K
CON1M	 dd	 1024*1024	;  1M

VDTE_STR struc

	 db	 (size DTE_STR) dup (?) ; 00-38
VCP_PMCS dq	 ?		; 40:  1st selector
VCP_PMDS dq	 ?		; 48:  2nd ...
VCP_PMES dq	 ?		; 50:  3rd ...
VCP_TR	 dq	 ?		; 58:  Task ...
VCP_4GB  dq	 ?		; 60:  All memory ...
VCP_LDT  dq	 ?		; 68:  LDT ...
VCP_VID  dq	 ?		; 70:  Video ...
VCP_SWAT dq	 30 dup (?)	; 78:  386SWAT selectors

VDTE_STR ends

	 public  LCLGDT,VCPGDT
LCLGDT	 VDTE_STR <>		; Local descriptor table for EPM
VCPGDT	 equ	 LCLGDT.VCP_PMCS ; Offset of VCPI selectors

IDTMAC	 macro	 NN
	 IDT_STR <PGROUP:PM_IRETD&NN&,DTE_CS,0,CPL0_INTR3,0> ; Local IDT
	 endm			; IDTMAC

	 public  LCLIDT
LCLIDT	 label	 tbyte
CNT	 =	 0
	 rept	 32
	 IDTMAC  %CNT
CNT	 =	 CNT+1
	 endm			; REPT 32

	 public  EPMTAB
EPMTAB	 EPM_STR <>		; Enter Protected Mode structure

	 public  LCLTSS
LCLTSS	 TSS_STR <>		; Local TSS

	 public  LaCODE,LaDATA,LaCR3,LaPTE,RaCR3,RaPTE,PaCR3,ROMPTE
LaCODE	 dd	 ?		; Linear address of our code segment
LaDATA	 dd	 ?		; ...			data
LaCR3	 dd	 ?		; ...			CR3
LaPTE	 dd	 ?		; ...			PTEs
RaCR3	 dw	 ?		; Relative		CR3
RaPTE	 dw	 ?		; ...			PTE
PaCR3	 dd	 ?		; Physical		CR3
ROMPTE	 dw	 ?		; Offset of ROM BASIC PTEs in PDT

	 public  PMI_FWD
PMI_FWD  df	 ?		; Selector:Offset to PMI code

	 public  OLDESP
OLDESP	 dd	 ?		; Save area for old ESP

	 public  CODESEG,DATASEG
CODESEG  dw	 ?,0		; Real mode code segment (padded to use as dword)
DATASEG  dw	 ?,0		; ...	    data ...

	 public  PMSTK,PMSTKZ
PMSTK	 dw	 256 dup (?)	; Protected mode stack
PMSTKZ	 label	 word		; End of ...

	 public  PMSTK_FVEC
PMSTK_FVEC label fword
	 dw	 PGROUP:PMSTKZ,0 ; Stack ending offset
	 dw	 DTE_SS 	; Stack selector

;------------------------------------------------------------

	 public  NEXTLOC
NEXTLOC  dw	 PGROUP:ZTAIL	; Offset of next available byte

	public	PORT67
PORT67	 dw	 ?		; I/O port for backdoor functions

	 public  EMS_PRES
EMS_PRES dw	 0		; 1 = EMS services present

	 public  CMD_FLAG
CMD_FLAG dw	 0		; Command flags
@CMD_SWAT equ	 8000h		; 386SWAT is installed

	 public  ROM_DEFAULT
@ROM_DEFAULT equ 0F600h 	; Default segment of ROM BASIC
ROM_DEFAULT  dw  @ROM_DEFAULT	; ...


	 public  ROMBAS,ROMBAS_LEN,ROMBAS_NAME
ROMBAS	 dw	 ?		; Segment of ROM BASIC
ROMBAS_LEN dd	 5*1024 	; Length of ... in bytes
ROMBAS_NAME db	 'RAMBASIC'     ; EMS handle name for ROM BASIC

	 public  EMS_FRAME
EMS_FRAME	dw	?	;Segment of EMS page frame

	 public  INFO_CTL,INFO,INFOSIZE,LCL_FLAG
	 include QMAXINFO.INC
	 align	 2
	 db	 ?		; Force even alignment for INFO_STR
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
INFOSIZE equ	 size INFO_STR
	 dw	 32 dup (?)	; Leave room for growth
LCL_FLAG equ	 INFO.INFO_LCL	; LCL_FLAG

	 public  DEV_HNDL
DEV_HNDL dw	 0		; Device handle #

	 public  NUMBERS_HI
NUMBERS_HI db	 '0123456789ABCDEF'

	 public  DEVNAME,EMMNAME
DEVNAME  db	 '386MAX$$',0   ; Our device name
EMMNAME  db	 'EMMXXXX0'     ; EMS device name
EMMNAME_LEN equ  $-EMMNAME	; Length of ...

	 public  IBMBIO,IBMDOS
IBMBIO	 db	 ?,':\IBMBIO.COM',0
IBMDOS	 db	 ?,':\IBMDOS.COM',0

;------------------ Messages ---------------------------

	 public  MSG_COPY
ifdef LANG_GR
MSG_COPY db	 'RAMBASIC -- Version 8.02 -- RAM-residenter BASIC-Handler fr PC-DOS 5.x',CR,LF
	 db	 '  (C) Copyright 1991-96 Qualitas, Inc.  Alle Rechte vorbehalten.',CR,LF,EOS
else
MSG_COPY db	 'RAMBASIC -- Version 8.02 -- RAM-resident BASIC Handler for PC-DOS 5.x',CR,LF
	 db	 '  (C) Copyright 1991-96 Qualitas, Inc.  GNU General Public License version 3.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public MSG_HELP
ifdef LANG_GR
MSG_HELP db	CR,LF
	 db	'Erm”glicht es BASIC-Programmen und EDIT.COM, mit '       ,CR,LF
	 db	'der BlueMAX-(tm)-BIOS-Kompression zusammenzuarbeiten'    ,CR,LF
	 db	'Optionen: /U  de-installieren'                           ,CR,LF
;;;;;;;; db	'          /P  PC-DOS bergehen'                          ,CR,LF
;;;;;;;; db	'          /32 kopiert alle 32 KB des ROM-BASIC'          ,CR,LF
;;;;;;;; db	'          /B  setzt ROM-BASIC bei F600 voraus'           ,CR,LF
	 db	'          /?  Hilfe'                                     ,CR,LF,EOS
else
MSG_HELP db	CR,LF
	 db	'Allows BASIC programs and EDIT.COM to operate ',CR,LF
	 db	'in conjunction with BlueMAX''s (tm) BIOS compression',CR,LF
	 db	'Options: /U  Uninstall'                 ,CR,LF
;;;;;;;; db	'         /P  PC-DOS override'           ,CR,LF
;;;;;;;; db	'         /32 Copy all 32K of ROM BASIC' ,CR,LF
;;;;;;;; db	'         /B  Assume ROM BASIC at F600'  ,CR,LF
	 db	'         /?  Help'                      ,CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_REMOVE,MSG_REMOVE_EMSERR
	 public  MSG_REMOVE_MEMERR,MSG_REMOVE_UNAVAIL,MSG_REMOVE_NOTINST
ifdef LANG_GR
MSG_REMOVE	db	'Residentes RAMBASIC wurde aus dem Speicher entfernt',                            CR,LF,EOS
MSG_REMOVE_EMSERR db	BEL,'ÍÍ> EMS-Fehler beim Entfernen des RAMBASIC aus dem Speicher aufgetreten.',   CR,LF,EOS
MSG_REMOVE_MEMERR db	BEL,'ÍÍ> Arena-Fehler beim Entfernen des RAMBASIC aus dem Speicher aufgetreten.', CR,LF,EOS
MSG_REMOVE_UNAVAIL db	BEL,'ÍÍ> kann nicht de-installieren, Interrupt 15 nicht verfgbar.',              CR,LF,EOS
MSG_REMOVE_NOTINST db	BEL,'ÍÍ> kann nichts de-installieren, was noch gar nicht installiert ist.',       CR,LF,EOS
else
MSG_REMOVE	db	'Resident RAMBASIC removed from memory', CR, LF, EOS
MSG_REMOVE_EMSERR db	BEL,'ÍÍ> EMS Error removing RAMBASIC from memory.',CR,LF,EOS
MSG_REMOVE_MEMERR db	BEL,'ÍÍ> Arena Error removing RAMBASIC from memory.',CR,LF,EOS
MSG_REMOVE_UNAVAIL db	BEL,'ÍÍ> Unable to deinstall, interrupt 15 is not available.',CR,LF,EOS
MSG_REMOVE_NOTINST db	BEL,'ÍÍ> Can not deinstall, not previously installed.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_INST_EMS,MSG_INST_RAM
ifdef LANG_GR
MSG_INST_EMS db  '  EMS-residentes BASIC wurde installiert.',CR,LF,EOS
MSG_INST_RAM db  '  RAM-residentes BASIC wurde installiert.',CR,LF,EOS
else
MSG_INST_EMS db  '  EMS-resident BASIC installed.',CR,LF,EOS
MSG_INST_RAM db  '  RAM-resident BASIC installed.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_NOTDOS5
ifdef LANG_GR
MSG_NOTDOS5 db	 BEL,'ÍÍ> falsche DOS-Versions-Nr. (geht erst ab 5.x).',CR,LF
else
MSG_NOTDOS5 db	 BEL,'ÍÍ> Incorrect DOS version # (must be 5.x or later).',CR,LF
endif				; IFDEF LANG_GR
MSG_NOTDOS5_LEN equ $-MSG_NOTDOS5 ; Length of ...

	 public  MSG_NOTPCDOS
ifdef LANG_GR
MSG_NOTPCDOS db   BEL,CR,LF,'  PC-DOS scheint nicht installiert zu sein. Ich habe keine Sytemdateien ',  CR,LF
	     db 	    'auf dem Boot-Laufwerk gefunden. Dieses Programm kann NUR zusammen mit',     CR,LF
	     db 	    'PC-DOS eingesetzt werden.',CR,LF,CR,LF
	     db 	    '  Bestimmte Utilities k”nnen verursachen, daá System-Dateien auf dem ',     CR,LF
	     db 	    'Boot-Laufwerk nicht mehr zu erreichen sind. Sollte dieses hier der Fall',   CR,LF
	     db 	    'sein, starten Sie bitte RAMBASIC mit der /P-Option.',CR,LF
else
MSG_NOTPCDOS db   BEL,CR,LF,'  PC-DOS does not appear to be installed.  System files not found',CR,LF
	     db   'on the boot drive.  This program should be run in conjunction with',CR,LF
	     db   'PC-DOS only.',CR,LF,CR,LF
	     db   '  Certain utilities may alter the boot drive mapping, causing ',CR,LF
	     db   'system files to be inaccessible.  If this is the case, run',CR,LF
	     db   'RAMBASIC with the /P option.',CR,LF
endif				; IFDEF LANG_GR
MSG_NOTPCDOS_LEN equ $-MSG_NOTPCDOS ; Length of ...

	 public  MSG_NOTPRES
ifdef LANG_GR
MSG_NOTPRES db	 BEL,'ÍÍ> BLUEMAX.SYS Einheiten-Treiber wurde nicht von CONFIG.SYS geladen.',CR,LF
else
MSG_NOTPRES db	 BEL,'ÍÍ> BLUEMAX.SYS device driver is not loaded from CONFIG.SYS.',CR,LF
endif				; IFDEF LANG_GR
MSG_NOTPRES_LEN equ $-MSG_NOTPRES ; Length of ...

	 public  MSG_WIN3
ifdef LANG_GR
MSG_WIN3   db	 BEL,'ÍÍ> Bitte verlassen Sie zuerst Windows!',CR,LF
else
MSG_WIN3   db	 BEL,'ÍÍ> You must first exit Windows.',CR,LF
endif				; IFDEF LANG_GR
MSG_WIN3_LEN equ $-MSG_WIN3	; Length of ...

	 public  MSG_TWICE
ifdef LANG_GR
MSG_TWICE db	 BEL,'ÍÍ> RAMBASIC wurde bereits installiert.',CR,LF
else
MSG_TWICE db	 BEL,'ÍÍ> RAMBASIC already installed.',CR,LF
endif				; IFDEF LANG_GR
MSG_TWICE_LEN equ $-MSG_TWICE	; Length of ...

	 public  MSG_NOROM
ifdef LANG_GR
MSG_NOROM db	 BEL,'ÍÍ> ROM-BASIC ist nicht vorhanden.',CR,LF
else
MSG_NOROM db	 BEL,'ÍÍ> ROM BASIC is not present.',CR,LF
endif				; IFDEF LANG_GR
MSG_NOROM_LEN equ $-MSG_NOROM	; Length of ...

	 public  MSG_NOCOPY
ifdef LANG_GR
MSG_NOCOPY db	 BEL,'ÍÍ> Fehler beim VCPI-Setup festgestellt.',CR,LF
else
MSG_NOCOPY db	 BEL,'ÍÍ> Error encountered during VCPI setup.',CR,LF
endif				; IFDEF LANG_GR
MSG_NOCOPY_LEN equ $-MSG_NOCOPY ; Length of ...

NDATA	 ends			; End NDATA segment


DTAIL	 segment use16 para public 'ndata' ; Start DTAIL segment
	 assume  ds:PGROUP

	 public  ZTAIL
ZTAIL	 label	 dword

DTAIL	 ends			; End DTAIL segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 NPPROC  EMSBASIC -- EMS Resident BASIC
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

* Display our copyright notice
* Check the command line
* Ensure we're running under PC-DOS 5.x or later
* Ensure we're running on a system with BASIC ROM (fail if not)
* Ensure we're running under BlueMAX (fail if not)
* Ensure we're not running under Windows/3 in enhanced mode
* Ensure we're not previously installed
* Check for DPMI support
* Check for an EMS handler
* Check for the EMS page frame
* Ensure there is enough EMS memory available
* Ensure EMSBASIC not already installed (fail if it is)
* Allocate EMS memory (if available)
* Map it into the first two pages of the EMS page frame
* Set the handle name
* Enter PM (through DPMI or VCPI) and copy ROM BASIC from physical F6000
  to the EMS page frame
* Install an INT 15h, function 22h handler
* Free our environment
* Go resident

Notes:
This program does not require any EMS services to function.
ROM BASIC is copied to the EMS page frame if it is available.
If EMS services are not available, the first 5K of ROM BASIC
is copied to the tail of the resident portion of this program.
The user may override the default selection of 5K with the /32
switch.  This causes the entire 32K of ROMBASIC to be copied to
either the Page Frame or to the end of the resident portion of
RAMBASIC.

|

; * Display our copyright notice

	 DOSCALL @STROUT,MSG_COPY ; Display the flag

; * Process the commnad line

	 call	 CHECK_PARMS	; Read the command line
	 jc	 near ptr EMSBASIC_ERR ; Jump if all done

; * Ensure we're running under PC-DOS 5.x or later

	 call	 IZITPCDOS5	; Izit PC-DOS 5.x or later?
	 jc	 near ptr EMSBASIC_ERR ; Jump if not

; * Ensure we're running on a system with BASIC ROM (fail if not)

	 call	 IZITRBASIC	; Izit ROM BASIC?
	 jc	 near ptr EMSBASIC_ERR ; Jump if not

; * Ensure we're running under BlueMAX (fail if not)

	 call	 IZITBLUE	; Izit BlueMAX?
	 jc	 near ptr EMSBASIC_ERR ; Jump if not

; * Ensure we're not running under Windows/3 in enhanced mode

	 call	 CHECK_WIN3	; Check for Windows/3 in enhanced mode
	 jc	 near ptr EMSBASIC_ERR ; Jump if so

; * Ensure we're not previously installed

	 call	 CHECK_INST	; Are we previously installed? (AX destroyed)
	 jnc	 short @F	; Jump if not

	 mov	 cx,MSG_TWICE_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_TWICE ; Tell 'em we're installed already

	 jmp	 short EMSBASIC_ERR ; Join common exit code
@@:

; * Determine if DPMI is available

	 call	 CHECK_DPMI	; Check for DPMI presence

; Assume BASIC to be copied to our program region (instead of EMS)

	 lea	 ax,RAMBASIC_TSR ; Get offset of end of TSR
	 shr	 ax,4-0 	; Convert from bytes to paras

	 mov	 BASIC_DEST,cs	; Get para of this program
	 add	 BASIC_DEST,ax	; Add the para of ROM BASIC destination

; Check to see if we should use EMS memory
; instead of adding ROMBASIC onto our TSR size

; * Ensure an EMS handler is present
; * Ensure the EMS page frame is present
; * Ensure there is enough EMS memory available
; * Ensure EMSBASIC not already installed (abort if true)

	 call	 IZITEMSMEM	; Is EMS available?
	 jc	 short RAMBASIC_RAM ; If not, add ROM BASIC to resident code

; * Allocate EMS memory
; * Map it into the first two pages of the EMS page frame
; * Set the handle name

	 call	 MAPEMS 	; Allocate it and map it in
	 jc	 short RAMBASIC_RAM ; If error, Add BASIC to resident portion

; Use EMS as ROM BASIC destination

	 mov	 ax,EMS_FRAME	; Get start of EMS Page Frame
	 mov	 BASIC_DEST,ax	; Store as address of RAM BASIC dest.

	 or	 RB_LCL,@LCL_EMS ; Mark as requesting BASIC copied to EMS

	 jmp	 short RAMBASIC_CONT ; Join common RAM and EMS code

RAMBASIC_RAM:

	 mov	 ROMBAS_LEN,5*1024 ; Overide user switch (if present)

RAMBASIC_CONT:

; * Enter PM (through DPMI or VCPI) and copy ROM BASIC from physical 000F6000
;   to the EMS page frame or to ZTAIL.

	 call	 COPY_ROM	; Copy ROM BASIC to EMS page frame
	 jc	 short EMSBASIC_ERR ; Jump if not

; * Install an INT 15h, function 22h handler

	 call	 INST15 	; Install our handler

; * Free our environment

	 xor	 ax,ax		; Zero for swap
	 xchg	 ax,PSP_ENVIR_PTR ; Get segment of our environment, set to zero
	 mov	 es,ax		; Get segment of our environment
	 assume  es:nothing	; Tell the assembler about it

	 DOSCALL @RELMEM	; Release memory at ES:0

; Display success banner

	 test	 RB_LCL,@LCL_EMS ; Is ROM BASIC to be copied to page frame?
	 jnz	 short INST_EMS ; Jump if so

	 DOSCALL @STROUT,MSG_INST_RAM ; Tell 'em we're about to install (RAM)
	 jmp	 short INST_COMN	; Join common code
INST_EMS:
	 DOSCALL @STROUT,MSG_INST_EMS ; Tell 'em we're about to install (EMS)
INST_COMN:

; * Go resident

	 lea	 dx,RAMBASIC_TSR ; CS:DX ==> next available byte

	 test	 RB_LCL,@LCL_EMS ; Is ROM BASIC to be copied to page frame?
	 jnz	 short @F	; Jump if so

	 add	 dx,ROMBAS_LEN.ELO ; Add in length of ROM BASIC to TSR size
@@:

	 int	 27h		; Go resident
EMSBASIC_ERR:
	 mov	 al,-1		; Universal error code
	 DOSCALL @EXITRC	; Exit with return code in AL
	 int	 20h		; Belt and suspenders

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMSBASIC endp			; End EMSBASIC procedure
	 NPPROC  CHECK_PARMS -- CHECK_PARMS Procedure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Read command line parameters

|

	 REGSAVE <ax,dx,si>	; Save registers


	 lea	 si,PSP_PARM_STRING ; DS:SI ==> parameter string
SKIPWHITE:
	 lodsb			; Get next character

	 cmp	 al,' '         ; Izit white space?
	 je	 short SKIPWHITE ; Jump if so

	 cmp	 al,TAB 	; Izit white space?
	 je	 short SKIPWHITE ; Jump if so

	 cmp	 al,'?'         ; Izit a request for help?
	 je	 short RAMBASIC_HELP ; Jump if so

	 cmp	 al,'/'         ; Izit switch character?
	 jne	 short CHECK_PARMS_CLC	; Jump if not

	 call	 SWPROC 	; Process switch character at DS:SI
	 jc	 short RAMBASIC_HELP ; Jump if invalid character

	 jmp	 SKIPWHITE	; Go around again

RAMBASIC_HELP:

	 DOSCALL @STROUT,MSG_HELP ; Display Help message
	 stc			; Mark as All Done
	 jmp	 short CHECK_PARMS_EXIT

CHECK_PARMS_CLC:
	 clc			; Mark as successful

CHECK_PARMS_EXIT:

	 REGREST <si,dx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PARMS	 endp			; End CHECK_PARMS_PROC procedure
	 NPPROC  SWPROC -- Process Switch Character
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Process switch character

On entry:

DS:SI	 ==>	 switch character

On exit:

CF	 =	 1 if valid switch character
	 =	 0 otherwise

DS:SI	 ==>	 (updated)

|

	 REGSAVE <ax>		; Save registers

	 lodsb			; Get switch character
	 call	 LOWERCASE	; Convert to common case

	 cmp	 al,'u'         ; Izit un-install?
	 jne	 short @F	; Jump if not

	 or	 RB_LCL,@LCL_REMOVE ; Mark as requesting un-installing

	 call	 REMOVE_RAMBASIC ; Remove ourselves

	 jmp	 short SWPROC_EXIT ; Join common exit code

@@:
	 cmp	 al,'3'         ; Izit 32KB BASIC?
	 jne	 short @F	; Jump if not

	 lodsb			; Get next command line character

	 cmp	 al,'2'         ; Izit 32KB BASIC?
	 jne	 short SWPROC_ERR ; Error if not

	 mov	 ROMBAS_LEN,32*1024 ; Copy all 32K of ROM BASIC
	 mov	 LPN_PPN_LEN,@LPN_PPN_32LEN ; Need 2 pages to hold ROM BASIC
				; (instead of 1 page)

	 clc			; Mark as successful

	 jmp	 short SWPROC_EXIT ; Join common exit code

@@:
	 cmp	 al,'p'         ; Izit IBM PC-DOS override?
	 jne	 short @F	; Jump if not

	 or	 RB_LCL,@LCL_PCDOS ; Assume PC-DOS is present

	 clc			; Mark as successful

	 jmp	 short SWPROC_EXIT ; Join common exit code
@@:
	 cmp	 al,'b'         ; Izit IBM PC-DOS override?
	 jne	 short @F	; Jump if not

	 or	 RB_LCL,@LCL_F600 ; Assume BASIC is at F600

	 clc			; Mark as successful

	 jmp	 short SWPROC_EXIT ; Join common exit code
@@:
SWPROC_ERR:
	 stc			; Mark as invalid
SWPROC_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SWPROC	 endp			; End SWPROC procedure
	 NPPROC  REMOVE_RAMBASIC -- Uninstall ourselves
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Remove the TSR from memory

1. Verify that there is a previous instance
2. Remove INT 15 handler from memory
3. Free EMS resources
4. Free memory from the first instance
5. Exit to DOS (to free our memory)

If there is nothing to uninstall,
CF is set upon exit.

|

; Verify that we have been previously installed

	 call	 CHECK_INST	; Are we previously installed? (AX=segment)
	 jc	 short @F	; Jump if so

	 DOSCALL @STROUT,MSG_REMOVE_NOTINST ; We are not previously installed
	 jmp	 short REMOVE_RAMBASIC_DOS ; Join common exit code

@@:
	 or	 ax,ax		; Is deinstall possible?
	 jnz	 short @F	; Jump if so

	 DOSCALL @STROUT,MSG_REMOVE_UNAVAIL ; Not able to deinstall
	 jmp	 short REMOVE_RAMBASIC_DOS ; Join common exit code
@@:

	 mov	 es,ax		; Segment of first instance
	 assume  es:PGROUP	; Tell the assembler about it

; ES => PGROUP of first instance of RAMBASIC

; Restore INT 15 hander

	 REGSAVE <ds>		; Save register

	 assume  ds:nothing	; Access OLDINT15_VEC from PGROUP via ES
				; (little white lie)

	 lds	 dx,OLDINT15_VEC ; Get original INT 15 vector
	 assume  ds:nothing	; Tell the assembler

	 mov	 al,15h 	; Interrupt vector 15h
	 DOSCALL @SETINT	; Set interrupt vector in AL to DS:DX

	 REGREST <ds>		; Restore register
	 assume  ds:PGROUP	; Tell the assembler about it

; Free EMS resources

	 assume  ds:nothing	; Access RB_LCL and EMMHNDL from PGROUP via ES
				; (little white lie)

	 test	 RB_LCL,@LCL_EMS ; Has ROM BASIC been copied to page frame?
	 jz	 short @F ; Jump if not

	 mov	 dx,EMMHNDL	; Get our EMS handle
	 EMMCALL @EMM_RLSPAGE	; Release it

	 assume  ds:PGROUP	; Retract nose

	 cmp	 ah,00h 	; Check EMS return code
	 je	 short @F	; Jump if no error

	 DOSCALL @STROUT,MSG_REMOVE_EMSERR ; Display error message
	 jmp	 short REMOVE_RAMBASIC_DOS ; Join common code

@@:

; Free memory from first instance

	 DOSCALL @RELMEM	; Release memory at ES:0
	 jnc	 short @F	; Jump if no error

	 DOSCALL @STROUT,MSG_REMOVE_MEMERR ; Display error message
	 jmp	 short REMOVE_RAMBASIC_DOS ; Join common code

@@:

	 DOSCALL @STROUT,MSG_REMOVE ; Tell 'em it worked

; Exit second instance of RAMBASIC

REMOVE_RAMBASIC_DOS:
	 mov	 al,0		; Normal return code
	 DOSCALL @EXITRC	; Exit process with return code in AL
	 int	 20h		; Belt and suspenders

	 assume  ds:nothing,es:nothing,ss:nothing

REMOVE_RAMBASIC  endp			; End REMOVE_RAMBASIC procedure
	 NPPROC  IZITPCDOS5 -- Izit PC-DOS 5.x or Later
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

* Ensure we're running under PC-DOS 5.x or later

On exit:

CF	 =	 0 if it is
	 =	 1 if not

|

	 REGSAVE <ax,bx,cx,dx,es> ; Save registers

; Check the version #

	 DOSCALL @DOSVER	; Return with
				; AL = major version #
				; AH = minor ...
				; BL = 00h if PC- or MS-DOS
				; BH, CX clobbered

	 cmp	 al,05h 	; Izit DOS 5.x or later?
	 jb	 short IZITPCDOS5_ERR1 ; Jump if not

; If the user wants to skip the PC-DOS check, let him (or her).
; This may be necessary if a disk compression utility like STACKER
; is present, then the system files will not be on the (supposedly)
; boot up drive.  The user is alerted that this option exists only
; through the IZITPCDOS5_ERR2 error message.  No mention of this
; override is present in HELP or the DOC file.

	 test	 RB_LCL,@LCL_PCDOS ; Should we assume PC-DOS is present?
	 jnz	 short IZITPCDOS5_CLC ; Jump if so

; Check the vendor type

	 cmp	 bl,00h 	; Izit PC- or MS-DOS?
	 jne	 short IZITPCDOS5_ERR2 ; Jump if not

; Ensure the files IBMBIO.COM and IBMDOS.COM are present
; on the startup drive

; The startup drive is found in the List of Lists

	 DOSCALL @GETLST	; Return with ES:BX ==> List of lists
	 assume  es:nothing	; Tell the assembler about it

	 mov	 al,es:[bx].LSTLST4_BOOT ; Get the boot drive # (origin-1)
	 add	 al,'A'-1       ; Convert to ASCII
	 mov	 IBMBIO[0],al	; Save in filename
	 mov	 IBMDOS[0],al	; ...

; Attempt to open the two files

	 mov	 al,@OPEN_R	; Function code for read-only
	 DOSCALL @OPENF2,IBMBIO ; Attempt to open it
	 jc	 short IZITPCDOS5_ERR2 ; Jump if not found

	 mov	 bx,ax		; Copy to handle register
	 DOSCALL @CLOSF2	; Close it up

	 mov	 al,@OPEN_R	; Function code for read-only
	 DOSCALL @OPENF2,IBMDOS ; Attempt to open it
	 jc	 short IZITPCDOS5_ERR2 ; Jump if not found

	 mov	 bx,ax		; Copy to handle register
	 DOSCALL @CLOSF2	; Close it up
IZITPCDOS5_CLC:
	 clc			; Indicate all went well

	 jmp	 short IZITPCDOS5_EXIT ; Join common exit code

IZITPCDOS5_ERR1:
	 mov	 cx,MSG_NOTDOS5_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOTDOS5 ; Tell 'em it's not DOS 5.x or later

	 jmp	 short IZITPCDOS5_ERR ; Join common error code

IZITPCDOS5_ERR2:
	 mov	 cx,MSG_NOTPCDOS_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOTPCDOS ; Tell 'em it's not PC-DOS
IZITPCDOS5_ERR:
	 stc			; Mark as in error
IZITPCDOS5_EXIT:
	 REGREST <es,dx,cx,bx,ax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITPCDOS5 endp 		; End IZITPCDOS5 procedure
	 NPPROC  IZITRBASIC -- Is ROM BASIC Present?
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

* Ensure we're running on a system with BASIC ROM (fail if not)

Note that we are always copying only the first 5K of ROM BASIC instead
of the entire 32K.  The only exception to this is if the user has
specifically requested 32K, through a command line option.  If this is
the case, LPN_PPN_LEN has already been updated.
Note also that we will only allow 32K to be copied to ROM if EMS is avail.

On exit:

CF	 =	 0 if all is well
	 =	 1 if not

|

	 REGSAVE <ax,bx,cx,dx,es> ; Save registers

	 mov	 ah,22h 	; Function code to return segment of ROM BASIC
	 int	 15h		; Request BIOS services
	 assume  es:nothing	; Tell the assembler about it
	 jnc	 short IZITRBASIC_5KB ; Jump if present

	 mov	 es,ROM_DEFAULT ; Assume the default location (F600)
	 assume  es:nothing	; Tell the assembler about it

	 test	 RB_LCL,@LCL_F600 ; Are we to assume BASIC is at F600?
	 jnz	 short IZITRBASIC_5KB ; Jump if so

	 mov	 al,18h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> current handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es		; Copy the segment #

	 cmp	 ax,@ROM_DEFAULT ; Izit in the usual place?
	 je	 short IZITRBASIC_FND ; Jump if it is

	 mov	 cx,MSG_NOROM_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOROM ; Tell 'em ROM BASIC not present

	 stc			; Mark as in error

	 jmp	 short IZITRBASIC_EXIT ; Join common exit code

IZITRBASIC_5KB:

; Note: The length of ROM BASIC is 5KB by default.

IZITRBASIC_FND:
	 mov	 ROMBAS,es	; Save for later use

	 clc			; Mark as found
IZITRBASIC_EXIT:
	 REGREST <es,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITRBASIC endp 		; End IZITRBASIC procedure
	 NPPROC  CHECK_WIN3 -- CHECK_WIN3 Procedure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT|

On exit: CF set if Win3 / enhanced mode is present

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 ax,1600h	; Enhanced Windows installation check
	 int	 2Fh		; Windows API

	 test	 al,7Fh 	; Check for enhanced Windows
	 jz	 short CHECK_WIN3_CLC ; Enhanced Windows is not running

	 cmp	 al,1		; Is it Windows/386 version 2.xx?
	 je	 short CHECK_WIN3_CLC ; Yes, so skip it

	 cmp	 al,0FFh	; Is it Windows/386 version 2.xx?
	 je	 short CHECK_WIN3_CLC ; Yes, so skip it

; Enhanced Windows/386 is running.  AL = major version #, AH = minor version #

	 mov	 cx,MSG_WIN3_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_WIN3 ; Display Windows 3.0 problem

	 stc			; Mark as Win3 present
	 jmp	 short CHECK_WIN3_EXIT ; Exit

; Enhanced Windows/386 is NOT running, continue on.

CHECK_WIN3_CLC:
	 clc			; Mark as Win3 not present

CHECK_WIN3_EXIT:

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_WIN3	 endp			; End CHECK_WIN3 procedure
	 NPPROC  IZITBLUE -- Is BlueMAX Installed
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

* Ensure we're running under BlueMAX (fail if not)

On exit:

CF	 =	 0 if it is
	 =	 1 if not

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

; See if we're already installed

	 mov	 al,02h 	; Access code for read/write
	 DOSCALL @OPENF2,DEVNAME ; Attempt to open 386MAX device driver
	 jnc	 short IZITBLUE1 ; That worked
IZITBLUE_XPRES:
	 mov	 cx,MSG_NOTPRES_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOTPRES ; Tell 'em 386MAX.SYS is not present

	 jmp	 short IZITBLUE_ERR ; Join common error exit code

IZITBLUE1:
	 mov	 DEV_HNDL,ax	; Save for later use
	 mov	 bx,ax		; Copy to handle register

; Ensure it's a device

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 jc	 short IZITBLUE_XPRES ; Something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 short IZITBLUE_XPRES ; No???

	 call	 INFO_READ	; Read in INFO structure

	 cmp	 INFO.INFO_SIGN.ELO[0],'83' ; Our signature?
	 jne	 short IZITBLUE_XPRES ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[2],'M6' ; Our signature?
	 jne	 short IZITBLUE_XPRES ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[4],'XA' ; Our signature?
	 jne	 short IZITBLUE_XPRES ; Not this time

	 mov	 ax,INFO.INFO_P67 ; I/O port number for EMM2 functions
	 mov	 PORT67,ax	; Save for EMMOUT macro

; Ensure BlueMAX is present (not just 386MAX)

	 test	 LCL_FLAG,@LCL_BCF ; Izit BCF compressed?
	 jnz	 short IZITBLUE_EXIT ; Jump if so (note CF=0)
IZITBLUE_ERR:
	 stc			; Mark as in error
IZITBLUE_EXIT:
	 pushf			; Save error return indicator

	 mov	 bx,DEV_HNDL	; Pick up device handle or NULL
	 or	 bx,bx		; Did we open 386MAX?
	 jz	 short @F	; Skip close if not

	 DOSCALL @CLOSF2	; Close handle in BX
@@:
	 popf			; Restore error return indicator

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITBLUE endp			; End IZITBLUE procedure
	 NPPROC  CHECK_INST -- Check for previous installation
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

* Ensure we're not previously installed

On exit:

CF	 =	 0 if we are not installed
	 =	 1 if we are already installed

AX	=	 Code segment of 1st copy if already installed	(CF=1)
		 0 if already installed but unable to deinstall (CF=1)
		 Undefined if not already installed		(CF=0)


|

	 REGSAVE <bx,cx,dx,si,di,es> ; Save registers

; Get current Int 15 handler

	 mov	 al,15h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> Int 15 handler
	 assume  es:nothing	; Tell the assembler about it

; Save address of original INT 15 handler for deinstallation

	 mov	 OLDINT15_VEC.VOFF,bx ; Save original INT 15 offset
	 mov	 OLDINT15_VEC.VSEG,es ; Save original INT 15 segment

; Check signature at current Int 15 handler

	 lea	 si,RAMBASIC_SIGN ; DS:SI ==> Our known signature
	 lea	 di,RAMBASIC_SIGN ; ES:DI ==> Supposed signature
	 mov	 cx,@RAMBASIC_SIGNLEN ; Length of signature

    repe cmps	 ds:[si].LO,es:[di].LO ; Compare 'em
	 jnz	 short @F	; Jump if strings do not match

; We found a previous version of RAMBASIC - deinstall if possible

	 mov	 ax,OLDINT15_VEC.VSEG ; Pass back CS of original TSR

	 jmp	 short CHECK_INST_STC ; Join common code

@@:

; We did not find a signature at the INT 15 handler,
; so we cannot deinstall.  However, we have to determine if RAMBASIC
; is previoulsy installed, even though deinstall is not possible.

	 mov	 ah,22h 	; Function code to return segment of ROM BASIC
	 int	 15h		; Request BIOS services
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short CHECK_INST_CLC ; Jump if we're not installed yet

	 mov	 dx,es		; Move BASIC address to general register

; Check to see if EMS sevices are available

	 mov	 al,67h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> current handler
	 assume  es:nothing	; Tell the assembler about it

	 lea	 di,es:[0].DD_NAME ; ES:DI ==> device name (if present)
	 lea	 si,EMMNAME	; DS:SI ==> EMS device name
	 mov	 cx,EMMNAME_LEN ; CX = length of ...
    repe cmpsb			; Compare 'em

	 jne	 short CHECK_INST_RAM ; Jump if EMS not avail.

CHECK_INST_EMS:

; Compare against page frame address

	 EMMCALL @EMM_GETPGFR	; Find the page frame address (-> BX)

	 or	 ah,ah		; Success?
	 jnz	 short CHECK_INST_RAM ; Jump if not (No EMS services avail)

	 cmp	 bx,dx		; Compare Frame to BASIC address
	 je	 short CHECK_INST_UNAVAIL ; jump if the same (must be installed)

; Compare our signature with that of just before BASIC's

CHECK_INST_RAM:

	 dec	 dx		; Point to para before ROM BASIC
	 mov	 es,dx		; Address the para prior to ROM BASIC
	 assume  es:nothing	; Tell the assembler about it

	 lea	 si,RAMBASIC_SIGN ; DS:SI ==> Our known signature
	 xor	 di,di		; Supposed signature
	 mov	 cx,@RAMBASIC_SIGNLEN ; Length of signature

    repe cmps	 ds:[si].LO,es:[di].LO ; Compare 'em
	 jnz	 short CHECK_INST_CLC ; Jump if strings do not match
				; If so, we are not installed

CHECK_INST_UNAVAIL:
	 xor	 ax,ax		; Indicate deinstall is not possible
CHECK_INST_STC:
	 stc			; Mark as already present
	 jmp	 short CHECK_INST_EXIT ; Join common exit code

CHECK_INST_CLC:
	 clc			; Mark as not previously installed
				; Return AX is undefined

CHECK_INST_EXIT:
	 REGREST <es,di,si,dx,cx,bx> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_INST endp 		; End CHECK_INST procedure
	 NPPROC  CHECK_DPMI -- CHECK_DPMI Procedure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT|

On exit: CF set if DPMI is present

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

	 mov	 ax,1687h	; Get DPMI Info
	 int	 2Fh		; DPMI hooks this one
	 assume  es:nothing	; Tell the assembler about it

	 or	 ax,ax		; Check for success
	 jnz	 short CHECK_DPMI_EXIT ; Jump if error (DPMI not present)

;;;;;;;; mov	 DPMI_FLAGS,bx	; Save Flags
;;;;;;;; mov	 DPMI_CPUTYPE,cl ; Save CPU type
;;;;;;;; mov	 DPMI_VER,dx	; Save DPMI version number
;;;;;;;; mov	 DPMI_HPDA_SIZE,si ; Save HPDA para count
	 mov	 DPMI_ENTRY.VECTOR.VSEG,es ; Save DPMI entry segment
	 mov	 DPMI_ENTRY.VECTOR.VOFF,di ; Save DPMI entry offset

	 or	 RB_LCL,@LCL_DPMI_PRES ; Mark as DPMI present

CHECK_DPMI_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DPMI endp 		; End CHECK_DPMI procedure
	 NPPROC  INFO_READ -- Read In INFO Structure
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 al,02h 	; Read from device
	 mov	 bx,DEV_HNDL	; Get device handle
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INFO_READ endp			; End INFO_READ procedure
	 NPPROC  IZITEMSMEM -- Is There Enough EMS Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

* Ensure an EMS handler is present (fail if not)
* Ensure the EMS page frame is present (fail if not)
* Ensure there is enough EMS memory available (fail if not)

On exit:

CF	 =	 0 if EMS services available
	 =	 1 if not (revert to conventional memory)

If CF = 0, EMS_FRAME is updated to indicate para of the EMS Page Frame.

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

; * Ensure an EMS handler is present (fail if not)

	 mov	 al,67h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> current handler
	 assume  es:nothing	; Tell the assembler about it

	 lea	 di,es:[0].DD_NAME ; ES:DI ==> device name (if present)
	 lea	 si,EMMNAME	; DS:SI ==> EMS device name
	 mov	 cx,EMMNAME_LEN ; CX = length of ...
    repe cmpsb			; Compare 'em
	 jne	 short IZITEMSMEM_ERR ; Jump if not present

	 mov	 EMS_PRES,1	; Set EMS present

; * Ensure the EMS page frame is present (fail if not)

	 EMMCALL @EMM_GETPGFR	; Return with BX = EMS page frame

	 cmp	 ah,0		; Did it work?
	 jne	 short IZITEMSMEM_ERR ; Jump if not

	 mov	 EMS_FRAME,bx	; Save as possible dest. of BASIC

; * Ensure there is enough EMS memory available (fail if not)

	 EMMCALL @EMM_GETPGCT	; Return with BX = # free 16KB pages
				; DX = total # pages

	 cmp	 ah,0		; Did it work?
	 jne	 short IZITEMSMEM_ERR ; Jump if not

	 cmp	 bx,LPN_PPN_LEN ; Is there enough?
	 jb	 short IZITEMSMEM_ERR ; Jump if not

; All EMS test have passed

	 clc			; Mark as EMS OK to use
	 jmp	 short IZITEMSMEM_EXIT ; Join common exit code

IZITEMSMEM_ERR:
	 stc			; Mark as an EMS error
IZITEMSMEM_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITEMSMEM endp 		; End IZITEMSMEM procedure
	 NPPROC  MAPEMS -- Allocate and Map EMS Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

* Allocate EMS memory
* Map it into the first two pages of the EMS page frame
* Set the handle name

On exit:

CF	 =	 0 if all is well
	 =	 1 if not

|

	 REGSAVE <ax,bx,cx,dx,si> ; Save registers

; Allocate the pages

	 mov	 bx,LPN_PPN_LEN ; Allocate this many 16KB pages
	 EMMCALL @EMM_SETPAGE	; Allocate 'em
				; Return with DX = EMS handle

	 cmp	 ah,0		; Did it work?
	 jne	 short MAPEMS_ERR ; Jump if not

	 mov	 EMMHNDL,dx	; Save for later use

; Map in the pages

	 mov	 si,00h 	; Physical page #
	 mov	 bx,0		; Logical page #
	 mov	 cx,LPN_PPN_LEN ; Get # 16KB pages allocated
@@:
	 mov	 ax,si		; Copy physical page # to AL
	 EMMCALL @EMM_MAPHNPG	; Map handle DX, LPN BX to PPN AL

	 cmp	 ah,0		; Did it work?
	 jne	 short MAPEMS_ERR ; Jump if not

	 inc	 si		; Skip to next physical page
	 inc	 bx		; ...	       logical ...

	 loop	 @B		; Jump if more 16KB pages to map

; Set the EMS handle name

	 mov	 al,01h 	; Subfunction to set handle name
	 lea	 si,ROMBAS_NAME ; DS:SI ==> ROM BASIC EMS handle name
	 EMMCALL @EMM_GETSETNAME ; Set handle name

	 cmp	 ah,0		; Did it work?
	 jne	 short MAPEMS_ERR ; Jump if not

	 clc			; Mark as OK

	 jmp	 short MAPEMS_EXIT ; Join common exit code

MAPEMS_ERR:
	 stc			; Mark as in error
MAPEMS_EXIT:
	 REGREST <si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MAPEMS	 endp			; End MAPEMS procedure
	 NPPROC  DB2HEX -- Convert AL to Hex At ES:DI
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL to hex at ES:DI

On entry:

AL	 =	 value to convert
ES:DI	 ==>	 output save area

On exit:

ES:DI	 ==>	 byte to right of converted number

|

	 push	 cx		; Save for a moment
	 mov	 cx,2		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 cx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DB2HEX	 endp			; End DB2HEX procedure
	 NPPROC  BIN2HEX_SUB
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL/AX/EAX to hex at ES:DI

On entry:

AL/AX	 =	 value to convert
CX	 =	 # hex digits to convert
ES:DI	 ==>	 output save area

On exit:

ES:DI	 ==>	 byte to right of converted number

|


	 REGSAVE <ax,bx,dx>	; Save registers

	 pushf			; Save flags
	 std			; Store backwards

	 mov	 dx,ax		; Copy to secondary register
	 lea	 bx,NUMBERS_HI	; XLAT table
	 add	 di,cx		; Skip to the end+1
	 push	 di		; Save to return
	 dec	 di		; Now the last digit
BIN2HEX_MORE:
	 mov	 al,dl		; Copy to XLAT register
	 and	 al,0Fh 	; Isolate low-order digit
	 xlat	 NUMBERS_HI	; Convert to ASCII hex
	 stosb			; Save in output area

	 shr	 dx,4		; Shift next digit down to low-order

	 loop	 BIN2HEX_MORE	; Jump if more digits to format

	 pop	 di		; Restore

	 popf			; Restore flags

	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2HEX_SUB endp		; End BIN2HEX_SUB procedure
	 NPPROC  LOWERCASE -- Convert To Lowercase
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Convert to lowercase

On entry:

AL	 =	 character to convert

On exit:

AL	 =	 converted character

|

	 cmp	 al,'A'         ; Izit below lower limit?
	 jb	 short LOWERCASE_EXIT ; Jump if so

	 cmp	 al,'Z'         ; Izit above uppper limit?
	 ja	 short LOWERCASE_EXIT ; Jump if so

	 add	 al,'a'-'A'     ; Convert to lowercase
LOWERCASE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure
	 NPPROC  COPY_ROM -- Copy ROM BASIC to EMS Page Frame
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

* Enter PM through VCPI and copy ROM BASIC from physical 000F6000
  to the EMS page frame

On exit:

CF	 =	 0 if all is well
	 =	 1 if not

|

	 pushad 		; Save all EGP registers
	 REGSAVE <ds,es>	; Save segment registers

	 test	 RB_LCL,@LCL_DPMI_PRES ; Is DPMI present?
	 jz	 short COPY_ROM_VCPI ; Jump if not (use VCPI back door)

	 call	 COPY_DPMI	; Copy ROM BASIC via DPMI method
	 jnc	 near ptr COPY_ROM_EXIT ; Exit if all went well,
				; ... otherwise try again, via VCPI

COPY_ROM_VCPI:

; The following call sets up PaCR3 needed by debugger if present

	 call	 SETUP_PMI	; Setup the PMI
	 jc	 near ptr COPY_ROM_ERR ; Jump if something went wrong

; Determine whether or not a resident debugger is present

	 VCPICALL2 @VCPI_DPRES	; Izit present?

	 or	 ah,ah		; Check for presence
	 jnz	 near ptr COPY_ROM_XDBG ; Jump if not

; Tell SWAT about our new CR3 and linear address

	 mov	 edx,-1 	; Mark as unchanged
	 mov	 ebx,PaCR3	; Get new CR3 physical address
	 VCPICALL2 @VCPI_DBGLIN ; Set new CR3 and linear address

	 or	 ah,ah		; Check for presence
;;;;;;;; SETMSG  "Error on debugger set CR3 and linear address",ERR
	 jnz	 near ptr COPY_ROM_ERR ; Jump if in error

; Initialize debugger GDT entries

	 lea	 di,LCLGDT.VCP_SWAT ; ES:DI ==> 1st debugger GDT entry
	 mov	 bx,VCP_SWAT	; Get initial selector
	 VCPICALL2 @VCPI_DBGINI ; Initialize the GDT entries

	 or	 ah,ah		; Check for presence
;;;;;;;; SETMSG  "Error on debugger GDT initialization",ERR
	 jnz	 near ptr COPY_ROM_ERR ; Jump if in error

; Initialize the debugger's IDT entries

	 xor	 bx,bx		; Initial interrupt #
	 mov	 cx,20h 	; # interrupt #s
	 lea	 di,LCLIDT	; ES:DI ==> initial IDT entry
	 mov	 edx,PaCR3	; Get physical address of CR3
COPY_ROM_DBGNEXT:
	 VCPICALL2 @VCPI_DBGIDT ; Initialize an IDT entry

	 cmp	 ah,83h 	; Check for invalid interrupt #
	 je	 short @F	; Jump if so

	 or	 ah,ah		; Check for presence
;;;;;;;; SETMSG  "Error on debugger GDT initialization",ERR
	 jnz	 near ptr COPY_ROM_ERR ; Jump if in error
@@:
	 inc	 bx		; Skip to next interrupt #
	 add	 di,size IDT_STR ; Skip to next IDT entry

	 loop	 COPY_ROM_DBGNEXT ; Jump if more interrupt #s

	 or	 CMD_FLAG,@CMD_SWAT ; Mark as enabled
COPY_ROM_XDBG:
	 call	 SETUP_GDT	; Setup the GDT

	 call	 SETUP_TSS	; Setup the TSS

; Setup to Enter and Exit Protected Mode

	 call	 SETUP_EPM	; Set it up

	 lea	 esi,EPMTAB	; Get offset of system tables
	 add	 esi,LaDATA	; Plus base linear address
	 mov	 OLDESP,esp	; Save old stack ptr

	 VCPICALL2 @VCPI_EPM	; Enter Protected Mode
COPY_ROM_PMON:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

; Ensure no interrupts between above VCPICALL and the following LSS

	 lss	 esp,PMSTK_FVEC ; SS:ESP ==> PM stack
	 assume  ss:nothing	; Tell the assembler about it

	 push	 DTE_DS 	; Get our data selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 DTE_ES 	; Get our extra data selector
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 xor	 ax,ax		; A convenient zero
	 mov	 fs,ax		; Clear selector
	 assume  fs:nothing	; Tell the assembler about it
	 mov	 gs,ax
	 assume  gs:nothing	; Tell the assembler about it

; Call 386SWAT if enabled

;;;;;;;; test	 CMD_FLAG,@CMD_SWAT ; Izit enabled?
;;;;;;;; jz	 short @F	; Not this time
;;;;;;;;
;;;;;;;; int	 01h		; Call the debugger
;;;@@:
	 push	 VCP_4GB	; Get all memory selector
	 pop	 es		; Address it
	 assume  es:AGROUP	; Tell the assembler about it

; Copy ROM BASIC from original segment to the EMS page frame

	 movzx	 esi,ROMPTE	; Get offset of ROM BASIC PTEs
	 sub	 si,RaPTE	; Less start of PTEs
	 shl	 esi,(12-2)-0	; Convert from 4KB in dowrd to bytes
				; AGROUP:ESI ==> ROM BASIC PTEs

; In case ROM BASIC is not on a 4KB boundary, handle that here

	 movzx	 eax,ROMBAS	; Get ROM BASIC segment
	 and	 ax,((4*1024) shr (4-0))-1 ; Isolate the 4KB offset in paras
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 esi,eax	; Add to source base
				; AGROUP:ESI ==> ROM BASIC

	 movzx	 edi,BASIC_DEST ; Get the segment of the EMS page frame
	 shl	 edi,4-0	; Convert from paras to bytes
				; AGROUP:EDI ==> EMS page frame

	 mov	 ecx,ROMBAS_LEN ; ECX = length of ROM BASIC in bytes
S32  rep movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Copy it

; Return to Virtual Mode

	 PUSHD	 gs		; GS with filler
	 PUSHD	 fs		; FS ...
	 push	 DATASEG.EDD	; DS ...
	 push	 DATASEG.EDD	; ES ...
	 push	 DATASEG.EDD	; SS ...
	 push	 OLDESP 	; ESP
	 PUSHD	 0		; EFL
	 push	 CODESEG.EDD	; Real mode CS with filler
	 lea	 eax,COPY_ROM_PMOFF ; Get return address
	 push	 eax		; EIP

	 push	 VCP_4GB	; Get all memory selector
	 pop	 ds		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ah,@VCPI	; Get major VCPI function code
	 mov	 al,@VCPI_EPM	; Return to VM86 mode
	 call	 PMI_FWD	; Call PMI code
COPY_ROM_PMOFF:
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 clc			; Indicate all went well

	 jmp	 short COPY_ROM_EXIT ; Join common exit code

COPY_ROM_ERR:
	 mov	 cx,MSG_NOCOPY_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOCOPY ; Tell 'em we had a problem

	 stc			; Mark as in error
COPY_ROM_EXIT:
	 REGREST <es,ds>	; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_ROM endp			; End COPY_ROM procedure
	 NPPROC  SETUP_PMI -- Setup Get Protected Mode Interface
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup Get Protected Mode Interface

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,si,di> ; Save registers

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,ds		; Get our data segment
	 shl	 eax,4-0	; Convert to paras to bytes
	 mov	 LaCODE,eax	; Save as our code's linear base address
	 mov	 LaDATA,eax	; Save as our data's linear base address

	 movzx	 eax,NEXTLOC	; Get offset of next available byte
	 add	 eax,LaDATA	; Plus its linear base address
	 add	 eax,4096-1	; Round up ...
	 and	 eax,not (4096-1) ; ...to 4KB boundary
	 mov	 LaCR3,eax	; Save as linear address of CR3
	 add	 eax,4096	; Skip over PDIR
	 mov	 LaPTE,eax	; Save as linear address of PTEs

	 mov	 eax,LaCR3	; Get linear address
	 sub	 eax,LaDATA	; Convert from linear to relative
	 mov	 RaCR3,ax	; Save for later use

	 mov	 ecx,LaCR3	; Get linear address
	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 VCPICALL2 @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX
	 mov	 PaCR3,edx	; Save for later use

	 mov	 eax,LaPTE	; Get linear address
	 sub	 eax,LaDATA	; Convert from linear to relative
	 mov	 RaPTE,ax	; Save for later use

; Setup our own PDIR with two PDEs

	 mov	 ecx,LaPTE	; Get its linear address
	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 VCPICALL2 @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX

	 mov	 eax,edx	; Copy to output register
	 mov	 di,RaCR3	; Get relative address of CR3
	 or	 eax,@PTE_URP	; Mark as User/Read-Write/Present
	 stosd			; Save as 1st PDE

	 mov	 ecx,LaPTE	; Get its linear address
	 add	 ecx,CON4K	; Skip to next PTE
	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 VCPICALL2 @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX

	 mov	 eax,edx	; Copy to output register
	 or	 eax,@PTE_URP	; Mark as User/Read-Write/Present
	 stosd			; Save as 2nd PDE

; Setup PMI

	 lea	 si,VCPGDT	; DS:SI ==> three DTEs for PMI
	 mov	 di,RaPTE	; ES:DI ==> PTEs
	 VCPICALL2 @VCPI_GPMI	; Return with EBX=offset, DI=advanced

	 cmp	 ah,0		; Check for error
;;;;;;;; SETMSG  "Unable to read Protected Mode Interface data",ERR
	 stc			; Assume in error
	 jne	 short SETUP_PMI_EXIT ; Jump if not OK (note CF=1)

	 mov	 PMI_FWD.FOFF,ebx ; Save offset of PMI
	 mov	 PMI_FWD.FSEL,VCP_PMCS ; Save selector of PMI
	 mov	 ROMPTE,di	; Save offset of ROM BASIC PTEs

; Setup PTEs for ROM BASIC

	 movzx	 eax,ROMBAS	; Get segment of ROM BASIC
	 shl	 eax,4-0	; Convert from paras to bytes
	 and	 ax,not (4*1024-1) ; Round down to 4KB boundary
	 or	 eax,@PTE_URP	; Mark as User/Read-Write/Present
	 mov	 cx,1+(32/4)	; # PTEs counting rounding
@@:
	 stosd			; Save as next ROM BASIC PTE

	 add	 eax,CON4K	; Skip to next PTE

	 loop	 @B		; Jump if more PTEs to fill in

; Save offset of next available byte

	 mov	 NEXTLOC,di	; Save it

	 clc			; Indicate all went well
SETUP_PMI_EXIT:
	 REGREST <di,si,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_PMI endp			; End SETUP_PMI procedure
	 NPPROC  SETUP_GDT -- Setup The GDT
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup the GDT for EPM

|

	 REGSAVE <eax,ebx>	; Save registers

; Setup local code descriptor

	 push	 LaCODE 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_CODE	; Pass access rights byte
	 push	 DTE_CS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local data descriptor

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_DS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local extra data descriptor

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_ES 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local stack descriptor

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_SS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local all memory descriptor

	 push	 dword ptr 0	; Pass base
	 push	 dword ptr 0	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 VCP_4GB	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local TSS descriptor

	 lea	 eax,LCLTSS	; Get local TSS address
	 add	 eax,LaDATA	; Convert from relative to absolute

	 push	 eax		; Pass base
	 push	 dword ptr (size TSS_STR) ; Pass length
	 push	 CPL0_IDLE3	; Pass access rights byte
	 push	 VCP_TR 	; Pass selector
	 call	 SET_GDT	; Set the GDT

	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_GDT endp			; End SETUP_GDT procedure
	 NPPROC  SET_GDT -- Set Global Descriptor Table
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set the blobal descriptor table.

|

SET_GDT_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
SET_GDT_DTE dw	 ?		; DTE to set
SET_GDT_ARB db	 ?,?		; Access rights byte
SET_GDT_LEN dd	 ?		; Segment length
SET_GDT_BAS dd	 ?		; Segment base

SET_GDT_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,bx,ecx>	; Save registers

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
	 mov	 LCLGDT.DESC_SEGLM1[bx],cl ; Save as data limit
;;;;;;;; ror	 ecx,16 	; Swap back

; Set access rights byte

	 mov	 al,[bp].SET_GDT_ARB ; Get it
	 mov	 LCLGDT.DESC_ACCESS[bx],al ; Set it

	 REGREST <ecx,bx,eax>	; Restore

	 pop	 bp		; Restore

	 ret	 2*2+2*4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_GDT  endp			; End SET_GDT procedure
	 NPPROC  SETUP_TSS --  Setup The TSS
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup the TSS for EPM

|

	 REGSAVE <eax>		; Save register

	 mov	 LCLTSS.TSS_ESP0,offset ds:PMSTKZ
	 mov	 LCLTSS.TSS_SS0,DTE_SS

	 mov	 eax,PaCR3	; Get CR3 physical address
	 mov	 LCLTSS.TSS_CR3,eax ; Save in TSS

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_TSS endp			; End SETUP_TSS procedure
	 NPPROC  SETUP_EPM -- Setup to Enter and Exit Protected Mode
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup to enter and exit protected mode.

|

	 REGSAVE <eax,ecx,edx,di> ; Save registers

	 mov	 CODESEG,cs	; Save for later use
	 mov	 DATASEG,ds	; Save for later use

; Setup our own CR3

	 mov	 eax,PaCR3	; Get CR3 physical address
	 mov	 EPMTAB.EPM_CR3,eax ; Save in EPMTAB

; Setup pointer to local GDT

	 lea	 eax,LCLGDT	; Get offset
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 LCLGDT.DTE_GDT.DTR_BASE,eax ; Save as linear address of GDT
	 mov	 LCLGDT.DTE_GDT.DTR_LIM,(size VDTE_STR)-1 ; Save as limit

	 lea	 eax,LCLGDT.DTE_GDT ; Get pointer
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 EPMTAB.EPM_GDTP,eax ; Save it

; Setup pointer to local IDT
; Note that the IDT has *NOT* been filled in

	 lea	 eax,LCLIDT	; Get offset
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 LCLGDT.DTE_IDT.DTR_BASE,eax ; Save as linear address of IDT
	 mov	 LCLGDT.DTE_IDT.DTR_LIM,32*8-1 ; Save as limit

	 lea	 eax,LCLGDT.DTE_IDT ; Get pointer
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 EPMTAB.EPM_IDTP,eax ; Save it

; Setup local LDT and TR

	 mov	 EPMTAB.EPM_LDTR,0 ; Don't use one
	 mov	 EPMTAB.EPM_TR,VCP_TR ; Use local one

; Setup return address

	 mov	 EPMTAB.EPM_EXIT.FOFF,offset cs:COPY_ROM_PMON
	 mov	 EPMTAB.EPM_EXIT.FSEL,DTE_CS ; Save our code selector

	 REGREST <di,edx,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_EPM endp			; End SETUP_EPM procedure
	 NPPROC  COPY_DPMI -- Copy ROM BASIC to EMS Page Frame (via DPMI)
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

* Enter PM through DPMI and copy ROM BASIC from physical 000F6000
  to the EMS page frame

On exit:

CF	 =	 0 if all is well
	 =	 1 if not

|

	 REGSAVE <ds,es,fs,gs>	; Save all segment registers
	 pushad 		; Save all EGP registers

; Allow DPMI physical -> Linear mapping below 1 MB

	 test	 INFO.INFO_DB2,@DB2_DPMIPHYS ; Are P2L mappings allowed?
	 jnz	 short @F	; Jump if so

	 mov	 bx,@DB2_DPMIPHYS ; Allow P2L mappings bit
	 EMMOUT  @EMM2_DB2FLAG	; Flip bits in DB2_FLAG as marked in BX
@@:

; Hook INT 21 so that we can filter out function 4Ch for return

	 mov	 al,21h 	; DOS interrupt
	 DOSCALL @GETINT	; Get interrupt vector in AL to ES:BX
	 assume  es:nothing	; Tell the assembler about it

	 mov	 DOSINT_TEMP.VECTOR.VSEG,es ; Save INT 21 segment
	 mov	 DOSINT_TEMP.VECTOR.VOFF,bx ; Save INT 21 offset

	 mov	 al,21h 	; DOS interrupt
	 DOSCALL @SETINT,DPMI_INT21 ; Set interrupt vector in AL to DS:DX

; Save stack for return from DPMI Protected Mode
; DPMI returns to VM mode with a different stack
; Note: There can be no more PUSH/POPs after we save the stack context

	 mov	 DPMI_STACK.VECTOR.VSEG,ss ; Save SS
	 mov	 DPMI_STACK.VECTOR.VOFF,sp ; Save SP

; Prepare HPDA linear address

	 mov	 bx,cs		; Get code segment
	 mov	 ax,NEXTLOC	; Get offset of HPDA (into PGROUP)
	 shr	 ax,4-0 	; Convert offset from bytes to paras
	 add	 ax,bx		; Add offset to segment
	 inc	 ax		; Round up to nearest paragraph

	 mov	 es,ax		; Store for entry into PM (HPDA para)
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,0		; Use 16 bit DPMI services

	 call	 DPMI_ENTRY	; Jump to PM via DPMI
	 jc	 DPMI_FAILURE	; Jump if error (we're still in VM)

;------------------------- Protected Mode ----------------------

	 assume  ds:PGROUP, es:nothing, ss:nothing, fs:nothing, gs:nothing

COMMENT |

After jump into PM:

CS,DS,SS =	Real mode counterparts (64K limit)
FS,GS	=	0
ES	=	PSP with 100h limit

|

; Allocate ROM BASIC destination descriptor

	 mov	 cx,1		; Number of descriptors to allocate

	 DPMICALL @DPMI_GETLDT	; Allocate LDT descriptor function (0000h)
	 jc	 near ptr DPMI_ERROR ; Jump if error

; Set up Base Address for destination descriptor

	 mov	 bx,ax		; Our destination selector
	 movzx	 ecx,BASIC_DEST ; Get the destination segment of BASIC
	 shl	 ecx,4-0	; Convert paras to bytes
	 mov	 dx,cx		; Get lower half of destination
	 shr	 ecx,16 	; Get upper half of destination

	 DPMICALL @DPMI_SSELBAS ; Set Segment Base Address function (0007h)
	 jc	 short DPMI_ERROR ; Jump if error

; Set up the limit for the destination descriptor

;;;;;;;; mov	 bx,??		; Our destination selector (already set)
	 xor	 cx,cx		; Zero the upper half of limit
	 mov	 dx,ROMBAS_LEN.ELO ; Set the limit of destiantion segment

	 DPMICALL @DPMI_SSELLIM ; Set Selector Limit function (0008h)
	 jc	 short DPMI_ERROR ; Jump if error

	 mov	 es,bx		; Load destination selector
	 assume  es:nothing	; Tell the assembler about it

; Find the linear address for ROM BASIC

	 movzx	 ebx,ROMBAS	; Get the Segment of physical page
	 shl	 ebx,4-0	; Convert paras to bytes
	 mov	 cx,bx		; Get lower half of source
	 shr	 ebx,16 	; Get upper half of source

	 xor	 si,si		; Zero upper half of map size
	 mov	 di,ROMBAS_LEN.ELO ; Lower half of map size

	 DPMICALL @DPMI_GETP2L	; Physical address Mapping function (0900h)
	 jc	 short DPMI_ERROR ; Jump if error

	 mov	 DPMI_LIN_BASIC.EHI,bx ; Store upper half of linear address
	 mov	 DPMI_LIN_BASIC.ELO,cx ; Store lower half of linear address

; Allocate ROM BASIC source descriptor

	 mov	 cx,1		; Number of descriptors to allocate

	 DPMICALL @DPMI_GETLDT	; Allocate LDT descriptor function (0000h)
	 jc	 short DPMI_ERROR ; Jump if error

; Set up Base Address for source descriptor

	 mov	 bx,ax		; Our source selector
	 mov	 cx,DPMI_LIN_BASIC.EHI ; Get source segment of BASIC (upper)
	 mov	 dx,DPMI_LIN_BASIC.ELO ; Get source segment of BASIC (lower)

	 DPMICALL @DPMI_SSELBAS ; Set Segment Base Address function (0007h)
	 jc	 short DPMI_ERROR ; Jump if error

; Set up the limit for the source descriptor

;;;;;;;; mov	 bx,??		; Our source selector (already set)
	 xor	 cx,cx		; Zero the upper half of limit
	 mov	 dx,ROMBAS_LEN.ELO ; Set the limit of source segment

	 DPMICALL @DPMI_SSELLIM ; Set Selector Limit function (0008h)
	 jc	 short DPMI_ERROR ; Jump if error

; Copy ROM BASIC (finally)

	 mov	 cx,ROMBAS_LEN.ELO ; Get the length

	 mov	 ds,bx		; Load source selector
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; A convenient zero
	 xor	 di,di		; A convenient zero
S16	rep movsb		; Move ROM BASIC

	 jmp	 short DPMI_EXIT_PM ; Join common PM exit code

	 assume  ds:nothing	; Tell the assembler

; DPMI Error

DPMI_ERROR:
	 assume  ds:PGROUP	; Tell the assembler

	 or	 RB_LCL,@LCL_DPMI_ERR ; Set error flag

	 assume  ds:nothing	; Tell the assembler

; Exit PM

DPMI_EXIT_PM:
	 xor	 al,al		; Error code
	 DOSCALL @EXITRC	; Exit DPMI (back to Real mode)

;------------------------- Real Mode ----------------------

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

; Note: Our interrupt 21 handler passes on two INT 21 functions before PM
;	Func 51 -> Get PSP address
;	Func 2F -> Get DTA address

DPMI_INT21:

	 cmp	 ah,@EXITRC	; Izit our Exit DOS call?
	 je	 DPMI_DONE	; Jump if so

	 jmp	 DOSINT_TEMP	; Jump to original INT 21 handler

DPMI_FAILURE:
	 assume  ds:PGROUP	; Tell the assembler

	 or	 RB_LCL,@LCL_DPMI_ERR ; Indicate there was a DPMI error

DPMI_DONE:

	 lss	 sp,DPMI_STACK	; Restore real mode stack
	 assume  ss:nothing	; Tell the assembler about it

; Unhook Interrupt 21h

	 REGSAVE <ds>		; Save

	 mov	 eax,DOSINT_TEMP ; Get original INT 21 vector
	 mov	 bx,INTVEC	; Gain addressability to the interrupt table
	 mov	 ds,bx		; ... via DS
	 assume  ds:INTVEC	; Tell the assembler about it

	 mov	 INT00_VEC[(type INT00_VEC)*21h],eax ; Restore INT 21h pointer

	 REGREST <ds>		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

; Restore DPMI physical -> Linear mapping status

	 test	 INFO.INFO_DB2,@DB2_DPMIPHYS ; Were P2L mappings allowed?
	 jnz	 short @F	; Jump if so

	 mov	 bx,@DB2_DPMIPHYS ; Restore P2L mappings bit
	 EMMOUT  @EMM2_DB2FLAG	; Flip bits in DB2_FLAG as marked in BX
@@:

	 test	 RB_LCL,@LCL_DPMI_ERR ; Was there an error? (CF cleared here)
	 jz	 short @F	; Jump if not

	 stc			; Indicate an error ocurred
@@:
	 popad			; Restore all EGP registers
	 REGREST <gs,fs,es,ds>	; Restore all segment registers
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_DPMI endp			; End COPY_DPMI procedure
	 NPPROC  INST15 -- Install INT 15h Handler
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

* Install an INT 15h, function 22h handler

|

	 REGSAVE <ax,bx,dx,es>	; Save registers

	 mov	 al,15h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT15_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT15_VEC.VSEG,es ; ...

;;;;;;;; mov	 al,15h 	; Intercept this one
	 DOSCALL @SETINT,INT15	; Install our own handler

	 REGREST <es,dx,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST15	 endp			; End INST15 procedure

NCODE	 ends			; End NCODE segment

	 MEND	 INITIAL	; End RAMBASIC module
