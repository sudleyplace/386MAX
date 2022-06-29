#
# dpmictst.mak - test program for dpmi_crc.asm
#

ALL: dpmictst.exe

MODEL = S
INCLUDE = $(MAXROOT)include;$(INCLUDE)
CFLAGS = /nologo /G2 /W3 /WX /A$(MODEL) /Od /D "_DEBUG" /GA /Z7
LFLAGS = /NOLOGO /NOD /PACKC:61440 /ALIGN:16 /ONERR:NOEXE /M /LI /CO
LIBS = libw $(MODEL)libcew
MAPFILE = NUL
LIBS_EXT = lr\lquilibr.lib
DEFFILE = dpmictst.def
LINK = link

dpmictst.exe: dpmictst.obj dpmictst.mak dpmictst.def $(LIBS_EXT)
	echo >NUL @<<dpmictst.CRF
dpmictst.obj
$@
$(MAPFILE)
$(MSVC)lib\+
$(MSVC)mfc\lib\+
$(LIBS_EXT)+
$(LIBS)
$(DEFFILE);
<<KEEP
	$(LINK) $(LFLAGS) @dpmictst.CRF

dpmictst.obj: dpmictst.cpp
	SET CL=/c $(CFLAGS)
	cl $(@B).cpp
	SET CL=

