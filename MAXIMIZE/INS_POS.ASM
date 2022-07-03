;' $Header:   P:/PVCS/MAX/MAXIMIZE/INS_POS.ASV   1.1   30 May 1997 11:45:44   BOB  $
	 title	 INS_POS  -- POS Subroutines for Maximize
	 page	 58,122
	 name	 INS_POS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-97 Qualitas, Inc.  GNU General Public License version 3.

|

comment |
int posinit (void);
void poswrite (int, char far *, char far *, WORD far *);
void nvramcheck (void);
void posread (int, char far *, char far *, WORD far *);
|
.386
	 include MASM.INC
	 include 386.INC
	 include DOSCALL.INC
	 include PTR.INC
	 include ABIOS.INC
	 include ASCII.INC

;;;;;;;;.model large,c

DGROUP group _DATA
PGROUP group INS_POS_DATA
REGROUP group RAM_EXTENSION_DATA

_DATA segment use16 dword public 'data' ; Start _DATA segment
_DATA ends			; End _DATA segment

INS_POS_DATA segment use16 dword public 'data' ; Start INS_POS_DATA segment
INS_POS_DATA ends		; End INS_POS_DATA segment

INS_POS_TEXT segment use16 byte public 'code' ; Start CODE segment
INS_POS_TEXT ends		; End CODE segment

SAVEADF_TEXT segment use16 byte public 'code' ; Start CODE segment

extrn	 _adf_dir:far		; char far *adf_dir (char far *dir)
				; Returns pointer to static data area

SAVEADF_TEXT ends		; End CODE segment

;      Updated Dec 27, 1989	by Rainer McCown
;
; Sample calling sequence from 'C'
;
; main()
;   {
;   char cmos_values[4];
;   char adapter_values[4];
;   char adapter_id[4];
;   int posr_error, posw_error;
;
;   if (posinit() == 0)
;      {      /* Read slot 8 */
;      posr_error = posread(8, cmos_values, adapter_values, adapter_id);
;      if (posr_error != 0) printf(" POS read error code %d",posr_error);
;      cmos_values[0] |= 0x10;
;      adapter_values[0] |= 0x10;
;      posw_error = poswrite(8, cmos_values, adapter_values, adapter_id);
;      if (posw_error != 0) printf(" POS write error code %d",posr_error);
;      }
;   }
;

;;;;;;;;.data
INS_POS_DATA segment
	 assume  ds:PGROUP

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

	 public  RAM_EXTSEG,ABIOS_SEG,ABIOS_SIZ,ABIOS_REM,FNAME_PTR
	 public  ABIOS_SYS,REXT_FNAME
RAM_EXTSEG dw	 seg RAM_EXTENSION ; Segment of RAM extension data
ABIOS_SEG dw	 0		; Segment allocated for RAM ABIOS
ABIOS_SIZ dw	 0		; Paras used for RAM ABIOS
ABIOS_REM dw	 ?		; Remaining paras in ABIOS_SEG block
FNAME_PTR dw	 ?		; Offset within PGROUP of filename in REXT_FNAME
ABIOS_SYS db	 'ABIOS.SYS',0  ; Found in c:\386max\adf\ directory
REXT_FNAME db	 128 dup (0)	; Full path to *.BIO files

INS_POS_DATA ends		; End INS_POS_DATA segment

; Define zero length RAM extension data
; On the PS/2 Model 56 486SLC2 (and possibly other new models) there is
; no ABIOS in the ROM.	We are expected to load the ABIOS image (which is
; prefixed with a RAM extension signature) and pass its segment.  We'll
; still need this empty entry to terminate the chain of RAM extensions.

RAM_EXTENSION_DATA segment use16 para public 'far_data'
	 assume  cs:nothing,ds:REGROUP

RAM_EXTENSION dw 0AA55h,0000
@RAM_EXTLEN equ $-RAM_EXTENSION

RAM_EXTENSION_DATA ends

INS_POS_TEXT segment
	 assume  cs:INS_POS_TEXT,ds:nothing

@CodeSize equ 1 		; Normally set by .model ...

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

	 FPPROC  _posinit	; -- Initialize POS Data Area
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

'C' callable routine to initialize the POS (programable option select) data.

On exit:

AX	 =	 0 if no error
	 =	 -1 otherwise

|

	 REGSAVE <eax,bx,cx,dx,si,di,ds,es,fs,gs> ; Save registers

	 mov	 ax,seg PGROUP	; Get segment of PGROUP
	 mov	 ds,ax		; Address it (*WARNING* SS != DS)
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 es,ax		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 SYSINIT_SEG,0	; Initialize to a meaningful NULL value

	 lea	 di,SYSPARM	; ES:DI ==> system parameters table

	 push	 ds		; Save for a moment
	 mov	 ds,RAM_EXTSEG	; DS:0 ==> RAM extension info
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ah,04h 	; Function code to build system parameters table
	 int	 15h		; Request BIOS service
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
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

; Note that this may involve a very large memory allocation, and it all
; must be contiguous.  We'll allocate the largest block we can, and
; take from it as needed.  We need to free it on exit if we failed,
; or resize it downward to the size used.
	 mov	 bx,-1		; Maximum allocation
	 DOSCALL @GETMEM	; Return largest free block in BX
	 mov	 ABIOS_REM,bx	; Save block size
	 DOSCALL @GETMEM	; AX = segment
	 jc	 near ptr POSINIT_RREADERR ; Jump if no room at the inn

	 mov	 ABIOS_SEG,ax	; Save starting paragraph

	 push	 ds		; Save addressability to PGROUP

	 push	 seg DGROUP	; Prepare to address DGROUP
	 pop	 ds		; Address it (DS == SS)
	 assume  ds:DGROUP	; Tell the assembler

	 PUSHD	 0		; Pass a null pointer
	 call	 _adf_dir	; On return: DX:AX ==> "c:\386max\adf\"
	 add	 sp,2*2 	; Remove arguments from stack

	 pop	 es		; Address PGROUP for stos
	 assume  es:PGROUP	; Tell the assembler

	 push	 es		; Put it back on stack for DS restore

	 lea	 di,REXT_FNAME	; Address pathname
	 mov	 si,ax		; Get offset of ADFDIR path
	 mov	 ds,dx		; Get segment ...
	 assume  ds:nothing	; Tell the assembler

	 cld			; String ops forwardly
@@:
	 lods	 ds:[si].LO	; Get a byte
	 mov	 FNAME_PTR,di	; Save offset of first character past end
	 stos	 REXT_FNAME[di] ; Save it
	 or	 al,al		; Izit the end?
	 jnz	 short @B	; Go around again if not

	 pop	 ds		; Restore PGROUP addressability
	 assume  ds:PGROUP	; Tell the assembler

	 lea	 si,ABIOS_SYS	; DS:SI ==> 'ABIOS.SYS',0
	 dec	 di		; ES:DI ==> trailing null in path

	 push	 di		; Save offset of file basename
@@:
	 lods	 ABIOS_SYS[si]	; Get next byte
	 stos	 REXT_FNAME[di] ; Save it
	 or	 al,al		; Izit the end?
	 jnz	 short @B	; Go around again if not

	 pop	 di		; Restore offset of file basename

; FNAME_PTR is the offset in PGROUP for the file basename
; ABIOS_SEG is the starting segment
; ABIOS_SIZ is the running total of paragraphs allocated
; ABIOS_REM is the number of paragraphs remaining unallocated
	 lea	 dx,REXT_FNAME	; DS:DX ==> 'c:\386max\adf\abios.sys',0

	 mov	 al,0		; Read-only, sharing compatibility mode
	 DOSCALL @OPENF2	; Open file DS:DX
	 jc	 near ptr POSINIT_RREADERR ; Jump if file doesn't exist

	 mov	 bx,ax		; Copy to handle register
	 mov	 cx,ABIOS_REM	; Get available paras
	 cmp	 cx,0FFFh	; Izit >64K ?
	 jbe	 short @F	; Jump if not

	 mov	 cx,0FFFh	; Maximum file size in paras
@@:
	 shl	 cx,4-0 	; Convert paras to bytes

	 mov	 ds,ABIOS_SEG	; Get start of available memory
	 assume  ds:nothing	; Tell the assembler

	 sub	 dx,dx		; Start at beginning of segment
	 DOSCALL @READF2	; Read CX bytes from BX into DS:DX

	 pushf			; Save result of read
	 mov	 cx,ax		; Save bytes read into count register

	 DOSCALL @CLOSF2	; Close file (ignore result)

	 popf			; Restore result of operation

	 jc	 near ptr POSINIT_RREADERR ; Jump if something went wrong

;;;;;;;  jcxz	 POSINIT_RREADERR ; Jump if file empty
	 or	 cx,cx		; Is the file empty?
	 jz	 near ptr POSINIT_RREADERR ; Jump if so

; Allocate the contents of ABIOS.SYS
	 movzx	 eax,cx 	; Get number of bytes read
	 add	 eax,16-1	; Round up to paragraph boundary
	 shr	 eax,4-0	; Convert bytes to paras
	 add	 ABIOS_SIZ,ax	; Add to count of allocated paras
	 sub	 ABIOS_REM,ax	; Subtract from remaining space
	 jbe	 near ptr POSINIT_RREADERR ; If no space left, we're out of luck

	 mov	 gs,ABIOS_SEG	; Address start of ABIOS.SYS
	 assume  gs:nothing	; Tell the assembler

	 add	 ax,ABIOS_SEG	; Skip space allocated for ABIOS.SYS
	 mov	 RAM_EXTSEG,ax	; Save start of RAM extensions

	 sub	 si,si		; GS:SI ==> ABIOS.SYS contents
				; CX = number of bytes
				; PGROUP:DI ==> start of file basename
POSINIT_NEXTREXT:
; Skip leading whitespace and get next filename
@@:
	 lods	 gs:[si].LO	; Get next character

	 call	 IZITWS 	; Check for whitespace
	 loope	 @B		; Go around again if so

	 je	 near ptr POSINIT_REXTDONE ; End of file

; AL = filename[0]
; GS:SI ==> next character in filename
; PGROUP:DI ==> file basename
; Copy to file basename
	 push	 di		; Save offset
@@:
	 stos	 REXT_FNAME[di] ; Save a character
	 call	 IZITWS 	; Check for end of filename
	 je	 short @F	; Jump if so

	 lods	 gs:[si].LO	; Get next character
	 jcxz	 @F		; Jump if it was the last character in the file

	 loop	 @B		; Go around again

@@:
	 mov	 PGROUP:[di-1].LO,0 ; Blast in a trailing null

	 pop	 di		; Restore file basename offset

; Now try to open the ABIOS RAM extension file
	 push	 seg PGROUP	; Prepare to address PGROUP
	 pop	 ds		; ...via DS
	 assume  ds:PGROUP	; Tell the assembler

	 lea	 dx,REXT_FNAME	; Pathname of file to open
	 mov	 al,0		; Read-only, sharing compatibility mode
	 DOSCALL @OPENF2	; Open file DS:DX
	 jc	 near ptr POSINIT_RREADERR ; Jump if file doesn't exist

	 mov	 bx,ax		; Copy into file handle register
POSINIT_READFSEG:
	 mov	 ax,ABIOS_SEG	; Get starting segment to read into
	 add	 ax,ABIOS_SIZ	; Skip what's been allocated already
	 mov	 ds,ax		; Address buffer for ABIOS image
	 assume  ds:nothing	; Tell the assembler

	 push	 cx		; Save loop counter
	 mov	 cx,0FFF0h	; Maximum bytes to read
	 sub	 dx,dx		; Offset to read into
	 DOSCALL @READF2	; Read CX bytes from BX into DS:DX
	 pop	 cx		; Restore
	 jc	 near ptr POSINIT_FREADERR ; Jump if read failed

	 cmp	 ax,0FFF0h	; Did we read the maximum?
	 jne	 short @F	; Jump if not (end of file)

;;;;;;;  add	 ax,16-1	; Round up to para boundary
	 shr	 ax,4-0 	; Convert bytes to paras
	 add	 ABIOS_SIZ,ax	; Add to count of bytes allocated
	 sub	 ABIOS_REM,ax	; Subtract from count of remaining space
	 jc	 near ptr POSINIT_FREADERR ; Jump if we ran out of space

	 jmp	 short POSINIT_READFSEG ; Go around again

@@:
	 add	 ax,16-1	; Round up to para boundary
	 shr	 ax,4-0 	; Convert bytes to paras
	 add	 ABIOS_SIZ,ax	; Add to count of bytes allocated
	 sub	 ABIOS_REM,ax	; Subtract from count of remaining space
	 jc	 near ptr POSINIT_FREADERR ; Jump if we ran out of space

	 DOSCALL @CLOSF2	; Close handle BX

	 jmp	 near ptr POSINIT_NEXTREXT ; Go around again

POSINIT_REXTDONE:
	 cmp	 ABIOS_SIZ,0	; Were any files read?
	 je	 short POSINIT_RREADERR ; Jump if not

; The RAM extensions are supposed to form a chain.  We need to terminate
; the chain by adding a zero-length extension to the end.
	 push	 es		; Save

	 mov	 ax,ABIOS_SEG	; Get starting segment
	 add	 ax,ABIOS_SIZ	; Skip paras already allocated

	 mov	 es,ax		; Address next segment
	 assume  es:nothing	; Tell the assembler

	 push	 seg REGROUP	; Prepare to address REGROUP
	 pop	 ds		; ... via DS
	 assume  ds:REGROUP	; Tell the assembler

	 sub	 di,di		; Start at offset 0
	 lea	 si,RAM_EXTENSION ; What to copy
	 mov	 cx,(@RAM_EXTLEN/2) ; Words to move
S16 rep  movs	 <es:[di].ELO,RAM_EXTENSION[si]> ; Copy empty RAM extension to end of chain
	 pop	 es		; Restore
	 assume  es:PGROUP	; Tell the assembler

	 add	 di,16-1	; Round up to paragraph boundary
	 shr	 di,4-0 	; Convert bytes to paras
	 add	 ABIOS_SIZ,di	; Allocate space for empty RAM extension
	 sub	 ABIOS_REM,di	; Subtract from remaining space
	 jc	 short POSINIT_RREADERR ; Jump if out of room

; Now try it again
	 mov	 ds,RAM_EXTSEG	; Address start of RAM extensions
	 assume  ds:nothing	; Tell the assembler

	 mov	 ah,04h 	; Function code to build system parameters table
	 lea	 di,SYSPARM	; ES:DI ==> system parameters table
	 int	 15h		; Request BIOS service
	 push	 seg PGROUP	; Prepare to address PGROUP
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 jc	 short POSINIT_RREADERR ; Jump if we failed

; We need to resize down to the space actually used so subsequent @GETMEM
; calls may succeed...
	 mov	 bx,ABIOS_SIZ	; Get number of paragraphs used
	 mov	 es,ABIOS_SEG	; Get RAM ABIOS segment
	 assume  es:nothing	; Tell the assembler

	 DOSCALL @MODMEM	; Ignore result
	 jmp	 POSINIT_ABIOSOK ; Join common code to initialize ABIOS

POSINIT_FREADERR:
; Error occurred.  Close file handle BX.
	 DOSCALL @CLOSF2	; Close handle BX

POSINIT_RREADERR:
	 push	 seg PGROUP	; Prepare to address PGROUP
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 jmp	 ERR_RET	; Join common error code

POSINIT_ABIOSOK:
	 mov	 ax,size INIT_TABLE_STR ; Get size of an init table entry
	 mul	 SYSPARM.NUM_ENTR ; Times # init table entries
	 add	 ax,16-1	; Round up to next para
	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 shr	 ax,cl		; Convert from bytes to paras
	 mov	 bx,ax		; Copy to @GETMEM register
	 DOSCALL @GETMEM	; Allocate Memory for init table
	 jb	 short ERR_RET0 ; Jump if something went wrong

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
	 assume  ds:PGROUP	; Tell the assembler about it
	 jc	 short ERR_RET0 ; Jump if something went wrong

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
	 DOSCALL @GETMEM	; Allocate memory for init table
ERR_RET0:
	 jb	 near ptr ERR_RET ; Jump if something went wrong

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
	 je	 near ptr INIT_POS_LID ; Jump if so

	 cmp	 es:[di].DEVICE_ID,@ABIOS_NVRAM ; Izit NVRAM Device ID?
	 je	 near ptr INIT_NVRAM_LID ; Jump if so

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

	 clc			; Done

	 jmp	 INIT_END	; Join common exit code

ERR_RET:			; Done but error
	 mov	 ax,ABIOS_SEG	; Get segment for RAM ABIOS
	 or	 ax,ax		; Did we allocate anything?
	 jz	 short @F	; Jump if not

	 mov	 es,ax		; Address segment to release it
	 assume  es:nothing	; Tell the assembler

	 DOSCALL @RELMEM	; Free segment at ES:0
@@:
	 stc			; Mark as error return

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
	 DOSCALL @GETMEM	; Allocate memory for Device Block
	 jb	 short ERR_RET	; Jump if something went wrong

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
	 DOSCALL @GETMEM	; Allocate memory for Function Transfer Table
	 jb	 near ptr ERR_RET ; Jump if something went wrong

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
	 assume  ds:PGROUP	; Tell the assembler about it

	 jmp	 BUMP_ID	; Go around again

; De-allocate memory for Initialization table ???

INIT_END:
	 pushf			; Save for a moment

	 cmp	 SYSINIT_SEG,0	; Did it get allocated?
	 je	 short @F	; Jump if not

	 mov	 es,SYSINIT_SEG ; Get segment of system initialization table
	 assume  es:nothing	; Tell the assembler about it

	 DOSCALL @RELMEM	; Release it

@@:
	 popf			; Restore (CF significant)

	 REGREST <gs,fs,es,ds,di,si,dx,cx,bx,eax> ; Restore
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing ; Tell the assembler about it
	 sbb	 ax,ax		; AX=-1 if we failed, 0 if success

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

_posinit  endp			; End posinit procedure
	 FPPROC  _posread	; -- Read POS Data for Slot
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

'C' callable routine to read the POS (programable option select) data

posread (slot#, cmos_vals, adapt_vals, adapt_id);

|

POS_STR struc

	 dw	 ?		; Caller's BP
	 dw	 (1+@CodeSize) dup (?) ; Return Address CS:IP or IP
SLOTNO	 db	 ?,?		; Slot #
CMOS_VALS dd	 ?		; Ptr to CMOS values
ADAP_VALS dd	 ?		; Ptr to adapter values
ADAP_ID   dd	 ?		; Ptr to adapter ID

POS_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <si,di,ds,es>	; Save registers

	 push	 seg PGROUP	; Prepare to address PGROUP
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler (*WARNING* SS != DS)

	 mov	 al,[bp].SLOTNO ; Get slot # of the adapter
	 mov	 POS_BLK.POS_SLOT_NO,al ; Save in request block

	 mov	 POS_BLK.RB_RETCODE,0FFFFh ; Set default error code
	 mov	 POS_BLK.RB_FUNC,0Dh ; Function - read adapter POS
				; and write it to I/O ports 100h to 105h

	 mov	 POS_BLK.RB_UNIT,0 ; Must be zero at startup
	 mov	 POS_BLK.RB_RES1,0 ; ...
	 mov	 POS_BLK.RB_RES2,0 ; ...

	 mov	 POS_BLK.POS_RES1,0 ; Must be zero at startup ??? WHY ???
	 mov	 POS_BLK.POS_RES2,0 ; ...
	 mov	 POS_BLK.POS_RES3,0 ; ...
	 mov	 POS_BLK.POS_RES4,0 ; ...

	 mov	 ax,[bp].ADAP_VALS.VOFF ; Get offset of ADAP_VALS
	 mov	 POS_BLK.POS_VEC.VOFF,ax ; Save in request block
	 mov	 ax,[bp].ADAP_VALS.VSEG ; Get segment of ADAP_VALS
	 mov	 POS_BLK.POS_VEC.VSEG,ax ; Save in request block

	 mov	 POS_BLK.POS_ADAPT_ID,-1 ; Zap the adapter ID

SYSPLACE_STR struc

SYSPLACE_DB_VEC dd ?		; Device Block pointer
SYSPLACE_FTT_VEC dd ?		; Function Transfer Table pointer

SYSPLACE_STR ends


SYSCALL_STR struc

	 db	 (size SYSPLACE_STR) dup (?)
	 dd	 ?		; Request block pointer
	 dw	 ?		; Common Data Area segment

SYSCALL_STR ends

	 push	 CDA_SEG	; CDA segment
	 push	 ds		; Request block segment
	 lea	 ax,POS_BLK	; ...		offset
	 push	 ax		; Pass to SYSPARM routine
	 sub	 sp,size SYSPLACE_STR ; Make room for place holders
	 call	 SYSPARM.STARTPTR ; Request ABIOS service
	 add	 sp,size SYSCALL_STR ; Pop our own calling args

	 mov	 ax,POS_BLK.RB_RETCODE ; Check for error conditions

	 cmp	 ax,0C005h	; Check for slot # out of bounds
	 je	 near ptr POSREAD_SAVEID ; Jump if so

	 cmp	 ax,0		; Izit in error?
	 jne	 near ptr POSREAD_EXIT ; Jump if so

	 cmp	 POS_BLK.POS_ADAPT_ID,-1 ; Check adapter id
	 je	 near ptr POSREAD_SAVEID ; Jump if not valid

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

	 mov	 ax,[bp].CMOS_VALS.VOFF ; Get offset of CMOS_VALS
	 mov	 POS_BLK.POS_VEC.VOFF,ax ; Save in request block
	 mov	 ax,[bp].CMOS_VALS.VSEG ; Get segment of CMOS_VALS
	 mov	 POS_BLK.POS_VEC.VSEG,ax ; Save in request block

	 push	 CDA_SEG	; CDA segment
	 push	 ds		; Request block segment
	 lea	 ax,POS_BLK	; ...		offset
	 push	 ax		; Pass to SYSPARM routine
	 sub	 sp,size SYSPLACE_STR ; Make room for place holders
	 call	 SYSPARM.STARTPTR ; Request ABIOS service
	 add	 sp,size SYSCALL_STR ; Pop our own calling args
POSREAD_SAVEID:
	 les	 di,[bp].ADAP_ID ; ES:DI ==> adapter id
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,POS_BLK.POS_ADAPT_ID ; Get adapter id
	 mov	 es:[di].ELO,ax ; Return adapter ID to caller

	 mov	 ax,POS_BLK.RB_RETCODE ; Return error code as result
POSREAD_EXIT:
	 REGREST <es,ds,di,si>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

_posread  endp			; End posread procedure
	 FPPROC  _poswrite	; -- Write POS Data to a Slot
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

'C' callable routine to write the POS (programable option select) data

poswrite (slot#, cmos_vals, adapt_vals, adapt_id)

|

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <si,di,ds,es>	; Save registers

	 push	 seg PGROUP	; Prepare to address PGROUP
	 pop	 ds		; Address it (*WARNING* SS != DS)
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 al,[bp].SLOTNO ; Get slot # of the adapter
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

	 mov	 ax,[bp].CMOS_VALS.VOFF ; Get offset of CMOS_VALS
	 mov	 POS_BLK.POS_VEC.VOFF,ax ; Save in request block
	 mov	 ax,[bp].CMOS_VALS.VSEG ; Get segment of CMOS_VALS
	 mov	 POS_BLK.POS_VEC.VSEG,ax ; Save in request block

	 les	 di,[bp].ADAP_ID ; ES:DI ==> adapter_id
	 assume  es:nothing	; Tell the assembler about it
	 mov	 ax,es:[di]	; Get adapter id
	 mov	 POS_BLK.POS_ADAPT_ID,ax ; Save in request block

	 push	 CDA_SEG	; CDA segment
	 push	 ds		; Request block segment
	 lea	 ax,POS_BLK	; ...		offset
	 push	 ax		; Pass to SYSPARM routine
	 sub	 sp,size SYSPLACE_STR ; Make room for place holders
	 call	 SYSPARM.STARTPTR ; Request ABIOS service
	 add	 sp,size SYSCALL_STR ; Pop our own calling args

	 mov	 ax,POS_BLK.RB_RETCODE ; Return error code as result

	 REGREST <es,ds,di,si>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

_poswrite endp			; End poswrite procedure
	 FPPROC  _nvramcheck	; -- Recompute NVRAM Checksum
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

'C' callable routine to recompute the NVRAM (Non-Volatile RAM) checksum

nvramcheck ()

|

	 REGSAVE <si,di,ds,es>	; Save registers

	 push	 seg PGROUP	; Prepare to address PGROUP
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler

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
	 DOSCALL @GETMEM	; Allocate memory for Function Transfer Table
	 jb	 near ptr NVRAMCHECK_EXIT ; Jump if something went wrong
				; ...with return code in AX

	 mov	 es,ax		; Address the new segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,NVRAM_LID	; Get NVRAM's logical ID
	 mov	 es:[0].RB_LID,ax ; Save in request block

	 mov	 ax,NVRAM_RB_LEN ; Get NVRAM's request block length
	 mov	 es:[0].RB_LEN,ax ; Save in request block

;;;;;;;; mov	 es:[0].RB_RETCODE,-1 ; Set default error code
;;;;;;;; mov	 es:[0].RB_FUNC,0Bh ; Function - Recompute checksum
;;;;;;;;
;;;;;;;; mov	 ax,0		; Flag:  NMI enabled on exit,
;;;;;;;;			;	 RAM type = 64-byte
;;;;;;;; mov	 es:[0].NVRAM_FLAG,ax
;;;;;;;; mov	 es:[52h],ax	; Save in pseudo-location
;;;;;;;;
;;;;;;;; mov	 es:[0].RB_UNIT,0 ; Must be zero at startup
;;;;;;;; mov	 es:[0].RB_RES1,0 ; ...
;;;;;;;; mov	 es:[0].RB_RES2,0 ; ...
;;;;;;;;
;;;;;;;; mov	 es:[0].NVRAM_RES1,0 ; ... ??? WHY ???
;;;;;;;; mov	 es:[0].NVRAM_RES2,0 ; ...
;;;;;;;; mov	 es:[0].NVRAM_RES3,0 ; ...
;;;;;;;; mov	 es:[0].NVRAM_RES4,0 ; ...
;;;;;;;;
;;;;;;;; push	 CDA_SEG	; CDA segment
;;;;;;;; push	 es		; Request block segment
;;;;;;;; xor	 ax,ax		; ...		offset
;;;;;;;; push	 ax		; Pass to SYSPARM routine
;;;;;;;; sub	 sp,size SYSPLACE_STR ; Make room for place holders
;;;;;;;; call	 SYSPARM.STARTPTR ; Request ABIOS service
;;;;;;;; add	 sp,size SYSCALL_STR ; Pop our own calling args
;;;;;;;;
;;;;;;;; mov	 ax,es:[0].RB_RETCODE ; Return error code as result
;;;;;;;;
;;;;;;;; cmp	 ax,0		; Izit OK?
;;;;;;;; jne	 short NVRAMCHECK_RLS ; Jump if not
;;;;;;;;
	 mov	 es:[0].RB_RETCODE,-1 ; Set default error code
	 mov	 es:[0].RB_FUNC,0Bh ; Function - Recompute checksum

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

	 push	 CDA_SEG	; CDA segment
	 push	 es		; Request block segment
	 xor	 ax,ax		; ...		offset
	 push	 ax		; Pass to SYSPARM routine
	 sub	 sp,size SYSPLACE_STR ; Make room for place holders
	 call	 SYSPARM.STARTPTR ; Request ABIOS service
	 add	 sp,size SYSCALL_STR ; Pop our own calling args

	 mov	 ax,es:[0].RB_RETCODE ; Return error code as result
NVRAMCHECK_RLS:
	 push	 ax		; Save for a moment
	 DOSCALL @RELMEM	; Release it
	 pop	 ax		; Restore
NVRAMCHECK_EXIT:
	 REGREST <es,ds,di,si>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

_nvramcheck endp		; End NVRAMCHECK procedure
;;;;;;;  NPPROC  INTOFF ; -- Disable Interrupts
;;;;;;;  assume  ds:DGROUP,es:nothing,ss:nothing
;;;;;;;COMMENT|
;;;;;;;
;;;;;;;Disable interrupts
;;;;;;;
;;;;;;;|
;;;;;;;
;;;;;;;  cli			; Disallow interrupts
;;;;;;;
;;;;;;;  ret			; Return to caller
;;;;;;;
;;;;;;;  assume  ds:nothing,es:nothing,ss:nothing
;;;;;;;
;;;;;;;INTOFF	 endp			; End INTOFF procedure
;;;;;;;  NPPROC  INTON	; -- Enable Interrupts
;;;;;;;  assume  ds:DGROUP,es:nothing,ss:nothing
;;;;;;;COMMENT|
;;;;;;;
;;;;;;;Enable interrupts
;;;;;;;
;;;;;;;|
;;;;;;;
;;;;;;;  sti			; Allow interrupts
;;;;;;;
;;;;;;;  ret			; Return to caller
;;;;;;;
;;;;;;;  assume  ds:nothing,es:nothing,ss:nothing
;;;;;;;
;;;;;;;INTON	 endp			; End INTON procedure
;;;;;;;
INS_POS_TEXT ends		; End CODE segment

	 MEND			; End INS_POS module
