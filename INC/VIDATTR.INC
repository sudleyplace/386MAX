;' $Header:   P:/PVCS/MAX/INC/VIDATTR.INV   1.0   05 Sep 1995 13:27:08   HENRY  $
;
; (C) Copyright 1987-93 Qualitas, Inc.	GNU General Public License version 3.
;
; VIDATTR.INC
;
; Video attribute equates
;

; Monochrome screen attributes

@ATMblack	  equ	0
@ATMund 	  equ	1
@ATMnorm	  equ	7
@ATMundhigh	  equ	9
@ATMhigh	  equ  15
@ATMrev 	  equ 112
@ATMrevhigh	  equ 120
@ATMundblink	  equ 129
@ATMblink	  equ 135
@ATMundhighblink  equ 137
@ATMhighblink	  equ 143
@ATMrevblink	  equ 240
@ATMrevhighblink  equ 248

; B/W screen attributes

@ATBWblack	  equ	0
@ATBWnorm	  equ	7
@ATBWhigh	  equ  15
@ATBWrev	  equ 112
@ATBWrevhigh	  equ 120
@ATBWblink	  equ 135
@ATBWhighblink	  equ 143
@ATBWrevblink	  equ 240
@ATBWrevhighblink equ 248

; Color screen attributes

@ATChigh	  equ	8
@ATCblink	  equ 128

; Color screen foreground attributes

@ATCFblack	  equ	0
@ATCFblue	  equ	1	 ; Attribute =		foreground
@ATCFgreen	  equ	2	 ;	      + (   8 x intense    )
@ATCFcyan	  equ	3	 ;	      + (  16 x background )
@ATCFred	  equ	4	 ;	      + ( 128 x blinking   )
@ATCFmagenta	  equ	5
@ATCFyellow	  equ	6
@ATCFwhite	  equ	7

; Color screen background attributes

@ATCBblack	  equ	0
@ATCBblue	  equ  16
@ATCBgreen	  equ  32
@ATCBcyan	  equ  48
@ATCBred	  equ  64
@ATCBmagenta	  equ  80
@ATCByellow	  equ  96
@ATCBwhite	  equ 112

; Color foreground colors merged with intensity bit

@ATCFFblack	  equ	@ATCFblack
@ATCFFblue	  equ	@ATCFblue
@ATCFFgreen	  equ	@ATCFgreen
@ATCFFcyan	  equ	@ATCFcyan
@ATCFFred	  equ	@ATCFred
@ATCFFmagenta	  equ	@ATCFmagenta
@ATCFFbrown	  equ	@ATCFyellow
@ATCFFltgray	  equ	@ATCFwhite
@ATCFFdkgray	  equ	@ATChigh  + @ATCFFblack
@ATCFFltblue	  equ	@ATChigh  + @ATCFFblue
@ATCFFltgreen	  equ	@ATChigh  + @ATCFFgreen
@ATCFFltcyan	  equ	@ATChigh  + @ATCFFcyan
@ATCFFltred	  equ	@ATChigh  + @ATCFFred
@ATCFFltmagenta   equ	@ATChigh  + @ATCFFmagenta
@ATCFFyellow	  equ	@ATChigh  + @ATCFFbrown
@ATCFFwhite	  equ	@ATChigh  + @ATCFFltgray

; Color background colors merged with blinking bit
; (use INT 10h, AX=1003h, BL=00h to enable, BL=01h to disable)

@ATCBBblack	  equ	@ATCBblack
@ATCBBblue	  equ	@ATCBblue
@ATCBBgreen	  equ	@ATCBgreen
@ATCBBcyan	  equ	@ATCBcyan
@ATCBBred	  equ	@ATCBred
@ATCBBmagenta	  equ	@ATCBmagenta
@ATCBBbrown	  equ	@ATCByellow
@ATCBBltgray	  equ	@ATCBwhite
@ATCBBdkgray	  equ	@ATCblink + @ATCBBblack
@ATCBBltblue	  equ	@ATCblink + @ATCBBblue
@ATCBBltgreen	  equ	@ATCblink + @ATCBBgreen
@ATCBBltcyan	  equ	@ATCblink + @ATCBBcyan
@ATCBBltred	  equ	@ATCblink + @ATCBBred
@ATCBBltmagenta   equ	@ATCblink + @ATCBBmagenta
@ATCBByellow	  equ	@ATCblink + @ATCBBbrown
@ATCBBwhite	  equ	@ATCblink + @ATCBBltgray

