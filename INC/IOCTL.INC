;' $Header:   P:/PVCS/MAX/INC/IOCTL.INV   1.0   05 Sep 1995 13:27:06   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; IOCTL.INC
;
; Equates for IOCTL word
;

.xcref @IOCTL_CTRL,@IOCTL_NET,@IOCTL_DEV
.xcref @IOCTL_EOF,@IOCTL_RAW,@IOCTL_CLK,@IOCTL_NUL
.xcref @IOCTL_COT,@IOCTL_CIN
;		 8000h		  (Reserved)
@IOCTL_CTRL equ  4000h		; Can process control strings
;		 2000h		  (Reserved)
@IOCTL_NET  equ  1000h		; 1=is a network device/file
;		 0800h		  (Reserved)
;		 0400h		  (Reserved)
;		 0200h		  (Reserved)
;		 0100h		  (Reserved)
@IOCTL_DEV  equ  0080h		; 1=is a device, 0=is a file
@IOCTL_EOF  equ  0040h		; 1=EOF on input, 0=not
@IOCTL_RAW  equ  0020h		; 1=operating in binary mode
;		 0010h		  (Reserved)
@IOCTL_CLK  equ  0008h		; 1=is the clock	  device
@IOCTL_NUL  equ  0004h		; 1=is the null 	  device
@IOCTL_COT  equ  0002h		; 1=is the console output device
@IOCTL_CIN  equ  0001h		; 1=is the console input  device

