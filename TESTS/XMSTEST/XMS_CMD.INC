;' $Header:   P:/PVCS/MISC/XMSTEST/XMS_CMD.INV   1.1   06 Aug 1992 13:18:14   HENRY  $

; Equates for CMD_FLAG

@CMD_A20 equ	 80h		; Test A20
@CMD_HMA equ	 40h		; Test HMA
@CMD_XMB equ	 20h		; Test XMBs
@CMD_MOV equ	 10h		; Test moves
@CMD_UMB equ	 08h		; Test UMBs
@CMD_MOD equ	 04h		; Test reallocation
@CMD_LCK equ	 02h		; Test locking
@CMD_EDG equ	 01h		; Test edge conditions

@CMD_ALL equ	 @CMD_A20 or @CMD_HMA or @CMD_XMB or @CMD_MOV or @CMD_UMB or @CMD_MOD or @CMD_LCK or @CMD_EDG

