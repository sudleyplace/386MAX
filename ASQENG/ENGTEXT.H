/*' $Header:   P:/PVCS/MAX/ASQENG/ENGTEXT.H_V   1.3   29 Feb 1996 10:54:08   HENRY  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-93 Qualitas, Inc.  GNU General Public License version 3.		      *
 *									      *
 * ENGTEXT.H								      *
 *									      *
 * ASQ Engine message definitions					      *
 *									      *
 ******************************************************************************/

/*
 * Shared definitions
 */
#define CONFIG_SYS "CONFIG.SYS"
#define AUTOEXEC_BAT "AUTOEXEC.BAT"

#ifdef MEM_INFO_C

/* mem_info.c - formatting routines for memory screens */

#ifdef LANG_GR
#define MSG1001 "Division / 0"
#define MSG1002 "Einzelschritt"
#define MSG1003 "NMI-Interrupt"
#define MSG1004 "Haltepunkt"
#define MSG1005 "öberlauf"
#define MSG1006 "PrtScr (Druck)"
#define MSG1007 "reserviert"
#define MSG1008 "reserviert"
#define MSG1009 "Tageszeit"
#define MSG1010 "Tastatur"
#define MSG1011 "@0IRQ 2 (Kaskade)"
#define MSG1012 "IRQ 3 (COM2)"
#define MSG1013 "IRQ 4 (COM1)"
#define MSG1014 "@1IRQ 5 (2. Drucker)"
#define MSG1015 "IRQ 6 (Diskette)"
#define MSG1016 "IRQ 7 (Drucker)"
#define MSG1017 "Video"
#define MSG1018 "Maschinen-Check"
#define MSG1019 "Speicher"
#define MSG1020 "Diskette/Platte"
#define MSG1021 "Kommunikation"
#define MSG1022 "Kassette"
#define MSG1023 "Tastatur"
#define MSG1024 "Drucker"
#define MSG1025 "residentes BASIC"
#define MSG1026 "Bootstrap"
#define MSG1027 "Tageszeit"
#define MSG1028 "Tastatur-Break"
#define MSG1029 "Zeitgeber (Timer)"
#define MSG1030 "Video-Initialisierg."
#define MSG1031 "Disketten-Parameter"
#define MSG1032 "Video-Grafik-Zeichen"
#define MSG1033 "DOS Programm-Ende"
#define MSG1034 "DOS Funktions-Aufruf"
#define MSG1035 "DOS PGM-Ende-Adresse"
#define MSG1036 "DOS Ctrl-Break-Adr."
#define MSG1037 "DOS schwerer Fehler"
#define MSG1038 "DOS abs.Disk-Lesen"
#define MSG1039 "DOS abs.Disk-Schreiben"
#define MSG1040 "DOS TSR"
#define MSG1041 "DOS Leerlauf (Idle)"
#define MSG1042 "reserviert fÅr DOS"
#define MSG1043 "DOS Netzwerk"
#define MSG1044 "reserviert fÅr DOS"
#define MSG1045 "DOS Multiplex"
#define MSG1046 "reserviert fÅr DOS"
#define MSG1047 "Maus"
#define MSG1048 "reserviert fÅr DOS"
#define MSG1049 "reserviert"
#define MSG1050 "Param. Festplatte 1"
#define MSG1051 "reserviert"
#define MSG1052 "Zeichensatz-Tabelle"
#define MSG1053 "reserviert"
#define MSG1054 "Param. Festplatte 2"
#define MSG1055 "reserviert"
#define MSG1056 "Alarm-Handler"
#define MSG1057 "reserviert"
#define MSG1058 "User-Interrupt"
#define MSG1059 "EMS-Anforderung"
#define MSG1060 "nicht benutzt"
#define MSG1061 "IRQ 8 (CMOS RTC)"
#define MSG1062 "IRQ 9 (IRQ 2-Umleitg)"
#define MSG1063 "IRQ 10"
#define MSG1064 "IRQ 11"
#define MSG1065 "IRQ 12 (Maus)"
#define MSG1066 "IRQ 13 (Koprozessor)"
#define MSG1067 "IRQ 14 (Festplatte)"
#define MSG1068 "IRQ 15"
#define MSG1069 "nicht benutzt"
#define MSG1070 "reserviert v. BASIC"
#define MSG1071 "benutzt v. BASIC"
#define MSG1072 "nicht benutzt"
#else
#define MSG1001 "Divide by Zero"
#define MSG1002 "Single Step"
#define MSG1003 "Nonmaskable"
#define MSG1004 "Breakpoint"
#define MSG1005 "Overflow"
#define MSG1006 "Print Screen"
#define MSG1007 "Reserved"
#define MSG1008 "Reserved"
#define MSG1009 "Time of Day"
#define MSG1010 "Keyboard"
#define MSG1011 "@0IRQ 2 (Cascade)"
#define MSG1012 "IRQ 3 (COM2)"
#define MSG1013 "IRQ 4 (COM1)"
#define MSG1014 "@1IRQ 5 (Alt. Printer)"
#define MSG1015 "IRQ 6 (Diskette)"
#define MSG1016 "IRQ 7 (Printer)"
#define MSG1017 "Video"
#define MSG1018 "Equipment Check"
#define MSG1019 "Memory"
#define MSG1020 "Diskette/Disk"
#define MSG1021 "Communications"
#define MSG1022 "Cassette"
#define MSG1023 "Keyboard"
#define MSG1024 "Printer"
#define MSG1025 "Resident BASIC"
#define MSG1026 "Bootstrap"
#define MSG1027 "Time of Day"
#define MSG1028 "Keyboard Break"
#define MSG1029 "Timer Tick"
#define MSG1030 "Video Initialization"
#define MSG1031 "Diskette Parameters"
#define MSG1032 "Video Graphics Chars"
#define MSG1033 "DOS Prgm. Terminate"
#define MSG1034 "DOS function call"
#define MSG1035 "DOS terminate addr."
#define MSG1036 "DOS Ctrl Break addr."
#define MSG1037 "DOS fatal error"
#define MSG1038 "DOS Abs. Disk Read"
#define MSG1039 "DOS Abs. Disk Write"
#define MSG1040 "DOS TSR"
#define MSG1041 "DOS Idle"
#define MSG1042 "Reserved for DOS"
#define MSG1043 "DOS Network"
#define MSG1044 "Reserved for DOS"
#define MSG1045 "DOS Multiplex"
#define MSG1046 "Reserved for DOS"
#define MSG1047 "Mouse"
#define MSG1048 "Reserved for DOS"
#define MSG1049 "Reserved"
#define MSG1050 "Fixed Disk 1 Params"
#define MSG1051 "Reserved"
#define MSG1052 "Character Table"
#define MSG1053 "Reserved"
#define MSG1054 "Fixed Disk 2 Params"
#define MSG1055 "Reserved"
#define MSG1056 "Alarm Handler"
#define MSG1057 "Reserved"
#define MSG1058 "User Interrupt"
#define MSG1059 "EMS Request"
#define MSG1060 "Not used"
#define MSG1061 "IRQ 8 (CMOS RTC)"
#define MSG1062 "IRQ 9 (IRQ 2 Redir.)"
#define MSG1063 "IRQ 10"
#define MSG1064 "IRQ 11"
#define MSG1065 "IRQ 12 (Mouse)"
#define MSG1066 "IRQ 13 (Coprocessor)"
#define MSG1067 "IRQ 14 (Fixed Disk)"
#define MSG1068 "IRQ 15"
#define MSG1069 "Not used"
#define MSG1070 "Reserved by BASIC"
#define MSG1071 "Used by BASIC"
#define MSG1072 "Not used"
#endif

/* Alternate titles for PC/XT interrupts */
#ifdef LANG_GR
#define MSG1073 "IRQ 2 (reserviert)"
#define MSG1074 "IRQ 5 (Festplatte)"
#else
#define MSG1073 "IRQ 2 (Reserved)"
#define MSG1074 "IRQ 5 (Fixed Disk)"
#endif

/*
 *	Memory_Summary - build text for Memory / Summary screen
 */

#ifdef LANG_GR
#define MSG1075 "DOS-System"
#define MSG1076 "Einheiten-Treiber"
#define MSG1077 "Seiten-Rahmen"
#define MSG1078 "unbekannt"
#define MSG1079 "verfÅgbar"
#define MSG1080 "LoDOS gesamt"
#define MSG1082 "nicht installiert"
#define MSG1084 "Video"
#define MSG1085 "Seiten-Rahmen"
#define MSG1189 "RAM"
#define MSG1086 "ROM"
#define MSG1190 "RAM oder ROM"
#define MSG1087 "UMB-Bereich"
#define MSG1087A "Teilsegmente"
#define MSG1088 "unbekannt"
#define MSG1089 "unbenutzt"
#define MSG1090 "verfÅgbar"
#define MSG1091 "HiDOS gesamt"
#define MSG1093 "ExTended verfÅgbar"
#define MSG1094 "ExTended gesamt   "
#define MSG1096 "phys. Speicher gesamt"
#define MSG1098 "ExPanded verfÅgbar"
#define MSG1099 "ExPanded gesamt   "
#define MSG1193 "EMS+XMS  gesamt   "
#else
#define MSG1075 "DOS System"
#define MSG1076 "Device Drivers"
#define MSG1077 "Page Frame"
#define MSG1078 "Unknown"
#define MSG1079 "Available"
#define MSG1080 "Total Low DOS"
#define MSG1082 "Not Installed"
#define MSG1084 "Video"
#define MSG1085 "Page Frame"
#define MSG1189 "RAM"
#define MSG1086 "ROM"
#define MSG1190 "RAM or ROM"
#define MSG1087 "Upper Memory Blocks"
#define MSG1087A "Subsegments"
#define MSG1088 "Unknown"
#define MSG1089 "Unused"
#define MSG1090 "Available"
#define MSG1091 "Total High DOS"
#define MSG1093 "Available Extended"
#define MSG1094 "Total Extended"
#define MSG1096 "Total Physical Memory"
#define MSG1098 "Available Expanded"
#define MSG1099 "Total Expanded"
#define MSG1193 "Total EMS+XMS Memory"
#endif

/*
 *	Memory_Low_DOS - build text for Memory / Low DOS screen
 */

#ifdef LANG_GR
#define MSG1100 "              Anfang     LÑnge  Programm-Umgebung"
#define MSG1101 "Name           hex.       dez.  oder Attrib.-Bits"
#else
#define MSG1100 "                       Decimal  Pgm Environment"
#define MSG1101 "Name         Hex Start  Length  or Attribute Bits"
#endif

/*
 *	Memory_High_DOS - build text for Memory / High DOS screen
 */

#ifdef LANG_GR
#define MSG1105 "              Anfang     LÑnge"
#define MSG1106 "Name           hex.       dez.  Programm-Umgebung"
#else
#define MSG1105 "                       Decimal"
#define MSG1106 "Name         Hex Start  Length  Pgm Environment"
#endif

/*
 *	Memory_ROM_Scan - build text for Memory / ROM Scan screen
 */

#ifdef LANG_GR
#define MSG1109 " Bereich    Grî·e  RAM   HiDOS   ROM  EMS  unben."
#else
#define MSG1109 "  Region     Size  RAM  HighDOS  ROM  EMS  Unused"
#endif


/*
 *	Memory_Interrupts - build text for Memory / Interrupts screen
 */

#ifdef LANG_GR
#define MSG1112 "Interrupts nach Anwendungs-Progammen"
#define MSG1114 "Name        Hex Anfang Interrupt-Nummern"

#define MSG1119 "Interrupts nach Nummern"
#define MSG1121 "Interrupt-Titel      ##  Name          Adresse"
#define MSG1122 "ohne"
#else
#define MSG1112 "Interrupts by User Program"
#define MSG1114 "Name         Hex Start Interrupt Numbers"

#define MSG1119 "Interrupts by Number"
#define MSG1121 "Interrupt Title      ##  Name          Address"
#define MSG1122 "None"
#endif

/*
 *	Memory_Extended - build text for Memory / Extended screen
 */

#ifdef LANG_GR
#define MSG1125 "Extended Memory nicht vorhanden"
#define MSG1126 "Gesamt-Extended-Memory"
#define MSG1128 "Belegung           Hex Anfang Grî·e"
#define MSG1130 "verfÅgbar"
#define MSG1131 "benutzt"
#else
#define MSG1125 "Extended memory not present"
#define MSG1126 "Total Extended Memory"
#define MSG1128 "Usage              Hex Start   Size"
#define MSG1130 "Available"
#define MSG1131 "Used"
#endif

/*
 *	Memory_Expanded - build text for Memory / Expanded screen
 */

#ifdef LANG_GR
#define MSG1132 "kein EMS-Speicher vorhanden"
#define MSG1133 "EMS Version"
#define MSG1165 "VCPI Version"
#define MSG1166 "Windows Version"
#define MSG1134 "Rahmen"
#define MSG1135 "abbildbare physikalische Seiten"
#define MSG1136 "EMS Handles"
#define MSG1137 "Alternat. Map-Register-Sets (AMRS)"
#define MSG1139 "Handle"
#define MSG1141 "verfÅgbar"
#define MSG1142 "gesamt"
#else
#define MSG1132 "No EMS memory present."
#define MSG1133 "EMS Version"
#define MSG1165 "VCPI Version"
#define MSG1166 "Windows Version"
#define MSG1134 "Frame"
#define MSG1135 "Mappable Physical Pages"
#define MSG1136 "EMS Handles"
#define MSG1137 "Alternate Map Register Sets (AMRS)"
#define MSG1139 "Handle"
#define MSG1141 "Available"
#define MSG1142 "Total"
#endif

/*
 *	Memory_EMS_Usage - build text for Memory / EMS Usage screen
 */

#ifdef LANG_GR
#define MSG1144 "kein EMS-Speicher vorhanden"
#define MSG1146 "EMS 4.0 nicht unterstÅtzt"
#define MSG1147 "LoDOS"
#define MSG1148 "0   1   2   3   4   5   6   7   8   9"
#define MSG1150 "Seite"
#define MSG1152 "HiDOS"
#define MSG1153 "A   B   C   D   E   F   1 MB"
#define MSG1157 "Unbenutzt"
#define MSG1158 "DOS"
#define MSG1160 "Rahmen"
#define MSG1161 "ROM"
#define MSG1191 "RAM"
#define MSG1192 "Video"
#else
#define MSG1144 "No EMS memory present."
#define MSG1146 "EMS 4.0 not supported."
#define MSG1147 "Low DOS"
#define MSG1148 "0   1   2   3   4   5   6   7   8   9"
#define MSG1150 "EMS Page"
#define MSG1152 "High DOS"
#define MSG1153 "A   B   C   D   E   F   1 MB"
#define MSG1157 "Unused"
#define MSG1158 "DOS"
#define MSG1160 "Frame"
#define MSG1161 "ROM"
#define MSG1191 "RAM"
#define MSG1192 "Video"
#endif

/*
 *	Memory_XMS - build text for Memory / XMS screen
 */

#ifdef LANG_GR
#define MSG1162 "kein XMS Speicher vorhanden."
#define MSG1188 "VDISK/Weitek vorhanden. XMS nicht verfÅgbar."
#define MSG1163 "Version"
#define MSG1164 "Treiber"
/*	MSG1165 & MSG1166 moved to EMS screen */
#define MSG1168 "verfÅgbarer UMB Speicher"
#define MSG1169 "grî·ter verfÅgbarer UMB-Bereich"
#define MSG1170 "verfÅgbarer XMS Speicher (EMB)"
#define MSG1171 "grî·ter verfÅgbarer EMB-Bereich"
#define MSG1173 "nicht belegt"
#define MSG1174 "belegt"
#define MSG1175 "nicht vorhanden"
#define MSG1176 "HMA Bereich"
#define MSG1177 "EMB-Handles verfÅgbar"
#define MSG1178 "A20 Adressleitung"
#define MSG1194 "DPMI Version"
#define MSG1195 "32-bit-Programme unterstÅtzt"
#define MSG1196 "Ja"
#define MSG1197 "Nein"
#define MSG1179 "in Betrieb"
#define MSG1180 "au·er Betrieb"
#else
#define MSG1162 "No XMS memory present."
#define MSG1188 "VDISK/Weitek present.  XMS not available."
#define MSG1163 "Version"
#define MSG1164 "Driver"
/*	MSG1165 & MSG1166 moved to EMS screen */
#define MSG1168 "Avail High DOS Upper Memory (UMB)"
#define MSG1169 "Largest Available UMB Area"
#define MSG1170 "Available XMS Memory (EMB)"
#define MSG1171 "Largest Available EMB Area"
#define MSG1173 "Not In Use"
#define MSG1174 "In Use"
#define MSG1175 "Does Not Exist"
#define MSG1176 "High Memory Area (HMA)"
#define MSG1177 "EMB Handles Available"
#define MSG1178 "A20 Address Line"
#define MSG1194 "DPMI Version"
#define MSG1195 "32-bit Programs Supported"
#define MSG1196 "Yes"
#define MSG1197 "No"
#define MSG1179 "Enabled"
#define MSG1180 "Disabled"
#endif

/*
 *	Memory_Timing - build text for Memory / Timing screen
 */

#ifdef LANG_GR
#define MSG1181 "Anfang Anfang  Grî·e  Zugriffszeit-Relation (%%)"
#define MSG1182 " Hex.    KB     KB   Zeit Ês 0   25   50  75  100"
#else
#define MSG1181 "  Hex     KB     KB   Access Speed Ratio (%%)"
#define MSG1182 "Start  Start   Size  Time Ês 0   25   50  75  100"
#endif

/* Last message used:  1195 */

#endif /* MEM_INFO_C */

#ifdef CFG_INFO_C

/* cfg_info.c - formatting routines for configuration screens */

/*
 *	Config_Summary - build text for Configuration / Sumary screen
 */

#ifdef LANG_GR

#define MSG2001 "DOS-Version"
#define MSG2002 "Files"
#define MSG2012 "einschl."
#define MSG2014 "im DOS"
#define MSG2003 "Buffers"
#define MSG2004 "FCBs"
#define MSG2005 "Stacks"
#define MSG2006 "Lastdrive"
#define MSG2007 "Break"
#define MSG2008 "ON"
#define MSG2009 "OFF"
#define MSG2051 "von CONFIG.SYS"
#define MSG2010 "SHELL="
#define MSG2011 "COUNTRY="
#define MSG2013 "DRIVPARM="
#define MSG2016 "Environment"
#define MSG2017 "Grî·e"
#define MSG2018 "benutzt"
#define MSG2019 "Byte"

#define MSG2032 "Offene FCBs"
#define MSG2033 "und Dateien"
#define MSG2034 ""

#define MSG2034A "Windows Verzeichnis"
#define MSG2034B "Windows Version"
#define MSG2034C "Windows Dateien:"

#define MSG2043 "%s Datei in %c:\\ nicht gefunden"
#define MSG2043A "%s Datei nicht gefunden"
#define MSG2045 "kein Qualitas .PRO-Dateibezug in " CONFIG_SYS
#define MSG2045A "kein ExtraDOS .PRO-Dateibezug in " CONFIG_SYS

#define MSG2045B "Windows Verzeichnis nicht gefunden"
#define MSG2045C "Qualitas Dateien:"
#define MSG2045D "Residente Programme:"
#define MSG2045E "Maximize Byte hochgeladen"
#define MSG2045F "Programme von Maximize hochgeladen:"
#define MSG2045G "Programme von Maximize im LoDOS belassen:"
#define MSG2045H1 \
" Typ           Initialisierung   Residente Grî·e - Region Gruppe Anford. Reihenfolge"
#define MSG2045H1L \
" Typ           Initialisierung   Residente Grî·e - Gruppe Anforderung"
#define MSG2045H1S \
" Name          Initialisierung   Residente Grî·e - Region Gruppe Anford. Schalter"
#define MSG2045H2 \
"               Programm   Env.   Programm   Env."
#define MSG2045I "Max"
#define MSG2045J "UMB"
#define MSG2045K "COMMAND.COM"
#define MSG2045L "Device"
#define MSG2045M "INSTALL="
#define MSG2045N "TSR"
#define MSG2045O "Teilseg (%c)"
#define MSG2045P "ExtraDOS (%c)"
#define MSG2045Q "Maximum"

#define MSG2045R1 "FLEXFRAME Fehler"
#define MSG2045R2 "FLEXFRAME benîtigt"
#define MSG2045R3 "FLEXFRAME erlaubt"
#define MSG2045R4 "LoDOS erzwungen"
#define MSG2045R5 "Beste Folge"
#define MSG2045R6 "Letzte Folge"

#define MSG2046 "Datei"
#define MSG2046A " Datei            Grî·e    Zeit   Datum"
#define MSG2047 "Datum"
#define MSG2048 "Zeit"
#define MSG2049 "Titel"
#define MSG2050 "keine Snapshot-Datei geladen"

#else

#define MSG2001 "DOS Version"
#define MSG2002 "Files"
#define MSG2012 "including"
#define MSG2014 "in DOS"
#define MSG2003 "Buffers"
#define MSG2004 "FCBs"
#define MSG2005 "Stacks"
#define MSG2006 "Lastdrive"
#define MSG2007 "Break"
#define MSG2008 "ON"
#define MSG2009 "OFF"
#define MSG2051 "From CONFIG.SYS"
#define MSG2010 "SHELL="
#define MSG2011 "COUNTRY="
#define MSG2013 "DRIVPARM="
#define MSG2016 "Environment"
#define MSG2017 "Size"
#define MSG2018 "Used"
#define MSG2019 "bytes"

#define MSG2032 "Open FCBs"
#define MSG2033 "Open Files"
#define MSG2034 ""

#define MSG2034A "Windows directory"
#define MSG2034B "Windows version"
#define MSG2034C "Windows files:"

#define MSG2043 "%s file not found in %c:\\"
#define MSG2043A "%s file not found"
#define MSG2045 "No Qualitas PROfile referenced in " CONFIG_SYS
#define MSG2045A "No ExtraDOS PROfile referenced in " CONFIG_SYS
#define MSG2045B "Windows directory not found"
#define MSG2045C "Qualitas files:"
#define MSG2045D "Resident programs:"
#define MSG2045E "Maximize bytes moved high"
#define MSG2045F "Programs moved high by Maximize:"
#define MSG2045G "Programs left low by Maximize:"
#define MSG2045H1 \
" Type          Initialization    Resident size -- Region Group Request Order"
#define MSG2045H1L \
" Type          Initialization    Resident size -- Group Request"
#define MSG2045H1S \
" Name          Initialization    Resident size -- Region Group Request Flags"
#define MSG2045H2 \
"               program    env    program    env"
#define MSG2045I "Max"
#define MSG2045J "UMB"
#define MSG2045K "COMMAND.COM"
#define MSG2045L "Device"
#define MSG2045M "INSTALL="
#define MSG2045N "TSR"
#define MSG2045O "Subseg (%c)"
#define MSG2045P "ExtraDOS (%c)"
#define MSG2045Q "maximum"

#define MSG2045R1 "FLEXFRAME error"
#define MSG2045R2 "FLEXFRAME required"
#define MSG2045R3 "FLEXFRAME allowed"
#define MSG2045R4 "Forced low"
#define MSG2045R5 "Best fit"
#define MSG2045R6 "Last fit"

#define MSG2046 "File"
#define MSG2046A " File             Size     Time   Date"
#define MSG2047 "Date"
#define MSG2048 "Time"
#define MSG2049 "Title"
#define MSG2050 "No snapshot file loaded."

#endif

/* Last message used:  2052 */

#endif /* CFG_INFO_C */

#ifdef HDW_INFO_C

/* hdw_info.c - formatting routines for hardware screens */

/* CMOS Titles */
#ifdef LANG_GR

#define MSG3016 "Sekunden"
#define MSG3017 "Sekunden-Alarm"
#define MSG3018 "Minuten"
#define MSG3019 "Minuten-Alarm"
#define MSG3020 "Stunden"
#define MSG3021 "Stunden-Alarm"
#define MSG3022 "Wochentag"
#define MSG3023 "Monatsdatum"
#define MSG3024 "Monat"
#define MSG3025 "Jahr"
#define MSG3026 "Status Register A"
#define MSG3027 "Status Register B"
#define MSG3028 "Status Register C"
#define MSG3029 "Status Register D"
#define MSG3030 "Diagnose-Status"
#define MSG3031 "Shutdown-Status"
#define MSG3032 "Disketten-Typen"
#define MSG3033 "reserviert"
#define MSG3034 "Festplatten-Typen"
#define MSG3035 "reserviert"
#define MSG3036 "GerÑte-Byte"
#define MSG3037 "Basisspeicher [Byte 0]"
#define MSG3038 "Basisspeicher [Byte 1]"
#define MSG3039 "Erw.-Speicher [Byte 0]"
#define MSG3040 "Erw.-Speicher [Byte 1]"

/* This group is only used on non-PS/2 machines */
#define MSG3041 "Erweiterung Festplatte 1"
#define MSG3042 "Erweiterung Festplatte 2"
#define MSG3043 "reserviert"
#define MSG3044 "CMOS-PrÅfsumme"
#define MSG3045 "Erw.-Speicher [Byte 0]"
#define MSG3046 "Erw.-Speicher [Byte 1]"
#define MSG3047 "Jahrhundert"
#define MSG3048 "Informations-Kennz."
#define MSG3049 "reserviert"

/* This group is only used on PS/2 machines */
#define MSG3050 "reserviert"
#define MSG3051 "CMOS-PrÅfsumme"
#define MSG3052 "reserviert"
#define MSG3053 "Erw.-Speicher [Byte 0]"
#define MSG3054 "Erw.-Speicher [Byte 1]"
#define MSG3055 "Jahrhundert"
#define MSG3056 "reserviert"

/* Names of the months */
#define MSG3058 "Januar"
#define MSG3059 "Februar"
#define MSG3060 "MÑrz"
#define MSG3061 "April"
#define MSG3062 "Mai"
#define MSG3063 "Juni"
#define MSG3064 "Juli"
#define MSG3065 "August"
#define MSG3066 "September"
#define MSG3067 "Oktober"
#define MSG3068 "November"
#define MSG3069 "Dezember"

#else

#define MSG3016 "Seconds"
#define MSG3017 "Second Alarm"
#define MSG3018 "Minutes"
#define MSG3019 "Minute Alarm"
#define MSG3020 "Hours"
#define MSG3021 "Hour Alarm"
#define MSG3022 "Day of Week"
#define MSG3023 "Date of Month"
#define MSG3024 "Month"
#define MSG3025 "Year"
#define MSG3026 "Status Register A"
#define MSG3027 "Status Register B"
#define MSG3028 "Status Register C"
#define MSG3029 "Status Register D"
#define MSG3030 "Diagnostic Status"
#define MSG3031 "Shutdown Status"
#define MSG3032 "Diskette Types"
#define MSG3033 "Reserved"
#define MSG3034 "Fixed Disk Types"
#define MSG3035 "Reserved"
#define MSG3036 "Equipment Byte"
#define MSG3037 "Low Base Memory"
#define MSG3038 "High Base Memory"
#define MSG3039 "Low Expansion Memory"
#define MSG3040 "High Expansion Memory"

/* This group is only used on non-PS/2 machines */
#define MSG3041 "Fixed Disk 1 Extension"
#define MSG3042 "Fixed Disk 2 Extension"
#define MSG3043 "Reserved"
#define MSG3044 "CMOS Checksum"
#define MSG3045 "Low Expansion Memory"
#define MSG3046 "High Expansion Memory"
#define MSG3047 "Date Century"
#define MSG3048 "Information Flags"
#define MSG3049 "Reserved"

/* This group is only used on PS/2 machines */
#define MSG3050 "Reserved"
#define MSG3051 "CMOS Checksum"
#define MSG3052 "Reserved"
#define MSG3053 "Low Expansion Memory"
#define MSG3054 "High Expansion Memory"
#define MSG3055 "Date Century"
#define MSG3056 "Reserved"

/* Names of the months */
#define MSG3058 "January"
#define MSG3059 "February"
#define MSG3060 "March"
#define MSG3061 "April"
#define MSG3062 "May"
#define MSG3063 "June"
#define MSG3064 "July"
#define MSG3065 "August"
#define MSG3066 "September"
#define MSG3067 "October"
#define MSG3068 "November"
#define MSG3069 "December"

#endif

/*
 *	Hardware_Summary - build text for Hardware / Summary screen
 */

#ifdef LANG_GR

#define MSG3070 "PC"
#define MSG3071 "XT"
#define MSG3072 "386-er Klasse"
#define MSG3073 "486-er Klasse"
#define MSG30P5 "Pentium Klasse"
#define MSG30P6 "Pentium Pro Klasse"
#define MSG3074 "AT"
#define MSG3075 "PS/2"

#define MSG3076 "PS/2 Modell 30"
#define MSG3077 "PS/2 Modell 50"
#define MSG3078 "PS/2 Modell 60"
#define MSG3079 "PS/2 Modell 55"
#define MSG3080 "PS/2 Modell 70"
#define MSG3081 "PS/2 Modell 80"
#define MSG3245 "PS/2 Modell 95"
#define MSG3247 "PS/2 Modell 40"
#define MSG3248 "PS/2 Modell 70 486"
#define MSG3082 "PS/2"
#define MSG3083 "unbekannt"
#define MSG3084 "Computer-Typ"
#define MSG3246 "(V86-Modus)"
#define MSG3128 "DOS"
#define MSG3085 "DOS-Betriebssystem"
#define MSG3086 "Hauptprozessor (CPU)"
#define MSG3087 "frÅhe Ausgabe des 80387"
#define MSG3088 ", "
#define MSG3089 "Weitek"
#define MSG3090 "Koprozessor"
#define MSG3091 "CPU-Takt in MHz"
//#error Translate
#define	MSG3091C "CPU ID"

#define MSG3092 "MC"
#define MSG3093 "EISA"
#define MSG3094 "ISA"
//#error Check translation (?)
#define	MSG309P	"PCI"
#define	MSG309PV "PCI v%u.%02u"
#define MSG3095 "Bus-Typ"
#define MSG3096 "BIOS Hersteller"
#define MSG3097 "BIOS Ausgabe-Datum"
#define MSG3098 "BIOS Modell"
#define MSG3099 "BIOS Untermodell"
#define MSG3100 "BIOS Revision"
#define MSG3101 "BIOS CRC"

#define MSG3102 "AT/386"
#define MSG3103 "NEAT"
#define MSG3104 "NEAT mit < 1 MB"
#define MSG3105 "VLSI"
#define MSG3106 "nicht verfÅgbar"
#define MSG3107 "Chipsatz"
#define MSG3108 "Disketten laut BIOS"
#define MSG3109 "Festplatten laut BIOS"
#define MSG3110 "logische Platten"
#define MSG3110C "CD-ROM Laufwerk"
#define MSG3133 "bis"
#define MSG3259 "Disk-Cache"
#define MSG3260 "ohne"
#define MSG3261 "nur Lesezugriffe"
/* #define MSG3262 "schreibt sofort" */
#define MSG3262 "Write through"
#define MSG3265 "Delayed write (%.1f sec)"
#define MSG3266 "Nicht-BIOS Laufw. (SCSI oder RAM-Disk)"
#define MSG3111 "Video-Adapter"
#define MSG3112 "Video-Modus"
#define MSG3113 "COM"
#define MSG3114 "serielle Ports"
#define MSG3115 "LPT"
#define MSG3116 "parallele Ports"
#define MSG3117 "erweitert"
#define MSG3118 "Standard"
#define MSG3119 "Tastatur"

#define MSG3249 "Maus"
#define MSG3250 "unbekannter Typ"
#define MSG3251 "Bus"
#define MSG3252 "seriell"
#define MSG3253 "InPort"
#define MSG3254 "PS/2"
#define MSG3255 "HP"
#define MSG3256 "Game-Adapter"
#define MSG3257 "installiert"
#define MSG3258 "nicht installiert"

#define MSG3120 "LIM Standard"
#define MSG3242 "System-Zeit"
#define MSG3122 "System-Datum"
#define MSG3124 "System-Basisspeicher"
#define MSG3125 "Speicher-Erweiterung"
#define MSG3127 "Disketten-Laufwerke"
#define MSG3130 "Typ"
#define MSG3131 "nicht verfÅgbar"
#define MSG3132 "Festplatte"

#define MSG3137 "MC-Konfiguration"
#define MSG3139 "Slot  ID  Adapter-Name"
#define MSG3141 "Systemplatine"

#define	MSG314P "Plug and Play Konfiguration"
#define	MSG314P1 "Version"
#define MSG314P2 "Total nodes"

// Small resources
#define	MSGP_VER	"Ver %u.%02u"
#define	MSGP_IRQ	"IRQ"
#define	MSGP_IRQHI	" High"
#define	MSGP_IRQLO	" Low"
#define	MSGP_DMACH	"DMA ch"
#define	MSGP_BUS	" Busmaster"
#define	MSGP_8BITONLY	" nur 8-Bit"
#define	MSGP_EISADMA	" EISA-Typ"
#define	MSGP_IORANGEALIGN "I/O mit %d Byte von %x-%x, Ausrichtung %d%s"
#define	MSGP_IO16BIT	", 16-Bit"
#define	MSGP_IO		"I/O %x"
#define	MSGP_IORANGE	"I/O %x-%x"

// Memory type decoding
#define	MSGP_MEMROM	" ROM"
#define	MSGP_MEMSHADOW	" Shadowed"
#define	MSGP_MEMEXPAND	" Erweiterung"
#define	MSGP_MEMCACHE	" Cacheable"

// Large resources
#define	MSGP_MEM16	"Mem16: Anfang %04x00-%04x00, LÑnge %04x00, Ausrichtung %d%s"
#define	MSGP_ID		"ID: %.40s"
#define	MSGP_MEM32	"Mem32: Anfang %lx-%lx, LÑnge %lx, Ausrichtung %ld%s"
#define	MSGP_MEM32F	"Speicher: %lx-%lx%s"

// Node attributes
#define	MSGP_NREMOVABLE	" entnehmbar"
#define	MSGP_NDOCKING	" Docking-Station"
#define	MSGP_NBOOTABLE	" Boot-fÑhig"
#define	MSGP_NINPUT	" Input"
#define	MSGP_NOUTPUT	" Output"

#else

#define MSG3070 "PC"
#define MSG3071 "XT"
#define MSG3072 "386 Class"
#define MSG3073 "486 Class"
#define MSG30P5 "Pentium"
#define MSG30P6 "Pentium Pro"
#define MSG3074 "AT"
#define MSG3075 "PS/2"

#define MSG3076 "PS/2 Model 30"
#define MSG3077 "PS/2 Model 50"
#define MSG3078 "PS/2 Model 60"
#define MSG3079 "PS/2 Model 55"
#define MSG3080 "PS/2 Model 70"
#define MSG3081 "PS/2 Model 80"
#define MSG3245 "PS/2 Model 95"
#define MSG3247 "PS/2 Model 40"
#define MSG3248 "PS/2 Model 70 486"
#define MSG3082 "PS/2"
#define MSG3083 "Unknown"
#define MSG3084 "Computer Type"
#define MSG3246 "(V86 mode)"
#define MSG3128 "DOS"
#define MSG3085 "DOS Operating System"
#define MSG3086 "Main Processor (CPU)"
#define MSG3087 "Early 80387"
#define MSG3088 ", "
#define MSG3089 "Weitek"
#define MSG3090 "Co-Processor"
#define MSG3091 "CPU Speed (megahertz)"
#define	MSG3091C "CPU ID"

#define MSG3092 "MC"
#define MSG3093 "EISA"
#define MSG3094 "ISA"
#define	MSG309P	"PCI"
#define	MSG309PV "PCI v%u.%02u"
#define MSG3095 "Bus Type"
#define MSG3096 "BIOS Manufacturer"
#define MSG3097 "BIOS Date Stamp"
#define MSG3098 "BIOS Model"
#define MSG3099 "BIOS Submodel"
#define MSG3100 "BIOS Revision"
#define MSG3101 "BIOS CRC"

#define MSG3102 "AT/386"
#define MSG3103 "NEAT"
#define MSG3104 "NEAT w/ < 1 MB"
#define MSG3105 "VLSI"
#define MSG3106 "N/A"
#define MSG3107 "Chipset"
#define MSG3108 "Diskettes Seen by BIOS"
#define MSG3109 "Fixed Disks Seen by BIOS"
#define MSG3110 "Logical Disk Drives"
#define MSG3110C "CD-ROM Drives"
#define MSG3133 "through"
#define MSG3259 "Disk Cache"
#define MSG3260 "None"
#define MSG3261 "Read Buffered"
#define MSG3262 "Write through"
#define MSG3265 "Delayed write (%.1f sec)"
#define MSG3266 "Non-BIOS drive (SCSI or RAMdisk)"
#define MSG3111 "Video Adapter"
#define MSG3112 "Video Mode"
#define MSG3113 "COM"
#define MSG3114 "Serial Ports"
#define MSG3115 "LPT"
#define MSG3116 "Parallel Ports"
#define MSG3117 "Enhanced"
#define MSG3118 "Standard"
#define MSG3119 "Keyboard"

#define MSG3249 "Mouse"
#define MSG3250 "Unknown Type"
#define MSG3251 "Bus"
#define MSG3252 "Serial"
#define MSG3253 "InPort"
#define MSG3254 "PS/2"
#define MSG3255 "HP"
#define MSG3256 "Game Adapter"
#define MSG3257 "Installed"
#define MSG3258 "Not Installed"

#define MSG3120 "LIM Standard"
#define MSG3242 "System Time"
#define MSG3122 "System Date"
#define MSG3124 "System Base Memory"
#define MSG3125 "Extended Memory"
#define MSG3127 "Diskette Drive"
#define MSG3130 "Type"
#define MSG3131 "N/A"
#define MSG3132 "Fixed Disk"

#define MSG3137 "MC Configuration"
#define MSG3139 "Slot  ID  Adapter Name"
#define MSG3141 "System Board"

#define	MSG314P "Plug and Play Configuration"
#define	MSG314P1 "Version"
#define MSG314P2 "Total nodes"

// Small resources
#define	MSGP_VER	"Ver %u.%02u"
#define	MSGP_IRQ	"IRQ"
#define	MSGP_IRQHI	" High"
#define	MSGP_IRQLO	" Low"
#define	MSGP_DMACH	"DMA ch"
#define	MSGP_BUS	" Bus master"
#define	MSGP_8BITONLY	" 8-bit only"
#define	MSGP_EISADMA	" EISA type"
#define	MSGP_IORANGEALIGN "I/O for %d bytes from %x-%x, alignment %d%s"
#define	MSGP_IO16BIT	", 16-bit"
#define	MSGP_IO		"I/O %x"
#define	MSGP_IORANGE	"I/O %x-%x"

// Memory type decoding
#define	MSGP_MEMROM	" ROM"
#define	MSGP_MEMSHADOW	" Shadowed"
#define	MSGP_MEMEXPAND	" Expansion"
#define	MSGP_MEMCACHE	" Cacheable"

// Large resources
#define	MSGP_MEM16	"Mem16: start %04x00-%04x00, length %04x00, align %d%s"
#define	MSGP_ID		"ID: %.40s"
#define	MSGP_MEM32	"Mem32: start %lx-%lx, length %lx, align %ld%s"
#define	MSGP_MEM32F	"Memory: %lx-%lx%s"

// Node attributes
#define	MSGP_NREMOVABLE	" removable"
#define	MSGP_NDOCKING	" docking-station"
#define	MSGP_NBOOTABLE	" bootable"
#define	MSGP_NINPUT	" input"
#define	MSGP_NOUTPUT	" output"

#endif

/*
 *	Hardware_Video - build text for Hardware / Video screen
 */

#ifdef LANG_GR

#define MSG3143 "Adapter-Typ"
#define MSG3161 "Hersteller"
#define MSG3162 "Modell"
#define MSG3144 "Speicher"
#define MSG3145 "Anzeige-Modus"
#define MSG3146 "KapazitÑt"
#define MSG3147 "Grafik-Speicher"
#define MSG3148 "ohne"
#define MSG3149 "Text-Speicher"
#define MSG3150 "ROM-Region"
#define MSG3151 "ohne"

#else

#define MSG3143 "Adapter Type"
#define MSG3161 "Adapter Vendor"
#define MSG3162 "Adapter Model"
#define MSG3144 "Adapter Memory"
#define MSG3145 "Display Mode"
#define MSG3146 "Display Size"
#define MSG3147 "Graphics Memory"
#define MSG3148 "None"
#define MSG3149 "Text Memory"
#define MSG3150 "ROM Region"
#define MSG3151 "None"

#endif

/*
 *	Hardware_Drives - build text for Hardware / Drives screen
 */


#ifdef LANG_GR

#define MSG3153 "Laufwerk        Grî·e   Kîpfe Zyl. Sektoren Typ"
#define MSG3156 "Diskette"
#define MSG3158 "n.v."
#define MSG3160 "Festplatte"

#else

#define MSG3153 "Drive            Size   Heads Cyls Sectors Type"
#define MSG3156 "Diskette"
#define MSG3158 "N/A"
#define MSG3160 "Fixed Disk"

#endif

/*
 *	Hardware_Ports - build text for Hardware / Ports screen
 */

#ifdef LANG_GR

#define MSG3164 "serieller"
#define MSG3165 "paralleler"
#define MSG3166 "Port"
#define MSG3167 " Adresse"

#else

#define MSG3164 "Serial"
#define MSG3165 "Parallel"
#define MSG3166 "Port"
#define MSG3167 "at Address"

#endif

/*
 *	Hardware_BIOS_Detail - build text for Hardware / BIOS Detail screen
 */

#ifdef LANG_GR

#define MSG3168 "BIOS Info      Hex-Anfang: Inhalt"
#define MSG3170 "serielle Port-Adressen"
#define MSG3171 "parallele Port-Adr."
#define MSG3173 "erweit. BIOS-Segment"
#define MSG3174 "install. Ausstattung"
#define MSG3175 "Hersteller-Test"
#define MSG3176 "Speicher-Grî·e in KB"
#define MSG3177 "Herst.-Fehler-Kennz."
#define MSG3178 "Tastatur-Kennzeichen"
#define MSG3179 "Tastatur-Anfang/Ende"
#define MSG3180 "Tastatur-Puffer"
#define MSG3181 ""
#define MSG3182 ""
#define MSG3183 ""
#define MSG3184 "Disk.-Laufwerks-Status"
#define MSG3185 "Disketten-Status"
#define MSG3186 "Monitor-Anzeige-Modus"
#define MSG3187 "Bild-Spalten Anzahl"
#define MSG3188 "Bild-Speicher LÑnge"
#define MSG3189 "Bild-Speicher Anfang"
#define MSG3190 "Cursor-Positionen"
#define MSG3191 ""
#define MSG3192 "Cursor-Modus"
#define MSG3193 "aktive Bild-Seite"
#define MSG3194 "aktive Kartenbasis"
#define MSG3195 "3x8 Register-Einstellg"
#define MSG3196 "Paletten-Einstellung"
#define MSG3197 "I/O ROM Init.-Zeiger"
#define MSG3198 "Interrupt-Kennzeichen"
#define MSG3199 "Zeitgeber-Wert [0] [1]"
#define MSG3200 "Tageswechsel (Rollover)"
#define MSG3201 "Break Bit (Bit 7)"
#define MSG3202 "Tastatur-Reset Kennz."
#define MSG3203 "Festplatten-Status"
#define MSG3204 "Anzahl Festplatten"
#define MSG3205 "Festpl.-Kontr.-Byte"
#define MSG3206 "Festpl.-Port Offset"
#define MSG3207 "Drucker-Timeout Kennz."
#define MSG3208 "serielle Timeout Kz."
#define MSG3209 "Tastatur-Puffer Anfang"
#define MSG3210 "Tastatur-Puffer Ende"
#define MSG3211 "Bildschirmzeilen -1"
#define MSG3212 "Zeichenhîhe"
#define MSG3213 "Video-Kontroll-Stati"
#define MSG3214 "div. Video-Infos"
#define MSG3215 "Media-Kontrolle"
#define MSG3216 "Festplatten-Status Reg."
#define MSG3217 "Festplatten-Fehler Reg."
#define MSG3218 "Festplatten-Int.-Kennz."
#define MSG3219 "Kombi-Kontroller-Kennz."
#define MSG3220 "aktuelle Zylinder"
#define MSG3221 "reserviert"
#define MSG3222 "Tastatur-Kennzeichen 2"
#define MSG3223 "Benutzer-Warte-Kennz."
#define MSG3224 "RTC Wort [0]:[1]"
#define MSG3225 "RTC Warte-Aktiv-Kz."
#define MSG3226 "reserviert"
#define MSG3227 "EGA-Struktur-Zeiger"

#else

#define MSG3168 "BIOS Item       Hex Start: Contents"
#define MSG3170 "Serial Port Addrs."
#define MSG3171 "Parallel Port Addrs."
#define MSG3173 "Extended BIOS Segment"
#define MSG3174 "Installed Equipment"
#define MSG3175 "Manufacturers Test"
#define MSG3176 "Memory Size in KB"
#define MSG3177 "Manuf. Error Flag"
#define MSG3178 "Keyboard Flag"
#define MSG3179 "Keyboard Head/Tail"
#define MSG3180 "Keyboard Buffer"
#define MSG3181 ""
#define MSG3182 ""
#define MSG3183 ""
#define MSG3184 "Diskette Drive Status"
#define MSG3185 "Diskette Status"
#define MSG3186 "CRT Display Mode"
#define MSG3187 "CRT Number Columns"
#define MSG3188 "CRT Regen Buffer Len."
#define MSG3189 "CRT Regen Buffer Start"
#define MSG3190 "Cursor Positions"
#define MSG3191 ""
#define MSG3192 "Cursor Mode"
#define MSG3193 "Active Page"
#define MSG3194 "Active Card Base"
#define MSG3195 "3x8 Register Setting"
#define MSG3196 "Palette Setting"
#define MSG3197 "I/O ROM Init. Pointer"
#define MSG3198 "Interrupt Flag"
#define MSG3199 "Timer Count Low/High"
#define MSG3200 "Timer Rollover Flag"
#define MSG3201 "Break Flag (Bit 7)"
#define MSG3202 "Keyboard Reset Flag"
#define MSG3203 "Fixed Disk Status"
#define MSG3204 "Number of Fixed Disks"
#define MSG3205 "Fixed Disk Ctrl. Byte"
#define MSG3206 "Fixed Disk Port Offset"
#define MSG3207 "Printer Timeout Flags"
#define MSG3208 "Serial Timeout Flags"
#define MSG3209 "Keyboard Buffer Start"
#define MSG3210 "Keyboard Buffer End"
#define MSG3211 "Display Rows Less 1"
#define MSG3212 "Character Height"
#define MSG3213 "Video Control States"
#define MSG3214 "Misc. Video Info."
#define MSG3215 "Media Control"
#define MSG3216 "Fixed Disk Status Reg."
#define MSG3217 "Fixed Disk Error Reg."
#define MSG3218 "Fixed Disk Int. Flag"
#define MSG3219 "Combined Cntrlr. Flag"
#define MSG3220 "Current Cylinders"
#define MSG3221 "Reserved"
#define MSG3222 "Keyboard Flag 2"
#define MSG3223 "User Wait Flag"
#define MSG3224 "RTC Low/High Word"
#define MSG3225 "RTC Wait Active Flag"
#define MSG3226 "Reserved"
#define MSG3227 "EGA Save Pointer"

#endif

/*
 *	Hardware_CMOS_Detail - build text for Hardware / CMOS Detail screen
 */

#ifdef LANG_GR
#define MSG3228 "kein CMOS-Speicher vorhanden."
#define MSG3229 "CMOS Information       Byte       Wert"
#else
#define MSG3228 "No CMOS memory present."
#define MSG3229 "CMOS Item              Byte      Value"
#endif

/*
 *	mca_slot - format text for one MCA bus slot
 */

#ifdef LANG_GR
#define MSG3235 "unbekannt"
#else
#define MSG3235 "Unknown"
#endif

/*
 * Display partition table
 */

#ifdef LANG_GR
#define MSG3239 "Partition  Typ  Anfang  Ende  aktiv"
#else
#define MSG3239 "Partition  Type  Begin  End  Active"
#endif

/* svga_memsize */

#ifdef LANG_GR
#define MSG3263 "unbekannt"
#define MSG3264 "mindestens 256 KB"
#else
#define MSG3263 "Unknown"
#define MSG3264 "At least 256 KB"
#endif

/* Last message used:  3264 */

#endif /* HDW_INFO_C */


#ifdef SYSINFO_C

/*
 *	sysinfo_init - collect system information
 */

#define MSG4001 "SysInfo"

/*
 *	get_bios_mfr - (try to) determine BIOS / machine manufacturer
 */

/* Part I:  Primary list */
#define MSG4120 "AST"

/* Very special case for AST machines */
#define MSG4121 "AST Premium 386 /20"
#define MSG4122 "AST Premium 386 /25"
#define MSG4123 "AST Premium 386 /SX"
#define MSG4124 "AST Premium 386 /16"
#define MSG4125 "AST Premium 386 /33"

/* Compaq:  another special case */
#define MSG4183 "Compaq"
#define MSG4184 "Portable"

/*
 *	get_video - get information about video subsystems
 */

/* Monochrome display adapter */
#define MSG4126 "MDA"
#ifdef LANG_GR
#define MSG4127 "Monochrom"
#else
#define MSG4127 "Monochrome"
#endif

/* Color Graphics adapter */
#define MSG4128 "CGA"
#ifdef LANG_GR
#define MSG4129 "Farbe"
#else
#define MSG4129 "Color"
#endif

/* Enhanced Graphics adapter */
#define MSG4130 "EGA"
#define MSG4131 MSG4127
#define MSG4132 MSG4129

/* Multi Color Graphics Array */
#define MSG4133 "MCGA"
#define MSG4134 MSG4127
#define MSG4135 MSG4129

/* Video Graphics Array */
#define MSG4136 "VGA"
#define MSG4188 "SVGA"
#define MSG4137 MSG4127
#define MSG4138 MSG4129

/* Hercules Graphics Card */
#define MSG4139 "HGC"
#define MSG4140 MSG4127

/* Hercules Graphics Card Plus */
#define MSG4141 "HGC+"
#define MSG4142 MSG4127

/* Hercules InColor Card */
#define MSG4143 "InCo"
#define MSG4144 MSG4127

/* XGA, 8514/a */
#define MSG4186 "XGA"
#define MSG4187 "8514"

/*
 *	get_driveparm - get parameters for one drive
 *	It is not necessary to change the decimal for internationalization.
 *	This is taken care of provided NUM_DECIMAL and NUM_COMMA are set
 *	properly in LIBTEXT.H
 */

#ifdef LANG_GR
	#define MSG4149 "unbekannt"
#else
	#define MSG4149 "Unknown"
#endif
	#define MSG4145 "360 KB"
	#define MSG4146 "1.2 MB"
	#define MSG4147 "720 KB"
	#define MSG4148 "1.44 MB"
	#define MSG4185 "2.88 MB"

#define MSG4150 "%.1f MB"

/*
 *	get_dosnames - get the real names of the DOS kernel files
 */

#define MSG4151 "%c:\\*.*"
#define MSG4152 "IBMDOS"
#define MSG4153 "IBMBIO"

/*
 *	get_config_params - get parameters from CONFIG.SYS
 */

#define MSG4154 "COMSPEC"
#define MSG4156 "PROMPT"
#ifdef LANG_GR
#define MSG4155 "unbekannt"
#define MSG4157 "Standard"
#define MSG4158 "PATH"
#define MSG4159 "ohne"
#else
#define MSG4155 "Unknown"
#define MSG4157 "Default"
#define MSG4158 "PATH"
#define MSG4159 "None"
#endif

/* Get the rest by (yuk!) reading CONFIG.SYS */
#define MSG4161 "%c:\\%s"

/* #define MSG4163-MSG4166 dead */
#define MSG4167 "shell"
#define MSG4168 "country"
#define MSG4169 "drivparm"
#define MSG4179 "device"

/*
 *	get_profile - read location of .pro file from DEVICE= line
 */

#define MSG4180 "386max.sys"
#define MSG4181 "bluemax.sys"
#define MSG4189 "move'em.mgr"
#define MSG4189A "extrados.max"
#define MSG4182 "pro="
/*
 *	add_filename - add name to list of open files
 */

#define MSG4170 "   "

/* MSG4171 */
/* MSG4172 */

#ifdef LANG_GR
#define MSG4175 "kein %s gefunden im Pfad %c:\\."
#else
#define MSG4175 "No %s found in path %c:\\."
#endif
#define MSG4176 "%c:\\%s"

#define MSG4177 "PRINT"
#define MSG4178 "FASTOPEN"


/* Last message used:  4189 */
#endif /* SYSINFO_C */

#ifdef MAPINFO_C

/* mapinfo.c - functions for building memory map */

/*
 *	make_umap - Make unified memory map list
 */

/* First item:	Interrupt vectors */
#define MSG5001 "Interrupts"

#ifdef LANG_GR

/* Second item:  BIOSdaten - Segment 40h */
#define MSG5002 "BIOS-Daten"

/* Third item:	Systemdatea - Segmente 50h u. 60H */
#define MSG5003 "System-Daten"

/* Sixth item:	Device Drivers */
#define MSG5004 "Einh-Treiber"

/* Seventh item:  DOS Files/Buffers */
#define MSG5005 "DOS-Daten"

/* Map Unused mem between end of DOS and 640k */
#define MSG5006 "-unbenutzt-"

#else

/* Second item:  BIOS Data - segment 40h */
#define MSG5002 "BIOS Data"

/* Third item:	System Data - segments 50h & 60H */
#define MSG5003 "System Data"

/* Sixth item:	Device Drivers */
#define MSG5004 "Device Drvrs"

/* Seventh item:  DOS Files/Buffers */
#define MSG5005 "DOS Data"

/* Map Unused mem between end of DOS and 640k */
#define MSG5006 "-Unused-"

#endif

/* Part II:  High DOS */

/* Map Extended BIOS, if any */
#define MSG5007 "Ext. BIOS"

/* Map the EMS page frame (if any) */
#ifdef LANG_GR
#define MSG5008 "Seitenrahmen"
#else
#define MSG5008 "Page Frame"
#endif

/* Map ROM BASIC if a real IBM system */
#define MSG5043 "ROM BASIC"

#ifdef LANG_GR
#define MSG5009 "- vor -"
#define MSG5010 "- nach -"
#else
#define MSG5009 "-Before-"
#define MSG5010 "-After-"
#endif

/*
 *	map_lowmem - build map for low DOS memory
 */

/* These are counted with -Available- */
#ifdef LANG_GR
#define MSG5011 "-verfÅgbar-"
#else
#define MSG5011 "-Available-"
#endif

/* This shouldn't actually appear in low memory */
#ifdef LANG_GR
#define MSG5012 "RAM o. ROM"
#else
#define MSG5012 "RAM or ROM"
#endif

/* This shouldn't actually appear in low memory */
#define MSG5013 "UMB"
#ifdef LANG_GR
#define MSG5014 "-unbekannt-"
#else
#define MSG5014 "-Unknown-"
#endif

/*
 *	map_highmem - build map for high DOS memory
 */

/* Dirty trick for 386MAX device driver */
#ifdef LANG_GR
#define MSG5015 "-verfÅgbar-"
#else
#define MSG5015 "-Available-"
#endif

/* XMS Upper Memory Block */
#define MSG5016 "UMB"

#ifdef LANG_GR
#define MSG5017 "-unbekannt-"
#define MSG5019 "-ungenannt-"
#else
#define MSG5017 "-Unknown-"
#define MSG5019 "-Unnamed-"
#endif

/*
 *	map_video - build map for video memory
 */

/* Fill in the mappings for video adapters */
#define MSG5018 "Video ("

/*
 *	map_sysrom - build map for system rom
 */

/* Map the System ROM */
#ifdef LANG_GR
#define MSG5020 "System-ROM"
#else
#define MSG5020 "System ROM"
#endif

/*
 *	map_roms - build map for on-card roms
 */

/* Size of ROM region */
#define MSG5022 "ROM"
#ifdef LANG_GR
#define MSG5021 "Video-ROM"
#define MSG5023 "Disk-ROM"
#else
#define MSG5021 "Video ROM"
#define MSG5023 "Disk ROM"
#endif

/*
 *	map_holes - build map for any regions unaccounted
 */

/* Accounted for by RAM or ROM entry */
#define MSG5026 "RAM"
#ifdef LANG_GR
#define MSG5024 "RAM o. ROM"
#define MSG5024b "Adapter RAM or ROM"
#define MSG5025 "unbekannt"
#define MSG5027 "-Unbenutzt-"
#else
#define MSG5024 "RAM or ROM"
#define MSG5024b "Adapter RAM or ROM"
#define MSG5025 "Unknown"
#define MSG5027 "-Unused-"
#endif

/*
 *	map_dd - build map for device drivers
 */

#ifdef LANG_GR
#define MSG5028 "Laufw. %c-%c"
#define MSG5029 "Laufw. %c"
#else
#define MSG5028 "Drive %c-%c"
#define MSG5029 "Drive %c"
#endif

/*
 *	map_dosdata
 */

/* Pointer to subsegment header */
#ifdef LANG_GR
#define MSG5030 "Einh.: %s"
#define MSG5031 "Einh.-Daten"
#define MSG5032 "IFS: %s"
#define MSG5033 "%3d FILES"
#define MSG5034 "EMS-Bereich"
#define MSG5035 "%3d BUFFERS"
#define MSG5036 "%3d FCBS"
#define MSG5037 "Laufw.-Liste"
#define MSG5038 "DOS-Stacks"
#else
#define MSG5030 "Dev: %s"
#define MSG5031 "Device data"
#define MSG5032 "IFS: %s"
#define MSG5033 "%3d FILES"
#define MSG5034 "EMS Workspace"
#define MSG5035 "%3d BUFFERS"
#define MSG5036 "%3d FCBS"
#define MSG5037 "Drive List"
#define MSG5038 "DOS Stacks"
#endif

/* Last message number used:  5029 */
#endif /* MAPINFO_C */


#ifdef ADF_C

#define MSG6000 "A:\\"

/*
 *	adf_setup - Collect and verify ADF file spec.
 */

/* File find structure */
#define MSG6001 "*.ADF"

/* Keywords */
#define MSG6002 "AdapterId"
#define MSG6003 "AdapterName"
#define MSG6004 "Prompt"
#define MSG6005 "Choice"
#define MSG6006 "Pos"
#define MSG6006b "Mem"
#define MSG6008 "Vcheck"

/* Set up the file spec */
#define MSG6007 "@%04X.ADF"

/* Last used:  6008 */

#endif /* ADF_C */


/* Tue Nov 20 18:38:39 1990 alan:  work */
/* Wed Nov 21 10:44:25 1990 alan:  fix bugs */
/* Mon Nov 26 17:06:03 1990 alan:  rwsystxt and other bugs */
/* Tue Nov 27 15:10:12 1990 alan:  bugs */
/* Thu Nov 29 16:41:57 1990 alan:  fix bugs */
/* Wed Dec 19 17:12:48 1990 alan:  new mapping technique */
/* Wed Dec 26 13:21:48 1990 alan:  fix bugs */
/* Sat Mar 09 12:06:07 1991 alan:  fix bugs */
/* Thu Mar 28 12:39:51 1991 alan:  fix bugs */
/* Thu Mar 28 21:58:35 1991 alan:  fix bugs */
/*⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø*/
/*≥    Mar 29		 92 hr	:  transferred to GERMAN	 ≥*/
/*≥				   needs to be tested		 ≥*/
/*¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ*/
