;' $Header:   P:/PVCS/MAX/QUILIB/MBOOT.ASV   1.1   30 May 1997 12:09:02   BOB  $

	TITLE	MBoot -- MultiBoot detection module
	Name	MBoot
	PAGE	60,132

COMMENT |

Copyright (C) 1992-97 Qualitas, Inc.  GNU General Public License version 3.

Original code by: Henry Groover, October 1992

Our detection of the current multiboot section is a bit convoluted.
If we're loaded as a TSR or via INSTALL=, we need to find the master
PSP (which may not be in low DOS).  We then need to find the first
block which belongs to the master PSP, is not the master PSP's
environment, and which is below the master PSP.  That is the temporary
environment created for the command processor at SHELL= time, and
that is the copy of CONFIG= we can count on not changing.  If we're
running from INSTALL=, this temporary environment will have been
created for us.

|

.8086
.xlist
Include MASM.INC
Include DOSCALL.INC
Include ASCII.INC
Include PTR.INC
Include DEVDRV.INC
Include BIOSDATA.INC
Include XMS.INC
Include MAC.INC
Include EXEC.INC
.list

PGROUP	group	NCODE,NDATA,STACK
PSPGROUP group	PSPSEG

NCODE segment byte public 'PROG'
NCODE ends

NDATA segment byte public 'PROG'
NDATA ends

STACK segment byte stack 'PROG'
STACK ends

PSPSEG segment at 0
assume cs:PSPGROUP,ds:PSPGROUP

	Public	PSP_ENVIR_PTR,PSP_STOR_MAX
Include PSP.INC

PSPSEG ends

NDATA	segment
	assume DS:PGROUP,ES:nothing

	 public  CONFIGSIG
CONFIGSIG db	 'CONFIG='      ; Lead-in for identifier
@CONFIGLEN equ	 $-CONFIGSIG

@ACTIVECONFIGLEN equ 128	; Maximum length for active config
	 public  ACTIVECONFIG,ConfigPtr
ACTIVECONFIG db  @ACTIVECONFIGLEN dup (0)
	 db	 0		; Extra null terminator
ConfigPtr dd	 -1		; -1 indicates it's not initialized

NDATA	ends			; End NDATA segment

NCODE	 segment
	 assume  CS:PGROUP,DS:nothing,es:nothing

	 NPPROC  FIND_CONFIG -- Check for CONFIG= in environment block at ES:0
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Check block with MAC at ES:0.  Make sure it's a valid environment block and
find CONFIG=.

On entry:
ES:0	 ==>	 MAC entry for block

On exit:
ZF=1		 ES:DI ==> CONFIG=
ZF=0		 Not found

|

	 REGSAVE <ax,cx,si>	; Save

; Look for CONFIG=
	 cld			; String ops forwardly
	 mov	 di,10h 	; Skip MAC entry
	 lea	 si,CONFIGSIG	; String to compare against
	 mov	 ax,es:[0].MAC_NPAR ; Get number of paras in segment
	 cmp	 ax,0800h	; Izit greater than 32K?
	 ja	 short FIND_CONFIG_EXIT ; Jump if so (note ZF=0)

	 mov	 cl,4-0 	; Paragraphs to bytes
	 shl	 ax,cl		; AX = bytes in environment
	 mov	 cx,ax		; Put in count register
	 sub	 al,al		; Value to scan for end of string
@@:
	 cmp	 cx,@CONFIGLEN	; Are we at the end?
	 jb	 short FIND_CONFIG_EXIT ; Jump if so (note ZF=0)

	 REGSAVE <cx,si,di>	; Save
	 mov	 cx,@CONFIGLEN	; Bytes to compare
  repe	 cmps	 CONFIGSIG[si],es:[di].LO ; Compare strings
	 REGREST <di,si,cx>	; Restore
	 je	 short FIND_CONFIG_EXIT ; Jump if we found it (note ZF=1)

; Find end of environment string
  repne  scas	 es:[di].LO	; ES:DI ==> next character after trailing null
	 jne	 short FIND_CONFIG_EXIT ; Jump if null not found (?)

	 cmp	 es:[di].LO,al	; Izit end of environment?
	 jne	 short @B	; Jump if not

	 inc	 al		; Ensure ZF=0
FIND_CONFIG_EXIT:
	 REGREST <si,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

FIND_CONFIG endp		; End FIND_CONFIG procedure

	 NPPROC  COPY_ACTIVE -- Copy active CONFIG to local ACTIVECONFIG
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

On entry:
ES:SI ==>	 First character after CONFIG= from environment

|

	 REGSAVE <ax,cx,si,di,ds,es> ; Save

	 lea	 di,ACTIVECONFIG ; Address local copy
	 mov	 cx,@ACTIVECONFIGLEN ; Maximum bytes to copy
	 push	 ds		; PGROUP segment
	 push	 es		; MAC segment
	 pop	 ds		; Address source
	 pop	 es		; Address destination
	 assume  ds:nothing,es:PGROUP ; Tell the assembler

	 cld			; String ops forwardly
@@:
	 lods	 ds:[si].LO	; Get a byte
	 stos	 ACTIVECONFIG[di] ; Save it
	 or	 al,al		; Izit the end?
	 loopnz  @B		; Go around again

	 REGREST <es,ds,di,si,cx,ax> ; Restore
	 assume  ds:PGROUP,es:nothing ; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

COPY_ACTIVE endp		; End COPY_ACTIVE procedure

	 NPPROC  WALK_MAC -- Walk MAC chain for temporary environment
	 assume  ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Search MAC for the temporary environment block.

On entry:
BX:0 ==>	Start of chain
DX		Segment of master PSP
BP		Master environment

On exit:
ZF=1		Entry found
ES:DI ==>	CONFIG=

ZF=0		Not found

|

	 REGSAVE <bx>		; Save

MAC_NEXT:
	 mov	 es,bx		; Address MAC entry
	 assume  es:nothing	; Tell the assembler

	 inc	 bx		; Skip MAC entry
	 cmp	 es:[0].MAC_OWNR,dx ; Izit our boy?
	 jne	 short MAC_LOOP ; Jump if not

	 cmp	 bx,dx		; Izit below the master PSP?
	 jnb	 short MAC_LOOP ; Jump if not

	 cmp	 bx,bp		; Izit the master environment?
	 je	 short MAC_LOOP ; Jump if so

	 call	 FIND_CONFIG	; Check ES:10 for CONFIG=
	 je	 short MAC_EXIT ; Jump if found

MAC_LOOP:
	 add	 bx,es:[0].MAC_NPAR ; Add length of segment
	 cmp	 es:[0].MAC_TYPE,@MAC_MID ; Izit the end?
	 je	 short MAC_NEXT ; Go around again if not
				; Note ZF=0
MAC_EXIT:
	 REGREST <bx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

WALK_MAC endp			; End WALK_MAC procedure

	NPPROC	 MbootActive -- Set active configuration
	assume	 ds:PGROUP,es:nothing,ss:nothing
COMMENT|

Determine which multiboot configuration is active.

On entry:
SI	 Starting segment of high DOS (-1 if none)

On exit:
CF=0	 ACTIVECONFIG contains ASCIIZ string
CF=1	 Multiboot not active

|

	 REGSAVE <ax,bx,cx,dx,si,di,bp,es> ; Save

; Save current high DOS arena link state.  This should work for all
; newer versions of 386MAX and most other memory managers (QEMM, DOS=UMB).
	 mov	 ax,@MACALG*100h + 02h ; 5802: Return link state in AL
	 DOSCALL		; AL==1 if arenas are linked, AL==0 if not
	 cbw			; Extend to word
	 mov	 cx,ax		; Save for later

; We want the real version.  If NETX is active, SETVER may be
; lying to us.
;;;;;;;  DOSCALL @DOSVER	; Return version in AL,AH
	 mov	 ax,3306h	; Get MS-DOS version (DOS 5+ only)
	 sub	 bx,bx		; Clear in case it's not DOS 5
	 DOSCALL		; BH=minor, BL=major, DL=revision #
	 xchg	 bh,bl		; Put in the proper order
	 cmp	 bx,0600h	; Izit DOS 6?
	 jb	 short INIT_TSR_ERR2 ; Jump if not

	 mov	 bx,0001h	; Join arenas
	 mov	 ax,@MACALG*100h + 03h ; Set link state
	 DOSCALL		; 5803: Set link state to BX

	 DOSCALL @GETPS0	; Return PSP in BX

INIT_TSR_PPSP:
	 mov	 es,bx		; Address PSP
	 assume  es:PSPGROUP	; Tell the assembler

	 mov	 ax,PSP_CTRL_PSP ; Get parent's PSP
	 or	 ax,ax		; Izit 0?
	 jz	 short INIT_TSR_INSTALL ; Jump if so

	 cmp	 ax,bx		; Izit the same?
	 je	 short @F	; Jump if so

	 mov	 bx,ax		; Prepare to address parent's PSP
	 jmp	 short INIT_TSR_PPSP ; Go around again

@@:
	 mov	 bp,PSP_ENVIR_PTR ; Get environment from master PSP
	 mov	 dx,bx		; Save master PSP

; We need to walk the MAC chains in high and low DOS until we find a segment
; whose owner == DX, segment < DX, and segment != BP.  Then we need to
; find string CONFIG=.	If all that happens, the ASCIIZ string following
; CONFIG= is our boy...
	 DOSCALL @GETLST	; ES:BX ==> list of lists
	 assume  es:nothing	; Tell the assembler

	 mov	 bx,es:[bx-2].ELO ; Get starting MAC entry
	 call	 WALK_MAC	; Search for temporary environment
	 je	 short INIT_TSR_FOUNDMAC ; Jump if found

	 mov	 bx,si		; Get start of high DOS
	 cmp	 bx,-1		; Does it exist?
	 je	 short INIT_TSR_ERR ; Jump if not

	 call	 WALK_MAC	; Search high DOS
	 je	 short INIT_TSR_FOUNDMAC ; Jump if found

INIT_TSR_INSTALL:
; Must be INSTALL= time.  Get our environment.
	 DOSCALL @GETPS0	; Return current PSP in BX
	 mov	 es,bx		; Address it
	 assume  es:PSPGROUP	; Tell the assembler

	 mov	 ax,PSP_ENVIR_PTR ; Get environment segment
	 or	 ax,ax		; Izit empty?
	 jz	 short INIT_TSR_ERR ; Jump if so

	 dec	 ax		; Back off to MAC segment
	 mov	 es,ax		; Address MAC segment
	 assume  es:nothing	; Tell the assembler

	 call	 FIND_CONFIG	; Check for CONFIG=
	 jne	 short INIT_TSR_ERR ; Jump if not found

INIT_TSR_FOUNDMAC:
	 lea	 si,[di+@CONFIGLEN] ; Get offset of active CONFIG
	 call	 COPY_ACTIVE	; Save a local copy

	 mov	 bx,cx		; Get previous link state
	 mov	 ax,@MACALG*100h + 03h ; Set link state
	 DOSCALL		; 5803: Set link state to BX

	 clc			; Success
	 jmp	 short INIT_TSR_EXIT ; Join common exit

INIT_TSR_ERR:
	 mov	 bx,cx		; Get previous link state
	 mov	 ax,@MACALG*100h + 03h ; Set link state
	 DOSCALL		; 5803: Set link state to BX
INIT_TSR_ERR2:
	 stc			; Indicate failure
INIT_TSR_EXIT:
	 REGREST <es,bp,di,si,dx,cx,bx,ax> ; Restore
	 assume  es:nothing	; Tell the assembler

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

MbootActive	 endp		; End MbootActive procedure

	 FPPROC  CURRENTMBOOT -- Return current multiboot configuration
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

If multiboot is present and active, return pointer to ACTIVECONFIG in
DX:AX.	Otherwise, return NULL.  Note that we're called with PASCAL
arguments.

On stack at entry:
starting segment of high DOS

On exit:
DX:AX ==> ACTIVECONFIG if MultiConfig active
DX:AX	 NULL if not

|

CMBARG_STR struc

	 dw	 ?		; Saved BP
	 dd	 ?		; Caller's CS:IP
CMBARG_STARTHIGH dw ?		; Starting segment of high DOS

CMBARG_STR ends

	 push	 bp		; Prepare to address stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <si,ds>	; Save

	 mov	 ax,seg PGROUP	; Prepare to address PGROUP
	 mov	 ds,ax		; Address it
	 assume  ds:PGROUP	; Tell the assembler

	 mov	 dx,ConfigPtr.VSEG ; Get segment
	 and	 dx,ConfigPtr.VOFF ; Combine with offset
	 cmp	 dx,-1		; Has it been initialized?
	 jne	 short CM_EXIT	; Jump if so

	 mov	 ConfigPtr.VSEG,0 ; Assume failure
	 mov	 ConfigPtr.VOFF,0

	 mov	 si,[bp].CMBARG_STARTHIGH ; Get start of high DOS arena
	 call	 MbootActive	; Is Multiboot active?
	 jc	 short CM_EXIT	; Jump if not

	 mov	 ConfigPtr.VOFF,offset PGROUP:ACTIVECONFIG ; Save offset for later
	 mov	 ConfigPtr.VSEG,seg PGROUP ; Segment of string
CM_EXIT:
	 mov	 dx,ConfigPtr.VSEG ; Segment of return value
	 mov	 ax,ConfigPtr.VOFF ; Offset

	 REGREST <ds,si>	; Restore
	 assume  ds:nothing	; Tell the assembler

	 pop	 bp		; Restore

	 ret	 2		; Return to caller, popping argument

	 assume  ds:nothing,es:nothing,ss:nothing

CURRENTMBOOT endp		; End CURRENTMBOOT procedure

NCODE	 ends			; End NCODE segment

	 MEND			; End module MBOOT
