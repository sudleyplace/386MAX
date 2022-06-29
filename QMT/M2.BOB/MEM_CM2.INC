;' $Header$
;
; (C) Copyright 1988-2000 Qualitas, Inc.  All rights reserved.
;
; MEM_CM2.INC
;
; Equates for CM2_FLAG.
;

CM2_REC record	\
 $CM2_NODAT:1,	\
 $CM2_TONE:1,	\
 $CM2_LIGHTS:1, \
 $CM2_NODOS:1,	\
 $CM2_NOCACHE:1,\
 $CM2_NOCACHETEST:1

@CM2_NODAT equ	     (mask $CM2_NODAT)	 ; 0020:  Don't write out a .DAT file
@CM2_TONE   equ      (mask $CM2_TONE)	 ; 0010:  TONE[=d:\path\filename.ext]
@CM2_LIGHTS equ      (mask $CM2_LIGHTS)  ; 0008:  LIGHTS[=d:\path\filename.ext]
@CM2_NODOS equ	     (mask $CM2_NODOS)	 ; 0004:  Don't test low DOS memory
@CM2_NOCACHE equ     (mask $CM2_NOCACHE) ; 0002:  Disable all cachine
@CM2_NOCACHETEST equ (mask $CM2_NOCACHETEST) ; 0001:  Disable caching of test code

