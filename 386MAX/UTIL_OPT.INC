;' $Header:   P:/PVCS/MAX/386MAX/UTIL_OPT.INV   1.0   11 Aug 1995 10:56:02   HENRY  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	GNU General Public License version 3.
;
; UTIL_OPT.INC
;
; Summary fit and Optimization progress structures
;

SUMFIT_STR struc

SUMFIT_PARA  dw  ?		; 00-01:  Para # of LSEG (0=last+1 entry)
SUMFIT_IPARA dw  ?		; 02-03:  # paras needed to install
SUMFIT_RPARA dw  ?		; 04-05:  # paras needed as resident program
SUMFIT_EPAR0 dw  ?		; 06-07:  # paras needed for environment before
				;	  (0=device driver)
				; For UMBs, SUMFIT_EPAR0 is the size in paras
				; to try to allocate.
SUMFIT_EPAR1 dw  ?		; 08-09:  # paras needed for environment after
				; For UMBs, SUMFIT_EPAR1 contains two subfields
				; defined in LOAD_SEG.INC

SUMFIT_PREG  db  ?		; 0A-0A:  Program region # specified (0=none)
SUMFIT_EREG  db  ?		; 0B-0B:  Environment ...
SUMFIT_GRP   db  ?		; 0C-0C:  Group # specified (0=none,
				;			    -1=386MAX,
				;			    -2=UMB)
SUMFIT_ORD   db  ?		; 0D-0D:  Program order # (origin-0)
				; The following field *MUST* be on word boundary
SUMFIT_FLAG  dw  0		; 0E-0F:  Flags (same as LSEG_FLAG)

SUMFIT_STR ends

; SIZE = 16 * max (IPARA, RPARA)

@NREGS	 equ	 8		; # distinct high DOS regions


RFIT_STR struc

RFIT_PORD db	 ?		; Program order #
RFIT_PREG db	 ?		; Program region #
RFIT_EREG db	 ?		; Environment region #

RFIT_STR ends

; Optimization progress structure
OPROG_STR struc

OPROG_PCT	dw	?	; Integer percentage completed
OPROG_FLAGS	dw	?	; Display flags
; All other structure members are far pointers to ASCIIZ strings.
OPROG_PDONE	dw	?	; Far pointer to number done so far (ASCIIZ)
		dw	?
OPROG_PELAPSED	dw	?	; HH:MM:SS elapsed
		dw	?
OPROG_PTOTAL	dw	?	; Total to process (n,nnn,nnn,nnn...)
		dw	?
OPROG_PTOTHIGH	dw	?	; Total bytes in high DOS
		dw	?
OPROG_PBESTCNT	dw	?	; Number done when best so far found
		dw	?
OPROG_PBESTELAP dw	?	; HH:MM:SS elapsed when best so far found
		dw	?
OPROG_PBESTBYTE dw	?	; Number of bytes moved high for best so far
		dw	?
OPROG_PBESTPCT	dw	?	; Best count as percentage of current count
		dw	?
OPROG_PBESTBPCT dw	?	; Best bytes moved as percentage of high DOS
		dw	?
OPROG_STR ends

@OPF_BESTDIRTY	equ	8000h	; When set, best data needs to be redisplayed

TIME_STR	struc
 TIME_HOURS	dw	?	; HH
 TIME_COL1	db	?	; :
 TIME_MINS	dw	?	; MM
 TIME_COL2	db	?	; :
 TIME_SECS	dw	?	; SS
 TIME_NULL	db	?	; 0
TIME_STR	ends

@LONGWORDS equ	5		; Number of words per long integer

; These sizes (in bytes) include space for a trailing null.
@LONGSPC equ	31		; Number of digits & commas needed for long
				; integer (Decimal digits + digits div 3)
@DDSPC	 equ	8		; Space needed for nnn,nnn bytes
@HMSSPC  equ	size TIME_STR	; Space needed for HH:MM:SS,0
@PCTDSPC equ	7		; Space needed for xxx.x%,0

; Define size of subsegment display field
@SUBSID_TXTLEN equ 12		; Length of text to appear in output
@SUBSID_TXT substr <'                >,2,@SUBSID_TXTLEN ; Text to initialize SUBSID_TXT
@SUBSID_TXT catstr <'>,@SUBSID_TXT
@SUBSID_TXT catstr @SUBSID_TXT,<'>

