;' $Header:   P:/PVCS/MAX/386MAX/QMAX_POS.ASV   1.2   30 May 1997 10:45:54   BOB  $
	 title	 QMAX_POS -- 386MAX POS Functions
	 page	 58,122
	 name	 QMAX_POS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Data    segment EDATA,	dword-aligned, public, class 'edata'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Group XGROUP:
	       Program segment XCODE,	byte-aligned,  public, class 'xcode'
	       Data    segment XDATA,	dword-aligned, public, class 'xdata'

Program derived from:  None.

Original code by:  Rainer McCown, December, 1989.

Modifications by:  Bob Smith.

|

.386
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include ASCII.INC
	 include ABIOS.INC
	 include DOSCALL.INC

	 include QMAX_OEM.INC
.list

PGROUP	 group	 CODE,EDATA,NDATA
XGROUP	 group	 XCODE,XDATA,RAM_EXT


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC

CODE	 ends			; End CODE segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 MAPSEG_NXT:word

	 public  POSDATA
	 include QMAX_POS.INC
POSDATA  POSD_STR @MAXPOSDEV dup (<?>) ; Save area for POS data

EDATA	 ends			; End EDATA segment

NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 NRD_FLAG:dword
	 include QMAX_NRD.INC

NDATA	 ends			; End NDATA segment

XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

	 extrn	 MCAID:word
	 extrn	 FLEXFILE_DPFE:byte
	 extrn	 PATHSTEM_LEN:word

	 public  INIT_ENTRY_CTR,LOGICAL_ID
INIT_ENTRY_CTR	 dw	     0
LOGICAL_ID	 dw	     0

	 public  SYSPARM,CDA_SEG,SYSINIT_SEG,NVRAM_LID,NVRAM_RB_LEN,POS_BLK
SYSPARM 	 SYSPARM_STR <>
CDA_SEG 	 dw	?
SYSINIT_SEG	 dw	?
NVRAM_LID	 dw	?	; NVRAM Logical ID
NVRAM_RB_LEN	 dw	?	; NVRAM Request Block Length
POS_BLK 	 RB_POS_STR <>	; Used for ABIOS POS requests

	 public  RAM_EXTSEG,OLD_MAPSEG,ABIOS_SYS
RAM_EXTSEG dw	 ?		; Segment of RAM extensions
OLD_MAPSEG dw	 ?		; Previous MAPSEG_NXT value
ABIOS_SYS db	 'ABIOS.SYS',0  ; Found in c:\386max\adf\ directory
@ABIOS_SYSLEN equ $-ABIOS_SYS	; Length of filename

	 public  NVRAM_CRCTAB
NVRAM_CRCTAB	 label word	; Ranges to compute NVRAM CRC on
	 dw	 0166h,32	; 166 - 185
	 dw	 0187h,2	; 187 - 188
	 dw	 018Ah,2	; 18A - 18B
	 dw	 018Eh,4	; 18E - 191
	 dw	 01C7h,450	; 1C7 - 388; planar POS values at 369h
	 dw	 0404h,1
	 dw	 04E8h,1
@NVRAM_CRCLEN equ ($-NVRAM_CRCTAB) shr 2 ; Number of ranges

XDATA	 ends			; End XDATA segment


; Define zero length RAM extension data
; On the PS/2 Model 56 486SLC2 (and possibly other new models) there is
; no ABIOS in the ROM.	We are expected to load the ABIOS image (which is
; prefixed with a RAM extension signature) and pass its segment.  We'll
; still need this empty entry to terminate the chain of RAM extensions.

RAM_EXT  segment use16 para public 'xdata' ; Start RAM_EXT segment
	 assume  ds:XGROUP

RAM_EXTENSION dw 0AA55h,0000
@RAM_EXTLEN equ $-RAM_EXTENSION

RAM_EXT  ends			; End RAM_EXT segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 public  @QMAX_POS_XCODE
@QMAX_POS_XCODE:		; Mark module start in .MAP file


SYSPLACE_STR struc

SYSPLACE_DB_VEC dd ?		; Device Block pointer
SYSPLACE_FTT_VEC dd ?		; Function Transfer Table pointer

SYSPLACE_STR ends


SYSCALL_STR struc

	 db	 (size SYSPLACE_STR) dup (?)
	 dd	 ?		; Request block pointer
	 dw	 ?		; Common Data Area segment

SYSCALL_STR ends


	 FPPROC  NVRAMFN -- Invoke ABIOS NVRAM functions
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Routine to call NVRAM (Non-Volatile RAM) functions:
	03h:	 Read device parameters
	08h:	 Read NVRAM[dx]
	09h:	 Write to NVRAM[dx]
	0bh:	 Recompute NVRAM checksum

On entry:
AH	 =	 NVRAM function (08h = read, 09h = write, 0Bh = checksum)
AL	 =	 New value (function 09h only)
DX	 =	 NVRAM index (functions 08h and 09h only)

On exit:
If CF=1,
AX	 =	 Error code

If CF=0,
AL	 =	 Byte read from NVRAM[dx] (function 08h only)

|

	 REGSAVE <bx,cx,dx,si,di,ds,es> ; Save registers

	 mov	 bx,seg XGROUP	; Get segment of XGROUP
	 mov	 ds,bx		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 mov	 bx,seg PGROUP	; Get segment of PGROUP
	 mov	 es,bx		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Because of a bug in the Phoenix MCA BIOS, we have to setup NVRAM_BLK
; differently than we would like to.  In particular, they test a location
; in the start of the segment of the request block (instead of NVRAM_FLAG)
; for whether or not the recomputation should be on the 64-byte RAM or
; the extended RAM.  To compensate for this, we allocate a new segment
; for NVRAM_BLK, setup the NVRAM_FLAG in the appropriate place, fill in
; NVRAM_BLK, and then call ABIOS.

; The word that the faulty Phoenix MCA BIOS tests is at DS:0052 if NMI
; is to be enabled upon exit, DS:00B2 otherwise (we always enable it).
; As that location is above the size of RB_NVRAM_STR, we just allocate
; room for 0052+2 bytes.

	 mov	 bx,52h+2	; Calculate # bytes to allocate
	 add	 bx,16-1	; Round up to next para
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 bx,cl		; Convert from bytes to paras
;;;;;;;; DOSCALL @GETMEM	; Allocate memory for Function Transfer Table
;;;;;;;; jb	 short NVRAMCHECK_EXIT ; Jump if something went wrong
;;;;;;;;			; ...with return code in AX
	 mov	 cx,MAPSEG_NXT	; Get next available segment
	 add	 MAPSEG_NXT,bx	; Skip over it

	 mov	 es,cx		; Address the new segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[0].NVRAM_XFERBUF.LO,al ; Save write value (if function 09h)
	 mov	 es:[0].RB_FUNC.LO,ah ; Function requested by caller
	 mov	 es:[0].RB_FUNC.HI,0 ; Clear high byte
	 mov	 es:[0].NVRAM_START,dx ; Starting NVRAM index
	 mov	 es:[0].NVRAM_LEN,1 ; Number of bytes to move

	 mov	 ax,NVRAM_LID	; Get NVRAM's logical ID
	 mov	 es:[0].RB_LID,ax ; Save in request block

	 mov	 ax,NVRAM_RB_LEN ; Get NVRAM's request block length
	 mov	 es:[0].RB_LEN,ax ; Save in request block

	 mov	 es:[0].RB_RETCODE,-1 ; Set default error code

	 mov	 ax,@NVRAM_FLAG_EXT ; Flag:  NMI enabled on exit,
				;	     RAM type = extended
	 mov	 es:[0].NVRAM_FLAG,ax
	 mov	 es:[52h],ax	; Save in pseudo-location

	 mov	 es:[0].RB_UNIT,0 ; Must be zero at startup
	 mov	 es:[0].RB_RES1,0 ; ...
	 mov	 es:[0].RB_RES2,0 ; ...

	 mov	 es:[0].NVRAM_RES1,0 ; ... ??? WHY ???
	 mov	 es:[0].NVRAM_RES2,0 ; ...
	 mov	 es:[0].NVRAM_RES3,0 ; ...
	 mov	 es:[0].NVRAM_RES4,0 ; ...

; Data pointers are needed for functions 08h and 09h only.  Since it's
; somewhat unclear from the documentation which data pointer gets used,
; initialize both in case someone implemented it incorrectly.
	 mov	 es:[0].NVRAM_VEC1.VSEG,es ; Segment of transfer buffer
	 mov	 es:[0].NVRAM_VEC1.VOFF,NVRAM_XFERBUF ; Offset ...
	 mov	 es:[0].NVRAM_VEC2.VSEG,es ; Segment of transfer buffer
	 mov	 es:[0].NVRAM_VEC2.VOFF,NVRAM_XFERBUF ; Offset ...

	 push	 CDA_SEG	; CDA segment
	 push	 es		; Request block segment
	 xor	 ax,ax		; ...		offset
	 push	 ax		; Pass to SYSPARM routine
	 sub	 sp,size SYSPLACE_STR ; Make room for place holders
	 call	 SYSPARM.STARTPTR ; Request ABIOS service
	 add	 sp,size SYSCALL_STR ; Pop our own calling args

	 mov	 ax,es:[0].RB_RETCODE ; Return error code as result
	 cmp	 ax,1		; Did we succeed?
	 cmc			; Set CF if non-zero (indicating failure)
	 jc	 short NVRAMCHECK_EXIT ; Jump if function failed

	 mov	 al,es:[0].NVRAM_XFERBUF.LO ; Get read value (function 08h only)
NVRAMCHECK_RLS:
;;;;;;;; push	 ax		; Save for a moment
;;;;;;;; DOSCALL @RELMEM	; Release it
;;;;;;;; pop	 ax		; Restore
NVRAMCHECK_EXIT:
	 REGREST <es,ds,di,si,dx,cx,bx> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NVRAMFN endp			; End NVRAMFN procedure

	 NPPROC  IZITWS -- Is AL a whitespace character?
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If AL is a whitespace character (CR,LF,TAB,SPACE,NUL or EOF) return ZF=1.
Otherwise ZF=0.

|

	 cmp	 al,LF		; Izit end of line?
	 je	 short @F	; Jump if so

	 cmp	 al,CR		; Izit end of line?
	 je	 short @F	; Jump if so

	 cmp	 al,' '         ; Izit space?
	 je	 short @F	; Jump if so

	 cmp	 al,TAB 	; Izit TAB?
	 je	 short @F	; Jump if so

	 cmp	 al,EOF 	; Izit end of file?
	 je	 short @F	; Jump if so

	 or	 al,al		; Izit a null?
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZITWS endp			; End IZITWS procedure

	 FPPROC  POSINIT -- Initialize POS Data Area
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

'C' callable routine to initialize the POS (programable option select) data.

On exit:

AX	 =	 0 if no error
	 =	 -1 otherwise

|

	 REGSAVE <bx,cx,dx,si,di,ds,es,fs,gs> ; Save registers

	 mov	 ax,seg PGROUP	; Get segment of PGROUP
	 mov	 fs,ax		; Address it
	 assume  fs:PGROUP	; Tell the assembler about it

	 mov	 ax,seg XGROUP	; Get segment of XGROUP
	 mov	 ds,ax		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it
	 mov	 es,ax		; Address it
	 assume  es:XGROUP	; Tell the assembler about it
	 lea	 di,SYSPARM	; ES:DI ==> system parameters table

	 push	 ds		; Save for a moment

	 lea	 ax,RAM_EXTENSION ; Get offset of RAM extension segment (/16)
	 shr	 ax,4-0 	; Convert from bytes to paras
	 add	 ax,seg XGROUP	; Plus the frame's segment

	 mov	 RAM_EXTSEG,ax	; Save default RAM extension segment
	 mov	 ds,ax		; DS:0 ==> RAM extension info
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ah,04h 	; Function code to build system parameters table
	 int	 15h		; Request BIOS service
	 pop	 ds		; Restore
	 assume  ds:XGROUP	; Tell the assembler about it
	 jnc	 near ptr POSINIT_ABIOSOK ; Jump if we succeeded

; Failure may indicate 1) an MCA machine that doesn't have an ABIOS, or
; that has a broken one; 2) one of the newer IBM machines that doesn't
; have the ABIOS in ROM (such as the PS/2 Model 56 486SLC2).
; If the latter reason holds, we try to find the ABIOS image file by
; searching d:\pathname\ADF (where d:\pathname\ is the path by which
; 386MAX.SYS is loaded) for ABIOS.SYS.	If this file exists, it should
; be a plain text file containing the name of one or more ABIOS RAM
; extensions (such as SF838XX.BIO).  According to the IBM Architectures
; reference, all such RAM extensions should have an extension .BIO and
; should have sizes which are multiples of 512 bytes.  Multiple RAM
; extensions may be listed in ABIOS.SYS separated by space and/or
; newlines.  We must read all such images into memory in the order
; they are listed in ABIOS.SYS, and pass the starting segment in DS
; when calling Int 15h functions 4 and 5.

	 mov	 ax,MAPSEG_NXT	; Get current top of storage
	 mov	 OLD_MAPSEG,ax	; Save as point to release from in case of error

	 lea	 dx,FLEXFILE_DPFE ; Start of filename
	 mov	 di,PATHSTEM_LEN ; Get length of MAX drive:\path
	 add	 di,dx		; Skip to end
	 mov	 XGROUP:[di].EDD,'\FDA' ; Add 'ADF\' to path
	 add	 di,4		; Skip to end of path (including ADF\)
	 lea	 si,ABIOS_SYS	; Filename.ext to copy
	 mov	 cx,@ABIOS_SYSLEN ; Bytes to copy (including null)
	 cld			; Ensure string ops forwardly

	 push	 di		; Save offset for filename
S16 rep  movs	 <FLEXFILE_DPFE[di],ABIOS_SYS[si]> ; Append to path

	 mov	 al,0		; Read-only, sharing compatibility mode
	 DOSCALL @OPENF2	; Open file DS:DX
	 pop	 di		; Get offset to read filename into

	 jc	 near ptr POSINIT_RREADERR ; Jump if file doesn't exist

	 mov	 bx,ax		; Copy to handle register
	 mov	 cx,-1		; Maximum file size

	 mov	 ds,MAPSEG_NXT	; Get available memory
	 assume  ds:nothing	; Tell the assembler

	 sub	 dx,dx		; Start at beginning of segment
	 DOSCALL @READF2	; Read CX bytes from BX into DS:DX

	 pushf			; Save result of read
	 mov	 cx,ax		; Copy bytes read into count register

	 DOSCALL @CLOSF2	; Close file (ignore result)

	 popf			; Restore result of operation
	 jc	 near ptr POSINIT_RREADERR ; Jump if something went wrong

;;;;;;;  jcxz	 POSINIT_RREADERR ; Jump if file was empty
	 or	 cx,cx		; Is the file empty?
	 jz	 near ptr POSINIT_RREADERR ; Jump if so

; Allocate the contents of ABIOS.SYS
	 movzx	 eax,cx 	; Get number of bytes read
	 add	 eax,16-1	; Round up to paragraph boundary
	 shr	 eax,4-0	; Convert bytes to paras
	 add	 ax,MAPSEG_NXT	; Get new high water mark
	 mov	 MAPSEG_NXT,ax	; Allocate storage for ABIOS.SYS
	 mov	 RAM_EXTSEG,ax	; Save start of RAM extensions

	 push	 ds		; Get start of ABIOS.SYS
	 pop	 gs		; Address via GS
	 assume  gs:nothing	; Tell the assembler

	 sub	 si,si		; GS:SI ==> ABIOS.SYS contents
				; CX = number of bytes
				; XGROUP:DI ==> start of file basename
POSINIT_NEXTREXT:
; Skip leading whitespace and get next filename
@@:
	 lods	 gs:[si].LO	; Get next character

	 call	 IZITWS 	; Check for whitespace
	 loope	 @B		; Go around again if so

	 je	 short POSINIT_REXTDONE ; End of file

; AL = filename[0]
; GS:SI ==> next character in filename
; XGROUP:DI ==> file basename
; Copy to file basename
	 push	 di		; Save offset
@@:
	 stos	 FLEXFILE_DPFE[di] ; Save a character
	 call	 IZITWS 	; Check for end of filename
	 je	 short @F	; Jump if so

	 lods	 gs:[si].LO	; Get next character
	 jcxz	 @F		; Jump if it was the last character in the file

	 loop	 @B		; Go around again

@@:
	 mov	 XGROUP:[di-1].LO,0 ; Blast in a trailing null

	 pop	 di		; Restore file basename offset

; Now try to open the ABIOS RAM extension file
	 push	 seg XGROUP	; Prepare to address XGROUP
	 pop	 ds		; ...via DS
	 assume  ds:XGROUP	; Tell the assembler

	 lea	 dx,FLEXFILE_DPFE ; Pathname of file to open
	 mov	 al,0		; Read-only, sharing compatibility mode
	 DOSCALL @OPENF2	; Open file DS:DX
	 jc	 short POSINIT_RREADERR ; Jump if file doesn't exist

	 mov	 bx,ax		; Copy into file handle register
	 mov	 ax,MAPSEG_NXT	; Get segment to read into
POSINIT_READFSEG:
	 mov	 ds,ax		; Address buffer for ABIOS image
	 assume  ds:nothing	; Tell the assembler

	 push	 cx		; Save loop counter
	 mov	 cx,0FFF0h	; Maximum bytes to read
	 sub	 dx,dx		; Offset to read into
	 DOSCALL @READF2	; Read CX bytes from BX into DS:DX
	 pop	 cx		; Restore
	 jc	 short POSINIT_FREADERR ; Jump if read failed

	 cmp	 ax,0FFF0h	; Did we read the maximum?
	 jne	 short @F	; Jump if not (end of file)

;;;;;;;  add	 ax,16-1	; Round up to para boundary
	 shr	 ax,4-0 	; Convert bytes to paras
	 add	 ax,MAPSEG_NXT	; Get next segment to read into
	 mov	 MAPSEG_NXT,ax	; Add to amount allocated
	 jmp	 short POSINIT_READFSEG ; Go around again

@@:
	 add	 ax,16-1	; Round up to para boundary
	 shr	 ax,4-0 	; Convert bytes to paras
	 add	 MAPSEG_NXT,ax	; Allocate file block

	 DOSCALL @CLOSF2	; Close handle BX

	 jmp	 short POSINIT_NEXTREXT ; Go around again

POSINIT_REXTDONE:
	 mov	 ax,MAPSEG_NXT	; Get next segment for allocation
	 cmp	 ax,RAM_EXTSEG	; Were any files read?
	 je	 short POSINIT_RREADERR ; Jump if not

; The RAM extensions are supposed to form a chain.  We need to terminate
; the chain by adding a zero-length extension to the end.
	 push	 es		; Save

	 mov	 es,ax		; Address next segment
	 assume  es:nothing	; Tell the assembler

	 push	 seg XGROUP	; Prepare to address XGROUP
	 pop	 ds		; ... via DS
	 assume  ds:XGROUP	; Tell the assembler

	 sub	 di,di		; Start at offset 0
	 lea	 si,RAM_EXTENSION ; What to copy
	 mov	 cx,@RAM_EXTLEN ; Bytes to move
S16 rep  movs	 <es:[di].LO,RAM_EXTENSION[si].LO> ; Copy empty RAM extension to end of chain
	 add	 di,16-1	; Round up to paragraph boundary
	 shr	 di,4-0 	; Convert bytes to paras
	 add	 MAPSEG_NXT,di	; Allocate space for empty RAM extension

	 pop	 es		; Restore
	 assume  es:XGROUP	; Tell the assembler

; Now try it again
	 mov	 ds,RAM_EXTSEG	; Address start of RAM extensions
	 assume  ds:nothing	; Tell the assembler

	 mov	 ah,04h 	; Function code to build system parameters table
	 lea	 di,SYSPARM	; ES:DI ==> system parameters table
	 int	 15h		; Request BIOS service
	 push	 seg XGROUP	; Prepare to address XGROUP
	 pop	 ds		; ... via DS
	 assume  ds:XGROUP	; Tell the assembler about it

	 jc	 short POSINIT_RREADERR ; Jump if we failed

	 jmp	 POSINIT_ABIOSOK ; Join common code to initialize ABIOS

POSINIT_FREADERR:
; Error occurred.  Close file handle BX.
	 DOSCALL @CLOSF2	; Close handle BX

POSINIT_RREADERR:
	 push	 seg XGROUP	; Prepare to address XGROUP
	 pop	 ds		; ... via DS
	 assume  ds:XGROUP	; Tell the assembler about it

	 mov	 ax,OLD_MAPSEG	; Get previous top of storage
	 mov	 MAPSEG_NXT,ax	; Release everything allocated so far

; We'll display MSG_ABIOSERR later unless NOABIOS is present in the profile.
	 or	 NRD_FLAG,@NRD_ABIOSERR ; Mark for later error display

	 jmp	 ERR_RET	; Join common error code

POSINIT_ABIOSOK:
	 mov	 ax,size INIT_TABLE_STR ; Get size of an init table entry
	 mul	 SYSPARM.NUM_ENTR ; Times # init table entries
	 add	 ax,16-1	; Round up to next para
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 ax,cl		; Convert from bytes to paras
	 mov	 bx,ax		; Copy to @GETMEM register
;;;;;;;; DOSCALL @GETMEM	; Allocate Memory for init table
;;;;;;;; jb	 near ptr ERR_RET ; Jump if something went wrong
	 mov	 ax,MAPSEG_NXT	; Get next available segment
	 add	 MAPSEG_NXT,bx	; Skip over it

	 mov	 SYSINIT_SEG,ax ; Save for later use
	 mov	 es,ax		; Address that segment
	 assume  es:nothing	; Tell the assembler about it
	 xor	 di,di		; ES:DI ==> initialization table

	 push	 ds		; Save for a moment

	 mov	 ds,RAM_EXTSEG	; DS:0 ==> RAM extension info
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ah,05h 	; Function code to build initialization table
	 int	 15h		; Request BIOS service
	 pop	 ds		; Restore
	 assume  ds:XGROUP	; Tell the assembler about it
	 jc	 near ptr ERR_RET ; Jump if something went wrong

COMMENT|

Build Common Data Area (CDA)

The size of the CDA is

size CDAHDR_STR 			header (essentially LID #0)
size CDALID_STR 			LID #1 (reserved)
(size CDALID_STR) x # logical ids	per device in INIT_TABLE_STR
DP_LEN					per device in INIT_TABLE_STR
2					data pointer count field

|

; Loop through the INIT_TABLE structure counting CDA size values

;;;;;;;; xor	 di,di		; ES:DI ==> start of init table
	 mov	 cx,SYSPARM.NUM_ENTR ; Get # init table entries

; Initialize accumulator in bytes

	 mov	 bx,2 + (size CDAHDR_STR) + (size CDALID_STR)
POSINIT_NEXT_ITE:
	 add	 bx,es:[di].DP_LEN ; Plus size of data pointers in bytes

	 mov	 ax,size CDALID_STR ; Get size of LID pointers in bytes
	 mul	 es:[di].NUM_LOG_IDS ; Times # logical IDs
	 add	 bx,ax		; Add into accumulator

	 add	 di,size INIT_TABLE_STR ; Skip to next entry

	 loop	 POSINIT_NEXT_ITE ; Jump if more init table entries

	 mov	 di,bx		; Save byte size

	 add	 bx,16-1	; Round up to next para
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 bx,cl		; Convert from bytes to paras
;;;;;;;; DOSCALL @GETMEM	; Allocate memory for init table
;;;;;;;; jc	 near ptr ERR_RET ; Jump if something went wrong
	 mov	 ax,MAPSEG_NXT	; Get next available segment
	 add	 MAPSEG_NXT,bx	; Skip over it

	 mov	 CDA_SEG,ax	; Save segment for later use
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

; Zero the CDA

	 push	 di		; Save for a moment

	 mov	 cx,di		; Copy length in bytes
	 xor	 di,di		; ES:DI ==> CDA
	 mov	 al,0		; A convenient zero
     rep stosb			; Zap it

	 pop	 di		; Restore

; Set Data Pointer #0 offset and count field

	 sub	 di,2		; Back off to data pointer count field
	 mov	 es:[di].ELO,0	; Zero data pointer count field

	 sub	 di,size CDADP_STR ; Back off to data pointer #0 length
	 mov	 es:[0].CDAHDR_DP0OFF,di ; Save in CDA

	 mov	 LOGICAL_ID,2	; Starting number for logical ids
	 mov	 INIT_ENTRY_CTR,0 ; Initialize system init table entry count

	 mov	 es,SYSINIT_SEG ; Get segment of system initialization table
	 assume  es:nothing	; Tell the assembler about it
	 xor	 di,di		; ES:DI ==> ...

; We initialize ABIOS internal and POS device ID only

GET_NEXTID:
	 cmp	 es:[di].DEVICE_ID,@ABIOS_POS ; Izit POS Device ID?
	 je	 short INIT_POS_LID ; Jump if so

	 cmp	 es:[di].DEVICE_ID,@ABIOS_NVRAM ; Izit NVRAM Device ID?
	 je	 short INIT_NVRAM_LID ; Jump if so

	 cmp	 es:[di].DEVICE_ID,@ABIOS_INTERNAL ; Izit ABIOS Internal ID?
	 je	 near ptr INIT_INT_LID ; Jump if so

					; Ignore the others
BUMP_ID:
	 mov	 ax,es:[di].NUM_LOG_IDS ; Get # logical IDs in this device
	 add	 LOGICAL_ID,ax	; Count them in
	 add	 di,size INIT_TABLE_STR ; Skip to next init table entry

	 mov	 ax,INIT_ENTRY_CTR ; Get current
	 inc	 ax		; Skip to next one
	 mov	 INIT_ENTRY_CTR,ax ; Save for later use

	 cmp	 ax,SYSPARM.NUM_ENTR ; Are we at the end?
	 jb	 short GET_NEXTID ; Jump if not

	 mov	 es,CDA_SEG	; Get CDA segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,LOGICAL_ID	; Get # logical IDs
	 mov	 es:[0].CDAHDR_NLIDS,ax ; Save in CDA

; Convert pointers in CDA from 32-bit to seg:off

	 mov	 bx,es:[0].CDAHDR_DP0OFF ; Get offset to DP #0
	 mov	 cx,es:[bx+(size CDADP_STR)] ; Get data pointer count
POSINIT_NEXT_DP:
	 mov	 dx,es:[bx].CDADP_VEC.EHI ; Get high-order word
	 mov	 ax,es:[bx].CDADP_VEC.ELO ; ... low-

	 push	 cx		; Save for a moment

	 mov	 cx,4		; Loop counter
	 clc			; Set CF=0
@@:
	 rcr	 dx,1		; Rotate in CF from AX low, out CF
	 rcr	 ax,1		; Shift low-order bit into CF
	 loop	 @B		; Jump if more bits

	 mov	 es:[bx].CDADP_VEC.VSEG,ax ; Save as segment
	 mov	 cl,4		; Rotate amount
	 rol	 dx,cl		; Rotate high-order nibble (original low-order)
	 mov	 es:[bx].CDADP_VEC.VOFF,dx ; Save as offset

	 pop	 cx		; Restore

	 sub	 bx,size CDADP_STR ; Back off to next DP structure

	 loop	 POSINIT_NEXT_DP ; Jump if more data pointers to normalize

	 mov	 ax,0		; Done

	 jmp	 INIT_END	; Join common exit code

ERR_RET:			; Done but error
	 mov	 ax,-1		; Mark as error return

	 jmp	 INIT_END	; Join common exit code

INIT_POS_LID:
	 mov	 ax,LOGICAL_ID	; Get its logical ID
	 mov	 POS_BLK.RB_LID,ax ; ...and save it for later use
	 mov	 ax,es:[di].INIT_RB_LEN ; Get request block length
	 mov	 POS_BLK.RB_LEN,ax ; ...and save it for later use

	 jmp	 short INIT_LID ; Join common code

INIT_NVRAM_LID:
	 mov	 ax,LOGICAL_ID	; Get its logical ID
	 mov	 NVRAM_LID,ax	; ...and save it for later use
	 mov	 ax,es:[di].INIT_RB_LEN ; Get request block length
	 cmp	 ax,size RB_NVRAM_STR ; Izit the minimum length?
	 jae	 short @F	; Jump if big enough

	 mov	 ax,size RB_NVRAM_STR ; Ensure it's big enough for read & write
@@:
	 mov	 NVRAM_RB_LEN,ax ; ...and save it for later use

; Allocate memory for Device Block

INIT_INT_LID:
INIT_LID:
	 mov	 ax,size CDALID_STR ; Size of a CDA element
	 mul	 LOGICAL_ID	; Times current logical ID to get
				; ...correct offset
	 mov	 si,ax		; Copy to index register

	 mov	 bx,es:[di].DEV_BLK_LEN ; Size of Device Block in bytes
	 add	 bx,16-1	; Round up to next para
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 bx,cl		; Convert from bytes to paras
;;;;;;;; DOSCALL @GETMEM	; Allocate memory for Device Block
;;;;;;;; jb	 short ERR_RET	; Jump if something went wrong
	 mov	 ax,MAPSEG_NXT	; Get next available segment
	 add	 MAPSEG_NXT,bx	; Skip over it

; Because of a bug in the Phoenix MCA BIOS, we must ensure that the
; low-order byte of the segment of the Device Block is non-zero

	 xor	 dx,dx		; Set AX:DX to segment

	 cmp	 al,0		; Izit non-zero?
	 jne	 short @F	; Jump if so

	 dec	 ax		; Back off by one para
	 add	 dx,16		; ...and forward by 16 bytes
@@:

; Save segment of Device Block in System Initialization Table

	 mov	 es,CDA_SEG	; Get CDA segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[si].CDALID_DBVEC.VOFF,dx ; Save offset
	 mov	 es:[si].CDALID_DBVEC.VSEG,ax ; ...  segment

; Allocate memory for Function Transfer Table

	 mov	 es,SYSINIT_SEG ; Get segment of system initialization table
	 assume  es:nothing	; Tell the assembler about it

	 mov	 bx,es:[di].FTT_LEN ; Get size of Function Transfer Table
	 add	 bx,16-1	; Round up to next para
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 bx,cl		; Convert from bytes to paras
;;;;;;;; DOSCALL @GETMEM	; Allocate memory for Function Transfer Table
;;;;;;;; jb	 short ERR_RET	; Jump if something went wrong
	 mov	 ax,MAPSEG_NXT	; Get next available segment
	 add	 MAPSEG_NXT,bx	; Skip over it

; Because of a bug in the Phoenix MCA BIOS, we must ensure that the
; low-order byte of the segment of the Function Transfer Table is non-zero

	 xor	 dx,dx		; Set AX:DX to segment

	 cmp	 al,0		; Izit non-zero?
	 jne	 short @F	; Jump if so

	 dec	 ax		; Back off by one para
	 add	 dx,16		; ...and forward by 16 bytes
@@:

; Save segment of FTT in System Initialization Table

	 mov	 es,CDA_SEG	; Get CDA segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 es:[si].CDALID_FTTVEC.VOFF,dx ; Save offset
	 mov	 es:[si].CDALID_FTTVEC.VSEG,ax ; ...  segment

; Call ABIOS to initialize pointers

	 mov	 es,SYSINIT_SEG ; Get segment of system initialization table
	 assume  es:nothing	; Tell the assembler about it

	 mov	 cx,1		; # logical IDs to initialize
;;;????? mov	 cx,es:[di].NUM_LOG_IDS ; Get # logical IDs in this device
	 mov	 dx,LOGICAL_ID	; Logical ID # to initialize

	 push	 ds		; Save for a moment
	 mov	 ds,CDA_SEG	;  DS -> Common Data Area
	 assume  ds:nothing	; Tell the assembler about it

	 call	 es:[di].INIT_PTR ; Initialize 'em
	 pop	 ds		; Restore
	 assume  ds:XGROUP	; Tell the assembler about it

	 jmp	 BUMP_ID	; Go around again

; De-allocate memory for Initialization table ???

INIT_END:
;;;;;;;; mov	 es,SYSINIT_SEG ; Get segment of system initialization table
;;;;;;;; assume  es:nothing	; Tell the assembler about it
;;;;;;;;
;;;;;;;; push	 ax		; Save for a moment
;;;;;;;; DOSCALL @RELMEM	; Release it
;;;;;;;; pop	 ax		; Restore
;;;;;;;;
	 REGREST <gs,fs,es,ds,di,si,dx,cx,bx> ; Restore
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

POSINIT  endp			; End POSINIT procedure
	 FPPROC  POSREAD -- Read POS Data for Slot
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

'C' callable routine to read the POS (programable option select) data

posread (slot#, cmos_vals)

On exit:

AX	 =	 0 if no error
	 !=	 0 otherwise

|

POSREAD_STR struc

	 dw	 ?		; Caller's BP
	 dd	 ?		; Return Address CS:IP
POSR_SLOTNO db	 ?,?		; Slot # (origin-1, or 0 for system board)
POSR_CMOS_VALS dd ?		; Ptr to CMOS values

POSREAD_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <bx,cx,dx,si,di,ds> ; Save registers

	 mov	 ax,seg XGROUP	; Get segment of XGROUP
	 mov	 ds,ax		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 mov	 al,[bp].POSR_SLOTNO ; Get slot # (origin-1) of the adapter
	 mov	 POS_BLK.POS_SLOT_NO,al ; Save in request block

	 mov	 POS_BLK.RB_RETCODE,0FFFFh ; Set default error code
	 mov	 POS_BLK.RB_FUNC,0Bh ; Function - Read 6 bytes from CMOS
				; into I/O ports 100h to 105h and
				; into adapter ID and Data Buffer

	 mov	 POS_BLK.RB_UNIT,0 ; Must be zero at startup
	 mov	 POS_BLK.RB_RES1,0 ; ...
	 mov	 POS_BLK.RB_RES2,0 ; ...

	 mov	 POS_BLK.POS_RES1,0 ; Must be zero at startup ??? WHY ???
	 mov	 POS_BLK.POS_RES2,0 ; ...
	 mov	 POS_BLK.POS_RES3,0 ; ...
	 mov	 POS_BLK.POS_RES4,0 ; ...

	 mov	 ax,[bp].POSR_CMOS_VALS.VOFF ; Get offset of CMOS_VALS
	 mov	 POS_BLK.POS_VEC.VOFF,ax ; Save in request block
	 mov	 ax,[bp].POSR_CMOS_VALS.VSEG ; Get segment of CMOS_VALS
	 mov	 POS_BLK.POS_VEC.VSEG,ax ; Save in request block

	 mov	 POS_BLK.POS_ADAPT_ID,-1 ; Zap the adapter ID

	 push	 CDA_SEG	; CDA segment
	 push	 ds		; Request block segment
	 lea	 ax,POS_BLK	; ...		offset
	 push	 ax		; Pass to SYSPARM routine
	 sub	 sp,size SYSPLACE_STR ; Make room for place holders
	 call	 SYSPARM.STARTPTR ; Request ABIOS service
	 add	 sp,size SYSCALL_STR ; Pop our own calling args

	 mov	 ax,POS_BLK.RB_RETCODE ; Return error code as result

	 REGREST <ds,di,si,dx,cx,bx> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+4		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,ss:nothing

POSREAD  endp			; End POSREAD procedure
	 FPPROC  POSWRITE -- Write POS Data to a Slot
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

'C' callable routine to write the POS (programable option select) data

poswrite (slot#, cmos_vals, adap_id)

On exit:

AX	 =	 0 if no error
	 !=	 0 otherwise

|

POSWRITE_STR struc

	 dw	 ?		; Caller's BP
	 dd	 ?		; ...	   CS:IP
POSW_SLOTNO    db ?,?		; Slot # (origin-1)
POSW_CMOS_VALS dd ?		; Ptr to CMOS values
POSW_ADAP_ID   dw ?		; Adapter ID

POSWRITE_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <bx,cx,dx,si,di,ds> ; Save registers

	 mov	 ax,seg XGROUP	; Get segment of XGROUP
	 mov	 ds,ax		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 mov	 al,[bp].POSW_SLOTNO ; Get slot # (origin-1) of the adapter
	 mov	 POS_BLK.POS_SLOT_NO,al ; Save in request block

	 mov	 POS_BLK.RB_RETCODE,0FFFFh ; Set default error code
	 mov	 POS_BLK.RB_FUNC,0Ch ; Function - Write POS bytes
				; to CMOS -- rebooting will then
				; write these bytes to the adapter

	 mov	 POS_BLK.RB_UNIT,0 ; Must be zero at startup
	 mov	 POS_BLK.RB_RES1,0 ; ...
	 mov	 POS_BLK.RB_RES2,0 ; ...

	 mov	 POS_BLK.POS_RES1,0 ; Must be zero at startup ??? WHY ???
	 mov	 POS_BLK.POS_RES2,0 ; ...
	 mov	 POS_BLK.POS_RES3,0 ; ...
	 mov	 POS_BLK.POS_RES4,0 ; ...

	 mov	 ax,[bp].POSW_CMOS_VALS.VOFF ; Get offset of CMOS_VALS
	 mov	 POS_BLK.POS_VEC.VOFF,ax ; Save in request block
	 mov	 ax,[bp].POSW_CMOS_VALS.VSEG ; Get segment of CMOS_VALS
	 mov	 POS_BLK.POS_VEC.VSEG,ax ; Save in request block

	 mov	 ax,[bp].POSW_ADAP_ID ; AX = adapter_id
	 mov	 POS_BLK.POS_ADAPT_ID,ax ; Save in request block

	 push	 CDA_SEG	; CDA segment
	 push	 ds		; Request block segment
	 lea	 ax,POS_BLK	; ...		offset
	 push	 ax		; Pass to SYSPARM routine
	 sub	 sp,size SYSPLACE_STR ; Make room for place holders
	 call	 SYSPARM.STARTPTR ; Request ABIOS service
	 add	 sp,size SYSCALL_STR ; Pop our own calling args

	 mov	 ax,POS_BLK.RB_RETCODE ; Return error code as result

	 REGREST <ds,di,si,dx,cx,bx> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+4+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

POSWRITE endp			; End POSWRITE procedure
	 FPPROC  NVRAM_CMPWRITE -- Write POS Data for system board to NVRAM
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Compare POS data with NVRAM values.  Write any that are different.
If any values were written, return with CF=1 to indicate NVRAM checksum
needs to be recalculated via ABIOS.

On entry:

On exit:
CF=1	One or more bytes were changed; recompute NVRAM checksum
CF=0	No changes made

|

NVRAMCW_STR struc

	 dw	 ?		; Caller's BP
	 dd	 ?		; ...	   CS:IP
NVRAMCW_DATA dd  ?		; Ptr to NVRAM values
NVRAMCW_LEN dw	 ?		; Number of bytes to write
NVRAMCW_BASE dw  ?		; Starting NVRAM offset

NVRAMCW_STR ends

@RW_ABIOS equ	 0		; 1=Use ABIOS functions to read/write NVRAM

RW_NVRAM	 macro	function
; function = 8 to read, 9 to write
; NVRAM index in DX
; If writing, AL=byte to write to NVRAM

ife @RW_ABIOS
if function EQ 9
	 push	 ax		; Save
endif				; IF writing
	 mov	 al,dl		; Get low byte of index
	 cli			; Nobody move
	 out	 @NVRAMIND_LO,al ; Send to low byte of NVRAM index register
	 jmp	 short $+2	; Wait for I/O to settle

	 mov	 al,dh		; Get high byte of index
	 out	 @NVRAMIND_HI,al ; Send to high byte of NVRAM index register
	 jmp	 short $+2	; Wait for I/O to settle

if function EQ 9
	 pop	 ax		; Restore
endif				; IF writing
endif				; IFE @RW_ABIOS

if @RW_ABIOS
	 mov	 ah,function	; 08h to read, 09h to write
	 call	 NVRAMFN	; Return error in AX if CF=1
				; Otherwise, return byte in AL for function 08h
else
if function EQ 9
	 out	 @NVRAMDATA,al	; Send to NVRAM
else
	 in	 al,@NVRAMDATA	; Get current value
endif				; IF writing/reading
	 sti			; Enable interrupts
endif				; IF @RW_ABIOS

	 endm			; End RW_NVRAM macro

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,bx,cx,dx,si,ds> ; Save

	 lds	 si,[bp].NVRAMCW_DATA ; Address array of values
	 sub	 bx,bx		; Initialize counter for changed values
	 mov	 cx,[bp].NVRAMCW_LEN ; Number of bytes to compare/write
	 mov	 dx,[bp].NVRAMCW_BASE ; Beginning NVRAM index

NVRAMCW_NEXT:
	 RW_NVRAM <08h> 	; Get NVRAM[dx] in AL
;;;;;;;  jc	 ???		; Ignore error

	 cmp	 al,ds:[si].LO	; Izit different?
	 lods	 ds:[si].LO	; Get next byte, advancing SI
	 je	 short NVRAMCW_LOOP ; Jump if so

	 RW_NVRAM <09h> 	; Save AL in NVRAM[dx]
;;;;;;;  jc	 ???		; Ignore error

	 inc	 bx		; Update bytes changed counter

NVRAMCW_LOOP:
	 inc	 dx		; Point to next NVRAM index location
	 loop	 NVRAMCW_NEXT	; Go around again

	 cmp	 bx,1		; Were any values written?
	 cmc			; Set CF if so

	 REGREST <ds,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 4+2+2		; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NVRAM_CMPWRITE endp		; End NVRAM_CMPWRITE procedure
	 FPPROC  POSREADALL -- Read All POS Data
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Read all POS data

This data is needed by MAXIMIZE in case it can't read it
from ABIOS because we've compressed the BIOS through Redwheat.

Note that we store the system board CMOS POS data in POSDATA[8].

|

	 REGSAVE <ax,bx,cx,si,di,ds> ; Save registers

	 push	 seg XGROUP	; Get segment of MCAID
	 pop	 ds		; Address it
	 assume  ds:XGROUP	; Tell the assembler about it

	 call	 POSINIT	; Initialize the ABIOS tables

	 or	 ax,ax		; Did we succeed?
	 jnz	 short POSREADALL_ERR ; Jump if initialization failed

	 lea	 di,POSDATA	; ES:DI ==> save area for POS data
	 lea	 si,MCAID	; DS:SI ==> MCA adapter IDs
	 mov	 cx,@MAXPOSDEV	; CX = maximum # slots + system board
	 mov	 bl,1		; Start with slot #0 (origin-1)
POSREADALL_NEXT:
S16	 movs	 <POSDATA[di].POSD_ID,MCAID[si]> ; Copy adapter ID into POSD_STR

	 cmp	 bl,9		; Izit the system board?
	 jb	 short @F	; Jump if not

	 sub	 bl,bl		; Read system board CMOS POS data
@@:
	 push	 es		; Pass segment of save area
	 push	 di		; ...  offset of POS data
	 push	 bx		; Pass slot #
	 call	 POSREAD	; Read in current POS values
				; Ignore return code in AX

	 or	 bl,bl		; Izit the system board?
	 jnz	 short POSREADALL_XSYS ; Jump if not

; We'd love to rely on the ABIOS to get the NVRAM bytes for the system
; board CMOS POS, but the somewhat scanty documentation indicates that
; for the system board, the 'option select byte' (note lack of plural)
; is returned.	We'll assume that the first byte returned is indeed POS[0],
; and that we need the other 3 only...
	 REGSAVE <cx,dx,di>	; Save

	 mov	 cx,(size POSD_CMOS)-1 ; Bytes left to fill in
	 mov	 dx,@NVRAMPOSBASE+1 ; Index of second sys POS byte in NVRAM
	 inc	 di		; Skip first byte
@@:
	 RW_NVRAM <08h> 	; Get NVRAM[dx] in AL
;;;;;;;  jc	 ???		; Ignore error

	 inc	 dx		; Skip to next
	 stos	 POSDATA[di].POSD_CMOS ; Save in structure
	 loop	 @B		; Go around again

	 REGREST <di,dx,cx>	; Restore

POSREADALL_XSYS:
	 inc	 bl		; Skip to next slot
	 add	 di,(size POSD_STR)-(type POSD_ID) ; Skip to next entry

	 loop	 POSREADALL_NEXT ; Jump if more slots to read

	 jmp	 short POSREADALL_EXIT ; Join common exit

POSREADALL_ERR:
	 or	 SYS_FLAG,@SYS_MCAXABIOS ; Mark as an MCA machine without ABIOS

POSREADALL_EXIT:
	 REGREST <ds,di,si,cx,bx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

POSREADALL endp 		; End POSREADALL procedure

	 FPPROC  NVRAM_CRC -- Recompute NVRAM CRC
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Recompute NVRAM CRC.

The ABIOS function that it would seem should do this only calculates
the CRC for the adapter NVRAM POS at 0-161h.  Apparently, this wasn't
a problem for earlier machines, but we need to do it ourselves on the
Model 56 486SLC2.

|

	 REGSAVE <ax,bx,cx,dx,si,di,ds> ; Save

	 push	 seg PGROUP	; Prepare to address PGROUP
	 pop	 ds		; Get addressability to data
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 ax,POSDATA[8*(size POSD_STR)].POSD_ID ; Get system board ID
	 cmp	 ax,0E0FEh	; Izit Model 56 486SLC2?
	 je	 short @F	; Jump if so

	 cmp	 ax,0E1FEh	; Izit other system (???)
	 jne	 short NVC_EXIT ; Jump if not

@@:
	 push	 seg XGROUP	; Prepare to address XGROUP
	 pop	 ds		; Get addressability to data
	 assume  ds:XGROUP	; Tell the assembler

	 cld			; String ops forwardly

	 sub	 di,di		; CRC accumulator
	 mov	 bx,-1		; CRC seed value

	 lea	 si,NVRAM_CRCTAB ; Address list of ranges
	 mov	 cx,@NVRAM_CRCLEN ; Number of ranges
NVC_NEXTRANGE:
	 lods	 NVRAM_CRCTAB[si] ; Get start of range
	 mov	 dx,ax		; Put into NVRAM index register
	 lods	 NVRAM_CRCTAB[si] ; Get length in bytes

	 push	 cx		; Save range counter

	 mov	 cx,ax		; Number of bytes in this range
NVC_NEXTBYTE:
	 RW_NVRAM <08h> 	; Get NVRAM[dx] in AL

	 xchg	 dx,di		; Save index, get accumulator

	 xor	 bh,al
	 mov	 al,bh
	 mov	 ah,dh		; Get high byte from accumulator
	 rol	 ax,4
	 xor	 bx,ax
	 rol	 ax,1
	 xchg	 bh,bl
	 xor	 bx,ax
	 ror	 ax,4
	 and	 al,0E0h
	 xor	 bx,ax
	 ror	 ax,1
	 mov	 dx,ax		; Save result in accumulator
	 xor	 bh,dl

	 xchg	 dx,di		; Save accumulator, get index

	 inc	 dx		; Skip to next NVRAM byte
	 loop	 NVC_NEXTBYTE	; Go around again

	 pop	 cx		; Restore range counter

	 loop	 NVC_NEXTRANGE	; Go around again

; Send BH to NVRAM[4EC], BL to NVRAM[4ED]
	 mov	 al,bh		; High byte of CRC
	 mov	 dx,4ECh	; The magic location for the NVRAM CRC
	 RW_NVRAM <09h> 	; Save AL in NVRAM[dx]
	 inc	 dx		; Skip to next location (4ED)
	 mov	 al,bl		; Low byte of CRC
	 RW_NVRAM <09h> 	; Save AL in NVRAM[dx]

NVC_EXIT:
	 REGREST <ds,di,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

NVRAM_CRC endp			; End NVRAM_CRC procedure

XCODE	 ends			; End XCODE segment

	 MEND			; End QMAX_POS module
