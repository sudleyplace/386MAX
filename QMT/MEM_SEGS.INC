;' $Header:   P:/PVCS/MAX/QMT/MEM_SEGS.INV   1.0   29 Jun 1998 13:04:58   BOB  $
;
; (C) Copyright 1998 Qualitas, Inc.  All rights reserved.
;
; MEM_SEGS.INC
;
; All segments in RAMexam in order of appearance


PGROUP	group	CODE,PROG,CODEZ
DGROUP	group	STACK,DATA,SEG_TAB,SEG_LEN,SEG_ACT,NDATA,DATAMSG,KEYSEG,ACTSEG,CALIBSEG,DATAZ,IDENT
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


SEG_TAB segment use16 word public 'data' ; Start SEG_TAB segment
SEG_TAB ends			; End SEG_TAB segment


SEG_LEN segment use16 word public 'data' ; Start SEG_LEN segment
SEG_LEN ends			; End SEG_LEN segment


SEG_ACT segment use16 word public 'data' ; Start SEG_ACT segment
SEG_ACT ends			; End SEG_ACT segment


NDATA	segment use16 dword public 'data' ; Start NDATA segment
NDATA	ends			; End NDATA segment


DATAMSG segment use16 byte public 'data' ; Start DATA segment
DATAMSG ends			; End DATAMSG segment


KEYSEG	segment use16 word public 'data' ; Start KEYSEG segment
KEYSEG	ends			; End KEYSEG segment


ACTSEG	segment use16 word public 'data' ; Start ACTSEG segment
ACTSEG	ends			; End ACTSEG segment


CALIBSEG segment use16 word public 'data' ; Start CALIBSEG segment
CALIBSEG ends			; End CALIBSEG segment


DATAZ	segment use16 para public 'dataz' ; Start DATAZ segment
DATAZ	ends			; End DATAZ segment


IDENT	segment use16 dword public 'dataz' ; Start IDENT segment
IDENT	ends			; End IDENT segment


PSP_SEG segment use16 at 0	; Start PSP_SEG segment
PSP_SEG ends			; End PSP_SEG segment

