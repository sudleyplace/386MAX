;
; modified - 22-apr-96 o.w.m - added vidmem statement, change comments
;
EXCLUDE=1000-A000   ;
VIDMEM=A000-C000    ; owm - get rid of console spurious characters 
NOWIN3              ; INSTALL ==> Do not install WINDOWS 3.0 support code
RAM=C800-CC00       ; was c800 MAXIMIZE ==> Protect RAM on ethernet adaptor
;USE=B000-B800      ; owm - not for mda systems
;VGASWAP            ; owm - had to take this out to get edit,msd, etc to work ; MAXIMIZE ==> Relocate video ROM.
