;' $Header:   P:/PVCS/MAX/QMT/MEM_SYS.ASV   1.0   05 Sep 1995 16:55:32   HENRY  $
	 title	 MEM_SYS -- MEMCHK System Identification Routines
	 page	 58,122
	 name	 MEM_SYS

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-98 Qualitas, Inc.

Segmentation:  See MEM_SEGS.INC for details.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|
.386p
.xlist
	 include MASM.INC
	 include DOS.INC
	 include 386.INC
	 include PTR.INC
	 include A20.INC
	 include CPUID.INC
	 include BIOSCONF.INC
	 include ROMSEG.INC
	 include INTVEC.INC
	 include MAXDEV.INC
	 include BITFLAGS.INC
	 include VDS.INC
	 include 8255.INC

	include MEM_SEGS.INC
	 include MEM_TIME.INC
.list

CGROUP	 group	 CPUID_SEG


DATAZ	 segment use16 para public 'dataz' ; Start DATAZ segment
	 assume  ds:DGROUP

	 extrn	 MAX_FLAG:dword

DATAZ	 ends			; End DATAZ segment


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:DGROUP

	 extrn	 CMD_FLAG:word
	 include MEM_CMD.INC

	 extrn	 GL2_FLAG:word
	 include MEM_GL2.INC

	 extrn	 PHYSIZE:dword

	 extrn	 A20SUP:word
	 extrn	 CPUTYPE:byte

	 public  XDDS
XDDS	 XDDS_STR <>		; Extended DDS structure
@XDDS_NREGS equ  32		; # regions we support
	 dd	 (2*@XDDS_NREGS-1) dup (?) ; There's one dword already in XDDS_STR

	 public  GLB_FLAG
	 include MEM_GLB.INC
GLB_FLAG dw	 0		; Global flags

	 public  GL3_FLAG
	 include MEM_GL3.INC
GL3_FLAG dw	 0		; Global flags

	 public  SYS_FLAG
	 include MEM_SYS.INC
SYS_FLAG dw	 0		; System identifier flags

	 public  ASTMIO,CPQMIO
ASTMIO	 dd	 80F00000h	; Special AST memory-mapped I/O address
CPQMIO	 dd	 80C00000h	; Special COMPAQ memory-mapped I/O address

	 public  TOP_GDT,TOP_MIO
TOP_GDT  MDTE_STR <>		; Move DTEs for top MIO ROM disabling
TOP_MIO  dw	 ?		; Top memory-mapped I/O port value

; SHDTAB contains a summary of shadow RAM usage allowing for
; discontiguous physical addresses.

	 public  SHDSIZE,SHDCNT,SHDIND,SHDTAB,@SHDTAB_LEN
	 include MEM_SHD.INC
SHDSIZE  dd	 0		; Amount of extra RAM in bytes
SHDCNT	 dw	 0		; # entries in SHDTAB
SHDIND	 dw	 DGROUP:SHDTAB	; Offset of next available entry in SHDTAB
@SHDTAB_LEN equ  128		; Maximum # entries in SHDTAB
SHDTAB	 SHD_STR @SHDTAB_LEN dup (<>) ; Shadow RAM structure

; In case we run out of physical memory when doing a DPMI Phys-to-lin,
; we need to back off to the original state which we save in the
; following table.  We need only enough entries to hold the initial state.

	 public  XSHDCNT,XSHDIND,XSHDTAB,@XSHDTAB_LEN
XSHDCNT  dw	 0		; # entries in XSHDTAB
XSHDIND  dw	 DGROUP:XSHDTAB ; Offset of next available entry in XSHDTAB
@XSHDTAB_LEN equ 128		; Maximum # entries in XSHDTAB
XSHDTAB  SHD_STR @XSHDTAB_LEN dup (<>) ; Initial shadow RAM structure


;;; ; SCRBTAB contains a summary of scrubbable RAM usage allowing for
;;; ; discontiguous physical addresses.
;;;
;;;	     public  SCRBCNT,SCRBIND,SCRBTAB
;;; SCRBCNT  dw      0		    ; # entries in structure
;;; SCRBIND  dw      DGROUP:SCRBTAB ; Offset of next available entry
;;; @SCRBTAB_LEN equ 16 	    ; Maximum # entries in SCRBTAB
;;; SCRBTAB  SCRB_STR @SCRBTAB_LEN dup (<>) ; Scrub RAM structure
;;;
;;;	     public  AT386_R09,AT386_R0D,AT386_R0E,AT386_R0F
;;; AT386_R09 db     ?,?	    ; C&T CHIPSet registers
;;; AT386_R0D db     ?,?
;;; AT386_R0E db     ?,?
;;; AT386_R0F db     ?,?
;;;
	 public  MACHID
MACHID	 db	 ?		; Machine identifier

	 public  MSG_TOSHSIGN
MSG_TOSHSIGN db  'T5100'
MSG_TOSHSIGN_LEN equ $-MSG_TOSHSIGN

	 public  MSG_QUADCOPY
MSG_QUADCOPY db  'Quadram Quad386XT',0
MSG_QUADCOPY_LEN equ $-MSG_QUADCOPY

	 public  MSG_ASTCOPY
MSG_ASTCOPY db	 'COPYRIGHT AST RESEARCH'
MSG_ASTCOPY_LEN equ $-MSG_ASTCOPY

	 public  LCL_OLISIGN
LCL_OLISIGN db	 'COPYRIGHT (C) OLIVETTI'
OLISIGN_LEN equ  $-LCL_OLISIGN	; Length of signature

	 public  LCL_ITTSIGN
LCL_ITTSIGN db	 '(C) COPYRIGHT XTRA BUSINESS SYSTEMS'
ITTSIGN_LEN equ  $-LCL_ITTSIGN	; Length of signature

	 public  LCL_EISASIGN
LCL_EISASIGN db  'EISA'
LCL_EISASIGN_LEN equ $-LCL_EISASIGN ; Length of signature

	 public  LCL_PHOENIXSIGN
LCL_PHOENIXSIGN db 'Phoenix Technologies Ltd' ; Tandy (GRiD) Phoenix BIOS signature
LCL_PHOENIXSIGN_LEN equ $-LCL_PHOENIXSIGN

	 public  LCL_TANDYSIGN
LCL_TANDYSIGN db 'Tandy' ; Tandy BIOS signature
LCL_TANDYSIGN_LEN equ $-LCL_TANDYSIGN

	 public  LCL_ALCSIGN
LCL_ALCSIGN db	 '(C) COPYRIGHT ALCATEL'
ALCSIGN_LEN equ  $-LCL_ALCSIGN	; Length of signature

	 public  LCL_CACHCTL1
LCL_CACHCTL1 db  0E6h,0ECh	; out EC,al	INTEL L2 Cache system
	 db	  86h,0E0h	; xchg ah,al
	 db	 0E6h,0EDh	; out ED,al
	 db	  86h,0E0h	; xchg ah,al
LCL_CACHCTL1_LEN equ  $-LCL_CACHCTL1 ; Length of signature

CACHCTL_STR struc

CACHCTL_OFF dw	 ?		; Offset in DGROUP of signature
CACHCTL_LEN dw	 ?		; Length of above signature

CACHCTL_STR ends

	 public  PCACHCTL
PCACHCTL CACHCTL_STR <DGROUP:LCL_CACHCTL1,LCL_CACHCTL1_LEN>
PCACHCTL_LEN equ ($-PCACHCTL)/(type CACHCTL_STR) ; # table entries

DATA	 ends			; End DATA segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:PGROUP

	 extrn	 ACTA20_COMSUB:word
	 extrn	 DEFOUT:byte
	 extrn	 MD_FLAG:dword

	 extrn	 A20COM_I92:near
	 extrn	 A20COM_XT:near
	 extrn	 A20COM_QUD:near

	 extrn	 CHECK_I92:near
	 extrn	 CHECK_I78:near
;;;;;;;; extrn	 READ_82C302:near
	 extrn	 DATASEG:word
	 extrn	 FCN_NOXRAM:near
	 extrn	 FCN_SHADOWRAM:near
	 extrn	 PPI_S2C:near
	 extrn	 PPI_S2K:near
	 extrn	 PPI_S2C_K2S:near
	 extrn	 PPI_S2K_K2S:near
	 extrn	 WAITOBUF_CLR:near

	 NPPROC  CHECK_SYS -- Check for Various Systems
	 assume  ds:DGROUP,es:DGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Check for PS/2-compatible machines.

|

	 REGSAVE <ax,bx,cx,dx,di,es,fs> ; Save registers

	 mov	 ax,seg PGROUP	; Get segment of PGROUP
	 mov	 fs,ax		; Address it
	 assume  fs:PGROUP	; Tell the assembler about it

; Check for ROM at E000 or E800

	 push	 0E000h 	; Get segment to check
	 pop	 es		; Address it
	 assume  es:ROMSEG	; Tell the assembler about it

	 cmp	 es:[0000h].ROMSIGN,@ROMSIGN ; Check for the signature at E000:0
	 je	 short CHECK_SYS_E000 ; Jump if present

	 cmp	 es:[8000h].ROMSIGN,@ROMSIGN ; Check for the signature at E800:0
	 jne	 short @F	; Jump if not present

	 or	 GLB_FLAG,@GLB_E800 ; Mark as present

	 jmp	 short @F	; Join common code

CHECK_SYS_E000:
	 or	 GLB_FLAG,@GLB_E000 ; Mark as present
@@:
	 push	 seg CPUID_SEG	; Get ROM BIOS segment
	 pop	 es		; Address via segment register
	 assume  es:CGROUP	; Tell the assembler about it

	 mov	 al,BIOSCPUID	; Get the machine ID byte
	 mov	 MACHID,al	; Save for later use

; Check for VLSI 82C480 L2 cache controllers

	 call	 CHECK_VLSI	; Check on 'em

; Check for EISA signature at F000:FFD9

; Some early EISA machines don't follow the spec, they put their
; signature somewhere else in the BIOS.  However, We can't search
; through the entire BIOS, because many ISA machines have EISA
; strings that we would pick up as false positives.

	 cmp	 dword ptr EISASIGN,'ASIE' ; Check for EISA signature
	 jne	 short @F	; Jump if not EISA machine

	 or	 SYS_FLAG,@SYS_EISA ; Mark as EISA system
@@:

; If we're entering PM via DPMI or VCPI, there's no need to
; get A20 gating information.  Moreover, the test for I/O port 92h
; can cause some systems to reboot.

	 test	 GL2_FLAG,@GL2_DPMI or @GL2_VCPI ; Is there a DPMI/VCPI host?
	 jnz	 short CHECK_SYS_NOA20 ; Jump if so

; Moreover, if there's an XMS driver present, we'll use that to gate A20

	 test	 GLB_FLAG,@GLB_XMS ; Is there an XMS driver present?
	 jnz	 short CHECK_SYS_NOA20 ; Jump if so

; Check on using I/O port 92h for toggling A20

	 mov	 ax,@A20_SUP	; A20 function, Query A20 gate support
	 int	 15h		; Request BIOS service

	 cmp	 ah,0		; Did it succeed?
	 jne	 short @F	; Jump if not

	 mov	 A20SUP,bx	; Save for later use
	 or	 GL3_FLAG,@GL3_A20FN ; Mark as services present

	 test	 bx,mask $A20_I92 ; Duzit use I/O port 92h to toggle A20?
	 jz	 short @F	; Jump if not

	 bts	 GL3_FLAG,$GL3_A20SET ; Izit already set?
	 jc	 short @F	; Jump if so

	 mov	 ACTA20_COMSUB,offset PGROUP:A20COM_I92 ; Save routine addr
@@:

; If this BIOS doesn't support A20 Architecture functions,
; check for I/O port 78h or 92h gating of A20

	 test	 GL3_FLAG,@GL3_A20FN ; Are A20 Architecture services present?
	 jnz	 short @F	; Jump if so

	 call	 CHECK_I78	; Check for I/O port 78h toggle of A20
	 call	 CHECK_I92	; Check for I/O port 92h A20 gating
@@:

; Get the undefined bits from the default Output Port byte
; unless we've already found an A20 gating method
; First, clear any pending scan code from the output buffer

	 test	 GL3_FLAG,mask $GL3_A20SET ; Izit already set?
	 jnz	 short CHECK_SYS_NODEFOUT ; Jump if so

	 pushf			; Save for a moment
	 cli			; Ensure no keyboard activity

	 call	 WAITOBUF_CLR	; Wait for the output buffer to clear

	 mov	 ah,@S2C_ROUT	; Read output port byte command
	 call	 PPI_S2C_K2S	; Send AH to 8042, return with AL = response
	 jc	 short @F	; Jump if error

	 call	 WAITOBUF_CLR	; Wait for the output buffer to clear

	 test	 al,mask $S2O_RESET ; If Reset not set, it's probably invalid
	 jz	 short @F	; Jump if not valid

	 and	 al,mask $S2O_UNDEF ; Isolate undefined bits
	 and	 DEFOUT,not (mask $S2O_UNDEF) ; Clear undefined bits
	 or	 DEFOUT,al	; Save for later use
@@:
	 popf			; Restore
CHECK_SYS_NODEFOUT:
CHECK_SYS_NOA20:

; Check for PS/2-compatible machines

	 mov	 ah,0C0h	; Attempt to read configuration record
	 stc			; Assume failure
	 int	 15h		; Request BIOS service
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short CHECK_SYS_XPS2 ; Jump if error

	 cmp	 ah,80h 	; Check for error return
	 je	 short CHECK_SYS_XPS2 ; Jump if error

	 cmp	 ah,86h 	; Check for error return
	 je	 short CHECK_SYS_XPS2 ; Jump if error

	 test	 es:[bx].CFG_PARMS,@CFG_MCA ; Izit a Micro Channel Architecture?
	 jz	 short CHECK_SYS_XPS2 ; Not this time

; Disable the watchdog timer to avoid false NMIs

	 mov	 ax,0C300h	; Function to disable watchdog timer
	 int	 15h		; Request BIOS service

	 or	 MAX_FLAG,@MD_MCA ; Mark as a PS/2-compatible machine
	 or	 MD_FLAG,@MD_MCA ; ...

	 test	 GL2_FLAG,@GL2_DPMI or @GL2_VCPI ; Is there a DPMI/VCPI host?
	 jnz	 near ptr CHECK_SYS_EXIT ; Jump if so

	 bts	 GL3_FLAG,$GL3_A20SET ; Izit already set?
	 jc	 short @F	; Jump if so

	 mov	 ACTA20_COMSUB,offset PGROUP:A20COM_I92 ; Save routine addr
@@:
	 test	 GL3_FLAG,@GL3_A20FN ; A20 services present?
	 jnz	 short @F	; Jump if so

	 mov	 A20SUP,mask $A20_I92 ; Mark as A20 support value
@@:
	 jmp	 short CHECK_SYS_EXIT ; Join common exit code

	 assume  es:nothing	; Tell the assembler about it

CHECK_SYS_XPS2:
	 mov	 al,MACHID	; Restore machine ID

	 cmp	 al,@CPU_PC	; Check for PC
	 je	 short CHECK_SYS_PCXT ; Jump if present

	 cmp	 al,@CPU_XT	; Check for XT
	 je	 short CHECK_SYS_PCXT ; Jump if present

	 cmp	 al,@CPU_XT2	; Check for XT2
	 je	 short CHECK_SYS_PCXT ; Jump if present

	 cmp	 al,@CPU_M30	; Check for PS/2 Model 30
	 je	 short CHECK_SYS_PCXT ; Jump if present

	 cmp	 al,@CPU_CNV	; Check for Convertible
	 je	 short CHECK_SYS_PCXT ; Jump if present

	 cmp	 al,@CPU_JR	; Check for Jr
	 je	 short CHECK_SYS_PCXT ; Jump if present

; Check for individual systems

	 call	 CHECK_TOSH	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYS_EXIT ; We found it, so just exit

	 call	 CHECK_QUAD386	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYS_EXIT ; We found it, so just exit

	 call	 CHECK_AST386	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYS_EXIT ; We found it, so just exit

	 call	 CHECK_HPRS	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYS_EXIT ; We found it, so just exit

	 call	 CHECK_GRID	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYS_EXIT ; We found it, so just exit

	 call	 CHECK_OLI	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYS_EXIT ; We found it, so just exit

	 call	 CHECK_CPQ386	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYS_EXIT ; We found it, so just exit

	 call	 CHECK_ITT	; Return with CF=0 if we found it, =1 otherwise
	 jnc	 short CHECK_SYS_EXIT ; We found it, so just exit

; None of the above

	 jmp	 short CHECK_SYS_EXIT ; Join common code

CHECK_SYS_PCXT:
	 or	 MAX_FLAG,@MD_XT ; Mark as PC/XT present
	 or	 MD_FLAG,@MD_XT ; ...

	 bts	 GL3_FLAG,$GL3_A20SET ; Izit already set?
	 jc	 short @F	; Jump if so

	 mov	 ACTA20_COMSUB,offset PGROUP:A20COM_XT ; Save routine addr
@@:
CHECK_SYS_EXIT:
;;;;;;;; call	 CMD_SHADOW	; Handle SHADOWRAM if specified
	 call	 CMD_TOP384	; Handle TOP384    if specified

	 REGREST <fs,es,di,dx,cx,bx,ax> ; Restore
	 assume  es:DGROUP,fs:nothing ; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_SYS endp			; End CHECK_SYS procedure
	 NPPROC  CHECK_VLSI -- Check For VLSI 82C480 Cache Controller
	 assume  ds:DGROUP,es:nothing,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Check for VSLI 82C480 cache controller

|

	 REGSAVE <cx,si,di>	; Save registers

	 cmp	 CPUTYPE,04h	; Izit 486 or later?
	 jb	 short CHECK_VLSI_EXIT ; Jump if not

	 xor	 si,si		; Initialize index into table
	 mov	 cx,PCACHCTL_LEN ; Get # table entries
CHECK_VLSI_NEXT:
	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 PCACHCTL[si].CACHCTL_OFF ; Get offset of source string
	 push	 PCACHCTL[si].CACHCTL_LEN ; ... length ...
	 call	 SRCHSTR	; Search for the string
	 jnc	 short CHECK_VLSI_FOUND ; Jump if found
				; Return with DI = offset of match in ROM
	 add	 si,size CACHCTL_STR ; Skip to next entry

	 loop	 CHECK_VLSI_NEXT ; Jump if more table entries

	 jmp	 short CHECK_VLSI_EXIT ; Join common exit code

CHECK_VLSI_FOUND:
	 or	 GL3_FLAG,@GL3_VLSI ; Mark as present
CHECK_VLSI_EXIT:
	 REGREST <di,si,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_VLSI endp 		; End CHECK_VLSI procedure
	 NPPROC  CHECK_TOSH -- Check for Toshiba 5100 Signature
	 assume  ds:DGROUP,es:nothing,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of Toshiba 5100 signature.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 pusha			; Save all GP registers

	 REGSAVE <es>		; Save segment register

	 push	 seg CPUID_SEG	; Get ROM BIOS segment
	 pop	 es		; Address via segment register
	 assume  es:CGROUP	; Tell the assembler about it

	 lea	 si,MSG_TOSHSIGN ; DS:SI ==> Toshiba 5100 signature
	 lea	 di,TOSHSIGN	; ES:DI ==> same if Toshiba 5100 machine
	 mov	 cx,MSG_TOSHSIGN_LEN ; CX = length of ...
    repe cmps	 MSG_TOSHSIGN[si],CGROUP:[di].LO ; Compare 'em
	 jne	 short CHECK_TOSH_XPRES ; Jump if no match

	 or	 SYS_FLAG,@SYS_TOSH ; Mark as Toshiba 5100 machine

	 clc			; Indicate we found it

	 jmp	 short CHECK_TOSH_EXIT ; Join common exit code

CHECK_TOSH_XPRES:
	 stc			; Indicate not Toshiba 5100 machine
CHECK_TOSH_EXIT:
	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_TOSH endp 		; End CHECK_TOSH procedure
	 NPPROC  CHECK_QUAD386 -- Check for Quadram 386XT Signature
	 assume  ds:DGROUP,es:nothing,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of Quadram 386XT signature.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 pusha			; Save all GP registers

	 REGSAVE <es>		; Save segment register

	 mov	 ah,0C0h	; Code to get BIOS configuration data
	 int	 15h		; Request BIOS service
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short CHECK_QUAD386_XPRES ; Not Quadram 386XT machine

	 cmp	 ah,0		; Ensure AH=00 on return
	 jne	 short CHECK_QUAD386_XPRES ; Not Quadram 386XT machine

	 cmp	 es:[bx].CFG_LEN,26 ; Ensure minimum length
	 jb	 short CHECK_QUAD386_XPRES ; Not Quadram 386XT machine

	 cmp	 es:[bx].CFG_MODEL,@CPU_XT ; Ensure correct model byte
	 jne	 short CHECK_QUAD386_XPRES ; Not Quadram 386XT machine

	 cmp	 es:[bx].CFG_TYPE,0A6h ; Ensure correct type byte
	 jne	 short CHECK_QUAD386_XPRES ; Not Quadram 386XT machine

	 lea	 si,MSG_QUADCOPY ; DS:SI ==> Quadram 386XT signature
	 lea	 di,[bx+10]	; ES:DI ==> same if Quadram 386XT machine
	 mov	 cx,MSG_QUADCOPY_LEN ; CX = length of ...
    repe cmps	 MSG_QUADCOPY[si],es:[di].LO ; Compare 'em
	 jne	 short CHECK_QUAD386_XPRES ; Jump if not found

	 or	 SYS_FLAG,@SYS_QUAD386 ; Mark as Quadram 386XT machine
	 or	 MAX_FLAG,@MD_XT ; Mark as XT as well
	 or	 MD_FLAG,@MD_XT ; ...

	 bts	 GL3_FLAG,$GL3_A20SET ; Izit already set?
	 jc	 short @F	; Jump if so

	 mov	 ACTA20_COMSUB,offset PGROUP:A20COM_QUD ; Save routine addr
@@:
	 clc			; Indicate we found it

	 jmp	 short CHECK_QUAD386_EXIT ; Join common exit code

CHECK_QUAD386_XPRES:
	 stc			; Indicate not Quadram 386XT machine
CHECK_QUAD386_EXIT:
	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_QUAD386 endp		; End CHECK_QUAD386 procedure
	 NPPROC  CHECK_AST386 -- Check for AST Premium/386
	 assume  ds:DGROUP,es:nothing,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of AST Premium/386

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 pusha			; Save all GP registers

	 REGSAVE <es>		; Save for a moment

	 mov	 ah,0C0h	; Code to get BIOS configuration data
	 stc			; Assume failure
	 int	 15h		; Request BIOS service
	 assume  es:nothing	; Tell the assembler about it
	 jc	 near ptr CHECK_AST386_XPRES ; Not AST 386 machine

	 cmp	 ah,0		; Ensure AH=00 on return
	 jne	 near ptr CHECK_AST386_XPRES ; Not AST 386 machine

AST_STR  struc

AST_ID	 db	 ?		; Machine ID
AST_COPR db	 22 dup (?)	; Copyright message

AST_STR  ends

; Equates for AST_ID

@AST_PREM20  equ 01h		; Premium /20
@AST_CUPID25 equ 08h		;	  /25
@AST_WALLST  equ 09h		;	   SX
@AST_PREM16  equ 0Bh		;	  /16
@AST_CUPID33 equ 0Dh		;	  /33

	 lea	 si,MSG_ASTCOPY ; DS:SI ==> AST copyright notice
	 add	 bx,es:[bx]	; Get length of configuration data
	 add	 bx,2		; Skip over word length
	 lea	 di,[bx].AST_COPR ; ES:DI ==> same if AST machine
	 mov	 cx,MSG_ASTCOPY_LEN ; CX = length of ...
    repe cmps	 MSG_ASTCOPY[si],es:[di].LO ; Compare 'em
	 jne	 near ptr CHECK_AST386_XPRES ; Jump if not found

	 or	 SYS_FLAG,@SYS_AST386 ; Mark as AST Premium/386

	 cmp	 es:[bx].AST_ID,@AST_PREM16 ; Izit Premium/16?
	 je	 short CHECK_AST386_MEM ; Yes, recover memory

	 cmp	 es:[bx].AST_ID,@AST_PREM20 ; Izit Premium/20?
	 je	 short CHECK_AST386_MEM ; Yes, recover memory

;;;;;;;; cmp	 es:[bx].AST_ID,@AST_WALLST ; Izit Premium/SX?
;;;;;;;; je	 short CHECK_AST386_COM ; Yes, no shadow RAM to recover
;;;;;;;;
;;;;;;;; cmp	 es:[bx].AST_ID,@AST_CPUID25 ; Izit Premium/25?
;;;;;;;; je	 short CHECK_AST386_COM ; Yes, no shadow RAM to recover
;;;;;;;;
;;;;;;;; cmp	 es:[bx].AST_ID,@AST_CPUID33 ; Izit Premium/33?
;;;;;;;; je	 short CHECK_AST386_COM ; Yes, no shadow RAM to recover

	 jmp	 short CHECK_AST386_COM ; Skip extra RAM recovery

CHECK_AST386_MEM:

; If there is more than 16MB-384KB of RAM installed, skip extra RAM recovery

	 cmp	 PHYSIZE,16*1024-384 ; Check it
	 ja	 short CHECK_AST386_COM ; Skip extra RAM recovery

	 test	 CMD_FLAG,@CMD_X384 ; Skip shadow RAM fill?
	 jnz	 short CHECK_AST386_COM ; Yes

	 push	 @TT_P2L	; Pass flags (needs P2L later)
	 PUSHD	 -1		; Pass handle (-1=none)
	 push	 dword ptr (256*1024) ; Amount of shadow RAM in bytes
	 push	 dword ptr 00FA0000h ; ...at this physical location
	 push	 dword ptr 00FA0000h ; ...	  linear ...
	 call	 SAVE_XSHADOW	; Append to shadow RAM structures

	 test	 GLB_FLAG,@GLB_E000 ; Is there a ROM at E000?
	 jnz	 short CHECK_AST386_COM ; Yes, don't touch the EGA ROM

	 call	 DISABLE_EGAROM ; Disable it
	 jc	 short CHECK_AST386_COM ; ROM not disabled

; Tell the system to decode the upper 128KB as high-only RAM

	 mov	 TOP_MIO,@AST_HRAM ; Mark as read-write, high-only
	 lea	 si,ASTMIO	; DS:SI ==> 32-bit destination address

	 int	 12h		; Return # KB of base memory in AX

	 cmp	 ax,512 	; Only 512KB of base memory?
	 je	 short @F	; Yes

	 or	 TOP_MIO,@ASTMIO_N512*0101h ; Mark as not 512KB system
@@:
	 call	 TOP_WRITE	; Write value in TOP_MIO to I/O port

; Add in the 128KB gained from disabling the ROM mapping

	 push	 @TT_P2L	; Pass flags (needs P2L later)
	 PUSHD	 -1		; Pass handle (-1=none)
	 push	 dword ptr (128*1024) ; Amount of shadow RAM in bytes
	 push	 dword ptr 00FE0000h ; ...at this physical location
	 push	 dword ptr 00FE0000h ; ...	  linear ...
	 call	 SAVE_XSHADOW	; Append to shadow RAM structures
CHECK_AST386_COM:
	 clc			; Indicate we found it

	 jmp	 short CHECK_AST386_EXIT ; Join common exit code

CHECK_AST386_XPRES:
	 stc			; Indicate not AST machine
CHECK_AST386_EXIT:
	 REGREST <es>		; Restore
	 assume  es:nothing	; Tell the assembler about it

	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_AST386 endp		; End CHECK_AST386 procedure
	 NPPROC  CHECK_HPRS -- Check for HP Vectra RS/16 or /20
	 assume  ds:DGROUP,es:nothing,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of HP Vectra RS/16 or /20.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 REGSAVE <ax,es>	; Save registers

	 push	 seg CPUID_SEG	; Get ROM BIOS segment
	 pop	 es		; Address via segment register
	 assume  es:CGROUP	; Tell the assembler about it

	 cmp	 HPSIGN.ELO,'PH' ; Ensure correct signature
	 jne	 short CHECK_HPRS_XPRES ; Jump if not found

	 or	 SYS_FLAG,@SYS_HPRS ; Mark as HP Vectra RS/16 or /20
	 mov	 al,HPTYPE	; Get the system type

; Skip shadow RAM fill on HP systems other than
; RS/16, RS/20, QS/16, QS/20, RS/20C, RS/25C, and QS/16S

	 cmp	 al,@HPRS16	; Izit an RS/16?
	 je	 short CHECK_HPRS_FILL ; Yes

	 cmp	 al,@HPRS20	; Izit an RS/20?
	 je	 short CHECK_HPRS_FILL ; Yes

	 cmp	 al,@HPQS16	; Izit an QS/16?
	 je	 short CHECK_HPRS_FILL ; Yes

	 cmp	 al,@HPQS20	; Izit an QS/20?
	 je	 short CHECK_HPRS_FILL ; Yes

	 cmp	 al,@HPRS20C	; Izit an RS/20C?
	 je	 short CHECK_HPRS_FILL ; Yes

	 cmp	 al,@HPRS25C	; Izit an RS/25C?
	 je	 short CHECK_HPRS_FILL ; Yes

	 cmp	 al,@HPQS16S	; Izit an QS/16S?
	 je	 short CHECK_HPRS_FILL ; Yes

	 or	 CMD_FLAG,@CMD_X384 ; Skip shadow RAM fill
CHECK_HPRS_FILL:
	 test	 CMD_FLAG,@CMD_X384 ; Skip shadow RAM fill?
	 jnz	 short @F	; Yes

	 push	 es		; Save for a moment

	 push	 seg DGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 call	 FCN_SHADOWRAM	; Mark as using SHADOWRAM

	 pop	 es		; Restore
	 assume  es:CGROUP	; Tell the assembler about it
@@:
	 clc			; Indicate we found it

	 jmp	 short CHECK_HPRS_EXIT ; Join common exit code

CHECK_HPRS_XPRES:
	 stc			; Indicate neither HPRS not SHADOWRAM system
CHECK_HPRS_EXIT:
	 REGREST <es,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_HPRS endp 		; End CHECK_HPRS procedure
	 NPPROC  CHECK_GRID -- Check for GRiD Systems 1500 or Later
	 assume  ds:DGROUP,es:nothing,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of GRiD Systems 1500 (Laptop) or later, or the line
of desktop machines made by Tandy for GRiD.

Desktop machines are identified by having a Phoenix copyright and:
  Classic bus machines have the byte 'C0' at F000:80A1 and
   an INT 15h model of @CPU_AT ...
  MCA bus machines have an INT 15h model of @CPU_MCA (notice no 'C0' byte) ...

and one of the following submodel codes:

81h	Tandy 4000, also Grid 1530 Laptop
82h	Tandy 4000LX aka GRiD 386is
03h	Tandy 4000SX aka GRiD 386isx
01h	Tandy 4016SX aka GRiD 386sx-MFP
01h	Tandy 5000   aka GRiD 386mc

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

@CFG_GRID_386IS2 equ 82h	; Grid 386is-XX (older version)
@CFG_GRID_1530	 equ 81h	; Grid 1530 Laptop (&Tandy 4000)
@CFG_GRID_386ISX equ 03h	; Grid 386isx
@CFG_GRID_386IS  equ 01h	; Grid 386 is-XX (newer version)
@CFG_GRID_MC	 equ 01h	; Grid 5000 (Micro channel)

	 pusha			; Save all GP registers
	 push	 es		; Save register

	 push	 seg CPUID_SEG	; Get ROM BIOS segment
	 pop	 es		; Address via segment register
	 assume  es:CGROUP	; Tell the assembler about it

	 cmp	 GRIDDASH.ELO,'--' ; Ensure correct signature
	 jne	 short CHECK_GRID_DESKTOPS ; Jump if not found

;;;;;;;; cmp	 GRIDSIGN.ELO,'RG' ; Ensure correct signature
;;;;;;;; jne	 short CHECK_GRID_XPRES ; Jump if not found
;;;;;;;;
;;;;;;;; cmp	 GRIDSIGN.EHI,'Di' ; Ensure correct signature
;;;;;;;; jne	 short CHECK_GRID_XPRES ; Jump if not found

	 mov	 ax,0E421h	; Get current color map
	 mov	 dl,0FFh	; Function code
	 int	 15h		; Request BIOS service
	 jc	 near ptr CHECK_GRID_XPRES ; Jump if not supported

	 cmp	 ah,00h 	; Check for valid return code
	 jne	 near ptr CHECK_GRID_XPRES ; Jump if not supported

; Check for 1450sx laptop

	 cmp	 GRIDMODEL,@GRIDLYNX.LO ; Izit a 1450sx?
	 jne	 short CHECK_GRID_X1450 ; If not, search for next ID

COMMENT |

If we are on a GRID 1450sx laptop,
we can't recover shadow RAM if any of these three modes are enabled.
	Standby mode
	Automatic standby mode
	Low power standby mode

|

;Check for Standby mode enabled

	 mov	ax, 0E489h	; Get/Set standby mode
	 mov	dl, 0FFh	; Get current state of standby mode
	 int	15h		; Request BIOS service
	 jc	short CHECK_GRID_STANDBY_OK ; Jump if standby mode not supported

	 cmp	ah,0		; AH should be 0
	 jne	short CHECK_GRID_NOXRAM ; Jump if error

	 cmp	dl,0		; Is standby mode disabled?
	 jne	short CHECK_GRID_NOXRAM ; If not, don't recover XRAM

CHECK_GRID_STANDBY_OK:

; Check for Auto standby mode enabled

	 mov	ax,0E48Ah	; Get/Set automatic standby mode
	 mov	dl,0FFh 	; Get state of auto standby mode
	 int	15h		; Request BIOS service
	 jc	short CHECK_GRID_AUTOSB_OK ;jump if auto standby mode not supported

	 cmp	ah,0		; AH should be 0
	 jne	short CHECK_GRID_NOXRAM ; Jump if error

	 cmp	dl,0		; Is auto standby mode disabled?
	 jne	short CHECK_GRID_NOXRAM ; If not, don't recover XRAM

CHECK_GRID_AUTOSB_OK:

; Check for Low Power Standby Mode enabled

	 mov	ax,0E48Bh	; Get/Set low power standby mode
	 mov	dl,0FFh 	; Get state of low power standby mode
	 int	15h		; Request BIOS service
	 jc	short CHECK_GRID_LOWBATT_OK ; Jump if low power standby not supported

	 cmp	ah,0		; AH should be 0
	 jne	short CHECK_GRID_NOXRAM ; Jump if error

	 cmp	dl,0		; Is low power standby mode disabled?
	 jne	short CHECK_GRID_NOXRAM ; If not, don't recover XRAM

CHECK_GRID_LOWBATT_OK:
	 jmp	 CHECK_GRID_CLC ; Proceed as normal

; Check for future laptops here

CHECK_GRID_X1450:
	 jmp	 CHECK_GRID_CLC ; Proceed as normal

CHECK_GRID_NOXRAM:
	 push	 es		; Save for a moment

	 push	 seg DGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 call	 FCN_NOXRAM	; Mark as NOXRAM

	 pop	 es		; Restore
	 assume  es:CGROUP	; Tell the assembler about it

	 jmp	short CHECK_GRID_CLC ; Proceed as normal

CHECK_GRID_DESKTOPS:

; Look for Phoenix signature

	 lea	 si,LCL_PHOENIXSIGN ; FS:SI ==> Tandy signature
	 lea	 di,PHOENIXSIGN     ; ES:DI ==> same if Tandy machine
	 mov	 cx,LCL_PHOENIXSIGN_LEN ; CX = length of ...
    repe cmps	 LCL_PHOENIXSIGN[si],PHOENIXSIGN[di] ; Compare 'em
	 jne	 short CHECK_GRID_XPRES ; Jump if no match

;;;;;;;; mov	 cl,GRIDSIGN2	; Save contents for later use

;Check to see if there is BIOS support
	 mov	 ah,0C0h	; Code to get BIOS configuration data
	 stc			; Assume failure
	 int	 15h		; Request BIOS service
	 assume  es:nothing	; Tell the assembler about it
	 jc	 short CHECK_GRID_XPRES ; Not Tandy desktop (4000 series)

	 cmp	 ah,0		; Ensure AH=00 on return
	 jne	 short CHECK_GRID_XPRES ; Not Tandy desktop (4000 series)

; Check for MCA first then AT compatible ID byte

	 test	 es:[bx].CFG_PARMS,@CFG_MCA ; Izit an MCA?
	 jnz	 short CHECK_GRID_MCA ; Jump if so

	 cmp	 es:[bx].CFG_MODEL,@CPU_AT ; Ensure correct model byte
	 jne	 short CHECK_GRID_XPRES ; Not Tandy desktop (4000 series)

; Check for AT compatible signature
;;;;;;;;
;;;;;;;; cmp	 cl,@GRIDSIGN2	; Ensure correct signature
;;;;;;;; jne	 short CHECK_GRID_XPRES ; Jump if not found

	 push	 seg CGROUP	; Setup ES for BIOS References
	 pop	 es		; Address it
	 assume  es:CGROUP	; Tell the assembler about it

; Search for the TANDY string in F000:0 to FFFF

	 push	 dword ptr 0F0000000h ; Get starting offset of BIOS
	 push	 0		; Length of search area (64KB)
	 push	 offset DGROUP:LCL_TANDYSIGN ; Get offset of source string
	 push	 LCL_TANDYSIGN_LEN ; Get length of ...
	 call	 SRCHSTR	; Search for the string
	 jc	 short CHECK_GRID_XPRES ; Jump if not found
				; Return with DI = offset of match in ROM

; Check for System type byte (sub-model type)

;;;;;;;; cmp	 es:[bx].CFG_TYPE,@CFG_GRID_386IS2 ; Ensure correct type byte
;;;;;;;; je	 short CHECK_GRID_DESKTOP ; Found older Grid 386is
;;;;;;;;
;;;;;;;; cmp	 es:[bx].CFG_TYPE,@CFG_GRID_386ISX ; Ensure correct type byte
;;;;;;;; je	 short CHECK_GRID_DESKTOP ; Found Grid 386isx
;;;;;;;;
;;;;;;;; cmp	 es:[bx].CFG_TYPE,@CFG_GRID_386IS ; Ensure correct type byte
;;;;;;;; jne	 short CHECK_GRID_XPRES ; Not newer Grid 386is (or any other)

CHECK_GRID_DESKTOP:
	 test	 CMD_FLAG,@CMD_X384 ; Is NOXRAM specified?
	 jnz	 short CHECK_GRID_CLC	  ; Yes, don't use it

	 push	 es		; Save for a moment

	 push	 seg DGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 call	 FCN_SHADOWRAM	; Mark as using SHADOWRAM

	 pop	 es		; Restore
	 assume  es:CGROUP	; Tell the assembler about it

	 jmp	 short CHECK_GRID_CLC ; Join common code

; It's an MCA with Tandy signature match

CHECK_GRID_MCA:
	 cmp	 es:[bx].CFG_TYPE,@CFG_GRID_MC ; Ensure correct type byte
	 jne	 short CHECK_GRID_XPRES ; Jump if not Tandy 5000
CHECK_GRID_CLC:
	 or	 SYS_FLAG,@SYS_GRID ; Mark as GRiD Systems 1500 or later
				; and desktops including MCA machines
				; and 1450SX laptop
	 clc			; Indicate we found it

	 jmp	 short CHECK_GRID_EXIT ; Join common exit code

CHECK_GRID_XPRES:
	 stc			; Indicate not GRiD machine
CHECK_GRID_EXIT:
	 pop	 es		; Restore
	 assume  es:nothing	; Tell the assembler about it
	 popa			; Restore all GP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_GRID endp 		; End CHECK_GRID procedure
	 NPPROC  CHECK_OLI -- Check for AT&T/Olivetti Signature
	 assume  ds:DGROUP,es:nothing,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of AT&T/Olivetti.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 REGSAVE <eax,cx,si,di,es> ; Save registers

	 push	 seg CPUID_SEG	; Get ROM BIOS segment
	 pop	 es		; Address via segment register
	 assume  es:CGROUP	; Tell the assembler about it

	 lea	 di,OLISIGN	; ES:DI ==> place where signature shoudl be
	 lea	 si,LCL_OLISIGN ; DS:SI ==> local copy of it
	 mov	 cx,OLISIGN_LEN ; # bytes in signature
    repe cmps	 LCL_OLISIGN[si],CGROUP:[di].LO ; Compare 'em
	 jne	 near ptr CHECK_OLI_XPRES ; Jump if no match

	 or	 SYS_FLAG,@SYS_OLI ; Mark as Olivetti/AT&T system

	 test	 CMD_FLAG,@CMD_X384 ; Skip shadow RAM fill?
	 jnz	 near ptr CHECK_OLI_CLC ; Yes

; Check for MCA which has no built-in RAM at 800A0000h

	 test	 MAX_FLAG,@MD_MCA ; Izit PS/2-compatible?
	 jnz	 near ptr CHECK_OLI_CLC ; Yes, don't recover any RAM

; Check for Olivetti M300 -- this machine has no built-in RAM
; so don't attempt to recover it

	 cmp	 OLIALTID,@OLI_M300 ; Izit an M300?
	 je	 near ptr CHECK_OLI_CLC ; Jump if so

; Check for Olivetti M305/M310 -- this machine has no built-in RAM
; so don't attempt to recover it

	 cmp	 OLIALTID,@OLI_M305 ; Izit an M305/M310?
	 je	 near ptr CHECK_OLI_CLC ; Jump if so

; Check for Olivetti M386/25 (XP2) -- this machine has no built-in RAM
; so don't attempt to recover it

	 cmp	 OLIALTID,@OLI_XP2 ; Izit an M386/25 (XP2)?
	 je	 near ptr CHECK_OLI_CLC ; Jump if so

; Check for Olivetti M386/20? (XP1/3/5) -- this machine has built-in RAM
; Check for AT&T WGS 6386 (Olivetti XP1)

	 cmp	 OLIALTID,@OLI_XP5 ; Izit an M386/20? (XP1/3/5)?
	 je	 near ptr CHECK_OLI_RAM ; Jump if so

; Check for Olivetti M386/25 (XP4/7/9) -- this machine has built-in RAM

	 cmp	 OLIALTID,@OLI_XP9 ; Izit an M386/25 (XP4/7/9)?
	 je	 near ptr CHECK_OLI_RAM ; Jump if so

; Check for Olivetti M316 -- this machine has C&T shadow RAM

	 cmp	 OLIALTID,@OLI_M316 ; Izit an M316?
	 je	 near ptr CHECK_OLI_SHD ; Jump if so to recover shadow RAM

	 jmp	 short CHECK_OLI_CLC ; Otherwise, no RAM recovery

CHECK_OLI_SHD:
	 push	 es		; Save for a moment

	 push	 seg DGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 call	 FCN_SHADOWRAM	; Mark as using SHADOWRAM

	 pop	 es		; Restore
	 assume  es:CGROUP	; Tell the assembler about it

	 jmp	 short CHECK_OLI_CLC ; Join common code


; Recover built-in RAM at 800A000h

CHECK_OLI_RAM:

; Check for ROM at E000 or E800.
; If not present, recover all 384KB.
; If present, and the vectors point to the ROM, re-vector them,
;   and recover all 384KB.
; Otherwise, recover the lower 256KB only.

	 mov	 eax,256*1024	; Amount of RAM in KB to recover

	 test	 GLB_FLAG,@GLB_E000 ; Check for the signature at E000:0
	 jnz	 short CHECK_OLI_SAVE ; Jump if present

	 test	 GLB_FLAG,@GLB_E800 ; ...and at E800:0
	 jnz	 short CHECK_OLI_SAVE ; Jump if present

	 call	 OLI_RESET	; Disable the system's use of built-in RAM
	 jc	 short CHECK_OLI_SAVE ; Jump if something went wrong

	 mov	 eax,384*1024	; Amount of RAM in KB to recover

; Recover AX KB of shadow RAM at 2GB+640KB

CHECK_OLI_SAVE:
	 push	 @TT_P2L	; Pass flags (needs P2L later)
	 PUSHD	 -1		; Pass handle (-1=none)
	 push	 eax		; Amount of shadow RAM in bytes
	 push	 dword ptr 800A0000h ; ...at this physical location
	 push	 dword ptr 800A0000h ; ...	  linear ...
	 call	 SAVE_XSHADOW	; Append to shadow RAM structures
CHECK_OLI_CLC:
	 clc			; Indicate we found it

	 jmp	 short CHECK_OLI_EXIT ; Join common exit code

CHECK_OLI_XPRES:
	 stc			; Indicate not AT&T/Olivetti machine
CHECK_OLI_EXIT:
	 REGREST <es,di,si,cx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_OLI endp			; End CHECK_OLI procedure
	 NPPROC  CHECK_CPQ386 -- Check For COMPAQ Deskpro 386
	 assume  ds:DGROUP,es:nothing,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of COMPAQ Deskpro 386

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 REGSAVE <eax,ecx,si,es> ; Save registers

	 push	 seg CPUID_SEG	; Get ROM BIOS segment
	 pop	 es		; Address via segment register
	 assume  es:CGROUP	; Tell the assembler about it

	 cmp	 VENDOR.EDD[0],'PMOC' ; Check for 'COMPAQ'
	 jne	 near ptr CHECK_CPQ386_ERR ; Not this time

	 cmp	 VENDOR.ELO[4],'QA' ; Check for 'COMPAQ'
	 jne	 near ptr CHECK_CPQ386_ERR ; Not this time

	 cmp	 BIOS_TYPE.ELO,'60' ; Check for COMPAQ 686 product
	 je	 short CHECK_CPQ386_OK ; Good guess

	 cmp	 BIOS_TYPE.ELO,'50' ; Check for COMPAQ 586 product
	 je	 short CHECK_CPQ386_OK ; Good guess

	 cmp	 BIOS_TYPE.ELO,'40' ; Check for COMPAQ 486 product
	 je	 short CHECK_CPQ386_OK ; Good guess

	 cmp	 BIOS_TYPE.ELO,'30' ; Check for COMPAQ 386 product
	 jne	 near ptr CHECK_CPQ386_ERR ; Not this time
CHECK_CPQ386_OK:
	 or	 SYS_FLAG,@SYS_CPQ ; Mark as COMPAQ Deskpro 386
	 and	 CMD_FLAG,not @CMD_TOP ; Remove TOP384 if specified

; If there is more than 16MB-384KB of RAM installed, skip extra RAM recovery

	 cmp	 PHYSIZE,16*1024-384 ; Check it
	 ja	 near ptr CHECK_CPQ386_CLC ; Skip extra RAM recovery

	 test	 CMD_FLAG,@CMD_X384 ; Skip shadow RAM fill?
	 jnz	 short CHECK_CPQ386_CLC ; Yes

	 mov	 si,OFFCPQSTR	; ES:SI ==> CPQSTR

; Determine if the 80C00000 I/O port scheme to recover shadow memory
; exists.  Newer COMPAQs remap their extra memory to the top of extended
; memory instead of this scheme.  If this is true, CPQSTR_FLAG will
; contain FFFF, and there will be no extra memory to recover.

; Note: Some Micronics systems put "COMPAQ" in the vendor ID field,
; but don't implement the 80C00000 protocol.  However, we no longer can
; use the 80C00000 scheme in our COMPAQ detection scheme since the newer
; COMPAQs do not support 80C00000.

	 cmp	 CGROUP:[si].CPQSTR_FLAG,0FFFFh ; Check the presence flag
	 je	 short CHECK_CPQ386_CLC ; No extra memory available

	 cmp	 CGROUP:[si].CPQSTR_TOT,4000h ; Ensure reasonable
	 ja	 short CHECK_CPQ386_ERR ; It's not, skip all this

	 cmp	 CGROUP:[si].CPQSTR_AVL,4000h ; Ensure reasonable
	 ja	 short CHECK_CPQ386_ERR ; It's not, skip all this

	 cmp	 CGROUP:[si].CPQSTR_LOW,0A000h ; Ensure reasonable
	 jb	 short CHECK_CPQ386_ERR ; It's not, skip all this

	 movzx	 eax,CGROUP:[si].CPQSTR_LOW ; Get low address in paras
	 movzx	 ecx,CGROUP:[si].CPQSTR_AVL ; Get size of available region in paras
	 jcxz	 CHECK_CPQ386_CLC ; Jump if no BIM to recover

	 sub	 eax,ecx	; Less size to get starting address in paras
	 shl	 eax,4-0	; Convert from paras to bytes
	 shl	 ecx,4-0	; Convert from paras to bytes
	 add	 eax,15*1024*1024 ; Plus 15MB to get physical address

	 push	 @TT_P2L	; Pass flags (needs P2L later)
	 PUSHD	 -1		; Pass handle (-1=none)
	 push	 ecx		; Amount of shadow RAM in bytes
	 push	 eax		; ...at this physical location
	 push	 eax		; ...	     linear ...
	 call	 SAVE_XSHADOW	; Append to shadow RAM structures
CHECK_CPQ386_CLC:
	 clc			; Indicate we found it

	 jmp	 short CHECK_CPQ386_EXIT ; Join common exit code

CHECK_CPQ386_ERR:
	 stc			; Indicate we didn't find it
CHECK_CPQ386_EXIT:
	 REGREST <es,si,ecx,eax> ; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_CPQ386 endp		; End CHECK_CPQ386 procedure
	 NPPROC  CHECK_ITT -- Check for ITT XTRA
	 assume  ds:DGROUP,es:nothing,fs:PGROUP,gs:nothing,ss:nothing
COMMENT|

Check on presence of ITT XTRA.

On exit:

CF	 =	 0 if found
	 =	 1 if not

|

	 REGSAVE <cx,si,di,es>	; Save registers

	 push	 seg CPUID_SEG	; Get ROM BIOS segment
	 pop	 es		; Address via segment register
	 assume  es:CGROUP	; Tell the assembler about it

	 lea	 di,ITTSIGN	; ES:DI ==> place where signature shoudl be
	 lea	 si,LCL_ITTSIGN ; DS:SI ==> local copy of it
	 mov	 cx,ITTSIGN_LEN ; # bytes in signature
    repe cmps	 LCL_ITTSIGN[si],CGROUP:[di].LO ; Compare 'em
	 je	 short CHECK_ITT_PRES ; Jump if it's a match

	 lea	 di,ITTSIGN	; ES:DI ==> place where signature should be
	 lea	 si,LCL_ALCSIGN ; FS:SI ==> local copy of it
	 mov	 cx,ALCSIGN_LEN ; # bytes in signature
    repe cmps	 LCL_ALCSIGN[si],CGROUP:[di].LO ; Compare 'em
	 jne	 short CHECK_ITT_XPRES ; Jump if no match
CHECK_ITT_PRES:
	 or	 SYS_FLAG,@SYS_ITT ; Mark as ITT XTRA/Alcatel

	 test	 CMD_FLAG,@CMD_X384 ; Skip shadow RAM fill?
	 jnz	 short @F	; Yes

	 push	 es		; Save for a moment

	 push	 seg DGROUP	; Setup ES for data references
	 pop	 es		; Address it
	 assume  es:DGROUP	; Tell the assembler about it

	 call	 FCN_SHADOWRAM	; Mark as using SHADOWRAM

	 pop	 es		; Restore
	 assume  es:CGROUP	; Tell the assembler about it
@@:
	 clc			; Indicate we found it

	 jmp	 short CHECK_ITT_EXIT ; Join common exit code

CHECK_ITT_XPRES:
	 stc			; Indicate not ITT machine
CHECK_ITT_EXIT:
	 REGREST <es,di,si,cx>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_ITT endp			; End CHECK_ITT procedure
;;;	     NPPROC  CMD_SHADOW -- SHADOWRAM Command
;;;	     assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; If SHADOWRAM specified, save it.
;;;
;;; |
;;;
;;;	     test    CMD_FLAG,@CMD_SHD ; Izit a SHADOWRAM system?
;;;	     jz      short CMD_SHADOW_EXIT ; Not this time
;;;
;;;	     call    INIT_AT386     ; Initialize AT/386 registers
;;;
;;; ; Add in shadow RAM from C000 to F000
;;;
;;;	     push    @TT_P2L	    ; Pass flags (needs P2L later)
;;;	     PUSHD   -1 	    ; Pass handle (-1=none)
;;;	     push    dword ptr (192*1024) ; Amount of shadow RAM in bytes
;;;	     push    dword ptr 000C0000h ; ...at this physical location
;;;	     push    dword ptr 000C0000h ; ...	      linear ...
;;;	     call    SAVE_XSHADOW   ; Append to shadow RAM structures
;;;
;;;	     push    dword ptr (192*1024) ; Amount of scrub RAM in bytes
;;;	     push    dword ptr 000C0000h ; ...at this location
;;;	     call    SAVE_SCRUB     ; Append to scrub RAM structure
;;; CMD_SHADOW_EXIT:
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; CMD_SHADOW endp		    ; End CMD_SHADOW procedure
	 NPPROC  CMD_TOP384 -- TOP384 Command
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

If TOP384 specified, save it.

|

	 REGSAVE <si>		; Save register

	 test	 CMD_FLAG,@CMD_TOP ; Izit generic top 384KB of RAM?
	 jz	 short CMD_TOP384_EXIT ; Not this time

	 push	 @TT_P2L	; Pass flags (needs P2L later)
	 PUSHD	 -1		; Pass handle (-1=none)
	 push	 dword ptr (256*1024) ; Amount of shadow RAM in bytes
	 push	 dword ptr 00FA0000h ; ...at this physical location
	 push	 dword ptr 00FA0000h ; ...	  linear ...
	 call	 SAVE_XSHADOW	; Append to shadow RAM structures

; Disable ROM remapping

	 call	 DISABLE_EGAROM ; Disable it
	 jc	 short CMD_TOP384_EXIT ; ROM not disabled

; Tell the system to decode the upper 128KB as high-only RAM

	 mov	 TOP_MIO,@CPQ_HRAM ; Mark as read-write, high-only
	 lea	 si,CPQMIO	; DS:SI ==> 32-bit destination address
	 call	 TOP_WRITE	; Write value in TOP_MIO to I/O port

; Add in the 128KB gained from disabling the ROM mapping

	 push	 @TT_P2L	; Pass flags (needs P2L later)
	 PUSHD	 -1		; Pass handle (-1=none)
	 push	 dword ptr (128*1024) ; Amount of shadow RAM in bytes
	 push	 dword ptr 00FE0000h ; ...at this physical location
	 push	 dword ptr 00FE0000h ; ...	  linear ...
	 call	 SAVE_XSHADOW	; Append to shadow RAM structures
CMD_TOP384_EXIT:
	 REGREST <si>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CMD_TOP384 endp 		; End CMD_TOP384 procedure
	 NPPROC  SAVE_SHADOW -- Append to Shadow RAM Structure
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save shadow RAM information in structure.

If @TT_L2P is set and there's a VDS server present,
translate the incoming linear address range into one
or more physical address ranges.

If running under Netroom, we can't translate more than 128K at a time
due to a bug in their implementation of VDS.  This means we need to
perform on-the-fly merging of physically contiguous and similar ranges,
since our tables won't hold 2GB/128K==16384 entries.

|

SAVE_SHADOW_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
SAVE_SHADOW_LBASE dd ?		; Linear base address
SAVE_SHADOW_PBASE dd ?		; Physical ...
SAVE_SHADOW_SIZE dd ?		; Size in bytes
SAVE_SHADOW_HNDL dd ?		; Handle (-1=none)
SAVE_SHADOW_FLAG dw ?		; Flags (see @TT_xxx for equates)

SAVE_SHADOW_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,ebx,ecx,dx,si,edi> ; Save registers

; See if there's translation to be done

	 test	 [bp].SAVE_SHADOW_FLAG,@TT_L2P ; Need translation?
	 jz	 near ptr SAVE_SHADOW_NOTRANS ; Jump if not

	 mov	 dx,[bp].SAVE_SHADOW_FLAG ; Save flags on entry
	 and	 [bp].SAVE_SHADOW_FLAG,not @TT_L2P ; Clear it for later use

	 test	 GLB_FLAG,@GLB_VDS ; VDS server present?
	 jz	 near ptr SAVE_SHADOW_NOTRANS ; Jump if not

	 mov	 eax,[bp].SAVE_SHADOW_SIZE ; Get size of block in bytes
;;;;;;;; mov	 ecx,20000h	; Netroom can't handle more than 128K

	 mov	 edi,[bp].SAVE_SHADOW_LBASE ; Starting linear address
	 mov	 ebx,[bp].SAVE_SHADOW_PBASE ; Starting physical address

; Break it up into 128K pieces so Netroom doesn't have a cow.
@@:
;;;;;;;; cmp	 eax,ecx	; Izit above the limit?
;;;;;;;; jbe	 short SAVE_SHADOW_AGAIN0 ; Jump if not
;;;;;;;;
;;;;;;;; push	 dx		; Pass flags
;;;;;;;; push	 [bp].SAVE_SHADOW_HNDL ; ... handle
;;;;;;;; push	 ecx		; Part of the size
;;;;;;;; push	 ebx		; Physical base address
;;;;;;;; push	 edi		; Linear base address
;;;;;;;; call	 SAVE_SHADOW	; Call ourselves with a size we can handle
;;;;;;;;
;;;;;;;; add	 edi,ecx	; Skip to next address
;;;;;;;; add	 ebx,ecx	; ...	       physical address
;;;;;;;; sub	 eax,ecx	; Adjust size remaining
;;;;;;;; jnz	 short @B	; Go around again if not finished
;;;;;;;;
;;;;;;;; jmp	 SAVE_SHADOW_EXIT ; Nothing left to do...
;;;;;;;;
;;;SAVE_SHADOW_AGAIN0:
;;;;;;;; mov	 [bp].SAVE_SHADOW_SIZE,eax ; Save remainder
;;;;;;;; mov	 [bp].SAVE_SHADOW_LBASE,edi ; Save updated linear base address
;;;;;;;; mov	 [bp].SAVE_SHADOW_PBASE,ebx ; ...	   physical ...
SAVE_SHADOW_AGAIN:
	 mov	 XDDS.XDDS_SIZE,eax ; Save in struc

	 mov	 XDDS.XDDS_FVEC.FOFF,edi ; Save base linear address in struc
	 mov	 XDDS.XDDS_FVEC.FSEL,0 ; ...

	 mov	 XDDS.XDDS_AVL,@XDDS_NREGS ; Save # available regions

; Since the DPMI hosts for QEMM and Netroom are unbundled, they don't
; properly handle VDS calls.  Worse than not handling them at all, they
; don't even fail the call.  We need to check for an unchanged structure...
	 mov	 XDDS.XDDS_DATA.RDDS_ADDR,-1 ; Bogus base address
	 mov	 XDDS.XDDS_DATA.RDDS_SIZE,0 ; Bogus size

	 lea	 edi,XDDS	; ES:EDI ==> XDDS struc
	 xor	 dx,dx		; No flags
	 VDSCALL @VDS_SLOCK	; Scatter/gather lock the region
	 jnc	 short SAVE_SHADOW_TRANS ; Jump if successful

	 cmp	 al,@VDSERR_PTEOVF ; Is our struc too small?
	 jne	 near ptr SAVE_SHADOW_ERRTRANS ; Jump if not
SAVE_SHADOW_OVF:

; If the region size field has changed (i.e. is smaller than the
; original size), then we can assume that it describes the maximum
; length in bytes that can be locked with this XDDS struc.

	 mov	 edi,[bp].SAVE_SHADOW_SIZE ; Get size of block in bytes
	 mov	 eax,XDDS.XDDS_SIZE ; Get the region size

	 cmp	 eax,edi	; Is the region size smaller?
	 jb	 short SAVE_SHADOW_XACCUM ; Jump if so

; Because Windows doesn't fill in the region size field with the
; actual size this region covers, we must count on the data fields
; being filled in correctly up to the point of overflow and use the
; sum of their lengths to determine the maximum length in bytes that
; can be locked with this XDDS struc.

	 mov	 cx,XDDS.XDDS_AVL ; Get # entries available
	 xor	 eax,eax	; Clear the byte accumulator
	 xor	 si,si		; Initialize index into XDDS
@@:
	 add	 eax,XDDS.XDDS_DATA[si].RDDS_SIZE ; Plus next region's size
				; in bytes
	 add	 si,size RDDS_STR ; Skip to next entry

	 loop	 @B		; Jump if more entries to accumulate

	 cmp	 eax,edi	; Is the region size still smaller?
	 jnb	 near ptr SAVE_SHADOW_ERRTRANS ; Jump if there's no hope
SAVE_SHADOW_XACCUM:
	 and	 eax,eax	; Izit a silly value?
	 jz	 near ptr SAVE_SHADOW_ERRTRANS ; Jump if there's no hope

; Recurse using a smaller region size

	 mov	 cx,[bp].SAVE_SHADOW_FLAG ; Get flags
	 or	 cx,@TT_L2P	; Mark as translation needed
	 push	 cx		; Pass flags
	 push	 [bp].SAVE_SHADOW_HNDL ; Pass handle
	 mov	 [bp].SAVE_SHADOW_HNDL,-1 ; Invalidate the handle for next time
	 push	 eax		; Pass length in bytes
	 PUSHD	 0		; Pass filler for physical address (not used)
	 push	 [bp].SAVE_SHADOW_LBASE ; Pass linear address
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

	 sub	 [bp].SAVE_SHADOW_SIZE,eax ; Subtract from previous size
	 jbe	 near ptr SAVE_SHADOW_EXIT ; Jump if it's all over

	 add	 [bp].SAVE_SHADOW_LBASE,eax ; Skip to next linear address

	 jmp	 SAVE_SHADOW_AGAIN ; Go around again

SAVE_SHADOW_TRANS:
	 xor	 si,si		; Initialize index into XDDS
	 mov	 cx,XDDS.XDDS_USED ; Get # entries used
	 jcxz	 SAVE_SHADOW_EXIT0 ; Jump if none (???)

; The VDS services under Windows may return with USE > AVL without
; carry set.  This is their subtle way of telling us that the call
; failed.

	 cmp	 cx,XDDS.XDDS_AVL ; Izit more than was available?
	 ja	 short SAVE_SHADOW_OVF ; Jump if so

	 mov	 edi,[bp].SAVE_SHADOW_LBASE ; Get the initial linear address

; Check for DPMI hosts which no longer handle VDS after entering protected mode.
	 cmp	 XDDS.XDDS_DATA.RDDS_ADDR,-1 ; Izit a bogus physical address?
	 jne	 short SAVE_SHADOW_NEXTREG ; Jump if not

	 cmp	 XDDS.XDDS_DATA.RDDS_SIZE,0 ; Izit a bogus size?
	 jne	 short SAVE_SHADOW_NEXTREG ; Jump if not

; For some reason, we didn't catch this when we retested for VDS services
; upon entry to protected mode during DPMI.
	 and	 GLB_FLAG,not @GLB_VDS ; No VDS services present
	 jmp	 short SAVE_SHADOW_NOTRANS ; Join common code

SAVE_SHADOW_NEXTREG:
	 mov	 eax,XDDS.XDDS_DATA[si].RDDS_SIZE ; Get size in bytes

	push	[bp].SAVE_SHADOW_FLAG ; Pass flags
	 push	 [bp].SAVE_SHADOW_HNDL ; Pass handle
	 mov	 [bp].SAVE_SHADOW_HNDL,-1 ; Invalidate the handle for next time
	 push	 eax		; Pass length in bytes
	 push	 XDDS.XDDS_DATA[si].RDDS_ADDR ; Pass physical address
	 push	 edi		; Pass linear address
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

	 add	 edi,eax	; Skip to the next linear address

	 add	 si,size RDDS_STR ; Skip to next entry

	 loop	 SAVE_SHADOW_NEXTREG ; Jump if more regions to process

; Since Netroom can't handle locking of multiple DMA regions, we need to
; unlock them now.
	 lea	 edi,XDDS	; ES:EDI ==> XDDS struc
	 xor	 dx,dx		; No flags
	 VDSCALL @VDS_SUNLK	; Scatter/gather unlock the region
;;;;;;;  jc	 ???		; Ignore error

SAVE_SHADOW_EXIT0:
	 jmp	 SAVE_SHADOW_EXIT ; Join common exit code

SAVE_SHADOW_ERRTRANS:
	 or	 [bp].SAVE_SHADOW_FLAG,@TT_UNALL ; Mark as unallocated
SAVE_SHADOW_NOTRANS:

; See if we can merge this entry with the previous one

	 cmp	 SHDCNT,0	; Any previous entries?
	 je	 near ptr SAVE_SHADOW1 ; Not this time

; Loop through all previous entries to see if this one can be
; merged with any one of them as a following block.

	 mov	 cx,SHDCNT	; Get # current entries
	 xor	 si,si		; Initialize index into SHDTAB
SAVE_SHADOW_NEXTSHD1:

; If the current entry is unallocated and the incoming one isn't
; or vice versa, we can't merge.

	 mov	 ax,SHDTAB[si].SHD_FLAG ; Get the current entry's flags
	 xor	 ax,[bp].SAVE_SHADOW_FLAG ; Merge with the incoming entry's flags

	 test	 ax,@TT_UNALL	; Is there a mismatch?
	 jnz	 short SAVE_SHADOW_LOOPSHD1 ; Yes, so we can't merge

	 mov	 eax,SHDTAB[si].SHD_ESIZE ; Get previous size in bytes
	 add	 eax,SHDTAB[si].SHD_PBASE ; Add in previous physical base
				; to get next physical base
	 cmp	 eax,[bp].SAVE_SHADOW_PBASE ; Same as new physical base?
	 jne	 short SAVE_SHADOW_LOOPSHD1 ; No, so there's a discontiguity

	 mov	 eax,SHDTAB[si].SHD_ESIZE ; Get previous size in bytes
	 add	 eax,SHDTAB[si].SHD_LBASE ; Add in previous linear base
				; to get next linear base
	 cmp	 eax,[bp].SAVE_SHADOW_LBASE ; Same as new linear base?
	 je	 short @F	; Jump if so (no discontiguity)

	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jz	 short SAVE_SHADOW_LOOPSHD1 ; Jump if not (can't merge discontiguity)

	 or	 SHDTAB[si].SHD_FLAG,@TT_P2L ; Mark as needing P2L later
	 mov	 SHDTAB[si].SHD_LBASE,-1 ; Zap the linear base
@@:
	 mov	 eax,[bp].SAVE_SHADOW_SIZE ; Get size of shadow RAM in bytes
	 add	 SHDTAB[si].SHD_ESIZE,eax ; Add into previous size
	 add	 SHDSIZE,eax	; Add into cumulative count, too

	 jmp	 SAVE_SHADOW_EXIT ; Join common exit code

SAVE_SHADOW_LOOPSHD1:
	 add	 si,size SHD_STR ; Skip to next entry

	 loop	 SAVE_SHADOW_NEXTSHD1 ; Jump if more entries to process

; Loop through all previous entries to see if this one can be
; merged with any one of them as a preceding block.

	 mov	 cx,SHDCNT	; Get # current entries
	 xor	 si,si		; Initialize index into SHDTAB
SAVE_SHADOW_NEXTSHD2:

; If the current entry is unallocated and the incoming one isn't
; or vice versa, we can't merge.

	 mov	 ax,SHDTAB[si].SHD_FLAG ; Get the current entry's flags
	 xor	 ax,[bp].SAVE_SHADOW_FLAG ; Merge with the incoming entry's flags

	 test	 ax,@TT_UNALL	; Is there a mismatch?
	 jnz	 short SAVE_SHADOW_LOOPSHD2 ; Yes, so we can't merge

	 mov	 eax,[bp].SAVE_SHADOW_SIZE ; Get incoming size in bytes
	 add	 eax,[bp].SAVE_SHADOW_PBASE ; Add in physical base to get
				; the next physical base
	 cmp	 eax,SHDTAB[si].SHD_PBASE ; Same as current physical base?
	 jne	 short SAVE_SHADOW_LOOPSHD2 ; No, so there's a discontiguity

	 mov	 eax,[bp].SAVE_SHADOW_SIZE ; Get incoming size in bytes
	 add	 eax,[bp].SAVE_SHADOW_LBASE ; Add in linear base to get
				; the next linear base
	 cmp	 eax,SHDTAB[si].SHD_LBASE ; Same as current linear base?
	 je	 short @F	; Jump if so (no discontiguity)

	 test	 GL2_FLAG,@GL2_DPMI ; Is there a DPMI host?
	 jz	 short SAVE_SHADOW_LOOPSHD2 ; Jump if not (can't merge discontiguity)

	 or	 SHDTAB[si].SHD_FLAG,@TT_P2L ; Mark as needing P2L later
	 mov	 SHDTAB[si].SHD_LBASE,-1 ; Zap the linear base
@@:
	 mov	 eax,[bp].SAVE_SHADOW_SIZE ; Get size of shadow RAM in bytes
	 add	 SHDTAB[si].SHD_ESIZE,eax ; Add into previous size
	 add	 SHDSIZE,eax	; Add into cumulative count, too
	 sub	 SHDTAB[si].SHD_PBASE,eax ; Subtract from physical base

	 cmp	 SHDTAB[si].SHD_LBASE,-1 ; Izit zapped?
	 je	 short @F	; Jump if so

	 sub	 SHDTAB[si].SHD_LBASE,eax ; Subtract from linear base
@@:
	 jmp	 short SAVE_SHADOW_EXIT ; Join common exit code

SAVE_SHADOW_LOOPSHD2:
	 add	 si,size SHD_STR ; Skip to next entry

	 loop	 SAVE_SHADOW_NEXTSHD2 ; Jump if more entries to process
SAVE_SHADOW1:
	 mov	 si,SHDIND	; Get offset of next index

	 cmp	 SHDCNT,@SHDTAB_LEN ; Are we at the maximum now?
	 je	 short SAVE_SHADOW_EXIT ; Jump if so (discard this one)

	 mov	 eax,[bp].SAVE_SHADOW_SIZE ; Get size of shadow RAM in bytes
	 mov	 ds:[si].SHD_ESIZE,eax ; Save in shadow RAM structure
	 add	 SHDSIZE,eax	; Add into cumulative count, too

	 mov	 eax,[bp].SAVE_SHADOW_LBASE ; Get linear base
	 mov	 ds:[si].SHD_LBASE,eax ; Save in shadow RAM structure
	 mov	 ds:[si].SHD_OLBASE,eax ; Save in shadow RAM structure

	 mov	 eax,[bp].SAVE_SHADOW_PBASE ; Get physcial base
	 mov	 ds:[si].SHD_PBASE,eax ; Save in shadow RAM structure

	 mov	 eax,[bp].SAVE_SHADOW_HNDL ; Get the handle #
	 mov	 ds:[si].SHD_HNDL,eax ; Save in shadow RAM structure

	 mov	 ax,[bp].SAVE_SHADOW_FLAG ; Get the new flags
	 mov	 ds:[si].SHD_FLAG,ax ; Save in shadow RAM structure

	 add	 SHDIND,size SHD_STR ; Skip to next entry
	 inc	 SHDCNT 	; Count in another entry
SAVE_SHADOW_EXIT:
	 REGREST <edi,si,dx,ecx,ebx,eax> ; Restore

	 pop	 bp		; Restore

	 ret	 2+4+4+4+4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_SHADOW endp		; End SAVE_SHADOW procedure
	 NPPROC  SAVE_XSHADOW -- Append to Shadow RAM Structures
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Save shadow RAM information in XSHDTAB structure
and pass on to SAVE_SHADOW.

If @TT_L2P is set and there's a VDS server present,
translate the incoming linear address range into one
or more physical address ranges.

|

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,si>	; Save registers

	 cmp	 XSHDCNT,@XSHDTAB_LEN ; Are we at the maximum now?
	 je	 short SAVE_XSHADOW_EXIT ; Jump if so (discard this one)

	 mov	 si,XSHDIND	; Get offset of next index

	 mov	 eax,[bp].SAVE_SHADOW_SIZE ; Get size of shadow RAM in bytes
	 mov	 ds:[si].SHD_ESIZE,eax ; Save in shadow RAM structure

	 mov	 eax,[bp].SAVE_SHADOW_LBASE ; Get linear base
	 mov	 ds:[si].SHD_LBASE,eax ; Save in shadow RAM structure
	 mov	 ds:[si].SHD_OLBASE,eax ; Save in shadow RAM structure

	 mov	 eax,[bp].SAVE_SHADOW_PBASE ; Get physcial base
	 mov	 ds:[si].SHD_PBASE,eax ; Save in shadow RAM structure

	 mov	 eax,[bp].SAVE_SHADOW_HNDL ; Get the handle #
	 mov	 ds:[si].SHD_HNDL,eax ; Save in shadow RAM structure

	 mov	 ax,[bp].SAVE_SHADOW_FLAG ; Get the new flags
	 mov	 ds:[si].SHD_FLAG,ax ; Save in shadow RAM structure

	 add	 XSHDIND,size SHD_STR ; Skip to next entry
	 inc	 XSHDCNT	; Count in another entry
SAVE_XSHADOW_EXIT:

; Save in other structure

	 push	 [bp].SAVE_SHADOW_FLAG ; Pass flags
	 push	 [bp].SAVE_SHADOW_HNDL ; Pass handle
	 push	 [bp].SAVE_SHADOW_SIZE ; Pass length in bytes
	 push	 [bp].SAVE_SHADOW_PBASE ; Pass physical address
	 push	 [bp].SAVE_SHADOW_LBASE ; Pass linear address
	 call	 SAVE_SHADOW	; Append to shadow RAM structure

	 REGREST <si,eax>	; Restore

	 pop	 bp		; Restore

	 ret	 2+4+4+4+4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SAVE_XSHADOW endp		; End SAVE_XSHADOW procedure
;;;	     NPPROC  SAVE_SCRUB -- Append to Scrub RAM Structure
;;;	     assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Save scrub RAM information in structure.
;;;
;;; |
;;;
;;; SAVE_SCRUB_STR struc
;;;
;;;	     dw      ?		    ; Caller's BP
;;;	     dw      ?		    ; Caller's IP
;;; SAVE_SCRUB_BASE dd ?	    ; Base address
;;; SAVE_SCRUB_SIZE dd ?	    ; Size in bytes
;;;
;;; SAVE_SCRUB_STR ends
;;;
;;;	     push    bp 	    ; Prepare to address the stack
;;;	     mov     bp,sp	    ; Hello, Mr. Stack
;;;
;;;	     REGSAVE <eax,si,ds>    ; Save registers
;;;
;;; ; See if we can merge this entry with the previous one
;;;
;;;	     cmp     SCRBCNT,0	    ; Any previous entries?
;;;	     je      short SAVE_SCRUB1 ; Not this time
;;;
;;;	     mov     si,SCRBIND     ; Get offset of next index
;;;	     sub     si,size SCRB_STR ; Back off to previous entry
;;;
;;;	     mov     eax,ds:[si].SCRB_ESIZE ; Get previous size in bytes
;;;	     add     eax,ds:[si].SCRB_EBASE ; Add in previous base
;;;				    ; to get next base
;;;
;;;	     cmp     eax,[bp].SAVE_SCRUB_BASE ; Same as new base?
;;;	     jne     short SAVE_SCRUB1 ; No, so there's a discontiguity
;;;
;;;	     mov     eax,[bp].SAVE_SCRUB_SIZE ; Get size of shadow RAM in bytes
;;;	     add     ds:[si].SCRB_ESIZE,eax ; Add into previous size in bytes
;;;
;;;	     jmp     short SAVE_SCRUB_EXIT ; Join common exit code
;;;
;;; SAVE_SCRUB1:
;;;	     mov     si,SCRBIND     ; Get offset of next index
;;;
;;;	     mov     eax,[bp].SAVE_SCRUB_SIZE ; Get size of shadow RAM in bytes
;;;	     mov     ds:[si].SCRB_ESIZE,eax ; Save as length in bytes
;;;
;;;	     mov     eax,[bp].SAVE_SCRUB_BASE ; Get base of shadow RAM
;;;	     mov     ds:[si].SCRB_EBASE,eax ; Save in shadow RAM structure
;;;
;;;	     add     SCRBIND,size SCRB_STR ; Skip to next entry
;;;	     inc     SCRBCNT	    ; Count in another entry
;;; SAVE_SCRUB_EXIT:
;;;	     REGREST <ds,si,eax>    ; Restore
;;;	     assume  ds:nothing     ; Tell the assembler about it
;;;
;;;	     pop     bp 	    ; Restore
;;;
;;;	     ret     4+4	    ; Return to caller, popping arguments
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; SAVE_SCRUB endp		    ; End SAVE_SCRUB procedure
	 NPPROC  TOP_WRITE -- Write Top Memory-mapped I/O Port
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Write value in TOP_MIO to top memory-mapped I/O port.

On entry:

DS:SI	 ==>	 32-bit destination address

|

	 REGSAVE <eax,cx,si,es> ; Save registers

	 push	 ds		; Setup ES to receive structure
	 pop	 es
	 assume  es:DGROUP	; Tell the assembler about it

; Setup the GDT for the move

; The source address is TOP_MIO

	 movzx	 eax,DATASEG	; Copy our data segment
	 shl	 eax,4-0	; Convert from paras to bytes
	 add	 eax,offset ds:TOP_MIO ; EAX has 32-bit linear address of TOP_MIO

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
	 mov	 ah,87h 	; Move block function
	 int	 15h		; Request system service
				; Ignore error returns

	 REGREST <es,si,cx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

TOP_WRITE endp			; End TOP_WRITE procedure
	 NPPROC  DISABLE_EGAROM -- Disable EGA ROM
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable EGA ROM at E000 -- restore interrupt vector segments
to C000.

On exit:

CF	 =	 1 if we could not disable it
	 =	 0 if all went OK (including no EGA ROM)

|

	 REGSAVE <ax,cx,di,es>	; Save registers

; Disable ROM remapping

; Check on EGA ROM at E000 -- if present, we try to disable it

	 test	 GLB_FLAG,@GLB_E000 ; Is there a ROM there?
	 jz	 short DISABLE_EGAROM_CLC ; No, already disabled

; If INT 10h, 1Fh, and 43h all point to E000, restore them to C000
; and remove the ROM/RAM at E000.
; If not, just disable the high DOS memory from E400 to F000

	 mov	 ax,seg INTVEC	; Address segment zero
	 mov	 es,ax
	 assume  es:INTVEC	; Tell the assembler about it

	 mov	 ax,0E000h	; Get shadow ROM segment

	 cmp	 ax,INT00_VEC.VSEG[10h*type INT00_VEC] ; Still point to ROM/RAM?
	 jne	 short DISABLE_EGAROM_ERR ; No, so don't disable the ROM

	 cmp	 ax,INT00_VEC.VSEG[1Fh*type INT00_VEC] ; Still point to ROM/RAM?
	 jne	 short DISABLE_EGAROM_ERR ; No, so don't disable the ROM

	 cmp	 ax,INT00_VEC.VSEG[43h*type INT00_VEC] ; Still point to ROM/RAM?
	 jne	 short DISABLE_EGAROM_ERR ; No, so don't disable the ROM

	 mov	 ax,0C000h	; Get EGA ROM segment

	 pushf			; Save flags
	 cli			; Nobody move

	 mov	 INT00_VEC.VSEG[10h*type INT00_VEC],ax ; Point back to ROM
	 mov	 INT00_VEC.VSEG[1Fh*type INT00_VEC],ax ; ...
	 mov	 INT00_VEC.VSEG[43h*type INT00_VEC],ax ; ...

	 popf			; Restore flags
DISABLE_EGAROM_CLC:
	 clc			; Indicate all went OK

	 jmp	 short DISABLE_EGAROM_EXIT ; Join common exit code

DISABLE_EGAROM_ERR:
	 stc			; Indicate we failed
DISABLE_EGAROM_EXIT:
	 REGREST <es,di,cx,ax>	; Restore
	 assume  es:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISABLE_EGAROM endp		; End DISABLE_EGAROM procedure
;;;	     NPPROC  INIT_AT386 -- Initialize AT/386 Settings
;;;	     assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;; COMMENT|
;;;
;;; Initialize AT386_Rxx values.
;;;
;;; |
;;;
;;;	     REGSAVE <ax>	    ; Save register
;;;
;;;	     or      GLB_FLAG,@GLB_AT386 ; Mark as present
;;;
;;;	     pushf		    ; Save flags
;;;	     cli		    ; Nobody move
;;;
;;;	     mov     al,09h	    ; Register #
;;;	     call    READ_82C302    ; Read data from 82C302 into AH
;;;	     mov     AT386_R09[0],ah ; Save old register value
;;;	     mov     AT386_R09[1],0 ; Save as Read/Write, all substitutions
;;;
;;; ; Check A000-C000 (register 0Dh)
;;;
;;;	     mov     al,0Dh	    ; Register #
;;;	     call    READ_82C302    ; Read data from 82C302 into AH
;;;	     mov     AT386_R0D[0],ah ; Save old register value
;;;	     mov     AT386_R0D[1],ah ; Same as before
;;;
;;; ; Check C000-E000 (register 0Eh)
;;;
;;; ;;;;;;;; mov     al,0Eh	    ; Register #
;;; ;;;;;;;; call    READ_82C302    ; Read data from 82C302 into AH
;;; ;;;;;;;; mov     AT386_R0E[0],ah ; Save old register value
;;;	     mov     AT386_R0E[0],-1 ; Save as on I/O channel
;;;	     mov     AT386_R0E[1],0 ; Save as on system board
;;;
;;; ; Check E000-10000 (register 0Fh)
;;;
;;;	     mov     al,0Fh	    ; Register #
;;;	     call    READ_82C302    ; Read data from 82C302 into AH
;;;	     and     ah,not 0Fh     ; Ensure E000-F000 on system board
;;;	     mov     AT386_R0F[0],ah ; Save old register value
;;;	     mov     AT386_R0F[1],0 ; Save as on system board
;;;
;;;	     popf		    ; Restore
;;;
;;;	     REGREST <ax>	    ; Restore
;;;
;;;	     ret		    ; Return to caller
;;;
;;;	     assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
;;;
;;; INIT_AT386 endp		    ; End INIT_AT386 procedure
	 NPPROC  SRCHSTR -- Search For A String
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Search for a string.

On entry:

On exit:

DI	 =	 offset of match in ROM
CF	 =	 0 if found
	 =	 1 if not

|

SRCHSTR_STR struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; ...	   IP
SRCHSTR_LEN1 dw  ?		; Length of string
SRCHSTR_OFF1 dw  ?		; Offset of string in DGROUP
SRCHSTR_LEN2 dw  ?		; Length of search area
SRCHSTR_VEC2 dd  ?		; Ptr to area to search

SRCHSTR_STR ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <ax,cx,si,es>	; Save registers

	 les	 di,[bp].SRCHSTR_VEC2 ; ES:DI ==> start of search area
	 assume  es:nothing	; Tell the assembler about it

	 mov	 si,[bp].SRCHSTR_OFF1 ; FS:SI ==> source string
	 mov	 cx,[bp].SRCHSTR_LEN2 ; Get length of search area
	 sub	 cx,[bp].SRCHSTR_LEN1 ; Less length of the string
	 dec	 cx		; Less one to not fall off the end
	 mov	 al,DGROUP:[si] ; Get the first byte
SRCHSTR_NEXT:
	 jcxz	 SRCHSTR_ERR	; Jump if no more bytes to check
   repne scas	 es:[di].LO	; Search for the 1st byte
	 jne	 short SRCHSTR_ERR ; Jump if no match

	 REGSAVE <cx,di>	; Save registers
	 mov	 si,[bp].SRCHSTR_OFF1 ; FS:SI ==> source string
	 inc	 si		; Plus one to account for the first match
	 mov	 cx,[bp].SRCHSTR_LEN1 ; Get length of the string
	 dec	 cx		; Less one to account for the first match
    repe cmps	 DGROUP:[si].LO,es:[di].LO ; Check the rest
	 REGREST <di,cx>	; Restore
	 jne	 short SRCHSTR_NEXT ; Jump if no match

	 dec	 di		; Back off to start of match

	 clc			; Mark as found

	 jmp	 short SRCHSTR_EXIT ; Join common exit code

SRCHSTR_ERR:
	 stc			; Mark as not found
SRCHSTR_EXIT:
	 REGREST <es,si,cx,ax>	; Restore
	 assume  es:nothing	; Tell the assembler about it

	 pop	 bp		; Restore

	 ret	 2+2+2+4	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SRCHSTR  endp			; End SRCHSTR procedure
	 NPPROC  OLI_RESET -- Disable Olivetti/AT&T Use of Shadow RAM
	 assume  ds:DGROUP,es:nothing,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Disable the Olivetti/AT&T system's use of shadow RAM

On exit:

CF	 =	 0 if all went OK
	 =	 1 otherwise

|

	 REGSAVE <ax,bx>	; Save registers

	 cli			; Disallow interrupts

	 call	 WAITOBUF_CLR	; Clear the 8042's output buffer

	 mov	 ah,0A8h	; Special function to set state
	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short OLI_RESET_XPRES ; Something went wrong

	 mov	 ah,81h 	; Code to read special register
	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short OLI_RESET_XPRES ; Something went wrong

	 mov	 ah,02h 	; Special register #2 (configuration latch)
	 call	 PPI_S2K_K2S	; Send command AH to 6805, response in AL
	 jc	 short OLI_RESET_XPRES ; Something went wrong

; Clear bit 6 in AL to disable the system's use of shadow RAM
; adn send back to the controller

	 and	 al,not @BIT6	; Clear it
	 mov	 bl,al		; Copy it

	 call	 WAITOBUF_CLR	; Clear the 8042's output buffer

	 mov	 ah,0A8h	; Special function to set state
	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short OLI_RESET_XPRES ; Something went wrong

	 mov	 ah,80h 	; Code to write special register
	 call	 PPI_S2C	; Send command AH to 8042
	 jc	 short OLI_RESET_XPRES ; Something went wrong

	 mov	 ah,02h 	; Special register #2 (configuration latch)
	 call	 PPI_S2K	; Send data AH to keyboard
	 jc	 short OLI_RESET_XPRES ; Something went wrong

	 mov	 ah,bl		; New value for configuration latch
	 call	 PPI_S2K	; Send data AH to keyboard
	 jc	 short OLI_RESET_XPRES ; Something went wrong

; Read the command byte to ensure last command accepted

	 mov	 ah,@S2C_RCMD	; Read the command byte
	 call	 PPI_S2C_K2S	; Send AH to 8042, return with AL = response
;;;;;;;; jc	 short OLI_RESET_XPRES ; Something went wrong
OLI_RESET_XPRES:
	 sti			; Allow interrupts

	 REGREST <bx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

OLI_RESET endp			; End OLI_RESET procedure

CODE	 ends			; End CODE segment

	 MEND			; End MEM_SYS module
