;' $Header:   P:/PVCS/MAX/BATPROC/EXEC.ASV   1.0   05 Sep 1995 15:08:52   HENRY  $

	  title     EXEC - Execute another program

	  page	    ,132		;make wide listing

	  comment   }

	  (C) Copyright 1990, Rex Conn, GNU General Public License version 3

	  These support routines replaces DOS function 4B, to execute
	  another program.  They also provide critical error handling.

	  } end description

	  ;
	  ; Includes
	  ;
	  include   macros.asm		 ;general macros

	  include   MASM.INC
	  include   DOSCALL.INC
	  include   IOCTL.INC

	  include   QMAX_CTL.INC
	  include   LOAD_SEG.INC

	  ;
	  ; External references
	  ;
	  extrn     _break_handler:near, errmsga:near

	  ;
	  ; Local macros
	  ;
loadds	  macro     reg 		; load ds differently depending on
					;    memory model
	  mov	    reg,DGROUP		; otherwise just load group location
	  mov	    ds,reg		; set up ds
	  assumeds			; set up assume
	  endm

assumeds  macro 			; set up ds assume depending on
					;    memory model
	  assume    ds:DGROUP		; fix assumes
	  endm

msg	  macro     name,text		; define message text
	  local     mbeg, mlen		; message start, length are local
mbeg	  equ	    $			; message start
name	  db	    mlen, text		; define length and text
mlen	  equ	    $ - mbeg - 1	; set length
	  endm

	  ;
	  ; Parameters
	  ;
	  ;    Bits in i24flags
	  ;
CHARDEV   equ	    80h 		;device is a character device
DOS3	  equ	    40h 		;running under DOS 3 or above


_DATA	  segment   word public 'DATA'  ;otherwise define data segment
DGROUP	  group     _DATA		;and group it
	  assume    cs:_TEXT, ds:DGROUP, es:nothing, ss:nothing

	  extrn     _tsrflag:word
;;;;;;;   extrn     _umbflag:word
;;;;;;;   extrn     _umbfailed:word
	  extrn     __psp:word
	  extrn     _psp_master:word
	  extrn     _loadhigh:word


oldint23  farptr    <>			;old INT 23h pointer
oldint24  farptr    <>			; old INT 24h pointer
ss_save   dw	    ?			;stack segment save
sp_save   dw	    ?			;stack pointer save
s_handles dw	    ?			; saved handles for STDIN & STDOUT

majorver  db	    ?			;DOS major version number for int24
i24flags  db	    ?			;int 24 handler control bits
int24sp   dw	    ?			;original stack pointer on int 24h
savecode  db	    ?			;temporary save of int 24 return code
inshell   db	    ?			;1 = in BATPROC, 0 = in external prog
brkflag   db	    ?			;ctrl-C flag

	  msg	    deverr, <" on device         ">  ;device error message
devname   equ	    deverr + 12 	;place to put device name

	  msg	    prompt1, <13,10,"R(etry), I(gnore), ">
	  msg	    prompt2, <"F(ail), ">
	  msg	    prompt3, <"or A(bort)? ">

	  msg	    bsmsg, <BS> 	;backspace
	  msg	    lfcrlf, <LF, CR, LF>  ;lf / cr / lf

	  public    MAXNAME,MOVNAME,MAXHNDL,MOVEM
MAXNAME   db	    '386MAX$$',0        ; Device name for 386MAX
MOVNAME   db	    'MOVE''EM$',0       ; Device name for Move'EM
MAXHNDL   dw	    ?			; Device handle
MOVEM	  db	    0			; 1 if Move'EM, 0 if MAX

	 public  INFO_CTL,MAXINFO
	 include QMAXINFO.INC
;;;;;;	 include MOVEINFO.INC
; INFO area structure common to MOVE'EM

MINFO_STR struc

MINFO_SIGN db	 '        '     ; 00-05:  Signature = "MOVE'EM"
MINFO_VER  db	 ?		; 06:	  MOVE'EM version # (filled in by MOVE'EM)
	  db	 '.'            ; 07:
	  db	 ?		; 08:
	  db	 ?		; 09:
MINFO_P1ST dd	 -1		; 0A-0D:   1 = Pointer to first MAC in low  DOS memory
MINFO_POVR dw	 -1		; 0E-0F:   2 = Segment of first MAC in high DOS memory
MINFO_LSEG dw	 0		; 10-11:   3 = 386LOAD chain segment
MINFO_OLD  dw	 ?		; 12-13:   4 = Old top of DOS in paras
MINFO_I21  dd	 ?		; 14-17:   5 = Old INT 21h handler
MINFO_CM2  dw	 0		; 18-19:   6 = CM2_FLAG
MINFO_MFL  dw	 0		; 1A-1B:   7 = MOV_FLAG

MINFO_STR ends

	 db	 ?			; Force even alignment for INFO_STR
INFO_CTL db	 ?			; IOCTL type
MAXINFO   INFO_STR  <>			; MAX info structure

@LSEGMAX equ	 128			; VERY long time to optimize...
	 align	 word
	 public  LSEG_PARA,LSEG_LIST
LSEG_PARA dw	 ?			; Paragraph of starting LSEG entry
LSEG_LIST dw	 (@LSEGMAX+1) dup (-1)	; List of valid LSEG entries

_DATA	  ends				;close data segment

	  page

_TEXT	  segment   word public 'CODE'  ;and start code segment
CGROUP	  group     _TEXT		; Ensure we have a group for _TEXT
	  assume    ds:DGROUP

	 public  oldint21,oldint27,bp_done
oldint21  farptr    <>			; old INT 21h pointer
oldint27  farptr    <>			; old INT 27h pointer
;;;;;;;xms_arg	 dw	    ?		; Last XMS function code (AX)
bp_done   db	    0			; if != 0, then BATPROC is finished

;;;;;;;  public  oldxmscall
;;;;;;;oldxmscall label    far		; Use to call previous handler
;;;;;;;oldxmshdr  db	    5 dup (?)
;;;;;;;    db	    0EAh		; Opcode for far jump immediate
;;;;;;;oldxmsnxt  farptr   <>		; Address of next XMS instruction

	 NPPROC _previous_umb -- Return count of previous UMB LSEG entries
	 assume ds:DGROUP,es:nothing,ss:nothing

COMMENT|

No arguments.  Gets MAX info structure, starts at beginning of LSEG chain,
and returns in AX the total number of UMB entries found AFTER the last
386LOAD LSEG entry (where LSEG_GRP <> @GRPUMB).

We take advantage of the order of the LSEG chain, and the order in which
CONFIG.SYS is processed.  Unlike the MAC chain, the LSEG chain is chrono-
logical.  386MAX.SYS will always come at the head of the LSEG chain
(unless NOLOADHIGH is specified).  Furthermore, all DEVICE= statements
in CONFIG.SYS will be processed before all INSTALL= statements, which
in turn will be processed before DOS processes the SHELL= statement.

Since the idea here is to catch any UMB allocations made by the SHELL=
program (NDOS and 4DOS both allocate UMB's at SHELL= time), we walk
through the LSEG chain to its (present) end.  A non-UMB entry (which
must be a DEVICE=/INSTALL= getsize or load high LSEG entry created by
386LOAD) resets our count of trailing UMB's to 0.  UMB LSEG entries
(which are created by XMS services, not by 386LOAD) are counted.  We
end up with a count of trailing UMB entries, which may include UMB's
allocated by the LAST statement in CONFIG.SYS as well as UMB's allocated
during processing of the SHELL= statement.

This scheme also assumes that BATPROC is run before any post-CONFIG.SYS
programs have had a chance to allocate UMB's.  In other words, it will
work in the MAXIMIZE context; otherwise, the value returned by this
procedure and stored in BATPROC.UMB is inaccurate as far as UMB's
allocated in CONFIG.SYS.  It will always accurately report trailing
UMB's at the time BATPROC is executed.

We also initialize LSEG_LIST for later comparison.  We can no longer
rely on hooking XMS UMB services to determine whether a program creates
LSEG entries; we need to compare the LSEG chain before and after the
program executes.  We call this procedure to initialize the list, and
new_umbs() after each program terminates.

|

	 REGSAVE <si,di,bp,es>	; Save

	 mov	 MAXHNDL,-1	; Initialize to invalid handle
	 mov	 LSEG_PARA,-1	; Assume no LSEG chain
	 mov	 LSEG_LIST,-1	; Assume no UMBs in chain

; Ensure we're already installed

	 mov	 al,02h 	; Access code for read/write
	 DOSCALL @OPENF2,MAXNAME ; Attempt to open 386MAX device driver
	 jnc	 short @F	; Jump if installed

PREVUMB_MOVE:
	 mov	 MOVEM,1	; Flag to use Move'EM info structure

	 mov	 al,02h 	; Access code for read/write
	 DOSCALL @OPENF2,MOVNAME ; Attempt to open Move'EM driver
	 jc	 short PUMB_ERR ; Jump if not installed

@@:
	 mov	 MAXHNDL,ax	; Save for later use
	 mov	 bx,ax		; Copy to handle register

; Ensure it's a device

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 jc	 short PUMB_ERR ; Something went wrong

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 short PUMB_ERR ; No???

	 mov	 al,02h 	; Read from device
	 mov	 bx,MAXHNDL	; Get device handle
	 mov	 cx,size INFO_STR ; CX = # bytes in INFO structure
	 cmp	 MOVEM,1	; Izit Move'EM?
	 jne	 short @F	; Jump if not

	 mov	 cx,size MINFO_STR ; CX = # bytes in Move'EM INFO structure
@@:
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into MAXINFO

	 sub	 ax,ax		; Clear result
	 mov	 dx,MAXINFO.INFO_LSEG ; Get first LSEG entry
	 cmp	 MOVEM,1	; Izit Move'EM?
	 jne	 short @F	; Jump if not

	 mov	 dx,MAXINFO.MINFO_LSEG ; Get first LSEG entry
@@:
	 mov	 LSEG_PARA,dx	; Save starting entry for later
	 sub	 bx,bx		; Address start of LSEG_LIST
PUMB_LSEG:
	 cmp	 dx,-1		; Izit the last one?
	 je	 short PUMB_EXIT ; Jump if so

	 mov	 es,dx		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 cmp	 es:[0].LSEG_GRP,@GRPUMB ; Izit a UMB?
	 jne	 short @F	; Jump if not

	 mov	 LSEG_LIST[bx],dx ; Save segment of UMB LSEG
	 add	 bx,type LSEG_LIST ; Skip to next entry
	 mov	 LSEG_LIST[bx],-1 ; Make sure it's terminated
	 inc	 ax		; Bump UMB count
	 jmp	 short PUMB_COMN ; Join common code for LSEG entry

@@:
	 sub	 ax,ax		; Restart UMB count for non-UMB entry
PUMB_COMN:
	 mov	 dx,es:[0].LSEG_NEXT ; Get segment of next entry
	 jmp	 short PUMB_LSEG ; Go around again

PUMB_ERR:
	 sub	 ax,ax		; Indicate failure - no UMB's found

PUMB_EXIT:
	 push	 ax		; Save for a minute
	 mov	 bx,MAXHNDL	; Get file handle
	 cmp	 bx,-1		; Did it get opened?
	 je	 short @F	; Jump if not

	 DOSCALL @CLOSF2	; Close file handle in BX
	 mov	 MAXHNDL,-1	; Mark as closed
@@:
	 pop	 ax		; Restore return value

	 push	 ax		; Save return value
	 or	 al,ah		; Combine return value bytes
	 or	 al,MOVEM	; Any found, or did we already try Move'em?
	 pop	 ax		; Restore return value
	 jnz	 short @F	; Jump if so

	 jmp	 PREVUMB_MOVE	; Jump if not

@@:
	 REGREST <es,bp,di,si>	; Restore
	 assume  es:nothing	; Tell the assembler

	 ret

	 assume ds:nothing,es:nothing

_previous_umb	endp			; Procedure Previous_UMB

	 NPPROC  _new_umbs -- Return number of UMBs added to LSEG chain
	 assume ds:DGROUP,es:nothing,ss:nothing
COMMENT|

Count every UMB LSEG that's not already in our list, and add them
to our list.  Purge any UMB LSEGs from our list if they aren't
currently in the LSEG chain.

Returns number of new UMBs in AX.  BX, CX, DX, and ES are trashed.

|

	 REGSAVE <si,di>	; Save

; First check for any UMB LSEG entries not in our list
	 push	 ds		; Get DGROUP segment
	 pop	 es		; Address for SCAS
	 assume  es:DGROUP	; Tell the assembler

	 lea	 di,LSEG_LIST	; Address list of LSEG segments
	 cld			; Strings ops forward
	 mov	 cx,@LSEGMAX	; Maximum number of entries
	 mov	 ax,-1		; End of list
  repne  scas	 LSEG_LIST[di]	; ES:DI ==> word after -1
	 jne	 short @F	; Jump if we ran till end

	 inc	 cx		; Subtract ending word (-1)
@@:
	 sub	 cx,@LSEGMAX	; Get -count of entries
	 neg	 cx		; Number of valid entries (not counting -1)

	 mov	 ax,LSEG_PARA	; Get paragraph of first LSEG entry
	 sub	 dx,dx		; Initialize count of new UMBs
NEWU_LSEG:
	 cmp	 ax,-1		; Izit the last one?
	 je	 short NEWU2	; Jump if so

	 mov	 es,ax		; Address it
	 assume  es:nothing	; Tell the assembler about it

	 push	 es:[0].LSEG_NEXT ; Save segment of next entry

	 cmp	 es:[0].LSEG_GRP,@GRPUMB ; Izit a UMB?
	 jne	 short @F	; Jump if not

	 push	 ds		; Get DGROUP segment
	 pop	 es		; Address for SCAS
	 assume  es:DGROUP	; Tell the assembler

	 lea	 di,LSEG_LIST	; Address list of LSEG segments
	 jcxz	 NEWU_ADDLSEG	; Add to list if none already present

	 push	 cx		; Save
  repne  scas	 LSEG_LIST[di]	; ES:DI ==> current -1 if not found
	 pop	 cx		; Restore
	 je	 short @F	; Jump if found

NEWU_ADDLSEG:
	 inc	 dx		; Count new LSEG entry
	 inc	 cx		; Add to count
	 mov	 DGROUP:[di].foff,ax ; Add to list
	 mov	 DGROUP:[di+(type LSEG_LIST)].foff,-1 ; Make sure list is terminated
@@:
	 pop	 ax		; Get segment of next entry
	 jmp	 short NEWU_LSEG ; Go around again

NEWU2:
; Now check for entries in LSEG_LIST that aren't LSEGs and delete them.
	 lea	 si,LSEG_LIST	; Address our list of LSEG UMB entries
	 mov	 di,si		; Copy to same offset

NEWU_NEXTLIST:
	 push	 ds		; Get DGROUP segment
	 pop	 es		; ES:DI ==> copy destination
	 assume  es:DGROUP	; Tell the assembler

	 lods	 LSEG_LIST[si]	; Get next entry
	 stos	 LSEG_LIST[di]	; Save it

	 cmp	 ax,-1		; Izit the end of the list?
	 je	 short NEWU_EXIT ; Jump if so

; If entry isn't in list, back off di to delete it.
	 mov	 bx,LSEG_PARA	; Get starting LSEG
NEWU_CHKLSEG:
	 cmp	 bx,-1		; Izit the end?
	 je	 short NEWU_DELETE ; Jump if so (delete from list)

	 cmp	 bx,ax		; Izit our boy?
	 je	 short NEWU_NEXTLIST ; Jump if so

	 mov	 es,bx		; Address LSEG entry
	 assume  es:nothing	; Tell the assembler

	 mov	 bx,es:[0].LSEG_NEXT ; Get paragraph of next LSEG entry
	 jmp	 short NEWU_CHKLSEG ; Go around again

NEWU_DELETE:
	 sub	 di,(type LSEG_LIST) ; Delete this entry
	 jmp	 short NEWU_NEXTLIST ; Go around again

NEWU_EXIT:
	 mov	 ax,dx		; Return number of new UMBs found

	 REGREST <di,si>	; Restore

	 ret

	 assume ds:nothing,es:nothing

_new_umbs	endp		; End procedure _new_umbs

	  ;
	  ; INT21 - Handle 31h call (Terminate & stay resident)
	  ;
	  ; On entry:
	  ;	    No requirements
	  ;
	  ; On exit:
	  ;	    All registers unchanged, interrupts on
	  ;
	  ;

	  public    int21
	  entry     int21,noframe,far,local
	  assume    ds:nothing

;;;;;;;;; sti				;restore interrupts
	  cmp	    cs:bp_done,1	; if BATPROC finished, ignore interrupt
	  je	    next_21
	  cmp	    ah,D_TSR
	  jne	    next_21
	  pushm     ax,ds		;save registers
	  loadds    ax			;set ds to data area using ax
	  assume    ds:DGROUP		; Tell the assembler
	  mov	    _tsrflag,21h	;set flag
	  popm	    ds,ax		;restore registers
	  assume    ds:nothing		; Tell the assembler
next_21:
	  jmp	    cs:[oldint21]
	  exit				;all done
	  assume    ds:nothing		; Tell the assembler


	  ;
	  ; INT27 - Handle old-fashioned Terminate & stay resident call
	  ;
	  ; On entry:
	  ;	    No requirements
	  ;
	  ; On exit:
	  ;	    All registers unchanged, interrupts on
	  ;

	  public    int27
	  entry     int27,noframe,far,local
	  assume    ds:nothing

	  sti				;restore interrupts
	  cmp	    cs:bp_done,1	; if BATPROC finished, ignore interrupt
	  je	    next_27
	  pushm     ax,ds		;save registers
	  loadds    ax			;set ds to data area using ax
	  assume    ds:DGROUP		; Tell the assembler
	  mov	    _tsrflag,27h	;set flag
	  popm	    ds,ax		;restore registers
	  assume    ds:nothing		; Tell the assembler
next_27:
	  jmp	    cs:[oldint27]
	  exit				;all done
	  assume    ds:nothing		; Tell the assembler


COMMENT|  -- This code is no longer needed --
	  ;
	  ; XMS_UMB - Handle XMS UMB calls
	  ;
	  ; On entry:
	  ;	    No requirements
	  ;
	  ; On exit:
	  ;	    All registers unchanged, interrupts on
	  ;

	  public    xms_umb
	  entry     xms_umb,noframe,far,local
	  assume    ds:nothing		; Tell the assembler

	  jmp	    short umb_entry	; for "hookability"
	  nop
	  nop
	  nop
umb_entry:
	  cmp	    bp_done,1		; if BATPROC finished, ignore interrupt
	  jne	    call_xms

	  call	    oldxmscall		; call XMS routines
	  jmp	    xms_bye

call_xms:
	  sti				;restore interrupts
	  push	    ax			; Save the function code
	  call	    oldxmscall		; call XMS routines
	  pop	    xms_arg		; Restore function code
	  or	    ax,ax		; AX = 1 if request was granted
	  jne	    short @F		; Jump if succeeded

	  cmp	    byte ptr xms_arg[1],010h ; Izit a UMB request?
	  jne	    short xms_bye	; request failed - forget about it

	  pushm     ax,ds		; Save registers
	  loadds    ax			; Address DGROUP
	  assume    ds:DGROUP		; Tell the assembler

	  inc	    _umbfailed		; Bump count of UMB failures

	  popm	    ds,ax		; Restore registers
	  assume    ds:nothing		; Tell the assembler
	  jmp	    short xms_bye	; Join common exit code

@@:
	  cmp	    byte ptr xms_arg[1],010h ; is it a Request UMB call?
	  jne	    free_umb

	  pushm     ax,ds		;save registers
	  loadds    ax			;set ds to data area using ax
	  assume    ds:DGROUP		; Tell the assembler

	  inc	    _umbflag		;set flag

	  popm	    ds,ax		;restore registers
	  assume    ds:nothing		; Tell the assembler
	  jmp	    short xms_bye

free_umb:
	  cmp	    byte ptr xms_arg[1],011h ; is it a free UMB call?
	  jne	    xms_bye

	  pushm     ax,ds		;save registers
	  loadds    ax			;set ds to data area using ax
	  assume    ds:DGROUP		; Tell the assembler

	  dec	    _umbflag		;set flag

	  popm	    ds,ax		;restore registers
	  assume    ds:nothing		; Tell the assembler
xms_bye:
	  exit				;all done

	  assume    ds:nothing		; Tell the assembler
|

	  ;
	  ; PSP_ENTRY - Dummy code to be moved down to PSP, offset 80h
	  ;

	  public	PSP_ENTRY,INT21PSP,INT27PSP
PSP_ENTRY label  byte
INT21PSP:
	  db	 0eah			; JMP FAR immed
	  dd	 CGROUP:int21
INT27PSP:
	  db	 0eah			; JMP FAR immed
	  dd	CGROUP:int27
;;;;;;;XMSPSP:
;;;;;;;   jmp	 short XMSPSP2
;;;;;;;   nop
;;;;;;;   nop
;;;;;;;   nop
;;;;;;;XMSPSP2:
;;;;;;;   db	 0eah			; JMP FAR immed
;;;;;;;   dd	 CGROUP:xms_umb
PSP_ENTRY_LEN	 equ	$-PSP_ENTRY

	  ;
	  ; PSP entry points for local int 21 and int 27 handlers
	  ;
	  ; These intermediate vectors are reset to their original values
	  ; when BATPROC goes resident, enabling us to throw away everything
	  ; above the PSP.
	  ;

INT21PSP_ENTRY	 equ	 80h		; Entry point for int 21 in PSP
INT21PSP_VEC	 equ	 INT21PSP_ENTRY+1 ; seg:offset of int 21 handler in PSP
INT27PSP_ENTRY	 equ	 85h		; Entry for int 27 in PSP
INT27PSP_VEC	 equ	 INT27PSP_ENTRY+1 ;	  "       int 27        "
;;;;;;;XMSPSP_ENTRY	 equ	 8Ah		; Entry for XMS handler in PSP
;;;;;;;XMSPSP_VEC	 equ	 XMSPSP_ENTRY+6 ;	"       XMS           "


	  ;
	  ; INIT_TSR - Set up TSR trapping code for INT 21 and INT 27
	  ;
	  ; On entry:
	  ;	    assume ds:DGROUP
	  ;
	  ; On exit:
	  ;	    AX, BX, CX, DX, ES destroyed
	  ;	    All other registers and interrupt state unchanged
	  ;

	  entry     _init_tsr,noframe	;set up entry point, no stack frame
	  assume    ds:DGROUP,es:nothing ; Called from C code

	  push	    ds			;save ds
	  push	    si			; Save SI
	  push	    di			; Save DI for a moment
	  mov	    bx,__psp		; Get PSP
	  mov	    di,INT21PSP_ENTRY	; Start of PSP area to use
	  mov	    es,bx		; Address PSP
	  assume    es:nothing		; Tell the assembler

	  loadseg   ds,cs,ax		;point ds to code segment
	  assume    ds:CGROUP		; Tell the assembler

	  lea	    si,PSP_ENTRY	; Dummy code to move down
	  mov	    cx,PSP_ENTRY_LEN	; Number of bytes to move
     rep  movsb 			; Move CX bytes from ds:si to es:di
	  pop	    di			; Restore DI
	  mov	    si,bx		; Save PSP value

	  mov	    al,21h		;interrupt number
	  calldos   GETINT		;get interrupt vector
	  assume    es:nothing		; Tell the assembler
	  mov	    oldint21.foff,bx	;save offset
	  mov	    oldint21.fseg,es	;save segment

	  mov	    al,27h		;interrupt number
	  calldos   GETINT		;get interrupt vector
	  assume    es:nothing		; Tell the assembler
	  mov	    oldint27.foff,bx	;save offset
	  mov	    oldint27.fseg,es	;save segment

	  push	    ds			; Save DS (pointing to code segment)
	  mov	    ds,si		; Load DS with PSP
	  assume    ds:nothing		; Tell the assembler
	  mov	    dx,INT21PSP_ENTRY	;ds:dx points to int21 handler in PSP
	  mov	    al,21h		;interrupt number
	  calldos   SETINT		;set new vector address

	  mov	    ds,si		; Load DS with PSP
	  assume    ds:nothing		; Tell the assembler
	  mov	    dx,INT27PSP_ENTRY	;ds:dx points to int27 handler in PSP
	  mov	    al,27h		;interrupt number
	  calldos   SETINT		;set new vector address
	  pop	    ds			; Restore DS (code segment)

;;;;;;;   mov	    ax,XMSTEST
;;;;;;;   int	    2Fh
;;;;;;;   cmp	    al,XMSFLAG
;;;;;;;   jne	    end_set		; no XMS driver loaded
;;;;;;;
;;;;;;;   mov	    ax,XMSADDR
;;;;;;;   int	    2Fh 		; pointer to XMS header in ES:BX
;;;;;;;   assume    es:nothing		; Tell the assembler
;;;;;;;
;;;;;;;   loadseg   ds,cs,ax		;point ds to code segment
;;;;;;;   assume    ds:CGROUP		; Tell the assembler
;;;;;;;
;;;;;;;   cli
;;;;;;;
;;;;;;;   mov	    al,es:[bx+0]	; Copy bytes 0-4 to local save area
;;;;;;;   mov	    oldxmshdr[0],al	; ...
;;;;;;;   mov	    al,es:[bx+1]	; ...
;;;;;;;   mov	    oldxmshdr[1],al	; ...
;;;;;;;   mov	    al,es:[bx+2]	; ...
;;;;;;;   mov	    oldxmshdr[2],al	; ...
;;;;;;;   mov	    al,es:[bx+3]	; ...
;;;;;;;   mov	    oldxmshdr[3],al	; ...
;;;;;;;   mov	    al,es:[bx+4]	; ...
;;;;;;;   mov	    oldxmshdr[4],al	; ...
;;;;;;;
;;;;;;;   mov	    oldxmsnxt.foff,bx	; save offset
;;;;;;;   add	    oldxmsnxt.foff,5	; avoid the jump at the beginning
;;;;;;;   mov	    oldxmsnxt.fseg,es	; save segment
;;;;;;;
;;;;;;;   mov	    byte ptr es:[bx],0EAh
;;;;;;;   mov	    word ptr es:[bx+1],XMSPSP_ENTRY
;;;;;;;   mov	    es:[bx+3],si
;;;;;;;   sti
;;;;;;;
;;;;;;;end_set:
	  pop	    si			; Restore SI
	  pop	    ds			;restore ds
	  assume    ds:nothing		; Tell the assembler

	  exit				;all done, no stack frame

	  assume    ds:nothing,es:nothing

	  ;
	  ; DEINIT_TSR - End TSR trapping for INT 21 and INT 27
	  ;
	  ; On entry:
	  ;	    DS is assumed to be = DGROUP
	  ;
	  ; On exit:
	  ;	    AX, BX, DX, ES destroyed
	  ;	    All other registers and interrupt state unchanged
	  ;

	  entry     _deinit_tsr,noframe ; set up entry point, no stack frame
	  assume    ds:DGROUP

	  mov	    bp_done,1		; set "BATPROC done" flag

	  push	    ds

	  push	    ds			; Get DGROUP segment
	  pop	    es			; Keep addressability in ES
	  assume    es:DGROUP		; Tell the assembler

	  mov	    dx,oldint24.foff	; restore old INT 24
	  mov	    ds,oldint24.fseg	;get old segment
	  assume    ds:nothing		;fix assumes
	  mov	    al,24h
	  calldos   SETINT		;reset vector address

	  mov	    ds,__psp		; Get PSP
	  assume    ds:nothing		; Tell the assembler

	  les	    bx,oldint21 	; Get old handler
	  assume    es:nothing		; Tell the assembler
	  cli				; Nobody move
	  mov	    ds:[INT21PSP_VEC].fOFF,bx ; Chain to old handler
	  mov	    ds:[INT21PSP_VEC].fSEG,es ; Set segment
	  les	    bx,oldint27 	; Get old int 27 handler
	  assume    es:nothing		; Tell the assembler
	  mov	    ds:[INT27PSP_VEC].fOFF,bx ; Set offset
	  mov	    ds:[INT27PSP_VEC].fSEG,es ; and segment
;;;;;;;   les	    bx,oldxmsnxt	; Old XMS entry
;;;;;;;   assume    es:nothing		; Tell the assembler
;;;;;;;   mov	    ds:[XMSPSP_VEC].fOFF,bx ; Set offset
;;;;;;;   mov	    ds:[XMSPSP_VEC].fSEG,es ; and segment
	  sti				; Enable interrupts

	  pop	    ds
	  assume    ds:DGROUP		; Tell the assembler

	  exit
	  assume    ds:nothing,es:nothing


	  ;
	  ; INT23 - Handle ctrl-C / ctrl-Break
	  ;
	  ; On entry:
	  ;	    No requirements
	  ;
	  ; On exit:
	  ;	    All registers unchanged, interrupts on
	  ;
	  ;

	  EVEN				; ensure even boundary to avoid NET3 bug
	  entry     int23,noframe,far,local  ;ctrl-C handler
	  assume    ds:nothing,es:nothing

	  sti				;restore interrupts
	  pushm     ax,ds		;save registers
	  loadds    ax			;set ds to data area using ax
	  assume    ds:DGROUP		; Tell the assembler

	  mov	    brkflag,1		;set flag

	  popm	    ds,ax		;restore registers
	  assume    ds:nothing		; Tell the assembler

	  stc				;abort program on return to dos
	  exit				;all done
	  assume    ds:nothing,es:nothing


	  ;
	  ; SET24 - Set up critical error handler
	  ;
	  ; On entry:
	  ;	    No requirements
	  ;
	  ; On exit:
	  ;	    AX, BX destroyed
	  ;	    All other registers and interrupt state unchanged
	  ;

	  entry     _set24,noframe	;set up entry point, no stack frame
	  assume    ds:DGROUP,es:nothing ; Called from C code

	  mov	    inshell,1		;show we are in BATPROC
	  calldos   VERSION		;get dos version
	  mov	    majorver,al 	;save major version

	  mov	    al,24h		; save old int 24
	  calldos   GETINT		;get interrupt vector
	  assume    es:nothing		; Tell the assembler

	  mov	    oldint24.foff,bx	;save offset
	  mov	    oldint24.fseg,es	;save segment

	  push	    ds			;save ds
	  loadseg   ds,cs,ax		;get interrupt handler segment
	  assume    ds:nothing		; Tell the assembler

	  lea	    dx,int24		;point to interrupt handler
	  mov	    al,24h		;get interrupt number
	  calldos   SETINT		;set interrupt handler address
	  pop	    ds			;restore ds
	  assume    ds:DGROUP		; Tell the assembler

	  exit				;all done, no stack frame
	  assume    ds:nothing,es:nothing; Tell the assembler


	  ;
	  ; INT24 - Critical error handler
	  ;
	  EVEN				; ensure even boundary to avoid NET3 bug
	  entry     int24,noframe,far,local   ;crit error handler
	  assume    ds:nothing,es:nothing

	  sti				;restore interrupts

	  pushm     ds,ax,bx		;save some registers

	  mov	    bx,sp		;copy stack pointer
	  add	    bx,6		;make bx = original stack pointer

	  pushm     cx,dx,si,di,bp,es	;save other registers
	  push	    ax			;save ax for a bit
	  loadds    ax			;set ds to data area using ax
	  assume    ds:DGROUP		; Tell the assembler

	  mov	    int24sp,bx		;save original stack pointer
	  mov	    i24flags,0		;clear flags

	  ;
	  ; Figure out the error code
	  ;
	  and	    di,0FFH		;strip high byte of error number
	  cmp	    majorver,3		;DOS version 3 or later?
	  jae	    getext		;yes, go get extended error
	  cmp	    di,12		;dos 2.x -- check error code
	  jbe	    dos2err		;if it's in range go on
	  mov	    di,12		;weird error code -- get general
					;  failure error number

dos2err:  add	    di,19		;offset to convert 2.x error to
					;  extended error
	  jmp	    short errout	;go handle error

	  ;
	  ; DOS 3 or above -- get extended error
	  ;
getext:   bset	    i24flags,DOS3	;set DOS 3 bit in flags
	  pushm     si,bp,ds		;save registers destroyed by dos call
	  xor	    bx,bx		;need bx=0 for dos get ext error
	  calldos   GETERR		;get extended error code
	  assume    ds:nothing		; Tell the assembler
	  mov	    di,ax		;copy to di
	  popm	    ds,bp,si		;restore registers
	  assume    ds:DGROUP		; Tell the assembler

	  ;
	  ; Output error message
	  ;
errout:   pop	    ax			;get back original ax
	  test	    ah,080H		;test for block dev error (bit 7 = 0)
	  jz	    diskerr		;if so go handle that

	  ;
	  ; Handle character device or FAT error
	  ;
	  mov	    es,bp		;set es = driver header segment
	  assume    es:nothing		; Tell the assembler

	  test	    word ptr es:[si+4],08000H  ;check driver char dev bit
	  jz	    faterr		;not a character device, must be FAT

	  bset	    i24flags,CHARDEV	;set character device flag
	  cmp	    di,21		;device not ready?
	  jne	    getdname		;if some other error go on

	  mov	    di,40		;use "not ready" instead of "drive
					;  not ready" error message

	  ;
	  ; Get device name from driver header; display error message
	  ;
getdname: pushm     di,ds		;save registers
	  cld				;go forward
	  loadseg   es,ds,ax		;destination is in data segment
	  assume    es:DGROUP		; Tell the assembler

	  mov	    ds,bp		;source is device driver header
	  assume    ds:nothing		; Tell the assembler

	  add	    si,10		;point to name field in driver header
	  lea	    di,devname		;point to local storage for name
	  mov	    cx,8		;device name length
	  rep	    movsb		;copy device name
	  popm	    ds,di		;restore registers
	  assume    ds:DGROUP,es:nothing ; Tell the assembler

	  call	    prterr		;print error message
	  lea	    si,deverr		;point to "on device" message
	  call	    prtmsg		;print it
	  jmp	    short doprompt	;go print prompt
	  ;
	  ; Handle FAT error
	  ;
faterr:   mov	    di,41		;FAT error message number
	  ;
	  ; Handle block device errors
	  ;
diskerr:  call	    prterr		;print error message
	  ;
	  ; Get user response to error
	  ;
doprompt: lea	    si,prompt1		;point to first part
	  call	    prtmsg		;display it
	  test	    i24flags,DOS3	;DOS 3?
	  jz	    endpromp		;if not, skip Fail prompt
	  lea	    si,prompt2		;point to Fail prompt
	  call	    prtmsg		;display it

endpromp: lea	    si,prompt3		;point to last part of prompt
	  call	    prtmsg		;display it

getkey:   mov	    ax,0E00h + BELL	;get write char func + beep character
	  xor	    bx,bx		;page 0
	  int	    10h 		;output beep

keyread:  mov	    ah,1		;check keyboard buffer
	  int	    16h 		;any character there?
	  jz	    readchr		;if not go read the real character
	  xor	    ah,ah		;read keyboard service
	  int	    16h 		;read key from buffer
	  jmp	    short keyread	;loop until buffer is empty

readchr:  xor	    ah,ah		;read keyboard service
	  int	    16h 		;read key from buffer
	  mov	    dl,al		;copy to dl (int 10h destroys AL)
	  mov	    ah,0Eh		;get write character function code
	  xor	    bx,bx		;page 0
	  int	    10h 		;output character to display
	  cmp	    dl,97		;is it lower case alpha?
	  jb	    chkretry		;if too small for lower case go on
	  sub	    dl,32		;convert lower case to upper case
	  ;
	  ; Branch depending on response
	  ;
chkretry: cmp	    dl,'R'              ;retry?
	  jne	    chkign		;no, check ignore
	  mov	    al,1		;get retry code
	  jmp	    short bye24 	;all done

chkign:   cmp	    dl,'I'              ;ignore?
	  jne	    chkabort		;no, check abort
	  xor	    al,al		;get ignore code
	  jmp	    short bye24 	;all done

chkabort: cmp	    dl,'A'              ;abort?
	  jne	    chkfail		;no, check fail
	  mov	    bp,int24sp		;get original stack pointer
	  mov	    ax,[bp+26]		;get CS value from original call
	  cmp	    inshell,0		;are we in BATPROC?
	  jne	    shellerr		;if so do not abort
	  mov	    al,2		;not in shell, do int 23 terminate
	  jmp	    short bye24 	;all done

chkfail:  test	    i24flags,DOS3	;DOS 3 or above?
	  jz	    badkey		;if not, Fail not allowed
	  cmp	    dl,'F'              ;fail?
	  je	    dofail		;if so, fail

badkey:   lea	    si,bsmsg		;illegal key pressed -- backspace
					;  over it
	  call	    prtmsg		;do backspace
	  jmp	    short getkey	;go try again

dofail:   mov	    al,3		;get fail code

	  ;
	  ; All done, return to dos (action code is in AL)
	  ;
bye24:	  mov	    savecode,al 	;save return code
	  lea	    si,lfcrlf		;point to final message
	  call	    prtmsg		;display it
	  popm	    es,bp,di,si,dx,cx,bx,ax   ;restore registers
	  mov	    al,savecode 	;get return code
	  pop	    ds			;restore ds
	  iret				;return to dos
	  ;
	  ; Error occurred inside BATPROC -- return with error code
	  ;
shellerr: lea	    si,lfcrlf		;point to final message
	  call	    prtmsg		;display it
	  add	    sp,24		;skip 9 words for registers saved
					;  at start, 3 for CS/IP/flags
					;  from int 24 = 12 words total
	  test	    i24flags,CHARDEV	;set indicators before we lose ds
	  pop	    ax			;restore registers from user's
	  pop	    bx			;  original int 21 call -- note
	  pop	    cx			;  pops do not change flags from
	  pop	    dx			;  test above
	  pop	    si
	  pop	    di
	  pop	    bp
	  pop	    ds
	  pop	    es
	  jz	    notchar		;KLUDGE -- can't do direct return
					;  for character devices
	  mov	    ax,31		;get general failure error code
	  push	    bp			;save bp for a minute
	  mov	    bp,sp		;copy stack pointer
	  or	    bptr [bp+6],1	;set returned carry flag on stack
	  pop	    bp			;restore bp
	  iret				;return to int 21 caller

notchar:  popf				;IP from original INT 21
	  popf				;CS
	  popf				;flags
	  jmp	    _break_handler	;go handle error

int24	  endp


	  ;
	  ; PRTERR - Print error message and prompt
	  ;
	  ; On entry:
	  ;	    DI = error number
	  ;
	  ; On exit:
	  ;	    AX destroyed
	  ;	    All other registers and interrupt state unchanged
	  ;
	  entry     prterr,noframe,,local  ;print error message and prompt

	  pushm     si,ds		;save prompt message address, ds
	  mov	    ax,di		;copy error number
	  call	    errmsga		;get error message address
	  call	    prtmsg		;print error message
	  popm	    ds,si		;get back prompt address, ds
	  exit				;all done


	  ;
	  ; PRTMSG - Print a message using BIOS output
	  ;
	  ; On entry:
	  ;	    DS:SI = address of message length byte (text follows
	  ;		      length byte)
	  ;
	  ; On exit:
	  ;	    AX destroyed
	  ;	    DS:SI = offset of last byte of message + 1
	  ;	    All other registers and interrupt state unchanged
	  ;
	  entry     prtmsg,noframe,,local  ;print a message to screen

	  pushm     bx,cx		;save registers
	  lodsb 			;get first byte
	  mov	    cl,al		;copy for count
	  xor	    ch,ch		;clear high byte

prt_loop: lodsb 			;load a character
	  mov	    ah,0Eh		;get write character function
	  xor	    bx,bx		;page 0
	  int	    10H 		;output the character
	  loop	    prt_loop		;and loop

	  popm	    cx,bx		;restore registers
	  exit				;all done

	  ;
	  ; EXEC -- Execute an external program
	  ;
	  ; If global _loadhigh is set, emulate DOS LH:
	  ; - Save arena link state
	  ; - Save allocation strategy
	  ; - Link arenas
	  ; - Set allocation strategy to first fit high (not high only)
	  ; - Load and execute via 4B00
	  ; - Restore allocation strategy
	  ; - Restore arena link state
	  ;
	  ; On entry:
	  ;	    Arguments on stack using pascal calling convention:
	  ;
	  ;	       char *filename:	    file to execute (full path)
	  ;	       char far *cmdline:   command tail
	  ;	       int envseg:	    environment block segment address
	  ;				      child process, 0 to not pass
	  ;				      these files
	  ;	       int *errnum:	    returned dos error number (only
	  ;				      valid if function returns -1)
	  ;
	  ; On exit:
	  ;	    AX = result code:
	  ;		 0  = program terminated normally
	  ;		 -1 = termination with carry set, couldn't execute,
	  ;		      see dos error number in errnum
	  ;		 -3 = terminated by ctrl-C
	  ;		 >0 = program's returned error code
	  ;	    BX, CX, DX destroyed
	  ;	    All other registers unchanged, interrupts on
	  ;

	  entry     EXEC		;set up exec entry point
	  ;
	  ; Arguments
	  ;
	  argW	    errnum		;pointer to dos error number
	  argW	    envseg		;environment segment address
	  argD	    cmdline		;far pointer to command tail
	  argW	    filename		;pointer to file name
	  ;
	  ; Local variables
	  ;
	  var	    eparms,<size EXECPARM>  ;dos EXEC parameter block
	  var	    fcb1,<size FCB>	;first FCB
	  var	    fcb2,<size FCB>	;second FCB
	  var	    prevlink,2		; Previous arena link state
	  var	    prevstra,2		; Previous allocation strategy
	  varend			;end of variables

	  pushm     si,di		;save registers

	  DOSCALL   @DRESET		; Flush SMARTDRV

	  ;
	  ; Get previous arena link state
	  ;
	  cmp	    _loadhigh,0 	; Is Loadhigh in effect?
	  je	    short EXEC_XLHIGH1	; Jump if not

	  mov	    ax,5802h		; Get UMB link status
	  DOSCALL			; Return status in AL
	  sub	    ah,ah		; Clear high byte
	  mov	    prevlink.foff,ax	; Save for later

	  mov	    ax,5800h		; Get allocation strategy
	  DOSCALL			; Return strategy in AX
	  mov	    prevstra.foff,ax	; Save for later

	  mov	    ax,5803h		; Set UMB link status
	  mov	    bx,1		; Connect low and high DOS
	  DOSCALL			; Ignore return value

	  mov	    ax,5801h		; Set allocation strategy
	  mov	    bx,0080h		; First fit high, then first fit low
	  DOSCALL			; Ignore return value

EXEC_XLHIGH1:
	  ;
	  ; Set up new int 23 (ctrl-C) address, save stack pointers
	  ;
	  mov	    al,23h		;interrupt number
	  calldos   GETINT		;get interrupt vector
	  mov	    oldint23.foff,bx	;save offset
	  mov	    oldint23.fseg,es	;save segment
	  push	    ds			;save ds
	  loadseg   ds,cs,ax		;point ds to code segment
	  mov	    dx,offset int23	;ds:dx points to int23
	  mov	    al,23h		;interrupt number
	  calldos   SETINT		;set new vector address
	  pop	    ds			;restore ds
	  ;
	  ; Set up (most of) exec parameter block, leave tail addr in si,
	  ; fcb segment (= ss) in ax.
	  ;
	  mov	    ax,envseg		;get environment segment
	  mov	    eparms.EXEC_ENV,ax	;store in parameter block
	  mov	    ax,ss		;get fcb segment
	  mov	    eparms.EXEC_F1S,ax	;set fcb1 segment
	  mov	    eparms.EXEC_F2S,ax	;set fcb2 segment
	  les	    si,cmdline		;get command tail segment and offset
	  mov	    eparms.EXEC_TSG,es	;store segment
	  mov	    eparms.EXEC_TOF,si	;store offset
	  ;
	  ; Fill the FCBs by using int 23 function 29h (parse filename)
	  ; If the first FCB parse does not return with DS:SI pointing to
	  ; white space, we have to skip characters until we find some.
	  ;
	  inc	    si			;skip the tail length byte
	  mov	    es,ax		;get fcb segment in es
	  lea	    di,fcb1		;get fcb1 offset
	  mov	    eparms.EXEC_F1O,di	;store in parameter block
	  mov	    al,1		;skip leading separators in parse
	  calldos   PARSE		;parse first file name

FCBScan:  lodsb 			;get a character from tail
	  cmp	    al,' '              ;is it blank?
	  je	    FCBRdy		;if so we're ready
	  cmp	    al,CR		;or <cr>
	  je	    FCBRdy		;if so we're ready
	  cmp	    al,TAB		;or tab?
	  je	    FCBRdy		;if so we're ready
	  jmp	    short FCBScan	;haven't found next white space, loop

FCBRdy:   lea	    di,fcb2		;get fcb2 offset
	  mov	    eparms.EXEC_F2O,di	;store in parameter block
	  mov	    al,1		;skip leading separators in parse
	  calldos   PARSE		;parse second file name
	  ;
	  ; Now call dos to execute the program (es still = ss = parameter
	  ; block segment)
	  ;
ExecGo:
	  push	    es
	  mov	    ax,__psp
	  mov	    es,ax
	  mov	    bx,es:[018h]	; get BATPROC's handles
	  mov	    es,_psp_master	; save STDIN & STDOUT handles in COMMAND.COM
	  mov	    dx,es:[018h]
	  mov	    s_handles,dx
	  mov	    es:[018h],bx
	  pop	    es

	  mov	    ah,050h		; set the PSP to COMMAND.COM
	  mov	    bx,_psp_master
	  int	    21h

	  mov	    brkflag,0		;clear break flag
	  push	    bp			;save bp
	  mov	    ss_save,ss		;then save stack segment
	  mov	    sp_save,sp		;and offset
	  lea	    bx,eparms		;ES:BX = addr of parameter block
	  mov	    dx,filename 	;DS:DX = addr of file name
	  mov	    inshell,0		;show external program running
	  xor	    al,al		;load program, not overlay
	  cld				;DOS 2.x may need this due to a bug
	  calldos   EXEC		;run the program
	  ;
	  ; Restore stack, old int 23, and handle table (maintenance caution
	  ; -- flags must not be changed until after pushf or carry
	  ; indicating error will be lost).
	  ;
	  loadds    bx			;set ds to data area using bx
	  mov	    inshell,1		;show BATPROC running
	  cli				;hold interrupts
	  mov	    ss,ss_save		;restore stack segment
	  mov	    sp,sp_save		;restore stack pointer
	  sti				;restore interrupts
	  pop	    bp			;restore bp
	  pushf 			;save the EXEC returned carry flag
	  push	    ax			;save error code
	  push	    ds			;save ds

	  mov	    es,_psp_master	; restore COMMAND.COM's handles
	  mov	    dx,s_handles
	  mov	    es:[018h],dx

	  mov	    ah,50h		; set the PSP back to BATPROC
	  mov	    bx,__psp
	  int	    21h

	  mov	    dx,oldint23.foff	;get old offset
	  mov	    ds,oldint23.fseg	;get old segment
	  assume    ds:nothing		;fix assumes
	  mov	    al,23h		;interrupt number
	  calldos   SETINT		;reset vector address

GetRes:   pop	    ds			;restore ds
	  assumeds			;fix assumes
	  ;
	  ; If LOADHIGH is in effect, restore previous settings and clear flag
	  ;
	  cmp	    _loadhigh,0 	; Is Loadhigh in effect?
	  je	    short EXEC_XLHIGH2	; Jump if not

	  mov	    _loadhigh,0 	; Clear flag for next time
	  mov	    ax,5801h		; Set allocation strategy
	  mov	    bx,prevstra.foff	; Get previous allocation strategy
	  DOSCALL			; Ignore return code

	  mov	    ax,5803h		; Set UMB link status
	  mov	    bx,prevlink.foff	; Get previous link status
	  DOSCALL			; Ignore return code

EXEC_XLHIGH2:
	  pop	    ax			;restore error code
	  popf				;restore 4Bh return carry flag

	  ; Return result to caller

	  jnc	    execok		;if no carry we're all set
	  mov	    bx,errnum		;point to caller dos error argument
	  mov	    [bx],ax		;store the dos error code
	  mov	    ax,-1		;get error return value
	  jmp	    short execdone	;all done

execok:   calldos   GETRET		;get child process return code
	  cmp	    ah,1		;check for ^C termination
	  je	    userbrk		;if so return ^C code
	  cmp	    brkflag,0		;^C recorded by int 23?
	  je	    nobreak		;if not go on

userbrk:  mov	    ax,-3		;get ^C termination return
	  jmp	    short execdone	;all done

nobreak:  xor	    ah,ah		;clear high byte of return code

execdone: popm	    di,si		;restore registers

	  exit				;that's all folks

_TEXT	  ends				;close segment

	  end

