;' $Header:   P:/PVCS/MAX/386DISK/QDISK.ASV   1.2   30 May 1997 10:34:14   BOB  $
	 title	 QDISK -- Qualitas RAM Disk For DOS 3.00 and Later
	 page	 59,122
	 name	 QDISK

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1984, 1988, 1992-7 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  word-aligned, public, class 'prog'
	       Program segment STACK, byte-aligned, stack,  class 'prog'

Program derived from:  None.

Original code by:  Bob Smith, May 1984.

Modifications by:  Bob Smith, October 1988
		   to use EMS or XMS calls
		   Bob Smith, April 1992
		   to implement XMSHI, 16-bit FATs,
		   and 32-bit sector numbers
		   Bob Smith, September 1993
		   to implement Removable Media function

|

.386
.xlist
	 include DOSCALL.INC
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include XMS.INC
	 include EMMCALL.INC
	 include DEVDRV.INC
	 include DEVDRVBL.INC
.list

; Common structures

XMSMOVE_STR struc

XMSMOVE_LEN dd	 ?		; Length of move
XMSMOVE_SHNDL dw ?		; Source handle
XMSMOVE_SOFF  dd ?		; Source offset
XMSMOVE_DHNDL dw ?		; Destin handle
XMSMOVE_DOFF  dd ?		; Destin offset

XMSMOVE_STR ends


EMSMOVE_STR struc

EMSMOVE_LEN   dd ?		; Region length in bytes
EMSMOVE_STYP  db ?		; Source memory type
EMSMOVE_SHNDL dw ?		; Source handle (if STYP = 1)
EMSMOVE_SOFF  dw ?		; Source initial offset
EMSMOVE_SLPSG dw ?		; Source initial segment or logical page
EMSMOVE_DTYP  db ?		; Destin memory type
EMSMOVE_DHNDL dw ?		; Destin handle (if DTYP = 1)
EMSMOVE_DOFF  dw ?		; Destin initial offset
EMSMOVE_DLPSG dw ?		; Destin initial segment or logical page

EMSMOVE_STR ends


PGROUP	 group	 STACK,CODE


STACK	 segment use16 byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


CODE	 segment use16 word public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 INIT:near

	 public  DEVDRV_LBL
DEVDRV_LBL label near		; Label for END statement

	 public  DEVDRV
DEVDRV	 DD_STR  <-1,DRV_ATTR_NON_IBM or DRV_ATTR_OCREM or DRV_ATTR_HUGE,PGROUP:DEV_STRA,PGROUP:DEV_INTR,1>

;  B O O T   R E C O R D   &   B I O S	 P A R A M E T E R   B L O C K

	 public  @BPS,@NDIR,@NFATS,@NRSV
@BPS	 equ	 128		; Default sector size (bytes-per-sector)
@SPC	 equ	 1		; Default # sectors per cluster
@SPD	 equ	 64*1024/@BPS	; Default # sectors per disk
@NDIR	 equ	 64		; Default # directory entries
@SPF	 equ	 6		; Default # sectors per FAT
@NFATS	 equ	 1		; # FATs
@NRSV	 equ	 1		; # reserved sectors (boot sector)

	 public  BOOT_REC,BPB,BPB_BPS,BPB_SPC,BPB_NDIR,BPB_SPD
	 public  BPB_MED,BPB_SPF,BPB_HUGE,BOOT_TYP1,BOOT_LEN
BOOT_REC label	 byte		; Dummy DOS boot record
	 db	 0EBh,00h,90h	; 00: 3-byte jump to boot code -- DR DOS requires
				;      that either EB or E9 appears here
				;      and SMARTDRV requires that if it's an EB,
				;      that the third byte is a 90.
	 db	 'RDV 1.20'     ; 03: Vendor ident (must be 8 bytes)
BPB	 label	 byte		;     Begin BPB block
BPB_BPS  dw	 @BPS		; 0B: # bytes per sector
BPB_SPC  db	 @SPC		; 0D: # sectors per cluster
	 dw	 @NRSV		; 0E: # reserved sectors (boot sector)
	 db	 @NFATS 	; 10: # FATs
BPB_NDIR dw	 @NDIR		; 11: # directory entries
BPB_SPD  dw	 @SPD		; 13: # sectors per disk
BPB_MED  db	 0F8h		; 15: Media descriptor byte (any hard disk)
BPB_SPF  dw	 @SPF		; 16: # sectors per FAT
	 dw	 8		; 18: # sectors per track
	 dw	 1		; 1A: # heads
	 dd	 0		; 1C: # hidden sectors
BPB_HUGE dd	 0		; 20: # sectors per disk if BPB_SPD is zero
				;     and DOS 4.x or later
	 db	 ?		; 24: Drive number
	 db	 ?		; 25: Reserved
	 db	 29h		; 26: Extended boot signature
	 dd	 0		; 27: Volume serial number
	 db	 'NO NAME    '  ; 2B: Volume label
	 db	 'FAT1'         ; 36:
BOOT_TYP1 db	 '2   '         ; 3A: File system type (FAT12 or FAT16)
BOOT_LEN equ	 $-BOOT_REC	; Length of boot record

	 public  MOVETYPE,BPSLG2,BPB_PTR
	 include QDSK_COM.INC
MOVETYPE db	 @MOVE_XMS	; Move type:  0 = XMS, 1 = EXT, 2 = EMS
BPSLG2	 db	 ?		; Log base 2 of BPB_BPS
BPB_PTR  dw	 PGROUP:BPB	; Pointer to BPB

	 public  RH_VEC
RH_VEC	 dd	 ?			; Request header vector

	 public  OLDSTK_VEC
OLDSTK_VEC dd	 ?		; Save area for old stack pointer

	 public  USER_DTA_VEC
USER_DTA_VEC dd  ?		; Seg:Off of caller's buffer

	 public  XMSDRV_VEC
XMSDRV_VEC dd	 ?		; Seg:Off of XMS driver

	 public  EXTBASE
EXTBASE  dd	 ?		; Base of EXT disk

	 public  HNDL
HNDL	 dw	 -1		; EMS/XMS handle (initially invalid)

	 public  DISK2MEM,MEM2DISK
DISK2MEM dw	 ?		; Address of disk to memory move routine
MEM2DISK dw	 ?		; ...	     memory to disk

	 public  START_OFF
START_OFF dd	 ?		; Starting byte offset

	 public  MOVE_LEN,XMS,EMS,EXT
MOVE_LEN dd	 ?		; Move length in bytes

	 org	 MOVE_LEN
XMS	 XMSMOVE_STR <> 	; XMS move structure
XMSEND	 label	 byte

	 org	 MOVE_LEN
EMS	 EMSMOVE_STR <> 	; EMS move structure
EMSEND	 label	 byte

	 org	 MOVE_LEN
EXT	 MDTE_STR <>		; EXT move structure
EXTEND	 label	 byte

if (type EMSMOVE_STR) gt (type XMSMOVE_STR)
if (type MDTE_STR) gt (type EMSMOVE_STR)
	 org	 EXTEND
else
	 org	 EMSEND
endif				; IF (TYPE MDTE_STR) GT (TYPE EMSMOVE_STR)
else
	 org	 XMSEND
endif				; IF (TYPE EMSMOVE_STR) GT (TYPE XMSMOVE_STR)

	 public  ARG_ERRNUM
ARG_ERRNUM db	 ?		; Error number (if applicable)

; F U N C T I O N   T A B L E

	 public  FNTAB
	 even
FNTAB	 dw	 PGROUP:INIT		; Initialization
	 dw	 PGROUP:MEDIA_CHECK	; Media check (block)
	 dw	 PGROUP:BUILD_BPB	; Build BPB   (block)
	 dw	 PGROUP:IOCTL_IN	; IOCTL input
	 dw	 PGROUP:INPUT		; Input (device to memory)
	 dw	 PGROUP:ND_INPUT	; Non-destructive input no wait (char)
	 dw	 PGROUP:IN_STAT 	; Input status	(char)
	 dw	 PGROUP:IN_FLUSH	; Input flush	(char)
	 dw	 PGROUP:OUTPUT		; Output (memory to device)
	 dw	 PGROUP:OUTPUT		; Output (write) (ignore verify)
	 dw	 PGROUP:OUT_STAT	; Output status (char)
	 dw	 PGROUP:OUT_FLUSH	; Output flush	(char)
	 dw	 PGROUP:IOCTL_OUT	; IOCTL output
	 dw	 PGROUP:OPEN_DEV	; Open device
	 dw	 PGROUP:CLOSE_DEV	; Close device
	 dw	 PGROUP:REM_MEDIA	; Removable Media
FNTAB_LEN equ	 ($-FNTAB)/(type FNTAB) ; # entries in table

	 public  LCLSTK
LCLSTK	 dw	 128 dup (?)	; Local stack
LCLSTKZ  label	 word		; End of local stack

	 FPPROC  DEV_STRA -- Device Strategy Routine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing
COMMENT|

Device strategy routine

|

	 assume  ds:PGROUP	; Tell a little white lie
CSOVR	 mov	 <RH_VEC.VSEG,es> ; Save segment of request header pointer
CSOVR	 mov	 <RH_VEC.VOFF,bx> ;   "  offset   "    "       "      "
	 assume  ds:nothing	; Retract nose

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

DEV_STRA endp			; End DEV_STRA procedure
	 FPPROC  DEV_INTR -- Device Interrupt Commands
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing
COMMENT|

Device interrupt commands

|
.8086
	 cld			; String ops forwardly

	 REGSAVE <bx,di,ds,es>	; Save segment registers

	 push	 cs		; Setup DS for data references
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

; Switch to local stack

	 mov	 OLDSTK_VEC.VSEG,ss ; Save current stack segment
	 mov	 OLDSTK_VEC.VOFF,sp ; Save current stack pointer

	 cli			; In case we're on an old 8088
	 push	 cs		; Move CS
	 pop	 ss		; ... to SS
	 assume  ss:nothing	; Tell the assembler about it
	 lea	 sp,LCLSTKZ	; Address new stack
	 sti

; Do the branch according to the function passed

	 les	 di,RH_VEC	; ES:DI ==> request header
	 assume  es:nothing	; Tell the assembler about it

	 mov	 bl,es:[di].SRH_CCD ; Get the function byte

	 cmp	 bl,FNTAB_LEN	; Check against # entries in table
	 jae	 short EXIT_ERR ; Call it an error

	 xor	 bh,bh		; Zero to use as word
	 shl	 bx,1		; Times tow to index table of words

	 jmp	 FNTAB[bx]	; Take appropriate action

COMMENT|

The following entries are not supported by this device

|

IOCTL_IN:
IOCTL_OUT:
				; C H A R   O N L Y
ND_INPUT:			;     Non-destructive input no wait
IN_STAT:			;     Input status
IN_FLUSH:			;     Input flush
OUT_STAT:			;     Output status
OUT_FLUSH:			;     Output flush
EXIT_ERR:
	 les	 bx,RH_VEC	; ES:BX ==> request header
	 assume  es:nothing	; Tell the assembler about it

	 STATUS  DONE,ERROR,ERR_UNK_CMD ; Mark as unknown command

	 jmp	 short EXIT	; Join common exit code


REM_MEDIA:
	 les	 bx,RH_VEC	; ES:BX ==> request header
	 assume  es:nothing	; Tell the assembler about it

	 STATUS  DONEBUSY,NOERROR ; Set status word (done, no error, busy)
				; to indicate that we're not removable
	 jmp	 short EXIT	; Join common exit code


	 public  EXIT_DONE
EXIT_DONE:
OPEN_DEV:			;     Open device
CLOSE_DEV:			;     Close device
	 les	 bx,RH_VEC	; ES:BX ==> request header
	 assume  es:nothing	; Tell the assembler about it

	 STATUS  DONE,NOERROR	; Set status word (done, no error)

	 public  EXIT
EXIT:

; Switch back to caller's stack

	 mov	 ss,OLDSTK_VEC.VSEG ; Restore the segment
	 assume  ss:nothing	; Tell the assembler about it
	 mov	 sp,OLDSTK_VEC.VOFF ;		  offsett

	 REGREST <es,ds,di,bx>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller
.386
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

DEV_INTR endp			; End DEV_INTR procedure
	 NPPROC  OUTPUT -- Memory to Disk
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Transfer from memory to disk

On entry:

ES:DI	 ==>	 SRH_STR

|

	 call	 RW_SAVE	; Save the RW parms

	 call	 SECTOR_WRITE	; Write out those sectors
	 jc	 short EXIT_ERR ; Jump if something went wrong

	 jmp	 EXIT_DONE	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

OUTPUT	 endp			; End OUTPUT procedure
	 NPPROC  INPUT -- Disk to Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Transfer from disk to memory

On entry:

ES:DI	 ==>	 SRH_STR

|

	 call	 RW_SAVE	; Save the RW parms

	 call	 SECTOR_READ	; Read in those sectors
	 jc	 short EXIT_ERR ; Jump if something went wrong

	 jmp	 EXIT_DONE	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

INPUT	 endp			; End INPUT procedure
	 NPPROC  BUILD_BPB -- Build BIOS Parameter Block
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Build BIOS parameter block

On entry:

ES:DI	 ==>	 SRH_STR

|

	 mov	 es:[di].BUILD_BPB_VEC.VOFF,offset cs:BPB ; Pointer to BPB table
	 mov	 es:[di].BUILD_BPB_VEC.VSEG,cs

	 jmp	 EXIT_DONE	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

BUILD_BPB endp			; End BUILD_BPB procedure
	 NPPROC  MEDIA_CHECK -- Media Check
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Media check

Set media not changed

On entry:

ES:DI	 ==>	 SRH_STR

|

	 mov	 es:[di].MC_RET,1 ; Store in return byte

	 jmp	 EXIT_DONE	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

MEDIA_CHECK endp		; End MEDIA_CHECK procedure
	 NPPROC  RW_SAVE -- Save Read/Write Parameters
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Save caller's DTA, starting sector #, and # sectors to transfer

On entry:

ES:DI	 ==>	 SRH_STR

|

	 REGSAVE <eax,cx>	; Save registers

	 mov	 eax,es:[di].RW_DTA_VEC  ; Save caller's DTA
	 mov	 USER_DTA_VEC,eax

	 mov	 cl,BPSLG2	; Get log base 2 of BPB_BPS

	 movzx	 eax,es:[di].RW_SSN ; Get starting sector #

	 cmp	 ax,-1		; Izit signal to use RW_HUGE_SSN?
	 jne	 short @F	; Jump if not

	 mov	 eax,es:[di].RW_HUGE_SSN ; Get starting sector #
@@:
	 shl	 eax,cl 	; Times BPB_BPS
	 mov	 START_OFF,eax	; ...to get starting byte offset

	 movzx	 eax,es:[di].RW_COUNT ; Get sector count
	 shl	 eax,cl 	; Times BPB_BPS
	 mov	 MOVE_LEN,eax	; ... to get total # bytes to transfer

	 REGREST <cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

RW_SAVE  endp			; End RW_SAVE procedure
	 NPPROC  SECTOR_READ -- Read Sectors
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Transfer from disk to memory.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <esi,edi>	; Save registers

	 mov	 esi,START_OFF	; ESI ==> starting byte offset
	 mov	 edi,USER_DTA_VEC ; EDI ==> caller's DTA

	 call	 DISK2MEM	; Transfer from disk ESI to memory EDI
				; Return with CF significant

	 REGREST <edi,esi>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

SECTOR_READ endp		; End SECTOR_READ procedure
	 NPPROC  SECTOR_WRITE -- Write Sectors
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Transfer from memory to disk.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <esi,edi>	; Save registers

	 mov	 esi,USER_DTA_VEC ; ESI ==> caller's DTA
	 mov	 edi,START_OFF	; EDI ==> starting byte offset in disk

	 call	 MEM2DISK	; Transfer from memory ESI to disk EDI
				; Return with CF significant

	 REGREST <edi,esi>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

SECTOR_WRITE endp		; End SECTOR_WRITE procedure

; This address is used as the break address for the device driver
; plus the size of the specific read and write routines

	 public  QCODE_END
QCODE_END label  byte

	 NPPROC  EXT_MEM2DISK -- Transfer from Memory to EXT Disk
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Transfer from memory EXT disk.

On entry:

ESI	 ==>	 Seg:Off of memory source
EDI	 ==>	 Linear offset in disk of destin

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <eax,ecx,si,es> ; Save registers

; Source = CNV
; Destin = EXT
; ESI = segment:offset of caller's buffer
; EDI = 32-bit offset of disk data

; Set destin address

	 mov	 eax,EXTBASE	; Get linear base address of the disk
	 add	 eax,edi	; Add it in to get linear offset
	 mov	 EXT.MDTE_ES.DESC_BASE01,ax ; Set bytes 0-1
	 ror	 eax,16  ; Shift down high-order word
	 mov	 EXT.MDTE_ES.DESC_BASE2,al ; Set byte 2
	 mov	 EXT.MDTE_ES.DESC_BASE3,ah ; Set byte 3

; Set source address

	 mov	 eax,esi	; Copy source Seg:Off
	 shr	 eax,(16-0)-(4-0) ; Convert from paras to bytes
	 and	 al,0F0h	; Isolate

	 movzx	 ecx,si 	; Isolate the offset
	 add	 eax,ecx	; Add to get 32-bit linear address of source

	 mov	 EXT.MDTE_DS.DESC_BASE01,ax ; Set bytes 0-1
	 ror	 eax,16  ; Shift down high-order word
	 mov	 EXT.MDTE_DS.DESC_BASE2,al ; Set byte 2
	 mov	 EXT.MDTE_DS.DESC_BASE3,ah ; Set byte 3

; Set source and destin AR bytes

	 mov	 EXT.MDTE_DS.DESC_ACCESS,CPL0_DATA ; Set access rights byte
	 mov	 EXT.MDTE_ES.DESC_ACCESS,CPL0_DATA ; Set access rights byte

; Set source and destin move lengths

	 mov	 ecx,MOVE_LEN	; Get the move length
	 mov	 EXT.MDTE_DS.DESC_SEGLM0,cx ; Save in DTE
	 mov	 EXT.MDTE_ES.DESC_SEGLM0,cx ; Save in DTE
	 ror	 ecx,16 	; Shift down high-order word
	 and	 cx,mask $SEGLM1 ; Isolate low-order nibble
	 mov	 EXT.MDTE_DS.DESC_SEGLM1,cl ; Save in DTE
	 mov	 EXT.MDTE_ES.DESC_SEGLM1,cl ; Save in DTE
	 rol	 ecx,16-1	; Shift back, convert from bytes to words

	 push	 cs		; Setup ES for block move
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 si,EXT 	; ES:SI ==> MOVE_STR
	 mov	 ah,87h 	; Function for block move
	 clc			; In case INT 15h handler exits with an IRET
	 int	 15h		; Request BIOS service
	 mov	 ARG_ERRNUM,ah	; Save error number (if any)
	 jc	 short @F	; Jump if error

	 cmp	 ah,1		; Check return code
	 cmc			; Complement to get CF=1 iff error
@@:
	 REGREST <es,si,ecx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

EXT_MEM2DISK endp		; End EXT_MEM2DISK procedure

	 public  OLDINT15_VEC,EXTSIZE
OLDINT15_VEC dd  ?		; Save area for old INT 15h handler
EXTSIZE  dw	 ?		; New amount of extended memory

	 FPPROC  INT15 -- BIOS Service Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

	 pushf			; Save flags

	 cmp	 ah,88h 	; Check for get extended memory size
	 jne	 short @F	; Not this time

	 mov	 ax,EXTSIZE	; Return new size

	 popf			; Restore flags

	 iret			; Return to caller

@@:
	 popf			; Restore flags

	 jmp	 OLDINT15_VEC	; Continue on

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

INT15	 endp			; End INT15 procedure
	 public  EXT_MEM2DISKZ
EXT_MEM2DISKZ label near
	 NPPROC  XMS_MEM2DISK -- Transfer from Memory to XMS Disk
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Transfer from memory to XMS disk.

On entry:

ESI	 ==>	 Seg:Off of memory source
EDI	 ==>	 Linear offset in disk of destin

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <eax,si>	; Save registers

; Source = CNV
; Destin = XMS
; ESI = segment:offset of caller's buffer
; EDI = 32-bit offset of disk data

	 mov	 ax,HNDL	; Get the handle
	 mov	 XMS.XMSMOVE_DHNDL,ax ; Save in structure
	 mov	 XMS.XMSMOVE_DOFF,edi ; Save as source offset

	 mov	 XMS.XMSMOVE_SHNDL,0 ; Mark as XMS destin
	 mov	 XMS.XMSMOVE_SOFF,esi ; Save as destin Seg:Off

	 mov	 ah,@XMS_MOVXMB ; Move the data
	 lea	 si,XMS 	; DS:SI ==> XMSMOVE_STR
	 call	 XMSDRV_VEC	; Request XMS service
				; Return with AX = 0 for error, AX = 1 for OK
	 mov	 ARG_ERRNUM,bl	; Save error number (if any)
	 sub	 ax,1		; Subtract to set CF if error

	 REGREST <si,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

XMS_MEM2DISK endp		; End XMS_MEM2DISK Procedure
	 public  XMS_MEM2DISKZ
XMS_MEM2DISKZ label near
	 NPPROC  EMS_MEM2DISK -- Transfer from Memory to EMS Disk
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Transfer from memory to EMS disk.

On entry:

ESI	 ==>	 Seg:Off of memory source
EDI	 ==>	 Linear offset in disk of destin

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <eax,si>	; Save registers

; Source = CNV
; Destin = EMS
; ESI = segment:offset of caller's buffer
; EDI = 32-bit offset of disk data

	 mov	 EMS.EMSMOVE_DTYP,1 ; Mark as EMS destin
	 mov	 eax,edi	; Copy to shift
	 shl	 eax,16-14	; Shift 16KB remainder into high-order word
	 shr	 ax,16-14	; Shift back to get offset in low-order word
	 mov	 EMS.EMSMOVE_DOFF.EDD,eax ; Save source LPN:Off
	 mov	 ax,HNDL	; Get the handle
	 mov	 EMS.EMSMOVE_DHNDL,ax ; Save in structure

	 mov	 EMS.EMSMOVE_STYP,0 ; Mark as CNV destin
	 mov	 EMS.EMSMOVE_SHNDL,0 ; Set to zero
	 mov	 EMS.EMSMOVE_SOFF.EDD,esi ; Save destin Seg:Off

	 mov	 al,0		; Subfunction for move
	 lea	 si,EMS 	; DS:SI ==> EMSMOVE_STR
	 EMMCALL @EMM_XMOVEMEM	; Move them bytes

	 mov	 ARG_ERRNUM,ah	; Save error number (if any)
	 cmp	 ah,1		; Check return code
	 cmc			; Complement to get CF=1 iff error

	 REGREST <si,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

EMS_MEM2DISK endp		; End EMS_MEM2DISK Procedure
	 public  EMS_MEM2DISKZ
EMS_MEM2DISKZ label near
	 NPPROC  EXT_DISK2MEM -- Transfer from EXT Disk to Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Transfer from EXT disk to memory.

On entry:

ESI	 ==>	 Linear offset in disk of source
EDI	 ==>	 Seg:Off of memory destin

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <eax,ecx,si,es> ; Save registers

; Source = EXT
; Destin = CNV
; ESI = 32-bit offset of disk data
; EDI = segment:offset of caller's buffer

; Set source address

	 mov	 eax,EXTBASE	; Get linear base address of the disk
	 add	 eax,esi	; Add it in to get linear offset
	 mov	 EXT.MDTE_DS.DESC_BASE01,ax ; Set bytes 0-1
	 ror	 eax,16  ; Shift down high-order word
	 mov	 EXT.MDTE_DS.DESC_BASE2,al ; Set byte 2
	 mov	 EXT.MDTE_DS.DESC_BASE3,ah ; Set byte 3

; Set destin address

	 mov	 eax,edi	; Copy destin Seg:Off
	 shr	 eax,(16-0)-(4-0) ; Convert from paras to bytes
	 and	 al,0F0h	; Isolate

	 movzx	 ecx,di 	; Isolate the offset
	 add	 eax,ecx	; Add to get 32-bit linear address of destin

	 mov	 EXT.MDTE_ES.DESC_BASE01,ax ; Set bytes 0-1
	 ror	 eax,16  ; Shift down high-order word
	 mov	 EXT.MDTE_ES.DESC_BASE2,al ; Set byte 2
	 mov	 EXT.MDTE_ES.DESC_BASE3,ah ; Set byte 3

; Set source and destin AR bytes

	 mov	 EXT.MDTE_DS.DESC_ACCESS,CPL0_DATA ; Set access rights byte
	 mov	 EXT.MDTE_ES.DESC_ACCESS,CPL0_DATA ; Set access rights byte

; Set source and destin move lengths

	 mov	 ecx,MOVE_LEN	; Get the move length
	 mov	 EXT.MDTE_DS.DESC_SEGLM0,cx ; Save in DTE
	 mov	 EXT.MDTE_ES.DESC_SEGLM0,cx ; Save in DTE
	 ror	 ecx,16 	; Shift down high-order word
	 and	 cx,mask $SEGLM1 ; Isolate low-order nibble
	 mov	 EXT.MDTE_DS.DESC_SEGLM1,cl ; Save in DTE
	 mov	 EXT.MDTE_ES.DESC_SEGLM1,cl ; Save in DTE
	 rol	 ecx,16-1	; Shift back, convert from bytes to words

	 push	 cs		; Setup ES for block move
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 si,EXT 	; ES:SI ==> MOVE_STR
	 mov	 ah,87h 	; Function for block move
	 clc			; In case INT 15h handler exits with an IRET
	 int	 15h		; Request BIOS service
	 mov	 ARG_ERRNUM,ah	; Save error number (if any)
	 jc	 short @F	; Jump if error

	 cmp	 ah,1		; Check return code
	 cmc			; Complement to get CF=1 iff error
@@:
	 REGREST <es,si,ecx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

EXT_DISK2MEM endp		; End EXT_DISK2MEM procedure
	 public  EXT_DISK2MEMZ
EXT_DISK2MEMZ label near
	 NPPROC  XMS_DISK2MEM -- Transfer from XMS Disk to Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Transfer from XMS disk to memory.

On entry:

ESI	 ==>	 Linear offset in disk of source
EDI	 ==>	 Seg:Off of memory destin

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <eax,si>	; Save registers

; Source = XMS
; Destin = CNV
; ESI = 32-bit offset of disk data
; EDI = segment:offset of caller's buffer

	 mov	 ax,HNDL	; Get the handle
	 mov	 XMS.XMSMOVE_SHNDL,ax ; Save in structure
	 mov	 XMS.XMSMOVE_SOFF,esi ; Save as source offset

	 mov	 XMS.XMSMOVE_DHNDL,0 ; Mark as CNV destin
	 mov	 XMS.XMSMOVE_DOFF,edi ; Save as destin Seg:Off

	 mov	 ah,@XMS_MOVXMB ; Move the data
	 lea	 si,XMS 	; DS:SI ==> XMSMOVE_STR
	 call	 XMSDRV_VEC	; Request XMS service
				; Return with AX = 0 for error, AX = 1 for OK
	 mov	 ARG_ERRNUM,bl	; Save error number (if any)
	 sub	 ax,1		; Subtract to set CF if error

	 REGREST <si,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

XMS_DISK2MEM endp		; End XMS_DISK2MEM procedure
	 public  XMS_DISK2MEMZ
XMS_DISK2MEMZ label near
	 NPPROC  EMS_DISK2MEM -- Transfer from EMS Disk to Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Transfer from EMS disk to memory.

On entry:

ESI	 ==>	 Linear offset in disk of source
EDI	 ==>	 Seg:Off of memory destin

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <eax,si>	; Save registers

; Source = EMS
; Destin = CNV
; ESI = 32-bit offset of disk data
; EDI = segment:offset of caller's buffer

	 mov	 EMS.EMSMOVE_STYP,1 ; Mark as EMS source
	 mov	 eax,esi	; Copy to shift
	 shl	 eax,16-14	; Shift 16KB remainder into high-order word
	 shr	 ax,16-14	; Shift back to get offset in low-order word
	 mov	 EMS.EMSMOVE_SOFF.EDD,eax ; Save as LPN:Off
	 mov	 ax,HNDL	; Get the handle
	 mov	 EMS.EMSMOVE_SHNDL,ax ; Save in structure

	 mov	 EMS.EMSMOVE_DTYP,0 ; Mark as CNV destin
	 mov	 EMS.EMSMOVE_DHNDL,0 ; Set to zero
	 mov	 EMS.EMSMOVE_DOFF.EDD,edi ; Save destin Seg:Off

	 mov	 al,0		; Subfunction for move
	 lea	 si,EMS 	; DS:SI ==> EMSMOVE_STR
	 EMMCALL @EMM_XMOVEMEM	; Move them bytes

	 mov	 ARG_ERRNUM,ah	; Save error number (if any)
	 cmp	 ah,1		; Check return code
	 cmc			; Complement to get CF=1 iff error

	 REGREST <si,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

EMS_DISK2MEM endp		; End EMS_DISK2MEM procedure
	 public  EMS_DISK2MEMZ
EMS_DISK2MEMZ label near

CODE	 ends			; End CODE segment

	 MEND	 DEVDRV_LBL	; End QDISK module
