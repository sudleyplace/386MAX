;' $Header:   P:/PVCS/MAX/386LOAD/GETSIZE.ASV   1.1   30 May 1997 10:38:04   BOB  $
	 title	 GETSIZE -- Routines used to calculate a program's size
	 page	 58,122
	 name	 GETSIZE

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Program segment DATZ,	para-aligned,  public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NLSEG,	para-aligned,  public, class 'ndata'
	       Program segment NDATA,	dword-aligned, public, class 'ndata'
	       Program segment DTAIL,	para-aligned,  public, class 'zdata'
	       Program segment UCODE,	byte-aligned,  public, class 'ucode'
	       Data    segment UDATA,	dword-aligned, public, class 'udata'
	       Program segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Program derived from:  LOADCOM.ASM

Original code by:  Bob Smith, February 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include EMMCALL.INC
	 include ASCII.INC
	 include IOCTL.INC
	 include KEYCALL.INC
	 include VIDCALL.INC
	 include MAC.INC
	 include PTR.INC
	 include EXE.INC
	 include DIR.INC
	 include BITFLAGS.INC
	 include DEVMAC.INC
	 include OPEN.INC
	 include DEVDRV.INC
	 include OPCODES.INC
	 include EXEC.INC
	 include DOSERR.INC

	 include LOAD_OPT.INC
ifdef @HARPO
	 include HARP_CMD.INC
endif				; ifdef @HARPO

.list

PGROUP	 group	 CODE,DATZ,NCODE,NLSEG,NDATA,DTAIL,UCODE,UDATA,ZZTAIL


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 @GSIZE_PAT1:abs ; Low word of filler pattern
	 extrn	 @GSIZE_PAT2:abs ; High word ...

ifdef @HARPO
	 extrn	 CMD_FLAG:word	; HARPO command line options
else
	 extrn	 OPT_FLAG:word
endif				; ifdef @HARPO

	 public  INT_NPAR
INT_NPAR dw	 0		; # paras in interrupt handlers
				; This value is zero because we allocate
				; it out of low memory, not high

CODE	 ends			; End CODE segment


DATZ	 segment para public 'data' ; Start DATZ segment
	 assume  cs:PGROUP,ds:PGROUP


ifndef @HARPO
	 extrn	 CFGFLAGS:word	; CFGFILE flags
	 extrn	 @CFG_GSIZE:abs ; Forced GETSIZE value
endif				; ifndef @HARPO

	 public  MIN_HOLE
MIN_HOLE dw	 2048/16	; Minimum hole size in paras for @CFG_COMSTK
				; or .COM programs with corruption at stack top

	 public  HSIZE_DELTA,GETSIZE_RDELTA,GETSIZE_IDELTA
HSIZE_DELTA dw	 0		; Paras to add to GETSIZE, since this program
				; wants more memory than it leads us to believe
GETSIZE_RDELTA dw 0		; Similar to HSIZE_DELTA, but only added when
				; program is loaded low for GETSIZE.
GETSIZE_IDELTA dw 0		; Add to low DOS initialization size

DATZ	 ends			; End DATZ segment


NLSEG	 segment para public 'ndata' ; Start NLSEG segment
	 assume  ds:PGROUP

	 extrn	 LSEG:tbyte
	 include LOAD_SEG.INC


NLSEG	 ends			; End NLSEG segment


UDATA	 segment dword public 'udata' ; Start UDATA segment
	 assume  ds:PGROUP

	 public  COMPSIZE
COMPSIZE dd	 ?		; File size for comparison


UDATA	 ends			; End UDATA segment


NDATA	 segment dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

ifndef @HARPO
	 include LOAD_LCL.INC
	 extrn	 LCL_FLAG:word	; Local Flags
else
	 include HARP_LCL.INC
	 extrn	 LCL_FLAG:word	; Local Flags
endif				; ifndef @HARPO

ifndef @HARPO
	 include LOAD_LC2.INC
	 extrn	 LC2_FLAG:word	; Local flags, part 2
endif				; ifndef @HARPO

	 public  FILE_HEAD
FILE_HEAD EXE_STR <>		; File header in case it's an .EXE file

	 public  EXEC_PRGMAC
EXEC_PRGMAC dw	 0		; Segment of program MAC

	 extrn	 EXE_NPAR:word

	 extrn	 EXEC_LOD:word	; Pointer to high DOS memory

ifndef @HARPO
	 extrn	 AZS_SIZELO:byte ; Tell 'em 'We loaded it low' message
endif				; ifndef @HARPO

	 public  TOPFILL
TOPFILL  dw	 09000h 	; Highest para # for fill/search of GETSIZE

	 public  EXEC_PRGNPAR
EXEC_PRGNPAR dw  ?		; Original # paras allocated to program

	 public  STKSIZE
STKSIZE  dd	 0		; Size of stack in bytes (used by TSRLOAD only)

	 public  PRGSIZE,MAXPARA,LENPARA,RESPARA
PRGSIZE  dd	 ?		; Program size at various points
MAXPARA  dw	 ?		; Maximum para # at start of FIND_PAT
LENPARA  dw	 ?		; Length of ...
RESPARA  dw	 ?		; Resident size in paras


NDATA	 ends			; End NDATA segment


DTAIL	 segment para public 'zdata' ; Start DTAIL segment
	 assume  ds:PGROUP

	 extrn	 POVR_MAC:word

DTAIL	 ends			; End DTAIL segment


ZZTAIL	 segment dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

ZZTAIL	 ends			; End ZZTAIL segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

ifndef @HARPO
	 extrn	 DISP_ERRMSG:near ; Display error message
endif				; ifndef @HARPO

	 NPPROC  FIND_REGION -- Find MAC Entry of Region in CX
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Find the MAC entry of the region # in CX

On entry:

CX	 =	 region # (1-9)

On exit:

CF	 =	 0 all went OK
AX:0	 =	 MAC entry

CF	 =	 1 something went wrong
AX	 =	 error code

|

	 REGSAVE <cx,es>	; Save registers

	 mov	 es,POVR_MAC	; Get segment of first MAC in high DOS memory
	 assume  es:nothing	; Tell the assembler about it
FIND_REGION_NEXT:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Check for valid
	 je	 short FIND_REGION_CHK ; It's OK

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Ensure valid
	 jne	 short FIND_REGION_ERRMAC ; It's not, so that's an error
FIND_REGION_CHK:
	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Izit free?
	 jne	 short FIND_REGION_LOOP ; Not this one

	 cmp	 cx,1		; Check for correct region #
	 je	 short FIND_REGION_CLC ; We found it
FIND_REGION_LOOP:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Check for end-of-the-line
	 je	 short FIND_REGION_ERRWSF ; It's all over

	 mov	 ax,es		; Get current MAC segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry

	 cmp	 es:[0].MAC_OWNR,@MAC_SPAN ; Izit a RAM or ROM entry?
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it
	 jne	 short FIND_REGION_NEXT ; Not this time

	 loop	 FIND_REGION_NEXT ; Jump if not current region
FIND_REGION_ERRWSF:
	 mov	 ax,@DOSERR_XMEM ; Mark as insufficient memory

	 jmp	 short FIND_REGION_ERRCOM ; Join common error code

FIND_REGION_ERRMAC:
	 mov	 ax,@DOSERR_XMAC ; Mark as control blocks destroyed
FIND_REGION_ERRCOM:
	 stc			; Indicate something went wrong

	 jmp	 short FIND_REGION_EXIT ; Join common exit code

FIND_REGION_CLC:
	 mov	 ax,es		; Return the segment of the MAC entry

	 clc			; Indicate we found it
FIND_REGION_EXIT:
	 REGREST <es,cx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FIND_REGION endp		; End FIND_REGION procedure
	 NPPROC  GETMEM_REG -- Allocate Memory From Specified Region
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Ensure enough memory is available from a specified region #
This routine doesn't actually allocate the memory, it just
ensures that the specified region is large enough.

On entry:

CX	 =	 region # (1-9)
BX	 =	 # paras to allocate

On exit:

CF	 =	 0 if successful
AX:0	 ==>	 MAC entry

CF	 =	 1 if not successful
AX	 =	 error codes

|

	 REGSAVE <es>		; Save register

	 call	 FIND_REGION	; Find the MAC entry of the region # in CX
	 jc	 short GETMEM_REG_EXIT ; Jump if error, code in AX

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it
GETMEM_REG_NEXT:
	 cmp	 es:[0].MAC_NPAR,bx ; Is there enough room?
	 jnc	 short GETMEM_REG_EXIT ; Yes (note CF=0)
GETMEM_REG_UNAVAIL:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Check for end-of-the-line
	 je	 short GETMEM_REG_ERR ; Yes, so there's no room

	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[0].MAC_OWNR,@MAC_SPAN ; Izit a RAM or ROM entry?
	 je	 short GETMEM_REG_ERR ; Yes, so there's no room

	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Izit free?
	 je	 short GETMEM_REG_NEXT ; Yes, go around again

	 jmp	 short GETMEM_REG_UNAVAIL ; Jump if already allocated

GETMEM_REG_ERR:
	 mov	 ax,@DOSERR_XMEM ; Mark as insufficient memory (note CF=1)

	 stc			; Indicate we failed
GETMEM_REG_EXIT:
	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GETMEM_REG endp 		; End GETMEM_REG procedure
	 NPPROC  FIND_PAT -- Find GETSIZE Pattern in Memory
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Find GETSIZE pattern in memory.

On entry:

CX	 =	 # paras to search
DX	 =	 starting para address of search (backwards)

On exit:

CF	 =	 1 if mismatch
ES:DI	 ==>	 mismatch

CF	 =	 0 otherwise
AX	 =	 # paras in maximum request
CX	 =	 updated (paragraphs remaining)

|

	 sub	 ax,ax		; Value to zero filler pattern with
FIND_PAT_NEXT:
	 REGSAVE <cx,dx>	; Save for a moment

	 UMIN	 cx,<64*(1024 shr (4-0))> ; CX = min (CX, 64KB)

	 mov	 di,cx		; ES:DI ==> ending para
;;;;;;;; shl	 di,4-0 	; Convert from paras to bytes
	 shl	 di,1
	 shl	 di,1
	 shl	 di,1
	 shl	 di,1

	 sub	 dx,cx		; Back off to starting point
	 mov	 es,dx		; Address it
	 assume  es:nothing	; Tell the assembler about it

;;;;;;;; shl	 cx,4-2 	; Convert from paras to dwords
	 shl	 cx,1
	 shl	 cx,1
	 jnz	 short FIND_PAT_NEXT2 ; Jump if something to search

; The mismatch address is ES:DI-4
; Handle case where DI == 0

	 dec	 dx		; Back off to previous segment
	 mov	 es,dx		; Address it
	 assume  es:nothing	; Tell the assembler about it
	 add	 di,16-4	; Skip to previous dword next para
	 inc	 cx		; Set ZF=0

	 jmp	 short FIND_PAT_MIS ; Mark as mis-match (note ZF=0)

FIND_PAT_NEXT2:
	 sub	 di,4		; Back off to previous dword

	 cmp	 es:[di].ELO,@GSIZE_PAT1 ; Check for expected pattern
	 jne	 short FIND_PAT_MIS ; Jump if mismatch (note ZF=0)

	 cmp	 es:[di].EHI,@GSIZE_PAT2 ; Check for expected pattern
	 jne	 short FIND_PAT_MIS ; Jump if mismatch (note ZF=0)

; Since some programs expect uninitialized data to be all 0's, we hide
; our filler pattern as we go.	This is a problem with one of the
; Banyan drivers, and can also cause DOS 5 MEM to lock up in a loop
; with interrupts disabled.
	 mov	 es:[di].ELO,ax ; Clear low word
	 mov	 es:[di].EHI,ax ; Clear high word (ZF unchanged)

	 loop	 FIND_PAT_NEXT2 ; Jump if more dwords to search
				; If we fall through here, ZF=1

FIND_PAT_MIS:
	 REGREST <dx,cx>	; Restore
	 stc			; Assume mismatch
	 jne	 short FIND_PAT_EXIT ; Jump if mismatch

	 sub	 dx,64*(1024 shr (4-0)) ; Less amount searched through

	 sub	 cx,64*(1024 shr (4-0)) ; Less amount searched through
	 ja	 short FIND_PAT_NEXT ; Jump if more to check

; Nothing used beyond LSEG.LSEG_RPARA

	 mov	 ax,LSEG.LSEG_RPARA ; Get resident size in paras including INT block
	 sub	 ax,INT_NPAR	; Less # paras in INT block
	 dec	 ax		; Count out MAC paragraph

	 clc			; Indicate pattern not found
FIND_PAT_EXIT:

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FIND_PAT endp			; End FIND_PAT procedure
	 NPPROC  FIND_MIS -- Find Missing GETSIZE Pattern in Memory
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Find missing GETSIZE pattern in memory

On entry:

AX=1		 search for mismatch
AX=0		 search for match
CX	 =	 # paras to search
DX	 =	 starting para address of search (backwards)

On exit:

CX	 =	 # paras remaining
CF	 =	 0 if pattern found
CF	 =	 1 otherwise
ES:DI	 ==>	 place pattern found

|

	 REGSAVE <ax,dx>	; Save registers

FIND_MIS_NEXTP:
	 mov	 di,16-4	; Start at end of paragraph
	 mov	 es,dx		; Ensure we have something in ES:DI
	 assume  es:nothing	; Tell the assembler

	 jcxz	 FIND_MIS_ERR	; Jump if none remaining

	 dec	 dx		; Back off to previous paragraph
	 mov	 es,dx		; Address segment
	 assume  es:nothing	; Tell the assembler

FIND_MIS_NEXTD:
	 cmp	 es:[di].ELO,@GSIZE_PAT1 ; Check for expected pattern
	 jne	 short @F	; Jump if mismatch

	 cmp	 es:[di].EHI,@GSIZE_PAT2 ; Check for expected pattern
	 jne	 short @F	; Jump if mismatch

; Is a match what we wanted?
	 cmp	 ax,0		; Are we looking for a match?
	 jmp	 short FIND_MIS_LOOP ; Join common code
@@:
; Is a mismatch what we wanted?
	 cmp	 ax,1		; Are we looking for a mismatch?

FIND_MIS_LOOP:
	 jne	 short @F	; Jump if not found

	 dec	 cx		; Subtract one paragraph
	 jmp	 short FIND_MIS_EXIT ; Join common exit (note CF=0)
@@:
	 sub	 di,4		; Back off to previous dword
	 jnc	 short FIND_MIS_NEXTD ; Jump if no underflow

	 loop	 FIND_MIS_NEXTP ; Jump if more paras to search

FIND_MIS_ERR:
	 stc			; Mark as none found, use maximum stack
FIND_MIS_EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FIND_MIS endp			; End FIND_MIS procedure
	 NPPROC  GETSIZE -- Get Initialization Size
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Get the initialization size

On entry:

ES	 =	 EXEC_PRGMAC

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

; Note that we use the larger of the current and original # paras
; allocated to the program in case the program re-allocated up or down.

	 mov	 cx,EXEC_PRGNPAR ; Get original # paras allocated to program
ifndef @HARPO
	 test	 LC2_FLAG,@LC2_ENDLOAD ; Did the program load at the high end?
	 jz	 short @F	; Jump if not

	 mov	 ax,EXE_NPAR	; Get size of load image
	 add	 HSIZE_DELTA,ax ; Add to initialization size delta
	 sub	 cx,ax		; Back off to start search below load image
	 dec	 cx		; Account for MAC entry
@@:
	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jz	 short @F	; Jump if not

; Note that we might try to load high, then retry with GETSIZE if the
; program didn't go resident.  We can therefore update HSIZE_DELTA
; when GETSIZE is in effect without worrying about whether we've already
; done so.
	 mov	 ax,GETSIZE_IDELTA ; Get initialization size delta for GETSIZE
	 add	 HSIZE_DELTA,ax ; Add to regular init size delta
@@:
endif				; IFNDEF @HARPO
	 mov	 ax,es:[0].MAC_NPAR ; Get current # paras in MAC entry

	 UMAX	 ax,cx		; AX = max (AX, CX)

; If GETSIZE is specified, limit our search to no higher than TOPFILL

	 mov	 cx,es		; Copy segment
	 add	 cx,ax		; Add to get para #

; Because the high and low MACs are joined, the current TOPFILL
; is high by one.

	 mov	 bx,TOPFILL	; Get current size
	 dec	 bx		; Simulate extra MAC entry at top

ifdef @HARPO
	 test	 CMD_FLAG,@CMD_GSIZE ; GETSIZE specified?
	 jz	 short @F	; Jump if not
else
	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jz	 short @F	; Jump if not
endif				; ifdef @HARPO

	 UMIN	 cx,bx		; CX = min (CX, TOPFILL-1)
@@:
	 sub	 cx,EXEC_PRGMAC ; Subtract to get # paras
;;;;;;;; jc	 ???		; Ignore error condition ???

	 mov	 di,LSEG.LSEG_RPARA ; Get maximum request including INT block
	 sub	 di,INT_NPAR	; Less # paras in INT block
	 dec	 di		; Count out MAC paragraph

	 sub	 cx,di		; Less maximum request excluding INT block
	 jnc	 short @F	; Jump if within range

	 add	 di,cx		; Back off max req to actual size
	 xor	 cx,cx		; Mark size as zero
@@:
	 mov	 dx,es		; Get program MAC segment
	 inc	 dx		; Count in MAC paragraph
	 add	 dx,di		; Plus maximum request excluding INT block
	 add	 dx,cx		; Get address of next para
	 mov	 MAXPARA,dx	; Save as maximum search address in paras
	 mov	 LENPARA,cx	; ...	  length of ...
	 mov	 RESPARA,di	; ...	  resident size in paras

; Start at DX:0 and search backwards for CX paras

	 call	 FIND_PAT	; Search for pattern
	 assume  es:nothing	; Tell the assembler about it
	MJ nc	 GETSIZE_XPAT	; Jump if pattern not found
				; Return with ES:DI ==> 1st mismatching dword
				; on a dword boundary
				; If jump taken, AX = # paras in maximum request

	 mov	 ax,es		; Copy segment
	 sub	 ax,EXEC_PRGMAC ; Less program MAC segment
	 dec	 ax		; Count out MAC para

; If the point of corruption is due to DOS putting a MAC entry
; just above the resident portion of the program, correct for that.
; In particular, subtract out one para and set the offset to 16-4
; as if the point of corruption was just below the MAC entry.

ifndef @HARPO
	 test	 LCL_FLAG,@LCL_TSR ; Izit TSRLOAD?
	 jz	 short @F	; Jump if not
endif				; ifndef @HARPO

	 cmp	 ax,RESPARA	; Izit the same?
	 jne	 short @F	; Jump if not

	 cmp	 di,16-4	; Izit within one para?
	 ja	 short @F	; Jump if not

	 dec	 ax		; Count out MAC para
	 mov	 di,16-4	; Set offset as if just below MAC entry
@@:
	 add	 ax,HSIZE_DELTA ; Add GETSIZE delta (if specified)
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes
	 add	 ax,di		; Add in offset
	 adc	 dx,0		; In case of overflow
	 add	 ax,4		; Skip over mismatch
	 adc	 dx,0		; In case of overflow
	 mov	 PRGSIZE.ELO,ax ; Save as program size in case we fail
	 mov	 PRGSIZE.EHI,dx

; Handle C-flag programs from the CFG file

ifndef @HARPO
	 test	 LC2_FLAG,@LC2_COMSTK ; Izit one of those?
	 jnz	 short GETSIZE_COMSTK ; Jump if so
endif				; ifndef @HARPO

; Handle .COM files with 64KB stack in TSRLOAD

	 test	 LCL_FLAG,@LCL_EXE ; Izit an .EXE file?
	 jnz	 short GETSIZE_END0 ; Jump if so

	 cmp	 ax,STKSIZE.ELO ; Izit exactly the size of the stack?
	 jne	 short GETSIZE_END0 ; Jump if not

	 cmp	 dx,STKSIZE.EHI ; Check high-order word, too
	 jne	 short GETSIZE_END0 ; Jump if not

ifndef @HARPO
	 test	 LCL_FLAG,@LCL_TSR ; Izit TSRLOAD?
	 jnz	 short GETSIZE_COMSTK ; Jump if so
else
	 jmp	 short GETSIZE_COMSTK ; Join common code
endif				; ifndef @HARPO
GETSIZE_END0:
	 jmp	 GETSIZE_END2	; Join common ending code

GETSIZE_COMSTK:
COMMENT|

 Determine the size of the stack below ES:DI.  We back off by an arbitrary
 amount to eliminate cases where the C flag is specified to catch programs
 like LanMan's LOAD.COM and PeerLogic's PIPES.EXE.  A loader goes at the
 high end of available memory and loads a program at the low end, leaving
 a big hole which we want to squeeze out of our GETSIZE calculations.
 We find and eliminate the first hole larger than 1K.

 (DX,AX) =	 Current program size in bytes

|

	 call	 BYT2PAR	; Convert (DX,AX) in bytes to AX in paras
				; rounding down
	 sub	 ax,RESPARA	; Subtract resident size of program
	 jbe	 short GETSIZE_END0 ; Jump if nothing left or resident size larger

	 mov	 cx,ax		; Maximum paras to search
	 sub	 bx,bx		; Default size of hole
	 sub	 si,si		; Initial largest hole
GETSIZE_NEXTMISS:
	 mov	 dx,cx		; Get # of paras remaining
	 add	 dx,EXEC_PRGMAC ; Get top paragraph for search
	 add	 dx,RESPARA	; Add resident size back in
	 sub	 dx,HSIZE_DELTA ; Take slop back out (if specified)
	 sub	 ax,ax		; Search until we get a match
	 call	 FIND_MIS	; Look for next occurrence of the pattern
	 jc	 short GETSIZE_HOLE ; Jump if none found, use last hole size

; Determine the size of the intact region.  DI<16, so we can afford to ignore
; it.
	 mov	 dx,es		; Paragraph to begin scanning at
	 mov	 bx,dx		; Save starting paragraph for comparison
	 mov	 ax,1		; Search until we get a mismatch
	 call	 FIND_MIS	; ES:DI ==> corruption (if found)
	 jcxz	 @F		; Jump if we went all the way

	MJ c	 GETSIZE_END1	; If we didn't find anything, bail out.
@@:
	 mov	 dx,es		; Paragraph we stopped at
	 sub	 bx,dx		; BX = size of hole in paragraphs + 1
	 UMAX	 si,bx		; Save largest so far in SI
	 mov	 bx,si		; Get largest so far
	 cmp	 bx,MIN_HOLE	; Izit at least 2K in length?
	 jb	 short GETSIZE_NEXTMISS ; Jump if not

GETSIZE_HOLE:
; Subtract size of large hole from the program size we've calculated
	 sub	 bx,(256/16)-1	; If we're cutting down on stack space,
				; make sure there's some extra margin
	 jc	 short GETSIZE_END1 ; Jump if too small

; BX contains size of hole in paragraphs
	 mov	 ax,bx		; Prepare to convert to bytes
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes
	 sub	 PRGSIZE.ELO,ax ; Subtract low word
	 sbb	 PRGSIZE.EHI,dx ; Subtract high word

GETSIZE_END1:
	 mov	 ax,PRGSIZE.ELO ; Get new value
	 mov	 dx,PRGSIZE.EHI ; ...
	 jmp	 short GETSIZE_END2 ; Join common code

GETSIZE_XPAT:
; AX contains program size in paragraphs
	 add	 ax,HSIZE_DELTA ; Add GETSIZE delta (if specified)
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

GETSIZE_END2:
; (DX,AX) contains program size in bytes
	 push	 cs		; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

ifndef @HARPO
	 test	 CFGFLAGS,@CFG_GSIZE ; Use GETSIZE value from .CFG file?
	 jnz	 short @F	; Jump if so
endif				; ifndef @HARPO

; Round up initialization size to a para boundary

	 add	 ax,16-1	; Add in slop
	 adc	 dx,0		; In case of overflow
	 and	 ax,not (16-1)	; Round to boundary

	 mov	 LSEG.LSEG_ISIZE.ELO,ax ; Save as initialization size
	 mov	 LSEG.LSEG_ISIZE.EHI,dx ; ...
@@:
	 mov	 ax,LSEG.LSEG_ISIZE.ELO ; Get initialization size
	 mov	 dx,LSEG.LSEG_ISIZE.EHI ; ...

; Ensure that the file's load size is no larger than its initialization size

	 cmp	 dx,LSEG.LSEG_LSIZE.EHI ; Ensure initialization size is big enough
	 ja	 short GETSIZE_END3 ; Jump if initialization size is larger
	 jb	 short @F	; Jump if load size is larger
				; Fall through if equal
	 cmp	 ax,LSEG.LSEG_LSIZE.ELO ; Ensure initialization size is big enough
	 jae	 short GETSIZE_END3 ; Jump if it is
@@:
	 mov	 LSEG.LSEG_LSIZE.ELO,ax ; Save as necessary load size
	 mov	 LSEG.LSEG_LSIZE.EHI,dx

	 or	 LSEG.LSEG_FLAG,@LSEG_LSIZ ; Mark as forced SIZE=
GETSIZE_END3:
ifndef @HARPO
	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jz	 short GETSIZE_EXIT ; Not this time

; Some programs (like SSTORDRV.SYS with the /NOUMB switch) go resident
; for more in high DOS than in low DOS.  How rude.  We handle this with
; the H1 flag in 386LOAD.CFG.
	 mov	 ax,GETSIZE_RDELTA ; Get additional size
	 add	 LSEG.LSEG_RPARA,ax ; Add to LSEG resident size

	 lea	 ax,AZS_SIZELO	; Tell 'em we loaded low
	 push	 ax		; Pass as argument
	 call	 DISP_ERRMSG	; Display an error message
endif				; ifndef @HARPO
GETSIZE_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GETSIZE  endp			; End GETSIZE procedure
	 NPPROC  FILL_MEM -- Fill Memory With a Pattern
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Fill memory with a pattern following EXEC_LOD.
During and after this call, the memory above GTAIL is invalid.

The length to fill at EXEC_LOD is then MAC_NPAR - (EXEC_LOD - (EXEC_PRGMAC+1)).

When loading a program with both EXE_MIN and EXE_MAX set to 0 paragraphs,
we behave differently.	EXEC_LOD will be the top of the region to fill.
The start is (EXEC_LOD - (EXEC_PRGNPAR - EXE_NPAR)).

|
	 REGSAVE <ax,cx,dx,di,es> ; Save for a moment

ifndef @HARPO
	 test	 LC2_FLAG,@LC2_ENDLOAD ; Does the program load at the high end?
	 jz	 short @F	; Jump if not

	 mov	 cx,EXEC_PRGNPAR ; Get total storage in paragraphs
	 sub	 cx,EXE_NPAR	; Subtract size of load image
	 mov	 ax,EXEC_LOD	; Get start of program storage
	 sub	 ax,cx		; Back off to start of region to fill
	 jmp	 short FILL_MEM_COM ; Join common code

@@:
endif				; IFNDEF @HARPO
	 mov	 cx,EXEC_PRGMAC ; Get program MAC segment

	 inc	 cx		; Count in MAC paragraph to get start
	 add	 cx,EXEC_PRGNPAR ; CX = ending fill point in paras

	 mov	 ax,EXEC_LOD	; Get program load segment
	 sub	 cx,ax		; Less program load segment to get
				; # paras available above EXEC_LOD
;;;;;;;; jc	 ???		; Ignore error condition ???

FILL_MEM_COM:
	 mov	 es,ax		; Reset as start point
	 assume  es:nothing	; Tell the assembler about it
FILL_MEM_PAT:
	 push	 cx		; Save for a moment

	 UMIN	 cx,<64*(1024 shr (4-0))> ; CX = min (CX, 64KB)

;;;;;;;; shl	 cx,4-2 	; Convert from paras to dwords
	 shl	 cx,1
	 shl	 cx,1

	 xor	 di,di		; ES:DI ==> store point
@@:
	 mov	 ax,@GSIZE_PAT1 ; Pick a pattern
	 stosw			; Save in memory
	 mov	 ax,@GSIZE_PAT2 ; Pick a pattern
	 stosw			; Save in memory

	 loop	 @B		; Jump if more

	 pop	 cx		; Restore

; Address the next segment

	 mov	 dx,es		; Get current segment
	 add	 dx,64*(1024 shr(4-0)) ; Skip to next 64KB in paras
	 mov	 es,dx		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 sub	 cx,64*(1024 shr (4-0)) ; Less maximum
	 ja	 short FILL_MEM_PAT ; Jump if more pattern to fill

	 REGREST <es,di,dx,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FILL_MEM endp			; End FILL_MEM procedure

NCODE	 ends			; End NCODE segment


UCODE	 segment byte public 'ucode' ; Start UCODE segment
	 assume  cs:PGROUP

	 NPPROC  LOADSUB -- Subroutine to LOADSIZE
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Subroutine to LOADSIZE

On entry:

DX:AX	 =	 file size in bytes

|

	 REGSAVE <ax,dx>	; Save registers

; Round up the load size to para boundary

	 add	 ax,16-1	; Round up to para boundary
	 adc	 dx,0		; In case of overflow
	 and	 ax,not (16-1)	; Ensure on para boundary

	 mov	 COMPSIZE.EHI,dx ; Save as comparison size
	 mov	 COMPSIZE.ELO,ax

; Count in the PSP (if present)

ifndef @HARPO
	 test	 LCL_FLAG,@LCL_TSR ; Izit TSRLOAD?
	 jz	 short @F	; Jump if not
endif				; ifndef @HARPO

	 add	 ax,100h	; Plus size of PSP
	 adc	 dx,0		; In case of overflow
@@:
	 mov	 LSEG.LSEG_LSIZE.EHI,dx ; Save high-order word
	 mov	 LSEG.LSEG_LSIZE.ELO,ax ;      low-order

	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LOADSUB  endp			; End LOADSUB procedure
	 NPPROC  LOADSIZE -- Calculate The File's Load Size
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Calculate the file's load size.

On entry:

(DX,AX)  =	 file size in bytes

|

	 REGSAVE <ax,cx,dx>	; Save registers

	 call	 LOADSUB	; Call common code

; Account for .EXE header if any

	 cmp	 FILE_HEAD.EXE_SIGN,@EXE_SIGN ; Izit an .EXE file?
	 je	 short @F	; Jump if so

	 cmp	 FILE_HEAD.EXE_SIGN,@EXE_SIG2 ; Izit an .EXE file?
	MJ ne	 LOADSIZE_EXIT	; Jump if it's a .COM file
@@:
	 or	 LCL_FLAG,@LCL_EXE ; Mark as an .EXE file

; Calculate file size based upon EXE header values

	 mov	 ax,FILE_HEAD.EXE_Q512 ; Get image size/512 quotient

; Adjust the file size Q512 down by one if R512 not zero

	 cmp	 FILE_HEAD.EXE_R512,1 ; Iff R512 != 0, CF=0
	 cmc			; Iff R512 != 0, CF=1
	 sbb	 ax,0		; Subtract 1 iff R512 != 0

	 mov	 dx,512 	; Get previous divisor
	 mul	 dx
	 add	 ax,FILE_HEAD.EXE_R512 ; Plus image size/512  remainder
	 adc	 dx,0		; In case of overflow

	 call	 LOADSUB	; Call common code

; DOS apparently adds EXE_MIN to the image size when checking for available
; space.  The commented-out code below may cause some programs to fail
; when the fit is very close to our calculated load size.
	 mov	 ax,FILE_HEAD.EXE_HSIZ ; Get size of header in paras
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes
;;;;;;;  sub	 LSEG.LSEG_LSIZE.ELO,ax ; Subtract out of load size
;;;;;;;  sbb	 LSEG.LSEG_LSIZE.EHI,dx
	 sub	 COMPSIZE.ELO,ax ; Subtract out of comparison size
	 sbb	 COMPSIZE.EHI,dx

	 mov	 ax,FILE_HEAD.EXE_MIN ; Get minimum # paras needed above
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes
	 add	 LSEG.LSEG_LSIZE.ELO,ax ; Add into load size
	 adc	 LSEG.LSEG_LSIZE.EHI,dx

; Ensure the stack fits into memory

	 mov	 ax,FILE_HEAD.EXE_SS ; Get initial SS in paras
	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes
	 add	 ax,FILE_HEAD.EXE_SP ; Plus initial SP
	 adc	 dx,0		; In case of overflow

ifndef @HARPO
	 test	 LCL_FLAG,@LCL_TSR ; Izit TSRLOAD?
	 jz	 short @F	; Jump if not
endif				; ifndef @HARPO

	 add	 ax,100h	; Plus size of PSP
	 adc	 dx,0		; In case of overflow
@@:
	 cmp	 dx,LSEG.LSEG_LSIZE.EHI ; Ensure it's big enough
	 jb	 short LOADSIZE_NPAR ; Jump if within range
	 ja	 short @F	; Jump if specified value is larger

	 cmp	 ax,LSEG.LSEG_LSIZE.ELO ; Ensure it's big enough
	 jbe	 short LOADSIZE_NPAR ; Jump if within range
@@:
	 mov	 LSEG.LSEG_LSIZE.ELO,ax ; Save as necessary load size
	 mov	 LSEG.LSEG_LSIZE.EHI,dx
LOADSIZE_NPAR:
	 mov	 ax,FILE_HEAD.EXE_Q512 ; Get image size/512 quotient
	 mov	 cl,9-4 	; Shift amount between 512 bytes and paras
	 shl	 ax,cl		; Convert from 512 bytes to paras
	 sub	 ax,FILE_HEAD.EXE_HSIZ ; Less size of header in paras
	 add	 ax,0010h	; Plus size of PSP in paras

	 add	 ax,FILE_HEAD.EXE_MAX ; Plus maximum # paras needed beyond image
	 jc	 short LOADSIZE_EXIT ; Jump if too many

	 mov	 EXE_NPAR,ax	; Save as # paras to allocate to EXE file
LOADSIZE_EXIT:
	 REGREST <dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LOADSIZE endp			; End LOADSIZE procedure

UCODE	 ends			; End UCODE segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 NPPROC  PAR2BYT -- Convert from Paras to Bytes
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Convert from paras to bytes

On entry:

AX	 =	 # paras

On exit:

(DX,AX)  =	 corresponding # bytes

|

	 REGSAVE <cx>		; Save register

	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 rol	 ax,cl		; Rotate upwards
	 mov	 dx,ax		; Copy to result register
	 and	 dx,@NIB0	; Isolate low-order nibble
	 and	 ax,not @NIB0	; Isolate other nibbles

	 REGREST <cx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

PAR2BYT  endp			; End PAR2BYT procedure
	 NPPROC  BYT2PAR -- Convert from Bytes to Paras
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Convert from bytes to paras, rounding down

On entry:

(DX,AX)  =	 # bytes

On exit:

AX	 =	 corresponding # paras (rounded down)

|

	 REGSAVE <cx,dx>	; Save registers

	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 ax,cl		; Convert from bytes to paras
	 and	 dx,@NIB0	; Isolate low-order nibble
	 ror	 dx,cl		; Rotate to high-order nibble
	 add	 ax,dx		; Include in result

	 REGREST <dx,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

BYT2PAR  endp			; End BYT2PAR procedure

NCODE	 ends			; End NCODE segment

	 MEND			; End GETSIZE module
