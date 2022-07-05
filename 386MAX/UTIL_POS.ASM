;' $Header:   P:/PVCS/MAX/386MAX/UTIL_POS.ASV   1.2   30 May 1997 10:46:38   BOB  $
	 title	 UTIL_POS -- 386MAX Utility -- Programmable Option Select Display
	 page	 58,122
	 name	 UTIL_POS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1990-7 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Data    segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, February, 1990.

Modifications by:  None.

|
.386
.xlist
	 include MASM.INC
	 include BITFLAGS.INC
	 include ASCII.INC
	 include EMM2CALL.INC

	 include QMAX_OEM.INC
	 include QMAX_POS.INC
.list

if @OEM_SYS eq @OEMSYS_RET
PGROUP	 group	 CODE,DATA,ZZTAIL


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

ZZTAIL	 segment use16 dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 extrn	 ZTAIL:byte

POSDATA  equ	 ZTAIL

ZZTAIL	 ends			; End ZZTAIL segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 public  MCAID
MCAID	 MCA_STR @MAXPOSDEV dup (<?>) ; MCA adapter IDs

	 public  POSBASE
POSBASE  dw	 ?		; POS base address

	 public  MSG_NOTMCA
ifdef LANG_GR
MSG_NOTMCA db	 BEL,'ÍÍ> Diese Programm l„uft nur auf Mikrokanal-PCs.',CR,LF,EOS
else
MSG_NOTMCA db	 BEL,'ÍÍ> This program runs on Micro Channel machines only.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_POSHEAD,MSG_POSLINE,MSG_POSTAIL
MSG_POSHEAD db	 'ÚÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄ¿',CR,LF
ifdef LANG_GR
	 db	 '³Slot-Nr.³ Adapter-ID ³  POS[0]  ³  POS[1]  ³  POS[2]  ³  POS[3]  ³ Sub Ad ³',CR,LF
else
	 db	 '³ Slot # ³ Adapter ID ³  POS[0]  ³  POS[1]  ³  POS[2]  ³  POS[3]  ³ Sub Ad ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÃÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄ´',CR,LF,EOS
;;;;;;;;;;;;;;;; '³   x    ³   xxxx     ³ xxxxxxxx ³ xxxxxxxx ³ xxxxxxxx ³ xxxxxxxx ³  xxxx  ³',CR,LF
MSG_POSLINE db	 '³   '
MSG_SLOT1 db	 'x    ³   '
MSG_AID  db	 'xxxx     ³ '
MSG_POS0 db	 'xxxxxxxx ³ '
MSG_POS1 db	 'xxxxxxxx ³ '
MSG_POS2 db	 'xxxxxxxx ³ '
MSG_POS3 db	 'xxxxxxxx ³  '
MSG_SUBA db	 'xxxx  ³',CR,LF,EOS
MSG_MT	 db	 '³   '
ifdef LANG_GR
MSG_SLOT2 db	 'x    ³ -keiner-   ³          ³          ³          ³          ³        ³',CR,LF,EOS
else
MSG_SLOT2 db	 'x    ³  -None-    ³          ³          ³          ³          ³        ³',CR,LF,EOS
endif				; IFDEF LANG_GR
MSG_POSTAIL db	 'ÀÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÙ',CR,LF,EOS

	 public  MSG_CMOS
MSG_CMOS db	 '³   '
	 db	 '     ³   '
	 db	 '     CMOS³ '
MSG_CPOS0 db	 'ABIOS    ³ '
ifdef LANG_GR
MSG_CPOS1 db	 'nicht    ³ '
MSG_CPOS2 db	 'unterst. ³ '
MSG_CPOS3 db	 '         ³  '
else
MSG_CPOS1 db	 'not      ³ '
MSG_CPOS2 db	 'supp.    ³ '
MSG_CPOS3 db	 '         ³  '
endif				; IFDEF LANG_GR
	  db	 '      ³',CR,LF,EOS

	 public  EMM2_RETURN
EMM2_RETURN db	 ?		; Return AH value from EMM2 POSCOPY call

DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 STROUT:near
	 extrn	 DW2HEX:near
	 extrn	 DB2BIT:near
	 extrn	 WINOUT:near

	 NPPROC  ACT_POS -- Programmable Option Select Display
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

; Ensure this is an MCA

	 call	 IZITMCA	; Izit an MCA?
	 jc	 short ACT_POS_EXIT ; Jump if not

; Read in the adapter IDs and POS values

	 call	 READID 	; Read 'em in

; Display the adapter IDs and POS values

	 call	 DISPID 	; Display 'em
ACT_POS_EXIT:
	 ret			; Return to DOS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_POS  endp			; End ACT_POS procedure
	 NPPROC  IZITMCA -- Izit an MCA
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Izit an MCA?

On exit:

CF	 =	 0 if it's an MCA
	 =	 1 otherwise

|

; Check for MCA-compatible machines

	 test	 LCL_FLAG,@LCL_MCA ; Izit MCA-compatible?
	 jnz	 short IZITMCA_EXIT ; Jump if so (note CF=0)

	 push	 dx		; Save for a moment

	 lea	 dx,MSG_NOTMCA	; Tell 'em the bad news
	 call	 STROUT 	; Display the string at DS:DX

	 pop	 dx		; Restore

	 stc			; Indicate not an MCA
IZITMCA_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITMCA  endp			; End IZITMCA procedure
	 NPPROC  READID -- Read System And Adapter IDs And POS Values
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read in system board and adapter IDs and POS values

|

	 REGSAVE <ax,bx,cx,dx,di> ; Save registers

	 mov	 ax,0C400h	; Get POS base address
	 int	 15h		; Request BIOS services

	 mov	 POSBASE,dx	; Save for later use

; Read in CMOS POS from 386MAX

	 lea	 di,POSDATA	; ES:DI ==> output save area
	 mov	 ah,@EMM2_POSCOPY ; Copy POS data
	 call	 WINOUT 	; Use Windows API or EMMOUT
	 mov	 EMM2_RETURN,ah ; Save return code

; Read in system board ID

	 mov	 cx,@MAXPOSDEV	; Get # slots
	 mov	 bl,0		; Start with slot #0
	 lea	 di,MCAID	; ES:DI ==> adapter ID save area
READID_NEXT:
	 cli			; Disallow interrupts

	 cmp	 bl,0		; Izit system board?
	 jne	 short READID_XSYS1 ; Jump if not

; Put system board into setup mode

	 in	 al,94h 	; Get current system board setup register
	 jmp	 short $+2	; I/O delay

	 and	 al,not @BIT7	; Clear enable bit
	 out	 94h,al 	; Put system board into setup mode
;;;;;;;; jmp	 short $+2	; I/O delay

	 jmp	 short READID_COM1 ; Join common code

; Put adapter into setup mode

READID_XSYS1:
	 mov	 al,bl		; Copy to I/O register
	 dec	 al		; Convert to origin-0
	 or	 al,@BIT3	; Select channel setup
	 out	 96h,al 	; Put into setup mode
	 jmp	 short $+2	; I/O delay

; Read adapter/system board ID

READID_COM1:
	 mov	 dx,POSBASE	; Adapter ID LSB register
	 in	 al,dx		; Get LSB of adapter ID
	 jmp	 short $+2	; I/O delay

	 mov	 ah,al		; Save for later use
	 inc	 dx		; Skip to adapter MSB register

	 in	 al,dx		; Get MSB of adapter ID
	 jmp	 short $+2	; I/O delay

	 xchg	 al,ah		; Swap to comparison order
	 stos	 MCAID.MCA_AID	; Save as adapter ID

; Read in the POS values

	 push	 cx		; Save outer count value

	 mov	 cx,4		; Get # POS values
@@:
	 inc	 dx		; Skip to POS[n]
	 in	 al,dx		; Get POS[n]
;;;;;;;; jmp	 short $+2	; I/O delay

	 stos	 MCAID.MCA_POS0 ; Save as POS[n] value

	 loop	 @B		; Jump if more POS values to read

	 pop	 cx		; Restore

; Read in subaddress extension

	 inc	 dx		; Skip to subaddress extension low-byte
	 in	 al,dx		; Get the value
	 jmp	 short $+2	; I/O delay

	 mov	 ah,al		; Save for later use
	 inc	 dx		; Skip to subaddress extension high-byte
	 in	 al,dx		; Get the value
	 jmp	 short $+2	; I/O delay

	 xchg	 al,ah		; Swap to comparison order
	 stos	 MCAID.MCA_SUBA ; Save as subaddress extension

	 cmp	 bl,0		; Izit system board?
	 jne	 short READID_XSYS2 ; Jump if not

; Put system board into enable mode

	 in	 al,94h 	; Get current system board setup register
	 jmp	 short $+2	; I/O delay

	 or	 al,@BIT7	; Set enable bit
	 out	 94h,al 	; Put system board into setup mode
;;;;;;;; jmp	 short $+2	; I/O delay

	 jmp	 short READID_COM2 ; Join common code

; Put adapter into enable mode

READID_XSYS2:
	 mov	 al,0		; Disable channel setup
	 out	 96h,al 	; No position selected
;;;;;;;; jmp	 short $+2	; I/O delay
READID_COM2:
	 sti			; Allow interrupts

	 inc	 bl		; Skip to next slot #

	 loop	 READID_NEXT	; Jump if more adapters to check

	 REGREST <di,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READID	 endp			; End READID procedure
	 NPPROC  DISPID -- Display Adapter IDs and POS Values
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display adapter IDs and POS values

|

	 REGSAVE <ax,bx,cx,dx,si,di,bp> ; Save registers

	 lea	 dx,MSG_POSHEAD ; Display the header
	 call	 STROUT 	; Display the string at DS:DX

; Loop through adpaters

	 mov	 cx,@MAXPOSDEV	; Get # slots
	 xor	 si,si		; Initialize index into MCAID
	 xor	 bp,bp		; Initialize index into POSDATA
	 xor	 bl,bl		; Initialize slot #
DISPID_NEXT:
	 cmp	 bl,0		; Izit system board?
	 jne	 short DISPID_XSYS ; Jump if not

	 mov	 MSG_SLOT1[-1],'S' ; Save marker for system board
	 mov	 MSG_SLOT1[ 0],'y'
	 mov	 MSG_SLOT1[+1],'s'

	 jmp	 short DISPID_COM ; Join common code

DISPID_XSYS:
	 mov	 al,bl		; Get slot #
	 add	 al,'0'         ; Convert to ASCII
	 mov	 MSG_SLOT1,al	; Save in message
	 mov	 MSG_SLOT2,al	; Save in message
	 mov	 MSG_SLOT1[-1],' ' ; Clear system board marker
	 mov	 MSG_SLOT1[+1],' '

	 mov	 MSG_AID[5],'A' ; Set 'Adap' text
	 mov	 MSG_AID[6],'d'
	 mov	 MSG_AID[7],'a'
	 mov	 MSG_AID[8],'p'
DISPID_COM:
	 mov	 ax,MCAID.MCA_AID[si] ; Get the adapter ID

	 cmp	 ax,-1		; Izit in empty?
	 je	 near ptr DISPID_MT ; Jump if so

	 lea	 di,MSG_AID	; ES:DI ==> output save area
	 call	 DW2HEX 	; Display AX in hex starting at ES:DI

; Format and display the POS data from the adapter

	 mov	 al,MCAID.MCA_POS0[si] ; Get POS[0] value
	 lea	 di,MSG_POS0	; ES:DI ==> output save area
	 call	 DB2BIT 	; Display AL in bits starting at ES:DI

; Display a marker if the adapter is not enabled

	 shr	 al,1		; Test adapter enable bit
	 mov	 al,' '         ; Assume enabled
	 jc	 short @F	; Jump if enabled
	 mov	 al,'*'         ; Marker for not enabled
@@:
	 stosb			; Save in output save area

	 mov	 al,MCAID.MCA_POS1[si] ; Get POS[1] value
	 lea	 di,MSG_POS1	; ES:DI ==> output save area
	 call	 DB2BIT 	; Display AL in bits starting at ES:DI

	 mov	 al,MCAID.MCA_POS2[si] ; Get POS[2] value
	 lea	 di,MSG_POS2	; ES:DI ==> output save area
	 call	 DB2BIT 	; Display AL in bits starting at ES:DI

	 mov	 al,MCAID.MCA_POS3[si] ; Get POS[3] value
	 lea	 di,MSG_POS3	; ES:DI ==> output save area
	 call	 DB2BIT 	; Display AL in bits starting at ES:DI

	 mov	 ax,MCAID.MCA_SUBA[si] ; Get subaddress extension value
	 lea	 di,MSG_SUBA	; ES:DI ==> output save area
	 call	 DW2HEX 	; Display AX in hex starting at ES:DI

	 lea	 dx,MSG_POSLINE ; Display the line
	 call	 STROUT 	; Display the string at DS:DX

; Format and display the POS data from the CMOS

	 cmp	 EMM2_RETURN,0	; Did EMM2_POSCOPY return an error?
	 jne	 short DISPID_STROUT ; Use default formatting if so

	 cmp	 bl,0		; Izit system board?
	 jne	 short @F	; Jump if not

	 mov	 bp,8*(size POSD_STR) ; Skip to system board CMOS POS
@@:
	 mov	 al,POSDATA.POSD_CMOS[bp+0] ; Get POS[0] value
	 lea	 di,MSG_CPOS0	; ES:DI ==> output save area
	 call	 DB2BIT 	; Display AL in bits starting at ES:DI

; Display a marker if the adapter is not enabled

	 shr	 al,1		; Test adapter enable bit
	 mov	 al,' '         ; Assume enabled
	 jc	 short @F	; Jump if enabled
	 mov	 al,'*'         ; Marker for not enabled
@@:
	 stosb			; Save in output save area

	 mov	 al,POSDATA.POSD_CMOS[bp+1] ; Get POS[1] value
	 lea	 di,MSG_CPOS1	; ES:DI ==> output save area
	 call	 DB2BIT 	; Display AL in bits starting at ES:DI

	 mov	 al,POSDATA.POSD_CMOS[bp+2] ; Get POS[2] value
	 lea	 di,MSG_CPOS2	; ES:DI ==> output save area
	 call	 DB2BIT 	; Display AL in bits starting at ES:DI

	 mov	 al,POSDATA.POSD_CMOS[bp+3] ; Get POS[3] value
	 lea	 di,MSG_CPOS3	; ES:DI ==> output save area
	 call	 DB2BIT 	; Display AL in bits starting at ES:DI

DISPID_STROUT:
	 lea	 dx,MSG_CMOS	; Display the line
	 call	 STROUT 	; Display the string at DS:DX

	 jmp	 short DISPID_LOOP ; Join common loop code

DISPID_MT:
	 lea	 dx,MSG_MT	; Display empty slot line
	 call	 STROUT 	; Display the string at DS:DX
DISPID_LOOP:
	 or	 bl,bl		; Izit the system board?
	 jnz	 short @F	; Jump if not

	 sub	 bp,bp		; Restart at beginning of CMOS POS data
	 jmp	 short DISPID_LOOP1 ; Join common code
@@:
	 add	 bp,size POSD_STR ; Skip to next slot
DISPID_LOOP1:
	 inc	 bl		; Skip to next slot #
	 add	 si,size MCA_STR ; Skip to next slot

;;;;;;;; loop	 DISPID_NEXT	; Jump if more slots
	 dec	 cx		; One fewer slot
	 jne	 near ptr DISPID_NEXT ; Jump if more slots

	 lea	 dx,MSG_POSTAIL ; Display the tail
	 call	 STROUT 	; Display the string at DS:DX

	 REGREST <bp,di,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPID	 endp			; End DISPID procedure

CODE	 ends			; End CODE segment
endif				; IF @OEM_SYS eq @OEMSYS_RET

	 MEND			; End UTIL_POS module
