;' $Header:   P:/PVCS/MAX/386MAX/QMAX_BSM.ASV   1.2   30 May 1997 10:44:12   BOB  $
	 title	 QMAX_BSM -- DPMI Backing Store Manager functions
	 page	 58,122
	 name	 QMAX_BSM

COMMENT|		Module Specifications

Copyright:  (C) Copyright 1987-98 Qualitas, Inc.  All rights reserved.

Segmentation:  Group PGROUP:
	       Data    segment EDATA, dword-aligned, public, class 'edata'
	       Group IGROUP:
	       Data    segment LDATA, dword-aligned, public, class 'icode'
	       Program segment ICODE, dword-aligned, public, class 'icode'
	       Data    segment IDATA, dword-aligned, public, class 'idata'

Program derived from:  None.

Modifications by:  None.

|

.386p
.xlist
	 include MASM.INC
	 include 386.INC
	 include PTR.INC
	 include DOSCALL.INC
	 include OPEN.INC
	 include ALLMEM.INC
	 include DIR.INC
	 include 8259.INC

	 include QMAX_OEM.INC
	 include QMAX_DTE.INC
	 include QMAX_TSS.INC
	 include QMAX_VMM.INC
	 include QMAXDPMI.INC
.list

if @OEM_VIRTUALMEM

PGROUP	 group	 EDATA
IGROUP	 group	 LDATA,ICODE,IDATA


EDATA	 segment use16 dword public 'edata' ; Start EDATA segment
	 assume  ds:PGROUP

	 extrn	 I31_FLAG:word
	 extrn	 DPM_FLAG:word
	 include QMAX_I31.INC

	 extrn	 DESC_TAB:qword
	 extrn	 VM2PM_PSP:word
	 extrn	 HPDABUF_SIZ:word
	 extrn	 PCURTSS:dword
	 extrn	 VMM_FLAG:word
	 extrn	 LaINDOS:dword

EDATA	 ends			; End EDATA segment


LDATA	 segment use16 dword public 'icode' ; Start LDATA segment
	 assume  ds:IGROUP

	 extrn	 ISEL_4GB3:word
	 extrn	 ISEL_DSIG3:word

LDATA	 ends			; End LDATA segment


IDATA	segment use16 dword public 'idata' ; Start IDATA segment
	assume	ds:IGROUP

	 public  PBSCache
PBSCache dd	 ?		; Offset in IGROUP of BSCache

	 public  BSMap,BSMapTop,BSMax,BSMin,BSInUse,BSPath
	 public  BSHit,BSMiss,BSActive
	 public  PageIOActive,LastSwapPSP,LastSwapHandle
BSMap	 dd	 0		; Linear address of BS map
BSMapTop dd	 0
BSMax	 dd	 0		; Max size to grow to in pages
BSMin	 dd	 1024*1024	; Min size to shrink to in bytes
BSInUse  dd	 0		; Number of pages in use
BSPath	 db	 80 dup (?)	; Name of swapfile
BSHit	 dd	 0		; Cache hits counter (info only)
BSMiss	 dd	 0		; Cache misses counter
BSActive db	 0		; Non-zero if pages should be aged
PageIOActive db  0		; Non-zero if page I/O in progress
LastSwapPSP dw	 0		; Last PSP used for page I/O
LastSwapHandle dw 0		; Last handle used for page I/O


BSFHeader struc 			; backing store file header struc

BSF_sig  dd	 ?		; Signature @BSF_SIGN
BSF_ver  dw	 ?		; Version number @BSFversion
BSF_size dd	 ?		; Size in pages

BSFHeader ends


@BSF_SIGN equ	 'PWSQ'         ; BS signature 'QSWP' in byte order
@BSFversion equ  1		; BS version #
@BSFTotal equ	 8192/4 	; Default BS size (8 MB in units of 4 KB)

	 public  BSFHDR,BSTotal,BSGTotal
BSFHDR	 BSFHeader <@BSF_SIGN, @BSFversion, 0> ; Default BS header info
BSTotal  equ	 BSFHDR.BSF_size ; Total size of BS in pages
BSGTotal dd	 @BSFTotal	; Global BS total size (default=8MB)

	 public  BSFTemp
BSFTemp  BSFHeader <>		; Temporary struc for testing


BSCEntry struc			; Backing store cache entry struc

BSCBackAddress dd ?		; Backing store address of page
				; MSB is set if entry is valid
BSCPage  dd	 ?		; Virtual address/client (low 12 bits)

BSCEntry ends


@BSCIndexBits		equ	9	; determines size of BS cache
@BSCLen 		equ	1 shl @BSCIndexBits ; number of cache entries
@BSCEntryValidBit	equ	31
@nClientBits		equ	12

	 public  @BSCSize
@BSCSize equ	 @BSCLen * (type BSCEntry) ; # bytes in static cache

IDATA	 ends			; End IDATA segment


ICODE	 segment use16 dword public 'icode' ; Start ICODE segment
	 assume  cs:IGROUP

	 extrn	 DPMIFN_GETPSP:near
	 extrn	 DPMIFN_SETPSP:near
	 extrn	 VMM_GET_PHYSICAL_PAGE:near
	 extrn	 VMM_ZERO_PAGE:near
	 extrn	 VMM_ALLOC:near
	 extrn	 VMM_LOCK:near
	 extrn	 LSM_MAP_PAGE:near

	 public  @QMAX_BSM_ICODE
@QMAX_BSM_ICODE:

COMMENT| The Backing Store Manager

The BSM manages the swapfile.  A single swapfile is used by all DPMI
clients, although each client has its own file handle to read and
write it.

Allocation is via a bitmap, in which there is one bit per backing store
page.  If the bit is set, the corresponding page is in use, otherwise
it is free.

When a page is read from the backing store, the BSM is no longer responsible
for maintaining the contents of that virutal page.  However, the BSM does
not immediately free a recently read page in order to avoid having to
write it the next time it is put on the backing store.

The low bits of the virtual page address form the index into the backing
store cache.  The number of bits required depends on cache size, and is
an assembly time constant.

Each cache entry contains a valid bit, a virtual page number, a client
identifier, and the backstore address from which the specified client's
virtual page was last read.  Since the backing store is used for all clients,
and each client has its own virtual address space, the BSM must maintain
client information to determine cache hits.

When the VMM gets a page from the backing store, the BSM compares the
requested virtual page with the virtual page specified by the cache entry
indexed by the requested virtual page.	If they are different, the
BSM then frees the backing store page specified in the cache entry.  The
cache entry is then updated with the newly requested virtual page and its
backing store address.

When the VMM puts a clean page on the backing store, the BSM compares
the specified virtual page with the page in the corresponding cache
entry.	If they are the same, a cache hit occurs and the BSM simply
returns the cached backstore address.  If they are different, the BSM
allocates a free backing store page, and writes out the page contents.

When the VMM frees a backing store page (because a client terminated or
freed the corresponding memory), the BSM must invalidate the corresponding
cache entry if the cache entry matches the freed virtual page.
|
	 NPPROC  BSM_INIT -- Initialize backing store
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Initialize Backing Store manager.

On entry:

EAX	=	size of backing store file in pages

On exit:

CF	 =	 0 if it worked
	 =	 1 otherwise
AX	 =	 error code

|

	 REGSAVE <ebx,ecx,edx,esi,edi> ; Save registers

	 mov	 bx,-1		; Mark as unopened in case we fail

	 test	 VMM_FLAG,@VMM_BSPRES ; Test if swapfile=xxxxx was found
	 jz	 near ptr BSM_INIT_NOSWAP ; Jump if not (note CF=0)

	 bts	 PageIOActive,0 ; Set active and test current state
	 jnc	 short @F	; Jump if page I/O not active

	 int	 3		; Recursive page I/O == death
@@:
COMMENT|

The name of the swapfile is in BSPath.	If the file doesn't exist,
create it here with size given by BSTotal.  If it does exist, read the
header to get the full size and then grow it to that size.

|

	 call	 BSM_OPEN	; Open the swapfile, return handle in AX
	 jc	 near ptr BSM_INIT_CREATE ; Jump if we can't open it

; Read the header into a temp buffer allocated on the stack

	 mov	 bx,ax		; Copy to handle register

	 mov	 ecx,size BSFTemp ; Number of bytes to read
	 lea	 edx,BSFTemp	; DS:eDX ==> temporary buffer
	 mov	 ah,@READF2	; Function code
	 DOSCALL0		; Read it
	 jc	 near ptr BSM_INIT_FAIL ; Jump if error

	 cmp	 BSFTemp.BSF_sig,@BSF_SIGN ; Izit a valid signature?
	 je	 short BSM_INIT_SIGOK	 ; Jump if so

	 mov	 eax,BSTotal	; Default size is BSTotal
	 mov	 BSFTemp.BSF_size,eax ; Use default
BSM_INIT_SIGOK:
	 mov	 edx,BSFTemp.BSF_size ; Read size

; Seek to the size of the file and do a write to commit the space

BSM_INIT_SETSIZE0:
	 shl	 edx,@BytePage	; Convert size to bytes
BSM_INIT_SETSIZE:
	 mov	 esi,edx	; Save size in ESI

	 call	 BSM_GROWSWAP	; Grow the swapfile to EDX bytes and truncate
	 jc	 short BSM_TRY_SMALLER ; Jump if error

	 call	 BSM_CLOSE	; Close the SWAPFILE
	 jc	 short BSM_INIT_FAIL ; Jump if error

	 mov	 bx,-1		; Mark handle register as invalid

	 jmp	 BSM_INIT_SETUPMAP ; Continue

BSM_TRY_SMALLER:		; ESI is the size just tried in bytes
	 shr	 esi,1		; Try half as big

	 cmp	 esi,BSMin	; Is it getting too small?
	 jb	 short @F	; Jump if so

	 mov	 edx,esi	; Copy size in bytes to EDX

	 jmp	 BSM_INIT_SETSIZE ; Try it again

@@:				; Here if we shrank below BSMin
	 call	 BSM_CLOSE	; Close the SWAPFILE
				; ignoring error return
	 mov	 bx,-1		; Mark handle register as invalid
BSM_INIT_FAIL:			; Here if file error
	 cmp	 bx,-1		; Is the handle register valid?
	 je	 short @F	; Jump if not

	 call	 BSM_CLOSE	; Close the SWAPFILE
;;;;;;;; jc	 short ???	; Ignore error return
;;;;;;;; mov	 bx,-1		; Mark handle register as invalid
@@:
	 clc			; Continue without swapfile

; No swapfile:	CF is significant on entry here

BSM_INIT_NOSWAP:
	 mov	 BSTotal,0	; No swap space
	 and	 VMM_FLAG,not @VMM_BSPRES ; Mark as not present

	 jmp	 BSM_INIT_EXIT	; Join exit code

BSM_INIT_CREATE:		; Here if we must create new bs file
	 call	 BSM_CREATE	; Create the swapfile, return handle in AX
	 jc	 short BSM_INIT_FAIL ; Jump if error

	 mov	 bx,ax		; Handle to bx
	 mov	 edx,BSTotal	; File size

	 jmp	 BSM_INIT_SETSIZE0 ; Process

BSM_INIT_SETUPMAP:

; The Backing Store map will reside 4MB below the page tables. Set
; the top equal to the start to indicate that the map initially is zero
; bytes in length. We will grow it later.

	 mov	 BSMap,@PTBase - @FourMeg ; Set address of BS map
	 mov	 BSMapTop,@PTBase - @FourMeg ; Initially zero length

	 mov	 eax,BSTotal	; Get size of BS file in 4KB
	 add	 eax,32*1024-1	; Round up to 32k multiple of 4KB
	 shr	 eax,15 	; Count of pages needed for map
	 call	 BSM_GROW_MAP	; Alloc and init the map
	 mov	 ax,@DERR_INSUFF_PHYS ; In case we fail
	 jc	 short BSM_INIT_NOSWAP ; Jump if it failed (note CF=1)

	 xor	 eax,eax	; A convenient zero
	 mov	 BSInUse,eax	; Make a zero
	 mov	 BSHit,eax	; Init var
	 mov	 BSMiss,eax	; ...
	 mov	 BSActive,al	; ...

; Zero out the cache area

	 mov	 edi,PBSCache	; Get offset of cache in IGROUP

	 mov	 es,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  es:IGROUP	; Tell the assembler about it

	 mov	 ecx,@BSCSize	; ECX <- cache size in bytes
	 shr	 ecx,2-0	; ECX <- cache size in dwords
	 xor	 eax,eax	; Zero to store
	 cld
     rep stos	 IGROUP:[edi].EDD ; Zero the cache

	 clc			; Mark as success
BSM_INIT_EXIT:
	 pushf			; Save CF
	 btr	 PageIOActive,0 ; Clear active status
	 popf			; Restore

	 REGREST <edi,esi,edx,ecx,ebx> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_INIT endp			; End BSM_INIT procedure
	 NPPROC  BSM_GROWSWAP -- Grow The SWAPFILE And Truncate
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Grow the swapfile and truncate

On entry:

BX	 =	 file handle
EDX	 =	 size in bytes

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise

|

	 REGSAVE <eax,ecx,edx>	; Save registers

@SWAP_TAIL equ	 8*1024 	; Size of the tail we're to write

	 sub	 edx,@SWAP_TAIL ; Make room for the tail we're to write

	 mov	 ecx,edx	; Copy size
	 shr	 ecx,16 	; Size in CX:DX
	 mov	 ax,@MOVFP2 shl 8 ; Seek from start
	 DOSCALL0		; Seek size
	 jc	 short BSM_GROWSWAP_EXIT ; Jump if error (note CF=1)

	 mov	 ecx,@SWAP_TAIL ; Write tail to force DOS to do something
	 xor	 edx,edx	; Set to start of segment (we don't actually
				; care what values are written)
	 mov	 ah,@WRITF2	; Write code
	 DOSCALL0		; Truncate the file
	 jc	 short BSM_GROWSWAP_EXIT ; Jump if error (note CF=1)

	 cmp	 ax,cx		; Did it actually work?
	 stc			; Assume not
	 jne	 short BSM_GROWSWAP_EXIT ; Jump if not (note CF=1)

	 mov	 ah,@WRITF2	; Write code
	 xor	 ecx,ecx	; Zero bytes to truncate
	 DOSCALL0		; Write
;;;;;;;; jc	 short BSM_GROWSWAP_EXIT ; Jump if error (note CF=1)
BSM_GROWSWAP_EXIT:
	 REGREST <edx,ecx,eax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_GROWSWAP endp		; End BSM_GROWSWAP procedure
	 NPPROC  BSM_OPEN -- Open The SWAPFILE
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Open the SWAPFILE

On exit:

AX	 =	 SWAPFILE handle

CF	 =	 0 if successful
	 =	 1 it not

|

	 REGSAVE <edx>		; Save register

	 mov	 ah,@OPENF2	; Open the swap file
	 mov	 al,@OPEN_LCL or @OPEN_DN or @OPEN_RW ; Local, deny none, RW
	 lea	 edx,BSPath	; DS:EDX ==> filename
	 DOSCALL0		; Open the file - handle to AX
				; Return with CF significant
	 REGREST <edx>		; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_OPEN endp			; End BSM_OPEN procedure
	 NPPROC  BSM_CREATE -- Create The SWAPFILE
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Create the SWAPFILE

On exit:

AX	 =	 file handle
CF	 =	 0 if successful
	 =	 1 it not

|

	 REGSAVE <cx,edx>	; Save registers

	 mov	 ah,@CREAF2	; Create code
	 mov	 cx,DIR_ATTR_HIDDEN ; Hidden attribute
	 lea	 edx,BSPath	; DS:EDX ==> filename
	 DOSCALL0		; Create the file, return handle in AX
				; Return with CF significant
	 REGREST <edx,cx>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_CREATE endp 		; End BSM_CREATE procedure
	 NPPROC  BSM_CLOSE -- Close The SWAPFILE
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Close the SWAPFILE

On entry:

BX	 =	 SWAPFILE handle to close

On exit:

CF	 =	 0 if successful
	 =	 1 it not

|

	 REGSAVE <ax,VMM_FLAG>	; Save registers

	 or	 VMM_FLAG,@VMM_BSCLOSE ; Mark as closing

	 mov	 ah,@CLOSF2	; Function code to close the file
	 DOSCALL0		; Request DOS services from PL0
				; Return with CF significant
	 REGREST <VMM_FLAG,ax>	; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_CLOSE endp			; End BSM_CLOSE procedure
	 NPPROC  BSM_INIT_CLIENT -- Initialize BSM For Client
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Initialize BSM for the current client.

On exit:

CF	 =	 0 if all went well
	 =	 1 otherwise with
AX	 =	 error code

|

	 REGSAVE <ebx,ecx,edx,edi,es> ; Save registers

	 test	 VMM_FLAG,@VMM_BSPRES ; Test if swapfile=xxxxx was found
	 jz	 near ptr BSM_INIT_CLIENT_EXIT ; Nothing to do (note CF=0)

	 bts	 PageIOActive,0 ; Set active and test current state
	 jnc	 short @F	; Jump if page I/O not active

	 int	 3		; Recursive page I/O == death
@@:
; Try to grow the swapfile now if:
;	(1) BSTotal < BSMax, AND
;	(2) BSInuse >= BSTotal/2

; The amount to attempt to grow by is (BSMax-BSTotal)/2

	 mov	 eax,BSTotal	; Get current page count

	 cmp	 eax,BSMax	; Are we at max?
	 jae	 short BSM_CLIENT_NOGROW ; Jump if so

	 shr	 eax,1		; Divide by 2

	 cmp	 eax,BSInUse	; Much being used?
	 ja	 short BSM_CLIENT_NOGROW ; Jump if not

	 shl	 eax,1		; Get total again
	 mov	 edi,BSMax	; Get max size
	 sub	 edi,eax	; Compute delta
	 shr	 edi,1		; Divide by 2
	 call	 BSM_GROW	; Try to grow it
BSM_CLIENT_NOGROW:
	 mov	 es,ISEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 ax,VM2PM_PSP	; Get the PSP segment
	 mov	 edi,PCURTSS	; edi <- offset of TSS in PGROUP
	 mov	 PGROUP:[edi].DPTSS_VMM_BS_PSP,ax ; Save psp

; The LastSwapPSP variable is used at client initialization time if the
; VMM needs to swap but the current client has not initialized the BSM.

	 mov	 LastSwapPSP,ax ; Save for later use

	 call	 BSM_OPEN	; Open the swapfile, return handle in AX
	 mov	 dx,@DERR_INSUFF_BACK ; In case we fail
	 jc	 short BSM_INIT_CLIENT_EXIT ; Jump if failed (note CF=1)

	 mov	 PGROUP:[edi].DPTSS_VMM_BS_handle,ax ; Save handle
	 mov	 LastSwapHandle,ax ; Used with LastSwapPSP (see above)

; Now set up the HPDA buffer save area. It is necessary to save
; the HPDA translation buffer during swap operations if the
; buffer is already in use.  To do this, we dedicate a physical
; page for each client, and save the linear address of that page
; in the TSS at DPTSS_VMM_IO_buffer.

	 mov	 PGROUP:[edi].DPTSS_VMM_IO_buffer,0 ; Init to zero
	 xor	 eax,eax	; Allocate at any linear address
	 mov	 ebx,1		; Get one page
	 mov	 ecx,mask $commit ; A committed page

	 call	 VMM_ALLOC	; Allocate
	 mov	 dx,@DERR_INSUFF_LINEAR ; In case we fail
	 jc	 short BSM_INIT_CLIENT_EXIT ; Jump out if failed (note CF=1)

	 mov	 PGROUP:[edi].DPTSS_VMM_IO_buffer,eax ; Save the address

	 call	 VMM_LOCK	; Lock it down
	 mov	 dx,@DERR_INSUFF_PHYS ; In case we fail
;;;;;;;; jc	 short BSM_INIT_CLIENT_EXIT ; Jump out if failed (note CF=1)

; Fall thru with carry significant

BSM_INIT_CLIENT_EXIT:
	 pushf			; Save CF
	 btr	 PageIOActive,0 ; Clear active status
	 popf			; Restore

	 mov	 ax,dx		; Copy error code (if any)

	 REGREST <es,edi,edx,ecx,ebx> ; Restore regs
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_INIT_CLIENT endp		; End BSM_INIT_CLIENT procedure
	 NPPROC  BSM_ALLOC -- Allocate a page of backing store
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Allocate a page in the backing store.  This is accomplished by
finding the first zero bit in the BS allocation map, setting it,
and returning the ordinal position of the bit in EAX. Returns
with carry set if no backing store free.

This call should only be made internal to the BSM. Use BSM_PUTPAGE
to put pages on the backing store.

On exit:

CF	=	0 => page allocated
	=	1 => no page available
EAX	=	Backing store address of allocated page

|

	 REGSAVE <ecx,edi,es>	; Save registers

; Set up to scan backing store allocation map

	 mov	 es,ISEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 mov	 edi,BSMap	; Start scan at bottom of map
	 mov	 eax,0FFFFFFFFh ; Value to scan for - NOT
	 mov	 ecx,BSTotal	; Total bs pages
	 shr	 ecx,5		; Dword scan - divide by 32
	 cld			; Forward
    repe scas	 es:[edi].EDD	; Do scan
	 stc			; Addume error
	 je	 short BSM_ALLOC_EXIT ; Z flag true if no zero bits (note CF=1)

	 sub	 edi,4		; Back it up a dword
	 mov	 eax,es:[edi]	; Pick up map word with zero
	 xor	 ecx,ecx	; Init bit counter
BSM_ALLOC_TEST:
	 bts	 eax,ecx	; Search for zero bit, set it
	 jnc	 short BSM_ALLOC_FOUND ; Jump if not this bit

	 inc	 ecx		; Inc bit number

	 jmp	 BSM_ALLOC_TEST ; Test next bit

BSM_ALLOC_FOUND:
	 mov	 es:[edi],eax	; Store updated bit map
	 mov	 eax,BSMap	; Compute backing store addr
	 sub	 edi,eax	; EDI <- byte offset of new allocation
	 shl	 edi,3		; Convert to bit
	 add	 edi,ecx	; Add in bit offset of zero bit found
	 mov	 eax,edi	; Return bs address in EAX
	 inc	 BSInUse	; Inc count of BS pages in use

	 clc			; flag success
BSM_ALLOC_EXIT:
	 REGREST <es,edi,ecx>	; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_ALLOC endp			; End BSM_ALLOC procedure
	 NPPROC  BSM_FREE -- Free a page from backing store
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Free a page in the backing store.

This call should only be made internal to the BSM.

On entry:

EAX	 =	 Backing store address of page to free

|

	 REGSAVE <eax, ecx, edi, es>		 ; save registers

	 mov	 ecx,eax			 ; copy backstore page number
	 and	 ecx,32-1			 ; will need only 5 low bits

	 mov	 es,ISEL_4GB3			 ; set up to address bs map
	 assume  es:AGROUP			 ; Tell the assembler about it

	 mov	 edi,BSMap	; ES:EDI <- bs map
	 shr	 eax,5		; Bit offset to dword offset

	 btr	 es:[edi+eax*4],ecx ; Clear the bit
	 jc	 short @F	; Jump if bit was set

	 int	 3				 ; freed an already free page
@@:
	 dec	 BSInUse	; Keep count of pages in use

	 REGREST <es,edi,ecx,eax> ; Free registers
	 assume  es:nothing	; Tell the assembler about it

	 ret					 ; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_FREE endp			; End BSM_FREE procedure
	 NPPROC  BSM_QUERY -- Get total and available backing store counts
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Query the amount of available backing store

On exit:

EAX	 =	 Available pages of backing store
EBX	 =	 Total pages of backing store

|

	 mov	 eax, BSTotal		 ; eax <- total size of BS file
	 mov	 ebx, eax		 ; ebx <- ...
	 sub	 eax, BSInUse		 ; available == total - in_use

	 ret				 ; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_QUERY endp			; End BSM_QUERY procedure
	 NPPROC  BSM_GROW -- Grow the backing store file
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Grow the backing store

On entry:

EDI	=	number of pages to grow it by

On exit:

CF	=	0 success
	=	1 fail

|

	 REGSAVE <eax,ebx,ecx,edx> ; Save registers

; First grow the map

	 mov	 eax,BSTotal	; EAX <- current size of BS file
	 add	 eax,edi	; Add increment pages
	 add	 eax,32*1024-1	; Round up to 32k multiple of 4KB
	 shr	 eax,15 	; Count of pages needed for map

	 mov	 ecx,BSMapTop	; LA of top of bs map
	 sub	 ecx,BSMap	; Sub LA of start of bs map
	 shr	 ecx,@BytePage	; Compute pages in map

	 sub	 eax,ecx	; EAX <- # new pages needed
	 jz	 short @F	; Jump if none

	 call	 BSM_GROW_MAP	; Grow it
	 jc	 short BSM_GROW_FAIL ; Jump if couldn't grow it
@@:

; Now grow the file

	 call	 BSM_OPEN	; Open the swapfile, return handle in AX
	 jc	 short BSM_GROW_FAIL ; Jump if error

	 mov	 bx,ax		; Copy to handle register

	 mov	 edx,BSTotal	; EDX <- current size of bs file
	 add	 edx,edi	; add increment pages

	 shl	 edx,@BytePage	; Convert size to bytes

	 call	 BSM_GROWSWAP	; Grow the swapfile to EDX bytes and truncate
	 jc	 short BSM_GROW_FAIL1 ; Jump if error

	 call	 BSM_CLOSE	; Close the SWAPFILE
	 jc	 short BSM_GROW_FAIL ; Jump if error

	 add	 BSTotal,edi	; Increment total BS page count
	 add	 BSGTotal,edi	; ...

	 jmp	 short BSM_GROW_EXIT ; exit

BSM_GROW_FAIL1:
	 call	 BSM_CLOSE	; Close the SWAPFILE
				; ignoring error return
BSM_GROW_FAIL:
	 stc
BSM_GROW_EXIT:
	 REGREST <edx,ecx,ebx,eax> ; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_GROW endp			; End BSM_GROW procedure
	NPPROC BSM_GET_CACHE_ENTRY -- Get address of BS cache entry
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|	BSM internal routine

On entry:

EBX:	Virtual address / client id

On exit:

ESI:	Pointer to cache entry

|
	REGSAVE <eax>

; The virtual address / client id is first shifted right to get the
; virtual page number.	The low @BSCIndexBits of the virtual page
; number form the index into the cache.  The size of a cache entry
; is currently eight, so it's ok to shift left by three to get a
; byte offset, which is then added to the base of the cache to yield
; the cache entry address

	mov	eax, ebx			; copy virtual address to eax
	shr	eax, @nClientBits		; get virtual page number
	and	eax, (1 shl @BSCIndexBits)-1	; mask low bits

if size BSCEntry - 8
%out Check index calculation
.err
else
	shl	eax, 3				; mul by size of BSCEntry
endif
	mov	esi, PBSCache			; esi <- lin addr of cache
	add	esi, eax			; esi <- lin addr of entry

	REGREST <eax>				; restore registers
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_GET_CACHE_ENTRY endp	; End BSM_GET_CACHE_ENTRY procedure
	 NPPROC  BSM_PUTPAGE -- Put a virtual page to the backing store
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Move a virtual page from physical memory to backing store.
Check the backing store cache of recently read pages to see
if it is still stored. If it is, then check if the page is
clean. If clean, just return the cached backing store address
for the page.  If dirty, write it out, reusing the cached backing
store address.	If the backing store address for the page is not
in the cache, allocate a new backing store page and do the write.

On entry:

EAX	=	is zero if page is clean; is non-zero if page is dirty
EBX	=	virtual address of page; low bits are client ID
EDX	=	linear address of current readable/writable buffer for page

On exit:
EAX	=	backing store address where page was stored
|
	REGSAVE <es, esi>			; save registers

	call	BSM_GET_CACHE_ENTRY		; get cache address to esi
	bt	[esi].BSCBackAddress, @BSCEntryValidBit ; entry valid?
	jnc	short BSM_PUTPAGE_MISS		; jump if entry not valid

	cmp	ebx, [esi].BSCPage		; does page match ?
	jne	short BSM_PUTPAGE_MISS	; jump if page/client don't match

	; Reach here if the cache entry for the virtual address matches.
	; Since the BSM is now responsible for maintaining the contents
	; of the virtual page, it is necessary to clear the cache entry.
	; The cache contains pages for which the BSM is no longer
	; responsible.

	btr	[esi].BSCBackAddress, @BSCEntryValidBit ; clear valid bit

	or	eax, eax		; if page is clean, just return bs
	jz	short BSM_CACHE_HIT	;   address in cache entry
					; else page is dirty
	mov	eax, [esi].BSCBackAddress ; re-use the old bs page
	jmp	short BSM_PUTPAGE_WRITE ; go do the write

BSM_CACHE_HIT:
	inc	BSHit			; keep track of backing store hits
	mov	eax, [esi].BSCBackAddress ; return address in eax
	jmp	BSM_PUTPAGE_EXIT	; done

BSM_PUTPAGE_MISS:
	inc	BSMiss			; incr miss count
	call	BSM_ALLOC		; get a backing store page
	jnc	BSM_PUTPAGE_WRITE	; if none available, try flushing
					;	the cache
	call	BSM_FLUSH_CACHE 	; flush cache

	call	BSM_ALLOC		; and try again
	jnc	short @F		; jump if allocated bs space
	int	3			; backing store overcommit!
@@:

BSM_PUTPAGE_WRITE:
	; eax is backing store page number
	; edx is linear address of page

	mov	es, ISEL_4GB3		; es <- AGROUP
	assume	es:AGROUP		; Tell the assembler about it

	call	BSM_WRITE_PAGE		; write out the page

BSM_PUTPAGE_EXIT:
	REGREST <esi, es>		; restore registers

	ret				; return to caller
	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
BSM_PUTPAGE	ENDP		; end of BSM_PUTPAGE procedure
	NPPROC BSM_GETPAGE -- Fetch a page from the backing store
	assume	ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|
	Move a page from backing store to physical memory.  Update the
	cache entry for the page.

On entry:

EAX	=	backing store address of page returned by BSM_PUTPAGE
EBX	=	virtual address of page; low bits are client ID
EDX	=	linear address of current readable/writable buffer for page
|
	REGSAVE <eax, esi, es>			; save registers

	call	BSM_GET_CACHE_ENTRY		; esi -> cache entry

	; if the entry is valid but does not match the current virtual page,
	; free the backing store page specified in the cache entry

	bt	[esi].BSCBackAddress, @BSCEntryValidBit ; is entry valid?
	jnc	short BSM_GETPAGE_READ		; jump if not valid
	cmp	[esi].BSCPage, ebx		; does page match?
	je	short BSM_GETPAGE_READ		; jump if match

	push	eax				; save for a moment
	mov	eax, [esi].BSCBackAddress	; get cached address
	btr	eax, @BSCEntryValidBit		; throw away valid bit
	call	BSM_FREE			; free the BS page

	pop	eax				; restore BS addr to get
BSM_GETPAGE_READ:
	 mov	 es, ISEL_4GB3			 ; es <- AGROUP
	 assume  es:AGROUP			 ; Tell the assembler about it

	 call	 BSM_READ_PAGE			 ; get the page

	 mov	 [esi].BSCPage, ebx		 ; set up cache entry
	 bts	 eax, @BSCEntryValidBit 	 ; set valid bit
	 mov	 [esi].BSCBackAddress, eax	 ; cache the BS address

	 REGREST <es, esi, eax> 		 ; restore regs
	 assume  es:nothing	; Tell the assembler about it

	 ret					 ; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
BSM_GETPAGE	ENDP		; end of BSM_GETPAGE procedure
	 NPPROC  BSM_PAGE_IO -- Open/Read/Write backing store file
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

On entry:

stack	 =	 word DOS command read (3f) or write (40) or close (3e)
EDX	 =	 linear address of page to read/write
EAX	 =	 backing store page number

|

io_args struc

io_ebp	 dd	 ?
io_ret	 dw	 ?
io_code  dw	 ?		; DOS function code

io_args ends

	 push	 ebp		; Set up stack
	 mov	 ebp,esp	; Address it

	 pushad 		; Save all EGP registers
	 REGSAVE <ds,es>	; Save registers

	 mov	 es,ISEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

; If we're in DOS, and that kind of debugging is enabled,
; signal an INT 01h

	 test	 DPM_FLAG,mask $DPM_DPMILOCK ; Should we check?
	 jz	 short @F	; Jump if not

	 mov	 esi,LaINDOS	; AGROUP:EAX ==> InDOS flag

	 cmp	 AGROUP:[esi].LO,0 ; Are we inside DOS?
	 je	 short @F	; Jump if not

	 int	 03h		; Call our debugger
@@:
	 bts	 PageIOActive,0 ; Set active and test current state
	 jnc	 short @F	; Jump if page I/O not active

	 int	 3		; Recursive page I/O == death
@@:
	 call	 BSM_SAVE_HPDA_BUF ; Save HPDA buffer if in use

	 mov	 esi,eax	; ESI <- backing store address

	 push	 PCURTSS	; Use HPDA stack in here
	 call	 DPMIFN_GETPSP	; Get PSP segment into BX

	 push	 bx		; BX <- current PSP

	 xor	 ax,ax		; Make a zero
	 mov	 edi,PCURTSS	; edi <- offset in PGROUP of current TSS

	 mov	 cx,PGROUP:[edi].DPTSS_VMM_BS_PSP ; Get swap PSP for client

	 or	 cx,cx		; Is client init'ed
	 jnz	 short @F	; Jump if yes

	 mov	 cx, LastSwapPSP ; Use last init'ed
	 mov	 PGROUP:[edi].DPTSS_VMM_BS_PSP,cx ; ...
@@:
	 cmp	 bx,PGROUP:[edi].DPTSS_VMM_BS_PSP ; If PSP is current
	 je	 short @F	; Then don't bother setting it

	 mov	 bx,PGROUP:[edi].DPTSS_VMM_BS_PSP ; Get the actual PSP

	 push	 PCURTSS	; Use HPDA stack in here
	 call	 DPMIFN_SETPSP	; Set PSP segment to BX
@@:
	 cmp	 [ebp].io_code.HI,@CLOSF2 ; If it's a close operation
	 je	 near ptr BSM_IO_DOIT ; Skip to the call

	 xchg	 edx,esi	; EDX <- bs address, ESI <- buffer

; The backing store address is in units of pages, seek addresses
; are in bytes.

	 shl	 edx,@BytePage	; Convert to bytes
	 mov	 ecx,edx	; Seek to page address
	 shr	 ecx,16 	; CX <- high half of seek addr
	 mov	 bx,PGROUP:[edi].DPTSS_VMM_BS_handle ; BX <- swapfile handle

	 or	 bx,bx		; Is client init'ed?
	 jnz	 short @F	; Jump if so

	 mov	 bx,LastSwapHandle ; Use previous handle
	 mov	 PGROUP:[edi].DPTSS_VMM_BS_handle,bx ; Use this handle for now
@@:
	 mov	 ah,@MOVFP2	; Load function code (seek)
	 DOSCALL0		; Seek

; Now set up the DTE_SWAPBUF descriptor to be based at the
; address of the page we are swapping

	 mov	 edx,esi	; Buffer address to EDX to save in GDT

	 mov	 DESC_TAB.DTE_SWAPBUF.DESC_BASE01,dx ; Set low bytes of base
	 shr	 edx,16 		 ; Shift high base bytes to dx
	 mov	 DESC_TAB.DTE_SWAPBUF.DESC_BASE2,dl  ; Store byte 2 of base
	 mov	 DESC_TAB.DTE_SWAPBUF.DESC_BASE3,dh  ; Store byte 3 of base
;;;;;;;; mov	 DESC_TAB.DTE_SWAPBUF.DESC_SEGLM0,@PageSize-1 ; Set segment limit
;;;;;;;; mov	 DESC_TAB.DTE_SWAPBUF.DESC_ACCESS,CPL0_DATA or CPL0 ; Read/write data segment
;;;;;;;; mov	 DESC_TAB.DTE_SWAPBUF.DESC_SEGLM1,0  ; No additional attributes needed

	 mov	 ax,DTE_SWAPBUF ; point ds|dx at page to move
	 mov	 ds,ax		; ds <- swap buffer selector
	 assume  ds:nothing	; Tell the assembler about it

	 xor	 edx,edx	; Offset is zero
	 mov	 ecx,@PageSize	; Number of bytes to transfer

COMMENT|

Because some DPMI clients don't lock their HW interrupt handlers, we
must put on more body armor.  In particular, if the client gets a page
fault inside (say) INT 08h (possibly through INT 1Ch) or 09h, and no
EOI has been sent to the PIC, the following DOS call generates disk
activity on a possibly interrupt-driven hard disk.  Because IRQ0 and
IRQ1 are higher priority interrupts than the HD interrupt, the latter
is shut out.  The workaround is for us to send a specific EOI to the
master PIC for IRQ0 and IRQ1.  We don't extend that favor to any other
IRQs as we can't be sure the HD is interrupt driven and we don't want
to risk causing any problems.  Sending a specific EOI for IRQ0 and
IRQ1 seems reasonably harmless.

|

	 test	 I31_FLAG,mask $I31_XMEI ; Izit one to worry about?
	 jz	 short BSM_IO_DOIT ; Jump if not

	 mov	 al,@EOI0	; Get specific EOI for IRQ0
	 out	 @ICR,al	; Tell the master PIC about it
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay
	 jmp	 short $+2	; I/O delay

	 mov	 al,@EOI1	; Get specific EOI for IRQ1
	 out	 @ICR,al	; Tell the master PIC about it
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
;;;;;;;; jmp	 short $+2	; I/O delay
BSM_IO_DOIT:
	 mov	 ax,[ebp].io_code ; Pick up read/write op argument
	 mov	 bx,PGROUP:[edi].DPTSS_VMM_BS_handle ; Pick up swap file handle
	 DOSCALL0		; Do the I/O
	 jnc	 short @F	; Shouldn't fail

	 cmp	 [ebp].io_code.HI,@CLOSF2 ; Allow close to fail
	 je	 short @F	; Jump if closing

	 int	 3		; But panic otherwise
@@:
	 pop	 bx		; restore psp used

	 cmp	 bx,PGROUP:[edi].DPTSS_VMM_BS_PSP ; Was it current?
	 je	 short @F	; Jump if so

	 push	 PCURTSS	; Use HPDA stack in here
	 call	 DPMIFN_SETPSP	; Set PSP segment to BX
@@:
	 mov	 ds,ISEL_DSIG3	; Get IGROUP data selector at PL3
	 assume  ds:IGROUP	; Tell the assembler about it

	 call	 BSM_RESTORE_HPDA_BUF ; Restore the HPDA buffer

	 btr	 PageIOActive,0 ; Clear active status

	 REGREST <es,ds>	; Restore registers
	 assume  ds:nothing,es:nothing ; Tell the assembler about it
	 popad			; Restore all EGP registers

	 pop	 ebp		; Restore

	 ret	 2		; Return popping arg

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_PAGE_IO endp		; End BSM_PAGE_IO procedure
	 NPPROC  BSM_READ_PAGE -- Read a page from backing store system
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Fetch the contents of a virtual page from backing store.

On entry:

EAX	 =	 backing store page number
EDX	 =	 linear address of buffer to receive page contents

|

	 push	 @READF2 shl 8	; DOS function code arg
	 call	 BSM_PAGE_IO	; Call generic i/o routine

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_READ_PAGE endp		; End BSM_READ_PAGE procedure
	 NPPROC  BSM_WRITE_PAGE -- Write a page to backing store
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Write a page to backing store

On entry:

EAX	 =	 backing store page number
EDX	 =	 linear addresss of buffer to receive page contents

|

	 push	 @WRITF2 shl 8	; DOS function code arg
	 call	 BSM_PAGE_IO	; Call generic i/o routine

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_WRITE_PAGE endp		; End BSM_WRITE_PAGE procedure
	 NPPROC  BSM_FLUSH_CACHE -- Flush the backing store cache
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Flush all the pages in the backing store cache to free up
backing store pages.

|

	 REGSAVE <eax,ecx,esi>	; Save registers

	 mov	 esi,PBSCache	; ESI <- LA of cache
	 mov	 ecx,@BSCLen	; Get # cache entries
BSM_FLUSH_NEXT:
	 mov	 eax,[esi].BSCBackAddress ; EAX <- bs address of page

	 btr	 eax,@BSCEntryValidBit ; Clear the valid bit
	 jnc	 short BSM_FLUSH_LOOP ; Jump if wasn't valid anyway

	 mov	 [esi].BSCBackAddress,0 ; Zero out this entry
	 call	 BSM_FREE	; Free the page
BSM_FLUSH_LOOP:
	 add	 esi,size BSCEntry ; Advance to next entry

	 loopd	 BSM_FLUSH_NEXT ; Go do it

	 REGREST <esi,ecx,eax>	; Restore regs

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_FLUSH_CACHE ENDP		; end of BSM_FLUSH_CACHE procedure
	NPPROC BSM_INVALIDATE_CACHE_ENTRY -- invalidate a BS cache entry
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|
	Invalidate the BS cache entry for a particular virtual address.
On entry:
EBX	=	virtual address for which cache should be invalidated
|
	REGSAVE <esi, eax>		; save registers

	test	VMM_FLAG,@VMM_BSPRES	; is backing store file in use?
	jz	short BSM_INVAL_EXIT	; jump if not

	call	BSM_GET_CACHE_ENTRY	; esi <- addr of entry in question

	mov	eax, [esi].BSCBackAddress ; load BS addr to eax
	btr	eax, @BSCEntryValidBit	; clear valid bit
	jnc	short @F		; jump if was already clear
	call	BSM_FREE		; else free the BS page
@@:
	mov	[esi].BSCBackAddress, 0 ; clear cache entry address
BSM_INVAL_EXIT:
	 REGREST <eax, esi>		 ; restore registers

	 ret				 ; return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing
BSM_INVALIDATE_CACHE_ENTRY	ENDP	; end of BSM_INVALIDATE_CACHE_ENTRY procedure
	 NPPROC  BSM_GROW_MAP -- Grow the Backing Store Map
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Grow the backing store map

On entry:

EAX	 =	 number of pages to grow by

On exit:

CF	 =	 0 ==> success
		 1 ==> failed

|

	 REGSAVE <eax,ebx,ecx>	; Save registers

	 mov	 ecx,eax	; Count with ECX
	 mov	 eax,BSMapTop	; EAX <- lin addr of top of map
	 jecxz	 BSM_GROW_MAP_DONE ; Jump if no more to grow
BSM_GROW_MAP_NEXT:
	 xor	 ebx,ebx	; Flags: non-swappable page / fail ok
	 call	 VMM_GET_PHYSICAL_PAGE ; Get a physical page

	 cmp	 ebx,-1 	; Did we get one?
	 stc			; Assume not
	 je	 short BSM_GROW_MAP_EXIT ; Jump if not (note CF=1)

	 call	 LSM_MAP_PAGE	; Map it at BSMapTop
	 jc	 short BSM_GROW_MAP_EXIT ; Jump if mapping failed (note CF=1)

	 call	 VMM_ZERO_PAGE	; Zero it out
BSM_GROW_MAP_ADVANCE:
	 add	 BSMapTop,@PageSize ; Bump next lin addr for map

	 loopd	 BSM_GROW_MAP_NEXT ; Get next if more
BSM_GROW_MAP_DONE:
	 clc			; Flag success
BSM_GROW_MAP_EXIT:
	 REGREST <ecx,ebx,eax>	; Restore registers

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_GROW_MAP endp		; End BSM_GROW_MAP procedure
	 NPPROC  BSM_TERMINATE_CLIENT -- Shutdown BSM for current client
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Close up the swapfile for the current client

|

	 test	 VMM_FLAG,@VMM_BSPRES ; Test if swapfile present
	 jz	 short @F	; Jump out if not

	 push	 eax		; Save for a moment
	 mov	 eax,PCURTSS	; Get offset in PGROUP of current TSS
	 test	 PGROUP:[eax].DPTSS_FLAG,mask $DPTSS_BSMINIT ; Izit initialized?
	 pop	 eax		; Restore
	 jz	 short @F	; Jump if not

	 or	 VMM_FLAG,@VMM_BSCLOSE ; Mark as closing

	 push	 @CLOSF2 shl 8	; DOS function code (close)
	 call	 BSM_PAGE_IO	; Close the swapfile

	 and	 VMM_FLAG,not @VMM_BSCLOSE ; Mark as no longer closing
@@:
	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_TERMINATE_CLIENT endp	; End BSM_TERMINATE_CLIENT procedure
	 NPPROC  BSM_SHUTDOWN -- Shutdown BSM
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

If we have a temporary swapfile, delete it, and rewrite it as just a
header.

|

	 REGSAVE <eax,ebx,ecx,edx> ; Save registers

	 test	 VMM_FLAG,@VMM_BSPRES ; Test if swapfile present
	 jz	 short BSM_SHUT_EXIT ; Jump out if not

	 test	 VMM_FLAG,@VMM_BSTEMP ; Test if swapfile is temporary
	 jz	 short BSM_SHUT_EXIT ; Jump out if not

	 lea	 edx,BSPath	; DS:eDX ==> file name
	 mov	 ah,@DELEF2	; Delete code
	 DOSCALL0		; Delete it
	 jc	 short BSM_SHUT_EXIT ; Quit if error

	 call	 BSM_CREATE	; Create the swapfile, return handle in AX
	 jc	 short BSM_SHUT_EXIT ; Quit if error

	 mov	 bx,ax		; Copy to handle register

	 mov	 ecx,size BSFHDR ; # bytes to write
	 lea	 edx,BSFHDR	; DS:eDX ==> buffer to write out
	 mov	 ah,@WRITF2	; Write code
	 DOSCALL0		; Write signature
				; ignoring error return
	 call	 BSM_CLOSE	; Close the SWAPFILE
				; ignoring error return
BSM_SHUT_EXIT:
	 REGREST <edx,ecx,ebx,eax> ; Restore

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_SHUTDOWN endp		; End BSM_SHUTDOWN procedure
	 NPPROC  BSM_SAVE_HPDA_BUF -- Save HPDA buffer
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Save the HPDA buffer if it is in use. This is necessary because we may
get a page fault while transferring data in the HDPA buffer (as in a
disk read) to client memory.  The resulting disk I/O requires use of the
HPDA buffer as well, so we must save the HDPA buffer around disk I/O
operations to the swapfile.

|

	 REGSAVE <eax,ebx,ecx,esi,edi,es> ; Save registers

	 mov	 es,ISEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 xor	 ax,ax		; Get *current* client info
	 mov	 ebx,PCURTSS	; EBX <- offset of current TSS in PGROUP

; Test if already saved

	 test	 PGROUP:[ebx].DPTSS_VMM_Flags,mask $vciBufferSaved ; Izit saved?
	 jz	 short @F	; Jump if not

	 int	 3		; Nested save - how did that happen?
@@:
	 mov	 ax,HPDABUF_SIZ

	 cmp	 PGROUP:[ebx].DPTSS_VMBUFSIZ,ax ; Is any of it in use?
	 je	 near ptr BSM_SAVE_NOSAVE ; Jump if not

	 mov	 ax,PGROUP:[ebx].DPTSS_VMBUFSIZ ; Save the current size
	 mov	 PGROUP:[ebx].DPTSS_VMM_Saved_size,ax
	 mov	 ax,PGROUP:[ebx].DPTSS_VMBUFOFF ; Save current offset
	 mov	 PGROUP:[ebx].DPTSS_VMM_Saved_offset,ax

	 mov	 esi,PGROUP:[ebx].DPTSS_LaHPDA	 ; Get linear address of HPDA
	 add	 esi,PGROUP:[ebx].DPTSS_VMBUFOFF.EDD ; current buffer start
	 add	 esi,PGROUP:[ebx].DPTSS_VMBUFSIZ.EDD ; esi <- end of buffer
	 movzx	 eax,HPDABUF_SIZ ; EAX <- total size
	 sub	 esi,eax	; ESI <- start of HPDA buffer

	 mov	 cx,PGROUP:[ebx].DPTSS_VMBUFSIZ ; Adjust buffer to full size
	 add	 PGROUP:[ebx].DPTSS_VMBUFOFF,cx ; End of buffer
	 sub	 PGROUP:[ebx].DPTSS_VMBUFOFF,ax ; Start of buffer
	 mov	 PGROUP:[ebx].DPTSS_VMBUFSIZ,ax ; Reset to full size
						; now save the buffer
	 movzx	 ecx,ax 	; ECX <- full size bytes

	 cmp	 ecx,@PageSize	; Don't need to save > 1 page
	 jb	 short @F	; Jump if less than a page

	 mov	 ecx,@PageSize	; Save just a page
@@:
	 shr	 ecx,2-0	; ECX <- full size dwords
	 mov	 edi,PGROUP:[ebx].DPTSS_VMM_IO_buffer ; EDI <- addr of buf
	 cld			; Forward
S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD> ; Copy

	 or	 PGROUP:[ebx].DPTSS_VMM_Flags, mask $vciBufferSaved ; flag it
BSM_SAVE_NOSAVE:
	 REGREST <es,edi,esi,ecx,ebx,eax> ; Restore regs
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_SAVE_HPDA_BUF endp		; End BSM_SAVE_HPDA_BUF procedure
	 NPPROC  BSM_RESTORE_HPDA_BUF -- Restore HPDA buffer
	 assume  ds:IGROUP,es:nothing,fs:nothing,gs:nothing,ss:PGROUP
COMMENT|

Restore the HPDA buffer if it was saved

|

	 REGSAVE <eax,ebx,ecx,esi,edi,es> ; Save registers

	 mov	 es,ISEL_4GB3	; Get AGROUP data selector at PL3
	 assume  es:AGROUP	; Tell the assembler about it

	 xor	 ax,ax		; Get *current* client info
	 mov	 ebx,PCURTSS	; EBX <- offset in PGROUP of current TSS

; Test if saved

	 test	 PGROUP:[ebx].DPTSS_VMM_Flags,mask $vciBufferSaved ; Izit saved?
	 jz	 short BSM_RESTORE_EXIT ; Jump if not

	 mov	 edi,PGROUP:[ebx].DPTSS_LaHPDA ; Get linear address of HPDA
	 add	 edi,PGROUP:[ebx].DPTSS_VMBUFOFF.EDD ; Current buffer start

	 mov	 esi,PGROUP:[ebx].DPTSS_VMM_IO_buffer ; ESI <- addr of buf
	 movzx	 ecx,HPDABUF_SIZ ; Full buffer size in bytes

	 cmp	 ecx,@PageSize	; Don't need to save > 1 page
	 jb	 short @F	; Jump if a page or less

	 mov	 ecx,@PageSize	; Just move a page
@@:
	 shr	 ecx,2		; Full buffer size in dwords
	 cld			; restore the buffer
S32  rep movs	 <AGROUP:[edi].EDD,AGROUP:[esi].EDD>

	 mov	 ax,PGROUP:[ebx].DPTSS_VMM_Saved_size
	 mov	 PGROUP:[ebx].DPTSS_VMBUFSIZ,ax ; Restore size value

	 mov	 ax,PGROUP:[ebx].DPTSS_VMM_Saved_offset
	 mov	 PGROUP:[ebx].DPTSS_VMBUFOFF,ax ; Restore offset value

; Mark as no longer saved

	 and	 PGROUP:[ebx].DPTSS_VMM_Flags,not (mask $vciBufferSaved) ; Mark it
BSM_RESTORE_EXIT:
	 REGREST <es,edi,esi,ecx,ebx,eax> ; Restore registers
	 assume  es:nothing	; Tell the assembler about it

	 ret			; Return to caller

	 assume  ds:nothing,es:nothing,fs:nothing,gs:nothing,ss:nothing

BSM_RESTORE_HPDA_BUF endp	; End BSM_RESTORE_HPDA_BUF procedure
	 align	 4		; Ensure dword alignment

ICODE	 ends			; End ICODE segment
endif				; IF @OEM_DPMI

	 MEND			; End QMAX_BSM module
