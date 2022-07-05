;' $Header:   P:/PVCS/MAX/386MAX/UTIL_TIM.ASV   1.3   08 Jul 1998 12:30:18   BOB  $
	 title	 UTIL_TIM -- 386MAX Utility Program -- TIME Action
	 page	 58,122
	 name	 UTIL_TIM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Program segment CODE,	byte-aligned,  public, class 'prog'
	       Data    segment DATA,	dword-aligned, public, class 'data'
	       Program segment NCODE,	byte-aligned,  public, class 'ncode'
	       Tail    segment ZZTAIL,	dword-aligned, public, class 'zzdata'

Link requirements:  None, standalone .COM routine.

Program derived from:  None.

Original code by:  Bob Smith, April, 1987.

Modifications by:  None.

|

.386
.xlist
	 include MASM.INC
	 include ASCII.INC
	 include 386.INC
	 include PTR.INC
	 include EMM2CALL.INC

	 include QMAX_OEM.INC
	 include QMAX_TIM.INC
.list

if @OEM_TIMEMEM
PGROUP	 group	 CODE,DATA,NCODE,ZZTAIL


DATA	 segment use16 dword public 'data' ; Start DATA segment
	 assume  ds:PGROUP

	 extrn	 GLB_FLAG:word
	 include QMAX_GLB.INC

	 extrn	 INFO_CTL:byte
	 include QMAX_CTL.INC

if @OEM_WIN3
	 extrn	 MSG_WINERR:byte
	 extrn	 WINRUN:byte
endif				; IF @OEM_WIN3

	 extrn	 PORT67:word

	 public  CON5,CON10,CON4KB
CON5	 dd	  5		; Constant  5
CON10	 dd	 10		; Constant 10
CON4KB	 dd	 4*1024 	; Constant 4KB

	 public  LA_START,LA_END
LA_START dd	 0		; Starting linear address
LA_END	 dd	 ?		; Ending ...

	 public  HISTSCALE
HISTSCALE db	 3		; Scale factor for histogram display

	 public  NPAGES
NPAGES	 dw	 ?		; # 4KB pages in system

	 public  MEMTIME_TOT,MEMTIME_CNT
MEMTIME_TOT dd	 256 dup (0)	; Total times for MEMTIME categories
MEMTIME_CNT dw	 256 dup (0)	; Weight for each of the above totals

	 public  AVGFAST
AVGFAST  dd	 ?		; Average of the fastest time

	 public  MSG_TIMEWAIT
MSG_TIMEWAIT db  'ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸',CR,LF
ifdef LANG_GR
	 db	 '³              Moment bitte, der Speicher wird durchgemessen...               ³',CR,LF
else
	 db	 '³               Timing memory accesses, please wait a moment...               ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,EOS

	 public  MSG_TIMEHDR
MSG_TIMEHDR label byte
ifdef LANG_GR
	 db	 '³                     SPEICHER-ZUGRIFFS-GESCHWINDIGKEITEN                     ³',CR,LF
else
	 db	 '³                             MEMORY ACCESS TIMES                             ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF
ifdef LANG_GR
	 db	 '³ Anfangs- ³    Bereich    ³ Gr”áe  ³ mittl.  ³ relativ z. schnellsten Bereich³',CR,LF
	 db	 '³ Adresse  ³ Anfang   Ende ³ in KB  ³ Zeit æs ³ (1.0 = schnellster)           ³',CR,LF
else
	 db	 '³ Starting ³     Range     ³        ³ Average ³ Ratio to Fastest Time         ³',CR,LF
	 db	 '³ Address  ³ Start     End ³ Length ³ Time æs ³ (1.0 = fastest)               ³',CR,LF
endif				; IFDEF LANG_GR
	 db	 'ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',CR,LF,EOS
;;;;;;;; db	 '³ ________ ³ _____ ³ _____ ³ _____  ³  _____  ³ __._ þþþþþþþþþþþþþþþþþþþþþþþþ>³',CR,LF,EOS

	 public  MSG_TIMELINE,MSG_HIST
MSG_TIMELINE db  '³ '
MSG_TIME_SA db	 '________ ³ '  ; Starting address
MSG_TIME_RS db	 '    _ ³ '     ; Range start
MSG_TIME_RE db	 '    _ ³ '     ; Range end
MSG_TIME_LN db	 '    _  ³  '   ; Length
MSG_TIME_AVG db  '    _  ³'     ; Average time
MSG_TIME_AVG_LEN equ 5
MSG_TIME_AC1 db  '  _.'        ; Ratio of access time
MSG_TIME_AC2 db  '_ '
MSG_HIST db	 (78-($-MSG_TIMELINE)) dup (' '),'³'
	 db	 CR,LF,EOS

	 public  MSG_TIMETRL
MSG_TIMETRL db	 'ÔÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¾',CR,LF,EOS

	 public  MSG_ABSENT
ifdef LANG_GR
MSG_ABSENT db	 'fehlt '
else
MSG_ABSENT db	 'Absent'
endif				; IFDEF LANG_GR
MSG_ABSENT_LEN equ $-MSG_ABSENT

	 public  MSG_PARITY
ifdef LANG_GR
MSG_PARITY db	 'Parit„tsfehler @ '
else
MSG_PARITY db	 'Parity error @ '
endif				; IFDEF LANG_GR
MSG_PARITY_LEN equ $-MSG_PARITY

	 public  PAR_FLAG
PAR_FLAG db	 0		; 1 = parity error occurred

DATA	 ends			; End DATA segment


; The following segment serves to address the next available byte
; after the DATA segment.  This location may be used for any variable
; length data which extends beyond the program.

ZZTAIL	 segment use16 dword public 'zzdata' ; Start ZZTAIL segment
	 assume  ds:PGROUP

	 extrn	 ZTAIL:byte

ZZTAIL	 ends			; End ZZTAIL segment


NCODE	 segment use16 byte public 'ncode' ; Start NCODE segment
	 assume  cs:PGROUP

	 extrn	 STROUT:near

NCODE	 ends			; End NCODE segment


CODE	 segment use16 byte public 'prog' ; Start CODE segment
	 assume  cs:PGROUP

	 extrn	 BIN2BASE:near
	 extrn	 DD2HEX:near
	 extrn	 CHECK_STATE:near
	 extrn	 INFO_READ:near
	 extrn	 SEND_CMD:near

	 NPPROC  ACT_TIME -- Action To Display Memory Access Times
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Time memory accesses throughout the system.

On entry:

DS:SI	 ==>	 next character on command line

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

MEMTIME_STR struc

MEMTIME_PA dd	 ?		; Physical address
MEMTIME_AC dw	 ?		; Access time

MEMTIME_STR ends

	 pushad 		; Save all EGP registers
	 push	 fs		; Save for a while

if @OEM_WIN3
	 cmp	 WINRUN,1	; Are we running under Windows?
	 je	 near ptr ACT_TIME_WINERR ; Jump if so
endif				; IF @OEM_WIN3

	 mov	 bx,GLB_FLAG	; Save current global flag
	 and	 bx,@GLB_AUTO or @GLB_ON ; Isolate flags

	 call	 CHECK_STATE	; Attempt to go ON or AUTO active
	 jc	 near ptr ACT_TIME_ERR ; Jump if not successful

	 lea	 dx,MSG_TIMEWAIT ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 lea	 di,ZTAIL[16-1] ; ES:DI ==> end of our data area
	 and	 di,not (16-1)	; Round down to para boundary
	 mov	 bp,sp		; Save stack pointer
	 EMMOUT  @EMM2_MEMTIME	; Get memory access times
				; Return error code in AH
	 mov	 sp,bp		; Restore

; Return to the previous state in BX

	 test	 bx,@GLB_ON	; Were we ON before?
	 jnz	 short @F	; Yes, stay that way

	 call	 INFO_READ	; Read in INFO structure
				; to get current GLB_FLAG

	 mov	 INFO_CTL,@CTL_OFF ; Mark as state OFF
	 call	 SEND_CMD	; Attempt to set state

	 call	 INFO_READ	; Read in INFO structure
				; to reset flags
@@:
	 and	 ah,ah		; Check return code
	 jnz	 near ptr ACT_TIME_ERR ; Something went wrong

	 mov	 NPAGES,cx	; Save for later use
	 mov	 ax,es		; Copy for add
	 shr	 di,4-0 	; Convert from bytes to paras
	 add	 di,ax		; Plus our data segment
	 mov	 fs,di		; Address it
	 assume  fs:nothing	; Tell the assembler about it

; Search the table for the smallest non-zero value (to be used as a divisor)

	 xor	 si,si		; Zero index into table
	 mov	 bx,-1		; Set accumulator to highest value
	 mov	 cx,NPAGES	; Get # entries in structure
ACT_TIME_MN1:
	 mov	 ax,fs:[si].MEMTIME_AC ; Get the access time

	 and	 ax,ax		; Izit zero?
	 jz	 short ACT_TIME_MN2 ; Yes, ignore this value

	 cmp	 ax,@TIM_ABS	; Absent marker?
	 je	 short ACT_TIME_MN2 ; Yes, ignore this value

	 cmp	 ax,@TIM_PAR	; Parity error marker?
	 je	 short ACT_TIME_MN2 ; Yes, ignore this value

	 cmp	 ax,bx		; Find the smaller
	 jae	 short ACT_TIME_MN2 ; Jump if

	 mov	 bx,ax		; Use new access time
ACT_TIME_MN2:
	 add	 si,size MEMTIME_STR ; Skip to next entry

	 loop	 ACT_TIME_MN1	; Jump if more

	 movzx	 ebx,bx 	; Zero high-order word

; Scale access times by smallest value (in EBX)

	 movzx	 edi,bx 	; Copy divisor
	 shr	 edi,1		; Divide by two to get halfway point

	 xor	 si,si		; Zero index into table
	 mov	 cx,NPAGES	; Get # entries in structure
ACT_TIME_SC1:
	 movzx	 eax,fs:[si].MEMTIME_AC ; Get the access time

	 cmp	 ax,@TIM_ABS	; Absent marker?
	 je	 short ACT_TIME_SC2 ; Yes, skip scaling

	 cmp	 ax,@TIM_PAR	; Parity error marker?
	 je	 short ACT_TIME_SC2 ; Yes, skip scaling

	 mov	 ebp,eax	; Copy actual time

	 mul	 CON10		; Times 10
	 add	 eax,edi	; Add in half of divisor
	 xor	 edx,edx	; Zero high-order dword
	 div	 ebx		; Divide by smallest time
	 xor	 edx,edx	; Zero to use as dword
	 add	 eax,2		; Bump ...
	 div	 CON5		; round up to nearest multiple of 5
	 mul	 CON5

; Accumulate into total and weight for this category

	 push	 bx		; Save for a moment

	 mov	 bx,ax		; Copy ratio time

	 cmp	 bx,length MEMTIME_CNT ; Longer than we can handle?
	 jb	 short ACT_TIME_CNT1 ; No, it's within range

	 mov	 bx,(length MEMTIME_CNT)-1 ; Use maximum
	 mov	 ax,bx		; Copy as new ratio
ACT_TIME_CNT1:
	 shl	 bx,1		; Times two to index table of words
	 inc	 MEMTIME_CNT[bx] ; Count in another weight

	 shl	 bx,1		; Times two more to index table of dwords
	 add	 MEMTIME_TOT[bx],ebp ; Add in actual time

	 pop	 bx		; Restore

	 xor	 ah,ah		; Zero high-order byte for division
	 div	 CON10.LO	; Convert to AH = tenths digit
				;	     AL = units  digit
	 xchg	 al,ah		; Convert to AH = units  digit
				;	     AL = tenths digit
;;;;;;;; aam			; Convert to AH = units  digit
;;;;;;;;			;	     AL = tenths digit
	 mov	 fs:[si].MEMTIME_AC,ax ; Save both for later display
ACT_TIME_SC2:
	 add	 si,size MEMTIME_STR ; Skip to next entry

	 loop	 ACT_TIME_SC1	; Jump if more

; Compute the average time for the fastest category

	 mov	 eax,MEMTIME_TOT[10*4] ; Get cumulative time
	 movzx	 ecx,MEMTIME_CNT[10*2] ; Get the weight
	 xor	 edx,edx	; Zero high-order dword
	 div	 ecx		; Divide by the weight
				; EAX = quotient, EDX = remainder
	 shr	 ecx,1		; Halve the divisor
	 cmp	 ecx,edx	; Check half divisor against remainder
	 adc	 eax,0		; Add one more to quotient if more than halfway
	 mov	 AVGFAST,eax	; Save as the average of the fastest time

; Display the entries as linear address, access category

	 lea	 dx,MSG_TIMEHDR ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 xor	 si,si		; Zero index into table
	 mov	 cx,NPAGES	; Get # entries in structure
	 xor	 edx,edx	; Starting linear address is 00000000
	 xor	 edi,edi	; Ending ...
	 mov	 bx,fs:[si].MEMTIME_AC ; Use first access time as seed
	 mov	 eax,fs:[si].MEMTIME_PA ; Get starting physical address
ACT_TIME_DP1:
	 cmp	 bx,fs:[si].MEMTIME_AC ; Same access time as last time?
	 je	 short ACT_TIME_DP2 ; Yes, skip over it

	 push	 bx		; Pass current access time
	 push	 eax		; Pass starting physical address
	 push	 edi		; Pass ending linear address
	 push	 edx		; ...  starting
	 call	 DISP_TIME	; Display the next time line

	 mov	 edx,edi	; Set as new starting linear address
	 mov	 bx,fs:[si].MEMTIME_AC ; Get new access time
	 mov	 eax,fs:[si].MEMTIME_PA ; Get new starting physical address
ACT_TIME_DP2:
	 add	 edi,CON4KB	; Skip to next ending linear address
	 add	 si,size MEMTIME_STR ; Skip to next entry

	 loop	 ACT_TIME_DP1	; Jump if more

	 push	 bx		; Pass curent access time
	 push	 eax		; Pass starting physical address
	 push	 edi		; Pass ending linear address
	 push	 edx		; ...  starting
	 call	 DISP_TIME	; Display the last time line

	 lea	 dx,MSG_TIMETRL  ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 cmp	 PAR_FLAG,1	; Did we encounter a parity error?
	 je	 short ACT_TIME_ERR ; Yes, mark as such

	 clc			; Indicate all went well

	 jmp	 short ACT_TIME_EXIT ; Join common exit code

if @OEM_WIN3
ACT_TIME_WINERR:
	 lea	 dx,MSG_WINERR	; DS:DX ==> error message
	 call	 STROUT 	; Display the string at DS:DX
endif				; IF @OEM_WIN3
ACT_TIME_ERR:
	 stc			; Indicate something went wrong
ACT_TIME_EXIT:
	 pop	 fs		; Restore
	 popad			; Restore all EGP registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

ACT_TIME endp			; End ACT_TIME procedure
	 NPPROC  DISP_TIME -- Display Time Line from DS:SI
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Display time line from MEMTIME structure entry at DS:SI

On entry:

BX	 =	 current time
EDX	 =	 starting address

|

DT_STR	 struc

	 dw	 ?		; Caller's BP
	 dw	 ?		; Caller's IP
DT_START dd	 ?		; Starting linear address
DT_END	 dd	 ?		; Ending ...
DT_PHYS  dd	 ?		; Starting physical address
DT_AC	 dw	 ?		; Access time

DT_STR	 ends

	 push	 bp		; Prepare to address the stack
	 mov	 bp,sp		; Hello, Mr. Stack

	 REGSAVE <eax,bx,ecx,edx,di> ; Save registers

	 mov	 bx,[bp].DT_AC	; Get current access time
	 mov	 edx,[bp].DT_START ; Get starting linear address

	 mov	 al,'0'         ; Fill value
	 lea	 di,MSG_TIME_SA ; ES:DI ==> starting address display area
	 mov	 cx,8		; # bytes in display area
     rep stosb			; Fill it up

	 mov	 al,' '         ; Fill value
	 lea	 di,MSG_TIME_RS ; ES:DI ==> range start display area
	 mov	 cx,5		; # bytes in display area
     rep stosb			; Fill it up

	 mov	 al,' '         ; Fill value
	 lea	 di,MSG_TIME_AC1[1] ; ES:DI ==> time category value
	 mov	 cx,MSG_ABSENT_LEN ; # bytes in display area
     rep stosb			; Fill it up

	 mov	 al,' '         ; Fill value
	 lea	 di,MSG_TIME_AVG[0] ; ES:DI ==> time average value
	 mov	 cx,MSG_TIME_AVG_LEN ; # bytes in display area
     rep stosb			; Fill it up

	 mov	 al,' '         ; Fill value
	 lea	 di,MSG_HIST	; ES:DI ==> histogram display area
	 mov	 cx,size MSG_HIST ; # bytes in display area
     rep stosb			; Fill it up

	 mov	 word ptr MSG_TIME_LN[0],'  ' ; Blank out length value
	 mov	 word ptr MSG_TIME_LN[2],'  '

	 mov	 eax,edx	; Copy starting address
	 lea	 di,MSG_TIME_SA ; ES:DI ==> starting address display area
	 call	 DD2HEX 	; Display dword in EAX at ES:DI

	 mov	 eax,edx	; Get starting address
	 shr	 eax,10-0	; Convert from bytes to 1KB
	 mov	 cx,10		; Display in decimal
	 lea	 di,MSG_TIME_RS[4] ; ES:DI ==> ending address display area
	 call	 BIN2BASE	; Display word in AX at ES:DI in decimal

	 cmp	 bx,@TIM_ABS	; Absent marker?
	 je	 near ptr DISP_TIME_ABS ; Yes, mark it as such

	 cmp	 bx,@TIM_PAR	; Parity error marker?
	 je	 near ptr DISP_TIME_PAR ; Yes, mark it as such

; Display average time for this category

	 mov	 ax,bx		; Copy time category in BCD
	 aad			; Convert to binary number
	 mov	 bx,ax		; Copy to index register

	 cmp	 bx,length MEMTIME_CNT ; Longer than we can handle?
	 jb	 short DISP_TIME_CNT2 ; No, it's within range

	 mov	 bx,(length MEMTIME_CNT)-1 ; Use maximum
DISP_TIME_CNT2:
	 push	 edx		; Save for a moment

	 shl	 bx,1		; Times two to index table of words
	 movzx	 ecx,MEMTIME_CNT[bx] ; Get the corresponding weight

	 shl	 bx,1		; Times two more to index table of dwords
	 mov	 eax,MEMTIME_TOT[bx] ; Get cumulative time
	 xor	 edx,edx	; Zero high-order dword

	 div	 ecx		; Divide by the weight
				; EAX = quotient, EDX = remainder
	 shr	 ecx,1		; Halve the divisor
	 cmp	 ecx,edx	; Check half divisor against remainder
	 adc	 eax,0		; Add one more to quotient if more than halfway

; Convert from 838 nanoseconds to microseconds

	 push	 eax		; Save for a moment

	 mov	 ecx,838	; Multiplier
	 mul	 ecx		; Form product in EDX:EAX
	 mov	 ecx,1000	; Divisor
	 div	 ecx		; Get quotient into EAX (really just AX)

	 lea	 di,MSG_TIME_AVG[4] ; ES:DI ==> AVG display area
	 mov	 cx,10		; Display in decimal
	 call	 BIN2BASE	; Display word in AX at ES:DI in decimal

	 pop	 eax		; Restore

; Convert EAX into a ratio to the category 10 time

	 mul	 CON10		; EDX:EAX = times ten for conversion
	 mov	 ecx,AVGFAST	; Get the average fastest time

	 div	 ecx		; Divide by the average fastest time
				; EAX = quotient, EDX = remainder
	 shr	 ecx,1		; Halve the divisor
	 cmp	 ecx,edx	; Check half divisor against remainder
	 adc	 eax,0		; Add one more to quotient if more than halfway
	 xor	 ah,ah		; Zero high-order byte for division
	 div	 CON10.LO	; Convert to AH = tenths digit
				;	     AL = units  digit
	 xchg	 al,ah		; Convert to AH = units  digit
				;	     AL = tenths digit
;;;;;;;; aam			; Convert to AH = units  digit
;;;;;;;;			;	     AL = tenths digit
	 mov	 bx,ax		; Copy ratio to display

; Display ratio for this category

	 mov	 MSG_TIME_AC2[-1],'.' ; Insert decimal point

	 xor	 ah,ah		; Zero to use as word
	 mov	 al,bh		; Copy access time integer part
	 lea	 di,MSG_TIME_AC1[2] ; ES:DI ==> access time address display area
	 mov	 cx,10		; Display in decimal
	 call	 BIN2BASE	; Display word in AX at ES:DI in decimal

	 xor	 ah,ah		; Zero to use as word
	 mov	 al,bl		; Copy access time fractional part
	 lea	 di,MSG_TIME_AC2[0] ; ES:DI ==> access time address display area
	 mov	 cx,10		; Display in decimal
	 call	 BIN2BASE	; Display word in AX at ES:DI in decimal

; Display the ratio as a histogram

	 mov	 ax,bx		; Copy ratio
	 aad			; Convert to binary
	 sub	 ax,10		; Convert to origin-0
	 add	 ax,5		; Round to nearest multiple of 10
	 xor	 dx,dx		; Zero to use as dword
	 div	 CON10.ELO	; Return with AX = quotient
	 mul	 HISTSCALE	; Times histogram scale factor
	 inc	 ax		; Convert to origin-1
	 mov	 cx,ax		; Copy to count register

	 mov	 al,'þ'         ; Histogram display character
	 mov	 ah,al		; Copy as trailing character

	 cmp	 cx,size MSG_HIST ; Check against upper limit
	 jbe	 short DISP_TIME_HIST1 ; It's within range

	 mov	 cx,size MSG_HIST ; Use maximum
	 mov	 ah,'>'         ; Trailing character
DISP_TIME_HIST1:
	 dec	 cx		; Subtract out trailing character
	 lea	 di,MSG_HIST	; ES:DI ==> histogram display area
     rep stosb			; Fill the histogram
	 mov	 al,ah		; Get trailing character fill
S16	 stosb			; Fill with trailing character

	 pop	 edx		; Restore

	 jmp	 short DISP_TIME_COM ; Join common code

DISP_TIME_ABS:
	 REGSAVE <cx,si>	; Save for a moment

	 lea	 di,MSG_HIST	; ES:DI ==> message display area
	 lea	 si,MSG_ABSENT	; DS:SI ==> absent message
	 mov	 cx,MSG_ABSENT_LEN ; # bytes in message
S16  rep movsb

	 REGREST <si,cx>	; Restore

	 jmp	 short DISP_TIME_COM ; Join common code

DISP_TIME_PAR:
	 REGSAVE <cx,si>	; Save for a moment

	 mov	 PAR_FLAG,1	; Mark as parity error occurred

	 lea	 di,MSG_HIST	; ES:DI ==> message display area
	 lea	 si,MSG_PARITY	; DS:SI ==> parity error message
	 mov	 cx,MSG_PARITY_LEN ; # bytes in message
S16  rep movsb

	 mov	 eax,[bp].DT_PHYS ; Get physical address
	 and	 ax,mask $PTE_FRM ; Isolate the frame
	 call	 DD2HEX 	; Display dword in EAX at ES:DI

	 REGREST <si,cx>	; Restore
DISP_TIME_COM:
	 mov	 eax,[bp].DT_END ; Get ending address
	 shr	 eax,10-0	; Convert from bytes to 1KB
	 lea	 di,MSG_TIME_RE[4] ; ES:DI ==> range end display area
	 mov	 cx,10		; Display in decimal
	 call	 BIN2BASE	; Display word in AX at ES:DI in decimal

	 mov	 eax,[bp].DT_END ; Get ending address
	 sub	 eax,edx	; Get length in bytes
	 shr	 eax,10-0	; Convert from bytes to 1KB
	 lea	 di,MSG_TIME_LN[4] ; ES:DI ==> length display area
	 mov	 cx,10		; Display in decimal
	 call	 BIN2BASE	; Display word in AX at ES:DI in decimal

	 lea	 dx,MSG_TIMELINE ; DS:DX ==> string to display
	 call	 STROUT 	; Display string at DS:DX

	 REGREST <di,edx,ecx,bx,eax> ; Restore

	 pop	 bp		; Restore

	 ret	 4+4+4+2	; Return to caller, popping arguments

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

DISP_TIME endp			; End DISP_TIME procedure

CODE	 ends			; End CODE segment
endif				; IF @OEM_TIMEMEM

	 MEND			; End UTIL_TIM module
