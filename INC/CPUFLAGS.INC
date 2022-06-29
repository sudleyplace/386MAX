;' $Header:   P:/PVCS/MAX/INC/CPUFLAGS.INV   1.0   05 Sep 1995 13:27:00   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; CPUFLAGS.INC
;
; CPUFLAGS record
;

.xcref CPUFLAGS,$R0,$NT,$IOPL,$OF,$DF,$IF,$TF,$SF,$ZF,$R1,$AF,$R2,$PF,$R3,$CF

if (@Cpu and 1000b)		; If 80386 instructions
.xcref $ID,$VIP,$VIF,$ACHI,$VMHI,$RFHI
CPUFLAGS record  $ID:1,$VIP:1,$VIF:1,$ACHI:1,$VMHI:1,$RFHI:1, \
		 $R0:1,$NT:1,$IOPL:2,$OF:1,$DF:1,$IF:1,$TF:1,$SF:1,$ZF:1,$R1:1,$AF:1,$R2:1,$PF:1,$R3:1,$CF:1
else
CPUFLAGS record  $R0:1,$NT:1,$IOPL:2,$OF:1,$DF:1,$IF:1,$TF:1,$SF:1,$ZF:1,$R1:1,$AF:1,$R2:1,$PF:1,$R3:1,$CF:1
endif				; IF (@Cpu AND 1000b)

