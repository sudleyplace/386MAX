;' $Header:   P:/PVCS/MAX/INC/INTRNATL.INV   1.0   05 Sep 1995 13:27:28   HENRY  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	GNU General Public License version 3.
;
; INTRNATL.INC
;
; Language-specific equates.
;

COMMENT|

A series of @NATL_ EQUates allows programs to compile using different
conventions.  For example, in German the Yes response is Ja, and the
significance of the comma and decimal point is reversed (65,536.0 would
be displayed as 65.536,0).

|

@NATL_TIME12	equ	0	; Time is displayed as AM/PM
@NATL_TIME24	equ	1	; Time is displayed 00:00 - 23:59

ifdef LANG_GR
@NATL_TIME	equ	@NATL_TIME24
@NATL_YESCHAR	equ	'J'     ; Ja
@NATL_NOCHAR	equ	'N'     ; Nein
@NATL_ABORT	equ	'A'     ; Abbruch
@NATL_RETRY	equ	'W'     ; Wiederholen
@NATL_FAIL	equ	'F'     ; Fehler
@NATL_POSTPONE	equ	'S'     ; SpÑter
@NATL_OVERWRITE equ	'N'     ; Neue Datei (alte Datei Åberschreiben)
@NATL_DECIMAL	equ	','     ; Decimal point character
@NATL_THOU	equ	'.'     ; Thousands separator
else
@NATL_TIME	equ	@NATL_TIME12
@NATL_YESCHAR	equ	'Y'     ; Yes
@NATL_NOCHAR	equ	'N'     ; No
@NATL_ABORT	equ	'A'     ; Abort
@NATL_RETRY	equ	'R'     ; Retry
@NATL_FAIL	equ	'F'     ; Fail
@NATL_POSTPONE	equ	'P'     ; Postpone
@NATL_OVERWRITE equ	'O'     ; Overwrite
@NATL_DECIMAL	equ	'.'     ; Decimal point character
@NATL_THOU	equ	','     ; Thousands separator
endif				; IFDEF LANG_GR
