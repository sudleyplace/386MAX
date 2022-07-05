;' $Header:   P:/PVCS/MAX/QMT/MEM_BLK.INV   1.0   05 Sep 1995 16:56:02   HENRY  $
;
; (C) Copyright 1988-93 Qualitas, Inc.	GNU General Public License version 3.
;
; MEM_BLK.INC
;
; Structures and equates for blocks with cursor movement
; (ASK in basic and advanced modes and the memory screen).
;

; ASKBLK equates

@ITEM_MEMADV equ 0		; Memory table field for advanced mode
@ITEM_ASKBAS equ 1		; Ask choice field for basic mode
@ITEM_ASKADV equ 2		; Ask choice field for advanced mode
@ITEM_ASKCMD equ 3		; Ask choice field for ASK dialog box


; Structure for BLK_STRS

; The following structure has one occurrence for each
; block on the screen for which there may be cursor
; movement.
; This means, the ASK screen in basic and advanced modes,
; the memory screen, and the dialog box triggered by the
; ASK keyword.

BLK_STR  struc

BLK_IND  dw	 ?		; Item index for this block
BLK_LEN  dw	 ?		; # valid items in this block
BLK_PCUP dw	 ?		; Ptr to translate table for cursor up
BLK_PCDN dw	 ?		; ...				    down
BLK_PCLF dw	 ?		; ...				    left
BLK_PCRT dw	 ?		; ...				    right
BLK_PCTB dw	 ?		; ...				    tab and s-tab
BLK_PARR dw	 ?		; ... to array of window structures indexed by BLK_IND
BLK_PPATXT dw	 ?		; Ptr to ptr to active text
BLK_PPBTXT dw	 ?		; Ptr to ptr to background text
BLK_AASK db	 ?		; Active ASK attribute
BLK_BASK db	 ?		; Background ...

BLK_STR  ends


