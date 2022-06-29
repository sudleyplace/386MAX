#' $Header:   P:/PVCS/MAX/INCLUDE/TEXTNAME.MAV   1.25   04 Apr 1996 16:29:14   HENRY  $
#
# TEXTNAME.MAK - Included makefile containing names of files in TEXT
#				 project.  The TEXT project contains text files as
#				 well as binaries distributed with the product which
#				 we don't build from source and which aren't associated
#				 with any other project.
#
# This include is shared by SETUP.MAK and TEXT.MAK
#

# Files from TEXT project to archive along with everything else.
# Ordered by extension (cfg, dll, etc) then by name.
ALLTEXT =$(B)readme\
	$(B)doshelp.add\
	$(B)editor.bat\
!if "$(LANG)" == "GR"
	$(B)maxhilfe.bat\
!else
	$(B)maxhelp.bat\
!endif
	$(B)qstrip.bat\
	$(B)readme.bat\
	$(B)rmoldmax.bat\
	$(B)386load.cfg\
	$(B)reorder.cfg\
	$(B)ctl3dv2.dll\
	$(B)dosmax32.dll\
	$(B)sfttabs.dll\
	$(B)hhelp.exe\
	$(B)rdosmax.exe\
	$(B)dosmax.ico\
	$(B)setup.ico\
	$(B)qpopup.inf\
	$(B)hhelp.ini\
	$(B)$(COREPROD).lst\
	$(B)qualitas.lst\
	$(B)packing.lst\
	$(B)stripmgr.lst\
	$(B)dosmaxf.pif\
	$(B)dosmaxw.pif\
	$(B)dosm95f.pif\
	$(B)dosm95w.pif\
	$(B)stripmgr.pif\
	$(B)stripm95.pif\
	$(B)evap.pif\
	$(B)dosmaxf.qpe\
	$(B)dosmaxw.qpe\
	$(B)maximize.trm\
	$(B)pnp.txt

# Files from TEXT project that we don't build and are copied directly
# onto the distribution disk 1.
ALLTEXT2 =$(B)setupdos.cfg

# The complete list of what gets archived on the distribution disk for
# unconditional extraction into the destination directory.
# *** NOTE *** No trailing blanks are allowed; this will cause extra
# lines in PACKAGE.CFG and will crash the build.
ALLBIN =$(B)386load.com\
	$(B)386util.com\
	$(B)romsrch.com\
	$(B)xlat.com\
	$(B)dosmax16.dll\
	$(B)goahead.drv\
	$(B)goahead.exe\
	$(B)maxedit.exe\
	$(B)maximize.exe\
	$(B)maxmeter.exe\
	$(B)memlimit.exe\
	$(B)qmt.exe\
	$(B)qpifedit.exe\
	$(B)qpopup.exe\
	$(B)setewv.exe\
	$(B)toolbox.exe\
	$(B)winmaxim.exe\
	$(B)maxhelp.hlp\
	$(B)maximize.hlp\
	$(B)setup.hlp\
	$(B)extrados.max\
	$(B)$(COREPROD).sys\
	$(B)386disk.sys\
	$(B)386load.sys\
	$(B)evap.exe\
	$(B)$(COREPROD).vxd

# Common binary list.  All of these are built.
ALLCOMN =$(B)asq.exe\
	$(B)batproc.exe\
	$(B)max.exe\
	$(B)snapshot.exe\
	$(B)stripmgr.exe\
	$(B)asq.hlp\
	$(B)max.hlp

# BlueMAX-only files that are built
#!IF "$(CORECODE)" == "U"
ALLBIN=$(ALLBIN)\
	$(B)rambasic.com
#!ENDIF

# BCF list
ALLBCF=\
	$(BCF)@0042.bcf\
	$(BCF)@05c1.bcf\
	$(BCF)@0671.bcf\
	$(BCF)@07c3.bcf\
	$(BCF)@0deb.bcf\
	$(BCF)@0eba.bcf\
	$(BCF)@0f65.bcf\
	$(BCF)@1a3f.bcf\
	$(BCF)@1ccd.bcf\
	$(BCF)@1d0a.bcf\
	$(BCF)@1e8a.bcf\
	$(BCF)@1f19.bcf\
	$(BCF)@1fe8.bcf\
	$(BCF)@2088.bcf\
	$(BCF)@20a6.bcf\
	$(BCF)@224d.bcf\
	$(BCF)@2271.bcf\
	$(BCF)@23e9.bcf\
	$(BCF)@23ef.bcf\
	$(BCF)@28e7.bcf\
	$(BCF)@2a94.bcf\
	$(BCF)@303c.bcf\
	$(BCF)@31a1.bcf\
	$(BCF)@31c3.bcf\
	$(BCF)@32c0.bcf\
	$(BCF)@3c2a.bcf\
	$(BCF)@3fa2.bcf\
	$(BCF)@402a.bcf\
	$(BCF)@4108.bcf\
	$(BCF)@436d.bcf\
	$(BCF)@46ec.bcf\
	$(BCF)@4735.bcf\
	$(BCF)@4d69.bcf\
	$(BCF)@4f0d.bcf\
	$(BCF)@51c4.bcf\
	$(BCF)@524a.bcf\
	$(BCF)@53ca.bcf\
	$(BCF)@55e3.bcf\
	$(BCF)@5743.bcf\
	$(BCF)@58c4.bcf\
	$(BCF)@639c.bcf\
	$(BCF)@6550.bcf\
	$(BCF)@65c9.bcf\
	$(BCF)@6b1c.bcf\
	$(BCF)@6cf3.bcf\
	$(BCF)@6ddb.bcf\
	$(BCF)@72b2.bcf\
	$(BCF)@788a.bcf\
	$(BCF)@78ed.bcf\
	$(BCF)@796a.bcf\
	$(BCF)@79c1.bcf\
	$(BCF)@79c8.bcf\
	$(BCF)@7bc9.bcf\
	$(BCF)@7cd8.bcf\
	$(BCF)@7f00.bcf\
	$(BCF)@8060.bcf\
	$(BCF)@8110.bcf\
	$(BCF)@895f.bcf\
	$(BCF)@8ac7.bcf\
	$(BCF)@8adc.bcf\
	$(BCF)@8c94.bcf\
	$(BCF)@8d5a.bcf\
	$(BCF)@8d6b.bcf\
	$(BCF)@8dc0.bcf\
	$(BCF)@8e68.bcf\
	$(BCF)@94e5.bcf\
	$(BCF)@95e0.bcf\
	$(BCF)@9832.bcf\
	$(BCF)@991e.bcf\
	$(BCF)@999b.bcf\
	$(BCF)@9a7c.bcf\
	$(BCF)@9a96.bcf\
	$(BCF)@9e57.bcf\
	$(BCF)@a8e9.bcf\
	$(BCF)@a934.bcf\
	$(BCF)@a94c.bcf\
	$(BCF)@aa2e.bcf\
	$(BCF)@aab9.bcf\
	$(BCF)@ac77.bcf\
	$(BCF)@aed1.bcf\
	$(BCF)@afb2.bcf\
	$(BCF)@b36c.bcf\
	$(BCF)@b378.bcf\
	$(BCF)@ba33.bcf\
	$(BCF)@bdc3.bcf\
	$(BCF)@bf7d.bcf\
	$(BCF)@c267.bcf\
	$(BCF)@c3e3.bcf\
	$(BCF)@c897.bcf\
	$(BCF)@c8e7.bcf\
	$(BCF)@ccdb.bcf\
	$(BCF)@cdd3.bcf\
	$(BCF)@d34f.bcf\
	$(BCF)@d99b.bcf\
	$(BCF)@dc3c.bcf\
	$(BCF)@ded3.bcf\
	$(BCF)@dee9.bcf\
	$(BCF)@dfea.bcf\
	$(BCF)@e15d.bcf\
	$(BCF)@e503.bcf\
	$(BCF)@e63c.bcf\
	$(BCF)@e740.bcf\
	$(BCF)@e7e6.bcf\
	$(BCF)@e86d.bcf\
	$(BCF)@eba0.bcf\
	$(BCF)@ec8a.bcf\
	$(BCF)@ee4c.bcf\
	$(BCF)@f075.bcf\
	$(BCF)@f179.bcf\
	$(BCF)@f1c1.bcf\
	$(BCF)@f2a6.bcf\
	$(BCF)@f4a1.bcf\
	$(BCF)@f656.bcf\
	$(BCF)@f89c.bcf\
	$(BCF)@faaa.bcf\
	$(BCF)@fee8.bcf\
	$(BCF)@ffb3.bcf

# These files get copied directly onto distribution disk 1.
ALLBIN2 =\
	$(B)qlogo.ovl\
	$(B)setup.exe\
	$(B)setupdos.hlp\
	$(B)setup.hlp\
	$(B)setupdos.ovl

# Optional files for network setup
OPTLST_NET =

# Optional version-check files.  Currently, this list is empty.
OPTLST_VERCHK =

# Static link libraries associated with third-party DLLs distributed
# with the product.  These libraries are copied to the $(MAXROOT)lib
# directory and are only needed to build the product; they are never
# distributed.
LIBRARIES =\
	$(L)ctl3ds.lib\
	$(L)ctl3dv2.lib\
	$(L)dzip.lib\
	$(L)dunzip.lib\
	$(L)dzip.dll\
	$(L)dunzip.dll\
	$(L)implode.lib\
	$(L)LHelp.lib\
	$(L)pifmgr.lib\
	$(L)sfttabs.lib\
	$(L)VerL.lib\
	$(L)crc32.obj\
	$(L)implodel.obj\
	$(L)libentry.obj\
	$(L)nocrt0.obj

