;' $Header:   P:/PVCS/MAX/INC/OPCODES.INV   1.2   30 Sep 1996 17:11:40   BOB  $
;
; (C) Copyright 1987-96 Qualitas, Inc.	All rights reserved.
;
; OPCODES.INC
;
; Equates for certain instruction opcodes
;

@OPCOD_ADDMR8	    equ  00h
@OPCOD_ADDMR16	    equ  01h
@OPCOD_ADDR8M	    equ  02h
@OPCOD_ADDR16M	    equ  03h
@OPCOD_ADDAL	    equ  04h
@OPCOD_ADDAX	    equ  05h

@OPCOD_ORMR8	    equ  08h
@OPCOD_ORMR16	    equ  09h
@OPCOD_ORR8M	    equ  0Ah
@OPCOD_ORR16M	    equ  0Bh
@OPCOD_ORAL	    equ  0Ch
@OPCOD_ORAX	    equ  0Dh

@OPCOD_ADCMR8	    equ  10h
@OPCOD_ADCMR16	    equ  11h
@OPCOD_ADCR8M	    equ  12h
@OPCOD_ADCR16M	    equ  13h
@OPCOD_ADCAL	    equ  14h
@OPCOD_ADCAX	    equ  15h

@OPCOD_SBBMR8	    equ  18h
@OPCOD_SBBMR16	    equ  19h
@OPCOD_SBBR8M	    equ  1Ah
@OPCOD_SBBR16M	    equ  1Bh
@OPCOD_SBBAL	    equ  1Ch
@OPCOD_SBBAX	    equ  1Dh

@OPCOD_ANDMR8	    equ  20h
@OPCOD_ANDMR16	    equ  21h
@OPCOD_ANDR8M	    equ  22h
@OPCOD_ANDR16M	    equ  23h
@OPCOD_ANDAL	    equ  24h
@OPCOD_ANDAX	    equ  25h

@OPCOD_SUBMR8	    equ  28h
@OPCOD_SUBMR16	    equ  29h
@OPCOD_SUBR8M	    equ  2Ah
@OPCOD_SUBR16M	    equ  2Bh
@OPCOD_SUBAL	    equ  2Ch
@OPCOD_SUBAX	    equ  2Dh

@OPCOD_XORMR8	    equ  30h
@OPCOD_XORMR16	    equ  31h
@OPCOD_XORR8M	    equ  32h
@OPCOD_XORR16M	    equ  33h
@OPCOD_XORAL	    equ  34h
@OPCOD_XORAX	    equ  35h

@OPCOD_CMPMR8	    equ  38h
@OPCOD_CMPMR16	    equ  39h
@OPCOD_CMPR8M	    equ  3Ah
@OPCOD_CMPR16M	    equ  3Bh
@OPCOD_CMPAL	    equ  3Ch
@OPCOD_CMPAX	    equ  3Dh

@OPCOD_GRP1R8I	    equ  80h
@OPCOD_GRP1R16I     equ  81h
@OPCOD_GRP1R16S     equ  83h



@OPCOD_2ND	    equ  0Fh
@OPCOD_CS	    equ  2Eh
@OPCOD_DS	    equ  3Eh
@OPCOD_ES	    equ  26h
@OPCOD_INCAX	    equ  40h
@OPCOD_INCCX	    equ  41h
@OPCOD_INCDX	    equ  42h
@OPCOD_INCBX	    equ  43h
@OPCOD_ARPL	    equ  63h
@OPCOD_FS	    equ  64h
@OPCOD_GS	    equ  65h
@OPCOD_SS	    equ  36h
@OPCOD_OSP	    equ  66h
@OPCOD_ASP	    equ  67h
@OPCOD_PUSHIM8	    equ  6Ah
@OPCOD_INSB	    equ  6Ch
@OPCOD_INSW	    equ  6Dh
@OPCOD_INSD	    equ  6D66h
@OPCOD_OUTSB	    equ  6Eh
@OPCOD_OUTSW	    equ  6Fh
@OPCOD_OUTSD	    equ  6F66h
@OPCOD_JCCLO	    equ  70h
@OPCOD_JCCHI	    equ  7Fh
@OPCOD_JCCLO2	    equ  800Fh
@OPCOD_JCCHI2	    equ  8F0Fh
@OPCOD_NOP	    equ  90h
@OPCOD_NOP2	    equ 0C087h		; XCHG AX,AX
@OPCOD_NOP3	    equ 0C08766h	; XCHG EAX,EAX
@OPCOD_NOP4	    equ 00E0C166h	; SHL  EAX,00
@OPCOD_ESC0	    equ 0D8h
@OPCOD_ESC7	    equ 0DFh
@OPCOD_LOOPNE	    equ 0E0h
@OPCOD_LOOPE	    equ 0E1h
@OPCOD_LOOP	    equ 0E2h
@OPCOD_LOCK	    equ 0F0h
@OPCOD_REPNE	    equ 0F2h
@OPCOD_REP	    equ 0F3h
@OPCOD_REPE	    equ 0F3h

@OPCOD_MOVR8	    equ  8Ah
@OPCOD_MOVR16	    equ  8Bh

@OPCOD_CALLF	    equ  9Ah
@OPCOD_CALLFD	    equ  9A66h
@OPCOD_CALLFDD	    equ 01EFFh

@OPCOD_PUSHF	    equ  9Ch
@OPCOD_PUSHFD	    equ  9C66h
@OPCOD_POPF	    equ  9Dh
@OPCOD_POPFD	    equ  9D66h
@OPCOD_MOVALM	    equ 0A0h
@OPCOD_MOVAXM	    equ 0A1h
@OPCOD_MOVMAL	    equ 0A2h
@OPCOD_MOVMAX	    equ 0A3h
@OPCOD_MOVSB	    equ 0A4h
@OPCOD_MOVSW	    equ 0A5h
@OPCOD_CMPSB	    equ 0A6h
@OPCOD_CMPSW	    equ 0A7h
@OPCOD_STOSB	    equ 0AAh
@OPCOD_STOSW	    equ 0ABh
@OPCOD_LODSB	    equ 0ACh
@OPCOD_LODSW	    equ 0ADh
@OPCOD_SCASB	    equ 0AEh
@OPCOD_SCASW	    equ 0AFh
@OPCOD_MOVAXIM	    equ 0B8h

@OPCOD_INT3	    equ 0CCh
@OPCOD_INT	    equ 0CDh
@OPCOD_INTO	    equ 0CEh

@OPCOD_POPSS	    equ  17h
@OPCOD_IRET	    equ 0CFh
@OPCOD_IRETD	    equ 0CF66h
@OPCOD_RET	    equ 0C3h
@OPCOD_RETD	    equ 0C366h
@OPCOD_RETF	    equ 0CBh
@OPCOD_RETFD	    equ 0CB66h

@OPCOD_RETP	    equ 0C2h
@OPCOD_RETDP	    equ 0C266h
@OPCOD_RETFP	    equ 0CAh
@OPCOD_RETFDP	    equ 0CA66h

@OPCOD_JCXZ	    equ 0E3h
@OPCOD_JECXZ	    equ 0E367h

@OPCOD_CALLN	    equ 0E8h
@OPCOD_CALLND	    equ 0E866h

@OPCOD_JMPN	    equ 0E9h
@OPCOD_JMPND	    equ 0E966h
@OPCOD_JMPF	    equ 0EAh
@OPCOD_JMPFD	    equ 0EA66h
@OPCOD_JMPS	    equ 0EBh

@OPCOD_INIB	    equ 0E4h
@OPCOD_INIW	    equ 0E5h
@OPCOD_INID	    equ 0E566h
@OPCOD_INDB	    equ 0ECh
@OPCOD_INDW	    equ 0EDh
@OPCOD_INDD	    equ 0ED66h

@OPCOD_OUTIB	    equ 0E6h
@OPCOD_OUTIW	    equ 0E7h
@OPCOD_OUTID	    equ 0E766h
@OPCOD_OUTDB	    equ 0EEh
@OPCOD_OUTDW	    equ 0EFh
@OPCOD_OUTDD	    equ 0EF66h

@OPCOD_HLT	    equ 0F4h
@OPCOD_STC	    equ 0F9h
@OPCOD_CLI	    equ 0FAh
@OPCOD_STI	    equ 0FBh
@OPCOD_GRP3A	    equ 0F6h
@OPCOD_GRP3B	    equ 0F7h
@OPCOD_GRP5	    equ 0FFh
@OPCOD_GRP5D	    equ 0FF66h

@OPCOD_GRP6	    equ 000Fh
@OPCOD_GRP7	    equ 010Fh
@OPCOD_LOADALL	    equ 050Fh
@OPCOD_CLTS	    equ 060Fh
@OPCOD_LOADALLD     equ 070Fh
@OPCOD_INVD	    equ 080Fh
@OPCOD_WBINVD	    equ 090Fh
@OPCOD_MOV_R32_CRn  equ 200Fh
@OPCOD_MOV_R32_DRn  equ 210Fh
@OPCOD_MOV_CRn_R32  equ 220Fh
@OPCOD_MOV_DRn_R32  equ 230Fh
@OPCOD_MOV_R32_TRn  equ 240Fh
@OPCOD_MOV_TRn_R32  equ 260Fh
@OPCOD_WRMSR	    equ 300Fh
@OPCOD_RDTSC	    equ 310Fh
@OPCOD_RDMSR	    equ 320Fh
@OPCOD_RDPMC	    equ 330Fh
@OPCOD_SYSENTER     equ 340Fh
@OPCOD_SYSEXIT	    equ 350Fh
@OPCOD_CPUID	   equ 0A20Fh

@OPCOD_CMOVLO	   equ 0400Fh
@OPCOD_CMOVHI	   equ 04F0Fh

@OPCOD_BSWAPLO	   equ 0C80Fh
@OPCOD_BSWAPHI	   equ 0CF0Fh

@OPCOD_WIN06	   equ 0FF0Fh
@OPCOD_UD2	   equ 0FF0Fh

