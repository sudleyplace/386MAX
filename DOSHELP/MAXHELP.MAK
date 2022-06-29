#
# Makefile for all DOS-based help files
#
# $Header:   P:/PVCS/MAX/DOSHELP/MAXHELP.MAV   1.8   02 Jun 1997 12:24:26   BOB  $
#

.SUFFIXES: .rtf .asc .hlp .rus .rgr .aus .agr .ogr .ous

INCLUDE=$(MAXROOT)include;$(INCLUDE)

!include <maxnames.mak>

H=hlp\		# Directory for intermediate .HLP files
O=out\		# Directory for intermediate .OUT files
C=hlp2\ 	# Directory for concatenated .HLP files

.r$(LANG){$(O)}.o$(LANG):
	hmakel $**
	xc/m/r $(@B).out $(O)*.o$(LANG)

.a$(LANG){$(O)}.o$(LANG):
	copy $** $(O)*.o$(LANG)

!IF "$(LANG)" == "GR" || "$(LANG)" == "gr" || "$(LANG)" == "Gr"
MSIZE=56	# Size of medium dialog box in German
MSIZ2=68	# Size of medium box 2 in German
!ELSE
MSIZE=52	# Size of medium dialog box in all other versions
MSIZ2=69	# Size of medium box 2 in all other versions
!ENDIF

HM=$(MAXROOT)TOOLS\helpmake
INHPRE=IN	# MI for Move'EM INSTALL help
HMR19=$(HM) /s1 /w19	   /o$(H)$(@B).hlp $(O)$(@B).o$(LANG)
HMR33=$(HM) /s1 /w33	   /o$(H)$(@B).hlp $(O)$(@B).o$(LANG)
HMA51=$(HM) /s2 /w51	   /o$(H)$(@B).hlp $(O)$(@B).o$(LANG)
HMR52=$(HM) /s1 /w$(MSIZE) /o$(H)$(@B).hlp $(O)$(@B).o$(LANG)
HMR53=$(HM) /s1 /w53	   /o$(H)$(@B).hlp $(O)$(@B).o$(LANG)
HMR69=$(HM) /s1 /w$(MSIZ2) /o$(H)$(@B).hlp $(O)$(@B).o$(LANG)
HMA76=$(HM) /s2 /w76	   /o$(H)$(@B).hlp $(O)$(@B).o$(LANG)


!IF "$(MCALLBACK)" == "Y"
ASQDATA= $(H)AS_D_HLP.hlp
QSHDATA= $(H)QS_D_HLP.hlp
!ELSE
ASQDATA=
QSHDATA=
!ENDIF

ASQFILES=$(H)AS_H_HLP.hlp\
$(H)AS_T_HLP.hlp\
$(H)AS_G_HLP.hlp\
$(H)AS_L_HLP.hlp
ASQFILES2=$(H)AS_Q_HLP.hlp$(ASQDATA)

INSFILES=$(H)$(INHPRE)_H_HLP.hlp\
$(H)$(INHPRE)_S_HLP.hlp\
$(H)$(INHPRE)_M_HLP.hlp\
$(H)$(INHPRE)_L_HLP.hlp\
$(H)$(INHPRE)_Q_HLP.hlp

MXFILES=$(H)MX_H_HLP.hlp\
$(H)MX_S_HLP.hlp\
$(H)MX_M_HLP.hlp\
$(H)MX_L_HLP.hlp
MXFILES2=$(H)MX_Q_HLP.hlp\
$(H)MX_D_HLP.hlp

QSHFILES=$(H)QS_H_HLP.hlp\
$(H)QS_O_HLP.hlp\
$(H)QS_Q_HLP.hlp$(QSHDATA)

ALL: DIR	hmakel.exe \
	$(C)ASQ.HLP		$(C)$(INHPRE)STALL.HLP	$(C)MAXIMIZE.HLP \
	$(C)QSHELL.HLP		$(C)$(INHPRE)DATE.HLP \
	$(BD)asq.hlp		$(BD)setupdos.hlp   $(BD)maximize.hlp \
	$(BD)max.hlp		$(BD)update.hlp

DEL:
	-rm $(H)*.*
	-rm $(C)*.hlp

DIR:
	vdir -c $(H) $(O) $(C)

pvcs.cfg:
	@echo <<pvcs.cfg
REFERENCEDIR=WRITEPROTECT P:\MAX\doshelp\*
VCSDIR = P:\PVCS\MAX\doshelp\*
ALIAS ALL P:\PVCS\MAX\doshelp\*.*,p:\pvcs\max\doshelp\udlocal2.bav
<<KEEP

GET: pvcs.cfg
	$(GETCMD) $(MAKEDIR)

# All files depend on this program
$(ASQFILES): hmakel.exe

$(INSFILES): hmakel.exe

$(MXFILES): hmakel.exe

$(QSHFILES): hmakel.exe

hmakel.exe: hmakel.c
	@Set INCLUDE=$(INCLUDE)
	@Set LIB=$(LIB)
	$(MSVC)BIN\cl /Ozax /Gr /Gs /AS /Fm /Zd /W3 /WX $*.c /link /li

$(C)ASQ.HLP:	 $(ASQFILES)	$(ASQFILES2)	 maxhelp.mak
	copy /b $(ASQFILES: =+)+$(ASQFILES2: =+) $@

$(C)$(INHPRE)STALL.HLP: $(INSFILES)	maxhelp.mak
	copy /b $(INSFILES: =+) $@

$(C)MAXIMIZE.HLP: $(MXFILES)	$(MXFILES2)	maxhelp.mak
	copy /b $(MXFILES: =+)+$(MXFILES2: =+) $@

$(C)QSHELL.HLP:  $(QSHFILES)	maxhelp.mak
	copy /b $(QSHFILES: =+) $@

$(C)$(INHPRE)DATE.HLP: $(C)$(INHPRE)STALL.HLP
	xc /n/a $** $@


$(BD)asq.hlp:	    $(C)ASQ.HLP
	xc /r $** $@

$(BD)setupdos.hlp:  $(C)$(INHPRE)STALL.HLP
	xc /r $** $@

$(BD)maximize.hlp:  $(C)MAXIMIZE.HLP
	xc /r $** $@

$(BD)max.hlp:	    $(C)QSHELL.HLP
	xc /r $** $@

$(BD)update.hlp:    $(C)$(INHPRE)DATE.HLP
	xc /r $** $@


$(H)AS_Q_HLP.hlp: $(O)AS_Q_HLP.o$(LANG)
	$(HMR19)

$(H)AS_G_HLP.hlp: $(O)AS_G_HLP.o$(LANG)
	$(HMR69)

$(H)AS_H_HLP.hlp: $(O)AS_H_HLP.o$(LANG)
	$(HMR69)

$(H)AS_L_HLP.hlp: $(O)AS_L_HLP.o$(LANG)
	$(HMR69)

$(H)AS_T_HLP.hlp: $(O)AS_T_HLP.o$(LANG)
	$(HMR69)

$(H)AS_D_HLP.hlp: $(O)AS_D_HLP.o$(LANG)
	$(HMA51)

$(H)$(INHPRE)_S_HLP.hlp: $(O)$(INHPRE)_S_HLP.o$(LANG)
	$(HMR33)

$(H)$(INHPRE)_M_HLP.hlp: $(O)$(INHPRE)_M_HLP.o$(LANG)
	$(HMR52)

$(H)$(INHPRE)_H_HLP.hlp: $(O)$(INHPRE)_H_HLP.o$(LANG)
	$(HMR69)

$(H)$(INHPRE)_L_HLP.hlp: $(O)$(INHPRE)_L_HLP.o$(LANG)
	$(HMR69)

$(H)$(INHPRE)_Q_HLP.hlp: $(O)$(INHPRE)_Q_HLP.o$(LANG)
	$(HMR19)

$(H)MX_S_HLP.hlp: $(O)MX_S_HLP.o$(LANG)
	$(HMR33)

$(H)MX_M_HLP.hlp: $(O)MX_M_HLP.o$(LANG)
	$(HMR52)

$(H)MX_L_HLP.hlp: $(O)MX_L_HLP.o$(LANG)
	$(HMR69)

$(H)MX_H_HLP.hlp: $(O)MX_H_HLP.o$(LANG)
	$(HMR69)

$(H)MX_Q_HLP.hlp: $(O)MX_Q_HLP.o$(LANG)
	$(HMR19)

$(H)MX_D_HLP.hlp: $(O)MX_D_HLP.o$(LANG)
	$(HMA76)

$(H)QS_Q_HLP.hlp: $(O)QS_Q_HLP.o$(LANG)
	$(HMR19)

$(H)QS_O_HLP.hlp: $(O)QS_O_HLP.o$(LANG)
	$(HMR53)

$(H)QS_H_HLP.hlp: $(O)QS_H_HLP.o$(LANG)
	$(HMR69)

$(H)QS_D_HLP.hlp: $(O)QS_D_HLP.o$(LANG)
	$(HMA51)

$(H)QI_S_HLP.hlp: $(O)QI_S_HLP.o$(LANG)
	$(HMR33)

$(H)QI_M_HLP.hlp: $(O)QI_M_HLP.o$(LANG)
	$(HMR52)

$(H)QI_H_HLP.hlp: $(O)QI_H_HLP.o$(LANG)
	$(HMR69)

$(H)QI_L_HLP.hlp: $(O)QI_L_HLP.o$(LANG)
	$(HMR69)

$(H)QI_Q_HLP.hlp: $(O)QI_Q_HLP.o$(LANG)
	$(HMR19)

