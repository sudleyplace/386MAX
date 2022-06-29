	  title     BATUTIL - Assembler utilities for BATPROC

	  ;
	  page	    ,132		;make wide listing
	  ;
	  comment   }

	  (C) Copyright 1990 Rex Conn
	  All Rights Reserved

	  } end description
	  ;
	  ;
	  ; Includes
	  ;
	  include   macros.asm		 ;general macros

	  .model    small		;small stuff

	  ;
	  .code 			;start code segment
	  ;

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
	  mov	    dl,'/'		; default to forward slash
got_switchar:
	  xor	    ah,ah
	  mov	    al,dl
	  exit

	  end

