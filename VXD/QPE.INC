QPE_STR 	struc

QPE_cSig		db		4 DUP (?)
QPE_bCheckSum		db		?
QPE_bVersion		db		?
QPE_cbQPIF		dw		?
QPE_Flags1		db		?
QPE_Reserved1		db		?
QPE_DosMax		dw		?
QPE_Reserved2		db		4 DUP (?)
QPE_szPIF		db		80 DUP (?)

QPE_STR 	 ends

@QPE_SIGL	 equ	4
@QPE_ON 	 equ	0080h
@QPE_OFF	 equ	0040h

