;' $Header:   P:/PVCS/MAX/INC/DEVMAC.INV   1.0   05 Sep 1995 13:26:48   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	GNU General Public License version 3.
;
; DEVMAC.INC
;
; Device name macro
;


DEVMAC	 macro	 NAME

@DEVLEN  sizestr NAME
@DEVNAME substr  NAME,2,@DEVLEN-2

	 rept	 10-@DEVLEN
@DEVNAME catstr  @DEVNAME,<$>	; Append a dollar sign
	 endm			; RPT

; Because eight-character device names are confused with file names,
; we must truncate the last character and insert a $.

@DEVNAME substr  @DEVNAME,1,7	; Drop off the last character
@DEVNAME catstr  @DEVNAME,<$>	; Append a dollar sign

@DEVNAME catstr  <">,@DEVNAME   ; Prefix a quote mark
@DEVNAME catstr  @DEVNAME,<">   ; Append a quote mark

	 endm			; DEVMAC

