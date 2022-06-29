;' $Header:   P:/PVCS/MAX/386MAX/QMAX_MBT.ASV   1.2   30 May 1997 10:45:36   BOB  $
	 title	 QMAX_MBT -- 386MAX Multiboot processing
	 page	 58,122
	 name	 QMAX_MBT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1993-7 Qualitas, Inc.  All rights reserved.

Segmentation:  Group XGROUP:
	       Program segment XCODE, byte-aligned,  public, class 'xcode'
	       Data    segment XDATA, dword-aligned, public, class 'xdata'

Program derived from:  None.

Original code by:  Henry Groover, March 1993.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include DOSCALL.INC
	 include EXEC.INC
	 include BIOSDATA.INC
.list

XGROUP	 group	XCODE,XDATA
PSPGRP	 group	PSPSEG

PSPSEG	 segment use16 at 0

ifdef @HARPO
	 extrn	 PSP_ENVIR_PTR:word
;;;;;;;  extrn	 PSP_CTRL_PSP:word
endif				; IFDEF @HARPO

PSPSEG	 ends			; End PSPSEG segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment

	 public  MBOOT_SECTION,SKIPSECT,CMP_COMMON
@MBOOT_SECTIONLEN equ 80	; Maximum length less trailing null
MBOOT_SECTION db (@MBOOT_SECTIONLEN+1) dup (0) ; Current CONFIG= setting
SKIPSECT db	 0		; Skip current section
CMP_COMMON db	 'COMMON',0     ; Reserved section name for all configurations

	 public  CONFIGSIG
CONFIGSIG db	 'CONFIG='      ; Lead-in for identifier
@CONFIGLEN equ	 $-CONFIGSIG

XDATA	 ends			; End XDATA segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

@DCBYT	equ	 22h		; Don't care byte for code search

	 NPPROC  CODESRCH -- Find model code
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

	Search for model code, using don't-care bytes.
	@DCBYT (22h) is used as the don't-care byte.

ENTRY:
	DS:SI ==> model code
	ES:DI ==> target code
	CX    =   length of model
	BX    =   limit of search

EXIT:
	Carry clear if found, ES:DI ==> start of code in target segment
	Carry set if not found.

|

	 REGSAVE <ax,bx,cx,dx,si> ; Save caller's registers

	 sub	 bx,cx		; Reduce search limit by length of model

	 xchg	 bx,cx		; BX = length of model
				; CX = limit of search
	 lodsb			; AL = 1st byte of model

CODESRCH_OLOOP:
   repne scasb				; Find 1st byte of model
	 jne	 short CODESRCH_NEVER	; Jump if we can't find the model

; AL = 1st byte of model
; SI ==> 2nd byte of model
; DI ==> 2nd byte of target, 1st byte has been matched

	 REGSAVE <ax,cx,si,di>	; Save pointers and length

	 mov	 cx,bx		; CX = length of model
	 jmp	 short CODESRCH_NXT	; Jam into the loop to account
					; ... for the 1st byte already matched
CODESRCH_ILOOP:
	 mov	 dl,es:[di]		; Pick up next byte of target
	 inc	 di			; Account for byte picked up

	 lodsb				; Pick up next byte of model

	 cmp	 al,@DCBYT		; Izit a don't-care byte?
	 je	 short CODESRCH_NXT	; Skip compare if so

	 cmp	 al,dl			; Are model and target equal?
	 jne	 short CODESRCH_MM	; No, so exit loop (Zero flag clear)

CODESRCH_NXT:
	 loop	 CODESRCH_ILOOP 	; Test 'em all

CODESRCH_MM:
	 REGREST <di,si,cx,ax>	; Restore pointers and length

; AL = 1st byte of model
; SI ==> 2nd byte of model
; DI ==> next byte of target
; CX = limit of search

	 loopne  CODESRCH_OLOOP 	; Look for 1st byte again

; If zero flag is clear, we've exahusted the search w/o finding the model

CODESRCH_NEVER:
	 jne	 short CODESRCH_STC	; Exit with carry set

	 dec	 di			; Back up to first byte in target

	 clc				; 'Found' return indicator

	 jmp	 short CODESRCH_EXIT	; Rejoin common exit code

CODESRCH_STC:
	 stc				; 'Not found' return indicator

CODESRCH_EXIT:
	 REGREST <si,dx,cx,bx,ax>	; Restore caller's registers

	 ret				; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CODESRCH endp				; End CODESRCH procedure

	NPPROC	 TARGET_CODE -- Code to find in CONFIG.SYS processor
	assume	 ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

This is actually data we use to search for similar code.  It's the
code in the CONFIG.SYS processor that loads and executes INSTALL=
commands.

|

	mov	 cx,ds:[0].ELO	; Get segment of temporary environment source
org	$-2			; Back off to operand word
@TENV_SRCOFF equ $-TARGET_CODE	; Offset of temp env source from start of code
	db	 @DCBYT,@DCBYT	; Don't care what it is
	mov	 ds:[bx].EXEC_ENV,cx ; Save as environment segment for 4B00 call
	mov	 ds:[bx].EXEC_CMD.VSEG,cs ; Fix up segment of command line
	mov	 ds:[bx].EXEC_FCB1.VSEG,cs ; Fix up FCB1
	mov	 ds:[bx].EXEC_FCB2.VSEG,cs ; ...    FCB2

	mov	 ax,4B00h	; Execute function

@TARGET_CLEN equ $-TARGET_CODE	; Length of code snippet to search for

	assume	 ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TARGET_CODE endp		; End TARGET_CODE procedure

	 NPPROC  FIND_CONFIG -- Check for CONFIG= in environment block at ES:0
	 assume  ds:XGROUP,es:nothing,ss:nothing
COMMENT|

Check environment block at ES:0 for CONFIG=.  If found, copy its
value to MBOOT_SECTION.

On entry:
ES:0	 ==>	 Environment block.

On exit:
MBOOT_SECTION updated if found.

|

	 REGSAVE <ax,cx,si,ds,es> ; Save

; Look for CONFIG=
	 cld			; String ops forwardly
	 sub	 di,di		; Start at beginning
	 lea	 si,CONFIGSIG	; String to compare against
	 mov	 cx,8000h-@CONFIGLEN ; Maximum environment size less signature
	 lods	 CONFIGSIG[si]	; Get first byte to compare, advancing SI
@@:
  repne  scas	 es:[di].LO	; Find first byte
	 jne	 short FIND_CONFIG_EXIT ; Jump if not found

	 jcxz	 FIND_CONFIG_EXIT ; Jump if we're at the end

	 REGSAVE <cx,di>	; Save
	 mov	 cx,@CONFIGLEN-1 ; First byte has already been compared
  repe	 cmps	 CONFIGSIG[si],es:[di].LO ; Compare strings
	 REGREST <di,cx>	; Restore

	 loopne  @B		; Go around again if mismatch

	 jne	 short FIND_CONFIG_EXIT ; Jump if we didn't find it

; ES:DI ==> O in CONFIG=.  Copy to MBOOT_SECTION.
	 lea	 si,[di+@CONFIGLEN-1] ; Prepare to copy it
	 lea	 di,MBOOT_SECTION ; Address local copy
	 mov	 cx,@MBOOT_SECTIONLEN ; Maximum bytes to copy
	 push	 ds		; XGROUP segment
	 push	 es		; Env segment
	 pop	 ds		; Address source
	 pop	 es		; Address destination
	 assume  ds:nothing,es:XGROUP ; Tell the assembler

FIND_CONFIG_NEXT:
	 lods	 ds:[si].LO	; Get a byte
	 cmp	 al,'z'         ; Izit alphabetic?
	 ja	 short @F	; Jump if not

	 cmp	 al,'a'         ; Izit lowercase?
	 jb	 short @F	; Jump if not

	 and	 al,5Fh 	; Force uppercase
@@:
	 stos	 MBOOT_SECTION[di] ; Save it
	 or	 al,al		; Izit the end?
	 loopnz  FIND_CONFIG_NEXT ; Go around again

FIND_CONFIG_EXIT:
	 REGREST <es,ds,si,cx,ax> ; Restore
	 assume  ds:XGROUP,es:nothing ; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FIND_CONFIG endp		; End FIND_CONFIG procedure

	 FPPROC  INIT_MBOOT -- Find the current CONFIG= setting
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ferret out the current CONFIG= setting, convert it to uppercase,
and save it for CHECK_MBOOT.

On entry:
DS:SI ==>	 Device request header

On exit:
MBOOT_SECTION is unchanged (0) if MultiBoot not active.  Otherwise,
it contains the contents of the CONFIG= environment variable.

|

	 REGSAVE <ds,es>	; Save seg registers
	 pusha			; Save registers

	 cld			; String ops forwardly

	 push	 ds		; Get segment of request header
	 pop	 es		; Address for search
	 assume  es:nothing	; Tell the assembler

	 push	 seg XGROUP	; Prepare to address our code segment
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler

	 DOSCALL @DOSVER	; Return version in AL,AH
	 xchg	 ah,al		; Put in the proper order
	 cmp	 ax,0600h	; Izit DOS 6?
	 jc	 short INIT_MBOOT_EXIT ; Jump if not (MBOOT_SECTION[0] = 0)

ifdef @HARPO
; If this is HARPO, it might be INSTALL= time in which case the
; request header is NULL.
	 mov	 ax,es		; Get segment of request header
	 or	 ax,si		; Combine with offset
	 jnz	 short IMB_DEVICE ; Jump if valid

	 DOSCALL @GETPS0	; Return PSP in BX

	 mov	 es,bx		; Address PSP
	 assume  es:PSPGRP	; Tell the assembler

	 mov	 ax,PSP_ENVIR_PTR ; Get environment segment
	 or	 ax,ax		; Izit valid?
	 jz	 short INIT_MBOOT_EXIT ; Jump if not

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 jmp	 short IMB_COM	; Join common code

IMB_DEVICE:
endif				; IFDEF @HARPO
; Search ES:0 for the code at TARGET_CODE
	 sub	 di,di		; Starting offset to search
	 mov	 cx,@TARGET_CLEN ; Length of code to search for
	 sub	 bx,bx		; Limit is 64K
	 sub	 bx,cx		; Less length of search target
	 lea	 si,TARGET_CODE ; Code to search for
	 call	 CODESRCH	; ES:DI ==> matching object
	 jc	 short INIT_MBOOT_EXIT ; Jump if not found

; We're grabbing the offset from a mov cx,ds:[????] instruction.
; This offset points to a word containing the segment address of
; the temporary environment used during INSTALL= processing.
	 add	 di,@TENV_SRCOFF ; Address start of offset operand
	 mov	 bx,es:[di].ELO ; Get environment load segment offset
	 mov	 es,es:[bx].ELO ; Get environment load segment
	 assume  es:nothing	; Tell the assembler

IMB_COM:
; ES:0 ==> environment.  We need to hunt for CONFIG= since it's
; conceivable that someone could have shuffled the environment around.
	 call	 FIND_CONFIG	; Return ZR if we found it


INIT_MBOOT_EXIT:
	 popa			; Restore
	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT_MBOOT endp 		; End INIT_MBOOT procedure

	 NPPROC  CMP_SECT -- Compare section name
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Compare (case insensitive) section name terminated by ] against
specified section name.

On entry:
DS:SI ==>	Section name terminated by ]
XGROUP:BX ==>	Name to compare (in caps)

On exit:
ZF=1		Compared OK
ZF=0		Compare failed

|

	 REGSAVE <ax,bx,cx,si>	; Save

	 mov	 cx,@MBOOT_SECTIONLEN ; Maximum bytes to compare
CMP_SECT_NEXT:
	 lods	 ds:[si].LO	; Get next byte
; MAX has already converted everything to uppercase
;;;;;;;  cmp	 al,'z'         ; Izit alphabetic?
;;;;;;;  ja	 short @F	; Jump if not
;;;;;;;
;;;;;;;  cmp	 al,'a'         ; Izit lowercase?
;;;;;;;  jb	 short @F	; Jump if not
;;;;;;;
;;;;;;;  and	 al,5Fh 	; Force uppercase
;;;;;;;@@:
	 mov	 ah,XGROUP:[bx].LO ; Get byte to compare
	 inc	 bx		; Skip to next

	 cmp	 al,ah		; Do they match?
	 loope	 CMP_SECT_NEXT	; Go around again if so

; A mismatch occurred.	AH must be 0 and AL must be ']'.
	 cmp	 al,']'         ; Was it the end?
	 jne	 short CMP_SECT_EXIT ; Jump if not (note ZF=0)

	 or	 ah,ah		; Set ZF=1 if compare succeeded
CMP_SECT_EXIT:
	 REGREST <si,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMP_SECT endp			; End CMP_SECT procedure

	 FPPROC  CHECK_MBOOT -- Check for current line in active/common section
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check the current profile line.
  If it's a Multiboot section header enclosed in square brackets
  like [section_name],
    If it matches MBOOT_SECTION or 'COMMON',
      SKIPSECT = 0.
    else
      SKIPSECT = 1.
    endif * Matches / doesn't match current or common
    Skip the line
  else
    If SKIPSECT == 1,
      Skip the line
    else
      Process the line
    endif * SKIPSECT == 0 / 1
  endif * Multiboot section header

On entry:
  DS:SI  ==> First non-whitespace character on line.

On exit:
  CF=1	 Continue processing line
  CF=0	 Don't process line; it's a section header or doesn't belong
	 to the active or common sections.

|

	 REGSAVE <ax,bx,si,di,es> ; Save registers

	 cld			; String ops forwardly

	 lods	 ds:[si].LO	; Get first non-whitespace character
	 cmp	 al,'['         ; Izit a Multiboot section name?
	 jne	 short CHECK_MBOOT_NOTSECT ; Jump if not

; DS:SI ==> First character of section name.  Check for common.
; Note that if someone has sections but Multiboot is not active,
; we'll only process common sections.
	 lea	 bx,XGROUP:CMP_COMMON ; Check for '[common]'
	 call	 CMP_SECT	; Return ZR if match occurred
	 je	 short @F	; Jump if comparison succeeded

	 lea	 bx,XGROUP:MBOOT_SECTION ; Check for active section
	 call	 CMP_SECT	; Return ZR if match occurred

@@:
	 setnz	 SKIPSECT	; SKIPSECT=1 if comparisons failed

	 clc			; Skip this line
	 jmp	 short CHECK_MBOOT_EXIT ; Join common exit (note CF=0)

CHECK_MBOOT_NOTSECT:
	 cmp	 SKIPSECT,1	; Set CF=1 if we're processing this section

CHECK_MBOOT_EXIT:
	 REGREST <es,di,si,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_MBOOT endp		; End CHECK_MBOOT procedure

XCODE	 ends			; End XCODE segment

	 MEND			; End QMAX_MBT module
