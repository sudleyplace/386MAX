;' $Header:   P:/PVCS/MAX/386MAX/UTIL_ROM.ASV   1.3   08 Jul 1998 11:44:04   BOB  $
	 title	 UTIL_ROM -- 386MAX Utility Program -- ROMSCAN Action
	 page	 58,122
	 name	 UTIL_ROM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Program segment UCODE,	byte-aligned,  public, class 'ucode'
	       Tail    segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Program derived from:  None.

Original code by:  Bob Smith, April, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include ASCII.INC
	 include BIOSCONF.INC
	 include ROMSEG.INC
	 include 386.INC
	 include PTR.INC
	 include EMM2CALL.INC
	 include VIDCALL.INC
	 include EMMCALL.INC

	 include QMAX_OEM.INC
	 include QMAX_FLX.INC
	 include QMAX_FMT.INC
	 include QMAX_MCS.INC
	 include QMAX_RAM.INC
.list

if @OEM_ROMSCAN
PGROUP	 group	 CODE,DATA,NCODE,UCODE,ZZTAIL

DD2DEC_MAC macro MSG

	 mov	 di,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 di		; Pass as argument
	 lea	 di,MSG 	; ES:DI ==> output save area
	 call	 DD2DEC 	; Convert (DX,AX) to decimal ending at ES:DI

	 endm			; DD2DEC_MAC


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 INFO_CTL:byte
	 include QMAX_CTL.INC

if @OEM_WIN3
	 extrn	 MSG_WINERR:byte
	 extrn	 WINRUN:byte
endif				; IF @OEM_WIN3

	 extrn	 PORT67:word
	 extrn	 SYSROM_START:word

	 extrn	 PMCSTAB:word,MCSTAB_CNT:word

; The following data values area used instead of constants
; to avoid phantom matches due to "bus capacitance".
; Thanks to Bill Kreuger of Intel for pointing out this problem.

	 public  DROMSIGN
@ROMOFF  equ	 1234h
DROMSIGN dw	 @ROMSIGN-@ROMOFF  ; Data value of @ROMSIGN

if @OEM_FLEXROM
	 public  FLEXROM_FLAG
FLEXROM_FLAG dw  ?		; FLEXROM flags (see QMAX_FLX.INC for equates)
endif				; IF @OEM_FLEXROM

	 public  LCLSYSROM_START
LCLSYSROM_START dd 0		; Local copy of starting segment of system ROM

	 public  PCMPTAB,PRAMTAB,PEXTADDR,ENTRYCNT,OLDGLB
PCMPTAB  dw	 ?		; Pointer to compressed RAM/ROM table (4KB)
PRAMTAB  dw	 ?		; ...	     RAM/ROM table	      (512B)
PEXTADDR dw	 ?		; ...	     EXTADDR_STR structure
ENTRYCNT dw	 ?		; # entries in EXTADDR_STR structure
OLDGLB	 dw	 ?		; Old GLB_FLAG

	public	PRAMTABZ
PRAMTABZ dw	 ?		; Pointer to end of RAM/ROM table

	 public  SCNSIZE_VID, SCNSIZE_RAM, SCNSIZE_ROM, SCNSIZE_OTH
	 public  SCNSIZE_EMSM,SCNSIZE_OVR, SCNSIZE_TOT
SCNSIZE_VID  dw  0		; Total amount of video RAM
SCNSIZE_RAM  dw  0		; ...		  RAM
SCNSIZE_ROM  dw  0		; ...		  ROM
SCNSIZE_OTH  dw  0		; ...		  unused memory
SCNSIZE_EMSM dw  0		; ...		  EMS-mappable memory
SCNSIZE_OVR  dw  0		; ...		  high DOS memory
SCNSIZE_TOT  dw  ?		; Total amount of all high DOS memory

	 public  SCNPCT_VID, SCNPCT_RAM, SCNPCT_ROM
	 public  SCNPCT_OTH, SCNPCT_EMSM,SCNPCT_OVR
SCNPCT_VID  dw	 ?		; Percentage of video RAM
SCNPCT_RAM  dw	 ?		; ...		RAM
SCNPCT_ROM  dw	 ?		; ...		ROM
SCNPCT_OTH  dw	 ?		; ...		unused memory
SCNPCT_EMSM dw	 ?		; ...		EMS-mappable memory
SCNPCT_OVR  dw	 ?		; ...		high DOS memory

	 public  SCNACCUM_HMA,	SCNACCUM_EXTUP,SCNACCUM_EXTMD
	 public  SCNACCUM_EXTDN,SCNACCUM_XMS,  SCNACCUM_EMS
	 public  SCNACCUM_VCPI, SCNACCUM_DPMI, SCNACCUM_ABS
	 public  SCNACCUM_PRG,	SCNACCUM_AVL,  SCNACCUM_UNK
SCNACCUM_HMA   dd 0		; Size in 1KB of HMA
SCNACCUM_EXTUP dd 0		; ...		 bottom up extended memory
SCNACCUM_EXTMD dd 0		; ...		 middle out extended memory
SCNACCUM_EXTDN dd 0		; ...		 top down extended memory
SCNACCUM_XMS   dd 0		; ...		 allocated XMS memory
SCNACCUM_EMS   dd 0		; ...		 allocated EMS memory
SCNACCUM_VCPI  dd 0		; ...		 allocated VCPI memory
SCNACCUM_DPMI  dd 0		; ...		 allocated DPMI memory
SCNACCUM_ABS   dd 0		; ...		 remapped memory
SCNACCUM_PRG   dd 0		; ...		 program storage
SCNACCUM_AVL   dd 0		; ...		 unallocated memory
SCNACCUM_UNK   dd 0		; ...		 unknown memory

	 public  SCNACCUM		; In same order as @EXTADDRTYPE_xxx
SCNACCUM dw	 PGROUP:SCNACCUM_HMA	;  0 = HMA
	 dw	 PGROUP:SCNACCUM_EXTUP	;  1 = Extended memory bottom up
	 dw	 PGROUP:SCNACCUM_EXTMD	;  2 = Extended memory middle out
	 dw	 PGROUP:SCNACCUM_EXTDN	;  3 = Extended memory top down
	 dw	 PGROUP:SCNACCUM_XMS	;  4 = XMS memory
	 dw	 PGROUP:SCNACCUM_EMS	;  5 = EMS memory
	 dw	 PGROUP:SCNACCUM_DPMI	;  6 = DPMI memory
	 dw	 PGROUP:SCNACCUM_ABS	;  7 = Remapped memory
	 dw	 PGROUP:SCNACCUM_ABS	;  8 = Low DOS memory fill
	 dw	 PGROUP:SCNACCUM_ABS	;  9 = High DOS memory fill
	 dw	 PGROUP:SCNACCUM_ABS	; 10 = ROM fill
	 dw	 PGROUP:SCNACCUM_PRG	; 11 = Program storage
	 dw	 PGROUP:SCNACCUM_UNK	; 12 = DMA buffer
	 dw	 PGROUP:SCNACCUM_UNK	; 13 = AMRS page tables
	 dw	 PGROUP:SCNACCUM_UNK	; 14 = Page Table level 1
	 dw	 PGROUP:SCNACCUM_UNK	; 15 = Page Table level 2
	 dw	 PGROUP:SCNACCUM_UNK	; 16 = IGROUP code/data
	 dw	 PGROUP:SCNACCUM_UNK	; 17 = TSSs
	 dw	 PGROUP:SCNACCUM_UNK	; 18 = I/O Bit Permission Map
	 dw	 PGROUP:SCNACCUM_DPMI	; 19 = DPMI memory handle table
	 dw	 PGROUP:SCNACCUM_DPMI	; 20 = LDT
	 dw	 PGROUP:SCNACCUM_UNK	; 21 = Unused part of LPM
	 dw	 PGROUP:SCNACCUM_UNK	; 22 = DPMI Page Directories
	 dw	 PGROUP:SCNACCUM_UNK	; 23 = Load module
	 dw	 PGROUP:SCNACCUM_UNK	; 24 = Windows 3 Paging Import Data
	 dw	 PGROUP:SCNACCUM_UNK	; 25 = Windows 3 UMB Instance Data
	 dw	 PGROUP:SCNACCUM_UNK	; 26 = Windows 3 Configuration File
	 dw	 PGROUP:SCNACCUM_UNK	; 27 = Stack
	 dw	 PGROUP:SCNACCUM_UNK	; 28 = EMS 16-bit Tables
	 dw	 PGROUP:SCNACCUM_UNK	; 29 = I/O Check Tables
	 dw	 PGROUP:SCNACCUM_UNK	; 30 = EMS 32-bit Tables
	 dw	 PGROUP:SCNACCUM_UNK	; 31 = XMS 32-bit Tables
	 dw	 PGROUP:SCNACCUM_UNK	; 32 = Static code/data
	 dw	 PGROUP:SCNACCUM_AVL	; 33 = Unallocated
	 dw	 PGROUP:SCNACCUM_UNK	; 34 = Periscope memory
	 dw	 PGROUP:SCNACCUM_DPMI	; 35 = DPMI old PM save area
	 dw	 PGROUP:SCNACCUM_DPMI	; 36 = DPMI dynamic save area
	 dw	 PGROUP:SCNACCUM_UNK	; 37 = Previous VDS table
	 dw	 PGROUP:SCNACCUM_UNK	; 38 = Used part of LPM
	 dw	 PGROUP:SCNACCUM_UNK	; 39 = FGROUP code/data
	 dw	 PGROUP:SCNACCUM_UNK	; 40 = JGROUP & DL2GROUP code/data
	 dw	 PGROUP:SCNACCUM_UNK	; 41 = Backing Store cache
	 dw	 PGROUP:SCNACCUM_UNK	; 42 = I/O trapping strucs

	 public  SCNTYPE		; In same order as @EXTADDRTYPE_xxx
SCNTYPE  dw	 PGROUP:SCNTYPE_HMA	;  0 = HMA
	 dw	 PGROUP:SCNTYPE_EXTUP	;  1 = Extended memory bottom up
	 dw	 PGROUP:SCNTYPE_EXTMD	;  2 = Extended memory middle out
	 dw	 PGROUP:SCNTYPE_EXTDN	;  3 = Extended memory top down
	 dw	 PGROUP:SCNTYPE_XMS	;  4 = XMS memory
	 dw	 PGROUP:SCNTYPE_EMS	;  5 = EMS memory
	 dw	 PGROUP:SCNTYPE_DPMI	;  6 = DPMI memory
	 dw	 PGROUP:SCNTYPE_ABS	;  7 = Remapped memory
	 dw	 PGROUP:SCNTYPE_LOWF	;  8 = Low DOS memory fill
	 dw	 PGROUP:SCNTYPE_OVRF	;  9 = High DOS memory fill
	 dw	 PGROUP:SCNTYPE_ROMF	; 10 = ROM fill
	 dw	 PGROUP:SCNTYPE_PRG	; 11 = Program storage
	 dw	 PGROUP:SCNTYPE_DMA	; 12 = DMA buffer
	 dw	 PGROUP:SCNTYPE_AMRS	; 13 = AMRS page tables
	 dw	 PGROUP:SCNTYPE_PT1	; 14 = Page Table level 1
	 dw	 PGROUP:SCNTYPE_PT2	; 15 = Page Table level 2
	 dw	 PGROUP:SCNTYPE_IGR	; 16 = IGROUP code/data
	 dw	 PGROUP:SCNTYPE_TSS	; 17 = TSSs
	 dw	 PGROUP:SCNTYPE_IOBIT	; 18 = I/O Bit Permission Map
	 dw	 PGROUP:SCNTYPE_DHNDL	; 19 = DPMI memory handle table
	 dw	 PGROUP:SCNTYPE_LDT	; 20 = LDT
	 dw	 PGROUP:SCNTYPE_LPMLO	; 21 = Unused part of LPM
	 dw	 PGROUP:SCNTYPE_DPDIR	; 22 = DPMI Page Directories
	 dw	 PGROUP:SCNTYPE_LOAD	; 23 = Load module
	 dw	 PGROUP:SCNTYPE_WIN3	; 24 = Windows 3 Paging Import Data
	 dw	 PGROUP:SCNTYPE_INST	; 25 = Windows 3 UMB Instance Data
	 dw	 PGROUP:SCNTYPE_CFG	; 26 = Windows 3 Configuration File
	 dw	 PGROUP:SCNTYPE_STK	; 27 = Stack
	 dw	 PGROUP:SCNTYPE_EMS16	; 28 = EMS 16-bit Tables
	 dw	 PGROUP:SCNTYPE_IOCHK	; 29 = I/O Check Tables
	 dw	 PGROUP:SCNTYPE_EMS32	; 30 = EMS 32-bit Tables
	 dw	 PGROUP:SCNTYPE_XMS32	; 31 = XMS 32-bit Tables
	 dw	 PGROUP:SCNTYPE_MAX	; 32 = Static code/data
	 dw	 PGROUP:SCNTYPE_AVL	; 33 = Unallocated
	 dw	 PGROUP:SCNTYPE_PSM	; 34 = Periscope memory
	 dw	 PGROUP:SCNTYPE_DPOPM	; 35 = DPMI old PM save area
	 dw	 PGROUP:SCNTYPE_DPDYN	; 36 = DPMI dynamic save area
	 dw	 PGROUP:SCNTYPE_VDS	; 37 = Previous VDS table
	 dw	 PGROUP:SCNTYPE_LPMHI	; 38 = Used part of LPM
	 dw	 PGROUP:SCNTYPE_FGR	; 39 = FGROUP code/data
	 dw	 PGROUP:SCNTYPE_JGR	; 40 = JGROUP & DL2GROUP code/data
	 dw	 PGROUP:SCNTYPE_BSC	; 41 = Backing Store cache
	 dw	 PGROUP:SCNTYPE_IOTRP	; 42 = I/O trapping strucs

	 public  SCNTYPE_LOW,  SCNTYPE_VID,  SCNTYPE_RAM,  SCNTYPE_ROM
	 public  SCNTYPE_OVR,  SCNTYPE_EMSM, SCNTYPE_OTH,  SCNTYPE_HMA
	 public  SCNTYPE_EXTUP,SCNTYPE_EXTDN,SCNTYPE_XMS,  SCNTYPE_EMS,
	 public  SCNTYPE_VCPI, SCNTYPE_DPMI, SCNTYPE_ABS,  SCNTYPE_PRG
	 public  SCNTYPE_LOWF, SCNTYPE_OVRF, SCNTYPE_ROMF
	 public  SCNTYPE_DMA,  SCNTYPE_AMRS, SCNTYPE_PT1,  SCNTYPE_PT2
	 public  SCNTYPE_IGR,  SCNTYPE_TSS,  SCNTYPE_IOBIT,SCNTYPE_DHNDL
	 public  SCNTYPE_LDT,  SCNTYPE_LPMLO,SCNTYPE_DPDIR,SCNTYPE_LOAD
	 public  SCNTYPE_WIN3, SCNTYPE_INST, SCNTYPE_CFG,  SCNTYPE_STK
	 public  SCNTYPE_EMS16,SCNTYPE_IOCHK,SCNTYPE_EMS32,SCNTYPE_XMS32
	 public  SCNTYPE_MAX,  SCNTYPE_AVL,  SCNTYPE_LPMHI
	 public  SCNTYPE_FGR,  SCNTYPE_JGR,  SCNTYPE_BSC,  SCNTYPE_IOTRP
ifdef LANG_GR
SCNTYPE_LOW  db  '        LoDOS'
else
SCNTYPE_LOW  db  '      Low DOS'
endif				; IFDEF LANG_GR
SCNTYPE_LEN equ  $-SCNTYPE_LOW	; Length of typical type
SCNTYPE_VID  db  '    Video RAM'
SCNTYPE_RAM  db  '          RAM'
SCNTYPE_ROM  db  '          ROM'
ifdef LANG_GR
SCNTYPE_OVR  db  'HiDOS Bereich'
SCNTYPE_EMSM db  'EMS abbildbar'
SCNTYPE_OTH  db  '     unbelegt'
SCNTYPE_HMA  db  '          HMA'
SCNTYPE_EXTUP db 'EXT von unten'
SCNTYPE_EXTMD db '     EXT Rest'
SCNTYPE_EXTDN db ' EXT von oben'
else
SCNTYPE_OVR  db  ' High DOS Mem'
SCNTYPE_EMSM db  ' EMS Mappable'
SCNTYPE_OTH  db  '       Unused'
SCNTYPE_HMA  db  '          HMA'
SCNTYPE_EXTUP db 'EXT Bottom Up'
SCNTYPE_EXTMD db 'EXT Remainder'
SCNTYPE_EXTDN db ' EXT Top Down'
endif				; IFDEF LANG_GR
SCNTYPE_XMS  db  '          XMS'
SCNTYPE_EMS  db  '          EMS'
SCNTYPE_VCPI db  '         VCPI'
ifdef LANG_GR
SCNTYPE_DPMI db  'DPMI-Speicher'
SCNTYPE_ABS  db  '   abgebildet'
else
SCNTYPE_DPMI db  '  DPMI Memory'
SCNTYPE_ABS  db  '     Remapped'
endif				; IFDEF LANG_GR
@SIZE_FILE  sizestr @OEM_FILE
SCNTYPE_PRG  db  (SCNTYPE_LEN-(@SIZE_FILE-2)) dup (' '),@OEM_FILE
ifdef LANG_GR
SCNTYPE_LOWF db  ' LoDOS-Fller'
SCNTYPE_OVRF db  ' HiDOS-Fller'
SCNTYPE_ROMF db  '   ROM-Fller'
SCNTYPE_DMA  db  '   DMA-Puffer'
SCNTYPE_AMRS db  '    AMRS PDEs'
SCNTYPE_PT1  db  '          PDT'
SCNTYPE_PT2  db  '  Page-Tables'
SCNTYPE_IGR  db  '       IGROUP'
SCNTYPE_TSS  db  '         TSSs'
SCNTYPE_IOBIT db '   I/O Bitmap'
SCNTYPE_DHNDL db ' DPMI-Handles'
SCNTYPE_LDT  db  '          LDT'
SCNTYPE_LPMLO db '   Unused LPM'
SCNTYPE_DPDIR db '   DPMI PDIRs'
SCNTYPE_LOAD db  '   Lade-Modul'
SCNTYPE_WIN3 db  '  WIN3-Import'
SCNTYPE_INST db  '    WIN3-Inst'
SCNTYPE_CFG  db  '  386LOAD.CFG'
SCNTYPE_STK  db  '        Stack'
SCNTYPE_EMS16 db '   EMS 16-bit'
SCNTYPE_IOCHK db '    I/O Check'
SCNTYPE_EMS32 db '   EMS 32-bit'
SCNTYPE_XMS32 db '   XMS 32-bit'
SCNTYPE_MAX   db '   MAX Static'
SCNTYPE_AVL   db 'verfgb. dyn.'
SCNTYPE_PSM   db 'Periscop-Ber.'
SCNTYPE_DPOPM db '  DPMI Old PM'
SCNTYPE_DPDYN db '  DPMI dynam.'
SCNTYPE_VDS   db '     Prev VDS'
SCNTYPE_LPMHI db '     Used LPM'
SCNTYPE_FGR  db  '       FGROUP'
SCNTYPE_JGR  db  ' JGR/DL2GROUP'
SCNTYPE_BSC  db  '     BS Cache'
SCNTYPE_IOTRP db '     I/O Trap'
else
SCNTYPE_LOWF db  ' Low DOS Fill'
SCNTYPE_OVRF db  'High DOS Fill'
SCNTYPE_ROMF db  '     ROM Fill'
SCNTYPE_DMA  db  '   DMA Buffer'
SCNTYPE_AMRS db  '    AMRS PDEs'
SCNTYPE_PT1  db  '          PDT'
SCNTYPE_PT2  db  '  Page Tables'
SCNTYPE_IGR  db  '       IGROUP'
SCNTYPE_TSS  db  '         TSSs'
SCNTYPE_IOBIT db '   I/O Bitmap'
SCNTYPE_DHNDL db ' DPMI Handles'
SCNTYPE_LDT  db  '          LDT'
SCNTYPE_LPMLO db '   Unused LPM'
SCNTYPE_DPDIR db '   DPMI PDIRs'
SCNTYPE_LOAD db  '  Load Module'
SCNTYPE_WIN3 db  '  WIN3 Import'
SCNTYPE_INST db  '    WIN3 Inst'
SCNTYPE_CFG  db  '  386LOAD.CFG'
SCNTYPE_STK  db  '        Stack'
SCNTYPE_EMS16 db '   EMS 16-bit'
SCNTYPE_IOCHK db '    I/O Check'
SCNTYPE_EMS32 db '   EMS 32-bit'
SCNTYPE_XMS32 db '   XMS 32-bit'
SCNTYPE_MAX   db '   MAX Static'
SCNTYPE_AVL   db ' Avail Shared'
SCNTYPE_PSM   db 'Periscope Mem'
SCNTYPE_DPOPM db '  DPMI Old PM'
SCNTYPE_DPDYN db ' DPMI Dynamic'
SCNTYPE_VDS   db '     Prev VDS'
SCNTYPE_LPMHI db '     Used LPM'
SCNTYPE_FGR  db  '       FGROUP'
SCNTYPE_JGR  db  ' JGR/DL2GROUP'
SCNTYPE_BSC  db  '     BS Cache'
SCNTYPE_IOTRP db '     I/O Trap'
endif				; IFDEF LANG_GR

	 public  ROMDBG
ROMDBG	 db	 0		; Debug flag:  0 = off, 1 = on, 2 = 2nd phase

	 public  MSG_SCNHDR,MSG_SEPLINE,MSG_SCNLINE,MSG_SCNTAIL
MSG_SCNHDR db	 'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸',CR,LF
ifdef LANG_GR
	 db	 '³                          SPEICHER-ABBILD                          ³',CR,LF
else
	 db	 '³                            MEMORY SCAN                            ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ´',CR,LF
ifdef LANG_GR
	 db	 '³   Typ         ³ Handle ³  Adress-Bereich   ³ Gr”áe (KB)³   Name   ³',CR,LF
else
	 db	 '³   Type        ³ Handle ³   Address Range   ³ Size (KB) ³   Name   ³',CR,LF
endif				; IFDEF LANG_GR
MSG_SEPLINE db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄ´',CR,LF,EOS
;;;;;;;; db	 '³ EMS Mappable  ³  ____  ³ 00000000-00000000 ³   nn,nnn  ³ aaaaaaaa ³',CR,LF
MSG_LINE db	 '³               ³        ³         -         ³           ³          ³'
MSG_LINE_LEN equ $-MSG_LINE ; Length of ...
MSG_SCNLINE db	 '³ '
MSG_SCNTYPE db	 '              ³  '
MSG_SCNHNDL db	 '      ³'
MSG_SCNOVR1 db	 ' '
MSG_SCNADDR1 db  '        -'
MSG_SCNADDR2 db  '        '
MSG_SCNOVR2 db	 ' ³        '
MSG_SCNSIZE  db  '_  ³ '
MSG_SCNNAME  db  '         ³',CR,LF,EOS
MSG_SCNTAIL db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´',CR,LF
ifdef LANG_GR
	 db	 '³   û hier berlappt HiDOS den RAM- oder ROM-Bereich                ³',CR,LF
else
	 db	 '³   û means that High DOS Memory overlaps RAM or ROM                ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÆÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍµ',CR,LF
ifdef LANG_GR
	 db	 '³                      SPEICHER-GESAMTANZEIGE                       ³',CR,LF
else
	 db	 '³                          MEMORY SUMMARY                           ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF
ifdef LANG_GR
	 db	 '³      HiDOS Adress-Bereich                   Extended Memory       ³',CR,LF
	 db	 '³  ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ        ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ   ³',CR,LF
MSG_VID  db	 '³      Video RAM:   _ KB -   _ %         EXT von unten:      _ KB   ³',CR,LF
MSG_RAM  db	 '³            RAM:   _    -   _          EXT Restanteil:      _      ³',CR,LF
MSG_ROM  db	 '³            ROM:   _    -   _            EXT von oben:      _      ³',CR,LF
MSG_OTH  db	 '³      unbenutzt:   _    -   _                     HMA:      _      ³',CR,LF
MSG_EMSM db	 '³  EMS abbildbar:   _    -   _                     XMS:      _      ³',CR,LF
MSG_OVR  db	 '³  HiDOS Bereich:   _    -   _                     EMS:      _      ³',CR,LF
MSG_VCPI db	 '³                 ÄÄÄÄÄÄÄÄÄÄÄÄÄ                   VCPI:      _      ³',CR,LF
MSG_TOT  db	 '³         gesamt:   _ KB - 100 %                  DPMI:      _      ³',CR,LF
MSG_AVL  db	 '³                                     verfgbar dynam.:      _      ³',CR,LF
MSG_ABS  db	 '³                                           abgebildet:      _      ³',CR,LF
MSG_PRG  db	 '³                                       Programm-Gr”áe:             ³',CR,LF
	 db	 '³                                                        ÄÄÄÄÄÄÄÄ   ³',CR,LF
MSG_ETOT db	 '³                                               gesamt:      _ KB   ³',CR,LF
else
	 db	 '³      High DOS Address Space                 Extended Memory       ³',CR,LF
	 db	 '³   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ         ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ   ³',CR,LF
MSG_VID  db	 '³      Video RAM:   _ KB -   _ %         EXT Bottom Up:      _ KB   ³',CR,LF
MSG_RAM  db	 '³            RAM:   _    -   _           EXT Remainder:      _      ³',CR,LF
MSG_ROM  db	 '³            ROM:   _    -   _            EXT Top Down:      _      ³',CR,LF
MSG_OTH  db	 '³         Unused:   _    -   _                     HMA:      _      ³',CR,LF
MSG_EMSM db	 '³   EMS Mappable:   _    -   _                     XMS:      _      ³',CR,LF
MSG_OVR  db	 '³   High DOS Mem:   _    -   _                     EMS:      _      ³',CR,LF
MSG_VCPI db	 '³                 ÄÄÄÄÄÄÄÄÄÄÄÄÄ                   VCPI:      _      ³',CR,LF
MSG_TOT  db	 '³          Total:   _ KB - 100 %                  DPMI:      _      ³',CR,LF
MSG_AVL  db	 '³                                         Avail Shared:      _      ³',CR,LF
MSG_ABS  db	 '³                                             Remapped:      _      ³',CR,LF
MSG_PRG  db	 '³                                         Program Size              ³',CR,LF
	 db	 '³                                                        ÄÄÄÄÄÄÄÄ   ³',CR,LF
MSG_ETOT db	 '³                                                Total:      _ KB   ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾',CR,LF,EOS

@SCNSIZE_OFF equ 20		; Offset from start of line to units digit of size
@SCNPCT_OFF  equ 29		; ...					      percentage
@SCNEXT_OFF  equ 61		; ...					      extended size

MSG_SCNSIZE_VID  equ MSG_VID [@SCNSIZE_OFF]
MSG_SCNSIZE_RAM  equ MSG_RAM [@SCNSIZE_OFF]
MSG_SCNSIZE_ROM  equ MSG_ROM [@SCNSIZE_OFF]
MSG_SCNSIZE_OTH  equ MSG_OTH [@SCNSIZE_OFF]
MSG_SCNSIZE_EMSM equ MSG_EMSM[@SCNSIZE_OFF]
MSG_SCNSIZE_OVR  equ MSG_OVR [@SCNSIZE_OFF]
MSG_SCNSIZE_TOT  equ MSG_TOT [@SCNSIZE_OFF]

MSG_SCNPCT_VID	 equ MSG_VID [@SCNPCT_OFF]
MSG_SCNPCT_RAM	 equ MSG_RAM [@SCNPCT_OFF]
MSG_SCNPCT_ROM	 equ MSG_ROM [@SCNPCT_OFF]
MSG_SCNPCT_OTH	 equ MSG_OTH [@SCNPCT_OFF]
MSG_SCNPCT_EMSM  equ MSG_EMSM[@SCNPCT_OFF]
MSG_SCNPCT_OVR	 equ MSG_OVR [@SCNPCT_OFF]

MSG_SCNSIZE_EXTUP  equ MSG_VID [@SCNEXT_OFF]
MSG_SCNSIZE_EXTMD  equ MSG_RAM [@SCNEXT_OFF]
MSG_SCNSIZE_EXTDN  equ MSG_ROM [@SCNEXT_OFF]
MSG_SCNSIZE_HMA    equ MSG_OTH [@SCNEXT_OFF]
MSG_SCNSIZE_XMS    equ MSG_EMSM[@SCNEXT_OFF]
MSG_SCNSIZE_EMS    equ MSG_OVR [@SCNEXT_OFF]
MSG_SCNSIZE_VCPI   equ MSG_VCPI[@SCNEXT_OFF]
MSG_SCNSIZE_DPMI   equ MSG_TOT [@SCNEXT_OFF]
MSG_SCNSIZE_AVL    equ MSG_AVL [@SCNEXT_OFF]
MSG_SCNSIZE_ABS    equ MSG_ABS [@SCNEXT_OFF]
MSG_SCNSIZE_PRG    equ MSG_PRG [@SCNEXT_OFF]
MSG_SCNSIZE_ETOT   equ MSG_ETOT[@SCNEXT_OFF]

DATA	 ends			; End DATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

ZZTAIL	 segment use16 dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 extrn	 ZTAIL:byte

ZZTAIL	 ends			; End ZZTAIL segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 STROUT:near

NCODE	 ends			; End NCODE segment


UCODE	 segment use16 byte public 'ucode' ; Start UCODE segment
	 assume  cs:PGROUP

	 extrn	 DD2DEC:near

UCODE	 ends			; End UCODE segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 BIN2BASE:near
	 extrn	 DW2HEX:near
	 extrn	 DD2HEX:near

	 extrn	 SEND_CMD:near
	 extrn	 CHECK_STATE:near
	 extrn	 INFO_READ:near

	 NPPROC  ACT_ROMDBG -- Action To Scan for ROMs and RAM With Debugging
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	 mov	 ROMDBG,1	; Mark as debugging

;;;;;;;; jmp	 short ACT_ROM	; Join common code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_ROMDBG endp 		; End ACT_ROMDBG procedure
	 NPPROC  ACT_ROM -- Action To Scan for ROMs and RAM
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Scan for ROMs and RAM

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers
	 REGSAVE <es>		; Save segment register

if @OEM_WIN3
	 cmp	 WINRUN,1	; Are we running under Windows?
	 je	 near ptr ACT_ROM_WINERR ; Jump if so
endif				; IF @OEM_WIN3

	 mov	 ax,SYSROM_START ; Get starting segment of system ROM
	 mov	 LCLSYSROM_START.ELO,ax ; Save for later use

	 mov	 ax,GLB_FLAG	; Save current global flag
	 and	 ax,@GLB_AUTO or @GLB_ON ; Isolate flags
	 mov	 OLDGLB,ax	; Save to restore later

	 call	 CHECK_STATE	; Attempt to go ON or AUTO active
	 jc	 near ptr ACT_ROM_ERR ; Jump if not successful

; Read in MCS table

	 mov	 PMCSTAB,offset PGROUP:ZTAIL ; Initialize pointer
	 mov	 di,PMCSTAB	; ES:DI ==> output save area
	 mov	 bp,sp		; Save stack pointer
	 EMMOUT  @EMM2_GETMCS	; Get memory chain structure, # entries in CX
				; Return error code in AH
	 mov	 sp,bp		; Restore

	 and	 ah,ah		; Check return code
	 jnz	 near ptr ACT_ROM_ERR ; Jump if something went wrong

	 mov	 MCSTAB_CNT,cx	; Save for later use

	 mov	 ax,size MCS_STR ; Get size of structure
	 mul	 cx		; Times # entries
	 add	 ax,PMCSTAB	; Plus start of MCSTAB
	 mov	 PCMPTAB,ax	; Save as start of compressed RAMTAB

	 mov	 di,PCMPTAB	; ES:DI ==> output save area
	 mov	 bp,sp		; Save stack pointer
	 EMMOUT  @EMM2_RAMSCAN	; Request RAM scan of high DOS memory
				; Return with AH = error status

	 mov	 sp,bp		; Restore

	 and	 ah,ah		; Check return code
	 jnz	 near ptr ACT_ROM_ERR ; Jump if something went wrong

if @OEM_FLEXROM

; Get FLEXROM flags

	 mov	 bp,sp		; Save stack pointer
	 EMMOUT  @EMM2_FLEXINFO ; Get FLEXROM info
				; Return with
				; EDX = Physical address of FlexROM table (for VxD)
				; CX  = # of entries in FlexROM table
				; BX  = FLEXROM_FLAG
	 mov	 sp,bp		; Restore

	 and	 ah,ah		; Check return code
	 jnz	 near ptr ACT_ROM_ERR ; Jump if something went wrong

	 mov	 FLEXROM_FLAG,bx ; Save for later use
endif				; IF @OEM_FLEXROM

; Expand the bytes at PCMPTAB from 4KB to 512-byte

	 mov	 si,PCMPTAB	; DS:SI ==> RAM scan values
	 lea	 di,[si+384/4]	; ES:DI ==> next available byte
	 mov	 PRAMTAB,di	; Save for later use
	 mov	 cx,384/4	; CX = # RAM scan bytes
RAMSCAN_NEXT:
	 lodsb			; Get next byte

	 push	 cx		; Save for a moment
	 mov	 cx,4*1024/512	; Expansion factor from 4KB to 512-byte
     rep stosb			; Save in expanded form
	 pop	 cx		; Restore

	 loop	 RAMSCAN_NEXT	; Jump if more bytes in RAM scan table

	mov	PRAMTABZ,di	; Save as ending pointer

@RAM_END equ	 -1		; Ending marker

	 mov	 al,@RAM_END	; Ending marker
S16	 stosb			; Save at end of table

; Read in EXTADDR_STR structure

	 mov	 PEXTADDR,di	; Save for later use
	 mov	 bp,sp		; Save stack pointer
	 mov	 al,ROMDBG	; Get debugging state
	 EMMOUT  @EMM2_EXTADDR	; Request extenbded memory addresses into ES:DI
				; Return with AH = error status and
				; CX = # structure entries filled in
	 mov	 sp,bp		; Restore

	 and	 ah,ah		; Check return code
	 jnz	 near ptr ACT_ROM_ERR ; Jump if something went wrong

	 mov	 ENTRYCNT,cx	; Save for later use

; Return to the previous state in OLDGLB

	 test	 OLDGLB,@GLB_ON ; Were we ON before?
	 jnz	 short @F	; Yes, stay that way

	 call	 INFO_READ	; Read in INFO structure
				; to get current GLB_FLAG

	 mov	 INFO_CTL,@CTL_OFF ; Mark as state OFF
	 call	 SEND_CMD	; Attempt to set state

	 call	 INFO_READ	; Read in INFO structure
				; to reset flags
@@:

; Mark high DOS memory

	 call	 MARK_HIGH	; Mark it

; Search for ROM

	 xor	 ebx,ebx	; Zero entire register
	 mov	 edx,0A000h	; Start with this segment
ACT_ROM_MORE:
	 mov	 es,dx		; Put it in a segment register
	 assume  es:ROMSEG	; Tell the assembler about it

	 mov	 ax,DROMSIGN	; Get ROM signature
	 add	 ax,@ROMOFF	; Plus offset

	 cmp	 ax,ROMSIGN	; Check for ROM signature
	 jne	 short ACT_ROM_NEXT ; Not this place

; On some systems (such as the Dell 316LT laptop), a sequence of
; bytes 55 AA 55 AA ... appears which can confuse us into thinking
; that there's a length 55x200h (47.5KB) ROM there.

	 cmp	 ax,ROMSIGN[2]	; Izit a false positive?
	 je	 short ACT_ROM_NEXT ; Jump if so

; There's a ROM in segment DX

	 movzx	 ecx,ROMLEN	; Get length parameter in 512-bytes
ACT_ROM_SYSTEM:
	 jcxz	 ACT_ROM_NEXT	; Jump if of zero length

	 mov	 bx,dx		; Copy segment #
	 sub	 bx,0A000h	; Convert to origin-A000
	 shr	 bx,9-4 	; Convert from paras to 512-bytes
	 add	 bx,PRAMTAB	; DS:BX ==> corresponding entry in RAMTAB
	 mov	 al,mask $RAM_RO1 ; Use first byte marker

; Check for a false positive on a ROM in high DOS memory,
; by ensuring that we don't overwrite the space reserved
; for PRAMTAB.

	mov	di,bx		; Get offset in PRAMTAB
	add	di,cx		; Plus length

	cmp	di,PRAMTABZ	; Izit too long?
	ja	short ACT_ROM_NEXT ; Jump if so (spurious)

	 push	 cx		; Save for a moment
@@:
	 or	 PGROUP:[bx],al ; Mark as ROM
	 mov	 al,mask $RAM_ROM ; Use other byte marker
	 inc	 bx		; Skip to next entry
	 loop	 @B		; Jump if more 512-byte blocks in the ROM

	 pop	 cx		; Restore

	 shl	 ecx,9-4	; Convert from 512-bytes to paras
	 add	 edx,ecx	; Skip to ending segment address

	 jmp	 short ACT_ROM_NEXT1 ; Join common code

ACT_ROM_NEXT:
	 add	 edx,512/16	; Skip to next 512-byte block
ACT_ROM_NEXT1:
	 cmp	 edx,LCLSYSROM_START ; End of the line?
	 jb	 short ACT_ROM_MORE ; Go around again
	 jne	 short @F	; Jump if not

	 mov	 ecx,10000h	; Get upper limit in segments
	 sub	 ecx,edx	; Less segment # to get length in paras
	 shr	 ecx,9-4	; Convert from paras to 512-bytes

	 jmp	 short ACT_ROM_SYSTEM ; Once more for the system ROM

@@:
	 push	 cs		; Setup for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; If we're on an EGA/VGA, mark the region A000-C000 as video RAM

	 call	 IZITEGA	; Check for EGA -- return AX = -1 if not

	 cmp	 ax,-1		; Check it out
	 je	 short ACT_ROM_XEGA ; Not this time

	 mov	 di,PRAMTAB	; ES:DI ==> start of RAMTAB at A000
	 mov	 cx,128 shl (10-9) ; Region size of 128KB in 512-bytes
@@:
	 or	 PGROUP:[di].LO,(mask $RAM_VID) or (mask $RAM_RAM); Mark as video RAM present
	 inc	 di		; Skip to next entry

	 loop	 @B		; Jump if more bytes to check

	 jmp	 short ACT_ROM_VIDCOM ; Join common code

ACT_ROM_XEGA:

; If there's a mono adapter present, mark the region B000-B800 as video RAM

	 mov	 dx,03B4h	; Address register of monochrome 6845

	 call	 CHK_CREG	; Check cursor register
	 jc	 short ACT_ROM_XMONO ; It's not present

	 mov	 di,PRAMTAB	; ES:DI ==> start of RAMTAB at A000
	 add	 di,(0B000h-0A000h) shr (9-4) ; Skip to B000 in table
	 mov	 cx,32 shl (10-9) ; Region size of 32KB in 512-bytes
@@:
	 or	 PGROUP:[di].LO,(mask $RAM_VID) or (mask $RAM_RAM); Mark as video RAM present
	 inc	 di		; Skip to next entry

	 loop	 @B		; Jump if more bytes to check
ACT_ROM_XMONO:

; If there's a color adapter present, mark the region B800-C000 as video RAM

	 mov	 dx,03D4h	; Address register of color/graphics 6845

	 call	 CHK_CREG	; Check cursor register
	 jc	 short ACT_ROM_XCOLR ; It's not present

	 mov	 di,PRAMTAB	; ES:DI ==> start of RAMTAB at A000
	 add	 di,(0B800h-0A000h) shr (9-4) ; Skip to B800 in table
	 mov	 cx,32 shl (10-9) ; Region size of 32KB in 512-bytes
@@:
	 or	 PGROUP:[di].LO,(mask $RAM_VID) or (mask $RAM_RAM); Mark as video RAM present
	 inc	 di		; Skip to next entry

	 loop	 @B		; Jump if more bytes to check
ACT_ROM_XCOLR:
ACT_ROM_VIDCOM:


if @OEM_FLEXROM

; Check for the case of VGA ROM and MAC entry at C000
; in which case we need to handle the gore at C000

	 test	 FLEXROM_FLAG,@FR_GORE ; Izit present?
	 jz	 short ACT_ROM_XGORE ; Jump if not

; Because the gore at C000 is 512 bytes long, the amount of high
; DOS memory is under-reported by 1KB.	The following instruction
; corrects that error.

	 inc	 SCNSIZE_OVR	; Add into total

	 push	 es		; Save for a moment

	 mov	 ax,0C000h	; Get segment of VGA ROM
	 mov	 es,ax		; Address it
	 assume  es:ROMSEG	; Tell the assembler about it

	 movzx	 cx,ROMLEN	; Get length in units of 512-bytes

	 mov	 di,PRAMTAB	; PGROUP:DI ==> start of RAMTAB
	 add	 di,(0C000h-0A000h) shr (9-4) ; Skip to entry for C000
@@:
	 and	 PGROUP:[di].LO,not (mask $RAM_OVR) ; Clear high DOS memory marker
	 inc	 di		; Skip to next 512-byte block

	 loop	 @B		; Jump if more 512-byte blocks

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it
ACT_ROM_XGORE:
endif				; IF @OEM_FLEXROM

; Display header info

	 lea	 dx,MSG_SCNHDR	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

; Display low DOS memory line

	 lea	 di,SCNTYPE_LOW ; PGROUP:DI ==> scan type
	 call	 COPY_SCN	; Copy scan type to MSG_SCNLINE

	 xor	 eax,eax	; EAX = starting address
	 lea	 di,MSG_SCNADDR1 ; PGROUP:DI ==> output save area
	 call	 DD2HEXNZ	; Display dword in EAX at ES:DI w/o zero fill

	 int	 12h		; Return with AX = memory size in KB
	 movzx	 eax,ax 	; Zero to use as dword
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 lea	 di,MSG_SCNADDR2 ; PGROUP:DI ==> output save area
	 call	 DD2HEXNZ	; Display dword in EAX at ES:DI w/o zero fill

	 shr	 eax,10-0	; Convert from bytes to 1KB
	 lea	 di,MSG_SCNSIZE ; ES:DI ==> output save area
	 mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 lea	 dx,MSG_SCNLINE ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 call	 CLEAR_SCNLINE	; Clear the SCAN line

	 lea	 dx,MSG_SEPLINE ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX


; Loop through RAMTAB and display info

COMMENT|

Register usage:

DS:SI	 ==>	 current position in RAMTAB
DS:BP	 ==>	 local maximum

|

; Determine where low DOS memory stops and start there

	 mov	 si,PRAMTAB	; DS:SI ==> RAMTAB

	 int	 12h		; Return with AX = memory size in KB

	 sub	 ax,640 	; Less start of our table in 1KB
	 jb	 short @F	; Jump if earlier than 640

	 shl	 ax,10-9	; Convert from 1KB to 512B
	 add	 si,ax		; Add as new start
@@:
RAMTAB_NEXT:
	 cmp	 PGROUP:[si].LO,@RAM_END ; Check against ending
	 je	 near ptr RAMTAB_END ; Jump if we're done

	 mov	 bp,si		; Save as highest address

; First, check for EMS-mappable addresses
; EMS = 1

	 mov	 bx,si		; DS:BX ==> next byte to check
RAMTAB_EMS:
	 test	 PGROUP:[bx].LO,mask $RAM_EMS ; Izit EMS-mappable?
	 jz	 short RAMTAB_EMS1 ; Jump if it isn't

	 inc	 bx		; Skip to next entry

	 cmp	 PGROUP:[bx].LO,@RAM_END ; Izit the end?
	 jne	 short RAMTAB_EMS ; Jump if not
RAMTAB_EMS1:
	 mov	 cx,bx		; Copy next address
	 sub	 cx,si		; Less starting address
	 jz	 short RAMTAB_XEMS ; Jump if not present

	 mov	 al,' '         ; Surrounding marker, format length
	 lea	 di,SCNTYPE_EMSM ; PGROUP:DI ==> scan type
	 call	 FMT_SCN	; Format scan line

	 shr	 cx,10-9	; Convert from 512B to 1KB
	 add	 SCNSIZE_EMSM,cx ; Add into total

	 cmp	 bx,bp		; Use the larger
	 jbe	 short @F	; Jump if new offset is no larger

	 mov	 bp,bx		; Use new address
@@:
;;;;;;;; mov	 si,bx		; Copy as next address
;;;;;;;;
	 jmp	 RAMTAB_LOOP	; Go around again


RAMTAB_XEMS:

; Next, check for ROM
; ROM = 1

; Izit first or subsequent byte of ROM or PSMEM?

	 test	 PGROUP:[si].LO,(mask $RAM_RO1) or (mask $RAM_ROM) or (mask $RAM_PSM) ; Izit it?
	 jz	 short RAMTAB_XROM ; Jump if not

; Look for consecutive ROM

	 mov	 bx,si		; DS:BX ==> next byte to check
	 xor	 cx,cx		; Zero high DOS count
RAMTAB_ROM:
	 test	 PGROUP:[bx].LO,mask $RAM_OVR ; Izit high DOS?
	 jz	 short @F	; Jump if not

	 inc	 cx		; Count in another one
@@:
	 inc	 bx		; Skip to next entry

	 cmp	 PGROUP:[bx].LO,@RAM_END ; Izit the end?
	 je	 short RAMTAB_ROM1 ; Jump if so

	 test	 PGROUP:[bx].LO,(mask $RAM_ROM)  or (mask $RAM_PSM) ; Izit ROM or PSMEM?
	 jnz	 short RAMTAB_ROM ; Jump if so
RAMTAB_ROM1:
	 push	 cx		; Save for a moment

	 mov	 cx,bx		; Copy next address
	 sub	 cx,si		; Less starting address
	 mov	 al,' '         ; Surrounding marker, format length
	 lea	 di,SCNTYPE_ROM ; PGROUP:DI ==> scan type
	 call	 FMT_SCN	; Format scan line

	 shr	 cx,10-9	; Convert from 512B to 1KB
	 add	 SCNSIZE_ROM,cx ; Add into total

	 pop	 cx		; Restore

	 call	 FMTOVR 	; Format and display it

	 shr	 cx,10-9	; Convert from 512B to 1KB
	 sub	 SCNSIZE_ROM,cx ; Remove from total

	 cmp	 bx,bp		; Use the larger
	 jbe	 short @F	; Jump if new offset is no larger

	 mov	 bp,bx		; Use new address
@@:
;;;;;;;; mov	 si,bx		; Copy as next address
;;;;;;;;
	 jmp	 RAMTAB_LOOP	; Go around again


RAMTAB_XROM:

; Next, check for video RAM
; VID = 1
; RAM = 1
; RO1 = 0
; ROM = 0

@RAMVID  equ	 (mask $RAM_VID) or (mask $RAM_RAM) or (mask $RAM_RO1) or (mask $RAM_ROM)

	 mov	 al,PGROUP:[bx] ; Get the value
	 and	 al,@RAMVID	; Isolate the bits
	 xor	 al,(mask $RAM_RO1) or (mask $RAM_ROM)

	 cmp	 al,@RAMVID	; Check for video RAM and no ROM
	 jne	 short RAMTAB_XVID ; Jump if not

; Look for consecutive video RAM

	 mov	 bx,si		; DS:BX ==> next byte to check
	 xor	 cx,cx		; Zero high DOS count
	 xor	 dx,dx		; Zero ROM or PSM count
RAMTAB_VID:
	 test	 PGROUP:[bx].LO,mask $RAM_OVR ; Izit high DOS?
	 jz	 short @F	; Jump if not

	 inc	 cx		; Count in another one
@@:
	 test	 PGROUP:[bx].LO,(mask $RAM_ROM) or (mask $RAM_PSM) ; Izit ROM or PSM?
	 jz	 short @F	; Jump if not

	 inc	 dx		; Count in another one
@@:
	 inc	 bx		; Skip to next entry

	 cmp	 PGROUP:[bx].LO,@RAM_END ; Izit the end?
	 je	 short RAMTAB_VID1 ; Jump if so

	 mov	 al,PGROUP:[bx] ; Get the value
	 and	 al,@RAMVID	; Isolate the bits
	 xor	 al,(mask $RAM_RO1) or (mask $RAM_ROM)

	 cmp	 al,@RAMVID	; Check for video RAM and no ROM
	 je	 short RAMTAB_VID ; Jump if so
RAMTAB_VID1:
	 push	 cx		; Save for a moment

	 mov	 cx,bx		; Copy next address
	 sub	 cx,si		; Less starting address
	 mov	 al,' '         ; Surrounding marker, format length
	 lea	 di,SCNTYPE_VID ; PGROUP:DI ==> scan type
	 call	 FMT_SCN	; Format scan line

	 shr	 cx,10-9	; Convert from 512B to 1KB
	 add	 SCNSIZE_VID,cx ; Add into total

	 pop	 cx		; Restore

	 call	 FMTOVR 	; Format and display it

	 shr	 cx,10-9	; Convert from 512B to 1KB
	 sub	 SCNSIZE_VID,cx ; Remove from total

	 mov	 cx,dx		; Copy counter
	 call	 FMTROM 	; Format and display it

	 shr	 cx,10-9	; Convert from 512B to 1KB
	 sub	 SCNSIZE_VID,cx ; Remove from total

	 cmp	 bx,bp		; Use the larger
	 jbe	 short @F	; Jump if new offset is no larger

	 mov	 bp,bx		; Use new address
@@:
;;;;;;;; mov	 si,bx		; Copy as next address
;;;;;;;;
	 jmp	 RAMTAB_LOOP	; Go around again


RAMTAB_XVID:

; Next, check for RAM
; RAM = 1
; RO1 = 0
; ROM = 0

@RAMRAM  equ	 (mask $RAM_RAM) or (mask $RAM_RO1) or (mask $RAM_ROM)

	 mov	 al,PGROUP:[bx] ; Get the value
	 and	 al,@RAMRAM	; Isolate the bits
	 xor	 al,(mask $RAM_RO1) or (mask $RAM_ROM)

	 cmp	 al,@RAMRAM	; Check for RAM and no ROM
	 jne	 short RAMTAB_XRAM ; Jump if not

; Look for consecutive RAM

	 mov	 bx,si		; DS:BX ==> next byte to check
	 xor	 cx,cx		; Zero high DOS count
RAMTAB_RAM:
	 test	 PGROUP:[bx].LO,mask $RAM_OVR ; Izit high DOS?
	 jz	 short @F	; Jump if not

	 inc	 cx		; Count in another one
@@:
	 inc	 bx		; Skip to next entry

	 cmp	 PGROUP:[bx].LO,@RAM_END ; Izit the end?
	 je	 short RAMTAB_RAM1 ; Jump if so

	 mov	 al,PGROUP:[bx] ; Get the value
	 and	 al,@RAMRAM	; Isolate the bits
	 xor	 al,(mask $RAM_RO1) or (mask $RAM_ROM)

	 cmp	 al,@RAMRAM	; Check for RAM and no ROM
	 je	 short RAMTAB_RAM ; Jump if so
RAMTAB_RAM1:
	 push	 cx		; Save for a moment

	 mov	 cx,bx		; Copy next address
	 sub	 cx,si		; Less starting address
	 mov	 al,' '         ; Surrounding marker, format length
	 lea	 di,SCNTYPE_RAM ; PGROUP:DI ==> scan type
	 call	 FMT_SCN	; Format scan line

	 shr	 cx,10-9	; Convert from 512B to 1KB
	 add	 SCNSIZE_RAM,cx ; Add into total

	 pop	 cx		; Restore

	 call	 FMTOVR 	; Format and display it

	 shr	 cx,10-9	; Convert from 512B to 1KB
	 sub	 SCNSIZE_RAM,cx ; Remove from total

	 cmp	 bx,bp		; Use the larger
	 jbe	 short @F	; Jump if new offset is no larger

	 mov	 bp,bx		; Use new address
@@:
;;;;;;;; mov	 si,bx		; Copy as next address
;;;;;;;;
	 jmp	 short RAMTAB_LOOP ; Go around again

@RAMIDN  equ	 (mask $RAM_RO1) or (mask $RAM_ROM) or (mask $RAM_EMS) or \
		 (mask $RAM_RAM) or (mask $RAM_IDN) or (mask $RAM_OVR) or \
		 (mask $RAM_PSM)

RAMTAB_XRAM:

; Next, check for no RAM and identity mapping (UNUSED)
; We also use this as a catchall category in case the
; corresponding entry in PRAMTAB is all zero.
; RAM = 0
; IDN = 1
; EMS = 0
; RO1 = 0
; ROM = 0
; OVR = 0
; PSM = 0

	 mov	 bx,si		; DS:BX ==> next byte to check
RAMTAB_IDN:
	 mov	 al,PGROUP:[bx] ; Get the value
	 and	 al,@RAMIDN	; Isolate the bits
	 jz	 short RAMTAB_IDN0 ; Jump if nobody's home

	 xor	 al,(mask $RAM_RAM) or (mask $RAM_EMS) or (mask $RAM_RO1) or \
		    (mask $RAM_ROM) or (mask $RAM_OVR) or (mask $RAM_PSM)

	 cmp	 al,@RAMIDN	; Check for no RAM and identity
	 jne	 short RAMTAB_IDN1 ; Jump if it isn't
RAMTAB_IDN0:
	 inc	 bx		; Skip to next entry

	 cmp	 PGROUP:[bx].LO,@RAM_END ; Izit the end?
	 jne	 short RAMTAB_IDN ; Go around again
RAMTAB_IDN1:
	 mov	 cx,bx		; Copy next address
	 sub	 cx,si		; Less starting address
	 jz	 short RAMTAB_XIDN ; Jump if not RAM

	 mov	 al,' '         ; Surrounding marker, format length
	 lea	 di,SCNTYPE_OTH ; PGROUP:DI ==> scan type
	 call	 FMT_SCN	; Format scan line

	 shr	 cx,10-9	; Convert from 512B to 1KB
	 add	 SCNSIZE_OTH,cx ; Add into total

	 cmp	 bx,bp		; Use the larger
	 jbe	 short @F	; Jump if new offset is no larger

	 mov	 bp,bx		; Use new address
@@:
;;;;;;;; mov	 si,bx		; Copy as next address
;;;;;;;;
;;;;;;;; jmp	 short RAMTAB_LOOP ; Go around again


RAMTAB_XIDN:

; Finally, check for USE= memory within the same region
; OVR = 1

	 mov	 bx,si		; DS:BX ==> next byte to check
RAMTAB_USE:
	 test	 PGROUP:[bx].LO,mask $RAM_OVR ; Izit high DOS memory?
	 jz	 short RAMTAB_USE1 ; Jump if it isn't

	 inc	 bx		; Skip to next entry

	 cmp	 PGROUP:[bx].LO,@RAM_END ; Izit the end?
	 jne	 short RAMTAB_USE ; Jump if not
RAMTAB_USE1:
	 mov	 cx,bx		; Copy next address
	 sub	 cx,si		; Less starting address
	 jz	 short RAMTAB_XUSE ; Jump if not in use

	 mov	 al,' '         ; Surrounding marker, format length
	 lea	 di,SCNTYPE_OVR ; PGROUP:DI ==> scan type
	 call	 FMT_SCN	; Format scan line

	 shr	 cx,10-9	; Convert from 512B to 1KB
	 add	 SCNSIZE_OVR,cx ; Add into total

	 cmp	 bx,bp		; Use the larger
	 jbe	 short @F	; Jump if new offset is no larger

	 mov	 bp,bx		; Use new address
@@:
;;;;;;;; mov	 si,bx		; Copy as next address
;;;;;;;;
;;;;;;;; jmp	 short RAMTAB_LOOP ; Go around again
RAMTAB_XUSE:
RAMTAB_LOOP:
	 mov	 si,bp		; Copy as next address

	 lea	 dx,MSG_SCNLINE ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 call	 CLEAR_SCNLINE	; Clear the SCAN line

	 jmp	 RAMTAB_NEXT	; Go around again

if @OEM_WIN3
ACT_ROM_WINERR:
	 lea	 dx,MSG_WINERR	; DS:DX ==> error message
	 call	 STROUT 	; Display the string at DS:DX

	 jmp	 short ACT_ROM_ERR ; Join common error code
endif				; IF @OEM_WIN3

ACT_ROM_ERR:
	 stc			; Indicate something went wrong

	 jmp	 ACT_ROM_EXIT	; Join common exit code


; All entries in RAMTAB processed

RAMTAB_END:
	 lea	 dx,MSG_SEPLINE ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

; Sort extended memory values

	 call	 ACT_ROM_SORTEXTMEM ; Sort 'em

; Calculate and format extended memory values

	 call	 ACT_ROM_CALCEXTMEM ; Calculate and format 'em

; Calculate total amount of high DOS memory

	 mov	 ax,SCNSIZE_VID ; Get amount of video RAM
	 add	 ax,SCNSIZE_RAM ; Plus amount of RAM
	 add	 ax,SCNSIZE_ROM ; Plus amount of ROM
	 add	 ax,SCNSIZE_OTH ; Plus amount of unused memory
	 add	 ax,SCNSIZE_EMSM ; Plus amount of EMS-mappable memory
	 add	 ax,SCNSIZE_OVR ; Plus amount of high DOS memory
	 mov	 SCNSIZE_TOT,ax ; Save for later use

; Format high DOS memory summary sizes

	 call	 ACT_ROM_FMTOVRVAL ; Format 'em

; Calculate and format high DOS memory summary percentages

	 call	 ACT_ROM_CALCOVRPCT ; Calculate and format 'em

; Calculate and format extended memory summary values

	 call	 ACT_ROM_CALCEXTSUM ; Calculate and format 'em

; Display memory summary

	 lea	 dx,MSG_SCNTAIL ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 clc			; Indicate all went well
ACT_ROM_EXIT:
	 REGREST <es>		; Restore
	 assume  es:PGROUP	; Tell the assembler about it
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_ROM  endp			; End ACT_ROM procedure
	 NPPROC  ACT_ROM_SORTEXTMEM -- Sort Extended Memory Values
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Sort extended memory values ascendingly by starting address
maintaining a stable sort.

|

	 REGSAVE <eax,cx,si,di> ; Save registers

	 mov	 si,PEXTADDR	; DS:SI ==> EXTADDR_STR structure

; As there are relatively few entries, we'll use a simple bubble sort

	 mov	 cx,ENTRYCNT	; Get # entries

	 cmp	 cx,1		; Check against limit cases
	 jbe	 short ACT_ROM_SORTEXTMEM_EXIT ; Jump if nothing to sort

	 dec	 cx		; Account for second entry (the number of
				; comparisons is ENTRYCNT-1)
SORTEXTMEM_OUTER:
	 push	 cx		; Save outer loop counter

	 lea	 di,PGROUP:[si+type EXTADDR_STR] ; Skip to next entry
	 mov	 eax,PGROUP:[si].EXTADDR_ADDR ; Get starting address
SORTEXTMEM_INNER:
	 cmp	 eax,PGROUP:[di].EXTADDR_ADDR ; Izit in sequence?
	 jbe	 short SORTEXTMEM_INNERLOOP ; Jump if so

; Rotate the entries between SI (low) and DI (high) upwards

	 push	 si		; Save starting offset

; Save the last entry on the stack

	 mov	 cx,(type EXTADDR_STR)/2 ; Get # words in each entry
@@:
	 push	 PGROUP:[di].ELO ; Save on stack
	 add	 di,2		; Skip to next word
	 loop	 @B		; Jump if more words to save

; DI points to next word following higher entry

	 mov	 cx,di		; Copy higher ending address
	 sub	 cx,si		; Subtract to get # bytes to rotate
	 sub	 cx,type EXTADDR_STR ; Less one entry saved on the stack
	 shr	 cx,1-0 	; Convert from bytes to words
	 sub	 di,2		; Back off to previous word
	 lea	 si,[di-(type EXTADDR_STR)] ; Point to entry below higher
	 std			; String ops backwards
     rep movsw			; Move downwards
	 cld			; Restore

; Restore the last entry from the stack to the first entry
; to complete the rotatation

	 mov	 cx,(type EXTADDR_STR)/2 ; Get # words in each entry
@@:
	 pop	 PGROUP:[di].ELO ; Restore from stack
	 sub	 di,2		; Skip to previous word
	 loop	 @B		; Jump if more words to restore

	 pop	 si		; Restore
	 pop	 cx		; Restore outer loop counter

	 jmp	 short SORTEXTMEM_OUTER ; Go around again

SORTEXTMEM_INNERLOOP:
	 add	 di,type EXTADDR_STR ; Skip to next entry

	 loop	 SORTEXTMEM_INNER ; Jump if more entries in inner loop

	 pop	 cx		; Restore outer loop counter

	 add	 si,type EXTADDR_STR ; Skip to next entry

	 loop	 SORTEXTMEM_OUTER ; Jump if more entries in outer loop
ACT_ROM_SORTEXTMEM_EXIT:
	 REGREST <di,si,cx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_ROM_SORTEXTMEM endp 	; End ACT_ROM_SORTEXTMEM procedure
	 NPPROC  ACT_ROM_CALCEXTMEM -- Calculate and Format Extended Memory Values
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate and format extended memory values

|

	 REGSAVE <eax,ebx,cx,dx,si,di,ebp> ; Save registers

	 mov	 si,PEXTADDR	; DS:SI ==> EXTADDR_STR structure

; Loop through the variable length fields displaying data along the way

	 mov	 cx,ENTRYCNT	; Get # entries

	 and	 cx,cx		; Anything to do?
	 jz	 near ptr ACT_ROM_CALCEXTMEM_EXIT ; Jump if nothing to do

	 mov	 ebx,PGROUP:[si].EXTADDR_ADDR ; Initialize last ending address
	 mov	 ebp,ebx	; ...
CALCEXTMEM_NEXT:

; Process allocated VCPI memory:  there is no table of
; such allocations.  We catch this type of allocated memory
; by the absence of other indicators.  In particular, if the
; last ending address (always on a 4KB boundary) is below the
; current starting address, and the difference is at least 4KB,
; mark the difference (rounded down to a 4KB boundary) as
; allocated VCPI memory.

	 cmp	 ROMDBG,2	; Are we in second phase?
	 je	 short CALCEXTMEM_NOVCPI ; Jump if so (no VCPI here)

	 mov	 eax,PGROUP:[si].EXTADDR_ADDR ; Get starting address

	 cmp	 eax,-1 	; Izit a zero-length EMS/XMS handle?
	 je	 short CALCEXTMEM_NOVCPI ; Jump if so

	 and	 eax,not (4*1024-1) ; Round down to 4KB boundary

	 sub	 eax,ebx	; Less starting address to get length (/4KB)
	 jbe	 short CALCEXTMEM_NOVCPI ; Jump if nothing there

; Call it allocated VCPI memory starting at EBX for EAX bytes

	 lea	 di,SCNTYPE_VCPI ; PGROUP:DI ==> type string
	 call	 COPY_SCN	; Copy scan type to MSG_SCNLINE

	 xchg	 eax,ebx	; Swap so that EAX = starting address
	 lea	 di,MSG_SCNADDR1 ; PGROUP:DI ==> output save area
	 call	 DD2HEXNZ	; Display dword in EAX at ES:DI w/o zero fill

; If we're debugging and the last ending address
; is not adjacent to the current starting address, note that fact

	 cmp	 ROMDBG,1	; Are we debugging?
	 jb	 short @F	; Jump if not

	 cmp	 eax,ebp	; Izit adjacent?
	 je	 short @F	; Jump if so

	 mov	 MSG_SCNOVR1,'*' ; Mark as holey
@@:
	 add	 eax,ebx	; Add to get ending address
	 lea	 di,MSG_SCNADDR2 ; PGROUP:DI ==> output save area
	 call	 DD2HEXNZ	; Display dword in EAX at ES:DI w/o zero fill

	 mov	 eax,ebx	; Copy length in bytes
	 shr	 eax,10-0	; Convert from bytes to 1KB
	 ror	 eax,16 	; Rotate down high-order word
	 mov	 dx,ax		; Copy to DX for DD2DEC
	 rol	 eax,16 	; Rotate back
	 DD2DEC_MAC MSG_SCNSIZE ; Format (DX,AX) into MSG_SCNSIZE

	 add	 SCNACCUM_VCPI.ELO,ax ; Accumulate the length
	 adc	 SCNACCUM_VCPI.EHI,dx ; In case of overflow

	 lea	 dx,MSG_SCNLINE ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 call	 CLEAR_SCNLINE	; Clear the SCAN line
CALCEXTMEM_NOVCPI:

; Format the type string

	 movzx	 di,PGROUP:[si].EXTADDR_TYPE ; Get the entry's type
	 shl	 di,1-0 	; Convert from words to bytes
	 mov	 di,SCNTYPE[di] ; PGROUP:DI ==> type string
	 call	 COPY_SCN	; Copy scan type to MSG_SCNLINE

; Format the starting address

	 mov	 eax,PGROUP:[si].EXTADDR_ADDR ; Get starting address
	 lea	 di,MSG_SCNADDR1 ; PGROUP:DI ==> output save area
	 call	 DD2HEXNZ	; Display dword in EAX at ES:DI w/o zero fill

; If we're in debugging phase and the last ending address
; is not adjacent to the current starting address, note that fact

	 cmp	 ROMDBG,2	; Are we in second phase?
	 jne	 short @F	; Jump if not

	 cmp	 eax,ebp	; Izit adjacent?
	 je	 short @F	; Jump if so

	 mov	 MSG_SCNOVR1,'*' ; Mark as holey
@@:

; Format the ending address

	 add	 eax,PGROUP:[si].EXTADDR_LEN ; Plus length to get ending address
	 mov	 ebp,eax	; Copy as last ending address
	 mov	 ebx,eax	; ...			      rounded up
	 add	 ebx,4*1024-1	; Round up to 4KB boundary
	 and	 ebx,not (4*1024-1) ; ...

	 lea	 di,MSG_SCNADDR2 ; PGROUP:DI ==> output save area
	 call	 DD2HEXNZ	; Display dword in EAX at ES:DI w/o zero fill

; Format the length

	 mov	 eax,PGROUP:[si].EXTADDR_LEN ; Get length in bytes

	 cmp	 ROMDBG,2	; Are we in second phase?
	 je	 short @F	; Jump if so (don't change scales)

	 shr	 eax,10-0	; Convert from bytes to 1KB
@@:
	 ror	 eax,16 	; Rotate down high-order word
	 mov	 dx,ax		; Copy to DX for DD2DEC
	 rol	 eax,16 	; Rotate back
	 DD2DEC_MAC MSG_SCNSIZE ; Format (DX,AX) into MSG_SCNSIZE

; Accumulate the length

	 movzx	 di,PGROUP:[si].EXTADDR_TYPE ; Get the entry's type

; If this is LDT or DPMI memory table for handle #0, it's actually
; allocated within program storage and should not be accumulated
; anywhere.  Otherwise, the memory should be accumulated as per
; the SCNACCUM_xxx entries.

	 cmp	 PGROUP:[si].EXTADDR_HNDL,0 ; Izit handle #0?
	 jne	 short @F	; Jump if not

	 cmp	 di,@EXTADDRTYPE_LDT ; Izit for the LDT?
	 je	 short CALCEXTMEM_XACCUM ; Jump if so (don't accumulate)

	 cmp	 di,@EXTADDRTYPE_DHNDL ; Izit for the DPMI memory handle table?
	 je	 short CALCEXTMEM_XACCUM ; Jump if so (don't accumulate)
@@:
	 shl	 di,1-0 	; Convert from words to bytes
	 mov	 di,SCNACCUM[di] ; PGROUP:DI ==> accumulator
	 add	 PGROUP:[di].ELO,ax ; Accumulate it
	 adc	 PGROUP:[di].EHI,dx ; In case of overflow
CALCEXTMEM_XACCUM:

; Format the handle # if valid

	 test	 PGROUP:[si].EXTADDR_FLAG,@EXTADDRFLAG_HNDL ; Izit valid?
	 jz	 short @F	; Jump if not

	 mov	 ax,PGROUP:[si].EXTADDR_HNDL ; Get the handle #
	 lea	 di,MSG_SCNHNDL ; PGROUP:DI ==> output save area
	 call	 DW2HEXNZ	; Display word in AX at ES:DI w/o zero fill
@@:

; Format the name if valid

	 test	 PGROUP:[si].EXTADDR_FLAG,@EXTADDRFLAG_NAME ; Izit valid?
	 jz	 short CALCEXTMEM_NONAME ; Jump if not

	 mov	 al,0		; Function code to get handle name
	 mov	 dx,PGROUP:[si].EXTADDR_HNDL ; Get the handle #
	 lea	 di,MSG_SCNNAME ; PGROUP:DI ==> output save area
	 EMMCALL @EMM_GETSETNAME ; Request EMS service

; Ensure that the handle name is valid

	 REGSAVE <ax,cx,di>	; Save registers

	 mov	 cx,8		; Size of EMM handle name
	 xor	 al,al		; Scan for a NUL

CALCEXTMEM_NAME_NEXT:
	 scas	 MSG_SCNNAME[di] ; Is next character a NUL?
	 jnz	 @F		; Jump if not

	 mov	 PGROUP:[di-1].LO,' ' ; Replace NUL with a space
@@:
	 loop	 CALCEXTMEM_NAME_NEXT ; Convert next character

	 REGREST <di,cx,ax>	; Restore registers

CALCEXTMEM_NONAME:
	 lea	 dx,MSG_SCNLINE ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 call	 CLEAR_SCNLINE	; Clear the SCAN line

; If this is the program storage entry and we're not finished (CX > 1),
; display a separator line for visual effect when debugging

	 cmp	 PGROUP:[si].EXTADDR_TYPE,@EXTADDRTYPE_PRG ; Izit program storage?
	 jne	 short @F	; Jump if not

	 cmp	 cx,1		; Are we finished?
	 je	 short @F	; Jump if so

	 cmp	 ROMDBG,1	; Are we debugging?
	 jne	 short @F	; Jump if not

	 mov	 ROMDBG,2	; Change to new mode
	 mov	 ebp,PGROUP:[si].EXTADDR_ADDR ; Get starting address

	 lea	 dx,MSG_SEPLINE ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX
@@:
	 add	 si,type EXTADDR_STR ; Skip to next entry

;;;;;;;; loop	 CALCEXTMEM_NEXT ; Jump if more entries

	 dec	 cx		; Count out another one
	 jnz	 near ptr CALCEXTMEM_NEXT ; Jump if more entries
ACT_ROM_CALCEXTMEM_EXIT:
	 REGREST <ebp,di,si,dx,cx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_ROM_CALCEXTMEM endp 	; End ACT_ROM_CALCEXTMEM procedure
	 NPPROC  ACT_ROM_FMTOVRVAL -- Format High DOS Memory Values
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format high DOS memory values

|

	 REGSAVE <ax,cx,di>	; Save registers

	 mov	 ax,SCNSIZE_VID ; Get amount of video RAM
	 lea	 di,MSG_SCNSIZE_VID ; PGROUP:DI ==> output save area
	 mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 mov	 ax,SCNSIZE_RAM ; Get amount of RAM
	 lea	 di,MSG_SCNSIZE_RAM ; PGROUP:DI ==> output save area
;;;;;;;; mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 mov	 ax,SCNSIZE_ROM ; Get amount of ROM
	 lea	 di,MSG_SCNSIZE_ROM ; PGROUP:DI ==> output save area
;;;;;;;; mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 mov	 ax,SCNSIZE_OTH ; Get amount of unused memory
	 lea	 di,MSG_SCNSIZE_OTH ; PGROUP:DI ==> output save area
;;;;;;;; mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 mov	 ax,SCNSIZE_EMSM ; Get amount of EMS-mappable memory
	 lea	 di,MSG_SCNSIZE_EMSM ; PGROUP:DI ==> output save area
;;;;;;;; mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 mov	 ax,SCNSIZE_OVR ; Get amount of high DOS memory
	 lea	 di,MSG_SCNSIZE_OVR ; PGROUP:DI ==> output save area
;;;;;;;; mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 mov	 ax,SCNSIZE_TOT ; Get total amount of memory
	 lea	 di,MSG_SCNSIZE_TOT ; PGROUP:DI ==> output save area
;;;;;;;; mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_ROM_FMTOVRVAL endp		; End ACT_ROM_FMTOVRVAL procedure
	 NPPROC  ACT_ROM_CALCOVRPCT -- Calculate and Format High DOS Memory Summary Percentages
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate and format high DOS memory summary percentages

|

	 REGSAVE <ax,cx,dx,di>	; Save registers

	 mov	 ax,100 	; Get multiplier
	 mul	 SCNSIZE_VID	; Times amount of video RAM
	 div	 SCNSIZE_TOT	; Divided by total amount
	 shl	 dx,1		; Times two to check for halfway

	 cmp	 SCNSIZE_TOT,dx ; Izit more than halfway?
	 adc	 ax,0		; Add if so
	 mov	 SCNPCT_VID,ax	; Save for later use

	 mov	 ax,100 	; Get multiplier
	 mul	 SCNSIZE_RAM	; Times amount of RAM
	 div	 SCNSIZE_TOT	; Divided by total amount
	 shl	 dx,1		; Times two to check for halfway

	 cmp	 SCNSIZE_TOT,dx ; Izit more than halfway?
	 adc	 ax,0		; Add if so
	 mov	 SCNPCT_RAM,ax	; Save for later use

	 mov	 ax,100 	; Get multiplier
	 mul	 SCNSIZE_ROM	; Times amount of ROM
	 div	 SCNSIZE_TOT	; Divided by total amount
	 shl	 dx,1		; Times two to check for halfway

	 cmp	 SCNSIZE_TOT,dx ; Izit more than halfway?
	 adc	 ax,0		; Add if so
	 mov	 SCNPCT_ROM,ax	; Save for later use

	 mov	 ax,100 	; Get multiplier
	 mul	 SCNSIZE_OTH	; Times amount of unused memory
	 div	 SCNSIZE_TOT	; Divided by total amount
	 shl	 dx,1		; Times two to check for halfway

	 cmp	 SCNSIZE_TOT,dx ; Izit more than halfway?
	 adc	 ax,0		; Add if so
	 mov	 SCNPCT_OTH,ax	; Save for later use

	 mov	 ax,100 	; Get multiplier
	 mul	 SCNSIZE_EMSM	; Times amount of EMS-mappable memory
	 div	 SCNSIZE_TOT	; Divided by total amount
	 shl	 dx,1		; Times two to check for halfway

	 cmp	 SCNSIZE_TOT,dx ; Izit more than halfway?
	 adc	 ax,0		; Add if so
	 mov	 SCNPCT_EMSM,ax ; Save for later use

	 mov	 ax,100 	; Get multiplier
	 mul	 SCNSIZE_OVR	; Times amount of high DOS memory
	 div	 SCNSIZE_TOT	; Divided by total amount
	 shl	 dx,1		; Times two to check for halfway

	 cmp	 SCNSIZE_TOT,dx ; Izit more than halfway?
	 adc	 ax,0		; Add if so
	 mov	 SCNPCT_OVR,ax	; Save for later use

; Now ensure that the percentages add up to 100
; If the total if too high, subtract one from the largest percentage
; If the total if too low, add one to the largest percentage

ACT_ROM_ODDPCT:
	 mov	 ax,SCNPCT_VID	; Get video RAM percentage
	 add	 ax,SCNPCT_RAM	; Plus RAM ...
	 add	 ax,SCNPCT_ROM	; Plus ROM ...
	 add	 ax,SCNPCT_OTH	; Plus unused memory ...
	 add	 ax,SCNPCT_EMSM ; Plus EMS-mappable memory ...
	 add	 ax,SCNPCT_OVR	; Plus high DOS memory ...

; Find the largest one

	 mov	 dx,SCNPCT_VID	; Assume it's video RAM
	 lea	 di,SCNPCT_VID	; Save its offset

	 cmp	 dx,SCNPCT_RAM	; Izit larger than RAM?
	 jae	 short @F	; Jump if so

	 mov	 dx,SCNPCT_RAM	; Assume it's RAM
	 lea	 di,SCNPCT_RAM	; Save its offset
@@:
	 cmp	 dx,SCNPCT_ROM	; Izit larger than ROM?
	 jae	 short @F	; Jump if so

	 mov	 dx,SCNPCT_ROM	; Assume it's ROM
	 lea	 di,SCNPCT_ROM	; Save its offset
@@:
	 cmp	 dx,SCNPCT_OTH	; Izit larger than unused memory?
	 jae	 short @F	; Jump if so

	 mov	 dx,SCNPCT_OTH	; Assume it's unused memory
	 lea	 di,SCNPCT_OTH	; Save its offset
@@:
	 cmp	 dx,SCNPCT_EMSM ; Izit larger than EMS-mappable memory?
	 jae	 short @F	; Jump if so

	 mov	 dx,SCNPCT_EMSM ; Assume it's EMS-mappable memory
	 lea	 di,SCNPCT_EMSM ; Save its offset
@@:
	 cmp	 dx,SCNPCT_OVR	; Izit larger than high DOS memory?
	 jae	 short @F	; Jump if so

	 mov	 dx,SCNPCT_OVR	; Assume it's high DOS memory
	 lea	 di,SCNPCT_OVR	; Save its offset
@@:

; Check against 100 %

	 cmp	 ax,100 	; Izit even as yet?
	 je	 short ACT_ROM_EVEN ; Jump if so
	 jb	 short ACT_ROM_ODDLO ; Jump if it's too small

	 dec	 PGROUP:[di].ELO ; Subtract one from largest percentage

	 jmp	 short ACT_ROM_ODDPCT ; Go around again

ACT_ROM_ODDLO:
	 inc	 PGROUP:[di].ELO ; Add one to largest percentage

	 jmp	 short ACT_ROM_ODDPCT ; Go around again

ACT_ROM_EVEN:

; Format the high DOS memory summary percentages

	 mov	 ax,SCNPCT_VID	; Get video RAM percentage
	 lea	 di,MSG_SCNPCT_VID ; PGROUP:DI ==> output save area
	 mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 mov	 ax,SCNPCT_RAM	; Get RAM percentage
	 lea	 di,MSG_SCNPCT_RAM ; PGROUP:DI ==> output save area
;;;;;;;; mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 mov	 ax,SCNPCT_ROM	; Get ROM percentage
	 lea	 di,MSG_SCNPCT_ROM ; PGROUP:DI ==> output save area
;;;;;;;; mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 mov	 ax,SCNPCT_OTH	; Get unused percentage
	 lea	 di,MSG_SCNPCT_OTH ; PGROUP:DI ==> output save area
;;;;;;;; mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 mov	 ax,SCNPCT_EMSM ; Get EMS_mappable percentage
	 lea	 di,MSG_SCNPCT_EMSM ; PGROUP:DI ==> output save area
;;;;;;;; mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 mov	 ax,SCNPCT_OVR	; Get high DOS memory percentage
	 lea	 di,MSG_SCNPCT_OVR ; PGROUP:DI ==> output save area
;;;;;;;; mov	 cx,10		; Use base 10
	 call	 BIN2BASE	; Convert AX to binary at ES:DI

	 REGREST <di,dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_ROM_CALCOVRPCT endp 	; End ACT_ROM_CALCOVRPCT procedure
	 NPPROC  ACT_ROM_CALCEXTSUM -- Calculate and Format Extended Memory Summary Values
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate and format extended memory summary values

|

	 REGSAVE <ax,bx,cx,dx,di> ; Save registers

	 xor	 bx,bx		; Zero accumulator (CX,BX)
	 xor	 cx,cx		; ...

	 mov	 ax,SCNACCUM_EXTUP.ELO ; Get size of bottom up extended memory
	 mov	 dx,SCNACCUM_EXTUP.EHI ; ...
	 add	 bx,ax		; Add into accumulator
	 adc	 cx,dx		; ...
	 DD2DEC_MAC MSG_SCNSIZE_EXTUP ; Format (DX,AX) into MSG_SCNSIZE_EXTUP

	 mov	 ax,SCNACCUM_EXTMD.ELO ; Get size of middle out extended memory
	 mov	 dx,SCNACCUM_EXTMD.EHI ; ...
	 add	 bx,ax		; Add into accumulator
	 adc	 cx,dx		; ...
	 DD2DEC_MAC MSG_SCNSIZE_EXTMD ; Format (DX,AX) into MSG_SCNSIZE_EXTMD

	 mov	 ax,SCNACCUM_EXTDN.ELO ; Get size of top down extended memory
	 mov	 dx,SCNACCUM_EXTDN.EHI ; ...
	 add	 bx,ax		; Add into accumulator
	 adc	 cx,dx		; ...
	 DD2DEC_MAC MSG_SCNSIZE_EXTDN ; Format (DX,AX) into MSG_SCNSIZE_EXTDN

	 mov	 ax,SCNACCUM_HMA.ELO ; Get size of HMA (0 or 64KB)
	 mov	 dx,SCNACCUM_HMA.EHI ; ...
	 add	 bx,ax		; Add into accumulator
	 adc	 cx,dx		; ...
	 DD2DEC_MAC MSG_SCNSIZE_HMA ; Format (DX,AX) into MSG_SCNSIZE_HMA

	 mov	 ax,SCNACCUM_XMS.ELO ; Get size of allocated XMS memory
	 mov	 dx,SCNACCUM_XMS.EHI ; ...
	 add	 bx,ax		; Add into accumulator
	 adc	 cx,dx		; ...
	 DD2DEC_MAC MSG_SCNSIZE_XMS ; Format (DX,AX) into MSG_SCNSIZE_XMS

	 mov	 ax,SCNACCUM_EMS.ELO ; Get size of allocated EMS memory
	 mov	 dx,SCNACCUM_EMS.EHI ; ...
	 add	 bx,ax		; Add into accumulator
	 adc	 cx,dx		; ...
	 DD2DEC_MAC MSG_SCNSIZE_EMS ; Format (DX,AX) into MSG_SCNSIZE_EMS

	 mov	 ax,SCNACCUM_VCPI.ELO ; Get size of allocated VCPI memory
	 mov	 dx,SCNACCUM_VCPI.EHI ; ...
	 add	 bx,ax		; Add into accumulator
	 adc	 cx,dx		; ...
	 DD2DEC_MAC MSG_SCNSIZE_VCPI ; Format (DX,AX) into MSG_SCNSIZE_VCPI

	 mov	 ax,SCNACCUM_DPMI.ELO ; Get size of allocated DPMI memory
	 mov	 dx,SCNACCUM_DPMI.EHI ; ...
	 add	 bx,ax		; Add into accumulator
	 adc	 cx,dx		; ...
	 DD2DEC_MAC MSG_SCNSIZE_DPMI ; Format (DX,AX) into MSG_SCNSIZE_DPMI

	 mov	 ax,SCNACCUM_AVL.ELO ; Get size of unallocated memory
	 mov	 dx,SCNACCUM_AVL.EHI ; ...
	 add	 bx,ax		; Add into accumulator
	 adc	 cx,dx		; ...
	 DD2DEC_MAC MSG_SCNSIZE_AVL ; Format (DX,AX) into MSG_SCNSIZE_AVL

	 mov	 ax,SCNACCUM_ABS.ELO ; Get size of remapped memory
	 mov	 dx,SCNACCUM_ABS.EHI ; ...
	 add	 bx,ax		; Add into accumulator
	 adc	 cx,dx		; ...
	 DD2DEC_MAC MSG_SCNSIZE_ABS ; Format (DX,AX) into MSG_SCNSIZE_ABS

	 mov	 ax,SCNACCUM_PRG.ELO ; Get size of program storage
	 mov	 dx,SCNACCUM_PRG.EHI ; ...
	 add	 bx,ax		; Add into accumulator
	 adc	 cx,dx		; ...
	 DD2DEC_MAC MSG_SCNSIZE_PRG ; Format (DX,AX) into MSG_SCNSIZE_PRG

	 mov	 ax,bx		; Get total memory size
	 mov	 dx,cx		; ...
	 DD2DEC_MAC MSG_SCNSIZE_ETOT ; Format (DX,AX) into MSG_SCNSIZE_ETOT

	 REGREST <di,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_ROM_CALCEXTSUM endp 	; End ACT_ROM_CALCEXTSUM procedure
	 NPPROC  FMTOVR -- Format And Display Overlapping High DOS Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display overlapping high DOS memory.

On entry:

DS:SI	 ==>	 starting address in RAMTAB
DS:BX	 ==>	 ending+1 ...
CX	 =	 # overlapping high DOS markers

|

	 push	 offset PGROUP:SCNSIZE_OVR ; Pass ptr to accumulator
	 push	 offset PGROUP:SCNTYPE_OVR ; Pass ptr to type string
	 push	 mask $RAM_OVR	; Pass high DOS memory mask
	 call	 FMTOVRCOM	; Call common routine

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMTOVR	 endp			; End FMTOVR procedure
	 NPPROC  FMTROM -- Format And Display Overlapping ROM/PSM Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display overlapping ROM/PSM memory.

On entry:

DS:SI	 ==>	 starting address in RAMTAB
DS:BX	 ==>	 ending+1 ...
CX	 =	 # overlapping ROM/PSM markers

|

	 push	 offset PGROUP:SCNSIZE_ROM ; Pass ptr to accumulator
	 push	 offset PGROUP:SCNTYPE_ROM ; Pass ptr to type string
	 push	 ((mask $RAM_ROM) or (mask $RAM_PSM)) ; Pass ROM/PSM mask
	 call	 FMTOVRCOM	; Call common routine

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMTROM	 endp			; End FMTROM procedure
	 NPPROC  FMTOVRCOM -- Format And Display Overlapping Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display overlapping memory.

On entry:

DS:SI	 ==>	 starting address in RAMTAB
DS:BX	 ==>	 ending+1 ...
CX	 =	 # overlapping markers

|

FMTOVR_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
FMTOVR_MSK db	 ?,?		; Mask value for tests
FMTOVR_PTYP dw	 ?		; Ptr to type string
FMTOVR_PACC dw	 ?		; Ptr to accumulator

FMTOVR_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, mr. Stack

	 REGSAVE <ax,cx,dx,si,di> ; Save registers

	 jcxz	 FMTOVRCOM_EXIT ; Jump if none

	 lea	 dx,MSG_SCNLINE ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 call	 CLEAR_SCNLINE	; Clear the SCAN line

	 mov	 al,[bp].FMTOVR_MSK ; Get mask value

; Find the next overlapping memory marker

FMTOVRCOM_NEXT1:
	 test	 al,PGROUP:[si] ; Izit overlapping memory?
	 jnz	 short FMTOVRCOM1 ; Jump if so

	 inc	 si		; Skip to next entry

	 cmp	 si,bx		; Are we at the end as yet?
	 jb	 short FMTOVRCOM_NEXT1 ; Jump if not

; Find scope of overlapping memory

FMTOVRCOM1:
	 mov	 di,si		; Copy starting address
FMTOVRCOM_NEXT2:
	 test	 al,PGROUP:[di] ; Izit overlapping memory?
	 jz	 short FMTOVRCOM2 ; Jump if not

	 inc	 di		; Skip to next entry

	 loop	 FMTOVRCOM_NEXT2 ; Jump if more markers to check

COMMENT|

Register usage:

DS:SI	 ==>	 starting address of overlapping memory in RAMTAB
DS:DI	 ==>	 ending+1 ...
CX	 =	 # remaining overlapping entries beyond this one

|

FMTOVRCOM2:
	 REGSAVE <ax,cx,di>	; Save for a moment

	 mov	 cx,di		; Copy next address
	 sub	 cx,si		; Less starting address

	 mov	 al,'û'         ; Surrounding marker
	 mov	 di,[bp].FMTOVR_PTYP ; PGROUP:DI ==> scan type
	 call	 FMT_SCN	; Format scan line

	 shr	 cx,10-9	; Convert from 512B to 1KB
	 mov	 di,[bp].FMTOVR_PACC ; Get offset of accumulator
	 add	 PGROUP:[di],cx ; Add into total

	 REGREST <di,cx,ax>	; Restore

	 jcxz	 FMTOVRCOM_EXIT ; Jump if no more overlapping memory markers

	 lea	 dx,MSG_SCNLINE ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 call	 CLEAR_SCNLINE	; Clear the SCAN line

	 mov	 si,di		; Copy as new starting address

	 jmp	 short FMTOVRCOM_NEXT1 ; Go around again

FMTOVRCOM_EXIT:
	 REGREST <di,si,dx,cx,ax> ; Restore

	 pop	 bp		; Restore

	 ret	 2+2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMTOVRCOM endp			; End FMTOVRCOM procedure
	 NPPROC  CLEAR_SCNLINE -- Clear The SCAN Line
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill the MSG_SCNLINE with its initial value from MSG_LINE

|

	 REGSAVE <cx,si,di>	; Save registers

	 mov	 cx,MSG_LINE_LEN ; Length of line in bytes
	 lea	 si,MSG_LINE	; DS:SI ==> clean line
	 lea	 di,MSG_SCNLINE ; ES:DI ==> dirty line
S16  rep movsb			; Clean it up

	 REGREST <di,si,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEAR_SCNLINE endp		; End CLEAR_SCNLINE procedure
	 NPPROC  FMT_SCN -- Format Scan Line
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format scan line

On entry:

DS:DI	 ==>	 scan type
DS:SI	 ==>	 start of entry in table
CX	 =	 length in 512-bytes units
AL	 =	 surrounding marker

|

	 REGSAVE <eax,ecx,dx,di> ; Save registers

	 call	 COPY_SCN	; Copy scan type at DS:DI to MSG_SCNLINE

	 mov	 MSG_SCNOVR1,al ; Save overlap marker
	 mov	 MSG_SCNOVR2,al ; ...

	 movzx	 eax,si 	; Copy offset
	 sub	 ax,PRAMTAB	; Less starting address to get
				; starting point - A0000h in 512-bytes
	 shl	 eax,9-0	; Convert from 512-byte to bytes
	 add	 eax,0A0000h	; Convert to origin-0
	 movzx	 ecx,cx 	; Zero to use as dword
	 shl	 ecx,9-0	; Convert from 512-byte to paras

	 lea	 di,MSG_SCNADDR1 ; PGROUP:DI ==> output save area
	 call	 DD2HEXNZ	; Display dword in EAX at ES:DI w/o zero fill

	 add	 eax,ecx	; Plus length to neding address
	 lea	 di,MSG_SCNADDR2 ; PGROUP:DI ==> output save area
	 call	 DD2HEXNZ	; Display dword in EAX at ES:DI w/o zero fill

	 mov	 eax,ecx	; Get length in bytes
	 shr	 eax,10-0	; Convert from bytes to 1KB
	 ror	 eax,16 	; Rotate down high-order word
	 mov	 dx,ax		; Copy to DX for DD2DEC
	 rol	 eax,16 	; Rotate back
	 DD2DEC_MAC MSG_SCNSIZE ; Format (DX,AX) into MSG_SCNSIZE

	 REGREST <di,dx,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_SCN  endp			; End FMT_SCN procedure
	 NPPROC  COPY_SCN -- Copy Scan Type to MSG_SCNLINE
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy scan type to MSG_SCNLINE

On entry:

DS:DI	 ==>	 scan type

|

	 REGSAVE <cx,si,di>	; Save registers

	 mov	 si,di		; DS:SI ==> scan type source
	 lea	 di,MSG_SCNTYPE ; ES:DI ==> ...       destin
	 mov	 cx,SCNTYPE_LEN ; Length of ...
     rep movsb			; Copy scan type

	 REGREST <di,si,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_SCN endp			; End COPY_SCN procedure
	 NPPROC  MARK_HIGH -- Mark High DOS Memory
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Mark high DOS memory areas.

|

	 REGSAVE <ax,bx,cx,si>	; Save registers

	 mov	 si,PMCSTAB	; DS:SI ==> memory chain structure
	 mov	 cx,MCSTAB_CNT	; CX = # entries in MCSTAB
MARK_HIGH1:
	 test	 ds:[si].MCS_FLAG,@MCS_HOLE ; Izit a hole (end of the chain)?
	 jnz	 short MARK_HIGH_EXIT ; Yes, skip out

	 test	 ds:[si].MCS_FLAG,@MCS_AVAIL ; Izit available?
	 jz	 short MARK_HIGH_LOOP ; No, skip it

	 mov	 bx,ds:[si].MCS_PARA ; Get paragraph #

	 sub	 bx,0A000h	; Convert to origin-A000
	 jc	 short MARK_HIGH_LOOP ; Jump if below 640KB

	 shr	 bx,9-4 	; Convert from paras to 512-bytes
	 add	 bx,PRAMTAB	; DS:BX ==> corresponding entry in RAMTAB

	 push	 cx		; Save for a moment

	 mov	 cx,ds:[si].MCS_NPAR ; Get # paragraphs
	 shr	 cx,9-4 	; Convert from paras to 512-bytes
	 mov	 al,mask $RAM_OVR ; Use high DOS memory marker
@@:
	 or	 PGROUP:[bx],al ; Mark as high DOS memory
	 inc	 bx		; Skip to next entry

	 loop	 @B		; Jump if more 512-byte blocks in the ROM

	 pop	 cx		; Restore
MARK_HIGH_LOOP:
	 add	 si,size MCS_STR ; Skip to next entry

	 loop	 MARK_HIGH1	; Jump if more entries
MARK_HIGH_EXIT:
	 REGREST <si,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

MARK_HIGH endp			; End MARK_HIGH procedure
	 NPPROC  IZITEGA -- Check For Presence of EGA
	 assume  ds:nothing,es:nothing,ss:nothing
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

	 assume  ds:nothing,es:nothing,ss:nothing

IZITEGA  endp			; End IZITEGA procedure
	 NPPROC  CHK_CREG -- Check Cursor Register DX For Adapter Presence
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <ax,dx>	; Save registers

	 mov	 al,0Fh 	; Set CRTC to address cursor register
	 out	 dx,al		; Tell CRTC about it
	 inc	 dx		; Point to data register
	 jmp	 short $+2	; I/O delay for PC AT
	 jmp	 short $+2
	 jmp	 short $+2

	 in	 al,dx		; Save original value
	 push	 ax		; on the stack
	 mov	 al,5Ah 	; Test value for cursor position
	 out	 dx,al		; Tell CRTC about it
	 jmp	 short $+2	; I/O delay for PC AT
	 jmp	 short $+2
	 jmp	 short $+2

	 in	 al,dx		; Read it back in

	 cmp	 al,5Ah 	; Check against test value
	 pop	 ax		; Restore original cursor value
	 jmp	 short $+2	; I/O delay for PC AT
	 jmp	 short $+2
	 jmp	 short $+2

	 out	 dx,al		; Restore original value in CRTC
	 jne	 short CHK_CREG_NO ; Not present

	 clc			; Indicate it's present
	 jmp	 short CHK_CREG_EXIT ; Join common exit code

CHK_CREG_NO:
	 stc			; Indicate it's not present
CHK_CREG_EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHK_CREG endp			; End CHK_CREG procedure
	 NPPROC  DW2HEXNZ -- Convert Word to Hex Without Zero Fill
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert word to hex without zero fill.

On entry:

AX	 =	 value to convert
ES:DI	 ==>	 output save area

On exit:

ES:DI	 ==>	 byte to right of converted number

|

	 REGSAVE <bx,cx>	; Save registers

	 mov	 bx,di		; Save original offset

	 call	 DW2HEX 	; Display word in AX at ES:DI

	 mov	 cx,4-1 	; # digits to look at
DW2HEXNZ_NEXT:
	 cmp	 es:[bx].LO,'0' ; Izit a leading zero?
	 jne	 short DW2HEXNZ_EXIT ; Jump if not

	 mov	 es:[bx].LO,' ' ; Fill with a blank

	 inc	 bx		; Skip to next byte

	 loop	 DW2HEXNZ_NEXT	; Jump if more leading bytes to check
DW2HEXNZ_EXIT:
	 REGREST <cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DW2HEXNZ endp			; End DW2HEXNZ procedure
	 NPPROC  DD2HEXNZ -- Convert Dword to Hex Without Zero Fill
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert dword to hex without zero fill.

On entry:

EAX	 =	 value to convert
ES:DI	 ==>	 output save area

On exit:

ES:DI	 ==>	 byte to right of converted number

|

	 REGSAVE <bx,cx>	; Save registers

	 mov	 bx,di		; Save original offset

	 call	 DD2HEX 	; Display dword in EAX at ES:DI

	 mov	 cx,8-1 	; # digits to look at
DD2HEXNZ_NEXT:
	 cmp	 es:[bx].LO,'0' ; Izit a leading zero?
	 jne	 short DD2HEXNZ_EXIT ; Jump if not

	 mov	 es:[bx].LO,' ' ; Fill with a blank

	 inc	 bx		; Skip to next byte

	 loop	 DD2HEXNZ_NEXT	; Jump if more leading bytes to check
DD2HEXNZ_EXIT:
	 REGREST <cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2HEXNZ endp			; End DD2HEXNZ procedure

CODE	 ends			; End CODE segment
endif				; IF @OEM_ROMSCAN

	 MEND			; End UTIL_ROM module
