;' $Header:   P:/PVCS/MAX/386MAX/QMAX_EEM.ASV   1.3   30 May 1997 10:44:18   BOB  $
	 title	 QMAX_EEM -- 386MAX INT 67h Handler, EEMS Functions
	 page	 58,122
	 name	 QMAX_EEM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'

Link requirements:  Final routine should have extension .SYS.

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC

	 include QMAX_DTE.INC
	 include QMAX_EMM.INC
	 include QMAX_OEM.INC
.list

if @OEM_EEMS

PGROUP	 group	 CODE,ECODE,EDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  cs:PGROUP

	 extrn	 PPMTAB:byte,PPMTAB_LEN:abs
	 include QMAX_PPM.INC

	 extrn	 NPHYS16F:byte
	 extrn	 NPHYS16S:byte
	 extrn	 FRAME:word
	 extrn	 PSEG2PHYS:dword
	 extrn	 RPNCUR:byte


	 public  EGETSET_FNS
EGETSET_FNS label word
	 dw	 PGROUP:EMM_EGETSET0
	 dw	 PGROUP:EMM_EGETSET1
	 dw	 PGROUP:EMM_EGETSET2
	 dw	 PGROUP:EMM_EGETSET3
;;;;;;;; dw	 PGROUP:EMM_EGETSET4
;;;;;;;; dw	 PGROUP:EMM_EGETSET5
;;;;;;;; dw	 PGROUP:EMM_EGETSET6
EGETSET_CNT equ ($-EGETSET_FNS)/2

EDATA	 ends			; End EDATA segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_EEM_ECODE
@QMAX_EEM_ECODE:nop		; Mark module start in .MAP file

	 extrn	 EMM_E00:near
	 extrn	 EMM_E00AL:near
	 extrn	 EMM_E83:near
	 extrn	 EMM_E84:near
	 extrn	 EMM_E8A:near
	 extrn	 EMM_E8B:near
	 extrn	 EMM_E8F:near
	 extrn	 EMM_EA3:near

	 extrn	 VALID_HNDL:near
	 extrn	 COPY2LCL:near
	 extrn	 PGMAP_COM:near
	 extrn	 PL3ESDI:near
	 extrn	 PL3DSSI:near
	 extrn	 RPN_DIFF:near

	 NPPROC  EMM_EGETPHYS -- EEMS Get Standard Physical Array
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

EMM Function 33, AH = 60h

EEMS Get standard physical page array.

Store into ES:DI the standard physical page address array.
Store into AL the entry count.

Error return 84 if EEMS not specified.

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 test	 CM2_FLAG,@CM2_EEMS ; EEMS specified?
	 jz	 near ptr EMM_E84 ; No, so call it an invalid function

	 call	 PL3ESDI	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,NPHYS16F.ELO ; Get # physical 16KB pages in EMS frame
	 mov	 bl,cl		; Initialize counter

	 jcxz	 EMM_EGETPHYS_PPM ; Empty EMS frame

	 mov	 ax,FRAME	; Get segment of EMS frame
	 shr	 ax,14-4	; Convert from paras to 16KB
EMM_EGETPHYS_NEXT1:
S32	 stos	 es:[edi].ELO	; Save in output area

	 inc	 ax		; Skip to next 16KB page

	 loop	 EMM_EGETPHYS_NEXT1 ; Jump if more 16KB pages in EMS frame

; Loop through PPMTAB looking for entries outside of conventional memory,
; that is, INC and SCR entries

EMM_EGETPHYS_PPM:
	 lea	 si,PPMTAB	; DS:SI ==> Physical Page Map table
	 mov	 cx,PPMTAB_LEN	; CX = PPMTAB length
EMM_EGETPHYS_NEXT2:
	 lodsb			; Get next marker
	 and	 al,not mask $PPM_SHD ; Clear shadow RAM marker

	 cmp	 al,@PPM_INC	; Izit an INCLUDEd memory marker?
	 je	 short EMM_EGETPHYS_SAVE ; Yes, save it's segment

	 cmp	 al,@PPM_SCR	; Izit a SCREEN memory marker?
	 jne	 short EMM_EGETPHYS_LOOP ; No, skip it
EMM_EGETPHYS_SAVE:
	 inc	 bl		; Account for it
	 mov	 ax,si		; Copy offset
	 sub	 ax,1+offset ds:PPMTAB ; Convert to origin-0

S32	 stos	 es:[edi].ELO	; Save in output area
EMM_EGETPHYS_LOOP:
	 loop	 EMM_EGETPHYS_NEXT2 ; Jump if more entries

	 mov	 [ebp].INTXX_EAX.ELO.LO,bl ; Return in AL

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing

EMM_EGETPHYS endp		; End EMM_EGETPHYS procedure
	 NPPROC  EMM_EGETSYS -- EEMS Get System Physical Array
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

EMM Function 41, AH = 68h

EEMS Get system physical page array.

Store into ES:DI the system physical page address array.
Store into AL the entry count.

Error return 84 if EEMS not specified.

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 test	 CM2_FLAG,@CM2_EEMS ; EEMS specified?
	 jz	 near ptr EMM_E84 ; No, so call it an invalid function

	 call	 PL3ESDI	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  es:nothing	; Tell the assembler about it

; Loop through PPMTAB looking for any mappable entries

	 lea	 si,PPMTAB	; DS:SI ==> Physical Page Map table
	 mov	 cx,PPMTAB_LEN	; CX = PPMTAB length
	 xor	 bl,bl		; Initialize counter
EMM_EGETSYS_NEXT2:
	 lodsb			; Get next marker
	 and	 al,not mask $PPM_SHD ; Clear shadow RAM marker

	 cmp	 al,@PPM_CNV	; Izit a conventional memory marker?
	 je	 short EMM_EGETSYS_SAVE ; Yes, save it's segment

	 cmp	 al,@PPM_INC	; Izit an INCLUDEd memory marker?
	 je	 short EMM_EGETSYS_SAVE ; Yes, save it's segment

	 cmp	 al,@PPM_FRM	; Izit an EMS frame memory marker?
	 je	 short EMM_EGETSYS_SAVE ; Yes, save it's segment

	 cmp	 al,@PPM_SCR	; Izit a SCREEN memory marker?
	 jne	 short EMM_EGETSYS_LOOP ; No, skip it
EMM_EGETSYS_SAVE:
	 inc	 bl		; Account for it
	 mov	 ax,si		; Copy offset
	 sub	 ax,1+offset ds:PPMTAB ; Convert to origin-0

S32	 stos	 es:[edi].ELO	; Save in output area
EMM_EGETSYS_LOOP:
	 loop	 EMM_EGETSYS_NEXT2 ; Jump if more entries

	 mov	 [ebp].INTXX_EAX.ELO.LO,bl ; Return in AL

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing

EMM_EGETSYS endp		; End EMM_EGETSYS procedure
	 NPPROC  EMM_EPGMAP -- EEMS Map Handle Page
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

EMM Function 42, AH = 69h

EEMS Map handle page.

For handle DX, map logical 16KB page BX to physical 16KB page AL

Error return 83 if DX not valid handle
	     8A if BX >= # 16KB pages allocated to handle DX
	     8B if AL >= NPHYS16S
	     84 if EEMS not specified

All registers except EBP, SS, and ESP may be destroyed.

|

	 sti			; Allow interrupts

	 test	 CM2_FLAG,@CM2_EEMS ; EEMS specified?
	 jz	 near ptr EMM_E84 ; No, so call it an invalid function

	 call	 VALID_HNDL	; Ensure it's a valid handle
	 jnc	 near ptr EMM_E83 ; It's not

	 cmp	 al,NPHYS16S	; Check physical 16KB page # (origin-0)
	 jnb	 near ptr EMM_E8B ; It's too big

	 mov	 ebx,PSEG2PHYS	; DS:EBX ==> translate table
	 xlat	 PSEG2PHYS.LO[ebx] ; Translate window # to physical 16KB page #
	 mov	 bl,al		; Copy to safe register

	 cli			; Disallow interrupts

	 push	 [ebp].INTXX_EDX.ELO ; Pass the handle
	 push	 [ebp].INTXX_EBX.ELO ; Pass the logical 16KB page # (origin-0)
	 push	 bx		; Pass the physical 16KB page # (origin-0)
	 call	 PGMAP_COM	; Call common page map routine
	 jc	 near ptr EMM_E8A ; Jump if logical page # not found
				; Return with AX = RPN
	 mov	 cx,ax		; Copy to use AX

; Keep the RPNCUR up-to-date with the RPN for this physical page

	 mov	 al,size RPN_STR ; Get size of structure
	 mul	 bl		; Times physical 16KB page # (origin-0)
	 mov	 di,ax		; Copy to index register
	 mov	 RPNCUR.RPN_RPN[di],cx ; Save in structure

	 sti			; Allow interrupts

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing

EMM_EPGMAP endp 		; End EMM_EPGMAP procedure
	 NPPROC  EMM_EGETSET -- EEMS Get/Set Page Mapping Registers
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

EMM Function 43, AH = 6Ah

EEMS Get/Set Page Mapping Registers (actually RPNs)

Error return 8F if subfunction parameter invalid
	     84 if EEMS not specified.

|

	 test	 CM2_FLAG,@CM2_EEMS ; EEMS specified?
	 jz	 near ptr EMM_E84 ; No, so call it an invalid function

	 cmp	 al,EGETSET_CNT  ; Check for valid subfunction range
	 jnb	 near ptr EMM_E8F ; It's too big

	 movzx	 ebx,al 	; Copy to index register, clear high-order bytes

	 jmp	 EGETSET_FNS[ebx*2] ; Take appropriate action

	 assume  ds:nothing,es:nothing

EMM_EGETSET endp		; End EMM_EGETSET procedure
	 NPPROC  EMM_EGETSET0 -- EEMS Store Page Mapping Registers
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

EMM Function 43, AX = 6A00h

Store Page Mapping Registers

Store the contents of the page mapping registers at ES:DI

Error return 8B if a window # is out of range

|

	 sti			; Allow interrupts

	 call	 ERPN_STORE	; Store 'em out
	 jc	 near ptr EMM_E8B ; It's too big

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing

EMM_EGETSET0 endp		; End EMM_EGETSET0 procedure
	 NPPROC  EMM_EGETSET1 -- EEMS Restore Page Mapping Registers
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

EMM Function 43, AX = 6A01h

Restore Page Mapping Registers

Read the contents of the page mapping registers from DS:SI

Error return A3 if any logical or physical page is out of range

|

	 sti			; Allow interrupts

	 call	 ERPN_READ	; Read 'em in
	 jc	 near ptr EMM_EA3 ; Something went wrong

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing

EMM_EGETSET1 endp		; End EMM_EGETSET1 procedure
	 NPPROC  EMM_EGETSET2 -- EEMS Store and Restore Page Mapping Registers
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

EMM Function 43, AX = 6A02h

Store/restore Page Mapping Registers

Store the contents of the page mapping registers at ES:DI,
then read the contents of the page mapping registers from DS:SI

Error return 8B if a window # is out of range
	     A3 if any logical or physical page in DS:SI is out of range

|

	 sti			; Allow interrupts

	 call	 ERPN_STORE	; Store 'em out
	 jc	 near ptr EMM_E8B ; It's too big

	 call	 ERPN_READ	; Read 'em in
	 jc	 near ptr EMM_EA3 ; Something went wrong

	 jmp	 EMM_E00AL	; Join common OK code

	 assume  ds:nothing,es:nothing

EMM_EGETSET2 endp		; End EMM_EGETSET2 procedure
	 NPPROC  EMM_EGETSET3 -- EEMS Get Size of Page Mapping Registers
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

EMM Function 43, AX = 6A03h

Get Page Mapping Registers size for window #s [CH, CH+CL)

Return in AL size in bytes of RPNs in user's save area

Error return 8B if a window # is out of range

|

	 sti			; Allow interrupts

	 call	 ERPN_SIZE	; Get size of array into AX
	 jc	 near ptr EMM_E8B ; It's too big

	 inc	 al		; Plus one for context #

	 jmp	 EMM_E00	; Join common OK code

	 assume  ds:nothing,es:nothing

EMM_EGETSET3 endp		; End EMM_EGETSET3 procedure
	 NPPROC  ERPN_STORE -- EEMS Store RPNs Out
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

Store the current Page Mapping Registers for windows [CH, CH+CL)
into user's data area.

On exit:

CF	 =	 0 if all went well
	 =	 1 if window # out of range

|

	 REGSAVE <ax,ebx,ecx,esi,edi,es> ; Save registers

	 call	 PL3ESDI	; Convert PL3 ES:DI to DTE_D4GB:EDI
	 assume  es:nothing	; Tell the assembler about it

	 mov	 al,[ebp].INTXX_ECX.ELO.HI ; Get starting window #

	 cmp	 al,NPHYS16S	; Check physical 16KB page # (origin-0)
	 jnb	 short ERPN_STORE_ERR ; It's too big

	 mov	 ebx,PSEG2PHYS	; DS:EBX ==> translate table
	 xlat	 PSEG2PHYS.LO[ebx] ; Translate window # to physical 16KB page #
	 mov	 ah,size RPN_STR ; Get size of each RPN entry
	 mul	 ah		; AX = offset into RPNCUR of physical 16KB page
	 mov	 si,ax		; Copy to index register

	 lea	 esi,RPNCUR[si] ; DS:ESI ==> corresponding entries in RPNCUR

	 call	 ERPN_SIZE	; Get size of array into AX
	 jc	 short ERPN_STORE_ERR ; Jump if out of range

	 movzx	 ecx,ax 	; Copy to count register

	 mov	 al,0		; Mark as context #0
S32	 stos	 es:[edi].LO	; Save in user's data area

	 pushf			; Save flags
	 cli			; Disallow interrupts

S32  rep movs	 <es:[edi].LO,ds:[esi].LO> ; Move the bytes

	 popf			; Restore

	 clc			; Indicate all went well

	 jmp	 short ERPN_STORE_EXIT ; Join common exit code

ERPN_STORE_ERR:
	 stc			; Indicate window # out of range
ERPN_STORE_EXIT:
	 REGREST <es,edi,esi,ecx,ebx,ax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

ERPN_STORE endp 		; End ERPN_STORE procedure
	 NPPROC  ERPN_READ -- EEMS Read RPNs In
	 assume  ds:PGROUP,es:PGROUP
COMMENT|

Read Page Mapping Registers for the windows [CH, CH+CL)
from user's data area.

Note that we read the data into local storage before
remapping any pages.  That way the user's data area can
reside in a page about to mapped out.

On exit:

CF	 =	 0 if all went well
	 =	 1 if something went wrong

|

	 REGSAVE <ax,ebx,ecx,edx,esi,edi,ds> ; Save registers

	 call	 PL3DSSI	; Convert PL3 DS:SI to DTE_D4GB:ESI
	 assume  ds:nothing	; Tell the assembler about it

	 lods	 ds:[esi].LO	; Get context #

	 cmp	 al,1		; Ensure it's within range
	 jb	 short ERPN_READ_EXIT ; Jump if out of range (note CF=1)

; Copy the input at DS:ESI into local storage in case we're
; about to pull the rug out from under the data.

	 call	 ERPN_SIZE	; Get size of array into AX
	 jc	 short ERPN_READ_EXIT ; Jump if out of range (note CF=1)

	 movzx	 ecx,ax 	; Copy to count register
	 mov	 edx,esp	; Save stack offset
	 sub	 esp,ecx	; Make room on the stack

	 call	 COPY2LCL	; Copy CX bytes from DS:ESI to local storage
	 assume  ds:PGROUP	; Tell the assembler about it

	 call	 ERPN_CNT	; Get count of array into AL
	 jc	 short ERPN_READ_EXIT ; Jump if out of range (note CF=1)

	 xor	 ch,ch		; Zero to use as word
	 mov	 cl,al		; Copy to count register

	 mov	 al,[ebp].INTXX_ECX.ELO.HI ; Get starting window #
	 mov	 ebx,PSEG2PHYS	; ES:EBX ==> translate table
	 xlat	 PSEG2PHYS.LO[ebx] ; Translate window # to physical 16KB page #

	 mov	 ah,size RPN_STR ; Get size of each RPN entry
	 mul	 ah		; AX = byte size of windows [CH, CH+CL)
	 mov	 di,ax		; Copy to index register
	 lea	 edi,RPNCUR[di] ; ES:EDI ==> starting entry in RPNCUR

	 call	 RPN_DIFF	; Remap CX RPNs at DS:ESI which differ
	 mov	 esp,edx	; Cut back the stack
				; Return with CF=1 if error
ERPN_READ_EXIT:
	 REGREST <ds,edi,esi,edx,ecx,ebx,ax> ; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

ERPN_READ endp			; End ERPN_READ procedure
	 NPPROC  ERPN_CNT -- Get Count of ERPN Array
	 assume  ds:nothing,es:nothing
COMMENT|

On exit:

AX	 =	 count of window #s [CH, CH+CL)

|

	 mov	 al,[ebp].INTXX_ECX.ELO.LO ; Get window count

	 cmp	 al,0		; Check for all windows
	 ja	 short ERPN_CNT_EXIT ; Jump if some windows (note CF=0)

	 mov	 al,NPHYS16S	; Get # physical 16KB pages in EMS system

	 sub	 al,[ebp].INTXX_ECX.ELO.HI ; Less starting window #
				; Return with CF significant
ERPN_CNT_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

ERPN_CNT endp			; End ERPN_CNT procedure
	 NPPROC  ERPN_SIZE -- Check Size of ERPN Array
	 assume  ds:nothing,es:nothing
COMMENT|

Check size of ERPN array from [CH, CH+CL).

On exit:

CF	 =	 0 if all went well
	 =	 1 if window # out of range

AX	 =	 byte size of array if CF=0

|

	 REGSAVE <ebx>		; Save register

; Ensure the starting window # plus the count is <= NPHYS16S

	 mov	 al,[ebp].INTXX_ECX.ELO.HI ; Get starting window #

	 mov	 ebx,PSEG2PHYS	; DS:EBX ==> translate table
	 xlat	 PSEG2PHYS.LO[ebx] ; Translate window # to physical 16KB page #
	 mov	 ah,al		; Copy to test range

	 call	 ERPN_CNT	; Get count of array into AL
	 jc	 short ERPN_SIZE_EXIT ; It's too big (note CF=1)

	 add	 ah,al		; Add to get next available physical page #

	 cmp	 NPHYS16S,ah	; Check against # physical 16KB pages in EMS system
	 jc	 short ERPN_SIZE_EXIT ; Jump if out of range (note CF=1)

	 mov	 ah,size RPN_STR ; Get size of each RPN entry
	 mul	 ah		; AX = byte size of windows [CH, CH+CL)
ERPN_SIZE_EXIT:
	 REGREST <ebx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing

ERPN_SIZE endp			; End ERPN_SIZE procedure
	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment
endif				; IF @OEM_EEMS

	 MEND			; End QMAX_EEM module
