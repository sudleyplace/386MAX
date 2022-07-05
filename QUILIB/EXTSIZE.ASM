;' $Header:   P:/PVCS/MAX/QUILIB/EXTSIZE.ASV   1.1   30 May 1997 12:09:00   BOB  $
	 title	 EXTSIZE -- Get extended memory size
	 page	 58,122
	 name	 EXTSIZE

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Uses simplified segment directives

Link requirements:  None, standalone subroutine.

Program derived from:  None.

Original code by:  Henry Groover, September, 1991.

Modifications by:  None.

|
.xlist
	 include MASM.INC
	 include PTR.INC
	 include CMOS.INC
	 include XMS.INC
.list

%.model  &MODEL

.data

	 include CPUID.INC
CGROUP	 group	 CPUID_SEG

	 public  XMSENTRY
XMSENTRY dd	 ?		; Entry address for XMS calls

.code

	 PPROC	 _extsize -- Return extended memory size per int 15 fn 88
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Call Int 15 function 88 to get extended memory size and return it in AX.

|

	 mov	 ah,88h 	; Prepare to get size
	 stc			; Set carry flag
	 int	 15h		; Call interrupt
	 jnc	 short @F	; Return AX

	 sub	 ax,ax		; Call failed - return 0
@@:

	 ret			; Return to caller
	 assume  ds:nothing,es:nothing,ss:nothing

_extsize	 endp			; End EXTSIZE procedure

	 PPROC	 _extcmos -- Return extended memory size per CMOS
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Check processor ID byte at F000:FFFE.  If it's an XT, return 0.
Otherwise, get size from CMOS and return in AX.

|

	 REGSAVE <es>		; Save register

	 mov	 ax,seg CGROUP	; Get segment for ID
	 mov	 es,ax		; Use ES to address it
	 assume  es:CGROUP	; Tell the assembler

	 mov	 al,BIOSCPUID	; Get the machine ID byte

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

	 pushf			; Save for a moment
	 cli			; Disallow interrupts

	 mov	 al,@CMOS_EXTHI ; Index register for high-order byte of EXT
	 out	 @CMOS_CMD,al	; Tell the CMOS about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@CMOS_DATA	; Get the high-order byte
	 mov	 ah,al		; Save for later use

	 mov	 al,@CMOS_EXTLO ; Index register for low-order byte of EXT
	 out	 @CMOS_CMD,al	; Tell the CMOS about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@CMOS_DATA	; Get the low-order byte
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay

	 popf			; Restore

	 jmp	 short CHECK_MODEL_EXIT ; Join common code

CHECK_MODEL_PCXT:
	 sub	 ax,ax		; Return 0 if no CMOS

CHECK_MODEL_EXIT:
	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_extcmos	 endp			; End extcmos procedure

	 PPROC	 _xmsmax -- Return size in K of largest EMB
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

On exit:
AX	=	0 if no XMS manager, or no free EMB's

|

	REGSAVE <si,di,es>	; Save registers

	mov	ax,4300h	; Check for driver installed
	int	2fh		; Return status in al
	cmp	al,80h		; Izit installed?
	je	short @F	; Jump if so

	sub	ax,ax		; Return 0
	jmp	short xmsmax_exit ; Join common exit code
@@:

	mov	ax,4310h	; Get address of driver control function
	int	2fh		; Return far entry point in ES:BX

	mov	XMSENTRY.VSEG,es ; Segment of entry
	mov	XMSENTRY.VOFF,bx ; Offset...

	mov	ah,@XMS_QRYXMB	; Query free extended memory
	call	XMSENTRY	; Return total in DX, largest in AX

xmsmax_exit:
	 REGREST <es,di,si>	; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return
	 assume  ds:nothing,es:nothing,ss:nothing

_xmsmax  endp			; End _xmsmax procedure

	 MEND			; End MAXSUB module
