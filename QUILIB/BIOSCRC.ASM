;' $Header:   P:/PVCS/MAX/QUILIB/BIOSCRC.ASV   1.1   30 May 1997 12:08:58   BOB  $
	 title	 BIOSCRC -- Subroutines to get BIOS type, size, and CRC
	 page	 58,122
	 name	 BIOSCRC

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1985-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  byte-aligned, public, class 'data'

Link requirements:  None, standalone subroutine.

Program derived from:  PD_SUB.ASM

Original code by:  Henry Groover, July 1991

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
	 include BIOSCONF.INC
	 include QMAX_AOX.INC	; AOX specific information
.list

%.model  &MODEL,c

	 @NO_UNDERBAR	equ	0
	 include VENDINFO.INC
	 include RAMSCAN.INC

	 .data

	 extrn	 errno:word
	 extrn	 SUB_FLAG:word	; Local flags - in VENDINFO.ASM
	 extrn	 PaSYSROM:word	; Physical start of ROM - set by MAXPRES

	 public  FIXBUF 	; Warning this item must be paragraph aligned
FIXBUF	 db	 16 dup (?)	; Buffer to fixup the last paragraph of BIOS

	 public  XORLIST
XORLIST  dw	 00000h, 0C0C1h, 0C181h, 00140h, 0C301h, 003C0h, 00280h, 0C241h
	 dw	 0C601h, 006C0h, 00780h, 0C741h, 00500h, 0C5C1h, 0C481h, 00440h
	 dw	 0CC01h, 00CC0h, 00D80h, 0CD41h, 00F00h, 0CFC1h, 0CE81h, 00E40h
	 dw	 00A00h, 0CAC1h, 0CB81h, 00B40h, 0C901h, 009C0h, 00880h, 0C841h
	 dw	 0D801h, 018C0h, 01980h, 0D941h, 01B00h, 0DBC1h, 0DA81h, 01A40h
	 dw	 01E00h, 0DEC1h, 0DF81h, 01F40h, 0DD01h, 01DC0h, 01C80h, 0DC41h
	 dw	 01400h, 0D4C1h, 0D581h, 01540h, 0D701h, 017C0h, 01680h, 0D641h
	 dw	 0D201h, 012C0h, 01380h, 0D341h, 01100h, 0D1C1h, 0D081h, 01040h
	 dw	 0F001h, 030C0h, 03180h, 0F141h, 03300h, 0F3C1h, 0F281h, 03240h
	 dw	 03600h, 0F6C1h, 0F781h, 03740h, 0F501h, 035C0h, 03480h, 0F441h
	 dw	 03C00h, 0FCC1h, 0FD81h, 03D40h, 0FF01h, 03FC0h, 03E80h, 0FE41h
	 dw	 0FA01h, 03AC0h, 03B80h, 0FB41h, 03900h, 0F9C1h, 0F881h, 03840h
	 dw	 02800h, 0E8C1h, 0E981h, 02940h, 0EB01h, 02BC0h, 02A80h, 0EA41h
	 dw	 0EE01h, 02EC0h, 02F80h, 0EF41h, 02D00h, 0EDC1h, 0EC81h, 02C40h
	 dw	 0E401h, 024C0h, 02580h, 0E541h, 02700h, 0E7C1h, 0E681h, 02640h
	 dw	 02200h, 0E2C1h, 0E381h, 02340h, 0E101h, 021C0h, 02080h, 0E041h
	 dw	 0A001h, 060C0h, 06180h, 0A141h, 06300h, 0A3C1h, 0A281h, 06240h
	 dw	 06600h, 0A6C1h, 0A781h, 06740h, 0A501h, 065C0h, 06480h, 0A441h
	 dw	 06C00h, 0ACC1h, 0AD81h, 06D40h, 0AF01h, 06FC0h, 06E80h, 0AE41h
	 dw	 0AA01h, 06AC0h, 06B80h, 0AB41h, 06900h, 0A9C1h, 0A881h, 06840h
	 dw	 07800h, 0B8C1h, 0B981h, 07940h, 0BB01h, 07BC0h, 07A80h, 0BA41h
	 dw	 0BE01h, 07EC0h, 07F80h, 0BF41h, 07D00h, 0BDC1h, 0BC81h, 07C40h
	 dw	 0B401h, 074C0h, 07580h, 0B541h, 07700h, 0B7C1h, 0B681h, 07640h
	 dw	 07200h, 0B2C1h, 0B381h, 07340h, 0B101h, 071C0h, 07080h, 0B041h
	 dw	 05000h, 090C1h, 09181h, 05140h, 09301h, 053C0h, 05280h, 09241h
	 dw	 09601h, 056C0h, 05780h, 09741h, 05500h, 095C1h, 09481h, 05440h
	 dw	 09C01h, 05CC0h, 05D80h, 09D41h, 05F00h, 09FC1h, 09E81h, 05E40h
	 dw	 05A00h, 09AC1h, 09B81h, 05B40h, 09901h, 059C0h, 05880h, 09841h
	 dw	 08801h, 048C0h, 04980h, 08941h, 04B00h, 08BC1h, 08A81h, 04A40h
	 dw	 04E00h, 08EC1h, 08F81h, 04F40h, 08D01h, 04DC0h, 04C80h, 08C41h
	 dw	 04400h, 084C1h, 08581h, 04540h, 08701h, 047C0h, 04680h, 08641h
	 dw	 08201h, 042C0h, 04380h, 08341h, 04100h, 081C1h, 08081h, 04040h

	 .code

	 extrn	 GETBCRC:far

	 NPPROC  CALC_SUM -- Calculate The Checksum
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Calculate Checksum.

On exit:

AX	 =	 computed SUM

|

SUM_STR  struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
SUM_CNT  dw	 ?		; Size in paragraphs
SUM_ADR  dd	 ?		; Address
SUM_ACC  dw	 ?		; Accumulator seed

SUM_STR  ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <bx,cx,dx,si,es> ; Save registers

	 cld			; String ops forwards

	 mov	 dx,[bp].SUM_ACC ; Initialize accumulated check sum

	 mov	 cx,[bp].SUM_CNT ; Get count of paragraphs
CALC_SUM_NEXTSEG:
	 push	 cx		; Save outer loop counter

	 mov	 cx,16		; Inner loop counter

	 mov	 es,[bp].SUM_ADR.VSEG ; Get the segment to check
	 assume  es:nothing	; Tell the assembler about it

	 mov	 si,[bp].SUM_ADR.VOFF ; ES:SI ==> memory to SUM

CALC_SUM_NEXT:
	 add	 dl,es:[si].LO	; Get next value
	 adc	 dh,0		;

	 inc	 si		; Bump index
	 loop	 CALC_SUM_NEXT	; Jump if more bytes

	 add	 [bp].SUM_ADR.VSEG,1 ; Skip to next paragraph

	 pop	 cx		; Restore outer loop counter

	 loop	 CALC_SUM_NEXTSEG ; Jump if more

	 mov	 ax,dx		; Copy to result register

	 REGREST <es,si,dx,cx,bx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+4+2		; Return to caller, popping arguments

CALC_SUM endp			; End CALC_SUM procedure
	 NPPROC  CALC_CRC -- Calculate The CRC
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Calculate CRC.

On exit:

AX	 =	 computed CRC

|

CRC_STR  struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
CRC_CNT  dw	 ?		; Size in 64KB (assumed > 0)
CRC_ADR  dd	 ?		; Address
CRC_ACC  dw	 ?		; Accumulator seed

CRC_STR  ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <bx,cx,dx,si,es> ; Save registers

	 cld			; String ops forwards

	 mov	 dx,[bp].CRC_ACC ; Initialize accumulated CRC

	 mov	 cx,[bp].CRC_CNT ; Get count of paragraphs
CALC_CRC_NEXTSEG:
	 push	 cx		; Save outer loop counter

	 mov	 cx,16		; Inner loop counter

	 mov	 es,[bp].CRC_ADR.VSEG ; Get the segment to check
	 assume  es:nothing	; Tell the assembler about it

	 mov	 si,[bp].CRC_ADR.VOFF ; ES:SI ==> memory to CRC
CALC_CRC_NEXT:
	 lods	 es:[si].LO	; Get next byte

	 xor	 dl,al		; XOR into low-order byte of accumulated CRC

	 xor	 bh,bh		; Zero to use as word
	 mov	 bl,dl		; Copy to index register
	 shl	 bx,1-0 	; Convert from words to bytes

	 mov	 dl,dh		; Shift down one byte
	 xor	 dh,dh		; Zero for next time
	 xor	 dx,XORLIST[bx] ; Compute polynomial residue

	 loop	 CALC_CRC_NEXT	; Jump if more

	 add	 [bp].CRC_ADR.VSEG,1 ; Skip to next paragraph

	 pop	 cx		; Restore outer loop counter

	 loop	 CALC_CRC_NEXTSEG ; Jump if more

	 mov	 ax,dx		; Copy to result register

	 REGREST <es,si,dx,cx,bx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,ss:nothing

CALC_CRC endp			; End CALC_CRC procedure

	 PPROC	 Get_BIOSCRC -- Return The BIOS CRC
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Calculate the BIOS CRC

On exit:

AX	 =	 16-bit BIOS CRC
DX	 =	 1 if AX is valid
		 0 otherwise

|

	 call	 MAXPRES	; Determine if 386MAX is present

	 test	 SUB_FLAG,@SUB_VM ; Are in protected mode?
	 jz	 short GET_BCRC_NOMAX ; No, go do real mode CRC

	 xor	 dx,dx		; Assume not valid
	 call	 GETBCRC	; Calculate BCRC if in protected mode
	 jc	 short @F	; If AX not valid

	 mov	 dx,1		; ...	valid
@@:
	 jmp	 GET_BCRC_EXIT	; If AX not valid

GET_BCRC_NOMAX:
	 REGSAVE <bx,cx,es>	; Preserve used registers

	 mov	 ax,@RSV_SEG	; Get start of restart jump segment
	 mov	 es,ax		;
	 assume  es:nothing	; Tell assembler

	 xor	 bx,bx		; Initialize index
	 mov	 cx,16		; Number of bytes to move
@@:
	 mov	 al,es:[bx].LO	; Get a byte
	 mov	 FIXBUF[bx],al	; Save in internal buffer
	 inc	 bx		; Bump index
	 loop	 @B		; Do until all gone

; The AOX Snap-in CPU test, while apparently innocuous, causes some
; systems like the Grid 386SX MFT to interpret the OUT to 73h as an
; out to 71h.  This has unfortunate results, as in ASQ we may have last
; indexed the CMOS drive type.	MicroChannel systems should all properly
; handle address decoding on the I/O address bus.
	 test	 SUB_FLAG,@SUB_MCA ; Izit a MicroChannel machine?
	 jz	 short GET_BCRC_OK ; Jump if not

	 mov	 al,@AOX_RID	; Command to read CPU info for AOX
	 out	 @AOX_MMD,al	; Request CPU info for AOX
	 in	 al,@AOX_MMD	; Read first byte (should be 55h)
	 mov	 ah,al		; Save
	 in	 al,@AOX_MMD	; Read next byte (should be aah)
	 cmp	 ax,055aah	; Is it an AOX board
	 jne	 short GET_BCRC_OK ; No, go do the CRC

	 mov	 FIXBUF[1].EHI,0F000h ; Fix restart vector segment
	 mov	 FIXBUF[1].ELO,0E05Bh ; Fix restart vector offset

	 mov	 ah,0C0h	; Function to get system configuration
	 int	 15h		; Request info pointer ES:BX
	 assume  es:nothing	; Tell assembler

	 jc	 short @F	; Go if not supported

	 mov	 al,es:[bx].CFG_MODEL ; Get the ID byte

	 mov	 FIXBUF[14],al	; Set ID back to normal
@@:
	 mov	 FIXBUF[15],0	; Clear fixup

	 xor	 ax,ax		; Initialize check sum seed
	 push	 ax		; Pass seed
	 mov	 ax,PaSYSROM	; Get start of physical system ROM (E000 or F000)
	 push	 ax		; Pass the segment
	 xor	 bx,bx		; Initialize offset
	 push	 bx		; Pass the offset

	 neg	 ax		; Subtract from 10000h
	 dec	 ax		; One less for the restart paragraph
	 push	 ax		; Pass the length in paras
	 call	 CALC_SUM	; Calculate the check sum into AX

	 push	 ax		; Pass seed
	 push	 ds		; Pass the segment
	 lea	 ax,FIXBUF	; Get internal buffer adddress
	 push	 ax		; Pass the offset

	 mov	 ax,1		; Number of paragraphs to work on
	 push	 ax		; Pass the length in paras
	 call	 CALC_SUM	; Calculate the check sum into AX

	 neg	 al		; Adjust to make 0 sum
	 mov	 FIXBUF[15],al	; Save fixup

GET_BCRC_OK:
	 xor	 ax,ax		; Initialize CRC seed
	 push	 ax		; Pass seed
	 mov	 ax,PaSYSROM	; Get start of physical system ROM (E000 or F000)
	 push	 ax		; Pass the segment
	 xor	 bx,bx		; Initialize offset
	 push	 bx		; Pass the offset

	 neg	 ax		; Subtract from 10000h
	 dec	 ax		; One less for the restart paragraph
	 push	 ax		; Pass the length in paras
	 call	 CALC_CRC	; Calculate the CRC into AX

	 push	 ax		; Pass seed
	 push	 ds		; Pass the segment
	 lea	 ax,FIXBUF	; Get internal buffer adddress
	 push	 ax		; Pass the offset

	 mov	 ax,1		; Number of paragraphs to work on
	 push	 ax		; Pass the length in paras
	 call	 CALC_CRC	; Calculate the CRC into AX

	 REGREST <es,cx,bx>	; Restore the stuff we used
	 assume  es:nothing	; Tell assembler

	 mov	 dx,1		; Flag valid CRC in AX

GET_BCRC_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

Get_BIOSCRC endp		; End Get_BIOSCRC procedure

	 MEND			; End BIOSCRC module

