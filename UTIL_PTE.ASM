; $Header:   P:/PVCS/MAX/386MAX/UTIL_PTE.ASV   1.3   08 Jul 1998 12:30:14   BOB  $
	 title	 UTIL_PTE -- 386UTIL/MOVE'EM PTE Display
	 page	 58,122
	 name	 UTIL_PTE

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1992-8 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Data    segment NDATA,	dword-aligned, public, class 'ndata'
	       Tail    segment ZZTAIL,	dword-aligned, public, class 'data'

Program derived from:  None.

Original code by:  Bob Smith, May, 1988.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include ASCII.INC
	 include 386.INC
	 include PTR.INC
	 include IOCTL.INC
	 include KEYCALL.INC
	 include BITFLAGS.INC
	 include EMM2CALL.INC

	 include QMAX_OEM.INC
.list


PGROUP	 group	 CODE,DATA,NDATA,ZZTAIL


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 TOTSIZE:dword

	 public  WRAPFLAG
WRAPFLAG db	 0		; 0 = 1MB wrap disabled
				; 1 = ...      enabled

	 public  MSG_WRP0,MSG_WRP1,MSG_LGND
MSG_WRP0 db	 '   PTEs shown as if 1MB wrap disabled, use PTE1 to show with wrap enabled.',CR,LF,EOS
MSG_WRP1 db	 '   PTEs shown as if 1MB wrap enabled, use PTE0 to show with wrap disabled.',CR,LF,EOS
MSG_LGND db	 '   Legend:  Ø means PTEs are one-to-one',CR,LF,EOS

	 public  MSG_HDR2
ifdef LANG_GR
MSG_HDR2 db	 'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸',CR,LF
	 db	 '³                       ABBILD DER SEITENTABELLEN-EINTRŽGE                    ³',CR,LF
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF
	 db	 '³ Lineare Adresse   ³Physikalische Addr.³ L„nge³ Typ                          ³',CR,LF
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,EOS
else
MSG_HDR2 db	 'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸',CR,LF
	 db	 '³                         PAGE TABLE ENTRIES MAP                              ³',CR,LF
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF
	 db	 '³   Linear address  ³  Physical address ³  Len ³ Type                         ³',CR,LF
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,EOS
endif

	 public  MSG_TAIL
MSG_TAIL db	 'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',CR,LF,EOS

	 public  MSG_PTE
MSG_PTE  db	 '³ '
MSG_PTE1 db	 '________-'
MSG_PTE2 db	 '________ '
MSG_PTE_SEP db	 '³ '
MSG_PTE3 db	 '________-'
MSG_PTE4 db	 '________ ³    '
MSG_PTE_LEN db	 '_ ³ ',EOS

	 public  BITTAB
	 even
BITTAB	 dw	 PGROUP:BIT000
	 dw	 PGROUP:BIT001
	 dw	 PGROUP:BIT010
	 dw	 PGROUP:BIT011
	 dw	 PGROUP:BIT100
	 dw	 PGROUP:BIT101
	 dw	 PGROUP:BIT110
	 dw	 PGROUP:BIT111

BIT000	 db	 'ROM, supervisor, not present ³',CR,LF,EOS
BIT001	 db	 'ROM, supervisor, present     ³',CR,LF,EOS
BIT010	 db	 'R/W, supervisor, not present ³',CR,LF,EOS
BIT011	 db	 'R/W, supervisor, present     ³',CR,LF,EOS
BIT100	 db	 'ROM, user, not present       ³',CR,LF,EOS
BIT101	 db	 'ROM, user, present           ³',CR,LF,EOS
BIT110	 db	 'R/W, user, not present       ³',CR,LF,EOS
BIT111	 db	 'R/W, user, present           ³',CR,LF,EOS

DATA	 ends			; End DATA segment


NDATA	 segment use16 dword public 'ndata' ; Start NDATA segment
	 assume  ds:PGROUP

	 extrn	 CON4KB:dword
	 extrn	 PORT67:word
if @OEM_WIN3
	 extrn	 MSG_WINERR:byte
	 extrn	 WINRUN:byte
endif				; IF @OEM_WIN3


NDATA	 ends			; End NDATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

ZZTAIL	 segment use16 dword public 'data' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 extrn	 ZTAIL:byte

ZZTAIL	 ends			; End ZZTAIL segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 BIN2BASE:near
	 extrn	 DD2HEX:near
	 extrn	 STROUT:near

	 NPPROC  ACT_PTE1 -- Action to Display Page Table Entries, Wrap Enabled
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

|

	 mov	 WRAPFLAG,1	; Save Wrap Flag enabled for later

	 call	 ACT_PTE	; Join common action code

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_PTE1 endp			; End ACT_PTE1 procedure
	 NPPROC  ACT_PTE -- Action to Display Page Table Entries
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 pushad 		; Save all EGP registers
	 REGSAVE <ds,es>	; Save segment registers

if @OEM_WIN3
	 cmp	 WINRUN,1	; Are we running under Windows?
	 je	 near ptr GETPTE_WINERR ; Jump if so
endif				; IF @OEM_WIN3

; Read in the PTEs

GETPTE_READ:
	 lea	 edi,ZTAIL	; ES:EDI ==> save area (although the EMM2 call
				; uses ES:DI only)
	 mov	 si,0		; SI = source offset
	 mov	 cx,0		; Get all PTEs
	 mov	 al,WRAPFLAG	; Get 1MB wrap flag
	 mov	 bp,sp		; Save current stack pointer
	 EMMOUT  @EMM2_GETPTE	; Get the PTEs
	 mov	 sp,bp		; Cut back the stack in case of error

	 or	 ah,ah		; Check for error
	 jnz	 near ptr GETPTE_ERR ; Jump if something went wrong

; Because the number of PTEs may be quite large, we can't always rely upon
; the value returned in CX as the table may exceed the 64KB of this segment.
; Instead, we use the total size value.

	 mov	 ecx,TOTSIZE	; Get total size of extended memory
	 add	 ecx,1024	; Plus amount for first megabyte
	 shr	 ecx,2-0	; Convert from bytes to dwords

	 lea	 dx,MSG_HDR2	; DS:DX ==> header
	 call	 STROUT 	; Display header

; Check PTEs for ascending order

	 mov	 ebx,edi	; Copy to safe register
	 mov	 esi,ebx	; Copy to source register
GETPTE_BREAK:

; Convert $PTE_AV1 (meaning the entry is absent) to (not (mask $PTE_P))

	 call	 CHECK_AV1	; Check on it

;;;;;;;; mov	 edx,ds:[si]	; Set initial PTE
	 call	 GET_NEXTPTE	; Return with the PTE at DS:ESI in EAX
	 mov	 edx,eax	; Copy for later use
	 and	 dx,(mask $PTE_FRM) or @PTE_URP ; Isolate important flags
GETPTE_NEXT:

; Convert $PTE_AV1 (meaning the entry is absent) to (not (mask $PTE_P))

	 call	 CHECK_AV1	; Check on it

;;;;;;;; lodsd			; Get next PTE
	 call	 GET_NEXTPTE	; Return with the PTE at DS:ESI in EAX
	 add	 esi,4		; Skip to next PTE
	 and	 ax,(mask $PTE_FRM) or @PTE_URP ; Isolate important flags

	 cmp	 eax,edx	; Same as expected?
	 je	 short GETPTE_LOOP ; Yes, continue on

	 sub	 esi,4		; Back off to first mismatching PTE
	 inc	 ecx		; Account for it

	 call	 DISP_RANGE	; Display the range

	 mov	 ebx,esi	; Set new initial value

	 loopd	 GETPTE_BREAK	; Jump if more PTEs to search

	 jmp	 short GETPTE_TAIL ; Join common tail code

GETPTE_LOOP:
	 add	 edx,CON4KB	; Skip to next expected PTE

	 loop	 GETPTE_NEXT	; Jump if more PTEs to search

	 call	 DISP_RANGE	; Display the range
GETPTE_TAIL:
	 lea	 dx,MSG_TAIL	; DS:DX ==> tail
	 call	 STROUT 	; Display the tail

	 lea	 dx,MSG_WRP0	; Assume disabled

	 cmp	 WRAPFLAG,0	; Check the value
	 je	 short @F	; Good guess

	 lea	 dx,MSG_WRP1	; Assume enabled
@@:
	 call	 STROUT 	; Display 1MB wrap message


	 lea	 dx,MSG_LGND	; DS:DX ==> legend
	 call	 STROUT 	; Display legend

	 clc			; Indicate no error

	 jmp	 short GETPTE_EXIT ; Join common exit code

if @OEM_WIN3
GETPTE_WINERR:
	 lea	 dx,MSG_WINERR	; DS:DX ==> error message
	 call	 STROUT 	; Display the string at DS:DX

	 jmp	 short GETPTE_ERR ; Join common error code
endif				; IF @OEM_WIN3

GETPTE_ERR:
	 stc			; Indicate something went wrong
GETPTE_EXIT:
	 REGREST <es,ds>	; Restore
	 assume  ds:nothing,es:nothing
	 popad			; Restore

	 ret			; Return to DOS

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_PTE  endp			; End ACT_PTE procedure
	 NPPROC  CHECK_AV1 -- Check on $PTE_AV1
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Convert $PTE_AV1 (meaning the entry is absent) to (not (mask $PTE_P))

|

	 push	 eax		; Save for a moment

	 call	 GET_NEXTPTE	; Return with the PTE at DS:ESI in EAX

	 test	 ax,mask $PTE_AV1 ; Izit absent?
	 jz	 short @F	; Not this time

	 and	 ax,not (mask $PTE_P) ; Mark as not present

	 call	 SET_NEXTPTE	; Save EAX as the PTE at DS:ESI
@@:
	 pop	 eax		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

CHECK_AV1 endp			; End CHECK_AV1 procedure
	 NPPROC  DISP_RANGE -- Display Range of PTEs
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display range of PTEs

On entry:

DS:EBX	 ==>	 initial PTE
DS:ESI-4 ==>	 ending PTE

|

; Display initial [EBX] and ending offsets [ESI-4]

	 REGSAVE <eax,cx,edx,di> ; Save registers

	 mov	 eax,ebx	; Get initial offset
	 sub	 eax,offset ds:ZTAIL ; Convert to origin-0
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	 mov	 edx,eax	; Save for later use

	 lea	 di,MSG_PTE1	; ES:DI ==> output save area
	 call	 DD2HEX 	; Convert EAX to hex at ES:DI

	 mov	 eax,esi	; Get ending+4 offset
	 sub	 eax,4		; Back off to last entry
	 sub	 eax,offset ds:ZTAIL ; Convert to origin-0
	 shl	 eax,(12-2)-0	; Convert from 4KB in dwords to bytes
	 push	 ax		; Save for a moment
	 or	 ax,not (mask $PTE_FRM) ; Set low-order FFF
	 lea	 di,MSG_PTE2	; ES:DI ==> output save area
	 call	 DD2HEX 	; Convert EAX to hex at ES:DI
	 pop	 ax		; Restore

; Display length of region

	 sub	 eax,edx	; Subtract to get length in bytes
	 shr	 eax,10-0	; Convert from bytes to 1KB
	 add	 eax,4		; Count in last PTE
	 lea	 di,MSG_PTE_LEN ; ES:DI ==> output save area
	 mov	 [di-3].EDD,'    ' ; Clear previous value
	 mov	 [di-4].LO,' '  ; ...
	 mov	 cx,10		; Use this base number system for conversion
	 call	 BIN2BASE	; Convert AX to ASCII ending at ES:DI

; Display initial (ds:[ebx]) and ending PTEs (ds:[esi-4])

;;;;;;;; mov	 eax,ds:[bx]	; Get initial PTE
	 xchg	 ebx,esi	; Swap to get PTE at DS:EBX
	 call	 GET_NEXTPTE	; Return with the PTE at DS:ESI in EAX
	 xchg	 ebx,esi	; Restore
	 and	 ax,mask $PTE_FRM ; Isolate the page bits
	 lea	 di,MSG_PTE3	; ES:DI ==> output save area
	 call	 DD2HEX 	; Convert EAX to hex at ES:DI

; Set separator if one-to-one

	 cmp	 eax,edx	; Check for one-to-one
	 mov	 MSG_PTE_SEP,'Ø' ; Assume so
	 je	 short @F	; Jump if so

	 mov	 MSG_PTE_SEP,'³' ; Not one-to-one
@@:
;;;;;;;; mov	 eax,ds:[si-4]	; Get ending PTE
	 sub	 esi,4		; Back off to last entry
	 call	 GET_NEXTPTE	; Return with the PTE at DS:ESI in EAX
	 add	 esi,4		; Restore
	 or	 ax,not (mask $PTE_FRM) ; Set low-order FFF
;;;;;;;; and	 ax,mask $PTE_FRM ; Isolate the page bits
	 lea	 di,MSG_PTE4	; ES:DI ==> output save area
	 call	 DD2HEX 	; Convert EAX to hex at ES:DI

	 lea	 dx,MSG_PTE	; DS:DX ==> the line
	 call	 STROUT 	; Display the line

;;;;;;;; movzx	 di,ds:[bx].LO	; Get common PTE bits
	 xchg	 ebx,esi	; Swap to get PTE at DS:EBX
	 call	 GET_NEXTPTE	; Return with the PTE at DS:ESI in EAX
	 xchg	 ebx,esi	; Restore
	 movzx	 di,al		; Get common PTE bits
	 and	 di,@PTE_URP	; Isolate PTE bits
	 shl	 di,1		; Times two to index table of words
	 mov	 dx,BITTAB[di]	; DS:DX ==> explanatory text
	 call	 STROUT 	; Display the text

	 REGREST <di,edx,cx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_RANGE endp 		; End DISP_RANGE procedure
	 NPPROC  GET_NEXTPTE -- Get Next PTE
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Get next PTE.  Take into account that DS:ESI might exceed 64KB.

On entry:

DS:ESI	 ==>	 next PTE

On exit:

EAX	 =	 next PTE

|

	 REGSAVE <ebx,ecx,ds>	; Save registers

	 mov	 ebx,esi	; Copy the offset
	 ror	 ebx,4-0	; Convert from bytes to paras,
				; retaining the low-order nibble
	 mov	 cx,ds		; Copy base segment
	 add	 cx,bx		; Add to get normalized segment
	 mov	 ds,cx		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 rol	 ebx,4-0	; Convert from paras to bytes
	 and	 bx,@NIB0	; Isolate the low-order nibble
	 mov	 eax,ds:[bx]	; Get the next PTE

	 REGREST <ds,ecx,ebx>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

GET_NEXTPTE endp		; End GET_NEXTPTE procedure
	 NPPROC  SET_NEXTPTE -- Set Next PTE
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Set next PTE.  Take into account that DS:ESI might exceed 64KB.

On entry:

EAX	 =	 next PTE
DS:ESI	 ==>	 next PTE

|

	 REGSAVE <ebx,ecx,ds>	; Save registers

	 mov	 ebx,esi	; Copy the offset
	 ror	 ebx,4-0	; Convert from bytes to paras,
				; retaining the low-order nibble
	 mov	 cx,ds		; Copy base segment
	 add	 cx,bx		; Add to get normalized segment
	 mov	 ds,cx		; Address it
	 assume  ds:nothing	; Tell the assembler about it

	 rol	 ebx,4-0	; Convert from paras to bytes
	 and	 bx,@NIB0	; Isolate the low-order nibble
	 mov	 ds:[bx],eax	; Set the next PTE

	 REGREST <ds,ecx,ebx>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SET_NEXTPTE endp		; End SET_NEXTPTE procedure

CODE	 ends			; End CODE segment

	 MEND			; End UTIL_PTE module
