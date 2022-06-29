;' $Header:   P:/PVCS/MISC/XMSTEST/XMS_XMB.ASV   1.1   06 Aug 1992 13:18:02   HENRY  $

	 title	 XMS_XMB -- XMS XMB Tester
	 page	 58,122
	 name	 XMS_XMB
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

	 extrn	 XMSDRV_VEC:dword
	 extrn	 ERRMSG:word
	 extrn	 ERRCODE:byte
	 extrn	 XMSHNDL:word
	 extrn	 EXTMOVE:tbyte

	 public  HNDLTAB
HNDLTAB  dw	 5 dup (?)	; Save area for handles

	 public  XMBSIZE
XMBSIZE  dw	 ?		; Size of XMB area

	 public  LOWMEM
LOWMEM	 dw	 ?		; Segment of 64KB area

	 public  MSG_XSIZE
MSG_XSIZE db	 '   Extended memory available is    '
MSG_XSIZE1 db	 '_ KB.',CR,LF,EOS

DATA	 ends			; End DATA segment


TEXT	 segment byte public 'data' ; Start TEXT segment
TEXT	 ends			; End TEXT segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 ALLOC_XMB:near
	 extrn	 DEALLOC_XMB:near
	 extrn	 QRY_XMB:near

	 NPPROC  CHECK_XMB -- Check Extended Memory Blocks
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check extended memory block size, allocate, and de-allocate.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers

	 DISPLAY "ออ> Checking Extended Memory Block Size, Allocate, and De-allocate..."

	 call	 QRY_XMB	; Query amount of free extended memory

	 cmp	 ax,0		; Check return code
	 SETMSG  "No free extended memory",XMS
	MJ e	 CHECK_XMB_ERR	; No luck today

	 mov	 XMBSIZE,ax	; Save for later use

	 lea	 di,MSG_XSIZE1	; ES:DI ==> output save area
	 call	 BIN2DEC	; Convert AX to decimal ending at ES:DI

	 DOSCALL @STROUT,MSG_XSIZE ; Display the message

; Allocate one XMB so we can get handle information

	 mov	 dx,1		; Allocate 1KB
	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to allocate 1 KB of extended memory",XMS
	MJ ne	 CHECK_XMB_ERR	; No luck today

; Request # free handles

	 push	 dx		; Save handle #
	 mov	 ah,@XMS_GETINF ; Code to get handle information
	 call	 XMSDRV_VEC	; Request XMS service
	 pop	 dx		; Restore

	 xor	 bh,bh		; Zero to use as word
	 inc	 bx		; Count in the current handle

; Use smaller of that and size of extended memory in KB

	 cmp	 bx,XMBSIZE	; Check against size of free extended memory
	 jbe	 short @F	; Jump if # handles is smaller

	 mov	 bx,XMBSIZE	; Use size of free extended memory
@@:
	 mov	 XMSHNDL,bx	; Save # free handles

; De-allocate the handle

	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to de-allocate 1 KB of extended memory",XMS
	MJ ne	 CHECK_XMB_ERR	; No luck today

; Allocate XMBs

	 call	 ALLOC_XMB	; Allocate 'em
	MJ c	 CHECK_XMB_ERR	; No luck today

; De-allocate the memory from bottom to top

	 call	 DEALLOC_XMB	; De-allocate 'em
	MJ c	 CHECK_XMB_ERR	; No luck today

; Ensure we have the same amount of free extended memory

	 call	 QRY_XMB	; Query amount of free extended memory

	 cmp	 ax,0		; Check return code
	 SETMSG  "No free extended memory",XMS
	MJ e	 CHECK_XMB_ERR	; No luck today

	 cmp	 ax,XMBSIZE	; Same as at the start?
	 SETMSG  "Free extended memory not same as at start"
	MJ ne	 CHECK_XMB_ERR	; No luck today

; Allocate several handles checking non-overlap

	 DISPLAY "   Checking for overlap"

	 mov	 dx,64		; Allocate 64KB
	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to allocate 1st 64 KB of extended memory",XMS
	MJ ne	 CHECK_XMB_ERR	; No luck today

	 mov	 HNDLTAB[0],dx	; Save the handle

	 mov	 dx,64		; Allocate 64KB
	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to allocate 2nd 64 KB of extended memory",XMS
	MJ ne	 CHECK_XMB_ERR	; No luck today

	 mov	 HNDLTAB[2],dx	; Save the handle

	 mov	 dx,64		; Allocate 64KB
	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to allocate 3rd 64 KB of extended memory",XMS
	MJ ne	 CHECK_XMB_ERR	; No luck today

	 mov	 HNDLTAB[4],dx	; Save the handle

	 DISPLAY "   De-allocating 1st handle"

	 mov	 dx,HNDLTAB[0]	; Get the handle #
	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to de-allocate 1st handle",XMS
	MJ ne	 CHECK_XMB_ERR	; No luck today
	 mov	 HNDLTAB[0],-1	; Mark as unallocated

	 mov	 dx,64		; Allocate 64KB
	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to allocate 4th 64 KB of extended memory",XMS
	MJ ne	 CHECK_XMB_ERR	; No luck today

	 mov	 HNDLTAB[6],dx	; Save the handle

	 mov	 dx,64		; Allocate 64KB
	 mov	 ah,@XMS_GETXMB ; Function to allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to allocate 5th 64 KB of extended memory",XMS
	MJ ne	 CHECK_XMB_ERR	; No luck today

	 mov	 HNDLTAB[8],dx	; Save the handle

; Allocate 64KB for XMS move

	 mov	 bx,1000h	; # paras to allocate
	 DOSCALL @GETMEM	; Allocate memory
	 SETMSG  "Unable to allocate conventional memory"
	MJ c	 CHECK_XMB_ERR	; Jump if not enough room

	 mov	 LOWMEM,ax	; Save address

; Fill each handle with a known value

	 mov	 dx,HNDLTAB[2]	; Get 2nd handle
	 mov	 ax,'01'        ; Get fill value
	 DISPLAY "   Filling Handle #2 with known values"
	 call	 FILL_HNDL	; Fill the handle with values
	 SETMSG  "Unable to fill handle #2 with known values",XMS
	MJ c	 CHECK_XMB_ERR	; Jump if error

	 mov	 dx,HNDLTAB[4]	; Get 3rd handle
	 mov	 ax,'23'        ; Get fill value
	 DISPLAY "   Filling Handle #3 with known values"
	 call	 FILL_HNDL	; Fill the handle with values
	 SETMSG  "Unable to fill handle #3 with known values",XMS
	MJ c	 CHECK_XMB_ERR	; Jump if error

	 mov	 dx,HNDLTAB[6]	; Get 4th handle
	 mov	 ax,'45'        ; Get fill value
	 DISPLAY "   Filling Handle #4 with known values"
	 call	 FILL_HNDL	; Fill the handle with values
	 SETMSG  "Unable to fill handle #4 with known values",XMS
	MJ c	 CHECK_XMB_ERR	; Jump if error

	 mov	 dx,HNDLTAB[8]	; Get 5th handle
	 mov	 ax,'67'        ; Get fill value
	 DISPLAY "   Filling Handle #5 with known values"
	 call	 FILL_HNDL	; Fill the handle with values
	 SETMSG  "Unable to fill handle #5 with known values",XMS
	MJ c	 CHECK_XMB_ERR	; Jump if error

; Check for known values

	 mov	 dx,HNDLTAB[2]	; Get 2nd handle
	 mov	 ax,'01'        ; Get fill value
	 call	 CHECK_HNDL	; Check the handle for values
	 SETMSG  "Mis-match checking handle #2",XMS
	MJ c	 CHECK_XMB_ERR	; Jump if error

	 mov	 dx,HNDLTAB[4]	; Get 3rd handle
	 mov	 ax,'23'        ; Get fill value
	 call	 CHECK_HNDL	; Check the handle for values
	 SETMSG  "Mis-match checking handle #3",XMS
	MJ c	 CHECK_XMB_ERR	; Jump if error

	 mov	 dx,HNDLTAB[6]	; Get 4th handle
	 mov	 ax,'45'        ; Get fill value
	 call	 CHECK_HNDL	; Check the handle for values
	 SETMSG  "Mis-match checking handle #4",XMS
	MJ c	 CHECK_XMB_ERR	; Jump if error

	 mov	 dx,HNDLTAB[8]	; Get 5th handle
	 mov	 ax,'67'        ; Get fill value
	 call	 CHECK_HNDL	; Check the handle for values
	 SETMSG  "Mis-match checking handle #5",XMS
	MJ c	 CHECK_XMB_ERR	; Jump if error

; De-allocate the handles

	 DISPLAY "   De-allocating 2nd handle"

	 mov	 dx,HNDLTAB[2]	; Get the handle #
	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to de-allocate 2nd handle",XMS
	MJ ne	 CHECK_XMB_ERR	; Jump if error
	 mov	 HNDLTAB[2],-1	; Mark as unallocated

	 DISPLAY "   De-allocating 3rd handle"

	 mov	 dx,HNDLTAB[4]	; Get the handle #
	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to de-allocate 3rd handle",XMS
	 jne	 short CHECK_XMB_ERR ; No luck today
	 mov	 HNDLTAB[4],-1	; Mark as unallocated

	 DISPLAY "   De-allocating 4th handle"

	 mov	 dx,HNDLTAB[6]	; Get the handle #
	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to de-allocate 4th handle",XMS
	 jne	 short CHECK_XMB_ERR ; No luck today
	 mov	 HNDLTAB[6],-1	; Mark as unallocated

	 DISPLAY "   De-allocating 5th handle"

	 mov	 dx,HNDLTAB[8]	; Get the handle #
	 mov	 ah,@XMS_RELXMB ; Function to de-allocate an XMB
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to de-allocate 5th handle",XMS
	 jne	 short CHECK_XMB_ERR ; No luck today
	 mov	 HNDLTAB[8],-1	; Mark as unallocated

	 clc			; Indicate all went well

	 jmp	 short CHECK_XMB_EXIT ; Join common exit code

CHECK_XMB_ERR:
	 stc			; Indicate we had a problem
CHECK_XMB_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_XMB endp			; End CHECK_XMB procedure
	 NPPROC  FILL_HNDL -- Fill Handle With Known Values
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Fill a handle with known values.

On entry:

DX	 =	 handle #
AX	 =	 fill value

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

; Fill the segment with known values

	 mov	 es,LOWMEM	; Get segment of XMS move area
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> start of segment
	 mov	 cx,64*(1024/2) ; # words in 64KB
     rep stosw			; Fill with known values

; Move the data to the XMB

	 mov	 EXTMOVE.EXTMOVE_LEN.ELO,0    ; Length is 64KB
	 mov	 EXTMOVE.EXTMOVE_LEN.EHI,1
	 mov	 EXTMOVE.EXTMOVE_SHNDL,0      ; Source handle is CNV
	 mov	 EXTMOVE.EXTMOVE_SOFF.VSEG,es ; ...    offset is ES:0
	 mov	 EXTMOVE.EXTMOVE_SOFF.VOFF,0
	 mov	 EXTMOVE.EXTMOVE_DHNDL,dx     ; Destin handle is XMS
	 mov	 EXTMOVE.EXTMOVE_DOFF.ELO,0   ; ...    offset is 0
	 mov	 EXTMOVE.EXTMOVE_DOFF.EHI,0

	 lea	 si,EXTMOVE	; DS:SI ==> EXTMOVE structure
	 mov	 ah,@XMS_MOVXMB ; Function to move XMBs
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 jne	 short FILL_HNDL_ERR ; No luck today

	 clc			; Indicate all went well

	 jmp	 short FILL_HNDL_EXIT ; Join common exit code

FILL_HNDL_ERR:
	 stc			; Indicate something went wrong
FILL_HNDL_EXIT:
	 REGREST <es,di,si,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FILL_HNDL endp			; End FILL_HNDL procedure
	 NPPROC  CHECK_HNDL -- Check Handle for Known Values
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check handle for known values

On entry:

DX	 =	 handle #
AX	 =	 fill value

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

; Fill the segment with known values from XMB

	 mov	 es,LOWMEM	; Get segment of XMS move area
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,ax		; Copy fill value

; Move the data from the XMB

	 mov	 EXTMOVE.EXTMOVE_LEN.ELO,0    ; Length is 64KB
	 mov	 EXTMOVE.EXTMOVE_LEN.EHI,1
	 mov	 EXTMOVE.EXTMOVE_DHNDL,0      ; Destin handle is CNV
	 mov	 EXTMOVE.EXTMOVE_DOFF.VSEG,es ; ...    offset is ES:0
	 mov	 EXTMOVE.EXTMOVE_DOFF.VOFF,0
	 mov	 EXTMOVE.EXTMOVE_SHNDL,dx     ; Source handle is XMS
	 mov	 EXTMOVE.EXTMOVE_SOFF.ELO,0   ; ...    offset is 0
	 mov	 EXTMOVE.EXTMOVE_SOFF.EHI,0

	 DISPLAY "   Reading known values from EMB"
	 lea	 si,EXTMOVE	; DS:SI ==> EXTMOVE structure
	 mov	 ah,@XMS_MOVXMB ; Function to move XMBs
	 call	 XMSDRV_VEC	; Request XMS service

	 cmp	 ax,1		; Check on our success
	 SETMSG  "Unable to move known values from EMB",XMS
	 jne	 short CHECK_HNDL_ERR ; No luck today

; Check for correct values

	 xor	 di,di		; ES:DI ==> values to check
	 mov	 ax,cx		; Restore fill value
	 mov	 cx,64*(1024/2) ; # words in 64KB
    repe scasw			; Search for values
	 jne	 short CHECK_HNDL_ERR ; Jump if mis-match

	 clc			; Indicate all went well

	 jmp	 short CHECK_HNDL_EXIT ; Join common exit code

CHECK_HNDL_ERR:
	 stc			; Indicate something went wrong
CHECK_HNDL_EXIT:
	 REGREST <es,di,si,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_HNDL endp 		; End CHECK_HNDL procedure
	 NPPROC  BIN2DEC -- Binary AX To Decimal at ES:DI & Preceding
	 assume  ds:PGROUP,es:PGROUP,ss:nothing

	 pushf			; Save flags

	 REGSAVE <ax,cx,dx>	; Save registers

	 mov	 cx,10		; Divisor
	 std			; String ops backwards
BIN2DEC_LOOP:
	 xor	 dx,dx		; Zero for divide
	 div	 cx		; Strip off another decimal digit
	 add	 dl,'0'         ; Convert to ASCII (0-9)
	 xchg	 al,dl		; Swap to store
	 stosb
	 xchg	 dl,al		; Swap back again

	 and	 ax,ax		; Check for zero quotient
	 jnz	 short BIN2DEC_LOOP ; Go around again

	 REGREST <dx,cx,ax>	; Restore

	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

BIN2DEC  endp			; End BIN2DEC procedure

CODE	 ends			; End CODE segment

	 MEND			; End XMS_XMB module
