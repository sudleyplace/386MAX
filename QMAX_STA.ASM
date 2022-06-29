;' $Header:   P:/PVCS/MAX/386MAX/QMAX_STA.ASV   1.3   30 May 1997 10:46:02   BOB  $
	 title	 QMAX_STA -- 386MAX Statistics Routines
	 page	 58,122
	 name	 QMAX_STA

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Program segment NCODE, byte-aligned,  public, class 'ncode'
	       Data    segment NDATA, dword-aligned, public, class 'ndata'
	       Group XGROUP:
	       Program segment XCODE,	byte-aligned,  public, class 'xcode'
	       Data    segment XDATA,	dword-aligned, public, class 'xdata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include VIDCALL.INC
	 include ASCII.INC
	 include 386.INC
	 include PTR.INC
	 include VIDATTR.INC
NOVER_HTU = 1
	 include VERSION.INC

	 include QMAX_OEM.INC
	 include QMAX_MCS.INC
if @OEM_BETA
	 include VERSBETA.INC
else
	 extrn	 VERSLTR1:abs
	 extrn	 VERSLTR2:abs
endif				; IF @OEM_BETA
.list

PGROUP	 group	 CODE,ECODE,EDATA,NCODE,NDATA
XGROUP	 group	 XCODE,XDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 EXTSIZE:dword
if @OEM_EMS
	 extrn	 EMMSIZE:dword
endif				; IF @OEM_EMS
	 extrn	 LOWSIZE:word
	 extrn	 OVRSIZE:word
if @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 MAPSIZE:word
	 extrn	 PRGSIZE:word
	 extrn	 SHDSIZE:word
	 extrn	 XSHDSIZE:word
endif				; if @OEM_SYS eq @OEMSYS_HPRS

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 HEXTABLE:byte

if @OEM_SYS eq @OEMSYS_ILIM or @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 PHYSIZE:dword
	 extrn	 NPHYSCNV:byte
endif				; if @OEM_SYS eq @OEMSYS_ILIM
if @OEM_EMS
	 extrn	 NPHYS16F:byte
	 extrn	 FRAME:word
endif				; IF @OEM_EMS
	 extrn	 LOWOFF:dword

COMMENT|

Here's how the English version looks on the screen:

’Õ 386MAX ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ Memory Usage Õ∏
≥⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒ The First Megabyte of Address Space ƒƒƒƒƒƒƒƒƒƒƒƒƒƒø≥
≥≥€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€≤≤≤≤≤≤≤≤˜˜˜˜˜˜˜˜˛±±±±±±±!!!!˛˛˛˛≥≥
≥¿≈ƒConventional memoryƒƒƒƒƒƒƒƒƒƒƒ≈Lowƒƒƒƒ≈Videoƒƒ≈≈Highƒƒ≈Oth≈ROMŸ≥
≥								   ≥
≥ New top of DOS memory     =	640 KB	      € DOS	   ˜ Video ≥
≥ Added low  DOS memory     =	736 KB	      ≤ Low	   ˛ ROM   ≥
≥ Added high DOS memory     =	192 KB	      ± High		   ≥
≥ Available Extended memory =	  0 KB	      ! Other	   # Unused≥
≥ Available Shared   memory =	992 KB	  Frame = E000	   ∞ EMS   ≥
‘ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ (C) Copyright 1987-98 Qualitas, Inc. Õæ

----> Here's how the GERMAN screen MUST look:
----> please modify ur code accordingly !
----> make the A   B   C's fit into the appropriate positions !
----> 'B' and 'Byte' are nouns and ALLWAYS in UPcase,
----> our plural form of 'byte' is 'Byte', not 'Bytes'.

’Õ 386MAX ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ Speicher-Belegung Õ∏
≥⁄ƒƒ 1. MB des Adress-Raums ƒƒƒƒƒ A    B    C	 D    E    F ƒƒƒƒƒø≥
≥≥€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€≤≤≤≤≤≤≤≤˜˜˜˜˜˜˜˜˛±±±±±±±!!!!˛˛˛˛≥≥
≥¿≈ƒ konventioneller Speicher ƒƒƒƒ≈LoDOSƒƒ≈Videoƒƒ≈≈HiDOSƒ≈and≈ROMŸ≥
≥								   ≥
≥ neue DOS-Obergrenze	    =	640 KB	      € DOS	   ˜ Video ≥
≥ zusÑtzl. LoDos-Speicher   =	736 KB	      ≤ LoDos	   ˛ ROM   ≥
≥ zusÑtzl. HiDos-Speicher   =	192 KB	      ± HiDos		   ≥
≥ verfÅgb. Extended Memory  =	  0 KB	      ! andere	   # unben.≥
≥ verfÅgb. dynam. Speicher  =	992 KB	 Rahmen = E000	   ∞ EMS   ≥
‘ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ (C) Copyright 1987-98 Qualitas, Inc. Õæ

|

	 public  MSG_STAT
if @OEM_SYS eq @OEMSYS_AST386
MSG_STAT db	 EOS
MSG_AST  db	 '’ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ∏',CR,LF
MSG_ASTLEN equ	 $-MSG_AST-2
MSG_AST1 db	 '≥ ',@OEM_TEXT,' -- Version '
	 db	 VERS_H,'.',VERS_T,VERS_U
	 db	 (MSG_AST1[MSG_ASTLEN-1]-$) dup (' '),'≥',CR,LF
	 db	 '≥ (C) Copyright 1987-98 Qualitas, Inc.    ≥',CR,LF
ifdef LANG_GR
	 db	 '≥ Alle Rechte vorbehalten.                ≥',CR,LF
	 db	 '≥  verfÅgb. Extended Memory =    _'
else
	 db	 '≥ All rights reserved.                    ≥',CR,LF
	 db	 '≥ Available Extended Memory =    _'
endif				; IFDEF LANG_GR
	 public  MSG_EAVL
MSG_EAVL db	 ' KB     ≥',CR,LF
ifdef LANG_GR
	 db	 '≥  verfÅgb. dynam. Speicher =    _'
else
	 db	 '≥ Available Shared   Memory =    _'
endif				; IFDEF LANG_GR
MSG_XAVL db	 ' KB     ≥',CR,LF
	 db	 '‘ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕæ',CR,LF
	 db	 EOS
elseif @OEM_SYS eq @OEMSYS_ILIM
MSG_STAT db	 CR,LF,CR,LF
ifdef LANG_GR
	 db	 @OEM_FILE,' legte      _ '
MSG_EPHY db	 'KB des gesamten Systemspeichers wie folgt an:',CR,LF
	 db	 CR,LF
	 db	 '    _ '
MSG_OTOP db	 'KB sind konventioneller Speicher, aufgefÅllt auf '
	 db	 '    _ '
MSG_NTOP db	 'KB,',CR,LF
	 db	 '    _ '
MSG_ETOT db	 'KB sind Erweiterungs-Speicher, wovon ',CR,LF,CR,LF
	 db	 '     '
	 db	 '     _ '
MSG_RPRG db	 'KB vom Einheitentreiber ',@OEM_FILE,' belegt wurden,',CR,LF
MSG_FIL0 db	 '     '
	 db	 '     _ '
MSG_FILL db	 'KB dem konventionellen Speicher zugeschlagen wurden,',CR,LF
MSG_FILZ db	 '     '
	 db	 '     _ '
MSG_EAVL db	 'KB als Extended Memory verfÅgbar sind,',CR,LF
	 db	 '     '
	 db	 '     _ '
MSG_XAVL db	 'KB als dynamischer Speicher verfÅgbar sind,',CR,LF
else
	 db	 @OEM_FILE,' has set up     _'
MSG_EPHY db	 'K bytes of total system memory as follows:',CR,LF
	 db	 CR,LF
	 db	 '    _'
MSG_OTOP db	 'K bytes are conventional memory, backfilled to '
	 db	 '    _'
MSG_NTOP db	 'K',CR,LF
	 db	 '    _'
MSG_ETOT db	 'K bytes are extended memory, of which:',CR,LF,CR,LF
	 db	 '     '
	 db	 '     _'
MSG_RPRG db	 'K bytes are used by the ',@OEM_FILE,' device driver',CR,LF
MSG_FIL0 db	 '     '
	 db	 '     _'
MSG_FILL db	 'K bytes are used to fill conventional memory',CR,LF
MSG_FILZ db	 '     '
	 db	 '     _'
MSG_EAVL db	 'K bytes are available as extended memory',CR,LF
	 db	 '     '
	 db	 '     _'
MSG_XAVL db	 'K bytes are available as shared   memory',CR,LF
endif				; IFDEF LANG_GR
	 db	 EOS
MSG_STATZ label  byte

elseif @OEM_SYS eq @OEMSYS_HPRS
MSG_STAT db	 EOS

ifdef LANG_GR

MSG_B640 db	 '  640 KB Basis-Hauptspeicher,',CR,LF,EOS

MSG_BEXP0 db	 '       '
MSG_BEXP db	 ' KB sind nutzbar als Expanded Memory,',CR,LF,EOS

MSG_RPRV0 db	 '  384 KB sind reservierter Speicher,',CR,LF
	 db	 '       '
MSG_RPRV db	 ' KB wurden bereits vorab belegt,',CR,LF,EOS

MSG_REXP0 db	 '       '
MSG_REXP db	 ' KB wurden in Expanded Memory umgewandelt,',CR,LF,EOS

MSG_RPRG0 db	 '       '
MSG_RPRG db	 ' KB sind belegt von ',@OEM_FILE,CR,LF,EOS

MSG_REXT0 db	 '       '
MSG_REXT db	 ' KB wurden in Extended Memory umgewandelt',CR,LF,EOS

MSG_ETOT0 db	 '    0'
MSG_ETOT db	 ' KB sind Extended Memory',CR,LF,EOS

MSG_EPRV0 db	 '      0'
MSG_EPRV db	 ' KB wurden bereits vorab belegt',CR,LF,EOS

MSG_EEXP0 db	 '      0'
MSG_EEXP db	 ' KB wurden in Expanded Memory umgewandelt',CR,LF,EOS

else

MSG_B640 db	 '  640K Base Memory',CR,LF,EOS

MSG_BEXP0 db	 '       '
MSG_BEXP db	 'K Usable as Expanded Memory',CR,LF,EOS

MSG_RPRV0 db	 '  384K Reserved Memory',CR,LF
	 db	 '       '
MSG_RPRV db	 'K Previously Allocated',CR,LF,EOS

MSG_REXP0 db	 '       '
MSG_REXP db	 'K Converted to Expanded Memory',CR,LF,EOS

MSG_RPRG0 db	 '       '
MSG_RPRG db	 'K Occupied by ',@OEM_FILE,CR,LF,EOS

MSG_REXT0 db	 '       '
MSG_REXT db	 'K Converted to Extended Memory',CR,LF,EOS

MSG_ETOT0 db	 '    0'
MSG_ETOT db	 'K Extended memory',CR,LF,EOS

MSG_EPRV0 db	 '      0'
MSG_EPRV db	 'K Previously Allocated',CR,LF,EOS

MSG_EEXP0 db	 '      0'
MSG_EEXP db	 'K Converted to Expanded Memory',CR,LF,EOS

endif				; IFDEF LANG_GR
	 public  MSG_EAVL
MSG_EAVL0 db	 '      0'
ifdef LANG_GR
MSG_EAVL db	 ' KB sind verfÅgbar',CR,LF,EOS
else
MSG_EAVL db	 'K Available',CR,LF,EOS
endif				; IFDEF LANG_GR

MSG_XAVL0 db	 '     '
ifdef LANG_GR
MSG_XAVL db	 ' KB sind als Expanded Memory verfÅgbar',CR,LF,EOS
else
MSG_XAVL db	 'K Expanded Memory Available',CR,LF,EOS
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_LHY
MSG_STAT db	 EOS
else

if @OEM_SYS eq @OEMSYS_OL2
MSG_STAT db	 '’Õ Version ',VERS_H,'.',VERS_T,VERS_U,' '
else
MSG_STAT db	 '’Õ ',@OEM_TEXT,' ÕÕÕ Version ',VERS_H,'.',VERS_T,VERS_U
if @OEM_BETA
	 db	 '.',BETA_H,BETA_T,BETA_U,'·'
	 db	 ' '
else
	 db	 VERSLTR1,VERSLTR2
endif				; IF @OEM_BETA
endif				; IF @OEM_SYS eq @OEMSYS_OL2
ifdef LANG_GR
	 db	 (MSG_STAT+68-21-$) dup ('Õ')
	 db	 ' Speicher-Belegung Õ∏',CR,LF
	 db	 '≥⁄≈<ƒƒƒ 1. MB des Adress-Raums ƒƒƒƒƒƒƒƒƒƒƒAƒƒƒBƒƒƒCƒƒƒDƒƒƒEƒƒƒFƒ>≈ø≥',CR,LF
MSG_LINE db	 '≥≥!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!≥≥',CR,LF
MSG_TEXT db	 '≥¿≈<ƒƒƒƒ konventioneller Speicher ƒƒƒƒƒƒƒ>≈ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ≥',CR,LF
	 db	 '≥                                                                  ≥',CR,LF
	 db	 '≥ neue DOS Obergrenze       =     _'
MSG_NTOP db	 ' KB        '
CHAR_DOS db	 '_ DOS        '
CHAR_VID db	 '_ Video ≥',CR,LF
	 db	 '≥ zusÑtzl. LoDOS Speicher   =     _'
MSG_CLO  db	 ' KB        '
CHAR_LOW db	 '_ LoDOS      '
CHAR_ROM db	 '_ ROM   ≥',CR,LF
else
	 db	 (MSG_STAT+68-16-$) dup ('Õ')
	 db	 ' Memory Usage Õ∏',CR,LF
	 db	 '≥⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒ The First Megabyte of Address Space ƒƒƒƒƒƒƒƒƒƒƒƒƒƒø≥',CR,LF
MSG_LINE db	 '≥≥!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!≥≥',CR,LF
MSG_TEXT db	 '≥¿≈ƒConventional memoryƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ≥',CR,LF
	 db	 '≥                                                                  ≥',CR,LF
	 db	 '≥ New top of DOS memory     =     _'
MSG_NTOP db	 ' KB        '
CHAR_DOS db	 '_ DOS        '
CHAR_VID db	 '_ Video ≥',CR,LF
	 db	 '≥ Added low  DOS memory     =     _'
MSG_CLO  db	 ' KB        '
CHAR_LOW db	 '_ Low        '
CHAR_ROM db	 '_ ROM   ≥',CR,LF
endif				; IFDEF LANG_GR
if @OEM_HIFILL
ifdef LANG_GR
	 db	 '≥ zusÑtzl. HiDOS Speicher   =     _'
MSG_CHI  db	 ' KB        '
CHAR_OVR db	 '_ HiDOS              ≥',CR,LF
else
	 db	 '≥ Added high DOS memory     =     _'
MSG_CHI  db	 ' KB        '
CHAR_OVR db	 '_ High               ≥',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_HIFILL
ifdef LANG_GR
	 db	 '≥ verfÅgb. Extended Memory  =     _'
	 public  MSG_EAVL
MSG_EAVL db	 ' KB        '
CHAR_OTH db	 '_ andere     '
CHAR_UNU db	 '_ unben.≥',CR,LF
else
	 db	 '≥ Available Extended memory =     _'
	 public  MSG_EAVL
MSG_EAVL db	 ' KB        '
CHAR_OTH db	 '_ Other      '
CHAR_UNU db	 '_ Unused≥',CR,LF
endif				; IFDEF LANG_GR

if @OEM_EMS
ifdef LANG_GR
	 db	 '≥ verfÅgb. dynam. Speicher  =     _'
MSG_EEXP db	 ' KB   Rahmen = ____'
MSG_FRAM db	 '     '
CHAR_EMS db	 '_ EMS   ≥',CR,LF
else
	 db	 '≥ Available Shared   memory =     _'
MSG_EEXP db	 ' KB    Frame = ____'
MSG_FRAM db	 '     '
CHAR_EMS db	 '_ EMS   ≥',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_EMS
				; IF @OEM_SYS eq @OEMSYS_LHY
				; IF @OEM_SYS eq @OEMSYS_HPRS
				; IF @OEM_SYS eq @OEMSYS_ILIM
endif				; IF @OEM_SYS eq @OEMSYS_AST386

	 public  MSG1,ROWLEN
if @OEM_SYS eq @OEMSYS_3COM
MSG1	 db	 '‘ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕæ',CR,LF
else
MSG1	 db	 '‘ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ (C) Copyright 1987-98 Qualitas, Inc. Õæ',CR,LF
endif				; IF @OEM_SYS eq @OEMSYS_3COM
ROWLEN	 equ	 $-MSG1 	; Row length in message
	 db	 EOS

	 public  MSG_STATLEN
MSG_STATLEN equ  $-MSG_STAT

	 public  @MSG_STAT_ROWCNT
@MSG_STAT_ROWCNT equ (MSG_STATLEN/ROWLEN)

EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_STA_ECODE
@QMAX_STA_ECODE:nop		; Mark module start in .MAP file

	 NPPROC  BIN2BASE -- Convert From Binary to Specified Base
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIN2BASE -- Convert the number in AX to ASCII in base CX storing the
low-order digit of the # at ES:DI.

On exit:

ES:DI	 ==>	 next byte below last one stored

|

	 REGSAVE <ax,cx,dx,si>	; Save registers

	 pushf			; Save all flags
	 std			; Direction backwards for MOVSB
BIN2BASE_LOOP:
	 xor	 dx,dx		; Zero high-order word for division
	 div	 cx		; Divide by number base
				; DX has remainder, AX has quotient
	 lea	 si,HEXTABLE	; Get address of table
	 add	 si,dx		; Offset into table

S16	 movs	 <es:[di].LO,HEXTABLE[si]> ; Store in result

	 and	 ax,ax		; Check for zero quotient
	 jnz	 short BIN2BASE_LOOP ; Not done yet
BIN2BASE_EXIT:
	 popf			; Restore flags

	 REGREST <si,dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2BASE endp			; End BIN2BASE procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 NRD_FLAG:dword
	 include QMAX_NRD.INC

	 public  MEM_MAP,MEM_MAP_LEN
MEM_MAP  db	 (1024*(1024/512)) dup (0) ; 1MB memory map in 512-byte blocks
MEM_MAP_LEN equ  $-MEM_MAP

if @OEM_SYS eq @OEMSYS_HPRS
	 public  REXP,REXT,ETOT
REXP	 dd	 0		; Size of EMS memory in reserved area in 1KB
REXT	 dd	 0		; Size of extended ...
ETOT	 dd	 ?		; Size of total extended memory
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

	 public  XLAT_MAP,XLAT_FLAG
;		  01234567890123
XLAT_MAP db	 '?€≤˜±˛˛˛Ë∞##∞##'; Translate table for MEM_MAP
XLAT_FLAG db	 0			;  0 = Unknown
	 db	 0			;  1 = DOS existing
	 db	 0			;  2 = DOS low memory
	 db	 0			;  3 = Video memory
	 db	 @MCS_AVAIL		;  4 = DOS high memory
	 db	 @MCS_UNAVL or @MCS_ROM ;  5 = ROM 1st entry, no other ROM
	 db	 @MCS_UNAVL or @MCS_ROM ;  6 = ROM 1st entry
	 db	 @MCS_UNAVL or @MCS_ROM ;  7 = ROM 2nd and subsequent entry
	 db	 @MCS_UNAVL or @MCS_RAM ;  8 = Other RAM above video
	 db	 @MCS_UNAVL		;  9 = EMS frame above video
	 db	 @MCS_UNAVL		; 10 = Excised high DOS memory
	 db	 @MCS_UNAVL		; 11 = Excised low  DOS memory
	 db	 @MCS_INCL		; 12 = INCLUDEd memory
	 db	 @MCS_EXCL		; 13 = EXCLUDEd memory
	 db	 @MCS_UNAVL		; 14 = PSM memory

	 public  @XLAT_UNK,@XLAT_DOS,@XLAT_LOW,@XLAT_VID
	 public  @XLAT_OVR,@XLAT_ROM0,@XLAT_ROM1,@XLAT_ROM2,@XLAT_OTH
	 public  @XLAT_EMS,@XLAT_XLO,@XLAT_XHI,@XLAT_INC,@XLAT_EXC
	 public  @XLAT_PSM
@XLAT_UNK equ	 0		; Unknown memory type
@XLAT_DOS equ	 1		; Existing DOS memory
@XLAT_LOW equ	 2		; Additional DOS low memory
@XLAT_VID equ	 3		; Video memory
@XLAT_OVR equ	 4		; Additional DOS high memory
@XLAT_ROM0 equ	 5		; ROM 1st entry, no other ROM
@XLAT_ROM1 equ	 6		; ROM 1st entry
@XLAT_ROM2 equ	 7		; ROM 2nd and subsequent entry
@XLAT_OTH equ	 8		; Other RAM above video memory
@XLAT_EMS equ	 9		; EMS frame above video memory
@XLAT_XLO equ	 10		; Excised low  DOS memory
@XLAT_XHI equ	 11		; Excised high DOS memory
@XLAT_INC equ	 12		; INCLUDEd memory
@XLAT_EXC equ	 13		; EXCLUDEd memory
@XLAT_PSM equ	 14		; PSM memory

NDATA	 ends			; End NDATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 public  @QMAX_STA_NCODE
@QMAX_STA_NCODE:nop		; Mark module start in .MAP file

	 extrn	 DISP_COLOR:near

	 FPPROC  FDISP_COLOR -- Far Call to DISP_COLOR
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to DISP_COLOR

|

DP_STR	 struc

	 dw	 ?		; Caller's BP
	 dd	 ?		; ...	   CS:IP
DP_ARG	 dw	 ?		; ...	   argument

DP_STR	 ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 push	 [bp].DP_ARG	; Pass same argument
	 call	 DISP_COLOR	; Display string in color

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDISP_COLOR endp		; End FDISP_COLOR procedure
	 FPPROC  FBIN2BASE -- Convert From Binary to Specified Base
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

FBIN2BASE -- Convert the number in AX to ASCII in base CX storing the
low-order digit of the # at ES:DI.

On exit:

ES:DI	 ==>	 next byte below last one stored

|

	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FBIN2BASE endp			; End FBIN2BASE procedure

NCODE	 ends			; End NCODE segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

if @OEM_SYS ne @OEMSYS_ILIM
	 public  LOWTEXT,OVRTEXT,EGATEXT,VIDTEXT,ROMTEXT,OTHTEXT,UNKTEXT
ifdef LANG_GR
LOWTEXT  db	 '≈Loƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
OVRTEXT  db	 '≈Hiƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
EGATEXT  db	 '≈EGAƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
VIDTEXT  db	 '≈Videoƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
ROMTEXT  db	 '≈ROMƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
OTHTEXT  db	 '≈and.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
UNKTEXT  db	 '≈unbek.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
else
LOWTEXT  db	 '≈Lowƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
OVRTEXT  db	 '≈Highƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
EGATEXT  db	 '≈EGAƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
VIDTEXT  db	 '≈Videoƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
ROMTEXT  db	 '≈ROMƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
OTHTEXT  db	 '≈Otherƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
UNKTEXT  db	 '≈Unknownƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
endif				; IFDEF LANG_GR

if @OEM_EMS
	 public  EMSTEXT
EMSTEXT  db	 '≈EMS'
endif				; IF @OEM_EMS

	 public  XLOTEXT
if @OEM_LOFILL
ifdef LANG_GR
XLOTEXT  db	 '≈NoLoƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
else
XLOTEXT  db	 '≈Nolowƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
XLOTEXT  db	 '≈unben.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
else
XLOTEXT  db	 '≈Unusedƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
endif				; IFDEF LANG_GR
endif				; IF @OEM_LOFILL

	 public  XHITEXT
if @OEM_HIFILL
ifdef LANG_GR
XHITEXT  db	 '≈NoHiƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
else
XHITEXT  db	 '≈Nohighƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
XHITEXT  db	 '≈unben.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
else
XHITEXT  db	 '≈Unusedƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
endif				; IFDEF LANG_GR
endif				; IF @OEM_HIFILL

	 public  INCTEXT,EXCTEXT
ifdef LANG_GR
INCTEXT  db	 '≈einschl.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
EXCTEXT  db	 '≈ausschl.ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
else
INCTEXT  db	 '≈Inclƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
EXCTEXT  db	 '≈Exclƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
endif				; IFDEF LANG_GR

if @OEM_SYS eq @OEMSYS_RET
	 public  PSMTEXT
PSMTEXT  db	 '≈PSƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ'
endif				; IF @OEM_SYS eq @OEMSYS_RET
endif				; IF @OEM_SYS ne @OEMSYS_ILIM

XDATA	 ends			; End XDATA segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 public  @QMAX_STA_XCODE
@QMAX_STA_XCODE:nop		; Mark module start in .MAP file

	 NPPROC  BIND2BASE -- Convert From Binary to Specified Base
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIND2BASE -- Convert the number in EAX to ASCII in base CX storing the
low-order digit of the # at ES:DI.

On exit:

ES:DI	 ==>	 next byte below last one stored

|

	 REGSAVE <eax,ecx,edx,si,ds> ; Save registers

	 mov	 dx,seg PGROUP	; Get segment of HEXTABLE
	 mov	 ds,dx		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 pushf			; Save all flags
	 std			; Direction backwards for MOVSB

	 movzx	 ecx,cx 	; Zero to use as dword
BIND2BASE_LOOP:
	 xor	 edx,edx	; Zero high-order dword for division
	 div	 ecx		; Divide by number base
				; EDX has remainder, EAX has quotient
	 lea	 si,HEXTABLE	; Get address of table
	 add	 si,dx		; Offset into table

S16	 movs	 <es:[di].LO,HEXTABLE[si]> ; Store in result

	 and	 eax,eax	; Check for zero quotient
	 jnz	 short BIND2BASE_LOOP ; Not done yet
BIND2BASE_EXIT:
	 popf			; Restore flags

	 REGREST <ds,si,edx,ecx,eax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIND2BASE endp			; End BIND2BASE procedure
	 FPPROC  CALC_STAT -- Calculate Statistics
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate statistics.

|

	 REGSAVE <eax,ebx,cx,dx,di,fs> ; Save registers

	 push	 seg XGROUP	; Get extra data segment
	 pop	 fs		; Address it
	 assume  fs:XGROUP	; Tell the assembler about it

if @OEM_SYS eq @OEMSYS_AST386

; EAVL = EXTSIZE

	 mov	 eax,EXTSIZE	; Get size of available extended memory
	 lea	 di,MSG_EAVL-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

; XAVL = EMMSIZE

	 mov	 eax,EMMSIZE	; Get size of available EMS memory
	 lea	 di,MSG_XAVL-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 push	 offset ds:MSG_AST ; Pass offset of string
	 call	 FDISP_COLOR	; Display string in color

elseif @OEM_SYS eq @OEMSYS_HPRS

	 mov	 eax,PHYSIZE	; Check total amount of physical memory
	 sub	 eax,1024	; Less the first megabyte
	 mov	 ETOT,eax	; Save as total extended memory
	 jnz	 short CALC_STAT_1MB ; Jump if it's not a 1MB system

	 or	 NRD_FLAG,@NRD_1MB ; Mark as a 1MB system
CALC_STAT_1MB:
	 DOSCALL @STROUT,MSG_B640 ; Display to user

; BEXP = NPHYSCNV * 16

	 cmp	 EMMSIZE,0	; Any EMS memory to manage?
	 je	 short CALC_STAT_BEXP0 ; Not this time

	 mov	 ax,NPHYSCNV.ELO ; Get # physical 16KB pages in conventional memory

	 shl	 ax,14-10	; Convert from 16KB to 1KB
	 jz	 short CALC_STAT_BEXP0 ; None this time

	 lea	 di,MSG_BEXP-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

	 DOSCALL @STROUT,MSG_BEXP0 ; Display to user
CALC_STAT_BEXP0:

; RPRV = 384 - (SHDSIZE - XSHDSIZE) + MAPSIZE/16*16 + max(LOWSIZE, 0)
; unless SHDSIZE = 0, in which
; RPRV = 384

	 mov	 ax,384 	; Get size of reserved area
	 mov	 dx,SHDSIZE	; Get size of shadow RAM

	 sub	 dx,XSHDSIZE	; Less excluded shadow memory
	 jz	 short CALC_STAT_RPRV0 ; Yes, we have no shadow RAM

	 sub	 ax,dx		; Less size of shadow RAM
	 mov	 dx,MAPSIZE	; Get size of ROM mapping region
	 and	 dx,not (16-1)	; Round down to 16KB boundary in case of NWB
	 add	 ax,dx		; Plus size of ROM mapping region

	 cmp	 LOWSIZE,0	; Check the sign
	 jle	 short CALC_STAT_RPRV0 ; Jump if there's nothing to fill

	 add	 ax,LOWSIZE	; Plus size of low DOS region
CALC_STAT_RPRV0:
	 lea	 di,MSG_RPRV-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

	 DOSCALL @STROUT,MSG_RPRV0 ; Display to user

; REXP = max((SHDSIZE - XSHDSIZE) - PRGSIZE - MAPSIZE/16*16 - max(LOWSIZE, 0), 0)/16*16
; REXP = min(EMMSIZE, REXP)
; unless it's not a 1MB system in which case PRGSIZE is taken from ETOT

	 movzx	 eax,SHDSIZE	; Get amount of shadow RAM
	 sub	 ax,XSHDSIZE	; Less excluded shadow memory
	 mov	 ebx,eax	; Save as available extended memory

	 test	 NRD_FLAG,@NRD_1MB ; Izit a 1MB system?
	 jz	 short CALC_STAT_1MB1 ; No, allocate RPRG to ETOT

	 sub	 ax,PRGSIZE	; Less amount used for program
	 jc	 short CALC_STAT_REXP_END ; Too small

	 mov	 ebx,eax	; Save as available extended memory
CALC_STAT_1MB1:
	 mov	 dx,MAPSIZE	; Get size of ROM mapping region
	 and	 dx,not (16-1)	; Round down to 16KB boundary in case of NWB

	 sub	 ax,dx		; Less amount used for ROM mapping
	 jc	 short CALC_STAT_REXP_END ; Too small

	 mov	 ebx,eax	; Save as available extended memory

	 cmp	 LOWSIZE,0	; Check the sign
	 jle	 short @F	; Jump if there's nothing to fill

	 sub	 ax,LOWSIZE	; Less amount used for low DOS fill
	 jc	 short CALC_STAT_REXP_END ; Too small
@@:
	 mov	 ebx,eax	; Save as available extended memory
	 and	 ax,not (16-1)	; Round down to multiple of 16KB

	 cmp	 eax,EMMSIZE	; Check against size of EMS memory
	 jbe	 short CALC_STAT_REXP1 ; It's in range

	 mov	 eax,EMMSIZE	; Use maximum
CALC_STAT_REXP1:
	 sub	 ebx,eax	; Save as available extended memory

	 mov	 REXP,eax	; Save for later use

	 and	 eax,eax	; Izit zero?
	 jz	 short CALC_STAT_REXP_END ; Yes, so skip it

	 lea	 di,MSG_REXP-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 DOSCALL @STROUT,MSG_REXP0 ; Display to user
CALC_STAT_REXP_END:
	 mov	 eax,ebx	; Copy available extended memory
	 mov	 REXT,eax	; Save for later use

	 and	 eax,eax	; Izit zero?
	 jz	 short CALC_STAT_REXT_END ; Yes, so skip it

	 lea	 di,MSG_REXT-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 DOSCALL @STROUT,MSG_REXT0 ; Display to user
CALC_STAT_REXT_END:

; RPRG = PRGSIZE

	 mov	 ax,PRGSIZE	; Get amount used for the program
	 lea	 di,MSG_RPRG-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

	 test	 NRD_FLAG,@NRD_1MB ; Izit a 1MB system?
	 jz	 short CALC_STAT_RPRG_END ; No, RPRG to be displayed under ETOT

	 DOSCALL @STROUT,MSG_RPRG0 ; Display to user
CALC_STAT_RPRG_END:

; ETOT = PHYSIZE - 1024

	 test	 NRD_FLAG,@NRD_1MB ; Izit a 1MB system?
	 jnz	 near ptr CALC_STAT_ETOT_EXIT ; Yes

	 mov	 eax,ETOT	; Get total size of extended memory
	 lea	 di,MSG_ETOT-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 DOSCALL @STROUT,MSG_ETOT0 ; Display to user

;;;;;;;; mov	 ax,EPRV	; Get amount previously allocated
;;;;;;;; lea	 di,MSG_EPRV-1	; ES:DI ==> units digit in message
;;;;;;;; mov	 cx,10		; Convert in decimal
;;;;;;;; call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI
;;;;;;;;
;;;;;;;; DOSCALL @STROUT,MSG_EPRV0 ; Display to user

; EEXP = EMMSIZE - REXP

	 mov	 eax,EMMSIZE	; Get size of available EMS memory
	 sub	 eax,REXP	; Less EMS memory in reserved area
	 jz	 short CALC_STAT_EEXP_END ; It's zero, so skip it

	 lea	 di,MSG_EEXP-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 DOSCALL @STROUT,MSG_EEXP0 ; Display to user
CALC_STAT_EEXP_END:
	 test	 NRD_FLAG,@NRD_1MB ; Izit a 1MB system?
	 jnz	 short CALC_STAT_1MB3 ; Yes, RPRG already displayed

	 DOSCALL @STROUT,MSG_RPRG0 ; Display to user
CALC_STAT_1MB3:

; EAVL = EXTSIZE - REXT

	 mov	 eax,EXTSIZE	; Get size of available extended memory
	 sub	 eax,REXT	; Less extended memory in reserved area
	 jz	 short CALC_STAT_EAVL_END ; It's zero, so skip it

	 lea	 di,MSG_EAVL-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 DOSCALL @STROUT,MSG_EAVL0 ; Display to user
CALC_STAT_EAVL_END:

; XAVL = EMMSIZE

	 mov	 eax,EMMSIZE	; Get size of available EMS memory

	 and	 eax,eax	; Izit zero?
	 jz	 short CALC_STAT_XAVL_END ; Yes, so skip it

	 lea	 di,MSG_XAVL-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 DOSCALL @STROUT,MSG_XAVL0 ; Display to user
CALC_STAT_XAVL_END:
CALC_STAT_ETOT_EXIT:
elseif @OEM_SYS eq @OEMSYS_ILIM

; EPHY = (PHYSIZE - 1024) + LOWOFF

	 mov	 eax,PHYSIZE	; Get size of physical memory
	 sub	 eax,1024	; Less the first megabyte
	 add	 eax,LOWOFF	; Get size of low DOS memory
	 lea	 di,MSG_EPHY-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

; OTOP = LOWOFF

	 mov	 ax,LOWOFF.ELO	; Get size of low DOS memory
	 lea	 di,MSG_OTOP-1	; ES:DI ==> units digit in message
;;;;;;;; mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

; NTOP = LOWOFF + LOWSIZE

	 mov	 ax,LOWOFF.ELO	; Get size of low DOS memory
	 add	 ax,LOWSIZE	; Plus amount of added/subtracted low DOS memory
	 lea	 di,MSG_NTOP-1	; ES:DI ==> units digit in message
;;;;;;;; mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

; ETOT = PHYSIZE - 1024

	 mov	 eax,PHYSIZE	; Get total amount of physical memory
	 sub	 eax,1024	; Less the first megabyte
	 lea	 di,MSG_ETOT-1	; ES:DI ==> units digit in message
;;;;;;;; mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

; RPRG = PRGSIZE + MAPSIZE

	 mov	 ax,PRGSIZE	; Get amount used for the program
	 add	 ax,MAPSIZE	; Plus size of ROM mapping region
	 lea	 di,MSG_RPRG-1	; ES:DI ==> units digit in message
;;;;;;;; mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

; EAVL = EXTSIZE

	 mov	 eax,EXTSIZE	; Get size of available extended memory
	 lea	 di,MSG_EAVL-1	; ES:DI ==> units digit in message
;;;;;;;; mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

; XAVL = EMMSIZE

	 mov	 eax,EMMSIZE	; Get size of available EMS memory
	 lea	 di,MSG_XAVL-1	; ES:DI ==> units digit in message
;;;;;;;; mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

; If fill is non-zero, format it; otherwise, overwrite it

; FILL = max(LOWSIZE, 0)

	 mov	 ax,LOWSIZE	; Get amount of added low DOS memory

	 cmp	 ax,0		; Check the sign of low DOS memory fill
	 jle	 short CALC_STAT_LIM0 ; Jump if it's not positive

	 lea	 di,MSG_FILL-1	; ES:DI ==> units digit in message
;;;;;;;; mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

	 jmp	 short CALC_STAT_LIM1 ; Join common code

CALC_STAT_LIM0:
	 lea	 si,MSG_FILZ	; DS:SI ==> source
	 lea	 di,MSG_FIL0	; ES:DI ==> destin
	 mov	 cx,MSG_STATZ-MSG_FILZ ; Length of data
S16  rep movsb			; Overwrite the fill part of MSG_STA

CALC_STAT_LIM1:
elseif @OEM_SYS eq @OEMSYS_LHY

else

if @OEM_EMS

; Calculate frame used for EMS memory

	 cmp	 EMMSIZE,0	; Any memory in use?
	 je	 short CALC_STAT_XFRM ; No

	 cmp	 NPHYS16F,4	; A full frame?
	 je	 short CALC_STAT1 ; Yes
CALC_STAT_XFRM:
	 lea	 di,MSG_FRAM-15 ; ES:DI ==> units digit in message
	 mov	 cx,15		; # bytes to clear
	 mov	 al,' '         ; With blanks
     rep stosb

	 jmp	 short CALC_STAT2 ; Join common code

CALC_STAT1:
	 mov	 ax,FRAME	; Get amount used
	 lea	 di,MSG_FRAM-1	; ES:DI ==> units digit in message
	 mov	 cx,16		; Convert in hexadecimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI
CALC_STAT2:
endif				; IF @OEM_EMS

; Calculate # KB of conventional memory total (new top of DOS)

	 mov	 ax,LOWOFF.ELO	; Get amount of conventional memory
	 add	 ax,LOWSIZE	; Plus amount added/subtracted in low DOS memory
	 lea	 di,MSG_NTOP-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

; Calculate # KB of conventional memory added

	 mov	 ax,LOWSIZE	; Get amount added/subtracted in low DOS memory

	 cmp	 ax,0		; Check the sign
	 jge	 short @F	; Jump if non-negative fill

	 neg	 ax		; Display the negative
@@:
	 lea	 di,MSG_CLO-1	; ES:DI ==> units digit in message
;;;;;;;; mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI

	 cmp	 LOWSIZE,0	; Check the sign
	 jge	 short @F	; Jump if non-negative fill

	 mov	 es:[di].LO,'-' ; Fill in the sign
@@:

if @OEM_EMS

; Calculate # KB of extended memory available for EMS memory

	 mov	 eax,EMMSIZE	; Get amount used
	 lea	 di,MSG_EEXP-1	; ES:DI ==> units digit in message
;;;;;;;; mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI
endif				; IF @OEM_EMS

; Calculate # KB of extended memory available

	 mov	 eax,EXTSIZE	; Get amount remaining
	 lea	 di,MSG_EAVL-1	; ES:DI ==> units digit in message
;;;;;;;; mov	 cx,10		; Convert in decimal
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

; Calculate amount of DOS high memory used

if @OEM_HIFILL
	 mov	 ax,OVRSIZE	; Get the amount
	 lea	 di,MSG_CHI-1	; ES:DI ==> units digit in message
;;;;;;;; mov	 cx,10		; Convert in decimal
	 call	 FBIN2BASE	; Convert AX to ASCII ending at ES:DI
endif				; IF @OEM_HIFILL

; Fill in MSG_LINE with graphics characters

; Because the memory map is units of 512-byte and the message line is
; units of 16KB we skip over every 32 (=16*1024/512) entries in MEM_MAP

@MEM_SKIP equ	 16*1024/512

	 lea	 si,MEM_MAP	; DS:SI ==> memory map
	 lea	 di,MSG_LINE[2] ; ES:DI ==> message line
	 lea	 bx,XLAT_MAP	; DS:BX ==> translate table
	 mov	 cx,MEM_MAP_LEN/@MEM_SKIP ; CX = # characters in MSG_LINE
CALC_STAT_XLAT:
	 lodsb			; Get next memory map character
	 add	 si,@MEM_SKIP-1 ; Skip to next 16KB boundary
	 xlat	 XLAT_MAP	; Translate into graphic character
S16	 stosb			; Save in message line
	 loop	 CALC_STAT_XLAT ; Jump if more characters to store

; Fill in MSG_TEXT with text

	 mov	 al,@XLAT_LOW	; Look for low memory
	 mov	 ah,@XLAT_LOW	; Look for low memory
	 lea	 si,LOWTEXT	; Text to insert
	 call	 SAVE_TEXT	; Store text in message line

	 mov	 al,@XLAT_VID	; Look for video memory
	 mov	 ah,@XLAT_VID	; Look for video memory
	 lea	 si,VIDTEXT	; Text to insert if non-EGA

	 test	 NRD_FLAG,@NRD_EGA ; Izit an EGA?
	 jz	 short CALC_STAT_NONEGA ; No

	 lea	 si,EGATEXT	; Text to insert if EGA
CALC_STAT_NONEGA:
	 test	 NRD_FLAG,@NRD_VGA ; Izit an VGA?
	 jz	 short CALC_STAT_NONVGA ; No

	 mov	 EGATEXT[1],'V' ; Text to insert if VGA
CALC_STAT_NONVGA:
	 call	 SAVE_TEXT	; Store text in message line

	 mov	 al,@XLAT_OVR	; Look for high memory
	 mov	 ah,@XLAT_OVR	; Look for high memory
	 lea	 si,OVRTEXT	; Text to insert
	 call	 SAVE_TEXT	; Store text in message line

	 mov	 al,@XLAT_ROM0	; Look for ROM memory
	 mov	 ah,@XLAT_ROM2	; Look for ROM memory
	 lea	 si,ROMTEXT	; Text to insert
	 call	 SAVE_TEXT	; Store text in message line

	 mov	 al,@XLAT_ROM1	; Look for ROM memory
	 mov	 ah,@XLAT_ROM2	; Look for ROM memory
	 lea	 si,ROMTEXT	; Text to insert
	 call	 SAVE_TEXT	; Store text in message line

	 mov	 al,@XLAT_OTH	; Look for other memory
	 mov	 ah,@XLAT_OTH	; Look for other memory
	 lea	 si,OTHTEXT	; Text to insert
	 call	 SAVE_TEXT	; Store text in message line

if @OEM_EMS
	 mov	 al,@XLAT_EMS	; Look for EMS frame
	 mov	 ah,@XLAT_EMS	; Look for EMS frame
	 lea	 si,EMSTEXT	; Text to insert
	 call	 SAVE_TEXT	; Store text in message line
endif				; IF @OEM_EMS

	 mov	 al,@XLAT_UNK	; Look for unknown memory
	 mov	 ah,@XLAT_UNK	; Look for unknown memory
	 lea	 si,UNKTEXT	; Text to insert
	 call	 SAVE_TEXT	; Store text in message line

	 mov	 al,@XLAT_XLO	; Look for excised low	memory
	 mov	 ah,@XLAT_XLO	; Look for excised low	memory
	 lea	 si,XLOTEXT	; Text to insert
	 call	 SAVE_TEXT	; Store text in message line

	 mov	 al,@XLAT_XHI	; Look for excised high memory
	 mov	 ah,@XLAT_XHI	; Look for excised high memory
	 lea	 si,XHITEXT	; Text to insert
	 call	 SAVE_TEXT	; Store text in message line

	 mov	 al,@XLAT_INC	; Look for INCLUDEd memory
	 mov	 ah,@XLAT_INC	; Look for INCLUDEd memory
	 lea	 si,INCTEXT	; Text to insert
	 call	 SAVE_TEXT	; Store text in message line

	 mov	 al,@XLAT_EXC	; Look for EXCLUDEd memory
	 mov	 ah,@XLAT_EXC	; Look for EXCLUDEd memory
	 lea	 si,EXCTEXT	; Text to insert
	 call	 SAVE_TEXT	; Store text in message line

if @OEM_SYS eq @OEMSYS_RET
	 mov	 al,@XLAT_PSM	; Look for PSM memory
	 mov	 ah,@XLAT_PSM	; Look for PSM memory
	 lea	 si,PSMTEXT	; Text to insert
	 call	 SAVE_TEXT	; Store text in message line
endif				; IF @OEM_SYS eq @OEMSYS_RET

; Fill in CHAR_ variables

	 lea	 bx,XLAT_MAP	; DS:BX ==> translate table

	 mov	 al,@XLAT_DOS	; Get DOS character index
	 xlat	 XLAT_MAP	; Translate into character
	 mov	 CHAR_DOS,al	; Save on screen

	 mov	 al,@XLAT_VID	; Get video character index
	 xlat	 XLAT_MAP	; Translate into character
	 mov	 CHAR_VID,al	; Save on screen

	 mov	 al,@XLAT_LOW	; Get DOS low character index
	 xlat	 XLAT_MAP	; Translate into character
	 mov	 CHAR_LOW,al	; Save on screen

	 mov	 al,@XLAT_ROM1	; Get ROM character index
	 xlat	 XLAT_MAP	; Translate into character
	 mov	 CHAR_ROM,al	; Save on screen

if @OEM_HIFILL
	 mov	 al,@XLAT_OVR	; Get DOS high character index
	 xlat	 XLAT_MAP	; Translate into character
	 mov	 CHAR_OVR,al	; Save on screen
endif				; IF @OEM_HIFILL

	 mov	 al,@XLAT_OTH	; Get other character index
	 xlat	 XLAT_MAP	; Translate into character
	 mov	 CHAR_OTH,al	; Save on screen

if @OEM_EMS
	 mov	 al,@XLAT_EMS	; Get EMS character index
	 xlat	 XLAT_MAP	; Translate into character
	 mov	 CHAR_EMS,al	; Save on screen
endif				; IF @OEM_EMS

	 mov	 al,@XLAT_XLO	; Get excised low  DOS character index
	 xlat	 XLAT_MAP	; Translate into character
	 mov	 CHAR_UNU,al	; Save on screen

;;;;;;;; mov	 al,@XLAT_XHI	; Get excised high DOS character index
;;;;;;;; xlat	 XLAT_MAP	; Translate into character
;;;;;;;; mov	 CHAR_XHI,al	; Save on screen

;;;;;;;; mov	 al,@XLAT_INC	; Get INCLUDEd character index
;;;;;;;; xlat	 XLAT_MAP	; Translate into character
;;;;;;;; mov	 CHAR_INC,al	; Save on screen

;;;;;;;; mov	 al,@XLAT_EXC	; Get EXCLUDEd character index
;;;;;;;; xlat	 XLAT_MAP	; Translate into character
;;;;;;;; mov	 CHAR_EXC,al	; Save on screen

				; IF @OEM_SYS eq @OEMSYS_LHY
				; IF @OEM_SYS eq @OEMSYS_ILIM
				; IF @OEM_SYS eq @OEMSYS_HPRS
endif				; IF @OEM_SYS eq @OEMSYS_AST386

	 REGREST <fs,di,dx,cx,ebx,eax> ; Restore
	 assume  fs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_STAT endp			; End CALC_STAT procedure
if @OEM_SYS ne @OEMSYS_HPRS and @OEM_SYS ne @OEMSYS_AST386 and @OEM_SYS ne @OEMSYS_ILIM and @OEM_SYS ne @OEMSYS_LHY
	 NPPROC  SAVE_TEXT -- Save Text in Message Line
	 assume  ds:PGROUP,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

On entry:

AL	 =	 1st MEM_MAP character to search for
AH	 =	 2nd MEM_MAP character to search for
FS:SI	 ==>	 source text to move into message line

|

	 REGSAVE <bx,cx,si,di>	; Save registers

	 lea	 di,MEM_MAP	; ES:DI ==> memory map
	 mov	 cx,MEM_MAP_LEN ; CX = # characters in MEM_MAP
SAVE_TEXT1:
	 jcxz	 SAVE_TEXT_EXIT ; None found
   repne scas	 PGROUP:[di].LO ; Search for it
	 jne	 short SAVE_TEXT_EXIT ; None found

	 xchg	 al,ah		; Look for this one next

	 lea	 bx,[di-1]	; Save starting address
    repe scas	 PGROUP:[di].LO ; Look for ending
	 je	 short SAVE_TEXT2 ; Nothing else there

	 dec	 di		; Backup to last+1
	 inc	 cx		; Count it back in
SAVE_TEXT2:
	 xchg	 al,ah		; Look for this one next

	 REGSAVE <cx,si,di>	; Save count and offset

	 sub	 di,bx		; DI = length in 512-byte blocks
	 shr	 di,14-9	; Convert from 512 to 16KB
	 sub	 bx,offset es:MEM_MAP ; Convert to origin-0, unit = 512
	 shr	 bx,14-9	; Convert from 512 to 16KB

	 mov	 cx,di		; Copy as text length
	 lea	 di,MSG_LINE[ROWLEN+2][bx] ; ES:DI ==> start of text area
S16  rep movs	 <PGROUP:[di].LO,XGROUP:[si].LO> ; Move text into message line

	 REGREST <di,si,cx>	; Restore

	 jmp	 SAVE_TEXT1	; Go around again

SAVE_TEXT_EXIT:
	 REGREST <di,si,cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_TEXT endp			; End SAVE_TEXT procedure
endif				; IF @OEM_SYS ne @OEMSYS_HPRS and @OEM_SYS ne @OEMSYS_AST386 and @OEM_SYS ne @OEMSYS_ILIM and @OEM_SYS ne @OEMSYS_LHY

XCODE	 ends			; End XCODE segment

	 MEND			; End QMAX_STA module
