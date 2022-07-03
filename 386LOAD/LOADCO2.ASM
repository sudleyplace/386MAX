;' $Header:   P:/PVCS/MAX/386LOAD/LOADCO2.ASV   1.1   30 May 1997 10:38:04   BOB  $
	 title	 LOADCO2 -- 386MAX Common Routines to DRVLOAD and TSRLOAD
	 page	 58,122
	 name	 LOADCO2

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,	word-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Program segment NDATA,	dword-aligned, public, class 'ndata'
	       Program segment DTAIL,	para-aligned,  public, class 'zdata'
	       Program segment ACODE,	byte-aligned,  public, class 'zdata'
	       Program segment ADATA,	dword-aligned, public, class 'zdata'
	       Program segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Program derived from:  None.

Original code by:  Bob Smith, February 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include 386.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include IOCTL.INC
	 include MAC.INC
	 include PTR.INC
	 include VERSION.INC
	 include EMMCALL.INC

	 include LOAD_OEM.INC
	 include QMAX_DBG.INC
	 include EMM2CALL.INC
.list

	 public  @GSIZE_PAT1,@GSIZE_PAT2
if @OEM_BETA
@GSIZE_PAT1 equ  66CCh		; GETSIZE pattern #1 (Int 03, OSP)
@GSIZE_PAT2 equ  0F190h 	; GETSIZE pattern #2 (NOP, ICE Int 01)
else
@GSIZE_PAT1 equ  3833h		; GETSIZE pattern #1 '83'
@GSIZE_PAT2 equ  4D36h		; GETSIZE pattern #2 'M6'
endif				; IF @OEM_BETA

PGROUP	 group	 CODE,DATA,NCODE,NDATA,DTAIL,ACODE,ADATA,ZZTAIL


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

if @OEM_WIN3
	 extrn	 WINRUN:byte
endif				; IF @OEM_WIN3

DATA	 ends			; End DATA segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 LCL_FLAG:word
	 include LOAD_LCL.INC

	 extrn	 LC2_FLAG:word
	 include LOAD_LC2.INC

	 extrn	 DOSVER:word
	 extrn	 XDOSVER:word
	 extrn	 BASNAME:byte
	 extrn	 DEV_HNDL:word
if @OEM_FLEX
	 extrn	 EMS_HNDL:word
endif				; IF @OEM_FLEX

NDATA	 ends			; End NDATA segment


ADATA	 segment use16 dword public 'zdata' ; Start ADATA segment
	 assume  ds:PGROUP

	 extrn	 IDENTIFY:byte
	 extrn	 AZS_XLOW:byte
	 extrn	 AZS_XDOS:byte
	 extrn	 AZS_XVER:byte
	 extrn	 AZS_NOTPRES:byte
if @OEM_WIN3
	 extrn	 AZS_WINERR:byte
endif				; IF @OEM_WIN3
	 extrn	 ALTPATHSEP:byte

ADATA	 ends			; End ADATA segment


DTAIL	 segment use16 para public 'zdata' ; Start DTAIL segment
	 assume  ds:PGROUP

; Note that INFO_STR *MUST* be the last data item in this segment
; to allow for future growth

	 public  INFO_CTL,INFO,INFOSIZE
	 include QMAXINFO.INC
	 include QMAX_CTL.INC
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
INFOSIZE equ	 size INFO_STR
	 org	 INFO+128	; Room for growth

	 public  QMAX_OWNR,CMD_FLAG,CM2_FLAG,POVR_MAC,P1ST_MAC,LOADSEG
	 public  BAS_SIGN,BAS_VER,OLDDOS,MSC_FLAG,MGRINT21_VEC,EMMSIZE,PORT67
	 public  CURINT67_VEC
QMAX_OWNR equ	 INFO.INFO_QMAX ; Segment of QMAX
CMD_FLAG  equ	 INFO.INFO_CMD	; CMD_FLAG
	 include QMAX_CMD.INC
CM2_FLAG  equ	 INFO.INFO_CM2	; CM2_FLAG
POVR_MAC  equ	 INFO.INFO_POVR ; First MAC in high DOS memory
P1ST_MAC  equ	 INFO.INFO_PMAC ; First MAC in low  DOS memory
LOADSEG   equ	 INFO.INFO_LSEG ; Segment of chain
BAS_SIGN  equ	 INFO.INFO_SIGN ; Signature of base module
BAS_VER   equ	 INFO.INFO_VER	; Version # ...
OLDDOS	  equ	 INFO.INFO_OLD	; Old top of DOS in paras
MSC_FLAG  equ	 INFO.INFO_MISC ; Miscellaneous flags
MGRINT21_VEC equ INFO.INFO_I21	; Old INT 21h handler
EMMSIZE   equ	 INFO.INFO_EMM	; Number of EMM pages
PORT67	  equ	 INFO.INFO_P67	; Back door port for EMM2CALL
CURINT67_VEC equ INFO.INFO_C67	; Entry point to MAX's Int 67 handler

if @OEM_FLEX
	 public  FRAMESEG,ONEPTE
FRAMESEG dw	 0		; Segment of EMS page frame
ONEPTE	 dd	 ?		; Room for one page table entry
endif				; IF @OEM_FLEX

	 DPALIGN INFO_CTL	; Align on para boundary

	 public  GTAIL		; Programs loaded via GETSIZE begin here
GTAIL	 MAC_STR <@MAC_MID,@MAC_FREE,0,0,0,'GTAILMAC'>

DTAIL	 ends			; End DTAIL segment


CODE	 segment byte use16 public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

if @OEM_WIN3
	 extrn	 WINOUT_INIT:near
endif				; IF @OEM_WIN3
	 extrn	 WINOUT:near

CODE	 ends			; End CODE segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 INFO_READ:near
	 extrn	 INFO_WRITE:near
if @OEM_FLEX
	 NPPROC  UNROUTE_I67 -- Restore previous Int 67h routing
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Check DB2_FLAG in MAX info structure.  If DEBUG=I67 was not in effect,
restore Int 67h processing to its previous setting.

|

;;;;;	 jmp	 short REROUTE_I67 ; Join common code

	 assume  ds:nothing,es:nothing,ss:nothing

UNROUTE_I67 endp		; End procedure UNROUTE_I67
endif				; IF @OEM_FLEX
if @OEM_FLEX
	 NPPROC  REROUTE_I67 -- Ensure Int 67h is routed through QMAX_OVR
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Check DB2_FLAG in MAX info structure.  If DEBUG=I67 is not in effect,
force Int 67h processing to go through resident handler in high DOS.

|

	 REGSAVE <ax,bx,dx>	; Save

	 test	 INFO.INFO_DBG,@DBG_X67 ; Is it already in effect?
	 jnz	 short @F	; Jump if so

if @OEM_WIN3
	 cmp	 WINRUN,0	; Are we running under Windows?
	 jne	 short @F	; Jump if so (call has no effect)
endif				; IF @OEM_WIN3
	 mov	 bx,@DBG_X67	; Route Int 67h through high DOS
	 mov	 ah,@EMM2_DBGFLAG ; Flip bits in DBG_FLAG
	 call	 WINOUT 	; Call through VxD (if necessary)
@@:
	 REGREST <dx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

REROUTE_I67 endp		; End procedure REROUTE_I67
endif				; IF @OEM_FLEX
if @OEM_FLEX
	 NPPROC  CHECK_EMSPTE -- Check for accessed PTEs in the page frame
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Turn EMS services back on if we're loading high with FLEXFRAME.

If any PTEs in the page frame have their accessed bit set, return
CF=1 to indicate that FLEXFRAME should not be allowed.

Many of the DECNET programs appear FLEXFRAME capable, but call interrupt
handlers which call code/data mapped permanently into the page frame.

|

	 REGSAVE <ax,bx,cx,si,di,es> ; Save

	 push	 ds		; Prepare to address PGROUP
	 pop	 es		; ...via ES
	 assume  es:PGROUP	; Tell the assembler

	 cmp	 EMS_HNDL,-1	; Izit allocated?
	 je	 short @F	; Jump if not

	 mov	 INFO_CTL,@CTL_EMSON ; Mark as EMS enable
	 call	 INFO_WRITE	; Enable EMS services

@@:
	 test	 LCL_FLAG,@LCL_IN67 ; Is an Int 67h handler installed?
	 jz	 short CHECKE_EXIT ; Jump if not (note CF=0)

	 call	 REROUTE_I67	; Force Int 67h to be handled in high DOS

if @OEM_WIN3
	 cmp	 WINRUN,0	; Are we running under Windows?
	 jne	 short CHECKE_EXIT ; Jump if so (call has no effect) (CF=0)
endif				; IF @OEM_WIN3

	 mov	 bx,FRAMESEG	; Get segment of page frame
	 or	 bx,bx		; Is there one?
	 jz	 short CHECKE_EXIT ; Jump if not (note CF=0)

	 mov	 cx,64/4	; Number of PTEs in 64K page frame
	 mov	 si,bx		; Get starting paragraph
	 shr	 si,10-4	; Convert paragraphs to K
CHECKE_NEXTPTE:

	 push	 cx		; Save loop counter

; Get a page table entry at SI K
	 mov	 ax,@EMM2_GETPTE*256 + 01h ; Get PTEs with 1MB wrap enabled
	 mov	 cx,4		; Get 1 PTE (4K)
	 lea	 di,ONEPTE	; ES:DI ==> destination for PTE
	 call	 WINOUT 	; Call through VxD (if necessary)
	 or	 ah,ah		; Did we succeed?

	 pop	 cx		; Restore loop counter

	 jnz	 short CHECKE_EXIT ; Jump if call failed (note CF=0)

	 test	 ONEPTE,mask $PTE_A ; Has it been accessed?
	 stc			; Assume one or more PTEs was accessed
	 jnz	 short CHECKE_EXIT ; Jump if so (note CF=1)

	 add	 si,4		; Skip to next PTE (4K)

	 loop	 CHECKE_NEXTPTE ; Go around again

				; Note CF=0
CHECKE_EXIT:
	 REGREST <es,di,si,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CHECK_EMSPTE endp		; End procedure CHECK_EMSPTE
endif				; IF @OEM_FLEX
if @OEM_FLEX
	 NPPROC  CLEAR_EMSPTE -- Clear accessed bit for all page frame PTEs
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Clear the @LCL_XFLEX bit for our resident Int 67h handler, and clear the
accessed bit in all page frame PTEs.  We'll check them later in CHECK_EMSPTE.

This procedure also disables EMS if we're loading high with FLEXFRAME.
This is done here to ensure that we disable it at precisely the same
point we start checking for hits on EMS services.  For example, with
STACKER loaded with the /EMS option, we'll need EMS services in CHECK_MEM
when we make a 4B03 call.

|

	 REGSAVE <ax,bx,cx,edx,esi,di,es> ; Save

	 push	 ds		; Prepare to address PGROUP
	 pop	 es		; ...via ES
	 assume  es:PGROUP	; Tell the assembler

	 test	 LCL_FLAG,@LCL_IN67 ; Is an Int 67h handler installed?
	 jz	 short CLEARE_EXIT ; Jump if not

	 call	 REROUTE_I67	; Force Int 67h to be handled in high DOS

if @OEM_WIN3
	 cmp	 WINRUN,0	; Are we running under Windows?
	 jne	 short CLEARE_EXIT ; Jump if so (call has no effect)
endif				; IF @OEM_WIN3

	 EMMCALL @EMM_GETPGFR	; AH=0, BX=page frame segment
	 or	 ah,ah		; Did we succeed?
	 jnz	 short CLEARE_EXIT ; Jump if not (NOFRAME)

	 mov	 FRAMESEG,bx	; Save for later

	 mov	 cx,64/4	; Number of PTEs in 64K page frame
	 movzx	 esi,bx 	; Get starting paragraph
	 shr	 si,10-4	; Convert paragraphs to K
CLEARE_NEXTPTE:

	 push	 cx		; Save loop counter

; Get a page table entry at SI K
	 mov	 ax,@EMM2_GETPTE*256 + 01h ; Get PTEs with 1MB wrap enabled
	 mov	 cx,4		; Get 1 PTE (4K)
	 lea	 di,ONEPTE	; ES:DI ==> destination for PTE
	 call	 WINOUT 	; Call through VxD (if necessary)
	 or	 ah,ah		; Did we succeed?

	 pop	 cx		; Restore loop counter

	 jnz	 short CLEARE_EXIT ; Jump if call failed (?)

; Save the entry with the accessed bit cleared
	 mov	 edx,ONEPTE	; Get the PTE contents
	 and	 edx,not (mask $PTE_A) ; Clear the accessed bit

	 shl	 esi,10-0	; Convert K to linear address (bytes)
	 mov	 ah,@EMM2_SETPTE ; Set PTE at ESI to EDX
	 call	 WINOUT 	; Call through VxD (if necessary)
	 shr	 esi,10-0	; Convert linear address to K

	 or	 ah,ah		; Did we succeed?
	 jnz	 short CLEARE_EXIT ; Jump if not (?)

	 add	 si,4		; Skip to next PTE (4K)

	 loop	 CLEARE_NEXTPTE ; Go around again

CLEARE_EXIT:
	 and	 LCL_FLAG,not @LCL_XFLEX ; Clear Int 67h called flag

	 cmp	 EMS_HNDL,-1	; Izit allocated?
	 je	 short CLEARE_EXIT1 ; Jump if not

	 mov	 INFO_CTL,@CTL_EMSOFF ; Mark as EMS disable
	 call	 INFO_WRITE	; Disable EMS services

CLEARE_EXIT1:
	 REGREST <es,di,esi,edx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

CLEAR_EMSPTE endp		; End procedure CLEAR_EMSPTE
endif				; IF @OEM_FLEX

NCODE	 ends			; End NCODE segment


ZZTAIL	 segment use16 dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 db	 ((16*2)-4) dup (?) ; Provide space for the MAC entry
				; created here when we resize downward

	 public  PIDENT
PIDENT	 dw	 PGROUP:IDENTIFY-100h ; Point to identification string
	 dw	 0		; ...less size of PSP

	 public  ZTAIL
ZTAIL	 label	 byte		; Relocation table of CHECK_MEM begins here

ZZTAIL	 ends			; End ZZTAIL segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 DISP_ERRMSG:near
	 extrn	 DISP_COPY:near

NCODE	 ends			; End NCODE segment


ACODE	 segment use16 byte public 'zdata' ; Start ACODE segment
	 assume  cs:PGROUP

	 extrn	 SAVE_2324:near
	 extrn	 REST_2324:near

	 NPPROC  FIND_BASE -- Ensure Base Program Is Loaded
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Ensure 386MAX.SYS is first loaded.  If it's TSRLOAD calling,
set @LC2_XMAX and return with CF clear.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <ax,bx,cx,dx>	; Save registers

	 test	 LCL_FLAG,@LCL_TSR ; Izit TSRLOAD or DRVLOAD?
	 jnz	 short FIND_BASE_TSR1 ; Jump if TSRLOAD

	 call	 SAVE_2324	; Save INTs 23h 24h and install our own handler
FIND_BASE_TSR1:

; Ensure DOS 3.x or later

	 DOSCALL @DOSVER	; AL = major
				; AH = minor
				; BX=CX=0

	 mov	 XDOSVER,ax	; Save for later use
	 xchg	 al,ah		; Swap to comparison order
	 mov	 DOSVER,ax	; Save in case it's not DOS 5
	 cmp	 ah,03h 	; Ensure late enough
	 jb	 near ptr FIND_BASE_XDOS ; It's too early

; We use this DOS 5 call to get the real version number.  Unfortunately,
; earlier DOS versions don't support this call, so we need to check for
; a return value in BX.  DOS 3.30 and 4.0 return FF in AL with CF=0 and
; BX unchanged.  I'm not sure we can rely on AL=FF, but BX unchanged seems
; safe.

; We can get screwed by SETVER if 386LOAD.COM has been loaded by
; NETX through the back door, and NETX has the wrong version.
	 mov	 ax,3306h	; Get MS-DOS version (sans SETVER lies)
	 sub	 bx,bx		; Clear in case it's not DOS 5
	 DOSCALL		; BL = major, BH = minor
	 xchg	 bl,bh		; Swap to comparison order
	 or	 bx,bx		; Is it a good version number?
	 jz	 short @F	; Jump if not

	 mov	 DOSVER,bx	; Save for later use
@@:
; Get switch character to see if we can use '/' as alternate path separator

	 mov	 al,00h 	; Code to return switch char
	 DOSCALL @SWITCH	; Return it in DL

	 cmp	 dl,'/'         ; Izit the usual?
	 je	 short @F	; Yes, disallow '/' as alternate path separator

	 mov	 ALTPATHSEP,'/' ; Save for later use
@@:

; See if our base program is installed

	 mov	 al,02h 	; Access code for read/write
	 DOSCALL @OPENF2,BASNAME ; Attempt to open base program device driver
	MJ c	 FIND_BASE_XPRES ; Not found ==> not installed

	 mov	 DEV_HNDL,ax	; Save for later use
	 mov	 bx,ax		; Copy to handle register

; Ensure it's a device

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 jc	 short FIND_BASE_ERRCLOS ; Something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 short FIND_BASE_ERRCLOS ; No???

	 call	 INFO_READ	; Read in INFO structure

	 DOSCALL @CLOSF2	; Close the device driver

	 cmp	 BAS_SIGN.ELO[0],'83' ; Our signature?
	 jne	 short FIND_BASE_XPRES ; Not this time

	 cmp	 BAS_SIGN.ELO[2],'M6' ; Our signature?
	 jne	 short FIND_BASE_XPRES ; Not this time

	 cmp	 BAS_SIGN.ELO[4],'XA' ; Our signature?
	 jne	 short FIND_BASE_XPRES ; Not this time

	 cmp	 BAS_VER[0],'5' ; Same major version # ?
	 jb	 short FIND_BASE_XVER ; Not this time
	 ja	 short FIND_BASE_CLOSE ; It's beyond us

	 cmp	 BAS_VER[2],'0' ; Same minor version # ?
	 jb	 short FIND_BASE_XVER ; Not this time
	 ja	 short FIND_BASE_CLOSE ; It's beyond us

	 cmp	 BAS_VER[3],'0' ; Same minor version # ?
	 jb	 short FIND_BASE_XVER ; Not this time
FIND_BASE_CLOSE:
	 test	 CMD_FLAG,@CMD_IGNFLEX ; Is IGNOREFLEXFRAME in effect?
	 jz	 short @F	; Jump if not

	 or	 LC2_FLAG,@LC2_IGNFLEX ; Transfer the flag
@@:
	 test	 LCL_FLAG,@LCL_TSR ; Izit TSRLOAD or DRVLOAD?
	 jz	 short FIND_BASE_CLC ; Jump if DRVLOAD

	 mov	 ax,cs		; Get our current segment

	 cmp	 ax,POVR_MAC	; Are we already loading in high memory?
	 jae	 short FIND_BASE_XLOW ; Yes, so that's an error
FIND_BASE_CLC:
if @OEM_WIN3
	 call	 WINOUT_INIT	; Set WINVXD_VEC and WINRUN
	 jnc	 short FIND_BASE_EXIT ; Jump if OK (note CF=0)

	 push	 offset cs:AZS_WINERR ; Tell 'em the bad news
	 jmp	 short FIND_BASE_ERREXIT ; Join common exit code
else
	 clc			; Indicate all went well
	 jmp	 short FIND_BASE_EXIT ; Join common exit code
endif				; IF @OEM_WIN3

FIND_BASE_XLOW:
	 push	 offset cs:AZS_XLOW ; Tell 'em the bad news
	 jmp	 short FIND_BASE_ERREXIT ; Join common exit code

FIND_BASE_XDOS:
	 push	 offset cs:AZS_XDOS ; Tell 'em the bad news
	 jmp	 short FIND_BASE_ERREXIT ; Join common exit code

FIND_BASE_XVER:
	 push	 offset cs:AZS_XVER ; Tell 'em the bad news
	 jmp	 short FIND_BASE_ERREXIT ; Join common exit code

FIND_BASE_ERRCLOS:
	 DOSCALL @CLOSF2	; Close the device driver
FIND_BASE_XPRES:
	 test	 LCL_FLAG,@LCL_TSR ; Izit TSRLOAD or DRVLOAD?
	 jz	 short @F	; If DRVLOAD, display error message

	 or	 LC2_FLAG,@LC2_XMAX ; Note that MAX is not present and continue
	 jmp	 short FIND_BASE_CLC ; Join common exit (no error)

@@:
	 push	 offset cs:AZS_NOTPRES ; Tell 'em 386MAX.SYS is not present
FIND_BASE_ERREXIT:
	 call	 DISP_COPY	; Display copyright notice
	 call	 DISP_ERRMSG	; Display an error message (pointer on stack)
	 stc			; Indicate something went wrong
FIND_BASE_EXIT:
	 pushf			; Save CF

	 test	 LCL_FLAG,@LCL_TSR ; Izit TSRLOAD or DRVLOAD?
	 jnz	 short FIND_BASE_TSR2 ; Jump if TSRLOAD

	 call	 REST_2324	; Restore old INTs 23h 24h
FIND_BASE_TSR2:
	 popf			; Restore

	 REGREST <dx,cx,bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FIND_BASE endp			; End FIND_BASE procedure

ACODE	 ends			; End ACODE segment

	 MEND			; End LOADCO2 module
