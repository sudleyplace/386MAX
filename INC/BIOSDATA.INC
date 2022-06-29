;' $Header:   P:/PVCS/MAX/INC/BIOSDATA.INV   1.0   05 Sep 1995 13:27:22   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; BIOSDATA.INC
;
; BIOS Data Area segment and others
;

.xcref BIOSDATA,RS232_BASE,PRINTER_BASE,EQUIP_FLAG,MFG_TST,MEMORY_SIZE
.xcref MFG_ERR_FLAG,KB_FLAG,KB_FLAG_1,ALT_INPUT,BUFFER_HEAD,BUFFER_TAIL
.xcref KB_BUFFER,KB_BUFFER_END,SEEK_STATUS,MOTOR_STATUS,MOTOR_COUNT
.xcref EGA_ROWS,EGA_PNTS,EGA_INFO,EGA_INF3,EGA_RSVD
.xcref DISKETTE_STATUS,CMD_BLOCK,HD_ERROR,NEC_STATUS,CRT_MODE,CRT_COLS
.xcref CRT_LEN,CRT_START,CURSOR_POSN,CURSOR_MODE,ACTIVE_PAGE,ADDR_6845
.xcref CRT_MODE_SET,CRT_PALLETTE,IO_ROM_INIT,IO_ROM_SEG,INTR_FLAG
.xcref TIMER_LOW,TIMER_HIGH,TIMER_OFL,BIOS_BREAK,RESET_FLAG,DISK_STATUS1
.xcref HF_NUM,CONTROL_BYTE,PORT_OFF,PRINT_TIM_OUT,VDS,RS232_TIM_OUT
.xcref BUFFER_START,BUFFER_END,LASTRATE,HF_STATUS,HF_ERROR,HF_INT_FLAG
.xcref HF_CNTRL,DSK_STATE,DSK_TRK,KB_FLAG_3,KB_FLAG_2,USER_FLAG,USER_FLAG_SEG
.xcref SAVE_PTR,RTC_LOW,RTC_HIGH,RTC_WAIT_FLAG,INTRA_APP

if (@Cpu and 1000b)		; If 80386 instructions
BIOSDATA segment use16 at 40h	; Start BIOSDATA segment
else
BIOSDATA segment at 40h 	; Start BIOSDATA segment
endif				; IF (@Cpu AND 1000b)

RS232_BASE dw	 4 dup (?)	; Addresses of RS232 adapters		      00
PRINTER_BASE dw  3 dup (?)	; Address of printers			      08
XBDA_SEG dw	 ?		; Segment of XBIOS data area		      0E
EQUIP_FLAG dw	 ?		; Installed hardware			      10
MFG_TST  db	 ?		; Initialization flag			      12
MEMORY_SIZE dw	 ?		; Memory size in K bytes		      13
MFG_ERR_FLAG db  ?		; Scratchpad for manufacturing		      15
	 db	 ?		; Error codes				      16

; Keyboard data areas

.xcref KBREC,$KB_INS,$KB_CAPL,$KB_NUML,$KB_SCRL
.xcref	     $KB_ALT,$KB_CTL,$KB_LSHFT,$KB_RSHFT
KBREC	 record  $KB_INS:1,$KB_CAPL:1,$KB_NUML:1, $KB_SCRL:1, \
		 $KB_ALT:1,$KB_CTL:1, $KB_LSHFT:1,$KB_RSHFT:1
KB_FLAG  KBREC	 <>		; Keyboard status			      17

.xcref KB1REC,$KB1_INS,$KB1_CAPS,$KB1_NUM,$KB1_SCRL
.xcref	      $KB1_HOLD,$KB1_SYS,$KB1_LALT,$KB1_LCTL
KB1REC	 record  $KB1_INS:1, $KB1_CAPS:1,$KB1_NUM:1, $KB1_SCRL:1, \
		 $KB1_HOLD:1,$KB1_SYS:1, $KB1_LALT:1,$KB1_LCTL:1
KB_FLAG_1 KB1REC <>		; Second byte of keyboard status	      18

ALT_INPUT db	 ?		; Storage for alternate keypad entry	      19
BUFFER_HEAD dw	 ?		; Pointer to head of keyboard buffer	      1A
BUFFER_TAIL dw	 ?		; Pointer to tail of keyboard buffer	      1C
KB_BUFFER dw	 16 dup (?)	; Room for 15 entries			      1E
KB_BUFFER_END label word	;					      3E

; Diskette data areas

SEEK_STATUS db	 ?		; Drive recalibration status		      3E
				; Bit 3-0 = drive 3-0 needs recalibration
				;   before next seek if bit is 0
MOTOR_STATUS db  ?		;					      3F
				; Bits 3-0 = drive 3-0 is currently running
				; Bit 7 = current operation is a write,
				;   & requires a delay
MOTOR_COUNT db	 ?		; Time out counter for drive turnoff	      40
DISKETTE_STATUS db ?		; Return code status byte		      41
CMD_BLOCK label  byte		;					      42
HD_ERROR  label  byte		;					      42
NEC_STATUS db	 7 dup (?)	; Status bytes from NEC 		      42

; Video display data areas

CRT_MODE db	 ?		; Current CRT mode			      49
CRT_COLS dw	 ?		; # columns on screen			      4A
CRT_LEN  dw	 ?		; Length of regen in bytes		      4C
CRT_START dw	 ?		; Starting address in regen buffer	      4E
CURSOR_POSN dw	 8 dup (?)	; Cursor for each of up to 8 pages	      50
CURSOR_MODE dw	 ?		; Current cursor mode setting		      60
ACTIVE_PAGE db	 ?		; Current page being displayed		      62
ADDR_6845 dw	 ?		; Base address for active display card	      63
CRT_MODE_SET db  ?		; Current setting of the 3x8 register	      65
CRT_PALLETTE db  ?		; Current pallette setting for color card     66

; POST data area

IO_ROM_INIT dw	 ?		; Pointer to optional I/O ROM init routine    67
IO_ROM_SEG dw	 ?		; Pointer to I/O ROM segment		      69
INTR_FLAG db	 ?		; Flag to indicate an interrupt happened      6B

; Timer data area

TIMER_LOW dw	 ?		; Low word of timer count		      6C
TIMER_HIGH dw	 ?		; High word of timer count		      6E
TIMER_OFL db	 ?		; Timer has rolled over since last read       70

; System data area

BIOS_BREAK db	 ?		; Bit 7 = 1 if break key has been hit	      71
RESET_FLAG dw	 ?		; Word=1234h if keyboard reset underway       72

; Hard file data areas

DISK_STATUS1 db  ?		;					      74
HF_NUM	 db	 ?		; # hard files				      75
CONTROL_BYTE db  ?		;					      76
PORT_OFF db	 ?		;					      77

; Printer and RS232 time-out values

PRINT_TIM_OUT db 4 dup (?)	;					      78
VDS	 equ	 PRINT_TIM_OUT[3] ;					      7B
RS232_TIM_OUT db 4 dup (?)	;					      7C

; Additional keyboard data area

BUFFER_START dw  ?		;					      80
BUFFER_END dw	 ?		;					      82

; EGA values

EGA_ROWS db	 ?		; # screen rows 			      84
EGA_PNTS dw	 ?		; # bytes per character 		      85
EGA_INFO db	 ?		; Information byte			      87
EGA_INF3 db	 ?		; Information byte 3?			      88
EGA_RSVD dw	 ?		; Reserved				      89

; Additional floppy data

LASTRATE db	 ?		; Last data rate selected		      8B

; Additional hard file data

HF_STATUS db	 ?		; Status register			      8C
HF_ERROR db	 ?		; Error register			      8D
HF_INT_FLAG db	 ?		; Hard file interrupt flag		      8E
HF_CNTRL db	 ?		; Combo hard file/floppy car bit 0=1	      8F

; Additional diskette area

DSK_STATE label  byte
	 db	 ?		; Drive 0 media state			      90
	 db	 ?		; Drive 1 media state			      91
	 db	 ?		; Drive 0 operation start byte		      92
	 db	 ?		; Drive 1 operation start byte		      93
DSK_TRK  db	 ?		; Drive 0 present cylinder		      94
	 db	 ?		; Drive 1 present cylinder		      95

; Additional keyboard LED flags

.xcref KB3REC,$KB3_RID,$KB3_ID1,$KB3_NUML,$KB3_ENH
.xcref	      $KB3_RALT,$KB3_RCTL,$KB3_E0,$KB3_E1
KB3REC	 record  $KB3_RID:1, $KB3_ID1:1, $KB3_NUML:1,$KB3_ENH:1, \
		 $KB3_RALT:1,$KB3_RCTL:1,$KB3_E0:1  ,$KB3_E1:1
.xcref @KBX
@KBX	 equ	 <mask $KB3_ENH> ; Flag for enhanced keyboard
KB_FLAG_3 KB3REC <>		;					      96

.xcref KB2REC,$KB2_ERR,$KB2_UPD,$KB2_RESEND,$KB2_ACK
.xcref	      $KB2_RSVD,$KB2_LED
KB2REC	 record  $KB2_ERR:1,$KB2_UPD:1,$KB2_RESEND:1,$KB2_ACK:1, \
		 $KB2_RSVD:1,$KB2_LED:3
KB_FLAG_2 KB2REC <>		;					      97

; Real time clock data area

USER_FLAG dw	 ?		; Offset addr of user's wait flag             98
USER_FLAG_SEG dw ?		; Segment of ...			      9A
RTC_LOW  dw	 ?		; Low word of user wait flag		      9C
RTC_HIGH dw	 ?		; High word of ...			      9E
RTC_WAIT_FLAG db ?		; Wait active flag			      A0

	 org	 0A8h
SAVE_PTR dd	 ?		; EGA data pointer			      A8

	 org	 0B0h
ALR_KEYB db	 ?		; ALR keyboard wait count (Def = 0Dh)	      B0
	 org	 0B0h
DELL_KEYB dw	 ?		; DELL keyboard wait count (varies according  B0
				; to BIOS shadowing and model)

; Intra-application communication area for any application

	 org	 0F0h
INTRA_APP db	 16 dup (?)	;					      F0

BIOSDATA ends			; End BIOSDATA segment


; EGA Save Pointer

.xcref EGASAVE_STR
EGASAVE_STR struc

EGASAVE_VPT dd	 ?		; Ptr to video parameter table
EGASAVE_DYN dd	 ?		; Ptr to dynamic save area
EGASAVE_ALP dd	 ?		; Ptr to alpha mode char gen
EGASAVE_GRX dd	 ?		; ...	 graphics ...
EGASAVE_2ND dd	 ?		; Ptr to VGA secondary save area
EGASAVE_RES1 dd  ?		; Reserved ptr
EGASAVE_RES2 dd  ?		; Reserved ptr

EGASAVE_STR ends

; VGA Secondary Save Pointer

.xcref VGASAVE_STR
VGASAVE_STR struc

VGASAVE_LEN dw	 ?		; Length of table in bytes incl this word
VGASAVE_DCC dd	 ?		; Ptr to display combination code table
VGASAVE_ALP dd	 ?		; Ptr to second alpha mode char gen
VGASAVE_PAL dd	 ?		; Ptr to user pallette profile table
	 dd	 3 dup (?)	; Reserved

VGASAVE_STR ends

.xcref XXBIOSDATA,STATUS_BYTE,SINGLE_DRIVE_MODE

if (@Cpu and 1000b)		; If 80386 instructions
XXBIOSDATA segment use16 at 50h
else
XXBIOSDATA segment at 50h
endif				; IF (@Cpu AND 1000b)

STATUS_BYTE db	 ?		; Print screen status flag
				; 0 = print screen not active or it
				;     was successful
				; 1 = in progress
				;-1 = error encountered during print screen

	 db	 3 dup (?)	; Reserved
SINGLE_DRIVE_MODE db ?		; Single drive mode status byte

XXBIOSDATA ends 		; End XXBIOSDATA segment

