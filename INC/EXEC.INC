;' $Header:   P:/PVCS/MAX/INC/EXEC.INV   1.0   05 Sep 1995 13:26:46   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; EXEC.INC
;
; DOS Load and Execute (4B00) structure
;

EXEC_STR struc

EXEC_ENV dw	 ?		; Segment of environment
EXEC_CMD dd	 ?		; Seg:off of command line
EXEC_FCB1 dd	 ?		; ...	     FCB #1
EXEC_FCB2 dd	 ?		; ...		 #2

EXEC_STR ends


EXECD_STR struc 		; Used for 32-bit EXEC calls

EXECD_CMD df	 ?		; Sel|off of command line
EXECD_FCB1 df	 ?		; ...	     FCB #1
EXECD_FCB2 df	 ?		; ...		 #2

EXECD_STR ends


; 4B01:  DOS Load and Debug structure

LOADDBG_STR struc

LOADDBG_ENV dw	 ?		; Segment of environment
LOADDBG_CMD dd	 ?		; Seg:off of command line
LOADDBG_FCB1 dd  ?		; ...	     FCB #1
LOADDBG_FCB2 dd  ?		; ...		 #2
LOADDBG_SSSP dd  ?		; SS:SP of loaded program (filled in by DOS)
LOADDBG_CSIP dd  ?		; CS:IP ...

LOADDBG_STR ends


; 4B03:  DOS Load Overlay structure

LOADOVL_STR struc

LOADOVL_SEG dw	 ?		; Segment of load point
LOADOVL_REL dw	 ?		; Relocation factor

LOADOVL_STR ends


; 4B05:  DOS Enter Exec State structure

EES_STR  struc

	 dw	 0		; Reserved
EES_FLAGS dw	 0		; Flags (see @EES_ below)
EES_NAME dd	 ?		; Ptr to ASCIIZ program name (including d:\path\)
EES_PSP  dw	 ?		; Segment # of PSP
EES_CSIP dd	 ?		; CS:IP of start of program
EES_SIZE dd	 ?		; Program size in bytes including PSP

EES_STR  ends


@EES_EXE equ	 0001h		; Program is an EXE
@EES_OVL equ	 0002h		; Program is an overlay

