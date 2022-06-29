;' $Header:   P:/PVCS/MAX/INC/8255.INV   1.0   05 Sep 1995 13:27:24   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; 8255.INC
;
; Equates for 8255/8042 Programmable Peripheral Interface (PPI)
;


.xcref @8255_A,@8255_B,@8255_C,@8255_CMD,@8042_ST
@8255_A  equ	 60h		; Read-only in PC Read/write in AT
@8255_B  equ	 61h		; Read/write
@8255_C  equ	 62h		; Read-only
@8255_CMD equ	 63h		; Command port
@8042_ST equ	 64h		; Status port
@PS2_A	 equ	 92h		; PS/2 System Control Port A


; Port B bit definitions
; $KEYB      <==>  1 = Read sense switches,	0 = Enable keyboard
; $XTPAR     <==> 11 = toggle parity off,      00 = toggle parity on
; $ATPAR     <==> 11 = toggle parity off,      00 = toggle parity on
; $SPKR      <==>  1 = Speaker data allowed
; $TIMER2    <==>  1 = TIMER 2 to speaker gate

.xcref @8255_B_REC
@8255_B_REC record $KEYB:1,$FILLB:1,$XTPAR:2,$ATPAR:2,$SPKR:1,$TIMER2:1

; Port B bit definitions for MC systems
; $CLRIRQ0   <==>  1 = W:  Reset IRQ0
; $PARITY    <==>  1 = R:  Channel check has occurred
; $TIMER2ST  <==>  1 = R:  Timer 2 state
; $REFRESH   <==>  1 = R:  Refresh toggle
; $ENAPAR2   <==>  1 = R/W:  Enable channel check
; $ENAPAR1   <==>  1 = R/W:  Enable parity  check
; $ENASPKR   <==>  1 = R/W:  Enable speaker data, 0 = disable ...
; $ENATIMER2 <==>  1 = R/W:  Enable timer 2 gate to speaker, 0 = disable ...

.xcref @8255_MC_REC
@8255_MC_REC record $CLRIRQ0:1,$PARITY:1,$TIMER2ST:1,$REFRESH:1, \
		    $ENAPAR2:1,$ENAPAR1:1,$ENASPKR:1,$ENATIMER2:1


; Port C bit definitions
; $MEMCHECK  <==> 1 = Memory parity check
; $IOCHECK   <==> 1 = I/O channel check
; $TIMER2OUT <==> 1 = Timer 2 output high, 0 = low

.xcref @8255_C_REC
@8255_C_REC record $MEMCHECK:1,$IOCHECK:1,$TIMER2OUT:1,$FILLC:5


; Command port definitions
; $OP	     <==> 0 = doing set/reset of bit in Port C
; $BITNO     <==> 000 = bit 0, etc.
; $BITSET    <==> 1 = set, 0 = reset

.xcref @8255_CMD_REC
@8255_CMD_REC record $OP:1,$FILLCMD:3,$BITNO:3,$BITSET:1


; Status port definitions for IN AL,@8042_ST
; $PAR	     <==> 80h 1 = Parity is even,	0 = Parity is odd
; $RCVTIM    <==> 40h 1 = Receive timeout	0 = OK
; $TRNTIM    <==> 20h 1 = Transmit timeout	0 = OK
; $KINH      <==> 10h 1 = Keyboard inhibited,	0 = OK
; $DATA      <==> 08h 1 = Data, 		0 = Command
; $SYSTST    <==> 04h 1 = Return from shutdown, 0 = POST
; $INPFULL   <==> 02h 1 = Input buffer full,	0 = OK
; $OUTFULL   <==> 01h 1 = Output buffer full,	0 = OK

.xcref @8042_ST_REC
@8042_ST_REC record $PAR:1,$RCVTIM:1,$TRNTIM:1,$KINH:1,$DATA:1,$SYSTST:1,$INPFULL:1,$OUTFULL:1


; 8042 command byte bit definitions
; $CMD_CPAT  <==> 40h 1 = IBM PC Compatibility	0 = not
; $CMD_PCM   <==> 20h 1 = IBM PC Mode		0 = not
; $CMD_DIS   <==> 10h 1 = Disable keyboard	0 = Enable keyboard
; $CMD_OVR   <==> 08h 1 = Override key lock	0 = Allow key lock
; $CMD_SYS   <==> 04h 1 = Return from shutdown	0 = POST
; $CMD_RSV   <==> 02h	  Reserved
; $CMD_OBFI  <==> 01h 1 = Enable out buf int	0 = Disable output buffer full interrupt

.xcref @8042_CMD
@8042_CMD record $CMD_CPAT:1,$CMD_PCM:1,$CMD_DIS:1,$CMD_OVR:1,$CMD_SYS:1,$CMD_RSV:1,$CMD_OBFI:1


; Status port commands for OUT @8042_ST,AL

.xcref @S2C_RCMD,@S2C_WCMD,@S2C_SELF,@S2C_ICHK,@S2C_DIAG
.xcref @S2C_AUXDIS,@S2C_AUXENA
.xcref @S2C_DIS,@S2C_ENA,@S2C_RINP,@S2C_ROUT,@S2C_WOUT
.xcref @S2C_TINP,@S2C_SHUT
@S2C_RCMD   equ  020h	; Read controller's command byte
@S2C_WCMD   equ  060h	; Write controller's command byte
@S2C_AUXDIS equ  0A7h	; Auxiliary device disable
@S2C_AUXENA equ  0A8h	; Auxiliary device enable
@S2C_SELF   equ  0AAh	; Self-test
@S2C_ICHK   equ  0ABh	; Interface check
@S2C_DIAG   equ  0ACh	; Diagnostic dump
@S2C_DIS    equ  0ADh	; Keyboard disable
@S2C_ENA    equ  0AEh	; Keyboard enable
@S2C_RINP   equ  0C0h	; Read	input  port
@S2C_ROUT   equ  0D0h	; Read	output port
@S2C_WOUT   equ  0D1h	; Write output port
@S2C_TINP   equ  0E0h	; Read test inputs
@S2C_PULSE  equ  0F0h	; Pulse three low-order output port bits
@S2C_SHUT   equ  0FEh	; Shutdown
@S2C_RESET  equ  0FFh	; Ensure in stable state

.xcref @C2S_SELF
@C2S_SELF   equ   55h	; Command to system response to self-test


; Output-port definitions for 8042
;
; $S2O_DATA   <==> 80h	1 = Keyboard data output high,	0 = low
; $S2O_CLOCK  <==> 40h	1 = Keyboard clock output high, 0 = low
; $S2O_IBFMT  <==> 20h	1 = Input buffer empty, 	0 = full
; $S2O_OBFUL  <==> 10h	1 = Output buffer full, 	0 = empty
;	      <==> 08h	    Undefined
;	      <==> 04h	    Undefined
; $S2O_GATE   <==> 02h	1 = Enable A20, 		0 = disable A20
; $S2O_RESET  <==> 01h	1 = Normal,			0 = system reset

.xcref @8042_OUT
@8042_OUT record $S2O_DATA:1,$S2O_CLOCK:1,$S2O_IBFMT:1,$S2O_OBFUL:1,$S2O_UNDEF:2,$S2O_GATE:1,$S2O_RESET:1

.xcref @S2O_D20,@S2O_E20
@S2O_D20    equ  0DDh	; Disable A20
@S2O_E20    equ  0DFh	; Enable A20


; System to 6805 keyboard commands as in OUT @8255_A,AL

.xcref @S2K_LED,@S2K_ECHO,@S2K_INV1,@S2K_SCAN,@S2K_INV2,@S2K_RID,@S2K_TYPE
.xcref @S2K_ENABLE,@S2K_DEFDI,@S2K_DEFEN,@S2K_SAKT,@S2K_SAKMB,@S2K_SAKM
.xcref @S2K_SAKTMB,@S2K_S1KT,@S2K_S1KMB,@S2K_S1KM,@S2K_RESEND,@S2K_RESET
@S2K_LED    equ  0EDh	; Set/reset LEDs
@S2K_ECHO   equ  0EEh	; Echo
@S2K_INV1   equ  0EFh	; Invalid command #1
@S2K_SCAN   equ  0F0h	; Select alternate scan codes
@S2K_INV2   equ  0F1h	; Invalid command #2
@S2K_RID    equ  0F2h	; Read ID (two bytes returned)
@S2K_TYPE   equ  0F3h	; Set typematic rate/delay
@S2K_ENABLE equ  0F4h	; Enable keyboard
@S2K_DEFDI  equ  0F5h	; Set default, disabled
@S2K_DEFEN  equ  0F6h	; Set default, enabled
@S2K_SAKT   equ  0F7h	; Set all keys - Typematic
@S2K_SAKMB  equ  0F8h	; Set all keys - Make/Break
@S2K_SAKM   equ  0F9h	; Set all keys - Make
@S2K_SAKTMB equ  0FAh	; Set all keys - Typematic/Make/Break
@S2K_S1KT   equ  0FBh	; Set one type - Typematic
@S2K_S1KMB  equ  0FCh	; Set one type - Make/Break
@S2K_S1KM   equ  0FDh	; Set one type - Make
@S2K_RESEND equ  0FEh	; Resend last output
@S2K_RESET  equ  0FFh	; Reset keyboard


; 8042 keyboard to system commands

.xcref @K2S_OVER23,@K2S_KID,@K2S_BATOK,@K2S_ECHO,@K2S_BREAK,@K2S_ACK
.xcref @K2S_BATER,@K2S_DIAGER,@K2S_RESEND,@K2S_OVER1
@K2S_OVER23 equ  000h	; Key detection error/overrun (Code sets #2 & 3)
@K2S_KID    equ 83ABh	; Keyboard ID
@K2S_BATOK  equ  0AAh	; BAT completion code
@K2S_ECHO   equ  0EEh	; Echo response
@K2S_BREAK  equ  0F0h	; Break code prefix
@K2S_ACK    equ  0FAh	; Last command acknowledged
@K2S_BATER  equ  0FCh	; BAT failure code
@K2S_DIAGER equ  0FDh	; Diagnostic failure
@K2S_RESEND equ  0FEh	; Resend last command
@K2S_OVER1  equ  0FFh	; Key detection error/overrun (Code set #1)


; PS/2 System Control Port A

.xcref PS2SCP_A
PS2SCP_A record  $PS2_FD0:1,$PS2_FD1:1,$PS2_RSV0:1,$PS2_WD:1,$PDS2_LOCK:1,$PS2_RSV1:1,$PS2_GATE:1,$PS2_RESET:1


