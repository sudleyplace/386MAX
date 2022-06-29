;' $Header:   P:/PVCS/MAX/386LOAD/LOADCOM.ASV   1.2   30 May 1997 10:38:06   BOB  $
	 title	 LOADCOM -- Common Routines to DRVLOAD and TSRLOAD
	 page	 58,122
	 name	 LOADCOM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Program segment DATZ,	para-aligned,  public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NLSEG,	para-aligned,  public, class 'ndata'
	       Program segment NDATA,	dword-aligned, public, class 'ndata'
	       Program segment DTAIL,	para-aligned,  public, class 'zdata'
	       Program segment UCODE,	byte-aligned,  public, class 'ucode'
	       Data    segment UDATA,	dword-aligned, public, class 'udata'
	       Program segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Program derived from:  None.

Original code by:  Bob Smith, February 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include EMMCALL.INC
	 include ASCII.INC
	 include IOCTL.INC
	 include KEYCALL.INC
	 include VIDCALL.INC
	 include MAC.INC
	 include PTR.INC
	 include EXE.INC
	 include DIR.INC
	 include BITFLAGS.INC
	 include DEVMAC.INC
	 include OPEN.INC
	 include DEVDRV.INC
	 include OPCODES.INC
	 include EXEC.INC

	 include LOAD_OEM.INC
	 include QMAX_FMT.INC
	 include UTIL_USE.INC
.list

PGROUP	 group	 CODE,DATZ,NCODE,NLSEG,NDATA,DTAIL,UCODE,UDATA,ZZTAIL


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 OPT_FLAG:word
	 include LOAD_OPT.INC

CODE	 ends			; End CODE segment


DATZ	 segment para public 'data' ; Start DATZ segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 DISP_COPY:near
	 extrn	 INT_NPAR:word
	 extrn	 HSIZE_DELTA:word
	 extrn	 GETSIZE_RDELTA:word
	 extrn	 GETSIZE_IDELTA:word
	 extrn	 MIN_HOLE:word

	 public  START_DATZ
START_DATZ label byte

	 public  EXEC_PSP
EXEC_PSP dw	 ?		; Segment of PSP

	 public  CFGFLAGS, @CFG_TOPF, @CFG_PROTMAN, @CFG_PTOPF, @CFG_GSIZE
	 public  @CFG_CLOSELOW,@CFG_CLOSEHI,@CFG_DRVSPC
CFGFLAGS dw	 0		; CFGFILE flags
@CFG_WINST equ	 8000h		; I = Instance me
@CFG_ESAVE equ	 4000h		; E = ENVSAVE
@CFG_TOPF  equ	 2000h		; T = TOPFILL limit
@CFG_GSIZE equ	 1000h		; S = Forced GETSIZE value
@CFG_XHILOAD equ 0800h		; L = don't load high
@CFG_COMSTK equ  0400h		; C = treat as COM file for stack determination
@CFG_I12    equ  0200h		; D = Use top of region as INT 12h value
@CFG_HSIZED equ  0100h		; H[0] = High size +delta
@CFG_NORETRY equ 0080h		; N = NORETRY
@CFG_PROTMAN equ 0040h		; P = PROTMAN.DOS; reduce Int 12h by 64K
@CFG_GSIZED equ  0020h		; H1= GETSIZE deltas
@CFG_PTOPF  equ  (@CFG_PROTMAN or @CFG_TOPF) ; Flags to set when PROTMAN$ found
				; in a device header
@CFG_CLOSELOW equ 0010h 	; B1= Close low DOS when loading high
@CFG_CLOSEHI equ  0008h 	; B2= Close high DOS when loading device high
@CFG_DRVSPC  equ  0004h 	; B3= If GETSIZE, hook INT 2Fh/4A11/FFFC and lie

	 public  PATCHFLAGS
PATCHFLAGS dw	 0		; Patch(es) to apply:
@PATCH_MITSUMI	 equ	0001h	; F0: Kill test for CS >= A000 (Mitsumi)

if @OEM_FLEX
	 public  EMMDEV,OLDINT67_PATCH
EMMDEV	 db 'EMMXXXX0',0        ; Needed by UTIL_USE for IZITEMS, etc.
OLDINT67_PATCH dd ?		; Address of patch point in MAX/Move'EM

	 FPPROC  INT67 -- Local INT 67h Handler
	 assume  ds:nothing,es:nothing,ss:nothing

; Provide space to copy the original contents of CURINT67_VEC - 5 bytes
	 jmp	 short @F	; Short jump - 2 bytes

	 nop			; 3 bytes
	 nop			; 4 bytes
	 nop			; 5 bytes

@@:
@PATCHLEN equ	 $-INT67	; Number of bytes to patch

; Ensure it's an EMS (not VCPI) function

	 cmp	 ah,@EMM_GETSTAT ; Izit below lowest numbered EMS function?
	 jb	 short INT67_EXIT ; Jump if so

	 cmp	 ah,@EMM_OSE	; Izit above highest numbered EMS function?
	 ja	 short INT67_EXIT ; Jump if so

	 or	 cs:LCL_FLAG,@LCL_XFLEX ; Mark as INT 67h called
INT67_EXIT:

	 db	 @OPCOD_JMPF	; Opcode for far jump
	 public  OLDINT67_VEC
OLDINT67_VEC dd  ?		; Save area for old INT 67h handler

	 assume  ds:nothing,es:nothing,ss:nothing

INT67	 endp			; End INT67 procedure
endif				; IF @OEM_FLEX

DATZ	 ends			; End DATZ segment


NLSEG	 segment para public 'ndata' ; Start NLSEG segment
	 assume  ds:PGROUP

	 extrn	 LSEG:tbyte
	 include LOAD_SEG.INC

NLSEG	 ends			; End NLSEG segment


UDATA	 segment dword public 'udata' ; Start UDATA segment
	 assume  ds:PGROUP

if @OEM_FLEX
	 extrn	 AZS_UGHEMS:byte
	 extrn	 PAACNT:word
	 extrn	 PAAOFF:word
	 extrn	 TOTEMS:word
	 extrn	 NMAPS:word
	 extrn	 MAPTAB:tbyte
endif				; IF @OEM_FLEX

	 extrn	 COMPSIZE:dword

if @OEM_FLEX
	 public  PREVMAC
PREVMAC  dw	 ?		; Segment of previous MAC entry in REST_EMS
endif				; IF @OEM_FLEX

	 public  INVALID_FID
INVALID_FID db	 '\/"[]|<>+=:;,' ; List of invalid FID chars (00-20, also)
				; Note some of these chars are stripped off
				; before this variable is consulted
INVALID_FID_LEN equ $-INVALID_FID ; # invalid chars

	 public  ALTPATHSEP
ALTPATHSEP db	 '\'            ; Alternate path separator

	 public  NUMBERS_HI
NUMBERS_HI db	 '0123456789ABCDEF' ; Conversion table for BIN2HEX_SUB

	 public  CFGFILE,CFGLINE,CFGPATH
CFGFILE  db	 @OEM_LOAD,'.CFG',0 ; Filename.ext of configuration file
CFGFILE_LEN equ  $-CFGFILE	; Length of ...
CFGLINE  label	 byte		; Share with CFGPATH
CFGPATH  db	 80 dup (?)	; Save area for CFGFILE path
CFGLINE_LEN equ  $-CFGLINE	; Length of ...

if @OEM_FLEX

; Save area for EMS mapping state

	 public  EMSSAVE
EMSSAVE  db	 (2*64) dup (?) ; Room for 2 bytes for each of 64 EMS-mappable pages
endif				; IF @OEM_FLEX

UDATA	 ends			; End UDATA segment


NDATA	 segment dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 LCL_FLAG:word
	 include LOAD_LCL.INC

	 extrn	 AZS_PRESS:byte
	 extrn	 AZS_ERRMAC:byte
	 extrn	 AZS_UGHCHG:byte
	 extrn	 AZS_UGHCHG1:byte
	 extrn	 AZS_UGHCHG2:byte

	 extrn	 PFID_ROOM:dword
	 extrn	 FILE_HEAD:byte
	 extrn	 EXEC_PRGMAC:word
	 extrn	 EXEC_INTMAC:word
	 extrn	 LSEGSEG:word
	 extrn	 EXEC_BLK:dword
	 extrn	 EXEC_REL:word
	 extrn	 EXEC_LOD:word
	 extrn	 LCL_PATH:byte

	 extrn	 TOPFILL:word
	 extrn	 STKSIZE:dword

	 public  OLDINT23_VEC,OLDINT24_VEC
OLDINT23_VEC dd  ?		; Save area for old INT 23h handler
OLDINT24_VEC dd  ?		; ...			24h

	 public  EXEC_LODLO,EXE_NPAR
EXEC_LODLO dw	 ?		; Segment of low-order @EXEC load
EXE_NPAR dw	 -1		; # paras to allocate to EXE file

	 public  LC2_FLAG
	 include LOAD_LC2.INC
LC2_FLAG dw	 0		; Local flags, part 2

	 public  CON10
CON10	 dw	 10		; Constant dword 10

	 public  DOSVER
DOSVER	 dw	 ?		; DOS version # in comparison order

	 public  XDOSVER
XDOSVER  dw	 ?		; Use this when lying about the DOS version #
				; Note:  NOT in comparison order

	 public  DEV_HNDL
DEV_HNDL dw	 ?		; Device handle

if @OEM_FLEX
	 public  EMS_HNDL
EMS_HNDL dw	 -1		; EMS handle (-1 if not in use)
endif				; IF @OEM_FLEX

	 public  EES
EES	 EES_STR <>		; Enter Exec State structure for DOS 5.x

	 DEVMAC  @OEM_IOCTL	; Create @DEVNAME for IOCTL calls

	 public  BASNAME
BASNAME  db	 @DEVNAME,0	; Device driver name
	 org	 BASNAME+8+1	; To avoid phase error

	 public  PRGREG
PRGREG	 db	 -1		; Program region #

	 public  MSG_CRLF
MSG_CRLF db	 CR,LF,EOS

	 public  PROT_NAME
PROT_NAME db	 'PROTMAN$',0   ; Name of PROTMAN device

	 public  UMBSEGS
@MAXUMBSEGS equ  40		; Maximum UMBs
UMBSEGS dw	 @MAXUMBSEGS dup (0) ; List of UMB segments

	 public  F0MOD,F0MOD_OFF1,F0MOD_OFF2,F0MOD_JC
F0MOD	 label	 byte		; Code search model for F0 (MTMCDE.SYS)
	 db	 8Ch,0CBh	; MOV BX,CS
	 db	 03h,0C3h	; ADD AX,BX
	 db	 0A3h		; MOV ...,AX
F0MOD_OFF1 label word		; First offset
	 db	 @DCBYTE,@DCBYTE ; Ignore when searching
	 db	 81h,3Eh	; CMP WORD PTR ...,
F0MOD_OFF2 label word		; Second offset
	 db	 @DCBYTE,@DCBYTE ; Ignore when searching, but match with OFF1
	 dw	 0A000h 	; CMP ...,A000
F0MOD_JC db	 72h		; JC ...
@F0MOD_LEN equ	 $-F0MOD

NDATA	 ends			; End NDATA segment


DTAIL	 segment para public 'zdata' ; Start DTAIL segment
	 assume  ds:PGROUP

	 extrn	 INFO_CTL:byte
	 include QMAX_CTL.INC

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 LOADSEG:word
	 extrn	 INFOSIZE:abs
	 extrn	 POVR_MAC:word
	 extrn	 CURINT67_VEC:dword

DTAIL	 ends			; End DTAIL segment


ZZTAIL	 segment dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 extrn	 ZTAIL:byte

ZZTAIL	 ends			; End ZZTAIL segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

if @OEM_FLEX
	 extrn	 CHECK_EMSPTE:near
endif				; IF @OEM_FLEX

	 public  @DCBYTE
@DCBYTE  equ	 22h		; An unlikely machine instruction component

	 NPPROC  SEARCH_MODEL -- Search for code model, ignore @DCBYTE
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Compare code at ES:DI with model at PGROUP:SI for CX bytes, ignoring
any differences on @DCBYTE values in the model.

On entry:

ES:DI ==>	Start of code to search for
PGROUP:SI ==>	Model to compare it with
CX	=	Length of model
DX	=	Number of bytes to search in target

On exit:

If found,
ZF	=	1
ES:DI	==>	Next byte after actual code

If not found,
ZF	=	0
DI		Contents destroyed

|

	 REGSAVE <ax,bx,cx,dx,si> ; Save

	 inc	 dx		; Prepare to subtract CX-1
	 sub	 dx,cx		; Subtract model length - 1 from search space
				; so we have room to compare the model
	 jb	 short SMOD_EXIT ; Jump if model > search space (note ZF=0)

SM_SCAN:
	 cmp	 dx,1		; Is there any remaining search space?
	 jb	 short SMOD_EXIT ; Exit if not (note ZF=0)

	 mov	 al,PGROUP:[si].LO ; Get first byte in model
	 xchg	 dx,cx		; Save model length, get bytes to compare
  repne  scas	 es:[di].LO	; Find the first candidate
	 xchg	 dx,cx		; Restore model length
	 jne	 short SMOD_EXIT ; Jump if we crapped out (note ZF=0)

	 REGSAVE <cx,si,di>	; Save model start and length

	 dec	 cx		; Remaining bytes to compare
	 jz	 short SMOD_CMPMOD1 ; Jump if we matched a one-byte model
				; Note: ZF=1

	 inc	 si		; Address next byte to compare
SM_CMPMOD:
	 lods	 PGROUP:[si].LO ; Get next byte for comparison
	 cmp	 al,@DCBYTE	; Izit a don't care byte?
	 je	 short @F	; Jump if so (note ZF=1)

	 cmp	 al,es:[di].LO	; Compare a byte
@@:
	 lea	 di,[di+1]	; Skip to next compare byte (ZF unchanged)
	 loope	 SM_CMPMOD	; Go around again if no mismatch

	 mov	 ax,di		; Save pointer to next byte

SMOD_CMPMOD1:
	 REGREST <di,si,cx>	; Restore model start and length

	 jne	 short SM_SCAN	; Go around again if not matched

; Note ZF=1
	 mov	 di,ax		; Return address of next byte

SMOD_EXIT:
	 REGREST <si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SEARCH_MODEL endp		; End SEARCH_MODEL procedure
	 NPPROC  CHECK_PATCH -- Patch code at EXEC_LOD
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Some programs just won't behave when loaded high.  Mitsumi's CD-ROM
driver is a good example.  We need to seek and destroy the code that
checks for CS >= A000.

|

	 REGSAVE <cx,dx,si,di,es> ; Save

	 mov	 es,EXEC_LOD	; Address segment of loaded program
	 assume  es:nothing	; Tell the assembler

	 test	 PATCHFLAGS,@PATCH_MITSUMI ; Izit MTMCDE.SYS?
	 jz	 short CPAT_XMITSUMI ; Jump if not

; Find the code that compares CS with A000 and force the compare to fail.
	 sub	 di,di		; ES:DI ==> Code to search
	 lea	 si,PGROUP:F0MOD ; PGROUP:SI ==> Model to look for
	 mov	 cx,@F0MOD_LEN	; Bytes to compare
	 mov	 dx,5000h	; How far to go in code
	 call	 SEARCH_MODEL	; ZF=1 if found, ES:DI ==> next byte
	 jne	 short CPAT_XMITSUMI ; Jump if not found

; Make sure the offsets match.
@F0MOD_OFF1 equ  (offset PGROUP:F0MOD_OFF1)-(offset PGROUP:F0MOD)
@F0MOD_OFF2 equ  (offset PGROUP:F0MOD_OFF2)-(offset PGROUP:F0MOD)
@F0MOD_JC equ	 (offset PGROUP:F0MOD_JC)-(offset PGROUP:F0MOD)

	 sub	 di,cx		; Back off to start of model
	 mov	 ax,es:[di+@F0MOD_OFF1].ELO ; Get first offset
	 cmp	 ax,es:[di+@F0MOD_OFF2].ELO ; Does it match second offset?
	 jne	 short CPAT_XMITSUMI ; Jump if not

	 mov	 es:[di+@F0MOD_JC].LO,@OPCOD_JMPS ; Make the jump unconditional
CPAT_XMITSUMI:
CPAT_EXIT:
	 REGREST <es,di,si,dx,cx> ; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_PATCH endp		; End CHECK_PATCH procedure

	 NPPROC  TOPFILL_CHECK -- Check for the reasons to lower TOPFILL
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Check for the reasons to lower TOPFILL:

1) IOCTL driver PROTMAN$ exists.  Get Int 12h value and lower by 128K.

2) Int FDh points to device header for PROTMAN$.  Same action as #1.

3) Int F1h's vector contains the text 'NetW'.  Get end of largest
available block and lower by 64K.

In cases 1 and 2, lower by an additional 64K if running DOS 5.

|
	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save what we are going to use

	 test	 CFGFLAGS,@CFG_TOPF ; Was TOPFILL specified in CFG file?
	MJ nz	 TFC_EXIT	; Jump if so (skip PROTMAN$ check)

	 mov	 al,01h 	; Access code for read
	 DOSCALL @OPENF2,PROT_NAME ; Attempt to open device driver
	 jnc	 short TFC_PROT1 ; Jump if open succeeded

; LANMAN remote boot- this is a four-letter word.  PROTMAN's there, but
; DOS doesn't know about it.  However, the Int FD vector points to a
; PROTMAN$ device header...
	 sub	 ax,ax		; Vector of IVT
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 les	 di,es:[0FDh*4].EDD ; Get suspected PROTMAN$ header address
	 assume  es:nothing	; Tell the assembler

	 int	 12h		; Get RAM size in AX
	 mov	 cl,10-4	; K to para conversion factor
	 shl	 ax,cl		; Convert to paragraphs
	 mov	 bx,es		; Get PROTMAN$ address
	 cmp	 bx,ax		; Izit above the top of DOS?
	MJ b	 TFC_EXIT	; Jump if not

	 mov	 cx,8		; Bytes to compare
	 lea	 di,[di].DD_NAME ; Address device name
	 lea	 si,PROT_NAME	; 'PROTMAN$'
   repe  cmps	 PROT_NAME,es:[di].DD_NAME ; Compare 'em
	 je	 short TFC_PROTMAN ; You can run but you can't hide...

; Check for NetW in interrupt F1 vector
	 sub	 ax,ax		; Vector of IVT
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 cmp	 es:[0F1h*4].ELO,'eN' ; Does low word compare?
	MJ ne	 TFC_EXIT	; Jump if not

	 cmp	 es:[0F1h*4].EHI,'Wt' ; Does high word compare?
	MJ ne	 TFC_EXIT	; Jump if not

; Netware remote boot loaders allocate 64K at the top of DOS, so
; COMMAND.COM will load below it.
	 mov	 bx,-1		; Allocate all of low DOS
	 DOSCALL @GETMEM	; Return largest block in BX
	 DOSCALL @GETMEM	; AX = segment of largest block

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 DOSCALL @RELMEM	; Release block

	 mov	 ax,es		; Get segment
	 dec	 ax		; Back off to MAC entry
	 mov	 es,ax		; Address MAC entry
	 assume  es:nothing	; Tell the assembler

	 add	 ax,es:[0].MAC_NPAR ; Skip to end of region - 1 para
	 sub	 ax,(1000h-1)	; Back off by 64K - 1 para
	 jmp	 short TFC_REDUCE ; Join common code

TFC_PROT1:
	 mov	 bx,ax		; Copy to handle register

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 pushf			; Save status
	 DOSCALL @CLOSF2	; Close the device driver
	 popf			; Restore status
	 jc	 short TFC_EXIT ; Something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 short TFC_EXIT ; Nope, go

TFC_PROTMAN:
	 int	 12h		; Get RAM size in AX
	 mov	 cl,10-4	; K to para conversion factor
	 shl	 ax,cl		; Convert to paragraphs

; If it's a newer PROTMAN and we're loading an end-loader like NET START,
; we don't need to reduce TOPFILL at all.  Check for
; 1. A MAC entry above the memory allocated to us,
; 2. with an owner of 0008h,
; 3. with a size of at least 32K,
; 4. and ending below the Int 12h top of DOS.
; If we find such a beast, leave TOPFILL alone.
	 test	 LCL_FLAG,@LCL_TSR ; Izit TSRLOAD?
	 jz	 short TFC_PROTMAN2 ; Jump if not

	 mov	 bx,cs		; Get our PSP
	 dec	 bx		; Back off to our MAC entry
	 mov	 es,bx		; Address it
	 assume  es:nothing	; Tell the assembler

	 cmp	 bx,ax		; Are we in low DOS?
	 jnb	 short TFC_PROTMAN2 ; Jump if not

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit the last entry?
	 je	 short TFC_PROTMAN2 ; Jump if so

	 add	 bx,es:[0].MAC_NPAR ; Skip our memory
	 inc	 bx		; Skip MAC entry
	 mov	 es,bx		; Address next MAC
	 assume  es:nothing	; Tell the assembler

	 add	 bx,es:[0].MAC_NPAR ; Skip PROTMAN's (alleged) allocation
	 inc	 bx		; Skip MAC entry
	 cmp	 bx,ax		; Does it end at or below the top of low DOS?
	 ja	 short TFC_PROTMAN2 ; Jump if not

	 cmp	 es:[0].MAC_OWNR,0008h ; Izit PROTMAN's magic owner value?
	 jne	 short TFC_PROTMAN2 ; Jump if not

	 cmp	 es:[0].MAC_NPAR,0800h ; Izit at least 32K in length?
	 jnb	 short TFC_EXIT ; Jump if so - PROTMAN is (probably) protected

TFC_PROTMAN2:
	 cmp	 DOSVER,0500h	; Izit DOS 5.00?
	 jb	 short TFC_REDUCE ; No

	 UMIN	 ax,TOPFILL	; If TOPFILL is already reduced, use the
				; request header input value.
	 UMIN	 ax,8000h	; Make sure it's <= 6000h below
TFC_REDUCE:
	 sub	 ax,02000h	; Maximum top fill value for LanMan 2.0

	 UMIN	 TOPFILL,ax	; Set New TOPFILL value if lower
TFC_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore used
	 assume  es:nothing	; Tell the assembler

	 ret

	 assume  ds:nothing,es:nothing,ss:nothing

TOPFILL_CHECK endp		; End TOPFILL_CHECK procedure
	 NPPROC  SKIP_WHITE -- Skip Over White Space
	 assume  ds:nothing,es:nothing,ss:nothing

	 lodsb			; Get next character

	 cmp	 al,' '         ; Check for blanks
	 je	 short SKIP_WHITE ; Go around again

	 cmp	 al,TAB 	; Check for tabs
	 je	 short SKIP_WHITE ; Go around again

	 dec	 si		; Back off to non-white character

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
	 NPPROC  MAC_MERGE -- Merge Adjacent Free MACs
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Merge adjacent feee MACs starting at ES:0.

On entry:

ES:0	 ==>	 first MAC in chain for search

On exit:

CF	 =	 0 if all went OK
	 =	 1 if something went wrong

|

MERGE_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
MERGE_SEG dw	 ?		; Starting segment

MERGE_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,cx,dx,si,ds,es> ; Save registers

	 mov	 es,[bp].MERGE_SEG ; Get starting segment
	 assume  es:nothing	; Tell the assembler about it

	 xor	 dx,dx		; Mark as no previous MAC entry as yet
MAC_MERGE_NEXT:
	 mov	 cx,1		; Set flag to load DS:SI from old ES:0

	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Izit free?
	 jne	 short MAC_MERGE_CHK ; Not this time

	 and	 dx,dx		; Is there a previous MAC entry as yet?
	 jz	 short MAC_MERGE_CHK ; No, hence no marge

	 cmp	 ds:[si].MAC_OWNR,@MAC_FREE ; Is the previous entry free?
	 jne	 short MAC_MERGE_CHK ; No, hence no merge

	 mov	 ax,es:[0].MAC_NPAR ; Get # paragraphs in freed MAC entry
	 inc	 ax		; Account for MAC paragraph
	 add	 ds:[si].MAC_NPAR,ax ; Merge into previous MAC entry
	 mov	 al,es:[0].MAC_TYPE ; Get the MAC type
	 mov	 ds:[si].MAC_TYPE,al ; Save as new type

	 xor	 cx,cx		; Set flag to skip load of DS:SI
MAC_MERGE_CHK:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit the end of the MAC entries?
	 je	 short MAC_MERGE_EXIT ; Yes, note CF=0

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Ensure valid
	 jne	 short MAC_MERGE_ERRMAC ; Not this time

; Save ES:0 as pointer to previous MAC entry unless we merged the last one

	 jcxz	 MAC_MERGE_CHK1 ; Jump if we freed the last MAC entry

	 push	 es		; Copy current segment
	 pop	 ds		; ...as old one
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; DS:SI ==> previous MAC entry
	 mov	 dx,1		; Mark as previous MAC entry in DS:SI
MAC_MERGE_CHK1:
	 mov	 ax,es		; Get current MAC segment
	 inc	 ax		; Account for MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 short MAC_MERGE_NEXT ; Go around again

MAC_MERGE_ERRMAC:
	 stc			; Indicate something went wrong
MAC_MERGE_EXIT:
	 REGREST <es,ds,si,dx,cx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,ss:nothing

MAC_MERGE endp			; End MAC_MERGE procedure

NCODE	 ends			; End NCODE segment


UCODE	 segment byte public 'ucode' ; Start UCODE segment
	 assume  cs:PGROUP

	 extrn	 DD2DEC:near
if @OEM_FLEX
	 extrn	 SET_MAPTAB:near
	 extrn	 IZITEMS:far
endif				; IF @OEM_FLEX

if @OEM_FLEX
	 NPPROC  INST67 -- Install INT 67h Handler If Appropriate
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Install INT 67h handler if appropriate.  Note that we get the entry
point to the Int 67 handler in MAX or Move'EM, and patch ourselves
in directly using the 5 bytes set aside for this purpose.  We do
NOT support programs which try to insert themselves into the Int 67
chain in this way; we can do it because MAX is ours to fiddle with.

|

	 REGSAVE <ax,cx,si,di,ds,es> ; Save registers

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jz	 short INST67_EXIT ; Jump if not

	 FCALL	 IZITEMS	; Is an EMS handler installed and ready?
	 jnc	 short INST67_EXIT ; Jump if not

; Thanks to programs which save the Int 67 vector then request EMS services
; via pushf/far call, we need to patch ourselves into MAX's Int 67 handler.
	 push	 ds		; Get PGROUP segment
	 pop	 es		; Address for MOVSB
	 assume  es:PGROUP	; Tell the assembler

	 lds	 si,CURINT67_VEC ; DS:SI ==> MAX/Move'EM entry point
	 assume  ds:nothing	; Tell the assembler

	 mov	 OLDINT67_PATCH.VOFF,si ; Save offset of patch point
	 mov	 OLDINT67_PATCH.VSEG,ds ; Save segment

	 pushf			; Save

	 cli			; Nobody move

; Copy @PATCHLEN bytes to INT67.  This is what we'll restore later
	 mov	 cx,@PATCHLEN	; Number of bytes in patch
	 lea	 di,INT67	; Copy original patch contents to local handler
	 cld			; Ensure string ops go forward
   rep	 movs	 PGROUP:INT67[di].LO,ds:[si].LO ; Move it

; Save offset of byte after patch bytes in MAX.  This is what we'll jump
; to for the previous handler.
	 mov	 OLDINT67_VEC.VOFF,si ; Save offset of entry point
	 mov	 OLDINT67_VEC.VSEG,ds ; Save segment

; Back off to the patch and blast in a far jump immediate to our handler
	 sub	 si,@PATCHLEN	; DS:SI ==> CURINT67_VEC
	 mov	 ds:[si].LO,@OPCOD_JMPF ; Far jump immediate
	 mov	 ds:[si+1].VOFF,offset PGROUP:INT67 ; Offset for jump
	 mov	 ds:[si+1].VSEG,cs ; Segment

	 popf			; Restore previous state of IF

	 or	 LCL_FLAG,@LCL_IN67 ; Mark as installed
INST67_EXIT:
	 REGREST <es,ds,di,si,cx,ax> ; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INST67	 endp			; End INST67 procedure
endif				; IF @OEM_FLEX
if @OEM_FLEX
	 NPPROC  INST_EMS -- Allocate EMS Memory If Requested
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Allocate EMS memory if requested (FLEXFRAME) and not GETSIZE.

The presence of a -1 in EMS_HNDL indicates whether or not
EMS pages have been mapped in and MAC entries adjusted.

If enabling FLEXFRAME, we ask MAX/Move'EM to temporarily
fail all EMS calls.

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

	 test	 LSEG.LSEG_FLAG,@LSEG_FLEX ; Is FLEXFRAME specified?
	MJ z	 INST_EMS_EXIT	; Jump if not

	 test	 LC2_FLAG,@LC2_IGNFLEX ; Is IGNOREFLEXFRAME in effect?
	MJ nz	 INST_EMS_EXIT	; Jump if so

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	MJ nz	 INST_EMS_EXIT	; Jump if so

	 call	 SET_MAPTAB	; Setup the MAPTAB table
	MJ c	 INST_EMS_ERR0	; Jump if something went wrong

	 mov	 bx,TOTEMS	; Get total EMS size needed (in paras)
	 mov	 cl,14-4	; Shift amount between paras and 16KB
	 shr	 bx,cl		; Convert from paras to 16KB
	MJ z	 INST_EMS_EXIT	; Jump if none needed (no pages)

; Request EMS memory

	 EMMCALL @EMM_SETPAGE	; Request allocation of BX pages

	 cmp	 ah,0		; Check for error
	MJ ne	 INST_EMS_ERR	; Jump if something went wrong

	 mov	 EMS_HNDL,dx	; Save for later use

; Save the existing EMS mapping

	 push	 ds		; Get our data segment for Get/set Page Map
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,EMSSAVE	; ES:DI ==> save area for EMS page map
	 mov	 al,0		; Function to save page map into ES:DI
	 EMMCALL @EMM_PAGEMAP	; Request save of EMS page map into ES:DI

	 cmp	 ah,0		; Izit in error?
	 jne	 short INST_EMS_ERR0 ; Jump if so

; Map logical pages into the mappable physical EMS pages

	 mov	 si,PAAOFF	; DS:SI ==> PAA_STR structure
	 mov	 cx,PAACNT	; CX = # entries
	 jcxz	 INST_EMS_ERR0	; Jump if none
	 mov	 bx,0		; First logical page #
INST_EMS_NEXT1:

; Find the next mappable physical EMS page

	 cmp	 ds:[si].PAA_SEG,-1 ; Check the segment
	 je	 short INST_EMS_LOOP1 ; Jump if it's been deleted

	 mov	 al,ds:[si].PAA_PPN ; Get the physical page #
	 EMMCALL @EMM_MAPHNPG	; Map it in

	 cmp	 ah,0		; Check for error
	MJ ne	 INST_EMS_ERR	; Jump if so

	 inc	 bx		; Skip to next logical page
INST_EMS_LOOP1:
	 add	 si,type PAA_STR ; Skip to next entry

	 loop	 INST_EMS_NEXT1 ; Jump if more entries to check

; Modify the MAC entries contiguous with EMS-mappable pages
; to encompass them unless less than RPAR2

	 mov	 ax,POVR_MAC	; Get segment of first MAC in high DOS memory
	 mov	 dx,LSEG.LSEG_RPAR2 ; Get forced resident size in paras (if any)
INST_EMS_NEXT2:
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 add	 ax,es:[0].MAC_NPAR ; Plus # paras in this entry

; If this is the last MAC entry, don't count in the MAC para
; so AX will point to just below the EMS mappable page (if any)

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Are we at the end?
	 je	 short @F	; Jump if so

	 inc	 ax		; Count in the MAC paragraph
@@:

	 cmp	 dx,es:[0].MAC_NPAR ; Will forced resident size fit?
	 ja	 short INST_EMS_LOOP2 ; Jump if not

; If it appears to fit, but
;	1) the size of the adjacent MAC entry is 0 or
;	2) the adjacent MAC entry is not free
; we ignore the possibility of FLEXFRAME, since there's nowhere for
; the program to go resident.  Note that we might have a 0-length
; MAC entry depending on how the region got filled up.
	 cmp	 es:[0].MAC_NPAR,0 ; Is the MAC entry empty?
	 je	 short INST_EMS_LOOP2 ; Jump if so

	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Izit available?
	 jne	 short INST_EMS_LOOP2 ; Jump if not

; Search for AX in the MAPTAB table

	 mov	 cx,NMAPS	; Get # active entries in table
	 xor	 bx,bx		; Zero index into MAPTAB
@@:
	 cmp	 ax,MAPTAB.MAP_SEG[bx]	; Check for a match
	 je	 short INST_EMS_FND ; Jump if so

	 add	 bx,type MAP_STR ; Skip to next MAPTAB entry

	 loop	 @B		; Jump if more MAPTAB entries
INST_EMS_LOOP2:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Are we at the end?
	 jne	 short INST_EMS_NEXT2 ; Jump if not

	 jmp	 short INST_EMS_EXIT ; Jump we're done

INST_EMS_ERR0:
	 jmp	 short INST_EMS_ERR ; Join common error code


; Include the MAPTAB.MAP_LEN[bx] paras into es:[0].MAC_NPAR
; unless

INST_EMS_FND:
	 mov	 cx,MAPTAB.MAP_LEN[bx]	; Get # paras
	 add	 es:[0].MAC_NPAR,cx ; Add # paras into base entry

; Setup a new MAC entry at the top of the new region
; unless we're at the end

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Are we at the end?
	 je	 short INST_EMS_EXIT ; Jump if so

	 REGSAVE <ds,es>	; Save for a moment

	 mov	 ds,ax		; Address the old MAC entry
	 assume  ds:nothing	; Tell the assembler about it

	 sub	 ds:[0].MAC_NPAR,cx ; Subtract # paras from old entry

	 mov	 ax,es		; Copy base segment
	 add	 ax,es:[0].MAC_NPAR ; Plus # paras in base entry
	 inc	 ax		; Count in the MAC paragraph

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 si,si		; DS:SI ==> old MAC entry
	 xor	 di,di		; ES:DI ==> new MAC entry
	 mov	 cx,size MAC_STR ; CX = # bytes in MAC entry structure
     rep movsb			; Copy to new location

	 REGREST <es,ds>	; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 jmp	 short INST_EMS_NEXT2 ; Go around again

INST_EMS_ERR:
	 and	 LSEG.LSEG_FLAG,not @LSEG_FLEX ; Clear FLEXFRAME state
	 or	 LSEG.LSEG_FLAG,@LSEG_XEMS ; Mark as EMS error during FLEXFRAME

	 mov	 dx,EMS_HNDL	; Get EMS handle # (if allocated)

	 cmp	 dx,-1		; Izit allocated?
	 je	 short INST_EMS_EXIT ; Jump if not

	 EMMCALL @EMM_RLSPAGE	; Release EMS pages for handle DX
	 mov	 EMS_HNDL,-1	; Mark as not allocated
INST_EMS_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax>  ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INST_EMS endp			; End INST_EMS procedure
endif				; IF @OEM_FLEX
if @OEM_FLEX
	 NPPROC  REST_EMS -- De-allocate Any EMS Memory
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

De-allocate any EMS memory

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

	 cmp	 EMS_HNDL,-1	; Izit allocated?
	MJ e	 REST_EMS_EXIT	; Jump if not

; Ensure MAC entries merged

	 push	 POVR_MAC	; Get segment of first MAC in high DOS memory
	 call	 MAC_MERGE	; Merge adjacent free MACs
	MJ c	 REST_EMS_ERRMAC ; Jump if there's a problem

; Modify the MAC entries contiguous with the mappable physical EMS pages
; to exclude it.
; Also, check for allocated memory in an EMS page
; and turn belly up if found

	 mov	 ax,POVR_MAC	; Get segment of first MAC in high DOS memory
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it
REST_EMS_NEXT:
	 mov	 PREVMAC,es	; Save segment of previous MAC

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it
REST_EMS_NEXT1:
	 add	 ax,es:[0].MAC_NPAR ; Plus # paras in this entry

; If this is the last MAC entry, don't count in the MAC para
; so AX will point to just below the EMS mappable page (if any)

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Are we at the end?
	 je	 short @F	; Jump if so

	 inc	 ax		; Count in the MAC paragraph
@@:

; Search for AX in the MAPTAB table

	 mov	 cx,NMAPS	; Get # active entries in table
	 xor	 bx,bx		; Zero index into MAPTAB
@@:
	 cmp	 ax,MAPTAB.MAP_END[bx] ; Check for a match
	 je	 short REST_EMS_FND ; Jump if so

	 add	 bx,type MAP_STR ; Skip to next MAPTAB entry

	 loop	 @B		; Jump if more MAPTAB entries

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Are we at the end?
	 jne	 short REST_EMS_NEXT ; Jump if not

	 jmp	 REST_EMS_RLS	; Join common release code

; The MAC entry at ES:0 ends at the top of a FLEXFRAME EMS page
; Ensure that MAC entry is free and has no more than
; MAPTAB.MAP_LEN[bx] paras

REST_EMS_FND:

; Either this MAC entry is free

	 mov	 ax,es		; Copy base segment in case we return
				; to REST_EMS_NEXT1 or error to REST_EMS_ERR1

	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Ensure it's free
	MJ ne	 REST_EMS_ERR	; Jump if not

; Ensure there's enough paras in the MAC entry

	 mov	 cx,MAPTAB.MAP_LEN[bx] ; Get # paras

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Are we at the end?
	 je	 short @F	; Jump if so

	 dec	 cx		; Count out the MAC paragraph at top of frame
@@:
	 cmp	 es:[0].MAC_NPAR,cx ; Check # paras in MAC against FLEX size
	 jae	 short REST_EMS_FIT ; Jump if enough

; See if this MAC entry starts at the beginning of the EMS page frame and
; it's the last one in memory, in which case we can eliminate it altogether.
; Note AX = ES for REST_EMS_ERR1

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Are we at the end?
	 jne	 short REST_EMS_ERR1 ; Jump if not

	 dec	 cx		; Back off to previous para

	 cmp	 es:[0].MAC_NPAR,cx ; Check # paras in MAC against FLEX size
	 jne	 short REST_EMS_ERR1 ; Jump if not on the boundary

	 mov	 es,PREVMAC	; Get the segment of the previous MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[0].MAC_TYPE,@MAC_END ; Mark as ending MAC entry

	 jmp	 REST_EMS_RLS	; Join common release EMS memory code

REST_EMS_FIT:

; See if we actually used FLEX memory
; This is the case if
;     EXEC_PRGMAC <= ES
; and EXEC_PRGMAC + ISIZE > (MAP_END - MAP_LEN)

	 mov	 ax,es		; Copy segment of MAC entry

	 cmp	 ax,EXEC_PRGMAC ; Izit above start of program?
	 jb	 short REST_EMS_FIT1 ; Jump if not

	 mov	 ax,LSEG.LSEG_ISIZE.ELO ; Get initialization size
	 mov	 dx,LSEG.LSEG_ISIZE.EHI ; ...
	 call	 BYT2PAR	; Convert (DX,AX) in bytes to AX in paras
				; rounding down
	 add	 ax,EXEC_PRGMAC ; Plus program MAC segment

	 mov	 dx,MAPTAB.MAP_END[bx] ; Get ending segment
	 sub	 dx,MAPTAB.MAP_LEN[bx] ; Less its length in paras

; Check ending segment of program against
; starting segment of EMS-mappable page

	 cmp	 ax,dx		; Check 'em
	 jbe	 short REST_EMS_FIT1 ; Jump if not used

	 or	 LSEG.LSEG_FLAG,@LSEG_INFLEX ; Mark as FLEXFRAME used
REST_EMS_FIT1:
	 mov	 ax,MAPTAB.MAP_LEN[bx] ; Get # paras
	 sub	 es:[0].MAC_NPAR,ax ; Subtract # paras from base entry

; Setup a new MAC entry at the bottom of the old region
; unless we're at the end

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Are we at the end?
	 je	 short REST_EMS_RLS ; Jump if so to release EMS memory

	 REGSAVE <ds>		; Save for a moment

	 mov	 ds,MAPTAB.MAP_END[bx] ; Address the old MAC entry at top of EMS
	 assume  ds:nothing	; Tell the assembler about it

	 add	 ds:[0].MAC_NPAR,ax ; Add # unusable paras into old entry

	 mov	 ax,es		; Copy base segment
	 add	 ax,es:[0].MAC_NPAR ; Plus # paras in base entry
	 inc	 ax		; Count in the MAC paragraph

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 si,si		; DS:SI ==> old MAC entry at top of EMS page
	 xor	 di,di		; ES:DI ==> new MAC entry
	 mov	 cx,size MAC_STR ; CX = # bytes in MAC entry structure
     rep movsb			; Copy to new location

	 REGREST <ds>		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 jmp	 REST_EMS_NEXT1 ; Go around again

COMMENT|

Enter at the first label if the entry is not free and thus
we need to include its paras

Enter at the second label if the entry is free and thus
we stop at the base MAC entry

|

REST_EMS_ERR:
	 add	 ax,es:[0].MAC_NPAR ; Plus # paras in base entry
	 inc	 ax		; Count in the MAC para
REST_EMS_ERR1:
	 sub	 ax,EXEC_INTMAC ; Less interrupt handler MAC segment
				; thus including its MAC para
	 dec	 ax		; Count out the program MAC para

	 push	 ds		; Setup ES for FMT_CHG
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 bx,AZS_UGHEMS	; Tell 'em the very bad news
	 push	 bx		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 call	 FMT_CHG	; Format the change line for "SIZE=nnn,nnn" w/AX
REST_EMS_WAIT:
	 call	 WAITFF 	; Wait until hell freezes over
				; (or the user presses Alt-255)
	 jmp	 short REST_EMS_EXIT ; Join common exit code


REST_EMS_ERRMAC:
	 lea	 ax,AZS_ERRMAC	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 jmp	 short REST_EMS_WAIT ; Join common wait code

; Restore the saved EMS mapping state

REST_EMS_RLS:
	 lea	 si,EMSSAVE	; DS:SI ==> save area for EMS page map
	 mov	 al,1		; Function to restore page map from DS:SI
	 EMMCALL @EMM_PAGEMAP	; Request restore of EMS page map from DS:SI

;;;;;;;; cmp	 ah,0		; Izit in error?
;;;;;;;; jne	 short REST_EMS_END ; Jump if so

; Release the EMS memory we allocated

	 mov	 dx,EMS_HNDL	; Get the EMS handle (if any)
	 EMMCALL @EMM_RLSPAGE	; Release EMS pages allocated to handle DX

;;;;;;;; cmp	 ah,0		; Check for error
;;;;;;;; je	 short @F	; Jump if no error
;;;;;;;;
;;;;;;;; lea	 di,AZS_UGHEMSERR1 ; ES:DI ==> output save area
;;;;;;;; mov	 al,ah		; Copy to DB2HEX input register
;;;;;;;; call	 DB2HEX 	; Convert AL to hex at ES:DI
;;;;;;;;
;;;;;;;; lea	 ax,AZS_UGHEMSERR ; Tell 'em the very bad news
;;;;;;;; push	 ax		; Pass message offset
;;;;;;;; call	 DISP_ERRMSG	; Display an error message
;;;@@:
REST_EMS_END:
	 mov	 EMS_HNDL,-1	; Mark as unallocated
REST_EMS_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REST_EMS endp			; End REST_EMS procedure
endif				; IF @OEM_FLEX
	 NPPROC  FMT_CHG -- Format Change Line
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Format the change line for "SIZE=nnn,nnn"

On entry:

AX	 =	 # paras in resident size

|

	 REGSAVE <ax,cx,dx,di>	; Save registers

	 push	 ax		; Save for a moment

	 mov	 ax,LSEG.LSEG_ASIZE.ELO ; Get low-order word of actual SIZE=
	 mov	 dx,LSEG.LSEG_ASIZE.EHI ; ... high-...

	 lea	 di,AZS_UGHCHG1 ; ES:DI ==> save area
	 mov	 cx,@DEC_LEFT	; Mark as left-justified
	 push	 cx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal at ES:DI
				; returning with ES:DI ==> next available byte

	 mov	 al,','         ; Get separator
	 stosb			; Save in message

	 pop	 ax		; Restore

	 call	 PAR2BYT	; Convert AX in paras to (DX,AX) in bytes

	 mov	 cx,@DEC_LEFT	; Mark as left-justified
	 push	 cx		; Pass as argument
	 call	 DD2DEC 	; Convert (DX,AX) to decimal at ES:DI
				; returning with ES:DI ==> next available byte

	 mov	 al,0		; Get terminator
	 stosb			; Save in message

	 lea	 ax,AZS_UGHCHG	; Tell 'em the very bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 lea	 ax,AZS_UGHCHG2 ; Tell 'em the very bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 REGREST <di,dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FMT_CHG  endp			; End FMT_CHG procedure
	 NPPROC  WAITFF -- Wait for FF
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Wait until hell freezes over or the user presses Alt-255.

|

	 REGSAVE <ax>		; Save register
@@:
	 call	 KEYWAIT	; Wait for an acknowledgement
				; Return with key in AX

	 cmp	 ax,00FFh	; Wait for Alt-255
	 jne	 short @B	; We go no further until then

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

WAITFF	 endp			; End WAITFF procedure
	 NPPROC  SKIP_FID -- Skip Over File Id Characters
	 assume  ds:nothing,es:PGROUP,ss:nothing
COMMENT|

Skip over d:\path\filename.ext

On entry:

DS:SI	 ==>	 start of FID

On exit:

AL	 =	 character after FID
DS:SI	 ==>	 next character after FID
DS:BX	 ==>	 "filename.ext"

@LCL_EXT set if extension present

|

	 REGSAVE <cx,di>	; Save registers

	 and	 LCL_FLAG,not @LCL_EXT ; Start with no extension

	 mov	 bx,si		; Initialize start of "filename.ext"
SKIP_FID_NEXT:
	 lodsb			; Get next character

	 cmp	 al,20h 	; Check for invalid range of 00-20
	 jbe	 short SKIP_FID_EXIT ; It's invalid, skip out

	 cmp	 al,'.'         ; Check for extension
	 je	 short SKIP_FID_EXT ; It's a match

	 cmp	 al,':'         ; Check for drive separator
	 je	 short SKIP_FID_NAME ; It's a match

	 cmp	 al,'\'         ; Check for path separator
	 je	 short SKIP_FID_XEXT ; It's a match

	 cmp	 al,ALTPATHSEP	; Check for alternate path separator
	 jne	 short SKIP_FID_SCAN ; Join common scan code
SKIP_FID_XEXT:
	 and	 LCL_FLAG,not @LCL_EXT ; There's no extension
SKIP_FID_NAME:
	 mov	 bx,si		; Point to following character

	 jmp	 short SKIP_FID_NEXT ; Join common code

SKIP_FID_EXT:
	 or	 LCL_FLAG,@LCL_EXT ; Mark as extension present

	 jmp	 short SKIP_FID_NEXT ; Join common code

SKIP_FID_SCAN:
	 lea	 di,INVALID_FID ; ES:DI ==> invalid FID chars
	 mov	 cx,INVALID_FID_LEN ; CX = # invalid FID characters
   repne scasb			; Look for it
	 jne	 short SKIP_FID_NEXT ; Not found, so it's valid -- go around again
SKIP_FID_EXIT:
	 dec	 si		; Back off to last char

	 REGREST <di,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SKIP_FID endp			; End SKIP_FID procedure
	 NPPROC  SAVE_2324 -- Save INTs 23h and 24h
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Save INTs 23h and 24h and install our own handler.

|

	 REGSAVE <ax,bx,ds,es>	; Save for a moment

	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 al,23h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old handler
	 assume  es:nothing	; Tell the assembler about it
	 mov	 OLDINT23_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT23_VEC.VSEG,es

	 DOSCALL @SETINT,INT23	; Install our own handler

	 mov	 al,24h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old handler
	 assume  es:nothing	; Tell the assembler about it
	 mov	 OLDINT24_VEC.VOFF,bx ; Save for later use
	 mov	 OLDINT24_VEC.VSEG,es

	 DOSCALL @SETINT,INT24	; Install our own handler

	 REGREST <es,ds,bx,ax>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SAVE_2324 endp			; End SAVE_2324 procedure
	 NPPROC  CHECK_MEM -- Check High DOS Memory
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check high DOS memory.

;;; We've just loaded a program up there via @EXEC and are wondering if
;;; it got up there correctly.	In particular, it might not if we're
;;; dealing with a SCSI bus master.

Correction:  The program didn't load up there because of FLEXFRAME
and disk caches.  Load it up there now.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 push	 EXEC_REL	; Save old relo point
	 push	 EXEC_LOD	; Save old load point

RELOTAB  equ	 ZTAIL[0]	; Location of relocation table
@RELOSIZ equ	 200		; # bytes in relocation table (must be /4)

	 lea	 ax,ZTAIL[(16-1)+@RELOSIZ] ; Get address of next available byte
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 ax,cl		; Convert from bytes to paras

	 mov	 bx,cs		; Copy current segment
	 add	 bx,ax		; Add to skip over our code/data
	 mov	 EXEC_LOD,bx	; Save for @EXEC use
	 mov	 EXEC_REL,bx	; Save for @EXEC use
	 mov	 EXEC_LODLO,bx	; Save for later use

	 lea	 bx,EXEC_BLK	; ES:BX ==> EXEC call parameter block
	 mov	 al,03h 	; Code to load but not execute
	 DOSCALL @EXEC,LCL_PATH ; Load into high DOS memory
	 pop	 EXEC_LOD	; Restore
	 pop	 EXEC_REL	; Restore
	 jc	 short CHECK_MEM_EXIT ; Jump if something went wrong (note CF=1)

	 test	 LCL_FLAG,@LCL_EXE ; Izit an .EXE file?
	 jz	 short @F	; Jump if not

	 call	 RELO_MEM	; Perform relocation of EXE file
	 jc	 short CHECK_MEM_EXIT ; Jump on error (note CF=1)
@@:

; Compare the two parts

;;;;;;;; call	 COMP_MEM	; Compare 'em
;;;;;;;; jnc	 short CHECK_MEM_EXIT ; Jump if same (note CF=0)
;;;;;;;;
; Copy the low-order part to the high-order part

	 call	 COPY_MEM	; Copy low to high

; Compare the two parts again

	 call	 COMP_MEM	; Compare 'em
	 jc	 short CHECK_MEM_EXIT ; Jump if something went wrong (note CF=1)

	 call	 CLEAR_MEM	; Clear the low memory copy

	 clc			; Mark as successful
CHECK_MEM_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_MEM endp			; End CHECK_MEM procedure
	 NPPROC  RELO_MEM -- Relocate EXE File for High DOS Memory
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Relocate EXE file for high DOS memory.

On exit:

CF	 =	 0 if all went OK
	 =	 0 otherwise

|

	 REGSAVE <ax,bx,cx,dx,si,di,bp,es> ; Save registers

; Open the file

	 mov	 al,@OPEN_R	; Function code for read-only
	 DOSCALL @OPENF2,LCL_PATH ; Attempt to open it
	 jc	 short RELO_MEM_EXIT ; Jump if error (note CF=1)

	 mov	 bx,ax		; Copy to file handle register

; Move the file pointer to the start of the relocation table items

	 mov	 dx,FILE_HEAD.EXE_IREL ; Get offset to first relocation item
	 xor	 cx,cx		; CX:DX ==> offset in file of relocation table
	 mov	 al,0		; Function code relative to start of file
	 DOSCALL @MOVFP2	; Move the file pointer to the start of the table
	 jc	 short RELO_MEM_EXITCLOSE ; Jump if error (note CF=1)

	 mov	 bp,FILE_HEAD.EXE_NREL ; Get # relocation table items

	 and	 bp,bp		; Any entries remaining?
	 jz	 short RELO_MEM_EXITCLOSE ; Jump if not (note CF=0)

; Read in the relocation table items

RELO_MEM_READ:
	 mov	 cx,@RELOSIZ/4	; Get # entries in table

	 UMIN	 cx,bp		; CX = min (CX, BP)
	 sub	 bp,cx		; Less # we're reading this round

	 push	 cx		; Save count of # entries
	 shl	 cx,1		; Convert from # entires (dwords) to bytes
	 shl	 cx,1
	 DOSCALL @READF2,RELOTAB ; Read it in
	 pop	 cx		; Restore
	 jc	 short RELO_MEM_EXITCLOSE ; Jump if error (note CF=1)

; Loop through relocation table items

	 xor	 si,si		; Initialize index into RELOTAB
	 mov	 dx,EXEC_LOD	; Get high memory segment
	 sub	 dx,EXEC_LODLO	; Less low memory segment
RELO_MEM_NEXT:
	 assume  es:nothing	; Tell the assembler about it

	 mov	 di,RELOTAB.ELO[si] ; Get offset within segment
	 mov	 ax,RELOTAB.EHI[si] ; Get segment addition
	 add	 ax,EXEC_LODLO	; Plus segment of low DOS memory copy
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 add	 es:[di],dx	; Relocate back to high DOS memory

	 add	 si,4		; Skip to next relocation table item

	 loop	 RELO_MEM_NEXT	; Jump if more entries in this chunk

	 and	 bp,bp		; Any entries remaining?
	 jnz	 short RELO_MEM_READ ; Jump if so
				; Fall through if not (note CF=0)
RELO_MEM_EXITCLOSE:
	 pushf			; Save flags (in particular CF)
	 DOSCALL @CLOSF2	; Close the file
	 popf			; Restore
RELO_MEM_EXIT:
	 REGREST <es,bp,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

RELO_MEM endp			; End RELO_MEM procedure
	 NPPROC  COMP_MEM -- Compare High and Low DOS Memory
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Compare high and low DOS memory parts of a loaded program.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save registers

	 mov	 dx,COMPSIZE.EHI ; Get high-order word of comparison size
	 mov	 bx,COMPSIZE.ELO ; ... low-...

; Back off by one para in case of previous rounding up

	 sub	 bx,16-1	; Less rounding factor
	 sbb	 dx,0		; In case of underflow

	 mov	 es,EXEC_LOD	; Address high-order segment
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> high-order copy

	 mov	 ds,EXEC_LODLO	; Address low-order segment
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; DS:SI ==> low-order copy
COMP_MEM_NEXT:
	 mov	 cx,8000h	; Assume full 64KB in words

	 and	 dx,dx		; Any high-order chunks remaining?
	 jnz	 short @F	; Jump if so

	 mov	 cx,bx		; Get low-order word of load size
	 shr	 cx,1-0 	; Convert from bytes to words
				; Note that if CX = 0, ZF=1
@@:
    repe cmpsw			; Compare 'em
	 jne	 short COMP_MEM_ERR ; Jump if there's a mismatch

	 mov	 ax,ds		; Copy segment
	 add	 ax,1000h	; Skip to next 64KB
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ax,es		; Copy segment
	 add	 ax,1000h	; Skip to next 64KB
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 and	 dx,dx		; Any big chunks remaining?
	 jz	 short COMP_MEM_EXIT ; Jump if not (note CF=0)

	 dec	 dx		; Less one big chunk

	 jmp	 short COMP_MEM_NEXT ; Go around again

COMP_MEM_ERR:
	 stc			; Indicate something went wrong
COMP_MEM_EXIT:
	 REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

COMP_MEM endp			; End COMP_MEM procedure
	 NPPROC  COPY_MEM -- Copy Low to High DOS Memory
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Copy low DOS memory loaded program to high DOS memory.

|

	 REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save registers

	 mov	 dx,COMPSIZE.EHI ; Get high-order word of comparison size
	 mov	 bx,COMPSIZE.ELO ; ... low-...

	 mov	 es,EXEC_LOD	; Address high-order segment
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> high-order copy

	 mov	 ds,EXEC_LODLO	; Address low-order segment
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; DS:SI ==> low-order copy
COPY_MEM_NEXT:
	 mov	 cx,8000h	; Assume full 64KB in words

	 and	 dx,dx		; Any high-order chunks remaining?
	 jnz	 short @F	; Jump if so

	 lea	 cx,[bx+1]	; Get low-order word of load size,
				; round up to word boundary
	 shr	 cx,1-0 	; Convert from bytes to words
	 jz	 short COPY_MEM_EXIT ; Jump if that's all folks
@@:
     rep movsw			; Copy to high DOS memory

	 mov	 ax,ds		; Copy segment
	 add	 ax,1000h	; Skip to next 64KB
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ax,es		; Copy segment
	 add	 ax,1000h	; Skip to next 64KB
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 and	 dx,dx		; Any big chunks remaining?
	 jz	 short COPY_MEM_EXIT ; Jump if not

	 dec	 dx		; Less one big chunk

	 jmp	 short COPY_MEM_NEXT ; Go around again

COPY_MEM_EXIT:
	 REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

COPY_MEM endp			; End COPY_MEM procedure
	 NPPROC  CLEAR_MEM -- Clear Low DOS Memory Copy
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Clear the low DOS memory copy of the program.

In order to avoid a program finding itself in low memory after
we've loaded it into high memory, we must zero the low memory copy.

|

	 REGSAVE <ax,bx,cx,dx,di,es> ; Save registers

	 mov	 dx,COMPSIZE.EHI ; Get high-order word of comparison size
	 mov	 bx,COMPSIZE.ELO ; ... low-...

	 mov	 es,EXEC_LODLO	; Address low-order segment
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> low-order copy
CLEAR_MEM_NEXT:
	 mov	 cx,8000h	; Assume full 64KB in words

	 and	 dx,dx		; Any high-order chunks remaining?
	 jnz	 short @F	; Jump if so

	 lea	 cx,[bx+1]	; Get low-order word of load size,
				; round up to word boundary
	 shr	 cx,1-0 	; Convert from bytes to words
	 jz	 short CLEAR_MEM_EXIT ; Jump if that's all folks
@@:
	 xor	 ax,ax		; Clear to this value
     rep stosw			; Clear the source data

	 mov	 ax,es		; Copy segment
	 add	 ax,1000h	; Skip to next 64KB
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 and	 dx,dx		; Any big chunks remaining?
	 jz	 short CLEAR_MEM_EXIT ; Jump if not

	 dec	 dx		; Less one big chunk

	 jmp	 short CLEAR_MEM_NEXT ; Go around again

CLEAR_MEM_EXIT:
	 REGREST <es,di,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CLEAR_MEM endp			; End CLEAR_MEM procedure
	 NPPROC  DB2HEX -- Convert AL to Hex At ES:DI
	 assume  ds:PGROUP,es:nothing,ss:nothing

	 push	 cx		; Save for a moment
	 mov	 cx,2		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 cx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DB2HEX	 endp			; End DB2HEX procedure
	 NPPROC  DW2HEX -- Convert AX to Hex At ES:DI
	 assume  ds:PGROUP,es:nothing,ss:nothing

	 push	 cx		; Save for a moment
	 mov	 cx,4		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 cx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DW2HEX	 endp			; End DW2HEX procedure
	 NPPROC  BIN2HEX_SUB
	 assume  ds:nothing,es:nothing,ss:nothing

	 REGSAVE <ax,bx,dx>	; Save registers

	 pushf			; Save flags
	 std			; Store backwards

	 mov	 dx,ax		; Copy to secondary register
	 lea	 bx,NUMBERS_HI	; XLAT table
	 add	 di,cx		; Skip to the end+1
	 push	 di		; Save to return
	 dec	 di		; Now the last digit
BIN2HEX_MORE:
	 mov	 al,dl		; Copy to XLAT register
	 and	 al,0Fh 	; Isolate low-order digit
	 xlat	 NUMBERS_HI	; Convert to ASCII hex
	 stosb			; Save in output area

	 shr	 dx,1		; Shift next digit down to low-order
	 shr	 dx,1
	 shr	 dx,1
	 shr	 dx,1

	 loop	 BIN2HEX_MORE	; Jump if more digits to format

	 pop	 di		; Restore

	 popf			; Restore flags

	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

BIN2HEX_SUB endp		; End BIN2HEX_SUB procedure
if @OEM_FLEX
	 NPPROC  FCN_FLEXFRAME -- Function to Handle FLEXFRAME
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Function to handle FLEXFRAME

On entry:

DS:SI	 ==>	 argument line

On exit:

DS:SI	 ==>	 (updated)
CF	 =	 1 if error
	 =	 0 otherwise

|

; Ignore FLEXFRAME if GETSIZE requested

	 test	 OPT_FLAG,@OPT_GSIZE ; Is GETSIZE specified?
	 jnz	 short @F	; Jump if so

	 or	 LSEG.LSEG_FLAG,@LSEG_FLEX ; Use EMS page frame requested

; If TSRLOAD, set ENVNAME too

	 test	 LCL_FLAG,@LCL_TSR ; Izit TSRLOAD?
	 jz	 short @F	; Jump if not

	 or	 OPT_FLAG,@OPT_ENAME ; Mark as name-only in the environment
@@:
	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_FLEXFRAME endp		; End FCN_FLEXFRAME procedure
endif				; IF @OEM_FLEX
	 NPPROC  FORCE_GETSIZE -- Function to Handle Forced GETSIZE
	 assume  ds:nothing,es:nothing,ss:nothing

	 or	 LSEG.LSEG_FLAG,@LSEG_GSIZE ; Mark as forced GETSIZE

	 jmp	 short FCN_GETSIZE ; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing

FORCE_GETSIZE endp		; End FORCE_GETSIZE procedure
	 NPPROC  FCN_GETSIZE -- Function to Handle GETSIZE
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Function to handle GETSIZE

On entry:

DS:SI	 ==>	 argument line

On exit:

DS:SI	 ==>	 (updated)
CF	 =	 1 if error
	 =	 0 otherwise

|
	 call	 DISP_COPY	; Show copyright.

	 or	 OPT_FLAG,@OPT_GSIZE ; Mark as GETSIZE requested
	 and	 OPT_FLAG,not @OPT_SIZE ; Clear SIZE= if present

	 mov	 LSEG.LSEG_ASIZE.ELO,-1 ; Save for SUMMARY report
	 mov	 LSEG.LSEG_ASIZE.EHI,-1

	 and	 LSEG.LSEG_FLAG,not @LSEG_FLEX ; Clear FLEXFRAME flag

	 mov	 PFID_ROOM.ELO,0 ; Clear any previous value
	 mov	 PFID_ROOM.EHI,0

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_GETSIZE endp		; End FCN_GETSIZE procedure
	 NPPROC  FCN_GROUP -- Function to Handle GROUP=
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Function to handle GROUP=

On entry:

DS:SI	 ==>	 argument line

On exit:

DS:SI	 ==>	 (updated)
CF	 =	 1 if error
	 =	 0 otherwise

|

	 REGSAVE <ax,dx>	; Save registers

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 lodsb			; Get next character

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_GROUP_ERR ; Too bad

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 call	 DEC2BIN	; Convert ASCII decimal digits at DS:SI to (DX,AX)
	 jc	 short FCN_GROUP_ERR ; Too large, so that's an error

; Ensure the value is below the special values @GPRMAX, etc. and non-zero

	 and	 dx,dx		; Ensure zero
	 jnz	 short FCN_GROUP_ERR ; Not so, so that's an error

	 cmp	 ax,128 	; Check against (abritrary) upper limit
	 jae	 short FCN_GROUP_ERR ; Too large, so that's an error

	 cmp	 ax,0		; Ensure non-zero
	 je	 short FCN_GROUP_ERR ; Not so, so that's an error

	 mov	 LSEG.LSEG_GRP,al ; Save as group #
;;;;;;;; or	 OPT_FLAG,@OPT_GRP ; Mark as specified

	 clc			; Indicate all went well

	 jmp	 short FCN_GROUP_EXIT ; Join common exit code

FCN_GROUP_ERR:
	 stc			; Indicate something went wrong
FCN_GROUP_EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_GROUP endp			; End FCN_GROUP procedure
	 NPPROC  FCN_INT -- Function to Handle INT
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Function to handle INT

On entry:

DS:SI	 ==>	 argument line

On exit:

DS:SI	 ==>	 (updated)
CF	 =	 1 if error
	 =	 0 otherwise

|

	 or	 OPT_FLAG,@OPT_INTR ; Interrupt requested

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_INT  endp			; End FCN_INT procedure
if @OEM_SYS ne @OEMSYS_3COM
	 NPPROC  FCN_NOPAUSE -- Function to Handle NOPAUSE
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Function to handle NOPAUSE

On entry:

DS:SI	 ==>	 argument line

On exit:

DS:SI	 ==>	 (updated)
CF	 =	 1 if error
	 =	 0 otherwise

|

	 or	 OPT_FLAG,@OPT_NOPAUSE ; No pause requested

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_NOPAUSE endp		; End FCN_NOPAUSE procedure
else
	 NPPROC  FCN_PAUSE -- Function to Handle PAUSE
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Function to handle PAUSE

On entry:

DS:SI	 ==>	 argument line

On exit:

DS:SI	 ==>	 (updated)
CF	 =	 1 if error
	 =	 0 otherwise

|

	 and	 OPT_FLAG,not @OPT_NOPAUSE ; Pause requested

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_PAUSE endp			; End FCN_PAUSE procedure
endif				; IF @OEM_SYS ne @OEMSYS_3COM
	 NPPROC  FCN_PRGREG -- Function to Handle PRGREG=
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Function to handle PRGREG=

On entry:

DS:SI	 ==>	 argument line

On exit:

DS:SI	 ==>	 (updated)
CF	 =	 1 if error
	 =	 0 otherwise

|

	 REGSAVE <ax,dx>	; Save registers

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 lodsb			; Get next character

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_PRGREG_ERR ; Too bad

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 call	 DEC2BIN	; Convert ASCII decimal digits at DS:SI to (DX,AX)
	 jc	 short FCN_PRGREG_ERR ; Too large, so that's an error

; Ensure the value is within range

	 and	 dx,dx		; Ensure zero
	 jnz	 short FCN_PRGREG_ERR ; Not so, so that's an error

	 cmp	 ax,10		; Check against (abritrary) upper limit
	 jae	 short FCN_PRGREG_ERR ; Too large, so that's an error

	 mov	 LSEG.LSEG_PREG,al ; Save as program region #
	 mov	 PRGREG,al	; Save to decrement
	 or	 OPT_FLAG,@OPT_PREG ; Mark as specified

	 clc			; Indicate all went well

	 jmp	 short FCN_PRGREG_EXIT ; Join common exit code

FCN_PRGREG_ERR:
	 stc			; Indicate something went wrong
FCN_PRGREG_EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_PRGREG endp 		; End FCN_PRGREG procedure
	 NPPROC  FCN_QUIET -- Function to Handle QUIET
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Function to handle QUIET

On entry:

DS:SI	 ==>	 argument line

On exit:

DS:SI	 ==>	 (updated)
CF	 =	 1 if error
	 =	 0 otherwise

|

	 or	 OPT_FLAG,@OPT_QUIET ; Quiet requested

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_QUIET endp			; End FCN_QUIET procedure
	 NPPROC  FCN_SIZE -- Function to Handle SIZE=
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Function to handle SIZE=nnnnnn or SIZE=nnnnnn,nnnnnn

On entry:

DS:SI	 ==>	 argument line

On exit:

DS:SI	 ==>	 (updated)
CF	 =	 1 if error
	 =	 0 otherwise

|

	 REGSAVE <ax,dx>	; Save registers

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 lodsb			; Get next character

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_SIZE_ERR ; Too bad

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 call	 DEC2BIN	; Convert ASCII decimal digits at DS:SI to (DX,AX)
	 jc	 short FCN_SIZE_ERR ; Jump if too big

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short FCN_SIZE_CLC ; Yes, don't save over

	 or	 OPT_FLAG,@OPT_SIZE ; Mark as SIZE= specified

; Round actual size up to para boundary

	 add	 ax,16-1	; Add in fudge
	 adc	 dx,0		; In case of overflow
	 and	 ax,not (16-1)	; Round down

	 mov	 LSEG.LSEG_ASIZE.ELO,ax ; Save for SUMMARY report
	 mov	 LSEG.LSEG_ASIZE.EHI,dx

	 mov	 PFID_ROOM.ELO,ax ; Save for later use
	 mov	 PFID_ROOM.EHI,dx ; ...

; Check for secondary resident size

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 lodsb			; Get next character

	 cmp	 al,','         ; Check for separator
	 jne	 short FCN_SIZE_END ; Jump if not

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 call	 DEC2BIN	; Convert ASCII decimal digits at DS:SI to (DX,AX)
	 jc	 short FCN_SIZE_ERR ; Jump if too big

; Round resident size up to para boundary

	 add	 ax,16-1	; Add in fudge
	 adc	 dx,0		; In case of overflow
	 and	 ax,not (16-1)	; Round down

	 call	 BYT2PAR	; Convert (DX,AX) in bytes to AX in paras
				; rounding down

	 mov	 LSEG.LSEG_RPAR2,ax ; Save for SUMMARY report
	 or	 LSEG.LSEG_FLAG,@LSEG_FSIZ ; Mark as forced resident SIZE=

	 jmp	 short FCN_SIZE_CLC ; Join common OK code

FCN_SIZE_END:
	 dec	 si		; Back off to last character
FCN_SIZE_CLC:
	 clc			; Indicate all went well

	 jmp	 short FCN_SIZE_EXIT ; Join common exit code

FCN_SIZE_ERR:
	 stc			; Indicate something went wrong
FCN_SIZE_EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_SIZE endp			; End FCN_SIZE procedure
	 NPPROC  FCN_VDS -- Function to Handle VDS
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Function to handle VDS

On entry:

DS:SI	 ==>	 argument line

On exit:

DS:SI	 ==>	 (updated)
CF	 =	 1 if error
	 =	 0 otherwise

|

	 or	 OPT_FLAG,@OPT_VDS ; VDS support present

	 clc			; Indicate all went well

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_VDS  endp			; End FCN_VDS procedure
	 NPPROC  CHECK_SETVER -- Check on SETVER Matches
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Check the "filename.ext",0 for presence in DOS 4.xx SETVER table.

|

SETVER_STR struc

	 dw	 ?		; Caller's IP
	 dw	 ?		; ...	   BP
SETVER_OFF dw	 ?		; Offset in PGROUP of "d:\path\filename.ext",0
				; to search for

SETVER_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

	 cmp	 DOSVER.HI,04h	; Izit DOS 4.xx?
	 jne	 short CHECK_SETVER_EXIT ; Jump if not
;;;;;;;; jb	 short CHECK_SETVER_EXIT ; Jump if earlier

	 push	 ds		; Get our data segment
	 pop	 es		; Address it for string ops
	 assume  es:PGROUP	; Tell the assembler about it

; Skip past "d:\path\" to "filename.ext",0

	 mov	 di,[bp].SETVER_OFF ; ES:DI ==> "d:\path\filename.ext",0
	 mov	 si,di		; Save in case not found

; Go to the end of the filename.ext

	 mov	 al,0		; ASCIIZ terminator
	 mov	 cx,-1		; We know it's there
   repne scasb			; Search for it
	 dec	 di		; Back off to trailing zero
	 mov	 dx,di		; Save ending+1

; Now search for the last path separator to get just the path

	 mov	 al,'\'         ; Get path separator
	 std			; Search backwards
   repne scasb			; Search for it
	 cld			; String ops forwards
	 jne	 short @F	; Jump if not found

	 lea	 si,[di+2]	; Copy offset of sep+1
@@:
				; DS:SI ==> "filename.ext",0
	 sub	 dx,si		; Subtract starting offset to get length

	 DOSCALL @GETLST	; Return with ES:BX ==> list of lists
	 assume  es:nothing	; Tell the assembler about it

	 mov	 di,es:[bx+35h] ; Get offset of SETVER table
CHECK_SETVER_NEXT:
	 xor	 ch,ch		; Zero to use as word
	 mov	 cl,es:[di]	; Get the length byte
	 jcxz	 CHECK_SETVER_EXIT ; Jump if that's all
	 inc	 di		; ...and skip over it

	 cmp	 cx,dx		; Izit the same length?
	 jne	 short @F	; Jump if not

	 call	 STRNICMP	; Compare 'em to length CX
	 jnc	 short CHECK_SETVER_OK ; Jump if it's a match
@@:
	 add	 di,cx		; Skip over filename in SETVER table
;;;;;;;; add	 di,2		; Skip over Major, Minor fields
	 add	 di,3		; Skip over Major, Minor, Count fields

;;;;;;;; cmp	 DOSVER.HI,05h	; Izit DOS 5.xx?
;;;;;;;; je	 short CHECK_SETVER_NEXT ; Jump if so (no count field)
;;;;;;;;
;;;;;;;; inc	 di		; Skip over Count field
;;;;;;;;
	 jmp	 short CHECK_SETVER_NEXT ; Go around again

CHECK_SETVER_OK:
	 add	 di,cx		; Skip over filename in SETVER table
	 mov	 ax,es:[di]	; Get major/minor version # into AL, AH
	 mov	 XDOSVER,ax	; Save for later use
CHECK_SETVER_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_SETVER endp		; End CHECK_SETVER procedure
	 NPPROC  STRNICMP -- String Compare Case-insensitive to Length-sensitive
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

String compare, case-insensitive, length-sensitive

On entry:

DS:SI	 ==>	 string #1
ES:DI	 ==>	 string #2
CX	 =	 length

On exit:

CF	 =	 0 if they compare equally
	 =	 1 otherwise

|

	 REGSAVE <ax,cx,si,di>	; Save registers
STRNICMP_NEXT:
	 clc			; Start with CF=0 in case CX=0
	 jcxz	 STRNICMP_EXIT	; Jump if that's all folks
    repe cmpsb			; Compare 'em
	 je	 short STRNICMP_EXIT ; Jump if same (note CF=0)

; Check for mismatch in upper/lowercase

	 mov	 al,ds:[si-1]	; Get previous character
	 mov	 ah,es:[di-1]	; ...

	 call	 LOWERCASE	; Convert AL to lowercase
	 xchg	 al,ah		; Swap 'em
	 call	 LOWERCASE	; Convert AL to lowercase

	 cmp	 al,ah		; Izit the same?
	 je	 short STRNICMP_NEXT ; Jump if so

	 stc			; Mark as a mismatch
STRNICMP_EXIT:
	 REGREST <di,si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

STRNICMP endp			; End STRNICMP procedure
	 NPPROC  GETPARAS -- Read decimal value and convert to paras
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Read a decimal value at DS:SI, round it up and convert to paras.

On entry:
DS:SI ==>	 ASCII decimal value

On exit:
DS:SI ==>	 First non-decimal character
AX		 Value in paras

|

	 REGSAVE <dx>		; Save

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 call	 DEC2BIN	; Convert ASCII decimal digits at DS:SI to (DX,AX)

; Round up initialization size increment to a para boundary

	 add	 ax,16-1	; Add in slop
	 adc	 dx,0		; In case of overflow
	 call	 BYT2PAR	; Convert (DX,AX) in bytes to AX in paras
				; rounding down

	 REGREST <dx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GETPARAS endp			; End GETPARAS procedure
	 NPPROC  READCFG -- Read Configuration File
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Read configuration file,
check for filename match, and
set flags as appropriate.

|

RDCFG_STR struc

	 dw	 ?		; Caller's IP
	 dw	 ?		; ...	   BP
RDCFG_OFF dw	 ?		; Offset in PGROUP of "d:\path\filename.ext",0
				; to search for
RDCFG_LEN dw	 ?		; Length of our path
RDCFG_VEC dd	 ?		; Pointer to ...

RDCFG_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

	 push	 ds		; Get our data segment
	 pop	 es		; Address it for string ops
	 assume  es:PGROUP	; Tell the assembler about it

; Construct d:\path\filename.ext for configuration file

	 push	 ds		; Save for a moment

	 lea	 di,CFGPATH	; ES:DI ==> temp save area for CFGFILE path
	 lds	 si,[bp].RDCFG_VEC ; DS:SI ==> our load path
	 mov	 cx,[bp].RDCFG_LEN ; CX = length of ...
     rep movsb			; Copy our load path to local save area

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 lea	 si,CFGFILE	; DS:SI ==> configuration file name
	 mov	 cx,CFGFILE_LEN ; CX = length of ...
     rep movsb			; Copy our filename.ext to local save area

; Open the configuration file

	 mov	 al,@OPEN_R	; Function code for read-only
	 DOSCALL @OPENF2,CFGPATH ; Attempt to open the file
	MJ c	 READCFG_ERR	; Jump if unable to read the file

	 mov	 bx,ax		; Copy to handle register

; Ensure it's a file

	 mov	 al,0		; Function to Get Device Information
	 DOSCALL @IOCTL2	; Return with DX = device information

	 test	 dx,@IOCTL_DEV	; Check for a device
	MJ nz	 READCFG_END	; Jump if so

; Skip past "d:\path\" to "filename.ext",0

	 mov	 di,[bp].RDCFG_OFF ; ES:DI ==> "d:\path\filename.ext",0
	 mov	 si,di		; Save in case not found

; Go to the end of the filename.ext

	 mov	 al,0		; ASCIIZ terminator
	 mov	 cx,-1		; We know it's there
   repne scasb			; Search for it
	 dec	 di		; Back off to trailing zero

; Now search for the last path separator to get just the path

	 mov	 al,'\'         ; Get path separator
	 std			; Search backwards
   repne scasb			; Search for it
	 cld			; String ops forwards
	 jne	 short @F	; Jump if not found

	 lea	 si,[di+2]	; Copy offset of sep+1
@@:
	 mov	 di,si		; ES:DI ==> "filename.ext",0

; Read in a line of the file into CFGLINE
	 mov	 CFGFLAGS,0	; Clear flags

READCFG_NEXTLINE:
	 call	 GETLINE	; Read it in
	MJ c	 READCFG_END	; Jump if no more lines (or error)

	 lea	 si,CFGLINE	; DS:SI ==> ASCIIZ line from file
	 call	 SKIP_WHITE	; Skip over any intervening white space

	 cmp	 ds:[si].LO,';' ; Izit a comment?
	 je	 short READCFG_NEXTLINE ; Jump if so

	 cmp	 ds:[si].LO,0	; Izit a blank line?
	 je	 short READCFG_NEXTLINE ; Jump if so

; Parse flags at DS:SI

	 sub	 ax,ax		; Clear temporary flags
	 mov	 dx,ax		; ...

	 xchg	 ax,CFGFLAGS	; Save and clear flags
	 xchg	 dx,PATCHFLAGS	; ...
	 call	 PARSE_FLAGS	; Parse 'em, return with DS:SI ==> next token
	 xchg	 ax,CFGFLAGS	; Restore flags & get flags to test in AX
	 xchg	 dx,PATCHFLAGS	; ...

; Check for match with filename.ext

	 call	 CHECK_NAME	; Check it
	 jc	 short READCFG_NEXTLINE ; Jump if no match

; Validate the file's date stamp

	 call	 CHECK_DATE	; Check it
	 jc	 short READCFG_NEXTLINE ; Jump if no match

	 or	 CFGFLAGS,ax	; Save flags for later processing
	 or	 PATCHFLAGS,dx	; ...

; Process the flags

	 test	 ax,@CFG_XHILOAD ; Izit not to be loaded high?
	 jz	 short READCFG_XXHILOAD ; Jump if not

	 test	 CM2_FLAG,@CM2_XSCSI ; Is there a BUSMASTER present?
	 jz	 short READCFG_XXHILOAD ; Jump if not

	 test	 OPT_FLAG,@OPT_VDS ; Is there a VDS keyword?
	 jnz	 short READCFG_XXHILOAD ; Jump if so

	 or	 LC2_FLAG,@LC2_XHILOAD ; Mark as not to be loaded high
READCFG_XXHILOAD:
	 test	 ax,@CFG_WINST	; Izit Instance Me?
	 jz	 short READCFG_XWINST ; Jump if not

	 or	 LSEG.LSEG_FLAG,@LSEG_WINST ; Mark as forced instancing
READCFG_XWINST:
	 test	 ax,@CFG_ESAVE	; Izit ENVSAVE?
	 jz	 short READCFG_XESAVE ; Jump if not

; Because we don't relocate the environment if ENVSAVE is specified,
; we must disable FLEXFRAME

if @OEM_FLEX
	 and	 LSEG.LSEG_FLAG,not @LSEG_FLEX ; Is use EMS page frame requested?
endif				; IF @OEM_FLEX
	 and	 OPT_FLAG,not @OPT_ENAME ; Remove mark as name-only in the environment
READCFG_XESAVE:
	 test	 ax,@CFG_GSIZE	; Izit forced GETSIZE limit?
	 jz	 short READCFG_XGSIZE ; Jump if not

	 REGSAVE <ax>		; Save flags

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 call	 DEC2BIN	; Convert ASCII decimal digits at DS:SI to (DX,AX)

; Round up initialization size to a para boundary

	 add	 ax,16-1	; Add in slop
	 adc	 dx,0		; In case of overflow
	 and	 ax,not (16-1)	; Round to boundary

	 mov	 LSEG.LSEG_ISIZE.ELO,ax ; Save as initialization size
	 mov	 LSEG.LSEG_ISIZE.EHI,dx

	 REGREST <ax>		; Restore

READCFG_XGSIZE:
	 test	 ax,@CFG_TOPF	; Izit TOPFILL?
	 jz	 short READCFG_XTOPF ; Jump if not

	 REGSAVE <ax>		; Save flags

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 call	 DEC2BIN	; Convert ASCII decimal digits at DS:SI to (DX,AX)

	 and	 dx,dx		; Izit valid?
	 jnz	 short @F	; Jump if not

	 and	 ax,ax		; Izit valid?
	 je	 short @F	; Jump if not

	 cmp	 ax,640 	; Izit valid?
	 ja	 short @F	; Jump if not

	 mov	 cl,10-4	; Shift amount between 1KB and paras
	 shl	 ax,cl		; Convert from 1KB to paras
	 UMIN	 TOPFILL,ax	; Save lesser for later use

@@:
	 REGREST <ax>		; Restore

READCFG_XTOPF:
	 test	 ax,@CFG_COMSTK ; Izit COM file stack trick?
	 jz	 short READCFG_XCOMSTK ; Jump if not

	 REGSAVE <ax>		; Save flags

	 or	 LC2_FLAG,@LC2_COMSTK ; Mark as COM stack trick in effect

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 call	 DEC2BIN	; Convert ASCII decimal digits at DS:SI to (DX,AX)

	 call	 BYT2PAR	; Convert (DX,AX) in bytes to AX in paras
				; rounding down

	 or	 ax,ax		; Izit valid?
	 jz	 short @F	; Ignore quietly if not

	 mov	 MIN_HOLE,ax	; Save for comparison later
@@:
	 REGREST <ax>		; Restore

READCFG_XCOMSTK:
	 test	 ax,@CFG_I12	; Izit top of DOS trick?
	 jz	 short READCFG_XI12 ; Jump if not

	 or	 LC2_FLAG,@LC2_I12 ; Mark as top of DOS trick in effect
READCFG_XI12:
	 test	 ax,@CFG_HSIZED ; Izit high size increment?
	 jz	 short READCFG_XHSIZED ; Jump if not

	 REGSAVE <ax>		; Save flags

	 call	 GETPARAS	; Get rounded decimal value in paras in AX

	 mov	 HSIZE_DELTA,ax ; Save as initialization size increment

	 REGREST <ax>		; Restore

READCFG_XHSIZED:
	 test	 ax,@CFG_NORETRY ; Izit NORETRY?
	 jz	 short READCFG_XNORETRY ; Jump if not

	 or	 OPT_FLAG,@OPT_NORETRY ; If TSR doesn't go resident, don't try
				; again in low DOS.

READCFG_XNORETRY:
	 test	 ax,@CFG_GSIZED ; Izit GETSIZE delta for resident size?
	 jz	 short READCFG_XGSIZED ; Jump if not

	 REGSAVE <ax>		; Save flags

; Get resident size increment
	 call	 GETPARAS	; Get rounded decimal value in paras in AX
	 mov	 GETSIZE_RDELTA,ax ; Save as low DOS resident size increment

; Get initialization size increment
	 call	 GETPARAS	; Get rounded decimal value in paras in AX
	 mov	 GETSIZE_IDELTA,ax ; Save as low DOS init size increment

	 REGREST <ax>		; Restore

READCFG_XGSIZED:
	 jmp	 READCFG_NEXTLINE ; Go around again

READCFG_END:
	 DOSCALL @CLOSF2	; Close it
;;;;;;;;
;;;;;;;; jmp	 short READCFG_EXIT ; Join common exit code
;;;;;;;;
READCFG_ERR:
READCFG_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,ss:nothing

READCFG  endp			; End READCFG procedure
	 NPPROC  GETLINE -- Read In A Line From A File
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Read in a line from a file.

On entry:

BX	 =	 file handle

On exit:

CF	 =	 1 if something went wrong, or EOL
	 =	 0 otherwise
CFGLINE  filled in with ASCIIZ line

|

	 REGSAVE <ax,cx,dx,si>	; Save registers

	 mov	 cx,CFGLINE_LEN ; Get buffer length
	 DOSCALL @READF2,CFGLINE ; Read it in
	 jc	 short GETLINE_EXIT ; Jump if something went wrong (note CF=1)

	 mov	 cx,ax		; Copy actual amount read
	 jcxz	 GETLINE_ERR	; Jump if that's all

	 cmp	 CFGLINE,EOF	; Izit the last line?
	 je	 short GETLINE_ERR ; Jump if so

; Search for line ending

	 lea	 si,CFGLINE	; DS:SI ==> the line plus tail
@@:
	 lodsb			; Get next character

	 cmp	 al,CR		; Izit EOL?
	 je	 short @F	; Jump if so

	 cmp	 al,LF		; Izit EOL?
	 je	 short @F	; Jump if so

	 cmp	 al,EOF 	; Izit EOF?
	 je	 short @F	; Jump if so

	 loop	 @B		; Jump if more characters
@@:
	 mov	 PGROUP:[si-1].LO,0 ; Set line terminator

; Skip over trailing line terminators

@@:
	 jcxz	 @F		; Jump if none left
	 lodsb			; Get next character
	 dec	 cx		; Account for it

	 cmp	 al,CR		; Izit EOL?
	 je	 short @B	; Jump if so

	 cmp	 al,LF		; Izit EOL?
	 je	 short @B	; Jump if so

	 cmp	 al,EOF 	; Izit EOF?
	 je	 short @B	; Jump if so
@@:

; Back up the file pointer to point to the next line

	 mov	 dx,cx		; Copy low-order of amount to move
	 xor	 cx,cx		; Zero high-...

	 neg	 dx		; Negate to move backwards
	 sbb	 cx,0		; In case of underflow
	 mov	 al,1		; Method = from current position
	 DOSCALL @MOVFP2	; Move the file pointer
GETLINE_DONE:
	 clc			; Mark as OK

	 jmp	 short GETLINE_EXIT ; Join common exit code

GETLINE_ERR:
	 stc			; Mark as all over
GETLINE_EXIT:
	 REGREST <si,dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

GETLINE  endp			; End GETLINE procedure
	 NPPROC  PARSE_FLAGS -- Parse Flags in CFGLINE
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Parse the flags in CFGLINE

On entry:

DS:SI	 ==>	 start of CFGLINE

On exit:

DS:SI	 ==>	 next token

|

	 REGSAVE <ax>		; Save register
PARSE_FLAGS_NEXT:
	 lodsb			; Get next character

; If the next character is white space, we're at the end of the flags

	 cmp	 al,' '         ; Izit white space?
	 je	 short PARSE_FLAGS_WS ; Jump if so

	 cmp	 al,TAB 	; Izit white space?
	 jne	 short @F	; Jump if not

PARSE_FLAGS_WS:
	 jmp	 PARSE_FLAGS_EXIT ; Join common exit

@@:
	 call	 LOWERCASE	; Convert AL to lowercase

	 cmp	 al,'i'         ; Izit Instance Me?
	 jne	 short PARSE_FLAGS1 ; Jump if not

	 or	 CFGFLAGS,@CFG_WINST ; Mark as to be instanced

	 jmp	 short PARSE_FLAGS_NEXT ; Go around again

PARSE_FLAGS1:
	 cmp	 al,'e'         ; Izit ENVSAVE?
	 jne	 short PARSE_FLAGS2 ; Jump if not

	 or	 CFGFLAGS,@CFG_ESAVE ; Mark as environment to be saved

	 jmp	 short PARSE_FLAGS_NEXT ; Go around again

PARSE_FLAGS2:
	 cmp	 al,'t'         ; Izit TOPFILL limit?
	 jne	 short PARSE_FLAGS3 ; Jump if not

	 or	 CFGFLAGS,@CFG_TOPF ; Mark as new TOPFILL limit

	 jmp	 short PARSE_FLAGS_NEXT ; Go around again

PARSE_FLAGS3:
	 cmp	 al,'s'         ; Izit GETSIZE value?
	 jne	 short PARSE_FLAGS4 ; Jump if not

	 or	 CFGFLAGS,@CFG_GSIZE ; Mark as GETSIZE value

	 jmp	 short PARSE_FLAGS_NEXT ; Go around again

PARSE_FLAGS4:
	 cmp	 al,'l'         ; Izit not to be loaded high?
	 jne	 short PARSE_FLAGS5 ; Jump if not

	 or	 CFGFLAGS,@CFG_XHILOAD ; Mark as not to be loaded high

	 jmp	 short PARSE_FLAGS_NEXT ; Go around again

PARSE_FLAGS5:
	 cmp	 al,'c'         ; Izit COM stack trick?
	 jne	 short PARSE_FLAGS6 ; Jump if not

	 or	 CFGFLAGS,@CFG_COMSTK ; Mark as COM stack trick

	 jmp	 short PARSE_FLAGS_NEXT ; Go around again

PARSE_FLAGS6:
	 cmp	 al,'d'         ; Izit top of DOS trick?
	 jne	 short PARSE_FLAGS7 ; Jump if not

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short @F	; Jump if so

	 or	 CFGFLAGS,@CFG_I12 ; Mark as top of DOS trick
@@:
	 jmp	 short PARSE_FLAGS_NEXT ; Go around again

PARSE_FLAGS7:
	 cmp	 al,'h'         ; Izit high DOS size delta?
	 jne	 short PARSE_FLAGS8 ; Jump if not

	 lodsb			; Get next character or digit
	 cmp	 al,'1'         ; Izit H1 (add to resident size for GETSIZE)?
	 ja	 short PARSE_FLAGS7B ; Jump if we should ignore it (H2, etc.)

	 je	 short @F	; Jump if H1

	 or	 CFGFLAGS,@CFG_HSIZED ; Mark as high DOS delta
	 cmp	 al,'0'         ; Izit H0 (add to resident size only for
				; GETSIZE)?
	 je	 short PARSE_FLAGS7B ; Jump if so

PARSE_FLAGSXDIGIT:
	 dec	 si		; Back off; it wasn't a digit
	 jmp	 short PARSE_FLAGS7B ; Join common code

@@:
	 or	 CFGFLAGS,@CFG_GSIZED ; Mark as GETSIZE delta
PARSE_FLAGS7B:
	 jmp	 PARSE_FLAGS_NEXT ; Go around again

PARSE_FLAGS8:
	 cmp	 al,'n'         ; Izit NORETRY?
	 jne	 short PARSE_FLAGS9 ; Jump if not

	 or	 CFGFLAGS,@CFG_NORETRY ; Mark as NORETRY

	 jmp	 PARSE_FLAGS_NEXT ; Go around again

PARSE_FLAGS9:
	 cmp	 al,'p'         ; Izit PROTMAN or its ilk?
	 jne	 short PARSE_FLAGS10 ;	Jump if not

	 or	 CFGFLAGS,@CFG_PROTMAN ; Mark as PROTMAN reduction

	 jmp	 PARSE_FLAGS_NEXT ; Go around again

PARSE_FLAGS10:
	 cmp	 al,'b'         ; Izit B1 (don't let SMARTDRV get low DOS)?
	 jne	 short PARSE_FLAGS11 ; Jump if not

	 lodsb			; Get next character or digit
	 cmp	 al,'1'         ; Izit B1 (close off low DOS)?
	 je	 short PARSE_FLAGS10B1 ; Jump if so

	 cmp	 al,'2'         ; Izit B2 (open high DOS for 386LOAD.SYS)?
	 je	 short PARSE_FLAGS10B2 ; Jump if so

	 cmp	 al,'3'         ; Izit B3 (if GETSIZE, hook INT 2Fh, lie for 4A11/FFFC)?
	 je	 short PARSE_FLAGS10B3 ; Jump if so

	 cmp	 al,'0'         ; Izit a digit?
	 jb	 short PARSE_FLAGSXDIGIT ; Jump if not

	 cmp	 al,'9'         ; Izit a digit?
	 ja	 short PARSE_FLAGSXDIGIT ; Jump if not

	 jmp	 short @F	; Join common code

PARSE_FLAGS10B1:
	 or	 CFGFLAGS,@CFG_CLOSELOW ; Don't free any low DOS
	 jmp	 short @F	; Join common code

PARSE_FLAGS10B2:
	 or	 CFGFLAGS,@CFG_CLOSEHI ; Close high DOS for 386LOAD.SYS
	 jmp	 short @F	; Join common code

PARSE_FLAGS10B3:
	 or	 CFGFLAGS,@CFG_DRVSPC ; Mark as telling INT 2Fh/4A11/FFFC lie
@@:
	 jmp	 PARSE_FLAGS_NEXT ; Go around again

PARSE_FLAGS11:
	 cmp	 al,'f'         ; Izit Fn (apply fix)?
	 jne	 short PARSE_FLAGS12 ; Jump if not

	 lodsb			; Get required digit
	 sub	 al,'0'         ; Get number of bits to shift

	 REGSAVE <cx>		; Save

	 mov	 cl,al		; Prepare to shift
	 mov	 ax,1		; F0 = 0001, F1 = 0002, F3 = 0004...
	 shl	 ax,cl		; Bits to add to patch flags

	 REGREST <cx>		; Restore

	 or	 PATCHFLAGS,ax	; Set patch flag specified
	 jmp	 PARSE_FLAGS_NEXT ; Go around again

PARSE_FLAGS12:
; Unknown flag (probably used by MAXIMIZE):  ignore it

	 jmp	 PARSE_FLAGS_NEXT ; Go around again

PARSE_FLAGS_EXIT:
	 call	 SKIP_WHITE	; Skip over any intervening white space

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

PARSE_FLAGS endp		; End PARSE_FLAGS procedure
	 NPPROC  CHECK_NAME -- Check for Matching Filename.exts
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Check for matching filename.exts

On entry:

DS:SI	 ==>	 "filename.ext" ... (followed by one of ' ', TAB, or 0)
ES:DI	 ==>	 "filename.ext",0

On exit:

CF	 =	 0 if it's a match
DS:SI	 ==>	 next token
CF	 =	 1 otherwise

|

	 REGSAVE <ax,di>	; Save registers

CHECK_NAME_NEXT:
	 cmpsb			; Compare 'em
	 je	 short CHECK_NAME_NEXT ; Jump if same

; Check for mismatch in upper/lowercase

	 mov	 al,ds:[si-1]	; Get previous character
	 mov	 ah,es:[di-1]	; ...

	 call	 LOWERCASE	; Convert AL to lowercase
	 xchg	 al,ah		; Swap 'em
	 call	 LOWERCASE	; Convert AL to lowercase

	 cmp	 al,ah		; Izit the same?
	 je	 short CHECK_NAME_NEXT ; Jump if so

; Check for end-of-name

	 cmp	 es:[di-1].LO,0 ; Izit string terminator?
	 jne	 short CHECK_NAME_ERR ; Jump if not

	 mov	 al,ds:[si-1]	; Get last character

	 cmp	 al,' '         ; Izit a blank separator?
	 je	 short @F	; Jump if so

	 cmp	 al,TAB 	; Izit a blank separator?
	 je	 short @F	; Jump if so

	 and	 al,al		; Izit line terminator?
	 jne	 short CHECK_NAME_ERR ; Jump if not
@@:
	 call	 SKIP_WHITE	; Skip over any intervening white space

	 clc			; Mark as a match

	 jmp	 short CHECK_NAME_EXIT ; Join common exit code

CHECK_NAME_ERR:
	 stc			; Mark as a mismatch
CHECK_NAME_EXIT:
	 REGREST <di,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_NAME endp 		; End CHECK_NAME procedure
	 NPPROC  CHECK_DATE -- Check For Matching File Dates
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Check for matching file dates

On entry:

DS:SI	 ==>	 file date yy/mm/dd
SS:BP	 ==>	 RDCFG_STR

On exit:

CF	 =	 0 if it's a match
DS:SI	 ==>	 next token
CF	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,di> ; Save registers

; Convert the text to directory format

	 xor	 di,di		; Initialize date accumulator

; First the year

	 call	 DEC2BIN	; Convert ASCII decimal digits at DS:SI to (DX,AX)

	 and	 dx,dx		; Izit valid?
	 jnz	 short CHECK_DATE_ERR ; Jump if not

	 cmp	 ax,99		; Izit valid?
	 ja	 short CHECK_DATE_ERR ; Jump if not

	 cmp	 ax,80		; Izit too small?
	 jae	 short @F	; Jump if not

	 add	 ax,100 	; Skip to next century
@@:
	 sub	 ax,80		; Convert to origin-1980
	 mov	 cl,$DATE_YY	; Shift amount for date-year
	 shl	 ax,cl		; Shift into place
	 or	 di,ax		; Include in accumulator

; Skip over date separator

	 lodsb			; Get next character

	 cmp	 al,'/'         ; Izit a valid separator?
	 je	 short @F	; Jump if so

	 cmp	 al,'-'         ; Izit another valid separator?
	 jne	 short CHECK_DATE_ERR ; Jump if not
@@:

; Next the month

	 call	 DEC2BIN	; Convert ASCII decimal digits at DS:SI to (DX,AX)

	 and	 dx,dx		; Izit valid?
	 jnz	 short CHECK_DATE_ERR ; Jump if not

	 cmp	 ax,12		; Izit valid?
	 ja	 short CHECK_DATE_ERR ; Jump if not

	 mov	 cl,$DATE_MM	; Shift amount for date-month
	 shl	 ax,cl		; Shift into place
	 or	 di,ax		; Include in accumulator

; Skip over date separator

	 lodsb			; Get next character

	 cmp	 al,'/'         ; Izit a valid separator?
	 je	 short @F	; Jump if so

	 cmp	 al,'-'         ; Izit another valid separator?
	 jne	 short CHECK_DATE_ERR ; Jump if not
@@:

; Last the day

	 call	 DEC2BIN	; Convert ASCII decimal digits at DS:SI to (DX,AX)

	 and	 dx,dx		; Izit valid?
	 jnz	 short CHECK_DATE_ERR ; Jump if not

	 cmp	 ax,31		; Izit valid?
	 ja	 short CHECK_DATE_ERR ; Jump if not

	 mov	 cl,$DATE_DD	; Shift amount for date-month
	 shl	 ax,cl		; Shift into place
	 or	 di,ax		; Include in accumulator

; If the date in the configuration file is 00/00/00,
; we assume it matches the file's actual date

	 cmp	 di,((2000-1980) shl $DATE_YY) or (0 shl $DATE_MM) or (0 shl $DATE_DD)
	 je	 short CHECK_DATE_END ; Jump if it's 00/00/00

; DI has the file date from the configuration file
; Get the corresponding date from the file

	 mov	 dx,[bp].RDCFG_OFF ; DS:DX ==> "d:\path\fileneme.ext",0
	 mov	 al,@OPEN_R	; Function code for read-only
	 DOSCALL @OPENF2	; Open the file
	 jc	 short CHECK_DATE_ERR ; Jump if error

	 mov	 bx,ax		; Copy to file handle register

	 mov	 al,0		; Function to get file's time/date
	 DOSCALL @GSTDAT	; Return with CX = time, DX = date

	 DOSCALL @CLOSF2	; Close it

	 cmp	 dx,di		; Izit the same date?
	 jne	 short CHECK_DATE_ERR ; Jump if not
CHECK_DATE_END:
	 call	 SKIP_WHITE	; Skip over any intervening white space

	 clc			; Mark as a match

	 jmp	 short CHECK_DATE_EXIT ; Join common exit code

CHECK_DATE_ERR:
	 stc			; Mark as a mismatch
CHECK_DATE_EXIT:
	 REGREST <di,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_DATE endp 		; End CHECK_DATE procedure
	 NPPROC  LOWERCASE -- Convert To Lowercase
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Convert to lowercase.

On entry:

AL	 =	 character to convert

On exit:

AL	 =	 converted character

|

	 cmp	 al,'A'         ; Check against lower limit of uppercase
	 jb	 short LOWERCASE_EXIT ; Jump if too small

	 cmp	 al,'Z'         ; Check against upper limit of uppercase
	 ja	 short LOWERCASE_EXIT ; Jump if too large

	 add	 al,'a'-'A'     ; Convet to lowercase
LOWERCASE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure
	 NPPROC  DEC2BIN -- Convert Decimal to Binary
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Convert decimal to binary

On entry:

DS:SI	 ==>	 ASCII decimal value to convert

On exit:

CF	 =	 1 if not successful
CF	 =	 0 if successful conversion
(DX,AX)  =	 converted value
DS:SI	 ==>	 points past last decimal digit

|

	 REGSAVE <bx,cx>	; Save registers

; (CX,BX) = temporary result

	 xor	 bx,bx		; Zero the low-order word of accumulator
	 xor	 cx,cx		; ...	   high-...
DEC2BIN_NEXT:
	 lodsb			; Get next digit

	 sub	 al,'0'         ; Convert to origin-0
	 jb	 short DEC2BIN_DONE ; That's all folks

	 cmp	 al,9		; Check against upper limit
	 ja	 short DEC2BIN_DONE ; That's all folks

	 xor	 ah,ah		; Zero to use as word
	 push	 ax		; Save for a moment

; Multiply (CX,BX) by 10 and store back into (CX,BX)

	 mov	 ax,cx		; Copy high-order word
	 mul	 CON10		; Shift over one decimal digit
	 jc	 short DEC2BIN_ERR0 ; Jump if too big

	 mov	 cx,ax		; Copy as quotient

	 mov	 ax,bx		; Copy low-order word
	 mul	 CON10		; Shift over one decimal digit
	 mov	 bx,ax		; Copy low-order word
	 add	 cx,dx		; In case of overflow
	 pop	 ax		; Restore new digit

; Add new digit in AX into (CX,BX)

	 add	 bx,ax		; Add into accumulator
	 adc	 cx,0		; In case of overflow
	 jc	 short DEC2BIN_ERR ; Jump if too big

	 jmp	 short DEC2BIN_NEXT ; Go around again

DEC2BIN_ERR0:
	 pop	 ax		; Restore
DEC2BIN_ERR:
	 stc			; Indicate something went wrong

	 jmp	 short DEC2BIN_EXIT ; Join common exit code

DEC2BIN_DONE:
	 dec	 si		; Back off to last digit + 1

	 mov	 ax,bx		; Copy to low-order return register
	 mov	 dx,cx		; ...	  high-...

	 clc			; Indicate all went well
DEC2BIN_EXIT:
	 REGREST <cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DEC2BIN  endp			; End DEC2BIN procedure

UCODE	 ends			; End UCODE segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 DISP_ERRMSG:near
	 extrn	 PAR2BYT:near
	 extrn	 BYT2PAR:near

	 FPPROC  INT23 -- Local INT 23h Handler
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Just return to the caller to continue the operation.

|

	 iret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INT23	 endp			; End INT23 procedure
	 FPPROC  INT24 -- Local INT 24h Handler
	 assume  ds:nothing,es:nothing,ss:nothing

	 sti			; Allow interrupts

	 add	 sp,6		; Pop off IP, CS, & Flags of INT 24h call
	 REGREST <ax,bx,cx,dx,si,di,bp,ds,es> ; Restore  INT 21h caller's regs

	 push	 ax		; Save for a moment
	 DOSCALL @GETDSK	; Any DOS call above 0Ch to stabilize DOS
	 pop	 ax		; Restore

	 stc			; Mark as in error

	 ret	 2		; Return to INT 21h caller, popping flags

	 assume  ds:nothing,es:nothing,ss:nothing

INT24	 endp			; End INT24 procedure
	 NPPROC  REST_2324 -- Restore INTS 23h and 24h
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Restore INTs 23h and 24h.

|

	 REGSAVE <ax,dx,ds>	; Save registers

	 mov	 al,23h 	; Restore this one
	 lds	 dx,OLDINT23_VEC ; DS:DX ==> old handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT	; Restore it

	 mov	 al,24h 	; Restore this one
	 lds	 dx,OLDINT24_VEC ; DS:DX ==> old handler
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETINT	; Restore it

	 REGREST <ds,dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REST_2324 endp			; End REST_2324 procedure
	 NPPROC  INFO_READ -- Read In INFO Structure
	 assume  ds:PGROUP,es:nothing,ss:nothing

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 al,02h 	; Access code for read/write
	 DOSCALL @OPENF2,BASNAME ; Attempt to open base program device driver
	 jc	 short @F	; Jump if not found

	 mov	 bx,ax		; Copy to handle register

	 mov	 al,02h 	; Read from device
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO

	 DOSCALL @CLOSF2	; Close it up
@@:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INFO_READ endp			; End INFO_READ procedure
	 NPPROC  INFO_WRITE -- Write Out INFO Structure
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

On entry:
INFO_CTL set to IOCTL function to be requested (@CTL_XFER,
@CTL_EMSOFF, or @CTL_EMSON).

|
	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 al,02h 	; Access code for read/write
	 DOSCALL @OPENF2,BASNAME ; Attempt to open base program device driver
	 jc	 short @F	; Jump if not found

	 mov	 bx,ax		; Copy to handle register

	 mov	 al,03h 	; Write to device
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 DOSCALL @IOCTL2,INFO_CTL ; Set IOCTL info from INFO

	 DOSCALL @CLOSF2	; Close it up
@@:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INFO_WRITE endp 		; End INFO_WRITE procedure
	 NPPROC  LINK_TLSEG -- Link LSEG at PGROUP:LSEG temporarily
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

We need to link the LSEG in PGROUP into the chain temporarily.
MAX will see the busy bit set in the LSEG_FLAG field and not
try to create LSEGs for UMBs.  This also keeps us from getting
delinked in CHECK_ORPHAN.  This LSEG will ALWAYS get unlinked.

While we're strolling through the LSEG chain, we'll save the
segments of all UMBs for later comparison in UNLINK_TLSEG.  If it's
386LOAD GETSIZE and any UMBs appear, we'll set the @LSEG_UMB flag.

|

	 REGSAVE <ax,bx,cx,dx,di,ds,es> ; Save

	 or	 LSEG.LSEG_FLAG,@LSEG_INPRO ; Make the LSEG busy
	 lea	 bx,PGROUP:LSEG ; Address starting offset of LSEG in PGROUP
	 mov	 cl,4-0 	; Convert bytes to paras
	 shr	 bx,cl		; DX = offset of LSEG in paras (should be 0)
	 mov	 cx,cs		; Get PGROUP segment
	 add	 bx,cx		; Get offset within PGROUP
	 mov	 LSEGSEG,bx	; Save for later
	 mov	 dx,LOADSEG	; Get starting segment in chain (can't be -1)

	 push	 ds		; Get PGROUP
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler

LTL_NEXT:
	 mov	 ds,dx		; Address next LSEG entry
	 assume  ds:nothing	; Tell the assembler

	 mov	 dx,ds:[0].LSEG_NEXT ; Get segment of next entry

	 cmp	 ds:[0].LSEG_GRP,@GRPUMB ; Izit a UMB?
	 jne	 short @F

	 cld			; Set forward direction
	 lea	 di,PGROUP:UMBSEGS ; Address list
	 mov	 cx,@MAXUMBSEGS ; Length of list in words
	 sub	 ax,ax		; Find next free entry
  repne  scas	 UMBSEGS[di]	; Look for a match
	 jne	 short @F	; Jump if no room

	 mov	 PGROUP:[di-(type UMBSEGS)].ELO,ds ; Save segment of UMB LSEG
@@:
	 cmp	 dx,-1		; Check for end-of-the-chain
	 jne	 short LTL_NEXT ; Jump if there's more

	 mov	 ds:[0].LSEG_NEXT,bx ; Save as pointer to next
	 mov	 ax,ds		; Save segment of previous LSEG

	 mov	 ds,bx		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ds:[0].LSEG_PREV,ax ; Save as segment of previous LSEG

	 REGREST <es,ds,di,dx,cx,bx,ax> ; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LINK_TLSEG endp 		; End LINK_TLSEG procedure
	 NPPROC  UNLINK_TLSEG -- Unlink temporary LSEG
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Unlink LSEG we temporarily hooked up.  If we're going resident,
we'll copy PGROUP:LSEG to its final destination and hook it up later.

While we're strolling through the LSEG chain, check for any UMB
LSEG entries that weren't there before.  If we find any, set the
@LSEG_UMB flag.  This tells Maximize to let the program load itself
high.

|

	 REGSAVE <ax,bx,cx,dx,di,ds,es> ; Save

	 push	 ds		; Get PGROUP
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler

	 mov	 dx,LOADSEG	; Get start of LSEG chain (always present)
	 sub	 bx,bx		; Segment of our LSEG (assume not found)
ULTL_NEXT:
	 mov	 ds,dx		; Address LSEG entry
	 assume  ds:nothing	; Tell the assembler

	 mov	 ax,dx		; Save segment of current entry
	 mov	 dx,ds:[0].LSEG_NEXT ; Get segment of next entry
	 cmp	 dx,LSEGSEG	; Izit our boy?
	 jne	 short @F	; Jump if not

	 mov	 bx,dx		; Save for later

@@:
; Check for UMB loaders.  Previously we've saved a list of UMB segments.
; If the number has increased or there are any new ones (we don't care
; about deletion and reshuffling) we'll set the @LSEG_UMB flag.
	 cmp	 ds:[0].LSEG_GRP,@GRPUMB ; Izit a UMB?
	 jne	 short @F

	 cld			; Set forward direction
	 lea	 di,PGROUP:UMBSEGS ; Address list
	 mov	 cx,@MAXUMBSEGS ; Length of list in words
  repne  scas	 UMBSEGS[di]	; Look for a match
	 je	 short @F	; Jump if found

	 or	 LSEG.LSEG_FLAG,@LSEG_UMB ; UMB loader - help yourself

@@:
	 cmp	 dx,-1		; Izit the end of the chain?
	 je	 short @F	; Jump if so

	 jmp	 short ULTL_NEXT ; Go around again

@@:
	 or	 bx,bx		; Did we find our temporary LSEG?
	 jz	 short ULTL_EXIT ; Jump if not (?)

	 mov	 ds,bx		; Address it
	 assume  ds:nothing	; Tell the assembler

	 mov	 ax,ds:[0].LSEG_PREV ; Get predecessor to temporary LSEG
	 mov	 dx,ds:[0].LSEG_NEXT ; Get its successor
	 cmp	 dx,-1		; Does next LSEG exist?
	 je	 short @F	; Jump if not

	 mov	 ds,dx		; Address next LSEG
	 assume  ds:nothing	; Tell the assembler

	 mov	 ds:[0].LSEG_PREV,ax ; Link to previous LSEG
@@:
	 mov	 ds,ax		; Address previous LSEG (always exists)
	 mov	 ds:[0].LSEG_NEXT,dx ; Link with next LSEG

ULTL_EXIT:
	 and	 LSEG.LSEG_FLAG,not @LSEG_INPRO ; Mark as not busy

	 REGREST <es,ds,di,dx,cx,bx,ax> ; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

UNLINK_TLSEG endp		; End UNLINK_TLSEG procedure
	 NPPROC  LINK_LSEG -- Link Into LSEG Chain
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Link into LSEG chain

|

	 REGSAVE <ax,bx,cx,si,di,es> ; Save registers

; Clear LSEG_PREG and LSEG_EREG if not user-specified

	 test	 OPT_FLAG,@OPT_PREG ; Izit specified?
	 jnz	 short @F	; Jump if so

	 mov	 LSEG.LSEG_PREG,@NOTSPEC ; Clear it
@@:
	 test	 OPT_FLAG,@OPT_EREG ; Izit specified?
	 jnz	 short @F	; Jump if so

	 mov	 LSEG.LSEG_EREG,@NOTSPEC ; Clear it
@@:
	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short LINK_LSEG_GSIZE ; Jump if so

	 mov	 ax,EXEC_PRGMAC ; Get program MAC segment
	 inc	 ax		; Count in MAC para
	 mov	 LSEG.LSEG_OWNRHI,ax ; Save as high DOS owner entry
	 mov	 LSEG.LSEG_INSTLO,0 ; Mark as no low DOS memory seg
	 mov	 LSEG.LSEG_INSTLEN,0  ; Save as length of ...

	 jmp	 short LINK_LSEG_GSIZECOM ; Join common code

LINK_LSEG_GSIZE:
	 mov	 LSEG.LSEG_OWNRHI,0 ; Mark as no high DOS owner entry
	 mov	 ax,EXEC_INTMAC ; Get interrupt handler MAC segment
	 inc	 ax		; Count in MAC para
	 mov	 LSEG.LSEG_INSTLO,ax ; Save as low DOS memory seg

	 mov	 ax,LSEG.LSEG_RPARA ; Get # paras requested including INT block
	 mov	 LSEG.LSEG_INSTLEN,ax ; Save as length of low DOS memory seg
LINK_LSEG_GSIZECOM:

	 and	 LSEG.LSEG_FLAG,not @LSEG_XRES ; Clear non-resident flag
	 mov	 LSEG.LSEG_NEXT,-1 ; Clear pointer to next LSEG

	 test	 LCL_FLAG,@LCL_RES ; Did it go resident?
	 jnz	 short @F	; Jump if so

	 or	 LSEG.LSEG_FLAG,@LSEG_XRES ; Mark as non-resident in LSEG entry
@@:
; Copy LSEG to its final resting place

	 mov	 bx,LSEGSEG	; Get the LSEG segment
	 mov	 es,bx		; Address it
	 assume  es:nothing	; Tell the assembler about it
	 xor	 di,di		; ES:DI ==> destin
	 lea	 si,LSEG	; DS:SI ==> source
	 mov	 cx,size LSEG_STR ; # bytes to copy
     rep movsb			; Copy it

; Calculate the segment of LSEG and link into the chain

	 mov	 ax,LOADSEG	; Get first LSEG pointer (if any)

	 cmp	 ax,2		; Any previous link?
	 jbe	 short LINK_LSEG_1ST ; Not this time

; Search through the chain for the end and link into it

@@:
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es:[0].LSEG_NEXT ; Get next segment

	 cmp	 ax,-1		; Check for end-of-the-chain
	 jne	 short @B	; Jump if there's more

	 mov	 es:[0].LSEG_NEXT,bx ; Save as pointer to next
	 mov	 ax,es		; Save segment of previous LSEG

	 mov	 es,bx		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[0].LSEG_PREV,ax ; Save as segment of previous LSEG

	 jmp	 short LINK_LSEG_EXIT ; Join common exit code

LINK_LSEG_1ST:
	 call	 INFO_READ	; Read in INFO structure

	 mov	 LOADSEG,bx	; Save in data structure

	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 call	 INFO_WRITE	; Write it back out
LINK_LSEG_EXIT:
	 REGREST <es,di,si,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LINK_LSEG endp			; End LINK_LSEG procedure
;;;	    NPPROC  INFO_LON -- Turn On Load State
;;;	    assume  ds:nothing,es:nothing,ss:nothing
;;;
;;;	    REGSAVE <ax,bx,cx,dx,ds> ; Save registers
;;;
;;;	    push    cs		   ; Setup for data references
;;;	    pop     ds		   ; Address it
;;;	    assume  ds:PGROUP	   ; Tell the assembler about it
;;;
;;;	    mov     al,02h	   ; Access code for read/write
;;;	    DOSCALL @OPENF2,BASNAME ; Attempt to open base program device driver
;;;	    jc	    short @F	   ; Jump if not found
;;;
;;;	    mov     bx,ax	   ; Copy to handle register
;;;
;;;	    mov     al,03h	   ; Write to device
;;;	    mov     cx,1	   ; CX = # bytes in INFO structure
;;;	    mov     INFO_CTL,@CTL_LON ; Mark as load state on
;;;	    DOSCALL @IOCTL2,INFO_CTL ; Set IOCTL info from INFO
;;;
;;;	    DOSCALL @CLOSF2	   ; Close it up
;;;@@:
;;;	    REGREST <ds,dx,cx,bx,ax> ; Restore
;;;	    assume  ds:nothing	   ; Tell the assembler about it
;;;
;;;	    ret 		   ; Return to caller
;;;
;;;	    assume  ds:nothing,es:nothing,ss:nothing
;;;
;;;INFO_LON endp		   ; End INFO_LON procedure
;;;	    NPPROC  INFO_LOFF -- Turn Off Load State
;;;	    assume  ds:nothing,es:nothing,ss:nothing
;;;
;;;	    REGSAVE <ax,bx,cx,dx,ds> ; Save registers
;;;
;;;	    push    cs		   ; Setup for data references
;;;	    pop     ds		   ; Address it
;;;	    assume  ds:PGROUP	   ; Tell the assembler about it
;;;
;;;	    mov     al,02h	   ; Access code for read/write
;;;	    DOSCALL @OPENF2,BASNAME ; Attempt to open base program device driver
;;;	    jc	    short @F	   ; Jump if not found
;;;
;;;	    mov     bx,ax	   ; Copy to handle register
;;;
;;;	    mov     al,03h	   ; Write to device
;;;	    mov     cx,1	   ; CX = # bytes in INFO structure
;;;	    mov     INFO_CTL,@CTL_LOFF ; Mark as load state off
;;;	    DOSCALL @IOCTL2,INFO_CTL ; Set IOCTL info from INFO
;;;
;;;	    DOSCALL @CLOSF2	   ; Close it up
;;;@@:
;;;	    REGREST <ds,dx,cx,bx,ax> ; Restore
;;;	    assume  ds:nothing	   ; Tell the assembler about it
;;;
;;;	    ret 		   ; Return to caller
;;;
;;;	    assume  ds:nothing,es:nothing,ss:nothing
;;;
;;;INFO_LOFF endp		   ; End INFO_LOFF procedure
	 NPPROC  KEYWAIT -- Wait For Keyboard Acknowledgement
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Purge the keyboard buffer and wait for a key press -- discard the key

On exit:

AX	 =	 last key pressed

|

KEYWAIT_NEXT:
	 KEYCALL @GETKST	; Get buffer state
	 jz	 short KEYWAIT_PAUSE ; Nothing available

	 KEYCALL @GETKEY	; Get the key

	 jmp	 KEYWAIT_NEXT	; Go around again

KEYWAIT_PAUSE:
	 KEYCALL @GETKEY	; Get the key

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

KEYWAIT  endp			; End KEYWAIT procedure
	 NPPROC  NEWLINE -- Ensure On Newline
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Ensure we're on a new line

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 VIDCALL @GETINF	; Get display page into BH
	 VIDCALL @GETPOS	; Get current cursor position into (DH,DL)
				; (CH,CL) = cursor type

	 cmp	 dl,0		; Izit in column 0?
	 je	 short NEWLINE_EXIT ; Jump if so

	 mov	 al,CR		; Ensure it's in column 0
	 VIDCALL @SETTTY	; Request video service
	 mov	 al,LF		; Ensure it's on a new line
	 VIDCALL @SETTTY	; Request video service
NEWLINE_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

NEWLINE  endp			; End NEWLINE procedure
	 NPPROC  NOLOAD_PRESS -- Load Failed, Press Any Key
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Tell the user that the load failed, and to press any key to continue

On entry:

CS:AX	 ==>	 ASCIIZ string with load failed error message

|

	 REGSAVE <ax>		; Save register

	 test	 OPT_FLAG,@OPT_QUIET ; Should we be quiet?
	 jnz	 short @F	; Yes

	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message
@@:
	 test	 OPT_FLAG,@OPT_NOPAUSE ; Should we pause?
	 jnz	 short @F	; Not this time

	 lea	 ax,AZS_PRESS	; Press a key
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

; Purge the keyboard buffer and wait for a key press -- discard the key

	 call	 KEYWAIT	; Wait for an acknowledgement
				; Return with key in AX
@@:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

NOLOAD_PRESS endp		; End NOLOAD_PRESS procedure
if @OEM_FLEX
	 NPPROC  REST67 -- Restore INT 67h If Intercepted
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Restore INT 67h if intercepted.  If we're loading high with FLEXFRAME,
we'll call CHECK_EMSPTE to turn EMS services back on.

|

	 REGSAVE <cx,si,di,es>	; Save registers

	 test	 LCL_FLAG,@LCL_IN67 ; Izit installed?
	 jz	 short REST67_EXIT ; No, ignore INT 67h

	 call	 CHECK_EMSPTE	; See if PTEs in page frame were accessed
	 jc	 short @F	; Jump if so

	 test	 LCL_FLAG,@LCL_XFLEX ; Izit disallowed?
	 jnz	 short @F	; Jump if so

	 test	 LSEG.LSEG_FLAG,@LSEG_XEMS ; Was there an EMS error?
	 jnz	 short @F	; Jump if so

	 or	 LSEG.LSEG_FLAG,@LSEG_FLEX ; Mark as FLEXFRAME-able
@@:

	 les	 di,OLDINT67_PATCH ; Address patch point
	 assume  es:nothing	; Tell the assembler

	 lea	 si,PGROUP:INT67 ; Address original contents of patch point
	 mov	 cx,@PATCHLEN	; Length of patch point

	 cld			; Ensure string ops go forward
	 pushf			; Save

	 cli			; Nobody move
   rep	 movs	 es:[di].LO,PGROUP:INT67[si].LO ; Restore contents of patch

	 popf			; Restore contents of IF

	 and	 LCL_FLAG,not @LCL_IN67 ; Mark as no longer installed
REST67_EXIT:
	 call	 CHECK_EMSPTE	; Turn EMS services back on (ignore result)

	 REGREST <es,di,si,cx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REST67	 endp			; End REST67 procedure
endif				; IF @OEM_FLEX
	 NPPROC  SET_EES -- Set Enter Exec State for DOS 5.x
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Set Enter Exec State for DOS 5.x

|

	 REGSAVE <ax,dx,ds>	; Save registers

	 push	 cs		; Setup DS for data references
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 cmp	 DOSVER,0500h	; Izit DOS 5.x or later?
	 jb	 short SET_EES_EXIT ; Jump if not

	 test	 LCL_FLAG,@LCL_EXE ; Izit an .EXE file?
	 jz	 short @F	; Jump if not

	 mov	 EES.EES_FLAGS,@EES_EXE ; Mark as an EXE program
@@:
	 mov	 EES.EES_NAME.VOFF,offset ds:LCL_PATH ; Save ptr to program name
	 mov	 EES.EES_NAME.VSEG,ds

	 mov	 ax,EXEC_PSP	; Get segment # of PSP
	 mov	 EES.EES_PSP,ax ; Save in EES structure

	 mov	 ax,FILE_HEAD.EXE_IP ; Get starting IP
	 mov	 EES.EES_CSIP.VOFF,ax ; Save in EES structure

	 mov	 ax,FILE_HEAD.EXE_CS ; Get starting CS
	 mov	 EES.EES_CSIP.VSEG,ax ; Save in EES structure

	 mov	 ax,LSEG.LSEG_LSIZE.ELO ; Get the load size
	 mov	 EES.EES_SIZE.ELO,ax ; Save in EES structure
	 mov	 ax,LSEG.LSEG_LSIZE.EHI ; ...
	 mov	 EES.EES_SIZE.EHI,ax ; Save in EES structure

; Ignore the error return as versions of DOS 5.00 prior to 409c
; don't implement this call and instead return CF=1, AX=0001.

	 mov	 al,05h 	; Function code for EnterExecState
	 DOSCALL @EXEC,EES	; Enter Exec State for this program
;;;;;;;; jnc	 short SET_EES_EXIT ; Jump if all went well
;;;;;;;;
;;;;;;;; int	 03h		; Call our debugger
SET_EES_EXIT:
	 REGREST <ds,dx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SET_EES  endp			; End SET_EES procedure

NCODE	 ends			; End NCODE segment

	 MEND			; End LOADCOM module
