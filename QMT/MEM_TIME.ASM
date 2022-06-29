;' $Header:   P:/PVCS/MAX/QMT/MEM_TIME.ASV   1.1   05 Jun 1998 14:04:30   BOB  $
	 title	 MEM_TIME -- MEMCHK Memory Timing Routines
	 page	 58,122
	 name	 MEM_TIME

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  dword-aligned, public, class 'data'

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include 8253.INC
	 include 386.INC
	 include PTR.INC
	 include MASM5.MAC
	 include DPMI.INC
	 include ALLMEM.INC
	 include KEYCODE.INC

	 include MEM_OEM.INC
	 include MEM_SCRN.INC
.list

PGROUP	 group	 CODE
DGROUP	 group	 DATA


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

ifdef @BETA
	 extrn	 DBG_FLAG:word
	 include MEM_DBG.INC
endif				; IFDEF @BETA
	 extrn	 GL2_FLAG:word
	 include MEM_GL2.INC

	 extrn	 SHDTAB:tbyte,SHDCNT:word
	 include MEM_SHD.INC

	 extrn	 CPUTYPE:byte
	 extrn	 DPMI_FMI:tbyte

	 extrn	 ELEVATTR:byte
	 extrn	 MEMATTR:byte
	 extrn	 MEMHATTR:byte
	 extrn	 EMEMATTR:byte
	 extrn	 AMEMATTR:byte
	 extrn	 IMEMATTR:byte
	 extrn	 TMEMATTR:byte

	 extrn	 CON4K:dword
	 extrn	 MAXSIZE:dword

	 extrn	 MEMITEM_LEN:word

	 extrn	 MEMIND:word
	 extrn	 SEL_4GB:word
	 extrn	 NEXTPTE:dword
	 extrn	 LaPTE:dword

	 extrn	 W_MEMEND:tbyte
	 extrn	 W_EBOX:tbyte
	 extrn	 W_MEMSCR:tbyte
	 extrn	 W_ELEV:tbyte
	 extrn	 W_MEMH:tbyte
	 extrn	 W_MEMSCR:tbyte
	 extrn	 W_MEMLIN:tbyte

	 extrn	 MSG_MEMSCR:byte
	 extrn	 MSG_MEMATTR:byte
	 extrn	 MSG_MEMLIN:byte
	 extrn	 MSG_ELEV:byte

	 extrn	 @MEMITEM_LEN:abs
	 extrn	 @MEMLIN_NCOL:abs
	 extrn	 @ELEV_NROW:abs
	 extrn	 @ELEV_SROW:abs

	 extrn	 PMSG_MEMEND:word
	 extrn	 MSG_MEMEND1:byte

	 extrn	 MSG_TOT:byte
	 extrn	 MSG_TOT_LEN:abs

	 extrn	 HELP_STATE:word
	 extrn	 @HELP_SCREEN:abs

	 public  TSTSIZEB,TSTSIZEW,TSTSIZED
TSTSIZEB dd	 ?		; Total amount of byte-wide memory to test in bytes
TSTSIZEW dd	 ?		; ...		  word-...
TSTSIZED dd	 ?		; ...		  dword-...

	 public  NMEMVAL
NMEMVAL  dd	 ?		; # valid memory ranges

	 public  MEMITEM_SIZ
MEMITEM_SIZ dw	 ?		; # bytes in MEMITEM display

	 public  TIMECNT
TIMECNT  dw	 ?		; Count of # different entries

	 public  TIMETAB
	 include MEM_TIME.INC
@TIMETAB_LEN equ 128
TIMETAB  TT_STR  @TIMETAB_LEN dup (<>)	 ; Memory timing table

	 public  MSG_MEMCLR
MSG_MEMCLR db	 ' ________-________     _ '

	 public  MAXVSAPI
MAXVSAPI db	 '386MAX',0     ; 386MAX DPMI name

DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 WPUT_C:near
	 extrn	 WPUT_SC:near
	 extrn	 WPUT_A:near
	 extrn	 WPUT_CSA:near
	 extrn	 WPUT_SA:near
	 extrn	 WPUT_SHD2:near

	 extrn	 BIN2DVAL:near
	 extrn	 BIND2DEC:near

	 extrn	 CALIBRATE:near

	 NPPROC  COPY_MEMVAL -- Copy Memory Values
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy memory values to timing table

|

	 REGSAVE <eax,cx,si,di> ; Save registers

	 xor	 di,di		; Initialize index into TIMETAB
	 mov	 TIMECNT,0	; Initialize the count

	 mov	 cx,SHDCNT	; Get # entries in SHDTAB
	 jcxz	 COPY_MEMVAL_EXIT ; Jump if none

	 xor	 si,si		; Initialize index into SHDTAB
COPY_MEMVAL_NEXT:
	 mov	 eax,SHDTAB[si].SHD_LBASE ; Get base linear address
	 mov	 TIMETAB[di].TT_LBASE,eax ; Save for later use

	 mov	 eax,SHDTAB[si].SHD_PBASE ; Get base physical address
	 mov	 TIMETAB[di].TT_PBASE,eax ; Save for later use

	 mov	 eax,SHDTAB[si].SHD_ESIZE ; Get size in bytes
	 mov	 TIMETAB[di].TT_LEN,eax ; Save as length in bytes

	 mov	 ax,SHDTAB[si].SHD_FLAG ; Get flags
	 mov	 TIMETAB[di].TT_FLAG,ax ; Save for later use

	 mov	 TIMETAB[di].TT_WIDTH,32 ; Use dwords for all references

	 add	 si,size SHD_STR ; Skip to next entry

	 cmp	 TIMECNT,@TIMETAB_LEN ; Izit at the maximum?
	 jae	 short @F	; Jump if so

	 add	 di,size TT_STR ; Skip to next entry

	 inc	 TIMECNT	; Count in another one
@@:
	 loop	 COPY_MEMVAL_NEXT ; Jump if more entries to copy
COPY_MEMVAL_EXIT:
	 REGREST <di,si,cx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_MEMVAL endp		; End COPY_MEMVAL procedure
	 NPPROC  CALC_MEMVAL -- Calculate Various Memory Value Variables
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate various memory value variables

|

	 REGSAVE <eax,bx,cx,si> ; Save registers

	 mov	 ax,TIMECNT	; Get # entries in structure

	 mov	 MEMITEM_LEN,1	; Assume no extra items off the screen
	 mov	 W_ELEV.NCOL,0	; Mark as inactive

	 cmp	 ax,@MEMITEM_LEN ; Izit larger than the # we can display?
	 jbe	 short @F	; Jump if not

	 mov	 W_ELEV.NCOL,1	; Mark as active
	 or	 GL2_FLAG,@GL2_MEMOVF ; Mark as overflowed

	 sub	 ax,@MEMITEM_LEN-1 ; Less the # we can display
				; (less one for length)
	 mov	 MEMITEM_LEN,ax ; Save for later use
	 mov	 ax,@MEMITEM_LEN ; Use maximum we can display
@@:
	 imul	 ax,@MEMLIN_NCOL ; Times # cols per line
	 mov	 MEMITEM_SIZ,ax ; Save for later use

; Count the total amount of memory in bytes to test

	 mov	 cx,TIMECNT	; Get # entries in structure
	 xor	 si,si		; Initialize index into TIMETAB
	 mov	 TSTSIZEB,0	; Initialize byte-wide total
	 mov	 TSTSIZEW,0	; ...	     word-...
	 mov	 TSTSIZED,0	; ...	     dword-...
	 mov	 NMEMVAL,0	; ...	     # valid memory ranges
CALC_MEMVAL_NEXT:
	 test	 TIMETAB[si].TT_FLAG,@TT_UNALL ; Izit unallocated?
	 jnz	 short @F	; Jump if so

	 mov	 eax,TIMETAB[si].TT_LEN ; Get the size in bytes
	 mov	 bx,TIMETAB[si].TT_WIDTH ; Get the chip width (8, 16, or 32)
	 shr	 bx,3		; Divide by 8 to get 1, 2, 4
	 bsf	 bx,bx		; Search for 1st one to get 0, 1, 2
	 shl	 bx,2		; Times four to index table of dwords
	 add	 TSTSIZEB[bx],eax ; Add into appropriate total

	 inc	 NMEMVAL	; Count in another valid memory range
@@:
	 add	 si,size TT_STR ; Skip to next entry

	 loop	 CALC_MEMVAL_NEXT ; Jump if more entries to check

	 REGREST <si,cx,bx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_MEMVAL endp		; End CALC_MEMVAL procedure
	 NPPROC  DISP_MEMSCR -- Display Memory Screen
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the memory screen background

|

	 push	 ax		; Save for a moment

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 short DISP_MEMSCR_EXIT ; Jump if not

; Clear the memory screen

	 mov	 al,MEMATTR	; Get memory screen attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:MSG_MEMSCR ; Pass address of local buffer
	 push	 offset ds:W_MEMSCR ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

; Display the memory header attributes

	 mov	 al,MEMHATTR	; Get memory header attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:W_MEMH ; Pass address of window descriptor
	 call	 WPUT_SA	; Smear attribute

; Display a shadow over the bottom line and right edge of the window

	 push	 offset ds:W_MEMSCR ; Pass address of window descriptor
	 call	 WPUT_SHD2	; Display a type 2 shadow
DISP_MEMSCR_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MEMSCR endp		; End DISP_MEMSCR procedure
	 NPPROC  DISP_MEMVAL -- Display Memory Values
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display memory values

|

	 REGSAVE <eax,bx,cx,edx,si,di,es> ; Save registers

	 test	 GL2_FLAG,@GL2_ADV ; Izit advanced mode?
	 jz	 near ptr DISP_MEMVAL_EXIT ; Jump if not

	 cmp	 HELP_STATE,@HELP_SCREEN ; Are we displaying help?
	 je	 near ptr DISP_MEMVAL_EXIT ; Jump if so

	 push	 ds		; Get our data selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 W_MEMLIN.NROW,0 ; Initialize # rows

	 mov	 cx,TIMECNT	; Get # entries in structure
	 xor	 si,si		; Initialize index into TIMETAB
				; (added to MEMIND * (size TT_STR))
	 xor	 bx,bx		; Initialize index into MEMLIN
DISP_MEMVAL_NEXT:
	 call	 FMT_MEM	; Format it

	 inc	 W_MEMLIN.NROW	; Count in another row
	 add	 bx,@MEMLIN_NCOL ; Skip to next entry
	 add	 si,size TT_STR ; Skip to next entry

	 cmp	 bx,MEMITEM_SIZ ; Izit at the maximum?
	 loopne  DISP_MEMVAL_NEXT ; Jump if more entries to display

	 mov	 ax,W_MEMLIN.NROW ; Get # rows in memory lines
	 mov	 W_ELEV.NROW,ax ; Save as # rows in elevator

; Set attributes for memory total line

	 lea	 di,MSG_MEMATTR[bx] ; ES:DI ==> attributes for this line
	 mov	 cx,@MEMLIN_NCOL ; Get # cols in the line
	 mov	 al,TMEMATTR	; Get active attribute
     rep stos	 MSG_MEMATTR[di] ; Store the attribute

; Clear characters for memory total line

	 lea	 di,MSG_MEMLIN[bx] ; ES:DI ==> characters for this line
	 mov	 cx,@MEMLIN_NCOL ; Get # cols in the line
	 mov	 al,' '         ; Get a blank
     rep stos	 MSG_MEMLIN[di].LO ; Store the blanks

	 lea	 si,MSG_TOT	; DS:SI ==> "Total " text
	 mov	 cx,MSG_TOT_LEN ; CX = length of "Total " text
	 mov	 di,bx		; Copy index
	 add	 di,@MEMLIN_NCOL ; Plus # cols in MEMLIN
	 lea	 di,MSG_MEMLIN[di - 7] ; ES:DI ==> total line
	 sub	 di,cx		; Back off to start
S16  rep movs	 <MSG_MEMLIN[di],MSG_TOT[si]> ; Copy to MEMLIN
;;;;;;;; mov	 MSG_MEMLIN[di - 13].EDD,'atoT'
;;;;;;;; mov	 MSG_MEMLIN[di -  9].ELO,' l'

; Format the total # bytes we're testing

	 xor	 eax,eax	; Clear accumulator

	 mov	 edx,TSTSIZEB	; Get byte-wide total
	 add	 edx,1024/2	; Round up halfway
	 shr	 edx,10-0	; Convert from bytes to 1KB rounding down
	 add	 eax,edx	; Add into total

	 mov	 edx,TSTSIZEW	; Get word-wide total
	 add	 edx,1024/2	; Round up halfway
	 shr	 edx,10-0	; Convert from bytes to 1KB rounding down
	 add	 eax,edx	; Add into total

	 mov	 edx,TSTSIZED	; Get dword-wide total
	 add	 edx,1024/2	; Round up halfway
	 shr	 edx,10-0	; Convert from bytes to 1KB rounding down
	 add	 eax,edx	; Add into total

	 mov	 di,bx		; Copy index
	 add	 di,@MEMLIN_NCOL ; Plus # cols in MEMLIN
	 lea	 di,MSG_MEMLIN[di - 2] ; ES:DI ==> text for this line
	 call	 BIND2DEC	; Convert EAX to decimal ending at ES:DI

	 inc	 W_MEMLIN.NROW	; Count in the total line

; Display the lines

	 push	 offset ds:MSG_MEMLIN ; Pass address of local buffer
	 push	 offset ds:W_MEMLIN ; Pass address of window descriptor
	 call	 WPUT_C 	; Output the characters

; Display the attributes

	 push	 offset ds:MSG_MEMATTR ; Pass address of local buffer
	 push	 offset ds:W_MEMLIN ; Pass address of window descriptor
	 call	 WPUT_A 	; Output the attributes

; Display the elevator if active

	 cmp	 W_ELEV.NCOL,0	; Izit active?
	 je	 short DISP_MEMVAL_XELEV ; Jump if not

	 mov	 al,ELEVATTR	; Get elevator attribute
	 push	 ax		; Pass attribute to smear
	 push	 offset ds:MSG_ELEV ; Pass address of local buffer
	 push	 offset ds:W_ELEV ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

COMMENT|

Output the elevator box

Calculate a number between 0 and @HELEV_NROW-3 which
represents approximately where we are in the text display.
This calculation is

(@ELEV_NROW - 3) * MEMIND / (DGROUP:[bx].NROW - @HTXT_NROW)

|

	 imul	 ax,MEMIND,@ELEV_NROW-3 ; Get 1st multiplier
	 xor	 dx,dx		; Zero to use as dword
	 mov	 cx,TIMECNT	 ; Get total # rows
	 sub	 cx,@MEMITEM_LEN ;Less # rows that fit on screen
	 div	 cx		; Divide to get value in AX

	 add	 ax,@ELEV_SROW+1 ; Plus starting row
	 mov	 W_EBOX.SROW,ax ; Save as starting row

	 mov	 al,'²'         ; Smear a half-tone
	 push	 ax		; Pass the character to smear
	 push	 offset ds:W_EBOX ; Pass address of window descriptor
	 call	 WPUT_SC	; Smear the character
DISP_MEMVAL_XELEV:

; Display the trailing line

	 mov	 al,EMEMATTR	; Get memory ending line attribute
	 push	 ax		; Pass attribute to smear
	 push	 PMSG_MEMEND	; Pass address of local buffer
	 push	 offset ds:W_MEMEND ; Pass address of window descriptor
	 call	 WPUT_CSA	; Output the characters, smear attribute

;;;;;;;; If we're displaying help topics, redraw it over the display we just updated.
;;;;;;;  call	 CHECK_RHELP	; Refresh help topic display if needed
DISP_MEMVAL_EXIT:
	 REGREST <es,di,si,edx,cx,bx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_MEMVAL endp		; End DISP_MEMVAL procedure
	 NPPROC  FMT_MEM -- Format and Display Memory Line
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Format and display the memory line.

On entry:

SI	 =	 index into TIMETAB (when added to MEMIND * (size TT_STR))
BX	 =	 index into MSG_MEMLIN

|

	 REGSAVE <eax,cx,si,edi> ; Save registers

	 call	 CLEAR_MEM	; Blank the output save area

	 imul	 ax,MEMIND,size TT_STR ; Get starting row #
				; times # bytes per entry
	 add	 si,ax		; Add to get starting offset

	 mov	 eax,TIMETAB[si].TT_PBASE ; Get base physical address
	 lea	 di,MSG_MEMLIN[bx].MEMLIN_BEG ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 add	 eax,TIMETAB[si].TT_LEN ; Add length in bytes to get ending address
	 lea	 di,MSG_MEMLIN[bx].MEMLIN_END ; ES:DI ==> output save area
	 call	 BIN2DVAL	; Convert EAX to hex or decimal at ES:DI

	 mov	 eax,TIMETAB[si].TT_LEN ; Get length in bytes
	 add	 eax,1024/2	; Round up halfway
	 shr	 eax,10-0	; Convert from bytes to 1KB (rounding down)
	 lea	 di,MSG_MEMLIN[bx].MEMLIN_SIZ ; ES:DI ==> output save area
	 call	 BIND2DEC	; Convert EAX to decimal ending at ES:DI

; If this is unallocated memory, flag it

	 mov	 al,AMEMATTR	; Get active attribute

	 test	 TIMETAB[si].TT_FLAG,@TT_UNALL ; Izit unallocated?
	 jz	 short @F	; Jump if not

	 mov	 al,IMEMATTR	; Get inactive attribute
@@:
	 lea	 di,MSG_MEMATTR[bx] ; ES:DI ==> attributes for this line
	 mov	 cx,@MEMLIN_NCOL ; Get # cols in the line
     rep stos	 MSG_MEMATTR[di] ; Store the attribute

	 REGREST <edi,si,cx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMT_MEM  endp			; End FMT_MEM procedure
	 NPPROC  CLEAR_MEM -- Clear the Output Save Area
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear the output save area

On entry:

BX	 =	 index into MSG_MEMLIN

|

	 REGSAVE <cx,si,di>	; Save registers

	 lea	 di,MSG_MEMLIN[bx] ; ES:DI ==> destin area to clear
	 lea	 si,MSG_MEMCLR	; DS:SI ==> source ...
	 mov	 cx,@MEMLIN_NCOL ; # bytes to clear
S16  rep movs	 <MSG_MEMLIN[di],MSG_MEMCLR[si]> ; Copy clear line

	 REGREST <di,si,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEAR_MEM  endp 		; End CLEAR_MEM procedure
	 NPPROC  CHECK_TIME -- Time All Memory Accesses
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Time memory accesses in extended memory.

This routine runs in protected mode.

On exit:

CF	 =	 0 if all went well
	 =	 1 if we failed on P2L and need to
		   try again allocating less memory than before

|

ifdef @BETA
	 test	 DBG_FLAG,@DBG_TIM ; Debugging memory timing?
	 jz	 short @F	; Not this time

	 int	 01h		; Call in the SWAT team
@@:
endif				; IFDEF @BETA

; Copy physical and shadow memory values to timing values

	 call	 COPY_MEMVAL	; Copy 'em

	 call	 CHECK_SX	; See if we're on an SX (16-bit memory)
	 jc	 short @F	; Jump if not

	 call	 WORD_MEMVAL	; Mark all memory as being 16-bits wide
@@:

; Calculate various memory value variables

	 call	 CALC_MEMVAL	; Calculate 'em

; Sort extended memory values

	 call	 SORT_MEMVAL	; Sort 'em

; Fill in missing memory ranges (unallocated ones)

	 call	 FILL_MEMVAL	; Fill 'em
	 jc	 short CHECK_TIME_EXIT ; Jump if we need to start again

; Sort extended memory values

	 call	 SORT_MEMVAL	; Sort 'em

	 call	 DISP_MEMVAL	; Display 'em

	 call	 CALIBRATE	; Calibrate macros for ETA timings

	 clc			; Indicate all went well
CHECK_TIME_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_TIME endp 		; End CHECK_TIME procedure
	 NPPROC  SORT_MEMVAL -- Sort Extended Memory Values
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Sort extended memory values ascendingly by starting address
maintaining a stable sort.

|

	 REGSAVE <eax,cx,si,di,es> ; Save registers

	 push	 ds		; Get DGROUP selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 lea	 si,TIMETAB	; DS:SI ==> TT_STR structure

; As there are relatively few entries, we'll use a simple bubble sort

	 mov	 cx,TIMECNT	; Get # entries in structure

	 cmp	 cx,1		; Check against limit cases
	 jbe	 short SORT_MEMVAL_EXIT ; Jump if nothing to sort

	 dec	 cx		; Account for second entry (the number of
				; comparisons is TIMECNT-1)
SORT_MEMVAL_OUTER:
	 push	 cx		; Save outer loop counter

	 lea	 di,DGROUP:[si+type TT_STR] ; Skip to next entry
	 mov	 eax,DGROUP:[si].TT_PBASE ; Get starting physical address
SORT_MEMVAL_INNER:
	 cmp	 eax,DGROUP:[di].TT_PBASE ; Izit in sequence?
	 jbe	 short SORT_MEMVAL_INNERLOOP ; Jump if so

; Rotate the entries between SI (low) and DI (high) upwards

	 push	 si		; Save starting offset

; Save the last entry on the stack

	 mov	 cx,(type TT_STR)/2 ; Get # words in each entry
@@:
	 push	 DGROUP:[di].ELO ; Save on stack
	 add	 di,2		; Skip to next word
	 loop	 @B		; Jump if more words to save

; DI points to next word following higher entry

	 mov	 cx,di		; Copy higher ending address
	 sub	 cx,si		; Subtract to get # bytes to rotate
	 sub	 cx,type TT_STR ; Less one entry saved on the stack
	 shr	 cx,1-0 	; Convert from bytes to words
	 sub	 di,2		; Back off to previous word
	 lea	 si,[di-(type TT_STR)] ; Point to entry below higher
	 std			; String ops backwards
S16  rep movs	 <es:[di].ELO,ds:[si].ELO> ; Move downwards
	 cld			; Restore

; Restore the last entry from the stack to the first entry
; to complete the rotation

	 mov	 cx,(type TT_STR)/2 ; Get # words in each entry
@@:
	 pop	 DGROUP:[di].ELO ; Restore from stack
	 sub	 di,2		; Skip to previous word
	 loop	 @B		; Jump if more words to restore

	 pop	 si		; Restore
	 pop	 cx		; Restore outer loop counter

	 jmp	 short SORT_MEMVAL_OUTER ; Go around again

SORT_MEMVAL_INNERLOOP:
	 add	 di,type TT_STR ; Skip to next entry

	 loop	 SORT_MEMVAL_INNER ; Jump if more entries in inner loop

	 pop	 cx		; Restore outer loop counter

	 add	 si,type TT_STR ; Skip to next entry

	 loop	 SORT_MEMVAL_OUTER ; Jump if more entries in outer loop
SORT_MEMVAL_EXIT:
	 REGREST <es,di,si,cx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SORT_MEMVAL endp		; End SORT_MEMVAL procedure
	 NPPROC  FILL_MEMVAL -- Fill In Unallocated Extended Memory Ranges
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in unallocated memory ranges
and merge physically adjacent ranges.

On exit:

CF	 =	 0 if all went well
	 =	 1 if we failed on P2L and need to
		   try again allocating less memory than before

|

	 pushad 		; Save all EGP registers
	 REGSAVE <es>		; Save register

	 push	 ds		; Get DGROUP selector
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 cx,TIMECNT	; Get # entries in structure
	 mov	 dx,cx		; Copy for later use

	 xor	 si,si		; Initialize index into TIMETAB
	 imul	 di,cx,size TT_STR ; Get length of existing entries

	 cmp	 cx,1		; Check against limit cases
	 jbe	 near ptr FILL_MEMVAL_TAIL ; Jump if nothing to fill

	 dec	 cx		; Account for second entry (the number of
				; comparisons is TIMECNT-1)
FILL_MEMVAL_NEXT:
	 mov	 eax,TIMETAB[si].TT_PBASE ; Get initial base
	 add	 eax,TIMETAB[si].TT_LEN ; Add its length in bytes to get next address

	 mov	 ebx,TIMETAB[si+(size TT_STR)].TT_PBASE ; Get next base
				; physical address
	 sub	 ebx,eax	; Izit contiguous?
	 jz	 short FILL_MEMVAL_CONT ; Jump if so

	 mov	 TIMETAB[di].TT_LEN,ebx ; Save as length in bytes
	 mov	 TIMETAB[di].TT_PBASE,eax ; Save for later use
	 mov	 TIMETAB[di].TT_LBASE,-1 ; Use filler value
	 mov	 TIMETAB[di].TT_FLAG,@TT_UNALL ; Save for later use
	 mov	 TIMETAB[di].TT_WIDTH,32 ; Use dwords for all references

; If this unallocated entry can be merged with the first entry, do so

	 test	 TIMETAB[si].TT_FLAG,@TT_UNALL ; Izit unallocated?
	 jz	 short @F	; Jump if not

	 cmp	 TIMETAB[di].TT_WIDTH,32 ; Izit the same width?
	 jne	 short @F	; Jump if not (can't merge)

	 add	 TIMETAB[si].TT_LEN,ebx ; Add into the first block's length in bytes
	 mov	 TIMETAB[si].TT_LBASE,-1 ; Zap the linear base
	 or	 TIMETAB[si].TT_FLAG,@TT_P2L ; Mark as needing P2L later

	 jmp	 short FILL_MEMVAL_LOOP ; Join common loop code

@@:
	 cmp	 TIMECNT,@TIMETAB_LEN ; Izit at the maximum?
	 jae	 short @F	; Jump if so

	 add	 di,size TT_STR ; Skip to next entry

	 inc	 TIMECNT	; Count in another one
	 mov	 PMSG_MEMEND,offset DGROUP:MSG_MEMEND1 ; Use unallocated message
@@:
	 jmp	 short FILL_MEMVAL_LOOP ; Join common loop code


COMMENT|

Two blocks are physically adjacent.  We can merge the two if

* Both block are allocated or both blocks are unallocated, and
* There's a DPMI host (so we can do P2L), and
* The memory widths are the same.

|

FILL_MEMVAL_CONT:
	 mov	 ax,TIMETAB[si].TT_FLAG ; Get the 1st entry's flags
	 xor	 ax,TIMETAB[si+(size TT_STR)].TT_FLAG ; Merge with the 2nd entry's flags

	 test	 ax,@TT_UNALL	; Is there a mismatch?
	 jnz	 short FILL_MEMVAL_LOOP ; Jump if so

	 mov	 ax,TIMETAB[si].TT_WIDTH ; Get the first entry's chip width

	 cmp	 ax,TIMETAB[si+(size TT_STR)].TT_WIDTH ; Izit the same?
	 jne	 short FILL_MEMVAL_LOOP ; Jump if not (can't merge)

; Merge the two entries, and mark as needing P2L later

	 mov	 eax,TIMETAB[si+(size TT_STR)].TT_LEN ; Get the second block's
				; length in bytes
	 add	 TIMETAB[si].TT_LEN,eax ; Add into the first block's length in bytes

	 mov	 TIMETAB[si].TT_LBASE,-1 ; Zap the linear base
	 or	 TIMETAB[si].TT_FLAG,@TT_P2L ; Mark as needing P2L later

; Delete the second entry by copying the entries above it
; down on top of it.

	 REGSAVE <cx,si,di>	; Save registers

	 lea	 cx,TIMETAB[di] ; Copy offset of next available entry
	 lea	 di,TIMETAB[si+2*(size TT_STR)] ; Skip to first entry to copy
	 lea	 si,TIMETAB[si+(size TT_STR)] ; Skip to entry being deleted
	 sub	 cx,di		; Subtract to get # bytes to copy
	 xchg	 si,di		; Exchange for MOVSB
S16  rep movs	 <DGROUP:[di].LO,DGROUP:[si].LO> ; Delete the entry

	 REGREST <di,si,cx>	; Restore

	 sub	 di,size TT_STR ; Back off next available entry
	 dec	 TIMECNT	; Account for one fewer entry
	 dec	 dx		; ...

	 jmp	 short FILL_MEMVAL_LOOP1 ; Join common code

FILL_MEMVAL_LOOP:
	 add	 si,type TT_STR ; Skip to next entry
FILL_MEMVAL_LOOP1:
;;;;;;;; loop	 FILL_MEMVAL_NEXT ; Jump if more entries to check
	 dec	 cx		; Account for one fewer entry
	 jnz	 near ptr FILL_MEMVAL_NEXT ; Jump if more entries to check
FILL_MEMVAL_TAIL:

; If the first entry starts above 0, append an unallocated entry

	 mov	 eax,0		; Get start of physical memory
	 mov	 ebx,TIMETAB.TT_PBASE ; Get the start of the first entry

	 sub	 ebx,eax	; Does the first entry start above 0?
	 jbe	 short FILL_MEMVAL_TAIL1 ; Jump if not

	 mov	 TIMETAB[di].TT_LEN,ebx ; Save as length in bytes
	 mov	 TIMETAB[di].TT_PBASE,eax ; Save for later use
	 mov	 TIMETAB[di].TT_LBASE,-1 ; Use filler value
	 mov	 TIMETAB[di].TT_FLAG,@TT_UNALL ; Save for later use
	 mov	 TIMETAB[di].TT_WIDTH,32 ; Use dwords for all references

	 cmp	 TIMECNT,@TIMETAB_LEN ; Izit at the maximum?
	 jae	 short @F	; Jump if so

	 add	 di,size TT_STR ; Skip to next entry

	 inc	 TIMECNT	; Count in another one
	 mov	 PMSG_MEMEND,offset DGROUP:MSG_MEMEND1 ; Use unallocated message
@@:
FILL_MEMVAL_TAIL1:

; If the last entry ends below MAXSIZE, append an unallocated entry
; to cover the difference.

	 dec	 dx		; Back off to last entry
	 imul	 si,dx,size TT_STR ; Get length of original entries

	 mov	 ebx,MAXSIZE	; Get end of extended memory
	 shl	 ebx,10-0	; Convert from 1KB to bytes

	 mov	 eax,TIMETAB[si].TT_PBASE ; Get the start of the last entry
	 add	 eax,TIMETAB[si].TT_LEN ; Add its length in bytes to get next address

	 sub	 ebx,eax	; Does the last entry end at MAXSIZE?
	 jbe	 short FILL_MEMVAL_TAIL2 ; Jump if so

	 mov	 TIMETAB[di].TT_LEN,ebx ; Save as length in bytes
	 mov	 TIMETAB[di].TT_PBASE,eax ; Save for later use
	 mov	 TIMETAB[di].TT_LBASE,-1 ; Use filler value
	 mov	 TIMETAB[di].TT_FLAG,@TT_UNALL ; Save for later use
	 mov	 TIMETAB[di].TT_WIDTH,32 ; Use dwords for all references

	 cmp	 TIMECNT,@TIMETAB_LEN ; Izit at the maximum?
	 jae	 short @F	; Jump if so

	 add	 di,size TT_STR ; Skip to next entry

	 inc	 TIMECNT	; Count in another one
	 mov	 PMSG_MEMEND,offset DGROUP:MSG_MEMEND1 ; Use unallocated message
@@:
FILL_MEMVAL_TAIL2:

; If appropriate, go through the TIMETAB entries once more
; for Physical-to-Linear translations

	 mov	 cx,TIMECNT	; Get # entries in structure
	 xor	 si,si		; Initialize index into TIMETAB
FILL_MEMVAL_NEXTP2L:
	 test	 TIMETAB[si].TT_FLAG,@TT_UNALL ; Izit unallocated?
	 jnz	 near ptr FILL_MEMVAL_LOOPP2L ; Jump if so

	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jz	 short FILL_MEMVAL_VCPI ; Jump if not

	 test	 TIMETAB[si].TT_FLAG,@TT_P2L ; Duzit need Phys-to-Lin trans?
	 jz	 near ptr FILL_MEMVAL_LOOPP2L ; Jump if not

	 push	 cx		; Save for a moment
	 push	 si		; ...

	 mov	 eax,TIMETAB[si].TT_PBASE ; Get physical address
	 mov	 cx,ax		; Copy low-order word
	 shr	 eax,16 	; Shift down high-order word
	 mov	 bx,ax		; Copy high-order word

	 mov	 eax,TIMETAB[si].TT_LEN ; Get the region length in bytes
	 mov	 di,ax		; Copy low-order word
	 shr	 eax,16 	; Shift down high-order word
	 mov	 si,ax		; Copy high-order word

	 DPMICALL @DPMI_GETP2L	; Request DPMI P2L service
	 pop	 si		; Restore
	 mov	 TIMETAB[si].TT_LBASE.ELO,cx ; Save low-order word
	 mov	 TIMETAB[si].TT_LBASE.EHI,bx ; ...  high-...
	 pop	 cx		; Restore
	 jnc	 near ptr FILL_MEMVAL_LOOPP2L ; Jump if all went well

	 cmp	 ax,8013h	; Izit short on physical memory?
	 je	 near ptr FILL_MEMVAL_ERR ; Jump if so (try again)

	 cmp	 ax,8012h	; Izit short on linear memory?
	 jne	 short FILL_MEMVAL_P2LERR ; Jump if not

; Distinguish the case where the 8012h is really an 8013h
; by doing a Free Information call.  If there's free linear
; memory, treat the 8012h asn a 8013h.

	 lea	 edi,DPMI_FMI	; ES:EDI ==> Free Memory Information struc
	 DPMICALL @DPMI_GETFMI	; Get free memory information
;;;;;;;; DPMIERR <'Unable to get DPMI free memory information.'>
;;;;;;;; jc	 near ptr DPMI_ALLOC_EXIT ; Jump if something went wrong (note CF=1)

	 cmp	 DPMI_FMI.DPMIFMI_APFREE,0 ; Are there any free linear addresses?
	 jne	 near ptr FILL_MEMVAL_ERR ; Jump if so (try again)
FILL_MEMVAL_P2LERR:
	 or	 TIMETAB[si].TT_FLAG,@TT_UNALL or @TT_P2LERR ; Mark as in error
	 mov	 PMSG_MEMEND,offset DGROUP:MSG_MEMEND1 ; Use unallocated message

	 jmp	 short FILL_MEMVAL_LOOPP2L ; Join common loop code

FILL_MEMVAL_VCPI:
	 REGSAVE <ecx,edi,es>	; Save for a moment

	 mov	 eax,NEXTPTE	; Get offset of next PTE
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	 mov	 ecx,TIMETAB[si].TT_PBASE ; Get physical address
	 and	 ecx,4*1024-1	; Isolate 4KB offset
	 or	 eax,ecx	; Include in address
	 mov	 TIMETAB[si].TT_LBASE,eax ; Save as linear address

	 mov	 edi,NEXTPTE	; Get offset of next PTE
	 add	 edi,LaPTE	; Plus linear address of PTEs

	 mov	 eax,TIMETAB[si].TT_PBASE ; Get physical address
	 mov	 ecx,TIMETAB[si].TT_LEN ; Get the region length in bytes
	 add	 ecx,eax	; Add to get ending address
	 and	 eax,not (4*1024-1) ; Round down to 4KB boundary
	 sub	 ecx,eax	; Subtract to get new length
	 add	 ecx,4*1024-1	; Round up to 4KB boundary
	 shr	 ecx,12-0	; Convert from bytes to 4KB (# PTEs)

	 or	 eax,@PTE_URP or (mask $PTE_CD) ; Mark as User/Read-Write/Present
				; and cache-disabled
	 mov	 es,SEL_4GB	; Get AGROUP data selector
	 assume  es:AGROUP	; Tell the assembler about it
@@:
S32	 stos	 AGROUP:[edi].EDD ; Save as next PTE

	 add	 eax,CON4K	; Skip to next PTE

	 LOOPD	 @B		; Jump if more PTEs to save

; Save back offset of next PTE

	 sub	 edi,LaPTE	; Less linear address of PTEs
	 mov	 NEXTPTE,edi	; Save as offset of next PTE

	 REGREST <es,edi,ecx>	; Restore
	 assume  es:DGROUP	; Tell the assembler about it
FILL_MEMVAL_LOOPP2L:
	 add	 si,type TT_STR ; Skip to next entry

;;;;;;;; loop	 FILL_MEMVAL_NEXTP2L ; Jump if more entries to check
	 dec	 cx		; One fewer entry
	 jnz	 FILL_MEMVAL_NEXTP2L ; Jump if more entries to check
FILL_MEMVAL_CALC:

; Calculate various memory value variables

	 call	 CALC_MEMVAL	; Calculate 'em

	 clc			; Indicate all went well

	 jmp	 short FILL_MEMVAL_EXIT ; Join common exit code

FILL_MEMVAL_ERR:
	 stc			; Indicate we failed on P2L
FILL_MEMVAL_EXIT:
	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_MEMVAL endp		; End FILL_MEMVAL procedure
	 NPPROC  WORD_MEMVAL -- Mark All Memory As 16-bits Wide
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mark all memory as being 16-bits wide.

|

	 REGSAVE <bx,cx>	; Save registers

	 mov	 cx,TIMECNT	; Get # entries in structure
	 xor	 bx,bx		; Initialize index into TIMETAB
WORD_MEMVAL_NEXT:
	 mov	 TIMETAB[bx].TT_WIDTH,16 ; Mark as 16-bits wide

	 add	 bx,size TT_STR ; Skip to next entry

	 loop	 WORD_MEMVAL_NEXT ; Jump if more entries to check

	 REGREST <cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WORD_MEMVAL endp		; End WORD_MEMVAL procedure
	 NPPROC  CHECK_SX -- Check For 386 SX Systems
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if we're running on a 386 SX system.

This routine runs in PM only.

On exit:

CF	 =	 0 if it's a 386 SX
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx>	; Save registers

	 cmp	 CPUTYPE,03h	; Izit a 386 system?
	 jne	 short CHECK_SX_ERR ; Jump if not

; If we started from RM, we can test for a 386 SX

	 test	 GL2_FLAG,@GL2_DPMI or @GL2_VCPI ; Is either host available?
	 jz	 short CHECK_SX_TEST ; Jump if not (we started from RM)

; If we entered PM via VCPI, we can test for a 386 SX

	 test	 GL2_FLAG,@GL2_VCPI ; Are we running under VCPI?
	 jnz	 short CHECK_SX_TEST ; Jump if so

; If the DPMI host is 386MAX, we can test for a 386 SX

	 REGSAVE <esi,edi,es>	; Save for a moment

	 lea	 esi,MAXVSAPI	; DS:ESI ==> 386MAX VSAPI name
	 DPMICALL @DPMI_VSAPI	; Return with ES:EDI ==> VSAPI entry point
	 assume  es:nothing	; Tell the assembler about it

	 REGREST <es,edi,esi>	; Restore
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short CHECK_SX_ERR ; Jump if not present
CHECK_SX_TEST:
COMMENT|

The test for 386 DX vs. 386 SX is done by attempting to set the ET bit
in CR0.  If it succeeds, the CPU is a DX; if it fails, it's an SX.

|

	 mov	 eax,cr0	; Get control register #0
	 mov	 ebx,eax	; Save to restore later

	 and	 eax,not (mask $ET) ; ET=0 works on DX only
	 mov	 cr0,eax	; Tell the CPU about it
	 mov	 eax,cr0	; Read it back in
	 mov	 cr0,ebx	; Restore original value

	 test	 eax,mask $ET	; Izit sticky?
	 jnz	 short CHECK_SX_EXIT ; Jump if so (note CF=0)
CHECK_SX_ERR:
	 stc			; Indicate it's not a 386 SX
CHECK_SX_EXIT:
	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SX endp			; End CHECK_SX procedure

CODE	 ends			; End CODE segment

	 MEND			; End MEM_TIME module
