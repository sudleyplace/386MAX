;'$Header:   P:/PVCS/MAX/EXTRADOS/HARP_INI.ASV   1.4   30 May 1997 11:13:10   BOB  $
	 title	 HARP_INI -- Initialization routines for HARPO
	 page	 58,122
	 name	 HARP_INI

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-97 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned, public, class 'prog'
	       Group DGROUP:
	       Data    segment DATA,  dword-aligned,public, class 'data'
	       Stack   segment STACK, para-aligned, stack,  class 'stack'

|
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include KEYCALL.INC
	 include ASCII.INC
	 include PTR.INC
	 include DEVDRV.INC
	 include IOCTL.INC
	 include VERSION.INC

	 include QMAX_CTL.INC
	 include SEGS.INC
	 include HARPO.INC
.list


;*******************************************************************


HCODE	 segment		; Start Resident Code segment
	 assume  ds:PGROUP

extern	 DATASEG:word		; Our Data Segment
extern	 CURR_PASS:byte 	; Current Pass variable (0,1,2,-1)
extern	 @PASS_INS:abs		; We're invoked from INSTALL=


;--------------- Miscellaneous --------------------

	 public  DOSVER,FIRST_MAC
DOSVER		 dw	 ?	; DOS version numbner
FIRST_MAC	 dw	 ?	; Segment of first MAC entry


;--------------- 386MAX (resident) variables --------------------------

	 public  PORT67,POVR_MAC,LOADSEG
PORT67		 dw	 0	; MAX's port 67 value
POVR_MAC	 dw	 -1	; Start of High DOS MAC chain
LOADSEG 	 dw	 0	; Start of LSEG chain

	 public  DEVNAME_MAX,DEV_HNDL
DEVNAME_MAX	 db	 '386MAX$$',0   ; MAX's device name
DEV_HNDL	 dw	 0		; Handle used to open MAX

	 public  MSG_COPY
MSG_COPY db	 @HNAME,' -- Version '
	 db	 VERS_H,'.',VERS_T,VERS_U
ifdef LANG_GR
	 db	 ' -- Ein DOS Memory Reorganizer',CR,LF
	 db	 '   (C) Copyright 1993-96 Qualitas, Inc.'
	 db	 '  Alle Rechte vorbehalten.',CR,LF
	 db	 EOS
else
	 db	 ' -- A DOS Memory Reorganizer',CR,LF
	 db	 '   (C) Copyright 1993-96 Qualitas, Inc.'
	 db	 '  All rights reserved.',CR,LF
if @MAX6
	 db	 '   Special version for Bank of America.',CR,LF
endif					; IF @MAX6
	 db	 EOS
endif					; IFDEF LANG_GR

	 public  MSG_PAUSE
ifdef LANG_GR
MSG_PAUSE  db	     '    Weiter mit beliebiger Taste...',CR,LF
else
MSG_PAUSE  db	     '    Press any key to continue...',CR,LF
endif					; IFDEF LANG_GR
	   db	 EOS

	 public  MSG_MAXIMIZE1
MSG_MAXIMIZE1	label byte
	     db  BEL
ifdef LANG_GR
	     db  'ÕÕ> ACHTUNG: Die Grî·e von '
else
	     db  'ÕÕ> WARNING: The size of '
endif				; IFDEF LANG_GR
	     db  EOS

	 public  MSG_MAXIMIZE2,MSG_MAXIMIZE3
MSG_MAXIMIZE2	label byte
ifdef LANG_GR
	     db  ' hat sich verÑndert.',CR,LF
MSG_MAXIMIZE3 db '    Wir empfehlen, MAXIMIZE zu wiederholen.'
else
	     db  ' has changed.',CR,LF
MSG_MAXIMIZE3 db '    It is recommended that you rerun MAXIMIZE.'
endif				; IFDEF LANG_GR
	     db  CR,LF,EOS

	 public  MSG_XENV
MSG_XENV db	 BEL
ifdef LANG_GR
	 db	 'ÕÕ> konnte Environment-Ladefunktion nicht finden.'
else
	 db	 'ÕÕ> Could not locate environment loader.'
endif				; IFDEF LANG_GR
	 db	 CR,LF,EOS

	 public  MSG_XI21
MSG_XI21 db	 BEL
ifdef LANG_GR
	 db	 'ÕÕ> konnte Interrupt 21h Behandlung nach 4Bh Routine nicht wiederherstellen.'
else
	 db	 'ÕÕ> Could not restore interrupt 21h handler after 4Bh trap.'
endif				; IFDEF LANG_GR
	 db	 CR,LF,EOS

	 public  MSG_XMEM
MSG_XMEM  db	 BEL
ifdef LANG_GR
	  db	 'ÕÕ> konnte COMMAND.COM nicht in HiDOS laden.',CR,LF
else
	  db	 'ÕÕ> Not enough memory to load COMMAND.COM into High DOS.'
endif				; IFDEF LANG_GR
	  db	 CR,LF,EOS

	 public  MSG_XLOAD,MSG_XLOAD1
MSG_XLOAD db	 BEL
ifdef LANG_GR
	  db	 'ÕÕ> Nicht genÅgend Speicher, um COMMAND.COM in HiDOS zu laden.'
	  db	 '    Fehler ('
else
	  db	 'ÕÕ> Could not load COMMAND.COM into High DOS.',CR,LF
	  db	 '    Error ('
endif				; IFDEF LANG_GR
MSG_XLOAD1 db	 '____).'
	  db	 CR,LF,EOS

	 public  MSG_XFIRST
MSG_XFIRST db	 BEL
ifdef LANG_GR
	   db	 'ÕÕ> ',@HNAME,' mu· das letzte INSTALL= Programm in CONFIG.SYS sein.',CR,LF
	   db	 '    Bitte MAXIMIZE wiederholen.'
else
	   db	 'ÕÕ> ',@HNAME,' must be the last INSTALL= program in CONFIG.SYS',CR,LF
	   db	 '    Please rerun MAXIMIZE.'
endif				; IFDEF LANG_GR
	   db	 CR,LF,EOS

	 public  MSG_LOWMEM
MSG_LOWMEM db	 BEL
ifdef LANG_GR
	   db	 'ÕÕ> Fehler in der Speicherkonfiguration.',CR,LF
else
	   db	 'ÕÕ> Memory configuration error.',CR,LF
endif				; IFDEF LANG_GR
	   db	 CR,LF,EOS

	 public  MSG_LOWMEM_ENV
MSG_LOWMEM_ENV label byte
ifdef LANG_GR
	   db	 '    konnte das Environment nicht in LoDOS laden.',CR,LF
	   db	 '    Bitte MAXIMIZE wiederholen.'
else
	   db	 '    Could not load the Environment into Low DOS memory.',CR,LF
	   db	 '    Please rerun MAXIMIZE.'
endif				; IFDEF LANG_GR
	   db	 CR,LF,EOS

	 public  MSG_LOWMEM_CCOM
MSG_LOWMEM_CCOM label byte
ifdef LANG_GR
	   db	 '    konnte COMMAND.COM nicht in LoDOS Speicher laden.',CR,LF
	   db	 '    Bitte MAXIMIZE wiederholen.'
else
	   db	 '    Could not load the COMMAND.COM into Low DOS memory.',CR,LF
	   db	 '    Please rerun MAXIMIZE.'
endif				; IFDEF LANG_GR
	   db	 CR,LF,EOS

	 public  MSG_ENV_SIZE
ifdef LANG_GR
MSG_ENV_SIZE db  'Master-Environment'
else
MSG_ENV_SIZE db  'the master environment'
endif				; IFDEF LANG_GR
	     db  EOS

	 public  MSG_FILES,MSG_FCB,MSG_BUFFERS,MSG_LASTDRV
	 public  MSG_STACKS,MSG_SUBSEG3,MSG_BATCH
MSG_FILES    db  'FILES=',EOS
MSG_FCB      db  'FCB=',EOS
MSG_BUFFERS  db  'BUFFERS=',EOS
MSG_LASTDRV  db  'LASTDRV=',EOS
MSG_STACKS   db  'STACKS=',EOS
ifdef LANG_GR
MSG_SUBSEG3  db  'DOS 3 Daten',EOS
MSG_BATCH    db  'Stapelverarbeitungs-Daten',EOS
else
MSG_SUBSEG3  db  'DOS 3 data',EOS
MSG_BATCH    db  'Batch processing data',EOS
endif				; IFDEF LANG_GR

	 public  MSG_IFS_G,MSG_IFS_H,MSG_IFS_R,MSG_IFS_Y
MSG_IFS_G    db  'IFS-G',EOS
MSG_IFS_H    db  'IFS-H',EOS
MSG_IFS_R    db  'IFS-R',EOS
MSG_IFS_Y    db  'IFS-Y',EOS

	 public  MSG_XSUBSEGLEN
MSG_XSUBSEGLEN label byte
	     db  BEL
ifdef LANG_GR
	     db  'ÕÕ> konnte CFG_SUBSEGLEN nicht ermitteln, ',@HNAME,' hier nicht installierbar.',CR,LF
	     db  '    Starten Sie den Computer neu, um das Programm zu Åbergehen.',CR,LF
else
	     db  'ÕÕ> Could not find CFG_SUBSEGLEN, ',@HNAME,' can not be installed on this machine.',CR,LF
	     db  '    Reboot to bypass this program.',CR,LF
endif				; IFDEF LANG_GR
	     db  CR,LF,EOS

if 0 ;===================
	 public  MSG_HIGHDOS_FULL
MSG_HIGHDOS_FULL label byte
	     db  BEL
	     db  'ÕÕ> WARNING: Not enough High DOS memory for sub-segments'
	     db  CR,LF,EOS
endif ;===================

	 public  MSG_REGION_OFLOW
MSG_REGION_OFLOW label byte
ifdef LANG_GR
	 db	 ' hat sich verÑndert.',CR,LF
	 db	 'Nicht genÅgend HiDOS Speicher fÅr DOS Teilsegmente.',CR,LF
	 db	 'Teilsegmente konnten nicht geladen werden.',CR,LF
	 db	 'Neustart und erneutes MAXIMIZE erforderlich.',CR,LF,EOS
else
	 db	 ' has changed.',CR,LF
	 db	 'Not enough high DOS memory for DOS sub-segments.',CR,LF
	 db	 'Sub-segments have failed to load.',CR,LF
	 db	 'You must reboot and rerun MAXIMIZE',CR,LF,EOS
endif				; IFDEF LANG_GR

;****************************************************************************

	 NPPROC  DISP_COPY -- Display Our Copyright Line
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT|

Display our copyright line.
This routine is called from both the Device Driver and Command Line version.
Note that if VERBOSE is not present, we may need to display our copyright
message before an error message.  Zeroing the first byte gives us a means
to avoid displaying it twice.

On entry:
DS:DI	=	Address of second message

|

	 REGSAVE <ax,dx>	; Save registers

	 push	 ds		; Save

	 push	 cs		; Get resident data segment
	 pop	 ds		; Address it
	 assume  ds:PGROUP	; Tell the assembler about it

	 cmp	 MSG_COPY[0],0	; Have we already tooted our horn?
	 je	 short @F	; Jump if so

	 mov	 ah,@STROUT	; DOS: Print String function (09h)
	 lea	 dx,MSG_COPY	; Copyright message
	 int	 21h		; Tell 'em "Qualitas rules"

	 mov	 MSG_COPY[0],0	; Make sure we don't display it again

@@:
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler

	 or	 di,di		; Is there a second message?
	 jz	 EXIT		; Jump if not

	 mov	 ah,@STROUT	; DOS: Print String function (09h)
	 mov	 dx,di		; "What we're loading high" message
	 int	 21h		; Tell 'em what this instance does

EXIT:
	 REGREST <dx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing

DISP_COPY endp			; End DISP_COPY procedure


HCODE	 ends			; End Resident Code segment


;****************************************************************************

HDATA	 segment		; Start Non-Resident Data segment


;--------------- Messages --------------------------

	 public  MSG_SUCCESS_DEV,MSG_SUCCESS_INS
ifdef LANG_GR
MSG_SUCCESS_DEV db '   Untersuche DOS Teilsegmente.'
		db     CR,LF,LF,EOS
MSG_SUCCESS_INS db '   Untersuche Befehlsprozessor (COMMAND).'
else
MSG_SUCCESS_DEV db '   Analyzing DOS sub-segments.'
		db     CR,LF,LF,EOS
MSG_SUCCESS_INS db '   Analyzing Command Processor.'
endif				; IFDEF LANG_GR
		db     CR,LF,LF,EOS

;--------------- Error Messages --------------------------
ifdef LANG_GR
	 public  MSG_NODOSVER
MSG_NODOSVER db  BEL,'ÕÕ> Sie mÅssen fÅr dieses Programm DOS 3.30 (oder hîher) einsetzen.'
	    db	 CR,LF,EOS

	 public  MSG_NOINSTALL
MSG_NOINSTALL db  BEL,'ÕÕ> Befehlsinterpreter nicht erkannt.',CR,LF
	    db	 CR,LF,EOS

	 public  MSG_386LOAD
MSG_386LOAD db	  BEL,'ÕÕ> Dieses Programm kann nicht im HiDOS laufen.',CR,LF
	    db	      '    Bitte entfernen Sie die 386LOAD Anweisung aus der CONFIG.SYS Zeile.'
	    db	 CR,LF,EOS

	 public  MSG_XMAX
MSG_XMAX    db	  BEL,'ÕÕ> Dieses Programm erfordert Qualitas MAX/BlueMAX ab Version 8.0.',CR,LF
	    db	 CR,LF,EOS

else

	 public  MSG_NODOSVER
MSG_NODOSVER db  BEL,'ÕÕ> You need DOS 3.30 (or above) to run this program.'
	    db	 CR,LF,EOS

	 public  MSG_NOINSTALL
MSG_NOINSTALL db	 BEL,'ÕÕ> Command interpreter not recognized.',CR,LF
	    db	 CR,LF,EOS

	 public  MSG_386LOAD
MSG_386LOAD db	 BEL,'ÕÕ> This program can not be run from High DOS memory.',CR,LF
	    db	     '    Please remove the 386LOAD statement from this line in CONFIG.SYS.'
	    db	 CR,LF,EOS

	 public  MSG_XMAX
MSG_XMAX    db	 BEL,'ÕÕ> This program requires Qualitas MAX/BlueMAX version 8.0 (or above).',CR,LF
	    db	 CR,LF,EOS

endif

	 public  MSG_DD_HELP
MSG_DD_HELP label byte
	   db	 BEL
ifdef LANG_GR
	   db	 'ÕÕ> Die einzige gÅltige Befehlszeilen-Option ist:',CR,LF
	   db	 '    ',@HNAME,' pro=',@HNAME,'.pro',CR,LF
	   db	 '    Die ',@HNAME,'.pro Datei kann jede von MAXIMIZE',CR,LF
	   db	 '    eingestellte Option enthalten.',CR,LF
else
	   db	 'ÕÕ> The only valid command line option is:',CR,LF
	   db	 '    ',@HNAME,' pro=',@HNAME,'.pro',CR,LF
	   db	 '    The ',@HNAME,'.pro file may contain options created',CR,LF
	   db	 '    by MAXIMIZE.',CR,LF
endif				; IFDEF LANG_GR
	   db	 CR,LF,EOS

	 public  MSG_NOPRO
MSG_NOPRO    db  BEL
ifdef LANG_GR
	     db  'ÕÕ> Das Profil mu· in der DEVICE= Zeile angegeben sein.'
else
	     db  'ÕÕ> The profile must be specified on the DEVICE= line.'
endif				; IFDEF LANG_GR
	     db  CR,LF,EOS

	 public  MSG_OFLOW
MSG_OFLOW label byte
	   db	 BEL
ifdef LANG_GR
	   db	 'ÕÕ> Ein DOS Teilsegment-öberlauf ist wÑhrend des GETSIZE Modus aufgetreten.',CR,LF
	   db	 '    Bitte MAXIMIZE wiederholen.',CR,LF
else
	   db	 'ÕÕ> A DOS sub-segment overflow has occurred, GETSIZE mode in effect.',CR,LF
	   db	 '    Please run MAXIMIZE.',CR,LF
endif				; IFDEF LANG_GR
	   db	 CR,LF,EOS

	 public  MSG_DEADMAN
MSG_DEADMAN label byte
	   db	 BEL
ifdef LANG_GR
	   db	 'ÕÕ> Ein Fehler wurde festgestellt bei AusfÅhrung von ',@HNAME,',',CR,LF
	   db	 '    Bitte MAXIMIZE wiederholen.',CR,LF
else
	   db	 'ÕÕ> An error was previously encountered while running ',@HNAME,',',CR,LF
	   db	 '    Please rerun MAXIMIZE.',CR,LF
endif				; IFDEF LANG_GR
	   db	 CR,LF,EOS

	 public  MSG_PRO_UNK
ifdef LANG_GR
MSG_PRO_UNK db	 BEL,'unbekanntes SchlÅsselwort ==> ',EOS
else
MSG_PRO_UNK db	 BEL,'Unknown keyword ==> ',EOS
endif				; IFDEF LANG_GR

	 public  MSG_ERR_XDOS
MSG_ERR_XDOS db  BEL
ifdef LANG_GR
	     db  'ÕÕ> DOS Version nicht erkennbar.'
else
	     db  'ÕÕ> Unrecognized version of DOS.'
endif				; IFDEF LANG_GR
	     db  CR,LF,EOS

	 public  MSG_XCCOM
MSG_XCCOM    db  BEL
ifdef LANG_GR
	     db  'ÕÕ> konnte COMMAND.COM Laderoutine nicht finden.'
else
	     db  'ÕÕ> Could not locate COMMAND.COM loader.'
endif				; IFDEF LANG_GR
	     db  CR,LF,EOS

;---------- 386MAX variables (non-resident) -----------------

	 public  INFO_CTL,INFO,INFOSIZE
	 include QMAXINFO.INC
INFO_CTL db	 ?		; IOCTL type
INFO	 INFO_STR <>
INFOSIZE equ	 size INFO_STR


;------------------------------------------------------------


HDATA	 ends			; End non-Resident Data segment

;****************************************************************************

HNCODE	 segment		; Start Non-Resident Code Segment


;****************************************************************************

	 NPPROC  CHECK_DOSVER -- CHECK_DOSVER procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Retrieve the DOS version number
* Minimum DOS version when running from INSTALL=     = 5.00 (COMMAND.COM)
* Minimum DOS version when running from Command Line = 4.00
* Minimum DOS version when running from CONFIG.SYS   = 3.30
* Determine if we are running under ROM-DOS [FIXME]

On exit:
CF	=	0 All went well
		1 DOS is below 4.0 (abort)

|

	 REGSAVE <ax,bx,cx,dx,di,ds> ; Save registers

	 mov	 ds,DATASEG	; Address our non-resident data
	 assume  ds:DGROUP	; Tell the assembler about it

; Get the DOS version number

	 DOSCALL @DOSVER	; Get the DOS Version

	 xchg	 al,ah		; Convert to usable format
	 mov	 DOSVER, ax	; Store the version # for later

	 cmp	 ah,05h 	; izit DOS Version 5.0 or greater
	 jae	 DOSVER_EXIT	; Yes, EVERYTHING is OK to do

; At this point we are running on a DOS version less than 5.0

	 cmp	 CURR_PASS,@PASS_INS ; INSTALL= time? (Needs DOS 5.0)
	 jne	 @F		; If not, continue checking

	 lea	 di,MSG_NOINSTALL ; Tell 'em we can't INSTALL='s
	 call	 DISP_COPY	; Display copyright and message

	 jmp	 near ptr DOSVER_ERR ; Set error flag, and leave

@@:
	 cmp	 ah,04h 	; izit DOS version 4.0
	 jae	 DOSVER_EXIT	; COMMAND_LINE and DEVICE can handle 4.00+

; At this point we are running on a version of DOS below 4.00

	 cmp	 ax,031Eh	; Compare against DOS 3.30
	 jae	 DOSVER_EXIT	; DEVICE = can handle 3.30+

; At this point we are running on a version of DOS below 3.30

	 lea	 di,MSG_NODOSVER ; Tell 'em we need at least DOS 3
	 call	 DISP_COPY	; Display copyright and message

DOSVER_ERR:
	 stc			; Indicate error

DOSVER_EXIT:
	 REGREST <ds,di,dx,cx,bx,ax> ; Restore registers
	 assume  ds:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
CHECK_DOSVER	 endp		; End CHECK_DOSVER procedure


;****************************************************************************

	 NPPROC  GET_FIRST_MAC -- GET_FIRST_MAC procedure
	 assume  ds:DGROUP,es:DGROUP,ss:nothing
COMMENT |

Get the address of the First MAC entry

|

	 REGSAVE <ax,bx,es>	; Save registers

; Get the address of the List of Lists

	 mov	ah,@GETLST	; DOS: List of Lists function (52h)
	 int	21h		; DOS Services (Return in ES:BX)
	 assume es:nothing	; Tell the assembler about it

	 mov	 ax,es:[bx-2]	; Save segment of first MAC
	 mov	 FIRST_MAC,ax	; ...

	 REGREST <es,bx,ax>	; Restore registers
	 assume  es:DGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
GET_FIRST_MAC	 endp		; End GET_FIRST_MAC procedure


;*************************************************************************

	 NPPROC  MAX_PRESENT -- Check for 386MAX device presence
	 assume  ds:nothing,es:nothing,ss:nothing

COMMENT |

Determine if MAX is present.

If MAX is present, save the PORT67 value for the VxD EMM2 call.
If MAX is not present, then we can't run since even GETSIZE mode
       needs MAX (for the EMM2 call)

On exit:
CF	=	0 MAX is present
	=	1 MAX is not present

|

	 REGSAVE <ax,bx,cx,dx,ds> ; Save caller's registers

	 push	 cs		; Address our resident data
	 pop	 ds		; ... via DS
	 assume  ds:PGROUP	; Tell the assembler about it

	 mov	 al,02h 	; R/W access
	 DOSCALL @OPENF2,DEVNAME_MAX ; Attempt to open 386MAX device driver
				;				 
	 mov	 ds,DATASEG	; Address our data		 ≥
	 assume  ds:DGROUP	; Tell the assembler about it	 ≥
				;				 ≥
	 jc	 EXIT_ERR	; Jump if FILE_OPEN failed ƒƒƒƒƒŸ

; Ensure it's a device

	 mov	 DEV_HNDL,ax	; Save for later use
	 mov	 bx,ax		; Move handle to proper register

	 mov	 al,00h 	; Function code to get device information
	 DOSCALL @IOCTL2	; Return in DX
	 jc	 EXIT_ERR	; Jump if error

	 test	 dx,@IOCTL_DEV	; Izit a device?
	 jz	 EXIT_ERR	; No???

; Get QMAXINFO structure

	 mov	 al,02h 	; Read from device
	 mov	 bx,DEV_HNDL	; Get device handle
	 mov	 cx,INFOSIZE	; CX = # bytes in INFO structure
	 mov	 INFO_CTL,@CTL_XFER ; Mark as INFO transfer
	 DOSCALL @IOCTL2,INFO_CTL ; Get IOCTL info into INFO

	 mov	 ax,INFO.INFO_P67 ; I/O port number for EMM2 functions
	 mov	 PORT67,ax	; Save for EMMOUT macro

	 mov	 ax,INFO.INFO_POVR ; Start of High DOS MAC chain
	 mov	 POVR_MAC,ax	; Save for later

	 mov	 ax,INFO.INFO_LSEG ; Start of LSEG chain
	 mov	 LOADSEG,ax	; Save for later

	 jmp	 EXIT_CLOSE	; Join common exit code

EXIT_ERR:

; Tell 'em MAX is not present

	 REGSAVE <di>		; Save

	 lea	 di,MSG_XMAX	; Tell 'em we need MAX
	 call	 DISP_COPY	; Display copyright and message

	 REGREST <di>		; Restore

	 stc			; Indicate MAX not present

	 jmp	 EXIT		; Join common exit code

EXIT_CLOSE:
	 mov	 bx,DEV_HNDL	; Get device handle
	 or	 bx,bx		; Is it open?
	 jz	 @F		; Jump if not

	 DOSCALL @CLOSF2	; Close the handle
@@:

	 clc			; Indicate all is OK
EXIT:
	 REGREST <ds,dx,cx,bx,ax> ; Restore caller's registers
	 assume  ds:nothing	; Tell the assembler about it


	 ret			; ... to caller

	 assume  ds:nothing,es:nothing,ss:nothing
MAX_PRESENT endp		; End of MAX_PRESENT routine


;***************************************************************************

	 NPPROC  CHECK_HIGH -- CHECK_HIGH procedure
	 assume  ds:nothing,es:nothing,ss:nothing
COMMENT |

Determine if we are being loaded via 386LOAD

On exit:
CF	=	0 We're in Low DOS
	=	1 We're in High DOS

|

	 REGSAVE <ax,di>	; Save registers

; Determine if we're in High DOS

	 mov	 ax,cs		; Get current code segment

	 cmp	 ax,0A000h	; Are we in High DOS?
	 jb	 EXIT		; Jump if not (Note: CF=1)

; Tell 'em we can't run in High DOS

	push	ds		; Save for a moment

	mov	ds,DATASEG	; Setup addressibility to DGROUP
	assume	ds:DGROUP	; Tell the assembler about it

	 lea	 di,MSG_386LOAD ; "Already in High DOS" message
	 call	 DISP_COPY	; Display copyright and message

	pop	ds		; Restore
	assume	ds:nothing	; Tell the assembler about it

	 clc			; Indiacte we're in High DOS

EXIT:
	 cmc			; CF = 0 : We're in Low DOS
				; CF = 1 : We're in High DOS

	 REGREST <di,ax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,ss:nothing
CHECK_HIGH	 endp		; End CHECK_HIGH procedure


;*************************************************************************

HNCODE	 ends			; End Non-Resident Code Segment


	 END			; End HARP_INI module


