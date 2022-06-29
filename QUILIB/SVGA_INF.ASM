;' $Header:   P:/PVCS/MAX/QUILIB/SVGA_INF.ASV   1.2   30 May 1997 12:09:06   BOB  $
	 title	 SVGA_INF -- Subroutines to get Super VGA information
	 page	 58,122
	 name	 SVGA_INF

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  byte-aligned, public, class 'data'

Link requirements:  None, standalone subroutine.

Original code by:  Henry Groover, April 1991

|

%.model  &MODEL,c

.8086
.xlist
	 include MASM.INC
	 include PTR.INC
	 include DOSCALL.INC
	 include VIDCALL.INC
	 include INTVEC.INC
	 include BIOSDATA.INC
.list

	 include SVGA_INF.INC
	 include VESA.INC

DVIDCALL macro FUNC
	 push	ds		; Save DGROUP addressability
	 VIDCALL FUNC
;;;;;	 assume ds:nothing	; Could be trashed
	 pop	ds		; Restore
;;;;;	 assume ds:DGROUP	; Tell the assembler
	 endm			; DVIDCALL

.data

; Table of vendor info structures
	 align	 2
	 public  ID_TAB
ID_TAB	 VINFO_STR	 <UNK_ID,MID_TAB,FUN_TAB,MID_MLEN,FUN_FLEN>
	 VINFO_STR	 <ATI_ID,ATI_MID_TAB,ATI_FUN_TAB,ATI_MLEN,ATI_FLEN>
	 VINFO_STR	 <TRIDENT_ID,TRIDENT_MID_TAB,TRIDENT_FUN_TAB,TRIDENT_MLEN,TRIDENT_FLEN>
	 VINFO_STR	 <VIDEO7_ID,VIDEO7_MID_TAB,VIDEO7_FUN_TAB,VIDEO7_MLEN,VIDEO7_FLEN>
	 VINFO_STR	 <PARADISE_ID,PARADISE_MID_TAB,PARADISE_FUN_TAB,PARADISE_MLEN,PARADISE_FLEN>
	 VINFO_STR	 <TSENG_ID,TSENG_MID_TAB,TSENG_FUN_TAB,TSENG_MLEN,TSENG_FLEN>
	 VINFO_STR	 <CHIPS_ID,CHIPS_MID_TAB,CHIPS_FUN_TAB,CHIPS_MLEN,CHIPS_FLEN>
	 VINFO_STR	 <GENOA_ID,GENOA_MID_TAB,GENOA_FUN_TAB,GENOA_MLEN,GENOA_FLEN>
	 VINFO_STR	 <VESA_ID,VESA_MID_TAB,S3_FUN_TAB,VESA_MLEN,S3_FLEN>
	 VINFO_STR	 <AHEAD_ID,AHEAD_MID_TAB,AHEAD_FUN_TAB,AHEAD_MLEN,AHEAD_FLEN>
	 VINFO_STR	 <ORCHID_ID,ORCHID_MID_TAB,ORCHID_FUN_TAB,ORCHID_MLEN,ORCHID_FLEN>
	 VINFO_STR	 <CIRRUS_ID,MID_TAB,FUN_TAB,MID_MLEN,FUN_FLEN>
	 VINFO_STR	 <S3_ID,S3_MID_TAB,S3_FUN_TAB,S3_MLEN,S3_FLEN>
	 VINFO_STR	 <DIAMOND_ID,DIAMOND_MID_TAB,FUN_TAB,DIAMOND_MLEN,FUN_FLEN>
	 VINFO_STR	 <STB_ID,STB_MID_TAB,S3_FUN_TAB,STB_MLEN,S3_FLEN>

	 public MODEL_JMP
MODEL_JMP label  word		; Jump table for model identification
	 dw	SVGA_MODEL_UNK	; Vendor unknown
	 dw	SVGA_MODEL_ATI
	 dw	SVGA_MODEL_TRIDENT
	 dw	SVGA_MODEL_VIDEO7
	 dw	SVGA_MODEL_PARADISE
	 dw	SVGA_MODEL_TSENG
	 dw	SVGA_MODEL_CHIPS
	 dw	SVGA_MODEL_GENOA
	 dw	SVGA_MODEL_TSENG	; Return OEM StringPtr
	 dw	SVGA_MODEL_AHEAD
	 dw	SVGA_MODEL_UNK
	 dw	SVGA_MODEL_UNK
	 dw	SVGA_MODEL_TSENG ; Model set during detection
	 dw	SVGA_MODEL_TSENG
	 dw	SVGA_MODEL_TSENG ; STB - model returned by BIOS

@VGASAVEMAX	 EQU	 2048		; Maximum bytes for save data area
@SCRNSAVEMAX	 EQU	 (80*50)	; Maximum words to save from screen

VGASAVE_STR	 struc
VGASAVE_STATE	 db	 @VGASAVEMAX dup (?)	; Save state data
VGASAVE_SCRN	 dw	 @SCRNSAVEMAX dup (?)	; Screen save area
VGASAVE_STR	 ends

	 public  VGASAVEP,VGASAVED,VGAROWS,VGACURSHAPE,VGACURPOS,NORESTORE
	 public  PREVMODE,PREVPAGE,VESA_MODECNT
VGASAVEP	 dw	 -1		; Ptr to save area
VGASAVED	 db	 ?		; Set to 1 if VGASAVE is valid
VGAROWS 	 db	 ?		; Number of rows on screen
VGACURSHAPE	 dw	 ?		; Start & end of cursor
VGACURPOS	 dw	 ?		; X and Y coordinates of cursor
NORESTORE	 db	 0		; If 1, let caller save/restore
PREVMODE	 db	 ?		; Text mode on entry
PREVPAGE	 db	 ?		; Page on entry
VESA_MODECNT	 dw	 ?		; Number of VESA modes supported

	 public  UNK_ID 		; 0
UNK_ID		 db	 '*Unknown*', 0

	 public  ATI_ID,ATI_SIG 	; 1
ATI_ID		 db	 'ATI', 0
ATI_SIG 	 db	 '761295520'
@ATI_SIGLEN	 equ	 $-ATI_SIG

ATIBIO_STR struc
	 db	 10h dup (?)		; 00: Signature, length, unknown
ATIBIO_EXTREG dw ?			; 10: I/O address for extended registers
	 db	 1Fh dup (?)		; 12: Unknown
ATIBIO_SIG db	 @ATI_SIGLEN dup (?)	; 31: Should match ATI_SIG
	 db	 6 dup (?)		; 3A: Unknown
ATIBIO_EVSIG dw  ?			; 40: "31" for VGAWONDER, "32" for EGA
ATIBIO_FLAGS db  ?			; 42:	Bit 0=8/16 bit ROM switch
					;	Bit 1=Mouse interface
					;	Bit 4=Use clock chip (?)
					;	Bit 7=Use C000-DFFF w/16 bit ROM
ATIBIO_REV db	 ?			; 43: '1' for 18800, '2' for 28800,
					;	'3' for 28800 with VRAM
	 db	 8 dup (?)		; 44: Unknown
ATIBIO_BMAJ db	 ?			; 4C: Major BIOS rev #
ATIBIO_BMIN db	 ?			; 4D: Minor BIOS rev #

ATIBIO_STR ends

	 public  TRIDENT_ID,TRIDENT_SIG ; 2
TRIDENT_ID	 db	 'Trident', 0
TRIDENT_SIG	 db	 'TRIDENT MICROSYSTEMS'
TRIDENT_SIGLEN	 equ	 $-TRIDENT_SIG

	 public  VIDEO7_ID		; 3
VIDEO7_ID	 db	 'Video 7', 0

	 public  PARADISE_ID,PARADISE_SIG ; 4
PARADISE_ID	 db	 'Paradise/WD', 0
PARADISE_SIG	 db	 'VGA='
PARADISE_SIGLEN  equ	 $-PARADISE_SIG

	 public  TSENG_ID		; 5
TSENG_ID	 db	 'Tseng Labs', 0

	 public  CHIPS_ID		; 6
CHIPS_ID	 db	 'Chips & Technologies', 0

	 public  GENOA_ID,GENOA_SIG,GENOA_MODBYTE ; 7
GENOA_ID	 db	 'Genoa', 0
GENOA_SIG	 db	 77h
GENOA_MODBYTE	 db	 ?, 99h, 66h

	 public  VESA_ID		; 8
VESA_ID 	 db	 'VESA', 0
VESA_SIGLEN	 equ	 ($-VESA_ID)-1	; Less trailing null

	 public  AHEAD_ID,AHEAD_SIG	; 9
AHEAD_ID	 db	 'Ahead',0
AHEAD_SIG	 db	 'AHEAD'
AHEAD_SIGLEN	 equ	 $-AHEAD_SIG

	 public  ORCHID_ID		; 10
ORCHID_ID	 db	 'Orchid Technology'
ORCHID_SIGLEN	 equ	 $-ORCHID_ID
		 db	 0

	 public  CIRRUS_ID		; 11
CIRRUS_ID	 db	 'Cirrus',0

	 public  S3_ID			; 12
S3_ID		 db	 'S3, Inc.', 0

	 public  DIAMOND_ID,DIAMOND_SIG
DIAMOND_ID	 db	 'Diamond',0
DIAMOND_SIG	 db	 'SpeedSTAR'
DIAMOND_SIG_LEN  equ	 $-DIAMOND_SIG
DIAMOND_SIG_OFF  equ	 0A71h		; Offset within BIOS for above signature
		 db	 0

	 public  STB_ID,STB_ETID,STB_S3ID
STB_ID		 db	 'STB',0        ; OEMString ID for STB cards
STB_SIGLEN	 equ	 ($-STB_ID)-1
STB_ETID	 db	 ' TLI4:'       ; OEMString ID for ERGOPowergraph
STB_ETIDLEN	 equ	 $-STB_ETID
STB_S3ID	 db	 ' S3:'         ; OEMString ID for S3 based Windows card
STB_S3IDLEN	 equ	 $-STB_S3ID

	 align	 2
	 public  MID_TAB,ATI_MID_TAB,TRIDENT_MID_TAB,VIDEO7_MID_TAB
MID_TAB 	 label	 word
MID_MLEN	 equ	 0
ATI_MID_TAB	 dw	 ATI_18800_ID
		 dw	 ATI_28800_ID
ATI_MLEN	 equ	 (($-ATI_MID_TAB) shr 1)
TRIDENT_MID_TAB  dw	 TRIDENT_8800_ID
		 dw	 TRIDENT_8900_ID
TRIDENT_MLEN	 equ	 (($-TRIDENT_MID_TAB) shr 1)
VIDEO7_MID_TAB	 dw	 VIDEO7_VEGA_ID
		 dw	 VIDEO7_FASTWRITE_ID
		 dw	 VIDEO7_V7VGAV5_ID
		 dw	 VIDEO7_1024i_ID
VIDEO7_MLEN	 equ	 (($-VIDEO7_MID_TAB) shr 1)

	 public  PARADISE_MID_TAB,TSENG_MID_TAB,CHIPS_MID_TAB,GENOA_MID_TAB
PARADISE_MID_TAB dw	 PARADISE_PVGA1a_ID
		 dw	 PARADISE_WD90C00_ID
		 dw	 PARADISE_WD90C10_ID
		 dw	 PARADISE_WD90C11_ID
PARADISE_MLEN	 equ	 (($-PARADISE_MID_TAB) shr 1)
TSENG_MID_TAB	 dw	 TSENG_ET3000_ID
		 dw	 TSENG_ET4000_ID
TSENG_MLEN	 equ	 (($-TSENG_MID_TAB) shr 1)
CHIPS_MID_TAB	 dw	 CHIPS_82C451_ID
		 dw	 CHIPS_82C452_ID
		 dw	 CHIPS_82C453_ID
		 dw	 CHIPS_82C455_ID
		 dw	 CHIPS_82C456_ID
CHIPS_MLEN	 equ	 (($-CHIPS_MID_TAB) shr 1)
GENOA_MID_TAB	 dw	 GENOA_5000_ID
		 dw	 GENOA_GVGA_ID
GENOA_MLEN	 equ	 (($-GENOA_MID_TAB) shr 1)

	 public  VESA_MID_TAB,AHEAD_MID_TAB,ORCHID_MID_TAB,S3_MID_TAB
VESA_MID_TAB	 label	 word
VESA_MLEN	 equ	 (($-VESA_MID_TAB) shr 1)
AHEAD_MID_TAB	 dw	 AHEAD_A_ID
		 dw	 AHEAD_B_ID
AHEAD_MLEN	 equ	 (($-AHEAD_MID_TAB) shr 1)
ORCHID_MID_TAB	 label	 word
ORCHID_MLEN	 equ	 (($-ORCHID_MID_TAB) shr 1)
S3_MID_TAB	 dw	 S3_86C911_ID
S3_MLEN 	 equ	 (($-S3_MID_TAB) shr 1)

	 public  DIAMOND_MID_TAB,STB_MID_TAB
DIAMOND_MID_TAB  dw	 DIAMOND_SIG
DIAMOND_MLEN	 equ	 (($-DIAMOND_MID_TAB) shr 1)
STB_MID_TAB	 label	 word
STB_MLEN	 equ	 (($-STB_MID_TAB) shr 1)

	 public  ATI_18800_ID,ATI_28800_ID,ATI_EXT
ATI_18800_ID	 db	 '18800', 0
ATI_28800_ID	 db	 '28800', 0
ATI_EXT 	 dw	 ?

	 public  TRIDENT_8800_ID,TRIDENT_8900_ID
TRIDENT_8800_ID  db	 '8800', 0
TRIDENT_8900_ID  db	 '8900', 0

	 public  VIDEO7_VEGA_ID,VIDEO7_FASTWRITE_ID,VIDEO7_V7VGAV5_ID
	 public  VIDEO7_1024i_ID
VIDEO7_VEGA_ID	 db	 'VEGA VGA', 0
VIDEO7_FASTWRITE_ID db	 'V7VGA Fastwrite', 0
VIDEO7_V7VGAV5_ID db	 'V7VGA Ver 5', 0
VIDEO7_1024i_ID  db	 '1024i', 0

	 public  PARADISE_PVGA1a_ID,PARADISE_WD90C00_ID,PARADISE_WD90C10_ID
	 public  PARADISE_WD90C11_ID
PARADISE_PVGA1a_ID db	 'PVGA 1a', 0
PARADISE_WD90C00_ID db	 'WD 90C00', 0
PARADISE_WD90C10_ID db	 'WD 90C10', 0
PARADISE_WD90C11_ID db	 'WD 90C11', 0

	 public  TSENG_ET3000_ID,TSENG_ET4000_ID
TSENG_ET3000_ID  db	 'ET 3000', 0
TSENG_ET4000_ID  db	 'ET 4000', 0

	 public  CHIPS_82C451_ID,CHIPS_82C452_ID,CHIPS_82C453_ID
	 public  CHIPS_82C455_ID,CHIPS_82C456_ID
CHIPS_82C451_ID  db	 '82C451 rev. '
CHIPS_82c451_rev db	 '0', 0
CHIPS_82C452_ID  db	 '82C452 rev. '
CHIPS_82c452_rev db	 '0', 0
CHIPS_82C453_ID  db	 '82C453 rev. '
CHIPS_82c453_rev db	 '0', 0
CHIPS_82C455_ID  db	 '82C455 rev. '
CHIPS_82c455_rev db	 '0', 0
CHIPS_82C456_ID  db	 '82C456 rev. '
CHIPS_82c456_rev db	 '0', 0

	 public  GENOA_5000_ID,GENOA_GVGA_ID
GENOA_5000_ID	 db	 '5000', 0
GENOA_GVGA_ID	 db	 'GVGA', 0

	 public  AHEAD_A_ID,AHEAD_B_ID
AHEAD_A_ID	 db	 'rev. A', 0
AHEAD_B_ID	 db	 'rev. B', 0

	 public  S3_86C911_ID
S3_86C911_ID	 db	 '86C911', 0

	 align	 2
	 public  FUN_TAB,ATI_FUN_TAB,TRIDENT_FUN_TAB,VIDEO7_FUN_TAB
FUN_TAB 		 label	 word
FUN_FLEN		 equ	 0
ATI_FUN_TAB		 dw	 S3_MEMSIZE
ATI_FLEN		 equ	 (($-ATI_FUN_TAB) shr 1) ; # entries
TRIDENT_FUN_TAB 	 dw	 TRIDENT_MEMSIZE
TRIDENT_FLEN		 equ	 (($-TRIDENT_FUN_TAB) shr 1)
VIDEO7_FUN_TAB		 dw	 VIDEO7_MEMSIZE
VIDEO7_FLEN		 equ	 (($-VIDEO7_FUN_TAB) shr 1)

	public	 PARADISE_FUN_TAB,TSENG_FUN_TAB,CHIPS_FUN_TAB,GENOA_FUN_TAB
PARADISE_FUN_TAB	 dw	 PARADISE_MEMSIZE
PARADISE_FLEN		 equ	 (($-PARADISE_FUN_TAB) shr 1)
TSENG_FUN_TAB		 dw	 TSENG_MEMSIZE
TSENG_FLEN		 equ	 (($-TSENG_FUN_TAB) shr 1)
CHIPS_FUN_TAB		 dw	 CHIPS_MEMSIZE
CHIPS_FLEN		 equ	 (($-CHIPS_FUN_TAB) shr 1)
GENOA_FUN_TAB		 dw	 GENOA_MEMSIZE
GENOA_FLEN		 equ	 ($-GENOA_FUN_TAB) shr 1

	public	 AHEAD_FUN_TAB,ORCHID_FUN_TAB,S3_FUN_TAB
AHEAD_FUN_TAB		 dw	 AHEAD_MEMSIZE
AHEAD_FLEN		 equ	 ($-AHEAD_FUN_TAB) shr 1
ORCHID_FUN_TAB		 label	 word
ORCHID_FLEN		 equ	 ($-ORCHID_FUN_TAB) shr 1
S3_FUN_TAB		 dw	 S3_MEMSIZE
S3_FLEN 		 equ	 ($-S3_FUN_TAB) shr 1

	 public  SVENDOR,VMODEL,SMODEL,SMEMORY,VESA_OEMP,VESA_MODES
SVENDOR  dw	 VENDOR_UNDEF	; Vendor is undefined until we call SVGA_*
VMODEL	 dw	 MODEL_UNDEF	; Vendor model also undefined
SMODEL	 dw	 ?		; Model if recognized during chipset detection
SMEMORY  dw	 ?		; Memory if recognized during chipset detection
VESA_OEMP dd	 ?		; Far ptr to VESA OEM string
VESA_MODES dd	 ?		; Far ptr to -1 terminated list of supported
				; modes (words)

	 .code

;-------------- Register constants -------------------------
@CHIPS_GIDREG	 equ	 0104h
@MDA_BASE	 equ	 03B4h
@MDA_STAT	 equ	 03B8h
@MODE_CTL	 equ	 03BFh		; Used for Tseng recognition
@TSENG_MISC	 equ	 03C0h
@TRIDENT_MCREG	 equ	 03C4h
@V7_EREG	 equ	 03C4h
@MISC_OUT	 equ	 03CCh
@AHEAD_AER	 equ	 03CEh
@PARADISE_EXT	 equ	 03CEh
@CGA_BASE	 equ	 03D4h
@CGA_STAT	 equ	 03D8h
@TSENG_ATTR	 equ	 03dah
@CHIPS_SETUPREG  equ	 46e8h

;-------------- Externally called functions ------------------

	 PPROC	 SVGA_ISVGA -- Return AX != 0 if VGA
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Determine if display is VGA/EGA, and return AX=0 if not, AX!=0 if it is.

Input:	None.
Output: AX=0	Not a VGA or EGA
	AX!=0	Is a VGA or EGA according to BIOS

|

	 REGSAVE <bx,cx,dx,si,di,bp> ; Save caller's registers

	 clc			; Clear CF
	 sub	 al,al		; AL=0: Read display combination code
	 DVIDCALL @GSTDCC	; Get/set display combination code
	 assume  ds:nothing	; It might be trashed

	 jc	 short ISVGA_ERR ; If CF=1, we fail

	 cmp	 al,@GSTDCC	; Izit supported?
	 jne	 short ISVGA_ERR ; No, so it can't be a VGA or EGA

	 mov	 ax,1		; AX!=0 indicates it's (supposedly) a VGA or EGA
	 jmp	 short ISVGA_EXIT ; Join common exit code

ISVGA_ERR:
	 sub	 ax,ax		; AX=0 indicates not VGA or EGA

ISVGA_EXIT:
	 REGREST <bp,di,si,dx,cx,bx> ; Restore caller's registers
	 assume  ds:nothing	; Tell the assembler

	 ret			; Return to caller
	 assume  ds:nothing,es:nothing,ss:nothing

SVGA_ISVGA	endp

	 PPROC	 SVGA_ACTIVEROM -- Return active ROM in AX or 0
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Determine active ROM segment and return in AX, or 0 if no valid
(seg & 0x07ff == 0) ROM segment found.

Input:	None.
Output: AX=0	No valid ROM segment found.
	AX	active ROM segment

|

	 REGSAVE <es>	; Save caller's register

	 mov	 ax, seg INTVEC ; Get a seg value for IDT
	 mov	 es, ax 	; Use es for IDT
	 assume  es:INTVEC	; Tell the assembler about it
	 mov	 ax, INT00_VEC.VSEG[1Fh*(type INT00_VEC)] ; Get segment
	 test	 ax, 07ffh	; Izit on a 32K boundary?
	 jz	 short ACTIVEROM_EXIT ; Yes, so this is our boy

	 mov	 ax, INT00_VEC.VSEG[43h*(type INT00_VEC)] ; Get int 43 segment
	 test	 ax, 07ffh	; Izit on a 32K boundary
	 jz	 short ACTIVEROM_EXIT ; This is OK

	 sub	 ax,ax		; AX=0 indicates no valid active ROM found

ACTIVEROM_EXIT:
	 REGREST <es>		; Restore caller's register

	 ret			; Return to caller
	 assume  ds:nothing,es:nothing,ss:nothing

SVGA_ACTIVEROM	endp

	 PPROC	 SVGA_VENDOR -- Return vendor code in AX
	 assume  ds:DGROUP, es:nothing, ss:nothing
COMMENT |

Determine vendor code, store it locally, and return it in AX.

Input:	 None.
Output:  AX = Vendor code (defined in SVGA_INF.H)

|

	 REGSAVE <BX,CX,DX,SI,DI,BP,ES>

	 call	 SAVE_SVGA	; Save video state

	 ; Make sure we have a VGA
	 call	 SVGA_ISVGA	; Returns AX=0 if not VGA
	 or	 ax,ax		; Izit a VGA?
	 jnz	 short @F	; Yes, continue

	 jmp	 SVGA_VENDOR_UNK ; Say we don't know this one

@@:
	 ; get active VGA ROM segment
	 call	 SVGA_ACTIVEROM ; AX = Active ROM segment
	 or	 ax,ax		; Izit valid?
	 jnz	 short GOT_ROMSEG ; Yes, continue

	 jmp	 SVGA_VENDOR_UNK ; Say we don't know

GOT_ROMSEG:
	 mov	 es, ax 	; address ROM segment
	 assume  es:nothing	; tell the assembler about it

;;;===================================================================
;;;
;;; VGA's identified by strings in active ROM
;;;
;;;===================================================================

	 ; Check for ATI; string ATI_SIG should be at ES:31h
	 lea	 di,es:[0].ATIBIO_SIG ; ES:DI ==> ATI_SIG in BIOS
	 lea	 si,ATI_SIG	; DGROUP:SI ==> ATI_SIG to search for
	 mov	 cx,@ATI_SIGLEN ; Bytes to compare
	 cld			; Set direction forward
   repe  cmps	 ATI_SIG[si],es:[0].ATIBIO_SIG[di] ; Compare 'em
	 jne	 SVGA_VENDOR_XATI ; Jump if mismatch

SVGA_VENDOR_ATI_S:
	 mov	 ax,es:[0].ATIBIO_EXTREG ; Get EXT register from ROM
	 mov	 ATI_EXT,ax	; Save for later
	 mov	 al,es:[0].ATIBIO_REV ; '1' for 18800, '2' or '3' for 28800
	 mov	 SMODEL,ATI_28800 ; Assume a later model
	 cmp	 al,'1'         ; Izit the revision 1?
	 jne	 short @F	; Jump if not

	 mov	 SMODEL,ATI_18800 ; Mark as chipset revision 1
@@:
	 jmp	 SVGA_VENDOR_ATI ; Join common code to return vendor ID

SVGA_VENDOR_XATI:
	 ; check for Genoa / Tseng
	 sub	 ax, ax 	; clear high order byte
	 mov	 al, es:[37h]	; get low byte pointer to Genoa ID
	 mov	 di, ax 	; es:di points to ID bytes in ROM
	 mov	 si, offset GENOA_SIG ; ds:si points to our Genoa signature
	 cld			; set direction up
	 cmpsb			; do we match so far?
	 jne	 @F		; if not, no dice

	 mov	 al, es:[di]	; get model identifier
	 inc	 si		; point to next byte
	 inc	 di		; next byte in target
	 lodsw			; get next two bytes to compare
	 cmp	 ax, es:[di]	; is it a normal match?
	 je	 SVGA_VENDOR_GENOA_S ; yes

	 xchg	 ah, al 	; try with bytes reversed
	 cmp	 ax, es:[di]	; is it a backwards match?
	 jne	 @F		; test failed

SVGA_VENDOR_GENOA_S:
	 jmp	 SVGA_VENDOR_GENOA ; identify as Genoa


@@:
	 ; check for Paradise / WD
	 mov	 di, 7dh	; pointer to Paradise signature in ROM
	 lea	 si, PARADISE_SIG ; pointer to our Paradise signature
	 mov	 cx, PARADISE_SIGLEN ; bytes to compare
	 cld			; set direction up
   repe  cmpsb			; compare
	 jne	 short @F	; If we failed, try the next one

	 jmp	 SVGA_VENDOR_PARADISE	; Identify as Paradise

@@:
	 ; Check for Ahead by checking signature at ROM:25h
	 mov	 di, 25h		; pointer to Ahead signature in ROM
	 lea	 si, AHEAD_SIG		; pointer to our Ahead signature
	 mov	 cx,AHEAD_SIGLEN	; bytes to compare
	 cld				; set direction up
   repe  cmpsb				; compare
	 jne	 short @F		; If we failed, try the next one

	 jmp	 SVGA_VENDOR_AHEAD	; Identify as Ahead

@@:
	 ; Check for Diamond SpeedStar by checking signature at ROM:A71h
	 mov	 di,DIAMOND_SIG_OFF	; Offset within ROM
	 lea	 si,DIAMOND_SIG 	; Our copy to compare
	 mov	 cx,DIAMOND_SIG_LEN	; Bytes to compare
	 cld				; Set forward direction
   repe  cmpsb				; Compare
	 jne	 short @F		; Jump if compare failed

	 mov	 SMODEL,DIAMOND_SS	; Identify as SpeedStar
	 jmp	 SVGA_VENDOR_DIAMOND	; Identify as Diamond

@@:
	 ; check for Trident by looking for string
	 push	 es			; BIOS segment
	 PUSHAX  0			; origin of search
	 PUSHAX  6000h			; check 24K
	 PUSHAX  <offset TRIDENT_SIG>	; string to search for
	 PUSHAX  TRIDENT_SIGLEN 	; length of string
	 call	 SRCHSTR		; go look for it
	 jc	 short @F		; didn't find it
	 jmp	 SVGA_VENDOR_TRIDENT	; identify as Trident

@@:
;;;==========================================================
;;;
;;; VGA's identified via ROM BIOS calls
;;;
;;;==========================================================

	 ; check for Video 7
	 xor	 bx,bx			; Assume not Video 7 or VEGA VGA
	 mov	 ax,6F00h		; V7 presence detection
	 DVIDCALL			; Video services

	 cmp	 bx,'V7'                ; Any of the products?
	 jnz	 short @F		; Nope, rejoin common code

; Check the chip version #

	 mov	 cx,0ffffh		; Assume not V7 VGA
	 mov	 ax,06f07h		; Get video memory configuration
	 DVIDCALL			; Video services

; Must be in the range 70h - 7Fh

	 xor	 dx,dx			; Assume no flags passed in
	 or	 cx,cx			; Zero if Video 7 board
	 jnz	 short @F		; Nope, rejoin common code

	 cmp	 bh,70h 		; V7VGA chip?
	 jb	 short @F		; Nope, rejoin common code
	 jmp	 SVGA_VENDOR_VIDEO7	; Identify as Video 7

@@:
	 push	 es			; Save ROM segment pointer

; Some VESA BIOSes return the VESA_Info_Modes data inside the
; @VESA_Getinfo data struc, so we need to use separate buffers
; for that and the @VESA_Getmodeinfo buffer.

@GETINFO_LEN equ 512			; Buffer length for @VESA_Getinfo
@GETMODEINFO_LEN equ 256		; ...		    @VESA_Getmodeinfo

	 sub	 sp,@GETINFO_LEN+@GETMODEINFO_LEN ; Reserve space

	 mov	 di,sp			; Get offset of ID string
	 push	 ss			; Get SS (should be == DGROUP anyway)
	 pop	 es			; ES:DI==> ID string space
	 assume  es:nothing		; Tell the assembler

	 mov	 ax,@VESA_Getinfo	; VESA function 4F
	 int	 10h			; Return AH=0, ID in ES:DI

	 or	 ah,ah			; Did the call succeed?
	 jz	 short @F		; Jump if so

	 mov	 ax,VENDOR_UNDEF	; Not identified; try next type
	 jmp	 STB_VESA_EXIT		; Join common exit
@@:
	 lea	 si,VESA_ID		; Address VESA signature
	 mov	 cx,VESA_SIGLEN 	; Number of bytes to compare
	 cld				; String ops forwardly
	 push	 di			; Save for a moment
  repe	 cmps	 DGROUP:[si].LO,es:[di].VESA_Info_Sig ; Compare strings
	 pop	 di			; Restore
	 je	 short @F		; Jump if it matches

	 mov	 ax,VENDOR_UNDEF	; Not identified; try next type
	 jmp	 STB_VESA_EXIT		; Join common exit

@@:
	 mov	 ax,VESA		; Identify as VESA
	 mov	 SMODEL,VESA_OEM	; Assume it's a generic VESA

	 REGSAVE <di,es>		; Save pointer to VESA_Info_str

	 les	 di,es:[di].VESA_Info_Modes ; Get supported modes list pointer
	 assume  es:nothing		; Tell the assembler

	 mov	 VESA_MODES.VOFF,di	; Save offset
	 mov	 VESA_MODES.VSEG,es	; Save segment

	 REGREST <es,di>		; Restore pointer to VESA_Info_str
	 assume  es:nothing		; Tell the assembler

	 les	 di,es:[di].VESA_Info_OEM ; Get pointer to OEM string
	 assume  es:nothing		; Tell the assembler

	 mov	 VESA_OEMP.VOFF,di	; Save offset
	 mov	 VESA_OEMP.VSEG,es	; Save segment

	 lea	 si,STB_ID		; Address STB signature
	 mov	 cx,STB_SIGLEN		; Number of bytes to compare
  repe	 cmps	 DGROUP:[si].LO,es:[di].LO ; Compare
	 jne	 short VESA_XSTB	; Jump if not STB

	 mov	 SMODEL,STB_ET4000	; Assume Tseng ET4000 model
	 mov	 SMEMORY,512		; ... which has 512K minimum
	 mov	 ax,di			; Save a copy of starting DI
	 lea	 si,STB_ETID		; Signature to compare
	 mov	 cx,STB_ETIDLEN 	; Bytes to compare
  repe	 cmps	 DGROUP:[si].LO,es:[di].LO ; Compare
	 je	 short SVGA_VENDOR_STB_EXIT ; It's a match- join exit code

	 mov	 SMODEL,STB_S3		; Assume S3 model (Windows accelerator)
	 mov	 SMEMORY,1024		; ... which has 1024K in ZIPs
	 mov	 di,ax			; Start over at beginning
	 lea	 si,STB_S3ID		; Signature to compare
	 mov	 cx,STB_S3IDLEN 	; Bytes to compare
  repe	 cmps	 DGROUP:[si].LO,es:[di].LO ; Compare
	 je	 short SVGA_VENDOR_STB_EXIT ; It's a match

	 mov	 SMODEL,-1		; Model unknown (ID string is in BIOS)
	 mov	 SMEMORY,512		; ... which probably has 512K

	 mov	 di,ax			; Display entire OEMString
SVGA_VENDOR_STB_EXIT:
	 mov	 VESA_OEMP.VOFF,di	; Move pointer past cryptic stuff
	 mov	 ax,STB 		; Identify as STB
	 jmp	 STB_VESA_EXIT		; Join common exit code

VESA_XSTB:
; It's a VESA board... we don't know who the vendor is, nor do we care.
; We'll walk through the list of supported video modes to find the
; maximum page size.  We'll also determine the memory by multiplying
; bytes_per_scan_line by y_resolution (if present) or by y-res values
; for the modes we know about.
	 mov	 di,sp			; Get offset of ID string
	 add	 di,@GETINFO_LEN	; Skip over ID string
	 push	 ss			; Get SS (should be == DGROUP anyway)
	 pop	 es			; ES:DI==> ID string space
	 assume  es:DGROUP		; Tell the assembler

	 mov	 SMEMORY,256		; Start with a safe assumption
	 mov	 SMODEL,VESA_OEM	; Assume it doesn't use 128K pages
	 mov	 VESA_MODECNT,0 	; Assume native mode only

	 REGSAVE <ds>			; Save

	 lds	 bx,VESA_MODES		; Address list of supported modes
	 assume  ds:nothing		; Tell the assembler

VESA_NEXTMODE:
	 mov	 cx,ds:[bx].ELO 	; Get mode number
	 cmp	 cx,-1			; Izit the end?
	 je	 short VESA_ENDMODES	; Jump if so

	 inc	 VESA_MODECNT		; Bump total

	 mov	 ax,@VESA_GetModeInfo	; Read mode CX info at ES:DI
	 push	 bx			; Do I trust the vendor?  Nooooo...
	 VIDCALL			; Return AH=0 if OK
	 pop	 bx			; Restore mode list pointer

	 or	 ah,ah			; Did we succeed?
	 jnz	 short VESA_MODELOOP	; Jump if not

	 mov	 ax,es:[di].VESA_Mode_Attr ; Get mode attributes
	 test	 ax,mask $VMASUP	; Is this mode supported by the
					; current adapter/display combination?
	 jz	 short VESA_MODELOOP	; Jump if not

	 cmp	 es:[di].VESA_Mode_Size,64 ; Does it use 128K+ pages?
	 jbe	 short @F		; Jump if not

	 mov	 SMODEL,VESA_128	; Mark as a dangerous customer
@@:
	 mov	 cx,es:[di].VESA_Mode_YRes ; Get (possibly) number of scan lines
	 test	 ax,mask $VMAOPT	; Is optional info present?
	 jnz	 short @F		; Jump if so (CX is valid)

; VESA modes we know about:
;	 100h	 640x400	x	256
;	 101h	 640x480	x	256
;	  6ah	 800x600	x	16
;	 102h	 800x600	x	16
;	 103h	 800x600	x	256
;	 104h	 1024x768	x	16
;	 105h	 1024x768	x	256
;	 106h	 1280x1024	x	16
;	 107h	 1280x1024	x	256
	 mov	 ax,ds:[bx].ELO 	; Get mode number
	 shr	 ax,1			; Knock off low order bit
	 mov	 cx,480 		; Safe minimal assumption
	 cmp	 ax,100h/2		; Izit 100h-101h?
	 je	 short @F		; Jump if so

	 mov	 cx,600 		; Up the ante
	 cmp	 ax,6ah/2		; Izit 6Ah?
	 je	 short @F		; Good guess

	 cmp	 ax,102h/2		; Izit 102h-103h?
	 je	 short @F		; Jump if so

	 mov	 cx,768 		; Try this
	 cmp	 ax,104h/2		; Izit 104h-105h?
	 je	 short @F		; Good guess

	 mov	 cx,1024		; Assume maximum
@@:
; CX is the number of scan lines.  Multiply by the bytes per line
; and divide by 1024 to get memory needed for this mode in K.
	 mov	 ax,es:[di].VESA_Mode_BPScan ; Get bytes per scan line
	 mul	 cx			; DX,AX = bytes for this mode
	 mov	 cx,1024		; Divisor to get size in K
	 div	 cx			; (DX,)AX = size in K
	 cmp	 ax,SMEMORY		; Izit the largest so far?
	 jbe	 short VESA_MODELOOP	; Jump if not

	 mov	 SMEMORY,ax		; New high water mark
VESA_MODELOOP:
	 add	 bx,2			; Skip to next mode
	 jmp	 short VESA_NEXTMODE	; Go around again

VESA_ENDMODES:
; We've got a value in K; round it up to a 64K boundary.
	 mov	 ax,SMEMORY		; Maximum bytes needed
	 add	 ax,64-1		; Round up
	 and	 ax,not (64-1)		; Knock off excess bits
	 mov	 SMEMORY,ax		; Save rounded value

	 REGREST <ds>			; Restore
	 assume  ds:DGROUP		; Tell the assembler

	 mov	 ax,VESA		; Assume VESA
STB_VESA_EXIT:
	 add	 sp,@GETINFO_LEN+@GETMODEINFO_LEN ; Restore stack
	 pop	 es			; Restore ROM segment
	 assume  es:nothing		; Tell the assembler

	 cmp	 ax,VENDOR_UNDEF	; Did we fail to identify the culprit?
	 je	 short NOT_VESA 	; Jump if so

	 jmp	 SVGA_VENDOR_EXIT	; Join common exit with vendor in AX

NOT_VESA:
;;;============================================================
;;;
;;; VGA's identified by diddling chipset
;;;
;;;============================================================

	 ; check for C&T
	 OUTP	 @CHIPS_SETUPREG, 1eh ; enter setup mode
	 INP	 @CHIPS_GIDREG	; read in from global ID register
	 push	 ax		; save value
	 OUTP	 @CHIPS_SETUPREG, 0eh ; exit setup mode
	 pop	 ax		; get global ID value in AL
	 cmp	 al, 0a5h	; is it A5?
	 jne	 short @F	; no, so keep checking
	 jmp	 SVGA_VENDOR_CHIPS ; yes

@@:
	 ; check for Trident
	 OUTP	 @TRIDENT_MCREG, 0eh ; index Mode control register 1
	 INNP			; read from MCR data
	 mov	 ah, al 	; save old value in AH
	 OUTP	 dx, 0		; write all bits 0
	 INP	 dx		; read value again
	 and	 al, 0fh	; get low nybble
	 mov	 bx, ax 	; save value returned
	 OUTP	 dx, ah 	; restore old value
	 cmp	 bl, 2		; is bit 1 only set?
	 jne	 short @F	; no, try next
	 jmp	 SVGA_VENDOR_TRIDENT ; yes

@@:
	 ; check for Tseng ET3000/ET4000
	 mov	 SMODEL,TSENG_ET3000 ; Assume 3000
	 INP	 @MISC_OUT	; is it emulating MDA?
	 mov	 cx, @CGA_STAT	; default = color
	 test	 al, 1		; izit color?
	 jnz	 @F		; yes
	 mov	 cx, @MDA_STAT	; use MDA registers
@@:
	 INP	 @MODE_CTL	; Get 3BF contents
	 mov	 ah,al		; Save in AL
	 OUTP	 dx,00h 	; Clear 3BF
	 INP	 cx		; Read from mode control port
	 cmp	 al,0ffh	; Impossible value for Tseng; may be Compaq
	MJ e	 SVGA_VENDOR_XTSENG ; Jump if so

	 push	 ax		; Save mode control value
	 test	 al,40h 	; Is bit 6 cleared?
	 jnz	 short @F	; Jump if not (not a Tseng 4000)

	 OUTP	 @MODE_CTL,02h	; Write to Tseng port
	 INP	 cx		; Read from mode control port
	 test	 al,40h 	; Is bit 6 set?
	 jz	 short @F	; Jump if not (not a Tseng 4000)

	 mov	 SMODEL,TSENG_ET4000 ; Set it

	 ; Unlock ET4000
	 OUTP	 @MODE_CTL,03h	; Magic cookie value
	 INP	 cx		; Get mode control register value
	 mov	 ah,al		; Save it

	 OUTP	 cx, 0a0h	; Unlock ET4000

@@:
	 INP	 cx		; Read from mode control register
	 INP	 @TSENG_MISC	; Read value from attribute index register
	 mov	 bh,al		; Save it
	 OUTP	 dx,16h+20h	; Write to Misc register (leave video on)
	 INNP			; read from attribute write port
	 mov	 bl,al		; Save register 16h value

	 cmp	 SMODEL,TSENG_ET4000 ; Izit a 4000?
	 je	 short @F	; Jump if so

	 dec	 dx		; Go back to index port
	 push	 ax		; Save AX for a moment
	 OUTP	 dx,16h+20h	; Address register 16h again
	 pop	 ax		; Restore AX
	 inc	 dx		; Address data port

@@:
	 xor	 al,10h 	; Toggle bit 4
	 OUTP	 dx,al		; Write changed value
	 INP	 cx		; Read from mode control register again
	 OUTP	 @TSENG_MISC,16h+20h ; Select register 16h again
	 INNP			; Get value
	 xor	 al,10h 	; Toggle bit 4
	 cmp	 al,bl		; Is it the same as was written?

	 pushf			; Save results of comparison

	 OUTP	 dx,bl		; Restore original register contents
	 INP	 cx		; Read from mode control register again

	 OUTP	 @TSENG_MISC,bh ; Restore original saved value

	 popf			; Restore results of comparison
	 pop	 ax		; Restore original mode control port value
	 pushf			; Save results of comparison

	 OUTP	 cx,al		; Restore mode control port
	 OUTP	 @MODE_CTL,ah	; Restore to normal value

	 popf			; Restore flags
	 jne	 short SVGA_VENDOR_XTSENG ; Try next one if failed

	 jmp	 SVGA_VENDOR_TSENG ; It's a Tseng

SVGA_VENDOR_XTSENG:
	 ; Check for S3 86C911 chipset
	 INP	 @MISC_OUT	; is it emulating MDA?
	 mov	 cx, @CGA_BASE	; default = color
	 test	 al, 1		; izit color?
	 jnz	 @F		; yes
	 mov	 cx, @MDA_BASE	; use MDA registers
@@:
	 OUTP	 cx,38h 	; Address S3 Register Lock 1
	 INNP			; Get contents of lock register
	 mov	 bl,al		; Save for later
	 OUTP	 dx,48h 	; Open, sesame!
	 OUTP	 cx,30h 	; Address Chip ID/Rev Register
	 INNP			; Read it
	 mov	 SMODEL,S3_86C911 ; Assume it's this one
	 cmp	 al,81h 	; Izit our boy?
	 jne	 short SVGA_VENDOR_XS3_UNLOCK ; Jump if not

	 OUTP	 cx,36h 	; Address Reset State Read 1
	 INNP			; Get low byte
	 test	 al,88h 	; These bits should be 0
	 jnz	 short SVGA_VENDOR_XS3_UNLOCK ; Jump if not

	 test	 al,10h 	; This bit must be 1
	 jz	 short SVGA_VENDOR_XS3_UNLOCK ; Jump if not

	 mov	 SMEMORY,1024	; Assume 1MB
	 test	 al,20h 	; If 1, 512K installed
	 jz	 short @F	; Jump if not

	 mov	 SMEMORY,512	; 512K installed
@@:
	 OUTP	 cx,38h 	; Address the lock register
	 OUTNP	 bl		; Restore original contents

	 jmp	 SVGA_VENDOR_S3 ; Mark as an S3 chipset

SVGA_VENDOR_XS3_UNLOCK:
	 OUTP	 cx,38h 	; Address what we thought was the lock register
	 OUTNP	 bl		; Restore original contents

SVGA_VENDOR_XS3:
	 ; Check for Orchid by scanning for signature string
	 push	 es			; BIOS segment
	 PUSHAX  6			; Origin of search
	 PUSHAX  24*1024		; Check 24K
	 PUSHAX  <offset ORCHID_ID>	; String to search for
	 PUSHAX  ORCHID_SIGLEN		; Length of string
	 call	 SRCHSTR		; Go fetch!
	 jc	 short @F		; Jump if not found

	 jmp	 SVGA_VENDOR_ORCHID	; Identify as Orchid

@@:

	 ; all options exhausted
	 jmp	 short SVGA_VENDOR_UNK

SVGA_VENDOR_ATI:
	 mov	 ax, ATI	; identify as ATI
	 jmp	 short SVGA_VENDOR_EXIT ; join common exit code

SVGA_VENDOR_GENOA:
	 mov	 ax, GENOA	; assume it's GVGA
;	 cmp	 GENOA_MODBYTE, 33h ; Is it Tseng ET3000/5100-5200?
;	 je	 SVGA_VENDOR_TSENG ; identify as Tseng
;	 cmp	 GENOA_MODBYTE, 55h ; Is it Tseng ET3000/5300-5400?
;	 je	 SVGA_VENDOR_TSENG ; identify as Tseng
	 jmp	 short SVGA_VENDOR_EXIT ; join common exit code

SVGA_VENDOR_TSENG:
	 mov	 ax, TSENG		; identify as Tseng
	 jmp	 short SVGA_VENDOR_EXIT ; join common exit code

SVGA_VENDOR_VIDEO7:
	 mov	 ax, VIDEO7		; identify as Video 7
	 jmp	 short SVGA_VENDOR_EXIT ; join common exit code

SVGA_VENDOR_PARADISE:
	 mov	 ax, PARADISE	; identify as Paradise
	 jmp	 short SVGA_VENDOR_EXIT

SVGA_VENDOR_CHIPS:
	 mov	 ax, CHIPS	; identify as C&T
	 jmp	 short SVGA_VENDOR_EXIT ; join common exit code

SVGA_VENDOR_TRIDENT:
	 mov	 ax, TRIDENT	; identify as TRIDENT
	 jmp	 short SVGA_VENDOR_EXIT ; join common exit code

SVGA_VENDOR_AHEAD:
	 mov	 ax,AHEAD	; Identify as AHEAD
	 jmp	 short SVGA_VENDOR_EXIT ; Join common exit code

SVGA_VENDOR_ORCHID:
	 mov	 ax,ORCHID	; Identify as ORCHID
	 jmp	 short SVGA_VENDOR_EXIT ; Join common exit code

SVGA_VENDOR_S3:
	 mov	 ax,S3_INC	; Identify as S3 chipset
	 jmp	 short SVGA_VENDOR_EXIT ; Join common exit code

SVGA_VENDOR_DIAMOND:
	 mov	 ax,DIAMOND	; Identify as Diamond
	 jmp	 short SVGA_VENDOR_EXIT ; Join common exit code

SVGA_VENDOR_UNK:
	 mov	 ax, VENDOR_UNK ; vendor code to return in AX

SVGA_VENDOR_EXIT:
	 cmp	 ax, SVENDOR	; did we change?
	 je	 @F		; no, so do nothing

	 mov	 VMODEL, MODEL_UNDEF ; make model undefined
	 mov	 SVENDOR, ax	; save for later use
@@:
;;;;;	 call	 REST_SVGA	; Restore all video state data

	 REGREST <ES,BP,DI,SI,DX,CX,BX> ; restore caller's registers
	 assume  es:nothing

	 ret			; return

	 assume  ds:nothing, es:nothing, ss:nothing

SVGA_VENDOR	endp

	 PPROC	 SVGA_VENDORID -- Return vendor ID * DX:AX
	 assume  ds:DGROUP, es:nothing, ss:nothing

COMMENT |

Return a character * to a static identification string for the
vendor specified in AX.  If AX=VENDOR_UNDEF, call SVGA_VENDOR
first to determine the vendor code.

Input:	 Vendor code or VENDOR_UNDEF on stack
Output:  DX:AX ==> ASCIIZ string identifying vendor or '*Unknown*'

|

	 push	 bp		; save bp
	 mov	 bp, sp 	; get stack pointer
	 mov	 ax, [bp].arg1w ; get argument

	 REGSAVE <BX,CX>	; Save caller's registers

	 cmp	 ax,VENDOR_UNDEF ; Izit defined yet?
	 jne	 short @F	; Jump if so

	 mov	 ax,SVENDOR	; Get saved vendor code
	 cmp	 ax,VENDOR_UNDEF ; Was vendor already defined?
	 jne	 short @F	; Jump if so

	 call	 SVGA_VENDOR	; get vendor code in AX

@@:
	 ; Vendor code is 0-based, since VENDOR_UNK is valid.
	 mov	 cl, VINFO_SHL	; Number of bits to shift
	 shl	 ax, cl 	; index into VINFO_STR array
	 add	 ax, offset ID_TAB ; add to base of array
	 mov	 bx, ax 	; use BX to get struct address
	 mov	 ax, [bx].VINFO_ID	; get char * to return

	 mov	 dx, ds 	; make it a far char *
	 REGREST <CX,BX>	; restore caller's registers

	 pop	 bp		; restore caller's BP

	 ret			; return

	 assume  ds:nothing, es:nothing, ss:nothing

SVGA_VENDORID	 endp

	 NPPROC  ATI_CHECKMODE -- Check ATI mode in AL
	 assume  ds:DGROUP, es:nothing, ss:nothing
COMMENT|

Use the ATI Int 10h function 12h to determine if a particular
mode is supported.

On entry:
AL	 Mode to check for

On exit:
ZR	 Not supported
NZ	 Supported

|

	 REGSAVE <bx,si,bp,es>	; Save

	 mov	 ah, 12h	; ATI extended BIOS call: is mode available?
	 mov	 bx, 5506h	; Get info for mode
	 mov	 bp, 0ffffh	; Set to an illegal return value
	 DVIDCALL		; Call VGA BIOS, saving DS
	 cmp	 bp, 0ffffh	; Set NZ if supported, otherwise ZR

	 REGREST <es,bp,si,bx>	; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing, es:nothing, ss:nothing

ATI_CHECKMODE endp		; End ATI_CHECKMODE procedure

	 PPROC	 SVGA_MODEL -- Return model code in AX
	 assume  ds:DGROUP, es:nothing, ss:nothing

COMMENT |

Determine the chipset/card model code and return it in AX.
If the vendor code has not been determined yet, do that first.

Input:	 None.
Output:  AX = model code as defined in SVGA_INF.H

|

	 REGSAVE <BX,CX,DX,SI,DI,BP,ES> ; Save caller's registers

;;;;;	 call	 SAVE_SVGA	; Save video state
;;;;;	 mov	 NORESTORE,1	; Disable save/restore

	 mov	 ax, SVENDOR	; get vendor code
	 cmp	 ax, VENDOR_UNDEF ; is it defined yet?
	 jne	 @F		; already defined, so check type

	 call	 SVGA_VENDOR	; return vendor code in AX

@@:
	 shl	 ax,1-0 	; Convert to word pointer for jmp table
	 mov	 bx,ax		; Put in base register
	 jmp	 MODEL_JMP[bx]	; Branch to appropriate vendor-specific code

SVGA_MODEL_UNK:
	 mov	 ax, MODEL_UNK	; All other options exhausted
	 jmp	 SVGA_MODEL_EXIT ; join common exit code

SVGA_MODEL_ATI:
; We've already gotten the model.
; Check all 512K modes to see if any are supported.
	 mov	 SMEMORY,256	; Assume 256K
	 mov	 al,55h 	; 1024x768x16
	 call	 ATI_CHECKMODE	; Izit supported?
	 jnz	 short SVGA_MODEL_ATI512 ; Jump if so

	 mov	 al,62h 	; 640x480x256
	 call	 ATI_CHECKMODE	; Izit supported?
	 jnz	 short SVGA_MODEL_ATI512 ; Jump if so

	 mov	 al,63h 	; 800x600x256
	 call	 ATI_CHECKMODE	; Izit supported?
	 jnz	 short SVGA_MODEL_ATI512 ; Jump if so

	 mov	 al,65h 	; 1024x768x16
	 call	 ATI_CHECKMODE	; Izit supported?
	 jz	 short @F	; Jump if not

SVGA_MODEL_ATI512:
	 mov	 SMEMORY,512	; At least 512K present
	 mov	 al,64h 	; 1024x768x256
	 call	 ATI_CHECKMODE	; Izit supported?
	 jz	 short @F	; Jump if not

	 mov	 SMEMORY,1024	; At least 1MB present
@@:
	 mov	 ax,SMODEL	; Model was set during recognition
	 jmp	 SVGA_MODEL_EXIT ; join common exit code

SVGA_MODEL_TRIDENT:
	 OUTP	 @TRIDENT_MCREG,0Bh ; version register
	 OUTNP	 0		; write out
	 INP	 dx		; read back
	 mov	 bx, TRIDENT_8800 ; default
	 cmp	 al, 3		; if >= 3, 8900
	 jb	 short @F	; 8800

	 mov	 bx, TRIDENT_8900 ; it's an 8900
@@:
	 mov	 ax, bx 	; put identifier in AX
	 jmp	 SVGA_MODEL_EXIT ; join common exit code

SVGA_MODEL_VIDEO7:
	 OUTP	 @V7_EREG,6	; address extensions enable register
	 OUTNP	 0eah		; enable extensions
	 OUTP	 @V7_EREG,08eh	; address version register
	 INNP			; get version in AL
	 cmp	 al, 80h	; if >= 80h, VEGA VGA
	 jb	 short @F	; no

	 mov	 ax, VIDEO7_VEGA ; identify as VEGA VGA
	 jmp	 SVGA_MODEL_EXIT ; join common exit code

@@:
	 cmp	 al, 70h	; if >= 70h, Fastwrite/VRAM
	 jb	 short @F	; nope

	 mov	 ax, VIDEO7_FASTWRITE ; identify as Fastwrite/VRAM
	 jmp	 SVGA_MODEL_EXIT ; join common exit code

@@:
	 cmp	 al, 5fh	; if > 5f, invalid
	 jna	 short @F	; OK

VIDEO7_MODEL_INVAL:
	 jmp	 SVGA_MODEL_UNK ; join code for unknown model

@@:
	 cmp	 al, 50h	; if >= 50, V7VGA v5
	 jb	 short @F	; nope

	 mov	 ax, VIDEO7_V7VGAv5 ; mark as v5
	 jmp	 SVGA_MODEL_EXIT ; join common exit code

@@:
	 cmp	 al, 4fh	; if > 4f, invalid
	 ja	 short VIDEO7_MODEL_INVAL ; join Video7 invalid model code

	 cmp	 al, 40h	; if < 40, invalid
	 jb	 short VIDEO7_MODEL_INVAL ; join V7 invalid model code

	 mov	 ax, VIDEO7_1024i ; mark as 1024i
	 jmp	 SVGA_MODEL_EXIT ; join common exit code

SVGA_MODEL_PARADISE:
	 mov	 ax, PARADISE_PVGA1a ; identify model

	 Public  PARADISE_EXIT
PARADISE_EXIT:
	 jmp	 SVGA_MODEL_EXIT ; join common exit code

SVGA_MODEL_TSENG:
	 mov	 ax,SMODEL	; Model was set during recognition
	 jmp	 SVGA_MODEL_EXIT ; join common exit code

SVGA_MODEL_CHIPS:
	 mov	 ax, 5f00h	; C&T extended BIOS call to get controller info
	 int	 10h		; call VGA BIOS
	 cmp	 al, 5fh	; is function supported?
	 je	 short @F	; yes, go ahead

	 jmp	 SVGA_MODEL_UNK ; join code for unknown model

@@:
	 mov	 al, bl 	; get chip type/revision info
	 and	 bl, 0fh	; isolate low nybble of revision
	 or	 bl, 30h	; convert to ASCII
	 mov	 cl, 4		; set up for shift
	 shr	 al, cl 	; get high nybble
	 or	 al, al 	; is it 0?
	 jz	 short SVGA_MODEL_CHIPS_82c451

	 cmp	 al, 1		; is it 1?
	 je	 short SVGA_MODEL_CHIPS_82c452

	 cmp	 al, 2		; is it 2?
	 je	 short SVGA_MODEL_CHIPS_82c455

	 mov	 ax, CHIPS_82c453 ; any other value means 82c453
	 mov	 CHIPS_82c453_rev, bl ; set rev byte
	 jmp	 short @F	; done

SVGA_MODEL_CHIPS_82c451:
	 mov	 ax, CHIPS_82c451 ; identify model
	 mov	 CHIPS_82c451_rev, bl ; set rev byte
	 jmp	 short @F	; and split

SVGA_MODEL_CHIPS_82c452:
	 mov	 ax, CHIPS_82c452 ; identify model
	 mov	 CHIPS_82c452_rev, bl ; set rev byte
	 jmp	 short @F	; and exit

SVGA_MODEL_CHIPS_82c455:
	 mov	 ax, CHIPS_82c455 ; identify model
	 mov	 CHIPS_82c455_rev, bl ; set rev byte
@@:
	 jmp	 SVGA_MODEL_EXIT ; join common exit code

SVGA_MODEL_GENOA:
	 mov	 al, GENOA_MODBYTE ; model byte gotten while determining chipset
	 cmp	 al, 33h	; izit 5100/5200?
	 je	 short @F	; yes

	 cmp	 al, 55h	; izit 5300/5400?
	 je	 short @F	; yes

	 mov	 ax, GENOA_GVGA ; it's a Genoa
	 jmp	 SVGA_MODEL_EXIT ; join common exit code

@@:
	 mov	 ax, GENOA_5000 ; it's actually a Tseng ET3000 (used for 5xxx
				; series Genoa cards)
	 jmp	 SVGA_MODEL_EXIT ; join common exit code

SVGA_MODEL_AHEAD:
	 OUTP	 @AHEAD_AER,0fh ; Address enable register
	 OUTNP	 20h		; Fetch enable value
	 in	 al,dx		; Read value back
	 cmp	 al, 20h	; Izit model A?
	 je	 short @F	; Yes

	 mov	 ax, AHEAD_B	; Identify as model B
	 jmp	 SVGA_MODEL_EXIT ; Join common exit code

@@:
	 mov	 ax, AHEAD_A	; Identify as model A
	 jmp	 SVGA_MODEL_EXIT ; Join common exit code

SVGA_MODEL_EXIT:
	 mov	 VMODEL, ax	; save for later use

;;;;;	 mov	 NORESTORE,0	; Clear flag
;;;;;	 call	 REST_SVGA	; Restore video state

	 REGREST <ES,BP,DI,SI,DX,CX,BX> ; restore caller's registers
	 assume  es:nothing	; Tell the assembler

	 ret			; return to caller

	 assume  ds:nothing, es:nothing, ss:nothing

SVGA_MODEL	endp

	 PPROC	 SVGA_MODELID -- Return model ID * DX:AX
	 assume  ds:DGROUP, es:nothing, ss:nothing

COMMENT |

Return a character * to a static ASCIIZ string representing the
passed model code.  If model code is MODEL_UNDEF, first determine
the model code.

Input:	 Model code on stack
Output:  DX:AX ==> ASCIIZ string representing model

|

	 push	 bp		; save bp
	 mov	 bp, sp 	; get stack pointer
	 mov	 ax, [bp].arg1w ; get argument

	 REGSAVE <BX,CX>	; Save caller's registers

	 cmp	 ax,MODEL_UNDEF ; Izit defined by caller?
	 jne	 short @F	; Jump if so

	 mov	 ax,VMODEL	; Get saved model ID
	 cmp	 ax,MODEL_UNDEF ; Did we previously figure it out?
	 jne	 short @F	; Jump if so

	 call	 SVGA_MODEL	; Get vendor code in AX

@@:
	 or	 ax, ax 	; Izit 0 (MODEL_UNK)?
	 jz	 short SVGA_MODELID_MINVAL ; If so, tell 'em so

	 cmp	 SVENDOR,VESA	; Izit a generic VESA?
	 je	 short @F	; Jump if so

	 cmp	 SVENDOR,STB	; Izit an STB?
	 jne	 short SVGA_MODELID_NOTVESA ; Jump if so

@@:
	 mov	 dx,VESA_OEMP.VSEG ; Get segment of OEM StringPtr
	 mov	 ax,VESA_OEMP.VOFF ; Get offset
	 jmp	 short SVGA_MODELID_EXIT2 ; Return to caller

SVGA_MODELID_NOTVESA:
	 dec	 ax		; make it 0-based
	 push	 ax		; save model ID
	 mov	 ax, SVENDOR	; get vendor ID
	 mov	 cl, VINFO_SHL	; Number of bits to shift
	 shl	 ax, cl 	; index into VINFO_STR array
	 add	 ax, offset ID_TAB ; add to base of array
	 mov	 bx, ax 	; use BX as index
	 mov	 cl, [bx].VINFO_MLEN	; get highest model for vendor
	 mov	 bx, [bx].VINFO_MTAB	; get pointer into model ID table
	 pop	 ax		; get model ID back
	 cmp	 al, cl 	; Izit a valid model ID for this vendor?
	 ja	 SVGA_MODELID_MINVAL ; return UNK_ID pointer

	 shl	 ax, 1		; make it an index into the dw table
	 add	 bx, ax 	; offset into <vendor>_MTAB
	 mov	 ax, [bx]	; get near char *
	 jmp	 short SVGA_MODELID_EXIT ; and we're done

SVGA_MODELID_MINVAL:
	 mov	 ax, offset UNK_ID

SVGA_MODELID_EXIT:

	 mov	 dx, ds 	; Make it a far *
SVGA_MODELID_EXIT2:
	 REGREST <CX,BX>	; restore caller's registers

	 pop	 bp		; restore caller's BP

	 ret			; return

	 assume  ds:nothing, es:nothing, ss:nothing

SVGA_MODELID	 endp

	 PPROC	SVGA_MEMSIZE -- dispatcher to appropriate memory size function
	 assume  ds:DGROUP, es:nothing, ss:nothing

COMMENT |

Return memory size in K in AX.	If size is unknown but is greater than a
known amount, that amount + 1 is returned.  For example, 257 means that
more than 256K is known to be installed.

Input:	 None.
Output:  AX = memory size in K or -1 if failed or unable to get size.

|

	 REGSAVE <BX,CX,DX>

;;;;;	 call	 SAVE_SVGA	; Save state
;;;;;	 mov	 NORESTORE,1	; Disable save/restore

	 mov	 ax, SVENDOR	; get vendor code
	 cmp	 ax, VENDOR_UNDEF ; Izit defined yet?
	 jne	 @F

	 call	 SVGA_VENDOR	; get vendor code in AX

@@:
	 ; Vendor code is 0-based, since VENDOR_UNK is valid.
	 mov	 cl, VINFO_SHL	; Number of bits to shift
	 shl	 ax, cl 	; index into VINFO_STR array
	 add	 ax, offset ID_TAB ; add to base of array
	 mov	 bx, ax 	; use BX to get struct address
	 cmp	 [bx].VINFO_FLEN, 1 ; is function 0 (get mem size) supported?
	 jb	 short SVGA_MEMSIZE_ERR ; return -1 to indicate error

	 mov	 bx, [bx].VINFO_FTAB	; get pointer into function table
	 call	 [bx].FUNT_FN0	; dispatch to OEM_MEMSIZE (function 0)
	 jmp	 short SVGA_MEMSIZE_EXIT ; join common exit code

SVGA_MEMSIZE_ERR:
	 mov	 ax, -1 	; return -1 to indicate something went wrong

SVGA_MEMSIZE_EXIT:
;;;;;	 mov	 NORESTORE,0	; Enable save/restore
	 call	 REST_SVGA	; Restore video state (saved during SVGA_VENDOR)

	 REGREST <DX,CX,BX>	; restore caller's registers

	 ret			; return

	 assume  ds:nothing, es:nothing, ss:nothing

SVGA_MEMSIZE	 endp

;------------------- Private functions --------------------
	 NPPROC  SAVE_SVGA -- save entire video state
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Save video state, rows, and screen contents.  Allocates VGASAVEP if not
already allocated.

|

	 REGSAVE <ax,bx,cx,dx,si,di,bp,es> ; Save

	 cmp	 NORESTORE,0	; Izit disabled?
	MJ nz	 SSVGA_EXIT	; Jump if so

	 ; Make sure we have a VGA
	 call	 SVGA_ISVGA	; Returns AX=0 if not VGA
	 or	 ax,ax		; Izit a VGA?
	MJ z	 SSVGA_EXIT	; Skip out if not

	 mov	 ax,seg BIOSDATA ; Address BIOS data area
	 mov	 es,ax		; via ES
	 assume  es:BIOSDATA	; Tell the assembler

	 mov	 al,EGA_ROWS	; Get number of rows
	 mov	 VGAROWS,al	; Save for restoral

	 ; We need to forcibly reset the mode when we're done (click, click)
	 ; This is annoying but necessary, as our tests send some cards
	 ; out into the wild blue yonder, and (surprise) these same cards
	 ; don't have a properly working save/restore state feature.
	 DVIDCALL @GETINF	; AL = mode, BH = page
	 mov	 PREVMODE,al	; Save mode
	 mov	 PREVPAGE,bh	; Save page (should be 0)

	 ; Since the Paradise PVGA1a card does NOT support save/restore,
	 ; we also have to save and restore cursor position/shape
	 DVIDCALL @GETPOS	; Get position for page BH in DX, shape in CX
	 mov	 VGACURSHAPE,cx ; Save shape
	 mov	 VGACURPOS,dx	; Save position

	 ; Invalidate save area
	 mov	 VGASAVED,0	; VGASAVE does not contain valid data

	 ; Invalidate pointer to save block
	 cmp	 VGASAVEP,-1	; Does it need to be reallocated?
	 jne	 short @F	; Jump if not

	 ; Allocate save pointer
	 mov	 bx,((size VGASAVE_STR) + 15) shr 4 ; Size of buffer in paras
	 DOSCALL @GETMEM	; Return pointer in AX
	 jc	 short SSVGA_EXIT ; No room at the inn

	 mov	 VGASAVEP,ax	; Save segment

@@:
	 ; Address save buffer
	 mov	 es,ax		; Address save buffer segment
	 assume  es:nothing	; Tell the assembler

	 ; If we're running under Windows, skip the save/restore
	 ; state.  It might be a DOSMAX window, and we really don't
	 ; NEED to since we're resetting the mode and restoring
	 ; the screen contents afterward.  Better to have an ugly
	 ; display than a crashed system.  Some cards expect to
	 ; have A000-AFFF mapped in for the save/restore state.
	 mov	 ax,1600h		; Win386 installation check
	 int	 2fh			; Call Windows-DOS API
	 test	 al,7fh 		; Izit 80h or 00h?
	 jz	 short @F		; Jump if so (Windows not running)

	 cmp	 al,1			; Izit Windows 2.x?
	 je	 short @F		; Jump if so

	 cmp	 al,-1			; Izit (also) Windows 2.x?
	 je	 short @F		; Jump if so

	 jmp	 short SSVGA_XSAVE	; Skip save/restore state

@@:
	 ; Check memory required for hardware + data save
	 mov	 ax,1c00h	; Save/restore subfun 0: get size needed
	 lea	 bx,es:[0].VGASAVE_STATE ; Offset of save buffer
	 mov	 cx,1+2 	; Hardware and data (not DAC)
	 push	 es		; Save buffer segment
	 DVIDCALL		; Call BIOS
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler

	 cmp	 al,1ch 	; Izit supported?
	 jne	 short SSVGA_XSAVE ; Not supported

	 cmp	 bx,@VGASAVEMAX/64 ; Do we need more space than we have?
	 ja	 short SSVGA_XSAVE ; Then don't try to save

	 mov	 ax,1c01h	; Save state
	 lea	 bx,es:[0].VGASAVE_STATE ; Offset of save buffer
	 mov	 cx,1+2 	; Hardware and data
	 push	 es		; Save buffer segment
	 DVIDCALL		; Call BIOS
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler

	 mov	 VGASAVED,1	; Mark as saved

SSVGA_XSAVE:
	 ; Move screen contents into save buffer
	 push	 ds		; Save for a minute

	 mov	 ax,0B800h	; Safe assumption for EGA/VGA
	 mov	 ds,ax		; Source segment
	 assume  ds:nothing	; Tell the assembler
	 sub	 si,si		; Assume page 0 active
	 lea	 di,es:[0].VGASAVE_SCRN ; Offset of screen buffer
	 mov	 cx,@SCRNSAVEMAX ; Maximum words to save
    rep  movsw			; Move it, and don't worry about
				; waiting for retrace...
	 pop	 ds		; Restore DGROUP segment
	 assume  ds:DGROUP	; Tell the assembler

SSVGA_EXIT:
	 REGREST <es,bp,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing

	 ret			; Return
	 assume  ds:nothing,es:nothing,ss:nothing

SAVE_SVGA	 endp		; end SAVE_SVGA procedure

	 NPPROC  REST_SVGA -- restore entire video state
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Restores video state, rows, and screen contents then releases buffer
allocated by SAVE_SVGA.

|

	 REGSAVE <ax,bx,cx,dx,si,di,bp,es> ; Save

	 cmp	 NORESTORE,0	; Izit disabled?
	MJ nz	 RSVGA_EXIT	; Jump if so

	 ; Make sure we have a VGA
	 call	 SVGA_ISVGA	; Returns AX=0 if not VGA
	 or	 ax,ax		; Izit a VGA?
	MJ z	 RSVGA_EXIT	; Skip out if not

	 ; Do we have a valid pointer?
	 mov	 ax,VGASAVEP	; Get segment of save buffer
	 cmp	 ax,-1		; Izit valid?
	MJ e	 RSVGA_EXIT	; Jump if not, and screw 50-line restore

	 mov	 es,ax		; Address buffer segment for restore state
	 assume  es:nothing	; Tell the assembler

	 cmp	 VGASAVED,0	; Did we also save state?
	 je	 short RSVGA_CHECKROWS ; Jump if not

	 cmp	 SVENDOR,S3_INC ; Izit the broken Orchid Fahrenheit?
	 je	 short RSVGA_CHECKROWS ; Jump if so

	 cmp	 SVENDOR,STB	; Izit an STB board?
	 jne	 short @F	; Jump if not

	 cmp	 VMODEL,STB_S3	; Izit the STB Windows Accelerator?
	 je	 short RSVGA_CHECKROWS ; Jump if so

@@:
	 mov	 ax,1c02h	; Restore state
	 lea	 bx,es:[0].VGASAVE_STATE ; Offset of save buffer
	 mov	 cx,1+2 	; Hardware and data
	 DVIDCALL		; Call BIOS

RSVGA_CHECKROWS:
	 ; Reset the video mode.  This will make multisync monitors
	 ; do the Twilight Zone thing, but we need it 'cause some cards
	 ; are totally wrecked when we're done testing, and their save /
	 ; restore state doesn't work (Orchid Fahrenheit 1280).
	 mov	 al,PREVMODE	; Get previous video mode
	 DVIDCALL @SETMOD	; Make it the current mode
	 mov	 al,PREVPAGE	; Get previous active page (should be 0)
	 DVIDCALL @SETPAG	; Make it the current page
	 mov	 cx,VGACURSHAPE ; Get cursor shape
	 DVIDCALL @SETTYP	; Make it the current cursor type
	 mov	 dx,VGACURPOS	; Get cursor position
	 mov	 bh,PREVPAGE	; Get active page (should be 0)
	 DVIDCALL @SETPOS	; Set cursor position for page BH to DH,DL

	 ; Restore screen contents now
	 REGSAVE <ds>		; Save DGROUP addressability

	 mov	 ds,VGASAVEP	; Address save buffer for string move
	 assume  ds:nothing	; Tell the assembler

	 sub	 di,di		; Assume destination page 0
	 mov	 bx,0B800h	; Safe assumption for VGA
	 mov	 es,bx		; Address regen buffer
	 assume  es:nothing	; Tell the assembler

	 lea	 si,ds:[0].VGASAVE_SCRN ; Offset of screen buffer
	 mov	 cx,@SCRNSAVEMAX ; Words to move
    rep  movsw			; Move it back

	 REGREST <ds>		; Restore DGROUP
	 assume  ds:DGROUP	; Tell the assembler

	 mov	 al,VGAROWS	; Get previous row count
	 cmp	 al,25-1	; Was it 25 rows?
	 je	 short RSVGA_ROWSDONE ; If so, join common code

	 cmp	 al,43-1	; Was it 43 rows?
	 je	 short RSVGA_R4350 ; Jump if not

	 cmp	 al,50-1	; Was it 50 rows?
	 jne	 short RSVGA_ROWSDONE ; Join common code if not

RSVGA_R4350:
; Restore 43 line mode
; Restore 50 line mode

	 mov	 ax,1112h	; Use ROM double dot font
	 mov	 bl,0		; Use block 0
	 DVIDCALL		; Set new font

RSVGA_ROWSDONE:
	 mov	 es,VGASAVEP	; Get save buffer segment in ES
	 assume  es:nothing	; Tell the assembler

	 DOSCALL @RELMEM	; Release it

	 mov	 VGASAVEP,-1	; Mark it as unallocated

RSVGA_EXIT:
	 REGREST <es,bp,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return
	 assume  ds:nothing,es:nothing,ss:nothing

REST_SVGA	endp		; End REST_SVGA procedure

; Gee, it would be really nice if this worked, but it doesn't.
; On the Ultra+, the contents of BBh doesn't look anything like
; what we'd expect from the documentation.
;;;;;;;  NPPROC  ATI_MEMSIZE -- return vidmem in K in AX
;;;;;;;  assume  ds:DGROUP, es:nothing, ss:nothing
;;;;;;;
;;;;;;;COMMENT |
;;;;;;;
;;;;;;;Get memory size for all ATI cards.
;;;;;;;
;;;;;;;Input:	 None (assumed to be ATI).
;;;;;;;Output:	AX = size (see SVGA_MEMSIZE).
;;;;;;;
;;;;;;;|
;;;;;;;
;;;;;;;  REGSAVE <BX,DX,SI,DI,ES>	; save caller's registers
;;;;;;;
;;;;;;;  OUTP	 ATI_EXT, 0bbh	; get monitor/memory
;;;;;;;  inc	 dx		; point to data port
;;;;;;;  in	 al, dx 	; get byte
;;;;;;;  mov	 bx, 256	; default value
;;;;;;;  test	 al, 20h	; test bit 5
;;;;;;;  jz	 @F		; not 512K
;;;;;;;
;;;;;;;  mov	 bx, 512	; 512K
;;;;;;;@@:
;;;;;;;  mov	 ax, bx 	; put return value in AX
;;;;;;;
;;;;;;;  REGREST <ES,DI,SI,DX,BX>	; restore caller's registers
;;;;;;;
;;;;;;;  ret			; return to caller
;;;;;;;
;;;;;;;  assume  ds:nothing, es:nothing, ss:nothing
;;;;;;;
;;;;;;;ATI_MEMSIZE	 endp
;;;;;;;
	 NPPROC  TRIDENT_MEMSIZE -- return vidmem in K in AX
	 assume  ds:DGROUP, es:nothing, ss:nothing

COMMENT |

Get memory size for Trident products.

Input:	 None (assumed to be Trident).
Output:  AX = size (see SVGA_MEMSIZE).

|

	 REGSAVE <BX,DX,SI,DI,BP,ES>	; save caller's registers

	 mov	 cx, 401eh	; Memsize mask & index for < 8800
	 OUTP	 @TRIDENT_MCREG,0bh ; get version
	 INNP			; get contents of version register
	 cmp	 al, 2		; is it < 8800?
	 jb	 short @F	; yes, so use 1e

	 mov	 cx, 031fh	; CH contains mask, CL index
@@:
	 OUTP	 @TRIDENT_MCREG,0bh ; Address hardware version register
	 OUTNP	 0		; Write to enable old definitions
	 OUTP	 @TRIDENT_MCREG,cl ; get Software Programming register
	 IODELAY		; Delay a bit extra

	 INNP			; Get data byte
	 and	 al, ch 	; mask off memory size bits
	 mov	 ah, al 	; put in high byte
	 test	 ah, 40h	; do we need to shift?
	 jz	 short @F	; nope

	 mov	 cl, 6		; number of bits to shift
	 shr	 ah, cl 	; get bits 6 and 7
@@:
	 or	 ah,ah		; Izit 0?
	 jnz	 short @F	; No, so we don't have to worry about bad values

	 DVIDCALL @GETINF	; Get current mode
	 mov	 bx,ax		; Save mode

	 mov	 ax,5fh 	; Attempt to set 1024x768x16 mode
	 DVIDCALL		; Call BIOS
	 xchg	 ax,bx		; Save result (in AH) and get previous mode

	 DVIDCALL @SETMOD	; Set mode
	 xchg	 ax,bx		; Get result from 5f mode set

	 mov	 cl,7		; Number of bits to shift
	 shr	 ah,cl		; Get high bit in bit 0
	 xor	 ah,1		; Invert bit - if no error, bit is 1
@@:
	 inc	 ah		; add 256
	 cmp	 ah, 3		; isit 768?
	 jne	 short @F	; no, so OK

	 inc	 ah		; make it 1MB
@@:
	 sub	 al, al 	; zero low byte

	 REGREST <ES,BP,DI,SI,DX,BX> ; restore caller's registers

	 ret			; return to caller

	 assume  ds:nothing, es:nothing, ss:nothing

TRIDENT_MEMSIZE  endp

	 NPPROC  CHIPS_MEMSIZE -- return vidmem in K in AX
	 assume  ds:DGROUP, es:nothing, ss:nothing

COMMENT |

Get memory size for C&T chipsets.

Input:	 None (assumed to be C&T chipset).
Output:  AX = size (see SVGA_MEMSIZE).

|

	 REGSAVE <BX,DX,SI,DI,BP,ES> ; save caller's registers

	 mov	 ax, 5f00h	; extended BIOS call - get VGA info
	 DVIDCALL		; call VGA BIOS
	 cmp	 al, 5fh	; izit supported?
	 je	 short @F	; yes - BH = memory size

	 mov	 ax, 256	; default memory size
	 jmp	 short CHIPS_MEMSIZE_EXIT ; join common exit code

@@:
	 or	 bh, bh 	; izit 0 (256K)?
	 jnz	 short @F	; nope

	 mov	 ax, 256	; 256K
	 jmp	 short CHIPS_MEMSIZE_EXIT ; join common exit code

@@:
	 cmp	 bh, 2		; izit 1 (512K)?
	 jnb	 short @F	; izit 2 (1MB)?

	 mov	 ax, 512	; 512K
	 jmp	 short CHIPS_MEMSIZE_EXIT ; join common exit code

@@:
	 mov	 ax, 1024	; 1MB
CHIPS_MEMSIZE_EXIT:

	 REGREST <ES,BP,DI,SI,DX,BX> ; restore caller's registers

	 ret			; return to caller

	 assume  ds:nothing, es:nothing, ss:nothing

CHIPS_MEMSIZE	 endp

	 NPPROC  GENOA_MEMSIZE -- return vidmem in K in AX
	 assume  ds:DGROUP, es:nothing, ss:nothing

COMMENT |

Get memory size for Genoa chipset.

Input:	 None (assumed to be Genoa chipset).
Output:  AX = size (see SVGA_MEMSIZE).

|

	 mov	 al,5fh 		; 1024x768x16 mode for Genoa
	 jmp	 MODECHG_MEMSIZE	; Join common code for getting size

	 assume  ds:nothing, es:nothing, ss:nothing

GENOA_MEMSIZE	 endp

	 NPPROC  PARADISE_MEMSIZE -- return vidmem in K in AX
	 assume  ds:DGROUP, es:nothing, ss:nothing

COMMENT |

Get memory size for Paradise chipset.

Input:	 None (assumed to be Paradise chipset).
Output:  AX = size (see SVGA_MEMSIZE).

|

	 REGSAVE <BX,CX,DX,SI,DI,BP,ES> ; save caller's registers

	 OUTP	 @PARADISE_EXT,0fh ; index PR5
	 INNP			; Get previous ER setting
	 mov	 bl,al		; Save it in BL
	 OUTP	 dx,05h 	; enable Paradise extensions
	 OUTP	 @PARADISE_EXT,0bh ; index PR1
	 INNP			; get memsize in bits 6-7
	 mov	 bh,al		; Save memsize
	 OUTP	 @PARADISE_EXT,0fh ; Index PR5
	 OUTNP	 bl		; Send out saved value for ER setting
	 mov	 al,bh		; Get memsize byte
	 mov	 cl, 6		; number of bits to shift
	 shr	 al, cl 	; isolate bits 6,7
	 mov	 bx, 256	; default size
	 cmp	 al, 2		; izit 512K?
	 jb	 short PARADISE_MEMSIZE_EXIT ; nope - 256K

	 ja	 short @F	; 1MB

	 mov	 bx, 512	; 512K
	 jmp	 short PARADISE_MEMSIZE_EXIT ; join common exit code

@@:
	 mov	 bx, 1024	; 1MB
PARADISE_MEMSIZE_EXIT:
	 mov	 ax, bx 	; put return value in AX

	 REGREST <ES,BP,DI,SI,DX,CX,BX> ; restore caller's registers

	 ret			; return to caller

	 assume  ds:nothing, es:nothing, ss:nothing

PARADISE_MEMSIZE	 endp

	 NPPROC  TSENG_MEMSIZE -- return vidmem in K in AX
	 assume  ds:DGROUP, es:nothing, ss:nothing

COMMENT |

Get memory size for Tseng chipset.

Input:	 None (assumed to be Tseng chipset).
Output:  AX = size (see SVGA_MEMSIZE).

|

	 mov	 al,37h 	; TSENG Labs 1024x768x16 mode
;;;	 jmp	 MODECHG_MEMSIZE ; Join common code to get size through mode chg

	 assume  ds:nothing, es:nothing, ss:nothing

TSENG_MEMSIZE	 endp

	 NPPROC  MODECHG_MEMSIZE -- Determine memory size through mode change
	 assume  ds:DGROUP, es:nothing, ss:nothing

COMMENT |

Get memory size by switching to mode in AL and checking to see if it sticks.
If it sticks, say we have 512K.

Input:	 AL = mode number
Output:  AX = size (see SVGA_MEMSIZE).

|

	 REGSAVE <BX,CX,DX,SI,DI,BP,ES> ; Save caller's registers

	 push	 ax		; Save mode to change to

	 DVIDCALL @GETINF	; GETMODE

	 mov	 bx,ax		; Save it in BX

	 pop	 ax		; Get mode to change to
	 push	 bx		; Save mode to restore
	 push	 ax		; Save mode to change to and compare

	 DVIDCALL @SETMOD	; Change mode to high-res

	 DVIDCALL @GETINF	; BIOS GETMODE

	 pop	 bx		; Get mode we were supposed to change to
	 cmp	 bl,al		; Did it stick?

	 pop	 ax		; Get mode to restore
	 pushf			; Save result of last comparison

	 DVIDCALL @SETMOD	; Restore text mode

	 mov	 ax,256 	; Assume failure
	 popf			; Get result of comparison
	 jne	 short @F	; If it didn't stick, we only have 256K

	 shl	 ax,1		; AX <<= 1 (512K)

@@:
	 REGREST <ES,BP,DI,SI,DX,CX,BX> ; Restore caller's registers
	 assume  es:nothing

	 ret			; return to caller

	 assume  ds:nothing, es:nothing, ss:nothing

MODECHG_MEMSIZE  endp

	 NPPROC  VIDEO7_MEMSIZE -- return vidmem in K in AX
	 assume  ds:DGROUP, es:nothing, ss:nothing

COMMENT |

Get size of memory on Video7 card.

Input:	 None (assumed to be Video7 with BIOS).
Output:  AX = size in K.

|

	 REGSAVE <BX,DX,SI,DI,BP,ES> ; save caller's registers

	 mov	 ax, 6f07h	; extended BIOS call - get revision/memory
	 DVIDCALL		; call VGA BIOS
	 and	 ah, not 80h	; mask off high bit
	 sub	 al, al 	; bits 0-6 of AH contain # of 256K blocks

	 REGREST <ES,BP,DI,SI,DX,BX> ; restore caller's registers

	 ret			; return to caller

	 assume  ds:nothing, es:nothing, ss:nothing

VIDEO7_MEMSIZE	 endp

	 NPPROC AHEAD_MEMSIZE -- Get memory size for AHEAD VGA
	 assume  ds:DGROUP,es:nothing,ss:nothing

COMMENT |

Get size of memory in K on AHEAD VGA card.

Input:	 None (assumed to be AHEAD VGA card).
Output:  AX = memory size in kilobytes

|

	 mov	 al,61h 	; AHEAD VGA 640x480x256 mode
	 jmp	 MODECHG_MEMSIZE ; Join common code to get size through mode chg

	 assume  ds:nothing, es:nothing, ss:nothing

AHEAD_MEMSIZE	 endp

	 NPPROC  S3_MEMSIZE -- Get memory size for S3 chipset
	 assume  ds:DGROUP,es:nothing,ss:nothing

COMMENT |

Memory size was determined during chipset detection.  Put it in AX and return.

|

	 mov	 ax,SMEMORY	; Get memory size (already calculated)
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

S3_MEMSIZE	endp		; End S3_MEMSIZE procedure

	 NPPROC  SRCHSTR -- Search For A String
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Search for a string.

On entry:

On exit:

DI	 =	 offset of match in ROM
CF	 =	 0 if found
	 =	 1 if not

|

SRCHSTR_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
SRCHSTR_LEN1 dw  ?		; Length of string
SRCHSTR_OFF1 dw  ?		; Offset of string in DGROUP
SRCHSTR_LEN2 dw  ?		; Length of search area
SRCHSTR_VEC2 dd  ?		; Ptr to area to search

SRCHSTR_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,cx,si,es>	; Save registers

	 les	 di,[bp].SRCHSTR_VEC2 ; ES:DI ==> start of search area
	 assume  es:nothing	; Tell the assembler about it

	 mov	 si,[bp].SRCHSTR_OFF1 ; DS:SI ==> source string
	 mov	 cx,[bp].SRCHSTR_LEN2 ; Get length of search area
	 sub	 cx,[bp].SRCHSTR_LEN1 ; Less length of the string
	 dec	 cx		; Less one to not fall off the end
	 mov	 al, ds:[si] ; Get the first byte

SRCHSTR_NEXT:
	 jcxz	 SRCHSTR_ERR	; Jump if no more bytes to check

   repne scas	 es:[di].LO	; Search for the 1st byte
	 jne	 short SRCHSTR_ERR ; Jump if no match

	 REGSAVE <cx,di>	; Save registers
	 mov	 si,[bp].SRCHSTR_OFF1 ; DS:SI ==> source string
	 inc	 si		; Plus one to account for the first match
	 mov	 cx,[bp].SRCHSTR_LEN1 ; Get length of the string
	 dec	 cx		; Less one to account for the first match
    repe cmps	 DGROUP:[si].LO,es:[di].LO ; Check the rest
	 REGREST <di,cx>	; Restore
	 jne	 short SRCHSTR_NEXT ; Jump if no match

	 dec	 di		; Back off to start of match

	 clc			; Mark as found

	 jmp	 short SRCHSTR_EXIT ; Join common exit code

SRCHSTR_ERR:
	 stc			; Mark as not found
SRCHSTR_EXIT:
	 REGREST <es,si,cx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2+2+4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,ss:nothing

SRCHSTR  endp			; End SRCHSTR procedure

	 MEND			; End SVGA_INF module
