;' $Header:   P:/PVCS/MAX/MAXIMIZE/INS_ADP.ASV   1.1   30 May 1997 11:45:44   BOB  $
	 title	 INS_ADP.ASM -- ADP Subroutines for Maximize
	 page	 58,122
	 name	 INS_ADP

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-97 Qualitas, Inc.  All rights reserved.

|

comment |	ins_adp.pro
int load_adp (char far *, WORD far *);
DWORD xaddr (int, int);
void exec_adp (WORD, struct _exec_block far *);
|
.model medium,c

.data

PUBLIC	EXEC_BLOCK

EXEC_BLOCK	LABEL	BYTE	;DOS LOAD/EXEC parameter block
LOAD_SEG	DW	0	;Segment to load ADP
		DW	0

ADP_ENTRY	DW	100H	;ADP execution entry point
ADP_SEG 	DW	0

.code

		PUBLIC	load_adp,exec_adp,free_adp,xaddr

;___ addr _____________________________________________________

;	Creates a DWORD out of the RQP high and low words

ADDR_FRAME	STRUC
		DW	?	;Callers BP
		DW	(1+@codesize) dup (?) ; Return Address CS:IP or IP
$HIGH		DW	?	;High part
$LOW		DW	?	;Low part
ADDR_FRAME	ENDS

xaddr		PROC
		PUSH	BP
		MOV	BP,SP
		MOV	DX,[BP].$HIGH
		MOV	AX,[BP].$LOW
		POP	BP
		RET
xaddr		ENDP

;--------------------------------------------------------------

; Loads an ADP into an allocated block and returns the segment address

LOAD_FRAME	STRUC
		DW	?	;Callers BP
		DW	(1+@codesize) dup (?) ; Return Address CS:IP or IP
ADP_PATH	DD	?	;Ptr to adapter path string
ADP_BLK_PTR	DD	?	;Ptr to return ADP address
LOAD_FRAME	ENDS

load_adp	PROC
		PUSH	BP	;Save the registers important to C
		MOV	BP,SP
		PUSH	SI
		PUSH	DI
		PUSH	DS
		PUSH	ES

		MOV	AX,DGROUP
		MOV	DS,AX
		MOV	ES,AX

		MOV	BX,640		;Request a memory block of 10K
					;10K limit on ADP size by IBM doc
		MOV	AH,48H		;If memory size limited, this
		INT	21H		;should be changed to allocate only
		JC	LOAD_ERR	;required amount.

		LES	BX,[BP].ADP_BLK_PTR	;Get address of seg ptr
		MOV	WORD PTR ES:[BX],AX	;Return seg address

		MOV	LOAD_SEG,AX	  ;Save block address
		LEA	BX,EXEC_BLOCK
		LDS	DX,[BP].ADP_PATH  ;Get address of path
		MOV	AX,DGROUP
		MOV	ES,AX
		MOV	AX,4B03H	;Load the ADP into the block
		INT	21H
		JC	LOAD_ERR

		XOR	AX,AX		;Return zero, for no error

LOAD_ERR:	POP	ES
		POP	DS
		POP	DI
		POP	SI
		POP	BP
		RET
load_adp	ENDP

;____ exec_adp ______________________________________________________

;  This is the entry point for the ADP call
;
;     Functions defined:   01  config adapter in one slot
;			   02  config all adapters of this type
;			   03  deallocate adapter in one slot
;			   04  deallocate all adapters of this type
;			   05  deduce the configuration of one adpter
;			   06  disable a block of system memory
;			   07  remap the memory to above 16MB
;			   08  remap the memory to below 16MB
;
;	C Calling sequence: exec_adp(adp_block, &eblk)
;		     where: struct _exec_block eblk;
;			    char adp_path[];
;

EXEC_FRAME	STRUC
		DW	?	;Callers BP
		DW	(1+@codesize) dup (?) ; Return Address CS:IP or IP
ADP_BLOCK	DW	?	;Segment address of ADP block
EBLK_ADDR	DD	?	;Ptr to adp exec block
EXEC_FRAME	ENDS

exec_adp	PROC
		PUSH	BP	;Save the registers important to C
		MOV	BP,SP
		PUSH	SI
		PUSH	DI
		PUSH	DS
		PUSH	ES

		MOV	AX,DGROUP
		MOV	DS,AX

		MOV	AX,[BP].ADP_BLOCK
		MOV	ADP_SEG,AX	  ;Construct far call to ADP
		LES	BX,[BP].EBLK_ADDR
		PUSH	ES
		PUSH	BX
		CALL	DWORD PTR ADP_ENTRY
		ADD	SP,4		;Remove eblk addr from stack

		POP	ES
		POP	DS
		POP	DI
		POP	SI
		POP	BP
		RET
exec_adp	ENDP

;____ free_adp _______________________________________________

; Release the memory block associated with and ADP

FREE_FRAME	STRUC
		DW	?	;Callers BP
		DW	(1+@codesize) dup (?) ; Return Address CS:IP or IP
ADP_BLK 	DW	?	;Segment address of ADP block
FREE_FRAME	ENDS

free_adp	PROC
		PUSH	BP	;Save the registers important to C
		MOV	BP,SP
		PUSH	DS
		PUSH	ES

		MOV	AX,DGROUP
		MOV	DS,AX

		MOV	AX,[BP].ADP_BLK ;Get segment address of block
		MOV	ES,AX
		MOV	AH,49H		;Release it
		INT	21H

		POP	ES
		POP	DS
		POP	BP
		RET
free_adp	ENDP
if (@Version LT 600)
IF1
    %OUT PASS 1 COMPLETE
ELSE
    %OUT PASS 2 COMPLETE
ENDIF
endif ;(@Version LT 600)
		END
