;' $Header:   P:/PVCS/MAX/386MAX/QMAX_MEM.ASV   1.4   30 May 1997 10:45:36   BOB  $
	 title	 QMAX_MEM -- 386MAX Memory Calculations
	 page	 58,122
	 name	 QMAX_MEM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Program segment NCODE, byte-aligned,  public, class 'ncode'
	       Data    segment NDATA, dword-aligned, public, class 'ndata'
	       Group XGROUP:
	       Program segment XCODE, byte-aligned,  public, class 'xcode'
	       Data    segment XDATA, dword-aligned, public, class 'xdata'
	       Group YGROUP:
	       Data    segment YDATA, dword-aligned, public, class 'ydata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include 386.INC
	 include PTR.INC
	 include ROMSEG.INC
	 include INTVEC.INC
	 include BIOSDATA.INC

	 include QMAX_OEM.INC
	 include QMAX_CPD.INC
	 include QMAX_EMM.INC
	 include QMAX_FLX.INC
.list

PGROUP	 group	 CODE,ECODE,EDATA,NCODE,NDATA
XGROUP	 group	 XCODE,XDATA
YGROUP	 group	 YDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  ds:PGROUP

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC

	 extrn	 CM4_FLAG:word
	 include QMAX_CM4.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC

	 extrn	 OLDDOS:word
if @OEM_EMS
	 extrn	 EMMSIZE:dword
endif				; IF @OEM_EMS
	 extrn	 VIDSIZE:word
	 extrn	 LOWSIZE:word
	 extrn	 OVRSIZE:word

CODE	 ends			; End CODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 extrn	 DISABLE_NMI:near
	 extrn	 ENABLE_NMI:near

ECODE	 ends			; End ECODE segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

if @OEM_FLEXROM
	 public  FLEXROMINTS	; Resource strucutre for relocating ROMs
FLEXROMINTS	FLEXROMINT_STR	@FLEXROM_RESOURCE_MAX dup (<@FLEX_UNUSED,?>)

	 public  NFLEXROMINTS
NFLEXROMINTS equ ($-FLEXROMINTS)/(type FLEXROMINT_STR) ; # interrupts

	 public  FLEXROMINTS_OFF
FLEXROMINTS_OFF dw	0	; Initiallly point to beginning of table
endif				; IF @OEM_FLEXROM

XDATA	 ends			; End XDATA segment


YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
	 assume  ds:YGROUP

	 extrn	 MSG_NOROOM:byte
ife @OEM_SOFT
	 extrn	 MSG_NOFRAME:byte
endif				; IFE @OEM_SOFT

if @OEM_SYS eq @OEMSYS_RET
	 extrn	 MSG_NOPSMEM:byte
endif				; IF @OEM_SYS eq @OEMSYS_RET

YDATA	 ends			; End YDATA segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 PPMTAB:byte,PPMTAB_LEN:abs
	 include QMAX_PPM.INC

	 extrn	 VIDOFF:dword
	 extrn	 LOWOFF:dword
	 extrn	 SYSROM_START:word
if @OEM_EMS
	 extrn	 FRAME:word
	 extrn	 HFRMLEN:dword
	 extrn	 HFRMSIZE:dword
	 extrn	 @MAX_EHNDLCNT:abs
endif				; IF @OEM_EMS

if @OEM_SYS eq @OEMSYS_RET
	 extrn	 PSMSIZE:word
	 extrn	 PSMWIN:word
	 extrn	 PSMSEG:word
endif				; IF @OEM_SYS eq @OEMSYS_RET

	 public  LCLMEM,LCLMEM_LEN
LCLMEM	 db	 128 dup (?)	; Save area for memory check
LCLMEM_LEN equ	 $-LCLMEM	; Length of ...

	 public  INCSIZE
INCSIZE  dw	 0		; Auto INCLUDE size

if @OEM_EMS
	 public  RPNCURSIZ
RPNCURSIZ dw	 ?		; Size of RPNCUR save area

; The following four DB entries are each padded with a zero
; to enable them to be addressed as a DW entry

	 public  NPHYS16F,NPHYS16S,NPHYSCNV,NPHYSINC,NPHYSSCR
NPHYS16F db	 4,0		; # physical 16KB pages in EMS frame
NPHYS16S db	 4,0		; # physical 16KB pages in EMS system
NPHYSCNV db	 ?,0		; # physical 16KB pages in conventional memory
				; which are initialized with actual memory
				; either original DOS or backfilled memory
NPHYSINC db	 ?,0		; # physical 16KB pages INCLUDEd
NPHYSSCR db	 ?,0		; # physical 16KB pages in SCREEN memory

	 public  @MPPBASE
if @OEM_SYS eq @OEMSYS_ILIM or @OEM_SYS eq @OEMSYS_HPRS
@MPPBASE equ	 256		; Start of Mappable Physical pages in KB
else
@MPPBASE equ	  64		; Start of Mappable Physical pages in KB
endif				; IF @OEM_SYS eq @OEMSYS_ILIM or @OEM_SYS eq @OEMSYS_HPRS
endif				; IF @OEM_EMS

if @OEM_FLEXROM
	 public  FLEXROM_LEN
FLEXROM_LEN	 dw	0	; Length of FlexROM table in bytes

	public	 FLEXROM_TBL	; FLEXROM Table
FLEXROM_TBL	FLEXROM_STR @FLEXROM_ROM_MAX dup (<?>) ; Flex ROM table

	 public  FLEXROM_FLAG,VGA_ALTSEG1,VGA_ALTSEG2
FLEXROM_FLAG dw  0		; FlexROM flags
VGA_ALTSEG1  dw  0		; Alternate (shadowed) location of Video ROM
VGA_ALTSEG2  dw  0		; ...
endif				; IF @OEM_FLEXROM

EDATA	 ends			; End EDATA segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 NRD_FLAG:dword
	 include QMAX_NRD.INC

	 extrn	 MEM_MAP:byte,MEM_MAP_LEN:abs
	 extrn	 @XLAT_ROM0:abs
	 extrn	 @XLAT_ROM1:abs
	 extrn	 @XLAT_ROM2:abs
	 extrn	 @XLAT_DOS:abs
	 extrn	 @XLAT_LOW:abs
	 extrn	 @XLAT_VID:abs
	 extrn	 @XLAT_UNK:abs
	 extrn	 @XLAT_OTH:abs
	 extrn	 @XLAT_OVR:abs
if @OEM_EMS
	 extrn	 @XLAT_EMS:abs
endif				; IF @OEM_EMS
	 extrn	 @XLAT_XLO:abs
	 extrn	 @XLAT_XHI:abs
	 extrn	 @XLAT_INC:abs
	 extrn	 @XLAT_EXC:abs
if @OEM_SYS eq @OEMSYS_RET
	 extrn	 @XLAT_PSM:abs
endif				; IF @OEM_SYS eq @OEMSYS_RET

; The following data values area used instead of constants
; to avoid phantom matches due to "bus capacitance".
; Thanks to Bill Kreuger of Intel for pointing out this problem.

	 public  DROMSIGN, @ROMOFF
@ROMOFF  equ	 1234h
DROMSIGN  dw	 @ROMSIGN-@ROMOFF  ; Data value of @ROMSIGN

NDATA	 ends			; End NDATA segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 SAVE_CACHEPM:far
	 extrn	 REST_CACHEPM:far

	 public  @QMAX_MEM_NCODE
@QMAX_MEM_NCODE:		; Mark module start in .MAP file

if (@OEM_EMS or @OEM_HIFILL) and @OEM_SYS ne @OEMSYS_ILIM
	 FPPROC  CHECK_RAM -- Check For RAM
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if there's RAM in the 512-byte block at BX:0

1.  Save the data in case there's really RAM there.

2.  Store a single value throughout the 512-byte block.

3.  Scan for the stored value and count the # matches.

4.  Restore the values saved in step 1.

5.  To err on the side of conservatism (we don't want to
    mis-identify real RAM), if we find the stored value
    at more than half the positions we'll call it real RAM.

On entry:

BX	 =	 segment to check

On exit:

CF	 =	 1 if RAM present
	 =	 0 if no RAM there

|

	 REGSAVE <ax,cx,dx,si,di,ds,es> ; Save registers

	 cli			; Ensure nobody moves
	 call	 DISABLE_NMI	; Disable NMIs

; 1.  Save the data in case there's really RAM there.

	 mov	 ds,bx		; Put into segment register
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; DS:SI ==> start of 512-byte block

	 push	 seg PGROUP	; Setup ES for string ops
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 di,LCLMEM	; ES:DI ==> local storage area
	 mov	 cx,LCLMEM_LEN/2 ; # words in LCLMEM
S16  rep movsw			; Copy it to local memory

	 mov	 es,bx		; Address the same segment with ES
	 assume  es:nothing	; Tell the assembler about it

; 2.  Store a single value throughout the 512-byte block.

	 mov	 ax,'&!'-1234h  ; Store this
	 add	 ax,1234h	; Add back in to avoid "bus capacitance" problems
	 mov	 cx,LCLMEM_LEN/2 ; # words in LCLMEM
	 xor	 di,di		; Offset of zero
     rep stosw			; Store constant value

; 3.  Scan for the stored value and count the # matches.

	 mov	 cx,LCLMEM_LEN/2 ; # words in LCLMEM
	 xor	 di,di		; Offset of zero
	 xor	 dx,dx		; Zero counter for mismatches
CHECK_RAM_NEXT:
	 jcxz	 CHECK_RAM_REST ; That's all folks
    repe scasw			; Scan for stored value
	 je	 short CHECK_RAM_REST ; No more to search

	 inc	 dx		; Count in a mismatch

	 jmp	 CHECK_RAM_NEXT ; Go around again

; 4.  Restore the values saved in step 1.

CHECK_RAM_REST:
	 push	 seg PGROUP	; Setup DS for MOVSW
	 pop	 ds
	 assume  ds:PGROUP	; Tell the assembler about it

	 lea	 si,LCLMEM	; DS:SI ==> local storage area
	 xor	 di,di		; ES:DI ==> start of 4KB block

	 mov	 cx,LCLMEM_LEN/2 ; # words in LCLMEM
S16  rep movsw			; Copy it from local memory

	 call	 ENABLE_NMI	; Enable NMI, clear the parity latches

	 sti			; Enable interrupts

; 5.  To err on the side of conservatism (we don't want to
;     mis-identify real RAM), if we find the stored value
;     at more than half the positions we'll call it real RAM.

	 cmp	 dx,LCLMEM_LEN/4 ; More than half are mismatches?

; CF = 0 means many mismatches (RAM not present)
; CF = 1 means few  mismatches (RAM	present)

	 REGREST <es,ds,di,si,dx,cx,ax> ; Restore
	 assume  ds:nothing,es:nothing

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_RAM endp			; End CHECK_RAM procedure
endif				; IF (@OEM_EMS or @OEM_HIFILL) and @OEM_SYS ne @OEMSYS_ILIM

NCODE	 ends			; End NCODE segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 public  @QMAX_MEM_XCODE
@QMAX_MEM_XCODE:		; Mark module start in .MAP file

	 extrn	 YMSGOUT2:near
	 extrn	 SAVE_CACHERM:far
	 extrn	 REST_CACHERM:far
	 extrn	 DISP_CPDMSG:far

if @OEM_FLEXROM
	 extrn	 FLEXROM_RESET:near
endif				; IF @OEM_FLEXROM

	 FPPROC  CALC_OVRSIZE -- Calculate OVRSIZE Value
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the value of OVRSIZE by counting the number
of @XLAT_OVR entries.

|

	 REGSAVE <ax,bx,cx,di>	; Save registers

	 xor	 bx,bx		; Zero counter

	 test	 CMD_FLAG,@CMD_XHI ; High filling allowed?
	 jnz	 short CALC_OVRSIZE_EXIT ; No

	 lea	 di,MEM_MAP	; ES:DI ==> start of memory map
	 mov	 cx,MEM_MAP_LEN ; Get # characters in MEM_MAP
	 mov	 al,@XLAT_OVR	; Search for this value
CALC_OVRSIZE_NEXT:
	 jcxz	 CALC_OVRSIZE_EXIT ; Jump if no more entries

   repne scasb			; Search for it
	 jne	 short CALC_OVRSIZE_EXIT ; No more entries

	 inc	 bx		; Count in another entry

	 jmp	 CALC_OVRSIZE_NEXT ; Go around again

; BX has the # 512-byte OVR entries

CALC_OVRSIZE_EXIT:
	 shr	 bx,10-9	; Convert from 512 to 1KB
	 mov	 OVRSIZE,bx	; Save for later use
	 jnz	 short CALC_OVRSIZE_EXIT1 ; Jump if there's something there

	 or	 CMD_FLAG,@CMD_XHI ; Mark as not present
CALC_OVRSIZE_EXIT1:
	 REGREST <di,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_OVRSIZE endp		; End CALC_OVRSIZE procedure
if @OEM_EMS
	 FPPROC  CALC_NPHYS -- Calculate Number of Physical EMS Pages
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate the number of physical pages in low DOS for EMS mapping,
and the size of the entries in the HFRMSAV area.

|

	 REGSAVE <ax,bx,cx,dx,si> ; Save registers

; Calculate # physical pages in all of CNV memory (including LOWSIZE memory)
;			 and in all of EMS system
;			 and in all of INCLUDEd memory

; Calculate # physical 16KB pages in CNV and INCLUDEd memory

	 mov	 bx,LOWOFF.ELO	; Get top of DOS memory
	 add	 bx,LOWSIZE	; Plus added/subtracted low DOS memory
	 shr	 bx,14-10	; Convert from 1KB to 16KB
	 lea	 bx,PPMTAB[bx]	; BX = next entry beyond low DOS memory fill

	 lea	 si,PPMTAB	; DS:SI ==> start of PPMTAB
	 mov	 cx,PPMTAB_LEN	; Get # entries in PPMTAB
	 xor	 dx,dx		; Zero accumulators
				; (DH,DL) = (INC,CNV)
CALC_NPHYS_NEXT:
	 lodsb			; Get next index
	 and	 al,not mask $PPM_SHD ; Remove shadow RAM marker

	 cmp	 al,@PPM_INC	; Izit INCLUDEd?
	 je	 short CALC_NPHYS_INC ; Yes

	 cmp	 al,@PPM_EXC	; Izit EXCLUDEd?
	 je	 short CALC_NPHYS_EXC ; Yes

	 cmp	 al,@PPM_SCR	; Izit SCREEN?
	 je	 short CALC_NPHYS_SCR ; Yes

	 cmp	 al,@PPM_FRM	; Izit in the EMS frame?
	 je	 short CALC_NPHYS_FRM ; Yes

	 cmp	 al,@PPM_CNV	; Izit conventional?
	 jne	 short CALC_NPHYS_LOOP ; No
CALC_NPHYS_CNV:
	 inc	 dl		; Count in another conventional page

	 jmp	 short CALC_NPHYS_LOOP ; Join common code

CALC_NPHYS_FRM:
	 cmp	 NPHYS16F,0	; Any pages supposed to be there?
	 jne	 short CALC_NPHYS_LOOP ; Yes, join common code

	 mov	 al,@PPM_AVL	; Mark as available
	 call	 SAVE_PHYS	; Save as last marker

	 jmp	 short CALC_NPHYS_LOOP ; Join common code

CALC_NPHYS_INC:
	 cmp	 si,bx		; Check against low DOS fill limit
	 ja	 short CALC_NPHYS_INC1 ; It's above that

	 mov	 al,@PPM_CNV	; Mark as conventional
	 call	 SAVE_PHYS	; Save as last marker

	 jmp	 short CALC_NPHYS_CNV ; Join common code

CALC_NPHYS_INC1:
	 inc	 dh		; Count in another INCLUDEd page

	 jmp	 short CALC_NPHYS_LOOP ; Join common code

CALC_NPHYS_EXC:
	 cmp	 si,bx		; Check against low DOS fill limit
	 ja	 short CALC_NPHYS_LOOP ; It's above that

	 mov	 al,@PPM_AVL	; Mark as available
	 call	 SAVE_PHYS	; Save as last marker

	 jmp	 short CALC_NPHYS_LOOP ; Join common code

CALC_NPHYS_SCR:
	 inc	 NPHYSSCR	; Count in another one
CALC_NPHYS_LOOP:
	 loop	 CALC_NPHYS_NEXT ; Jump if more entries

	 mov	 NPHYSCNV,dl	; Save as # physical 16KB pages in CNV memory
				; including backfilled
	 mov	 NPHYSINC,dh	; Save as # physical 16KB pages INCLUDEd

	 add	 dl,dh		; DL = total #
	 add	 dl,NPHYS16F	; Plus # physical 16KB pages in EMS frame
	 add	 dl,NPHYSSCR	; Plus # physical 16KB pages in SCREEN memory
	 mov	 NPHYS16S,dl	; Save as # physical 16KB pages in EMS system

; Calculate the size of the RPNCUR area
; This size is one RPN_STR entry per physical page in the EMS system

	 mov	 al,size RPN_STR ; Size of RPN_STR table entry
	 mul	 NPHYS16S	; Times # entries
	 mov	 RPNCURSIZ,ax	; Save for later use

; Calculate the size of the entries in the HFRMSAV area
; This size is one RPN_STR entry per physical page in the EMS frame
; plus size of the owning handle

	 mov	 al,size RPN_STR ; Size of FRMSAV table entry (without handle)
	 mul	 NPHYS16F	; Times # physical 16KB pages in EMS frame
	 add	 ax,size HFRM_OWNR ; Plus size of owning handle
				; size of an HFRMSAV entry
	 mov	 HFRMLEN.ELO,ax ; Save for later use
	 mov	 ah,@MAX_EHNDLCNT ; Get # entries
	 mul	 ah		; Product is size of entire array
	 mov	 HFRMSIZE.ELO,ax ; Save for later use

	 REGREST <si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_NPHYS endp 		; End CALC_NPHYS procedure
endif				; IF @OEM_EMS
	 NPPROC  SAVE_PHYS -- Save Previous Physical Page Map Marker
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save AL as the previous physical page map marker
keeping any shadow marker flag if present.

On entry:

AL	 =	 @PPM_ marker
DS:SI-1  ==>	 previous PPMTAB entry

|

	 REGSAVE <ax>		; Save register

	 mov	 ah,ds:[si-1]	; Get previous marker
	 and	 ah,mask $PPM_SHD ; Isolate shadow RAM marker
	 or	 al,ah		; Include in marker to save back
	 mov	 ds:[si-1],al	; Save back

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_PHYS endp			; End SAVE_PHYS procedure
if @OEM_EMS
	 NPPROC  FILL_PPM -- Fill In The Physical Page Map
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in the Physical Page Map

|

	 REGSAVE <ax,cx,di>	; Save registers

	 mov	 cx,OLDDOS	; Get top of DOS memory in paras
	 shr	 cx,10-4	; Round down to 1KB
	 add	 cx,LOWSIZE	; Plus added/subtracted low DOS memory in 1KB
	 shr	 cx,14-10	; Convert from 1KB to 16KB

	 mov	 di,@MPPBASE	; Get base of Mappable Physical Pages
	 shr	 di,14-10	; Convert from 1KB to 16KB
	 sub	 cx,di		; Less starting index
	 lea	 di,PPMTAB[di]	; ES:DI ==> start of @MPPBASE in PPMTAB

	 mov	 al,@PPM_CNV	; Marker for conventional pages
     rep stosb			; Fill it in

	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_PPM endp			; End FILL_PPM procedure
endif				; IF @OEM_EMS
	 NPPROC  CHECK_VIDMEM -- Check Out Video Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check out video memory start and length:
In the order in which they are checked...

			 Usual values	 Assumed values
Adapter        In KB	 Para	Length	 Para	Length
------------------------------------------------------
EGA		640	 A000 L 2000	 A000 L 2000
MONO		704	 B000 L  100	 B000 L 1000
CGA		736	 B800 L  800	 B000 L 1000

Note that we are purposely conservative with the above
values in order to reduce tech support calls.  We document
how to override the default settings which then puts the
responsibility more on the user's shoulders.

|

	 REGSAVE <ax,bx>	; Save registers

	 mov	 ax,640 	; Assume EGA present
;;;;;;;; mov	 bx,128 	; Size of EGA memory

	 test	 NRD_FLAG,@NRD_EGA ; EGA present?
	 jnz	 short CHECK_VIDMEM1 ; Yes, so that's all folks

	 mov	 ax,704 	; Assume MDA present
;;;;;;;; mov	 bx,16		; Size of MDA memory

	 test	 NRD_FLAG,@NRD_MDA ; Monochrome adapter present?
	 jnz	 short CHECK_VIDMEM1 ; Yes, so that's all folks

	 mov	 ax,640 	; Must be CGA
;;;;;;;; mov	 ax,704 	; Must be CGA
;;;;;;;; mov	 ax,736 	; Must be CGA
;;;;;;;; mov	 bx,32		; Size of CGA memory
CHECK_VIDMEM1:
	 mov	 VIDOFF.ELO,ax	; Save for later use in 1KB
	 sub	 ax,768 	; Use maximum to C000h
	 neg	 ax
	 mov	 VIDSIZE,ax	; Save as video memory size in 1KB

	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VIDMEM endp		; End CHECK_VIDMEM procedure
	 NPPROC  VGARAM -- Search for VGA ROM
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search for VGA ROM and mark as RAM=xxxx-C800.
We're padding the ROMs to 32 KB because too many video ROMs lie about
their length to be compatible with the original IBM VGA adapter.
Skip this if it's an MCA as the VGA ROM is in E000-10000.

|

	 REGSAVE <ax,bx,cx,dx,si,es>  ; Save registers

	 test	 LCL_FLAG,@LCL_VGA ; Izit a VGA?
	 jz	 near ptr VGARAM_EXIT ; Jump if not

	 test	 LCL_FLAG,@LCL_MCA ; Izit an MCA-compatible machine?
	 jnz	 near ptr VGARAM_EXIT ; Jump if so

	 mov	 bx, 0C000h	; assume default value

	 mov	 ax, seg INTVEC ; Get a seg value for IDT
	 mov	 es, ax 	; Use es for IDT
	 assume  es:INTVEC	; Tell the assembler about it

	 cmp	 INT00_VEC.VSEG[1Fh*(type INT00_VEC)],0E000h ; Izit at E000?
	 je	 short VGARAM_E000 ; Jump if so

	 cmp	 INT00_VEC.VSEG[43h*(type INT00_VEC)],0E000h ; Izit at E000?
	 jne	 short VGARAM_CHECKSEG ; Jump if not
VGARAM_E000:
	 mov	 bx,0E000h	; put in bx
VGARAM_CHECKSEG:
	 mov	 es, bx 	; Address it -- bx contains segment
	 assume  es:ROMSEG	; Tell the assembler about it

; Ensure it's ROM

	 mov	 ax,DROMSIGN	; Get ROM signature
	 add	 ax,@ROMOFF	; Plus offset

	 cmp	 ax,ROMSIGN	; Check for ROM signature
	 jne	 short VGARAM_EXIT ; Jump if not

; ES = Segment of video ROM

; If this is a COMPAQ video ROM, then we can believe the ROM marker

	 CPD	 'Calling CHECK_CPQVID,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 CHECK_CPQVID	; Check for COMPAQ video ROM
	 jc	 short @F	; Jump if it's a COMPAQ video ROM
				; If so, CX = ROM length in bytes/512

	 mov	 cx,32*(1024/512) ; Pad the video ROM to 32 KB
@@:
	 mov	 dx,cx		; Save ROM length for later

; If VGASWAP (or video unshadowing) is active, then use the
; flexrom video source (instead of segment BX)

	 test	 FLEXROM_FLAG,@FR_ACTIVE ; Is FLEXROM active?
	 jz	 short VGARAM_XVGASWAP ; Jump if not

; Find video entry in FLEXROM_TBL (if it exists)

	 xor	 si,si		; Zero index into FlexROM table
@@:
	 test	 FLEXROM_TBL[si].FLEX_FLAG,@FLEXFLAG_VGA ; Izit a video entry?
	 jnz	 short @F	; Jump if so

	 add	 si,@FLEXROM_STRLEN ; point to next entry

	 cmp	 si,FLEXROM_LEN ; More ROMs to process?
	 jb	 short @B	; Jump if more entries

	 jmp	 short VGARAM_XVGASWAP ; None of the entries are video (huh?)

@@:
	 mov	 bx,FLEXROM_TBL[si].FLEX_SRC ; Get Source ROM address

VGARAM_XVGASWAP:

; Address the (source) video ROM within the MEM_MAP table

	 shr	 bx,(9-4)	; Convert paras to 512 bytes
	 lea	 si,MEM_MAP[bx] ; DS:SI ==> memory map in 512-byte blocks

; If we're on a C&T Shadow RAM system, mark the trailing values as ROM
; so we'll cache them

	 mov	 ah,@XLAT_OTH	; Mark as other high DOS memory

	 test	 CM2_FLAG,@CM2_SHD ; Izit AT386 or NEAT shadow RAM?
	 jz	 short VGARAM1_NEXT ; Jump if not

	 mov	 ah,@XLAT_ROM2	; Mark as 2nd or subsequent ROM
VGARAM1_NEXT:
	 lodsb			; Get next character

	 cmp	 al,@XLAT_UNK	; Izit unknown?
	 jne	 short @F	; Jump if not

	 mov	 PGROUP:[si-1].LO,ah ; Mark as ROM or other high DOS memory
@@:
	 loop	 VGARAM1_NEXT	; Jump if more to check

; If there are two video ROMs, we'll have to pad them both becuase
; they both might have active code/data above the 24 KB mark.

	 test	 FLEXROM_FLAG,@FR_SHDROM ; Are there two video ROMs?
	 jz	 short VGARAM_EXIT ; Jump if not

	 shl	 bx,(9-4)	; Convert 512 bytes back to paras

	 mov	 si,VGA_ALTSEG1 ; Get primary/secondary video source address

	 cmp	 bx,si		; Is this the one we padded already?
	 jne	 short @F	; Jump if not

	 mov	 si,VGA_ALTSEG2 ; Get other primary/secondary video address
				; This is the one we have to pad this time
@@:
	 mov	 bx,si		; Move to proper index register

	 shr	 bx,(9-4)	; Convert paras to 512 bytes
	 lea	 si,MEM_MAP[bx] ; DS:SI ==> memory map in 512-byte blocks
	 mov	 cx,dx		; Length of video ROM
;;;;;;;; mov	 ah,??		; Replacement marker is already set

VGARAM2_NEXT:
	 lodsb			; Get next character

	 cmp	 al,@XLAT_UNK	; Izit unknown?
	 jne	 short @F	; Jump if not

	 mov	 PGROUP:[si-1].LO,ah ; Mark as ROM or other high DOS memory
@@:
	 loop	 VGARAM2_NEXT	; Jump if more to check

VGARAM_EXIT:
	 REGREST <es,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VGARAM	 endp			; End VGARAM procedure
	 NPPROC  CHECK_CPQVID -- CHECK_CPQVID Procedure
	 assume  ds:PGROUP,es:ROMSEG,fs:nothing,gs:nothing,ss:nothing

COMMENT |

Check for true COMPAQ video ROM

On true COMPAQ video ROMs, we should trust the video ROM length identifier.
However, we have to tally up the lengths of all ROMs within the first 32 KB
since we can not assume that there is only 1 ROM marker.

Check for specific COMPAQ 386 machines
* Test MAX's system flag for the COMPAQ bit
* Check for COMPAQ video BIOS signature
* Check for COMPAQ specific interrupt handler

On entrance:
ES	=	Segment of video ROM

On exit:
CF	=	0 If it's not a COMPAQ
	=	1 If it's a COMAPQ
CX	=	ROM length in bytes/512 (if on a COMPAQ)
	=	Undefined (if not on a COMPAQ)

|

	 REGSAVE <ax,bx,dx>	; Save registers

; Are we running on a COMAPQ machine?

	 test	 SYS_FLAG,@SYS_CPQ ; Is it a COMPAQ Deskpro 386/486?
	 jz	 short CHECK_CPQVID_XCPQ ; Jump if not

; Are we running with a genuine COMPAQ video board? (signature check)

	 cmp	 [CPQVID_SIG+0].EDD,'PMOC' ; Is it the COMPAQ video signature?
	 jne	 short CHECK_CPQVID_XCPQ ; Jump if not

	 cmp	 [CPQVID_SIG+4].ELO,'QA' ; Is it the COMPAQ video signature?
	 jne	 short CHECK_CPQVID_XCPQ ; Jump if not

; Are we running with a genuine COMPAQ video board? (interrupt check)

; If video BIOS is genuine COMPAQ, CX will return some value guaranteed
; by COMPAQ's video BIOS programmers to be other than FFFF.  This is how
; COMPAQ's own programs determine if there is a genuine COMPAQ video BIOS
; present.

	 REGSAVE <ds,es>	; Save segment registers (a little paranoia)

	 mov	 ax,0BF03h	; COMPAQ Get video environment function
	 xor	 bx,bx		; Unused parameter (should be zero)
	 mov	 cx,-1		; CX will be modified if true COMPAQ video
	 int	 10h		; Call the video BIOS
	 assume  ds:nothing	; Just in case the BIOS screws us
	 assume  es:nothing	; ...
				; Return BH = Active monitor
				;	 BL = Master mode
				;	 CH = 0 (reserved)
				;	 CL = Switchable VDU mode supported
				;	 DH = Internal monitor type
				;	 DL = External monitor type

	 REGREST <es,ds>	; Restore segment registers
	 assume  ds:PGROUP	; Tell the assembler about it
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 cx,-1		; Was anyone home?
	 je	 short CHECK_CPQVID_XCPQ ; Jump if not COMAPQ video BIOS

; Since we're going to trust the ROMLEN value on a COMPAQ,
; and not automatically assume it is a 32 KB ROM, we have to ensure
; that the minimum length includes the secondary ROM (if any)

; If present, the secondary ROM will probably be at C680-C700 (for 2 KB)
; or C680-C800 (for 6 KB)

; Note that if there is a ROM that straddles the 32 KB line,
; we will include its entire length as part of the video ROM.

; ES ==> Primary video ROM

	 xor	 bx,bx		; Initialize offset within 32 KB block

CHECK_CPQVID_NEXT:
	 cmp	 es:[bx].ROMSIGN,@ROMSIGN ; Is it a ROM? (primary or secondary)
	 je	 short CHECK_CPQVID_ROM ; Jump if so

	 add	 bx,16		; Skip to next paragraph

	 jmp	 short @F	; Join common code

CHECK_CPQVID_ROM:
	 movzx	 ax,es:[bx].ROMLEN ; Get BIOS size (in 512 blocks)
	 shl	 ax,(9-0)	; Convert from 512 bytes to bytes

	 add	 bx,ax		; Add ROM size to get new offset
	 mov	 cx,bx		; Tally in another video ROM
@@:
	 cmp	 bx,32*1024	; At end of 32 KB block?
	 jb	 short CHECK_CPQVID_NEXT ; Jump if more to check

; We're on a true COMPAQ video ROM, trust the ROM ID length byte

	 add	 cx,(512-1)	; Round to next 512 boundary
	 shr	 cx,(9-0)	; Convert from bytes to 512 bytes

	 stc			; Indicate we're on a COMPAQ

	 jmp	 short CHECK_CPQVID_EXIT ; Join common exit code

CHECK_CPQVID_XCPQ:
	 clc			; Indicate we're not on a COMPAQ

CHECK_CPQVID_EXIT:
	 REGREST <dx,bx,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPQVID	 endp		; End CHECK_CPQVID procedure
	 FPPROC  FILL_ROM -- Fill ROM Values in MEM_MAP
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

AL	 =	 @XLAT_ROM0 or @XLAT_ROM1
ES:DI	 ==>	 ROM spot in MEM_MAP
CX	 =	 # 512-byte entries to fill in

|

	 REGSAVE <ax,cx,di>	; Save registers

	 jcxz	 FILL_ROM_EXIT	; Nothing to fill in??

;;;;;;;; mov	 al,@XLAT_ROM1	; ROM index for 1st entry
S16	 stosb			; Fill it in

	 dec	 cx		; Account for it
	 mov	 al,@XLAT_ROM2	; ROM index for 2nd and subsequent entry
     rep stosb			; Save in memory map
FILL_ROM_EXIT:
	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_ROM endp			; End FILL_ROM procedure
	 NPPROC  ROMSCAN -- Search For ROM In High Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search for ROMs in high memory and fill in MEM_MAP accordingly.

|

	 REGSAVE <ax,bx,cx,dx,si,di,es> ; Save registers

; Search for ROM in segments C000-SYSROM_START (inclusive) in 512-byte blocks

	 mov	 dx,0C000h	; Start with this segment
ROMSCAN_MORE:
	 mov	 es,dx		; Address it
	 assume  es:ROMSEG	; Tell the assembler about it

	 mov	 ax,DROMSIGN	; Get ROM signature
	 add	 ax,@ROMOFF	; Plus offset

	 cmp	 ax,ROMSIGN	; Check for ROM signature
	 jne	 short ROMSCAN_NEXT ; No match

; On some systems (such as the Dell 316LT laptop), a sequence of
; bytes 55 AA 55 AA ... appears which can confuse us into thinking
; that there's a length 55x200h (47.5KB) ROM there.

	 cmp	 ax,ROMSIGN[2]	; Izit a false positive?
	 je	 short ROMSCAN_NEXT ; Jump if so

; There's a ROM in segment ES (also in DX)

; Confirm that it's really ROM by writing into it
; Too bad some cache controllers allow writes into ROM

;;;;;;;; mov	 cl,ROMLEN	; Get length of ROM in 512-byte blocks
;;;;;;;; not	 cl		; Ensure different value
;;;;;;;; xchg	 cl,ROMLEN	; Swap 'em
;;;;;;;; xchg	 cl,ROMLEN	; Swap 'em
;;;;;;;;
;;;;;;;; cmp	 cl,ROMLEN	; Compare 'em
;;;;;;;; jne	 short ROMSCAN_NEXT ; Jump if it's not ROM
;;;;;;;;
	 movzx	 cx,ROMLEN	; Get length of ROM in 512-byte blocks

	 shl	 cx,9-4 	; Convert from 512 to paras
	 jnz	 short ROMSCAN_NORM ; Jump if normal length

	 cmp	 dx,0E000h	; Check for this segment
	 jne	 short ROMSCAN_NEXT ; Ignore it

	 mov	 cx,64*(1024/16) ; Assume all 64KB used in E000
ROMSCAN_NORM:
	 add	 dx,cx		; Skip to ending segment address
	 shr	 cx,9-4 	; Convert from paras to 512

	 mov	 di,es		; Copy to STOSB register
	 shr	 di,9-4 	; Convert from paras to 512

	 lea	 di,MEM_MAP[di] ; Point to spot within MEM_MAP

	 push	 seg PGROUP	; Setup ES for string ops
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 mov	 al,@XLAT_ROM1	; ROM index for 1st entry
	 call	 FILL_ROM	; Fill in ROM values in MEM_MAP

	 jmp	 short ROMSCAN_NEXT1 ; Join common code

ROMSCAN_NEXT:
	 add	 dx,512/16	; Skip to next 512-byte block
ROMSCAN_NEXT1:
	 cmp	 dx,SYSROM_START ; End of the line?
	 jb	 short ROMSCAN_MORE ; No, go around again

	 push	 seg PGROUP	; Setup DS for string ops
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

; Note in the following test, we're relying on system ROM to be
; on a 64KB boundary at the high end of the first MB

	 mov	 di,SYSROM_START ; Copy to STOSB register
	 xor	 cx,cx		; Initialize as 10000h
	 sub	 cx,di		; Subtract to get length in paras
	 shr	 cx,9-4 	; Convert from paras to 512
ROMSCAN_SYS:
	 push	 di		; Save for a moment

	 shr	 di,9-4 	; Convert from paras to 512
	 lea	 di,MEM_MAP[di] ; Point to spot within MEM_MAP

	 mov	 al,@XLAT_ROM1	; ROM index for 1st entry
	 call	 FILL_ROM	; Fill in ROM values in MEM_MAP

	 pop	 di		; Restore

;;;;;;;; add	 di,1000h	; Skip to next 64KB
;;;;;;;; jnc	 short ROMSCAN_SYS ; More ROM to fill in

; See if there's a ROM at E000

	 push	 0E000h 	; The segment in question
	 pop	 es		; Address it
	 assume  es:ROMSEG	; Tell the assembler about it

	 mov	 ax,DROMSIGN	; Get ROM signature
	 add	 ax,@ROMOFF	; Plus offset

	 cmp	 ax,ROMSIGN	; Check for ROM signature
	 jne	 short ROMSCAN_EXIT ; No match

	 or	 NRD_FLAG,@NRD_E000 ; Mark as ROM at E000
ROMSCAN_EXIT:
	 REGREST <es,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ROMSCAN  endp			; End ROMSCAN procedure
if @OEM_EMS
	 NPPROC  EMMSCAN -- Find Room For EMS Frame
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

See if there's room for the EMS frame.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx,si,di> ; Save registers

; This routine is called before EMMSIZE has been set unless the
; user specified EMS=

	 test	 CMD_FLAG,@CMD_EMS ; Did the user specify EMS=?
	 jz	 short @F	; No, so EMMSIZE is not valid

	 cmp	 EMMSIZE,0	; Using expanded memory?
	 je	 near ptr EMMSCAN_END ; Not this time
@@:
	 test	 CMD_FLAG,@CMD_FRM ; Did the user specify a frame?
	 jnz	 short EMMSCAN_SHORT ; Yes, use it

	 mov	 FRAME,0F000h	; Start at the top
EMMSCAN_SHORT:
	 mov	 cx,NPHYS16F.ELO ; Get # physical 16KB pages in EMS frame
	 shl	 cx,14-9	; Convert from 16KB to 512
	 mov	 bx,FRAME	; Get the frame paragraph #
	 shr	 bx,9-4 	; Convert from paras to 512
EMMSCAN_NEXT:
	 lea	 di,MEM_MAP[bx] ; ES:DI ==> start of EMS frame in MEM_MAP

	 and	 cx,cx		; Check for empty frame
	 jz	 near ptr EMMSCAN2A ; All went well

	 REGSAVE <cx,di>	; Save for a moment
EMMSCAN_NEXTENTRY:
	 mov	 al,es:[di]	; Get current entry
	 inc	 di		; Skip to next entry

	 cmp	 al,@XLAT_DOS	; Izit low DOS memory?
	 je	 short EMMSCAN_NEXT_OK ; Yes, so that's OK

	 cmp	 al,@XLAT_LOW	; Izit low DOS memory fill?
	 je	 short EMMSCAN_NEXT_OK ; Yes, so that's OK

	 cmp	 al,@XLAT_OVR	; Izit high DOS memory?
	 je	 short EMMSCAN_NEXT_OK ; Yes, so that's OK

	 cmp	 al,@XLAT_UNK	; Izit unknown memory?
	 je	 short EMMSCAN_NEXT_OK ; Yes, so that's OK

	 cmp	 al,@XLAT_INC	; Izit INCLUDEd memory?
	 jne	 short EMMSCAN_XENTRY ; Can't use this location
EMMSCAN_NEXT_OK:
	 loop	 EMMSCAN_NEXTENTRY ; Jump if more entries to check

	 cmp	 ax,ax		; Ensure ZF=1
EMMSCAN_XENTRY:
	 REGREST <di,cx>	; Restore
	 jne	 short EMMSCAN_SHIFT ; No luck, shift the frame down

; The frame seems to fit at ES:DI; see if it is in low DOS memory

	 mov	 dx,LOWOFF.ELO	; Get offset of low DOS memory (unit = 1KB)
	 add	 dx,LOWSIZE	; Add in the amount of fill (unit = 1KB)
	 shl	 dx,10-9	; Convert from 1KB to 512-bytes

	 cmp	 bx,dx		; Check against putative FRAME
	 jae	 short EMMSCAN2A ; Jump if it's not in low DOS memory

if @OEM_SYS eq @OEMSYS_HPRS
	 test	 CM3_FLAG,@CM3_LOWFR ; LOWFRAME allowed?
	 jz	 short EMMSCAN_PHYS ; Not this time
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

; Ensure the FRAME doesn't overlap OLDDOS to LOWOFF if non-zero

	 mov	 si,LOWOFF.ELO	; Get top of DOS memory in 1KB
	 shl	 si,10-4	; Convert from 1KB to paras

	 cmp	 si,OLDDOS	; Check against top of low DOS memory in paras
	 je	 short EMMSCAN2B ; Jump if no hole between OLDDOS and LOWOFF+LOWSIZE

; The putative frame overlaps the hole at OLDDOS (with appropriate
; conversions of units of measurement)
; if (FRAME <= LOWOFF) && (OLDDOS <= FRAME+NPHYS16F)
; In this case, we continue looking for a valid FRAME

	 mov	 ax,bx		; Copy to test
	 shl	 ax,9-4 	; Convert from 512-byte to paras

	 mov	 dx,cx		; Copy to test
	 shl	 dx,9-4 	; Convert from 512-byte to paras
	 add	 dx,ax		; Skip to end of frame (in paras)

; SI	 =	 LOWOFF (in paras)
; OLDDOS =	 OLDDOS (in paras)
; AX	 =	 FRAME	(in paras)
; DX	 =	 FRAMEZ (in paras)

	 cmp	 ax,si		; Check FRAME vs. LOWOFF
	 ja	 short EMMSCAN2B ; Jump if no overlap

	 cmp	 OLDDOS,dx	; Check OLDDOS vs. FRAMEZ
	 jbe	 short EMMSCAN_SHIFT ; Jump if there's overlap
EMMSCAN2B:
	 or	 LCL_FLAG,@LCL_LOWFR ; Mark as residing in low DOS memory
	 mov	 dx,LOWOFF.ELO	; Get offset of low DOS memory (unit = 1KB)
	 add	 dx,LOWSIZE	; Add in the amount of fill (unit = 1KB)

	 mov	 ax,bx		; Copy to test
	 shr	 ax,10-9	; Convert from 512-byte to 1KB

	 cmp	 ax,dx		; Use the smaller
	 jae	 short EMMSCAN2A ; Jump if no need to reduce LOWSIZE

	 and	 CMD_FLAG,not @CMD_XLO ; Assume something's there

	 sub	 ax,LOWOFF.ELO	; Less top of DOS memory
	 mov	 LOWSIZE,ax	; Mark as lower DOS memory fill
	 jnz	 short EMMSCAN2A ; Jump if LOWSIZE active

	 or	 CMD_FLAG,@CMD_XLO ; Mark as no lowfill
EMMSCAN2A:
	 jmp	 short EMMSCAN2 ; Join common code

EMMSCAN_SHIFT:
	 test	 CMD_FLAG,@CMD_FRM ; Did the user specify a frame?
if @OEM_SOFT
	 jnz	 short EMMSCAN_PHYS ; Yes, so try with one less physical page
else
	 jnz	 short EMMSCAN_FRMERR ; Yes, so that's an error
endif				; IF @OEM_SOFT

	 sub	 bx,16*(1024/512) ; Back off by 16KB of 512-bytes

	 test	 CM3_FLAG,@CM3_NOFR ; NOFRAME specified?
	 jz	 near ptr EMMSCAN_NEXT ; No, so there's no low limit

	 add	 FRAME,16*1024/16 ; Skip up 16KB in the default frame
EMMSCAN_PHYS:
	 test	 CM3_FLAG,@CM3_NOFR ; Install with no page frame?
	 jz	 short EMMSCAN_XFRM ; Not this time

	 dec	 NPHYS16F	; Try with one less 16KB page in the frame

	 jmp	 EMMSCAN_SHORT	; Go around again

; We found a hole for the EMS page frame
; CX still has the # 512-byte physical pages in the frame

EMMSCAN2:
	 shl	 bx,9-4 	; Convert from 512 to paras
	 mov	 FRAME,bx	; Save as new frame segment

	 mov	 al,@XLAT_EMS	; Fill in with this kind
	 push	 cx		; Save for a moment
     rep stosb			; Consider it filled in
	 pop	 cx		; Restore

; Fill in PPMTAB with @PPM_FRM

	 REGSAVE <cx,di>	; Save registers

	 mov	 di,FRAME	; Get frame segment
	 shr	 di,14-4	; Convert from paras to 16KB
	 lea	 di,PPMTAB[di]	; ES:DI ==> EMS frame in PPMTAB
	 shr	 cx,14-9	; Convert from 512-byte to 16KB
	 jz	 short EMMSCAN3A ; Jump if no page frame
@@:
	 mov	 al,es:[di]	; Get current value
	 and	 al,mask $PPM_SHD ; Isolate shadow RAM marker
	 or	 al,@PPM_FRM	; Mark as EMS page frame entry
S16	 stosb			; Store it back

	 loop	 @B		; Jump if more entries to process
EMMSCAN3A:
	 REGREST <di,cx>	; Restore

;;;;;;;; cmp	 NPHYS16F,4	; Full page frame available?
;;;;;;;; je	 short EMMSCAN3 ; Yes
;;;;;;;;
;;;;;;;; push	 offset YGROUP:MSG_SHORT ; Tell 'em we're a bit short
;;;;;;;; call	 YMSGOUT2	; Display YGROUP message
EMMSCAN3:
	 test	 CMD_FLAG,@CMD_XHI ; High filling allowed?
	 jnz	 short EMMSCAN_END ; Not this time

; Calculate the OVRSIZE value

	 call	 CALC_OVRSIZE	; Count @XLAT_OVR entries
EMMSCAN_END:
	 clc			; Indicate all went well

	 jmp	 short EMMSCAN_EXIT ; Join common exit code

EMMSCAN_XFRM:
	 push	 offset YGROUP:MSG_NOROOM ; Tell 'em the bad news
	 call	 YMSGOUT2	; Display YGROUP message

ife @OEM_SOFT
	 jmp	 short EMMSCAN_ERR ; Join common error code

EMMSCAN_FRMERR:
	 push	 offset YGROUP:MSG_NOFRAME ; Tell 'em the bad news
	 call	 YMSGOUT2	; Display YGROUP message
endif				; IFE @OEM_SOFT
EMMSCAN_ERR:
	 stc			; Indicate something went wrong
EMMSCAN_EXIT:
	 REGREST <di,si,dx,cx,bx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

EMMSCAN  endp			; End EMMSCAN procedure
endif				; IF @OEM_EMS
	 NPPROC  FILL_ALIGN -- Align Fill Elements in MEM_MAP
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure that the ROM and OVR entries are properly
aligned on 4KB boundaries (16KB if SHADOWRAM system).

If any entry is unaligned, remove it by marking it
as "other" RAM.

The code which swaps ROM with fast RAM requires they be on a 4KB
boundary and be a multiple of 4KB (the ubiquitous page size).

Were we to swap ROM into RAM we must swap a multiple of 4KB.
If the ROM isn't on such a boundary and length, we might swap RAM
into RAM with some potential conflict if the RAM is special memory
on an installed board (like video memory is).

The granularity of the CHIPset is 16KB, so if are on such a system,
we must use a coarser unit.

|

	 REGSAVE <ax,dx>	; Save registers

; First check OVR entries

	 mov	 dx,(4*1024/512)-1 ; Use 4KB alignment
	 mov	 al,@XLAT_OVR	; Search for this first
	 mov	 ah,@XLAT_OVR	; Search for this second
	 call	 CHK_ALIGN	; Align to 4KB boundary

	 test	 CM2_FLAG,@CM2_SHD ; Izit AT386 or NEAT shadow RAM?
	 jz	 short @F	; Not this time

	 mov	 dx,(16*1024/512)-1 ; It's to be 16KB alignment
@@:

; Next check ROM entries

	 mov	 al,@XLAT_ROM1	; Search for this first
	 mov	 ah,@XLAT_ROM2	; Search for this second
	 call	 CHK_ALIGN	; Align to 4KB boundary

	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_ALIGN endp 		; End FILL_ALIGN procedure
	 NPPROC  CHK_ALIGN -- Check on MEM_MAP Alignment
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Ensure certain MEM_MAP entries are aligned.

On entry:

AL	 =	 1st character to search for
AH	 =	 2nd character to search for
DX	 =	 alignment mask

|

	 REGSAVE <bx,cx,dx,di>	; Save registers

	 lea	 di,MEM_MAP	; ES:DI ==> start of memory map
	 mov	 cx,MEM_MAP_LEN ; Get # characters in MEM_MAP
CHK_ALIGN_NEXT:
;;;;;;;; jcxz	 CHK_ALIGN_EXIT ; No more to search
	and	cx,cx		; Any more to search?
	jz	near ptr CHK_ALIGN_EXIT ; Jump if not

   repne scasb			; Search for it
	 jne	 short CHK_ALIGN_EXIT ; No more found

; Fill in leading entries to a 4KB boundary with @XLAT_OTH

	 REGSAVE <cx,di>	; Save for a moment

	 dec	 di		; Back up to last mismatch
;;;;;;;; inc	 cx		; Account for it

	 mov	 bx,di		; Copy starting offset
	 sub	 bx,offset es:MEM_MAP ; Convert to origin-0

	 lea	 cx,[bx+(4*1024/512)-1] ; Round up to 4KB boundary
	 and	 cx,not ((4*1024/512)-1) ; Round down
	 sub	 cx,bx		; Less starting point to get length

	 push	 ax		; Save for a moment
	 mov	 al,@XLAT_OTH	; Fill with this
     rep stosb			; Fill it up
	 pop	 ax		; Restore

	 cmp	 ah,es:[di]	; Is the next one in the same sequence?
	 jne	 short @F	; No, continue on

S16	 stosb			; Mark as starting byte
@@:
	 REGREST <di,cx>	; Restore
CHK_ALIGN_NEXT1:
	 mov	 bx,di		; Copy starting offset
	 sub	 bx,1+offset es:MEM_MAP ; Convert to origin-0

	 test	 bx,dx		; Ensure it's aligned
	 jz	 short CHK_ALIGN_TAIL ; It's OK, check the tail

; Fill in this entry with @XLAT_OTH unless specified in a USE= statement.

	 call	 MARK_ALIGN	; Mark as other unless in use

	 jcxz	 CHK_ALIGN_EXIT ; No more to search

	 cmp	 ah,es:[di]	; Is the next one in the same sequence?
	 jne	 short CHK_ALIGN_NEXT ; No, continue on

S16	 stosb			; Mark as starting byte
	 loop	 CHK_ALIGN_NEXT1 ; Go around again
CHK_ALIGN_TAIL:
	 jcxz	 CHK_ALIGN_EXIT ; No more to search
	 xchg	 al,ah		; Swap with second entry
    repe scasb			; Search for more of same
	 xchg	 al,ah		; Swap with second entry
	 je	 short CHK_ALIGN_EXIT ; All the same, must be on 4/16KB boundary

	 cmp	 al,es:[di-1]	; Does it abut other RAM/ROM of the same type?
	 je	 short CHK_ALIGN_TAIL ; Yes, continue on

	 dec	 di		; Back up to last mismatch
	 inc	 cx		; Account for it

	 mov	 bx,di		; Copy ending offset
	 sub	 bx,offset es:MEM_MAP ; Convert to origin-0

; BX contains the offset from the start of MEM_MAP of the byte
; immediately following the end of the searched-for entry

; If NOCRR is in effect and we're aligning ROMs,
; don't fill in trailing ROM residues with @XLAT_OTH

	cmp	al,@XLAT_ROM1	; Izit ROM start?
	jne	short @F	; Jump if not

	test	CM4_FLAG,@CM4_NOCRR ; Is NOCRR in effect?
	jnz	short CHK_ALIGN_NEXT ; Jump if so
@@:

; Fill in trailing entries to a 4KB boundary with @XLAT_OTH

	 REGSAVE <ax,cx,di>	; Save for a moment

	 mov	 cx,bx		; Copy offset
	 and	 cx,not ((4*1024/512)-1) ; Round down to 4KB boundary
	 sub	 cx,bx		; Less starting point to get negative of length
	 neg	 cx		; Negate to get positive length

	 dec	 di		; Back up to last entry
	 std			; String ops backwards
	 mov	 al,@XLAT_OTH	; Fill with this
     rep stosb			; Fill it up
	 cld			; String ops forwards

	 REGREST <di,cx,ax>	; Restore
CHK_ALIGN_TAIL1:
	 test	 bx,dx		; Ensure it's on a 4/16KB boundary
	 jz	 short CHK_ALIGN_NEXT ; It's OK, check the next entry

; Fill in this entry with @XLAT_OTH unless specified in a USE= statement.

	 dec	 bx		; Back up to previous entry
	 call	 MARK_ALIGN	; Mark as other unless in use

	 jmp	 CHK_ALIGN_TAIL1 ; Go around again

CHK_ALIGN_EXIT:
	 REGREST <di,dx,cx,bx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHK_ALIGN endp			; End CHK_ALIGN procedure
	 NPPROC  MARK_ALIGN -- Mark Aligned Entries
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mark aligned entries

Note we don't just blast in an other RAM marker in case there
is a USE= statement covering that area.  The code in CALC_PPMTAB
will ensure that the shadow RAM underneath won't be recovered
unless the entire 16KB block is available.

On entry:

BX	 =	 offset into MEM_MAP of entry to mark as other

|

	 cmp	 MEM_MAP[bx],@XLAT_OVR ; Izit part of a USE= statement?
	 je	 short @F	; Jump if so

	 mov	 MEM_MAP[bx],@XLAT_OTH ; Unmark it
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

MARK_ALIGN endp 		; End MARK_ALIGN procedure
	 NPPROC  CALC_PPMTAB -- Cleanup PPMTAB
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in PPMTAB entries for shadow RAM.

If both RAM and ROM occur in a 16KB block, don't use as shadow RAM.

|

	 REGSAVE <ax,cx,dx,si,di> ; Save registers

@AT386SEG equ	 16*(0A000h/512) ; Start of search in 512-byte blocks

	 lea	 di,MEM_MAP[@AT386SEG] ; ES:DI ==> memory map in 512-byte blocks
	 mov	 cx,MEM_MAP_LEN-@AT386SEG ; CX = # chars in MEM_MAP to search
	 sub	 cx,64*(1024/512) ; Less the ROM BIOS segment
	 shr	 cx,14-9	; Convert from 512-byte to 16KB
CALC_PPMTAB_NEXT:
	 push	 cx		; Save over inner loop

; First see if there's any RAM in the block

	 mov	 cx,16*1024/512 ; CX = # 512-byte chars in 16KB

	 mov	 al,@XLAT_OTH	; RAM marker
	 REGSAVE <cx,di>	; Save for a moment
   repne scasb			; Search for it
	 REGREST <di,cx>	; Restore
	 je	 near ptr CALC_PPMTAB_RAM ; Yes, there's some RAM there

; Next see if the region has already been EXCLUDEd,
; in which case we treat it as RAM

	 mov	 al,@XLAT_EXC	; EXCLUDEd marker
	 REGSAVE <cx,di>	; Save for a moment
   repne scasb			; Search for it
	 REGREST <di,cx>	; Restore
	 je	 near ptr CALC_PPMTAB_RAM ; Yes, there's some RAM there

; Next see if the region has video RAM

	 mov	 al,@XLAT_VID	; Video RAM marker
	 REGSAVE <cx,di>	; Save for a moment
   repne scasb			; Search for it
	 REGREST <di,cx>	; Restore
	 je	 near ptr CALC_PPMTAB_RAM ; Yes, there's some RAM there

; Next see if the region is part of a FLEXROM source
; If so, we can't recover as shadow RAM

if @OEM_FLEXROM
	 REGSAVE <ax,bx,di>	; Save registers

	 test	 FLEXROM_FLAG,@FR_ACTIVE ; Is FLEXROM active?
	 jz	 short CALC_PPMTAB_FLEXEXIT ; Jump if not (Note: CF=0)

	 xor	 bx,bx		; Initialize index into FLEXROM_TBL

	 sub	 di,offset PGROUP:MEM_MAP ; Get number of units into MEM_MAP
	 shl	 di,(9-4)	; Convert 512 bytes to paras

CALC_PPMTAB_FLEXNEXT:
	 mov	 ax,FLEXROM_TBL[bx].FLEX_SRC ; Get start of FLEXROM entry
	 and	 ax,not ((1 shl (14-4))-1) ; Round down para to 16KB

	 cmp	 di,ax		; Is ROM start below MEM_MAP entry?
	 jb	 short CALC_PPMTAB_FLEXLOOP ; Jump if below

	 mov	 ax,FLEXROM_TBL[bx].FLEX_LEN ; Get ROM length (/4KB)
	 shr	 ax,(4-0)	; Convert from bytes to paras
	 add	 ax,FLEXROM_TBL[bx].FLEX_SRC ; Add source to get ending para

	 cmp	 di,ax		; Is ROM ending above MEM_MAP entry?
	 jb	 short CALC_PPMTAB_FLEXEXIT ; Jump if not (Note CF=1)

CALC_PPMTAB_FLEXLOOP:
	 add	 bx,@FLEXROM_STRLEN ; Bump up to next entry

	 cmp	 bx,FLEXROM_LEN ; Any more entries?
	 jb	 short CALC_PPMTAB_FLEXNEXT ; Jump if more FLEXROM entries
				; Note: CF=0

CALC_PPMTAB_FLEXEXIT:
	 REGREST <di,bx,ax>	; Restore registers
	 jc	 short CALC_PPMTAB_LOOP ; Try next entry in MEMMAP
endif				; IF @OEM_FLEXROM

; Next see if the region has normal ROM when we're excluding ROM

	 test	 CMD_FLAG,@CMD_XRM ; NOROM specified?
	 jnz	 short CALC_PPMTAB_XRM ; Yes

	 test	 CM2_FLAG,@CM2_ROM ; ROM= specified?
	 jz	 short CALC_PPMTAB_ROM ; No, mark as shadow RAM
CALC_PPMTAB_XRM:
	 mov	 al,@XLAT_ROM1	; Normal ROM marker
	 REGSAVE <cx,di>	; Save for a moment
   repne scasb			; Search for it
	 REGREST <di,cx>	; Restore
	 je	 short CALC_PPMTAB_RAM ; Yes, there's some ROM there

; We are not handling the case where the ROM overlaps into the next
; 16KB block *FIXME*

	 jmp	 short CALC_PPMTAB_SHD ; Mark as shadow RAM

; If there's ROM in this block, set @PPM_ROM

CALC_PPMTAB_ROM:
	 mov	 al,@XLAT_ROM2	; 2nd and subsequent ROM marker
	 REGSAVE <cx,di>	; Save for a moment
   repne scasb			; Search for it
	 REGREST <di,cx>	; Restore
	 jne	 short CALC_PPMTAB_SHD ; Not this time

	 mov	 si,di		; Copy address in MEM_MAP
	 sub	 si,offset ds:MEM_MAP ; Convert to origin-0
	 shr	 si,9-4 	; Convert from 512-byte to 16KB

	 cmp	 PPMTAB[si],@PPM_EXC ; Already EXCLUDEd?
	 je	 short CALC_PPMTAB_LOOP ; Yes, so skip it

	 mov	 PPMTAB[si],@PPM_ROM ; Mark as some ROM
CALC_PPMTAB_SHD:
	 mov	 si,di		; Copy address in MEM_MAP
	 sub	 si,offset ds:MEM_MAP ; Convert to origin-0
	 shr	 si,9-4 	; Convert from 512-byte to 16KB

	 cmp	 PPMTAB[si],@PPM_EXC ; Already EXCLUDEd?
	 je	 short CALC_PPMTAB_LOOP ; Yes, so skip it

	 or	 PPMTAB[si],mask $PPM_SHD ; Mark as available for shadow RAM

;;;;;;;; jmp	 short CALC_PPMTAB_LOOP ; Join common loop code

CALC_PPMTAB_RAM:
CALC_PPMTAB_LOOP:
	 pop	 cx		; Restore

	 add	 di,16*1024/512 ; Skip to next 16KB block

	 dec	 cx		; One more 16KB block processed
	 jnz	 near ptr CALC_PPMTAB_NEXT ; Jump if more left

	 REGREST <di,si,dx,cx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_PPMTAB endp		; End CALC_PPMTAB procedure
	 NPPROC  FILL_LOW -- Fill MEM_MAP With LOW
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in MEM_MAP memory map with DOS low memory

|

	 REGSAVE <ax,cx,si,di>	; Save registers

	 test	 CMD_FLAG,@CMD_XLO ; Are we allowed to fill in low DOS memory?
	 jnz	 short FILL_LOW_HIGH ; No

	 mov	 al,@XLAT_LOW	; DOS low memory added
	 lea	 di,MEM_MAP	; ES:DI ==> start of memory map
	 mov	 cx,LOWOFF.ELO	; Get old top of DOS (unit = 1KB)
	 shl	 cx,10-9	; Convert from 1KB to 512
	 add	 di,cx		; Move to that point
	 mov	 cx,LOWSIZE	; Get the amount (unit = 1KB)

	 cmp	 cx,0		; Check the sign
	 jle	 short @F	; Jump if nothing to fill

	 shl	 cx,10-9	; Convert from 1KB to 512
     rep stosb			; Save in diagram
@@:
	 mov	 si,LOWOFF.ELO	; Get top of DOS memory in 1KB
	 shr	 si,14-10	; Convert from 1KB to 16KB
	 lea	 si,PPMTAB[si]	; DS:SI ==> start of LOWOFF in PPMTAB

	 mov	 cx,LOWSIZE	; Get size of low DOS memory fill

	 cmp	 cx,0		; Check the sign
	 jle	 short FILL_LOW_EXIT ; Jump if nothing to fill

	 shr	 cx,14-10	; Convert from 1KB to 16KB
	 jz	 short FILL_LOW_EXIT ; Jump if nothing to fill
FILL_LOWPPM_NEXT:
	 lodsb			; Get next marker
	 mov	 ah,al		; Copy original value
	 and	 al,not mask $PPM_SHD ; Clear shadow RAM marker

	 cmp	 al,@PPM_AVL	; Izit available?
	 jne	 short FILL_LOWPPM_LOOP ; Not this time

	 and	 ah,mask $PPM_SHD ; Isolate shadow RAM marker
	 mov	 al,@PPM_CNV	; Conventional marker
	 or	 al,ah		; Include shadow RAM Marker
	 mov	 ds:[si-1],al	; Mark it as conventional
FILL_LOWPPM_LOOP:
	 loop	 FILL_LOWPPM_NEXT ; Jump if more pages to check

	 jmp	 short FILL_LOW_EXIT ; Join common exit code

; If there's UNK memory at 640KB, mark it as OVR memory

FILL_LOW_HIGH:
	 test	 CMD_FLAG,@CMD_XHI ; Are we allowed to fill in high DOS memory?
	 jnz	 short FILL_LOW_EXIT ; No, so skip all this

	 lea	 di,MEM_MAP[640*(1024/512)] ; ES:DI ==> 640KB in MEM_MAP
	 mov	 cx,128 shl (10-9) ; CX = maximum length of region in 512-bytes
	 mov	 al,@XLAT_UNK	; Search for this one
FILL_LOW_NEXT:
	 jcxz	 FILL_LOW_EXIT	; No more entries
   repne scasb			; Look for UNK entries
	 jne	 short FILL_LOW_EXIT ; No more found

	 mov	 PGROUP:[di-1].LO,@XLAT_OVR ; Mark as high DOS memory

	 jmp	 FILL_LOW_NEXT	; Go around again

FILL_LOW_EXIT:
	 REGREST <di,si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_LOW endp			; End FILL_LOW procedure
	 NPPROC  FILL_XLO -- Fill MEM_MAP With XLO
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If NOLOW specified, set unknown entries in MEM_MAP
below VIDOFF to XLO.

|

	 REGSAVE <ax,cx,di>	; Save registers

	 test	 CMD_FLAG,@CMD_XLO ; Low filling allowed?
	 jz	 short FILL_XLO_EXIT ; Yes

	 lea	 di,MEM_MAP	; ES:DI ==> start of MEM_MAP
	 mov	 cx,VIDOFF.ELO	; CX = start of video buffers in 1KB
	 shl	 cx,10-9	; Convert from 1KB to 512-byte
	 mov	 al,@XLAT_UNK	; Search for this one
FILL_XLO_NEXT:
	 jcxz	 FILL_XLO_EXIT	; No more entries
   repne scasb			; Look for UNK entries
	 jne	 short FILL_XLO_EXIT ; No more found

	 mov	 PGROUP:[di-1].LO,@XLAT_XLO ; Mark as excised low memory

	 jmp	 FILL_XLO_NEXT	; Go around again

FILL_XLO_EXIT:
	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_XLO endp			; End FILL_XLO procedure
	 NPPROC  FILL_XHI -- Fill MEM_MAP With XHI
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If NOHIGH specified, remove OVR entries in MEM_MAP.

|

	 REGSAVE <ax,cx,di>	; Save registers

	 test	 CMD_FLAG,@CMD_XHI ; High filling allowed?
	 jz	 short FILL_XHI_EXIT ; Yes

	 mov	 OVRSIZE,0	; No, hence the size is zero

	 lea	 di,MEM_MAP	; ES:DI ==> start of MEM_MAP
	 mov	 cx,MEM_MAP_LEN ; CX = # entries in MEM_MAP
	 mov	 al,@XLAT_OVR	; Search for this one
FILL_XHI_NEXT:
	 jcxz	 FILL_XHI_EXIT	; No more entries
   repne scasb			; Look for OVR entries
	 jne	 short FILL_XHI_EXIT ; Join common exit code

	 mov	 PGROUP:[di-1].LO,@XLAT_XHI ; Mark as excised high memory

	 jmp	 FILL_XHI_NEXT	; Go around again

FILL_XHI_EXIT:
	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_XHI endp			; End FILL_XHI procedure
	 NPPROC  FILL_INC -- Fill MEM_MAP With INC
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If auto INCLUDE specified, change OVR and XHI entries
in MEM_MAP to INC entries.

|

	 REGSAVE <ax,cx,dx,si,di> ; Save registers

	 mov	 dx,INCSIZE	; Get auto INCLUDE value

	 and	 dx,dx		; Any value specified?
	 jz	 short FILL_INC_EXIT ; No

	 lea	 si,MEM_MAP	; DS:SI ==> start of MEM_MAP
	 mov	 cx,MEM_MAP_LEN ; CX = # entries in MEM_MAP
FILL_INC_NEXT:
	 lodsb			; Get next character

	 cmp	 al,@XLAT_OVR	; Izit high DOS memory?
	 je	 short FILL_INC_OVR ; Yes

	 cmp	 al,@XLAT_XHI	; Izit excised high DOS memory?
	 jne	 short FILL_INC_LOOP ; No
FILL_INC_OVR:

; Ensure that this entry is on 16 KB boundary

	 mov	 di,si		; Copy to test
	 sub	 di,1+offset ds:MEM_MAP ; Convert to origin-0

	 test	 di,(16*1024/512)-1 ; Ensure all zero
	 jnz	 short FILL_INC_LOOP ; Not this time

; Ensure that this entry is followed by 16KB/512 of the same values

	 push	 cx		; Save for a moment
	 mov	 di,si		; Copy to SCASB register
	 mov	 cx,(16*1024/512)-1 ; # entries which must be the same
    repe scasb
	 pop	 cx		; Restore
	 jne	 short FILL_INC_LOOP ; Not this time

; Mark the entry in PPMTAB as INCLUDEd

	 mov	 di,si		; Copy to index register
	 sub	 di,1+offset ds:MEM_MAP ; Convert to origin-0
	 shr	 di,14-9	; Convert from 512-byte to 16KB

	 mov	 al,PPMTAB[di]	; Get current value
	 and	 al,mask $PPM_SHD ; Isolate shadow RAM marker
	 add	 al,@PPM_INC	; Mark as INCLUDEd
	 mov	 PPMTAB[di],al	; Save back

; Mark the entries in MEM_MAP as INCLUDEd

	 mov	 al,@XLAT_INC	; The new marker
	 push	 cx		; Save for a moment
	 mov	 di,si		; Copy to SCASB register
	 dec	 di		; Back off to starting entry
	 mov	 cx,16*1024/512 ; Entry count
     rep stosb			; Store new marker
	 pop	 cx		; Restore

	 sub	 dx,16		; Account for 16KB
	 jbe	 short FILL_INC_EXIT ; Jump if nomore entries to fill in
FILL_INC_LOOP:
	 loop	 FILL_INC_NEXT	; Jump if more
FILL_INC_EXIT:
	 REGREST <di,si,dx,cx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_INC endp			; End FILL_INC procedure
if @OEM_SYS eq @OEMSYS_RET
	 NPPROC  FILL_PSM -- Fill MEM_MAP With PSM Entries
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If PSMEM is specified, change PSMWIN consecutive OVR or UNK entries
in MEM_MAP to PSM entries.

|

	 REGSAVE <ax,cx,dx,si,di> ; Save registers

	 cmp	 PSMWIN,0	; Izit specified?
	 je	 near ptr FILL_PSM_EXIT ; No

	 lea	 si,MEM_MAP	; DS:SI ==> start of MEM_MAP
	 mov	 cx,MEM_MAP_LEN ; CX = # entries in MEM_MAP

; If the user has requested a specific segment into which the PSM
; memory should be mapped, handle that now

	 cmp	 PSMSEG,0	; Izit specified?
	 je	 short FILL_PSM_NEXT ; Jump if not

	 mov	 cx,1		; We get only one chance
	 mov	 si,PSMSEG	; Get segment to use
	 shr	 si,9-4 	; Convert from paras to 512 bytes
	 lea	 si,MEM_MAP[si] ; Plus start of MEM_MAP
FILL_PSM_NEXT:
	 lodsb			; Get next character

	 cmp	 al,@XLAT_OVR	; Izit high DOS memory?
	 je	 short FILL_PSM_OVR ; Yes

	 cmp	 al,@XLAT_UNK	; Izit unknown memory?
	 jne	 short FILL_PSM_LOOP ; No
FILL_PSM_OVR:

; Ensure that this entry is on 4 KB boundary

	 mov	 di,si		; Copy to test
	 sub	 di,1+offset ds:MEM_MAP ; Convert to origin-0

	 test	 di,(4*1024/512)-1 ; Ensure all zero
	 jnz	 short FILL_PSM_LOOP ; Not this time

; Ensure that this entry is followed by PSMWIN of the same values

	 push	 cx		; Save for a moment
	 lea	 di,[si-1]	; Copy starting address to SCASB register
	 mov	 cx,PSMWIN	; Get size of PSM window in 1KB (/4KB)
	 shl	 cx,10-9	; Convert from 1KB to 512 bytes
    repe scas	 MEM_MAP[di]	; Search for it
	 pop	 cx		; Restore
	 jne	 short FILL_PSM_LOOP ; Not this time

; Mark the entry in PPMTAB as available

	 mov	 di,si		; Copy to index register
	 sub	 di,1+offset ds:MEM_MAP ; Convert to origin-0
	 shr	 di,14-9	; Convert from 512-byte to 16KB

	 mov	 al,PPMTAB[di]	; Get current value
	 and	 al,mask $PPM_SHD ; Isolate shadow RAM marker
	 add	 al,@PPM_AVL	; Mark as available
	 mov	 PPMTAB[di],al	; Save back

; Mark the entries in MEM_MAP as PSM

	 lea	 di,[si-1]	; Copy starting address to SCASB register
	 mov	 cx,PSMWIN	; Get size of PSM window in 1KB (/4KB)
	 shl	 cx,10-9	; Convert from 1KB to 512 bytes
	 mov	 al,@XLAT_PSM	; The new marker
     rep stosb			; Store new marker

	 mov	 ax,si		; Copy starting address+1
	 sub	 ax,1+offset ds:MEM_MAP ; Convert to origin-0 in 512 bytes
	 shl	 ax,9-4 	; Convert from 512 bytes to paras
	 mov	 PSMSEG,ax	; Save for later use

	 jmp	 short FILL_PSM_EXIT ; Join common exit code

FILL_PSM_LOOP:
	 loop	 FILL_PSM_NEXT	; Jump if more

	 mov	 PSMWIN,0	; Mark as not found
	 mov	 PSMSIZE,0	; Mark as not found

	 push	 offset YGROUP:MSG_NOPSMEM ; Get offset of error message
	 call	 YMSGOUT2	; Display YGROUP message
FILL_PSM_EXIT:
	 REGREST <di,si,dx,cx,ax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_PSM endp			; End FILL_PSM procedure
endif				; IF @OEM_SYS eq @OEMSYS_RET
	 NPPROC  CALC_MEMMAP -- Clean Up MEM_MAP
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Mark excluded areas below LOWOFF+LOWSIZE as conventional memory.

|

	 REGSAVE <ax,bx,cx,di>	; Save registers

	 mov	 bx,LOWOFF.ELO	; Get top of original DOS memory
	 add	 bx,LOWSIZE	; Plus added/subtracted low DOS memory
	 shl	 bx,10-9	; Convert from 1KB to 512-byte
	 lea	 bx,MEM_MAP[bx] ; Point to place within MEM_MAP
	 lea	 di,MEM_MAP	; ES:DI ==> MEM_MAP
	 mov	 cx,MEM_MAP_LEN ; Get # characters in MEM_MAP
	 mov	 al,@XLAT_EXC	; Search for this
CALC_MEMMAP_NEXT:
	 jcxz	 CALC_MEMMAP_EXIT ; That's all folks
   repne scasb			; Search for EXCLUDEd memory
	 jne	 short CALC_MEMMAP_EXIT ; No more characters

	 cmp	 di,bx		; Check against upper limit
	 ja	 short CALC_MEMMAP_EXIT ; Out of range

	 mov	 es:[di-1].LO,@XLAT_DOS ; Mark as existing DOS memory

	 jmp	 short CALC_MEMMAP_NEXT ; Go around again

CALC_MEMMAP_EXIT:
	 REGREST <di,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_MEMMAP endp		; End CALC_MEMMAP procedure
	 FPPROC  FILL_MAP -- Fill In Initial MEM_MAP Entries
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Fill in initial MEM_MAP entries:

DOS original memory
Video memory
ROM
Other RAM

Check for and handle special AST ROM

|

	 REGSAVE <ax,cx,di>	; Save registers

; Fill in MEM_MAP memory map with DOS main memory

	 lea	 di,MEM_MAP	; ES:DI ==> start of memory map
	 mov	 al,@XLAT_DOS	; DOS memory already present
	 mov	 cx,LOWOFF.ELO	; Get old top of DOS (unit = 1KB)
	 shl	 cx,10-9	; Convert from 1KB to 512
     rep stosb			; Save in diagram

; Fill in MEM_MAP memory map with video memory

	 call	 CHECK_VIDMEM	; Check out video memory present
				; This fills in VIDOFF and VIDSIZE

	 mov	 al,@XLAT_VID	; Video memory
	 lea	 di,MEM_MAP	; ES:DI ==> start of memory map
	 mov	 cx,VIDOFF.ELO	; Get start of video memory (unit = 1KB)
	 shl	 cx,10-9	; Convert from 1KB to 512
	 add	 di,cx		; Move to that point
	 mov	 cx,VIDSIZE	; Get the amount (unit = 1KB)
	 shl	 cx,10-9	; Convert from 1KB to 512
     rep stosb			; Save in diagram

; Fill in MEM_MAP memory map with ROM

	 CPD	 'Calling ROMSCAN,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 ROMSCAN	; Fill in ROM values

; Some ASTs (the Premium 386/25 in particular) contain a 64 KB BIOS
; at E000.  All of it is filler except for the 16 byte signature.
; If this signature is present, recover 64KB at E000.
; Note: This recovery is performed here (instead of in CHECK_AST),
;	so that CHECK_ARGS may override this default behavior.

	 REGSAVE <ax,si,fs>	; Save registers

	 mov	 ax,0E000h	; Address the alleged BIOS
	 mov	 fs,ax		; ... via ES
	 assume  fs:nothing	; Tell the assembler about it

	 cmp	 fs:[0].EDD,0CB80AA55h ; Izit the expected signature?
	 jne	 short FILLMAP_NOTAST ; Jump if not

	 cmp	 fs:[4].EDD,'STSA' ; Izit the expected signature?
	 jne	 short FILLMAP_NOTAST ; Jump if not

	 cmp	 fs:[8].EDD,'ODAH' ; Izit the expected signature?
	 jne	 short FILLMAP_NOTAST ; Jump if not

	 cmp	 fs:[0Ch].EDD,'MARW' ; Izit the expected signature?
	 jne	 short FILLMAP_NOTAST ; Jump if not

	 lea	 si,MEM_MAP[16*(0E000h/512)] ; ES:DI ==> memory map in 512-byte blocks
	 mov	 cx,(64*1024/512) ; Get number of MEM_MAP characters to convert

FILLMAP_AST_NEXT:
	 lodsb			; Pick up MEM_MAP marker

	 cmp	 al,@XLAT_ROM1	; Marked as primary ROM?
	 je	 short FILLMAP_AST_CHANGE ; Jump if so

	 cmp	 al,@XLAT_ROM2	; Marked as secondary ROM?
	 jne	 short FILLMAP_AST_LOOP ; No, try next MEMMAP netry

FILLMAP_AST_CHANGE:
	 mov	 PGROUP:[si-1].LO,@XLAT_OVR ; Mark as High DOS

FILLMAP_AST_LOOP:
	 loop	 FILLMAP_AST_NEXT ; Try next MEM_MAP marker

FILLMAP_NOTAST:
	 REGREST <fs,si,ax>	; Restore registers
	 assume  fs:nothing	; Tell the assembler about it

if @OEM_EMS
	 CPD	 'Calling FILL_PPM,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 FILL_PPM	; Fill in the Physical Page Map
endif				; IF @OEM_EMS

	 REGREST <di,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FILL_MAP endp			; End FILL_MAP procedure
if (@OEM_EMS or @OEM_HIFILL) and @OEM_SYS ne @OEMSYS_ILIM
	 NPPROC  RAMSCAN -- Search For RAM In High Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If high DOS memory or EMS page frame needed,
search for RAM in high memory and fill in MEM_MAP accordingly.

|

	 pusha			; Save all GP registers

	 test	 CMD_FLAG,@CMD_EMS ; Did the user specify EMS=?
	 jz	 short @F	; No, so EMMSIZE is not valid

	 cmp	 EMMSIZE,0	; Using expanded memory?
	 jne	 short @F	; Yes, continue on

	 test	 CMD_FLAG,@CMD_XHI ; Do we need high DOS memory?
	 jnz	 near ptr RAMSCAN_EXIT ; Not this time, so don't check RAM
@@:

; Search for RAM present in pages not already mapped

@RAM_START equ	 16*(0B000h/512) ; Start of RAM search in 512-byte blocks

	 call	 SAVE_CACHERM	; Save and disable the state of the
				; cache controller for Compaq and HP 386 systems
				; BP = current state

	 call	 SAVE_CACHEPM	; Save and disable 486 caching

	 lea	 di,MEM_MAP[@RAM_START] ; ES:DI ==> memory map in 512-byte blocks
	 mov	 cx,MEM_MAP_LEN-@RAM_START ; CX = # characters in MEM_MAP to search
RAMSCAN_NEXT:
	 jcxz	 RAMSCAN_END	; No more to search

	 mov	 al,@XLAT_UNK	; Search the unknown memory areas
   repne scasb			; Search for 'em
	 jne	 short RAMSCAN_END ; No more found

	 dec	 di		; Back off to matching entry
;;;;;;;; inc	 cx		; Account for it
	 mov	 bx,di		; Copy starting offset+1
	 sub	 bx,offset PGROUP:MEM_MAP ; Convert to origin-0
	 shl	 bx,9-4 	; Convert from 512 to paras

	 call	 CHECK_RAM	; Check for RAM in 512-byte block at BX:0
	 mov	 al,@XLAT_OTH	; Assume valid other system RAM
	 jc	 short RAMSCAN_FND ; Jump if RAM present

	 mov	 al,@XLAT_OVR	; It's not RAM
RAMSCAN_FND:
S16	 stosb			; Mark as OTH or OVR
;;;;;;;; dec	 cx		; Account for it

	 jmp	 RAMSCAN_NEXT	; Go around again

RAMSCAN_END:
	 call	 REST_CACHEPM	; Restore state of 486 cache controller from BP
	 call	 REST_CACHERM	; Restore state of cache controller from BP
				; for Compaq and HP 386 systems
RAMSCAN_EXIT:
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

RAMSCAN  endp			; End RAMSCAN procedure
endif				; IF (@OEM_EMS or @OEM_HIFILL) and @OEM_SYS ne @OEMSYS_ILIM
	 FPPROC  CALC_ALLMEM -- Calculate Needed Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Calculate needed DOS memory.

1.  Check out video memory overlap

2.  Compute LOWSIZE and fill in MEM_MAP accordingly


On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pusha			; Save all GP registers
	 REGSAVE <ds,es>	; Save segment registers

	 push	 seg PGROUP	; Setup ES for string ops
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 test	 CMD_FLAG,@CMD_XLO ; Are we allowed to fill low DOS memory?
	 jnz	 short CALC_ALLMEM_XLO ; No

	 cmp	 LOWOFF.ELO,640 ; Izit a 640 KB system?
	 je	 short @F	; Skip HP check

	 test	 SYS_FLAG,@SYS_HPRS ; Izit an HP Vectra RS/20?
	 jnz	 short CALC_ALLMEM_XLO ; Yes, so don't fill low memory because
				; of their extended BIOS data area
				; from 636 KB to 640 KB
@@:
	 mov	 ax,VIDOFF.ELO	; Get start of video memory
	 sub	 ax,LOWOFF.ELO	; Difference is LOWSIZE (unit = 1KB)
	 mov	 LOWSIZE,ax	; Save for later use
if @OEM_LOFILL
	 ja	 short CALC_ALLMEM_LOWCOM ; Jump if there's low DOS memory to fill
else
	 jbe	 short CALC_ALLMEM_XLO ; Jump if nothing there

	 mov	 ax,LOWOFF.ELO	; Get top of original DOS memory
	 add	 ax,LOWSIZE	; Plus amount we're to add

	 sub	 ax,640 	; Check against maximum allowed to fill
	 jbe	 short CALC_ALLMEM_LOWCOM ; It's within range

	 sub	 LOWSIZE,ax	; Less low DOS memory to add
	 ja	 short CALC_ALLMEM_LOWCOM ; Jump if something there

endif				; IF @OEM_LOFILL
CALC_ALLMEM_XLO:
	 or	 CMD_FLAG,@CMD_XLO ; Mark as not filling low memory
	 mov	 LOWSIZE,0	; Ensure zero
CALC_ALLMEM_LOWCOM:

; Fill in MEM_MAP memory map with RAM=xxxx-C800 if it's a VGA

	 call	 VGARAM 	; Fill in VGA RAM values

; Fill in MEM_MAP memory map with DOS low memory

	 call	 FILL_LOW	; Fill it in

if (@OEM_EMS or @OEM_HIFILL) and @OEM_SYS ne @OEMSYS_ILIM

; Fill in MEM_MAP memory map with RAM

	 CPD	 'Calling RAMSCAN,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 RAMSCAN	; Fill in RAM values
endif				; IF (OEM_EMS or @OEM_HIFILL) and @OEM_SYS ne @OEMSYS_ILIM

; Calculate the OVRSIZE value

	 call	 CALC_OVRSIZE	; Count @XLAT_OVR entries

if @OEM_FLEXROM
	 CPD	 'Calling VGASWAP,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 VGASWAP	; Move all flexible ROMs
endif				; IF @OEM_FLEXROM

if @OEM_EMS

; See if there's room for the EMS frame

	 CPD	 'Calling EMMSCAN,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 call	 EMMSCAN	; Search for the room
	 jc	 short CALC_ALLMEM_ERR ; Something went wrong
endif				; IF @OEM_EMS

if @OEM_SYS eq @OEMSYS_RET
	 call	 FILL_PSM	; Fill in Periscope memory entries
endif				; IF @OEM_SYS eq @OEMSYS_RET

	 call	 CALC_MEMMAP	; Clean up MEM_MAP

; If NOLOW specified, remove LOW entries in MEM_MAP

	 call	 FILL_XLO	; Fill it in

; If NOHIGH specified, remove OVR entries in MEM_MAP

	 call	 FILL_XHI	; Fill it in

; If auto INCLUDE specified, fill in OVR entries as INC entries

	 call	 FILL_INC	; Fill it in

if @OEM_EMS
	 call	 CALC_NPHYS	; Calculate # physical pages in EMS memory
endif				; IF @OEM_EMS

; At this point, all of MEM_MAP is filled in.
; Ensure that the ROM and OVR entries are properly
; aligned on 4/16KB boundaries

	 call	 FILL_ALIGN	; Ensure aligned

	 call	 CALC_PPMTAB	; Clean up PPMTAB

; Calculate the OVRSIZE value

	 call	 CALC_OVRSIZE	; Count @XLAT_OVR entries

	 clc			; Indicate all went well

	 jmp	 short CALC_ALLMEM_EXIT ; Join common exit code

CALC_ALLMEM_ERR:
	 stc			; Indicate something went wrong
CALC_ALLMEM_EXIT:
	 REGREST <es,ds>	; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CALC_ALLMEM endp		; End CALC_ALLMEM procedure
if @OEM_FLEXROM
	 NPPROC  VGASWAP -- Prepare to Swap flexible ROMs
	 assume  ds:PGROUP,es:nothing,fs:XGROUP,gs:nothing,ss:nothing

COMMENT|

Modify entries in MAPTAB to reflect any Flexible ROMs

|

	 pusha			; Save all GP registers
	 REGSAVE <es>		; Save segment register

	 test	 FLEXROM_FLAG,@FR_ACTIVE ; Is FLEXROM active?
	 jz	 near ptr VGASWAP_EXIT ; Jump if not

	 push	 SEG PGROUP	; Where we will find MAP_MEM
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

	 xor	 bx,bx		; Initialize index into FLEXROM_TBL

VGASWAP_NEXT:

; Copy existing MEM_MAP entries for the source ROM to the destin

	 mov	 di,FLEXROM_TBL[bx].FLEX_DST ; Dest of VGA ROM in paras
	 shr	 di,(9-4)	; Convert from paras to 512 bytes
	 lea	 di,MEM_MAP[di] ; ES:DI ==> Destin VGA ROM in MEM_MAP

	 mov	 si,FLEXROM_TBL[bx].FLEX_SRC ; Source of VGA ROM in paras
	 shr	 si,(9-4)	; Convert from paras to 512 bytes
	 lea	 si,MEM_MAP[si] ; DS:SI ==> Source VGA ROM in MEM_MAP

; Skip this if the source is the same as the destination

	 cmp	 si,di		; Izit same as destination?
	 je	 short VGASWAP_SAME ; Jump if so

	 mov	 cx,FLEXROM_TBL[bx].FLEX_LEN ; Length in bytes
	 shr	 cx,(9-0)	; Convert from bytes to 512 bytes

; It is possible that the ROMS might already be correct, that is
; FLEX_DST is High DOS and FLEX_SRC is ROM.  This would happen on the
; DELL (if VGASWAP is used for unshadowing) where the active ROM is at
; C000, and the passive ROM is at E000.  Check for this condition here.

	 cmp	 byte ptr [si],@XLAT_OVR ; Is source already High DOS?
	 je	 short VGASWAP_NOMOVE ; Jump if so

S16  rep movs	 <MEM_MAP[di],MEM_MAP[si]> ; Copy source MEM_MAP to destin

; Mark old source as High DOS

	 mov	 di,FLEXROM_TBL[bx].FLEX_SRC ; Source of VGA ROM in paras
	 shr	 di,(9-4)	; Convert from paras to 512 bytes
	 lea	 di,MEM_MAP[di] ; ES:DI ==> Source VGA ROM in MEM_MAP

	 mov	 al,@XLAT_OVR	; Mark as high DOS memory
	 mov	 cx,FLEXROM_TBL[bx].FLEX_LEN ; Length in bytes
	 shr	 cx,(9-0)	; Convert from bytes to 512 bytes

     rep stos	 MEM_MAP[di]	; Mark dest as High DOS memory

; Mark the alternate video ROM source as High DOS.
; This only happens if the Video ROM is shadowed AND
; the user has requested VGASWAP.

	 test	 FLEXROM_FLAG,@FR_SHDVGA ; VGASWAP and shadowed BIOS present?
	 jz	 short VGASWAP_NOSHADOW ; Jump if not

	 mov	 di,VGA_ALTSEG1 ; Get one of the alternate video ROM sources

	 cmp	 di,FLEXROM_TBL[bx].FLEX_SRC ; Have we processed this address?
	 jne	 short @F	; Jump if not

	 mov	 di,VGA_ALTSEG2 ; Use this alternate video source
@@:
	 shr	 di,(9-4)	; Convert from paras to 512 bytes
	 lea	 di,MEM_MAP[di] ; ES:DI ==> Source VGA ROM in MEM_MAP

	 mov	 al,@XLAT_OVR	; Mark as high DOS memory
	 mov	 cx,FLEXROM_TBL[bx].FLEX_LEN ; Length in bytes
	 shr	 cx,(9-0)	; Convert from bytes to 512 bytes

     rep stos	 MEM_MAP[di]	; Mark dest as High DOS memory

VGASWAP_SAME:
VGASWAP_NOMOVE:
VGASWAP_NOSHADOW:

; Relocate the resources associated with the ROM

	 mov	 di,FLEXROM_TBL[bx].FLEX_SRC ; Source of ROM in paras
	 mov	 dx,FLEXROM_TBL[bx].FLEX_DST ; Destin of ROM in paras
	 mov	 cx,FLEXROM_TBL[bx].FLEX_LEN ; Logical length of ROM in bytes

	 CPD	 'Calling FLEXROM_RESET,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'
	 CPD	 '                        SRC=%DI DEST=%DX LEN=%CX'

	 call	 FLEXROM_RESET	; Find the ROM's resources
				; Resource relocation done in protected mode

	 CPD	 'Leaving FLEXROM_RESET,  CS:IP=%CS:%IP  DS=%DS  ES=%ES'

	 add	 bx,@FLEXROM_STRLEN ; Point to next entry

	 cmp	 bx,FLEXROM_LEN ; More ROMs to process?
	 jb	 near ptr VGASWAP_NEXT ; Process next entry, if so

; The VGASWAP destination should only consist of one ROM
; Scan MEM_MAP at the destination address, and if we find a secondary
; ROM, convert it to @XLAT_OTH.  This will avoid the split ROM problem

; Find video entry (if it exists)

	 xor	 bx,bx		; Zero index into FlexROM table
@@:
	 test	 FLEXROM_TBL[bx].FLEX_FLAG,@FLEXFLAG_VGA ; Izit a video entry?
	 jnz	 short VGASWAP_SPLIT_VIDEO ; Jump if so

	 add	 bx,@FLEXROM_STRLEN ; point to next entry

	 cmp	 bx,FLEXROM_LEN ; More ROMs to process?
	 jb	 short @B	; Jump if more entries

	 jmp	 short VGASWAP_EXIT ; None of the entries are video

VGASWAP_SPLIT_VIDEO:
	 mov	 di,FLEXROM_TBL[bx].FLEX_DST ; Dest of VGA ROM in paras
	 shr	 di,(9-4)	; Convert from paras to 512 bytes
	 lea	 si,MEM_MAP[di] ; ES:DI ==> Destin VGA ROM in MEM_MAP

	 mov	 cx,FLEXROM_TBL[bx].FLEX_LEN ; Length in bytes
	 shr	 cx,(9-0)	; Convert from bytes to 512 bytes

; Verify that the first marker is a ROM marker

	 lods	 MEM_MAP[si]	; Get first MEM_MAP marker
	 dec	 cx		; Count in the first marker

	 cmp	 al,@XLAT_ROM0	; Izit a ROM marker?
	 je	 short VGASWAP_SPLIT_NEXT ; Jump if so

	 cmp	 al,@XLAT_ROM1	; Izit the alternate ROM marker?
	 jne	 short VGASWAP_EXIT ; Jump if not

; Search for second ROM marker (belonging to split ROM)

VGASWAP_SPLIT_NEXT:
	 lods	 MEM_MAP[si]	; Get next MEM_MAP marker

	 cmp	 al,@XLAT_ROM0	; Izit a ROM marker?
	 je	 short VGASWAP_SPLIT_FOUND ; Jump if so

	 cmp	 al,@XLAT_ROM1	; Izit the alternate ROM marker?
	 je	 short VGASWAP_SPLIT_FOUND ; Jump if so

	 loop	 VGASWAP_SPLIT_NEXT ; Check next MEM_MAP entry for split ROM

	 jmp	 short VGASWAP_EXIT ; Jump, The ROM is not a split ROM

VGASWAP_SPLIT_FOUND:
	 mov	 di,si		; Address MEM_MAP via destination register
	 dec	 di		; Address beginning of secondary ROM

; Blast away second (split) ROM

	 mov	 al,@XLAT_OTH	; Use 'other' marker to overwrite ROM
    rep stos	 MEM_MAP[di]	; Overwrite second ROM

VGASWAP_EXIT:

	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

VGASWAP  endp			; End VGASWAP procedure
endif				; IF @OEM_FLEXROM

XCODE	 ends			; End XCODE segment

	 MEND			; End QMAX_MEM module
