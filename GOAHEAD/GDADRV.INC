;' $Header:   P:/PVCS/MAX/GOAHEAD/GDADRV.INV   1.3   01 Feb 1996 10:30:42   BOB  $
;
; (C) Copyright 1995 Qualitas, Inc.  All rights reserved.
;
; GOAHEAD.INC
;
; GOAHEAD include file
;

; User-defined messages are numbered between DRV_RESERVED (0800h)
; and DRV_USER (4000h).

LCLDRV_GETBUFADDR   equ 0800h ; Return a pointer to the DOSMem buffer address
LCLDRV_REGISTER     equ 0801h ; Register a WinApp to which messages should be posted
LCLDRV_UNREGISTER   equ 0802h ; Unregister a WinApp
LCLDRV_QUERYCLOSE   equ 0803h ; Query DRV_CLOSE count
LCLDRV_QUERYENABLE  equ 0804h ; Query enable state (TRUE if enabled, FALSE if disabled)
LCLDRV_QUERYINSTALL equ 0805h ; Query install state (TRUE if installed, FALSE if not)
LCLDRV_QUERYLOWSEG  equ 0806h ; Query lowest free segment ever encountered
LCLDRV_DISABLE	    equ 0807h ; Free all allocated memory and go dormant
LCLDRV_ENABLE	    equ 0808h ; Allocate all low DOS memory and awake
LCLDRV_GETMEMHISTORY equ 0809h ; Return a pointer to the MemHistTab buffer
LCLDRV_GETMODHISTORY equ 080Ah ; Return a pointer to the ModHistTab buffer
LCLDRV_QUERYGORE    equ 080Bh ; Query size of gore (amount of DOS memory to leave free)
LCLDRV_GETMODFILE   equ 080Ch ; Return a pointer to the SpecMod buffer
LCLDRV_READPROFILE  equ 080Dh ; Reread the profile
LCLDRV_GETCSDS	    equ 080Eh ; Return CS & DS

@FILENAME equ	<'GOAHEAD'> ; Driver filename
@FILENAMEXT equ <'GOAHEAD.DRV'> ; Driver filename.ext
@APPNAME  equ	<'GAHD_APP'> ; Module name of our .EXE file


; Equates and record for LCL_FLAG

LCL_REC record	\
		$LCL_INSTNR:1,	\
		$LCL_INSTGA:1,	\
		$LCL_INSTGDA:1, \
		$LCL_INSTGF:1,	\
		$LCL_INSTGDF:1, \
		$LCL_RIDDIS:1,	\
		$LCL_DBG:1,	\
		$LCL_GFALLOC:1, \
		$LCL_TABFULL:1, \
		$LCL_DUPDIS:1,	\
		$LCL_GOREDIS:1, \
		$LCL_CLOSE:1,	\
		$LCL_INSTALL:1, \
		$LCL_CMDDIS:1,	\
		$LCL_FREE:1

@LCL_INSTNR  equ (mask $LCL_INSTNR)	; 4000:  Installed NotifyRegister hook
@LCL_INSTGA  equ (mask $LCL_INSTGA)	; 2000:  ...	   GA		  ...
@LCL_INSTGDA equ (mask $LCL_INSTGDA)	; 1000:  ...	   GDA		  ...
@LCL_INSTGF  equ (mask $LCL_INSTGF)	; 0800:  ...	   GF		  ...
@LCL_INSTGDF equ (mask $LCL_INSTGDF)	; 0400:  ...	   GDF		  ...
@LCL_RIDDIS  equ (mask $LCL_RIDDIS)	; 0200:  Disable due to incompat driver
@LCL_DBG     equ (mask $LCL_DBG)	; 0100:  In a debuggin' mood
@LCL_GFALLOC equ (mask $LCL_GFALLOC)	; 0080:  Allocate more DOS memory on GlobalFree
@LCL_TABFULL equ (mask $LCL_TABFULL)	; 0040:  DOSMem table full
@LCL_DUPDIS  equ (mask $LCL_DUPDIS)	; 0020:  Disabled due to duplication
@LCL_GOREDIS equ (mask $LCL_GOREDIS)	; 0010:  Disabled due to gore = -1
@LCL_CLOSE   equ (mask $LCL_CLOSE)	; 0008:  The driver has been closed at
					;	 least once
@LCL_INSTALL equ (mask $LCL_INSTALL)	; 0004:  If set and @LCL_CLOSE,
					;	 installed
@LCL_CMDDIS  equ (mask $LCL_CMDDIS)	; 0002:  Disabled due to command
@LCL_FREE    equ (mask $LCL_FREE)	; 0001:  Driver has been freed from
					;	 memory
@LCL_DISABLE equ (@LCL_DUPDIS  or \
		  @LCL_RIDDIS  or \
		  @LCL_GOREDIS or \
		  @LCL_CMDDIS) ; Disabled for one reason or another


; The following equates *MUST* match the ones in RESDRV.H

IDC_DRVNAME  equ 1000		; ID for driver text
IDC_NOLOAD   equ 1001		; ...	 "Don't load Go Ahead this time"
;;;_LOADONCE equ 1002		; ...	 "Load Go Ahead this time"
IDC_REMOVE   equ 1003		; ...	 "Uninstall Go Ahead"
IDC_NOWARN   equ 1004		; ...	 "Always load Go Ahead and don't warn me again"

IDS_US_STARTUPGRP equ 1 	; ID for US Startup Group string
IDS_DE_STARTUPGRP equ 2 	; ...	 German ...

