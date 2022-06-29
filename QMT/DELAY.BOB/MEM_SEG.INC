;' $Header$
;
; (C) Copyright 1988-97 Qualitas, Inc.	All rights reserved.
;
; MEM_SEG.INC
;
; All segments for RAMexam
;

PGROUP	group	CODE,PROG,CODEZ
DGROUP	group	STACK,DATA,CALIBSEG,KEYSEG,ACTSEG,NDATA,SEG_TAB,SEG_LEN,SEG_ACT,DATAMSG,LBLSEGA,LBLSEG,LBLSEGZ,DATAZ,IDENT
PSPGRP	group	PSP_SEG


CODE	segment use16 byte public 'prog' ; Start CODE segment
CODE	ends			; End CODE segment


PROG	segment use16 byte public 'prog' ; Start PROG segment
PROG	ends			; End PROG segment


CODEZ	segment use16 para public 'prog' ; Start CODEZ segment
CODEZ	ends			; End CODEZ segment


STACK	segment use16 dword stack 'data' ; Start STACK segment
STACK	ends			; End STACK segment


DATA	segment use16 dword public 'data' ; Start DATA segment
DATA	ends			; End DATA segment


CALIBSEG segment use16 word public 'data' ; Start CALIBSEG segment
CALIBSEG ends			; End CALIBSEG segment


KEYSEG	segment use16 word public 'data' ; Start KEYSEG segment
KEYSEG	ends			; End KEYSEG segment


ACTSEG	segment use16 word public 'data' ; Start ACTSEG segment
ACTSEG	ends			; End ACTSEG segment


NDATA	segment use16 dword public 'data' ; Start NDATA segment
NDATA	ends			; End NDATA segment


SEG_TAB segment use16 word public 'data' ; Start SEG_TAB segment
SEG_TAB ends			; End SEG_TAB segment


SEG_LEN segment use16 word public 'data' ; Start SEG_LEN segment
SEG_LEN ends			; End SEG_LEN segment


SEG_ACT segment use16 word public 'data' ; Start SEG_ACT segment
SEG_ACT ends			; End SEG_ACT segment


DATAMSG segment use16 byte public 'data' ; Start DATAMSG segment
DATAMSG ends			; End DATAMSG segment


LBLSEGA segment use16 word public 'data' ; Start LBLSEGA segment
LBLSEGA ends			; End LBLSEGA segment


LBLSEG	segment use16 word public 'data' ; Start LBLSEG segment
LBLSEG	ends			; End LBLSEG segment


LBLSEGZ segment use16 word public 'data' ; Start LBLSEGZ segment
LBLSEGZ ends			; End LBLSEGZ segment


DATAZ	segment use16 para public 'dataz' ; Start DATAZ segment
DATAZ	ends			; End DATAZ segment


IDENT	segment use16 dword public 'dataz' ; Start IDENT segment
IDENT	ends			; End IDENT segment


PSP_SEG segment use16 at 0	; Start PSP_SEG segment
PSP_SEG ends			; End PSP_SEG segment


