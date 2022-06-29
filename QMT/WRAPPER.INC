;' $Header:   P:/PVCS/MAX/QMT/WRAPPER.INV   1.0   05 Sep 1995 16:56:02   HENRY  $
SIGNAL_CHAR equ ESCAPE
; SIGNAL_CHAR is used to signal that the following character is a command char


; SYMNAME is used to define the symbols in the following format
; SYMNAME SYMBOL,COL_SIZE,ROW_SIZE
SYMNAME  macro symbol, colsym, rowsym
 db	 SIGNAL_CHAR,'S','&symbol',0,'&colsym',0,'&rowsym',0
endm	 SYMNAME

; ONESYMNAME is used to define the symbols in the following format
; ONESYMNAME SYMBOL
ONESYMNAME  macro symbol
 db	 SIGNAL_CHAR,'O','&symbol',0
endm	 ONESYMNAME

; INDENT is followed by a byte representing the new indent value
; INDENT 20
INDENT	macro size
 db SIGNAL_CHAR,'I',size
endm	INDENT

; COL_WIDTH @NO_COLS		; Example
COL_WIDTH macro width
  db	 SIGNAL_CHAR,'W',width
endm	 COL_WIDTH

; CENTER centers text on the line by itself
; CENTER 'Screen Overview'
CENTER macro text
ifnb <text>
  db SIGNAL_CHAR,'C',text,00h
else
  db SIGNAL_CHAR,'C',00h
endif
endm   CENTER

; RAWOUT puts text into output file sans any dbs
; RAWOUT <ENDS>
RAWOUT macro text
  db SIGNAL_CHAR,'R',text,00h
endm   RAWOUT

; COLOR is followed by a byte indicating the number of the new color.
;	Use COLOR 0 early in the file to tell WRAPPER we're using colors.
; COLOR clr
COLOR macro clr
  db SIGNAL_CHAR,'L',clr
endm   COLOR

; EOT - End of Text macro
EOT macro
 db SIGNAL_CHAR,'Z'
endm EOT
