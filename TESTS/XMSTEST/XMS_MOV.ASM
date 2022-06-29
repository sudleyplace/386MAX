;' $Header:   P:/PVCS/MISC/XMSTEST/XMS_MOV.ASV   1.1   06 Aug 1992 13:18:00   HENRY  $

	 title	 XMS_MOV -- XMS Move Tester
	 page	 58,122
	 name	 XMS_MOV
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-92 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment TEXT,  byte-aligned,  public, class 'data'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, July, 1988.

Modifications by:  None.

|

.286c
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include PTR.INC
	 include XMS.INC
	 include XMS_TEST.INC
.list


PGROUP	 group	 CODE,DATA,TEXT


DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 XMS_QRYXMB:byte

	 extrn	 XMSDRV_VEC:dword
	 extrn	 ERRMSG:word
	 extrn	 ERRCODE:byte
	 extrn	 XMBSIZE:word
	 extrn	 XMSHNDL:word

	 public  HNDL1,HNDL2
HNDL1	 dw	 ?		; Handle #1 for CHECK_MOV
HNDL2	 dw	 ?		; ...	  2

	 public  HNDL1_LEN,HNDL2_LEN
HNDL1_LEN dw	 ?		; Handle #1 length for CHECK_MOV
HNDL2_LEN dw	 ?		; Handle #2

	 public  MOVE_LEN
MOVE_LEN dw	 ?		; Length of move

	 public  LCLROM1,LCLROM2
LCLROM1  dw	 ?		; Save area for local ROM segment #1
LCLROM2  dw	 ?		; Save area for local ROM segment #2

	 public  XMBHNDL
XMBHNDL  dw	 255 dup (?)	; Save area for handle #

	 public  EXTMOVE
EXTMOVE  EXTMOVE_STR <> 	; Extended Memory Move block

DATA	 ends			; End DATA segment


TEXT	 segment byte public 'data' ; Start TEXT segment
TEXT	 ends			; End TEXT segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 NPPROC  CHECK_MOV -- Check On Extended Memory Block Move
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check on extended memory block move

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers

	 DISPLAY "様> Extended memory block move"

	 call	 QRY_XMB	; Query amount of free extended memory
	 SETMSG  "No free extended memory",XMS
	 MJ c	 CHECK_MOV_ERR	; Jump if no free extended memory

	 mov	 XMBSIZE,ax	; Save for later use

; Allocate some memory

	 call	 ALLOC_XMB	; Allocate 'em
	 MJ c	 CHECK_MOV_ERR	; No so fast

; De-allocate every other handle

	 call	 ALTDEALLOC_XMB ; De-allocate 'em
	 MJ c	 CHECK_MOV_ERR	; No so fast

; Allocate all of the rest of memory to two handles

	 call	 SPLIT_MEM	; Split it up
	 MJ c	 CHECK_MOV_ERR	; Jump if something went wrong

; Calculate length as smaller of HNDL1_LEN, HNDL2_LEN, and 64

	 mov	 ax,HNDL1_LEN	; Get length of handle #1

	 cmp	 ax,HNDL2_LEN	; Check against handle #2 length
	 jbe	 short @F	; Jump if handle #1 length is smaller

	 mov	 ax,HNDL2_LEN	; Get handle #2 length
@@:
	 cmp	 ax,64		; Check against 64KB
	 jbe	 short @F	; Jump if handle length is smaller

	 mov	 ax,64		; Use 64KB as length
@@:
	 mov	 MOVE_LEN,ax	; Save as move length

; Fill all other handles with known values

;;;;;;;; DISPLAY "   Filling all other XMBs"
;;;;;;;; call	 FILL_XMB	; Fill 'em up
;;;;;;;; MJ c	 CHECK_MOV_ERR	; Jump if something went wrong

; Allocate conventional memory for move of XMB copy of system ROM

	 DISPLAY "   Allocating 1st block of conventional memory"
	 mov	 bx,MOVE_LEN	; Get length of move in KB
	 shl	 bx,10-4	; Convert from KB to paras
	 DOSCALL @GETMEM
	 SETMSG  "Unable to allocate 1st block of conventional memory"
	 MJ c	 CHECK_MOV_ERR	; Bad luck

	 mov	 LCLROM1,ax	; Save for later use

	 DISPLAY "   Allocating 2nd block of conventional memory"
	 mov	 bx,MOVE_LEN	; Get length of move in KB
	 shl	 bx,10-4	; Convert from KB to paras
	 DOSCALL @GETMEM
	 SETMSG  "Unable to allocate 2nd block of conventional memory"
	 MJ c	 CHECK_MOV_ERR	; Bad luck

	 mov	 LCLROM2,ax	; Save for later use

; Copy system ROM to LCLROM1

	 DISPLAY "   Copying system ROM to LCLROM1"
	 REGSAVE <ds,es>	; Save registers

	 mov	 es,LCLROM1	; Destin is LCLROM1 segment
	 assume  es:nothing	; Tell the assembler about it
	 xor	 di,di		; ES:DI ==> LCLROM1 segment

	 mov	 ax,0F000h	; Source is system ROM
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it
	 xor	 si,si		; DS:SI ==> system ROM

	 mov	 cx,MOVE_LEN	; Get length of move in KB
	 shl	 cx,10-1	; Convert from KB to words
     rep movsw			; Copy system ROM and LCLROM1

	 REGREST <es,ds>	; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

; Move LCLROM1 to top of handle #1

	 mov	 ax,MOVE_LEN	; Get length of move in KB
	 mov	 dx,ax		; Copy to shift
	 shl	 ax,10-0	; Convert from KB to bytes
	 shr	 dx,16-(10-0)	; Convert from KB to bytes
	 mov	 EXTMOVE.EXTMOVE_LEN.ELO,ax ; Save as move length
	 mov	 EXTMOVE.EXTMOVE_LEN.EHI,dx

	 mov	 ax,HNDL1	; Get handle #1
	 mov	 EXTMOVE.EXTMOVE_DHNDL,ax ; Save as destin handle

; Set destin offset as end-MOVE_LEN of block #1

	 SETLEN  1,D,MOVE_LEN,0,0 ; #1, destin, subtract MOVE_LEN KB, 0 bytes,
				; add 0 bytes

	 mov	 EXTMOVE.EXTMOVE_SHNDL,0 ; Mark as conventional memory source
	 mov	 ax,LCLROM1	; Get segment of local ROM #1
	 mov	 EXTMOVE.EXTMOVE_SOFF.VOFF,0 ; Source is LCLROM1:0000
	 mov	 EXTMOVE.EXTMOVE_SOFF.VSEG,ax

	 DISPLAY "   Moving LCLROM1 to Handle #1"
	 lea	 si,EXTMOVE	; DS:SI ==> EXTMOVE structure
	 mov	 ah,@XMS_MOVXMB ; Function to move XMBs
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to move LCLROM1 to Handle #1",XMS
	 MJ ne	 CHECK_MOV_ERR	; No luck today

; Move within handle #1 downwards by 1KB to offset zero

	 mov	 cx,HNDL1_LEN	; Get length of handle #1 in KB
	 sub	 cx,MOVE_LEN	; Less length of the move
	 jbe	 CHECK_MOV2	; Jump if no more room in handle #1

	 DISPLAY "様> Moving Handle #1 down from top to bottom"

	 mov	 ax,EXTMOVE.EXTMOVE_DHNDL ; Get destination handle
	 mov	 EXTMOVE.EXTMOVE_SHNDL,ax ; Save as source handle
CHECK_MOV1_NEXT:

; Save old destin as new source offset

	 mov	 ax,EXTMOVE.EXTMOVE_DOFF.ELO
	 mov	 EXTMOVE.EXTMOVE_SOFF.ELO,ax

	 mov	 ax,EXTMOVE.EXTMOVE_DOFF.EHI
	 mov	 EXTMOVE.EXTMOVE_SOFF.EHI,ax

; Move destin offset down by 1KB

	 sub	 EXTMOVE.EXTMOVE_DOFF.ELO,1024 ; Less 1KB
	 sbb	 EXTMOVE.EXTMOVE_DOFF.EHI,0

	 DISPLAY "   Moving Handle #1 down by 1KB"
	 lea	 si,EXTMOVE	; DS:SI ==> EXTMOVE structure
	 mov	 ah,@XMS_MOVXMB ; Function to move XMBs
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to move handle #1 down by 1KB",XMS
	 MJ ne	 CHECK_MOV_ERR	; No luck today

	 loop	 CHECK_MOV1_NEXT ; Jump if more room in handle #1 memory
CHECK_MOV2:

; Move handle #1 to top of handle #2

; Save old destin as new source offset

	 mov	 ax,EXTMOVE.EXTMOVE_DOFF.ELO
	 mov	 EXTMOVE.EXTMOVE_SOFF.ELO,ax

	 mov	 ax,EXTMOVE.EXTMOVE_DOFF.EHI
	 mov	 EXTMOVE.EXTMOVE_SOFF.EHI,ax

	 mov	 ax,HNDL2	; Get handle #2
	 mov	 EXTMOVE.EXTMOVE_DHNDL,ax ; Save as destin handle

; Set destin offset as end-MOVE_LEN of block #2

	 SETLEN  2,D,MOVE_LEN,0,0 ; #2, destin, subtract MOVE_LEN KB, 0 bytes
				; add 0 bytes

	 DISPLAY "様> Moving Handle #1 to top of Handle #2"
	 lea	 si,EXTMOVE	; DS:SI ==> EXTMOVE structure
	 mov	 ah,@XMS_MOVXMB ; Function to move XMBs
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to move handle #1 to top of Handle #2",XMS
	 MJ ne	 CHECK_MOV_ERR	; No luck today

; Move within handle #2 downwards by 1KB to offset zero

	 mov	 cx,HNDL2_LEN	; Get length of handle #2 in KB
	 sub	 cx,MOVE_LEN	; Less length of the move
	 jbe	 CHECK_MOV3	; Jump if no more room in handle #1

	 DISPLAY "様> Moving Handle #2 down from top to bottom"

	 mov	 ax,EXTMOVE.EXTMOVE_DHNDL ; Get destination handle
	 mov	 EXTMOVE.EXTMOVE_SHNDL,ax ; Save as source handle
CHECK_MOV2_NEXT:

; Save old destin as new source offset

	 mov	 ax,EXTMOVE.EXTMOVE_DOFF.ELO
	 mov	 EXTMOVE.EXTMOVE_SOFF.ELO,ax

	 mov	 ax,EXTMOVE.EXTMOVE_DOFF.EHI
	 mov	 EXTMOVE.EXTMOVE_SOFF.EHI,ax

; Move destin offset down by 1KB

	 sub	 EXTMOVE.EXTMOVE_DOFF.ELO,1024 ; Less 1KB
	 sbb	 EXTMOVE.EXTMOVE_DOFF.EHI,0

	 DISPLAY "   Moving Handle #2 down by 1KB"
	 lea	 si,EXTMOVE	; DS:SI ==> EXTMOVE structure
	 mov	 ah,@XMS_MOVXMB ; Function to move XMBs
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to move handle #2 down by 1KB",XMS
	 MJ ne	 CHECK_MOV_ERR	; No luck today

	 loop	 CHECK_MOV2_NEXT ; Jump if more room in handle #1 memory
CHECK_MOV3:

; Move handle #2 to LCLROM2

	 mov	 ax,HNDL2	; Get handle #2
	 mov	 EXTMOVE.EXTMOVE_SHNDL,ax ; Save as source handle
	 mov	 EXTMOVE.EXTMOVE_SOFF.ELO,0 ; Source offset is 0
	 mov	 EXTMOVE.EXTMOVE_SOFF.EHI,0

	 mov	 EXTMOVE.EXTMOVE_DHNDL,0 ; Mark as conventional memory destin
	 mov	 ax,LCLROM2
	 mov	 EXTMOVE.EXTMOVE_DOFF.VOFF,0 ; Destin is LCLROM2:0
	 mov	 EXTMOVE.EXTMOVE_DOFF.VSEG,ax

	 lea	 si,EXTMOVE	; DS:SI ==> EXTMOVE structure
	 DISPLAY "   Moving Handle #2 to LCLROM2"
	 mov	 ah,@XMS_MOVXMB ; Function to move XMBs
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to move Handle #2 to LCLROM2",XMS
	 MJ ne	 CHECK_MOV_ERR	; No luck today

; Compare LCLROM1 and LCLROM2

	 DISPLAY "   Comparing LCLROM1 to LCLROM2"
	 REGSAVE <ds,es>	; Save registers

	 mov	 es,LCLROM2	; Destin is LCLROM2 segment
	 assume  es:nothing	; Tell the assembler about it
	 xor	 di,di		; ES:DI ==> LCLROM2 segment

	 mov	 ds,LCLROM1	; Source is LCLROM1 segment
	 assume  ds:nothing	; Tell the assembler about it
	 xor	 si,si		; DS:SI ==> system ROM

	 mov	 cx,MOVE_LEN	; Get length of move in KB
	 shl	 cx,10-1	; Convert from KB to words
    repe cmpsw			; Compare LCLROM1 and LCLROM2

	 REGREST <es,ds>	; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it
	 SETMSG  "Mis-match on LCLROM1 to LCLROM2 compare"
	 MJ ne	 CHECK_MOV_ERR	; Jump if mis-match

;;;;;;;; DISPLAY "   Checking all other XMBs"
;;;;;;;; call	 CHECK_FILL	; Check 'em
;;;;;;;; jc	 short CHECK_MOV_ERR ; Jump if something went wrong

; De-allocate the handle #1 and #2

	 call	 REL_HNDL12	; Release handles 1 and 2
	 jc	 short CHECK_MOV_ERR ; Jump if something went wrong

; De-allocate the rest of the handles

	 call	 DEALLOC_XMB	; De-allocate 'em
	 jc	 short CHECK_MOV_ERR ; No so fast

; Ensure we have the same amount of free extended memory

	 call	 QRY_XMB	; Query amount of free extended memory
	 SETMSG  "No free extended memory",XMS
	 jc	 short CHECK_MOV_ERR ; No luck today

	 cmp	 ax,XMBSIZE	; Same as at the start?
	 SETMSG  "Free extended memory not same as at start"
	 jne	 short CHECK_MOV_ERR ; No luck today

	 clc			; Indicate all went well

	 jmp	 short CHECK_MOV_EXIT ; Join common exit code

CHECK_MOV_ERR:
	 stc			; Indicate we had a problem
CHECK_MOV_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_MOV endp			; End CHECK_MOV procedure
	 NPPROC  QRY_XMB -- Query Free Extended Memory
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Query the amonut of free extended memory.

On exit:

AX	 =	 size of largest free block in KB
DX	 =	 total amount of free extended memory in KB

|

	 DISPLAY "   Requesting XMB free size"
	 mov	 ah,XMS_QRYXMB	; Function to query XMB size
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check return code
				; CF = 0 if some memory is available,
				; CF = 1 if no memory available, BL = error code

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

QRY_XMB  endp			; End QRY_XMB procedure
	 NPPROC  ALLOC_XMB -- Allocate XMBs
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Allocate XMBs

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers

	 DISPLAY "様> Allocating XMBs"

	 mov	 cx,XMSHNDL	; # handles to allocate
	 lea	 di,XMBHNDL	; ES:DI ==> handle save area
ALLOC_XMB_NEXT:
	 DISPLAY "   Allocating 1 KB of extended memory"

	 mov	 dx,1		; Allocate 1KB
	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to allocate 1 KB of extended memory",XMS
	 jne	 short ALLOC_XMB_ERR ; No luck today

	 mov	 ax,dx		; Copy the handle
	 stosw			; Save in handle table

	 loop	 ALLOC_XMB_NEXT ; Jump if more to allocate

	 clc			; Indicate all went well

	 jmp	 short ALLOC_XMB_EXIT ; Join common exit code

ALLOC_XMB_ERR:
	 stc			; Indicate we had a problem
ALLOC_XMB_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ALLOC_XMB endp			; End ALLOC_XMB procedure
	 NPPROC  ALTDEALLOC_XMB -- De-allocate Every Other Handle
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

De-allocate every other handle from XMBHNDL.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers

	 mov	 cx,XMSHNDL	; # handles to de-allocate
	 shr	 cx,1		; De-allocate every other one
	 lea	 si,XMBHNDL	; DS:SI ==> handle save area
ALTDEALLOC_XMB_NEXT1:
	 lodsw			; Get the next handle

	 and	 ax,ax		; Check for already de-allocated
	 jz	 short ALTDEALLOC_XMB_LOOP1 ; Jump if so

	 mov	 dx,ax		; Copy to handle register

	 DISPLAY "   De-allocating 1 KB of extended memory"

	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to de-allocate 1 KB of extended memory",XMS
	 jne	 short ALTDEALLOC_XMB_ERR ; No luck today

	 mov	 ds:[si-2].ELO,0 ; Mark the handle as available
ALTDEALLOC_XMB_LOOP1:
	 add	 si,2		; Discard the next handle

	 loop	 ALTDEALLOC_XMB_NEXT1 ; Jump if more to de-allocate

	 clc			; Indicate all went well

	 jmp	 short ALTDEALLOC_XMB_EXIT ; Join common exit code

ALTDEALLOC_XMB_ERR:
	 stc			; Indicate something went wrong
ALTDEALLOC_XMB_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ALTDEALLOC_XMB endp		; End ALTDEALLOC_XMB procedure
	 NPPROC  DEALLOC_XMB -- De-allocate XMBs
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

De-allocate XMBs

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers

	 DISPLAY "様> De-allocating XMBs"

	 mov	 cx,XMSHNDL	; # handles to de-allocate
	 lea	 si,XMBHNDL	; DS:SI ==> handle save area
DEALLOC_XMB_NEXT:
	 lodsw			; Get the next handle

	 and	 ax,ax		; Check for already de-allocated
	 jz	 short DEALLOC_XMB_LOOP ; Jump if so

	 mov	 dx,ax		; Copy to handle register

	 DISPLAY "   De-allocating 1 KB of extended memory"

	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to de-allocate 1 KB of extended memory",XMS
	 jne	 short DEALLOC_XMB_ERR ; No luck today
DEALLOC_XMB_LOOP:
	 loop	 DEALLOC_XMB_NEXT ; Jump if more to de-allocate

	 clc			; Indicate all went well

	 jmp	 short DEALLOC_XMB_EXIT ; Join common exit code

DEALLOC_XMB_ERR:
	 stc			; Indicate we had a problem
DEALLOC_XMB_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DEALLOC_XMB endp		; End DEALLOC_XMB procedure
	 NPPROC  SPLIT_MEM - Split Memory In Half
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Split memory into two pieces

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,dx>	; Save registers

	 call	 QRY_XMB	; Query amount of free extended memory
	 SETMSG  "No extended memory for Move Block Tests",XMS
	 MJ c	 SPLIT_MEM_ERR	; Bad luck

	 shr	 ax,1		; Split in two
	 mov	 HNDL1_LEN,ax	; Save for later use

	 cmp	 ax,128 	; Ensure it's big enough for our tests
	 SETMSG  "Insufficient memory for Move Block Tests"
	 jb	 short SPLIT_MEM_ERR ; Bad luck

	 mov	 dx,ax		; Copy to allocate register

; Allocate half of it

	 DISPLAY "   Allocating 1st half of free size"

	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to allocate 1st half of free size",XMS
	 jne	 short SPLIT_MEM_ERR ; No luck today

	 mov	 HNDL1,dx	; Save as handle #1

	 call	 QRY_XMB	; Query amount of free extended memory
	 SETMSG  "No extended memory for Move Block Tests",XMS
	 jc	 short SPLIT_MEM_ERR ; Bad luck

	 mov	 HNDL2_LEN,ax	; Save for later use
	 mov	 dx,ax		; Copy to allocate register

; Allocate the other half of it

	 DISPLAY "   Allocating 2nd half of free size"

	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to allocate 2nd half of free size",XMS
	 jne	 short SPLIT_MEM_ERR ; No luck today

	 mov	 HNDL2,dx	; Save as handle #2

	 clc			; Indicate all went well

	 jmp	 short SPLIT_MEM_EXIT ; Join common exit code

SPLIT_MEM_ERR:
	 stc			; Indicate something went wrong
SPLIT_MEM_EXIT:
	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SPLIT_MEM endp			; End SPLIT_MEM procedure
	 NPPROC  REL_HNDL12 -- Release Handles 1 and 2
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Release handles 1 and 2

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,dx>	; Save registers

	 DISPLAY "   De-allocating handle #1"

	 mov	 dx,HNDL1	; Get handle #1
	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to de-allocate source handle",XMS
	 jne	 short REL_HNDL12_ERR ; No luck today

; De-allocate the destin handle

	 DISPLAY "   De-allocating handle #2"

	 mov	 dx,HNDL2	; Get handle #2
	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to de-allocate destin handle",XMS
	 jne	 short REL_HNDL12_ERR ; No luck today

	 clc			; Indicate all went well

	 jmp	 short REL_HNDL12_EXIT ; Join common exit code

REL_HNDL12_ERR:
	 stc			; Indicate something went wrong
REL_HNDL12_EXIT:
	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REL_HNDL12 endp 		; End REL_HNDL12 procedure

CODE	 ends			; End CODE segment

	 MEND			; End XMS_MOV module
