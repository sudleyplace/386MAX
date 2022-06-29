;' $Header:   P:/PVCS/MAX/386MAX/QMAX_FCN.ASV   1.6   30 May 1997 10:44:32   BOB  $
	 title	 QMAX_FCN -- 386MAX Argument Functions
	 page	 58,122
	 name	 QMAX_FCN

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Program segment HICODE,	dword-aligned, public, class 'prog'
	       Program segment ZCODE,	para-aligned,  public, class 'zcode'
	       Program segment ECODE,	dword-aligned, public, class 'ecode'
	       Program segment DEBUG,	byte-aligned,  public, class 'ecode'
	       Data    segment EDATA,	dword-aligned, public, class 'edata'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Group SGROUP:
	       Program segment SCODE,	para-aligned,  public, class 'scode'
	       Group IGROUP:
	       Data    segment IDATA,	dword-aligned, public, class 'idata'
	       Group JGROUP:
	       Data    segment JDATA,	dword-aligned, public, class 'jcode'
	       Group XGROUP:
	       Program segment XCODE,	byte-aligned,  public, class 'xcode'
	       Data    segment XDATA,	dword-aligned, public, class 'xdata'
	       Data    segment SEG_LEN, word-aligned,  public, class 'xdata'
	       Data    segment SEG_ACT, word-aligned,  public, class 'xdata'
	       Data    segment SEG_TAB, word-aligned,  public, class 'xdata'
	       Group YGROUP:
	       Data    segment YDATA,	dword-aligned, public, class 'ydata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include PTR.INC
	 include 8259.INC
	 include BITFLAGS.INC
	 include MAXDEV.INC
	 include CPUFET.INC
	 include CPUID.INC
	 include ABIOS.INC
	 include 386.INC
	 include DEVDRV.INC
	 include DIR.INC
	 include OPEN.INC
	 include VIDATTR.INC
	 include VIDCALL.INC
	 include BIOSDATA.INC

	 include QMAX_CFG.INC
	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
	 include QMAX_TRC.INC
	 include QMAX_FLX.INC
	 include QMAX_STK.INC
	 include QMAX_VMM.INC
	 include QMAXDPMI.INC
.list

PGROUP	 group	 CODE,HICODE,ZCODE,ECODE,DEBUG,EDATA,NCODE,NDATA
SGROUP	 group	 SCODE
IGROUP	 group	 IDATA
JGROUP	 group	 JDATA
if @OEM_SOFT
XGROUP	 group	 XCODE,XDATA,SEG_LEN,SEG_ACT,SEG_TAB
else
XGROUP	 group	 XCODE,XDATA
endif				; IF @OEM_SOFT
YGROUP	 group	 YDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC

	 extrn	 DBG_FLAG:word
	 include QMAX_DBG.INC

	 extrn	 DB2_FLAG:word
	 include QMAX_DB2.INC

	 extrn	 DB3_FLAG:word
	 include QMAX_DB3.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC

	 extrn	 PORT15:word
	 extrn	 PORT67:word
	 extrn	 EXTSIZE:dword
if @OEM_EMS
	 extrn	 EMMSIZE:dword
endif				; IF @OEM_EMS
	 extrn	 TOTSIZE:dword
	 extrn	 SWPSIZE:word

if @OEM_BCF
	 extrn	 SYSROM_START:word
	 extrn	 VIRT_DEV_DPFE:byte
endif				; IF @OEM_BCF

	 extrn	 CT_ROMCFG:byte
	 extrn	 CT_RAM_AB:byte
	 extrn	 CT_RAM_CD:byte
	 extrn	 CT_RAM_EF:byte

CODE	 ends			; End CODE segment


HICODE	 segment use16 dword public 'prog' ; Start HICODE segment
	 assume  ds:PGROUP

	 extrn	 RH_VEC:dword

HICODE	 ends			; End HICODE segment


ZCODE	 segment use16 para public 'zcode' ; Start ZCODE segment
	 assume  ds:PGROUP

if @OEM_HIFILL
	 extrn	 LSEG:tbyte
	 include LOAD_SEG.INC
endif				; IF @OEM_HIFILL

ZCODE	 ends			; End ZCODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

if @OEM_EMS
	 extrn	 EMM_GETPMR:near
	 extrn	 EMM_GETL2PMAP:near
endif				; IF @OEM_EMS
	 extrn	 READ_CHIPSET:near
	 extrn	 FKEYWAIT:far

ECODE	 ends			; End ECODE segment


DEBUG	 segment use16 byte public 'ecode' ; Start DEBUG segment
	 assume  cs:PGROUP

	 extrn	 DW2HEX:near

	 FPPROC  FDW2HEX -- Far Call to DW2HEX
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

Same as DW2HEX

On exit:

Same as DW2HEX

|

	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDW2HEX  endp			; End FDW2HEX procedure

DEBUG	 ends			; End DEBUG segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

if @OEM_VIRTUALMEM
	 extrn	 VMM_FLAG:word
endif				; IF @OEM_VIRTUALMEM

if @OEM_BCF
	 extrn	 FIX_FLAG:word
endif				; if @OEM_BCF

if @OEM_SOFT
	 extrn	 REP_FAC:word
endif				; IF @OEM_SOFT

if @OEM_DMA
	 include QMAX_DMA.INC
endif				; IF @OEM_DMA

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

if @OEM_DPMI
	 extrn	 DPM_FLAG:word
	 include QMAX_I31.INC
endif				; IF @OEM_DPMI

	 extrn	 PPMTAB:byte
	 include QMAX_PPM.INC

	 extrn	 CON64KB:dword
	 extrn	 CON1MB:dword

	 extrn	 LOADCOUNT:word
	 extrn	 LOADTAB:tbyte
	 extrn	 LOADTABIND:word
	 extrn	 LOADBYTE:dword
	 include QMAX_LOD.INC

	 extrn	 MAPSEG_NXT:word
	 extrn	 LOWOFF:dword
	 extrn	 LMLTOP:dword
if @OEM_EMS
	 extrn	 EMM_FNS10:word
	 extrn	 EMM_FNS11:word

	 extrn	 MRS_MAX:byte
	 extrn	 FRAME:word
	 extrn	 PORTPMR:word
	 extrn	 NPHYS16F:byte
	 extrn	 EMMBUG:byte
endif				; IF @OEM_EMS
	 extrn	 NSTACKS:word
if @OEM_DMA
	 extrn	 DMASIZE:word
endif				; IF @OEM_DMA
	 extrn	 INCSIZE:word
	 extrn	 VIDOFF:dword
	 extrn	 VIDSIZE:word
	 extrn	 PHYSIZE:dword
	 extrn	 PaMAX:dword
if @OEM_XMS
	 extrn	 XMSNHNDL:word
	 extrn	 HMAMIN:word

if @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 XMS_FLAG:word
	 include QMAX_XMS.INC
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
endif				; IF @OEM_XMS

if @OEM_BCF
	 extrn	 BCF_CNT:word
	 extrn	 BCF_SEG:word
	 extrn	 BCF_BIOSSIZE:dword
	 extrn	 BIOS_CRC64:word
	 extrn	 BIOS_CRC128:word
endif				; IF @OEM_BCF

if @OEM_SYS eq @OEMSYS_RET
	 extrn	 PSMSIZE:word
	 extrn	 PSMWIN:word
	 extrn	 PSMSEG:word
endif				; IF @OEM_SYS eq @OEMSYS_RET

if @OEM_DPMI
	 extrn	 LDT_SIZ:dword	; Size in bytes of LDT (/8)
	 extrn	 XLDT_SIZ:dword ; Size in bytes of extended LDT (/@DPMI_BOUND)
	 extrn	 HPDABUF_SIZ:word
	 extrn	 HPDABUF_OFF:word
	 extrn	 HPDASTK_SIZ:word
	 extrn	 HPDASTK_OFF:word
	 extrn	 HPDASTK_TOP:word
	 extrn	 HPDAVMC_CNT:word
	 extrn	 HPDAVMC_OFF:word
	 extrn	 DPMIHNDL_CNT:dword
	 extrn	 DPMIHNDL_SIZ:dword
	 extrn	 DPMIPDIR_CNT:dword
	 extrn	 DPMIDYN_SIZ:dword
	 extrn	 HPDA_NPAR:word
endif				; IF @OEM_DPMI

	 include QMAX_POS.INC
	 extrn	 POSDATA:word	; Save area for POS data

if @OEM_FLEXROM
	 extrn	 FLEXROM_FLAG:word
	 extrn	 FLEXROM_LEN:word
	 extrn	 FLEXROM_TBL:tbyte
endif				; IF @OEM_FLEXROM
	 extrn	 CHECKER_LEN:word

	 extrn	 XMSBND_BRKPNT:dword

	 extrn	 CACHEMASK:dword

	 extrn	 CPUFET_FLAG:dword

	 extrn	 IO_LIM_MASK:word

	 extrn	 CPUTYPE:byte

	 extrn	 CACHESIZE:dword
	 extrn	 CACHESZ_RM:word

	 public  CM4_FLAG
	 include QMAX_CM4.INC
CM4_FLAG dw	 0		; Command flags, part 4

	 public  DSTK_CNT,DSTK_ISIZ
DSTK_CNT dw	 6		; # DOS stacks to install (0=none)
DSTK_ISIZ dw	 128		; Size of each DOS stack in bytes (/4)

	 public  DSTK_HWINTS,DSTK_FLAG
DSTK_HWINTS db	 (256/8) dup (0) ; Bitmap for DOS stacks interrupts
DSTK_FLAG DSTK_REC <>		;  DOS stacks usage

EDATA	 ends			; End EDATA segment


SCODE	 segment use16 para public 'scode' ; Start SCODE segment
	 assume  ds:SGROUP

	 extrn	 SCODE_END:byte

SCODE	 ends			; End SCODE segment


JDATA	 segment use16 dword public 'jcode' ; Start JDATA segment
	 assume  ds:JGROUP

	 extrn	 NOSCAN_MAP:byte
	 extrn	 FILLPAT:dword

JDATA	 ends			; End JDATA segment


IDATA	 segment use16 dword public 'idata' ; Start IDATA segment
	 assume  ds:IGROUP

if @OEM_VIRTUALMEM
	 extrn	 BSPath:byte
	 extrn	 BSGTotal:dword
	 extrn	 BSMin:dword
endif				; IF @OEM_VIRTUALMEM

IDATA	 ends			; End IDATA segment


if @OEM_SOFT
SEG_TAB  segment use16 word public 'xdata' ; Start SEG_TAB segment
	 assume  ds:XGROUP

	 extrn	 SYSARG_TAB:word
	 extrn	 NSYSARGS:abs

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use16 word public 'xdata' ; Start SEG_LEN segment
	 assume  ds:XGROUP

	 extrn	 SYSARG_LEN:word

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use16 word public 'xdata' ; Start SEG_ACT segment
	 assume  ds:XGROUP

	 extrn	 SYSARG_ACT:dword

SEG_ACT  ends			; End SEG_ACT segment
endif				; IF @OEM_SOFT


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 NRD_FLAG:dword
	 include QMAX_NRD.INC

	 extrn	 MOVE_TAB:qword
	 extrn	 IOWRAP:byte

	 extrn	 MEM_MAP:byte,MEM_MAP_LEN:abs
	 extrn	 SEPARATOR:byte

	 extrn	 @XLAT_EXC:abs
	 extrn	 @XLAT_INC:abs
	 extrn	 @XLAT_OTH:abs
	 extrn	 @XLAT_OVR:abs
	 extrn	 @XLAT_ROM0:abs
	 extrn	 @XLAT_ROM1:abs
	 extrn	 @XLAT_ROM2:abs
	 extrn	 @XLAT_UNK:abs
	 extrn	 @XLAT_VID:abs

if @OEM_BCF
	 extrn	 DRVPATH_END:word
endif				; IF @OEM_BCF

if @OEM_XMS
	 extrn	 @MAX_XHNDLCNT:abs
endif				; IF @OEM_XMS

if @OEM_HIFILL
	 extrn	 PRGREG:word
endif				; IF @OEM_HIFILL

	 extrn	 CACHESZ_RM:word

if @OEM_DEBUG
	 public  EXEC_BLK
EXEC_BLK dw	 ?,?		; Load and relocation factors
endif				; IF @OEM_DEBUG

	 public  READ_CNT,READ_SEG
READ_CNT dw	 ?		; # bytes in the file
READ_SEG dw	 ?		; Segment of the file

	 public  PROF_CNT,PROF_SEG
PROF_CNT dw	 ?		; # bytes in the profile
PROF_SEG dw	 ?		; Segment of the profile

NDATA	 ends			; End NDATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 public  @QMAX_FCN_NCODE
@QMAX_FCN_NCODE:		; Mark module start in .MAP file

if @OEM_SRAM or @OEM_SYS eq @OEMSYS_HPRS or @OEM_SYS eq @OEMSYS_NEC
	 FPPROC  CHECK_CHIPSET -- Check on C and T CHIPSets
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Attempt to determine whether or not this system supports the 82C302,
82C307, or 82C212 by writing to I/O port 21h and checking to see if
the same value appears at I/O port 23h.

On exit:

CF	 =	 0 either 82C302, 82C307, or 82C212 appears to be present
	 =	 1 neither is present
If CF = 0,
CX	 =	 0 if 82C302 or 82C307
	 =	 1 if 82C212
If CF = 1,
CX	 =	 0 if no compatible CHIPSet present
	 =	 1 if NEAT CHIPSet with < 1MB

|

	 REGSAVE <ax,bx>	; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

; First ensure that I/O ports 22h and 23h are not decoded as
; I/O ports 20h and 21h.

; Register usage:
;
; AL	 =	 scratch
; BL	 =	 original value from I/O port 21h
; BH	 =	 original value from I/O port 23h
; AH	 =	 second   value from I/O port 23h

	 in	 al,@IMR	; Get and save the I/O port
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 mov	 bl,al		; Save to restore later

	 in	 al,@CT_DATA	; Get the I/O port
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 not	 al		; Complement the value so it's different
	 mov	 bh,al		; Save to compare

	 out	 @IMR,al	; Change the IMR
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 in	 al,@CT_DATA	; Get and save the I/O port
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 popf			; Restore flags

	 mov	 ah,al		; Save to compare
	 mov	 al,bl		; Get original value of IMR

	 out	 @IMR,al	; Restore it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 cmp	 ah,bh		; Compare original and second values
	 je	 short CHECK_CHIPSET_ERR0 ; Jump if same (thus same I/O ports)

; Note we must check for NEAT first because some systems (like the
; Packard-Bell laptop RJB brought in) responds to both register
; 64h and 08h, but it's a NEAT CHIPSet.

; If it's the 82C212, then Register 64h has bit 7 = 0

	 mov	 al,64h 	; 82C212 register
	 call	 READ_CHIPSET	; Read data from CHIPSet into AH

; Some CHIPSets (as on the NEC SX Plus) return all zeros for out of bound
; AT/386 registers so we must weed them out here

	 cmp	 ah,0		; Ensure some bits set
	 je	 short CHECK_CHIPSET_XNEAT ; Jump if not NEAT

	 test	 ah,@BIT7	; Ensure it's clear
	 jz	 short CHECK_CHIPSET_NEAT ; Jump if it is

; If it's the 82C302 or 82C307, then Register 08h has bit 7 = 0

CHECK_CHIPSET_XNEAT:
	 mov	 al,08h 	; 82C302/82C307 register
	 call	 READ_CHIPSET	; Read data from CHIPSet into AH

	 xor	 cx,cx		; Assume it's the 82C302/82C307

	 test	 ah,@BIT7	; Ensure it's clear
	 jz	 short CHECK_CHIPSET_CLC ; Jump if so

; The 82C307 can be distinguished by reading registers 14h-17h;
; at least one of them should be non-FF

	 mov	 bl,-1		; Initialize to identity element for AND
	 mov	 cx,17h-14h+1	; # registers to read
	 mov	 al,14h 	; First 82C307 bank register
@@:
	 call	 READ_CHIPSET	; Read data from CHIPSet into AH

	 and	 bl,ah		; Include in accumulator

	 inc	 al		; Skip to next register

	 loop	 @B		; Jump if more registers to read

	 cmp	 bl,-1		; Izit unchanged?
	 je	 short CHECK_CHIPSET_ERR0 ; Jump if so, hence no CHIPSet present

;;;;;;;; xor	 cx,cx		; It's the 82C307 (CX already zero)

	 jmp	 short CHECK_CHIPSET_CLC ; Join common OK code

CHECK_CHIPSET_NEAT:
	 mov	 cx,1		; It's the 82C212

; Ensure there's a full 1MB available

	 mov	 al,6Ah 	; 82C212 bank 0/1 enable register
	 call	 READ_CHIPSET	; Read data from CHIPSet into AH

	 and	 ah,@BIT5 or @BIT6 or @BIT7 ; Isolate relevant bits

	 cmp	 ah,000b shl 5	; Check for one bank, disabled
	 je	 short CHECK_CHIPSET_ERR1 ; Jump if so

	 cmp	 ah,001b shl 5	; Check for two banks, disabled
	 je	 short CHECK_CHIPSET_ERR1 ; Jump if so

	 cmp	 ah,010b shl 5	; Check for one bank, 256K and 64K
	 je	 short CHECK_CHIPSET_ERR1 ; Jump if so

	 cmp	 ah,011b shl 5	; Check for two banks, 256K and 64K
	 je	 short CHECK_CHIPSET_ERR1 ; Jump if so

	 cmp	 ah,100b shl 5	; Check for one bank, 256K only
	 je	 short CHECK_CHIPSET_ERR1 ; Jump if so
CHECK_CHIPSET_CLC:
	 clc			; Assume it's present

	 jmp	 short CHECK_CHIPSET_EXIT ; Join common exit code

CHECK_CHIPSET_ERR0:
	 xor	 cx,cx		; Indicate no CHIPSet present

	 jmp	 short CHECK_CHIPSET_ERR ; Join common error code

CHECK_CHIPSET_ERR1:
	 mov	 cx,1		; Indicate NEAT with < 1MB present
CHECK_CHIPSET_ERR:
	 stc			; Indicate not supported
CHECK_CHIPSET_EXIT:
	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CHIPSET endp		; End CHECK_CHIPSET procedure
endif				; IF @OEM_SRAM or @OEM_SYS eq @OEMSYS_HPRS or @OEM_SYS eq @OEMSYS_NEC

NCODE	 ends			; End NCODE segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

if @OEM_BCF
	 include QMAX_BCF.INC
	 extrn	 BCFINTS:tbyte
	 extrn	 NBCFINTS:abs
endif
if @OEM_EMS
	 extrn	 MAX_EMSMEM:dword
endif				; IF @OEM_EMS

if @OEM_HIFILL
	 extrn	 HPDAR:word
	 extrn	 XBDAR:word
	 extrn	 STACKR:word
endif				; IF @OEM_HIFILL

	 extrn	 OLDINT24_VEC:dword
	 extrn	 FLEXFILE_DPFE:byte
	 extrn	 PATHSTEM_LEN:word

	 public  LODBASE
LODBASE  dd	 0		; Start of file load area (0=uninitialized)

	 public  OLDINT1C_VEC
OLDINT1C_VEC dd  ?		; Save area for INT 1Ch handler

	 public  WAIT_CNT
WAIT_CNT dw	 ?		; Wait loop counter

	 public  EMMSIZE2
EMMSIZE2 dd	 -1		; Value of EMS= to calculate corresponding EXT=

	 public  DSTK_NPAR
DSTK_NPAR dw	 0		; Total size of all DOS stacks code and data
				; in paras

if @OEM_WIN3
	 extrn	 ALT_VIRT_DEV_NAME:word     ; Pointer to alternate VXD DPFE
	 extrn	 ALT_VIRT_DEV_NAME_LEN:word ; Length of above
endif				; IF @OEM_WIN3

if @OEM_FLEXROM
	 extrn	 FLEXROMINTS:tbyte
	 extrn	 FLEXROMINTS_OFF:word
	 extrn	 LASTKEY:word

	 public  VGASWAP_TEXT
VGASWAP_TEXT	db	'='
VGASWAP_TXTSRC	db	'C000,'                 ; Source
VGASWAP_TXTDST	db	'B000,'                 ; Destin
VGASWAP_TXTLEN	db	'8000,'                 ; Length in bytes
		db	'40,74,7C,10C,1B4,4A8;'
endif				; IF @OEM_FLEXROM

	 public  POSFILE_SLOTCHG
POSFILE_SLOTCHG db	0	; count of slots where POSFILE data differs
				; from CMOS values in POSDATA

if @OEM_DMA
extrn	 DMA_MAX_LEN:word
endif				; IF @OEM_DMA

	 public  SWAP_FNEZ
SWAP_FNEZ db	 @OEM_FILE,'.SWP',0 ; Filename.ext,0 for temporary SWAPFILE
SWAP_FNEZ_LEN equ $-SWAP_FNEZ	; Length of ...

XDATA	 ends			; End XDATA segment


YDATA	 segment use16 dword public 'Ydata' ; Start YDATA segment
	 assume  ds:YGROUP

	 extrn	 MSG_SEP:byte
	 extrn	 MSG_UNK:byte
	 extrn	 MSG_OVF:byte
	 extrn	 MSG_SWERR:byte
	 extrn	 MSG_VAL:byte

if @OEM_EMS
	 extrn	 MSG_CMDCHK_EMSEXT:byte
	 extrn	 MSG_CMDCHK_FRM1:byte

if @OEM_SYS eq @OEMSYS_HPRS
MSG_CMDCHK_INC1 equ MSG_CMDCHK_FRM1
MSG_CMDCHK_EXC1 equ MSG_CMDCHK_INC1
else
	 extrn	 MSG_CMDCHK_INC1:byte
MSG_CMDCHK_EXC1 equ MSG_CMDCHK_INC1
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
endif				; IF @OEM_EMS

if @OEM_WTK
	 extrn	 MSG_CMDCHK_WTK:byte
endif				; IF @OEM_WTK

if @OEM_MISC
	 extrn	 MSG_POPEN:byte
endif				; IF @OEM_MISC

if @OEM_BCF
	 extrn	 MSG_BCF_ARGERR:byte
	 extrn	 MSG_AUTOBCF_TERSE:byte
	 extrn	 MSG_AUTOBCF_INST:byte
	 extrn	 MSG_AUTOBCF_ARGERR:byte
	 extrn	 MSG_AUTOBCF_128K:byte
	 extrn	 MSG_AUTOBCF_64K:byte
endif				; IF @OEM_BCF

if @OEM_SOFT
	 extrn	 MSG_UNKSYS:byte
	 extrn	 MSG_NOIOWRAP:byte
endif				; IF @OEM_SOFT

if @OEM_DEBUG
	 extrn	 MSG_LEXEC:byte
	 extrn	 MSG_EXECUP:byte
	 extrn	 MSG_EXTLOD:byte
endif				; IF @OEM_DEBUG

	 extrn	 MSG_POSBOOT:byte

if @OEM_DPMI
	 extrn	 MSG_DPMI:byte
endif				; IF @OEM_DPMI

if @OEM_HIFILL
	 extrn	 MSG_DOS5:byte
endif				; IF @OEM_HIFILL

if @OEM_FLEXROM
	 extrn	 MSG_PRESS:byte
	 extrn	 MSG_VGASWAP_TWICE:byte
endif				; IF @OEM_FLEXROM

YDATA	 ends			; End YDATA segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP,ds:XGROUP

	 public  @QMAX_FCN_XCODE
@QMAX_FCN_XCODE:		; Mark module start in .MAP file

	 extrn	 POSWRITE:far
	 extrn	 NVRAM_CMPWRITE:far
	 extrn	 NVRAMFN:far
	 extrn	 NVRAM_CRC:far
	 extrn	 GET_POSID:near
if @OEM_BCF
	 extrn	 CHECK_BCF:near
endif				; IF @OEM_BCF
	 extrn	 XSKIP_WHITE:near
	 extrn	 XSKIP_BLACK:near
	 extrn	 GET_CMDARGS:near
	 extrn	 FILL_ROM:far
	 extrn	 INST24:far
	 extrn	 REST24:far
	 extrn	 CHECK_CNV:far
	 extrn	 DISP_UNK:near
	 extrn	 DISP_UNK2:near
	 extrn	 LOWERCASE:near
	 extrn	 BASE2BIN:near
	 extrn	 BASE2BIND:near
	 extrn	 UPPERCASE:near
	 extrn	 IZITCOMMENT:near
	 extrn	 IZITEOL:near
	 extrn	 XSKIP_EOL:near
	 extrn	 ABORT_IGNORE:near
if @OEM_MISC
	 extrn	 PROC_PROFILE:near
endif				; IF @OEM_MISC

if @OEM_FLEXROM
	 extrn	 ROMINT10:far
	 extrn	 ROMINT11:far
	 extrn	 ROMINT13:far
	 extrn	 ROMINT6D:far
	 extrn	 FINDIGN:far
	 extrn	 FINDERR:far

	 public  FLEXROM_RESOURCE
FLEXROM_RESOURCE label	byte	; List of all FlexROM resources
	 db	 00h		; Resource g
	 db	 @ROMINT_CODE	; Resource h

@FLEXRESOURCE_CNT equ ($-FLEXROM_RESOURCE)/(size FLEXROM_RESOURCE)

	 public  FLEXROM_ACTION
FLEXROM_ACTION	 label	word	; List of all FlexROM actions
	 dw	 offset XGROUP:ROMINT10 ; Action g
	 dw	 offset XGROUP:ROMINT11 ; Action h
	 dw	 offset XGROUP:ROMINT13 ; Action i
	 dw	 offset XGROUP:ROMINT6D ; Action j
	 dw	 offset XGROUP:FINDERR	; Action k

@FLEXACTION_CNT equ ($-FLEXROM_ACTION)/(size FLEXROM_ACTION)

@FIRST_FLEXRESOURCE	equ	'g'     ; Must be lower case
@FIRST_FLEXACTION	equ	'g'     ; Must be lower case

FLEXDEFAULT_STR struc
   FLEXDEFAULT_NUM	dw	?	; Interrupt number
   FLEXDEFAULT_RES	dw	?	; Default Resource type
   FLEXDEFAULT_ACT	dw	?	; Default Decoding Action (offset)
FLEXDEFAULT_STR ends

	 public  FLEX_DEFAULTS	; List of FlexROM Default Actions
FLEX_DEFAULTS	label	dword
	FLEXDEFAULT_STR <40h, @ROMINT_CODE or @ROMINT_VGA, offset XGROUP:ROMINT10> ; 10
	FLEXDEFAULT_STR <44h, @ROMINT_CODE,		   offset XGROUP:ROMINT11> ; 11
	FLEXDEFAULT_STR <4Ch, @ROMINT_CODE,		   offset XGROUP:ROMINT13> ; 13
	FLEXDEFAULT_STR <74h, @ROMINT_VGA,		   offset XGROUP:FINDIGN>  ; 1D
	FLEXDEFAULT_STR <7Ch, @ROMINT_VGA,		   offset XGROUP:FINDIGN>  ; 1F
	FLEXDEFAULT_STR <10Ch,@ROMINT_VGA,		   offset XGROUP:FINDIGN>  ; 43
	FLEXDEFAULT_STR <1B4h,@ROMINT_CODE or @ROMINT_VGA, offset XGROUP:ROMINT6D> ; 6D
	FLEXDEFAULT_STR <4A8h,@ROMINT_VGA,		   offset XGROUP:FINDIGN>  ; 40:A8

	 public  NFLEX_DEFAULTS
NFLEX_DEFAULTS equ ($-FLEX_DEFAULTS)/(type FLEXDEFAULT_STR) ; # defaults
endif				; IF @OEM_FLEXROM

	 NPPROC  DISPAZSTR -- Display ASCIIZ String With Attribute
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display ASCIIZ string with attribute

|

DAZS_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
DAZS_OFF dw	 ?		; Offset in YGROUP of ASCIIZ string to display
DAZS_ATTR db	 ?,?		; Screen attribute to use

DAZS_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <bx,si>	; Save registers

	 mov	 bl,[bp].DAZS_ATTR ; Get screen attribute
	 mov	 si,[bp].DAZS_OFF ; YGROUP:SI ==> ASCIIZ string to display
	 call	 DISPAZS	; Display AZS string with attribute

	 REGREST <si,bx>	; Restore

	 pop	 bp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPAZSTR endp			; End DISPAZSTR procedure
	 NPPROC  DISP_ERRLAST -- Display An Error Message With Last Keyword
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display an error message along with the keyword we're processing

|

DISPEL_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
DISPEL_OFF dw	 ?		; Offset in YGROUP of error message to display

DISPEL_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <si,di>	; Save registers

	 mov	 si,LASTKEY	; DS:SI ==> last keyword
	 mov	 di,[bp].DISPEL_OFF ; YGROUP:DI ==> error message
	 call	 DISP_UNK	; Display it along with unknown keyword at DS:SI

	 REGREST <di,si>	; Restore

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ERRLAST endp		; End DISP_ERRLAST procedure
	 NPPROC  DISP_ERRLAST2 -- Display An Error Message With Last Keyword
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display an error message along with the keyword we're processing
Also asks user (in DISP_ERR) if they would like to continue to load MAX,
or abort installation. (CF=1 if abort)

On Exit:
  CF = 1 if Abort is intended
  CF = 0 if user wishes to continue

|

;;;;This structure is defined above
;;;;DISPEL_STR struc
;;;;
;;;;	 dw	 ?		; Caller's BP
;;;;	 dw	 ?		; ...	   IP
;;;;DISPEL_OFF dw	 ?		; Offset in YGROUP of error message to display
;;;;
;;;;DISPEL_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <si,di>	; Save registers

	 mov	 si,LASTKEY	; DS:SI ==> last keyword
	 mov	 di,[bp].DISPEL_OFF ; YGROUP:DI ==> error message
	 call	 DISP_UNK2	; Display it along with unknown keyword at DS:SI

	 REGREST <di,si>	; Restore

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ERRLAST2 endp		; End DISP_ERRLAST2 procedure
	 NPPROC  ARGEND -- Search for End of Argument List
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Search for end of argument list

On entry:

DS:SI	 ==>	 current position in argument

On exit:

DS:DI	 ==>	 end of argument list

|

	 mov	 di,si		; DS:DI ==> starting offset

	 test	 NRD_FLAG,@NRD_PRO ; Are we in the profile?
	 jz	 short ARGEND_EXIT ; No, hence no arguments
ARGEND_NEXT:
	 cmp	 ds:[di].LO,TAB ; Allow this in the argument
	 je	 short @F	; Jump if so

	 cmp	 ds:[di].LO,' ' ; Stop when below this
	 jb	 short ARGEND_EXIT ; Jump if we're at the end
@@:
	 inc	 di		; Skip to next character

	 jmp	 ARGEND_NEXT	; Go around again

ARGEND_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ARGEND	 endp			; End ARGEND procedure
if @OEM_SYS eq @OEMSYS_RET
	 FPPROC  LCL_INT1C -- Secondary Hardware Timer Interrupt Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Secondary hardware timer interrupt handler.
Count down WAIT_CNT until zero.

|

	 pushf			; Save flags in case they're important

	 push	 ds		; Save for a moment

	 push	 seg XGROUP	; Setup DS to point to code segment
	 pop	 ds		; ... for @SETINT
	 assume  ds:XGROUP	; Tell the assembler about it

	 cmp	 WAIT_CNT,0	; Izit already zero?
	 je	 short @F	; Jump if so

	 dec	 WAIT_CNT	; Account for one timer tick
@@:
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 popf			; Restore

	 jmp	 OLDINT1C_VEC	; Continue on with next handler

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LCL_INT1C endp			; End LCL_INT1C procedure
endif				; IF @OEM_SYS eq @OEMSYS_RET
if @OEM_SYS eq @OEMSYS_RET
	 FPPROC  BOOTPAUSE -- Pause for A Moment
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Pause for a moment.

|

	 REGSAVE <ax,bx,dx,ds,es> ; Save registers

	 push	 seg XGROUP	; Setup DS to point to code segment
	 pop	 ds		; ... for @SETINT
	 assume  ds:XGROUP	; Tell the assembler about it

; Wait for some time to pass so that the user can read the screen message.
; The technique we use is to install an INT 1Ch handler and count the
; ticks as they go by.

	 mov	 al,1Ch 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old INT 1Ch handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDINT1C_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT1C_VEC.VSEG,es

@WAIT_SECS equ	 2		; Wait this many seconds

	 mov	 WAIT_CNT,18*@WAIT_SECS ; Set countdown timer used by INT1C
				; in units of timer ticks (~18/sec)

	 sti			; Ensure interrupts enabled

	 mov	 al,1Ch 	; Intercept this one
	 DOSCALL @SETINT,LCL_INT1C ; Install our handler
@@:
	 sti			; Ensure interrupts enabled

	 cmp	 WAIT_CNT,0	; Izit done?
	 jne	 short @B	; Jump if not

	 lds	 dx,OLDINT1C_VEC ; DS:DX ==> previous INT 1Ch handler
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 al,1Ch 	; Restore this one
	 DOSCALL @SETINT	; Restore previous handler

	 REGREST <es,ds,dx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BOOTPAUSE endp			; End BOOTPAUSE procedure
endif				; IF @OEM_SYS eq @OEMSYS_RET
if @OEM_MISC or @OEM_HIFILL or @OEM_WIN3
	 FPPROC  READFILE -- Read A File
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Read a file into memory starting at the next
available segment.

On entry:

DS:SI	 ==>	 d:\path\filename.ext

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise
DS:SI	 ==>	 next character in filename

|

READF_STR struc

	 dw	 ?		; Caller's BP
	 dd	 ?		; ...	   CS:IP
READF_FLAG dw	 ?		; Flag:  0 = don't delete
				;	 1 = delete when done
READF_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to last character

	 mov	 dx,si		; Save as start of filename

; Search for end of filename

@@:
	 lodsb			; Get next character

	 cmp	 al,'/'         ; Izit a separator?
	 je	 short @F	; Jump if so

	 cmp	 al,' '         ; Too small for filename?
	 ja	 short @B	; No, go around again
@@:
	 dec	 si		; Back off to terminator

; Attempt to open the file

	 mov	 cl,0		; String terminator
	 xchg	 cl,[si]	; Terminate filename.ext
	 mov	 al,0		; Access code for read-only
	 stc			; Assume error
	 DOSCALL @OPENF2	; Open the file at DS:DX
	 xchg	 cl,[si]	; Restore filename.ext
	 jc	 short READFILE_EXIT ; Something went wrong (note CF=1)

	 mov	 bx,ax		; Copy to file handle register

	 REGSAVE <bx,dx,ds>	; Save for a moment

	 mov	 ds,MAPSEG_NXT	; Setup DS for OPENF2
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 READ_SEG,ds	; Save for later use

	 xor	 dx,dx		; DS:DX ==> profile segment
	 mov	 cx,0FFFFh	; Read in all of it

	 stc			; Assume error
	 DOSCALL @READF2	; Read it in
				; Return with CF significant (used below)

	 mov	 READ_CNT,ax	; Save # bytes read
	 mov	 bx,ax		; Copy to index register
	 mov	 ds:[bx].LO,EOF ; Terminate with EOF

	 REGREST <ds,dx,bx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it
	 jc	 short READFILE_EXIT ; Something went wrong (note CF=1)

	 add	 ax,16		; Round up to para boundary (count in EOF, too)
	 shr	 ax,4-0 	; Convert from bytes to paras
	 add	 MAPSEG_NXT,ax	; Skip over this segment

	 DOSCALL @CLOSF2	; Close file handle BX

	 cmp	 [bp].READF_FLAG,1 ; Izit to be deleted?
	 jne	 short READFILE_XDEL ; Jump if not

	 mov	 cl,0		; String terminator
	 xchg	 cl,[si]	; Terminate filename.ext
	 DOSCALL @DELEF2	; Delete the file at DS:DX
	 xchg	 cl,[si]	; Restore filename.ext
READFILE_XDEL:
	 clc			; Indicate all went OK
READFILE_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

READFILE endp			; End READFILE procedure
endif				; IF @OEM_MISC or @OEM_HIFILL or @OEM_WIN3
	 NPPROC  MARKENTRY -- Mark Entries Avoiding ROM Overwrite
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Mark entries in MEM_MAP avoiding overwriting an initial ROM marker.
If an initial ROM marker is found, transfer it as the new start of ROM.

On entry:

AL	 =	 new marker
ES:DI	 ==>	 location in MEM_MAP to mark
CX	 =	 # entries to mark

On exit:

CX	 =	 0
ES:DI	 ==>	 (updated)

|

	 REGSAVE <ax>		; Save register

	 jcxz	 MARKENTRY_EXIT ; Jump if nothing to do

	 cmp	 PGROUP:[di].LO,@XLAT_ROM2 ; Izit in the middle of ROM?
	 jne	 short MARKENTRY_NEXT1ST ; Jump if not

; Search backwards for leading ROM marker

	 push	 di		; Save for a moment
@@:
	 dec	 di		; Back off to previous entry
	 mov	 ah,PGROUP:[di] ; Get previous entry

	 cmp	 ah,@XLAT_ROM2	; Izit still in the middle of ROM?
	 je	 short @B	; Jump if so

	 pop	 di		; Restore

	 mov	 PGROUP:[di],ah ; Save as new leading ROM marker
MARKENTRY_NEXT1ST:
	 mov	 ah,PGROUP:[di] ; Get old marker
	 mov	 PGROUP:[di],al ; Save new marker

	 cmp	 ah,@XLAT_ROM0	; Izit a 1st ROM marker?
	 je	 short @F	; Jump if so

	 cmp	 ah,@XLAT_ROM1	; Izit a 1st ROM marker?
	 jne	 short MARKENTRY_LOOP1ST ; Jump if not
@@:
	 inc	 di		; Skip to next entry

	 dec	 cx		; Account for it
	 jz	 short MARKENTRY_SAVE1ST ; Save old initial marker

; Search for secondary markers and replace with AL

MARKENTRY_NEXT2ND:
	 cmp	 PGROUP:[di].LO,@XLAT_ROM2 ; Izit a secondary marker?
	 mov	 PGROUP:[di],al ; Save new marker
	 jne	 short MARKENTRY_LOOP1ST ; Jump if not

	 inc	 di		; Skip to next entry

	 loop	 MARKENTRY_NEXT2ND ; Jump if more secondary entries
MARKENTRY_SAVE1ST:
	 cmp	 PGROUP:[di].LO,@XLAT_ROM2 ; Izit a secondary marker?
	 jne	 short MARKENTRY_EXIT ; Jump if not

	 mov	 PGROUP:[di],ah ; Save old initial marker

	 jmp	 short MARKENTRY_EXIT ; Join common exit code

MARKENTRY_LOOP1ST:
	 inc	 di		; Skip to next entry

	 loop	 MARKENTRY_NEXT1ST ; Jump if more entries to mark
MARKENTRY_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARKENTRY endp			; End MARKENTRY procedure
	 NPPROC  YMSGOUT2 -- Display YGROUP Message
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display YGROUP message.

Note that this routine might be called to note that we're not
running on a 386, so we are limited to 8088 instructions.

|

YMSGOUT2_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's return address
YMSGOUT2_OFF dw  ?		; Offset in YGROUP of message

YMSGOUT2_STR ends

	 push	 bp		; Prepare to address stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,dx,ds>	; Save registers

	 mov	 ax,seg YGROUP	; Get message segment
	 mov	 ds,ax		; Address it
	 assume  ds:YGROUP	; Tell the assembler about it

	 mov	 dx,[bp].YMSGOUT2_OFF ; DS:DX ==> message

	 DOSCALL @STROUT	; Display it

	 REGREST <ds,dx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

YMSGOUT2 endp			; End YMSGOUT2 procedure
if @OEM_LOFILL
	 NPPROC  VIDCOM -- Set Video Range
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Set video range

On entry:

BP	 =	 low value in paras
AX	 =	 length in paras

|

	 REGSAVE <bx,cx,di>	; Save registers

; Clear the existing video memory markers (to high DOS memory) from MEM_MAP
; and save new markers.

	 push	 ax		; Save length indicator

	 lea	 di,MEM_MAP	; ES:DI ==> start of memory map
	 mov	 al,@XLAT_VID	; Search for these
	 mov	 cx,MEM_MAP_LEN ; # bytes in MEM_MAP
   repne scas	 PGROUP:[di].LO ; Search for it (it must be there)

	 dec	 di		; Back off to start
	 mov	 bx,di		; Copy starting point
    repe scas	 PGROUP:[di].LO ; Search for others just like it

	 dec	 di		; Back off to last mismatch
	 mov	 cx,di		; Copy end+1 offset
	 mov	 di,bx		; Restore starting offset
	 sub	 cx,di		; Subtract to get length
	 mov	 al,@XLAT_OVR	; Mark as high DOS memory
     rep stos	 PGROUP:[di].LO

	 pop	 ax		; Restore

; Save new VIDOFF and VIDSIZE

	 mov	 cx,bp		; Copy starting offset
	 shr	 cx,10-4	; Convert from paras to 1KB
	 mov	 VIDOFF.ELO,cx	; Save for others to use

	 mov	 cx,ax		; Copy length
	 shr	 cx,10-4	; Convert from paras to 1KB
	 mov	 VIDSIZE,cx	; Save for others to use

; Save new markers

	 mov	 cx,ax		; Copy to count register
	 shr	 cx,9-4 	; Convert from paras to 512

; Mark as other VID in MEM_MAP

	 mov	 di,bp		; Copy starting offset
	 shr	 di,9-4 	; Convert from paras to 512
	 lea	 di,MEM_MAP[di] ; Point to spot within MEM_MAP

	 mov	 al,@XLAT_VID	; VID index
     rep stos	 PGROUP:[di].LO ; Save in memory map

	 REGREST <di,cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VIDCOM	 endp			; End VIDCOM procedure
endif				; IF @OEM_LOFILL
if @OEM_DEBUG
	 NPPROC  LOADUP -- Copy LOD Module To Extended Memory
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Copy a load module to extended memory

On entry:

PGROUP:DI ==>	 LOAD_STR for this module

On entry:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,ebx,ecx,edx,si> ; Save registers

	 mov	 edx,LODBASE	; Get last top of memory value

	 and	 edx,edx	; Izit specified as yet?
	 jnz	 short @F	; Jump if so

	 mov	 edx,PHYSIZE	; Use current physical size
	 shl	 edx,10-0	; Convert from 1KB to bytes
@@:
	 sub	 edx,LOADTAB.LOAD_USIZ[di] ; Less size of uninitialized data

	 mov	 ecx,LOADTAB.LOAD_SIZ[di] ; Get size of initialized data
	 sub	 edx,ecx	; Less it to get base address
	 mov	 LODBASE,edx	; Save as new value for next time
	 mov	 LOADTAB.LOAD_PHYS[di],edx ; Save physical address of image

	 cmp	 edx,CON1MB	; Ensure it's within bounds
	 jb	 near ptr LOADUP_ERR ; Jump if not

; If this module doesn't support MD_VSIZE, that's all we need do

	 test	 LOADTAB.LOAD_FLG[di],@LOAD_VSIZE ; Duzit support MD_VSIZE?
	 jz	 near ptr LOADUP_XVSIZE ; Jump if not

; Calculate DTE limit

	 mov	 ebx,ecx	; Copy to save in DTEs

	 dec	 ebx		; Convert from length to limit

	 cmp	 ebx,CON1MB	; Check against limit limit
	 jb	 short @F	; Jump if within range

	 shr	 ebx,12-0	; Convert from bytes to 4KB
	 or	 ebx,(mask $DTE_G) shl (8*(DESC_SEGLM1-DESC_BASE2)) ; Set G-bit
@@:

; Save DTE for source and destination limits

	 mov	 MOVE_TAB.MDTE_DS.DESC_SEGLM0,bx ; Save as data limit
	 mov	 MOVE_TAB.MDTE_ES.DESC_SEGLM0,bx ; ...
	 rol	 ebx,16 	; Swap high- and low-order words
	 mov	 MOVE_TAB.MDTE_DS.DESC_SEGLM1,bl ; Save size & flags
	 mov	 MOVE_TAB.MDTE_ES.DESC_SEGLM1,bl ; ...
;;;;;;;; ror	 ebx,16 	; Swap back

	 movzx	 ebx,LOADTAB.LOAD_SEG[di] ; Get segment of module in low DOS
	 shl	 ebx,4-0	; Convert from paras to bytes
LOADUP_NEXT:

; Save DTE for source base and A/R

	 mov	 MOVE_TAB.MDTE_DS.DESC_BASE01.EDD,ebx
	 rol	 ebx,8		; Rotate out the high-order byte
	 mov	 MOVE_TAB.MDTE_DS.DESC_BASE3,bl ; Save as base byte #3
	 ror	 ebx,8		; Rotate back
	 mov	 MOVE_TAB.MDTE_DS.DESC_ACCESS,CPL0_DATA

; Save DTE for destination base and A/R

	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE01.EDD,edx
	 rol	 edx,8		; Rotate out the high-order byte
	 mov	 MOVE_TAB.MDTE_ES.DESC_BASE3,dl ; Save as base byte #3
	 ror	 edx,8		; Rotate back
	 mov	 MOVE_TAB.MDTE_ES.DESC_ACCESS,CPL0_DATA

	 REGSAVE <ebx,ecx,edx,fs,gs> ; Save because you can never tell
				; what a BIOS might clobber

; Set move length as smaller of actual length
; and the maximum move length (64KB).

	 cmp	 ecx,CON64KB	; Izit too big?
	 jbe	 short @F	; Jump if not

	 mov	 ecx,CON64KB	; Use smaller
@@:
	 shr	 ecx,1-0	; Convert from bytes to words

	 lea	 si,MOVE_TAB	; ES:SI ==> GDT
	 mov	 ah,87h 	; Function code to BIOS block move
	 int	 15h		; Request BIOS service

	 REGREST <gs,fs,edx,ecx,ebx> ; Restore

	 cmp	 ah,0		; Did it work?
	 jne	 short LOADUP_ERR ; Jump if not

	 mov	 eax,CON64KB	; Get maximum length moved

	 add	 ebx,eax	; Skip to next source base
	 add	 edx,eax	; ...	       destin ...

	 sub	 ecx,eax	; Less length
	 ja	 short LOADUP_NEXT ; Jump if there's more to do

; Copy the MD_VSIZE portion to the next available segment

	 REGSAVE <di,ds,es>	; Save for a moment

	 mov	 ds,LOADTAB.LOAD_SEG[di] ; Get segment of file header
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ecx,ds:[0].MD_VSIZE ; Get # bytes to move

	 push	 es		; Save for a moment

	 mov	 ax,MAPSEG_NXT	; Get next available segment

	 mov	 es,ax		; Get next available segment
	 assume  es:nothing	; Tell the assembler about it

	 xchg	 ax,ds:[0].MD_IVIRT.VSEG ; Get INIT_VIRT segment

	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; Start at the beginning of the segment
	 xor	 di,di		; ...

S16  rep movs	 <es:[di].LO,ds:[si].LO> ; Copy to lower memory

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 add	 di,16-1	; Round up to para boundary
	 shr	 di,4-0 	; Convert from bytes to paras
	 add	 MAPSEG_NXT,di	; Skip over the low DOS memory portion

	 REGREST <es,ds,di>	; Restore
	 assume  ds:nothing,es:PGROUP ; Tell the assembler about it
LOADUP_XVSIZE:
	 clc			; Indicate all went well

	 jmp	 short LOADUP_EXIT ; Join common exit code

LOADUP_ERR:
	 stc			; Indicate the move failed
LOADUP_EXIT:
	 REGREST <si,edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOADUP	 endp			; End LOADUP procedure
endif				; IF @OEM_DEBUG
if @OEM_EMS
	 FPPROC  FCN_AMRS -- AMRS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_AMRS_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_AMRS_ERR ; Jump if too large

	 cmp	 ax,255 	; Check against maximum
	 jbe	 short @F	; It's within range

	 mov	 al,255 	; Use maximum
@@:
	 mov	 MRS_MAX,al	; Save for later use

	 clc			; Indicate all went well

	 jmp	 short FCN_AMRS_EXIT ; Join common exit code

FCN_AMRS_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_AMRS_ERR:
	 stc			; Indicate something went wrong
FCN_AMRS_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_AMRS endp			; End FCN_AMRS procedure
endif				; IF @OEM_EMS
	 FPPROC  FCN_AUTO -- AUTO Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CMD_FLAG,@CMD_XLO or @CMD_XHI ; Mark as NOLOW and NOHIGH
	 or	 GLB_FLAG,@GLB_AUTO ; Mark as initially  AUTO
	 and	 GLB_FLAG,not @GLB_ON ; ...and not ON
	 or	 CMD_FLAG,@CMD_INI ; Mark as present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_AUTO endp			; End FCN_AUTO procedure
if @OEM_BCF
	 FPPROC  BCF_ERRCOM -- BCF / AUTOBCF error display
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

If AUTOBCF or BCF= doesn't come up with an accessible file, we
check in BCF.LST for a matching filename.  If found, we tell 'em
to re-run INSTALL from the distribution diskette; INSTALL will
extract the correct BCF file.  If not found, we display the 64K
and 128K CRC values and tell 'em to try calling the BBS...

|

	 REGSAVE <ax,bx,cx,si,di,ds,READ_SEG> ; Save

; Format 64K and 128K CRCs into the message we'll display if we can't
; find it in BCF.LST.
	 lea	 di,YGROUP:MSG_AUTOBCF_128K ; Address of ____.BCF for 128K
	 mov	 ax,BIOS_CRC128 ; Binary value of 128K BIOS CRC

	 push	 es		; Save ES

	 push	 BIOS_CRC64	; Value for 64K BIOS CRC

	 push	 seg YGROUP	; YGROUP segment value
	 pop	 es		; Get segment for YGROUP
	 assume  es:YGROUP	; Tell the assembler

	 call	 FDW2HEX	; Convert AX to hex at ES:DI
	 pop	 ax		; Get 64K BIOS CRC from stack

	 lea	 di,YGROUP:MSG_AUTOBCF_64K ; Address of ____.BCF for 64K
	 call	 FDW2HEX	; Convert AX to hex at ES:DI

; Search for the 128K BIOS CRC in BCF.LST.  Each line consists of @xxxx.bcf

	 push	 fs		; XGROUP segment value
	 pop	 ds		; Address XGROUP
	 assume  ds:XGROUP	; Tell the assembler

	 lea	 si,XGROUP:FLEXFILE_DPFE ; Address start of path
	 mov	 bx,PATHSTEM_LEN ; Skip to first character after trailing '\'
	 mov	 XGROUP:[bx+si].EDD,'.FCB' ; 'BCF.'
	 mov	 XGROUP:[bx+si+4].EDD,'TSL' ; 'LST',0

	 pop	 es		; Restore ES
	 assume  es:PGROUP	; Tell the assembler

	 push	 0		; Mark as NOT to be deleted
	 call	 READFILE	; Read in the file at DS:SI
	 jc	 short BCF_ERRXLIST ; Jump if not present

; Data is at READ_SEG:0 for READ_CNT bytes

	 mov	 ds,READ_SEG	; Address segment for file data
	 assume  ds:nothing	; Tell the assembler

	 sub	 si,si		; Starting offset
	 mov	 cx,READ_CNT	; Length of file
	 cld			; String ops forwardly
BCF_NEXTLINE:
	 lods	 ds:[si].LO	; Get next byte
	 cmp	 al,'@'         ; Izit start of filename?
	 loopne  short BCF_NEXTLINE ; Go around again if not

	 jne	 short BCF_ERRXLIST ; Jump if end of file

; DS:SI ==> hex BCF value
	 REGSAVE <cx,si>	; Save
	 mov	 cx,16		; Use base 16 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 REGREST <si,cx>	; Restore
	 jc	 short BCF_NEXTLINE ; Ignore if too large

	 cmp	 ax,BIOS_CRC128 ; Izit our boy?
	 jne	 short BCF_NEXTLINE ; Go around again if not

	 push	 offset YGROUP:MSG_AUTOBCF_INST ; Pass address of error message
	 jmp	 short @F	; Join common code

BCF_ERRXLIST:
	 push	 offset YGROUP:MSG_AUTOBCF_ARGERR ; Pass address of error message
@@:
	 call	 YMSGOUT2	; Display YGROUP message

	 REGREST <READ_SEG,ds,di,si,cx,bx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BCF_ERRCOM endp 		; End BCF_ERRCOM procedure
endif				; IF @OEM_BCF
	 FPPROC  FCN_32BITDMA -- 32BITDMA Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 mov	 REP_FAC,1	; Use repeat factor of 1 for I/O ports
	 mov	 IO_LIM_MASK,-1 ; All I/O bits are significant

if @OEM_DMA
	 or	 CM2_FLAG,@CM2_EISA_DMA ; Mark as using EISA style DMA
	 mov	 DMA_MAX_LEN,@DMA_MAX_EISALEN ; Maximum size of DMA buffer
endif				; IF @OEM_DMA

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_32BITDMA endp		; End FCN_32BITDMA procedure
if @OEM_BCF
	 FPPROC  FCN_AUTOBCF -- AUTOBCF Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Process the matching BIOS Compression File
Construct the correct BCF= statement and call FCN_BCF

On entry:

DS:SI	 ==>	 next character in command line or profile

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise
DS:SI	 ==>	 next character in command line or profile (updated)

|

	 REGSAVE <ax,bx,cx,di>	; Save registers

; Check for optional /t for terse.  We'll also pass it with other options
; on to FCN_BCF.

	 REGSAVE <si,ds>	; Save for a moment

	 sub	 bx,bx		; Assume no /t option
FCN_AUTOBCF_OPTS:
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to last character in case not '/'

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 short FCN_AUTOBCF_XARGS ; Jump if so

	 call	 IZITEOL	; Check for end of the line
	 je	 short FCN_AUTOBCF_XARGS ; Jump if so

	 cmp	 al,'/'         ; Must be
	 jne	 short FCN_AUTOBCF_XARGS ; Ignore if not a switch

	 inc	 si		; Skip over '/'
	 lodsb			; Get next character
	 call	 LOWERCASE	; Convert AL to lowercase

	 cmp	 al,'t'         ; Terse option?
	 jne	 short FCN_AUTOBCF_OPTS ; Go around again if not

	 mov	 bx,si		; Save offset of next character
FCN_AUTOBCF_XARGS:
; Copy our own load path (we're assuming the BCF file is in the same subdir)

	 lea	 di,VIRT_DEV_DPFE ; ES:DI ==> local buffer
	 mov	 al,'='         ; Leading character for BCF= in FCN_BCF
S16	 stos	 VIRT_DEV_DPFE[di] ; Save in file spec

	 lds	 si,RH_VEC	; DS:SI ==> request header
	 assume  ds:nothing	; Tell the assembler about it

	 lds	 si,ds:[si].INIT_CMD_VEC ; Get address of command line args
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 cx,DRVPATH_END ; Get offset to end+1 of path
	 sub	 cx,si		; Less start to get length
S16  rep movs	 <VIRT_DEV_DPFE[di],ds:[si].LO> ; Copy it

	 REGREST <ds,si>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 al,'@'         ; Leading character for @xxx.BCF
S16	 stos	 VIRT_DEV_DPFE[di] ; Save in file spec

	 mov	 ax,BIOS_CRC128 ; Assume it's a 128KB BIOS
	 call	 BCF_FIND	; Attempt to find BCF file at VIRT_DEV_DPFE[1]
	 jnc	 short FCN_AUTOBCF1 ; Jump if found

	 mov	 ax,BIOS_CRC64	; Assume it's a  64KB BIOS
	 call	 BCF_FIND	; Attempt to find BCF file at VIRT_DEV_DPFE[1]
	 jnc	 short FCN_AUTOBCF1 ; Jump if found

	 or	 bx,bx		; Is the terse option set?
	 jz	 short @F	; Jump if not

	 mov	 si,bx		; Skip past /t option
	 push	 offset YGROUP:MSG_AUTOBCF_TERSE ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message
	 jmp	 short FCN_AUTOBCF_ERR ; Join common error code

@@:
	 call	 BCF_ERRCOM	; Call common error display code
FCN_AUTOBCF_ERR:
	 stc			; Indicate there was a problem

	 jmp	 short FCN_AUTOBCF_EXIT ; Join common exit code

; VIRT_DEV_DPFE contains BCF=name of the BCF file

FCN_AUTOBCF1:

; Skip to end of the line

	 mov	 al,0		; String terminator
	 mov	 cx,-1		; We know it's there
   repne scasb			; Skip over it
	 dec	 di		; Back off to trailing zero

; Copy optional arguments

	 push	 di		; Save for a moment

; Search for end of arguments

	 call	 ARGEND 	; Return with DS:DI ==> end of argument list
	 mov	 cx,di		; Copy ending offset

	 pop	 di		; Restore

	 sub	 cx,si		; Less current position to get length
S16  rep movs	 <VIRT_DEV_DPFE[di],ds:[si].LO> ; Copy to local buffer

	 mov	 al,0		; Terminator in case there's none
S16	 stos	 VIRT_DEV_DPFE[di] ; Save in file spec

; Call FCN_BCF pointing to local buffer

	 REGSAVE <si,ds>	; Save for a moment

	 push	 es		; Copy address of string
	 pop	 ds		; ...to DS:SI
	 assume  ds:PGROUP	; Tell the assembler about it

	 lea	 si,VIRT_DEV_DPFE ; DS:SI ==> "BCF= ..." string

	 FCALL	 FCN_BCF	; Far call using near
				; Return with CF significant

	 REGREST <ds,si>	; Restore
	 assume  ds:nothing	; Tell the assembler about it
FCN_AUTOBCF_EXIT:
	 REGREST <di,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_AUTOBCF endp		; End FCN_AUTOBCF procedure
endif				; IF @OEM_BCF
if @OEM_BCF
	 NPPROC  BCF_FIND -- Find a BCF File
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Find a BCF file

On entry:

VIRT_DEV_DPFE[1] starts the BCF file
ES:DI	 ==>	 char after '@' in name
AX	 =	 BIOS CRC to use

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 REGSAVE <eax,bx,dx,di,ds> ; Save registers

	 call	 FDW2HEX	; Convert AX to hex at ES:DI

	 mov	 eax,'FCB.'     ; Get trailing text
S16	 stos	 VIRT_DEV_DPFE.EDD[di] ; Save in tail

	 mov	 al,0		; String terminator
S16	 stos	 VIRT_DEV_DPFE[di] ; Save in tail

	 push	 OLDINT24_VEC	; Save old INT 24h handler's address
	 call	 INST24 	; Install local INT 24h handler

	 push	 es		; Copy address of string
	 pop	 ds		; ...to DS:DX
	 assume  ds:PGROUP	; Tell the assembler about it

	 DOSCALL @OPENF2,VIRT_DEV_DPFE[1] ; Attempt to open the file
	 jc	 short @F	; Jump if in error (note CF=1)

	 mov	 bx,ax		; Copy to handle register
	 DOSCALL @CLOSF2	; Close the file
				; Return with CF significant
@@:
	 call	 REST24 	; Restore INT 24h handler (not changing CF)
	 pop	 OLDINT24_VEC	; Restore old INT 24h handler's address

	 REGREST <ds,di,dx,bx,eax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BCF_FIND endp			; End BCF_FIND procedure
endif				; IF @OEM_BCF
if @OEM_BCF
	 FPPROC  FCN_BCF -- BCF=d:\path\filename.ext Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Process a BIOS Compression File

On entry:

DS:SI	 ==>	 next character in command line or profile

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise
DS:SI	 ==>	 next character in command line or profile (updated)

|

	 REGSAVE <eax,bx,cx>	; Save register

	 push	 OLDINT24_VEC	; Save old INT 24h handler's address
	 call	 INST24 	; Install local INT 24h handler

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 near ptr FCN_BCF_EQ ; Too bad

	 push	 0		; Mark as NOT to be deleted
	 call	 READFILE	; Read in the file at DS:SI
	 jc	 near ptr FCN_BCF_OPEN ; Something went wrong

	 mov	 ax,READ_SEG	; Get the segment
	 mov	 BCF_SEG,ax	; Save for later use
	 mov	 ax,READ_CNT	; Get the count
	 mov	 BCF_CNT,ax	; Save for later use

; Check for optional arguments

FCN_BCF_OPTS:
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to last character in case not '/'

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 near ptr FCN_BCF_XARGS ; Jump if so

	 call	 IZITEOL	; Check for end of the line
	 je	 near ptr FCN_BCF_XARGS ; Jump if so

	 cmp	 al,'/'         ; Must be
	 jne	 near ptr FCN_BCF_ARGERR ; Too bad

	 inc	 si		; Skip over '/'
	 lodsb			; Get next character
	 call	 LOWERCASE	; Convert AL to lowercase

	 cmp	 al,'t'         ; Terse option (AUTOBCF only)?
	 je	 short FCN_BCF_OPTS ; Ignore it if so

	 cmp	 al,'i'         ; Ignore error during Search BCF?
	 jne	 short @F	; Nope, check next option

	 or	 CMD_FLAG,@CMD_FORCEBCF ; Mark as FORCEBCF
	 jmp	 short FCN_BCF_OPTS ; Go look for more options
@@:
	 cmp	 al,'d'         ; Debug option?
	 jne	 short @F	; Nope, check next option

	 or	 DB3_FLAG,@DB3_BCF ; Debug through SRCH_BCFINT
	 jmp	 short FCN_BCF_OPTS ; Go look for more options
@@:
	 cmp	 al,'f'         ; Fix option?
	 jne	 short FCN_BCF_XF ; Nope, check next option

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to last character in case not '='

	 cmp	 al,'='         ; Must be
	 jne	 FCN_BCF_ARGERR ; Nope, must be invalid option

	 inc	 si		; Skip over '='

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX

	 cmp	 ax,width FIX_REC ; Izit within range?
	 jae	 FCN_BCF_ARGERR ; Nope, must be invalid option

	 bts	 FIX_FLAG,ax	; Set the fixup bit
	 jmp	 short FCN_BCF_OPTS ; Go look for more options

FCN_BCF_XF:
	 cmp	 al,'s'         ; Skip option?
	 jne	 FCN_BCF_ARGERR ; Nope, must be invalid option

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to last character in case not ','

	 cmp	 al,'='         ; Must be
	 jne	 FCN_BCF_ARGERR ; Nope, must be invalid option

FCN_BCF_INTBYPASS:
	 inc	 si		; Skip over '=' or ","

	 mov	 cx,16		; Use base 16 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX

	 shl	 ax,2		; Convert interrupt number to DWORD address
	 movzx	 eax,ax 	; Clear upper word

	 mov	 cx,NBCFINTS	; Number of entries in BCFINTS table
	 xor	 bx,bx		; Start at begining of table

FCN_BCF_INTLOOP:
	 cmp	 eax,BCFINTS.[bx].BCFINT_VEC ; Is this the interrupt in question?
	 je	 @F		; Yep, go on

	 add	 bx,size BCFINT_STR ; Bump pointer to next record
	 loop	 FCN_BCF_INTLOOP ; Check next record

	 jmp	 short FCN_BCF_ARGERR ; They passed us an invalid int number
@@:
	 lea	 ax,XGROUP:FINDIGN ; Get the offset of the ignore routine
	 mov	 BCFINTS.[bx].BCFINT_FIND.VOFF,ax ; Set function to ignore type

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to last character in case not ','

	 cmp	 al,','         ; More interrupts to skip?
	 je	 short FCN_BCF_INTBYPASS ; Jump if so

	 jmp	 FCN_BCF_OPTS	; Go look for more options

FCN_BCF_XARGS:

; Process the BCF

	 call	 CHECK_BCF	; Check it
	 jc	 short FCN_BCF_ERR ; Jump if error

; Mark MEM_MAP values for old ROM as high DOS

	 REGSAVE <cx,si,di>	; Save for a moment

	 mov	 di,SYSROM_START ; Get starting segment of system ROM
	 mov	 cx,di		; Copy to compute length
	 neg	 cx		; Subtract from 10000h to get size in paras
	 mov	 eax,BCF_BIOSSIZE ; Get the new size of the ROM in bytes
				; (as a multiple of 4KB)
	 shr	 eax,4-0	; Convert from bytes to paras
	 sub	 cx,ax		; Less the new size of the ROM in paras
				; to get length of area to fill in
	 neg	 ax		; Subtract from 1MB in paras
	 mov	 SYSROM_START,ax ; Save as new starting segment of system ROM
	 shr	 cx,9-4 	; Convert from paras to 512-bytes
	 shr	 di,9-4 	; Convert from paras to 512-bytes
	 lea	 di,MEM_MAP[di] ; ES:DI ==> SYSROM in MEM_MAP

; In case the user has already specified a use for the ROM at SYSROM_START,
; we search for the start of the system ROM

FCN_BCF_NEXT:
	 mov	 al,PGROUP:[di] ; Get next marker

	 cmp	 al,@XLAT_ROM0	; Izit a 1st entry?
	 je	 short FCN_BCF1 ; Jump if so

	 cmp	 al,@XLAT_ROM1	; Izit a 1st entry?
	 je	 short FCN_BCF1 ; Jump if so

	 inc	 di		; Skip to next marker

	 loop	 FCN_BCF_NEXT	; Jump if more markers

	 jmp	 short FCN_BCF_CLC ; Join common OK code

; Mark the MEM_MAP entries from old start of system ROM to the new start
; as high DOS

FCN_BCF1:
	 mov	 ah,al		; Save old initial marker
	 mov	 al,@XLAT_OVR	; Get high DOS marker
     rep stos	 PGROUP:[di].LO ; Mark as high DOS memory
	 mov	 al,ah		; Copy ROM type marker
S16	 stos	 PGROUP:[di].LO ; Save new initial marker in MEM_MAP

; Mark the MEM_MAP entries from the new start of system ROM to 10000h
; as ROM

	 lea	 cx,MEM_MAP	; Get start of memory map
	 add	 cx,MEM_MAP_LEN ; Plus length to get end + 1
	 sub	 cx,di		; Less start of new system ROM + 1 in bytes
	 mov	 al,@XLAT_ROM2	; Get secondary ROM marker
     rep stos	 PGROUP:[di].LO ; Mark as ROM

	 REGREST <di,si,cx>	; Restore
FCN_BCF_CLC:
	 and	 CMD_FLAG,not @CMD_XRM ; Mark as NOROM not specified

	 clc			; Mark as valid

	 jmp	 short FCN_BCF_EXIT ; Join common tail code

FCN_BCF_ARGERR:
	 push	 offset YGROUP:MSG_BCF_ARGERR ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 jmp	 short FCN_BCF_ERR ; Join common error code

FCN_BCF_OPEN:
	 call	 BCF_ERRCOM	; Call common error display code

	 jmp	 short FCN_BCF_ERR ; Join common tail code

FCN_BCF_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_BCF_ERR:
	 stc			; Indicate there was a problem
FCN_BCF_EXIT:
	 call	 REST24 	; Restore INT 24h handler
	 pop	 OLDINT24_VEC	; Restore old INT 24h handler's address

	 REGREST <cx,bx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_BCF  endp			; End FCN_BCF procedure
endif				; IF @OEM_BCF
	 FPPROC  FCN_CACHESIZE -- CACHESIZE=nnnn Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <eax,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_CACHESIZE_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIND	; Convert the number at DS:SI to binary in EAX
	 jc	 short FCN_CACHESIZE_ERR ; Jump if too large

; External cache size was specified in K.  We need to save it as a dword
; count for twice the size of the external cache.
	 add	 eax,(64-1)	; Round up to a multiple of 64K
	 and	 ax,not (64-1)	; Round down

	 cmp	 eax,4000h	; Izit above the maximum (1GB)?
	 ja	 short FCN_CACHESIZE_OVF ; Jump if so

	 shl	 eax,(10+1-2)	; Get size in dwords * 2
	 mov	 CACHESIZE,eax	; Save for later

	 shr	 eax,16-2	; Convert dwords to 64K blocks
	 cmp	 ax,10h 	; Izit greater than 1024K?
	 jbe	 short @F	; Jump if so

	 mov	 ax,10h 	; Maximum flush size for real mode
@@:
	 mov	 CACHESZ_RM,ax	; Save for later

	 clc			; Indicate success

	 jmp	 short FCN_CACHESIZE_EXIT ; Join common exit code

FCN_CACHESIZE_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
	 jmp	 short FCN_CACHESIZE_ERR ; Join common error

FCN_CACHESIZE_OVF:
	 push	 offset YGROUP:MSG_OVF ; Pass offset in YGROUP of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword

FCN_CACHESIZE_ERR:
	 stc			; Indicate something went wrong

FCN_CACHESIZE_EXIT:
	 REGREST <cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_CACHESIZE endp		; End FCN_CACHESIZE procedure
if @OEM_LOFILL
	 FPPROC  FCN_CGA -- CGA Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,bp>	; Save registers

	 mov	 bp,0B800h	; Get starting offset in paras
	 mov	 ax,00800h	; Get length in paras

	 call	 VIDCOM 	; Set video range to BP (low), AX (length)

	 clc			; Indicate all went well

	 REGREST <bp,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_CGA  endp			; End FCN_CGA procedure
endif				; IF @OEM_LOFILL
if @OEM_DEBUG
	 FPPROC  FCN_DBG8042 -- DEBUG=8042 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB3_FLAG,@DB3_8042 ; Use 8042 reset to reboot

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBG8042 endp		; End FCN_DBG8042 procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGABIOS -- DEBUG=ABIOS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB3_FLAG,@DB3_ABIOS ; Signal NMI on ABIOS calls if BCF in effect

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGABIOS endp		; End FCN_DBGABIOS procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGALLROM -- DEBUG=ALLROM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_AROM ; Force all ROM to RAM

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGALLROM endp		; End FCN_DBGALLROM procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGBIOS -- DEBUG=BIOS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 and	 DB3_FLAG,not @DB3_EPM ; Enter protected mode via BIOS code
				; rather than through MAX code
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGBIOS endp		; End FCN_DBGBIOS procedure
endif				; IF @OEM_DEBUG
if @OEM_EMS and @OEM_DEBUG
	 FPPROC  FCN_DBGCALL -- DEBUG=CALL Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_CALL ; Mark as NMI on PGMAPCALL

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGCALL endp		; End FCN_DBGCALL procedure
endif				; IF @OEM_EMS and @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGCAPS -- DEBUG=CAPS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_CAPS ; Mark as breakpoint interrupt on CapsLock

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGCAPS endp		; End FCN_DBGCAPS procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGCOMPROM -- DEBUG=COMPROM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_CROM ; Display debug info if COMPROM fails

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGCOMPROM endp		; End FCN_DBGCOMPROM procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGCR3 -- DEBUG=CR3 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_CR3 ; Mark as set high-order bit of CR3

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGCR3 endp 		; End FCN_DBGCR3 procedure
endif				; IF @OEM_DEBUG
if @OEM_DPMI
	 FPPROC  FCN_DBGDPMI -- DEBUG=DPMI Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DPM_FLAG,mask $DPM_DPMI ; Enable debugging of DPMI features

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGDPMI endp		; End FCN_DBGDPMI procedure
endif				; IF @OEM_DPMI
if @OEM_DPMI
	 FPPROC  FCN_DBGDPMIERR -- DEBUG=DPMIERR Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DPM_FLAG,mask $DPM_DPMIERR ; Enable debugging of DPMI errors

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGDPMIERR endp		; End FCN_DBGDPMIERR procedure
endif				; IF @OEM_DPMI
if @OEM_DPMI
	 FPPROC  FCN_DBGDPMILOCK -- DEBUG=DPMILOCK Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DPM_FLAG,mask $DPM_DPMILOCK ; Check for InDOS when paging

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGDPMILOCK endp		; End FCN_DBGDPMILOCK procedure
endif				; IF @OEM_DPMI
if @OEM_DPMI
	 FPPROC  FCN_DBGDPMINEWSEL -- DEBUG=DPMINEWSEL Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DPM_FLAG,mask $DPM_DPMINEWSEL ; Force new selector on all
				; allocates
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGDPMINEWSEL endp		; End FCN_DBGDPMINEWSEL procedure
endif				; IF @OEM_DPMI
if @OEM_DPMI
	 FPPROC  FCN_DBGDPMIPHYS -- DEBUG=DPMIPHYS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_DPMIPHYS ; Disable checks in DPMI_GETP2L

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGDPMIPHYS endp		; End FCN_DBGDPMIPHYS procedure
endif				; IF @OEM_DPMI
if @OEM_DPMI
	 FPPROC  FCN_DBGDPMISEL -- DEBUG=DPMISEL Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DPM_FLAG,mask $DPM_DPMISEL ; Enable debugging of LAST_DPMI_xS
				; selector errors
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGDPMISEL endp		; End FCN_DBGDPMISEL procedure
endif				; IF @OEM_DPMI
if @OEM_DPMI
	 FPPROC  FCN_DBGDPMISPURNT -- DEBUG=DPMISPURNT Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DPM_FLAG,mask $DPM_DPMISPURNT ; Enable debugging of spurious
				; NT task switches
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGDPMISPURNT endp		; End FCN_DBGDPMISPURNT procedure
endif				; IF @OEM_DPMI
if @OEM_DPMI
	 FPPROC  FCN_DBGDPMISTD -- DEBUG=DPMISTD Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DPM_FLAG,mask $DPM_DPMISTD ; Force KRNL386 to come up in
				; standard mode
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGDPMISTD endp		; End FCN_DBGDPMISTD procedure
endif				; IF @OEM_DPMI
if @OEM_DPMI
	 FPPROC  FCN_DBGDPMITERM -- DEBUG=DPMITERM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DPM_FLAG,mask $DPM_DPMITERM ; Signal INT 01h if we free
				; resources the client forgot about upon termination
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGDPMITERM endp		; End FCN_DBGDPMITERM procedure
endif				; IF @OEM_DPMI
if @OEM_DPMI
	 FPPROC  FCN_DBGDPMIV100 -- DEBUG=DPMIV100 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DPM_FLAG,mask $DPM_DPMIV100 ; Force DPMI version 1.00
				; even if Rational Systems-based program
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGDPMIV100 endp		; End FCN_DBGDPMIV100 procedure
endif				; IF @OEM_DPMI
if @OEM_DPMI
	 FPPROC  FCN_DBGDPMIXCOPY -- DEBUG=DPMIXCOPY Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DPM_FLAG,mask $DPM_DPMIXCOPY ; Don't check DPMI copyright
				; notices for Phar Lap and Rational
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGDPMIXCOPY endp		; End FCN_DBGDPMIXCOPY procedure
endif				; IF @OEM_DPMI
if @OEM_EMS and @OEM_DEBUG
	 FPPROC  FCN_DBGEMSERR -- DEBUG=EMSERR Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_EMSERR ; Signal INT 01h on EMS errors

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGEMSERR endp		; End FCN_DBGEMSERR procedure
endif				; IF @OEM_EMS and @OEM_DEBUG
if @OEM_EMS and @OEM_DEBUG
	 FPPROC  FCN_DBGEMSPTE -- DEBUG=EMSPTE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_EPTE ; Mark as testing EMS PTEs

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGEMSPTE endp		; End FCN_DBGEMSPTE procedure
endif				; IF @OEM_EMS and @OEM_DEBUG
if @OEM_EMS and @OEM_DEBUG
	 FPPROC  FCN_DBGEMSRDWR -- DEBUG=EMSRDWR Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 mov	 EMMBUG,2	; Level 2 EMM debugging (catch reads
				; from and/or writes into unmapped
				; EMS pages)
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGEMSRDWR endp		; End FCN_DBGEMSRDWR procedure
endif				; IF @OEM_EMS and @OEM_DEBUG
if @OEM_EMS and @OEM_DEBUG
	 FPPROC  FCN_DBGEMSSAVE -- DEBUG=EMSSAVE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_ESAVE ; Enable EMMBUG for EMS save page maps

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGEMSSAVE endp		; End FCN_DBGEMSSAVE procedure
endif				; IF @OEM_EMS and @OEM_DEBUG
if @OEM_EMS and @OEM_DEBUG
	 FPPROC  FCN_DBGEMSWRIT -- DEBUG=EMSWRIT Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 mov	 EMMBUG,1	; Level 1 EMM debugging (catch writes
				; into unmapped EMS pages)
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGEMSWRIT endp		; End FCN_DBGEMSWRIT procedure
endif				; IF @OEM_EMS and @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGEPM -- DEBUG=EPM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB3_FLAG,@DB3_EPM ; Enter protected mode via MAX code
				; rather than through int 15 AH=89
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGEPM endp 		; End FCN_DBGEPM procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGEVM -- DEBUG=EVM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_EVM ; Mark as debugging Enter VM 8086 mode

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGEVM endp 		; End FCN_DBGEVM procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGFILL -- DEBUG=FILL Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 push	 ds		; Prepare to address JGROUP

	 push	 seg JGROUP	; Get the segment
	 pop	 ds		; Address it
	 assume  ds:JGROUP	; Tell the assembler

	 mov	 FILLPAT,0CC9066F1h ; ICE Int 01, NOPD, Int 3

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGFILL endp		; End FCN_DBGFILL procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGHLT -- DEBUG=HLT Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_HLT ; Mark as NMI on CLI/HLT

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGHLT endp 		; End FCN_DBGHLT procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGI06 -- DEBUG=I06 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_I06 ; Mark as error on Invalid Opcodes

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGI06 endp 		; End FCN_DBGI06 procedure
endif				; IF @OEM_DEBUG
if @OEM_EMS and @OEM_DEBUG
	 FPPROC  FCN_DBGI67 -- DEBUG=I67 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_I67 ; Mark as debugging INT 67h calls

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGI67 endp 		; End FCN_DBGI67 procedure
endif				; IF @OEM_EMS and @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGINV -- DEBUG=INV Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_INV ; Mark as UGHNF ==> INT 06h

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGINV endp 		; End FCN_DBGINV procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGIOWRAP -- DEBUG=IOWRAP Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 mov	 CHECKER_LEN,03FFh+1 ; Mark as length of CHECKERxxx tables
	 mov	 IOWRAP,0FFh	; Mark as debugging I/O wraps at FFFF

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGIOWRAP endp		; End FCN_DBGIOWRAP procedure
endif				; IF @OEM_DEBUG
if @OEM_EMS and @OEM_DEBUG
	 FPPROC  FCN_DBGJMP -- DEBUG=JMP Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_JMP ; Mark as NMI on PGMAPJMP

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGJMP endp 		; End FCN_DBGJMP procedure
endif				; IF @OEM_EMS and @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGLED -- DEBUG=LED Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_LED ; Mark as blink LEDs during EVM code

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGLED endp 		; End FCN_DBGLED procedure
endif				; IF @OEM_DEBUG
	 FPPROC  FCN_DBGNOVCPI -- DEBUG=NOVCPI Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DPM_FLAG,mask $DPM_NOVCPI ; Disable VCPI presence detection

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGNOVCPI endp		; End FCN_DBGNOVCPI procedure
if @OEM_DEBUG
	 FPPROC  FCN_DBGNOWRAP -- DEBUG=NOWRAP Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_XWRAP ; Mark as debugging stack wraps

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGNOWRAP endp		; End FCN_DBGNOWRAP procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGPIC -- DEBUG=PIC Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB3_FLAG,@DB3_PIC ; Mark as reprogramming PIC on EPM

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGPIC endp 		; End FCN_DBGPIC procedure
endif				; IF @OEM_DEBUG
if @OEM_EMS and @OEM_DEBUG
	 FPPROC  FCN_DBGPMR -- DEBUG=PMR Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_PMR ; Mark as NMI on PMR I/O

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGPMR endp 		; End FCN_DBGPMR procedure
endif				; IF @OEM_EMS and @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGRC -- DEBUG=RC Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_RC ; Mark as reason code termination message

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGRC endp			; End FCN_DBGRC procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGROM -- DEBUG=ROM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_ROM ; Mark as NMI on ROM writes

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGROM endp 		; End FCN_DBGROM procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGROMSWAP -- DEBUG=ROMSWAP Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_ROMSW ; Don't single-step over writes
				; into video ROM
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGROMSWAP endp		; End FCN_DBGROMSWAP procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGSCRUB -- DEBUG=SCRUB Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB3_FLAG,@DB3_SCRUB ; Mark as call SWAT in SCRUB_SHADOW

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGSCRUB endp		; End FCN_DBGSCRUB procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGSOR -- DEBUG=SOR Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_SOR ; Mark as UGHNF ==> INT 0Dh

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGSOR endp 		; End FCN_DBGSOR procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGTIME -- DEBUG=TIME Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB3_FLAG,@DB3_TIME ; Mark as call SWAT in TIME_ALLMEM

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGTIME endp		; End FCN_DBGTIME procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGTRIP -- DEBUG=TRIP Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB3_FLAG,@DB3_TRIP ; Use triple fault to reboot

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGTRIP endp		; End FCN_DBGTRIP procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGUNSHADOWROM -- DEBUG=UNSHADOWROM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_SROM ; Display debug info if UNSHADOWROM fails

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGUNSHADOWROM endp 	; End FCN_DBGUNSHADOWROM procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG and @OEM_VCPI
	 FPPROC  FCN_DBGVCPI -- DEBUG=VCPI Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_VCPI ; Mark as debugging VCPI code

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGVCPI endp		; End FCN_DBGVCPI procedure
endif				; IF @OEM_DEBUG and @OEM_VCPI
if @OEM_DEBUG and @OEM_VDS
	 FPPROC  FCN_DBGVDS -- DEBUG=VDS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_VDS ; Mark as call SWAT on VDS calls

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGVDS endp 		; End FCN_DBGVDS procedure
endif				; IF @OEM_DEBUG and @OEM_VDS
if @OEM_DEBUG and @OEM_VCPI
	 FPPROC  FCN_DBGVMS -- DEBUG=VMS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_VMS ; Mark as call SWAT on buggy
				; VCPI mode switches
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGVMS endp 		; End FCN_DBGVMS procedure
endif				; IF @OEM_DEBUG and @OEM_VCPI
	FPPROC	FCN_NOCRR -- NOCRR Function
	assume	ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	or	CM4_FLAG,@CM4_NOCRR ; Mark as in effect

	clc			; Indicate all went well

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOCRR endp			; End FCN_NOCRR procedure
	 FPPROC  FCN_NOGATE -- NOGATE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 cmp	 CPUTYPE,04h	; Izit a 486 or higher?
	 jb	 short NOGATE_EXIT ; Jump if not

	 and	 CPUFET_FLAG,not @CPUFET_INVD ; Don't use INVD/WBINVD
NOGATE_EXIT:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOGATE endp 		; End FCN_NOGATE procedure
if @OEM_DMA and @OEM_DEBUG
	 FPPROC  FCN_DBGXDMA -- DEBUG=XDMA Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_XDMA ; Mark as no DMA PTE checking

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGXDMA endp		; End FCN_DBGXDMA procedure
endif				; IF @OEM_DMA and @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_DBGX09 -- DEBUG=X09 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_X09 ; Mark as no INT 09h IDT trap

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGX09 endp 		; End FCN_DBGX09 procedure
endif				; IF @OEM_DEBUG
if @OEM_EMS and @OEM_DEBUG
	 FPPROC  FCN_DBGX67 -- DEBUG=X67 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_X67 ; Mark as no INT 67h IDT trap

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGX67 endp 		; End FCN_DBGX67 procedure
endif				; IF @OEM_EMS and @OEM_DEBUG
if @OEM_EMS and @OEM_DEBUG
	 FPPROC  FCN_DBGXM -- DEBUG=XM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_XM ; Mark as signal NMI on XMove interrupts

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGXM endp			; End FCN_DBGXM procedure
endif				; IF @OEM_EMS and @OEM_DEBUG
if @OEM_DEBUG and @OEM_XMS
	 FPPROC  FCN_DBGXMS -- DEBUG=XMS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB2_FLAG,@DB2_XMS ; Mark as call SWAT on XMS calls

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGXMS endp 		; End FCN_DBGXMS procedure
endif				; IF @OEM_DEBUG and @OEM_XMS
if @OEM_DEBUG and @OEM_XMS
	 FPPROC  FCN_DBGXMSPTE -- DEBUG=XMSPTE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DB3_FLAG,@DB3_XPTE ; Mark as testing XMS PTEs

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGXMSPTE endp		; End FCN_DBGXMSPTE procedure
endif				; IF @OEM_DEBUG and @OEM_XMS
if @OEM_DEBUG
	 FPPROC  FCN_DBGXR -- DEBUG=XR Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 DBG_FLAG,@DBG_XR ; Mark as allow XR moves

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DBGXR endp			; End FCN_DBGXR procedure
endif				; IF @OEM_DEBUG
if @OEM_DMA
	 FPPROC  FCN_DMA -- DMA Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT |

Set the DMA buffer length

|

	 REGSAVE <ax,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_DMA_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_DMA_ERR ; Jump if too large

	 cmp	 ax,@DMA_MIN_LEN ; Check against minimum buffer length
	 jae	 short @F	; It's within range

	 mov	 ax,@DMA_MIN_LEN ; Use minimum buffer length
@@:
	 cmp	 ax,DMA_MAX_LEN ; Check against maximum (128 KB or 16 MB)
	 jbe	 short @F	; It's within range

	 mov	 ax,DMA_MAX_LEN ; Use maximum buffer length
@@:
	 add	 ax,4-1 	; Round up to 4KB boundary
	 and	 ax,not (4-1)

	 mov	 DMASIZE,ax	; Save for later use
	 or	 CM3_FLAG,@CM3_DMA ; Mark as specified

	 clc			; Indicate all went well

	 jmp	 short FCN_DMA_EXIT ; Join common exit code

FCN_DMA_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_DMA_ERR:
	 stc			; Indicate something went wrong
FCN_DMA_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DMA  endp			; End FCN_DMA procedure
endif				; IF @OEM_DMA
if @OEM_EMS and @OEM_SYS ne @OEMSYS_ILIM
	 FPPROC  FCN_DOS4 -- DOS4 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM3_FLAG,@CM3_DOS4 ; Mark as DOS4 specified

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DOS4 endp			; End FCN_DOS4 procedure
endif				; IF @OEM_EMS and @OEM_SYS ne @OEMSYS_ILIM
if @OEM_HIFILL
	 FPPROC  FCN_DOS5 -- DOS5 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

This keyword has no function, since we automatically detect
DOS=UMB.  Ignore it, but not quietly.

|

	 push	 offset YGROUP:MSG_DOS5 ; "DOS5 keyword is obsolete; ..."
	 call	 YMSGOUT2	; Display YGROUP message

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DOS5 endp			; End FCN_DOS5 procedure
endif				; IF @OEM_HIFILL
if @OEM_DPMI
	 FPPROC  FCN_DPMIMEM -- DPMIMEM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

DPMIMEM=lll,sss,bbb,ccc,hhh,ppp,ddd
						    Min 	     Max
where lll is the # entries in the LDT		    @NLDTE_MIN	     8192
      sss is the byte size of the HPDA stack	    @HPDASTK_MIN     ...
      bbb is the byte size of the HPDA buffer	    @HPDABUF_MIN     ...
      ccc is the # VM callbacks 		    @HPDAVMC_MIN     ...
      hhh is the # DPMI memory handles		    @DPMIHNDL_MIN    ...
      ppp is the # page directories		    @DPMIPDIR_MIN    ...
  and ddd is the byte size of the dynamic save area @DPMIDYN_MIN     ...

All items but the first are optional.  Missing items may be elided.

|

	 REGSAVE <eax,ecx,edx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 near ptr FCN_DPMIMEM_EQ ; Too bad

; Check for an initial (optional) value
;     lll is the # entries in the LDT
; This value times 8 is saved into LDT_SIZ

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit elided?
	 je	 short FCN_DPMIMEM0 ; Jump if not

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 near ptr FCN_DPMIMEM_CALC ; Jump if so

	 call	 IZITEOL	; Check for end of the line
	 je	 near ptr FCN_DPMIMEM_CALC ; Jump if so

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_DPMIMEM_MSG ; Jump if too large

	 cmp	 ax,@NLDTE_MIN	; Check against minimum
	 jae	 short @F	; Jump if it's within range

	 mov	 ax,@NLDTE_MIN	; Use minimum
@@:
	 cmp	 ax,8192	; Check against maximum
	 jbe	 short @F	; It's within range

	 mov	 ax,8192	; Use maximum
@@:
	 movzx	 eax,ax 	; Zero to use as dword
	 mov	 ecx,eax	; Copy to calculate size of bitmap
	 add	 ecx,8*8-1	; Round up to next qword of bits
	 and	 ecx,not (8*8-1) ; ...
	 shr	 ecx,3-0	; Convert from bits to bytes
	 mov	 XLDT_SIZ,ecx	; Save as byte size of bitmap
	 imul	 eax,eax,type DESC_STR ; Times the size of each entry
	 mov	 LDT_SIZ,eax	; Save for later use
	 add	 eax,XLDT_SIZ	; Add to get pre-rounded extended size
	 add	 eax,@DPMI_BOUND-1 ; Round up to next
	 and	 eax,not (@DPMI_BOUND-1) ; ... boundary for ALLOCMEM
	 mov	 XLDT_SIZ,eax	; Save for later use

; Check for a second (optional) value delimited by a comma
;     sss is the byte size of the HPDA stack
; saved into HPDASTK_SIZ

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit present?
	 jne	 near ptr FCN_DPMIMEM_CALC ; Jump if not
FCN_DPMIMEM0:
	 inc	 si		; Skip over separator
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit elided?
	 je	 short FCN_DPMIMEM1 ; Jump if so

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 near ptr FCN_DPMIMEM_CALC ; Jump if so

	 call	 IZITEOL	; Check for end of the line
	 je	 near ptr FCN_DPMIMEM_CALC ; Jump if so

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_DPMIMEM_MSG ; Jump if too large

	 and	 ax,not (4-1)	; Round down to a dword boundary

	 cmp	 ax,@HPDASTK_MIN ; Check against minimum
	 jae	 short @F	; Jump if it's within range

	 mov	 ax,@HPDASTK_MIN ; Use minimum
@@:
	 mov	 HPDASTK_SIZ,ax ; Save for later use

; Check for a third (optional) value delimited by a comma
;     bbb is the byte size of the HPDA buffer
; saved into HPDABUF_SIZ

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit present?
	 jne	 near ptr FCN_DPMIMEM_CALC ; Jump if not
FCN_DPMIMEM1:
	 inc	 si		; Skip over separator
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit elided?
	 je	 short FCN_DPMIMEM2 ; Jump if so

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 near ptr FCN_DPMIMEM_CALC ; Jump if so

	 call	 IZITEOL	; Check for end of the line
	 je	 near ptr FCN_DPMIMEM_CALC ; Jump if so

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_DPMIMEM_MSG ; Jump if too large

	 and	 ax,not (4-1)	; Round down to a dword boundary

	 cmp	 ax,@HPDABUF_MIN ; Check against minimum
	 jae	 short @F	; Jump if it's within range

	 mov	 ax,@HPDABUF_MIN ; Use minimum
@@:
	 mov	 HPDABUF_SIZ,ax ; Save for later use

; Check for a fourth (optional) value delimited by a comma
;     ccc is the # VM callbacks
; saved into HPDAVMC_CNT

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit present?
	 jne	 near ptr FCN_DPMIMEM_CALC ; Jump if not
FCN_DPMIMEM2:
	 inc	 si		; Skip over separator
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit elided?
	 je	 short FCN_DPMIMEM3 ; Jump if so

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 near ptr FCN_DPMIMEM_CALC ; Jump if so

	 call	 IZITEOL	; Check for end of the line
	 je	 near ptr FCN_DPMIMEM_CALC ; Jump if so

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_DPMIMEM_MSG ; Jump if too large

	 cmp	 ax,@HPDAVMC_MIN ; Check against minimum
	 jae	 short @F	; Jump if it's within range

	 mov	 ax,@HPDAVMC_MIN ; Use minimum
@@:
	 mov	 HPDAVMC_CNT,ax ; Save for later use

; Check for a fifth (optional) value delimited by a comma
;     hhh is the # DPMI memory handles
; saved into DPMIHNDL_CNT

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit present?
	 jne	 near ptr FCN_DPMIMEM_CALC ; Jump if not
FCN_DPMIMEM3:
	 inc	 si		; Skip over separator
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit elided?
	 je	 short FCN_DPMIMEM4 ; Jump if so

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 near ptr FCN_DPMIMEM_CALC ; Jump if so

	 call	 IZITEOL	; Check for end of the line
	 je	 near ptr FCN_DPMIMEM_CALC ; Jump if so

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_DPMIMEM_MSG ; Jump if too large

	 cmp	 ax,@DPMIHNDL_MIN ; Check against minimum
	 jae	 short @F	; Jump if it's within range

	 mov	 ax,@DPMIHNDL_MIN ; Use minimum
@@:
	 movzx	 eax,ax 	; Zero to use as dword
	 mov	 DPMIHNDL_CNT,eax ; Save for later use
	 imul	 eax,type DPMIHNDL_STR ; Times # bytes in each entry
	 add	 eax,@DPMI_BOUND-1 ; Round up to next
	 and	 eax,not (@DPMI_BOUND-1) ; ... boundary for ALLOCMEM
	 mov	 DPMIHNDL_SIZ,eax ; Save for later use

; Check for a sixth (optional) value delimited by a comma
;     ppp is the # page directories
; saved into DPMIPDIR_CNT

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit present?
	 jne	 near ptr FCN_DPMIMEM_CALC ; Jump if not
FCN_DPMIMEM4:
	 inc	 si		; Skip over separator
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit elided?
	 je	 short FCN_DPMIMEM5 ; Jump if so

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 short FCN_DPMIMEM_CALC ; Jump if so

	 call	 IZITEOL	; Check for end of the line
	 je	 short FCN_DPMIMEM_CALC ; Jump if so

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_DPMIMEM_MSG ; Jump if too large

	 cmp	 ax,@DPMIPDIR_MIN ; Check against minimum
	 jae	 short @F	; Jump if it's within range

	 mov	 ax,@DPMIPDIR_MIN ; Use minimum
@@:
	 movzx	 eax,ax 	; Zero to use as dword
	 mov	 DPMIPDIR_CNT,eax ; Save for later use

; Check for a seventh (optional) value delimited by a comma
;     ddd is the byte size of the dynamic save area
; saved into DPMIDYN_SIZ

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit present?
	 jne	 short FCN_DPMIMEM_CALC ; Jump if not
FCN_DPMIMEM5:
	 inc	 si		; Skip over separator
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit elided?
	 je	 short FCN_DPMIMEM6 ; Jump if so

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 short FCN_DPMIMEM_CALC ; Jump if so

	 call	 IZITEOL	; Check for end of the line
	 je	 short FCN_DPMIMEM_CALC ; Jump if so

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_DPMIMEM_MSG ; Jump if too large

	 cmp	 ax,@DPMIDYN_MIN ; Check against minimum
	 jae	 short @F	; Jump if it's within range

	 mov	 ax,@DPMIDYN_MIN ; Use minimum
@@:
	 and	 eax,@DPMI_BOUND-1 ; Round down to proper boundary
	 mov	 DPMIDYN_SIZ,eax ; Save for later use
FCN_DPMIMEM6:
FCN_DPMIMEM_CALC:

; Calculate HPDA dynamic data area offsets from the above values

	 mov	 ax,size HPDA_STR  ; Get size of static elements
	 add	 ax,4-1 	; Round up to dword boundary
	 and	 ax,not (4-1)	; ...
	 mov	 HPDASTK_OFF,ax ; Save for later use

	 add	 ax,HPDASTK_SIZ ; Plus its size
	 jc	 short FCN_DPMIMEM_MSG ; Jump if it's too large

	 mov	 HPDASTK_TOP,ax ; Save for later use
	 mov	 HPDABUF_OFF,ax ; Save for later use

	 add	 ax,HPDABUF_SIZ ; Plus its size
	 jc	 short FCN_DPMIMEM_MSG ; Jump if it's too large

	 mov	 HPDAVMC_OFF,ax ; Save for later use
	 mov	 cx,HPDAVMC_CNT ; Get # VM callbacks
	 imul	 cx,size HPDAVMC_STR ; Times # bytes per callback
	 jc	 short FCN_DPMIMEM_MSG ; Jump if it's too large

	 add	 ax,cx		; Plus its size
	 jc	 short FCN_DPMIMEM_MSG ; Jump if it's too large

	 add	 ax,16-1	; Round up to para boundary
	 jc	 short FCN_DPMIMEM_MSG ; Jump if it's too large

;;;;;;;; and	 ax,not (16-1)	; ...
	 shr	 ax,4-0 	; Convert from bytes to paras

	 mov	 HPDA_NPAR,ax	; Save for later use

	 clc			; Indicate all went well

	 jmp	 short FCN_DPMIMEM_EXIT ; Join common exit code

FCN_DPMIMEM_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword

	 jmp	 short FCN_DPMIMEM_ERR ; Join common error code

FCN_DPMIMEM_MSG:
	 push	 offset YGROUP:MSG_DPMI ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message
FCN_DPMIMEM_ERR:
	 stc			; Indicate something went wrong
FCN_DPMIMEM_EXIT:
	 REGREST <edx,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_DPMIMEM endp		; End FCN_DPMIMEM procedure
endif				; IF @OEM_DPMI
if @OEM_EMS and @OEM_EEMS
	 FPPROC  FCN_EEMS -- EEMS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM2_FLAG,@CM2_EEMS ; Mark as EEMS specified

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_EEMS endp			; End FCN_EEMS procedure
endif				; IF @OEM_EMS and @OEM_EEMS
if @OEM_EMS
	 FPPROC  FCN_EMS_SUB -- Subroutine to FCN_EMS
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Subroutine to FCN_EMS

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,cx>	; Save registers

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIND	; Convert the number at DS:SI to binary in EAX
	 jc	 short FCN_EMS_SUB_EXIT ; Jump if too large

	 test	 LCL_FLAG,@LCL_DRV ; Another EMS driver present?
	 jnz	 short FCN_EMS_SUB_CLC ; Yes, just ignore this value

	 and	 eax,not (16-1) ; Round down to 16KB boundary

	 cmp	 eax,MAX_EMSMEM ; Izit bigger than the maximum allowed?
	 ja	 short FCN_EMS_SUB_ERR ; Jump if so

	 mov	 EMMSIZE2,eax	; Save for later use

	 and	 eax,eax	; Izit EMS=0?
	 jnz	 short FCN_EMS_SUB_CLC ; Jump if not

	 mov	 EMMSIZE,eax	; Save for later use
	 or	 CMD_FLAG,@CMD_EMS ; Mark as present
	 mov	 NPHYS16F,0	; Mark as no physical 16KB pages in EMS frame

	 jmp	 short FCN_EMS_SUB_CLC ; Join common OK code

FCN_EMS_SUB_ERR:
if @OEM_SYS ne @OEMSYS_HPRS
	 push	 offset YGROUP:MSG_OVF ; Pass offset in YGROUP of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
endif				; IF @OEM_SYS ne @OEMSYS_HPRS
	 stc			; Indicate something went wrong

	 jmp	 short FCN_EMS_SUB_EXIT ; Join common exit code

FCN_EMS_SUB_CLC:
	 clc			; Indicate all went well
FCN_EMS_SUB_EXIT:
	 REGREST <cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_EMS_SUB endp		; End FCN_EMS_SUB procedure
endif				; IF @OEM_EMS
if @OEM_EMS and @OEM_SYS ne @OEMSYS_HPRS
	 FPPROC  FCN_EMS -- EMS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Because we now have a common memory pool, this keyword
is almost obsolete.  The only value of interest is EMS=0.
Parse the line to ensure the syntax is proper
and to skip over it, but otherwise ignore it.

|


	 REGSAVE <ax>		; Save register

	 test	 CMD_FLAG,@CMD_EXT ; EXT= already specified?
	 jz	 short @F	; No

	 push	 offset YGROUP:MSG_CMDCHK_EMSEXT ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 jmp	 short FCN_EMS_ERR ; Join common error code

@@:
	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_EMS_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 call	 FCN_EMS_SUB	; Handle via subroutine
	 jc	 short FCN_EMS_ERR ; Jump if too large

	 clc			; Indicate all went well

	 jmp	 short FCN_EMS_EXIT ; Join common exit code

FCN_EMS_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_EMS_ERR:
	 stc			; Indicate something went wrong
FCN_EMS_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_EMS  endp			; End FCN_EMS procedure
endif				; IF @OEM_EMS and @OEM_SYS ne @OEMSYS_HPRS
if @OEM_EMS
	 FPPROC  FCN_EMS30 -- EMS30 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

EMS30 function

|

	 or	 CM4_FLAG,@CM4_EMS30 ; Mark as supported
	 mov	 EMM_FNS10,offset PGROUP:EMM_GETPMR ; Install handler
	 mov	 EMM_FNS11,offset PGROUP:EMM_GETL2PMAP ; ...

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_EMS30 endp			; End FCN_EMS30 procedure
endif				; IF @OEM_EMS
if @OEM_EMS and @OEM_SYS ne @OEMSYS_ILIM
	 FPPROC  FCN_EXCLUDE -- EXCLUDE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx,di,bp>	; Save registers
FCN_EXCLUDE_AGAIN:
	 call	 GET_CMDARGS	; Parse command line for xxxx-yyyy
	 jc	 short FCN_EXCLUDE_ERR ; Jump if something went wrong
				; Return with BP = 1st arg, AX = length

; Ensure that the starting and length values are a multiple of 16KB

	 test	 ax,(16*1024/16)-1 ; Ensure it's on a 16KB boundary
	 jnz	 short FCN_EXCLUDE_ERR1 ; It isn't

	 test	 bp,(16*1024/16)-1 ; Ensure it's on a 16KB boundary
	 jnz	 short FCN_EXCLUDE_ERR1 ; It isn't

; Mark the entries in MEM_MAP as @XLAT_EXC unles they are already ROM

	 call	 EXCLUDE_SUB	; Exclude from para BP of length AX paras

	 mov	 SEPARATOR,','  ; Mark as new separator

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Check for more arguments
	 je	 short FCN_EXCLUDE_AGAIN ; Yes, go around again

;;;;;;;; or	 CM2_FLAG,@CM2_EXC ; Mark as present

	 clc			; Indicate all went well

	 jmp	 short FCN_EXCLUDE_EXIT ; Join common exit code

FCN_EXCLUDE_ERR1:
	 push	 offset YGROUP:MSG_CMDCHK_EXC1 ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message
FCN_EXCLUDE_ERR:
	 stc			; Indicate something went wrong
FCN_EXCLUDE_EXIT:
	 mov	 SEPARATOR,'='  ; Mark as old separator

	 REGREST <bp,di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_EXCLUDE endp		; End FCN_EXCLUDE procedure
endif				; IF @OEM_EMS and @OEM_SYS ne @OEMSYS_ILIM
	 NPPROC  EXCLUDE_SUB -- Subroutine to Exclude Memory
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Mark the entries in MEM_MAP as @XLAT_EXC unles they are already ROM

On entry:

BP	 =	 starting location in paras
AX	 =	 length in paras

|

	 REGSAVE <ax,cx,di>	; Save registers

	 mov	 cx,ax		; Copy to count register
	 shr	 cx,9-4 	; Convert from paras to 512-byte
	 jz	 short EXCLUDE_SUB_PPM ; None to mark

	 mov	 di,bp		; Copy to index register
	 shr	 di,9-4 	; Convert from paras to 512-byte
	 lea	 di,MEM_MAP[di] ; Point to spot within MEM_MAP
EXCLUDE_SUB_NEXT:
	 cmp	 PGROUP:[di].LO,@XLAT_OVR ; High DOS memory?
	 je	 short @F	; Yes, EXCLUDE it

	 cmp	 PGROUP:[di].LO,@XLAT_UNK ; Unknown memory?
	 jne	 short EXCLUDE_SUB_LOOP ; No, skip it
@@:
	 mov	 PGROUP:[di].LO,@XLAT_EXC ; Mark as EXCLUDEd
EXCLUDE_SUB_LOOP:
	 inc	 di		; Skip to next entry

	 loop	 EXCLUDE_SUB_NEXT ; Jump if more entries to check
EXCLUDE_SUB_PPM:

; Mark the entry in PPMTAB as @PPM_EXC

	 mov	 cx,ax		; Copy to count register
	 shr	 cx,14-4	; Convert from paras to 16KB

	 mov	 di,bp		; Copy to index register
	 shr	 di,14-4	; Convert from paras to 16KB
	 lea	 di,PPMTAB[di]	; Point to spot within PPMTAB

	 mov	 al,@PPM_EXC	; EXC index
     rep stos	 PGROUP:[di].LO ; Save in memory map

	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EXCLUDE_SUB endp		; End EXCLUDE_SUB procedure
if @OEM_EMS
	 FPPROC  FCN_EXT -- EXT Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <eax,cx>	; Save registers

	 test	 LCL_FLAG,@LCL_DRV ; Another EMS driver present?
	 jnz	 short FCN_EXT_SKIP ; Yes, ignore previous EMS=

	 test	 CMD_FLAG,@CMD_EMS ; EMS= already specified?
	 jz	 short FCN_EXT_SKIP ; No

	 push	 offset YGROUP:MSG_CMDCHK_EMSEXT ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 jmp	 short FCN_EXT_ERR ; Join common error code

FCN_EXT_SKIP:
	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_EXT_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIND	; Convert the number at DS:SI to binary in EAX
	 jc	 short FCN_EXT_ERR ; Jump if too large

	 test	 LCL_FLAG,@LCL_DRV ; Another EMS driver present?
	 jnz	 short @F	; Yes, ignore this keyword

	 mov	 EXTSIZE,eax	; Save for later use
	 or	 CMD_FLAG,@CMD_EXT ; Mark as present
@@:
	 clc			; Indicate all went well

	 jmp	 short FCN_EXT_EXIT ; Join common exit code

FCN_EXT_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_EXT_ERR:
	 stc			; Indicate something went wrong
FCN_EXT_EXIT:
	 REGREST <cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_EXT  endp			; End FCN_EXT procedure
endif				; IF @OEM_EMS
if @OEM_SYS eq @OEMSYS_RET
	 FPPROC  FCN_EXTSIZE -- EXTSIZE=nnnn Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <eax,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_EXTSIZE_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIND	; Convert the number at DS:SI to binary in EAX
	 jc	 short FCN_EXTSIZE_ERR ; Jump if too large

if @OEM_DEBUG
; If we've already loaded a LOD module, we've used the
; wrong value for PHYSIZE

	 cmp	 LODBASE,0	; Izit used as yet?
	 jne	 short FCN_EXTSIZE_EXTLOD ; Jump if so
endif				; IF @OEM_DEBUG
	 and	 eax,not (4-1)	; Round down to a multiple of four

	 mov	 TOTSIZE,eax	; Save for later use
	 add	 eax,1024	; Plus first megabyte
	 mov	 PHYSIZE,eax	; Save as top of physical memory
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 mov	 PaMAX,eax	; Save as current maximum physical address

; If TOP384 is specified, clear its actions and recall it

	 test	 CM2_FLAG,@CM2_TOP ; Izit specified?
	 jz	 short @F	; Jump if not

	 and	 CM2_FLAG,not @CM2_TOP ; Clear its actions
	 and	 I15_FLAG,not @I15_CPQ ; ...

	 call	 far ptr FCN_TOP384 ; Call it again with new PHYSIZE
@@:
	 clc			; Indicate all went well

	 jmp	 short FCN_EXTSIZE_EXIT ; Join common exit code

if @OEM_DEBUG
FCN_EXTSIZE_EXTLOD:
	 push	 offset YGROUP:MSG_EXTLOD ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 jmp	 short FCN_EXTSIZE_ERR ; Join common error code
endif				; IF @OEM_DEBUG

FCN_EXTSIZE_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_EXTSIZE_ERR:
	 stc			; Indicate something went wrong
FCN_EXTSIZE_EXIT:
	 REGREST <cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_EXTSIZE endp		; End FCN_EXTSIZE procedure
endif				; IF @OEM_SYS eq @OEMSYS_RET
if @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT
	 FPPROC  FCN_FASTRAM -- FASTRAM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM3_FLAG,@CM3_FSTRM ; Mark as AST FAST RAM board present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_FASTRAM endp		; End FCN_FASTRAM procedure
endif				; IF @OEM_SYS eq @OEMSYS_AST386 or @OEM_SOFT
if @OEM_FLEXROM
	 FPPROC  FCN_FLEXROM -- VGA SWAP Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Syntax:

FLEXROM=xxxx,yyyy,zzzz[,nn[ab][,nn[ab]...]]
	where xxxx is the source segment in paras
	where yyyy is the destin ...
	where zzzz is the source length in bytes
	where nn is a resource (40,4A8,etc)
	where a is an optional relocation type (code,data,etc)
	where b is an optional single-stepping action routine

|

	 REGSAVE <eax,bx,cx,dx,di>	; Save registers

	 mov	 bx,FLEXROM_LEN ; Get index into table

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character in case not '='

	 cmp	 al,'='         ; Izit present?
	 jne	 near ptr FCN_FLEXROM_ERR ; Jump if not

; Get ROM Source segment

	 inc	 si		; Skip over the separator
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,16		; Use base 16 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_FLEXROM_ERR ; Jump if too large

; Ensure it's on a 4KB boundary

	 and	 ax,not (4*1024/16-1) ; Round down to 4KB boundary

	 mov	 FLEXROM_TBL[bx].FLEX_SRC,ax ; Save as source segment
	 mov	 dx,ax		; Save source segment

; Get ROM destination segment

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character in case not ','

	 cmp	 al,','         ; Izit present?
	 jne	 near ptr FCN_FLEXROM_ERR ; Jump if not

	 inc	 si		; Skip over the separator
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,16		; Use base 16 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_FLEXROM_ERR ; Jump if too large

; Ensrue it's on a 4KB noundary

	 and	 ax,not (4*1024/16-1) ; Round down to 4KB boundary

	 mov	 FLEXROM_TBL[bx].FLEX_DST,ax ; Save as destin segment

; Get ROM Length in bytes

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character in case not ','

	 cmp	 al,','         ; Izit present?
	 jne	 near ptr FCN_FLEXROM_ERR ; Jump if not

	 inc	 si		; Skip over the separator
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,16		; Use base 16 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_FLEXROM_ERR ; Jump if too large

; Ensure it's on a 4KB boundary

	 and	 ax,not (4*1024/16-1) ; Round down to 4KB boundary

	 mov	 FLEXROM_TBL[bx].FLEX_LEN,ax ; Save as ROM length

; Get any (and all) optional resources

	 mov	 bx,FLEXROMINTS_OFF ; Get pointer into resource table

FCN_FLEXROM_NEXT_RES:

; Get the Interrupt number to be relocated

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character in case not ','

	 cmp	 al,','         ; Izit present?
	 jne	 near ptr FCN_FLEXROM_XRES ; Jump if not, no more resources

	 inc	 si		; Skip over the separator
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,16		; Use base 16 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_FLEXROM_ERR ; Jump if too large

; Check to see if there is more resource space available in table

	 cmp	 [bx].FLEXROMINTS.FLEXROMINT_NUM,@FLEX_UNUSED ; Izit unused?
	 jne	 near ptr FCN_FLEXROM_RNG ; All slots already filled, error.

; Save resource number into table

	 mov	 [bx].FLEXROMINTS.FLEXROMINT_NUM,ax ; Save resource number

	 mov	 [bx].FLEXROMINTS.FLEXROMINT_SRC,dx ; Save source segment

; Get the Resource's flag

	 call	 XSKIP_WHITE	; Skip over more white space

; See if the we should use defaults for resource and action

	 cmp	 al,','         ; Izit a comma?
	 je	 short FCN_FLEXROM_DEFAULT ; Yes, so use defaults

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 short FCN_FLEXROM_DEFAULT ; Yes, so use defaults

	 cmp	 al,CR		; Izit a CR?
	 je	 short FCN_FLEXROM_DEFAULT ; Yes, so use defaults

	 xor	 ah,ah		; Convert byte to word
	 sub	 ax,@FIRST_FLEXRESOURCE ; Convert resource to 0 base

	 cmp	 ax,@FLEXRESOURCE_CNT ; Is index with range?
	 jae	 near ptr FCN_FLEXROM_RNG ; Jump if value out of range

	 mov	 di,ax		; Move to index register

	 movzx	 ax,[di].FLEXROM_RESOURCE ; Get resource from table

; Save resource information into table

	 mov	 [bx].FLEXROMINTS.FLEXROMINT_FLAG,ax ; Save resource flag

; Get the Resource's action

	 call	 XSKIP_WHITE	; Skip over more white space

	 xor	 ah,ah		; Convert byte to word
	 sub	 ax,@FIRST_FLEXACTION ; Convert action to 0 base

; Save resource information into table

	 rol	 eax,16 	; Move index to high word
	 mov	 ax,seg XGROUP	; Get segment of action items
	 rol	 eax,16 	; Move segment to high word

	 cmp	 ax,@FLEXACTION_CNT ; Is index with range?
	 jae	 near ptr FCN_FLEXROM_RNG ; Jump if value out of range

	 shl	 ax,1		; Convert bytes -> words
	 mov	 di,ax		; Move to index register

	 mov	 ax,[di].FLEXROM_ACTION ; Get action offset from table

	 mov	 [bx].FLEXROMINTS.FLEXROMINT_FIND,eax ; Save resource action

FCN_FLEXROM_NEXT_RESOURCE:

	 add	 bx,@FLEXROMINT_STRLEN ; Point to next entry
	 add	 FLEXROMINTS_OFF,@FLEXROMINT_STRLEN ; Point to next entry

	 jmp	 near ptr FCN_FLEXROM_NEXT_RES ; Get next resource

FCN_FLEXROM_XRES:

; Place marker in FLEXROMINTS table indicating entry done.

	 or	 FLEXROM_FLAG,@FR_ACTIVE ; Mark as FLEXROM being active

	 add	 FLEXROM_LEN,@FLEXROM_STRLEN ; Count in one more entry

	 clc			; Indicate all went well

	 jmp	 short FCN_FLEXROM_EXIT ; Joiin common exit code

; Process using default resource and action for specified resource

FCN_FLEXROM_DEFAULT:

	 mov	 ax,[bx].FLEXROMINTS.FLEXROMINT_NUM ; Get resource number

	 xor	 di,di		; Start at begining of defaults table
	 mov	 cx,NFLEX_DEFAULTS ; Number of defaults to look for

FCN_FLEXROM_DEFAULTS_NEXT:
	 cmp	 [di].FLEX_DEFAULTS.FLEXDEFAULT_NUM,ax ; Izit ours?
	 je	 short FCN_FLEXROM_DEFAULT_FOUND ; Yes

	 add	 di,size FLEXDEFAULT_STR ; Point to next entry
	 loop	 short FCN_FLEXROM_DEFAULTS_NEXT ; Try next entry

	 jmp	 short FCN_FLEXROM_ERR ; Error, can't find default

FCN_FLEXROM_DEFAULT_FOUND:

; Store default resource
	 mov	 ax,[di].FLEX_DEFAULTS.FLEXDEFAULT_RES ; Get default resource
	 mov	 [bx].FLEXROMINTS.FLEXROMINT_FLAG,ax ; Save resource flag

; Store default action
	 mov	 ax,seg XGROUP	; Get segment of action items
	 rol	 eax,16 	; Move to high word
	 mov	 ax,[di].FLEX_DEFAULTS.FLEXDEFAULT_ACT ; Get default action
	 mov	 [bx].FLEXROMINTS.FLEXROMINT_FIND,eax ; Save resource action

	 dec	 si		; Back up to read last character again

	 jmp	 short FCN_FLEXROM_NEXT_RESOURCE ; Look for more

FCN_FLEXROM_RNG:
	 push	 offset YGROUP:MSG_OVF ; Pass offset in YGROUP of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_FLEXROM_ERR:
	 stc			; Indicate something went wrong
FCN_FLEXROM_EXIT:
	 REGREST <di,dx,cx,bx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_FLEXROM endp		; End FCN_FLEXROM procedure
endif				; IF @OEM_FLEXROM
if @OEM_DEBUG or @OEM_SYS eq @OEMSYS_HPRS or @OEM_SYS eq @OEMSYS_ILIM
	 FPPROC  FCN_FORCEA20 -- FORCEA20 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM3_FLAG,@CM3_XA20 ; Mark as A20 forced (virtualize A20)
	 and	 CM2_FLAG,not @CM2_UNSH ; Remove UNSHIFT if present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_FORCEA20 endp		; End FCN_FORCEA20 procedure
endif				; IF @OEM_DEBUG or @OEM_SYS eq @OEMSYS_HPRS or @OEM_SYS eq @OEMSYS_ILIM
if @OEM_BCF
	 FPPROC  FCN_FORCEBCF -- FORCEBCF Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Ignore any error messages during BCF validation.

On entry:

DS:SI	 ==>	 next character in command line or profile

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise
DS:SI	 ==>	 next character in command line or profile (updated)

|

	 or	 CMD_FLAG,@CMD_FORCEBCF ; Mark as FORCEBCF

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_FORCEBCF endp		; End FCN_FORCEBCF procedure
endif				; IF @OEM_BCF
if @OEM_EMS
	 FPPROC  FCN_FRAME -- FRAME Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_FRAME_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,16		; Use base 16 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_FRAME_ERR ; Jump if too large

	 cmp	 ax,100h	; See if they're using a shorthand
	 jae	 short @F	; Not this time

	 xchg	 al,ah		; Swap high- and low-order bytes
@@:
	 test	 ax,(16*1024/16)-1 ; Ensure it's on a 16KB boundary
	 jz	 short @F	; It is

	 push	 offset YGROUP:MSG_CMDCHK_FRM1 ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 jmp	 short FCN_FRAME_ERR ; So that's an error

@@:
	 mov	 FRAME,ax	; Save for later use
	 or	 CMD_FLAG,@CMD_FRM ; Mark as present

	 clc			; Indicate all went well

	 jmp	 short FCN_FRAME_EXIT ; Join common exit code

FCN_FRAME_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_FRAME_ERR:
	 stc			; Indicate something went wrong
FCN_FRAME_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_FRAME endp			; End FCN_FRAME procedure
endif				; IF @OEM_EMS
if @OEM_HIFILL and @OEM_SYS eq @OEMSYS_ILIM
	 FPPROC  FCN_HIGHDOS -- HIGHDOS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 and	 CMD_FLAG,not @CMD_XHI ; Remove NOHIGH

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_HIGHDOS endp		; End FCN_HIGHDOS procedure
endif				; IF @OEM_HIFILL and @OEM_SYS eq @OEMSYS_ILIM
if @OEM_XMS
	 FPPROC  FCN_HMAMIN -- HMAMIN Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_HMAMIN_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_HMAMIN_ERR ; Jump if too large

	 cmp	 ax,63		; Check against upper limit
	 jbe	 short @F	; It's within range

	 mov	 ax,63		; Use maximum
@@:
	 mov	 HMAMIN,ax	; Save for later use

	 clc			; Indicate all went well

	 jmp	 short FCN_HMAMIN_EXIT ; Join common exit code

FCN_HMAMIN_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_HMAMIN_ERR:
	 stc			; Indicate something went wrong
FCN_HMAMIN_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_HMAMIN endp 		; End FCN_HMAMIN procedure
endif				; IF @OEM_XMS
if @OEM_FLEX
	 FPPROC  FCN_IGNOREFLEXFRAME -- IGNOREFLEXFRAME Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CMD_FLAG,@CMD_IGNFLEX ; Mark as present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_IGNOREFLEXFRAME endp	; End FCN_IGNOREFLEXFRAME procedure
endif				; IF @OEM_FLEX
if @OEM_HIFILL
	 NPPROC  GETREG_SUB -- Parse size and region values
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Parse size and region values for HPDAREG, STACKREG, and XBDAREG.

If only one value is specified (undocumented), it's the region.
Make sure it's in range (0-9).  If two are specified, the first
one is the long decimal size (0 to 1MB-1) and the second is the region.

On entry:

XGROUP:BX ==>	 REG_STR (see QMAX_NRD.INC)
DS:SI	  ==>	 character after keyword

On exit:

CF=0		 Values parsed OK
CF=1		 Error(s) occurred
DS:SI	  =	 (updated)

|

	 REGSAVE <eax,cx,dx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short GETREG_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIND	; Convert the number at DS:SI to binary in EAX
	 jc	 short GETREG_OVF ; Jump if too large

	 cmp	 eax,CON1MB	; Izit >= 1MB?
	 jnb	 short GETREG_OVF ; Jump if too large

	 mov	 dx,-1		; Assume no second parameter; default size

; Check for optional second parameter specifying region.  If first parameter
; only is specified, it indicates the region.  If both are present, the
; first is the size and the second is the region.

	 push	 ax		; Save low word of first parameter

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character in case not separator

	 cmp	 al,','         ; Izit separator for optional window segment?

	 pop	 ax		; Restore
	 jne	 short GETREG_DONE ; Jump if not

	 shr	 eax,4-0	; Convert bytes to paras (rounding down)
	 mov	 dx,ax		; Save first argument as size

	 inc	 si		; Skip over separator

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short GETREG_OVF ; Jump if too large

GETREG_DONE:
; AX = region number to check
; DX = size in paras
	 cmp	 ax,9		; Check against maximum
	 ja	 short GETREG_OVF ; Jump if too large

	 mov	 XGROUP:[bx].RREG,ax ; Save for later use
	 mov	 XGROUP:[bx].RSIZE,dx ; Save for later comparison
GETREG_CLC:
	 clc			; Indicate all went well

	 jmp	 short GETREG_EXIT ; Join common exit code

GETREG_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 jmp	 short GETREG_ERR ; Join common error code

GETREG_OVF:
	 push	 offset YGROUP:MSG_OVF ; Pass address of error message
GETREG_ERR:
	 call	 DISP_ERRLAST	; Display error message with last keyword
	 stc			; Indicate something went wrong
GETREG_EXIT:
	 REGREST <dx,cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GETREG_SUB endp 		; End GETREG_SUB procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 FPPROC  FCN_HPDAREG -- HPDAREG=size,reg Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <bx>		; Save

	 lea	 bx,XGROUP:HPDAR ; Address structure
	 call	 GETREG_SUB	; Return CF=0 if OK

	 REGREST <bx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_HPDAREG endp		; End FCN_HPDAREG procedure
endif				; IF @OEM_HIFILL
if @OEM_EMS and @OEM_SYS ne @OEMSYS_ILIM
	 FPPROC  FCN_INCLUDE -- INCLUDE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx,di,bp>	; Save registers
FCN_INCLUDE_AGAIN:
	 or	 NRD_FLAG,@NRD_INC ; Allow auto INCLUDE=

	 call	 GET_CMDARGS	; Parse command line for xxxx-yyyy
	 jc	 near ptr FCN_INCLUDE_ERR ; Jump if something went wrong
				; Return with BP = 1st arg, AX = length

	 test	 NRD_FLAG,@NRD_INC ; Did we find a match?
	 jnz	 short @F	; No, there's a length parameter

	 mov	 INCSIZE,bp	; Save for later use

	 jmp	 short FCN_INCLUDE_SEP ; Join common code

@@:
	 and	 NRD_FLAG,not @NRD_INC ; Clear for next time

; Ensure that the starting and length values are a multiple of 16KB

	 test	 ax,(16*1024/16)-1 ; Ensure it's on a 16KB boundary
	 jnz	 short FCN_INCLUDE_ERR1 ; It isn't

	 test	 bp,(16*1024/16)-1 ; Ensure it's on a 16KB boundary
	 jnz	 short FCN_INCLUDE_ERR1 ; It isn't

; Mark the entries in PPMTAB as @PPM_INC

	 mov	 cx,ax		; Copy to count register
	 shr	 cx,14-4	; Convert from paras to 16KB

	 mov	 di,bp		; Copy to index register
	 shr	 di,14-4	; Convert from paras to 16KB
	 lea	 di,PPMTAB[di]	; Point to spot within PPMTAB

	 push	 ax		; Save for a moment
	 mov	 al,@PPM_INC	; INC index
     rep stos	 PGROUP:[di].LO ; Save in memory map
	 pop	 ax		; Restore

; Mark the entries in MEM_MAP above LOWOFF as @XLAT_INC

	 mov	 bx,LOWOFF.ELO	; Get top of original DOS memory
	 shl	 bx,10-9	; Convert from 1KB to 512-byte
	 lea	 bx,MEM_MAP[bx] ; Point to place within MEM_MAP

	 mov	 cx,ax		; Copy to count register
	 shr	 cx,9-4 	; Convert from paras to 512-byte

	 mov	 di,bp		; Copy to index register
	 shr	 di,9-4 	; Convert from paras to 512-byte
	 lea	 di,MEM_MAP[di] ; Point to spot within MEM_MAP

	 sub	 bx,di		; Izit below top of DOS?
	 jbe	 short @F	; No

	 add	 di,bx		; Mark new start as above top of DOS
	 sub	 cx,bx		; Account for in length
	 jbe	 short FCN_INCLUDE_SEP ; Nothing left
@@:
	 push	 ax		; Save for a moment
	 mov	 al,@XLAT_INC	; INC index
	 call	 MARKENTRY	; Mark the entries avoiding ROM overwrite
	 pop	 ax		; Restore
FCN_INCLUDE_SEP:
	 mov	 SEPARATOR,','  ; Mark as new separator

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Check for more arguments
	 je	 near ptr FCN_INCLUDE_AGAIN ; Yes, go around again

	 or	 CM2_FLAG,@CM2_INC ; Mark as present

	 clc			; Indicate all went well

	 jmp	 short FCN_INCLUDE_EXIT ; Join common exit code

FCN_INCLUDE_ERR1:
	 push	 offset YGROUP:MSG_CMDCHK_INC1 ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message
FCN_INCLUDE_ERR:
	 stc			; Indicate something went wrong
FCN_INCLUDE_EXIT:
	 mov	 SEPARATOR,'='  ; Mark as old separator

	 REGREST <bp,di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_INCLUDE endp		; End FCN_INCLUDE procedure
endif				; IF @OEM_EMS and @OEM_SYS ne @OEMSYS_ILIM
if @OEM_MISC
	 FPPROC  FCN_IOP -- IOP Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_IOP_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,16		; Use base 16 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_IOP_ERR ; Jump if too large

	 cmp	 ax,0F000h	; Check against minimum
	 jb	 short FCN_IOP_CLC ; Jump and ignore if too small

	 cmp	 al,00h 	; Ensure it's on a appropriate boundary
	 jne	 short FCN_IOP_CLC ; Jump and ignore if not multiple of 100h

	 mov	 PORTPMR,ax	; Save as port for PMR mapping
	 add	 ax,80h 	; Skip to PORT15 location
	 mov	 PORT15,ax	; Save for later use
	 add	 ax,4		; Skip to next set of four I/O addresses
	 mov	 PORT67,ax	; Save for later use

;;;;;;;; or	 CMD_FLAG,@CMD_IOP ; Mark as present
FCN_IOP_CLC:
	 clc			; Indicate all went well

	 jmp	 short FCN_IOP_EXIT ; Join common exit code

FCN_IOP_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_IOP_ERR:
	 stc			; Indicate something went wrong
FCN_IOP_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_IOP  endp			; End FCN_IOP procedure
endif				; IF @OEM_MISC
if @OEM_SOFT
	 FPPROC  FCN_IOWRAP -- IOWRAP Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT |

IOWRAP - Sets the I/O Repeat Factor to 40h

This option is used if 1) the machine has only 10 bits of I/O addressing
(i.e. an ISA system) and 2) software relies on this.  In other words,
some unknown situation may occur where a program does an OUT DX,AL
with DX=C81 and expects that it's writing to port 81h.

Our default behavior is now the same as that previously enabled by
the now-defunct NOIOWRAP option; IOWRAP forces our previous behavior.

|

	 mov	 REP_FAC,40h	; Use repeat factor of 40 for I/O ports

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_IOWRAP endp 		; End FCN_IOWRAP procedure
endif				; IF @OEM_SOFT
	 FPPROC  FCN_ISTACKS -- ISTACKS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_ISTACKS_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_ISTACKS_ERR ; Jump if too large

	 mov	 NSTACKS,ax	; Save for later use
;;;;;;;; or	 CMD_FLAG,@CMD_STK ; Mark as present

	 clc			; Indicate all went well

	 jmp	 short FCN_ISTACKS_EXIT ; Join common exit code

FCN_ISTACKS_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_ISTACKS_ERR:
	 stc			; Indicate something went wrong
FCN_ISTACKS_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_ISTACKS endp		; End FCN_ISTACKS procedure
if @OEM_DEBUG
	 FPPROC  FCN_LMLTOP -- LMLTOP Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <eax,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_LMLTOP_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,16		; Use base 16 to convert
	 call	 BASE2BIND	; Convert the number at DS:SI to binary in EAX
	 jc	 short FCN_LMLTOP_ERR ; Jump if too large

	 shr	 eax,10-0	; Convert from bytes to 1KB
	 mov	 LMLTOP,eax	; Save for later use

	 or	 LCL_FLAG,@LCL_LML ; Mark as low memory load

	 clc			; Indicate all went well

	 jmp	 short FCN_LMLTOP_EXIT ; Join common exit code

FCN_LMLTOP_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_LMLTOP_ERR:
	 stc			; Indicate something went wrong
FCN_LMLTOP_EXIT:
	 REGREST <cx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LMLTOP endp 		; End FCN_LMLTOP procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_LOAD -- LOAD=d:\path\filename.ext Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <eax,bx,cx,dx,di,gs> ; Save registers

	 push	 OLDINT24_VEC	; Save old INT 24h handler's address
	 call	 INST24 	; Install local INT 24h handler

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 near ptr FCN_LOAD_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 dx,si		; Save as start of profile fid

; Search for end of filename

FCN_LOAD1:
	 lodsb			; Get next character

	 cmp	 al,' '         ; Too small for filename?
	 ja	 short FCN_LOAD1 ; No, go around again

	 dec	 si		; Back off to terminator

; Search for end of arguments

	 call	 ARGEND 	; Return with DS:DI ==> end of argument list

; Load the file into memory

	 mov	 ax,MAPSEG_NXT	; Get next available segment
	 mov	 EXEC_BLK.ELO,ax ; Save as segment address for load
	 mov	 EXEC_BLK.EHI,ax ; Save as relocation factor

	 lea	 bx,EXEC_BLK	; ES:BX ==> EXEC block
	 mov	 cl,0		; String terminator
	 xchg	 cl,[si]	; Terminate filename.ext
	 mov	 al,03h 	; Access code for load overlay

	 REGSAVE <cx,dx,si>	; Save over EXEC
	 DOSCALL @EXEC		; Load the overlay
	 REGREST <si,dx,cx>	; Restore

	 xchg	 cl,[si]	; Restore filename.ext
	 jc	 near ptr FCN_LOAD_EXEC ; Something went wrong

COMMENT|

Call the real mode initialization code

On entry:

DS:DX	 ==>	 "d:\path\filename.ext [arguments]",0
DS:SI	 ==>	 "[arguments]",0

|

; Relocate code if necessary

	 mov	 ax,MAPSEG_NXT	; Get next available segment
	 mov	 gs,ax		; Setup GS for real mode initialization
	 assume  gs:nothing	; Tell the assembler about it

	 test	 gs:[0].MD_ATTR,@MD_EXE ; Izit an .EXE file?
	 jnz	 short @F	; Yes, skip relocation

	 add	 gs:[0].MD_IREAL.VSEG,ax ; Relocate it
@@:

; Set flags for XT or MCA if necessary

	 test	 LCL_FLAG,@LCL_XT ; Izit an XT?
	 jz	 short @F	; Not this time

	 or	 gs:[0].MD_ATTR,@MD_XT ; Mark as an XT
@@:
	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jz	 short @F	; Not this time

	 or	 gs:[0].MD_ATTR,@MD_MCA ; Mark as an MCA-compatible
@@:

; Tell the load module that we support APIVER features if it does

	 test	 gs:[0].MD_ATTR,@MD_VER ; Duzit?
	 jz	 short @F	; Jump if not

	 mov	 gs:[0].MD_MAXVER,01h ; Tell 'em
@@:

; Tell the load module we support MD_VSIZE if it does

	 or	 gs:[0].MD_ATTR,@MD_VSIZE ; Tell 'em

; Terminate filename and argument list

	 mov	 bx,si		; Copy offset of filename terminator

	 cmp	 ds:[si].LO,TAB ; Any arguments?
	 je	 short FCN_LOAD5 ; Jump if so

	 cmp	 ds:[si].LO,' ' ; Any arguments?
	 jb	 short FCN_LOAD6 ; Jump if not
FCN_LOAD5:
	 inc	 si		; Skip over filename terminator
FCN_LOAD6:
	 mov	 cx,0		; Terminators
	 xchg	 cl,ds:[bx]	; Swap 'em
	 xchg	 ch,ds:[di]	; Swap 'em
	 call	 gs:[0].MD_IREAL ; Call it to initialize
	 xchg	 ch,ds:[di]	; Restore
	 xchg	 cl,ds:[bx]	; Restore

	 mov	 si,di		; DS:SI ==> end of argument list

	 test	 gs:[0].MD_ATTR,@MD_RMIE ; Test for real mode initialization error
	 jnz	 near ptr FCN_LOAD_ERR ; Jump if something went wrong

if @OEM_DPMI

; See if the load module requested DPMI services

	 test	 gs:[0].MD_ATTR,@MD_DPMI ; Izit requested?
	 jz	 short @F	; Jump if not

	 or	 LCL_FLAG,@LCL_DPMI ; Note as such
@@:
endif				; IF @OEM_DPMI

; Check for any additional fields in the header

	 test	 gs:[0].MD_ATTR,@MD_VER ; Izit present?
	 jz	 short FCN_LOAD_NOFLDS ; Jump if not

; Check to see if module wishes to recover any High DOS

	 mov	 cx,gs:[0].MD_OVR_LEN ; Get length of High DOS in paras (/4KB)
	 jcxz	 FCN_LOAD_XOVR	; Jump if none to recover

; Mark as OVR in MEM_MAP (Create High DOS)

	 shr	 cx,9-4 	; Convert from paras to 512 bytes
	 mov	 di,gs:[0].MD_OVR ; Get segment of old ROM (/4KB)
	 shr	 di,9-4 	; Convert from paras to 512 bytes
	 lea	 di,MEM_MAP[di] ; Point into MEM_MAP
	 mov	 al,@XLAT_OVR	; OVR index
	 call	 MARKENTRY	; Mark the entries avoiding ROM overwrite
FCN_LOAD_XOVR:
FCN_LOAD_NOFLDS:

; Save load table information backwards as that's the way the
; extended memory is reserved.

	 mov	 di,LOADTABIND	; Get index to next load table entry
	 sub	 di,size LOAD_STR ; Skip to next entry backwards

	 mov	 ax,MAPSEG_NXT	; Get next available segment
	 mov	 LOADTAB.LOAD_SEG[di],ax ; Save in LOAD structure

	 mov	 eax,gs:[0].MD_SIZE ; Get the initialization size in bytes

	 and	 eax,eax	; Anything to save?
	 jz	 near ptr FCN_LOAD_CLC ; Jump if not

	 add	 eax,16-1	; Round up to para boundary
	 and	 ax,not (16-1)	; and down again
	 add	 LOADBYTE,eax	; Add into accumulated load count
	 mov	 LOADTAB.LOAD_SIZ[di],eax ; Save load size

	 shr	 eax,4-0	; Convert from bytes to paras

	 test	 gs:[0].MD_ATTR,@MD_VER ; Does this one have INIT_VIRT?
	 jz	 short FCN_LOAD_VSIZE ; Nope, so it automatically supports MD_VSIZE

	 cmp	 gs:[0].MD_VSIZE,0 ; Duzit support MD_VSIZE?
	 je	 short @F	; Jump if not
FCN_LOAD_VSIZE:
	 or	 LOADTAB.LOAD_FLG[di],@LOAD_VSIZE ; Mark as supporting VSIZE
	 mov	 ax,((size MD_STR)+16-1)/16 ; Leave just the header
@@:
	 add	 MAPSEG_NXT,ax	; Skip over the low DOS memory portion

; See if there's any uninitialized data

	 test	 gs:[0].MD_ATTR,@MD_VER ; Izit present?
	 jz	 short @F	; Jump if not

	 cmp	 gs:[0].MD_APIVER,0001h ; Izit present?
	 jb	 short @F	; Jump if not

	 mov	 eax,gs:[0].MD_USIZE ; Get byte size of uninitialized data
	 add	 eax,16-1	; Round up to para boundary
	 and	 ax,not (16-1)	; and down again
	 add	 LOADBYTE,eax	; Add into accumulated load count
	 mov	 LOADTAB.LOAD_USIZ[di],eax ; Save as uninitialized data size
@@:
	 mov	 eax,gs:[0].MD_DATA ; Read in the data segment offset
	 mov	 LOADTAB.LOAD_DAT[di],eax ; Save load size

; Copy the resident portion to extended memory

	 call	 LOADUP 	; Copy it upstairs
	 jc	 short FCN_LOAD_ERRUP ; Jump if something went wrong

	 mov	 LOADTABIND,di	; Save current index
	 inc	 LOADCOUNT	; Count in another table entry
FCN_LOAD_CLC:
	 clc			; Indicate all went well

	 jmp	 short FCN_LOAD_EXIT ; Join common tail code

FCN_LOAD_EXEC:
	 push	 offset YGROUP:MSG_LEXEC ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 call	 XSKIP_EOL	; Skip over rest of line
	 call	 ABORT_IGNORE	; Ask user if they want to abort
				; CF=1 if user wishes to ABORT

	 jmp	 short FCN_LOAD_EXIT ; Join common tail code (CF set)

FCN_LOAD_ERRUP:
	 push	 offset YGROUP:MSG_EXECUP ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 jmp	 short FCN_LOAD_ERR ; Join common tail code

FCN_LOAD_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_LOAD_ERR:
	 stc			; Indicate there was a problem
FCN_LOAD_EXIT:
	 call	 REST24 	; Restore INT 24h handler
	 pop	 OLDINT24_VEC	; Restore old INT 24h handler's address

	 REGREST <gs,di,dx,cx,bx,eax> ; Restore
	 assume  gs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LOAD endp			; End FCN_LOAD procedure
endif				; @OEM_DEBUG
if @OEM_EMS and @OEM_SYS eq @OEMSYS_HPRS
	 FPPROC  FCN_LOWFRAME -- LOWFRAME Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM3_FLAG,@CM3_LOWFR ; Mark as low memory EMS page frame allowed

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_LOWFRAME endp		; End FCN_LOWFRAME procedure
endif				; IF @OEM_EMS and @OEM_SYS eq @OEMSYS_HPRS
	 FPPROC  FCN_MCE -- MCE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM4_FLAG,@CM4_MCE ; Mark as enabled if present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_MCE  endp			; End FCN_MCE procedure
if @OEM_LOFILL
	 FPPROC  FCN_MONO -- MONO Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,bp>	; Save registers

	 mov	 bp,0B000h	; Get starting offset in paras
	 mov	 ax,01000h	; Get length in paras

	 call	 VIDCOM 	; Set video range to BP (low), AX (length)

	 clc			; Indicate all went well

	 REGREST <bp,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_MONO endp			; End FCN_MONO procedure
endif				; IF @OEM_LOFILL
if @OEM_HIFILL
	 FPPROC  FCN_NO4B -- NO4B Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 I15_FLAG,@I15_X4B ; Mark as not allowing 4B00 into high DOS

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NO4B endp			; End FCN_NO4B procedure
endif				; IF @OEM_HIFILL
if @OEM_HIFILL
	 FPPROC  FCN_NO58 -- NO58 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 I15_FLAG,@I15_X58 ; Mark as not emulating 5800 support

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NO58 endp			; End FCN_NO58 procedure
endif				; IF @OEM_HIFILL
	 FPPROC  FCN_NOABIOS -- NOABIOS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 and	 NRD_FLAG,not @NRD_ABIOSERR ; Ignore ABIOS initialization errors

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOABIOS endp		; End FCN_NOABIOS procedure
	 FPPROC  FCN_NOCACHE -- NOCACHE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 and	 CACHEMASK,not ((mask $CD) or (mask $NW)) ; Don't disable cache
				; and write-through in EPM code

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOCACHE endp		; End FCN_NOCACHE procedure
if @OEM_HIFILL
	 FPPROC  FCN_NOCOMPROM -- NOCOMPROM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM3_FLAG,@CM3_XCROM ; Mark as not compressing system ROMs

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOCOMPROM endp		; End FCN_NOCOMPROM procedure
endif				; IF @OEM_HIFILL
if @OEM_DMA
	 FPPROC  FCN_NOEISADMA -- NOEISADMA Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 and	 CM2_FLAG,not (@CM2_EISA_DMA) ; Mark as not using
				; ... EISA style DMA
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOEISADMA endp		; End FCN_NOEISADMA procedure
endif				; If @OEM_DMA
if @OEM_EMS and @OEM_SYS ne @OEMSYS_ILIM
	 FPPROC  FCN_NOFRAME -- NOFRAME Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM3_FLAG,@CM3_NOFR ; Mark as NOFRAME

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOFRAME endp		; End FCN_NOFRAME procedure
endif				; IF @OEM_EMS and @OEM_SYS ne @OEMSYS_ILIM
	 FPPROC  FCN_NOVME -- NOVME Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 and	 CPUFET_FLAG,not @CPUFET_VME ; Mark as NOT supporting VME

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOVME endp			; End FCN_NOVME procedure
if @OEM_XMS and @OEM_SYS eq @OEMSYS_HPRS
	 FPPROC  FCN_NOHMA -- NOHMA Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 XMS_FLAG,mask $XMS_XHMA ; Mark as HMA permanently unavailable
	 and	 GLB_FLAG,not @GLB_HMA ; Clear this one, too

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOHMA endp			; End FCN_NOHMA procedure
endif				; IF @OEM_XMS and @OEM_SYS eq @OEMSYS_HPRS
if @OEM_SOFT
	 FPPROC  FCN_NOIOWRAP -- NOIOWRAP Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT |

NOIOWRAP - Sets the I/O Repeat Factor to 1

This option is defunct, as this is now the default behavior.

|

	 push	 offset YGROUP:MSG_NOIOWRAP ; "NOIOWRAP keyword is obsolete..."
	 call	 YMSGOUT2	; Display YGROUP message

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOIOWRAP endp		; End FCN_NOIOWRAP procedure
endif				; IF @OEM_SOFT
if @OEM_HIFILL
	 FPPROC  FCN_NOLOADHI -- NOLOADHI Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 test	 CM3_FLAG,@CM3_PREG0 ; Izit PRGREG=0 present?
	 jnz	 short @F	; Jump if so, as PRGREG=0 supplants NOLOADHI

	 or	 CM3_FLAG,@CM3_XLHI ; Mark as no load into high DOS memory
if @OEM_HIFILL
	 or	 LSEG.LSEG_FLAG,@LSEG_XLHI ; Mark as such in LSEG
endif				; IF @OEM_HIFILL

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOLOADHI endp		; End FCN_NOLOADHI procedure
endif				; IF @OEM_HIFILL
if @OEM_DMA and @OEM_DEBUG
	 FPPROC  FCN_NODMA -- NODMA Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CMD_FLAG,@CMD_XDM ; Mark as not trapping DMA

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NODMA endp			; End FCN_NODMA procedure
endif				; IF @OEM_DMA and @OEM_DEBUG
if @OEM_DPMI
	 FPPROC  FCN_NODPMI -- NODPMI Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CMD_FLAG,@CMD_XDPMI ; Disable DPMI features

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NODPMI endp 		; End FCN_NODPMI procedure
endif				; IF @OEM_DPMI
if @OEM_HIFILL
	 FPPROC  FCN_NOHIGH -- NOHIGH Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CMD_FLAG,@CMD_XHI ; Mark as not filling high memory

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOHIGH endp 		; End FCN_NOHIGH procedure
endif				; IF @OEM_HIFILL
if @OEM_SYS ne @OEMSYS_HPRS
if @OEM_SYS ne @OEMSYS_AST386
if @OEM_SYS ne @OEMSYS_OLI
if @OEM_SYS ne @OEMSYS_OL2
	 FPPROC  FCN_NOLOW -- NOLOW Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CMD_FLAG,@CMD_XLO ; Mark as not filling low memory

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOLOW endp			; End FCN_NOLOW procedure
endif				; IF @OEM_SYS ne @OEMSYS_OL2
endif				; IF @OEM_SYS ne @OEMSYS_OLI
endif				; IF @OEM_SYS eq @OEMSYS_AST386
endif				; IF @OEM_SYS ne @OEMSYS_HPRS
	FPPROC	FCN_NOPNP -- NOPNP Function
	assume	ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	or	CM2_FLAG,@CM2_NOPnP ; Mark as NOT supporting PnP

	clc			; Indicate all went well

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOPNP endp			; End FCN_NOPNP procedure
if @OEM_SYS ne @OEMSYS_ILIM
if @OEM_SYS ne @OEMSYS_HPRS
if @OEM_SYS ne @OEMSYS_AST386
if @OEM_SYS ne @OEMSYS_OLI
if @OEM_SYS ne @OEMSYS_OL2
	 FPPROC  FCN_NOROM -- NOROM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 test	 LCL_FLAG,@LCL_BCF ; Is AUTOBCF/BCF in effect?
	 jnz	 short @F	; Jump if so (ignore NOROM)

	 or	 CMD_FLAG,@CMD_XRM ; Mark as NOROM specified
@@:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOROM endp			; End FCN_NOROM procedure
endif				; IF @OEM_SYS ne @OEMSYS_OL2
endif				; IF @OEM_SYS ne @OEMSYS_OLI
endif				; IF @OEM_SYS ne @OEMSYS_AST386
endif				; IF @OEM_SYS ne @OEMSYS_HPRS
endif				; IF @OEM_SYS ne @OEMSYS_ILIM
if @OEM_SYS eq @OEMSYS_RET
	 FPPROC  FCN_NOSCAN -- NOSCAN Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <eax,cx,ebp,gs> ; Save registers

	 mov	 ax,seg JGROUP	; Get segment of NOSCAN_MAP
	 mov	 gs,ax		; Address it
	 assume  gs:JGROUP	; Tell the assembler about it
FCN_NOSCAN_AGAIN:
	 call	 GET_CMDARGS	; Parse command line for xxxx-yyyy
	 jc	 short FCN_NOSCAN_ERR ; Jump if something went wrong
				; Return with BP = 1st arg, AX = length

; Round starting address down to 4KB boundary

	 movzx	 eax,ax 	; Zero to use as dword in case end is 10000
	 movzx	 ebp,bp 	; ...
	 add	 eax,ebp	; Add to get ending address
	 shr	 ebp,12-4	; Convert from paras to 4KB, rounding down
	 shr	 eax,12-4	; ...

; Ensure it's within the proper range

	 cmp	 ax,1024/4	; Izit too large (above or equal to 1MB)?
	 jb	 short @F	; Jump if not

	 mov	 ax,1024/4	; Use maximum
@@:
	 sub	 ax,bp		; Subtract to get actual count
	 jbe	 short FCN_NOSCAN_NEXT ; Jump if it's invalid

	 mov	 cx,ax		; Copy to count register

	 cmp	 bp,1024/4	; Izit too large (above or equal to 1MB)?
	 jae	 short FCN_NOSCAN_NEXT ; Jump if so

	 sub	 bp,640/4	; Izit too small (below 640KB)?
	 jb	 short FCN_NOSCAN_NEXT ; Jump if so

; Mark in NOSCAN_MAP

@@:
	 bts	 NOSCAN_MAP.ELO,bp ; Set the bit

	 inc	 bp		; Skip to next entry

	 loop	 @B		; Jump if more entries to mark
FCN_NOSCAN_NEXT:
	 mov	 SEPARATOR,','  ; Mark as new separator

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Check for more arguments
	 je	 short FCN_NOSCAN_AGAIN ; Yes, go around again

	 clc			; Indicate all went well

	 jmp	 short FCN_NOSCAN_EXIT ; Join common exit code

FCN_NOSCAN_ERR:
	 stc			; Indicate something went wrong
FCN_NOSCAN_EXIT:
	 mov	 SEPARATOR,'='  ; Mark as old separator

	 REGREST <gs,ebp,cx,eax> ; Restore
	 assume  gs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOSCAN endp 		; End FCN_NOSCAN procedure
endif				; IF @OEM_SYS eq @OEMSYS_RET
	 FPPROC  FCN_NOSCSI -- NOSCSI Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM2_FLAG,@CM2_XSCSI ; Mark as not checking for SCSI bus masters

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOSCSI endp 		; End FCN_NOSCSI procedure
if @OEM_SOFT
	 FPPROC  FCN_NOPARITY -- NOPARITY Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CMD_FLAG,@CMD_XPARITY ; Mark as not enabling parity check

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOPARITY endp		; End FCN_NOPARITY procedure
endif				; IF @OEM_SOFT
if @OEM_DEBUG and 0
	 FPPROC  FCN_NOSPEC -- NOSPEC Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 call	 far ptr FCN_NOXRAM ; No extra RAM recovery
if @OEM_DEBUG
	 call	 far ptr FCN_NOPULSE ; No pulsing the 8042
	 call	 far ptr FCN_NOSCRUB ; No scrubbing recovered RAM
endif				; IF @OEM_DEBUG
	 call	 far ptr FCN_NOWARMBOOT ; No caching of FF00-10000
	 call	 far ptr FCN_NOLOW ; No low filling
if @OEM_HIFILL
	 call	 FCN_NOCOMPROM	; No ROM compression
	 call	 FCN_NOHIGH	; No high filling
	 call	 FCN_NOLOADHI	; No LOADHI
endif				; IF @OEM_HIFILL
	 call	 far ptr FCN_SHADOWROM ; Don't UNSHADOWROM
	 call	 FCN_NOROM	; No ROM caching
	 call	 far ptr FCN_NOXBIOS ; No XBIOS relocation
	 call	 FCN_NOSCSI	; No SCSI bus master checking
if @OEM_LOFILL
	 call	 far ptr FCN_VEGA ; VIDMEM=A000-C000
endif				; IF @OEM_LOFILL

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOSPEC endp 		; End FCN_NOSPEC procedure
endif				; IF @OEM_DEBUG and 0
	 FPPROC  FCN_NOTIME -- NOTIME Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM2_FLAG,@CM2_NOTIME ; Skip TIME_ALLMEM - use highest memory

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOTIME endp 		; End FCN_NOTIME procedure
if @OEM_FLEXROM
	 FPPROC  FCN_NOVGASIG -- FCN_NOVGASIG procedure
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT |

Syntax:

NOVGASIG

NOVGASIG is short for "NO VGA SIGNATURE"
It is used when the user is enabling VGASWAP, but does not want
the 512 byte GORE area to be created.

|

	 or	 FLEXROM_FLAG,@FR_NOGORE ; Mark as no GORE requested

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
FCN_NOVGASIG	 endp			; End FCN_NOVGASIG procedure
endif				; IF @OEM_FLEXROM
if @OEM_WIN3
	 FPPROC  FCN_NOWIN3 -- NOWIN3 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM3_FLAG,@CM3_NOWIN3 ; Mark as no support for WIN3

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOWIN3 endp 		; End FCN_NOWIN3 procedure
endif				; IF @OEM_WIN3
if @OEM_WIN3
	 FPPROC  FCN_NOWIN30 -- NOWIN30 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT |

Indicate that we are supporting Windows 3.1 and above

|

	 mov	 XMSBND_BRKPNT,-1 ; Remove artificial XMS breakpoint

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOWIN30 endp		; End FCN_NOWIN30 procedure
endif				; IF @OEM_WIN3
if @OEM_FLEXROM
	 FPPROC  FCN_VGASWAP -- VGA SWAP Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Syntax:

VGASWAP[=[src][,[dest][,len]]]

Moves the EGA or VGA ROM from C000 to B000 for a length of 32KB
This is just a simple form of the FLEXROM option.

Note: The 3 arguments (source, destination, & length) are optional
      and default to C000, B000, & 8000 respectively.  Any of the
      three may be specified and used instead of the default.  If
      any of the parameters are not specified, the FLEXFILE will
      have the opportunity to change a value.  The most common example
      will be the FLEXFILE finding the BIOS at E000 instead of C000.

|

	 REGSAVE <eax,bx,ds>	; Save registers

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jnz	 near ptr FCN_VGASWAP_EXIT ; Jump if so

	 test	 FLEXROM_FLAG,@FR_VGA ; Is VGASWAP already active?
	 jnz	 near ptr FCN_VGASWAP_TWICE ; Jump if so

	 mov	 bx,FLEXROM_LEN ; Get index into FlexROM table
	 or	 FLEXROM_TBL[bx].FLEX_FLAG,@FLEXFLAG_VGA ; Mark entry as video
	 or	 FLEXROM_FLAG,@FR_VGA ; Mark as Video ROM being FLEXed

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character in case not '='

	 cmp	 al,'='         ; Izit present?
	 jne	 near ptr FCN_VGASWAP_FLEX ; Assume defaults if not

	 inc	 si		; Skip over the '=' separator
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,CR		; Izit end of line?
	 je	 short FCN_VGASWAP_FLEX ; Continue on

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 short FCN_VGASWAP_FLEX ; Continue on

	 cmp	 al,EOF 	; Izit end of file?
	 je	 short FCN_VGASWAP_FLEX ; Continue on

	 cmp	 al,','         ; Izit a comma?
	 je	 short @F	; Jump if so (next field)

	 lodsd			; Get source text from profile
	 mov	 VGASWAP_TXTSRC.EDD,eax ; And place in our text string
	 or	 FLEXROM_FLAG,@FR_VSRC ; Mark as source explicitly stated
@@:

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit a comma?
	 jne	 short @F	; Jump if not

	 inc	 si		; Skip comma
@@:

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,CR		; Izit end of line?
	 je	 short FCN_VGASWAP_FLEX ; Continue on

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 short FCN_VGASWAP_FLEX ; Continue on

	 cmp	 al,EOF 	; Izit end of file?
	 je	 short FCN_VGASWAP_FLEX ; Continue on

	 cmp	 al,','         ; Izit a comma?
	 je	 short @F	; Jump if so (next field)

	 lodsd			; Get source text from profile
	 mov	 VGASWAP_TXTDST.EDD,eax ; And place in our text string
	 or	 FLEXROM_FLAG,@FR_VDST ; Mark as destin explicitly stated
@@:
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit a comma?
	 jne	 short @F	; Jump if not

	 inc	 si		; Skip comma
@@:

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,CR		; Izit end of line?
	 je	 short FCN_VGASWAP_FLEX ; Continue on

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 short FCN_VGASWAP_FLEX ; Continue on

	 cmp	 al,EOF 	; Izit end of file?
	 je	 short FCN_VGASWAP_FLEX ; Continue on

	 inc	 si		; Skip in case it's a comma

	 cmp	 al,','         ; Izit a comma?
	 je	 short @F	; Jump if so (next field)

	 dec	 si		; Back up (it wasn't a comma)

	 lodsd			; Get source text from profile
	 mov	 VGASWAP_TXTLEN.EDD,eax ; And place in our text string
	 or	 FLEXROM_FLAG,@FR_VLEN ; Mark as length explicitly stated

@@:
FCN_VGASWAP_FLEX:
	 REGSAVE <si>		; Save pointer into profile

	 lea	 si,VGASWAP_TEXT ; Offset of FlexROM arguments

	 push	 seg XGROUP	; Get the segment of the FlexROM arguments
	 pop	 ds		;
	 assume  ds:nothing	; Tell the assembler about it

	 call	 FCN_FLEXROM	; Call it (Return with CF significant)

	 REGREST <si>		; Restore profile pointer

	 jmp	 short FCN_VGASWAP_EXIT ; Join common success code

FCN_VGASWAP_TWICE:
	 push	 offset YGROUP:MSG_VGASWAP_TWICE ; Pass address of warning
	 call	 YMSGOUT2	; Display YGROUP message

	 push	 offset YGROUP:MSG_PRESS ; Address of 'Press any key'
	 call	 YMSGOUT2	; Display YGROUP message

	 call	 FKEYWAIT	; Give 'em a chance to read message
				; Return with key in AX

	 clc			; Ensure profile processing continues
FCN_VGASWAP_EXIT:
	 REGREST <ds,bx,eax>	; Restore
	 assume ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_VGASWAP endp		; End FCN_VGASWAP procedure
endif				; IF @OEM_FLEXROM
if @OEM_WIN3
	 FPPROC  FCN_VXD -- VXD=d:\path\filename.ext Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <eax,bx,cx,dx,di,gs> ; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 near ptr FCN_VXD_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 dx,si		; Save as start of profile fid

; Search for end of filename

FCN_VXD1:
	 lodsb			; Get next character

	 cmp	 al,' '         ; Too small for filename?
	 ja	 short FCN_VXD1 ; No, go around again

	 dec	 si		; Back off to terminator

; Search for end of arguments

	 call	 ARGEND 	; Return with DS:DI ==> end of argument list

	 mov	 cx,si		; Address of terminator
	 sub	 cx,dx		; Less start address is length - 1
				; ... not including the trailing NUL

	 mov	 ALT_VIRT_DEV_NAME_LEN,cx ; Save length for CHECK_ARGS
	 mov	 ALT_VIRT_DEV_NAME,dx ; ... and the starting address

	 clc			; Normal return indicator

	 jmp	 short FCN_VXD_EXIT ; Join common exit code

FCN_VXD_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_VXD_ERR:
	 stc			; Indicate there was a problem
FCN_VXD_EXIT:
	 REGREST <gs,di,dx,cx,bx,eax> ; Restore
	 assume  gs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_VXD  endp			; End FCN_NOWIN3 procedure
endif				; IF @OEM_WIN3
if @OEM_SYS ne @OEMSYS_AST386
if @OEM_SYS ne @OEMSYS_OLI
if @OEM_SYS ne @OEMSYS_OL2
	 FPPROC  FCN_NOWARMBOOT -- NOWARMBOOT Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM2_FLAG,@CM2_NWB ; Mark as no warm boot protection desired

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOWARMBOOT endp		; End FCN_NOWARMBOOT procedure
endif				; IF @OEM_SYS ne @OEMSYS_OL2
endif				; IF @OEM_SYS ne @OEMSYS_OLI
endif				; IF @OEM_SYS eq @OEMSYS_AST386
if @OEM_DEBUG
	 FPPROC  FCN_NOSCRUB -- NOSCRUB Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM3_FLAG,@CM3_XSCRB ; Mark as not scrubbing extra RAM

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOSCRUB endp		; End FCN_NOSCRUB procedure
endif				; IF @OEM_DEBUG
if @OEM_DEBUG
	 FPPROC  FCN_NOPULSE -- NOPULSE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM3_FLAG,@CM3_XPULS ; Mark as not pulsing 8042

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOPULSE endp		; End FCN_NOPULSE procedure
endif				; IF @OEM_DEBUG
	 FPPROC  FCN_NOXBIOS -- NOXBIOS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 push	 ds		; Save for a moment

	 push	 seg PGROUP	; Get our data segment
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 test	 I15_FLAG,@I15_XBREL ; Izit in use?
	 jz	 short @F	; Jump if not

	 and	 I15_FLAG,not @I15_XBREL ; Clear the bits

	 call	 CHECK_CNV	; Check on conventional memory
@@:
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOXBIOS endp		; End FCN_NOXBIOS procedure
	 FPPROC  FCN_NOXRAM -- NOXRAM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM2_FLAG,@CM2_X384 ; Mark as not recovering 384 of RAM
	 and	 CM2_FLAG,not @CM2_SHD ; Mark as no SHADOWRAM

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_NOXRAM endp 		; End FCN_NOXRAM procedure
	 FPPROC  FCN_RET -- This routine does nothing
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 clc			; Indicate that all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_RET  endp			; End FCN_RET procedure
	 FPPROC  FCN_ON -- ON Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 GLB_FLAG,@GLB_ON ; Mark as initially ON
	 and	 GLB_FLAG,not @GLB_AUTO ; ...and not AUTO
	 or	 CMD_FLAG,@CMD_INI ; Mark as present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_ON	 endp			; End FCN_ON procedure
	 FPPROC  FCN_POSFILE -- POSFILE=d:\path\filename.ext Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT^

Process a new POS file.
Read data from file & compare with data gotten from ABIOS into
POSDATA.  For each slot, write out only if different from POSDATA
values.  Reboot ONLY if one or more differences necessitated writing
to the POS.

Since MAXIMIZE now supports POS indices greater than 0-3, for the
system board only we need to support writes into NVRAM followed
by recomputation of the NVRAM checksum.

Systems like the Model 56 486SLC2 require manual calculation of the
NVRAM CRC.  This is handled in NVRAM_CRC.  Perhaps it's a bug or an
oversight that the ABIOS doesn't handle it.

The format of POSFILE.BIN has changed slightly:
Field	Type	Length	Description
Slot #	BYTE	1	Bits 0-5 are the slot number, with 0 being the
			system board.  If bit 7 = 1, 32 bytes of POS data
			rather than 4 follow.  This will only occur for
			the system board.  If bit 6 = 1, it's a different
			record type altogether.  If the entire field is
			0FFh, it's the end of the file.

If bit 6 of slot # is clear:
POS data BYTE	{4|32}	Length is 4 unless bit 7 of the slot # field is set.
			With 4 byte POS values, if any of the values are
			different from current CMOS POS values, all 4 will
			be written.  With 32 byte NVRAM values, each byte
			is compared.  Only changed bytes are written to
			NVRAM.

If bit 6 of slot # is set:
Index	WORD	1	Starting index into NVRAM.  This is normally 369h
			for the planar device (slot 0).
Data len BYTE	1	Number of data bytes following
NV data BYTE	?	Data bytes to write into NVRAM starting at Index.

On entry:

DS:SI	 ==>	 next character in command line or profile

On exit:

CF	 =	 1 if something went wrong
DS:SI	 ==>	 next character in command line or profile (updated)
Reboot system otherwise

^

	 REGSAVE <ax,bx,cx,dx,di,bp,gs> ; Save registers

	 push	 OLDINT24_VEC	; Save old INT 24h handler's address
	 call	 INST24 	; Install local INT 24h handler

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 near ptr FCN_POSFILE_EQ ; Too bad

	 push	 1		; Mark as to be deleted
	 call	 READFILE	; Read in the file at DS:SI
	 mov	 bp,si		; Save SI ==> end of arguments
	 jc	 near ptr FCN_POSFILE_CLC ; Something went wrong, ignore it

	 mov	 gs,READ_SEG	; Get the segment
	 assume  gs:nothing	; Tell the assembler about it
	 xor	 si,si		; GS:SI ==> POS values from file

; Process the POS file -- note that POSINIT has been called already
	 mov	 POSFILE_SLOTCHG, 0 ; initialize count of slots changed

FCN_POSFILE_NEXT:
	 xor	 ah,ah		; Zero to use as word
	 lods	 gs:[si].LO	; Get the slot # (0 for system, 1-8 for
				; slots, 80h for direct NVRAM write, or
				; 40h for NVRAM write to a specified base)

	 cmp	 al,0FFh	; Izit the end?
	 je	 short FCN_POSFILE_EOF ; Jump if so

; Get the adapter ID for slot AX into BX

	 push	 ax		; Save for a moment

	 and	 al,3fh 	; Strip high bits
	 mov	 bx,ax		; Save slot # (origin:1)
	 sub	 al,1		; Convert to origin:0
	 jnc	 short @F	; Jump if not slot 0

	 mov	 al,@MAXPOSDEV-1 ; Index for slot 0 data
@@:
	 mov	 ah,(size POSD_STR) ; Prepare for MUL
	 mul	 ah		; Get pointer into POSDATA
	 mov	 di,ax		; Put pointer in index register
	 lea	 di,POSDATA[di].POSD_ID ; PGROUP:DI ==> CMOS POS values
	 call	 GET_POSID	; Return with AX = POS ID for slot BL (origin:1)
	 mov	 bx,ax		; Copy POS ID

	 pop	 ax		; Restore

; Check POS ID for slot against POSDATA
	 cmp	 bx,PGROUP:[di].POSD_ID ; Does the ID match?
	 jne	 near ptr FCN_POSFILE_ERR ; Something is wrong with our data

; Handle writes to NVRAM specially
	 test	 al,80h 	; Izit NVRAM write for system board?
	 jz	 short @F	; Jump if not

	 push	 @NVRAMPOSBASE	; Default base for system board POS[0] (369h)
	 mov	 ax,@NVRAMPOSMAX ; Default number of bytes for system board (32)
	 jmp	 short FCN_POSFILE_NVRAMCOM ; Join common code

@@:
	 test	 al,40h 	; Izit NVRAM write to specified base?
	 jz	 short @F	; Jump if not

	 lods	 gs:[si].ELO	; Get starting NVRAM offset
	 push	 ax		; Pass first argument
	 lods	 gs:[si].LO	; Get number of bytes following
	 sub	 ah,ah		; Clear high byte
FCN_POSFILE_NVRAMCOM:
	 push	 ax		; Pass second argument
	 push	 gs		; Pass segment of data
	 push	 si		; ...  offset
	 call	 NVRAM_CMPWRITE ; Return with CF=1 if values different
	 rcl	 POSFILE_SLOTCHG,1 ; Set bit 0 if changed
	 ror	 POSFILE_SLOTCHG,1 ; Set high bit for manual CRC

	 add	 si,ax		; Skip remainder of data

	 jmp	 FCN_POSFILE_NEXT ; Go around again

@@:
; Check POSDATA values against POSFILE values
	 mov	 cx, (size POSD_STR) - (type POSD_STR.POSD_ID) ; get # of bytes
								; to check
	 lea	 di,[di].POSD_CMOS[0] ; PGROUP:di ==> POSDATA.POSD_CMOS
	 push	 si		; save pointer into POSFILE data
    repe cmps	 gs:[si].LO,PGROUP:[di].LO ; are they all the same?
	 pop	 si		; restore pointer to POSFILE data
	 je	 short @F	; if all are the same, don't write POS

FCN_POSFILE_BLAST:
; blast values into POS
	 inc	 POSFILE_SLOTCHG ; bump count of changed slots

	 push	 bx		; Pass adapter ID
	 push	 gs		; Pass segment of CMOS values
	 push	 si		; ...  offset
	 push	 ax		; Pass slot # (origin-1)
	 call	 POSWRITE	; Write out new POS values

@@:
	 add	 si,4		; Skip over the four POS values

	 jmp	 FCN_POSFILE_NEXT ; Go around again

FCN_POSFILE_EOF:
; Reached the end of the POSFILE; check to see if any slots were changed
	 cmp	 POSFILE_SLOTCHG,0 ; did any slots get reprogrammed?
	 jz	 short FCN_POSFILE_CLC ; no changes, so continue

; If bit 7 was set, we need to manually recompute the NVRAM CRC (ugh).
	 test	 POSFILE_SLOTCHG,80h ; Any changes to NVRAM?
	 jz	 short FCN_POSFILE_REBOOT ; Jump if not

	 call	 NVRAM_CRC	; Recalculate NVRAM CRC on Model 56 SLC2

; In case future implementations use the ABIOS checksum function to
; also calculate the NVRAM CRC, we always call it...
;;;;;;;  test	 POSFILE_SLOTCHG,7fh ; Did any other adapters change?
;;;;;;;  jz	 short FCN_POSFILE_REBOOT2 ; Jump if not

FCN_POSFILE_REBOOT:
	 mov	 ah,0Bh 	; Recompute NVRAM checksum
	 call	 NVRAMFN	; AX = error code if CF=1
;;;;;;;  jc	 ???		; Ignore error

FCN_POSFILE_REBOOT2:
; The new POS values have been written out -- reboot so they can take effect

	 push	 offset YGROUP:MSG_POSBOOT ; Pass address of message
	 call	 YMSGOUT2	; Display YGROUP message

; Pause for a moment to allow the user to read the message

	 call	 BOOTPAUSE	; Pause it

; Ensure the reset flag has the proper value

	 mov	 ax,seg BIOSDATA ; Get segment of BIOS data area
	 mov	 ds,ax		; Address it
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 mov	 RESET_FLAG,1234h ; Tell 'em we're rebooting

	 jmp	 REBOOT 	; Jump to BIOS reboot location

	 assume  ds:nothing	; Tell the assembler about it

FCN_POSFILE_CLC:

; Search for end of arguments to reach EOL

	 mov	 si,bp		; Get saved argument list pointer
	 call	 ARGEND 	; Return with DS:DI ==> end of argument list
	 mov	 si,di		; SI ==> end of argument list

	 clc			; Mark as valid

	 jmp	 short FCN_POSFILE_EXIT ; Join common tail code

FCN_POSFILE_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword

	 mov	 bp,si		; Put argument pointer in BP
FCN_POSFILE_ERR:
	 mov	 si,bp		; Restore updated argument pointer
	 stc			; Indicate there was a problem
FCN_POSFILE_EXIT:

	 call	 REST24 	; Restore INT 24h handler
	 pop	 OLDINT24_VEC	; Restore old INT 24h handler's address

	 REGREST <gs,bp,di,dx,cx,bx,ax> ; Restore
	 assume  gs:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_POSFILE endp		; End FCN_POSFILE procedure
if @OEM_HIFILL
	 FPPROC  FCN_PRGREG -- PRGREG=n Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_PRGREG_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_PRGREG_CLC ; Jump if too large, ignore it

	 cmp	 ax,1		; Check against minimum
	 jb	 short FCN_PRGREG0 ; Jump if zero

	 cmp	 ax,9		; Check against maximum
	 ja	 short FCN_PRGREG_CLC ; Ignore it and use first region

	 or	 CM3_FLAG,@CM3_PREG ; Mark as present
	 mov	 PRGREG,ax	; Save for later use

	 jmp	 short FCN_PRGREG_CLC ; Join common code

FCN_PRGREG0:
	 or	 CM3_FLAG,@CM3_PREG0 ; Mark as present
	 and	 CM3_FLAG,not @CM3_XLHI ; PRGREG=0 supplants NOLOADHI
if @OEM_HIFILL
	 and	 LSEG.LSEG_FLAG,not @LSEG_XLHI ; ...
endif				; IF @OEM_HIFILL
FCN_PRGREG_CLC:
	 clc			; Indicate all went well

	 jmp	 short FCN_PRGREG_EXIT ; Join common exit code

FCN_PRGREG_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_PRGREG_ERR:
	 stc			; Indicate something went wrong
FCN_PRGREG_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_PRGREG endp 		; End FCN_PRGREG procedure
endif				; IF @OEM_HIFILL
if @OEM_MISC
	 FPPROC  FCN_PRO -- PRO=d:\path\filename.ext Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax>		; Save register

	 push	 OLDINT24_VEC	; Save old INT 24h handler's address
	 call	 INST24 	; Install local INT 24h handler

; Ensure we're not already processing a profile

	 test	 NRD_FLAG,@NRD_PRO ; Already in process?
	 jnz	 short FCN_PRO_UNK ; Yes, so that's an error

	 or	 NRD_FLAG,@NRD_PRO ; Mark as being processed

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_PRO_EQ ; Too bad

	 push	 0		; Mark as NOT to be deleted
	 call	 READFILE	; Read in the file at DS:SI
	 jc	 short FCN_PRO_OPEN ; Something went wrong

	 mov	 ax,READ_SEG	; Get the segment
	 mov	 PROF_SEG,ax	; Save for later use
	 mov	 ax,READ_CNT	; Get the count
	 mov	 PROF_CNT,ax	; Save for later use

; Process the profile

	 call	 PROC_PROFILE	; Process the profile entries
				; Return with CF significant
	 jmp	 short FCN_PRO_EXIT ; Join common tail code

FCN_PRO_OPEN:
	 push	 offset YGROUP:MSG_POPEN ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 jmp	 short FCN_PRO_ERR ; Join common tail code

FCN_PRO_UNK:
	 push	 di		; Save for later

	 mov	 di,offset YGROUP:MSG_UNK ; Pass address of error message
	 call	 DISP_UNK2	; Display it along with unknown keyword at DS:SI

	 pop	 di		; Restore

	 jmp	 short FCN_PRO_EXIT ; Join common tail code

FCN_PRO_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_PRO_ERR:
	 stc			; Indicate there was a problem
FCN_PRO_EXIT:
	 pushf			; Save flags
	 and	 NRD_FLAG,not @NRD_PRO ; Mark as not being processed
	 popf			; Restore

	 call	 REST24 	; Restore INT 24h handler
	 pop	 OLDINT24_VEC	; Restore old INT 24h handler's address

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_PRO  endp			; End FCN_PRO procedure
endif				; IF @OEM_MISC
if @OEM_SYS eq @OEMSYS_RET
	 FPPROC  FCN_PSMEM -- PSMEM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_PSMEM_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_PSMEM_ERR ; Jump if too large

; Round down to 4KB boundary

	 and	 ax,not (4-1)	; Round it down

	 mov	 PSMSIZE,ax	; Set size of Periscope memory
	 mov	 PSMWIN,8*4	; Set size of Periscope window in high DOS
				; in 1KB (/4KB)

; Check for optional window segment

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character in case not separator

	 cmp	 al,','         ; Izit separator for optional window segment?
	 jne	 short FCN_PSMEM_CLC ; Jump if not

	 inc	 si		; Skip over separator

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,16		; Use base 16 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_PSMEM_ERR ; Jump if too large

	 and	 ax,not ((4*1024/16)-1) ; Round down to a 4KB boundary
	 mov	 PSMSEG,ax	; Save as window segment
FCN_PSMEM_CLC:
	 clc			; Indicate all went well

	 jmp	 short FCN_PSMEM_EXIT ; Join common exit code

FCN_PSMEM_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_PSMEM_ERR:
	 stc			; Indicate something went wrong
FCN_PSMEM_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_PSMEM endp			; End FCN_PSMEM procedure
endif				; IF @OEM_SYS eq @OEMSYS_RET
if @OEM_HIFILL
	 FPPROC  FCN_RAM -- RAM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx,di,bp>	; Save registers
FCN_RAM_AGAIN:
	 call	 GET_CMDARGS	; Parse command line for xxxx-yyyy
	 jc	 short FCN_RAM_ERR ; Jump if something went wrong
				; Return with BP = 1st arg, AX = length

	 mov	 cx,ax		; Copy to count register
	 shr	 cx,9-4 	; Convert from paras to 512
	 jz	 short @F	; Jump if empty RAM

; Mark as other RAM in MEM_MAP

	 mov	 di,bp		; Copy to STOSB register
	 shr	 di,9-4 	; Convert from paras to 512-byte
	 lea	 di,MEM_MAP[di] ; Point to spot within MEM_MAP

	 mov	 al,@XLAT_OTH	; Other RAM index
	 call	 MARKENTRY	; Mark the entries avoiding ROM overwrite
@@:
	 mov	 SEPARATOR,','  ; Mark as new separator

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Check for more arguments
	 je	 short FCN_RAM_AGAIN ; Yes, go around again

	 or	 CM2_FLAG,@CM2_RAM ; Mark as present

	 clc			; Indicate all went well

	 jmp	 short FCN_RAM_EXIT ; Join common exit code

FCN_RAM_ERR:
	 stc			; Indicate something went wrong
FCN_RAM_EXIT:
	 mov	 SEPARATOR,'='  ; Mark as old separator

	 REGREST <bp,di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_RAM  endp			; End FCN_RAM procedure
endif				; IF @OEM_HIFILL
	 FPPROC  FCN_RESETKEYB -- RESETKEYB Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM2_FLAG,@CM2_SELFT ; Mark as 8042 self-test on GOREAL

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_RESETKEYB endp		; End FCN_RESETKEYB procedure
if @OEM_HIFILL or @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2 or @OEM_SYS eq @OEMSYS_CA
	 FPPROC  FCN_ROM -- ROM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,bx,cx,di,bp> ; Save registers
FCN_ROM_AGAIN:
	 call	 GET_CMDARGS	; Parse command line for xxxx-yyyy
	 jc	 short FCN_ROM_ERR ; Jump if something went wrong
				; Return with BP = 1st arg, AX = length

	 mov	 cx,ax		; Copy length in paras
	 shr	 cx,9-4 	; Convert from paras to 512
	 jz	 short FCN_ROM_MARK ; Jump if empty ROM

; Mark as ROM in MEM_MAP

	 mov	 di,bp		; Copy to FILL_ROM register
	 shr	 di,9-4 	; Convert from paras to 512
	 lea	 di,MEM_MAP[di] ; Point to spot within MEM_MAP

	 mov	 al,@XLAT_ROM0	; Use special ROM marker
	 call	 FILL_ROM	; Fill in ROM values in MEM_MAP

	 add	 di,cx		; Check next location for @XLAT_ROM2

	 cmp	 PGROUP:[di].LO,@XLAT_ROM2 ; Did we overwrite another ROM?
	 jne	 short FCN_ROM_MARK ; Not this time

	 mov	 PGROUP:[di].LO,@XLAT_ROM1 ; Mark as starting a normal ROM
FCN_ROM_MARK:
	 or	 CM2_FLAG,@CM2_ROM ; Mark as ROM specified

	 mov	 SEPARATOR,','  ; Mark as new separator

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Check for more arguments
	 je	 short FCN_ROM_AGAIN ; Yes, go around again

	 or	 CM2_FLAG,@CM2_ROM ; Mark as present

	 clc			; Indicate all went well

	 jmp	 short FCN_ROM_EXIT ; Join common exit code

FCN_ROM_ERR:
	 stc			; Indicate something went wrong
FCN_ROM_EXIT:
	 mov	 SEPARATOR,'='  ; Mark as old separator

	 REGREST <bp,di,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_ROM  endp			; End FCN_ROM procedure
endif				; IF @OEM_HIFILL or @OEM_SYS eq @OEMSYS_OLI or @OEM_SYS eq @OEMSYS_OL2 or @OEM_SYS eq @OEMSYS_CA
if @OEM_EMS and (@OEM_SYS eq @OEMSYS_RET or @OEM_SYS eq @OEMSYS_SHS)
	 FPPROC  FCN_SCREEN -- SCREEN Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx,di>	; Save registers

	 or	 CM2_FLAG,@CM2_SCR ; Mark as SCREEN specified

; Mark the entries in PPMTAB as @PPM_SCR

	 lea	 di,PPMTAB[0B000h shr (14-4)] ; ES:DI ==> B000 in 16KB
	 mov	 al,@PPM_SCR	; Mark as SCREEN pages
	 mov	 cx,64/16	; All 64KB's worth
     rep stos	 PGROUP:[di].LO ; Fill it up

	 REGREST <di,cx,ax>	; Restore

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SCREEN endp 		; End FCN_SCREEN procedure
endif				; IF @OEM_EMS and (@OEM_SYS eq @OEMSYS_RET or @OEM_SYS eq @OEMSYS_SHS)
if @OEM_SRAM or @OEM_SYS eq @OEMSYS_HPRS or @OEM_SYS eq @OEMSYS_NEC
	 FPPROC  FCN_SHADOWRAM -- SHADOWRAM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx,dx,ds>	; Save for a moment

	 test	 CM2_FLAG,@CM2_X384 ; NOXRAM specified?
	 jnz	 short FCN_SHADOWRAM_CLC ; Yes, ignore the keyword

	 or	 CM3_FLAG,@CM3_SHDCA ; Mark as using SHADOWRAM in case CompuAdd

	 call	 CHECK_CHIPSET	; Check on it
	 jc	 short FCN_SHADOWRAM_CLC ; Jump if not present

	 jcxz	 FCN_SHADOWRAM_SHD ; Jump if 82C302

	 mov	 CT_ROMCFG,65h	; Mark as 82C212 register
	 mov	 CT_RAM_AB,67h
	 mov	 CT_RAM_CD,68h
	 mov	 CT_RAM_EF,69h
FCN_SHADOWRAM_SHD:
	 or	 CM2_FLAG,@CM2_SHD ; Mark as using SHADOWRAM
	 and	 CM3_FLAG,not @CM3_SHDCA ; Mark as not set
FCN_SHADOWRAM_CLC:
	 clc			; Indicate all went well

	 REGREST <ds,dx,cx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SHADOWRAM endp		; End FCN_SHADOWRAM procedure
endif				; IF @OEM_SRAM or @OEM_SYS eq @OEMSYS_HPRS or @OEM_SYS eq @OEMSYS_NEC
if @OEM_SYS ne @OEMSYS_ILIM and @OEM_SYS ne @OEMSYS_HPRS
	 FPPROC  FCN_SHADOWROM -- SHADOWROM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM3_FLAG,@CM3_ROMSH ; Leave the ROM at E000 or E800 alone

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SHADOWROM endp		; End FCN_SHADOWROM procedure
endif				; IF @OEM_SYS ne @OEMSYS_ILIM and @OEM_SYS ne @OEMSYS_HPRS
if @OEM_DMA and @OEM_DEBUG
	 FPPROC  FCN_SLOWDMA -- SLOWDMA Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM2_FLAG,@CM2_SDMA ; Mark as SLOWDMA

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SLOWDMA endp		; End FCN_SLOWDMA procedure
endif				; IF @OEM_DMA and @OEM_DEBUG
if @OEM_HIFILL
	 FPPROC  FCN_STACKREG -- STACKREG=size,reg Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <bx>		; Save

	 lea	 bx,XGROUP:STACKR ; Address structure
	 call	 GETREG_SUB	; Return CF=0 if OK
	 jc	 short @F	; Jump if failed

	 or	 NRD_FLAG,@NRD_SRSPEC ; Mark as specified (note CF=0)
@@:
	 REGREST <bx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_STACKREG endp		; End FCN_STACKREG procedure
endif				; IF @OEM_HIFILL
	 FPPROC  FCN_STACKS -- STACKS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

To setup DOS stacks, use

STACKS=nn[,nnn] [/H] [/I=nn,nn,...]
STACKS=ON
STACKS=OFF

|

	 REGSAVE <ax,cx,dx,di>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 near ptr FCN_STACKS_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 ds:[si].ELO,'FO' ; Izit start of 'OFF'?
	 je	 near ptr FCN_STACKS_OFF ; Jump if so

	 cmp	 ds:[si].ELO,'NO' ; Izit start of 'ON'?
	 je	 near ptr FCN_STACKS_ON ; Jump if so

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_STACKS_ERR ; Jump if too large

	 mov	 DSTK_CNT,ax	; Save as # DOS stacks
	 and	 I15_FLAG,not @I15_DSTK ; Clear the bits in
				; case there's more than one STACKS= specified
	 and	 ax,ax		; Izit active?
	 jz	 short @F	; Jump if not

	 or	 I15_FLAG,@I15_DSTK ; Mark as active
@@:
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Izit separator?
	 jne	 short FCN_STACKS_XSEP1 ; Jump if not (use default size)

	 inc	 si		; Skip over separator

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_STACKS_ERR ; Jump if too large

	 add	 ax,4-1 	; Round up to next dword
	 and	 ax,not (4-1)	; ...
	 mov	 DSTK_ISIZ,ax	; Save as size of each stack in bytes (/4)
FCN_STACKS_XSEP:
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character
FCN_STACKS_XSEP1:

; Check for optional switches

	 cmp	 al,'/'         ; Izit switch character?
	 jne	 short FCN_STACKS_CLC ; Jump if not

	 inc	 si		; Skip over separator

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'h'         ; Izit locate stacks high?
	 jne	 short FCN_STACKS_XSW_H ; Jump if not

	 or	 NRD_FLAG,@NRD_STACKHI ; Use STACKREG=PRGREG if none specified

	 jmp	 short FCN_STACKS_XSEP ; Go around again

FCN_STACKS_XSW_H:
	 cmp	 al,'i'         ; Izit select interrupt #?
	 jne	 short FCN_STACKS_XSW_I ; Jump if not

	 mov	 dl,'='         ; Use initial separator
FCN_STACKS_SW_I:
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,dl		; Izit separator?
	 jne	 short FCN_STACKS_XSEP1 ; Jump if not

	 inc	 si		; Skip over separator
	 mov	 dl,','         ; Use secondary separator

	 mov	 cx,16		; Use base 16 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 near ptr FCN_STACKS_ERR ; Jump if too large

	 cmp	 ax,@IMRBASE	; Izit below master PIC start?
	 jb	 short @F	; Jump if so

	 cmp	 ax,@IMRBASE+8	; Izit above master PIC end?
	 ja	 short @F	; Jump if so

	 bts	 DSTK_HWINTS.ELO,ax ; Mark as to be intercepted

	 jmp	 short FCN_STACKS_SW_I ; Go around again

@@:
	 cmp	 ax,@IMR2BASE	; Izit below slave PIC start?
	 jb	 short FCN_STACKS_OVF ; Jump if so

	 cmp	 ax,@IMR2BASE+8 ; Izit above slave PIC end?
	 ja	 short FCN_STACKS_OVF ; Jump if so

	 bts	 DSTK_HWINTS.ELO,ax ; Mark as to be intercepted

	 jmp	 short FCN_STACKS_SW_I ; Go around again

FCN_STACKS_XSW_I:
FCN_STACKS_XSW:

; Unknown switch character

	 push	 offset YGROUP:MSG_SWERR ; Pass offset in YGROUP of error message
	 call	 DISP_ERRLAST2	; Display error message with last keyword
				; Returns CF=1 if user wishes to abort

	 pushf			; Save CF state

	 call	 XSKIP_BLACK	; Skip to end of STACKS= line to prevent
				; A second error (invalid line ending)

	 popf			; Restore CF state

	 jmp	 short FCN_STACKS_EXIT ; Join common error code (CF set)

; Invalid interrupt number

FCN_STACKS_OVF:
	 push	 offset YGROUP:MSG_OVF ; Pass offset in YGROUP of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword

	 jmp	 short FCN_STACKS_ERR ; Join common error code

FCN_STACKS_CLC:

; Calculate the size of DSTK_TAB_STR at one entry per DOS stack

	 mov	 ax,DSTK_CNT	; Get the # DOS stacks
	 imul	 cx,ax,type DSTK_TAB_STR ; Times size of each entry

; Calculate the total stack size

;;;;;;;; mov	 ax,DSTK_CNT	; Get the # DOS stacks
	 mul	 DSTK_ISIZ	; Times the individual size in bytes (/4)
	 jc	 short FCN_STACKS_OVF ; Jump if it's too large

	 add	 ax,offset SGROUP:SCODE_END[16-1] ; Plus code size, round up
				; to para boundary
	 jc	 short FCN_STACKS_OVF ; Jump if it's too large

	 add	 ax,cx		; Add in size of DSTK_TAB_STR
	 jc	 short FCN_STACKS_OVF ; Jump if it's too large

	 shr	 ax,4-0 	; Convert from bytes to paras
	 mov	 DSTK_NPAR,ax	; Save for later use

; If there were no /I= switches, mark all HW
; interrupts as being intercepted

	 cmp	 DSTK_HWINTS[@IMRBASE/8],0 ; Has it been set by /I=?
	 jne	 short @F	; Jump if so

	 cmp	 DSTK_HWINTS[@IMR2BASE/8],0 ; Has it been set by /I=?
	 jne	 short @F	; Jump if so

	 mov	 DSTK_HWINTS[@IMRBASE/8],0FFh ; Mark master HW interrupts
	 mov	 DSTK_HWINTS[@IMR2BASE/8],0FFh ; ...  slave ...
@@:
FCN_STACKS_ONCOM:
	 and	 DSTK_FLAG,not (mask $DSTK_GLBOFF) ; Mark as globally on
FCN_STACKS_OFFCOM:
	 clc			; Indicate all went well

	 jmp	 short FCN_STACKS_EXIT ; Join common exit code

; The keyword starts with 'OF'.  Ensure it ends with 'F'.

FCN_STACKS_OFF:
	 cmp	 ds:[si+2].LO,'F' ; Izit the end of 'OFF'?
	 jne	 short FCN_STACKS_XSW ; Jump if not (bad switch)

	 or	 DSTK_FLAG,mask $DSTK_GLBOFF ; Mark as globally off

	 add	 si,3		; Skip over the keyword

	 jmp	 short FCN_STACKS_OFFCOM ; Join common code

; The keyword starts with 'ON', or 'OFF'.  Skip over the text

FCN_STACKS_ON:
	 add	 si,2		; Skip over the keyword

	 jmp	 short FCN_STACKS_ONCOM ; Join common code

FCN_STACKS_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_STACKS_ERR:
	 stc			; Indicate something went wrong
FCN_STACKS_EXIT:
	 REGREST <di,dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_STACKS endp 		; End FCN_STACKS procedure
if @OEM_SOFT or @OEM_ACCEL
	 FPPROC  FCN_SWAP -- SWAP Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_SWAP_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_SWAP_ERR ; Jump if too large

	 test	 al,4-1 	; Ensure it's a multiple of 4K
	 jz	 short @F	; It is

	 and	 al,not (4-1)	; Round down to 4KB boundary
@@:
	 cmp	 ax,640 	; Check against 640KB limit
	 jbe	 short @F	; It's within range

	 mov	 ax,640 	; Use maximum
@@:
	 mov	 SWPSIZE,ax	; Save for later use

	 clc			; Indicate all went well

	 jmp	 short FCN_SWAP_EXIT ; Join common exit code

FCN_SWAP_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_SWAP_ERR:
	 stc			; Indicate something went wrong
FCN_SWAP_EXIT:
	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SWAP endp			; End FCN_SWAP procedure
endif				; IF @OEM_SOFT or @OEM_ACCEL
if @OEM_VIRTUALMEM
	 FPPROC  FCN_SWAPFILE -- SWAPFILE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <eax,bx,cx,edx,di,es,gs> ; Save registers

	 push	 OLDINT24_VEC	; Save old INT 24h handler's address
	 call	 INST24 	; Install local INT 24h handler

	 mov	 ax,seg PGROUP	; Get segment of PGROUP
	 mov	 gs,ax		; Address it
	 assume  gs:PGROUP	; Tell the assembler about it

	 mov	 ax,seg IGROUP	; Get segment of IGROUP
	 mov	 es,ax		; Address it
	 assume  es:IGROUP	; Tell the assembler about it

	 or	 VMM_FLAG,@VMM_BSTEMP ; Mark as temporary swapfile

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 call	 IZITCOMMENT	; Izit start of comment?
	 je	 short FCN_SWAPFILE_TMP ; Jump if so

	 call	 IZITEOL	; Check for end of the line
	 je	 short FCN_SWAPFILE_TMP ; Jump if so

	 cmp	 al,'/'         ; Izit switch character?
	 je	 short FCN_SWAPFILE_TMP ; Jump if so

	 cmp	 al,'='         ; Must be
	 jne	 near ptr FCN_SWAPFILE_EQ ; Too bad

	 inc	 si		; Skip over it
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

; Copy and normalize the FID to BSPATH

	 lea	 di,BSPath	; ES:DI ==> output save area

	 cmp	 ds:[si+1].LO,':' ; Is there a drive separator?
	 je	 short FCN_SWAPFILE1 ; Jump if so

	 DOSCALL @GETDSK	; Return with current drive # in AL (origin-0)
	 add	 al,'A'         ; Convert to uppercase ASCII

S16	 stos	 BSPath[di]	; Save in output area
	 mov	 al,':'         ; Get drive separator
S16	 stos	 BSPath[di]	; Save in output area

	 jmp	 short FCN_SWAPFILE2 ; Join common code

FCN_SWAPFILE1:
S16	 movs	 <BSPath[di].ELO,ds:[si].ELO> ; Move drive letter and separator
FCN_SWAPFILE2:
	 cmp	 ds:[si].LO,'\' ; Is there a path separator?
	 je	 short FCN_SWAPFILE3 ; Jump if so

	 mov	 al,'\'         ; Get path separator
S16	 stos	 BSPath[di]	; Save in output area

	 REGSAVE <si,ds>	; Save for a moment

	 mov	 al,BSPath	; Get drive letter
	 call	 UPPERCASE	; Convert AL to uppercase
	 sub	 al,'A'-1       ; Convert to origin-1
	 mov	 dl,al		; Copy to @GETDIR register

	 push	 es		; Get destin segment
	 pop	 ds		; Address it
	 assume  ds:nothing	; Tell the assembler about it
	 mov	 si,di		; DS:SI ==> output save area

	 DOSCALL @GETDIR	; Get current directory for drive DL to DS:SI

; Skip to the end of the output area

	 mov	 al,0		; String terminator
	 mov	 cx,-1		; We know it's there
   repne scas	 BSPath[di]	; Search for it

	 dec	 di		; Back off to trailing zero

	 cmp	 es:[di-1].LO,'\' ; Is there a trailing path separator?
	 je	 short @F	; Jump if so

	 mov	 al,'\'         ; Get path separator
S16	 stos	 BSPath[di]	; Save in output area
@@:
	 REGREST <ds,si>	; Restore
	 assume  ds:nothing	; Tell the assembler about it
FCN_SWAPFILE3:

; Copy the rest of the FID

FCN_SWAPFILE4:
	 lodsb			; Get the next character

	 cmp	 al,'/'         ; Izit switch character?
	 je	 short FCN_SWAPFILE5 ; Jump if so

	 cmp	 al,' '         ; Too small for filename?
	 jbe	 short FCN_SWAPFILE5 ; Jump if so

S16	 stos	 BSPath[di]	; Save in output area

	 jmp	 short FCN_SWAPFILE4 ; Go around again

; Use a temporary swap file:  use the filename in BSPath, but don't
; create it.

FCN_SWAPFILE_TMP:
	 REGSAVE <si>		; Save for a moment

	 lea	 di,BSPath	; ES:DI ==> output save area

	 lea	 si,XGROUP:FLEXFILE_DPFE ; Address start of path
	 mov	 cx,PATHSTEM_LEN ; Get length of the path
S16  rep movs	 <BSPath[di],FLEXFILE_DPFE[si]> ; Copy the path

	 lea	 si,SWAP_FNEZ	; Get filename.ext,0 of temporary swapfile
	 mov	 cx,SWAP_FNEZ_LEN ; Get # bytes in ...
S16  rep movs	 <BSPath[di],SWAP_FNEZ[si]> ; Copy the filename.ext,0

	 REGREST <si>		; Restore

	 jmp	 short FCN_SWAPFILE_SWITCH ; Join common code

FCN_SWAPFILE5:
	 dec	 si		; Back off to terminator

	 mov	 al,0		; String terminator
S16	 stos	 BSPath[di]	; Save in output area


; Parse switch characters from the command line

FCN_SWAPFILE_SWITCH:
	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,'/'         ; Izit switch character?
	 jne	 short FCN_SWAPFILE_XSW ; Jump if not

	 inc	 si		; Skip over it
	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'s'         ; Izit size?
	 jne	 short FCN_SWAPFILE_XSW_S ; Jump if not

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Izit size?
	 jne	 near ptr FCN_SWAPFILE_EQ ; Jump if not

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Skip back to character

	 cmp	 al,'0'         ; Izit a valid digit?
	 jb	 near ptr FCN_SWAPFILE_VAL ; Jump if not

	 cmp	 al,'9'         ; Izit a valid digit?
	 ja	 near ptr FCN_SWAPFILE_VAL ; Jump if not

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIND	; Convert the number at DS:SI to binary in EAX
	 jc	 near ptr FCN_SWAPFILE_ERR ; Jump if too large

	 add	 eax,(4*1024/1024)-1 ; Round up to 4KB boundary in 1KB
	 shr	 eax,12-10	; Convert from 1KB to 4KB

	 mov	 edx,BSMin	; Get minimum swapfile size in bytes
	 shr	 edx,12-0	; Convert from bytes to 4KB

	 cmp	 eax,edx	; Izit below the minimum?
	 jae	 short @F	; Jump if not

	 mov	 eax,edx	; Use the minimum
@@:
	 mov	 BSGTotal,eax	; Save for later use

	 jmp	 short FCN_SWAPFILE_SWITCH ; Go around again

FCN_SWAPFILE_XSW_S:
	 cmp	 al,'p'         ; Izit perm?
	 jne	 short FCN_SWAPFILE_XSW_P ; Jump if not

	 and	 VMM_FLAG,not @VMM_BSTEMP ; Mark as no longer temporary

	 jmp	 short FCN_SWAPFILE_SWITCH ; Go around again

FCN_SWAPFILE_XSW_P:

; Unknown switch character

	 push	 offset YGROUP:MSG_SWERR ; Pass offset in YGROUP of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword

	 jmp	 short FCN_SWAPFILE_ERR ; Join common error code

FCN_SWAPFILE_XSW:
	 or	 VMM_FLAG,@VMM_BSGLOBAL ; Mark as globally present
FCN_SWAPFILE_CLC:
	 clc			; Indicate all went well

	 jmp	 short FCN_SWAPFILE_EXIT ; Join common exit code


FCN_SWAPFILE_VAL:
	 push	 offset YGROUP:MSG_VAL ; Pass offset in YGROUP of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword

	 jmp	 short FCN_SWAPFILE_ERR ; Join common error code

FCN_SWAPFILE_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass offset in YGROUP of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_SWAPFILE_ERR:
	 stc			; Indicate something went wrong
FCN_SWAPFILE_EXIT:
	 call	 REST24 	; Restore INT 24h handler
	 pop	 OLDINT24_VEC	; Restore old INT 24h handler's address

	 REGREST <gs,es,di,edx,cx,bx,eax> ; Restore
	 assume  es:PGROUP,gs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SWAPFILE endp		; End FCN_SWAPFILE procedure
endif				; IF @OEM_VIRTUALMEM
if @OEM_SOFT
	 FPPROC  FCN_SYS -- SYS Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,ebx,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_SYS_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over white space
	 dec	 si		; Back off to last character

; Search for the argument text

	 xor	 ebx,ebx	; Zero index register
	 mov	 cx,NSYSARGS	; # arguments to check
FCN_SYS_NEXT:
	 REGSAVE <cx,si,di,es>	; Save for a moment

	 push	 seg XGROUP	; Get SYSARG_TAB segment
	 pop	 es		; Address it
	 assume  es:XGROUP	; Tell the assembler about it

	 mov	 di,SYSARG_TAB[ebx*(type SYSARG_TAB)] ; Get location of text
	 mov	 cx,SYSARG_LEN[ebx*(type SYSARG_LEN)] ; Get length
    repe cmps	 ds:[si].LO,SYSARG_TAB.LO[di] ; Compare 'em
	 REGREST <es,di,si,cx>	; Restore
	 assume  es:PGROUP	; Tell the assembler about it
	 je	 short FCN_SYS_FOUND ; A match

	 inc	 ebx		; Skip to next entry

	 loop	 FCN_SYS_NEXT	; Jump if more entries to check

	 push	 offset YGROUP:MSG_UNKSYS ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message

	 jmp	 short FCN_SYS_ERR ; Join common error code

FCN_SYS_FOUND:
	 add	 si,SYSARG_LEN[ebx*(type SYSARG_LEN)] ; Skip over the keyword
;;;;;;;; or	 CMD_FLAG,@CMD_SYS ; Mark as present

	 jmp	 SYSARG_ACT[ebx*(type SYSARG_ACT)] ; Take appropriate action


	 public  SYSCHK_INBOARD
SYSCHK_INBOARD:
	 or	 DBG_FLAG,@DBG_CR3 ; Mark as needing CR3 fixup
	 or	 SYS_FLAG,@SYS_INBRD ; Mark as present

	 jmp	 short FCN_SYS_CLC ; Join common code


	 public  SYSCHK_JET386
SYSCHK_JET386:
	 or	 SYS_FLAG,@SYS_JET386 ; Mark as present
FCN_SYS_CLC:
	 clc			; Indicate all went well

	 jmp	 short FCN_SYS_EXIT ; Join common exit code


FCN_SYS_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_SYS_ERR:
	 stc			; Indicate something went wrong
FCN_SYS_EXIT:
	 REGREST <cx,ebx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_SYS  endp			; End FCN_SYS procedure
endif				; IF @OEM_SOFT
if @OEM_SYS eq @OEMSYS_RET
	 FPPROC  FCN_TERSE -- TERSE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CMD_FLAG,@CMD_TERSE ; Mark as terse mode

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TERSE endp			; End FCN_TERSE procedure
endif				; IF @OEM_SYS eq @OEMSYS_RET
if @OEM_SOFT or @OEM_SYS eq @OEMSYS_OEM or @OEM_SYS eq @OEMSYS_ASEM
	 FPPROC  FCN_TOP384 -- TOP384 Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 cmp	 PHYSIZE,16*1024-384 ; Check it
	 jbe	 short @F	; Jump if there's no overlap

	 or	 CM2_FLAG,@CM2_X384 ; Skip shadow RAM fill

	 jmp	 short FCN_TOP384_EXIT ; Join common exit code

@@:
	 or	 CM2_FLAG,@CM2_TOP ; Mark as generic top 384KB of RAM
	 or	 I15_FLAG,@I15_CPQ ; ...
FCN_TOP384_EXIT:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TOP384 endp 		; End FCN_TOP384 procedure
endif				; IF @OEM_SOFT or @OEM_SYS eq @OEMSYS_OEM or @OEM_SYS eq @OEMSYS_ASEM
if @OEM_DEBUG and DBG_TRACE
	 FPPROC  FCN_TRACE -- TRACE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM3_FLAG,@CM3_TRACE ; Mark as trace buffer active

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_TRACE endp			; End FCN_TRACE procedure
endif				; IF @OEM_DEBUG and DBG_TRACE
if @OEM_SOFT
	 FPPROC  FCN_UNSHIFT -- UNSHIFT Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 CM2_FLAG,@CM2_UNSH ; Mark as avoid extraneous shifts
	 and	 CM3_FLAG,not @CM3_XA20 ; Remove FORCEA20 if present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_UNSHIFT endp		; End FCN_UNSHIFT procedure
endif				; IF @OEM_SOFT
if @OEM_HIFILL
	 FPPROC  FCN_USE -- USE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx,di,bp>	; Save registers
FCN_USE_AGAIN:
	 call	 GET_CMDARGS	; Parse command line for xxxx-yyyy
	 jc	 short FCN_USE_ERR ; Jump if something went wrong
				; Return with BP = 1st arg, AX = length

if @OEM_BCF

; If BCF is in effect, limit the range of this USE= statement to
; the portion below BCF-compressed system ROM

	 cmp	 BCF_SEG,0	; Izit in effect?
	 je	 short FCN_USE_XBCF ; Jump if not

	 mov	 cx,bp		; Copy starting para
	 add	 cx,ax		; Plus length to get ending para

	 cmp	 cx,SYSROM_START ; Izit overlapping?
	 jbe	 short FCN_USE_XBCF ; Jump if not

	 mov	 ax,SYSROM_START ; Get new ending para

	 sub	 ax,bp		; Less starting para to get length
	 jbe	 short FCN_USE_NEXT ; Jump if too small
FCN_USE_XBCF:
endif				; IF @OEM_BCF

; Mark as OVR in MEM_MAP

	 mov	 cx,ax		; Copy to count register
	 shr	 cx,9-4 	; Convert from paras to 512
	 shr	 bp,9-4 	; Convert from paras to 512
	 lea	 di,MEM_MAP[bp] ; Point to spot within MEM_MAP

	 mov	 al,@XLAT_OVR	; OVR index
	 call	 MARKENTRY	; Mark the entries avoiding ROM overwrite

;;;;;;;; cmp	 PGROUP:[di].LO,@XLAT_ROM2 ; Izit secondary ROM indicator?
;;;;;;;; jne	 short @F	; Not this time
;;;;;;;;
;;;;;;;; mov	 PGROUP:[di].LO,@XLAT_ROM1 ; Mark as primary ROM indicator
;;:
FCN_USE_NEXT:
	 mov	 SEPARATOR,','  ; Mark as new separator

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 cmp	 al,','         ; Check for more arguments
	 je	 short FCN_USE_AGAIN ; Yes, go around again

	 or	 CM2_FLAG,@CM2_USE ; Mark as present

	 clc			; Indicate all went well

	 jmp	 short FCN_USE_EXIT ; Join common exit code

FCN_USE_ERR:
	 stc			; Indicate something went wrong
FCN_USE_EXIT:
	 mov	 SEPARATOR,'='  ; Mark as old separator

	 REGREST <bp,di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_USE  endp			; End FCN_USE procedure
endif				; IF @OEM_HIFILL
if @OEM_LOFILL
	 FPPROC  FCN_VEGA -- EGA/VGA Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,bp>	; Save registers

	 mov	 bp,0A000h	; Get starting offset in paras
	 mov	 ax,02000h	; Get length in paras

	 call	 VIDCOM 	; Set video range to BP (low), AX (length)

	 clc			; Indicate all went well

	 REGREST <bp,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_VEGA endp			; End FCN_VEGA procedure
endif				; IF @OEM_LOFILL
if @OEM_LOFILL
	 FPPROC  FCN_VIDMEM -- VIDMEM Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,bx,bp>	; Save registers

	 call	 GET_CMDARGS	; Parse command line for xxxx-yyyy
	 jc	 short FCN_VIDMEM_ERR ; Jump if something went wrong
				; Return with BP = 1st arg, AX = length

	 mov	 bx,LOWOFF.ELO	; Get current top of low memory

	 cmp	 bp,bx		; Check against minimum
	 jae	 short @F	; It's within range

	 mov	 bp,bx		; Use minimum

	 jmp	 short FCN_VIDMEM_CLC ; Join common exit code

@@:
	 call	 VIDCOM 	; Set video range to BP (low), AX (length)
FCN_VIDMEM_CLC:
	 clc			; Indicate all went well

	 jmp	 short FCN_VIDMEM_EXIT ; Join common exit code

FCN_VIDMEM_ERR:
	 stc			; Indicate something went wrong
FCN_VIDMEM_EXIT:
	 REGREST <bp,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_VIDMEM endp 		; End FCN_VIDMEM procedure
endif				; IF @OEM_LOFILL
	 FPPROC  FCN_WTKF -- WEITEK=FORCE Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

This routine is called from CHECK_NDP for a Cyrix EMC87 which is why
it isn't surrounded by IF @OEM_WTK.

|

	 or	 NRD_FLAG,@NRD_WTK ; Mark as installed
	 or	 CM3_FLAG,@CM3_XA20 ; Mark as FORCEA20

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_WTKF endp			; End FCN_WTKF procedure
if @OEM_WTK
	 FPPROC  FCN_WTK0 -- WEITEK=OFF Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing
COMMENT|

Error is non-fatal.

|

	 test	 NRD_FLAG,@NRD_WTK ; Izit present?
	 jz	 short FCN_WTK0_ERR ; No, so that's an error

	 and	 GLB_FLAG,not @GLB_WTK ; Mark as initially inactive
	 or	 CMD_FLAG,@CMD_WTK ; Mark as present

	 jmp	 short FCN_WTK0_EXIT ; Join common exit code

FCN_WTK0_ERR:
	 push	 offset YGROUP:MSG_CMDCHK_WTK ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message
FCN_WTK0_EXIT:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_WTK0 endp			; End FCN_WTK0 procedure
endif				; IF @OEM_WTK
if @OEM_WTK
	 FPPROC  FCN_WTK1 -- WEITEK=ON Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 test	 NRD_FLAG,@NRD_WTK ; Izit present?
	 jz	 short FCN_WTK1_ERR ; No, so that's an error

	 or	 GLB_FLAG,@GLB_WTK ; Mark as initially active
	 or	 CMD_FLAG,@CMD_WTK ; Mark as present

	 jmp	 short FCN_WTK1_EXIT ; Join common exit code

FCN_WTK1_ERR:
	 push	 offset YGROUP:MSG_CMDCHK_WTK ; Pass address of error message
	 call	 YMSGOUT2	; Display YGROUP message
FCN_WTK1_EXIT:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_WTK1 endp			; End FCN_WTK1 procedure
endif				; IF @OEM_WTK
if @OEM_HIFILL
	 FPPROC  FCN_XBDAREG -- XBDAREG=size,reg Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <bx>		; Save

	 lea	 bx,XGROUP:XBDAR ; Address structure
	 call	 GETREG_SUB	; Return CF=0 if OK
	 jc	 short @F	; Jump if failed

	 or	 NRD_FLAG,@NRD_XBRSPEC ; Mark as specified (note CF=0)
@@:
	 REGREST <bx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_XBDAREG endp		; End FCN_XBDAREG procedure
endif				; IF @OEM_HIFILL
	 FPPROC  FCN_XBIOSHI -- XBIOSHI Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 or	 NRD_FLAG,@NRD_XBIOSHI ; Use XBDAREG=PRGREG if none specified

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_XBIOSHI endp		; End FCN_XBIOSHI procedure
if @OEM_XMS
	 FPPROC  FCN_XMSHNDL -- XMSHNDL Function
	 assume  ds:nothing,es:PGROUP,fs:XGROUP,gs:nothing,ss:nothing

	 REGSAVE <ax,cx>	; Save registers

	 call	 XSKIP_WHITE	; Skip over more white space

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_XMSHNDL_EQ ; Too bad

	 call	 XSKIP_WHITE	; Skip over more white space
	 dec	 si		; Back up to character

	 mov	 cx,10		; Use base 10 to convert
	 call	 BASE2BIN	; Convert the number at DS:SI to binary in AX
	 jc	 short FCN_XMSHNDL_ERR ; Jump if too large

	 cmp	 ax,2		; Check against minimum
	 jae	 short @F	; Jump if it's not too small

	 mov	 ax,2		; Use minimum
@@:
	 cmp	 ax,@MAX_XHNDLCNT ; Check against maximum
	 jbe	 short @F	; Jump if it's not too large

	 mov	 ax,@MAX_XHNDLCNT ; Use maximum
@@:
	 mov	 XMSNHNDL,ax	; Save for later use

	 clc			; Indicate all went well

	 jmp	 short FCN_XMSHNDL_EXIT ; Join common exit code

FCN_XMSHNDL_EQ:
	 push	 offset YGROUP:MSG_SEP ; Pass address of error message
	 call	 DISP_ERRLAST	; Display error message with last keyword
FCN_XMSHNDL_ERR:
	 stc			; Indicate something went wrong
FCN_XMSHNDL_EXIT:
	 REGREST <cx,ax>	; Restore

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FCN_XMSHNDL endp		; End FCN_XMSHNDL procedure
endif				; IF @OEM_XMS
	 NPPROC  DISPAZS -- Display AZS String With Attribute
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display AZS string with attribute.

On entry:

YGROUP:SI ==>	 string to display
BL	 =	 attribute to use

|

	 REGSAVE <ax,bx,cx,dx,si,ds> ; Save registers

	 mov	 ax,seg YGROUP	; Get segment of string to display
	 mov	 ds,ax		; Address it
	 assume  ds:YGROUP	; Tell the assembler about it

	 mov	 bh,0		; BH = display page #
	 VIDCALL @GETPOS	; Get cursor position into (DH,DL) from page BH
				; (CH,CL) is cursor type

	 mov	 cx,1		; # characters to write each time
	 mov	 bh,0		; BH = display page #
DISPAZS1:
	 lods	 YGROUP:[si].LO ; Get next byte

	 cmp	 al,0		; Izit the end?
	 je	 short DISPAZS2 ; Jump if so

	 VIDCALL @SETCAT	; Write character attribute at cursor
	 inc	 dl		; Skip to the next column
	 VIDCALL @SETPOS	; Set new cursor position

	 jmp	 short DISPAZS1 ; Go around again

DISPAZS2:
	 mov	 al,CR		; Reset to start of line
	 VIDCALL @SETTTY	; Write to screen

	 REGREST <ds,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISPAZS  endp			; End DISPAZS procedure

XCODE	 ends			; End XCODE segment

	 MEND			; End QMAX_FCN module
