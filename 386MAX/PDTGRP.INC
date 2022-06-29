;' $Header:   P:/PVCS/MAX/386MAX/PDTGRP.INV   1.0   21 Sep 1995 18:53:48   HENRY  $
;
; (C) Copyright 1987-92 Qualitas, Inc.	All rights reserved.
;
; PDTGRP.INC
;
; Equates for PDTGRP
;

PDTGRP	 group	 PDTSEG


PDTSEG	 segment use16 para public 'pdtgrp' ; Start PDTSEG segment
	 assume  fs:PDTGRP

	 extrn	 OFFPDT:dword

	 assume  fs:nothing

PDTSEG	 ends			; End PDTSEG segment

