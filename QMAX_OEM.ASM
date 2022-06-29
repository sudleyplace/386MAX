;' $Header:   P:/PVCS/MAX/386MAX/QMAX_OEM.ASV   1.2   30 May 1997 10:45:48   BOB  $
	 title	 QMAX_OEM -- 386MAX OEM Module
	 page	 58,122
	 name	 QMAX_OEM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group XGROUP:
	       Code    segment XCODE, byte-aligned,  public, class 'xcode'
	       Group YGROUP:
	       Data    segment YDATA, dword-aligned, public, class 'ydata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|
.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC

	 include QMAX_OEM.INC
.list

PGROUP	 group	 CODE,EDATA
XGROUP	 group	 XCODE
YGROUP	 group	 YDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

if @OEM_SYS eq @OEMSYS_QUAD386
;;if @OEM_SYS eq @OEMSYS_LHY
;;if @OEM_SYS eq @OEMSYS_AST386
;;ife @OEM_BKFILL
;;ife @OEM_HIFILL
;;if @OEM_SYS eq @OEMSYS_ILIM
;;if @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2
	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC
endif				; IF @OEM_SYS eq @OEMSYS_QUAD386

if @OEM_SYS eq @OEMSYS_AST386 or @OEM_SYS eq @OEMSYS_MIT
	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC
endif				; IF @OEM_SYS eq @OEMSYS_AST386

if @OEM_SYS eq @OEMSYS_ILIM or @OEM_SYS eq @OEMSYS_GRID
	 extrn	 DBG_FLAG:word
	 include QMAX_DBG.INC
endif				; IF @OEM_SYS eq @OEMSYS_ILIM

if @OEM_SYS eq @OEMSYS_QUAD386
;;if @OEM_SYS eq @OEMSYS_AST386
;;if @OEM_SYS eq @OEMSYS_ILIM
;;if @OEM_SYS eq @OEMSYS_JET386
	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC
endif				; IF @OEM_SYS eq @OEMSYS_QUAD386

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  cs:PGROUP

if @OEM_SYS eq @OEMSYS_ILIM or @OEM_SYS eq @OEMSYS_3COM
	 extrn	 DMASIZE:word
endif				; IF @OEM_DMA

EDATA	 ends			; End EDATA segment


YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
	 assume  ds:YGROUP

if @OEM_SYS eq @OEMSYS_JET386
LICENSE  db	 'Licensed for use to Orchid Technologies, Inc.',CR,LF,EOS
endif				; IF @OEM_SYS eq @OEMSYS_JET386

YDATA	 ends			; End YDATA segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 public  @QMAX_OEM_XCODE
@QMAX_OEM_XCODE:		; Mark module start in .MAP file

if @OEM_SYS eq @OEMSYS_JET386
	 extrn	 YMSGOUT:near
endif				; IF @OEM_SYS eq @OEMSYS_JET386

	 NPPROC  DISP_OEM -- Display OEM Messages
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display OEM messages if any.

This routine executes in real mode only.

|

if @OEM_SYS eq @OEMSYS_QUAD386

; We don't need to select this machine via SYS_FLAG as it will be
; tested for and set in CHECK_QUAD386

	 or	 CMD_FLAG,@CMD_XRM ; Mark as NOROM
endif				; IF @OEM_SYS eq @OEMSYS_QUAD386


if @OEM_SYS eq @OEMSYS_LHY
	 or	 CMD_FLAG,@CMD_XRM ; Mark as NOROM
endif				; IF @OEM_SYS eq @OEMSYS_LHY


if @OEM_SYS eq @OEMSYS_AST386

; We don't need to select this machine via SYS_FLAG as it will be
; tested for and set in CHECK_AST386

	 or	 CMD_FLAG,@CMD_XRM ; Mark as NOROM
	 or	 CM2_FLAG,@CM2_NWB ; Mark as NOWARMBOOT
endif				; IF @OEM_SYS eq @OEMSYS_AST386


ife @OEM_BKFILL
	 or	 CMD_FLAG,@CMD_XLO ; Mark as no low DOS memory
endif				; IFE @OEM_BKFILL


ife @OEM_HIFILL
	 or	 CMD_FLAG,@CMD_XHI ; Mark as no high DOS memory
endif				; IFE @OEM_HIFILL


if @OEM_SYS eq @OEMSYS_ILIM
	 or	 CMD_FLAG,@CMD_XHI ; Mark as no high DOS memory fill
				; unless overridden by HIGHDOS
	 or	 CMD_FLAG,@CMD_XRM ; Mark as no ROM swap
	 or	 SYS_FLAG,@SYS_INBRD ; Mark as Inboard/AT or /PC
	 or	 DBG_FLAG,@DBG_CR3 ; Mark as needing CR3 fixup
	 mov	 DMASIZE,64	; Use default DMA buffer size of 64KB
endif				; IF @OEM_SYS eq @OEMSYS_ILIM


if @OEM_SYS eq @OEMSYS_3COM
	 mov	 DMASIZE,36	; Use default DMA buffer size of 36KB
endif				; IF @OEM_SYS eq @OEMSYS_3COM


if @OEM_SYS eq @OEMSYS_GRID
	 or	 DBG_FLAG,@DBG_SOR ; Mark as DEBUG=SOR
endif				; IF @OEM_SYS eq @OEMSYS_GRID


if @OEM_SYS eq @OEMSYS_JET386
	 or	 SYS_FLAG,@SYS_JET386 ; Mark as JET 386

	 REGSAVE <ax>		; Save register

	 lea	 ax,YGROUP:LICENSE ; Display license statement
	 push	 ax		; Pass as argument
	 call	 YMSGOUT	; Display YGROUP message

	 REGREST <ax>		; Restore
endif				; IF @OEM_SYS eq @OEMSYS_JET386

if @OEM_SYS eq @OEMSYS_MIT
	 or	 CM2_FLAG,@CM2_UNSH ; Mark as unshift in effect
endif				; IF @OEM_SYS eq @OEMSYS_MIT

if @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2
	 or	 CMD_FLAG,@CMD_TERSE ; Mark as terse mode
endif				; IF @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_OEM endp			; End DISP_OEM procedure

XCODE	 ends			; End XCODE segment

	 MEND			; End QMAX_OEM module
