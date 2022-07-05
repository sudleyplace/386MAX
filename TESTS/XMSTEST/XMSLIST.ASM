;' $Header:   P:/PVCS/MISC/XMSTEST/XMSLIST.ASV   1.1   06 Aug 1992 13:18:12   HENRY  $

	 title	 XMSLIST -- XMS Lister
	 page	 58,122
	 name	 XMSLIST
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-92 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Stack   segment STACK, byte-aligned,  stack,  class 'prog'
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Tail    segment DTAIL, dword-aligned, public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, July, 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include PTR.INC
	 include XMS.INC
	 include 386.INC
.list

XMSALLOC_STR struc

XMSALLOC_ADDR dd ?		; Lock address
XMSALLOC_LEN  dd ?		; Length in bytes
XMSALLOC_OWNR dw ?		; Owning handle #
XMSALLOC_LOCK db ?		; Lock count
	 db	 ?		; For alignment

XMSALLOC_STR ends


XMSFREE_STR struc		; For free chain

XMSFREE_NEXT dd  ?		; 32-bit address of next block:  -1 = last
XMSFREE_PREV dd  ?		; ...		    prev block:  -1 = first
XMSFREE_LEN  dd  ?		; 32-bit length of this block in bytes

XMSFREE_STR ends


PGROUP	 group	 STACK,CODE,DATA,DTAIL

; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment use16 byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 public  XMSMEM
XMSMEM	 XMSFREE_STR <> 	; Common data structure

	 public  MOVETAB
MOVETAB  MDTE_STR <>		; Move GDT

	 public  XMSSLO,XMSPREV,XMSBASE,XMSFREE,TOTFREE,XMSHNDL,CNTALLOC,PXMSALLOC
XMSSLO	 dd	 ?		; Lowest XMS address
XMSPREV  dd	 ?		; Save area for previous entry
XMSBASE  dd	 ?		; ...		current
XMSFREE  dd	 -1		; Next lowest free address (-1 = none)
TOTFREE  dd	 0		; Total free lengths
XMSHNDL  dw	 ?		; XMS handle #
CNTALLOC dw	 ?		; Count of allocated handles
PXMSALLOC dw	 -1		; Ptr to next lowest allocated entry

	 public  XMSDRV_VEC
XMSDRV_VEC dd	 ?		; Address of XMS driver

	 public  LCL_FLAG
LCL_FLAG db	 0		; Local flags
@LCL_SLO equ	 80h		; Span low filled in

	 public  MSG_HDR
MSG_HDR  db	 'XMSLIST  -- Version 2.00 -- XMS Memory DIsplay',CR,LF
	 db	 '  (C) Copyright 1988-91 Qualitas, Inc.  GNU General Public License version 3.',CR,LF
	 db	 'Base       Base+Len   Length   NextFree  PrevFree Owner  Lock',CR,LF
MSG_LINE db	 '컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�',CR,LF,EOS
MSG_FXMS  label  byte
MSG_FXMS_BASE db '________:  '
MSG_FXMS_BPL  db '________  '
MSG_FXMS_LEN  db '________  '
MSG_FXMS_NEXT db '________  '
MSG_FXMS_PREV db '________  '
	 db	 CR,LF,EOS

MSG_AXMS  label  byte
MSG_AXMS_BASE db '________:  '
MSG_AXMS_BPL  db '________  '
MSG_AXMS_LEN  db '________  '
	      db '          '
	      db '          '
MSG_AXMS_OWNR db '____   '
MSG_AXMS_LOCK db '__'
	 db	 CR,LF,EOS

	 public  MSG_TAIL
MSG_TAIL label	 byte
MSG_TAIL_BEG db  '________:  '
MSG_TAIL_END db  '________  '
MSG_TAIL_LEN db  '________  '
MSG_TAIL_FREE db '________'
	 db	 CR,LF,EOS

	 public  MSG_NOTPRES,MSG_NOXMB
MSG_NOTPRES db	 BEL,'袴> XMS driver not rpesent.',CR,LF,EOS
MSG_NOXMB db	 BEL,'袴> No free extended memory.',CR,LF,EOS

	 public  XLAT_TAB
XLAT_TAB db	 '0123456789ABCDEF'

	 public  LCLSTK,LCLSTKZ
LCLSTK	 dw	 256 dup (?)	; Local stack
LCLSTKZ  dw	 0		; End of the stack

DATA	 ends			; End DATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

DTAIL	 segment use16 dword public 'data' ; Start DTAIL segment
	 assume  ds:PGROUP

	 public  ZTAIL
ZTAIL	 label	 byte

DTAIL	 ends			; End DTAIL segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

.xlist
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list
	 NPPROC  XMSLIST -- XMS Lister
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

; Switch to local stack

	 lea	 sp,LCLSTKZ

; Ensure XMS driver present

	 mov	 ax,4300h	; Function to determine presence
	 int	 2Fh		; Request redirector service

	 cmp	 al,80h 	; Check for presence
	 je	 short @F	; Jump if present

	 DOSCALL @STROUT,MSG_NOTPRES ; Tell 'em the bad news

	 jmp	 XMSLIST_EXIT	; Join common exit code

@@:

; Request driver control address

	 push	 es		; Save for a moment

	 mov	 ax,4310h	; Function to get address
	 int	 2Fh		; Request redirector service
	 assume  es:nothing	; Tell the assembler about it

	 mov	 XMSDRV_VEC.VOFF,bx ; Save for later use
	 mov	 XMSDRV_VEC.VSEG,es

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

; Ensure XMS memory present

	 mov	 ah,@XMS_QRYXMB ; Function to query XMB size
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,0		; Check return code
	 jne	 short @F	; Jump if some available

	 DOSCALL @STROUT,MSG_NOXMB ; Tell 'em the bad news

	 jmp	 XMSLIST_EXIT	; Join common exit code

@@:
;;;;;;;; mov	 XMBSIZE,ax	; Save for later use

; Display message header

	 DOSCALL @STROUT,MSG_HDR

; Find all allocated handles

	 call	 FNDALLOC	; Find 'em

; Setup move GDT source and destin length

	 mov	 ecx,(size XMSFREE_STR)-1 ; Move limit in bytes

	 mov	 MOVETAB.MDTE_DS.DESC_SEGLM0,cx
	 ror	 ecx,16 	; Shift down the high-order word
	 mov	 MOVETAB.MDTE_DS.DESC_SEGLM1,cl
	 rol	 ecx,16 	; Restore

	 mov	 MOVETAB.MDTE_ES.DESC_SEGLM0,cx
	 ror	 ecx,16 	; Shift down the high-order word
	 mov	 MOVETAB.MDTE_ES.DESC_SEGLM1,cl
	 rol	 ecx,16 	; Restore

; Setup move GDT destin address as XMSMEM

	 xor	 eax,eax	; Zero the entire register
	 mov	 ax,cs		; Copy current segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 lea	 ebx,XMSMEM	; Get offset in this segment of our XMS structure
	 add	 eax,ebx	; Add to get 32-bit linear address of XMSMEM

	 mov	 MOVETAB.MDTE_ES.DESC_BASE01,ax
	 shr	 eax,16 	; Shift down the high-order word
	 mov	 MOVETAB.MDTE_ES.DESC_BASE2,al
	 mov	 MOVETAB.MDTE_ES.DESC_BASE3,ah

; Setup move GDT source and destin access rights bytes

	 mov	 MOVETAB.MDTE_DS.DESC_ACCESS,CPL0_DATA
	 mov	 MOVETAB.MDTE_ES.DESC_ACCESS,CPL0_DATA

; Loop through extended memory using BIOS Block Moves

; On entry:

; EAX	 =	 next 32-bit linear address

	 call	 FNDSTART	; Find start of XMS free chain
	 jc	 near ptr XMSLIST_EXIT ; Jump if something went wrong
XMSLIST_NEXT:

; Display the lower address of XMSFREE and PXMSALLOC

	 mov	 eax,XMSFREE	; Get next lowest free address

	 cmp	 CNTALLOC,0	; Izit the end of allocated handles?
	 je	 short XMSLIST_NEXT1 ; Jump if so

	 mov	 bx,PXMSALLOC	; Get pointer to next lowest allocated address

	 cmp	 eax,PGROUP:[bx].XMSALLOC_ADDR ; Check against next lowest addr
	 jb	 short XMSLIST_NEXT1 ; Jump if free address is lower

	 mov	 eax,PGROUP:[bx].XMSALLOC_ADDR ; Get its address
	 mov	 XMSBASE,eax	; Save as current base

	 test	 LCL_FLAG,@LCL_SLO ; Izit filled in as yet?
	 jnz	 short @F	; Jump if so

	 lea	 di,MSG_TAIL_BEG ; ES:DI ==> output area
	 call	 DD2HEX 	; Format EAX in hex at ES:DI
	 mov	 XMSSLO,eax	; Save for later use
	 or	 LCL_FLAG,@LCL_SLO ; Mark as filled in
@@:

; Display the data in XMSALLOC_STR

;;;;;;;; mov	 eax,PGROUP:[bx].XMSALLOC_ADDR ; Get its address
	 lea	 di,MSG_AXMS_BASE ; ES:DI ==> output area
	 call	 DD2HEX 	; Format EAX in hex at ES:DI

	 add	 eax,PGROUP:[bx].XMSALLOC_LEN ; Plus its length in bytes
	 lea	 di,MSG_AXMS_BPL ; ES:DI ==> output area
	 call	 DD2HEX 	; Format EAX in hex at ES:DI

	 mov	 eax,PGROUP:[bx].XMSALLOC_LEN ; Get its length in bytes
	 mov	 XMSMEM.XMSFREE_LEN,eax ; Save as the last block's length
	 lea	 di,MSG_AXMS_LEN ; ES:DI ==> output area
	 call	 DD2HEX 	; Format EAX in hex at ES:DI

	 mov	 ax,PGROUP:[bx].XMSALLOC_OWNR ; Get its owning handle
	 lea	 di,MSG_AXMS_OWNR ; ES:DI ==> output area
	 call	 DW2HEX 	; Format AX in hex at ES:DI

	 mov	 al,PGROUP:[bx].XMSALLOC_LOCK ; Get its lock count
	 lea	 di,MSG_AXMS_LOCK ; ES:DI ==> output area
	 call	 DB2HEX 	; Format AL in hex at ES:DI

	 DOSCALL @STROUT,MSG_AXMS ; Display the entry

	 add	 PXMSALLOC,size XMSALLOC_STR ; Skip to next entry
	 dec	 CNTALLOC	; Count out another entry

	 jmp	 XMSLIST_NEXT	; Join common code

XMSLIST_NEXT1:
	 cmp	 eax,-1 	; Izit the end of free memory?
	 je	 near ptr XMSLIST_END ; Jump if so

	 test	 LCL_FLAG,@LCL_SLO ; Izit filled in as yet?
	 jnz	 short @F	; Jump if so

	 lea	 di,MSG_TAIL_BEG ; ES:DI ==> output area
	 call	 DD2HEX 	; Format EAX in hex at ES:DI
	 mov	 XMSSLO,eax	; Save for later use
	 or	 LCL_FLAG,@LCL_SLO ; Mark as filled in
@@:
	 mov	 XMSBASE,eax	; Save as current base

; Setup move GDT source address as EAX

	 mov	 MOVETAB.MDTE_DS.DESC_BASE01,ax
	 shr	 eax,16 	; Shift down the high-order word
	 mov	 MOVETAB.MDTE_DS.DESC_BASE2,al
	 mov	 MOVETAB.MDTE_DS.DESC_BASE3,ah

	 lea	 si,MOVETAB	; ES:SI ==> move GDT
	 mov	 cx,(size XMSFREE_STR)/2 ; Move length in words
	 mov	 ah,87h 	; Function code to move extended memory
	 int	 15h		; Request BIOS service

	 and	 ah,ah		; Check return code
	 jz	 short @F	; Jump if OK

	 int	 03h		; Call our debugger
@@:

; Display the data in XMSMEM

	 mov	 eax,XMSBASE	; Get pointer to base entry
	 lea	 di,MSG_FXMS_BASE ; ES:DI ==> output area
	 call	 DD2HEX 	; Format EAX in hex at ES:DI

	 add	 eax,XMSMEM.XMSFREE_LEN ; Plus its length in bytes
	 lea	 di,MSG_FXMS_BPL ; ES:DI ==> output area
	 call	 DD2HEX 	; Format EAX in hex at ES:DI

	 mov	 eax,XMSMEM.XMSFREE_LEN ; Get length in bytes
	 lea	 di,MSG_FXMS_LEN ; ES:DI ==> output area
	 call	 DD2HEX 	; Format EAX in hex at ES:DI

	 mov	 eax,XMSMEM.XMSFREE_NEXT ; Get pointer to next entry
	 lea	 di,MSG_FXMS_NEXT ; ES:DI ==> output area
	 call	 DD2HEX 	; Format EAX in hex at ES:DI

	 mov	 eax,XMSMEM.XMSFREE_PREV ; Get pointer to previous entry
	 lea	 di,MSG_FXMS_PREV ; ES:DI ==> output area
	 call	 DD2HEX 	; Format EAX in hex at ES:DI

	 DOSCALL @STROUT,MSG_FXMS ; Display the entry

; Ensure XMSFREE_PREV checks out

	 mov	 eax,XMSMEM.XMSFREE_PREV ; Get pointer to previous entry

	 cmp	 eax,-1 	; Anything precede us?
	 je	 short @F	; Not this time

	 cmp	 eax,XMSPREV	; Check against previous entry
	 je	 short @F	; Jump if it checks out

	 int	 03h		; Call debugger
@@:
	 mov	 eax,XMSBASE	; Get current base
	 mov	 XMSPREV,eax	; Save as previous entry

; Save free length

	 mov	 eax,XMSMEM.XMSFREE_LEN ; Get this block's length
	 add	 TOTFREE,eax	; Save as part of free length

	 mov	 eax,XMSMEM.XMSFREE_NEXT ; Get pointer to next entry
	 mov	 XMSFREE,eax	; Save for later use

	 jmp	 XMSLIST_NEXT	; Go around again

; Display beginning and ending addresses, total and free lengths

XMSLIST_END:
	 mov	 eax,XMSBASE	; Get pointer to base entry
	 add	 eax,XMSMEM.XMSFREE_LEN ; Plus the last block's length
	 lea	 di,MSG_TAIL_END ; ES:DI ==> output area
	 call	 DD2HEX 	; Format EAX in hex at ES:DI

	 sub	 eax,XMSSLO	; Less starting address to get span
	 lea	 di,MSG_TAIL_LEN ; ES:DI ==> output area
	 call	 DD2HEX 	; Format EAX in hex at ES:DI

	 mov	 eax,TOTFREE	; Get free length
	 lea	 di,MSG_TAIL_FREE ; ES:DI ==> output area
	 call	 DD2HEX 	; Format EAX in hex at ES:DI

	 DOSCALL @STROUT,MSG_LINE ; Display it
	 DOSCALL @STROUT,MSG_TAIL ; Display it
XMSLIST_EXIT:
	 ret			; Return to DOS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XMSLIST  endp			; End XMSLIST procedure
	 NPPROC  FNDALLOC -- Find XMS Allocated Handles
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find all XMS allocated handles

|

	 REGSAVE <eax,bx,cx,dx,di> ; Save registers

	 lea	 di,ZTAIL	; ES:DI ==> XMS allocattion structure
	 mov	 XMSHNDL,0	; Initialize starting handle
	 mov	 CNTALLOC,0	; Initialize allocated count
FNDALLOC_NEXT:
	 mov	 dx,XMSHNDL	; Get handle #
	 mov	 PGROUP:[di].XMSALLOC_OWNR,dx ; Save owning handle (if valid)
	 mov	 ah,@XMS_GETINF ; Function to get handle information
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
	 jne	 short FNDALLOC_LOOP ; Jump if not valid

	 movzx	 eax,dx 	; Copy length in 1KB
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 mov	 PGROUP:[di].XMSALLOC_LEN,eax ; Save length in bytes
	 mov	 PGROUP:[di].XMSALLOC_LOCK,bh ; Save lock count

	 mov	 dx,XMSHNDL	; Get handle #
	 mov	 ah,@XMS_LCKXMB ; Function to lock an XMB
	 call	 XMSDRV_VEC	; Request XMS service
				; Return with DX:BX = address if AX = 1

	 cmp	 ax,1		; Check return code
	 jne	 short FNDALLOC_LOOP ; Jump if not valid

	 mov	 PGROUP:[di].XMSALLOC_ADDR.ELO,bx ; Save low-order address
	 mov	 PGROUP:[di].XMSALLOC_ADDR.EHI,dx ; ...  high-...

	 add	 di,size XMSALLOC_STR ; Skip to next entry

	 inc	 CNTALLOC	; Count in another allocated handle

	 mov	 dx,XMSHNDL	; Get handle #
	 mov	 ah,@XMS_UNLXMB ; Function to unlock an XMB
	 call	 XMSDRV_VEC	; Request XMS service
;;;;;;;;
;;;;;;;; cmp	 ax,1		; Check return code
;;;;;;;; jne	 short FNDALLOC_LOOP ; Jump if not valid
FNDALLOC_LOOP:
	 inc	 XMSHNDL	; Skip to next handle

	 cmp	 XMSHNDL,0	; Izit wrapped?
	 jne	 short FNDALLOC_NEXT ; Jump if not

; Sort CNTALLOC entries in ascending order by address

	 cmp	 CNTALLOC,0	; Get count of entries
	 je	 FNDALLOC_EXIT	; Jump if none

	 mov	 PXMSALLOC,offset PGROUP:ZTAIL ; Point to 1st struc

COMMENT|

As there's unlikely to be very many allocated handles,
we'll use a simple bubble sort

BX	 =	 lowest entry under consideration (outer loop)
DI	 =	 next ...			  (inner loop)

|

	 mov	 bx,PXMSALLOC	; Get 1st ptr
	 mov	 cx,CNTALLOC	; Get count of entries
FNDALLOC_ONEXT:
	 mov	 eax,PGROUP:[bx].XMSALLOC_ADDR ; Get its address
	 mov	 di,bx		; Copy as next preceding address

	 push	 cx		; Save for a moment

	 jmp	 short FNDALLOC_ILOOP ; Join common code

FNDALLOC_INEXT:
	 cmp	 eax,PGROUP:[di].XMSALLOC_ADDR ; Izit smaller?
	 jbe	 short FNDALLOC_ILOOP ; Jump if so (no exchange)

; Exchange the two entries

;;;;;;;; mov	 eax,PGROUP:[bx].XMSALLOC_ADDR ; Get its address
	 xchg	 eax,PGROUP:[di].XMSALLOC_ADDR ; Swap 'em
	 mov	 PGROUP:[bx].XMSALLOC_ADDR,eax ; ...

	 mov	 eax,PGROUP:[bx].XMSALLOC_LEN ; Get its length
	 xchg	 eax,PGROUP:[di].XMSALLOC_LEN ; Swap 'em
	 mov	 PGROUP:[bx].XMSALLOC_LEN,eax ; ...

	 mov	 al,PGROUP:[bx].XMSALLOC_LOCK ; Get its lock count
	 xchg	 al,PGROUP:[di].XMSALLOC_LOCK ; Swap 'em
	 mov	 PGROUP:[bx].XMSALLOC_LOCK,al ; ...

	 pop	 cx		; Restore outer loop counter

	 jmp	 FNDALLOC_ONEXT ; Go around again

FNDALLOC_ILOOP:
	 add	 di,size XMSALLOC_STR ; Skip to next struc

	 loop	 FNDALLOC_INEXT ; Jump if more inner loop elements
FNDALLOC_OLOOP:
	 pop	 cx		; Restore outer loop count

	 add	 bx,size XMSALLOC_STR ; Skip to next struc

	 loop	 FNDALLOC_ONEXT ; Jump if more outer loop elements
FNDALLOC_EXIT:
	 REGREST <di,dx,cx,bx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FNDALLOC endp			; End FNDALLOC procedure
	 NPPROC  FNDSTART -- Return Starting XMS Free Address
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Return starting XMS free address

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,dx>	; Save register

; Allocate a 1KB entry, lock it, unlock it, free it

	 mov	 dx,1		; Minimum allocation unit
	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service
				; Return with DX = handle if AX = 1

	 cmp	 ax,1		; Check on our success
	 je	 short @F	; Jump if OK

	 cmp	 bl,0A0h	; Izit no memory free?
	 je	 short FNDSTART_CLC ; Jump if so

	 jmp	 short FNDSTART_ERR ; Jump if in error

@@:
	 mov	 XMSHNDL,dx	; Save as handle #

;;;;;;;; mov	 dx,XMSHNDL	; Get handle #
	 mov	 ah,@XMS_LCKXMB ; Function to lock an XMB
	 call	 XMSDRV_VEC	; Request XMS service
				; Return with DX:BX = address if AX = 1

	 cmp	 ax,1		; Check on our success
	 jne	 short FNDSTART_ERR ; Jump if in error

	 mov	 XMSFREE.ELO,bx ; Save the 32-bit address
	 mov	 XMSFREE.EHI,dx ; ...

	 mov	 dx,XMSHNDL	; Get handle #
	 mov	 ah,@XMS_UNLXMB ; Function to unlock an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 jne	 short FNDSTART_ERR ; Jump if in error

	 mov	 dx,XMSHNDL	; Get handle #
	 mov	 ah,@XMS_RELXMB ; Function to release an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 jne	 short FNDSTART_ERR ; Jump if in error
FNDSTART_CLC:
	 clc			; Indicate all went well

	 jmp	 short FNDSTART_EXIT ; Join common exit code

FNDSTART_ERR:
	 stc			; Indicate something went wrong
FNDSTART_EXIT:
	 REGREST <dx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FNDSTART endp			; End FNDSTART procedure
	 NPPROC  DB2HEX -- Binary AL To Hex at ES:DI & Following
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 cx,2		; # hex digits to convert (left-to-right)
	 lea	 bx,XLAT_TAB	; DS:BX ==> translate table
	 mov	 dl,al		; Copy for testing
DB2HEX_LOOP:
	 rol	 dl,4		; Rotate high-order nibble to low-order
	 mov	 al,dl		; Copy to format
	 and	 al,0Fh 	; Isolate nibble
	 xlat	 XLAT_TAB	; Translate to ASCII

	 stosb

	 loop	 DB2HEX_LOOP	; Go around again

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DB2HEX	 endp			; End DB2HEX procedure
	 NPPROC  DW2HEX -- Binary AX To Hex at ES:DI & Following
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 cx,4		; # hex digits to convert (left-to-right)
	 lea	 bx,XLAT_TAB	; DS:BX ==> translate table
	 mov	 dx,ax		; Copy for testing
DW2HEX_LOOP:
	 rol	 dx,4		; Rotate high-order nibble to low-order
	 mov	 al,dl		; Copy to format
	 and	 al,0Fh 	; Isolate nibble
	 xlat	 XLAT_TAB	; Translate to ASCII

	 stosb

	 loop	 DW2HEX_LOOP	; Go around again

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DW2HEX	 endp			; End DW2HEX procedure
	 NPPROC  DD2HEX -- Binary EAX To Hex at ES:DI & Following
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <ax,bx,cx,edx> ; Save registers

	 mov	 cx,8		; # hex digits to convert (left-to-right)
	 lea	 bx,XLAT_TAB	; DS:BX ==> translate table
	 mov	 edx,eax	; Copy for testing
DD2HEX_LOOP:
	 rol	 edx,4		; Rotate high-order nibble to low-order
	 mov	 al,dl		; Copy to format
	 and	 al,0Fh 	; Isolate nibble
	 xlat	 XLAT_TAB	; Translate to ASCII

	 stosb

	 loop	 DD2HEX_LOOP	; Go around again

	 REGREST <edx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2HEX	 endp			; End DD2HEX procedure

CODE	 ends			; End CODE segment

	 MEND	 XMSLIST	; End XMSLIST module
