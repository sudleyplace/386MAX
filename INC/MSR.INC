;' $Header:   P:/PVCS/MAX/INC/MSR.INV   1.1   28 Jun 1996 17:56:20   BOB  $
;
; (C) Copyright 1992-6 Qualitas, Inc.  All rights reserved.
;
; MSR.INC
;
; Structures and equates for the Model-Specific Registers
;

; MSRs for Pentium CPUs

@MSR_MCADDR  equ  00h		 ; Machine check address
@MSR_MCTYPE  equ  01h		 ; Machine check type
@MSR5_PRR    equ  02h		 ; TR1	- Parity reversal register
;;;;;	     equ  03h		 ; (RESERVED)
@MSR5_ICEB   equ  04h		 ; TR2	- Instruction cache end bit
@MSR5_CTDAT  equ  05h		 ; TR3	- Cache test data
@MSR5_CTTAG  equ  06h		 ; TR4	- Cache test tag
@MSR5_CTCTL  equ  07h		 ; TR5	- Cache test control
@MSR5_TLBLA  equ  08h		 ; TR6	- TLB Test linear address
@MSR5_TLBLO  equ  09h		 ; TR7	- TLB Test control & physical address 31-12
@MSR5_TLBHI  equ  0Ah		 ; TR8	- TLB Test physical address 35-32
@MSR5_BTBTAG equ  0Bh		 ; TR9	- BTB Test tag
@MSR5_BTBTGT equ  0Ch		 ; TR10 - BTB Test target
@MSR5_BTBCTL equ  0Dh		 ; TR11 - BTB Test control
@MSR5_ETBP   equ  0Eh		 ; TR12 - Execution tracing and branch prediction
;;;;;	     equ  0Fh		 ; (RESERVED)
@MSR5_TSC    equ  10h		 ; Time stamp counter
@MSR5_CES    equ  11h		 ; Control and event select
@MSR5_CNT0   equ  12h		 ; Counter #0
@MSR5_CNT1   equ  13h		 ; Counter #1


; Record for Machine Check Type register

MCTYP_REC record $MCT_LCK:1,$MCT_MIO:1,$MCT_DC:1,$MCT_WR:1,$MCT_CHK:1

; MSRs for Pentium Pro CPUs

;;;;_MCADDR	equ  000h	 ; R/W:  Machine check address (same as P5)
;;;;_MCTYPE	equ  001h	 ; R/W:  Machine check type	...
@MSR6_TSC	equ  010h	 ; R/W:
@MSR6_APICBASE	equ  01Bh	 ; R/W:  APIC base
@MSR6_PERFCTR0	equ  0C1h	 ; R/W:  Performance counter 0
@MSR6_PERFCTR1	equ  0C2h	 ; R/W:  ...		     1
@MSR6_MTRR_CAP	equ  0FEh	 ; R:
@MSR6_MCG_CAP	equ  179h	 ; R:
@MSR6_MCG_STAT	equ  17Ah	 ; R/W:
@MSR6_PEVTSEL0	equ  186h	 ; R/W:  Performance Event Select 0
@MSR6_PEVTSEL1	equ  187h	 ; R/W:  ...			  1
@MSR6_DBGCTL	equ  1D9h	 ; R/W:  Debug Control
@MSR6_LBRFREIP	equ  1DBh	 ; R/W:  Last Branch From EIP
@MSR6_LBRTOEIP	equ  1DCh	 ; R/W:  ...	     To   ...
@MSR6_LEXFREIP	equ  1DDh	 ; R/W:  Last Exception From EIP
@MSR6_LEXTOEIP	equ  1DEh	 ; R/W:  ...		To   ...


MSR6_DBGCTL record $DBGCTL_TR:1,  \
		   $DBGCTL_PB3:1, \
		   $DBGCTL_PB2:1, \
		   $DBGCTL_PB1:1, \
		   $DBGCTL_PB0:1, \
		   $DBGCTL_BTF:1, \
		   $DBGCTL_LBR:1

@DBGCTL_TR  equ (mask $DBGCTL_TR)  ; Enable trace messages ???
@DBGCTL_PB3 equ (mask $DBGCTL_PB3) ; Toggle perf/brkpt pin 3 on match to DR3
@DBGCTL_PB2 equ (mask $DBGCTL_PB2) ; ...		   2		   2
@DBGCTL_PB1 equ (mask $DBGCTL_PB1) ; ...		   1		   1
@DBGCTL_PB0 equ (mask $DBGCTL_PB0) ; ...		   0		   0
@DBGCTL_BTF equ (mask $DBGCTL_BTF) ; Enable Branch Trace Facility
@DBGCTL_LBR equ (mask $DBGCTL_LBR) ; Enable Last Branch/Exception Facility

