;' $Header:   P:/PVCS/MAX/386MAX/UTIL_USE.ASV   1.2   30 May 1997 10:46:44   BOB  $
	 title	 UTIL_USE -- 386LOAD/MOVE'EM TSR FLEXFRAME Code
	 page	 58,122
	 name	 UTIL_USE

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Program segment DATZ,	para-aligned,  public, class 'data'
	       Program segment ACODE,	byte-aligned,  public, class 'zdata'
	       Data    segment ADATA,	dword-aligned, public, class 'zdata'

Link requirements:  Final routine should have extension .SYS.
		    Link with VERSION.OBJ.

Program derived from:  None.

Original code by:  Bob Smith, March 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include EMMCALL.INC
	 include MAC.INC
	 include OPEN.INC
	 include IOCTL.INC

	 include UTIL_USE.INC
	 include COMM_OEM.INC
.list

if @OEM_FLEX
PGROUP	 group	 DATA,DATZ,ACODE,ADATA


DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 POVR_MAC:word

DATA	 ends			; End DATA segment


DATZ	 segment para public 'data' ; Start DATZ segment
	 assume  ds:PGROUP

	 extrn	 EMMDEV:tbyte

DATZ	 ends			; End DATZ segment


ADATA	 segment dword public 'zdata' ; Start ADATA segment
	 assume  ds:PGROUP

	 extrn	 NEXTAVL:word

	 public  MAPTAB,NMAPS
MAPTAB	 MAP_STR @NMAPS dup (<?,?>) ; EMS mapping table structure
NMAPS	 dw	 ?		; # active maps

	 public  PAAOFF,PAACNT,TOTEMS
PAAOFF	 dw	 ?		; Offset of PAS_STR structure
PAACNT	 dw	 ?		; # entries in ...
TOTEMS	 dw	 ?		; Total EMS size in paras

ADATA	 ends			; End ADATA segment


ACODE	 segment byte public 'zdata' ; Start ACODE segment
	 assume  cs:PGROUP

	 FPPROC  IZITEMS -- Is an EMS Handler Installed
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Is an EMS handler installed?
This routine is a FAR procedure so it can be
called from MAXSUB.ASM.  We make sure in MAXSUB.ASM
that DS=PGROUP is a valid assumption.

On exit:

CF	 =	 1 if EMS handler installed and ready
	 =	 0 if not

|

	 REGSAVE <ax,bx,dx>	; Save registers

; Check for active EMS handler

	 mov	 al,@OPEN_R	; Subfunction code for read-only
	 DOSCALL @OPENF2,EMMDEV ; Attempt to open EMS device
	 jc	 short IZIT_EMS_XPRES ; Jump if error

	 mov	 bx,ax		; Copy to handle register

; Ensure that it's a device

	 mov	 al,00h 	; Subfunction to read device info
	 DOSCALL @IOCTL2	; Return with DL = I/O control info

	 test	 dl,@IOCTL_DEV	; Izit a device?
	 jz	 short IZIT_EMS_CLOSE ; Jump if not

; Finally, ensure that it's not busy

	 mov	 al,07h 	; Subfunction to read device status
	 DOSCALL @IOCTL2	; Return with DL = I/O control info

	 cmp	 al,0FFh	; Izit ready?
	 jne	 short IZIT_EMS_CLOSE ; Jump if not

	 DOSCALL @CLOSF2	; Close it up

	 stc			; Mark as installed and ready

	 jmp	 short IZIT_EMS_EXIT ; Join common exit code

IZIT_EMS_CLOSE:
	 DOSCALL @CLOSF2	; Close it up
IZIT_EMS_XPRES:
	 clc			; Mark as not present
IZIT_EMS_EXIT:
	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

IZITEMS  endp			; End IZITEMS procedure
	 NPPROC  SET_MAPTAB -- Setup MAPTAB Table
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Setup MAPTAB table.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

	 FCALL	 IZITEMS	; Is an EMS handler installed and ready?
	MJ nc	 SET_MAPTAB_ERR ; Jump if not

	 push	 ds		; Get data segment
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Find all available pages above conventional memory

	 mov	 di,NEXTAVL	; ES:DI ==> next available byte
	 mov	 PAAOFF,di	; Save for later use
	 mov	 al,0		; Function code to return the array
	 EMMCALL @EMM_GETPHYS	; Return with ES:DI filled in and CX = # entries

	 cmp	 ah,0		; Check for error
	MJ ne	 SET_MAPTAB_ERR ; Jump if so

	 mov	 PAACNT,cx	; Save for later use
	 mov	 NMAPS,0	; Initialize # active maps

; Trundle through the entries

	 int	 12h		; Get top of conventional memory
	 mov	 cl,10-4	; Shift amount between paras and 1KB
	 shl	 ax,cl		; Convert from 1KB to paras

	 xor	 bx,bx		; Zero index into MAPTAB
	 mov	 si,PAAOFF	; DS:SI ==> PAA_STR structure
	 mov	 cx,PAACNT	; CX = # entries

	 jcxz	 SET_MAPTAB_ENDLOOP ; Bug out if no pages

SET_MAPTAB_NEXT:
	 cmp	 ax,ds:[si].PAA_SEG ; Check against the segment
	 ja	 short SET_MAPTAB_DEL ; Jump if not above conventional memory

; See if we should merge it with the previous entry

	 and	 bx,bx		; Any previous entry?
	 jz	 short SET_MAPTAB_NEW ; Jump if not

	 mov	 dx,MAPTAB.MAP_SEG[bx-(type MAP_STR)] ; Get previous starting segment
	 add	 dx,MAPTAB.MAP_LEN[bx-(type MAP_STR)] ; Plus its length

	 cmp	 dx,ds:[si].PAA_SEG ; Izit contiguous with the preceding entry?
	 jne	 short SET_MAPTAB_NEW ; Jump if not

; Merge with previous entry

	 add	 MAPTAB.MAP_LEN[bx-(type MAP_STR)],16*1024/16 ; Add in another 16KB in paras

	 jmp	 short SET_MAPTAB_LOOP ; Join common loop code

; Establish a new entry if it's contiguous with some high DOS

SET_MAPTAB_NEW:

; Ensure it's contiguous with a free MAC entry in high DOS

	 mov	 dx,POVR_MAC	; Get segment of 1st MAC entry in high DOS
SET_MAPTAB_NEXTMAC:
	 mov	 es,dx		; Address the next MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 inc	 dx		; Skip over MAC entry
	 add	 dx,es:[0].MAC_NPAR ; Get # paras in this MAC entry
	 mov	 di,dx		; Copy to working register in case middle entry

; Ensure this is a valid MAC entry

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 je	 short @F	; Jump if so

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 jne	 short SET_MAPTAB_ERRMAC ; Jump if not

	 inc	 di		; Skip over spanning MAC entry
@@:
	 cmp	 di,ds:[si].PAA_SEG ; Izit the same segment?
	 je	 short SET_MAPTAB_NEW1 ; Jump if so

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 jne	 short SET_MAPTAB_NEXTMAC ; Jump if not

; Delete the segment from the PAA table

SET_MAPTAB_DEL:
	 mov	 ds:[si].PAA_SEG,-1 ; Delete it

	 jmp	 short SET_MAPTAB_LOOP ; Join common loop code

SET_MAPTAB_NEW1:
	 mov	 dx,ds:[si].PAA_SEG ; Get the segment #
	 mov	 MAPTAB.MAP_SEG[bx],dx	; Save for later use
	 mov	 MAPTAB.MAP_LEN[bx],16*1024/16 ; Mark its length as 16KB in paras
	 inc	 NMAPS		; Count in another entry

	 add	 bx,type MAP_STR ; Skip to next entry
SET_MAPTAB_LOOP:
	 add	 si,size PAA_STR ; Skip to next entry

	 loop	 SET_MAPTAB_NEXT ; Jump if more entries

; Count how many pages to map as well as
; set ending segment # and convert both segment #s
; to point to preceding MAC entry

SET_MAPTAB_ENDLOOP:
	 xor	 si,si		; Initialize index into MAPTAB
	 mov	 cx,NMAPS	; CX = # entries
	 xor	 bx,bx		; Zero # paras
	 jcxz	 SET_MAPTAB_CLC ; Jump if none
SET_MAPTAB_NEXTMAP:
	 mov	 ax,MAPTAB.MAP_SEG[si] ; Get starting segment #
	 dec	 ax		; Back off to preceding MAC entry
	 mov	 MAPTAB.MAP_SEG[si],ax ; Save back

	 mov	 dx,MAPTAB.MAP_LEN[si] ; Get length in paras
	 add	 ax,dx		; Add to get ending segment #
	 mov	 MAPTAB.MAP_END[si],ax ; Save back

	 add	 bx,dx		; Count in more paras
	 add	 si,type MAP_STR ; Skip to next entry

	 loop	 SET_MAPTAB_NEXTMAP ; Jump if more entries to count
SET_MAPTAB_CLC:
	 mov	 TOTEMS,bx	; Save for later use

	 clc			; Indicate all went well

	 jmp	 short SET_MAPTAB_EXIT ; Join common exit code

SET_MAPTAB_ERRMAC:
SET_MAPTAB_ERR:
	 stc			; Indicate something went wrong
SET_MAPTAB_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SET_MAPTAB endp 		; End SET_MAPTAB procedure

ACODE	 ends			; End ACODE segment
endif				; IF @OEM_FLEX

	 MEND			; End UTIL_USE module
