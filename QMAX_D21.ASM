;' $Header:   P:/PVCS/MAX/386MAX/QMAX_D21.ASV   1.3   30 May 1997 10:44:14   BOB  $
	 title	 QMAX_D21 -- 386MAX DPMI INT 21h Translation Services
	 page	 58,122
	 name	 QMAX_D21

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-8 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Program segment LCODE, dword-aligned, public, class 'icode'
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Data    segment IDATA, dword-aligned, public, class 'idata'
	       Data    segment ACTSEG,word-aligned,  public, class 'idata'

Program derived from:  None.

Original code by:  Bob Smith, July 1991.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include DOSCALL.INC
	 include CPUFLAGS.INC
	 include BITFLAGS.INC
	 include ALLMEM.INC
	 include ASCII.INC
	 include DPMI.INC
	 include CDI.INC
	 include FCB.INC
	 include DOSERR.INC
	 include DSKSER.INC
	 include MASM5.MAC
	 include DTA.INC
	 include GENERIC.INC
	 include EXEC.INC

	 include QMAX_OEM.INC
	 include QMAX_DTE.INC
	 include QMAX_EMM.INC
	 include QMAX_I31.INC
	 include QMAX_TSS.INC
	 include QMAX_VMM.INC
	 include QMAXDPMI.INC
.list

if @OEM_DPMI

PGROUP	 group	 ECODE,EDATA
IGROUP	 group	 LCODE,LDATA,ICODE,IDATA,ACTSEG
PSPGRP	 group	 PSPSEG


PSPSEG	 segment use16 at 0	; Start PSPSEG segment
	 assume  ds:PSPGRP

	 extrn	 PSP_ENVIR_PTR:word

PSPSEG	 ends			; End PSPSEG segment


LCODE	 segment use16 dword public 'icode' ; Start LCODE segment
	 assume  cs:IGROUP

	 extrn	 GETSELBASE:far

LCODE	 ends			; End LCODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 INTPROC00Z:near
	 extrn	 FQRY_PGCNT:far
	 extrn	 FALLOCMEM:far
	 extrn	 FDEALLOCMEM:far
	 extrn	 FXMS_MEMSPAN:far

ECODE	 ends			; End ECODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 SEL_4GB3:word
	 extrn	 CON64KB:dword
	 extrn	 CON1MB:dword
	 extrn	 DOSVER:word

	 extrn	 DPMI_CODE:word
	 extrn	 DPMI_DATA:word

	 extrn	 VM2PM_TSS:word
	 extrn	 XMSBMAP_LEN:dword
	 extrn	 PCURTSS:dword
	 extrn	 EXITRC:word
	 extrn	 I31_FLAG:word
	 extrn	 DPMI_CPIHOOK:byte
	 extrn	 LPMSTK_FVEC:fword

if @OEM_VIRTUALMEM
	 extrn	 VMM_FLAG:word
endif

	 public  OLDDTA_VEC
OLDDTA_VEC dd	 ?		; Save area for address of old DTA

	 public  VMCREGS
VMCREGS  VMC_STR <>		; Used to simulate VM calls

EDATA	 ends			; End EDATA segment


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_DS3:word

LDATA	 ends			; End LDATA segment


; Define DOS INT 21h functions which we handle

DPMIDOSMAC macro VAL,ACT

ACTSEG	 segment use16 word public 'idata' ; Start ACTSEG segment
	 assume  ds:IGROUP

	 org	 DPMIDOS_ACT + VAL * (type DPMIDOS_ACT) ; Set to appropriate origin
	 dw	 IGROUP:INT21_DPMIJMP_&ACT
	 org	 DPMIDOS_ACTZ  ; Restore to end of the table

ACTSEG	 ends			; End ACTSEG segment

	 endm			; DPMIDOSMAC


ACTSEG	 segment use16 word public 'idata' ; Start ACTSEG segment
	 assume  ds:IGROUP

	 public  DPMIDOS_ACT
DPMIDOS_ACT dw	 256 dup (IGROUP:INT21_DPMIJMP_PASSTHRU) ; Seed with pass through action
DPMIDOS_ACTZ label word

ACTSEG	 ends			; End ACTSEG segment


; The following DOS functions require special treatment

.sall
	 DPMIDOSMAC @STROUT,STROUT	; 09:  Display string at DS:eDX
	 DPMIDOSMAC @BKEYIN,BKEYIN	; 0A:  Buffered keyboard input to DS:eDX
	 DPMIDOSMAC @CKEYIN,CKEYIN	; 0C:  Clear keyboard buffer & invoke input as AL=1,6,7,8,A
	 DPMIDOSMAC @SRCH1 ,SRCH1	; 11:  Search for first dir entry, FCB at DS:eDX
	 DPMIDOSMAC @SRCH2 ,SRCH2	; 12:  Search for next dir entry, FCB at DS:eDX
	 DPMIDOSMAC @DELEF ,DELEF	; 13:  Delete file, FCB at DS:eDX
	 DPMIDOSMAC @RENMF, RENMF	; 17:  Rename file, FCB at DS:eDX
	 DPMIDOSMAC @SETDTA,SETDTA	; 1A:  Set disk transfer addr to DS:eDX
	 DPMIDOSMAC @FATADR,FATADR	; 1B:  Get allocation table info of default drive, DS:eBX ==> media type
	 DPMIDOSMAC @FATAD2,FATAD2	; 1C:  Get allocation table info of drive in DL, DS:eBX ==> media type
	 DPMIDOSMAC @GETDPB,GETDPB	; 1F:  Return DS:eBX ==> drive parameter block for default drive
	 DPMIDOSMAC @SETINT,SETINT	; 25:  Set interrupt vector in AL to DS:eDX
	 DPMIDOSMAC @PARSF, PARSF	; 29:  Parse filename at DS:eSI to ES:eDI
	 DPMIDOSMAC @GETDTA,GETDTA	; 2F:  Get disk transfer addr to ES:eBX
	 DPMIDOSMAC @GETDP2,GETDP2	; 32:  Return DS:eBX ==> drive parameter block for drive DL (origin-1)
	 DPMIDOSMAC @DOSPTR,DOSPTR	; 34:  Return ES:eBX ==> DOS call level byte (internal)
	 DPMIDOSMAC @GETINT,GETINT	; 35:  Get interrupt vector in AL to ES:eBX
	 DPMIDOSMAC @GETCDI,GSTCDI	; 38:  Get/set country-dependent information
	 DPMIDOSMAC @MKDIR ,MKDIR	; 39:  Create a subdirectory named DS:eDX
	 DPMIDOSMAC @RMDIR ,RMDIR	; 3A:  Remove the subdirectory named DS:eDX
	 DPMIDOSMAC @CHDIR ,CHDIR	; 3B:  Change current directory to DS:eDX
	 DPMIDOSMAC @CREAF2,CREAF2	; 3C:  Create file, ASCIIZ at DS:eDX, attr in CX
	 DPMIDOSMAC @OPENF2,OPENF2	; 3D:  Open file, ASCIIZ at DS:eDX
	 DPMIDOSMAC @READF2,READF2	; 3F:  Read from file BX, to DS:eDX
	 DPMIDOSMAC @WRITF2,WRITF2	; 40:  Write to file BX, from DS:eDX
	 DPMIDOSMAC @DELEF2,DELEF2	; 41:  Delete file, ASCIIZ at DS:eDX
	 DPMIDOSMAC @GSTMOD,GSTMOD	; 43:  Get (AL=0)/set (AL=1) file mode to CX, ASCIIZ at DS:eDX
	 DPMIDOSMAC @IOCTL2,IOCTL2	; 44:  I/O Control for devices, handle in BX
	 DPMIDOSMAC @GETDIR,GETDIR	; 47:  Get current directory for drive DL to DS:eSI
	 DPMIDOSMAC @GETMEM,GETMEM	; 48:  Get memory (eBX paras)
	 DPMIDOSMAC @RELMEM,RELMEM	; 49:  Release memory (in ES)
	 DPMIDOSMAC @MODMEM,MODMEM	; 4A:  Modify memory block ES to eBX paras
	 DPMIDOSMAC @EXEC  ,EXEC	; 4B:  Execute a program
	 DPMIDOSMAC @EXITRC,EXITRC	; 4C:  Exit with return code
	 DPMIDOSMAC @FIND1 ,FIND1	; 4E:  Search for first dir entry, ASCIIZ at DS:eDX
	 DPMIDOSMAC @FIND2 ,FIND2	; 4F:  Search for next dir entry, from DTA
	 DPMIDOSMAC @SETPSP,SETPSP	; 50:  Set current PSP to BX (internal)
	 DPMIDOSMAC @GETPS0,GETPS0	; 51:  Get current PSP into BX (same as 62h) (internal)
	 DPMIDOSMAC @GETLST,GETLST	; 52:  Get list of lists pointer into ES:eBX
	 DPMIDOSMAC @BP2DPB,BP2DPB	; 53:  Translate BPB at DS:eSI to DPB at ES:eBP
	 DPMIDOSMAC @BLDPS2,BLDPS2	; 55:  Create new program segment prefix at DX:0 with top of DOS at SI:0
	 DPMIDOSMAC @RENMF2,RENMF2	; 56:  Rename file, from ASCIIZ at DS:eDX to ASCIIZ at ES:eDI
	 DPMIDOSMAC @TMPFIL,TMPFIL	; 5A:  Create temporary file, ASCIIZ at DS:eDX, attr in CX
	 DPMIDOSMAC @NEWFIL,NEWFIL	; 5B:  Create new file, ASCIIZ at DS:eDX, attr in CX
;;;	 DPMIDOSMAC @???   ,??? 	; 5D:  ???
;;;	 DPMIDOSMAC @???   ,??? 	; 5E:  ???
;;;	 DPMIDOSMAC @???   ,??? 	; 5F:  ???
	 DPMIDOSMAC @FIXPTH,FIXPTH	; 60:  Resolve path in DS:eSI to canonical form in ES:eDI
;;;	 DPMIDOSMAC @???   ,??? 	; 61:  ???
	 DPMIDOSMAC @GETPSP,GETPSP	; 62:  Get current PSP into BX
;;;	 DPMIDOSMAC @???   ,??? 	; 63:  ???
;;;	 DPMIDOSMAC @???   ,??? 	; 64:  ???
	 DPMIDOSMAC @GETXCD,GETXCD	; 65:  Get extended conuntry-dependent information
	 DPMIDOSMAC @GSTSER,GSTSER	; 69:  Get/set disk serial # for drive BL (origin-1) to DS:eDX
;;;	 DPMIDOSMAC @???   ,??? 	; 6A:  ???
;;;	 DPMIDOSMAC @???   ,??? 	; 6B:  ???
	 DPMIDOSMAC @XOPCR2,XOPCR2	; 6C:  Extended Open/Create file, ASCIIZ at DS:eSI, attr in CX, mode in BX, flags in DX

; The following DOS functions require no special treatment

	 DPMIDOSMAC @KEYINE,KEYINE	; 01:  Keyboard input w/wait & echo to AL
	 DPMIDOSMAC @CHROUT,CHROUT	; 02:  Display output in DL to CON:
	 DPMIDOSMAC @AUXIN ,AUXIN	; 03:  Serial input w/wait to AL
	 DPMIDOSMAC @AUXOUT,AUXOUT	; 04:  Serial output in DL
	 DPMIDOSMAC @LPTOUT,LPTOUT	; 05:  Printer output in DL
	 DPMIDOSMAC @DCONIO,DCONIO	; 06:  Direct console I/O: If DL=FFh, AL<--, else <--DL
	 DPMIDOSMAC @DCONIN,DCONIN	; 07:  Direct keyboard input w/o echo to AL
	 DPMIDOSMAC @KEYIN ,KEYIN	; 08:  Keyboard input w/wait, w/o echo to AL
	 DPMIDOSMAC @KEYSTA,KEYSTA	; 0B:  Check keyboard status (AL=FFh if char is available)
	 DPMIDOSMAC @DRESET,DRESET	; 0D:  Disk reset
	 DPMIDOSMAC @SELDSK,SELDSK	; 0E:  Select disk in DL (origin-0)
	 DPMIDOSMAC @CPM18 ,CPM18	; 18:  CP/M compatibility
	 DPMIDOSMAC @GETDSK,GETDSK	; 19:  Get default disk drive to AL (origin-0)
	 DPMIDOSMAC @CPM1D ,CPM1D	; 1D:  CP/M compatibility
	 DPMIDOSMAC @CPM1E ,CPM1E	; 1E:  CP/M compatibility
	 DPMIDOSMAC @CPM20 ,CPM20	; 20:  CP/M compatibility
	 DPMIDOSMAC @BLDPSP,BLDPSP	; 26:  Create new program segment prefix
	 DPMIDOSMAC @GETDTE,GETDTE	; 2A:  Get system date into CX:DX
	 DPMIDOSMAC @SETDTE,SETDTE	; 2B:  Set system date from CX:DX
	 DPMIDOSMAC @GETTME,GETTME	; 2C:  Get system time into CX:DX
	 DPMIDOSMAC @SETTME,SETTME	; 2D:  Set system time from CX:DX
	 DPMIDOSMAC @VERIFY,VERIFY	; 2E:  Set/reset verify switch
	 DPMIDOSMAC @DOSVER,DOSVER	; 30:  Get DOS version #
	 DPMIDOSMAC @KEEPRC,KEEPRC	; 31:  Terminate process and remain resident, exit code in AL
	 DPMIDOSMAC @CHKBRK,CHKBRK	; 33:  Ctrl-Break check
	 DPMIDOSMAC @FATAD3,FATAD3	; 36:  Get allocation table info of drive in DL
	 DPMIDOSMAC @SWITCH,SWITCH	; 37:  Get (AL=00)/Set (AL=01) switch character
	 DPMIDOSMAC @CLOSF2,CLOSF2	; 3E:  Close file, handle in BX
	 DPMIDOSMAC @MOVFP2,MOVFP2	; 42:  Move file's read/write pointer
	 DPMIDOSMAC @FHCOPY,FHCOPY	; 45:  Copy a file handle from BX to AX
	 DPMIDOSMAC @FHCREA,FHCREA	; 46:  Create a file handle from BX to CX
	 DPMIDOSMAC @GETRC ,GETRC	; 4D:  Get return code from sub-process into AX
	 DPMIDOSMAC @GETVRF,GETVRF	; 54:  Get verify state
	 DPMIDOSMAC @GSTDAT,GSTDAT	; 57:  Get (AL=0)/set (AL=1) a file's date & time in DX, CX
	 DPMIDOSMAC @MACALG,MACALG	; 58:  Memory allocation chain algorithm
	 DPMIDOSMAC @EXTERR,EXTERR	; 59:  Get extended error
	 DPMIDOSMAC @FILACC,FILACC	; 5C:  Lock/unlock file access
	 DPMIDOSMAC @SETFHC,SETFHC	; 67:  Set file handle count to BX for current PSP
	 DPMIDOSMAC @COMFIL,COMFIL	; 68:  Commit file handle BX

; The following DOS functions are not supported by Windows 3.0
; and are handled by returning to the caller

	 DPMIDOSMAC @PTERM, PTERM	; 00:  Program terminate:  CS=>PSP
	 DPMIDOSMAC @OPENF, OPENF	; 0F:  Open file, FCB at DS:DX
	 DPMIDOSMAC @CLOSF, CLOSF	; 10:  Close file, FCB at DS:DX
	 DPMIDOSMAC @RDSEQ, RDSEQ	; 14:  Sequential read, FCB at DS:DX
	 DPMIDOSMAC @WRSEQ, WRSEQ	; 15:  Sequential write, FCB at DS:DX
	 DPMIDOSMAC @CREAF, CREAF	; 16:  Create file, FCB at DS:DX
	 DPMIDOSMAC @RDRND, RDRND	; 21:  Read random, FCB at DS:DX to DTA
	 DPMIDOSMAC @WRRND, WRRND	; 22:  Write random, FCB at DS:DX from DTA
	 DPMIDOSMAC @SIZEF, SIZEF	; 23:  Get file size, FCB at DS:DX
	 DPMIDOSMAC @SETRND,SETRND	; 24:  Set random record field, FCB at DS:DX
	 DPMIDOSMAC @RDBLK, RDBLK	; 27:  Read block random, FCB at DS:DX, CX=rec cnt
	 DPMIDOSMAC @WRBLK, WRBLK	; 28:  Write block random, FCB at DS:DX, CX=rec cnt
.lall


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

	 extrn	 DPMITYPEIG:byte

DLBL	 macro	 LBL
INT21_DPMIJMP_&LBL label word
	 endm			; DLBL


ACT	 macro	 LBL
	 public  INT21_DPMI_&LBL
	 dw	 IGROUP:INT21_DPMI_&LBL
	 endm			; ACT


DOSFN	 macro	 LBL,ARGS
	 dw	 IGROUP:DOSFN_&LBL
ifnb <ARGS>
	 dw	 ARGS
endif				; IFNB
	 endm			; DOSFN


DJMP	 macro	 LBL
	 dw	 IGROUP:DOSFN_JMP
	 dw	 IGROUP:INT21_DPMIJMP_&LBL
	 endm			; DJMP


	 public  JMPTAB21
JMPTAB21 label	 word
.sall
	 DLBL	 STROUT 	; 09:  Display string at DS:eDX
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 STROUT
     DLBL	 STROUT_NEXT
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 RELBUF 	; No need to copy back the displayed string
	 ACT	 STROUT_TAIL	; Go around again
	 DJMP	 STROUT_NEXT
     DLBL	 STROUT_TAIL
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 BKEYIN 	; 0A:  Buffered keyboard input to DS:eDX
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 BKEYIN
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 LOW2EXT,<INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 CKEYIN 	; 0C:  Clear keyboard buffer & invoke input as AL=1,6,7,8,A
	 ACT	 CKEYIN


	 DLBL	 SRCH1		; 11:  Search for first dir entry, FCB at DS:eDX
	 DLBL	 SRCH2		; 12:  Search for next dir entry, FCB at DS:eDX
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 GETDTA,<size DTA_STR>
	 ACT	 SRCH1
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 LOW2EXT,<INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 RELDTA,<size DTA_STR>
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 DELEF		; 13:  Delete file, FCB at DS:eDX
	 DLBL	 RENMF		; 17:  Rename file, FCB at DS:eDX
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 DELEF
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 LOW2EXT,<INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 SETDTA 	; 1A:  Set disk transfer addr to DS:eDX
	 ACT	 SETDTA


	 DLBL	 FATADR 	; 1B:  Get allocation table info of default drive, DS:eBX ==> media type
	 DLBL	 FATAD2 	; 1C:  Get allocation table info of drive in DL, DS:eBX ==> media type
	 DLBL	 GETDPB 	; 1F:  Return DS:eBX ==> drive parameter block for default drive
	 DLBL	 GETDP2 	; 32:  Return DS:eBX ==> drive parameter block for drive DL (origin-1)
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 SIMVMI,21h
	 DOSFN	 SEG2SEL,<@DATASEL,VMC_DS,I31_DS-@I31BACK>
	 DOSFN	 IF32ZX,<VMC_EBX.EHI>
	 DOSFN	 REST_VMCREGS
	 ACT	 EXIT


	 DLBL	 SETINT 	; 25:  Set interrupt vector in AL to DS:eDX
	 ACT	 SETINT


	 DLBL	 PARSF		; 29:  Parse filename at DS:eSI to ES:eDI
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDI>
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 ASCIIZ_LEN,<INTXX_ESI,I31_DS-@I31BACK>
	 ACT	 PARSF
	 DOSFN	 GETBUF,<VMC_ESI.ELO,VMC_DS,INTXX_ESI,I31_DS-@I31BACK>
	 DOSFN	 GETBUF,<VMC_EDI.ELO,VMC_ES,INTXX_EDI,I31_ES-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 LOW2EXT,<INTXX_EDI,I31_ES-@I31BACK>
	 DOSFN	 RELBUF 	; No need to copy back the filename
	 DOSFN	 RELREG,<VMC_ESI.ELO,INTXX_ESI>
;;;;;;;; DOSFN	 IF32ZX,<VMC_ESI.EHI> ; Done in RELREG
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDI>
	 ACT	 EXIT


	 DLBL	 GETDTA 	; 2F:  Get disk transfer addr to ES:eBX
	 ACT	 GETDTA


	 DLBL	 DOSPTR 	; 34:  Return ES:eBX ==> DOS call level byte (internal)
	 DLBL	 GETLST 	; 52:  Get list of lists pointer into ES:eBX
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 SIMVMI,21h
	 DOSFN	 SEG2SEL,<@DATASEL,VMC_ES,I31_ES-@I31BACk>
	 DOSFN	 IF32ZX,<VMC_EBX.EHI>
	 DOSFN	 REST_VMCREGS
	 ACT	 EXIT


	 DLBL	 GETINT 	; 35:  Get interrupt vector in AL to ES:eBX
	 ACT	 GETINT


	 DLBL	 GSTCDI 	; 38:  Get/set country-dependent information
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 GSTCDI
	 DOSFN	 SIMVMI,21h
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT

	 DLBL	 GETCDI 	; Get CDI
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 LOW2EXT,<INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 MKDIR		; 39:  Create a subdirectory named DS:eDX
	 DLBL	 RMDIR		; 3A:  Remove the subdirectory named DS:eDX
	 DLBL	 CHDIR		; 3B:  Change current directory to DS:eDX
	 DLBL	 CREAF2 	; 3C:  Create file, ASCIIZ at DS:eDX, attr in CX
	 DLBL	 OPENF2 	; 3D:  Open file, ASCIIZ at DS:eDX
	 DLBL	 DELEF2 	; 41:  Delete file, ASCIIZ at DS:eDX
	 DLBL	 GSTMOD 	; 43:  Get (AL=0)/set (AL=1) file mode to CX, ASCIIZ at DS:eDX
	 DLBL	 NEWFIL 	; 5B:  Create new file, ASCIIZ at DS:eDX, attr in CX
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 ASCIIZ_LEN,<INTXX_EDX,I31_DS-@I31BACK>
	 ACT	 MKDIR
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 RELBUF 	; No need to copy back the ASCIIZ string
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 READF2 	; 3F:  Read from file BX, to DS:eDX
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_INTXXREG,<INTXX_ECX>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 READF2
     DLBL	 READF2_NEXT
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 ACT	 READF2_TAIL
	 DOSFN	 LOW2EXT,<INTXX_EDX,I31_DS-@I31BACK>
	 ACT	 READF2_NEXT
     DLBL	 READF2_LAST
	 DOSFN	 LOW2EXT,<INTXX_EDX,I31_DS-@I31BACK>
	 ACT	 READF2_DONE
	 DJMP	 READF2_EXIT
     DLBL	 READF2_ERR
;;;;;;;; DOSFN	 RELBUF 	; Nothing to copy back on error
;;;;;;;; DJMP	 READF2_EXIT
     DLBL	 READF2_TAIL
	 DOSFN	 RELBUF 	; Nothing to copy back on error
     DLBL	 READF2_EXIT
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_ECX>
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 WRITF2 	; 40:  Write to file BX, from DS:eDX
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_INTXXREG,<INTXX_ECX>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 WRITF2
     DLBL	 WRITF2_NEXT
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 ACT	 WRITF2_TAIL
	 DOSFN	 RELBUF 	; Nothing to copy back on writes
	 ACT	 WRITF2_NEXT
     DLBL	 WRITF2_LAST
;;;;;;;; DOSFN	 RELBUF 	; Nothing to copy back on writes
;;;;;;;; ACT	 WRITF2_DONE
;;;;;;;; DJMP	 WRITF2_EXIT
     DLBL	 WRITF2_ERR
;;;;;;;; DOSFN	 RELBUF 	; Nothing to copy back on error
;;;;;;;; DJMP	 WRITF2_EXIT
;;;; DLBL	 WRITF2_TAIL
	 DOSFN	 RELBUF 	; Nothing to copy back on writes
;;;; DLBL	 WRITF2_EXIT
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_ECX>
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 IOCTL2 	; 44:  I/O Control for devices, handle in BX
	 ACT	 IOCTL2

	 DLBL	 READDEV	; 4402:  Read from device
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 LOW2EXT,<INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT

	 DLBL	 WRITDEV	; 4403:  Write to device
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 RELBUF 	; No need to copy back control string
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 GETDIR 	; 47:  Get current directory for drive DL to DS:eSI
	 DOSFN	 SAVE_INTXXREG,<INTXX_ESI>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 GETDIR
	 DOSFN	 GETBUF,<VMC_ESI.ELO,VMC_DS,INTXX_ESI,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 LOW2EXT,<INTXX_ESI,I31_DS-@I31BACK>
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_ESI>
	 ACT	 EXIT


	 DLBL	 GETMEM 	; 48:  Get memory (eBX paras)
	 ACT	 GETMEM


	 DLBL	 RELMEM 	; 49:  Release memory (in ES)
	 ACT	 RELMEM


	 DLBL	 MODMEM 	; 4A:  Modify memory block ES to eBX paras
	 ACT	 MODMEM


	 DLBL	 EXEC		; 4B:  Execute a program
	 DOSFN	 SAVE_INTXXREGWORD,<INTXX_EAX.EHI>
	 DOSFN	 SAVE_INTXXREG,<INTXX_EBX>
	 DOSFN	 SAVE_INTXXREG,<INTXX_ECX>
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_INTXXREG,<INTXX_ESI>
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDI>
	 DOSFN	 SAVE_INTXXREG,<INTXX_EBP>
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 ASCIIZ_LEN,<INTXX_EDX,I31_DS-@I31BACK>
	 ACT	 EXEC
	 DJMP	 EXEC_RESTALL

	 DLBL	 EXEC_LE	; Used for 4B00:  Load and execute
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 GETBUF,<VMC_EBX.ELO,VMC_ES,INTXX_EBX,I31_ES-@I31BACK>
	 DOSFN	 EXEC_LEFIX
	 DOSFN	 EXEC_SAVEENV
	 DOSFN	 SIMVMI,21h
	 DOSFN	 EXEC_RESTENV
	 DOSFN	 EXEC_LETERM
	 DOSFN	 RELBUF 	; No need to copy back parameter block
	 DOSFN	 RELBUF 	; ...		       filename
     DLBL	 EXEC_RESTALL
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EBP>
	 DOSFN	 REST_INTXXREG,<INTXX_EDI>
	 DOSFN	 REST_INTXXREG,<INTXX_ESI>
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 DOSFN	 REST_INTXXREG,<INTXX_ECX>
	 DOSFN	 REST_INTXXREG,<INTXX_EBX>
	 DOSFN	 REST_INTXXREGWORD,<INTXX_EAX.EHI>
	 ACT	 EXIT

	 DLBL	 EXEC_SAVEENV_ERR ; We ran out of low DOS memory in EXEC_SAVEENV
	 DOSFN	 EXEC_RESTENV
	 DLBL	 EXEC_LEFIX_ERR ; We ran out of low DOS memory in EXEC_LEFIX
	 DOSFN	 EXEC_LETERM
	 DOSFN	 RELBUF 	; No need to copy back parameter block
	 DOSFN	 RELBUF 	; ...		       filename
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EBX>
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 ERRXMEM


	 DLBL	 EXITRC 	; 4C:  Exit with return code
	 ACT	 EXITRC


	 DLBL	 FIND1		; 4E:  Search for first dir entry, ASCIIZ at DS:eDX
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 GETDTA,<size DTA_STR>
	 DOSFN	 ASCIIZ_LEN,<INTXX_EDX,I31_DS-@I31BACK>
	 ACT	 FIND1
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 RELBUF 	; No need to copy back the ASCIIZ string
	 DOSFN	 RELDTA,<size DTA_STR>
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 FIND2		; 4F:  Search for next dir entry, from DTA
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 GETDTA,<size DTA_STR>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 RELDTA,<size DTA_STR>
	 DOSFN	 REST_VMCREGS
	 ACT	 EXIT


	 DLBL	 SETPSP 	; 50:  Set current PSP to BX (internal)
	 DOSFN	 SAVE_INTXXREG,<INTXX_EBX>
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 SEL2SEG,<VMC_EBX.ELO>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EBX>
	 ACT	 EXIT


	 DLBL	 GETPS0 	; 51:  Get current PSP into BX (same as 62h) (internal)
	 DLBL	 GETPSP 	; 62:  Get current PSP into BX
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 SIMVMI,21h
	 DOSFN	 SEG2SEL,<@DATASEL,VMC_EBX.ELO,INTXX_EBX.ELO>
	 DOSFN	 COPY_INTXXREG,<INTXX_EBX.ELO,VMC_EBX.ELO>
	 DOSFN	 REST_VMCREGS
	 ACT	 EXIT


	 DLBL	 BP2DPB 	; 53:  Translate BPB at DS:eSI to DPB at ES:eBP
	 DOSFN	 SAVE_INTXXREG,<INTXX_ESI>
	 DOSFN	 SAVE_INTXXREG,<INTXX_EBP>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 BP2DPB
	 DOSFN	 GETBUF,<VMC_ESI.ELO,VMC_DS,INTXX_ESI,I31_DS-@I31BACK>
	 DOSFN	 GETBUF,<VMC_EBP.ELO,VMC_ES,INTXX_EBP,I31_ES-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 LOW2EXT,<INTXX_EBP,I31_ES-@I31BACK>
	 DOSFN	 RELBUF 	; No need to copy back the BPB
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EBP>
	 DOSFN	 REST_INTXXREG,<INTXX_ESI>
	 ACT	 EXIT


	 DLBL	 BLDPS2 	; 55:  Create new program segment prefix at DX:0 with top of DOS at SI:0
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_INTXXREG,<INTXX_ESI>
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 SEL2SEG,<VMC_EDX.ELO>
	 DOSFN	 SEL2SEG,<VMC_ESI.ELO>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_ESI>
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 RENMF2 	; 56:  Rename file, from ASCIIZ at DS:eDX to ASCIIZ at ES:eDI
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDI>
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 ASCIIZ_LEN,<INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 ASCIIZ_LEN,<INTXX_EDI,I31_ES-@I31BACK>
	 ACT	 RENMF2
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 GETBUF,<VMC_EDI.ELO,VMC_ES,INTXX_EDI,I31_ES-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 RELBUF 	; No need to copy back the filename
	 DOSFN	 RELBUF 	; No need to copy back the filename
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDI>
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


	 DLBL	 TMPFIL 	; 5A:  Create temporary file, ASCIIZ at DS:eDX, attr in CX
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 ASCIIZ_LEN,<INTXX_EDX,I31_DS-@I31BACK>
	 ACT	 TMPFIL
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 LOW2EXT,<INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


;;;;;;;; DLBL	 ???		; 5D:  ???
;;;;;;;; DLBL	 ???		; 5E:  ???
;;;;;;;; DLBL	 ???		; 5F:  ???


	 DLBL	 FIXPTH 	; 60:  Resolve path in DS:eSI to canonical form in ES:eDI
	 DOSFN	 SAVE_INTXXREG,<INTXX_ESI>
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDI>
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 ASCIIZ_LEN,<INTXX_ESI,I31_DS-@I31BACK>
	 ACT	 FIXPTH
	 DOSFN	 GETBUF,<VMC_ESI.ELO,VMC_DS,INTXX_ESI,I31_DS-@I31BACK>
	 DOSFN	 GETBUF,<VMC_EDI.ELO,VMC_ES,INTXX_EDI,I31_ES-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 LOW2EXT,<INTXX_EDI,I31_ES-@I31BACK>
	 DOSFN	 RELBUF 	; No need to copy back the filename
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDI>
	 DOSFN	 REST_INTXXREG,<INTXX_ESI>
	 ACT	 EXIT


;;;;;;;; DLBL	 ???		; 61:  ???
;;;;;;;; DLBL	 ???		; 63:  ???
;;;;;;;; DLBL	 ???		; 64:  ???


	 DLBL	 GETXCD 	; 65:  Get extended conuntry-dependent information
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDI>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 GETXCD
	 DOSFN	 GETBUF,<VMC_EDI.ELO,VMC_DS,INTXX_EDI,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 LOW2EXT,<INTXX_EDI,I31_DS-@I31BACK>
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDI>
	 ACT	 EXIT


	 DLBL	 GSTSER 	; 69:  Get/set disk serial # for drive BL (origin-1) to DS:eDX
	 DOSFN	 SAVE_INTXXREG,<INTXX_EDX>
	 DOSFN	 SAVE_VMCREGS
	 ACT	 GSTSER
	 DOSFN	 GETBUF,<VMC_EDX.ELO,VMC_DS,INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 LOW2EXT,<INTXX_EDX,I31_DS-@I31BACK>
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_EDX>
	 ACT	 EXIT


;;;;;;;; DLBL	 ???		; 6A:  ???
;;;;;;;; DLBL	 ???		; 6B:  ???


	 DLBL	 XOPCR2 	; 6C:  Extended Open/Create file, ASCIIZ at DS:eSI, attr in CX, mode in BX, flags in DX
	 DOSFN	 SAVE_INTXXREG,<INTXX_ESI>
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 ASCIIZ_LEN,<INTXX_ESI,I31_DS-@I31BACK>
	 ACT	 XOPCR2
	 DOSFN	 GETBUF,<VMC_ESI.ELO,VMC_DS,INTXX_ESI,I31_DS-@I31BACK>
	 DOSFN	 SIMVMI,21h
	 DOSFN	 RELBUF 	; No need to copy back the ASCIIZ string
	 DOSFN	 REST_VMCREGS
	 DOSFN	 REST_INTXXREG,<INTXX_ESI>
	 ACT	 EXIT


; The following DOS functions require no special treatment

	 DLBL	 KEYINE 	; 01:  Keyboard input w/wait & echo to AL
	 DLBL	 CHROUT 	; 02:  Display output in DL to CON:
	 DLBL	 AUXIN		; 03:  Serial input w/wait to AL
	 DLBL	 AUXOUT 	; 04:  Serial output in DL
	 DLBL	 LPTOUT 	; 05:  Printer output in DL
	 DLBL	 DCONIO 	; 06:  Direct console I/O: If DL=FFh, AL<--, else <--DL
	 DLBL	 DCONIN 	; 07:  Direct keyboard input w/o echo to AL
	 DLBL	 KEYIN		; 08:  Keyboard input w/wait, w/o echo to AL
	 DLBL	 KEYSTA 	; 0B:  Check keyboard status (AL=FFh if char is available)
	 DLBL	 DRESET 	; 0D:  Disk reset
	 DLBL	 SELDSK 	; 0E:  Select disk in DL (origin-0)
	 DLBL	 CPM18		; 18:  CP/M compatibility
	 DLBL	 GETDSK 	; 19:  Get default disk drive to AL (origin-0)
	 DLBL	 CPM1D		; 1D:  CP/M compatibility
	 DLBL	 CPM1E		; 1E:  CP/M compatibility
	 DLBL	 CPM20		; 20:  CP/M compatibility
	 DLBL	 BLDPSP 	; 26:  Create new program segment prefix
	 DLBL	 GETDTE 	; 2A:  Get system date into CX:DX
	 DLBL	 SETDTE 	; 2B:  Set system date from CX:DX
	 DLBL	 GETTME 	; 2C:  Get system time into CX:DX
	 DLBL	 SETTME 	; 2D:  Set system time from CX:DX
	 DLBL	 VERIFY 	; 2E:  Set/reset verify switch
	 DLBL	 DOSVER 	; 30:  Get DOS version #
	 DLBL	 KEEPRC 	; 31:  Terminate process and remain resident, exit code in AL
	 DLBL	 CHKBRK 	; 33:  Ctrl-Break check
	 DLBL	 FATAD3 	; 36:  Get allocation table info of drive in DL
	 DLBL	 SWITCH 	; 37:  Get (AL=00)/Set (AL=01) switch character
	 DLBL	 CLOSF2 	; 3E:  Close file, handle in BX
	 DLBL	 MOVFP2 	; 42:  Move file's read/write pointer
	 DLBL	 FHCOPY 	; 45:  Copy a file handle from BX to AX
	 DLBL	 FHCREA 	; 46:  Create a file handle from BX to CX
	 DLBL	 GETRC		; 4D:  Get return code from sub-process into AX
	 DLBL	 GETVRF 	; 54:  Get verify state
	 DLBL	 GSTDAT 	; 57:  Get (AL=0)/set (AL=1) a file's date & time in DX, CX
	 DLBL	 MACALG 	; 58:  Memory allocation chain algorithm
	 DLBL	 EXTERR 	; 59:  Get extended error
	 DLBL	 FILACC 	; 5C:  Lock/unlock file access
	 DLBL	 SETFHC 	; 67:  Set file handle count to BX for current PSP
	 DLBL	 COMFIL 	; 68:  Commit file handle BX

	 DLBL	 PASSTHRU	; Pass through label for all other functions
	 DOSFN	 SAVE_VMCREGS
	 DOSFN	 SIMVMI,21h
	 DOSFN	 REST_VMCREGS
	 ACT	 EXIT

; The following DOS functions are not supported by Windows 3.0
; and are handled by returning to the caller

	 DLBL	 PTERM		; 00:  Program terminate:  CS=>PSP
	 DLBL	 OPENF		; 0F:  Open file, FCB at DS:DX
	 DLBL	 CLOSF		; 10:  Close file, FCB at DS:DX
	 DLBL	 RDSEQ		; 14:  Sequential read, FCB at DS:DX
	 DLBL	 WRSEQ		; 15:  Sequential write, FCB at DS:DX
	 DLBL	 CREAF		; 16:  Create file, FCB at DS:DX
	 DLBL	 RDRND		; 21:  Read random, FCB at DS:DX to DTA
	 DLBL	 WRRND		; 22:  Write random, FCB at DS:DX from DTA
	 DLBL	 SIZEF		; 23:  Get file size, FCB at DS:DX
	 DLBL	 SETRND 	; 24:  Set random record field, FCB at DS:DX
	 DLBL	 RDBLK		; 27:  Read block random, FCB at DS:DX, CX=rec cnt
	 DLBL	 WRBLK		; 28:  Write block random, FCB at DS:DX, CX=rec cnt
	 ACT	 UNSUP
.lall

IDATA	 ends			; End IDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 extrn	 SETLBASE:near
	 extrn	 GET_LDT:near
	 extrn	 GETSET_LDTFIX:near
	 extrn	 CLR_LDTZERO:near
	 extrn	 PMINTCOM:far
	 extrn	 DPMIFN_MODMEM:near
	 extrn	 DPMIFN_GROWMEMHNDL:near
	 extrn	 DPMIFN_LPMSTK:near
	 extrn	 DPMIFN_TERMINATE:near

if @OEM_VIRTUALMEM
	 extrn	 VMM_QUERY:far
endif				; IF @OEM_VIRTUALMEM

	 public  @QMAX_D21_ICODE
@QMAX_D21_ICODE:		; Mark module start in .MAP file

	 FPPROC  INT21_DPMI -- DOS Calls from DPMI Clients
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DOS calls from DPMI clients

On entry:

AH	 =	 function #

|

INT21_STR struc

INT21_EIP dd	 ?		; Caller's EIP
INT21_CS  dw	 ?,?		;	   CS
INT21_EFL dd	 ?		;	   EFL
INT21_ESP dd	 ?		;	   ESP if we came from DPMI call
INT21_SS  dw	 ?,?		;	   SS  ...

INT21_STR ends

; If the caller is at PL0, don't pass on to any DPMI clients

	 test	 [esp].INTDPI_CS,mask $PL ; Izit at PL0?
	 jz	 short INT21_INTRETPM ; Jump if so

; If there's a DPMI client active and it has hooked this interrupt,
; give it a crack at this interrupt.
; Note that if there are no DPMI clients active, then the corresponding
; bit in DPMI_CPIHOOK must be clear.

; Note that we can't use BT with immediate here as MASM 5.10 doesn't
; handle it correctly

	 assume  ss:PGROUP	; Tell the assembler about it
	 test	 DPMI_CPIHOOK[21h/8],1 shl (21h mod 8) ; Izit hooked by current client?
	 assume  ss:nothing	; Tell the assembler about it
	 jz	 short INT21_INTRETPM ; Jump if not

	 mov	 [esp].INTCOM_INTNO,4*21h + offset PGROUP:INTPROC00Z

	 push	 @PMINTCOM_NRM	; Use application stack
	 jmp	 near ptr PMINTCOM ; Jump to common code

; We're back to handle it ourselves

	 public  INT21_INTRETPM
INT21_INTRETPM:
	 PUSHD	 0		; Put pseudo-error code onto stack

	 pushad 		; All EGP registers

	 cld			; Ensure string ops forwardly
	 mov	 ebp,esp	; SS:EBP ==> INTXX_STR
				; (nothing above INTXX_SS is valid)

	 REGSAVE <ds,es>	; Save segment registers

; Note that the above REGSAVE is mapped by I31_STR and must be
; consistent with it

	 mov	 es,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  es:PGROUP	; Tell the assembler about it

	 push	 LPMSTK_FVEC.FSEL ; Save current LPM stack top
	 push	 LPMSTK_FVEC.FOFF ; ...

; Set new LPM stack top for nested callers if it's active
; and we're called from PM, not PL0

	 lea	 eax,[ebp].INTXX_EIP ; SS:EAX ==> INTDPI_STR from PL3
	 push	 eax		; Pass the offset
	 call	 DPMIFN_LPMSTK	; Save new LPM stack as appropriate

; Enable interrupts if the caller has them enabled

	 push	 [ebp].INTXX_EFL.ELO ; Get caller's flags
	 and	 [esp].ELO,not ((mask $NT) or (mask $DF) or (mask $TF)) ; NT=TF=DF=0
	 popf			; Put caller's IF into effect

	 movzx	 eax,[ebp].INTXX_EAX.ELO.HI ; Copy function code
	 mov	 si,DPMIDOS_ACT[eax*(type DPMIDOS_ACT)] ; CS:SI ==> action stream

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 09:  Display string at DS:eDX

; On entry (in PL3 stack):
; DS:eDX ==>	 string to display

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_STROUT:

; Because the string we're asked to print might be in a code
; selector (as is the case with KRNL386), we get the selector
; base and use that via our all memory selector.

	 push	 [ebp-@I31BACK].I31_DS ; Pass selector
	 FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address of selector

	 mov	 edi,eax	; Save for later use

; Determine the length of the EOS-terminated string

	 xor	 ecx,ecx	; Initialize string counter
	 mov	 eax,[ebp].INTXX_EDX ; DS:EAX ==> caller's string
				; Already zeroed to use as dword if 16-bit client
@@:
	 inc	 ecx		; Count in another

	 cmp	 ds:[eax+ecx-1].LO,EOS ; Izit end-of-string?
	 jne	 short @B	; Jump if not

	 dec	 ecx		; Exclude terminator

; ECX	 =	 length of string including terminator
; DS:EAX ==>	 start of string

; Loop through the string in chunks of no more than DPTSS_VMBUFSIZ bytes

INT21_DPMI_STROUT_NEXT:
	 mov	 ebx,ecx	; Copy current size

	 push	 eax		; Save for a moment

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 cmp	 bx,PGROUP:[eax].DPTSS_VMBUFSIZ ; Izit within bounds?
	 jb	 short @F	; Jump if so

	 mov	 bx,PGROUP:[eax].DPTSS_VMBUFSIZ ; Use maximum
	 dec	 bx		; Make room for string terminator
@@:
	 pop	 eax		; Restore

	 inc	 bx		; Count in terminator

	 REGSAVE <eax,ds>	; Save for a moment

	 add	 eax,ebx	; Add to get offset in caller's DS

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

	 mov	 dl,EOS 	; String terminator
	 xchg	 dl,AGROUP:[eax+edi-1] ; Ensure properly terminated

	 REGREST <ds,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 [ebp].INTXX_EDX,eax ; Save as new source offset

	 push	 eax		; Save for a moment

	 push	 bx		; RELBUF:  # bytes to release in buffer
	 push	 bx		; GETBUF:  # leading bytes to copy
	 push	 bx		; GETBUF:  # bytes to allocate in buffer

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

INT21_DPMI_STROUT_TAIL:
	 pop	 eax		; Restore

	 REGSAVE <eax,ds>	; Save for a moment

	 add	 eax,ebx	; Add to get offset in caller's DS

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

	 xchg	 dl,AGROUP:[eax+edi-1] ; Restore previous byte

	 REGREST <ds,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 dec	 bx		; Count out terminator
	 add	 eax,ebx	; Skip to next base address

	 sub	 ecx,ebx	; Less last chunk
	 ja	 short @F	; Jump if there's more to display

	 lea	 si,INT21_DPMIJMP_STROUT_TAIL ; CS:SI ==> action stream
@@:
	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 0A:  Buffered keyboard input to DS:eDX

; On entry (in PL3 stack):
; DS:eDX ==>	 buffer

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_BKEYIN:
	 mov	 eax,[ebp].INTXX_EDX ; DS:EAX ==> caller's buffer
				; Already zeroed to use as dword if 16-bit client
	 movzx	 ax,ds:[eax].LO ; Get the buffer length byte
	 add	 ax,2		; Plus total and actual length bytes

	 push	 ax		; LOW2EXT:  # bytes to release (entire buffer)
	 push	 ax		; LOW2EXT:  # trailing bytes to copy (entire buffer)
	 push	 1		; GETBUF:   # leading bytes to copy (buffer length byte)
	 push	 ax		; GETBUF:   # bytes to allocate (entire buffer)

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 0C:  Clear keyboard buffer & invoke input as AL=1,6,7,8,A

; On entry (in PL3 stack):
; AL	 =	 function #

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_CKEYIN:
	 mov	 al,[ebp].INTXX_EAX.ELO.LO ; Get function code from AL

	 cmp	 al,@KEYINE	; Izit Keyboard input w/wait & echo to AL?
	 je	 short INT21_DPMI_CKEYIN_KEYINE ; Jump if so

	 cmp	 al,@DCONIO	; Izit Direct console I/O: If DL=FFh, AL<--, else <--DL?
	 je	 short INT21_DPMI_CKEYIN_DCONIO ; Jump if so

	 cmp	 al,@DCONIN	; Izit Direct keyboard input w/o echo to AL?
	 je	 short INT21_DPMI_CKEYIN_DCONIN ; Jump if so

	 cmp	 al,@KEYIN	; Izit Keyboard input w/wait, w/o echo to AL?
	 je	 short INT21_DPMI_CKEYIN_KEYIN ; Jump if so

	 cmp	 al,@BKEYIN	; Izit Buffered keyboard input to DS:eDX?
	 je	 short INT21_DPMI_CKEYIN_BKEYIN ; Jump if so

; None of the above:  ignore it

	 jmp	 INT21_DPMI_EXIT ; Join common exit code


INT21_DPMI_CKEYIN_KEYINE:
	 lea	 si,INT21_DPMIJMP_KEYINE ; CS:SI ==> action stream

	 jmp	 short INT21_DPMI_CKEYIN_COM ; Join common code

INT21_DPMI_CKEYIN_DCONIO:
	 lea	 si,INT21_DPMIJMP_DCONIO ; CS:SI ==> action stream

	 jmp	 short INT21_DPMI_CKEYIN_COM ; Join common code

INT21_DPMI_CKEYIN_DCONIN:
	 lea	 si,INT21_DPMIJMP_DCONIN ; CS:SI ==> action stream

	 jmp	 short INT21_DPMI_CKEYIN_COM ; Join common code

INT21_DPMI_CKEYIN_KEYIN:
	 lea	 si,INT21_DPMIJMP_KEYIN ; CS:SI ==> action stream

	 jmp	 short INT21_DPMI_CKEYIN_COM ; Join common code

INT21_DPMI_CKEYIN_BKEYIN:
	 lea	 si,INT21_DPMIJMP_BKEYIN ; CS:SI ==> action stream
INT21_DPMI_CKEYIN_COM:
	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 11:  Search for first dir entry, FCB at DS:eDX
; 12:  Search for next dir entry, FCB at DS:eDX
; 13:  Delete file, FCB at DS:eDX
; 17:  Rename file, FCB at DS:eDX

; On entry (in PL3 stack):
; DS:eDX ==>	 FCB

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_SRCH1:
INT21_DPMI_DELEF:

; If this is an extended FCB, use (size XFCB_STR),
; otherwise use (size FCB_STR)

	 mov	 ebx,[ebp].INTXX_EDX ; DS:EBX ==> caller's buffer
				; Already zeroed to use as dword if 16-bit client

	 mov	 ax,size XFCB_STR ; Assume it's extended FCB

	 cmp	 ds:[ebx].XFCB_PREF,0FFh ; Izit extended FCB?
	 je	 short @F	; Jump if so

	 mov	 ax,size FCB_STR ; It's not extended
@@:
	 push	 ax		; LOW2EXT:  # bytes to release
	 push	 ax		; LOW2EXT:  # trailing bytes to copy
	 push	 ax		; GETBUF:   # leading bytes to copy
	 push	 ax		; GETBUF:   # bytes to allocate

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 1A:  Set disk transfer addr to DS:eDX

; On entry (in PL3 stack):
; DS:eDX ==>	 DTA

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_SETDTA:
	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 mov	 bx,[ebp-@I31BACK].I31_DS ; Get DTA selector
	 mov	 PGROUP:[eax].DPTSS_DTA_FVEC.FSEL,bx ; Set Selector of DTA

	 mov	 ebx,[ebp].INTXX_EDX ; Get DTA offset
	 IF16ZX  bx,IG		; Zero to use as dword if 16-bit client

	 mov	 PGROUP:[eax].DPTSS_DTA_FVEC.FOFF,ebx ; Set Offset of DTA

	 jmp	 INT21_DPMI_EXIT ; Join common exit code

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 25:  Set interrupt vector in AL to DS:eDX

; On entry (in PL3 stack):
; AL	 =	 interrupt #
; DS:eDX ==>	 interrupt handler

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_SETINT:
	 mov	 bl,[ebp].INTXX_EAX.ELO.LO ; Get interrupt # from AL
	 mov	 cx,[ebp-@I31BACK].I31_DS ; Get selector
	 mov	 edx,[ebp].INTXX_EDX ; Get offset (16- or 32-bit)

; Note that if the client is 32-bit, they should give to us
; the address in DS:EDX which we pass onto the SETPMIV call.
; If the client is 16-bit, it doesn't hurt for us to read the
; EDX register above as the DPMI call will ignore the high-order word.

	 DPMICALL0 @DPMI_SETPMIV ; Request DPMI service
	 jnc	 near ptr INT21_DPMI_EXIT ; Jump if all went OK

	 int	 03h		; Call our debugger

	 jmp	 INT21_DPMI_ERR ; Join common error code

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 29:  Parse filename at DS:eSI to ES:eDI
; On entry (in PL3 stack):
; DS:eSI ==>	 filename to parse
; ES:eDI ==>	 FCB or XFCB

; On exit (in PL3 stack):
; AL	 =	 flags
; DS:eSI ==>	 first character after the filename

; On entry (in registers):
; SS:ESP =	 ASCIIZ length in bytes
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_PARSF:
	 pop	 bx		; Restore ASCIIZ length of filename

	 mov	 ds,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 eax,[ebp].INTXX_ESI ; DS:EBX ==> caller's filename to parse
	 IF16ZX  ax,IG		; Zero to use as dword if 16-bit client
	 mov	 [ebp].INTXX_ESI,eax ; Save back for GETBUF (note we clobber
				; the high-order word for 16-bit clients)
	 mov	 edx,[ebp].INTXX_EDI ; DS:EDX ==> caller's FCB
				; Already zeroed to use as dword if 16-bit client

; If this is an extended FCB, use (size XFCB_STR),
; otherwise use (size FCB_STR)

	 mov	 ax,size XFCB_STR ; Assume it's extended FCB

	 cmp	 ds:[edx].XFCB_PREF,0FFh ; Izit extended FCB?
	 je	 short @F	; Jump if so

	 mov	 ax,size FCB_STR ; It's not extended
@@:
	 push	 bx		; RELBUF:   # bytes to release for filename
	 push	 ax		; LOW2EXT:  # bytes to release for xFCB
	 push	 ax		; LOW2EXT:  # trailing bytes to copy (entire xFCB)
	 push	 ax		; GETBUF:   # leading bytes to copy (entire xFCB)
	 push	 ax		; GETBUF:   # bytes to allocate for xFCB
	 push	 bx		; GETBUF:   # leading bytes to copy (entire filename)
	 push	 bx		; GETBUF:   # bytes to allocate for filename

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 2F:  Get disk transfer addr to ES:eBX

; On exit (in PL3 stack):
; ES:eBX ==>	 DTA

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_GETDTA:
	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 mov	 bx,PGROUP:[eax].DPTSS_DTA_FVEC.FSEL ; Get Selector of DTA
	 mov	 [ebp-@I31BACK].I31_ES,bx ; Return in caller's ES

	 mov	 ebx,PGROUP:[eax].DPTSS_DTA_FVEC.FOFF ; Get Offset of DTA

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short @F	; Jump if so

	 mov	 [ebp].INTXX_EBX,ebx ; Return in caller's ES:EBX

	 jmp	 INT21_DPMI_EXIT ; Join common exit code

@@:
	 mov	 [ebp].INTXX_EBX.ELO,bx ; Return in caller's ES:BX

	 jmp	 INT21_DPMI_EXIT ; Join common exit code

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 35:  Get interrupt vector in AL to ES:eBX

; On entry (in PL3 stack):
; AL	 =	 interrupt #

; On exit (in PL3 stack):
; ES:eBX ==>	 interrupt handler

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_GETINT:
	 mov	 bl,[ebp].INTXX_EAX.ELO.LO ; Get interrupt # from AL
	 DPMICALL0 @DPMI_GETPMIV ; Request DPMI service
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger
@@:

; CX:eDX ==> Sel:Off of protected mode interrupt handler

	 mov	 [ebp-@I31BACK].I31_ES,cx ; Return in caller's ES

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short @F	; Jump if so

	 mov	 [ebp].INTXX_EBX,edx ; Return in caller's EBX

	 jmp	 INT21_DPMI_EXIT ; Join common OK code

@@:
	 mov	 [ebp].INTXX_EBX.ELO,dx ; Return in caller's BX

	 jmp	 INT21_DPMI_EXIT ; Join common OK code

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 38:  Get/set country-dependent information

; On entry (in PL3 stack):
; DS:eDX ==>	 buffer to use

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_GSTCDI:
	 mov	 VMCREGS.VMC_DS,-1 ; Save in structure in case it's Set CDI

	 cmp	 [ebp].INTXX_EDX.ELO,-1 ; Izit Set CDI?
	 je	 short INT21_DPMI_SETCDI ; Jump if so

	 mov	 ax,size CDI_STR ; Get size of CDI structure

	 push	 ax		; LOW2EXT:  # bytes to release
	 push	 ax		; LOW2EXT:  # trailing bytes to copy (entire buffer)
	 push	 0		; GETBUF:   # leading bytes to copy (nothing)
	 push	 ax		; GETBUF:   # bytes to allocate

	 lea	 si,INT21_DPMIJMP_GETCDI ; CS:SI ==> action stream
INT21_DPMI_SETCDI:
	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 39:  Create a subdirectory named DS:eDX
; 3A:  Remove the subdirectory named DS:eDX
; 3B:  Change current directory to DS:eDX
; 3C:  Create file, ASCIIZ at DS:eDX, attr in CX
; 3D:  Open file, ASCIIZ at DS:eDX
; 41:  Delete file, ASCIIZ at DS:eDX
; 43:  Get (AL=0)/set (AL=1) file mode to CX, ASCIIZ at DS:eDX
; 4E:  Search for first dir entry, ASCIIZ at DS:eDX
; 5B:  Create new file, ASCIIZ at DS:eDX, attr in CX

; On entry (in PL3 stack):
; AL	 =	 function # for some functions
; CX	 =	 attr for some functions
; DS:eDX ==>	 ASCIIZ string for some functions

; 6C:  Extended Open/Create file, ASCIIZ at DS:eSI, attr in CX, mode in BX, flags in DX

; On entry (in PL3 stack):
; BX	 =	 mode
; CX	 =	 attr
; DX	 =	 flags
; DS:eSI ==>	 ASCIIZ string

; On entry (in registers):
; SS:ESP =	 ASCIIZ length in bytes
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_MKDIR:
INT21_DPMI_FIND1:
INT21_DPMI_XOPCR2:
	 pop	 bx		; Restore ASCIIZ length of filename

	 push	 bx		; RELBUF:  # bytes to release
	 push	 bx		; GETBUF:  # leading bytes to copy
	 push	 bx		; GETBUF:  # bytes to allocate

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 5A:  Create temporary file, ASCIIZ at DS:eDX, attr in CX

; On entry (in PL3 stack):
; AL	 =	 function # (5Ah)
; CX	 =	 attr
; DS:eDX ==>	 ASCIIZ string

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_TMPFIL:
	 pop	 bx		; Restore ASCIIZ length of filename
	 add	 bx,12+1	; Reserve space for temporary filename

	 push	 bx		; LOW2EXT:  # bytes to release (entire buffer)
	 push	 bx		; LOW2EXT:  # trailing bytes to copy (entire buffer)
	 push	 bx		; GETBUF:  # leading bytes to copy
	 push	 bx		; GETBUF:  # bytes to allocate

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 3F:  Read from file BX, to DS:eDX

; On entry (in PL3 stack):
; eCX	 =	 # bytes to read into buffer
; DS:eDX ==>	 input buffer

; On exit (in PL3 stack):
; eAX	 =	 # bytes read

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_READF2:
	 mov	 eax,[ebp].INTXX_EDX ; DS:EAX ==> caller's buffer
				; Already zeroed to use as dword if 16-bit client
	 mov	 ecx,[ebp].INTXX_ECX ; Get # bytes to read
				; Already zeroed to use as dword if 16-bit client

; ECX	 =	 length of buffer
; DS:EAX ==>	 start of buffer

; Loop through the buffer in chunks of no more than DPTSS_VMBUFSIZ bytes

	 xor	 edx,edx	; Initialize count of # bytes actually read

	 mov	 di,VMCREGS.VMC_EAX.ELO ; Save caller's function code

	 push	 eax		; Save base address
INT21_DPMI_READF2_NEXT:
	 pop	 eax		; Restore base address

	 mov	 [ebp].INTXX_EDX,eax ; Save as next destin offset

	 push	 eax		; Save base address

	 lea	 si,INT21_DPMIJMP_READF2_NEXT ; CS:SI ==> action stream

	 mov	 ebx,ecx	; Copy current size

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 cmp	 ebx,PGROUP:[eax].DPTSS_VMBUFSIZ.EDD ; Izit within bounds?
	 jb	 short @F	; Jump if so

	 mov	 ebx,PGROUP:[eax].DPTSS_VMBUFSIZ.EDD ; Use maximum
@@:
	 mov	 VMCREGS.VMC_ECX.ELO,bx ; Save as # bytes to transfer
	 mov	 VMCREGS.VMC_EAX.ELO,di ; Save as function code

	 push	 0		; GETBUF:   # leading bytes to copy
	 push	 bx		; GETBUF:   # bytes to allocate

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

INT21_DPMI_READF2_TAIL:
	 pop	 eax		; Restore base address

; The CPU flags from the operation are now in VMC_FL
; If CF is set, there was an error and we should quit
; If CF is clear, VMC_EAX.ELO has the # bytes transferred
; which we should accumulate

	 test	 VMCREGS.VMC_FL,mask $CF ; Izit an error?
	 jnz	 short INT21_DPMI_READF2_ERR ; Jump if so

	 push	 ebx		; Save for a moment

	 movzx	 ebx,VMCREGS.VMC_EAX.ELO ; Get actual # bytes transferred
	 add	 edx,ebx	; Accumulate # bytes transferred
	 add	 eax,ebx	; Skip to next base address
	 sub	 ecx,ebx	; Less last chunk

	 pop	 ebx		; Restore

	 cmp	 VMCREGS.VMC_EAX.ELO,0 ; Did we reach EOF?
	 je	 short INT21_DPMI_READF2_DONE0 ; Jump if so

; If DOS transferred fewer bytes than requested, copy those and quit

	 cmp	 VMCREGS.VMC_EAX.ELO,bx ; Compare actual vs. requested
	 jb	 short INT21_DPMI_READF2_LAST ; Jump if it's short

; We need a trailing check on reading zero bytes to
; terminate early.

	 jecxz	 INT21_DPMI_READF2_LAST ; Jump if there's nothing more to do

	 push	 eax		; Save base address

	 push	 bx		; LOW2EXT:  # bytes to release
	 push	 VMCREGS.VMC_EAX.ELO ; LOW2EXT:  # trailing bytes to copy

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

INT21_DPMI_READF2_LAST:
	 lea	 si,INT21_DPMIJMP_READF2_LAST ; CS:SI ==> action stream

	 push	 bx		; LOW2EXT:  # bytes to release
	 push	 VMCREGS.VMC_EAX.ELO ; LOW2EXT:  # trailing bytes to copy

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

INT21_DPMI_READF2_DONE0:
	 lea	 si,INT21_DPMIJMP_READF2_TAIL ; CS:SI ==> action stream

	 push	 bx		; RELBUF:  # bytes to release
INT21_DPMI_READF2_DONE:
	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short INT21_DPMI_READF2_DONE1 ; Jump if so

	 mov	 VMCREGS.VMC_EAX,edx ; Return # bytes transferred

	 jmp	 short @F	; Join common code

INT21_DPMI_READF2_DONE1:
	 mov	 VMCREGS.VMC_EAX.ELO,dx ; Return # bytes transferred
@@:
	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

INT21_DPMI_READF2_ERR:
	 lea	 si,INT21_DPMIJMP_READF2_ERR ; CS:SI ==> action stream

	 push	 bx		; RELBUF:  # bytes to release

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 40:  Write to file BX, from DS:eDX

; On entry (in PL3 stack):
; eCX	 =	 # bytes to write from buffer
; DS:eDX ==>	 output buffer

; On exit (in PL3 stack):
; eAX	 =	 # bytes written

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_WRITF2:
	 mov	 eax,[ebp].INTXX_EDX ; DS:EAX ==> caller's buffer
				; Already zeroed to use as dword if 16-bit client
	 mov	 ecx,[ebp].INTXX_ECX ; Get # bytes to write
				; Already zeroed to use as dword if 16-bit client

; ECX	 =	 length of buffer
; DS:EAX ==>	 start of buffer

; Loop through the buffer in chunks of no more than DPTSS_VMBUFSIZ bytes

	 xor	 edx,edx	; Initialize count of # bytes actually written

	 mov	 di,VMCREGS.VMC_EAX.ELO ; Save caller's function code

	 push	 eax		; Save base address
INT21_DPMI_WRITF2_NEXT:
	 pop	 eax		; Restore base address

	 mov	 [ebp].INTXX_EDX,eax ; Save as next source offset

	 push	 eax		; Save base address

	 lea	 si,INT21_DPMIJMP_WRITF2_NEXT ; CS:SI ==> action stream

	 mov	 ebx,ecx	; Copy current size

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 cmp	 ebx,PGROUP:[eax].DPTSS_VMBUFSIZ.EDD ; Izit within bounds?
	 jb	 short @F	; Jump if so

	 mov	 ebx,PGROUP:[eax].DPTSS_VMBUFSIZ.EDD ; Use maximum
@@:
	 mov	 VMCREGS.VMC_ECX.ELO,bx ; Save as # bytes to transfer
	 mov	 VMCREGS.VMC_EAX.ELO,di ; Save as function code

	 push	 bx		; GETBUF:  # leading bytes to copy
	 push	 bx		; GETBUF:  # bytes to allocate

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

INT21_DPMI_WRITF2_TAIL:
	 pop	 eax		; Restore base address

; The CPU flags from the operation are now in VMC_FL
; If CF is set, there was an error and we should quit
; If CF is clear, VMC_EAX.ELO has the # bytes transferred
; which we should accumulate

	 test	 VMCREGS.VMC_FL,mask $CF ; Izit an error?
	 jnz	 short INT21_DPMI_WRITF2_ERR ; Jump if so

	 push	 ebx		; Save for a moment

	 movzx	 ebx,VMCREGS.VMC_EAX.ELO ; Get actual # bytes transferred
	 add	 edx,ebx	; Accumulate # bytes transferred
	 add	 eax,ebx	; Skip to next base address
	 sub	 ecx,ebx	; Less last chunk

	 pop	 ebx		; Restore

	 cmp	 VMCREGS.VMC_EAX.ELO,0 ; Did we reach EOF?
	 je	 short INT21_DPMI_WRITF2_DONE0 ; Jump if so

; If DOS transferred fewer bytes than requested, just quit

	 cmp	 VMCREGS.VMC_EAX.ELO,bx ; Compare actual vs. requested
	 jb	 short INT21_DPMI_WRITF2_LAST ; Jump if it's short

; We need a trailing check on writing zero bytes to
; avoid truncating the file on the next iteration.

	 jecxz	 INT21_DPMI_WRITF2_LAST ; Jump if there's nothing more to do

	 push	 eax		; Save base address

	 push	 bx		; RELBUF:  # bytes to release

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

INT21_DPMI_WRITF2_LAST:
;;;;;;;; lea	 si,INT21_DPMIJMP_WRITF2_LAST ; CS:SI ==> action stream
;;;;;;;;
;;;;;;;; push	 bx		; RELBUF:  # bytes to release
;;;;;;;;
;;;;;;;; lods	 JMPTAB21[si]	; Get next action
;;;;;;;; jmp	 ax		; Take appropriate action
;;;;;;;;
INT21_DPMI_WRITF2_DONE0:
;;;;;;;; lea	 si,INT21_DPMIJMP_WRITF2_TAIL ; CS:SI ==> action stream
;;;;;;;;
;;;;;;;; push	 bx		; RELBUF:  # bytes to release
INT21_DPMI_WRITF2_DONE:
	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short INT21_DPMI_WRITF2_DONE1 ; Jump if so

	 mov	 VMCREGS.VMC_EAX,edx ; Return # bytes transferred

	 jmp	 short @F	; Join common code

INT21_DPMI_WRITF2_DONE1:
	 mov	 VMCREGS.VMC_EAX.ELO,dx ; Return # bytes transferred
@@:
;;;;;;;; lods	 JMPTAB21[si]	; Get next action
;;;;;;;; jmp	 ax		; Take appropriate action
;;;;;;;;
INT21_DPMI_WRITF2_ERR:
	 lea	 si,INT21_DPMIJMP_WRITF2_ERR ; CS:SI ==> action stream

	 push	 bx		; RELBUF:  # bytes to release

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
; 44:  I/O Control for devices, handle in BX

; On entry (in PL3 stack):
; AL	 =	 function code
; Other register meanings dependent upon
; the function code

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_IOCTL2:
	 mov	 al,[ebp].INTXX_EAX.ELO.LO ; Get function code from AL

; 4400:  Get device information
; 4401:  Set device information

	 cmp	 al,01h 	; Izit Get/Set Device Info?
	 jbe	 short INT21_DPMI_IOCTL2_PASSTHRU ; Jump if so

; 4402:  Read control string from char device

	 cmp	 al,02h 	; Izit read control string from char device?
	 je	 short INT21_DPMI_IOCTL2_READDEV ; Jump if so

; 4403:  Write control string to char device

	 cmp	 al,03h 	; Izit write control string to char device?
	 je	 short INT21_DPMI_IOCTL2_WRITDEV ; Jump if so

; 4404:  Read control string from block device

	 cmp	 al,04h 	; Izit read control string from block device?
	 je	 short INT21_DPMI_IOCTL2_READDEV ; Jump if so

; 4405:  Write control string to block device

	 cmp	 al,05h 	; Izit write control string to block device?
	 je	 short INT21_DPMI_IOCTL2_WRITDEV ; Jump if so

; The following functions are all pass through
; 4406:  Get input device status
; 4407:  Get output device status
; 4408:  Duzit support removable media?
; 4409:  Izit a drive on a network?
; 440A:  Izit a file on a network?
; 440B:  Set sharing and lock retries

	 cmp	 al,0Bh 	; Izit pass through?
	 jbe	 short INT21_DPMI_IOCTL2_PASSTHRU ; Jump if so

; 440C:  Generic IOCTL for character devices

	 cmp	 al,0Ch 	; Izit generic IOCTL for char devices?
	 je	 short INT21_DPMI_IOCTL2_GENDEV ; Jump if so

; 440D:  Generic IOCTL for block devices

	 cmp	 al,0Dh 	; Izit generic IOCTL for block devices?
	 je	 near ptr INT21_DPMI_IOCTL2_GENBLK ; Jump if so

; 440E:  Check multiple drives per block device
; 440F:  Change logical drive

	 cmp	 al,0Fh 	; Izit pass through?
	 jbe	 short INT21_DPMI_IOCTL2_PASSTHRU ; Jump if so

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action


INT21_DPMI_IOCTL2_PASSTHRU:
	 lea	 si,INT21_DPMIJMP_PASSTHRU ; CS:SI ==> action stream

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action


INT21_DPMI_IOCTL2_READDEV:
INT21_DPMI_IOCTL2_READBLK:
	 mov	 ebx,[ebp].INTXX_ECX ; Get # bytes to read
;;;;;;;; IF16ZX  bx,IG		; Zero to use as dword if 16-bit client
INT21_DPMI_IOCTL2_READ:
	 push	 [ebp].INTXX_EDX ; Save over following code as
				; we'll clobber it
	 call	 SAVE_VMCREGS	; Save current values of VMCREGS on stack
	 call	 EGP2VMCREGS	; Transfer caller's EGP registers to VMCREGS

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 jne	 short @F	; Jump if not

	 mov	 [ebp].INTXX_EDX.EHI,0 ; Zero to use as dword
@@:
	 push	 bx		; LOW2EXT:  # bytes to release
	 push	 bx		; LOW2EXT:  # trailing bytes to copy
	 push	 1		; GETBUF:   # leading bytes to copy
	 push	 bx		; GETBUF:   # bytes to allocate

	 lea	 si,INT21_DPMIJMP_READDEV ; CS:SI ==> action stream

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action


INT21_DPMI_IOCTL2_WRITDEV:
INT21_DPMI_IOCTL2_WRITBLK:
	 mov	 ebx,[ebp].INTXX_ECX ; Get # bytes to read
;;;;;;;; IF16ZX  bx,IG		; Zero to use as dword if 16-bit client
INT21_DPMI_IOCTL2_WRITE:
	 push	 [ebp].INTXX_EDX ; Save over following code as
				; we'll clobber it
	 call	 SAVE_VMCREGS	; Save current values of VMCREGS on stack
	 call	 EGP2VMCREGS	; Transfer caller's EGP registers to VMCREGS

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 jne	 short @F	; Jump if not

	 mov	 [ebp].INTXX_EDX.EHI,0 ; Zero to use as dword
@@:
	 push	 bx		; RELBUF:  # bytes to release
	 push	 bx		; GETBUF:  # leading bytes to copy
	 push	 bx		; GETBUF:  # bytes to allocate

	 lea	 si,INT21_DPMIJMP_WRITDEV ; CS:SI ==> action stream

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action


INT21_DPMI_IOCTL2_GENDEV:
	 mov	 al,[ebp].INTXX_ECX.ELO.LO ; Get subfunction code from CL

	 cmp	 al,4Ah 	; Izit Set Code Page?
	 je	 short INT21_DPMI_IOCTL2_GENDEV_SCP ; Jump if so

	 cmp	 al,4Ch 	; Izit Prepare Start?
	 je	 short INT21_DPMI_IOCTL2_GENDEV_PS ; Jump if so

	 cmp	 al,4Dh 	; Izit Prepare End?
	 je	 short INT21_DPMI_IOCTL2_GENDEV_PE ; Jump if so

	 cmp	 al,6Ah 	; Izit Get Code Page?
	 je	 short INT21_DPMI_IOCTL2_GENDEV_GCP ; Jump if so

	 cmp	 al,6Bh 	; Izit Get Prepare List?
	 je	 short INT21_DPMI_IOCTL2_GENDEV_GPL ; Jump if so

; The subfunction code is not supported

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action


INT21_DPMI_IOCTL2_GENDEV_PS:
	 mov	 ds,[ebp-@I31BACK].I31_DS ; Get callers' DS
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ebx,[ebp].INTXX_EDX ; DS:eBX ==> caller's buffer
	 IF16ZX  bx,IG		; Zero to use as dword if 16-bit client
	 mov	 bx,ds:[ebx+2]	; Get PS_LENGTH in bytes
	 add	 bx,2		; Plus size of control flags

	 jmp	 INT21_DPMI_IOCTL2_WRITE ; Join common code


INT21_DPMI_IOCTL2_GENDEV_SCP:
INT21_DPMI_IOCTL2_GENDEV_PE:
	 mov	 ds,[ebp-@I31BACK].I31_DS ; Get callers' DS
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ebx,[ebp].INTXX_EDX ; DS:eBX ==> caller's buffer
	 IF16ZX  bx,IG		; Zero to use as dword if 16-bit client
	 mov	 bx,ds:[ebx]	; Get Packet Length in bytes

	 jmp	 INT21_DPMI_IOCTL2_WRITE ; Join common code


INT21_DPMI_IOCTL2_GENDEV_GCP:
INT21_DPMI_IOCTL2_GENDEV_GPL:
	 mov	 ds,[ebp-@I31BACK].I31_DS ; Get callers' DS
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ebx,[ebp].INTXX_EDX ; DS:eBX ==> caller's buffer
	 IF16ZX  bx,IG		; Zero to use as dword if 16-bit client
	 mov	 bx,ds:[ebx]	; Get Packet Length in bytes

	 jmp	 INT21_DPMI_IOCTL2_READ ; Join common code


INT21_DPMI_IOCTL2_GENBLK:
	 mov	 al,[ebp].INTXX_ECX.ELO.LO ; Get subfunction code from CL

	 mov	 bx,size DP_STR ; Get size of Device Parameter structure

	 cmp	 al,40h 	; Izit Set Device Parameters?
	 je	 near ptr INT21_DPMI_IOCTL2_WRITE ; Jump if so

	 cmp	 al,60h 	; Izit Get Device Parameters?
	 je	 near ptr INT21_DPMI_IOCTL2_READ ; Jump if so

; We won't support the following two calls until we translate the
; transfer address in TIO_VEC as well as figure out the track byte size
;;;;;;;;
;;;;;;;; mov	 bx,size TIO_STR ; Get size of Track I/O structure
;;;;;;;;
;;;;;;;; cmp	 al,41h 	; Izit Write Track?
;;;;;;;; je	 short INT21_DPMI_IOCTL2_WRITE ; Jump if so
;;;;;;;;
;;;;;;;; cmp	 al,61h 	; Izit Read Track?
;;;;;;;; je	 short INT21_DPMI_IOCTL2_READ ; Jump if so
;;;;;;;;
	 mov	 bx,size TFV_STR ; Get size of Track Format/Verify structure

	 cmp	 al,42h 	; Izit Format and Verify a track?
	 je	 near ptr INT21_DPMI_IOCTL2_WRITE ; Jump if so

	 cmp	 al,62h 	; Izit Verify a track?
	 je	 near ptr INT21_DPMI_IOCTL2_WRITE ; Jump if so

	 mov	 bx,size AF_STR ; Get size of Access Flag structure

	 cmp	 al,47h 	; Izit Set Access Flag?
	 je	 near ptr INT21_DPMI_IOCTL2_WRITE ; Jump if so

	 cmp	 al,67h 	; Izit Get Access Flag?
	 je	 near ptr INT21_DPMI_IOCTL2_READ ; Jump if so

; The subfunction code is not supported

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 47:  Get current directory for drive DL to DS:eSI

; On entry (in PL3 stack):
; DL	 =	 drive #
; DS:eSI ==>	 buffer

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_GETDIR:
	 mov	 ax,64		; Use maximum directory name size

	 push	 ax		; LOW2EXT   # bytes to release
	 push	 ax		; LOW2EXT:  # trailing bytes to copy
	 push	 0		; GETBUF:   # leading bytes to copy
	 push	 ax		; GETBUF:   # bytes to allocate

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 48:  Get memory (eBX paras)

; On entry (in PL3 stack):
; eBX	 =	 # paras to allocate

; On exit (in PL3 stack):
; AX	 =	 selector of allocated memory

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

; The memory is rounded up to the next @DPMI_BOUND boundary and allocated
; from the CMP.

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_GETMEM:
	 mov	 ds,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 eax,[ebp].INTXX_EBX ; Get # paras to allocate
	 IF16ZX  ax,IG		; Zero to use as dword if 16-bit client

; Note we must fail the call for -1 paras (although for 16-bit programs,
; we might very well have that much memory to allocate) because some
; programs (well, if you must know, it's Borland's TASMX) expect it
; to fail and don't bother to check the return code.

; Note that the above value of -1 is 0000FFFF for 16-bit programs, and
; FFFFFFFF for 32-bit programs.

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short INT21_DPMI_GETMEM16A ; Jump if so

	 cmp	 eax,-1 	; Izit maximum # paras?
	 je	 short INT21_DPMI_GETMEM_NOMEM ; Jump if so

	 jmp	 short @F	; Join common code

INT21_DPMI_GETMEM16A:
	 cmp	 ax,-1		; Izit maximum # paras?
	 je	 short INT21_DPMI_GETMEM_NOMEM ; Jump if so
@@:
	 shl	 eax,4-0	; Convert from paras to bytes

	 add	 eax,@DPMI_BOUND-1 ; Round up to
	 jc	 short INT21_DPMI_GETMEM_NOMEM ; Jump if truly ridiculous

	 and	 eax,not (@DPMI_BOUND-1) ; ... @DPMI_BOUND boundary

	 push	 @ALLOC_DPMI	; Tell 'em what kind of memory we're allocating
	 push	 eax		; Pass # bytes to allocate
	 FIXICALL PGROUP:FALLOCMEM,DTE_CS2 ; Allocate 'em
				; Return with EBX = linear address of memory
	 jnc	 short INT21_DPMI_GETMEM_MEMOK ; Jump if memory found
INT21_DPMI_GETMEM_NOMEM:

; We're out of memory, find out how much we actually have
; and return that to the caller

if @OEM_VIRTUALMEM
	 test	 VMM_FLAG,@VMM_SYSINIT		; Izit present?
	 jz	 short @F
	 FCALL	 VMM_QUERY	; Request free committable memory size
	 jmp	 short INT21_DPMI_GETMEM_SKIP
@@:				; Return with EDX = size of largest in 1KB
endif				; IF @OEM_VIRTUALMEM
	 push	 @ALLOC_DPMI	; Pass allocation type
	 FIXICALL PGROUP:FQRY_PGCNT,DTE_CS2 ; Request free memory size
				; Return with EAX = # available 1KB
				; ...	      EDX = size of largest in 1KB
INT21_DPMI_GETMEM_SKIP:
	 shl	 edx,10-4	; Convert from 1KB to paras

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short INT21_DPMI_GETMEM16C ; Jump if so

	 cmp	 edx,-1 	; Izit special allocation value?
	 jne	 short @F	; Jump if not

	 dec	 edx		; Use maximum (in units of paras)
@@:
	 mov	 [ebp].INTXX_EBX,edx ; Return in caller's BX

	 jmp	 INT21_DPMI_ERRXMEM ; Join common error code

INT21_DPMI_GETMEM16C:
	 cmp	 dx,-1		; Izit special allocation value or above?
	 jb	 short @F	; Jump if not

	 dec	 dx		; Use maximum (in units of paras)
@@:
	 mov	 [ebp].INTXX_EBX.ELO,dx ; Return in caller's BX

	 jmp	 INT21_DPMI_ERRXMEM ; Join common error code


; We've successfully allocated EAX bytes at EBX
; Allocate a selector to map the memory,
; return that to the caller, allocate a DPMI handle
; and save that information in the DPMI handle space

INT21_DPMI_GETMEM_MEMOK:
	 mov	 edx,eax	; Copy length in bytes

	 push	 @BIT0		; Mark as segment-to-selector
	 push	 1		; # selectors to allocate
	 call	 GET_LDT	; Get next LDT selector in EAX ($TI and $PL set)
				; and LDTE marked as CPL3_DATA
	 xchg	 eax,ebx	; Swap to more convenient registers
	 jc	 near ptr INT21_DPMI_GETMEM_NOSEL ; Jump if not available

; EAX	 =	 base address
; EBX	 =	 selector
; EDX	 =	 length in bytes

; Mark selector BX as data at base EAX of length EDX

; Save base address

	 push	 bx		; Pass the selector
	 call	 SETLBASE	; Set selector base to EAX
;;;;;;;; jc	 short ???	; Ignore the error (error, what error?)

	 push	 bx		; Save selector

	 and	 bx,not ((mask $TI) or (mask $PL)) ; Clear TI and PL bits
	 mov	 ecx,PCURTSS	; Get offset in PGROUP of the current TSS
	 add	 ebx,PGROUP:[ecx].DPTSS_LaLDT ; Plus linear address of DPMI LDT

	 pushf			; Save flags
	 cli			; Disallow interrupts

; Save selector limit

	 push	 edx		; Save for a moment

	 dec	 edx		; Convert from length to limit

; See if we need to set the G-bit in the selector
; note that if we set the G-bit, we might provide a limit
; which is up to 4KB higher than the actual memory defines

	 cmp	 edx,CON1MB	; Izit bigger than a breadbox?
	 jb	 short @F	; Jump if not

	 shr	 edx,12-0	; Convert from bytes to 4KB
	 or	 edx,(mask $DTE_G) shl (8*(DESC_SEGLM1-DESC_BASE2)) ; Set G-bit
@@:
	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 AGROUP:[ebx].DESC_SEGLM0,dx ; Save limit bits 0-15
	 shr	 edx,16 	; Shift down high-order word
	 and	 AGROUP:[ebx].DESC_SEGLM1,not ((mask $DTE_G) or (mask $SEGLM1)) ; Clear incoming bits
	 or	 AGROUP:[ebx].DESC_SEGLM1,dl ; Save limit bits 16-19, G-bit

	 pop	 edx		; Restore selector length

	 popf			; Restore
				; (note interrupts might become enabled)
	 pop	 bx		; Restore selector

; Return selector BX to the caller's AX

	 mov	 [ebp].INTXX_EAX.ELO,bx ; Return it

; Find a free DPMI handle in which we can save
; selector BX at base EAX of length EDX

INT21_DPMI_GETMEM_GROWUP:
	 mov	 edi,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 ecx,PGROUP:[edi].DPTSS_DPMIHNDL_CNT ; Get total # handles
	 mov	 edi,PGROUP:[edi].DPTSS_LaDPMIHNDL ; Get linear address of DPMI
				; memory handle table
INT21_DPMI_GETMEM_NEXT:
	 cmp	 AGROUP:[edi].DPMIHNDL_LEN,0 ; Izit a valid entry?
	 jne	 short INT21_DPMI_GETMEM_LOOP ; Jump if so

	 mov	 AGROUP:[edi].DPMIHNDL_LA,eax ; Save base address
	 mov	 AGROUP:[edi].DPMIHNDL_LEN,edx ; Save length
	 mov	 AGROUP:[edi].DPMIHNDL_SEL,bx ; Save memory selector

	 mov	 ax,VM2PM_TSS	; Get current TSS selector
	 mov	 AGROUP:[edi].DPMIHNDL_TSS,ax ; Save for later use

	 jmp	 INT21_DPMI_CLC ; Join common OK code

INT21_DPMI_GETMEM_LOOP:
	 add	 edi,type DPMIHNDL_STR ; Skip to next entry

	 loopd	 INT21_DPMI_GETMEM_NEXT ; Jump if more handles to check

	 call	 DPMIFN_GROWMEMHNDL ; Attempt to grow DPMI memory handle struc
	 jnc	 short INT21_DPMI_GETMEM_GROWUP ; Jump if we succeeded

; We ran out of selectors or handles
; De-allocate the memory at base EAX of length EDX

INT21_DPMI_GETMEM_NOSEL:
	 push	 edx		; Pass byte length
	 push	 eax		; Pass starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
;;;;;;;; jc	 short ???	; Ignore error return

	 jmp	 INT21_DPMI_ERRXHNDL ; Join common error code

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 49:  Release memory (in ES)

; On entry (in PL3 stack):
; ES	 =	 selector to release

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_RELMEM:
	 mov	 ds,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 bx,[ebp-@I31BACK].I31_ES ; Get caller's ES

; Find caller's selector in the DPMI handle table

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 ecx,PGROUP:[edi].DPTSS_DPMIHNDL_CNT ; Get total # handles
	 mov	 edi,PGROUP:[edi].DPTSS_LaDPMIHNDL ; Get linear address of DPMI
				; memory handle table
INT21_DPMI_RELMEM_NEXT:
	 cmp	 AGROUP:[edi].DPMIHNDL_LEN,0 ; Izit a valid entry?
	 je	 short INT21_DPMI_RELMEM_LOOP ; Jump if not

	 cmp	 bx,AGROUP:[edi].DPMIHNDL_SEL ; Izit same memory selector?
	 jne	 short INT21_DPMI_RELMEM_LOOP ; Jump if not

; De-allocate the memory

	 push	 AGROUP:[edi].DPMIHNDL_LEN ; Pass byte length
	 push	 AGROUP:[edi].DPMIHNDL_LA ; Pass starting linear address
	 FIXICALL PGROUP:FDEALLOCMEM,DTE_CS2 ; Deallocate the memory
;;;;;;;; jc	 short ???	; Ignore error return

; Free the selector

	 push	 bx		; Pass the selector
	 call	 CLR_LDTZERO	; Free this LDT selector & zero selectors
;;;;;;;; jc	 short ???	; Ignore error return (error, what error?)

	 mov	 AGROUP:[edi].DPMIHNDL_LEN,0 ; Mark as free

	 jmp	 INT21_DPMI_CLC ; Join common OK code

INT21_DPMI_RELMEM_LOOP:
	 add	 edi,type DPMIHNDL_STR ; Skip to next entry

	 loopd	 INT21_DPMI_RELMEM_NEXT ; Jump if more handles to check

; We didn't find the selector, so we're assuming that it's invalid

	 jmp	 INT21_DPMI_ERRMNF ; Go around again

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 4A:  Modify memory block ES to eBX paras

; On entry (in PL3 stack):
; eBX	 =	 # paras of new size
; ES	 =	 selector to modify

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_MODMEM:
	 mov	 ds,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ax,[ebp-@I31BACK].I31_ES ; Get caller's ES

; Find caller's selector in the DPMI handle table

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 ecx,PGROUP:[edi].DPTSS_DPMIHNDL_CNT ; Get total # handles
	 mov	 edi,PGROUP:[edi].DPTSS_LaDPMIHNDL ; Get linear address of DPMI
				; memory handle table
INT21_DPMI_MODMEM_NEXT:
	 cmp	 AGROUP:[edi].DPMIHNDL_LEN,0 ; Izit a valid entry?
	 je	 short INT21_DPMI_MODMEM_LOOP ; Jump if not

	 cmp	 ax,AGROUP:[edi].DPMIHNDL_SEL ; Izit same memory selector?
	 je	 near ptr INT21_DPMI_MODMEM_MATCH ; Jump if so
INT21_DPMI_MODMEM_LOOP:
	 add	 edi,type DPMIHNDL_STR ; Skip to next entry

	 loopd	 INT21_DPMI_MODMEM_NEXT ; Jump if more handles to check

; We didn't find the selector; it might be a DOS memory selector

	 push	 ax		; Pass the selector
	 FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address of selector

	 cmp	 eax,CON1MB	; Izit in the first megabyte?
	 jae	 near ptr INT21_DPMI_ERRMNF ; Jump if not

	 test	 al,@NIB0	; Izit divisible by 16?
	 jnz	 near ptr INT21_DPMI_ERRMNF ; Jump if not

; Ensure # paras for resize is within range of a 16-bit register

	 mov	 ebx,[ebp].INTXX_EBX ; Get # paras for resize
	 IF16ZX  bx,IG		; Zero to use as dword if 16-bit client

	 cmp	 ebx,0000FFFFh	; Check against maximum for 16-bit register
	 ja	 near ptr INT21_DPMI_ERRMNF ; Jump if not

	 mov	 es,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  es:PGROUP	; Tell the assembler about it

; Give DOS a chance at it

	 call	 SAVE_VMCREGS	; Save current values of VMCREGS on stack
	 call	 EGP2VMCREGS	; Transfer caller's EGP registers to VMCREGS

;;;;;;;; mov	 VMCREGS.VMC_EAX.ELO.HI,@MODMEM ; Save DOS function
;;;;;;;; mov	 VMCREGS.VMC_EBX.ELO,bx ; Save # paras to allocate
	 mov	 VMCREGS.VMC_SP,0 ; Tell 'em to find their own stack
	 mov	 VMCREGS.VMC_SS,0 ; ...
	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 VMCREGS.VMC_ES,ax ; Save as segment to modify

	 push	 ebx		; Save # paras for a moment

	 mov	 bx,21h 	; BL = Interrupt #, BH = flags (none)
	 xor	 cx,cx		; # words to copy
	 lea	 edi,VMCREGS	; ES:EDI ==> VMC register structure
	 DPMICALL0 @DPMI_SIMVMI  ; Request DPMI service
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger
@@:
	 pop	 ebx		; Restore

	 test	 VMCREGS.VMC_FL,mask $CF ; Did DOS like that value?
	 jnz	 short INT21_DPMI_MODMEM_ERRDOS ; Jump if not

	 push	 es		; Save for a moment

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 movzx	 esi,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 and	 si,not ((mask $TI) or (mask $PL)) ; Isolate selector value
	 mov	 eax,PCURTSS	; Get offset in PGROUP of the current TSS
	 add	 esi,PGROUP:[eax].DPTSS_LaLDT ; Plus linear address of DPMI LDT
				; to get linear address of this LDT entry

	 shl	 ebx,4-0	; Convert from paras to bytes

; Set new limit in the LDT

	 dec	 ebx		; Convert from length to limit

; See if we need to set the G-bit in the selector
; note that if we set the G-bit, we might provide a limit
; which is up to 4KB higher than the actual memory defines

	 cmp	 ebx,CON1MB	; Izit bigger than a breadbox?
	 jb	 short @F	; Jump if not

	 shr	 ebx,12-0	; Convert from bytes to 4KB
	 or	 ebx,(mask $DTE_G) shl (8*(DESC_SEGLM1-DESC_BASE2)) ; Set G-bit
@@:
	 mov	 AGROUP:[esi].DESC_SEGLM0,bx ; Save limit bits 0-15
	 shr	 ebx,16 	; Shift down high-order word
	 and	 AGROUP:[esi].DESC_SEGLM1,not ((mask $DTE_G) or (mask $SEGLM1)) ; Clear incoming bits
	 or	 AGROUP:[esi].DESC_SEGLM1,bl ; Save limit bits 16-19, G-bit

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_MODMEM_ERRDOS:
	 call	 VMCREGS2EGP	; Transfer VMCREGS to caller's EGP registers
	 call	 REST_VMCREGS	; Restore old values of VMCREGS from stack

	 jmp	 INT21_DPMI_EXIT ; Join common exit code

	 assume  es:AGROUP	; Tell the assembler about it

INT21_DPMI_MODMEM_MATCH:

; See whether or not we're shrinking or growing

	 movzx	 ebx,ax 	; Get memory selector
	 and	 bx,not ((mask $TI) or (mask $PL)) ; Clear TI and PL bits

	 mov	 esi,PCURTSS	; Get offset in PGROUP of the current TSS
	 add	 ebx,PGROUP:[esi].DPTSS_LaLDT ; Plus linear address of DPMI LDT

	 mov	 esi,AGROUP:[edi].DPMIHNDL_LA ; Get linear address
	 mov	 eax,AGROUP:[edi].DPMIHNDL_LEN ; Get current length in bytes
	 mov	 edx,[ebp].INTXX_EBX ; Get new size in paras
	 IF16ZX  dx,IG		; Zero to use as dword if 16-bit client

	 test	 edx,@NIB7	; Is the number above 0FFFFFFFh?
	 jnz	 short INT21_DPMI_MODMEM_ERR ; Jump if truly ridiculous

	 shl	 edx,4-0	; Convert from paras to bytes

	 cmp	 edx,not (@DPMI_BOUND-1) ; Izit too large to round up?
	 ja	 short INT21_DPMI_MODMEM_ERR ; Jump if truly ridiculous

	 add	 edx,@DPMI_BOUND-1 ; Round up to @DPMI_BOUND
	 and	 edx,not (@DPMI_BOUND-1) ; ... boundary (which could become 1MB)

COMMENT|

Register usage:

EAX	 =	 current size of this block in bytes (/@DPMI_BOUND)
EDX	 =	 new size of this block in bytes (/@DPMI_BOUND)
ESI	 ==>	 starting linear address of block
EDI	 ==>	 DPMI handle entry

|

	 call	 DPMIFN_MODMEM	; Grow or srhink the memory
	 jc	 short INT21_DPMI_MODMEM_ERR ; Jump if something went wrong

; Set new limit in the LDT to EDX

	 dec	 edx		; Convert from length to limit

; See if we need to set the G-bit in the selector
; note that if we set the G-bit, we might provide a limit
; which is up to 4KB higher than the actual memory defines

	 cmp	 edx,CON1MB	; Izit bigger than a breadbox?
	 jb	 short @F	; Jump if not

	 shr	 edx,12-0	; Convert from bytes to 4KB
	 or	 edx,(mask $DTE_G) shl (8*(DESC_SEGLM1-DESC_BASE2)) ; Set G-bit
@@:
	 mov	 AGROUP:[ebx].DESC_SEGLM0,dx ; Save limit bits 0-15
	 shr	 edx,16 	; Shift down high-order word
	 and	 AGROUP:[ebx].DESC_SEGLM1,not ((mask $DTE_G) or (mask $SEGLM1)) ; Clear incoming bits
	 or	 AGROUP:[ebx].DESC_SEGLM1,dl ; Save limit bits 16-19, G-bit

; Set new base in the LDT

	 mov	 eax,AGROUP:[edi].DPMIHNDL_LA ; Get linear address

	 push	 [ebp-@I31BACK].I31_ES ; Get caller's selector
	 call	 SETLBASE	; Set selector base to EAX
;;;;;;;; jc	 short ???	; Ignore the error (error, what error?)

	 jmp	 INT21_DPMI_CLC ; Join common OK code


; No room anywhere

INT21_DPMI_MODMEM_ERR:

; There wasn't enough memory above this block
; Calculate how much memory there is above this block

	 add	 esi,eax	; Skip to the end of this block
	 mov	 ecx,edx	; Copy new size
	 sub	 ecx,eax	; Get increase in bytes

	 shr	 ecx,10-0	; Convert from bytes to 1KB
	 shr	 esi,10-0	; Convert from bytes to 1KB

; Check XMSBMAP for ECX adjacent free entries at ESI

	 lea	 eax,[ecx+esi]	; Skip to ending entry

	 cmp	 eax,XMSBMAP_LEN ; Ensure it's within bounds
	 ja	 short INT21_DPMI_MODMEM_ERR1 ; Jump if too high

; Determine the span of available entries starting
; at EDI for no more than ECX entries

; Note that we use XMS2 as the allocation type to get 1KB granularity
; without physical boundary concerns.

	 push	 @ALLOC_XMS2	; Pass the allocation type
	 push	 ecx		; Pass # entries we need
	 push	 edi		; Pass starting offset into XMSBMAP
	 FIXICALL PGROUP:FXMS_MEMSPAN,DTE_CS2 ; Determine the span of available entries
				; returning EDI = # consecutive available entries
	 add	 esi,edi	; Add to get first unavailable entry
INT21_DPMI_MODMEM_ERR1:

; ESI	 =	 first address (in 1KB) not available
; EDI	 ==>	 DPMI handle entry

	 shl	 esi,10-0	; Convert from 1KB to bytes
	 sub	 esi,AGROUP:[edi].DPMIHNDL_LA ; Less starting linear address
	 sub	 esi,AGROUP:[edi].DPMIHNDL_LEN ; Less current length
	 shr	 esi,4-0	; Convert from bytes to paras

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short INT21_DPMI_MODMEM16A ; Jump if so

	 cmp	 esi,0000FFFFh	; Izit special allocation value?
	 jne	 short @F	; Jump if not

	 mov	 esi,0000FFFEh	; Use maximum (in units of paras)
@@:
	 mov	 [ebp].INTXX_EBX,esi ; Return in caller's EBX

	 jmp	 INT21_DPMI_ERRXMEM ; Join common error code

INT21_DPMI_MODMEM16A:
	 cmp	 esi,0000FFFFh	; Izit special allocation value or above?
	 jb	 short @F	; Jump if not

	 mov	 esi,0000FFFEh	; Use maximum (in units of paras)
@@:
	 mov	 [ebp].INTXX_EBX.ELO,si ; Return in caller's BX

	 jmp	 INT21_DPMI_ERRXMEM ; Join common error code

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 4B:  Execute a program

; On entry (in PL3 stack):
; AL	 =	 function code
; DS:eDX ==>	 ASCIIZ filename
; ES:eBX ==>	 parameter block

; On entry (in registers):
; SS:ESP =	 ASCIIZ length in bytes
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_EXEC:
	 pop	 bx		; Restore ASCIIZ length of filename

; Split cases depending upon the function code in AL

	 mov	 al,[ebp].INTXX_EAX.ELO.LO ; Get function code from AL

	 cmp	 al,00h 	; Izit load and execute?
	 je	 short INT21_DPMI_EXEC_LE ; Jump if so

; The function code is not supported

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action


; 4B00:  Load and execute

INT21_DPMI_EXEC_LE:
	 mov	 ax,size EXEC_STR ; Get size of 16-bit Load and Execute struc

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short @F	; Jump if so

	 mov	 ax,size EXECD_STR ; Get size of 32-bit Load and Execute struc
@@:
	 lea	 si,INT21_DPMIJMP_EXEC_LE ; CS:SI ==> action stream

	 push	 bx		; RELBUF:   # bytes to release for filename
	 push	 ax		; RELBUF:   # bytes to release for parm block
	 push	 ax		; GETBUF:   # leading bytes to copy
	 push	 ax		; GETBUF:   # bytes to allocate for parm block
	 push	 bx		; GETBUF:   # leading bytes to copy
	 push	 bx		; GETBUF:   # bytes to allocate for filename

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 4C:  Exit with return code

; On entry (in PL3 stack):
; AL	 =	 return code

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_EXITRC:

; If there are any activities which need to be done at
; termination time when PCURTSS and TR match, now's the time

	 call	 DPMIFN_TERMINATE ; Handle termination (note IF=0 upon return)
	 assume  ds:nothing,es:PGROUP  ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; ...

; Note that because we're about to cause our caller to perform an IRETD,
; which will cause a task switch, we don't have to save or restore
; any registers

	 mov	 al,[ebp].INTXX_EAX.ELO.LO ; Get return code from AL
	 mov	 EXITRC.LO,al	; Save return code

	 or	 I31_FLAG,mask $I31_EXIT ; Mark as normal termination

;;;;;;;; cli			; Disable interrupts to avoid HW interrupt
;;;;;;;;			; after POPAD looking like a VM interrupt
;;;;;;;;			; (already disabled)
	 pop	 LPMSTK_FVEC.FOFF ; Restore
	 pop	 LPMSTK_FVEC.FSEL ; ...

;;;;;;;; REGREST <es,ds>	; Restore caller's selectors
;;;;;;;; assume  ds:nothing,es:nothing ; Tell the assembler about it
	 add	 esp,2+2	; Strip old LDT selectors (might be invalid)

	 popad			; Restore caller's EGP registers

	 add	 esp,size INTXX_ERR ; Strip off pseudo-error code

; Set NT bit and IRET to it to affect task switch

	 pushf			; Save flags
	 or	 [esp].ELO,mask $NT ; Set the NT bit
	 popf			; Put it into effect

; The following IRET causes a task switch to the back link TSS
; which is (presumably) PVMTSS.  As the task switch from PVMTSS
; was initiated by the hand-constructed CALLF VM2PM_TSS, execution
; continues at that point.

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 53:  Translate BPB at DS:eSI to DPB at ES:eBP

; On entry (in PL3 stack):
; DS:eSI ==>	 BIOS parameter block
; ES:eBP ==>	 Drive parameter block

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_BP2DPB:

; The size of the Drive Parameter Block is 31 bytes for DOS 3.x,
; 32 bytes for DOS 4.x; I'm not sure about DOS 5.x

; The size of the BIOS Parameter Block is 32 bytes for DOS 3.x,
; 36 bytes for DOS 4.x; I'm not sure about DOS 5.x

	 mov	 bx,32		; Assume it's DOS 4.x
	 mov	 ax,36		; Assume it's DOS 4.x

	 cmp	 DOSVER,0400h	; Izit DOS 4.x or later?
	 jae	 short @F	; Jump if so

	 mov	 bx,31		; It's DOS 3.x
	 mov	 ax,32		; It's DOS 3.x
@@:
	 push	 ax		; RELBUF:   # bytes to release for BPB
	 push	 bx		; LOW2EXT:  # bytes to release for DPB
	 push	 bx		; LOW2EXT:  # trailing bytes to copy
	 push	 0		; GETBUF:   # leading bytes to copy
	 push	 bx		; GETBUF:   # bytes to allocate for DPB
	 push	 ax		; GETBUF:   # leading bytes to copy
	 push	 ax		; GETBUF:   # bytes to allocate for BPB

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 56:  Rename file, from ASCIIZ at DS:eDX to ASCIIZ at ES:eDI

; On entry (in PL3 stack):
; DS:eDX ==>	 Old ASCIIZ filename
; ES:eDI ==>	 New ASCIIZ filename

; On entry (in registers):
; SS:ESP+0 =	 ASCIIZ length of ES:eDI in bytes
; SS:ESP+2 =	 ASCIIZ length in DS:eDX in bytes
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_RENMF2:
	 pop	 bx		; Save size of new filename
	 pop	 ax		; ...	       old ...

	 push	 ax		; RELBUF:  # bytes to release for old filename
	 push	 bx		; RELBUF:  # bytes to release for new filename
	 push	 bx		; GETBUF:  # leading bytes to copy
	 push	 bx		; GETBUF:  # bytes to allocate for new filename
	 push	 ax		; GETBUF:  # leading bytes to copy
	 push	 ax		; GETBUF:  # bytes to allocate for old filename

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 60:  Resolve path in DS:eSI to canonical form in ES:eDI

; On entry (in PL3 stack):
; DS:eSI ==>	 ASCIIZ filename to resolve
; ES:eDI ==>	 128-byte output buffer

; On entry (in registers):
; SS:ESP =	 ASCIIZ length in bytes
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_FIXPTH:
	 pop	 bx		; Restore ASCIIZ length of filename

@FIXPTH_SIZE equ 128		; Output buffer size

	 push	 bx		; RELBUF:   # bytes to release for filename
	 push	 @FIXPTH_SIZE	; LOW2EXT:  # bytes to release for buffer
	 push	 @FIXPTH_SIZE	; LOW2EXT:  # trailing bytes to copy
	 push	 0		; GETBUF:   # leading bytes to copy
	 push	 @FIXPTH_SIZE	; GETBUF:   # bytes to allocate for buffer
	 push	 bx		; GETBUF:   # leading bytes to copy
	 push	 bx		; GETBUF:   # bytes to allocate for filename

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 65:  Get extended country-dependent information

; On entry (in PL3 stack):
; CX	 =	 # bytes to return
; DS:eDI ==>	 return buffer

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_GETXCD:
	 mov	 eax,[ebp].INTXX_ECX ; Get # bytes to copy
;;;;;;;; IF16ZX  ax,IG		; Zero to use as dword if 16-bit client

	 push	 ax		; LOW2EXT   # bytes to release
	 push	 ax		; LOW2EXT:  # trailing bytes to copy
	 push	 0		; GETBUF:   # leading bytes to copy
	 push	 ax		; GETBUF:   # bytes to allocate

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

; 69:  Get/set disk serial # for drive BL (origin-1) to DS:eDX

; On entry (in PL3 stack):
; AL	 =	 0 to get serial #
;	 =	 1 to set serial #
; DS:eDX ==>	 input (AL=0)/output (AL=1) buffer

; On entry (in registers):
; CS:SI  ==>	 action stream
; ES	 =	 PGROUP
; SS:EBP ==>	 INTXX_STR (nothing above INTXX_SS is valid)

	 assume  es:PGROUP	; Tell the assembler about it
INT21_DPMI_GSTSER:
	 mov	 bx,type DSKSER_STR ; # bytes in disk serial # structure

	 push	 bx		; LOW2EXT:  # bytes to release

	 cmp	 [ebp].INTXX_EAX.ELO.LO,0 ; Izit get serial #?
	 je	 short INT21_DPMI_GETSER ; Jump if so
				; Fall through if set serial #
	 push	 0		; LOW2EXT:  # trailing bytes to copy
	 push	 bx		; GETBUF:   # leading bytes to copy

	 jmp	 short INT21_DPMI_GSTSER_COM ; Join common code

INT21_DPMI_GETSER:
	 push	 bx		; LOW2EXT:  # trailing bytes to copy
	 push	 0		; GETBUF:   # leading bytes to copy
INT21_DPMI_GSTSER_COM:
	 push	 bx		; GETBUF:   # bytes to allocate

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing ; Tell the assembler about it


; ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ

INT21_DPMI_ERRXMEM:
	 mov	 [ebp].INTXX_EAX.ELO,@DOSERR_XMEM ; Mark as insufficient memory

	 jmp	 short INT21_DPMI_ERR ; Join common error code

INT21_DPMI_ERRXHNDL:
	 mov	 [ebp].INTXX_EAX.ELO,@DOSERR_XHNDL ; Mark as no handles left

	 jmp	 short INT21_DPMI_ERR ; Join common error code

INT21_DPMI_ERRMNF:
	 mov	 [ebp].INTXX_EAX.ELO,@DOSERR_MNF ; Mark as invalid memory block address
INT21_DPMI_ERR:
	 or	 [ebp].INTXX_EFL.ELO,mask $CF ; Mark as in error

	 jmp	 short INT21_DPMI_EXIT ; Join common exit code

INT21_DPMI_CLC:
	 and	 [ebp].INTXX_EFL.ELO,not (mask $CF) ; Mark as not in error

	 assume  ss:PGROUP	; Tell the assembler about it
INT21_DPMI_EXIT:
	 cli			; Disable interrupts to avoid HW interrupt
				; after POPAD looking like a VM interrupt
	 pop	 LPMSTK_FVEC.FOFF ; Restore
	 pop	 LPMSTK_FVEC.FSEL ; ...

	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 popad			; Restore all EGP registers

	 add	 esp,size INTXX_ERR ; Strip off pseudo-error code

	 iretd			; Return to caller


INT21_DPMI_UNSUP:
	 mov	 [ebp].INTXX_EAX.ELO.LO,-1 ; Return universal error code

	 jmp	 INT21_DPMI_ERR ; Call it an error

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT21_DPMI endp 		; End INT21_DPMI procedure
	 NPPROC  DPMIFN_GETDTA -- Get Address Of DTA From Low DOS
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get address of the DTA from low DOS

On exit:

EDI	 =	 Seg:Off of DTA in low DOS

|

	 REGSAVE <ax,bx,cx>	; Save registers

	 call	 SAVE_VMCREGS	; Save current values of VMCREGS on stack

	 mov	 VMCREGS.VMC_EAX.ELO.HI,@GETDTA ; Save DOS function
	 mov	 VMCREGS.VMC_SP,0 ; Tell 'em to find their own stack
	 mov	 VMCREGS.VMC_SS,0 ; ...
	 mov	 VMCREGS.VMC_FL,0 ; Set to known value

; Note that the following code doesn't care whether or not the
; current DPMI client is 16- or 32-bit as VMCREGS is within 64KB

	 mov	 bx,21h 	; BL = Interrupt #, BH = flags (none)
	 xor	 cx,cx		; # words to copy
	 lea	 edi,VMCREGS	; ES:EDI ==> VMC register structure
	 DPMICALL0 @DPMI_SIMVMI  ; Request DPMI service
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger
@@:
	 mov	 di,VMCREGS.VMC_ES ; Get segment of DTA
	 shl	 edi,16 	; Shift to high-order word
	 mov	 di,VMCREGS.VMC_EBX.ELO ; Get offset of DTA
DPMIFN_GETDTA_EXIT:
	 call	 REST_VMCREGS	; Restore old values of VMCREGS from stack

	 REGREST <cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_GETDTA endp		; End DPMIFN_GETDTA procedure
	 NPPROC  DPMIFN_SETDTA -- Set Address Of DTA In Low DOS
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set address of the DTA in low DOS

|

DPMIFN_SETDTA_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
DPMIFN_SETDTA_VEC dd ?		; New Seg:Off for DTA in low DOS

DPMIFN_SETDTA_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,edi> ; Save registers

	 call	 SAVE_VMCREGS	; Save current values of VMCREGS on stack

	 mov	 VMCREGS.VMC_EAX.ELO.HI,@SETDTA ; Save DOS function
	 mov	 edi,[ebp].DPMIFN_SETDTA_VEC ; Get new Seg:Off
	 mov	 VMCREGS.VMC_EDX.ELO,di ; Set offset of DTA
	 shr	 edi,16 	; Shift down high-order word
	 mov	 VMCREGS.VMC_DS,di ; Set segment of DTA
	 mov	 VMCREGS.VMC_SP,0 ; Tell 'em to find their own stack
	 mov	 VMCREGS.VMC_SS,0 ; ...
	 mov	 VMCREGS.VMC_FL,0 ; Set to known value

; Note that the following code doesn't care whether or not the
; current DPMI client is 16- or 32-bit as VMCREGS is within 64KB

	 mov	 bx,21h 	; BL = Interrupt #, BH = flags (none)
	 xor	 cx,cx		; # words to copy
	 lea	 edi,VMCREGS	; ES:EDI ==> VMC register structure
	 DPMICALL0 @DPMI_SIMVMI  ; Request DPMI service
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger
@@:
	 call	 REST_VMCREGS	; Restore old values of VMCREGS from stack

	 REGREST <edi,cx,bx,ax> ; Restore

	 pop	 ebp		; Restore

	 ret	 4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_SETDTA endp		; End DPMIFN_SETDTA procedure
	 NPPROC  DPMIFN_DTA2EXT -- Copy Contents of DTA in Low DOS To Extended Memory
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy contents of DTA in low DOS to extended memory

|

DPMIFN_DTA2EXT_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
DPMIFN_DTA2EXT_VEC dd ? 	; Seg:Off of DTA in low DOS
DPMIFN_DTA2EXT_LEN dw ? 	; Length of ...

DPMIFN_DTA2EXT_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,esi,edi,ds,es> ; Save registers

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

	 movzx	 esi,[ebp].DPMIFN_DTA2EXT_VEC.VSEG ; Copy segment of DTA
	 shl	 esi,4-0	; Convert from paras to bytes
	 movzx	 ecx,[ebp].DPMIFN_DTA2EXT_VEC.VOFF ; Copy offset of DTA
	 add	 esi,ecx	; DS:ESI ==> source DTA

	 mov	 edi,PCURTSS	; Get offset in PGROUP of current TSS

	 les	 edi,PGROUP:[edi].DPTSS_DTA_FVEC ; ES:EDI ==> destin DTA
	 assume  es:nothing	; Tell the assembler about it

	 movzx	 ecx,[ebp].DPMIFN_DTA2EXT_LEN ; Get DTA length in bytes

S32  rep movs	 <es:[edi].LO,AGROUP:[esi].LO> ; Copy from low to extended

	 REGREST <es,ds,edi,esi,ecx> ; Restore
	 assume  ds:nothing,es:PGROUP ; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_DTA2EXT endp		; End DPMIFN_DTA2EXT procedure
	 NPPROC  DPMIFN_EXT2DTA -- Copy Contents of DTA in Extended Memory To Low DOS
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy contents of DTA in extended memory to low DOS

|

DPMIFN_EXT2DTA_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
DPMIFN_EXT2DTA_VEC dd ? 	; Seg:Off of DTA in low DOS
DPMIFN_EXT2DTA_LEN dw ? 	; Length of ...

DPMIFN_EXT2DTA_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,esi,edi,ds,es> ; Save registers

	 mov	 esi,PCURTSS	; Get offset in PGROUP of current TSS

	 lds	 esi,PGROUP:[esi].DPTSS_DTA_FVEC ; DS:ESI ==> source DTA
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 movzx	 edi,[ebp].DPMIFN_EXT2DTA_VEC.VSEG ; Copy segment of DTA
	 shl	 edi,4-0	; Convert from paras to bytes
	 movzx	 ecx,[ebp].DPMIFN_EXT2DTA_VEC.VOFF ; Copy offset of DTA
	 add	 edi,ecx	; ES:EDI ==> destin DTA

	 movzx	 ecx,[ebp].DPMIFN_EXT2DTA_LEN ; Get DTA length in bytes

S32  rep movs	 <AGROUP:[edi].LO,ds:[esi].LO> ; Copy from extended to low

	 REGREST <es,ds,edi,esi,ecx> ; Restore
	 assume  ds:nothing,es:PGROUP ; Tell the assembler about it

	 pop	 ebp		; Restore

	 ret	 4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_EXT2DTA endp		; End DPMIFN_EXT2DTA procedure
	 NPPROC  EGP2VMCREGS -- Set VMCREGS To Caller Values
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set VMCREGS EGP values to caller's registers
and zero the stack pointer and segment registers

On entry:

SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

|

	 REGSAVE <eax>		; Save register

	 mov	 eax,[ebp].INTXX_EAX ; Get EAX
	 mov	 VMCREGS.VMC_EAX,eax ; Save in structure

	 mov	 eax,[ebp].INTXX_EBX ; Get EBX
	 mov	 VMCREGS.VMC_EBX,eax ; Save in structure

	 mov	 eax,[ebp].INTXX_ECX ; Get ECX
	 mov	 VMCREGS.VMC_ECX,eax ; Save in structure

	 mov	 eax,[ebp].INTXX_EDX ; Get EDX
	 mov	 VMCREGS.VMC_EDX,eax ; Save in structure

	 mov	 eax,[ebp].INTXX_ESI ; Get ESI
	 mov	 VMCREGS.VMC_ESI,eax ; Save in structure

	 mov	 eax,[ebp].INTXX_EDI ; Get EDI
	 mov	 VMCREGS.VMC_EDI,eax ; Save in structure

	 mov	 eax,[ebp].INTXX_EBP ; Get EBP
	 mov	 VMCREGS.VMC_EBP,eax ; Save in structure

	 mov	 ax,[ebp].INTXX_EFL.ELO ; Get FL
	 and	 ax,not (mask $IOPL) ; Clear the IOPL bits
	 or	 ax,@VMIOPL shl $IOPL ; IOPL=@VMIOPL
	 mov	 VMCREGS.VMC_FL,ax ; Save in structure

	 mov	 VMCREGS.VMC_SP,0 ; Save in structure
	 mov	 VMCREGS.VMC_DS,0 ; ...
	 mov	 VMCREGS.VMC_ES,0 ; ...
	 mov	 VMCREGS.VMC_FS,0 ; ...
	 mov	 VMCREGS.VMC_GS,0 ; ...
	 mov	 VMCREGS.VMC_SS,0 ; ...

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EGP2VMCREGS endp		; End EGP2VMCREGS procedure
	 NPPROC  VMCREGS2EGP -- Set Caller Values To VMCREGS
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set caller's registers to VMCREGS EGP values
except for the stack pointer and segment registers

On entry:

SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

|

	 REGSAVE <eax>		; Save register

	 mov	 eax,VMCREGS.VMC_EAX ; Get EAX from structure
	 mov	 [ebp].INTXX_EAX,eax ; Return to caller

	 mov	 eax,VMCREGS.VMC_EBX ; Get EBX from structure
	 mov	 [ebp].INTXX_EBX,eax ; Return to caller

	 mov	 eax,VMCREGS.VMC_ECX ; Get ECX from structure
	 mov	 [ebp].INTXX_ECX,eax ; Return to caller

	 mov	 eax,VMCREGS.VMC_EDX ; Get EDX from structure
	 mov	 [ebp].INTXX_EDX,eax ; Return to caller

	 mov	 eax,VMCREGS.VMC_ESI ; Get ESI from structure
	 mov	 [ebp].INTXX_ESI,eax ; Return to caller

	 mov	 eax,VMCREGS.VMC_EDI ; Get EDI from structure
	 mov	 [ebp].INTXX_EDI,eax ; Return to caller

	 mov	 eax,VMCREGS.VMC_EBP ; Get EBP from structure
	 mov	 [ebp].INTXX_EBP,eax ; Return to caller

	 mov	 ax,VMCREGS.VMC_FL ; Get FL from structure
	 and	 ax,not ((mask $NT) or (mask $IOPL)); NT=IOPL=0
	 or	 ax,@DPMIOPL shl $IOPL ; IOPL=@DPMIOPL
	 mov	 [ebp].INTXX_EFL.ELO,ax ; Return to caller

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMCREGS2EGP endp		; End VMCREGS2EGP procedure
	 NPPROC  SAVE_VMCREGS -- Save Current Values Of VMCREGS On Stack
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

So we'll be re-entrant, save the current values in
VMCREGS on the stack so we can restore them later.

|

SAVEVMC_STR struc

	 dd	 ?		; Caller's EBP
SAVEVMC_RET dw	 ?		; ...	   IP
SAVEVMC_VMC db	 (size VMCREGS) dup (?) ; Save area for VMCREGS

SAVEVMC_STR ends

	 sub	 esp,(size VMCREGS)-(size SAVEVMC_RET) ; Make room for it less return address

; Copy return address to bottom of stack

	 push	 (type SAVEVMC_RET) ptr [esp+(size VMCREGS)-(size SAVEVMC_RET)]

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,esi,edi>	; Save registers

	 lea	 edi,[ebp].SAVEVMC_VMC ; SS:EDI ==> destin values
	 mov	 ecx,size VMCREGS ; ECX = # bytes to move
	 lea	 esi,VMCREGS	; PRGOUP:ESI ==> source values
S32  rep movs	 <PGROUP:[edi].LO,VMCREGS.LO[esi]> ; Copy current values to stack

	 REGREST <edi,esi,ecx>	; Restore

	 pop	 ebp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_VMCREGS endp		; End SAVE_VMCREGS procedure
	 NPPROC  REST_VMCREGS -- Restore Old Values Of VMCREGS From Stack
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore the old values of VMCREGS from the stack.

Note that the CPU flags are not changed by this function.

|

RESTVMC_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
RESTVMC_VMC db	 (size VMCREGS) dup (?) ; Save area for VMCREGS

RESTVMC_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,esi,edi>	; Save registers

;;;;;;;; pushf			; Save flags

	 lea	 esi,[ebp].SAVEVMC_VMC ; SS:ESI ==> source values
	 mov	 ecx,size VMCREGS ; ECX = # bytes to move
	 lea	 edi,VMCREGS	; PRGOUP:EDI ==> destin values
S32  rep movs	 <VMCREGS.LO[edi],ss:[esi].LO> ; Copy current values to stack

;;;;;;;; popf			; Restore flags

	 REGREST <edi,esi,ecx>	; Restore

	 pop	 ebp		; Restore

	 ret	 (size VMCREGS) ; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_VMCREGS endp		; End REST_VMCREGS procedure
	 NPPROC  DOSFN_SAVE_INTXXREG -- Save An INTXX_STR Register
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save an INTXX_STR register onto the stack

On entry:

CS:SI	 ==>	 action stream with
		 offset in [ebp].INTXX_STR of register
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered

|

	 lods	 JMPTAB21[si]	; Get offset in [ebp].INTXX_STR of register
	 movsx	 eax,ax 	; Sign extend to use with EBP
	 push	 [ebp+eax].EDD	; Save onto the stack

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 jne	 short @F	; Jump if not

	 mov	 [ebp+eax].EDD.EHI,0 ; Zero to use as dword
@@:
	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_SAVE_INTXXREG endp	; End DOSFN_SAVE_INTXXREG procedure
	 NPPROC  DOSFN_COPY_INTXXREG -- Copy An INTXX_STR Register to VMCREGS
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy an INTXX_STR register to VMCREGS

On entry:

CS:SI	 ==>	 action stream with
		 offset in [ebp].INTXX_STR of source register
		 VMC_xxx offset for target register
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered

|

	 push	 bx		; Save for a moment

	 lods	 JMPTAB21[si]	; Get offset in [ebp].INTXX_STR of register
	 movsx	 eax,ax 	; Sign extend to use with EBP
	 push	 [ebp+eax].ELO	; Save onto the stack

	 lods	 JMPTAB21[si]	; Get offset of target register
	 mov	 bx,ax		; Copy to index register

	 pop	 VMCREGS.ELO[bx] ; Save as corresponding VMC_xxx register

	 pop	 bx		; Restore

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_COPY_INTXXREG endp	; End DOSFN_COPY_INTXXREG procedure
	 NPPROC  DOSFN_REST_INTXXREG -- Restore An INTXX_STR Register
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore an INTXX_STR register from the stack

On entry:

CS:SI	 ==>	 action stream with
		 offset in [ebp].INTXX_STR of register
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered

|

	 lods	 JMPTAB21[si]	; Get offset in [ebp].INTXX_STR of register
	 movsx	 eax,ax 	; Sign extend to use with EBP
	 pop	 [ebp+eax].EDD	; Restore from the stack

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_REST_INTXXREG endp	; End DOSFN_REST_INTXXREG procedure
	 NPPROC  DOSFN_SAVE_INTXXREGWORD -- Save Word In An INTXX_STR Register
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save a word in an INTXX_STR register onto the stack

On entry:

CS:SI	 ==>	 action stream with
		 offset in [ebp].INTXX_STR of register
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered

|

	 lods	 JMPTAB21[si]	; Get offset in [ebp].INTXX_STR of register
	 movsx	 eax,ax 	; Sign extend to use with EBP
	 push	 [ebp+eax].ELO	; Save onto the stack

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_SAVE_INTXXREGWORD endp	; End DOSFN_SAVE_INTXXREGWORD procedure
	 NPPROC  DOSFN_REST_INTXXREGWORD -- Restore Word In An INTXX_STR Register
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore a word in an INTXX_STR register from the stack

On entry:

CS:SI	 ==>	 action stream with
		 offset in [ebp].INTXX_STR of register
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered

|

	 lods	 JMPTAB21[si]	; Get offset in [ebp].INTXX_STR of register
	 movsx	 eax,ax 	; Sign extend to use with EBP
	 pop	 [ebp+eax].ELO	; Restore from the stack

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_REST_INTXXREGWORD endp	; End DOSFN_REST_INTXXREGWORD procedure
	 NPPROC  DOSFN_RELREG -- Relativize a VMC_STR Register
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Relativize a VMC_STR register by subtracting from it the start of the
HPDA buffer and adding to it the corresponding INTXX_STR register.

On entry:

CS:SI	 ==>	 action stream with
		 VMC_xxx offset for offset-register
		 offset in [ebp].INTXX_STR of register
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered

|

	 REGSAVE <bx,ecx,edx>	; Save registers

	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS

	 lods	 JMPTAB21[si]	; Get offset of offset-register
	 mov	 bx,ax		; Copy to index register

	 movzx	 ecx,VMCREGS.ELO[bx] ; Get corresponding VMC_xxx register
	 sub	 cx,PGROUP:[edx].DPTSS_VMBUFOFF ; Less offset of HPDA buffer

	 lods	 JMPTAB21[si]	; Get offset in [ebp].INTXX_STR of register
	 movsx	 eax,ax 	; Sign extend to use with EBP

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short DOSFN_RELREG16 ; Jump if so

	 add	 ecx,[ebp+eax]	; Add in INTXX_STR register
	 mov	 VMCREGS.EDD[bx],ecx ; Save back

	 jmp	 short DOSFN_RELREG_EXIT ; Join common exit code

DOSFN_RELREG16:
	 add	 cx,[ebp+eax]	; Add in INTXX_STR register
	 mov	 VMCREGS.ELO[bx],cx ; Save back
DOSFN_RELREG_EXIT:
	 REGREST <edx,ecx,bx>	; Restore

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_RELREG endp		; End DOSFN_RELREG procedure
	 NPPROC  DOSFN_SAVE_VMCREGS -- Invoke SAVE_VMCREGS And Continue
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Invoke SAVE_VMCREGS and EGP2VMCREGS and continue on

On entry:

CS:SI	 ==>	 action stream with
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
AX	 =	 clobbered

|

	 call	 SAVE_VMCREGS	; Save current values of VMCREGS on stack
	 call	 EGP2VMCREGS	; Transfer caller's EGP registers to VMCREGS

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_SAVE_VMCREGS endp 	; End DOSFN_SAVE_VMCREGS procedure
	 NPPROC  DOSFN_REST_VMCREGS -- Invoke REST_VMCREGS And Continue
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Invoke VMCREGS2EGP and REST_VMCREGS and continue on

On entry:

CS:SI	 ==>	 action stream with
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
AX	 =	 clobbered

|

	 call	 VMCREGS2EGP	; Transfer VMCREGS to caller's EGP registers
	 call	 REST_VMCREGS	; Restore old values of VMCREGS from stack

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_REST_VMCREGS endp 	; End DOSFN_REST_VMCREGS procedure
	 NPPROC  DOSFN_GETBUF -- Allocate Temporary Buffer
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate temporary buffer from the HPDA
and copy from extended memory to the HPDA buffer

On entry:

CS:SI	 ==>	 action stream with
		 VMC_xxx offset for offset-register
		 VMC_xxx ...	    segment-...
		 xxx to be used in EBP+xxx as offset
		 xxx ...		      selector
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)
SS:ESP+0 =	 # bytes to allocate
SS:ESP+2 =	 # bytes to copy

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered
ESP	 =	 (updated)

|

GETBUF_STR struc

GETBUF_EBP dd	 ?		; Caller's EBP
GETBUF_LEN dw	 ?		; # bytes to allocate
GETBUF_CPY dw	 ?		; # bytes to copy

GETBUF_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,ecx,edx,edi,ds,es> ; Save registers

; Use HPDA_BUF as temporary buffer

	 mov	 cx,[ebp].GETBUF_LEN ; Get size of buffer

	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS

	 lods	 JMPTAB21[si]	; Get offset of offset-register
	 mov	 bx,ax		; Copy to index register
	 mov	 ax,PGROUP:[edx].DPTSS_VMBUFOFF ; Get offset of HPDA buffer
	 mov	 VMCREGS.ELO[bx],ax ; DOS memory offset

	 add	 PGROUP:[edx].DPTSS_VMBUFOFF,cx ; Add into next offset
	 sub	 PGROUP:[edx].DPTSS_VMBUFSIZ,cx ; Subtract from size
	 jnc	 short @F	; Jump if there's room

	 int	 03h		; Call our debugger
@@:
	 movzx	 edi,VMCREGS.ELO[bx] ; Save the destin offset

	 lods	 JMPTAB21[si]	; Get offset of segment-register
	 mov	 bx,ax		; Copy to index register
	 mov	 ax,PGROUP:[edx].DPTSS_HPDASEG ; Get segment of HPDA
	 mov	 VMCREGS.ELO[bx],ax ; DOS memory segment

; Copy from extended memory to HPDA buffer

	 movzx	 ecx,[ebp].GETBUF_CPY ; Get # bytes to copy
	 mov	 ebp,[ebp].GETBUF_EBP ; Get caller's EBP to address INTXX_STR

	 lods	 JMPTAB21[si]	; Get xxx to be used in EBP+xxx for offset
	 movsx	 eax,ax 	; Sign extend to use with EBP

	 mov	 ebx,[ebp+eax]	; Get value of source offset
				; Already zeroed to use as dword if 16-bit client

	 lods	 JMPTAB21[si]	; Get xxx to be used in EBP+xxx for segment
	 movsx	 eax,ax 	; Sign extend to use with EBP

	 push	 esi		; Save for a moment

	 mov	 esi,ebx	; Copy source offset

	 mov	 ds,[ebp+eax]	; DS:ESI ==> caller's buffer
	 assume  ds:nothing	; Tell the assembler about it

	 add	 edi,PGROUP:[edx].DPTSS_LaHPDA ; Plus linear address of HPDA
				 ; AGROUP:EDI ==> HPDA buffer

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

S32  rep movs	 <AGROUP:[edi].LO,ds:[esi].LO> ; Copy the leading bytes
				; from caller's buffer to DOS memory buffer
	 pop	 esi		; Restore

	 REGREST <es,ds,edi,edx,ecx,ebx> ; Restore
	 assume  ds:nothing,es:PGROUP ; Tell the assembler about it

	 pop	 ebp		; Restore

	 lods	 JMPTAB21[si]	; Get next action

	 push	 ax		; Push as "return" address

	 ret	 2+2		; Take appropriate action, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_GETBUF endp		; End DPMIFN_GETBUF procedure
	 NPPROC  DOSFN_RELBUF -- Release Temporary Buffer
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Release temporary buffer from the HPDA

On entry:

CS:SI	 ==>	 action stream with
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)
SS:ESP	 =	 # bytes to release

On exit:

CS:SI	 ==>	 (updated)
AX	 =	 clobbered
ESP	 =	 (updated)

|

RELBUF_STR struc

RELBUF_EBP dd	 ?		; Caller's EBP
RELBUF_LEN dw	 ?		; # bytes to release

RELBUF_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <edx>		; Save registers

	 mov	 ax,[ebp].RELBUF_LEN ; Get size of buffer
	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS

	 sub	 PGROUP:[edx].DPTSS_VMBUFOFF,ax ; Subtract from offset
	 add	 PGROUP:[edx].DPTSS_VMBUFSIZ,ax ; Add into size

	 REGREST <edx>		; Restore

	 pop	 ebp		; Restore

	 lods	 JMPTAB21[si]	; Get next action

	 push	 ax		; Push as "return" address

	 ret	 2		; Take appropriate action, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_RELBUF endp		; End DPMIFN_RELBUF procedure
	 NPPROC  DOSFN_EXT2LOW -- Copy From Extended Memory to Low DOS
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy from extended memory to HPDA buffer in low DOS

On entry:

CS:SI	 ==>	 action stream with
		 xxx to be used in EBP+xxx as offset
		 xxx ...		      selector
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)
SS:ESP	 =	 # bytes to copy

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered
ESP	 =	 (updated)

|

EXT2LOW_STR struc

EXT2LOW_EBP dd	 ?		; Caller's EBP
EXT2LOW_LEN dw	 ?		; # bytes to copy

EXT2LOW_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

; Copy from extended memory to HPDA buffer

	 REGSAVE <ecx,edi,ds,es> ; Save for a moment

	 movzx	 ecx,[ebp].EXT2LOW_LEN ; Get # bytes to copy
	 mov	 ebp,[ebp].EXT2LOW_EBP ; Get caller's EBP to address INTXX_STR

	 lods	 JMPTAB21[si]	; Get xxx to be used in EBP+xxx for offset
	 movsx	 eax,ax 	; Sign extend to use with EBP

	 mov	 edi,[ebp+eax]	; Get value of source offset
				; Already zeroed to use as dword if 16-bit client

	 lods	 JMPTAB21[si]	; Get xxx to be used in EBP+xxx for segment
	 movsx	 eax,ax 	; Sign extend to use with EBP

	 mov	 ds,[ebp+eax]	; DS:EDI ==> caller's buffer
	 assume  ds:nothing	; Tell the assembler about it

	 push	 esi		; Save for a moment

	 mov	 esi,edi	; DS:ESI ==> caller's buffer

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 edi,PGROUP:[eax].DPTSS_LaHPDA ; Get linear address of HPDA
	 add	 edi,PGROUP:[eax].DPTSS_VMBUFOFF.EDD ; AGROUP:EDI ==> HPDA buffer

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

S32  rep movs	 <AGROUP:[edi].LO,ds:[esi].LO> ; Copy the leading bytes
				; from caller's buffer to DOS memory buffer
	 pop	 esi		; Restore

	 REGREST <es,ds,edi,ecx> ; Restore
	 assume  ds:nothing,es:PGROUP ; Tell the assembler about it

	 pop	 ebp		; Restore

	 lods	 JMPTAB21[si]	; Get next action

	 push	 ax		; Push as "return" address

	 ret	 2		; Take appropriate action, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_EXT2LOW endp		; End DOSFN_EXT2LOW procedure
	 NPPROC  DOSFN_SIMVMI -- Simulate Interrupt
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Simulate interrupt

On entry:

CS:SI	 ==>	 action stream with
		 INT # to simulate
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
AX	 =	 clobbered

|

	 REGSAVE <bx,cx,edi>	; Save registers

; Request simulation of interrupt

; Note that the following code doesn't care whether or not the
; current DPMI client is 16- or 32-bit as VMCREGS is within 64KB

	 lods	 JMPTAB21[si]	; Get interrupt # to simulate
	 mov	 bx,ax		; BL = Interrupt #, BH = flags (none)
	 xor	 cx,cx		; # words to copy
	 lea	 edi,VMCREGS	; ES:EDI ==> VMC register structure
	 DPMICALL0 @DPMI_SIMVMI  ; Request DPMI service
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger
@@:
	 REGREST <edi,cx,bx>	; Restore

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_SIMVMI endp		; End DOSFN_SIMVMI procedure
	 NPPROC  DOSFN_LOW2EXT -- Copy From DOS Buffer to Extended Memory
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy bytes from DOS buffer to caller's buffer
and release it

On entry:

CS:SI	 ==>	 action stream with
		 xxx to be used in EBP+xxx as offset
		 xxx ...		      selector
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)
SS:ESP+0 =	 # bytes to copy
SS:ESP+2 =	 # bytes to release

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered
ESP	 =	 (updated)

|

LOW2EXT_STR struc

LOW2EXT_EBP dd	 ?		; Caller's EBP
LOW2EXT_CPY dw	 ?		; # bytes to copy
LOW2EXT_LEN dw	 ?		; # bytes to release

LOW2EXT_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

; Copy from HPDA buffer to extended memory

	 REGSAVE <ecx,edx,edi>	; Save for a moment

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS

	 mov	 edx,PGROUP:[eax].DPTSS_LaHPDA ; Get linear address of HPDA
	 add	 edx,PGROUP:[eax].DPTSS_VMBUFOFF.EDD ; AGROUP:EDX ==> HPDA buffer
	 movzx	 ecx,[ebp].LOW2EXT_LEN ; Get # bytes to release
	 sub	 edx,ecx	; Back off to data to copy back

	 push	 ebp		; Save offset of LOW2EXT_STR

	 movzx	 ecx,[ebp].LOW2EXT_CPY ; Get # bytes to copy
	 mov	 ebp,[ebp].LOW2EXT_EBP ; Get caller's EBP to address INTXX_STR

	 lods	 JMPTAB21[si]	; Get xxx to be used in EBP+xxx for offset
	 movsx	 eax,ax 	; Sign extend to use with EBP

	 mov	 edi,[ebp+eax]	; Get value of destin offset
				; Already zeroed to use as dword if 16-bit client

	 lods	 JMPTAB21[si]	; Get xxx to be used in EBP+xxx for selector
	 movsx	 eax,ax 	; Sign extend to use with EBP

; Because we might be asked to write into a code selector
; (well, actually, KRNL386 asks us to do that), we get the
; selector base and use that via our all memory selector.

	 push	 [ebp+eax].ELO	; Get caller's selector
	 FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address from LDT

	 push	 es		; Save for a moment

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 add	 edi,eax	; AGROUP:EDI ==> caller's buffer

	 push	 esi		; Save for a moment

	 mov	 esi,edx	; Copy to source register
				; DS:ESI ==> HPDA buffer
S32  rep movs	 <AGROUP:[edi].LO,AGROUP:[esi].LO> ; Copy the trailing bytes
				; from DOS memory buffer to caller's buffer
	 pop	 esi		; Restore

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 pop	 ebp		; Restore

	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 mov	 cx,[ebp].LOW2EXT_LEN ; Get # bytes to release
	 sub	 PGROUP:[eax].DPTSS_VMBUFOFF,cx ; Subtract from starting offset
	 add	 PGROUP:[eax].DPTSS_VMBUFSIZ,cx ; Add back into size

	 REGREST <edi,edx,ecx>	; Restore

	 pop	 ebp		; Restore

	 lods	 JMPTAB21[si]	; Get next action

	 push	 ax		; Push as "return" address

	 ret	 2+2		; Take appropriate action, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_LOW2EXT endp		; End DOSFN_LOW2EXT procedure
	 NPPROC  DOSFN_SEG2SEL -- Convert Segment To Selector
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert segment to selector

On entry:

CS:SI	 ==>	 action stream with
		 @DATASEL or @CODESEL
		 VMC_xxx offset for segment register
		 xxx to be used in EBP+xxx as selector
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered

|

	 REGSAVE <bx,cx,ds>	; Save registers

	 mov	 ds,ISEL_DS3	; Get PGROUP data selector at PL3
	 assume  ds:PGROUP	; Tell the assembler about it

; Convert the resulting segment to a selector

	 lods	 JMPTAB21[si]	; Get @DATASEL or @CODESEL
	 mov	 cx,ax		; Save for a moment

	 lods	 JMPTAB21[si]	; Get offset of segment-register
	 mov	 bx,ax		; Copy to index register

; Distinguish between code and data selectors.	If it's to
; be code selector, we don't set the B-bit in the selector
; because the code mapped by this selector is in VM.

	 cmp	 cx,@CODESEL	; Do we want a code selector?
	 mov	 cx,DPMI_CODE	; Get A/R word for 16-bit app
	 je	 short DOSFN_SEG2SEL1 ; Jump if so

	 mov	 cl,DPMI_DATA.LO ; Get A/R byte for 16-bit app

; Set B-bit for data selectors if it's not a 16-bit app

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 setne	 ch		; CH = 1 if 32-bit or no DPMI
				;    = 0 if 16-bit
	 shl	 ch,$DTE_B	; Set B-bit for 32-bit apps
DOSFN_SEG2SEL1:
	 movzx	 eax,VMCREGS.ELO[bx] ; Get incoming segment
	 shl	 eax,4-0	; Convert from paras to bytes

	 push	 cx		; Pass A/R word
	 push	 CON64KB	; Pass segment length in bytes
	 push	 eax		; Pass base address
	 call	 GETSET_LDTFIX	; Return with EAX = selector ($TI and $PL set)
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger
@@:
	 mov	 bx,ax		; Copy resulting selector

	 lods	 JMPTAB21[si]	; Get xxx to be used in EBP+xxx for segment
	 movsx	 eax,ax 	; Sign extend to use with EBP
	 mov	 [ebp+eax],bx	; Return in caller's selector

	 REGREST <ds,cx,bx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_SEG2SEL endp		; End DOSFN_SEG2SEL procedure
	 NPPROC  DOSFN_SEL2SEG -- Convert Selector To Segment
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert selector to segment

On entry:

CS:SI	 ==>	 action stream with
		 VMC_xxx offset for selector register
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered

|

	 REGSAVE <bx>		; Save register

; Convert the initial selector to a segment

	 lods	 JMPTAB21[si]	; Get offset in VMCREGS of selector register
	 mov	 bx,ax		; Copy to index register

; Note that we're assuming that the given selector is in
; the LDT and is valid

	 push	 VMCREGS.ELO[bx] ; Pass selector
	 FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address from LDT

; Note that we're assuming that the base address is within the
; first megabyte and is on a para boundary

	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 VMCREGS.ELO[bx],ax ; Save back

	 REGREST <bx>		; Restore

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_SEL2SEG endp		; End DOSFN_SEL2SEG procedure
	 NPPROC  DOSFN_IF32ZX -- If 32-bit Client, Zero To use As Dword
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If we're running as a 32-bit client, zero the high-order
word of a register to use as a dword.

On entry:

CS:SI	 ==>	 action stream with
		 VMC_xxx offset of high-order word to zero
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
AX	 =	 clobbered

|

	 REGSAVE <bx>		; Save register

	 lods	 JMPTAB21[si]	; Get offset in VMCREGS of high-order word
	 mov	 bx,ax		; Copy to index register

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short @F	; Jump if so

	 mov	 VMCREGS.ELO[bx],0 ; Zero to use as dword
@@:
	 REGREST <bx>		; Restore

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_IF32ZX endp		; End DOSFN_IF32ZX procedure
	 NPPROC  DOSFN_ASCIIZ_LEN -- Get Length Of ASCIIZ String
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get length of ASCIIZ string

On entry:

CS:SI	 ==>	 action stream with
		 xxx to be used in EBP+xxx as offset
		 xxx to be used in EBP+xxx as selector
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered
SS:ESP+0 =	 length of ASCIIZ string

|

	 REGSAVE <ebx,edi,ds>	; Save registers

	 lods	 JMPTAB21[si]	; Get xxx to be used in EBP+xxx for offset
	 movsx	 eax,ax 	; Sign extend to use with EBP

	 mov	 edi,[ebp+eax]	; Get value of source offset
	 IF16ZX  di,IG		; Zero to use as dword if 16-bit client

	 lods	 JMPTAB21[si]	; Get xxx to be used in EBP+xxx for selector
	 movsx	 eax,ax 	; Sign extend to use with EBP

	 mov	 ds,[ebp+eax]	; DS:EDI ==> ASCIIZ string
	 assume  ds:nothing	; Tell the assembler about it

; Determine the length of the ASCIIZ string

	 xor	 ebx,ebx	; Initialize string counter
@@:
	 inc	 ebx		; Count in another

	 cmp	 ds:[edi+ebx-1].LO,0 ; Izit end-of-string?
	 jne	 short @B	; Jump if not

	 mov	 ax,bx		; Copy to return to next routine

; AX	 =	 length of string including zero-terminator

	 REGREST <ds,edi,ebx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 push	 ax		; Pass to next routine

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_ASCIIZ_LEN endp		; End DOSFN_ASCIIZ_LEN procedure
	 NPPROC  DOSFN_GETDTA -- Allocate a DTA
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate a DTA and copy to low DOS

On entry:

CS:SI	 ==>	 action stream with
		 size of the DTA to allocate
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
AX	 =	 clobbered

|

	 push	 OLDDTA_VEC	; Save old address of the DTA

	 REGSAVE <edx>		; Save register

; Tell DOS we're using a new DTA

	 call	 DPMIFN_GETDTA	; Get Seg:Off of DTA in low DOS into EDI
	 mov	 OLDDTA_VEC,edi ; Save to restore later

	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS

	 push	 PGROUP:[edx].DPTSS_HPDASEG ; Get segment of HPDA
	 push	 PGROUP:[edx].DPTSS_VMBUFOFF ; Get offset of DTA
	 call	 DPMIFN_SETDTA	; Set address of DTA in low DOS

	 lods	 JMPTAB21[si]	; Get size of DTA

	 add	 PGROUP:[edx].DPTSS_VMBUFOFF,ax ; Add into starting offset
	 sub	 PGROUP:[edx].DPTSS_VMBUFSIZ,ax ; Remove from size
	 jnc	 short @F	; Jump if there's room

	 int	 03h		; Call our debugger
@@:

; Copy the extended memory DTA to low DOS

	 push	 ax		; Pass length of DTA in bytes
	 push	 PGROUP:[edx].DPTSS_HPDASEG ; Get segment of HPDA
	 push	 PGROUP:[edx].DPTSS_VMBUFOFF ; Get offset+AX of DTA
	 sub	 [esp].ELO,ax	; Back off to actual DTA
	 call	 DPMIFN_EXT2DTA ; Copy contents of DTA at DPTSS_DTA_FVEC
				; (Sel|Off) to low DOS (Seg:Off)

	 REGREST <edx>		; Restore

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_GETDTA endp		; End DOSFN_GETDTA procedure
	 NPPROC  DOSFN_RELDTA -- Release a DTA
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Release a DTA and copy back to extended memory

On entry:

CS:SI	 ==>	 action stream with
		 size of the DTA to allocate
		 next action
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
AX	 =	 clobbered

|

	 REGSAVE <edx>		; Save register

	 mov	 edx,PCURTSS	; Get offset in PGROUP of current TSS

	 lods	 JMPTAB21[si]	; Get size of DTA

	 push	 ax		; Pass length of DTA in bytes
	 push	 PGROUP:[edx].DPTSS_HPDASEG ; Get segment of HPDA
	 push	 PGROUP:[edx].DPTSS_VMBUFOFF ; Get offset+AX of DTA
	 sub	 [esp].ELO,ax	; Back off to actual DTA
	 call	 DPMIFN_DTA2EXT ; Copy contents of DTA in low DOS (Seg:Off)
				; to DPTSS_DTA_FVEC (Sel|Off)

	 sub	 PGROUP:[edx].DPTSS_VMBUFOFF,ax ; Subtract from offset
	 add	 PGROUP:[edx].DPTSS_VMBUFSIZ,ax ; Add into size

	 push	 OLDDTA_VEC	; Pass Seg:Off of old DTA
	 call	 DPMIFN_SETDTA	; Set address of DTA in low DOS

	 REGREST <edx>		; Restore

	 pop	 OLDDTA_VEC	; Restore previous DTA address

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_RELDTA endp		; End DOSFN_RELDTA procedure
	 NPPROC  DOSFN_JMP -- Jump To A New Action Stream
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Jump to a new action stream

On entry:

CS:SI	 ==>	 action stream with
		 next action stream
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

CS:SI	 ==>	 (updated)
AX	 =	 clobbered

|

	 lods	 JMPTAB21[si]	; Get next action
	 mov	 si,ax		; CS:SI ==> action stream

	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_JMP endp			; End DOSFN_JMP procedure
	 NPPROC  DOSFN_EXEC_SAVEENV -- Load And Execute Save Environment
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Load and execute save environment

On entry:

CS:SI	 ==>	 action stream with
		 next action stream
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

SS:ESP+0 =	 Environment selector
SS:ESP+2 =	 PSP ...
SS:ESP+4 =	 VM stack segment
CS:SI	 ==>	 (updated)
EAX	 =	 clobbered

|

SAVEENV_STR struc

SAVEENV_EBP    dd ?		; Caller's EBP
SAVEENV_ENVSEL dw ?		; Environment selector
SAVEENV_PSPSEL dw ?		; PSP ...
SAVEENV_VMSTKSEG dw ?		; VM stack segment

SAVEENV_STR ends

	 sub	 esp,(type SAVEENV_STR)-(type SAVEENV_EBP) ; Make room

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <bx,ds>	; Save registers

	 DOSCALL @GETPS0	; Get current PSP into BX

	 mov	 ds,bx		; Address it
	 assume  ds:PSPGRP	; Tell the assembler about it

	 mov	 [ebp].SAVEENV_PSPSEL,bx ; Save to restore later

	 mov	 ax,PSP_ENVIR_PTR ; Get current environment selector
	 mov	 [ebp].SAVEENV_ENVSEL,ax ; Save to restore later

; Convert the environment selector to a segment.
; Note we're assuming that it's in the first megabyte and
; on a para boundary.  There's not much we can do if that's
; not the case.

	 push	 ax		; Pass as argument
	 FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address of selector

	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 PSP_ENVIR_PTR,ax ; Save as environment segment

; Allocate room for a VM stack

	 mov	 [ebp].SAVEENV_VMSTKSEG,0 ; Assume we fail

	 mov	 bx,@HPDAFRM_SIZ/16 ; Get stack frame size in paras
	 call	 DOSFN_GETMEM	; Allocate BX paras of low DOS memory
	 jc	 short @F	; Jump if we failed
				; Return with AX = Seg of allocated memory
	 mov	 [ebp].SAVEENV_VMSTKSEG,ax ; Save to restore later
	 mov	 VMCREGS.VMC_SS,ax ; Save to use in low memory
	 shl	 bx,4-0 	; Convert from paras to bytes
	 mov	 VMCREGS.VMC_SP,bx ; Save to use in low memory

	 clc			; Mark as successful
@@:
	 REGREST <ds,bx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore
	 jnc	 short @F	; Jump if all went OK

	 or	 VMCREGS.VMC_FL,mask $CF ; Mark as in error so we free
				; low DOS memory at DOSFN_EXEC_LETERM
	 lea	 si,INT21_DPMIJMP_EXEC_SAVEENV_ERR ; CS:SI ==> action stream
@@:
	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_EXEC_SAVEENV endp 	; End DOSFN_EXEC_SAVEENV procedure
	 NPPROC  DOSFN_EXEC_RESTENV -- Load And Execute Restore Environment
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Load and execute restore environment

On entry:

CS:SI	 ==>	 action stream with
		 next action stream
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)
SS:ESP+0 =	 Environment selector
SS:ESP+2 =	 PSP ...
SS:ESP+4 =	 VM stack segment

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered
ESP	 =	 (updated)

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ds>		; Save register

	 mov	 ax,[ebp].SAVEENV_ENVSEL ; Get the original environment selector

	 mov	 ds,[ebp].SAVEENV_PSPSEL ; Address the PSP
	 assume  ds:PSPGRP	; Tell the assembler about it

	 mov	 PSP_ENVIR_PTR,ax ; Restore it

; Release the VM stack we allocated earlier

	 mov	 ax,[ebp].SAVEENV_VMSTKSEG ; Get the VM stack segment

	 and	 ax,ax		; Izit valid?
	 jz	 short @F	; Jump if not

	 call	 DOSFN_RELMEM	; De-allocate segment AX in low DOS memory
	 jnc	 short @F	; Jump if successful

	 int	 03h		; Call our debugger
@@:
	 REGREST <ds>		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 ebp		; Restore

	 lods	 JMPTAB21[si]	; Get next action

	 push	 ax		; Push as "return" address

	 ret	 (type SAVEENV_STR)-(type SAVEENV_EBP) ; Take appropriate action, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_EXEC_RESTENV endp 	; End DOSFN_EXEC_RESTENV procedure
	 NPPROC  DOSFN_EXEC_LEFIX -- Load And Execute Fixup
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Load and execute fixup

On entry:

CS:SI	 ==>	 action stream with
		 next action stream
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)

On exit:

SS:ESP+0 =	 Segment of command line
SS:ESP+2 =	 ...	    FCB #1
SS:ESP+4 =	 ...		#2
CS:SI	 ==>	 (updated)
EAX	 =	 clobbered

|

EXEC_LE_STR struc

EXEC_LE_EBP  dd ?		; Caller's EBP
EXEC_LE_CMD  dw ?		; Segment of command line
EXEC_LE_FCB1 dw ?		; ...	     FCB #1
EXEC_LE_FCB2 dw ?		; ...		 #2

EXEC_LE_STR ends

	 sub	 esp,(type EXEC_LE_STR)-(type EXEC_LE_EBP) ; Make room

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ebx,ecx,edx,esi,edi,ds,fs> ; Save registers

	mov	[ebp].EXEC_LE_CMD,-1 ; Mark as undefined
	mov	[ebp].EXEC_LE_FCB1,-1 ; ...
	mov	[ebp].EXEC_LE_FCB2,-1 ; ...

; ES:BX in VMCREGS points to EXEC_STR or EXECD_STR

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

	 movzx	 edx,VMCREGS.VMC_ES ; Get low DOS segment
	 shl	 edx,4-0	; Convert from paras to bytes
	 movzx	 eax,VMCREGS.VMC_EBX.ELO ; Get low DOS offset
	 add	 edx,eax	; DS:EDX ==> EXEC_STR in low DOS

; The command line in EXEC_CMD needs to be allocated and copied to low DOS

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short DOSFN_EXEC_LEFIX1 ; Jump if so

	 lfs	 esi,ds:[edx].EXECD_CMD ; FS:ESI ==> command line
	 assume  fs:nothing	; Tell the assembler about it

	 jmp	 short @F	; Join common code

DOSFN_EXEC_LEFIX1:
	 xor	 esi,esi	; Zero to use as dword
	 lfs	 si,ds:[edx].EXEC_CMD ; FS:ESI ==> command line
	 assume  fs:nothing	; Tell the assembler about it
@@:
	 movzx	 ecx,fs:[esi].LO ; Get size of the command line
	 add	 ecx,2		; Include length byte and trailing CR

	 mov	 ebx,ecx	; Copy # bytes needed
	 add	 ebx,16-1	; Round up to para boundary
	 shr	 ebx,4-0	; Convert from bytes to paras
	 call	 DOSFN_GETMEM	; Allocate BX paras of low DOS memory
	 jc	 near ptr DOSFN_EXEC_LEFIX_EXIT ; Jump if we failed (note CF=1)
				; Return with AX = Seg of allocated memory
	mov	[ebp].EXEC_LE_CMD,ax ; Save to release later

; Copy data from command line to low DOS

	 push	 es		; Save for a moment

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 movzx	 edi,ax 	; Copy segment
	 shl	 edi,4-0	; Convert from paras to bytes

S32  rep movs	 <AGROUP:[edi].LO,fs:[esi].LO> ; Copy it

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 shl	 eax,16 	; Shift segment to high-order word
	 mov	 ds:[edx].EXEC_CMD,eax ; Save new Seg:off

; The FCB in EXEC_FCB1 needs to be allocated and copied to low DOS

	 mov	 ecx,size FCB_STR ; Get size of the FCB

	 mov	 ebx,ecx	; Copy # bytes needed
	 add	 ebx,16-1	; Round up to para boundary
	 shr	 ebx,4-0	; Convert from bytes to paras
	 call	 DOSFN_GETMEM	; Allocate BX paras of low DOS memory
	 jc	 near ptr DOSFN_EXEC_LEFIX_EXIT ; Jump if we failed (note CF=1)
				; Return with AX = Seg of allocated memory
	mov	[ebp].EXEC_LE_FCB1,ax ; Save to release later

	 movzx	 edi,ax 	; Copy segment
	 shl	 edi,4-0	; Convert from paras to bytes
				; AGROUP:EDI ==> destination

; Copy data from FCB #1 to low DOS

	 push	 es		; Save for a moment

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short DOSFN_EXEC_LEFIX2 ; Jump if so

	 mov	 bx,ds:[edx].EXECD_FCB1.FSEL ; Get selector
	 mov	 esi,ds:[edx].EXECD_FCB1.FOFF ; Get offset

	 push	 bx		; Pass selector
	 push	 esi		; Pass offset
	 push	 ecx		; Pass length in bytes
	 push	 edi		; Pass target address
	 call	 DOSFN_CHKRNG	; Check the range
	 jc	 short DOSFN_EXEC_LEFIX2B ; Jump if it's invalid

	 mov	 fs,bx		; FS:ESI ==> FCB #1
	 assume  fs:nothing	; Tell the assembler about it

	 jmp	 short DOSFN_EXEC_LEFIX2A ; Join common code

DOSFN_EXEC_LEFIX2:
	 mov	 bx,ds:[edx].EXEC_FCB1.VSEG ; Get selector
	 movzx	 esi,ds:[edx].EXEC_FCB1.VOFF ; Get offset

	 push	 bx		; Pass selector
	 push	 esi		; Pass offset
	 push	 ecx		; Pass length in bytes
	 push	 edi		; Pass target address
	 call	 DOSFN_CHKRNG	; Check the range
	 jc	 short DOSFN_EXEC_LEFIX2B ; Jump if it's invalid

	 mov	 fs,bx		; FS:ESI ==> FCB #1
	 assume  fs:nothing	; Tell the assembler about it
DOSFN_EXEC_LEFIX2A:
S32  rep movs	 <AGROUP:[edi].LO,fs:[esi].LO> ; Copy it
DOSFN_EXEC_LEFIX2B:
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 shl	 eax,16 	; Shift segment to high-order word
	 mov	 ds:[edx].EXEC_FCB1,eax ; Save new Seg:off

; The FCB in EXEC_FCB2 needs to be allocated and copied to low DOS

	 mov	 ecx,size FCB_STR ; Get size of the FCB

	 mov	 ebx,ecx	; Copy # bytes needed
	 add	 ebx,16-1	; Round up to para boundary
	 shr	 ebx,4-0	; Convert from bytes to paras
	 call	 DOSFN_GETMEM	; Allocate BX paras of low DOS memory
	 jc	 short DOSFN_EXEC_LEFIX_EXIT ; Jump if we failed (note CF=1)
				; Return with AX = Seg of allocated memory
	mov	[ebp].EXEC_LE_FCB2,ax ; Save to release later

	 movzx	 edi,ax 	; Copy segment
	 shl	 edi,4-0	; Convert from paras to bytes
				; AGROUP:EDI ==> destination

; Copy data from FCB #2 to low DOS

	 push	 es		; Save for a moment

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 cmp	 DPMITYPEIG,@DPMITYPE16 ; Izit a 16-bit client?
	 je	 short DOSFN_EXEC_LEFIX3 ; Jump if so

	 mov	 bx,ds:[edx].EXECD_FCB2.FSEL ; Get selector
	 mov	 esi,ds:[edx].EXECD_FCB2.FOFF ; Get offset

	 push	 bx		; Pass selector
	 push	 esi		; Pass offset
	 push	 ecx		; Pass length in bytes
	 push	 edi		; Pass target address
	 call	 DOSFN_CHKRNG	; Check the range
	 jc	 short DOSFN_EXEC_LEFIX3B ; Jump if it's invalid

	 mov	 fs,bx		; FS:ESI ==> FCB #2
	 assume  fs:nothing	; Tell the assembler about it

	 jmp	 short DOSFN_EXEC_LEFIX3A ; Join common code

DOSFN_EXEC_LEFIX3:
	 mov	 bx,ds:[edx].EXEC_FCB2.VSEG ; Get selector
	 movzx	 esi,ds:[edx].EXEC_FCB2.VOFF ; Get offset

	 push	 bx		; Pass selector
	 push	 esi		; Pass offset
	 push	 ecx		; Pass length in bytes
	 push	 edi		; Pass target address
	 call	 DOSFN_CHKRNG	; Check the range
	 jc	 short DOSFN_EXEC_LEFIX3B ; Jump if it's invalid

	 mov	 fs,bx		; FS:ESI ==> FCB #2
	 assume  fs:nothing	; Tell the assembler about it
DOSFN_EXEC_LEFIX3A:
S32  rep movs	 <AGROUP:[edi].LO,fs:[esi].LO> ; Copy it
DOSFN_EXEC_LEFIX3B:
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 shl	 eax,16 	; Shift segment to high-order word
	 mov	 ds:[edx].EXEC_FCB2,eax ; Save new Seg:off

; The environment must be zero (MS says so, that's why)

	 mov	 ds:[edx].EXEC_ENV,0 ; Force it

	 clc			; Indicate all went well
DOSFN_EXEC_LEFIX_EXIT:
	 REGREST <fs,ds,edi,esi,edx,ecx,ebx> ; Restore
	 assume  ds:nothing,fs:nothing ; Tell the assembler about it
	 pop	 ebp		; Restore
	 jnc	 short @F	; Jump if all went well

	 lea	 si,INT21_DPMIJMP_EXEC_LEFIX_ERR ; CS:SI ==> action stream
@@:
	 lods	 JMPTAB21[si]	; Get next action
	 jmp	 ax		; Take appropriate action

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_EXEC_LEFIX endp		; End DOSFN_EXEC_LEFIX procedure
	 NPPROC  DOSFN_EXEC_LETERM -- Load and Execute Termination
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Load and execute termination

On entry:

CS:SI	 ==>	 action stream with
		 next action stream
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_SS is valid)
SS:ESP+0 =	 Segment of command line
SS:ESP+2 =	 ...	    FCB #1
SS:ESP+4 =	 ...		#2

On exit:

CS:SI	 ==>	 (updated)
EAX	 =	 clobbered
ESP	 =	 (updated)

|

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

; The command line in EXEC_CMD needs to be de-allocated

	mov	ax,[ebp].EXEC_LE_CMD ; Get the segment

	cmp	ax,-1		; Izit undefined?
	je	short @F	; Jump if so

	 call	 DOSFN_RELMEM	; De-allocate segment AX in low DOS memory
	 jnc	 short @F	; Jump if successful

	 int	 03h		; Call our debugger
@@:

; The FCB in EXEC_FCB1 needs to be de-allocated

	mov	ax,[ebp].EXEC_LE_FCB1 ; Get the segment

	cmp	ax,-1		; Izit undefined?
	je	short @F	; Jump if so

	 call	 DOSFN_RELMEM	; De-allocate segment AX in low DOS memory
	 jnc	 short @F	; Jump if successful

	 int	 03h		; Call our debugger
@@:

; The FCB in EXEC_FCB2 needs to be de-allocated

	mov	ax,[ebp].EXEC_LE_FCB2 ; Get the segment

	cmp	ax,-1		; Izit undefined?
	je	short @F	; Jump if so

	 call	 DOSFN_RELMEM	; De-allocate segment AX in low DOS memory
	 jnc	 short @F	; Jump if successful

	 int	 03h		; Call our debugger
@@:
	 pop	 ebp		; Restore

	 lods	 JMPTAB21[si]	; Get next action

	 push	 ax		; Push as "return" address

	 ret	 (type EXEC_LE_STR)-(type EXEC_LE_EBP) ; Take appropriate action, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_EXEC_LETERM endp		; End DOSFN_EXEC_LETERM procedure
	 NPPROC  DOSFN_CHKRNG -- Check Selector Validity and Range
	 assume  ds:AGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check selector validity and range.
If it's invalid, fill the target with zeros.

On exit:

CF	 =	 0 if valid
	 =	 1 otherwise

|

CHKRNG_STR struc

	 dd	 ?		; Caller's EBP
	 dw	 ?		; ...	   IP
CHKRNG_DST dd	 ?		; Destination in AGROUP
CHKRNG_LEN dd	 ?		; Length in bytes
CHKRNG_FVEC df	 ?		; Sel|Off of source

CHKRNG_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ecx,edi>	; Save registers

; Check the selector for validity

	 verr	 [ebp].CHKRNG_FVEC.FSEL ; Izit readable?
	 jnz	 short DOSFN_CHKRNG_ERR ; Jump if not

; Alas, VERR passes not present readable selectors
; so we must check for that separately via LAR

	 lar	 ax,[ebp].CHKRNG_FVEC.FSEL ; Get A/R word

	 test	 ah,mask $DT_P	; Izit present?
	 jz	 short DOSFN_CHKRNG_ERR ; Jump if not

	 mov	 ecx,[ebp].CHKRNG_LEN ; Get length of the move
	 jecxz	 DOSFN_CHKRNG_CLC ; Jump if it's empty

	 dec	 ecx		; Convert from length to limit

; Ensure it's within selector limits

	 lsl	 eax,[ebp].CHKRNG_FVEC.FSEL.EDD ; Get selector limit

	 add	 ecx,[ebp].CHKRNG_FVEC.FOFF ; Plus starting offset
	 jc	 short DOSFN_CHKRNG_ERR ; Jump if start+length wraps

	 cmp	 ecx,eax	; Check ending address against limit
	 ja	 short DOSFN_CHKRNG_ERR ; Jump if start+length > limit
DOSFN_CHKRNG_CLC:
	 clc			; Mark as valid

	 jmp	 short DOSFN_CHKRNG_EXIT ; Join common exit code

DOSFN_CHKRNG_ERR:
	 mov	 ecx,[ebp].CHKRNG_LEN ; Get length of the move
	 mov	 edi,[ebp].CHKRNG_DST ; AGROUP:EDI ==> destination
	 mov	 al,0		; Write zeros
     rep stos	 AGROUP:[edi].LO ; Zero it

	 stc			; Mark invalid
DOSFN_CHKRNG_EXIT:
	 REGREST <edi,ecx,eax>	; Restore

	 pop	 ebp		; Restore

	 ret	 4+4+6		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_CHKRNG endp		; End DOSFN_CHKRNG procedure
	 NPPROC  DOSFN_GETMEM -- Allocate Low DOS Memory
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate low DOS memory

On entry:

BX	 =	 # paras to allocate

On exit:

CF	 =	 0 if successful
AX	 =	 segment in low DOS of allocated memory

CF	 =	 1 if unsuccessful
AX	 =	 DOS error code

|

	 REGSAVE <bx,cx,edi>	; Save registers

	 call	 SAVE_VMCREGS	; Save current values of VMCREGS on stack

	 mov	 VMCREGS.VMC_EAX.ELO.HI,@GETMEM ; Save DOS function
	 mov	 VMCREGS.VMC_EBX.ELO,bx ; Save # paras we need
	 mov	 VMCREGS.VMC_SP,0 ; Tell 'em to find their own stack
	 mov	 VMCREGS.VMC_SS,0 ; ...
	 mov	 VMCREGS.VMC_FL,0 ; Set to known value

; Note that the following code doesn't care whether or not the
; current DPMI client is 16- or 32-bit as VMCREGS is within 64KB

	 mov	 bx,21h 	; BL = Interrupt #, BH = flags (none)
	 xor	 cx,cx		; # words to copy
	 lea	 edi,VMCREGS	; ES:EDI ==> VMC register structure
	 DPMICALL0 @DPMI_SIMVMI  ; Request DPMI service
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger
@@:
	 mov	 ax,VMCREGS.VMC_EAX.ELO ; Get segment of allocated memory
	 mov	 bx,VMCREGS.VMC_FL ; Get the return flags

	 call	 REST_VMCREGS	; Restore old values of VMCREGS from stack

	 bt	 bx,$CF 	; Copy $CF to CF

	 REGREST <edi,cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_GETMEM endp		; End DOSFN_GETMEM procedure
	 NPPROC  DOSFN_RELMEM -- De-allocate Low DOS Memory
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

De-allocate low DOS memory

On entry:

AX	 =	 segment in low DOS to de-allocate

On exit:

CF	 =	 0 if successful

CF	 =	 1 if unsuccessful
AX	 =	 DOS error code

|

	 REGSAVE <bx,cx,edi>	; Save registers

	 call	 SAVE_VMCREGS	; Save current values of VMCREGS on stack

	 mov	 VMCREGS.VMC_EAX.ELO.HI,@RELMEM ; Save DOS function
	 mov	 VMCREGS.VMC_ES,ax ; Save segment # to de-allocate
	 mov	 VMCREGS.VMC_SP,0 ; Tell 'em to find their own stack
	 mov	 VMCREGS.VMC_SS,0 ; ...
	 mov	 VMCREGS.VMC_FL,0 ; Set to known value

; Note that the following code doesn't care whether or not the
; current DPMI client is 16- or 32-bit as VMCREGS is within 64KB

	 mov	 bx,21h 	; BL = Interrupt #, BH = flags (none)
	 xor	 cx,cx		; # words to copy
	 lea	 edi,VMCREGS	; ES:EDI ==> VMC register structure
	 DPMICALL0 @DPMI_SIMVMI  ; Request DPMI service
	 jnc	 short @F	; Jump if all went OK

	 int	 03h		; Call our debugger
@@:
	 mov	 ax,VMCREGS.VMC_EAX.ELO ; Get the error code (if any)
	 mov	 bx,VMCREGS.VMC_FL ; Get the return flags

	 call	 REST_VMCREGS	; Restore old values of VMCREGS from stack

	 bt	 bx,$CF 	; Copy $CF to CF

	 REGREST <edi,cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DOSFN_RELMEM endp		; End DOSFN_RELMEM procedure
	 align	 4		; Ensure dword alignment

ICODE	 ends			; End ICODE segment
endif				; IF @OEM_DPMI

	 MEND			; End QMAX_D21 module
