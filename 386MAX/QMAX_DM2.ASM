;' $Header:   P:/PVCS/MAX/386MAX/QMAX_DM2.ASV   1.2   30 May 1997 10:44:18   BOB  $
	 title	 QMAX_DM2 -- 386MAX DMA Test Functions
	 page	 58,122
	 name	 QMAX_DM2

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group XGROUP:
	       Program segment XCODE, byte-aligned,  public, class 'xcode'
	       Data    segment XDATA, dword-aligned, public, class 'xdata'

Link requirements:  Final routine should have extension .SYS.

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.186
.xlist
	 include MASM.INC
	 include DMA.INC
	 include PTR.INC
	 include 8259.INC
	 include INTVEC.INC
	 include BITFLAGS.INC
	 include BIOSDATA.INC

	 include QMAX_DMA.INC
	 include QMAX_OEM.INC
.list

if @OEM_DMA and @OEM_SYS ne @OEMSYS_ILIM
INSTINT  macro	 NN

	 lea	 ax,DMA_INT&NN	; Get our offset
	 xchg	 ax,INT00_VEC.VOFF[&NN&h*type INT00_VEC] ; Swap offsets
	 mov	 OLDINT&NN&_VEC.VOFF,ax ; Save to restore later

	 mov	 ax,cs		; Get our segment
	 xchg	 ax,INT00_VEC.VSEG[&NN&h*type INT00_VEC] ; Swap segments
	 mov	 OLDINT&NN&_VEC.VSEG,ax ; Save to restore later

	 endm			; INSTINT


RESTINT  macro	 NN

	 mov	 ax,OLDINT&NN&_VEC.VOFF ; Get old offset
	 mov	 INT00_VEC.VOFF[&NN&h*type INT00_VEC],ax ; Restore
	 mov	 ax,OLDINT&NN&_VEC.VSEG ; Get old segment
	 mov	 INT00_VEC.VSEG[&NN&h*type INT00_VEC],ax ; Restore

	 endm			; RESTINT


INTMAC	 macro	 INTNO,IRQNO
	 FPPROC  DMA_INT&INTNO -- Interrupt Handler for INTNO&h
	 assume  ds:nothing,es:nothing,ss:nothing

	 push	 bx		; Save for a moment

	 mov	 bx,$IRQ&IRQNO	; Get IRQ #
	 call	 CHECK_USAGE	; Check on DMA usage

	 pop	 bx		; Restore

	 jmp	 OLDINT&INTNO&_VEC ; Continue on

	 assume  ds:nothing,es:nothing,ss:nothing

DMA_INT&INTNO endp		; End DMA_INT&INTNO procedure
	 endm			; INTMAC


PGROUP	 group	 CODE,EDATA
XGROUP	 group	 XCODE,XDATA


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 SBIOSDATA:word

CODE	 ends			; End CODE segment


EDATA	 segment dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 DMASIZE:word
	 extrn	 DMA_FLIP:byte
	 extrn	 DMA_ICNT:byte
	 extrn	 MAPSEG_NXT:word

EDATA	 ends			; End EDATA segment


XDATA	 segment dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

	 public  OLDINT0A_VEC,OLDINT0B_VEC
	 public  OLDINT0C_VEC,OLDINT0D_VEC
	 public  OLDINT0E_VEC,OLDINT0F_VEC
	 public  OLDINT72_VEC,OLDINT73_VEC
	 public  OLDINT74_VEC,OLDINT75_VEC
	 public  OLDINT76_VEC,OLDINT77_VEC
OLDINT0A_VEC dd  ?		; Save area for old INT 0Ah interrupt handler
OLDINT0B_VEC dd  ?		;			0Bh
OLDINT0C_VEC dd  ?		;			0Ch
OLDINT0D_VEC dd  ?		;			0Dh
OLDINT0E_VEC dd  ?		;			0Eh
OLDINT0F_VEC dd  ?		;			0Fh
OLDINT72_VEC dd  ?		;			72h
OLDINT73_VEC dd  ?		;			73h
OLDINT74_VEC dd  ?		;			74h
OLDINT75_VEC dd  ?		;			75h
OLDINT76_VEC dd  ?		;			76h
OLDINT77_VEC dd  ?		;			77h

	 public  NDMA
NDMA	 dw	 8		; # DMA channels to check

	 public  DMA_IRQ
DMA_IRQ  db	 8 dup (?)	; IRQ for each channel

	 public  OLDIMR,OLDIMR2
OLDIMR	 db	 ?		; Old master mask register
OLDIMR2  db	 ?		; ... slave

	 public  HDISK
HDISK	 db	 80h		; Initial hard disk #

	 public  MAX_TSECTS,MAX_DSECTS
MAX_TSECTS db	 0		; Maximum # sectors read in transfer
MAX_DSECTS db	 0		; Maximum # sectors read via DMA

	 public  DMA_CHNO
DMA_CHNO db	 0		; Channel #s for DMA

	 public  IRQ_FLAG
IRQ_FLAG db	 0		; IRQ flags
@IRQ_DMA equ	 80h		; DMA encountered

XDATA	 ends			; End XDATA segment


XCODE	 segment byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 public  @QMAX_DM2_XCODE
@QMAX_DM2_XCODE:nop		; Mark module start in .MAP file

	 FPPROC  TEST_DMA -- Test For Hard Disk DMA
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Test for hard disk DMA.

|

	 test	 CM3_FLAG,@CM3_DMA ; Was DMA= specified?
	 jnz	 short TEST_DMA_EXIT ; Yes, don't bother to override

; Ensure there's a hard disk in the system

	 REGSAVE <ds>		; Save for a moment

	 mov	 ds,SBIOSDATA	; Get segment of BIOS data area
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 cmp	 HF_NUM,0	; Any hard disks installed?
	 REGREST <ds>		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 je	 short TEST_DMA_EXIT ; Not this time

; Get and set IMR values

	 call	 SET_IMR	; Set 'em

; Install our interrupt handlers

	 call	 INST_INTS	; Install 'em

; Clear DMA count registers

	 call	 CLEAR_DMA	; Clear 'em

; Request hard disk activity on each hard disk in sequence

	 call	 READ_HD	; Read 'em

; Restore interrupts

	 call	 REST_INTS	; Restore interrupts

; Restore IMR

	 call	 REST_IMR	; Restore 'em

	 cmp	 DMA_CHNO,0	; Any DMA transfers?
	 je	 short TEST_DMA_EXIT ; Not this time

	 mov	 DMASIZE,@DMA_DSK ; Use hard disk transfer buffer size
TEST_DMA_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

TEST_DMA endp			; End TEST_DMA procedure
	 NPPROC  SET_IMR -- Get and Set IMR Values
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Get and set IMR values.

|

	 REGSAVE <ax>		; Save register

; Get current IMR values

	 cli			; Disallow interrupts

	 in	 al,@IMR	; Get current master mask register
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 mov	 OLDIMR,al	; Save to restore later

	 test	 LCL_FLAG,@LCL_XT ; Izit a PC/XT?
	 jnz	 short SET_IMR1 ; Yes, no second controller

	 in	 al,@IMR2	; Get current slave mask register
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 mov	 OLDIMR2,al	; Save to restore later
SET_IMR1:

; Set new IMR values

	 mov	 al,OLDIMR	; Get current master mask register
	 or	 al,(mask $IRQ0) or (mask $IRQ1) ; Mask off IRQ0 and IRQ1
	 out	 @IMR,al	; Tell the PIC about it
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 sti			; Allow interrupts

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SET_IMR  endp			; End SET_IMR procedure
	 NPPROC  INST_INTS -- Install Our Interrupt Handlers
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Install our interrupt handlers.

|

	 REGSAVE <ax,ds>	; Save registers

; Install our own INT 0Ah-0Fh, and 72h-77h interrupt handlers

	 push	 seg INTVEC	; Segment of interrupt vector table
	 pop	 ds		; Address it
	 assume  ds:INTVEC	; Tell the assembler about it

	 cli			; Disallow interrupts

	 INSTINT 0A
	 INSTINT 0B
	 INSTINT 0C
	 INSTINT 0D
	 INSTINT 0E
	 INSTINT 0F

	 test	 LCL_FLAG,@LCL_XT ; Izit a PC/XT?
	MJ nz	 INST_INTS_EXIT ; Yes, no second controller

	 INSTINT 72
	 INSTINT 73
	 INSTINT 74
	 INSTINT 75
	 INSTINT 76
	 INSTINT 77
INST_INTS_EXIT:
	 sti			; Allow interrupts

	 REGREST <ds,ax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INST_INTS endp			; End INST_INTS procedure
	 NPPROC  CLEAR_DMA -- Clear DMA Count Registers
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Clear DMA count registers

|

	 REGSAVE <ax,cx,dx,si>	; Save registers

	 mov	 cx,NDMA	; # DMA channels
	 xor	 si,si		; Initialize index into DMA_ICNT
	 xor	 dh,dh		; Zero to use as word
	 xor	 al,al		; Constant value to ouptut

	 test	 LCL_FLAG,@LCL_XT ; Izit a PC/XT?
	 jz	 short CLEAR_DMA_NEXT1 ; No
				; Yes, so channel #0 is used for memory refresh
	 inc	 si		; Skip channel #0
	 dec	 cx		; Account for it
CLEAR_DMA_NEXT1:
	 mov	 dl,DMA_FLIP[si] ; Get next count register
	 out	 dx,al		; Set flip-flip
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 mov	 dl,DMA_ICNT[si] ; Get next count register

	 out	 dx,al		; Clear the low-order byte
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 out	 dx,al		; Clear the high-order byte
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 inc	 si		; Skip to next count register

	 loop	 CLEAR_DMA_NEXT1 ; Jump if more DMA channels to clear

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jz	 short CLEAR_DMA_EXIT ; Not this time

	 mov	 cx,NDMA	; # DMA channels
	 xor	 si,si		; Initialize DMA channel #
CLEAR_DMA_NEXT2:
	 mov	 ax,si		; Get DMA channel #
	 or	 al,@DMA3_WCNT	; Write transfer count register

	 out	 @DMA3_CMD,al	; Tell the DMA controller
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 xor	 al,al		; Constant value to ouptut

	 out	 @DMA3_DATA,al	; Clear the low-order byte
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 out	 @DMA3_DATA,al	; Clear the high-order byte
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 inc	 si		; Skip to next count register

	 loop	 CLEAR_DMA_NEXT2 ; Jump if more DMA channels to clear
CLEAR_DMA_EXIT:
	 REGREST <si,dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CLEAR_DMA endp			; End CLEAR_DMA procedure
	 NPPROC  READ_HD -- Read The Hard Disk
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Read the hard disk(s).

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

; Read in a sector to initiate a DMA transfer

READ_HD_NEXT:
	 and	 IRQ_FLAG,not @IRQ_DMA ; Clear the flag

	 REGSAVE <es>		; Save for a moment

	 mov	 es,MAPSEG_NXT	; Get next available segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,0201h	; Read one sector
	 xor	 bx,bx		; ...into ES:BX
	 mov	 cx,0001h	; ...from cylinder #0, sector #1,
	 mov	 dh,00h 	; ...head #0,
	 mov	 dl,HDISK	; ...disk #
	 int	 13h		; Request disk service

	 REGREST <es>		; Restore
	 assume  es:PGROUP	; Tell the assembler about it
	 jc	 short READ_HD_EXIT ; That didn't work

; Get the drive parameters

; Some SCSI hard disk software drivers clobber ES over the
; following call.  For safety's sake, we save the ones we
; depend upon.

	 REGSAVE <ds,es>	; Save for a moment

	 mov	 ah,08h 	; Get drive parameters
	 mov	 dl,HDISK	; ...for this disk #
	 int	 13h		; Request disk service

	 REGREST <es,ds>	; Restore
	 jc	 short READ_HD_EXIT ; That didn't work

	 inc	 HDISK		; Skip to next hard disk #

	 and	 cl,not (@BIT7 or @BIT6) ; Isolate sector limit
	 inc	 cl		; Convert from limit to length

	 cmp	 cl,MAX_TSECTS	; Check against current maximum
	 jbe	 short READ_HD_NEXT2 ; Go around again

	 mov	 MAX_TSECTS,cl	; Save as new maximum
READ_HD_NEXT2:
	 test	 IRQ_FLAG,@IRQ_DMA ; Did we encounter DMA?
	 jz	 short READ_HD_NEXT ; Not this time

	 cmp	 cl,MAX_DSECTS	; Check against current maximum
	 jbe	 short READ_HD_NEXT ; Go around again

	 mov	 MAX_DSECTS,cl	; Save as new maximum

	 jmp	 short READ_HD_NEXT ; Go around again

READ_HD_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

READ_HD  endp			; End READ_HD procedure
	 NPPROC  REST_INTS -- Restore Old Interrupt Handlers
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Restore old interrupt handlers.

|

	 REGSAVE <ax,ds>	; Save registers

; Restore old INT 0Ah-0Fh, and 72h-77h interrupt handlers

	 push	 seg INTVEC	; Segment of interrupt vector table
	 pop	 ds		; Address it
	 assume  ds:INTVEC	; Tell the assembler about it

	 cli			; Disallow interrupts

	 RESTINT 0A
	 RESTINT 0B
	 RESTINT 0C
	 RESTINT 0D
	 RESTINT 0E
	 RESTINT 0F

	 test	 LCL_FLAG,@LCL_XT ; Izit a PC/XT?
	 jnz	 short REST_INTS_EXIT ; Yes, no second controller

	 RESTINT 72
	 RESTINT 73
	 RESTINT 74
	 RESTINT 75
	 RESTINT 76
	 RESTINT 77
REST_INTS_EXIT:
	 sti			; Allow interrupts

	 REGREST <ds,ax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REST_INTS endp			; End REST_INTS procedure
	 NPPROC  REST_IMR -- Restore IMR
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Restore original IMR

|

	 REGSAVE <ax>		; Save register

	 cli			; Disallow interrupts

	 mov	 al,OLDIMR	; Get old master mask register
	 out	 @IMR,al	; Tell the PIC about it
	 jmp	 short $+2	; Drain PIQ
	 jmp	 short $+2	; Drain PIQ

	 test	 LCL_FLAG,@LCL_XT ; Izit a PC/XT?
	 jnz	 short REST_IMR_EXIT ; Yes, no second controller

	 mov	 al,OLDIMR2	; Get old slave mask register
	 out	 @IMR2,al	; Tell the PIC about it
	 jmp	 short $+2	; Drain PIQ
	 jmp	 short $+2	; Drain PIQ
REST_IMR_EXIT:
	 sti			; Allow interrupts

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REST_IMR endp			; End REST_IMR procedure

	 INTMAC  0A,2
	 INTMAC  0B,3
	 INTMAC  0C,4
	 INTMAC  0D,5
	 INTMAC  0E,6
	 INTMAC  0F,7
	 INTMAC  72,10
	 INTMAC  73,11
	 INTMAC  74,12
	 INTMAC  75,13
	 INTMAC  76,14
	 INTMAC  77,15

	 NPPROC  CHECK_USAGE -- Check on DMA Usage
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Check on DMA usage.

See if any DMA channel has reached termination by inspecting
the count registers for FFFF.

On entry:

BX	 =	 IRQ #

|

	 REGSAVE <ax,bx,cx,dx,si,ds> ; Save registers

	 push	 seg PGROUP	; Get data segment
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 cx,NDMA	; # DMA channels
	 xor	 si,si		; Initialize index into DMA_ICNT
	 xor	 dh,dh		; Zero to use as word
	 mov	 bh,1		; Set strobe bit for channel #
CHECK_USAGE_NEXT1:
	 mov	 dl,DMA_FLIP[si] ; Get next count register
	 out	 dx,al		; Set flip-flip
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 mov	 dl,DMA_ICNT[si] ; Get next count register

	 in	 al,dx		; Get current word count, low-byte
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 mov	 ah,al		; Save for a moment

	 in	 al,dx		; Get current word count, low-byte
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 inc	 ax		; Reached terminal count (-1)?
	 jnz	 short CHECK_USAGE_LOOP1 ; Not yet

	 mov	 DMA_IRQ[si],bl ; Save IRQ #
	 or	 DMA_CHNO,bh	; Mark as using DMA on this channel
	 or	 IRQ_FLAG,@IRQ_DMA ; Mark as DMA encountered
CHECK_USAGE_LOOP1:
	 shl	 bh,1		; Shift strobe
	 inc	 si		; Skip to next DMA channel

	 loop	 CHECK_USAGE_NEXT1 ; Jump if more DMA channels to check

; Check for special MCA-compatible machine DMA usage

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jz	 short CHECK_USAGE_EXIT ; Not this time

	 mov	 cx,NDMA	; # DMA channels
	 xor	 si,si		; Initialize channel #
	 mov	 bh,1		; Set strobe bit for channel #
CHECK_USAGE_NEXT2:
	 mov	 ax,si		; Copy channel #
	 or	 al,@DMA3_RCNT	; Read transfer count register

	 out	 @DMA3_CMD,al	; Tell the DMA controller about it
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 in	 al,@DMA3_DATA	; Get current word count, low-byte
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 mov	 ah,al		; Save for a moment

	 in	 al,@DMA3_DATA	; Get current word count, low-byte
	 jmp	 short $+2	; Drain the PIQ
	 jmp	 short $+2	; Drain the PIQ

	 inc	 ax		; Reached terminal count (-1)?
	 jnz	 short CHECK_USAGE_LOOP2 ; Not yet

	 mov	 DMA_IRQ[si],bl ; Save IRQ #
	 or	 DMA_CHNO,bh	; Mark as using DMA on this channel
	 or	 IRQ_FLAG,@IRQ_DMA ; Mark as DMA encountered
CHECK_USAGE_LOOP2:
	 shl	 bh,1		; Shift strobe
	 inc	 si		; Skip to next DMA channel

	 loop	 CHECK_USAGE_NEXT2 ; Jump if more DMA channels to check
CHECK_USAGE_EXIT:
	 REGREST <ds,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_USAGE endp		; End CHECK_USAGE procedure

XCODE	 ends			; End XCODE segment
endif				; IF @OEM_DMA and @OEM_SYS ne @OEMSYS_ILIM

	 MEND			; End QMAX_DM2 module
