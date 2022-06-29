;' $Header:   P:/PVCS/MAX/MEMLIMIT/MEMLIMIT.ASV   1.3   30 May 1997 11:55:08   BOB  $
	 title	 MEMLIMIT -- 386MAX Memory Manager Utility Program
	 page	 70,132
	 name	 MEMLIMIT

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-97 Qualitas, Inc.  All rights reserved.

Original code by:  Bob Depelteau

Modifications by:  None.

Description:
	This utility is intended for use with 386MAX version 5.13 and
	above.	It will hook the necessary resources to provide a way
	of limiting the common memory pool resources available to
	applications.  A typical use for this would be to stop
	applications like Lotus 123 or Autocad from allocating all of
	the available memory in the system.

Command Line Options:

	EMS    - to limit EMS memory available
	VCPI   - to limit VCPI memory available
	XMS    - to limit available XMS memory
	NODPMI - to disable DPMI memory
	NOXMS  - to disable XMS memory
	NOSWAP - to turn off the DPMI swapfile
	WIN30  - allocate all XMS memory above 16Mb
	REMOVE - to remove TSR from memory

	Note: The XMS, EMS, and VCPI key words must be followed by an
	      equal sign and a decimal value setting the maximum
	      amount to report.
	      All of the commands except REMOVE and WIN30 may be followed by
	      an optional count.

	Example; MEMLIMIT ems=100 nodpmi,0

	The example above limits the EMS memory to 100 16K pages
	for 1 call, and disables the DPMI memory forever.

	The first value is the maximum number of pages to report,
	and the second is the number of times to report the first
	value before going inactive.

	The size of a page is in increments of 16kb for EMS, 4Kb
	for VCPI, and 1kb for XMS.

	Valid range for the count is 0-255.
	If the count is 0 the request continues forever, 1 is the default.

|
SUBTTL Program declarations
PAGE
.xlist
.386
.SALL
	 include ASCII.INC
	 include MASM.INC
	 include DOSCALL.INC
	 include IOCTL.INC
	 include OPCODES.INC
	 include DEVDRV.INC
	 include EMMCALL.INC
	 include VCPI.INC
	 include XMS.INC
	 include VDS.INC
	 include PTR.INC
	 include DPMI.INC
	 include VMVSAPI.INC
	 include VERSION.INC
	 include DOSERR.INC
	 include MAC.INC

	 include EMM2CALL.INC
	 include QMAX_CTL.INC
	 include QMAX_DBG.INC
.list

@XENTS	equ	16		; Number of words in XMS allocation table
@X16M	equ	16384-64	; Number of XMS blocks before 16M boundary

CMDPKT	struc		; Begin command packet structure

CMD	dw	?	; Operation
STAT	dw	?	; Status of operation
LIMIT	dd	?	; Limit to set
COUNT	dw	?	; Number of times to report limit
PKTFLG	db	?	; Flags:  see @CMD_xxx below
	db	?	; Reserved for alignment

CMDPKT	ends		; End CMDPKT

@PKT_KILO equ	 01h	; Value is in kilobytes

@HLP_SW   equ	0	; CMDPKT.CMD values
@REM_SW   equ	1
@EMS_SW   equ	2
@VCPI_SW  equ	3
@XMS_SW   equ	4
@DPMI_SW  equ	5
@XMSL_SW  equ	6
@W30_SW   equ	7
@EMS_SW2  equ	8
@VCPI_SW2 equ	9
@XMS_SW2  equ	10
@DPMI_SW2 equ	11
@XMSL_SW2 equ	12
@W30_SW2  equ	13
@NSWP_SW  equ	14
@NSWP_SW2 equ	15
@DOS_SW   equ	16
@DOS_SW2  equ	17

@CMD_MAX  equ	17	; Number of highest command

CMDOPT	struc		; Parser command structure

SWTCH	dw	?	; Pointer to keyword string
LEN	db	?	; Keyword length
OPT	db	?	; Command packet option to execute
OPTFLG	db	?	; Flags:  see @OPT_xxx below
	db	?	; Reserved for alignment

CMDOPT ends		; End CMDOPT

@OPT_LIM equ	 01h	; Option may be followed by a limit (=limit)
@OPT_CNT equ	 02h	; ...			      count (,count)

XMSCHN	struc		; Structure of the XMS jump chaining structure

OPCD	db	?	; Jump opcode
JADR	dd	?	; Jump address

XMSCHN	ends		; End XMSCHN


PGROUP	 group	 CODE,NCODE,NDATA,NTEXT
ZGROUP	 group	 ZDATA


CODE	segment use16 byte public 'code' ; Start CODE segment
CODE	ends


NCODE	 segment use16 byte public 'code' ; Start NCODE segment
NCODE	 ends			; End NCODE segment


NDATA	 segment use16 dword public 'code' ; Start NDATA segment
NDATA	 ends			; End NDATA segment


NTEXT	 segment use16 byte public 'code' ; Start NTEXT segment
NTEXT	 ends			; End NTEXT segment


STACK	 segment STACK 'stack'

	 public  LCLSTK
LCLSTK	 dw	 512 dup (?)

STACK	 ends


ZDATA	 segment use16 para	; Start ZDATA segment
	 assume  cs:ZGROUP

	 public  ZTAIL
ZTAIL	 label	 byte		; End of data

ZDATA	 ends			; End ZDATA segment


PSPSEG	segment use16 at 0
	assume	cs:PSPSEG	; Make the assembler happy

.xlist
	INCLUDE PSP.INC 	; Define PSP area for program
.list

PSPSEG	ends


subttl Code segment Resident data
page +
CODE	segment 		; Start CODE segment
	assume	cs:PGROUP,ds:PGROUP

;  ORDER DEPENDENT 
	public	DEVDRV
DEVDRV	DD_STR	<-1,DRV_ATTR_CHAR,DEV_STRA,DEV_INTR,'MEMLIMIT'>
	public	XMSJMP
XMSJMP	label near
	jmp	$+5		; Dummy XMS jump header
	nop			;
	nop			;
	nop			;
	db	@OPCOD_JMPF	; Opcode for a far jump
	public	XMSJADR,XALOCNUM,RES_FLAG
XMSJADR dd	0		; To be patched when installing XMS trapping
XALOCNUM dw	0		; Number of used entries in XALOCTBL

RES_FLAG dw	0		; Resident flags
 @EMSFOUND equ	8000h		; XMS services found
 @KILLXMS  equ	0080h		; Switch to turn off all XMS
 @LIMITXMS equ	0040h		; Switch to LIMIT XMS
 @DOS58DIS equ	0020h		; Disable DOS 5803h support
 @RES	   equ	0010h		; Set when we are resident
 @HOOK67   equ	0008h		; Set when INT 67 is found and hooked
				; Note that this is set before our code is copied high
 @TRAPDPMI equ	0004h		; Trap DPMI calls?
 @TRAPVCPI equ	0002h		; Trap VCPI calls?
 @TRAPEMS  equ	0001h		; Trap EMS calls?


	public	DOSCNT,XMSCNT
DOSCNT	db	0		; Number of times to disable DOS 5803h
XMSCNT	db	0		; Number of times to disable XMS

	public	OLD67PROC
OLD67PROC dd	0		; Holder for old interrupt 67 vector

	 public  INVJMP, INVJOFF, INVJSEG
INVOFF	 equ	 0ah-(offset EMSSIG - offset INVJMP)

	 public  INVJMP
	 DPALIGN DEVDRV 	; Ensure para-aligned for EMS name

INVORG	 label	 word		; Used to compute segment
	 db	 @OPCOD_NOP	; Put in a couple NOPs
	 db	 @OPCOD_NOP	; So that INT 67 offset is non-zero
				; which is necessary for DOS's MEM command

INVJMP	 label	 word		; Destination of INT 67 Hook
	 db	 @OPCOD_JMPF	; Opcode for a far jump

	public INVJOFF, INVJSEG
INVJOFF dw	offset INT67PROC; We are going to set the interrupt vector...
INVJSEG dw	SEG CODE	; to point here and patch this jump

EMMSIGLEN equ 8
	public	EMSSIG
	 org	INVORG.DD_NAME	; Ensure at DD_NAME offset in para-aligned seg
EMSSIG	db	'EMMXXXX0',0    ; This is for people to search for.

;  ORDER DEPENDENT 

	public	NEW67SEG
NEW67SEG dw	0		; Holder for new interrupt 67 segment
	public	PSPPTR
PSPPTR	dw	0		; Segment holder of the PSP
	public	OLD21PROC
OLD21PROC dd	0		; Holder for old interrupt 21h vector
	public	OLD2FPROC
OLD2FPROC dd	0		; Holder for old interrupt 2F vector
	public	VCPILIM
VCPILIM dd	0		; Limit for VCPI memory in Kb
	public	VCPICNT
VCPICNT db	0		; Number of times to lie about VCPI
	public	EMSLIM
EMSLIM	dw	0		; Limit for EMS memory in Kb
	public	EMSCNT
EMSCNT	db	0		; Number of times to lie about EMS
	public	DPMICNT
DPMICNT db	0		; Number of times to disable DPMI
	public	XMSPTR
XMSPTR	dd	0		; Holder for XMS calls
	public	LODSEG
LODSEG	dw	0		; Segment of resident code
	public	UMBSEG
UMBSEG	dw	0		; Segment of UMB allocation
	public	CMDPTR
CMDPTR	dd	0		; Device driver command packet pointer
	public	XMSLIM
XMSLIM	dd	0		; Limit for XMS Memory
	public	XALOCTBL
XALOCTBL dw	@XENTS dup (0)	; Table of XMS handles over 16mb

	 public  DOSMAC
DOSMAC	 dw	 ?		; Segment of first DOS MAC entry

	 public  OLDSPAN
OLDSPAN  dd	 4 dup (?)	; Save area for old spanning entry

	 public  VMVSAPI_VEC
VMVSAPI_VEC dd	 PGROUP:XMSTRAP_RETF ; VM VSAPI entry point with default Ptr

szMEMLIMIT db	'MEMLIMIT',0    ; Signature
 lMEMLIMIT =	$ - szMEMLIMIT	; Length of our signature

	 public  PORT67,DBG_FLAG
PORT67	 dw	 ?		; Back door EMM2CALL value
DBG_FLAG dw	 ?		; Current DBG_FLAG value

	FPPROC INT2FPROC -- Interrupt 2F handler
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT|	Our INT 2Fh handler

Handles:
	168Ah	-- VSAPI
	4300h	-- Used to implement NOXMS
	1687h	-- Used to implement NODPMI
	1606h	-- Used to detect a Windows exit to free NOWIN3 memory

|

	 cmp	 ax,@DPMI_API2F ; Should we check the name?
	 je	 CHECK_NAME	; Yes, check it

	 cmp	 ax,4300h	; Is this an XMS request?
	 je	 XMS_REQ	; Yes, Handle it

	 cmp	 ax,@DPMI_GPME	; Is this a DPMI request?
	 je	 DPMI_REQ	; Yes, handle it

	 cmp	 ax,1606h	; Is this a WINDOWS terminate request?
	 je	 WIN_FREE	; Yes, FREE XMS used
I2F_JMP:
	 jmp	 OLD2FPROC	; Continue down the line

XMS_REQ:
	 test	 RES_FLAG,@KILLXMS ; Should we kill the XMS support
	 jz	 short I2F_JMP	; No, exit (FIXME)

	 cmp	 XMSCNT,0	; Are we doing this forever
	 je	 short I2F_IRET ; Yes, exit w/o passing request on

	 dec	 XMSCNT 	; Otherwise count down
	 jnz	 short I2F_IRET ; Exit if counter hasn't zeroed

	 and	 RES_FLAG,(not @KILLXMS) ; Counter zeroed, turn off
				; our masking of this call
	 jmp	 short I2F_IRET ; Exit w/o passing request on

WIN_FREE:
	 call	 FREEXMS	; Free any XMS memory we reserved
	 jmp	 short I2F_JMP	; Exit, passing control to next 2Fh

DPMI_REQ:
	 test	 RES_FLAG,@TRAPDPMI ; Should we kill the DPMI support
	 jz	 short I2F_JMP	; No, pass request on

	 cmp	 DPMICNT,0	; Are we doing this forever
	 je	 short I2F_IRET ; Yes, IRET

	 dec	 DPMICNT	; Otherwise count down
	 jnz	 short I2F_IRET ; Did count down zero?, Exit if not

	 and	 RES_FLAG,(not @TRAPDPMI) ; Count zeroed, stop masking
				; this call
	 jmp	 short I2F_IRET ; Exit w/o passing request on

CHECK_NAME:			; Check DS:SI against our Signature
	 REGSAVE <cx,es,di>	; Note that CX is pushed first

	 mov	 cx,cs		; Set ES to CS for signature comparison
	 mov	 es,cx		; . . .
	 assume  es:PGROUP	; Tell assembler

	 mov	 cx,lMEMLIMIT	; Get length of compare
	 lea	 di,szMEMLIMIT	; Address our string

     rep cmpsb			; Compare strings

	 je	 RETURN_INFO	; If they where equal, return info

	 REGREST <cx,di,es>	; Restore used regs
	 assume  es:nothing
	 jmp	 OLD2FPROC	; Continue down the line

RETURN_INFO:
	 REGREST <cx,cx,cx>	; Pull ES,DI off stack, and restore CX
	 assume  es:PGROUP	; Still valid

	 xor	 ax,ax		; Show success
	 lea	 di,API_PROC	; Address our Entry Point

I2F_IRET:
	 iret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
INT2FPROC  endp 		; End INT2FPROC
	NPPROC TOGGLE_DBG -- Toggle state of @DBG_X67
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Since VCPI access is frequently done via back door PORT67, we set
@DBG_X67.  MAX 7.01.044 checks @DBG_X67 on back door VCPI and converts
it to an Int 67h so we can pick it up down here.

Note that this is not needed for EMS calls, since the QMAX_IDT code
that picks up EMS calls out of the IDT does not do so if the current
Int 67h vector is not MAX's.

On entry:
	AX = Mask for @DBG_X67 state (ffff = turn on, 0 = turn off)

|

	REGSAVE <ax,bx> 	; Save

; If DBG_FLAG already has @DBG_X67 in the desired state, do nothing.

	mov	bx,@DBG_X67	; Bits we're interested in

	xor	ax,DBG_FLAG	; Set @DBG_X67 if different

	test	ax,bx		; Izit in the desired state?
	jz	short TDBG_EXIT ; Jump if we don't need to do anything

	xor	DBG_FLAG,bx	; Update our local copy

	EMMOUT	@EMM2_DBGFLAG	; Flip BX bits in MAX's DBG_FLAG
TDBG_EXIT:
	REGREST <bx,ax> 	; Restore

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	ret			; Return to caller

TOGGLE_DBG endp 		; End TOGGLE_DBG procedure
	FPPROC API_PROC -- Extended Command processor
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COMMENT|

On Entry:
	DS:SI points to extended command structure

On Exit:
	AH = Status for operation and
	DS:[SI.STAT] = results of the operation (error if ah != 0)

|

	 REGSAVE <ebx,ecx,edx,ds,es> ; save what we are going to use

	 push	 ds		;
	 pop	 es		; Set ES:SI to CMDOPT data structure
	 assume  es:nothing	; Lie to the assembler

	 mov	 ax,cs		; Ensure data segments ..
	 mov	 ds,ax		; set to code
	 assume  ds:PGROUP	; Tell assembler

	 mov	 es:[si].STAT,EM_BADCMD ; Possible message to print

	 mov	 bx,es:[si].CMD ; Get command
	 cmp	 bx,@CMD_MAX	; Izit greater than the highest supported command?
	 ja	 API_EXIT	; Yes, exit with pre-loaded error code

	 shl	 bx,1		; Turn command byte into word offset
	 add	 bx,offset API_JMP_TBL ; Convert to offset into JMP table
	 jmp	 [bx]		; Transfer control to routine

; At run-time we will replace invalid options with a common API_EXIT_NSUP
; subroutine I.E., if there is no XMS, remove all XMS related options

API_JMP_TBL dw	offset API_EXIT_NSUP
	    dw	offset REM_SW
	    dw	offset EMS_SW
	    dw	offset VCPI_SW
	    dw	offset XMS_SW
	    dw	offset DPMI_SW
	    dw	offset XMSL_SW
	    dw	offset W30_SW
	    dw	offset EMS_SW2
	    dw	offset VCPI_SW2
	    dw	offset XMS_SW2
	    dw	offset DPMI_SW2
	    dw	offset API_EXIT_NSUP
	    dw	offset W30_SW2
	    dw	offset NSWP_SW
	    dw	offset NSWP_SW2
	    dw	offset DOS_SW
	    dw	offset DOS_SW2

; ----- EMS Limit request
EMS_SW:
	 or	 RES_FLAG,@TRAPEMS ; Enable EMS trapping

	 mov	 ah,@EMM_GETPGCT ; Get page count

	 pushf			; Simulate interrupt
	 call	 OLD67PROC	; Holder for old interrupt 67 vector

; Change units to 16KB if in kilobytes

	 test	 es:[si].PKTFLG,@PKT_KILO ; Izit in kilobytes?
	 jz	 short @F	; Jump if not

	 shr	 es:[si].LIMIT,14-10 ; Convert from 1KB to 16KB
@@:
	 mov	 ax,bx		; Get number of unallocated pages
	 sub	 ax,es:[si].LIMIT.ELO ; Compute limit value
	 jnc	 short @F	; Anything left? Yep, go

	 mov	 ax,0		; Nope, keep it all
@@:
	 mov	 EMSLIM,ax	; Store it
	 mov	 ax,es:[si].COUNT ; Get count value
	 mov	 EMSCNT,al	; Store

	 mov	 es:[si].STAT,EM_EMS ; Message to print

	 jmp	 API_EXIT_OK	; Join common OK code

DOS_SW:
; ----- DOS 5803h Disable request
; If the DOS spanning entry is present, save and remove it

	 call	 NOSPAN 	; Save and remove the DOS spanning entry

	 jmp	 API_EXIT_OK	; Join common OK code

XMS_SW:
; ----- XMS Disable request
	 or	 RES_FLAG,@KILLXMS ; Enable XMS trapping
	 mov	 ax,es:[si].COUNT ; Get count value
	 mov	 XMSCNT,al	; Store

	 mov	 es:[si].STAT,EM_XMS ; Set status for return

	 jmp	 API_EXIT_OK	; Join common OK code

XMSL_SW:			; ----- XMS Limit request
	 GETXSTAT		; Do a XMS status call
	 cmp	 al,80H 	; Is the XMS stuff working?
	 je	 short @F	; Yes, continue

	 mov	 es:[si].STAT,EM_NOXMS ; XMS is NFG, set return status
	 jmp	 API_EXIT_OK	; Exit
@@:
	 or	 RES_FLAG,@LIMITXMS ; Enable XMS limiting

	 mov	 ah,@XMS_QRY2XMB ; Request amount of free XMS
	 call	 XMSJADR	; Request XMS service (use direct backdoor)

	 mov	 eax,edx	; Get total free XMS
	 sub	 eax,es:[si].LIMIT ; Subtract our limit
	 jnc	 short @F	; Was it more than we had? No go

	 mov	 eax,0		; Set it to not reserve anything
@@:
	 mov	 XMSLIM,eax	; Store it
	 mov	 ax,es:[si].COUNT ; Get count value
	 mov	 XMSCNT,al	; Store

	 mov	 es:[si].STAT,EM_XMSL ; Set return status

	 jmp	 API_EXIT_OK	; Join common OK code

VCPI_SW:			; ----- VCPI Limit request
	 or	 RES_FLAG,@TRAPVCPI ; Enable VCPI trapping

	 mov	 ax,(@VCPI shl 8)+(@VCPI_GNFP) ; Call to get all available?

	 pushf			; Simulate interrupt
	 call	 OLD67PROC	; Holder for old interrupt 67 vector

; Change units to 4KB if in kilobytes

	 test	 es:[si].PKTFLG,@PKT_KILO ; Izit in kilobytes?
	 jz	 short @F	; Jump if not

	 shr	 es:[si].LIMIT,12-10 ; Convert from 1KB to 4KB
@@:
	 mov	 eax,edx	; Get total available
	 sub	 eax,es:[si].LIMIT ; Adjust limit value
	 jnc	 short @F	; Anything left? Yea go

	 mov	 eax,0		; Nope set limit to keep all that is left
@@:
	 mov	 VCPILIM,eax	; Store it
	 mov	 ax,es:[si].COUNT ; Get count value
	 mov	 VCPICNT,al	; Store

	 mov	 es:[si].STAT,EM_VCPI ; Set return status

	 mov	 ax,-1		; Set @DBG_X67
	 call	 TOGGLE_DBG	; Toggle debug flags

	 jmp	 API_EXIT_OK	; Join common OK code

DPMI_SW:			; ----- DPMI Disable request
	 or	 RES_FLAG,@TRAPDPMI ; Enable DPMI trapping
	 mov	 ax,es:[si].COUNT ; Get count value
	 mov	 DPMICNT,al	; Store

	 mov	 es:[si].STAT,EM_DPMI ; Set return status

	 jmp	 API_EXIT_OK	; Join common OK code

REM_SW: 			; ----- Remove resident request
	 call	 REMOVE 	; Remove the current resident portion

	 jmp	 API_EXIT_OK	; Join common exit code


W30_SW: 			; ----- Windows XMS save allocation
	 mov	 es:[si].STAT,EM_WIN5 ; Set return status

	 mov	 bx,XALOCNUM	; Get next available entry count
	 cmp	 bx,@XENTS	; Is the buffer full?
	 jae	 API_EXIT_OK	; Yes, do an error exit (FIXME)

	 shl	 bx,1		; Word align for table index
	 mov	 ax,es:[si].LIMIT.ELO ; Get handle
	 mov	 XALOCTBL.[bx],ax ; Save handle in table
	 inc	 XALOCNUM	; Bump counter

	 mov	 es:[si].STAT,EM_WIN3 ; Set return status
	 jmp	 API_EXIT_OK	; Join common OK code


EMS_SW2:
	 mov	 es:[si].STAT,EM_WIN5 ; Set return status

	 and	 RES_FLAG, (not @TRAPEMS) ; Disable request

	 mov	 es:[si].STAT,EM_EMSF ; Set return status
	 jmp	 API_EXIT_OK	; Join common OK code

VCPI_SW2:
	 mov	 es:[si].STAT,EM_WIN5 ; Set return status
	 and	 RES_FLAG,(not @TRAPVCPI) ; Disable request

	 mov	 es:[si].STAT,EM_VCPIF ; Set return status

	 mov	 ax,0		; Clear @DBG_X67
	 call	 TOGGLE_DBG	; Toggle DBG_FLAG state

	 jmp	 API_EXIT_OK	; Join common OK code

DOS_SW2:
	 mov	 es:[si].STAT,EM_WIN5 ; Set return status

; If the DOS spanning entry is not present, restore it

	 call	 SPANFREE	; Restore the DOS spanning entry

	 jmp	 short API_EXIT_OK ; Join common OK code

XMS_SW2:			; XMSFREE
	 and	 RES_FLAG, not (@LIMITXMS or @KILLXMS ) ; Clear all XMS limits
	 mov	 es:[si].STAT,EM_XMSF ; Set return status
	 jmp	 short API_EXIT_OK ; Join common OK code

DPMI_SW2:
	 and	 RES_FLAG,(not @TRAPDPMI) ; Yes, don't need to lie any more

	 mov	 es:[si].STAT,EM_DPMIF ; Set return status
	 jmp	 short API_EXIT_OK ; Join common OK code

W30_SW2:
	 call	 FREEXMS	; Free any XMS memory we reserved

	 mov	 es:[si].STAT,EM_WINF ; Set return status
	 jmp	 short API_EXIT_OK ; Join common OK code

NSWP_SW:
	 mov	 es:[si].STAT,EM_WIN5 ; Set return status

	 mov	 bx,es:[si].COUNT ; Get count value

	 cmp	 bx,1		; Izit forever?
	 sbb	 bx,0		; Set to -1 if so
	 mov	 ax,@VMVSAPI_NOSWAP ; Function code to disable swapping
	 call	 VMVSAPI_VEC	; Request VSAPI service
				; returning old count in BX
	 mov	 es:[si].STAT,EM_SWAP ; Set return status
	 jmp	 short API_EXIT_OK	; Join common OK code

NSWP_SW2:
	 mov	 es:[si].STAT,EM_WIN5 ; Set return status

	 mov	 bx,0		; Count is zero to re-enable
	 mov	 ax,@VMVSAPI_NOSWAP ; Function code to disable swapping
	 call	 VMVSAPI_VEC	; Request VSAPI service
				; returning old count in BX
	 mov	 es:[si].STAT,EM_SWAPF ; Set return status
	 jmp	 short API_EXIT_OK ; Join common OK code

API_EXIT_NSUP:
	 mov	 es:[si].STAT,EM_NSUP ; Set return status

API_EXIT_OK:
	 mov	 ah,0		; Return no error

API_EXIT:
	 REGREST <es,ds,edx,ecx,ebx> ; Restore the registers we used
	 assume  ds:nothing,es:nothing ; Tell assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

API_PROC endp			; End API_PROC
	 FPPROC  INT67PROC -- Interrupt 67 handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

; Only hooked up when necessary, otherwise inactive.

	 REGSAVE <ds>		; Save used REG

; Address DATA with DS

	 push	 cs		; Address DATA with DS
	 pop	 ds		; . . .
	 assume  ds:PGROUP	; Tell the assembler

; Check EMS limit

	 test	 RES_FLAG,@TRAPEMS ; Are we trapping EMS calls?
	 jz	 short TRAP_VCPI ; No, check for VCPI calls

	 cmp	 ah,@EMM_GETPGCT ; Is this a GETPGCT call?
	 jne	 short TRAP_VCPI ; No, check for VCPI calls

	 pushf			; Simulate interrupt
	 call	 OLD67PROC	; Holder for old interrupt 67 vector

	 push	 ax		; Save call status

	 mov	 ax,bx		; Get the number of unallocated
	 sub	 ax,EMSLIM	; Check against limit
	 jnc	 short @F	; Is the Limit lower

	 mov	 ax,0		; No, set to no more available
@@:
	 mov	 bx,ax		; Set new available value

	 pop	 ax		; Restore EMS call status

	 cmp	 EMSCNT,0	; Are we doing this forever?
	 je	 short @F	; Yes, Continue

	 dec	 EMSCNT 	; No, count down
	 jnz	 short @F	; Was this the last time?

	 and	 RES_FLAG,(not @TRAPEMS) ; Yes, clear flag
@@:
	 jmp	 short I67_EXIT_IRET ; Exit handler (Only DS on stack)

TRAP_VCPI:			; ----- Check VCPI limit
	 test	 RES_FLAG, @TRAPVCPI ; Are we trapping VCPI calls?
	 jz	 short I67_EXIT_JMP ; No, continue on.

	 cmp	 ax,(@VCPI shl 8)+(@VCPI_GNFP) ; Is this an interesting call?
	 jne	 short I67_EXIT_JMP ; No, pass to real guy

	 pushf			; Simulate interrupt
	 call	 OLD67PROC	; Holder for old interrupt 67 vector

	 push	 eax		; Save working storage

	 mov	 eax,edx	; Get max number of pages available
	 sub	 eax,VCPILIM	; Adjust to compensate for the limit imposed
	 jnc	 short @F	; Any left? No, go

	 mov	 eax,0		; No, tell them we are out
@@:
	 mov	 edx,eax	; Set limited value
	 pop	 eax		; Restore working storage

	 cmp	 VCPICNT,0	; Do we need to check counter?
	 je	 short I67_EXIT_IRET ; No, exit

	 dec	 VCPICNT	; Yea, count down one
	 jnz	 short I67_EXIT_IRET ; Are we at zero?

	 and	 RES_FLAG,(not @TRAPVCPI) ; Disable request

I67_EXIT_IRET:			; Exit using the IRET method
	 REGREST <ds>		; Restore DS
	 assume  ds:nothing	; Tell assembler

	 iret

I67_EXIT_JMP:
	 REGREST <ds>		; Restore DS
	 assume  ds:nothing	; Tell assembler

	 jmp	OLD67PROC	; Transfer control to "real" I67

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT67PROC endp			; End INT67PROC
	 NPPROC  NOSPAN -- Save And Remove DOS Spanning Entry
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save and remove the DOS spanning entry.

On entry:

ES:SI	 ==>	 CMDOPT data structure

|

	 REGSAVE <eax,dx,fs>	; Save registers

	 test	 RES_FLAG,@DOS58DIS ; Izit already disabled?
	 jnz	 short NOSPAN_DONE ; Jump if so

	 int	 12h		; Get memory size into AX in kilobytes
	 shl	 ax,10-4	; Convert from 1KB to paras
	 mov	 dx,ax		; Save for later use
	 dec	 dx		; Less one for spanning entry

	 mov	 ax,DOSMAC	; Get segment of initial MAC entry
NOSPAN_NEXT:
	 mov	 fs,ax		; Address the next MAC entry
	 assume  fs:nothing	; Tell the assembler about it

; Validate the MAC chain

	 cmp	 fs:[0].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short @F	; Jump if so

	 cmp	 fs:[0].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 jne	 short NOSPAN_ERRMAC ; Jump if not
@@:
	 inc	 ax		; Skip over MAC paragraph
	 add	 ax,fs:[0].MAC_NPAR ; Plus # paras in this entry

	 cmp	 ax,dx		; Is this one the spanning entry?
	 jb	 short NOSPAN_NEXT ; Jump if not
	 ja	 short NOSPAN_ERR ; Jump if we passed it???

	 inc	 fs:[0].MAC_NPAR ; Include the spanning entry

	 mov	 fs,ax		; Address the spanning entry
	 assume  fs:nothing	; Tell the assembler about it

; Save the spanning entry to restore later

	 mov	 eax,fs:[0].EDD ; Get 1st four bytes
	 mov	 OLDSPAN[0],eax ; Save it

	 mov	 eax,fs:[4].EDD ; Get 2nd four bytes
	 mov	 OLDSPAN[4],eax ; Save it

	 mov	 eax,fs:[8].EDD ; Get 3rd four bytes
	 mov	 OLDSPAN[8],eax ; Save it

	 mov	 eax,fs:[12].EDD ; Get 4th four bytes
	 mov	 OLDSPAN[12],eax ; Save it
NOSPAN_DONE:
	 or	 RES_FLAG,@DOS58DIS ; Enable DOS trapping
	 mov	 ax,es:[si].COUNT ; Get count value
	 mov	 DOSCNT,al	; Store

	 mov	 es:[si].STAT,EM_SPAN ; Set status for return

	 jmp	 short NOSPAN_EXIT ; Join common exit code

NOSPAN_ERR:
	 mov	 es:[si].STAT,EM_ERRSPAN ; Set status for return (not present)

	 jmp	 short NOSPAN_EXIT ; Join common exit code

NOSPAN_ERRMAC:
	 mov	 es:[si].STAT,EM_ERRMAC ; Set status for return (MAC error)
NOSPAN_EXIT:
	 REGREST <fs,dx,eax>	; Restore
	 assume  fs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NOSPAN	 endp			; End NOSPAN procedure
	 NPPROC  SPANFREE -- Restore The DOS Spanning Entry
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore the DOS spanning entry.

On entry:

ES:SI	 ==>	 CMDOPT data structure

|

	 REGSAVE <eax,dx,fs>	; Save registers

	 test	 RES_FLAG,@DOS58DIS ; Izit already disabled?
	 jz	 short SPANFREE_DONE ; Jump if not

	 int	 12h		; Get memory size into AX in kilobytes
	 shl	 ax,10-4	; Convert from 1KB to paras
	 mov	 dx,ax		; Save for later use

	 mov	 ax,DOSMAC	; Get segment of initial MAC entry
SPANFREE_NEXT:
	 mov	 fs,ax		; Address the next MAC entry
	 assume  fs:nothing	; Tell the assembler about it

; Validate the MAC chain

	 cmp	 fs:[0].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short @F	; Jump if so

	 cmp	 fs:[0].MAC_TYPE,@MAC_END ; Izit an ending entry?
	 jne	 short SPANFREE_ERRMAC ; Jump if not
@@:
	 inc	 ax		; Skip over MAC paragraph
	 add	 ax,fs:[0].MAC_NPAR ; Plus # paras in this entry

	 cmp	 ax,dx		; Is this one the spanning entry?
	 jb	 short SPANFREE_NEXT ; Jump if not
	 ja	 short SPANFREE_ERR ; Jump if we passed it???

	 dec	 fs:[0].MAC_NPAR ; Make room for the spanning entry

	 mov	 fs,ax		; Address the spanning entry
	 assume  fs:nothing	; Tell the assembler about it

; Restore the spanning entry

	 mov	 eax,OLDSPAN[0] ; Get 1st four bytes
	 mov	 fs:[0].EDD,eax ; Restore it

	 mov	 eax,OLDSPAN[4] ; Get 2nd four bytes
	 mov	 fs:[4].EDD,eax ; Restore it

	 mov	 eax,OLDSPAN[8] ; Get 3rd four bytes
	 mov	 fs:[8].EDD,eax ; Restore it

	 mov	 eax,OLDSPAN[12] ; Get 4th four bytes
	 mov	 fs:[12].EDD,eax ; Restore it
SPANFREE_DONE:
	 and	 RES_FLAG,(not @DOS58DIS) ; Disable DOS trapping
	 mov	 es:[si].STAT,EM_SPANF ; Set return status

	 jmp	 short SPANFREE_EXIT ; Join common exit code

SPANFREE_ERR:
	 mov	 es:[si].STAT,EM_ERRSPAN ; Set status for return (not present)

	 jmp	 short SPANFREE_EXIT ; Join common exit code

SPANFREE_ERRMAC:
	 mov	 es:[si].STAT,EM_ERRMAC ; Set status for return (MAC error)
SPANFREE_EXIT:
	 REGREST <fs,dx,eax>	; Restore
	 assume  fs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SPANFREE endp			; End SPANFREE procedure
	FPPROC	INT21PROC -- Interrupt 21h trap
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DOS interrupt handler

Watch for function 5803h and lie as appropriate.

|

	 push	 ds		; Save for a moment

	 push	 cs		; Get data segment
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 cmp	 ax,(@MACALG shl 8) or 03h ; Is this a 5803h request?
	 jne	 short INT21PROC_ORIG ; Jump if not

	 test	 RES_FLAG,@DOS58DIS ; Should we disable it?
	 jz	 short INT21PROC_ORIG ; Jump if not

	 cmp	 DOSCNT,0	; Are we doing this forever?
	 je	 short INT21PROC_XFN ; Jump if so

	 dec	 DOSCNT 	; Otherwise count down
	 jnz	 short INT21PROC_XFN ; Did counter run dry? nope go.

	 and	 RES_FLAG,(not @DOS58DIS) ; Disable DOS trapping

	 jmp	 short INT21PROC_ORIG ; Continue with original handler

INT21PROC_XFN:
	 mov	 ax,@DOSERR_XFN ; Mark as invalid function

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 iret			; Return to caller

INT21PROC_ORIG:
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 jmp	 OLD21PROC	; Pass to next procedure

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT21PROC endp			; End INT21PROC
	FPPROC	XMSTRAP -- XMS request processor
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;
; watches XMS size request function 8 and 88
;

	 jmp	 $+5		; Dummy XMS jump header
	 nop			;
	 nop			;
	 nop			;

	 test	 RES_FLAG,@LIMITXMS ; Is XMS limiting enabled?
	 jz	 short @F	; No, exit

	 cmp	 ah,@XMS_QRYXMB ; Is this a size request
	 je	 short XMST10	; Yes, Join common code

	 cmp	 ah,@XMS_QRY2XMB ; Is this a size request
	 je	 short XMST10	; No, Join common exit code
@@:
	 jmp	 XMSJMP 	; Transfer control to original processor

XMST10:
	 push	 bp		;

	 REGSAVE <ebx,esi,edi,ds> ; Save

	 push	 cs		; Set DS to...
	 pop	 ds		; code segment for faster reference
	 assume  ds:PGROUP	; Tell assembler

	 push	 ax		; Save the call type

	 cmp	 XMSCNT,0	; Are we doing this forever
	 je	 short @F	; Yep, go

	 dec	 XMSCNT 	; Count down
	 jnz	 short @F	; Last time to do this?

	 and	 RES_FLAG,(not @LIMITXMS) ; Yep, turn off limiting switch
@@:
	 REGSAVE <eax,ecx,edx>	; Save so we don't trash upper 16 bits

	 mov	 ah,@XMS_QRY2XMB ; Query call
	 call	 XMSJADR	; Call old handler

	 mov	 bp,bx		; Save error code
	 or	 bl,bl		; Set Z if no error

	 mov	 ebx,eax	; Move status to general purpos regs
	 mov	 esi,ecx	;
	 mov	 edi,edx	;
	 REGREST <edx,ecx,eax>	; Restore

	 jnz	 short XMST50	; Don't adjust things if we got an error

	 sub	 edi,XMSLIM	; Subtract the amount to reserve
	 jnc	 short @F	; Is there any left over?

	 mov	 edi,0		; Nope, tell them we have none

	 and	 bp,0ff00h	; And set status to refelect so
	 or	 bp,0a0h	;
@@:
	 cmp	 ebx,edi	; Is the largest block more than whats left?
	 jbe	 short XMST50	; Nope, go

	 mov	 ebx,edi	; Trim down the largest block
XMST50:
	 pop	 ax		; Restore call type

	 cmp	 ah,@XMS_QRYXMB ; Is this a 2.0 query request
	 jne	 short XMST60	; No, go process 3.0 call

	 mov	 ax,bx		; Set up 2.0 return registers
	 mov	 dx,di		;

	 cmp	 ebx,10000h	; Is the value to big for the register
	 jb	 short @F	; No, go

	 mov	 ax,-1		; Yes, make it the max then
@@:
	 cmp	 edi,10000h	; Is the value to big for the register
	 jb	 short XMST80	; No, go

	 mov	 dx,-1		; Yes, make it the max then
	 jmp	 short XMST80	; Exit
XMST60:
	 mov	 eax,ebx	; Restore 3.0 format call status
	 mov	 ecx,esi	;
	 mov	 edx,edi	;
XMST80:

	 REGREST <ds,edi,esi,ebx> ; Restore
	 assume  ds:nothing	; Tell assembler

	 mov	 bx,bp		; Restore status of call

	 pop	 bp		;
XMSTRAP_RETF:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

XMSTRAP endp			; End XMSTRAP
	NPPROC	FREEXMS -- Free any reserved XMS memory
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	REGSAVE <ax,bx,cx,dx,di>

	mov	cx,XALOCNUM	; Number of XMS allocation saved
	jcxz	short XMSF_EXIT ; Any? No, go on

	lea	di,XALOCTBL	; Get pointer to table
@@:
	mov	dx,[di] 	; Get handle to free

	mov	ah,@XMS_UNLXMB	; Unlock block of XMS memory function
	call	XMSPTR		; Request XMS service

	mov	ah,@XMS_RELXMB	; Release XMS memory function
	call	XMSPTR		; Request XMS service

	add	di,type XALOCTBL ; Bump pointer
	loop	short @B	;

	mov	XALOCNUM,0	; Clear number of XMS allocation saved
XMSF_EXIT:
	REGREST <di,dx,cx,bx,ax>

	ret

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FREEXMS endp			; End FREEXMS
	 NPPROC  REMOVE -- Remove resident code from memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 test	 RES_FLAG,@RES	; Are we the resident copy?
	 jnz	 short @F	; Jump if so.

	 mov	 es:[si].STAT,EM_C4F ; Tell them we are not installed yet

	 jmp	 REM090 	; Join common error
@@:
	 call	 FREEXMS	; Free any XMS memory we reserved

	 push	 es		; Save for a while

; Ensure that we also own the other interrupt handlers

	 call	 CHECK_INTS	; Check 'em out
	 jc	 short REM080	; Jump if we don't own all the others

	 les	 bx,XMSPTR	; Get the XMS call pointer
	 mov	 ax,es		; Make sure the pointer is valid
	 or	 ax,bx		;
	 jz	 short @F	; Zero is a bad pointer

	 mov	 ax,cs		; Move for compare
	 cmp	 es:[bx+3],ax	; Are we still in control?
	 jne	 short REM080	; Nope, abort removal

	 push	 si		; Save
	 lea	 si,XMSJMP	; Pointer to XMS jump original state
	 pushf			; Flags away
	 cli			; No interruptions please.
	 mov	 al,[si].OPCD	; Read old opcode
	 mov	 es:[bx].OPCD,al ; Store original op code
	 mov	 ax,[si].JADR.VOFF ; Get old offset
	 mov	 es:[bx].JADR.VOFF,ax ; Store original offset
	 mov	 ax,[si].JADR.VSEG ; Get old segment
	 mov	 es:[bx].JADR.VSEG,ax ; Store original segment
	 popf			; Return interrupts to original state
	 pop	 si		; Restore
@@:
	 push	 ds		; Save
	 lds	 dx,OLD21PROC	; Get address of original 21h processor
	 assume  ds:nothing	; Tell assembler

	 mov	 al,21h 	; DOS interrupt number
	 DOSCALL @SETINT	; Return int 21h to original processor

	 pop	 ds		; Restore ..
	 assume  ds:PGROUP	; Tell assembler

	 push	 ds		; Save
	 lds	 dx,OLD2FPROC	; Get address of original 2F processor
	 assume  ds:nothing	; Tell assembler

	 mov	 al,2Fh 	; XMS interrupt number
	 DOSCALL @SETINT	; Return int 2F to original processor

	 pop	 ds		; Restore ..
	 assume  ds:PGROUP	; Tell assembler

	 push	 ds		; and save again

	 lds	 dx,OLD67PROC	; Get old EMS int vector
	 assume  ds:nothing	; Tell assembler

	 mov	 al,67h 	; Int value
	 DOSCALL @SETINT	; Return int EMS to original processor

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell assembler

	 pop	 es		; Restore
	 assume  es:nothing	; Lie to assembler

	 mov	 es:[si].STAT,EM_C3F ; Set flag in non-resident portion

; ----- Free our program space

	 mov	 dx,UMBSEG	; Get UMB segment
	 or	 dx,dx		; Did we load into an UMB
	 jz	 short @F	; No, go free low DOS allocation

	 mov	 ah,@XMS_RELUMB ; Free UMB
	 call	 XMSPTR 	; Request XMS service

	 jmp	 short REM090	; Join common exit code
@@:
	 mov	 ax,CMDPTR.VOFF ; Did we enter via the...
	 or	 ax,CMDPTR.VSEG ; device driver interface?
	 jnz	 short REM090	; Don't free DOS memory if so

	 mov	 es,PSPPTR	; Get psp segment
	 assume  es:nothing	; Lie to assembler

	 DOSCALL @RELMEM	; Tell dos to free our mem block (ES)

	 jmp	 short REM090	; Join common error

REM080:
	 pop	 es		; Restore
	 assume  es:nothing	; Lie to assembler

	 mov	 es:[si].STAT,EM_C2F ; Set message flag
REM090:
	 mov	 ah,8FH 	; Internal error code

	 ret			; Back to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REMOVE	endp			; End REMOVE
	 NPPROC  CHECK_INTS -- Check Ownership Of Interrupts
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on the ownership of interrupts before we restore them

On exit:

CF	 =	 0 if we own all the ones we will restore
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,es>	; Save registers

	 test	 RES_FLAG,@HOOK67 ; Did we hook 67?
	 jnz	 @F

	 mov	 al,67h 	; Function to get EMM Interrupt
	 DOSCALL @GETINT	; Return with ES:BX ==> current handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es		; Put segment in a safe place

	 cmp	 ax,NEW67SEG	; Izit pointing to us?
	 jne	 short CHECK_INTS_ERR ; No, well it can't be removed then

@@:
	 mov	 al,21h 	; DOS interrupt number
	 DOSCALL @GETINT	; Return with ES:BX ==> current handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es		; Copy segment

	 cmp	 ax,LODSEG	; Izit pointing to us?
	 jne	 short CHECK_INTS_ERR ; No, well it can't be removed then

	 mov	 al,2Fh 	; Function to get XMS vector
	 DOSCALL @GETINT	; Return with ES:BX ==> current handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es		; Copy segment

	 cmp	 ax,LODSEG	; Izit pointing to us?
	 jne	 short CHECK_INTS_ERR ; No, well it can't be removed then

	 clc			; Indicate we own 'em all

	 jmp	 short CHECK_INTS_EXIT ; Join common exit code

CHECK_INTS_ERR:
	 stc			; Indicate we don't own 'em all
CHECK_INTS_EXIT:
	 REGREST <es,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_INTS endp 		; End CHECK_INTS procedure
	 FPPROC  DEV_STRA -- Device driver strategy
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 push	 ds		; Save for a moment

	 push	 cs		; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 CMDPTR.VOFF,bx ; Save header offset
	 mov	 CMDPTR.VSEG,es ; Save header segment

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to DOS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_STRA endp			; End DEV_STRA
	 FPPROC  STUB_INTR -- Device driver resident interrupt processor
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 push	 ds		; Save

	 lds	 bx,CMDPTR	; Get pointer to cmd packet
	 assume  ds:nothing	; Lie to assembler

	 mov	 [bx].SRH_STA,(8100h or ERR_UGH) ; Set status in Request header

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell assembler

	 ret			; Back to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STUB_INTR endp			; End STUB_INTR

	public TSREND
TSREND	label	near

CODE	ends			; End segment

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TSR portion ends here ;;;;;;;;;;;;;;;;;

subttl Code segment Initialization Data
page +
NDATA	 segment		; Start NDATA segment
	 assume  ds:PGROUP


	 public  INFO_CTL,INFO,INFOSIZE
	 include QMAXINFO.INC
	 align	 2		; Force even alignment for INFO_STR
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
INFOSIZE equ	 size INFO_STR

	 public  OLDINT21_VEC,DPMIDRV_VEC,OLDSTK_VEC
OLDINT21_VEC dd  ?		; Seg:Off of old INT 21h handler
DPMIDRV_VEC dd	 ?		; Seg:Off of DPMI switch entry point
OLDSTK_VEC dd	 ?		; Seg:Off of old stack

LCL_FLAG db	 0		; Local flags
 @XMSFOUND equ	 80h		; XMS services found
 @INSTALLED equ  20h		; MEMLIMIT already installed

MEMAPI	   dd	 0		; MEMLIMIT API

	public CMDPACK
CMDPACK     CMDPKT <0,0,0,0>	; Command packet


CMD_MAC  macro	 TXT,SW,FLAG
	 local	 L1,L2

NTEXT	 segment		; Start NTEXT segment
	 assume  ds:PGROUP

L1	 db	 TXT		; The command text
L2	 equ	 $-L1		; Length of text string

NTEXT	 ends			; End NTEXT segment

	 CMDOPT <PGROUP:L1,L2,SW,FLAG>

	 endm			; CMD_MAC

	 public CMDSWTCH,CMDS
CMDSWTCH label	 tbyte
	 CMD_MAC 'VCPIFREE', @VCPI_SW2
	 CMD_MAC 'VCPI',     @VCPI_SW,  <@OPT_CNT or @OPT_LIM>
	 CMD_MAC 'EMSFREE',  @EMS_SW2
	 CMD_MAC 'EMS',      @EMS_SW,   <@OPT_CNT or @OPT_LIM>
	 CMD_MAC 'XMSFREE',  @XMS_SW2
	 CMD_MAC 'XMS',      @XMSL_SW,  <@OPT_CNT or @OPT_LIM>
	 CMD_MAC 'NOXMS',    @XMS_SW,    @OPT_CNT
	 CMD_MAC 'DPMIFREE', @DPMI_SW2
	 CMD_MAC 'NODPMI',   @DPMI_SW,   @OPT_CNT
	 CMD_MAC 'REMOVE',   @REM_SW
	 CMD_MAC '/?',       @HLP_SW
	 CMD_MAC 'WIN30FREE',@W30_SW2
	 CMD_MAC 'WIN30',    @W30_SW
	 CMD_MAC 'SWAPFREE', @NSWP_SW2
	 CMD_MAC 'NOSWAP',   @NSWP_SW,   @OPT_CNT
	 CMD_MAC 'SPANFREE', @DOS_SW2
	 CMD_MAC 'NOSPAN',   @DOS_SW,    @OPT_CNT
CMDS	 equ	 ($-CMDSWTCH)/(type CMDOPT) ; Number of command line keywords

	 public  DPMIMAX
DPMIMAX  db	 '386MAX',0     ; VM VSAPI name

	public MSG_NSUP
ifdef LANG_GR
MSG_NSUP    db	'Function not currently supported.',CR,LF,EOS
else
MSG_NSUP    db	'Function not currently supported.',CR,LF,EOS
endif

	public MSG_BADCMD, MSG_BADVCPI, MSG_VCPI
ifdef LANG_GR
MSG_BADCMD  db	'TSR meldete unbekannten Aufruf-Fehler.',CR,LF,EOS
MSG_BADVCPI db	'ungÅltiger Parameter fÅr VCPI-Begrenzung benutzt.',CR,LF,EOS
MSG_VCPI    db	'VCPI-Begrenzung gesetzt.',CR,LF,EOS
else
MSG_BADCMD  db	'TSR reported an unknown request error.',CR,LF,EOS
MSG_BADVCPI db	'Invalid parameter used for VCPI limit.',CR,LF,EOS
MSG_VCPI    db	'VCPI limit set.',CR,LF,EOS
endif				; IFDEF LANG_GR

	public MSG_BADEMS, MSG_EMS, MSG_DPMI
ifdef LANG_GR
MSG_BADEMS  db	'ungÅltiger Parameter fÅr EMS-Begrenzung benutzt.',CR,LF,EOS
MSG_EMS     db	'EMS-Begrenzung gesetzt.',CR,LF,EOS
MSG_DPMI    db	'DPMI abgeschaltet.',CR,LF,EOS
else
MSG_BADEMS  db	'Invalid parameter used for EMS limit.',CR,LF,EOS
MSG_EMS     db	'EMS limit set.',CR,LF,EOS
MSG_DPMI    db	'DPMI disabled.',CR,LF,EOS
endif				; IFDEF LANG_GR

	public MSG_XMS, MSG_XMSL, MSG_C2F
ifdef LANG_GR
MSG_XMS     db	'XMS abgeschaltet.',CR,LF,EOS
MSG_XMSL    db	'XMS-Begrenzung gesetzt.',CR,LF,EOS
MSG_C2F     db	'kann TSR nicht entfernen.',CR,LF,EOS
else
MSG_XMS     db	'XMS disabled.',CR,LF,EOS
MSG_XMSL    db	'XMS limit set.',CR,LF,EOS
MSG_C2F     db	'Unable to remove TSR.',CR,LF,EOS
endif				; IFDEF LANG_GR

	public MSG_C3F, MSG_C4F, MSG_SIGNON
ifdef LANG_GR
MSG_C3F     db	'MemLimit aus dem Speicher entfernt.',CR,LF,EOS
MSG_C4F     db	'MemLimit ist nicht resident im System.',CR,LF,EOS
MSG_SIGNON  db	'MEMLIMIT  -- Version ',VERS_H,'.',VERS_T,VERS_U,' -- Ein Dienstprogramm zur Speicherbegrenzung',CR,LF
	    db	'   (C) Copyright 1991-96 Qualitas, Inc.  Alle Rechte vorbehalten.',CR,LF,EOS
else
MSG_C3F     db	'MemLimit successfully remove from memory.',CR,LF,EOS
MSG_C4F     db	'MemLimit is not resident in the system.',CR,LF,EOS
MSG_SIGNON  db	'MEMLIMIT  -- Version ',VERS_H,'.',VERS_T,VERS_U,' -- A Memory Limiting Utility',CR,LF
	    db	'   (C) Copyright 1991-96 Qualitas, Inc.  All rights reserved.',CR,LF,EOS
endif				; IFDEF LANG_GR

	public MSG_NOTPRES, MSG_SYNTAX, MSG_NOXMS, MSG_WIN1, MSG_WINDOWS_NFG
ifdef LANG_GR
MSG_NOTPRES db	'kann Qualitas MAX/BLUEMAX nicht finden.',CR,LF,EOS
MSG_SYNTAX  db	'ungÅltige Option in der Befehlszeile.',CR,LF,EOS
MSG_NOXMS   db	'XMS-Service nicht vorhanden.',CR,LF,EOS
MSG_WIN1    db	'kein nicht-zugewiesener XMS-Speicher oberhalb 16 MB.',CR,LF,EOS
MSG_WINDOWS_NFG db 'Kann MEMLIMIT nicht unter Windows im erweiterten Modus ausfÅhren',CR,LF,EOS
else
MSG_NOTPRES db	'Unable to find Qualitas MAX/BLUEMAX.',CR,LF,EOS
MSG_SYNTAX  db	'Invalid command line option.',CR,LF,EOS
MSG_NOXMS   db	'No XMS services available.',CR,LF,EOS
MSG_WIN1    db	'No unallocated XMS memory above 16Mb.',CR,LF,EOS
MSG_WINDOWS_NFG db 'Cannot run MEMLIMIT under Windows Enhanced mode',CR,LF,EOS
endif				; IFDEF LANG_GR

	public MSG_WIN2, MSG_WIN3, MSG_WIN4, MSG_WIN5
ifdef LANG_GR
MSG_WIN2    db	'kein freier XMS-Speicher.',CR,LF,EOS
MSG_WIN3    db	'XMS-Speicher oberhalb 16 MB wurde zugewiesen.',CR,LF,EOS
MSG_WIN4    db	'zugewiesener Speicher oberhalb 16 MB ist jetzt frei.',CR,LF,EOS
MSG_WIN5    db	'XMS-Zuweisungs-Tabelle ist voll.',CR,LF,EOS
else
MSG_WIN2    db	'No free XMS memory.',CR,LF,EOS
MSG_WIN3    db	'XMS memory above 16Mb has been allocated.',CR,LF,EOS
MSG_WIN4    db	'Allocated memory above 16Mb is now free.',CR,LF,EOS
MSG_WIN5    db	'XMS allocation table full.',CR,LF,EOS
endif				; IFDEF LANG_GR

	public MSG_VDSE
ifdef LANG_GR
MSG_VDSE    db	'unerwarteter VDS-Fehler aufgetreten.',CR,LF,EOS
else
MSG_VDSE    db	'Unexpected VDS failure.',CR,LF,EOS
endif				; IFDEF LANG_GR
	public MSG_XMSF
ifdef LANG_GR
MSG_XMSF    db	'XMS Begrenzung wurde aufgehoben.',CR,LF,'$'
else
MSG_XMSF    db	'XMS limitations have been removed.',CR,LF,'$'
endif
	public MSG_VCPIF
ifdef LANG_GR
MSG_VCPIF   db	'VCPI Begrenzung wurde aufgehoben.',CR,LF,'$'
else
MSG_VCPIF   db	'VCPI limitations have been removed.',CR,LF,'$'
endif
	public MSG_EMSF
ifdef LANG_GR
MSG_EMSF    db	'EMS Begrenzung wurde aufgehoben.',CR,LF,'$'
else
MSG_EMSF    db	'EMS limitations have been removed.',CR,LF,'$'
endif
	public MSG_WINF
ifdef LANG_GR
MSG_WINF    db	'Windows 3.0 XMS Begrenzung wurde aufgehoben.',CR,LF,'$'
else
MSG_WINF    db	'Windows 3.0 XMS limitations have been removed.',CR,LF,'$'
endif
	public MSG_DPMIF
ifdef LANG_GR
MSG_DPMIF   db	'DPMI Begrenzung wurde aufgehoben.',CR,LF,'$'
else
MSG_DPMIF   db	'DPMI limitations have been removed.',CR,LF,'$'
endif
	 public  MSG_SWAP,MSG_SWAPF
ifdef LANG_GR
MSG_SWAP db	 'SWAPFILE abgeschaltet.',CR,LF,EOS
MSG_SWAPF db	 'SWAPFILE Begrenzung wurde aufgehoben.',CR,LF,EOS
else
MSG_SWAP db	 'SWAPFILE disabled.',CR,LF,EOS
MSG_SWAPF db	 'SWAPFILE limitations have been removed.',CR,LF,EOS
endif

	 public  MSG_SPAN,MSG_SPANF
ifdef LANG_GR
MSG_SPAN db	 'DOS Span Eintrag abgeschaltet.',CR,LF,EOS
MSG_SPANF db	 'DOS Span Eintrag aktiviert.',CR,LF,EOS
MSG_ERRSPAN db	 'DOS Span Eintrag nicht vorhanden.',CR,LF,EOS
MSG_ERRMAC db	 'Fehler in Speicher-Zuordnungskette.',CR,LF,EOS
else
MSG_SPAN db	 'DOS spanning entry is disabled.',CR,LF,EOS
MSG_SPANF db	 'DOS spanning entry is enabled.',CR,LF,EOS
MSG_ERRSPAN db	 'DOS spanning entry is not present.',CR,LF,EOS
MSG_ERRMAC db	 'Memory allocation chain error.',CR,LF,EOS
endif

	public MSG_HELP
MSG_HELP    label byte
ifdef LANG_GR
	    db	'éndert Typ u. Grî·e des von Qualitas MAX/BlueMAX ermittelten verfÅgb. Speichers.',CR,LF
	    db	'ZulÑssige Befehlszeilen-Optionen:',CR,LF
	    db	'  EMS    - begrenzt verfÅgbaren EMS Speicher (mit EMSFREE freigeben)',CR,LF
	    db	'  VCPI   - begrenzt verfÅgbaren VCPI Speicher (mit VCPIFREE freigeben)',CR,LF
	    db	'  XMS    - begrenzt verfÅgbaren XMS Speicher (mit XMSFREE freigeben)',CR,LF
	    db	'  NODPMI - schaltet DPMI Speicher ab (mit DPMIFREE freigeben)',CR,LF
	    db	'  NOXMS  - schaltet XMS Speicher ab (mit XMSFREE freigeben)',CR,LF
	    db	'  NOSWAP - schaltet DPMI Swapfile aus (mit SWAPFREE einschalten)',CR,LF

	    db	'  REMOVE - entfernt TSR aus dem Speicher.',CR,LF
	    db	'  WIN30  - belegt gesamten XMS Speicher Åber 16 MB (mit WIN30FREE freigeben)',CR,LF
;	    db	'  EMS    - begrenzt verfÅgbaren EMS-Speicher',CR,LF
;	    db	'  VCPI   - begrenzt verfÅgbaren VCPI-Speicher',CR,LF
;	    db	'  XMS    - begrenzt verfÅgbaren XMS-Speicher',CR,LF
;	    db	'  NODPMI - schaltet DPMI-Speicher aus',CR,LF
;	    db	'  NOXMS  - schaltet XMS-Speicher aus',CR,LF
;	    db	'  REMOVE - entfernt TSR aus dem Speicher',CR,LF
;	    db	'  WIN30  - ordnet allen XMS-Speicher oberhalb 16 MB zu',CR,LF
	    db	'  NOSPAN - schaltet den DOS Span Eintrag ab. (mit SPANFREE aktivieren)',CR,LF
	    db	'--> Die EMS-, VCPI- und XMS-Schalter erfordern ein nachfolgendes = Zeichen',CR,LF
	    db	'    mit einem Dezimalwert zur Einstellung der maximalen Grî·e. Allen Schal-',CR,LF
	    db	'    tern au·er REMOVE und WIN30 kann ein Komma folgen mit einem wahlfreien',CR,LF
	    db	'    ZÑhler.',CR,LF
	    db	'Beispiel: MEMLIMIT ems=100 nodpmi,0',CR,LF,LF
	    db	'Der erste Wert jedes Schalters ist die maximale Seitenzahl, der zweite legt',CR,LF
	    db	'fest, wie oft der erste Wert wiedergeben wird, bevor er inaktiv wird. Die',CR,LF

	    db	'Seitengrî·e ist im Raster: 16 KB fÅr EMS, 4 KB fÅr VCPI und 1 KB fÅr XMS,',CR,LF
	    db	'wenn dem ersten Wert nicht ein "K" folgt (z.B. ems=100k); "K" gibt die Grî·e',CR,LF
	    db	'in Einheiten von 1KB an. Der zulÑssige Bereich fÅr den ZÑhler ist 0-255.',CR,LF
	    db	'Ein ZÑhlerwert 0 (Null) bewirkt fortlaufende Anforderung. Obiges Beispiel',CR,LF
	    db	'begrenzt EMS-Speicher auf 100 16-KB-Seiten fÅr einen Aufruf und schaltet',CR,LF
	    db	'DPMI dauerhaft ab.',CR,LF
else
	    db	'Changes the type and amount of available memory reported by Qualitas MAX/BlueMAX',CR,LF
	    db	'The following are valid command line options:',CR,LF
	    db	'  EMS    - to limit EMS memory available. (EMSFREE to cancel)',CR,LF
	    db	'  VCPI   - to limit VCPI memory available. (VCPIFREE to cancel)',CR,LF
	    db	'  XMS    - to limit XMS memory available. (XMSFREE to cancel)',CR,LF
	    db	'  NODPMI - to disable DPMI memory. (DPMIFREE to cancel)',CR,LF
	    db	'  NOXMS  - to disable XMS memory. (XMSFREE to cancel)',CR,LF
	    db	'  NOSWAP - to disable the DPMI swapfile. (SWAPFREE to cancel)',CR,LF
	    db	'  REMOVE - to remove TSR from memory',CR,LF
	    db	'  WIN30  - allocate all XMS memory above 16Mb. (WIN30FREE to cancel)',CR,LF
	    db	'  NOSPAN - to disable the DOS spanning entry. (SPANFREE to cancel)',CR,LF
	    db	'Note: The XMS, EMS, and VCPI keywords must be followed by an equal sign and a',CR,LF
	    db	'      decimal value setting the maximum amount to report.  All the keywords',CR,LF
	    db	'      except REMOVE and WIN30 may be followed by a comma and an optional count.',CR,LF
	    db	'Example: MEMLIMIT ems=100 nodpmi,0',CR,LF,LF
	    db	'The first value in each keyword is the maximum number of pages to report, and',CR,LF
	    db	'the second is the number of times to report the first value before going',CR,LF
	    db	'inactive.  The size of a page is in increments of 16KB for EMS, 4KB for VCPI,',CR,LF
	    db	'and 1KB for XMS unless the first value is followed by a "k" (e.g., ems=100k) in',CR,LF
	    db	'which case the size is in units of 1KB.  The valid range for the count is 0-255.',CR,LF
	    db	'A count of 0 continues the request forever.  The example limits EMS memory to',CR,LF
	    db	'100 16KB pages for one call, and disables the DPMI services forever.',CR,LF,EOS
endif				; IFDEF LANG_GR

	public MSG_QHLP
ifdef LANG_GR
MSG_QHLP    db	'Hilfe erhalten Sie mit /? ',CR,LF,EOS
else
MSG_QHLP    db	'Use /? for help',CR,LF,EOS
endif				; IFDEF LANG_GR

	public DEVNAME
DEVNAME     db	'386MAX$$',0    ; MAX's driver name
	public VDD
VDD	DDS_STR <>		; Structure for VDS calls


MSG_MAC  macro	 NAM

	 dw	 PGROUP:MSG_&NAM

% EM_&NAM equ	 CNT+0		; Assign a number to the equate
CNT	 =	 CNT+1		; Skip to the next number in sequence

	 endm			; MSG_MAC

CNT	 =	 0		; Initialize for origin-0 indexing

	 public  MSG_TBL
MSG_TBL  label	 word
	 MSG_MAC BADCMD
	 MSG_MAC BADVCPI
	 MSG_MAC VCPI
	 MSG_MAC BADEMS
	 MSG_MAC EMS
	 MSG_MAC DPMI
	 MSG_MAC XMS
	 MSG_MAC C2F
	 MSG_MAC C3F
	 MSG_MAC C4F
	 MSG_MAC NOTPRES
	 MSG_MAC HELP
	 MSG_MAC XMSL
	 MSG_MAC NOXMS
	 MSG_MAC WIN1
	 MSG_MAC WIN2
	 MSG_MAC WIN3
	 MSG_MAC WIN4
	 MSG_MAC WIN5
	 MSG_MAC VDSE
	 MSG_MAC XMSF
	 MSG_MAC VCPIF
	 MSG_MAC EMSF
	 MSG_MAC WINF
	 MSG_MAC DPMIF
	 MSG_MAC SWAP
	 MSG_MAC SWAPF
	 MSG_MAC SPAN
	 MSG_MAC SPANF
	 MSG_MAC ERRMAC
	 MSG_MAC ERRSPAN
	 MSG_MAC NSUP

XMSTBLENTS equ 256

	public XMSTBL
XMSTBL	dd	XMSTBLENTS dup (0)

NDATA	 ends			; End NDATA segment


NCODE	 segment		; Start NCODE segment
	 assume  cs:PGROUP

	 FPPROC  DEV_INTR -- Device driver interrupt processor
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

|

	 REGSAVE <ds,es,si,di,dx,cx,bx,ax> ; Save untill exit

	 push	 cs		; Set DS to...
	 pop	 ds		; code segment for data reference
	 assume  ds:PGROUP	; Tell assembler

	 les	 bx,CMDPTR	; Get pointer to cmd packet
	 assume  es:nothing	; Tell assembler

	 mov	 es:[bx].INIT_UNITS,0 ; Set unit field to 0
	 mov	 es:[bx].INIT_END_VEC.VOFF,0 ; Set initial program memory...
	 mov	 es:[bx].INIT_END_VEC.VSEG,cs ; useage to zero

	 mov	 LODSEG,cs	; Set initial resident code segment to low DOS

	 DOSCALL @STROUT,MSG_SIGNON ; Display a signon message

	 call	 ISMAX		; Is 386MAX in the system?
	 jnc	 short @F	; Yep, keep going

	 DOSCALL @STROUT,MSG_NOTPRES ; Tell 'em 386MAX.SYS is not present

	 mov	 ax,(8000h or ERR_UGH) ; Error code to set in RH

	 jmp	 DEVI090	; Join common exit code

@@:
	 mov	 es:[bx].INIT_END_VEC.VOFF,offset PGROUP:TSREND ; Set correct ending address

	 call	 INST_CHK	; Run the test for previous installation

	 test	 LCL_FLAG,@INSTALLED ; Have we been run before?
	 jnz	 short @F	; Yes, don't install interrrupts

	 call	 INST_RES	; Install interrupts

@@:
	 les	 bx,CMDPTR	; Get pointer to cmd packet
	 assume  es:nothing	; Tell assembler

	 les	 bx,es:[bx].INIT_CMD_VEC ; Get pointer to command line
	 assume  es:nothing	; Tell assembler

	 call	 PREPARSE	; Pre-process command line

	 mov	 ax,1		; Set end of line error as default

	 cmp	 cx,1		; Did they type a command line?
	 jbe	 short DEVI050	; If it's more than 1 byte try to parse it

	 lea	 si,CMDPACK	; Get pointer to command structure
DEVI030:
	 call	 PARSE		; Parse command string
	 jc	 short DEVI050	; Go if error

	 cmp	 [si].CMD,@HLP_SW ; Is it a help request?
	 je	 short DEVI050	; Yes, ignore it

	 cmp	 [si].CMD,@W30_SW ; Is it the windows mem alloc request?
	 jne	 short DEVI040	; No, go

	 call	 WINALLOC	; Allocate all available XMS mem above 16mb

	 jmp	 short DEVI050	; Bypass resident code call
DEVI040:
	 call	 MEMAPI 	; . . .

	 REGSAVE <ax>		; Save call status

	 mov	 di,[si].STAT	; Use the command status to index ...
	 shl	 di,1		; the message table
	 mov	 dx,MSG_TBL.[di] ; Get message offset
	 DOSCALL @STROUT	; Print the failure type and exit

	 REGREST <ax>		; Retrieve call status
DEVI050:
	 cmp	 ax,1		; Are we finished?
	 je	 short DEVI060	; Yes, go

	 test	 ah,-1		; Was there an error?
	 jz	 short DEVI030	; No, process another command

	 call	 REMOVE_RES	; Remove resident hooks

	 les	 bx,CMDPTR	; Get pointer to cmd packet
	 assume  es:nothing	; Tell assembler

	 mov	 es:[bx].INIT_END_VEC.VOFF,0 ; Set ending address to zero

	 mov	 ax,(8000h or ERR_UGH) ; Error code to set in RH

	 jmp	 short DEVI090	; Join common exit code
DEVI060:
	 test	 LCL_FLAG,@INSTALLED ; Do we need to stay resident?
	 jnz	 short DEVI070	; No, we are already installed

	 push	 ds		; Save

	 mov	 ds,LODSEG	; Reload DS so we may touch resident data
	 assume  ds:PGROUP	; Lie to assembler (maybe)

	 or	 RES_FLAG,@RES	; Set internal flag signifing we are resident

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell assembler

	 test	 UMBSEG,-1	; Did we load into a UMB?
	 jz	 short DEVI090	; No, do normal termination

DEVI070:
	 mov	 DEVDRV.DD_ATTR,0 ; Set attribute to block type
	 mov	 DEVDRV.DD_NAME,0 ; Set unit field to 0

	 les	 bx,CMDPTR	; Get pointer to cmd packet
	 assume  es:nothing	; Tell assembler

	 mov	 es:[bx].INIT_END_VEC.VOFF,0 ; Set ending address to zero

DEVI090:
	les	bx,CMDPTR	; Get pointer to cmd packet
	assume	es:nothing	; Tell assembler

	or	ah,1		; Set done bit

	mov	es:[bx].SRH_STA,ax ; Set status in Request header

	mov	DEVDRV.DD_INTR,offset STUB_INTR ;

	REGREST <ax,bx,cx,dx,di,si,es,ds> ; Restore
	assume	ds:nothing,es:nothing ; Tell assembler

	ret			; Return to DOS

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DEV_INTR endp			; End DEV_INTR
	NPPROC	INIT -- Initialization procedure
	assume	ds:nothing,es:PSPSEG,fs:nothing,gs:nothing,ss:nothing
;
; This procedure prints the sign on banner.  Then checks
; that 386MAX is installed.  If not we return a -1 error
; otherwise we check to see if we are installed. If not we install
; ourselves. Parse the command line and call our installed
; routine to set whatever parameters are requested.
; Note: Several configuration parameters may be set at one time.
;	If a request to deinstall is issued all other parameters
;	are ignored.
;

	 mov	 ax,cs		; Set up our data segment register ..
	 mov	 ds,ax		; to point to code
	 assume  ds:PGROUP	; Tell assembler

	 mov	 PSPPTR,es	; Save the PSP segment

	 mov	 LODSEG,cs	; Set initial resident code segment to low DOS

	 DOSCALL @STROUT,MSG_SIGNON ; Display a signon message

	 call	 ISMAX		; Is 386MAX in the system?
	 jnc	 short @F	; Yep, keep going

	 DOSCALL @STROUT,MSG_NOTPRES ; Tell 'em 386MAX.SYS is not present

	 or	 LCL_FLAG,@INSTALLED ; Set flag; we don't need to replace vectors

	 jmp	 INIT_ERRX	; Join common error exit code

@@:
	 call	 CHECK_WIN3	; Check to see if we are in Windows
	 jnc	 @F		; No Windows, keep on truckin

	 DOSCALL @STROUT,MSG_WINDOWS_NFG ; Tell them we don't do Windows
	 or	 LCL_FLAG,@INSTALLED ; Set flag to abort installation
	 jmp	 INIT_ERRX	; Join common error exit code

@@:
	 call	 INST_CHK	; Run the test for previous installation

	 call	 VMVSAPI_CHK	; Check on VM VSAPI services
				; FIXME !! Do we do this in Device driver?

	 test	 LCL_FLAG,@INSTALLED ; Have we been run before?
	 jnz	 short @F	; Yes so don't install interrrupts

	 call	 INST_RES	; Install resident hooks
	 jmp	 short INIT010	; Bypass getting XMS pointer we did it in the
				; installation of resident hooks
@@:
; ----- Install the pointer to the XMS services if available
	 GETXSTAT		; Do a XMS status call
	 cmp	 al,80H 	; Is the XMS stuff working?
	 jne	 short INIT010	; No, don't futs with it then

	 GETXPTR		; Get a pointer to XMS handler in es:bx
	 assume  es:nothing	; Tell assembler

	 mov	 XMSPTR.VOFF,bx ; Save the XMS call offset
	 mov	 XMSPTR.VSEG,es ; Save the XMS call segment

; ----- check the command line length parse it if we can
INIT010:
	 mov	 es,PSPPTR	; Get a segment for PSP access
	 assume  es:PSPSEG	; Tell assembler

	 mov	 ch,0		; Get command line length...
	 mov	 cl,PSP_PARM_COUNT ; in CX
	 cmp	 cx,1		; Did they type a command line?
	 ja	 short @F	; If it's more than 1 byte try to parse it

	 DOSCALL @STROUT,MSG_QHLP ; Tell 'em we need a command line

	 jmp	 short INIT090	; Join common error exit code
@@:
	 lea	 bx,PSP_PARM_STRING ; Get command line pointer
	 call	 UPCASE 	; Convert string to upper case alphas

	 lea	 si,CMDPACK	; Get pointer to command structure
	 mov	 dx,0		; Set the command counter to 0
INIT075:
	 push	 dx		; Save counter
	 call	 PARSE		; Parse command string
	 pop	 dx		; Get back counter
	 jc	 short INIT085	; Do we have a valid command packet?

	 inc	 dx		; Yes bump counter

	 cmp	 [si].CMD,@HLP_SW ; Is it a help request?
	 jne	 short @F	; no, go

	 mov	 [si].STAT,EM_HELP ; Yea, set a flag saying print status

	 mov	 ah,8FH 	; Internal error code to print message

	 jmp	 short INIT080	; Bypass EMS call
@@:
	 cmp	 [si].CMD,@W30_SW ; Is it the windows mem alloc request?
	 jne	 short @F	; No, go

	 call	 WINALLOC	; Allocate all available XMS mem above 16mb

	 jmp	 short INIT080	; Bypass resident code call
@@:
	 call	 MEMAPI 	; . . .

	 cmp	 [si].CMD,@NSWP_SW2 ; Izit SWAPFREE?
	 jne	 short @F	; Jump if not

	 call	 CLEAR_SWAP	; Clear the swapfile if possible
@@:
INIT080:
	 REGSAVE <ax,dx>	; Save call status

	 mov	 di,[si].STAT	; Use the command status to index ...
	 shl	 di,1		; the message table
	 mov	 dx,[MSG_TBL+di] ; Get message offset
	 DOSCALL @STROUT	; Print the failure type and exit

	 REGREST <dx,ax>	; Retrieve call status

	 test	 ah,-1		; Was there an error?
	 jz	 short INIT075	; No, process another command

	 jmp	 short INIT_ERRX ; Join common error code
INIT085:
; ----- see if parser returned an error
	 cmp	 ax,-1		; Was the error an EOS
	 je	 short @F	; No, it was something else go

	 or	 dx,dx		; Well did we do anything?
	 jnz	 short INIT_OK	; No, go on
@@:
	 DOSCALL @STROUT,MSG_SYNTAX ; Yea, tell'em syntax error

INIT090:
	jmp	short INIT_ERRX ; Join common error code

INIT_OK:
	 mov	 ax,0		; Everything worked clear error flag.

	 test	 LCL_FLAG,@INSTALLED ; Do we need to stay resident?
	 jnz	 INIT_EXIT	; No, we are already installed

	 mov	 ds,LODSEG	; Reload DS so we may touch resident data
	 assume  ds:PGROUP	; Lie to assembler (maybe)

	 or	 RES_FLAG,@RES	; Set internal flag signifing we are resident

	 test	 UMBSEG,-1	; Did we load into a UMB?
	 jne	 short INIT_EXIT ; Yes, just exit

; ----- Free our environment
	 mov	 es,PSPPTR	; Get psp segment
	 assume  es:PSPSEG	; Tell assembler

	 xor	 ax,ax		; Zero for swap
	 xchg	 ax,es:PSP_ENVIR_PTR ; Get segment of our environment, set to zero
	 mov	 es,ax		; Save segment of our MAC
	 DOSCALL @RELMEM	; Release memory at ES:0

; ----- Terminate and stay resident
	 mov	 dx,PSPPTR	; Compute the...
	 mov	 ax,cs		; number of paragraphs difference between ...
	 sub	 ax,dx		; the PSP and our code segment.
	 lea	 dx,TSREND[16-1] ; Get code ending offset
	 shr	 dx,4		; Convert it to paragraph
	 add	 dx,ax		; Don't forget the PSP
	 DOSCALL @KEEPRC	; Terminate

; ----- Error processing code
INIT_ERRX:

	test	LCL_FLAG,@INSTALLED ; Did we install our interrupts? 0=yes
	jnz	short @F	; No, just return error

	call	REMOVE_RES	; Remove resident hooks
@@:
	mov	al,-1		; Give'em a big reason
INIT_EXIT:
	DOSCALL @EXITRC 	; Return to DOS with exit code in AL

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INIT	endp			; End INIT procedure
	NPPROC	WINALLOC -- XMS memory allocation protection for windows 30
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 pusha			; Save all GP registers
	 push	 es		; Save

	 push	 ds		; Set ES to CODE
	 pop	 es		;
	 assume  es:PGROUP	; Tell assembler

	 push	 bp		;

	 GETXSTAT		; Do a XMS status call
	 cmp	 al,80H 	; Is the XMS stuff working?
	 je	 short @F	; Yes, go do request

	 mov	 [si].STAT,EM_NOXMS ; Message to print no XMS available
	 jmp	 WA_100 	; Goto common error exit
@@:
	 lea	 di,XMSTBL	; Get pointer to XMS handle table
	 xor	 bp,bp		; Zero counter
WA_010:
	 mov	 ah,@XMS_QRYXMB ; Request free/size of XMS memory
	 call	 XMSPTR 	; Request XMS service

	 or	 ax,ax		; Check for some free memory
	 jnz	 short @F	; Go, if some

	 or	 bp,bp		; Did we find any memory?
	 jnz	 short WA_050	; Yes, go process it

	 mov	 [si].STAT,EM_WIN2 ; Message flag (No free XMS over 16m)
	 jmp	 WA_100 	; Goto common error exit
@@:
	 mov	 [di].EHI,ax	; Save number of 1k blocks

	 mov	 dx,ax		; Try to get everything
	 mov	 ah,@XMS_GETXMB ; Allocate XMS memory
	 call	 XMSPTR 	; Request XMS service

	 inc	 bp		;
	 mov	 [di].ELO,dx	; Save handle in table
	 add	 di,type XMSTBL ; Bump pointer

	 jmp	 short WA_010	; Go allocate more memory
WA_050:
	 mov	 cx,bp		; Set loop count

	 lea	 di,XMSTBL	; Reload pointer to XMS handle table
	 mov	 [si].COUNT,0	; Clear counter
WA_060:
	 push	 cx		;
	 mov	 dx,[di].ELO	; Get handle
	 mov	 [si].LIMIT.ELO,dx ; Save for resident call

	 mov	 ah,@XMS_LCKXMB ; Lock block of XMS memory function
	 call	 XMSPTR 	; Request XMS service

	 cmp	 ax,1		; Did lock work?
	 jne	 short WA_090	; No, go
WA_070:
	 mov	 VDD.DDS_FVEC.FSEL,0 ; Selector zero
	 mov	 VDD.DDS_FVEC.FOFF.EHI,dx ; Set 32 bit address
	 mov	 VDD.DDS_FVEC.FOFF.ELO,bx ; Set 32 bit address

	 mov	 ax,1024	; Block size
	 mul	 [di].EHI	; Compute number of bytes in allocation

	 mov	 VDD.DDS_SIZE.ELO,ax ; Save number of bytes...
	 mov	 VDD.DDS_SIZE.EHI,dx ; for this allocation

	 push	 di		; Save for VDS call

	 xor	 dx,dx		; Set VDS flags
	 lea	 di,VDD 	; Get offset of VDD structure
	 VDSCALL @VDS_LOCK	; Attempt to lock DMA region

	 pop	 di		; Restore index
	 jnc	 short @F	; No VDS errors keep going

	 mov	 [si].STAT,EM_VDSE ; Message flag (VDS failure)
	 jmp	 short WA_100	; Goto common error exit
@@:
	 push	 di		; Save for VDS call

	 xor	 dx,dx		; Set VDS flags
	 lea	 di,VDD 	; Get offset of VDD structure
	 VDSCALL @VDS_LOCK	; Unlock DMA region

	 pop	 di		; Restore index

	 cmp	 VDD.DDS_POFF.EHI,100H ; Check < 16MB
	 jae	 short WA_080	; It's over, log it in

	 mov	 dx,[di].ELO	; Get handle again

	 mov	 ah,@XMS_UNLXMB ; Unlock block of XMS memory function
	 call	 XMSPTR 	; Request XMS service

	 mov	 ah,@XMS_RELXMB ; Release XMS memory function
	 call	 XMSPTR 	; Request XMS service

	 jmp	 short WA_090	; Bypass resident call
WA_080:
	 call	 MEMAPI 	; . . .
	 inc	 [si].COUNT	; Bump counter

	 cmp	 ah,0		; Any error
	 jne	 short WA_EXIT	; Yes, exit
WA_090:
	 add	 di,type XMSTBL ; Bump pointer
	 pop	 cx		;
	 loop	 short WA_060	; Do next allocation

	 mov	 ah,0		; Assume no error
	 cmp	 [si].COUNT,0	; Did we pass anything to resident portion
	 jne	 short @F	; Yea, go

	 mov	 [si].STAT,EM_WIN1 ; Message flag (No XMS over 16m)
WA_100:
	 mov	 ah,8FH 	; Internal error code to print message
	 jmp	 short WA_EXIT	; Exit
@@:
	 mov	 ax,0		; Clear error indicator
WA_EXIT:
	 pop	 bp		; Restore
	 pop	 es		;
	 assume  es:nothing	; Tell assembler

	 popa			; Restore all GP registers

	 ret

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

WINALLOC endp
	NPPROC PARSE -- Command line parser
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;
; This routine is called to parse the command line.
; On entry DS:BX should point to the point on the command line to start
; parsing, CX is the length of the command line and DS:SI should point
; to a command packet structure (CMDPKT) the command line will be parsed
; until 1 command has been processed or the end of the command line
; is reached.
; On exit AX will contain the status for the operation, DS:BX will be
; updated to the next portion of the command line to parse, CX will
; refelect the amount of the command line left to parse, and
; the CMDPKT pointer to be DS:SI will hold a valid command to sent to the
; resident portion of the TSR. If AX is not zero the following error condition
; occured AX=1 all commands were parsed succesfully, AX=-1 invalid
; command switch or syntax error.  If AX returns not zero then
; the current command packet is invalid and no additional information may
; be gotten from the unparsed portion of the command line if any.
;
; Registers used: AX,BX,CX,DX,SI,DI
;

	jcxz	PAR010		; We have to have some stuff to parse
@@:
	cmp	es:[bx].LO,' '  ; Is this character a space
	jne	short @F	; No, go see what it is then

	inc	bx		; Yes, bypass it
	loop	short @B	; Go look at next character
PAR010:
	mov	ax,1		; Return that the end of the..
	stc			; command line was reached..
	ret			; and the command packet is invalid
@@:
	REGSAVE <si,cx> 	; Save registers we are going to use

	lea	di,CMDSWTCH	; Get a pointer to start of switch structures
	mov	cx,CMDS 	; Get the number of switches
@@:
	REGSAVE <di,cx> 	; Save registers we are going to use

	mov	cl,[di].LEN	; Get the length of this command string
	mov	ch,0		; Make it a word in CX
	mov	si,[di].SWTCH	; Get pointer to string to check
	mov	di,bx		; Put command line pointer into index reg
	cld			; Direction up
	rep cmpsb		; Compare
	REGREST <cx,di> 	; Restore used
	je	short @F	; Did it match? Yes. go.

	add	di,SIZE CMDOPT	; Change pointer to next structure
	loop	short @B	; Keep checking

	REGREST <cx,si> 	; Restore used
PAR050:
	mov	ax,-1		; No matching switch was found
	stc			; There must be was a syntax error
	ret			; Return error
@@:
	REGREST <cx,si> 	; Restore used
	mov	al,[di].LEN	; Get string length
	cbw			; Make word
	add	bx,ax		; Update pointer to next field
	sub	cx,ax		; Update number of characters left
	jnc	short @F	; Make sure we don't go negative

	xor	cx,cx		; Zero out if < 0
@@:
	mov	al,[di].OPT	; Get the command to send to TSR
	cbw			; Make it a word
	mov	[si].CMD,ax	; Store it in the command packet
	mov	[si].STAT,0	; Zero out the rest of...
	mov	[si].PKTFLG,0	; ...
	mov	[si].LIMIT,0	; the fields...
	mov	[si].COUNT,1	; except the count default to 1 for it

	test	[di].OPTFLG,@OPT_LIM ; Do we have a limit to the switch?
	jz	short @F	; Nope go

	mov	al,'='          ; Delimiter to look for
	call	VALUE		; We have a least one
	jc	short PAR050	; Make sure the is valid (required field)

	mov	[si].LIMIT,eax	; Save it as the limit value

	 cmp	 es:[bx].LO,'K' ; Izit in kilobytes?
	 jne	 short @F	; Jump if not

	 inc	 bx		; Skip over the suffix
	 dec	 cx		; Account for it in the count
	 or	 [si].PKTFLG,@PKT_KILO ; Mark as in kilobytes
@@:
	test	[di].OPTFLG,@OPT_CNT ; Is there a count?
	jz	short @F	; Nope, go

	mov	al,','          ; Delimiter to look for
	call	VALUE		; Yep, get it (optional field no need to check)
	jc	short @F	; Make sure they entered something (optional)

	mov	[si].COUNT,ax	; Save the count value
@@:
	xor	ax,ax		; Clear error flag
	clc			; Clear status flag
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PARSE	endp			; End PARSE
	NPPROC	VALUE -- Get a value from the command string
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;
; On Entry DS:BX point to the command string CX = number of bytes
; in command string.
; Note: DS:BX must point to a field delimiter (=,;)
;
; On Exit DS:BX and CX are updated to next field and EAX has the value
; that was gotten from the command string. Carry will be set if no value
; was contained in the string EAX will also be zero for this condition.
;
;

	jcxz	VAL090		; Verify command line length
@@:
	mov	ah,es:[bx]	; Get a character
	cmp	ah,al		; Is it a vaild delimiter
	je	short @F	; Process next char as a number if it is

	cmp	ah,' '          ; Look for leading spaces...
	jne	short VAL090	; and remove them
	inc	bx		;
	loop	short @B	; Check next character

	jmp	short VAL090	; Goto error routine
@@:
	dec	cx		; Update length...
	inc	bx		; and pointer
	jcxz	VAL090		; Anything left?
@@:
	cmp	es:[bx].LO,' '  ; Is it a trailing space?
	jne	short @F	; Nope it better be a number then

	inc	bx		; Bypass the spaces we find
	loop	short @B	;

	jmp	short VAL090	; We hit the end of the command string exit
@@:
	mov	al,es:[bx].LO	; Get current character
	cmp	al,'-'          ; Is it a negate character
	jne	short @F	; Nope, go

	call	VALUE		; Get the value to negate

	jc	VAL090		; Exit if we had an error

	neg	ax		; Make negative

	jmp	short VAL080	; Go to exit
@@:
	xor	eax,eax 	; Zero accumulators
	mov	edx,eax 	;
@@:
	mov	dl,es:[bx]	; Get the character in question
	sub	dl,'0'          ; Make decimal
	cmp	dl,9		; Make sure it's a number
	ja	short @F	; If it isn't then we are done

	push	edx		; Save
	mov	edx,10		; Adjust AX to add another number in
	mul	edx		;
	pop	edx		; Restore
	add	eax,edx 	; It's a number so add it to the running count
	inc	bx		; Bump pointer to string
	loop	@B		; Do the next character
@@:
VAL080:
	clc			; Clear status flag
	ret			; Return to caller
VAL090:
	mov	eax,0		; No valid number found
	stc			; Set error flag
	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VALUE	endp			; End VALUE
	NPPROC	UPCASE -- Convert string to upper case characters
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;
; Convert the string at es:bx for for cx charaters to upper case
; note: only characters a-z are affected
;

	REGSAVE <bx,cx> 	; Save registers we are going to use

	jcxz	UC090		; Check for something to convert
UC010:
	mov	al,es:[bx]	; Get the character in question
	cmp	al,'a'          ; Is it out of range?
	jb	short @F	; Yes, go

	cmp	al,'z'          ; Is it out of range the other way?
	ja	short @F	; Yes, go

	and	al,0DFh 	; Convert it to lower case
	mov	es:[bx],al	; Put it back where it came from
@@:
	inc	bx		; Bump pointer
	loop	UC010		; Do the next character
UC090:
	REGREST <cx,bx> 	; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UPCASE	endp			; End UPCASE
	NPPROC	INST_RES -- Install resident hooks
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;
; Install interrupt handlers
; and move to an UMB if available
;

	 push	 ds		; Save until exit

; ----- Install our interrupt handlers

; ----- Check on XMS

	 GETXSTAT		; Do a XMS status call
	 cmp	 al,80H 	; Is the XMS stuff working?
	 jne	 HOOK2F 	; Yes, hook it and set flag

	 or	 LCL_FLAG,@XMSFOUND ; Set flag

	 GETXPTR		; Get a pointer to XMS handler in es:bx
	 assume  es:nothing	; Tell assembler

	 mov	 XMSPTR.VOFF,bx ; Save the XMS call offset
	 mov	 XMSPTR.VSEG,es ; Save the XMS call segment

	 lea	 dx,TSREND.[16-1] ; Get code ending offset
	 add	 dx,15		; Bump to next paragraph
	 shr	 dx,4		; Convert to paragraphs

	 mov	 ah,@XMS_GETUMB ; Request an UMB allocation
	 call	 XMSPTR 	; Request XMS service

	 cmp	 ax,1		; Check for error
	 jne	 short @F	; Go, if error

	 mov	 UMBSEG,bx	; Save UMB segment
	 mov	 LODSEG,bx	; Save as resident segment

	 REGSAVE <si,di>	; Save for a while

	 mov	 es,bx		; Set destination segment
	 assume  es:nothing	; Tell assembler

	 xor	 si,si		; Start at the begining for source...
	 mov	 di,si		; and destination
	 lea	 cx,TSREND	; Get the length of transfer

	 cld			; Direction up
     rep movsb			; Relocate ourself into an UMB

	 REGREST <di,si>	; Restore trashed regs
@@:
	 mov	 ds,LODSEG	; Set data accesses to UMB
	 assume  ds:PGROUP	; Lie to assembler

	 les	 bx,XMSPTR	; Get pointer to XMS handler
	 assume  es:nothing	; Tell assembler

	 push	 si		; Save for a while
	 lea	 si,XMSJMP	; Get pointer to our internal XMS jump

	 pushf			; Save flags
	 cli			; No interruptions

	 mov	 XMSJADR.VOFF,bx ; Patch our internal jump offset ..
	 add	 XMSJADR.VOFF,5 ; to go past the near call we are patching.
	 mov	 XMSJADR.VSEG,es ; Save jump segment.

	 mov	 al,es:[bx].OPCD ; Get original opcode
	 mov	 [si].OPCD,al	; Save it

	 mov	 ax,es:[bx].JADR.VOFF ; Get original offset
	 mov	 [si].JADR.VOFF,ax ; Save it

	 mov	 ax,es:[bx].JADR.VSEG ; Get original segment
	 mov	 [si].JADR.VSEG,ax ; Save it

	 mov	 es:[bx].OPCD,@OPCOD_JMPF ; Set the XMS jump opcode
	 mov	 es:[bx].JADR.VOFF,offset XMSTRAP ; Set offset to us
	 mov	 ax,LODSEG	; Get segment of resident code
	 mov	 es:[bx].JADR.VSEG,ax ; Set segment

	 popf			; Get back interrupt flag state
	 pop	 si		; Get back used reg

HOOK2F:
	 lea	 dx,INT2FPROC	; Get offset to our 2F handler
	 mov	 al,2Fh 	; Hook 2Fh
	 DOSCALL @SETINT	; Call DOS to set int vec to us

	 lea	 dx,API_PROC	; Address MEMAPI
	 mov	 cs:MEMAPI.VOFF,dx ; Save offset
	 mov	 cs:MEMAPI.VSEG,ds ; Save segment

HOOK21:

	 lea	 dx,INT21PROC	; Get offset to our 21h handler
	 mov	 al,21h 	; DOS interrupt #
	 DOSCALL @SETINT	; Call DOS to set int vec to us

	 test	 RES_FLAG,@HOOK67 ; Is there an INT 67 vector?
	 je	 short IR_EXIT	; No, exit

; If INT67 exists, hook up ours, and copy possible signature.

	 mov	 ax,LODSEG	; Get segment
	 mov	 INVJSEG,ax	; Patch our EMS handler jump code

	 lea	 dx,INVORG	; Compute the segment..
	 shr	 dx,4		; of our EMS..
	 add	 dx,ax		; interrupt handler.
	 mov	 NEW67SEG,dx	; Save segment for uninstall command

	 mov	 ds,OLD67PROC.VSEG ; Get the segment of old EMS handler
	 assume  ds:nothing	; Lie to assembler

	 REGSAVE <es,si,di,cx>	; Save while we move data

;;;;	 mov	 dx,INVOFF	; EMS int handler relative offset
	 mov	 es,LODSEG	; Load segment of UMB (destination)
	 assume  es:PGROUP	; Lie to assembler

	 or	 es:RES_FLAG,@EMSFOUND ; Assume there is EMS

	 mov	 si,0Ah 	; DS:SI -> Address EMS signature in handler
	 mov	 di,offset EMSSIG ; ES:DI -> Address our EMS signature
	 mov	 cx,8		; Length of sig

     rep cmpsb			; Izt an EMM signature?

	 je	 @F		;

	 and	 es:RES_FLAG,not (@EMSFOUND) ; Clear EMS Flag

@@:
	 mov	 si,0Ah 	; DS:SI -> Address EMS signature in handler
	 mov	 di,offset EMSSIG ; ES:DI -> Address our EMS signature
	 mov	 cx,9		; Length of sig (including possible NULL)

     rep movsb			; Move data

	 REGREST <cx,di,si,es>	; Restore used regs
	 assume  es:nothing	; Tell assembler

	 mov	 ds,dx		; Set DS to EMS handler segment
	 assume  ds:nothing	; Lie to assembler

	 mov	 dx,INVOFF	; EMS int handler relative offset
	 mov	 al,67h 	; Interrupt number to set
	 DOSCALL @SETINT	; Call DOS to set int vec for us
;;;;;	 jmp	 short IR_EXIT

IR_EXIT:
	 REGSAVE <es,ax,di>	; Save used regs

	 mov	 ds,LODSEG	; Load segment of UMB (destination)
	 assume  ds:PGROUP	; Lie to assembler

	 push	 cs		; Address non-res code
	 pop	 es		; With ES
	 assume  es:PGROUP	; Force DS to be used.

	 mov	 ax,offset API_EXIT_NSUP ; Get this offset in a handy location
	 lea	 di,API_JMP_TBL ; Address table

	 test	 ds:RES_FLAG,@EMSFOUND ; Did we find EMS?
	 jnz	 @F

	 mov	 [di+(2*@EMS_SW)],ax ; Blank out a function
	 mov	 [di+(2*@EMS_SW2)],ax ; Blank out a function

@@:
	 test	 ds:RES_FLAG,@HOOK67 ; Was 67 Hooked?
	 jnz	 @F		; Yes, don't blank out functions

	 mov	 [di+(2*@VCPI_SW)],ax ; Blank out a function
	 mov	 [di+(2*@VCPI_SW2)],ax ; Blank out a function
@@:
	 test	 es:LCL_FLAG,@XMSFOUND ; Was XMS found and hooked?
	 jnz	 @F		; Yes, don't blank out functions

	 mov	 [di+(2*@XMS_SW)],ax ; Blank out a function
	 mov	 [di+(2*@XMSL_SW)],ax ; Blank out a function
	 mov	 [di+(2*@XMS_SW2)],ax ; Blank out a function
	 mov	 [di+(2*@XMSL_SW2)],ax ; Blank out a function
@@:
	 REGREST <di,ax,es>	; Restore used regs

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell assembler

	 ret

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_RES endp			; End INST_RES
	NPPROC	INST_CHK -- Check for previous installation
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;
; Do various tests to determine if we are already installed,
; and set INSTALLED to !=0 if we find another resident copy
;

; Get the segment of the first DOS MAC entry

	 DOSCALL @GETLST	; Return with ES:BX ==> List of Lists
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es:[bx-2]	; Get the segment of the first DOS MAC entry
	 mov	 DOSMAC,ax	; Save for later use

; ----- Get the current holder of int 21h
	 mov	 al,21h 	; DOS interrupt number
	 DOSCALL @GETINT	; Call DOS to get interrupt vector
	 assume  es:nothing	; Tell assembler

	 mov	 OLD21PROC.VOFF,bx ; Save away offset
	 mov	 OLD21PROC.VSEG,es ; Save away segment

; ----- Get the current holder of int 2F
	 mov	 al,2Fh 	; Get 2F
	 DOSCALL @GETINT	; Get interrupt vector in AL to ES:BX
	 assume  es:nothing	; Tell assembler

	 mov	 OLD2FPROC.VOFF,bx ; Save away offset
	 mov	 OLD2FPROC.VSEG,es ; Save away segment

; ----- Get the current holder of int 67

	 mov	 al,67h 	; EMS interrupt number
	 DOSCALL @GETINT	; Get interrupt vector in AL to ES:BX
	 assume  es:nothing	; Tell assembler

	 mov	 OLD67PROC.VOFF,bx ; Save away offset
	 mov	 OLD67PROC.VSEG,es ; Save away segment

	 cmp	 OLD67PROC,0h	; Is the vector there?
	 je	 @F

	 or	 RES_FLAG,@HOOK67 ; Set the flag
@@:

; ----- Are we installed already and, the current vector holder

	 lea	 si,szMEMLIMIT	; Address string for VSAPI
	 mov	 ax,@DPMI_API2F 	; VSAPI
	 int	 2Fh		; Do it
	 assume  es:nothing	; Tell assembler the news

	 and	 ax,ax		; Are we installed?
	 jnz	 short ICHK_EXIT ; No, Skip this

; We are installed, mark flag, save Entry Point away

	 or	 LCL_FLAG,@INSTALLED ; Set state to installed

	 mov	 MEMAPI.VSEG,es ; Save Entry Point away
	 mov	 MEMAPI.VOFF,di ; . . .

;;;;;;	 jmp	 short ICHK_EXIT ; We're done

ICHK_EXIT:

	ret

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_CHK endp			; End INST_CHK
	 NPPROC  REMOVE_RES -- Remove resident hooks
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 push	 ds		; Save

	 lds	 dx,OLD67PROC	; Get old interrupt vector code
	 assume  ds:nothing	; Lie to assembler

	 mov	 al,67h 	; Int number to set
	 DOSCALL @SETINT	; Call dos to do work

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell assembler

	 push	 ds		; Save

	 lds	 dx,OLD21PROC	; Get old interrupt vector code
	 assume  ds:nothing	; Lie to assembler

	 mov	 al,21h 	; Int number to set
	 DOSCALL @SETINT	; Call dos to do work

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell assembler

	 push	 ds		; Save again
	 lds	 dx,OLD2FPROC	; Get int 2F handler address
	 assume  ds:nothing	; Lie to assembler

	 mov	 al,2Fh 	; Int number to set
	 DOSCALL @SETINT	; Return int 2F to original processor

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell assembler

	 les	 bx,XMSPTR	; Get the XMS call pointer
	 assume  es:nothing	; Lie to assembler

	 mov	 ax,es		; Make sure the pointer is valid
	 or	 ax,bx		;
	 jz	 short REMOVE_RES_EXIT ; Zero if the pointer is bad

	 push	 si		; Save
	 lea	 si,XMSJMP	; Pointer to XMS jump original state
	 pushf			; Flags away
	 cli			; No interruptions please.
	 mov	 al,[si].OPCD	; Read old opcode
	 mov	 es:[bx].OPCD,al ; Store original op code
	 mov	 ax,[si].JADR.VOFF ; Get old offset
	 mov	 es:[bx].JADR.VOFF,ax ; Store original offset
	 mov	 ax,[si].JADR.VSEG ; Get old segment
	 mov	 es:[bx].JADR.VSEG,ax ; Store original segment
	 popf			; Return interrupts to original state
	 pop	 si		; Restore

	 mov	 dx,UMBSEG	; Get UMB segment
	 or	 dx,dx		; Did we load into an UMB
	 jz	 short REMOVE_RES_EXIT ; No, go free low DOS allocation

	 mov	 ah,@XMS_RELUMB ; Free UMB
	 call	 XMSPTR 	; Request XMS service

REMOVE_RES_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REMOVE_RES endp 		; End REMOVE_RES
	NPPROC	ISMAX -- Check for 386MAX$$ device
	assume	ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

; ----- See if MAX is installed
	mov	al,02h		; Access code for read/write
	DOSCALL @OPENF2,DEVNAME ; Attempt to open 386MAX device driver
	jc	short ISMAX_ERR ; It failed

; ----- Ensure it's a device
	mov	bx,ax		; Copy to handle register
	mov	al,00h		; Function code to get device information
	DOSCALL @IOCTL2 	; Return in DX
	jc	short ISMAX_ERRCLOSE ; Something went wrong; go puke on self

	test	dx,@IOCTL_DEV	; Is it a device?
	jz	short ISMAX_ERRCLOSE ; Jump if not

; Read the MAX info structure to get current debug flags and PORT67
	mov	al,02h		; Read from device
	mov	cx,INFOSIZE	; CX = # bytes in INFO structure
	mov	INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO
;;;;;;; jc	???		; Ignore error

	DOSCALL @CLOSF2 	; Close MAX file handle

; Check signature to be sure it's not an impostor
	cmp	INFO.INFO_SIGN.ELO[0],'83' ; Our signature?
	jne	short ISMAX_ERR ; Not this time

	cmp	INFO.INFO_SIGN.ELO[2],'M6' ; Our signature?
	jne	short ISMAX_ERR ; Not this time

	cmp	INFO.INFO_SIGN.ELO[4],'XA' ; Our signature?
	jne	short ISMAX_ERR ; Not this time

	mov	ax,INFO.INFO_P67 ; Get I/O port for Int 67h communications
	mov	PORT67,ax	; Save in resident data area
	mov	ax,INFO.INFO_DBG ; Get current DBG_FLAG value
	mov	DBG_FLAG,ax	; Save in resident data area

	clc			; Indicate success

	jmp	short ISMAX_EXIT ; Join common exit

ISMAX_ERRCLOSE:
	DOSCALL @CLOSF2 	; Close MAX file handle
ISMAX_ERR:
	stc			; Set error return status

ISMAX_EXIT:
	ret			; Return with carry as status

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ISMAX	endp			; End ISMAX
	NPPROC	PREPARSE -- Pre-process config.sys line
	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;
; Entry: ES:BX = string after the device=
; Exit: ES:BX points to first parameter
;	CX length of parameter line
;

	mov	cx,0		; Initialize counter
@@:
	mov	al,es:[bx]	; Get character
	cmp	al,LF		; Is it a LF?
	je	short @F	; Yes, goto next level
	cmp	al,CR		; Is it a CR?
	je	short @F	; Yes, goto next level
	inc	bx		; Bump pointer
	cmp	al,' '          ; Was it a space?
	je	short @B	; Yes, strip it out
	cmp	al,TAB		; Was it a tab?
	je	short @B	; Yes, strip it out
@@:
	mov	al,es:[bx]	; Get next character
	cmp	al,LF		; Is it a LF
	je	short @F	; Yes, goto next level
	cmp	al,CR		; Is it a CR
	je	short @F	; Yes, goto next level
	inc	bx		; Bump pointer
	cmp	al,' '          ; Was it a space?
	jne	short @B	; No, keep looking
@@:
	push	bx		; Save start of parameters
@@:
	mov	al,es:[bx]	; Get next character
	cmp	al,LF		; Is it a LF
	je	short @F	; Yes, go
	cmp	al,CR		; Is it a CR
	je	short @F	; Yes, go
	inc	cx		; Bump counter
	inc	bx		; Bump pointer
	jmp	short @B	; Go look for end of line
@@:
	pop	bx		; Get back start of parameters

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

PREPARSE endp			; End PREPARSE
	 NPPROC  CHECK_WIN3 -- CHECK_WIN3 Procedure
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On exit: CF set if Win3 / enhanced mode is present

|

	 REGSAVE <ax,dx>	; Save registers

	 mov	 ax,1600h	; Enhanced Windows installation check
	 int	 2Fh		; Windows API

	 test	 al,7Fh 	; Check for enhanced Windows
	 jz	 short CHECK_WIN3_CLC ; Enhanced Windows is not running

	 cmp	 al,1		; Is it Windows/386 version 2.xx?
	 je	 short CHECK_WIN3_CLC ; Yes, so skip it

	 cmp	 al,0FFh	; Is it Windows/386 version 2.xx?
	 je	 short CHECK_WIN3_CLC ; Yes, so skip it

; Enhanced Windows/386 is running.  AL = major version #, AH = minor version #

	 stc			; Mark as Win3 present

	 jmp	 short CHECK_WIN3_EXIT ; Exit

; Enhanced Windows/386 is NOT running, continue on.

CHECK_WIN3_CLC:
	 clc			; Mark as Win3 not present
CHECK_WIN3_EXIT:
	 REGREST <dx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_WIN3 endp 		; End CHECK_WIN3 procedure
	 NPPROC  VMVSAPI_CHK -- Check On VM VSAPI Services
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check on VM VSAPI services

|

	 REGSAVE <ax,si,di,es>	; Save registers

	 lea	 si,DPMIMAX	; DS:SI ==> DPMI host name for 386MAX
	 mov	 ax,@DPMI_API2F ; Get VSAPI function #
	 int	 2Fh		; request multiplexor service
	 assume  es:nothing	; Tell the assembler about it
				; Returning ES:DI ==> VSAPI entry point
	 and	 ax,ax		; Did it succeed?
	 jnz	 short @F	; Jump if not

	 mov	 VMVSAPI_VEC.VOFF,di ; Save for later use
	 mov	 VMVSAPI_VEC.VSEG,es ; ...
@@:
	 REGREST <es,di,si,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VMVSAPI_CHK endp		; End VMVSAPI_CHK procedure
	 NPPROC  CLEAR_SWAP -- Clear The SWAPFILE
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Clear the swapfile by entering and exiting DPMI

|

	 pusha			; Save all GP registers
	 REGSAVE <ds,es>	; Save segment registers

	 mov	 ax,@DPMI_GPME	; Function code to Get PM Entry
	 int	 2Fh		; Request multiplexor service
				; Return with BX = flags
				;	      CL = processor type
				;	      DX = DPMI version #
				;	      SI = # paras for HPDA
				;	      ES:DI ==> switch entry point
	 or	 ax,ax		; Izit present?
	 jnz	 short CLEAR_SWAP_EXIT ; Jump if not (well, we tried)

	 mov	 DPMIDRV_VEC.VOFF,di ; Save for later use
	 mov	 DPMIDRV_VEC.VSEG,es ; ...

	 mov	 al,21h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT21_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT21_VEC.VSEG,es ; ...

	 mov	 OLDSTK_VEC.VSEG,ss ; Save to restore upon exit
	 mov	 OLDSTK_VEC.VOFF,sp ; ...

; Hook INT 21h to catch the termination

	 mov	 al,21h 	; Intercept this one
	 DOSCALL @SETINT,INT21	; Install our own handler for termination

	 lea	 ax,ZGROUP:ZTAIL[16-1] ; Get offset in ZGROUP of end
	 shr	 ax,4-0 	; Convert from bytes to paras
	 add	 ax,seg ZGROUP	; Plus segment of ZGROUP
	 mov	 es,ax		; Address it for the HPDA
	 assume  es:nothing	; Tell the assembler about it

; Enter PM via DPMI switch entry point

	 mov	 ax,1		; We're a 32-bit client
	 call	 DPMIDRV_VEC	; Request entry into PM
	 jc	 short @F	; Jump if we failed

	 DOSCALL @EXITRC	; Terminate through DOS
@@:
CLEAR_SWAP_NEXT:

; Give back the INT 21h handler

	 lds	 dx,OLDINT21_VEC ; DS:DX ==> original INT 21h handler
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 al,21h 	; Restore this one
	 DOSCALL @SETINT	; Restore
CLEAR_SWAP_EXIT:
	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CLEAR_SWAP endp 		; End CLEAR_SWAP procedure
	 NPPROC  INT21 -- DOS Services Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

DOS services interrupt handler

On entry:

AH	 =	 function code

|

	 pushf			; Save flags

	 cmp	 ah,@EXITRC	; Izit exit time?
	 jne	 short INT21_ORIG ; Jump if not

;;;;;;;; popf			; Restore flags

	 lss	 sp,OLDSTK_VEC	; Address the stack for termination
	 assume  ss:nothing	; Tell the assembler about it

	 mov	 ax,cs		; Get code/data segment
	 mov	 ds,ax		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 jmp	 CLEAR_SWAP_NEXT ; Join common code

	 assume  ds:nothing	; Tell the assembler about it

INT21_ORIG:
	 popf			; Restore flags

	 jmp	 OLDINT21_VEC	; Continue with next handler in sequence

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INT21	 endp			; End INT21 procedure

NCODE	ends			; End NCODE segment

	end	INIT
