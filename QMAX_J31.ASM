;' $Header:   P:/PVCS/MAX/386MAX/QMAX_J31.ASV   1.2   30 May 1997 10:45:22   BOB  $
	 title	 QMAX_J31 -- 386MAX INT 31h Additional Routines
	 page	 58,122
	 name	 QMAX_J31

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-8 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Program segment LCODE, dword-aligned, public, class 'icode'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'

Program derived from:  None.

Original code by:  Bob Smith, June 1991.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include 386.INC
	 include PTR.INC
	 include CPUFLAGS.INC
	 include BITFLAGS.INC
	 include ALLMEM.INC
	 include MAC.INC
	 include MASM5.MAC

	 include QMAX_OEM.INC
	 include QMAX_DTE.INC
	 include QMAX_I31.INC
	 include QMAX_TSS.INC
	 include QMAXDPMI.INC
.list

if @OEM_DPMI

PGROUP	 group	 CODE,ECODE,EDATA
IGROUP	 group	 ICODE,LCODE
JGROUP	 group	 JCODE


LCODE	 segment use16 dword public 'icode' ; Start LCODE segment
	 assume  cs:IGROUP

	 extrn	 GETSELBASE:far

LCODE	 ends			; End LCODE segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 P1ST_MAC:dword
	 extrn	 POVR_MAC:word

CODE	 ends			; End CODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 FSET_GDT:far

ECODE	 ends			; End ECODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 I31_FLAG:word
	 extrn	 DPM_FLAG:word
	 extrn	 DPMITYPE:byte
	 extrn	 CON64KB:dword
	 extrn	 CON1MB:dword
	 extrn	 DESC_TAB:qword
	 extrn	 SEL_4GB3:word
	 extrn	 PCURTSS:dword

	 extrn	 DPMI_CODE:word
	 extrn	 DPMI_DATA:word
	 extrn	 DPMI_DPL:byte

	 public  PDPMILDT
PDPMILDT dd	 ?		; Offset in PGROUP of DPMI LDT

@LDT_SIZ equ	 @NLDTE_DEF*(type DESC_STR) ; Byte size of DPMI LDT (/8)
@XLDT_SIZ equ	 @LDT_SIZ+(((8*8-1)+@NLDTE_DEF)/(8*8))*8 ; Count in one bit
				; per qword rounded up to next qword
@XLDT_RND equ	 (@XLDT_SIZ+(@DPMI_BOUND-1)) and not (@DPMI_BOUND-1)

	 public  LDT_SIZ,XLDT_SIZ
LDT_SIZ  dd	 @LDT_SIZ	; Byte size of initial and resident DPMI LDT (/8)
				; never bigger than 64KB
XLDT_SIZ dd	 @XLDT_RND	; Byte size of initial extended LDT (/@DPMI_BOUND)
				; (including trailing bitmap)

EDATA	 ends			; End EDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 public  @QMAX_J31_ICODE
@QMAX_J31_ICODE:		; Mark module start in .MAP file

	 extrn	 VALID_LSEL:near
	 extrn	 GET_LDT:near
	 extrn	 CLR_LDTZERO:near
	 extrn	 GETSET_LDTFIX:near
	 extrn	 GETLBASE:near
	 extrn	 SETLBASE:near
	 extrn	 DPMIFN_DTECACHE:near

	 extrn	 INT31_CLC:near
	 extrn	 INT31_ERR_MAC:near
	 extrn	 INT31_ERR_MNF:near
	 extrn	 INT31_ERR_NODMEM:near
	 extrn	 INT31_ERR_NOSEL:near
	 extrn	 INT31_ERR_INVSEL:near
	 extrn	 INT31_ERR_INVVAL:near

	 FPPROC  FDPMIFN_CHKACCESS -- Check A/R Byte - far version
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check A/R byte

On entry:

Same as DPMIFN_CHKACCESS

On exit:

Same as DPMIFN_CHKACCESS

|

	 call	 DPMIFN_CHKACCESS ; Check it out

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDPMIFN_CHKACCESS endp		; End FDPMIFN_CHKACCESS procedure
	 NPPROC  DPMIFN_CHKACCESS -- Check A/R Byte
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check A/R byte

On entry:

AL	 =	 A/R byte to check

On exit:

AH	 =	 clobbered
CF	 =	 0 if valid
	 =	 1 if not

|

	 test	 al,mask $DT_DC ; Check must-be-1-bit
	 jz	 short DPMIFN_CHKACCESS_ERR ; Jump if invalid

	 test	 I31_FLAG,mask $I31_DUSE ; Enforce descriptor usage rules?
	 jz	 short @F	; Jump if not

	 mov	 ah,al		; Copy for testing
	 and	 ah,mask $DT_DPL ; Isolate DPL bits

	 cmp	 ah,DPMI_DPL	; Ensure it's DPMI DPL
	 jne	 short DPMIFN_CHKACCESS_ERR ; Jump if invalid
@@:

; If present and code, ensure readable and non-conforming

	 test	 al,mask $DT_P	; Izit present?
	 jz	 short DPMIFN_CHKACCESS_EXIT ; Jump if not (note CF=0)

	 test	 al,mask $DC_COD ; Izit code?
	 jz	 short DPMIFN_CHKACCESS_EXIT ; Jump if not (note CF=0)

	 mov	 ah,al		; Copy for testing
	 and	 ah,not (mask $DT_DPL) ; Clear DPL bits
	 or	 ah,DPMI_DPL	; Ensure proper DPL
	 and	 ah,not (mask $DD_ACC) ; Clear accessed bit

; Ensure present code is readable and non-conforming code

	 cmp	 ah,DPMI_CODE.LO ; Izit?
	 je	 short DPMIFN_CHKACCESS_EXIT ; Jump if valid (note CF=0)
DPMIFN_CHKACCESS_ERR:
	 stc			; Mark as invalid
DPMIFN_CHKACCESS_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_CHKACCESS endp		; End DPMIFN_CHKACCESS procedure
	 NPPROC  DPMIFN_CHKSEGLM1 -- Check Segment Limit Flags
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Validate the segment limit flags

On entry:

AL	 =	 flags to check

On exit:

CF	 =	 0 if valid
	 =	 1 if not

|

	 test	 I31_FLAG,mask $I31_DUSE ; Enforce descriptor usage rules?
	 jz	 short @F	; Jump if not (note CF=0)

	 test	 al,mask $DTE_0 ; Ensure must be 0 bit is 0
	 jz	 short @F	; Jump if valid (note CF=0)

	 stc			; Mark as invalid
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_CHKSEGLM1 endp		; End DPMIFN_CHKSEGLM1 procedure
	 NPPROC  DPMI_GETLDT -- DPMI 0.9 Function to Allocate LDT Selectors
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to allocate LDT selectors

On entry (in INTXX_STR):

AX	 =	 0000h
CX	 =	 # LDT selectors to allocate
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
AX	 =	 base selector (if successful)

CF	 =	 1 if not successful
AX	 =	 8011 if descriptor unavailable

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 cx,[ebp].INTXX_ECX.ELO ; Get # selectors to allocate
	 jcxz	 DPMI_GETLDT_EXIT ; Jump if none (should this be an error?)

	 push	 0		; Mark as not segment-to-selector
	 push	 cx		; # selectors to allocate
	 call	 GET_LDT	; Get next LDT selector in EAX ($TI and $PL set)
				; and LDTE marked as CPL3_DATA
	 jc	 near ptr INT31_ERR_NOSEL ; Jump if not available

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Return in caller's AX
DPMI_GETLDT_EXIT:
	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETLDT endp		; End DPMI_GETLDT procedure
	 NPPROC  DPMI_RELLDT -- DPMI 0.9 Function to Release an LDT Selector
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to release an LDT selector

On entry (in INTXX_STR):

AX	 =	 0001h
BX	 =	 LDT selector to release
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8022 if invalid selector

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get selector to free

	 push	 @BIT0		; Ensure it's modifiable
	 push	 bx		; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if something went wrong

	 push	 bx		; Get selector to free
	 call	 CLR_LDTZERO	; Free this LDT selector & zero selectors
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if something went wrong

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_RELLDT endp		; End DPMI_RELLDT procedure
	 NPPROC  DPMI_SEG2SEL -- DPMI 0.9 Function to Map a Segment to an LDT Selector
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to map a segment to an LDT selector

On entry (in INTXX_STR):

AX	 =	 0002h
BX	 =	 segment #
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
AX	 =	 selector

CF	 =	 1 if not successful
AX	 =	 8011 if descriptor unavailable

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 movzx	 eax,[ebp].INTXX_EBX.ELO ; Get the segment #
	 shl	 eax,4-0	; Convert from paras to bytes

; Set B-bit for data selectors if it's not a 16-bit app

	 mov	 cl,DPMI_DATA.LO ; Get A/R byte for 16-bit app

	 cmp	 DPMITYPE,@DPMITYPE16 ; Izit a 16-bit client?
	 setne	 ch		; CH = 1 if 32-bit or no DPMI
				;    = 0 if 16-bit
	 shl	 ch,$DTE_B	; Set B-bit for 32-bit apps

	 push	 cx		; Pass A/R word
	 push	 CON64KB	; Pass segment length in bytes
	 push	 eax		; Pass base address
	 call	 GETSET_LDTFIX	; Return with EAX = selector ($TI and $PL set)
	 jc	 near ptr INT31_ERR_NOSEL ; Jump if not available

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Return in caller's AX

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_SEG2SEL endp		; End DPMI_SEG2SEL procedure
	 NPPROC  DPMI_NXTSEL -- DPMI 0.9 Function to Get Selector Increment Value
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to get selector increment value

On entry (in INTXX_STR):

AX	 =	 0003h
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
AX	 =	 selector increment value

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 [ebp].INTXX_EAX.ELO,size DESC_STR ; Return in caller's AX

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_NXTSEL endp		; End DPMI_NXTSEL procedure
	 NPPROC  DPMI_GSELBAS -- DPMI 0.9 Function to Get Selector Base
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to get selector base

On entry (in INTXX_STR):

AX	 =	 0006h
BX	 =	 LDT selector
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
CX:DX	 =	 selector base

CF	 =	 1 if not successful
AX	 =	 8022 if invalid selector

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 push	 0		; Ignore modifiable check
	 push	 [ebp].INTXX_EBX.ELO ; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if not valid

	 push	 [ebp].INTXX_EBX.ELO ; Pass the selector
	 call	 GETLBASE	; Return with EAX = base address from LDT

	 mov	 [ebp].INTXX_EDX.ELO,ax ; Return low-order in DX
	 shr	 eax,16 	; Shift down high-order word
	 mov	 [ebp].INTXX_ECX.ELO,ax ; ...	 high-..      CX

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GSELBAS endp		; End DPMI_GSELBAS procedure
	 NPPROC  DPMI_SSELBAS -- DPMI 0.9 Function to Set Selector Base
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to set selector base

On entry (in INTXX_STR):

AX	 =	 0007h
BX	 =	 LDT selector
CX:DX	 =	 selector base
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8022 if invalid selector
	 =	 8025 if invalid address

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 ax,[ebp].INTXX_ECX.ELO ; Get high-order word from CX
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_EDX.ELO ; Get low-order word from DX

;;; ; Ensure the resulting selector range is outside MINBASE through TOPBASE
;;;
;;;	     cmp     eax,TOPBASE    ; Check against our top limit
;;;	     jae     short @F	    ; Jump if it's beyond our limits
;;;
;;;	     movzx   ebx,[ebp].INTXX_EBX.ELO ; Get the selector
;;;	     lsl     ebx,ebx	    ; Get the selector limit
;;;	     nop		    ; Errata # ??
;;;	     jnz     short @F	    ; Jump if it's invalid
;;;
;;;	     add     ebx,eax	    ; Add to get highest address for this selector
;;;
;;;	     cmp     ebx,MINBASE    ; Check against lower bound
;;;	     jae     near ptr INT31_ERR_INVADDR ; Jump if it's within our limits
;;; @@:
;;;
; Validate the selector

	 mov	 bx,[ebp].INTXX_EBX.ELO ; Get the selector

	 push	 @BIT0		; Ensure it's modifiable
	 push	 bx		; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if not valid

; Attempt to set the base address

	 push	 bx		; Pass the selector
	 call	 SETLBASE	; Set selector base to EAX
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if not valid

; Ensure invisible descriptor caches are reset

	 call	 DPMIFN_DTECACHE ; Reset 'em

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_SSELBAS endp		; End DPMI_SSELBAS procedure
	 NPPROC  DPMI_SSELLIM -- DPMI 0.9 Function to Set Selector Limit
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to set selector limit

On entry (in INTXX_STR):

AX	 =	 0008h
BX	 =	 LDT selector
CX:DX	 =	 selector limit
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8021 if invalid value
	 =	 8022 if invalid selector
	 =	 8025 if invalid address

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Validate the selector

	 movzx	 ebx,[ebp].INTXX_EBX.ELO ; Get the selector

	 push	 @BIT0		; Ensure it's modifiable
	 push	 bx		; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if not valid

	 and	 bx,not ((mask $TI) or (mask $PL)) ; Clear TI and PL bits
	 mov	 eax,PCURTSS	; Get offset in PGROUP of the current TSS
	 add	 ebx,PGROUP:[eax].DPTSS_LaLDT ; Plus linear address of DPMI LDT

	 mov	 dx,[ebp].INTXX_ECX.ELO ; Get high-order word from CX
	 shl	 edx,16 	; Shift to high-order word
	 mov	 dx,[ebp].INTXX_EDX.ELO ; Get low-order word from DX

; If the incoming limit is > 1MB, then the low-order 12 bits must be set

; Check incoming limit against 1MB break point

	 cmp	 edx,CON1MB	; Izit bigger than a breadbox?
	 jb	 short DPMI_SSELLIM1 ; Jump if not

; Ensure all 12 low-order bits are set

	 xor	 dx,0FFFh	; Complement 'em

	 test	 dx,0FFFh	; Ensure all clear (previously set)
	 jnz	 near ptr INT31_ERR_INVVAL ; Jump if invalid

	 shr	 edx,12-0	; Convert from bytes to 4KB
	 or	 edx,(mask $DTE_G) shl (8*(DESC_SEGLM1-DESC_BASE2)) ; Set G-bit
DPMI_SSELLIM1:

;;; ; Ensure selector is valid and that the resulting selector
;;; ; range is outside MINBASE through TOPBASE
;;;
;;;	     push    [ebp].INTXX_EBX.ELO ; Pass the selector
;;;	     call    GETLBASE	    ; Return with EAX = base address from LDT
;;;
;;;	     cmp     eax,TOPBASE    ; Check against our top limit
;;;	     jae     short @F	    ; Jump if it's beyond our limits
;;;
;;;	     movzx   ebx,[ebp].INTXX_EBX.ELO ; Get the selector
;;;	     lsl     ebx,ebx	    ; Get the selector limit
;;;	     nop		    ; Errata # ??
;;; ;;;;;;;; jnz     short @F	    ; Jump if it's invalid (can't happen)
;;;
;;;	     add     ebx,eax	    ; Add to get highest address for this selector
;;;
;;;	     cmp     ebx,MINBASE    ; Check against lower bound
;;;	     jae     near ptr INT31_ERR_INVADDR ; Jump if it's within our limits
;;; @@:

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 AGROUP:[ebx].DESC_SEGLM0,dx ; Save limit bits 0-15
	 shr	 edx,16 	; Shift down high-order word

; Clear segment limit bits 16-19 and the G-bit

	 and	 AGROUP:[ebx].DESC_SEGLM1,not ((mask $DTE_G) or (mask $SEGLM1))
	 or	 AGROUP:[ebx].DESC_SEGLM1,dl ; Save limit bits 16-19

; Ensure invisible descriptor caches are reset

	 call	 DPMIFN_DTECACHE ; Reset 'em

	 popf			; Restore
				; (note interrupts might become enabled)
	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_SSELLIM endp		; End DPMI_SSELLIM procedure
	 NPPROC  DPMI_SSELARW -- DPMI 0.9 Function to Set Selector A/R Word
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to set selector A/R word

On entry (in INTXX_STR):

AX	 =	 0009h
BX	 =	 LDT selector
CL	 =	 A/R byte
CH	 =	 extended flags
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8021 if invalid value
	 =	 8022 if invalid selector
	 =	 8025 if invalid address

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Validate the A/R byte

	 mov	 al,[ebp].INTXX_ECX.ELO.LO ; Get the A/R byte
	 call	 DPMIFN_CHKACCESS ; Check it out
	 jc	 near ptr INT31_ERR_INVVAL ; Jump if invalid

; Validate the selector

	 movzx	 ebx,[ebp].INTXX_EBX.ELO ; Get the selector

	 push	 @BIT0		; Ensure it's modifiable
	 push	 bx		; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if not valid

	 and	 bx,not ((mask $TI) or (mask $PL)) ; Clear TI and PL bits
	 mov	 eax,PCURTSS	; Get offset in PGROUP of the current TSS
	 add	 ebx,PGROUP:[eax].DPTSS_LaLDT ; Plus linear address of DPMI LDT

; Validate the extended flags

	 mov	 al,[ebp].INTXX_ECX.ELO.HI ; Get extended flags
	 call	 DPMIFN_CHKSEGLM1 ; Check it out
	 jc	 near ptr INT31_ERR_INVVAL ; Jump if invalid

	 pushf			; Save flags
	 cli			; Disallow interrupts

; Save data into LDT

	 mov	 ax,[ebp].INTXX_ECX.ELO ; AL = A/R byte
					; AH = extended flags
; In case we skipped checking the selector's DPL, ensure it has the
; proper value now.

	 and	 al,not (mask $DT_DPL) ; Clear DPL bits
	 or	 al,DPMI_DPL	; Ensure proper DPL

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 AGROUP:[ebx].DESC_ACCESS,al ; Save the A/R byte

	 and	 ah,not (mask $SEGLM1) ; Clear segment limit bits
	 and	 AGROUP:[ebx].DESC_SEGLM1,mask $SEGLM1 ; Isolate segment limit 16-19
	 or	 AGROUP:[ebx].DESC_SEGLM1,ah ; Save extended flags

; Ensure invisible descriptor caches are reset

	 call	 DPMIFN_DTECACHE ; Reset 'em

	 popf			; Restore flags
				; (note interrupts might become enabled)
	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_SSELARW endp		; End DPMI_SSELARW procedure
	 NPPROC  DPMI_GETALIAS -- DPMI 0.9 Function to Get Selector Alias
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to get selector alias

On entry (in INTXX_STR):

AX	 =	 000Ah
BX	 =	 LDT selector
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8011 if descriptor unavailable
	 =	 8022 if invalid selector

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Validate the selector

	 movzx	 ebx,[ebp].INTXX_EBX.ELO ; Get the selector

	 push	 0		; Ignore modifiable check
	 push	 bx		; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if not valid

	 bt	 bx,$TI 	; Ensure it's in the LDT (VALID_LSEL allows DTE_BDA)
	 jnc	 near ptr INT31_ERR_INVSEL ; Jump if not valid

	 push	 0		; Mark as not segment-to-selector
	 push	 1		; # selectors to allocate
	 call	 GET_LDT	; Get next LDT selector in EAX ($TI and $PL set)
				; and LDTE marked as CPL3_DATA
	 jc	 near ptr INT31_ERR_NOSEL ; Jump if not available

; Return selector to caller

	 mov	 [ebp].INTXX_EAX.ELO,ax ; Return it

; Set new selector to same base and limit as the specified one

	 mov	 esi,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 esi,PGROUP:[esi].DPTSS_LaLDT ; Get linear address of DPMI LDT

	 and	 bx,not ((mask $TI) or (mask $PL)) ; Clear TI and PL bits
	 and	 ax,not ((mask $TI) or (mask $PL)) ; Clear TI and PL bits

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edx,AGROUP:[esi+ebx].EDQLO ; Get low-order dword
	 mov	 AGROUP:[esi+eax].EDQLO,edx ; Save for new selector

	 mov	 edx,AGROUP:[esi+ebx].EDQHI ; Get high-order dword
	 mov	 AGROUP:[esi+eax].EDQHI,edx ; Save for new selector

; Ensure that it's a data selector

	 mov	 bl,DPMI_DATA.LO ; Get A/R byte for 16-bit app
	 mov	 AGROUP:[esi+eax].DESC_ACCESS,bl ; Set it

	 popf			; Restore flags
				; (note interrupts might become enabled)
	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETALIAS endp		; End DPMI_GETALIAS procedure
	 NPPROC  DPMI_GETLDTE -- DPMI 0.9 Function to Get LDT Entry
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to get LDT entry

On entry (in INTXX_STR):

AX	 =	 000Bh
BX	 =	 LDT selector
ES:eDI	 ==>	 output save area
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8022 if invalid selector

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Validate the selector

	 movzx	 ebx,[ebp].INTXX_EBX.ELO ; Get the selector

	 push	 0		; Ignore modifiable check
	 push	 bx		; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if not valid

	 and	 bx,not (mask $PL) ; Clear PL bits

	 lea	 esi,DESC_TAB	; Get offset in PGROUP of GDT

	 btr	 bx,$TI 	; Izit in the LDT?
	 jnc	 short @F	; Jump if not

	 mov	 esi,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 esi,PGROUP:[esi].DPTSS_LaLDT ; Get linear address of DPMI LDT

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it
@@:
	 assume  ds:nothing	; Tell the assembler about it

; Because DS can point to either PGROUP or AGROUP,
; we remove the ASSUME on it to avoid mistakes.

	 add	 esi,ebx	; Add base address to get to LDTE
				; DS:ESI ==> LDTE
	 mov	 edi,[ebp].INTXX_EDI ; Get caller's eDI
	 IF16ZX  di		; Zero to use as dword if 16-bit client

	 mov	 es,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  es:nothing	; Tell the assembler about it

	 pushf			; Save flags
	 cli			; Disallow interrupts

S32	 movs	 <es:[edi].EDD,ds:[esi].EDD> ; Save in caller's buffer
S32	 movs	 <es:[edi].EDD,ds:[esi].EDD> ; Save in caller's buffer

	 popf			; Restore flags
				; (note interrupts might become enabled)
	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETLDTE endp		; End DPMI_GETLDTE procedure
	 NPPROC  DPMI_SETLDTE -- DPMI 0.9 Function to Set LDT Entry
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI 0.9 function to set LDT entry

On entry (in INTXX_STR):

AX	 =	 000Ch
BX	 =	 LDT selector
ES:eDI	 ==>	 DTE to set
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8021 if invalid value
	 =	 8022 if invalid selector
	 =	 8025 if invalid linear address
		 (this last error is not in the 0.9 spec and so
		  we don't enforce it here as some programs might
		  break were we to do so)

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 edi,[ebp].INTXX_EDI ; Get caller's eDI
	 IF16ZX  di		; Zero to use as dword if 16-bit client

	 mov	 es,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  es:nothing	; Tell the assembler about it

; Validate the A/R byte

	 mov	 al,es:[edi].DESC_ACCESS ; Get the A/R byte
	 call	 DPMIFN_CHKACCESS ; Check it out
	 jc	 near ptr INT31_ERR_INVVAL ; Jump if invalid

; Validate the extended flags
; The segment limit code below is unnecessary as we're changing
; the entire LDTE

	 mov	 al,es:[edi].DESC_SEGLM1 ; Get the extended flags
	 call	 DPMIFN_CHKSEGLM1 ; Check it out
	 jc	 near ptr INT31_ERR_INVVAL ; Jump if invalid

; Validate the selector

	 movzx	 ebx,[ebp].INTXX_EBX.ELO ; Get the selector

	 push	 @BIT0		; Ensure it's modifiable
	 push	 bx		; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if not valid

	 and	 bx,not ((mask $TI) or (mask $PL)) ; Clear TI and PL bits
	 mov	 eax,PCURTSS	; Get offset in PGROUP of the current TSS
	 add	 ebx,PGROUP:[eax].DPTSS_LaLDT ; Plus linear address of DPMI LDT

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 ds,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  ds:AGROUP	; Tell the assembler about it

; Save data into LDT

	 mov	 eax,es:[edi].EDQLO ; Get low-order word
	 mov	 AGROUP:[ebx].EDQLO,eax ; Save it

	 mov	 eax,es:[edi].EDQHI ; Get high-order word
	 mov	 AGROUP:[ebx].EDQHI,eax ; Save it

; In case we allowed the KRNL to write this LDTE, clear the must-be-zero bit

	 and	 AGROUP:[ebx].DESC_SEGLM1,not (mask $DTE_0) ; Clear it

; In case we skipped checking the selector's DPL, ensure it has the
; proper value now.

	 and	 AGROUP:[ebx].DESC_ACCESS,not (mask $DT_DPL) ; Clear DPL bits
	 mov	 al,DPMI_DPL	; Get proper DPL
	 or	 AGROUP:[ebx].DESC_ACCESS,al ; Ensure proper DPL

; Ensure invisible descriptor caches are reset

	 call	 DPMIFN_DTECACHE ; Reset 'em

	 popf			; Restore flags
				; (note interrupts might become enabled)
	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_SETLDTE endp		; End DPMI_SETLDTE procedure
	 NPPROC  DPMI_GETRLDT -- DPMI 0.9 Function to Allocate A Reserved LDT Selector
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to allocate a reserved LDT selector

On entry (in INTXX_STR):

AX	 =	 000Dh
BX	 =	 selector to allocate
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8011 if descriptor unavailable
	 =	 8022 if invalid selector

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Validate the selector

	 movzx	 ebx,[ebp].INTXX_EBX.ELO ; Get the selector

	 btr	 bx,$TI 	; Ensure it's in the LDT
	 jnc	 near ptr INT31_ERR_INVSEL ; Jump if not

	 cmp	 bx,@NLDTE_RSV*(type DESC_STR) ; Izit within limits?
	 jae	 near ptr INT31_ERR_INVSEL ; Jump if not

	 and	 bx,not (mask $PL) ; Clear PL bits
	 mov	 eax,PCURTSS	; get offset in PGROUP opf the current TSS
	 add	 ebx,PGROUP:[eax].DPTSS_LaLDT ; Plus linear address of DPMI LDT

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 bts	 AGROUP:[ebx].DESC_ACCESS,$DT_DC ; Mark as in use
	 jc	 near ptr INT31_ERR_NOSEL ; Jump if already in use

	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETRLDT endp		; End DPMI_GETRLDT procedure
	 NPPROC  DPMI_GETMLDTE -- Get Multiple LDT Entries
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Get multiple LDT entries

On entry (in INTXX_STR):

AX	 =	 000Eh
CX	 =	 number of descriptors to copy
ES:eDI	 =	 pointer to an array of structures in GetSetLDT
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8022 if invalid selector
CX	 =	 number of descriptors successfully copied

All other registers except EBP, FS, GS, and SS may be clobbered.

|

GetSetLDT struc

GS_Sel	 dw	 ?		; The selector
GS_Desc  dq	 ?		; The descriptor

GetSetLDT ends

	 push	 gs		; Save over this routine

	 xor	 cx,cx		; Init count of descriptors copied

	 mov	 edi,[ebp].INTXX_EDI ; Get caller's eDI
	 IF16ZX  di		; Zero to use as dword if 16-bit client

	 mov	 es,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  es:nothing	; Tell the assembler about it

	 mov	 esi,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 esi,PGROUP:[esi].DPTSS_LaLDT ; Get linear address of DPMI LDT

	 mov	 gs,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  gs:AGROUP	; Tell the assembler about it
DPMI_GETMLDTE_NEXT:
	 cmp	 cx,[ebp].INTXX_ECX.ELO ; Have we done them all?
	 je	 short DPMI_GETMLDTE_DONE ; Jump if so

; Validate the current selector

	 movzx	 ebx,es:[edi].GS_Sel ; Get next selector

; We have to test the local/global bit because the VALID_LSEL routine
; allows some GDT entries to pass thru.

	 test	 bx,mask $TI	; Izit in the LDT?
	 jz	 short DPMI_GETMLDTE_INVSEL ; Jump if not

	 push	 0		; Ignore modifiable check
	 push	 bx		; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 short DPMI_GETMLDTE_INVSEL ; Jump if not

	 and	 bx,not ((mask $PL) or (mask $TI))  ; Clear PL and TI bits

	 push	 esi		; Save LDT base

	 add	 esi,ebx	; Make descriptor base
	 add	 edi,size GS_Sel ; Skip over selector to DTE

	 pushf			; Save flags
	 cli			; Disallow interrupts

S32	 movs	 <es:[edi].EDD,AGROUP:[esi].EDD> ; Save in caller's buffer
S32	 movs	 <es:[edi].EDD,AGROUP:[esi].EDD> ; ...

	 popf			; Restore flags

	 pop	 esi		; Recall LDT base

	 inc	 cx		; Count in another selector copied

	 jmp	 DPMI_GETMLDTE_NEXT ; Go around again


DPMI_GETMLDTE_DONE:
	 pop	 gs		; Restore
	 assume  gs:nothing	; Tell the assembler about it

	 jmp	 INT31_CLC	; Join common OK code

DPMI_GETMLDTE_INVSEL:
	 pop	 gs		; Restore
	 assume  gs:nothing	; Tell the assembler about it

	 mov	 [ebp].INTXX_ECX.ELO,cx ; Save count of descs copied

	 jmp	 INT31_ERR_INVSEL ; Join common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETMLDTE endp		; End DPMIFN_SETMLDT procedure
	 NPPROC  DPMI_SETMLDTE -- Set Multiple LDT Entries
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Get multiple LDT entries

On entry (in INTXX_STR):

AX	 =	 000Fh
CX	 =	 number of descriptors to set
ES:eDI	 =	 pointer to an array of structures in GetSetLDT
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8022 if invalid selector
	 =	 8021 if invalid access rights
	 =	 8025 if invalid linear address
		 (this last error is not in the 0.9 spec and so
		  we don't enforce it here as some programs might
		  break were we to do so)
CX	 =	 number of descriptors successfully set

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 push	 gs		; Save over this routine

	 xor	 cx,cx		; init count of descriptors set

	 mov	 esi,[ebp].INTXX_EDI ; Get caller's eDI
	 IF16ZX  si		; Zero to use as dword if 16-bit client

	 mov	 gs,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  gs:nothing	; Tell the assembler about it

	 mov	 edi,PCURTSS	; Get offset in PGROUP of the current TSS
	 mov	 edi,PGROUP:[edi].DPTSS_LaLDT ; Get linear address of DPMI LDT

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it
DPMI_SETMLDTE_NEXT:
	 cmp	 cx,[ebp].INTXX_ECX.ELO ; Have we done them all?
	 je	 short DPMI_SETMLDTE_DONE ; Jump if so

; Validate the current selector

	 movzx	 ebx,gs:[esi].GS_Sel ; Get next selector

; We have to test the local/global bit because the VALID_LSEL routine
; allows some GDT entries to pass thru.

	 test	 bx,mask $TI	; Izit in the LDT?
	 jz	 short DPMI_SETMLDTE_INVSEL ; Jump if not

	 push	 @BIT0		; Ensure it's modifiable
	 push	 bx		; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 short DPMI_SETMLDTE_INVSEL ; Jump if not

; Validate the A/R byte

	 mov	 al,gs:[esi].GS_Desc.DESC_ACCESS ; Get the A/R byte
	 call	 DPMIFN_CHKACCESS ; Check it out
	 jc	 short DPMI_SETMLDTE_INVVAL ; Jump if invalid

	 and	 bx,not ((mask $PL) or (mask $TI))  ; Clear PL and TI bits

	 push	 edi		; Save LDT base

	 add	 edi,ebx	; Make descriptor base
	 add	 esi,size GS_Sel ; Skip over selector to DTE

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 push	 edi		; Save address of DTE

S32	 movs	 <AGROUP:[edi].EDD,gs:[esi].EDD> ; Copy from caller's buffer
S32	 movs	 <AGROUP:[edi].EDD,gs:[esi].EDD> ; ...

	 pop	 edi		; Restore

; In case we skipped checking the selector's DPL, ensure it has the
; proper value now.

	 and	 AGROUP:[edi].DESC_ACCESS,not (mask $DT_DPL) ; Clear DPL bits
	 mov	 al,DPMI_DPL	; Get proper DPL
	 or	 AGROUP:[edi].DESC_ACCESS,al ; Ensure proper DPL

	 popf			; Restore flags

	 pop	 edi		; Recall LDT base

	 inc	 cx		; Count in another selector copied

	 jmp	 DPMI_SETMLDTE_NEXT ; Go around again

DPMI_SETMLDTE_DONE:
	 pop	 gs		; Restore
	 assume  gs:nothing	; Tell the assembler about it

	 call	 DPMIFN_DTECACHE ; Reset 'em

	 jmp	 INT31_CLC	; Join ommon OK code

DPMI_SETMLDTE_INVSEL:
	 pop	 gs		; Restore
	 assume  gs:nothing	; Tell the assembler about it

	 call	 DPMIFN_DTECACHE ; Reset 'em

	 mov	 [ebp].INTXX_ECX.ELO,cx ; Save count of descs copied

	 jmp	 INT31_ERR_INVSEL ; Join common error code

DPMI_SETMLDTE_INVVAL:
	 pop	 gs		; Restore
	 assume  gs:nothing	; Tell the assembler about it

	 call	 DPMIFN_DTECACHE ; Reset 'em

	 mov	 [ebp].INTXX_ECX.ELO,cx ; Save count of descs copied

	 jmp	 INT31_ERR_INVVAL ; Join common error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_SETMLDTE endp		; End DPMIFN_SETMLDT procedure
	 NPPROC  DPMIFN_SETMLDT -- Set Multiple LDT Entries
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set multiple LDT entries

On entry:

EAX	 ==>	 base of allocated DOS memory
BX	 =	 base selector
EDX	 =	 size of the allocated block in bytes
IF	 =	 0 (interrupts disabled)

On exit:

EAX	 ==>	 next 64KB block
BX	 =	 next selector
EDX	 =	 remainder of block size and 64KB

|

	 REGSAVE <ecx>		; Save register

; Set the LDT entries to the proper base and limit

; The first LDTE has full limit

	 mov	 ecx,edx	; Use full limit
DPMIFN_SETMLDT_NEXT:
	 push	 ecx		; Pass size of area in bytes
	 push	 DPMI_DATA	; Pass access rights word
	 push	 bx		; Pass descriptor to set (note $TI set)
	 FIXICALL PGROUP:FSET_GDT,DTE_CS2 ; Set the LDT to EAX base

; If it's not a 16-bit client, we're done

	 cmp	 DPMITYPE,@DPMITYPE16 ; Izit a 16-bit client?
	 jne	 short DPMIFN_SETMLDT_EXIT ; Jump if not

	 add	 bx,size DESC_STR ; Skip to next LDTE
	 add	 eax,CON64KB	; Skip to next 64KB block

	 sub	 edx,CON64KB	; Less last LDTE
	 jb	 short DPMIFN_SETMLDT_EXIT ; Jump if that's all folks

; Use smaller of EDX and 64KB as the limit

	 mov	 ecx,CON64KB	; Get 64KB

	 cmp	 ecx,edx	; Use the smaller
	 jae	 short @F	; Jump if EDX will do

	 mov	 ecx,edx	; Use the smaller
@@:
	 jmp	 short DPMIFN_SETMLDT_NEXT ; Go around again

DPMIFN_SETMLDT_EXIT:
	 REGREST <ecx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_SETMLDT endp		; End DPMIFN_SETMLDT procedure
	 NPPROC  DPMI_GETDMEM -- DPMI 0.9 Function to Allocate DOS Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to allocate DOS memory

On entry (in INTXX_STR):

AX	 =	 0100h
BX	 =	 # paras to allocate
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful
AX	 =	 segment of allocated memory
DX	 =	 selector for allocated memory

CF	 =	 1 if not successful
AX	 =	 0007 if memory control blocks damaged
	 =	 0008 if insufficient DOS memory
	 =	 8011 if descriptor unavailable
BX	 =	 # paras in largest block

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 mov	 es,SEL_4GB3	; Get our all memory selector
	 assume  es:AGROUP	; Tell the assembler about it

; Find a selector to use
; If this is a 16-bit client, allocate multiple 64KB selectors

	 mov	 dx,[ebp].INTXX_EBX.ELO ; Get # paras to allocate
	 mov	 ax,1		; Assume it's not a 16-bit client

	 cmp	 DPMITYPE,@DPMITYPE16 ; Izit a 16-bit client?
	 jne	 short @F	; Jump if not

	 movzx	 eax,dx 	; Copy # paras to allocate
	 add	 eax,(1 shl (16-4))-1 ; Round up to 64KB boundary in paras
	 shr	 eax,16-4	; Convert from paras to 64KB
@@:
	 mov	 si,ax		; Save # selectors to allocate

	 push	 @BIT0		; Mark as segment-to-selector
	 push	 si		; # selectors to allocate
	 call	 GET_LDT	; Get next LDT selector in EAX ($TI and $PL set)
				; and LDTE marked as CPL3_DATA
	 jc	 near ptr INT31_ERR_NOSEL ; Jump if not available

	 mov	 di,ax		; Save selector value

; Find DOS memory to use

	 movzx	 eax,P1ST_MAC.VSEG ; Get segment of head of MAC entries
	 shl	 eax,4-0	; Convert from paras to bytes
	 movzx	 ebx,P1ST_MAC.VOFF ; Get offset ...
	 add	 ebx,eax	; AGROUP:EBX ==> linear address

; Merge adjacent free entries

	 FIXICALL JGROUP:FMAC_MERGESUB,DTE_CSJG ; Merge MAC entries starting at 0:EBX
	 jc	 near ptr INT31_ERR_MAC ; Jump if something went wrong

	 xor	 cx,cx		; Initialize counter of largest free block

; Register usage:

; CX	 =	 size of largest free block in paras (in case we
;		 can't find one large enough)
; DX	 =	 size of the block we're looking for (in paras)
; ES:EBX ==>	 current block

DPMI_GETDMEM_NEXT:
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 jne	 near ptr DPMI_GETDMEM_ERRMAC ; Jump if not
@@:
	 cmp	 AGROUP:[ebx].MAC_OWNR,@MAC_FREE ; Izit available?
	 jne	 short DPMI_GETDMEM_LOOP ; Jump if not

; Save size of largest available MAC entry

	 mov	 ax,AGROUP:[ebx].MAC_NPAR ; Get size of this MAC entry

	 cmp	 cx,ax		; Izit larger than before?
	 jae	 short @F	; Jump if not

	 mov	 cx,ax		; Save as new largest
@@:
	 cmp	 dx,ax		; Izit enough?
	 ja	 short DPMI_GETDMEM_LOOP ; Jump if not
	 pushf			; Save flags
	 cli			; Disallow interrupts
	 je	 short DPMI_GETDMEM_FIT ; Jump if it fits exactly

; Split the MAC entry in two

	 mov	 AGROUP:[ebx].MAC_NPAR,dx ; Save as new size

; Split the block into pieces of size DX and (AX-DX)

	 inc	 dx		; Count in MAC paragraph
	 sub	 ax,dx		; Get 2nd block size
	 movzx	 edx,dx 	; Zero to use as dword
	 shl	 edx,4-0	; Convert from paras to bytes
				; GS:EBX+EDX ==> 2nd entry

	 mov	 cl,@MAC_MID	; Mark as middle block
	 xchg	 cl,AGROUP:[ebx].MAC_TYPE ; Swap with current type
	 mov	 AGROUP:[ebx+edx].MAC_TYPE,cl ; Save as new type
	 mov	 AGROUP:[ebx+edx].MAC_OWNR,@MAC_FREE ; Mark as free
	 mov	 AGROUP:[ebx+edx].MAC_NPAR,ax ; Save new size
DPMI_GETDMEM_FIT:

; Save the current PSP segment as the owner

	 push	 bx		; Save for a moment

	 DOSCALL @GETPS0	; Get PSP into BX

	 push	 bx		; Pass selector as argument
	 FIXICALL IGROUP:GETSELBASE,DTE_CSIG ; Return with EAX = base address of selector
	 shr	 eax,4-0	; Convert from bytes to paras

	 pop	 bx		; Restore

	 mov	 AGROUP:[ebx].MAC_OWNR,ax ; Save as owner

	 lea	 eax,[ebx+(size MAC_STR)] ; Copy and skip over MAC entry

	 mov	 edx,eax	; Copy linear address
	 shr	 edx,4-0	; Convert from bytes to paras
	 mov	 [ebp].INTXX_EAX.ELO,dx ; Return segment  in caller's AX
	 mov	 [ebp].INTXX_EDX.ELO,di ; ...	 selector ...	      DX

	 movzx	 edx,[ebp].INTXX_EBX.ELO ; Get # paras to allocate
	 shl	 edx,4-0	; Convert from paras to bytes

	 mov	 bx,di		; Copy selector #

; EAX	 ==>	 base of allocated DOS memory
; BX	 =	 base selector
; EDX	 =	 size of the allocated block in bytes

	 call	 DPMIFN_SETMLDT ; Set multiple LDT entries
				; EAX = next block
				; BX  = next selector
				; EDX = remainder of size

	 popf			; Restore flags
				; (note interrupts might become enabled)
	 jmp	 INT31_CLC	; Join common exit code

DPMI_GETDMEM_LOOP:
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 je	 short DPMI_GETDMEM_ERRNOMEM ; Jump if so

	 movzx	 eax,AGROUP:[ebx].MAC_NPAR ; Get # paras in this entry
	 inc	 eax		; Account for MAC para
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 ebx,eax	; AGROUP:EBX ==> linear address

	 jmp	 DPMI_GETDMEM_NEXT ; Go around again


; Not enough memory:  return size of largest block in caller's BX
; and free the allocated selector(s)

DPMI_GETDMEM_ERRNOMEM:
	 lea	 bx,INT31_ERR_NODMEM ; Get offset of common error exit code

	 jmp	 short DPMI_GETDMEM_ERRCOM ; Join common error code


; Memory Allocation chain error:  return size of largest block in caller's BX
; and free the allocated selector(s)

DPMI_GETDMEM_ERRMAC:
	 lea	 bx,INT31_ERR_MAC ; Get offset of common error exit code
DPMI_GETDMEM_ERRCOM:
	 mov	 [ebp].INTXX_EBX.ELO,cx ; Return size of largest available
				; block in caller's BX
	 mov	 cx,si		; Copy # allocated selectors
@@:
	 push	 di		; Get the selector to free
	 call	 CLR_LDTZERO	; Free this LDT selector & zero selectors
;;;;;;;; jc	 short ???	; Ignore return code

	 add	 di,type DESC_STR ; Skip to next selector

	 loop	 @B		; Jump if more selectors to free

	 jmp	 bx		; Join common error exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_GETDMEM endp		; End DPMI_GETDMEM procedure
	 NPPROC  DPMI_RELDMEM -- DPMI 0.9 Function to Free DOS Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to free DOS memory

We're assuming that the original DOS memory block
remains intact and has not been split up into
separate pieces.

On entry (in INTXX_STR):

AX	 =	 0101h
DX	 =	 selector of block to free
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 0007 if memory control blocks damaged
	 =	 0009 if incorrect memory segment specified
	 =	 8022 if invalid selector

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Validate the selector

	 movzx	 ebx,[ebp].INTXX_EDX.ELO ; Get the selector

	 push	 @BIT1		; Ensure it's a DOS memory block
	 push	 bx		; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if not valid

	 push	 bx		; Pass the selector
	 call	 GETLBASE	; Return with EAX = base address from LDT

; Validate the MAC entry

	 mov	 es,SEL_4GB3	; Get our all memory selector
	 assume  es:AGROUP	; Tell the assembler about it

	 sub	 eax,size MAC_STR ; Back off to MAC entry

; Ensure there's a MAC entry preceding it

	 cmp	 AGROUP:[eax].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[eax].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 jne	 near ptr INT31_ERR_MNF ; Jump if not
@@:

; Search the MAC chain (high and low)

	 movzx	 ebx,P1ST_MAC.VSEG ; Get segment of head of MAC entries
	 shl	 ebx,4-0	; Convert from paras to bytes
	 movzx	 ecx,P1ST_MAC.VOFF ; Get offset ...
	 add	 ebx,ecx	; AGROUP:EBX ==> linear address

	 call	 DPMIFN_FINDMAC ; Search for EAX linear starting at EBX linear
	 jnc	 short DPMI_RELDMEM1  ; Jump if it's a match

	 movzx	 ebx,POVR_MAC	; Get segment of first MAC entry in high DOS

	 cmp	 bx,-1		; Izit valid?
	 je	 near ptr INT31_ERR_MAC ; Jump if not

	 shl	 ebx,4-0	; Convert from paras to bytes

	 call	 DPMIFN_FINDMAC ; Search for EAX linear starting at EBX linear
	 jc	 near ptr INT31_ERR_MAC ; Jump if not found
DPMI_RELDMEM1:
	 cmp	 AGROUP:[eax].MAC_OWNR,@MAC_SPAN ; Izit a spanning entry?
	 je	 near ptr INT31_ERR_MAC ; Jump if so

	 mov	 AGROUP:[eax].MAC_OWNR,@MAC_FREE ; Mark as available

	 mov	 bx,[ebp].INTXX_EDX.ELO ; Get the selector

	 movzx	 edx,AGROUP:[eax].MAC_NPAR ; Get # paras in this MAC entry
	 shl	 edx,4-0	; Convert from paras to bytes
DPMI_RELDMEM_NEXT:
	 push	 bx		; Pass selector to free
	 call	 CLR_LDTZERO	; Free this LDT selector & zero selectors
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if something went wrong

; If this is not a 16-bit client, we're done

	 cmp	 DPMITYPE,@DPMITYPE16 ; Izit a 16-bit client?
	 jne	 short DPMI_RELDMEM_EXIT ; Jump if not

	 sub	 edx,CON64KB	; Less last LDTE
	 jb	 short DPMI_RELDMEM_EXIT ; Jump if that's all folks

	 add	 bx,size DESC_STR ; Skip to next LDTE

	 jmp	 short DPMI_RELDMEM_NEXT ; Go around again

DPMI_RELDMEM_EXIT:
	 jmp	 INT31_CLC	; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_RELDMEM endp		; End DPMI_RELDMEM procedure
	 NPPROC  DPMIFN_FINDMAC -- Find An Entry In The MAC Chain
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find an entry in the MAC chain.

On entry:

EAX	 =	 linear address to find
EBX	 =	 linear address to start search

On exit:

CF	 =	 0 if we found it
	 =	 1 if not (includes MAC chain error)

|

	 REGSAVE <ebx,ecx>	; Save registers
DPMIFN_FINDMAC_NEXT:
	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 jne	 short DPMIFN_FINDMAC_ERR ; Jump if not
@@:
	 cmp	 eax,ebx	; Duzit match?
	 je	 short DPMIFN_FINDMAC_EXIT ; Jump if so (note CF=0)

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 je	 short DPMIFN_FINDMAC_ERR ; Jump if so

	 movzx	 ecx,AGROUP:[ebx].MAC_NPAR ; Get # paras in MAC entry
	 inc	 ecx		; Count in the MAC entry
	 shl	 ecx,4-0	; Convert from paras to bytes
	 add	 ebx,ecx	; Add to get next linear address

	 cmp	 ebx,CON1MB	; Izit outasight?
	 jb	 short DPMIFN_FINDMAC_NEXT ; Jump if not
DPMIFN_FINDMAC_ERR:
	 stc			; Indicate not found (or MAC error)
DPMIFN_FINDMAC_EXIT:
	 REGREST <ecx,ebx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_FINDMAC endp		; End DPMIFN_FINDMAC procedure
	 NPPROC  DPMIFN_TESTSEL -- Test LDT Selector For Availability
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Test LDT selector for availability

On entry:

AGROUP:EAX ==>	 DTE in LDT

On exit:

CF	 =	 0 if selector is available
	 =	 1 if not

|

	 cmp	 AGROUP:[eax].EDQLO,0 ; Izit available?
	 jne	 short @F	; Jump if not

	 cmp	 AGROUP:[eax].EDQHI,0 ; Izit available?
	 je	 short DPMIFN_TESTSEL_EXIT ; Jump if so (note CF=0)
@@:
	 stc			; Mark as not available
DPMIFN_TESTSEL_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_TESTSEL endp		; End DPMIFN_TESTSEL procedure
	 NPPROC  DPMIFN_ALLOCSEL -- Mark LDT Selector As In Use
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mark LDT selector as in use

On entry:

AGROUP:EAX ==>	 DTE in LDT

On exit:

CF	 =	 0 if selector was available
	 =	 1 if not

|

	 bts	 AGROUP:[eax].DESC_ACCESS,$DT_DC ; Mark as in use

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_ALLOCSEL endp		; End DPMIFN_ALLOCSEL procedure
	 NPPROC  DPMIFN_FREESEL -- Mark LDT Selector As Free
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mark LDT selector as free

On entry:

AGROUP:EAX ==>	 DTE in LDT

On exit:

CF	 =	 0 if selector was in use
	 =	 1 if not

|

	 btr	 AGROUP:[eax].DESC_ACCESS,$DT_DC ; Mark as not in use
	 cmc			; Complement so that CF=1 is error

	 mov	 AGROUP:[eax].EDQLO,0 ; Free the selector
	 mov	 AGROUP:[eax].EDQHI,0 ; ...

	 pushf			; Save CF over TEST

	 test	 DPM_FLAG,mask $DPM_DPMINEWSEL ; Are we forcing new selectors?
	 jz	 short @F	; Jump if not

	 mov	 AGROUP:[eax].EDQLO,@NEWSEL_EDQLO ; Free the selector
	 mov	 AGROUP:[eax].EDQHI,@NEWSEL_EDQHI ; ...
@@:
	 popf			; Restore CF

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_FREESEL endp		; End DPMIFN_FREESEL procedure
	 NPPROC  DPMIFN_SELFCN -- Test, Allocate, Or Free LDT Selectors
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Test, allocate, or free LDT selectors

On entry

AGROUP:EBX ==>	 low DOS memory corresponding to selector in INTXX_EDX.ELO
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On entry (in INTXX_STR):

BX	 =	 new block size in paras
DX	 =	 selector of block to resize

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|
DPMIFN_SELFCN_STR struc

DPMIFN_SELFCN_EBP dd ?		; Caller's EBP
	 dw	 ?		; ...	   IP
DPMIFN_SELFCN_FCN dw ?		; Function to use (Test, Allocate, or Free)

DPMIFN_SELFCN_STR ends

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 REGSAVE <eax,ebx,ecx,edx>  ; Save registers

; If this is a 16-bit client, see if we need more selectors

	 cmp	 DPMITYPE,@DPMITYPE16 ; Izit a 16-bit client?
	 jne	 short DPMIFN_SELFCN_CLC ; Jump if not

	 movzx	 eax,AGROUP:[ebx].MAC_NPAR ; Get current block size in paras
	 add	 eax,(1 shl (16-4))-1 ; Round up to 64KB boundary in paras
	 shr	 eax,16-4	; Convert from paras to 64KB

	 mov	 ebx,[ebp].DPMIFN_SELFCN_EBP ; SS:EBX ==> INTXX_STR

	 movzx	 ecx,ss:[ebx].INTXX_EBX.ELO ; Get new block size in paras
	 add	 ecx,(1 shl (16-4))-1 ; Round up to 64KB boundary in paras
	 shr	 ecx,16-4	; Convert from paras to 64KB

	 sub	 cx,ax		; Subtract to get # new selectors we need
	 jz	 short DPMIFN_SELFCN_CLC ; Jump if it's zero

; Check for CX adjacent selectors above base

	 add	 ax,ss:[ebx].INTXX_EDX.ELO ; Plus the base selector
	 and	 ax,not ((mask $TI) or (mask $PL)) ; Clear TI and PL bits
	 mov	 edx,PCURTSS	; Get offset in PGROUP of the current TSS
	 add	 eax,PGROUP:[edx].DPTSS_LaLDT ; Plus linear address of DPMI LDT
@@:
	 call	 [ebp].DPMIFN_SELFCN_FCN ; Call appropriate function
	 jc	 short DPMIFN_SELFCN_EXIT ; Jump if not (note CF=1)

	 add	 eax,size DESC_STR ; Skip to next LDTE

	 loop	 @B		; Jump if more selectors to check
DPMIFN_SELFCN_CLC:
	 clc			; Indicate all went well
DPMIFN_SELFCN_EXIT:
	 REGREST <edx,ecx,ebx,eax> ; Restore

	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMIFN_SELFCN endp		; End DPMIFN_SELFCN procedure
	 NPPROC  DPMI_MODDMEM -- DPMI 0.9 Function to Resize DOS Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DPMI 0.9 function to resize DOS memory

On entry (in INTXX_STR):

AX	 =	 0102h
BX	 =	 new block size in paras
DX	 =	 selector of block to resize
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 0007 if memory control blocks damaged
	 =	 0008 if insufficient DOS memory
	 =	 0009 if incorrect memory segment specified
	 =	 8011 if descriptor unavailable
	 =	 8022 if invalid selector
BX	 =	 # paras available for resize

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Validate the MAC entry

	 push	 @BIT1		; Ensure it's a DOS memory block
	 push	 [ebp].INTXX_EDX.ELO ; Pass the selector
	 call	 VALID_LSEL	; Ensure LDT selector is valid
	 jc	 near ptr INT31_ERR_INVSEL ; Jump if not valid

	 push	 [ebp].INTXX_EDX.ELO ; Pass the base selector
	 call	 GETLBASE	; Return with EAX = base address from LDT

	 mov	 ebx,eax	; Copy for convenience
	 sub	 ebx,size MAC_STR ; Back off to the MAC entry

	 mov	 es,SEL_4GB3	; Get our all memory selector
	 assume  es:AGROUP	; Tell the assembler about it

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short @F	; Jump if so

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 jne	 near ptr INT31_ERR_MAC ; Jump if not
@@:

; Split cases depending upon grow or shrink

	 mov	 dx,[ebp].INTXX_EBX.ELO ; Get new block size in paras

	 sub	 dx,AGROUP:[ebx].MAC_NPAR ; Izit grow or shrink?
	 jb	 near ptr DPMI_MODDMEM_SHRINK ; Jump if it's shrink
	 je	 near ptr INT31_CLC ; Jump if it's a wash
				; Fall through to grow

; See if there's enough room above this entry for DX additional paras

	 xor	 cx,cx		; Initialize counter of largest free block

	 cmp	 AGROUP:[ebx].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 je	 near ptr DPMI_MODDMEM_ERRNOMEM ; Jump if so (CX has largest size)

; Merge adjacent free entries

	 FIXICALL JGROUP:FMAC_MERGESUB,DTE_CSJG ; Merge MAC entries starting at 0:EBX
	 jc	 near ptr INT31_ERR_MAC ; Jump if something went wrong

	 movzx	 eax,AGROUP:[ebx].MAC_NPAR ; Get # paras in this entry
	 inc	 eax		; Account for MAC para
	 shl	 eax,4-0	; Convert from paras to bytes

	 cmp	 AGROUP:[ebx+eax].MAC_OWNR,@MAC_FREE ; Izit free?
	 jne	 near ptr DPMI_MODDMEM_ERRNOMEM ; Jump if not (CX has largest size)

	 mov	 cx,AGROUP:[ebx+eax].MAC_NPAR ; Get the size
	 inc	 cx		; Count in MAC paragraph

	 cmp	 dx,cx		; Izit enough?
	 ja	 near ptr DPMI_MODDMEM_ERRNOMEM ; Jump if not (CX has largest size)

	 push	 offset IGROUP:DPMIFN_TESTSEL ; Pass offset of test sel fn
	 call	 DPMIFN_SELFCN	; Test the selectors
	 jc	 near ptr INT31_ERR_NOSEL ; Jump if not all available

	 push	 offset IGROUP:DPMIFN_ALLOCSEL ; Pass offset of allocate sel fn
	 call	 DPMIFN_SELFCN	; Mark the selectors
	 jc	 near ptr INT31_ERR_NOSEL ; Jump if not all available

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 al,AGROUP:[ebx+eax].MAC_TYPE ; Get the upper type
	 mov	 AGROUP:[ebx].MAC_TYPE,al ; Save as lower type

	 cmp	 dx,cx		; Izit same size?
	 je	 short DPMI_MODDMEM_FIT ; Jump if it just fits

; Split the MAC entry in two

	 push	 dx		; Save grow size in paras

	 add	 dx,AGROUP:[ebx].MAC_NPAR ; Add to get total size
	 mov	 ax,cx		; Copy as available size
	 add	 ax,AGROUP:[ebx].MAC_NPAR ; Add to get total size

; Split the block into pieces of size DX and (AX-DX)

	 inc	 dx		; Count in MAC paragraph
	 sub	 ax,dx		; Get 2nd block size
	 movzx	 edx,dx 	; Zero to use as dword
	 shl	 edx,4-0	; Convert from paras to bytes
				; GS:EBX+EDX ==> 2nd entry

	 mov	 cl,@MAC_MID	; Mark as middle block
	 xchg	 cl,AGROUP:[ebx].MAC_TYPE ; Swap with current type
	 mov	 AGROUP:[ebx+edx].MAC_TYPE,cl ; Save as new type
	 mov	 AGROUP:[ebx+edx].MAC_OWNR,@MAC_FREE ; Mark as free
	 mov	 AGROUP:[ebx+edx].MAC_NPAR,ax ; Save new size

	 pop	 dx		; Restore grow size in paras
DPMI_MODDMEM_FIT:
	 add	 AGROUP:[ebx].MAC_NPAR,dx ; Add to get new size

; Set new LDTEs to the appropriate base and size
; Note that we reset the initial LDTEs via a common subroutine
; used above

	 movzx	 edx,AGROUP:[ebx].MAC_NPAR ; Get total size in paras
	 shl	 edx,4-0	; Convert from paras to bytes
	 lea	 eax,[ebx+(size MAC_STR)] ; Copy and skip over MAC entry
	 mov	 bx,[ebp].INTXX_EDX.ELO ; Get the base selector

; EAX	 ==>	 base of allocated DOS memory
; BX	 =	 base selector
; EDX	 =	 size of the allocated block in bytes

	 call	 DPMIFN_SETMLDT ; Set multiple LDT entries
				; EAX = next block
				; BX  = next selector
				; EDX = remainder of size

	 jmp	 short DPMI_MODDMEM_RESET ; Join common reset code


; The request is to shrink the size of the DOS memory block
; -DX is the size by which it should be reduced
; AGROUP:EBX ==> low DOS memory MAC entry

DPMI_MODDMEM_SHRINK:
	 pushf			; Save flags
	 cli			; Disallow interrupts

	 add	 AGROUP:[ebx].MAC_NPAR,dx ; Add to get new (reduced) size
	 neg	 dx		; Negate to get size of upper (free) block
	 dec	 dx		; Count out MAC paragraph
	 mov	 ax,dx		; Copy to common register

	 movzx	 edx,AGROUP:[ebx].MAC_NPAR ; Get new size of lower block
	 inc	 edx		; Count in MAC paragraph
	 shl	 edx,4-0	; Convert from paras to bytes

	 mov	 cl,@MAC_MID	; Mark as middle block
	 xchg	 cl,AGROUP:[ebx].MAC_TYPE ; Swap with current type
	 mov	 AGROUP:[ebx+edx].MAC_TYPE,cl ; Save as new type
	 mov	 AGROUP:[ebx+edx].MAC_OWNR,@MAC_FREE ; Mark as free
	 mov	 AGROUP:[ebx+edx].MAC_NPAR,ax ; Save new size

; Set new limits

	 push	 ebx		; Save for a moment

	 movzx	 edx,AGROUP:[ebx].MAC_NPAR ; Get total size in paras
	 shl	 edx,4-0	; Convert from paras to bytes
	 lea	 eax,[ebx+(size MAC_STR)] ; Copy and skip over MAC entry
	 mov	 bx,[ebp].INTXX_EDX.ELO ; Get the base selector

; EAX	 ==>	 base of allocated DOS memory
; BX	 =	 base selector
; EDX	 =	 size of the allocated block in bytes

	 call	 DPMIFN_SETMLDT ; Set multiple LDT entries
				; EAX = next block
				; BX  = next selector
				; EDX = remainder of size
	 pop	 ebx		; Restore

; Free trailing selectors (if any)

; If it's not a 16-bit client, we're done

	 cmp	 DPMITYPE,@DPMITYPE16 ; Izit a 16-bit client?
	 jne	 short DPMI_MODDMEM_RESET ; Jump if not

	 push	 offset IGROUP:DPMIFN_FREESEL ; Pass offset of free sel fn
	 call	 DPMIFN_SELFCN	; Free the selectors
	 jc	 short DPMI_MODDMEM_ERRNOSEL ; Jump if not all available
DPMI_MODDMEM_RESET:

; Ensure invisible descriptor caches are reset

	 call	 DPMIFN_DTECACHE ; Reset 'em

	 popf			; Restore flags
				; (note interrupts might become enabled)
DPMI_MODDMEM_EXIT:
	 jmp	 INT31_CLC	; Join common exit code


; Error freeing selectors

DPMI_MODDMEM_ERRNOSEL:
	 popf			; Restore flags
				; (note interrupts might become enabled)
	 jmp	 INT31_ERR_NOSEL ; Join common error code


; Not enough memory:  return size of largest block in caller's BX

DPMI_MODDMEM_ERRNOMEM:
	 mov	 [ebp].INTXX_EBX.ELO,cx ; Return size of largest available
				; block in caller's BX

	 jmp	 INT31_ERR_NODMEM ; Join common error exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DPMI_MODDMEM endp		; End DPMI_MODDMEM procedure
	 align	 4		; Ensure dword alignment

ICODE	 ends			; End ICODE segment
endif				; IF @OEM_DPMI


JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

	 public  @QMAX_J31_JCODE
@QMAX_J31_JCODE:		; Mark module start in .MAP file

	 extrn	 MAC_MERGESUB:near

	 FPPROC  FMAC_MERGESUB -- MAC Merge Subroutine
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Far call to MAC_MERGESUB

On entry:

Same as for MAC_MERGESUB

On exit:

Same as for MAC_MERGESUB

|

	 call	 MAC_MERGESUB	; Merge MAC entries starting at 0:EBX
				; Return with CF significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FMAC_MERGESUB endp		; End FMAC_MERGESUB procedure

JCODE	 ends			; End JCODE segment

	 MEND			; End QMAX_J31 module
