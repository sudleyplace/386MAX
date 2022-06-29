;' $Header:   P:/PVCS/MAX/386MAX/QMAX_IDT.INV   1.0   11 Aug 1995 10:55:56   HENRY  $
;
; (C) Copyright 1992 Qualitas, Inc.  All rights reserved.
;
; QMAX_IDT.INC
;
; IDT swap macro
;

IDTMAC	 macro	 N1,N2,SRC,SAV,FORCE
	 local	 L1

IDT	 equ	 <AGROUP:[ebx+N1*(type IDT_STR)]>

	 mov	 ax,SRC&INT&N2&_FVEC.FSEL ; Get selector
ifb <FORCE>
	 cmp	 ax,IDT.IDT_SELECT ; Same as IDT?
	 je	 short L1	; Yes, ignore this interrupt
endif
	 xchg	 ax,IDT.IDT_SELECT ; Swap with IDT
ifnb <SAV>
	 mov	 SAV&INT&N2&_FVEC.FSEL,ax ; Save for later use
endif

	 mov	 eax,SRC&INT&N2&_FVEC.FOFF ; Get 32-bit offset
	 xchg	 ax,IDT.IDT_OFFLO ; Swap with IDT
ifnb <SAV>
	 mov	 SAV&INT&N2&_FVEC.FOFF.ELO,ax ; Save for later use
endif
	 shr	 eax,16 	; Shift to low-order
	 xchg	 ax,IDT.IDT_OFFHI ; Swap with IDT
ifnb <SAV>
	 mov	 SAV&INT&N2&_FVEC.FOFF.EHI,ax ; Save for later use
endif

	 mov	 al,SRC&INT&N2&_ARB ; Get access rights byte
	 xchg	 al,IDT.IDT_ACCESS ; Swap with IDT
ifnb <SAV>
	 mov	 SAV&INT&N2&_ARB,al ; Save for later use
endif
L1:
	 endm

