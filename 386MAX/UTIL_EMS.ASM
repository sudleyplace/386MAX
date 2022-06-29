;' $Header:   P:/PVCS/MAX/386MAX/UTIL_EMS.ASV   1.3   08 Jul 1998 12:30:08   BOB  $
	 title	 UTIL_EMS -- 386MAX Utility Program -- Map EMS Action
	 page	 58,122
	 name	 UTIL_EMS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

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
	 include VIDCALL.INC
	 include EMMCALL.INC
	 include EMM2CALL.INC
	 include ASCII.INC
	 include 386.INC
	 include PTR.INC

	 include QMAX_PPM.INC
	 include QMAX_MCS.INC
	 include QMAX_OEM.INC
.list

if @OEM_MAPEMS
PGROUP	 group	 CODE,DATA,NCODE,ZZTAIL


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 EMMSIZE:dword
	 extrn	 NUMBERS_HI:byte

	 public  MCSTAB_CNT2
MCSTAB_CNT2 dw	 ?

	 public  EMMVERS,EMMTOTAL,EMMAVAIL,EMMHACT,EMMFRAME,EMM16S
EMMVERS  db	 ?		; EMM version # in BCD
EMMTOTAL dw	 ?		; Total # pages
EMMAVAIL dw	 ?		; # available pages
EMMHACT  dw	 ?		; # active handles
EMMFRAME dw	 -1		; EMS page frame
EMM16S	 dw	 ?		; # mappable physical pages

	 public  EMMSTATA,MSGHMS,MSGHNDL,MSGMEM
EMMSTATA db	 'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸',CR,LF
ifdef LANG_GR
	 db	 '³                            EMS-SPEICHER-BELEGUNG                            ³',CR,LF
else
	 db	 '³                            EXPANDED MEMORY USAGE                            ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF
ifdef LANG_GR
	 db	 '³       Handle    Gr”áe     Name         EMM-Version '
MSGVERSH db	 'x.'
MSGVERSL db	 'x  Rahmen = '
MSGPGFR  db	 'ohne       ³',CR,LF
	 db	 '³ ÄÄÄÄÄÄÄÄÄÄÄÄ    ÄÄÄÄÄÄ    ÄÄÄÄÄÄÄÄ      '
MSG16S	 db	 '_ abbildbare physikalische Seiten   ³',CR,LF,EOS
else
	 db	 '³       Handle    Memory    Name         EMM Version '
MSGVERSH db	 'x.'
MSGVERSL db	 'x   Frame = '
MSGPGFR  db	 'NONE       ³',CR,LF
	 db	 '³ ÄÄÄÄÄÄÄÄÄÄÄÄ    ÄÄÄÄÄÄ    ÄÄÄÄÄÄÄÄ      '
MSG16S	 db	 '_ Mappable Physical Pages           ³',CR,LF,EOS
endif				; IFDEF LANG_GR
MSGHMS	 db	 '³         '
MSGHNDL  db	 '   _        _'
MSGMEM	 db	 '     '
MSGHNAM  db	 '_                                                 ³',CR,LF
MSGHMS_LEN equ	 $-MSGHMS	; Length of the line

	 public  EMMSTATZ
EMMSTATZ label	 byte
ifdef LANG_GR
	 db	 '³ frei [dynam.]        '
else
	 db	 '³ Avail Shared         '
endif				; IFDEF LANG_GR
MSGAVAIL db	 '                                                       ³',CR,LF
	 db	 '³                  ÄÄÄÄ                                                       ³',CR,LF
ifdef LANG_GR
EMMSTATT db	 '³       gesamt         '
else
EMMSTATT db	 '³        Total         '
endif				; IFDEF LANG_GR
MSGTOTAL db	 ' KB                                                    ³',CR,LF,EOS

	 public  MSG_EMSNONE
ifdef LANG_GR
MSG_EMSNONE db	 'kein EMS-Speicher anzeigbar.',CR,LF,EOS
else
MSG_EMSNONE db	 'No EMS memory to report on.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  PEMMNEXT,PEMMHPAG,PEMMPPM,PPMTAB_LEN
PEMMNEXT dw	 PGROUP:ZTAIL	; Pointer to next available location
PEMMHPAG dw	 ?		; ...	     handle-page table
PEMMPPM  dw	 ?		; ...	     PPMTAB array
PEMMMCS  dw	 ?		; ...	     MCSTAB array
PPMTAB_LEN dw	 ?		; Length of PPMTAB array

	 public  MSG_PPMTAB,MSG_PPMTAB0
ifdef LANG_GR
MSG_PPMTAB db	 'ÆÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍµ  EMS-Seiten  ÆÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍµ',CR,LF
else
MSG_PPMTAB db	 'ÆÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍµ EMS Page Map ÆÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍµ',CR,LF
endif				; IFDEF LANG_GR
	   db	 '³       0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F   1 MB  ³',CR,LF
MSG_PPMTAB0 db	 '³',77 dup (' '),'³',CR,LF,EOS

ifdef LANG_GR
MSG_PPMAVL db	 '³ ? unbelegtÄÄ ',EOS
MSG_PPMCNV db	 '³ ? DOS     ÄÄ ',EOS
MSG_PPMINC db	 '³ ? einschl.ÄÄ ',EOS
MSG_PPMEXC db	 '³ ? ausschl.ÄÄ ',EOS
MSG_PPMFRM db	 '³ ? Rahmen  ÄÄ ',EOS
MSG_PPMRAM db	 '³ ? RAM     ÄÄ ',EOS
MSG_PPMROM db	 '³ ? ROM     ÄÄ ',EOS
MSG_PPMSCR db	 '³ ? Schirm  ÄÄ ',EOS
MSG_PPMBLK db	 '³              ',EOS
else
MSG_PPMAVL db	 '³ ? Unused  ÄÄ ',EOS
MSG_PPMCNV db	 '³ ? DOS     ÄÄ ',EOS
MSG_PPMINC db	 '³ ? Include ÄÄ ',EOS
MSG_PPMEXC db	 '³ ? Exclude ÄÄ ',EOS
MSG_PPMFRM db	 '³ ? Frame   ÄÄ ',EOS
MSG_PPMRAM db	 '³ ? RAM     ÄÄ ',EOS
MSG_PPMROM db	 '³ ? ROM     ÄÄ ',EOS
MSG_PPMSCR db	 '³ ? Screen  ÄÄ ',EOS
MSG_PPMBLK db	 '³              ',EOS
endif				; IFDEF LANG_GR
MSG_PPMLEN equ	 $-MSG_PPMBLK-1 ; Length of typical MSG_PPMxxx

	 public  PPMTAB_XLAT
PPMTAB_XLAT db	 '#'            ; 00 = Available page
	 db	 'Û'            ; 01 = Conventional page
	 db	 '²'            ; 02 = INCLUDEd page
	 db	 '±'            ; 03 = EXCLUDEd page
	 db	 '°'            ; 04 = EMS frame
	 db	 '÷'            ; 05 = SCREEN page
	 db	 'è'            ; 06 = RAM
	 db	 'þ'            ; 07 = ROM

	 public  PPMTAB_TYP
PPMTAB_TYP db	 @PPM_AVL
	 db	 @PPM_CNV
	 db	 @PPM_INC
	 db	 @PPM_EXC
	 db	 @PPM_FRM
	 db	 @PPM_SCR
	 db	 @PPM_RAM
	 db	 @PPM_ROM
NPPMTYP  equ	 $-PPMTAB_TYP	; # PPM types

	 public  MSG_PPMTYP
MSG_PPMTYP dw	 PGROUP:MSG_PPMAVL
	 dw	 PGROUP:MSG_PPMCNV
	 dw	 PGROUP:MSG_PPMINC
	 dw	 PGROUP:MSG_PPMEXC
	 dw	 PGROUP:MSG_PPMFRM
	 dw	 PGROUP:MSG_PPMSCR
	 dw	 PGROUP:MSG_PPMRAM
	 dw	 PGROUP:MSG_PPMROM
	 dw	 PGROUP:MSG_PPMBLK

	 public  MSG_PPMTAIL
MSG_PPMTAIL db	 'Ô',77 dup ('Í'),'¾',CR,LF,EOS

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
	 extrn	 CHECK_LINE:near

NCODE	 ends			; End NCODE segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 DW2HEX:near
	 extrn	 BIN2BASE:near
	 extrn	 CHECK_STATE:near
	 extrn	 WINOUT:near

	 NPPROC  ACT_EMS -- Action To Display EMS Memory Map
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display EMS memory map

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers

; Ensure EMS memory in use

	 cmp	 EMMSIZE,0	; Any in use?
	 je	 near ptr ACT_EMS_NONE ; Not this time

; Ensure we're in AUTO or ON state

	 test	 GLB_FLAG,@GLB_AUTO or @GLB_ON ; Check state
	 jz	 near ptr ACT_EMS_NONE ; Jump if we're OFF

; Get and save EMM version #

	 EMMCALL @EMM_GETVERS	; Get EMM version

	 or	 ah,ah		; Check for error
	 jnz	 near ptr ACT_EMS_ERR ; Something went wrong

	 mov	 EMMVERS,al	; Save it away

; Get total & available # pages

	 EMMCALL @EMM_GETPGCT

	 or	 ah,ah		; Check for error
	 jnz	 near ptr ACT_EMS_ERR ; Something went wrong

	 mov	 EMMAVAIL,bx	; Save for later use
	 mov	 EMMTOTAL,dx

; Get EMM page frame address

	 EMMCALL @EMM_GETPGFR

	 or	 ah,ah		; Check for error
	 jnz	 short ACT_EMS_FRM1 ; Something went wrong

	 mov	 EMMFRAME,bx	; Save for later use
ACT_EMS_FRM1:

; Get EMM handle count

	 EMMCALL @EMM_GETHNCT	; Get handle count into BX

	 or	 ah,ah		; Check for error
	 jnz	 near ptr ACT_EMS_ERR ; Something went wrong

	 mov	 EMMHACT,bx	; Save # active handles

; Get EMM handle-pages

	 mov	 di,PEMMNEXT	; Get pointer to next available byte
	 mov	 PEMMHPAG,di	; ES:DI ==> data area
	 EMMCALL @EMM_GETALPG	; Get all handle-pages into ES:DI

	 or	 ah,ah		; Check for error
	 jnz	 near ptr ACT_EMS_ERR ; Something went wrong

	 mov	 ax,EMMHACT	; Get # active handles
	 shl	 ax,2-0 	; Convert from two words to bytes
	 add	 PEMMNEXT,ax	; Skip over table

; Get # mappable physical pages

	 mov	 al,1		; Subfunction to get # entries
	 EMMCALL @EMM_GETPHYS	; Return count in CX

	 or	 ah,ah		; Check for error
	 jnz	 near ptr ACT_EMS_ERR ; Something went wrong

	 mov	 EMM16S,cx	; Save for later use

; Get MCS table

	 mov	 di,PEMMNEXT	; ES:DI ==> next available byte
	 mov	 PEMMMCS,di	; Save pointer for later use

	 call	 CHECK_STATE	; Attempt to go ON or AUTO active
	 jc	 near ptr ACT_EMS_ERR ; Jump if not successful

	 mov	 ah,@EMM2_GETMCS ; Get MCSTAB array
	 call	 WINOUT 	; Use Windows API or EMMOUT
				; Return with error code in AH

	 and	 ah,ah		; Check for error
	 jnz	 near ptr ACT_EMS_ERR ; Something went wrong

	 mov	 MCSTAB_CNT2,cx  ; Save for later use
	 mov	 ax,size MCS_STR ; Get byte size of structure
	 mul	 cx		; Times # entries
	 add	 PEMMNEXT,ax	; Bump to next available byte

; Get PPMTAB array

	 mov	 di,PEMMNEXT	; ES:DI ==> next available byte
	 mov	 PEMMPPM,di	; Save pointer for later use

	 mov	 ah,@EMM2_GETPPM ; Get PPMTAB array
	 call	 WINOUT 	; Use Windows API or EMMOUT
				; Return with error code in AH

	 and	 ah,ah		; Check for error
	 jnz	 short ACT_EMS_ERR ; Something went wrong

	 mov	 PPMTAB_LEN,cx	; Save for later use
	 add	 PEMMNEXT,cx	; Bump to next available byte

	 EMMCALL @EMM_GETSTAT	; Harmless get status call to go inactive

; Copy over the PPMTAB translate table characters

	 lea	 bx,PPMTAB_XLAT ; DS:BX ==> translate table

	 mov	 al,@PPM_AVL	; Available memory
	 xlat	 PPMTAB_XLAT	; Translate to printable graphic
	 mov	 MSG_PPMAVL[2],al ; Save in message

	 mov	 al,@PPM_CNV	; Conventional memory
	 xlat	 PPMTAB_XLAT	; Translate to printable graphic
	 mov	 MSG_PPMCNV[2],al ; Save in message

	 mov	 al,@PPM_INC	; INCLUDEd memory
	 xlat	 PPMTAB_XLAT	; Translate to printable graphic
	 mov	 MSG_PPMINC[2],al ; Save in message

	 mov	 al,@PPM_EXC	; EXCLUDEd memory
	 xlat	 PPMTAB_XLAT	; Translate to printable graphic
	 mov	 MSG_PPMEXC[2],al ; Save in message

	 mov	 al,@PPM_FRM	; EMS frame memory
	 xlat	 PPMTAB_XLAT	; Translate to printable graphic
	 mov	 MSG_PPMFRM[2],al ; Save in message

	 mov	 al,@PPM_SCR	; SCREEN memory
	 xlat	 PPMTAB_XLAT	; Translate to printable graphic
	 mov	 MSG_PPMSCR[2],al ; Save in message

	 mov	 al,@PPM_RAM	; RAM memory
	 xlat	 PPMTAB_XLAT	; Translate to printable graphic
	 mov	 MSG_PPMRAM[2],al ; Save in message

	 mov	 al,@PPM_ROM	; ROM memory
	 xlat	 PPMTAB_XLAT	; Translate to printable graphic
	 mov	 MSG_PPMROM[2],al ; Save in message

; Format and display the numbers

	 call	 DISP_STATS	; Display the usage statistics
ACT_EMS_CLC:
	 clc			; Indicate all went well

	 jmp	 short ACT_EMS_EXIT ; Join common exit code

ACT_EMS_NONE:
	 lea	 dx,MSG_EMSNONE ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 jmp	 short ACT_EMS_CLC ; Join common code

ACT_EMS_ERR:
	 stc			; Indicate something went wrong
ACT_EMS_EXIT:
	 popa			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_EMS  endp			; End ACT_EMS procedure
	 NPPROC  DISP_STATS -- Display EMM Statistics
	 assume  ds:PGROUP,es:PGROUP,ss:nothing

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save registers

; Format version #

	 lea	 bx,NUMBERS_HI	; DS:BX ==> translate table
	 mov	 al,EMMVERS	; Get version #
	 mov	 cl,4		; Shift amount
	 shl	 ax,cl		; Shift out high-order
	 shr	 al,cl		; Shift back low-order

	 and	 al,0Fh 	; Isolate low-order nibble
	 xlat	 NUMBERS_HI	; Translate to hex
	 mov	 MSGVERSL,al	; Save in message

	 mov	 al,ah		; Copy high-order nibble
	 and	 al,0Fh 	; Isolate low-order nibble
	 xlat	 NUMBERS_HI	; Translate to hex
	 mov	 MSGVERSH,al	; Save in message

; Format the # mappable physical pages

	 mov	 ax,EMM16S	; Get the entry count
	 lea	 di,MSG16S
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert binary AX to base ending at ES:DI

; Compute total amount of expanded memory

	 mov	 ax,EMMTOTAL	; Get total # pages
	 mov	 cl,4		; Shift amount to multiply by 16
	 shl	 ax,cl		; AX has memory in units of 1K
	 lea	 di,MSGTOTAL-1
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert binary AX to base ending at ES:DI

; Format amount of expanded memory available

	 mov	 ax,EMMAVAIL	; Get # pages available
	 mov	 cl,4		; Shift amount to multiply by 16
	 shl	 ax,cl		; AX has memory in units of 1K
	 lea	 di,MSGAVAIL-1
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert binary AX to base ending at ES:DI

; Format page frame address

	 mov	 ax,EMMFRAME	; Get page frame address

	 cmp	 ax,-1		; Check for invalid
	 je	 short DISP_STATS_FRM ; Jump if invalid

	 lea	 di,MSGPGFR	; ES:DI ==> save area
	 call	 DW2HEX 	; Convert binary AX to hex starting at ES:DI
DISP_STATS_FRM:

; Format handle-pages

	 mov	 cx,EMMHACT	; CX = # active handles

; Display title

	 lea	 dx,EMMSTATA	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 mov	 bx,PEMMHPAG	; DS:BX ==> all handle pages table
DISP_STATS_LOOP:
	 push	 cx		; Save for a moment

	 mov	 ax,[bx]	; Get the handle
	 lea	 di,MSGHNDL[3]	; Put it here
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert binary AX to base ending at ES:DI

	 mov	 ax,[bx+2]	; Get # pages
	 mov	 cl,4		; Shift amount to multiply by 16
	 shl	 ax,cl		; AX has memory in units of 1K
	 lea	 di,MSGMEM-1	; Put it here
	 REGSAVE <ax,di>	; Save for a moment
	 mov	 cx,6		; # bytes to clear
	 mov	 al,' '         ; Clear value
	 std			; Store backwards
     rep stosb
	 cld			; Restore direction flag
	 REGREST <di,ax>	; Restore
	 mov	 cx,10		; Convert in decimal
	 call	 BIN2BASE	; Convert binary AX to base ending at ES:DI

; Get the handle name

	 mov	 dx,[bx]	; Get the handle
	 mov	 al,0		; Subfunction to get handle name
	 lea	 di,MSGHNAM	; ES:DI ==> save area
	 EMMCALL @EMM_GETSETNAME ; Return with ES:DI filled in

	 pop	 cx		; Restore

	 add	 bx,4		; Skip to next handle

; Display this handle's statistics

; Because this line displays the handle name and that might contain
; an EOS, we must use standard output rather than @STROUT

	 REGSAVE <ax,bx,cx,dx>	; Save for a moment

; Because the name can contain garbage, we'll launder characters
; below a blank

	 lea	 di,MSGHNAM	; ES:DI ==> handle name
	 mov	 cx,8		; CX = length of ...
DISP_STATS_HNAM:
	 cmp	 es:[di].LO,' ' ; Izit a blank or above?
	 jae	 short @F	; Jump if so

	 mov	 es:[di].LO,' ' ; Zap it
@@:
	 inc	 di		; Skip to next entry

	 loop	 DISP_STATS_HNAM ; Jump if more characters to launder

	 mov	 bx,@STD_OUT	; Send to standard output
	 mov	 cx,MSGHMS_LEN	; Length of the message
	 DOSCALL @WRITF2,MSGHMS ; Display the line
	 call	 CHECK_LINE	; Count in another line and check for pause

	 REGREST <dx,cx,bx,ax>	; Restore

	 loop	 DISP_STATS_LOOP ; Jump if more handles to display

DISP_STATS_TRAIL:

; Display EMM Trailer

	 lea	 dx,EMMSTATZ	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

; Merge MCSTAB and PPMTAB w.r.t. RAM and ROM entries

	 mov	 si,PEMMMCS	; Initialize MCSTAB index
	 mov	 cx,MCSTAB_CNT2 ; CX = # entries in MCSTAB
DISP_STATS_MCSNEXT:
	 mov	 al,@PPM_ROM	; Assume it's ROM

	 test	 [si].MCS_FLAG,@MCS_ROM ; Izit ROM?
	 jnz	 short DISP_STATS_MCS1 ; Yes, set PPMTAB entries

	 mov	 al,@PPM_RAM	; Assume it's RAM

	 test	 [si].MCS_FLAG,@MCS_RAM ; Izit ROM?
	 jz	 short DISP_STATS_MCSLOOP ; No, continue on
DISP_STATS_MCS1:
	 push	 cx		; Save for a moment

	 mov	 di,[si].MCS_PARA ; Get the paragraph #
	 mov	 cx,[si].MCS_NPAR ; Get the # paragraphs
	 add	 cx,di		; Convert from length to end
	 add	 cx,(16*1024/512)-1 ; Round up
	 shr	 cx,14-4	; Convert from paras to 16KB
	 shr	 di,14-4	; Convert from paras to 16KB

	 sub	 cx,di		; Convert from end to length
	 jnc	 short DISP_STATS_MCS2 ; Jump if no overlap

	 neg	 cx		; Negate to account for 1MB wrap
DISP_STATS_MCS2:
	 add	 di,PEMMPPM	; ES:DI ==> this entry in PPMTAB
     rep stosb			; Save in PPMTAB array

	 pop	 cx		; Restore
DISP_STATS_MCSLOOP:
	 add	 si,type MCS_STR ; Skip to next entry

	 loop	 DISP_STATS_MCSNEXT ; Jump if more entries


; Display the PPMTAB

DISP_STATS_PPM:
	 mov	 si,PEMMPPM	; DS:SI ==> PPMTAB array
	 lea	 di,MSG_PPMTAB0[8] ; ES:DI ==> output save area
	 mov	 cx,PPMTAB_LEN	; Get length of array
	 lea	 bx,PPMTAB_XLAT ; DS:BX ==> translate table
DISP_STATS_PPM_NEXT1:
	 lodsb			; Get next PPM character
	 and	 al,not mask $PPM_SHD ; Remove shadow RAM bit
	 mov	 [si-1].LO,al	; Save back
	 xlat	 PPMTAB_XLAT	; Translate into
S16	 stosb			; Save into output area

	 loop	 DISP_STATS_PPM_NEXT1 ; Jump if more entries

	 lea	 dx,MSG_PPMTAB	; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

; Display the PPMTAB legend and range information

	 mov	 cx,NPPMTYP	; CX = # PPMTAB types
	 xor	 si,si		; Initialize index into PPM tables
DISP_STATS_PPM_NEXT2:
	 call	 DISP_PPM	; Display PPM range values
	 inc	 si		; Skip to next index value

	 loop	 DISP_STATS_PPM_NEXT2 ; Jump if more to display
DISP_STATS_XWIN:
	 lea	 dx,MSG_PPMTAIL ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 REGREST <di,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_STATS endp 		; End DISP_STATS procedure
	 NPPROC  DISP_PPM -- Display PPMTAB Range
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

Display the range of addresses (if any) of PPM memory
of type whose index is in SI.

On entry:

SI	 =	 byte index into PPM tables

|

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save registers

	 mov	 cx,PPMTAB_LEN	; Get length of PPMTAB
	 mov	 di,PEMMPPM	; ES:DI ==> PPMTAB
	 lea	 dx,MSG_PPMTAB0[MSG_PPMLEN] ; DX ==> output save area
DISP_PPM_NEXT:
	 jcxz	 DISP_PPM_END	; None remain
	 mov	 al,PPMTAB_TYP[si] ; Get the current type
   repne scasb			; Search for it
	 jne	 short DISP_PPM_END ; That's all folks

	 mov	 bx,di		; Save index of start+1
	 sub	 bx,PEMMPPM	; Convert to origin-1
	 dec	 bx		; Convert to origin-0

	 jcxz	 DISP_PPM1	; Jump if nothing else to find
    repe scasb			; Skip over others of the same value
	 je	 short DISP_PPM1 ; Jump if we found others

	 dec	 di		; Back off to last+1
	 inc	 cx		; Count back in
DISP_PPM1:
	 mov	 ax,bx		; Copy to DW2HEX register
	 shl	 ax,14-4	; Convert from 16KB to paras

	 xchg	 dx,di		; Swap current PPMTAB offset with
				; the current output pointer

	 cmp	 di,offset es:MSG_PPMTAB0[77-9] ; At the end as yet?
	 jb	 short DISP_PPM2 ; Not as yet

	 call	 DISP_PPMLINE	; Display the line
	 mov	 si,NPPMTYP	; Mark next line as not named
	 lea	 di,MSG_PPMTAB0[MSG_PPMLEN] ; DI ==> output save area
DISP_PPM2:
	 call	 DW2HEX 	; Convert binary AX to hex starting at ES:DI
	 mov	 al,'-'         ; Separator
S16	 stosb			; Save in output area

	 mov	 ax,dx		; Copy offset of last+1
	 sub	 ax,PEMMPPM	; Convert to origin-1

	 shl	 ax,14-4	; Convert from 16KB to paras
	 jnz	 short DISP_PPM3 ; Jump if not 1MB

	 push	 ax		; Save for a moment
	 mov	 al,'1'         ; 1MB marker
S16	 stosb			; Save in output area
	 pop	 ax		; Restore
DISP_PPM3:
	 call	 DW2HEX 	; Convert binary AX to hex starting at ES:DI
	 mov	 al,' '         ; Separator
S16	 stosb			; Save in output area
	 mov	 al,' '         ; Separator
S16	 stosb			; Save in output area

	 xchg	 dx,di		; Swap back

	 jmp	 short DISP_PPM_NEXT ; Go around again

DISP_PPM_END:
	 cmp	 dx,offset ds:MSG_PPMTAB0[MSG_PPMLEN] ; Any output?
	 je	 short DISP_PPM_EXIT ; Not for this one

	 mov	 di,dx		; ES:DI ==> next available byte
	 call	 DISP_PPMLINE	; Display the line
DISP_PPM_EXIT:
	 REGREST <di,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_PPM endp			; End DISP_PPM procedure
	 NPPROC  DISP_PPMLINE -- Display A PPMTAB Line
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

On entry:

SI	 =	 byte index into PPM tables
ES:DI	 ==>	 next available output byte

|

	 REGSAVE <ax,cx,dx,di>	; Save registers

	 lea	 cx,MSG_PPMTAB0[78] ; Point to end of the line

	 sub	 cx,di		; Less current location
	 jb	 short DISP_PPM_END1 ; Nothing remains

	 mov	 al,' '         ; Fill with blanks
     rep stosb			; Smear 'em
DISP_PPM_END1:
	 shl	 si,1		; Times two to index table of words
	 mov	 dx,MSG_PPMTYP[si] ; DS:DX ==> initial message
	 shr	 si,1		; Restore
	 call	 STROUT 	; Display string at DS:DX

	 lea	 dx,MSG_PPMTAB0[MSG_PPMLEN] ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 REGREST <di,dx,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_PPMLINE endp		; End DISP_PPMLINE procedure

CODE	 ends			; End CODE segment
endif				; IF @OEM_MAPEMS

	 MEND			; End UTIL_EMS module
