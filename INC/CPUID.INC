;' $Header:   P:/PVCS/MAX/INC/CPUID.INV   1.0   05 Sep 1995 13:27:28   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; CPUID.INC
;
; CPUID_SEG segment and equates
;

; CPUID equates for byte at F000:FFFE

.xcref @CPU_PC,@CPU_XT,@CPU_JR,@CPU_AT,@CPU_XT2,@CPU_M30,@CPU_CNV,@CPU_MCA
@CPU_PC  equ	 0FFh		; IBM PC
@CPU_XT  equ	 0FEh		; IBM PC XT
@CPU_JR  equ	 0FDh		; IBM PCjr
@CPU_AT  equ	 0FCh		; IBM PC AT & PS/2 Model 50/60
@CPU_XT2 equ	 0FBh		; IBM PC XT with 256/640 system board
@CPU_M30 equ	 0FAh		; IBM PS/2 Model 30
@CPU_CNV equ	 0F9h		; IBM PC Convertible
@CPU_MCA equ	 0F8h		; IBM PS/2 MCA or ISA 386


.xcref CPUID_SEG,ITTSIGN,HPFNS,HPSIGN,HPTYPE,@HPRS20,@HPRS16,@HPQS16,@HPQS20
.xcref @HPRS20C,@HPRS25C,@HPQS16S
.xcref ZDSSIGN
.xcref @GRIDSIGN2,GRIDSIGN2,GRIDDASH,GRIDMODEL,OLISIGN,PHOENIXSIGN
.xcref NECSIGN2,NECSIGNLAP
.xcref NECSIGN,NECSXSIGN
.xcref CASIGN,CALEVEL,DELLTYPE,EISASIGN
.xcref OFFCPQSTR,OFFCPQST2
.xcref ZDSISIG,@ZDSMOD1,@ZDSMOD2,@ZDSMOD3,@ZDSMOD4
.xcref BIOS_TYPE,VENDOR,REBOOT,REBOOTD,REBOOT_VEC,BIOS_DATE
.xcref EPSALTID,OLIALTID,BIOSCPUID,CHKSUM
.xcref @OLI_M300,@OLI_M316,@OLI_M305,@OLI_XP2,@OLI_XP9
if (@Cpu and 1000b)		; If 80386 instructions
CPUID_SEG segment use16 at 0F000h ; Start CPUID_SEG segment
else
CPUID_SEG segment at 0F000h	; Start CPUID_SEG segment
endif				; IF (@Cpu AND 1000b)

	 org	 0010h
ITTSIGN  db	 '(C) COPYRIGHT XTRA BUSINESS SYSTEMS' ; ITT XTRA signature

	 org	 00E0h
HPFNS	 proc	 far		; HP function dispatcher
HPFNS	 endp

	 org	 00F8h
HPSIGN	 db	 'HP'           ; HP signature
HPTYPE	 db	 ?		; HP type:
@HPRS20  equ	 62h		; 62h = RS/20
@HPRS16  equ	 66h		; 66h = RS/16
@HPQS16  equ	 67h		; 67h = QS/16
@HPQS20  equ	 68h		; 68h = QS/20
@HPRS20C equ	 69h		; 69h = RS/20C
@HPRS25C equ	 6Ah		; 6Ah = RS/25C
@HPQS16S equ	 8Ch		; 8Ch = QS/16S

	 org	 800Ch
ZDSSIGN  db	 'ZDS'          ; Zenith signature (all systems)

	 org	 80A1h
@GRIDSIGN2 equ	 0C0h		; Code for Tandy/GRiD (source unknown)
GRIDSIGN2 db	 @GRIDSIGN2	; Tandy/GRiD desktop (4000/5000) signature

	 org	 0DFDCh
GRIDDASH db	 '--'           ; GRiD signature
	 org	 0DFFEh
GRIDMODEL db	 ?		; GRiD model byte
@GRIDROAD equ	  44h		; Roadrunner sx LEAP
@GRID1537 equ	  54h		; Model 1537sx LEAP
@GRID1530 equ	  74h		; Model 1530
@GRIDLYNX equ	 0F4h		; Lynx sx LEAP (1450sx)

	 org	 0E000h
TOSHSIGN db	 'T5100'        ; Toshiba 5100 signature

	 org	 0E009h
OLISIGN  db	 'COPYRIGHT (C) OLIVETTI' ; Olivetti/AT&T signature

	 org	 0E038h
PHOENIXSIGN db	 'Phoenix Technologies Ltd' ; Phoenix BIOS signature

	 org	 0E05Eh
NECSIGN2 db	 'NEC Corporation'

	 org	 0E06Fh
NECSIGNLAP db	 'UltraLite Versa'

	 org	 0E076h
NECSIGN  db	 'NEC Corporation' ; NEC signature
	 org	 0E091h
NECSXSIGN db	 'SX Plus'      ; NEC SX Plus signature

	 org	 0E0C1h
CASIGN	 db	 'System: 386'  ; CompuAdd signature
	 db	 'R'            ; Not present on Micronics boards used by CA
CALEVEL  db	 ?		; ... BIOS level
				;  '3' or later ==> memory reclamation

	 org	 0E845h 	; Dell system model identifier
DELLTYPE db	 ?		; Types defined below

@DELL_SYS300	 equ	03h	; System 300
@DELL_SYS310	 equ	06h	; System 310
@DELL_SYS325	 equ	07h	; System 325
@DELL_SYS310A	 equ	09h	; System 310A
@DELL_SYS316	 equ	0ah	; System 316
@DELL_SYS316SX	 equ	0dh	; System 316SX
@DELL_SYS316LT	 equ	0eh	; System 316LT
@DELL_SYS320LX	 equ	0fh	; System 320LX
@DELL_SYS425E	 equ	11h	; System 425E
@DELL_SYS433E	 equ	12h	; System 433E
@DELL_SYS320LT	 equ	13h	; System 320LT
@DELL_SYS3xxD	 equ	14h	; System 325D & System 333D
@DELL_SYS3xxP	 equ	15h	; System 325P & System 333P
@DELL_SYS425GE	 equ	17h	; System 425GE
@DELL_SYS433GE	 equ	18h	; System 433GE
@DELL_SYS320N	 equ	1bh	; System 320N

	 org	 0FFD9h
EISASIGN  db	 'EISA'         ; EISA system board signature

	 org	 0FFE0h
OFFCPQSTR dw	 ?		; Offset of primary COMPAQ memory structure
OFFCPQST2 dw	 ?		; ...	    CPU revision two bytes

	 org	 0801Eh
CPQCUT_POINTER	dw	?	; Vector Table entry pointing to Cut Table

	 org	 0FFE3h
ZDSISIG  db	 'ZBIOS'        ; Zenith interface signature
@ZDSMOD1 equ	 'Z-300'
@ZDSMOD2 equ	 'MONGOOSE'
@ZDSMOD3 equ	 'DRAGON'
@ZDSMOD4 equ	 'FOX'
; If none of the above found, we should be able to find 'MFM-300'
; Somewhere in the F000 segment.

	 org	 0FFE8h
BIOS_TYPE db	 ?,?		; BIOS type code for COMPAQs
				; '03' = 386 product
	 org	 0FFEAh
VENDOR	 db	 6 dup (?)	; Vendor name

	 org	 0FFF0h
REBOOT	 label	 far		; Reboot address
REBOOTD  db	 0EAh		; Far jump opcode
REBOOT_VEC dd	 ?		; Immediate operand
BIOS_DATE db	 '??/??/??'     ; BIOS date

	 org	 0FFFDh
EPSALTID label	 byte		; Epson alternate ID byte
OLIALTID db	 ?		; Olivetti alternate ID byte
BIOSCPUID db	 ?		; The CPU's identification byte
CHKSUM	 db	 ?		; Checksum

@OLI_M300 equ	 'R'            ; M300
@OLI_M316 equ	 'b'            ; M316
@OLI_M305 equ	 't'            ; M305/M310
@OLI_XP2 equ	 'V'            ; M386/25 (XP2)
@OLI_XP5 equ	 'E'            ; M386/20? (XP1/3/5) (XP1=AT&T WGS 6386)
@OLI_XP9 equ	 'P'            ; M386/25 (XP4/7/9)

CPUID_SEG ends			; End CPUID_SEG segment

