;' $Header:   P:/PVCS/MAX/386MAX/QMAX_BCF.ASV   1.2   30 May 1997 10:44:10   BOB  $
	 title	 QMAX_BCF -- 386MAX BCF Functions
	 page	 58,122
	 name	 QMAX_BCF

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Program segment HICODE,	dword-aligned, public, class 'prog'
	       Data    segment EDATA,	dword-aligned, public, class 'edata'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Group XGROUP:
	       Program segment XCODE,	byte-aligned,  public, class 'xcode'
	       Data    segment XDATA,	dword-aligned, public, class 'xdata'
	       Group YGROUP:
	       Data    segment YDATA,	dword-aligned, public, class 'ydata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include VIDCALL.INC
	 include VIDATTR.INC
	 include ASCII.INC
	 include 386.INC
	 include PTR.INC
	 include BITFLAGS.INC
	 include ALLMEM.INC
	 include CPUID.INC
	 include BIOSDATA.INC

	 include QMAX_BCF.INC
	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
	 include QMAX_XBI.INC	; Common include file for XBIOS fixups
	 include BIOSCONF.INC
	 include QMAX_AOX.INC	; AOX specific information
.list

if @OEM_BCF
PGROUP	 group	 CODE,HICODE,EDATA,NCODE,NDATA
XGROUP	 group	 XCODE,XDATA
YGROUP	 group	 YDATA
CGROUP	 group	 CPUID_SEG


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 SYSROM_START:word

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  ds:PGROUP

	 extrn	 SBIOSDATA:word

HICODE	 ends			; End HICODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

if @OEM_DEBUG
	 extrn	 CPDCNT:word
	 extrn	 CPD_FLAG:word
	 include QMAX_CPD.INC
endif				; IF @OEM_DEBUG
	 extrn	 DB3_FLAG:word
	 include QMAX_DB3.INC

	 extrn	 CON128KB:dword
	 extrn	 CON64KB:dword
	 extrn	 CON1MB:dword
	 extrn	 MAPSEG_NXT:word

	 public  BCF_CNT,BCF_SEG,MIVT_VEC
BCF_CNT  dw	 ?		; # bytes in the BCF
BCF_SEG  dw	 ?		; Segment of the BCF
MIVT_VEC df	 ?		; Seg:off32 of the Modify Interrupt Vector Table

; The MIVT structure is as follows

MIVT_STR struc

MIVT_OLD dd	 ?		; Old offset
MIVT_NEW dw	 ?		; New ...
MIVT_LEN dw	 ?		; Length of entry in bytes

MIVT_STR ends

	 public  BCF_BIOSSIZE,BCF_BASSIZE,BIOS_CRC64,BIOS_CRC128
BCF_BIOSSIZE dd  ?		; Size of new BIOS in bytes (multiple of 4KB)
BCF_BASSIZE  dw  0		; Size of BASIC in bytes (zero if not present)
BIOS_CRC64 dw	 ?		; BIOS CRC if 64KB
BIOS_CRC128 dw	 ?		; ...	     128KB

	 public FIX_FLAG
FIX_FLAG FIX_REC <>		; BCF fixup flags

EDATA	 ends			; End EDATA segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 NRD_FLAG:dword
	 include QMAX_NRD.INC

	 extrn	 UCSYSROM_START:dword

	 public  XAM863
XAM863	 dd	 'M863'         ; Slack area text filler

NDATA	 ends			; End NDATA segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

	 extrn	 CPQ_FLAG:word
	 include QMAX_CPQ.INC

	 extrn	 FINDHW_ACT:word
	 extrn	 OLDINTHW_VEC:dword
	 extrn	 ROMADDR:word
	 extrn	 CPQINT01_SAVE:dword
	 extrn	 CPQINT29_VEC:dword

	 public BIO_FIXBUF
BIO_FIXBUF db	16 dup (0)	; AOX BIOS correction buffer

	 public  CHECK_BCFTAB
CHECK_BCFTAB label word
	 dw	 XGROUP:CHECK_BCF_CMDERR ; 00 = error
	 dw	 XGROUP:CHECK_BCF_EMOV	 ; 01 = move from E000
	 dw	 XGROUP:CHECK_BCF_FMOV	 ; 02 = move from F000
	 dw	 XGROUP:CHECK_BCF_ADDW	 ; 03 = word fixup
	 dw	 XGROUP:CHECK_BCF_ADDB	 ; 04 = byte fixup
	 dw	 XGROUP:CHECK_BCF_CMDERR ; 05 = ;; Move multiple from E000
	 dw	 XGROUP:CHECK_BCF_CMDERR ; 06 = ;; Move multiple from F000
	 dw	 XGROUP:CHECK_BCF_CMDERR ; 07 = ;; Add multiple Word
	 dw	 XGROUP:CHECK_BCF_CMDERR ; 08 = ;; Add multiple Byte
	 dw	 XGROUP:CHECK_BCF_CMDERR ; 09 = error
	 dw	 XGROUP:CHECK_BCF_CMDERR ; 0A = error
	 dw	 XGROUP:CHECK_BCF_CMDERR ; 0B = error
	 dw	 XGROUP:CHECK_BCF_CMDERR ; 0C = error
	 dw	 XGROUP:CHECK_BCF_CMDERR ; 0D = error
	 dw	 XGROUP:CHECK_BCF_CMDERR ; 0E = error
	 dw	 XGROUP:CHECK_BCF_CMDERR ; 0F = error
	 dw	 XGROUP:CHECK_BCF_CMDERR ; 10 = error
	 dw	 XGROUP:CHECK_BCF_EMOVB  ; 11 = move BASIC from E000
	 dw	 XGROUP:CHECK_BCF_FMOVB  ; 12 = move BASIC from F000
CHECK_BCFTABLEN equ ($-CHECK_BCFTAB)/(type CHECK_BCFTAB) ; # entries in table

	 public  PROC_BCFTAB
PROC_BCFTAB label word
	 dw	 XGROUP:PROC_BCF_CMDERR ; 00 = error
	 dw	 XGROUP:PROC_BCF_EMOV	; 01 = move from E000
	 dw	 XGROUP:PROC_BCF_FMOV	; 02 = move from F000
	 dw	 XGROUP:PROC_BCF_ADDW	; 03 = word fixup
	 dw	 XGROUP:PROC_BCF_ADDB	; 04 = byte fixup
	 dw	 XGROUP:PROC_BCF_CMDERR ; 05 = error
	 dw	 XGROUP:PROC_BCF_CMDERR ; 06 = error
	 dw	 XGROUP:PROC_BCF_EMVM	; 07 = Move multiple from E000
	 dw	 XGROUP:PROC_BCF_FMVM	; 08 = Move multiple from F000
	 dw	 XGROUP:PROC_BCF_ADMW	; 09 = Add multiple Word
	 dw	 XGROUP:PROC_BCF_ADMB	; 0A = Add multiple Byte
	 dw	 XGROUP:PROC_BCF_CMDERR ; 0B = error
	 dw	 XGROUP:PROC_BCF_CMDERR ; 0C = error
	 dw	 XGROUP:PROC_BCF_CMDERR ; 0D = error
	 dw	 XGROUP:PROC_BCF_CMDERR ; 0E = error
	 dw	 XGROUP:PROC_BCF_CMDERR ; 0F = error
	 dw	 XGROUP:PROC_BCF_CMDERR ; 10 = error
	 dw	 XGROUP:PROC_BCF_EMOVB	; 11 = move BASIC from E000
	 dw	 XGROUP:PROC_BCF_FMOVB	; 12 = move BASIC from F000
PROC_BCFTABLEN equ ($-PROC_BCFTAB)/(type PROC_BCFTAB) ; # entries in table

	 public  XORLIST
XORLIST  dw	 00000h, 0C0C1h, 0C181h, 00140h, 0C301h, 003C0h, 00280h, 0C241h
	 dw	 0C601h, 006C0h, 00780h, 0C741h, 00500h, 0C5C1h, 0C481h, 00440h
	 dw	 0CC01h, 00CC0h, 00D80h, 0CD41h, 00F00h, 0CFC1h, 0CE81h, 00E40h
	 dw	 00A00h, 0CAC1h, 0CB81h, 00B40h, 0C901h, 009C0h, 00880h, 0C841h
	 dw	 0D801h, 018C0h, 01980h, 0D941h, 01B00h, 0DBC1h, 0DA81h, 01A40h
	 dw	 01E00h, 0DEC1h, 0DF81h, 01F40h, 0DD01h, 01DC0h, 01C80h, 0DC41h
	 dw	 01400h, 0D4C1h, 0D581h, 01540h, 0D701h, 017C0h, 01680h, 0D641h
	 dw	 0D201h, 012C0h, 01380h, 0D341h, 01100h, 0D1C1h, 0D081h, 01040h
	 dw	 0F001h, 030C0h, 03180h, 0F141h, 03300h, 0F3C1h, 0F281h, 03240h
	 dw	 03600h, 0F6C1h, 0F781h, 03740h, 0F501h, 035C0h, 03480h, 0F441h
	 dw	 03C00h, 0FCC1h, 0FD81h, 03D40h, 0FF01h, 03FC0h, 03E80h, 0FE41h
	 dw	 0FA01h, 03AC0h, 03B80h, 0FB41h, 03900h, 0F9C1h, 0F881h, 03840h
	 dw	 02800h, 0E8C1h, 0E981h, 02940h, 0EB01h, 02BC0h, 02A80h, 0EA41h
	 dw	 0EE01h, 02EC0h, 02F80h, 0EF41h, 02D00h, 0EDC1h, 0EC81h, 02C40h
	 dw	 0E401h, 024C0h, 02580h, 0E541h, 02700h, 0E7C1h, 0E681h, 02640h
	 dw	 02200h, 0E2C1h, 0E381h, 02340h, 0E101h, 021C0h, 02080h, 0E041h
	 dw	 0A001h, 060C0h, 06180h, 0A141h, 06300h, 0A3C1h, 0A281h, 06240h
	 dw	 06600h, 0A6C1h, 0A781h, 06740h, 0A501h, 065C0h, 06480h, 0A441h
	 dw	 06C00h, 0ACC1h, 0AD81h, 06D40h, 0AF01h, 06FC0h, 06E80h, 0AE41h
	 dw	 0AA01h, 06AC0h, 06B80h, 0AB41h, 06900h, 0A9C1h, 0A881h, 06840h
	 dw	 07800h, 0B8C1h, 0B981h, 07940h, 0BB01h, 07BC0h, 07A80h, 0BA41h
	 dw	 0BE01h, 07EC0h, 07F80h, 0BF41h, 07D00h, 0BDC1h, 0BC81h, 07C40h
	 dw	 0B401h, 074C0h, 07580h, 0B541h, 07700h, 0B7C1h, 0B681h, 07640h
	 dw	 07200h, 0B2C1h, 0B381h, 07340h, 0B101h, 071C0h, 07080h, 0B041h
	 dw	 05000h, 090C1h, 09181h, 05140h, 09301h, 053C0h, 05280h, 09241h
	 dw	 09601h, 056C0h, 05780h, 09741h, 05500h, 095C1h, 09481h, 05440h
	 dw	 09C01h, 05CC0h, 05D80h, 09D41h, 05F00h, 09FC1h, 09E81h, 05E40h
	 dw	 05A00h, 09AC1h, 09B81h, 05B40h, 09901h, 059C0h, 05880h, 09841h
	 dw	 08801h, 048C0h, 04980h, 08941h, 04B00h, 08BC1h, 08A81h, 04A40h
	 dw	 04E00h, 08EC1h, 08F81h, 04F40h, 08D01h, 04DC0h, 04C80h, 08C41h
	 dw	 04400h, 084C1h, 08581h, 04540h, 08701h, 047C0h, 04680h, 08641h
	 dw	 08201h, 042C0h, 04380h, 08341h, 04100h, 081C1h, 08081h, 04040h

	 public  BCFINTS
BCFINTS  label	 tbyte
		 ;				00h  Divide overflow
		 ;				01h  Single-step
	 BCFINT_STR <XGROUP:FINDIGN,   4*02h> ; 02h  NMI
		 ;				03h  Breakpoint
	 BCFINT_STR <XGROUP:FINDCHK,   4*04h> ; 04h  Overflow
	 BCFINT_STR <XGROUP:FINDIGN,   4*05h> ; 05h  Print screen/BOUND
	 BCFINT_STR <XGROUP:FINDCHK,   4*06h> ; 06h  Invalid opcode
	 BCFINT_STR <XGROUP:FINDERR,   4*07h> ; 07h  Reserved
	 BCFINT_STR <XGROUP:FINDROMCHK,4*08h> ; 08h  IRQ0:  Timer tick
	 BCFINT_STR <XGROUP:FINDROMCHK,4*09h> ; 09h  IRQ1:  Keyboard
	 BCFINT_STR <XGROUP:FINDROMCHK,4*0Ah> ; 0Ah  IRQ2:  Miscellaneous
	 BCFINT_STR <XGROUP:FINDROMCHK,4*0Bh> ; 0Bh  IRQ3:  COM2
	 BCFINT_STR <XGROUP:FINDROMCHK,4*0Ch> ; 0Ch  IRQ4:  COM1
	 BCFINT_STR <XGROUP:FINDROMCHK,4*0Dh> ; 0Dh  IRQ5:  LPT2
	 BCFINT_STR <XGROUP:FINDROMCHK,4*0Eh> ; 0Eh  IRQ6:  Diskette
	 BCFINT_STR <XGROUP:FINDROMCHK,4*0Fh> ; 0Fh  IRQ7:  Printer
	 BCFINT_STR <XGROUP:FIND10,    4*10h> ; 10h  Video services
	 BCFINT_STR <XGROUP:FINDCHK,   4*11h> ; 11h  Get equipment flags
	 BCFINT_STR <XGROUP:FINDCHK,   4*12h> ; 12h  Get memory size
	 BCFINT_STR <XGROUP:FIND13,    4*13h> ; 13h  Disk/Diskette services
	 BCFINT_STR <XGROUP:FIND14,    4*14h> ; 14h  COM services
	 BCFINT_STR <XGROUP:FIND15,    4*15h> ; 15h  BIOS services
	 BCFINT_STR <XGROUP:FIND16,    4*16h> ; 16h  Keyboard services
	 BCFINT_STR <XGROUP:FIND17,    4*17h> ; 17h  Printer services
		 ;				18h  BASIC services
		 ;				19h  Warm boot
	 BCFINT_STR <XGROUP:FIND1A,    4*1Ah> ; 1Ah  Timer services
	 BCFINT_STR <XGROUP:FIND1B,    4*1Bh> ; 1Bh  Control-break
	 BCFINT_STR <XGROUP:FINDCHK,   4*1Ch> ; 1Ch  Timer tick
	 BCFINT_STR <XGROUP:FINDIGN,   4*1Dh> ; 1Dh  Video parameter table
		 ;				1Eh  Diskette parameter table
	 BCFINT_STR <XGROUP:FINDIGN,   4*1Fh> ; 1Fh  Graphic characters table
		 ;				20h-3Fh DOS services
	 BCFINT_STR <XGROUP:FIND40,    4*40h> ; 40h  Diskette services
	 BCFINT_STR <XGROUP:FINDIGN,   4*41h> ; 41h  HD #0 parameter table
	 BCFINT_STR <XGROUP:FINDIGN,   4*42h> ; 42h  EGA revectored INT 10h
	 BCFINT_STR <XGROUP:FINDIGN,   4*43h> ; 43h  EGA first 128 characters
	 BCFINT_STR <XGROUP:FINDCHK,   4*44h> ; 44h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*45h> ; 45h  Reserved
	 BCFINT_STR <XGROUP:FINDIGN,   4*46h> ; 46h  HD #1 parameter table
	 BCFINT_STR <XGROUP:FINDCHK,   4*47h> ; 47h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*48h> ; 48h  Reserved
	 BCFINT_STR <XGROUP:FINDVERIFY,4*49h> ; 49h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*4Ah> ; 4Ah  Reserved
	 BCFINT_STR <XGROUP:FIND4B,    4*4Bh> ; 4Bh  VDS services
	 BCFINT_STR <XGROUP:FINDCHK,   4*4Ch> ; 4Ch  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*4Dh> ; 4Dh  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*4Eh> ; 4Eh  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*4Fh> ; 4Fh  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*50h> ; 50h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*51h> ; 51h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*52h> ; 52h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*53h> ; 53h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*54h> ; 54h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*55h> ; 55h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*56h> ; 56h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*57h> ; 57h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*58h> ; 58h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*59h> ; 59h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*5Ah> ; 5Ah  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*5Bh> ; 5Bh  Reserved
	 BCFINT_STR <XGROUP:FIND5C,    4*5Ch> ; 5Ch  NETBIOS
	 BCFINT_STR <XGROUP:FINDIGN,   4*5Dh> ; 5Dh  Reserved (used by Core controller)
	 BCFINT_STR <XGROUP:FINDCHK,   4*5Eh> ; 5Eh  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*5Fh> ; 5Fh  Reserved
		 ;				60h-67h User-available interrupts
	 BCFINT_STR <XGROUP:FINDCHK,   4*68h> ; 68h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*69h> ; 69h  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*6Ah> ; 6Ah  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*6Bh> ; 6Bh  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*6Ch> ; 6Ch  Reserved
	 BCFINT_STR <XGROUP:FIND10,    4*6Dh> ; 6Dh  Secondary VGA interrupt
	 BCFINT_STR <XGROUP:FINDCHK,   4*6Eh> ; 6Eh  Reserved
	 BCFINT_STR <XGROUP:FINDCHK,   4*6Fh> ; 6Fh  Reserved
	 BCFINT_STR <XGROUP:FINDROMCHK,4*70h> ; 70h  IRQ08:  Real-time clock
	 BCFINT_STR <XGROUP:FINDROMCHK,4*71h> ; 71h  IRQ09:  redirect to IRQ2
	 BCFINT_STR <XGROUP:FINDROMCHK,4*72h> ; 72h  IRQ10:  Reserved
	 BCFINT_STR <XGROUP:FINDROMCHK,4*73h> ; 73h  IRQ11:  Reserved
	 BCFINT_STR <XGROUP:FINDROMCHK,4*74h> ; 74h  IRQ12:  Auxiliary device
	 BCFINT_STR <XGROUP:FIND75,    4*75h> ; 75h  IRQ13:  80287/387
	 BCFINT_STR <XGROUP:FINDROMCHK,4*76h> ; 76h  IRQ14:  HD controller
	 BCFINT_STR <XGROUP:FINDROMCHK,4*77h> ; 77h  IRQ15:  Reserved
	 BCFINT_STR <XGROUP:FINDIGN,   04A8h> ;12Ah  EGA save ptr
	 public  NBCFINTS
NBCFINTS equ	 ($-BCFINTS)/(type BCFINT_STR) ; # interrupts to check

; Define additional FIX_FLAG entries
; This line *MUST* be directly after the BCFINTS list

FIXUP0	 BCFINT_STR <		   ,	    , @BCFSKIP> ; Fixup #0

NBCFIXINTS equ	 ($-BCFINTS)/(type BCFINT_STR) ; # interrupts to check
				; in INIT_MIVT

XBDAFMAC BCFX			; Define XBDA patching table

XDATA	 ends			; End XDATA segment


YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
	 assume  ds:YGROUP

	 extrn	 MSG_BCF_FCRC:byte
	 extrn	 MSG_BCF_BCRC:byte
	 extrn	 MSG_BCF_CMD:byte
	 extrn	 MSG_BCF_INT:byte
	 extrn	 MSG_BCF_INT1:byte
	 extrn	 MSG_BCF_DBG:byte
	 extrn	 MSG_BCF_DBG1:byte

	 extrn	 AZS_WORKING:byte
	 extrn	 AZS_BLNKING:byte

YDATA	 ends			; End YDATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 DISP_CPDMSG_PM:near

	 extrn	 FBIN2BASE:far

	 public  @QMAX_BCF_NCODE
@QMAX_BCF_NCODE:

	 NPPROC  INIT_MIVT -- Initialize MIVT
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize modify interrupt vector table.

This routine runs in PM only.

On exit:
@NRD_BCFERR set in NRD_FLAG if an error occurred (i.e., an interrupt
pointed into system ROM but was not covered by a BCF fixup).

|

	 pushad 		; Save all EGP registers
	 push	 gs		; Save segment register

	 test	 LCL_FLAG,@LCL_BCF ; Izit in effect?
	 jz	 near ptr INIT_MIVT_EXIT ; Jump if not

	 push	 DTE_D4GB	; Get our all memory segment
	 pop	 gs		; Address it
	 assume  gs:AGROUP	; Tell the assembler about it

	 movzx	 edi,MIVT_VEC.FSEL ; Get MIVT segment
	 shl	 edi,4-0	; Convert from paras to bytes
				; AGROUP:EDI ==> MIVT segment
	 xor	 esi,esi	; Zero to use as dword
	 mov	 si,seg XGROUP	; Get segment of XGROUP
	 shl	 esi,4-0	; Convert from paras to bytes
				; AGROUP:ESI ==> XGROUP:0

; If we have FIX_FLAG fixups, process them now

	 test	 FIX_FLAG,mask $FIX0 ; Izit fixup # 0?
	 jz	 short INIT_MIVT_XFIX0 ; Jump if not

; Fixup #0 is at offset 000Eh in XBDA2

	 movzx	 ebx,SBIOSDATA	; Get BIOS data segment
	 shl	 ebx,4-0	; Convert from para to bytes

	 assume  gs:BIOSDATA	; Tell the assembler about it
	 movzx	 ebx,XBDA_SEG[ebx] ; Get the segment of the XBDA
	 assume  gs:AGROUP	; Tell the assembler about it
	 shl	 ebx,4-0	; Convert from para to bytes

	 movzx	 eax,AGROUP:[ebx+00B4h].ELO ; Get number of paras to XBDA2
	 shl	 eax,4-0	; Convert from para to bytes

; Ensure that the XBDA2 offset is within the XBDA

	 movzx	 ecx,AGROUP:[ebx].LO ; Get the size of the XBDA in KB
	 shl	 ecx,10-0	; Convert from 1 KB to bytes

	 cmp	 eax,ecx	; Izit within the XBDA?
	 jae	 short INIT_MIVT_XFIX0 ; Jump if not

	 add	 eax,ebx	; Add to get 32-bit linear address of XBDA2

; Ensure that segment of the pointer in XBDA2 is in E000 or F000

	 cmp	 AGROUP:[eax+000Eh].VSEG, 0E000h ; Izit in the E000 BIOS?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[eax+000Eh].VSEG, 0F000h ; Izit in the F000 BIOS?
	 jne	 short INIT_MIVT_XFIX0 ; Jump if not

@@:
	 add	 eax,000Eh	; Skip to offset in XBDA2

	 lea	 ebx,XGROUP:FIXUP0[esi] ; XGROUP:EBX ==> Fixup #0 entry
	 mov	 AGROUP:[ebx].BCFLIN_ADR,eax ; Save linear address for fixup #0
INIT_MIVT_XFIX0:
	 mov	 cx,NBCFIXINTS	; CX = # interrupt vectors to check
	 lea	 esi,XGROUP:BCFINTS[esi] ; XGROUP:ESI ==> BCF interrupt structures
INIT_MIVT_NEXTBCF:
	 mov	 ebx,AGROUP:[esi].BCFLIN_ADR ; Get ROM 32 bit pointer

	 cmp	 ebx,@BCFSKIP	; Should we skip this interrupt?
	 je	 near ptr INIT_MIVT_LOOPBCF ; Yes, go do the next interrupt

; Convert the ROM address into a 32-bit linear address

	 movzx	 edx,AGROUP:[ebx].VSEG ; Get the segment, zero high-order word
	 shl	 edx,4-0	; Convert from paras to bytes
	 movzx	 eax,AGROUP:[ebx].VOFF ; Get the offset
	 add	 edx,eax	; Add to get 32-bit linear address
				; AGROUP:EDX ==> ROM (presumably)

; If it's above the start of the system ROM but below the start of the
; table, it's a shortcoming of the BCF file and we need to flag it as
; an error.
	 assume  ss:PGROUP	; Tell the assembler
	 cmp	 edx,ss:UCSYSROM_START ; Izit below the start of system ROM?
	 assume  ss:nothing	; Tell the assembler
	 jb	 near ptr INIT_MIVT_LOOPBCF ; Jump if below ROM (ignore it)

; Check for within table lower limit

	 cmp	 edx,AGROUP:[edi].MIVT_OLD ; Izit below table lower limit?
	 jb	 short INIT_MIVT_BCFERR ; Jump if so (it's an error)

; Look for this address in the MIVT tables

	 xor	 ebp,ebp	; Zero index into MIVT tables
INIT_MIVT_NEXTMIVT:
	 movzx	 eax,AGROUP:[edi+ebp].MIVT_LEN ; Get the length in bytes
	 add	 eax,AGROUP:[edi+ebp].MIVT_OLD ; Plus old offset to get upper limit

	 cmp	 edx,eax	; Izit within this entry?
	 jb	 short INIT_MIVT_FOUND ; Jump if within this entry

	 add	 ebp,type MIVT_STR ; Skip to next entry

	 cmp	 ebp,MIVT_VEC.FOFF ; Izit outside table upper limit?
	 jnb	 short INIT_MIVT_BCFERR ; Jump if so

	 jmp	 short INIT_MIVT_NEXTMIVT ; Try the next one

INIT_MIVT_FOUND:
	 sub	 edx,AGROUP:[edi+ebp].MIVT_OLD ; Less old starting address
	 jnc	 short INIT_MIVT_INRANGE ; Jump if within range

	 add	 edx,AGROUP:[edi+ebp].MIVT_OLD ; Restore for debugging

INIT_MIVT_BCFERR:
	 test	 LCL_FLAG,@LCL_SWAT ; Is 386SWAT installed?
	 jz	 short @F	; Jump if not

; EBX = Linear address of the location to fix up.
; EDX = Linear address in the BIOS of suspect entry.
; EDI = Linear address of the MIVT Table
; EBP = MIVT Entry that we worked up to.

	 int	 03h		; Call our debugger
@@:
	 push	 ds		; Save for later
	 push	 ss		; Get sel for PGROUP in Low DOS
	 pop	 ds		; . . .
	 assume  ds:PGROUP	; PGROUP in Low DOS

	 push	 CPD_FLAG	; Save contents of CPD flag

	 or	 CPD_FLAG,@CPD_MSG ; Turn on CPD messages
	 mov	 CPDCNT,0	; Next three lines should be contigous


	 CPDPM	 'Unhandled Fixup in BCF'
	 CPDPM	 '  ==> Linear address to fix up: %EBX'
	 CPDPM	 '  ==>       Address pointed to: %EDX'

	 mov	 CPDCNT,@CPDCNT ; Force next message to pause

	 CPDPM	 ' '            ; Force a pause

	 pop	 CPD_FLAG	; Restore CPD Flag

	 pop	 ds		; Restore DS
	 assume  ds:PGROUP	; (Extended memory PGROUP)

; We need to use the NRD_FLAG in low DOS so we can check it after returning
; to virtual mode.
	 assume  ss:PGROUP	; Address copy in low DOS
	 or	 ss:NRD_FLAG,@NRD_BCFERR ; Flag as an error
	 assume  ss:nothing	; Tell the assembler
	 jmp	 short INIT_MIVT_LOOPBCF ; Continue with next

INIT_MIVT_INRANGE:
	 add	 dx,AGROUP:[edi+ebp].MIVT_NEW ; Plus new starting address

	 mov	 AGROUP:[ebx].VOFF,dx ; Save as new offset
	 mov	 AGROUP:[ebx].VSEG,0F000h ; ...     segment
INIT_MIVT_LOOPBCF:
	 add	 esi,size BCFINT_STR ; Skip to next entry

;;;;;;;  loop	 INIT_MIVT_NEXTBCF ; Jump if more BCF interrupts
	 dec	 cx		; Adjust loop counter
	 jnz	 near ptr INIT_MIVT_NEXTBCF ; Jump if more BCF interrupts

COMMENT |

Check here for FIXUP1 - Needed for the Memorex Telex machine

Get the interrupt 77 vector (after it has been BCF adjusted)
and place it in the primary XBDA at affset 74h

|

	 test	 FIX_FLAG,mask $FIX1 ; Izit fixup # 1?
	 jz	 short INIT_MIVT_XFIX1 ; Jump if not

	 movzx	 ebx,SBIOSDATA	; Get BIOS data segment
	 shl	 ebx,4-0	; Convert from para to bytes

	 assume  gs:BIOSDATA	; Tell the assembler about it
	 movzx	 ebx,XBDA_SEG[ebx] ; Get the segment of the XBDA
	 assume  gs:AGROUP	; Tell the assembler about it
	 shl	 ebx,4-0	; Convert from para to bytes

	 mov	 eax,AGROUP:[4*77h] ; Get interrupt 77 vector
	 mov	 AGROUP:[ebx+74h],eax ; ... and save in XBDA

INIT_MIVT_XFIX1:

COMMENT |

Check for special machines that have ROM pointers in the XBDA.
If we find one, patch it to point to the new BIOS location.

|
	 xor	 ebx,ebx	; Zero pointer
	 mov	 bx,seg XGROUP	; Get segment of XGROUP
	 shl	 ebx,4-0	; Convert from paras to bytes
				; AGROUP:EBX ==> XGROUP:0
	 lea	 ebx,XGROUP:BCFX_TBL[ebx] ; XGROUP:EBX ==> XBDA structures

	 movzx	 esi,AGROUP:[40Eh].ELO ; Get XBDA pointer
	 shl	 esi,(4-0)	; Convert paras to bytes

	 mov	 cx,BCFX_CNT	; Load loop counter with the number of items

INIT_MIVT_NEXTXBDA:

	 REGSAVE <esi>		; Save XBDA pointer

	 mov	 ax,AGROUP:[ebx].BCFX_STR_CRC ; Get the BIOS CRC
	 cmp	 BIOS_CRC128,ax ; Is this the BIOS in question?
	 jne	 short INIT_MIVT_LOOPXBDA ; No, bypass fixup

	 movzx	 eax,AGROUP:[ebx].BCFX_STR_POF ; Get the paragraph offset
	 or	 ax,ax		; Any value?
				; (note:0 is not valid and can't be used
				;  so we interpret it as a special flag)
	 je	 short @F	; No, Go

	 movzx	 eax,AGROUP:[esi+eax].ELO ; Get the paragraph offset count
	 shl	 eax,(4-0)	; Convert paras to bytes
	 add	 esi,eax	; Add in the byte offset of structure
@@:
	 movzx	 eax,AGROUP:[ebx].BCFX_STR_FUP ; Get the fixup offset
	 add	 esi,eax	; Add in the offset of element

	 mov	 eax,AGROUP:[ebx].BCFX_STR_OLD ; Get what should be there
	 cmp	 AGROUP:[esi],eax ; Izit the expected entry?
	 jne	 short INIT_MIVT_LOOPXBDA ; Jump if not

	 mov	 eax,AGROUP:[ebx].BCFX_STR_NEW ; Get what we want there
	 mov	 AGROUP:[esi],eax ; Patch the location

INIT_MIVT_LOOPXBDA:
	 REGREST <esi>		; Restore XBDA pointer

	 add	 ebx,size BCF_XBDA_STR ; Bump index to next structure
	 loop	 INIT_MIVT_NEXTXBDA ; Do until counter expires

INIT_MIVT_EXIT:
	 pop	 gs		; Restore
	 assume  gs:nothing	; Tell the assembler about it
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_MIVT endp			; End INIT_MIVT procedure

NCODE	 ends			; End NCODE segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 public  @QMAX_BCF_XCODE
@QMAX_BCF_XCODE:		; Mark module start in .MAP file

	 extrn	 FINDHW_ROM:near
	 extrn	 FINDCHK:far
	 extrn	 FINDIGN:far
	 extrn	 FINDERR:far
	 extrn	 FINDVERIFY:far
	 extrn	 FIND13:far
	 extrn	 FIND14:far
	 extrn	 FIND15:far
	 extrn	 FIND16:far
	 extrn	 FIND17:far
	 extrn	 FIND1A:far
	 extrn	 FIND1B:far
	 extrn	 FIND40:far
	 extrn	 FIND4B:far
	 extrn	 FIND5C:far
	 extrn	 CPQINT29:far
	 extrn	 SAVEINT01:near

	 extrn	 FMT_ERR_CODE:far
	 extrn	 YMSGOUT2:near

	 extrn	 DISPAZS:near

	 FPPROC  CHECK_BCRC -- Set BIOS CRC
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set BIOS CRC

|

	 REGSAVE <eax,bx,fs,gs> ; Save registers

	 push	 seg XGROUP	; Get the segment
	 pop	 fs		; Address it
	 assume  fs:XGROUP	; Tell the assembler about it

	 push	 @RSV_SEG	; Restart vector segment
	 pop	 gs		; Address it
	 assume  gs:nothing	; Tell assembler

;	 Copy the last paragraph of BIOS to internal buffer

	 mov	 eax,gs:[0]	; Get first four bytes
	 mov	 BIO_FIXBUF[0].EDD,eax ; Save away
	 mov	 eax,gs:[4]	; Get next four bytes
	 mov	 BIO_FIXBUF[4].EDD,eax ; Save away
	 mov	 eax,gs:[8]	; Get next four bytes
	 mov	 BIO_FIXBUF[8].EDD,eax ; Save away
	 mov	 eax,gs:[12]	; Get next four bytes
	 mov	 BIO_FIXBUF[12].EDD,eax ; Save away

; If we're on a non-MicroChannel system, we need to be cautious of
; a potential hardware flaw that causes some systems to interpret
; an out to 73h as an out to 71h.  This was a major problem in ASQ,
; where the last CMOS value we indexed via port 70h was the hard disk
; type (not a happy ending).  This same test is in the real mode and
; VCPI CRC code in BIOSCRC.ASM and VCPI_CRC.ASM.
	 test	 LCL_FLAG,@LCL_MCA ; Izit a MicroChannel system?
	 jz	 short CB_050	; Jump if not

	 mov	 al,@AOX_RID	; Command to read CPU info for AOX
	 out	 @AOX_MMD,al	; Request CPU info for AOX
	 in	 al,@AOX_MMD	; Read first byte (should be 55h)
	 mov	 ah,al		; Save
	 in	 al,@AOX_MMD	; Read next byte (should be aah)
	 cmp	 ax,055aah	; Is it an AOX board
	 jne	 CB_050 	; No, go do the CRC

	 mov	 BIO_FIXBUF[1].EDD,0F000E05Bh ; Fix restart vector

	 REGSAVE <es>		; Save for BIOS call

	 mov	 ah,0C0h	; Function to get system configuration
	 int	 15h		; Request info pointer ES:BX
	 assume  es:nothing	; Tell assembler

	 mov	 al,es:[bx].CFG_MODEL ; Get the ID byte
	 REGREST <es>		; Restore used
	 assume  es:PGROUP	; Tell assembler

	 jc	 short @F	; Go if not supported

	 mov	 BIO_FIXBUF[14],al ; Set ID back to normal
@@:
	 push	 0h		; Pass the seed for accumulator
	 push	 0E000h 	; Pass the start segment
	 push	 0h		; ...		 offset
	 mov	 eax,CON128KB	; Get length in bytes
	 sub	 eax,16 	; Cut back by the last para
	 push	 eax		; Pass the length in bytes
	 call	 CALC_SUM	; Calculate the checksum into AX

	 push	 ax		; Pass the seed for accumulator
	 push	 seg XGROUP	; Pass the start segment
	 lea	 ax,BIO_FIXBUF	; Get offset of buffer
	 push	 ax		; Pass the offset of AOX corrected BIOS buffer
	 push	 0		; Pass high-order word of
	 push	 16-1		; Pass the length in bytes (omit fixup)
	 call	 CALC_SUM	; Calculate the checksum into AX

	 neg	 al		; Adjust to make 0 sum
	 mov	 BIO_FIXBUF[15],al ; Save fixup
CB_050:
	 push	 0h		; Pass the seed for accumulator
	 push	 0E000h 	; Pass the start segment
	 push	 0h		; ...		 offset
	 mov	 eax,CON128KB	; Get length in bytes
	 sub	 eax,16 	; Cut back by the last para
	 push	 eax		; Pass the length in bytes
	 call	 CALC_CRC	; Calculate the CRC into AX

	 push	 ax		; Pass the seed for accumulator
	 push	 seg XGROUP	; Pass the start segment
	 lea	 ax,BIO_FIXBUF	; Get offset of buffer
	 push	 ax		; Pass the offset of AOX corrected BIOS buffer
	 push	 0		; Pass high-order word of
	 push	 16		; Pass the length in bytes
	 call	 CALC_CRC	; Calculate the CRC into AX

	 mov	 BIOS_CRC128,ax ; Save for later use

	 push	 0h		; Pass the seed for accumulator
	 push	 0F000h 	; Pass the start segment
	 push	 0h		; ...		 offset
	 mov	 eax,CON64KB	; Get length in bytes
	 sub	 eax,16 	; Cut back by the last para
	 push	 eax		; Pass the length in bytes
	 call	 CALC_CRC	; Calculate the CRC into AX

	 push	 ax		; Pass the seed for accumulator
	 push	 seg XGROUP	; Pass the start segment
	 lea	 ax,BIO_FIXBUF	; Get offset of buffer
	 push	 ax		; Pass the offset of AOX corrected BIOS buffer
	 push	 0		; Pass high-order word of
	 push	 16		; Pass the length in bytes
	 call	 CALC_CRC	; Calculate the CRC into AX

	 mov	 BIOS_CRC64,ax	; Save for later use
CN_EXIT:
	 REGREST <gs,fs,bx,eax> ; Restore
	 assume  fs:nothing,gs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_BCRC endp 		; End CHECK_BCRC procedure
	 NPPROC  CHECK_BCF -- Check A BCF File
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Check a BCF file for validity.

* Decrypt the file
* Validate the CRC for the BCF file -- it should be zero
* Validate the CRC for the target BIOS -- it should match BCFH_BCRC
* Calculate BIOS segment length
* Validate the BCF command cells and interrupt vector values

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,si,ds,gs> ; Save registers

	 mov	 bl,@ATMrevhighblink ; Get screen attribute
	 lea	 si,YGROUP:AZS_WORKING ; YGROUP:SI ==> ASCIIZ string to display
	 call	 DISPAZS	; Display AZS string with attribute

	 mov	 ds,BCF_SEG	; Get BCF segment
	 assume  ds:nothing	; Tell the assembler about it

; * Decrypt the file

	 push	 seg CGROUP	; Get segment of BIOS
	 pop	 gs		; Address it
	 assume  gs:CGROUP	; Tell the assembler about it
	 mov	 bx,@BCF_CRYPTOFF ; GS:BX ==> decryption offset

	 mov	 si,ds:[0].BCFH_SIZE ; DS:SI ==> starting address
	 mov	 cx,BCF_CNT	; Get the size of the BCF file
	 sub	 cx,si		; Less starting offset
CHECK_BCF_CRYPT:
	 lodsb			; Get next byte from BCF file
	 add	 al,gs:[bx]	; Plus encryption byte in BIOS
	 mov	 ds:[si-1],al	; Save back
	 inc	 bx		; Skip to next byte in BIOS

	 loop	 CHECK_BCF_CRYPT ; Jump if more bytes to decrypt

	 and	 ds:[0].BCFH_REV,not @BCF_CRYPT ; Mark as decrypted for CRC calc

; * Validate the CRC for the BCF file -- it should match BCFH_FCRC

	 xor	 bx,bx		; A convenient zero
	 xchg	 bx,ds:[0].BCFH_FCRC ; Swap with the CRC of the file

	 push	 0h		; Pass the seed for accumulator
	 push	 BCF_SEG	; Pass the segment
	 push	 0h		; ...	   offset
	 push	 0		; Pass high-order word of
	 push	 BCF_CNT	; ...the length in bytes
	 call	 CALC_CRC	; Calculate the CRC into AX

	 mov	 ds:[0].BCFH_FCRC,bx ; Restore the CRC of the file

	 cmp	 ax,bx		; Izit a valid CRC?
	 jne	 near ptr CHECK_BCF_FCRC ; Jump if not

; * Validate the CRC for the target BIOS -- it should match BCFH_BCRC

	 mov	 ax,ds:[0].BCFH_BCRC ; Get the CRC of the target BIOS

	 cmp	 ax,BIOS_CRC64	; Check against the BIOS CRC if 64KB
	 je	 short @F	; Jump if it's a match

	 cmp	 ax,BIOS_CRC128 ; Check against the BIOS CRC if 128KB
	 jne	 near ptr CHECK_BCF_BCRC ; Jump if it doesn't match
@@:

; * Calculate BIOS segment length

	 movzx	 eax,ds:[0].BCFH_BOFF ; Get starting offset in bytes
	 and	 ax,not (4096-1) ; Round down to 4KB boundary
	 sub	 eax,CON64KB	; Subtract from 64KB
	 neg	 eax		; Negate to get positive value
	 mov	 BCF_BIOSSIZE,eax ; Save as size of BIOS

; * Validate the BCF command cells and interrupt vector values
;   We can't do the validation if the command cells are variable length

	 cmp	 ds:[0].BCFH_VERS,1 ; Check BCF version number
	 jae	 short CHECK_BCF_OK ; Jump if version 1 (or later)

	 mov	 cx,ds:[0].BCFH_NCELL ; Get the # command cells
	 mov	 si,ds:[0].BCFH_SIZE ; DS:SI ==> starting address
CHECK_BCF_NEXT:
	 movzx	 eax,ds:[si].BCF_CMD ; Get command byte

	 cmp	 al,CHECK_BCFTABLEN ; Ensure valid
	 jae	 short CHECK_BCF_CMDERR ; Jump if not

	 jmp	 CHECK_BCFTAB[eax*2] ; Take appropriate action

CHECK_BCF_EMOVB:
CHECK_BCF_FMOVB:
	 mov	 ax,ds:[si].BCF_DATA ; Get move length
	 mov	 BCF_BASSIZE,ax ; Save as size

;;;;;;;; jmp	 short CHECK_BCF_LOOP ; Join common loop code

CHECK_BCF_EMOV:
CHECK_BCF_FMOV:
CHECK_BCF_ADDW:
CHECK_BCF_ADDB:
CHECK_BCF_LOOP:

	 add	 si,size BCF_CSTR ; Skip to next entry (rev 1.0)

	 loop	 CHECK_BCF_NEXT ; Jump if more command cells

CHECK_BCF_OK:

; Run through interrupt vectors ferreting out those
; which point into system ROM

	 call	 SRCH_BCFINT	; Search for 'em
	 jc	 short CHECK_BCF_INTERR ; Jump if we didn't find an important one

	 or	 LCL_FLAG,@LCL_BCF ; Mark as in effect

	 mov	 bl,@ATMnorm	; Get screen attribute
	 lea	 si,YGROUP:AZS_BLNKING ; YGROUP:SI ==> ASCIIZ string to display
	 call	 DISPAZS	; Display AZS string with attribute

	 clc			; Indicate all went well

	 jmp	 short CHECK_BCF_EXIT ; Join common exit code

CHECK_BCF_FCRC:
	 lea	 dx,YGROUP:MSG_BCF_FCRC ; Pass address of error message

	 jmp	 short CHECK_BCF_ERR ; Join common error code

CHECK_BCF_BCRC:
	 lea	 dx,YGROUP:MSG_BCF_BCRC ; Pass address of error message

	 jmp	 short CHECK_BCF_ERR ; Join common error code

CHECK_BCF_CMDERR:
	 lea	 dx,YGROUP:MSG_BCF_CMD ; Pass address of error message

	 jmp	 short CHECK_BCF_ERR ; Join common error code

CHECK_BCF_INTERR:
	 lea	 dx,YGROUP:MSG_BCF_INT ; Pass address of error message
CHECK_BCF_ERR:
	 push	 seg YGROUP	; Get message segment
	 pop	 ds		; Address it
	 assume  ds:YGROUP	; Tell the assembler about it

	 mov	 bl,@ATMnorm	; Get screen attribute
	 lea	 si,YGROUP:AZS_BLNKING ; YGROUP:SI ==> ASCIIZ string to display
	 call	 DISPAZS	; Display AZS string with attribute

	 DOSCALL @STROUT	; Display it

	 stc			; Indicate something went wrong
CHECK_BCF_EXIT:
	 REGREST <gs,ds,si,ecx,ebx,eax> ; Restore
	 assume  ds:nothing,gs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_BCF endp			; End CHECK_BCF procedure
	 NPPROC SRCH_BCFINT_GETLIN - Get linear address in EBX of XGROUP:[si].BCFINT_VEC
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Subroutine to get linear address in EBX of XGROUP:[si].BCFINT_VEC

Entry: XGROUP:SI points to current BCFINT structure

Exit:  EBX - Set to the linear address pointed to by the interrupt
	     vector in question
|
	 push	 eax		; Destroy as little as possible

	 movzx	 ebx,XGROUP:[si].BCFINT_VEC.VSEG ; Get the segment, zero high-order word
	 shl	 ebx,4-0	; Convert from paras to bytes
	 movzx	 eax,XGROUP:[si].BCFINT_VEC.VOFF ; Get the offset
	 add	 ebx,eax	; Add to get 32-bit linear address
	 mov	 XGROUP:[si].BCFLIN_ADR,ebx ; Set linear address pointer

	 pop	 eax		; Restore orginal value

	 mov	 XGROUP:[si].BCFLIN_ADR,ebx ; Set new linear address pointer

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH_BCFINT_GETLIN endp
	 NPPROC SRCH_BCFCHKDUBL - Check for duplicate ROM fixup entries
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for duplicate ROM fixup entries and set the @BCFSKIP
flag for BCFLIN_ADR if found

Entry: XGROUP:SI points to current BCFINT structure
       EBX Linear address in question
       CX number of ints left to test

Exit:  XGROUP:[si].BCFLIN_ADR will be set to @BCFSKIP if duplicate is found

|
	 REGSAVE <ax,cx,di>	; Save our current count

	 mov	 ax,NBCFINTS	; AX = # interrupt vectors to check
	 sub	 ax,cx		; Reduce AX to the number we have done
	 mov	 cx,ax		; Put in CX for loop count

	 lea	 di,BCFINTS	; XGROUP:DI ==> First BCF interrupt structure

	 jcxz	 short SRCH_BCFINT_CHKDONE ; Avoid doing first entry
SRCH_BCFINT_CHK:
	 cmp	 XGROUP:[di].BCFLIN_ADR,ebx ; Have we recorded this address before?
	 jne	 short @F	; No, skip to next entry

	 mov	 XGROUP:[si].BCFLIN_ADR,@BCFSKIP ; Set flag to skip fixup for this int
	 jmp	 short SRCH_BCFINT_CHKDONE ; Go on we don't need to look further
@@:
	 add	 di,size BCFINT_STR ; Skip to next entry
	 loop	 SRCH_BCFINT_CHK ; Go look at next entry

SRCH_BCFINT_CHKDONE:

	 REGREST <di,cx,ax>	; Restore count

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH_BCFCHKDUBL endp
	 NPPROC  SRCH_BCFINT -- Search For BCF Interrupts
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Search for BCF interrupts

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,bx,cx,si,ds,gs> ; Save registers

	 push	 seg XGROUP	; Get the segment
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 push	 seg AGROUP	; Get interrupt vector segment
	 pop	 gs		; Address it
	 assume  gs:AGROUP	; Tell the assembler about it

; Save old INT 01h handler to restore later

	 push	 es		; Save for a moment

	 call	 SAVEINT01	; Save current INT 01h handler

; Save old and install new INT 29h handler so we don't display
; ^C when the INT 1Bh is called.

	 mov	 al,29h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old INT 29h handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 CPQINT29_VEC.VOFF,bx ; Save to restore later
	 mov	 CPQINT29_VEC.VSEG,es

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 al,29h 	; Intercept this one
	 DOSCALL @SETINT,CPQINT29 ; Install our own one

; Set address of action routine if found

	 mov	 FINDHW_ACT,offset XGROUP:FINDHW_ROM ; Save it
	 mov	 ROMADDR,0E000h ; Set lowest expected ROM address

	 mov	 cx,NBCFINTS	; CX = # interrupt vectors to check
	 lea	 si,BCFINTS	; XGROUP:SI ==> BCF interrupt structures
SRCH_BCFINT_NEXT:
	 call	 SRCH_BCFINT_GETLIN ; Get linear address of BCFINT_VEC...
				    ; and set XGROUP:[si].BCFLIN_ADR to it..
				    ; and return linear address in EBX
	 mov	 eax,XGROUP:[si].BCFINT_VEC ; Get offset into segment 0

	 mov	 CPQINT01_SAVE,eax ; Save as seed in case of ignore
	 mov	 bx,ax		; Copy the offset to index register

	 mov	 ax,AGROUP:[bx].VSEG ; Get the segment from segment 0

	 and	 ax,ax		; Izit valid?
	 jz	 near ptr SRCH_BCFINT_LOOP ; Jump if not

	 cmp	 ax,SYSROM_START ; Izit in system ROM?
	 jb	 short @F	; Jump if below

	 REGSAVE <eax,ebx>	; Save for a moment

	 movzx	 eax,ax 	; Get segment
	 shl	 eax,4-0	; Convert paras to bytes
	 movzx	 ebx,AGROUP:[bx].VOFF ; Get offset
	 add	 eax,ebx	; Get linear address
	 cmp	 eax,CON1MB	; Izit in the HMA?

	 REGREST <ebx,eax>	; Restore
	 jc	 short SRCH_BCFINT_LOOP ; Jump if not - it's in system ROM

@@:
	 cmp	 bx,4*100h	; Check for above the interrupt vector section
	 jae	 short SRCH_BCFINT_XINT ; Jump if it's too large

; None of the above -- search for the original address

	 REGSAVE <bx,es>	; Save for a moment

	 mov	 ax,bx		; Get offset into segment 0
	 shr	 ax,2-0 	; Convert from bytes to dwords
	 DOSCALL @GETINT	; Return with ES:BX ==> old INT xxh handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINTHW_VEC.VOFF,bx ; Save to use later
	 mov	 OLDINTHW_VEC.VSEG,es

	 REGREST <es,bx>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it
SRCH_BCFINT_XINT:

; If debugging BCF, display current interrupt here

	 test	 DB3_FLAG,@DB3_BCF	; Debugging BCF?
	 jz	 short SRCH_BCFINT_XDBG ; Nope

	 REGSAVE <ax,si,ds>	; Save for a moment

	 push	 seg PGROUP	; Get data segment (needed for HEXTABLE)
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ax,bx		; Get the address of interrupt vector
	 shr	 ax,2		; Convert from address to interrupt number
	 lea	 si,YGROUP:MSG_BCF_DBG1 ;
	 call	 FMT_ERR_CODE	; Format the interrupt number

	 push	 offset YGROUP:MSG_BCF_DBG ; Display debugging message
	 call	 YMSGOUT2	; Display YGROUP message

	 REGREST <ds,si,ax>	; Restore
	 assume  ds:XGROUP	; tell the assembler about it
SRCH_BCFINT_XDBG:
	 call	 XGROUP:[si].BCFINT_FIND ; Take appropriate action
	 jc	 short SRCH_BCFINT_ERR ; Jump if we didn't find it

	 btr	 CPQ_FLAG,$CPQ_TRIPERR ; Did we trip on the trip?
	 jc	 short SRCH_BCFINT_ERR ; Jump if we tripped

	 mov	 eax,CPQINT01_SAVE ; EAX ==> saved interrupt vector
	 mov	 XGROUP:[si].BCFINT_VEC,eax ; Save for later use

	 call	 SRCH_BCFINT_GETLIN ; Get linear address of BCFINT_VEC...
				    ; and set XGROUP:[si].BCFLIN_ADR to it..
				    ; and return linear address in EBX

	 call	 SRCH_BCFCHKDUBL ; Check for redundant entries in BCFINTS

SRCH_BCFINT_LOOP:

	 add	 si,size BCFINT_STR ; Skip to next entry

;;;;;;;  loop	 SRCH_BCFINT_NEXT ; Jump if more BCF interrupts to search
	 dec	 cx		; Adjust loop counter
	 jnz	 near ptr SRCH_BCFINT_NEXT ; Jump if more BCF interrupts to search

	 clc			; Indicate all went well

	 jmp	 short SRCH_BCFINT_EXIT ; Join common exit code

SRCH_BCFINT_ERR:
	 test	 CMD_FLAG,@CMD_FORCEBCF ; Ignore BCF error?
	 jnz	 short SRCH_BCFINT_LOOP ; Jump if so

	 REGSAVE <di,es>	; Save for a moment

	 push	 seg YGROUP	; Get data segment
	 pop	 es		; Address it
	 assume  es:YGROUP	; Tell the assembler about it

	 mov	 ax,bx		; Get the offset in segment 0
	 lea	 di,YGROUP:MSG_BCF_INT1 ; ES:DI ==> output save area
	 mov	 cx,16		; Convert in hexadecimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

	 REGREST <es,di>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 stc			; Indicate something went wrong
SRCH_BCFINT_EXIT:

; Restore original INT 29h handler

	 push	 seg XGROUP	; Get the segment
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 pushf			; Save for a moment

	 mov	 al,29h 	; Restore this one
	 lds	 dx,CPQINT29_VEC ; DS:DX ==> original handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT	; Install our own one

	 popf			; Restore

	 REGREST <gs,ds,si,cx,bx,eax> ; Restore
	 assume  gs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCH_BCFINT endp		; End SRCH_BCFINT procedure
	 NPPROC  CALC_CRC -- Calculate The CRC
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Calculate CRC.

On exit:

AX	 =	 computed CRC

|

CRC_STR  struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
CRC_CNT  dd	 ?		; Size in bytes
CRC_ADR  dd	 ?		; Segment in paras
CRC_ACC  dw	 ?		; Accumulator seed

CRC_STR  ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ebx,ecx,dx,si,ds> ; Save registers

	 mov	 ds,[bp].CRC_ADR.VSEG ; Get the segment to check
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 dx,[bp].CRC_ACC ; Get accumulated CRC
	 mov	 si,[bp].CRC_ADR.VOFF ; DS:SI ==> memory to CRC
CALC_CRC_NEXTSEG:
	 mov	 ecx,[bp].CRC_CNT ; Get the size in bytes

	 cmp	 ecx,CON64KB	; Check against maximum
	 jbe	 short CALC_CRC_NEXT ; Jump if it's within range

	 xor	 cx,cx		; Use full range
CALC_CRC_NEXT:
	 lodsb			; Get next byte

	 xor	 dl,al		; XOR into low-order byte of accumulated CRC
	 movzx	 ebx,dl 	; Copy to index register, zero high-order bytes
	 movzx	 dx,dh		; Shift down one byte, zero high-order byte
	 xor	 dx,XORLIST[ebx*(type XORLIST)] ; Compute polynomial residue

	 loop	 CALC_CRC_NEXT	; Jump if more bytes in this 64KB segment

	 mov	 ecx,CON64KB	; Get one segment's worth

	 sub	 [bp].CRC_CNT,ecx ; Less that amount
	 jbe	 short CALC_CRC_EXIT ; Jump if no more

	 mov	 ax,ds		; Copy current segment
	 add	 ax,1000h	; Skip to next 64KB
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 CALC_CRC_NEXTSEG ; Go around again

CALC_CRC_EXIT:
	 mov	 ax,dx		; Copy to result register

	 REGREST <ds,si,dx,ecx,ebx> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 4+4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_CRC endp			; End CALC_CRC procedure
	 NPPROC  CALC_SUM -- Calculate The Checksum
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Calculate Checksum.

On exit:

AX	 =	 computed SUM

|

SUM_STR  struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
SUM_CNT  dd	 ?		; Size in bytes
SUM_ADR  dd	 ?		; Segment in paras
SUM_ACC  dw	 ?		; Accumulator seed

SUM_STR  ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ebx,ecx,dx,si,ds> ; Save registers

	 mov	 ds,[bp].SUM_ADR.VSEG ; Get the segment to check
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 si,[bp].SUM_ADR.VOFF ; DS:SI ==> memory to SUM
	 mov	 dx,[bp].SUM_ACC ; Get accumulated SUM
CALC_SUM_NEXTSEG:
	 mov	 ecx,[bp].SUM_CNT ; Get the size in bytes

	 cmp	 ecx,CON64KB	; Check against maximum
	 jbe	 short CALC_SUM_NEXT ; Jump if it's within range

	 xor	 cx,cx		; Use full range
CALC_SUM_NEXT:
	 add	 dl,[si]	; Get next value
	 adc	 dh,0		;

	 inc	 si		; Bump index
	 loop	 CALC_SUM_NEXT	; Jump if more bytes in this 64KB segment

	 mov	 ecx,CON64KB	; Get one segment's worth

	 sub	 [bp].SUM_CNT,ecx ; Less that amount
	 jbe	 short CALC_SUM_EXIT ; Jump if no more

	 mov	 ax,ds		; Copy current segment
	 add	 ax,1000h	; Skip to next 64KB
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 CALC_SUM_NEXTSEG ; Go around again

CALC_SUM_EXIT:
	 mov	 ax,dx		; Copy to result register

	 REGREST <ds,si,dx,ecx,ebx> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 4+4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_SUM endp			; End CALC_SUM procedure
	 FPPROC  PROC_BCF -- Process A BCF File
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Process a BCF file.

On entry:

ES:0	 ==>	 low memory save area

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers
	 REGSAVE <fs,gs>	; Save segment registers

	 mov	 MIVT_VEC.FOFF,0 ; Zero initial offset
	 mov	 ax,MAPSEG_NXT	; Get next available segment
	 mov	 MIVT_VEC.FSEL,ax ; Save as MIVT segment

	 mov	 fs,BCF_SEG	; Get BCF segment
	 assume  fs:nothing	; Tell the assembler about it

; Clear the slack area in the start of the first 4KB block

	 mov	 cx,fs:[0].BCFH_BOFF ; Get starting offset as count in bytes
	 and	 cx,4096-1	; Isolate count modulo 4KB
	 xor	 di,di		; ES:DI ==> low memory

	 push	 cx		; Save for a moment

	 shr	 cx,2-0 	; Convert from bytes to dwords
	 mov	 eax,XAM863	; Initial value
     rep stosd			; Clear the initial area

	 pop	 cx		; Restore

	 and	 cx,4-1 	; Isolate count modulo 4
	 lea	 si,XAM863	; DS:SI ==> trailing text
S16  rep movsb			; Copy to slack area

; Compute the distance from the start of the pseudo-F000 segment

	 mov	 di,fs:[0].BCFH_BOFF ; ES:DI ==> starting offset in bytes
	 and	 di,4096-1	; Isolate offset modulo 4KB

	 mov	 edx,BCF_BIOSSIZE ; Get the size of the BIOS in bytes
				; (as a multiple of 4KB)
	 sub	 edx,CON64KB	; Subtract from 64KB to get offset
	 neg	 edx		; Negate to get positive value

	 mov	 cx,fs:[0].BCFH_NCELL ; Get the # command cells
	 mov	 si,fs:[0].BCFH_SIZE ; FS:SI ==> starting address

PROC_BCF_NEXT:
	 movzx	 eax,fs:[si].BCF_CMD ; Get command byte

	 cmp	 al,PROC_BCFTABLEN ; Ensure valid
	 jae	 near ptr PROC_BCF_CMDERR ; Jump if not

	 jmp	 PROC_BCFTAB[eax*2] ; Take appropriate action
;;;;;;;;
; Ignore MIVTx entries
;;;;;;;;
;;;;_BCF_MIVT1:
;;;;_BCF_MIVT2:
;;;;;;;; mov	 ax,fs:[si].BCF_ICNT ; Get # triples
;;;;;;;; imul	 ax,3*2 	; Convert from # triples to bytes
;;;;;;;; add	 si,ax		; Skip over triples in MIVT
;;;;;;;;
;;;;;;;; jmp	 short PROC_BCF_LOOP ; Join common loop code
;;;;;;;;
PROC_BCF_EMOV:
	 mov	 ax,0E000h	; Source is E000

	 jmp	 short @F	; Join common code

PROC_BCF_FMOV:
	 mov	 ax,0F000h	; Source is F000
@@:
	 REGSAVE <cx,esi>	; Save registers

	 mov	 cx,fs:[si].BCF_DATA ; Get move length
	 movzx	 esi,fs:[si].BCF_OFF ; Get source offset
	 call	 MOVE_SUB	; Process MOVE command

	 REGREST <esi,cx>	; Restore registers

	 jmp	 near ptr PROC_BCF_LOOP ; Join common loop code

PROC_BCF_ADDW:
	 mov	 ax,fs:[si].BCF_DATA ; Get the word to add
	 mov	 bx,fs:[si].BCF_OFF ; Get new BIOS offset
	 sub	 bx,dx		; Less starting offset
	 add	 es:[bx],ax	; Add it in

	 jmp	 short PROC_BCF_LOOP ; Join common loop code

PROC_BCF_ADDB:
	 mov	 al,fs:[si].BCF_DATA.LO ; Get the byte to add
	 mov	 bx,fs:[si].BCF_OFF ; Get new BIOS offset
	 sub	 bx,dx		; Less starting offset
	 add	 es:[bx],al	; Add it in

;;;;;;;; jmp	 short PROC_BCF_LOOP ; Join common loop code

PROC_BCF_EMOVB:
PROC_BCF_FMOVB:

; There's really nothing to do with BASIC

	 jmp	 short PROC_BCF_LOOP ; Join common loop code

PROC_BCF_EMVM:
	 mov	 ax,0E000h	; Source is E000

	 jmp	 short @F	; Join common move code

PROC_BCF_FMVM:
	 mov	 ax,0F000h	; Source is F000
@@:

	 REGSAVE <cx>		; Save command cell count

	 mov	 cx,fs:[si].BCF_MML ; Get multiple entry count
	 add	 si,size BCF_MMCSTR ; Point to next structure element
@@:
	 REGSAVE <cx,esi>	; Save registers

	 mov	 cx,fs:[si].BCF_MLN ; Get BCF_MLN length of data
	 movzx	 esi,fs:[si].BCF_MOF ; Get BCF_MOF offset of data

	 call	 MOVE_SUB	; Process MOVE command

	 REGREST <esi,cx>	; Restore registers

	 add	 si,size BCF_MMDSTR ; Point to next structure
	 loop	 @B		; Next move entry

	 REGREST <cx>		; Restore command cell count

	 jmp	 short PROC_BCF_LOOP_VER1 ; Join common loop code

PROC_BCF_ADMW:
	 REGSAVE <cx>		; Save command cell count

	 movzx	 cx,fs:[si].BCF_AMWN ; Get multiple entry count
	 mov	 ax,fs:[si].BCF_AMWV ; Get the word to add
	 add	 si,size BCF_AMWSTR ; Point to first offset value

@@:
	 mov	 bx,fs:[si]	; Get new BIOS offset
	 sub	 bx,dx		; Less starting offset
	 add	 es:[bx],ax	; Add it in
	 add	 si,2		; Next fixup offset

	 loop	 @B		; Next word fixup

	 REGREST <cx>		; Restore command cell count

	 jmp	 short PROC_BCF_LOOP_VER1 ; Join common loop code

PROC_BCF_ADMB:
	 REGSAVE <cx>		; Save command cell count

	 movzx	 cx,fs:[si].BCF_AMBN ; Get multiple entry count
	 mov	 al,fs:[si].BCF_AMBV ; Get the byte to add
	 add	 si,size BCF_AMBSTR ; Point to first offset value

@@:
	 mov	 bx,fs:[si]	; Get new BIOS offset
	 sub	 bx,dx		; Less starting offset
	 add	 es:[bx],al	; Add it in
	 add	 si,2		; Next fixup offset

	 loop	 @B		; Next word fixup

	 REGREST <cx>		; Restore command cell count

	 jmp	 short PROC_BCF_LOOP_VER1 ; Join common loop code


PROC_BCF_LOOP:
	 add	 si,type BCF_CSTR ; Skip to next entry

PROC_BCF_LOOP_VER1:
	 dec	 cx		; Count one more command cell processed
	 jnz	 near ptr PROC_BCF_NEXT ; Jump if more command cells

; Append pseudo-entry to end of MIVT

;;;;;;;; mov	 ebx,MIVT_VEC.FOFF ; Get current offset
;;;;;;;; mov	 gs:[ebx].MIVT_OLD,1024*1024 ; Mark old entry as 1MB
;;;;;;;; add	 ebx,type MIVT_STR ; Skip to next entry

; Protect MIVT structure

	 mov	 ebx,MIVT_VEC.FOFF ; Get current offset
	 add	 ebx,16-1	; Round up to para boundary
	 shr	 ebx,4-0	; Convert from bytes to paras
	 add	 MAPSEG_NXT,bx	; Skip over it

	 clc			; Indicate all went well

	 jmp	 short PROC_BCF_EXIT ; Join common exit code

PROC_BCF_CMDERR:
	 stc			; Indicate something went wrong
PROC_BCF_EXIT:
	 REGREST <gs,fs>	; Restore
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PROC_BCF endp			; End PROC_BCF procedure
	 NPPROC  MOVE_SUB -- Subroutine for MOVE command
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT |

Subroutine to process MOVE BCF commands
Updates the MIVT structure for Protected Mode vector relocation

On entry:
AX	=	BIOS segment (E000 or F000)
CX	=	Byte length of move
DX	=	Offset in bytes of new BIOS relative to F000
ESI	=	Offset into source BIOS
ES:DI	=	Next location in new BIOS that is being created

|

	 REGSAVE <ax,ds,gs>	; Save registers

	 push	 ax		; Save BIOS segment

	 movzx	 eax,ax 	; Zero to use as dword
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 eax,esi	; Add to get 32-bit old offset

; Get Normalized address into GS:BX

	 movzx	 ebx,MIVT_VEC.FSEL ; Get the segment of MIVT
	 shl	 ebx,4-0	; Convert paras -> bytes
	 add	 ebx,MIVT_VEC.FOFF ; Combine 32-bit linear address of the
				; current offset
	 ror	 ebx,4-0	; Move Paras to interesting location
	 mov	 gs,bx		; Address normalize segment
	 rol	 ebx,4-0	; Put byte back
	 and	 bx,@NIB0	; Trim off values just put into segment

	 mov	 gs:[bx].MIVT_OLD,eax ; Save as old offset
	 mov	 gs:[bx].MIVT_NEW,di ; ...	new ...
	 mov	 gs:[bx].MIVT_LEN,cx ; ...	length
	 add	 gs:[bx].MIVT_NEW,dx ; Add into new offset
	 add	 MIVT_VEC.FOFF,type MIVT_STR ; Skip to next entry

	 pop	 ds		; Address the BIOS
	 assume  ds:nothing	; Tell the assembler about it

S16  rep movsb			; Copy source data to destin

	 REGREST <gs,ds,ax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MOVE_SUB endp			; End MOVE_SUB procedure
	 FPPROC  FINDROMCHK -- Find The Owner Of INTs not in ROM below E000
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of an INT not in ROM below E000.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax>		 ; Save register

	 mov	 ax,OLDINTHW_VEC.VSEG ; Get segment of routine to execute

	 cmp	 ax,0E000h	; Izit in our system ROM?
	 jae	 short @F	; Jump if so

	 cmp	 ax,0C000h	; Izit at or above lowest possible ROM?
	 jae	 short FINDROMCHK1 ; Jump if so (skip FINDCHK) (note CF=0)
@@:
	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0
FINDROMCHK1:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDROMCHK endp 		; End FINDROMCHK procedure
	 FPPROC  FIND10 -- Find The Owner Of INT 10h/6Dh
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of INT 10h/6Dh.

On entry:

All registers may be significant.
OLDINTHW_VEC contains address of routine to execute.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax>		 ; Save register

	 mov	 ah,@GETINF	; Code to get video information
	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND10	 endp			; End FIND10 procedure
	 FPPROC  FIND75 -- Find The Owner Of INT 75h
	 assume  ds:XGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of INT 75h.

On entry:

All registers may be significant.
OLDINTHW_VEC contains address of routine to execute.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax>		 ; Save register

	 mov	 ax,OLDINTHW_VEC.VSEG ; Get segment of routine to execute

	 cmp	 ax,0E000h	; Izit in our system ROM?
	 jae	 short FIND75_CHK ; Jump if so

	 cmp	 ax,0C000h	; Izit at or above lowest possible ROM?
	 jae	 short FIND75_EXIT ; Jump if so (skip FINDCHK) (note CF=0)

; If there's no NDP in the system, skip this routine
; as it might point to code (such as in an AOX context)
; where they assume that this interrupt is called only
; if an NDP is present.

	 test	 LCL_FLAG,@LCL_NDPIN ; Izit installed?
	 jz	 short FIND75_EXIT ; Jump if so (skip FINDCHK) (note CF=0)
FIND75_CHK:
	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0
FIND75_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND75	 endp			; End FIND75 procedure

XCODE	 ends			; End XCODE segment
endif				; IF @OEM_BCF

	 MEND			; End QMAX_BCF module

