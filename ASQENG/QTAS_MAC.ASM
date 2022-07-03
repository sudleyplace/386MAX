;' $Header:   P:/PVCS/MAX/ASQENG/QTAS_MAC.ASV   1.1   30 May 1997 14:58:42   BOB  $
	 title	 QTASMAC -- Qualitas Memory Allocation Chain Mapper
	 page	 58,122
	 name	 QTASMAC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Microsoft conventions using .MODEL, .DATA, and .CODE.

Link requirements:  Nothing special.

Program derived from:  UTIL_MAP.ASM, UTIL_MA2.ASM.

Original code by:  Bob Smith, April, 1987.

Modifications by:  Alan C. Lindsay, August 1990, April 1991.

|

.xlist
	 include MASM.INC
	 include PTR.INC
	 include MAC.INC	; Structure of MAC entry
	 include DEVDRV.INC
	 include INTVEC.INC
	 include PSPSTR.INC	; Structure for PSP area
	 include LOAD_SEG.INC
	 include EMM2CALL.INC
.list

;
;	Identification codes
;
MACTYPE_UNKNOWN equ '?'
MACTYPE_DOS	equ '@'
MACTYPE_DRVRS	equ '8'
MACTYPE_CMDCOM	equ 'C'
MACTYPE_PRGM	equ 'P'
MACTYPE_DD	equ 'D'
MACTYPE_AVAIL	equ 'A'
MACTYPE_RAMROM	equ 'R'
MACTYPE_CURRENT equ 'T'
MACTYPE_UMB	equ 'U'
MACTYPE_SUBSEG	equ 'S'
;

	 extrn	__psp:word	; C runtime variable for psp segment
	 extrn	__osmajor:byte	; C runtime variable for DOS major version

	 .MODEL LARGE,PASCAL

	 .DATA			; Our local static data

ENTNAMESIZE EQU 16
ENVTEXTSIZE EQU 40
MACINFO_STR	 STRUC			; Structure of MAC item being assembled
ID		 dw	 ?		; Id code of entry
START		 dw	 ?		; Segment of MAC entry
NPARA		 dw	 ?		; Size of entry in paragraphs
OWNER		 dw	 ?		; Owning segment
ENTNAME 	 db	ENTNAMESIZE dup (?) ; Name of entry if known
ENVTEXT 	 db	ENVTEXTSIZE dup (?) ; Environment text, if any
MACINFO_STR	 ENDS

	 public  LCLITEM
LCLITEM  MACINFO_STR <>

;
; Local variables for mapping routine
;
ITEMCOUNT	 dw	 ?		; Item counter
BUFPTR		 dd	 ?		; Pointer to caller's buffer

CURMAC		 dw	 ?		; Segment of current MAC entry
CUROWNR 	 dw	 ?		; MAC_OWNR of CURMAC
CURNPAR 	 dw	 ?		; MAC_NPAR of CURMAC
CURTYPE 	 db	 ?		; MAC_TYPE of CURMAC
CURMDRV 	 db	 ?		; MAC_DRV  of CURMAC
CURENV		 dw	 ?		; Segment of current environment
CURDEV_VEC	 dd	 -1		; Pointer to current device driver header
LSEGFLAG	 db	 ?		; 1 = MAC entry is an LSEG, 0 = not
TOKTYP		 db	 ?		; Token type (@SFO_xxx)
LOADSEG 	 dw	 ?		; Segment of first LSEG entry
;
; Local variables for mapping interrupts
;
MAC_LO		 dw	 ?		; MAC low paragraph
MAC_HI		 dw	 ?		; ... high ...

INT_OFF 	 dw	 ?		; Offset into interrupt vector table
INT_CNT 	 dw	 ?		; # remaining interrupt vectors to check

TOKEN_LIST	 dw	 @SFO_HARPO*256+@TOKEN_FILES   ; Subsegment tokens to scan for
		 dw	 @SFO_HARPO*256+@TOKEN_FCB
		 dw	 @SFO_HARPO*256+@TOKEN_BUFFERS
		 dw	 @SFO_HARPO*256+@TOKEN_LASTDRV
		 dw	 @SFO_HARPO*256+@TOKEN_STACKS
		 dw	 @SFO_HARPO*256+@TOKEN_DOS3
		 dw	 @SFO_HARPO*256+@TOKEN_BATCH
		 dw	 @SFO_HARPO*256+@TOKEN_IFS_G
		 dw	 @SFO_HARPO*256+@TOKEN_IFS_H
		 dw	 @SFO_HARPO*256+@TOKEN_IFS_R
		 dw	 @SFO_HARPO*256+@TOKEN_IFS_Y
		 dw	 @SFO_MAX*256+	@TOKEN_XBDAREG
		 dw	 @SFO_MAX*256+	@TOKEN_HPDAREG
		 dw	 @SFO_MAX*256+	@TOKEN_STACKREG
		 dw	 0
@TOKEN_LEN equ	 ($-TOKEN_LIST)/(type TOKEN_LIST) ; Number of tokens to scan

TOKEN_MSGS	 db	 'Files    '    ; Messages to tag subsegments with
@TOKEN_MSGLEN equ $-TOKEN_MSGS		; Length of each message
		 db	 'FCBs     '
		 db	 'Buffers  '
		 db	 'Lastdrv  '
		 db	 'Stacks   '
		 db	 'DOSdata  '
		 db	 'Tmpdata  '
		 db	 'IFS-G    '
		 db	 'IFS-H    '
		 db	 'IFS-R    '
		 db	 'IFS-Y    '
		 db	 'XBDA     '
		 db	 'HPDA     '
		 db	 'MAX Stack'
ifdef LANG_GR
		 db	 'Unbekannt'
else
		 db	 'Unknown  '
endif

	 .CODE

COMMENT|

	 QTAS_MAC - Process Qualitas Memory Allocation Chains

	 (Also works for Low DOS)

	 int pascal far qtas_mac(
		WORD first_mac, 	Segment of first MAC entry
		WORD first_lseg,	Segment of first LSEG if nonzero
		MACINFO far *buf,	Buffer to fill
		int nbuf);		Max space in buffer
	 Return:  number of entries found, or -1 if errors.

|

	 public  QTAS_MAC
QTAS_MAC proc	 macseg:word, lseg:word, macbuf:dword, nbuf:word

	 REGSAVE <si, di, ds, es>	; Save segment registers

	 mov	 ax,nbuf	; Get bytes available
	 or	 ax,ax		; Is there anything left?
	 jz	 QTAS_MAC_ERRMAC ; Bail out if bogus input

	 mov	 ITEMCOUNT,ax	; Set item counter to buffer size

	 mov	 ax,lseg	; Pick up first LSEG
	 mov	 LOADSEG,ax	; Save it

	 les	 bx,macbuf	; Get pointer to buffer
	 mov	 word ptr BUFPTR,bx ; Save in local variable
	 mov	 word ptr BUFPTR+2,es

	 mov	 es,macseg	; Pick up starting segment
	 assume  es:nothing	; Tell the assembler

QTAS_MAC_NEXT:

; Ensure we are where we think we should be

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Check for valid entry
	 je	 short @F	 ; It is

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Maybe it's a middle entry
	 jne	 short QTAS_MAC_ERRMAC ; Not this time
@@:
;
	 push	 es
	 push	 ds
	 pop	 es		; Make DS = ES temporarily
	 cld			; String forwards
	 mov	 di,offset LCLITEM	; Clear local item storage
	 mov	 cx,size LCLITEM
	 mov	 al,0
	 rep	 stosb		; Zap it
	 pop	 es
	 mov	 LCLITEM.ID,MACTYPE_UNKNOWN
;
	 call	 DO_MAC 	; Process the entry at ES:0
	 cmp	 ITEMCOUNT,0	; Check item count
	 jle	 QTAS_MAC_LAST	; Bail out if so

	 cmp	 CURTYPE,@MAC_END ; Wuzit the last entry?
	 je	 short QTAS_MAC_LAST ; Jump if so

	 mov	 ax,es		; Copy current segment
	 add	 ax,CURNPAR	; Plus # paras
	 inc	 ax		; Count in the MAC paragraph

	 mov	 es,ax		; Point to next entry
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 QTAS_MAC_NEXT ; Go around again

QTAS_MAC_LAST:
	 mov	 ax,nbuf	; Compute number of items found
	 sub	 ax,ITEMCOUNT

	 jmp	 short QTAS_MAC_EXIT ; Join common exit code

QTAS_MAC_ERRMAC:
	 mov	 ax,-1		; Indicate something went wrong
QTAS_MAC_EXIT:

	 REGREST <es, ds, di, si>	; Restore
	 assume  ds:nothing,es:nothing,ss:nothing
	 ret

QTAS_MAC endp			; End of procedure


	 NPPROC  IZITLSEG	; -- Is CURMAC An LSEG Entry?
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Is CURMAC an LSEG entry?

On entry:

CURMAC	 ==>	 current MAC entry

On exit:

CF	 =	 1 if so
	 =	 0 if not

|

	 REGSAVE <ax,bx,es>	; Save registers

; Search through the LSEG chain looking for a match with CURMAC

	 mov	 bx,CURMAC	; Get segment of current MAC entry
	 inc	 bx		; Count in the MAC paragraph
	 mov	 ax,LOADSEG	; Get start of LSEG chain
IZITLSEG_NEXT:
	 cmp	 ax,-1		; Izit the end?
	 je	 short IZITLSEG_EXIT ; Jump if so (note CF=0)

	 cmp	 ax,bx		; Same segment?
	 je	 short IZITLSEG_FOUND ; Jump if it's a match

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es:[0].LSEG_NEXT ; Get segment of next entry

	 jmp	 short IZITLSEG_NEXT ; Go around again

IZITLSEG_FOUND:
	 stc			; Mark as a match
IZITLSEG_EXIT:
	 REGREST <es,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

IZITLSEG endp			; End IZITLSEG procedure
	 NPPROC  DO_MAC 	; -- Process MAC Entry at ES:0
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

On entry:

ES:0	 ==>	 MAC entry

|

	 REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save registers

	 cld			; String ops forwardly

	 mov	 CURMAC,es	; Save for later use

	 mov	 al,es:[0].MAC_TYPE ; Get type of MAC entry
	 mov	 CURTYPE,al	; Save for later use

	 mov	 ax,es:[0].MAC_OWNR ; Get owner of MAC entry
	 mov	 CUROWNR,ax	; Save for later use

	 mov	 ax,es:[0].MAC_NPAR ; Get # paras in MAC entry
	 mov	 CURNPAR,ax	; Save for later use

	 mov	 al,es:[0].MAC_DRV ; Get drive # in MAC entry
	 mov	 CURMDRV,al	; Save for later use

	 mov	 LSEGFLAG,0	; Assume not an LSEG entry

	 call	 IZITLSEG	; Is CURMAC an LSEG entry?
	 jnc	 short DO_MAC_XLSEG ; Jump if not

	 mov	 LCLITEM.START,es ; Entry starts with LSEG

	 mov	 ax,es		; Copy current MAC segment
	 add	 ax,CURNPAR	; Plus the # paragraphs
	 inc	 ax		; Count in MAC paragraph

	 mov	 CURMAC,ax	; Make this the new current entry

	 mov	 es,ax		; Address next MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 mov	 al,es:[0].MAC_TYPE ; Get type of MAC entry
	 mov	 CURTYPE,al	; Save for later use

	 mov	 ax,es:[0].MAC_OWNR ; Get the owner
	 mov	 CUROWNR,ax	; Save for later use

	 mov	 ax,es:[0].MAC_NPAR ; Get the # paragraphs
	 inc	 ax		; Count in MAC paragraph of the LSEG entry
	 add	 CURNPAR,ax	; Add to total # paras

	 mov	 al,es:[0].MAC_DRV ; Get drive # in MAC entry
	 mov	 CURMDRV,al	; Save for later use

	 mov	 LSEGFLAG,1	; Mark as an LSEG entry

	 jmp	 short DO_MAC_XLSEG_COM ; Join common code

DO_MAC_XLSEG:
	 mov	 ax,CURMAC	; Get starting segment
	 mov	 LCLITEM.START,ax

DO_MAC_XLSEG_COM:
	 mov	 ax,CURNPAR	; Get the # paragraphs
	 mov	 LCLITEM.NPARA,ax ; Store it

	 mov	 ax,CUROWNR	; Get current owner

	 and	 ax,ax		; Available entry?
	 jz	 short @F	; Jump if so

	 cmp	 ax,@MAC_HOLE	; Izit a hole left by a shrunken UMB?
	 jne	 short DO_MAC_XAVAIL ; Jump if not
@@:
	 jmp	 DO_MAC_AVAIL	; Treat either case as an available entry

DO_MAC_XAVAIL:
	 mov	 cx,__psp	; Get our PSP segment

	 cmp	 ax,cx		; Same as current segment?
	MJ z,	 DO_MAC_CUR	; Yes, handle specially

	 cmp	 ax,@MAC_LINK	; Starting entry?
	 jne	 short @F	; Jump if not

	 cmp	 CURMAC,9000h	; Izit possibly a DOS-compatible spanning entry?
	MJ b	 DO_MAC_DRVRS	; No - it must be the start of DOS

	 jmp	 short DO_MAC_SPAN ; It's a DOS-compatible spanning entry

@@:
	 cmp	 ax,@MAC_SPAN	; Spanning entry?
	 jne	 short @F	; Jump if not

DO_MAC_SPAN:
	 jmp	 DO_MAC_RAMROM	; Mark as filler for RAM or ROM

@@:
	 cmp	 ax,@MAC_DRV	; Device driver entry?
	MJ e,	 DO_MAC_DD	; Yes, handle separately

	 cmp	 ax,@MAC_UMB	; UMB entry?
	MJ e,	 DO_MAC_UMB	; Yes, say so

	 cmp	 ax,@MAC_LSEG	; LSEG entry?
	MJ e,	 DO_MAC_UMB	; Yes, call it a UMB

	 cmp	 ax,@MAC_SUBSEG_DOS ; DOS Subsegment entry?
	MJ e	 DO_MAC_SUBSEG_DOS  ; Jump if so

	 cmp	 ax,@MAC_SUBSEG_MAX ; MAX Subsegment entry?
	MJ e	 DO_MAC_SUBSEG_MAX  ; Jump if so

; ES:0	 ==>	 current MAC entry
; AX	 =	 CUROWNR

	 mov	 LCLITEM.OWNER,ax ; Store owning segment

; Switch to segment of owner
	 mov	 es,ax		; Address via segment register
	 assume  es:nothing	; Tell the assembler about it

; We recognize COMMAND.COM as the first entry which owns itself

	 cmp	 ax,es:PSP.PSP_CTRL_PSP ; Izit its own control PSP?
	 je	 DO_MAC_CMD
	 mov	 LCLITEM.ID,MACTYPE_PRGM ; No, mark it as program
	 jmp	 @F
DO_MAC_CMD:
	 mov	 LCLITEM.ID,MACTYPE_CMDCOM ; Mark it as COMMAND.COM
@@:
	 assume  ds:nothing	; So we use ES for PSP_ENVIR_PTR
	 mov	 ax,es:PSP.PSP_ENVIR_PTR ; Get the owner's ENV pointer
	 assume  ds:DGROUP,es:nothing

	 mov	 CURENV,ax	; Save as current environment

	 and	 ax,ax		; Anybody home?
	MJ z,	 DO_MAC_DOS4	; No, maybe we can get the name from the MAC
;
; Attempt to catch environment tail-ending.
; This occurs when a TSR frees its environment, but doesn't
; zero out the environment pointer in its PSP.
; If the environment segment is preceded by what looks like a
; MAC entry (based on the .MAC_TYPE field), and that MAC entry owner
; is unequal to the current owner, then assume its spurious.
;
	 dec	 ax		; Back up to what we hope is a MAC entry
	 mov	 es,ax		; Address via segment register
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Check for valid MAC entry
	 je	 short DO_MAC1 ; Jump if it's a match

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Check for valid MAC entry
	 jne	 short DO_MAC_DOS4 ; No match, must not be a MAC entry

; Preceding para looks like a MAC entry -- ensure matching owners

DO_MAC1:
	 mov	 ax,es:[0].MAC_OWNR ; Get the environment's owner

	 cmp	 ax,CUROWNR	; Check for match with our owner
	 je	 short DO_MAC2 ; It's a match, display the program name

; If this is DOS 4.x or later, we can get the program name from
; the MAC entry

DO_MAC_DOS4:
	 cmp	 __osmajor,4	; Check DOS version #
	MJ b,	 DO_MAC_COMM	; Jump if too early
;
	 push	 es
	 mov	 es,CURMAC	; Get segment of current MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 lea	 si,es:[0].MAC_NAME ; DS:SI ==> source name
	 mov	 cx,8		; Length of name
	 call	 SAVE_NAME
	 pop	 es

	 jmp	 DO_MAC_COMM	; Join common code

	 assume  ds:DGROUP	; Tell the assembler about it

DO_MAC2:
	 mov	 ax,CURENV	; Segment of environment block
	 mov	 es,ax		; Address via segment register
	 assume  es:nothing	; Tell the assembler about it

	 dec	 ax		; Plus 1
	 cmp	 ax,CURMAC	; Izit the current MAC entry?
	 jnz	 @F		; Jump if not

DO_ENV_AGAIN:
	 call	 DISP_TEXT	; Save env text if so
@@:

; Search for program name in the environment

	 xor	 di,di		; ES:DI ==> start of environment
	 mov	 al,0		; Environment entry terminator
	 mov	 cx,-1		; We know it's there
DO_MAC_ENV:
   repne scasb			; Search for it

	 scasb			; Check next entry
	 jne	 short DO_MAC_ENV ; Not at end as yet

	 mov	 ax,1		; Test value

	 scasw			; Normal filler?
	 je	 short @F	; Jump if so

; I put this in, but don't see where it may be necessary. -HG
;;;;;;;; If the COMMAND.COM environment is low, we may have a CONFIG=
;;;;;;;; type environment (DOS 6 with MultiConfig or SET in CONFIG.SYS).
;;;;;;;; If that's the case, we need to get the strings section from CURMAC,
;;;;;;;; not from the owner's environment.
;;;;;;;  mov	 ax,es		; Get environment segment
;;;;;;;  dec	 ax		; Back off to MAC
;;;;;;;  cmp	 ax,CURMAC	; Izit the current MAC?
;;;;;;; MJ e	 DO_MAC_COMM	; Jump if so
;;;;;;;
;;;;;;;  mov	 ax,CURMAC	; Get current MAC
;;;;;;;  inc	 ax		; Skip to data
;;;;;;;  mov	 es,ax		; Address it
;;;;;;;  assume  es:nothing	; Tell the assembler
;;;;;;;
;;;;;;;  jmp	 short DO_ENV_AGAIN ; Try again
	 jmp	 DO_MAC_COMM	; Environment has no strings section

@@:
	 mov	 al,0		; Search for string terminator
	 push	 di		; Save
	 mov	 cx,-1		; We know it's there
   repne scasb			; Search for it
	 dec	 di		; Back off to terminating zero
	 mov	 cx,di		; Copy pointer

	 pop	 di		; Restore original offset

	 sub	 cx,di		; CX = length of name

	 mov	 al,'\'         ; Path separator

	 REGSAVE <cx,di>	; Save for a moment
@@:
	 mov	 si,di		; Save current offset
   repne scasb			; Search for it
	 je	 short @B	; Jump if found
	 REGREST <di,cx>	; Restore

	 mov	 al,'/'         ; Alternate path separator
@@:
	 mov	 dx,di		; Save current offset
   repne scasb			; Search for it
	 je	 short @B	; Jump if found

; Put the larger of the two offsets into SI

	 cmp	 dx,si		; Compare 'em
	 jbe	 short @F	; SI is larger
	 mov	 si,dx		; DX is larger
@@:
	 mov	 cx,0		; 0 means it's null terminated
	 call	 SAVE_NAME	; Store program name

	 jmp	 DO_MAC_COMM	; and display it


DO_MAC_DRVRS:
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 mov	 LCLITEM.ID,MACTYPE_DRVRS ; Store "Device Drvrs" id
	 jmp	 DO_MAC_COMM	; Join common code
;
;--------------------------------------------------------------------------
;
DO_MAC_DD:
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 mov	 ax,es		; Copy MAC segment
	 inc	 ax		; Skip over MAC entry to owner

	 mov	 CURDEV_VEC.VSEG,ax ; Save for later use
	 mov	 CURDEV_VEC.VOFF,0

	 mov	 LCLITEM.OWNER,ax ; Store owning segment

DO_MAC_DD1:
	 les	 di,CURDEV_VEC	; ES:DI ==> current driver header

	 mov	 ax,es:[di].DD_NEXT.VOFF ; Get offset of nested driver
	 mov	 CURDEV_VEC.VOFF,ax ; Save for later use

	 inc	 ax		; Izit -1 (end-of-the-line)?
	 jz	 short DO_MAC_DD2 ; Jump if so

	 mov	 ax,es:[di].DD_NEXT.VSEG ; Get segment of nested driver

	 cmp	 ax,CURDEV_VEC.VSEG ; Same as before?
	 je	 short @F	; Yes

	 and	 ax,ax		; Segment unset?
	 jz	 short @F	; Yes, assume same as before
DO_MAC_DD2:
	 mov	 CURDEV_VEC.VSEG,-1 ; Mark as no more
@@:
	 mov	 al,CURMDRV	; Get the drive # if a block device
	 mov	 ah,es:[di].DD_NAME[0] ; Get # units in this device

	 test	 es:[di].DD_ATTR,DRV_ATTR_CHAR ; Izit a character device driver?
	 jz	 short DO_MAC_DD_BLK ; No, hence there's no name field

	 lea	 si,es:[di].DD_NAME ; ES:SI ==> name field

	 call	 SAVE_CHARDEV

	 mov	 es,CURMAC	; Restore pointer to current MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 DO_MAC_COMM	; Join common code


DO_MAC_DD_BLK:
	 call	 SAVE_BLKDEV

	 mov	 es,CURMAC	; Restore pointer to current MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 DO_MAC_COMM	; Join common code

	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it
DO_MAC_SUBSEG_MAX:
	 mov	 TOKTYP,@SFO_MAX ; Mark as MAX token

	 jmp	 short @F	; Join common code

DO_MAC_SUBSEG_DOS:
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it
	 mov	 TOKTYP,@SFO_HARPO ; Mark as DOS token
@@:
	 mov	 ax,es		; Copy MAC segment
	 inc	 ax		; Skip over MAC entry to owner

	 mov	 LCLITEM.OWNER,ax ; Store owning segment

; ES:[0].MAC_DRV contains a token (listed in MAC.INC).	Find
; the corresponding description.
	 REGSAVE <ax,dx,si,di>	; Save

	 mov	 al,es:[0].MAC_DRV ; Get identifying token
	 mov	 ah,TOKTYP	; Get the token type
	 lea	 di,TOKEN_LIST	; List of valid tokens to scan
	 push	 ds		; Get DGROUP segment
	 pop	 es		; Address it for string ops
	 assume  es:DGROUP	; Tell the assembler

; The last token is the same as an invalid token.
	 cld			; Set forward direction
	 mov	 cx,@TOKEN_LEN	; Number of tokens to scan
  repne  scas	 TOKEN_LIST[di] ; Search for it
	 sub	 di,(offset DGROUP:TOKEN_LIST[(type TOKEN_LIST)]) ; DI = index of token (origin:0)
	 shr	 di,1		; Shift by log2(type TOKEN_LIST)
	 lea	 si,TOKEN_MSGS	; Address start of list
	 mov	 cx,@TOKEN_MSGLEN ; Number of bytes to move
	 mov	 ax,di		; Multiplier for TOKEN_MSGS
	 mul	 cx		; AX = offset from TOKEN_MSGS
	 add	 si,ax		; DGROUP:SI ==> message to copy
	 lea	 di,LCLITEM.ENTNAME ; Address name field
   rep	 movs	 TOKEN_MSGS[si],LCLITEM.ENTNAME[di] ; Copy it
	 sub	 al,al		; Create a trailing null
	 stos	 LCLITEM.ENTNAME[di] ; Zap it

	 REGREST <di,si,dx,ax>	; Restore

	 mov	 es,CURMAC	; Restore pointer to current MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 mov	 LCLITEM.ID,MACTYPE_SUBSEG
	 jmp	 DO_MAC_COMM	; Join common code


DO_MAC_RAMROM:
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 mov	 LCLITEM.ID,MACTYPE_RAMROM
	 jmp	 short DO_MAC_COMM ; Join common code


DO_MAC_CUR:
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 mov	 LCLITEM.ID,MACTYPE_CURRENT

	 mov	 es,ax		; Address via segment register
	 assume  es:nothing	; Tell the assembler about it
	 assume  ds:nothing

	 jmp	 short DO_MAC_COMM ; Join common code


DO_MAC_UMB:
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 mov	 LCLITEM.ID,MACTYPE_UMB
	 jmp	 short DO_MAC_COMM ; Join common code

DO_MAC_AVAIL:
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 mov	 LCLITEM.ID,MACTYPE_AVAIL
	 jmp	 short DO_MAC_COMM ; Join common code

DO_MAC_COMM:
	 cmp	 word ptr LCLITEM.ID,MACTYPE_PRGM ; Check for type program
	 jnz	 DO_MAC_COPY
	 cmp	 byte ptr LCLITEM.ENTNAME,0	; Check for no name
	 jnz	 DO_MAC_COPY
	 mov	 LCLITEM.ID,MACTYPE_UNKNOWN	; Program with no name, set id to unknown
DO_MAC_COPY:
	 REGSAVE <es,di>	; Save registers
	 les	 di,BUFPTR	; Point at caller's buffer
	 mov	 si,offset LCLITEM ; ..and our local item
	 mov	 cx,SIZE LCLITEM ; How much to copy
	 rep	 movsb		; Copy it
	 mov	 word ptr BUFPTR,di ; Update pointer
	 REGREST <di,es>	; Restore registers

	 ; Reset size in case we're processing device drivers
	 mov	 word ptr LCLITEM.NPARA,0	; Size too

	 dec	 ITEMCOUNT	; Bump counter
	 jz	 short DO_MAC_EXIT ; If out of space

	 cmp	 CURDEV_VEC.VSEG,-1 ; Any more nested device drivers?
	 je	 short DO_MAC_EXIT ; Not this time

	 jmp	 DO_MAC_DD1	; Go around again

DO_MAC_EXIT:
	 REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore
	 assume  ds:DGROUP,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DO_MAC endp			; End DO_MAC procedure

	 NPPROC  SAVE_NAME
COMMENT|

Save MAC entry name in local structure

On entry;

ES:SI = Name
CX    = Chars in name, 0 if null-terminated

|

	 assume  ds:DGROUP,es:nothing ; Tell the assembler

	 mov	 bx,offset LCLITEM.ENTNAME ; Point at name storage
	 or	 cx,cx			; Check for CX = 0
	 jz	 SAVE_NAME_1		; If so
	 cmp	 cx,ENTNAMESIZE 	; Clip name length
	 jl	 SAVE_NAME_2		; Less than sizeof(NAME)
SAVE_NAME_1:
	 mov	 cx,ENTNAMESIZE - 1
SAVE_NAME_2:
	 mov	 al,es:[si]		; Copy to local storage
	 cmp	 al,0			; Terminator?
	 jz	 SAVE_NAME_EXIT 	; Yes, bail out
	 mov	 [bx],al
	 inc	 si			; Bump pointers
	 inc	 bx
	 dec	 cx			; Else, loop
	 jnz	 SAVE_NAME_2
SAVE_NAME_EXIT:
	 mov	 byte ptr [bx],0	; Force null-terminator

	 ret			; All done

SAVE_NAME endp

	 NPPROC  SAVE_CHARDEV
COMMENT|

Save character device driver name in local structure

On entry;

ES:SI = Name

|

	 assume  ds:DGROUP,es:nothing ; Tell the assembler

	 mov	 LCLITEM.ID,MACTYPE_DD	; Set the entry ID
	 mov	 bx,offset LCLITEM.ENTNAME ; Point at name storage
	 mov	 word ptr [bx],'eD'     ; Store Dev=
	 add	 bx,2
	 mov	 word ptr [bx],'=v'
	 add	 bx,2

	 mov	 cx,8			; Name is always 8 chars
SAVE_CHARDEV_1:
	 mov	 al,es:[si]		; Copy to local storage
	 cmp	 al,0			; Terminator?
	 jz	 SAVE_CHARDEV_EXIT	; Yes, bail out
	 cmp	 al,0dh 		; '\r'?
	 jnz	 @F
	 mov	 al,' '                 ; ...then substitute space
	 jmp	 short SAVE_CHARDEV_2
@@:
	 cmp	 al,0ah 		; '\n'?
	 jnz	 @F
	 mov	 al,' '                 ; ...then substitute space
@@:
SAVE_CHARDEV_2:
	 mov	 [bx],al		; Store one character
	 inc	 si			; Bump pointers
	 inc	 bx
	 dec	 cx			; Else, loop
	 jnz	 SAVE_CHARDEV_1
SAVE_CHARDEV_EXIT:
	 mov	 byte ptr [bx],0	; Force null-terminator

	 ret			; All done

SAVE_CHARDEV endp


	 NPPROC  SAVE_BLKDEV
COMMENT|

Save block device driver name in local structure

On entry;

AH=count
AL=first unit

|

	 assume  ds:DGROUP,es:nothing ; Tell the assembler

	 mov	 LCLITEM.ID,MACTYPE_DD	; Set the entry ID
	 mov	 bx,offset LCLITEM.ENTNAME ; Point at name storage
	 mov	 word ptr [bx],'rD'     ; Store "Drive"
	 add	 bx,2
	 mov	 word ptr [bx],'vi'
	 add	 bx,2
	 mov	 word ptr [bx],' e'
	 add	 bx,2

	 cmp	 ah,1			; More than one drive?
	 jg	 SAVE_BLKDEV_2

	 mov	 ah,' '                 ; Only one drive
	 add	 al,'A'                 ; Convert number to letter
	 mov	 [bx],ax		; Store it
	 inc	 bx
	 jmp	 SAVE_BLKDEV_EXIT	; Join common code

SAVE_BLKDEV_2:
	 dec	 bx
	 mov	 word ptr [bx],' s'     ; Make "Drive" into "Drives"
	 add	 bx,2

	 add	 al,'A'                 ; Convert numbers to letters
	 add	 ah,al
	 dec	 ah

	 mov	 [bx],al		; Store starting letter
	 inc	 bx
	 mov	 byte ptr [bx],'-'      ; Hyphen
	 inc	 bx
	 mov	 [bx],ah		; Store ending letter
	 inc	 bx

SAVE_BLKDEV_EXIT:
	 mov	 byte ptr [bx],0	; Force null-terminator

	 ret			; All done

SAVE_BLKDEV endp


	 NPPROC  DISP_TEXT	; -- Display Text of MAC Entry
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Display text of MAC entry.
If environment name only (starts with 0000, 0001), stop display
after the name.

On entry;

ES:0	 ==>	 Environment text

|

	 REGSAVE <ax,cx,dx,si,di> ; Save registers
	 assume ds:DGROUP,es:nothing

	 xor	 di,di		; ES:DI ==> start of data
	 mov	 si,offset LCLITEM.ENVTEXT

	 mov	 cx,ENVTEXTSIZE - 1 ; Size of text area
	 xor	 dx,dx		; Initialize flags to zero

	 cmp	 es:[di].ELO,0000h ; Izit a word like this?
	 jne	 short DISP_TEXT_NEXT ; No, continue on

	 cmp	 es:[di].EHI,0001h ; Izit a word like this?
	 jne	 short DISP_TEXT_NEXT ; No, continue on

	 add	 di,4		; Yes, skip over it
	 inc	 dx		; Mark as environment name only
DISP_TEXT_NEXT:
	 mov	 al,es:[di]	; Get next character
	 inc	 di		; Bump pointer

	 cmp	 al,80h 	; Bigger than the highest character?
	 jae	 short DISP_TEXT_EXIT ; Yes, skip out

	 cmp	 al,' '         ; Bigger than a blank?
	 jae	 short DISP_TEXT_STORE ; Yes, just store it

	 and	 al,al		; Zero value?
	 jnz	 short DISP_TEXT_EXIT ; No, skip out

	 and	 dx,dx		; Check for environment name only
	 jnz	 short DISP_TEXT_EXIT ; That's all folks

	 mov	 al,'³'         ; Use fill value
DISP_TEXT_STORE:
	 mov	 ds:[si],al	; Store one text char
	 inc	 si
	 loop	 DISP_TEXT_NEXT ; Jump if more text to display
DISP_TEXT_EXIT:
	 mov	 byte ptr ds:[si],0	; String terminator
	 REGREST <di,si,dx,cx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_TEXT endp			; End DISP_TEXT procedure

	 MEND			; End UTIL_MA2 module
