; $Header:   P:/PVCS/MAX/ASQENG/BUSINFO.ASV   1.2   30 May 1997 14:58:38   BOB  $
	 title	 BUSINFO -- Bus architecture and slot info
	 page	 58,122
	 name	 BUSINFO

COMMENT|		Module Specifications

Copyright:  Copyright (C) 1996-7 Qualitas, Inc.  All rights reserved.

Segmentation:  Microsoft conventions using .MODEL, .DATA, and .CODE.

Link requirements:  None.

Program derived from:  None.

Original code by:  Henry Groover, January 1996.


|

	.MODEL LARGE,PASCAL

.xlist
	 include MASM.INC
	 include PTR.INC
	 include CPUID.INC
	 include PCI.INC
	 include PNP.INC
.list

DGROUP	group	_DATA
PnPGRP	group	PnPSEG

PnPSEG	segment at 0
	assume	ds:PnPGRP

	public	PnPSTR
PnPSTR	PnP_STR <>		; Dummy struc

	assume	ds:nothing
PnPSEG	ends

.data

	 public  MOVPCI
MOVPCI	 db	 66h,0BAh,'PCI ' ; MOV EDX,' ICP'
MOVPCI_LEN equ	 $-MOVPCI	; Length of ...

	 public  AMIBIOS
AMIBIOS  db	 'AMIBIOS(C)AMI' ; Identifying string
AMIBIOS_LEN equ  $-AMIBIOS	; Length of ...

AMIDATE_STR struc		; Date struc which follows the above string

AMIDATE_MM dw	 ?		; Month
AMIDATE_SEP1 db  '/'            ; Separator
AMIDATE_DD dw	 ?		; Day
AMIDATE_SEP2 db  '/'            ; Separator
AMIDATE_CCYY dd  ?		; Century-Year (e.g. '1994')

AMIDATE_STR ends

	public	PnP_SEG
PnP_SEG dw	?		; Segment of PnP struc

	public	PnP_NodeSize,PnP_NumNodes,PnP_Node,PnP_CTL
	public	PnP_PRODID,PnP_PRODNO,PnP_Message
	public	PnP_MinESCDSize,PnP_ESCDSize,PnP_NVStorageBase
	public	PnP_APMSize
PnP_NodeSize dw ?		; PnP size of largest device node
PnP_NumNodes db ?,?		; PnP # nodes the BIOS returns
PnP_Node     dw ?		; PnP node # for Get/Set System Device Nodes
PnP_CTL      dw ?		; PnP control flags
PnP_PRODID   dd ?		; Product ID
PnP_PRODNO   dd ?		; ...	  #
PnP_Message  dw ?		; Event message
PnP_MinESCDSize dw ?		; Minimum buffer byte size for writing to NVS
PnP_ESCDSize dw ?		; Size allocated for the ESCD within NV storage block
PnP_NVStorageBase dd ?		;
PnP_APMSize  dw ?		; APM buffer size

	public	OffPnP_RMVEC,OffPnP_PMCS,OffPnP_PMOFF
OffPnP_RMVEC dd PnP_RMVEC	; Offset to PnP_RMVEC in PnP_STR or PnP2_STR
OffPnP_PMCS  dd PnP_PMCS	; ...	    PnP_PMCS  ...
OffPnP_PMOFF dd PnP_PMOFF	; ...	    PnP_PMOFF ...

.code

	 extrn	 _SRCHSTR:near

	 PPROC	 IS_EISA -- Determine if system is EISA
	 assume  ds:DGROUP,es:nothing,ss:nothing

COMMENT|

Determine if system is EISA.

Ripped off from CHECK_MODEL in QMAX_SYS.ASM.

On exit:

AX	 =	 1 if BIOS reports system is EISA
	 =	 0 if not

|

	 REGSAVE <es>		; Save

	 mov	 ax,seg CPUID_SEG ; Get ROM BIOS segment
	 mov	 es,ax		; Address via segment register
	 assume  es:CPUID_SEG ; Tell the assembler about it

; Check for EISA signature at F000:FFD9

; Some early EISA machines don't follow the spec, they put their
; signature somewhere else in the BIOS.  However, We can't search
; through the entire BIOS, because many ISA machines have EISA
; strings that we would pick up as false positives.

	 sub	 ax,ax		; Clear return value

	 cmp	 word ptr EISASIGN[0],'IE' ; Check for first part of EISA signature
	 jne	 short IS_EISA_EXIT ; Jump if not EISA machine

	 cmp	 word ptr EISASIGN[2],'AS' ; Check for part two...
	 jne	 short IS_EISA_EXIT ; Jump if not EISA machine

	 inc	 ax		; Indicate success

IS_EISA_EXIT:
	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

IS_EISA  endp			; End IS_EISA procedure

	 NPPROC  CHECK_AMI -- Check On Certain AMI BIOSes
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Check on certain AMI BIOSes which have a bug which prevents us
from calling PCICALL.

On exit:

CF	 =	 0 if found
	 =	 1 if not
DI	 =	 offset in ROM of string match

|

; Search for the AMIBIOS string in F000:0

	 mov	 di,seg CPUID_SEG ; Segment of BIOS
	 push	 di		; Pass it as search segment
	 sub	 di,di		; Starting offset
	 push	 di		; Pass as search offset
	 mov	 di,1000h	; Length of search area (4KB)
	 push	 di		; Pass as search length
	 lea	 di,AMIBIOS	; Get offset of source string
	 push	 di		; Pass as offset within DGROUP
	 mov	 di,AMIBIOS_LEN ; Get length of source string
	 push	 di		; Pass as length
	 call	 _SRCHSTR	; Search for the string
				; Return with DI = offset of match in ROM
				; Return with CF=0 if found, CF=1 if not
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_AMI endp			; End CHECK_AMI procedure

	 PPROC	 IS_PCI -- Determine if system is PCI
	 assume  ds:DGROUP,es:nothing,ss:nothing

COMMENT|

Determine if system is PCI.

Taken from CHECK_MODEL in QMAX_SYS.ASM.

We must check for a certain buggy AMI BIOS, as the call that normally
tells us whether PCI BIOS functions are available changes the BIOS
to read/write.	It's not a happy ending.

On exit:

AX	 =	 1 if BIOS reports system is PCI
	 =	 0 if not
	 =	-1 if PCI but unsafe to call functions

|

	 REGSAVE <di,es>	; Save

	 call	 CHECK_AMI	; See if this is an AMI BIOS with the bug which
				; prevents us from making the PCICALL below
				; Return with DI = offset of match in ROM
	 jc	 short IS_PCI_XAMI ; Jump if not AMI BIOS

	 mov	 ax,seg CPUID_SEG ; Get ROM BIOS segment
	 mov	 es,ax		; Address via segment register
	 assume  es:CPUID_SEG ; Tell the assembler about it

	 add	 di,AMIBIOS_LEN ; Skip over the string

; This bug should be fixed in the BIOS with a code base date of 04/15/1994.
; Note that the code base date is from the original BIOS vendor (AMI)
; which has been modified by Intel.  Apparently, Intel doesn't get the
; code from AMI in a timely manner or they're slow to integrate it into
; their own versions.

	 cmp	 es:[di].AMIDATE_SEP1,'/' ; Izit valid?
	 jne	 short IS_PCI_XAMI ; Jump if not

	 cmp	 es:[di].AMIDATE_SEP2,'/' ; Izit valid?
	 jne	 short IS_PCI_XAMI ; Jump if not

	 cmp	 es:[di].AMIDATE_CCYY.ELO,'91' ; Izit later than 1999?
	 ja	 short IS_PCI_XAMI ; Jump if later (assume fixed)

	 cmp	 es:[di].AMIDATE_CCYY.EHI,'49' ; Izit later than 1994?
	 ja	 short IS_PCI_XAMI ; Jump if later (assume fixed)
	 jb	 short IS_PCI_AMI ; Jump if earlier (assume buggy)
				       ; Fall through if same
	 cmp	 es:[di].AMIDATE_MM,'40' ; Izit later than 04?
	 ja	 short IS_PCI_XAMI ; Jump if later (assume fixed)
	 jb	 short IS_PCI_AMI ; Jump if earlier (assume buggy)
				       ; Fall through if same
	 cmp	 es:[di].AMIDATE_DD,'51' ; Izit later than 15?
	 jae	 short IS_PCI_XAMI ; Jump if same or later (assume fixed)
;;;;;;;; jb	 short IS_PCI_AMI ; Jump if earlier (assume buggy)

	 assume  es:nothing	; Tell the assembler about it

; Search for the MOVPCI string in F000:0 to FFFF

IS_PCI_AMI:
	 mov	 di,seg CPUID_SEG ; Get BIOS segment
	 push	 di		; Pass as search segment
	 sub	 di,di		; Starting offset
	 push	 di		; Pass as start offset for search
	 push	 di		; Length of search area (64KB)
	 lea	 di,MOVPCI	; Get offset of source string
	 push	 di		; Pass as offset within DGROUP
	 mov	 di,MOVPCI_LEN	; Get length of source string
	 push	 di		; Pass as string length
	 call	 _SRCHSTR	; Search for the string
	 jc	 short IS_PCI_XAMI ; Jump if not found (safe to call BIOS)

	 mov	 ax,-1		; Mark as PCI but unsafe to do anything with
	 jmp	 short IS_PCI_EXIT ; Join common exit

IS_PCI_XAMI:
	 stc			; Assume failure
	 PCICALL @PCI_INST	; Return CF=0 and AH=0 if PCI BIOS present
	 jnc	 short @F	; Jump if call may have succeeded

	 sub	 ax,ax		; PCI - not
	 jmp	 short IS_PCI_EXIT ; Join common exit code

@@:
; AH = 0 if PCI BIOS supported but not a PCI system.
	 or	 ah,ah		; ZF=1 if PCI
	 mov	 ax,0		; Assume not PCI
	 jnz	 short IS_PCI_EXIT ; Jump if not PCI

	 mov	 ax,bx		; Return BCD version

IS_PCI_EXIT:
	 REGREST <es,di>	; Restore

	 ret			; Return to caller

IS_PCI	 endp			; End IS_PCI procedure

	NPPROC	IZIT_PnP -- Determine Plug 'n Play Availability
	assume	ds:DGROUP,es:nothing,ss:DGROUP
COMMENT|

Determine Plug 'n Play availability

If this is a PnP BIOS, somewhere in the BIOS on a para boundary
is the PnP structure with a matching checksum.

Return CF=1 if not PnP.

|

	REGSAVE <ax,cx,si,ds>	; Save registers

	mov	cx,0F000h	; Segment of start of ROM (paras)
	mov	ds,cx		; Address it
	assume	ds:nothing	; Tell the assembler about it

	neg	cx		; Get length of BIOS in paras
	xor	si,si		; Initialize index into BIOS
@@:
	cmp	ds:[si].ELO,'P$' ; Duzit have the right signature?
	jne	short IZIT_PnP_SKIP ; Jump if not

	cmp	ds:[si].EHI,'Pn' ; Does it have the other half?
	je	short IZIT_PnP_SUM ; Jump if so
IZIT_PnP_SKIP:
	add	si,16		; Skip to next para

	loop	@B		; Jump if more paras to check

	stc			; Mark as not present

	jmp	short IZIT_PnP_EXIT ; Join common exit code

IZIT_PnP_SUM:

; Validate the checksum

	REGSAVE <cx,si> 	; Save for a moment

	sub	cx,cx		; Clear high byte
	mov	cl,ds:[si].PnP_LEN ; Get the structure's byte length
	mov	ah,0		; Initialize the checksum accumulator
@@:
	lods	ds:[si].LO	; Get the next byte
	add	ah,al		; Add into accumulator
	loop	@B		; Jump if more bytes to checksum

	REGREST <si,cx> 	; Restore

	cmp	ah,0		; Duzit match?
	jne	short IZIT_PnP_SKIP ; Jump if not

; Ensure it's a version 1.0 struc

	cmp	ds:[si].PnP_VER,10h ; Izit version 1.0?
	jne	short IZIT_PnP_SKIP ; Jump if not

; Ensure it's one of the two type strucs we support

	cmp	ds:[si].PnP_LEN,size PnP_STR ; Izit new struc?
	je	short @F	; Jump if so

	cmp	ds:[si].PnP_LEN,size PnP2_STR ; Izit old struc?
	jne	short IZIT_PnP_SKIP ; Jump if not

	mov	OffPnP_RMVEC.ELO,PnP2_RMVEC ; Save as offset
	mov	OffPnP_PMCS.ELO, PnP2_PMCS	; ...
	mov	OffPnP_PMOFF.ELO,PnP2_PMOFF ; ...
@@:
	mov	ax,ds		; Copy the segment
	mov	cl,4-0		; Bytes to paras
	shr	si,cl		; Convert from bytes to paras
	add	ax,si		; Add to get the segment

	mov	PnP_SEG,ax	; Save for later use

	clc			; Mark as present
IZIT_PnP_EXIT:
	REGREST <ds,si,cx,ax>	; Restore
	assume	ds:DGROUP	; Tell the assembler about it

	ret			; Return to caller

	assume	ds:nothing,es:nothing,ss:nothing

IZIT_PnP endp			; End IZIT_PnP procedure

	 PPROC	 IS_PNP -- Determine if system is Plug and Play
	 assume  ds:DGROUP,es:nothing,ss:nothing

COMMENT|

Determine if system has Plug and Play BIOS support.

On exit:

AX	 =	 1 if Plug and Play supported
	 =	 0 if not

|

	 call	 IZIT_PnP	; CF=1 if not
	 cmc			; CF=1 if PnP
	 sbb	 ax,ax		; AX=-1 if PnP
	 neg	 ax		; AX=1 if PnP

	 ret			; Return to caller

IS_PNP	 endp			; End IS_PNP procedure

PNP_VM	 PROC	 pwDS:dword ; Return Plug and Play BIOS entry for VM
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

/*-asm-*/ DWORD pascal far pnp_vm( WORD far *pwDS );

On exit:

DX:AX =  Far entry point (if successful)
DX:AX =  0 if unsuccessful

|

	 REGSAVE <si,es>	; Save

	 sub	 ax,ax		; Zero return value
	 cwd			; ...and extend to DX:AX

	 call	 IZIT_PnP	; Set PNP_SEG
	 jc	 short PNP_VM_EXIT ; Jump if not present

	 mov	 es,PNP_SEG	; Get PNP segment
	 assume  es:PnPSeg	; Tell the assembler

	 mov	 si,OffPnP_RMVEC.ELO ; Get offset to PnP_RMVEC
	 mov	 ax,PnPSEG:[si].VOFF ; Get the RM entry point
	 mov	 dx,PnPSEG:[si].VSEG ; Get RM segment

	 mov	 bx,PnPSEG:[0].PnP_RMDS ; Get the RM data segment

	 cmp	 PnPSEG:[0].PnP_LEN,size PnP_STR ; Izit new struc?
	 je	 short @F	; Jump if so

	 sub	 bx,bx		; No RMDS in old struc

@@:
	 les	 si,pwDS	; Address return data segment
	 assume  es:nothing	; Tell the assembler

	 mov	 es:[si].ELO,bx ; Save return value

PNP_VM_EXIT:
	 REGREST <es,si>	; Restore
	 assume  es:nothing	; Tell the assembler

	 ret	 4		; Return to caller, popping argument

PNP_VM	 endp			; End PNP_VM procedure

	 PPROC	 PNP_BIOS_STR -- Return address of BIOS structure
	 assume  ds:DGROUP,es:nothing,ss:nothing

COMMENT|

Returns pointer to structure containing additional info.

/*-asm-*/ LPPNPBIOS_STR pascal far pnp_bios_str( void );

On exit:

DX:AX	 =	 Structure address if PNP
	 =	 0:0 if not

|

	 sub	 ax,ax		; Zero default return
	 cwd			; Extend to DX

	 call	 IZIT_PnP	; Set PNP_SEG
	 jc	 short @F	; Jump if not PNP

	 mov	 dx,PNP_SEG	; DX:0 (DX:AX) = start of structure
@@:
	 ret			; Return to caller

PNP_BIOS_STR endp		; End PNP_BIOS_STR procedure

	 end
