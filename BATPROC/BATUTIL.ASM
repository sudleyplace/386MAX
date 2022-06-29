	  title     BATUTIL - Assembler utilities for BATPROC

	  ;
	  page	    ,132		;make wide listing
	  ;
	  comment   }

	  (C) Copyright 1990 Rex Conn
	  All Rights Reserved

	  These BATPROC support routines provide fast screen I/O and other
	  functions for BATPROC.

	  } end description
	  ;
	  ;
	  ; Includes
	  ;
	  include   macros.asm		 ;general macros


	  .model    small		;small stuff

	  .data 			;start data segment

	  extrn     __osmajor:byte	; DOS major version number

XMSControl dd	    ?			; address of XMS driver
emm_name  db	    'EMMXXXX0'          ;name of EMS driver
column	  dw	    ?			;current display column
lmargin   dw	    ?			;display left margin
rmargin   dw	    ?			;display right margin
status	  dw	    ?			;address of 6845 status register
control   dw        ?                   ;dummy word for use in NDP tests

	  ;
	  .code 			;start code segment
	  ;

	  ;
	  ; BIOS_KEY - get key from the BIOS
	  ;
	  ; On exit:
	  ;	    AX, BX, DX, destroyed
	  ;	    All other registers unchanged, interrupts on
	  ;
	  entry     _bios_key,noframe  ;set up entry point

	  xor	    ax,ax
	  int	    16h
	  mov	    bh,ah
	  xor	    ah,ah
	  or	    al,al
	  jnz	    not_special
	  mov	    al,bh		; set extended scan code
	  add	    ax,0100h
not_special:
	  exit				; all done

	  ;
	  ; GET_SWITCHAR - get the current DOS switch character
	  ;
	  ; On exit:
	  ;	    AX, DX destroyed
	  ;	    All other registers unchanged, interrupts on
	  ;
	  entry     _get_switchar,noframe

	  mov	    ax,3700h
	  int	    21h
	  cmp	    al,0FFh		; function supported?
	  jne	    got_switchar
	  mov	    dl,'/'              ; default to forward slash
got_switchar:
	  xor	    ah,ah
	  mov	    al,dl
	  exit


	  ;
	  ; GET_EXPANDED - get amount of expanded memory
	  ;
	  ; On entry:
	  ;	    Argument on stack:
	  ;	      unsigned int *emsfree:   pointer to free ems page count
	  ;
	  ; On exit:
	  ;	    AX = pages (16K) of expanded memory
	  ;	    BX, DX destroyed
	  ;	    All other registers unchanged, interrupts on
	  ;
	  entry     get_expanded,argframe   ;set up entry point

	  argW	    emsfree		;one argument, point to free page cnt

	  pushm     si,di		;save registers
	  mov	    al,67h		;get EMS interrupt number
	  calldos   GETINT		;get interrupt vector in es:bx
	  lea	    si,emm_name 	;point to driver name for comparison
	  mov	    di,10		;address of name field in dev header
	  mov	    cx,8		;comparison length
	  cld				;move forward
	  repe	    cmpsb		;does driver name match?
	  jne	    noems		;no, no EMS
	  callems   UPCNT		;get ems page counts
	  or	    ah,ah		;any error?
	  jnz	    noems		;if error, return no ems
	  mov	    si,emsfree		;get address of free page count
	  mov	    [si],bx		;store free page count
	  mov	    ax,dx		;get total page count
	  jmp	    short gxret 	;and return
noems:
	  xor	    ax,ax		;clear total page count
gxret:
	  popm	    di,si		;restore registers
	  exit


	  ;
	  ; GET_CPU - get cpu type
	  ;
	  ; On exit:
	  ;    AX = 86 if an 8088/8086
	  ;	   186 if an 80186/80188
	  ;	   200 for a NEC V20/V30
	  ;	   286 if an 80286
	  ;	   386 if an 80386
	  ;
	  ;    CX destroyed, all other registers unchanged, interrupts on
	  ;
	  entry     _get_cpu,noframe	;set up entry point

	  pushf 			; put flags register onto the stack
	  xor	    ax,ax
	  push	    ax			; put AX on the stack
	  popf				; bring it back in flags
	  pushf 			; try to set bits 12 thru 15 to a zero
	  pop	    ax			; get back Ur flags word in AX
	  and	    ax,0F000h		; if bits 12 thru 15 are set, then it's
	  cmp	    ax,0F000h		;   an 808x, 8018x or NEC V20/V30
	  je	    old_chip

	  mov	    ax,07000h		; set FLAG bits 12 thru 14 - NT, IOPL
	  push	    ax			; put it onto the stack
	  popf				;   and try to put 07000H into flags
	  pushf 			; push flags again
	  pop	    ax			;   and bring back AX for a compare
	  and	    ax,07000h		; if bits 12 thru 14 are set
	  jnz	    got_386		;   then it's an 80386
	  mov	    ax,286		; it's an 80286
	  jmp	    short cpu_bye

got_386:
	  mov	    ax,386		; it's an 80386
	  jmp	    short cpu_bye

old_chip:
	  mov	    ax,0FFFFh		; load up AX
	  mov	    cl,33		; this will shift 33 times if it's an
					;   8088/8086, or once if 80188/80186
	  shl	    ax,cl		; Shifting 33 should zero all bits
	  jz	    not_186
	  mov	    ax,186		; it's an 80188/80186
	  jmp	    short cpu_bye

not_186:
	  xor	    al,al		; set ZF
	  mov	    al,40h		; mul on NEC does NOT affect ZF
	  mul	    al			;   but on 8086/88, ZF gets thrown
	  jz	    got_nec
	  mov	    ax,86		; it's an 8088/8086
	  jmp	    short cpu_bye

got_nec:
	  mov	    ax,200		; it's a NEC V20/V30
cpu_bye:
	  popf
	  exit


          ;
          ; GET_NDP - get ndp type
          ;
          ; On exit:
          ;    AX = 0 if no ndp
          ;        87 if an 8087
          ;        287 if an 80287
          ;        387 if an 80387
          ;
          ;  All other registers unchanged, interrupts on
          ;

          entry     _get_ndp,noframe	;set up entry point

          fninit				; try to initialize NDP
          mov       byte ptr control+1,0	; clear memory byte
          fnstcw    control			; put control word in mem
          mov       ah,byte ptr control+1
          cmp       ah,03h			; if AH is 3, NDP is present
          je        chk_87			;   found NDP
          xor       ax,ax			; clear AX to show no NDP
          jmp       short bye_ndp

; 'got an 8087 ?
chk_87:
          and       control,NOT 0080h		; turn ON interrupts (IEM=0)
          fldcw     control			; load control word
          fdisi					; turn OFF interrupts (IEM=1)
          fstcw     control			; store control word
          test      control,0080h		; if IEM=1, NDP is 8087
          jz        chk287
          mov       ax,087
          jmp       short bye_ndp
chk287:
          finit				; set default infinity mode
          fld1				; make infinity
          fldz				;     by dividing
          fdiv				;         1 by zero !!
          fld       st			; now make negative infinity
          fchs
          fcompp			; compare two infinities
          fstsw     control		; if, for 8087 or 80287
          fwait				; 'til status word is put away
          mov       ax,control		; get control word
          sahf				; put AH into flags
          jnz       got387		; not an 80287
          mov       ax,0287
          jmp       short bye_ndp
got387:
          mov       ax,0387		; must be a 80387
bye_ndp:
          exit


	  ;
	  ; GET_EXTENDED - get amount of extended memory
	  ;
	  ; On exit:
	  ;	    AX = # of 1K blocks of extended memory
	  ;	    All other registers unchanged, interrupts on
	  ;
	  entry     _get_extended,noframe   ;set up entry point

	  cmp	    __osmajor,10
	  jae	    got_88
	  call	    _get_cpu
	  cmp	    ax,286		; is it an 86/88/186/188/V20/V30?
	  jb	    got_88		;   yup, so no extended mem
	  mov	    ax,08800h		; get interrupt number
	  int	    15h
	  cmp	    ah,080h
	  jb	    got_ext
got_88:
	  xor	    ax,ax		; probably not really extended!
got_ext:
	  exit


	  ;
	  ; GET_XMS - get amount of XMS memory
	  ;
	  ; On entry:
	  ;	  int *hma_status
	  ;
	  ; On exit:
	  ;	    AX = # of 1K blocks of extended memory
	  ;	    BX, DX, ES destroyed
	  ;	    All other registers unchanged, interrupts on
	  ;
	  entry     get_xms,argframe	; set up entry point

	  argW	    hma_state

	  cmp	    __osmajor,10
	  jae	    not_286
	  call	    _get_cpu
	  cmp	    ax,286		; is it an 86/88/186/188/V20/V30?
	  jb	    not_286

	  mov	    al,2Fh		; Check INT 2fh vector
	  calldos   GETINT		;   (DOS 2 sets to 0!)
	  mov	    ax,es
	  or	    ax,bx
	  jz	    not_286		; if ES:BX = 0:0, forget it

	  mov	    ax,XMSTEST
	  int	    2Fh
	  cmp	    al,XMSFLAG
	  je	    got_xms
not_286:
	  xor	    ax,ax
	  jmp	    short no_xms
got_xms:
	  mov	    ax,XMSADDR
	  int	    2Fh
	  mov	    word ptr [XMSControl],bx
	  mov	    word ptr [XMSControl+2],es

	  mov	    ah,1		; get HMA availability
	  mov	    dx,0FFFFh
	  call	    [XMSControl]

	  mov	    ah,al
	  mov	    al,bl		; save error code
	  cmp	    ah,0
	  je	    no_hma

	  push	    ax
	  mov	    ah,2		; release the HMA
	  call	    [XMSControl]
	  pop	    ax
no_hma:
	  mov	    bx,hma_state
	  mov	    [bx],ax

	  mov	    ah,8		; query free extended memory
	  call	    [XMSControl]
no_xms:
	  exit


          ;
          ; DosBeep - beep the speaker with the specified tone & duration
          ;
          ; On entry:
          ;       int frequency
          ;       int duration (in 1/18th second increments)
          ;
          ; On exit:
          ;         AX, BX, CX, DX, ES destroyed
          ;         All other registers unchanged, interrupts on
          ;

          EVEN
          entry     DosBeep,argframe	; set up entry point

          argW      duration            ; length of time (in 1/18th increments)
          argW      freq                ; frequency (in Hz)

          sti
          mov       ax, 040h		; point ES to ROM BIOS data area
          mov       es, ax
          mov       cx,freq
          cmp       cx,20		; anything less than 20 Hz creates
          jb        beep_wait		;   a divide overflow

          mov       dx,012h
          mov       ax,034DCh
          div       cx
          push      ax
          mov       al, 10110110b	; select 8253
          out       43h, al
          jmp       $+2
          pop       ax
          out       42h, al		; low byte of divisor
          jmp       $+2
          xchg      ah, al
          out       42h, al		; high byte of divisor
          jmp       $+2

; Wait for desired duration by monitoring time-of-day 18 Hz clock

          mov       dx,es:[06Ch]
beep_edge_loop:				; get leading edge of timer tick
          cmp       dx,es:[06Ch]
          je        beep_edge_loop

beep_wait:
          mov       dx, es:[06Ch]       ;save original tick count
          cmp       cx,20		; are we beeping or just waiting?
          jb        beep_loop

          in        al, 61h		; get current value of control bits
          jmp       $+2
          or        al, 3
          out       61h, al		; turn speaker on
beep_loop:
          sti		         	; because programs keep doing a CLI!!
          cmp       word ptr duration,1	; if only waiting 1 tick, don't check
          je        no_char		;   for a key
          mov       ah,01h		; check for ^C or ^BREAK
          int       16h
          je        no_char
          or        ax,ax
          jz        beep_off		; ^BREAK waiting
          cmp       al,3		; ^C waiting
          je        beep_off
no_char:
          mov       ax, es:[06Ch]
          sub       ax, dx              ;get time elapsed

beep_test:
          cmp       ax,duration         ;now check duration
          jb        beep_loop           ;loop if not there yet

          cmp       cx,20
          jb        beep_bye

beep_off:
          in        al,61h
          jmp       $+2
          and       al,11111100b	; turn speaker off
          out       61h, al
beep_bye:
          exit


	  ;
	  ; SCREEN - position the cursor
	  ;
	  ; On entry:
	  ;	    Arguments are:
	  ;	       int row
	  ;	       int column
	  ;
	  ; On exit:
	  ;	    AX, BX, DX destroyed
	  ;	    All other registers unchanged, interrupts on
	  ;
	  entry     screen,argframe  ;set up entry point

	  argW	    s_column
	  argW	    s_row

	  mov	    ah,2
	  xor	    bx,bx
	  mov	    dh,s_row
	  mov	    dl,s_column
	  int	    10h
	  exit


	  ;
	  ; WINDOW - scroll or clear the window
	  ;
	  ; On entry:
	  ;	    Arguments are:
	  ;	       int upper row
	  ;	       int left column
	  ;	       int lower row
	  ;	       int right column
	  ;	       int scroll mode (-1 = down, 0 = clear window, 1 = up)
	  ;	       int attribute
	  ;
	  ; On exit:
	  ;	    AX, BX, CX, DX destroyed
	  ;	    All other registers unchanged, interrupts on
	  ;
	  entry     window,argframe  ;set up entry point

	  argW	    w_attrib
	  argW	    w_mode
	  argW	    w_rcol
	  argW	    w_lrow
	  argW	    w_lcol
	  argW	    w_urow

	  mov	    ch,w_urow
	  mov	    cl,w_lcol
	  mov	    dh,w_lrow
	  mov	    dl,w_rcol
	  mov	    bh,w_attrib

	  cmp	    word ptr w_mode,0
	  jge	    scroll_up
	  mov	    ax,0700h
	  sub	    ax,w_mode
	  jmp	    short scroll_it
scroll_up:
	  mov	    ah,06h
	  mov	    al,w_mode
scroll_it:
	  int	    10h

	  exit


	  ;
	  ; READ_CHAR - read the character at the cursor position
	  ;
	  ; On entry:
	  ;	    Arguments are:
	  ;	       int row
	  ;	       int column
	  ;
	  ; On exit:
	  ;	    Returns the character and attribute in AX
	  ;	    AX, BX, CX, DX destroyed
	  ;	    All other registers unchanged, interrupts on
	  ;
	  entry     read_char,argframe	;set up entry point

	  argW	    rc_column
	  argW	    rc_row

	  push	    di
	  mov	    dh,rc_row
	  mov	    dl,rc_column
	  call	    initpchr

	  mov	    dx,status		;get 6845 status register address
	  or	    dx,dx		; check for mono
	  jz	    readit		;if so, skip retrace wait

rtend:	  in	    al,dx		;wait for horizontal retrace end
	  shr	    al,1		;check retrace bit
	  jc	    rtend		;wait for it to go off
	  cli				;no interrupts while we wait for it
					;  to go back on
rtstart:  in	    al,dx		;wait for horizontal retrace start
	  shr	    al,1		;check retrace bit
	  jnc	    rtstart		;wait for it to go on

readit:   mov	    ax,es:[di]		;read from display
	  sti				;enable interrupts again
	  xor	    ah,ah
	  pop	    di
	  exit

	  ;
	  ; WRITE_CHAR - write one character
	  ;
	  ; On entry:
	  ;	    Arguments are:
	  ;	       int row
	  ;	       int column
	  ;	       int attribute
	  ;	       int character
	  ;
	  ; On exit:
	  ;	    AX, BX, CX, DX destroyed
	  ;	    All other registers unchanged, interrupts on
	  ;
	  entry     write_char,argframe  ;set up entry point

	  argW	    wc_char
	  argW	    wc_attrib
	  argW	    wc_column
	  argW	    wc_row

	  push	    di
	  mov	    dh,wc_row
	  mov	    dl,wc_column
	  call	    initpchr

	  mov	    ah,wc_attrib
	  mov	    al,wc_char
	  call	    pchar
	  pop	    di
	  exit


BIOS_RAM	segment at 40h
		org	87h
		info	db	?
BIOS_RAM	ends


	  ;
	  ; GET_VIDEO - get the video adapter and monitor type
	  ;
	  ; On exit:
	  ;	    Returns monitor type:
	  ;	       0 = monochrome
	  ;	       1 = cga
	  ;	       2 = ega w/mono monitor
	  ;	       3 = ega w/color monitor
	  ;	       4 = vga w/mono monitor
	  ;	       5 = vga w/color monitor
	  ;
	  ;	    AX, BX, CX destroyed
	  ;	    All other registers unchanged, interrupts on
	  ;
	  entry     _get_video,noframe	 ;set up entry point

	  push	    bp			; save BP for old BIOS bug
	  mov	    ax,01A00h		; function 1A returns active adapter
	  int	    10h 		; al will return as 1a if supported
	  cmp	    al,01ah
	  jnz	    no_dc
	  cmp	    bl,7		; monochrome VGA?
	  jz	    mono_vga
	  cmp	    bl,8		; color VGA?
	  jz	    color_vga
	  mov	    bl,4		; color EGA?
	  jz	    color_ega
	  mov	    bl,5		; monochrome EGA?
	  jz	    mono_ega

no_dc:
	  mov	    ah,12h		; Get information about the EGA
	  mov	    bl,10h
	  int	    10h
	  cmp	    bl,10h		; if it came back as 10h (no EGA),
	  je	    invalid		;   skip next test

	  push	    ds
	  mov	    ax,BIOS_RAM 	; BIOS RAM area
	  mov	    ds,ax
	  assume    ds:BIOS_RAM
	  mov	    bl,info		; get information byte
	  pop	    ds
	  assume    ds:nothing

	  test	    bl,8		; is the EGA active (bit 3 == 0)?
	  jnz	    invalid
	  cmp	    bh,1		; monochrome monitor?
	  jnz	    color_ega
mono_ega:
	  mov	    ax,2
	  jmp	    short got_video
color_ega:
	  mov	    ax,3
	  jmp	    short got_video
mono_vga:
	  mov	    ax,4
	  jmp	    short got_video
color_vga:
	  mov	    ax,5
	  jmp	    short got_video

invalid:
	  mov	    ah,0Fh		; get video mode
	  int	    10h
	  cmp	    al,7
	  jnz	    color_cga
	  xor	    ax,ax
	  jmp	    short got_video
color_cga:
	  mov	    ax,1
got_video:
	  pop	    bp
	  exit


	  ;
	  ; QPRINT - quick-print a string directly to display memory
	  ;
	  ; On entry:
	  ;	    Arguments are:
	  ;	       int row: 	row for output
	  ;	       int column:	column for output
	  ;	       int attribute:	attribute output
	  ;	       char *string:	string to display
	  ;
	  ; On exit:
	  ;	    AX, BX, CX, DX, ES destroyed
	  ;	    All other registers unchanged, interrupts on
	  ;
	  entry     qprint,argframe	;set up entry point

	  argW	    string		;string address
	  argW	    attrib		;display attribute
	  argW	    ocolumn		;column number
	  argW	    orow		;row number

	  pushm     si,di		;save registers

	  mov	    dh,orow		;get row
	  mov	    dl,ocolumn		;get column
	  call	    initpchr		;initialize the display routines
	  mov	    ax,ocolumn
	  add	    column,ax		; adjust start column (for clipping)
	  mov	    si,string		;point to string

ploop:
	  lodsb 			;get a character to display
	  or	    al,al		;end of string?
	  jz	    pbye		;if so we're done
	  mov	    ah,attrib		;get attribute
	  call	    pchar		;display the character
	  jmp	    short ploop 	;keep going
pbye:
	  popm	    di,si		;restore registers
	  exit


	  ;
	  ; INITPCHR - Initialize direct video I/O
	  ;
	  ; On entry:
	  ;	    DH = screen row
	  ;	    DL = screen column
	  ;
	  ; On exit:
	  ;	    ES:DI = location in display buffer of specified row
	  ;		    and column
	  ;	    AX, CX, DX destroyed
	  ;	    All other registers unchanged, interrupts on
	  ;
	  ;
	  entry     initpchr,noframe,,local   ;set entry point

	  mov	    status,0		;clear wait for retrace (CGA) address
	  mov	    column,0		;clear column
	  mov	    lmargin,0		;clear left margin
	  xor	    ax,ax		;get zero
	  mov	    es,ax		;point es to ROM BIOS data area
	  mov	    ax,es:[044Ah]	;get line length
	  mov	    rmargin,ax		;set right margin to line length
	  mul	    dh			;line length * row = total row bytes
					;  in ax
	  xor	    dh,dh		;clear high byte so dx = column
	  add	    ax,dx		;add the number of columns
	  add	    ax,ax		;* 2 for attribute byte
	  add	    ax,es:[044Eh]	;add offset into screen buffer
	  push	    ax			;save the cursor position offset
	  mov	    cx,0B000h		;assume mono screen
	  cmp	    byte ptr es:[0449h],7  ;check video mode
	  jz	    ipdone		;if mode 7, it's mono & we're done
	  mov	    ax,es:[0463h]	;address of 6845 video controller
	  add	    ax,6		;offset for status register
	  mov	    status,ax		;save status register address
	  mov	    cx,0B800h		;set for cga/ega/vga

ipdone:   mov	    es,cx		;copy video segment
	  xor	    di,di		;set DI to hardware video offset

	  pop	    ax			;get back old cursor offset
	  add	    di,ax		;add to video buffer offset
	  exit


	  ;
	  ; PCHAR - display a character directly to video memory
	  ;
	  ; On entry:
	  ;	    AH = attribute
	  ;	    AL = character to print
	  ;	    ES:DI = segment:offset for video memory
	  ;
	  ; On exit:
	  ;	    ES:DI = updated video memory location
	  ;	    AX, BX, CX, DX destroyed
	  ;	    column updated
	  ;	    All other registers unchanged, interrupts on
	  ;
	  ;
	  entry     pchar,noframe,,local   ;set entry point

	  mov	    cx,1		;print 1 character
	  cmp	    al,9		;check for tab
	  jne	    doprint		;not tab, go display it
	  mov	    bx,column		;tab  - get current column number
	  and	    bx,07h		;take lower three bits
	  mov	    cx,8		;get tab width
	  sub	    cx,bx		;get number of blanks
	  mov	    al,' '              ;display that many blanks
doprint:
	  mov	    bx,column		;get current column
	  cmp	    bx,lmargin		;to left of horizontal offset?
	  jb	    noprint		;yup - don't print it
	  cmp	    bx,rmargin		;to right of right margin?
	  jge	    noprint		;yup - don't print it
	  mov	    dx,status		;get 6845 status register address
	  or	    dx,dx		; check for monochrome, EGA, or VGA
	  jz	    writeit		;if so, skip retrace wait
	  mov	    bx,ax		;save character and attribute

hrtend:   in	    al,dx		;wait for horizontal retrace end
	  shr	    al,1		;check retrace bit
	  jc	    hrtend		;wait for it to go off
	  cli				;no interrupts while we wait for it
					;  to go back on
hrtstart: in	    al,dx		;wait for horizontal retrace start
	  shr	    al,1		;check retrace bit
	  jnc	    hrtstart		;wait for it to go on
	  mov	    ax,bx		;get back character & attr

writeit:  stosw 			;write to display
	  sti				;enable interrupts again

noprint:  inc	    column		;increment column counter
	  loop	    doprint		;check for more chars to print
	  exit

	  end

