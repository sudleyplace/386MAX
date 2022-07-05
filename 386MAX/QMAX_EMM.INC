;' $Header:   P:/PVCS/MAX/386MAX/QMAX_EMM.INV   1.1   08 Oct 1996 13:45:58   BOB  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; QMAX_EMM.INC
;
; Structures and equates for EMM functions
;

; Allocation types

@ALLOC_XMS  equ  0		; XMS allocation ( 1KB boundary)
@ALLOC_VCPI equ  1		; VCPI ...	   4KB
@ALLOC_EMS  equ  2		; EMS ...	  16KB
@ALLOC_DPMI equ  3		; DPMI ...	   1KB
@ALLOC_XMS2 equ  4		; XMS  ...	   1KB w/o physical boundaries

; EMS handle numbers

@OSE_HNDL equ	 0		; OS/E handle
@SCR_HNDL equ	 254		; SCREEN handle
@NUL_HNDL  equ	 255		; NUL pseudo-handle
@FREE_HNDL equ	 255		; EMS free chain pseudo-handle
@VMS_HNDL  equ	 256		; VCPI/XMS free chain pseudo-handle

@UNMAP_PTE equ	 0FFFF0000h	; Unmap PTE is this plus N*1000h


; Equates for EMM_FLAG

@EMM_NOSE  equ	 8000h		; No OS/E functions allowed
@EMM_INUSE equ	 4000h		; Access key in use
@EMM_SET28 equ	 2000h		; Function 28 set has been done

; Structure for map of PMRs, one for each 16KB page

RPN_STR  struc			; RPNCUR structure

RPN_RPN  dw	 ?		; Relative page #

RPN_STR  ends


; Structure for handle and map of PMRs in EMS frame

HFRM_STR struc

HFRM_OWNR db	 ?		; Owning handle for this layer
HFRM_SAVE db	 ?		; A complete copy of PMR_MAP

HFRM_STR ends


; Structure for HNDLPAGE/PAGELINK tables

PL_STR	 struc			; PAGELINK structure

PL_NEXT  dd	 ?		; Link to next entry

PL_STR	 ends


