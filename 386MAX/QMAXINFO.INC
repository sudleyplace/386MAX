;' $Header:   P:/PVCS/MAX/386MAX/QMAXINFO.INV   1.0   11 Aug 1995 10:55:52   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAXINFO.INC
;
; INFO area structure common to QMAX & QMAXCOM
;

INFO_STR struc

INFO_SIGN db	 '      '       ; 00-05:  Signature = '386MAX'
INFO_VER  db	 ?		; 06:	  QMAX version # (filled in by QMAX)
	  db	 '.'            ; 07:
	  db	 ?		; 08:
	  db	 ?		; 09:
INFO_QMAX dw	 ?		; 0A-0B:   1 = Segment of QMAX (non-relocatable)
INFO_HIGH dw	 ?		; 0C-0D:   2 = Segment of memory allocated
INFO_OWNR dw	 0		; 0E-0F:   3 = Owner (filled in by QMAXCOM)
INFO_GLB  dw	 0		; 10-11:   4 = GLB_FLAG (Global program flags)
INFO_LOW  dw	 ?		; 12-13:   5 = LOWSIZE
INFO_VID  dw	 ?		; 14-15:   6 = VIDSIZE
INFO_OVR  dw	 ?		; 16-17:   7 = OVRSIZE
	  dw	 0		; 18-19:   8 = EXTSIZE if ON or AUTO (obsolete)
	  dw	 0		; 1A-1B:   9 = EMMSIZE (obsolete)
INFO_PRG  dw	 ?		; 1C-1D:  10 = PRGSIZE
INFO_MAP  dw	 ?		; 1E-1F:  11 = MAPSIZE
	  dw	 0		; 20-21:  12 = TOTSIZE (obsolete)
INFO_P15  dw	 ?		; 22-23:  13 = PORT15
INFO_P67  dw	 ?		; 24-25:  14 = PORT67
INFO_COMR dw	 ?		; 26-27:  15 = CMDCOM_PAR
INFO_OLD  dw	 ?		; 28-29:  16 = OLDLOW in paras
INFO_SYS  dd	 0		; 2A-2D:  17 = SYS_FLAG (System-dependent flags)
INFO_PMAC dd	 0		; 2E-31:  18 = P1ST_MAC
INFO_LCL  dw	 0		; 32-33:  19 = LCL_FLAG (Local program flags)
INFO_DBG  dw	 0		; 34-35:  20 = DBG_FLAG (Debug flags, part 1)
INFO_DB2  dw	 0		; 36-37:  21 = DB2_FLAG (Debug flags, part 2)
INFO_MISC dw	 0		; 38-39:  22 = Miscellaneous flags
INFO_POVR dw	 -1		; 3A-3B:  23 = Segment of first MAC in high DOS memory
INFO_CMD  dw	 0		; 3C-3D:  24 = CMD_FLAG
INFO_CM2  dw	 0		; 3E-3F:  25 = CM2_FLAG
INFO_CM3  dw	 0		; 40-41:  26 = CM3_FLAG
INFO_LSEG dw	 -1		; 42-43:  27 = 386LOAD chain segment
INFO_OFF  dw	 ?		; 44-45:  28 = Size of extended memory if OFF
INFO_SHD  dw	 0		; 46-47:  29 = Size of shadow RAM
INFO_XSHD dw	 0		; 48-49:  30 = Size of extra shadow RAM
INFO_SWP  dw	 0		; 4A-4B:  31 = SWPSIZE
INFO_ONF  dw	 0		; 4C-4D:  32 = EXTSIZE over ON/OFF
INFO_SROM dw	 0F000h 	; 4E-4F:  33 = SYSROM_START
INFO_DB3  dw	 0		; 50-51:  34 = DB3_FLAG (Debug flags, part 3)
INFO_I21  dd	 ?		; 52-55:  35 = OLDINT21_VEC
INFO_C67  dd	 ?		; 56-59:  36 = CURINT67_VEC
INFO_TOT  dd	 ?		; 5A-5D:  37 = TOTSIZE as dword
INFO_EXT  dd	 ?		; 5E-61:  38 = EXTSIZE if ON or AUTO as dword
INFO_EMM  dd	 ?		; 62-65:  39 = EMMSIZE as dword

INFO_STR ends


