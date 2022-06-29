#' $Header:   P:/PVCS/MISC/XMSTEST/UMBTEST.MAV   1.2   22 Feb 1994 12:47:44   HENRY  $
#
# Makefile for UMBTEST.EXE
#
#' $Log:   P:/PVCS/MISC/XMSTEST/UMBTEST.MAV  $
#' 
#'    Rev 1.2   22 Feb 1994 12:47:44   HENRY
#' Update XMSTEST to check for broken UMB resize
#'
#'    Rev 1.1   06 Aug 1992 13:17:56   HENRY
#' Handle reallocation of XMS handle allocated with size 0
#

PROJ=UMBTEST
O=ret\				# Object directory
I=$(INCDIR)			# path for generic includes

OLDINC=$(INCLUDE)		# Previous INCLUDE value
ALLINC=$(O);$(I);$(INCLUDE)	# INCLUDE search path

CC=cl
CFLAGS=/AL /W4 /BATCH /FPa /Zd /Gs /Fm
AFLAGS=/mu /p /r /t /w1 /DLANG_$(LANG) # MASM options
LLIBS=LLIBCA
LINKER=link
LRF=echo > NUL
LFLAGS=/NOI /BATCH /FAR /PACKC /MAP

.c{$(O)}.obj :
	$(CC) /c $(CFLAGS) /Fo$@ $< /link /li

.asm{$(O)}.obj:
	 @ff /, $(R)$(@B).asm > $(O)dirntry.tmp
	 @copy $(I)semicol.txt+$(O)dirntry.tmp $(O)dirntry.inc >NUL
	 set INCLUDE=$(ALLINC)
	 masm $(@B) $(AFLAGS), $(O) $(LSTMAC);
	 set INCLUDE=$(OLDINC)
	 @dispobj $*/w
	 @ff $*/,/#


OBJS=	$(O)UMBTEST.obj $(O)XMSINFO.obj

all:	$(O)$(PROJ).exe

$(O)UMBTEST.obj : UMBTEST.C

$(O)XMSINFO.obj : XMSINFO.ASM


$(O)$(PROJ).exe : $(OBJS)
	$(LINKER) @<<$(O)$(PROJ).lrf
		$(OBJS: = +^
)
		$@
		$*.map
		$(LLIBS: = +^
)
		$(LFLAGS);
<<KEEP

