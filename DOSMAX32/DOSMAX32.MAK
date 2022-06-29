#' $Header:   P:/PVCS/MAX/DOSMAX32/DOSMAX32.MAV   1.3   26 Feb 1996 13:09:14   BOB  $

TARGETOS=WIN95
APPVER=4.0

!include <win32.mak>

O=RET\			# Directory for .OBJs
R=			# Directory for source
BINDIR=$(MAXROOT)lib\	# Save area for build targets
I=$(MAXROOT)include\	# include files

!IF "$(LANG)" == "US"
RCNAME=dosmax32.rc
!ELSE
RCNAME=dosmax32.$(LANG)
!ENDIF
DLLNAME=dosmax32.d$(LANG)

all: $(O)$(DLLNAME)	 \
     $(BINDIR)$(DLLNAME)

################ D O S M A X 3 2 #####################################

OBJS=			 \
####### $(O)COPYHOOK.OBJ \
####### $(O)CTXMENU.OBJ  \
	$(O)DOSMAX32.OBJ \
####### $(O)ICONHDLR.OBJ \
####### $(O)IPERSIST.OBJ \
	$(O)PROPSHET.OBJ \
	$(O)SHEXINIT.OBJ \
	$(O)DOSMAX32.RES


$(O)$(DLLNAME): 	 \
	$(OBJS) 	 \
	$(R)DOSMAX32.DEF
  $(implib) -machine:$(CPU) -def:dosmax32.def -out:$(O)dosmax32.lib $(OBJS)
  $(link) $(linkdebug) $(dlllflags) -base:0x1C000000 -out:$(O)$(DLLNAME) $(OBJS) \
	  $(olelibsdll) shell32.lib comctl32.lib w32sut32.lib		 \
	  $(O)dosmax32.lib $(O)dosmax32.exp

{$(R)}.cpp{$(O)}.obj:
    $(cc) $(cdebug) $(cflags) /DLANG_$(LANG) $(cvarsdll) /Fo$(O) $(@B).cpp

$(O)CTXMENU.obj:	$(R)CTXMENU.cpp  \
			$(R)priv.h	 \
			$(R)dosmax32.h	 \
			$(R)resource.h

$(O)IPERSIST.obj:	$(R)IPERSIST.cpp \
			$(R)priv.h	 \
			$(R)dosmax32.h

$(O)DOSMAX32.obj:	$(R)DOSMAX32.cpp \
			$(R)priv.h	 \
			$(R)dosmax32.h

$(O)PROPSHET.obj:	$(R)PROPSHET.cpp \
			$(R)priv.h	 \
			$(R)dosmax32.h	 \
			$(I)dosmax2.h	 \
			$(R)resource.h

$(O)SHEXINIT.obj:	$(R)SHEXINIT.cpp	$(R)priv.h	$(R)dosmax32.h


$(O)dosmax32.res: $(R)$(RCNAME)
    $(rc) $(rcflags) $(rcvars) /Fo$(O)dosmax32.res -dLANG_$(LANG) $(RCNAME)

$(BINDIR)$(DLLNAME):	  $(O)$(DLLNAME)
    copy $(O)$(DLLNAME)   $(BINDIR)$(DLLNAME)
## The following copy is also done in TEXT.MAK, but I do it here so
##   we can test the DLL right away without having to run TEXT.MAK.
    copy $(O)$(DLLNAME)   $(BINDIR)dosmax32.dll

