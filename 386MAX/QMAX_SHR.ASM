;' $Header:   P:/PVCS/MAX/386MAX/QMAX_SHR.ASV   1.2   30 May 1997 10:45:58   BOB  $
	 title	 QMAX_SHR -- 386MAX INT 31h Shared Memory Routines
	 page	 58,122
	 name	 QMAX_SHR

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1991-7 Qualitas, Inc.  GNU General Public License version 3.

Segmentation:  Group PGROUP:
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Group JGROUP:
	       Program segment JCODE, dword-aligned, public, class 'jcode'

Program derived from:  None.

Original code by:  Bob Smith, June 1991.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include BITFLAGS.INC
	 include ALLMEM.INC

	 include QMAX_OEM.INC
	 include QMAX_DTE.INC
	 include QMAX_I31.INC
	 include QMAX_VMM.INC
.list

if @OEM_DPMI

PGROUP	 group	 EDATA
IGROUP	 group	 ICODE
JGROUP	 group	 JCODE


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 DPMITYPE:byte

	 extrn	 SEL_4GB3:word
	 extrn	 SEL_DSIG3:word

	 public  PSHMEMHANDLES,SHMEMHANDLESIZE
PSHMEMHANDLES dd ?		; LA of shared memory handle array
SHMEMHANDLESIZE dd ?		; Size in bytes of shmem handle array

	 public  BlockedHandle,BlockedClient,BlockedStatus,BlockedType
BlockedHandle dd ?		; Shared mem handle we are blocked on
BlockedClient dw ?		; Client who blocked
BlockedStatus db 0		; Non-zero if system is blocked
BlockedType db	 ?		; Type of serialization request that blocked

EDATA	 ends			; End EDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 extrn	 FVMM_LOCK:far
	 extrn	 FVMM_FREE:far
	 extrn	 FVMM_ALLOC:far
	 extrn	 FVMM_ZERO_PAGE:far
	 extrn	 FVMM_REALLOC:far

ICODE	 ends			; End ICODE segment

COMMENT |

There are four basic operations on shared memory:

	1) allocation			FDPMI_GETSHR
	2) deallocation 		FDPMI_RELSHR
	3) serialization		FDPMI_SERIALIZE
	4) release of serialization	FDPMI_RELSERIAL

The host maintains shared memory information in a handle structure:

SharedMemHandle struc	; per shared memory block
	SMH_la		dd	?	; base linear address
	SMH_length	dd	?	; size in bytes
	SMH_name	db 128 dup (?)	; the asciiz name of the block
	SMH_cinfo	db (size SMClientInfo)*@TSS_MAX dup (?) ; client information
SharedMemHandle ends

The name is supplied by the client when shared memory is allocated.  If
a subsequent allocation of shared memory, either by the same or a
different client, uses the same name, the same shared memory is granted.

Each shared memory handle contains an array of SMClientInfo structures,
one for each TSS.  The SMClientInfo structure is defined as follows:

SMClientInfo struc	; client information tracking structure
	smci_client	dw	?	; TSS selector of client
	smci_uses	dw	?	; allocation count by client
	smci_shares	dw	?	; shared serialization count by client
	smci_excl	dw	?	; exclusive ser'tion count by client
SMClientInfo ends

All shared memory handles are kept in a dynamically grown array, and
a pointer to this array is kept in the variable PSHMEMHANDLES. The
pages backing the array are kept locked.

The size of the shared memory region that a client allocates may be zero.
In this case, FDPMI_GETSHR allocates a handle, but no memory. Normally,
it allocates memory by calling FVMM_ALLOC with the appropriate flags.
The allocator also clears the first 16 bytes of the handle, as specified
by DPMI 1.0.

The handle returned to the client when it allocates shared memory is the
offset into the shared memory handles array of the corresponding
SharedMemHandle structure.

Serialization is supported by FDPMI_SERIALIZE.	Each shared memory
handle is in one of three states:

@SMEM_FREE		equ	1	; not serialized
@SMEM_SHARED		equ	2	; shared serialized
@SMEM_EXCLUSIVE 	equ	3	; exclusive serialized

A handle in the @SMEM_FREE state enters the @SMEM_EXCLUSIVE state
or @SMEM_SHARED state when a successful serialization request is
made.  If a subsequent serialization request is made while the
handle is not in the @SMEM_FREE state, the caller remains in the
loop in FDPMI_SERIALIZE until either:

	1) the serialization request is asynchronously cancelled
    or	2) the serialization is released by the original serializer
|




JCODE	 segment use16 dword public 'jcode' ; Start JCODE segment
	 assume  cs:JGROUP

	 public  @QMAX_SHR_JCODE
@QMAX_SHR_JCODE:		; Mark module start in .MAP file

	 FPPROC  FDPMI_GETSHR -- DPMI 1.0 Function to Allocate Shared Memory
	 assume  ds:PGROUP,es:PGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI 1.0 function to allocate shared memory

On entry (in INTXX_STR):

AX	 =	 0D00h
ES:EDI	 =	 selector:offset of shared memory allocation req struct
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8012 no linear memory
		 8013 no physical memory
		 8014 no backing store
		 8016 handle unavailable
		 8021 name too long

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; First see if we can find the requested block, as identified by its
; name.

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 cmp	 PSHMEMHANDLES,0 ; Is zero if uninitialized
	 jne	 short DPMI_GS_HINITOK ; Jump if initialized

; Make the initial allocation of the shared memory handle array
; (in the shared memory area)

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 xor	 eax,eax	; Alloc at any address
	 mov	 ebx,1		; Alloc one page
	 mov	 ecx,(mask $commit) or (mask $shared) ; Set flags
	 FIXICALL IGROUP:FVMM_ALLOC,DTE_CSIG ; Allocate the memory
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jc	 near ptr GETSHR_ERR_NOHNDL ; Bail on fail

; Now lock it

	 REGSAVE <eax,ds>	; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 mov	 ebx,1		; Lock 1 page
	 FIXICALL IGROUP:FVMM_LOCK,DTE_CSIG ; Call VMM to lock pages
				; Return with CF significant
	 REGREST <ds,eax>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
	 jc	 near ptr GETSHR_ERR_NOHNDL ; bail on fail

	 mov	 PSHMEMHANDLES,eax ; Save addr of handles
	 mov	 SHMEMHANDLESIZE,@PageSize ; Record size of handle array

	 push	 ds		; Save for a moment
	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it
	 FIXICALL IGROUP:FVMM_ZERO_PAGE,DTE_CSIG ; Zero it out
	 pop	 ds		; Restore
	 assume  ds:PGROUP	; Tell the assembler about it

	 jmp	 near ptr DPMI_GS_NEWHANDLE; skip trying to find specified handle

DPMI_GS_HINITOK:

; Here we have an array of handles. Now search the array for the given
; handle:

	 mov	 ds,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 esi,[ebp].INTXX_EDI
	 IF16ZX  si		; Zero to use as dword if 16-bit client

; DS:ESI now points to the client's shared memory request structure

	 lds	 esi,ds:[esi].SMR_name ; Load pointer to block name
	 assume  ds:nothing	; Tell the assembler about it

; DS:ESI now points to the shared memory block name as passed by client

	 cmp	 ds:[esi].LO,0	; Don't allow null name
	 je	 near ptr GETSHR_ERR_INVVAL ; Jump if it's empty

	 call	 SMEM_FIND_NAME ; Look up in shared mem handles

	 or	 ebx,ebx	; Zero means not found
	 jz	 short DPMI_GS_NEWHANDLE; need to make a new handle
DPMI_GS_MATCH:				; here if matching name found
	 mov	 ds,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 esi,[ebp].INTXX_EDI ; Get caller's pointer
	 IF16ZX  si		; DS:ESI now points to request structure

	 mov	 eax,AGROUP:[ebx].SMH_length ; Get actual length
	 mov	 ds:[esi].SMR_actSize,eax ; Store in request struct

	 mov	 eax,AGROUP:[ebx].SMH_la ; Get block address
	 mov	 ds:[esi].SMR_address,eax ; Store in request struct
	 mov	 ds:[esi].SMR_handle,ebx ; Set handle

	 mov	 eax,PSHMEMHANDLES ; Handle is actually offset
	 sub	 ds:[esi].SMR_handle,eax ;   from base of array

	 call	 SMEM_ADD_USER	; Add this user to handle

	 clc			; Flag success

	 ret			; Return to caller

DPMI_GS_NEWHANDLE:		; Need to alloc new handle

; Search the existing array for an unused (LA=0) handle.

	 mov	 ebx,PSHMEMHANDLES ; EBX <- handle array base
	 mov	 edx,SHMEMHANDLESIZE ; EDX <- handle array size
	 add	 edx,ebx	; EDX <- end of handle array
DPMI_GS_FINDFREE:
	 cmp	 ebx,edx	; At end of array?
	 jae	 short DPMI_GS_GROW_HANDLES ; Yes, need to grow handle array

	 cmp	 AGROUP:[ebx].SMH_la,0 ; Is linear address zero?
	 je	 short DPMI_GS_FOUND_FREE ; Yes - use it

	 add	 ebx,size SharedMemHandle ; Advance handle array pointer

	 jmp	 DPMI_GS_FINDFREE ; Try the next one

DPMI_GS_GROW_HANDLES:		; Try to grow the handle array

; Set up VMM_REALLOC call

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 push	 dword ptr (mask $shared) or (mask $commit) ; flags argument
	 mov	 eax,SHMEMHANDLESIZE ; EAX <- current size
	 add	 eax,@PageSize	; EAX <- new size in bytes
	 shr	 eax,@BytePage	; EAX <- new size in pages
	 push	 eax		; Pass new size arg
	 dec	 eax		; Old size is one page less
	 push	 eax		; Pass old size arg
	 push	 PSHMEMHANDLES	; Pass address arg
	 FIXICALL IGROUP:FVMM_REALLOC,DTE_CSIG ; Try to grow it
	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 or	 eax,eax	; EAX is linear addr or zero
	 jz	 near ptr GETSHR_ERR_NOHNDL ; Couldn't do it

	 mov	 PSHMEMHANDLES,eax ; Save new array address

; Lock the new page

	 add	 eax,SHMEMHANDLESIZE ; EAX <- base of new page

	 REGSAVE <eax,ds>	; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 mov	 ebx,1		; Lock one page
	 FIXICALL IGROUP:FVMM_LOCK,DTE_CSIG ; Lock it down since we may
				; need to touch during int
	 REGREST <ds,eax>	; Restore addr of new page
	 assume  ds:nothing	; Tell the assembler about it
	 jc	 near ptr GETSHR_ERR_NOHNDL ; Couldn't do it

	 push	 ds		; Save for a moment

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 FIXICALL IGROUP:FVMM_ZERO_PAGE,DTE_CSIG ; Zero out the new page

	 pop	 ds		; Restore
	 assume  ds:nothing	; Tell the assembler about it

	 add	 SHMEMHANDLESIZE,@PageSize ; Adjust size

	 jmp	 DPMI_GS_NEWHANDLE ; Go try it again

DPMI_GS_FOUND_FREE:		; EBX is free handle
	 mov	 ds,[ebp-@I31BACK].I31_ES ; Get caller's ES
	 assume  ds:nothing	; Tell the assembler about it

	 mov	 esi,[ebp].INTXX_EDI ; Get caller's EDI
	 IF16ZX  si		; DS:ESI now points to request structure

; Zero length request is allowed but is a special case

	 mov	 ecx,ds:[esi].SMR_reqSize ; Pick up requested size

	 or	 ecx,ecx	; Is it zero?
	 jnz	 short DPMI_GS_NOT_ZERO ; Jump if not

; Here if zero length requested - first set fields in request structure

	 mov	 ds:[esi].SMR_actSize,0 ; Set actual size
	 mov	 ds:[esi].SMR_handle,ebx ; Set handle
	 mov	 eax,PSHMEMHANDLES
	 sub	 ds:[esi].SMR_handle,eax ; Handle is offset from base
	 mov	 ds:[esi].SMR_address,-1 ; Mark as in use

	 jmp	 short DPMI_GS_SETUP_HANDLE ; Now go set up the handle info

DPMI_GS_NOT_ZERO:		; Need to allocate memory
	 REGSAVE <ebx,ds>	; Save handle address

	 mov	 ebx,ds:[esi].SMR_reqSize ; Get requested size in bytes
	 add	 ebx,@PageSize-1 ; Round up to page
	 rcr	 ebx,1		; Convert to pages (handle too large value)
	 shr	 ebx,@BytePage-1 ; ...

	 xor	 eax,eax	; Any address will do

	 mov	 ecx,(mask $commit) or (mask $shared) ; Flags argument

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 FIXICALL IGROUP:FVMM_ALLOC,DTE_CSIG ; Allocate shared memory
				; Return with CF significant
	 REGREST <ds,ebx>	; Restore
	 assume  ds:nothing	; Tell the assembler about it
	 jc	 near ptr GETSHR_ERR_NOMEM ; Fail on mem unavailable

; Fill in request struct fields

	 mov	 ds:[esi].SMR_address,eax ; Set linear address

	 mov	 eax,ds:[esi].SMR_reqSize ; Get requested size
	 mov	 ds:[esi].SMR_actSize,eax ; Copy to actual size
	 mov	 ds:[esi].SMR_handle,ebx  ; Set handle

	 mov	 eax,PSHMEMHANDLES ; Get handle array base
	 sub	 ds:[esi].SMR_handle,eax ; Handle is offset from base
DPMI_GS_SETUP_HANDLE:

; Now set up the internal handle

	 mov	 eax,ds:[esi].SMR_actSize ; Fetch size
	 mov	 AGROUP:[ebx].SMH_length,eax ; Store in handle

	 mov	 eax,ds:[esi].SMR_address ; Fetch address
	 mov	 AGROUP:[ebx].SMH_la,eax ; Store in handle

; Copy the handle name

	 lea	 edi,[ebx].SMH_name

	 lds	 esi,ds:[esi].SMR_name
	 assume  ds:nothing	; Tell the assembler about it

	 cld
	 mov	 cx,128 	; max name length
DPMI_GS_COPY_NAME:
	 sub	 cx,1		; Dec count of max chars left
	 jb	 short GETSHR_ERR_INVVAL ; Fail if negative

	 lods	 ds:[esi].LO
S32	 stos	 es:[edi].LO

	 or	 al,al		; End of name?
	 jnz	 short DPMI_GS_COPY_NAME ; Get more if not

; Init owner and user info

	 lea	 edi,[ebx].SMH_cinfo ; Point to info data
	 xor	 al,al		; Prepare to zero it
	 mov	 ecx,size SMH_cinfo ; Size of region to zero
     rep stos	 es:[edi].LO	; Zap it

	 call	 SMEM_ADD_USER			; record usage by this client

; Clear the first 16 bytes of the allocated block

	 mov	 edi,es:[ebx].SMH_la ; Get address
	 mov	 ecx,es:[ebx].SMH_length ; Get length

	 cmp	 ecx,16 	; If below 16
	 jb	 short @F	; Then jump

	 mov	 ecx,16 	; Else size to clear is 16
@@:
	 xor	 al,al		; A zero byte
     rep stos	 es:[edi].LO	; Stick it

	 cmp	 BlockedHandle,ebx ; Blocked on this handle?
	 jne	 short @F	; Jump if not

	 mov	 BlockedStatus,0 ; Clear block
@@:
	 clc			; Flag success

	 jmp	 short GETSHR_EXIT ; Join common exit code

GETSHR_ERROR:
	 stc			; Flag error
GETSHR_EXIT:
	 ret			; Return to caller

GETSHR_ERR_INVVAL:
	 mov	 ax,8025h	; Invalid value error

	 jmp	 GETSHR_ERROR	; Join error code

GETSHR_ERR_NOMEM:
	 mov	 ax,8013h	; Not enough memory

	 jmp	 GETSHR_ERROR	; Join error code

GETSHR_ERR_NOHNDL:
	 mov	 ax,8016h	; Handle unavailable

	 jmp	 GETSHR_ERROR	; Join error code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDPMI_GETSHR endp		; End FDPMI_GETSHR procedure
	 FPPROC  FDPMI_RELSHR -- DPMI 1.0 Function to Release Shared Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI 1.0 function to allocate shared memory

On entry (in INTXX_STR):

AX	 =	 0D01h
SI:DI	 =	 selector:offset of shared memory handle
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8023 bad handle

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 pushf			; Save flags
	 cli			; don't interrupt

; Do a sanity check on the handle. Remember that the client's handle is
; an offset in the shared memory handles array. Compare the value against
; the total allocated size of that array.

	 mov	 ax,[ebp].INTXX_ESI.ELO ; High half of handle
	 shl	 eax,16 	; Shift it up
	 mov	 ax,[ebp].INTXX_EDI.ELO ; Low half of handle

	 cmp	 eax, SHMEMHANDLESIZE ; Is it within reason
	 jae	 short DPMI_RELSHR_ERROR ; Jump if not

	 add	 eax,PSHMEMHANDLES ; Add base of handles array
	 mov	 ebx,eax	; Copy to ebx

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

; Update the information in the shared memory handle

	 call	 SMEM_REMOVE_USER ; Dec usage count by client
	 jc	 short DPMI_RELSHR_ERROR ; Client is not a user

; When the user count for a block goes to zero we can free the memory
; and the handle.

	 call	 SMEM_USER_COUNT ; Get user count for block

	 or	 eax,eax	; Is user count zero?
	 jnz	 short DPMI_RELSHR_SUCCESS	; done (success) if not zero

; First free the memory

	 cmp	 AGROUP:[ebx].SMH_length,0 ; Is it zero length?
	 je	 short @F	; Jump if yes

	 REGSAVE <ebx,ds>	; Save handle address

	 mov	 eax,AGROUP:[ebx].SMH_la ; Get linear address
	 mov	 ebx,AGROUP:[ebx].SMH_length ; Get length in bytes
	 add	 ebx,@PageSize-1 ; Round up to page
	 shr	 ebx,@BytePage	; Convert to pages

	 mov	 ds,SEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 FIXICALL IGROUP:FVMM_FREE,DTE_CSIG ; Let it go

	 REGREST <ds,ebx>	; Restore
	 assume  ds:PGROUP	; Tell the assembler about it
@@:

; If we were in a blocked state, pending on this block, then cancel
; the serialization request.

	 cmp	 BlockedStatus,1 ; Are we blocked?
	 jne	 short @F	; Jump if not

	 cmp	 BlockedHandle,ebx ; Blocked on this handle?
	 jne	 short @F	; Jump if not

	 mov	 BlockedStatus,0 ; Clear block
@@:
	 mov	 es:[ebx].SMH_la,0  ; Mark handle as not in use

	 jmp	 short DPMI_RELSHR_SUCCESS ; Done

DPMI_RELSHR_ERROR:
	 popf			; Restore flags

	 stc			; Flag error

	 mov	 ax,8023h	; Invalid handle error code

	 ret			; Return to caller

DPMI_RELSHR_SUCCESS:
	 popf			; Restore flags

	 clc			; Flag success

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDPMI_RELSHR endp		; End of FDPMI_RELSHR procedure
	 FPPROC  FDPMI_SERIALIZE -- DPMI 1.0 Function to Serialize on Shared Memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI 1.0 function to serialize on shared memory

Since we have only a single thread, only one client can
be in a blocked state at any given time.  This is evident
because as soon as one client blocks, no other client can
gain control and become the second blocked client.  In a
multi-threaded system, any non-blocked thread could be
scheduled when the active thread becomes blocked.  Since
we do not have multiple threads, we have no choice but to
become idle when the active client becomes blocked.

The only activity in the system that is not synchronous
with the single thread is the activity related to
hardware interrupts.  The specification allows
hardware interrupt handlers to remain active while a client
is blocked.  In our implementation, a hardware interrupt
handler may unblock a blocked client by cancelling a
pending serialization request or by releasing ownership
of a shared memory block.  The interrupt handler may
run in the context of either the blocked client or another
client in the system; since all hardware interrupt handlers
are asynchronous with the main thread, it is largely
irrelevant.  The only consideration that the application
developer must make with regards to this distinction is that
a pending serialization can only be cancelled by the
blocked client, and a serialization on a shared block
can only be released by the client that owns it.

The functionality that the shared memory facility is
capable of providing is then limited to waiting for
a particular asynchronous external event prior to resuming
execution of the main thread. (Equivalent functionality can
easily be implemented without the aid of the shared memory
facility.)  If the event is trapped by an interrupt handler
running in the context of the client that owns the shared
memory for which the system is blocked, the interrupt handler
may unblock the system by releasing the shared memory.
If the event is trapped by an interrupt handler
running in the context of the client which blocked, the
interrupt handler may unblock the system by cancelling the
serialization request.

The two distinct means to unblock the system are reflected
in the dual nature of DPMI function 0D03h, Free Serialization.
The function is actually two separate functions: (1) release
ownership (shared or exclusive) of shared memory block, and
(2) cancel a pending serialization request.

On entry (in INTXX_STR):

AX	 =	 0D02h
DX	 =	 option bits
		 bit 0	=0 suspend until available =1 just return
		 bit 1	=0 exclusive serialize =1 shared serialize
SI:DI	 =	 selector:offset of shared memory handle
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8004 deadlock
		 8005 serialization request cancelled by function 0D03h
		 8017 lock count exceeded
		 8018 exclusize serialize failed because block is already
		      under exclusive serialization
		 8019 exclusize serialize failed because block is already
		      under shared serialization
		 8023 bad handle

All other registers except EBP, FS, GS, and SS may be clobbered.

|

; Do a sanity check on the handle. Remember that the client's handle is
; an offset in the shared memory handles array. Compare the value against
; the total allocated size of that array.

	 mov	 ax,[ebp].INTXX_ESI.ELO ; High half of handle
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_EDI.ELO ; Low half of handle

	 cmp	 eax,SHMEMHANDLESIZE ; Is it within reason
	 jae	 SERIAL_ERR_INVHNDL ; Jump if not

	 add	 eax,PSHMEMHANDLES ; Add base of handles array
	 mov	 ebx,eax	; Copy to EBX

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

; EBX is now the linear address of the given shared memory handle

	 mov	 dx,1		; Signal first pass thru loop
DPMI_SERIAL_LOOP:
	 pushf			; Save flags
	 cli			; don't interrupt

	 cmp	 dx,1		; First pass?
	 je	 short @F	; Skip if yes

	 cmp	 BlockedStatus,0 ; Has a req been cancelled?
	 je	 short DPMI_SERIAL_CANCEL ; yes - jump
@@:
	 xor	 dx,dx		; NOT first pass now

	 call	 SMEM_GET_STATE ; AX <- shared mem state(EBX)

	 cmp	 ax,@SMEM_FREE	; If no serializations
	 je	 short DPMI_SERIAL_ADD ; Go for it

	 cmp	 ax,@SMEM_EXCLUSIVE ; Else if exclusive
	 je	 short DPMI_SERIAL_BLOCKED ; Too bad
				; else must be shared
	 test	 [ebp].INTXX_EDX.ELO.LO,@BIT1 ; Test requested serial type
	 jz	 short DPMI_SERIAL_BLOCKED ; Jump if exclusive requested

DPMI_SERIAL_ADD:
	 test	 [ebp].INTXX_EDX.ELO.LO,@BIT1 ; Test requested serial type
	 setnz	 al		; Pass result as argument

	 call	 SMEM_ADD_SERIAL ; Update serialization data
	 jc	 short DPMI_SERIAL_BADHANDLE ; Jump if current client
				; not a user of the block
	 popf			; We are done

	 clc			; Flag success

	 ret			; Return to caller

DPMI_SERIAL_BLOCKED:		; Here if mem not available
	 test	 [ebp].INTXX_EDX.ELO.LO,@BIT0 ; Test if suspend requested
	 jz	 short DPMI_SERIAL_SETBLOCK ; Jump if client wants to blk

; Client does not wish to suspend. Return appropriate error code.

	 popf			; Restore flags

	 cmp	 ax,@SMEM_EXCLUSIVE ; Branch on mem state
	 je	 near ptr SERIAL_ERR_EXCLUSIVE ; State is exclusive lock

	 jmp	 near ptr SERIAL_ERR_SHARED	; state is shared lock

DPMI_SERIAL_SETBLOCK:		; Become blocked here
	 str	 BlockedClient	; Record as client who blocked
	 mov	 BlockedHandle,ebx ; Record memory we blocked on
	 test	 [ebp].INTXX_EDX.ELO.LO,@BIT1 ; Test requested serial type
	 setnz	 BlockedType	; Record blocked req type
	 mov	 BlockedStatus,1 ; now blocked

	 popf			; Maybe allow interrupts

	 nop			; The pause that refreshes

	 jmp	 DPMI_SERIAL_LOOP ; Wait for things to change

DPMI_SERIAL_CANCEL:
	 popf			; Get flags back

	 jmp	 short SERIAL_ERR_REQCAN ; Jump to common error code

DPMI_SERIAL_BADHANDLE:
	 popf			; Get flags back

	 jmp	 short SERIAL_ERR_INVHNDL ; Jump to common error code

SERIAL_ERR_EXCLUSIVE:
	 mov	 ax,8018h	; Exclusive error

	 jmp	 short SERIAL_ERR_EXIT ; Join error code

SERIAL_ERR_SHARED:
	 mov	 ax,8019h	; Shared error

	 jmp	 short SERIAL_ERR_EXIT ; Join error code

SERIAL_ERR_REQCAN:
	 mov	 ax,8005h	; Request was cancelled

	 jmp	 short SERIAL_ERR_EXIT ; Join error code

SERIAL_ERR_INVHNDL:
	 mov	 ax,8023h	; Bad handle
SERIAL_ERR_EXIT:
	 stc			; Flag error

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDPMI_SERIALIZE endp		; End DPMI_SERIALIZE procedure
	 FPPROC  FDPMI_RELSERIAL -- DPMI 1.0 Function to Release Serialization
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

DPMI 1.0 function to:
	(1) release serialization of a shared memory block
	(2) cancel a pending serialization request

On entry (in INTXX_STR):

AX	 =	 0D03h
DX	 =	 option bits
		 bit 0	=0 release an exclusive serialization
			=1 release a shared serialization
		 bit 1	=0 release serialization
			=1 cancel a pending serialization request
SI:DI	 =	 selector:offset of shared memory handle
IF	 =	 caller's (possibly enabled)
SS:EBP	 ==>	 INTXX_STR (nothing above INTXX_EFL is valid)

On exit (in INTXX_STR):

CF	 =	 0 if successful

CF	 =	 1 if not successful
AX	 =	 8002 invalid state
		 8023 bad handle

All other registers except EBP, FS, GS, and SS may be clobbered.

|

	 pushf				; hold flags
	 cli				; don't interrupt

; Do a sanity check on the handle. Remember that the client's handle is
; an offset in the shared memory handles array. Compare the value against
; the total allocated size of that array.

	 mov	 ax,[ebp].INTXX_ESI.ELO ; High half of handle
	 shl	 eax,16 	; Shift to high-order word
	 mov	 ax,[ebp].INTXX_EDI.ELO ; Low half of handle
	 cmp	 eax,SHMEMHANDLESIZE ; Is it within reason
	 jae	 short DPMI_RELSER_BADHNDL ; Jump if not

	 add	 eax,PSHMEMHANDLES ; Add base of handles array
	 mov	 ebx,eax	; Copy to EBX

	 mov	 es,SEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

; First see if client is trying to cancel a pending request. In order
; to cancel, the following conditions must hold:
;
;	1) We must be in a blocked state
;	2) The memory block specified for this call must be the memory
;	   that we blocked on.
;	3) The client which is blocked must be the current client
;	4) The serialization type specified for this call must match the
;	   serialization type of the blocked request.

	 test	 [ebp].INTXX_EDX.ELO.LO,@BIT1 ; test pending bit in options
	 jz	 short DPMI_RELSER_RELEASE ; jump if not cancelling

	 cmp	 BlockedStatus,0		; are we blocked?
	 je	 short DPMI_RELSER_BADREQUEST	; jump if not

	 str	 ax

	 cmp	 BlockedClient,ax ; Is this blocked client?
	 jne	 short DPMI_RELSER_BADREQUEST ; Jump if not

	 cmp	 BlockedHandle,ebx ; Is this blocked mem?
	 jne	 short DPMI_RELSER_BADREQUEST ; Jump if not

	 test	 [ebp].INTXX_EDX.ELO.LO,@BIT0 ; Get request type
	 setnz	 al		; AL <- request type

	 cmp	 BlockedType,al ; Does the type match?
	 jne	 short DPMI_RELSER_BADREQUEST ; Jump if not

; Here if we meet all conditions for cancelling the request:

	 mov	 BlockedStatus,0 ; Cancel the request

	 jmp	 short DPMI_RELSER_SUCCESS ; Successfully cancelled

DPMI_RELSER_RELEASE:
	 test	 [ebp].INTXX_EDX.ELO.LO,@BIT0 ; Get request type
	 setnz	 al		; AL <- request type arg

	 call	 SMEM_REMOVE_SERIAL ; Update serialization info
	 jc	 short DPMI_RELSER_BADREQUEST ; Jump if bad request
DPMI_RELSER_SUCCESS:
	 popf			; Restore flags

	 clc			; flag success

	 ret			; Return to caller

DPMI_RELSER_BADHNDL:
	 popf			; Restore flags

	 stc			; Flag error

	 mov	 ax,8023h	; Bad handle error

	 ret			; Return to caller

DPMI_RELSER_BADREQUEST:
	 popf			; Restore flags

	 mov	 ax,8002h	; Block not in correct state for req

	 stc			; Flag error

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

FDPMI_RELSERIAL endp		; End DPMI_RELSERIAL procedure
	 NPPROC  SMEM_ADD_USER -- Utility function for shared memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Utility function for shared memory - record usage of block by current client

On entry:

ES:EBX	=	shared memory handle

|

	REGSAVE <ax, cx, edi>

	pushf
	cli

; First see if this block has an entry for the current client

	 lea	 edi,[ebx].SMH_cinfo		 ; point to info records
	 mov	 cx,@TSS_MAX			 ; count of info records
	 str	 ax				 ; ax <- current client
SMEM_ADD_NEXT:
	 cmp	 es:[edi].smci_client,ax	 ; compare this client
	 je	 short SMEM_ADD_GOT_CLIENT	 ; jmp if matches

	 add	 edi,size SMClientInfo		; advance to next record

	 loop	 SMEM_ADD_NEXT			 ; go do next

; Client not found - put in first unused slot

	 lea	 edi,[ebx].SMH_cinfo		 ; point to info records
	 mov	 cx,@TSS_MAX			 ; count of info records
SMEM_ADD_NEW:
	 cmp	 es:[edi].smci_client,0 	 ; unused?
	 jne	 short @F			 ; jump if not

	 mov	 es:[edi].smci_client,ax	 ; grab this slot

	 jmp	 short SMEM_ADD_GOT_CLIENT

@@:
	 add	 edi,size SMClientInfo ; Advance to next record

	 loop	 SMEM_ADD_NEW	; Go do next

	 int 3			; ?? no slot available ??
SMEM_ADD_GOT_CLIENT:
	 inc	 es:[edi].smci_uses ; Usage noted

	 popf			; Allow ints maybe

	 REGREST <edi,cx,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SMEM_ADD_USER endp		; End SMEM_ADD_USER procedure
	 NPPROC  SMEM_ADD_SERIAL -- Utility function for shared memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Utility function for shared memory - record serialization of block
by current client

On entry:

AL	=	0 ==> exclusive serialization
		1 ==> shared serialization
ES:EBX	=	shared memory handle

On exit:

CF	=	0 success
	=	1 error - current client is not a user of the block

|

	 REGSAVE <cx,dx,edi>	; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

; First see if this block has an entry for the current client

	 lea	 edi,[ebx].SMH_cinfo ; Point to info records
	 mov	 cx,@TSS_MAX	; Count of info records
	 str	 dx		; DX <- current client
SMEM_ADDSER_NEXT:
	 cmp	 es:[edi].smci_client,dx ; Compare this client
	 je	 short SMEM_ADDSER_GOT_CLIENT ; Jmp if matches

	 add	 edi,size SMClientInfo ; Advance to next record

	 loop	 SMEM_ADDSER_NEXT ; Go do next

; Client not found - return error

SMEM_ADDSER_FAIL:
	 popf			; Restore flags

	 stc			; Flag error

	 jmp	 short SMEM_ADDSER_EXIT ; Join common exit code

SMEM_ADDSER_GOT_CLIENT:
	 cmp	 es:[edi].smci_uses,0 ; Is client a user?
	 je	 SMEM_ADDSER_FAIL ; Jump out if not

	 or	 al,al		; Test serialization type
	 jz	 short @F	; Jump if exclusive

	 inc	 es:[edi].smci_shares ; Bump counter

	 jmp	 short SMEM_ADDSER_SUCCESS ; We are done

@@:
	 inc	 es:[edi].smci_excl ; Bump counter
SMEM_ADDSER_SUCCESS:
	 popf			; Restore flags

	 clc			; Flag success
SMEM_ADDSER_EXIT:
	 REGREST <edi,dx,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SMEM_ADD_SERIAL endp		; End SMEM_ADD_SERIAL procedure
	 NPPROC  SMEM_REMOVE_SERIAL -- Utility function for shared memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Utility function for shared memory - record release of serialization of block
by current client

On entry:

AL	=	0 ==> exclusive serialization
		1 ==> shared serialization
ES:EBX	=	shared memory handle

On exit:

CF	=	0 success
	=	1 error - current client is not a user of the block or did
		not have the indicated type of serialization

|

	 REGSAVE <cx, dx, edi>

	 pushf					 ; don't allow interrupts
	 cli

; First see if this block has an entry for the current client

	 lea	 edi,[ebx].SMH_cinfo		 ; point to info records
	 mov	 cx,@TSS_MAX			 ; count of info records
	 str	 dx				 ; dx <- current client
SMEM_REMSER_NEXT:
	 cmp	 es:[edi].smci_client,dx	 ; compare this client
	 je	 short SMEM_REMSER_GOT_CLIENT	 ; jmp if matches

	 add	 edi, size SMClientInfo 	 ; advance to next record

	 loop	 SMEM_REMSER_NEXT		 ; go do next

; Client not found - return error

SMEM_REMSER_FAIL:
	 popf		; Restore flags

	 stc		; Flag error

	 jmp	 short SMEM_REMSER_EXIT ; Join common exit code

SMEM_REMSER_GOT_CLIENT:
	 cmp	 es:[edi].smci_uses,0 ; Is client a user?
	 je	 short SMEM_REMSER_FAIL ; Jump if not

	 or	 al,al		; Test serialization type
	 jz	 short @F	; Jump if exclusive

	 cmp	 es:[edi].smci_shares, 0	 ; anything to release?
	 je	 SMEM_REMSER_FAIL		 ; jump if not

	 dec	 es:[edi].smci_shares		 ; release serialization

	 jmp	 short SMEM_REMSER_SUCCESS

@@:
	 cmp	 es:[edi].smci_excl,0 ; Anything to release?
	 je	 short SMEM_REMSER_FAIL ; Jump if not

	 dec	 es:[edi].smci_excl ; Release serialization
SMEM_REMSER_SUCCESS:
	 popf			; Restore flags

	 clc			; Flag success
SMEM_REMSER_EXIT:
	 REGREST <edi,dx,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SMEM_REMOVE_SERIAL endp 	; End SMEM_REMOVE_SERIAL procedure
	 NPPROC  SMEM_REMOVE_USER -- Utility function for shared memory
	 assume  ds:PGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Utility function for shared memory - decrement usage count of given
for block by current client.

On entry:

ES:EBX	=	shared memory handle

On exit:

CF	=	0 Success
	=	1 Error - current client is not a user of the block

|
	 REGSAVE <ax,cx,edi>	; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

; First see if this block has an entry for the current client

	 lea	 edi,[ebx].SMH_cinfo ; Point to info records
	 mov	 cx,@TSS_MAX	; Count of info records
	 str	 ax		; AX <- current client
SMEM_REMOVE_NEXT:
	 cmp	 es:[edi].smci_client,ax ; Compare this client
	 je	 short SMEM_REMOVE_FOUND_CLIENT ; Jump if matches

	 add	 edi,size SMClientInfo ; Advance to next record

	 loop	 SMEM_REMOVE_NEXT ; Go do next

	 jmp	 short SMEM_REMOVE_NOT

; Client not found

SMEM_REMOVE_FOUND_CLIENT:
	 cmp	 es:[edi].smci_uses,0 ; Any uses?
	 je	 short SMEM_REMOVE_NOT ; Jump if not

; If use count for client becomes zero, zero out it's owner counts

	 dec	 es:[edi].smci_uses ; Decrement use count
	 jnz	 short @F	; If count for client is zero

	 xor	 ax,ax		; Zero out the owner counts
	 mov	 es:[edi].smci_shares,ax ; Zero the share count
	 mov	 es:[edi].smci_excl,ax ; Zero the exclusive count
@@:
	 popf			; Restore flags

	 clc			; Return true
SMEM_REMOVE_EXIT:
	 REGREST <edi,cx,ax>	; Restore

	 ret			; Return to caller

SMEM_REMOVE_NOT:
	 popf			; Restore flags

	 stc			; Return false

	 jmp	 SMEM_REMOVE_EXIT ; Join common exit code

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SMEM_REMOVE_USER endp		; End SMEM_REMOVE_USER procedure
	 NPPROC  SMEM_FIND_NAME -- Utility function for shared memory
	 assume  ds:nothing,es:AGROUP,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Utility function for shared memory - find given name in shared mem handles

On entry:

ES	=	AGROUP
DS:ESI	=	name passed by client

On exit:

EBX	=	pointer to address of handle (record) if found
	=	zero if not found

|
	 REGSAVE <eax,ecx,edx,edi>	; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 mov	 ebx,PSHMEMHANDLES ; EBX <- LA of shared mem handles
	 mov	 edx,SHMEMHANDLESIZE ; EDX <- size ...
	 add	 edx,ebx	; EDX <- end of ...

; Loop through each handle, searching for the given name

SMEM_FIND_SEARCH:
	 cmp	 ebx,edx	; Are we done?
	 jae	 short SMEM_FIND_NOTFOUND ; Jump if didn't find it

	 cmp	 AGROUP:[ebx].SMH_la,0 ; If address is zero,
	 je	 short SMEM_FIND_ADVANCE ; ...ignore this handle

	 lea	 edi,[ebx].SMH_name ; EDI <- name for this handle
	 mov	 ecx,size SMH_name ; Max name length
	 mov	 eax,esi	; Remember requested name offset
	 cld
    repe cmps	 ds:[esi].LO,AGROUP:[edi].LO ; Try to match names
	 lea	 esi,[esi-2]	; Backup to last matching char
	 xchg	 esi,eax	; Restore ESI to requested name ptr

	 cmp	 eax,esi	; If EAX < ESI, no matching char
	 jb	 short SMEM_FIND_ADVANCE ; So go get next handle

	 cmp	 ds:[eax].LO,0	  ; If last match was zero byte, success
	 je	 short SMEM_FIND_EXIT ; EBX is handle address - go do it
SMEM_FIND_ADVANCE:
	 add	 ebx,size SharedMemHandle ; Advance handle array pointer

	 jmp	 SMEM_FIND_SEARCH ; Look again

SMEM_FIND_NOTFOUND:
	 xor	 ebx, ebx	; Return EBX==0 to indicate not found
SMEM_FIND_EXIT:
	 popf			; Restore flags

	 REGREST <edi,edx,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SMEM_FIND_NAME endp		; End SMEM_FIND_NAME procedure
	 NPPROC  SMEM_USER_COUNT -- Utility function for shared memory
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Utility function for shared memory - get user count for a given block

On entry:

ES:EBX	 =	 shared memory handle

On exit:

EAX	 =	 number of clients that have a non-zero use count for the block

|

	 REGSAVE <cx,edi>	; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 lea	 edi,es:[ebx].SMH_cinfo ; Point to client info
	 mov	 cx,@TSS_MAX	; Count of client records
	 xor	 eax,eax	; Init count
SMEM_COUNT_NEXT:
	 cmp	 es:[edi].smci_client,0 ; Record in use?
	 je	 short SMEM_COUNT_ADVANCE ; Jump if not

	 cmp	 es:[edi].smci_uses,0 ; Any uses?
	 je	 short SMEM_COUNT_ADVANCE ; Jump if not

	 inc	 eax		; Bump counter
SMEM_COUNT_ADVANCE:
	 add	 edi,size SMClientInfo ; Point to next client record

	 loop	 SMEM_COUNT_NEXT ; Do next one

	 popf			; Restore flags

	 REGREST <edi,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SMEM_USER_COUNT endp		; End SMEM_USER_COUNT procedure
	 NPPROC  SMEM_GET_STATE -- Utility function for shared memory
	 assume  ds:PGROUP,es:AGROUP,fs:nothing,gs:nothing,ss:nothing
COMMENT|

Utility function for shared memory - get the state of a given block.
A block is always in one of three states:

	@SMEM_FREE		not serialized
	@SMEM_SHARED		shared serialized
	@SMEM_EXCLUSIVE 	exclusive serialized

On entry:

ES:EBX	=	shared memory handle

On exit:

AX	=	block state (@SMEM_FREE, @SMEM_SHARED, or @SMEM_EXCLUSIVE)

|

	 REGSAVE <cx,edi>	; Save registers

	 pushf			; Save flags
	 cli			; Disallow interrupts

	 lea	 edi,es:[ebx].SMH_cinfo ; Point to client info
	 mov	 cx,@TSS_MAX	; Count of client records
	 xor	 eax,eax	; Init count
SMEM_STATE_NEXT:
	 cmp	 es:[edi].smci_client,0 ; Record in use?
	 je	 short SMEM_STATE_ADVANCE ; Jump if not

	 cmp	 es:[edi].smci_uses,0 ; Any uses?
	 je	 short SMEM_STATE_ADVANCE ; Jump if not

	 cmp	 es:[edi].smci_shares,0 ; Any shares?
	 jne	 short SMEM_STATE_SHARED ; Jump if so

	 cmp	 es:[edi].smci_excl,0 ; Any exclusives? (at most,1)
	 jne	 short SMEM_STATE_EXCL ; Jump if so
SMEM_STATE_ADVANCE:
	 add	 edi,size SMClientInfo ; Advance to next

	 loop	 SMEM_STATE_NEXT ; Go do next one until done

; If we fall thru, the state is free

	 mov	 ax,@SMEM_FREE	; Set free state

	 jmp	 short SMEM_STATE_EXIT ; Join common exit code

SMEM_STATE_SHARED:
	 mov	 ax,@SMEM_SHARED ; Set shared state

	 jmp	 short SMEM_STATE_EXIT ; Join common exit code

SMEM_STATE_EXCL:
	mov	ax,@SMEM_EXCLUSIVE ; Set exclusive state
SMEM_STATE_EXIT:
	 popf			; Restore flags

	 REGREST <edi,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

SMEM_GET_STATE endp		; End SMEM_GET_STATE procedure
	 align	 4		; Ensure dword alignment

JCODE	 ends			; End JCODE segment
endif				; IF @OEM_DPMI

	 MEND			; End QMAX_SHR module
