
; These equates control how 386DISK is assembled

@OEM_SUBT_386	 equ 1
@OEM_HARPO	 equ 0	; 1 = Supports subsegment table

	 include QMAX_OEM.ALL

@OEM_SYS	 equ @OEMSYS_RET
@OEM_IOCTL	 equ <'386MAX'>         ; IOCTL name for 386MAX
@OEM_MAX	 equ <'386MAX'>         ; File name for 386MAX
@OEM_DISK	 equ <'386DISK'>        ; File name for 386DISK
@OEM_PTEXT	 equ <'Qualitas MAX'>   ; Text name for Qualitas MAX

