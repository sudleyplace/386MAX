;' $Header:   P:/PVCS/MAX/MAXIMIZE/MAXSUB.ASV   1.2   30 May 1997 11:45:44   BOB  $
	 title	 MAXSUB -- Subroutines to MAXIMIZE
	 page	 58,122
	 name	 MAXSUB

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1990-97 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Ungrouped:
	       Program segment xxx_TEXT, word-aligned,	public, class 'code'
	       Group DGROUP:
	       Data    segment _DATA,	 word-aligned,	public, class 'data'
	       Group PGROUP:
	       Program segment CODE,	 byte-aligned,	public, class 'prog'
	       Program segment DATZ,	 byte-aligned,	public, class 'data'
	       Data    segment DTAIL,	 dword-aligned, public, class 'zdata'
	       Program segment ACODE,	 byte-aligned,	public, class 'zdata'
	       Program segment UCODE,	 byte-aligned,	public, class 'ucode'
	       Data    segment UDATA,	 dword-aligned, public, class 'udata'
	       Data    segment ZZTAIL,	 dword-aligned, public, class 'zzdata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1990.

Modifications by:  None.

|

; See MAXSUB.PRO for C language prototypes for procedures contained herein.

;	 option OLDMACROS
;	 option OLDSTRUCTS

;	 option DOTNAME
;	 option CASEMAP:ALL
;	 option NOSCOPED
;	 option EXPR16

.8086
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include CPUID.INC
.386p
	 include 386.INC
.8086
	 include OPEN.INC
	 include BIOSDATA.INC
	 include IOCTL.INC
	 include EMMCALL.INC
	 include EMM2CALL.INC
	 include CMOS.INC
	 include 8255.INC
	 include BIOSCONF.INC
	 include PTR.INC
	 include DIR.INC
	 include DEVDRV.INC
	 include OPCODES.INC
	 include BITFLAGS.INC
	 include XMS.INC
	 include VDISK.INC
	 include CPUFLAGS.INC
	 include VIDCALL.INC
	 include ROMSEG.INC
	 include DOSCALL.INC
	 include MAC.INC

	 include QMAX_RAM.INC
	 include LOAD_SEG.INC
.list

%.model  &MODEL

; ASYS constant values for different builds are in COMM_OEM.INC
	 include COMM_OEM.INC

	 @NO_UNDERBAR	equ	1
	 include VENDINFO.INC
	 include RAMSCAN.INC

.data

	 extrn	 _errno:word
	 extrn	 _EmsCurrent:dword	; defined in ins_glb.h
	 extrn	 _EmsFrame:word 	; defined in ins_glb.h
;;;	 extrn	 _ExtSize:dword 	; defined in maxvar.h
	 extrn	 _ScreenSize:dword	; defined in ui.h

	 public  _BIOSConf,_BIOSDate
_BIOSConf dd	 ?		; Pointer to BIOS configuration data
_BIOSDate db	 ?,?,?		; Year-1900, Month (origin-1), day (origin-1)

	 public  SCRNO
	 align	 2
SCRNO	 dw	 ?		; Screen number

	 public  _PosData,_AdapPosData
	 include QMAX_POS.INC
_PosData POSD_STR @MAXPOSDEV dup (<>) ; Save area for CMOS POS data from MAX
_AdapPosData MCA_STR @MAXPOSDEV dup (<>) ; Save area for current POS data

	 public  _PosDataStat,_Pos32
_PosDataStat db  0		; Return status of EMM2 POSCOPY call
				; (Pretend it's OK if MAX isn't present)
_Pos32	 dw	 0		; 1 = NVRAM writes for system POS supported

	 public  _MaxVer
_MaxVer  db	 0,?,?		; 386MAX version #

	 public  _BcfFlag
_BcfFlag db	 0		; 1 = BCF in effect, 0 = not
	 public  _BusmFlag
_BusmFlag db	 0		; 1 = Busmaster present, 0 = not
	 public  _CompROM
_CompROM db	 0		; 1 = COMPROM in effect, 0 = not

MAXHIGHREGIONS equ	10
	 public _nHighRegions,_waHighRegions
_nHighRegions dw	0	; Number of high DOS regions
_waHighRegions dw MAXHIGHREGIONS dup (0) ; Sizes of regions in paras

	 extrn	_SUB_FLAG:word	; Local flags
	 extrn	_LCL_FLAG:word	; MAX local flags

	 public  MAXNAME
if (ASYS EQ MOVEM)
MAXNAME  db	 'MOVE''EM$',0   ; Name of our device
else
MAXNAME  db	 '386MAX$$',0   ; Name of our device
endif

	 public  INFO_CTL,MAXINFO,INFOSIZE,_LoadSeg
if (ASYS EQ MOVEM)
	 include MOVEINFO.INC
else
	 public  PORT67,LCL_FLAG,_SysRom
	 include QMAXINFO.INC
endif				; IF ASYS EQ MOVEM
	 include QMAX_CTL.INC
INFO_CTL db	 ?		; IOCTL type
MAXINFO  INFO_STR <>		; MAX information structure
	 dw	 10 dup (0)	; Room for growth
INFO_END label	 byte

INFOSIZE equ	 size INFO_STR

if (ASYS NE MOVEM)
	 public  Port67
Port67	 equ	 MAXINFO.INFO_P67

	 public  LCL_FLAG
LCL_FLAG equ	 MAXINFO.INFO_LCL
	 include QMAX_LCL.INC

	 public  CM2_FLAG
CM2_FLAG equ	 MAXINFO.INFO_CM2 ; Get secondary command flags
	 include QMAX_CM2.INC

	 public  SYS_FLAG
SYS_FLAG equ	 MAXINFO.INFO_SYS ; System type flags
	 include QMAX_SYS.INC

	 org	 MAXINFO.INFO_SROM
_SysRom  label	 word		; Get start of system ROM
endif

	 org	 MAXINFO.INFO_LSEG
_LoadSeg label	 word		; ... starting segment of LSEG chain

	 org	 MAXINFO.INFO_POVR
_Povr_Mac label word		; ... starting segment of high DOS memory

	 org	 INFO_END

	 public  RAMTAB
RAMTAB	 db	 (384/4) dup (0) ; RAMSCAN table (filled in with 2's if NOSCAN)

	 public  _RebootCmd
_RebootCmd dd	 0		; REBOOTCMD= from profile

	 public  _Comspec
_Comspec dd	 ?		; COMSPEC or ersatz COMSPEC (initialized in
				; MAXIMIZE.C)

	 public  SLASH_C
SLASH_C  db	 '/c',0         ; for _spawnl(P_WAIT,Comspec,Comspec,RebootCmd,0)

if @OEM_HARPO
	 public  _Harpo_profile
_Harpo_profile db 128 dup (0)	; HARPO profile (gotten via EMM2CALL)

	 public  _psubsegs
_psubsegs dd	 ?		; PSUBSEGS converted to a far pointer

endif				; IF @OEM_HARPO

SGROUP	 group	 SCREENS_TEXT

SCREENS_TEXT segment byte public 'code' ; Start SCREENS code segment
	 assume  ds:nothing

	 extrn	 _show_progress:far	; Function to display progress
	 extrn	 _confirm_abesc:far	; Function to confirm abort/Esc

SCREENS_TEXT ends		; End SCREENS_TEXT segment

INST2324_TEXT segment byte public 'code' ; Start INST2324 code segment
	 assume  ds:nothing

	 extrn	 _enable23:far		; Function to enable int 23 handling
	 extrn	 _disable23:far 	; Function to disable	    "
	 extrn	 _done2324:proc 	; Function to shut down int 23/24

INST2324_TEXT ends		; End INST2324_TEXT segment

CODE	 segment byte public 'prog' ; Start CODE segment
CODE	 ends			; End CODE segment

CGROUP	 group	 CPUID_SEG
PGROUP	 group	 CODE,DATZ,DTAIL,ACODE,UCODE,UDATA,ZZTAIL


DATZ	 segment byte public 'data' ; Start DATZ segment
	 assume  ds:PGROUP

	 public  EMMDEV
EMMDEV	 db	 'EMMXXXX0',0   ; EMM device driver name

	 include UTIL_OPT.INC

	public AZS_TOTAL,AZS_TOTHIGH,AZS_CUR,AZS_CURTIME,AZS_BEST
	public AZS_BESTTIME,AZS_BESTBYTES,AZS_BESTPCT,AZS_BESTBPCT
AZS_TOTAL db	@LONGSPC dup (?)	; Space for formatted total
AZS_TOTHIGH db	@DDSPC	 dup (?)	; Space for total high DOS bytes
AZS_CUR  db	@LONGSPC dup (?)	; Space for formatted done so far
AZS_CURTIME db	@HMSSPC  dup (?)	; Space for formatted HH:MM:SS
AZS_BEST db	@LONGSPC dup (?)	; Space for formatted best count
AZS_BESTTIME db @HMSSPC  dup (?)	; Space for best HH:MM:SS
AZS_BESTBYTES db @DDSPC  dup (?)	; Space for best # bytes moved high
AZS_BESTPCT db	@PCTDSPC dup (?)	; Space for best as percentage of total
AZS_BESTBPCT db @PCTDSPC dup (?)	; Space for best bytes high as % total

DATZ	 ends			; End DATZ segment


UDATA	 segment dword public 'udata' ; Start UDATA segment
	 assume  ds:PGROUP

	 extrn	 PSUMFIT_TAB:word
if @OEM_HARPO
	 extrn	 PSUBSEG_TAB:word
	 extrn	 NSUBSEGS:word
endif				; IF @OEM_HARPO

	 extrn	 NREGS:word
	 extrn	 REGTAB:word

	 public  UTL_FLAG
	 include QMAX_UTL.INC
UTL_FLAG dw	 @UTL_COT	; Mark as output not redirected

	 public  _OPT_PROGRESS,_OPT_CALLBACK
_OPT_PROGRESS dw _show_progress,seg SGROUP ; Entry point for progress display
_OPT_CALLBACK dw _confirm_abesc,seg SGROUP ; Entry point for confirm callback

UDATA	 ends			; End UDATA segment


DTAIL	 segment dword public 'zdata' ; Start DTAIL segment
	 assume  ds:PGROUP

	 public  POVR_MAC,LOADSEG
POVR_MAC dw	 ?		; ...
LOADSEG  dw	 ?		; Local copy for SUMFIT

DTAIL	 ends			; End DTAIL segment


ACODE	 segment byte public 'zdata' ;code' Start ACODE segment
	 assume  cs:PGROUP

	 extrn	 IZITEMS:far

ACODE	 ends			; End ACODE segment


UCODE	 segment byte public 'ucode' ; Start UCODE segment
	 assume  cs:PGROUP

	 extrn	 CALCREG:far
	 extrn	 SAVE_SUMFIT:far
	 extrn	 GET_TOPFIT:far
	 extrn	 ORDFIT:far
	 extrn	 CPY_SUMFIT:far
	 extrn	 RLS_TOPFIT:far
	 extrn	 REST_SUMFIT:far

UCODE	 ends			; End UCODE segment

CODE	 segment		; Start CODE segment
	 assume  cs:PGROUP

if @OEM_HARPO
	 NPPROC  WINOUT -- Make EMM2CALL for UTIL_OPT.ASM
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

This is merely a stub, since MAXIMIZE won't run under Windows.

|

DOT386
	 REGSAVE <gs>		; Save

	 push	 seg DGROUP	; Prepare to address PORT67
	 pop	 gs		; Address it
	 assume  gs:DGROUP	; Tell the assembler

	 EMMOUT 		; Call MAX via back door

	 REGREST <gs>		; Restore
	 assume  gs:nothing	; Tell the assembler
.8086

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

WINOUT	 endp			; End WINOUT procedure
endif				; IF @OEM_HARPO

CODE	 ends			; End CODE segment

STACK	 segment word public 'stack' ; Start STACK segment
STACK	 ends			; End STACK segment


ZZTAIL	 segment dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 public  ZTAIL
ZTAIL	 label	 byte		; Next available byte
	 db	 2500 dup (?)	; Room for local storage for SUMFIT tables

ZZTAIL	 ends			; End ZZTAIL segment


.code
.xcref CSOVR
CSOVR	 macro	 INSTR,ARGS

	 db	 2Eh		; CS:
	 INSTR	 ARGS

	 endm			; CSOVR

	 extrn	 MCA_POS:far	; PASCAL procedure to get current POS
	 extrn	 _Get_CMOS_POS:far ; Procedure to get CMOS POS
	 extrn	 __spawnl:proc	; C library function to execute and return
	 extrn	 _exit:proc	; C library function to return to DOS
	 extrn	 _cstdwind:proc ; Procedure to shut down windowing

	 public  OLDINT1C_VEC
OLDINT1C_VEC dd  ?		; Save area for old INT 1Ch handler

	 public  DATASEG
DATASEG  dw	 seg DGROUP	; Segment of our data group

	 public  WAIT_CNT
WAIT_CNT dw	 ?		; Wait counter in units of timer ticks

	 PPROC	 _debug -- Call Our Debugger
	 assume  ds:DGROUP,es:nothing,ss:nothing

	 int	 03h		; Call our debugger

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_debug	 endp			; End _debug procedure
	 PPROC	 _izit4dos -- Determine If 4DOS Is Loaded
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Determine whether or not 4DOS is loaded.

On exit:

AX	 =	 1 if so
	 =	 0 if not

|

	 REGSAVE <bx>		; Save register

	 mov	 ax,0D44Dh	; Get 4DOS function
	 mov	 bx,0		; Subfunction to get version
	 int	 2Fh		; Call redirector

	 cmp	 ax,44DDh	; Izit 4DOS?
	 je	 short @F	; Jump if so

	 mov	 ax,0E44Fh	; Get NDOS function
	 mov	 bx,0		; Subfunction to get version
	 int	 2Fh		; Call redirector

	 cmp	 ax,44EEh	; Izit NDOS?
	 mov	 ax,0		; Assume not
	 jne	 short IZIT4D_EXIT ; Jump if not

@@:
	 mov	 ax,1		; Mark as present
IZIT4D_EXIT:
	 REGREST <bx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_izit4dos endp			; End _izit4dos procedure
	 FPPROC  INT1C -- Secondary Timer Tick Handler
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Secondary timer tick handler.
Count down WAIT_CNT until zero.

|

	 pushf			; Save flags in case they're important

	 cmp	 WAIT_CNT,0	; Izit already zero?
	 je	 short @F	; Jump if so

	 assume  ds:MAXSUB_TEXT ; Tell a white lie
CSOVR	 dec	 WAIT_CNT	; Account for one timer tick
	 assume  ds:nothing	; Retract nose
@@:
	 popf			; Restore

	 jmp	 OLDINT1C_VEC	; Continue on with next handler

	 assume  ds:nothing,es:nothing,ss:nothing

INT1C	 endp			; End INT1C procedure
	 PPROC	 _reboot -- Reboot The System
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Reboot the system

|

	 DOSCALL @DRESET	; Reset all disk drives and flush buffers

; In case we're running under PC-TOOLS's disk cache, flush it via
; this strange call

	 mov	 ax,0FFA5h	; Special parameter #1
	 mov	 cx,0FFFFh	; ...		    #2
	 int	 16h		; Request keyboard (?) service

; Wait for some time to pass so that any disk cache can flush its buffers.
; The technique we use is to install an INT 1Ch handler and count the
; ticks as they go by.

	 mov	 al,1Ch 	; Intercept this one
	 DOSCALL @GETINT	; Return with ES:BX ==> old INT 1Ch handler
	 assume  es:nothing	; Tell the assembler about it

	 assume  ds:MAXSUB_TEXT ; Tell a white lie
CSOVR	 mov	 <OLDINT1C_VEC.VOFF,bx> ; Save for later use
CSOVR	 mov	 <OLDINT1C_VEC.VSEG,es>
	 assume  ds:nothing	; Retract nose

@WAIT_SECS equ	 6		; Wait this many seconds

	 assume  ds:MAXSUB_TEXT ; Tell a white lie
CSOVR	 mov	 <WAIT_CNT,18*@WAIT_SECS> ; Set countdown timer used by INT1C
	 assume  ds:nothing	; Retract nose
				; in units of timer ticks (~18/sec)

	 push	 cs		; Setup DS to point to code segment
	 pop	 ds		; ... for @SETINT
	 assume  ds:MAXSUB_TEXT ; Tell the assembler about it

	 sti			; Ensure interrupts enabled

	 mov	 al,1Ch 	; Intercept this one
	 DOSCALL @SETINT,INT1C	; Install our handler
@@:
	 sti			; Ensure interrupts enabled

	 cmp	 WAIT_CNT,0	; Izit done?
	 jne	 short @B	; Jump if not

	 lds	 dx,OLDINT1C_VEC ; DS:DX ==> previous INT 1Ch handler
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 al,1Ch 	; Restore this one
	 DOSCALL @SETINT	; Restore previous handler

; Next, wait until the diskette drive motor has stopped

	 mov	 ax,seg BIOSDATA ; Get BIOS data area segment
	 mov	 ds,ax		; Address it
	 assume  ds:BIOSDATA	; Tell the assembler about it
@@:
	 test	 MOTOR_STATUS,@BIT0 ; Izit running?
	 jnz	 short @B	; Jump if so

; After we're done waiting, execute whatever command the user specified
; via the REBOOTCMD= maximize.cfg option.
	 mov	 ax,seg DGROUP	; Restore addressability to DGROUP
	 mov	 ds,ax		; Address it
	 assume  ds:DGROUP	; Tell the assembler

	 mov	 ax,_RebootCmd.ELO ; Get offset
	 or	 ax,_RebootCmd.EHI ; Combine with segment
	 jz	 short NO_REBOOTCMD ; Jump if no reboot command specified

; User specified a REBOOTCMD string.  Execute %COMSPEC% /c and pass
; it as an argument.
; (void) _spawnl (P_WAIT, Comspec, Comspec, "/c", RebootCmd, NULL);
	 sub	 ax,ax		; Create a NULL to terminate list
	 push	 ax		; Segment of NULL (or exit(0))

	 les	 bx,_RebootCmd	; Command line pointer
	 assume  es:nothing	; Tell the assembler

	 cmp	 es:[bx].LO,0	; Izit empty?
	 jnz	 short @F	; Jump if not

	 call	 _cstdwind	; Shut down windowing system
	 call	 _done2324	; Restore int 23/24 vectors
	 call	 _exit		; exit(0)

@@:
	 push	 ax		; Offset of NULL

	 push	 es		; Segment of command line
	 push	 bx		; Offset of command line

	 lea	 dx,SLASH_C	; "/C"
	 push	 ds		; Segment of option
	 push	 dx		; Offset of option

	 les	 bx,_Comspec
	 assume  es:nothing	; Tell the assembler
	 push	 es		; Segment of argv[0]
	 push	 bx		; Offset of argv[0]

	 push	 es		; Segment of executable to load
	 push	 bx		; Offset of executable to load

	 push	 ax		; P_WAIT

	 ; Move cursor to bottom of screen
	 VIDCALL @GETINF	; BH = current page
	 mov	 dx,_ScreenSize.ELO ; Get number of rows in screen
	 dec	 dx		; Highest row
	 mov	 dh,dl		; Row to set
	 sub	 dl,dl		; Column 0
	 VIDCALL @SETPOS	; Set cursor position for page BH to DH,DL (r,c)

	 call	 __spawnl	; AX = return code
	 add	 sp,5*4+2	; Strip P_WAIT and far pointers from stack

NO_REBOOTCMD:
; Set reset flag to force warm boot

	 mov	 ax,seg BIOSDATA ; Get BIOS data area segment
	 mov	 ds,ax		; Address it
	 assume  ds:BIOSDATA	; Tell the assembler about it

	 mov	 RESET_FLAG,1234h ; Set flag to avoid memory count (cold boot)

	 mov	ax,0C300h	; Disable watchdog time-out
	 int	15h		; Request BIOS service

if (ASYS NE MOVEM)
.286p
; See if 386MAX is installed and NOWARMBOOT is in effect

	 push	 seg DGROUP	; Setup addressibility to DGROUP
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 test	 _SUB_FLAG,@SUB_VM ; Are we in V86 Mode?
	 jz	 short REBOOT_NOPROB ; Jump if not

	 push	 seg CGROUP	; Get segment of CPUID
	 pop	 ds		; Address it
	 assume  ds:CGROUP	; Tell the assembler about it

	 cmp	 REBOOTD,@OPCOD_JMPF ; Izit a far jump immediate?
	 jne	 short REBOOT_ALT ; No, use alternate method of rebooting

	 cmp	 REBOOT_VEC.VSEG,0F000h ; Izit a reboot to system ROM?
	 je	 short REBOOT_ALT ; Yes, use alternate method of rebooting

	 test	 _SUB_FLAG,@SUB_MCA ; Izit an MCA system?
	 jz	 short REBOOT_NOPROB ; No, so we can assume it's to 386MAX

	 cmp	 REBOOT_VEC.VSEG,0E000h ; Izit a reboot to system ROM?
	 jne	 short REBOOT_NOPROB ; No, so we can assume it's to 386MAX
REBOOT_ALT:
	 cli			; Disallow interrupts
	 mov	 al,0		; Subfunction to exit unconditionally
	 EMMOUT  @EMM2_GOREAL	; Request 386MAX service
.8086
endif
REBOOT_NOPROB:
	 cli			; Disallow interrupts

	 jmp	 REBOOT 	; Reboot the system

	 assume  ds:nothing,es:nothing,ss:nothing

_reboot  endp			; End _reboot procedure
	 PPROC	 _maxmovpres -- Determine Presence of 386MAX/Move'em
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Determine presence of 386MAX.
Also, define additional variables needed if present.

On exit:

AX	 =	 1 if present (with additional variables defined)
	 =	 0 if not

|

	 REGSAVE <bx,cx,dx,si,di,es> ; Save registers

	 push	 es		; Save for a moment

	 mov	 ah,0C0h	; Function code to Ptr to BIOS configuration data
	 int	 15h		; Request BIOS service
	 assume  es:nothing	; Tell the assembler about it

	 mov	 _BIOSConf.VOFF,bx ; Save for later use
	 mov	 _BIOSConf.VSEG,es ; ...

	 mov	 ax,seg CGROUP	; Get segment of CPUID
	 mov	 es,ax		; Address it
	 assume  es:CGROUP	; Tell the assembler about it

	 mov	 ax,BIOS_DATE.ELO[0] ; Get the month # (e.g. '04')
	 xchg	 al,ah		; Swap to AAD order
	 sub	 ax,'00'        ; Convert from ASCII to binary
	 aad			; AL = AH*10 + AL, AH = 0
	 mov	 _BIOSDate[1],al ; Save in month field

	 mov	 ax,BIOS_DATE.ELO[3] ; Get the day # (e.g. '23')
	 xchg	 al,ah		; Swap to AAD order
	 sub	 ax,'00'        ; Convert from ASCII to binary
	 aad			; AL = AH*10 + AL, AH = 0
	 mov	 _BIOSDate[2],al ; Save in day field

	 mov	 ax,BIOS_DATE.ELO[6] ; Get the year # (e.g. '93')
	 xchg	 al,ah		; Swap to AAD order
	 sub	 ax,'00'        ; Convert from ASCII to binary
	 aad			; AL = AH*10 + AL, AH = 0

	 cmp	 al,80		; Izit in the current century?
	 jae	 short @F	; Jump if so

	 add	 al,100 	; Convert to next century
@@:
	 mov	 _BIOSDate[0],al ; Save in year field

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 mov	 ax,0FFA5h	; Code for PC-CACHE
	 mov	 cx,0CCCCh	; Code to set /WRITE=OFF
	 int	 16h		; Request service from PC-CACHE

	 call	 IZIT386	; Izit a 386 or later CPU?
	 jc	 short @F	; Jump if not

	 call	 IZIT486	; Izit a 486 or later CPU?
	 jc	 short @F	; Jump if not

	 or	 _SUB_FLAG,@SUB_486 ; Mark as 486 or later CPU
@@:
	 mov	 al,@OPEN_R	; Function code for read-only access
	 DOSCALL @OPENF2,MAXNAME ; Attempt to open the device

	MJ c	 MAXPRES_ERR	; Jump if not

	 mov	 bx,ax		; Copy to handle register
	 mov	 al,0		; Function code to get device information
	 DOSCALL @IOCTL2	; Get device information into DX
	MJ c	 MAXPRES_ERRCLOSE ; Jump if not

	 test	 dx,@IOCTL_DEV	; Izit a device?
	MJ z	 MAXPRES_ERRCLOSE ; Jump if not

	 mov	 al,02h 	; Read from device
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO
	MJ c	 MAXPRES_ERRCLOSE ; Jump if error

	 DOSCALL @CLOSF2	; Close the file

; Save 386MAX version # for later use

	 mov	 al,MAXINFO.INFO_VER[0] ; Get hundreds digit
	 mov	 _maxver[0],al	; Save for later use
	 mov	 al,MAXINFO.INFO_VER[2] ; Get tens digit
	 mov	 _maxver[1],al	; Save for later use
	 mov	 al,MAXINFO.INFO_VER[3] ; Get units digit
	 mov	 _maxver[2],al	; Save for later use

	 push	 ds		; Save DGROUP segment

	 mov	 ax,seg PGROUP	; Get segment of LOADSEG
	 mov	 ds,ax		; Address PGROUP
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 ax,seg DGROUP	; Get DGROUP segment
	 mov	 es,ax		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

;---------- Can't call any C functions as they require DS:DGROUP ---------
	 mov	 ax,_LOADSEG	; Get load segment #
	 mov	 LOADSEG,ax	; Save

	 mov	 ax,_POVR_MAC	; Get high DOS segment #
	 mov	 POVR_MAC,ax	; Save
if (ASYS NE MOVEM)
	 test	 CM2_FLAG,@CM2_XSCSI ; Is there a Busmaster device present?
	 jz	 short @F	; Jump if not

	 mov	 _BusMflag,1	; Mark as present
@@:
endif

;---------- IZITEMS requires DS:PGROUP ------------------------------------
	 call	 IZITEMS	; Is an EMS handler installed and ready?

	 pop	 ds		; Restore addressability to DGROUP
	 assume  ds:DGROUP	; Tell the assembler

;---------- DS is OK for C functions now ----------------------------------
	 jnc	 short MAXPRES_XEMS ; Jump if no EMS services available

	 EMMCALL @EMM_GETPGFR	; Request page frame address into BX

	 cmp	 ah,0		; Izit valid?
	 jne	 short MAXPRES_XEMS ; Jump if not

	 mov	 ax,bx		; Copy segment
	 mov	 cl,4-0 	; Shift count
	 shl	 ax,cl		; Convert from paras to bytes
	 mov	 _EmsCurrent.ELO,ax ; Save as low-order word
	 add	 cl,(16-4)-4	; Shift count
	 shr	 bx,cl		; Convert from paras to bytes
	 mov	 _EmsCurrent.EHI,bx ; Save as high-order word
	 mov	 _EmsFrame,1	; Mark as present
MAXPRES_XEMS:
if (ASYS NE MOVEM)
; If we're at version 5.01 or later, read in POS data

	 test	 LCL_FLAG,@LCL_BCF ; Is the BIOS compressed?
	 jz	 short @F	; Jump if not

; Save BCF flag status for later use

	 mov	 _BCFFLAG,1	; Mark as BCF in effect
@@:
	 cmp	 _maxver[0],'5' ; Izit above 5.xx?
	 ja	 short @F	; Jump if so

	 cmp	 _maxver[1],'0' ; Izit above 5.0x?
	 ja	 short @F	; Jump if so

	 cmp	 _maxver[2],'1' ; Izit at or above 5.01?
	 jb	 short MAXPRES_XPOS ; Jump if not
@@:

; This call may return a non-zero value if a 6.02 386MAX version is running
; or if the system has no ABIOS (one NCR system had no ABIOS).	We also
; check to see if the running MAX version supports system board CMOS and
; direct writes to system board NVRAM.

	 push	 ds		; Segment for @EMM2_POSCOPY
	 lea	 bx,_PosData	; Offset of save area
	 push	 bx		; Pass offset of save area
	 call	 _Get_CMOS_POS	; AX=1 if success, AX=0 if failure
	 add	 sp,2*2 	; Strip arguments from stack

	 xor	 al,1		; Invert meaning of return code
	 mov	 _PosDataStat,al ; Save error code for later

; See if MAX supports system board CMOS and direct writes to system board NVRAM.
	 mov	 ax,_PosData[0].POSD_ID ; -1 if not supported
	 inc	 ax		; Was it -1?
	 jnz	 short MAXPRES_SYSPOS ; Jump if not (system CMOS supported)

; If it's an older version of MAX, we need to clobber the C401 values
; that may appear to be slot IDs.
	 sub	 bx,bx		; Address slot 0 data (system board)
	 mov	 cx,@MAXPOSDEV	; Number of slots + system board
MAXPRES_XSYSPOS_NEXT:
	 cmp	 _PosData[bx].POSD_ID,0C401h ; Izit bogus value filled in by MAX 6.01?
	 jne	 short @F	; Jump if not

	 mov	 _PosData[bx].POSD_ID,-1 ; Kill it
@@:
	 add	 bx,size POSD_STR ; Skip to next slot
	 loop	 MAXPRES_XSYSPOS_NEXT ; Go around again

;;;;;;;  sub	 ax,ax		; 32-byte NVRAM POS not supported
MAXPRES_SYSPOS:
	 mov	 _Pos32,ax	; Save for later

; Read in adapter POS data for later use

	 push	 ds		; Segment of data
	 lea	 bx,_AdapPosData ; Get offset
	 push	 bx		; Pass offset of data
	 call	 MCA_POS	; Fill in adapter and system board POS data
				; (Pascal procedure strips arguments)
				; Ignore return value in AX (AX=0 is success)

MAXPRES_XPOS:
	 sub	 ax,ax		; Assume no COMPROM
	 test	 LCL_FLAG,@LCL_CROM ; Is COMPROM in effect?
	 jz	 short @F	; No COMPROM

	 inc	 ax		; Set COMPROM
@@:
	 mov	 _CompROM,al	; Set public flag
endif
	 or	 _SUB_FLAG,@SUB_PRES ; Mark as present

	 mov	 ax,1		; Indicate it's present

	 jmp	 short MAXPRES_EXIT ; Join common exit code

MAXPRES_ERRCLOSE:
	 DOSCALL @CLOSF2	; Close the file
MAXPRES_ERR:

	 xor	 ax,ax		; Indicate not present
MAXPRES_EXIT:
	 REGREST <es,di,si,dx,cx,bx> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_maxmovpres endp		; End _maxmovpres procedure
	 PPROC	 _ramscan -- Test For Presence of RAM In High DOS Memory
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Test for presence of RAM in high DOS memory.

If 386MAX is present, ask it to do it for us.
Otherwise, do it ourselves.

On exit:

DX:AX	 ==>	 RAMSCAN structure

|

	 REGSAVE <cx,di,bp,es>	; Save registers

	 push	 ds		; Setup ES for RAMSCAN
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it
if (ASYS NE MOVEM)
	 call	 _MAXPRES	; Set all variables

	 test	 _SUB_FLAG,@SUB_PRES ; Is 386MAX present?
	 jz	 short RAMSCAN_XPRES ; Jump if not

	 test	 _SUB_FLAG,@SUB_VM ; Izit active?
	 jz	 short RAMSCAN_XPRES ; Jump if not

	 lea	 di,DGROUP:RAMTAB ; ES:DI ==> output save area
	 mov	 bp,sp		; Save stack pointer
	 EMMOUT  @EMM2_RAMSCAN	; Request RAM scan of high DOS memory
				; Return with AH = error status
	 mov	 sp,bp		; Restore

;;;;;;;; cmp	 ah,0A4h	; Check for access denied
;;;;;;;; je	 short RAMSCAN_DENY ; Jump if denied
;;;;;;;;
	 and	 ah,ah		; Check return code
	 jz	 short RAMSCAN_DONE ; Join common exit code
RAMSCAN_ERR:
	 xor	 ax,ax		; Return null address
	 xor	 dx,dx		; ...in DX:AX

	 jmp	 short RAMSCAN_EXIT ; Join common exit code


; 386MAX is not present -- do it ourselves

RAMSCAN_XPRES:
endif ;MOVEM
	 call	 LCL_RAMSCAN	; Use local subroutine
RAMSCAN_DONE:

; Because some systems with local bus video have the video ROM
; at C000 as read-write, we check for that here and clear the
; $RAM_RAM bit.

	 mov	 ax,0C000h	; Get the video ROM segment
	 mov	 es,ax		; Address it
	 assume  es:RGROUP	; Tell the assembler about it

	 cmp	 ROMSIGN,@ROMSIGN ; Izit marked as a ROM?
	 jne	 short RAMSCAN_EXIT0 ; Jump if not

	 xor	 ah,ah		; Zero to use as word
	 mov	 al,ROMLEN	; Get the ROM length in 512 bytes
	 mov	 cl,12-9	; Shift amount between 4KB and 512 bytes
	 shr	 ax,cl		; Convert from 512 bytes to 4KB (rounding down)
	 jz	 short RAMSCAN_EXIT0 ; Jump if nothing (e.g. VGASWAP gore)

	 mov	 cx,ax		; Copy to count register

	 mov	 di,(0C000h-0A000h) shr (12-4) ; Get index of C000
RAMSCAN_VRAM:
	 and	 RAMTAB[di],not (mask $RAM_RAM) ; Mark as not RAM
	 inc	 di		; Skip to next 4KB block

	 loop	 RAMSCAN_VRAM ; Jump if more 4KB blocks to check
RAMSCAN_EXIT0:

; Return pointer to structure in DX:AX

	 lea	 ax,DGROUP:RAMTAB ; Get the offset into AX
	 mov	 dx,ds		; Copy segment into DX
RAMSCAN_EXIT:
	 REGREST <es,bp,di,cx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_ramscan endp			; End _ramscan procedure
	 NPPROC  LCL_RAMSCAN -- Search For RAM In High Memory
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

If high DOS memory or EMS page frame needed,
search for RAM in high memory and fill in MEM_MAP accordingly.

|

	 REGSAVE <ax,bx,cx,dx,si,di,bp> ; Save all GP registers
	 push	 es		; Save segment register

	 push	 ds		; Setup ES for string ops
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 call	 SAVE_CACHE	; Save and disable the state of the
				; cache controller
				; EBP = current state

	 mov	 cx,size RAMTAB ; CX = # characters in RAMTAB to fill in
	 lea	 di,DGROUP:RAMTAB ; ES:DI ==> RAMSCAN table
LCL_RAMSCAN_NEXT:
	 mov	 bx,di		; Copy starting offset+1
	 sub	 bx,offset DGROUP:RAMTAB ; Convert to origin-0
	 push	 cx		; Save for a moment
	 mov	 cl,12-4	; Shift amount between paras and 4K
	 shl	 bx,cl		; Convert from 4KB to paras
	 pop	 cx		; Restore
	 add	 bx,0A000h	; Convert to origin-A000

; Note that if we use DGROUP: here, MASM 5.10 will translate the expression
; as "mov al,[di+0000]," putting the two passes out of sync.
	 mov	 al,es:[di].LO	; Get byte from RAMTAB
	 or	 al,al		; Izit marked as NOSCAN?
	 jnz	 short @F	; Jump if so

	 call	 _CHECK_RAM	; Check for RAM in 512-byte block at BX:0
				; Return with CF=1 if RAM present
	 adc	 al,0		; Add in if RAM present
@@:
	 stos	 RAMTAB[di]	; Save in RAMSCAN table

	 loop	 LCL_RAMSCAN_NEXT ; Jump if more 4KB blocks to test

	 call	 REST_CACHE	; Restore state of cache controller from EBP

	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
	 REGREST <bp,di,si,dx,cx,bx,ax> ; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

LCL_RAMSCAN endp		; End LCL_RAMSCAN procedure
	 PPROC	 _maximize -- Maximize Resident Program Location/Order
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Maximize resident program location/order

On entry:

MAX_STR on stack

On exit:

DX:AX	 ==>	 SUMFIT tables
_psubsegs ==>	 SUBFIT tables, or NULL if none

|

MAXSTR	 struc

	 dw	 ?		; Caller's BP
	 dw	 (1+@codesize) dup (?) ; Caller's IP or CS:IP
MAXFLAG  dw	 ?		; Flags:  0 = don't re-order
				;	  1 = allow re-ordering
MAXSTR	 ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ds,es>	; Save registers

	 call	 _disable23	; Disable handling of int 23

	 mov	 ax,seg PGROUP	; Get segment for UCODE
	 mov	 ds,ax		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it
	 mov	 es,ax		; Address it
	 assume  es:PGROUP	; Tell the assembler about it

; Set up entry point for _show_progress
	 mov	 ax,seg SCREENS_TEXT ; Get segment for _show_progress
	 jmp	 short @F	; Jump over kluge code

	 public  Farcall_kluge
Farcall_kluge	 label byte
	 call	 _show_progress ; Use opcode as data; if PUSH CS, use CS

@@:
	 cmp	 Farcall_kluge.LO,90h ; Izit NOP?
	 jne	 short @F	; No, it's a far call

	 mov	 ax,cs		; Farcall optimization in effect; use CS
@@:
	 mov	 _OPT_PROGRESS.VSEG,ax ; Store it in public entry point
	 mov	 _OPT_CALLBACK.VSEG,ax ; Fix up segment of entry point

; Calculate region sizes

	 call	 CALCREG	; Calculate region sizes
;;;;;;; MJ c	 TRIALFIT_ERRMAC ; Jump if MAC error

; Save number of regions and region sizes for later
	 mov	 cx,NREGS	; Get number of regions
	 jcxz	 Maximize_done_regs ; Jump if none

	 cmp	 cx,MAXHIGHREGIONS ; Is the size OK?
	 jna	 short @F	; Jump if so

	 mov	 cx,MAXHIGHREGIONS ; Maximum we'll copy
@@:
	 REGSAVE <si,di,es>	; Prepare for string move

	 mov	 ax,seg DGROUP ; Prepare to address DGROUP
	 mov	 es,ax		; Address it
	 assume  es:DGROUP	; Tell the assembler

	 mov	 _nHighRegions,cx ; Save it

	 lea	 si,REGTAB	; DS:SI ==> Source words
	 lea	 di,_waHighRegions ; ES:DI ==> Destination

S16 rep movs <_waHighRegions[di],REGTAB[si]> ; Move it

	 REGREST <es,di,si>	; Restore
	 assume  es:PGROUP	; Tell the assembler

Maximize_done_regs:
; Save the summary data in local tables for SUMFIT

	 call	 SAVE_SUMFIT	; Save 'em

; Allocate room for top fits

	 call	 GET_TOPFIT	; Get it

; Order the possibilities

	 push	 [bp].MAXFLAG	; Pass on caller's flag
	 call	 ORDFIT 	; Order 'em

; Copy TOPFIT data to SUMFIT tables

	 call	 CPY_SUMFIT	; Copy 'em

; De-allocate room for top fits

	 call	 RLS_TOPFIT	; Release it

; Release SUMFIT table

	 call	 REST_SUMFIT	; Release 'em

if @OEM_HARPO
; Initialize pointer to SUBFIT_TAB
	 mov	 ax,seg DGROUP	; Get local data segment
	 mov	 es,ax		; Address it
	 assume  es:DGROUP	; Tell the assembler

	 mov	 ax,NSUBSEGS	; Get number of subsegments
	 mov	 dx,ax		; Zero segment if none
	 or	 ax,ax		; Are there any?
	 jz	 short @F	; Jump if none

	 mov	 ax,PSUBSEG_TAB ; Offset of SUBFIT_TAB
	 mov	 dx,seg PGROUP	; Segment of SUBFIT_TAB
@@:
	 mov	 _psubsegs.VOFF,ax ; Save offset to PSUBFIT_TAB
	 mov	 _psubsegs.VSEG,dx ; Save segment
endif				; IF @OEM_HARPO

; Return result pointer in DX:AX

	 mov	 ax,PSUMFIT_TAB ; Get the offset into AX
	 mov	 dx,seg PGROUP	; Copy segment into DX

	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing ; Tell the assembler about it

	 call	 _enable23	; Re-enable Int 23 handling

	 pop	 bp		; Restore

	 ret			; Return to caller
				; Note:  caller strips the argument
				;	 from the stack
	 assume  ds:nothing,es:nothing,ss:nothing

_maximize endp			; End _maximize procedure

	 PPROC	 _createfile -- Create a Filename
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Create a "d:\path\filename.ext" and then close it up.

On stack:

Ptr to "d:\path\filename.ext"

On exit:

AX	 =	 0 if all went OK
	 =	 -1 otherwise

_ERRNO	 =	 error code if AX=-1

|

CF_STR	 struc

	 dw	 ?		; Caller's BP
	 dw	 (1+@codesize) dup (?) ; Caller's IP or CS:IP
CF_PFNEA dw	 (1+@datasize) dup (?) ; Pointer to "d:\path\filename.ext"

CF_STR	 ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <bx,cx,dx>	; Save registers

if @datasize			; Large data
	 push	 ds		; Save for a moment

	 lds	 dx,[bp].CF_PFNEA.EDD ; DS:DX ==> "d:\path\filename.ext"
	 assume  ds:nothing	; Tell the assembler about it
else				; Small data
	 mov	 dx,[bp].CF_PFNEA ; DS:DX ==> "d:\path\filename.ext"
endif
	 mov	 cx,DIR_ATTR_NORM ; Mark it as normal
	 DOSCALL @CREAF2	; Create the file
if @datasize			; Large data
	 pop	 ds		; Restore
	 assume  ds:DGROUP	; Tell the assembler about it
endif
	 jc	 short CF_EXECERR ; Jump if something went wrong

	 mov	 bx,ax		; Copy to handle register
	 DOSCALL @CLOSF2	; Close it up

	 xor	 ax,ax		; Clear the return code (note CF=0)
CF_EXECERR:
	 mov	 _ERRNO,ax	; Save
	 jnc	 short CF_EXIT	; Jump if no error

	 mov	 ax,-1		; Return with error
CF_EXIT:
	 REGREST <dx,cx,bx>	; Restore

	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_createfile endp		; End _createfile procedure
	 PPROC	_FP_LSEG -- File Pointer Logical Segment
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

File pointer logical segment

|

FP_STR	 struc

	 dw	 ?		; Caller's BP
	 dw	 (1+@codesize) dup (?) ; Caller's IP or CS:IP
FP_FAR	 dd	 ?		; Far data pointer

FP_STR	 ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 mov	 ax,[bp].FP_FAR.VSEG ; Get actual segment

	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_FP_LSEG endp			; End _FP_LSEG procedure
	 PPROC	_FP_LOFF -- File Pointer Logical Offset
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

File pointer logical offset

|

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 mov	 ax,[bp].FP_FAR.VOFF ; Get actual offset

	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_FP_LOFF endp			; End _FP_LOFF procedure


RPOS_STR struc

	 dw	 ?		; Caller's BP
	 dw	 (1+@codesize) dup (?) ; Caller's IP or CS:IP
RPOS_MAGIC dw	 ?		; Magic value (LO=index,HI=3)

RPOS_STR ends

	 PPROC	 _readpos32 -- Read POS values directly from NVRAM
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Read POS values directly from NVRAM.  This is not supported by the
ABIOS, and there doesn't seem to be any way to do it.  These values
are needed by the Model 90, which needs a RAM statement to protect
the XGA memory mapped I/O registers.  The values are in POS[27].

On entry:
SS:SP ==>	 RPOS_STR

On exit:
AL	 =	 POS value

|

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 mov	 ax,[bp].RPOS_MAGIC ; Get magic value

	 cli			; Nobody move
	 out	 @NVRAMIND_LO,al ; Index NVRAM
	 jmp	 short $+2	; Wait for I/O to settle

	 mov	 al,ah		; Get high byte of index (?)
	 out	 @NVRAMIND_HI,al ; Index NVRAM
	 jmp	 short $+2	; Wait for I/O to settle

	 in	 al,@NVRAMDATA	; Get byte
	 sti			; Enable interrupts

	 sub	 ah,ah		; Clear high byte

	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_readpos32 endp 		; End readpos32 procedure

WRPOS_STR struc

	 dw	 ?		; Caller's BP
	 dw	 (1+@codesize) dup (?) ; Caller's IP or CS:IP
WRPOS_MAGIC dw	 ?		; Magic value (LO=index,HI=3)
WRPOS_NEWVAL dw  ?		; New value

WRPOS_STR ends

;;;;;;;  PPROC	 _writepos32 -- Write POS values directly to NVRAM
;;;;;;;  assume  ds:DGROUP,es:nothing,ss:nothing
;;;;;;;COMMENT|
;;;;;;;
;;;;;;;Write POS values directly to NVRAM.  This is not supported by the
;;;;;;;ABIOS for POS bytes past the range 0-3, and there doesn't seem to
;;;;;;;be any way to do it.  These values may require change to relocate
;;;;;;;the Model 90's XGA memory mapped I/O registers.  The values are
;;;;;;;in POS[27].
;;;;;;;
;;;;;;;******** NOTE *******
;;;;;;;After changing these bytes, the ABIOS must be called to recompute
;;;;;;;the NVRAM checksum.
;;;;;;;
;;;;;;;On entry:
;;;;;;;SS:SP ==>	 WRPOS_STR
;;;;;;;
;;;;;;;On exit:
;;;;;;;Nothing.
;;;;;;;
;;;;;;;|
;;;;;;;
;;;;;;;  push	 bp		; Prepare to address the stack
;;;;;;;  mov	 bp,sp		; Hello, Mr. Stack
;;;;;;;
;;;;;;;  REGSAVE <ax>		; Save
;;;;;;;
;;;;;;;  mov	 ax,[bp].WRPOS_MAGIC ; Get magic value
;;;;;;;
;;;;;;;  cli			; Nobody move
;;;;;;;  out	 @NVRAMIND_LO,al ; Index NVRAM
;;;;;;;  jmp	 short $+2	; Wait for I/O to settle
;;;;;;;
;;;;;;;  mov	 al,ah		; Get high byte of index (?)
;;;;;;;  out	 @NVRAMIND_HI,al ; Index NVRAM
;;;;;;;  jmp	 short $+2	; Wait for I/O to settle
;;;;;;;
;;;;;;;  mov	 al,[bp].WRPOS_NEWVAL.LO ; Get new NVRAM value
;;;;;;;  out	 @NVRAMDATA,al	; Write byte
;;;;;;;  sti			; Enable interrupts
;;;;;;;
;;;;;;;  REGREST <ax>		; Restore
;;;;;;;
;;;;;;;  pop	 bp		; Restore
;;;;;;;
;;;;;;;  ret			; Return to caller
;;;;;;;
;;;;;;;  assume  ds:nothing,es:nothing,ss:nothing
;;;;;;;
;;;;;;;_writepos32 endp 	; End writepos32 procedure
	 NPPROC  IZIT386 -- Determine Presence of 386 or Later
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Determine presence of an 80386 or later processor.

On exit:

CF	 =	 0 if it's a 386 or later CPU
	 =	 1 otherwise

N.B.:  Use only 8088 instructions!!!!

|

	 REGSAVE <ax>		; Save register

	 push	 sp		; First test for earlier than a 286
	 pop	 ax

	 cmp	 ax,sp		; Same?
	 jne	 short IZIT386_X386 ; No, it's too early
.286

; Now distinguish 286 from 386

	 pushf			; Save flags for a moment

	 push	 mask $IOPL	; Try to set IOPL bits in flag register
	 popf

	 pushf			; Get flags back into AX
	 pop	 ax

	 popf			; Restore original flags

	 test	 ax,mask $IOPL	; Any bits set?
	 jnz	 short IZIT386_EXIT ; Yes, so it's a 386 or later (note CF=0)
IZIT386_X386:
	 stc			; Indicate it's not a 386
IZIT386_EXIT:
	 REGREST <ax>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT386  endp			; End IZIT386 procedure
	 NPPROC  IZIT486 -- Determine Presence of 486 or Later
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

The test for 386 vs. 486 or later is done by attempting to set the
Alignment Check bit in the high-order word of the extended flag dword.
If that's successful, it's a 486 or later; otherwise, it's not.

On exit:

CF	 =	 0 if it's a 486 or later CPU
	 =	 1 otherwise

|

DOT386 p

	 push	 bp		; Save to align stack
	 mov	 bp,sp		; Save original stack pointer

	 and	 esp,(0FFFFh and (not (4-1))) ; Align on a dword boundary in
				; case we're in V86 mode and $AM is set in CR0
				; Also clear upper word of ESP

	 push	 eax		; Save to use as scratch
	 pushfd 		; Save original flags

	 pushfd 		; Save temporary flags
	 or	 [esp].EHI,mask $AC ; Set Alignment Check bit
	 popfd			; Put into effect

	 pushfd 		; Put onto the stack
	 pop	 eax		; Copy to register

	 test	 eax,(mask $AC) shl 16 ; Izit still set?
	 jnz	 short @F	; Yes, so it's a 486

	 popfd			; Restore temporary flags

	 stc			; Indicate it's not a 486

	 jmp	 short IZIT486_EXIT ; Join common code

@@:
	 popfd			; Restore temporary flags

	 clc			; Indicate it's a 486
IZIT486_EXIT:
	 pop	 eax		; Restore

	 mov	 sp,bp		; Restore original pointer
	 pop	 bp		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

IZIT486  endp			; End IZIT486 procedure
	 PPROC	 _nogate -- Set flag for NOGATE option
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

The Maximize.cfg NOGATE keyword tells us not to use WBINVD to flush
the cache.  If MAX is present, WBINVD will be emulated according to
Gateway detection or the presence of the 386MAX NOGATE keyword.

|

	 or	 _SUB_FLAG,@SUB_XINVD ; Don't use WBINVD

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

_nogate  endp			; End _nogate procedure
	 NPPROC  SAVE_CACHE -- Save and Disable Cache Controller
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save the state of and disable the cache controller.

On exit:

EBP	 =	 state of cache controller

|

; If we're on a 486 or later system, disable the cache through CR0

	 test	 _SUB_FLAG,@SUB_486 ; Izit a 486?
	 jz	 short SAVE_CACHE_X486 ; Jump if not

	 push	 eax		; Save register

	 mov	 eax,cr0	; Get current value
	 mov	 ebp,eax	; Save to restore later
	 or	 eax,(mask $CD) or (mask $NW) ; CD=NW=1

	 test	 _SUB_FLAG,@SUB_XINVD ; NOGATE specified?

	 mov	 cr0,eax	; Tell the CPU about it

; WBINVD locks some Gateway systems.  If Max is present, WBINVD will be
; emulated by manually flushing the cache.  If the NOGATE option is present
; in MAXIMIZE.CFG, we'll force the manual flush.
	 jnz	 short @F	; Jump if NOGATE specified

	 WBINVD 		; Write-back external cache and flush
	 jmp	 short SAVE_CACHE_XFLUSH ; Join common code

@@:
	 call	 _FLUSH_CACHE	; Manually flush cache controller

SAVE_CACHE_XFLUSH:
	 pop	 eax		; Restore

;;;;;;;; jmp	 short SAVE_CACHE_EXIT ; Join common exit code

SAVE_CACHE_X486:
SAVE_CACHE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_CACHE endp 		; End SAVE_CACHE procedure
	 NPPROC  REST_CACHE -- Restore Cache Controller
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Restore the state of the cache controller

On entry:

EBP	 =	 original state of cache controller

|

; If we're on a 486 or later system, restore the state of the cache

	 test	 _SUB_FLAG,@SUB_486 ; Izit a 486?
	 jz	 short REST_CACHE_X486 ; Jump if not

	 push	 eax		; Save register

	 mov	 eax,cr0	; Get current value
	 and	 eax,not ((mask $CD) or (mask $NW)) ; CD=NW=0
	 and	 ebp,(mask $CD) or (mask $NW) ; Isolate original state
	 or	 eax,ebp	; Set to previous value

	 test	 _SUB_FLAG,@SUB_XINVD ; NOGATE specified?

	 mov	 cr0,eax	; Tell the CPU about it

; WBINVD locks some Gateway systems.  If Max is present, WBINVD will be
; emulated by manually flushing the cache.  If the NOGATE option is present
; in MAXIMIZE.CFG, we'll force the manual flush.
	 jnz	 short @F	; Jump if NOGATE specified

	 WBINVD 		; Write-back external cache and flush
	 jmp	 short REST_CACHE_XFLUSH ; Join common code

@@:
	 call	 _FLUSH_CACHE	; Manually flush cache controller

REST_CACHE_XFLUSH:
	 pop	  eax		; Restore

;;;;;;;; jmp	 short REST_CACHE_EXIT ; Join common exit code

REST_CACHE_X486:
REST_CACHE_EXIT:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

REST_CACHE endp 		; End REST_CACHE procedure

if @OEM_HARPO
	 PPROC	 _harpo_pro -- Return far pointer to HARPO profile
	 assume  ds:DGROUP,es:nothing,ss:nothing

	 REGSAVE <di>		; Save

	 push	 ds		; Get DGROUP segment
	 pop	 es		; Address for EMM2CALL
	 assume  es:DGROUP	; Tell the assembler

	 lea	 di,DGROUP:_Harpo_profile ; Address of HARPO profile

	 cmp	 _Harpo_profile,0 ; Has it already been set?
	 jne	 short HPRO_EXIT ; Jump if so

	 EMMOUT  @EMM2_HARPOINFO,@HARPO_GET_FILESPEC ; Copy profile name to ES:DI
HPRO_EXIT:
	 mov	 dx,es		; Segment of Harpo_profile
	 mov	 ax,di		; Offset

	 REGREST <di>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_harpo_pro endp 		; End _harpo_pro procedure
endif				; IF @OEM_HARPO

if (ASYS NE MOVEM)
	 PPROC	 _openhigh -- Attempt to link high DOS using 5803
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Try to link arenas.  Return AX=0 if we succeed, else DOS error code.

On exit:
AX	 0 or DOS error code

|

	 REGSAVE <bx,es>	; Save

	 mov	 ax,_LoadSeg	; Get start of LSEG chain
	 cmp	 ax,-1		; Izit valid?
	 je	 short @F	; Jump if not

; Set the 386LOAD in-progress bit in the first LSEG entry.  This
; prevents MAX from creating LSEG entries for UMBs allocated by
; MAXIMIZE via malloc().
	 mov	 es,ax		; Address first LSEG (386MAX)
	 assume  es:nothing	; Tell the assembler

	 or	 es:[0].LSEG_FLAG,@LSEG_INPRO ; Set 386LOAD in-progress bit
@@:
	 mov	 ax,@MACALG*256 + 03h ; Set arena link state to BX
	 mov	 bx,mask $LINK_HIGH ; 0001 to link
	 DOSCALL		; AX=error code if failure
	 jc	 short @F	; Jump if we failed

	 sub	 ax,ax		; Indicate success
@@:
	 REGREST <es,bx>	; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_openhigh endp			; End _openhigh procedure
endif				; IF ASYS NE MOVEM
if (ASYS NE MOVEM)
	 PPROC	 _closehigh -- Attempt to close high DOS using 5803
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Try to unlink arenas.  Return AX=0 if we succeed, else DOS error code.

On exit:
AX	 0 or DOS error code

|

	 REGSAVE <bx,es>	; Save

	 mov	 ax,@MACALG*256 + 03h ; Set arena link state to BX
	 sub	 bx,bx		; 0000 to unlink
	 DOSCALL		; AX=error code if failure
	 jc	 short @F	; Jump if we failed

	 sub	 ax,ax		; Indicate success
@@:
	 mov	 bx,_LoadSeg	; Get start of LSEG chain
	 cmp	 bx,-1		; Izit valid?
	 je	 short @F	; Jump if not

; Clear the 386LOAD in-progress bit in the first LSEG entry.  We
; set it on entry in openhigh() to prevent MAX from creating LSEG
; entries for UMBs allocated by MAXIMIZE via malloc().
	 mov	 es,bx		; Address first LSEG (386MAX)
	 assume  es:nothing	; Tell the assembler

	 and	 es:[0].LSEG_FLAG,not @LSEG_INPRO ; Clear 386LOAD in-progress bit
@@:
	 REGREST <es,bx>	; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_closehigh endp 		; End _closehigh procedure
endif				; IF ASYS NE MOVEM
if (ASYS NE MOVEM)
	 PPROC	 _is_PCI -- Check for PCI local bus BIOS
	 assume  ds:DGROUP,es:nothing,ss:nothing
COMMENT|

If a newer version of MAX tests for the PCI local bus BIOS, we'll
need to strip out USE= statements in the system ROM area if we don't
already have the PCIBIOS keyword in MAXIMIZE.CFG.

On exit:
	 AX=0	 No PCI BIOS
	 AX!=0	 PCI BIOS

|

	 mov	 ax,SYS_FLAG.ELO ; Get SYS_FLAG from MAX

; Note that the following will generate an error if @SYS_PCIBIOS is in
; the high word of SYS_FLAG.
	 and	 ax,@SYS_PCIBIOS ; Isolate PCI local bus BIOS

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

_is_PCI  endp			; End _is_PCI procedure
endif				; IF ASYS NE MOVEM

	 MEND			; End MAXSUB module
