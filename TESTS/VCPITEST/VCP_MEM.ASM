;' $Header:   P:/PVCS/MISC/VCPITEST/VCP_MEM.ASV   1.1   22 Feb 1994 12:31:42   HENRY  $

	 title	 VCP_MEM -- VCPI Memory Allocation Routines
	 page	 58,122
	 name	 VCP_MEM
	 include DIRNTRY.INC	; Include the file's directory entry

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1988-94 Qualitas, Inc.

Environment:  IBM PC, tested under DOS 3.30.

Segmentation:  Group PGROUP:
	       Program segment CODE,  byte-aligned,  public, class 'prog'
	       Data    segment DATA,  dword-aligned, public, class 'data'
	       Data    segment TEXT,  byte-aligned,  public, class 'data'
	       Tail    segment DTAIL, byte-aligned,  public, class 'data'

Link requirements:  None, standalone subroutine.

Program derived from:  None.

Original code by:  Bob Smith, September, 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include DOSCALL.INC
	 include ASCII.INC
	 include VCPI.INC

	 include VCP_TEST.INC
	 include EMM2CALL.INC
.list


PGROUP	 group	 CODE,DATA,TEXT,DTAIL


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 PORT67:word

	 extrn	 CMD_FLAG:word
	 include VCP_FLAG.INC

	 extrn	 ERRMSG:word
	 extrn	 ERRCODE:byte

	 public  NFREE,NFREE_R1,NFREE_R2,NFREE_R3,NFREE_R4
	 public  NFREE_F1,NFREE_F2,NFREE_F3,MPA
NFREE	 dd	 ?		; # free pages
NFREE_R1 dd	 ?		; # pages to free in round #1
NFREE_R2 dd	 ?		; ...			   #2
NFREE_R3 dd	 ?		; ...			   #3
NFREE_R4 dd	 ?		; ...			   #4
NFREE_F1 dd	 ?		; # pages free after round #1
NFREE_F2 dd	 ?		; ...			   #2
NFREE_F3 dd	 ?		; ...			   #3
MPA	 dd	 ?		; Maximum physical memory address

	 public  MSG_FREE
MSG_FREE db	 'There are '
MSG_FREE1 db	 '________h available 4KB pages.',CR,LF,EOS

	 public  MSG_MPA
MSG_MPA  db	 'The maximum physical memory address is '
MSG_MPA1 db	 '________h.',CR,LF,EOS

DATA	 ends			; End DATA segment


DTAIL	 segment use16 para public 'data' ; Start DTAIL segment
	 assume  ds:PGROUP

	 extrn	 ZTAIL:byte

DTAIL	 ends			; End DTAIL segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP,ds:nothing,es:nothing

	 extrn	 BIN2DWORD:near

	 NPPROC  CHECK_ALLOC -- Check on Allocation and De-allocation
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing
COMMENT|

Check on VCPI allocation and de-allocation

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers

	 DISPLAY '様> Getting maximum physical memory address...'

	 VCPIBACK @VCPI_GMPA	; Return in EDX
	 mov	 MPA,edx	; Save for later use

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to get maximum physical memory address",ERR
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

	 mov	 eax,MPA	; Get maximum physical memory address
	 lea	 di,MSG_MPA1	; ES:DI ==> output save area
	 call	 BIN2DWORD	; Convert EAX to hex at ES:DI

	 DOSCALL @STROUT,MSG_MPA ; Display the message

	 DISPLAY '様> Checking for # free pages...'

	 VCPIBACK @VCPI_GNFP	; Get # free pages

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to get free page count",ERR
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

	 xor	 eax,eax	; Zero accumulator
	 mov	 NFREE,edx	; Save for later use
	 shr	 edx,2		; Divide by # interleaved rounds
	 mov	 NFREE_R1,edx	; Save for later use
	 add	 eax,edx	; Add into accumulator
	 mov	 NFREE_F1,eax	; Save for later use
	 mov	 NFREE_R2,edx	; Save for later use
	 add	 eax,edx	; Add into accumulator
	 mov	 NFREE_F2,eax	; Save for later use
	 mov	 NFREE_R3,edx	; Save for later use
	 add	 eax,edx	; Add into accumulator
	 mov	 NFREE_F3,eax	; Save for later use
	 mov	 NFREE_R4,edx	; Save for later use
	 shl	 edx,2		; Restore

	 sub	 edx,NFREE	; Subtract total # (result is non-positive)
	 jz	 short @F	; Jump if it came out even

	 inc	 NFREE_R1	; Free an extra page in round #1
	 inc	 NFREE_F1	; One more freed
	 inc	 NFREE_F2	; One more freed
	 inc	 NFREE_F3	; One more freed
	 inc	 edx		; Account for it
	 jz	 short @F	; Jump if no remainder

	 inc	 NFREE_R2	; Free an extra page in round #2
	 inc	 NFREE_F2	; One more freed
	 inc	 NFREE_F3	; One more freed
	 inc	 edx		; Account for it
	 jz	 short @F	; Jump if no remainder

	 inc	 NFREE_R3	; Free an extra page in round #3
	 inc	 NFREE_F3	; One more freed
@@:
	 mov	 eax,NFREE	; Get # free pages
	 lea	 di,MSG_FREE1	; ES:DI ==> output save area
	 call	 BIN2DWORD	; Convert EAX to hex at ES:DI

	 DOSCALL @STROUT,MSG_FREE ; Display the message

; Allocate all pages

	 call	 ALLOCSUB	; Use subroutine
	 jc	 near ptr CHECK_ALLOC_ERR ; Jump if something went wrong

; Now free the pages in ascending order

	 DISPLAY '様> Freeing pages in ascending order...'

	 mov	 ecx,NFREE	; Get # free pages
	 lea	 si,ZTAIL	; DS:SI ==> end of our program
@@:
	 lodsd			; Get next physical address
	 mov	 edx,eax	; Copy to input register
	 VCPIBACK @VCPI_FREE	; Free the 4KB page in EDX

	 cmp	 ah,0		; Ensure no error
	 SETMSG  "Error freeing 4KB page in ascending order",ERR
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

	 loop	 dword ptr @B	; Jump if more pages to free

; Attempt to free an extra page

;;;;;;;; DISPLAY '様> Attempting to free extra page...'
;;;;;;;;
;;;;;;;; lea	 si,ZTAIL	; DS:SI ==> end of our program
;;;;;;;; lodsd			; Get next physical address
;;;;;;;; mov	 edx,eax	; Copy to input register
;;;;;;;; VCPIBACK @VCPI_FREE	; Free the 4KB page in EDX
;;;;;;;;
;;;;;;;; cmp	 ah,8Ah 	; Ensure correct error
;;;;;;;; SETMSG  "Incorrect error freeing extra 4KB page",ERR
;;;;;;;; jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

; Ensure the free page count is the same

	 DISPLAY '様> Checking free page count...'

	 VCPIBACK @VCPI_GNFP	; Get # free pages

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to get free page count",ERR
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

	 cmp	 edx,NFREE	; Check it
	 SETMSG  "Mis-match on free page count, freed in ascending order"
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

; Allocate all pages

	 call	 ALLOCSUB	; Use subroutine
	 jc	 near ptr CHECK_ALLOC_ERR ; Jump if something went wrong

; Now free the pages in descending order

	 DISPLAY '様> Freeing pages in descending order...'

	 lea	 si,ZTAIL	; DS:SI ==> end of our program
	 mov	 eax,NFREE	; Get # free pages
	 dec	 eax		; Less one for last page
	 shl	 eax,2-0	; Convert from dwords to bytes
	 add	 si,ax		; DS:SI ==> last physical address

	 mov	 ecx,NFREE	; Get # free pages
@@:
	 std			; String ops backwards
	 lodsd			; Get next physical address
	 mov	 edx,eax	; Copy to input register
	 VCPIBACK @VCPI_FREE	; Free the 4KB page in EDX
	 cld			; String ops forwards

	 cmp	 ah,0		; Ensure no error
	 SETMSG  "Error freeing 4KB page in descending order",ERR
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

	 loop	 dword ptr @B	; Jump if more pages to free

; Attempt to free an extra page

;;;;;;;; DISPLAY '様> Attempting to free extra page...'
;;;;;;;;
;;;;;;;; lea	 si,ZTAIL	; DS:SI ==> end of our program
;;;;;;;; lodsd			; Get next physical address
;;;;;;;; mov	 edx,eax	; Copy to input register
;;;;;;;; VCPIBACK @VCPI_FREE	; Free the 4KB page in EDX
;;;;;;;;
;;;;;;;; cmp	 ah,8Ah 	; Ensure correct error
;;;;;;;; SETMSG  "Incorrect error freeing extra 4KB page",ERR
;;;;;;;; jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

; Ensure the free page count is the same

	 DISPLAY '様> Checking free page count...'

	 VCPIBACK @VCPI_GNFP	; Get # free pages

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to get free page count",ERR
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

	 cmp	 edx,NFREE	; Check it
	 SETMSG  "Mis-match on free page count, freed in descending order"
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

; Allocate all pages

	 call	 ALLOCSUB	; Use subroutine
	 jc	 near ptr CHECK_ALLOC_ERR ; Jump if something went wrong

; Now free the pages in ascending interleaved order

	 DISPLAY '様> Freeing pages in ascending interleaved order, round #1...'

	 mov	 ecx,NFREE_R1	; Get # pages to free in round #1
	 lea	 si,ZTAIL[0]	; DS:SI ==> end of our program
@@:
	 lodsd			; Get next physical address
	 add	 esi,16-4	; Skip to next block of 4 PTEs
	 mov	 edx,eax	; Copy to input register
	 VCPIBACK @VCPI_FREE	; Free the 4KB page in EDX

	 cmp	 ah,0		; Ensure no error
	 SETMSG  "Error freeing 4KB page in ascending interleaved order",ERR
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

	 loop	 dword ptr @B	; Jump if more pages to free

; Ensure the free page count is correct

	 DISPLAY '様> Checking free page count after round #1...'

	 VCPIBACK @VCPI_GNFP	; Get # free pages

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to get free page count",ERR
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

	 cmp	 edx,NFREE_F1	; Check it
	 SETMSG  "Mis-match on free page count, freed in ascending interleaved order"
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

; Free ascending interleaved pages, round #2

	 DISPLAY '様> Freeing pages in ascending interleaved order, round #2...'

	 mov	 ecx,NFREE_R2	; Get # pages to free in round #2
	 lea	 si,ZTAIL[4]	; DS:SI ==> end of our program
@@:
	 lodsd			; Get next physical address
	 add	 esi,16-4	; Skip to next block of 4 PTEs
	 mov	 edx,eax	; Copy to input register
	 VCPIBACK @VCPI_FREE	; Free the 4KB page in EDX

	 cmp	 ah,0		; Ensure no error
	 SETMSG  "Error freeing 4KB page in ascending interleaved order",ERR
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

	 loop	 dword ptr @B	; Jump if more pages to free

; Ensure the free page count is correct

	 DISPLAY '様> Checking free page count after round #2...'

	 VCPIBACK @VCPI_GNFP	; Get # free pages

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to get free page count",ERR
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

	 cmp	 edx,NFREE_F2	; Check it
	 SETMSG  "Mis-match on free page count, freed in ascending interleaved order"
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

; Free ascending interleaved pages, round #3

	 DISPLAY '様> Freeing pages in ascending interleaved order, round #3...'

	 mov	 ecx,NFREE_R3	; Get # pages to free in round #3
	 lea	 si,ZTAIL[8]	; DS:SI ==> end of our program
@@:
	 lodsd			; Get next physical address
	 add	 esi,16-4	; Skip to next block of 4 PTEs
	 mov	 edx,eax	; Copy to input register
	 VCPIBACK @VCPI_FREE	; Free the 4KB page in EDX

	 cmp	 ah,0		; Ensure no error
	 SETMSG  "Error freeing 4KB page in ascending interleaved order",ERR
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

	 loop	 dword ptr @B	; Jump if more pages to free

; Ensure the free page count is correct

	 DISPLAY '様> Checking free page count after round #3...'

	 VCPIBACK @VCPI_GNFP	; Get # free pages

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to get free page count",ERR
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

	 cmp	 edx,NFREE_F3	; Check it
	 SETMSG  "Mis-match on free page count, freed in ascending interleaved order"
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

; Free ascending interleaved pages, round #4

	 DISPLAY '様> Freeing pages in ascending interleaved order, round #4...'

	 mov	 ecx,NFREE_R4	; Get # pages to free in round #4
	 lea	 si,ZTAIL[12]	; DS:SI ==> end of our program
@@:
	 lodsd			; Get next physical address
	 add	 esi,16-4	; Skip to next block of 4 PTEs
	 mov	 edx,eax	; Copy to input register
	 VCPIBACK @VCPI_FREE	; Free the 4KB page in EDX

	 cmp	 ah,0		; Ensure no error
	 SETMSG  "Error freeing 4KB page in ascending interleaved order",ERR
	 jne	 short CHECK_ALLOC_ERR ; Jump if in error

	 loop	 dword ptr @B	; Jump if more pages to free

; Attempt to free an extra page

;;;;;;;; DISPLAY '様> Attempting to free extra page...'
;;;;;;;;
;;;;;;;; lea	 si,ZTAIL	; DS:SI ==> end of our program
;;;;;;;; lodsd			; Get next physical address
;;;;;;;; mov	 edx,eax	; Copy to input register
;;;;;;;; VCPIBACK @VCPI_FREE	; Free the 4KB page in EDX
;;;;;;;;
;;;;;;;; cmp	 ah,8Ah 	; Ensure correct error
;;;;;;;; SETMSG  "Incorrect error freeing extra 4KB page",ERR
;;;;;;;; jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

; Ensure the free page count is correct

	 DISPLAY '様> Checking free page count...'

	 VCPIBACK @VCPI_GNFP	; Get # free pages

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to get free page count",ERR
	 jne	 near ptr CHECK_ALLOC_ERR ; Jump if in error

	 cmp	 edx,NFREE	; Check it
	 SETMSG  "Mis-match on free page count, freed in ascending interleaved order"
	 jne	 short CHECK_ALLOC_ERR ; Jump if in error











	 clc			; Indicate present

	 jmp	 short CHECK_ALLOC_EXIT ; Join common exit code

CHECK_ALLOC_ERR:
	 stc			; Indicate not present
CHECK_ALLOC_EXIT:
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

CHECK_ALLOC endp		; End CHECK_ALLOC procedure
	 NPPROC  ALLOCSUB -- Allocate Subroutine
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing
COMMENT|

Allocate all 4KB pages and place the physical addresses at ZTAIL

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,ecx,di>	; Save registers

	 DISPLAY '様> Allocating all free pages...'

	 mov	 ecx,NFREE	; Get # free pages
	 lea	 di,ZTAIL	; ES:DI ==> end of our program
@@:
	 VCPIBACK @VCPI_ALLOC	; Allocate a 4KB page

	 cmp	 ah,0		; Ensure no error
	 SETMSG  "Error allocating 4KB page",ERR
	 jne	 short ALLOCSUB_ERR ; Jump if in error

	 mov	 eax,edx	; Copy to output register
	 stosd			; Save in output area

	 loop	 dword ptr @B	; Jump if more pages to allocate

; Ensure we get an error if we try to allocate one more page

	 VCPIBACK @VCPI_ALLOC	; Allocate a 4KB page

	 cmp	 ah,88h 	; Ensure correct error
	 SETMSG  "Failure to get 88h error allocating 4KB page",ERR
	 jne	 short ALLOCSUB_ERR ; Jump if in error

; Ensure the # free pages is zero

	 DISPLAY '様> Checking free page count...'

	 VCPIBACK @VCPI_GNFP	; Get # free pages

	 cmp	 ah,0		; Check for error
	 SETMSG  "Unable to get free page count",ERR
	 jne	 near ptr ALLOCSUB_ERR ; Jump if in error

	 cmp	 edx,0		; Check it
	 SETMSG  "Mis-match on free page count after allocating all pages"
	 jne	 short ALLOCSUB_ERR ; Jump if in error

	 clc			; Indicate all went asll

	 jmp	 short ALLOCSUB_EXIT ; Join common exit code

ALLOCSUB_ERR:
	 stc			; Indicate something went wrong
ALLOCSUB_EXIT:
	 REGREST <di,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing

ALLOCSUB endp			; End ALLOCSUB procedure

CODE	 ends			; End CODE segment

	 MEND			; End VCP_MEM module
