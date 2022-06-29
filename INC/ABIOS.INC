;' $Header:   P:/PVCS/MAX/INC/ABIOS.INV   1.0   05 Sep 1995 13:26:42   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; ABIOS.INC
;
; Structures and equates used to access ABIOS
;

; Device ID equates

@ABIOS_INTERNAL  equ	00h	; ABIOS internal calls
@ABIOS_DISKETTE  equ	01h	; Diskette
@ABIOS_DISK	 equ	02h	; Disk
@ABIOS_VIDEO	 equ	03h	; Video
@ABIOS_KEYB	 equ	04h	; Keyboard
@ABIOS_PARALLEL  equ	05h	; Parallel ports
@ABIOS_SERIAL	 equ	06h	; Serial communications
@ABIOS_SYSTIME	 equ	07h	; System timer
@ABIOS_RTC	 equ	08h	; Real-time clock
@ABIOS_SYSSERV	 equ	09h	; System services
@ABIOS_NMI	 equ	0Ah	; NMI
@ABIOS_MOUSE	 equ	0Bh	; Pointing device
;;;;;;; 	 equ	0Ch	; (Reserved)
;;;;;;; 	 equ	0Dh	; (Reserved)
@ABIOS_NVRAM	 equ	0Eh	; NVRAM
@ABIOS_DMA	 equ	0Fh	; DMA
@ABIOS_POS	 equ	10h	; POS
;;;;;;; 	 equ	11h	; (Reserved)
;;;;;;; 	 equ	12h	; (Reserved)
;;;;;;; 	 equ	13h	; (Reserved)
;;;;;;; 	 equ	14h	; (Reserved)
;;;;;;; 	 equ	15h	; (Reserved)
@ABIOS_KEYBSECUR equ	16h	; Keyboard security



SYSPARM_STR    struc

STARTPTR       dd      ?	; Common Start Routine Pointer
	       dd      ?	; Common Interrupt Routine Ptr
	       dd      ?	; Common Time-out Routine Ptr
STACK_REQ      dw      ?	; Stack Required (bytes)
	       dd      0	; RESERVED
	       dd      0	; RESERVED
	       dd      0	; RESERVED
	       dd      0	; RESERVED
NUM_ENTR       dw      ?	; Number of Entries in Initialization Table

SYSPARM_STR    ends


INIT_TABLE_STR struc

DEVICE_ID      dw      ?	; Device ID
NUM_LOG_IDS    dw      ?	; Number of Logical IDs
DEV_BLK_LEN    dw      ?	; Device Block Length
INIT_PTR       dd      ?	; Initialize Device Block and Function
				;   Transfer Table Routine Pointer
INIT_RB_LEN    dw      ?	; Request Block Length
FTT_LEN        dw      ?	; Function Transfer Table Length
DP_LEN	       dw      ?	; Data Pointers Length
	       db      ?	; Secondary Device ID
	       db      ?	; Revision
	       dw      0	; RESERVED
	       dw      0	; RESERVED
	       dw      0	; RESERVED

INIT_TABLE_STR ends


CDAHDR_STR struc		; CDA header

CDAHDR_DP0OFF dw ?		; Offset to data pointer 0 length
CDAHDR_NLIDS  dw ?		; # logical IDs
	 dd	 ?		; Reserved

CDAHDR_STR ends


CDALID_STR struc		; CDA logical ID

CDALID_DBVEC dd  ?		; Device block pointer
CDALID_FTTVEC dd ?		; Function transfer table pointer

CDALID_STR ends


CDADP_STR struc 		; CDA data pointer

CDADP_LEN dw	 ?		; Length
CDADP_VEC dd	 ?		; Pointer

CDADP_STR ends


REQ_BLK_STR    struc

RB_LEN	   dw	 ?		; 00-01:  Request block length
RB_LID	   dw	 ?		; 02-03:  Logical ID
RB_UNIT    dw	 ?		; 04-05:  Unit
RB_FUNC    dw	 ?		; 06-07:  Function
RB_RES1    dw	 0		; 08-09:  RESERVED (set to ZERO)
RB_RES2    dw	 0		; 0A-0B:  RESERVED (set to ZERO)
RB_RETCODE dw	 ?		; 0C-0D:  Return Code -- also OUTPUT (set to -1)
	   dw	 ?		; 0E-0F:  Time-out   --- only OUTPUT
RB_SPP	   db	 16 dup (?)	; 10-??:  Service specific parameters

REQ_BLK_STR    ends


RB_POS_STR struc		; Request Block for POS device

db (size RB_SPP-RB_LEN) dup (?) ; 00-0F:  Request block header
POS_SLOT_NO  db  ?		; 10-10:  Slot #
POS_RES1     db  0		; 11-11:  RESERVED (set to ZERO)
POS_ADAPT_ID dw  ?		; 12-13:  Adapter ID -- Input/Output
POS_RES2     dw  0		; 14-15:  RESERVED (set to ZERO)
POS_VEC      dd  ?		; 16-19:  Ptr to Data Buffer -- Input
POS_RES3     dw  0		; 1A-1B:  RESERVED (set to ZERO)
POS_RES4     dw  0		; 1C-1D:  RESERVED (set to ZERO)

RB_POS_STR ends


RB_NVRAM_STR struc		; Request Block for NVRAM device

db (size RB_SPP-RB_LEN) dup (?) ; 00-0F:  Request block header
NVRAM_RES1   dw  0		; 10-11:  RESERVED (set to ZERO)
NVRAM_VEC1   dd  ?		; 12-15:  Data pointer #1
NVRAM_RES2   dw  0		; 16-17:  RESERVED (set to ZERO)
NVRAM_RES3   dw  0		; 18-19:  RESERVED (set to ZERO)
NVRAM_VEC2   dd  ?		; 1A-1D:  Data pointer #2
NVRAM_RES4   dw  0		; 1E-1F:  RESERVED (set to ZERO)
NVRAM_FLAG   dw  ?		; 20-21:  Flag (see @NVRAM_FLAG_ below)
NVRAM_START  dw  ?		; 22-23:  Starting NVRAM index
NVRAM_LEN    dw  ?		; 24-25:  Bytes to transfer

RB_NVRAM_STR ends

; Define a transfer buffer for read (08h) and write (09h) functions
NVRAM_XFERBUF equ [(size RB_NVRAM_STR)+10h].LO

@NVRAM_FLAG_NMIDIS equ 8000h	; NMI state on exit:  0 = enabled, 1 = disabled
@NVRAM_FLAG_EXT    equ 0001h	; RAM type:  0 = 64-byte RAM, 1 = Extended RAM

