;' $Header:   P:/PVCS/MAX/386MAX/QMAX_TIM.ASV   1.6   30 May 1997 10:46:08   BOB  $
	 title	 QMAX_TIM -- 386MAX Memory Timer Routines
	 page	 58,122
	 name	 QMAX_TIM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Program segment ECODE, dword-aligned, public, class 'ecode'
	       Program segment BLINK, byte-aligned,  public, class 'blink'
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Program segment NCODE, byte-aligned,  public, class 'ncode'
	       Data    segment NDATA, dword-aligned, public, class 'ndata'
	       Group XGROUP:
	       Program segment XCODE, byte-aligned,  public, class 'xcode'
	       Data    segment XDATA, dword-aligned, public, class 'xdata'
	       Data    segment WBPAT_SEG, word-aligned, public, class 'xdata'
	       Group YGROUP:
	       Data    segment YDATA, dword-aligned, public, class 'ydata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include KEYCALL.INC
	 include CPUFET.INC
	 include CPUID.INC
	 include 386.INC
	 include PTR.INC
	 include 8253.INC
	 include 8259.INC
	 include OPCODES.INC
	 include BIOSDATA.INC
	include PNP.INC

	 include QMAX_DBG.INC
	 include QMAX_DTE.INC
	 include QMAX_OEM.INC
	 include QMAX_TDT.INC
	 include QMAX_FLX.INC
.list

PGROUP	 group	 CODE,ECODE,BLINK,EDATA,NCODE,NDATA
XGROUP	 group	 XCODE,XDATA,WBPAT_SEG
YGROUP	 group	 YDATA


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 ENABLE_IMR:near

	 extrn	 GOREAL_SUB:near

	 extrn	 SHADOW_ENABLE:near
	 extrn	 SHADOW_DISABLE:near

	 extrn	 WARMBOOT:near

	 extrn	 CMD_FLAG:word
	 include QMAX_CMD.INC

	 extrn	 CM2_FLAG:word
	 include QMAX_CM2.INC

	 extrn	 CM3_FLAG:word
	 include QMAX_CM3.INC

	 extrn	 DB2_FLAG:word
	 include QMAX_DB2.INC

	 extrn	 DB3_FLAG:word
	 include QMAX_DB3.INC

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 LCL_FLAG:word
	 include QMAX_LCL.INC

	 extrn	 SYS_FLAG:dword
	 include QMAX_SYS.INC

	 extrn	 SHDSIZE:word
	 extrn	 MAPSIZE:word

	 extrn	 SYSROM_START:word

CODE	 ends			; End CODE segment


BLINK	 segment use16 byte public 'blink' ; Start BLINK segment
	 assume  cs:PGROUP

	 extrn	 CHECKPOINT:near

BLINK	 ends			; End BLINK segment


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 I15_FLAG:word
	 include QMAX_I15.INC

	 extrn	 DESC_TAB:qword

	 extrn	 ASTMIO_LO:dword
	 extrn	 CPQMIO_LO:dword

	 extrn	 SHDTAB:word
	 extrn	 SCRBTAB:word,SCRBCNT:word
	 include QMAX_SHD.INC

	 extrn	 PHYSIZE:dword
	 extrn	 HIMEM_CS:word

	 extrn	 LOWOFF:dword
	 extrn	 LMLTOP:dword
	 extrn	 CON4KB:dword
	 extrn	 CON128KB:dword
	 extrn	 CON1MB:dword

	 extrn	 LaVROM_BEG:dword

if @OEM_BCF
	 extrn	 BCF_BIOSSIZE:dword
endif				; IF @OEM_BCF

	 extrn	 CPUTYPE:byte

if @OEM_FLEXROM
	 extrn	 FLEXROM_LEN:word
	 extrn	 FLEXROM_TBL:tbyte
endif				; IF OEM_FLEXROM

	 extrn	 CACHESIZE:dword

	extrn	PnP_SEG:word
	extrn	PnP_DATA:word

	 public  MAPTAB_CNT,MAPTAB_IND
MAPTAB_CNT dw	 0		; # entries in MAPTAB
MAPTAB_IND dw	 0		; Index into MAPTAB of next entry

	 public  MAPTAB
	 include QMAX_MAP.INC
MAPTAB	 MAP_STR 16 dup (<0>)	; The re-mapping table initially all zero

	 public  MAPSEG_NXT
MAPSEG_NXT dw	 ?		; Next available map segment

	 public  CACHEMASK
CACHEMASK dd	 (mask $CD) or (mask $NW) ; How to disable cache via CR0

EDATA	 ends			; End EDATA segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 NRD_FLAG:dword
	 include QMAX_NRD.INC

	 extrn	 TDESC_TAB:qword

	 extrn	 ERR_CODE:byte
	 extrn	 ERR_FLAG:byte
	 extrn	 @ERR_TIM:abs

	 extrn	 MEM_MAP:byte
	 extrn	 MEM_MAP_LEN:abs
	 extrn	 @XLAT_ROM0:abs
	 extrn	 @XLAT_ROM1:abs
	 extrn	 @XLAT_ROM2:abs

	 public  OLDTMPINT15_VEC
OLDTMPINT15_VEC dd ?		; Save area for original INT 15h handler

	 public  TOP_GDT,TOP_MIO
TOP_GDT  MDTE_STR <>		; Move DTEs for top MIO ROM disabling
TOP_MIO  dw	 ?		; Top memory-mapped I/O port value

	 public  MEMTIME_LO,MEMTIME_MD,MEMTIME_HI,MEMTIME
MEMTIME_LO dw	 ?		; Low memory access timer value
MEMTIME_MD dw	 ?		; Middle ...
MEMTIME_HI dw	 ?		; High ...
MEMTIME  dw	 ?		; The best of the above times

TIDT_MAC macro	 NCNT
	 IDT_STR <PGROUP:TINTPROC&NCNT,DTE_CS,,CPL0_INTR3,0>
	 endm			; TIDT_MAC

	 public  TIDT_DESC
TIDT_DESC label  qword		; Interrupt descriptor table

CNT	 =	 0
NTIDT	 equ	 0Eh+1		; # timing IDT entries
.xlist
	 rept	 NTIDT		; Define interrupts 00h to NTIDT-1

	 TIDT_MAC %CNT
CNT	 =	 CNT+1

	 endm			; REPT NTIDT
.list
	 public  TIDT_DESC_LEN
TIDT_DESC_LEN equ $-TIDT_DESC	; Length of the TIDT

	 public  DMA_STR0,DMA_STR1,DMA_STR2
DMA_STR0 db	 80h, 0FAh,  ?	; CMP DL,?
	 db	 73h,	?	; JAE ?
	 db	 8Ah,  7Eh,  ?	; MOV BH,[BP+?]
DMA_STR1 db	 02h, 0FFh	; ADD BH,BH
	 db	 32h, 0DBh	; XOR BL,BL
	 db	 03h, 0C3h	; ADD AX,BX
	 db	 83h, 0D2h, 00h ; ADC DX,0
DMA_STR2 db	 80h, 0FAh,  ?	; CMP DL,?

; Define external cache default.  256K is the optimal size for most systems.
@CACHESIZE_S equ (256/64)	; Size in 64K blocks

	 public  CACHESZ_RM
CACHESZ_RM dw	 @CACHESIZE_S * 2 ; External cache in 64K blocks * 2

NDATA	 ends			; End NDATA segment


XDATA	 segment use16 dword public 'xdata' ; Start XDATA segment
	 assume  ds:XGROUP

	 extrn	 CPQVGAOFF:word
	 extrn	 CPQVGAPATOFF:word
	 extrn	 CPQVGAPAT:byte
	 extrn	 CPQVGAPAT_LEN:abs
	 extrn	 CPQVGABUG_LEN3:abs

	 extrn	 CPQVGAOFF2A:word
	 extrn	 CPQVGABUG2_RPL1_LEN:abs
	 extrn	 CPQVGABUG2_RPL1:byte
	 extrn	 CPQVGABUG2_FIX1_LEN:abs
	 extrn	 CPQVGABUG2_FIX1:byte
	 extrn	 CPQVGAOFF2B:word
	 extrn	 CPQVGABUG2_RPL2_LEN:abs
	 extrn	 CPQVGABUG2_RPL2:byte
	 extrn	 CPQVGABUG2_FIX2_LEN:abs
	 extrn	 CPQVGABUG2_FIX2:byte

	 extrn	 SHAD_KEYB_DLY:byte

XDATA	 ends			; End XDATA segment


YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
	 assume  ds:YGROUP

	 extrn	 MSG_ERRTIM:byte
	 extrn	 MSG_ERRTIM1:byte

YDATA	 ends			; End YDATA segment


XCODE	 segment use16 byte public 'xcode' ; Start XCODE segment
	 assume  cs:XGROUP

	 public  @QMAX_TIM_XCODE
@QMAX_TIM_XCODE:		; Mark module start in .MAP file

	 extrn	 FMT_ERR_CODE:far
	 extrn	 CALC_FORCE:far
if @OEM_BCF
	 extrn	 PROC_BCF:far
endif				; IF @OEM_BCF

	 NPPROC  INST_TMPINT15 -- Install Temporary INT 15h Handler
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Install a temporary INT 15 handler.

This handler is necessary to overcome a hardware and software
bug in the COMPAQ 386 products.

The hardware bug is a spurious parity error when reading the
configuration register.  The software bug is a mishandle of
the parity error (AH=01, CF=1) within the INT 16h BIOS code.

The solution is to install an INT 15 handler which traps
block move calls, checks for a parity error and ignores it.

|

	 REGSAVE <ax,bx,dx,es>	; Save registers

	 mov	 al,15h 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> current handler
	 assume  es:nothing	; Tell the assembler about it

	 mov	 OLDTMPINT15_VEC.VOFF,bx ; Save for later use
	 mov	 OLDTMPINT15_VEC.VSEG,es

	 mov	 al,15h 	; Intercept this one
	 DOSCALL @SETINT,TMPINT15 ; Install our own handler

	 REGREST <es,dx,bx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

INST_TMPINT15 endp		; End INST_TMPINT15 procedure
	 NPPROC  REST_TMPINT15 -- Restore From Temporary INT 15h Handler
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore original INT 15 handler after INST_TMPINT15.

|

	 REGSAVE <ax,dx,ds>	; Save registers

	 lds	 dx,OLDTMPINT15_VEC ; DS:DX ==> original INT 15h handler
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 al,15h 	; Intercept this one
	 DOSCALL @SETINT	; Restore

	 REGREST <ds,dx,ax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_TMPINT15 endp		; End REST_TMPINT15 procedure
	 NPPROC  TOP_WRITE -- Write Top Memory-mapped I/O Port
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Write value in TOP_MIO to top memory-mapped I/O port.

On entry:

DS:SI	 ==>	 32-bit destination address

|

	 REGSAVE <eax,cx,si,es> ; Save registers

; Setup the GDT for the move

	 push	 seg PGROUP	; Setup ES for INT 15h
	 pop	 es		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; The source address is TOP_MIO

	 xor	 eax,eax	; Zero entire register
	 mov	 ax,seg PGROUP	; Copy the segment of TOP_MIO
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 eax,offset PGROUP:TOP_MIO ; EAX has 32-bit linear address of TOP_MIO

	 mov	 TOP_GDT.MDTE_DS.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 TOP_GDT.MDTE_DS.DESC_BASE3,al
;;;;;;;; ror	 eax,8		; Rotate back
	 mov	 TOP_GDT.MDTE_DS.DESC_SEGLM0,3 ; Save as data limit
	 mov	 TOP_GDT.MDTE_DS.DESC_SEGLM1,0 ; Save size & flags
	 mov	 TOP_GDT.MDTE_DS.DESC_ACCESS,CPL0_DATA

	 lodsd			; Get destination address

	 mov	 TOP_GDT.MDTE_ES.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Bring down the high-order byte
	 mov	 TOP_GDT.MDTE_ES.DESC_BASE3,al ; Save in GDT
;;;;;;;; ror	 eax,8		; Rotate back
	 mov	 TOP_GDT.MDTE_ES.DESC_SEGLM0,3 ; Save as data limit
	 mov	 TOP_GDT.MDTE_ES.DESC_SEGLM1,0 ; Save size & flags
	 mov	 TOP_GDT.MDTE_ES.DESC_ACCESS,CPL0_DATA

	 lea	 si,TOP_GDT	; ES:SI ==> GDT for memory-mapped I/O
	 mov	 cx,1		; Write one word
	 REGSAVE <fs,gs>	; Save for a moment
	 mov	 ah,87h 	; Function code to move extended memory
	 int	 15h		; Request BIOS service
	 REGREST <gs,fs>	; Restore
				; Ignore error returns
	 REGREST <es,si,cx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TOP_WRITE endp			; End TOP_WRITE procedure
	 FPPROC  SAVE_CACHERM -- Save and Disable Cache Controller (Real Mode)
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save the state of and disable the cache controller.
This procedure is to be called in real mode only.

On exit:

EBP	 =	 state of cache controller

|

	 REGSAVE <eax,ds>	; Save registers

	 push	 seg PGROUP	; Setup DS for data references
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

; If we're on a 486 or later system, disable the cache through CR0
; in SAVE_CACHEPM.

	 cmp	 CPUTYPE,04h	; Izit a 486 or later?
	 jnb	 short SAVE_CACHERM_EXIT ; Jump if so

; If we're on a COMPAQ system, disable (and flush) the cache controller.
; We can (and must) do this in real mode on Compaq systems; only some
; systems (like the IBM PS/ValuePoint 486/DX2) can't enter protected
; mode with the cache controller disabled.

	 test	 SYS_FLAG,@SYS_CPQ ; Izit a COMPAQ Deskpro 386?
	 jz	 short SAVE_CACHE_XCPQ ; Not this time

	 call	 INST_TMPINT15	; Install temporary INT 15h handler

	 mov	 al,00h 	; Get cache controller status
	 KEYCALL @CPQCACHE	; Request keyboard service

	 mov	 bp,ax		; Save status

	 cmp	 ah,0E2h	; Check for valid data
	 jne	 short @F	; Not this time

	 mov	 al,02h 	; Disable cache contoller
	 KEYCALL @CPQCACHE	; Request keyboard service
@@:
	 jmp	 short SAVE_CACHERM_EXIT ; Join common exit code

SAVE_CACHE_XCPQ:

; If we're on an HP RS/20C or /25C system, disable (and flush)
; the cache controller

	 test	 SYS_FLAG,@SYS_HPCACHE ; Cache controller present?
	 jz	 short SAVE_CACHE_XHP ; Not this time

	 mov	 ah,11h 	; Get state of cache controller
	 call	 HPFNS		; Call HP function dispatcher

	 mov	 bp,ax		; Save status

	 cmp	 ah,02h 	; Check for valid data
	 je	 short @F	; Not this time

	 mov	 ah,10h 	; Disable cache controller
	 call	 HPFNS		; Call HP function dispatcher
@@:
;;;;;;;; jmp	 short SAVE_CACHERM_EXIT ; Join common exit code

SAVE_CACHE_XHP:
SAVE_CACHERM_EXIT:
	 REGREST <ds,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_CACHERM endp		; End SAVE_CACHERM procedure
	 FPPROC  REST_CACHERM -- Restore Cache Controller (Real Mode)
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore the state of the cache controller
This procedure may only be called from real mode.

On entry:

EBP	 =	 original state of cache controller

|

	 REGSAVE <eax,si,ds>	; Save registers

	 push	 seg PGROUP	; Setup DS for data references
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

; If we're on a 486 or later system, restore the state of the cache
; via CR0 in REST_CACHEPM.

	 cmp	 CPUTYPE,04h	; Izit a 486 or later?
	 jnb	 short REST_CACHERM_EXIT ; Jump if so

; If we're on a COMPAQ system, restore the state of the cache controller

	 test	 SYS_FLAG,@SYS_CPQ ; Izit a COMPAQ Deskpro 386?
	 jz	 short REST_CACHE_XCPQ ; Not this time

	 mov	 ax,bp		; Restore status

	 cmp	 ah,0E2h	; Check for valid data
	 jne	 short @F	; Not this time

	 KEYCALL @CPQCACHE	; Request keyboard service
@@:

; When we disabled the cache controller in SAVE_CACHE, the system
; also disabled the ROM double mapping -- restore that state here so
; we can copy the correct values into local RAM in COPY_ROM.

; Tell the system to decode the upper 128KB as high/low ROM

	 mov	 TOP_MIO,@CPQ_HLROM ; Mark as read-only, high/low
	 lea	 si,CPQMIO_LO	; DS:SI ==> 32-bit destination address
	 call	 TOP_WRITE	; Write value in TOP_MIO to I/O port

	 call	 REST_TMPINT15	; Restore original INT 15h handler

	 jmp	 short REST_CACHERM_EXIT ; Join common exit code

REST_CACHE_XCPQ:

; If we're on an HP RS/20C or /25C system, restore the state of
; the cache controller

	 test	 SYS_FLAG,@SYS_HPCACHE ; Cache controller present?
	 jz	 short REST_CACHE_XHP ; Not this time

	 mov	 ax,bp		; Copy previous state (AX:  0=ON, 1=OFF)

	 cmp	 ah,02h 	; Check for valid data
	 je	 short @F	; Not this time

	 mov	 ah,al		; Copy to function register
	 add	 ah,0Fh 	; Shift to origin-0Fh
	 call	 HPFNS		; Call HP function dispatcher
@@:
;;;;;;;; jmp	 short REST_CACHERM_EXIT ; Join common exit code

REST_CACHE_XHP:
REST_CACHERM_EXIT:
	 REGREST <ds,si,eax>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_CACHERM endp		; End REST_CACHERM procedure
	 FPPROC  TIME_ROM -- Time ROM Accesses
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search for ROMs in MEM_MAP and time them filling in
MAPTAB in the process.

|

	 REGSAVE <eax,ebx,cx,dx,si,di,bp> ; Save registers

; In case there's a cache controller, we must disallow interrupts
; to avoid system ROM being re-cached and thus obtaining a false
; timing on it.

	 pushf			; Save for a moment
	 cli			; Disallow interrupts

	 call	 SAVE_CACHERM	; Save and disable the state of the
				; cache controller for Compaq and HP 386's
				; BP = current state

	 call	 far ptr SAVE_CACHEPM ; Save and disable cache controller for
				; 486; BP = current state

; First flush any cache controller memory

	 REGSAVE <ds,es>	; Save for a moment

	 mov	 cx,256/64	; # iterations for 256KB at 64KB per iteration
	 xor	 bx,bx		; Initialize the starting segment
FLUSH_ROM:
	 xor	 si,si		; Initialize the starting source offset
	 xor	 di,di		; ...			  destin
	 mov	 ds,bx		; DS:SI ==> low memory
	 mov	 es,bx		; ES:DI ==> ...
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 push	 cx		; Save for a moment
	 mov	 cx,64*(1024/4) ; Move all 64KB
S16  rep movsd			; Fill the cache
	 pop	 cx		; Restore

	 add	 bx,1000h	; Skip to next block of 64KB

	 loop	 FLUSH_ROM	; Jump if more 64KB block to read in

	 REGREST <es,ds>	; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 mov	 si,MAPTAB_IND	; Get index of next entry in MAPTAB

; If the user specified any ROM keyword, look for special ROM markers only

	 mov	 dl,@XLAT_ROM1	; Normal ROM marker

	 test	 CMD_FLAG,@CMD_XRM ; NOROM specifed?
	 jnz	 short TIME_ROM_SPEC ; Yes, look for special markers only

	 test	 CM2_FLAG,@CM2_ROM ; ROM= specifed?
	 jz	 short TIME_ROM_NORM ; No
TIME_ROM_SPEC:
	 mov	 dl,@XLAT_ROM0	; Special ROM marker
TIME_ROM_NORM:

; Search through MEM_MAP for ROM entries

	 lea	 di,MEM_MAP	; ES:DI ==> start of memory map
	 mov	 cx,MEM_MAP_LEN ; Get # characters in MEM_MAP
TIME_ROM_NEXT:
	 mov	 al,dl		; Search for 1st entry

	 and	 cx,cx		; Izit the end?
	 jz	 near ptr TIME_ROM_EXIT ; Yes, no more to search

   repne scasb			; Search for it
	 jne	 near ptr TIME_ROM_EXIT ; No more found

	 mov	 ax,di		; Copy starting offset
	 sub	 ax,1+offset es:MEM_MAP ; Convert to origin-0
	 shl	 ax,9-4 	; Convert from 512-byte to paras
	 mov	 MAPTAB.MAP_PARA_DST[si],ax ; Save starting segment

; Now search for the end to get its length

	 mov	 al,@XLAT_ROM2	; Search for 2nd entry
TIME_ROM0:
	 jcxz	 TIME_ROM1	; No more to search for???
    repe scasb			; Search for more of same
	 je	 short TIME_ROM1 ; Jump if all the same

;;;;;;;; cmp	 dl,es:[di-1]	; Does it abut other ROM?
;;;;;;;; je	 short TIME_ROM0 ; Yes, continue on
;;;;;;;;
	 dec	 di		; Back up to last mismatch
	 inc	 cx		; Account for it
TIME_ROM1:
	 mov	 ax,di		; Copy ending offset
	 sub	 ax,offset es:MEM_MAP ; Convert to origin-0
	 shl	 ax,9-4 	; Convert from 512-byte to paras
	 sub	 ax,MAPTAB.MAP_PARA_DST[si] ; Subtract starting point to get length
	 mov	 MAPTAB.MAP_LEN[si],ax ; Save length in paras

	 or	 MAPTAB.MAP_FLAG[si],@MAP_ROM ; Mark as ROM

; Check for COMPAQ VGA with bug

	 mov	 eax,LaVROM_BEG ; Get beginning linear address of video ROM
	 shr	 eax,4-0	; Convert from bytes to paras

	 cmp	 ax,MAPTAB.MAP_PARA_DST[si] ; Izit the video ROM?
	 jne	 short TIME_ROM1A ; Jump if not

	 test	 NRD_FLAG,@NRD_CPQVGA ; Izit COMPAQ VGA with bug?
	 jz	 short @F	; Jump if not

	 or	 MAPTAB.MAP_FLAG[si],@MAP_CPQVGA ; Mark as present
@@:
	 test	 NRD_FLAG,@NRD_CPQVGA2 ; Izit COMPAQ VGA with 2nd bug?
	 jz	 short @F	; Jump if not

	 or	 MAPTAB.MAP_FLAG[si],@MAP_CPQVGA2 ; Mark as present
@@:
TIME_ROM1A:

; Reduce the size of the ROM to 4KB boundaries

	 movzx	 eax,MAPTAB.MAP_PARA_DST[si] ; Get starting segment
	 movzx	 ebx,MAPTAB.MAP_LEN[si] ; Get length in paras
	 add	 ebx,eax	; Point to end of ROM

; Round up the starting segment to 4KB boundary

	 add	 ax,(4*1024/16)-1 ; Note that this can never overflow
	 and	 ax,not ((4*1024/16)-1)

; Round down the ending segment to 4KB boundary

	 and	 bx,not ((4*1024/16)-1)

	 sub	 ebx,eax	; Convert back to length
	 ja	 short TIME_ROM2 ; Its length is valid

	 xor	 bx,bx		; Set the length to zero
	 mov	 MAPTAB.MAP_FLAG[si],0 ; Clear the flags
TIME_ROM2:
	 mov	 MAPTAB.MAP_PARA_DST[si],ax ; Save as starting segment
	 mov	 MAPTAB.MAP_LEN[si],bx ; Save as length in paras

	 and	 bx,bx		; Any ROM left?
	 jz	 short TIME_ROM3 ; All gone

	 cmp	 ax,SYSROM_START ; Izit the system ROM?
	 jb	 short TIME_ROM_XBIOS ; Jump if not

	 or	 MAPTAB.MAP_FLAG[si],@MAP_BIOS ; Mark as system BIOS

if @OEM_BCF

; Check for BCF file load

	 test	 LCL_FLAG,@LCL_BCF ; Izit present?
	 jz	 short TIME_ROM_XBIOS ; Jump if not

	 mov	 eax,BCF_BIOSSIZE ; Get the new size of the ROM in bytes
				; (as a multiple of 4KB)
	 shr	 eax,4-0	; Convert from bytes to paras
	 mov	 MAPTAB.MAP_LEN[si],ax ; Save as new length in paras
	 neg	 ax		; Subtract from 64KB to get starting segment
	 mov	 MAPTAB.MAP_PARA_DST[si],ax ; Save as new segment

	 or	 MAPTAB.MAP_FLAG[si],@MAP_BCF ; Mark as BCFed ROM

	 jmp	 short TIME_ROM_FORCE ; Mark as forced swap

endif				; IF @OEM_BCF
TIME_ROM_XBIOS:
	 test	 DB2_FLAG,@DB2_AROM ; ALLROM forced?
	 jnz	 short TIME_ROM_FORCE ; Jump if so

	 push	 MAPTAB.MAP_PARA_DST[si] ; Pass segment to time
	 call	 far ptr TIME_MEM ; Return with AX = timer value

	 jmp	 short TIME_ROM_SAVE ; Join common save code

TIME_ROM_FORCE:
	 mov	 ax,-1		; Mark as very slow to force swap
TIME_ROM_SAVE:
	 mov	 MAPTAB.MAP_TIME[si],ax ; Save access time value
TIME_ROM3:
	 mov	 ax,MAPTAB.MAP_PARA_DST[si] ; Get destin para

if @OEM_FLEXROM

; If this ROM is a VGA SWAP source, set the MAP_PARA_DST to the VGA SWAP dest

	 REGSAVE <bx>		; Save
	 xor	 bx,bx		; Start of FLEXROM table

TIME_ROM_NEXTFLEX:
	 cmp	 ax,FLEXROM_TBL[bx].FLEX_DST ; Izit our expected destin?
	 je	 short TIME_ROM4 ; Jump if so

	 add	 bx,@FLEXROM_STRLEN ; Point to next entry

	 cmp	 bx,FLEXROM_LEN ; Any more entries left?
	 jb	 short TIME_ROM_NEXTFLEX ; Try next FLEXROM entry

	 jmp	 short TIME_ROM5 ; Not found, continue on

TIME_ROM4:
	 mov	 ax,FLEXROM_TBL[bx].FLEX_SRC ; Get our expected source
	 mov	 MAPTAB.MAP_TIME[si],-1 ; Ensure caching if VGASWAP ROM
TIME_ROM5:
	 REGREST <bx>		; restore
endif				; IF @OEM_FLEXROM

	 mov	 MAPTAB.MAP_PARA_SRC[si],ax ; Save back

	 add	 si,type MAP_STR ; Skip to next entry
	 inc	 MAPTAB_CNT	; Count in another entry

	 jmp	 TIME_ROM_NEXT	; Go around again

TIME_ROM_EXIT:
	 mov	 MAPTAB_IND,si	; Keep up-to-date

	 call	 far ptr REST_CACHEPM ; Restore state of cache controller from
				; BP for 486 systems.

	 call	 REST_CACHERM	; Restore state of cache controller from BP
				; for Compaq and HP 386 systems.

	 popf			; Restore flags

	 REGREST <bp,di,si,dx,cx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIME_ROM endp			; End TIME_ROM procedure
	 FPPROC  COPY_ROM -- Copy ROM to Local Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Copy a ROM described by MAPTAB[si] to local memory
and patch if necessary.

|

	 pusha			; Save all GP registers
	 REGSAVE <ds,es>	; Save segment registers

	 mov	 cx,MAPTAB.MAP_LEN[si] ; Get length in paras

	 mov	 es,MAPSEG_NXT	; Get next low memory segment
	 assume  es:nothing	; Tell the assembler about it

	 mov	 MAPTAB.MAP_PAR2[si],es ; Save for later use
	 add	 MAPSEG_NXT,cx	; Skip to next available para

if @OEM_BCF
	 test	 MAPTAB.MAP_FLAG[si],@MAP_BCF ; Izit a BCF ROM?
	 jz	 short COPY_ROM_XBCF ; Jump if not

	 call	 PROC_BCF	; Process the BCF file
;;;;;;;; jc	 short ???	; Ignore error return

	 jmp	 short COPY_ROM_COM ; Join common code

COPY_ROM_XBCF:
endif				; IF @OEM_BCF

	 REGSAVE <si,ds,es>	; Save for a moment

	 mov	 ds,MAPTAB.MAP_PARA_SRC[si] ; Get source para
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; Initial offset is zero
	 xor	 di,di		; Initial offset is zero
COPY_ROM_NEXT:
	 push	 cx		; Save for a moment

	 cmp	 cx,1000h	; Check against 64KB in paras
	 jbe	 short @F	; Jump if within range

	 mov	 cx,1000h	; Use maximum
@@:
	 shl	 cx,4-2 	; Convert from paras to dwords

S16  rep movsd			; Copy it

	 pop	 cx		; Restore

	 mov	 ax,ds		; Copy current source segment
	 add	 ax,1000h	; Skip to next 64KB
	 mov	 ds,ax		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 ax,es		; Copy current destin segment
	 add	 ax,1000h	; Skip to next 64KB
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 sub	 cx,1000h	; Less maximum moved
	 ja	 short COPY_ROM_NEXT ; Jump if more of ROM to copy

	 REGREST <es,ds,si>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
COPY_ROM_COM:

; If this is COMPAQ VGA ROM with bug, patch it now

	 test	 MAPTAB.MAP_FLAG[si],@MAP_CPQVGA ; Izit COMPAQ VGA with bug?
	 jz	 short COPY_ROM_XCPQ1 ; Jump if not

	 push	 fs		; Save for a moment

	 push	 seg XGROUP	; Get segment of CPQVGAxxx
	 pop	 fs		; Address it
	 assume  fs:XGROUP	; Tell the assembler about it

	 mov	 di,CPQVGAOFF	; ES:DI ==> buggy code
	 mov	 es:[di].LO,@OPCOD_JMPN ; Call it a near jump
	 add	 di,3		; Skip over near jump to simulate IP
	 mov	 ax,CPQVGAPATOFF ; Get offset of patch area
	 sub	 ax,di		; Less simulated IP to get relative jump value
	 mov	 es:[di-2].ELO,ax ; Save as relative jump offset

	 mov	 di,CPQVGAPATOFF ; Get offset of patch area
	 lea	 si,CPQVGAPAT	; FS:SI ==> patch code
	 mov	 cx,CPQVGAPAT_LEN ; Length of ...
S16  rep movs	 <es:[di].LO,CPQVGAPAT[si]> ; Copy to cached copy
				; DI has simulated IP
	 mov	 CPQVGAPATOFF,di ; Save as offset of next patch point

	 mov	 ax,CPQVGAOFF	; Get start of buggy code
	 add	 ax,CPQVGABUG_LEN3 ; Plus length of buggy code to get CLR_SCRN:
	 sub	 ax,di		; Less simulated IP to get relative jump value
	 mov	 es:[di-2].ELO,ax ; Save as relative jump offset

	 pop	 fs		; Restore
	 assume  fs:nothing	; Tell the assembler about it
COPY_ROM_XCPQ1:

; If this is COMPAQ VGA ROM with bug, patch it now

	 test	 MAPTAB.MAP_FLAG[si],@MAP_CPQVGA2 ; Izit COMPAQ VGA with bug?
	 jz	 short COPY_ROM_XCPQ2 ; Jump if not

	 push	 fs		; Save for a moment

	 push	 seg XGROUP	; Get segment of CPQVGAxxx
	 pop	 fs		; Address it
	 assume  fs:XGROUP	; Tell the assembler about it

; Insert 1st replacement string into the buggy code and fixup the
; rel16 value which references the corresponding fix string

	 mov	 di,CPQVGAOFF2A ; ES:DI ==> buggy code
	 mov	 cx,CPQVGABUG2_RPL1_LEN ; Length of ...
	 lea	 si,CPQVGABUG2_RPL1 ; FS:SI ==> 1st replacement code
S16  rep movs	 <es:[di].LO,CPQVGABUG2_RPL1[si]> ; Copy to cached copy
	 mov	 ax,CPQVGAPATOFF ; Get offset of patch area
	 sub	 ax,di		; Less simulated IP to get relative jump value
	 mov	 es:[di-2].ELO,ax ; Save as relative jump offset

; Copy 1st fix string to video ROM patch area

	 mov	 di,CPQVGAPATOFF ; Get offset of patch area
	 lea	 si,CPQVGABUG2_FIX1 ; FS:SI ==> 1st fix code
	 mov	 cx,CPQVGABUG2_FIX1_LEN ; Length of ...
S16  rep movs	 <es:[di].LO,CPQVGABUG2_FIX1[si]> ; Copy to cached copy
				; DI has simulated IP
	 mov	 CPQVGAPATOFF,di ; Save as offset of next patch point

; Insert 2nd replacement string into the buggy code and fixup the
; rel16 value which reference the corresponding fix string

	 mov	 di,CPQVGAOFF2B ; ES:DI ==> buggy code
	 mov	 cx,CPQVGABUG2_RPL2_LEN ; Length of ...
	 lea	 si,CPQVGABUG2_RPL2 ; FS:SI ==> 2nd replacement code
S16  rep movs	 <es:[di].LO,CPQVGABUG2_RPL2[si]> ; Copy to cached copy
	 mov	 ax,CPQVGAPATOFF ; Get offset of patch area
	 sub	 ax,di		; Less simulated IP to get relative jump value
	 mov	 es:[di-2].ELO,ax ; Save as relative jump offset

; Copy 2nd fix string to video ROM patch area

	 mov	 di,CPQVGAPATOFF ; Get offset of patch area
	 lea	 si,CPQVGABUG2_FIX2 ; FS:SI ==> 2nd fix code
	 mov	 cx,CPQVGABUG2_FIX2_LEN ; Length of ...
S16  rep movs	 <es:[di].LO,CPQVGABUG2_FIX2[si]> ; Copy to cached copy
				; DI has simulated IP
	 mov	 CPQVGAPATOFF,di ; Save as offset of next patch point

	 pop	 fs		; Restore
	 assume  fs:nothing	; Tell the assembler about it
COPY_ROM_XCPQ2:

; If this is system ROM and we're to patch the boot location, do it now

	 test	 MAPTAB.MAP_FLAG[si],@MAP_BIOS ; Izit system ROM?
	 jz	 near ptr COPY_ROM_EXIT ; Jump if not

; Address the ROM checksum as ES:BX
; and the far boot location as ES:BX-15

	 mov	 bx,MAPTAB.MAP_LEN[si] ; Get length in paras
@@:
	 cmp	 bx,1000h	; Izit bigger than 64KB?
	 jbe	 short @F	; Jump if not

	 sub	 bx,1000h	; Less 64KB's worth
	 mov	 ax,es		; Get current destin segment
	 add	 ax,1000h	; Skip to next 64KB
	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 jmp	 short @B	; Go around again

@@:
	 shl	 bx,4-0 	; Convert from paras to bytes (might be zero)
	 dec	 bx		; Less one to address checksum

	 test	 MAPTAB.MAP_FLAG[si],@MAP_BOOT ; Patch boot location?
	 jz	 short COPY_ROM_CPQ ; Not this time

	 cmp	 es:[bx][0-15].LO,@OPCOD_JMPF ; Check for far jump opcode
	 jne	 short COPY_ROM_CPQ ; Not this time

	 lea	 ax,WARMBOOT	; Get low memory offset
	 sub	 es:[bx],al	; Subtract from checksum
	 sub	 es:[bx],ah	; Subtract from checksum
	 xchg	 ax,es:[bx][1-15].ELO ; Swap with current offset
	 add	 es:[bx],al	; Add into checksum
	 add	 es:[bx],ah	; Add into checksum

	 mov	 ax,HIMEM_CS	; Get device driver segment in high DOS memory
	 sub	 es:[bx],al	; Subtract from checksum
	 sub	 es:[bx],ah	; Subtract from checksum
	 xchg	 ax,es:[bx][3-15].ELO ; Swap with current segment
	 add	 es:[bx],al	; Add into checksum
	 add	 es:[bx],ah	; Add into checksum

; If this is a COMPAQ Deskpro 386 and the ROM being copied is at
; F000 or higher, check for DMA restriction code and remove it if found.

COPY_ROM_CPQ:
	 test	 SYS_FLAG,@SYS_CPQ ; Izit a COMPAQ Deskpro 386?
	 jz	 short COPY_ROM_EXIT ; Not this time

	 xor	 di,di		; Initial offset is zero

	 mov	 cx,MAPTAB.MAP_LEN[si] ; Get length in paras

	 shl	 cx,4-0 	; Convert from paras to bytes
	 jnz	 short COPY_ROM_DMANEXT ; Jump if not 64KB long

	 inc	 di		; Skip over first byte
	 dec	 cx		; Account for it

; Now CX is non-zero even if the ROM is 64KB

COPY_ROM_DMANEXT:
	 jcxz	 COPY_ROM_EXIT	; Jump if no more to search
	 mov	 al,DMA_STR1[0] ; Get 1st byte in string
   repne scasb			; Search for it
	 jne	 short COPY_ROM_EXIT ; Jump if not found

	 REGSAVE <cx,si,di>	; Save for a moment

	 lea	 si,DMA_STR1[1] ; DS:SI ==> remainder of string
	 mov	 cx,(DMA_STR2-DMA_STR1)-1 ; Get length of the remainder

    repe cmpsb			; Compare 'em
	 REGREST <di,si,cx>	; Restore
	 jne	 short COPY_ROM_DMANEXT ; Jump if more to compare

	 mov	 ax,DMA_STR0[0].ELO ; Get first two bytes in string 0

	 cmp	 ax,es:[di-(DMA_STR1-DMA_STR0)-1] ; Same as in ROM?
	 jne	 short COPY_ROM_DMANEXT ; Not this time

	 mov	 ax,DMA_STR2[0].ELO ; Get first two bytes in string 2

	 cmp	 ax,es:[di+(DMA_STR2-DMA_STR1)-1] ; Same as in ROM?
	 jne	 short COPY_ROM_DMANEXT ; Not this time

	 mov	 dx,MAPTAB.MAP_PARA_SRC[si] ; Get source para
	 shl	 dx,4-0 	; Convert from paras to bytes
	 add	 dx,di		; Plus offset

	 mov	 al,0FFh	; Replace with this

	 cmp	 dx,8000h	; Into the second half?
	 jb	 short COPY_ROM_CPQ1 ; No, skip checksum update

	 sub	 es:[bx],al	; Subtract from checksum
COPY_ROM_CPQ1:
	 xchg	 al,es:[di-(DMA_STR1-DMA_STR0)][2-1] ; Patch it

	 cmp	 dx,8000h	; Into the second half?
	 jb	 short COPY_ROM_CPQ2 ; No, skip checksum update

	 add	 es:[bx],al	; Add into checksum
COPY_ROM_CPQ2:
	 mov	 al,0FFh	; Replace with this

	 cmp	 dx,8000h	; Into the second half?
	 jb	 short COPY_ROM_CPQ3 ; No, skip checksum update

	 sub	 es:[bx],al	; Subtract from checksum
COPY_ROM_CPQ3:
	 xchg	 al,es:[di+(DMA_STR2-DMA_STR1)][2-1] ; Patch it

	 cmp	 dx,8000h	; Into the second half?
	 jb	 short COPY_ROM_CPQ4 ; No, skip checksum update

	 add	 es:[bx],al	; Add into checksum
COPY_ROM_CPQ4:
	 jmp	 COPY_ROM_DMANEXT ; Go around again

COPY_ROM_EXIT:
	 REGREST <es,ds>	; Restore
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it
	 popa			; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

COPY_ROM endp			; End COPY_ROM procedure
	 FPPROC  UNSHADOW -- Disable System Usage Of Shadow RAM
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable the system's use of shadow RAM

|

	 REGSAVE <si>		; Save register

	 test	 SYS_FLAG,@SYS_CPQ ; Izit COMPAQ Deskpro 386/486?
	 jz	 short UNSHADOW_XCPQ ; Jump if not

	 test	 I15_FLAG,@I15_ROM ; Izit to be disabled?
	 jz	 short UNSHADOW_EXIT ; Jump if not

	 lea	 si,CPQMIO_LO	; DS:SI ==> 32-bit destination address
	 mov	 TOP_MIO,@CPQ_HRAM ; Mark as read-write, high-only

	 jmp	 short UNSHADOW_HRAM ; Join common code

UNSHADOW_XCPQ:
	 test	 SYS_FLAG,@SYS_AST386 ; Izit an AST Premium/386?
	 jz	 short UNSHADOW_XAST ; Jump if not

	 mov	 TOP_MIO,@AST_HRAM ; Mark as read-write, high-only
	 lea	 si,ASTMIO_LO	; DS:SI ==> 32-bit destination address

	 cmp	 LOWOFF.ELO,512 ; Only 512KB of base memory?
	 je	 short @F	; Yes

	 or	 TOP_MIO,@ASTMIO_N512*0101h ; Mark as not 512KB system
@@:
	 jmp	 short UNSHADOW_HRAM ; Join common code

UNSHADOW_XAST:
	 test	 CM2_FLAG,@CM2_TOP ; Izit generic top 384KB of RAM?
	 jz	 short UNSHADOW_XTOP ; Jump if not

	 lea	 si,CPQMIO_LO	; DS:SI ==> 32-bit destination address
	 mov	 TOP_MIO,@CPQ_HRAM ; Mark as read-write, high-only
UNSHADOW_HRAM:
	 test	 I15_FLAG,@I15_ROM ; Izit to be disabled?
	 jz	 short UNSHADOW_EXIT ; Jump if not

; Tell the system to decode the upper 128KB as high-only RAM

	 call	 INST_TMPINT15	; Install temporary INT 15h handler
	 call	 TOP_WRITE	; Write value in TOP_MIO to I/O port
	 call	 REST_TMPINT15	; Restore original INT 15h handler

	 jmp	 short UNSHADOW_EXIT ; Join common exit code

UNSHADOW_XTOP:





UNSHADOW_EXIT:
	 REGREST <si>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

UNSHADOW endp			; End UNSHADOW procedure

XCODE	 ends			; End XCODE segment


ECODE	 segment use16 dword public 'ecode' ; Start ECODE segment
	 assume  cs:PGROUP

	 public  @QMAX_TIM_ECODE
@QMAX_TIM_ECODE:		; Mark module start in .MAP file

	 extrn	 ENABLE_NMI:near
	 extrn	 CLR_PARITY:near

	 extrn	 SET_GDT:near
	 extrn	 RESET_KEYB:near

	 FPPROC  TIME_MEM -- Time Memory Accesses
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Time 32-bit memory accesses to the current data segment

On entry:

TIMER_DS =	 segment or selector of location to test

On exit:

AX	 =	 timer value

|

TIMER_STR struc

	 dd	 ?		; Caller's EBP
	 dd	 ?		; Caller's return address
TIMER_DS dw	 ?		; Segment/selector to time

TIMER_STR ends

@TIME_SIZE equ	 4		; # kilobytes to time

	 push	 ebp		; Prepare to address the stack
	 mov	 ebp,esp	; Hello, Mr. Stack

	 pushf			; Save flags
	 cld			; String ops forwardly
	 cli			; Disable interrupts

	 REGSAVE <cx,si,ds>	; Save register

	 mov	 ds,[ebp].TIMER_DS ; Get segment to time
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 si,si		; Offset zero
	 mov	 cx,@TIME_SIZE*1024/4 ; # iterations in units of dwords

	 call	 TIMER_SETUP	; Initialize timer channel 2

	 push	 eax		; Save for a moment
     rep lodsd
	 pop	 eax		; Restore

	 call	 TIMER_READ	; Latch and read timer 2 value into AX
	 call	 TIMER_RESTORE	; Restore timer channel 2

	 REGREST <ds,si,cx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 popf			; Restore flags

	 pop	 ebp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIME_MEM endp			; End TIME_MEM procedure
	 NPPROC  TIMER_SETUP -- Setup Timer
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SPEED	 equ	 8		; Assume worst case of 8MHz CPU

DELAY1US macro			; Delay for 1 microsecond

	 push	 cx		; Save for a moment
	 mov	 cx,1+1000/(11*SPEED) ; Account for CPU speed
	 loop	 $		; Wait for completion
	 pop	 cx		; Restore

	 endm

TIMER_SET equ	 (0*@TIMER_CH) or @TIMER_LMSB or (2*@TIMER_MODE) or @TIMER_BIN

	 REGSAVE <ax>		; Save register

	 mov	 al,TIMER_SET	; Setup counter 0, mode 2
	 out	 @8253_CTL,al
	 DELAY1US		; Wait for 1 microsecond

	 xor	 al,al		; Zero gives full count of 65536
	 out	 @8253_CH0,al	; Load low-order byte
	 DELAY1US		; Wait for 1 microsecond

	 out	 @8253_CH0,al	; Load high-order byte
	 DELAY1US		; Wait for 1 microsecond

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIMER_SETUP endp		; End TIMER_SETUP procedure
	 NPPROC  TIMER_RESTORE -- Restore Timer
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIMER_RESET equ  (0*@TIMER_CH) or @TIMER_LMSB or (3*@TIMER_MODE) or @TIMER_BIN

	 REGSAVE <ax>		; Save register

	 mov	 al,TIMER_RESET ; Setup counter 0, mode 3
	 out	 @8253_CTL,al
	 DELAY1US		; Wait for 1 microsecond

	 xor	 al,al		; Zero gives full count of 65536
	 out	 @8253_CH0,al	; Load low-order byte
	 DELAY1US		; Wait for 1 microsecond

	 out	 @8253_CH0,al	; Load high-order byte
	 DELAY1US		; Wait for 1 microsecond

	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIMER_RESTORE endp		; End TIMER_RESTORE procedure
	 NPPROC  TIMER_READ -- Read Timer
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIMER_LATCH equ  @TIMER_LATCH or (0*@TIMER_CH)

	 mov	 al,TIMER_LATCH ; Tell 8253 to latch channel 0

	 out	 @8253_CTL,al	; Latch current contents
	 DELAY1US		; Wait for 1 microsecond

	 in	 al,@8253_CH0	; Read in low-order byte
	 DELAY1US		; Wait for 1 microsecond

	 mov	 ah,al		; Copy
	 in	 al,@8253_CH0	; Read in high-order byte
	 DELAY1US		; Wait for 1 microsecond

	 xchg	 al,ah		; Swap for comparisons
	 neg	 ax		; Convert count down to count up

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIMER_READ endp 		; End TIMER_READ procedure

	 align	 4		; Ensure dword alignment

ECODE	 ends			; End ECODE segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 public  @QMAX_TIM_NCODE
@QMAX_TIM_NCODE:		; Mark module start in .MAP file

	 extrn	 EPM:near
	 extrn	 YMSGOUT:near
if @OEM_DEBUG
	 extrn	 SWATINI:near
endif				; IF @OEM_DEBUG

	 NPPROC  NRCACHE_INVD -- Invalidate cache by hand for timing
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Some systems have a broken WBINVD instruction (INVD is broken as
well).	This is due to a hardware bug in the chipset.

There's a software workaround.  Unfortunately, there's no way to
detect when it's needed.  The DEBUG=WBINVD keyword tells us to use WBINVD.
Otherwise, we assume it might be a faulty chipset and avoid it.

The workaround is to read twice as much data as the cache contains.
This could be 512K to 1MB (the P54C has a 512K cache).

Note that this routine is bimodal.

|

	 REGSAVE <eax,ecx,dx,esi,ds> ; Save

	 pushf			; Save interrupt flag

	 cld			; Set forward direction

	 smsw	 ax		; Get MSW
	 test	 ax,mask $PE	; Are we in protected mode?
	 jnz	 short CACHE_INVDPM ; Jump if so

; Invalidate cache from real mode.

	 cli			; Nobody move

	 sub	 dx,dx		; Starting segment
	 movzx	 ecx,CACHESZ_RM ; Number of 64K segments to read
@@:
	 sub	 esi,esi	; Starting offset
	 mov	 ds,dx		; Address segment
	 assume  ds:nothing	; Tell the assembler

	 push	 cx		; Save

	 mov	 cx,4000h	; 64K in dwords
  rep	 lods	 ds:[esi].EDD	; Read it

	 pop	 cx		; Restore

	 add	 dx,1000h	; Skip to next 64K segment

	 loop	 @B		; Go around again

	 jmp	 short CACHE_INVDRET ; Join common exit

; Invalidate cache from protected mode.  Note that we're using TDTE_GDT.
CACHE_INVDPM:
	 cli			; Nobody move

	 push	 TDTE_D4GB	; Get all memory selector for timing GDT
	 pop	 ds		; Address it
	 assume  ds:nothing	; Tell the assembler

	 mov	 ecx,CACHESIZE	; Dwords to read
	 sub	 esi,esi	; Starting offset
 S32 rep lods	 <ds:[esi].EDD> ; Read it

CACHE_INVDRET:
	 popf			; Restore IF

	 REGREST <ds,esi,dx,ecx,eax> ; Restore
	 assume  ds:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

NRCACHE_INVD endp		; End NRCACHE_INVD procedure

	 FPPROC  SAVE_CACHEPM -- Save and Disable Cache Controller (Bimodal)
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save the state of and disable the cache controller.

This procedure only operates on 486 or higher CPUs, and may be called
from protected mode.

On exit:

EBP	 =	 state of cache controller

|

	 REGSAVE <eax>		; Save register

; If we're on a 486 or later system, disable the cache through CR0

	 cmp	 CPUTYPE,04h	; Izit a 486 or later?
	 jb	 short SAVE_CACHE_X486 ; Jump if not

	 mov	 eax,cr0	; Get current value
	 mov	 ebp,eax	; Save to restore later
	 or	 eax,CACHEMASK	; Disable caching if specified

	 WBPAT	 NRCACHE_INVD,PGROUP ; Invalidate cache for timing

	 mov	 cr0,eax	; Tell the CPU about it

	 WBPAT	 NRCACHE_INVD,PGROUP ; Invalidate cache for timing


;;;;;;;  jmp	 short SAVE_CACHEPM_EXIT ; Join common exit code

SAVE_CACHE_X486:
SAVE_CACHEPM_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_CACHEPM endp		; End SAVE_CACHEPM procedure
	 FPPROC  REST_CACHEPM -- Restore Cache Controller (Bimodal)
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore the state of the cache controller on 486 systems.

This procedure may be called from protected mode.

On entry:

EBP	 =	 original state of cache controller

|

	 REGSAVE <eax>		; Save register

; If we're on a 486 or later system, restore the state of the cache

	 cmp	 CPUTYPE,04h	; Izit a 486 or later?
	 jb	 short REST_CACHE_X486 ; Jump if not

	 mov	 eax,cr0	; Get current value
;;;;;;;  and	 eax,(not CACHEMASK) ; Turn off CD and NW disable bits
	 not	 eax		; Flip bits
	 or	 eax,CACHEMASK	; Turn on bits we want off
	 not	 eax		; Turn off CD and NW disable bits
	 and	 ebp,CACHEMASK	; Isolate original state
	 or	 eax,ebp	; Set to previous value

	 WBPAT	 NRCACHE_INVD,PGROUP ; Invalidate cache for timing

	 mov	 cr0,eax	; Tell the CPU about it

	 WBPAT	 NRCACHE_INVD,PGROUP ; Invalidate cache for timing

;;;;;;;  jmp	 short REST_CACHEPM_EXIT ; Join common exit code

REST_CACHE_X486:
REST_CACHEPM_EXIT:
	 REGREST <eax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_CACHEPM endp		; End REST_CACHEPM procedure
	 FPPROC  TIME_ALLMEM -- Time Memory Accesses
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Time memory accesses in extended memory and manage MAP_STR.

On exit:

CF	 =	 0 if all went OK
	 =	 1 if something went wrong

|

	 REGSAVE <eax,ebx,cx,edx,si,di,ds,es,fs,gs> ; Save registers

	 push	 seg PGROUP	; Setup ES for INT 15h call
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 test	 CM2_FLAG,@CM2_NOTIME ; Was NOTIME specified?
	 jz	 short @F	; Jump if not

	 mov	 ebx,PHYSIZE	; Load MAX at the top of memory
	 mov	 LMLTOP,ebx	; Specify load address
	 mov	 MEMTIME,0AAAAh ; Pretend all extended memory is slow
	 or	 LCL_FLAG,@LCL_LML ; Mark as low memory load
	 jmp	 TIME_ALLMEM_FF00 ; Check for NOWARMBOOT

@@:
; Compute high memory address for TDTE_ES

	 mov	 eax,SHDTAB.SHD_EBASE ; Use base of shadow RAM for 4KB

	 cmp	 SHDSIZE,0	; Any shadow RAM?
	 jne	 short @F	; Yes, use it

	 mov	 eax,PHYSIZE	; Get size of physical memory
	 shl	 eax,10-0	; Convert from 1KB to bytes
	 sub	 eax,CON4KB	; Less a 4KB page's worth
@@:
	 mov	 TDESC_TAB.TDTE_ES.DESC_BASE01.EDD,eax
	 rol	 eax,8		; Rotate out the high-order byte
	 mov	 TDESC_TAB.TDTE_ES.DESC_BASE3,al
	 ror	 eax,8		; Rotate back
	 mov	 TDESC_TAB.TDTE_ES.DESC_SEGLM0,0FFFFh ; 64KB of data
	 mov	 TDESC_TAB.TDTE_ES.DESC_SEGLM1,0
	 mov	 TDESC_TAB.TDTE_ES.DESC_ACCESS,CPL0_DATA

; Ensure shadow RAM (if any) is initialized

	 call	 SCRUB_SHADOW	; Initalize shadow RAM

	 call	 SAVE_CACHERM	; Save and disable the state of the
				; cache controller for Compaq and HP 386's
				; BP = current state

	 CHECK	 1		; Checkpoint

	 lea	 si,TDESC_TAB	; ES:SI ==> descriptor tables
	 call	 EPM		; Use common subroutine to Enter Protected Mode
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it
	 jnc	 short TIME_ALLMEM1 ; Jump if we succeeded

; Return in protected mode with interrupts and NMI disabled

TIME_ALLMEM_ERRPROT:
	 mov	 ERR_CODE,ah	; Save error code
	 or	 ERR_FLAG,@ERR_TIM ; Mark as in error

	 jmp	 TIME_ALLMEM_ERR ; Join common error code

TIME_ALLMEM1:

	 CHECK	 2		; Checkpoint

if @OEM_DEBUG

; See if we should invoke SWAT

	 test	 DB3_FLAG,@DB3_TIME ; Time for SWAT?
	 jz	 short @F	; Jump if not

	 call	 SWATINI	; Initialize 386SWAT
	 jc	 short @F	; Jump if not loaded

	 int	 01h		; Call our debugger
@@:
endif				; IF @OEM_DEBUG

; Note that we CANNOT do this just before entering protected mode, as it
; will cause some systems (PS/ValuePoint 486DX2, Gateway) to go south...
	 FCALL	 SAVE_CACHEPM	; Save and disable cache controller for 486
				; BP = current state

; Time high memory

	 push	 TDTE_ES	; Pass segment of high memory
	 FCALL	 TIME_MEM	; Return with AX = timer value

	 mov	 MEMTIME_HI,ax	; Save for later use
	 mov	 MEMTIME,ax	; Save for later use in case we don't LML

	 call	 CLR_PARITY	; Clear any parity errors

; Time middle memory to see if it's faster than high memory
; Start at 1MB and proceed upwards in 128 KB blocks until the
; time x 1.5 is better than MEMTIME_HI

	 mov	 ebx,CON1MB	; Get starting address
	 mov	 MEMTIME_MD,0AAAAh ; Save big value to ensure initial failure
	 mov	 edx,PHYSIZE	; Get top of physical memory
	 shl	 edx,10-0	; Convert from 1KB to bytes

	 CHECK	 3		; Checkpoint
TIME_ALLMEM_MID_NEXT:
	 cmp	 ebx,edx	; Check against top of physical memory
	 jae	 short TIME_ALLMEM_MID_EXIT ; That's all folks

	 mov	 TDESC_TAB.TDTE_ES.DESC_BASE01.EDD,ebx ; Save base address
	 rol	 ebx,8		; Rotate out the high-order byte
	 mov	 TDESC_TAB.TDTE_ES.DESC_BASE3,bl
	 ror	 ebx,8		; Rotate back
	 mov	 TDESC_TAB.TDTE_ES.DESC_ACCESS,CPL0_DATA ; Save access rights

; Time the middle memory

	 push	 TDTE_ES	; Pass segment of middle memory
	 FCALL	 TIME_MEM	; Return with AX = timer value

	 call	 CLR_PARITY	; Clear any parity errors

; Save the smaller of this time and the best time so far

	cmp	ax,MEMTIME_MD	; Use smaller of the two to avoid creeping diff
	jae	short @F	; Jump if new time is not smaller

	mov	MEMTIME_MD,ax	; Save new smaller time
@@:
	mov	cx,ax		; Copy middle time to halve
	shr	cx,1		; Get  0.5 x time
	add	cx,ax		; Plus 1.0 x time to get 1.5 x

	cmp	cx,MEMTIME_HI	; Check against high memory time
	jb	short TIME_ALLMEM_MID_EXIT ; That's all folks

	 add	 ebx,CON128KB	; Skip to next section

	 jmp	 short TIME_ALLMEM_MID_NEXT ; Go around again

TIME_ALLMEM_MID_EXIT:
	 FCALL	 REST_CACHEPM	; Restore state of cache controller from BP
				; for 486 systems.

	 CHECK	 4		; Checkpoint

	 shr	 ebx,10-0	; Convert from bytes to 1KB

	 cmp	 ebx,PHYSIZE	; Ensure no larger
	 jbe	 short TIME_ALLMEM_MID_EXIT1 ; It's within range

	 mov	 ebx,PHYSIZE	; Use maximum
TIME_ALLMEM_MID_EXIT1:
	 test	 LCL_FLAG,@LCL_LML ; Izit already set?
	 jnz	 short @F	; Jump if so

	 mov	 LMLTOP,ebx	; Save as LML top
@@:
TIME_ALLMEM_A31COM:
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 CHECK	 7		; Checkpoint

; Ensure all selectors are in one-to-one 64KB memory

	 mov	 ax,TDTE_SS	; Get one-to-one 64KB selector
	 mov	 ds,ax		; Set 'em up
	 mov	 es,ax
	 mov	 fs,ax
	 mov	 gs,ax
;;;;;;;; mov	 ss,ax
;;;;;;;; mov	 sp,sp
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

; Enter real mode

	 call	 GOREAL_SUB	; Enter real mode
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 CHECK	 8		; Checkpoint

; Restore original master and slave interrupt masks

	 call	 ENABLE_IMR	; Enable the 8259 interrupt mask register

	 call	 RESET_KEYB	; Ensure the keyboard is reset

	 sti			; Enable interrupts

	 call	 ENABLE_NMI	; Enable NMI, clear the parity latches

	 cmp	 ERR_CODE,0	; Check for error code
	 je	 short TIME_ALLMEM_LOW ; Jump if no error
TIME_ALLMEM_ERR:
	 mov	 al,ERR_CODE	; Get the error code
	 lea	 si,YGROUP:MSG_ERRTIM1 ; YGROUP:SI ==> error code save area
	 call	 FMT_ERR_CODE	; Format the error code

	 push	 offset YGROUP:MSG_ERRTIM ; Tell 'em the bad news
	 call	 YMSGOUT	; Display YGROUP message

	 stc			; Indicate something went wrong

	 jmp	 TIME_ALLMEM_EXIT ; Join common exit code

; Time low memory accesses

TIME_ALLMEM_LOW:
	 mov	 bx,LOWOFF.ELO	; Get top of original DOS memory
	 sub	 bx,@TIME_SIZE	; Back off by amount to time
	 shl	 bx,10-4	; Convert from 1KB to paras

	 call	 SAVE_CACHEPM	; Save and disable cache controller for 486
				; BP = current state

	 push	 bx		; Pass segment argument
	 call	 TIME_MEM	; Return with AX = timer value

	 call	 REST_CACHEPM	; Restore state of cache controller from BP
				; for 486 systems.

	 mov	 MEMTIME_LO,ax	; Save for later use

	 call	 CALC_FORCE	; Calculate if we're forced ON

	 test	 CMD_FLAG,@CMD_XDM ; NODMA specified?
	 jnz	 short TIME_ALLMEM2 ; Yes, so no low memory load

	 test	 GLB_FLAG,@GLB_FORC ; Is the ON state forced?
	 jz	 short TIME_ALLMEM2 ; No, so no low memory load

; Skip low memory load if using shadow RAM

;;;;;;;; cmp	 SHDSIZE,0	; Any shadow RAM?
;;;;;;;; jne	 short TIME_ALLMEM2 ; Yes, so no low memory load

; If high memory accesses are worse than 1.5 x middle memory accesses
; mark as low memory load

	 mov	 ax,MEMTIME_MD	; Get middle memory access time
	 mov	 bx,ax		; Copy to halve
	 shr	 bx,1		; Get  0.5 x middle time
	 add	 bx,ax		; Plus 1.0 x middle time to get 1.5 x

	 cmp	 bx,MEMTIME_HI	; Which is better?
	 jb	 short TIME_ALLMEM_LML ; Jump if ext memory is slower than middle
				; Use LMLTOP as calculated above

; If high memory accesses are worse than 1.5 x low memory accesses
; mark as low memory load

	 mov	 ax,MEMTIME_LO	; Get low memory access time
	 mov	 bx,ax		; Copy to halve
	 shr	 bx,1		; Get  0.5 x low time
	 add	 bx,ax		; Plus 1.0 x low time to get 1.5 x

	 cmp	 bx,MEMTIME_HI	; Which is better?
	 jae	 short TIME_ALLMEM2 ; Jump if extended memory is reasonably fast

	 test	 LCL_FLAG,@LCL_LML ; Izit already set?
	 jnz	 short TIME_ALLMEM_LML ; Jump if so

	 mov	 ebx,LOWOFF	; Get top of low memory load
	 mov	 LMLTOP,ebx	; Save for later use
TIME_ALLMEM_LML:
	 mov	 MEMTIME,ax	; Save as the best time
	 or	 LCL_FLAG,@LCL_LML ; Mark as low memory load
TIME_ALLMEM2:
	 call	 REST_CACHERM	; Restore state of cache controller from BP
				; for Compaq and HP 386 systems.

; If ROM memory accesses are worse than 1.5 x best memory accesses
; mark ROMs to be moved into LML memory

; Because an XT's hard disk and system ROM are so timing dependent,
; we can't afford to swap them with fast RAM.
; We force NOROM in MARK_XT, but allow the user to override it
; with ROM= statements.

if @OEM_SYS eq @OEMSYS_ILIM
	 test	 SYS_FLAG,@SYS_INBRDPC ; Running on an Inboard/PC?
	 jnz	 near ptr TIME_ALLMEM_END ; Yes, skip all this
endif				; IF @OEM_SYS eq @OEMSYS_ILIM

;;;;;;;; test	 LCL_FLAG,@LCL_XT ; Running on an XT?
;;;;;;;; jnz	 short TIME_ALLMEM_FF00 ; Yes, just check for NOWARMBOOT
;;;;;;;;
	 call	 TIME_ROM	; Search for ROMs in MEM_MAP

	 mov	 ax,MEMTIME	; Get best memory access time
	 mov	 bx,ax		; Copy to halve
	 shr	 bx,1		; Get  0.5 x best time
	 add	 ax,bx		; Plus 1.0 x best time to get 1.5 x

	 xor	 si,si		; Initialize index into MAPTAB

	 mov	 cx,MAPTAB_CNT	; Get # entries
	 jcxz	 @F		; Jump if no entries to test
	 jmp	 short TIME_ALLMEM_NEXT1 ; make a short jump
@@:
	 jmp	 TIME_ALLMEM_FF00  ; make a long jump

TIME_ALLMEM_NEXT1:
	 test	 MAPTAB.MAP_FLAG[si],@MAP_ROM ; Izit ROM?
	 jz	 TIME_ALLMEM_LOOP ; Not this one

; If this matches the PnP RM data segment, ensure it doesn't get swapped

	mov	bx,PnP_DATA	; Get the PnP data segment
	and	bx,not ((4*1024/16)-1) ; Round down to 4KB boundary in paras
	jz	short @F	; Jump if not present

	cmp	bx,MAPTAB[si].MAP_PARA_SRC ; Duzit match?
	je	near ptr TIME_ALLMEM_LOOP ; Jump if so
@@:

; Force swap of EGA ROM if shadow RAM

	 test	 CM2_FLAG,@CM2_SHD ; Izit AT386 or NEAT shadow RAM?
	 jz	 short TIME_ALLMEM_NEXT1A ; Not this time

	 cmp	 MAPTAB.MAP_PARA_SRC[si],0C800h ; Izit EGA ROM?
	 jb	 short TIME_ALLMEM_SWAP ; Yes, so be sure to swap it
TIME_ALLMEM_NEXT1A:
	 test	 SYS_FLAG,@SYS_CPQ ; Izit a COMPAQ DP 386?
	 jz	 short TIME_ALLMEM_NEXT1B ; Not this time

	 test	 MAPTAB.MAP_FLAG[si],@MAP_BIOS ; Izit system ROM?
	 jnz	 short TIME_ALLMEM_SWAP ; Yes, so be sure to swap it

TIME_ALLMEM_NEXT1B:
	 cmp	 ax,MAPTAB.MAP_TIME[si] ; Compare 'em
	 jae	 short TIME_ALLMEM_LOOP ; ROM time is better, don't swap it
TIME_ALLMEM_SWAP:
	 test	 MAPTAB.MAP_FLAG[si], @MAP_BIOS ; Izit system ROM?
	 jz	 TIME_ALLMEM_XKEYB	; Nope - skip this

; Check SHAD_KEYB_DLY - if non-zero, blast it into 40:B0
; This value may be set by any system recognition routine such as
; for Dell and ALR.

	 push	 seg XGROUP		; Get segment value for XGROUP
	 pop	 fs			; Use FS to point to XGROUP
	 assume  fs:XGROUP		; Tell the assembler about it

	 sub	 bx, bx 		; Clear BX
	 xchg	 bl, SHAD_KEYB_DLY	; Get value to be blasted and reset it
	 assume  fs:nothing		; Forget about FS
	 or	 bl, bl 		; Izit 0?
	 jz	 TIME_ALLMEM_XKEYB	; Yes; go ahead and copy ROM

	 push	 seg BIOSDATA		; Get segment value for BIOSDATA
	 pop	 fs			; Use FS to point to BIOSDATA
	 assume  fs:BIOSDATA		; Tell the assembler about it
	 mov	 DELL_KEYB, bx		; Blast away!
	 assume  fs:nothing		; Forget about contents of FS

TIME_ALLMEM_XKEYB:
	 mov	 bx,MAPTAB.MAP_LEN[si] ; Get length in paras
	 shr	 bx,10-4	; Convert from paras to 1KBs
	 add	 MAPSIZE,bx	; Add into total size
	 or	 MAPTAB.MAP_FLAG[si],@MAP_SWAP ; Mark as subject to swapping

; Unless NOWARMBOOT is specified, if this is in system ROM mark as
; containing warm boot location

	 test	 CM2_FLAG,@CM2_NWB ; NOWARMBOOT specifed?
	 jnz	 short TIME_ALLMEM_COPY1 ; Yes

	 test	 MAPTAB.MAP_FLAG[si],@MAP_BIOS ; Izit system ROM?
	 jz	 short TIME_ALLMEM_COPY1 ; Not this time

	 or	 MAPTAB.MAP_FLAG[si],@MAP_BOOT ; Mark as warm boot location
TIME_ALLMEM_COPY1:
	 call	 COPY_ROM	; Copy the ROM to local memory
TIME_ALLMEM_LOOP:
	 add	 si,type MAP_STR ; Skip to next entry

	 dec	 cx			; Simulate loop
	 jnz	 near ptr TIME_ALLMEM_NEXT1 ; Jump if more entries

TIME_ALLMEM_FF00:
	 test	 CM2_FLAG,@CM2_NWB ; NOWARMBOOT specifed?
	 jnz	 near ptr TIME_ALLMEM_END ; Yes, skip out

; Unless there's already a ROM swap for the memory at FF00:0 L 0100,
; put one in.  This way, we can be sure of handling warm boot to F000:FFF0

	 mov	 cx,MAPTAB_CNT	; Get # entries
	 jcxz	 TIME_ALLMEM_NEW ; Add a new entry
	 xor	 si,si		; Initialize index into MAPTAB
TIME_ALLMEM_NEXT2:
	 test	 MAPTAB.MAP_FLAG[si],@MAP_ROM ; Izit ROM?
	 jz	 short TIME_ALLMEM_LOOP2 ; Not this one

	 mov	 ax,MAPTAB.MAP_PARA_SRC[si] ; Get starting para #
	 add	 ax,MAPTAB.MAP_LEN[si] ; Plus length in paras
	 jc	 short TIME_ALLMEM_CHOP ; Carry means it encompasses it

TIME_ALLMEM_LOOP2:
	 add	 si,type MAP_STR ; Skip to next entry

	 loop	 TIME_ALLMEM_NEXT2 ; Jump if more entries

	 jmp	 short TIME_ALLMEM_NEW ; None found, add in as new entry

TIME_ALLMEM_CHOP:

; We found the entry which encompasses the reboot location.

	 test	 MAPTAB.MAP_FLAG[si],@MAP_SWAP ; Marked as swappable?
	 jnz	 short TIME_ALLMEM_END ; Yes, join common exit code

; Subtract 4KB from the entry and add in that part as a new entry

	 sub	 MAPTAB.MAP_LEN[si],4*1024/16 ; Chop off top 4KB of this ROM
	 or	 MAPTAB.MAP_FLAG[si],@MAP_CHOP ; Mark as chopped
	 and	 MAPTAB.MAP_FLAG[si],not @MAP_BOOT ; No longer warm boot loc

; Add a new entry to MAPTAB

TIME_ALLMEM_NEW:
	 mov	 si,MAPTAB_IND	; Index of next entry

	 test	 SYS_FLAG,@SYS_CPQ ; Izit a COMPAQ Deskpro 386?
	 jz	 short TIME_ALLMEM_NEW1 ; No

	 mov	 MAPTAB.MAP_PARA_SRC[si],0F800h ; Set starting para
	 mov	 MAPTAB.MAP_PARA_DST[si],0F800h ; Set starting para
	 mov	 MAPTAB.MAP_LEN[si],  0800h ; Set length in paras
	 add	 MAPSIZE,32	; Plus 32KB in mapping region

	 jmp	 short TIME_ALLMEM_NEW2 ; Join common code

TIME_ALLMEM_NEW1:
	 mov	 MAPTAB.MAP_PARA_SRC[si],0FF00h ; Set starting para
	 mov	 MAPTAB.MAP_PARA_DST[si],0FF00h ; Set starting para
	 mov	 MAPTAB.MAP_LEN[si],  0100h ; Set length in paras
	 add	 MAPSIZE,4	; Plus 4KB in mapping region
TIME_ALLMEM_NEW2:

; Mark as swappable system ROM with warm boot location

	 mov	 MAPTAB.MAP_FLAG[si],@MAP_ROM or @MAP_SWAP or @MAP_BOOT or @MAP_BIOS

	 call	 COPY_ROM	; Copy the ROM to local memory

	 add	 si,type MAP_STR ; Skip to next entry
	 mov	 MAPTAB_IND,si	; Save as new index
	 inc	 MAPTAB_CNT	; Count in another entry
TIME_ALLMEM_END:

; Add a new entry to MAPTAB for the PnP BIOS entry point

	call	CACHE_PnP	; Cache the one or two 4KB PnP struc blocks

	 call	 UNSHADOW	; Disable the system's use of shadow RAM (if any)

	 clc			; Indicate all went OK
TIME_ALLMEM_EXIT:
	 REGREST <gs,fs,es,ds,di,si,edx,cx,ebx,eax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIME_ALLMEM endp		; End TIME_ALLMEM procedure
	NPPROC	CACHE_PNP -- Cache The PnP Struc In BIOS
	assume	ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Cache the PnP struc in the BIOS

|

	REGSAVE <ax,ebx,cx,edx,si> ; Save registers

	mov	ax,PnP_SEG	; Get the PnP struc segment in BIOS

	and	ax,ax		; Izit present?
	jz	near ptr CACHE_PnP_EXIT ; Jump if not

	mov	ebx,0F800h	; Get system ROM cache start if CPQ

	test	SYS_FLAG,@SYS_CPQ ; Izit a COMPAQ Deskpro 386?
	jnz	short @F	; Jump if so

	mov	ebx,0FF00h	; Get system ROM cache start for all others
@@:

; If NOWARMBOOT is specified, we needn't check for the PnP struc
; overlapping the warm boot location

	test	CM2_FLAG,@CM2_NWB ; NOWARMBOOT specifed?
	jnz	short @F       ; Yes, skip test

	cmp	ax,bx		; Izit entirely in the reboot location?
	jae	near ptr CACHE_PnP_EXIT ; Jump if so (nothing more to do)
@@:

; It's just possible that the PnP struc overlaps into the reboot location
; unless NOWARMBOOT is specified.
; If so, we cache just the lower 4KB and let the reboot caching code
; which has already run cache the rest.

	movzx	edx,ax		; Copy to calculate length
	add	edx,((type PnP_STR)+16-1)/16 ; Plus size of struc in paras

	test	CM2_FLAG,@CM2_NWB ; NOWARMBOOT specifed?
	jnz	short @F       ; Yes, skip test

	cmp	edx,ebx 	; Izit overlapping into the reboot location?
	jb	short @F	; Jump if not

	and	edx,not (4*1024/16-1) ; Round down to 4KB boundary in paras
@@:
	add	edx,4*1024/16-1  ; Round up to 4KB boundary in paras
	and	edx,not (4*1024/16-1) ; ...

	and	ax,not (4*1024/16-1) ; Round down to 4KB boundary in paras

; See if this entry overlaps an existing entry
; AX	=	starting para of PnP entry (rounded down to 4KB boundary)
; DX	=	ending ...		   (...     up ...		)

	xor	si,si		; Initialize index into MAPTAB
	mov	cx,MAPTAB_CNT	; Get # entries
	jcxz	CACHE_PnP_ADD	; Jump if no entries
CACHE_PnP_NEXT:
	mov	bx,MAPTAB[si].MAP_PARA_SRC ; Get starting para

	cmp	dx,bx		; Duzit end after start of this entry?
	jbe	short CACHE_PnP_LOOP ; Jump if not (no overlap)

	add	bx,MAPTAB[si].MAP_LEN ; Plus length in paras

; BX	=	ending para of current entry

	cmp	ax,bx		; Duzit start after ending of this entry?
	jae	short CACHE_PnP_LOOP ; Jump if so (no overlap)

; At this point, the PnP entry and the current ROM entry overlap

	bts	MAPTAB[si].MAP_FLAG,$MAP_SWAP ; Mark as swappable
	jc	short @F	; Jump if already so marked

	push	ax		; Save for a moment

	mov	ax,MAPTAB.MAP_LEN[si] ; Get length in paras
	shr	ax,10-4 	; Convert from paras to 1KBs
	add	MAPSIZE,ax	; Add into total size

	pop	ax		; Restore

	call	COPY_ROM	; Copy the ROM to local memory
@@:

; If the ending of the PnP entry is at or below the ending of the current
; entry, we can shorten the PnP entry to end at the start of the current
; entry.

	cmp	dx,bx		; Duzit end at or below current entry?
	ja	short @F	; Jump if not

	mov	dx,MAPTAB[si].MAP_PARA_SRC ; Make PnP end = start of current entry
@@:

; If the start of the PnP entry is at or above the start of the current
; entry, we can shorten the PnP entry to start at the end of the current
; entry.

	cmp	ax,MAPTAB[si].MAP_PARA_SRC ; Duzit start at or above current entry?
	jb	short @F	; Jump if not

	mov	ax,bx		; Make PnP start = end of current entry
@@:

; If there's anything left in the PnP entry, set the current entry's
; start and length to that of the PnP entry.

	sub	dx,ax		; Subtract to get length in paras (/4KB)
	jbe	short CACHE_PnP_EXIT ; Jump if empty

COMMENT|

Technically, we can never get here because the PnP struc is only 34
bytes long.  This means that the PnP struc can span at most two 4KB
entries.  Thus, it can never start below an existing ROM entry as well
as end above the same ROM (that could only happen if the PnP struc
spanned at least three 4KB pages).  Nonetheless, the code below should
work.

|

	mov	MAPTAB[si].MAP_PARA_SRC,ax ; Save as source para
	mov	MAPTAB[si].MAP_PARA_DST,ax ; ...     destin ...
	mov	bx,dx		; Copy length
	xchg	bx,MAPTAB[si].MAP_LEN	   ; Swap with length

	shr	bx,10-4 	; Convert from paras to 1KB
	sub	MAPSIZE,bx	; Less 4KB in mapping region

	shr	dx,10-4 	; Convert from paras to 1KB
	add	MAPSIZE,dx	; Plus 4KB in mapping region

; Mark as swappable ROM

	mov	MAPTAB.MAP_FLAG[si],@MAP_ROM or @MAP_SWAP

	call	COPY_ROM	; Copy the ROM to local memory

	jmp	short CACHE_PnP_EXIT ; Join common exit code

CACHE_PnP_LOOP:
	add	si,type MAP_STR ; Skip to next entry

	loop	CACHE_PnP_NEXT	; Jump if more entries to check
CACHE_PnP_ADD:
	sub	dx,ax		; Subtract to get length in paras (/4KB)
	jbe	short CACHE_PnP_EXIT ; Jump if empty

	mov	si,MAPTAB_IND	; Index of next entry
	mov	MAPTAB.MAP_PARA_SRC[si],ax ; Set starting para
	mov	MAPTAB.MAP_PARA_DST[si],ax ; ...
	mov	MAPTAB.MAP_LEN[si],dx ; Set length in paras
	shr	dx,10-4 	; Convert from paras to 1KB
	add	MAPSIZE,dx	; Plus 4KB in mapping region

; Mark as swappable ROM

	mov	MAPTAB.MAP_FLAG[si],@MAP_ROM or @MAP_SWAP

	call	COPY_ROM	; Copy the ROM to local memory

	add	si,type MAP_STR ; Skip to next entry
	mov	MAPTAB_IND,si	; Save as new index
	inc	MAPTAB_CNT	; Count in another entry
CACHE_PnP_EXIT:
	REGREST <si,edx,cx,ebx,ax> ; Restore

	ret			; Return to caller

	assume	ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CACHE_PNP endp			; End CACHE_PNP procedure
	 FPPROC  TMPINT15 -- Temporary INT 15h Handler
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Temporary INT 15h handler.

Convert parity errors into normal return.

|

ARG_STR  struc

	 dw	 ?		; Caller's BP
ARG_CSIP dd	 ?		; Caller's return address
ARG_FLG  dw	 ?		; Caller's flags

ARG_STR  ends

	 pushf			; Save flags

	 cmp	 ah,87h 	; Check for block move
	 jne	 short TMPINT15_ORIG ; Not this time, continue on

	 popf			; Restore

; Set flags to caller's value (IF is the only important one)

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack
	 push	 [bp].ARG_FLG	; Put flags onto stack
	 popf			; Restore caller's IF
	 pop	 bp		; Restore

	 pushf			; Simulate INT calling environment
	 cli
	 call	 OLDTMPINT15_VEC ; Call original handler

	 pushf			; Save flags for a moment

	 cmp	 CPUTYPE,04h	; Izit a 486 or later?
	 jb	 short @F	; Jump if not

	 WBPAT	 NRCACHE_INVD,PGROUP ; Invalidate cache data for timing
@@:
	 popf			; Restore flags

	 jnc	 short TMPINT15_RETF ; No problem, return to caller

	 pushf			; Save flags

	 cmp	 ah,01h 	; Check for parity error
	 jne	 short TMPINT15_RETF0 ; Not this time

	 popf			; Restore

	 xor	 ah,ah		; Normal return code, CF=0, ZF=1

	 jmp	 short TMPINT15_RETF ; Join common exit code

TMPINT15_RETF0:
	 popf			; Restore
TMPINT15_RETF:
	 ret	 2		; Return to caller, popping flags

TMPINT15_ORIG:
	 popf			; Restore flags

	 jmp	 OLDTMPINT15_VEC ; Continue on

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TMPINT15 endp			; End TMPINT15 procedure
	 NPPROC  SCRUB_SHADOW -- Initialize Shadow RAM
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Initialize shadow RAM to avoid parity errors.

|

	 REGSAVE <eax,bx,ecx,si,edi,ds,es,fs,gs> ; Save registers

	 test	 CM3_FLAG,@CM3_XSCRB ; NOSCRUB specified?
	 jnz	 short SCRUB_SHADOW_EXIT0 ; Yes, so skip all this

	 cmp	 SCRBCNT,0	; Get count of scrub RAM entries
	 je	 short SCRUB_SHADOW_EXIT0 ; None this time

	 CHECK	 9		; Checkpoint

	 lea	 si,TDESC_TAB	; ES:SI ==> descriptor tables
	 call	 EPM		; Use common subroutine to Enter Protected Mode
	 assume  ds:PGROUP,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it
	 jnc	 short SCRUB_SHADOW_PROT ; Jump if we succeeded

	 mov	 ERR_CODE,ah	; Save error code
	 or	 ERR_FLAG,@ERR_TIM ; Mark as in error
SCRUB_SHADOW_EXIT0:
	 jmp	 SCRUB_SHADOW_EXIT ; Join common exit code

SCRUB_SHADOW_PROT:
	 CHECK	 10		; Checkpoint

if @OEM_DEBUG

; See if we should invoke SWAT

	 test	 DB3_FLAG,@DB3_SCRUB ; Time for SWAT?
	 jz	 short @F	; Jump if not

	 call	 SWATINI	; Initialize 386SWAT
	 jc	 short @F	; Jump if not loaded

	 int	 01h		; Call our debugger
@@:
endif				; IF @OEM_DEBUG
	 call	 SHADOW_ENABLE	; Set shadow RAM on CHIPSets to read-write

	 mov	 cx,SCRBCNT	; Get count of scrub RAM entries
	 lea	 si,SCRBTAB	; DS:SI ==> scrub RAM structure
SCRUB_SHADOW_NEXT:
	 REGSAVE <cx,si>	; Save for a moment

	 mov	 eax,PGROUP:[si].SCRB_EBASE ; Get base of RAM
	 movzx	 ecx,PGROUP:[si].SCRB_ESIZE ; Get size of block in 1KB
	 shl	 ecx,10-0	; Convert from 1KB to bytes

	 push	 ecx		; Pass size of block
	 push	 CPL0_DATA or CPL0 ; Pass access rights byte
	 push	 DTE_BIOS	; Pass descriptor to set
	 call	 SET_GDT	; Set the GDT to EAX base

	 push	 ds		; Setup ES for MOVSD
	 pop	 es
	 assume  es:PGROUP	; Tell the assembler about it

	 lea	 si,DESC_TAB.TDTE_BIOS ; DS:SI ==> above entry in DESC_TAB
	 lea	 di,TDESC_TAB.TDTE_BIOS ; ES:DI ==> above entry in TDESC_TAB
S16	 movsd			; Move both dwords
S16	 movsd

	 push	 DTE_BIOS	; Get destination selector
	 pop	 es		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 xor	 edi,edi	; ES:EDI ==> start of this block of shadow RAM
	 shr	 ecx,2-0	; Convert from bytes to dwords

	 xor	 eax,eax	; Set to zero in case some programs expect it

	 REGSAVE <ecx,edi>	; Save for a moment
     rep stos	 es:[edi].EDD	; Store a value there (any value)
	 REGREST <edi,ecx>	; Restore

	 REGSAVE <ecx,edi>	; Save for a moment
     rep stos	 es:[edi].EDD	; Store a value there (any value)
	 REGREST <edi,ecx>	; Restore

	 REGSAVE <ecx,edi>	; Save for a moment
     rep stos	 es:[edi].EDD	; Store a value there (any value)
	 REGREST <edi,ecx>	; Restore

	 REGREST <si,cx>	; Restore

	 add	 si,size SCRB_STR ; Skip to next entry

	 loop	 SCRUB_SHADOW_NEXT ; Jump if more entries

	 CHECK	 11		; Checkpoint

	 call	 SHADOW_DISABLE ; Set shadow RAM on CHIPSets to original values

; Ensure all selectors are in one-to-one 64KB memory

	 mov	 ax,TDTE_SS	; Get one-to-one 64KB selector
	 mov	 ds,ax		; Set 'em up
	 mov	 es,ax
	 mov	 fs,ax
	 mov	 gs,ax
;;;;;;;; mov	 ss,ax
;;;;;;;; mov	 sp,sp
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

; Enter real mode

	 call	 GOREAL_SUB	; Enter real mode
	 assume  ds:PGROUP,es:PGROUP ; Tell the assembler about it

	 CHECK	 12		; Checkpoint

; Restore original master and slave interrupt masks

	 call	 ENABLE_IMR	; Enable the 8259 interrupt mask register

	 call	 RESET_KEYB	; Ensure the keyboard is reset

	 sti			; Enable interrupts

	 call	 ENABLE_NMI	; Enable NMI, clear the parity latches
SCRUB_SHADOW_EXIT:
	 REGREST <gs,fs,es,ds,edi,si,ecx,bx,eax> ; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 assume  fs:nothing,gs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SCRUB_SHADOW endp		; End SCRUB_SHADOW procedure
	 NPPROC  TIDTPROC -- Timer IDT Procedures
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Timer IDT procedures -- just blink the LEDs forever.

|

TINT_MAC macro	 INTNO1,INTNO2
	 local	 LAB

	 .xcref  TINTPROC&INTNO1
	 public  TINTPROC&INTNO1
TINTPROC&INTNO1:
	 push	 ax		;; Save for a moment
	 mov	 ax,INTNO2	;; Save interrupt #

	 jmp	 short TINTCOM	;; Join common code

	 endm			; TINT_MAC

CNT	 =	 0

.xlist
	 rept	 NTIDT		; Define interrupts 00h to NTIDT-1

	 TINT_MAC %CNT,%CNT
CNT	 =	 CNT+1

	 endm			; REPT NTIDT
.list

TINTCOM:
	 cmp	 ax,2		; Check for NMI
	 je	 short TINT_NMI ; Good guess
TINT_BLINK:
	 push	 ax		; Pass interrupt #
	 call	 CHECKPOINT	; Mark as next checkpoint

	 jmp	 short TINT_BLINK ; Go around again

TINT_NMI:
	 push	 ds		; Save for a moment

	 push	 DTE_DS 	; Get our data selector
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 ERR_CODE,07h	; Save error code
	 or	 ERR_FLAG,@ERR_TIM ; Mark as in error

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 pop	 ax		; Restore

	 iretd			; Return to caller
				; Note that this IRET allows another NMI
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TIDTPROC endp			; End TIDTPROC procedure

NCODE	 ends			; End NCODE segment

	 MEND			; End QMAX_TIM module
