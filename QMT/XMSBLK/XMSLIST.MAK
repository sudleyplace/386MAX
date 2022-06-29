
# Note that the MASM options assume MASM 5.10b

OEM=RET 			# Default 3-letter OEM name
PRODNAME=XMSLIST		# Product file basename

O=$(OEM)\			# OEM-specific files
R=					# Source directory
S=R:\MAX\STATUTIL\	# Utility directory

ALLINC=$(O) 		# INCLUDE search path

LD=link

AFLAGS=/mu /p /r /t /w1 /DW16 /Zd # MASM options
LFLAGS=/map /line /nod		# Linker options

{$(R)}.asm{$(O)}.obj:
	 set INCLUDE=$(ALLINC);$(INCLUDE)
	 masm %s $(AFLAGS), $(O);

{$(S)}.asm{$(O)}.obj:
	 set INCLUDE=$(ALLINC);$(INCLUDE)
	 masm %s $(AFLAGS), $(O);

ALL:	$(O)$(PRODNAME).EXE \
		$(BINDIR)$(PRODNAME).EXE

############### XMSLIST #######################

OBJS=	$(O)$(PRODNAME).OBJ \
		$(O)PRINTF.OBJ

$(O)$(PRODNAME).OBJ:   $(PRODNAME).ASM

$(O)PRINTF.OBJ: 	   $(S)PRINTF.ASM

$(O)$(PRODNAME).EXE:   $(OBJS)	  $(PRODNAME).MAK
	 $(LD) @<<$(O)$(PRODNAME).arf
		$(OBJS: =+^
)
		$*.exe
		$*.map
		$(LFLAGS)
		NUL.def
<<KEEP

$(BINDIR)$(PRODNAME).EXE:	$(O)$(PRODNAME).EXE
	xc /r %s $@

