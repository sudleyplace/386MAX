;***************************************************************************

PGROUP	 group	 HCODE,CODE,DATZ,NLSEG,NDATA,UDATA,DTAIL,ZZTAIL,NCODE,UCODE,HTAIL,HNCODE
DGROUP	 group	 HDATA,STACK
XGROUP	 group	 XCODE,XDATA,HZZTAIL
PSPGRP	 group	 PSP_SEG

;***************************************************************************


PSP_SEG  segment at 0			; Start PSP segment
PSP_SEG  ends				; End	PSP segment

HCODE	 segment byte public 'hcode'    ; Resident Code         (HARPO)
HCODE	 ends				;

CODE	 segment byte public 'prog'     ; Start CODE segment    (GETSIZE)
CODE	 ends

DATZ	 segment para public 'data'     ; Start DATZ segment    (GETSIZE)
DATZ	 ends

NLSEG	 segment para public 'ndata'    ; Start NLSEG segment   (GETSIZE)
NLSEG	 ends

NDATA	 segment dword public 'ndata'   ; Start NDATA segment   (GETSIZE)
NDATA	 ends

UDATA	 segment dword public 'udata'   ; Start UDATA segment   (GETSIZE)
UDATA	 ends

DTAIL	 segment para public 'zdata'    ; Start DTAIL segment   (GETSIZE)
DTAIL	 ends

ZZTAIL	 segment dword public 'zzdata'  ; Start ZZTAIL segment  (GETSIZE)
ZZTAIL	 ends

NCODE	 segment byte public 'ncode'    ; Start NCODE segment   (GETSIZE)
NCODE	 ends

UCODE	 segment byte public 'ucode'    ; Start UCODE segment   (GETSIZE)
UCODE	 ends

HTAIL	 segment byte public 'htail'    ; End of Resident Code  (HARPO)
HTAIL	 ends				;

HNCODE	 segment byte public 'hncode'   ; Non-Resident Code     (HARPO)
HNCODE	 ends				;

HDATA	 segment dword public 'hdata'   ; Resident Data         (HARPO)
HDATA	 ends				;

STACK	 segment para stack 'stack'     ; Stack segment         (HARPO)
STACK	 ends				;

XDATA	 segment dword public 'xdata'   ; Start XDATA segment
XDATA	 ends

XCODE	 segment byte public 'xcode'    ; Start XCODE segment
XCODE	 ends

HZZTAIL  segment para public 'zztail'   ; End of Non-Res Data  (HARPO)
HZZTAIL  ends				;


