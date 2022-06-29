;' $Header:   P:/PVCS/MAX/386DISK/QDISK_IN.ASV   1.5   30 May 1997 10:34:14   BOB  $
	 title	 QDISK_IN -- QDISK Initialization Routines
	 page	 59,122
	 name	 QDISK_IN

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1984, 1988, 1992-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  word-aligned,  public, class 'prog'
	       Program segment ZCODE, dword-aligned, public, class 'prog'

Program derived from:  None.

Original code by:  Bob Smith, May 1984.

Modifications by:  Bob Smith, October 1988
		   to use EMS or XMS calls
		   Bob Smith, April 1992
		   to implement XMSHI, 16-bit FATs,
		   and 32-bit sector numbers

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include DTA.INC
	 include DIR.INC
	 include PTR.INC
	 include XMS.INC
	 include IOCTL.INC
	 include CPUFLAGS.INC
	 include KEYCALL.INC
	 include EMMCALL.INC
	 include DEVDRV.INC
	 include VERSION.INC
	 include 386.INC
	include DOSOEM.INC

	 include QDSK_OEM.INC
.list

ARGERR	 macro	 MSG,NUM	; Note that this macro *MUST* preserve FL

	 mov	 ARG_ERRADDR,offset cs:MSG
ifnb <NUM>
	 mov	 ARG_ERRNUM,NUM
else
	 mov	 ARG_ERRNUM,0
endif				; IFNB

	 endm			; ARGERR

@BPS_MIN1 equ	 128		; Minimum # bytes per sector for pre-MS-DOS 7
@BPS_MAX1 equ	 512		; Maximum ...

@BPS_MIN2 equ	 512		; Minimum # bytes per sector for MS-DOS 7
@BPS_MAX2 equ	2048		; Maximum ...


PGROUP	 group	 CODE,ZCODE


ZCODE	 segment use16 dword public 'prog' ; Start ZCODE segment
	 assume  ds:PGROUP

	 public  ZTAIL
ZTAIL	 label	 byte

ZCODE	 ends			; End ZCODE segment


CODE	 segment use16 word public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 MEM2DISK:word
	 extrn	 DISK2MEM:word

	 extrn	 INT15:near
	 extrn	 OLDINT15_VEC:dword
	 extrn	 EXTBASE:dword
	 extrn	 EXTSIZE:word

	 extrn	 XMS_MEM2DISK:near
	 extrn	 XMS_MEM2DISKZ:near
	 extrn	 EXT_MEM2DISK:near
	 extrn	 EXT_MEM2DISKZ:near
	 extrn	 EMS_MEM2DISK:near
	 extrn	 EMS_MEM2DISKZ:near

	 extrn	 XMS_DISK2MEM:near
	 extrn	 XMS_DISK2MEMZ:near
	 extrn	 EXT_DISK2MEM:near
	 extrn	 EXT_DISK2MEMZ:near
	 extrn	 EMS_DISK2MEM:near
	 extrn	 EMS_DISK2MEMZ:near

	 extrn	 MOVETYPE:byte
	 include QDSK_COM.INC

	 extrn	 RH_VEC:dword
	 extrn	 XMSDRV_VEC:dword
	 extrn	 MOVE_LEN:dword
	 extrn	 BPSLG2:byte
	 extrn	 BPB_PTR:word
	 extrn	 BPB_BPS:word
	 extrn	 BPB_SPD:word
	 extrn	 BPB_MED:byte
	 extrn	 BPB_SPC:byte
	 extrn	 BPB_NDIR:word
	 extrn	 BPB_SPF:word
	 extrn	 BPB_HUGE:dword
	 extrn	 USER_DTA_VEC:dword
	 extrn	 BOOT_REC:byte
	 extrn	 BOOT_TYP1:byte
	 extrn	 BOOT_LEN:abs
	 extrn	 EXIT_DONE:near
	 extrn	 EXIT:near
	 extrn	 QCODE_END:near
	 extrn	 HNDL:word
	 extrn	 @BPS:abs
	 extrn	 @NDIR:abs
	 extrn	 ARG_ERRNUM:byte
	 extrn	 @NFATS:abs
	 extrn	 @NRSV:abs

@DEVLEN  sizestr @OEM_IOCTL
@DEVNAME substr  @OEM_IOCTL,2,@DEVLEN-2

	 rept	 10-@DEVLEN
@DEVNAME catstr  @DEVNAME,<$>	; Append a dollar sign
	 endm			; RPT

; Because eight-character device names are confused with file names,
; we must truncate the last character and insert a $.

@DEVNAME substr  @DEVNAME,1,7	; Drop off the last character
@DEVNAME catstr  @DEVNAME,<$>	; Append a dollar sign

@DEVNAME catstr  <'>,@DEVNAME   ; Prefix a quote mark
@DEVNAME catstr  @DEVNAME,<'>   ; Append a quote mark

	 public  HNDLNAME
HNDLNAME db	 @OEM_DISK
if (HNDLNAME+8-$)
	 db	 (HNDLNAME+8-$) dup ('0') ; Pad with zeros
endif
	 org	 $-1
	 db	 '0'            ; Suffix a number

	 public  QDISK_END
QDISK_END dw	 PGROUP:QCODE_END ; Current ending address

	 public  M2D_SRC
M2D_SRC  dw	 PGROUP:XMS_MEM2DISK
	 dw	 PGROUP:EXT_MEM2DISK
	 dw	 PGROUP:EMS_MEM2DISK

	 public  M2D_END
M2D_END  dw	 PGROUP:XMS_MEM2DISKZ
	 dw	 PGROUP:EXT_MEM2DISKZ
	 dw	 PGROUP:EMS_MEM2DISKZ

	 public  D2M_SRC
D2M_SRC  dw	 PGROUP:XMS_DISK2MEM
	 dw	 PGROUP:EXT_DISK2MEM
	 dw	 PGROUP:EMS_DISK2MEM

	 public  D2M_END
D2M_END  dw	 PGROUP:XMS_DISK2MEMZ
	 dw	 PGROUP:EXT_DISK2MEMZ
	 dw	 PGROUP:EMS_DISK2MEMZ

	 public  FAT_OFF,FAT_LEN,DIR_OFF,DIR_LEN,NCIF
FAT_OFF  dd	 ?		; Byte offset of FAT
FAT_LEN  dd	 ?		; Byte length of FAT
DIR_OFF  dd	 ?		; Byte offset of DIR
DIR_LEN  dd	 ?		; Byte length of DIR
NCIF	 dw	 ?		; # clusters in FAT

; Note that the values in NEXTNUM and NEXTMAX must be in the same order

	 public  NEXTIND,NEXTNUM
NEXTIND  dw	 0		; Index into NEXTNUM
NEXTNUM  dw	 PGROUP:DISKKILO
	 dw	 PGROUP:LCL_BPS
	 dw	 PGROUP:LCL_NDIR
NEXTLIM  equ	 ($-NEXTNUM)/(type NEXTNUM)

	 public  NEXTMAX
NEXTMAX  dd	 -1		; Maximum value for DISKKILO
	 dd	 64*1024-1	; ...		    LCL_BPS
	 dd	 64*1024-1	; ...		    LCL_NDIR

@NDIR_MIN equ	 16		; Minimum # directory entries (must be >=16)

	 public  DISKKILO,LCL_BPS,LCL_NDIR
DISKKILO dd	 64		; Disk size in kilobytes
LCL_BPS  dw	 @BPS,0 	; Local value for BPB_BPS, padded to dword
LCL_NDIR dw	 @NDIR,0	; Local value for BPB_NDIR, padded to dword

	 public  ARG_ERRADDR
ARG_ERRADDR dw	 ?		; Offset of error message

	 public  DOSVER
DOSVER	 dw	 ?		; DOS version # in comparison order

	public	BPS_MIN,BPS_MAX
BPS_MIN dw	@BPS_MIN1	; Minimum # bytes/sector
BPS_MAX dw	@BPS_MAX1	; Maximum ...

	 public  XMS_GETXMBFN,XMS_QRYXMBFN
XMS_GETXMBFN db  @XMS_GETXMB	; Function code to use to allocate XMS memory
XMS_QRYXMBFN db  @XMS_QRYXMB	; ...			  query ...

	public	DOSOEM
DOSOEM	db	?		; DOS OEM number

	 public  SPCLG2
SPCLG2	 db	 ?		; Log 2 of BPB_SPC

	 public  LCL_FLAG
LCL_FLAG db	 0		; Local flags
@LCL_XMSHI equ	 80h		; /XMSHI specified
@LCL_NOMAX equ	 40h		; 386MAX not present

	 public  COPY_MSG
COPY_MSG db	 CR,LF
@@:	 db	 @OEM_DISK
	 db	 (@B+9-$) dup (' '),'-- Version '
	 db	 VERS_H,'.',VERS_T,VERS_U
ifdef LANG_GR
	 db	 ' -- 386-virtuelle Platte',CR,LF
else
	 db	 ' -- 386 Virtual Disk Drive',CR,LF
endif				; IFDEF LANG_GR
	 db	 '   (C) Copyright 1984-96 Qualitas, Inc.'
ifdef LANG_GR
	 db	 '  Alle Rechte vorbehalten.',CR,LF,EOS
else
	 db	 '  All rights reserved.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_NOT386,MSG_NOTDOS3,MSG_NOTPRES,MSG_INSUF
	 public  MSG_NODRV,MSG_DRVERR
	 public  MSG_INVARG,MSG_TOOMANY,MSG_TOOBIG,MSG_INCOMPAT
ifdef LANG_GR
MSG_NOT386 db	 BEL,'ÕÕ> Sie haben die falsche Maschine; ich benîtige einen 80386.',CR,LF,EOS
MSG_NOTDOS3 db	 BEL,'ÕÕ> Dieses Programm verlangt DOS 3.00 oder hîher!',CR,LF,EOS
MSG_NOTPRES db	 BEL,'ÕÕ> ',@OEM_MAX,'.SYS-Einh.-Treiber wurde von CONFIG.SYS nicht geladen.',CR,LF,EOS
MSG_INSUF db	 BEL,'ÕÕ> Ihre Platte ist zu klein.',CR,LF,EOS
MSG_NODRV db	 BEL,'ÕÕ> Es wurde kein '
MSG_NODRV1 db	     'XMS-Treiber installiert.',CR,LF,EOS ; Using default of XMS
MSG_DRVERR db	 BEL,'ÕÕ> Fehler vom '
MSG_DRVERR1 db	     'XMS-Treiber gemeldet:  ',EOS ; Using default of XMS
MSG_INVARG db	 BEL,'ÕÕ> unzulÑssiger Schalter; verwenden Sie /EXT, /XMS, /XMSHI oder /EMS.',CR,LF,EOS
MSG_TOOMANY db	 BEL,'ÕÕ> zu viele Argumente in der Befehls-Zeile.',CR,LF,EOS
MSG_TOOBIG db	 BEL,'ÕÕ> Wert zu gro·· - maximal 65536.',CR,LF,EOS
MSG_INCOMPAT db  BEL,'ÕÕ> Disk Parameter nicht kompatibel.',CR,LF,EOS
MSG_XMS_SWITCH db 'ÕÕ> /EXT-Speicher ist belegt, ich nehme /XMS-Speicher.',CR,LF,EOS
else
MSG_NOT386 db	 BEL,'ÕÕ> Wrong machine type:  must run on an 80386.',CR,LF,EOS
MSG_NOTDOS3 db	 BEL,'ÕÕ> This program requires DOS 3.00 or later.',CR,LF,EOS
MSG_NOTPRES db	 BEL,'ÕÕ> ',@OEM_MAX,'.SYS device driver not loaded from CONFIG.SYS.',CR,LF,EOS
MSG_INSUF db	 BEL,'ÕÕ> Disk size too small.',CR,LF,EOS
MSG_NODRV db	 BEL,'ÕÕ> No '
MSG_NODRV1 db	     'XMS driver installed.',CR,LF,EOS ; Using default of XMS
MSG_DRVERR db	 BEL,'ÕÕ> Error from '
MSG_DRVERR1 db	     'XMS driver:  ',EOS ; Using default of XMS
MSG_INVARG db	 BEL,'ÕÕ> Invalid switch:  use /EXT, /XMS, /XMSHI, or /EMS.',CR,LF,EOS
MSG_TOOMANY db	 BEL,'ÕÕ> Too many command line arguments.',CR,LF,EOS
MSG_TOOBIG db	 BEL,'ÕÕ> Value too large:  maximum is 65536.',CR,LF,EOS
MSG_INCOMPAT db  BEL,'ÕÕ> Incompatible disk parameters.',CR,LF,EOS
MSG_XMS_SWITCH db 'ÕÕ> /EXT memory in use, using /XMS memory.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_PRESS
ifdef LANG_GR
MSG_PRESS db	 CR,LF
	 db	 BEL,'ÕÕ> ',@OEM_DISK,' wurde nicht installiert',CR,LF
	 db	     '    weiter mit beliebiger Taste...'
else
MSG_PRESS db	 CR,LF
	 db	 BEL,'ÕÕ> ',@OEM_DISK,' not installed',CR,LF
	 db	     '    Press any key to continue...'
endif				; IFDEF LANG_GR
	 db	 CR,LF,EOS

	 public  INIT_MSG,DRIV_MSG,SIZE_NUM,TYPE_TXT,BPS_NUM,DIR_NUM
ifdef LANG_GR
INIT_MSG db	 'Laufwerk '
DRIV_MSG db	 '_:     '
SIZE_NUM db	 '_ KB im '
TYPE_TXT db	 'XMS-Speicher,   '
BPS_NUM  db	 '_ Byte/Sektor,   '
DIR_NUM  db	 '_ Verzeichnis-EintrÑge',CR,LF,EOS
else
INIT_MSG db	 'Drive '
DRIV_MSG db	 '_:      '
SIZE_NUM db	 '_ KB of '
TYPE_TXT db	 'XMS memory,   '
BPS_NUM  db	 '_ bytes per sector,    '
DIR_NUM  db	 '_ directory entries.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  EMSNAME
EMSNAME  db	 'EMMXXXX0'     ; Name of EMS driver
EMSNAME_LEN equ  $-EMSNAME	; Length of ...

	 public  DEVNAME
DEVNAME  db	 @DEVNAME,0	; Device driver name

	 public  NUMBERS_LO,NUMBERS_HI
NUMBERS_LO db	 '0123456789abcdef'     ; Conversion table for BASE2BIND
NUMBERS_HI db	 '0123456789ABCDEF'     ; Conversion table for BIN2BASE

LBL_DATE equ	 (1988-1980)*512+10*32+23 ; Date of completion
LBL_TIME equ	 0*2048+0*32+0/2
LBL_CLUS equ	 0
LBL_SIZE equ	 0

; Note that Win95 marks as a RAM drive (via a RAM chip icon) only those
; disks whose label starts with any of 'MS-RAMDRIVE', 'VDISK', or 'RDV'.
; As we'd like to be so marked and the last one is the shortest, we
; expand upon that one.

	 public  DISK_LABEL
DISK_LABEL DIR_STR <'RDV-386D','ISK',DIR_ATTR_LABEL,,LBL_TIME,LBL_DATE,LBL_CLUS,LBL_SIZE>

	 public  EMSERR_NUM
EMSERR_NUM db	 80h
	 db	 84h
	 db	 85h
	 db	 87h
	 db	 88h
	 db	 89h
EMSERR_LEN equ	 $-EMSERR_NUM	; # error numbers supported

	 public  XMSERR_NUM
XMSERR_NUM db	  80h
	 db	  81h
	 db	  82h
	 db	  8Eh
	 db	  8Fh
	 db	 0A0h
	 db	 0A1h
	 db	 0A2h
	 db	 0A3h
	 db	 0A4h
	 db	 0A5h
	 db	 0A6h
	 db	 0A7h
	 db	 0A8h
	 db	 0A9h
XMSERR_LEN equ	 $-XMSERR_NUM	; # error numbers supported

	 public  EXTERR_NUM
EXTERR_NUM db	 01h
	 db	 02h
	 db	 03h
EXTERR_LEN equ	 $-EXTERR_NUM	; # error numbers supported

	 public  EMSERR_TAB,XMSERR_TAB
	 even
EMSERR_TAB dw	 PGROUP:EMS80
	 dw	 PGROUP:EMS84
	 dw	 PGROUP:EMS85
	 dw	 PGROUP:EMS87
	 dw	 PGROUP:EMS88
	 dw	 PGROUP:EMS89
XMSERR_TAB dw	 PGROUP:XMS80
	 dw	 PGROUP:XMS81
	 dw	 PGROUP:XMS82
	 dw	 PGROUP:XMS8E
	 dw	 PGROUP:XMS8F
	 dw	 PGROUP:XMSA0
	 dw	 PGROUP:XMSA1
	 dw	 PGROUP:XMSA2
	 dw	 PGROUP:XMSA3
	 dw	 PGROUP:XMSA4
	 dw	 PGROUP:XMSA5
	 dw	 PGROUP:XMSA6
	 dw	 PGROUP:XMSA7
	 dw	 PGROUP:XMSA8
	 dw	 PGROUP:XMSA9
EXTERR_TAB dw	 PGROUP:EXT01
	 dw	 PGROUP:EXT02
	 dw	 PGROUP:EXT03

ifdef LANG_GR
EMS80	 db	 'Software-Fehler',EOS
EMS84	 db	 'unzulÑssige Funktion',EOS
EMS85	 db	 'keine Handles verfÅgbar',EOS
EMS87	 db	 'zu wenig Speicher',EOS
else
EMS80	 db	 'software error.',EOS
EMS84	 db	 'invalid function.',EOS
EMS85	 db	 'no available handles.',EOS
EMS87	 db	 'insufficient memory.',EOS
endif				; IFDEF LANG_GR
EMS88	 equ	 EMS87
EMS89	 equ	 EMS87
XMS80	 equ	 EMS84
ifdef LANG_GR
XMS81	 db	 'VDISK entdeckt',EOS
XMS82	 db	 'Gate-Adress-Leitung A20 ist fehlerhaft',EOS
XMS8E	 db	 'genereller Treiber-Fehler.',EOS
XMS8F	 db	 'nicht-behebbarer Treiber-Fehler.',EOS
else
XMS81	 db	 'VDISK detected.',EOS
XMS82	 db	 'gate address line A20 failed.',EOS
XMS8E	 db	 'general driver error detected.',EOS
XMS8F	 db	 'unrecoverable driver error detected.',EOS
endif				; IFDEF LANG_GR
XMSA0	 equ	 EMS87
XMSA1	 equ	 EMS85
ifdef LANG_GR
XMSA2	 db	 'Einheit (Handle) ist ungÅltig.',EOS
XMSA3	 db	 'Quell-Einheit (Handle) is ungÅltig.',EOS
XMSA4	 db	 'Quell-Offset ist ungÅltig.',EOS
XMSA5	 db	 'Ziel-Einheit (Handle) ist ungÅltig.',EOS
XMSA6	 db	 'Ziel-Offset ist ungÅltig.',EOS
XMSA7	 db	 'LÑnge ist ungÅltig.',EOS
XMSA8	 db	 'MOVE hat ungÅltige öberlappung.',EOS
XMSA9	 db	 'ParitÑtsfehler entdeckt',EOS
else
XMSA2	 db	 'handle is invalid.',EOS
XMSA3	 db	 'source handle is invalid.',EOS
XMSA4	 db	 'source offset is invalid.',EOS
XMSA5	 db	 'destination handle is invalid.',EOS
XMSA6	 db	 'destination offset is invalid.',EOS
XMSA7	 db	 'length invalid.',EOS
XMSA8	 db	 'move has invalid overlap.',EOS
XMSA9	 db	 'parity error is detected.',EOS
endif				; IFDEF LANG_GR
EXT01	 equ	 XMSA9
ifdef LANG_GR
EXT02	 db	 'Ausnahme-Interrupt entdeckt',EOS
else
EXT02	 db	 'exception interrupt is detected.',EOS
endif				; IFDEF LANG_GR
EXT03	 equ	 XMS82

	 NPPROC  INIT -- Initialization Code
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Check command line arguments and take action as appropriate.
Fill in the BPB pointer and ending addresses.

|
.8086
	 REGSAVE <ax,dx>	; Save registers

	 DOSCALL @STROUT,COPY_MSG ; Display the copyright message

	 REGREST <dx,ax>	; Restore

; Ensure we're on a 386

	 call	 CHECK_CPUID	; Check it
	 MJ c	 UGH_INIT1	; Jump if not with ARG_ERRADDR filled in
.386
	 pushad 		; Save all EGP registers

; Ensure it's DOS 3.x or later

	mov	al,0		; Ask for DOS OEM number in BH
	 DOSCALL @DOSVER	; Get DOS version #
				; AL=major version #, AH=minor
				; BH=OEM number
				; CX=0
	 xchg	 al,ah		; Swap to comparison order
	 mov	 DOSVER,ax	; Save for later use
	mov	DOSOEM,bh	; ...

	 cmp	 ah,03h 	; Check version #
	 ARGERR  MSG_NOTDOS3	; Set error message
	 jb	 near ptr UGH_INIT ; Jump if it's earlier than DOS 3.00

; Ensure 386MAX is installed

	 mov	 al,0		; Code for read-only access
	 DOSCALL @OPENF2,DEVNAME ; Attempt to open the file
	 jc	 short INIT_NOMAX ; Jump if it's not present

	 mov	 bx,ax		; Copy to handle register

; Ensure it's a device

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 pushf			; Save flags
	 DOSCALL @CLOSF2	; Close it up
	 popf			; Restore
	 jc	 short INIT_NOMAX ; Something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jnz	 short @F	; Jump if it's a device
INIT_NOMAX:
	 or	 LCL_FLAG,@LCL_NOMAX ; Mark as not present
@@:

; Parse the command line

	 call	 CHECK_ARGS	; Check command line arguments
	 jc	 near ptr UGH_INIT ; Take error exit with ARG_ERRADDR filled in

	 test	 LCL_FLAG,@LCL_NOMAX ; Izit still not present?
	 ARGERR  MSG_NOTPRES	; In case of error
	 jnz	 near ptr UGH_INIT ; Jump if not

	 push	 cs		; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Move in the boot record

	 mov	 si,ds		; Get source segment
	 shl	 esi,16 	; Shift into high-order word
	 lea	 si,BOOT_REC	; ESI ==> Seg:Off of boot record
	 xor	 edi,edi	; EDI ==> 32-bit offset in disk of destin
	 mov	 ecx,BOOT_LEN	; CX = byte length of boot record
	 mov	 MOVE_LEN,ecx	; Save as move length
	 bt	 MOVE_LEN,0	; Test for odd length
	 adc	 MOVE_LEN,0	; Add to make it even
	 ARGERR  MSG_DRVERR	; Set error message
	 call	 MEM2DISK	; Transfer from memory ESI to disk EDI
	 jc	 near ptr UGH_INIT ; Jump if something went wrong

; Initialize FAT in local memory

	 lea	 di,ZTAIL	; ES:DI ==> scratch area at end of program
	 xor	 ecx,ecx	; Initialize initial size of FAT

	 mov	 al,BPB_MED	; Get media descriptor byte from BPB
S16	 stosb			; Store as 1st byte in FAT
	 mov	 ax,0FFFFh	; Set remaining two bytes in entry
S16	 stosw			; Store as 2nd and 3rd bytes
	 add	 ecx,3		; Account for bytes stored

; If we're using a 16-bit FAT, store the fourth byte

	 cmp	 NCIF,4086	; Izit a 16-bit FAT?
	 jbe	 short @F	; Jump if not

S16	 stosb			; Store as 4th byte in FAT
	 inc	 ecx		; Account for byte stored
@@:
; Move in initial FAT values

;;;;;;;; mov	 si,ds		; Get source segment
;;;;;;;; shl	 esi,16 	; Shift into high-order word
	 lea	 si,ZTAIL	; ESI ==> Seg:Off of FAT
	 mov	 edi,FAT_OFF	; EDI ==> 32-bit offset in disk of destin
	 add	 FAT_OFF,ecx	; Skip over it for the next time
	 mov	 MOVE_LEN,ecx	; Save as move length
	 bt	 MOVE_LEN,0	; Test for odd length
	 adc	 MOVE_LEN,0	; Add to make it even
	 ARGERR  MSG_DRVERR	; Set error message
	 call	 MEM2DISK	; Transfer from memory ESI to disk EDI
	 jc	 near ptr UGH_INIT ; Jump if something went wrong

	 sub	 ecx,FAT_LEN	; Less byte length of FAT
	 neg	 ecx		; ECX = size of remainder of FAT

; In case the FAT is too large, limit the amount of memory we zero

; We must pick a value that's not too large so as to minimize the
; initialization size in case we're being loaded high via 386LOAD.

@ZEROMAX equ	 1024		; Maximum size of region to zero

	 mov	 ebx,ecx	; Save actual amount to zero & move
CHECK_ARGS_NEXTFAT:
	 mov	 ecx,ebx	; Initialize to remainder

	 cmp	 ecx,@ZEROMAX	; Izit bigger than arbitrary maximum?
	 jbe	 short @F	; Jump if not

	 mov	 ecx,@ZEROMAX	; Use maximum
@@:
	 lea	 di,ZTAIL	; ES:DI ==> scratch area at end of program
	 call	 ZEROSEG	; Zero ECX bytes at ES:DI

; Move in the next part of the FAT

;;;;;;;; mov	 si,ds		; Get source segment
;;;;;;;; shl	 esi,16 	; Shift into high-order word
	 lea	 si,ZTAIL	; ESI ==> Seg:Off of DIR
	 mov	 edi,FAT_OFF	; EDI ==> 32-bit offset in disk of destin
	 add	 FAT_OFF,ecx	; Skip over it for the next time
	 mov	 MOVE_LEN,ecx	; Save as move length
	 bt	 MOVE_LEN,0	; Test for odd length
	 adc	 MOVE_LEN,0	; Add to make it even
	 ARGERR  MSG_DRVERR	; Set error message
	 call	 MEM2DISK	; Transfer from memory ESI to disk EDI
	 jc	 near ptr UGH_INIT ; Jump if something went wrong

	 sub	 ebx,ecx	; Less amount moved
	 jnz	 short CHECK_ARGS_NEXTFAT ; Jump if there's more to do

; Clear the directory in local memory and set the disk label

	 lea	 di,ZTAIL	; ES:DI ==> scratch area at end of program
	 lea	 si,DISK_LABEL	; DS:SI ==> address of disk label
	 mov	 cx,type DIR_STR ; CX = byte length of disk label
S16  rep movsb			; Move it

; Move in the disk label

;;;;;;;; mov	 si,ds		; Get source segment
;;;;;;;; shl	 esi,16 	; Shift into high-order word
	 lea	 si,ZTAIL	; ESI ==> Seg:Off of DIR
	 mov	 edi,DIR_OFF	; EDI ==> 32-bit offset in disk of destin
	 mov	 ecx,type DIR_STR ; ECX = byte length of DIR
	 add	 DIR_OFF,ecx	; Skip over it for the next time
	 mov	 MOVE_LEN,ecx	; Save as move length
	 bt	 MOVE_LEN,0	; Test for odd length
	 adc	 MOVE_LEN,0	; Add to make it even
	 ARGERR  MSG_DRVERR	; Set error message
	 call	 MEM2DISK	; Transfer from memory ESI to disk EDI
	 jc	 near ptr UGH_INIT ; Jump if something went wrong

	 mov	 ecx,DIR_LEN	; ECX = length of DIR in bytes
	 sub	 ecx,type DIR_STR ; Less amount already moved

; In case the directory is too large, limit the amount of memory we zero

	 mov	 ebx,ecx	; Save actual amount to zero & move
CHECK_ARGS_NEXTDIR:
	 mov	 ecx,ebx	; Initialize to remainder

	 cmp	 ecx,@ZEROMAX	; Izit bigger than arbitrary maximum?
	 jbe	 short @F	; Jump if not

	 mov	 ecx,@ZEROMAX	; Use maximum
@@:
	 lea	 di,ZTAIL	; ES:DI ==> scratch area at end of program
	 call	 ZEROSEG	; Zero ECX bytes at ES:DI

; Move in the next part of the directory

;;;;;;;; mov	 si,ds		; Get source segment
;;;;;;;; shl	 esi,16 	; Shift into high-order word
	 lea	 si,ZTAIL	; ESI ==> Seg:Off of DIR
	 mov	 edi,DIR_OFF	; EDI ==> 32-bit offset in disk of destin
	 add	 DIR_OFF,ecx	; Skip over it for the next time
	 mov	 MOVE_LEN,ecx	; Save as move length
	 bt	 MOVE_LEN,0	; Test for odd length
	 adc	 MOVE_LEN,0	; Add to make it even
	 ARGERR  MSG_DRVERR	; Set error message
	 call	 MEM2DISK	; Transfer from memory ESI to disk EDI
	 jc	 near ptr UGH_INIT ; Jump if something went wrong

	 sub	 ebx,ecx	; Less amount moved
	 jnz	 short CHECK_ARGS_NEXTDIR ; Jump if there's more to do

; Display completion message to the user

	 call	 SEND_MSGS	; Tell the user

; Finally, if we're installing as an EXT disk, hook INT 15h

	 cmp	 MOVETYPE,@MOVE_EXT ; Izit an EXT disk?
	 jne	 short @F	; Not this time

	 mov	 al,15h 	; Intercept this one
	 DOSCALL @SETINT,INT15	; Install our own handler
@@:
	 popad			; Restore all EGP registers

	 jmp	 EXIT_DONE	; Exit

; The following entry is used to report an unspecified failure
; during initialization

UGH_INIT:
	 popad			; Restore all EGP registers
.8086
UGH_INIT1:
	 REGSAVE <ax,bx,cx,dx,di,ds,es>  ; Save registers

	 push	 cs		; Setup DS for data references
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 cs		; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 dx,ARG_ERRADDR ; Get offset of error message
	 DOSCALL @STROUT	; Tell the user about it

	 mov	 al,ARG_ERRNUM	; Get error number (if any)

	 cmp	 MOVETYPE,@MOVE_XMS ; Izit an XMS disk?
	 je	 short UGH_INIT_XMS ; Yes

	 cmp	 MOVETYPE,@MOVE_EMS ; Izit an EMS disk?
	 je	 short UGH_INIT_EMS ; Yes

	 mov	 cx,EXTERR_LEN	; CX = # EXT error messages
	 lea	 di,EXTERR_NUM	; ES:DI ==> EXT error numbers
   repne scasb			; Search for it
	 jne	 short UGH_INIT_CRLF ; Jump if not found

	 sub	 di,1+offset es:EXTERR_NUM ; Convert to origin-0
	 shl	 di,1		; Times two to index table of words

	 mov	 dx,EXTERR_TAB[di] ; DS:DX ==> error message
	 DOSCALL @STROUT	; Display it

	 jmp	 short UGH_INIT_CRLF ; Join common code

UGH_INIT_EMS:
	 mov	 cx,EMSERR_LEN	; CX = # EMS error messages
	 lea	 di,EMSERR_NUM	; ES:DI ==> EMS error numbers
   repne scasb			; Search for it
	 jne	 short UGH_INIT_CRLF ; Jump if not found

	 sub	 di,1+offset es:EMSERR_NUM ; Convert to origin-0
	 shl	 di,1		; Times two to index table of words

	 mov	 dx,EMSERR_TAB[di] ; DS:DX ==> error message
	 DOSCALL @STROUT	; Display it

	 jmp	 short UGH_INIT_CRLF ; Join common code

UGH_INIT_XMS:
	 mov	 cx,XMSERR_LEN	; CX = # XMS error messages
	 lea	 di,XMSERR_NUM	; ES:DI ==> XMS error numbers
   repne scasb			; Search for it
	 jne	 short UGH_INIT_CRLF ; Jump if not found

	 sub	 di,1+offset es:XMSERR_NUM ; Convert to origin-0
	 shl	 di,1		; Times two to index table of words

	 mov	 dx,XMSERR_TAB[di] ; DS:DX ==> error message
	 DOSCALL @STROUT	; Display it
UGH_INIT_CRLF:
	 DOSCALL @STROUT,MSG_PRESS ; Tell to press a key

; Purge the keyboard buffer and wait for a key press -- discard the key

	 call	 KEYWAIT	; Wait for an acknowledgement
				; Return with key in AX

; Release any storage allocated

	 cmp	 MOVETYPE,@MOVE_EXT ; Izit an EXT disk?
	 je	 short UGH_INIT_EXIT ; Yes, nothing to release

	 mov	 dx,HNDL	; Get the EMS/XMS handle

	 cmp	 dx,-1		; Check the handle
	 je	 short UGH_INIT_EXIT ; None this time

	 cmp	 MOVETYPE,@MOVE_XMS ; Izit an XMS disk?
	 je	 short UGH_INIT_XMS2 ; Yes

	 EMMCALL @EMM_RLSPAGE	; Release the handle and memory

	 jmp	 short UGH_INIT_EXIT ; Join common exit code

UGH_INIT_XMS2:
	 mov	 ah,@XMS_RELXMB ; Release the handle and memory
	 call	 XMSDRV_VEC	; Request XMS service
				; Ignore error return
UGH_INIT_EXIT:
	 les	 bx,RH_VEC	; Restore ES:BX to request header
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[bx].INIT_UNITS,0	; No units defined
	 mov	 es:[bx].INIT_END_VEC.VOFF,0
	 mov	 es:[bx].INIT_END_VEC.VSEG,cs ; Mark as ending address

	 STATUS  DONE,ERROR,ERR_UGH	; Mark as general failure

	 REGREST <es,ds,di,dx,cx,bx,ax> ; Restore all EGP registers
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 jmp	 EXIT
.386
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

INIT	 endp			; End INIT Procedure
	 NPPROC  CHECK_ARGS -- Check the Command Line Arguments
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

The command line arguments are of the form:

nnnn		 Disk size of nnnn kilobytes
nnn		 Sector size in bytes (power of two)
nnn		 # directory entries in root
/XMS		 Extended memory (XMS) disk
/XMSHI		 Extended memory (XMS) disk from highest linear address
/EMS		 Expanded memory (EMS) disk
/EXT		 Top down extended memory disk
/NOMAX		 Don't require 386MAX to be in the system
/INT		 Signal INT 03h to call our debugger

|

	 pushad 		; Save all EGP registers
	 REGSAVE <ds,es>	; Save segment registers

; If this is MS-DOS 7 or later, the minimum and maximum #
; bytes/sector is different

; Note that we're checking for not IBM only on the theory that
; any other DOS 7.00 is more likely to be based on MS code
; than IBM code.

	cmp	DOSVER,0700h	; Izit DOS 7 or later?
	jb	short @F	; Jump if not

	cmp	DOSOEM,@DOSOEM_IBM ; Izit PC-DOS 7.00?
	je	short @F	; Jump if so

	mov	BPS_MIN,@BPS_MIN2 ; Use different values
	mov	BPS_MAX,@BPS_MAX2 ; ...
@@:
	 lds	 si,RH_VEC	; DS:SI ==> request header
	 assume  ds:nothing	; Tell the assembler about it

	 lds	 si,ds:[si].INIT_CMD_VEC ; DS:SI ==> command line
	 assume  ds:nothing	; Tell the assembler about it

	 push	 cs		; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it
CHECK_ARGS_INIT:		; Initial scan to skip over file name
	 lodsb			; Get the next byte

	 cmp	 al,CR		; If CR, then no arguments
	 je	 near ptr CHECK_ARGS_VALID ; ...and we use the defaults

	 cmp	 al,LF		; If LF, then no arguments
	 je	 near ptr CHECK_ARGS_VALID ; ...and we use the defaults

	 cmp	 al,' '         ; If a space, then we've reached the end
	 je	 short CHECK_ARGS_SRCH ; Yup

	 and	 al,al		; If zero, we've reached the end
	 jnz	 short CHECK_ARGS_INIT ; Not there as yet, continue looking
CHECK_ARGS_SRCH:		; Search for arguments
	 call	 SKIP_WHITE	; Skip over white space
CHECK_COMP:
	 cmp	 al,CR		; Check for terminator
	 je	 near ptr CHECK_ARGS_VALID ; Jump if nothing more

	 cmp	 al,LF		; Check for terminator
	 je	 near ptr CHECK_ARGS_VALID ; Jump if nothing more

	 cmp	 al,';'         ; Check for terminator
	 je	 near ptr CHECK_ARGS_VALID ; Jump if nothing more

	 cmp	 al,'/'         ; Check for separator
	 je	 short CHECK_ARGS_SEP ; Jump if so

; Unless the next character is a digit, we'll ignore it so as
; to allows comment text between the numbers as does VDISK.

	 cmp	 al,'0'         ; Check for digit
	 jb	 short CHECK_ARGS_SRCH ; Ignore it

	 cmp	 al,'9'         ; Check upper limit
	 ja	 short CHECK_ARGS_SRCH ; Ignore it, go around again

	 dec	 si		; Back up to first character
	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIND	; Convert the number at DS:SI to binary EAX
	 ARGERR  MSG_TOOBIG	; In case of error
	 jc	 near ptr CHECK_ARGS_ERR ; Jump if too large
				; DS:SI ==> next character

	 mov	 di,NEXTIND	; Get next index

	 cmp	 di,NEXTLIM*(type NEXTNUM) ; Check for out of range
	 ARGERR  MSG_TOOMANY	; In case of error
	 jae	 near ptr CHECK_ARGS_ERR ; Too many numbers

	 shl	 di,1		; Convert from word index (NEXTNUM) to
				; dword index (NEXTMAX)

	 cmp	 eax,NEXTMAX[di] ; Izit too big?
	 ARGERR  MSG_TOOBIG	; In case of error
	 ja	 near ptr CHECK_ARGS_ERR ; Jump if so

	 shr	 di,1		; Convert back

	 add	 NEXTIND,type NEXTNUM ; Skip over it for next time
	 mov	 di,NEXTNUM[di] ; ES:DI ==> next numeric value

	 mov	 es:[di],eax	; Save new value

	 jmp	 CHECK_ARGS_SRCH ; Go around again

CHECK_ARGS_SEP:

; Check for /EXT

	 cmp	 ds:[si-1].EDD,'TXE/' ; Check for EXT
	 mov	 MOVETYPE,@MOVE_EXT ; Assume so
	 mov	 MSG_DRVERR1.EDD,' TXE'
	 mov	 MSG_NODRV1.EDD,' TXE'
	 mov	 TYPE_TXT.EDD,' TXE'
	 je	 near ptr CHECK_ARGS_SEP1 ; Good guess

; Check for /EMS

	 cmp	 ds:[si-1].EDD,'SME/' ; Check for EMS
	 mov	 MOVETYPE,@MOVE_EMS ; Assume so
	 mov	 MSG_DRVERR1.EDD,' SME'
	 mov	 MSG_NODRV1.EDD,' SME'
	 mov	 TYPE_TXT.EDD,' SME'
	 je	 short CHECK_ARGS_SEP1 ; Good guess

; Check for /XMS or /XMSHI

	 cmp	 ds:[si-1].EDD,'SMX/' ; Check for XMS
	 mov	 MOVETYPE,@MOVE_XMS ; Assume so
	 mov	 MSG_DRVERR1.EDD,' SMX'
	 mov	 MSG_NODRV1.EDD,' SMX'
	 mov	 TYPE_TXT.EDD,' SMX'
	 je	 short CHECK_ARGS_SEP0 ; Good guess

; Check for /NOMAX

	 cmp	 ds:[si-1].EDD,'MON/' ; Check for start of NOMAX
	 jne	 short CHECK_ARGS_XNOMAX ; Jump if not

	 cmp	 ds:[si+3].ELO,'XA' ; Check for end of NOMAX
	 jne	 short CHECK_ARGS_XNOMAX ; Jump if not

	 and	 LCL_FLAG,not @LCL_NOMAX ; Clear prohibition
	 add	 si,5		; Skip over text

	 jmp	 CHECK_ARGS_SRCH ; Join common code

CHECK_ARGS_XNOMAX:

; Check for /INT

	 cmp	 ds:[si-1].EDD,'TNI/' ; Check for /INT
	 jne	 short CHECK_ARGS_XINT ; Jumpif not

	 int	 03h		; Call our debugger

	 jmp	 short CHECK_ARGS_SEP1 ; Join common code

CHECK_ARGS_XINT:
CHECK_ARGS_INV:
	 ARGERR  MSG_INVARG	; In case of error

	 jmp	 CHECK_ARGS_ERR ; Not this time

; Check for /XMSHI keyword

CHECK_ARGS_SEP0:
	 cmp	 ds:[si+3].ELO,'IH' ; Izit tail of 'XMSHI'?
	 jne	 short CHECK_ARGS_SEP1 ; Jump if not

	 or	 LCL_FLAG,@LCL_XMSHI ; Mark as specified
	 add	 si,2		; Skip over tail
CHECK_ARGS_SEP1:
	 add	 si,3		; Skip over text

	 jmp	 CHECK_ARGS_SRCH ; Join common code

CHECK_ARGS_VALID:
	 push	 cs		; Setup DS for data references
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

; Ensure there are a minimum # directory entries in case the user
; specifes fewer than 16 and we round that number down to zero (not
; a happy ending).

	 cmp	 LCL_NDIR,@NDIR_MIN ; Izit below the minimum?
	 jae	 short @F	; Jump if not

	 mov	 LCL_NDIR,@NDIR_MIN ; Set to minimum
@@:

; If /EXT specified, check to see if there's enough EXT memory.  If not
; the user probably confused XMS with EXT and should have used /XMS.
; If this is the case, display a message and switch to /XMS.

	 cmp	MOVETYPE,@MOVE_EXT ; Is this an /EXT move?
	 jne	short CHECK_ARGS_XEXT ; Nope, continue on

	 mov	 ah,88h 	; Get extended memory size
	 int	 15h		; Request BIOS service

	 movzx	 eax,ax 	; Zero to use as dword

	 cmp	 eax,DISKKILO	; Is there enough EXT memory?
	 jae	 short CHECK_ARGS_XEXT ; Jump if so

	 mov	 MOVETYPE,@MOVE_XMS ; Switch to /XMS memory
	 mov	 MSG_DRVERR1.EDD,' SMX'
	 mov	 MSG_NODRV1.EDD,' SMX'
	 mov	 TYPE_TXT.EDD,' SMX'

	 DOSCALL @STROUT,MSG_XMS_SWITCH ; Display memory switch message

CHECK_ARGS_XEXT:

; Move in the proper MEM2DISK and DISK2MEM code
; Note that we *MUST* move the MEM2DISK code first in order to
; preserve

	 movzx	 bx,MOVETYPE	; Get move type
	 shl	 bx,1		; Times two to index table of words
	 mov	 si,M2D_SRC[bx] ; DS:SI ==> move source offset
	 mov	 di,QDISK_END	; ES:DI ==> ...  destin
	 mov	 MEM2DISK,di	; Save as new address
	 mov	 cx,M2D_END[bx] ; CX = move source ending address
	 sub	 cx,si		; Less source start to get length
S16  rep movsb			; Move into place

	 mov	 si,D2M_SRC[bx] ; DS:SI ==> move source offset
	 mov	 DISK2MEM,di	; Save as new address
	 mov	 cx,D2M_END[bx] ; CX = move source ending address
	 sub	 cx,si		; Less source start to get length
S16  rep movsb			; Move into place
	 mov	 QDISK_END,di	; Save as ending address

	 movzx	 ax,BPB_SPC	; Get # sector per cluster from BPB
	 bsf	 ax,ax		; Get low-order bit index
	 mov	 SPCLG2,al	; Save as log base 2

; Check disk size against maximum

	 call	 GET_MAXSIZE	; Get the maximum size into EAX
	 jc	 near ptr CHECK_ARGS_ERR ; Jump if something went wrong

	 cmp	 eax,DISKKILO	; Check against requested amount
	 jae	 short CHECK_ARGS_DEF ; Jump if it's enough

	 mov	 DISKKILO,eax	; Reduce our requested amount
CHECK_ARGS_DEF:
	 mov	 ax,LCL_BPS	; Get local copy of BPB_BPS
	 mov	 BPB_BPS,ax	; Save in BPB

; Check BPB_BPS for validity (power of two)

	 mov	 ax,BPB_BPS	; Get # bytes per sector from BPB
	 bsf	 ax,ax		; Get low-order bit index
	 mov	 BPSLG2,al	; Save as log base 2
	 xor	 bx,bx		; Zero a register
	 bts	 bx,ax		; Set the bit

	 cmp	 bx,BPB_BPS	; Ensure the same
	 jne	 short CHECK_ARGS_BPSDEF ; Jump if not a power of two

	 cmp	 bx,BPS_MIN	; Check against minimum
	 jb	 short CHECK_ARGS_BPSMIN ; Jump if it's too small

	 cmp	 bx,BPS_MAX	; Check against maximum
	 jbe	 short CHECK_ARGS_DISK ; Jump if it's within range

	 mov	 ax,BPS_MAX	; Use maximum

	 jmp	 short CHECK_ARGS_BPSCOM ; Join common code

CHECK_ARGS_BPSMIN:
CHECK_ARGS_BPSDEF:
	 mov	 ax,BPS_MIN	; Use minimum
CHECK_ARGS_BPSCOM:
	 mov	 BPB_BPS,ax	; Save for later use
	 bsf	 ax,ax		; Get low-order bit index
	 mov	 BPSLG2,al	; Save as log base 2
CHECK_ARGS_DISK:
	 call	 SET_NDIR	; Set BPB_NDIR based upon BPB_BPS

; See if the total number of sectors in the disk fits within
; the BPB-imposed limit of 16 bits (the size of BPB_SPD).

	 mov	 eax,DISKKILO	; Get requested disk size in kilobytes
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 mov	 cl,BPSLG2	; Get log base 2 of BPB_BPS
	 shr	 eax,cl 	; Divide by BPB_BPS to get # sectors in disk

	 cmp	 eax,0FFFFh	; Duzit fit within 16-bits?
	 jbe	 short CHECK_ARGS_DIR ; Jump if so

; If we're running under DOS 4.x or later, we can allow the number
; of sectors per disk to exceed 64K

	 cmp	 DOSVER,0400h	; Izit DOS 4.x or later?
	 jb	 short CHECK_ARGS_BPSINC ; Jump if not

	 mov	 BPB_SPD,0	; Mark as using huge field
	 mov	 BPB_HUGE,eax	; Save as huge # sectors per disk

	 jmp	 short CHECK_ARGS_DIR1 ; Join common code

CHECK_ARGS_BPSINC:
	 inc	 BPSLG2 	; Increase log base 2
	 shl	 BPB_BPS,1	; Double the # bytes per sector (must be
				; a power of two)
	mov	ax,BPS_MAX	; Get maximum # bytes/sector

	cmp	BPB_BPS,ax	; Check against maximum
	jbe	short CHECK_ARGS_DISK ; Jump if it's within range

	 inc	 SPCLG2 	; Increase log base 2
	 shl	 BPB_SPC,1	; Double the # sectors per cluster (must be
				; a power of two)
	 ARGERR  MSG_INCOMPAT	; In case of error
	 jnc	 near ptr CHECK_ARGS_DEF ; Use default values

	 jmp	 CHECK_ARGS_ERR ; Join common error code

CHECK_ARGS_DIR:
	 mov	 BPB_SPD,ax	; Save as # sectors per disk
CHECK_ARGS_DIR1:

; Ensure # directory entries fits evenly into a sector multiple
; at 32 bytes per entry

	 movzx	 eax,BPB_NDIR	; Get # directory entries
	 shl	 eax,5-0	; Convert from 32-bytes to bytes
	 call	 ROUND_SECT	; Round up to sector boundary
	 mov	 cl,BPSLG2	; Get log base 2 of BPB_BPS
	 shr	 eax,cl 	; Divide by BPB_BPS to get
				; # sectors in DIR
	 mov	 ebx,eax	; Copy # sectors in directory

; Calculate # clusters in the FAT as
;
;  (BPB_SPD - ((32 * BPB_NDIR) / BPB_BPS) - (@NFATS * BPB_SPF) - @NRSV) / BPB_SPC

	 movzx	 eax,BPB_SPD	; Get # sectors per disk

	 and	 ax,ax		; Izit huge?
	 jnz	 short @F	; Jump if not

	 mov	 eax,BPB_HUGE	; Get # sectors per disk
@@:
	 sub	 eax,ebx	; Less # sectors in DIR

	 movzx	 ebx,BPB_SPF	; Get # sectors per FAT
	 imul	 ebx,@NFATS	; Times # FATs
	 sub	 eax,ebx	; Less # sectors in FATs

	 sub	 eax,@NRSV	; Less # reserved sectors

; Convert from sectors to # clusters rounding up to next cluster boundary

	 movzx	 ebx,BPB_SPC	; Get # sectors per cluster
	 dec	 ebx		; Less one for rounding
	 add	 eax,ebx	; Add to round up
	 mov	 cl,SPCLG2	; Get log base 2 of BPB_SPC
	 shr	 eax,cl 	; Divide by BPB_SPC to get
				; # clusters in FAT

; Ensure # clusters <= 0FFF6h (maximum for 16-bit FAT)

	 cmp	 eax,0000FFF6h	; Duzit fit in 16-bit FAT?
	 ja	 near ptr CHECK_ARGS_BPSINC ; Not this time, increment BPS

	 mov	 BOOT_TYP1,'2'  ; Mark as 12-bit FAT

	 cmp	 ax,4086	; Izit a 16-bit FAT?
	 jbe	 short @F	; Jump if not

	 mov	 BOOT_TYP1,'6'  ; Mark as 16-bit FAT
@@:
	 mov	 NCIF,ax	; Save as # clusters in FAT

; Calculate byte offset and size of various disk parts

; By definition the boot record is in the first sector and occupies
; exactly one sector.

; Calculate offset & size of FAT
; It starts in the second sector and has a byte length of
;    ceil(NCIF x 3/2) if we're using a 12-bit FAT
;    ceil(NCIF x 4/2) ...	       16-...
; Drives with more than 4086 clusters have a 16-bit FAT;
; drives with 4086 or fewer clusters have a 12-bit FAT.

	 movzx	 eax,BPB_BPS	; Skip over boot sector
	 imul	 eax,@NRSV	; Times # reserved sectors
;;;;;;;; call	 ROUND_SECT	; Round up to sector boundary
	 mov	 FAT_OFF,eax	; ...to get byte offset of FAT

	 movzx	 eax,NCIF	; Get # clusters in FAT

	 cmp	 ax,4086	; Izit a 16-bit FAT?
	 jbe	 short CHECK_ARGS_FAT12 ; Jump if not

	 shl	 eax,1		; Times (4/2)

	 jmp	 short CHECK_ARGS_FATCOM ; Join common code

CHECK_ARGS_FAT12:
	 imul	 ax,3		; Times multiplier
	 inc	 ax		; Round up
	 shr	 ax,1		; Divide by two
CHECK_ARGS_FATCOM:
	 call	 ROUND_SECT	; Round up to sector boundary
	 mov	 FAT_LEN,eax	; ...to get byte length of FAT

; Calculate # sectors per FAT

;;;;;;;; mov	 eax,FAT_LEN	; Get byte length of FAT
	 mov	 cl,BPSLG2	; Get log base 2 of BPB_BPS
	 shr	 eax,cl 	; Divide by BPB_BPS to get SPF

; If the new value is larger than we used before,
; start over again with the new value.	If it's smaller
; than before, accept it so as to terminate the algorithm.
; Note that the initial value for BPB_SPF is artifically
; small so we are always increasing it.

	 xchg	 ax,BPB_SPF	; Save for later use

	 cmp	 ax,BPB_SPF	; Is the old one smaller than the new one?
	 jb	 near ptr CHECK_ARGS_DIR1 ; Jump if so

; Calculate offset & size of DIR
; It starts in the sector following FAT and has a byte length of
;    BPB_NDIR x (type DIR_STR)

	 mov	 eax,FAT_OFF	; Get byte offset of FAT
	 add	 eax,FAT_LEN	; Plus its byte length
	 call	 ROUND_SECT	; Round up to sector boundary
	 mov	 DIR_OFF,eax	; ...to get byte offset of DIR

	 movzx	 eax,BPB_NDIR	; Get # directory entries
	 shl	 eax,5-0	; Times (type DIR_STR)
	 call	 ROUND_SECT	; Round up to sector boundary
	 mov	 DIR_LEN,eax	; ...to get byte length of DIR

; Ensure the disk size is large enough to hold the boot sector,
; FAT and DIR, and one cluster of data

	 mov	 eax,DIR_OFF	; Get byte offset of DIR
	 add	 eax,DIR_LEN	; Plus its byte length
	 call	 ROUND_SECT	; Round up to sector boundary

	 movzx	 ebx,BPB_SPC	; Get # sectors per cluster
	 mov	 cl,BPSLG2	; Get log base 2 of BPB_BPS
	 shl	 ebx,cl 	; Times BPB_BPS to get # bytes per cluster
	 add	 eax,ebx	; Add into accumulator
	 add	 eax,1024-1	; Round up to 1KB boundary
	 shr	 eax,10-0	; Convert from bytes to 1KB
				; ...to get the minimum disk size
	 cmp	 eax,DISKKILO	; Compare 'em
	 ARGERR  MSG_INSUF	; In case of error
	 ja	 near ptr CHECK_ARGS_ERR ; Jump if it's too large

; Allocate EMS or XMS memory for the disk

	 cmp	 MOVETYPE,@MOVE_XMS ; Izit an XMS disk?
	 je	 short CHECK_ARGS_XMS ; Yes

	 cmp	 MOVETYPE,@MOVE_EMS ; Izit an EMS disk?
	 je	 short CHECK_ARGS_EMS ; Yes

	 mov	 al,15h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old INT 15h handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT15_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT15_VEC.VSEG,es

	 jmp	 CHECK_ARGS_END ; Join common ending code

CHECK_ARGS_EMS:
	 mov	 ebx,DISKKILO	; Get disk size in 1KB
	 add	 ebx,16-1	; Round up to multiple of 16KB
	 rcr	 ebx,1		; Include CF
	 shr	 ebx,14-10-1	; Convert from 1KB to 16KB

	 cmp	 ebx,64*1024-1	; Check against maximum
	 ARGERR  MSG_INSUF	; In case of error
	 ja	 near ptr CHECK_ARGS_ERR ; Jump if it's too large

	 EMMCALL @EMM_SETPAGE	; Allocate memory

	 and	 ah,ah		; Check return code
	 ARGERR  MSG_DRVERR,ah	; In case of error
	 jnz	 short CHECK_ARGS_ERR ; Jump if something went wrong

	 mov	 HNDL,dx	; Save the handle

; Set handle name to 386DISK

CHECK_ARGS_EMS1:
	 lea	 si,HNDLNAME	; DS:SI ==> handle name
	 mov	 al,01h 	; Subfunction to set handle name
	 EMMCALL @EMM_GETSETNAME ; Set handle name

	 cmp	 ah,0A1h	; Check for duplicate name
	 jne	 short CHECK_ARGS_EMS2 ; Jump if not

	 inc	 HNDLNAME[7]	; Skip to next name

	 jmp	 short CHECK_ARGS_EMS1 ; Go around again

CHECK_ARGS_EMS2:
	 and	 ah,ah		; Check return code
	 ARGERR  MSG_DRVERR,ah	; In case of error
	 jnz	 short CHECK_ARGS_ERR ; Jump if something went wrong

	 jmp	 short CHECK_ARGS_END ; Join common ending code

CHECK_ARGS_XMS:

; Check for XMSHI

	 test	 LCL_FLAG,@LCL_XMSHI ; Izit specified?
	 jz	 short @F	; Jump if not

	 call	 ALLOC_XMSHI	; Allocate XMS memory at the highest address
	 jnc	 short CHECK_ARGS_END ; Jump if all went well

	 jmp	 short CHECK_ARGS_ERR ; Jump if something went wrong

@@:
	 mov	 edx,DISKKILO	; Get disk size in 1KB
	 mov	 ah,XMS_GETXMBFN ; Allocate memory
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 ARGERR  MSG_DRVERR,bl	; In case of error
	 jne	 short CHECK_ARGS_ERR ; Jump if something went wrong

	 mov	 HNDL,dx	; Save the handle
CHECK_ARGS_END:
	 les	 bx,RH_VEC	; ES:BX ==> request header
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[bx].INIT_UNITS,1	; # diskette units
	 mov	 ax,QDISK_END	; Get ending offset
	 mov	 es:[bx].INIT_END_VEC.VOFF,ax
	 mov	 es:[bx].INIT_END_VEC.VSEG,cs

; Save offset and segment of BPB pointer array in data packet

	 mov	 es:[bx].INIT_BPB_VEC.VOFF,offset cs:BPB_PTR
	 mov	 es:[bx].INIT_BPB_VEC.VSEG,cs

	 clc			; Indicate all went well

	 jmp	 short CHECK_ARGS_EXIT ; Join common exit code

CHECK_ARGS_ERR:
	 stc			; Indicate an error occurred
CHECK_ARGS_EXIT:
	 REGREST <es,ds>	; Restore
	 popad			; ...

	 ret			; Return to caller with carry flag

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

CHECK_ARGS endp 			; End CHECK_ARGS procedure
	 NPPROC  GET_MAXSIZE -- Get Maximum Available Disk Size
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Get the maximum available disk size.

On exit:

CF	 =	 0 if all went OK
EAX	 =	 maximum available disk size in 1KB

CF	 =	 1 otherwise with
ARGERR	 =	 error message

|

	 REGSAVE <ebx,ecx,edx,si,di,es> ; Save registers

	 cmp	 MOVETYPE,@MOVE_XMS ; Izit an XMS disk?
	 je	 short GET_MAXSIZE_XMS ; Yes

	 cmp	 MOVETYPE,@MOVE_EMS ; Izit an EMS disk?
	 je	 short GET_MAXSIZE_EMS ; Yes

	 mov	 ah,88h 	; Get extended memory size
	 int	 15h		; Request BIOS service

	 movzx	 eax,ax 	; Zero to use as dword

	 push	 eax		; Save return value

	 mov	 ebx,DISKKILO	; Get requested disk size

	 cmp	 ebx,eax	; Use the smaller
	 jbe	 short @F	; Jump if requested amount is smaller

	 mov	 ebx,eax	; Use available amount
@@:
	 sub	 eax,ebx	; Subtract out amount we're using
	 mov	 EXTSIZE,ax	; Save as new size of extended memory

	 mov	 ebx,eax	; Copy and zero high-order word
	 shl	 ebx,10-0	; Convert from 1KB to bytes
	 add	 ebx,1024*1024	; Plus first megabyte
	 mov	 EXTBASE,ebx	; Save as base of disk

	 pop	 eax		; Restore return value

	 jmp	 GET_MAXSIZE_COM ; Join common code with result in EAX

GET_MAXSIZE_EMS:

; Ensure EMS driver installed

	 mov	 al,67h 	; Interrupt #
	 DOSCALL @GETINT	; Return with ES:BX ==> old handler
	 assume  es:nothing	; Tell the assembler about it

	 lea	 di,es:[0].DD_NAME ; ES:DI ==> device name
	 lea	 si,EMSNAME	; DS:SI ==> "EMMXXXX0"
	 mov	 cx,EMSNAME_LEN ; CX = length of name
    repe cmpsb			; Compare 'em
	 ARGERR  MSG_NODRV	; In case of error
	 jne	 short GET_MAXSIZE_ERR ; Not this time

	 EMMCALL @EMM_GETPGCT	; Return with BX = # available, DX = total

	 and	 ah,ah		; Check return code
	 ARGERR  MSG_DRVERR,ah	; In case of error
	 jnz	 short GET_MAXSIZE_ERR ; Jump if something went wrong

	 movzx	 eax,bx 	; Copy to return register
	 shl	 eax,14-10	; Convert from 16KB to 1KB

	 jmp	 short GET_MAXSIZE_COM ; Join common code with result in EAX

GET_MAXSIZE_XMS:

; Ensure XMS driver installed

	 mov	 ax,4300h	; Check for presence
	 int	 2Fh		; Request multiplexor service

	 cmp	 al,80h 	; Izit installed?
	 ARGERR  MSG_NODRV	; In case of error
	 jne	 short GET_MAXSIZE_ERR ; Not this time

	 mov	 ax,4310h	; Get address of driver control
	 int	 2Fh		; Request multiplexor service
	 assume  es:nothing	; Tell the assembler about it

	 mov	 XMSDRV_VEC.VOFF,bx ; Save for later use
	 mov	 XMSDRV_VEC.VSEG,es

	 mov	 ah,@XMS_VERS	; Get version # into AH,AL
	 call	 XMSDRV_VEC	; Request XMS service
				; AH = major version #
				; AL = minor ...
				; BX = debugging version #
				; DX = 1 iff HMA is available

	 cmp	 ah,03h 	; Izit version 3.00 or later?
	 jb	 short @F	; Jump if not

	 mov	 XMS_GETXMBFN,@XMS_GET2XMB ; Use extended functions
	 mov	 XMS_QRYXMBFN,@XMS_QRY2XMB ; ...
@@:
	 xor	 eax,eax	; Zero to use as dword
;;;;;;;; xor	 edx,edx	; ...		       (not used)
	 mov	 ah,XMS_QRYXMBFN ; Request size of available XMBs
	 mov	 bl,0		; Set to non-error value
	 call	 XMSDRV_VEC	; Request XMS service
				; EAX = largest free block
				; EDX = total amount free
				; ECX = maximum physical address
	 test	 bl,80h 	; Izit in error?
	 ARGERR  MSG_DRVERR,bl	; In case of error
	 jnz	 short GET_MAXSIZE_ERR ; Jump if something went wrong
GET_MAXSIZE_COM:
	 clc			; Indicate all went well

	 jmp	 short GET_MAXSIZE_EXIT ; Join common exit code

GET_MAXSIZE_ERR:
	 stc			; Indicate something went wrong
GET_MAXSIZE_EXIT:
	 REGREST <es,di,si,edx,ecx,ebx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller with carry flag

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

GET_MAXSIZE endp		; End GET_MAXSIZE procedure
	 NPPROC  ROUND_SECT -- Round Up to Sector Boundary
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing
COMMENT|

Round up to sector boundary

On entry:

EAX	 =	 byte offset

On exit:

EAX	 =	 rounded value

|

	 push	 ecx		; Save register

	 movzx	 ecx,BPB_BPS	; Get # bytes per sector from BPB
	 add	 eax,ecx	; Round up to sector boundary
	 dec	 eax		; ...but not too far
	 mov	 cl,BPSLG2	; Get log base 2 of BPB_BPS
	 shr	 eax,cl 	; Round down
	 shl	 eax,cl 	; Round up

	 pop	 ecx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

ROUND_SECT endp 		; End ROUND_SECT procedure
	 NPPROC  SET_NDIR -- Set BPB_NDIR Based Upon BPB_BPS
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set BPB_NDIR based upon BPB_BPS

Because of certain assumptions in programs such as CHKDSK, the number
of directory entries in the root is limited to strictly less than
BPB_BPS * (256/32).  This value comes from the fact that CHKDSK
divides the # bytes in the directory (BPB_NDIR*32) by the # bytes per
sector (BPB_BPS) using an 8-bit divide.  If BPB_NDIR is >= BPB_BPS * 8
then the 8-bit divide overflows.

There's more:  For reasons that escape me, DOS (at least MS-DOS 5.0)
imposes another restriction on the number of directory entries where
it fails if the number of directory entries is > ((BPS*8)-(BPS/32))
which is the same as 255*(BPS/32).  This is equivalent to saying that
the number of sectors allocated to the root directory can be no larger
than 255.

Also, some programs (such as STACKER) require that the BPB_NDIR be a
multiple of 16.

|

	 REGSAVE <ax,bx>	; Save registers

	 mov	 ax,BPB_BPS	; Get # bytes per sector
	 shr	 ax,5		; AX = BPS/32 (# dir entries per sector)
	 imul	 ax,255 	; AX = 255*(BPS/32)

	 mov	 bx,LCL_NDIR	; Get local copy of BPB_NDIR

	 cmp	 bx,ax		; Use the smaller
	 jbe	 short @F	; Jump if specified value is smaller

	 mov	 bx,ax		; Use limited value
@@:
	 and	 bx,not (16-1)	; Round down to multiple of 16

	 mov	 BPB_NDIR,bx	; Save in BPB

	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_NDIR endp			; End SET_NDIR procedure
	 NPPROC  ZEROSEG -- Zero Bytes In Segment
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Zero bytes in segment

On entry:

ECX	 =	 # bytes to zero
ES:DI	 ==>	 start of region to zero

|

	 REGSAVE <ax,ebx,ecx,di,es> ; Save registers

	 xor	 ax,ax		; Zero value

	 movzx	 ebx,di 	; Get initial offset
	 neg	 bx		; Negate to subtract from 64K

; Zero the rest of the region if it fits in the segment

	 cmp	 ecx,ebx	; Will the STOS overflow?
	 ja	 short @F	; Jump if so

	 mov	 ebx,ecx	; Use actual length
@@:
	 push	 cx		; Save for a moment
	 mov	 cx,bx		; Use maximum
     rep stosb			; Zero it
	 pop	 cx		; Restore
ZEROSEG_NEXT:
	 sub	 ecx,ebx	; Less amount stored
	 jz	 short ZEROSEG_EXIT ; Join common exit code

; Skip to next 64KB

	 mov	 bx,es		; Get current segment
	 add	 bx,1000h	; Skip to next 64KB
	 mov	 es,bx		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> next chunk to zero
	 mov	 ebx,ecx	; Save as length of STOS

	 cmp	 ecx,64*1024	; Will the STOS overflow?
	 jbe	 short @F	; Jump if not

	 mov	 ebx,64*1024	; Use maximum of 64KB
@@:
	 push	 ecx		; Save for a moment
	 mov	 ecx,ebx	; Copy as word length
	 shr	 ecx,1-0	; Convert from bytes to words
     rep stosw			; Zero it
	 jnc	 short @F	; Jump if ECX was even
S16	 stosb			; Save extra byte
@@:
	 pop	 ecx		; Restore

	 jmp	 short ZEROSEG_NEXT ; Go around again

ZEROSEG_EXIT:
	 REGREST <es,di,ecx,ebx,ax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ZEROSEG  endp			; End ZEROSEG procedure
	 NPPROC  ALLOC_XMSHI -- Allocate XMS Memory From Highest Address
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Allocate XMS memory from the highest address

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <eax,bx,ecx,edx,esi,edi,bp> ; Save registers

COMMENT|

Loop through available XMS memory allocating blocks
looking for the one with the highest linear address.

The algorithm used is as follows:

* Allocate all XMS memory, saving the handles on the stack.

* For any handle whose size is big enough to contain our disk, get its
  linear address (by locking the handle) and compare against the
  highest linear address seen so far.

* After all memory is allocated, if we found a region large enough,
  free that region, allocate the difference between the region size
  and our disk size (which should be at the start of the region), and
  then allocate the disk size we need (which should be at the end of
  the region) thus using the highest linear address.

|

; Note that the equates below are chosen from the set
; of invalid handle numbers

@LAST_HNDL equ	 -1		; Marker on stack for no more handles
@SKIP_HNDL equ	 -2		; ...		      handle to skip (in HNDL)

	 xor	 esi,esi	; Initialize highest linear address so far
	 push	 @LAST_HNDL	; Save ending handle marker
ALLOC_XMSHI_NEXT:
	 xor	 eax,eax	; Zero to use as dword
	 xor	 edx,edx	; ...
	 mov	 ah,XMS_QRYXMBFN ; Request size of available XMBs
	 mov	 bl,0		; Set to non-error value
	 call	 XMSDRV_VEC	; Request XMS service
				; EAX = largest free block
				; EDX = total amount free
				; Ignore error return (AX=0, BL>=80)
	 test	 bl,80h 	; Izit in error?
	 jnz	 short ALLOC_XMSHI_DONE ; Jump if not

	 mov	 edx,eax	; Allocate the largest available block
	 mov	 ecx,eax	; Save size in 1KB for later use
	 mov	 ah,XMS_GETXMBFN ; Allocate memory
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 ARGERR  MSG_DRVERR,bl	; In case of error
	 jne	 near ptr ALLOC_XMSHI_ERRPOP ; Jump if something went wrong

	 push	 dx		; Save the handle to free later

	 cmp	 ecx,DISKKILO	; Izit the allocated size big enough?
	 jb	 short ALLOC_XMSHI_NEXT ; Jump if not

	 mov	 ah,@XMS_LCKXMB ; Lock the memory
	 call	 XMSDRV_VEC	; Request XMS service
				; DX:BX = linear address

	 cmp	 ax,1		; Check return code
	 ARGERR  MSG_DRVERR,bl	; In case of error
	 jne	 near ptr ALLOC_XMSHI_ERRPOP ; Jump if something went wrong

	 shl	 edx,16 	; Shift to high-order word
	 mov	 dx,bx		; EDX = linear address

	 cmp	 edx,esi	; Use the higher address
	 jb	 short @F	; Jump if not larger

	 mov	 esi,edx	; Use higher linear address
	 mov	 edi,ecx	; Save the size in 1KB
	 pop	 HNDL		; Get the handle
	 push	 HNDL		; Put it back
@@:

; Unlock the memory

	 pop	 dx		; Get the handle
	 push	 dx		; Put it back
	 mov	 ah,@XMS_UNLXMB ; Unlock the memory
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 ARGERR  MSG_DRVERR,bl	; In case of error
	 jne	 near ptr ALLOC_XMSHI_ERRPOP ; Jump if something went wrong

	 jmp	 ALLOC_XMSHI_NEXT ; Go around again

COMMENT|

We've found the XMS block with the highest linear address
and its handle is in HNDL.  That block may be larger than
the size we need, so we must free it, allocate the difference
between its size and what we need, then allocate the remainder.

Register Usage:

HNDL	 =	 handle of largest block (if any)
DI	 =	 size of largest block in 1KB (if any)

|

ALLOC_XMSHI_DONE:
	 mov	 dx,HNDL	; Get the handle
	 mov	 bl,0A0h	; Error code for insufficient memory

	 cmp	 dx,-1		; Izit valid?
	 ARGERR  MSG_DRVERR,bl	; In case of error
	 je	 short ALLOC_XMSHI_ERRPOP ; Jump if something went wrong

	 mov	 ah,@XMS_RELXMB ; Release the handle and memory
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 ARGERR  MSG_DRVERR,bl	; In case of error
	 jne	 short ALLOC_XMSHI_ERRPOP ; Jump if something went wrong

; Search through the handles on the stack for this one and zap it
; Note that this code ASSUMEs that the handle will be found

	 mov	 bp,sp		; SS:BP ==> handles on stack
@@:
	 cmp	 dx,[bp].ELO	; Izit our handle?
	 je	 short @F	; Jump if so

	 add	 bp,2		; Skip to next handle

	 jmp	 short @B	; Go around again

@@:
	 mov	 [bp].ELO,@SKIP_HNDL ; Mark as to be skipped

; Calculate the difference in 1KB and allocate it

	 mov	 edx,edi	; Get size of the highest block
	 sub	 edx,DISKKILO	; Less size of what we need
	 jz	 short @F	; Jump if it's exact

	 mov	 ah,XMS_GETXMBFN ; Allocate memory
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 ARGERR  MSG_DRVERR,bl	; In case of error
	 jne	 short ALLOC_XMSHI_ERRPOP ; Jump if something went wrong

	 push	 dx		; Save the handle to free later
@@:
	 mov	 edx,DISKKILO	; Get the size we need
	 mov	 ah,XMS_GETXMBFN ; Allocate memory
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 ARGERR  MSG_DRVERR,bl	; In case of error
	 jne	 short ALLOC_XMSHI_ERRPOP ; Jump if something went wrong

	 mov	 HNDL,dx	; Save the handle

; Free all the handles on the stack

@@:
	 pop	 dx		; Get the next handle

	 cmp	 dx,@LAST_HNDL	; Izit the last one?
	 je	 short ALLOC_XMSHI_EXIT ; Jump if so (note CF=0)

	 cmp	 dx,@SKIP_HNDL	; Izit to be skipped?
	 je	 short @B	; Jump if so

	 mov	 ah,@XMS_RELXMB ; Release the handle and memory
	 call	 XMSDRV_VEC	; Request XMS service
				; Ignore error return
	 jmp	 short @B	; Go around again


; Some error occurred and we must free the handles on the stack

ALLOC_XMSHI_ERRPOP:

; Free all the handles on the stack

@@:
	 pop	 dx		; Get the next handle

	 cmp	 dx,@LAST_HNDL	; Izit the last one?
	 je	 short ALLOC_XMSHI_ERR ; Jump if so

	 cmp	 dx,@SKIP_HNDL	; Izit to be skipped?
	 je	 short @B	; Jump if so

	 mov	 ah,@XMS_RELXMB ; Release the handle and memory
	 call	 XMSDRV_VEC	; Request XMS service
				; Ignore error return
	 jmp	 short @B	; Go around again


ALLOC_XMSHI_ERR:
	 stc			; Indicate something went wrong
ALLOC_XMSHI_EXIT:
	 REGREST <bp,edi,esi,edx,ecx,bx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ALLOC_XMSHI endp		; End ALLOC_XMSHI procedure
	 NPPROC  SKIP_WHITE -- Skip over White Space
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing
COMMENT|

Skip over white space.

On entry:

DS:SI	 ==>	 next character

On exit:

AL	 =	 non-white character
DS:SI	 ==>	 next character

|

@@:
	 lodsb			; Get the next byte

	 cmp	 al,' '         ; Check for blank
	 je	 short @B	; Go around again

	 cmp	 al,TAB 	; Check for TAB
	 je	 short @B	; Go around again

	 cmp	 al,40h 	; Test for conversion of alpha to lower case
	 jb	 short @F	; Not this time

	 or	 al,20h 	; Convert alpha to lower case
@@:
	 ret			; Return to caller with next byte in AL

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

SKIP_WHITE endp 			; End SKIP_WHITE procedure
	 NPPROC  BASE2BIND -- Convert From Specified Base to Binary
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing
COMMENT|

Convert the number at DS:SI in base CX to binary.
The converted # is returned in EAX.

On entry:

CX	 =	 number base
DS:SI	 ==>	 string to convert

On exit:

CF	 =	 1 if overflow
	 =	 0 if OK
EAX	 =	 binary value
DS:SI	 ==>	 updated

|

	 REGSAVE <ebx,ecx,dx,edi,es> ; Save registers

	 movzx	 ecx,cx 	; Zero to use as dword
	 xor	 ebx,ebx	; Zero accumulator
	 call	 SKIP_WHITE	; Skip over more white space

	 push	 cs		; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it
BASE2BIND_LOOP:
	 lea	 edi,NUMBERS_LO ; Get address of number conversion table
	 push	 cx		; Save number base (and table length)
   repne scasb			; Look for the character
	 pop	 cx		; Restore number base
	 jne	 short BASE2BIND_DONE ; Not one of ours

	 sub	 di,1+offset es:NUMBERS_LO ; Convert to origin 0
	 mov	 eax,ebx	; Copy old to multiply by base

	 mul	 ecx		; Shift over accumulated #
	 jc	 short BASE2BIND_OVF ; Jump if out of range

	 mov	 ebx,eax	; Copy back
	 add	 ebx,edi	; Add in new #
	 jc	 short BASE2BIND_OVF ; Jump if out of range

	 lodsb			; Get next digit

	 cmp	 al,40h 	; Test for conversion of alpha to lower case
	 jb	 short BASE2BIND_LOOP ; Not this time

	 or	 al,20h 	; Convert alpha to lower case

	 jmp	 BASE2BIND_LOOP ; Go around again

BASE2BIND_OVF:
	 stc			; Indicate something went wrong

	 jmp	 short BASE2BIND_EXIT ; Join common exit code

BASE2BIND_DONE:
	 dec	 si		; Back off to previous character
	 mov	 eax,ebx	; Place result in accumulator

	 clc			; Indicate all went well
BASE2BIND_EXIT:
	 REGREST <es,edi,dx,ecx,ebx> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller with number in AX

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

BASE2BIND endp			; End BASE2BIND procedure
	 NPPROC  BIND2BASE -- Convert From Binary to Specified Base
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing
COMMENT|

Convert the number in EAX to ASCII in base CX storing the
low-order digit of the # at ES:DI.

|

	 REGSAVE <eax,ebx,edx,si,di> ; Save registers

	 pushf			; Save all flags
	 std			; Direction backwards for MOVSB

	 mov	 ebx,8		; Go through this many times (up to 9,999,999K)
	 xchg	 bx,cx		; Swap to put loop counter into CX
				; divisor into EBX
BIND2BASE_LOOP:
	 xor	 edx,edx	; Zero high-order word for division
	 div	 ebx		; Divide by number base
				; EDX has remainder, EAX has quotient
	 lea	 si,NUMBERS_HI	; DS:SI ==> translate table
	 add	 si,dx		; Offset into table

S16	 movsb			; Store in result

	 and	 eax,eax	; Check for zero quotient
	 jz	 short BIND2BASE_EXIT ; That's all folks

	 loop	 BIND2BASE_LOOP ; Jump if more digits to convert
BIND2BASE_EXIT:
	 popf			; Restore flags

	 REGREST <di,si,edx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

BIND2BASE endp			; End BIND2BASE procedure
	 NPPROC  BIN2BASE -- Convert From Binary to Specified Base
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing
COMMENT|

Convert the number in AX to ASCII in base CX storing the
low-order digit of the # at ES:DI.

|

	 REGSAVE <ax,bx,dx,si,di> ; Save registers

	 pushf			; Save all flags
	 std			; Direction backwards for MOVSB

	 mov	 bx,6		; Go through this many times (up to 999,999K)
	 xchg	 bx,cx		; Swap to put loop counter into CX
BIN2BASE_LOOP:
	 xor	 dx,dx		; Zero high-order word for division
	 div	 bx		; Divide by number base
				; DX has remainder, AX has quotient
	 lea	 si,NUMBERS_HI	; DS:SI ==> translate table
	 add	 si,dx		; Offset into table

S16	 movsb			; Store in result

	 and	 ax,ax		; Check for zero quotient
	 jz	 short BIN2BASE_EXIT ; That's all folks

	 loop	 BIN2BASE_LOOP	; Jump if more digits to convert
BIN2BASE_EXIT:
	 popf			; Restore flags

	 REGREST <di,si,dx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

BIN2BASE endp				; End BIN2BASE procedure
	 NPPROC  SEND_MSGS -- Display Messages
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Display messages about what we've setup --
disk size, byte per sector, and # directory entries.

|

	 REGSAVE <eax,bx,cx,dx,di,es> ; Save registers

	 les	 bx,RH_VEC	; Restore ES:BX to request header
	 assume  es:nothing	; Tell the assembler about it

	 mov	 al,es:[bx].INIT_DRIV ; AL=drive # (origin-0)

	 push	 cs		; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 add	 al,'A'         ; Convert to drive letter
	 mov	 DRIV_MSG,al	; Save in message

	 lea	 di,SIZE_NUM	; ES:DI ==> units digit
	 mov	 eax,DISKKILO	; Get # kilobytes in disk
	 mov	 cx,10		; Use this number base
	 call	 BIND2BASE	; Convert EAX to binary base CX ending ES:DI

	 lea	 di,BPS_NUM	; ES:DI ==> units digit
	 mov	 ax,BPB_BPS	; Get # bytes per sector
	 mov	 cx,10		; Use this number base
	 call	 BIN2BASE	; Convert AX to binary base CX ending ES:DI

	 lea	 di,DIR_NUM	; ES:DI ==> units digit
	 mov	 ax,BPB_NDIR	; Get # directory entries
	 mov	 cx,10		; Use this number base
	 call	 BIN2BASE	; Convert AX to binary base CX ending ES:DI

	 DOSCALL @STROUT,INIT_MSG ; Display initial message

	 REGREST <es,di,dx,cx,bx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

SEND_MSGS endp			; End SEND_MSGS procedure
	 NPPROC  CHECK_CPUID -- Check On CPU Identifier
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Ensure we're running on an 80386 processor.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

N.B.:  Use only 8088 instructions!!!!

|
.8086
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
	 clc			; Assume OK
	 jnz	 short CHECK_CPUID_EXIT ; Yes, so continue on
CHECK_CPUID_ERR:
	 ARGERR  MSG_NOT386	; Tell 'em the bad news

	 stc			; Indicate we have a problem
CHECK_CPUID_EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller
.386
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

CHECK_CPUID endp		; End CHECK_CPUID procedure
	 NPPROC  KEYWAIT -- Wait For Keyboard Acknowledgement
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing
COMMENT|

Purge the keyboard buffer and wait for a key press -- discard the key

On exit:

AX	 =	 last key pressed

|

KEYWAIT_NEXT:
	 KEYCALL @GETKST	; Get buffer state
	 jz	 short KEYWAIT_PAUSE ; Nothing available

	 KEYCALL @GETKEY	; Get the key

	 jmp	 KEYWAIT_NEXT	; Go around again

KEYWAIT_PAUSE:
	 KEYCALL @GETKEY	; Get the key

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

KEYWAIT  endp			; End KEYWAIT procedure

CODE	 ends			; End CODE segment

	 MEND			; End QDISK_IN module
