;' $Header:   P:/PVCS/MAX/INC/VDISK.INV   1.0   05 Sep 1995 13:27:14   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; VDISK.INC
;
; Structure for VDISK header in extended memory
;

VDISK_STR struc

	 db	 0,0,0		; 3-byte jump to boot code (not bootable)
VDISK_VEND db	 'VDISK3.3'     ; 8-byte vendor identification

; Boot record copy of BIOS parameter block

VDISK_BPB dw	 ?		; Number of bytes per disk sector
	 db	 ?		; Sectors per allocation unit
	 dw	 ?		; Number of reserved sectors (for boot record)
	 db	 ?		; Number of File Allocation Table (FAT) copies
	 dw	 ?		; Number of root directory entries
	 dw	 ?		; Total number of sectors
	 db	 ?		; Media descriptor byte
	 dw	 ?		; Number of sectors occupied by a single FAT
				; End of boot record BIOS Parameter block

;The following three words mean nothing to VDISK, they are placed here
;to conform to the DOS standard for boot records.

	 dw	 8		; Sectors per track
	 dw	 1		; Number of heads
	 dw	 0		; Number of hidden sectors

; The following word is the 16-bit kilobyte address of the first byte in
; extended memory that is not occupied by a VDISK buffer
; It is placed into this location so that other users of extended memory
; may find where all the VDISKs end.

; This field may be accessed by moving the boot record of the First extended
; memory VDISK from absolute location 10 0000H.  Before assuming that the
; value below is valid, the vendor ID (constant VDISK) should be verified
; to make sure that SOME VDISK has been installed.

; For example, if two VDISKs are installed, one 320KB and one 64KB, the
; address calculations are as follows:

; Extended memory start address  = 100000H (1024KB)
; Start addr of 1st VDISK buffer = 100000H (1024KB)
; Length of 1st VDISK buffer	 = 050000H ( 320KB)
; End addr of 1st VDISK buffer	 = 14FFFFH
; Start addr of 2nd VDISK buffer = 150000H (1344KB)
; Length of 2nd VDISK buffer	 = 010000H (  64KB)
; End addr of 2nd VDISK buffer	 = 15FFFFH
; First byte after all VDISKs	 = 160000H (1408KB)
; Divide by 1024		 =   0580H (1408D)

; Content of BOOT_EM		 =   0580H

VDISK_NEXT dw	 1024		; KB addr of first free byte of extended memory

VDISK_STR ends

