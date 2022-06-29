;'$Header:   P:/PVCS/MAX/EXTRADOS/HARP_FCN.ASV   1.1   30 May 1997 11:13:08   BOB  $
	 title	 HARP_FCN -- Argument parsing routines for HARPO
	 page	 58,122
	 name	 HARP_FCN

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-7 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  dword-aligned,public, class 'data'
	       Stack   segment STACK, para-aligned, stack,  class 'stack'

|
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include KEYCALL.INC
	 include ASCII.INC
	 include PTR.INC
	 include DEVDRV.INC
	 include MAC.INC

	 include EMM2CALL.INC
	 include SEGS.INC
	 include HARPO.INC
	 include LOAD_SEG.INC
.list



;*******************************************************************

XCODE	 segment		; Code in QMAX_MBT

extern	 INIT_MBOOT:far 	; Detect Multiboot
extern	 CHECK_MBOOT:far	; Check for Multiboot lines

XCODE	 ends


XDATA	 segment dword public 'xdata'   ; Start XDATA segment
	 assume  ds:XGROUP

	 extern  MBOOT_SECTION:byte
	 extern  CMP_COMMON:byte

	 public  MBOOT_LBR,MBOOT_RBR
MBOOT_LBR db	 CR,LF,'['      ; Left bracket for [section name]
MBOOT_LBR_LEN equ $-MBOOT_LBR	; Length of ...
MBOOT_RBR db	 ']',CR,LF      ; Right ...
MBOOT_RBR_LEN equ $-MBOOT_RBR	; Length of ...

	 public  ONTRACK
ONTRACK  db	 'ONTRACK',0    ; Signature of OnTrack's DDO driver
ONTRACK_LEN equ  $-ONTRACK	; Length of ...

	 public  MODEL_LINE
MODEL_LINE db	 'MODEL='
MODEL_VAL  db	 '?',CR,LF,EOF
MODEL_LEN equ	 $-MODEL_LINE	; Length of ...

	 public  MODEL_OFF
MODEL_OFF dw	 ?		; Offset in XGROUP of model # value

XDATA	 ends


HCODE	 segment		; Start Resident Code segment
	 assume  ds:PGROUP

extern	 DATASEG:word		; Our Data Segment
extern	 CCOM_REGION:byte	; Region of CCOM
extern	 ENV_REGION:byte	; Region of master environment
extern	 SHARE_REGION:byte	; Region of SHARE
extern	 CCOM_LEN:word		; Length in paras
extern	 ENV_LEN:word		; Length in paras
extern	 PRESSANY:near		; Press any Key to Continue
extern	 GET_TOKEN:near 	; Returns DI ==> next token in list
extern	 CONFIG_NEXT:word	; Storage for DOS next-para pointer
extern	 DOSVER:word		; DOS version number
extern	 FILES_REG:byte 	; FILES= region
extern	 DISP_COPY:near 	; Display Copyright message

extern	 PORT67:word		; MAX's backdoor port (usually F084)

extern	 LSEG:LSEG_STR		; COMMAND.COM's LSEG structure

extern	 RH_VEC:VECTOR		; Request header
extern	 MODELNO:byte		; Model #

;-------------- Pass (0,1,2) variables ------------------------

	 public  CURR_PASS
CURR_PASS db	 ?	; Current Pass variable

	 public  @PASS_DEV,@PASS_INS,@PASS_CMD,@PASS_ALL
@PASS_DEV equ	 0	; DEVICE=      time
@PASS_INS equ	 1	; INSTALL=     time
@PASS_CMD equ	 2	; Command Line time (ignore this case)
@PASS_ALL equ	 -1	; Both DEVICE= and INSTALL= time


;------------ Profile string ----------------------------

	 public  FILESPEC
FILESPEC db	 80 dup (0)	; Profile filespec

	 public  DEAD_DEV,DEAD_INS,DEAD_OFLOW
DEAD_DEV db	 @DEAD_DEV	; DEVICE=  DeadMan switch
DEAD_INS   db	 @DEAD_INS	; INSTALL= DeadMan switch
DEAD_OFLOW db	 @DEAD_OFLOW	; Subseg overflow DeadMan switch

	 public  DEAD_NAME,DEAD_FTIME,DEAD_FDATE
DEAD_NAME  dw	 ?		; Name of applicable DeadMan switch
DEAD_FTIME dw	 ?		; Time stamp of profile
DEAD_FDATE dw	 ?		; Date stamp of profile


;***************************************************************************

	 NPPROC  REMOVE_DEAD -- REMOVE_DEAD procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Remove the Deadman switch from the profile

On entry:
CX	=	Segment for Read Buffer

The DeadMan switch can be one of a few possibilities...
OVERFLOW	- Subsegment overrun
NOLOADHI = D	- Lockup with DEVICE=
NOLOADHI = I	- Lockup with INSTALL=


|

@READ_OFF equ	 10h		; Read buffer should be 1 paragraph
				; from the beginning of our segment

	 REGSAVE <ax,bx,cx,dx,si,di,bp,ds,es> ; Save registers

	 cmp	 CURR_PASS,@PASS_CMD ; Coming from the command line?
	 je	 EXIT		; Jump if so (no need for DeadMan switch)

; Address our resident data

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 push	 cs		; Address our data
	 pop	 es		; ... via ES
	 assume  es:PGROUP	; Tell the assembler about it

; Open the profile

	 mov	 ax,3D02h	; DOS: Open file for Read/Write
	 lea	 dx,FILESPEC	; Address of profile
	 int	 21h		; Open the profile
	 jc	 OPEN_ERR	; Jump if profile not found

	 mov	 bx,ax		; Save file handle

; Read in the profile

	 mov	 ds,cx		; Read Buffer Segment
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ah,@READF2	; DOS: read from file (3Fh)
;;;;;;;; mov	 bx,??		; File handle (already set)
	 mov	 cx,-1		; Number of bytes to read in
	 mov	 dx,@READ_OFF	; DS:DX => Read buffer (skip 1 para)
	 int	 21h		; Read in the profile
	 jc	 READ_ERR	; Jump if read error

	 mov	 bp,ax		; Save file size

; Close the profile

	 mov	 ah,@CLOSF2	; DOS: Close file function (3Eh)
;;;;;;;; mov	 bx,??		; File handle (already set)
	 int	 21h		; Close the profile

; Does the first line contain the DeadMan switch?

	 mov	 si,@READ_OFF	; Address beginning of buffer
	 mov	 di,DEAD_NAME	; Address of model to search for
	 mov	 cx,@DEAD_LEN	; Length of switch

    repe cmpsb			; Is it the deadman switch?
	 jne	 NO_DEADMAN	; Jump if not

; Search for the start of the second line

	 push	 ds		; Address the buffer
	 pop	 es		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

	 mov	 di,@READ_OFF	; Address beginning of buffer
	 mov	 cx,-1		; Length of longest line
	 mov	 al,LF		; Look for a LF
   repne scas	 BPTR es:[di]	; Look for EOL

; Skip over the first line

	 neg	 cx		; Get number of bytes till EOL
	 dec	 cx		; Account for ??
	 sub	 bp,cx		; Calculate new file size

; BP	= Size of new profile
; DS:SI = Address of start of this file

; Create a new profile (truncate to 0 length)

	 REGSAVE <ds>		; Save segment of read buffer

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ah,@CREAF2	; DOS: Create a 0 byte file (3Ch)
	 mov	 cx,0		; Normal attirbutes
	 lea	 dx,FILESPEC	; Address of profile
	 int	 21h		; Create the 0 byte profile

	 REGREST <ds>		; Restore segment of read buffer
	 assume  ds:nothing	; Tell the assembler about it
	 jc	 CREATE_ERR	; Jump if error

	 mov	 bx,ax		; Save file handle

; Write out the new profile

	 mov	 ah,@WRITF2	; DOS: Write file function
	 mov	 cx,bp		; File size
;;;;;;;; mov	 bx,??		; File handle (already set)
	 mov	 dx,di		; Update pointer to skip first line
	 int	 21h		; Write the profile to disk
;;;;;;;; jc	 WRITE_ERR	; Jump if error

; Restore the previous time/date stamp
	 mov	 ax,(@GSTDAT*256)+01h ; Set file time/date stamp
	 mov	 cx,DEAD_FTIME	; Time stamp before we added deadman switch
	 mov	 dx,DEAD_FDATE	; Date stamp ...
	 DOSCALL		; Set time/date for BX when it's closed
;;;;;;;  jc	 ???		; Ignore error

; Close the profile

READ_ERR:
	 mov	 ah,@CLOSF2	; DOS: Close file function (3Eh)
;;;;;;;; mov	 bx,??		; File handle (already set)
	 int	 21h		; Close the profile

OPEN_ERR:
CREATE_ERR:
NO_DEADMAN:
EXIT:
	 REGREST <es,ds,bp,di,si,dx,cx,bx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
REMOVE_DEAD	 endp		; End REMOVE_DEAD procedure


;****************************************************************************

HCODE	 ends			; End Resident Code segment


;****************************************************************************

HDATA	 segment		; Start Non-Resident Data segment


;--------------- Messages ----------------------------


;--------------- Error messages ----------------------------

	 extern  MSG_DD_HELP:byte
	 extern  MSG_NOPRO:byte
	 extern  MSG_OFLOW:byte
	 extern  MSG_DEADMAN:byte
	 extern  MSG_PRO_UNK:byte

;-------------- Profile parsing variables ------------------------

PRO_FCN  struc				; Profile option structure
   TEXTSTR	db	10 dup (?)	; Actual text
   TEXTLEN	db	?		; Text length
   PASS 	db	?		; 0, 1, or -1
   PTRFCN	dw	?		; Ptr to action routine
PRO_FCN ends				; End of structure

	 public  PRO_FCNS
PRO_FCNS label	 PRO_FCN	; List of all valid profile options

	 PRO_FCN <'DEBUG',      5, -1, FCN_DEBUG>       ; Enable debugging
	 PRO_FCN <'GETSIZE',    7, -1, FCN_GETSIZE>     ; Enable Getsize mode
	 PRO_FCN <'VERBOSE',    7, -1, FCN_VERBOSE>     ; Display copyright

	 PRO_FCN <'C',          1,  1, FCN_COMSPEC>     ; Relocate COMSPEC
	 PRO_FCN <'E',          1,  1, FCN_ENV>         ; Relocate master Environment
	 PRO_FCN <'SHARE',      5,  1, FCN_SHARE>       ; Relocate SHARE
	 PRO_FCN <'NOPSP',      5,  1, FCN_NOPSP>       ; Don't create fake PSP

	 PRO_FCN <<@TOKEN_FILES>,   1, 0, FCN_FILES>	; FILES=   command
	 PRO_FCN <<@TOKEN_FCB>,     1, 0, FCN_FCBS>	; FCB=	   command
	 PRO_FCN <<@TOKEN_BUFFERS>, 1, 0, FCN_BUFFERS>	; BUFFERS= command
	 PRO_FCN <<@TOKEN_LASTDRV>, 1, 0, FCN_LASTDRV>	; LASTDRV= command
	 PRO_FCN <<@TOKEN_STACKS>,  1, 0, FCN_STACKS>	; STACKS=  command
	 PRO_FCN <<@TOKEN_DOS3>,    1, 0, FCN_ALL>	; All DOS 3.3 Subsegs
	 PRO_FCN <<@TOKEN_BATCH>,   1, 0, FCN_BATCH>	; Temp. batch storage
	 PRO_FCN <<@TOKEN_IFS_G>,   1, 0, FCN_IFS_G>	; IFS-G
	 PRO_FCN <<@TOKEN_IFS_H>,   1, 0, FCN_IFS_H>	; IFS-H
	 PRO_FCN <<@TOKEN_IFS_R>,   1, 0, FCN_IFS_R>	; IFS-R
	 PRO_FCN <<@TOKEN_IFS_Y>,   1, 0, FCN_IFS_Y>	; IFS-Y

	 PRO_FCN <'OVERFLOW',   8,  0, FCN_OVERFLOW>    ; Subseg overflow
	 PRO_FCN <'NOLOADHI',   8, -1, FCN_DEADMAN>     ; DeadMan SWITCH

	 PRO_FCN <'MODEL',      5, -1, FCN_MODEL>       ; Model #

@FCN_LAST equ $ 		; Address of last keyword entry

	 public  PRO_TOKEN
PRO_TOKEN db	 ?	; Current token being processed in profile


;----------------------------------------


HDATA	 ends			; End non-Resident Data segment

;****************************************************************************

HNCODE	 segment		; Start Non-Resident Code Segment
	 assume  cs:PGROUP

extern	 LOWERCASE:near 	; Convert character in AL to lowercase
extern	 UPPERCASE:near 	; Convert character in AL to uppercase
extern	 SKIP_WHITE:near	; Skip over white space
extern	 SKIP_BLACK:near	; Skip over black space
extern	 FMT_WORD:near		; Foramt AX => ES:DI
extern	 BASE2BIN:near		; Convert text number to hexadecimal (16bit)
extern	 BASE2BIND:near 	; Convert text number to hexadecimal (32bit)

;****************************************************************************

	 NPPROC  IZITCOMMENT -- Check for a comment delimiter
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

If AL is a comment delimiter (; or *) return ZR, otherwise NZ.

|

	 cmp	 al,';'         ; Izit a comment delimiter?
	 je	 short @F	; Jump if so

	 cmp	 al,'*'         ; Izit other comment delimiter?
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

IZITCOMMENT endp		; End IZITCOMMENT procedure
	 NPPROC  DD_PARSE -- Parse Device Driver Command Line
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Parse the device driver command line.


On entry:
ES:BX	 ==>	 request header

|

	 REGSAVE <ax,cx,dx,si,di,ds,es> ; Save registers

	 lds	 si,es:[bx].INIT_STR.INIT_CMD_VEC ; DS:SI ==> command line
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 es,DATASEG	; Setup addressibility to DGROUP
	 assume  ds:DGROUP	; Tell the assembler about it

	 call	 SKIP_WHITE	; Skip over white space
				; Return with AL = char, DS:SI ==> next
	 call	 SKIP_BLACK	; Skip over black space
				; Return with AL = char, DS:SI ==> next

SKIPWHITE:
	 lodsb			; Get next character

	 cmp	 al,' '         ; Izit white space?
	 je	 SKIPWHITE	; Jump if so

	 cmp	 al,TAB 	; Izit white space?
	 je	 SKIPWHITE	; Jump if so

	 cmp	 al,CR		; Izit a CR?
	 je	 DD_PARSE_CLC	; Jump if so

	 cmp	 al,LF		; Izit a LF?
	 je	 DD_PARSE_CLC	; Jump if so

	 call	 IZITCOMMENT	; Izit a comment?
	 je	 DD_PARSE_CLC	; Jump if so

	 call	 DD_SWPROC	; Process switch character at DS:SI
	 jc	 LISTS_HELP	; Jump if invalid character

	 jmp	 SKIPWHITE	; Go around again

LISTS_HELP:
	 mov	 ds,DATASEG	; Setup addressibility to DGROUP
	 assume  ds:DGROUP	; Tell the assembler about it

	 lea	 dx,MSG_DD_HELP ; Display error message

DD_PARSE_MSG:
	 mov	 ah,09h 	; DOS: Print String function
	 int	 21h		; Tell 'em the bad news

	 call	 PRESSANY	; Wait for keystroke

	 stc			; Indicate command line parsing error

	 jmp	 DD_PARSE_EXIT ; Join common exit code

DD_PARSE_CLC:

	 clc			; Mark as successful

DD_PARSE_EXIT:
	 REGREST <es,ds,di,si,dx,cx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DD_PARSE endp			; End DD_PARSE procedure


;*************************************************************************

	 NPPROC  DD_SWPROC -- Process Switch Character
	 assume  ds:nothing,es:DGROUP,ss:nothing
COMMENT|

Process switch character (for Device Driver)

On entry:
DS:SI	 ==>	 switch character

On exit:
CF	 =	 1 if valid switch character
	 =	 0 otherwise

DS:SI	 ==>	 (updated)

|

	 REGSAVE <ax,di,cx>	; Save registers

; The only option that we accept is PRO=
; Anything else will generate a warning message

	 cmp	 al,'P'         ; Start of PRO= command?
	 jne	 SWPROC_ERR	; Jump if not

	 cmp	 WPTR ds:[si],'OR' ; Rest of PRO= comand?
	 jne	 SWPROC_ERR	; Jump if not

	 inc	 si		; Skip over rest of command
	 inc	 si		; ...

; Look for '='

	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 al,'='         ; Check for mandatory '='
	 jne	 SWPROC_ERR	; Jump if error

	 call	 SKIP_WHITE	; Look for argument
	 dec	 si		; Skip back to start of argument

; Address start of filespec

	 mov	 di,si		; Save start of filespec

	 call	 SKIP_BLACK	; Skip to end of filespec
	 dec	 si		; Skip back to start of black space

	 mov	 cl,0		; Terminate string with a NULL

	 xchg	 BPTR ds:[si],cl ; Ensure it is NULL terminated

; DI = Start of filespec
; SI = End of filespec

; Copy filespec to resident buffer (for DeadMan switch)

	 REGSAVE <si,di,es>	; Save registers

	 push	 cs		; Address our resident code
	 pop	 es		; ... via ES
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 si,di		; Address start of string
	 lea	 di,FILESPEC	; Address our resident buffer

@@:
	 lods	 BPTR ds:[si]	; get one character from CONFIG.SYS
	 stos	 BPTR PGROUP:[di] ; Store in resident code

	 or	 al,al		; End of the line?
	 jnz	 @B		; Jump if not

	 REGREST <es,di,si>	; Restore registers
	 assume  es:DGROUP	; Tell the assembler about it


; Copy filespec to MAX

	 REGSAVE <es>		; Save registers

	 push	 ds		; Address the tokenized CONFIG.SYS
	 pop	 es		; ... via ES
	 assume  es:nothing	; Tell the assembler about it

	 push	 bp		; Save BP
	 mov	 bp,sp		; Save SP (in case MAX trashes it)

	 mov	 al,@HARPO_SET_FILESPEC ; Pass filespec to MAX function
	 EMMOUT  @EMM2_HARPOINFO ; Pass HARPO filespec to MAX

	 mov	 sp,bp		; Restore SP
	 pop	 bp		; Restore BP

	 REGREST <es>		; Restore registers
	 assume  es:DGROUP	; Tell the assembler about it

	 mov	 CURR_PASS,@PASS_DEV ; Only allow DEVICE= profile options
	 call	 READ_PROFILE	; Read in the profile (filespec at DS:DI)

	 xchg	 BPTR ds:[si],cl ; Restore regular terminator

	 clc			; Mark as successful

	 jmp	 SWPROC_EXIT	; Join common exit code


;---------
@@:

SWPROC_ERR:
	 stc			; Mark as invalid

	 jmp	 SWPROC_EXIT	; Join common exit code

SWPROC_CLC:
	 clc			; Indicate OK

SWPROC_EXIT:
	 REGREST <cx,di,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DD_SWPROC	 endp		; End DD_SWPROC procedure


;****************************************************************************

	 NPPROC  INSERT_DEAD -- INSERT_DEAD procedure
	 assume  ds:nothing,es:DGROUP,ss:nothing
COMMENT |

Insert the DeadMan switch in the profile after saving its time and
date stamp.

|

	 REGSAVE <ax,bx,cx,dx,si,di,ds> ; Save registers

	 cmp	 CURR_PASS,@PASS_CMD ; Coming from the command line?
	 je	 EXIT		; Jump if so (no need for DeadMan switch)

	 test	 CMD_FLAG,@CMD_DEAD_DEV ; Is deadman switch already active?
	 jnz	 EXIT		; Jump if so (no need for two DeadMan switches)

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

; Setup the particular Deadman switch into the PROFILE_HEADER

	 REGSAVE <es>		; Save registers

	 mov	 ax,seg XGROUP	; Get segment of profile data
	 mov	 es,ax		; Address it
	 assume  es:XGROUP	; Tell the assembler

	 mov	 si,DEAD_NAME	; Particular DeadMan in effect
	 lea	 di,HEADER_START ; Start of Profile Header
	 mov	 cx,@DEAD_LEN	; Length of DeadMan switch
     rep movs	 BPTR HEADER_START[di],BPTR DEAD_NAME[si] ; Apply the DeadMan name

	 REGREST <es>		; Restore registers
	 assume  es:DGROUP	; Tell the assembler about it

; Open the profile

	 mov	 ax,3D02h	; DOS: Open file for Read/Write
	 lea	 dx,FILESPEC	; Address of profile
	 int	 21h		; Open the profile
	 jc	 OPEN_ERR	; Jump if profile not found

	 mov	 bx,ax		; Save file handle

	 mov	 ax,(@GSTDAT*256)+00h ; Get file time/date stamp
	 DOSCALL		; CX = time, DX = date
;;;;;;;  jc	 ???		; Ignore error

	 mov	 DEAD_FTIME,cx	; Save for later
	 mov	 DEAD_FDATE,dx	; Save

; Read in the profile (again)
; I know it's already in memory, (but unfortunately its in uppercase)

	 mov	 ax,seg XGROUP	; Prepare to address it
	 mov	 ds,ax		; Address XGROUP
	 assume  ds:XGROUP	; Tell the assembler

	 mov	 ah,3Fh 	; DOS: Read from file function
	 mov	 cx,-1		; Read in up to 64 KB
;;;;;;;; mov	 bx,??		; File handle (already set)
	 lea	 dx,PROFILE_START ; Start of buffer
	 int	 21h		; Read in the profile
	 jc	 READ_ERR	; Jump if error

; Calculate new profile size

	 mov	 cx,ax		; Size of original profile
	 add	 ax,dx		; Plus start of file
	 mov	 si,ax		; Save for later use
	 sub	 dx,WPTR offset HEADER_START ; Get size of new line
	 add	 cx,dx		; Size of new profile

; Reset DOS' Read/Write pointer

	 REGSAVE <cx>		; Save register

	 mov	 ax,4200h	; DOS: LSEEK from the beginning of the file
;;;;;;;; mov	 bx,??		; File handle (already set)
	 xor	 cx,cx		; Start of file
	 xor	 dx,dx		; ...
	 int	 21h		; Reset the read/write pointer

	 REGREST <cx>		; Restore register
	 jc	 LSEEK_ERR	; Jump if error

; If we parsed a MODEL= value, put the new model # in place

	 test	 LCL_FLAG,@LCL_MODEL ; Did we find one?
	 jz	 short @F	; Jump if not

	 mov	 di,MODEL_OFF	; Get offset of model # value
	 mov	 al,MODELNO	; Get the current model #
	 add	 al,'0'         ; Convert to ASCII
	 mov	 ds:[di],al	; Save in profile
@@:
	 test	 LCL_FLAG,@LCL_MODEL ; Did we find one?
	 jnz	 short ID1	; Jump if so
@@:
	 dec	 si		; Back up to last char
	 dec	 cx		; Count out possible EOF

	 cmp	 BPTR ds:[si],EOF ; Izit an EOF?
	 je	 short @B	; Jump if so

	 inc	 cx		; Count in last one
ID1:

; Write out the new profile

	 mov	 ah,@WRITF2	; DOS: Write file function
;;;;;;;; mov	 cx,??		; New File size (with extra line)
	 lea	 dx,HEADER_START ; New File start (with extra line)
	 int	 21h		; Write the profile to disk
;;;;;;;; jc	 WRITE_ERR	; Jump if error

; If we didn't parse a MODEL= value, do so now

	 test	 LCL_FLAG,@LCL_MODEL ; Did we find one?
	 jnz	 short ID2	; Jump if so

	 or	 LCL_FLAG,@LCL_MODEL ; Mark as now present

	 mov	 al,MODELNO	; Get the current model #
	 add	 al,'0'         ; Convert to ASCII
	 mov	 MODEL_VAL,al	; Save in line text

; Write out the current section name or [common] if none

	 mov	 cx,MBOOT_LBR_LEN ; Length of lbr
	 DOSCALL @WRITF2,MBOOT_LBR ; Write out the left bracket
;;;;;;;; jc	 WRITE_ERR	; Jump if error

	 lea	 si,CMP_COMMON	; DS:SI ==> 'COMMON',0

	 cmp	 MBOOT_SECTION[0],0 ; Izit valid?
	 je	 short @F	; Jump if not

	 lea	 si,MBOOT_SECTION ; DS:SI ==> [section name]
@@:
	 mov	 dx,si		; DS:DX ==> start of section name
	 mov	 cx,0-1 	; Initialize counter (less trailing zero)
@@:
	 lods	 BPTR ds:[si]	; Get next character
	 inc	 cx		; Count it in

	 cmp	 al,0		; Izit EOL?
	 jne	 short @B	; Jump if not

	 DOSCALL @WRITF2	; Write out the section name
;;;;;;;; jc	 WRITE_ERR	; Jump if error

	 mov	 cx,MBOOT_RBR_LEN ; Length of rbr
	 DOSCALL @WRITF2,MBOOT_RBR ; Write out the right bracket
;;;;;;;; jc	 WRITE_ERR	; Jump if error

	 mov	 ah,@WRITF2	; DOS: Write file function
	 mov	 cx,MODEL_LEN	; Size of MODEL= line
	 lea	 dx,MODEL_LINE	; DS:DX ==> MODEL= line
	 int	 21h		; Write out the line
;;;;;;;; jc	 WRITE_ERR	; Jump if error
ID2:

; Close the profile

READ_ERR:
LSEEK_ERR:
	 mov	 ah,@CLOSF2	; DOS: Close file function (3Eh)
;;;;;;;; mov	 bx,??		; File handle (already set)
	 int	 21h		; Close the profile

OPEN_ERR:
EXIT:
	 REGREST <ds,di,si,dx,cx,bx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
INSERT_DEAD	 endp		; End INSERT_DEAD procedure


;***************************************************************************

	 NPPROC  GET_PROFILE -- GET_PROFILE procedure
	 assume  ds:DGROUP,es:DGROUP,ss:nothing
COMMENT |

Allow INSTALL= to determine the profile name

|

	 REGSAVE <ax,dx,di>	; Save registers

	 cmp	 PORT67,0	; Is MAX present?
	 je	 EXIT		; Jump if not

; Retrieve MAX's filespec

	 REGSAVE <es>		; Save registers

	 push	 cs		; Address our resident data
	 pop	 es		; ... via ES
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,FILESPEC	; Address to place filespec

	 push	 bp		; Save BP
	 mov	 bp,sp		; Save SP (in case MAX trashes it)

	 mov	 al,@HARPO_GET_FILESPEC ; Get filespec to MAX
	 EMMOUT  @EMM2_HARPOINFO ; Rettrieve profile filespec from MAX

	 mov	 sp,bp		; Restore SP
	 pop	 bp		; Restore BP

	 REGREST <es>		; Restore registers
	 assume  es:DGROUP	; Tell the assembler about it

; Verify that the profile is valid

	 cmp	 FILESPEC,0	; Look at the first character
	 je	 ERR		; Jump if profile not present

; Process the profile

	 REGSAVE <ds>		; Save registers

	 push	 cs		; Address the filespec
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 call	 READ_PROFILE	; Process the profile (filespec at DS:DI)

	 REGREST <ds>		; Restore registers
	 assume  ds:DGROUP	; Tell the assembler about it

	 jmp	 EXIT		; Join common exit code

; Let 'em know we really need a profile to continue

ERR:
	 lea	 di,MSG_NOPRO	; "We need a profile" message
	 call	 DISP_COPY	; Display copyright and message

EXIT:
	 REGREST <di,dx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
GET_PROFILE	 endp			; End GET_PROFILE procedure


;***************************************************************************

	 NPPROC  READ_PROFILE -- READ_PROFILE Procedure
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Read, Process, and Close the profile.

On entry:
DS:DI	=	Address of null-terminated profile filespec
		(within tokenized CONFIG.SYS)

|

	 REGSAVE <ax,bx,cx,dx,si,di,ds> ; Save registers

; Open the profile

	 mov	 dx,di		; DS:DX = Address of filespec

	 mov	 al,0		; Read/Write
	 DOSCALL @OPENF2	; Open file, ASCIIZ at DS:DX
	 jc	 OPEN_ERR	; Jump if error

	 mov	 bx,ax		; Move file handle to DOS' favorite register

	 mov	 ax,seg XGROUP	; Get segment of profile buffer
	 mov	 ds,ax		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

; Read in the entire profile

	 mov	 cx,-1		; Read in up to 64 KB
	 DOSCALL @READF2,PROFILE_START ; Read from file BX to DS:DX
	 jc	 READ_ERR	; Jump if error

	 mov	 si,dx		; Get pointer to profile
	 mov	 cx,ax		; Get profile byte Count

	 cmp	 cx,0		; Is the profile empty?
	 je	 READ_ERR	; Jump if nothing to read

; Close the profile

	 DOSCALL @CLOSF2	; Close file, handle in BX
	 jc	 CLOSE_ERR	; Jump if error

; Convert the profile to uppercase

	 REGSAVE <ax,cx,si>	; Save registers

@@:	 lodsb			; Get character
	 call	 UPPERCASE	; Convert character to uppercase
	 mov	 [si-1],al	; Store back
	 loop	 @B		; Next character

	 mov	 byte ptr [si],EOF ; Add EOF in case there isn't one
				; DOS 5's EDIT.COM needs this

; Check for Multiboot
	 push	 ds		; Save

	 lds	 si,RH_VEC	; Get pointer to request header
	 assume  ds:nothing	; Tell the assembler

	 call	 INIT_MBOOT	; Get contents of CONFIG=

	 pop	 ds		; Restore
	 assume  ds:XGROUP	; Tell the assembler

	 REGREST <si,cx,ax>	; Restore registers

; Parse the profile

NEXT_LINE:
	 test	 CMD_FLAG,@CMD_DEAD_DEV ; Is the deadman switch active?
	 jnz	 END_OF_PRO	; Jump if so

	 call	 SKIP_WHITE	; Skip over white space (place char in AL)
	 dec	 si		; Back up to non-white character

	 cmp	 al,EOF 	; Izit End of file?
	 je	 END_OF_PRO	; Jump if so

	 call	 CHECK_MBOOT	; Return CF=1 if we should process the line
	 jnc	 short READP_TOSSLINE ; Jump if we should skip it

	 cmp	 al,CR		; Izit an empty line?
	 jne	 @F		; Jump if not

READP_TOSSLINE:
	 call	 SKIP_EOL	; Skip to next line (place char in AL)
	 jmp	 NEXT_LINE	; Next line
@@:

	 call	 IZITCOMMENT	; Izit a comment?
	 jne	 @F		; Jump if not

	 call	 SKIP_EOL	; Skip to next line (place char in AL)
	 jmp	 NEXT_LINE	; Try next line
@@:

; Compare keyword against option list

	 REGSAVE <bx,cx,dx,si,di> ; Save registers

	 mov	 dx,si		; Save pointer to profile keyword
	 lea	 bx,PRO_FCNS	; Address start of keyword table

NEXT_KEY:

	 mov	 si,dx		; Get pointer to profile keyword

	 xor	 cx,cx		; Prepare for 16 bit entry
	 mov	 cl,DGROUP:[bx].PRO_FCN.TEXTLEN ; Get byte count of keyword
	 lea	 di,DGROUP:[bx].PRO_FCN.TEXTSTR ; Address the string

    repe cmpsb			; Compare them
	 jz	 TEMP1		; Jump if we found a match

	 add	 bx,size PRO_FCN ; Next keyword

	 cmp	 bx,@FCN_LAST	; Have we reached last entry
	 jb	 NEXT_KEY	; Jump if not (next keyword)

	 stc			; Indicat no match was found
	 jmp	 TEMP2		; Exit loop

; We found a keyword match
; Now check to see if it is valid during this pass

TEMP1:
	 cmp	 DGROUP:[bx].PRO_FCN.PASS,@PASS_ALL ; Option valid for all passes?
	 je	 TEMP3		; Jump if so

	 mov	 al,DGROUP:[bx].PRO_FCN.PASS ; Get pass number for specific option

	 cmp	 al,CURR_PASS	; Is this option allowed on current pass?
	 clc			; Assume wrong pass
	 jne	 TEMP2		; Jump if not valid during current pass

; Profile option is valid during this pass
; Execute the profile routine here!

TEMP3:
;;;;;;;; lodsb			; Get next character
	 call	 DGROUP:[bx].PRO_FCN.PTRFCN ; Execute the routine
				; Note: CF significant

TEMP2:

	 REGREST <di,si,dx,cx,bx> ; Restore registers
	 jc	 UNK_KEY	; Must be an unknown keyword

; Skip to the start of the next profile line

	 mov	 al,[si]	; Get current character
	 call	 SKIP_EOL	; Skip to end of line
				; It has already been processed

	 jmp	 NEXT_LINE	; Try next line

; Invalid profile line (if we have reached here)

UNK_KEY:
	 mov	 al,[si-1]	; Get current character
	 call	 DISP_UNK	; Display unknown keyword

	 jmp	 NEXT_LINE	; Try next line

OPEN_ERR:
READ_ERR:
CLOSE_ERR:

	 jmp	 EXIT		; Join common code

END_OF_PRO:

;--------

; Check to see if ONTRACK's DDO driver is loaded at the top of
; low DOS.  If so, we can't load COMMAND.COM high as DDO attempts
; to relocate itself into high DOS memory and there's no footprint
; for it.
; However, if we're running under MS-DOS 7, we can relocate both
; the DDO and COMMAND.COM high.

	 REGSAVE <ax,cx,si,di,es> ; Save registers

	 cmp	 MODELNO,2	; Izit MS-DOS 7.00?
	 je	 short DDO_DONE ; Jump if so (we can relocate both high)

; Search for the DDO within low DOS memory

	 DOSCALL @GETLST	; Return with ES:BX ==> LoL
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es:[bx-2]	; Get segment of first MAC entry
DDO_NEXT:
	 mov	 es,ax		; Address the next MAC entry
	 assume  es:nothing	; Tell the assembler about it

; See if this is ONTRACK's DDO entry

	 lea	 si,ONTRACK	; DS:SI ==> ONTRACK's name
	 mov	 di,40h 	; Constant offset within DDO
	 mov	 cx,ONTRACK_LEN ; CX = # bytes in name
	 cld			; String ops forwardly
    repe cmps	 ONTRACK[si],BPTR es:[di]
	 je	 short DDO_FOUND ; Jump if found

; Try the next MAC entry

	 add	 ax,es:[MAC_STR.MAC_NPAR] ; Plus the length
	 inc	 ax		; Skip over the MAC para

	 cmp	 ax,0A000h	; Izit in high DOS?
	 jae	 short DDO_DONE ; Jump if so

	 cmp	 es:[MAC_STR.MAC_TYPE],@MAC_END ; Izit the end?
	 je	 short DDO_DONE ; Jump if so

	 jmp	 DDO_NEXT	; Go around again

DDO_FOUND:
	 or	 LCL_FLAG,@LCL_DDO ; Mark as found
DDO_DONE:
	 REGREST <es,di,si,cx,ax> ; Restore
	 assume  es:DGROUP	; Tell the assembler about it

; If in GETSIZE mode, then ensure that we analyze CCOM and the env.
; We do this by enabling CCOM and ENVIRON unless NOLOADHI has been set.

	 test	 LCL_FLAG,@LCL_TEST ; GETSIZE mode?
	 jz	 LCL1		; Jump if not

	 mov	 al,'C'         ; Get CCOM token
	 call	 GET_TOKEN	; DI ==> Specific Token entry
	 jc	 XCCOM		; Jump if token not found

	 or	 LCL_FLAG,@LCL_CCOM ; Mark as analyzing CCOM

XCCOM:

	 mov	 al,'E'         ; Get Environment token
	 call	 GET_TOKEN	; DI ==> Specific Token entry
	 jc	 XENV		; Jump if token not found

	 or	 LCL_FLAG,@LCL_ENVIRON ; Mark as analyzing the env.

XENV:
LCL1:

;--------

; Prohibit Loading CCOM or the environment high in DOS 4
; or if OnTrack's DDO driver is present
; Also, since CCOM is loading Low, we can use CCOM_REG as the
; region for SHARE.  This should  be done AFTER we check for
; GETSIZE (just above)

	 test	 LCL_FLAG,@LCL_DDO ; Izit present?
	 jnz	 LCL2		; Jump if so

	 cmp	 DOSVER.HILO_STR.HI,4 ; Is it DOS 4?
	 jne	 @F		; Jump if not
LCL2:
	 and	 LCL_FLAG,not (@LCL_CCOM or @LCL_ENVIRON) ; Turn these off
;;;;;;;; mov	 CCOM_REGION,0	; Specify no CCOM region
	 mov	 ENV_REGION,0	; Specify no master env region

	 mov	 al,SHARE_REGION ; Get region for SHARE
	 mov	 CCOM_REGION,al ; ... and stuff away
@@:

;--------

; Wipe out the C and E tokens.	They were only needed during READ_PROFILE
; This must be done AFTER we check for GETSIZE mode (just above)

	 mov	 al,'C'         ; Get CCOM token
	 call	 GET_TOKEN	; DI ==> Specific Token entry
	 jc	 @F		; Jump if token not found

	 mov	 PGROUP:[di].TOKEN_STR.VALUE,0 ; Zap entire entry
@@:

	 mov	 al,'E'         ; Get Environment token
	 call	 GET_TOKEN	; DI ==> Specific Token entry
	 jc	 @F		; Jump if token not found

	 mov	 PGROUP:[di].TOKEN_STR.VALUE,0 ; Zap entire entry
@@:


; If the environment is in the same region as the program, change the
; LSEG_EREG field to @NOTSPEC.	It is specified, but we need to make
; our LSEG entry consistent with others, where environment specified
; in the program region means a change should be made (remove ENVREG=)
	 mov	 al,LSEG.LSEG_EREG ; Get environment region
	 or	 al,al		; Izit loaded high?
	 jz	 short @F	; Jump if not

	 cmp	 al,LSEG.LSEG_PREG ; Izit the same as the program region?
	 jne	 short @F	; Jump if not

	 mov	 LSEG.LSEG_EREG,@NOTSPEC ; Mark as not specified
@@:
;--------

EXIT:

	 REGREST <ds,di,si,dx,cx,bx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

READ_PROFILE	 endp		; End READ_PROFILE procedure


;***************************************************************************

	 NPPROC  SKIP_EOL -- SKIP_EOL Procedure
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Skip to end of line

On entry:
DS:SI	==>	Text in question

On exit:
AL	=	Current character
DS:SI	=	Updated.

|

NEXT_CHAR:
	 lodsb			; Get next character

	 cmp	 al,EOF 	; End of the file?
	 je	 EXIT		; Jump if so

	 cmp	 al,LF		; Izit a Line Feed?
	 jne	 NEXT_CHAR	; If not, try next character

EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

SKIP_EOL	 endp		; End SKIP_EOL procedure

;***************************************************************************

	 NPPROC  DISP_UNK -- DISP_UNK Procedure
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Display any unknown profile keywords (the entire line)

On entry:
DS:SI	==>	Keyword in question

On exit:
DS:SI	==>	Updated

|

	 REGSAVE <dx,di>	; Save

	 push	 ds		; Save for a moment

	 push	 es		; Prepare to address DGROUP
	 pop	 ds		; Address for message display
	 assume  ds:DGROUP	; Tell the assembler

	 lea	 di,MSG_PRO_UNK ; "Unknown keyword" message
	 call	 DISP_COPY	; Display copyright and error message

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler

NEXT_CHAR:
	 lods	 BPTR ds:[si]	; Get character to dislay
	 mov	 dl,al		;

	 DOSCALL @CHROUT	; Display output in DL to CON:

	 cmp	 dl,LF		; Izit an EOL?
	 jne	 NEXT_CHAR	; Jump if not

	 REGREST <di,dx>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_UNK	 endp		; End DISP_UNK procedure


;***************************************************************************

	 NPPROC  FCN_DEBUG -- Enable debugging
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Profile action to enable debugging
Usage: DEBUG

On entry:
DS:SI	==>	character following keyword

On exit:
DS:DI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 or	 LCL_FLAG,@LCL_DEBUG ; Enable debugging

	 clc			; Indicate success

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_DEBUG	 endp		; End FCN_DEBUG procedure


;***************************************************************************

	 NPPROC  FCN_GETSIZE -- Enable GETSIZE mode
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Profile action to enable debugging
Usage: GETSIZE

On entry:
DS:SI	==>	character following keyword

On exit:
DS:DI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 or	 LCL_FLAG,@LCL_TEST ; Enable GETSIZE (note CF=0)

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_GETSIZE	 endp		; End FCN_GETSIZE procedure


;***************************************************************************

	 NPPROC  FCN_VERBOSE -- Enable VERBOSE mode
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Always display copyright message
Usage: VERBOSE

On entry:
DS:SI	==>	character following keyword

On exit:
DS:DI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 or	 CMD_FLAG,@CMD_VERBOSE ; Enable garrulosity

	 clc			; Indicate success

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_VERBOSE	 endp		; End FCN_VERBOSE procedure


;***************************************************************************

	 NPPROC  FCN_FILES -- Process FILES=
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Profile action to move FILES= into High DOS memory
Usage: F = 1234, 2

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 mov	 PRO_TOKEN,@TOKEN_FILES ; We are processing FILES=

	 call	 FCN_TOKEN	; Process the FILES= command
				; Note: CF=significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_FILES	 endp		; End FCN_FILES procedure


;***************************************************************************

	 NPPROC  FCN_FCBS -- FCN_FCBS procedure
	 assume  ds:nothing,es:DGROUP,ss:nothing
COMMENT |

Profile action to move FCB= into High DOS memory
Usage: X = 1234, 2

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 mov	 PRO_TOKEN,@TOKEN_FCB ; We are processing FCB=

	 call	 FCN_TOKEN	; Process the FCB= command
				; Note: CF=significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
FCN_FCBS	 endp		; End FCN_FCBS procedure


;***************************************************************************

	 NPPROC  FCN_BUFFERS -- FCN_BUFFERS procedure
	 assume  ds:nothing,es:DGROUP,ss:nothing
COMMENT |

Profile action to move BUFFERS= into High DOS memory
Usage: B = 1234, 2

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 mov	 PRO_TOKEN,@TOKEN_BUFFERS ; We are processing BUFFERS=

	 call	 FCN_TOKEN	; Process the BUFFERS= command
				; Note: CF=significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
FCN_BUFFERS	 endp		; End FCN_BUFFERS procedure


;***************************************************************************

	 NPPROC  FCN_LASTDRV -- FCN_LASTDRV procedure
	 assume  ds:nothing,es:DGROUP,ss:nothing
COMMENT |

Profile action to move LASTDRV= into High DOS memory
Usage: L = 1234, 2

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 mov	 PRO_TOKEN,@TOKEN_LASTDRV ; We are processing LASTDRV=

	 call	 FCN_TOKEN	; Process the LASTDRV= command
				; Note: CF=significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
FCN_LASTDRV	 endp		; End FCN_LASTDRV procedure


;***************************************************************************

	 NPPROC  FCN_STACKS -- FCN_STACKS procedure
	 assume  ds:nothing,es:DGROUP,ss:nothing
COMMENT |

Profile action to move STACKS= into High DOS memory
Usage: S = 1234, 2

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 mov	 PRO_TOKEN,@TOKEN_STACKS ; We are processing STACKS=

	 call	 FCN_TOKEN	; Process the STACKS= command
				; Note: CF=significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
FCN_STACKS	 endp		; End FCN_STACKS procedure


;***************************************************************************

	 NPPROC  FCN_ALL -- FCN_ALL procedure
	 assume  ds:nothing,es:DGROUP,ss:nothing
COMMENT |

Profile action to move All DOS 3.3 sub-segments into High DOS memory
Usage: V = 1234, 2

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 mov	 PRO_TOKEN,@TOKEN_DOS3 ; We are processing DOS 3.3 subsegs

	 call	 FCN_TOKEN	; Process the V= command
				; Note: CF=significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
FCN_ALL  endp		; End FCN_ALL procedure


;***************************************************************************

	 NPPROC  FCN_BATCH -- Process batch processing workspace
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Profile action to move batch data into High DOS memory
Usage: Q = 80, 2

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 mov	 PRO_TOKEN,@TOKEN_BATCH ; We are processing batch data

	 call	 FCN_TOKEN	; Process the batch data command
				; Note: CF=significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_BATCH endp			; End FCN_BATCH procedure

;***************************************************************************

	 NPPROC  FCN_IFS_G -- Process IFS-G
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Profile action to move IFS-G data into High DOS memory
Usage: G = 80, 2

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 mov	 PRO_TOKEN,@TOKEN_IFS_G ; We are processing IFS_G data

	 call	 FCN_TOKEN	; Process the batch data command
				; Note: CF=significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_IFS_G endp			; End FCN_IFS_G procedure

;***************************************************************************

	 NPPROC  FCN_IFS_H -- Process IFS-H
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Profile action to move IFS-H data into High DOS memory
Usage: H = 80, 2

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 mov	 PRO_TOKEN,@TOKEN_IFS_H ; We are processing IFS_H data

	 call	 FCN_TOKEN	; Process the batch data command
				; Note: CF=significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_IFS_H endp			; End FCN_IFS_H procedure
;***************************************************************************

	 NPPROC  FCN_IFS_R -- Process IFS-R
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Profile action to move IFS-R data into High DOS memory
Usage: R = 80, 2

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 mov	 PRO_TOKEN,@TOKEN_IFS_R ; We are processing IFS_R data

	 call	 FCN_TOKEN	; Process the batch data command
				; Note: CF=significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_IFS_R endp			; End FCN_IFS_R procedure

;***************************************************************************

	 NPPROC  FCN_IFS_Y -- Process IFS-Y
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Profile action to move IFS-G data into High DOS memory
Usage: Y = 80, 2

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 mov	 PRO_TOKEN,@TOKEN_IFS_Y ; We are processing IFS_Y data

	 call	 FCN_TOKEN	; Process the batch data command
				; Note: CF=significant

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_IFS_Y endp			; End FCN_IFS_Y procedure

;***************************************************************************

	 NPPROC  FCN_COMSPEC -- FCN_COMSPEC procedure
	 assume  ds:nothing,es:DGROUP,ss:nothing
COMMENT |

Profile action to move COMMAND.COM into High DOS memory
Usage: C = 1234,2

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 REGSAVE <ax,di>	; Save registers

	 mov	 PRO_TOKEN,'C'  ; We are processing COMMAND.COM

	 call	 FCN_TOKEN	; Process the C= command
	 jc	 EXIT		; Note: CF=significant

	 mov	 al,'C'         ; Get current token
	 call	 GET_TOKEN	; DI ==> Specific Token entry
	 jc	 EXIT_CLC	; Jump if NOLOADHI in effect

	 mov	 ax,PGROUP:[di].TOKEN_STR.NPAR ; Get size in paras
	 mov	 CCOM_LEN,ax	; ... and save

	 mov	 al,PGROUP:[di].TOKEN_STR.REG  ; Get program region
	 mov	 CCOM_REGION,al 	; ... and save for relocation
	 mov	 LSEG.LSEG_PREG,al	; ... and save in LSEG

	 or	 LCL_FLAG,@LCL_CCOM ; Move COMMAND.COM to High DOS

EXIT_CLC:
	 clc			; Indicate all went well

EXIT:
	 REGREST <di,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
FCN_COMSPEC  endp		; End FCN_COMSPEC procedure


;***************************************************************************

	 NPPROC  FCN_ENV -- FCN_ENV procedure
	 assume  ds:nothing,es:DGROUP,ss:nothing
COMMENT |

Profile action to move the master environment into High DOS memory
Usage: E = 1234,2

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 REGSAVE <ax,di>	; Save registers

	 mov	 PRO_TOKEN,'E'  ; We are processing the environment

	 call	 FCN_TOKEN	; Process the E= command
	 jc	 EXIT		; Note: CF=significant

	 or	 LCL_FLAG,@LCL_XENV ; Assume NOLOADHI in effect

	 mov	 al,'E'         ; Get current token
	 call	 GET_TOKEN	; DI ==> Specific Token entry
	 jc	 EXIT_CLC	; Jump if NOLOADHI in effect

	 and	 LCL_FLAG,not (@LCL_XENV) ; Environment to be loaded High

	 mov	 ax,PGROUP:[di].TOKEN_STR.NPAR ; Get size in paras
	 mov	 ENV_LEN,ax	; .... and save

	 mov	 al,PGROUP:[di].TOKEN_STR.REG  ; Get environment region
	 mov	 ENV_REGION,al		; ... and save for relocation
	 mov	 LSEG.LSEG_EREG,al	; ... and save in LSEG

	 or	 LCL_FLAG,@LCL_ENVIRON ; Move the environ to High DOS

EXIT_CLC:
	 clc			; Indicate all went well

EXIT:
	 REGREST <di,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
FCN_ENV  endp			; End FCN_ENV procedure


;***************************************************************************

	 NPPROC  FCN_TOKEN -- FCN_TOKEN procedure
	 assume  ds:nothing,es:DGROUP,ss:nothing
COMMENT |

Common sub-routine to FCN_FILES, FCN_FCBS, ...

On entry:
DS:SI	=	Command Line (pointing to para count)

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error


|

	 REGSAVE <cx,di>	; Save registers

	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 al,'='         ; Look for mandatory equals sign
	 jne	 EXIT_STC	; Jump if not present

	 call	 SKIP_WHITE	; Skip over white space
	 dec	 si		; Back up to character

	 mov	 al,PRO_TOKEN	; Get current token
	 call	 GET_TOKEN	; DI ==> Specific Token entry

	 cmp	 WPTR ds:[si],'ON' ; Izit part of NOLOADHI?
	 je	 NOLOADHI	; Jump if so

	 mov	 cx,10		; Use decimal
	 call	 BASE2BIND	; Convert HEX at DS:SI ==> EAX
				; (CCOM for DOS6 is greater than 65,535)

DOT386
	 add	 eax,0Fh	; Round up to next para
	 shr	 eax,4-0	; Convert bytes to paras
.8086

	 mov	 PGROUP:[di].TOKEN_STR.NPAR,ax ; Save number of paras

	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 al,','         ; Look for optional comma
	 jne	 EXIT_STC	; Jump if not present

	 call	 SKIP_WHITE	; Skip over white space
	 dec	 si		; Back up to character

	 mov	 cx,16		; Use hexadecimal
	 call	 BASE2BIN	; Convert HEX at DS:SI ==> AX

	 cmp	 PRO_TOKEN,@TOKEN_FILES ; Is it FILES=
	 jne	 @F		; Jump if not

	 xchg	 FILES_REG,al	; FILES_REG = Requested region number
				; AL = 0
@@:
	 mov	 PGROUP:[di].TOKEN_STR.REG,al ; Region number

	 jmp	 EXIT_CLC	; Join common exit code

NOLOADHI:
	 cmp	 WPTR ds:[si+2],'OL' ; Izit part of NOLOADHI?
	 jne	 EXIT_STC	; Jump if not

	 cmp	 WPTR ds:[si+4],'DA' ; Izit part of NOLOADHI?
	 jne	 EXIT_STC	; Jump if not

	 cmp	 WPTR ds:[si+6],'IH' ; Izit part of NOLOADHI?
	 jne	 EXIT_STC	; Jump if not

; Specify that this region never goes high

	 mov	 PGROUP:[di].TOKEN_STR.VALUE,0 ; Clear the token

EXIT_CLC:
	 clc			; Indicate success

	 jmp	 EXIT		; Join common code

EXIT_STC:
	 stc			; Indicate profile error

EXIT:
	 REGREST <di,cx>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
FCN_TOKEN	 endp		; End FCN_TOKEN procedure


;***************************************************************************

	 NPPROC  FCN_OVERFLOW -- A subsegment overflow has ocurred
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Profile action to react to a subsegment overflow
Usage: OVERFLOW

On entry:
DS:SI	==>	character following keyword

On exit:
DS:DI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 REGSAVE <di,ds>	; Save

	 push	 es		; Get DGROUP segment
	 pop	 ds		; Address for message display
	 assume  ds:DGROUP	; Tell the assembler

	 lea	 di,MSG_OFLOW	; "Overflow has occurred" message
	 call	 DISP_COPY	; Display copyright and message

	 REGREST <ds,di>	; Restore registers
	 assume  ds:nothing	; Tell the assembler

	 call	 PRESSANY	; Wait for user aknowledgement

	 mov	 DEAD_NAME,offset PGROUP:DEAD_DEV ; Affix a DeadMan name

	 or	 LCL_FLAG,@LCL_TEST ; Enable GETSIZE

	 clc			; Indicate success

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_OVERFLOW	 endp		; End FCN_OVERFLOW procedure


;***************************************************************************

	 NPPROC  FCN_DEADMAN -- A Catastrophic error has ocurred
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Profile action to react to a catastrophic error
Usage: NOLOADH = D
	NOLOADH = I

On entry:
DS:SI	==>	character following keyword

On exit:
DS:DI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

; Determine if we are parsing a DEVICE= or INSTALL= DeadMan switch

	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 al,'='         ; Look for mandatory equals sign
	 jne	 DEAD_ALL	; Jump if not present

	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 al,'d'         ; Is it the DEVICE= DeadMan switch?
	 je	 DEAD_DEVICE	; Jump if so

	 cmp	 al,'i'         ; Is it the INSTALL= DeadMan switch?
	 je	 DEAD_INSTALL	; Jump if so

; Universal DeadMan switch

DEAD_ALL:
	 or	 CMD_FLAG,@CMD_DEAD_DEV ; Do not run this program at all

	 jmp	 DISP_MSG		; Join common exit code

; DEVICE= DeadMan switch

DEAD_DEVICE:
	 cmp	 CURR_PASS,@PASS_DEV ; Correct pass?
	 jne	 EXIT	; Jump if not

	 or	 CMD_FLAG,@CMD_DEAD_DEV ; Do not run this program

	 jmp	 DISP_MSG	; Join common exit code

; INSTALL= DeadMan switch

DEAD_INSTALL:
	 cmp	 CURR_PASS,@PASS_INS ; Correct pass?
	 jne	 EXIT	; Jump if not

	 or	 CMD_FLAG,@CMD_DEAD_DEV ; Do not run this program

DISP_MSG:
	 REGSAVE <di,ds>	; Save registers

	 push	 es		; Prepare to address DGROUP
	 pop	 ds		; Address for message display
	 assume  ds:DGROUP	; Tell the assembler

	 lea	 di,MSG_DEADMAN ; "DeadMan encountered" message
	 call	 DISP_COPY	; Display copyright and message

	 REGREST <ds,di>	; Restore registers
	 assume  ds:nothing	; Tell the assembler

	 call	 PRESSANY	; Wait for user aknowledgement
EXIT:

	 clc			; Indicate success

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_DEADMAN	 endp		; End FCN_DEADMAN procedure


;***************************************************************************

	 NPPROC  FCN_SHARE -- Move the SHARE to High DOS
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Profile action to move an implicit SHARE to High DOS
Usage: SHARE

On entry:
DS:SI	==>	character following keyword

On exit:
DS:DI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 or	 LCL_FLAG,@LCL_CMD_SHARE ; Move implicit SHARE to High DOS?

	 mov	 SHARE_REGION,1 ; [FIXME]

	 clc			; Indicate success

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_SHARE	 endp		; End FCN_SHARE procedure


;***************************************************************************

	 NPPROC  FCN_NOPSP -- Do not create a fake PSP
	 assume  ds:nothing,es:DGROUP,ss:nothing

COMMENT |

Profile action to not create a fake PSP
Usage: NOPSP

On entry:
DS:SI	==>	character following keyword

On exit:
DS:DI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 or	 LCL_FLAG,@LCL_NOPSP ; Don't create a fake PSP

	 clc			; Indicate success

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_NOPSP	 endp		; End FCN_NOPSP procedure


;***************************************************************************

	 NPPROC  FCN_MODEL -- FCN_MODEL procedure
	 assume  ds:nothing,es:DGROUP,ss:nothing
COMMENT |

Profile action to determine model # from first pass
Usage: MODEL=n

On entry:
DS:SI	==>	character following keyword

On exit:
DS:SI	==>	character following parameter
CF	=	0 if all went well
	=	1 if there was an error

|

	 REGSAVE <ax,es>	; Save registers

; Look for '='

	 call	 SKIP_WHITE	; Skip over white space

	 cmp	 al,'='         ; Check for mandatory '='
	 jne	 EXIT		; Jump if error

	 call	 SKIP_WHITE	; Look for argument
	 dec	 si		; Skip back to start of argument

	 mov	 ax,seg XGROUP	; Get segment of profile data
	 mov	 es,ax		; Address it
	 assume  es:XGROUP	; Tell the assembler

	 mov	 MODEL_OFF,si	; Save for later use

	 mov	 cx,10		; Use decimal
	 call	 BASE2BIN	; Convert HEX at DS:SI ==> AX

	 mov	 MODELNO,al	; Save for later use
	 or	 LCL_FLAG,@LCL_MODEL ; Mark as present

	 cmp	 al,2		; Izit MODEL=2?
	 jne	 short EXIT_CLC ; Jump if not

	 or	 LCL_FLAG,@LCL_CCOM ; Mark as analyzing CCOM
EXIT_CLC:
	 clc			; Indicate all went well
EXIT:
	 REGREST <es,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FCN_MODEL endp			; End FCN_MODEL procedure


;***************************************************************************

HNCODE	 ends			; End Non-Resident Code Segment

;***************************************************************************

HZZTAIL  segment		; End of Non-Res Data	(HARPO)

	 extern  HEADER_START:byte	; Start of profile header
	 extern  PROFILE_START:byte	; Start of profile body

HZZTAIL  ends			;

;***************************************************************************

	 END			; End HARP_FCN module

