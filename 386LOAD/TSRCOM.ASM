;' $Header:   P:/PVCS/MAX/386LOAD/TSRCOM.ASV   1.1   30 May 1997 10:38:10   BOB  $
	 title	 TSRCOM -- 386LOAD/MOVE'EM TSR Loader For AUTOEXEC.BAT
	 page	 58,122
	 name	 TSRCOM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Program segment DATZ,	para-aligned,  public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NLSEG,	para-aligned,  public, class 'ndata'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Program segment DTAIL,	para-aligned,  public, class 'zdata'
	       Program segment ACODE,	byte-aligned,  public, class 'zdata'
	       Data    segment ADATA,	dword-aligned, public, class 'zdata'
	       Program segment SEG_TXT, byte-aligned,  public, class 'zdata'
	       Program segment SEG_LEN, word-aligned,  public, class 'zdata'
	       Program segment SEG_TAB, word-aligned,  public, class 'zdata'
	       Program segment SEG_ACT, word-aligned,  public, class 'zdata'
	       Program segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Program derived from:  None.

Original code by:  Bob Smith, March 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include DOS.INC
	 include DOSERR.INC
	 include KEYCALL.INC
	 include EXE.INC
	 include EXEC.INC
	 include DTA.INC
	 include DIR.INC
	 include MAC.INC
	 include PTR.INC
	 include VIDATTR.INC
	 include OPCODES.INC
	 include IOCTL.INC
	 include CPUFLAGS.INC
	 include BITFLAGS.INC
	 include DEVDRV.INC

	 include LOAD_OEM.INC
.list

ARG_STR  struc

	 dw	 ?		; Caller's BP
ARG_CSIP dd	 ?		; Caller's return address
ARG_FLG  dw	 ?		; Caller's flags

ARG_STR  ends


PGROUP	 group	 CODE,DATZ,NCODE,NDATA,NLSEG,DTAIL,ACODE,ADATA,SEG_LEN,SEG_TAB,SEG_ACT,ZZTAIL


ZZTAIL	 segment dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 extrn	 ZTAIL:byte

ZZTAIL	 ends			; End ZZTAIL segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 TOPFILL_CHECK:near
	 extrn	 NEWLINE:near
	 extrn	 INST_ENV:near
	 extrn	 BYT2PAR:near
	 extrn	 MAC_MERGE:near
if @OEM_FLEX
	 extrn	 REST_EMS:near
	 extrn	 REST67:near
endif				; IF @OEM_FLEX

	 extrn	 GETMEM_REG:near
	 extrn	 GETMEM_SRCH:near
	 extrn	 LINK_LSEG:near
	 extrn	 INST_CMDLINE:near
	 extrn	 INST_FCBS:near
	 extrn	 SET_EES:near
	 extrn	 INFO_READ:near
	 extrn	 INFO_WRITE:near

NCODE	 ends			; End NCODE segment


DATZ	 segment para public 'data' ; Start DATZ segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 EXEC_PSP:word
	 extrn	 IGN_PSP:word
	 extrn	 INT_NPAR:word	; # paras in interrupt handlers
if @OEM_FLEX
	 extrn	 OLDINT67_PATCH:dword
endif				; IF @OEM_FLEX

	 public  LCL_FLAG
	 include LOAD_LCL.INC
LCL_FLAG dw	 @LCL_TSR	; Local flags

	 public  OPT_FLAG
	 include LOAD_OPT.INC
OPT_FLAG dw	 @OPT_TSRDEF	; Option flags with defaults

	 public  CURPSP
CURPSP	 dw	 ?		; Save area for current PSP

	 public  TEMPSTK,TEMPSTKZ
	 align	 2
TEMPSTK  dw	 180h dup (0CDEFh) ; Temporary stack
TEMPSTKZ label	 word		; End of temporary stack

	 public  PLCLSTK
PLCLSTK  dw	 ?		; Pointer to local stack offset

	 public  LSEGSEG
LSEGSEG  dw	 ?		; Segment of LSEG

	 public  LEXEC_BLK
LEXEC_BLK EXEC_STR <>		; Load and execute command block

	 public  LCL_PATHARG,LCL_PATH
LCL_PATHARG dw	 ?		; Offset in LCL_PATH following trailing zero
LCL_PATH db	 255 dup (0)	; Local path to FID right-justified
				; followed by a zero, the argument
				; length byte, and the arguments
				; Note that under 4DOS, the total command
				; line (including pathname and arguments)
				; may be 255 characters.  Although the
				; command tail in the PSP only allows
				; 127 characters, the pathname itself
				; may be 128 characters in network
				; environments.
	 public  DMAC
DMAC	 dw	 ?		; Starting DOS MAC entry

DATZ	 ends			; End DATZ segment


NLSEG	 segment para public 'ndata' ; Start NLSEG segment
	 assume  ds:PGROUP

	 extrn	 TOPFILL:word

; The following data values *MUST* be on a para boundary
; and *MUST* remain in this order for future compatibility
; with the SUMMARY option.

	 public  LSEG		; Load segment chain structure
	 include LOAD_SEG.INC
LSEG	 LSEG_STR <-1,-1,,0,0,0,0,0,0,0,@NOTSPEC,@NOTSPEC,0,?,0>

	 public  LSEGOFF_IFLAG
LSEG_IFLAG db	 0		; Flags for set interrupts
LSEGOFF_IFLAG equ LSEG_IFLAG-LSEG ; Offset from start of LSEG

	 public  INT_END,@INT_SIZE
INT_END  label	 byte		; End of interrupt handlers
@INT_SIZE equ	 INT_END-LSEG	; Size of interrupt block in bytes

NLSEG	 ends			; End NLSEG segment


ADATA	 segment dword public 'zdata' ; Start ADATA segment
	 assume  ds:PGROUP

	 extrn	 AZS_XHI:byte
	 extrn	 AZS_NOROOM:byte
	 extrn	 AZS_FILE:byte
	 extrn	 AZS_ARGS:byte
	 extrn	 AZS_XENV:byte
	 extrn	 AZS_NOTPRES:byte
	 extrn	 AZS_LOWFAIL:byte
	 extrn	 AZS_EXEC:byte
	 extrn	 LINECNT:word
	 extrn	 ALTPATHSEP:byte
	 extrn	 MSG_COPY:byte

	 public  ENVPATH_VEC
ENVPATH_VEC dd	 ?		; Pointer to next path in environment

	 public  LODPATH_VEC,LODPATH_LEN
LODPATH_VEC dd	 ?		; Pointer to our load path
LODPATH_LEN dw	 0		; Length of ...

	 public  UTL_FLAG
	 include QMAX_UTL.INC
UTL_FLAG dw	 0		; Local utility program flags

	 public  EXEFILE_OFF,EXEFILE_LEN
EXEFILE_OFF dw	 ?		; EXE file offset
EXEFILE_LEN dw	 ?		; EXE file length

	 public  MSG_EXE,NOPATH
MSG_EXE  db	 '.EXE'         ; File extension
NOPATH	 db	 0		; Terminator of above and no path ASCIIZ string
MSG_EXELEN equ	 $-MSG_EXE	; Length of ...

	 public  CURDRV
CURDRV	 db	 ?		; Current drive letter (uppercase)

	 public  MSG_QQQ
MSG_QQQ  db	 '.???',0       ; File extension
MSG_QQQLEN equ	 $-MSG_QQQ	; Length of ...

	 public  LCL_FID
LCL_FID  db	 80 dup (0)	; Local copy of FID

	 public  MSG_PATH
MSG_PATH db	 'PATH='        ; Path string
MSG_PATHLEN equ  $-MSG_PATH	; Message length

	 include QMAX_IDN.INC

ADATA	 ends			; End ADATA segment


NDATA	 segment dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 AZS_XHILOAD:byte
	 extrn	 AZS_NOLOAD:byte
	 extrn	 AZS_LOADLO:byte
	 extrn	 AZS_ERRMAC:byte
	 extrn	 AZS_XMAXLOW:byte
AZS_UGHUGH equ	 AZS_ERRMAC

	 extrn	 PRGREG:byte
	 extrn	 CON10:word
	 extrn	 STD_ERR:word
	 extrn	 MACLOC:byte
	 extrn	 MACALG:byte
	 extrn	 DOSVER:word
	 extrn	 XDOSVER:word
	 extrn	 EXEC_PRGNPAR:word
	 extrn	 EXE_NPAR:word
	 extrn	 EXEC_PSP:word
	 extrn	 DRV_FCB1:byte
	 extrn	 DRV_FCB2:byte

	 extrn	 LC2_FLAG:word
	 include LOAD_LC2.INC

	 extrn	 NUMBERS_HI:byte

	 extrn	 HELP_TEXT:byte
	 extrn	 HELP_LEN:abs
	 extrn	 EXEC_PRGMAC:word ; Segment of program MAC
	 extrn	 FILE_HEAD:byte ; File header in case it's an .EXE file

	 public  EXEC_BLK,EXEC_LOD,EXEC_REL
EXEC_BLK label	 word		; EXEC call parameter block
EXEC_LOD dw	 ?		; Pointer to high DOS memory
EXEC_REL dw	 0		; Relocation factor

	 public  EXEC_ENVMAC,EXEC_INTMAC,EXEC_TOP
EXEC_ENVMAC dw	 0		; Segment of environment MAC
EXEC_INTMAC dw	 0		; Segment of interrupt handlers MAC
EXEC_TOP dw	 ?		; Top of region in 1KB

	 public  ENV_HEAD,ENV_TAIL,ENV_SIZE,ENV_NPAR,PRG_NPAR
ENV_HEAD dw	 ?		; Offset of environment head
ENV_TAIL dw	 0		; Size of environment tail
ENV_SIZE dw	 0		; Size of environment in bytes
				; rounded up to a para boundary
ENV_NPAR dw	 ?		; # paras in environment
PRG_NPAR dw	 ?		; # paras in program including PSP
				; but not the interrupt block

	 public  PFID_OFF,PFID_NAM,PFID_NXT,PFID_ROOM
PFID_OFF dw	 ?		; Offset of PROG= argument
PFID_NAM dw	 ?		; Offset of "filename.ext"
PFID_NXT dw	 ?		; Ending offset of FID
PFID_ROOM dd	 ?		; Room needed for the program
				; including the PSP but not interrupt block

	 public  GSIZE_NPAR
GSIZE_NPAR dw	 ?		; # paras needed to go resident w/GETSIZE

	 public  PARG_OFF,PARG_LEN
PARG_OFF dw	 ?		; Offset of PROG= argument's arguments
PARG_LEN dw	 ?

	 public  OLDDTA_VEC
OLDDTA_VEC dd	 ?		; Save area for pointer to old DTA

	 public  END_RET
END_RET  db	 -1		; Ending return code

	 public  AZS_386LOAD
AZS_386LOAD db	 @OEM_LOAD,' ',0

	 public  AZS_CRLF
AZS_CRLF db	 CR,LF,0	; Line terminators

	 public  LCL_DTA
LCL_DTA  DTA_STR <>		; Local DTA

	 public  PBID_MSG,ID_LEN
PBID_MSG dw	 0		; Pointer to ID message
ID_LEN	 dw	 0		; Length of ID message

; I'd like to use offset PGROUP:PSP_*, but that generates fixups...
	 public  L4EXEC_BLK
L4EXEC_BLK LOADDBG_STR <0,80h,5Ch,6Ch,,> ; Structure for 4B01 (load for execution)

NDATA	 ends			; End NDATA segment


CMDARG_MAC macro TXT,ACT,ATTRIB
	 local	 LCL_TXT,LCL_LEN

SEG_TXT  segment byte public 'zdata' ; Start SEG_TXT segment
	 assume  ds:PGROUP

LCL_TXT  db	 TXT
LCL_LEN  equ	 $-LCL_TXT

SEG_TXT  ends			; End SEG_TXT segment


SEG_LEN  segment word public 'zdata' ; Start SEG_LEN segment
	 assume  ds:PGROUP

	 dw	 LCL_LEN

SEG_LEN  ends			; End SEG_LEN segment


SEG_TAB  segment word public 'zdata' ; Start SEG_TAB segment
	 assume  ds:PGROUP

	 dw	 PGROUP:LCL_TXT

SEG_TAB  ends			; End SEG_TAB segment


SEG_ACT  segment word public 'zdata' ; Start SEG_ACT segment
	 assume  ds:PGROUP

	 dw	 PGROUP:ACT

SEG_ACT  ends			; End SEG_ACT segment

	 endm			; CMDARG_MAC


SEG_TAB  segment word public 'zdata' ; Start SEG_TAB segment
	 assume  ds:PGROUP

	 public  CMDARG_TAB
CMDARG_TAB label word

SEG_TAB  ends			; End SEG_TAB segment


SEG_LEN  segment word public 'zdata' ; Start SEG_LEN segment
	 assume  ds:PGROUP

	 public  CMDARG_LEN
CMDARG_LEN label word

SEG_LEN  ends			; End SEG_LEN segment


SEG_ACT  segment word public 'zdata' ; Start SEG_ACT segment
	 assume  ds:PGROUP

	 public  CMDARG_ACT
CMDARG_ACT label word

SEG_ACT  ends			; End SEG_ACT segment

; All keywords in this table *MUST* be in lowercase

	 CMDARG_MAC 'ddd',      CMDCHK_MAPDEV   ; Synonym for MAPDEV
	 CMDARG_MAC 'display',  CMDCHK_DISPLAY
	 CMDARG_MAC 'envname',  CMDCHK_ENVNAME
	 CMDARG_MAC 'mapdev',   CMDCHK_MAPDEV
	 CMDARG_MAC 'mapdrv',   CMDCHK_MAPDEV   ; Synonym for MAPDEV
	 CMDARG_MAC '/d',       CMDCHK_MAPDEV   ; Synonym for MAPDEV
	 CMDARG_MAC 'mapmem',   CMDCHK_MAPMEM
	 CMDARG_MAC '/m',       CMDCHK_MAPMEM   ; Synonym for MAPMEM
	 CMDARG_MAC 'summary',  CMDCHK_SUMMARY
	 CMDARG_MAC '/s',       CMDCHK_SUMMARY  ; Synonym for SUMMARY
	 CMDARG_MAC 'ver',      CMDCHK_VER
	 CMDARG_MAC '/v',       CMDCHK_VER      ; Synonym for VER

SEG_ACT  segment word public 'zdata' ; Start SEG_ACT segment
	 assume  ds:PGROUP

NODISP_ACT equ	$-CMDARG_ACT	; Commands below the line don't call
				; DISP_COPY before invocation

SEG_ACT  ends			; End SEG_ACT segment

	 CMDARG_MAC 'envreg',   CMDCHK_ENVREG
	 CMDARG_MAC 'envsave',  CMDCHK_ENVSAVE
if @OEM_FLEX
	 CMDARG_MAC 'flexframe',CMDCHK_FLEXFRAME
endif				; IF @OEM_FLEX
	 CMDARG_MAC 'getsize',  CMDCHK_GETSIZE
	 CMDARG_MAC 'group',    CMDCHK_GROUP
	 CMDARG_MAC 'inorder',  CMDCHK_INORDER
	 CMDARG_MAC '/sid',     CMDCHK_INORDBG
	 CMDARG_MAC '/si',      CMDCHK_INORDER
	 CMDARG_MAC 'help',     CMDCHK_HELP
	 CMDARG_MAC '/?',       CMDCHK_HELP     ; Synonym for HELP
	 CMDARG_MAC 'int',      CMDCHK_INT
	 CMDARG_MAC 'noretry',  CMDCHK_NORETRY
if @OEM_SYS eq @OEMSYS_3COM
	 CMDARG_MAC 'pause',    CMDCHK_PAUSE
else
	 CMDARG_MAC 'nopause',  CMDCHK_NOPAUSE
endif				; IF @OEM_SYS eq @OEMSYS_3COM
	 CMDARG_MAC 'prgreg',   CMDCHK_PRGREG
	 CMDARG_MAC 'prog',     CMDCHK_PROG
	 CMDARG_MAC 'psp',      CMDCHK_PSP
	 CMDARG_MAC 'quiet',    CMDCHK_QUIET
	 CMDARG_MAC '/q',       CMDCHK_QUIET    ; Synonym for QUIET
	 CMDARG_MAC 'reorder',  CMDCHK_REORDER
	 CMDARG_MAC '/srd',     CMDCHK_REORDBG
	 CMDARG_MAC '/sr',      CMDCHK_REORDER
	 CMDARG_MAC 'size',     CMDCHK_SIZE
	 CMDARG_MAC 'terse',    CMDCHK_TERSE    ; Don't display copyright
	 CMDARG_MAC 'verbose',  CMDCHK_VERBOSE  ; display copyright
	 CMDARG_MAC 'vds',      CMDCHK_VDS


SEG_TAB  segment word public 'zdata' ; Start SEG_TAB segment
	 assume  ds:PGROUP

	 public  NCMDARGS
NCMDARGS equ	 ($-CMDARG_TAB)/(type CMDARG_TAB) ; Its length

SEG_TAB  ends			; End SEG_TAB segment


DTAIL	 segment para public 'zdata' ; Start DTAIL segment
	 assume  ds:PGROUP

	 extrn	 INFO_CTL:byte
	 include QMAX_CTL.INC

	 extrn	 MSC_FLAG:word
	 include QMAX_MSC.INC

	 extrn	 LOADSEG:word
	 extrn	 POVR_MAC:word
	 extrn	 GTAIL:byte

	 public  ORG_PSP
ORG_PSP  dw	 ?		; Original PSP (before relocation)

DTAIL	 ends			; End DTAIL segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 PSP_TERMINATE:dword
	 extrn	 PSP_STOR_MAX:word
	 extrn	 PSP_ENVIR_PTR:word
	 extrn	 PSP_FILE_TAB_SIZ:word
	 extrn	 PSP_FILE_TAB_PTR:dword
	 extrn	 PSP_PARM_COUNT:byte
	 extrn	 PSP_PARM_STRING:byte
	 extrn	 PSP_FCB1:byte
	 extrn	 PSP_FCB2:byte
	 extrn	 PSP_CTRL_PSP:word
	 extrn	 PSP_DTA:byte

CODE	 ends			; End CODE segment


ACODE	 segment byte public 'zdata' ; Start ACODE segment
	 assume  cs:PGROUP

	 extrn	 FIND_BASE:near
	 extrn	 SKIP_WHITE:near
	 extrn	 SKIP_FID:near
	 extrn	 LOADSIZE:near
	 extrn	 ACT_MAP:near
	 extrn	 ACT_DDD:near
	 extrn	 SUMMARY:near
	 extrn	 INORDER:near
	 extrn	 REORDER:near
	 extrn	 INORDER_DBG:near
	 extrn	 REORDER_DBG:near
	 extrn	 CHECK_LINE:near
if @OEM_FLEX
	 extrn	 INST_EMS:near
	 extrn	 INST67:near
endif				; IF @OEM_FLEX

	 extrn	 FORCE_GETSIZE:near
	 extrn	 FCN_GETSIZE:near
	 extrn	 FCN_GROUP:near
	 extrn	 FCN_INT:near
	 extrn	 FCN_PRGREG:near
if @OEM_SYS ne @OEMSYS_3COM
	 extrn	 FCN_NOPAUSE:near
else
	 extrn	 FCN_PAUSE:near
endif				; IF @OEM_SYS ne @OEMSYS_3COM
	 extrn	 FCN_QUIET:near
	 extrn	 FCN_SIZE:near
if @OEM_FLEX
	 extrn	 FCN_FLEXFRAME:near
endif				; IF @OEM_FLEX
	 extrn	 FCN_VDS:near
	 extrn	 DEC2BIN:near
	 extrn	 CHECK_SETVER:near
	 extrn	 READCFG:near
	 extrn	 CHECK_ORPHAN:near
	 extrn	 STROUT:near

	 NPPROC  BASE2BIN -- Convert From Specified Base to Binary
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

BASE2BIN -- Convert the number at DS:SI in base CX to binary.
The converted # is returned in AX.

On exit:

CF	 =	 1 if overflow
	 =	 0 if OK
AX	 =	 converted #

|

	 REGSAVE <bx,dx,di,es>	; Save registers

	 call	 SKIP_WHITE	; Skip over more white space
	 lodsb			; Get next character

	 xor	 bx,bx		; Zero accumulator

	 push	 cs		; Move CS to ES for SCASB
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it
BASE2BIN_LOOP:
	 cmp	 al,'a'         ; Check for lower case character
	 jb	 @F		; Continue if it's not.
	 and	 al,not ('a'-'A') ; Convert to upper case
@@:
	 lea	 di,NUMBERS_HI	; Get address of number conversion table
	 push	 cx		; Save number base (and table length)
   repne scasb			; Look for the character
	 pop	 cx		; Restore number base
	 jne	 short BASE2BIN_DONE ; Not one of ours

	 sub	 di,1+offset PGROUP:NUMBERS_HI ; Convert to origin 0
	 mov	 ax,bx		; Copy old to multiply by base

	 mul	 cx		; Shift over accumulated #
	 jnc	 short BASE2BIN_ADD ; Jump if within range

; Allow overflow if 'Keyword=10000'

	 dec	 dx		; Check for DX=1
	 jnz	 short BASE2BIN_OVF ; Not this time

	 and	 di,di		; Check for new digit
	 jnz	 short BASE2BIN_OVF ; Not this time

	 cmp	 ds:[si].LO,'0' ; Check against lower range
	 jb	 short BASE2BIN_ADD ; Jump if not a digit

	 cmp	 ds:[si].LO,'9' ; Check against upper range
	 jbe	 short BASE2BIN_OVF ; Jump if it's a digit
BASE2BIN_ADD:
	 mov	 bx,ax		; Copy back
	 add	 bx,di		; Add in new #
	 jc	 short BASE2BIN_OVF ; Jump if out of range

	 lodsb			; Get next digit

	 jmp	 BASE2BIN_LOOP	; Go around again

BASE2BIN_OVF:

	 stc			; Indicate something went wrong

	 jmp	 short BASE2BIN_EXIT ; Join common exit code

BASE2BIN_DONE:
	 dec	 si		; Back off to previous character
	 mov	 ax,bx		; Get result from accumulator

	 clc			; Indicate all went well
BASE2BIN_EXIT:
	 REGREST <es,di,dx,bx>	; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller with number in AX

	 assume  ds:nothing,es:nothing,ss:nothing

BASE2BIN endp			; End BASE2BIN procedure
	 NPPROC  INIT_PARMS -- Initialize Parameters
	 assume  ds:PGROUP,es:PGROUP,ss:nothing

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save registers

	 cld			; String ops forwardly

if @OEM_SYS eq @OEMSYS_3COM
	 or	 OPT_FLAG,@OPT_NOPAUSE ; No pause is the default
endif				; IF @OEM_SYS eq @OEMSYS_3COM

; Check for arguments

	 lea	 si,PSP_PARM_STRING ; DS:SI ==> argument line
IP_ARGS_WHITE:
	 call	 SKIP_WHITE	; Skip over any intervening white space

	 cmp	 ds:[si].LO,CR	; Check for ending
	MJ e	 IP_ARGS_EXIT	; That's all folks

; Search for the argument text

	 xor	 bx,bx		; Zero index register
	 mov	 cx,NCMDARGS	; # arguments to check
CHECK_ARGS_NEXTARG:
	 mov	 di,CMDARG_TAB[bx] ; Get location of text

	 REGSAVE <cx,si>	; Save for a moment
	 mov	 cx,CMDARG_LEN[bx] ; Get length
CHECK_ARGS_NEXTCHAR:
	 lodsb			; Get next command line char
	 or	 al,20h 	; Convert to lowercase

	 inc	 di		; Skip to next character in table

	 cmp	 al,es:[di-1]	; Check against CMDARG_TAB
	 loope	 CHECK_ARGS_NEXTCHAR ; Jump if more characters to compare


	 lodsb			; Get next character (while we can)

	 REGREST <si,cx>	; Restore
	 jne	 short CHECK_ARGS_NEXT1 ; If not a match, look for more

	 cmp	 al,'/'         ; Check for valid separator
	 je	 short CHECK_ARGS_FOUND ; A match

	 cmp	 al,'='         ; Check for valid separator
	 je	 short CHECK_ARGS_FOUND ; A match

	 cmp	 al,';'         ; Check for a semicolon
	 je	 short CHECK_ARGS_FOUND ; A match

	 cmp	 al,' '         ; Check for blank or below
	 jbe	 short CHECK_ARGS_FOUND ; A match

CHECK_ARGS_NEXT1:
	 add	 bx,type CMDARG_TAB ; Skip to next entry

	 loop	 CHECK_ARGS_NEXTARG ; Jump if more entries to check

; Keyword not found

IP_ARGS_ERR0:
	 jmp	 IP_ARGS_ERR	; Join common error code

CHECK_ARGS_FOUND:
	 add	 si,CMDARG_LEN[bx] ; Skip over the keyword

	 jmp	 CMDARG_ACT[bx] ; Take appropriate action


	 public  CMDCHK_VER
CMDCHK_VER:
	 or	 OPT_FLAG,@OPT_VER ; Mark as specified

	 call	 CHECK_INFO	; Check and display IDN info
	 jnc	 short IP_ARGS_WHITE ; Go around again
IP_ARGS_CLC0:
	 jmp	 IP_ARGS_CLC	; Jump if something went wrong (ignore error)


	 public  CMDCHK_DISPLAY
CMDCHK_DISPLAY:
	 mov	 ax,@STD_OUT	; Get handle for standard output
	 push	 ax		; Send it there
	 call	 FCN_DISPLAY	; Display the argument line

	 jmp	 short IP_ARGS_WHITE ; Go around again


	 public  CMDCHK_ENVNAME
CMDCHK_ENVNAME:
	 or	 OPT_FLAG,@OPT_ENAME ; Mark as name-only in the environment

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_ENVREG
CMDCHK_ENVREG:
	 call	 FCN_ENVREG	; Mark as ENVREG= specified
	 jc	 short IP_ARGS_ERR0 ; Jump if something went wrong

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_GETSIZE
CMDCHK_GETSIZE:
	 call	 FCN_GETSIZE	; Mark as GETSIZE specified

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_GROUP
CMDCHK_GROUP:
	 call	 FCN_GROUP	; Mark as GROUP= specified
	 jc	 short IP_ARGS_ERR0 ; Jump if error

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_INT
CMDCHK_INT:
	 call	 FCN_INT	; Mark as INT specified

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_MAPDEV
CMDCHK_MAPDEV:
	 or	 OPT_FLAG,@OPT_TABLE ; Mark as specified

	 test	 LC2_FLAG,@LC2_XMAX ; Is MAX in the system?
	MJ nz	 IP_ARGS_ERRXMAX ; Jump if not

	 call	 CHECK_INFO	; Check and display IDN info
	 jc	 short IP_ARGS_CLC0 ; Jump if something went wrong (ignore error)

	 call	 ACT_DDD	; Display device driver report

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_MAPMEM
CMDCHK_MAPMEM:
	 or	 OPT_FLAG,@OPT_TABLE ; Mark as specified

	 test	 LC2_FLAG,@LC2_XMAX ; Is MAX in the system?
	MJ nz	 IP_ARGS_ERRXMAX ; Jump if not

	 call	 CHECK_INFO	; Check and display IDN info
	 jc	 short IP_ARGS_CLC0 ; Jump if something went wrong (ignore error)

	 call	 ACT_MAP	; Display memory map

	 jmp	 IP_ARGS_WHITE	; Go around again


; Do NOT put program name only in environment requested and free the main
; environment, unless FLEXFRAME is requested.  In that case, we must relocate
; the environment and ENVNAME is our only mechanism.

	 public  CMDCHK_ENVSAVE
CMDCHK_ENVSAVE:
if @OEM_FLEX
	 test	 LSEG.LSEG_FLAG,@LSEG_FLEX ; Is use EMS page frame requested?
	 jnz	 short @F	; Yes, so we ignore this option
endif				; IF @OEM_FLEX

	 and	 OPT_FLAG,not @OPT_ENAME ; Remove mark as name-only in the environment
@@:
	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_NORETRY
CMDCHK_NORETRY:
	 or	 OPT_FLAG,@OPT_NORETRY ; If TSR doesn't go resident, don't try
				; again in low DOS.
	 jmp	 IP_ARGS_WHITE	; Go around again


if @OEM_SYS ne @OEMSYS_3COM
	 public  CMDCHK_NOPAUSE
CMDCHK_NOPAUSE:
	 call	 FCN_NOPAUSE	; Mark as NOPAUSE specified

	 jmp	 IP_ARGS_WHITE	; Go around again
else
	 public  CMDCHK_PAUSE
CMDCHK_PAUSE:
	 call	 FCN_PAUSE	; Mark as PAUSE specified

	 jmp	 IP_ARGS_WHITE	; Go around again
endif				; IF @OEM_SYS ne @OEMSYS_3COM


	 public  CMDCHK_PRGREG
CMDCHK_PRGREG:
	 call	 FCN_PRGREG	; Mark as PRGREG= specified
	MJ c	 IP_ARGS_ERR	; Jump if error

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_PSP
CMDCHK_PSP:
	 call	 FCN_PSP	; Mark as PSP= specified
	MJ c	 IP_ARGS_ERR	; Jump if error

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_QUIET
CMDCHK_QUIET:
	 call	 FCN_QUIET	; Mark as QUIET specified

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_SUMMARY
CMDCHK_SUMMARY:
	 or	 OPT_FLAG,@OPT_TABLE ; Mark as specified

	 test	 LC2_FLAG,@LC2_XMAX ; Is MAX in the system?
	MJ nz	 IP_ARGS_ERRXMAX ; Jump if not

	 call	 SUMMARY	; Display summary report

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_INORDER
CMDCHK_INORDER:
	 or	 OPT_FLAG,@OPT_TABLE ; Mark as specified

	 test	 LC2_FLAG,@LC2_XMAX ; Is MAX in the system?
	MJ nz	 IP_ARGS_ERRXMAX ; Jump if not

	 call	 INORDER	; Display summary report

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_INORDBG
CMDCHK_INORDBG:
	 or	 OPT_FLAG,@OPT_TABLE ; Mark as specified

	 test	 LC2_FLAG,@LC2_XMAX ; Is MAX in the system?
	 jnz	 short IP_ARGS_ERRXMAX ; Jump if not

	 call	 INORDER_DBG	; Display summary report

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_REORDER
CMDCHK_REORDER:
	 or	 OPT_FLAG,@OPT_TABLE ; Mark as specified

	 test	 LC2_FLAG,@LC2_XMAX ; Is MAX in the system?
	 jnz	 short IP_ARGS_ERRXMAX ; Jump if not

	 call	 REORDER	; Display summary report

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_REORDBG
CMDCHK_REORDBG:
	 or	 OPT_FLAG,@OPT_TABLE ; Mark as specified

	 test	 LC2_FLAG,@LC2_XMAX ; Is MAX in the system?
	 jnz	 short IP_ARGS_ERRXMAX ; Jump if not

	 call	 REORDER_DBG	; Display summary report

	 jmp	 IP_ARGS_WHITE	; Go around again


if @OEM_FLEX
	 public  CMDCHK_FLEXFRAME
CMDCHK_FLEXFRAME:
	 call	 FCN_FLEXFRAME	; Mark as FLEXFRAME specified

	 jmp	 IP_ARGS_WHITE	; Go around again
endif				; IF @OEM_FLEX


	 public  CMDCHK_SIZE
CMDCHK_SIZE:
	 call	 FCN_SIZE	; Mark as SIZE= specified
	 jc	 short IP_ARGS_ERR ; Jump if something went wrong

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_VDS
CMDCHK_VDS:
	 call	 FCN_VDS	; Mark as VDS specified
	 jc	 short IP_ARGS_ERR ; Jump if something went wrong

	 jmp	 IP_ARGS_WHITE	; Go around again


	 public  CMDCHK_HELP
CMDCHK_HELP:
	 or	 OPT_FLAG,@OPT_VER ; Mark so we can exit cleanly
	 call	 ACT_HELP	; Display help screen
	 jmp	 IP_ARGS_CLC	; Cut out -- we're done

	 public  CMDCHK_TERSE
CMDCHK_TERSE:
	 mov	 MSG_COPY,0	; Zap copyright notice

	 jmp	 IP_ARGS_WHITE	; Go around again

	 public  CMDCHK_VERBOSE
CMDCHK_VERBOSE:
	 call	 DISP_COPY

	 jmp	 IP_ARGS_WHITE	; Go around again

	 public  CMDCHK_PROG
CMDCHK_PROG:
	 call	 FCN_PROG	; Mark as PROG= specified
	 jc	 short IP_ARGS_ERR ; Jump if something went wrong

; All arguments processed -- ensure at least a table option or PROG= specified

IP_ARGS_EXIT:

; Was a table display or verify option specified?

	 test	 OPT_FLAG,@OPT_TABLE or @OPT_VER ; Well?
	 jnz	 short IP_ARGS_CLC ; Yes

	 cmp	 OPT_FLAG,@OPT_TSRDEF ; Any options specified (other than default)?
	 je	 short IP_ARGS_MAP ; No, display memory map

	 test	 OPT_FLAG,@OPT_PROG ; Specified?
	 jnz	 short IP_ARGS_CLC ; Jump if so
	 jmp	 short IP_ARGS_ERR ; Join common error code

IP_ARGS_ERRXMAX:
	 lea	 ax,AZS_NOTPRES ; Tell 'em the bad news
	 jmp	 IP_ARGS_ERRCOM ; Join common error code

IP_ARGS_ERR:
	 lea	 ax,AZS_ARGS	; Tell 'em the bad news
IP_ARGS_ERRCOM:
	 push	 ax		; Pass message offset
	 call	 DISP_COPY	; If copyright hasn't been displayed, do it now
	 call	 DISP_ERRMSG	; Display an error message
IP_ARGS_STC:
	 stc			; Indicate something went wrong

	 jmp	 short INIT_PARMS_EXIT ; Join common exit code

IP_ARGS_MAP:
	 test	 LC2_FLAG,@LC2_XMAX ; Is MAX in the system?
	 jnz	 short IP_ARGS_ERRXMAX ; Jump if not

	 or	 OPT_FLAG,@OPT_TABLE ; Mark as specified

	 call	 ACT_MAP	; Display memory map
IP_ARGS_CLC:
	 clc			; Indicate all went well
INIT_PARMS_EXIT:
	 REGREST <di,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

INIT_PARMS endp 		; End INIT_PARMS procedure
	 NPPROC  FIND_FILE -- Find The Specified File
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Find the specified file via the PATH.

On exit:

CF	 =	 0 if all went OK
LCL_PATH =	 d:\path\filename.ext

CF	 =	 1 if something went wrong

|

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save registers

; Establish our own local DTA

	 push	 es		; Save for a moment

	 DOSCALL @GETDTA	; Return with ES:BX ==> current DTA
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDDTA_VEC.VOFF,bx ; Save to restore later
	 mov	 OLDDTA_VEC.VSEG,es

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 DOSCALL @SETDTA,LCL_DTA ; Set DTA to DS:DX

; Copy drive and path (if any) in LCL_FID to LCL_PATH

	 lea	 si,LCL_FID	; DS:SI ==> LCL_FID
	 lea	 di,LCL_PATH	; ES:DI ==> LCL_PATH

	 cmp	 ds:[si][1].LO,':' ; Check for drive separator
	 je	 short FIND_FILE_DRV ; It's present

	 DOSCALL @GETDSK	; Return with AL = disk # (origin-0)
	 add	 al,'A'         ; Convert to uppercase ASCII

	 jmp	 short FIND_FILE_DRVCOM ; Join common code

FIND_FILE_DRV:
	 lodsb			; Get and skip over the drive letter
	 inc	 si		; Skip over drive separator

	 or	 al,20h 	; Convert to lowercase
	 add	 al,'A'-'a'     ; Convert to uppercase
FIND_FILE_DRVCOM:
	 stosb			; Save in LCL_PATH
	 mov	 CURDRV,al	; Save for later use

	 mov	 al,':'         ; Get drive separator
	 stosb			; Save in LCL_PATH

	 cmp	 ds:[si].LO,'\' ; Check for path separator
	 je	 short FIND_FILE_PATH ; It's a match

	 mov	 al,ALTPATHSEP	; Get alternate path separator

	 cmp	 al,ds:[si].LO	; Check for it
	 je	 short FIND_FILE_PATH ; It's a match

	 mov	 al,'\'         ; Path separator
	 stosb			; Save in LCL_PATH

	 mov	 dl,LCL_PATH[0] ; Get the drive letter
	 sub	 dl,'A'-1       ; Convert to origin-1

	 xchg	 si,di		; Save for a moment
	 DOSCALL @GETDIR	; Fill in current path on drive DL
	 xchg	 si,di		; Restore
	MJ c	 FIND_FILE_ERR	; Something went wrong

; Skip to end of LCL_PATH

	 mov	 al,0		; Search for the end
	 mov	 cx,-1		; We know it's there
   repne scasb			; Skip over it

	 dec	 di		; Backup to trailing zero

; Append any other path info from LCL_FID to LCL_PATH

	 call	 PATHSEP	; Append path separator to ES:DI unless present
FIND_FILE_PATH:
	 mov	 cx,PFID_NAM	; Get offset of start of "filename.ext"
	 sub	 cx,si		; Less current offset
     rep movsb			; Copy to LCL_PATH
	 mov	 es:[di].LO,0	; Save 0 in LCL_PATH
				; ES:DI ==> trailing zero

	 call	 PATHSEP	; Append path separator to ES:DI unless present

; Find the "PATH=" setting in the environment

	 call	 FIND_PATH	; Find the "PATH=" setting in the environment

	 jmp	 short FIND_FILE_COPYNAME ; Join common code

; Copy next path to LCL_PATH

FIND_FILE_NEXT:
	 lds	 si,ENVPATH_VEC ; DS:SI ==> next path in environment
	 assume  ds:nothing	; Tell the assembler about it

	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 ds:[si].LO,0	; End of the PATH environment?
	MJ e	 FIND_FILE_ERR	; Yes, file not found

	 lea	 di,LCL_PATH	; Assume drive separator present
	 mov	 ah,':'         ; Drive separator

	 cmp	 ah,ds:[si][1]	; Check for drive separator
	 je	 short FIND_FILE_NEXT1 ; It is

	 mov	 al,CURDRV	; Get current drive letter
	 lea	 di,LCL_PATH
	 stosw			; Save in LCL_PATH
FIND_FILE_NEXT1:
	 lodsb			; Get next character

	 cmp	 al,0		; Check for end of the PATH
	 je	 short FIND_FILE_NEXT2 ; Good guess

	 cmp	 al,';'         ; Check for separator
	 je	 short FIND_FILE_NEXT3 ; Good guess

	 stosb			; Save in LCL_PATH

	 jmp	 short FIND_FILE_NEXT1 ; Go around again

FIND_FILE_NEXT2:
	 dec	 si		; Backup to trailing zero
FIND_FILE_NEXT3:
	 mov	 ENVPATH_VEC.VOFF,si ; Save for next time

	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

; Append path separator to ES:DI unless already present at ES:DI-1
; Copy "filename.ext" to end of path at ES:DI

FIND_FILE_COPYNAME:
	 call	 PATHSEP	; Append path separator to ES:DI unless present

	 mov	 si,PFID_NAM	; DS:SI ==> "filename.ext"
	 mov	 cx,PFID_NXT	; Get ending offset
	 sub	 cx,si		; Less start = length

	 mov	 bx,di		; Save offset of "filename.ext"
     rep movsb			; Copy to end of current path
	 mov	 es:[di].LO,0	; Ensure properly terminated

; Append ".???" if no extension present

	 test	 LCL_FLAG,@LCL_EXT ; Extension present?
	 jnz	 short FIND_FILE_SRCH ; Yes, just search for it

	 lea	 si,MSG_QQQ	; DS:SI ==> ".???",0
	 mov	 cx,MSG_QQQLEN	; Length of ...
     rep movsb			; Copy to end of current path

; Attempt to find the file

FIND_FILE_SRCH:
	 mov	 cx,DIR_ATTR_NORM ; Code for normal file
	 DOSCALL @FIND1,LCL_PATH ; Find it
	 jc	 short FIND_FILE_NEXT ; Jump if not found

; Skip checks if extension already supplied

	 test	 LCL_FLAG,@LCL_EXT ; Extension present?
	 jnz	 short FIND_FILE_EXT ; Yes, so that's all folks

; Check for .COM and .EXE in that order

FIND_FILE_COMEXE:
	 lea	 di,LCL_DTA.DTA_FID[0] ; ES:DI ==> start of FID in DTA
	 mov	 al,0		; Search for terminator
	 mov	 cx,-1		; We know it's there
   repne scasb			; Search for it
	 neg	 cx		; Complement to length+2
	 dec	 cx		; Less initial -1, but counting trailing zero
	 sub	 di,4+1 	; Back off to extension

	 cmp	 es:[di].ELO,'C.' ; Check first two letters
	 jne	 short FIND_FILE_EXE ; Check for '.EXE'

	 cmp	 es:[di+2].ELO,'MO' ; Check next two letters
	 je	 short FIND_FILE_END ; It's a match
FIND_FILE_EXE:
	 cmp	 es:[di].ELO,'E.' ; Check first two letters
	 jne	 short FIND_FILE_SRCHNEXT ; No luck, try next file

	 cmp	 es:[di+2].ELO,'EX' ; Check next two letters
	 jne	 short FIND_FILE_SRCHNEXT ; No luck, try next file

	 or	 LC2_FLAG,@LC2_EXE ; Mark as having found an .EXE file
	 mov	 EXEFILE_OFF,di ; Save for later use
	 mov	 EXEFILE_LEN,cx ; ...
FIND_FILE_SRCHNEXT:
	 DOSCALL @FIND2 	; Search again
	 jnc	 short FIND_FILE_COMEXE ; Join common code

	 test	 LC2_FLAG,@LC2_EXE ; Have we found an .EXE file?
	MJ z	 FIND_FILE_NEXT ; Jump if not found to next path

	 mov	 di,EXEFILE_OFF ; ES:DI ==> location for EXE file offset
	 lea	 si,MSG_EXE	; DS:SI ==> ".EXE",0
	 mov	 cx,MSG_EXELEN	; Length of ...
     rep movsb			; Copy to end of current path

	 mov	 cx,EXEFILE_LEN ; Restore length

	 jmp	 short FIND_FILE_END ; Join common end code

FIND_FILE_EXT:
	 lea	 di,LCL_PATH[0] ; ES:DI ==> start of LCL_PATH
	 mov	 al,0		; Search for terminator
	 mov	 cx,-1		; We know it's there
   repne scasb			; Search for it

	 jmp	 short FIND_FILE_END1 ; Join common code

FIND_FILE_END:
	 mov	 di,bx		; ES:DI ==> "filename.ext",0 in LCL_PATH
	 lea	 si,LCL_DTA.DTA_FID ; DS:SI ==> actual "filename.ext",0
     rep movsb			; Copy to LCL_PATH
FIND_FILE_END1:
	 mov	 LCL_PATHARG,di ; Save offset for later use
	 sub	 di,offset es:LCL_PATH ; Less starting offset to get length
				; Including trailing zero
	 add	 ENV_TAIL,di	; Include in size of environment tail
	 add	 ENV_SIZE,di	; Include in overall size, too

; Convert LCL_PATH to uppercase

	 lea	 si,LCL_PATH	; DS:SI ==> start of LCL_PATH
	 call	 UPPERCASE_STR	; Convert ASCIIZ string at DS:SI to uppercase

; Check this "filename.ext",0 for presence in DOS 4.xx SETVER table

	 push	 si		; Pass as argument
	 call	 CHECK_SETVER	; Check it, fill in XDOSVER if found

	 push	 LODPATH_VEC.VSEG ; Pass segment of our load path
	 push	 LODPATH_VEC.VOFF ; Pass offset of ...
	 push	 LODPATH_LEN	; Pass length of ...
	 push	 si		; Pass as argument
	 call	 READCFG	; Read configuration file,
				; look for a match with the specified file,
				; and set flags as appropriate

; Copy "filename.ext" to LSEG structure

	 lea	 di,LCL_PATH	; ES:DI ==> start of LCL_PATH
	 push	 di		; Save
	 mov	 al,0		; Search for string terminator
	 mov	 cx,-1		; We know it's there
   repne scasb			; Search for it
	 dec	 di		; Back off to terminating zero
	 mov	 cx,di		; Copy ending offset
	 mov	 bx,di		; ...

	 pop	 di		; Restore original offset

	 sub	 cx,di		; CX = length of name

	 mov	 al,'\'         ; Path separator

	 REGSAVE <cx,di>	; Save for a moment
@@:
	 mov	 si,di		; Save current offset
   repne scasb			; Search for it
	 je	 short @B	; Jump if found
	 REGREST <di,cx>	; Restore

	 mov	 al,'/'         ; Alternate path separator
@@:
	 mov	 dx,di		; Save current offset
   repne scasb			; Search for it
	 je	 short @B	; Jump if found

; Put the larger of the two offsets into SI

	 cmp	 dx,si		; Compare 'em
	 jbe	 short @F	; SI is larger

	 mov	 si,dx		; DX is larger
@@:
				; DS:SI ==> "filename.ext" in LCL_PATH
	 mov	 cx,bx		; Copy ending offset
	 sub	 cx,si		; Less starting offset
	 lea	 di,LSEG.LSEG_FNE ; ES:DI ==> LSEG save area
     rep movsb			; Copy to LCL_PATH

	 clc			; Indicate found

	 jmp	 short FIND_FILE_EXIT ; Join common exit code

FIND_FILE_ERR:
	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 stc			; Indicate something went wrong
FIND_FILE_EXIT:
	 pushf			; Save flags

	 push	 ds		; Save for a moment

	 lds	 dx,OLDDTA_VEC	; DS:DX ==> old DTA
	 assume  ds:nothing	; Tell the assembler about it
	 DOSCALL @SETDTA	; Restore it

	 pop	 ds		; Restore

	 popf			; Restore

	 REGREST <di,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FIND_FILE endp			; End FIND_FILE procedure
	 NPPROC  FIND_PATH -- Find PATH in Our Environment
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Find the "PATH=" setting in our environment.

|

	 REGSAVE <ax,cx,si,di,es> ; Save registers

; Because of a difference in DOS 5.x, we must handle the case where
; our environment segment # is zero.

	 mov	 cx,PSP_ENVIR_PTR ; Get segment # of our environment
	 jcxz	 FIND_PATH_XENV ; Jump if not present

	 mov	 es,cx		; Address it
	 assume  es:nothing	; Tell the assembler about it
	 xor	 di,di		; ES:DI ==> our environment

	 mov	 ENVPATH_VEC.VSEG,cx ; Save segment
	 mov	 LODPATH_VEC.VSEG,cx ; ...

	 cmp	 es:[di].ELO,0	; Izit over before we began?
	 jne	 short FIND_PATH_NEXT ; Not so fast

	 inc	 di		; Skip over first zero
FIND_PATH_NEXT:
	 cmp	 es:[di].LO,0	; End of the environment?
	 je	 short FIND_PATH_PROG0 ; Yes, "PATH=" not found????

	 lea	 si,MSG_PATH	; DS:SI ==> "PATH="
	 mov	 cx,MSG_PATHLEN ; Length of string
    repe cmpsb			; Compare 'em
	 je	 short FIND_PATH_PROG ; We found it (note CF=0)

	 mov	 al,0		; ASCIIZ terminator
	 mov	 cx,-1		; We know it's there
   repne scasb			; Search for it

	 jmp	 short FIND_PATH_NEXT ; Go around again

; Enter here with CF significant

FIND_PATH_PROG0:
	 mov	 ENVPATH_VEC.VOFF,di ; Save offset for later use
	 inc	 di		; Skip over last zero
	 mov	 cx,-1		; We know it's there

	 jmp	 short FIND_PATH_PROG1 ; Jump if we're at the end

FIND_PATH_PROG:
	 mov	 ENVPATH_VEC.VOFF,di ; Save offset for later use
	 mov	 cx,-1		; We know it's there

; Find path of our own program for CFGFILE

	 mov	 al,0		; ASCIIZ terminator
@@:
   repne scasb			; Search for it

	 scasb			; Check for next byte of zero
	 jne	 short @B	; Jump if still looking
FIND_PATH_PROG1:
	 add	 di,2		; Skip over string count word
	 mov	 LODPATH_VEC.VOFF,di ; Save as start of our path

; Go to the end of the filename.ext

	 mov	 al,0		; ASCIIZ terminator
   repne scasb			; Search for it
	 dec	 di		; Back off to trailing zero
	 neg	 cx		; Get length of path
	 dec	 cx		; Remove bias (we started with 1)

; Now search for the last path separator to get just the path

	 mov	 si,LODPATH_VEC.VOFF ; Get start of our path in case not found
	 mov	 al,'\'         ; Get path separator
	 std			; Search backwards
   repne scasb			; Search for it
	 cld			; String ops forwards
	 jne	 short FIND_PATH_PROG2 ; Jump if not found

	 lea	 si,[di+2]	; Copy offset of sep+1
FIND_PATH_PROG2:
	 sub	 si,LODPATH_VEC.VOFF ; Less start to get length
	 mov	 LODPATH_LEN,si ; Save as length of path

	 jmp	 short FIND_PATH_EXIT ; Join common exit code

FIND_PATH_XENV:
	 mov	 ENVPATH_VEC.VSEG,ds ; Save segment
	 mov	 ENVPATH_VEC.VOFF,offset ds:NOPATH ; ...and offset

	 mov	 LODPATH_VEC.VSEG,ds ; Save segment
	 mov	 LODPATH_VEC.VOFF,offset ds:NOPATH ; ...and offset

	 mov	 ENV_SIZE,2+2	; Set default size to account for 0000h, 0001h
FIND_PATH_EXIT:
	 REGREST <es,di,si,cx,ax> ; Restore
	 assume  es:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FIND_PATH endp			; End FIND_PATH procedure
	 NPPROC  PATHSEP -- Append Path Separator to ES:DI
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Append path separator to ES:DI unless already present at ES:DI-1.

On entry:

ES:DI	 ==>	 trailing zero

On exit:

ES:DI	 ==>	 trailing zero (updated)

|

	 push	 ax		; Save for a moment

	 cmp	 es:[di-1].LO,'\' ; Check for path separator
	 je	 short PATHSEP_EXIT ; Already there, join common code

	 mov	 al,ALTPATHSEP	; Get alternate path separator

	 cmp	 al,es:[di-1].LO ; Check for alternate path separator
	 je	 short PATHSEP_EXIT ; Already there, join common code

	 mov	 es:[di].ELO,'\' ; Save '\',0 in LCL_PATH
	 inc	 di		; ES:DI ==> trailing zero
PATHSEP_EXIT:
	 pop	 ax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

PATHSEP  endp			; End PATHSEP procedure
	 NPPROC  FCN_ENVREG -- Function to Handle ENVREG=
	 assume  ds:nothing,es:PGROUP,ss:nothing
COMMENT|

Function to handle ENVREG=

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
	 jne	 short FCN_ENVREG_ERR ; Too bad

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 call	 DEC2BIN	; Convert ASCII decimal digits at DS:SI to (DX,AX)
	 jc	 short FCN_ENVREG_ERR ; Too large, so that's an error

; Ensure the value is within range

	 and	 dx,dx		; Ensure zero
	 jnz	 short FCN_ENVREG_ERR ; Not so, so that's an error

	 cmp	 ax,10		; Check against (abritrary) upper limit
	 jae	 short FCN_ENVREG_ERR ; Too large, so that's an error

	 mov	 LSEG.LSEG_EREG,al ; Save as environment region #
	 or	 OPT_FLAG,@OPT_EREG ; Mark as specified

	 clc			; Indicate all went well

	 jmp	 short FCN_ENVREG_EXIT ; Join common exit code

FCN_ENVREG_ERR:
	 stc			; Indicate something went wrong
FCN_ENVREG_EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_ENVREG endp 		; End FCN_ENVREG procedure
	 NPPROC  FCN_PSP -- Function to Handle PSP=
	 assume  ds:nothing,es:PGROUP,ss:nothing
COMMENT|

Function to handle PSP=

On entry:

DS:SI	 ==>	 argument line

On exit:

DS:SI	 ==>	 (updated)
CF	 =	 1 if error
	 =	 0 otherwise
AX	 =	 clobbered
BX	 =	 ...
CX	 =	 ...
DI	 =	 ...

|
	 or	 OPT_FLAG,@OPT_TSRDEF ; Mark as specified

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 lodsb			; Get next character

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_PSP_ERR ; Too bad

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 mov	 cx,16		; Base for conversion
	 call	 BASE2BIN	; Convert number at DS:SI to AX
	 jc	 short FCN_PSP_ERR ; Too bad

	 mov	 IGN_PSP,ax	; Save the PSP to ignore

	 clc			; Indicate all went well

	 jmp	 short FCN_PSP_EXIT ; Join common exit code

FCN_PSP_ERR:
	 stc			; Indicate something went wrong
FCN_PSP_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_PSP  endp			; End FCN_PSP procedure
	 NPPROC  FCN_PROG -- Function to Handle PROG=
	 assume  ds:nothing,es:PGROUP,ss:nothing
COMMENT|

Function to handle PROG=

On entry:

DS:SI	 ==>	 argument line

On exit:

DS:SI	 ==>	 (updated)
CF	 =	 1 if error
	 =	 0 otherwise
AX	 =	 clobbered
BX	 =	 ...
CX	 =	 ...
DI	 =	 ...

|

	 or	 OPT_FLAG,@OPT_PROG ; Mark as specified

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 lodsb			; Get next character

	 cmp	 al,'='         ; Must be
	 jne	 short FCN_PROG_ERR ; Too bad

	 call	 SKIP_WHITE	; Skip over any intervening white space

	 mov	 PFID_OFF,si	; Save address of PROG= argument

	 call	 SKIP_FID	; Skip over FID
				; returning DS:BX ==> filename.ext
				;	    DS:SI ==> next character after FID
				;	    AL = character after FID

; Convert offsets from origin-PSP_PARM_STRING to origin-LCL_FID

	 sub	 bx,PFID_OFF	; Less starting offset
	 lea	 bx,LCL_FID[bx] ; Plus new starting offset
	 mov	 PFID_NAM,bx	; Save name offset for later use

	 mov	 bx,si		; Copy ending offset
	 sub	 bx,PFID_OFF	; Less starting offset
	 lea	 bx,LCL_FID[bx] ; Plus new starting offset
	 mov	 PFID_NXT,bx	; Save ending offset ...

	 mov	 cx,si		; Copy ending offset

	 sub	 cx,PFID_OFF	; AX = length of FID
	 jz	 short FCN_PROG_ERR ; Gotta specify something

; Copy the FID to local storage

	 lea	 di,LCL_FID	; ES:DI ==> start of local FID

	 push	 si		; Save for a moment

	 mov	 si,PFID_OFF	; DS:SI ==> start of FID
     rep movsb			; Copy to local storage
	 mov	 al,0		; Trailing zero
	 stosb			; Save in local storage

; Convert LCL_FID to uppercase

	 lea	 si,LCL_FID	; DS:SI ==> start of local FID
	 call	 UPPERCASE_STR	; Convert ASCIIZ string at DS:SI to uppercase

	 pop	 si		; Restore

	 mov	 PARG_OFF,si	; Save offset of arguments (if any)

; Search to end of the line

@@:
	 lodsb			; Get next character

	 cmp	 al,CR		; Stop on CR
	 jne	 short @B	; Not yet

	 mov	 ax,si		; Copy offset
	 dec	 ax		; Back off to CR
	 sub	 ax,PARG_OFF	; AX = length of ARG
	 mov	 PARG_LEN,ax	; Save for later

	 clc			; Indicate all went well

	 jmp	 short FCN_PROG_EXIT ; Join common exit code

FCN_PROG_ERR:
	 stc			; Indicate something went wrong
FCN_PROG_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_PROG endp			; End FCN_PROG procedure
	 NPPROC  OPEN_FILE -- Open The File
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Open the file and save its handle and load size

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 call	 FIND_FILE	; Find it via path, return with AX=handle
	MJ c	 OPEN_FILE_ERRMSG ; Something went wrong

	 test	 LC2_FLAG,@LC2_XHILOAD ; Izit not to be loaded high?
	 jnz	 short OPEN_FILE_XHILOAD ; Jump if so

	 mov	 al,0		; Access code for read-only
	 DOSCALL @OPENF2,LCL_PATH ; Open it
	 jc	 short OPEN_FILE_ERRMSG ; Something went wrong

	 mov	 bx,ax		; Copy to handle register

; Read in the file's header in case it's an .EXE file

	 mov	 cx,type EXE_STR ; # bytes to read in
	 DOSCALL @READF2,FILE_HEAD ; Read into local buffer
	 jc	 short OPEN_FILE_ERRCLOS ; Jump if something went wrong

; Determine the load size in bytes

	 xor	 cx,cx		; Set CX:DX to 0:0
	 xor	 dx,dx
	 mov	 al,2		; Code to move file pointer to EOF
	 DOSCALL @MOVFP2	; Move file pointer by CX:DX as per AL
				; Return with DX:AX == file size in bytes
	 jc	 short OPEN_FILE_ERRCLOS ; Jump if something went wrong

	 call	 LOADSIZE	; Get the load size

; If SIZE= not already specified, use load size as the amount of room

	 test	 OPT_FLAG,@OPT_SIZE ; Wuzit specified?
	 jnz	 short OPEN_FILE_SIZE ; Jump if so

	 mov	 ax,LSEG.LSEG_LSIZE.ELO ; Get the load size
	 mov	 dx,LSEG.LSEG_LSIZE.EHI

	 cmp	 dx,PFID_ROOM.EHI ; Check against room needed
	 jb	 short OPEN_FILE_SIZE ; Jump if room size is larger
	 ja	 short @F	; Jump if load size is larger

	 cmp	 ax,PFID_ROOM.ELO ; Check against room needed
	 jbe	 short OPEN_FILE_SIZE ; Jump if room size is no smaller
@@:
	 mov	 PFID_ROOM.ELO,ax ; Save as amount of room needed
	 mov	 PFID_ROOM.EHI,dx ; Save as amount of room needed
OPEN_FILE_SIZE:
; If min paras and max paras are both 0, the program is treated specially
; by DOS.  The maximum available region will be allocated, the PSP will
; be created at the low end of the region as usual, but the program itself
; will be loaded at the high end of the region.  We also need to check that
; EXE_NPAR is valid.  It should have been set to the load image size,
; since EXE_MAX is 0.
	 test	 LCL_FLAG,@LCL_EXE ; Izit an EXE file?
	 jz	 short @F	; Jump if not

	 mov	 ax,FILE_HEAD.EXE_MIN ; Get minimum paras beyond load image
	 or	 ax,FILE_HEAD.EXE_MAX ; Combine with maximum paras
	 jnz	 short @F	; Jump if it's not an end loader

	 cmp	 EXE_NPAR,0	; Izit greater than 0 and less than 512K?
	 jle	 short @F	; Jump if not

	 or	 LC2_FLAG,@LC2_ENDLOAD ; Program loads at the high end of
				; region with the PSP at the low end
@@:
	 DOSCALL @CLOSF2	; Close it up, ignore error

	 clc			; Indicate all went well

	 jmp	 short OPEN_FILE_EXIT ; Join common exit code

OPEN_FILE_XHILOAD:
	 lea	 ax,AZS_XHILOAD ; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 jmp	 short OPEN_FILE_ERR ; Join common error code

OPEN_FILE_ERRCLOS:
	 DOSCALL @CLOSF2	; Close it up, ignore error
OPEN_FILE_ERRMSG:
	 lea	 ax,AZS_FILE	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message
OPEN_FILE_ERR:
	 stc			; Indicate something went wrong
OPEN_FILE_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

OPEN_FILE endp			; End OPEN_FILE procedure
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
	 call	 CHECK_LINE	; Count in another line and check for pause

	 popf			; Restore CF
CHECK_INFO_EXIT:
	 REGREST <ds,cx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_INFO endp 		; End CHECK_INFO procedure
	 NPPROC  TSRCOM -- TSR Common Loader
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Load TSR into high DOS memory

|

; Use a default TOPFILL value of PSP_STOR_MAX.	The only case where this
; is a baldfaced lie is when PROTMAN$ is present, and we check for that
; in TOPFILL_CHECK unless the T flag was present.

	 mov	 ax,PSP_STOR_MAX ; Highest possible value for TOPFILL
	 mov	 TOPFILL,ax	; Save for later use

; Get starting MAC entry in low DOS

	 push	 es		; Save

	 DOSCALL @GETLST	; ES:BX ==> list of lists
	 assume  es:nothing	; Tell the assembler

	 mov	 ax,es:[bx-2].ELO ; Get starting DOS MAC entry
	 mov	 DMAC,ax	; Save for later

	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler

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
	 call	 CHECK_INFO	; Check and display IDN info
	 jc	 short ERR_EXIT0 ; Jump if something went wrong

	 call	 FIND_BASE	; Ensure base program is loaded
	 jc	 short ERR_EXIT0 ; Exit on error

	 call	 INIT_PARMS	; Initialize parameters
	 jc	 short ERR_EXIT0 ; Exit on error

	 test	 OPT_FLAG,@OPT_INTR ; INT specified?
	 jz	 short INSTALL_XINT ; Not this time

	 int	 03h		; Call debugger
INSTALL_XINT:

; Was a table or verify option specified?

	 test	 OPT_FLAG,@OPT_TABLE or @OPT_VER ; Well?
	MJ nz	 TSRCOM_EXIT	; Yes, join common exit code

	 test	 LC2_FLAG,@LC2_XMAX ; Are we loading low because MAX isn't in?
	 jnz	 short @F	; Jump if so

	 cmp	 PRGREG,0	; Did user ask to load program low?
	 jne	 short INSTALL_XLOW ; Jump if not

@@:
	 call	 LOADLOW_XMAX	; Load it without GETSIZE
	 jmp	 TSRCOM_EXIT	; Join common exit code

INSTALL_XLOW:
	 mov	 ax,POVR_MAC	; Get segment of first MAC in high DOS memory

	 cmp	 ax,-1		; Check for high DOS memory
	 je	 short @F	; None this time, maybe in low DOS memory

	 call	 CHECK_ORPHAN	; Check on orphan LSEG entries

	 push	 ax		; Merge starting at this segment
	 call	 MAC_MERGE	; Merge adjacent free MACs
	 jc	 short ERRMAC_EXIT ; Exit on error

@@:
	 call	 CALC_ENV	; Calculate size of environment
	 jc	 short ERR_EXIT0 ; Exit on error

	 call	 OPEN_FILE	; Open the PROG= file
	 jc	 short ERR_EXIT0 ; Exit on error

	 jmp	 TSRCOM_SUB	; Continue with low code

;;;ERR_EXITIDN:
;;;	 call	 CHECK_INFO	; Check and display IDN info
;;;
;;;	 jmp	 short ERR_EXIT0 ; Join common error exit code

ERRMAC_EXIT:
	 lea	 ax,AZS_ERRMAC	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message
ERR_EXIT0:
	 call	 DISP_COPY	; If copyright hasn't been displayed, do it now

	 jmp	 ERR_EXIT	; Join common error exit code

TSRCOM	 endp			; End TSRCOM procedure
	 NPPROC  LOADLOW_XMAX -- Load program low with 0 bytes overhead
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Load program in low DOS without (possibly) MAX in the system,
and without any overhead.  Like COMMAND.COM, we need to relocate
ourselves in the high end of low DOS.

If we fail to load the requested program, we display an error
message and return.

We need to figure out where the program will load for the DOS
Enter Exec State (4B05) call.  To do this, we need to:
 1. Load ourselves into the high end of low DOS.
 2. Set up a MAC entry and free our PSP and environment at the old
    load address.
 3. Set current PSP to our high address.
 4. Calculate the putative environment size.
 5. Ask DOS to allocate a block of the expected environment size.
 6. Free it after noting the new high water mark.  This should
    be our program's PSP.  It might or might not be the same as
    our original PSP.
 7. Execute 4B05 if DOS 5.
 8. Execute 4B01 using the environment gotten from our parent's PSP.
 9. Set up initial CS:IP and SS:SP using the new PSP (in effect on
    return from 4B01).
10. Blast the terminate vector from our PSP into the new PSP.
11. Free ourselves.  We no longer exist.
12. Parse FCB's and set AH and AL.
13. Zero all other registers.
14. Load new SS:SP and jump.

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save

; OPEN_FILE sets variables we'll need later (FILE_HEAD.*, LSEG.LSEG_LSIZE)
	 call	 OPEN_FILE	; Find the file and open it
	MJ c	 LOADLOW_XMAX_EXE ; Jump if we failed

; 1. Load ourselves into the high end of low DOS.
; 2. Free our PSP and environment at the old load address.
;    We need to move our environment as well, since in the INSTALL=
;    configuration DOS will not create an environment for 4B01.

	 sub	 bx,bx		; Assume no environment
	 mov	 cx,PSP_ENVIR_PTR ; Get our environment pointer
	 jcxz	 short @F	; Jump if empty

	 dec	 cx		; Back off to environment MAC entry
	 mov	 es,cx		; Address environment MAC entry
	 assume  es:nothing	; Tell the assembler

	 mov	 bx,es:[0].MAC_NPAR ; Get length of environment
	 inc	 bx		; Add environment MAC entry
	 inc	 cx		; Address environment segment
@@:
	 mov	 EXEC_ENVMAC,cx ; Save source env segment (or 0) for later

	 mov	 cx,ds		; Get current PGROUP segment
	 dec	 cx		; Address MAC entry
	 mov	 es,cx		; Use ES:
	 assume  es:nothing	; Tell the assembler

	 mov	 ax,es:[0].MAC_NPAR ; Get size of block
	 lea	 dx,ZTAIL[16-1] ; Get highest possible address, rounded up
	 mov	 cl,4-0 	; Convert bytes to paragraphs
	 shr	 dx,cl		; DX = paras needed for TSRLOAD.COM

	 mov	 cx,EXE_NPAR	; Paras needed for resident program
	 add	 cx,dx		; Plus paras needed for TSRLOAD
	 add	 cx,bx		; Plus paras needed for environment
	 cmp	 cx,ax		; Minus paras available - Is it enough?
	MJ nc	 LOADLOW_XMAX_ERR ; Not enough memory

	 sub	 ax,bx		; Subtract size of environment
	 sub	 ax,dx		; Less paras needed for TSRLOAD
	 dec	 ax		; Less MAC entry

	 mov	 es:[0].MAC_NPAR,ax ; Set new length
	 mov	 es:[0].MAC_OWNR,0 ; Free it
	 mov	 al,@MAC_MID	; New entry type
	 xchg	 al,es:[0].MAC_TYPE ; Get previous type

	 mov	 cx,es		; Get current MAC entry
	 add	 cx,es:[0].MAC_NPAR ; Skip segment
	 inc	 cx		; Skip initial MAC entry
	 mov	 es,cx		; Address new MAC entry
	 assume  es:nothing	; Tell the assembler

	 inc	 cx		; Skip PSP/environment MAC entry

	 or	 bx,bx		; Do we have an environment?
	 jz	 short LOADLOW_XMAX_NOENV ; Jump if not

; ES:0 is the new environment MAC entry, DX is TSRLOAD size in paras,
; and CX is the new environment segment
	 mov	 PSP_ENVIR_PTR,cx ; Save new environment segment
	 add	 cx,bx		; Get new PSP value
	 mov	 es:[0].MAC_TYPE,@MAC_MID ; Set type of entry
	 dec	 bx		; Subtract MAC entry from length
	 mov	 es:[0].MAC_NPAR,bx ; Set length of entry
	 mov	 es:[0].MAC_OWNR,cx ; Set owner

	 REGSAVE <cx,ds>	; Save

; Copy old environment up high.  We need it for 4B01.
	 mov	 di,10h 	; Skip over MAC entry in destination
	 sub	 si,si		; Start at beginning of source segment
	 mov	 cl,4-1 	; Convert paras to words
	 shl	 bx,cl		; BX = words to copy
	 mov	 cx,bx		; Prepare for string move
	 mov	 bx,EXEC_ENVMAC ; Prepare to address source segment
	 mov	 ds,bx		; Address old environment segment
	 assume  ds:nothing	; Tell the assembler

  rep	 movs	 es:[di].ELO,ds:[si].ELO ; Copy environment

	 dec	 bx		; Back off to old environment's MAC entry
	 mov	 ds,bx		; Address MAC entry
	 assume  ds:nothing	; Tell the assembler

	 mov	 ds:[0].MAC_OWNR,0 ; Free old environment

	 REGREST <ds,cx>	; Restore
	 assume  ds:PGROUP	; Tell the assembler

	 dec	 cx		; Back off to new MAC entry
	 mov	 es,cx		; Address it
	 assume  es:nothing	; Tell the assembler

	 inc	 cx		; Point to new PSP once again
LOADLOW_XMAX_NOENV:
; ES:0 is the new PSP MAC entry, AL is the previous MAC type,
; DX is the size of TSRLOAD in paras, and CX is the new PSP.

	 mov	 es:[0].MAC_TYPE,al ; Create entry with saved type
	 mov	 es:[0].MAC_OWNR,cx ; Save owner (PSP)
	 mov	 es:[0].MAC_NPAR,dx ; Size in paras

	 mov	 es,cx		; Address new PSP
	 assume  es:nothing	; Tell the assembler

	 mov	 EXEC_PRGMAC,ds ; Save old load location

	 mov	 EXEC_PSP,es	; Save new PSP location for INST_*
	 mov	 L4EXEC_BLK.LOADDBG_CMD.VSEG,es ; Fix up segments
	 mov	 L4EXEC_BLK.LOADDBG_FCB1.VSEG,es
	 mov	 L4EXEC_BLK.LOADDBG_FCB2.VSEG,es

	 sub	 si,si		; Copy everything, including PSP
	 mov	 di,si		; Copy to destination offset
	 mov	 bx,dx		; Save length of high end segment
	 mov	 cl,4-1 	; Convert paragraphs to words
	 shl	 dx,cl		; DX = words needed for TSRLOAD.COM
	 mov	 cx,dx		; Count to move
   rep	 movs	 es:[di].ELO,PGROUP:[si].ELO ; Copy code high
	 mov	 ax,es		; Get new segment

	 mov	 ds,ax		; Initialize DS
	 assume  ds:PGROUP,es:PGROUP ; Now tell the truth about ES, too

	 mov	 bx,cs		; Get low segment for comparison
	 cmp	 bx,PSP_FILE_TAB_PTR.VSEG ; Izit part of the file table ptr?
	 jne	 short @F	; Don't try to change it if not

	 mov	 PSP_FILE_TAB_PTR.VSEG,ax ; Fix up far pointer to file table
@@:
	 mov	 ss,ax		; Point SS:SP to local stack in high end of DOS
	 assume  ss:nothing	; Tell the assembler

	 push	 ax		; New CS
	 lea	 ax,LOADLOW_XMAX_HIGHEND ; New IP
	 push	 ax		; Set up for far return

	 retf			; Load CS with value in high end of low DOS

	 public  LOADLOW_XMAX_HIGHEND
LOADLOW_XMAX_HIGHEND:
	 test	 LC2_FLAG,@LC2_XMAX ; Are we forced to do this?
	 jz	 short @F	; Jump if not (user specified PRGREG=0)

	 lea	 ax,AZS_NOTPRES ; Tell 'em MAX isn't present
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message (pointer on stack)

	 lea	 ax,AZS_XMAXLOW ; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message (pointer on stack)
@@:
; 3. Set current PSP to our high address.
	 mov	 bx,cs		; New PSP
	 DOSCALL @SETPSP	; Set PSP to BX

;    We set up the command line and FCB's in our own PSP.  Note that
;    we require the bogus EXEC_PSP value set above.
	 call	 INST_CMDLINE	; Copy arguments following prog=pathname

	 call	 INST_FCBS	; Set up DRV_FCB1 and DRV_FCB2

; 4. Calculate the putative environment size.
	 sub	 di,di		; Start at beginning of env segment
	 sub	 al,al		; What to look for
	 mov	 cx,-1		; How far to look
	 mov	 es,PSP_ENVIR_PTR ; Address environment segment
	 assume  es:nothing	; Tell the assembler

@@:
  repne  scas	 es:[di].LO	; Find end of string
	 scas	 es:[di].LO	; Look for second null
	 jne	 short @B	; Go around again

	 lea	 bx,[di+2].LO	; Include word for count of STRINGS items
	 lea	 di,LCL_PATH	; Start of path

	 push	 ds		; PGROUP segment
	 pop	 es		; Prepare to address PGROUP
	 assume  es:PGROUP	; Tell the assembler

	 mov	 cx,255 	; Maximum path length
  repne  scas	 LCL_PATH	; Find end of path
	 sub	 di,offset PGROUP:LCL_PATH ; Get length including \0
	 lea	 bx,[bx+di+16-1] ; BX = size in bytes of environment rounded up
	 mov	 cl,4		; Bits to shift
	 shr	 bx,cl		; BX = size of environment in paragraphs

; 5. Ask DOS to allocate a block of the expected environment size.
	 DOSCALL @GETMEM	; AX:0 = new segment
	 jc	 short LOADLOW_XMAX_XDOS5 ; Give up on EES call

; 6. Free it after noting the new high water mark.  This should
;    be our program's PSP.  It might or might not be the same as
;    our original PSP.
	 push	 ax		; Save putative environment segment

	 mov	 bx,-1		; Attempt to allocate largest block
	 DOSCALL @GETMEM	; CF=1, BX=maximum possible segment
	 DOSCALL @GETMEM	; AX = new high water mark

	 push	 ax		; Save for a moment
	 mov	 es,ax		; Prepare to free segment
	 assume  es:nothing	; Tell the assembler

	 DOSCALL @RELMEM	; Release segment ES
	 pop	 ax		; Restore

	 pop	 es		; Get putative environment segment
	 assume  es:nothing	; Tell the assembler

	 DOSCALL @RELMEM	; Release putative environment segment
	 pop	 ax		; Restore high water mark

; AX contains the putative new PSP
	 call	 FIX_FILEHEAD	; Set EXEC_PSP and fix up FILE_HEAD variables

; 7. Execute 4B05 if DOS 5.
	 call	 SET_EES	; If DOS 5, set EES

LOADLOW_XMAX_XDOS5:
; 8. Execute 4B01 using the environment gotten from our parent's PSP.

	 push	 ds		; Prepare to address PGROUP
	 pop	 es		; Address PGROUP
	 assume  es:nothing	; Tell the assembler

	 lea	 bx,L4EXEC_BLK	; ES:BX ==> load for EXEC call parameter block
	 mov	 al,01h 	; Code to load for execution
	 DOSCALL @EXEC,LCL_PATH ; Load into high DOS memory
	 jc	 short LOADLOW_XMAX_EXE ; Jump if it failed

; 9. Set up initial CS:IP and SS:SP using the new PSP (in effect on
;    return from 4B01).
;10. Blast the terminate vector from our PSP into the new PSP.
	 DOSCALL @GETPSP	; Return current PSP in BX
	 mov	 EXEC_PSP,bx	; Save it
	 mov	 es,bx		; Prepare to address new PSP
	 assume  es:nothing	; Tell the assembler

	 mov	 ax,PSP_TERMINATE.VOFF ; Offset of terminate address
	 mov	 bx,PSP_TERMINATE.VSEG ; Segment ...
	 mov	 cx,PSP_CTRL_PSP ; Our parent's PSP
	 assume  ds:nothing,es:PGROUP ; Tell a little white lie
	 mov	 PSP_TERMINATE.VOFF,ax ; Set offset and segment
	 mov	 PSP_TERMINATE.VSEG,bx ; in new PSP
	 mov	 PSP_CTRL_PSP,cx ; Take ourselves out of the chain
	 assume  ds:PGROUP,es:nothing ; Retract nose

;11. Free ourselves and our environment.  We no longer exist.
	 mov	 ax,ds		; Get our PSP
	 dec	 ax		; Back off to MAC entry
	 mov	 es,ax		; Address MAC entry
	 assume  es:nothing	; Tell the assembler

	 mov	 es:[0].MAC_OWNR,0 ; Nuke our MAC entry

	 mov	 ax,PSP_ENVIR_PTR ; Get our environment segment
	 or	 ax,ax		; Izit empty?
	 jz	 short @F	; Jump if so

	 dec	 ax		; Back off to MAC entry
	 mov	 es,ax		; Address environment MAC entry
	 assume  es:nothing	; Tell the assembler

	 mov	 es:[0].MAC_OWNR,0 ; Nuke environment MAC entry
@@:
;12. Parse FCB's and set AH and AL.
	 mov	 ah,DRV_FCB1	; FCB valid flags
	 mov	 al,DRV_FCB2

;13. Zero all other registers.
	 sub	 dx,dx		; Zero register
	 mov	 si,dx
	 mov	 di,dx
	 mov	 bp,dx

	 mov	 es,EXEC_PSP	; Set ES to new PSP
	 assume  es:nothing	; Tell the assembler

	 mov	 ds,EXEC_PSP	; Set DS to new PSP
	 assume  ds:nothing	; Tell the assembler

;14. Load new SS:SP and jump.
	 mov	 bx,L4EXEC_BLK.LOADDBG_SSSP.VOFF ; New SP
	 mov	 cx,L4EXEC_BLK.LOADDBG_SSSP.VSEG ; New SS

	 cli			; Nobody move
	 mov	 ss,cx		; Load SS
	 assume  ss:nothing	; Tell the assembler

	 mov	 sp,bx		; Load SP
	 sti			; Enable interrupts

	 sub	 bx,bx		; Clear BX
	 mov	 cx,bx		; ... and CX

	 jmp	 L4EXEC_BLK.LOADDBG_CSIP ; Begin execution of loaded program

LOADLOW_XMAX_EXE:
	 lea	 ax,AZS_EXEC	; Tell 'em the bad news
	 jmp	 short LOADLOW_XMAX_ERRCOM ; Join common error code

LOADLOW_XMAX_ERR:
	 lea	 ax,AZS_LOWFAIL ; Tell 'em the bad news
LOADLOW_XMAX_ERRCOM:
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message (pointer on stack)
LOADLOW_XMAX_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LOADLOW_XMAX endp		; End LOADLOW_XMAX procedure
	 NPPROC  CALC_ENV -- Calculate Size of Environment
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Calculate the size of the environment head.
That is, the part of the environment excluding the 'd:\path\filename.ext',0

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,cx,di,es>	; Save registers

; Because of a difference in DOS 5.x, we must handle the case where
; our environment segment # is zero.

	 mov	 cx,PSP_ENVIR_PTR ; Get segment # of our environment
	 jcxz	 CALC_ENV_XENV	; Jump if not present (DR-DOS INSTALL= time)

	 mov	 es,cx		; Address it
	 assume  es:nothing	; Tell the assembler about it
	 xor	 di,di		; ES:DI ==> our environment

	 mov	 al,0		; Search for ending
	 mov	 cx,8000h	; Maximum # bytes
	 cld			; String ops forwardly
CALC_ENV_NEXT:
   repne scasb			; Search until found
	 jcxz	 CALC_ENV_ERR	; Something went wrong

	 scasb			; Check for next byte of zero
	 jne	 short CALC_ENV_NEXT ; Jump if found as yet

	 add	 di,2		; Skip over next word
	 mov	 ENV_HEAD,di	; Save as size of environment head
				; excluding the program name
	 add	 ENV_SIZE,di	; Include in overall size, too

; Check for called via MS-DOS 4.x and 5.x INSTALL
; This condition is recognized by the environment containing
; just the two ending bytes of zeros.

	 cmp	 es:[0].ELO,0000h ; Any environment parameters?
	 je	 short CALC_ENV_XENV ; Jump if not (MS-DOS 4.x and 5.x
				; or 6.x w/o MultiConfig INSTALL= time)

; Check for MS-DOS 6.x w/MultiConfig INSTALL= time.  This context
; has a valid environment, but our Ctrl-PSP's Ctrl-PSP is zero.

	 mov	 es,PSP_CTRL_PSP ; Get the segment of our Ctrl-PSP
	 assume  es:nothing	; Tell the assembler about it

; In order to get addressibality to the Ctrl-PSP via ES,
; we need to lie to the assembler so it generates the proper
; segment override.

	 assume  ds:nothing,es:PGROUP ; Tell a white lie
	 cmp	 PSP_CTRL_PSP,0000h ; Is its Ctrl-PSP valid?
	 assume  ds:PGROUP,es:nothing ; Retract nose
	 jne	 short @F	; Jump if so

; Fall through if MS-DOS 6.x w/MultiConfig

CALC_ENV_XENV:
	 or	 LSEG.LSEG_FLAG,@LSEG_INST ; Mark as present
@@:
	 clc			; Indicate all went well

	 jmp	 short CALC_ENV_EXIT ; Join common exit code

CALC_ENV_ERR:
	 lea	 ax,AZS_XENV	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message

	 stc			; Indicate something went wrong
CALC_ENV_EXIT:
	 REGREST <es,di,cx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CALC_ENV endp			; End CALC_ENV procedure
	 NPPROC  UPPERCASE_STR -- Convert ASCIIZ String to Uppercase
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Convert the ASCIIZ string at DS:SI to uppercase.

|

	 REGSAVE <ax,si>	; Save registers
UPPERCASE_STR_NEXT:
	 lodsb			; Get next character

	 cmp	 al,'a'         ; Check against lower limit
	 jb	 short UPPERCASE_STR_LOOP ; Jump if too small

	 cmp	 al,'z'         ; Check against upper limit
	 ja	 short UPPERCASE_STR_LOOP ; Jump if too large

	 add	 ds:[si-1].LO,'A'-'a' ; Convert to uppercase
UPPERCASE_STR_LOOP:
	 and	 al,al		; Check for ending
	 jnz	 short UPPERCASE_STR_NEXT ; Jump if not at the end as yet

	 REGREST <si,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

UPPERCASE_STR endp		; End UPPERCASE_STR procedure
	 FPPROC  GETSIZE_UMB -- Load GETSIZE code in high DOS
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

If a sufficiently large UMB exists for (offset GTAIL) + (size PSP_STR),
copy our code up there, fix up segment references where necessary,
free ourselves in low DOS, and return to the caller in high DOS.

If we're loading via INSTALL=, stay out of high DOS.  The program
we're loading may be a UMB allocator.

FIXME If we're not using high DOS (INSTALL= or no room upstairs)
we should find a hole previously left by 386LOAD and use it.  To
make this scheme work, we need to hook our Int 67 handler into
the chain via the program's interrupt block.

On entry:
nothing.

On exit:
All segment registers changed if successful.

|

GSUMB_STR	struc
	dw	?		; Saved BP
	dw	?		; Return address
GSUMB_CS dw	?		; CS on return
GSUMB_STR	ends

	 push	 bp		; Save
	 mov	 bp,sp		; Prepare to address stack

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save

	 mov	 ax,POVR_MAC	; Get segment of first MAC in high DOS
	 cmp	 ax,-1		; Check for high DOS memory
	MJ e	 GETSIZE_UMB_EXIT ; Tough luck

	 test	 LSEG.LSEG_FLAG,@LSEG_INST ; Are we loading via INSTALL=?
	MJ nz	 GETSIZE_UMB_EXIT ; Jump if so

	 lea	 bx,GTAIL[16-1].LO ; Get offset from PSP for GTAIL rounded up

	 mov	 cl,4		; Convert to paras
	 shr	 bx,cl		; Paras we need to move

	 mov	 di,cs		; Temporary owner
	 call	 GETMEM 	; Find region with at least BX paras
				; returning AX new PSP
	MJ c	 GETSIZE_UMB_EXIT ; Jump if no room at the inn

GETSIZE_UMB_MOVE:
	 mov	 [bp].GSUMB_CS,ax ; Change return segment

	 mov	 bx,cs		; Get old CS for comparison
	 cmp	 bx,PSP_FILE_TAB_PTR.VSEG ; Izit used for the file handle table?
	 jne	 short @F	; Jump if not

	 mov	 PSP_FILE_TAB_PTR.VSEG,ax ; Change segment of file table pointer

@@:
	 dec	 ax		; Address MAC entry
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 inc	 ax		; Restore new PSP
	 mov	 es:[0].MAC_OWNR,ax ; Set owner

	 mov	 es,ax		; Address PSP in high DOS
	 assume  es:PGROUP	; Tell the assembler

	 sub	 si,si		; Begin at ground zero
	 mov	 di,si		; Destination
	 mov	 cx,offset PGROUP:GTAIL[16-1].LO ; Get offset from PSP for GTAIL
	 and	 cx,not (16-1)	; Knock off excess
   rep	 movs	 PGROUP:[di].LO,PGROUP:[si].LO ; Move it

	 mov	 ds,ax		; Address data in high DOS
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 ss,ax		; Address local stack in high DOS
	 assume  ss:nothing	; Tell the assembler

;------ We no longer have addressability to low DOS through DS --------

	 push	 ds		; Save PGROUP segment

if @OEM_FLEX
; Now we need to re-patch ourselves into the previous Int 67 handler
	 test	 LCL_FLAG,@LCL_IN67 ; Are we hooking Int 67?
	 jz	 short @F	; Jump if not

	 les	 bx,OLDINT67_PATCH ; Address patch point
	 assume  es:nothing	; Tell the assembler

	 mov	 es:[bx+1].VSEG,ax ; Fix up segment of far jump immediate
@@:
endif				; IF @OEM_FLEX

	 mov	 ax,cs		; Get old PSP
	 dec	 ax		; Segment of old MAC
	 mov	 es,ax		; Address old MAC entry
	 assume  es:nothing	; Tell the assembler

	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Free it

	 push	 DMAC		; Starting segment in low DOS
	 call	 MAC_MERGE	; Merge free MAC entries

	 mov	 ax,PSP_ENVIR_PTR ; Get our environment
	 or	 ax,ax		; Do we have one?
	 jz	 short @F	; Jump if not

	 dec	 ax		; Back off to environment MAC entry
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 mov	 es:[0].MAC_OWNR,ds ; Set new owner
@@:
	 pop	 es		; Restore high DOS PGROUP
	 assume  es:PGROUP	; Tell the assembler

	 mov	 bx,ds		; Get new PSP
	 DOSCALL @SETPSP	; Make BX the current PSP
	 jmp	 short GETSIZE_UMB_EXIT2 ; Join common exit

GETSIZE_UMB_EXIT:
; Search for a hole left in low DOS by 386LOAD.COM
	 lea	 bx,GTAIL[16-1].LO ; Get offset from PSP for GTAIL rounded up
	 mov	 cl,4		; Convert to paras
	 shr	 bx,cl		; Paras we need to move

	 mov	 ax,DMAC	; Get starting MAC entry in low DOS
GETSIZE_UMB_FINDLO:
	 mov	 es,ax		; Address MAC entry
	 assume  es:nothing	; Tell the assembler

	 cmp	 ax,POVR_MAC	; Have we schlepped over into high DOS?
	 jnb	 short GETSIZE_UMB_EXIT2 ; Jump if so

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Izit a valid MAC entry?
	 je	 short @F	; Jump if so

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit other valid MAC entry?
	 jne	 short GETSIZE_UMB_EXIT2 ; Bail if so

@@:
	 inc	 ax		; Skip to new PSP

	 cmp	 es:[0].MAC_OWNR,@MAC_LOADLO ; Izit one of our holes?
	 jne	 short @F	; Jump if so

	 cmp	 es:[0].MAC_NPAR,bx ; Izit big enough?
	 jb	 short @F	; Jump if so

	 mov	 es:[0].MAC_OWNR,cs ; Make it ours temporarily
	 jmp	 GETSIZE_UMB_MOVE ; Join common code to relocate

@@:
	 add	 ax,es:[0].MAC_NPAR ; Skip to next MAC entry

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Izit a middle entry?
	 je	 short GETSIZE_UMB_FINDLO ; Go around again if so

GETSIZE_UMB_EXIT2:
	 push	 ds		; Get PGROUP (wherever it is)
	 pop	 es		; Restore ES
	 assume  es:PGROUP	; Tell the assembler

	 REGREST <di,si,dx,cx,bx,ax> ; Restore

	 pop	 bp		; Restore

	 ret			; Return to caller with new CS

	 assume  ds:nothing,es:nothing,ss:nothing

GETSIZE_UMB endp		; End GETSIZE_UMB procedure

ACODE	 ends			; End ACODE segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 GETMEM:near
	 extrn	 FIND_OWNER:near
	 extrn	 MODMEM:near
	 extrn	 LOADHI:near

	 extrn	 KEYWAIT:near

	 extrn	 NOLOAD_PRESS:near

	 NPPROC  FIX_FILEHEAD -- Set new EXEC_PSP and fix FILE_HEAD
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Set EXEC_PSP to the segment in AX and fix up CS:ip and SS:sp values
in FILE_HEAD.

On entry:
AX	 Segment for new EXEC_PSP

On exit:
nothing.
|

	 REGSAVE <bx>		; Save

	 mov	 EXEC_PSP,ax	; Save as PSP segment
	 mov	 bx,ax		; Copy the segment
	 add	 bx,10h 	; Skip over PSP

	 test	 LC2_FLAG,@LC2_ENDLOAD ; Are we loading at the high end?
	 jz	 short @F	; Jump if not

	 add	 bx,EXEC_PRGNPAR ; Skip to end of region
	 sub	 bx,EXE_NPAR	; Back off by size of load image
@@:
	 mov	 EXEC_LOD,bx	; Save as load point

	 test	 LCL_FLAG,@LCL_EXE ; Izit an .EXE file?
	 jnz	 short FFH_EXE ; Jump if so

	 mov	 EXEC_REL,ax	; Save as relocation factor
	 mov	 FILE_HEAD.EXE_SS,ax ; Save as SS for .COM file
	 mov	 FILE_HEAD.EXE_CS,ax ; ...     CS
	 mov	 FILE_HEAD.EXE_IP,100h ; ...   IP

	 jmp	 short FFH_EXECOM ; Join common code

FFH_EXE:
	 xchg	 EXEC_REL,bx	; Save new relocation factor, get previous one
	 sub	 FILE_HEAD.EXE_SS,bx ; Remove previous relocation factor
	 sub	 FILE_HEAD.EXE_CS,bx
	 mov	 bx,EXEC_REL	; Get new relocation factor
	 add	 FILE_HEAD.EXE_SS,bx ; Relocate it
	 add	 FILE_HEAD.EXE_CS,bx
FFH_EXECOM:
	 REGREST <bx>		; Restore

	 ret			; Return to caller
	 assume  ds:nothing,es:nothing,ss:nothing

FIX_FILEHEAD endp		; End FIX_FILEHEAD procedure
	 NPPROC  FIND_MEM -- Find High DOS Memory
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Find high DOS memory into which we can fit the file.
Ensure there's room for the environment if same region
as well as interrupt handlers and data.  If we're trying
to load high (as opposed to GETSIZE) and there's not
enough memory, force GETSIZE and return without having
allocated anything.

If GETSIZE (forced or otherwise) is in effect on entry,
ensure we have enough low DOS memory available.

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,es> ; Save registers

	 mov	 MACLOC,@MACLOC_LO ; Use low fit in designated block
	 mov	 MACALG,0	; By default, use first fit

	 cmp	 DOSVER,0314h	; Izit DOS 3.20 or later?
	 jb	 short FIND_MEM_ALG ; No, use first fit

	 mov	 al,0		; Function code to return current algorithm
	 DOSCALL @MACALG	; Return with AX=0, 1, or 2

	 mov	 MACALG,al	; Save as current algorithm

; In case someone tried to run LOADHIGH 386LOAD prog=... make sure
; the link to high DOS is closed.
	 cmp	 DOSVER,0500h	; Are 5802/5803 functions supported?
	 jb	 short FIND_MEM_ALG ; Jump if not

	 mov	 ax,(@MACALG*256) + 03h ; Set high DOS link status
	 sub	 bx,bx		; Close link to high DOS
	 DOSCALL		; Ignore error return

FIND_MEM_ALG:
	 mov	 ax,PFID_ROOM.ELO ; Get the amount of room needed
	 mov	 dx,PFID_ROOM.EHI ; Get the amount of room needed
	 call	 BYT2PAR	; Convert (DX,AX) in bytes to AX in paras
	 mov	 PRG_NPAR,ax	; Save as # paras in program w/PSP

; Unless ENVSAVE or GETSIZE is specified, the environment is loaded
; low so it takes up no room in high DOS.

	 mov	 ENV_NPAR,0	; Assume none

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short @F	; Jump if so

	 test	 OPT_FLAG,@OPT_ENAME ; Name-only in the environment?
	 jnz	 short FIND_MEM1 ; Jump if so
@@:
	 call	 CALC_ENV_NPAR	; Fill in ENV_NPAR from ENV_SIZE
FIND_MEM1:
	 mov	 ax,@INT_SIZE+16-1 ; Get size of interrupt handlers (rounded up)
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 ax,cl		; Convert from bytes to paras
	 mov	 INT_NPAR,ax	; Save as # paras in interrupt handlers
	 inc	 ax		; Count in MAC paragraph
	 mov	 LSEG.LSEG_NPARA,ax ; Save for later use

; Wait to after we set xxx_NPAR variables before testing for
; any high DOS memory.

	 cmp	 POVR_MAC,-1	; Any high DOS memory?
	MJ e	 FIND_MEM_XHI	; Jump if there's none

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	MJ nz	 FIND_MEM_GETSIZE ; Jump if so

; If ENVREG not specified, or ENVREG = PRGREG, allocate space together

	 test	 OPT_FLAG,@OPT_EREG ; Environment region number specified?
	 jz	 short FIND_MEM_SAME ; Not this time, allocate in same region

	 test	 OPT_FLAG,@OPT_PREG ; Program region number specified?
	MJ z	 FIND_MEM_DIFF	; Not this time, allocate separately

	 mov	 al,LSEG.LSEG_EREG ; Get environment region #

	 cmp	 al,LSEG.LSEG_PREG ; Check against program region #
	MJ ne	 FIND_MEM_DIFF	; Unequal, allocate separately

; Find room for program, environment, and interrupt handlers
; in same region (LSEG.LSEG_PREG)

FIND_MEM_SAME:
	 mov	 bx,INT_NPAR	; Get # paras in interrupt handlers
	 inc	 bx		; Count in MAC paragraph
	 add	 bx,PRG_NPAR	; Plus # paras in program w/PSP

; Find larger of BX and LSEG.LSEG_RPAR2

	 cmp	 bx,LSEG.LSEG_RPAR2 ; Is BX larger?
	 jae	 short @F	; Jump if so

	 mov	 bx,LSEG.LSEG_RPAR2 ; Use RPAR2
@@:
	 cmp	 ENV_NPAR,0	; Is there an environment in high DOS?
	 je	 short @F	; Jump if not

	 inc	 bx		; Count in MAC paragraph
	 add	 bx,ENV_NPAR	; Plus # paras in environment
@@:

; Distinguish whether or not a program region was specified

	 test	 OPT_FLAG,@OPT_PREG ; Program region specified?
	 jz	 short FIND_MEM_SAME_XREG ; Jump if not

; Find memory for program, environment, and interrupt handlers
; in a specific region

	 xor	 ch,ch		; Zero to use as word
	 mov	 cl,LSEG.LSEG_PREG ; Get program region #
	 call	 GETMEM_REG	; Ensure region CX has at least BX paras
				; returning AX=MAC entry
	 jc	 short FIND_MEM_ERRCOD0 ; Jump if error, code in AX

	 jmp	 short FIND_MEM_SAME_COM ; Join common code

; Find memory for interrupt handlers, program, and environment
; in any region

FIND_MEM_SAME_XREG:
	 call	 GETMEM_SRCH	; Find region with at least BX paras
				; returning AX = MAC entry, CX = region #
	 jc	 short FIND_MEM_ERRCOD0 ; Jump if error, code in AX

	 mov	 LSEG.LSEG_PREG,cl ; Save region #

; The MAC entry in AX has at least the required # paras -- it might have more

FIND_MEM_SAME_COM:
	 mov	 EXEC_INTMAC,ax ; Save as interrupt MAC segment
	 mov	 es,ax		; Get segment of interrupt MAC
	 assume  es:nothing	; Tell the assembler about it

; Split off environment from top of block

	 cmp	 ENV_NPAR,0	; Is there an environment in high DOS?
	 je	 short FIND_MEM_SAME_COM1 ; Jump if not

	 mov	 bx,es:[0].MAC_NPAR ; Get # paragraphs in this entry
	 sub	 bx,ENV_NPAR	; Less # paras in environment
	 dec	 bx		; Count out MAC paragraph
	 call	 MODMEM 	; Modify memory block ES:0 to BX paras
	 jc	 short FIND_MEM_ERRCOD0 ; Jump if error, code in AX

; ES:0 ==> EXEC_INTMAC

	 mov	 ax,es		; Get current MAC segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry
	 mov	 EXEC_ENVMAC,ax ; Save as environment MAC segment
FIND_MEM_SAME_COM1:

; Split off interrupt handlers from bottom of block

	 mov	 bx,INT_NPAR	; Get # paras in interupt handlers
	 call	 MODMEM 	; Modify memory block ES:0 to BX paras
	 jc	 short FIND_MEM_ERRCOD0 ; Jump if error, code in AX

; ES:0 ==> EXEC_INTMAC

	 mov	 ax,es		; Get current MAC segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry
	 mov	 EXEC_PRGMAC,ax ; Save as program MAC segment

	 mov	 al,LSEG.LSEG_PREG ; Get region # for program
	 mov	 LSEG.LSEG_EREG,al ; Save as environment region #

	 jmp	 FIND_MEM_COM	; Join common code

FIND_MEM_ERRCOD0:
	 jmp	 FIND_MEM_ERRCOD ; Join common error code code

; Find room for (interrupt handlers, program) and environment separately

FIND_MEM_DIFF:
	 mov	 bx,INT_NPAR	; Get # paras in interupt handlers
	 inc	 bx		; Count in MAC paragraph
	 add	 bx,PRG_NPAR	; Plus # paras in program w/PSP

; Find larger of BX and LSEG.LSEG_RPAR2

	 cmp	 bx,LSEG.LSEG_RPAR2 ; Is BX larger?
	 jae	 short @F	; Jump if so

	 mov	 bx,LSEG.LSEG_RPAR2 ; Use RPAR2
@@:

; Distinguish whether or not a region was specified

	 test	 OPT_FLAG,@OPT_PREG ; Program region specified?
	 jz	 short FIND_MEM_DIFF_XREG1 ; No

; Find memory for program in a specific region

	 xor	 ch,ch		; Zero to use as word
	 mov	 cl,LSEG.LSEG_PREG ; Get program region #
	 call	 GETMEM_REG	; Ensure region CX has at least BX paras
				; returning AX=MAC entry
	 jc	 short FIND_MEM_ERRCOD0 ; Jump if error, code in AX

	 jmp	 short FIND_MEM_DIFF_ENV ; Join common environment allocation code

; Find memory for program in any region

FIND_MEM_DIFF_XREG1:
	 call	 GETMEM_SRCH	; Find region with at least BX paras
				; returning AX = MAC entry, CX = region #
	 jc	 short FIND_MEM_ERRCOD0 ; Jump if error, code in AX

	 mov	 LSEG.LSEG_PREG,cl ; Save region #

; The MAC entry in AX has at least the required # paras -- it might have more

FIND_MEM_DIFF_ENV:
	 mov	 EXEC_INTMAC,ax ; Save as interrupt MAC segment
	 mov	 es,ax		; Get segment of interrupt MAC
	 assume  es:nothing	; Tell the assembler about it

; Split off interrupt handlers from bottom of block

	 mov	 bx,INT_NPAR	; Get # paras in interupt handlers
	 call	 MODMEM 	; Modify memory block ES:0 to BX paras
	 jc	 short FIND_MEM_ERRCOD0 ; Jump if error, code in AX

; ES:0 ==> EXEC_INTMAC

	 mov	 ax,es		; Get current MAC segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry
	 mov	 EXEC_PRGMAC,ax ; Save as program MAC segment

	 mov	 bx,ENV_NPAR	; Get # paras in environment

	 cmp	 bx,0		; Is there an environment in high DOS?
	 je	 short FIND_MEM_COM0 ; Jump if not

; Distinguish whether or not a region was specified

	 test	 OPT_FLAG,@OPT_EREG ; Environment region specified?
	 jz	 short FIND_MEM_DIFF_XREG2 ; No

; Find memory for environment in a specific region

	 xor	 ch,ch		; Zero to use as word
	 mov	 cl,LSEG.LSEG_EREG ; Get environment region #
	 call	 GETMEM_REG	; Ensure region CX has at least BX paras
				; returning AX=MAC entry
	MJ c	 FIND_MEM_ERRCOD ; Jump if error, code in AX

	 jmp	 short FIND_MEM_ENVCOM ; Join common code

; Find memory for environment in any region

FIND_MEM_DIFF_XREG2:
	 call	 GETMEM_SRCH	; Find region with at least BX paras
				; returning AX = MAC entry, CX = region #
	MJ c	 FIND_MEM_ERRCOD ; Jump if error, code in AX

	 mov	 LSEG.LSEG_EREG,cl ; Save region #
FIND_MEM_ENVCOM:
	 mov	 EXEC_ENVMAC,ax ; Save as environment MAC segment
	 mov	 es,ax		; Get segment of environment MAC
	 assume  es:nothing	; Tell the assembler about it

; ES:0 ==> EXEC_ENVMAC

; Split the environment off from the top of the current block

	 mov	 bx,es:[0].MAC_NPAR ; Get # paragraphs in this entry

	 sub	 bx,ENV_NPAR	; Less # paras in environment
	 jz	 short FIND_MEM_COM0 ; Jump if none remaining

	 dec	 bx		; Count out MAC paragraph
	 jz	 short FIND_MEM_COM0 ; Jump if none remaining

	 call	 MODMEM 	; Modify memory block ES:0 to BX paras
	MJ c	 FIND_MEM_ERRCOD ; Jump if error, code in AX

	 mov	 ax,es		; Get current MAC segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry
	 mov	 EXEC_ENVMAC,ax ; Save as environment MAC segment
FIND_MEM_COM0:
	 jmp	 FIND_MEM_COM	; Join common code

FIND_MEM_XHI:
	 test	 OPT_FLAG,@OPT_QUIET ; Should we be quiet?
	 jnz	 short @F	; Yes

	 lea	 ax,AZS_XHI	; Tell 'em the bad news
	 push	 ax		; Pass as argument
	 call	 DISP_ERRMSG	; Display an error message
@@:
	 call	 FORCE_GETSIZE	; Mark as if GETSIZE were specified

	 jmp	 short FIND_MEM_GETSIZE ; Join common GETSIZE code

FIND_MEM_NOROOM:
if @OEM_SYS ne @OEMSYS_3COM
	 test	 OPT_FLAG,@OPT_QUIET ; Should we be quiet?
	 jnz	 short @F	; Yes

	 lea	 ax,AZS_NOROOM	; Tell 'em the bad news
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message
@@:
endif				; IF @OEM_SYS ne @OEMSYS_3COM

if @OEM_FLEX
	 call	 REST_EMS	; De-allocate any EMS memory
endif				; IF @OEM_FLEX

	 call	 FORCE_GETSIZE	; Mark as if GETSIZE were specified

	 push	 POVR_MAC	; Get segment of first MAC in high DOS memory
	 call	 MAC_MERGE	; Merge adjacent free MACs
	MJ c	 FIND_MEM_ERRMAC ; Jump if there's a problem

	 jmp	 FIND_MEM_ERRCOM ; Join common error return code

FIND_MEM_GETSIZE:
	 mov	 ax,LSEG.LSEG_LSIZE.ELO ; Get the load size
	 mov	 dx,LSEG.LSEG_LSIZE.EHI ; ...
	 mov	 PFID_ROOM.ELO,ax ; Ignore any SIZE= parameter
	 mov	 PFID_ROOM.EHI,dx ; ...

	 call	 BYT2PAR	; Convert (DX,AX) in bytes to AX in paras
	 mov	 PRG_NPAR,ax	; Save as # paras in program w/PSP

; Downsize our memory

	 push	 ds		; Reset ES to data
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler about it

; Even if we've relocated ourselves into a hole in low DOS, we still
; need to calculate a (temporary) resident size value.

	 lea	 bx,GTAIL[16-1] ; Get offset of our tail
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 bx,cl		; Convert from bytes to paras
	 mov	 GSIZE_NPAR,bx	; Save for later use

; If GETSIZE_UMB managed to relocate ourselves into high DOS or a previous
; 386LOAD hole, we want to start allocating environment/int block/PSP at
; the DOS high water mark.  Note that the DOS high water mark is NOT
; necessarily the last MAC entry in low DOS; it is the last FREE MAC
; entry in low DOS.
; This is the case if we are loaded via INSTALL=
	 mov	 ax,cs		; Get current PSP
	 cmp	 ax,ORG_PSP	; Have we relocated?
	 je	 short FIND_MEM_XHIGHWATER ; Jump if not

	 mov	 bx,DMAC	; Get start of MAC
	 sub	 ax,ax		; No free MAC entry found
FIND_MEM_HIGHWATER:
	 mov	 es,bx		; Address MAC entry
	 assume  es:nothing	; Tell the assembler

	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Izit available?
	 jne	 short @F	; Jump if not

	 mov	 ax,bx		; Save as high water mark
@@:
	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Izit the end?
	 jne	 short @F	; Jump if not

	 or	 ax,ax		; Did we find anything free?
	MJ z	 FIND_MEM_ERRCOD ; Jump if not

	 mov	 bx,ax		; Last free entry in low DOS
	 jmp	 short FIND_MEM_GETSIZE2 ; Jump if so

@@:
	 add	 bx,es:[0].MAC_NPAR ; Skip to end of block
	 inc	 bx		; Add in MAC entry
	 jmp	 short FIND_MEM_HIGHWATER ; Keep going come hell or ...

FIND_MEM_XHIGHWATER:
;;;;;;;; and	 OPT_FLAG,not (@OPT_PREG or @OPT_EREG) ; Mark as not specified
;;;;;;;; mov	 LSEG.LSEG_PREG,@NOTSPEC ; ...
;;;;;;;; mov	 LSEG.LSEG_EREG,@NOTSPEC ; ...
;;;;;;;;
	 mov	 bx,GSIZE_NPAR	; Get resident GETSIZE paras
	 DOSCALL @MODMEM	; Modify memory block at segment ES-1 to BX paras
;;;;;;;; jc	 short ???	; Jump if something went wrong

	 mov	 dx,cs		; Get current segment
	 add	 bx,dx		; Add to get next segment
FIND_MEM_GETSIZE2:
	 mov	 es,bx		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 EXEC_ENVMAC,es ; Save as environment MAC segment

; Allocate memory for environment low

	 call	 CALC_ENV_NPAR	; Fill in ENV_NPAR from ENV_SIZE
				; We fill this in here (possibly for the
				; second time) since we might have a
				; "suprise GETSIZE" due to lack of memory.

	 mov	 bx,ENV_NPAR	; Get # paras in environment
	 call	 MODMEM 	; Modify memory block ES:0 to BX paras
	MJ c	 FIND_MEM_ERRCOD ; Jump if error, code in AX

; Skip to next region

	 mov	 ax,es		; Get current MAC segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 EXEC_INTMAC,es ; Save as environment MAC segment

; Allocate memory for interrupt handlers low

	 mov	 bx,INT_NPAR	; Get # paras in interrupt handlers
	 call	 MODMEM 	; Modify memory block ES:0 to BX paras
	MJ c	 FIND_MEM_ERRCOD ; Jump if error, code in AX

; Save segment of program MAC entry

	 mov	 ax,es		; Get current MAC segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry
	 mov	 EXEC_PRGMAC,ax ; Save as program MAC segment
FIND_MEM_COM:

; If there's no environment in high DOS, allocate one in
; low DOS.

	 cmp	 ENV_NPAR,0	; Is there an environment in high DOS?
	 jne	 short FIND_MEM_COM1 ; Jump if so

	 mov	 ax,cs		; Copy code segment
	 lea	 bx,GTAIL[16-1] ; Get offset from PSP for GTAIL rounded up
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 bx,cl		; Convert from bytes to paras
	 add	 ax,bx		; Add to get next available para
	 mov	 EXEC_ENVMAC,ax ; Save for later use

; Fill in MAC fields for this pseudo-entry

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,ENV_SIZE	; Get size of environment
	 add	 ax,16-1	; Round up to para boundary
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 ax,cl		; Convert from bytes to paras
	 mov	 es:[0].MAC_NPAR,ax ; Save as pseudo-MAC size in paras
	 mov	 es:[0].MAC_TYPE,@MAC_END ; Mark as ending entry (what else?)
FIND_MEM_COM1:
	 mov	 es,EXEC_ENVMAC ; Get environment MAC segment
	 assume  es:nothing	; Tell the assembler about it
	 mov	 es:[0].MAC_OWNR,@MAC_TEMP ; Save as temporary owner

	 mov	 es,EXEC_INTMAC ; Get interrupt handlers MAC segment
	 assume  es:nothing	; Tell the assembler about it
	 mov	 es:[0].MAC_OWNR,@MAC_TEMP ; Save as temporary owner

	 mov	 ax,EXEC_PRGMAC ; Get program MAC segment
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it
	 mov	 es:[0].MAC_OWNR,@MAC_TEMP ; Save as temporary owner

	 mov	 bx,es:[0].MAC_NPAR ; Get actual # paras in the program region
	 mov	 EXEC_PRGNPAR,bx ; Save for later use

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jz	 short @F	; No, go

	 mov	 bx,TOPFILL	; Get the current TOPFILL value
	 sub	 bx,EXEC_PRGMAC ; Subtract the segment of the EXEC program
	 dec	 bx		; Account for the MAC

	 UMIN	 EXEC_PRGNPAR,bx ; Keep the lesser
@@:
	 inc	 ax		; Count in MAC paragraph
	 call	 FIX_FILEHEAD	; Set EXEC_REL and CS:IP/SS:SP

	 add	 ax,es:[0].MAC_NPAR ; Plus # paragraphs in this entry
	 mov	 cl,10-4	; Shift amount between paras and 1KB
	 shr	 ax,cl		; Convert from paras to 1KB
	 mov	 EXEC_TOP,ax	; Save for later use

	 mov	 ax,EXEC_INTMAC ; Get interrupt handler segment
	 inc	 ax		; Skip over MAC entry
	 mov	 LSEGSEG,ax	; Save for later use

	 clc			; Indicate all went well

	 jmp	 short FIND_MEM_EXIT ; Join common exit code

; Error code in AX

FIND_MEM_ERRCOD:

; Release any memory we've allocated

	 call	 FREE_MACS	; Free 'em up

	 cmp	 ax,@DOSERR_XMAC ; Check for MAC destroyed
	 je	 short FIND_MEM_ERRMAC ; Jump if a match

	 cmp	 ax,@DOSERR_XMEM ; Check for insufficient memory
	MJ e	 FIND_MEM_NOROOM ; Jump if a match

	 lea	 ax,AZS_UGHUGH	; Tell 'em the bad news

	 jmp	 short FIND_MEM_ERRCOM0 ; Join common error code

	 assume  es:nothing	; Tell the assembler about it

FIND_MEM_ERRMAC:
	 lea	 ax,AZS_ERRMAC	; Tell 'em the bad news
FIND_MEM_ERRCOM0:
	 push	 ax		; Pass message offset
	 call	 DISP_ERRMSG	; Display an error message
FIND_MEM_ERRCOM:
if @OEM_FLEX
	 call	 REST_EMS	; De-allocate any EMS memory
endif				; IF @OEM_FLEX

	 stc			; Indicate something went wrong
FIND_MEM_EXIT:
	 REGREST <es,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FIND_MEM endp			; End FIND_MEM procedure
	 NPPROC  EMU_GETMEM -- Emulate DOS GETMEM Call
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Allocate memory (emulate DOS call 48h)

On entry:

SS:BP	 ==>	 ARG_STR
BX	 =	 # paras to allocate

On exit:

CF	 =	 0 if successful
AX:0	 ==>	 allocated block

CF	 =	 1 if not successful
AX	 =	 error codes
BX	 =	 size of largest available block

|

	 REGSAVE <di,ds>	; Save registers

	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 MACLOC,@MACLOC_LO ; Use low fit algorithm in designated block
	 mov	 MACALG,0	; By default, use first fit

	 cmp	 DOSVER,0314h	; Izit DOS 3.20 or later?
	 jb	 short EMU_GETMEM1 ; No, use first fit

	 mov	 al,0		; Function code to return current algorithm
	 DOSCALL @MACALG	; Return with AX=0, 1, or 2

	 mov	 MACALG,al	; Save as current algorithm
EMU_GETMEM1:
	 mov	 di,[bp].ARG_CSIP.VSEG ; Get caller's segment

	 call	 FIND_OWNER	; Find owner of segment DI
	 jc	 short EMU_GETMEM_EXIT ; Oops, CF=1, AX=code

	 call	 GETMEM 	; Allocate BX paras returning AX=allocated block
				; Pass error flag in CF to caller
EMU_GETMEM_EXIT:
	 REGREST <ds,di>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

EMU_GETMEM endp 		; End EMU_GETMEM procedure
	 NPPROC  INT22_CLEANUP -- Convert PSP MAC owner to @MAC_LOADLO
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Set owner of MAC for our PSP to @MAC_LOADLO so subsequent 386LOAD.COM
instances can use it.

On entry:
Entry via PSP_TERMINATE

On exit:
Jump to previous PSP_TERMINATE

|

	 pushf			; Save IF
	 cli			; Nobody move

	 REGSAVE <ax,es>	; Save (although it's not really necessary)

	 mov	 ax,cs		; Address our PSP
	 dec	 ax		; Back off to MAC entry
	 mov	 es,ax		; Address MAC entry
	 assume  es:nothing	; Tell the assembler

	 mov	 es:[0].MAC_OWNR,@MAC_LOADLO ; Make it a 386LOAD hole

	 REGREST <es,ax>	; Restore
	 assume  es:nothing	; Tell the assembler

	 popf			; Restore interrupt flag

	 public  PREV_INT22
	 db	 @OPCOD_JMPF	; Far jump immediate
PREV_INT22 dd	 ?		; Previous PSP_TERMINATE

	 assume  ds:nothing,es:nothing,ss:nothing

INT22_CLEANUP endp		; End INT22_CLEANUP procedure
	 NPPROC  TSRCOM_SUB -- TSR Common Loader Subroutine
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Load TSR into high DOS memory.

This procedure jumps to itself with GETSIZE in effect if an attempt
to load high fails.

|

	 mov	 ORG_PSP,cs	; Save original PSP for later comparison
	 call	 TOPFILL_CHECK	; Check the TOPFILL value

if @OEM_FLEX
	 cmp	 POVR_MAC,-1	; Any high DOS memory?
	 je	 short @F	; Jump if not

; Allocate and map EMS memory so we have maximum amounts to find

	 call	 INST_EMS	; Install it

; Install INT 67h handler if appropriate

	 call	 INST67 	; Install it
@@:
endif				; IF @OEM_FLEX
; During FIND_MEM we begin using space above GTAIL.

	 test	 OPT_FLAG,@OPT_GSIZE ; Was GETSIZE specified?
	 jz	 short @F	; Jump if not

	 FCALL	 GETSIZE_UMB	; If we can fit in high DOS, return to
				; the following location in high DOS

	 call	 FIND_MEM	; Find low DOS memory for GETSIZE
	 jnc	 short INIT_STACK ; Join common code if OK

	 jmp	 ERR_EXIT	; It's totally hopeless

@@:
	 call	 FIND_MEM	; Find high DOS memory
	 jc	 short TSRCOM_SUB ; If we failed, go around again with
				; GETSIZE already in effect

INIT_STACK:
	 call	 LOADHI 	; Load the file into memory
	MJ nc	 NORM_EXIT	; Jump if normal exit

; If GETSIZE not in effect, attempt to load the program into low memory

INSTALL_LOW:
if @OEM_SYS eq @OEMSYS_3COM
	 or	 LCL_FLAG,@LCL_DISP ; Mark as displayed
endif				; IF @OEM_SYS eq @OEMSYS_3COM

if @OEM_FLEX
; Restore INT 67h if intercepted

	 call	 REST67 	; Restore it

; De-allocate any EMS memory

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jnz	 short @F	; Yes, than INST_EMS not called

	 call	 REST_EMS	; Restore it
@@:
endif				; IF @OEM_FLEX

	 test	 OPT_FLAG,@OPT_GSIZE or @OPT_NORETRY ; Is GETSIZE specified, or NORETRY?
	MJ nz	 ERR_EXIT	; Yes, so just quit

	 lea	 ax,AZS_LOADLO	; The load failed, loading low
	 call	 NOLOAD_PRESS	; Call common NOLOAD and PRESS routines

; Go around again with forced GETSIZE in effect

	 call	 FORCE_GETSIZE	; Turn on GETSIZE, turn off FLEXFRAME
	 jmp	 short TSRCOM_SUB ; Go around again

ERR_EXIT:

; Release any memory we've allocated if GETSIZE was used

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE specified?
	 jz	 short @F	; Not this time

	 call	 FREE_MACS	; Free 'em up
@@:
	 test	 OPT_FLAG,@OPT_VER ; Wuzit just /V ?
	 jnz	 short @F	; Yes, skip NOLOAD message

	 test	 LSEG.LSEG_FLAG,@LSEG_INST ; Called via DOS 4.x INSTALL?
	 jnz	 short @F	; Yes, don't complain if the program didn't
				; go resident or was a UMB allocator

	 lea	 ax,AZS_NOLOAD	; The load failed, no hope
	 call	 NOLOAD_PRESS	; Call common NOLOAD and PRESS routines
@@:
	 jmp	 TSRCOM_EXIT	; Join common exit code

NORM_EXIT:
	 mov	 ax,EXEC_INTMAC ; Get interrupt handler segment
	 inc	 ax		; Skip over MAC entry
	 mov	 LSEGSEG,ax	; Save for later use

	 call	 LINK_LSEG	; Link into the LSEG chain

; If 386LOAD GETSIZE is in effect, there are UMBs allocated and we've
; marked it as a non-resident program, we need to set the ownership of
; the LSEG MAC to @MAC_LSEG so it doesn't get freed and unlinked in
; CHECK_ORPHSUB...
	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE requested?
	 jz	 short NORM_EXIT2 ; Jump if not

	 mov	 cx,LSEG.LSEG_FLAG ; Get flags
	 and	 cx,(@LSEG_UMB or @LSEG_XRES) ; Isolate flags to test
	 cmp	 cx,(@LSEG_UMB or @LSEG_XRES) ; Did it load itself high
				; with nothing left low?
	 jne	 short NORM_EXIT2 ; Jump if not

	 mov	 es,EXEC_INTMAC ; Address LSEG MAC entry
	 assume  es:nothing	; Tell the assembler

	 mov	 es:[0].MAC_OWNR,@MAC_LSEG ; Set owner to prevent deletion
	 and	 es:[(size MAC_STR)].LSEG_FLAG,not @LSEG_UMB ; Mask off UMB flag
	 mov	 es:[(size MAC_STR)].LSEG_INSTLO,-1 ; Make sure it doesn't
				; get unlinked by the next transient program
NORM_EXIT2:
; Save the back link to the LSEG entry in our program's MAC entry
	 mov	 es,EXEC_PRGMAC ; Address program's MAC entry
	 assume  es:nothing	; Tell the assembler

	 dec	 ax		; Back off to MAC entry
	 mov	 es:[0].MAC_BACK,ax ; Save back link to LSEG MAC entry

	 test	 OPT_FLAG,@OPT_GSIZE ; GETSIZE requested?
	MJ z	 NORM_EXIT1 ; No, don't bother going resident

; Before going resident, free our own environment

; Because of a difference in DOS 5.x, we must handle the case where
; our environment segment # is zero.

	 mov	 cx,PSP_ENVIR_PTR ; Get segment # of our environment
	 jcxz	 @F		; Jump if not present

	 mov	 es,cx		; Address it
	 assume  es:nothing	; Tell the assembler about it
	 DOSCALL @RELMEM	; Release it, ignore error return
@@:

;;;;;;;; Create our own environment within the PSP using the program name
;;;;;;;
;;;;;;;  mov	 ax,cs		; Copy code segment
;;;;;;;  cmp	 ax,POVR_MAC	; Are we in high DOS?
;;;;;;;  jnb	 short NORM_EXIT_ENVFREE ; Continue if so
;;;;;;;
;;;;;;;  mov	 es,ax		; Address through ES
;;;;;;;  assume  es:PGROUP	; Tell the assembler about it
;;;;;;;
;;;;;;;  lea	 bx,PSP_PARM_COUNT ; Get offset of start
;;;;;;;  mov	 cl,4-0 	; Shift amount between bytes and paras
;;;;;;;  shr	 bx,cl		; Convert from bytes to paras
;;;;;;;  add	 ax,bx		; Add in # paras to environment
;;;;;;;  mov	 PSP_ENVIR_PTR,ax ; Save as our pointer
;;;;;;;  mov	 PSP_PARM_COUNT[-16],0 ; Ensure not 'M' or 'Z'
;;;;;;;
;;;;;;;  mov	 ax,EXEC_ENVMAC ; Get segment of high DOS memory environment
;;;;;;;
;;;;;;;  and	 ax,ax		; Izit valid?
;;;;;;;  jz	 short NORM_EXIT_ENVFREE ; Jump if not
;;;;;;;
;;;;;;;  push	 ds		; Save for a moment
;;;;;;;
;;;;;;;  inc	 ax		; Skip over MAC entry
;;;;;;;  mov	 ds,ax		; Address it
;;;;;;;  assume  ds:nothing	; Tell the assembler about it
;;;;;;;
;;;;;;;  lea	 di,PSP_PARM_COUNT ; ES:DI ==> destin
;;;;;;;  mov	 ax,0000h	; Leading separator
;;;;;;;  stosw			; Save in "environment"
;;;;;;;  mov	 ax,0001h	; Leading separator
;;;;;;;  stosw			; Save in "environment"
;;;;;;;  mov	 si,ENV_HEAD	; DS:SI ==> source
;;;;;;;  mov	 cx,ENV_TAIL	; CX = size of environment tail
;;;;;;;     rep movsb			; Copy to local area
;;;;;;;
;;;;;;;  pop	 ds		; Restore
;;;;;;;  assume  ds:PGROUP	; Tell the assembler about it
NORM_EXIT_ENVFREE:

; Go resident

	 mov	 dx,GSIZE_NPAR	; Get # paras needed to go resident w/GETSIZE

; Free all our file handles

	 mov	 cx,PSP_FILE_TAB_SIZ ; Get # file handles in table
	 jcxz	 NORM_EXIT0	; Jump if none
	 xor	 bx,bx		; Initialize index into STD_FILES
@@:
	 DOSCALL @CLOSF2	; Close the file handle
;;;;;;;; jc	 ???		; Ignore error return

	 inc	 bx		; Skip to next file handle

	 loop	 @B		; Jump if more handles to force duplicate
NORM_EXIT0:
	 mov	 ax,cs		; Get current PSP
	 cmp	 ax,POVR_MAC	; Are we in high DOS?
	 jnb	 short TSRCOM_EXIT ; Jump if so (don't go resident)

; We're not going resident, but we want to leave the hole plugged by
; a @MAC_LOADLO entry so subsequent 386LOAD.COM instances can take
; advantage of it.  We'll go resident, regain control via PSP_TERMINATE,
; change our MAC entry, and immediately jump to the previous terminate
; address.

; Get previous Int 22 vector and set it to our cleanup code
	 mov	 ax,offset PGROUP:INT22_CLEANUP ; Get cleanup return offset
	 xchg	 ax,PSP_TERMINATE.VOFF ; Save and get previous offset
	 mov	 PREV_INT22.VOFF,ax ; Save previous offset

	 mov	 ax,cs		; Get cleanup return segment
	 xchg	 ax,PSP_TERMINATE.VSEG ; Save and get previous segment
	 mov	 PREV_INT22.VSEG,ax ; Save previous segment

	 mov	 al,END_RET	; Get return code
	 DOSCALL @KEEPRC	; Go resident with return code
	 int	 20h		; Be safe if on DOS 4.00 Version 1.x

NORM_EXIT1:
	 test	 LSEG.LSEG_FLAG,@LSEG_INST ; Called via DOS 4.x INSTALL?
	 jz	 short TSRCOM_EXIT ; Jump if not

	 call	 INFO_READ	; Read in INFO structure

; Tell the code in 386MAX to lie once about the @GETRC value

	 or	 MSC_FLAG,@MSC_GETRC ; Tell 'em to lie

	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 call	 INFO_WRITE	; Write it back out
TSRCOM_EXIT:
	 mov	 ax,cs		; Get current PSP
	 cmp	 ax,POVR_MAC	; Are we in high DOS?
	 jb	 short TSRCOM_EXIT1 ; Jump if not

; We need to free ourselves in high DOS manually; DOS won't do it since
; we leave high DOS unlinked.

	 dec	 ax		; Back off to MAC entry
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler

	 mov	 es:[0].MAC_OWNR,0 ; Free ourselves
	 push	 POVR_MAC	; Starting MAC entry to merge
	 call	 MAC_MERGE	; Merge free MAC entries in high DOS

TSRCOM_EXIT1:
	 mov	 al,END_RET	; Get return code
	 DOSCALL @EXITRC	; Return to DOS with exit code

	 assume  ds:nothing,es:nothing,ss:nothing

TSRCOM_SUB endp 		; End TSRCOM_SUB procedure
	 NPPROC  FREE_MACS -- Free All Allocated MAC Entries
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Free all allocated MAC entries

If we've still allocated some interrupt vectors,
don't free INTMAC.

|

	 REGSAVE <cx>		; Save register

	 mov	 cx,EXEC_ENVMAC ; Get environment MAC segment
	 call	 EXEC_FREE	; Free it
	 mov	 EXEC_ENVMAC,0	; Mark as unallocated

	 mov	 cx,EXEC_INTMAC ; Get interrupt handler MAC segment
	 call	 EXEC_FREE	; Free it
	 mov	 EXEC_INTMAC,0	; Mark as unallocated

	 mov	 cx,EXEC_PRGMAC ; Get program MAC segment
	 call	 EXEC_FREE	; Free it
	 mov	 EXEC_PRGMAC,0	; Mark as unallocated

	 REGREST <cx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FREE_MACS endp			; End FREE_MACS procedure
	 NPPROC  EXEC_FREE -- Free An EXEC MAC Entry
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Free a EXEC_xxxMAC entry

On entry:

CX	 =	 initial MAC entry to free

|

	 REGSAVE <ax,es>	; Save registers

	 jcxz	 EXEC_FREE_EXIT ; Jump if not allocated

	 mov	 es,cx		; Address program MAC
	 assume  es:nothing	; Tell the assembler about it

; Ensure valid MAC entry

	 mov	 al,es:[0].MAC_TYPE ; Get MAC entry type

	 cmp	 al,@MAC_MID	; Izit a middle entry?
	 je	 short @F	; Yes

	 cmp	 al,@MAC_END	; Izit an ending entry?
	 jne	 short EXEC_FREE_ERR ; No, so that's an error
@@:
	 mov	 es:[0].MAC_OWNR,@MAC_FREE ; Mark as free

;;;;;;;; jmp	 short EXEC_FREE_EXIT ; Join common exit code

; Memory chain allocation error

EXEC_FREE_ERR:



EXEC_FREE_EXIT:
	 REGREST <es,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

EXEC_FREE endp			; End EXEC_FREE procedure
	 NPPROC  DISP_ASCIIZ -- Display ASCIIZ String To Handle
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Write string to specified handle.

|

DISP_AZS_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
DISP_AZS_OFF dw  ?		; Offset of ASCIIZ string
DISP_AZS_HNDL dw ?		; Handle to use

DISP_AZS_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,dx,di,ds,es> ; Save registers

	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 cs		; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

; Calculate message length for @WRITF2

	 cld			; String ops forwardly
	 mov	 di,[bp].DISP_AZS_OFF; ES:DI ==> AZS message to display
	 mov	 al,0		; ASCIIZ string terminator
	 mov	 cx,-1		; We know it's there
   repne scasb			; Search for it
	 inc	 cx		; Back up
	 inc	 cx
	 neg	 cx		; Negate to get length

	 mov	 bx,[bp].DISP_AZS_HNDL ; Get specified handle
	 mov	 dx,[bp].DISP_AZS_OFF; DS:DX ==> error message
	 DOSCALL @WRITF2	; Write it out

	 REGREST <es,ds,di,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_ASCIIZ endp		; End DISP_ASCIIZ procedure
	 NPPROC  FCN_DISPLAY -- Display The Argument Line
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Display the argument line

|

FCN_DISPLAY_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
FCN_DISPLAY_HNDL dw ?		; Handle to use

FCN_DISPLAY_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,ds>	; Save registers

	 push	 cs		; Setup DS for data references
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 test	 LCL_FLAG,@LCL_DISP ; Already displayed?
	 jnz	 short FCN_DISPLAY_EXIT ; Yes, don't do it again

	 or	 LCL_FLAG,@LCL_DISP ; Mark as displayed

	 call	 NEWLINE	; Ensure we're starting on a new line

	 xor	 bh,bh		; Zero to use as word
	 mov	 bl,PSP_PARM_COUNT ; Get length of argument line

	 and	 bx,bx		; Any characters?
	 jz	 short FCN_DISPLAY_EXIT ; Not this time
FCN_DISPLAY_NEXT:
	 mov	 al,PSP_PARM_COUNT[bx] ; Get last character

	 cmp	 al,' '         ; Check for white space
	 je	 short FCN_DISPLAY_WHITE ; Good guess

	 cmp	 al,TAB 	; Check for white space
	 jne	 short FCN_DISPLAY1 ; Not this time
FCN_DISPLAY_WHITE:
	 dec	 bx		; One less trailing character

	 jmp	 short FCN_DISPLAY_NEXT ; Go around again

FCN_DISPLAY1:
	 and	 bx,bx		; Any text to display?
	 jz	 short FCN_DISPLAY_EXIT ; Not this time

	 mov	 cl,0		; ASCIIZ terminator
	 xchg	 cl,PSP_PARM_STRING[bx] ; Convert to ASCIIZ string

	 push	 [bp].FCN_DISPLAY_HNDL ; Send to specified handle
	 lea	 ax,AZS_386LOAD ; Display "386LOAD "
	 push	 ax		; Pass message offset
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 push	 [bp].FCN_DISPLAY_HNDL ; Send to specified handle
	 lea	 ax,PSP_PARM_STRING ; Display the argument line
	 push	 ax		; Pass message offset
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 xchg	 cl,PSP_PARM_STRING[bx] ; Restore to original value

	 push	 [bp].FCN_DISPLAY_HNDL ; Send to specified handle
	 lea	 ax,AZS_CRLF	; Display the line terminators
	 push	 ax		; Pass message offset
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle
FCN_DISPLAY_EXIT:
	 REGREST <ds,cx,bx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_DISPLAY endp		; End FCN_DISPLAY procedure
	 NPPROC  DISP_ERRMSG -- Display Error Message
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Display an error message.

|

DISP_ERR_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
DISP_ERR_OFF dw  ?		; Offset of error message

DISP_ERR_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 test	 LCL_FLAG,@LCL_PSP ; Izit intercepted?
	 jz	 short DISP_ERRMSG1 ; Not this time

; Restore old PSP

	 REGSAVE <ax,bx,ds>	; Save registers

	 push	 cs		; Setup DS for data references
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 bx,CURPSP	; Get old PSP
	 DOSCALL @SETPSP	; Restore it
	 and	 LCL_FLAG,not @LCL_PSP ; Mark as no longer intercepted

	 REGREST <ds,bx,ax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

DISP_ERRMSG1:
	 call	 DISP_COPY	; Show'em who we are
	 push	 STD_ERR	; Send to standard error output
	 call	 FCN_DISPLAY	; Display the argument line to specified handle

	 push	 STD_ERR	; Send to standard error output
	 push	 [bp].DISP_ERR_OFF; Write out the error message
	 call	 DISP_ASCIIZ	; Display the ASCIIZ string to handle

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_ERRMSG endp		; End DISP_ERRMSG procedure

	 NPPROC  DISP_COPY -- Display copyright notice and ID info
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

If copyright notice and ID info have not yet been displayed, do it.
Set the first byte of MSG_COPY to 0 so we don't do it twice.

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 cmp	 MSG_COPY,0	; Izit already displayed?
	 jz	 short DISP_COPY_EXIT ; Jump if so

	 lea	 dx,MSG_COPY	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 mov	 MSG_COPY,0	; Clear it

	 mov	 dx,PBID_MSG	; Get pointer to ID message
	 or	 dx,dx		; Izit NULL?
	 jz	 short DISP_COPY_EXIT ; Jump if so

	 mov	 bx,dx		; Get pointer
	 add	 bx,ID_LEN	; Add length of message
	 mov	 PGROUP:[bx].LO,EOS ; Set up for STROUT

	 call	 STROUT 	; Display string with line checking
				; (Lines in ID message - 1 already added
				; to LINECNT)
DISP_COPY_EXIT:
	 REGREST <dx,cx,bx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_COPY endp			; End DISP_COPY procedure

	 NPPROC  ACT_HELP -- Display help screen
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Display help screen and return

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 mov	 cx,HELP_LEN	; CX = # bytes in message
	 mov	 bx,@STD_OUT	; Send to standard output handle
	 DOSCALL @WRITF2,HELP_TEXT ; Display the message

	 call	 CHECK_LINE	; Count in another line and check for pause

	 call	 DISP_COPY	; Display copyright notice at end


	 REGREST <dx,cx,bx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_HELP endp			; End ACT_HELP procedure
	 NPPROC  CALC_ENV_NPAR -- Fill in ENV_NPAR
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Fill in ENV_NPAR and return

|

	 REGSAVE <ax,cx>	; Save registers

	 mov	 ax,ENV_SIZE	; Get size of environment
	 add	 ax,16-1	; Round up to para boundary
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 ax,cl		; Convert from bytes to paras
	 mov	 ENV_NPAR,ax	; Save as # paras in environment
	 inc	 ax		; Count in MAC paragraph
	 mov	 LSEG.LSEG_EPAR0,ax ; Save for later use

	 REGREST <cx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CALC_ENV_NPAR endp			; End CALC_ENV_NPAR procedure

NCODE	 ends			; End NCODE segment

	 MEND			; End TSRCOM module
