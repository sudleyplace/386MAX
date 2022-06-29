;' $Header:   P:/PVCS/MAX/386MAX/QMAX_PDT.ASV   1.2   30 May 1997 10:45:52   BOB  $
	 title	 QMAX_PDT -- 386MAX PDT Functions
	 page	 58,122
	 name	 QMAX_PDT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group FGROUP:
	       Data    segment FDATA, dword-aligned, public, class 'fixup'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC

	 include QMAX_DTE.INC
	 include QMAX_OEM.INC

	 include PDTGRP.INC
.list

PGROUP	 group	 CODE,ECODE,EDATA
FGROUP	 group	 FDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 LCL_CR3:dword

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 CR2_PTE:dword
;;;;;;;; extrn	 LOWOFF:dword
;;;;;;;; extrn	 PRGSIZE:word
	 extrn	 PRGPDT:dword

;;;;;;;; extrn	 CON4KB:dword
;;;;;;;; extrn	 CON1MB:dword

	 extrn	 PPDT1MB:dword
	 extrn	 PPDTBACK:dword
;;;;;;;; extrn	 PPDTRSV:dword
	 extrn	 PPDTMISS:dword
	 extrn	 PPDTCNVZ:dword

	 public  WRAPTAB
WRAPTAB  dd	 16 dup (?)	; 1MB wrap entries

	 public  WRAPWTK
WRAPWTK  label	 dword		; 1MB wrap entries when Weitek 1167 installed

CNT	 =	 0

	 rept	 16
	 dd	 0C0000000h + 4*1024*CNT + @PTE_URP + (mask $PTE_CD)
CNT	 =	 CNT+1
	 endm

	 public  MISSPTE
MISSPTE  dd	 -1		; Missing PTE

	 public  PTE_FLAG
	 include QMAX_PTE.INC
PTE_FLAG dw	 0

EDATA	 ends			; End EDATA segment


FDATA	 segment use16 dword public 'fixup' ; Start FDATA segment
	 assume  ds:FGROUP

	 extrn	 MSG_DMAPAGE:byte

if @OEM_DEBUG
	 public  INT0E_DMAPAGE
INT0E_DMAPAGE db 'DMA page err',0
endif				; IF @OEM_DEBUG

FDATA	 ends			; End FDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_PDT_ECODE
@QMAX_PDT_ECODE:		; Mark module start in .MAP file

	 extrn	 INTXXCOM:near

	 NPPROC  WRAP_SWAP -- Swap 1MB Wrap Table Entries
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Swap the 1MB wrap table entries.

|

	 REGSAVE <eax,ebx,cx,si,di> ; Save registers

	 mov	 cx,64/4	; # 4KB pages in the 64KB
	 mov	 ebx,PPDT1MB	; EBX ==> offset in PDT of 1MB entries
	 add	 ebx,PRGPDT	; Plus offset of PDT in PGROUP
				; PGROUP:EBX ==> offset in PGROUP of 1MB entries
	 lea	 si,WRAPTAB	; PGROUP:SI ==> 1MB wrap table

	 test	 GLB_FLAG,@GLB_WTK ; Is the Weitek active?
	 jz	 short WRAP_SWAP_TAB ; No, use the usual table

	 lea	 si,WRAPWTK	; PGROUP:SI ==> 1MB wrap table for Weitek
WRAP_SWAP_TAB:
	 mov	 di,si		; PGROUP:DI ==> ...
	 cld			; String ops forwardly
WRAP_SWAP_NEXT:
	 lods	 PGROUP:[si].PDT_PTE ; Get the wrap table entry

	 xchg	 eax,PGROUP:[ebx].PDT_PTE ; Swap with current PTE

S16	 stos	 PGROUP:[di].PDT_PTE ; Save back into wrap table

	 add	 ebx,type PDT_PTE ; Skip to next entry in PTE

	 loop	 WRAP_SWAP_NEXT ; Jump if more entries to swap

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB

	 and	 GLB_FLAG,not @GLB_TLB ; Clear for next time

	 REGREST <di,si,cx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRAP_SWAP endp			; End WRAP_SWAP procedure
	 NPPROC  WRAP_ENABLE -- Enable 1MB Wrap
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Enable the 1MB wrap.

On exit:

CF	 =	 0 if we flushed the TLB
	 =	 1 if we didn't

|

; Izit forced disabled, already enabled, or not sensitive?

;;;;;;;; test	 GLB_FLAG,@GLB_X1MB or @GLB_1MB or @GLB_XWRP
	 test	 GLB_FLAG,@GLB_X1MB or @GLB_1MB
	 jnz	 short WRAP_ENABLE_SKIP ; Yes, skip it (note CF=0)

	 test	 LCL_FLAG,@LCL_WRP ; Is WRAPTAB initialized?
	 jz	 short WRAP_ENABLE_SKIP ; No, so skip it (note CF=0)

	 pushf			; Save flags

	 cli			; Disable interrupts

	 push	 es		; Save for a moment

	 push	 DTE_DS 	; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 WRAP_SWAP	; Swap the 1MB wrap table entries

	 or	 GLB_FLAG,@GLB_1MB ; Mark as enabled

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 popf			; Restore flags

	 stc			; Indicate we flushed the TLB
WRAP_ENABLE_SKIP:
	 cmc			; Indicate we didn't flush the TLB

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRAP_ENABLE endp		; End WRAP_ENABLE procedure
	 NPPROC  WRAP_DISABLE -- Disable 1MB Wrap
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable the 1MB wrap.

On exit:

CF	 =	 0 if we flushed the TLB
	 =	 1 if we didn't

|

;;;;;;;; test	 GLB_FLAG,@GLB_X1MB or @GLB_XWRP ; Izit sensitive?
	 test	 GLB_FLAG,@GLB_X1MB ; Izit sensitive?
	 jnz	 short WRAP_DISABLE_SKIP ; No, skip it (note CF=0)

	 test	 GLB_FLAG,@GLB_1MB ; Izit already disabled?
	 jz	 short WRAP_DISABLE_SKIP ; Yes, no need to do it again (note CF=0)

	 test	 LCL_FLAG,@LCL_WRP ; Is WRAPTAB initialized?
	 jz	 short WRAP_DISABLE_SKIP ; No, so skip it (note CF=0)

	 pushf			; Save flags

	 cli			; Disable interrupts

	 push	 es		; Save for a moment

	 push	 DTE_DS 	; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 WRAP_SWAP	; Swap the 1MB wrap table entries

	 and	 GLB_FLAG,not @GLB_1MB ; Mark as disabled

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 popf			; Restore flags

	 stc			; Indicate we flushed the TLB
WRAP_DISABLE_SKIP:
	 cmc			; Indicate we didn't flush the TLB

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WRAP_DISABLE endp		; End WRAP_DISABLE procedure
	 NPPROC  FLUSH_TLB -- Flush Translation Lookaside Buffer
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Flush the translation lookaside buffer by respecifying the
Page Descriptor Base Register.

|

	 push	 eax

	 mov	 eax,LCL_CR3	; Get contents of CR3
	 mov	 cr3,eax	; Set it again to flush cache

	 pop	 eax

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FLUSH_TLB endp			; End FLUSH_TLB procedure
	 NPPROC  FIND_PTE -- Find PTE in PDT
	 assume  ds:nothing,es:nothing,fs:PDTGRP,gs:nothing,ss:PGROUP
COMMENT|

On entry:

FIND_PTE_PTE =	 PTE to find in PDT

On exit:

CF	 =	 1 PTE not found,
	 =	 0 all went ok
ESI	 =	 offset in PDT of the matching PTE

|

FIND_PTE_STR struc

FIND_PTE_EBP dd  ?		; Caller's EBP
	 dw	 ?		; Caller's IP
FIND_PTE_PTE dd  ?		; The PTE to search for

FIND_PTE_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <ecx,edx>	; Save registers

	 and	 PTE_FLAG,not @PTE_MISS ; Reset flags

	 mov	 edx,[ebp].FIND_PTE_PTE ; Get the PTE to search for

; Ensure the entry we find is valid by setting the bits in EDX

	 or	 dx,@PTE_URP	; Mark as User/Read-write/Present

	 mov	 esi,PPDTBACK	; FS:ESI ==> end of PDT backfill (multiple of 4KB in 4KB in dwords)
	 mov	 ecx,PPDTCNVZ	; Get offset of end of conventional entries (multiple of 4KB in 4KB in dwords)
	 sub	 ecx,esi	; Less start of table
	 shr	 ecx,12-(12-2)	; Convert from 4KB in dwords to 4KB

; Search for EDX in the PDT -- return that offset in ESI
; Start at FS:ESI for ECX entries

	 call	 FIND_PTE_SUB	; Find it
	 jnc	 short FIND_PTE_EXIT  ; Jump if found

	 test	 PTE_FLAG,@PTE_SWAP ; Doing SWAP_MEM?
	 jnz	 short FIND_PTE_PHYS  ; Yes, return pseudo-offset

	 test	 PTE_FLAG,@PTE_TEST ; Testing PTEs?
	 jnz	 short FIND_PTE_MISS  ; Yes, just mark it as missing

	 mov	 cr2,edx	; Save in control register
	 mov	 CR2_PTE,esi	; Save start

	 mov	 ebp,[ebp].FIND_PTE_EBP ; Restore caller's EBP
	 mov	 si,[ebp].INTXX_INTNO ; Get caller's interrupt # times 4
	 lea	 bx,FGROUP:MSG_DMAPAGE ; Offset of message to display to user

if @OEM_DEBUG
	 lea	 di,FGROUP:INT0E_DMAPAGE ; Offset of message to display on screen
endif				; IF @OEM_DEBUG

	 jmp	 INTXXCOM	; Join common code

FIND_PTE_PHYS:
	 mov	 esi,PPDTMISS	; FS:ESI ==> missing PTE save area
	 mov	 OFFPDT[esi],edx ; Save PTE
FIND_PTE_MISS:
	 mov	 MISSPTE,edx	; Save for debugging
	 or	 PTE_FLAG,@PTE_MISS ; Note one is missing

	 stc			; Indicate not found
FIND_PTE_EXIT:
	 REGREST <edx,ecx>	; Restore

	 pop	 ebp		; Restore

	 ret	 1*4		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_PTE endp			; End FIND_PTE procedure
	 NPPROC  FIND_PTE_SUB -- Find A PTE
	 assume  ds:nothing,es:nothing,fs:PDTGRP,gs:nothing,ss:nothing
COMMENT|

On entry:

FS:ESI	 ==>	 start searching here
ECX	 =	 # entries to search through
EDX	 =	 PTE to find

On exit:

CF	 =	 1 PTE not found,
	 =	 0 all went ok
ESI	 =	 offset in PDT of the matching PTE

|

	 REGSAVE <eax,ecx>	; Save registers
FIND_PTE_SUB_SRCH:
	 mov	 eax,OFFPDT[esi] ; Get PTE

; Isolate the address but don't confuse with non-physical or mapped memory

	 and	 ax,(mask $PTE_FRM) or (mask $PTE_AV1) or (mask $PTE_AV0) or @PTE_URP

	 cmp	 eax,edx	; Same address?
	 je	 short FIND_PTE_SUB_FOUND ; Yes, we found it

	 add	 esi,4		; Bump to next PTE

	 loopd	 FIND_PTE_SUB_SRCH ; Jump if more 4KB pages to check

	 stc			; Indicate PTE not found

	 jmp	 short FIND_PTE_SUB_EXIT ; Join common exit code

FIND_PTE_SUB_FOUND:
	 clc			; Indicate PTE found
FIND_PTE_SUB_EXIT:
	 REGREST <ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND_PTE_SUB endp		; End FIND_PTE_SUB procedure
;;;	     NPPROC  TEST_PTE -- Test PTEs
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Test PTEs to ensure they're all there
;;;
;;; |
;;;
;;;	     REGSAVE <eax,ecx,esi,ds> ; Save registers
;;;
;;;	     push    DTE_DS	    ; Get our data selector
;;;	     pop     ds 	    ; Address it
;;;	     assume  ds:PGROUP	    ; Tell the assembler about it
;;;
;;;	     or      PTE_FLAG,@PTE_TEST ; Mark as testing PTEs
;;;
;;; ; Test physical chips on system board
;;;
;;;	     xor     eax,eax	    ; Start with 00000000
;;;	     mov     cx,LOWOFF.ELO  ; Get # 1KB blocks of system board memory
;;;
;;;	     test    LCL_FLAG,@LCL_LML ; Low memory load?
;;;	     jz      short TEST_PTE1 ; Not this time
;;;
;;;	     sub     cx,PRGSIZE     ; Less program size
;;; TEST_PTE1:
;;;	     shr     cx,12-10	    ; Convert from 1KB to 4KB
;;; TEST_PTE_NEXT1:
;;;	     push    eax	    ; Pass PTE as argument
;;;	     call    FIND_PTE	    ; Find PTE in the PDT, return offset in ESI
;;;				    ; assume ss:PGROUP
;;;				    ; Ignore value returned in ESI
;;;
;;;	     test    PTE_FLAG,@PTE_MISS ; Is one missing?
;;;	     jnz     short TEST_PTE_MISS ; Yes
;;;
;;;	     add     eax,CON4KB     ; Skip to next 4KB page
;;;
;;;	     loop    TEST_PTE_NEXT1 ; Jump if more PTEs on system board
;;;
;;; ; Test physical chips from start of PDT to PPDTRSV
;;;
;;;	     mov     eax,CON1MB     ; Start at 1MB
;;;	     mov     ecx,PPDTRSV    ; Get offset of reserved area (multiple of 4KB in 4KB in dwords)
;;;	     sub     ecx,1024	    ; Less the first megabyte
;;;	     shr     ecx,12-(12-2)  ; Convert from 4KB in dwords to 4KB
;;; TEST_PTE_NEXT2:
;;;	     push    eax	    ; Pass PTE as argument
;;;	     call    FIND_PTE	    ; Find PTE in the PDT, return offset in ESI
;;;				    ; assume ss:PGROUP
;;;				    ; Ignore value returned in ESI
;;;
;;;	     test    PTE_FLAG,@PTE_MISS ; Is one missing?
;;;	     jnz     short TEST_PTE_MISS ; Yes
;;;
;;;	     add     eax,CON4KB     ; Skip to next 4KB page
;;;
;;;	     loopd   TEST_PTE_NEXT2 ; Jump if more PTEs on system board
;;;
;;;	     jmp     short TEST_PTE_EXIT ; Join common code
;;;
;;; TEST_PTE_MISS:		    ; A PTE is missing!!
;;;	     and     PTE_FLAG,not @PTE_MISS ; Reset flag
;;;	     or      GLB_FLAG,@GLB_NMI ; Mark as NMI occurring
;;; TEST_PTE_EXIT:
;;;	     and     PTE_FLAG,not @PTE_TEST ; Reset flag
;;;
;;;	     REGREST <ds,esi,ecx,eax> ; Restore
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; TEST_PTE endp		    ; End TEST_PTE procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment

	 MEND			; End QMAX_PDT module
