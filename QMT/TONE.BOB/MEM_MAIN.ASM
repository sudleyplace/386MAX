;' $Header:   P:/PVCS/MAX/QMT/MEM_MAIN.ASV   1.3   05 Jun 1998 14:03:24   BOB  $
	 title	 MEM_MAIN -- MEMCHK Main Routines
	 page	 58,122
	 name	 MEM_MAIN

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
	 include DOSCALL.INC
	 include ASCII.INC
	 include CMOS.INC
	 include CPUFLAGS.INC
	 include 386.INC
	 include PTR.INC
	 include VDISK.INC
	 include VIDCALL.INC
	 include VIDATTR.INC
	 include KEYCALL.INC
	 include 8259.INC
	 include EISA.INC
	 include XMS.INC
	 include BIOSDATA.INC
	 include VDS.INC
	 include BITFLAGS.INC
	 include OPEN.INC
	 include IOCTL.INC
	 include INTRNATL.INC
	 include MAC.INC
	 include DEVDRV.INC

	 include MAXDEV.INC
	 include MEM_BLK.INC
	 include MEM_DTE.INC
	 include MEM_OEM.INC
	 include MEM_SCRN.INC
	include MEM_SEGS.INC
	 include MEM_TIME.INC
.list

CODE	 segment use16 byte public 'prog' ; Start CODE segment
CODE	 ends			; End CODE segment


PROG	 segment use16 byte public 'prog' ; Start PROG segment
PROG	 ends			; End PROG segment


CODEZ	 segment use16 para public 'prog' ; Start CODEZ segment
	 assume  cs:PGROUP

	 public  CTAIL
CTAIL	 label	 byte

CODEZ	 ends			; End CODEZ segment


PSP_SEG  segment use16 at 0	; Start PSP_SEG segment
	 assume  cs:PSPGRP,ds:PSPGRP

	 public  PSP_ENVIR_PTR,PSP_TERMINATE
	 include PSP.INC

PSP_SEG  ends			; End PSP_SEG segment


STACK	 segment use16 dword stack 'data' ; Start STACK segment
	 assume  ds:DGROUP

	 public  PMSTK,PMSTKZ
PMSTK	 dw	 0FFh dup (?)	; Protected mode stack
PMSTKZ	 dw	 0		; End of ...

	 public  LCLSTK,LCLSTKZ
LCLSTK	 dw	 0FFh dup (?)	; Local stack
LCLSTKZ  dw	 0		; Top of stack

STACK	 ends			; End STACK segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	extrn	CMD_FLAG:dword
	include MEM_CMD.INC

	 extrn	 CNT_FLAG:word
	 include MEM_CNT.INC

	 extrn	 GLB_FLAG:word
	 include MEM_GLB.INC

	 extrn	 GL3_FLAG:word
	 include MEM_GL3.INC

	 extrn	 SYS_FLAG:word
	 include MEM_SYS.INC

	 extrn	 SHDSIZE:dword
	 extrn	 XSHDCNT:word
	 extrn	 XSHDTAB:tbyte
	 include MEM_SHD.INC

	 extrn	 BLK_STRS:tbyte

	 extrn	 FNGETKST:byte
	 extrn	 FNGETKEY:byte

	 extrn	 DPMIMSG:word

	 extrn	 @MSG_SMALL:abs
	 extrn	 @MSG_LARGE:abs

	 extrn	 MSG_COPY:byte
	 extrn	 MSG_NOT386:byte
	 extrn	 MSG_NOTVM:byte
	 extrn	 MSG_MULBUG:byte
	 extrn	 MSG_XMEM:byte
	 extrn	 MSG_XMEM1:byte
	 extrn	 MSG_XMEM2:byte
	 extrn	 MSG_XMEMSEED:byte
	 extrn	 MSG_CRLF:byte
	 extrn	 MSG_NOMEM:byte
	 extrn	 MSG_EISA:byte
	 extrn	 MSG_PRVEXT:byte
	 extrn	 MSG_ASKCLR:byte
	 extrn	 MSG_WIN3:byte
	 extrn	 MSG_MEMERR:byte
	 extrn	 MSG_MEMERR1:byte
	 extrn	 MSG_MEMERR_LEN:abs
	 extrn	 MSG_NMIERR:byte
	 extrn	 MSG_NMIERR1:byte
	 extrn	 MSG_NMIERR_LEN:abs
	 extrn	 MSG_NOERR:byte
	 extrn	 MSG_NOERR_LEN:abs
	 extrn	 MSG_CANCELLED:byte
	 extrn	 MSG_CANCELLED_LEN:abs

	 extrn	 ZMSG_UNLSAF:tbyte
	 extrn	 ZMSG_UNLTRN:tbyte
	 extrn	 ZMSG_UNLINV:tbyte
	 extrn	 ZMSG_UNLIDM:tbyte
	 extrn	 ZMSG_LNKINV:tbyte
	 extrn	 ZMSG_LNKIDM:tbyte

	 extrn	 ZMSG_CURPATB:tbyte
	 extrn	 ZMSG_CURPATW:tbyte
	 extrn	 ZMSG_CURPATD:tbyte

	 extrn	 ZMSG_BLK:tbyte
	 extrn	 ZMSG_ELAP:tbyte

	 extrn	 MSG_ELAP:byte
	 extrn	 MSG_ELAP_LEN:abs

	 extrn	 MEMERRCNT:word
	 extrn	 NMIERRCNT:word

	 extrn	 DDS:tbyte

	 public  CON4K,CON32K,CON64K,CON128K,CON1M,CON16M
CON4K	 dd	 00001000h	;   4K constant
CON32K	 dd	 00008000h	;  32K ...
CON64K	 dd	 00010000h	;  64K ...
CON128K  dd	 00020000h	; 128K ...
CON1M	 dd	 00100000h	;   1M ...
CON16M	 dd	 01000000h	;  16M ...

	 public  MUL_ARG1,MUL_ARG2,MUL_PROD
MUL_ARG1 dd	 00000081h
MUL_ARG2 dd	 0417A000h
MUL_PROD dq	 000000020FE7A000h

	 public  MOVE_TAB
MOVE_TAB MDTE_STR <>		; Block move structure

	 public  PHYSIZE,CMOSIZE,MAXSIZE
PHYSIZE  dd	 ?		; Top of physical extended memory in KB (fn88)
CMOSIZE  dd	 ?		; Top of physical extended memory in KB (CMOS)
MAXSIZE  dd	 ?		; Top of physical extended memory in KB (larger)

	 public  DPMIDRV_VEC
DPMIDRV_VEC dd	 ?		; Seg:Off of DPMI handler

	 public  VIDBASE_FVEC
VIDBASE_FVEC df  ?		; Ptr to screen base

	 public  DOSVER
DOSVER	 dw	 ?		; DOS version # in comparison order

	 public  TOPFILL
TOPFILL  dw	 ?		; Top of DOS value

	 public  CLRMODE
CLRMODE  dw	 ?		; Color mode:  0 = mono, 1 = B&W, 2 = color

	 public  GL2_FLAG
	 include MEM_GL2.INC
GL2_FLAG dw	 0		; Secondary global flags

	 public  CODESEG,PSPSEG
CODESEG  dw	 seg PGROUP	; Code segment paragraph
PSPSEG	 dw	 ?		; PSP segment

	 public  HPDASEG
HPDASEG  dw	 ?		; Segment of the HPDA (if DPMI host)

	 public  INT_FLAG,ARG_FLAG
INT_FLAG label	 word		; Pseudo-variable needed by SWAT_KEY.OBJ
ARG_FLAG dw	 0		; Pseudo-variable ...

	 public  MAPSEG_NXT
MAPSEG_NXT dw	 ?		; Next available para

	 public  XMSZLEN
XMSZLEN  dw	 0		; Zero-length XMS handle (0=none)

	 public  CPUTYPE
CPUTYPE  db	 ?		; CPU type: 03 = 386, 04 = 486, etc.

	 public  DPMITERM
DPMITERM db	 0		; DPMI terminate flag

	 public  XMS_QRYXMB,XMS_GETXMB,XMS_XLATFLAGS
XMS_QRYXMB db	 @XMS_QRYXMB	; Function code to query XMS memory
XMS_GETXMB db	 @XMS_GETXMB	; ...		   allocate ...
XMS_XLATFLAGS dw @TT_XMS or @TT_L2P ; SAVE_SHADOW flags (translate if VDS)

	 public  SCRNTYPE
SCRNTYPE db	 ?		; Screen type
; These values are indices into A??? values and AMAC_SYSATTR[]
@SCRN_MONO equ	 0		; Monochrome
@SCRN_BW   equ	 1		; Black & White
@SCRN_COLR equ	 2		; Color

AMAC	 macro	 name,monocolor,bwcolor,color
	 public  A&name,name&ATTR
A&name	 db	 monocolor,bwcolor,color ; Mono, B&W, and normal colors
name&ATTR db	 ?		; Current working attribute
	 endm			; AMAC

AMAC_STR struc

AMAC_SYSATTR db 3 dup (?)	; Attrs to use for monochrome, B&W, color
AMAC_WORK db	 ?		; Working color

AMAC_STR ends

	 align	 4
ATTR_TAB label dword
;	  Mono		Black&White	ForeColor	 BackColor
AMAC DEF, @ATMnorm,	@ATBWnorm,	<@ATCFFdkgray+@ATCBBdkgray> ; Attr for Default
AMAC MSG, @ATMrev,	@ATBWrev,	<@ATCFFred+@ATCBBwhite> ; Attr for messages
;;;;;;;AMAC BAR, @ATMnorm,	@ATBWnorm,	<@ATCFFwhite+@ATCBBred>
AMAC WRK, @ATMrevblink, @ATBWrevblink,	<@ATCFFred+@ATCBBwhite> ; Attr when working
AMAC ERR, @ATMrev,	@ATBWrev,	<@ATCFFyellow+@ATCBBred> ; Attr for errors
AMAC BRD, @ATMnorm,	@ATBWnorm,	<@ATCFFmagenta+@ATCBBcyan> ; Attr for border
AMAC TTL, @ATMrev,	@ATBWrev,	<@ATCFFblue+@ATCBBwhite> ; Attr for titles
AMAC CPY, @ATMrev,	@ATBWrev,	<@ATCFFwhite+@ATCBBblue> ; Attr for copyright
AMAC AAR, @ATMrev,	@ATBWrev,	<@ATCFFltgray+@ATCBBblue> ; Attr for "GNU General Public License version 3."
AMAC KEY, @ATMrev,	@ATBWrev,	<@ATCFFyellow+@ATCBBblue> ; Attr for key
AMAC KEY2,@ATMnorm,	@ATBWnorm,	<@ATCFFyellow+@ATCBBdkgray> ; Attr for keys at bottom of screen
AMAC SHD1,@ATMnorm,	@ATBWnorm,	<@ATCFFblack+@ATCBBdkgray> ; Attr for type 1 shadow
AMAC SHD2,@ATMnorm,	@ATBWnorm,	<@ATCFFltgray+@ATCBBdkgray> ; Attr for type 2 shadow
AMAC PRG, @ATMrev,	@ATBWrev,	<@ATCFFyellow+@ATCBBblue>	; Progress Screen
AMAC PRG1,@ATMhigh,	@ATBWhigh,	<@ATCFFred+@ATCBBblack> ; Active progress (solid char)
AMAC PRG2,@ATMnorm,	@ATBWnorm,	<@ATCFFblack+@ATCBBblack>	; Inactive progress (blanks)
AMAC ELEV,@ATMrev,	@ATBWrev,	<@ATCFFblack+@ATCBBltgray> ; Attr for elevator
AMAC MEM, @ATMnorm,	@ATBWnorm,	<@ATCFFblack+@ATCBBdkgray> ; Memory screen
AMAC MEMH,@ATMhigh,	@ATBWhigh,	<@ATCFFwhite+@ATCBBdkgray> ; Memory screen header line
AMAC WMEM,@ATMrev,	@ATBWrev,	<@ATCFFyellow+@ATCBBblack>	; Memory screen working line
AMAC AMEM,@ATMhigh,	@ATBWhigh,	<@ATCFFyellow+@ATCBBdkgray> ; Memory screen active line
AMAC IMEM,@ATMnorm,	@ATBWnorm,	<@ATCFFltgray+@ATCBBdkgray> ; Memory screen inactive line
AMAC EMEM,@ATMnorm,	@ATBWnorm,	<@ATCFFltgray+@ATCBBdkgray> ; Memory screen ending line (key)
AMAC TMEM,@ATMhigh,	@ATBWhigh,	<@ATCFFyellow+@ATCBBdkgray> ; Memory screen total line
AMAC HTTL,@ATMrev,	@ATBWrev,	<@ATCFFred+@ATCBBltgray> ; Attr for help titles
AMAC HLP, @ATMrev,	@ATBWrev,	<@ATCFFblue+@ATCBBltgray> ; Attr for help screen
AMAC HLPA,@ATMnorm,	@ATBWnorm,	<@ATCFFwhite+@ATCBBblack> ; Attr for active help lines
AMAC HLPB,@ATMrev,	@ATBWrev,	<@ATCFFblack+@ATCBBltgray> ; Attr for background help lines
AMAC HERR,@ATMnorm,	@ATBWnorm,	<@ATCFFyellow+@ATCBBred> ; Attr for help error screen
AMAC HKEY,@ATMnorm,	@ATBWnorm,	<@ATCFFwhite+@ATCBBdkgray> ; Attr for help keys
AMAC HLT, @ATMrev,	@ATBWrev,	<@ATCFFblue+@ATCBBltgray> ; Halt screen
AMAC ASK, @ATMrev,	@ATBWrev,	<@ATCFFyellow+@ATCBBblue>	; Ask Screen
AMAC ASKAA,@ATMnorm,	@ATBWnorm,	<@ATCFFblue+@ATCBBltgray> ; Advanced Active
AMAC ASKAB,@ATMrev,	@ATBWrev,	<@ATCFFltcyan+@ATCBBblue>	; Advanced Background
AMAC ASKMA,@ATMrev,	@ATBWrev,	<@ATCFFyellow+@ATCBBblack>	; Memory Active
AMAC ASKMB,@ATMrev,	@ATBWrev,	<@ATCFFblack+@ATCBBdkgray> ; Memory Background
AMAC ASKBA,@ATMrev,	@ATBWrev,	<@ATCFFblue+@ATCBBltgray> ; Basic Active
AMAC ASKBB,@ATMrev,	@ATBWrev,	<@ATCFFblue+@ATCBBltgray> ; Basic Background
AMAC STATT,@ATMnorm,	@ATBWhigh,	<@ATCFFwhite+@ATCBBdkgray> ; Status title
AMAC STATL,@ATMnorm,	@ATBWnorm,	<@ATCFFltcyan+@ATCBBdkgray> ; Attr for status line
AMAC BACK, @ATMnorm,	@ATBWnorm,	<@ATCFFbrown+@ATCBred> ; Background
AMAC DLGB, @ATMrev,	@ATBWrev,	<@ATCFFwhite+@ATCBBcyan> ; Dialog box fill and border
AMAC DLGBTN, @ATMnorm,	@ATBWnorm,	<@ATCFFblack+@ATCBBltgray> ; Button (normal)
AMAC DLGABTN, @ATMrev,	@ATBWrev,	<@ATCFFwhite+@ATCBBltgray> ; Button (highlighted)
AMAC DLGBHK, @ATMrev,	@ATBWrev,	<@ATCFFblue+@ATCBBltgray> ; Button hotkey
AMAC DLGABHK, @ATMhigh, @ATBWhigh,	<@ATCFFwhite+@ATCBBltgray> ; Button hotkey highlight
AMAC DLGRBHK, @ATMhigh, @ATCFFyellow,	<@ATCFFred+@ATCBBltgray> ; Radio button hotkey
AMAC DLGTHK, @ATMhigh,	@ATCFFyellow,	<@ATCFFred+@ATCBBcyan> ; Title hotkey highlight
AMAC DLGEH, @ATMnorm,	@ATBWnorm,	<@ATCFFwhite+@ATCBBblue> ; Edit highlight
AMAC DLGEN, @ATMnorm,	@ATBWnorm,	<@ATCFFblack+@ATCBBltgray> ; Edit normal
AMAC DLGEF, @ATMrev,	@ATBWrev,	<@ATCFFwhite+@ATCBBltgray> ; Edit normal with focus
AMAC DIS, @ATMblack,	@ATCFFblue,	<@ATCFFltgray+@ATCBBdkgray> ; Disabled text attributes
@AMAC_CNT equ ($-ATTR_TAB)/(size AMAC_STR)


	 public  STATATTR,STATHATTR
STATATTR equ	 MEMATTR+0	; Attr for status screen
STATHATTR equ	 MEMHATTR+0	; Attr for status header


	 public  VIDMODE1,VIDMODE2
VIDMODE1 db	 ?		; Original video mode
VIDMODE2 db	 ?		; New video mode

	 public  MAXNAME
MAXNAME  db	 '386MAX$$',0   ; Device name for 386MAX/BlueMAX

	 public  PROT_NAME
PROT_NAME db	 'PROTMAN$',0   ; Name of PROTMAN device

	 public  CONSOLE
CONSOLE  db	 'CON',0        ; Name of the console device

DATA	 ends			; End DATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DATAZ	 segment use16 para public 'dataz' ; Start DATAZ segment
	 assume  ds:DGROUP

	 extrn	 MAX_FLAG:dword

DATAZ	 ends			; End DATAZ segment


IDENT	 segment use16 dword public 'dataz' ; Start IDENT segment
	 assume  ds:DGROUP

	 extrn	 ZTAIL:byte

IDENT	 ends			; End IDENT segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 ACTA20_COMSUB:word

	 extrn	 A20COM_XMS:near
	 extrn	 ENTER_PM:near
	 extrn	 CHECK_SYS:near
	 extrn	 CHECK_ARGS:near
	 extrn	 BIN2DEC:near
	 extrn	 BIND2DEC:near
ifndef @RAMDEMO
	 extrn	 CHECK_INFO:near
endif

	 extrn	 SAVE_XSHADOW:near
	 extrn	 CHECK_SWAT:near
	 extrn	 CHECK_VCPI:near
	extrn	RMPAGE:near

	 extrn	 CLEAR_STATLIN:near

	 public  DATASEG
DATASEG  dw	 seg DGROUP	; Data segment paragraph

	 public  MD_FLAG
MD_FLAG  dd	 ?		; Flags from MAX_FLAG addressible from CS

	 public  XMSDRV_VEC
XMSDRV_VEC dd	 ?		; Seg:Off of XMS handler

	 NPPROC  MEMCHK -- Memory Checker
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 mov	 es,DATASEG	; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 PSPSEG,ds	; Save for later use

	 mov	 ds,DATASEG	; Address it
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 ss,DATASEG	; Address it
	 lea	 sp,LCLSTKZ	; Switch to local stack

; Reset the next segment value

	call	REMAPSEG_NXT	; Reset it

	 DOSCALL @STROUT,MSG_COPY ; Display the flag

	 DOSCALL @DOSVER	; Get DOS version #
				; Return with
				; AL=major
				; AH=minor
				; BX=CX=0
	 xchg	 al,ah		; Swap to comparison order

	 mov	 DOSVER,ax	; Save for later use

; Determine whether or not standard output is redirected

	 mov	 bx,@STD_OUT	; Copy to handle register
	 mov	 al,0		; Code to read device information
	 DOSCALL @IOCTL2	; Read I/O control
	 jc	 short @F	; Jump on error

	 and	 dx,@IOCTL_DEV or @IOCTL_COT ; Isolate device output bits

	 cmp	 dx,@IOCTL_DEV or @IOCTL_COT ; Izit standard output?
	 jne	 short @F	; Jump if not

	 or	 CMD_FLAG,@CMD_STDOUT ; Mark as standard output
@@:
	 call	 CHECK_CPUID	; Ensure we're on a 386 processor
	 jc	 short MEMCHK_ERR ; Jump if something went wrong

ifndef @RAMDEMO
	 call	 CHECK_INFO	; Check and display IDN info
	 jc	 short MEMCHK_ERR ; Jump if something went wrong
endif
	 call	 CHECK_KEYB	; Determine keyboard type

	 call	 CHECK_PHYS	; See how much physical memory there is

	 call	 CHECK_SWAT	; See if SWAT is present

	 call	 CHECK_MAX	; See if 386MAX is active

	 call	 CHECK_XMSDRV	; Check on XMS driver

	 call	 CHECK_VM86	; Ensure no V86 mode monitor w/o DPMI/VCPI
	 jc	 short MEMCHK_ERR ; Jump if something went wrong

	 call	 CHECK_MULBUG	; Check for 386 multiply bug
	 jc	 short MEMCHK_ERR ; Jump if something went wrong

	 call	 CHECK_VDS	; See if there's a VDS server present

	 call	 CHECK_ARGS	; Check on command line arguments
	 jc	 short MEMCHK_ERR ; Jump if something went wrong, or if
				; we're not scheduled for execution yet.

	 call	 CHECK_WIN3	; See if Windows 3.x is active
	 jc	 short MEMCHK_ERR ; Jump if it is

	 call	 CHECK_SYS	; Check for various systems

	 call	 CHECK_CNV	; Check on conventional memory usage

	 call	 CHECK_XMS	; Check on XMS memory usage

	 call	 CHECK_XMEM	; Check on extended memory usage
	 jc	 short MEMCHK_ERR ; Jump if something went wrong

	 call	 CHECK_PRVEXT	; Check on preceding extended memory usage
	 jc	 short MEMCHK_ERR ; Jump if something went wrong

	 call	 CHECK_SCRN	; Check on Color vs. B&W

	 call	 ENTER_PM	; Enter protected mode

	 call	 DISP_EXIT	; Display message upon exit as appropriate
MEMCHK_ERR:
	 call	 GIVEBACK	; Give back any resources allocated

	 mov	 al,0		; Zero error return
	 DOSCALL @EXITRC	; Return to DOS

	assume	ds:PGROUP	; Make QLINK happy

	 public  OLDINT15_VEC,OLDINT22_VEC
OLDINT15_VEC dd  ?		; Save area for INT 15h handler
;;;;;;;OLDINT21_VEC dd	?	; ...		    21h ...
OLDINT22_VEC dd  ?		; ...		    22h ...

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MEMCHK	 endp			; End MEMCHK procedure
	NPPROC	REMAPSEG_NXT -- Reset Next Segment Value
	assume	ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Reset next segment value

|

	REGSAVE <ax,cx> 	; Save registers

	mov	MAPSEG_NXT,ds	; Save as frame base of DATAZ
	lea	ax,ZTAIL	; Get offset of next available byte
	mov	cl,4-0		; Shift amount between bytes to paras
	shr	ax,cl		; Convert from bytes to paras
	add	MAPSEG_NXT,ax	; Add to get next available para

	REGREST <cx,ax> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REMAPSEG_NXT endp		; End REMAPSEG_NXT procedure
	 NPPROC  CHECK_CPUID -- Check On CPU Identifier
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure we're running on an 80386 processor.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,dx>	; Save registers

	 push	 sp		; First test for a 286/386
	 pop	 ax

	 cmp	 ax,sp		; Same?
	 jne	 short CHECK_CPUID_ERR ; No, it's neither a 286 nor a 386

; Now distinguish 286 from 386

	 pushf			; Save flags for a moment

	 mov	 ax,mask $IOPL	; Try to set IOPL bits in flag register

	 push	 ax
	 popf

	 pushf			; Get flags back into AX
	 pop	 ax

	 popf			; Restore original flags

	 test	 ax,mask $IOPL	; Any bits set?
	 jz	 short CHECK_CPUID_ERR ; Jump if not (that's an error

	 mov	 CPUTYPE,03h	; It's at least a 386

; Now distinguish a 386 from a 486

	 call	 IZIT486	; Izit a 486?
	 jnc	 short @F	; Jump if not

	 mov	 CPUTYPE,04h	; Mark as at least a 486
@@:
	 clc			; Indicate all went well

	 jmp	 short CHECK_CPUID_EXIT ; Join common exit code

CHECK_CPUID_ERR:
	 DOSCALL @STROUT,MSG_NOT386 ; Tell 'em the bad news

	 stc			; Indicate we have a problem
CHECK_CPUID_EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPUID endp		; End CHECK_CPUID procedure
	 NPPROC  IZIT486 -- Determine Presence of 486
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

The test for 386 vs. 486 or later is done by attempting to set the
Alignment Check bit in the high-order word of the extended flag dword.
If that's successful, it's a 486 or later; otherwise, it's a 386.

On exit:

CF	 =	 0 if it's a 386
	 =	 1 if it's a 486

|

	 push	 bp		; Save to align stack
	 mov	 bp,sp		; Save original stack pointer

	 and	 esp,(0FFFFh and (not (4-1))) ; Align on a dword boundary in
				; case we're in V86 mode and $AM is set in CR0
				; Also clear upper word of ESP

	 push	 eax		; Save to use as scratch
	 pushfd 		; Save original flags

	 pushfd 		; Save original flags
	 or	 [esp].EHI,mask $AC ; Set Alignment Check bit
	 popfd			; Put into effect

	 pushfd 		; Put onto the stack
	 pop	 eax		; Copy to register

	 test	 eax,(mask $AC) shl 16 ; Izit still set?
	 jnz	 short @F	; Yes, so it's a 486

	 popfd			; Restore original flags

	 clc			; Indicate it's a 386

	 jmp	 short IZIT486_EXIT ; Join common code

@@:
	 popfd			; Restore original flags

	 stc			; Indicate it's a 486
IZIT486_EXIT:
	 pop	 eax		; Restore

	 mov	 sp,bp		; Restore original pointer
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT486  endp			; End IZIT486 procedure
	 NPPROC  CHECK_KEYB -- Check On Keyboard Type
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Determine the keyboard type (enhanced or not).

If it's an enhanced keyboard, assume enhanced BIOS.

If not, check for enhanced BIOS - an enhanced BIOS connected to an
84-key keyboard may not return combinations like Alt-TAB unless we
use the extended keyboard calls.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,es> ; Save registers

	 mov	 ax,seg BIOSDATA ; Get segment of BIOS data area
	 mov	 es,ax		; Address it
	 assume  es:BIOSDATA	; Tell the assembler about it

	 test	 KB_FLAG_3,mask $KB3_ENH ; Izit an enhanced keyboard?
	 jnz	 short CHECK_KEYB_EXT ; Jump if so (assume enhanced BIOS)

; No enhanced keyboard, but we may want to use the extended functions
; to get Alt-TAB.  This is identical to the user interface code we
; use to determine if we have BOTH an enhanced keyboard and enhanced
; Int 16h BIOS.

; Get the current keyboard contents and save on the stack.
	 sub	 cx,cx		; Nothing currently in the buffer

	 cli			; Nobody move
@@:
	 KEYCALL @GETKST	; Return ZF=1 if empty
	 jz	 short @F	; Jump if empty

	 KEYCALL @GETKEY	; Remove from buffer
	 inc	 cx		; Count in another one
	 push	 ax		; Save keycode
	 jmp	 short @B	; Go around again

@@:
	 push	 cx		; Save count of keycodes on stack

; Try to stuff and read back a bogus keycode (-1).
	 mov	 cx,-1		; Keycode to stuff
	 mov	 ax,@PUTKEY*100h + 0ffh ; Put into buffer
	 KEYCALL		; Return AL=0 if success

	 cmp	 al,1		; Did we succeed?
	 jnc	 short @F	; Jump if not (note CF=0)

	 KEYCALL @EXTKST	; Extended keycode read (non-destructive)
	 setz	 al		; AL=0 if we have something
	 cmp	 al,1		; Did the put succeed?
	 jnc	 short @F	; Jump if not (note CF=0)

	 KEYCALL @EXTKEY	; Extended keycode read
	 add	 ax,1		; CF=1 if AX=-1
@@:
	 pushf			; Save results of test
	 pop	 bx		; ...in BX

; Strip count and saved keycodes (if any) from stack
	 pop	 dx		; Number of keycodes to put back
	 or	 dx,dx		; Are there any?
	 jz	 short CHECK_KEYB_STRIP ; Jump if not

@@:
	 pop	 cx		; Get keycode to stuff
	 KEYCALL @PUTKEY	; Stuff CX into buffer
	 dec	 dx		; Adjust loop counter
	 jnz	 short @B	; Go around again if not done

CHECK_KEYB_STRIP:
	 sti			; Enable interrupts

	 test	 bx,mask $CF	; Do we have extended BIOS functions?
	 jz	 short CHECK_KEYB_EXIT ; Jump if not

CHECK_KEYB_EXT:
	 mov	 FNGETKST,@EXTKST ; Use extended functions
	 mov	 FNGETKEY,@EXTKEY ; ...
CHECK_KEYB_EXIT:
	 REGREST <es,dx,cx,bx,ax> ; Restore
	 assume  es:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_KEYB endp 		; End CHECK_KEYB procedure
	 NPPROC  CHECK_DEV -- Check for device
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return CF=1 if device exists.

On entry:
DS:DX ==> Device name

On exit:
CF=1	 Exists and is a device
CF=0	 Doesn't exist or isn't a device

|

	 REGSAVE <ax,bx,dx>	; Save

	 mov	 al,@OPEN_R	; Code for read-only access
	 DOSCALL @OPENF2	; Open it
	 jc	 short CHECK_DEV_EXIT ; Jump if no luck

	 mov	 bx,ax		; Save handle

	 mov	 al,0		; Code to get device info
	 DOSCALL @IOCTL2	; Read device info
	 pushf			; Save CF from call
	 DOSCALL @CLOSF2	; Close the file
	 popf			; Restore CF
	 jc	 short CHECK_DEV_EXIT ; Jump if something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jnz	 short CHECK_DEV_EXIT ; Jump if so (note CF=0)

	 stc			; Not a device
CHECK_DEV_EXIT:
	 cmc			; Set CF if success

	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_DEV endp			; End CHECK_DEV procedure
	NPPROC	CHECK_VM86 -- Check On Virtual 8086 Mode
	assume	ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if there's another VM86 monitor running.
If so, it must support VCPI or (if it's MAX) DPMI.

Because of the way DPMI handles NMI, we're slightly better off
using VCPI than DPMI services, hence the preference for VCPI.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise.

|

	pusha			; Save all GP registers
	REGSAVE <es>		; Save register

; Reset the next segment value

	call	REMAPSEG_NXT	; Reset it

	test	CMD_FLAG,@CMD_NOVCPI ; Should we ignore VCPI services?
	jnz	short CHECK_VM86_NOVCPI ; Jump if so

; See if there's a VCPI host available

	call	CHECK_VCPI	; Izit available?
	jnc	short CHECK_VM86_EXIT ; Jump if so
CHECK_VM86_NOVCPI:
	test	CMD_FLAG,@CMD_NODPMI ; Should we ignore DPMI services?
	jnz	short CHECK_VM86_NODPMI ; Jump if so

; Through the school of hard knocks, we now know that we can't
; trust anyone else's DPMI support.  QEMM, NETROOM, and DR DOS
; all fail in some way on which our use of DPMI depends.  If it's
; not MAX, we won't use DPMI.

	test	GL2_FLAG,@GL2_MAX ; Izit 386MAX?
	jz	short CHECK_VM86_NODPMI ; Jump if not

	mov	ax,1687h	; Function code to check DPMI presence
	int	2Fh		; Request multiplexor service
				; Return with BX = flags
				;	      CL = processor type
				;	      DX = DPMI version #
				;	      SI = # paras for HPDA
				;	      ES:DI ==> switch entry point
	or	ax,ax		; Izit present?
	jnz	short CHECK_VM86_NODPMI ; Jump if not

	mov	DPMIDRV_VEC.VOFF,di ; Save for later use
	mov	DPMIDRV_VEC.VSEG,es ; ...

	mov	ax,MAPSEG_NXT	; Get next available segment
	mov	HPDASEG,ax	; Save for later use
	add	MAPSEG_NXT,si	; Skip over it

	mov	es,PSPSEG	; Address PSP
	assume	es:PSPGRP	; Tell the assembler about it

	mov	ax,PSP_TERMINATE.VSEG ; Copy the segment
	mov	bx,PSP_TERMINATE.VOFF ; ...	 offset

	mov	es,CODESEG	; Setup alias to code segment
	assume	es:PGROUP	; Tell the assembler about it

	mov	OLDINT22_VEC.VOFF,bx ; Save for later use
	mov	OLDINT22_VEC.VSEG,ax ; ...

	or	GL2_FLAG,@GL2_DPMI ; Mark as using DPMI services to enter PM

	clc			; Mark as successful

	jmp	short CHECK_VM86_EXIT ; Join common exit code

CHECK_VM86_NODPMI:
	smsw	ax		; Get machine status word

	test	ax,mask $PE	; Check the Protect Enable bit
	jnz	short CHECK_VM86_ERR ; Jump if VM86 running

	call	RMPAGE		; Setup RM page tables

	clc			; Mark as successful

	jmp	short CHECK_VM86_EXIT ; Join common exit code

CHECK_VM86_ERR:
	DOSCALL @STROUT,MSG_NOTVM ; Tell 'em the bad news

	stc			; Indicate we have a problem
CHECK_VM86_EXIT:
	REGREST <es>		; Restore
	assume	es:DGROUP	; Tell the assembler about it
	popa			; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VM86 endp 		; End CHECK_VM86 procedure
	 NPPROC  CHECK_MULBUG -- Check for 386 Multiply Bug
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for 386 multiply bug.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise.

|

	 REGSAVE <eax,cx,edx>	; Save registers

	 mov	 cx,8000h	; Set iteration count
CHECK_MULBUG_NEXT:
	 mov	 eax,MUL_ARG1	; Get first argument
	 mul	 MUL_ARG2	; Times second argument

	 cmp	 edx,MUL_PROD.EDQHI ; Check high-order dword
	 jne	 short CHECK_MULBUG_ERR ; Not this time, so that's an error

	 cmp	 eax,MUL_PROD.EDQLO ; Check low-order dword
	 loope	 CHECK_MULBUG_NEXT ; Jump if equal and more iterations
	 je	 short CHECK_MULBUG_EXIT ; Jump if all went well (note CF=0)
CHECK_MULBUG_ERR:
	 DOSCALL @STROUT,MSG_MULBUG ; Tell 'em the bad news

	 stc			; Indicate something went wrong
CHECK_MULBUG_EXIT:
	 REGREST <edx,cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_MULBUG endp		; End CHECK_MULBUG procedure
	 NPPROC  CHECK_VDS -- See If There Is A VDS Server Present
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if there's a VDS server present.

|

	 REGSAVE <ax,dx,di,es>	; Save registers

; If neither a DPMI nor VCPI host is present, we're starting from RM
; and VDS services are not needed.  Moreover, we must not use such
; services in case there's an AOX card in the system providing VDS
; services as it returns bus physical data (and furthermore, it isn't
; always reliable).

	 test	 GL2_FLAG,@GL2_DPMI or @GL2_VCPI ; Is either host available?
	 jz	 short CHECK_VDS_EXIT ; Jump if not (we're starting from RM)

	 push	 seg BIOSDATA	; Get segment of BIOS data area
	 pop	 es		; Address it
	 assume  es:BIOSDATA	; Tell the assembler about it

	 test	 VDS,@VDS_ENA	; Izit present?
	 jz	 short CHECK_VDS_EXIT ; Jump if not

COMMENT|

Even though there appears to be a VDS server, that's not enough for us
to use it.  As it turns out, EMM386.SYS that ships with DR-DOS doesn't
correctly handle VDS calls at 4MB.  In particular, at 4MB+4KB, they
return a physical address of zero.  I can't seem to find a way to
detect them directly, so here we'll make such a call and if it returns
bogus data, we'll do without VDS.

|

	 push	 ds		; Get segment of DDS
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 DDS.DDS_SIZE,4*1024 ; Save as size in bytes
	 mov	 DDS.DDS_FVEC.FOFF,4*1024*1024+4*1024 ; Save as linear offset
	 mov	 DDS.DDS_FVEC.FSEL,0 ; Save as segment/selector
	 mov	 DDS.DDS_POFF,-1 ; Use non-zero value

	 lea	 di,DDS 	; ES:DI ==> DDS struc
	 xor	 dx,dx		; Clear flags
	 VDSCALL @VDS_LOCK	; Lock the DMA region
	 jc	 short CHECK_VDS_EXIT ; Jump if something went wrong

	 cmp	 DDS.DDS_POFF,0 ; Izit physical address zero?
	 je	 short CHECK_VDS_EXIT ; Jump if so (that's bogus)

	 or	 GLB_FLAG,@GLB_VDS ; Mark as VDS server present
CHECK_VDS_EXIT:
	 REGREST <es,di,dx,ax>	; Restore
	 assume  es:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VDS endp			; End CHECK_VDS procedure
	 NPPROC  CHECK_PHYS -- See How Much Physical Memory There Is
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See how much physical memory there is.

|

	REGSAVE <eax,bx,cx,edx> ; Save registers

; See if COMPAQ/Phoenix/maybe others memory function works

	xor	cx,cx		; Set to known value
	xor	dx,dx		; ...
	mov	ax,0E801h	; Get function code to return extended memory
	int	15h		; Request BIOS service
				; Return AX = installed extmem in 1KB up to 16MB
				; ...	 BX = ..		 64KB above 16MB
				; ...	 CX = configured extmem in 1KB up to 16MB
				; ...	 DX = ..		 64KB above 16MB
	jcxz	@F		; Jump if not supported

	movzx	eax,cx		; Get extended memory up to 16MB in 1KB
	movzx	edx,dx		; Zero to use as dword
	shl	edx,16-10	; Convert from 64KB to 1KB
	add	eax,edx 	; Plus extmem up to 16MB

	jmp	short CHECK_PHYS1 ; Join common code

@@:

; See if the AMI BIOS PCI Memory Function works

	mov	ax,0DA88h	; Get function code to return extended memory
	int	15h		; Request BIOS service
				; Return extended memory in CL:BX, AX=0
	cmp	ax,0		; Did it work?
	jne	short @F	; Jump if not

	mov	al,cl		; Copy the high-order byte (AH already zero)
	shl	eax,16		; Shift to high-order word
	mov	ax,bx		; Copy low-order word

	jmp	short CHECK_PHYS1 ; Join common code

@@:

; Get size of extended memory from BIOS

	 mov	 ah,88h 	; Function code to get size of extended memory
	 int	 15h		; Request service, result in AX in 1KB blocks

	 movzx	 eax,ax 	; Zero to use as dword
CHECK_PHYS1:
	 and	 eax,not (4-1)	; Round down to a multiple of four
	 add	 eax,1024	; Plus first megabyte
	 mov	 PHYSIZE,eax	; Save for later use

; Get size of extended memory from CMOS

	 test	 MAX_FLAG,@MD_XT ; Running on an XT?
	 jnz	 short CHECK_PHYS_EXIT ; Jump if so

	 cli			; Disallow interrupts
	 xor	 eax,eax	; Zero to use as dword

	 mov	 al,@CMOS_EXTHI ; Get extended memory size, high-order byte
	 out	 @CMOS_CMD,al	; Tell the CMOS about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@CMOS_DATA	; Get the data byte
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 ah,al		; Copy to high-order byte

	 mov	 al,@CMOS_EXTLO ; Get extended memory size, low-order byte
	 out	 @CMOS_CMD,al	; Tell the CMOS about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@CMOS_DATA	; Get the data byte
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 sti			; Allow interrupts

	 add	 eax,1024	; Plus first megabyte

	 mov	 CMOSIZE,eax	; Save for later use

; Save the larger for later use

	 cmp	 eax,PHYSIZE	; Is CMOS larger?
	 jae	 short @F	; Jump if so

	 mov	 eax,PHYSIZE	; Use PHYSIZE
@@:
	 mov	 MAXSIZE,eax	; Save for later use
CHECK_PHYS_EXIT:
	REGREST <edx,cx,bx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PHYS endp 		; End CHECK_PHYS procedure
	 NPPROC  CHECK_MAX -- See If 386MAX Is Active
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if 386MAX is active.

|

	 REGSAVE <dx>		; Save registers

	 lea	 dx,MAXNAME	; Device name for 386MAX
	 call	 CHECK_DEV	; See if it's a device
	 jnc	 short CHECK_MAX_EXIT ; Jump if not

	 or	 GL2_FLAG,@GL2_MAX ; Mark as present
CHECK_MAX_EXIT:
	 REGREST <dx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_MAX endp			; End CHECK_MAX procedure
	 NPPROC  CHECK_XMSDRV -- See If XMS Driver Present
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if there's an XMS driver present.

|

	 REGSAVE <ax,bx,dx,es>	; Save registers

; See if there is a XMS handler

	 mov	 ax,4300h	; Function code to detect presence
	 int	 2Fh		; Request multiplexor service

	 cmp	 al,80h 	; Izit installed?
	 jne	 short CHECK_XMSDRV_EXIT ; Jump if not

	 mov	 ax,4310h	; Function code to request entry point
	 int	 2Fh		; Request multiplexor service
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es		; Copy the segment

	 mov	 es,CODESEG	; Setup alias to code segment
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 XMSDRV_VEC.VOFF,bx ; Save for later use
	 mov	 XMSDRV_VEC.VSEG,ax ; ...

	 or	 GL3_FLAG,mask $GL3_A20SET ; Mark as found
	 mov	 ACTA20_COMSUB,offset PGROUP:A20COM_XMS ; Save routine addr
	 or	 GLB_FLAG,@GLB_XMS ; Mark as present

; In case we're under a memory manager in AUTO mode, allocate
; a zero-length XMS handle to put it into VM.

	 xor	 dx,dx		; Size of request in kilobytes
	 mov	 ah,@XMS_GETXMB ; Function code to allocate XMS memory
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Did it work?
	 jne	 short @F	; Jump if not

	 mov	 XMSZLEN,dx	; Save to free later
@@:
CHECK_XMSDRV_EXIT:
	 REGREST <es,dx,bx,ax>	; Restore
	 assume  es:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_XMSDRV endp		; End CHECK_XMSDRV procedure
	 NPPROC  CHECK_CNV -- Check on Conventional Memory Usage
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on conventional memory usage.

|

	 REGSAVE <eax,ebx>	; Save registers

	 call	 GET_TOPDOS	; Return with EBX = segment of the top of DOS
	 shl	 ebx,4-0	; Convert from paras to bytes

	 movzx	 eax,MAPSEG_NXT ; Get the next available segment
	 shl	 eax,4-0	; Convert from paras to bytes

	 sub	 ebx,eax	; Subtract to get length above us in bytes
	 jbe	 short CHECK_CNV_EXIT ; Jump if we allocated too much for SWAT

; Store the conventional below us and mark it as unallocated

	 push	 @TT_L2P or @TT_UNALL ; Pass flags (needs translation if VDS
				; present, and it's unallocated)
	 PUSHD	 -1		; Pass handle # (-1=none)
	 push	 eax		; Amount of conventional memory in bytes
	 PUSHD	 0		; ...at this physical location
	 PUSHD	 0		; ...at this linear location
	 call	 SAVE_XSHADOW	; Append to shadow RAM structures

; Allocate conventional memory above us and lock it

	 push	 @TT_L2P	; Pass flags (needs translation if VDS present)
	 PUSHD	 -1		; Pass handle # (-1=none)
	 push	 ebx		; Amount of conventional memory in bytes
	 push	 eax		; ...at this physical location
	 push	 eax		; ...at this linear location
	 call	 SAVE_XSHADOW	; Append to shadow RAM structures
CHECK_CNV_EXIT:
	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CNV endp			; End CHECK_CNV procedure
	 NPPROC  GET_TOPDOS -- Get Segment of Top of DOS
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get the segment of the top of DOS.
Take into consideration ugly things such as PROTMAN$.

On exit:

EBX	 =	 segment of the top of DOS

|

	 REGSAVE <ax,cx,dx,si,di,es> ; Save registers

	 push	 ds		; Save for a moment

	 mov	 ds,PSPSEG	; Address the PSP
	 assume  ds:PSPGRP	; Tell the assembler about it

	 mov	 ax,PSP_STOR_MAX ; Get the next available para

	 pop	 ds		; Restore
	 assume  ds:DGROUP	; Tell the assembler about it

	 mov	 TOPFILL,ax	; Save as initial top fill value

	 mov	 al,01h 	; Access code for read
	 DOSCALL @OPENF2,PROT_NAME ; Attempt to open device driver
	 jnc	 short TFC_PROT1 ; Jump if open succeeded

; LANMAN remote boot- this is a four-letter word.  PROTMAN's there, but
; DOS doesn't know about it.  However, the Int FD vector points to a
; PROTMAN$ device header...

	 sub	 ax,ax		; Vector of IVT
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 les	 di,es:[0FDh*4].EDD ; Get suspected PROTMAN$ header address
	 assume  es:nothing	; Tell the assembler

	 int	 12h		; Get RAM size in AX
	 mov	 cl,10-4	; K to para conversion factor
	 shl	 ax,cl		; Convert to paragraphs
	 mov	 bx,es		; Get PROTMAN$ address
	 cmp	 bx,ax		; Izit above the top of DOS?
	MJ b	 TFC_EXIT	; Jump if not

	 mov	 cx,8		; Bytes to compare
	 lea	 di,[di].DD_NAME ; Address device name
	 lea	 si,PROT_NAME	; 'PROTMAN$'
    repe cmps	 PROT_NAME,es:[di].DD_NAME ; Compare 'em
	 je	 short TFC_PROTMAN ; You can run but you can't hide...

; Check for NetW in interrupt F1 vector

	 sub	 ax,ax		; Vector of IVT
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 cmp	 es:[0F1h*4].ELO,'eN' ; Does low word compare?
	MJ ne	 TFC_EXIT	; Jump if not

	 cmp	 es:[0F1h*4].EHI,'Wt' ; Does high word compare?
	MJ ne	 TFC_EXIT	; Jump if not

; Netware remote boot loaders allocate 64K at the top of DOS, so
; COMMAND.COM will load below it.

	 mov	 ax,cs		; Get segment
	 dec	 ax		; Back off to MAC entry
	 mov	 es,ax		; Address MAC entry
	 assume  es:nothing	; Tell the assembler

	 add	 ax,es:[0].MAC_NPAR ; Skip to end of region - 1 para
	 sub	 ax,(1000h-1)	; Back off by 64K - 1 para

	 jmp	 short TFC_REDUCE ; Join common code

TFC_PROT1:
	 mov	 bx,ax		; Copy to handle register

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 pushf			; Save status
	 DOSCALL @CLOSF2	; Close the device driver
	 popf			; Restore status
	 jc	 short TFC_EXIT ; Something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 short TFC_EXIT ; Nope, go
TFC_PROTMAN:
	 int	 12h		; Get RAM size in AX
	 mov	 cl,10-4	; K to para conversion factor
	 shl	 ax,cl		; Convert to paragraphs

; If it's a newer PROTMAN and we're loading an end-loader like NET START,
; we don't need to reduce TOPFILL at all.  Check for
; 1. A MAC entry above the memory allocated to us,
; 2. with an owner of 0008h,
; 3. with a size of at least 32K,
; 4. and ending below the Int 12h top of DOS.
; If we find such a beast, leave TOPFILL alone.

	 mov	 bx,cs		; Get our PSP
	 dec	 bx		; Back off to our MAC entry
	 mov	 es,bx		; Address it
	 assume  es:nothing	; Tell the assembler

	 cmp	 bx,ax		; Are we in low DOS?
	 jnb	 short TFC_PROTMAN2 ; Jump if not

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit the last entry?
	 je	 short TFC_PROTMAN2 ; Jump if so

	 add	 bx,es:[0].MAC_NPAR ; Skip our memory
	 inc	 bx		; Skip MAC entry
	 mov	 es,bx		; Address next MAC
	 assume  es:nothing	; Tell the assembler

	 add	 bx,es:[0].MAC_NPAR ; Skip PROTMAN's (alleged) allocation
	 inc	 bx		; Skip MAC entry
	 cmp	 bx,ax		; Does it end at or below the top of low DOS?
	 ja	 short TFC_PROTMAN2 ; Jump if not

	 cmp	 es:[0].MAC_OWNR,0008h ; Izit PROTMAN's magic owner value?
	 jne	 short TFC_PROTMAN2 ; Jump if not

	 cmp	 es:[0].MAC_NPAR,0800h ; Izit at least 32K in length?
	 jnb	 short TFC_EXIT ; Jump if so - PROTMAN is (probably) protected
TFC_PROTMAN2:
	 cmp	 DOSVER,0500h	; Izit DOS 5.00?
	 jb	 short TFC_REDUCE ; No

	 UMIN	 ax,TOPFILL	; If TOPFILL is already reduced, use the
				; request header input value.
	 UMIN	 ax,8000h	; Make sure it's <= 6000h below
TFC_REDUCE:
	 sub	 ax,02000h	; Maximum top fill value for LanMan 2.0

	 UMIN	 TOPFILL,ax	; Set New TOPFILL value if lower
TFC_EXIT:
	 movzx	 ebx,TOPFILL	; Return to caller in EBX

	 REGREST <es,di,si,dx,cx,ax> ; Restore
	 assume  es:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_TOPDOS endp 		; End GET_TOPDOS procedure
	 NPPROC  CHECK_XMS -- Check on XMS Memory Usage
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on XMS memory usage.

|

	 REGSAVE <eax,bx,ecx,edx,esi>  ; Save registers

	 test	 GLB_FLAG,@GLB_XMS ; Izit present?
	 jz	 near ptr CHECK_XMS_EXIT ; Jump if not

; If we're in RM or VCPI, allocate all XMS memory and include it
; as shadow memory.
; That way, we can use RM to PM switch and then test it.
; If we're in VM, we'll allocate memory from DPMI/PM.

	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jnz	 near ptr CHECK_XMS_EXIT ; Jump if so

	 mov	 ah,@XMS_REQHMA ; Attempt to get the HMA (and thus 1MB to 1.1MB)
	 mov	 dx,-1		; Mark as an application
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Did it succeed?
	 jne	 short @F	; Jump if not

	 or	 GLB_FLAG,@GLB_HMA ; Mark as allocated
	 add	 PHYSIZE,64	; Account for it
@@:

; If there's an XMS 3.0 handler present, use the extended services

	 mov	 ah,@XMS_VERS	; Function code to get XMS version #
	 call	 XMSDRV_VEC	; Request XMS service
				; AX = XMS version (0300h)
				; BX = MAX version (0701h) if @GL2_MAX

	 cmp	 ax,0300h	; Izit version 3.0 or above?
	 jb	 short CHECK_XMS_X30 ; Jump if so

	 mov	 XMS_QRYXMB,@XMS_QRY2XMB ; Use extended services
	 mov	 XMS_GETXMB,@XMS_GET2XMB ; ...

; If 386MAX is providing XMS services, @XMS_LCKXMB returns linear
; address.
	 test	 GL2_FLAG,@GL2_MAX ; Is 386MAX the XMS provider?
	 jnz	 short CHECK_XMS_X30 ; Jump if so

	 and	 XMS_XLATFLAGS,not @TT_L2P ; No VDS translation needed
CHECK_XMS_X30:

; Allocate XMS memory until there's no more

CHECK_XMS_NEXT:
	 xor	 eax,eax	; Zero to use as dword
	 mov	 ah,XMS_QRYXMB	; Function code to query XMS memory
	 call	 XMSDRV_VEC	; Request XMS service
				; Return with eAX = size of largest free
				;	      eDX = total amount
	 and	 eax,eax	; Is any XMS memory available?
	 jnz	 short CHECK_XMS1 ; Jump if so

; Thanks to a bug in DRDOS 7, we need to be careful about
; what this function returns.  DRDOS 7 claims to implement
; XMS version 3.00 services, but they return error code 80h
; (not implemented) for this extended function.

	 cmp	 bl,80h 	; Izit not implemented?
	 jne	 short CHECK_XMS_EXIT ; Jump if not

	 mov	 XMS_QRYXMB,@XMS_QRYXMB ; Use distended services
	 mov	 XMS_GETXMB,@XMS_GETXMB ; ...

	 xor	 eax,eax	; Zero to use as dword
	 mov	 ah,XMS_QRYXMB	; Function code to query XMS memory
	 call	 XMSDRV_VEC	; Request XMS service
				; Return with eAX = size of largest free
				;	      eDX = total amount
	 and	 eax,eax	; Is any XMS memory available?
	 jz	 short CHECK_XMS_EXIT ; Jump if not
CHECK_XMS1:
ifndef @RAMDEMO
	 mov	 ecx,eax	; Copy amount in 1KB for later use
	 shl	 ecx,10-0	; Convert from 1KB to bytes
	 mov	 edx,eax	; Copy amount in 1KB to input register
	 mov	 ah,XMS_GETXMB	; Function code to allocate XMS memory
	 call	 XMSDRV_VEC	; Request XMS service
				; Return with AX = 1 if OK
				;	      DX = handle #
	 and	 ax,ax		; Did it succeed?
	 jz	 short CHECK_XMS_ERR ; Jump if not (error code in BL)

; Lock the memory to get the linear or physical address

	 movzx	 esi,dx 	; Copy handle #

	 mov	 ah,@XMS_LCKXMB ; Function code to lock XMS memory
	 call	 XMSDRV_VEC	; Request XMS service
				; Return with AX = 1 if OK
				;	      DX:BX = linear address if 386MAX
				;	      DX:BX = physical address if XMS 3

	 and	 ax,ax		; Did it succeed?
	 jz	 short CHECK_XMS_ERR ; Jump if not (error code in BL)

; Save the memory in local tables

	 push	 XMS_XLATFLAGS	; Pass flags (needs translation if VDS
				; present, and XMS-allocated)
	 push	 esi		; Pass XMS handle #
	 push	 ecx		; Amount of shadow RAM in bytes
	 push	 dx		; ...at this physical location
	 push	 bx		; ...
	 push	 dx		; ...at this linear location
	 push	 bx		; ...
	 call	 SAVE_XSHADOW	; Append to shadow RAM structures

	 jmp	 CHECK_XMS_NEXT ; Go around again

CHECK_XMS_ERR:
endif


CHECK_XMS_EXIT:
	 REGREST <esi,edx,ecx,bx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_XMS endp			; End CHECK_XMS procedure
	 NPPROC  CHECK_XMEM -- Check on Extended Memory Usage
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on extended memory usage.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise.

|

	 REGSAVE <eax,ebx,edx,di> ; Save registers

	 mov	 eax,PHYSIZE	; Get size of physical memory
	 sub	 eax,1024	; Less first megabyte

	 test	 MAX_FLAG,@MD_XT ; Running on an XT?
	 jnz	 near ptr CHECK_XMEM_COM ; Yes, no CMOS to check

	 test	 SYS_FLAG,@SYS_EISA ; Izit an EISA machine?
	 jz	 short CHECK_XMEM1 ; Skip if not EISA

	 mov	 edx,eax	; Save amount of fn 88 memory in 1KB

	 push	 dword ptr ((1024*1024)/1024) ; Pass starting address in 1KB
	 call	 CHECK_EISA_EXT ; Check for any EISA super extended memory
				; Return with EISA super ext. memory in EAX
				; and lowest extra RAM address in EBX (unit=1KB)
;;;;;;;; jc	 near ptr CHECK_XMEM_EXIT ; Jump if there was an error in EISA land
				; (note CF=1)
	 jc	 short CHECK_XMEM_EISAERR ; Jump if there was an error in EISA land

; Note that we ignore EISA system errors as that's someone else's problem.
; Moreover, when NETROOM cloaks the BIOS, it doesn't emulate the EISA calls,
; so they return 86 (invalid function).

ifndef @RAMDEMO

; If there's extra non-contiguous RAM above the normal EISA memory,
; save it for later use.

	 call	 CHECK_EISA_SHD ; Check on memory at EBX*1024
endif
	 xchg	 eax,edx	; Assume we're going to use fn88 memory

	 cmp	 eax,edx	; Is fn 88 memory greater than EISA memory?
	 jae	 short CHECK_XMEM1 ; Jump if so

; If there's an XMS driver or DPMI host present, don't validate
; unallocated EISA memory

	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jnz	 short @F	; Jump if so, don't validate unallocated memory

	 test	 GLB_FLAG,@GLB_XMS ; Is there an XMS driver present?
	 jnz	 short @F	; Jump if so, don't validate unallocated memory

	 call	 VALIDATE_EISAMEM ; Validate the EISA memory that we found
	 jc	 short CHECK_XMEM1 ; Jump if EISA memory is not safe to use
@@:
CHECK_XMEM_EISAERR:
	 mov	 eax,edx	; Use EISA findings as total ext memory
CHECK_XMEM1:
	 and	 eax,not (4-1)	; Round down to a multiple of four
	 add	 eax,1024	; Plus first megabyte
	 mov	 PHYSIZE,eax	; Save as top of physical memory

	 mov	 eax,CMOSIZE	; Get size of extended memory in CMOS

; Ensure BIOS = CMOS

	 cmp	 eax,PHYSIZE	; Check 'em
	 je	 near ptr CHECK_XMEM_COM ; Jump if same

; If there's an XMS handler or DPMI host present, don't bother complaining

	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jnz	 near ptr CHECK_XMEM_LARGER ; Jump if so (save the larger one)

	 test	 GLB_FLAG,@GLB_XMS ; Is there an XMS driver present?
	 jnz	 short CHECK_XMEM_LARGER ; Jump if so (save the larger one)

	 test	 GL2_FLAG,@GL2_LARGER ; Did the user state a preference?
	 jnz	 short CHECK_XMEM_LARGER ; Jump if so (save the larger one)

	 test	 GL2_FLAG,@GL2_SMALLER ; Did the user state a preference?
	 jnz	 short CHECK_XMEM_SMALLER ; Jump if so (save the smaller one)

; We're already in real mode, so if SWAT is present, the Int 15h value has been
; reduced artificially, and we should ignore the CMOS value.

	 test	 GL2_FLAG,@GL2_SWAT ; Is 386SWAT present?
	 jnz	 short CHECK_XMEM_SMALLER ; Use smaller value if so

COMMENT|

On some systems, the CMOS value is artifically smaller for one of two
reasons:  either it's a COMPAQ system with more than 16MB but the CMOS
is set to 16MB for obsolete 286 software compatibility, or it's an
EISA system with more than 64MB and the CMOS bytes are not wide enough
to represent that much memory (in kilobytes).  In either case, we
choose the larger value.

Note that this check follows the test for the /S keyword, so if
there's a problem with our assumptions (that in the above two cases,
the larger value is the correct one), we have an override.

|

	 cmp	 eax,16*1024	; Is the CMOS size exactly 16MB?
	 je	 short CHECK_XMEM_LARGER ; Jump if so (save the larger one)

	 cmp	 eax,63*1024	; Is the CMOS size at or above 63MB?
	 jae	 short CHECK_XMEM_LARGER ; Jump if so (save the larger one)

	 push	 eax		; Save CMOS value for a moment

	 lea	 di,MSG_XMEM1	; ES:DI ==> output save area
	 call	 BIND2DEC	; Convert EAX to decimal ending at ES:DI

	 mov	 eax,PHYSIZE	; Get BIOS value
	 lea	 di,MSG_XMEM2	; ES:DI ==> output save area
	 call	 BIND2DEC	; Convert EAX to decimal ending at ES:DI

	 DOSCALL @STROUT,MSG_XMEM ; Tell 'em the bad news
CHECK_XMEM_AGAIN:
	 DOSCALL @STROUT,MSG_XMEMSEED ; Tell 'em the bad news

	 DOSCALL @KEYINE	; Get keystroke into AL

	 cmp	 al,0		; Izit an extended char?
	 jne	 short @F	; Jump if not

	 DOSCALL @KEYINE	; Get keystroke into AL
	 mov	 al,-1		; Mark as invalid
@@:
	 call	 LOWERCASE	; Convert AL to lowercase

; The valid responses are 'S', 'L', and CR (same as 'S')

	 cmp	 al,@MSG_SMALL	; Ensure valid
	 je	 short @F	; Jump if so

	 cmp	 al,CR		; Ensure valid
	 je	 short @F	; Jump if so

	 cmp	 al,@MSG_LARGE	; Check other valid response
	 jne	 short CHECK_XMEM_AGAIN ; Jump if not
@@:
	 mov	 bl,al		; Copy to test later

	 DOSCALL @STROUT,MSG_CRLF ; End the line

	 pop	 eax		; Restore CMOS value

; See what they chose

	 cmp	 bl,@MSG_SMALL	; Izit to use the smaller?
	 je	 short CHECK_XMEM_SMALLER ; Jump if so

	 cmp	 bl,CR		; Izit to use the smaller?
	 je	 short CHECK_XMEM_SMALLER ; Jump if so

; Use the larger of the two numbers

CHECK_XMEM_LARGER:
	 cmp	 eax,PHYSIZE	; Compare to use larger
	 jbe	 short CHECK_XMEM_COM ; Jump if CMOS is no larger

	 mov	 PHYSIZE,eax	; Use CMOS

	 jmp	 short CHECK_XMEM_COM ; Join common code

CHECK_XMEM_SMALLER:
	 cmp	 eax,PHYSIZE	; Compare to use smaller
	 jae	 short CHECK_XMEM_COM ; Jump if CMOS is no smaller

	 mov	 PHYSIZE,eax	; Use CMOS
CHECK_XMEM_COM:
ifndef @RAMDEMO
	 call	 SAVE_FN88	; Save fn88 memory (if appropriate)
endif
	 mov	 eax,PHYSIZE	; Get top of physical memory
	 sub	 eax,1024	; Less first megabyte
	 shl	 eax,10-0	; Convert from 1KB to bytes

	 add	 eax,SHDSIZE	; Plus size of shadow memory in bytes
	 jnz	 short CHECK_XMEM_CLC ; Jump if there's memory to check

	 DOSCALL @STROUT,MSG_NOMEM ; Tell 'em there's not enough memory

	 stc			; Indicate something went wrong

	 jmp	 short CHECK_XMEM_EXIT ; Join common code

CHECK_XMEM_CLC:
	 clc			; Allow it with a warning
CHECK_XMEM_EXIT:
	 REGREST <di,edx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_XMEM endp 		; End CHECK_XMEM procedure
ifndef @RAMDEMO
	 NPPROC  CHECK_EISA_SHD -- Check On Extra EISA RAM
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on extra non-contiguous EISA RAM.

On entry:

EBX	 =	 lowest address of extra RAM (unit=1KB) (-1 if none)
ECX	 =	 length in 1KB

|

	 REGSAVE <eax,ebx,ecx>	; Save registers

	 test	 CMD_FLAG,@CMD_X384 ; Is NOXRAM specified?
	 jnz	 short CHECK_EISA_SHD_EXIT ; Jump if so
CHECK_EISA_SHD_NEXT:
	 cmp	 ebx,-1 	; Izit present?
	 je	 short CHECK_EISA_SHD_EXIT ; Jump if not

	 mov	 ecx,ebx	; Copy starting address in 1KB

	 push	 ebx		; Pass starting address in 1KB
	 call	 CHECK_EISA_EXT ; Check for any EISA super extended memory
				; Return with EISA super ext. memory in EAX
				; and lowest extra RAM address in EBX
	 add	 eax,(1024*1024)/1024 ; Add back in the first 1MB

	 sub	 eax,ecx	; Izit within reason?
	 jbe	 short @F	; Jump if not

	 shl	 ecx,10-0	; Convert from 1KB to bytes
	 shl	 eax,10-0	; ...

	 push	 @TT_P2L	; Pass flags (needs P2L later)
	 PUSHD	 -1		; Pass handle # (-1=none)
	 push	 eax		; Amount of shadow RAM in bytes
	 push	 ecx		; ...at this location
	 push	 ecx		; Use same base in case no VDS present
	 call	 SAVE_XSHADOW	; Append to shadow RAM structures
@@:
	 jmp	 CHECK_EISA_SHD_NEXT ; Go around again

CHECK_EISA_SHD_EXIT:
	 REGREST <ecx,ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EISA_SHD endp		; End CHECK_EISA_SHD procedure
endif
ifndef @RAMDEMO
	 NPPROC  SAVE_FN88 -- Save Function 88h Memory
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save function 88h memory

|

	 REGSAVE <eax>		; Save register

	 mov	 eax,PHYSIZE	; Get size of physical memory

	 sub	 eax,1024	; Less first megabyte
	 jz	 short SAVE_FN88_EXIT ; Jump if no fn88 memory

; If there's neither an XMS driver nor DPMI host present,
; allocate this memory as top-down extended.

	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jnz	 short SAVE_FN88_EXIT ; Jump if so

	 test	 GLB_FLAG,@GLB_XMS ; Is there an XMS driver present?
	 jnz	 short SAVE_FN88_EXIT ; Jump if so

	 shl	 eax,10-0	; Convert from 1KB to bytes

; In order to protect this memory, we must install an INT 15h, fn88 handler
; which returns zero for any further INT 15h fn88 calls.

	 call	 INST_INT15	; Install it

	 push	 @TT_L2P or @TT_P2L ; Pass flags (needs translation if VDS
				; present, followed by P2L because we can't
				; trust the address if it's in the HMA)
	 PUSHD	 -1		; Pass handle # (-1=none)
	 push	 eax		; Amount of shadow RAM in bytes
	 push	 CON1M		; ...at this linear location
	 push	 CON1M		; Use same base in case no VDS present
	 call	 SAVE_XSHADOW	; Append to shadow RAM structures
SAVE_FN88_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_FN88 endp			; End SAVE_FN88 procedure
endif
ifndef @RAMDEMO
	 NPPROC  INST_INT15 -- Install Our INT 15h Handler
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Install our INT 15h, fn88 handler.  Because we're installing
an interrupt handler, we must also install at least an INT 23h
handler in case the user interrupts execution before we finish.
Note that if we were to do any disk access, we should also install
an INT 24h handler.

|

	 REGSAVE <ax,bx,dx,ds,es,fs> ; Save registers

	 push	 ds		; Setup FS to address DGROUP
	 pop	 fs		; Address it
	 assume  fs:DGROUP	; Tell the assembler about it

	 mov	 ds,CODESEG	; Setup alias to code segment
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 al,23h 	; Intercept this one
	 DOSCALL @SETINT,INT23	; Install our own handler

	 mov	 al,15h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT15_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT15_VEC.VSEG,es ; ...

	 or	 GLB_FLAG,@GLB_I15 ; Mark as installed

	 mov	 al,15h 	; Intercept this one
	 DOSCALL @SETINT,INT15	; Install our own handler

	 REGREST <fs,es,ds,dx,bx,ax> ; Restore
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_INT15 endp 		; End INST_INT15 procedure
endif
ifndef @RAMDEMO
	 FPPROC  INT15 -- BIOS Services Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIOS services interrupt handler.

|

	 pushf			; Save in case they're important

	 cmp	 ah,88h 	; Izit Get Extended Memory Size?
	 jne	 short INT15_ORIG ; Jump if not

	 xor	 ax,ax		; Return zero

	 popf			; Restore flags

	 iret			; Return to caller

INT15_ORIG:
	 popf			; Restore flags

	 jmp	 OLDINT15_VEC	; Continue with original handler

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT15	 endp			; End INT15 procedure
endif
	 FPPROC  INT23 -- Ctrl-Break Termination Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ctrl-Break termination handler

|

	 iret			; Return to caller (ignoring the action)

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT23	 endp			; End INT23 procedure
	 NPPROC  CHECK_EISA_EXT -- Get Size of EISA Extended Memory
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get size of extended memory by polling the EISA slots.
We already know we are on an EISA machine.
Start counting EISA memory from 1MB, not from top of fn 88 memory.

On exit:

EAX	 =	 Amount of EISA extended memory
EBX	 =	 Lowest address above EAX with extra non-contiguous
		 system RAM (-1 if none) in units of 1KB

Local Variables: EDI - Top of EISA memory place holder (units of 256 bytes)

|

CHKEISA_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
CHKEISA_START dd ?		; Starting address in bytes in 1KB

CHKEISA_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <cx,edx,si,edi,ds> ; Save registers

	 DOSCALL @STROUT,MSG_EISA ; Tell 'em what we're doing as it might
				; take a while

	 mov	 edi,[bp].CHKEISA_START ; Copy starting address in 1KB
	 shl	 edi,10-8	; Convert from 1KB to 256 bytes
	 mov	 ebx,-1 	; Initialize lowest address with non-contiguous
				; system RAM (in units of 256 bytes)
	 mov	 ds,MAPSEG_NXT	; Setup DS for Slot buffer
	 assume  ds:nothing	; Tell the assembler about it
EISA_START_SEARCH:
	 xor	 cx,cx		; Function 0 (CH), Slot 0 (CL)
GET_SUPER_FCN:
	 xor	 si,si		; DS:SI==> slot buffer
	 mov	 ax,ReadEISAFuncInfo ; Get Function Information

; Note: There are rude BIOSes that clobber registers that they aren't
;	supposed to.  Take precaution by saving and then restoring
;	all registers.	Some BIOSes (thanks Mylex) even disable
;	interrupts upon exit from the interrupt 15h call.

	 REGSAVE <ebx,ecx,edx,esi,edi,ebp> ; Save general registers
	 REGSAVE <ds,es,fs,gs>	; Save segment registers

	 int	 15h		; Request BIOS service
				; Return error code in AH
				; Update data strucutre at DS:SI

	 sti			; Enable interrupts (Thanks Mylex)

	 REGREST <gs,fs,es,ds>	; Restore segment registers
	 REGREST <ebp,edi,esi,edx,ecx,ebx> ; Restore general registers

	 jnc	 short CHECK_SUP ; Jump if call was successful

	 cmp	 ah,80h 	; Past all slots?
	 je	 short ALL_SLOTS_COUNTED ; Yes

	 cmp	 ah,81h 	; Invalid function number?
	 je	 short @F	; Yep, continue on

	 cmp	 ah,83h 	; Empty slot?
	 jne	 near ptr CHECK_EISA_ERR ; Unknown error, display the bad news
@@:
	 inc	 cl		; Increment to next slot
	 xor	 ch,ch		; Start again at function 0

	 jmp	 short GET_SUPER_FCN ; Try next slot

CHECK_SUP:

; We have some configuration information,
; Check to see if it's a memory configuration

	 test	 [si].EISA_FUNC_INFO,mask $EISAFNC_MEM ; Izit a memory entry?
	 jnz	 short GET_ENTRY ; Yes
NO_MEMORY_ENTRIES:
	 inc	 ch		; No - bump to next function

	 jmp	 short GET_SUPER_FCN ; Go around again

GET_ENTRY:
	 lea	 si,[si].EISA_MEMCONFIG ; Point at memory configuration

; We have memory - Check to see if it is system (or other) memory

GOT_MEMORY_ENTRY:
	 mov	 al,[si].MEM_CONFIG ; Memory config byte

	 test	 al,mask $EISAMEM_RAM ; Izit RAM?
	 jz	 short NEXT_SUPER_ENTRY ; Jump if not

	 and	 al,mask $EISAMEM_MEMTYPE ; We need the memory config bits

	 cmp	 al,@EISAMEM_SYS shl $EISAMEM_MEMTYPE ; System memory?
	 je	 short CONT_CHK_ENTRY ; Yes

; Check to see if there are more memory entries in this function

NEXT_SUPER_ENTRY:
	 test	 [si].MEM_CONFIG,mask $EISAMEM_CONT ; More memory entries?
	 jz	 short NO_MEMORY_ENTRIES ; No

	 add	 si,size EISAMEM_STR ; Yes - bump to next memory entry

	 jmp	 short GOT_MEMORY_ENTRY ; Go around again

; We have system memory - Check to see if it is the next logical block

CONT_CHK_ENTRY:
	 mov	 edx,[si].MEM_START_LSB.EDD ; Get starting address (+ some)
	 and	 edx,00FFFFFFh	; Clear top byte of dword

	 cmp	 edx,edi	; Is this the next logical block?
	 je	 short GOT_SUPER_BLOCK ; Jump if so
	 jb	 short NEXT_SUPER_ENTRY ; Jump if it's too low

; Check for lowest address above current high-water mark with system RAM
; First, is this incoming address in extended memory?

	 cmp	 edx,(1024*1024)/256 ; Izit at or above 1MB?
	 jb	 short @F	; Jump if not

	 cmp	 edx,ebx	; Izit a new low?
	 jae	 short @F	; Jump if not

	 mov	 ebx,edx	; Save as new low
@@:
	 jmp	 short NEXT_SUPER_ENTRY ; No, try the next block

; We have the next logical block of system memory

GOT_SUPER_BLOCK:
	 movzx	 edx,[si].MEM_LEN ; Memory size in 1 KB blocks

	 shl	 edx,(10-8)	; Convert from 256 bytes -> 1KB
	 jnz	 short NOT_64MB ; Skip if not 64 meg

	 mov	 edx,10000h shl (10-8) ; Make edx=64 Mbytes of 256 byte blocks
NOT_64MB:
	 add	 edi,edx	; New top of memory

	 cmp	 ebx,edi	; Check against lowest extra RAM address
	 ja	 short @F	; Jump if still valid

	 mov	 ebx,-1 	; Invalidate the lowest extra RAM address
@@:
	 jmp	 near ptr EISA_START_SEARCH ; Go at it again (from beginning)

ALL_SLOTS_COUNTED:
	 shr	 edi,(10-8)	; Convert from 256 bytes -> 1KB
	 sub	 edi,(1024*1024)/1024 ; Subtract for the first 1MB
	 mov	 eax,edi	; Return extended memory in EAX

	 cmp	 ebx,-1 	; Is the lowest extra RAM address valid?
	 je	 short @F	; Jump if not

	 shr	 ebx,10-8	; Convert from 256 bytes to 1KB
@@:
	 clc			; Mark as successful

	 jmp	 short CHECK_EISA_EXIT ; Continue on

CHECK_EISA_ERR:
	 stc			; Indicate something went wrong

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

CHECK_EISA_EXIT:
	 pushf			; Save flags (CF is significant)
	 push	 ax		; Save for a moment

	 mov	 ds,DATASEG	; Get segment of DGROUP
	 assume  ds:DGROUP	; Tell the assembler about it

	 DOSCALL @STROUT,MSG_CRLF ; End the line

	 pop	 ax		; Restore
	 popf			; Restore flags register

	 REGREST <ds,edi,si,edx,cx> ; Restore
	 assume  ds:DGROUP	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 4		; Return to caller, popping argument

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EISA_EXT endp		; End CHECK_EISA_EXT procedure
	 NPPROC  VALIDATE_EISAMEM -- Ensure EISA memory is valid
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure any EISA memory that we plan to use is valid

If there is less than 16MB of EISA memory, assume that the memory is valid.
If there is more than 16MB of EISA memory, perform a 1024 byte Read/Write
test at 16MB, and at 256 KB increments, until we hit the top of
reported memory.

On entry:
EAX	 =	 Amount of fn88 memory (in KB)
EDX	 =	 Amount of EISA memory (in KB)

On exit:
CF	=	0 if the EISA memory is valid
		1 if not

|

@EISA_CMP_SIZE equ	 1024	; # of bytes to compare
@EISA_CMP_INC  equ	 256*1024 ; Extended memory increment size

	 REGSAVE <eax,ecx,edx,esi,edi,es> ; Save registers

; Initialize input parameters

	 shl	 edx,(10-0)	; Convert KB to bytes

	 cmp	 edx,CON16M	; Is there more than 16MB of EISA memory
	 jbe	 near ptr VALIDATE_EISAMEM_CLC ; Jump if not
				; We only need to test memory above 16 MB

; Initialize source (extended memory) and destination (local buffer)

	 mov	 esi,CON16M	; Source is 16 MB line
	 movzx	 edi,MAPSEG_NXT ; Destin is next available free para
	 mov	 es,di		; Address MAPSEG
	 assume  es:nothing	; Tell the assemblera bout it
	 shl	 edi,4-0	; Convert from paras to bytes

VALIDATE_EISAMEM_NEXT:

; Save extended memory into primary buffer

	 mov	 ecx,@EISA_CMP_SIZE ; # bytes to read
	 call	 BIOS_BLOCK_MOVE ; Move from ext to cnv memory
	 jc	 near ptr VALIDATE_EISAMEM_STC ; Jump if error

; Copy the primary buffer to secondary buffer

	 REGSAVE <si,di>	; Save registers

	 mov	 cx,@EISA_CMP_SIZE/4 ; # dwords to copy
	 xor	 si,si		; Address primary buffer
	 mov	 di,@EISA_CMP_SIZE ; Address secondary buffer
S16  rep movs	 <es:[di].EDD,es:[si].EDD> ; Move data to secondary buffer

; Negate the memory in secondary buffer (to create a unique pattern)

	 mov	 cx,@EISA_CMP_SIZE/4 ; # dwords to negate
	 mov	 si,@EISA_CMP_SIZE ; Address secondary buffer

@@:
	 not	 es:[si].EDD	; Negate the value
	 add	 si,4		; Next dword
	 loop	 @B		; Do for entire count

	 REGREST <di,si>	; Restore registers

; Write our pattern from secondary buffer to extended memory

	 xchg	 esi,edi	; Switch source and destination
	 add	 esi,@EISA_CMP_SIZE ; Bump up to secondary buffer

	 mov	 ecx,@EISA_CMP_SIZE ; # bytes to read
	 call	 BIOS_BLOCK_MOVE ; Move from cnv to ext memory
	 jc	 short VALIDATE_EISAMEM_STC ; Jump if error

; Read our pattern back from extended memory into secondary buffer

	 xchg	 esi,edi	; Switch source and destination

	 mov	 ecx,@EISA_CMP_SIZE ; # bytes to read
	 call	 BIOS_BLOCK_MOVE ; Move from ext to cnv memory
	 jc	 short VALIDATE_EISAMEM_STC ; Jump if error

; Write back original memory from primary buffer to extended memory

	 xchg	 esi,edi	; Switch source and destination
	 sub	 esi,@EISA_CMP_SIZE ; Bump back to primary buffer

	 mov	 ecx,@EISA_CMP_SIZE ; # bytes to read
	 call	 BIOS_BLOCK_MOVE ; Move from cnv to ext memory
	 jc	 short VALIDATE_EISAMEM_STC ; Jump if error

; Negate pattern in secondary buffer to duplicate origianl pattern

	 REGSAVE <si,di>	; Save registers

	 mov	 cx,@EISA_CMP_SIZE/4 ; # dwords to negate
	 mov	 si,@EISA_CMP_SIZE ; Address secondary buffer

@@:
	 not	 es:[si].EDD	; Negate the value
	 add	 si,4		; Next dword
	 loop	 @B		; Do for entire count

; Compare primary and secondary buffers

	 mov	 cx,@EISA_CMP_SIZE/4 ; # dwords to negate
	 xor	 di,di		; Address primary buffer
	 mov	 si,@EISA_CMP_SIZE ; Address secondary buffer
    repe cmps	 es:[di].EDD,es:[si].EDD ; Compare the buffers

	 REGREST <di,si>	; Restore registers

	 jnz	 short VALIDATE_EISAMEM_STC ; Jump if buffers are not equal
				; (Memory is not safe to use)

; Buffers are equal, one more block of extended memory is valid

	 xchg	 esi,edi	; Switch source and destination
	 add	 esi,@EISA_CMP_INC ; Skip to next extended memory block

	 cmp	 esi,edx	; More extended memory to check?
	 jb	 near ptr VALIDATE_EISAMEM_NEXT ; Jump if so
VALIDATE_EISAMEM_CLC:
	 clc			; Indicate we can use EISA memory

	 jmp	 short VALIDATE_EISAMEM_EXIT ; Join common exit code

VALIDATE_EISAMEM_STC:
	 stc			; Indicate we can't use EISA memory
VALIDATE_EISAMEM_EXIT:
	 REGREST <es,edi,esi,edx,ecx,eax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VALIDATE_EISAMEM endp		; End VALIDATE_EISAMEM procedure
	 NPPROC  BIOS_BLOCK_MOVE -- BIOS_BLOCK_MOVE procedure
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT |

Move memory via the BIOS_BLOCK_MOVE function call

On entry:
ECX	=	Number of bytes to move
ESI	=	Linear address of source
EDI	=	...		  destin

|

	 REGSAVE <eax,ecx,esi,es> ; Save registers

; Set up source for move

	 mov	 eax,esi	; Get linear address of source

	 mov	 MOVE_TAB.MDTE_DS.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 MOVE_TAB.MDTE_DS.DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 MOVE_TAB.MDTE_DS.DESC_SEGLM0,cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 mov	 MOVE_TAB.MDTE_DS.DESC_SEGLM1,cl ; Save size & flags
	 ror	 ecx,16 	; Swap back
	 mov	 MOVE_TAB.MDTE_DS.DESC_ACCESS,CPL0_DATA

; Setup destination address for move

	 mov	 eax,edi	; Get linear address of desitnation

	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 MOVE_TAB.MDTE_ES.DESC_SEGLM0,cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 mov	 MOVE_TAB.MDTE_ES.DESC_SEGLM1,cl ; Save size & flags
	 ror	 ecx,16 	; Swap back
	 mov	 MOVE_TAB.MDTE_ES.DESC_ACCESS,CPL0_DATA

; Move the data

	 mov	 es,DATASEG	; Address MOVE_TAB
	 assume  es:DGROUP	; Tell the assembler about it

	 lea	 si,MOVE_TAB	; ES:SI ==> block move descriptor tables
	 shr	 cx,1		; Convert from bytes to words

	 REGSAVE <fs,gs>	; Save for a moment
	 mov	 ah,87h 	; Function code to move extended memory
	 int	 15h		; Request BIOS service
	 REGREST <gs,fs>	; Restore
	 jc	 short BBM_STC	; Jump if error

	 cmp	 ah,00h 	; Ensure it worked
	 jne	 short BBM_STC	; Jump if error

	 clc			; Indicate success

	 jmp	 short BBM_EXIT ; Join common exit code

BBM_STC:
	 stc			; Indicate failure
BBM_EXIT:
	 REGREST <es,esi,ecx,eax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
BIOS_BLOCK_MOVE  endp			; End BIOS_BLOCK_MOVE procedure
	 NPPROC  CHECK_PRVEXT -- Check on Preceding Extended Memory Usage
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on preceding extended memory usage.

|

	 REGSAVE <eax,ebx,ecx,si,bp> ; Save registers

; Setup source address for move

	 mov	 eax,CON1M	; Read starting at 1MB
	 mov	 ecx,size VDISK_STR ; # bytes to read

	 mov	 MOVE_TAB.MDTE_DS.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 MOVE_TAB.MDTE_DS.DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 MOVE_TAB.MDTE_DS.DESC_SEGLM0,cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 mov	 MOVE_TAB.MDTE_DS.DESC_SEGLM1,cl ; Save size & flags
	 ror	 ecx,16 	; Swap back
	 mov	 MOVE_TAB.MDTE_DS.DESC_ACCESS,CPL0_DATA

; Setup destination address for move

	 sub	 sp,size VDISK_STR ; Make room on the stack
	 mov	 bp,sp		; Address it

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,ss		; Copy stack segment para
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,sp 	; Get stack offset, zero high-order word
	 add	 eax,ebx	; Plus stack offset to get destination

	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE3,al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 MOVE_TAB.MDTE_ES.DESC_SEGLM0,cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 mov	 MOVE_TAB.MDTE_ES.DESC_SEGLM1,cl ; Save size & flags
	 ror	 ecx,16 	; Swap back
	 mov	 MOVE_TAB.MDTE_ES.DESC_ACCESS,CPL0_DATA

; Move the data to the local stack

	 lea	 si,MOVE_TAB	; ES:SI ==> block move descriptor tables
	 shr	 cx,1		; Convert from bytes to words

	 mov	 [bp].VDISK_VEND.EDD,0 ; Ensure mismatch in case BIOS
	 mov	 [bp+4].VDISK_VEND,0 ; ...block move fails

	 REGSAVE <fs,gs>	; Protect ourselves from the unwashed

	 mov	 ah,87h 	; Function code to move extended memory
	 int	 15h		; Request BIOS service
	 REGREST <gs,fs>	; Restore

; Some BIOSes/memory managers fails to handle CF correctly (set it when
; the move works, or clear when it fails) and some fail to return the
; correct value in AH (set to zero when the move fails, set to non-zero
; when it works).  Thus we don't check any of that.  The downside is that
; we don't display an error message if the move fails.

	 cmp	 [bp].VDISK_VEND.EDD,'SIDV' ; Check for signature
	 jne	 short CHECK_PRVEXT_CLC ; Jump if no signature

	 cmp	 [bp+4].VDISK_VEND,'K' ; Check for signature
	 jne	 short CHECK_PRVEXT_CLC ; Jump if no signature

	 cmp	 [bp].VDISK_NEXT,1024+64 ; Izit a pseudo-VDISK?
	 je	 short CHECK_PRVEXT_CLC ; Jump if so (ignore it)

	 DOSCALL @STROUT,MSG_PRVEXT ; Tell 'em to remove their VDISK
CHECK_PRVEXT_ERR:
	 add	 sp,size VDISK_STR ; Strip from stack

	 stc			; Indicate something went wrong

	 jmp	 short CHECK_PRVEXT_EXIT ; Join common exit code

CHECK_PRVEXT_CLC:
	 add	 sp,size VDISK_STR ; Strip from stack

	 clc			; Indicate all went well
CHECK_PRVEXT_EXIT:
	 REGREST <bp,si,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_PRVEXT endp		; End CHECK_PRVEXT procedure
	 NPPROC  CHECK_SCRN -- Check on Screen Mode
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on screen mode.

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

; See if there's an EGA present

	 call	 IZITEGA	; Check for EGA -- return AX = -1 if not

	 cmp	 ax,-1		; Check it out
	 je	 short @F	; Not this time

	 or	 GL2_FLAG,@GL2_EGA ; Mark as present
@@:

; Save original screen mode

	 VIDCALL @GETINF	; Get video information
	 and	 al,not 80h	; Isolate mode bits
	 mov	 VIDMODE1,al	; Save for later use

; Check for monochrome mode

	 cmp	 al,07h 	; Check it
	 je	 near ptr CHECK_SCRN_MONO ; Good guess

	 mov	 VIDBASE_FVEC.FOFF,000B8000h ; Save as screen memory base

; Check for forced black & white display

	 test	 CMD_FLAG,@CMD_BW ; Izit forced to black & white?
	 jnz	 short CHECK_SCRN_BW ; Jump if it is

; Check for forced color display

	 test	 CMD_FLAG,@CMD_DSET ; Is the display type already set?
	 jnz	 short CHECK_SCRN_COLR ; Jump if not

; Check the DCC to see if color is an option; if so, assume that's OK

	 test	 GL2_FLAG,@GL2_EGA ; Is there at least an EGA?
	 jz	 short CHECK_SCRN_ASK ; Jump if not

	 mov	 al,0		; Code to read the DCC
	 VIDCALL @GSTDCC	; Return the DCC in (BL,BH)
				; BL = active display code
				; BH = alternate display code

	 cmp	 al,@GSTDCC	; Izit supported?
	 jne	 short CHECK_SCRN_ASK ; Jump if not

	 cmp	 bl,02h 	; Izit color CGA?
	 je	 short CHECK_SCRN_COLR ; Jump if so

	 cmp	 bl,04h 	; Izit color EGA?
	 je	 short CHECK_SCRN_COLR ; Jump if so

	 cmp	 bl,06h 	; Izit color PGC?
	 je	 short CHECK_SCRN_COLR ; Jump if so

	 cmp	 bl,08h 	; Izit analog color?
	 je	 short CHECK_SCRN_COLR ; Jump if so

	 cmp	 bl,0Ch 	; Izit analog color?
	 je	 short CHECK_SCRN_COLR ; Jump if so

	 jmp	 short CHECK_SCRN_BW ; Assume it's black & white


; Ask about color

CHECK_SCRN_ASK:
	 test	 CMD_FLAG,@CMD_BWDEF ; Should we assume B&W?
	 jnz	 short CHECK_SCRN_BW ; Jump if so

	 DOSCALL @STROUT,MSG_ASKCLR ; Ask it

	 mov	 al,@NATL_YESCHAR ; Character to write
	 mov	 bh,0		; Display page #0
	 mov	 bl,@ATCFFyellow or @ATCBBred
	 mov	 cx,1		; # characters to write
	 VIDCALL @SETCAT	; Write char/attr
@@:
	 KEYCALL @GETKEY	; Wait for a response

	 call	 LOWERCASE	; Convert AL to lowercase

@NATL_YESCHARLC equ @NATL_YESCHAR + ('a' - 'A')
@NATL_NOCHARLC	equ @NATL_NOCHAR  + ('a' - 'A')

	 cmp	 al,@NATL_YESCHARLC ; Check for positive response
	 je	 short CHECK_SCRN_COLR ; It's color

	 cmp	 al,CR		; Check for default response
	 je	 short CHECK_SCRN_COLR ; It's color

	 cmp	 al,@NATL_NOCHARLC ; Check for negative response
	 jne	 short @B	; Jump if non-responsive

CHECK_SCRN_BW:
	 mov	 SCRNTYPE,@SCRN_BW ; Mark as B&W mode
	 mov	 VIDMODE2,02h	; B&W mode
	 mov	 bx,1		; It's Black & White

	 jmp	 short CHECK_SCRN_COM ; Join common code

CHECK_SCRN_COLR:
	 mov	 SCRNTYPE,@SCRN_COLR ; Mark as color mode
	 mov	 VIDMODE2,03h	; Color mode
	 mov	 bx,2		; It's Color
CHECK_SCRN_COM:
	 test	 CMD_FLAG,@CMD_BWDEF ; Did we skip the question?
	 jnz	 short CHECK_SCRN_EXIT ; Jump if so

	 DOSCALL @STROUT,MSG_CRLF ; End the line

	 jmp	 short CHECK_SCRN_EXIT ; Join common exit code

CHECK_SCRN_MONO:
	 mov	 VIDBASE_FVEC.FOFF,000B0000h ; Save as screen memory base
	 mov	 SCRNTYPE,@SCRN_MONO ; Mark as monochrome mode
	 mov	 VIDMODE2,07h	; Monochrome mode
	 mov	 bx,0		; It's Monochrome
CHECK_SCRN_EXIT:
	 mov	 CLRMODE,bx	; Save for later use

; Set screen attributes for Monochrome, Black & White, or Color adapters

	 call	 SET_COLOR	; Set 'em

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SCRN endp 		; End CHECK_SCRN procedure
	 NPPROC  SET_COLOR -- Set Colors
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set colors

This routine is bimodal.

|

	 REGSAVE <ax,bx,cx,si>	; Save registers

	 mov	 bx,CLRMODE	; Get color mode:  0 =mono, 1 = B&W, 2 = color
	 mov	 cx,@AMAC_CNT	; Number of attributes to initialize
	 sub	 si,si		; Initialize index into ATTR_TAB

; Set screen attributes for Monochrome, Black & White, or Color adapters
@@:
	 mov	 al,ATTR_TAB[si].AMAC_SYSATTR[bx] ; Get attribute
	 mov	 ATTR_TAB[si].AMAC_WORK,al ; Save as the real thing

	 add	 si,size AMAC_STR ; Skip to next one
	 loop	 @B		; Go around again

	 mov	 al,AASKAA[bx]	; Get advanced active ask line attr
	 mov	 BLK_STRS[@ITEM_ASKADV * (type BLK_STR)].BLK_AASK,al

	 mov	 al,AASKAB[bx]	; Get advanced background ask line attr
	 mov	 BLK_STRS[@ITEM_ASKADV * (type BLK_STR)].BLK_BASK,al

	 mov	 al,AASKMA[bx]	; Get memory active ask line attr
	 mov	 BLK_STRS[@ITEM_MEMADV * (type BLK_STR)].BLK_AASK,al

	 mov	 al,AASKMB[bx]	; Get memory background ask line attr
	 mov	 BLK_STRS[@ITEM_MEMADV * (type BLK_STR)].BLK_BASK,al

	 mov	 al,AASKBA[bx]	; Get basic active ask line attr
	 mov	 BLK_STRS[@ITEM_ASKBAS * (type BLK_STR)].BLK_AASK,al
	 mov	 BLK_STRS[@ITEM_ASKCMD * (type BLK_STR)].BLK_AASK,al

	 mov	 al,AASKBB[bx]	; Get basic background ask line attr
	 mov	 BLK_STRS[@ITEM_ASKBAS * (type BLK_STR)].BLK_BASK,al
	 mov	 BLK_STRS[@ITEM_ASKCMD * (type BLK_STR)].BLK_BASK,al

	 mov	 al,ASTATT[bx]	; Get status title attr
	 mov	 ZMSG_UNLSAF.ZMSG_ATTR,al ; Use in this message
	 mov	 ZMSG_UNLTRN.ZMSG_ATTR,al ; ...
	 mov	 ZMSG_UNLINV.ZMSG_ATTR,al ; ...
	 mov	 ZMSG_UNLIDM.ZMSG_ATTR,al ; ...
	 mov	 ZMSG_LNKINV.ZMSG_ATTR,al ; ...
	 mov	 ZMSG_LNKIDM.ZMSG_ATTR,al ; ...

	 mov	 ZMSG_CURPATB.ZMSG_ATTR,al ; ...
	 mov	 ZMSG_CURPATW.ZMSG_ATTR,al ; ...
	 mov	 ZMSG_CURPATD.ZMSG_ATTR,al ; ...

	 mov	 ZMSG_BLK.ZMSG_ATTR,al ; ...
	 mov	 ZMSG_ELAP.ZMSG_ATTR,al ; ...

	 call	 CLEAR_STATLIN	; Clear the status lines

	 REGREST <si,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_COLOR endp			; End SET_COLOR procedure
	 NPPROC  IZITEGA -- Check For Presence of EGA
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return AX = -1 if EGA not present, otherwise
       AL =  0 if present and in color mode
	     1		      in mono mode
	     2		      in enhanced color mode
       AH = memory settings (0 = 64k, 1 = 128k, 2 = 192k, 3 = 256k)
|

	 REGSAVE <bx,cx>	; Save registers

	 mov	 bl,10h 	; Function code to return EGA information
	 mov	 bh,0FFh	; Set to value out of range
	 mov	 cl,0Fh 	; Ditto

	 VIDCALL @GETEGA	; Get EGA information
				; If EGA present, return with
				; BH = 0 if color mode, 1 if mono
				; BL = 0 (64k), 1 (128k), 2 (192k), 3 (256k)
				; CH = feature bits
				; CL = switch setting

	 mov	 ax,-1		; Assume not present

	 cmp	 bh,01h 	; Check against maximum allowed value
	 ja	 short IZITEGA_EXIT ; Invalid, no EGA

	 cmp	 bl,03h 	; Check against maximum allowed value
	 ja	 short IZITEGA_EXIT ; Invalid, no EGA

	 cmp	 cl,0Bh 	; Check against maximum allowed value
	 ja	 short IZITEGA_EXIT ; Invalid, no EGA

	 mov	 al,bh		; Copy mode to AL
	 mov	 ah,bl		; ...and memory size to AH

	 cmp	 cl,9		; Check switch setting for enhanced color mode
	 jne	 short IZITEGA_EXIT ; Not this time

	 mov	 al,2		; It's in enhanced color mode
IZITEGA_EXIT:
	 REGREST <cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITEGA  endp			; End IZITEGA procedure
	 NPPROC  LOWERCASE -- Convert to Lowercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert to lowercase

On entry:

AL	 =	 character to convert

On exit:

AL	 =	 converted character

|

	 cmp	 al,'A'         ; Check against lower limit of uppercase
	 jb	 short @F	; Jump if too small

	 cmp	 al,'Z'         ; Check against upper ...
	 ja	 short @F	; Jump if too large

	 add	 al,'a'-'A'     ; Convert to lowercase
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure
	 NPPROC  GIVEBACK -- Give Back Any Resources Allocated
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Give back any resources allocated.

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 test	 GLB_FLAG,@GLB_I15 ; Did we intercept INT 15h?
	 jz	 short @F	; Jump if not

	 push	 ds		; Save for a moment

	 lds	 dx,OLDINT15_VEC ; DS:DX ==> old handler
	 assume  ds:nothing	; Tell the assembler about it
	 mov	 al,15h 	; Restore this one
	 DOSCALL @SETINT	; Restore the old handler

	 pop	 ds		; Restore
	 assume  ds:DGROUP	; Tell the assembler about it
@@:
;;;;;;;  test	 GLB_FLAG,@GLB_I21 ; Did we intercept INT 21h?
;;;;;;;  jz	 short @F	; Jump if not
;;;;;;;
;;;;;;;  push	 ds		; Save for a moment
;;;;;;;
;;;;;;;  lds	 dx,OLDINT21_VEC ; DS:DX ==> old handler
;;;;;;;  assume  ds:nothing	; Tell the assembler about it
;;;;;;;  mov	 al,21h 	; Restore this one
;;;;;;;  DOSCALL @SETINT	; Restore the old handler
;;;;;;;
;;;;;;;  pop	 ds		; Restore
;;;;;;;  assume  ds:DGROUP	; Tell the assembler about it
;;;;;;;@@:
	 test	 GLB_FLAG,@GLB_XMS ; Is there an XMS handler?
	 jz	 short GIVEBACK_EXIT ; Jump if not

	 test	 GLB_FLAG,@GLB_HMA ; Did we allocate the HMA?
	 jz	 short @F	; Jump if not

	 mov	 ah,@XMS_RELHMA ; Function code to release the HMA
	 call	 XMSDRV_VEC	; Request XMS service
				; Ignore error return
@@:

; Did we allocate a zero-length XMS handle?

	 mov	 dx,XMSZLEN	; Get the handle #

	 and	 dx,dx		; Izit valid?
	 jz	 short @F	; Jump if not

	 mov	 ah,@XMS_RELXMB ; Function code to release XMS memory
	 call	 XMSDRV_VEC	; Request XMS service
				; Ignore error return
@@:

; Release any XMS memory we allocated

	 mov	 cx,XSHDCNT	; Get # entries in XSHDTAB
	 jcxz	 GIVEBACK_EXIT	; Jump if none

	 xor	 bx,bx		; Initialize index into XSHDTAB
GIVEBACK_NEXT:
	 test	 XSHDTAB[bx].SHD_FLAG,@TT_XMS ; Izit an XMS handle?
	 jz	 short GIVEBACK_LOOP ; Jump if not

	 mov	 dx,XSHDTAB[bx].SHD_HNDL.ELO ; Get handle #

	 push	 bx		; Save because HIMEM clobbers it

	 mov	 ah,@XMS_UNLXMB ; Function code to unlock XMS memory
	 call	 XMSDRV_VEC	; Request XMS service
				; Ignore error return

	 mov	 ah,@XMS_RELXMB ; Function code to release XMS memory
	 call	 XMSDRV_VEC	; Request XMS service
				; Ignore error return
	 pop	 bx		; Restore
GIVEBACK_LOOP:
	 add	 bx,size SHD_STR ; Skip to next entry

	 loop	 GIVEBACK_NEXT	; Jump if more entries to check
GIVEBACK_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GIVEBACK endp			; End GIVEBACK procedure
	 NPPROC  CHECK_WIN3 -- See If Windows 3.x Is Active
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if Windows 3.x is active.

On exit:

CF	 =	 1 if Windows is active
	 =	 0 if not

|

	 REGSAVE <ax,dx>	; Save registers

	 mov	 ax,1600h	; Code for Windows/386 Installation Check
	 int	 2Fh		; Request multiplexor service
				; AL = 00h if not running
				; AL = 80h if not running
				; AL = 01h if Version 2.xx running
				; AL = FFh if Version 2.xx running
				; AL = Major version #, AH = Minor ...

	 test	 al,7Fh 	; Test for 00h and 80h
	 jz	 short CHECK_WIN3_EXIT ; Jump if not running (note CF=0)

	 cmp	 al,01h 	; Izit 2.xx?
	 je	 short CHECK_WIN3_EXIT ; Jump if so (note CF=0)

	 cmp	 al,0FFh	; Izit the other 2.xx?
	 je	 short CHECK_WIN3_EXIT ; Jump if so (note CF=0)

;;;;;;;; or	 GLB_FLAG,@GLB_WIN3 ; Mark as running under Windows
	 DOSCALL @STROUT,MSG_WIN3 ; Tell 'em how much of a bad idea this is

	 stc			; Mark as active
CHECK_WIN3_EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_WIN3 endp 		; End CHECK_WIN3 procedure
	 NPPROC  DISP_EXIT -- Display Message Upon Exit
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display message upon exit

|

	 REGSAVE <ax,bx,cx,dx,di,es> ; Save registers

; Because we terminated via INT 22h, DOS has closed all our file handles
; so we need to open (and afterwards close) standard output.

	 mov	 al,@OPEN_RW	; Function code to open in read-write mode
	 DOSCALL @OPENF2,CONSOLE ; Open the console device
	 jc	 near ptr DISP_EXIT_EXIT1 ; Jump if something went wrong

	 mov	 bx,ax		; Send to standard output

	 test	 CNT_FLAG,@CNT_DISPEXIT ; Display message upon exit?
	 jz	 short DISP_EXIT_EXIT ; Jump if not

	 test	 CNT_FLAG,@CNT_HALT ; Were tests cancelled by user?
	 jz	 short @F	; Jump if not

	 mov	 cx,MSG_CANCELLED_LEN ; Get # bytes in message
	 DOSCALL @WRITF2,MSG_CANCELLED ; Display the message

	 jmp	 short DISP_EXIT_EXIT ; Join common exit

@@:
	 mov	 cx,MSG_ELAP_LEN ; Get # bytes in message
	 DOSCALL @WRITF2,MSG_ELAP ; Display the message

; If there were any errors, say so; otherwise, say not.

	 mov	 ax,MEMERRCNT	; Get # memory errors
	 or	 ax,NMIERRCNT	; Get # parity errors
	 jz	 short DISP_EXIT_XERR ; Jump if no errors

	 push	 ds		; Get DGROUP data segment
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 ax,MEMERRCNT	; Get # memory errors

	 cmp	 ax,0		; Were there any memory errors?
	 je	 short @F	; Jump if not

	 lea	 di,MSG_MEMERR1 ; ES:DI ==> output save area
	 call	 BIN2DEC	; Convert AX to decimal ending at ES:DI

	 mov	 cx,MSG_MEMERR_LEN ; CX = # bytes in message
	 DOSCALL @WRITF2,MSG_MEMERR ; Display the message
@@:
	 mov	 ax,NMIERRCNT	; Get # parity errors

	 cmp	 ax,0		; Were there any parity errors?
	 je	 short @F	; Jump if not

	 lea	 di,MSG_NMIERR1 ; ES:DI ==> output save area
	 call	 BIN2DEC	; Convert AX to decimal ending at ES:DI

	 mov	 cx,MSG_NMIERR_LEN ; CX = # bytes in message
	 DOSCALL @WRITF2,MSG_NMIERR ; Display the message
@@:
	 jmp	 short DISP_EXIT_EXIT ; Join common exit code

DISP_EXIT_XERR:
	 mov	 cx,MSG_NOERR_LEN ; CX = # bytes in message
	 DOSCALL @WRITF2,MSG_NOERR ; Display the message
DISP_EXIT_EXIT:
	 test	 GLB_FLAG,@GLB_DPMIERR ; Did we terminate on a DPMI error?
	 jz	 short @F	; Jump if not

	 mov	 dx,DPMIMSG	; DS:DX ==> terminating message
	 mov	 di,dx		; Copy to get and skip over length byte
	 movzx	 cx,DGROUP:[di].LO ; Get the length byte
	 inc	 dx		; Skip over it
	 DOSCALL @WRITF2	; Tell the user about it
@@:
	 DOSCALL @CLOSF2	; Close the file
DISP_EXIT_EXIT1:
	 REGREST <es,di,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_EXIT endp			; End DISP_EXIT procedure

CODE	 ends			; End CODE segment

	 MEND	 MEMCHK 	; End MEM_MAIN module
