;' $Header:   P:/PVCS/MAX/ASQENG/TESTMEM.ASV   1.1   30 May 1997 14:58:44   BOB  $
	 TITLE	 TESTMEM -- Test the Contents of a Block of Memory
	 page	 58,122
	 name	 TESTMEM

COMMENT|		Module Specifications

Copyright:  Copyright (c) 1990-7 Qualitas, Inc.  All rights reserved.

Segmentation:  Microsoft conventions using .MODEL, .DATA, and .CODE.

Link requirements:  None.

Program derived from:  None.

Modifications by:  Henry Groover, May 1992.

|

;
;	Unusual return values
;
MEM_UNK    equ 0	; Unknown (initial state)
MEM_RAM    equ 1	; RAM memory
MEM_ROM    equ 2	; ROM memory
MEM_EMPTY  equ 3	; Unused (i.e. empty) memory
;
.xlist
	 include MASM.INC
	 include PTR.INC
	 include EMM2CALL.INC

	 include QMAX_RAM.INC
.list

	.MODEL	LARGE,PASCAL
@NO_UNDERBAR	equ	1	; Use underbars on extrns
	 include RAMSCAN.INC
	 include VENDINFO.INC
;;;;;;;.code			; Included in RAMSCAN.INC

.data
	 extrn	 _SUB_FLAG:word ; Local flags - in VENDINFO.ASM
	 extrn	 _PORT67:word	; EMM2CALL value - in RAMSCAN.ASM
PORT67	 equ	 _PORT67

	 public SCANDONE,TESTMEM_MAP
SCANDONE db	0		; 1=TESTMEM_MAP filled in
TESTMEM_MAP db	(384/4) dup (0) ; 1 byte per 4K block
				; values are:
				;	00: Not scanned yet
				;	01: RAM
				;	10: ROM
				;	11: Unknown (set by NOSCAN keyword)

	 public TESTMEM_LASTSEG,TESTMEM_LASTRES
TESTMEM_LASTSEG dw -1		; Last segment tested outside of high DOS
TESTMEM_LASTRES db 0		; Last result of test outside of high DOS

.code

	 NPPROC TESTMEM_SUB -- Check for RAM at BX:0
	 assume ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Check for RAM in the paragraph at BX:0.  _CHECK_RAM is very slow,
since it takes pains to flush the cache controller.  If a call to
_CHECK_RAM is required, we make it and flag the return value in
TESTMEM_MAP.  Otherwise, we map the requested paragraph into the
map of @LCLMEM_LEN byte blocks described by TESTMEM_MAP.

If the scan is requested in low DOS, we check to see if it's covered
by the last test we made outside of A000-10000.

On entry:
BX:0	==>	Paragraph to check for RAM
_MAXPRES has already been called to set _SUB_FLAG.

On exit:
CF	= 1	RAM
	= 0	Not RAM
ES		Destroyed

|

	 REGSAVE <ax,bx,cx,si,di> ; Save

	 cmp	 bx,0A000h	; Izit in high DOS?
	 jnb	 short TMSUB_HIGH ; Jump if so

; Paragraph is in low DOS.  See if it's covered by last low DOS _CHECK_RAM
	 push	 bx		; Save segment value
	 sub	 bx,TESTMEM_LASTSEG ; Get offset from last test
	 cmp	 bx,@LCLMEM_LEN/16 ; Izit within range?
	 pop	 bx		; Restore
	 jb	 short @F	; Jump if in range

	 mov	 TESTMEM_LASTSEG,bx ; Save segment tested
	 call	 _CHECK_RAM	; Return with CF significant
	 mov	 TESTMEM_LASTRES,0 ; Prepare to save CF contents
	 adc	 TESTMEM_LASTRES,0 ; Set to 1 if RAM, otherwise 0

@@:
	 cmp	 TESTMEM_LASTRES,0 ; Clear CF if RAM
	 cmc			; Set CF if RAM
	 jmp	 short TMSUB_EXIT ; Join common exit code

TMSUB_HIGH:
; Paragraph is in high DOS.  Check to see if we've scanned high DOS yet.
	 push	 ds		; Setup ES for RAMSCAN
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 si,bx		; Copy starting para to index register
	 mov	 bx,0A000h	; Get starting para of high DOS
	 sub	 si,bx		; Get paras from start of high DOS
	 mov	 cl,12-4	; Convert paras to 4K blocks
	 shr	 si,cl		; Get index into TESTMEM_MAP[]

	 cmp	 SCANDONE,0	; Have we done the scan yet?
	 jne	 short TMSUB_TEST ; Jump if so

	 mov	 SCANDONE,1	; Mark as done

	 test	 _SUB_FLAG,@SUB_PRES ; Is 386MAX present?
	 jz	 short TMSUB_SCANREAL ; Jump if not

	 test	 _SUB_FLAG,@SUB_VM ; Izit active?
	 jz	 short TMSUB_SCANREAL ; Jump if not

	 lea	 di,DGROUP:TESTMEM_MAP ; ES:DI ==> output save area
	 mov	 ah,@EMM2_RAMSCAN ; Request RAM scan of high DOS memory
	 call	 _EMM2_VXD_Call ; Call through VxD (if necessary)
				; Return with AH = error status

;;;;;;;; cmp	 ah,0A4h	; Check for access denied
;;;;;;;; je	 short RAMSCAN_DENY ; Jump if denied
;;;;;;;;
	 and	 ah,ah		; Check return code
	 jz	 short TMSUB_EXIT ; Join common exit code (note CF=0)

	 jmp	 short TMSUB_TEST ; Test result

TMSUB_SCANREAL:
; BX = A000; scan high DOS and save the results in TESTMEM_MAP

	 cld			; Set forward direction
	 mov	 cx,size TESTMEM_MAP ; Number of 4K blocks to test
	 lea	 di,TESTMEM_MAP ; Address start of map
TMSUB_NEXTREAL:
; Bozo MASM won't assemble this line properly
;;;;;;;  mov	 al,DGROUP:[di].LO ; Get flags for this block
	 mov	 al,es:[di].LO	; Get flags for this block
	 or	 al,al		; Is NOSCAN set?
	 jnz	 short TMSUB_LOOPREAL ; Jump if so

	 call	 _CHECK_RAM	; Return with CF=1 if BX:0 is RAM
	 mov	 al,0		; Assume it's not RAM
	 jnc	 short TMSUB_LOOPREAL ; Jump if not

	 or	 al,mask $RAM_RAM ; Indicate it's RAM
TMSUB_LOOPREAL:
	 stos	 TESTMEM_MAP[di] ; Save in map
	 add	 bx,4096/16	; Skip to next 4K in paras
	 loop	 TMSUB_NEXTREAL ; Go around again

TMSUB_TEST:
;;;;;;;  bt	 TESTMEM_MAP[si],$RAM_RAM ; Set CF if RAM
	 mov	 al,TESTMEM_MAP[si] ; Get flags (see QMAX_RAM.INC)
	 mov	 cl,$RAM_RAM+1	; Move $RAM_RAM into CF
	 shr	 al,cl		; Set CF if RAM

TMSUB_EXIT:
	 REGREST <di,si,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume   ds:nothing,es:nothing,ss:nothing

TESTMEM_SUB endp		; End TESTMEM_SUB procedure

comment|
/*-asm-*/ int pascal far testmem(unsigned short start, unsigned short far *npara);
|
;=======================================================================
;
;	testmem - Test contents of a block of memory
;
;	int pascal far testmem(
;		unsigned short start,	  /* Paragraph to start at */
;		unsigned short far *npara) /* How many paragraphs to test */
;
;	returns:	-1 if ROM detected
;			 0 if nothing detected
;			 1 if RAM detected
;
;	This function identifies the largest contiguous block of memory
; of a given type starting at the specified paragraph.	The npara argument
; is adjusted to indicate the size of the block found.
;
;=======================================================================
;
TESTMEM PROC	start:word, npara:dword

	call	_MAXPRES	; Set variables needed for _CHECK_RAM

	les	bx,npara	; Pick up npara
	mov	cx,word ptr es:[bx]
	mov	bx,start	; Pick up start

;
	push	si		; Preserve caller's registers
	push	di		; Preserve caller's registers
	cld			; Direction = forward
;
	mov	dx,MEM_UNK	; Flag state as unknown
TEST1:
	mov	ax,MEM_RAM	; Assume it's RAM
	call	TESTMEM_SUB	; Return with CF=1 if RAM at BX:0
	jc	short CHK_SAME	; Join common code if RAM

NOT_RAM:
	cmp	dx,MEM_ROM	; Did we already decide it was ROM?
	jnz	TRY_UNUSED	; No...

	mov	ax,dx		; Yes, then don't test for unused
	jmp	CHK_SAME	; Join common code

TRY_UNUSED:
	mov	es,bx		; Set up pointer to memory
	assume	es:nothing	; Tell the assembler

	mov	si,cx		; Save CX across scan
	mov	ax,0FFFFh	; This what we're looking for
	mov	cx,16/2 	; How many words
	sub	di,di		; Start at ES:0
	repz	scasw		; Check for all 0xffff.
	or	cx,cx		; Set up for later test
	mov	cx,si		; Restore CX
	mov	ax,MEM_EMPTY	; Prep for UNUSED
	jz	CHK_SAME	; Join common code if so

	mov	ax,MEM_ROM	; Else, assume it's ROM
CHK_SAME:
	cmp	ax,dx		; Compare this result with previous one
	je	IS_SAME 	; If same as previous

	cmp	dx,MEM_UNK	; First time through?
	jne	DONE		; No, then we're done testing

	mov	dx,ax		; Yes, then we know what we're looking for
IS_SAME:
	inc	bx		; Bump segment

	loop	TEST1		; ..and go around again

DONE:
	pop	di		; Restore caller's registers
	pop	si		; Restore caller's registers
	les	bx,npara
	mov	ax,es:[bx]	; Get original size again
	sub	ax,cx		; Difference is how many we found
	mov	es:[bx],ax

	mov	ax,dx		; Set up return value
	ret			; and return

TESTMEM ENDP
;
	end
