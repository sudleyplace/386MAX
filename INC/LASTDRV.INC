;' $Header:   P:/PVCS/MAX/INC/LASTDRV.INV   1.0   05 Sep 1995 13:27:42   HENRY  $
;
; Current directory structure
;
; Allocated by LASTDRIVE= parameter; contains current directory
; and other info for each drive in the system.
;

CDIR_STR struc

CDIR_PATH db 43h dup (?)	; 00: Current path for drive (ASCIIZ)
CDIR_FLAGS dw	 ?		; 43: Flags (defined below as @CDF_xxx)
CDIR_LPDPB dd	 ?		; 45: Far pointer to DPB
CDIR_SCLUST dw	 ?,?		; 49: Starting cluster of dir or -1, filler -1
				; If network, far pointer to REDIRIFS record
CDIR_5F03 dw	 ?		; 4D: Network only: stored value from Int 21
CDIR_ROOT dw	 ?		; 4F: Offset of root '\' in path

; DOS 4.0 and higher only:
CDIR_UNK1 db	 ?		; 51: Used by network (???)
CDIR_LPIFS dd	 ?		; 52: Far pointer to IFS driver (0 if DOS)
CDIR_UNK2 dw	 ?		; 56: Unknown

CDIR_STR ends

CDFLAGS record $CDF_TYP:2,$CDF_JOIN:1,$CDF_SUBST:1,$CDF_RSVD:12;

@CDFT_INVAL equ  00b		; Invalid CDF_TYP value
@CDFT_PHYS equ	 01b		; Physical drive
@CDFT_NET equ	 10b		; Network drive
@CDFT_IFS equ	 11b		; Installable file system (IFS)

@CDF_JOIN equ	 mask $CDF_JOIN ; JOIN: current path does not include JOIN
@CDF_SUBST equ	 mask $CDF_SUBST ; SUBST: "      "    "    "     "    SUBST

