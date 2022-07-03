;' $Header:   P:/PVCS/MAX/386MAX/UTIL_COM.ASV   1.3   08 Jul 1998 12:30:06   BOB  $
	 title	 UTIL_COM -- 386MAX Common Utility Program
	 page	 58,122
	 name	 UTIL_COM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Stack   segment STACK,	byte-aligned,  stack,  class 'prog'
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Data    segment SEG_LEN, word-aligned,  public, class 'data'
	       Data    segment SEG_TAB, word-aligned,  public, class 'data'
	       Data    segment SEG_ACT, word-aligned,  public, class 'data'
	       Data    segment SEG_DSP, byte-aligned,  public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Program segment ACODE,	byte-aligned,  public, class 'zdata'
	       Data    segment ADATA,	dword-aligned, public, class 'zdata'
	       Program segment UCODE,	byte-aligned,  public, class 'ucode'
	       Data    segment UDATA,	dword-aligned, public, class 'udata'
	       Data    segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Program derived from:  None.

Original code by:  Bob Smith, April, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include VIDCALL.INC
	 include KEYCALL.INC
	 include VIDATTR.INC
	 include CPUFLAGS.INC
	 include ASCII.INC
	 include IOCTL.INC
NOVER_HTU = 1
	 include VERSION.INC
	 include 386.INC
	 include PTR.INC

	 include QMAX_OEM.INC
	 include QMAX_CTL.INC
	 include QMAX_FMT.INC
if @OEM_BETA
	 include VERSBETA.INC
endif				; IF @OEM_BETA

if @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 VERS_HP:abs
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
.list

PGROUP	 group	 STACK,CODE,DATA,NCODE,NDATA,SEG_LEN,SEG_TAB,SEG_ACT,SEG_DSP,ACODE,ADATA,UCODE,UDATA,ZZTAIL

; The following segment both positions class 'prog' segments lower in
; memory than others so the first byte of the resulting .COM file is
; in the CODE segment, as well as satisfies the LINKer's need to have
; a stack segment.

STACK	 segment use16 byte stack 'prog' ; Start STACK segment
STACK	 ends			; End STACK segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 MSG_COPY:byte
	 extrn	 MSG_DEFUNCT:byte
	 extrn	 MSG_NOT386:byte
	 extrn	 MSG_NOT386_LEN:abs

	 extrn	 MSG_NOTPRES:byte
	 extrn	 MSG_NOTPRES_LEN:abs
	 extrn	 MSG_NOTVER:byte
	 extrn	 MSG_NOTVER_LEN:abs

	 extrn	 MSG_NOTFND:byte
	 extrn	 MSG_NOTFND_LEN:abs

if @OEM_HIFILL
	 extrn	 MSG_CLOSMAC:byte
	 extrn	 MSG_CLOSMAC_LEN:abs
endif				; IF @OEM_HIFILL

	 public  UTL_FLAG
	 include QMAX_UTL.INC
UTL_FLAG dw	 0		; Local utility program flags

	 public  INFO_CTL,INFO,INFOSIZE
	 include QMAXINFO.INC
	 db	 ?		; Force even alignment for INFO_STR
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
INFOSIZE equ	 size INFO_STR

	 public  QMAX_VER,DEVICE_CS,QMAX_HI,OWNER,GLB_FLAG
	 public  LOWSIZE,OVRSIZE,EXTSIZE,EMMSIZE,PRGSIZE,MAPSIZE
	 public  PORT67,CMDCOM_PAR,OLDDOS,SYS_FLAG,P1ST_MAC,LCL_FLAG,POVR_MAC
	 public  CMD_FLAG,CM2_FLAG,LOADSEG,SHDSIZE,XSHDSIZE,ONFSIZE
	 public  SYSROM_START,DB3_FLAG,TOTSIZE
QMAX_VER equ	 INFO.INFO_VER	;      Version #
	 include QMAX_HDM.INC
	 public  HDM_FLAG
DEVICE_CS equ	 INFO.INFO_QMAX ;  1 = Segment of device driver (non-relocatable)
QMAX_HI  equ	 INFO.INFO_HIGH ;  2 = Starting segment #
OWNER	 equ	 INFO.INFO_OWNR ;  3 = Owner of block
GLB_FLAG equ	 INFO.INFO_GLB	;  4 = Global flags (see QMAX_GLB.INC for equates)
LOWSIZE  equ	 INFO.INFO_LOW	;  5 = LOWSIZE in 1KB
				;  6 = VIDSIZE
OVRSIZE  equ	 INFO.INFO_OVR	;  7 = OVRSIZE
				;  8 = EXTSIZE (obsolete)
				;  9 = EMMSIZE (obsolete)
PRGSIZE  equ	 INFO.INFO_PRG	; 10 = PRGSIZE
MAPSIZE  equ	 INFO.INFO_MAP	; 11 = MAPSIZE
				; 12 = TOTSIZE (obsolete)
				; 13 = PORT15
PORT67	 equ	 INFO.INFO_P67	; 14 = I/O port for INT 67h communications
CMDCOM_PAR equ	 INFO.INFO_COMR ; 15 = CMDCOM_PAR
OLDDOS	 equ	 INFO.INFO_OLD	; 16 = Size of original DOS memory in paras
SYS_FLAG equ	 INFO.INFO_SYS	; 17 = SYS_FLAG
P1ST_MAC equ	 INFO.INFO_PMAC ; 18 = Pointer to last intial entry in MAC chain
LCL_FLAG equ	 INFO.INFO_LCL	; 19 = LCL_FLAG
				; 20 = DBG_FLAG (Debug flags, part 1)
				; 21 = DB2_FLAG (Debug flags, part 2)
				; 22 = Segment of first MAC below video buffers
POVR_MAC equ	 INFO.INFO_POVR ; 23 = Segment of first MAC entry in high DOS memory
CMD_FLAG equ	 INFO.INFO_CMD	; 24 = Command flags (see QMAX_CMD.INC for equates)
CM2_FLAG equ	 INFO.INFO_CM2	; 25 = CM2_FLAG
				; 26 = CM3_FLAG
LOADSEG  equ	 INFO.INFO_LSEG ; 27 = 386LOAD chain segment
	 include QMAX_CMD.INC
				; 28 = OFFSIZE
SHDSIZE  equ	 INFO.INFO_SHD	; 29 = SHDSIZE
XSHDSIZE equ	 INFO.INFO_XSHD ; 30 = XSHDSIZE
				; 31 = SWPSIZE
ONFSIZE  equ	 INFO.INFO_ONF	; 32 = ONFSIZE
SYSROM_START equ INFO.INFO_SROM ; 33 = Starting segment of system ROM
DB3_FLAG equ	 INFO.INFO_DB3	; 34 = DB3_FLAG
				; 35 = OLDINT21_VEC
				; 36 = CURINT67_VEC
TOTSIZE  equ	 INFO.INFO_TOT	; 37 = TOTSIZE
EXTSIZE  equ	 INFO.INFO_EXT	; 38 = EXTSIZE
EMMSIZE  equ	 INFO.INFO_EMM	; 39 = EMMSIZE


	 public  DEV_HNDL
DEV_HNDL dw	 ?		; Device handle

	 public  DOSVER
DOSVER	 dw	 ?		; DOS version # (in comparison format)

@DEVLEN  sizestr @OEM_IOCTL
@DEVNAME substr  @OEM_IOCTL,2,@DEVLEN-2

	 rept	 10-@DEVLEN
@DEVNAME catstr  @DEVNAME,<$>	; Append a dollar sign
	 endm			; RPT

; Because eight-character device names are confused with file names,
; we must truncate the last character and insert a $.

@DEVNAME substr  @DEVNAME,1,7	; Drop off the last character
@DEVNAME catstr  @DEVNAME,<$>	; Append a dollar sign

@DEVNAME catstr  <'>,@DEVNAME   ; Prefix a quote mark
@DEVNAME catstr  @DEVNAME,<'>   ; Append a quote mark

	 public  DEVNAME
DEVNAME  db	 @DEVNAME,0	; Device driver name

COMMENT& ; *DELETEME*
;;;if @OEM_SYS ne @OEMSYS_ILIM
	 public  MSG_SEP
MSG_SEP  db	 ', '           ; Separator between keywords in DISP_NOTFND
MSG_SEP_LEN equ  $-MSG_SEP	; Length of ...

	 public  MSG_WRAP
MSG_WRAP db	 CR,LF,'    '   ; Wrap between lines of keywords in DISP_NOTFND
MSG_WRAP_LEN equ $-MSG_WRAP	; Length of ...
&

	 public  MSG_CRLF
MSG_CRLF db	 CR,LF		; Ending CR/LF for DISP_NOTFND
MSG_CRLF_LEN equ $-MSG_CRLF	; Length of ...
	 db	 EOS		; In case it's used by @STROUT
;;;endif			   ; IF @OEM_SYS ne @OEMSYS_ILIM

	 public  NUMBERS_HI
NUMBERS_HI db	 '0123456789ABCDEF' ; Conversion table for BIN2BASE

	 public  LCLSTK,LCLSTKZ
	 even			; Optimize stack accesses
LCLSTK	 dw	 400h dup (?)
LCLSTKZ  dw	 0		; Return offset

	 public  PBID_MSG,ID_LEN
PBID_MSG dw	 0		; Pointer to ID message
ID_LEN	 dw	 0		; Length of ID message

DATA	 ends			; End DATA segment


SEG_TAB  segment use16 word public 'data' ; Start SEG_TAB segment
	 assume  ds:PGROUP

	 extrn	 ARG_TAB:word
	 extrn	 NARGS:abs
	 extrn	 SWITCH_HELP:byte
	 extrn	 SWHELP_LEN:abs

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment use16 word public 'data' ; Start SEG_LEN segment
	 assume  ds:PGROUP

	 extrn	 ARG_LEN:word

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment use16 word public 'data' ; Start SEG_ACT segment
	 assume  ds:PGROUP

	 extrn	 ARG_ACT:word

SEG_ACT  ends			; End SEG_ACT segment


SEG_DSP  segment use16 byte public 'data' ; Start SEG_DSP segment
	 assume  ds:PGROUP

	 extrn	 ARG_DSP:byte

SEG_DSP  ends			; End SEG_DSP segment



NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
NCODE	 ends			; End NCODE segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 LINECNT:word

	 include QMAX_IDN.INC

NDATA	 ends			; End NDATA segment


ADATA	 segment use16 dword public 'zdata' ; Start ADATA segment
ADATA	 ends			; End ADATA segment


ACODE	 segment use16 byte public 'zdata' ; Start ACODE segment
	 assume  cs:PGROUP

	 extrn	 STROUT:near
	 extrn	 CHECK_LINE:near

	 NPPROC  CHECK_INFO -- Check IDN Information
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Check and display IDN information.

On exit:

CF	 =	 0 if all went OK
	 =	 1 if something went wrong
CX	 =	 1 if a one-line message was displayed
	 =	 0 if not

|

	 REGSAVE <cx,ds>	; Save registers

	 push	 cs		; Ensure DS points to IDENTIFY
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

ife @OEM_INST
	 cmp	 IDENT_CHK,0	; Has it been filled in as yet?
	MJ e	 CHECK_INFO_EXIT ; Jump if not (note CF=0)
endif

	 CHKIDN  @STD_OUT,@STD_ERR,PBID_MSG,ID_LEN ; Check and save message pointer
				; Return with CX and CF significant
	 jcxz	 CHECK_INFO_EXIT ; Jump if no message displayed

	 pushf			; Save CF

	 dec	 cx		; Less one because CHECK_LINE adds one
	 add	 LINECNT,cx	; Include in total line count
;;	 call	 CHECK_LINE	; Count in another line and check for pause

	 popf			; Restore CF
CHECK_INFO_EXIT:
	 REGREST <ds,cx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_INFO endp 		; End CHECK_INFO procedure

ACODE	 ends			; End ACODE segment


UCODE	 segment use16 byte public 'ucode' ; Start UCODE segment

	 extrn	 HEX2BIN:near

UCODE	 ends			; End UCODE segment


UDATA	 segment use16 dword public 'udata' ; Start UDATA segment

	 extrn	 IGN_PSP:word

UDATA	 ends			; End UDATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

ZZTAIL	 segment use16 dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 public  PIDENT
PIDENT	 dw	 PGROUP:IDENTIFY-100h ; Point to identification string
	 dw	 0		; ...less size of PSP

	 public  ZTAIL
ZTAIL	 label	 byte

ZZTAIL	 ends			; End ZZTAIL segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

if @OEM_WTK and @OEM_SYS eq @OEMSYS_LHY
	 extrn	 DISP_WTK:near
endif				; IF @OEM_WTK and @OEM_SYS eq @OEMSYS_LHY

if @OEM_LIST
	 extrn	 ACT_LIST:near
endif				; IF @OEM_LIST

if @OEM_WIN3
	 extrn	 WINOUT_INIT:near
endif				; IF @OEM_WIN3

.xlist
	 public  PSP_ENVIR_PTR,PSP_CTRL_PSP
	 include PSP.INC	; Define & skip over PSP area for .COM program
.list
	 NPPROC  UTIL -- 386MAX Utility Program
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	 lea	 sp,LCLSTKZ	; Use our own stack

; Get and save DOS version #

	 DOSCALL @DOSVER	; AL = major
				; AH = minor
				; BX=CX=0
	 xchg	 al,ah		; Swap to comparison order
	 mov	 DOSVER,ax	; Save for later use

	 call	 CHECK_CPUID	; Ensure we're on a 386 processor
	MJ c	 UTIL_ERR_EXIT	; Join common error exit code

	 call	 CHECK_INFO	; Check and display IDN info
	MJ c	 UTIL_ERR_EXIT	; Jump if something went wrong

; See if we're already installed

	 mov	 al,02h 	; Access code for read/write
	 DOSCALL @OPENF2,DEVNAME ; Attempt to open 386MAX device driver
	 jnc	 short UTIL1	; That worked
UTIL_ERR:
	 call	 DISP_COPY	; Display copyright notice

	 mov	 cx,MSG_NOTPRES_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOTPRES ; Tell 'em 386MAX.SYS is not present
	 call	 CHECK_LINE	; Count in another line and check for pause

	 jmp	 UTIL_ERR_EXIT	; Join common error exit code

UTIL_VER:
	 call	 DISP_COPY	; Display copyright notice

	 mov	 cx,MSG_NOTVER_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOTVER ; Tell 'em it's the wrong version #
	 call	 CHECK_LINE	; Count in another line and check for pause

	 jmp	 UTIL_ERR_EXIT	; Join common error exit code

UTIL1:
	 mov	 DEV_HNDL,ax	; Save for later use
	 mov	 bx,ax		; Copy to handle register

; Ensure it's a device

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 jc	 short UTIL_ERR ; Something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 short UTIL_ERR ; No???

	 call	 INFO_READ	; Read in INFO structure

	 cmp	 INFO.INFO_SIGN.ELO[0],'83' ; Our signature?
	 jne	 short UTIL_ERR ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[2],'M6' ; Our signature?
	 jne	 short UTIL_ERR ; Not this time

	 cmp	 INFO.INFO_SIGN.ELO[4],'XA' ; Our signature?
	 jne	 short UTIL_ERR ; Not this time

	 cmp	 INFO.INFO_VER[0],VERS_H ; Same high version # ?
	 jne	 short UTIL_VER ; Not this time

	 mov	 al,VERS_T	; Get mid-digit of version #
	 mov	 ah,VERS_U	; Get low-digit of version #

	 cmp	 ax,INFO.INFO_VER.ELO[2] ; Same low numbers?
	 jne	 short UTIL_VER ; Not this time

if @OEM_MAPMEM or @OEM_TIMEMEM or @OEM_ROMSCAN or @OEM_MAPEMS or @OEM_MAPDEV

; Determine whether or not standard output is redirected

	 mov	 bx,@STD_OUT	; Copy to handle register
	 mov	 al,0		; Code to read device information
	 DOSCALL @IOCTL2	; Read I/O control
	 jc	 short @F	; Jump on error

	 and	 dx,@IOCTL_DEV or @IOCTL_COT ; Isolate device output bits

	 cmp	 dx,@IOCTL_DEV or @IOCTL_COT ; Izit standard output?
	 jne	 short @F	; Jump if not

	 or	 UTL_FLAG,@UTL_COT ; Mark as console output
@@:
endif				; IF @OEM_MAPMEM or @OEM_TIMEMEM or @OEM_ROMSCAN or @OEM_MAPEMS or @OEM_MAPDEV

if @OEM_WIN3
	 call	 WINOUT_INIT	; Set WINVXD_VEC and WINRUN
	 jc	 short UTIL_ERR_EXIT ; Jump if something went wrong

endif				; IF @OEM_WIN3
	 call	 CHECK_ARGS	; See if there are any command line args
	 mov	 al,0		; Return code = 0 if no errors
	 jnc	 short UTIL_EXIT ; Jump if no errors
UTIL_ERR_EXIT:
	 mov	 al,-1		; Give 'em a big reason
UTIL_EXIT:
	 call	 DISP_COPY	; Display copyright notice

	 DOSCALL @EXITRC	; Return to DOS with reason code in AL

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UTIL	 endp			; End UTIL procedure
	 NPPROC  DISP_COPY -- Display copyright notice & clear it
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display copyright notice via STROUT, then set its first byte to 0.

|

if @OEM_SYS ne @OEMSYS_HPRS
	 cmp	 MSG_COPY,0	; Izit already displayed?
	 je	 short DC_EXIT	; Jump if so

	 REGSAVE <bx,dx>	; Save registers

	 lea	 dx,MSG_COPY	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX

	 mov	 dx,PBID_MSG	; Get pointer to ID message
	 or	 dx,dx		; Izit NULL?
	 jz	 short @F	; Jump if so

	 mov	 bx,dx		; Get pointer
	 add	 bx,ID_LEN	; Add length of message
	 mov	 PGROUP:[bx].LO,EOS ; Set up for STROUT

	 call	 STROUT 	; Display string with line checking
				; (Lines in ID message - 1 already added
				; to LINECNT)
@@:
	 REGREST <dx,bx>	; Restore

	 mov	 MSG_COPY,0	; Zap it so we don't display it twice
DC_EXIT:
endif				; IF @OEM_SYS ne @OEMSYS_HPRS
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_COPY endp			; End DISP_COPY procedure
	 NPPROC  CHECK_ARGS -- Check Command Line Arguments
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if there are any command line arguments.

On exit:

CF	 =	 0 if none
	 =	 1 if there were some

|

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save registers

	 lea	 si,PSP_PARM_STRING ; DS:SI ==> command line

	 call	 STR_LOWER	; Convert string to lowercase
	 call	 SKIP_WHITE	; Skip over white space

	 dec	 si		; Back up to non-white space

	 cmp	 al,CR		; End of the line?
	 je	 short CHECK_ARGS_DEF ; Yes, take the default action

	 cmp	 ds:[si].ELO,'sp' ; Are bytes 1&2 'PS' ?
	 jne	 short CHECK_ARGS_NEXTCMD ; No

	 cmp	 ds:[si].EHI,'=p' ; Are bytes 3&4 'P=' ?
	 jne	 short CHECK_ARGS_NEXTCMD ; Nope

	 add	 si,4		; Skip over 'PSP='
	 call	 HEX2BIN	; Return value in AX and CF=0 if OK
	 jc	 CHECK_ARGS_ERR ; Sound the alarum

	 mov	 IGN_PSP,ax	; PSP value to ignore
	 jmp	 short CHECK_ARGS_NEXTTOKN ; Get next token

CHECK_ARGS_NEXTCMD:
	 mov	 cx,NARGS	; Get # different arguments
	 xor	 bx,bx		; Zero index register
CHECK_ARGS_NEXTKWD:
	 REGSAVE <cx,si>	; Save registers
	 mov	 di,ARG_TAB[bx] ; Get pointer to keyword
	 mov	 cx,ARG_LEN[bx] ; Get its length
    repe cmpsb			; Compare 'em
	 REGREST <si,cx>	; Restore
	 je	 short CHECK_ARGS_FOUND ; Jump if found

	 add	 bx,type ARG_TAB ; Skip to next keyword

	 loop	 CHECK_ARGS_NEXTKWD ; Jump if more arguments to check
CHECK_ARGS_NOTFND:

if @OEM_SYS eq @OEMSYS_ILIM
	 test	 CMD_FLAG,@CMD_XHI ; High DOS memory allowed?
	 jnz	 short CHECK_ARGS_DEF ; No, convert all arguments to LIST
endif				; IF @OEM_SYS eq @OEMSYS_ILIM

	 call	 DISP_NOTFND	; Display the "Not found" message

	 jmp	 short CHECK_ARGS_ERR ; Join common error code

CHECK_ARGS_DEF:
if @OEM_LIST
	 call	 DISP_COPY	; Display copyright notice

	 call	 ACT_LIST	; Take appropriate action
	 jc	 short CHECK_ARGS_ERR ; Something went wrong
else
if @OEM_WTK and @OEM_SYS eq @OEMSYS_LHY
	 call	 DISP_WTK	; Display Weitek state
endif				; IF @OEM_WTK and @OEM_SYS eq @OEMSYS_LHY
	 jmp	 short CHECK_ARGS_ERR ; Join common error code
endif				; IF @OEM_LIST

;;;if @OEM_SYS ne @OEMSYS_ILIM
	 jmp	 short CHECK_ARGS_CLC ; Join common OK code

CHECK_ARGS_FOUND:
	 add	 si,ARG_LEN[bx] ; Skip over argument

	 cmp	 [si].LO,' '    ; Ensure next value is white space
	 je	 short CHECK_ARGS_ACT ; It's OK

	 cmp	 [si].LO,TAB	; ...or white space
	 je	 short CHECK_ARGS_ACT ; It's OK

	 cmp	 [si].LO,'/'    ; ...or a slash
	 je	 short CHECK_ARGS_ACT ; It's OK

	 cmp	 [si].LO,CR	; ... or a line ending
	 jne	 short CHECK_ARGS_NOTFND ; Too bad
CHECK_ARGS_ACT:
	 shr	 bx,1		; Get pointer into byte array
	 test	 ARG_DSP[bx],80h ; Izit one we suppress copyright notice for?
	 jnz	 short @F	; Jump if so

	 call	 DISP_COPY	; Display copyright notice and user info

@@:
	 shl	 bx,1		; Convert BX back into a word pointer
	 call	 ARG_ACT[bx]	; Take appropriate action
	 jc	 short CHECK_ARGS_ERR ; Something went wrong (note CF=1)

CHECK_ARGS_NEXTTOKN:
	 call	 SKIP_WHITE	; Skip over white space

	 dec	 si		; Back up to non-white space

	 cmp	 al,CR		; End of the line?
	 jne	 short CHECK_ARGS_NEXTCMD ; Process next command
CHECK_ARGS_CLC:
;;;endif			   ; IF @OEM_SYS ne @OEMSYS_ILIM
	 clc			; Indicate all went well

	 jmp	 short CHECK_ARGS_EXIT ; Join common exit code

CHECK_ARGS_ERR:
	 stc			; Indicate something went wrong
CHECK_ARGS_EXIT:
	 REGREST <di,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ARGS endp 		; End CHECK_ARGS procedure
;;;if @OEM_SYS ne @OEMSYS_ILIM
	 NPPROC  DISP_NOTFND -- Display Not Found Message
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display "Not found" message

|

	 pusha			; Save registers

; Display the message header

	 mov	 cx,MSG_NOTFND_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOTFND ; No, tell 'em so

	 call	 CHECK_LINE	; Count in another line and check for pause

	 call	 ACT_HELP	; Display help text

	 popa			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_NOTFND endp		; End DISP_NOTFND procedure
;;;endif			   ; IF @OEM_SYS ne @OEMSYS_ILIM
;;;if @OEM_SYS ne @OEMSYS_ILIM
	 NPPROC  UPPERCASE -- Convert DS:DX for CX Bytes to Uppercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert text to uppercase

On entry:

DS:DX	 ==>	 text to convert
CX	 =	 # bytes in text to convert

|

	 REGSAVE <ax,cx,si>	; Save registers

	 mov	 si,dx		; DS:SI ==> text to convert
UPPERCASE_NEXT:
	 lodsb			; Get next byte

	 cmp	 al,'a'         ; Test for conversion of alpha to upper case
	 jb	 short UPPERCASE_LOOP ; Not this time

	 cmp	 al,'z'         ; Check against upper limit
	 ja	 short UPPERCASE_LOOP ; Not this time

	 add	 al,'A'-'a'     ; Convert alpha to lower case
	 mov	 ds:[si-1].LO,al ; Save back into text
UPPERCASE_LOOP:
	 loop	 UPPERCASE_NEXT ; Jump if more etxt to convert

	 REGREST <si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UPPERCASE endp			; End UPPERCASE procedure
;;;endif			   ; IF @OEM_SYS ne @OEMSYS_ILIM
;;;if @OEM_SYS ne @OEMSYS_ILIM
	 NPPROC  LOWERCASE -- Convert AL to Lowercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 cmp	 al,40h 	; Test for conversion of alpha to lower case
	 jb	 short LOWERCASE_EXIT ; Not this time

	 or	 al,20h 	; Convert alpha to lower case
LOWERCASE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

LOWERCASE endp			; End LOWERCASE procedure
;;;endif			   ; IF @OEM_SYS ne @OEMSYS_ILIM
if @OEM_SYS eq @OEMSYS_RET
	 NPPROC  ACT_VER
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display the version # of 386MAX (already done by copyright notice)

|

	 call	 CHECK_INFO	; Check and display IDN info
				; Return with CF significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_VER  endp			; End ACT_VER procedure
endif				; IF @OEM_SYS eq @OEMSYS_RET
	 NPPROC  ACT_HELP
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display help screen showing all options and keywords.

|

	 pusha			; Push'em

	 mov	 cx,SWHELP_LEN	; CX = # bytes in message
	 mov	 bx,@STD_OUT	; Send to standard output handle
	 DOSCALL @WRITF2,SWITCH_HELP ; Display the message

	 call	 CHECK_LINE	; Count in another line and check for pause

	 call	 DISP_COPY	; Display copyright notice at end

	 popa			; Pop'em

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_HELP endp			; End ACT_HELP procedure
;;;if @OEM_SYS ne @OEMSYS_ILIM
	 NPPROC  STR_LOWER -- Convert String to Lowercase
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

DS:SI	 ==>	 command line

|

	 REGSAVE <ax,si>	; Save registers
STR_LOWER_NEXT:
	 lodsb			; Get next character

	 cmp	 al,CR		; End of the line?
	 je	 short STR_LOWER_EXIT ; Yes

	 call	 LOWERCASE	; Convert AL to lowercase
	 mov	 [si-1],al	; Save back

	 jmp	 STR_LOWER_NEXT ; Go around again

STR_LOWER_EXIT:
	 REGREST <si,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

STR_LOWER endp			; End STR_LOWER procedure
;;;endif			   ; IF @OEM_SYS ne @OEMSYS_ILIM
;;;if @OEM_SYS ne @OEMSYS_ILIM
	 NPPROC  SKIP_WHITE -- Skip Over White Space
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 lodsb			; Get next character

	 cmp	 al,' '         ; Izit a blank?
	 je	 short SKIP_WHITE ; Yes, so go around again

	 cmp	 al,TAB 	; Izit a TAB?
	 je	 short SKIP_WHITE ; Yes, so go around again

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SKIP_WHITE endp 		; End SKIP_WHITE procedure
;;;endif			   ; IF @OEM_SYS ne @OEMSYS_ILIM
;;;if @OEM_SYS ne @OEMSYS_ILIM
	 NPPROC  ARGNOMORE -- Ensure No More Arguments On Command Line
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure there are no more arguments on the command line

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,si> ; Save registers

	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 al,CR		; End of the line?
	 je	 short ARGNOMORE_EXIT ; Yes, so that's OK (note CF=0)

	 call	 DISP_NOTFND	; Display the "Not found" message

	 stc			; Note something went wrong
ARGNOMORE_EXIT:
	 REGREST <si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ARGNOMORE endp			; End ARGNOMORE procedure
;;;endif			   ; IF @OEM_SYS ne @OEMSYS_ILIM
	 NPPROC  BIN2BASE -- Convert From Binary to Specified Base
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIN2BASE -- Convert the number in AX to ASCII in base CX storing the
low-order digit of the # at ES:DI.

On exit:

ES:DI	 ==>	 next byte to left of the number

|

	 REGSAVE <ax,cx,dx,si,ds,es> ; Save all registers

	 push	 cs		; Set for MOVSB below
	 pop	 ds		; Now DS addresses NUMBERS_HI
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 cs		; Set for DI
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 pushf			; Save all flags
	 std			; Direction backwards for MOVSB
BIN2BASE_LOOP:
	 xor	 dx,dx		; Zero high-order word for division
	 div	 cx		; Divide by number base
				; DX has remainder, AX has quotient
	 lea	 si,NUMBERS_HI	; Get address of table
	 add	 si,dx		; Offset into table

S16	 movsb			; Store in result

	 and	 ax,ax		; Check for zero quotient
	 jnz	 short BIN2BASE_LOOP ; Not done yet
BIN2BASE_EXIT:
	 popf			; Restore flags

	 REGREST <es,ds,si,dx,cx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2BASE endp			; End BIN2BASE procedure
	 NPPROC  BIND2BASE -- Convert From Binary to Specified Base
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

BIND2BASE -- Convert the number in EAX to ASCII in base CX storing the
low-order digit of the # at ES:DI.

On exit:

ES:DI	 ==>	 next byte to left of the number

|

	 REGSAVE <eax,ecx,edx,si,ds,es> ; Save registers

	 push	 cs		; Set for MOVSB below
	 pop	 ds		; Now DS addresses NUMBERS_HI
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 cs		; Set for DI
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 pushf			; Save all flags
	 std			; Direction backwards for MOVSB

	 movzx	 ecx,cx 	; Zero to use as dword
BIND2BASE_LOOP:
	 xor	 edx,edx	; Zero high-order dword for division
	 div	 ecx		; Divide by number base
				; EDX has remainder, EAX has quotient
	 lea	 si,NUMBERS_HI	; Get address of table
	 add	 si,dx		; Offset into table

S16	 movs	 <es:[di].LO,NUMBERS_HI[si]> ; Store in result

	 and	 eax,eax	; Check for zero quotient
	 jnz	 short BIND2BASE_LOOP ; Not done yet
BIND2BASE_EXIT:
	 popf			; Restore flags

	 REGREST <es,ds,si,edx,ecx,eax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIND2BASE endp			; End BIND2BASE procedure
	 NPPROC  DB2BIT -- Convert AL to Bits At ES:DI
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL to bits at ES:DI

On entry:

AL	 =	 value to convert
ES:DI	 ==>	 output save area

On exit:

ES:DI	 ==>	 byte to right of converted number

|

	 REGSAVE <ax,cx>	; Save for a moment

	 mov	 cx,8		; # bits in a byte

	 mov	 ah,al		; Copy value
@@:
	 mov	 al,'0'         ; Assume it's a zero
	 shl	 ah,1		; Shift out high-order bit
	 adc	 al,0		; Add in if it's a one
	 stosb			; Save in output data area

	 loop	 @B		; Jump if more bits to convert

	 REGREST <cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DB2BIT	 endp			; End DB2BIT procedure
	 NPPROC  DB2HEX -- Convert AL to Hex At ES:DI
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL to hex at ES:DI

On entry:

AL	 =	 value to convert
ES:DI	 ==>	 output save area

On exit:

ES:DI	 ==>	 byte to right of converted number

|

	 push	 cx		; Save for a moment
	 mov	 cx,2		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 cx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DB2HEX	 endp			; End DB2HEX procedure
	 NPPROC  DW2HEX -- Convert AX to Hex At ES:DI
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AX to hex at ES:DI

On entry:

AX	 =	 value to convert
ES:DI	 ==>	 output save area

On exit:

ES:DI	 ==>	 byte to right of converted number

|


	 push	 cx		; Save for a moment
	 mov	 cx,4		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 cx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DW2HEX	 endp			; End DW2HEX procedure
	 NPPROC  DD2HEX -- Convert EAX to Hex At ES:DI
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert EAX to hex at ES:DI

On entry:

EAX	 =	 value to convert
ES:DI	 ==>	 output save area

On exit:

ES:DI	 ==>	 byte to right of converted number

|


	 push	 cx		; Save for a moment
	 mov	 cx,8		; # hex digits
	 call	 BIN2HEX_SUB	; Handle by subroutine
	 pop	 cx		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DD2HEX	 endp			; End DD2HEX procedure
	 NPPROC  BIN2HEX_SUB
	 assume  ds:nothing,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert AL/AX/EAX to hex at ES:DI

On entry:

AL/AX/EAX=	 value to convert
CX	 =	 # hex digits to convert
ES:DI	 ==>	 output save area

On exit:

ES:DI	 ==>	 byte to right of converted number

|


	 REGSAVE <ax,bx,edx>	; Save registers

	 pushf			; Save flags
	 std			; Store backwards

	 mov	 edx,eax	; Copy to secondary register
	 lea	 bx,NUMBERS_HI	; XLAT table
	 add	 di,cx		; Skip to the end+1
	 push	 di		; Save to return
	 dec	 di		; Now the last digit
BIN2HEX_MORE:
	 mov	 al,dl		; Copy to XLAT register
	 and	 al,0Fh 	; Isolate low-order digit
	 xlat	 NUMBERS_HI	; Convert to ASCII hex
S16	 stosb			; Save in output area

	 shr	 edx,4		; Shift next digit down to low-order

	 loop	 BIN2HEX_MORE	; Jump if more digits to format

	 pop	 di		; Restore

	 popf			; Restore flags

	 REGREST <edx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BIN2HEX_SUB endp		; End BIN2HEX_SUB procedure
	 NPPROC  INFO_READ -- Read In INFO Structure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 al,02h 	; Read from device
	 mov	 bx,DEV_HNDL	; Get device handle
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INFO_READ endp			; End INFO_READ procedure
	 NPPROC  INFO_WRITE -- Write Out INFO Structure
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 al,03h 	; Write to device
	 mov	 bx,DEV_HNDL	; Get device handle
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Set IOCTL info from INFO

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INFO_WRITE endp 		; End INFO_WRITE procedure
if @OEM_HIFILL
	 NPPROC  DISP_ERRMAC -- Display MAC Error Message
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display memory allocation chain error message

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 cx,MSG_CLOSMAC_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_CLOSMAC ; Tell 'em the bad news
	 call	 CHECK_LINE	; Count in another line and check for pause

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_ERRMAC endp		; End DISP_ERRMAC procedure
endif				; IF @OEM_HIFILL
	 NPPROC  CHECK_CPUID -- Check On CPU Identifier
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure we're running on an 80386 processor.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

N.B.:  Use only 8088 instructions!!!!

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 push	 sp		; First test for a 286/386
	 pop	 ax

	 cmp	 ax,sp		; Same?
	 jne	 short CHECK_CPUID_ERR ; No, it's neither a 286 nor a 386

; Distinguish 286 from 386

	 pushf			; Save flags for a moment

	 mov	 ax,mask $IOPL	; Try to set IOPL bits in flag register

	 push	 ax
	 popf

	 pushf			; Get flags back into AX
	 pop	 ax

	 popf			; Restore original flags

	 test	 ax,mask $IOPL	; Any bits set?
	 clc			; Assume OK
	 jnz	 short CHECK_CPUID_EXIT ; Yes, so continue on
CHECK_CPUID_ERR:
	 call	 DISP_COPY	; Display copyright notice

	 mov	 cx,MSG_NOT386_LEN ; CX = # bytes in message
	 mov	 bx,@STD_ERR	; Send to standard error handle
	 DOSCALL @WRITF2,MSG_NOT386 ; Tell 'em it's the wrong CPU
	 call	 CHECK_LINE	; Count in another line and check for pause

	 stc			; Indicate we have a problem
CHECK_CPUID_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPUID endp		; End CHECK_CPUID procedure
	 NPPROC  ACT_DEFUNCT -- Print message for defunct options
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing

	 lea	 dx,MSG_DEFUNCT ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 ret

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_DEFUNCT endp		; End CHECK_CPUID procedure

CODE	 ends			; End CODE segment

	 MEND	 UTIL		; End UTIL_COM module
