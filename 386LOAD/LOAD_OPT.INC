;' $Header:   P:/PVCS/MAX/386LOAD/LOAD_OPT.INV   1.0   05 Sep 1995 14:47:46   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; LOAD_OPT.INC
;
; Equates for OPT_FLAG
;

@OPT_INTR    equ 8000h		; INT
@OPT_PROG    equ 4000h		; PROG=
@OPT_PREG    equ 2000h		; PRGREG=1 to 9
@OPT_EREG    equ 1000h		; ENVREG=1 to 9
@OPT_QUIET   equ 0800h		; QUIET
@OPT_ENAME   equ 0400h		; ENVNAME
@OPT_NOPAUSE equ 0200h		; NOPAUSE
@OPT_GSIZE   equ 0100h		; GETSIZE
@OPT_TABLE   equ 0080h		; Table display
@OPT_VER     equ 0040h		; VER
@OPT_SIZE    equ 0020h		; SIZE=
@OPT_VDS     equ 0010h		; VDS
				; ENVSAVE
				; FLEXFRAME
@OPT_NORETRY equ 0008h		; NORETRY

@OPT_TSRDEF equ  @OPT_ENAME	; Default options for TSRLOAD
@OPT_DRVDEF equ  0		; ...		      DRVLOAD


; These are now extern:abs from GETSIZE.ASM
;@GSIZE_PAT1 equ  <'83'>         ; GETSIZE pattern #1
;@GSIZE_PAT2 equ  <'M6'>         ; GETSIZE pattern #2

