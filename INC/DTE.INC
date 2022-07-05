;' $Header:   P:/PVCS/MAX/INC/DTE.INV   1.0   05 Sep 1995 13:27:16   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; DTE.INC
;
; Descriptor Table Entry structures and equates
;

; Descriptor Table Register Structure

.xcref DTR_STR,DTR_LIM,DTR_BASE
DTR_STR  struc

DTR_LIM  dw	 ?		; 00-01:  Limit (#bytes - 1)
DTR_BASE dd	 ?		; 02-05:  Base offset

DTR_STR  ends


; Descriptor Table Entry Structure

.xcref DTE_STR,DTE_DUMMY,DTE_GDT,DTE_IDT,DTE_DS,DTE_ES,DTE_SS,DTE_CS,DTE_BIOS
DTE_STR  struc

DTE_DUMMY dq	 ?		; 00-07:  First entry not accessible
DTE_GDT  dq	 ?		; 08-0F:  Global descriptor table
DTE_IDT  dq	 ?		; 10-17:  Interrupt ...
DTE_DS	 dq	 ?		; 18-1F:  DS ...
DTE_ES	 dq	 ?		; 20-27:  ES ...
DTE_SS	 dq	 ?		; 28-2F:  SS ...
DTE_CS	 dq	 ?		; 30-37:  CS ...
DTE_BIOS dq	 ?		; 38-3F:  Temporary BIOS ...

DTE_STR  ends


; Move block Descriptor Table Entry structure

.xcref MDTE_STR,MDTE_DUMMY,MDTE_GDT,MDTE_DS,MDTE_ES,MDTE_BIOS,MDTE_SS
MDTE_STR struc

MDTE_DUMMY dq	 ?		; 00-07:  First entry not accessible
MDTE_GDT  dq	 ?		; 08-0F:  Global descriptor table
MDTE_DS   dq	 ?		; 10-17:  DS ...
MDTE_ES   dq	 ?		; 18-1F:  ES ...
MDTE_BIOS dq	 ?		; 20-27:  Temporary BIOS ...
MDTE_SS   dq	 ?		; 28-2F:  SS ...

MDTE_STR ends


; Individual Descriptor Table Entry structure

.xcref DESC_STR,DESC_SEGLM0,DESC_BASE01,DESC_BASE2,DESC_ACCESS,DESC_SEGLM1,DESC_BASE3
DESC_STR struc

DESC_SEGLM0 dw	 ?		; 00-01:  Segment limit, 0-15
DESC_BASE01 dw	 ?		; 02-03:  Segment base bytes 0-1
DESC_BASE2  db	 ?		; 04-04:	       byte  2
DESC_ACCESS db	 ?		; 05-05:  Access rights
DESC_SEGLM1 db	 ?		; 06-06:  Segment limit, 16-19, and flags
DESC_BASE3  db	 ?		; 07-07:	       byte  3

DESC_STR ends


; Record for DESC_SEGLM1 above

.xcref DLIM_REC,$DTE_G,$DTE_B,$DTE_0,$DTE_AVL,$SEGLM1
DLIM_REC record  $DTE_G:1,$DTE_B:1,$DTE_0:1,$DTE_AVL:1,$SEGLM1:4


; Descriptor type record

.xcref DTYP_REC,$DT_P,$DT_DPL,$DT_DC,$DT_TYP
DTYP_REC record  $DT_P:1,$DT_DPL:2,$DT_DC:1,$DT_TYP:4
.xcref DCOD_REC,$DC_COD,$DC_CONF,$DC_READ,$DC_ACC
DCOD_REC record  $DC_COD:1,$DC_CONF:1,$DC_READ:1,$DC_ACC:1
.xcref DDAT_REC,$DD_COD,$DD_EXPD,$DD_WRIT,$DD_ACC
DDAT_REC record  $DD_COD:1,$DD_EXPD:1,$DD_WRIT:1,$DD_ACC:1
.xcref DSYS_REC,$DS_386,$DS_GATE,$DS_BUSY,$DS_TASK
DSYS_REC record  $DS_386:1,$DS_GATE:1,$DS_BUSY:1,$DS_TASK:1


; CPL 0 Access Equates
; System and gate descriptor types
.xcref CPL0_IDLE2,CPL0_LDT,CPL0_BUSY2,CPL0_CALL2,CPL0_TASK,CPL0_INTR2
.xcref CPL0_TRAP2,CPL0_IDLE3,CPL0_BUSY3,CPL0_CALL3,CPL0_INTR3,CPL0_TRAP3
CPL0_IDLE2 equ	 10000001b	; Idle 286 TSS		1
CPL0_LDT   equ	 10000010b	; LDT			2
CPL0_BUSY2 equ	 10000011b	; Busy 286 TSS		3
CPL0_CALL2 equ	 10000100b	; 286 call gate 	4
CPL0_TASK  equ	 10000101b	; Task gate		5
CPL0_INTR2 equ	 10000110b	; 286 interrupt gate	6
CPL0_TRAP2 equ	 10000111b	; 286 trap gate 	7
				; Reserved		8
CPL0_IDLE3 equ	 10001001b	; Idle 386 TSS		9
				; Reserved		A
CPL0_BUSY3 equ	 10001011b	; Busy 386 TSS		B
CPL0_CALL3 equ	 10001100b	; 386 call gate 	C
				; Reserved		D
CPL0_INTR3 equ	 10001110b	; 386 interrupt gate	E
CPL0_TRAP3 equ	 10001111b	; 386 trap gate 	F


; Data and executable types
.xcref CPL0_DRO,CPL0_DATA,CPL0_CODE
CPL0_DRO  equ	 10010000b	; Data, read-only
CPL0_DATA equ	 10010010b	; Data, writable
CPL0_CODE equ	 10011010b	; Code, nonconforming, readable


; CPL 1, 2, and 3 equates
.xcref CPL0,CPL1,CPL2,CPL3
CPL0	 equ	 0 shl $DT_DPL	; Current privilege level 0
CPL1	 equ	 1 shl $DT_DPL	; ...			  1
CPL2	 equ	 2 shl $DT_DPL	; ...			  2
CPL3	 equ	 3 shl $DT_DPL	; ...			  3


; DPL 0, 1, 2, and 3 equates

DPL0	 equ	 0 shl $DT_DPL	; Descriptor privilege level 0
DPL1	 equ	 1 shl $DT_DPL	; ...			     1
DPL2	 equ	 2 shl $DT_DPL	; ...			     2
DPL3	 equ	 3 shl $DT_DPL	; ...			     3


; RPL 0, 1, 2, and 3 equates

RPL0	 equ	 0 shl $PL	; Requestor privilege level 0
RPL1	 equ	 1 shl $PL	; ...			    1
RPL2	 equ	 2 shl $PL	; ...			    2
RPL3	 equ	 3 shl $PL	; ...			    3


; Interrupt Descriptor Table structure

.xcref IDT_STR,IDT_OFFLO,IDT_SELECT,IDT_UNUSED,IDT_ACCESS,IDT_OFFHI
IDT_STR struc

IDT_OFFLO  dw	 ?		; 00-01:  Offset low-word
IDT_SELECT dw	 ?		; 02-03:  Segment selector
IDT_UNUSED db	 0		; 04-04:  Not used
IDT_ACCESS db	 ?		; 05-05:  Access rights
IDT_OFFHI  dw	 ?		; 06-07:  Offset high-word

IDT_STR ends


; Selector code record

.xcref SELECTOR,$SEL,$TI,$PL
SELECTOR record  $SEL:13,$TI:1,$PL:2


