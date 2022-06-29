;' $Header:   P:/PVCS/MAX/386MAX/QMAX_CPQ.ASV   1.2   30 May 1997 10:44:12   BOB  $
	 title	 QMAX_CPQ -- 386MAX COMPAQ ROM Compressing Functions
	 page	 58,122
	 name	 QMAX_CPQ

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment EDATA,	dword-aligned, public, class 'edata'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Group XGROUP:
	       Program segment XCODE,	byte-aligned,  public, class 'xcode'
	       Data    segment XDATA,	dword-aligned, public, class 'xdata'
	       Group YGROUP:
	       Data    segment YDATA,	dword-aligned, public, class 'ydata'

Program derived from:  None.

Original code by:  Bob Smith, September, 1989.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include 386.INC
	 include PTR.INC
	 include CPUID.INC
	 include INTVEC.INC
	 include CPUFLAGS.INC
	 include BITFLAGS.INC
	 include BIOSDATA.INC
	 include IOPBITS.INC
	 include OPCODES.INC
	 include VDS.INC

	 include QMAX_OEM.INC
.list

PGROUP	 group	 CODE,EDATA,NDATA
XGROUP	 group	 XCODE,XDATA
YGROUP	 group	 YDATA
CGROUP	 group	 CPUID_SEG


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 DB2_FLAG:dword
	 include QMAX_DB2.INC

	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC

	 extrn	 SYSROM_START:word

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

	 extrn	 CPQMIO_LO:dword
	 extrn	 CON1MB:dword

EDATA	 ends			; End EDATA segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 NRD_FLAG:dword
	 include QMAX_NRD.INC

	 extrn	 TOP_MIO:word
	 extrn	 MEM_MAP:byte
	 extrn	 @XLAT_OVR:abs
	 extrn	 @XLAT_ROM0:abs
	 extrn	 @XLAT_ROM1:abs
	 extrn	 @XLAT_ROM2:abs

NDATA	 ends			; End EDATA segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

	 public  CPQINT01_VEC,CPQINT29_VEC
CPQINT01_VEC dd  ?		; Save area for original INT 01h handler
CPQINT29_VEC dd  ?		; ...			     29h ...

	 public  OLDINTHW_VEC
OLDINTHW_VEC dd  ?		; Save area for original hardware interrupt handler

	 public  CPQINT01_LAST,CPQINT01_TRIP,CPQINT01_SAVE
CPQINT01_LAST dd ?		; Last used address
CPQINT01_TRIP dd ?		; Tripping address
CPQINT01_SAVE dd 0		; Saved address

	 public  CURIDTR_VEC,CURIDTR
CURIDTR_VEC dd	 ?		; Seg:off of the current IDTR
CURIDTR  df	 ?		; Current IDTR

	 public  ROMADDR,ROMIDN
ROMADDR  dw	 ?		; Lowest expected ROM address
ROMIDN	 dw	 ?		; Highest multiple of 4KB of identical ROM parts

	 public  TRIP_CS,TRIP_DS,TRIP_ES,TRIP_SS
TRIP_CS  equ	 CPQINT01_TRIP.VSEG ; Tripping address's segment registers
TRIP_DS  dw	 ?
TRIP_ES  dw	 ?
TRIP_SS  dw	 ?

	 public  TRIP_BX,TRIP_BP,TRIP_SI,TRIP_DI
TRIP_BX  dw	 ?		; Tripping address's base and index registers
TRIP_BP  dw	 ?
TRIP_SI  dw	 ?
TRIP_DI  dw	 ?

	 public  FINDHW_ACT
FINDHW_ACT dw	 ?		; Action if tripping address found

	 public  PRMACT
PRMACT	 dw	 XGROUP:RM000	; R/M = 000 = [BX+SI]
	 dw	 XGROUP:RM001	; R/M = 001 = [BX+DI]
	 dw	 XGROUP:RM010	; R/M = 010 = [BP+SI]
	 dw	 XGROUP:RM011	; R/M = 011 = [BP+DI]
	 dw	 XGROUP:RM100	; R/M = 100 = [SI]
	 dw	 XGROUP:RM101	; R/M = 101 = [DI]
	 dw	 XGROUP:RM110	; R/M = 110 = [BP]
	 dw	 XGROUP:RM111	; R/M = 111 = [BX]

	 public  IGNCNT
IGNCNT	 dw	 0		; Failed ignore count

	 public  CPQ_FLAG
	 include QMAX_CPQ.INC
CPQ_FLAG CPQ_REC <>		; Local CPQ flags


CPQINT_STR struc

CPQINT_NUM dw	 ?		; Interrupt #
CPQINT_FIND dd	 ?		; Action routine to find it

CPQINT_STR ends

	 public  CPQINTS
	 align	 2
CPQINTS  label	 tbyte
		 ;   00h		     Divide overflow
		 ;   01h		     Single-step
	 CPQINT_STR <02h,XGROUP:FINDIGN>   ; NMI
		 ;   03h		     Breakpoint
	 CPQINT_STR <04h,XGROUP:FINDCHK>   ; Overflow
	 CPQINT_STR <05h,XGROUP:FINDIGN>   ; Print screen/BOUND
	 CPQINT_STR <06h,XGROUP:FINDCHK>   ; Invalid opcode
	 CPQINT_STR <07h,XGROUP:FINDERR>   ; Reserved
	 CPQINT_STR <08h,XGROUP:FINDCHK>   ; IRQ0:  Timer tick
	 CPQINT_STR <09h,XGROUP:FINDCHK>   ; IRQ1:  Keyboard
	 CPQINT_STR <0Ah,XGROUP:FINDCHK>   ; IRQ2:  Miscellaneous
	 CPQINT_STR <0Bh,XGROUP:FINDCHK>   ; IRQ3:  COM2
	 CPQINT_STR <0Ch,XGROUP:FINDCHK>   ; IRQ4:  COM1
	 CPQINT_STR <0Dh,XGROUP:FINDCHK>   ; IRQ5:  LPT2
	 CPQINT_STR <0Eh,XGROUP:FINDCHK>   ; IRQ6:  Diskette
	 CPQINT_STR <0Fh,XGROUP:FINDCHK>   ; IRQ7:  Printer
		 ;   10h		     Video services
	 CPQINT_STR <11h,XGROUP:FINDCHK>   ; Get equipment flags
	 CPQINT_STR <12h,XGROUP:FINDCHK>   ; Get memory size
	 CPQINT_STR <13h,XGROUP:FIND13>    ; Disk/Diskette services
	 CPQINT_STR <14h,XGROUP:FIND14>    ; COM services
	 CPQINT_STR <15h,XGROUP:FIND15>    ; BIOS services
	 CPQINT_STR <16h,XGROUP:FIND16>    ; Keyboard services
	 CPQINT_STR <17h,XGROUP:FIND17>    ; Printer services
		 ;   18h		     BASIC services
		 ;   19h		     Warm boot
	 CPQINT_STR <1Ah,XGROUP:FIND1A>    ; Timer services
	 CPQINT_STR <1Bh,XGROUP:FIND1B>    ; Control-break
	 CPQINT_STR <1Ch,XGROUP:FINDCHK>   ; Timer tick
	 CPQINT_STR <1Dh,XGROUP:FINDIGN>   ; Video parameter table
		 ;   1Eh		     Diskette parameter table
	 CPQINT_STR <1Fh,XGROUP:FINDIGN>   ; Graphic characters table
		 ;   20h-3Fh		     DOS services
	 CPQINT_STR <40h,XGROUP:FIND40>    ; Diskette services
	 CPQINT_STR <41h,XGROUP:FINDIGN>   ; HD #0 parameter table
	 CPQINT_STR <42h,XGROUP:FINDIGN>   ; EGA revectored INT 10h
	 CPQINT_STR <43h,XGROUP:FINDIGN>   ; EGA first 128 characters
	 CPQINT_STR <44h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <45h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <46h,XGROUP:FINDIGN>   ; HD #1 parameter table
	 CPQINT_STR <47h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <48h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <49h,XGROUP:FINDVERIFY>; Reserved
	 CPQINT_STR <4Ah,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <4Bh,XGROUP:FIND4B>    ; VDS services
	 CPQINT_STR <4Ch,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <4Dh,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <4Eh,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <4Fh,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <50h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <51h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <52h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <53h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <54h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <55h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <56h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <57h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <58h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <59h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <5Ah,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <5Bh,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <5Ch,XGROUP:FIND5C>    ; NETBIOS
	 CPQINT_STR <5Dh,XGROUP:FINDIGN>   ; Reserved (used by Core controller)
	 CPQINT_STR <5Eh,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <5Fh,XGROUP:FINDCHK>   ; Reserved
		 ;   60h-67h		     User-available interrupts
	 CPQINT_STR <68h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <69h,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <6Ah,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <6Bh,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <6Ch,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <6Dh,XGROUP:FINDIGN>   ; Secondary VGA interrupt
	 CPQINT_STR <6Eh,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <6Fh,XGROUP:FINDCHK>   ; Reserved
	 CPQINT_STR <70h,XGROUP:FINDCHK>   ; IRQ08:  Real-time clock
	 CPQINT_STR <71h,XGROUP:FINDCHK>   ; IRQ09:  Redirect to IRQ2
	 CPQINT_STR <72h,XGROUP:FINDCHK>   ; IRQ10:  Reserved
	 CPQINT_STR <73h,XGROUP:FINDCHK>   ; IRQ11:  Reserved
	 CPQINT_STR <74h,XGROUP:FINDCHK>   ; IRQ12:  Auxiliary device
	 CPQINT_STR <75h,XGROUP:FINDCHK>   ; IRQ13:  80287
	 CPQINT_STR <76h,XGROUP:FINDCHK>   ; IRQ14:  HD controller
	 CPQINT_STR <77h,XGROUP:FINDCHK>   ; IRQ15:  Reserved
NCPQINTS equ	 ($-CPQINTS)/(type CPQINT_STR) ; # interrupts

	 public  OLDCPQSTK_VEC
OLDCPQSTK_VEC dd ?		; Caller's SS:SP

	 public  PNETB_CCB,NETB_CCB
PNETB_CCB dd	 XGROUP:NETB_CCB ; Ptr to NETBIOS CCB
NETB_CCB db	 0,21h,-1,-1,8 dup (0) ; NETBIOS status call Command Control Block
	 dd	 XGROUP:STATBLK ; Ptr to status block

	 public  STATBLK
STATBLK  db	 50 dup (?)	; Status block output save area

	 public  CPQSTK,CPQSTKZ
CPQSTK	 dw	 1024 dup ('??') ; Local stack
CPQSTKZ  label	 word

XDATA	 ends			; End XDATA segment


YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
	 assume  ds:YGROUP

if @OEM_DEBUG
	 extrn	 MSG_ERRCPQ:byte
	 extrn	 MSG_ERRCPQ1:byte
endif				; IF @OEM_DEBUG

YDATA	 ends			; End YDATA segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 extrn	 FMT_ERR_CODE:far
	 extrn	 INST_TMPINT15:near
	 extrn	 TOP_WRITE:near
	 extrn	 REST_TMPINT15:near
	 extrn	 YMSGOUT2:near
	 extrn	 ROM2OVR:near

	 public  @QMAX_CPQ_XCODE
@QMAX_CPQ_XCODE:		; Mark module start in .MAP file

	 NPPROC  COMPROM -- Compress COMPAQ System ROM
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Attempt to compress the COMPAQ system ROM from 64KB to 32KB.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers
	 REGSAVE <ds,es>	; Save segment registers

	 test	 I15_FLAG,@I15_CPQ ; Izit a COMPAQ TOP384 scheme?
	 jz	 short @F	; Jump if not

; Tell the system to decode the upper 128KB as high-only RAM

	 call	 INST_TMPINT15	; Install temporary INT 15h handler

	 mov	 TOP_MIO,@CPQ_HRAM ; Mark as read-write, high-only
	 lea	 si,CPQMIO_LO	; DS:SI ==> 32-bit destination address
	 call	 TOP_WRITE	; Write value in TOP_MIO to CPQ I/O port
@@:

; Compare the two BIOS parts

	 push	 seg CGROUP	; Get the segment #
	 pop	 es		; Address it
	 assume  es:CGROUP	; Tell the assembler about it

	 xor	 si,si		; ES:SI ==> bottom half
	 mov	 di,8000h	; ES:DI ==> top half
	 mov	 cx,32*1024	; # bytes in 32KB
    repe cmps	 CGROUP:[si].LO,CGROUP:[di].LO ; Compare 'em

	 pushf			; Save flags

	 test	 I15_FLAG,@I15_CPQ ; Izit a COMPAQ TOP384 scheme?
	 jz	 short @F	; Jump if not

; Tell the system to decode the upper 128KB as high/low ROM

	 push	 si		; Save for a moment
	 mov	 TOP_MIO,@CPQ_HLROM ; Mark as read-only, high/low
	 lea	 si,CPQMIO_LO	; DS:SI ==> 32-bit destination address
	 call	 TOP_WRITE	; Write value in TOP_MIO to CPQ I/O port
	 pop	 si		; Restore

	 call	 REST_TMPINT15	; Restore original INT 15h handler
@@:
	 popf			; Restore
	 je	 short @F	; Jump if all match

	 dec	 si		; Back off to first mismatch
@@:
	 and	 si,not (4*1024-1) ; Round down to 4KB boundary
	 stc			; Assume error
	 jz	 near ptr COMPROM_ERR1 ; Jump if nothing recoverable

; Up to ROMIDN, the two halves are identical

	 push	 seg XGROUP	; Get the segment
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 mov	 ROMIDN,si	; Save for later use

; Set address of action routine if found

	 mov	 FINDHW_ACT,offset XGROUP:FINDHW_CPQ ; Save it
	 mov	 ROMADDR,0F000h ; Set lowest expected ROM address

; Save old INT 01h handler to restore later

	 call	 SAVEINT01	; Save current INT 01h handler

; Save old and install new INT 29h handler so we don't display
; ^C when the INT 1Bh is called.

	 mov	 al,29h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old INT 29h handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 CPQINT29_VEC.VOFF,bx ; Save to restore later
	 mov	 CPQINT29_VEC.VSEG,es

	 mov	 al,29h 	; Intercept this one
	 DOSCALL @SETINT,CPQINT29 ; Install our own one

; Loop through all selected interrupt vectors, redirecting into
; the second half all of those which point into the first half.

	 mov	 cx,NCPQINTS	; Get # interrupt vectors
	 jcxz	 COMPROM_DONE	; Jump if no interrupts
	 xor	 si,si		; Initialize index into table

	 push	 seg INTVEC	; Get the segment #
	 pop	 es		; Address it
	 assume  es:INTVEC	; Tell the assembler about it
COMPROM_NEXTINT:

; See if it already points to F000

	 mov	 bx,CPQINTS.CPQINT_NUM[si] ; Get the interrupt #
	 shl	 bx,2-0 	; Times four to index table of dwords

	 mov	 ax,INT00_VEC.VSEG[bx] ; Get the segment from segment 0

	 and	 ax,ax		; Izit valid?
	 jz	 short COMPROM_LOOPINT ; Jump if not

	 cmp	 INT00_VEC.VSEG[bx],0F000h ; Izit in BIOS?
	 jne	 short COMPROM_XBIOS ; Jump if not

	 mov	 ax,ROMIDN	; Get highest multiple of 4KB of identical ROM parts

	 cmp	 ax,INT00_VEC.VOFF[bx] ; Izit within identical ROM parts?
	 jbe	 short @F	; Jump if not

	 or	 INT00_VEC.VOFF[bx],8000h ; Point into the 2nd half
@@:
	 jmp	 short COMPROM_LOOPINT ; Join common loop code

COMPROM_XBIOS:
	 push	 es		; Save for a moment

; Save the address of the selected interrupt handler

	 mov	 al,CPQINTS.CPQINT_NUM[si].LO ; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old INT 01h handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINTHW_VEC.VOFF,bx ; Save to use later
	 mov	 OLDINTHW_VEC.VSEG,es

	 cmp	 es:[bx].LO,@OPCOD_IRET ; Izit an IRET?
	 pop	 es		; Restore
	 assume  es:INTVEC	; Tell the assembler about it
	 je	 short COMPROM_LOOPINT ; Jump if so

	 call	 CPQINTS.CPQINT_FIND[si] ; Take appropriate action
	 jc	 near ptr COMPROM_ERR ; Jump if we failed

	 btr	 CPQ_FLAG,$CPQ_TRIPERR ; Did we trip on the trip?
	 jc	 near ptr COMPROM_ERR ; Jump if we failed
COMPROM_LOOPINT:
	 add	 si,size CPQINT_STR ; Skip to the next entry

	 loop	 COMPROM_NEXTINT ; Jump if more interrupts
COMPROM_DONE:

; Mark first 32KB of ROM at F000:0 as available high DOS memory
; and transfer the ROM marker at F000:0 to F000:8000.

	 push	 seg PGROUP	; Setup DS for ROM2OVR
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 seg XGROUP	; Get the segment
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

	 mov	 bx,ROMIDN	; Get highest multiple of 4KB of identical ROM parts
	 shr	 bx,9-0 	; Convert from bytes to 512-bytes
	 mov	 di,0F000h shr (9-4) ; Express starting address (F000) in 512-bytes
	 mov	 ah,MEM_MAP[di] ; Get current ROM marker

; Search for the next secondary ROM marker and replace it with the
; current ROM marker in AL.  This allows us to implement the user's
; request to map in high DOS memory at ROMIDN in case he knows better.

	 push	 di		; Save (for ROM2OVR)
	 dec	 di		; Back up for loop
@@:
	 inc	 di		; Skip to next entry

	 mov	 al,MEM_MAP[bx+di] ; Get MEM_MAP entry

	 cmp	 al,@XLAT_ROM0	; Izit a primary ROM marker?
	 je	 short @F	; Jump if so

	 cmp	 al,@XLAT_ROM1	; Izit the other primary ROM marker?
	 je	 short @F	; Jump if so

	 cmp	 al,@XLAT_ROM2	; Izit secondary ROM marker?
	 jne	 short @B	; Jump if not

	 mov	 MEM_MAP[bx+di],ah ; Save in F000:ROMIDN
@@:
	 pop	 di		; Restore

	 mov	 cx,bx		; Copy for use in ROM2OVR
	 mov	 al,@XLAT_OVR	; Mark as high DOS memory
	 call	 ROM2OVR	; Mark as high DOS memory in MEM_MAP
				; offset DI for CX entries

	 mov	 ax,ROMIDN	; Get highest multiple of 4KB of identical ROM parts
	 mov	 bx,ax		; Copy to set SYSROM_START
	 shr	 bx,4-0 	; Convert from bytes to paras
	 add	 bx,0F000h	; Add old ROM start
	 mov	 SYSROM_START,bx ; Save as new starting segment of system ROM

	 push	 seg CGROUP	; Get segment of system BIOS
	 pop	 es		; Address it
	 assume  es:CGROUP	; Tell the assembler about it

	 test	 SYS_FLAG,@SYS_CPQ ; Izit COMPAQ Deskpro 386/486?
	 jz	 short COMPROM_REF ; Jump if not

; If the primary or secondary CPQSTR is in ROMIDN, shift to the second half
; Note AX = ROMIDN still

	 lea	 bx,OFFCPQSTR	; CGROUP:BX ==> structure

	 cmp	 ax,CGROUP:[bx] ; Izit within the identical parts?
	 jb	 short @F	; Jump if not

	 call	 CPQSETSTR	; Point the structure into second half
@@:
	 lea	 bx,OFFCPQST2	; CGROUP:BX ==> structure

	 cmp	 ax,CGROUP:[bx] ; Izit within the identical parts?
	 jb	 short @F	; Jump if not

	 call	 CPQSETSTR	; Point the structure into second half
@@:

; If we recovered all the BIM memory, zap the CPQSTR presence flag

	 test	 NRD_FLAG,@NRD_CPQBIM ; Did we recover BIM memory?
	 jz	 short @F	; Jump if not

	 call	 CPQZAPSTR	; Zap the BIM presence flag
@@:
COMPROM_REF:
	 call	 ROMREF 	; Check on internal ROM references

	 clc			; Mark as successful

	 jmp	 short COMPROM_EXIT ; Join common exit code

	 assume  ds:nothing,es:nothing ; Tell the assembler about it

; An interrupt failed to convert

COMPROM_ERR:
if @OEM_DEBUG
	 push	 seg PGROUP	; Setup DS for data references
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 test	 DB2_FLAG,@DB2_CROM ; Display debug info?
	 jz	 short COMPROM_STC ; Jump if not

	 push	 seg XGROUP	; Get the segment
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

	 mov	 al,CPQINTS.CPQINT_NUM.LO[si] ; Get the interrupt #
	 lea	 si,YGROUP:MSG_ERRCPQ1 ; YGROUP:SI ==> error code save area
	 call	 FMT_ERR_CODE	; Format the error code

	 push	 offset YGROUP:MSG_ERRCPQ ; Tell 'em the bad news
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IF @OEM_DEBUG
COMPROM_STC:
	 stc			; Mark as unsuccessful

	 assume  ds:nothing,es:nothing ; Tell the assembler about it

COMPROM_EXIT:

; Restore original INT 29h handler

	 push	 seg XGROUP	; Get the segment
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 pushf			; Save for a moment

	 mov	 al,29h 	; Restore this one
	 lds	 dx,CPQINT29_VEC ; DS:DX ==> original handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT	; Install our own one

	 popf			; Restore
COMPROM_ERR1:
	 REGREST <es,ds>	; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it
	 popa			; Restore

	 ret			; Return to DOS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMPROM  endp			; End COMPROM procedure
	 NPPROC  CPQSETSTR -- Set CPQ Structure
	 assume  ds:PGROUP,es:CGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set COMPAQ memory structure

On entry:

CGROUP:BX ==>	 pointer to structure

|

	 REGSAVE <ax,si>	; Save registers

; Tell the system to decode the upper 128KB as high/low RAM

	 call	 INST_TMPINT15	; Install temporary INT 15h handler

	 mov	 TOP_MIO,@CPQ_HLRAM ; Mark as read-write, high/low
	 lea	 si,CPQMIO_LO	; DS:SI ==> 32-bit destination address
	 call	 TOP_WRITE	; Write value in TOP_MIO to CPQ I/O port

; Point the structure into the second half

	 mov	 al,CGROUP:[bx].HI ; Get current value
	 add	 CHKSUM,al	; Add old value back into the checksum
	 or	 CGROUP:[bx].HI,80h ; Point into the 2nd half
	 mov	 al,CGROUP:[bx].HI ; Get new value
	 sub	 CHKSUM,al	; Subtract new value from the checksum

; Tell the system to decode the upper 128KB as high/low ROM

	 mov	 TOP_MIO,@CPQ_HLROM ; Mark as read-only, high/low
	 lea	 si,CPQMIO_LO	; DS:SI ==> 32-bit destination address
	 call	 TOP_WRITE	; Write value in TOP_MIO to CPQ I/O port

	 call	 REST_TMPINT15	; Restore original INT 15h handler

	 REGREST <si,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CPQSETSTR endp			; End CPQSETSTR procedure
	 NPPROC  CPQZAPSTR -- Zap CPQ BIM Presence Flag
	 assume  ds:PGROUP,es:CGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Zap COMPAQ BIM presence flag

|

	 REGSAVE <ax,bx,si>	; Save registers

; Tell the system to decode the upper 128KB as high/low RAM

	 call	 INST_TMPINT15	; Install temporary INT 15h handler

	 mov	 TOP_MIO,@CPQ_HLRAM ; Mark as read-write, high/low
	 lea	 si,CPQMIO_LO	; DS:SI ==> 32-bit destination address
	 call	 TOP_WRITE	; Write value in TOP_MIO to CPQ I/O port

; Point the structure into the second half

	 mov	 bx,OFFCPQSTR	; CGROUP:BX ==> structure

	 mov	 ax,0FFFFh	; Get new value
	 sub	 CHKSUM,al	; Subtract new value from the checksum
	 sub	 CHKSUM,ah	; ...

	 xchg	 ax,CGROUP:[bx].CPQSTR_FLAG ; Get current value
	 add	 CHKSUM,al	; Add old value back into the checksum
	 add	 CHKSUM,ah	; ...

; Tell the system to decode the upper 128KB as high/low ROM

	 mov	 TOP_MIO,@CPQ_HLROM ; Mark as read-only, high/low
	 lea	 si,CPQMIO_LO	; DS:SI ==> 32-bit destination address
	 call	 TOP_WRITE	; Write value in TOP_MIO to CPQ I/O port

	 call	 REST_TMPINT15	; Restore original INT 15h handler

	 REGREST <si,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CPQZAPSTR endp			; End CPQZAPSTR procedure
	 NPPROC  ROMREF -- Check On Internal ROM References
	 assume  ds:PGROUP,es:CGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on internal ROM references.

Any instructions of the form

MOV reg,CS:[disp]

where disp < ROMIDN, must be converted to point into the
second half of the BIOS.

|

	 REGSAVE <ax,dx,si,fs>	; Save registers

	 push	 seg XGROUP	; Get segment of XGROUP
	 pop	 fs		; Address it
	 assume  fs:XGROUP	; Tell the assembler about it

; Tell the system to decode the upper 128KB as high/low RAM

	 test	 I15_FLAG,@I15_CPQ ; Izit a COMPAQ TOP384 scheme?
	 jz	 short @F	; Jump if not

	 call	 INST_TMPINT15	; Install temporary INT 15h handler

	 mov	 TOP_MIO,@CPQ_HLRAM ; Mark as read-write, high/low
	 lea	 si,CPQMIO_LO	; DS:SI ==> 32-bit destination address
	 call	 TOP_WRITE	; Write value in TOP_MIO to CPQ I/O port
@@:
	 mov	 dx,ROMIDN	; Get highest multiple of 4KB of identical ROM parts

; Check for CS:MOV (2E 8A)

	 mov	 ax,(@OPCOD_MOVR8  shl 8) or @OPCOD_CS ; Search for this
	 call	 ROMREF_MRM	; Search through even/odd parts using MOD R/M

; Check for CS:MOV (2E 8B)

	 mov	 ax,(@OPCOD_MOVR16 shl 8) or @OPCOD_CS ; Search for this
	 call	 ROMREF_MRM	; Search through even/odd parts using MOD R/M

; Check for CS:MOV (2E A0)

	 mov	 ax,(@OPCOD_MOVALM shl 8) or @OPCOD_CS ; Search for this
	 call	 ROMREF_MOF	; Search through even/odd parts using MOFFS

; Check for CS:MOV (2E A1)

	 mov	 ax,(@OPCOD_MOVAXM shl 8) or @OPCOD_CS ; Search for this
	 call	 ROMREF_MOF	; Search through even/odd parts using MOFFS

; Tell the system to decode the upper 128KB as high/low ROM

	 test	 I15_FLAG,@I15_CPQ ; Izit a COMPAQ TOP384 scheme?
	 jz	 short @F	; Jump if not

	 mov	 TOP_MIO,@CPQ_HLROM ; Mark as read-only, high/low
	 lea	 si,CPQMIO_LO	; DS:SI ==> 32-bit destination address
	 call	 TOP_WRITE	; Write value in TOP_MIO to CPQ I/O port

	 call	 REST_TMPINT15	; Restore original INT 15h handler
@@:
	 REGREST <fs,si,dx,ax>	; Restore
	 assume  fs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROMREF	 endp			; End ROMREF procedure
	 NPPROC  ROMREF_MRM -- Search Through Even/Odd Using MOD R/M
	 assume  ds:PGROUP,es:CGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search through even/odd parts using the MOD R/M byte.

On entry:

AX	 =	 pattern to search for
DX	 =	 ROMIDN

|

	 REGSAVE <di>		; Save registers

	 mov	 di,8000h	; Search through the second half on even boundary
	 call	 ROMREF_MRMSUB	; Search for pattern in AX

	 mov	 di,8001h	; Search through the second half on odd boundary
	 call	 ROMREF_MRMSUB	; Search for pattern in AX

	 REGREST <di>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROMREF_MRM endp 		; End ROMREF_MRM procedure
	 NPPROC  ROMREF_MRMSUB -- Subroutine to ROMREF_MRM
	 assume  ds:PGROUP,es:CGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Subroutine to ROMREF_MRM

On entry:

AX	 =	 pattern to search for
DX	 =	 ROMIDN
ES:DI	 ==>	 starting point in CGROUP

|

	 REGSAVE <bx,cx,di>	; Save registers

	 mov	 cx,32*1024/2-1 ; # words in 32KB
ROMREF_MRMSUB1:
	 jcxz	 ROMREF_MRMSUB2 ; Jump if no more remain
   repne scasw			; Search for pattern
	 jne	 short ROMREF_MRMSUB2 ; Jump if not found

	 mov	 bl,es:[di]	; Get the MOD R/M byte
	 and	 bl,(mask $MOD) or (mask $RM) ; Isolate MOD and R/M fields

	 cmp	 bl,(00b shl $MOD) or (@DISP shl $RM) ; Izit MOD=00, DISP?
	 jne	 short ROMREF_MRMSUB1 ; Jump if not

	 cmp	 dx,CGROUP:[di+1] ; Izit within the identical parts?
	 jb	 short ROMREF_MRMSUB1 ; Jump if not

	 mov	 bl,CGROUP:[di+2] ; Get original value
	 add	 CHKSUM,bl	; Add old value back into the checksum
	 or	 bl,80h 	; Shift to second half
	 mov	 CGROUP:[di+2],bl ; Save back into ROM
	 sub	 CHKSUM,bl	; Subtract new value from the checksum

	 jmp	 ROMREF_MRMSUB1 ; Go around again

ROMREF_MRMSUB2:
	 REGREST <di,cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROMREF_MRMSUB endp		; End ROMREF_MRMSUB procedure
	 NPPROC  ROMREF_MOF -- Search Through Even/Odd Using MOFFS
	 assume  ds:PGROUP,es:CGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search through even/odd parts using the MOFFS value.

On entry:

AX	 =	 pattern to search for
DX	 =	 ROMIDN

|

	 REGSAVE <di>		; Save registers

	 mov	 di,8000h	; Search through the second half on even boundary
	 call	 ROMREF_MOFSUB	; Search for pattern in AX

	 mov	 di,8001h	; Search through the second half on odd boundary
	 call	 ROMREF_MOFSUB	; Search for pattern in AX

	 REGREST <di>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROMREF_MOF endp 		; End ROMREF_MOF procedure
	 NPPROC  ROMREF_MOFSUB -- Subroutine to ROMREF_MOF
	 assume  ds:PGROUP,es:CGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Subroutine to ROMREF_MOF

On entry:

AX	 =	 pattern to search for
DX	 =	 ROMIDN
ES:DI	 ==>	 starting point in CGROUP

|

	 REGSAVE <bx,cx,di>	; Save registers

	 mov	 cx,32*1024/2-1 ; # words in 32KB
ROMREF_MOFSUB1:
	 jcxz	 ROMREF_MOFSUB2 ; Jump if no more remain
   repne scasw			; Search for pattern
	 jne	 short ROMREF_MOFSUB2 ; Jump if not found

	 cmp	 dx,CGROUP:[di] ; Izit within the identical parts?
	 jb	 short ROMREF_MOFSUB1 ; Jump if not

	 mov	 bl,CGROUP:[di+1] ; Get original value
	 add	 CHKSUM,bl	; Add old value back into the checksum
	 or	 bl,80h 	; Shift to second half
	 mov	 CGROUP:[di+1],bl ; Save back into ROM
	 sub	 CHKSUM,bl	; Subtract new value from the checksum

	 jmp	 ROMREF_MOFSUB1 ; Go around again

ROMREF_MOFSUB2:
	 REGREST <di,cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROMREF_MOFSUB endp		; End ROMREF_MOFSUB procedure
	 FPPROC  FINDHW -- Find Owner of Hardware Interrupt
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of a hardware interrupt.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 mov	 OLDCPQSTK_VEC.VSEG,ss ; Save old stack pointers
	 mov	 OLDCPQSTK_VEC.VOFF,sp ; ...

	 push	 seg XGROUP	; Get new stack segment
	 pop	 ss		; Address it
	 assume  ss:nothing	; Tell the assembler about it
	 lea	 sp,CPQSTKZ	; SS:SP ==> new stack

	 REGSAVE <ax,dx>	; Save registers

; Install our own single-step interrupt handler

	 call	 INSTINT01	; Install our INT 01h handler

	 or	 CPQ_FLAG,mask $CPQ_I01 ; Mark as active

	 REGREST <dx,ax>	; Restore

STK_STR  struc

	 dw	 ?		; Caller's BP
STK_ARG1 dw	 ?		; Argument #1

STK_STR  ends

	 pushad 		; Save all EGP registers
	 REGSAVE <ds,es>	; Save segment registers

	 pushf			; Simulate INT calling environment
	 cli

	 pushf			; Save flags
	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack
	 or	 [bp].STK_ARG1,mask $TF ; Set trap flag
	 pop	 bp		; Restore
	 popf			; Put into effect

	 call	 OLDINTHW_VEC	; Request hardware interrupt service

	 REGREST <es,ds>	; Restore
	 popad			; Restore all EGP registers

	 and	 CPQ_FLAG,not (mask $CPQ_I01) ; Mark as inactive

	 test	 CPQ_FLAG,mask $CPQ_I1B ; Is Ctrl-Break active?
	 jz	 short @F	; Jump if not

	 push	 ax		; Save for a moment
	 DOSCALL @KEYSTA	; Get keyboard status and check for Ctrl-Break
				; Ignore return value
	 pop	 ax		; Restore
@@:
	 call	 RESTINT01	; Restore the original INT 01h handler

	 btr	 CPQ_FLAG,$CPQ_TRIP ; Test and reset trip flag
	 cmc			; Complement to conform to prologue
	 jc	 short FINDHW_EXIT ; Jump if not found (note CF=1)

; Calculate the address of the dword with original
; hardware interrupt handler address

	 call	 DECODE_TRIP	; Attempt to decode the tripping address
	 jc	 short FINDHW_EXIT ; Jump if not found (note CF=1)

	 call	 FINDHW_ACT	; Take appropriate action

	 clc			; Indicate all went well
FINDHW_EXIT:
	 lss	 sp,OLDCPQSTK_VEC ; Restore original stack pointer
	 assume  ss:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDHW	 endp			; End FINDHW procedure
	 NPPROC  FINDHW_CPQ -- Action Routine If Tripping Address Found
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Action routine if tripping address found in CPQINT01_SAVE.

|

	 REGSAVE <bx,es>	; Save registers

	 les	 bx,CPQINT01_SAVE ; Get the saved dword address
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 bx,ROMIDN	; Izit within the identical parts?
	 ja	 short @F	; Jump if not

	 or	 es:[bx].VOFF,8000h ; Point into the 2nd half
@@:
	 REGREST <es,bx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDHW_CPQ endp 		; End FINDHW_CPQ procedure
	 FPPROC  FINDIGN -- Ignore If There's A Mismatch
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

The interrupt vector's segment is not in F000.

Ignore it.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 clc			; Mark as successful

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDIGN  endp			; End FINDIGN procedure
	 FPPROC  FINDCHK -- Find An Interrupt Vector
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

The interrupt vector's segment is not in F000.

Attempt to find it, but don't get upset if we don't.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 call	 FINDHW 	; Call as hardware interrupt
				; Return with CF significant
	 adc	 IGNCNT,0	; Count it in if we failed

	 and	 CPQ_FLAG,not (mask $CPQ_TRIPERR) ; Ignore trip failure

	 clc			; Mark as successful

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDCHK  endp			; End FINDCHK procedure
	 FPPROC  FINDERR -- Fail On The Mismatch
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

The interrupt vector's segment is not in F000.

That's all folks.
Note that this routine is called from ROM_RESET.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 stc			; Mark as unsuccessful

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDERR  endp			; End FINDERR procedure
	 FPPROC  FINDVERIFY -- Find The Owner (after pointer verification)
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Verify that an interrupt is valid before we find its owner

* Ensure that the vector is not 0000:0000
* Ensure that the interrupt handler is not all zeros
* Ensure that the interrupt handler is not 0FFh
* Ensure that the interrupt handler is not inside the XBDA (if present)

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax,ebx,dx,es> ; Save registers

; Verify that the interrupt vector is valid (not 0:0)

	 mov	 ebx,OLDINTHW_VEC ; Get the vector we're about to jump to

	 or	 ebx,ebx	; Is the vector zero?
	 jz	 short FIND_VERIFY_CLC ; Jump if so

; Verify that the vector points to valid code

	 mov	 es,OLDINTHW_VEC.VSEG ; Address the vector's code
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[bx].ELO,0	; Does it point to zero?
	 je	 short FIND_VERIFY_CLC ; Jump if so

	 cmp	 es:[bx].ELO,-1 ; Does it point to 0FFFFh?
	 je	 short FIND_VERIFY_CLC ; Jump if so

	 mov	 dx,es		; Get the segment of our routine

; See if an XBDA exists

	 mov	 ah,0C0h	; Return System Configuration function
	 int	 15h		; System services (returns in ES:BX)
	 assume  es:nothing	; Tell the assembler
	 jc	 short FIND_VERIFY_CALL ; Jump if service not present

	 cmp	 ah,86h 	; Error?
	 je	 short FIND_VERIFY_CALL ; Jump if service not present

	 test	 es:[bx+5].LO,@BIT2 ; Is XBIOS allocated?
	 jz	 short FIND_VERIFY_CALL ; Jump if XBDA not present

; Verify that the vector does not point into the XBDA

	 push	 seg BIOSDATA	; Address the BIOS Data Area
	 pop	 es		; ... via ES
	 assume  es:BIOSDATA	; Tell the assembler about it

	 cmp	 dx,XBDA_SEG	; Compare against lower limit of XBDA
	 jb	 short FIND_VERIFY_CALL ; Jump if handler is below XBDA

	 mov	 bx,XBDA_SEG	; Save segment of XBDA

	 mov	 es,XBDA_SEG	; Address the XBDA
	 assume  es:nothing	; Tell the assembler about it

	 movzx	 ax,es:[1].LO	; Get the length of the XBDA (in KB)
	 shl	 ax,(10-4)	; Convert from KB to paras

	 add	 ax,bx		; Add in start of XBDA (to length)

	 cmp	 dx,ax		; Compare against XBDA upper limit
	 jbe	 short FIND_VERIFY_CLC ; Jump if XBDA top is above the handler

; Call the interrupt vector (all the tests have passed)

FIND_VERIFY_CALL:
	 call	 FINDCHK	; Call as hardware interrupt
				; Return with carry flag significant
	 jmp	 short FIND_VERIFY_EXIT ; Goto common exit

FIND_VERIFY_CLC:
	 clc			; Indicate no error
FIND_VERIFY_EXIT:
	 REGREST <es,dx,ebx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FINDVERIFY endp 		; End FINDVERIFY procedure
	 FPPROC  FIND13 -- Find The Owner Of INT 13h
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of INT 13h.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax,dx>	; Save registers

	 mov	 ah,10h 	; Code to test drive ready
	 mov	 dl,80h 	; For fixed disk #0
	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0

	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND13	 endp			; End FIND13 procedure
	 FPPROC  FIND14 -- Find The Owner Of INT 14h
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of INT 14h.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax,dx>	; Save registers

	 mov	 ah,03h 	; Code to return status
	 mov	 dx,0		; ...of COMM port #0
	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0

	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND14	 endp			; End FIND14 procedure
	 FPPROC  FIND15 -- Find The Owner Of INT 15h
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of INT 15h.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax>		; Save register

	 mov	 ah,01h 	; Code to turn cassette motor off
	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND15	 endp			; End FIND15 procedure
	 FPPROC  FIND16 -- Find The Owner Of INT 16h
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of INT 16h.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax>		; Save register

	 mov	 ah,01h 	; Code to return keyboard status
	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND16	 endp			; End FIND16 procedure
	 FPPROC  FIND17 -- Find The Owner Of INT 17h
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of INT 17h.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax,dx>	; Save registers

	 mov	 ah,02h 	; Code to return printer status
	 mov	 dx,0		; ...of printer port #0
	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0

	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND17	 endp			; End FIND17 procedure
	 FPPROC  FIND1A -- Find The Owner Of INT 1Ah
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of INT 1Ah.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax>		; Save register

	 mov	 ah,02h 	; Code to read real-time clock
	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND1A	 endp			; End FIND1A procedure
	 FPPROC  FIND1B -- Find The Owner Of INT 1Bh
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of INT 1Bh.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 or	 CPQ_FLAG,mask $CPQ_I1B ; Mark as active

	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0

	 and	 CPQ_FLAG,not (mask $CPQ_I1B) ; Mark as inactive

	 clc			; Mark as successful

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND1B	 endp			; End FIND1B procedure
	 FPPROC  FIND40 -- Find The Owner Of INT 40h
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of INT 40h.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax,dx>	; Save registers

	 mov	 ah,00h 	; Code to reset disk system
	 mov	 dl,00h 	; For floppy disk #0
	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0

	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND40	 endp			; End FIND40 procedure
	 FPPROC  FIND4B -- Find The Owner Of INT 4Bh
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of INT 4Bh.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 pusha			; Save all GP registers

	 mov	 ah,not @VDS_MAJOR ; Anything but a VDS function
	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0

	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND4B	 endp			; End FIND4B procedure
	 FPPROC  FIND5C -- Find The Owner Of INT 5Ch
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Find the owner of INT 5Ch.

On entry:

All registers may be significant.

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <bx,es>	; Save registers

; Is vector pointing to somewhere in ROM?

	 cmp	 OLDINTHW_VEC.VSEG,0C000h ; Pointing to anywhere in ROM?
	 jae	 short FIND5C_EXIT; Jump if so (skip FINDHW) (note CF=0)

	 les	 bx,PNETB_CCB	; ES:BX ==> status call to NETBIOS
	 assume  es:nothing	; Tell the assembler about it

	 call	 FINDCHK	; Call as hardware interrupt
				; Return with CF=0
FIND5C_EXIT:
	 REGREST <es,bx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FIND5C	 endp			; End FIND5C procedure
	 FPPROC  CPQINT01 -- Single-step Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Single-step interrupt handler

|

CPQINT01_STR struc

CPQINT01_BP dw	 ?		; Caller's BP
CPQINT01_IP dw	 ?		; ...	   IP
CPQINT01_CS dw	 ?		; ...	   CS
CPQINT01_FL dw	 ?		; ...	   FL
CPQINT01_FL2 dw  ?		; ...	   FL if CS:IP ==> POPF

CPQINT01_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 test	 CPQ_FLAG,mask $CPQ_TRIP ; Izit set already?
	 jnz	 short CPQINT01_CLR ; Jump if so

	 test	 CPQ_FLAG,mask $CPQ_I01 ; Izit active?
	 jz	 short CPQINT01_CLR ; Jump if not

	 REGSAVE <eax,ebx>	; Save for a moment
	 mov	 ax,ROMADDR	; Get the lowest expected ROM address
	 cmp	 ax,[bp].CPQINT01_CS ; Izit in ROM?
	 ja	 short @F	; Jump if not (note CF=0)

	 movzx	 eax,[bp].CPQINT01_CS ; Get segment address
	 shl	 eax,4-0	; Convert paras to bytes
	 movzx	 ebx,[bp].CPQINT01_IP ; Get offset
	 add	 eax,ebx	; EAX = linear address
;;;;;;;  cmp	 eax,CON1MB	; Izit below the HMA?
	 cmp	 eax,00100000h	; Izit below the HMA?
@@:
	 REGREST <ebx,eax>	; Restore
	 ja	 short CPQINT01_SAVELAST ; Jump if not

	 push	 CPQINT01_LAST.VSEG ; Get last segment
	 push	 CPQINT01_LAST.VOFF ; ...      offset

	 assume  ds:XGROUP	; Tell a white lie
CSOVR	 pop	 CPQINT01_TRIP.VOFF ; Save as tripping offset
CSOVR	 pop	 CPQINT01_TRIP.VSEG ; ...	       segment
	 assume  ds:nothing	; Retract nose

	 assume  ds:XGROUP	; Tell a white lie
CSOVR	 mov	 <TRIP_DS,ds>	; Save all segment registers
CSOVR	 mov	 <TRIP_ES,es>
CSOVR	 mov	 <TRIP_SS,ss>
CSOVR	 mov	 <TRIP_BX,bx>
CSOVR	 mov	 <TRIP_SI,si>
CSOVR	 mov	 <TRIP_DI,di>
	 assume  ds:nothing	; Retract nose

	 push	 [bp].CPQINT01_BP ; Get caller's BP

	 assume  ds:XGROUP	; Tell a white lie
CSOVR	 pop	 TRIP_BP
CSOVR	 or	 <CPQ_FLAG,mask $CPQ_TRIP> ; Mark as set
	 assume  ds:nothing	; Retract nose
CPQINT01_CLR:
	 and	 [bp].CPQINT01_FL,not (mask $TF) ; Clear trap flag

	 jmp	 short CPQINT01_IRET ; Join common IRET code

CPQINT01_SAVELAST:
	 assume  ds:XGROUP	; Tell a white lie
	 push	 [bp].CPQINT01_CS   ; Get caller's segment
	 push	 [bp].CPQINT01_IP   ; ...	   offset
CSOVR	 pop	 CPQINT01_LAST.VOFF ; Save as last offset
CSOVR	 pop	 CPQINT01_LAST.VSEG ; ...	   segment
	 assume  ds:nothing	; Retract nose

; Check for next instruction as IRET or POPF

	 REGSAVE <ax,si,di,ds>	; Save registers

	 lds	 si,CPQINT01_LAST ; Get address of next instruction
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 di,0		; Assume it's POPF (# bytes to skip up stack)

	 cmp	 ds:[si].LO,@OPCOD_POPF ; Izit a POPF?
	 je	 short CPQINT01_TF ; Jump if so

	 mov	 di,4		; Assume it's IRET (# bytes to skip up stack)

	 cmp	 ds:[si].LO,@OPCOD_IRET ; Izit an IRET?
	 jne	 short @F	; Jump if not
CPQINT01_TF:
	 or	 [bp+di].CPQINT01_FL2,mask $TF ; Ensure trap flag set
@@:
	 REGREST <ds,di,si,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it
CPQINT01_IRET:
	 pop	 bp		; Restore

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CPQINT01 endp			; End CPQINT01 procedure
	 FPPROC  CPQINT29 -- Raw Output Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Raw output interrupt handler

|

	 test	 CPQ_FLAG,mask $CPQ_I1B ; Is Ctrl-Break active?
	 jz	 short @F	; Jump if not

	 iret			; Ignore the character

@@:
	 jmp	 CPQINT29_VEC	; Continue with original handler

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CPQINT29 endp			; End CPQINT29 procedure
	 NPPROC  DECODE_TRIP -- Decode The Tripping Address
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Decode the tripping address

On exit:

CF	 =	 0 if successful
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,si,es>	; Save registers

; Calculate the address of the dword with original INT 13h handler address

	 mov	 ax,TRIP_DS	; Get default segment register
	 mov	 CPQINT01_SAVE.VSEG,ax ; Save for later use
	 mov	 CPQINT01_SAVE.VOFF,0  ; Zero offset
	 and	 CPQ_FLAG,not (mask $CPQ_SEG) ; Mark as not present

	 les	 si,CPQINT01_TRIP ; ES:SI ==> tripping address
	 assume  es:nothing	; Tell the assembler about it
DECODE_NEXT:
	 lods	 es:[si].LO	; Get next byte

	 cmp	 al,@OPCOD_CS	; Izit CS: override?
	MJ e	 DECODE_CS	; Jump if so

	 cmp	 al,@OPCOD_DS	; Izit DS: override?
	MJ e	 DECODE_DS	; Jump if so

	 cmp	 al,@OPCOD_ES	; Izit ES: override?
	MJ e	 DECODE_ES	; Jump if so

	 cmp	 al,@OPCOD_SS	; Izit SS: override?
	MJ e	 DECODE_SS	; Jump if so

	 cmp	 al,@OPCOD_CALLF ; Izit far call immediate?
	MJ e	 DECODE_IMMED	; Jump if so

	 cmp	 al,@OPCOD_JMPF ; Izit far jump immediate?
	MJ e	 DECODE_IMMED	; Jump if so

	 cmp	 al,@OPCOD_GRP5 ; Izit a Group 5 instruction?
	MJ ne	 DECODE_ERR	; Jump if not

	 lods	 es:[si].LO	; Get the MOD R/M byte

	 mov	 ah,al		; Copy for destructive testing
	 and	 ah,mask $REG	; Isolate the register field
	 shr	 ah,$REG	; Shift to low-order

	 cmp	 ah,011b	; Izit CALL Ep?
	 je	 short @F	; Jump if so

	 cmp	 ah,101b	; Izit JMP Ep?
	MJ ne	 DECODE_ERR	; Jump if not
@@:
	 and	 al,not (mask $REG) ; Clear the REG field
	 mov	 ah,al		; Copy for destructive testing
	 and	 ah,mask $MOD	; Isolate the MOD field
	 shr	 ah,$MOD	; Shift to low-order

	 cmp	 ah,11b 	; Izit MOD = 11?
	MJ e	 DECODE_ERR	; Jump if so

	 cmp	 al,(00b shl $MOD) or (110b shl $RM) ; Izit special 00xxx110 ?
	MJ e	 DECODE_D16	; Jump if so

	 cmp	 ah,00b 	; Izit MOD = 00?
	 je	 short DECODE_EA ; Yes, just no displacement

	 cmp	 ah,01b 	; Izit MOD = 01?
	 je	 short DECODE_D8 ; Yes, get sign-extended DISP8
				; Fall through for 16-bit displacement w/EA

	 push	 ax		; Save MOD R/M byte

	 lods	 es:[si].ELO	; Get the 16-bit displacement
	 mov	 CPQINT01_SAVE.VOFF,ax ; Save for later use

	 pop	 ax		; Restore

	 jmp	 short DECODE_EA ; Join common EA code

DECODE_D8:
	 push	 ax		; Save MOD R/M byte

	 lods	 es:[si].LO	; Get the 8-bit displacement
	 cbw			; Sign extend it
	 mov	 CPQINT01_SAVE.VOFF,ax ; Save for later use

	 pop	 ax		; Restore
DECODE_EA:
	 and	 al,mask $RM	; Isolate R/M field
	 shr	 al,$RM 	; Shift to low-order
	 mov	 bh,0		; Zero to use as word
	 mov	 bl,al		; Copy to index register
	 shl	 bx,1		; Times two to index table od words

	 jmp	 PRMACT[bx]	; Take appropriate action

; Effective address is BX+SI

RM000:
	 mov	 ax,TRIP_BX	; Get base value
	 add	 ax,TRIP_SI	; Plus index value

	 jmp	 short DECODE_OFF ; Join common code

; Effective address is BX+DI

RM001:
	 mov	 ax,TRIP_BX	; Get base value
	 add	 ax,TRIP_DI	; Plus index value

	 jmp	 short DECODE_OFF ; Join common code

; Effective address is BP+SI

RM010:
	 mov	 ax,TRIP_BP	; Get base value
	 add	 ax,TRIP_SI	; Plus index value

	 jmp	 short DECODE_CHKSS ; Join common SS checking code

; Effective address is BP+DI

RM011:
	 mov	 ax,TRIP_BP	; Get base value
	 add	 ax,TRIP_DI	; Plus index value

	 jmp	 short DECODE_CHKSS ; Join common SS checking code

; Effective address is SI

RM100:
	 mov	 ax,TRIP_SI	; Get index value

	 jmp	 short DECODE_OFF ; Join common code

; Effective address is DI

RM101:
	 mov	 ax,TRIP_DI	; Get index value

	 jmp	 short DECODE_OFF ; Join common code

; Effective address is BP

RM110:
	 mov	 ax,TRIP_BP	; Get base value
DECODE_CHKSS:
	 test	 CPQ_FLAG,mask $CPQ_SEG ; Izit present?
	 jnz	 short @F	; Jump if so

	 mov	 bx,TRIP_SS	; Get default segment override
	 mov	 CPQINT01_SAVE.VSEG,bx ; Save for later use
@@:
	 jmp	 short DECODE_OFF ; Join common

; Effective address is BX

RM111:
	 mov	 ax,TRIP_BX	; Get base value
DECODE_OFF:
	 add	 CPQINT01_SAVE.VOFF,ax ; Save for later use

	 jmp	 short DECODE_CLC ; Join common OK code

DECODE_D16:
	 lods	 es:[si].ELO	; Get the 16-bit displacement
	 mov	 CPQINT01_SAVE.VOFF,ax ; Save for later use

	 jmp	 short DECODE_CLC ; Join common OK code

DECODE_CS:
	 mov	 ax,TRIP_CS	; Get segment register value

	 jmp	 short DECODE_SEG ; Join common code

DECODE_DS:
	 mov	 ax,TRIP_DS	; Get segment register value

	 jmp	 short DECODE_SEG ; Join common code

DECODE_ES:
	 mov	 ax,TRIP_ES	; Get segment register value

	 jmp	 short DECODE_SEG ; Join common code

DECODE_SS:
	 mov	 ax,TRIP_SS	; Get segment register value
DECODE_SEG:
	 or	 CPQ_FLAG,mask $CPQ_SEG ; Mark as segment override present

	 mov	 CPQINT01_SAVE.VSEG,ax ; Save for later use

	 jmp	 DECODE_NEXT	; Go around again

DECODE_ERR:
	 or	 CPQ_FLAG,mask $CPQ_TRIPERR ; Mark as a trip

	 stc			; Mark as unsuccessful

	 jmp	 short DECODE_EXIT ; Join common exit code

DECODE_IMMED:
	 mov	 CPQINT01_SAVE.VOFF,si ; Save the address
	 mov	 CPQINT01_SAVE.VSEG,es
DECODE_CLC:
	 clc			; Mark as successful
DECODE_EXIT:
	 REGREST <es,si,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DECODE_TRIP endp		; End DECODE_TRIP procedure
	 NPPROC  SAVEINT01 -- Save Current INT 01h Handler
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save the current INT 01h handler.

|

	 REGSAVE <eax,bx,es>	; Save registers

	 mov	 ax,seg PGROUP	; Get segment of CON1MB
	 mov	 es,ax		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Because the IDTR might not be at linear address 0, use the address
; obtained via SIDTD (which is what the CPU uses, but not
; DOSCALL @GETINT/@SETINT).

	 SIDTD	 CURIDTR	; Save current IDTR

	 mov	 eax,CURIDTR.DTR_BASE ; Get its linear address

	 cmp	 eax,CON1MB	; Izit out of reach?
	 jb	 short @F	; Jump if not

	 xor	 eax,eax	; Use the one at 0:0
@@:
	 ror	 eax,4-0	; Convert from bytes to paras
				; retaining the orginal value
	 mov	 es,ax		; Address it
	 assume  es:INTVEC	; Tell the assembler about it

	 rol	 eax,4-0	; Rotate back
	 and	 eax,@NIB0	; Isolate the residue mod 16
	 mov	 bx,ax		; Copy to index register

	 mov	 CURIDTR_VEC.VOFF,bx ; Save for later use
	 mov	 CURIDTR_VEC.VSEG,es ; ...

;;;;;;;; les	 bx,CURIDTR_VEC ; ES:BX ==> current IDT
;;;;;;;; assume  es:INTVEC	; Tell the assembler about it
;;;;;;;;
	 mov	 eax,INT00_VEC[bx+01h*(type INT00_VEC)] ; Get the address
	 mov	 CPQINT01_VEC,eax ; Save to restore later

	 REGREST <es,bx,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVEINT01 endp			; End SAVEINT01 procedure
	 NPPROC  INSTINT01 -- Install Our INT 01h Handler
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Install our INT 01h handler.

|

	 REGSAVE <bx,es>	; Save registers

	 les	 bx,CURIDTR_VEC ; ES:BX ==> current IDT
	 assume  es:INTVEC	; Tell the assembler about it

	 mov	 INT00_VEC[bx+01h*(type INT00_VEC)].VOFF,offset XGROUP:CPQINT01
	 mov	 INT00_VEC[bx+01h*(type INT00_VEC)].VSEG,seg XGROUP

	 REGREST <es,bx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INSTINT01 endp			; End INSTINT01 procedure
	 NPPROC  RESTINT01 -- Restore Original INT 01h Handler
	 assume  ds:XGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore the original INT 01h handler.

|

	 REGSAVE <eax,bx,es>	; Save registers

	 les	 bx,CURIDTR_VEC ; ES:BX ==> current IDT
	 assume  es:INTVEC	; Tell the assembler about it

	 mov	 eax,CPQINT01_VEC ; Get original address
	 mov	 INT00_VEC[bx+01h*(type INT00_VEC)],eax ; Restore

	 REGREST <es,bx,eax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RESTINT01 endp			; End RESTINT01 procedure
if @OEM_CPQCUT
	 NPPROC  CHECK_LOSTINT -- Find interrupts about to be lost
	 assume  ds:PGROUP,es:nothing,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

If we've processed a Compaq ROM cut table, there may still be
interrupt vectors pointing into the twilight zone between the
old system ROM start and the new.

If we find any of these, add 32KB to the offset to relocate it to
the high half.

On entry:

DX	 =	 New SYSROM_START value (in paras)

On exit:

DX	 =	 Old SYSROM_START (SYSROM_START updated).

|

	 REGSAVE <ax,bx,cx,si,es> ; Save registers

	 mov	 ax,seg INTVEC	; Get segment of IDT
	 mov	 es,ax		; Address it
	 assume  es:INTVEC	; Tell the assembler about it

	 mov	 si,dx		; Get new system ROM start
	 sub	 si,SYSROM_START ; Less the old one to get the offset in paras
	 shl	 si,4-0 	; Convert from paras to bytes

; SI has the offset of the new system ROM start and is used to
; check each IDT entry to see if points into the twilight zone.

	 mov	 cx,256 	; Get # interrupts to check
	 xor	 bx,bx		; Initialize offset into IDT
CHECK_LOSTINT_NEXT:
	 mov	 ax,INT00_VEC[bx].VSEG ; Get the segment

	 cmp	 ax,SYSROM_START ; Izit in the ROM?
	 jne	 short CHECK_LOSTINT_LOOP ; Jump if not

	 mov	 ax,INT00_VEC[bx].VOFF ; Get the offset

	 cmp	 ax,si		; Izit below the new start point?
	 jae	 short CHECK_LOSTINT_LOOP ; Jump if not

	 or	 INT00_VEC[bx].VOFF,8000h ; Relocate to the high half
CHECK_LOSTINT_LOOP:
	 add	 bx,type INT00_VEC ; Skip to next IDT entry

	 loop	 CHECK_LOSTINT_NEXT ; Jump if more entries to check

; Swap the values and return the old one

	 xchg	 SYSROM_START,dx ; Set new Start of System BIOS

	 REGREST <es,si,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_LOSTINT endp		; End CHECK_LOSTINT procedure
endif				; IF @OEM_CPQCUT

XCODE	 ends			; End XCODE segment

	 MEND			; End QMAX_CPQ module
