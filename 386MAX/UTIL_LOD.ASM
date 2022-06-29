;' $Header:   P:/PVCS/MAX/386MAX/UTIL_LOD.ASV   1.2   30 May 1997 10:46:24   BOB  $
	 title	 UTIL_LOD -- 386MAX Utility Program -- LOADxx Actions
	 page	 58,122
	 name	 UTIL_LOD

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Tail    segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, April, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include MAC.INC

	 include QMAX_CTL.INC
	 include QMAX_OEM.INC
	 include LOAD_SEG.INC
.list

if @OEM_HILOAD
PGROUP	 group	 CODE,DATA,NCODE,ZZTAIL


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 QMAX_VER:byte
	 extrn	 INFO_CTL:byte
	 include QMAX_HDM.INC

	 extrn	 PSP_ENVIR_PTR:word
	 extrn	 DEVICE_CS:word
	 extrn	 QMAX_HI:word
	 extrn	 CMDCOM_PAR:word
	 extrn	 PORT67:word
	 extrn	 OWNER:word
	 extrn	 MSG_RUNLO:byte
	 extrn	 MSG_RUNHI:byte
	 extrn	 MSG_AVAIL:byte
	 extrn	 MSG_AVAIL1:byte
	 extrn	 MSG_DOT:byte
	 extrn	 P1ST_MAC:dword
	 extrn	 POVR_MAC:word
	 extrn	 OLDDOS:word
	 extrn	 LOWSIZE:word

	 extrn	 MSG_NOROOM:byte
	 extrn	 MSG_NOROOM1:byte
	 extrn	 MSG_NOROOM2:byte
	 extrn	 MSG_NOROOM3:byte
	 extrn	 MSG_NOROOM_LEN:abs

	 extrn	 MSG_NOHIGH:byte
	 extrn	 MSG_NOHIGH_LEN:abs

	 extrn	 MSG_CLOSHI:byte
	 extrn	 MSG_CLOSHI_LEN:abs

	 extrn	 MSG_CLOSHI_OFF:byte
	 extrn	 MSG_OPENHI_ON:byte

	 extrn	 MSG_RELEASE:byte

	 extrn	 MSG_USED:byte
	 extrn	 MSG_USED1:byte
	 extrn	 MSG_USED2:byte

	 extrn	 DOSVER:word

if @OEM_WIN3
	 extrn	 WINRUN:byte
endif				; IF @OEM_WIN3

	 public  CURPSP
CURPSP	 dw	 ?		; Save area for segment of current PSP

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
	 extrn	 CHECK_LINE:near

NCODE	 ends			; End NCODE segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 BIN2BASE:near
	 extrn	 DISPMEM:near
	 extrn	 DISP_ERRMAC:near
	 extrn	 INFO_WRITE:near

	 NPPROC  ACT_LOADHI -- Action to Load Programs in High DOS Memory
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Load programs in high DOS memory.

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,di> ; Save registers

	 test	 CMD_FLAG,@CMD_XHI ; High filling allowed?
	 jz	 short ACT_LOADHI1 ; Yes

	 mov	 cx,MSG_NOHIGH_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOHIGH ; No, tell 'em so
	 call	 CHECK_LINE	; Count in another line and check for pause

	 jmp	 ACT_LOADHI_ERR ; Join common error code

ACT_LOADHI1:

; Is high DOS memory closed off?

	 cmp	 HDM_FLAG,@HDM_CLOS ; Check it
	 jne	 short ACT_LOADHI_OPEN ; Not this time

	 call	 ACT_OPENHI	; Open it up
	 jc	 near ptr ACT_LOADHI_ERR ; Something went wrong

; Did we release low memory last time?

ACT_LOADHI_OPEN:
	 mov	 al,@HDM_OPEN	; Open marker
	 xchg	 al,HDM_FLAG	; Swap it

	 cmp	 al,@HDM_REL	; Check it
	 jne	 short ACT_LOADHI2 ; It's normal

	 lea	 dx,MSG_RELEASE ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 jmp	 ACT_LOADHI_WRITE ; Join common exit code

ACT_LOADHI2:

; Check to see where we are currently loading programs

	 cmp	 OWNER,0	; Are we already loading in high memory?
	 jne	 near ptr ACT_LOADHI_DISP ; Yes, just display the status

	 lea	 dx,MSG_RUNHI	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

; Get and save the segment of the current PSP

	 DOSCALL @GETPS0	; Get PSP of current task into BX

	 mov	 CURPSP,bx	; Save to restore later

; Change the current PSP to that of 386MAX

	 mov	 bx,DEVICE_CS	; Get segment of device driver
	 DOSCALL @SETPSP	; Set PSP of current task to BX

; Allocate all of low memory

	 mov	 bx,-1		; Get largest possible
	 DOSCALL @MODMEM	; We know this will fail
	 DOSCALL @MODMEM	; Use value of BX from previous call
	 jnc	 short ACT_LOADHI_E0 ; Jump if all went well

	 int	 03h		; Call debugger
ACT_LOADHI_E0:

; Now get address of next block in high memory and save in INFO_STR

	 mov	 bx,-1		; Allocate all paragraphs
	 DOSCALL @GETMEM	; We know this will fail
	 DOSCALL @GETMEM	; Return with segment of memory block in AX
	 jnc	 short ACT_LOADHI_E1 ; Jump if all went well

	 int	 03h		; Call debugger
ACT_LOADHI_E1:
	 mov	 QMAX_HI,ax	; Save segment number

	 push	 es		; Save for a moment

	 mov	 es,ax		; Address segment for @RELMEM
	 assume  es:nothing	; Tell the assembler about it

	 DOSCALL @RELMEM	; Release the highmem paragraphs
	 jnc	 short ACT_LOADHI_E2 ; Jump if all went well

	 int	 03h		; Call debugger
ACT_LOADHI_E2:
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 OWNER,cs	; Save as owner of the block

	 lea	 ax,ZTAIL[16-1] ; AX ==> end of our data area
				; Rounded up to paragraph boundary
	 shr	 ax,4		; Convert from bytes to paras
	 add	 ax,1024/16	; Plus 1KB for environment, etc.
	 add	 ax,CMDCOM_PAR	; Add in size of COMMAND.COM in paras

	 cmp	 bx,ax		; Enough room for COMMAND.COM + 386MAX.COM?
	 ja	 short ACT_LOADHI_FMT ; Yes, continue on

	 push	 es		; Save for a moment

	 mov	 es,OWNER	; Get segment of block to release
	 assume  es:nothing	; Tell the assembler about it

	 DOSCALL @RELMEM	; Bye
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it
	 jnc	 short ACT_LOADHI_E3 ; Jump if all went well

	 int	 03h		; Call debugger
ACT_LOADHI_E3:
	 push	 bx		; Save for a moment
	 mov	 bx,CURPSP	; Restore old PSP
	 DOSCALL @SETPSP	; Set PSP of current task to BX
	 pop	 bx		; Restore

	 mov	 OWNER,0	; Zero the owner entry to avoid recursion
	 call	 ACT_CLOSHI	; Close off high memory
;;;;;;;; jc	 ???		; Jump if something went wrong

; Format the size of 386MAX.COM and COMMAND.COM into the error message

	 mov	 ax,bx		; Get size available in paras
	 shr	 ax,10-4	; Convert from paras to 1KB, rounding down
	 lea	 di,MSG_NOROOM1+1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 mov	 ax,CMDCOM_PAR	; Get size of COMMAND.COM in paras
	 add	 ax,(1024/16)-1 ; Round up to 1KB boundary
	 shr	 ax,10-4	; Convert from paras to 1KB
	 lea	 di,MSG_NOROOM2+1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 lea	 ax,ZTAIL[16-1] ; AX ==> end of our data area in bytes
				; Rounded up to paragraph boundary
	 add	 ax,1024	; Plus 1KB for environment, etc.
	 add	 ax,1024-1	; Round up to 1KB boundary
	 shr	 ax,10-0	; Convert from bytes to 1KB
	 lea	 di,MSG_NOROOM3+1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 mov	 cx,MSG_NOROOM_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOROOM ; Tell 'em there's no room
	 call	 CHECK_LINE	; Count in another line and check for pause

	 jmp	 short ACT_LOADHI_ERR ; Join common error code

ACT_LOADHI_FMT:
	 mov	 ax,bx		; Copy size of high memory block
	 add	 ax,1024/16-1	; Round up to 1KB boundary
	 shr	 ax,10-4	; Convert from paras to 1KB

	 lea	 di,MSG_AVAIL1-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 mov	 bx,CURPSP	; Restore old PSP
	 DOSCALL @SETPSP	; Set PSP of current task to BX

	 lea	 dx,MSG_AVAIL	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX
	 lea	 dx,MSG_DOT	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX
ACT_LOADHI_ALG:

; If we're running DOS 3.2 or later, get and save the current
; Memory Allocation Chain Algorithm

;;;;;;;; DOSCALL @DOSVER	; Return AL=major, AH=minor, BX=CX=0
;;;;;;;; xchg	 al,ah		; Swap to comparison order
;;;;;;;;
;;;;;;;; cmp	 ax,0314h	; DOS 3.2 or later?
;;;;;;;; jb	 short ACT_LOADHI_WRITE ; No
;;;;;;;;
;;;;;;;; mov	 al,0		; Function code to get algorithm
;;;;;;;; DOSCALL @MACALG	; Return algorithm # in AL
;;;;;;;;
;;;;;;;; xor	 ah,ah		; Zero to use as word
;;;;;;;; mov	 INFO.INFO_ALG,ax ; Save algorithm #
;;;;;;;;
; Switch to last fit algorithm
;;;;;;;;
;;;;;;;; mov	 al,1		; Function code to set algorithm
;;;;;;;; mov	 bx,2		; Code for last fit
;;;;;;;; DOSCALL @MACALG	; Set algorithm #

; Note that because we're intercepting @MACALG set in the
; resident device driver, it's important to rewrite the INFO
; structure after calling @MACALG set.

ACT_LOADHI_WRITE:
	 call	 INFO_WRITE	; Write out INFO structure

	 clc			; Indicate all went well

	 jmp	 short ACT_LOADHI_EXIT ; Join common exit code

ACT_LOADHI_DISP:
if @OEM_HILOAD
	 call	 DISPMEM	; Display memory allocation status
endif				; IF @OEM_HILOAD

	 clc			; Indicate all went well

	 jmp	 short ACT_LOADHI_EXIT ; Join common exit code

ACT_LOADHI_ERR:
	 stc			; Indicate something went wrong
ACT_LOADHI_EXIT:
	 REGREST <di,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_LOADHI endp 		; End ACT_LOADHI procedure
	 NPPROC  ACT_LOADLO -- Action to Load Programs in Low DOS Memory
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Load programs in low DOS memory.

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,di> ; Save registers

	 test	 CMD_FLAG,@CMD_XHI ; High filling allowed?
	 jz	 short ACT_LOADLO1 ; Yes

	 mov	 cx,MSG_NOHIGH_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOHIGH ; No, tell 'em so
	 call	 CHECK_LINE	; Count in another line and check for pause

	 jmp	 ACT_LOADLO_ERR ; Join common error code

ACT_LOADLO1:

; Is high DOS memory closed off?

;;;;;;;; cmp	 HDM_FLAG,@HDM_CLOS ; Check it
;;;;;;;; jne	 short ACT_LOADLO_OPEN ; Not this time
;;;;;;;;
;;;;;;;; mov	 cx,MSG_CLOSHI_LEN ; CX = # bytes in message
;;;;;;;; mov	 bx,@STD_ERR	; Send to standard error handle
;;;;;;;; DOSCALL @WRITF2,MSG_CLOSHI ; Tell 'em we can't do it
;;;;;;;; call	 CHECK_LINE	; Count in another line and check for pause
;;;;;;;;
;;;;;;;; jmp	 ACT_LOADLO_ERR ; Join common error code


ACT_LOADLO_OPEN:

; If we're running DOS 3.2 or later, restore the current
; Memory Allocation Chain Algorithm

;;;;;;;; DOSCALL @DOSVER	; Return AL=major, AH=minor, BX=CX=0
;;;;;;;; xchg	 al,ah		; Swap to comparison order
;;;;;;;;
;;;;;;;; cmp	 ax,0314h	; DOS 3.2 or later?
;;;;;;;; jb	 short ACT_LOADLO_ALG ; No
;;;;;;;;
; Restore algorithm
;;;;;;;;
;;;;;;;; mov	 al,1		; Function code to set algorithm
;;;;;;;; mov	 bx,INFO.INFO_ALG ; Get algorithm #
;;;;;;;; DOSCALL @MACALG	; Set algorithm #
;;;;;;;;
;;;;;;;; mov	 INFO.INFO_ALG,bx ; Restore in INFO structure
ACT_LOADLO_ALG:

; Did we release low memory last time?

	 mov	 al,@HDM_OPEN	; Open marker
	 xchg	 al,HDM_FLAG	; Swap it

	 cmp	 al,@HDM_REL	; Check it
	 jne	 short ACT_LOADLO2 ; It's normal

	 lea	 dx,MSG_RELEASE ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 jmp	 ACT_LOADLO_WRITE ; Join common exit code

ACT_LOADLO2:

; Check to see where we are currently loading programs

	 cmp	 OWNER,0	; Are we already loading in low memory?
	 jne	 short ACT_LOADLO3 ; No, return to load low

	 cmp	 al,@HDM_CLOS	; Is high memory closed off?
	 jne	 near ptr ACT_LOADLO_CLOSHI ; No, so close it off

; Note that OWNER is already 0.
	 call	 ACT_CLOSHI	; Close off high memory in case it's DOS=UMB
	 jmp	 ACT_LOADLO_DISP ; Yes, just display the status

ACT_LOADLO3:
	 lea	 dx,MSG_RUNLO	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

; Allocate all of high DOS memory to get its size

	 mov	 bx,-1		; Get largest possible
	 DOSCALL @MODMEM	; We know this will fail
	 mov	 ax,bx		; Copy size of remaining block
	 add	 ax,1024/16-1	; Round up to 1KB boundary
	 shr	 ax,10-4	; Convert from paras to 1KB

	 lea	 di,MSG_USED2-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

; We have allocated all of low DOS memory -- de-allocate it

; Get and save the segment of the current PSP

	 DOSCALL @GETPS0	; Get PSP of current task into BX

	 mov	 CURPSP,bx	; Save to restore later

; Change the current PSP to that of 386MAX

	 mov	 bx,DEVICE_CS	; Get segment of device driver
	 DOSCALL @SETPSP	; Set PSP of current task to BX

	 push	 es		; Save for a moment

	 mov	 es,OWNER	; Get segment of block to release
	 assume  es:nothing	; Tell the assembler about it

	 DOSCALL @RELMEM	; Bye
	 jnc	 short ACT_LOADLO_E1 ; Jump if all went well

	 int	 03h		; Call debugger
ACT_LOADLO_E1:

; If the previous owner's environment block is contiguous with
; its program block, merge the two by allocating all of memory

	 mov	 bx,-1		; Allocate all paragraphs
	 DOSCALL @GETMEM	; We know this will fail
;;;;;;;; DOSCALL @GETMEM	; Return with segment of memory block in AX
;;;;;;;; jnc	 short ACT_LOADLO_E2 ; Jump if all went well
;;;;;;;;
;;;;;;;; int	 03h		; Call debugger
ACT_LOADLO_E2:
;;;;;;;; mov	 es,ax		; Copy to release register
;;;;;;;; DOSCALL @RELMEM	; Bye
;;;;;;;; jnc	 short ACT_LOADLO_E3 ; Jump if all went well
;;;;;;;;
;;;;;;;; int	 03h		; Call debugger
ACT_LOADLO_E3:
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 OWNER,0	; Delete current owner
	 mov	 ax,cs		; Copy current segment
	 sub	 ax,QMAX_HI	; Less starting segment to get size in paras

	 add	 ax,1024/16-1	; Round up to 1KB boundary
	 shr	 ax,10-4	; Convert from paras to 1KB

	 lea	 di,MSG_USED1-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 mov	 bx,CURPSP	; Restore old PSP
	 DOSCALL @SETPSP	; Set PSP of current task to BX

	 lea	 dx,MSG_USED	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX
ACT_LOADLO_WRITE:

; Be sure to release our own memory before closing off high memory

; First the environment

	 push	 es		; Save for a moment

	 mov	 es,PSP_ENVIR_PTR ; Get segment of our environment
	 assume  es:nothing	; Tell the assembler about it

	 DOSCALL @RELMEM	; Bye
	 jnc	 short ACT_LOADLO_E4 ; Jump if all went well

	 int	 03h		; Call debugger
ACT_LOADLO_E4:
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

; Next the program

	 DOSCALL @RELMEM	; Bye
	 jnc	 short ACT_LOADLO_E5 ; Jump if all went well

	 int	 03h		; Call debugger
ACT_LOADLO_E5:

; Finally, merge the MAC entries by requesting more memory than is available

	 mov	 bx,-1		; Allocate all paragraphs
	 DOSCALL @GETMEM	; We know this will fail

; Now close off high memory

ACT_LOADLO_CLOSHI:
	 xor	 ax,ax		; A convenient zero
	 xchg	 ax,OWNER	; Zero the owner entry to avoid recursion
	 call	 ACT_CLOSHI	; Close off high memory
	 xchg	 ax,OWNER	; Restore the owner entry
	 jc	 short ACT_LOADLO_ERR ; Something went wrong

	 call	 INFO_WRITE	; Write out INFO structure

	 clc			; Indicate all went well

	 jmp	 short ACT_LOADLO_EXIT ; Join common exit code

ACT_LOADLO_DISP:
if @OEM_HILOAD
	 call	 DISPMEM	; Display memory allocation status
endif				; IF @OEM_HILOAD

	 clc			; Indicate all went well

	 jmp	 short ACT_LOADLO_EXIT ; Join common exit code

ACT_LOADLO_ERR:
	 stc			; Indicate something went wrong
ACT_LOADLO_EXIT:
	 REGREST <di,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_LOADLO endp 		; End ACT_LOADLO procedure
	 NPPROC  ACT_CLOSHI -- Close Off High Memory Load
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Close off loading programs in high DOS memory.

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,es>	; Save registers

	 cmp	 DOSVER,0500h	; Izit DOS 5 or higher?
	 jb	 short ACT_CLOSHIXDOS5 ; Jump if not

; Give MAX in high DOS a chance to close it (unless NO58 is in effect)
	 mov	 ax,(@MACALG shl 8) or 03h ; Set arena link status
	 sub	 bx,bx		; Unlink arenas
	 DOSCALL		; Ignore error return

ACT_CLOSHIXDOS5:
	 test	 CMD_FLAG,@CMD_XHI ; High filling allowed?
	 jz	 short ACT_CLOSHI1 ; Yes

	 mov	 cx,MSG_NOHIGH_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOHIGH ; No, tell 'em so
	 call	 CHECK_LINE	; Count in another line and check for pause

	 jmp	 ACT_CLOSHI_ERR ; Join common error code

ACT_CLOSHI1:
	 cmp	 HDM_FLAG,@HDM_CLOS ; Already closed off?
	 je	 short ACT_CLOSHI_CLC ; Yes, nothing to do

; If we're loading program in high DOS memory now, release it

	 cmp	 OWNER,0	; Are we already loading in low memory?
	 je	 short ACT_CLOSHI_LOW ; Yes, continue on

	 call	 ACT_LOADLO	; Restore load low status
ACT_CLOSHI_LOW:
	 mov	 HDM_FLAG,@HDM_CLOS ; Mark it as closed off

; Follow the memory allocation chain to the last entry below the
; video buffers and mark the one before that as the last entry

	 les	 bx,P1ST_MAC	; ES:BX ==> head of MAC
	 assume  es:nothing	; Tell the assembler about it

	 call	 TOPDOS 	; Get top of contiguous DOS memory into AX
	 shl	 ax,10-4	; Convert from 1KB to paras
	 dec	 ax		; Back off to previous entry
	 mov	 dx,ax		; Save for later use

; Point to next MAC entry (if not the last)

ACT_CLOSHI_NEXT:
	 mov	 ax,es		; Copy current segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[bx].MAC_NPAR ; Add in # paragraphs in this entry

; Ensure we are where we think we should be.  The link may already
; have been closed by our 5803 call.

	 cmp	 es:[bx].MAC_TYPE,@MAC_END ; Maybe it's the last entry
	 je	 short @F	; It may be if the 5800 call worked

	 cmp	 es:[bx].MAC_TYPE,@MAC_MID ; Maybe it's a middle entry
	 jne	 short ACT_CLOSHI_ERRMAC ; Not this time

@@:
	 cmp	 ax,dx		; Found it as yet?
	 jae	 short ACT_CLOSHI_FOUND ; Yes

	 xor	 bx,bx		; Offset of zero
	 mov	 es,ax		; Point to next entry
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 ACT_CLOSHI_NEXT ; Go around again

ACT_CLOSHI_FOUND:
	 mov	 es:[bx].MAC_TYPE,@MAC_END ; Mark as the last entry

; Leave the spanning entry in place a la DOS 5
;;;;;;;; If we're told to emulate DOS 5, leave the spanning entry there
;;;;;;;
;;;;;;;  test	 CM2_FLAG,@CM2_DOS5 ; Emulating DOS 5's warts?
;;;;;;;  jnz	 short @F	; Jump if so
;;;;;;;
;;;;;;;  inc	 es:[bx].MAC_NPAR ; Add the MAC entry back into the chain
;;;;;;;@@:
	 call	 INFO_WRITE	; Write out INFO structure
ACT_CLOSHI_CLC:
	 lea	 dx,MSG_CLOSHI_OFF ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 clc			; Indicate all went well

	 jmp	 short ACT_CLOSHI_EXIT ; Join common exit code

ACT_CLOSHI_ERRMAC:
	 call	 DISP_ERRMAC	; Display MAC error message
ACT_CLOSHI_ERR:
	 stc			; Indicate something went wrong
ACT_CLOSHI_EXIT:
	 REGREST <es,cx,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_CLOSHI endp 		; End ACT_CLOSHI procedure
	 NPPROC  ACT_OPENHI -- Open Up High Memory Load
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Open up loading programs in high DOS memory.

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,es> ; Save registers

	 cmp	 DOSVER,0500h	; Izit DOS 5 or higher?
	 jb	 short ACT_OPENHIXDOS5 ; Jump if not

; Give MAX in high DOS a chance to open it (unless NO58 is in effect)
; If DOS=UMB is active, we'll detect that later.
	 mov	 ax,(@MACALG shl 8) or 03h ; Set arena link status
	 mov	 bx,1		; Link arenas
	 DOSCALL		; Ignore error return

ACT_OPENHIXDOS5:
	 test	 CMD_FLAG,@CMD_XHI ; High filling allowed?
	 jz	 short ACT_OPENHI1 ; Yes

	 mov	 cx,MSG_NOHIGH_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOHIGH ; No, tell 'em so
	 call	 CHECK_LINE	; Count in another line and check for pause

	 jmp	 ACT_OPENHI_ERR ; Join common error code

ACT_OPENHI1:
	 cmp	 HDM_FLAG,@HDM_CLOS ; Already opened up?
	 jne	 short ACT_OPENHI_CLC ; Yes, nothing to do

; Follow the memory allocation chain to the last entry below the
; space allocated for a spanning entry and mark that one as a middle entry

	 les	 bx,P1ST_MAC	; ES:BX ==> head of MAC
	 assume  es:nothing	; Tell the assembler about it

	 call	 TOPDOS 	; Get top of contiguous DOS memory into AX
	 shl	 ax,10-4	; Convert from 1KB to paras
	 dec	 ax		; Back off to spanning entry
	 mov	 dx,ax		; Save for later use

; Point to next MAC entry (if not the last)

ACT_OPENHI_NEXT:
	 mov	 ax,es		; Copy current segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[bx].MAC_NPAR ; Add in # paragraphs in this entry

; Ensure we are where we think we should be

	 cmp	 es:[bx].MAC_TYPE,@MAC_END ; Maybe it's the last entry
	 je	 short ACT_OPENHI_LAST1 ; It is, check for validity

	 cmp	 es:[bx].MAC_TYPE,@MAC_MID ; Maybe it's a middle entry
	 jne	 short ACT_OPENHI_ERRMAC ; Not this time

; If arenas were already linked via 5803, or our 5803 call succeeded,
; check for POVR_MAC.
	 cmp	 ax,POVR_MAC	; Have we stumbled into high DOS?
	 jb	 short @F	; Jump if not

	 je	 short ACT_OPENHI_CLC ; Jump if it's ours

; If DOS=UMB is in effect, we might be pointing into high DOS above
; POVR_MAC.  There may be MAC entries preceding the initial DOS high
; segment (MAX and subsegments).
	 cmp	 DOSVER,0500h	; Izit DOS 5 or higher?
	 jae	 short ACT_OPENHI_CLC ; Jump if so

	 jmp	 short ACT_OPENHI_ERRMAC ; Treat it as a MAC error
@@:
	 xor	 bx,bx		; Offset of zero
	 mov	 es,ax		; Point to next entry
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 ACT_OPENHI_NEXT ; Go around again

ACT_OPENHI_LAST1:
	 cmp	 ax,dx		; Found it as yet?
	 jne	 short ACT_OPENHI_ERRMAC ; No, so that's an error
;;;;;;;  je	 short ACT_OPENHI_LAST2 ; Jump if so
;;;;;;;
;;;;;;;; If we're told to emulate DOS 5, the spanning MAC entry
;;;;;;;; might already be present
;;;;;;;
;;;;;;;  test	 CM2_FLAG,@CM2_DOS5 ; Emulating DOS 5's warts?
;;;;;;;  jz	 short ACT_OPENHI_ERRMAC ; No, so that's an error
;;;;;;;
;;;;;;;  dec	 dx		; Decrement expected top para
;;;;;;;
;;;;;;;  cmp	 ax,dx		; Found it as yet?
;;;;;;;  jne	 short ACT_OPENHI_ERRMAC ; No, so that's an error
;;;;;;;
;;;;;;;; At this point, it appears that there is room for the spanning
;;;;;;;; MAC entry, but it might not actually be present.
;;;;;;;
;;;;;;;  jmp	 short ACT_OPENHI_LAST3 ; Join common code
;;;;;;;
;;;;;;;; The end of the load DOS MAC entry chain points to top of DOS
;;;;;;;; at (say) A000.  Make room for the spanning entry
;;;;;;;
;;;;;;;ACT_OPENHI_LAST2:
;;;;;;;  dec	 es:[bx].MAC_NPAR ; Delete the MAC entry from the chain
;;;;;;;  dec	 dx		; Back off to previous para
;;;;;;;ACT_OPENHI_LAST3:

; Mark it as a middle entry

	 mov	 es:[bx].MAC_TYPE,@MAC_MID ; Mark as a middle entry

; Fill in new MAC entry just below video buffers

	 mov	 es,dx		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[0].MAC_TYPE,@MAC_MID ; Mark as a middle entry
	 mov	 es:[0].MAC_OWNR,@MAC_SPAN ; Mark as a spanning entry
	 mov	 ax,POVR_MAC	; Get segment of first MAC entry in high DOS
	 sub	 ax,dx		; Less top of low DOS memory
	 dec	 ax		; Less the MAC entry
	 mov	 es:[0].MAC_NPAR,ax ; Save as # paras in MAC entry

	 mov	 HDM_FLAG,@HDM_OPEN ; Mark it as opened up
	 call	 INFO_WRITE	; Write out INFO structure
ACT_OPENHI_CLC:
	 lea	 dx,MSG_OPENHI_ON ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 clc			; Indicate all went well

	 jmp	 short ACT_OPENHI_EXIT ; Join common exit code

ACT_OPENHI_ERRMAC0:
	 mov	 bx,CURPSP	; Restore old PSP
	 DOSCALL @SETPSP	; Set PSP of current task to BX
ACT_OPENHI_ERRMAC:
	 call	 DISP_ERRMAC	; Display MAC error message
ACT_OPENHI_ERR:
	 stc			; Indicate something went wrong
ACT_OPENHI_EXIT:
	 REGREST <es,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_OPENHI endp 		; End ACT_OPENHI procedure
	 NPPROC  TOPDOS -- Get Top of DOS Memory into AX
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

On exit:

AX	 =	 top of DOS memory in 1KB

|

if @OEM_WIN3
	 cmp	 WINRUN,1	; Are we running under Windows?
	 jne	 short @F	; Jump if not

	 int	 12h		; Return with AX = top of DOS in 1KB

	 jmp	 short TOPDOS_EXIT ; Join common exit code

@@:
endif				; IF @OEM_WIN3
	 mov	 ax,OLDDOS	; Get top of original DOS in paras
	 add	 ax,(1024/16)-1 ; Round up to 1KB in paras
	 shr	 ax,10-4	; Convert from paras to 1KB
	 add	 ax,LOWSIZE	; Plus size of added low memory
TOPDOS_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

TOPDOS	 endp			; End TOPDOS procedure

CODE	 ends			; End CODE segment
endif				; IF @OEM_HILOAD

	 MEND			; End UTIL_LOD module
