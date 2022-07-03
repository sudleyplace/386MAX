;' $Header:   P:/PVCS/MAX/386MAX/QMAX_I09.ASV   1.2   30 May 1997 10:44:36   BOB  $
	 title	 QMAX_I09 -- 386MAX INT 09h Handler
	 page	 58,122
	 name	 QMAX_I09

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment HICODE,dword-aligned, public, class 'prog'
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
	 include ASCII.INC
	 include 386.INC
	 include 8255.INC
	 include KEYCALL.INC
	 include BITFLAGS.INC
	 include CPUFLAGS.INC
	 include BIOSDATA.INC
	 include PTR.INC
	 include VDISK.INC
	 include INTVEC.INC
	 include SCANCODE.INC
	 include ALLMEM.INC

	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
	 include QMAX_SWT.INC	; For SWAT
.list

PGROUP	 group	 CODE,HICODE,ECODE,EDATA
FGROUP	 group	 FDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 SHADOW_ENABLE:near
;;;;;;;; extrn	 PPI_S2C:near

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC

	 extrn	 LOWSIZE:word

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  ds:PGROUP

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

HICODE	 ends			; End HICODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  cs:PGROUP

	 extrn	 PPDTMAP:dword
	 extrn	 MAPBASE:dword
	 extrn	 OLDINT_VECS:dword
	 extrn	 LaCVD:dword

	 extrn	 PPL0STK_NRM:dword
	 extrn	 LAST_INTCOM:dword

	 extrn	 MAPTAB_CNT:word
	 include QMAX_MAP.INC

if @OEM_DMA
	 extrn	 DMA_CHAN:byte
endif				; IF @OEM_DMA

	 extrn	 LaVROM_BEG:dword
	 extrn	 LaVROM_END:dword

EDATA	 ends			; End EDATA segment


FDATA	 segment use16 dword public 'fixup' ; Start FDATA segment
	 assume  ds:FGROUP

	 extrn	 MSG_ICTRL:byte

FDATA	 ends			; End FDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_I09_ECODE
@QMAX_I09_ECODE:even		; Mark module start in .MAP file

	 extrn	 INTPROC00Z:near
	 extrn	 INTPROC09:near
	 extrn	 FLUSH_TLB:near
	 extrn	 SWAP_MAP:near
	 extrn	 GOREAL_REBOOT:near
	 extrn	 DSTK_CHK:near

	 FPPROC  INT09 -- Hardware Keystroke Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 cmp	 esp,PPL0STK_NRM ; Is the stack normal?
	 jne	 short INT09_XDSTKCHK ; No

; See if we should switch to our local DOS stack

	 test	 I15_FLAG,@I15_DSTK ; Izit active?
	 jz	 short @F	; Jump if not

	 mov	 [esp].NRM_INTNO,4*09h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 09h

; If this is a HW interrupt subject to DOS stacks, switch stacks

	 call	 DSTK_CHK	; Check it out
	 assume  ds:nothing	; Tell the assembler about it
@@:
INT09_XDSTKCHK:
	 test	 [esp].NRM_EFL.EHI,mask $VM ; Izit from VM 8086 mode?
	 jz	 near ptr INTPROC09 ; Jump if not (INTCOM catches DPMI calls)

	 push	 ax		; Save for a moment

; Check for Ctrl-Alt-Del if we're on an XT or an Inboard/AT
; As it turns out, the INBRDAT.SYS driver reboots the system
; by itself from its INT 09h handler, so we can't afford to
; wait for the AX=4F53h from INT 15h.  Thus we must catch it here.

	 test	 SYS_FLAG,@SYS_INBRDAT ; Izit an Inboard/AT?
	 jnz	 short @F	; Yes

	 test	 LCL_FLAG,@LCL_XT ; Running on an XT?
	 jz	 near ptr INT09_ROM ; Not this time
@@:

; Check for Ctrl-Alt-Del

	 call	 GETSHIFT	; Return with shift states in AL
	 assume  gs:nothing	; Tell the assembler about it

	 and	 al,(mask $DALT) or (mask $DCTL) ; Isolate just these two

	 cmp	 al,(mask $DALT) or (mask $DCTL) ; Ctrl and Alt pressed?
	 jne	 near ptr INT09_ROM ; Not this time

; Read in the scan code to check for the Delete key

	 in	 al,@8255_A	; Read in the scan code

	 cmp	 al,@SSC_DEL	; Check for Delete key
	 jne	 near ptr INT09_ROM ; Not this time

	 pop	 ax		; Restore

	 test	 LCL_FLAG,@LCL_XT ; Running on an XT?
	 jnz	 short INT09_XLHI ; Yes, no need to disable

; If we're loaded into high DOS memory, to enable other programs
; to catch the reboot, we signal it via INT 15h function 4F

	 push	 ds		; Save for a moment

	 push	 DTE_DSHI	; Get address of high DOS memory data
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 test	 LCL_FLAG,@LCL_LODHI ; Loading high?
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it
	 jz	 short INT09_XLHI ; No, no need to signal it

	 push	 ax		; Save for a moment

	 mov	 ax,4F53h	; Signal Delete key pressed
	 stc			; Assume no problem
	 int	 15h		; Call low memory handler
	 jnc	 near ptr INT09_ROM ; Jump if we're to ignore it

	 pop	 ax		; Restore

; In case @LCL_FST was set, we didn't disable the keyboard
; above -- do it now.
;;;;;;;;
;;;;;;;; test	 LCL_FLAG,@LCL_FST ; Fast keyboard?
;;;;;;;; jz	 short INT09_XLHI ; No, so it was disabled above
;;;;;;;;
;;;;;;;; mov	 ah,@S2C_DIS	; Code to disable the keyboard
;;;;;;;; call	 PPI_S2C	; Send command AH to 8042
INT09_XLHI:

COMMENT|

Distinguish between two cases:

Type		 Mode	  Test			Action
--------------------------------------------------------------------
Hardware	 VM86	  ESP=PPL0STK_NRM	Goto INT09_NRM
Hardware	 PM	  CS=[EBP].NRM_CS	Strip back stack to LAST_INTCOM

|

	 cmp	 esp,PPL0STK_NRM ; Is the stack normal?
	 je	 short INT09_NRM ; Yes, it must have come from VM86 mode

; Note that interrupts are disabled at this point

	 mov	 esp,LAST_INTCOM ; Get offset of bottom of last INTCOM_STR
				; interrupt frame
INT09_NRM:
	 PUSHD	 0		; Put pseudo-error code onto stack

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 cld			; String ops forwardly
	 mov	 ebp,esp	; Address the stack

	 mov	 [ebp].INTXX_INTNO,4*09h + offset PGROUP:INTPROC00Z ; Mark as hardware INT 09h

; Mark return address as that of INT 09h handler

	 sub	 [ebp].INTXX_ESP.ELO,6 ; Make room for FL, IP, and CS
				; Ignore carry flag

; Save CS, IP, and FL on PL3 stack as in a real mode interrupt

	 push	 DTE_D4GB	; Selector of all memory as data
	 pop	 ds		; Address it
	 assume  ds:AGROUP	; Tell the assembler about it

	 movzx	 edi,[ebp].INTXX_SS ; Get stack segment
	 shl	 edi,4-0	; Convert from paras to bytes
	 movzx	 ebx,[ebp].INTXX_ESP.ELO ; Get caller's ESP

; Get the appropriate INT 09h vector
; If there is any high or low DOS memory fill, use OLDINT_VECS[4*09h];
; otherwise, use the 0:4*09h vector

	 mov	 eax,AGROUP:[09h*(type INT00_VEC)] ; Get current handler

	 test	 CMD_FLAG,@CMD_XHI ; High DOS memory excluded?
	 jz	 short @F	; No, so it's in use

	 cmp	 LOWSIZE,0	; Check the sign
	 jle	 short INT09_CAD_NOFILL ; Jump if no low fill for DOS
@@:
	 mov	 eax,OLDINT_VECS[09h*(type INT00_VEC)] ; Get original handler
INT09_CAD_NOFILL:
	 xchg	 ax,[ebp].INTXX_EIP.ELO ; Swap IPs
	 mov	 AGROUP:[edi+ebx],ax ; Save on PL3 stack

	 shr	 eax,16 	; Shift segment down to low-order
	 add	 bx,2		; Account for saved word, emulate 64KB wrap

	 xchg	 ax,[ebp].INTXX_CS ; Swap CSs
	 mov	 AGROUP:[edi+ebx],ax ; Save on PL3 stack

	 add	 bx,2		; Account for saved word, emulate 64KB wrap

	 mov	 ax,[ebp].INTXX_EFL.ELO ; Get FL (as opposed to EFL)
	 mov	 AGROUP:[edi+ebx],ax ; Save on PL3 stack

; Clear any VDISK signature

	 mov	 edi,LaCVD	; Get linear address of pseudo-1MB PTE

	 cmp	 AGROUP:[edi].VDISK_VEND.EDD,'SIDV' ; Signature present?
	 jne	 short @F	; Not this time

	 mov	 AGROUP:[edi].VDISK_VEND,0 ; Invalidate the signature
@@:

; Turn off trap, interrupt, and nested task flags in PL0 stack

	 and	 [ebp].INTXX_EFL.ELO,not ((mask $TF) or (mask $IF) or (mask $NT))

	 lea	 bx,FGROUP:MSG_ICTRL ; Offset of user message

	 jmp	 GOREAL_REBOOT	; Exit from protected mode and reboot

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT09_ROM:
	 pop	 ax		; Restore

	 PUSHD	 0		; Put pseudo-error code onto stack

	 pushad 		; Save all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]
	 cld			; String ops forwardly
	 mov	 ebp,esp	; Address the stack

	 test	 GLB_FLAG,@GLB_ROM ; Needing ROM swap?
	 jz	 short INT09_EXIT ; Not this time

if @OEM_DMA
	 cmp	 DMA_CHAN,0	; Any DMA channels in use?
	 jne	 short INT09_EXIT ; Yes, wait for the next keystroke
endif				; IF @OEM_DMA

; In case this ROM uses multiple pages, don't swap it out if we're
; interrupting it in segment LaVROM_BEG to LaVROM_END

	 movzx	 eax,[ebp].INTXX_CS ; Get caller's segment
	 shl	 eax,4-0	; Convret from paras to bytes

	 cmp	 eax,LaVROM_BEG ; In starting video ROM segment?
	 jb	 short @F	; Jump if too small

	 cmp	 eax,LaVROM_END ; Check against upper limit of video ROM
	 jb	 short INT09_EXIT ; It's within range, wait for the next keystroke
@@:

; Swap the pages beginning at MAPBASE with the entries in MAPTAB

	 push	 DTE_DS 	; Get data selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 DTE_PDT	; Get PDT selector
	 pop	 fs		; Address it
	 assume  fs:nothing	; Tell the assembler about it

	 mov	 cx,MAPTAB_CNT	; Get # entries in table
	 jcxz	 INT09_MAP_NONE ; Skip out if nothing to do
	 mov	 edx,MAPBASE	; Get linear address of map base
	 mov	 esi,PPDTMAP	; Initialize offset into MAPBASE area
	 xor	 di,di		; Initialize index to MAPTAB
INT09_MAP_NEXT:
	 call	 SWAP_MAP	; Swap PTEs for MAP, increment ESI and EDX

	 add	 di,type MAP_STR ; Skip to next entry

	 loop	 INT09_MAP_NEXT ; Jump if more entries

; Because we just changed the page table, we must flush the TLB

	 call	 FLUSH_TLB	; Flush the TLB
INT09_MAP_NONE:
	 and	 GLB_FLAG,not @GLB_ROM ; Mark as no longer needing ROM swap

; If we're on a SHADOWRAM system, restore the new CHIPset register values

	 call	 SHADOW_ENABLE	; Set shadow RAM on CHIPSets to read-write

	 assume  ds:nothing	; Tell the assembler about it

INT09_EXIT:
	 popad			; Restore all EGP registers
				; N.B.:  Do not follow with [EAX+???*?]

	 add	 esp,size INTXX_ERR ; Strip off pseudo-error code

	 jmp	 INTPROC09	; Continue on

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT09	 endp			; End INT09 procedure
	 NPPROC  GETSHIFT -- Get Keyboard Shift States
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get keyboard shift states

On exit:

AL	 =	 keyboard Ctrl-, Alt-, and L&R-shift states
ZF	 =	 1 if all states off
	 =	 0 otherwise
GS	 =	 DTE_D4GB

|

	 REGSAVE <bx>		; Save for a moment

	 push	 DTE_D4GB	; Get selector for all of memory
	 pop	 gs		; Address it
	 assume  gs:BIOSDATA	; Tell the assembler about it

	 mov	 bx,seg BIOSDATA ; Get segment of BIOS data area
	 shl	 bx,4-0 	; Convert from paras to bytes

	 mov	 al,KB_FLAG[bx] ; Get keyboard flags

; Isolate Ctrl, Alt, and L&R Shift states

	 and	 al,(mask $DALT) or (mask $DCTL) or (mask $DLSH) or (mask $DRSH)
	 REGREST <bx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETSHIFT endp			; End GETSHIFT procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment

	 MEND			; End QMAX_I09 module
