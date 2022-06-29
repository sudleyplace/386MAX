;' $Header:   P:/PVCS/MAX/INC/EMMCALL.INV   1.0   05 Sep 1995 13:26:52   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; EMMCALL.INC
;
; EMMCALL macro and equates
;

.xcref @EMM_BLDINDX, @EMM_CLRBUFF, @EMM_PRTBUFF
.xcref @EMM_GETSTAT, @EMM_GETPGFR, @EMM_GETPGCT,   @EMM_SETPAGE
.xcref @EMM_MAPHNPG, @EMM_RLSPAGE, @EMM_GETVERS,   @EMM_SAVEMAP
.xcref @EMM_RESTMAP, @EMM_GETPMR,  @EMM_GETL2P,    @EMM_GETHNCT
.xcref @EMM_GETHNPG, @EMM_GETALPG, @EMM_PAGEMAP,   @EMM_GETSETPART
.xcref @EMM_MULPGMAP,@EMM_REALLOC, @EMM_GETSETATTR,@EMM_GETSETNAME
.xcref @EMM_GETHDIR, @EMM_PGMAPJMP,@EMM_PGMAPCALL, @EMM_XMOVEMEM
.xcref @EMM_GETPHYS, @EMM_GETXINFO,@EMM_RAWALLOC,  @EMM_ALTMAPREG
.xcref @EMM_BOOT,    @EMM_OSE,	   @EMM_TEST

; Expanded Memory Manager INT 67h Function Calls
;				  Fn =
@EMM_BLDINDX	equ 3Dh 	;      Build JLASER index
@EMM_CLRBUFF	equ 3Eh 	;      Clear image in buffer
@EMM_PRTBUFF	equ 3Fh 	;      Print image in buffer
@EMM_GETSTAT	equ 40h 	;  1 = Get status
@EMM_GETPGFR	equ 41h 	;  2 = Get page frame address
@EMM_GETPGCT	equ 42h 	;  3 = Get unallocated page count
@EMM_SETPAGE	equ 43h 	;  4 = Allocate pages
@EMM_MAPHNPG	equ 44h 	;  5 = Map handle page
@EMM_RLSPAGE	equ 45h 	;  6 = Unallocate pages
@EMM_GETVERS	equ 46h 	;  7 = Get EMM version #
@EMM_SAVEMAP	equ 47h 	;  8 = Save page map
@EMM_RESTMAP	equ 48h 	;  9 = Restore page map
@EMM_GETPMR	equ 49h 	; 10 = Get PMR array
@EMM_GETL2P	equ 4Ah 	; 11 = Get log to phys page xlat array
@EMM_GETHNCT	equ 4Bh 	; 12 = Get EMM handle count
@EMM_GETHNPG	equ 4Ch 	; 13 = Get EMM handle pages
@EMM_GETALPG	equ 4Dh 	; 14 = Get all EMM handle pages
@EMM_PAGEMAP	equ 4Eh 	; 15 = Get/Set page mapping registers
@EMM_GETSETPART equ 4Fh 	; 16 = Get/set partial PMRs
@EMM_MULPGMAP	equ 50h 	; 17 = Map/unmap multiple HPs
@EMM_REALLOC	equ 51h 	; 18 = Reallocate pages
@EMM_GETSETATTR equ 52h 	; 19 = Get/set handle attr
@EMM_GETSETNAME equ 53h 	; 20 = Get/set handle name
@EMM_GETHDIR	equ 54h 	; 21 = Get handle directory
@EMM_PGMAPJMP	equ 55h 	; 22 = Alter page map & jump
@EMM_PGMAPCALL	equ 56h 	; 23 = Alter page map & call
@EMM_XMOVEMEM	equ 57h 	; 24 = Exchange/move memory
@EMM_GETPHYS	equ 58h 	; 25 = Get mappable physical
@EMM_GETXINFO	equ 59h 	; 26 = Get hardware info
@EMM_RAWALLOC	equ 5Ah 	; 27 = Allocate raw pages
@EMM_ALTMAPREG	equ 5Bh 	; 28 = Alternate map registers
@EMM_BOOT	equ 5Ch 	; 29 = Prepare for warm boot
@EMM_OSE	equ 5Dh 	; 30 = Enable/disable OS/E fns
;;;;;;;;;	equ 5Eh 	; 31 = Reserved
@EMM_TEST	equ 5Fh 	; 32 = EMM test functions


.xcref EMMCALL
EMMCALL  macro	 FUNC
ifnb	<FUNC>
if FUNC gt 255
	 mov	 ax,FUNC
else
	 mov	 ah,FUNC
endif				; IF FUNC gt 255
endif				; IFNB <FUNC>
	 int	 67h

	 endm			; EMMCALL

