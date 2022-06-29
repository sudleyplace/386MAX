% ifidni <OEM>,<DET>		; If building Retail RAMDEMO
  PNAME equ <'RAMdemo'>         ; Set name
  PUNAME equ <'RAMDEMO'>        ; Set uper case name
  PDIFF equ <' '>               ; Difference in name size (from 8)
  PDIFF_2a equ <' '>            ; Half the difference+1
  PDIFF_2b equ <' '>            ; Half the difference (second half)+1
  @RAMEXAM equ 1		; Setup an equate for quick checking
  @RAMDEMO equ 1		; ...
endif

% ifidni <OEM>,<DEB>		; If building Beta RAMDEMO
  PNAME equ <'RAMdemo'>         ; Set name
  PUNAME equ <'RAMDEMO'>        ; Set uper case name
  PDIFF equ <' '>               ; Difference in name size (from 8)
  PDIFF_2a equ <' '>            ; Half the difference+1
  PDIFF_2b equ <' '>            ; Half the difference (second half)+1
  @RAMEXAM equ 1		; Setup an equate for quick checking
  @RAMDEMO equ 1		; ...
  @BETA equ 1			; Defined if Beta Version is build
endif

% ifidni <OEM>,<RET>		; If building Retail RAMEXAM
  PNAME equ <'RAMexam'>         ; Set name
  PUNAME equ <'RAMEXAM'>        ; Set uper case name
  PDIFF equ <' '>               ; Difference in name size (from 8)
  PDIFF_2a equ <' '>            ; Half the difference+1
  PDIFF_2b equ <' '>            ; Half the difference (second half)+1
  @RAMEXAM equ 1		; Setup an equate for quick checking
endif

% ifidni <OEM>,<MIC>		; If building Retail RAMEXAM for Micron
  PNAME equ <'RAMexam'>         ; Set name
  PUNAME equ <'RAMEXAM'>        ; Set uper case name
  PDIFF equ <' '>               ; Difference in name size (from 8)
  PDIFF_2a equ <' '>            ; Half the difference+1
  PDIFF_2b equ <' '>            ; Half the difference (second half)+1
  @RAMEXAM equ 1		; Setup an equate for quick checking
endif

% ifidni <OEM>,<TAN>		; If building Retail RAMEXAM for Tandon
  PNAME equ <'RAMexam'>         ; Set name
  PUNAME equ <'RAMEXAM'>        ; Set uper case name
  PDIFF equ <' '>               ; Difference in name size (from 8)
  PDIFF_2a equ <' '>            ; Half the difference+1
  PDIFF_2b equ <' '>            ; Half the difference (second half)+1
  @RAMEXAM equ 1		; Setup an equate for quick checking
endif

% ifidni <OEM>,<REB>		; If building Beta RAMEXAM
  PNAME equ <'RAMexam'>         ; Set name
  PUNAME equ <'RAMEXAM'>        ; Set uper case name
  PDIFF equ <' '>               ; Difference in name size (from 8)
  PDIFF_2a equ <' '>            ; Half the difference+1
  PDIFF_2b equ <' '>            ; Half the difference (second half)+1
  @RAMEXAM equ 1		; Setup an equate for quick checking
  @BETA equ 1			; Defined if Beta Version is build
endif

ifndef PNAME			; If not building above
  PNAME equ <'QMT'>             ; Set name
  PUNAME equ <'QMT'>            ; Set upper name
  PDIFF equ <'     '>           ; Difference in name size (from 8)
  PDIFF_2a equ <'   '>          ; Half the difference+1
  PDIFF_2b equ <'    '>         ; Half the difference (second half)+1
  @QMT equ 1			; Setup an equate for quick checking
endif

% ifidni <OEM>,<QMB>		; If building Beta QMT
  @BETA equ 1			; Defined if Beta Version is build
endif
