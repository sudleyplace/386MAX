; $Header:   P:/PVCS/MAX/386MAX/UTIL_DDD.ASV   1.3   08 Jul 1998 12:30:06   BOB  $
	 title	 UTIL_DDD -- 386UTIL/MOVE'EM Device Driver Display
	 page	 58,122
	 name	 UTIL_DDD

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1986-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Program segment UCODE,	byte-aligned,  public, class 'ucode'
	       Data    segment UDATA,	dword-aligned, public, class 'udata'

Program derived from:  None.

Original code by:  Bob Smith, May, 1986.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include DOS.INC
	 include FCB.INC
	 include INTVEC.INC
	 include DEVDRV.INC
	 include PTR.INC
	 include KEYCALL.INC
	 include IOCTL.INC
	 include MAC.INC
	 include LOAD_SEG.INC

	 include QMAX_FMT.INC
	 include COMM_OEM.INC
.list

if @OEM_MAPDEV
DDD_SEG  segment at 0		; Start DDD_SEG segment

NEXT_VEC label	 dword		; Pointer to next device driver
NEXT_OFF dw	 ?
NEXT_SEG dw	 ?		; -1 = last device in this routine

DEV_ATTR dw	 ?		; Device attribute
DEV_STR  dw	 ?		; Pointer to device strategy
DEV_INT  dw	 ?		; Pointer to device interrupt handler

; The next eight bytes are filled in differently for block vs. character
; devices.

; For block devices, the first byte contains the # units defined by this
; routine, and the remaining bytes are undefined.

; For character devices, the device name is placed there, left-justified,
; and blank-filled.

DEV_NAME db	 8 dup (?)	; Block device # block devices

DDD_SEG  ends			; End DDD_SEG segment


PGROUP	 group	 CODE,DATA,NDATA,UCODE,UDATA


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 CHECK_LINE:near

CODE	 ends			; End CODE segment


DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 POVR_MAC:word
	 extrn	 LOADSEG:word

DATA	 ends			; End DATA segment


NDATA	 segment dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 LINECNT:word
	 extrn	 NUMBERS_HI:byte
	 extrn	 DOSVER:word

NDATA	 ends			; End NDATA segment


UDATA	 segment dword public 'udata' ; Start UDATA segment
	 assume  ds:PGROUP

	 extrn	 LINECNT:word
	 extrn	 NUMBERS_HI:byte
	 extrn	 DOSVER:word

	 public  NULNAME
NULNAME  db	 'NUL     '     ; Nul device driver name

	 public  PFILE_HNDL
PFILE_HNDL dd	 002Ah		; Pointer to start of DOS file info which
				; follows the last device driver

	 public  LASTOFF,LASTSEG,LASTHI,HIGHSEG
LASTOFF  dw	 ?		; Last DD offset
LASTSEG  dw	 -1		; ...	  segment
LASTHI	 dw	 -1		; Last DD segment in high DOS
HIGHSEG  dw	 ?		; Highest segment

	 public  MSG_DDDHDR,MSG_ICLR,MSG_FILL,MSG_IDSP,MSG_DDDTAIL
MSG_DDDHDR db	 'ีอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออธ',CR,LF
ifdef LANG_GR
	 db	 'ณ                   SPEICHER-PLAN DER EINHEITEN-TREIBER                       ณ',CR,LF
else
	 db	 'ณ                        MEMORY MAP for DEVICE DRIVERS                        ณ',CR,LF
endif				; IFDEF LANG_GR
	 db	 'รฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด',CR,LF
ifdef LANG_GR
	 db	 'ณ           ณ   Hex-    ณ  Lnge  ณ                                           ณ',CR,LF
	 db	 'ณ Name      ณ  Anfang   ณ   dez.  ณ Interrupt-Nummern                         ณ',CR,LF
else
	 db	 'ณ           ณ           ณ Decimal ณ                                           ณ',CR,LF
	 db	 'ณ Name      ณ Hex Start ณ  Length ณ Interrupt Numbers                         ณ',CR,LF
endif				; IFDEF LANG_GR
	 db	 'รฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤด',CR,LF
	 db	 0
MSG_ICLR db	 '                                           ณ',CR,LF,0
MSG_FILL db	 'ณ           ณ           ณ         ณ'
MSG_IDSP db	 '                                          '
MSG_IDSP_LEN equ $-MSG_IDSP	; Length of display area
	 db	 ' ณ',CR,LF,0
MSG_DDDTAIL db	 'ิอออออออออออฯอออออออออออฯอออออออออฯอออออออออออออออออออออออออออออออออออออออออออพ',CR,LF
	 db	 0

	 public  MSG_VEC
MSG_VEC  db	 ' '
MSG_SEG  db	 '____:'
MSG_OFF  db	 '____ ณ',0

	 public  MSG_NAME
MSG_NAME db	 'ณ '
MSG_NAME1 db	 '________  ณ',0

	 public  MSG_SIZE
	 db	 ?,?		; Room for overflow if number too large
MSG_SIZE db	 '       '
MSG_SIZELEN equ  $-MSG_SIZE
MSG_SIZE1 db	 '0 ณ',0

	 public  MSG_NDEV,MSG_NDEV1
ifdef LANG_GR
MSG_NDEV db	 'ณ Laufw.'
else
MSG_NDEV db	 'ณ Drive '
endif				; IFDEF LANG_GR
MSG_NDEV1 db	 '__  ณ',0

	 public  CNT_INTS,MSG_INTS1
CNT_INTS dw	 ?		; # interrupt vectors found
MSG_INTS1 db	 256 dup (' 00'),0

UDATA	 ends			; End UDATA segment


UCODE	 segment byte public 'ucode' ; Start UCODE segment
	 assume  cs:PGROUP

	 extrn	 DD2DEC:near
	 extrn	 DISP_ASCIIZ:near

	 NPPROC  ACT_DDD -- Device Driver Display
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Device driver display

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

	 DOSCALL @GETLST	; Return with ES:BX ==> list of lists
	 assume  es:DDD_SEG	; Tell the assembler

; Now search for "NUL     " in segment ES

	 lea	 di,DEV_NAME-1	; Initialize offset
	 lea	 si,NULNAME	; DS:SI ==> "NUL     "
	 mov	 cx,1-(size DEV_NAME) ; # possible offsets
NUL_AGAIN:
	 inc	 di		; Skip to next offset
	 dec	 cx		; Account for it

	 REGSAVE <cx,si,di>	; Save for a moment

	 mov	 cx,size DEV_NAME ; Length of device name
    repe cmpsb			; Compare 'em

	 REGREST <di,si,cx>	; Restore
	 loopne  NUL_AGAIN	; Jump if no match and more offsets to compare
	MJ ne	 ACT_DDD_ERR	; Not found???

	 mov	 bx,di		; Copy to another index register
	 sub	 bx,offset es:DEV_NAME ; Back off to start of header

	 mov	 ax,DEV_ATTR[bx] ; Get attributes
	 and	 ax,DRV_ATTR_CHAR or DRV_ATTR_NUL ; Isolate bits

	 cmp	 ax,DRV_ATTR_CHAR or DRV_ATTR_NUL ; At least these bits *MUST* be set
	 jne	 short NUL_AGAIN ; Not this time

	 mov	 di,bx		; Restore for later use

	 push	 es		; Save for a moment

	 cmp	 DOSVER,0400h	; Izit DOS 4.00 or later?
	 jb	 short ACT_DDD_DOS3 ; Jump if not
@@:
	 les	 bx,es:[bx].DD_NEXT ; ES:BX ==> next device driver
	 assume  es:nothing	; Tell the assembler

	 mov	 ax,es		; Get MAC entry para+1

	 cmp	 ax,POVR_MAC	; Is it in High DOS
	 jae	 short @B	; Yea, go back and get next

	 dec	 ax		; Back off to MAC entry para
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 add	 ax,es:[0].MAC_NPAR ; Plus # paras in this entry
	 inc	 ax		; Account for MAC para

	 jmp	 short ACT_DDD_DOSCOM ; Join common code

ACT_DDD_DOS3:
	 mov	 PFILE_HNDL.VSEG,es ; Save in pointer var
	 les	 bx,PFILE_HNDL	; ES:BX ==> pointer to file handle information
	 assume  es:nothing	; Tell the assembler
	 les	 bx,es:[bx]	; ES:BX ==> pointer to start of high DOS
	 assume  es:nothing	; Tell the assembler
	 mov	 ax,es:[bx].VSEG ; AX:0 ==> start of high DOS
ACT_DDD_DOSCOM:
	 mov	 HIGHSEG,ax	; Save for later use

	 pop	 es		; Restore
	 assume  es:DDD_SEG	; Tell the assembler

; Display message header

	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lea	 ax,MSG_DDDHDR	; DS:AX ==> message to display
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 add	 LINECNT,6-1	; Add in size of header
	 call	 CHECK_LINE	; Count in another line and check for pause
ACT_DDD_NEXT:
	 mov	 ax,4		; # digits to convert
	 push	 ax		; Pass as argument #3
	 lea	 ax,MSG_SEG	; Put result here
	 push	 ds		; Pass as argument #2 (segment)
	 push	 ax		; Pass as argument #2 (offset)
	 push	 es		; Pass as argument #1 (value)
	 call	 BIN2HEX	; Convert binary to hex

	 mov	 ax,4		; # digits to convert
	 push	 ax		; Pass as argument #3
	 lea	 ax,MSG_OFF	; Put result here
	 push	 ds		; Pass as argument #2 (segment)
	 push	 ax		; Pass as argument #2 (offset)
	 push	 di		; Pass as argument #1 (value)
	 call	 BIN2HEX	; Convert binary to hex

	 REGSAVE <di,es>	; Save for a moment

	 push	 cs		; Setup ES for DD2DEC
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MSG_SIZE	; ES:DI ==> output save area
	 mov	 cx,MSG_SIZELEN+1 ; CX = # bytes in MSF field
	 mov	 al,' '         ; Fill with this
     rep stosb			; Fill it up

	 REGREST <es,di>	; Restore
	 assume  es:DDD_SEG	; Tell the assembler

	 mov	 ax,es		; Copy segment

	 cmp	 ax,POVR_MAC	 ; Is it in High DOS
	 jb	 ACT_DDD_NEXTLOW ; No, go

	 cmp	 LASTHI,ax	; Have we done this segment before?
	 je	 short ACT_DDD_NEXTHI ; Yea then we don't need a size field

	 mov	 LASTHI,ax	; Save for next time

	 call	 ACT_DDD_GET_HI_SIZ ; See if an LSEG is for this segment?
	 jnc	 short @F	; There is so AX has size

	 mov	 [MSG_SIZE+(MSG_SIZELEN-5)].ELO,'??'  ; Put 5 question in..
	 mov	 [MSG_SIZE+(MSG_SIZELEN-3)].ELO,'?,'  ; the size field
	 mov	 [MSG_SIZE+(MSG_SIZELEN-1)].ELO,'??'  ;

	 jmp	 short ACT_DDD_NEXTHI ; Continue
@@:

	 call	 ACT_DDD_DISPSIZ ; Display AX paragraphs in bytes in size field
ACT_DDD_NEXTHI:
	 call	 FINDINTS	; Find interrupt vector list

	 jmp	 short ACT_DDD_NEXT4 ; Continue display

ACT_DDD_NEXTLOW:
	 cmp	 LASTSEG,-1	; Check for first time
	 je	 short ACT_DDD_NEXT1 ; It is, don't format size

	 cmp	 ax,LASTSEG	; Check against last one
	 ja	 short ACT_DDD_NEXT1 ; Out of order

	 mov	 ax,LASTSEG	; Get last segment
	 mov	 dx,es		; Copy current segment

	 sub	 ax,dx		; Less current segment
	 jnz	 short @F	; Jump if it's a different segment

	 mov	 LASTOFF,di	; Save as same offset for size of zero
@@:
	 call	 ACT_DDD_DISPSIZ ; Display AX paragraphs in bytes in size field

ACT_DDD_NEXT1:
	 call	 FINDINTS	; Find interrupt vector list

	 cmp	 LASTSEG,-1	; Check for first time
	 jne	 short ACT_DDD_NEXT3 ; It isn't

	 mov	 ax,HIGHSEG	; Use highest segment
	 mov	 LASTSEG,ax	; Save for next time
	 mov	 LASTOFF,0

	 jmp	 short ACT_DDD_NEXT4 ; Join common code

; Some networks write directly into the resident device driver chain
; thus causing the new segment to be higher than the old segment.
; We check for that here to avoid being confused by them

ACT_DDD_NEXT3:
	 mov	 ax,es		; Get current segment

	 cmp	 ax,LASTSEG	; Check against last segment
	 ja	 short ACT_DDD_NEXT4 ; Jump if it's spurious

	 mov	 LASTSEG,ax	; Save for next time
	 mov	 LASTOFF,di

ACT_DDD_NEXT4:
	 mov	 cx,16		; # bits to test
	 mov	 bx,DEV_ATTR[di] ; Get attributes

	 test	 bx,DRV_ATTR_CHAR ; Izit a character device?
	 jnz	 short FLAG_COM_CHAR ; Good guess

	 mov	 al,DEV_NAME[di] ; Get # drives supported
	 aam			; Convert to BCD
	 add	 ax,'00'        ; Convert to ASCII
	 mov	 MSG_NDEV1[0],ah ; Save in message
	 mov	 MSG_NDEV1[1],al

	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lea	 ax,MSG_NDEV	; DS:AX ==> the message to display
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 jmp	 short FLAG_COM_SIZE ; Join common size code

FLAG_COM_CHAR:
	 REGSAVE <ax,bx,cx,si,di> ; Save for a moment

	 lea	 si,DEV_NAME[di] ; DS:SI ==> source
	 lea	 di,MSG_NAME1	; ES:DI ==> destination

	 mov	 ax,ds
	 mov	 bx,es
	 mov	 ds,bx
	 assume  ds:DDD_SEG	; Tell the assembler
	 mov	 es,ax
	 assume  es:PGROUP	; Tell the assembler

	 mov	 cx,8		; # bytes in device name
	 push	 ax		; Save for a moment
FLAG_COM_CHAR_NEXT:
	 lodsb			; Get next byte

	 cmp	 al,' '         ; Check for too small
	 jae	 short @F	; Jump if OK

	 mov	 al,' '         ; Substitute a blank
@@:
	 stosb			; Store it

	 loop	 FLAG_COM_CHAR_NEXT ; Jump if more to display

	 pop	 ax		; Restore

	 mov	 ds,ax
	 assume  ds:PGROUP	; Tell the assembler
	 mov	 es,bx
	 assume  es:DDD_SEG	; Tell the assembler

	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lea	 ax,MSG_NAME	; DS:AX ==> the message to display
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 REGREST <di,si,cx,bx,ax> ; Restore
FLAG_COM_SIZE:
	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lea	 ax,MSG_VEC	; DS:AX ==> the message to display
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 cmp	 word ptr MSG_SIZE1[-1],'0 ' ; Anybody home?
	 jne	 short FLAG_COM_CRLF ; Not this time

	 mov	 MSG_SIZE1,' '  ; Clear the size value
FLAG_COM_CRLF:
	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lea	 ax,MSG_SIZE	; DS:AX ==> the message to display
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

; Display interrupt vectors (if any)

	 cmp	 CNT_INTS,0	; Any found?
	 je	 short ACT_DDD_INTCLR ; Not this time

	 call	 DISP_DDDINTS	; Display 'em

	 jmp	 short ACT_DDD_INTCOM ; Join common code

ACT_DDD_INTCLR:
	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lea	 ax,MSG_ICLR	; DS:AX ==> the message to display
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle
ACT_DDD_INTCOM:
	 call	 CHECK_LINE	; Count in another line and check for pause

	 cmp	 NEXT_OFF[di],-1 ; Check for end of the line
	 les	 di,NEXT_VEC[di] ; ES:DI ==> next device driver
	 je	 short ACT_DDD_TAIL ; That's all folks

	 jmp	 ACT_DDD_NEXT	; Go around for more

ACT_DDD_ERR:
	 stc			; Indicate something went wrong

	 jmp	 short ACT_DDD_EXIT ; Join common exit code

; Display the trailer

ACT_DDD_TAIL:
	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 lea	 ax,MSG_DDDTAIL ; DS:AX ==> the message to display
	 push	 ax		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 clc			; Indicate all went well
ACT_DDD_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_DDD  endp			; End ACT_DDD procedure
	 NPPROC ACT_DDD_DISPSIZ - Set driver size element of message
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

 Entry AX - Number of paragraphs used by driver

|
	 REGSAVE <ax,bx,dx,di,es> ; Save for a moment

	 mov	 cl,1*4 	; Shift amount for one digit
	 mov	 dx,ax		; Copy paragraph difference
	 shl	 ax,cl		; Shift out high-order digit
	 mov	 cl,3*4 	; Shift amount for three digits
	 shr	 dx,cl		; DX:AX has paragraph difference in bytes

	 push	 cs		; Setup ES for DD2DEC
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 push	 ax		; Save for a moment

	 lea	 di,MSG_SIZE	; ES:DI ==> output save area
	 mov	 cx,MSG_SIZELEN ; CX = # bytes in ...
	 mov	 al,' '         ; Fill with this
     rep stosb			; Fill it up
				; ES:DI ==> units digit of result
	 pop	 ax		; Restore

	 mov	 cx,@DEC_COMMA	; Mark as right-justified, comma insertion
	 push	 cx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal at ES:DI

	 REGREST <es,di,dx,bx,ax> ; Restore
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing


ACT_DDD_DISPSIZ endp		; ACT_DDD_DISPSIZ
	 NPPROC ACT_DDD_GET_HI_SIZ -- Get size of driver from LSEG
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

 Entry: AX - Segment of driver

 Exit:	CY - Set LSEG not found.
	CY - Clear.
	     AX = Number of high DOS paragraphs used to load driver

|
	 REGSAVE <bx,es>	; Save registers

	 mov	 bx,LOADSEG	; Get start of LSEG chain
@@:
	 cmp	 bx,-1		; Izit the end?
	 je	 short @F	;

	 mov	 es,bx		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 bx,es:[0].LSEG_NEXT ; Get segment of next entry

	 cmp	 ax,es:[0].LSEG_OWNRHI ; Same segment?
	 jne	 short @B	; No go do the next

	 mov	 ax,es:[0].LSEG_RPARA ; Get resident size

	 stc			; Set flag (No error)
@@:
	 cmc			; Flip flag for caller

	 REGREST <es,bx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_DDD_GET_HI_SIZ endp 	; End ACT_DDD_GET_HI_SIZ

	 NPPROC  FINDINTS -- Find Interrupt Vectors
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Find interrupt vectors whose segment is between ES:DI and LASTSEG:LASTOFF.

|

	 REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save registers

	 mov	 CNT_INTS,0	; Initialize counter

	 cmp	 LASTSEG,-1	; First time through?
	 je	 short FINDINTS_EXIT1 ; Yes

	 mov	 dx,es		; Copy for comparison

; Setup ES to point to interrupt vector table

	 mov	 ax,seg INTVEC
	 mov	 es,ax
	 assume  es:INTVEC	; Tell the assembler about it

	 lea	 bx,MSG_INTS1	; CS:BX ==> save area
	 lea	 si,INT00_VEC	; ES:SI ==> interrupt vector table
	 mov	 cx,0E0h	; # doubleword entries to search
FINDINTS_NEXT:
	 jcxz	 FINDINTS_EXIT	; No more words

	 cmp	 dx,INT00_VEC.VSEG[si] ; Check against current segment
	 ja	 short FINDINTS_LOOP ; Too small
	 jne	 short FINDINTS1 ; Unequal segments

	 cmp	 di,INT00_VEC.VOFF[si] ; Ensure current offset precedes it
	 ja	 short FINDINTS_LOOP ; Too small
FINDINTS1:
	 mov	 ax,LASTSEG	; Get last segment

	 cmp	 ax,INT00_VEC.VSEG[si] ; Check against segment
	 jb	 short FINDINTS_LOOP ; Too big
	 ja	 short FINDINTS2 ; Unequal segments

	 mov	 ax,LASTOFF	; Get last offset

	 cmp	 ax,INT00_VEC.VOFF[si] ; Check against offset
	 jbe	 short FINDINTS_LOOP ; Too big
FINDINTS2:
	 mov	 [bx].LO,' '    ; Include separator
	 inc	 bx		; Skip over it

	 mov	 ax,2		; # digits to convert
	 push	 ax		; Pass as argument #3
	 push	 cs		; Pass as argument #2 (segment)
	 push	 bx		; Pass as argument #2 (offset)

	 mov	 ax,si		; Copy offset
	 shr	 ax,1		; Divide by four to get interrupt #
	 shr	 ax,1
	 xchg	 al,ah		; Copy to high-order byte

	 push	 ax		; Pass as argument #1 (value)
	 call	 BIN2HEX	; Convert binary to hex

	 inc	 CNT_INTS	; Count in another one

	 add	 bx,2		; Skip to next output location
FINDINTS_LOOP:
	 add	 si,4		; Skip to next entry

	 loop	 FINDINTS_NEXT	; Jump if more entries
FINDINTS_EXIT:
	 mov	 [bx].LO,0	; Terminate the string
FINDINTS_EXIT1:
	 REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FINDINTS endp			; End FINDINTS procedure
	 NPPROC  DISP_DDDINTS -- Display Interrupt Vectors
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display interrupt vectors

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

	 push	 cs		; Setup ES for STOS
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 si,MSG_INTS1	; DS:SI ==> interrupt save area
	 mov	 bx,CNT_INTS	; Get current count
	 lea	 dx,MSG_IDSP	; DS:DX ==> message to display
DISP_DDDINTS_NEXTLIN:

; Clear the interrupt display area

	 lea	 di,MSG_IDSP	; ES:DI ==> output save area
	 mov	 cx,MSG_IDSP_LEN ; CX = length of ...
	 mov	 al,' '         ; Fill with this
     rep stosb			; Fill it up
	 mov	 cx,MSG_IDSP_LEN ; CX = length of ...
	 lea	 di,MSG_IDSP	; ES:DI ==> output save area
DISP_DDDINTS_NEXTCHR:
	 lods	 MSG_INTS1	; Get next character

	 and	 al,al		; Izit the last one?
	 jz	 short DISP_DDDINTS_NEXTCHRZ ; Jump if so

	 stos	 MSG_IDSP	; Save in output save area

	 loop	 DISP_DDDINTS_NEXTCHR ; Jump if more characters
DISP_DDDINTS_NEXTCHRZ:
	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 push	 dx		; Pass as argument
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 call	 CHECK_LINE	; Count in another line and check for pause

	 lea	 dx,MSG_FILL	; DS:AX ==> message to display

	 sub	 bx,MSG_IDSP_LEN/3 ; Less # interrupts just displayed
	 ja	 short DISP_DDDINTS_NEXTLIN ; Jump if more

	 cmp	 LINECNT,0	; Did we just wrap?
	 je	 short DISP_DDDINTS_EXIT ; Jump if not

	 dec	 LINECNT	; Count out another
DISP_DDDINTS_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_DDDINTS endp		; End DISP_DDDINTS procedure
	 NPPROC  BIN2HEX -- Convert Binary To Hex
	 assume  ds:PGROUP,es:nothing,ss:nothing

BIN2HEX_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's return address
SRC	 dw	 ?		; Convert this value
DES_VEC  dd	 ?		; Put it here
NDIGS	 dw	 ?		; # digits to convert

BIN2HEX_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,dx,di,es> ; Save registers

	 cld			; String ops forwardly
	 mov	 ax,[bp].SRC	; Convert this value
	 les	 di,[bp].DES_VEC ; ES:DI ==> destination
	 lea	 bx,NUMBERS_HI	; DS:BX ==> translate table
	 mov	 cx,[bp].NDIGS	; # digits to convert
	 mov	 dx,ax		; Copy for loop below
BIN2HEX_LOOP:
	 push	 cx		; Save loop counter

	 mov	 cl,4		; Shift amount
	 rol	 dx,cl		; Rotate around another nibble
	 mov	 al,dl		; Copy
	 and	 al,0Fh 	; Isolate low-order nibble
	 xlat	 NUMBERS_HI	; Translate into ASCII hex
	 stosb			; Store in result

	 pop	 cx		; Restore

	 loop	 BIN2HEX_LOOP	; Jump if more digits to convert

	 REGREST <es,di,dx,cx,bx,ax> ; Restore

	 pop	 bp		; Restore

	 ret	 8		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,ss:nothing

BIN2HEX  endp			; End BIN2HEX procedure

UCODE	 ends			; End UCODE segment
endif				; IF @OEM_MAPDEV

	 MEND			; End UTIL_DDD module
