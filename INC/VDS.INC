;' $Header:   P:/PVCS/MAX/INC/VDS.INV   1.0   05 Sep 1995 13:26:44   HENRY  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	All rights reserved.
;
; VDS.INC
;
; Structures and equates for Virtual DMA Services
;

; Structures for Virtual DMA Services

DDS_STR  struc			; DMA Descriptor Structure

DDS_SIZE dd	 ?		; 00-03:  Region size
DDS_FVEC df	 ?		; 04-09:  Linear segment/selector:offset
DDS_BID  dw	 ?		; 0A-0B:  Buffer ID
DDS_POFF dd	 ?		; 0C-0F:  Physical address

DDS_STR  ends


XDDS_STR struc

XDDS_SIZE dd	 ?		; 00-03:  Region size
XDDS_FVEC df	 ?		; 04-09:  Linear segment/selector:offset
	  dw	 ?		; 0A-0B:  (reserved)
XDDS_AVL  dw	 ?		; 0C-0D:  # entries available
XDDS_USED dw	 ?		; 0E-0F:  # entries used (or would be used)
XDDS_DATA dd	 ?		; 10-??:  variable length data area

XDDS_STR ends


; The following structure maps XDDS_DATA when region address/size is used

RDDS_STR struc

RDDS_ADDR dd	 ?		; Region physical address
RDDS_SIZE dd	 ?		; ...	 size in bytes

RDDS_STR ends


; The following structure maps XDDS_DATA when Page Table Entries are used

PDDS_STR struc

PDDS_PTE  dd	 ?		; Page Table Entry

PDDS_STR ends


; The following structure maps XDDS_DATA when previous VDS table is used

VDDS_STR struc

VDDS_ADDR dd	 ?		; Region physical address
VDDS_EPTA dd	 ?		; Ending physical translation address

VDDS_STR ends


; Equates for DMA service functions

.xcref @VDS_MAJOR,  @VDS_VERS,	 @VDS_LOCK,   @VDS_UNLK,   @VDS_SLOCK
.xcref @VDS_SUNLK,  @VDS_GETBUF, @VDS_RELBUF, @VDS_MEM2BUF
.xcref @VDS_BUF2MEM,@VDS_DISTRAN,@VDS_ENATRAN
@VDS_MAJOR   equ 81h		; Major function code

@VDS_VERS    equ 02h		; Get version #
@VDS_LOCK    equ 03h		; Lock DMA region
@VDS_UNLK    equ 04h		; Unlock DMA region
@VDS_SLOCK   equ 05h		; Scatter/gather lock DMA region
@VDS_SUNLK   equ 06h		; Scatter/gather unlock DMA region
@VDS_GETBUF  equ 07h		; Request DMA buffer
@VDS_RELBUF  equ 08h		; Release DMA buffer
@VDS_MEM2BUF equ 09h		; Memory to DMA buffer
@VDS_BUF2MEM equ 0Ah		; DMA buffer to memory
@VDS_DISTRAN equ 0Bh		; Disable DMA translation
@VDS_ENATRAN equ 0Ch		; Enable DMA translation

; Equates for flags in DX

@VDSF_COPY   equ 0002h		; Automatically copy to/from buffer
@VDSF_XBUF   equ 0004h		; Disable automatic buffer allocation
@VDSF_XMAP   equ 0008h		; Disable automatic remap feature
@VDSF_X64    equ 0010h		; Region must not cross 64KB physical boundary
@VDSF_X128   equ 0020h		; Region must not cross 128KB physical boundary
@VDSF_PTE    equ 0040h		; Copy page table entries for scatter/gather
@VDSF_PLOCK  equ 0080h		; Lock present PTEs only
@VDSF_BPHYS  equ 0100h		; Return BUS physical address


; Equates for DMASERV byte in BIOS data area

.xcref @VDS_ENA,@VDS_CHAIN
@VDS_ENA     equ 00100000b	; Virtual DMA services enabled
@VDS_CHAIN   equ 00001000b	; Virtual DMA services chain


; Virtual DMA Service Error Codes

.xcref @VDSERR_XCONT, @VDSERR_BOUND, @VDSERR_BUFOVF,@VDSERR_INUSE
.xcref @VDSERR_PTEOVF,@VDSERR_INVBID,@VDSERR_CPYOVF,@VDSERR_INVDCN
.xcref @VDSERR_CNTOVF,@VDSERR_CNTUND,@VDSERR_INVMIN,@VDSERR_INVFLG
.xcref @VDSERR_INVSEL,@VDSERR_UALOCK,@VDSERR_NPLOCK
@VDSERR_XCONT	 equ 01h	; Region not in contiguous memory
@VDSERR_BOUND	 equ 02h	; Region crosses a DMA boundary
@VDSERR_UALOCK	 equ 03h	; Unable to lock pages
;;;;		     04h	; No buffer available
@VDSERR_BUFOVF	 equ 05h	; Region too large for DMA buffer
@VDSERR_INUSE	 equ 06h	; Buffer currently in use
;;;;		     07h	; Invalid memory region
@VDSERR_NPLOCK	 equ 08h	; Memory was not previously locked
@VDSERR_PTEOVF	 equ 09h	; Too many physical pages
@VDSERR_INVBID	 equ 0Ah	; Invalid buffer ID
@VDSERR_CPYOVF	 equ 0Bh	; Copy count+offset > buffer
@VDSERR_INVDCN	 equ 0Ch	; Invalid DMA channel #
@VDSERR_CNTOVF	 equ 0Dh	; Disable count overflow
@VDSERR_CNTUND	 equ 0Eh	; Disable count underflow
@VDSERR_INVMIN	 equ 0Fh	; Invalid minor function
@VDSERR_INVFLG	 equ 10h	; Invalid flag bits
@VDSERR_INVSEL	 equ 11h	; Invalid selector in DDS


; Macro for Virtual DMA Service calls

.xcref VDSCALL
VDSCALL  macro	 NN

ifnb <NN>
	 mov	 ax,(@VDS_MAJOR shl 8) or (NN) ; Set major/minor function code
else
	 mov	 ah,@VDS_MAJOR	;; Set major DMA Services function code
endif				; IFNB <NN>
	 int	 4Bh		;; Request DMA Service

	 endm			; DMACALL

