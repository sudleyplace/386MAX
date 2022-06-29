;' $Header:   P:/PVCS/MISC/VCPITEST/VCP_EPM.ASV   1.1   22 Feb 1994 12:32:02   HENRY  $

	 title	 VCP_EPM -- VCPI Enter Protected Mode Routines
	 page	 58,122
	 name	 VCP_EPM
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-94 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment TEXT,  byte-aligned,  public, class 'data'
	       Tail    segment DTAIL, byte-aligned,  public, class 'data'

Link requirements:  None, standalone subroutine.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include VCPI.INC
	 include 386.INC
	 include PTR.INC

	 include VCP_TEST.INC
	 include QMAX_FIL.INC
	 include EMM2CALL.INC
.list


EPM_STR  struc

EPM_CR3  dd	 ?		; New CR3
EPM_GDTP dd	 ?		; Pointer to new GDTR base
EPM_IDTP dd	 ?		; Pointer to new IDTR base
EPM_LDTR dw	 ?		; New LDTR
EPM_TR	 dw	 ?		; New TR
EPM_EXIT df	 ?		; CS:EIP of exit point

EPM_STR  ends


PGROUP	 group	 CODE,DATA,TEXT,DTAIL


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 PORT67:word

	 extrn	 CMD_FLAG:word
	 include VCP_FLAG.INC

	 extrn	 ERRMSG:word
	 extrn	 ERRCODE:byte
	 extrn	 NFREE:dword

	 public  CON4K,CON64K,CON1M
CON4K	 dd	    4*1024	;  4K
CON64K	 dd	   64*1024	; 64K
CON1M	 dd	 1024*1024	;  1M

VDTE_STR struc

	 db	 (size DTE_STR) dup (?) ; 00-38
VCP_PMCS dq	 ?		; 40:  1st selector
VCP_PMDS dq	 ?		; 48:  2nd ...
VCP_PMES dq	 ?		; 50:  3rd ...
VCP_TR	 dq	 ?		; 58:  Task ...
VCP_4GB  dq	 ?		; 60:  All memory ...
VCP_LDT  dq	 ?		; 68:  LDT ...
VCP_VID  dq	 ?		; 70:  Video ...
VCP_SWAT dq	 30 dup (?)	; 78:  386SWAT selectors

VDTE_STR ends

	 public  LCLGDT,VCPGDT
LCLGDT	 VDTE_STR <>		; Local descriptor table for EPM
VCPGDT	 equ	 LCLGDT.VCP_PMCS ; Offset of VCPI selectors

IDTMAC	 macro	 NN
	 IDT_STR <PGROUP:PM_IRETD&NN&,DTE_CS,0,CPL0_INTR3,0> ; Local IDT
	 endm			; IDTMAC

	 public  LCLIDT
LCLIDT	 label	 tbyte
CNT	 =	 0
	 rept	 32
	 IDTMAC  %CNT
CNT	 =	 CNT+1
	 endm			; REPT 32

	 public  EPMTAB
EPMTAB	 EPM_STR <>		; Enter Protected Mode structure

	 public  LCLTSS
LCLTSS	 TSS_STR <>		; Local TSS

	 public  LaCODE,LaDATA,LaCR3,LaPTE,RaCR3,RaPTE,PaCR3
LaCODE	 dd	 ?		; Linear address of our code segment
LaDATA	 dd	 ?		; ...			data
LaCR3	 dd	 ?		; ...			CR3
LaPTE	 dd	 ?		; ...			PTEs
RaCR3	 dw	 ?		; Relative		CR3
RaPTE	 dw	 ?		; ...			PTE
PaCR3	 dd	 ?		; Physical		CR3

	 public  PMI_FWD,PMI_ERR
PMI_FWD  df	 ?		; Selector:Offset to PMI code
PMI_ERR  dw	 ?		; PMI error flag

	 public  OLDESP
OLDESP	 dd	 ?		; Save area for old ESP

	 public  CODESEG,DATASEG
CODESEG  dw	 ?		; Real mode code segment
DATASEG  dw	 ?		; ...	    data

	 public  FIRSTPTE,NEXTPTE
FIRSTPTE dw	 ?		; Offset of first PTE
NEXTPTE  dw	 ?		; ...	    next

	 public  PIDT
PIDT	 df	 ?		; Pointer to (global) IDT

BIT_REC  record  $EAX:1,$EBX:1,$ECX:1,$EDX:1,$ESI:1,$EDI:1,$EBP:1,$ESP:1

	 public  BIT_EAX_EDX,BIT_EAX
;		 eeeeeeee
;		 abcdsdbs
;		 xxxxiipp
BIT_EAX_EDX dw	 01101110b
BIT_EAX     dw	 01111110b

	 public  SAVE_EAX,SAVE_EBX,SAVE_ECX,SAVE_EDX,
	 public  SAVE_ESI,SAVE_EDI,SAVE_EBP
SAVE_EAX dd	 ?		; Save area for EAX
SAVE_EBX dd	 ?		;		EBX
SAVE_ECX dd	 ?		;		ECX
SAVE_EDX dd	 ?		;		EDX
SAVE_ESI dd	 ?		;		ESI
SAVE_EDI dd	 ?		;		EDI
SAVE_EBP dd	 ?		;		EBP

	 public  PMSTK,PMSTKZ
PMSTK	 dw	 256 dup (?)	; Protected mode stack
PMSTKZ	 label	 word		; End of ...

	 public  PMSTK_FVEC
PMSTK_FVEC label fword
	 dw	 PGROUP:PMSTKZ,0 ; Stack ending offset
	 dw	 DTE_SS 	; Stack selector

	 public  NEXTLOC
NEXTLOC  dw	 PGROUP:ZTAIL	; Offset of next available byte

	 public  MSG_DVER
MSG_DVER  db	 'Debugger specification version #'
MSG_DVER1 db	 '____.',CR,LF,EOS

DATA	 ends			; End DATA segment


DTAIL	 segment use16 para public 'data' ; Start DTAIL segment
	 assume  ds:PGROUP

	 extrn	 ZTAIL:byte

DTAIL	 ends			; End DTAIL segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:nothing,es:nothing

	 extrn	 BIN2WORD:near

IRETD_MAC macro  NN
	 public  PM_IRETD&NN
PM_IRETD&NN&:
	 push	 &NN
	 int	 01h		; Call our debugger
	 iretd			; Return to caller
	 endm			; IRETD_MAC

CNT	 =	 0
	 rept	 32
	 IRETD_MAC %CNT
CNT	 =	 CNT+1
	 endm			; REPT 32

	 FPPROC  TMPINT67 -- Temporary Int 67h handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TMPINT67 endp			; End procedure TMPINT67
	 NPPROC  CHECK_EPM -- Check on Enter Protected Mode Calls
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on VCPI Enter Protected Mode calls.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers

; Read in CR0

	 DISPLAY "様> Reading CR0..."

	 VCPIBACK @VCPI_GCR0	; Return in EBX

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to read CR0",ERR
	 jne	 near ptr CHECK_EPM_ERR ; Jump if in error

; Ensure $PG and $PE are set

	 DISPLAY "様> Testing CR0..."

	 and	 ebx,(mask $PG) or (mask $PE) ; Isolate the bits

	 cmp	 ebx,(mask $PG) or (mask $PE) ; Ensure all set
	 SETMSG  "PG and PE not both set in CR0",ERR
	 jne	 near ptr CHECK_EPM_ERR ; Jump if in error

; The following call sets up PaCR3 needed by debugger if present

	 DISPLAY "様> Setup for PMI..."

	 call	 SETUP_PMI	; Setup the PMI
	 jc	 near ptr CHECK_EPM_ERR ; Jump if something went wrong

; Determine whether or not a resident debugger is present

; Note that if EMS=0 and we're using back door VCPI, we'll need
; to set up a temporary Int 67h handler in case it's an older MAX
; version that doesn't always hook Int 67h.

	 REGSAVE <ds,es>	; Save

	 mov	 ax,3567h	; Get current Int 67h vector
	 DOSCALL		; ES:BX ==> current holder
	 assume  es:nothing	; Tell the assembler

	 push	 es		; Save vector
	 push	 bx		; Save offset

	 lea	 dx,PGROUP:TMPINT67 ; Address temporary handler
	 mov	 ax,2567h	; Set Int 67 handler
	 DOSCALL		; ...to DS:DX

	 VCPICALL @VCPI_DPRES	; Izit present?

	 pop	 dx		; Restore previous handler's vector
	 pop	 ds		; ...and offset
	 assume  ds:nothing	; Tell the assembler

	 push	 ax		; Save result of VCPICALL

	 mov	 ax,2567h	; Set current Int 67h vector
	 DOSCALL		; ...to previous value in DS:DX

	 pop	 ax		; Restore

	 or	 ah,ah		; Check for presence

	 REGREST <es,ds>	; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler

	 jnz	 near ptr CHECK_EPM_XDBG ; Jump if not

; Display the version #s

	 mov	 ax,bx		; Get the debugger version #
	 lea	 di,MSG_DVER1	; Put formatted value here
	 call	 BIN2WORD	; Convert AX to hex at ES:DI

	 DOSCALL @STROUT,MSG_DVER ; Display it

; Tell SWAT about our new CR3 and linear address

	 mov	 edx,-1 	; Mark as unchanged
	 mov	 ebx,PaCR3	; Get new CR3 physical address
	 VCPICALL @VCPI_DBGLIN	; Set new CR3 and linear address

	 or	 ah,ah		; Check for presence
	 SETMSG  "Error on debugger set CR3 and linear address",ERR
	 jnz	 near ptr CHECK_EPM_ERR ; Jump if in error

; Initialize debugger GDT entries

	 lea	 di,LCLGDT.VCP_SWAT ; ES:DI ==> 1st debugger GDT entry
	 mov	 bx,VCP_SWAT	; Get initial selector
	 VCPICALL @VCPI_DBGINI	; Initialize the GDT entries

	 or	 ah,ah		; Check for presence
	 SETMSG  "Error on debugger GDT initialization",ERR
	 jnz	 near ptr CHECK_EPM_ERR ; Jump if in error

; Initialize the debugger's IDT entries

	 xor	 bx,bx		; Initial interrupt #
	 mov	 cx,20h 	; # interrupt #s
	 lea	 di,LCLIDT	; ES:DI ==> initial IDT entry
	 mov	 edx,PaCR3	; Get physical address of CR3
CHECK_EPM_DBGNEXT:
	 VCPICALL @VCPI_DBGIDT	; Initialize an IDT entry

	 cmp	 ah,83h 	; Check for invalid interrupt #
	 je	 short @F	; Jump if so

	 or	 ah,ah		; Check for presence
	 SETMSG  "Error on debugger GDT initialization",ERR
	 jnz	 near ptr CHECK_EPM_ERR ; Jump if in error
@@:
	 inc	 bx		; Skip to next interrupt #
	 add	 di,size IDT_STR ; Skip to next IDT entry

	 loop	 CHECK_EPM_DBGNEXT ; Jump if more interrupt #s

	 or	 CMD_FLAG,@CMD_SWAT ; Mark as enabled

	 jmp	 short CHECK_EPM_GPMI ; Join common code

CHECK_EPM_XDBG:
	 DISPLAY "様> Debugger not present"
CHECK_EPM_GPMI:
	 DISPLAY "様> Setup for GDT..."

	 call	 SETUP_GDT	; Setup the GDT

;;;;;;;; DISPLAY "様> Setup for IDT..."
;;;;;;;;
;;;;;;;; call	 SETUP_IDT	; Setup the IDT
;;;;;;;;
	 DISPLAY "様> Setup for TSS..."

	 call	 SETUP_TSS	; Setup the TSS

; Check the physical mapping in the first megabyte

	 DISPLAY "様> Checking physical mapping in first megabyte..."

	 mov	 bx,1024/4	; Get # PTEs in first 1MB
	 xor	 cx,cx		; Initialize page number
	 mov	 si,RaPTE	; Initialize index into PTEs
CHECK_EPM_NEXT:
	 VCPIBACK @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to convert linear to physical address",ERR
	 jne	 near ptr CHECK_EPM_ERR ; Jump if in error

	 lodsd			; Get next PTE
	 and	 ax,mask $PTE_FRM ; Isolate the frame

	 cmp	 eax,edx	; Ensure they are the same
	 SETMSG  "Mis-match on linear to physical address mapping",ERR
	 jne	 near ptr CHECK_EPM_ERR ; Jump if in error

	 inc	 cx		; Skip to next page number

	 dec	 bx		; One fewer PTE
	 jnz	 short CHECK_EPM_NEXT ; Jump if more PTEs to check

; Check for invalid linear address

	 test	 CMD_FLAG,@CMD_NOXLA ; Skip check for invalid linear addresses?
	 jnz	 short CHECK_EPM_NOXLA ; Yes

	 DISPLAY "様> Checking invalid linear address..."

	 mov	 cx,-1		; Use invalid linear address
	 VCPIBACK @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX

	 cmp	 ah,8Bh 	; Check for correct error
	 SETMSG  "Invalid error code from invalid linear address",ERR
	 jne	 near ptr CHECK_EPM_ERR ; Jump if in error
CHECK_EPM_NOXLA:

; Setup to Enter and Exit Protected Mode

	 call	 SETUP_EPM	; Set it up

	 DISPLAY "様> Entering protected mode..."

	 lea	 esi,EPMTAB	; Get offset of system tables
	 add	 esi,LaDATA	; Plus base linear address
	 mov	 OLDESP,esp	; Save old stack ptr

	 mov	 PMI_ERR,0	; Start off with no error

	 VCPIBACK @VCPI_EPM	; Enter Protected Mode
CHECK_EPM_PMON:
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

; Ensure no interrupts between above VCPICALL and the following LSS

	 lss	 esp,PMSTK_FVEC ; SS:ESP ==> PM stack
	 assume  ss:nothing	; Tell the assembler about it

	 push	 DTE_DS 	; Get our data selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 DTE_ES 	; Get our extra data selector
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 xor	 ax,ax		; A convenient zero
	 mov	 fs,ax		; Clear selector
	 assume  fs:nothing	; Tell the assembler about it
	 mov	 gs,ax
	 assume  gs:nothing	; Tell the assembler about it

; Call 386SWAT if enabled

	 test	 CMD_FLAG,@CMD_SWAT ; Izit enabled?
	 jz	 short @F	; Not this time

	 int	 01h		; Call the debugger
@@:
; Check # free pages

	 pushad 		; Save all EGP registers

	 mov	 ah,@VCPI	; Get major VCPI function code
	 mov	 al,@VCPI_GNFP	; Get # free 4KB pages into EDX
	 call	 PMI_FWD	; Call PMI code

	 push	 BIT_EAX_EDX	; Pass checking bit vector
	 call	 CHECK_EGP	; Check all EGP registers except EAX and EDX
	 SETMSG  "Mismatch on registers -- GNFP in PMI"
	 jne	 short CHECK_EPM_PMERR ; Jump if mismatch

	 cmp	 edx,NFREE	; Compare 'em
	 SETMSG  "Mismatch on # free pages in PMI"
	 jne	 short CHECK_EPM_PMERR ; Jump if mismatch

; Allocate a 4KB page

	 pushad 		; Save all EGP registers

	 mov	 ah,@VCPI	; Get major VCPI function code
	 mov	 al,@VCPI_ALLOC ; Return physical address in EDX
	 call	 PMI_FWD	; Call PMI code

	 push	 BIT_EAX_EDX	; Pass checking bit vector
	 call	 CHECK_EGP	; Check all EGP registers except EAX and EDX
	 SETMSG  "Mismatch on registers -- ALLOC in PMI"
	 jne	 short CHECK_EPM_PMERR ; Jump if mismatch

	 cmp	 ah,0		; Ensure no error
	 SETMSG  "Unable to allocate a 4KB page in PMI",ERR
	 jne	 short CHECK_EPM_PMERR ; Jump if mismatch

; Free a 4KB page

	 pushad 		; Save all EGP registers

	 mov	 ah,@VCPI	; Get major VCPI function code
	 mov	 al,@VCPI_FREE	; Free physical address in EDX
	 call	 PMI_FWD	; Call PMI code

	 push	 BIT_EAX_EDX	; Pass checking bit vector
	 call	 CHECK_EGP	; Check all EGP registers except EAX and EDX
	 SETMSG  "Mismatch on registers -- FREE in PMI"
	 jne	 short CHECK_EPM_PMERR ; Jump if mismatch

	 cmp	 ah,0		; Ensure no error
	 SETMSG  "Unable to de-allocate a 4KB page in PMI",ERR
	 jne	 short CHECK_EPM_PMERR ; Jump if mismatch

	 jmp	 short CHECK_EPM_PMEXIT ; Join common exit code

CHECK_EPM_PMERR:
	 mov	 PMI_ERR,-1	; Mark as in error

; Return to VM86 mode

CHECK_EPM_PMEXIT:
	 mov	 SAVE_EAX,eax	; Save all EGP registers
	 mov	 SAVE_EBX,ebx
	 mov	 SAVE_ECX,ecx
	 mov	 SAVE_EDX,edx
	 mov	 SAVE_ESI,esi
	 mov	 SAVE_EDI,edi
	 mov	 SAVE_EBP,ebp

	 push	 0		; GS filler
	 push	 gs		; GS
	 push	 0		; FS filler
	 push	 fs		; FS
	 push	 0		; DS filler
	 push	 DATASEG	; DS
	 push	 0		; ES filler
	 push	 DATASEG	; ES
	 push	 0		; SS filler
	 push	 DATASEG	; SS
	 push	 OLDESP 	; ESP
	 push	 dword ptr (-1) ; EFL
	 push	 0		; CS filler
	 push	 CODESEG	; Real mode CS
	 lea	 eax,CHECK_EPM_PMOFF ; Get return address
	 push	 eax		; EIP

	 push	 VCP_4GB	; Get all memory selector
	 pop	 ds		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ah,@VCPI	; Get major VCPI function code
	 mov	 al,@VCPI_EPM	; Return to VM86 mode
	 call	 PMI_FWD	; Call PMI code
CHECK_EPM_PMOFF:
	 assume  ds:PGROUP	; Tell the assembler about it

	 DISPLAY "様> Entering real mode..."
	 DISPLAY "様> Checking for register corruption..."

	 push	 SAVE_EAX	; Put all EGP registers onto the stack
	 push	 SAVE_ECX
	 push	 SAVE_EDX
	 push	 SAVE_EBX
	 push	 dword ptr 0
	 push	 SAVE_EBP
	 push	 SAVE_ESI
	 push	 SAVE_EDI

	 push	 BIT_EAX	; Pass checking bit vector
	 call	 CHECK_EGP	; Check all EGP registers except EAX and EDX
	 SETMSG  "Mismatch on registers -- EPM in PMI"
	 je	 short @F	; Jump if match

	 int	 03h		; Call debugger
@@:
	 cmp	 PMI_ERR,0	; Check for PMI error
	 jne	 short CHECK_EPM_ERR ; Jump if something went wrong

	 clc			; Indicate present

	 jmp	 short CHECK_EPM_EXIT ; Join common exit code

CHECK_EPM_ERR:
	 stc			; Indicate not present
CHECK_EPM_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EPM endp			; End CHECK_EPM procedure
	 NPPROC  CHECK_EGP -- Check EGP Registers Except EAX and EDX
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check all EGP registers on the stack except for EAX and EDX

|

CHK_STR  struc

	 dw	 ?		; Caller's IP
CHK_BIT  dw	 ?		; Bit vector for checking
CHK_EDI  dd	 ?		; Caller's EDI
CHK_ESI  dd	 ?		;	   ESI
CHK_EBP  dd	 ?		;	   EBP
CHK_ESP  dd	 ?		;	   ESP
CHK_EBX  dd	 ?		;	   EBX
CHK_EDX  dd	 ?		;	   EDX
CHK_ECX  dd	 ?		;	   ECX
CHK_EAX  dd	 ?		;	   EAX

CHK_STR  ends

	 test	 [esp].CHK_BIT,mask $EAX ; Check on EAX?
	 jz	 short @F	; Not this time

	 ror	 eax,16 	; Swap low- and high-order words

	 cmp	 ax,[esp].CHK_EAX.EHI ; Check it
	 pushf			; Save flags
	 rol	 eax,16 	; Swap low- and high-order words
	 popf			; Restore flags
	 jne	 short CHECK_EGP_EXIT ; Jump if in error
@@:
	 test	 [esp].CHK_BIT,mask $EBX ; Check on EBX?
	 jz	 short @F	; Not this time

	 cmp	 ebx,[esp].CHK_EBX ; Check on EBX
	 jne	 short CHECK_EGP_EXIT ; Jump if in error
@@:
	 test	 [esp].CHK_BIT,mask $ECX ; Check on ECX?
	 jz	 short @F	; Not this time

	 cmp	 ecx,[esp].CHK_ECX ; Check on ECX
	 jne	 short CHECK_EGP_EXIT ; Jump if in error
@@:
	 test	 [esp].CHK_BIT,mask $EDX ; Check on EDX?
	 jz	 short @F	; Not this time

	 cmp	 edx,[esp].CHK_EDX ; Check on EDX
	 jne	 short CHECK_EGP_EXIT ; Jump if in error
@@:
	 test	 [esp].CHK_BIT,mask $ESI ; Check on ESI?
	 jz	 short @F	; Not this time

	 cmp	 esi,[esp].CHK_ESI ; Check on ESI
	 jne	 short CHECK_EGP_EXIT ; Jump if in error
@@:
	 test	 [esp].CHK_BIT,mask $EDI ; Check on EDI?
	 jz	 short @F	; Not this time

	 cmp	 edi,[esp].CHK_EDI ; Check on EDI
	 jne	 short CHECK_EGP_EXIT ; Jump if in error
@@:
	 test	 [esp].CHK_BIT,mask $EBP ; Check on EBP?
	 jz	 short @F	; Not this time

	 cmp	 ebp,[esp].CHK_EBP ; Check on EBP
	 jne	 short CHECK_EGP_EXIT ; Jump if in error
@@:

; Return to caller with ZF set is OK, clear if not

CHECK_EGP_EXIT:
	 ret	 8*4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_EGP endp			; End CHECK_EGP procedure
	 NPPROC  SETUP_GDT -- Setup The GDT
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup the GDT for EPM

|

	 REGSAVE <eax,ebx>	; Save registers

; Setup local code descriptor

	 push	 LaCODE 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_CODE	; Pass access rights byte
	 push	 DTE_CS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local data descriptor

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_DS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local extra data descriptor

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_ES 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local stack descriptor

	 push	 LaDATA 	; Pass base
	 push	 CON64K 	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 DTE_SS 	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local all memory descriptor

	 push	 dword ptr 0	; Pass base
	 push	 dword ptr 0	; Pass length
	 push	 CPL0_DATA	; Pass access rights byte
	 push	 VCP_4GB	; Pass selector
	 call	 SET_GDT	; Set the GDT

; Setup local TSS descriptor

	 lea	 eax,LCLTSS	; Get local TSS address
	 add	 eax,LaDATA	; Convert from relative to absolute

	 push	 eax		; Pass base
	 push	 dword ptr (size TSS_STR) ; Pass length
	 push	 CPL0_IDLE3	; Pass access rights byte
	 push	 VCP_TR 	; Pass selector
	 call	 SET_GDT	; Set the GDT

	 REGREST <ebx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_GDT endp			; End SETUP_GDT procedure
	 NPPROC  SETUP_TSS --  Setup The TSS
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup the TSS for EPM

|

	 REGSAVE <eax>		; Save register

	 mov	 LCLTSS.TSS_ESP0,offset ds:PMSTKZ
	 mov	 LCLTSS.TSS_SS0,DTE_SS

	 mov	 eax,PaCR3	; Get CR3 physical address
	 mov	 LCLTSS.TSS_CR3,eax ; Save in TSS

	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_TSS endp			; End SETUP_TSS procedure
	 NPPROC  SETUP_EPM -- Setup to Enter and Exit Protected Mode
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup to enter and exit protected mode.

|

	 REGSAVE <eax,ecx,edx,di> ; Save registers

	 mov	 CODESEG,cs	; Save for later use
	 mov	 DATASEG,ds	; Save for later use

; Setup our own CR3

	 mov	 eax,PaCR3	; Get CR3 physical address
	 mov	 EPMTAB.EPM_CR3,eax ; Save in EPMTAB

; Setup pointer to local GDT

	 lea	 eax,LCLGDT	; Get offset
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 LCLGDT.DTE_GDT.DTR_BASE,eax ; Save as linear address of GDT
	 mov	 LCLGDT.DTE_GDT.DTR_LIM,(size VDTE_STR)-1 ; Save as limit

	 lea	 eax,LCLGDT.DTE_GDT ; Get pointer
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 EPMTAB.EPM_GDTP,eax ; Save it

; Setup pointer to local IDT
; Note that the IDT has *NOT* been filled in

	 lea	 eax,LCLIDT	; Get offset
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 LCLGDT.DTE_IDT.DTR_BASE,eax ; Save as linear address of IDT
	 mov	 LCLGDT.DTE_IDT.DTR_LIM,32*8-1 ; Save as limit

	 lea	 eax,LCLGDT.DTE_IDT ; Get pointer
	 add	 eax,LaDATA	; Plus linear address of data segment
	 mov	 EPMTAB.EPM_IDTP,eax ; Save it

; Setup local LDT and TR

	 mov	 EPMTAB.EPM_LDTR,0 ; Don't use one
	 mov	 EPMTAB.EPM_TR,VCP_TR ; Use local one

; Setup return address

	 mov	 EPMTAB.EPM_EXIT.FOFF,offset cs:CHECK_EPM_PMON
	 mov	 EPMTAB.EPM_EXIT.FSEL,DTE_CS ; Save our code selector

	 REGREST <di,edx,ecx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_EPM endp			; End SETUP_EPM procedure
	 NPPROC  SETUP_IDT -- Setup Interrupt Descriptor Table
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup the interrupt descriptor table

|

	 REGSAVE <>		; Save registers




	 REGREST <>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_IDT endp			; End SETUP_IDT procedure
	 NPPROC  SET_GDT -- Set Global Descriptor Table
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set the blobal descriptor table.

|

SET_GDT_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
SET_GDT_DTE dw	 ?		; DTE to set
SET_GDT_ARB db	 ?,?		; Access rights byte
SET_GDT_LEN dd	 ?		; Segment length
SET_GDT_BAS dd	 ?		; Segment base

SET_GDT_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,bx,ecx>	; Save registers

	 mov	 eax,[bp].SET_GDT_BAS ; Get segment base
	 mov	 ecx,[bp].SET_GDT_LEN ; Get segment length
	 dec	 ecx		; Convert from length to limit

	 cmp	 ecx,CON1M	; Check against limit limit
	 jb	 short @F	; Jump if within range

	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 or	 ecx,(mask $DTE_G) shl 16 ; Set G-bit
@@:
	 mov	 bx,[bp].SET_GDT_DTE ; Get the DTE to set

	 mov	 LCLGDT.DESC_BASE01.EDD[bx],eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 LCLGDT.DESC_BASE3[bx],al ; Save as base byte #3
	 ror	 eax,8		; Rotate back
	 mov	 LCLGDT.DESC_SEGLM0[bx],cx ; Save as data limit
	 rol	 ecx,16 	; Swap high- and low-order words
	 mov	 LCLGDT.DESC_SEGLM1[bx],cl ; Save as data limit
;;;;;;;; ror	 ecx,16 	; Swap back

; Set access rights byte

	 mov	 al,[bp].SET_GDT_ARB ; Get it
	 mov	 LCLGDT.DESC_ACCESS[bx],al ; Set it

	 REGREST <ecx,bx,eax>	; Restore

	 pop	 bp		; Restore

	 ret	 2*2+2*4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_GDT  endp			; End SET_GDT procedure
	 NPPROC  SETUP_PMI -- Setup Get Protected Mode Interface
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Setup Get Protected Mode Interface

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,si,di> ; Save registers

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,ds		; Get our data segment
	 shl	 eax,4-0	; Convert to paras to bytes
	 mov	 LaCODE,eax	; Save as our code's linear base address
	 mov	 LaDATA,eax	; Save as our data's linear base address

	 movzx	 eax,NEXTLOC	; Get offset of next available byte
	 add	 eax,LaDATA	; Plus its linear base address
	 add	 eax,4096-1	; Round up ...
	 and	 eax,not (4096-1) ; ...to 4KB boundary
	 mov	 LaCR3,eax	; Save as linear address of CR3
	 add	 eax,4096	; Skip over PDIR
	 mov	 LaPTE,eax	; Save as linear address of PTEs

	 mov	 eax,LaCR3	; Get linear address
	 sub	 eax,LaDATA	; Convert from linear to relative
	 mov	 RaCR3,ax	; Save for later use

	 mov	 ecx,LaCR3	; Get linear address
	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 VCPIBACK @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX
	 mov	 PaCR3,edx	; Save for later use

	 mov	 eax,LaPTE	; Get linear address
	 sub	 eax,LaDATA	; Convert from linear to relative
	 mov	 RaPTE,ax	; Save for later use

; Setup our own PDIR with two PDEs

	 mov	 ecx,LaPTE	; Get its linear address
	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 VCPIBACK @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX

	 mov	 eax,edx	; Copy to output register
	 mov	 di,RaCR3	; Get relative address of CR3
	 or	 eax,@PTE_URP	; Mark as User/Read-Write/Present
	 stosd			; Save as 1st PDE

	 mov	 ecx,LaPTE	; Get its linear address
	 add	 ecx,CON4K	; Skip to next PTE
	 shr	 ecx,12-0	; Convert from bytes to 4KB
	 VCPIBACK @VCPI_L2P	; Convert linear addr in CX to phys addr in EDX

	 mov	 eax,edx	; Copy to output register
	 or	 eax,@PTE_URP	; Mark as User/Read-Write/Present
	 stosd			; Save as 2nd PDE

	 DISPLAY "様> Reading Protected Mode Interface data..."

	 lea	 si,VCPGDT	; DS:SI ==> three DTEs for PMI
	 mov	 di,RaPTE	; ES:DI ==> PTEs
	 VCPIBACK @VCPI_GPMI	; Return with EBX=offset, DI=advanced

	 mov	 PMI_FWD.FOFF,ebx ; Save offset of PMI
	 mov	 PMI_FWD.FSEL,VCP_PMCS ; Save selector of PMI
	 mov	 NEXTPTE,di	; Save offset of next PTE
	 mov	 NEXTLOC,di	; Save offset of next available byte

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to read Protected Mode Interface data",ERR
	 je	 short SETUP_PMI_EXIT ; Jump if OK (note CF=0)

	 stc			; Mark as in error
SETUP_PMI_EXIT:
	 REGREST <di,si,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SETUP_PMI endp			; End SETUP_PMI procedure

CODE	 ends			; End CODE segment

	 MEND			; End VCP_EPM module
