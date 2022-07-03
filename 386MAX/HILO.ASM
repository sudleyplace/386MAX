;' $Header:   P:/PVCS/MAX/386MAX/HILO.ASV   1.2   07 Apr 1997 10:16:46   BOB  $
	 title	 HILO -- 386MAX LOADHIGH/LOADLOW Utility Program
	 page	 58,122
	 name	 HILO

COMMENT|		Module Specifications

*********************************** QUALITAS ***********************************
********************************* CONFIDENTIAL *********************************

Copyright:  (C) Copyright 1987-95 Qualitas, Inc.

Segmentation:  Group PGROUP:
	       Stack   segment STACK,	byte-aligned,  stack,  class 'prog'
	       Program segment CODE,	word-aligned,  public, class 'prog'
	       Data    segment DATA,	byte-aligned,  public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'prog'
	       Data    segment NDATA,	dword-aligned, public, class 'data'
	       Tail    segment ZZTAIL,	byte-aligned,  public, class 'zzdata'

Program derived from:  None.

Original code by:  Bob Smith, April, 1987.

Modifications by:  Herbert Reibe c/o Klaus Albrecht MÅnchen
		   on 1. Mar. 1992, messages transferred to German.
		   please check length of modified lines !!
		   especially lines which probably must EQU others

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include CPUFLAGS.INC
	 include ASCII.INC
	 include IOCTL.INC
	 include VERSION.INC
	 include MAC.INC
	 include PTR.INC

	 include QMAX_OEM.INC
	 include QMAX_CTL.INC
	 include VERSBETA.INC
.list

PGROUP	 group	 STACK,CODE,DATA,NCODE,NDATA,ZZTAIL

; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment use16 byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 public  UTL_FLAG
	 include QMAX_UTL.INC
UTL_FLAG dw	 0		; Local utility program flags

	 public  INFO_CTL,INFO,INFOSIZE
	 include QMAXINFO.INC
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
INFOSIZE equ	 size INFO_STR

	 public  QMAX_VER,DEVICE_CS,QMAX_HI,OWNER,GLB_FLAG
	 public  LOWSIZE,OVRSIZE
	 public  PORT67,CMDCOM_PAR,OLDDOS,P1ST_MAC,POVR_MAC
	 public  CMD_FLAG,CM2_FLAG
QMAX_VER equ	 INFO.INFO_VER	;      Version #
	 include QMAX_HDM.INC
	 public  HDM_FLAG
DEVICE_CS equ	 INFO.INFO_QMAX ;  1 = Segment of device driver (non-relocatable)
QMAX_HI  equ	 INFO.INFO_HIGH ;      Starting segment #
OWNER	 equ	 INFO.INFO_OWNR ;  3 = Owner of block
GLB_FLAG equ	 INFO.INFO_GLB	;  4 = Global flags (see QMAX_GLB.INC for equates)
LOWSIZE  equ	 INFO.INFO_LOW	;  5 = LOWSIZE in 1KB
OVRSIZE  equ	 INFO.INFO_OVR	;  7 = OVRSIZE
PORT67	 equ	 INFO.INFO_P67	; 14 = I/O port for INT 67h communications
CMDCOM_PAR equ	 INFO.INFO_COMR ; 15 = CMDCOM_PAR
OLDDOS	 equ	 INFO.INFO_OLD	; 16 = Size of original DOS memory in paras
P1ST_MAC equ	 INFO.INFO_PMAC ; 18 = Pointer to first entry in MAC chain
POVR_MAC equ	 INFO.INFO_POVR ; 23 = Segment of first MAC entry in high DOS memory
CMD_FLAG equ	 INFO.INFO_CMD	; 24 = Command flags (see QMAX_CMD.INC for equates)
CM2_FLAG equ	 INFO.INFO_CM2	; 25 = CM2_FLAG
	 include QMAX_CMD.INC

	 public  DEV_HNDL
DEV_HNDL dw	 ?		; Device handle

	 public  DOSVER
DOSVER	 dw	 ?		; DOS version # (in comparison format)

	 public  MSG_COPY
MSG_COPY db	 @OEM_TEXT
	 db	 (MSG_COPY+15-$) dup (' '),'-- Version '
	 db	 VERS_H,'.',VERS_T,VERS_U
if @OEM_BETA
	 db	 '.',BETA_H,BETA_T,BETA_U,'·'
endif				; IF @OEM_BETA
ifdef LANG_GR
	 db	 ' -- Ein Memory-Manager fÅr 386-Systeme',CR,LF
	 db	 '   (C) Copyright 1987-95 Qualitas, Inc.'
	 db	 '  Alle Rechte vorbehalten.',CR,LF
	 db	 EOS
else
	 db	 ' -- A Memory Manager for 386 Systems',CR,LF
	 db	 '   (C) Copyright 1987-95 Qualitas, Inc.'
	 db	 '  GNU General Public License version 3.',CR,LF
	 db	 EOS
endif				; IFDEF LANG_GR

	 public  MSG_NOT386
ifdef LANG_GR
MSG_NOT386 db	 BEL,'ÕÕ> falscher Maschinentyp',CR,LF
	 db	     '    erfordert einen 80386.',CR,LF
else
MSG_NOT386 db	 BEL,'ÕÕ> Wrong machine type',CR,LF
	 db	     '    Must run on an 80386.',CR,LF
endif				; IFDEF LANG_GR
MSG_NOT386_LEN equ $-MSG_NOT386

	 public  MSG_NOTPRES
if @OEM_SYS eq @OEMSYS_NEC
ifdef LANG_GR
MSG_NOTPRES db	 BEL,'ÕÕ> NEC-Version des ',@OEM_FILE,'.SYS-Einheiten-Treibers nicht geladen',CR,LF
	    db	     '    von CONFIG.SYS.',CR,LF
else
MSG_NOTPRES db	 BEL,'ÕÕ> NEC Version of ',@OEM_FILE,'.SYS device driver not loaded from CONFIG.SYS.',CR,LF
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
MSG_NOTPRES db	 BEL,'ÕÕ> ',@OEM_FILE,'.SYS-Einheiten-Treiber nicht geladen von CONFIG.SYS.',CR,LF
else
MSG_NOTPRES db	 BEL,'ÕÕ> ',@OEM_FILE,'.SYS device driver not loaded from CONFIG.SYS.',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_NEC
MSG_NOTPRES_LEN equ $-MSG_NOTPRES

	 public  MSG_NOTVER
ifdef LANG_GR
MSG_NOTVER db	 BEL,'ÕÕ> falsche ',@OEM_TEXT,' Versionsnummer.',CR,LF
else
MSG_NOTVER db	 BEL,'ÕÕ> Incorrect ',@OEM_TEXT,' version number.',CR,LF
endif				; IFDEF LANG_GR
MSG_NOTVER_LEN equ $-MSG_NOTVER

	 public  MSG_RUNHI,MSG_RUNLO
ifdef LANG_GR
MSG_RUNHI db	 'ÕÕ> Lade Programme in oberen Speicher (HiDOS) ...',CR,LF,EOS
MSG_RUNLO db	 'ÕÕ> Lade Programme in unteren Speicher (LoDOS) ...',CR,LF,EOS
else
MSG_RUNHI db	 'ÕÕ> Loading programs in HIGH memory...',CR,LF,EOS
MSG_RUNLO db	 'ÕÕ> Loading programs in LOW memory...',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_AVAIL,MSG_AVAIL1
ifdef LANG_GR
MSG_AVAIL db	 'ÕÕ>   _'
MSG_AVAIL1 db	 ' KB im HiDOS Speicher verfÅgbar',EOS
else
MSG_AVAIL db	 'ÕÕ>   _'
MSG_AVAIL1 db	 ' KB available in HIGH memory',EOS
endif				; IFDEF LANG_GR

	 public  MSG_BLK
ifdef LANG_GR
MSG_BLK  db	 ', grî·ter Block ist   _'
MSG_BLK1 db	 ' KB',EOS
else
MSG_BLK  db	 ', largest block is   _'
MSG_BLK1 db	 ' KB',EOS
endif				; IFDEF LANG_GR

	 public  MSG_DOT
MSG_DOT  db	 '.',CR,LF,EOS
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

	 public  DEVNAME
DEVNAME  db	 @DEVNAME,0	; Device driver name

	 public  MSG_CLOSMAC
ifdef LANG_GR
MSG_CLOSMAC db	  BEL,'ÕÕ> Fehler in Speicher-Zuordnungskette.',CR,LF
else
MSG_CLOSMAC db	  BEL,'ÕÕ> Memory allocation chain error.',CR,LF
endif				; IFDEF LANG_GR
MSG_CLOSMAC_LEN equ $-MSG_CLOSMAC

	 public  NUMBERS_HI
NUMBERS_HI db	 '0123456789ABCDEF' ; Conversion table for BIN2BASE

	 public  LCLSTK,LCLSTKZ
	 even			; Optimize stack accesses
LCLSTK	 dw	 80h dup (?)
LCLSTKZ  dw	 0		; Return offset

DATA	 ends			; End DATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 STROUT:near

NCODE	 ends			; End NCODE segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
NDATA	 ends			; End NDATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

ZZTAIL	 segment use16 dword public 'zdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 public  ZTAIL
ZTAIL	 label	 byte

ZZTAIL	 ends			; End ZZTAIL segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

if @OEM_HILOAD
ifdef LOADLO
	 extrn	 ACT_LOADLO:near
elseifdef LOADHI
	 extrn	 ACT_LOADHI:near
else
.err2 Neither LOADHI nor LOADLO specified.
endif				; IFDEF LOADLO
endif				; IF @OEM_HILOAD
if @OEM_WIN3
	 extrn	 WINOUT_INIT:near
endif				; IF @OEM_WIN3
.xlist
	 public  PSP_ENVIR_PTR
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list
	 NPPROC  HILO -- 386MAX LOADHIGH/LOADLOW Utility Program
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing

	 lea	 sp,LCLSTKZ	; Use our own stack

; Get and save DOS version #

	 DOSCALL @DOSVER	; AL = major
				; AH = minor
				; BX=CX=0
	 xchg	 al,ah		; Swap to comparison order
	 mov	 DOSVER,ax	; Save for later use

	 push	 sp		; First test for a 286/386
	 pop	 ax

	 cmp	 ax,sp		; Same?
	 jne	 short HILO_CPUID_ERR ; No, it's neither a 286 nor a 386

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
	 jnz	 short HILO_CPUID_OK ; Yes, so continue on
HILO_CPUID_ERR:
	 mov	 cx,MSG_NOT386_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOT386 ; Tell 'em it's the wrong CPU

	 jmp	 HILO_ERR_EXIT	; Join common error exit code

HILO_CPUID_OK:

; Wipe out our own environment to avoid confusion with TSRs
; which freed their environment but didn't zero the pointer

	 REGSAVE <eax,es>	; Save registers

	 mov	 ax,PSP_ENVIR_PTR ; Get our ENV pointer

	 and	 ax,ax		; Izit valid?
	 jz	 short ENVFREE_EXIT ; No, skip out

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 eax,eax	; Zero a register
	 mov	 es:[0].EDD,eax ; Zero the environment
ENVFREE_EXIT:
	 REGREST <es,eax>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it

; Display the flag

	 lea	 dx,MSG_COPY	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

; See if we're already installed

	 mov	 al,02h 	; Access code for read/write
	 DOSCALL @OPENF2,DEVNAME ; Attempt to open 386MAX device driver
	 jnc	 short HILO1	; That worked
HILO_ERR:
	 mov	 cx,MSG_NOTPRES_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOTPRES ; Tell 'em 386MAX.SYS is not present

	 jmp	 HILO_ERR_EXIT	; Join common error exit code

HILO_VER:
	 mov	 cx,MSG_NOTVER_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOTVER ; Tell 'em it's the wrong version #

	 jmp	 HILO_ERR_EXIT	; Join common error exit code

HILO1:
	 mov	 DEV_HNDL,ax	; Save for later use
	 mov	 bx,ax		; Copy to handle register

; Ensure it's a device

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 jc	 short HILO_ERR ; Something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 short HILO_ERR ; No???

	 call	 INFO_READ	; Read in INFO structure

	 cmp	 INFO.INFO_SIGN.ELO[0],'83' ; Our signature?
	 jne	 short HILO_ERR ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[2],'M6' ; Our signature?
	 jne	 short HILO_ERR ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[4],'XA' ; Our signature?
	 jne	 short HILO_ERR ; Not this time

	 cmp	 INFO.INFO_VER[0],VERS_H ; Same high version # ?
	 jne	 short HILO_VER ; Not this time

	 mov	 al,VERS_T	; Get mid-digit of version #
	 mov	 ah,VERS_U	; Get low-digit of version #

	 cmp	 ax,INFO.INFO_VER.ELO[2] ; Same low numbers?
	 jne	 short HILO_VER ; Not this time

if @OEM_WIN3
	 call	 WINOUT_INIT	; Set WINVXD_VEC and WINRUN
;;;;;;;  jc	 ???		; Ignore error

endif				; IF @OEM_WIN3

if @OEM_HILOAD
ifdef LOADLO
	 call	 ACT_LOADLO	; Load programs into low DOS memory
else
	 call	 ACT_LOADHI	; Load programs into high DOS memory
endif				; IFDEF LOADLO
endif				; IF @OEM_HILOAD
	 mov	 al,0		; Return code = 0 if no errors
	 jnc	 short HILO_EXIT ; Jump if no errors
HILO_ERR_EXIT:
	 mov	 al,-1		; Give 'em a big reason
HILO_EXIT:
	 DOSCALL @EXITRC	; Return to DOS with reason code in AL

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

HILO	 endp			; End HILO procedure
	 NPPROC  BIN2BASE -- Convert From Binary to Specified Base
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing
COMMENT|

BIN2BASE -- Convert the number in AX to ASCII in base CX storing the
low-order digit of the # at ES:DI.

On exit:

ES:DI	 ==>	 next byte to left of the number

|

	 REGSAVE <ax,bx,cx,dx,si,bp,ds,es> ; Save all registers

	 push	 cs		; Set for MOVSB below
	 pop	 ds		; Now DS addresses NUMBERS_HI
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 cs		; Set for DI
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 pushf			; Save all flags
	 std			; Direction backwards for MOVSB

	 mov	 bp,8		; Go through this many times
BIN2BASE_LOOP:
	 xor	 dx,dx		; Zero high-order word for division
	 div	 cx		; Divide by number base
				; DX has remainder, AX has quotient
	 lea	 si,NUMBERS_HI	; Get address of table
	 add	 si,dx		; Offset into table

	 movsb			; Store in result

	 and	 ax,ax		; Check for zero quotient
	 jz	 short BIN2BASE_EXIT ; That's all folks

	 dec	 bp		; Check for last digit
	 jnz	 short BIN2BASE_LOOP ; Not done yet
BIN2BASE_EXIT:
	 popf			; Restore flags

	 REGREST <es,ds,bp,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

BIN2BASE endp			; End BIN2BASE procedure
	 NPPROC  INFO_READ -- Read In INFO Structure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 al,02h 	; Read from device
	 mov	 bx,DEV_HNDL	; Get device handle
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

INFO_READ endp			; End INFO_READ procedure
	 NPPROC  INFO_WRITE -- Write Out INFO Structure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 al,03h 	; Write into device
	 mov	 bx,DEV_HNDL	; Get device handle
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Set IOCTL info from INFO

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

INFO_WRITE endp 		; End INFO_WRITE procedure
	 NPPROC  SEND_CMD -- Set The State
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

Set the state to INFO_CTL.

On exit:

INFO_CTL =	 0 if successful
	 >	 0 otherwise

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 al,03h 	; Write into device
	 mov	 bx,DEV_HNDL	; Get device handle
	 mov	 cx,1		; CX = # bytes in INFO_CTL
	 DOSCALL @IOCTL2,INFO_CTL ; Set IOCTL info from INFO

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

SEND_CMD endp			; End SEND_CMD procedure
	 NPPROC  DISP_ERRMAC -- Display MAC Error Message
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing
COMMENT|

Display memory allocation chain error message

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 cx,MSG_CLOSMAC_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_CLOSMAC ; Tell 'em the bad news

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

DISP_ERRMAC endp		; End DISP_ERRMAC procedure
	 NPPROC  DISPMEM -- Display Memory Allocation Status
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

Display memory allocation status.

|

	 REGSAVE <ax,bx,cx,dx,di,es> ; Save registers

	 test	 CMD_FLAG,@CMD_XHI ; NOHIGH specified?
	 jnz	 near ptr DISPMEM_EXIT ; Yes, avoid displaying any information

	 cmp	 OWNER,0	; Any previous owner?
	 je	 short DISPMEM_LOW ; No, so we're running in low memory

; We are running in high memory

	 lea	 dx,MSG_RUNHI	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 jmp	 short DISPMEM_COM ; Join common display code

DISPMEM_LOW:

; We are running in low memory

	 lea	 dx,MSG_RUNLO	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

; Calculate size of high DOS memory
; Search through high memory allocation chain entries for free ones

DISPMEM_COM:
	 mov	 es,POVR_MAC	; ES:0 ==> first MAC in high memory
	 assume  es:nothing	; Tell the assembler about it

	 xor	 dx,dx		; Zero accumulator
	 xor	 di,di		; Zero largest block size
	 mov	 bx,cs		; Get our own segment
DISPMEM_NEXT:
	 cmp	 bx,es:[0].MAC_OWNR ; Check for our own entries
	 je	 short DISPMEM_AVAIL ; Mark it as available

	 cmp	 es:[0].MAC_OWNR,0 ; Check for available
	 jne	 short DISPMEM_INUSE ; Not this one
DISPMEM_AVAIL:
	 mov	 ax,es:[0].MAC_NPAR ; Get its size in paras
	 add	 dx,ax		; Add it into total

	 cmp	 ax,di		; Check against largest block so far
	 jbe	 short DISPMEM_INUSE ; It's no larger

	 mov	 di,ax		; Copy as largest block so far
DISPMEM_INUSE:

; Ensure we are where we think we should be

	 cmp	 es:[0].MAC_TYPE,'Z' ; Maybe it's the last entry
	 je	 short DISPMEM_END ; It is, so that's the end of the chain

	 cmp	 es:[0].MAC_TYPE,'M' ; Maybe it's a middle entry
	 jne	 short DISPMEM_ERRMAC ; Not this time

	 mov	 ax,es		; Copy current segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Add in # paragraphs in this entry
	 mov	 es,ax		; Point to next entry
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 DISPMEM_NEXT ; Go around again

DISPMEM_END:
	 mov	 bx,di		; Copy to unused register

; DX = # paras in high memory segment
; BX = # paras in largest block

	 mov	 ax,dx		; Copy size of high memory block
	 add	 ax,1024/16-1	; Round up to 1KB boundary
	 shr	 ax,10-4	; Convert from paras to 1KB

	 lea	 di,MSG_AVAIL1-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 push	 dx		; Save for a moment
	 lea	 dx,MSG_AVAIL	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX
	 pop	 dx		; Restore

	 cmp	 bx,dx		; Check against largest block
	 je	 short DISPMEM_DOT ; Jump if no fragmentation

	 mov	 ax,bx		; Copy size of largest high memory block
	 shr	 ax,10-4	; Convert from paras to 1KB, rounding down

	 lea	 di,MSG_BLK1-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 lea	 dx,MSG_BLK	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX
DISPMEM_DOT:
	 lea	 dx,MSG_DOT	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX
DISPMEM_ERRMAC:
DISPMEM_EXIT:
	 REGREST <es,di,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

DISPMEM  endp			; End DISPMEM procedure

CODE	 ends			; End CODE segment

	 MEND	 HILO		; End HILO module
