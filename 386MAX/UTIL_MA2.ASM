; $Header:   P:/PVCS/MAX/386MAX/UTIL_MA2.ASV   1.3   08 Jul 1998 12:30:10   BOB  $
	 title	 UTIL_MA2 -- 386MAX/MOVEIT Memory Map Display
	 page	 58,122
	 name	 UTIL_MA2

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Program segment UCODE,	byte-aligned,  public, class 'ucode'
	       Data    segment UDATA,	dword-aligned, public, class 'udata'

Program derived from:  None.

Original code by:  Bob Smith, March 1988.

Modifications by:  None.

|

.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include KEYCALL.INC
	 include MAC.INC
	 include BITFLAGS.INC
	 include PTR.INC
	 include DEVDRV.INC
	 include INTVEC.INC
	 include IOCTL.INC
	 include EMM2CALL.INC

	 include COMM_OEM.INC	; QMAX_OEM.INC or LOAD_OEM.INC
	 include LOAD_SEG.INC
	 include UTIL_OPT.INC	; Defines @SUBSID_TXT
.list

if @OEM_MAPMEM
PGROUP	 group	 CODE,DATA,NCODE,NDATA,UCODE,UDATA
elseif @OEM_TIMEMEM or @OEM_ROMSCAN or @OEM_MAPEMS
PGROUP	 group	 CODE,DATA
endif				; IF @OEM_MAPMEM


if @OEM_MAPMEM or @OEM_TIMEMEM or @OEM_ROMSCAN or @OEM_MAPEMS or @OEM_MAPDEV
DATA	 segment dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 UTL_FLAG:word
	 include QMAX_UTL.INC

	 extrn	 P1ST_MAC:dword

DATA	 ends			; End DATA segment


CODE	 segment byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 PSP_ENVIR_PTR:word
	 extrn	 PSP_CTRL_PSP:word
	 extrn	 CHECK_LINE:near

CODE	 ends			; End CODE segment
endif				; IF @OEM_MAPMEM or @OEM_TIMEMEM or @OEM_ROMSCAN or @OEM_MAPEMS or @OEM_MAPDEV


if @OEM_MAPMEM
NDATA	 segment dword public 'ndata' ; Start NDATA segment
	 assume  cs:PGROUP

	 extrn	 DOSVER:word

NDATA	 ends			; End NDATA segment


UDATA	 segment dword public 'udata' ; Start UDATA segment
	 assume  cs:PGROUP

	 extrn	 POVR_MAC:word

if @OEM_HARPO
	 public  MSG_UNKSUB
MSG_UNKSUB  db	 @SUBSID_TXT	; Blank filler for MAPMEM display
endif				; IF @OEM_HARPO

	 public  IGN_PSP
	 public  MAPENV,CURMAC,CUROWNR,CURNPAR,CURTYPE,CURMDRV,CURENV
	 public  CURDEV_VEC
IGN_PSP  dw	 0		; PSP to ignore
MAPENV	 dw	 0		; Our own environment segment
CURMAC	 dw	 ?		; Segment of current MAC entry
CUROWNR  dw	 ?		; MAC_OWNR of CURMAC
CURNPAR  dw	 ?		; MAC_NPAR of CURMAC
CURTYPE  db	 ?		; MAC_TYPE of CURMAC
CURMDRV  db	 ?		; MAC_DRV  of CURMAC
CURENV	 dw	 ?		; Segment of current environment
CURDEV_VEC dd	 -1		; Pointer to current device driver header

	 public  CMDCOM_VEC,CMDCOM_LEN
CMDCOM_VEC dd	 ?		; Pointer to name of COMMAND.COM
CMDCOM_LEN dw	 ?		; Length of ...

	 public  MAC_LO,MAC_HI
MAC_LO	 dw	 ?		; MAC low paragraph
MAC_HI	 dw	 ?		; ... high ...

	 public  IND_DRVRS,PTR_DRVRS
IND_DRVRS dw	 ?		; Index into PTR_DRVRS
PTR_DRVRS dw	 PGROUP:MSG_DRVRS ; Pointer to first device driver message
	 dw	 PGROUP:MSG_DRVRS ; ...        last ...

	 public  INT_OFF,INT_CNT,INT_MAX
INT_OFF  dw	 ?		; Offset into interrupt vector table
INT_CNT  dw	 ?		; # remaining interrupt vectors to check
INT_MAX  db	 ?		; Maximum # interrupts displayed per line

	 public  LSEGFLAG
LSEGFLAG db	 ?		; 1 = MAC entry is an LSEG, 0 = not

	 public  MSG_CR,MSG_CRLEN
MSG_CR	 db	 CR
MSG_CRLEN equ	 $-MSG_CR

	 public  MSG_DOS
MSG_DOS  db	 'DOS'          ; Name for DOS region
MSG_DOS_LEN equ  $-MSG_DOS	; ...and its length

	 public  MSG_DRVRS
ifdef LANG_GR
MSG_DRVRS db	 'Einh.Treiber' ; Name for device driver region
else
MSG_DRVRS db	 'Device Drvrs' ; Name for device driver region
endif				; IFDEF LANG_GR
MSG_DRVRS_LEN equ $-MSG_DRVRS	; ...and its length

	 public  MSG_BEGDRVRS
ifdef LANG_GR
MSG_BEGDRVRS db  'Treiber-Anf.' ; Name for start of device driver region
else
MSG_BEGDRVRS db  'Driver Start' ; Name for start of device driver region
endif				; IFDEF LANG_GR
MSG_BEGDRVRS_LEN equ $-MSG_BEGDRVRS ; ...and its length

	 public  MSG_ENDDRVRS
ifdef LANG_GR
MSG_ENDDRVRS db  'Treiber-Ende' ; Name for end of device driver region
else
MSG_ENDDRVRS db  'Driver End  ' ; Name for end of device driver region
endif				; IFDEF LANG_GR
MSG_ENDDRVRS_LEN equ $-MSG_ENDDRVRS ; ...and its length

	 public  MSG_AVL
ifdef LANG_GR
MSG_AVL  db	 '-verfgbar-'  ; Name for available region
else
MSG_AVL  db	 '-Available-'  ; Name for available region
endif				; IFDEF LANG_GR
MSG_AVL_LEN equ  $-MSG_AVL	; ...and its length

	 public  MSG_BLKDD
ifdef LANG_GR
MSG_BLKDD db	 'Laufwerk'     ; In case a block device is in high DOS memory
else
MSG_BLKDD db	 'Drive '       ; In case a block device is in high DOS memory
endif				; IFDEF LANG_GR
MSG_BLKDD_LEN equ $-MSG_BLKDD

	 public  MSG_CMDCOM
MSG_CMDCOM db	 'COMMAND.COM'  ; The name of our interpreter
MSG_CMDCOM_LEN equ $-MSG_CMDCOM ; ...and its length

	 public  MSG_COMSPEC
MSG_COMSPEC db	 'COMSPEC='     ; The environment name of COMMAND.COM
MSG_COMSPEC_LEN equ $-MSG_COMSPEC ; ...and its length

	 public  MSG_RAMROM
ifdef LANG_GR
MSG_RAMROM db	 'Æ RAM oder ROM µ' ; Filler for RAM or ROM
else
MSG_RAMROM db	 'ÆÍ RAM or ROM Íµ' ; Filler for RAM or ROM
endif				; IFDEF LANG_GR
MSG_RAMROM_LEN equ $-MSG_RAMROM ; ...and its length

if @OEM_HARPO
SUBSEG_DISP_STR struc
  SUBSEG_DISP_OWNR db ?      ; @SFO_HARPO, @SFO_MAX, etc.
  SUBSEG_DISP_TYPE db ?      ; Type (F,X,B,L,S)
  SUBSEG_DISP_NAME dw ?      ; Pointer to Name
SUBSEG_DISP_STR ends

	 public  MSG_SUBSEG
MSG_SUBSEG  label SUBSEG_DISP_STR
	 SUBSEG_DISP_STR <@SFO_HARPO, @TOKEN_FILES,PGROUP:MSG_FILES  >	;
	 SUBSEG_DISP_STR <@SFO_HARPO, @TOKEN_FCB,PGROUP:MSG_FCBS   >  ;
	 SUBSEG_DISP_STR <@SFO_HARPO, @TOKEN_BUFFERS,PGROUP:MSG_BUFFERS>  ;
	 SUBSEG_DISP_STR <@SFO_HARPO, @TOKEN_LASTDRV,PGROUP:MSG_LASTDRV>  ;
	 SUBSEG_DISP_STR <@SFO_HARPO, @TOKEN_STACKS,PGROUP:MSG_STACKS >  ;
	 SUBSEG_DISP_STR <@SFO_HARPO, @TOKEN_IFS_G,PGROUP:MSG_IFS_G >  ;
	 SUBSEG_DISP_STR <@SFO_HARPO, @TOKEN_IFS_H,PGROUP:MSG_IFS_H >  ;
	 SUBSEG_DISP_STR <@SFO_HARPO, @TOKEN_IFS_R,PGROUP:MSG_IFS_R >  ;
	 SUBSEG_DISP_STR <@SFO_HARPO, @TOKEN_IFS_Y,PGROUP:MSG_IFS_Y >  ;
	 SUBSEG_DISP_STR <@SFO_HARPO, @TOKEN_DOS3,PGROUP:MSG_SUBSEG_DOS3>
	 SUBSEG_DISP_STR <@SFO_HARPO, @TOKEN_BATCH,PGROUP:MSG_BATCH>
	 SUBSEG_DISP_STR <@SFO_MAX,   @TOKEN_XBDAREG,PGROUP:MSG_XBDAREG>
	 SUBSEG_DISP_STR <@SFO_MAX,   @TOKEN_HPDAREG,PGROUP:MSG_HPDAREG>
	 SUBSEG_DISP_STR <@SFO_MAX,   @TOKEN_STACKREG,PGROUP:MSG_STACKREG>
	 SUBSEG_DISP_STR <0, 0 ,PGROUP:MSG_UNKSUB >  ;

	 public  MSG_FILES,MSG_FCBS,MSG_BUFFERS
	 public  MSG_LASTDRV,MSG_STACKS,MSG_SUBSEG_DOS3,MSG_BATCH
	 public  MSG_XBDAREG,MSG_HPDAREG,MSG_STACKREG
	 public  MSG_IFS_G,MSG_IFS_H,MSG_IFS_R,MSG_IFS_Y
MSG_FILES	 db	 ' F (Files)  '
MSG_FCBS	 db	 ' X (FCBs)   '
MSG_BUFFERS	 db	 ' B (Buffers)'
MSG_LASTDRV	 db	 ' L (Lastdrv)'
MSG_STACKS	 db	 ' S (Stacks) '
MSG_IFS_G	 db	 ' G (IFS)    '
MSG_IFS_H	 db	 ' H (IFS)    '
MSG_IFS_R	 db	 ' R (IFS)    '
MSG_IFS_Y	 db	 ' Y (IFS)    '
MSG_SUBSEG_DOS3  db	 ' V (DOSdata)'
MSG_BATCH	 db	 ' Q (tmpdata)'
MSG_HPDAREG	 db	 ' HPDA       '
MSG_XBDAREG	 db	 ' XBDA       '
MSG_STACKREG	 db	 ' MAX Stack  '

	 public  TEXT_SUBSEG_DOS3
TEXT_SUBSEG_DOS3 db ' FILES, BUFFERS, FCBS, LASTDRV '
@TEXT_SUBSEG_DOS3_LEN equ $-TEXT_SUBSEG_DOS3	; Length of above
endif				; IF @OEM_HARPO

	 public  MSG_HDR,MSG_MAC
MSG_HDR  db	 'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸',CR,LF
ifdef LANG_GR
	 db	 '³                   SPEICHER-PLAN FšR RESIDENTE PROGRAMME                     ³',CR,LF
else
	 db	 '³                      MEMORY MAP for RESIDENT PROGRAMS                       ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF
ifdef LANG_GR
	 db	 '³                               LoDOS Bereich                                 ³',CR,LF
else
	 db	 '³                               Low DOS Memory                                ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF
ifdef LANG_GR
	 db	 '³              ³ Hex- ³ Hex- ³ Hex- ³  L„nge  ³                               ³',CR,LF
	 db	 '³ Name         ³Anfang³ Ende ³Halter³   dez.  ³ Text oder Interrupt-Nummern   ³',CR,LF
else
	 db	 '³              ³ Hex  ³ Hex  ³ Hex  ³ Decimal ³                               ³',CR,LF
	 db	 '³ Name         ³ Start³ End  ³ Owner³  Length ³ Text or Interrupt Numbers     ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,EOS
ifdef LANG_GR
;;;;;;;; db	 '³ Dateinam.Erw ³ xxxx ³ xxxx ³ xxxx ³ nnn,nnn ³                               ³',CR,LF
else
;;;;;;;; db	 '³ Filename.ext ³ xxxx ³ xxxx ³ xxxx ³ nnn,nnn ³                               ³',CR,LF
endif				; IFDEF LANG_GR
MSG_MAC  db	 '³ '
MSG_NAME db	 '             ³ '
MSG_NAME_LEN equ $-MSG_NAME-2
MSG_START db	 '   _ ³ '
MSG_END  db	 '   _ ³ '
MSG_OWNR db	 '     ³ '
MSG_BLEN db	 '      _ ³'
MSG_TEXT db	 (MSG_MAC+78-$) dup (' '),'³',CR,LF
MSG_MACLEN equ	  $-MSG_MAC	; Length in bytes of MSG_MAC

	 public  MSG_INTS
MSG_INTS db	 '³              ³      ³      ³      ³         ³'
MSG_INTS1 db	 (MSG_INTS+78-$) dup (' '),'³',CR,LF
MSG_INTSLEN equ  $-MSG_INTS	; Interrupt message length

	 public  MSG_MIDDLE,MSG_MAPTAIL
MSG_MIDDLE db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF
ifdef LANG_GR
	 db	 '³                               HiDOS Bereich                                 ³',CR,LF
else
	 db	 '³                               High DOS Memory                               ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF
ifdef LANG_GR
	 db	 '³              ³ Hex- ³ Hex- ³ Hex- ³  L„nge  ³                               ³',CR,LF
	 db	 '³ Name         ³Anfang³ Ende ³Halter³   dez.  ³ Text oder Interrupt-Nummern   ³',CR,LF
else
	 db	 '³              ³ Hex  ³ Hex  ³ Hex  ³ Decimal ³                               ³',CR,LF
	 db	 '³ Name         ³ Start³ End  ³ Owner³  Length ³ Text or Interrupt Numbers     ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,EOS


MSG_MAPTAIL db	 'ÔÍÍÍÍÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾',CR,LF,EOS

	 public  LAST_AVAIL_S,LAST_AVAIL_N,MERGING
LAST_AVAIL_S dw  0		; Start of last available block
LAST_AVAIL_N dw  0		; Number of paragraphs in merged block
MERGING  db	 0		; Amalgamating blocks (only if PSP=xxxx is used)
MERGE1ST db	 0		; Displayed 1st IGN_PSP block (should be envseg)

	 public  HEXTAB
HEXTAB	 db	 'fedcba9876543210FEDCBA9876543210' ; Hex to binary table
HEXTABLEN equ	 $-HEXTAB

UDATA	 ends			; End UDATA segment


NCODE	 segment byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 DB2HEX:near
	 extrn	 DW2HEX:near

NCODE	 ends			; End NCODE segment


UCODE	 segment byte public 'ucode' ; Start UCODE segment
	 assume  cs:PGROUP

	 extrn	 IZITLSEG:near

	 NPPROC  ACT_MAPCMD -- Find COMMAND.COM
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Find COMMAND.COM

|

	 REGSAVE <ax,bx,cx,si,di,es> ; Save registers

; Search through our environment for COMSPEC=

	 mov	 es,PSP_ENVIR_PTR ; ES:0 ==> our environment
	 assume  es:nothing	; Tell the assembler about it

	 xor	 di,di		; ES:DI ==> start of environment
	 lea	 si,MSG_COMSPEC ; DS:SI ==> "COMSPEC="
	 mov	 cx,MSG_COMSPEC_LEN ; CX = Length of ...
	 mov	 al,0		; ASCIIZ string terminator
ACT_MAPCMD_NEXTNAME:
	 REGSAVE <cx,si,di>	; Save for a moment
    repe cmpsb			; Compare 'em
	 REGREST <di,si,cx>	; Restore
	 je	 short ACT_MAPCMD_FOUND ; Jump if we found it

	 push	 cx		; Save for a moment
	 mov	 cx,-1		; We know it's there
   repne scasb			; Search for it
	 pop	 cx		; Restore

	 cmp	 es:[di].LO,0	; End of the line?
	 jne	 short ACT_MAPCMD_NEXTNAME ; Jump if not

; We didn't find COMSPEC, so just use the default names

	 mov	 CMDCOM_VEC.VOFF,offset PGROUP:MSG_CMDCOM
	 mov	 CMDCOM_VEC.VSEG,ds
	 mov	 CMDCOM_LEN,MSG_CMDCOM_LEN

	 jmp	 short ACT_MAPCMD_EXIT ; Join common exit code

ACT_MAPCMD_FOUND:
	 add	 di,cx		; Skip to end of the "COMSPEC="

; Skip over leading drive and path

	 mov	 bx,di		; Copy starting point
ACT_MAPCMD_NEXTCHAR:
	 mov	 al,es:[di]	; Get next character
	 inc	 di		; Skip over it

	 cmp	 al,0		; Izit end-of-the-line?
	 je	 short ACT_MAPCMD_END ; Jump if so

; Convert to uppercase

	 cmp	 al,'a'         ; Check against lower limit
	 jb	 short @F	; Jump if too small

	 cmp	 al,'z'         ; Check against upper limit
	 ja	 short @F	; Jump if too large

	 add	 es:[di-1].LO,'A'-'a' ; Convert to uppercase
@@:
	 cmp	 al,':'         ; Izit drive separator?
	 je	 short ACT_MAPCMD_START ; Jump if so

	 cmp	 al,'\'         ; Izit a path separator?
	 je	 short ACT_MAPCMD_START ; Jump if so

	 cmp	 al,'/'         ; Izit alternate path separator?
	 jne	 short ACT_MAPCMD_NEXTCHAR ; Jump if not
ACT_MAPCMD_START:
	 mov	 bx,di		; Save as new starting point

	 jmp	 short ACT_MAPCMD_NEXTCHAR ; Go around again

ACT_MAPCMD_END:
	 mov	 CMDCOM_VEC.VOFF,bx ; Save as starting offset
	 mov	 CMDCOM_VEC.VSEG,es ; ...     segment

	 dec	 di		; Back off to ASCIIZ string terminator
	 sub	 di,bx		; Subtract start to get length
	 mov	 CMDCOM_LEN,di	; Save for later use
ACT_MAPCMD_EXIT:
	 REGREST <es,di,si,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_MAPCMD endp 		; End ACT_MAPCMD procedure
	 NPPROC  ACT_MAPWIPE -- Wipe Our Own Environment
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Wipe out our own environment to avoid confusion with TSRs
which freed their environment but didn't zero the pointer

|

	 REGSAVE <ax,es>	; Save registers

	 mov	 ax,PSP_ENVIR_PTR ; Get our ENV pointer

	 and	 ax,ax		; Izit valid?
	 jz	 short ACT_MAPWIPE_EXIT ; No, skip out

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 ax,ax		; A convenient zero
	 mov	 es:[0].ELO,ax	; Zero the environment
	 mov	 es:[0].EHI,ax
ACT_MAPWIPE_EXIT:
	 REGREST <es,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_MAPWIPE endp		; End ACT_MAPWIPE procedure
	 NPPROC  ACT_MAPDOS -- Display DOS Line
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Display the DOS memory line

|

	 REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save registers

	 mov	 IND_DRVRS,0	; Initialize device driver index

	 cmp	 DOSVER,0500h	; Izit DOS 5.00 or later?
	 jb	 short @F	; Jump if not

	 mov	 PTR_DRVRS[0],offset PGROUP:MSG_BEGDRVRS ; Save as first message
	 mov	 PTR_DRVRS[2],offset PGROUP:MSG_ENDDRVRS ; ...	   last
@@:

; Copy name to MSG_NAME field

	 push	 cs		; Setup ES for MOVSB
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MSG_NAME	; ES:DI ==> MSG_NAME field

	 call	 CLEAR_NAME	; Clear the MSG_NAME field

	 lea	 si,MSG_DOS	; DS:SI ==> message to display
	 mov	 cx,MSG_DOS_LEN ; Length of message
     rep movsb			; Move it in

	 xor	 ax,ax		; Get starting segment
	 lea	 di,MSG_START	; DS:DI ==> starting digit in message
	 call	 DW2HEX_DS	; Convert AX to binary ending at DS:DI

	 mov	 ax,P1ST_MAC.VSEG ; Get ending segment
	 lea	 di,MSG_END	; DS:DI ==> starting digit in message
	 call	 DW2HEX_DS	; Convert AX to binary ending at DS:DI

	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 mov	 dx,ax		; Copy
	 shl	 ax,cl		; Convert from paras to bytes
	 rol	 dx,cl		; Rotate high-order nibble down
	 and	 dx,@NIB0	; Isolate low-order nibble
	 lea	 di,MSG_BLEN[6] ; DS:DI ==> units digit in message
	 call	 CONV_NUM	; Convert DX,AX to binary ending at DS:DI

	 call	 CLEAR_TEXT	; Clear the MSG_TEXT field

; Display interrupt numbers within the MAC entry

; Setup lower limit (inclusive) in paras, and
;	upper limit (exclusive) in paras

	 mov	 MAC_LO,1	; Save as low paragraph
	 mov	 ax,P1ST_MAC.VSEG ; Get ending segment
	 mov	 MAC_HI,ax	; Save as high ...

	 mov	 INT_OFF,0	; Initialize interrupt vector starting offset
	 mov	 INT_CNT,256	; Initialize # interrupts to check

	 lea	 di,MSG_TEXT	; DI ==> interrupt # save area
	 call	 DISP_INTS_LINE ; Display next line of interrupts

	 mov	 bx,@STD_OUT	; Send to standard output
	 mov	 cx,MSG_MACLEN	; Length of message
	 DOSCALL @WRITF2,MSG_MAC ; Display the line
	 call	 CHECK_LINE	; Count in another line and check for pause
ACT_MAPDOS_MORE:
	 test	 UTL_FLAG,@UTL_INT ; Any more interrupts to display?
	 jz	 short ACT_MAPDOS_EXIT ; Not this time

	 lea	 di,MSG_INTS1	; DI ==> interrupt # save area
	 call	 DISP_INTS_LINE ; Display next line of interrupts

	 mov	 bx,@STD_OUT	; Send to standard output
	 mov	 cx,MSG_INTSLEN ; Length of message
	 DOSCALL @WRITF2,MSG_INTS ; Display the line
	 call	 CHECK_LINE	; Count in another line and check for pause

	 jmp	 ACT_MAPDOS_MORE ; Go around again

ACT_MAPDOS_EXIT:
	 REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_MAPDOS endp 		; End ACT_MAPDOS procedure
	 NPPROC  ACT_MAPSUB -- Subroutine to ACT_MAP
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Subroutine to ACT_MAP.

On entry:

ES:0	 ==>	 next MAC entry

|

	 REGSAVE <ax,es>	; Save registers
ACT_MAPSUB_NEXT:

; Ensure we are where we think we should be

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Check for valid entry
	 je	 short @F	 ; It is

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Maybe it's a middle entry
	 jne	 short ACT_MAPSUB_ERRMAC ; Not this time
@@:
	 call	 DISP_MAC	; Display the entry at ES:0

	 cmp	 CURTYPE,@MAC_END ; Wuzit the last entry?
	 je	 short ACT_MAPSUB_LAST ; Jump if so

	 mov	 ax,es		; Copy current segment
	 add	 ax,CURNPAR	; Plus # paras
	 inc	 ax		; Count in the MAC paragraph

	 mov	 es,ax		; Point to next entry
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 ACT_MAPSUB_NEXT ; Go around again

ACT_MAPSUB_LAST:
	 clc			; Indicate all went well

	 jmp	 short ACT_MAPSUB_EXIT ; Join common exit code

ACT_MAPSUB_ERRMAC:
	 stc			; Indicate something went wrong
ACT_MAPSUB_EXIT:
	 REGREST <es,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

ACT_MAPSUB endp 		; End ACT_MAPSUB procedure
	 NPPROC  DISP_MAC -- Display MAC Entry at ES:0
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

On entry:

ES:0	 ==>	 MAC entry

|

	 REGSAVE <ax,bx,cx,dx,si,di,ds,es> ; Save registers

	 cld			; String ops forwardly

	 mov	 CURMAC,es	; Save for later use

	 mov	 al,es:[0].MAC_TYPE ; Get type of MAC entry
	 mov	 CURTYPE,al	; Save for later use

	 mov	 ax,es:[0].MAC_OWNR ; Get owner of MAC entry
	 mov	 CUROWNR,ax	; Save for later use

	 mov	 ax,es:[0].MAC_NPAR ; Get # paras in MAC entry
	 mov	 CURNPAR,ax	; Save for later use

	 mov	 al,es:[0].MAC_DRV ; Get drive # in MAC entry
	 mov	 CURMDRV,al	; Save for later use

	 mov	 LSEGFLAG,0	; Assume not an LSEG entry

	 mov	 ax,es		; Copy CURMAC
	 inc	 ax		; Skip to LSEG entry (if present)

	 call	 IZITLSEG	; Is AX an LSEG entry?
	 jnc	 short DISP_MAC_XLSEG ; Jump if not

	 push	 es		; Save for a moment

	 mov	 ax,es		; Copy current MAC segment
	 add	 ax,CURNPAR	; Plus the # paragraphs
	 inc	 ax		; Count in MAC paragraph

	 mov	 es,ax		; Address next MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,es:[0].MAC_OWNR ; Get the owner
	 mov	 CUROWNR,ax	; Save for later use

; Because some programs release their storage directly (ugh!) rather
; than using the DOS @RELMEM function, we check for it being free here

;;;;;;;; cmp	 ax,@MAC_FREE	; Izit free?
;;;;;;;; jne	 short


	 mov	 al,es:[0].MAC_TYPE ; Get type of MAC entry
	 mov	 CURTYPE,al	; Save for later use

	 mov	 ax,es:[0].MAC_NPAR ; Get the # paragraphs
	 inc	 ax		; Count in MAC paragraph of the LSEG entry
	 add	 CURNPAR,ax	; Add to total # paras

	 mov	 al,es:[0].MAC_DRV ; Get drive # in MAC entry
	 mov	 CURMDRV,al	; Save for later use

	 mov	 LSEGFLAG,1	; Mark as an LSEG entry

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
DISP_MAC_XLSEG:
	 cmp	 MERGING,0	; Are we merging entries?
	MJ ne	 DISP_MAC_MERGE ; Yes, so skip display

	 mov	 ax,CURMAC	; Get starting segment
	 lea	 di,MSG_START	; DS:DI ==> starting digit in message
	 call	 DW2HEX_DS	; Convert AX to binary ending at DS:DI

	 mov	 ax,CURMAC	; Copy current MAC segment
	 add	 ax,CURNPAR	; Plus the # paragraphs
	 inc	 ax		; Count in MAC paragraph

	 lea	 di,MSG_END	; DS:DI ==> starting digit in message
	 call	 DW2HEX_DS	; Convert AX to binary ending at DS:DI

	 mov	 dx,CURNPAR	; Get the # paragraphs

	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 mov	 ax,dx		; Copy
	 shl	 ax,cl		; Convert from paras to bytes
	 rol	 dx,cl		; Rotate high-order nibble down
	 and	 dx,@NIB0	; Isolate low-order nibble
	 lea	 di,MSG_BLEN[6] ; DS:DI ==> units digit in message
	 call	 CONV_NUM	; Convert DX,AX to binary ending at DS:DI

	 call	 CLEAR_TEXT	; Clear the MSG_TEXT field

	 mov	 ax,CUROWNR	; Get current owner

	 and	 ax,ax		; Available entry?
	 jz	 short @F	; Jump if so

	 cmp	 ax,@MAC_HOLE	; Special available entry?
	 jne	 short DISP_MAC_XAVAIL ; Jump if not

@@:
	 jmp	 DISP_MAC_AVAIL ; Display as free entry

DISP_MAC_XAVAIL:
	 mov	 cx,cs		; Get current segment

	 cmp	 ax,cx		; Same as current segment?
	 je	 short @F	; Yes, merge it

	 cmp	 ax,IGN_PSP	; Izit a PSP we should ignore?
	 je	 short @F	; Yes, merge it

	 jmp	 short DISP_MAC_NOMRG ; Treat this entry normally

@@:
	 mov	 MERGING,1	; Set flag to amalgamate
	 mov	 ax,CURMAC	; Get current block
	 mov	 LAST_AVAIL_S,ax ; Set start of merged block
	 mov	 ax,CURNPAR	; Get number of blocks
	 inc	 ax		; Add in MAC entry
	 mov	 LAST_AVAIL_N,ax ; Initialize number of merged blocks

	 cmp	 MERGE1ST,0	; Izit the first block (should be envseg)?
	MJ nz	 DISP_MAC_MTEST ; Don't display unless next block won't merge

	 inc	 MERGE1ST	; Make the "first merge" flag non-zero
	 mov	 MERGING,0	; Clear merging flag
	 jmp	 DISP_MAC_CUR	; Display first block separately, assuming
				; it's the envseg for IGN_PSP

DISP_MAC_NOMRG:
	 call	 DISP_INTS	; Display interrupt #s of MAC entry at ES:0
	 jc	 short DISP_MAC_XTEXT ; Jump if we found some matches

	 cmp	 ax,@MAC_DRV	; Device driver entry?
	 je	 short DISP_MAC_XTEXT ; Yes, skip text display

	 cmp	 LSEGFLAG,1	; Izit an LSEG entry?
	 je	 short DISP_MAC_XTEXT ; Yes, skip text display

	 call	 DISP_TEXT	; Display text of MAC entry at ES:0
DISP_MAC_XTEXT:
	 cmp	 CURMAC,9000h	; Izit well above DOS owner entries?
	 jae	 short @F	; Jump if so

	 cmp	 ax,0008h	; Starting entry?
	MJ e	 DISP_MAC_DRVRS ; Yes, skip conversion
@@:
	 cmp	 ax,@MAC_DRV	; Device driver entry?
	MJ e	 DISP_MAC_DD	; Yes, handle separately

if @OEM_HARPO
	cmp	 ax,@MAC_SUBSEG_DOS ; Is this a sub-segment entry?
	MJ e	 DISP_MAC_SUBSEG_DOS ; Yes, handle separately

	cmp	 ax,@MAC_SUBSEG_MAX ; Is this a sub-segment entry?
	MJ e	 DISP_MAC_SUBSEG_MAX ; Yes, handle separately
endif				; IF @OEM_HARPO

	 cmp	 ax,@MAC_UMB	; UMB entry?
	MJ e	 DISP_MAC_UMB	; Yes, say so

	 cmp	 ax,@MAC_LSEG	; LSEG entry?
	MJ e	 DISP_MAC_UMB	; Yes, call it a UMB

	 cmp	 ax,@MAC_LINK	; Linking entry?
	MJ e	 DISP_MAC_RAMROM ; Yes, so it's a filler for RAM or ROM

	 cmp	 ax,@MAC_SPAN	; Spanning entry?
	MJ e	 DISP_MAC_RAMROM ; Yes, so it's a filler for RAM or ROM

; ES:0	 ==>	 current MAC entry
; AX	 =	 CUROWNR

	 lea	 di,MSG_OWNR	; DS:DI ==> starting digit in message
	 call	 DW2HEX_DS	; Convert AX to binary ending at DS:DI
	 mov	 MSG_OWNR[4],' ' ; Remove any previous '-'

	 mov	 es,ax		; Address via segment register
	 assume  es:PGROUP	; Tell the assembler about it

; We recognize COMMAND.COM as the first entry which owns itself

	 cmp	 ax,PSP_CTRL_PSP ; Izit its own control PSP?
	MJ e	 DISP_MAC_CMD	; Yes

	 assume  ds:nothing	; So we use ES for PSP_ENVIR_PTR
	 mov	 ax,PSP_ENVIR_PTR ; Get the owner's ENV pointer
	 assume  ds:PGROUP,es:nothing

	 mov	 CURENV,ax	; Save as current environment

	 and	 ax,ax		; Anybody home?
	MJ z	 DISP_MAC_DOS4	; No, maybe we can get the name from the MAC

;;;;;;;; cmp	 ax,MAPENV	; Same as our own environment?
;;;;;;; MJ e	 DISP_MAC_UNK	; Yes, skip it and blank 'Filename.ext'
;;;;;;;;
; Attempt to catch environment tail-ending.
; This occurs when a TSR frees its environment, but doesn't
; zero out the environment pointer in its PSP.
; If the environment segment is preceded by what looks like a
; MAC entry (based on the .MAC_TYPE field), and that MAC entry owner
; is unequal to the current owner, then assume its spurious.

	 dec	 ax		; Back up to what we hope is a MAC entry
	 mov	 es,ax		; Address via segment register
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Check for valid MAC entry
	 je	 short DISP_MAC1 ; Jump if it's a match

	 cmp	 es:[0].MAC_TYPE,@MAC_END ; Check for valid MAC entry
	 jne	 short DISP_MAC_DOS4 ; No match, must not be a MAC entry

; Preceding para looks like a MAC entry -- ensure matching owners

DISP_MAC1:
	 mov	 ax,es:[0].MAC_OWNR ; Get the environment's owner

	 cmp	 ax,CUROWNR	; Check for match with our owner
	 je	 short DISP_MAC2 ; It's a match, display the program name

; If this is DOS 4.x or later, we can get the program name from
; the MAC entry

DISP_MAC_DOS4:
	 cmp	 DOSVER,0400h	; Check DOS version #
	MJ b	 DISP_MAC_UNK	; Jump if too early

; Copy name to MSG_NAME field

	 call	 CLEAR_NAME	; Clear the MSG_NAME field

; Move filename at CURMAC:[0].MAC_NAME to MSG_NAME

	 mov	 ds,CURMAC	; Get segment of current MAC entry
	 assume  ds:nothing	; Tell the assembler about it
				; DS:SI ==> source text
	 push	 cs
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MSG_NAME	; ES:DI ==> MSG_NAME field
	 lea	 si,ds:[0].MAC_NAME ; DS:SI ==> source name
	 mov	 cx,8		; No longer than this
@@:
	 lodsb			; Get next character

	 and	 al,al		; End of the line?
	 jz	 short @F	; Yes, display it

	 stosb			; Save in MSG_NAME

	 loop	 @B		; Go around again
@@:
	 jmp	 DISP_MAC_MSG	; Display it

	 assume  ds:PGROUP	; Tell the assembler about it

DISP_MAC2:
	 mov	 es,CURENV	; Address via segment register
	 assume  es:nothing	; Tell the assembler about it

; Search for program name in the environment

	 xor	 di,di		; ES:DI ==> start of environment
	 mov	 al,0		; Environment entry terminator
	 mov	 cx,-1		; We know it's there
DISP_MAC_ENV:
   repne scasb			; Search for it

	 scasb			; Check next entry
	 jne	 short DISP_MAC_ENV ; Not at end as yet

	 mov	 ax,1		; Test value

	 scasw			; Normal filler?
	MJ ne	 DISP_MAC_UNK	; No, skip it and fill 'Filename.ext'

	 mov	 al,0		; Search for string terminator
	 push	 di		; Save
	 mov	 cx,-1		; We know it's there
   repne scasb			; Search for it
	 dec	 di		; Back off to terminating zero
	 mov	 cx,di		; Copy pointer

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
	 call	 CLEAR_NAME	; Clear the MSG_NAME field

; Move filename at ES:SI to MSG_NAME

	 push	 es		; Setup DS for string ops
	 pop	 ds
	 assume  ds:nothing	; Tell the assembler about it
				; DS:SI ==> source text
	 push	 cs
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MSG_NAME	; ES:DI ==> MSG_NAME field
@@:
	 lodsb			; Get next character

	 and	 al,al		; End of the line?
	MJ z	 DISP_MAC_MSG	; Yes, display it

	 stosb			; Save in MSG_NAME

	 jmp	 @B		; Go around again

DISP_MAC_MERGE:
	 assume  ds:PGROUP,es:nothing ; Tell the assembler

; Update merged totals... ignore possible holes
	 mov	 ax,LAST_AVAIL_N ; Get total of merged blocks
	 add	 ax,CURNPAR	; Add in our paragraphs
	 inc	 ax		; Add 1 paragraph for MAC entry
	 mov	 LAST_AVAIL_N,ax ; Update total

DISP_MAC_MTEST:
	 cmp	 CURTYPE,@MAC_END ; Izit the end?
	 je	 short DISP_MAC_MDISP ; Display accumulated data

	 mov	 ax,LAST_AVAIL_N ; Get total of merged blocks
	 add	 ax,LAST_AVAIL_S ; Add start of available block

	 push	 es		; Save ES
	 mov	 es,ax		; Address next MAC
	 assume  es:nothing	; Tell the assembler

	 inc	 ax		; Skip the MAC
	 add	 ax,es:[0].MAC_NPAR ; Add number of paragraphs in next block
	 mov	 dx,es:[0].MAC_OWNR ; Get owner of next entry
	 pop	 es		; Restore ES
	 assume  es:nothing	; Tell the assembler

	 cmp	 ax,POVR_MAC	; Izit in low DOS?
	 jnb	 short DISP_MAC_MDISP ; End of low DOS; display it

	 or	 dx,dx		; Izit free?
	MJ z	 DISP_MAC_EXIT	; Yes, so we can keep merging

	 cmp	 dx,IGN_PSP	; Izit still one we should ignore?
	MJ e	 DISP_MAC_EXIT	; Yes, so keep on merging

	 mov	 ax,cs		; Get our CS
	 cmp	 ax,dx		; Izit our CS (special case we ALWAYS ignore)?
	MJ e	 DISP_MAC_EXIT	; Yes, keep on merging

DISP_MAC_MDISP:
	 ; Use our merged data to format output buffer
	 mov	 ax,LAST_AVAIL_S ; Get starting block
	 lea	 di,MSG_START	; DS:DI ==> starting digit in message
	 call	 DW2HEX_DS	; Convert AX to binary ending at DS:DI

	 mov	 ax,LAST_AVAIL_S ; Get starting paragraph
	 add	 ax,LAST_AVAIL_N ; Get number of paras (MAC entries included)

	 lea	 di,MSG_END	; DS:DI ==> starting digit in message
	 call	 DW2HEX_DS	; Convert AX to binary ending at DS:DI

	 mov	 dx,LAST_AVAIL_N ; Get the # paragraphs
	 dec	 dx		; Adjust for extra MAC entry

	 mov	 cl,4-0 	; Shift amount between bytes and paras
	 mov	 ax,dx		; Copy
	 shl	 ax,cl		; Convert from paras to bytes
	 rol	 dx,cl		; Rotate high-order nibble down
	 and	 dx,@NIB0	; Isolate low-order nibble
	 lea	 di,MSG_BLEN[6] ; DS:DI ==> units digit in message
	 call	 CONV_NUM	; Convert DX,AX to binary ending at DS:DI

	 call	 CLEAR_NAME	; Clear the MSG_NAME field
	 call	 CLEAR_OWNR	; Clear the owner field

	 push	 cs		; Setup ES for MOVSB
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MSG_NAME	; ES:DI ==> MSG_NAME field
	 lea	 si,MSG_AVL	; DS:SI ==> message to display
	 mov	 cx,MSG_AVL_LEN ; Length of message
     rep movsb			; Move it in


	 mov	 MERGING,0	; Clear flag
	 mov	 LAST_AVAIL_S,0 ; Clear starting block
	 mov	 LAST_AVAIL_N,0 ; Clear total block count
	 jmp	 DISP_MAC_MSG	; Join common display code

DISP_MAC_DRVRS:
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 push	 cs		; Setup ES for MOVSB
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MSG_NAME	; ES:DI ==> MSG_NAME field

	 call	 CLEAR_NAME	; Clear the MSG_NAME field

	 mov	 si,IND_DRVRS	; Get message index
	 xor	 IND_DRVRS,1	; Skip to next message modulo two
	 shl	 si,1		; Times two to index table of words
	 mov	 si,PTR_DRVRS[si] ; DS:SI ==> message to display
	 mov	 cx,MSG_DRVRS_LEN ; Length of message
     rep movsb			; Move it in

	 jmp	 DISP_MAC_MSG	; Join common code


DISP_MAC_CMD:
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 push	 cs		; Setup ES for MOVSB
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MSG_NAME	; ES:DI ==> MSG_NAME field

	 call	 CLEAR_NAME	; Clear the MSG_NAME field

	 push	 ds		; Save for a moment

	 lds	 si,CMDCOM_VEC	; DS:SI ==> message to display
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 cx,CMDCOM_LEN	; Length of message
     rep movsb			; Move it in

	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 jmp	 DISP_MAC_MSG	; Join common code


DISP_MAC_DD:
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 mov	 ax,es		; Copy MAC segment
	 inc	 ax		; Skip over MAC entry to owner

	 cmp	 es:[0].MAC_OWNR,@MAC_DRV ; Are we looking at the driver's MAC?
	 je	 short @F	; Yea, go

	 mov	 ax,es:[0].MAC_OWNR ; Get the driver segment
@@:
	 lea	 di,MSG_OWNR	; DS:DI ==> starting digit in message
	 call	 DW2HEX_DS	; Convert AX to binary ending at DS:DI
	 mov	 MSG_OWNR[4],' ' ; Remove any previous '-'

	 mov	 CURDEV_VEC.VSEG,ax ; Save for later use
	 mov	 CURDEV_VEC.VOFF,0
DISP_MAC_DD1:
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 lds	 si,CURDEV_VEC	; DS:SI ==> current driver header
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ax,ds:[si].DD_NEXT.VOFF ; Get offset of nested driver
	 assume  ss:PGROUP	; Tell the assembler about it
	 mov	 CURDEV_VEC.VOFF,ax ; Save for later use

	 inc	 ax		; Izit -1 (end-of-the-line)?
	 jz	 short DISP_MAC_DD2 ; Jump if so

	 mov	 ax,ds:[si].DD_NEXT.VSEG ; Get segment of nested driver

	 cmp	 ax,CURDEV_VEC.VSEG ; Same as before?
	 je	 short @F	; Yes

	 and	 ax,ax		; Segment unset?
	 jz	 short @F	; Yes, assume same as before
DISP_MAC_DD2:
	 mov	 CURDEV_VEC.VSEG,-1 ; Mark as no more
	 assume  ss:nothing	; Tell the assembler about it
@@:
	 call	 CLEAR_NAME	; Clear the MSG_NAME field

	 mov	 es,CURMAC	; Restore pointer to current MAC entry
	 assume  es:nothing	; Tell the assembler about it

	 mov	 al,CURMDRV	; Get the drive # if a block device
	 mov	 ah,ds:[si].DD_NAME[0] ; Get # units in this device

	 push	 cs		; Setup ES for MOVSB
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it
	 lea	 di,MSG_NAME	; ES:DI ==> MSG_NAME field

	 test	 ds:[si].DD_ATTR,DRV_ATTR_CHAR ; Izit a character device driver?
	 jz	 short DISP_MAC_DD_BLK ; No, hence there's no name field

	 lea	 si,ds:[si].DD_NAME ; DS:SI ==> name field

	 mov	 ax,'eD'        ; Prefix with 'Dev='
	 stosw			; Save in output buffer
	 mov	 ax,'=v'        ; Prefix with 'Dev='
	 stosw			; Save in output buffer

	 mov	 cx,8 shr (1-0) ; Length of device driver name in words
     rep movsw			; Move it in

	 jmp	 DISP_MAC_MSG	; Join common code


DISP_MAC_DD_BLK:
	 call	 CLEAR_NAME	; Clear the MSG_NAME field

	 push	 cs		; Setup DS for MOVSB
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 lea	 si,MSG_BLKDD	; DS:SI ==> message to display
	 mov	 cx,MSG_BLKDD_LEN ; Length of message
     rep movsb			; Move it in

	 cmp	 ah,1		; Check for multiple units
	 ja	 short DISP_MAC_DD_BLKS ; There's more than one
	MJ b	 DISP_MAC_EXIT	; Don't display if no devices assigned

	 add	 al,'A'         ; Convert to ASCII
	 stosb			; Save as starting drive

	 jmp	 DISP_MAC_MSG	; Join common code


DISP_MAC_DD_BLKS:
	 mov	 es:[di-1].ELO,' s' ; Make it plural
	 inc	 di		; Skip over it

	 add	 al,'A'         ; Convert to ASCII
	 stosb			; Save as starting drive

	 add	 ah,al		; Skip to next drive letter
	 dec	 ah		; Back to last letter

	 mov	 al,'-'         ; Separator in AL,
				; trailing driver letter in AH
	 stosw			; Save in output buffer

	 jmp	 near ptr DISP_MAC_MSG ; Join common code

if @OEM_HARPO
DISP_MAC_SUBSEG_DOS:
	 mov	 ah,@SFO_HARPO	; Mark as DOS (Harpo) subsegment

	 jmp	 short @F	; Join common code

DISP_MAC_SUBSEG_MAX:
	 mov	 ah,@SFO_MAX	; Mark as MAX subsegment
@@:
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

; This entry should have a blank owner field

	 call	 CLEAR_OWNR	; Clear the owner field
	 call	 CLEAR_NAME	; Clear the MSG_NAME field

; Find correct subseg name.  All MAC entries of type @MAC_SUBSEG should
; have an identifier (listed in MAC.INC as @TOKEN_...) in the MAC_DRV field.

	 mov	 al,es:[0].MAC_DRV ; Get subsegment type
	 xor	 bx,bx		; Initialize index into name table

SUBSEG_NEXT:
	 cmp	 MSG_SUBSEG[bx].SUBSEG_DISP_OWNR,ah ; Izit the same owner?
	 jne	 short @F	; Jump if not

	 cmp	 MSG_SUBSEG[bx].SUBSEG_DISP_TYPE,al ; Is this our subseg?
	 je	 short SUBSEG_DONE ; Jump if so
@@:
	 cmp	 MSG_SUBSEG[bx].SUBSEG_DISP_TYPE,0 ; End of the list?
	 je	 short SUBSEG_DONE ; Jump if so (use default name)

	 add	 bx,type SUBSEG_DISP_STR ; Bump to next entry

	 jmp	 SUBSEG_NEXT	; Try next entry

SUBSEG_DONE:
	 mov	 si,MSG_SUBSEG[bx].SUBSEG_DISP_NAME ; Get subseg name

	 push	 cs		; Setup ES for MOVSB
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

; Note that the names we share with util/s have a leading space for
; indentation purposes.
	 lea	 di,MSG_NAME[-1] ; ES:DI ==> Space before MSG_NAME field
	 mov	 cx,@SUBSID_TXTLEN ; Length of message
     rep movsb			; Move it in

; Clear out the interrupt vector field (except for STACKS=)

	 cmp	 al,@TOKEN_STACKS ; Is it the STACKS= subsegment?
	 je	 short @F	; Jump if so

	 call	 CLEAR_TEXT	; Subsegs have no text
@@:

; If DOS 3.3, then we'll use the special subseg text description

	 cmp	 al,@TOKEN_DOS3 ; Izit the DOS3 hodgepodge?
	 jne	 short @F	; Jump if not

	 mov	 cx,@TEXT_SUBSEG_DOS3_LEN ; Length of special text string
	 lea	 si,TEXT_SUBSEG_DOS3 ; Address of special text string
	 lea	 di,MSG_TEXT	; Output save area
     rep movs	 MSG_TEXT[di],TEXT_SUBSEG_DOS3[si] ; Move the text message
@@:

	 jmp	 short DISP_MAC_MSG ; Join common code
endif				; IF @OEM_HARPO

DISP_MAC_RAMROM:
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 call	 CLEAR_OWNR	; Clear the owner field
	 call	 CLEAR_NAME	; Clear the MSG_NAME field

	 push	 cs		; Setup ES for MOVSB
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it
	 lea	 di,MSG_MAC	; ES:DI ==> border
	 lea	 si,MSG_RAMROM	; DS:SI ==> message to display

	 mov	 cx,MSG_RAMROM_LEN ; Length of message
     rep movsb			; Move it in

	 jmp	 short DISP_MAC_MSG ; Join common code


DISP_MAC_CUR:
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

;;;;;;;; mov	 word ptr MSG_OWNR[0],'C-'
;;;;;;;; mov	 word ptr MSG_OWNR[2],'ru'
;;;;;;;; mov	 byte ptr MSG_OWNR[4],'-'
	 call	 CLEAR_OWNR	; Clear the owner field

	 mov	 es,ax		; Address via segment register
	 assume  es:PGROUP	; Tell the assembler about it
	 assume  ds:nothing
	 mov	 ax,PSP_ENVIR_PTR ; Get the owner's ENV pointer
	 assume  ds:PGROUP,es:nothing
	 mov	 MAPENV,ax	; Save for later use

	 jmp	 short DISP_MAC_AVAIL1 ; Join common code


DISP_MAC_UMB:
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 mov	 word ptr MSG_OWNR[0],'U-'
	 mov	 word ptr MSG_OWNR[2],'BM'
	 mov	 byte ptr MSG_OWNR[4],'-'

	 jmp	 short DISP_MAC_UNK ; Join common code

DISP_MAC_AVAIL:
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 call	 CLEAR_OWNR	; Clear the owner field
DISP_MAC_AVAIL1:
	 call	 CLEAR_NAME	; Clear the MSG_NAME field

	 push	 cs		; Setup ES for MOVSB
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it
	 lea	 di,MSG_NAME	; ES:DI ==> MSG_NAME field
	 lea	 si,MSG_AVL	; DS:SI ==> message to display
	 mov	 cx,MSG_AVL_LEN ; Length of message
     rep movsb			; Move it in

	 jmp	 short DISP_MAC_MSG ; Join common code

DISP_MAC_UNK:
	 call	 CLEAR_NAME	; Clear the MSG_NAME field
	 public  DISP_MAC_MSG
DISP_MAC_MSG:
	 push	 cs
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

; Ensure the MSG_NAME field is valid by laundering characters
; below a blank

	 lea	 si,MSG_NAME	; DS:SI ==> MSG_NAME field
	 mov	 cx,8+1+3	; CX = maximize length
DISP_MAC_MSG_NEXT:
	 lodsb			; Get next character

	 cmp	 al,' '         ; Check against lower limit
	 jae	 short @F	; Jump if beyond reproach

	 mov	 PGROUP:[si-1].LO,' ' ; Convert to a blank
@@:
	 loop	 DISP_MAC_MSG_NEXT ; Jump if more characters to launder

	 mov	 bx,@STD_OUT	; Send to standard output
	 mov	 cx,MSG_MACLEN	; Length of message
	 DOSCALL @WRITF2,MSG_MAC ; Display the line
	 call	 CHECK_LINE	; Count in another line and check for pause

; Reset borders in case RAM or ROM stepped on them

	 mov	 MSG_NAME.ELO[-2],' ³'
	 mov	 MSG_NAME.ELO[MSG_NAME_LEN-1],'³ '

	 cmp	 CURDEV_VEC.VSEG,-1 ; Any more nested device drivers?
	 je	 short DISP_MAC_MORE ; Not this time

	 call	 CLEAR_OWNR	; Clear the owner field
	 call	 CLEAR_TEXT	; Clear the MSG_TEXT field

	 mov	 ax,'  '        ; A convenient blank
	 mov	 MSG_START.ELO[0],ax ; Blank the starting address
	 mov	 MSG_START.EHI[0],ax ; Blank the starting address

	 mov	 MSG_END.ELO[0],ax   ; Blank the ending address
	 mov	 MSG_END.EHI[0],ax   ; Blank the ending address

	 mov	 MSG_BLEN.ELO[0],ax  ; Blank length
	 mov	 MSG_BLEN.EHI[0],ax  ; Blank length

	 mov	 MSG_BLEN.ELO[4],ax  ; Blank length
	 mov	 MSG_BLEN.EHI[4],ax  ; Blank length

	 jmp	 DISP_MAC_DD1	; Go around again


DISP_MAC_MORE:
	 test	 UTL_FLAG,@UTL_INT ; Any more interrupts to display?
	 jz	 short DISP_MAC_EXIT ; Not this time

	 lea	 di,MSG_INTS1	; DI ==> interrupt # save area
	 call	 DISP_INTS_LINE ; Display next line of interrupts

	 mov	 bx,@STD_OUT	; Send to standard output
	 mov	 cx,MSG_INTSLEN ; Length of message
	 DOSCALL @WRITF2,MSG_INTS ; Display the line
	 call	 CHECK_LINE	; Count in another line and check for pause

	 jmp	 short DISP_MAC_MORE ; Go around again

	 public  DISP_MAC_EXIT
DISP_MAC_EXIT:
	 REGREST <es,ds,di,si,dx,cx,bx,ax> ; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_MAC endp			; End DISP_MAC procedure
	 NPPROC  CLEAR_OWNR -- Clear The Owner Field
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Clear the MSG_OWNR field

|

	 REGSAVE <ax>		; Save register

	 mov	 ax,'  '        ; A convenient blank
	 mov	 MSG_OWNR.ELO[0],ax ; Blank the owner's address
	 mov	 MSG_OWNR.EHI[0],ax ; Blank the owner's address
	 mov	 MSG_OWNR[4],al ; Blank the owner's address

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CLEAR_OWNR endp 		; End CLEAR_OWNR procedure
	 NPPROC  CLEAR_TEXT -- Clear Text Field
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Clear the MSG_TEXT field

|

	 REGSAVE <ax,cx,di,es>	; Save registers

	 push	 cs		; Setup ES for STOSB
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MSG_TEXT	; ES:DI ==> save area
	 mov	 cx,size MSG_TEXT ; Size of text area
	 mov	 al,' '         ; Fill with blanks
     rep stosb			; Fill 'er up

	 REGREST <es,di,cx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CLEAR_TEXT endp 		; End CLEAR_TEXT procedure
	 NPPROC  DISP_INTS -- Display Interrupt Numbers of MAC Entry
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Display interrupt numbers within the MAC entry

On entry;

ES:0	 ==>	 MAC entry

On exit:

CF	 =	 0 if no matching interrupts found
	 =	 1 if some interrupts found

|

	 REGSAVE <ax,di>	; Save registers

; Setup lower limit (inclusive) in paras, and
;	upper limit (exclusive) in paras

	 mov	 ax,es		; Copy the segment
	 mov	 MAC_LO,ax	; Save as low paragraph

	 add	 ax,CURNPAR	; Plus # paragraphs
	 inc	 ax		; Count the MAC entry, too to get upper limit
	 mov	 MAC_HI,ax	; Save as high ...

	 mov	 INT_OFF,0	; Initialize interrupt vector starting offset
	 mov	 INT_CNT,256	; Initialize # interrupts to check

	 lea	 di,MSG_TEXT	; DI ==> interrupt # save area
	 call	 DISP_INTS_LINE ; Display next line of interrupts

	 REGREST <di,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_INTS endp			; End DISP_INTS procedure
	 NPPROC  DISP_INTS_LINE -- Display Next Line of Interrupts
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Display interrupt numbers in the range of MAC_LO and MAC_HI
starting at 0:INT_OFF for INT_CNT values.

On entry:

DI	 =	 offset of display area in PGROUP

On exit:

CF	 =	 0 if no matching interrupts found
	 =	 1 if some interrupts found

|

	 REGSAVE <ax,bx,cx,dx,si,di,bp,ds,es> ; Save registers

	 push	 cs		; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

; Clear out the interrupt vector field

	 push	 di		; Save for a moment
	 mov	 cx,size MSG_INTS1 ; Size of text area
	 mov	 al,' '         ; Fill with blanks
     rep stosb			; Fill 'er up
	 pop	 di		; Restore

	 inc	 di		; Skip over leading blank

; Setup local variables

	 mov	 si,INT_OFF	; SI ==> interrupt vector table start
	 mov	 cx,INT_CNT	; CX = # remaining interrupts
	 mov	 bx,MAC_LO	; Get lower paragraph #
	 mov	 dx,MAC_HI	; Get higher ...

	 and	 UTL_FLAG,not @UTL_INT ; Mark as no more interrupts to display
	 mov	 INT_MAX,10	; Initialize maximum # interrupts displayed

	 mov	 ax,seg INTVEC	; Get segment of interrupt vectors
	 mov	 ds,ax
	 assume  ds:INTVEC	; Tell the assembler about it

	 xor	 bp,bp		; Initialize interrupt # counter
DISP_INTS_NEXT:
	 mov	 ax,INT00_VEC.VOFF[si] ; Get the offset
	 add	 ax,16-1	; Round up to next para
	 rcr	 ax,1		; Copy CF to high-order bit
	 shr	 ax,1		; Shift down to units of paras
	 shr	 ax,1
	 shr	 ax,1

	 add	 ax,INT00_VEC.VSEG[si] ; Add the segment to get para #
	 jc	 short DISP_INTS_LOOP ; Jump if too big

	 cmp	 ax,bx		 ; Check against the lower limit
	 jb	 short DISP_INTS_LOOP ; Too small

	 cmp	 ax,dx		 ; Check against the upper limit
	 jae	 short DISP_INTS_LOOP ; Too big

; Pick off INTs 30h and 31h as they are not valid interrupts

	 cmp	 si,30h*(type INT00_VEC) ; Izit INT 30h?
	 je	 short DISP_INTS_LOOP ; Jump if so

	 cmp	 si,31h*(type INT00_VEC) ; Izit INT 31h?
	 je	 short DISP_INTS_LOOP ; Jump if so

	 dec	 INT_MAX	; One fewer interrupt to display
	 jns	 short DISP_INTS_FMT ; Jump if we can fit in more

;;;;;;;; dec	 di		; Back up to last blank
;;;;;;;; mov	 ax,'..'        ; Continuation symbol
;;;;;;;; stosw			; Save in output area

	 or	 UTL_FLAG,@UTL_INT ; Mark as more interrupts to display
	 mov	 INT_OFF,si	; Save as next offset in interrupt vector table
	 mov	 INT_CNT,cx	; Save as remaining count

	 jmp	 short DISP_INTS_EXIT ; Join common exit code

DISP_INTS_FMT:
	 mov	 ax,si		; Copy interrupt offset in bytes
	 shr	 ax,1		; Convert from bytes
	 shr	 ax,1		; ...to dwords
	 call	 DB2HEX 	; Convert AL to hex at ES:DI, incrementing DI

	 mov	 al,' '         ; Separator
	 stosb			; Save in output area
	 inc	 bp		; Count in another matching interrupt #
DISP_INTS_LOOP:
	 add	 si,type INT00_VEC ; Skip to next interrupt vector

	 loop	 DISP_INTS_NEXT ; Jump if more interrupt #s to check
DISP_INTS_EXIT:
	 cmp	 bp,1		; CF = 1 if no match, 0 otherwise
	 cmc			; CF = 0 if no match, 1 otherwise

	 REGREST <es,ds,bp,di,si,dx,cx,bx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_INTS_LINE endp		; End DISP_INTS_LINE procedure
	 NPPROC  DISP_TEXT -- Display Text of MAC Entry
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Display text of MAC entry.
If environment name only (starts with 0000, 0001), stop display
after the name.

On entry;

ES:0	 ==>	 MAC entry

|

	 REGSAVE <ax,cx,dx,si,di,ds,es> ; Save registers

	 mov	 ax,es		; Copy segment
	 inc	 ax		; Skip over MAC entry
	 mov	 ds,ax
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; DS:SI ==> start of data

	 push	 cs		; Setup ES for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MSG_TEXT	; ES:DI ==> save area
	 mov	 cx,size MSG_TEXT ; Size of text area

	 xor	 dx,dx		; Initialize flags to zero

	 cmp	 ds:[si].ELO,0000h ; Izit a word like this?
	 jne	 short DISP_TEXT_NEXT ; No, continue on

	 cmp	 ds:[si].EHI,0001h ; Izit a word like this?
	 jne	 short DISP_TEXT_NEXT ; No, continue on

	 add	 si,4		; Yes, skip over it
	 inc	 dx		; Mark as environment name only
DISP_TEXT_NEXT:
	 lodsb			; Get next character

	 cmp	 al,80h 	; Bigger than the highest character?
	 jae	 short DISP_TEXT_EXIT ; Yes, skip out

	 cmp	 al,' '         ; Bigger than a blank?
	 jae	 short DISP_TEXT_STORE ; Yes, just store it

	 and	 al,al		; Zero value?
	 jnz	 short DISP_TEXT_EXIT ; No, skip out

	 and	 dx,dx		; Check for environment name only
	 jnz	 short DISP_TEXT_EXIT ; That's all folks

	 mov	 al,'³'         ; Use fill value
DISP_TEXT_STORE:
	 stosb			; Save in output area

	 loop	 DISP_TEXT_NEXT ; Jump if more text to display
DISP_TEXT_EXIT:
	 REGREST <es,ds,di,si,dx,cx,ax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_TEXT endp			; End DISP_TEXT procedure
	 NPPROC  CLEAR_NAME -- Clear MSG_NAME Field
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Clear the MSG_NAME field

|

	 REGSAVE <ax,cx,di,es>	; Save registers

	 push	 cs
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,MSG_NAME	; ES:DI ==> filename.ext
	 mov	 cx,MSG_NAME_LEN ; Length of area
	 mov	 al,' '         ; Fill with this
     rep stosb			; Consider it blanked

	 REGREST <es,di,cx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CLEAR_NAME endp 		; End CLEAR_NAME procedure
	 NPPROC  CONV_NUM -- Convert Numbers
	 assume  ds:PGROUP,es:PGROUP,ss:nothing
COMMENT|

This procedure converts the 32-bit number in DX,AX to decimal,
storing the digits backwards at DS:DI.

|

	 REGSAVE <ax,bx,cx,dx,si,di,bp,es> ; Save registers

	 mov	 bp,dx		; Copy to local registers
	 mov	 bx,ax

	 push	 ds		; Setup ES:DI
	 pop	 es
	 assume  es:nothing	; Tell the assembler about it

	 std			; Store backwards

	 mov	 cx,7		; # characters to blank
	 mov	 al,' '         ; Fill with this
	 push	 di		; Save for a moment
     rep stosb
	 pop	 di		; Restore

	 mov	 cx,10		; Divisor
	 xor	 si,si		; Zero thousands separator counter
CONV_NUM_LOOP:
	 xor	 dx,dx		; Zero high-order for division
	 mov	 ax,bp		; Get the high-order size
	 div	 cx		; Strip off a decimal digit
	 mov	 bp,ax		; Store back as new high-order size
	 mov	 ax,bx		; Get the low-order size
	 div	 cx		; Strip off a decimal digit
	 mov	 bx,ax		; Store back as new low-order size
	 mov	 al,dl		; Copy to store
	 add	 al,'0'         ; Convert to ASCII

	 cmp	 si,3		; Store thousands separator first?
	 jne	 short CONV_NUM_LOOP1 ; Not yet

	 xor	 si,si		; Zero counter
	 push	 ax		; Save for a moment
;;;;;;;; mov	 al,CDI.CDI_SEPTHO ; Thousands separator
	 mov	 al,@NATL_THOU	; Thousands separator
	 stosb			; Store it
	 pop	 ax		; Restore
CONV_NUM_LOOP1:
	 inc	 si		; Count one more in
	 stosb			; Store backwards at ES:DI

	 mov	 ax,bx		; Copy low-order size
	 or	 ax,bp		; Include high-order size
	 jnz	 short CONV_NUM_LOOP  ; Go around again

	 cld			; Restore direction flag

	 REGREST <es,bp,di,si,dx,cx,bx,ax> ; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CONV_NUM endp			; End CONV_NUM procedure
	 NPPROC  DW2HEX_DS -- Convert AX to Hex At DS:DI
	 assume  ds:PGROUP,es:nothing,ss:nothing

	 push	 es		; Save for a moment

	 push	 ds		; Setup for data references
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 call	 DW2HEX 	; Convert AX to hex at ES:DI

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DW2HEX_DS endp			; End DW2HEX_DS procedure

	 NPPROC  HEX2BIN -- Convert string at DS:SI to Hex
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT |
Input:	 DS:SI ==> ASCII string in hex to convert to binary (max. 4 digits)
Output:  AX = binary value
	 SI ==> next character not part of string
	 CF=0 if successful
	 CF=1 if invalid character found
|

	 REGSAVE <bx,cx,dx,di,es> ; Save registers

	 push	 ds		; Get segment for PGROUP
	 pop	 es		; Use ES: for PGROUP
	 assume  es:PGROUP	; Tell the assembler

	 mov	 cx,4		; Maximum number of characters + NULL
	 sub	 bx,bx		; Initial value for BX
	 sub	 ah,ah		; Clear high byte

HEX2BIN_NEXT:
	 lodsb			; Get character in AL

	 mov	 dx,cx		; Save character count

	 lea	 di,HEXTAB	; ES:DI ==> Hex conversion table
	 mov	 cx,HEXTABLEN	; Number of characters in table
   repne scasb			; Izit a hex digit?
	 jne	 short HEX2BIN_DONE ; If not, we're done

	 and	 cx,16-1	; Knock off bit for case
	 mov	 ax,cx		; Put it in AX
	 mov	 cl,4-0 	; Number of bits to shift
	 shl	 bx,cl		; Move previous value over one nybble
	 add	 bx,ax		; Add in new value

	 mov	 cx,dx		; Restore character count

	 loop	 HEX2BIN_NEXT	; Get next character

HEX2BIN_DONE:
	 mov	 ax,bx		; Put return value in AX
	 clc			; Clear CF

HEX2BIN_EXIT:
	 REGREST <es,di,dx,cx,bx> ; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

HEX2BIN endp			; End HEX2BIN procedure

UCODE	 ends			; End UCODE segment
endif				; IF @OEM_MAPMEM

	 MEND			; End UTIL_MA2 module
