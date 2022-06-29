;' $Header:   P:/PVCS/MAX/QUILIB/RAMSCAN.ASV   1.1   30 May 1997 12:09:04   BOB  $
	 title	 RAMSCAN -- Subroutines to scan RAM in V86 or real mode
	 page	 58,122
	 name	 RAMSCAN

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1985-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  byte-aligned, public, class 'data'

Link requirements:  None, standalone subroutine.

Program derived from:  BIOSCRC.ASM

Original code by:  Henry Groover, October 1991

|
.286p
.xlist
	 include MASM.INC
	 include ASCII.INC
	 include PTR.INC
	 include DIR.INC
	 include FCB.INC
	 include DOSCALL.INC
	 include 386.INC
	 include EMMCALL.INC
	 include CMOS.INC
	 include 8255.INC
	 include INTVEC.INC
	 include OPEN.INC
	 include IOCTL.INC

	 include EMM2CALL.INC
	 include QMAXWIN3.INC
	 include QMAX_POS.INC
.list

%.model  &MODEL,c

	 @NO_UNDERBAR	equ	0
	 @RAMSCAN_OWNR	equ	1
	 include VENDINFO.INC
	 include RAMSCAN.INC

	 include CPUID.INC
CGROUP	 group	 CPUID_SEG

	 .data

	 extrn	 SUB_FLAG:word	; Local flags - in VENDINFO.ASM

	 public  INFO_CTL,MAXINFO
	 include QMAXINFO.INC
	 include QMAX_CTL.INC
INFO_CTL db	 ?		; IOCTL type
MAXINFO  INFO_STR <>		; MAX information structure
	 dw	 10 dup (0)	; Room for growth
INFO_END label	 byte

	 public  INFOSIZE,PORT67,LCL_FLAG,MAXROM,POVR_MAC,MAXINFOVER
INFOSIZE equ	 size INFO_STR
PORT67	 equ	 MAXINFO.INFO_P67 ; Get 386MAX I/O port
LCL_FLAG equ	 MAXINFO.INFO_LCL ; Get local flags
POVR_MAC equ	 MAXINFO.INFO_POVR ; Starting segment of high DOS arena
MAXROM	 equ	 MAXINFO.INFO_SROM ; Get start of system ROM
MAXINFOVER equ	 MAXINFO.INFO_VER ; Version of MAX running ("6;02")
	 include QMAX_LCL.INC

	 public  PaSYSROM,CMPROM
PaSYSROM dw	 0F000h 	; Physical segment of system ROM (assumes Non-MCA)
CMPROM	 dw	 0F000h 	; Compressed segment of system ROM (assumes Non-MCA)

	 public  MAXVER
MAXVER	 db	 0,?,?		; 386MAX version #

	 public  NMIPORT,NMIENA,NMIDIS,NMIMASK
NMIPORT  dw	 @CMOS_CMD	; NMI clear I/O port
NMIENA	 db	 @CMOS_ENANMI	; ... enable value
NMIDIS	 db	 @CMOS_DISNMI	; ... disable value
NMIMASK  db	 mask $ATPAR	; ... clear mask

	 public  LCLMEM
LCLMEM	 db	 @LCLMEM_LEN dup (?) ; Save area for memory check

	 public  MAXdNAME
MAXdNAME  db	 '386MAX$$',0   ; Name of our device

	 public  WINVXD_VEC
WINVXD_VEC dd	 ?		; Far entry point to our VXD

	 .code

	 NPPROC  MARK_XT -- Mark As An XT
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Mark as an XT

|

	 or	 SUB_FLAG,@SUB_XT ; Mark as an XT

	 mov	 NMIPORT,0A0h	; NMI clear I/O port
	 mov	 NMIENA,80h	; ... enable value
	 mov	 NMIDIS,00h	; ... disable value
	 mov	 NMIMASK,mask $XTPAR ; ... clear mask

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

MARK_XT  endp			; End MARK_XT procedure
	 NPPROC  CHECK_MODEL -- Check for MCA-Compatible Machines
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Check for MCA-compatible, EISA, and a whole bunch more machines.

|

	 REGSAVE <ax,bx,cx,es> ; Save registers

	 mov	 ax,seg CGROUP	; Get CPUID seg
	 mov	 es,ax		; Address it
	 assume  es:CGROUP	; Tell the assembler about it

; Check for MCA-compatible machines

	 call	 Is_MCA 	; Return AX=1 if MCA, AX=0 if not,
	 jc	 short CHECK_MODEL_XBCF ; CF=1 if read configuration call failed

	 or	 ax,ax		; Izit 0?
	 jz	 short CHECK_MODEL_XMC ; See if it's a 128K BIOS anyway

	 or	 SUB_FLAG,@SUB_MCA ; Mark as an MCA-compatible machine
	 jmp	 short CHECK_MODEL_BCF ; Join common BCF code

CHECK_MODEL_XMC:
	 call	 Is_BCF 	; Return AX=1 if BCF capable, AX=0 if not
	 or	 ax,ax		; Izit 0?
	 jz	 short CHECK_MODEL_XBCF ; Does not support BCF

CHECK_MODEL_BCF:
	 or	 SUB_FLAG,@SUB_BCF ; Mark as BCF capable
	 mov	 PaSYSROM,0E000h ; Mark as start of 128K BIOS
	 mov	 CMPROM,0E000h	; Mark as start of 128K BIOS

CHECK_MODEL_XBCF:
	 mov	 al,BIOSCPUID	; Get machine ID

	 cmp	 al,@CPU_PC	; Check for PC
	 je	 short CHECK_MODEL_PCXT ; Jump if present

	 cmp	 al,@CPU_XT	; Check for XT
	 je	 short CHECK_MODEL_PCXT ; Jump if present

	 cmp	 al,@CPU_XT2	; Check for XT2
	 je	 short CHECK_MODEL_PCXT ; Jump if present

	 cmp	 al,@CPU_M30	; Check for PS/2 Model 30
	 je	 short CHECK_MODEL_PCXT ; Jump if present

	 cmp	 al,@CPU_CNV	; Check for Convertible
	 je	 short CHECK_MODEL_PCXT ; Jump if present

	 cmp	 al,@CPU_JR	; Check for Jr
	 je	 short CHECK_MODEL_PCXT ; Jump if present

	 jmp	 short CHECK_MODEL_EXIT ; Join common code

CHECK_MODEL_PCXT:
	 call	 MARK_XT	; Mark as PC/XT present
CHECK_MODEL_EXIT:
	 REGREST <es,cx,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_MODEL endp		; End CHECK_MODEL procedure
	 NPPROC  OUTCMOS -- Out To CMOS, Conditional Read
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Out to CMOS, conditional read.

Note that this routine is bimodal.

|

	 out	 dx,al		; Send to CMOS

	 cmp	 dx,@CMOS_CMD	; Izit an AT?
	 jne	 short @F	; Jump if not

	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@CMOS_DATA	; Ensure OUT is followed by IN
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

OUTCMOS  endp			; End OUTCMOS procedure
	 NPPROC  CLR_PARITY -- Clear Parity Latches
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Clear the parity latches

Note that this routine is bimodal.

|

	 REGSAVE <ax>		; Save register

	 mov	 ah,NMIMASK	; Get parity mask
	 in	 al,@8255_B	; Get the parity latches
	 jmp	 short $+2	; I/O delay

	 or	 al,ah		; Toggle parity check latches off
	 out	 @8255_B,al	; Tell the system about it
	 jmp	 short $+2	; I/O delay

	 xor	 al,ah		; Toggle parity check latches on
	 out	 @8255_B,al	; Tell the system about it
;;;;;;;; jmp	 short $+2	; I/O delay

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CLR_PARITY endp 		; End CLR_PARITY procedure
	 NPPROC  ENABLE_NMI -- Enable NMI, Clear Parity Latches
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Enable NMI, clear parity latches.

Note that this routine is bimodal.

|

	 pushf			; Save flags
	 cli			; Ensure interrupts disabled

	 REGSAVE <ax,dx>	; Save for a moment

; Clear the parity latches

	 call	 CLR_PARITY	; Clear any parity errors

; Enable the NMI latch

	 mov	 dx,NMIPORT	; Get NMI clear I/O port
	 mov	 al,NMIENA	; ...	  enable value
	 call	 OUTCMOS	; Out to CMOS, conditional read

	 REGREST <dx,ax>	; Restore
	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ENABLE_NMI endp 		; End ENABLE_NMI procedure
	 NPPROC  DISABLE_NMI -- Disable NMI
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Disable NMI

Note that this routine is bimodal.

|

	 pushf			; Save flags
	 cli			; Ensure interrupts disabled

	 REGSAVE <ax,dx>	; Save for a moment

; Disable NMI

	 mov	 dx,NMIPORT	; Get NMI clear I/O port
	 mov	 al,NMIDIS	; ...	  disable value
	 call	 OUTCMOS	; Out to CMOS, conditional read

	 REGREST <dx,ax>	; Restore
	 popf			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISABLE_NMI endp		; End DISABLE_NMI procedure
	 PPROC	FLUSH_CACHE -- Overwhelm the cache
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

In case we're on a system with an external cache (we assume the
optimal size of 256K) we need to flush the cache (and prepare to
invalidate it) by reading lots of data.

Note that we can't use WBINVD for this purpose even on systems
that (theoretically) support it because of a bug in certain chipsets.

|

	 REGSAVE <ax,cx,dx,si,ds> ; Save

	 sub	 dx,dx		; Start at 0:0
	 mov	 cx,8		; Number of 64K segments to read

	 cld			; Set forward direction (up)
@@:
	 mov	 ds,dx		; Address segment
	 assume  ds:nothing	; Tell the assembler

	 sub	 si,si		; Starting offset

	 push	 cx		; Save for a moment
	 mov	 cx,32*1024	; 64K in words
  rep	 lods	 ds:[si].ELO	; Read the data
	 pop	 cx		; Restore

	 add	 dx,1000h	; Skip to next segment

	 loop	 @B		; Go around again

FCACHE_EXIT:
	 REGREST <ds,si,dx,cx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FLUSH_CACHE endp		; End FLUSH_CACHE procedure
	 PPROC	CHECK_RAM -- Check For RAM
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

See if there's RAM in the 512-byte block at BX:0 (length of
test block is defined as @LCLMEM_LEN in BIOSCRC.INC).

1.  Save the data in case there's really RAM there.

2.  Store a single value throughout the 512-byte block.

3.  Flush any cache controller by reading lots of data

4.  Scan for the stored value and count the # matches.

5.  Restore the values saved in step 1.

6.  To err on the side of conservatism (we don't want to
    mis-identify real RAM), if we find the stored value
    at more than half the positions we'll call it real RAM.

On entry:

BX	 =	 segment to check

On exit:

CF	 =	 1 if RAM present
	 =	 0 if no RAM there

|

	 REGSAVE <ax,cx,dx,si,di,es> ; Save registers

	 cli			; Ensure nobody moves
	 call	 DISABLE_NMI	; Disable NMIs

; 1.  Save the data in case there's really RAM there.

	 push	 ds		; Get DGROUP
	 pop	 es		; Address DGROUP
	 assume  es:nothing	; Tell the assembler

	 mov	 ds,bx		; Put into segment register
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; DS:SI ==> start of 512-byte block

	 lea	 di,DGROUP:LCLMEM ; ES:DI ==> local storage area
	 mov	 cx,@LCLMEM_LEN/2 ; # words in LCLMEM
     rep movsw			; Copy it to local memory

	 mov	 es,bx		; Address the same segment with ES
	 assume  es:nothing	; Tell the assembler about it

; 2.  Store a single value throughout the 512-byte block.

	 mov	 ax,'&!'-1234h  ; Store this
	 add	 ax,1234h	; Add back in to avoid "bus capacitance" problems
	 mov	 cx,@LCLMEM_LEN/2 ; # words in LCLMEM
	 xor	 di,di		; Offset of zero
     rep stosw			; Store constant value

; 3.  Flush any cache controller by reading lots of data

	 call	 FLUSH_CACHE	; Read 512K at 0:0

; 4.  Scan for the stored value and count the # matches.

	 mov	 cx,@LCLMEM_LEN/2 ; # words in LCLMEM
	 xor	 di,di		; Offset of zero
	 xor	 dx,dx		; Zero counter for mismatches
CHECK_RAM_NEXT:
	 jcxz	 CHECK_RAM_REST ; That's all folks
    repe scasw			; Scan for stored value
	 je	 short CHECK_RAM_REST ; No more to search

	 inc	 dx		; Count in a mismatch

	 jmp	 CHECK_RAM_NEXT ; Go around again

; 5.  Restore the values saved in step 1.

CHECK_RAM_REST:
	 mov	 ax,seg DGROUP	; Get our DS
	 mov	 ds,ax		; Setup DS for MOVSW
	 assume  ds:DGROUP	; Tell the assembler about it

	 lea	 si,DGROUP:LCLMEM ; DS:SI ==> local storage area
	 xor	 di,di		; ES:DI ==> start of 4KB block

	 mov	 cx,@LCLMEM_LEN/2 ; # words in LCLMEM
     rep movsw			; Copy it from local memory

	 call	 ENABLE_NMI	; Enable NMI, clear the parity latches

	 sti			; Enable interrupts

; 6.  To err on the side of conservatism (we don't want to
;     mis-identify real RAM), if we find the stored value
;     at more than half the positions we'll call it real RAM.

	 cmp	 dx,@LCLMEM_LEN/4 ; More than half are mismatches?

; CF = 0 means many mismatches (RAM not present)
; CF = 1 means few  mismatches (RAM	present)

	 REGREST <es,di,si,dx,cx,ax> ; Restore
	 assume  es:nothing

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_RAM endp			; End CHECK_RAM procedure
	 PPROC	 MAXPRES -- Determine Presence of 386MAX
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Determine presence of 386MAX.
Also, define additional variables needed if present.
Note that we completely ignore the presence of Move'em, as this
info structure call is made only to get MAX-specific info such
as the start of the compressed ROM.

On exit:

AX	 =	 1 if present (with additional variables defined)
	 =	 0 if not

|

	 REGSAVE <bx,cx,dx,es> ; Save registers

	 call	 CHECK_MODEL	; Get model-dependent information

	 call	 Is_VM		; Set @SUB_VM flag if in V86 mode -
				; CRC code will expect us to have set
				; it in MAXPRES

	 mov	 al,@OPEN_R	; Function code for read-only access
	 DOSCALL @OPENF2,MAXdNAME ; Attempt to open the device
	MJ c	 MAXPRES_ERR	; Jump if not

	 mov	 bx,ax		; Copy to handle register
	 mov	 al,0		; Function code to get device information
	 DOSCALL @IOCTL2	; Get device information into DX
	MJ c	 MAXPRES_ERRCLOSE ; Jump if not

	 test	 dx,@IOCTL_DEV	; Izit a device?
	MJ z	 MAXPRES_ERRCLOSE ; Jump if not

	 mov	 al,02h 	; Read from device
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO
	MJ c	 MAXPRES_ERRCLOSE ; Jump if error

	 DOSCALL @CLOSF2	; Close the file

	 mov	 ax,MAXROM	; Get start of system ROM from 386MAX
	 mov	 CMPROM,ax	; Save for later use

	 or	 SUB_FLAG,@SUB_PRES ; Set present bit (tested by GETBCRC)

	 mov	 ax,1		; Indicate it's present

	 jmp	 short MAXPRES_EXIT ; Join common exit code

MAXPRES_ERRCLOSE:
	 DOSCALL @CLOSF2	; Close the file
MAXPRES_ERR:
	 xor	 ax,ax		; Indicate not present
MAXPRES_EXIT:
	 REGREST <es,dx,cx,bx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

MAXPRES  endp			; End MAXPRES procedure

	 PPROC	 Get_BIOS_Start -- Return start of BIOS
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Return starting segment of ROM.  If argument on stack = 1, return
start of compressed ROM; otherwise, physical ROM.

On entry:
Argw	 =	 1: return compressed ROM
		 0: return physical ROM

On exit:
AX	 =	 segment of requested ROM

|
GBIOS_args	struc
	 dw	?	; Caller's BP
if @codesize
	 dd	?	; Caller's CS:IP
else
	 dw	?	; Caller's IP
endif
	 arg1	dw ?
GBIOS_args	ends

	 push	 bp		; Save BP
	 mov	 bp,sp		; Get stack frame

	 call	 MAXPRES	; Get MAX data

	 mov	 ax,[bp].arg1	; Get argument
	 or	 ax,ax		; Izit 0?
	 jz	 short GBIOS_Phys ; Return physical ROM

	 mov	 ax,CMPROM	; Return compressed ROM
	 jmp	 short GBIOS_Exit ; Join common exit code

GBIOS_Phys:
	 mov	 ax,PaSYSROM	; Physical ROM address

GBIOS_Exit:
	 pop	 bp		; Restore BP

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

Get_BIOS_Start endp

	 PPROC	 EMM2_VXD_Call -- Make EMM2CALL through VXD if necessary
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

With registers set up for EMM2CALL, determine if we're running under
Windows 3.0 or higher.	If so, get our VXD entry point and make the
EMM2CALL indirectly.  Otherwise, make the EMM2CALL normally.  Assume
that MAX is present.

On entry:
AH	 EMM2CALL function

On exit:
AH=A4	 In Windows and unable to get VXD entry point
AH=return value from EMM2CALL

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save

	 mov	 ax,1600h	; Detect Win386 running
	 int	 2fh		; Return with AL=0 or AL=80 if no Windows

	 test	 al,7fh 	; Are we running under Windows?
	 jz	 short EMM2_VXD_TEST ; Call MAX directly if not (Note ZF=1)

	 cmp	 al,01h 	; Izit 2.xx?
	 je	 short EMM2_VXD_TEST ; Jump if so (Note ZF=1)

	 cmp	 al,0FFh	; Izit the other 2.xx?
	 je	 short EMM2_VXD_TEST ; Jump if so (Note ZF=1)

	 xor	 di,di		; In case we're not running Windows 3???
	 mov	 es,di		; ES:DI == 0:0
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,1684h	; Function code for Get Device Entry Point
	 mov	 bx,@VXD_ID	; Our device ID
	 int	 2Fh		; Request multiplexor support
	 assume  es:nothing	; Tell the assembler about it
				; Return with ES:DI ==> Device API Entry Point

	 mov	 WINVXD_VEC.VOFF,di ; Save for later use
	 mov	 WINVXD_VEC.VSEG,es ; ...

	 or	 al,1		; Clear ZF to bypass next test
EMM2_VXD_TEST:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 jz	 short EMM2_VXD_MAX ; Call MAX directly if ZF set

EMM2_VXD_WIN3:
	 cmp	 WINVXD_VEC.VSEG,0 ; Did Get Device Entry Point fail?
	 jnz	 short @F	; Jump if not

	 cmp	 WINVXD_VEC.VOFF,0 ; Is offset portion 0 as well?
	 jnz	 short @F	; Jump if not

	 mov	 ah,0A4h	; Force error condition
	 jmp	 short EMM2_VXD_EXIT ; Join common exit code

@@:
	 push	 @VXDAPI_UTIL	; Code to request Utility service
	 call	 WINVXD_VEC	; Request Windows Virtual Device API service
	 jmp	 short EMM2_VXD_EXIT ; Join common exit code

EMM2_VXD_MAX:
	 EMMOUT 		; Call MAX through the back door

EMM2_VXD_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

EMM2_VXD_Call	 endp		; End EMM2_VXD_Call procedure
	 PPROC	 Get_CMOS_POS -- Return CMOS component of POS data
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Return CMOS component of POS data.  Versions of MAX that capture the
system board CMOS POS data return it in bufptr[8] for backward
compatibility with versions of MAX that don't return this value.
We therefore move bufptr[8] to the beginning of the list, so
bufptr[0] contains the system board CMOS POS, and bufptr[1-8]
contain the values for adapters 1 through 8.

On entry:
Argw	 =	 Far pointer to buffer (POSD_STR[9])

On exit:
AX	 =	 1 if successful, else 0.

|
CMOS_args	struc
	 dw	?	; Caller's BP
if @codesize
	 dd	?	; Caller's CS:IP
else
	 dw	?	; Caller's IP
endif
	 bufptr dd ?
CMOS_args	ends

	 push	 bp		; Save BP
	 mov	 bp,sp		; Get stack frame

	 REGSAVE <bx,cx,dx,si,di,ds,es> ; Save

	 call	 MAXPRES	; Get MAX data
	 or	 ax,ax		; Izit present?
	 jz	 CMOS_Exit	; Bail out if MAX not present.
				; (Note AX=0)

	 mov	 ah,@EMM2_POSCOPY ; Copy POS data into ES:DI
	 les	 di,[bp].bufptr ; Get pointer
	 assume  es:nothing	; Tell the assembler

	 call	 EMM2_VXD_Call	; Make EMM2CALL through VXD if necessary
COMMENT|
MAX did not always fail on this call, but would always indicate
success irregardless of the validity of the data returned.  A
failure here may indicate that the system has no ABIOS, or that
386MAX 6.02 is present with no ABIOS support.
|
CMOS_Return:
	 or	 ah,ah		; Did it succeed?
	 mov	 ax,1		; Assume success
	 jnz	 short CMOS_Err ; Jump if it failed

	 push	 ax		; Save result

	 push	 es		; Segment of buffer
	 pop	 ds		; Address for lods
	 assume  ds:nothing	; Tell the assembler

; We need to move bufptr[8] so it is the first element, keeping
; all others in order.	We exchange it with the previous element
; 8 times.
	 mov	 cx,8		; Number of slots to move
	 lea	 si,[di+(size POSD_STR)*8] ; First exchange source
	 mov	 bx,size POSD_STR ; Width of each element
	 cld			; String ops forwardly
CMOS_Exchange:
	 sub	 si,bx		; Back off to previous element

	 REGSAVE <cx,si>	; Save

	 mov	 cx,size POSD_STR ; Number of bytes to exchange
@@:
	 mov	 al,ds:[si+bx].LO ; Get a byte from bufptr[n+1]
	 xchg	 al,ds:[si].LO	; Exchange with byte from bufptr[n]
	 mov	 ds:[si+bx].LO,al ; Save byte in new location
	 inc	 si		; Adjust byte index

	 loop	 @B		; Process all bytes

	 REGREST <si,cx>	; Restore outer loop counter

	 loop	 CMOS_Exchange	; Go around again

	 pop	 ax		; Restore return value

	 jmp	 short CMOS_Exit ; Join common exit

CMOS_Err:
	 sub	 ax,ax		; Indicate failure
CMOS_Exit:
	 REGREST <es,ds,di,si,dx,cx,bx> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler

	 pop	 bp		; Restore BP

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

Get_CMOS_POS endp

	 MEND			; End RAMSCAN module
