;' $Header:   P:/PVCS/MAX/386MAX/QMAX_MSG.ASV   1.6   30 May 1997 10:45:40   BOB  $
	 title	 QMAX_MSG -- 386MAX Message Text
	 page	 58,122
	 name	 QMAX_MSG

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group FGROUP:
	       Data    segment FDATA, dword-aligned, public, class 'fixup'
	       Group YGROUP:
	       Data    segment YDATA, dword-aligned, public, class 'ydata'

Program derived from:  None.

Original code by:  Bob Smith, January, 1987.

Modifications by:  Herbert Reibe c/o Klaus Albrecht MÅnchen
		   on 1. Mar. 1992, messages transferred to German.
	   --->    please check length of modified lines,
		   especially in lines which probably must EQU others.

|

.386p
.xlist
	 include MASM.INC
	 include ASCII.INC
	 include DTE.INC
NOVER_HTU = 1
	 include VERSION.INC

	 include QMAX_OEM.INC
	 include QMAX_FLX.INC
	 include QMAX_DTE.INC

if @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 VERS_HP:abs
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
	 extrn	 VERSLTR1:abs
if @OEM_BETA
	 include VERSBETA.INC
endif				; IF @OEM_BETA
.list

FGROUP	 group	 FDATA
YGROUP	 group	 YDATA


FDATA	 segment use16 dword public 'fixup' ; Start FDATA segment
	 assume  ds:FGROUP

LENTXT	 macro	 LAB,MSG
	 local	 LABA,LABZ

	 public  LAB
if @OEM_SYS eq @OEMSYS_HPRS
LAB	 LENTXT_STR <LABZ-LABA>
ifdef LANG_GR
LABA	 db	 ' ',@OEM_TEXT,' interner Fehler Nr.',(ERRNO/10)+'0',(ERRNO mod 10)+'0'
else
LABA	 db	 ' ',@OEM_TEXT,' internal error #',(ERRNO/10)+'0',(ERRNO mod 10)+'0'
endif				; IFDEF LANG_GR
ERRNO	 =	 ERRNO+1	; Skip to next error #
else
LAB	 LENTXT_STR <LABZ-LABA>
LABA	 db	 MSG
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

LABZ	 label	 byte

	 endm			; LENTXT

ERRNO	 =	 1		; Initial error #

LENTXT	 MSG_L01,    <'A debug exception'>             ; 01
LENTXT	 MSG_L03,    <'A breakpoint exception'>        ; 02
LENTXT	 MSG_L06,    <'An invalid opcode'>             ; 03
if @OEM_SYS eq @OEMSYS_HPRS
LENTXT	 MSG_L08,    <'A double fault'>                ; 04
LENTXT	 MSG_L09,    <'A MAPTAB fault'>                ; 05
else
LENTXT2  MSG_L08,    <'A double fault'>                ; 04
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
if @OEM_SYS eq @OEMSYS_HPRS
LENTXT	 MSG_L0A,    <'An invalid PRG fault'>          ; 06
LENTXT	 MSG_L0B,    <'A segment not present fault'>   ; 07
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
ifdef LANG_GR
LENTXT	 MSG_L0D,    <'Ein interner Systemfehler '>    ; 08
else
LENTXT	 MSG_L0D,    <'An internal system error'>      ; 08
endif				; IFDEF LANG_GR
if @OEM_SYS eq @OEMSYS_HPRS
ifdef LANG_GR
LENTXT	 MSG_L0E,    <'Ein Seitenfehler'>              ; 09
else
LENTXT	 MSG_L0E,    <'A page fault'>                  ; 09
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
LENTXT	 MSG_DMAPAGE,<'A DMA page fault'>              ; 10
LENTXT	 MSG_PNP,    <'A page not present fault'>      ; 11
LENTXT	 MSG_SUP,    <'A page not user fault'>         ; 12
LENTXT	 MSG_ROM,    <'A read-only EMS page fault'>    ; 13
LENTXT	 MSG_CRn,    <'A ROM move into CRn'>           ; 14
LENTXT	 MSG_CTRL,   <'Ctrl-Alt-Del'>                  ; 15
LENTXT	 MSG_WOUT,   <'A write to 8042 output port'>   ; 16
if @OEM_SYS eq @OEMSYS_HPRS
LENTXT	 MSG_8255,   <'A ROM initialize of 8255'>      ; 17
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
LENTXT	 MSG_PULSE,  <'A pulse of 8042 output port'>   ; 18
LENTXT	 MSG_286,    <'A shift to 286 mode'>           ; 19
LENTXT	 MSG_XTA20,  <'A degate of A20'>               ; 20
if @OEM_SYS eq @OEMSYS_HPRS
LENTXT	 MSG_MFG,    <'A ROM write to MFG port'>       ; 21
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
LENTXT	 MSG_SELF,   <'A ROM keyboard self-test'>      ; 22
LENTXT	 MSG_REBOOT  <'A ROM reboot from F000:FFF0'>   ; 23
LENTXT	 MSG_ICTRL,  <'INT 09h Ctrl-Alt-Del'>          ; 24
LENTXT	 MSG_P92,    <'MCA Port 92h reset'>            ; 25
if @OEM_DMA
ifdef LANG_GR
LENTXT2  MSG_DMAFULL,<'DMA-Transfergrenze Åberschritten: DMA=  _ in ',@OEM_FILE,'.PRO-File eintragen'> ; xx
else
LENTXT2  MSG_DMAFULL,<'DMA transfer limit exceeded:  put DMA=  _ in ',@OEM_FILE,'.PRO file'> ; xx
endif				; IFDEF LANG_GR
endif				; IF @OEM_DMA
LENTXT2  MSG_L0A,    <'An invalid TSS fault'>          ; xx
LENTXT2  MSG_L0B,    <'A segment not present fault'>   ; xx
ifdef LANG_GR
LENTXT2  MSG_L0C,    <'Stapelspeicherfehler BP=____ SP=____'>    ; xx
else
LENTXT2  MSG_L0C,    <'A stack fault with BP=____ SP=____'>    ; xx
endif				; IFDEF LANG_GR
	 public  L0CNUM,L0CNUM2
L0CNUM	 equ	 $-4		; Start fill here for SP
L0CNUM2  equ	 $-12		; ...		      BP

LENTXT2  MSG_LLA,    <'A 286 LOADALL exception'>       ; xx
LENTXT2  MSG_L11,    <'An Alignment Check Fault'>      ; xx
LENTXT2  MSG_L12,    <'A Machine Check Fault at ________________'> ; xx
	 public  L12NUM
L12NUM	 label	 byte		; Start fill here - 16

if @OEM_SYS eq @OEMSYS_HPRS
ifdef LANG_GR
LENTXT2  MSG_NF,     <@OEM_TEXT,' Privilegierte Anweisung entdeckt'>
else
LENTXT2  MSG_NF,     <@OEM_TEXT,' Privileged Operation Detected'>
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
LENTXT2  MSG_NF,     <'Ausnahmesituation bei privilegierter Anweisung'>
else
LENTXT2  MSG_NF,     <'A Privileged operation exception'>
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

if @OEM_SYS eq @OEMSYS_HPRS
LENTXT2  MSG_TITLE,<CR,LF,@OEM_TEXT,' Version ',VERS_HP,'.0',VERS_H,'.',VERS_T,VERS_U,CR,LF>
LENTXT2  MSG_TITL2,CR
LENTXT2  MSG_TITL3,CR
LENTXT2  MSG_TITL4,CR
ifdef LANG_GR
LENTXT2  MSG_LKEY, <'Mit beliebiger Taste starten Sie Ihren Computer neu. '>
else
LENTXT2  MSG_LKEY, <'Press any key to restart your computer. '>
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_OL2
ifdef LANG_GR
LENTXT2  MSG_TITLE,<CR,LF,'Memory Manager Version ',VERS_H,'.',VERS_T,VERS_U,CR,LF>
else
LENTXT2  MSG_TITLE,<CR,LF,'Memory Manager Version ',VERS_H,'.',VERS_T,VERS_U,CR,LF>
endif				; IFDEF LANG_GR
LENTXT2  MSG_TITL2,CR
LENTXT2  MSG_TITL3,CR
LENTXT2  MSG_TITL4,CR
ifdef LANG_GR
LENTXT2  MSG_LKEY, <'DrÅcken Sie eine beliebige Taste oder starten Sie das System neu. '>
else
LENTXT2  MSG_LKEY, <'Press any key or reset the system to continue. '>
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
LENTXT2  MSG_TITLE,<CR,LF,@OEM_TEXT,' Version ',VERS_H,'.',VERS_T,VERS_U,CR,LF,\
		    CR,LF,'Eine Anwendung hat die System-IntegritÑt verletzt:',CR,LF,CR,LF>
else
LENTXT2  MSG_TITLE,<CR,LF,@OEM_TEXT,' Version ',VERS_H,'.',VERS_T,VERS_U,CR,LF,\
		    CR,LF,'An application has violated system integrity:',CR,LF,CR,LF>
endif				; IFDEF LANG_GR

; The following text is split into several pieces because bozo MASM
; can't handle lines this long.

ifdef LANG_GR
;	  1	    2	      3 	4	  5	    6	      7
;1234567890123456789012345678901234567890123456789012345678901234567890123
LENTXT2  MSG_TITL2,<CR,LF,\
'ÕÕ> Der Prozessor meldete uns soeben den Versuch eines Programmes,',CR,LF,\
'    Systemressourcen in unerlaubter Weise zu nutzen oder exklusiv',CR,LF,\
'    verfÅgbare und bereits belegte Ressourcen erneut anzufordern.',CR,LF>
LENTXT2  MSG_TITL3,<\
'    Das System ist wahrscheinlich in einem instabilen Zustand und',CR,LF,CR,LF,\
'    sollte neu gestartet werden. Entfernen Sie vorÅbergehend einen',CR,LF,\
'    oder mehrere GerÑtetreiber und/oder residente Programme, um den',CR,LF>
LENTXT2  MSG_TITL4,<\
'    Verursacher zu ermitteln. Wir haben als zuletzt gestartetes',CR,LF,\
'    Programm erkannt:',CR,LF,CR,LF,\
'    '>
LENTXT2  MSG_APPLUNK <'(unbekannt)'>
	 public  MSG_TAIL
MSG_TAIL LENTXT_STR <MSG_TAILZ-MSG_TAILA>
MSG_TAILA db CR,LF,CR,LF
	db '    Sollte das Problem mit Entfernen eines bestimmten Programmes',CR,LF
	db '    zu lîsen sein, wenden Sie sich bitte an dessen Hersteller.',CR,LF
	db CR,LF
MSG_TAILZ label byte
LENTXT2  MSG_LKEY, <'ÕÕ> Starten Sie neu mit beliebiger Taste... '>
else
LENTXT2  MSG_TITL2,<CR,LF,\
'ÕÕ> The system processor has reported that a program has attempted to use',CR,LF,\
'    system resources improperly or to use nonshareable resources already',CR,LF>
LENTXT2  MSG_TITL3,<\
'    in use.  It is likely that the system is in an unstable state and',CR,LF,\
'    should be rebooted.  Temporarily remove one or more of your device',CR,LF,\
'    drivers and/or resident programs to find the program in conflict with',CR,LF>
LENTXT2  MSG_TITL4,<\
'    those resources.  For reference, the last program to load is',CR,LF,CR,LF,\
'    '>
LENTXT2  MSG_APPLUNK <'(unknown)'>
LENTXT2  MSG_TAIL, <CR,LF,CR,LF,\
'    If a specific vendor''s program can be removed to prevent this conflict,',CR,LF,\
'    please contact that vendor.',CR,LF,CR,LF>
LENTXT2  MSG_LKEY, <'ÕÕ> Press any key to reboot the system... '>
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_OL2
				; IF @OEM_SYS eq @OEMSYS_HPRS

if @OEM_SYS eq @OEMSYS_HPRS
ifdef LANG_GR
LENTXT2  MSG_LADR, <' bei ____:____ aufgetreten.',CR,LF>
else
LENTXT2  MSG_LADR, <' at ____:____ has occurred.',CR,LF>
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
LENTXT2  MSG_LADR, <' bei ____:____ aufgetreten',CR,LF,'in Ihrer Anwendung.',CR,LF>
else
LENTXT2  MSG_LADR, <' at ____:____ has occurred',CR,LF,'in your application.',CR,LF>
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

	 public  MSG_ADDROFF,MSG_ADDRSEG,MSG_ADDRSEP
ifdef LANG_GR
MSG_ADDRSEG equ  MSG_LADR[5+(size LENTXT_LEN)] ; Skipping over length word
else
MSG_ADDRSEG equ  MSG_LADR[4+(size LENTXT_LEN)] ; Skipping over length word
endif				; IFDEF LANG_GR
MSG_ADDRSEP equ  MSG_ADDRSEG[4] ; The Seg:Off separator
MSG_ADDROFF equ  MSG_ADDRSEG[5]

if @OEM_SYS eq @OEMSYS_HPRS
ifdef LANG_GR
LENTXT2  MSG_PRIVOP,<CR,LF,'Die Anwendung erfordert, da· ',@OEM_TEXT,' AUS ist',CR,LF,\
			   'Soll ich ',@OEM_TEXT,' abschalten und (C) fortfahren oder (R) neu starten? '>
;
else
LENTXT2  MSG_PRIVOP,<CR,LF,'This application must run with ',@OEM_TEXT,' OFF ',CR,LF,\
			   'Deactivate ',@OEM_TEXT,' and (C)ontinue or (R)estart? (C/R) '>
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

ifdef LANG_GR
LENTXT2  MSG_DPMIADDR,<' bei ____|________ aufgetreten',CR,LF,'in Ihrer DPMI-Anwendung.',CR,LF>
else
LENTXT2  MSG_DPMIADDR,<' at ____|________ has occurred',CR,LF,'in your DPMI application.',CR,LF>
endif				; IFDEF LANG_GR

	 public  MSG_DPMIADDRSEL,MSG_DPMIADDRSEP,MSG_DPMIADDROFF
ifdef LANG_GR
MSG_DPMIADDRSEL equ  MSG_DPMIADDR[5+(size LENTXT_LEN)] ; Skipping over length word
else
MSG_DPMIADDRSEL equ  MSG_DPMIADDR[4+(size LENTXT_LEN)] ; Skipping over length word
endif				; IFDEF LANG_GR
MSG_DPMIADDRSEP equ  MSG_DPMIADDRSEL[4]
MSG_DPMIADDROFF equ  MSG_DPMIADDRSEL[5]

LENTXT2  MSG_DPMIAPPLNAME,<78 dup (?)> ; Length of name of last DPMI application

ifdef LANG_GR
LENTXT2  MSG_DPMIPRESS, <'ÕÕ> weiter mit beliebiger Taste... '>
else
LENTXT2  MSG_DPMIPRESS, <'ÕÕ> Press any key to continue... '>
endif				; IFDEF LANG_GR

; The following message are used by either DISP_STR or SWAT and
; thus need to span both formats.  DISP_STR uses a leading
; byte containing the length of the following message.	SWAT
; uses ASCIIZ format.

LENTXT3  macro	 LAB,MSG

LENTXT2  LAB,MSG
	 db	 0		; Terminator for SWAT if used

	 endm			; LENTXT3


LENTXT3  DPMIMSG_LOW,	 <78 dup (?)>
LENTXT3  DPMIMSG_APPLFULL,<'Appl Stack Overflow'>
LENTXT3  DPMIMSG_LPMFULL,<'LPM Stack Overflow'>
LENTXT3  DPMIMSG_VMFULL, <'VM Stack Overflow'>
LENTXT3  DPMIMSG00,	 <'A Divide Exception'>
LENTXT3  DPMIMSG01,	 <'A Debug Exception'>
LENTXT3  DPMIMSG02,	 <'An NMI Exception'>
LENTXT3  DPMIMSG03,	 <'A Breakpoint Exception'>
LENTXT3  DPMIMSG04,	 <'An INTO Exception'>
LENTXT3  DPMIMSG05,	 <'A BOUND Exception'>
LENTXT3  DPMIMSG06,	 <'An Invalid Opcode'>
LENTXT3  DPMIMSG07,	 <'NDP Not Available'>
LENTXT3  DPMIMSG08,	 <'A Double Fault'>
LENTXT3  DPMIMSG09,	 <'An NDP Segment Overrun'>
LENTXT3  DPMIMSG0A,	 <'A TSS Fault'>
LENTXT3  DPMIMSG0B,	 <'A Segment Not Present'>
LENTXT3  DPMIMSG0C,	 <'A Stack Fault'>
LENTXT3  DPMIMSG0D,	 <'A GP Fault'>
LENTXT3  DPMIMSG0E,	 <'A Page Fault'>
LENTXT3  DPMIMSG0F,	 <'An INT 0Fh Exception'>
LENTXT3  DPMIMSG10,	 <'An NDP Exception'>
LENTXT3  DPMIMSG11,	 <'An Alignment Check'>
LENTXT3  DPMIMSG12,	 <'An INT 12h Exception'>
LENTXT3  DPMIMSG13,	 <'An INT 13h Exception'>
LENTXT3  DPMIMSG14,	 <'An INT 14h Exception'>
LENTXT3  DPMIMSG15,	 <'An INT 15h Exception'>
LENTXT3  DPMIMSG16,	 <'An INT 16h Exception'>
LENTXT3  DPMIMSG17,	 <'An INT 17h Exception'>
LENTXT3  DPMIMSG18,	 <'An INT 18h Exception'>
LENTXT3  DPMIMSG19,	 <'An INT 19h Exception'>
LENTXT3  DPMIMSG1A,	 <'An INT 1Ah Exception'>
LENTXT3  DPMIMSG1B,	 <'An INT 1Bh Exception'>
LENTXT3  DPMIMSG1C,	 <'An INT 1Ch Exception'>
LENTXT3  DPMIMSG1D,	 <'An INT 1Dh Exception'>
LENTXT3  DPMIMSG1E,	 <'An INT 1Eh Exception'>
LENTXT3  DPMIMSG1F,	 <'An INT 1Fh Exception'>

FDATA	 ends			; End FDATA segment


YDATA	 segment use16 dword public 'ydata' ; Start YDATA segment
	 assume  ds:YGROUP

if @OEM_WTK
	 public  MSG_WTKOFF
ifdef LANG_GR
MSG_WTKOFF db	 BEL,'ÕÕ> Weitek-FPA nicht verfÅgbar, solange OFF.',CR,LF,EOS
else
MSG_WTKOFF db	 BEL,'ÕÕ> Weitek FPA Unavailable while OFF.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_WTK

	 public  MSG_UNK,MSG_SEP,MSG_SWERR
	 public  MSG_VAL
if @OEM_SYS eq @OEMSYS_HPRS
MSG_SEP  label	 byte
ifdef LANG_GR
MSG_UNK  db	 BEL,'ÕÕ> unerkannter Parameter in CONFIG.SYS',CR,LF
	 db	     '    Ñndern Sie Ihre CONFIG.SYS',CR,LF,EOS
else
MSG_UNK  db	 BEL,'ÕÕ> Unrecognized Parameter in CONFIG.SYS',CR,LF
	 db	     '    Modify CONFIG.SYS',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_CMDCHK_EMSEXT
ifdef LANG_GR
MSG_CMDCHK_EMSEXT db BEL,'ÕÕ> Grî·e zusammen mit EXT= angegeben,',CR,LF
	 db		 '    zulÑssig ist nur eines von beiden',CR,LF,EOS
else
MSG_CMDCHK_EMSEXT db BEL,'ÕÕ> size and EXT= both specified',CR,LF
	 db		 '    Use at most one of them.',CR,LF,EOS
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
MSG_SEP  db	 BEL,'ÕÕ> Trennzeichen fehlt:  ',EOS
MSG_UNK  db	 BEL,'ÕÕ> unbekannter Schalter in DEVICE= Zeile der CONFIG.SYS:  ',EOS
MSG_SWERR db	 BEL,'ÕÕ> ungÅltiges Schalterzeichen:  ',EOS
MSG_VAL  db	 BEL,'ÕÕ> Fehlender Wert:  ',EOS
else
MSG_SEP  db	 BEL,'ÕÕ> Missing separator:  ',EOS
MSG_UNK  db	 BEL,'ÕÕ> Unknown keyword on DEVICE= line in CONFIG.SYS:  ',EOS
MSG_SWERR db	 BEL,'ÕÕ> Invalid switch character:  ',EOS
MSG_VAL  db	 BEL,'ÕÕ> Missing value:  ',EOS
endif				; IFDEF LANG_GR

	 public  MSG_INVALIDOK,MSG_CRLF
ifdef LANG_GR
MSG_INVALIDOK db 'Taste A bricht Installation ab, andere Taste Åbergeht SchlÅsselwort: ' , EOS
else
MSG_INVALIDOK db 'Press A to Abort installation, any other key to ignore keyword: ' , EOS
endif

MSG_CRLF      db CR , LF , EOS

if @OEM_MISC
	 public  MSG_UNKPRO,MSG_EOLERR
ifdef LANG_GR
MSG_UNKPRO db	 BEL,'ÕÕ> unbekannter Schalter in Profildatei:  ',EOS
MSG_EOLERR db	 BEL,'ÕÕ> unzulÑssiges Zeilenende in Profildatei.',CR,LF,EOS
else
MSG_UNKPRO db	 BEL,'ÕÕ> Unknown keyword in profile:  ',EOS
MSG_EOLERR db	 BEL,'ÕÕ> Invalid line ending in profile.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_MISC

	 public  MSG_INVERR
ifdef LANG_GR
MSG_INVERR db	 BEL,'ÕÕ> ungÅltige Adresse oder LÑnge.',CR,LF,EOS
else
MSG_INVERR db	 BEL,'ÕÕ> Invalid address or length.',CR,LF,EOS
endif				; IFDEF LANG_GR

if @OEM_EMS
	 public  MSG_CMDCHK_EMSEXT
ifdef LANG_GR
MSG_CMDCHK_EMSEXT db BEL,'ÕÕ> EMS= mit EXT= gemeinsam -- nur alternativ zulÑssig.',CR,LF,EOS
else
MSG_CMDCHK_EMSEXT db BEL,'ÕÕ> EMS= and EXT= both specified -- use at most one of them.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_EMS

	 public  MSG_OVF
ifdef LANG_GR
MSG_OVF  db	 BEL,'ÕÕ> Wert au·erhalb des Bereichs:  ',EOS
else
MSG_OVF  db	 BEL,'ÕÕ> Value out of range:  ',EOS
endif				; IFDEF LANG_GR

endif				; IF @OEM_SYS eq @OEMSYS_HPRS


if @OEM_BCF
	 public  MSG_BCF_FCRC,MSG_BCF_BCRC,MSG_BCF_CMD,MSG_BCF_INT
	 public  MSG_BCF_INT1,MSG_BCF_DBG,MSG_BCF_DBG1,MSG_BCF_ARGERR
	 public  MSG_BCFERR,MSG_AUTOBCF_INST,MSG_AUTOBCF_TERSE
	 public  MSG_AUTOBCF_ARGERR,MSG_AUTOBCF_128K,MSG_AUTOBCF_64K
ifdef LANG_GR
MSG_BCF_FCRC db  BEL,'ÕÕ> BCF-Datei beschÑdigt.',CR,LF,EOS
MSG_BCF_BCRC db  BEL,'ÕÕ> BCF-Datei falsch fÅr den Host-Rechner.',CR,LF,EOS
MSG_BCF_CMD  db  BEL,'ÕÕ> BCF-Datei hat falschen Befehl.',CR,LF,EOS
MSG_BCF_INT  db  BEL,'ÕÕ> BCF-Datei 0000:000'
MSG_BCF_INT1 db  '_ pa·t nicht',CR,LF,EOS
MSG_BCF_DBG  db  TAB,TAB,TAB,'BCF-Debug '
MSG_BCF_DBG1 db  '__.',CR,EOS
MSG_BCF_ARGERR db BEL,'ÕÕ> BCF-Datei hat falsches Argument.',CR,LF,EOS
MSG_BCFERR db	 BEL,'ÕÕ> unbehandelter Interrupt in BCF-Datei.',CR,LF,EOS
MSG_AUTOBCF_TERSE db BEL,'ÕÕ> BIOS Komprimierungsdatei nicht gefunden. Bitte MAXIMIZE wiederholen.',CR,LF,EOS
MSG_AUTOBCF_INST db BEL,'ÕÕ> ',@OEM_TEXT,' konnte keine gÅltige BIOS Komprimierungs-',CR,LF
		 db	'    Datei (BCF) finden. Bitte INSTALL oder UPDATE von der',CR,LF
		 db	'    ',@OEM_TEXT,' Installationsdiskette wiederholen.',CR,LF,EOS
MSG_AUTOBCF_ARGERR db BEL,'ÕÕ> ',@OEM_TEXT,' konnte keine gÅltige BIOS Komprimierungs-',CR,LF
		 db	'    Datei (BCF) finden. Bei VerfÅgbarkeit kînnen Sie diese',CR,LF
		 db	'    per Download vom Qualitas Bulletin Board, Rufnummer',CR,LF
		 db	'    +1 (301) 907-8030 oder Åber CompuServe (GO PCVENA) erhalten.',CR,LF
		   db	  '    128k BIOS CRC-Datei wÑre @'
MSG_AUTOBCF_128K   db '____.BCF, 64K BIOS-CRC @'
else
MSG_BCF_FCRC db  BEL,'ÕÕ> BCF file is corrupted.',CR,LF,EOS
MSG_BCF_BCRC db  BEL,'ÕÕ> BCF file is not correct for host machine.',CR,LF,EOS
MSG_BCF_CMD  db  BEL,'ÕÕ> BCF file command error.',CR,LF,EOS
MSG_BCF_INT  db  BEL,'ÕÕ> BCF file 0000:000'
MSG_BCF_INT1 db  '_ mismatch.',CR,LF,EOS
MSG_BCF_DBG  db  TAB,TAB,TAB,'BCF Debug '
MSG_BCF_DBG1 db  '__.',CR,EOS
MSG_BCF_ARGERR db BEL,'ÕÕ> BCF file argument error.',CR,LF,EOS
MSG_BCFERR db	 BEL,'ÕÕ> Unhandled interrupt in BCF file.',CR,LF,EOS
MSG_AUTOBCF_TERSE db BEL,'ÕÕ> BIOS Compression File not found.  Please run MAXIMIZE.',CR,LF,EOS
MSG_AUTOBCF_INST db BEL,'ÕÕ> ',@OEM_TEXT,' was unable to locate a valid BIOS Compression',CR,LF
		 db	'    file (BCF).  Please re-run INSTALL or UPDATE from your',CR,LF
		 db	'    ',@OEM_TEXT,' diskette.',CR,LF,EOS
MSG_AUTOBCF_ARGERR db BEL,'ÕÕ> ',@OEM_TEXT,' was unable to locate a valid BIOS Compression',CR,LF
		 db	'    file (BCF).  If the necessary BCF is available you may',CR,LF
		 db	'    download it from the Qualitas Bulletin Board at',CR,LF
		 db	'    (301) 907-8030 or through CompuServe (GO PCVENA).',CR,LF
		   db	  '    128K BIOS CRC file would be @'
MSG_AUTOBCF_128K   db '____.BCF, 64K BIOS CRC @'
endif				; IFDEF LANG_GR
MSG_AUTOBCF_64K    db '____.BCF',CR,LF,EOS
endif				; IF @OEM_BCF


if @OEM_DEBUG
	 public  MSG_ERRCPQ,MSG_ERRCPQ1
MSG_ERRCPQ db	 BEL,'ÕÕ> Interrupt '
ifdef LANG_GR
MSG_ERRCPQ1 db	 '__h Konvertierungsfehler bei ROM-Komprimierung.',CR,LF,EOS
else
MSG_ERRCPQ1 db	 '__h failed to convert during ROM compress.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_ERRSROM,MSG_ERRSROM1
MSG_ERRSROM db	 BEL,'ÕÕ> Interrupt '
ifdef LANG_GR
MSG_ERRSROM1 db  '__h Konvertierungsfehler bei UNSHADOWROM.',CR,LF,EOS
else
MSG_ERRSROM1 db  '__h failed to convert during UNSHADOWROM.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_SHDROM1,MSG_SHDROM2,MSG_SHDROM3,MSG_SHDROM4
ifdef LANG_GR
MSG_SHDROM1 db	 BEL,'ÕÕ> kein ROM bei E000 oder E800 vorhanden.',CR,LF,EOS
MSG_SHDROM2 db	 BEL,'ÕÕ> kein ROM bei C000 vorhanden.',CR,LF,EOS
MSG_SHDROM3 db	 BEL,'ÕÕ> ROM bei C000 und E000 oder E800 ungleich.',CR,LF,EOS
MSG_SHDROM4 db	 EOS
else
MSG_SHDROM1 db	 BEL,'ÕÕ> No ROM at E000 or E800.',CR,LF,EOS
MSG_SHDROM2 db	 BEL,'ÕÕ> No ROM at C000.',CR,LF,EOS
MSG_SHDROM3 db	 BEL,'ÕÕ> ROM at C000 and E000 or E800 not same.',CR,LF,EOS
MSG_SHDROM4 db	 EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_DEBUG

if @OEM_DPMI
	 public  MSG_DPMI
ifdef LANG_GR
MSG_DPMI db	 BEL,'ÕÕ> ungÅltige DPMIMEM Option.',CR,LF,EOS
else
MSG_DPMI db	 BEL,'ÕÕ> Invalid DPMIMEM option.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_DPMI

if @OEM_EMS
	 public  MSG_CMDCHK_FRM1
if @OEM_SYS eq @OEMSYS_HPRS
ifdef LANG_GR
MSG_CMDCHK_FRM1 db BEL,'ÕÕ> ungÅltige Adresse angegeben,',CR,LF
	 db	       '    mu· Mehrfaches von 16 KB sein.',CR,LF,EOS
else
MSG_CMDCHK_FRM1 db BEL,'ÕÕ> Invalid Address specified',CR,LF
	 db	       '    Must be a multiple of 16 KB',CR,LF,EOS
endif				; IFDEF LANG_GR
else
	 public  MSG_CMDCHK_INC1
ifdef LANG_GR
MSG_CMDCHK_FRM1 db BEL,'ÕÕ> FRAME Wert mu· im 16 KB-Raster liegen.',CR,LF,EOS
MSG_CMDCHK_INC1 db BEL,'ÕÕ> ungÅltige Adresse angegeben,',CR,LF
	 db	       '    mu· Mehrfaches von 16 KB sein.',CR,LF,EOS
else
MSG_CMDCHK_FRM1 db BEL,'ÕÕ> FRAME value must be on a 16KB boundary.',CR,LF,EOS
MSG_CMDCHK_INC1 db BEL,'ÕÕ> Invalid address specified',CR,LF
	 db	       '    Must be a multiple of 16 KB',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
endif				; IF @OEM_EMS

if @OEM_WTK
	 public  MSG_CMDCHK_WTK
ifdef LANG_GR
MSG_CMDCHK_WTK	db BEL,'ÕÕ> Weitek FPA nicht gefunden.',CR,LF,EOS
else
MSG_CMDCHK_WTK	db BEL,'ÕÕ> Weitek FPA not found.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_WTK

if @OEM_MISC
	 public  MSG_POPEN
ifdef LANG_GR
MSG_POPEN db	 BEL,'ÕÕ> kann Profil-Datei nicht erreichen.',CR,LF,EOS
else
MSG_POPEN db	 BEL,'ÕÕ> Unable to access profile.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_MISC

;;;;;;;if @OEM_BCF
;;;;;;;  public  MSG_BCFOPEN
;;;;;;;ifdef LANG_GR
;;;;;;;MSG_BCFOPEN db	 BEL,'ÕÕ> kann BCF-Datei nicht erreichen.',CR,LF,EOS
;;;;;;;else
;;;;;;;MSG_BCFOPEN db	 BEL,'ÕÕ> Unable to access BCF file.',CR,LF,EOS
;;;;;;;endif				; IFDEF LANG_GR
;;;;;;;endif				; IF @OEM_BCF
;;;;;;;
if @OEM_SOFT
	 public  MSG_UNKSYS
ifdef LANG_GR
MSG_UNKSYS db	 BEL,'ÕÕ> unbekannter Systemtyp nach SYS=.',CR,LF,EOS
else
MSG_UNKSYS db	 BEL,'ÕÕ> Unknown system type following SYS=.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_SOFT

if @OEM_DEBUG
	 public  MSG_LEXEC,MSG_EXECUP,MSG_EXTLOD
ifdef LANG_GR
MSG_LEXEC db	 BEL,'ÕÕ> kann Lade-Modul nicht erreichen.',CR,LF,EOS
MSG_EXECUP db	 BEL,'ÕÕ> kann Lade-Modul nicht in Extended Memory verlagern.',CR,LF,EOS
MSG_EXTLOD db	 BEL,'ÕÕ> EXTSIZE= mu· allen LOAD= Anweisungen vorangehen.',CR,LF,EOS
else
MSG_LEXEC db	 BEL,'ÕÕ> Unable to access load module.',CR,LF,EOS
MSG_EXECUP db	 BEL,'ÕÕ> Unable to move load module to extended memory.',CR,LF,EOS
MSG_EXTLOD db	 BEL,'ÕÕ> EXTSIZE= must precede all LOAD= statements.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_DEBUG


	 public  MSG_ERRPRO,MSG_ERRPRO1
	 public  MSG_ERRTIM,MSG_ERRTIM1
	 public  MSG_ERRMOV,MSG_ERRMOV1
	 public  MSG_ERRMOV2,MSG_ERRMOV3,MSG_ERRMOV4
if @OEM_SYS eq @OEMSYS_HPRS
ifdef LANG_GR
MSG_ERRPRO db	 BEL,'ÕÕ> ',@OEM_TEXT,' kann nicht in Protected-Mode schalten -- Fehlercode '
MSG_ERRPRO1 db	 '__.',CR,LF,EOS
MSG_ERRTIM db	 BEL,'ÕÕ> ',@OEM_TEXT,' kann erweiterten Speicher nicht messen -- Fehlercode '
MSG_ERRTIM1 db	 '__.',CR,LF,EOS
MSG_ERRMOV db	 BEL,'ÕÕ> ',@OEM_TEXT,' kann erweiterten Speicher nicht belegen -- Fehlercode '
MSG_ERRMOV1 db	 '__.',CR,LF,EOS
else
MSG_ERRPRO db	 BEL,'ÕÕ> ',@OEM_TEXT,' unable to enter protected mode -- error code '
MSG_ERRPRO1 db	 '__.',CR,LF,EOS
MSG_ERRTIM db	 BEL,'ÕÕ> ',@OEM_TEXT,' unable to time extended memory -- error code '
MSG_ERRTIM1 db	 '__.',CR,LF,EOS
MSG_ERRMOV db	 BEL,'ÕÕ> ',@OEM_TEXT,' unable to access extended memory -- error code '
MSG_ERRMOV1 db	 '__.',CR,LF,EOS
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
MSG_ERRPRO db	 BEL,'ÕÕ> kann nicht in Protected-Mode schalten -- Fehlercode '
MSG_ERRPRO1 db	 '__.',CR,LF,EOS
MSG_ERRTIM db	 BEL,'ÕÕ> kann erweiterten Speicher nicht messen -- Fehlercode '
MSG_ERRTIM1 db	 '__.',CR,LF,EOS
MSG_ERRMOV db	 BEL,'ÕÕ> kann Code nicht in erweiterten Speicher verlagern -- Fehlercode '
MSG_ERRMOV1 db	 '__.',CR,LF,'    Adresse = '
MSG_ERRMOV2 db	 '____'
MSG_ERRMOV3 db	 '____, ZÑhler = '
MSG_ERRMOV4 db	 '____.',CR,LF,EOS
else
MSG_ERRPRO db	 BEL,'ÕÕ> Unable to enter protected mode -- error code '
MSG_ERRPRO1 db	 '__.',CR,LF,EOS
MSG_ERRTIM db	 BEL,'ÕÕ> Unable to time extended memory -- error code '
MSG_ERRTIM1 db	 '__.',CR,LF,EOS
MSG_ERRMOV db	 BEL,'ÕÕ> Unable to move code to extended memory -- error code '
MSG_ERRMOV1 db	 '__.',CR,LF,'    Address = '
MSG_ERRMOV2 db	 '____'
MSG_ERRMOV3 db	 '____, Count = '
MSG_ERRMOV4 db	 '____.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_HPRS


	 public  MSG_COPYRIGHT,MSG_COPYRIGHT_LEN,MSG_COPY
MSG_COPYRIGHT db CR,LF
if @OEM_SYS eq @OEMSYS_OL2
ifdef LANG_GR
MSG_COPY db	 'Memory Manager'
else
MSG_COPY db	 'Memory Manager'
endif				; IFDEF LANG_GR
	 db	 '-- Version '
else
MSG_COPY db	 @OEM_TEXT
	 db	 (MSG_COPY+15-$) dup (' '),'-- Version '
endif				; IF @OEM_SYS eq @OEMSYS_OL2
if @OEM_SYS eq @OEMSYS_HPRS
	 db	 VERS_HP,'.0'
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
	 db	 VERS_H,'.',VERS_T,VERS_U
if @OEM_BETA
	 db	 '.',BETA_H,BETA_T,BETA_U,'·'
else
	 db	 VERSLTR1
endif				; IF @OEM_BETA
	 db	 ' -- ',@OEM_SUBT,CR,LF
	 db	 '   (C) Copyright 1987-98 Qualitas, Inc.'
ifdef LANG_GR
	 db	 '  Alle Rechte vorbehalten.',CR,LF
else
	 db	 '  All rights reserved.',CR,LF
endif				; IFDEF LANG_GR
if @OEM_SYS eq @OEMSYS_OLI
	 db	 '   Copyright (C) Olivetti Inc., 1989-98  All Rights Reserved',CR,LF
endif				; IF @OEM_SYS eq @OEMSYS_OLI
	 db	 EOS
MSG_COPYRIGHT_LEN equ $-MSG_COPYRIGHT


	 public  MSG_ABORT
ifdef LANG_GR
MSG_ABORT db	 BEL,'ÕÕ> Sie haben die Alt-Taste betÑtigt.',CR,LF,EOS
else
MSG_ABORT db	 BEL,'ÕÕ> Alt-key pressed.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_NOT386,MSG_NOTVM
ifdef LANG_GR
MSG_NOT386 db	 BEL,'ÕÕ> falscher Maschinen-Typ,',CR,LF
	 db	     '    erfordert einen 80386.',CR,LF,EOS
MSG_NOTVM db	 BEL,'ÕÕ> virtuelle Maschine schon belegt,',CR,LF
	 db	     '    entfernen Sie die betreffende Software.',CR,LF,EOS
else
MSG_NOT386 db	 BEL,'ÕÕ> Wrong machine type',CR,LF
	 db	     '    Must run on an 80386.',CR,LF,EOS
MSG_NOTVM db	 BEL,'ÕÕ> Virtual Machine already in use',CR,LF
	 db	     '    Remove software using virtual machine.',CR,LF,EOS
endif				; IFDEF LANG_GR


	 public  MSG_NOROOM
ifdef LANG_GR
MSG_NOROOM db	 BEL,'ÕÕ> kein Seitenrahmen (PageFrame) verfÅgbar,',CR,LF
	 db	     '    Ñndern Sie die Hardware entsprechend.',CR,LF,EOS
else
MSG_NOROOM db	 BEL,'ÕÕ> No Page Frame Available',CR,LF
	 db	     '    Reconfigure hardware to make a page frame available.',CR,LF,EOS
endif				; IFDEF LANG_GR
ife @OEM_SOFT
	 public  MSG_NOFRAME
ifdef LANG_GR
MSG_NOFRAME db	 BEL,'ÕÕ> FRAME-Einstellung Åberlappt Hardware-Adressraum',CR,LF
else
MSG_NOFRAME db	 BEL,'ÕÕ> FRAME value overlaps accessory hardware',CR,LF
endif				; IFDEF LANG_GR
if @OEM_SYS eq @OEMSYS_HPRS
ifdef LANG_GR
	 db	     '    nehmen Sie einen anderen FRAME-Wert in CONFIG.SYS.',CR,LF,EOS
else
	 db	     '    Specify a different FRAME value in CONFIG.SYS.',CR,LF,EOS
endif				; IFDEF LANG_GR
else
	 db	 EOS
endif				; IF @OEM_SYS eq @OEMSYS_HPRS
endif				; IFE @OEM_SOFT


	 public  MSG_WSFULL,MSG_NOTDRV
ifdef LANG_GR
MSG_WSFULL db	 BEL,'ÕÕ> zu wenig Extended Memory verfÅgbar,',CR,LF
	 db	     '    geben Sie anderen Programmen kleineren Anteil.',CR,LF,EOS
MSG_NOTDRV db	 BEL,'ÕÕ> Åbergeordneter EMS-Verwalter gefunden,',CR,LF
else
MSG_WSFULL db	 BEL,'ÕÕ> Insufficient Extended Memory Available',CR,LF
	 db	     '    Allocate less extended memory to other programs.',CR,LF,EOS
MSG_NOTDRV db	 BEL,'ÕÕ> Preceding EMS manager found',CR,LF
endif				; IFDEF LANG_GR
if @OEM_SYS eq @OEMSYS_HPRS
ifdef LANG_GR
	 db	     '    bitte entfernen, oder setzen Sie die ',@OEM_TEXT,'-Grî·e auf 0 (Null).',CR,LF,EOS
else
	 db	     '    Remove it or set ',@OEM_TEXT,' size to zero',CR,LF,EOS
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
	 db	     '    bitte entfernen, oder setzen Sie EMS=0',CR,LF,EOS
else
	 db	     '    Remove it or use EMS=0',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_HPRS

if @OEM_SYS eq @OEMSYS_HPRS
	 public  MSG_EMSFULL,MSG_NOEMS
ifdef LANG_GR
MSG_EMSFULL  db  BEL,'ÕÕ> wandle allen verfÅgbaren Speicher um, kann aber',CR,LF
	 db	     '    zu wenig an gefordertem ExPanded Memory liefern',CR,LF,EOS
MSG_NOEMS db	 BEL,'ÕÕ> kann kein ExPanded Memory anlegen',CR,LF,EOS
else
MSG_EMSFULL  db  BEL,'ÕÕ> Converting all available memory, but',CR,LF
	 db	     '    unable to supply all requested expanded memory',CR,LF,EOS
MSG_NOEMS db	 BEL,'ÕÕ> Unable to create expanded memory',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_HPRS


if @OEM_SYS eq @OEMSYS_QUAD386
	 public  MSG_XQUAD,MSG_NOTINST
ifdef LANG_GR
MSG_XQUAD   db	 BEL,'ÕÕ> Dieser Treiber kann nur auf Quadram 386XTs installiert werden.',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' nicht installiert',CR,LF
else
MSG_XQUAD   db	 BEL,'ÕÕ> This driver cannot be installed on non-Quadram 386XT machines.',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' not installed',CR,LF
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_CA
	 public  MSG_XCA,MSG_NOTINST
ifdef LANG_GR
MSG_XCA     db	 BEL,'ÕÕ> Dieser Treiber kann nur auf CompuAdd installiert werden.',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' nicht installiert',CR,LF
else
MSG_XCA     db	 BEL,'ÕÕ> This driver cannot be installed on non-CompuAdd machines.',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' not installed',CR,LF
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_ASEM
	 public  MSG_XASEM,MSG_NOTINST
ifdef LANG_GR
MSG_XASEM   db	 BEL,'ÕÕ>  Diese Version von ',@OEM_TEXT,' kann nur auf ASEM benutzt werden',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' nicht installiert',CR,LF
else
MSG_XASEM   db	 BEL,'ÕÕ> This version of ',@OEM_TEXT,' may be used on ASEM machines only',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' not installed',CR,LF
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_AM1
	 public  MSG_XAM1,MSG_NOTINST
ifdef LANG_GR
MSG_XAM1  db	 BEL,'ÕÕ>  Diese Version von ',@OEM_TEXT,' fordert einen MC-Adapter mit ID 7430',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' nicht installiert',CR,LF
else
MSG_XAM1  db	 BEL,'ÕÕ> This version of ',@OEM_TEXT,' requires a Micro Channel adapter with ID 7430',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' not installed',CR,LF
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_AM2
	 public  MSG_XAM1,MSG_NOTINST
	 ; The following message should be AM1 (not AM2)
ifdef LANG_GR
MSG_XAM1  db	 BEL,'ÕÕ>  Diese Version von ',@OEM_TEXT,' fordert eine AMKLY-Speicherplatine',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' nicht installiert',CR,LF
else
MSG_XAM1  db	 BEL,'ÕÕ> This version of ',@OEM_TEXT,' requires an AMKLY memory board',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' not installed',CR,LF
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_AM3
	 public  MSG_XAM3,MSG_NOTINST
ifdef LANG_GR
MSG_XAM3  db	 BEL,'ÕÕ>  Diese Version von ',@OEM_TEXT,' fordert eine AMKLY-EISA-Maschine.',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' nicht installiert',CR,LF
else
MSG_XAM3  db	 BEL,'ÕÕ> This version of ',@OEM_TEXT,' requires an AMKLY EISA machine.',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' not installed',CR,LF
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_EPSON
	 public  MSG_XEPSON,MSG_NOTINST
ifdef LANG_GR
MSG_XEPSON  db	 BEL,'ÕÕ>  Diese Version von ',@OEM_TEXT,' kann nur auf Epson-PCs laufen',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' nicht installiert',CR,LF
else
MSG_XEPSON  db	 BEL,'ÕÕ> This version of ',@OEM_TEXT,' may be used on EPSON machines only',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' not installed',CR,LF
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_TOSH
	 public  MSG_XTOSH,MSG_NOTINST
ifdef LANG_GR
MSG_XTOSH   db	 BEL,'ÕÕ> Dieser Treiber kann nur auf Toshiba 5100-Maschinen installiert werden.',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' nicht installiert',CR,LF
else
MSG_XTOSH   db	 BEL,'ÕÕ> This driver cannot be installed on non-Toshiba 5100 machines.',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' not installed',CR,LF
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_AST386
	 public  MSG_XAST,MSG_NOTINST
ifdef LANG_GR
MSG_XAST    db	 BEL,'ÕÕ> Dieser Treiber kann nur nur auf AST-Maschinen installiert werden.',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' nicht installiert',CR,LF
else
MSG_XAST    db	 BEL,'ÕÕ> This driver cannot be installed on non-AST machines.',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' not installed',CR,LF
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_HPRS
	 public  MSG_XHPRS,MSG_NOTINST
ifdef LANG_GR
MSG_XHPRS   db	 BEL,'ÕÕ> Dieser Treiber kann nur nur auf HP-Maschinen installiert werden.',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' nicht installiert',CR,LF
else
MSG_XHPRS   db	 BEL,'ÕÕ> This driver cannot be installed on non-HP machines',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' not installed',CR,LF
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_GRID
	 public  MSG_XGRID,MSG_NOTINST
ifdef LANG_GR
MSG_XGRID   db	 BEL,'ÕÕ> Dieser Treiber kann nur auf GRiD-Maschinen installiert werden.',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' nicht installiert',CR,LF
else
MSG_XGRID   db	 BEL,'ÕÕ> This driver cannot be installed on non-GRiD machines',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' not installed',CR,LF
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_OLI
	 public  MSG_XOLI,MSG_NOTINST
ifdef LANG_GR
MSG_XOLI    db	 BEL,'ÕÕ> ',@OEM_TEXT,' kann nur auf OLIVETTI oder AT&T 80386 benutzt werden',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' nicht installiert',CR,LF
else
MSG_XOLI    db	 BEL,'ÕÕ> ',@OEM_TEXT,' may be used on OLIVETTI or AT&T 80386 class machines only',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' not installed',CR,LF
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_OL2
	 public  MSG_XOLI,MSG_NOTINST
ifdef LANG_GR
MSG_XOLI    db	 BEL,'ÕÕ> Memory-Manager kann auf dieser Maschine nicht benutzt werden',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> Memory-Manager nicht installiert',CR,LF
else
MSG_XOLI    db	 BEL,'ÕÕ> Memory Manager may not be used on this machine',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> Memory Manager not installed',CR,LF
endif				; IFDEF LANG_GR
elseif @OEM_SYS eq @OEMSYS_NEC
	 public  MSG_XNEC,MSG_NOTINST
ifdef LANG_GR
MSG_XNEC    db	 BEL,'ÕÕ>  Diese Version von ',@OEM_TEXT,' kann nur auf NEC-PCs laufen',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' nicht installiert',CR,LF
else
MSG_XNEC    db	 BEL,'ÕÕ> This version of ',@OEM_TEXT,' may be used on NEC machines only',CR,LF,EOS
MSG_NOTINST db	 BEL,'ÕÕ> ',@OEM_TEXT,' not installed',CR,LF
endif				; IFDEF LANG_GR
else
	 public  MSG_NOTINST
ifdef LANG_GR
MSG_NOTINST db	 BEL,'ÕÕ> Memory-Manager NICHT installiert',CR,LF
else
MSG_NOTINST db	 BEL,'ÕÕ> Memory manager NOT installed.',CR,LF
endif				; IFDEF LANG_GR
				; IF @OEM_SYS eq @OEMSYS_NEC
				; IF @OEM_SYS eq @OEMSYS_OL2
				; IF @OEM_SYS eq @OEMSYS_OLI
				; IF @OEM_SYS eq @OEMSYS_GRID
				; IF @OEM_SYS eq @OEMSYS_HPRS
				; IF @OEM_SYS eq @OEMSYS_AST386
				; IF @OEM_SYS eq @OEMSYS_TOSH
				; IF @OEM_SYS eq @OEMSYS_CA
				; IF @OEM_SYS eq @OEMSYS_EPSON
				; IF @OEM_SYS eq @OEMSYS_AM3
				; IF @OEM_SYS eq @OEMSYS_AM2
				; IF @OEM_SYS eq @OEMSYS_AM1
				; IF @OEM_SYS eq @OEMSYS_ASEM
endif				; IF @OEM_SYS eq @OEMSYS_QUAD386
	 public  MSG_PRESS
ifdef LANG_GR
MSG_PRESS db	     '    weiter mit beliebiger Taste...',CR,LF,EOS
else
MSG_PRESS db	     '    Press any key to continue...',CR,LF,EOS
endif				; IFDEF LANG_GR

if @OEM_SYS eq @OEMSYS_ILIM
	 public  MSG_NOINBRDPC,MSG_NOINBRDAT,MSG_NOINBRDPS
ifdef LANG_GR
MSG_NOINBRDPC db BEL,'ÕÕ> INBRDPC.SYS mu· zuerst geladen werden.',CR,LF,EOS
MSG_NOINBRDAT db BEL,'ÕÕ> INBRDAT.SYS mu· zuerst geladen werden.',CR,LF,EOS
MSG_NOINBRDPS db BEL,'ÕÕ> Dieser Treiber kann nur in Verbindung mit INTEL-',CR,LF
	      db     '    Speicherplatinen installiert werden.',CR,LF,EOS
else
MSG_NOINBRDPC db BEL,'ÕÕ> INBRDPC.SYS must be loaded first.',CR,LF,EOS
MSG_NOINBRDAT db BEL,'ÕÕ> INBRDAT.SYS must be loaded first.',CR,LF,EOS
MSG_NOINBRDPS db BEL,'ÕÕ> This driver can be installed in conjunction with',CR,LF
	      db     '    Intel memory boards only.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_ILIM

if @OEM_SYS eq @OEMSYS_3COM
	 public  MSG_NO3COM
ifdef LANG_GR
MSG_NO3COM db	 BEL,'ÕÕ> Dieser Treiber kann nur in Verbindung mit 3COM',CR,LF
	   db	     '    installiert werden.',CR,LF,EOS
else
MSG_NO3COM db	 BEL,'ÕÕ> This driver can be installed in conjunction with 3COM only.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_3COM

if @OEM_SYS eq @OEMSYS_SHS
	 public  MSG_NOOMNI
ifdef LANG_GR
MSG_NOOMNI db	 BEL,'ÕÕ> Dieser Treiber kann nur in Verbindung mit OMNIVIEW',CR,LF
	   db	     '    installiert werden.',CR,LF,EOS
else
MSG_NOOMNI db	 BEL,'ÕÕ> This driver can be installed in conjunction with OMNIVIEW only.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_SHS

	 public  MSG_BUSMASTER
ifdef LANG_GR
MSG_BUSMASTER db BEL,'ÕÕ> ',@OEM_TEXT,' hat eine Busmaster-Einheit entdeckt, die keinen Plat-',CR,LF
	 db	     '    ten-Transfer ins HiDOS unterstÅtzt. Das kann in bestimmten Umgebungen',CR,LF
	 db	     '    zu Datenverlusten fÅhren. In der README-Datei finden Sie im Abschnitt',CR,LF
	 db	     '    BUSMASTER-EINHEITEN weitere Informationen.',CR,LF
	 db	 EOS
else
MSG_BUSMASTER db BEL,'ÕÕ> ',@OEM_TEXT,' has detected a busmaster device which does not support',CR,LF
	 db	     '    disk transfers into high DOS memory.  This may result in loss of data in',CR,LF
	 db	     '    specific environments.  Consult the "Busmastering Devices" section of the',CR,LF
	 db	     '    README file for more information.',CR,LF
	 db	 EOS
endif				; IFDEF LANG_GR

if @OEM_SIZE
	 public  MSG_SIZE_P1,MSG_SIZE_P2,MSG_SIZE_P3
ifdef LANG_GR
MSG_SIZE_P1 db	 BEL,'ÕÕ> zu wenig Extended Memory verfÅgbar:',CR,LF
	 db	 '   LoDOS Speicher     =      _'
else
MSG_SIZE_P1 db	 BEL,'ÕÕ> Insufficient extended memory available:',CR,LF
	 db	 '   Low  DOS memory    =      _'
endif				; IFDEF LANG_GR

	 public  MSG_SIZE_LOW
if @OEM_SYS eq @OEMSYS_AST386
MSG_SIZE_LOW db  ' KB',CR,LF
else
ifdef LANG_GR
MSG_SIZE_LOW db  ' KB (verwenden Sie NOLOW oder VIDMEM=A000-C000)',CR,LF
else
MSG_SIZE_LOW db  ' KB (use NOLOW or VIDMEM=A000-C000)',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_AST386

if @OEM_HIFILL
ifdef LANG_GR
	 db	 '   HiDOS Speicher     =      _'
else
	 db	 '   High DOS memory    =      _'
endif				; IFDEF LANG_GR

	 public  MSG_SIZE_OVR
ifdef LANG_GR
MSG_SIZE_OVR db  '    (verwenden Sie NOHIGH)',CR,LF
else
MSG_SIZE_OVR db  '    (use NOHIGH)',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_HIFILL
ifdef LANG_GR
	 db	 '   ROM Abbildung      =      _'
else
	 db	 '   ROM re-mapping     =      _'
endif				; IFDEF LANG_GR

	 public  MSG_SIZE_MAP
if @OEM_SYS eq @OEMSYS_AST386
MSG_SIZE_MAP db  CR,LF
else
ifdef LANG_GR
MSG_SIZE_MAP db  '    (verwenden Sie NOROM oder NOWARMBOOT)',CR,LF
else
MSG_SIZE_MAP db  '    (use NOROM or NOWARMBOOT)',CR,LF
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_AST386

ifdef LANG_GR
	 db	 '   Extended Memory    =      _'
else
	 db	 '   Extended memory    =      _'
endif				; IFDEF LANG_GR

	 public  MSG_SIZE_EXT
MSG_SIZE_EXT db  EOS

ifdef LANG_GR
MSG_SIZE_P2 db	 ', einschl.     _'
else
MSG_SIZE_P2 db	 ', including    _'
endif				; IFDEF LANG_GR

	 public  MSG_SIZE_PRV
if @OEM_XMS
ifdef LANG_GR
MSG_SIZE_PRV db  ' KB fÅr vorherige VDISK oder HMA',EOS
else
MSG_SIZE_PRV db  ' KB for preceding VDISK or HMA',EOS
endif				; IFDEF LANG_GR
else
ifdef LANG_GR
MSG_SIZE_PRV db  ' KB fÅr vorherige VDISK',EOS
else
MSG_SIZE_PRV db  ' KB for preceding VDISK',EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_XMS

MSG_SIZE_P3 db	 CR,LF
ifdef LANG_GR
	 db	 '   EMS Speicher       =      _'
else
	 db	 '   EMS      memory    =      _'
endif				; IFDEF LANG_GR

	 public  MSG_SIZE_EMM
MSG_SIZE_EMM db  CR,LF
ifdef LANG_GR
	 db	 '   Programmspeicher   =      _'
else
	 db	 '   Program storage    =      _'
endif				; IFDEF LANG_GR

	 public  MSG_SIZE_PRG
MSG_SIZE_PRG db  CR,LF
ifdef LANG_GR
	 db	 'gesamt erforderlich   =       '
else
	 db	 'Total needed          =       '
endif				; IFDEF LANG_GR

	 public  MSG_SIZE_REQ
MSG_SIZE_REQ db  ' KB',CR,LF
ifdef LANG_GR
	 db	 'gesamt verfÅgbar      =      _'
else
	 db	 'Total available       =      _'
endif				; IFDEF LANG_GR

	 public  MSG_SIZE_TOT
MSG_SIZE_TOT db  ' KB',CR,LF
ifdef LANG_GR
	 db	 '                         ƒƒƒƒƒ',CR,LF
	 db	 'reduziere Bedarf um          _'
else
	 db	 '                         ƒƒƒƒƒ',CR,LF
	 db	 'Reduce total needed by       _'
endif				; IFDEF LANG_GR

	 public  MSG_SIZE_DIF
MSG_SIZE_DIF db  ' KB',CR,LF
	 db	 EOS
endif				; IF @OEM_SIZE

	 public  MSG_POSBOOT
ifdef LANG_GR
MSG_POSBOOT db	 'System-Neustart, um POS-Werte zu Ñndern...',CR,LF,EOS
else
MSG_POSBOOT db	 'Rebooting system to change POS values...',CR,LF,EOS
endif				; IFDEF LANG_GR

if @OEM_WIN3
	 public  MSG_NOVXD
ifdef LANG_GR
MSG_NOVXD db	 BEL,'ÕÕ> kann die Datei ',@OEM_FILE,'.VxD nicht im selben Verzeichnis',CR,LF
	  db	     '    wie ',@OEM_FILE,'.SYS finden;',CR,LF
	 db	     '    schalte WINDOWS 3 UnterstÅtzung ab.',CR,LF
	 db	     '    weiter mit beliebiger Taste...',CR,LF,EOS
else
MSG_NOVXD db	 BEL,'ÕÕ> Unable to locate ',@OEM_FILE,'.VxD file in same directory as ',@OEM_FILE,'.SYS;',CR,LF
	 db	     '    Disabling support for Windows 3.',CR,LF
	 db	     '    Press any key to continue...',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_NOALTVXD
ifdef LANG_GR
MSG_NOALTVXD db  BEL,'ÕÕ> kann die Datei ',@OEM_FILE,'.VxD nicht finden',CR,LF
	 db	     '    schalte WINDOWS 3 UnterstÅtzung ab.',CR,LF
	 db	     '    weiter mit beliebiger Taste...',CR,LF,EOS
else
MSG_NOALTVXD db  BEL,'ÕÕ> Unable to locate ',@OEM_FILE,'.VxD file',CR,LF
	 db	     '    Disabling support for Windows 3.',CR,LF
	 db	     '    Press any key to continue...',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_WIN3

if @OEM_FLEXROM
	 public  MSG_NOFLEXFILE_PASS1
ifdef LANG_GR
MSG_NOFLEXFILE_PASS1 db  BEL,'ÕÕ> kann die Datei ',@FLEXFILE,' nicht im selben Verzeichnis',CR,LF
		     db      '    wie ',@OEM_FILE,'.SYS finden;',CR,LF,EOS
else
MSG_NOFLEXFILE_PASS1 db  BEL,'ÕÕ> Unable to locate ',@FLEXFILE,' in same directory as ',@OEM_FILE,'.SYS;',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_NOFLEXFILE_PASS2
ifdef LANG_GR
MSG_NOFLEXFILE_PASS2 db  BEL,'ÕÕ> Lese-Fehler bei ',@FLEXFILE,' im 2. Durchlauf.',CR,LF,EOS
else
MSG_NOFLEXFILE_PASS2 db  BEL,'ÕÕ> Error reading ',@FLEXFILE,' during pass 2.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_FF_XROOM
ifdef LANG_GR
MSG_FF_XROOM	db	 BEL,'ÕÕ> VGASWAP-Fehler: zu wenig Speicherplatz.',CR,LF,EOS
else
MSG_FF_XROOM	db	 BEL,'ÕÕ> VGASWAP error: not enough storage space.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_FF_XVER
ifdef LANG_GR
MSG_FF_XVER	 db	 BEL,'ÕÕ> VGASWAP-Fehler: ',@FLEXFILE,'-Version pa·t nicht.',CR,LF,EOS
else
MSG_FF_XVER	 db	 BEL,'ÕÕ> VGASWAP error: ',@FLEXFILE,' version mismatch.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_FF_ERR,MSG_FF_ERR1
ifdef LANG_GR
MSG_FF_ERR	db	 BEL,'ÕÕ> Fehler '
MSG_FF_ERR1	db	 '__ bei Video-Umsetzung.',CR,LF,EOS
else
MSG_FF_ERR	db	 BEL,'ÕÕ> Error '
MSG_FF_ERR1	db	 '__ during video translation.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_FF_XVID,MSG_FF_XVID1
ifdef LANG_GR
MSG_FF_XVID	db	 BEL,'ÕÕ> VGASWAP-Fehler: konnte Video-Bereichsanfang im '
MSG_FF_XVID1	db	 '__. Durchlauf nicht finden.',CR,LF,EOS
else
MSG_FF_XVID	db	 BEL,'ÕÕ> VGASWAP error: could not find video entry during pass '
MSG_FF_XVID1	db	 '__.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_PASS1_PAK
ifdef LANG_GR
MSG_PASS1_PAK	db	 '    VGASWAP abgeschaltet, weiter mit beliebiger Taste...',CR,LF,EOS
else
MSG_PASS1_PAK	db	 '    VGASWAP disabled, Press any key to continue...',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_VGASWAP_TWICE
ifdef LANG_GR
MSG_VGASWAP_TWICE db	 BEL,'ÕÕ> VGASWAP kann nicht zweimal aufgerufen werden, '
		  db	 'ich Åbergehe den zweiten Aufruf.',CR,LF,EOS
else
MSG_VGASWAP_TWICE db	 BEL,'ÕÕ> VGASWAP can not be invoked twice, '
		  db	 'ignoring second instance.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_FF_NOROM
ifdef LANG_GR
MSG_FF_NOROM	 db	 BEL,'ÕÕ> Achtung, NOROM hat Vorrang vor VGASWAP.',CR,LF,EOS
else
MSG_FF_NOROM	 db	 BEL,'ÕÕ> Warning, NOROM takes precedence over VGASWAP.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_FF_NORAM
ifdef LANG_GR
MSG_FF_NORAM	 db	 BEL,'ÕÕ> Achtung, RAM= hat Vorrang vor VGASWAP.',CR,LF,EOS
else
MSG_FF_NORAM	 db	 BEL,'ÕÕ> Warning, RAM= takes precedence over VGASWAP.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_FF_SHDROM
ifdef LANG_GR
MSG_FF_SHDROM	 db	 BEL,'ÕÕ> Achtung, SHADOWROM hat Vorrang vor VGASWAP.',CR,LF,EOS
else
MSG_FF_SHDROM	 db	 BEL,'ÕÕ> Warning, SHADOWROM takes precedence over VGASWAP.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_FF_ROM
ifdef LANG_GR
MSG_FF_ROM	 db	 BEL,'ÕÕ> Achtung, ROM= hat Vorrang vor VGASWAP.',CR,LF,EOS
else
MSG_FF_ROM	 db	 BEL,'ÕÕ> Warning, ROM= takes precedence over VGASWAP.',CR,LF,EOS
endif				; IFDEF LANG_GR

endif				; IF @OEM_FLEXROM

	 public  MSG_EISA_BAD,MSG_EISA_BAD1
ifdef LANG_GR
MSG_EISA_BAD db  BEL,'ÕÕ> Fehler aufgetreten mit EISA-Konfiguration -- Fehlercode '
else
MSG_EISA_BAD db  BEL,'ÕÕ> Error encountered with EISA configuration -- error code '
endif				; IFDEF LANG_GR
MSG_EISA_BAD1 db '__.',CR,LF,EOS

if @OEM_SYS eq @OEMSYS_RET
	 public  MSG_NOPSMEM
ifdef LANG_GR
MSG_NOPSMEM db	 BEL,'ÕÕ> kein Platz im HiDOS fÅr PERISCOPE-Speicher.',CR,LF,EOS
else
MSG_NOPSMEM db	 BEL,'ÕÕ> No room in high DOS for Periscope memory.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_SYS eq @OEMSYS_RET

if @OEM_HIFILL
	 public  MSG_DOS5
ifdef LANG_GR
MSG_DOS5 db	 BEL,'ÕÕ> DOS5 Schalter ist gegenstandslos; zur Aktivierung dieser Funktion',CR,LF
	 db	 ' fÅgen Sie in CONFIG.SYS den Eintrag DOS=UMB hinzu.',CR,LF,EOS
else
MSG_DOS5 db	 BEL,'ÕÕ> DOS5 keyword is obsolete; place DOS=UMB in the CONFIG.SYS file'
	 db	 ' to enable this feature.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_HIFILL

if @OEM_SOFT
	 public  MSG_NOIOWRAP
ifdef LANG_GR
MSG_NOIOWRAP db  BEL,'ÕÕ> NOIOWRAP Schalter ist gegenstandslos.',CR,LF,EOS
else
MSG_NOIOWRAP db  BEL,'ÕÕ> NOIOWRAP keyword is obsolete.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_SOFT

	 public  MSG_VDSERR
ifdef LANG_GR
MSG_VDSERR db	 BEL,'ÕÕ> Fehler von VDS Aufruf zurÅckerhalten.',CR,LF,EOS
else
MSG_VDSERR db	 BEL,'ÕÕ> Error returned from VDS call.',CR,LF,EOS
endif				; IFDEF LANG_GR

	 public  MSG_ABIOSERR
ifdef LANG_GR
MSG_ABIOSERR db  BEL,'ÕÕ> kann ABIOS nicht initialisieren. Rufen Sie MAXIMIZE auf',CR,LF
	 db	 '    zum Kopieren von ABIOS.SYS und *.BIO Dateien von der Referenzediskette.',CR,LF,EOS
else
MSG_ABIOSERR db  BEL,'ÕÕ> Unable to initialize ABIOS.  Run MAXIMIZE to copy',CR,LF
	 db	 '    ABIOS.SYS and *.BIO files from your reference diskette.',CR,LF,EOS
endif				; IFDEF LANG_GR

if @OEM_HIFILL
	 public  MSG_HPDARCHG,MSG_STACKRCHG,MSG_XBDARCHG
ifdef LANG_GR
MSG_HPDARCHG db  BEL,'ÕÕ> kann HPDA nicht in HiDOS verlagern. Bitte MAXIMIZE wiederholen.',CR,LF,EOS
MSG_STACKRCHG db  BEL,'ÕÕ> kann STACKS nicht in HiDOS verlagern. Bitte MAXIMIZE wiederholen.',CR,LF,EOS
MSG_XBDARCHG db  BEL,'ÕÕ> kann XBIOS Datenbereich nicht in HiDOS verlagern. Bitte MAXIMIZE wiederholen.',CR,LF,EOS
else
MSG_HPDARCHG db  BEL,'ÕÕ> Unable to move HPDA to high DOS.  Please re-run MAXIMIZE.',CR,LF,EOS
MSG_STACKRCHG db  BEL,'ÕÕ> Unable to move STACKS to high DOS.  Please re-run MAXIMIZE.',CR,LF,EOS
MSG_XBDARCHG db  BEL,'ÕÕ> Unable to move XBIOS data area to high DOS.  Please re-run MAXIMIZE.',CR,LF,EOS
endif				; IFDEF LANG_GR
endif				; IF @OEM_HIFILL

	 public  AZS_WORKING,AZS_BLNKING
ifdef LANG_GR
AZS_WORKING db	 ' Åberprufe BCF Datei...',0
else
AZS_WORKING db	 ' Validating BCF file...',0
endif				; IFDEF LANG_GR
AZS_BLNKING db	 '                       ',0

YDATA	 ends			; End YDATA segment

	 MEND			; End QMAX_MSG module
