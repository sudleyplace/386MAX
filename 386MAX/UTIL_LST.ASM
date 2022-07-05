;' $Header:   P:/PVCS/MAX/386MAX/UTIL_LST.ASV   1.3   08 Jul 1998 12:30:08   BOB  $
	 title	 UTIL_LST -- 386MAX Utility Program -- LIST Action
	 page	 58,122
	 name	 UTIL_LST

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Tail    segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Program derived from:  None.

Original code by:  Bob Smith, April, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include MAC.INC
	 include EMMCALL.INC
	 include EMM2CALL.INC
	 include 386.INC
	 include PTR.INC

	 include QMAX_MAP.INC
	 include QMAX_MCS.INC
	 include QMAX_OEM.INC
.list

if @OEM_LIST
PGROUP	 group	 CODE,DATA,NCODE,ZZTAIL


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 INFO_CTL:byte
	 include QMAX_CTL.INC

	 extrn	 EMMSIZE:dword
if @OEM_SYS eq @OEMSYS_ILIM

	 public  MSG_STA
ifdef LANG_GR
MSG_STA  db	 ', wovon ',CR,LF,CR,LF
else
MSG_STA  db	 ', of which:',CR,LF,CR,LF
endif				; IFDEF LANG_GR
	 db	 '                 '
ifdef LANG_GR
MSG_XAVL db	 'KB frei sind fr EMS-Speicher-Anwendungen,',CR,LF
else
MSG_XAVL db	 'K bytes are free for use by expanded memory applications',CR,LF
endif				; IFDEF LANG_GR
	 db	 '                 '
ifdef LANG_GR
MSG_XUSE db	 'KB von EMS-Speicher-Anwendungen belegt sind,',CR,LF
else
MSG_XUSE db	 'K bytes are being used by expanded memory applications',CR,LF
endif				; IFDEF LANG_GR
	 db	 EOS
MSG_STA_LEN equ  $-MSG_STA	; Length of message
else

if @OEM_HILOAD
	 extrn	 MSG_RUNHI:byte
;;;;;;;; extrn	 MSG_RUNLO:byte

	 extrn	 MSG_AVAIL:byte
	 extrn	 MSG_AVAIL1:byte

	 extrn	 MSG_BLK:byte
	 extrn	 MSG_BLK1:byte
	 extrn	 MSG_DOT:byte
endif				; IF @OEM_HILOAD

	 extrn	 MAPSIZE:word
	 extrn	 PRGSIZE:word
	 extrn	 EXTSIZE:dword
	 extrn	 OVRSIZE:word
	 extrn	 LOWSIZE:word
	 extrn	 SHDSIZE:word
	 extrn	 XSHDSIZE:word
	 extrn	 OWNER:word

	 extrn	 POVR_MAC:word

	 extrn	 MSG_LIST:byte
	 extrn	 MSG_CRLF:byte

	 extrn	 MSG_PRG:byte,MSG_PRG1:byte
	 extrn	 MSG_MAP:byte,MSG_MAP1:byte,MSG_MAP2:byte

if @OEM_HIFILL
	 extrn	 MSG_OVR:byte,MSG_OVR1:byte,MSG_OVR2:byte
endif				; IF @OEM_HIFILL

	 extrn	 MSG_LOW:byte,MSG_LOW1:byte
	 extrn	 MSG_EMM:byte,MSG_EMM1:byte
	 extrn	 MSG_EXT:byte,MSG_EXT1:byte
	 extrn	 MSG_TOT:byte,MSG_TOT1:byte
	 extrn	 MSG_SHD:byte,MSG_SHD1:byte

if @OEM_EMSLIST
	 extrn	 MSG_EXP:byte,MSG_EXP1:byte
	 extrn	 MSG_EXPINUSE:byte
	 extrn	 MSG_EXPAVAIL:byte
endif				; IF @OEM_EMSLIST

	 public  EXP_TOTAL,EXP_AVAIL,EXP_INUSE
EXP_TOTAL dw	 0		; Total EMS memory in 1KB
EXP_AVAIL dw	 0		; Available ...
EXP_INUSE dw	 0		; In use ...

	 public  PMAPTAB,MAPTAB_CNT
PMAPTAB  dw	 PGROUP:ZTAIL	; Ptr to MAPTAB
MAPTAB_CNT dw	 ?		; # MAPTAB entries

if @OEM_HIFILL or @OEM_ROMSCAN
	 public  PMCSTAB,MCSTAB_CNT
PMCSTAB  dw	 ?		; Ptr to MCSTAB
MCSTAB_CNT dw	 ?		; # MCSTAB entries
endif				; IF @OEM_HIFILL or @OEM_ROMSCAN
endif				; IF @OEM_SYS eq @OEMSYS_ILIM

DATA	 ends			; End DATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

ZZTAIL	 segment use16 dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 extrn	 ZTAIL:byte

ZZTAIL	 ends			; End ZZTAIL segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 STROUT:near
	 extrn	 CHECK_INFO:near

NCODE	 ends			; End NCODE segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 INFO_READ:near
	 extrn	 BIN2BASE:near
	 extrn	 BIND2BASE:near
	 extrn	 DW2HEX:near
	 extrn	 WINOUT:near

if @OEM_SYS ne @OEMSYS_ILIM
	 extrn	 SEND_CMD:near
	 extrn	 CHECK_STATE:near
	 extrn	 DISP_STATE:near
endif				; IF @OEM_SYS ne @OEMSYS_ILIM

if @OEM_SYS eq @OEMSYS_AST386
	 extrn	 DISP_COLOR:near
endif				; IF @OEM_SYS eq @OEMSYS_AST386

if @OEM_WTK
	 extrn	 DISP_WTK:near
endif				; IF @OEM_WTK

	 NPPROC  ACT_LIST -- Action To List 386MAX Memory Usage
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

List 386MAX Virtual 8086 mode monitor memory usage.

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers

	 call	 CHECK_INFO	; Check and display IDN info
	 jc	 near ptr ACT_LIST_ERR ; Something went wrong

if @OEM_SYS ne @OEMSYS_HPRS

if @OEM_SYS ne @OEMSYS_ILIM
	 mov	 bx,GLB_FLAG	; Save current global flag
	 and	 bx,@GLB_AUTO or @GLB_ON ; Isolate flags

	 call	 CHECK_STATE	; Attempt to go ON or AUTO active
	 jc	 near ptr ACT_LIST_ERR ; Jump if not successful
endif				; IF @OEM_SYS ne @OEMSYS_ILIM

	 lea	 di,ZTAIL	; ES:DI ==> end of our data area
	 mov	 cx,-1		; CX = maximum length
	 mov	 ah,@EMM2_GETTEXT ; Set function code
	 call	 WINOUT 	; Use Windows API or EMMOUT
				; Return with error code in AH

	 and	 ah,ah		; Check return code
	 jnz	 near ptr ACT_LIST_ERR ; Something went wrong

if @OEM_SYS eq @OEMSYS_AST386
	 push	 offset ds:ZTAIL ; Pass offset of string
	 call	 DISP_COLOR	; Display string in color
else
if @OEM_SYS eq @OEMSYS_ILIM
	 REGSAVE <bx>		; Save for a moment

	 cmp	 EMMSIZE,0	; Any EMS memory to manage?
	 je	 short ACT_LIST_FMT0  ; Not this time

	 EMMCALL @EMM_GETPGCT	; Get page counts, BX = unallocated, DX = total

	 or	 ah,ah		; Check for error return
	 jnz	 short ACT_LIST_FMT0  ; Something went wrong, call them both zero

	 movzx	 ebx,bx 	; Zero to use as dword
	 shl	 ebx,14-10	; Convert from 16KB to 1KB
	 mov	 cx,10		; Convert in decimal

	 mov	 eax,EMMSIZE	; Get amount of EMS memory
	 sub	 eax,ebx	; Less amount of available EMS memory
	 lea	 di,MSG_XUSE-1	; ES:DI ==> units digit in message
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 mov	 ax,bx		; Get amount of available EMS memory
	 lea	 di,MSG_XAVL-1	; ES:DI ==> units digit in message
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

; Search for the EOS and back it up over the preceding CR,LF

	 mov	 cx,-1		; We know it's there
	 mov	 al,EOS 	; Search value
	 lea	 di,ZTAIL	; ES:DI ==> end of our data area
   repne scasb			; Search for it
	 sub	 di,3		; Back off over trailing CR,LF,EOS

	 lea	 si,MSG_STA	; DS:SI ==> local statistics message
	 mov	 cx,MSG_STA_LEN ; Length of ...
S16  rep movsb			; Copy to end of global statistics message
ACT_LIST_FMT0:
	 REGREST <bx>		; Restore
endif				; IF @OEM_SYS eq @OEMSYS_ILIM
	 lea	 dx,ZTAIL	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX
endif				; IF @OEM_SYS eq @OEMSYS_AST386

if @OEM_SYS ne @OEMSYS_ILIM

	 mov	 di,PMAPTAB	; ES:DI ==> save area for MAPTAB
	 mov	 ah,@EMM2_GETMAP ; Set function code
	 call	 WINOUT 	; Use Windows API or EMMOUT
				; Return with error code in AH

	 and	 ah,ah		; Check return code
	 jnz	 near ptr ACT_LIST_ERR ; Something went wrong

	 mov	 MAPTAB_CNT,cx	; Save for later use

if @OEM_HIFILL
	 mov	 ax,size MAP_STR ; Get size of structure
	 mul	 cx		; Times # entries
	 add	 ax,PMAPTAB	; Plus start of MAPTAB
	 mov	 PMCSTAB,ax	; Save as start of MCSTAB

	 mov	 di,PMCSTAB	; ES:DI ==> save area for MCSTAB
	 mov	 ah,@EMM2_GETMCS ; Set function code
	 call	 WINOUT 	; Use Windows API or EMMOUT
				; Return with error code in AH

	 and	 ah,ah		; Check return code
	 jnz	 near ptr ACT_LIST_ERR ; Jump if something went wrong

	 mov	 MCSTAB_CNT,cx	; Save for later use
endif				; IF @OEM_HIFILL

; Return to the previous state in BX

	 test	 bx,@GLB_ON	; Were we ON before?
	 jnz	 short @F	; Yes, stay that way

	 call	 INFO_READ	; Read in INFO structure
				; to get current GLB_FLAG

	 mov	 INFO_CTL,@CTL_OFF ; Mark as state OFF
	 call	 SEND_CMD	; Attempt to set state

	 call	 INFO_READ	; Read in INFO structure
				; to reset flags
@@:
	 cmp	 MAPSIZE,0	; Any ROM mapping to display?
	 je	 short @F	; Not this time

; Loop through MAPTAB to find any ROMs

	 call	 LIST_ROM	; List ROM mapping region
@@:

; Get expanded memory usage if EMS driver installed

	 cmp	 EMMSIZE,0	; Any EMS memory to manage?
	 je	 short ACT_LIST_FMT1  ; Not this time

	 EMMCALL @EMM_GETPGCT	; Get page counts, BX = unallocated, DX = total

	 or	 ah,ah		; Check for error return
	 jnz	 short ACT_LIST_FMT1  ; Something went wrong, call them both zero

	 shl	 bx,14-10	; Convert from 16KB to 1KB
	 mov	 EXP_AVAIL,bx	; Save as available 1KB
	 shl	 dx,14-10	; Convert from 16KB to 1KB
	 mov	 EXP_TOTAL,dx	; Save as total 1KB
	 sub	 dx,bx		; Difference is amount in use
	 mov	 EXP_INUSE,dx	; Save as in use 1KB
ACT_LIST_FMT1:
	 lea	 dx,MSG_LIST	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX

	 mov	 cx,10		; Convert in decimal

	 mov	 ax,PRGSIZE	; Get total memory manager size
	 lea	 di,MSG_PRG1[5] ; ES:DI ==> units digit in message
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 lea	 dx,MSG_PRG	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX

if @OEM_SYS eq @OEMSYS_ILIM
	 test	 SYS_FLAG,@SYS_INBRDPC ; Izit Inboard/PC?
	 jnz	 short	ACT_LIST_INBRDPC1 ; Yes, skip MAPSIZE display
endif				; IF @OEM_SYS eq @OEMSYS_ILIM
	 mov	 ax,MAPSIZE	; Get size of BIOS mapping region
	 lea	 di,MSG_MAP1[5] ; ES:DI ==> units digit in message
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 lea	 dx,MSG_MAP	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX
ACT_LIST_INBRDPC1:

if @OEM_HIFILL
	 mov	 ax,OVRSIZE	; Get high DOS memory
	 lea	 di,MSG_OVR1[5] ; ES:DI ==> units digit in message
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 and	 ax,ax		; Any high DOS memory?
	 jz	 short @F	; Not this time

	 call	 LIST_HIGH	; List the high DOS memory
@@:
	 lea	 dx,MSG_OVR	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX
endif				; IF @OEM_HIFILL

if @OEM_SYS eq @OEMSYS_ILIM
	 test	 SYS_FLAG,@SYS_INBRDPC ; Izit Inboard/PC?
	 jnz	 short	ACT_LIST_INBRDPC2 ; Yes, skip LOWSIZE display
endif				; IF @OEM_SYS eq @OEMSYS_ILIM
	 mov	 ax,LOWSIZE	; Get amount added in low DOS memory

	 cmp	 ax,0		; Check the sign
	 jge	 short @F	; Jump if non-negative fill

	 neg	 ax		; Display the negative
@@:
	 lea	 di,MSG_LOW1[5] ; ES:DI ==> units digit in message
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 cmp	 LOWSIZE,0	; Check the sign
	 jge	 short @F	; Jump if non-negative fill

	 mov	 es:[di].LO,'-' ; Fill in the sign
@@:
	 lea	 dx,MSG_LOW	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX
ACT_LIST_INBRDPC2:
	 mov	 eax,EMMSIZE	; Get size of EMS memory
	 lea	 di,MSG_EMM1[5] ; ES:DI ==> units digit in message
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 lea	 dx,MSG_EMM	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX

	 mov	 eax,EXTSIZE	; Get size of remaining extended memory
	 lea	 di,MSG_EXT1[5] ; ES:DI ==> units digit in message
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 lea	 dx,MSG_EXT	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX

	 movzx	 eax,MAPSIZE	; Get size of ROM mamping region
	 add	 ax,PRGSIZE	; Plus size of program storage
	 add	 ax,OVRSIZE	; ...	       high DOS memory fill
	 add	 eax,EMMSIZE	; ...	       EMS memory
	 add	 eax,EXTSIZE	; ...	       extended memory

	 cmp	 LOWSIZE,0	; Check the sign
	 jle	 short @F	; Jump if it doesn't contribute to the usage

	 movzx	 ebx,LOWSIZE	; Get  ...     low  DOS memory fill
	 add	 eax,ebx	; Plus ...
@@:
	 lea	 di,MSG_TOT1[5] ; ES:DI ==> units digit in message
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 push	 ax		; Save for a moment
	 lea	 dx,MSG_TOT	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX
	 pop	 ax		; Restore

	 movzx	 ebx,SHDSIZE	; Get size of shadow RAM (if any)
	 sub	 bx,XSHDSIZE	; Less extra to install

	 cmp	 ebx,eax	; Use the smaller
	 jae	 short @F	; Jump if AX is smaller

	 mov	 eax,ebx	; Use total size
@@:
	 and	 eax,eax	; Is there any?
	 jz	 short @F	; Not this time

	 lea	 di,MSG_SHD1[5] ; ES:DI ==> units digit in message
	 call	 BIND2BASE	; Convert EAX to ASCII ending at ES:DI

	 lea	 dx,MSG_SHD	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX
@@:
	 lea	 dx,MSG_CRLF	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX

if @OEM_EMSLIST
	 mov	 ax,EXP_TOTAL	; Get total expanded memory
	 lea	 di,MSG_EXP1[5] ; ES:DI ==> units digit in message
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 mov	 ax,EXP_AVAIL	; Get size of available EMS memory
	 lea	 di,MSG_EXPAVAIL[3] ; ES:DI ==> units digit in message
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 mov	 ax,EXP_INUSE	; Get size of in use EMS memory
	 lea	 di,MSG_EXPINUSE[3] ; ES:DI ==> units digit in message
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 lea	 dx,MSG_EXP	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX
endif				; if @OEM_EMSLIST

if @OEM_HILOAD
	 call	 DISPMEM	; Display memory allocation status
endif				; IF @OEM_HILOAD

endif				; IF @OEM_SYS ne @OEMSYS_ILIM
endif				; IF @OEM_SYS ne @OEMSYS_HPRS

if @OEM_SYS ne @OEMSYS_ILIM
	 call	 DISP_STATE	; Display the current state
endif				; IF @OEM_SYS ne @OEMSYS_ILIM

if @OEM_WTK
	 call	 DISP_WTK	; Display the Weitek state, if present
endif				; IF @OEM_WTK

	 clc			; Indicate all went well

	 jmp	 short ACT_LIST_EXIT ; Join common exit code

ACT_LIST_ERR:
	 stc			; Indicate something went wrong
ACT_LIST_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_LIST endp			; End ACT_LIST procedure
if @OEM_SYS ne @OEMSYS_ILIM
	 NPPROC  LIST_ROM -- List ROM Mapping Regions
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

List ROM mapping regions.

|

	 REGSAVE <ax,cx,si,di>	; Save registers

	 mov	 si,PMAPTAB	; DS:SI ==> memory chain structure
	 lea	 di,MSG_MAP2	; ES:DI ==> output area
	 mov	 cx,MAPTAB_CNT	; CX = # entries
LIST_ROM_NEXT:
	 test	 [si].MAP_FLAG,@MAP_ROM ; Izit ROM?
	 jz	 short LIST_ROM_NOROM ; Not this one

	 test	 [si].MAP_FLAG,@MAP_SWAP ; Izit subject to swapping?
	 jz	 short LIST_ROM_NOROM ; Not this one

	 test	 [si].MAP_FLAG,@MAP_CHOP ; Izit chopped?
	 jz	 short LIST_ROM_ROM_NOCHOP ; Not this one

	 add	 [si].MAP_LEN,4*1024/16 ; Add back in the 4KB chopped out
LIST_ROM_ROM_NOCHOP:
	 cmp	 [si].MAP_LEN,0 ; Any paras in entry?
	 je	 short LIST_ROM_NOROM ; Not this one

	 mov	 ax,' ,'        ; Separator
S16	 stosw			; Save in output area

	 push	 cx		; Save for a moment

	 mov	 ax,[si].MAP_PARA_DST ; Get starting paragraph
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 push	 ax		; Save for a moment
	 mov	 al,'-'         ; Separator
S16	 stosb			; Save in otuput area
	 pop	 ax		; Restore

	 add	 ax,[si].MAP_LEN ; Get # paras in entry
	 jnc	 short LIST_ROM_ROM1 ; Jump if no 1MB

	 push	 ax		; Save for a moment
	 mov	 al,'1'         ; 1MB marker
S16	 stosb			; Save in output area
	 pop	 ax		; Restore
LIST_ROM_ROM1:
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 pop	 cx		; Restore
LIST_ROM_NOROM:
	 add	 si,size MAP_STR ; Skip to next entry

	 loop	 LIST_ROM_NEXT	; Jump if more to test

	 mov	 al,CR		; Line ending
S16	 stosb
	 mov	 al,LF		; Line ending
S16	 stosb
	 mov	 al,EOS 	; String ending
S16	 stosb

	 REGREST <di,si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LIST_ROM endp			; End LIST_ROM procedure
endif				; IF @OEM_SYS ne @OEMSYS_ILIM
if @OEM_HIFILL
	 NPPROC  LIST_HIGH -- List High DOS Memory
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

List high DOS memory areas.

|

	 REGSAVE <ax,cx,si,di>	; Save registers

	 mov	 si,PMCSTAB	; DS:SI ==> memory chain structure
	 lea	 di,MSG_OVR2	; ES:DI ==> output area
	 mov	 cx,MCSTAB_CNT	; CX = # entries in MCSTAB
LIST_HIGH1:
	 test	 ds:[si].MCS_FLAG,@MCS_HOLE ; Izit a hole (end of the chain)?
	 jnz	 short LIST_HIGH_EXIT ; Yes, skip out

	 test	 ds:[si].MCS_FLAG,@MCS_AVAIL ; Izit available?
	 jz	 short LIST_HIGH_LOOP ; No, skip it

	 mov	 ax,' ,'        ; Separator
S16	 stosw			; Save in output area

	 mov	 ax,ds:[si].MCS_PARA ; Get paragraph #
	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 push	 ax		; Save for a moment
	 mov	 al,'-'         ; Separator
S16	 stosb			; Save in output area
	 pop	 ax		; Restore

	 add	 ax,ds:[si].MCS_NPAR ; Plus # paragraphs
	 call	 DW2HEX 	; Convert AX to hex at ES:DI
LIST_HIGH_LOOP:
	 add	 si,size MCS_STR ; Skip to next entry

	 loop	 LIST_HIGH1	; Jump if more entries
LIST_HIGH_EXIT:
	 mov	 al,CR		; Line ending
S16	 stosb
	 mov	 al,LF		; Line ending
S16	 stosb
	 mov	 al,EOS 	; String ending
S16	 stosb

	 REGREST <di,si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LIST_HIGH endp			; End LIST_HIGH procedure
endif				; IF @OEM_HIFILL
if @OEM_HILOAD
	 NPPROC  DISPMEM -- Display Memory Allocation Status
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display memory allocation status.

|

	 REGSAVE <ax,bx,cx,dx,di,es> ; Save registers

	 test	 CMD_FLAG,@CMD_XHI ; NOHIGH specified?
	 jnz	 near ptr DISPMEM_EXIT ; Yes, avoid displaying any information

	 cmp	 OWNER,0	; Any previous owner?
	 je	 short DISPMEM_LOW ; No, so we're running in low memory

; We are running in high memory

	 lea	 dx,MSG_RUNHI	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX

	 jmp	 short DISPMEM_COM ; Join common display code

DISPMEM_LOW:

; We are running in low memory
;;;;;;;;
;;;;;;;; lea	 dx,MSG_RUNLO	; DS:DX ==> string to display
;;;;;;;; call	 STROUT 	; Display the string at DS:DX
;;;;;;;;
; Calculate size of high DOS memory
; Search through high memory allocation chain entries for free ones

DISPMEM_COM:
	 mov	 es,POVR_MAC	; ES:0 ==> first MAC in high memory
	 assume  es:nothing	; Tell the assembler about it

	 xor	 dx,dx		; Zero accumulator
	 xor	 di,di		; Zero largest block size
	 mov	 bx,cs		; Get our own segment
DISPMEM_NEXT:
	 cmp	 bx,es:[0].MAC_OWNR ; Check for our own entries
	 je	 short DISPMEM_AVAIL ; Mark it as available

	 cmp	 es:[0].MAC_OWNR,@MAC_FREE ; Check for available
	 jne	 short DISPMEM_INUSE ; Not this one
DISPMEM_AVAIL:
	 mov	 ax,es:[0].MAC_NPAR ; Get its size in paras
	 add	 dx,ax		; Add it into total

	 cmp	 ax,di		; Check against largest block so far
	 jbe	 short DISPMEM_INUSE ; It's no larger

	 mov	 di,ax		; Copy as largest block so far
DISPMEM_INUSE:

; Ensure we are where we think we should be

	 cmp	 es:[0].MAC_TYPE,'Z' ; Maybe it's the last entry
	 je	 short DISPMEM_END ; It is, so that's the end of the chain

	 cmp	 es:[0].MAC_TYPE,'M' ; Maybe it's a middle entry
	 jne	 short DISPMEM_ERRMAC ; Not this time

	 mov	 ax,es		; Copy current segment
	 inc	 ax		; Count in MAC paragraph
	 add	 ax,es:[0].MAC_NPAR ; Add in # paragraphs in this entry
	 mov	 es,ax		; Point to next entry
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 DISPMEM_NEXT ; Go around again

DISPMEM_END:
	 mov	 bx,di		; Copy to unused register

; DX = # paras in high memory segment
; BX = # paras in largest block

	 mov	 ax,dx		; Copy size of high memory block
	 add	 ax,1024/16-1	; Round up to 1KB boundary
	 shr	 ax,10-4	; Convert from paras to 1KB

	 lea	 di,MSG_AVAIL1-1 ; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 push	 dx		; Save for a moment
	 lea	 dx,MSG_AVAIL	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX
	 pop	 dx		; Restore

	 cmp	 bx,dx		; Check against largest block
	 je	 short DISPMEM_DOT ; Jump if no fragmentation

	 mov	 ax,bx		; Copy size of largest high memory block
	 shr	 ax,10-4	; Convert from paras to 1KB, rounding down

	 lea	 di,MSG_BLK1-1	; ES:DI ==> units digit in message
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

	 lea	 dx,MSG_BLK	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX
DISPMEM_DOT:
	 lea	 dx,MSG_DOT	; DS:DX ==> string to display
	 call	 STROUT 	; Display the string at DS:DX
DISPMEM_ERRMAC:
DISPMEM_EXIT:
	 REGREST <es,di,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISPMEM  endp			; End DISPMEM procedure
endif				; IF @OEM_HILOAD

CODE	 ends			; End CODE segment
endif				; IF @OEM_LIST

	 MEND			; End UTIL_LST module
