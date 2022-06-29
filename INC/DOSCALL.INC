;' $Header:   P:/PVCS/MAX/INC/DOSCALL.INV   1.1   24 Jul 1997 16:23:38   BOB  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	All rights reserved.
;
; DOSCALL.INC
;
;	 PC-DOS INTERRUPT 21h FUNCTION CODES
;

.xcref @PTERM ,@KEYINE,@CHROUT,@AUXIN ,@AUXOUT,@LPTOUT,@DCONIO,@DCONIN	; 00-07
.xcref @KEYIN ,@STROUT,@BKEYIN,@KEYSTA,@CKEYIN,@DRESET,@SELDSK,@OPENF	; 08-0F
.xcref @CLOSF ,@SRCH1 ,@SRCH2 ,@DELEF ,@RDSEQ ,@WRSEQ ,@CREAF ,@RENMF	; 10-17
.xcref @CPM18 ,@GETDSK,@SETDTA,@FATADR,@FATAD2,@CPM1D ,@CPM1E ,@GETDPB	; 18-1F
.xcref @CPM20 ,@RDRND ,@WRRND ,@SIZEF ,@SETRND,@SETINT,@BLDPSP,@RDBLK	; 20-27
.xcref @WRBLK ,@PARSF ,@GETDTE,@SETDTE,@GETTME,@SETTME,@VERIFY,@GETDTA	; 28-2F
.xcref @DOSVER,@KEEPRC,@GETDP2,@CHKBRK,@DOSPTR,@GETINT,@FATAD3,@SWITCH	; 30-37
.xcref @GETCDI,@MKDIR ,@RMDIR ,@CHDIR ,@CREAF2,@OPENF2,@CLOSF2,@READF2	; 38-3F
.xcref @WRITF2,@DELEF2,@MOVFP2,@GSTMOD,@IOCTL2,@FHCOPY,@FHCREA,@GETDIR	; 40-47
.xcref @GETMEM,@RELMEM,@MODMEM,@EXEC  ,@GETRC ,@EXITRC,@FIND1 ,@FIND2	; 48-4F
.xcref @SETPSP,@GETPS0,@GETLST,@BP2DPB,@GETVRF,@BLDPS2,@RENMF2,@GSTDAT	; 50-57
.xcref @MACALG,@EXTERR,@TMPFIL,@NEWFIL,@FILACC				; 58-5F
.xcref @FIXPTH,        @GETPSP, 	       @GETXCD,@GSTGCP,@SETFHC	; 60-67
.xcref @COMFIL,@GSTSER, 	       @XOPCR2				; 68-6F

@PTERM	 equ	 00h	; Program terminate:  CS=>PSP
@KEYINE  equ	 01h	; Keyboard input w/wait & echo to AL
@CHROUT  equ	 02h	; Display output in DL to CON:
@AUXIN	 equ	 03h	; Serial input w/wait to AL
@AUXOUT  equ	 04h	; Serial output in DL
@LPTOUT  equ	 05h	; Printer output in DL
@DCONIO  equ	 06h	; Direct console i/o: If DL=FFh, AL<--, else <--DL
@DCONIN  equ	 07h	; Direct keyboard input w/o echo to AL
@KEYIN	 equ	 08h	; Keyboard input w/wait, w/o echo to AL
@STROUT  equ	 09h	; Print string at DS:DX
@BKEYIN  equ	 0Ah	; Buffered keyboard input to DS:DX
@KEYSTA  equ	 0Bh	; Check keyboard status (AL=FFh if char is available)
@CKEYIN  equ	 0Ch	; Clear keyboard buffer & invoke input as AL=1,6,7,8,A
@DRESET  equ	 0Dh	; Disk reset
@SELDSK  equ	 0Eh	; Select disk in DL (origin-0)
@OPENF	 equ	 0Fh	; Open file, FCB at DS:DX
@CLOSF	 equ	 10h	; Close file, FCB at DS:DX
@SRCH1	 equ	 11h	; Search for first dir entry, FCB at DS:DX
@SRCH2	 equ	 12h	; Search for next dir entry, FCB at DS:DX
@DELEF	 equ	 13h	; Delete file, FCB at DS:DX
@RDSEQ	 equ	 14h	; Sequential read, FCB at DS:DX
@WRSEQ	 equ	 15h	; Sequential write, FCB at DS:DX
@CREAF	 equ	 16h	; Create file, FCB at DS:DX
@RENMF	 equ	 17h	; Rename file, FCB at DS:DX
@CPM18	 equ	 18h	; CP/M compatibility
@GETDSK  equ	 19h	; Get default disk drive to AL (origin-0)
@SETDTA  equ	 1Ah	; Set disk transfer addr to DS:DX
@FATADR  equ	 1Bh	; Get allocation table info of default drive
@FATAD2  equ	 1Ch	; Get allocation table info of drive in DL
@CPM1D	 equ	 1Dh	; CP/M compatibility
@CPM1E	 equ	 1Eh	; CP/M compatibility
@GETDPB  equ	 1Fh	; Return DS:BX ==> drive parameter block for default drive
@CPM20	 equ	 20h	; CP/M compatibility
@RDRND	 equ	 21h	; Read random, FCB at DS:DX to DTA
@WRRND	 equ	 22h	; Write random, FCB at DS:DX from DTA
@SIZEF	 equ	 23h	; Get file size, FCB at DS:DX
@SETRND  equ	 24h	; Set random record field, FCB at DS:DX
@SETINT  equ	 25h	; Set interrupt vector in AL to DS:DX
@BLDPSP  equ	 26h	; Create new program segment prefix
@RDBLK	 equ	 27h	; Read block random, FCB at DS:DX, CX=rec cnt
@WRBLK	 equ	 28h	; Write block random, FCB at DS:DX, CX=rec cnt
@PARSF	 equ	 29h	; Parse filename at DS:SI to ES:DI
@GETDTE  equ	 2Ah	; Get system date into CX:DX
@SETDTE  equ	 2Bh	; Set system date from CX:DX
@GETTME  equ	 2Ch	; Get system time into CX:DX
@SETTME  equ	 2Dh	; Set system time from CX:DX
@VERIFY  equ	 2Eh	; Set/reset verify switch
@GETDTA  equ	 2Fh	; Get disk transfer addr to ES:BX
; Functions available only in DOS 2.00 and later versions follow
@DOSVER  equ	 30h	; Get DOS version #
@KEEPRC  equ	 31h	; Terminate process and remain resident, exit code in AL
@GETDP2  equ	 32h	; Return DS:BX ==> drive parameter block for drive DL (origin-1)
@CHKBRK  equ	 33h	; Ctrl-Break check
@DOSPTR  equ	 34h	; Return ES:BX ==> DOS call level byte (internal)
@GETINT  equ	 35h	; Get interrupt vector in AL to ES:BX
@FATAD3  equ	 36h	; Get allocation table info of drive in DL
@SWITCH  equ	 37h	; Get (AL=00)/Set (AL=01) switch character
@GETCDI  equ	 38h	; Get country dependent information
@MKDIR	 equ	 39h	; Create a subdirectory named DS:DX
@RMDIR	 equ	 3Ah	; Remove the subdirectory named DS:DX
@CHDIR	 equ	 3Bh	; Change current directory to DS:DX
@CREAF2  equ	 3Ch	; Create file, ASCIIZ at DS:DX, attr in CX
@OPENF2  equ	 3Dh	; Open file, ASCIIZ at DS:DX
@CLOSF2  equ	 3Eh	; Close file, handle in BX
@READF2  equ	 3Fh	; Read from file BX, to DS:DX
@WRITF2  equ	 40h	; Write to file BX, from DS:DX
@DELEF2  equ	 41h	; Delete file, ASCIIZ at DS:DX
@MOVFP2  equ	 42h	; Move file's read/write pointer
@GSTMOD  equ	 43h	; Get (AL=0)/set (AL=1) file mode to CX, ASCIIZ at DS:DX
@IOCTL2  equ	 44h	; I/O Control for devices, handle in BX
@FHCOPY  equ	 45h	; Copy a file handle from BX to AX
@FHCREA  equ	 46h	; Create a file handle from BX to CX
@GETDIR  equ	 47h	; Get current directory for drive DL to DS:SI
@GETMEM  equ	 48h	; Get memory (BX paras)
@RELMEM  equ	 49h	; Release memory (in ES)
@MODMEM  equ	 4Ah	; Modify memory block ES to BX paras
@EXEC	 equ	 4Bh	; Execute a program
@EXITRC  equ	 4Ch	; Exit process with return code in AL
@GETRC	 equ	 4Dh	; Get return code from sub-process into AX
@FIND1	 equ	 4Eh	; Search for first dir entry, ASCIIZ at DS:DX
@FIND2	 equ	 4Fh	; Search for next dir entry, from DTA
@SETPSP  equ	 50h	; Set current PSP to BX (internal)
@GETPS0  equ	 51h	; Get current PSP into BX (same as 62h) (internal)
@GETLST  equ	 52h	; Get list of lists pointer into ES:BX
@BP2DPB  equ	 53h	; Translate BPB at DS:SI to DPN at ES:BP
@GETVRF  equ	 54h	; Get verify state
@BLDPS2  equ	 55h	; Create new program segment prefix at DX:0 with top of DOS at SI:0
@RENMF2  equ	 56h	; Rename file, from ASCIIZ at DS:DX to ASCIIZ at ES:DI
@GSTDAT  equ	 57h	; Get (AL=0)/set (AL=1) a file's date & time in DX, CX
; Functions available only in DOS 3.00 and later versions follow
@MACALG  equ	 58h	; Memory allocation chain algorithm
@EXTERR  equ	 59h	; Get extended error
@TMPFIL  equ	 5Ah	; Create temporary file, ASCIIZ at DS:DX, attr in CX
@NEWFIL  equ	 5Bh	; Create new file, ASCIIZ at DS:DX, attr in CX
@FILACC  equ	 5Ch	; Lock/unlock file access
;		 5Dh	  Used internally by DOS
;		 5Eh	  Used internally by DOS
;		 5Fh	  Used internally by DOS
@FIXPTH  equ	 60h	; Resolve path in DS:SI to canonical form in ES:DI
;		 61h	  Used internally by DOS
@GETPSP  equ	 62h	; Get current PSP into BX
; Functions available only in DOS 3.10 and later versions follow
; Functions available only in DOS 3.20 and later versions follow
;		 63h	  Used internally by DOS
;		 64h	  Used internally by DOS
; Functions available only in DOS 4.00 and later versions follow
@GETXCD  equ	 65h	; Get extended country-dependent information
@GSTGCP  equ	 66h	; Get/set global code page
@SETFHC  equ	 67h	; Set file handle count to BX for current PSP
@COMFIL  equ	 68h	; Commit file handle BX
@GSTSER  equ	 69h	; Get/set disk serial # for drive BL (origin-1) to DS:DX
;		 6Ah	  Used internally by DOS
;		 6Bh	  Used internally by DOS
@XOPCR2  equ	 6Ch	; Extended Open/Create file, ASCIIZ at DS:SI, attr in CX, mode in BX, flags in DX


.xcref DOSCALL
DOSCALL  macro	 FUNC,PARM1
ifnb	<FUNC>
ifnb	<PARM1>
F_C	 =	 FUNC
if (F_C eq 02h) or ((F_C ge 04h) and (F_C le 06h)) or (F_C eq 0Eh) or (F_C eq 2Eh) or (F_C eq 36h)
	 mov	 dl,PARM1
else
if (F_C eq 47h)
   if @WordSize eq 4
	 lea	 esi,PARM1
   else
	 lea	 si,PARM1
   endif
else
   if @WordSize eq 4
	 lea	 edx,PARM1
   else
	 lea	 dx,PARM1
   endif
endif				; IF (F_C EQ 47H)
endif				; IF (F_C EQ 02H) OR ...
endif				; IFNB <PARM1>
	 mov	 ah,FUNC
endif				; IFNB <FUNC>
	 int	 21h
	 endm			; DOSCALL


DOSCALL0 macro	FNCODE		; DOSCALL from PL0

ifnb	<FNCODE>
	 mov	 ax,FNCODE	; Get subfunction
endif				; IFNB <FNCODE>
	 PUSHD	 ss		; Simulate PL3 ring transition
	 push	 esp		; ...by saving SS|ESP
	 add	 [esp].EDD,4	; Add so that SS:ESP on stack points to the
				; PL0 stack before this call
	 int	 21h		; Request DOS service
	 lea	 esp,[esp+2*4]	; Strip from the stack w/o modifying flags

	 endm			; DOSCALL0


.xcref @STD_INP,@STD_OUT,@STD_ERR,@STD_AUX,@STD_PRT
@STD_INP equ	 0000		; Standard DOS 2.00 file handles
@STD_OUT equ	 0001
@STD_ERR equ	 0002
@STD_AUX equ	 0003
@STD_PRT equ	 0004


; Equates for @GETRC reason code

@GETRC_NRM equ	 00h		; Normal termination
@GETRC_I23 equ	 01h		; Ctrl-Brk (INT 23h) ...
@GETRC_I24 equ	 02h		; Critical Device Error (INT 24h) ...
@GETRC_RES equ	 03h		; Resident (AH=@KEEPRC) ...
@GETRC_INV equ	 0FFh		; Invalid value


; Equates for @MOVFP2

@MOVFP2_BEG equ 0		; Start of file
@MOVFP2_CUR equ 1		; Current position
@MOVFP2_END equ 2		; End of file

