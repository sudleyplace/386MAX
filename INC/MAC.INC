;' $Header:   P:/PVCS/MAX/INC/MAC.INV   1.0   05 Sep 1995 13:27:26   HENRY  $
;
; (C) Copyright 1987-95 Qualitas, Inc.	All rights reserved.
;
; MAC.INC
;
; Memory Allocation Chain structure and equates
;


.xcref MAC_STR
MAC_STR  struc

MAC_TYPE db	 ?		; 'Z' = last, 'M' = valid
MAC_OWNR dw	 ?		; Owner:  0 = unallocated
				;	 -1 = device driver
				;	 -2 = upper memory block
MAC_NPAR dw	 ?		; # paragraphs allocated to this entry
				; not counting the MAC para
MAC_BACK dw	 ?		; Back pointer to previous entry
MAC_DRV  db	 ?		; Block device driver starting drive #
MAC_NAME db	 '        '     ; Program name,0 if DOS 4.x

MAC_STR  ends

; Note that MAC_BACK is used in high DOS memory only.

; Equates for MAC_OWNR

@MAC_FREE equ	  0		; Unallocated
@MAC_DRV  equ	 -1		; Device driver
@MAC_UMB  equ	 -2		; Upper Memory Block
@MAC_SPAN equ	 -3		; RAM or ROM
@MAC_TEMP equ	 -4		; Temporary owner
@MAC_INT  equ	 -5		; INT block entry (merged into ENV entry)
@MAC_LSEG equ	 -6		; UMB LSEG block entry
@MAC_LFREE equ	 -7		; LSEG-to-be-freed
@MAC_PLUG equ	 -8		; Used during 386LOAD to plug holes outside
				; of target region
@MAC_SUBSEG_DOS equ -9		; Sub-segment (FILES=, BUFFERS=, ...)
@MAC_HOLE equ	 -10		; Hole created by a UMB resizing downward
@MAC_LOADLO equ  -11		; 386LOAD.COM hole in low DOS
@MAC_SUBSEG_MAX equ -12 	; Sub-segment (HPDAREG=, XBDAREG=, ...)

@MAC_LINK equ	 0008h		; MAC linking entry used to span into high DOS

; Equates for MACLOC

@MACLOC_LO equ	 0		; Low fit in designated block
@MACLOC_HI equ	 1		; High ...

; Equates for MAC_TYPE

@MAC_MID   equ	  'M'           ; Middle entry
@MAC_END   equ	  'Z'           ; Ending entry

; These tokens are used in the subsegment structure.  They are also
; saved in the MAC_DRV field of the MAC entry for each subsegment to
; simplify display code in 386util.

;----- HARPO tokens ------------
@TOKEN_FILES	 equ 'F'        ; FILES= token
@TOKEN_FCB	 equ 'X'        ; FCB= token
@TOKEN_BUFFERS	 equ 'B'        ; BUFFERS= token
@TOKEN_LASTDRV	 equ 'L'        ; LASTDRV= token
@TOKEN_STACKS	 equ 'S'        ; STACKS= token
@TOKEN_DOS3	 equ 'V'        ; DOS 3 data token
@TOKEN_BATCH	 equ 'Q'        ; Temporary batch data token
;;;;;;_CCOM	 equ 'C'        ; Used only in tables; COMMAND.COM has an LSEG
;;;;;;_ENV	 equ 'E'        ; COMMAND.COM's environment- covered by LSEG
@TOKEN_IFS_G	 equ 'G'        ; Installable File System - G ???
@TOKEN_IFS_H	 equ 'H'        ; Installable File System - H ???
@TOKEN_IFS_R	 equ 'R'        ; Installable File System - R ???
@TOKEN_IFS_Y	 equ 'Y'        ; Installable File System - Y ???
;----- MAX subsegment tokens ---
@TOKEN_XBDAREG	 equ 'D'        ; XBDAREG=
@TOKEN_HPDAREG	 equ 'H'        ; HPDAREG=
@TOKEN_STACKREG  equ 'M'        ; STACKREG=
;----- DOS data tokens ---------
;;;;;;_FILES	 equ 'F'        ; FILES= token
;;;;;;_FCB	 equ 'X'        ; FCB= token
;;;;;;_BUFFERS	 equ 'B'        ; BUFFERS= token
;;;;;;_LASTDRV	 equ 'L'        ; LASTDRV= token
;;;;;;_STACKS	 equ 'S'        ; STACKS= token
@TOKEN_XBUFFERS  equ 'C'        ; DOS 4 BUFFERS /X
@TOKEN_DEVICE	 equ 'D'        ; DEVICE=
@TOKEN_XDEVICE	 equ 'E'        ; Appended to device
@TOKEN_IFS	 equ 'I'        ; IFS driver (?)
@TOKEN_ENDCHAIN  equ 'T'        ; End of subsegment chain marker

; Memory allocation strategies used in 5800/5801
; Note that all combinations of non-reserved bits are valid.  The
; $STRA_BEST bit is clear for first fit, set for best fit.
; $STRA_NOLSEG, $STRA_END and $STRA_TMP are used internally.

STRA_REC record $STRA_NOLSEG:1,$STRA_END:1,$STRA_TMP:1,$STRA_HITRAN:1,\
	$STRA_RSV1:4,\
	$STRA_HI:1,$STRA_HIONLY:1,$STRA_RSV2:4,$STRA_LAST:1,$STRA_BEST:1
@STRA_NOLSEG equ mask $STRA_NOLSEG ; 8000: Don't create LSEG entry
@STRA_END equ	 mask $STRA_END ; 4000: Allocate at high end of region
@STRA_TMP equ	 mask $STRA_TMP ; 2000: Use @MAC_TEMP entries in low DOS
@STRA_HITRAN equ mask $STRA_HITRAN ; 1000: Crossed over into high DOS
@STRA_HI equ	 mask $STRA_HI	; 0080: High first
@STRA_HIONLY equ mask $STRA_HIONLY ; 0040: High only
@STRA_LAST equ	 mask $STRA_LAST ; 0002: Last fit
@STRA_BEST equ	 mask $STRA_BEST ; 0001: Best fit
@STRA_INVAL equ  ((mask $STRA_RSV1) or (mask $STRA_RSV2)) ; Invalid bits
@STRA_NEEDHI equ @STRA_HIONLY	; Bits that need arenas linked
@STRA_WANTHI equ (@STRA_HI or @STRA_HIONLY or @STRA_HITRAN) ; Bit that could
				; use high DOS
@STRA_UMB equ	 @STRA_HIONLY	; Strategy for XMS UMB allocations

; Flags used for 5802/5803 and in DOS link flag at (List of lists):89h
LINK_REC record $LINK_RSVD:15,$LINK_HIGH:1


@MACALG_GETSTR	equ 00h ; Return allocation strategy in AX
@MACALG_SETSTR	equ 01h ; Set	 ...		     to BX
@MACALG_FFLO   equ 00h	; First fit low only
@MACALG_BFLO   equ 01h	; Best ...
@MACALG_LFLO   equ 02h	; Last ...
@MACALG_FFHI   equ 40h	; First fit high only
@MACALG_BFHI   equ 41h	; Best ...
@MACALG_LFHI   equ 42h	; Last ...
@MACALG_FFHILO equ 80h	; First fit high, then low
@MACALG_BFHILO equ 81h	; Best ...
@MACALG_LFHILO equ 82h	; Last ...
@MACALG_GETLINK equ 02h ; Return upper memory link state in AL
@MACALG_SETLINK equ 03h ; Set	 ...			 to BX
@MACALG_LINK   equ 01h	; Upper memory state is linked
@MACALG_UNLINK equ 00h	; ...			unlinked


