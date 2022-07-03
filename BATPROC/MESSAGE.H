//' $Header:   P:/PVCS/MAX/BATPROC/MESSAGE.H_V   1.3   27 Feb 1996 10:08:12   HENRY  $

// MESSAGE.H - Various text messages for BATPROC
//   (put here to simplify language conversions)
//   Copyright (c) 1990-96  Rex C. Conn and Qualitas, Inc.  GNU General Public License version 3
//⁄ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
//≥  modified for GERMAN users, pls check completely,  ≥
//≥  change YES-switches to Ja (J),		       ≥
//≥  No = Nein (should be ok)			       ≥
//≥  Abort = Abbruch (should be ok)		       ≥
//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ

// USAGE messages
#ifdef LANG_GR

#define ATTRIB_USAGE "[+|-AHRS] ^..."
#define BATPROC_USAGE "quelle[,quelle2[,...]] ziel lader [ausnahme_liste]"
#define BREAK_USAGE "[on | off]"
#define CALL_USAGE "^"
#define CDD_USAGE "~"
#define COLOR_USAGE "#"
#define COPY_USAGE "[/ABMPQRUV] ^[...[/AB] ^[/AB]]"
#define CTTY_USAGE "device"
#define DELETE_USAGE "[/PQY] ^..."
#define DESCRIBE_USAGE "^..."
#define DRAWBOX_USAGE "urow lcol lrow rcol style # [FILL bg]"
#define DRAWLINE_USAGE "row col len style #"
#define ESET_USAGE "varname..."
#define EXCEPT_USAGE "(^...) ..."
#define FOR_USAGE "%var IN (set) DO ... [args]"
#define GLOBAL_USAGE "[/IQ] ..."
#define IF_USAGE "[NOT] bedingung ..."
#define IFF_USAGE "[NOT] bedingung THEN ... [ELSE[IFF] ...] ENDIFF"
#define INKEY_INPUT_USAGE "[/Wn][text] %%var"
#define KEYSTACK_USAGE "[\"text\"] [nn] [@n]"
#define MD_USAGE "~..."
#define MOVE_USAGE "[/PQR] ^[... ^]"
#define POPD_USAGE "[*]"
#define RD_USAGE "~..."
#define RENAME_USAGE "[/PQ] ^... ^"
#define SCREEN_USAGE "row col [text]"
#define SCRPUT_USAGE "row col # text"
#define TEE_USAGE "[/A] ^..."
#define TYPE_USAGE "[/LP] ^..."
#define UNSET_USAGE "name..."
#define VERIFY_USAGE BREAK_USAGE

#else

#define ATTRIB_USAGE "[+|-AHRS] ^..."
#define BATPROC_USAGE "infile[,infile2[,...]] outfile loader [exclude_list]"
#define BREAK_USAGE "[on | off]"
#define CALL_USAGE "^"
#define CDD_USAGE "~"
#define COLOR_USAGE "#"
#define COPY_USAGE "[/ABMPQRUV] ^[...[/AB] ^[/AB]]"
#define CTTY_USAGE "device"
#define DELETE_USAGE "[/PQY] ^..."
#define DESCRIBE_USAGE "^..."
#define DRAWBOX_USAGE "urow lcol lrow rcol style # [FILL bg]"
#define DRAWLINE_USAGE "row col len style #"
#define ESET_USAGE "varname..."
#define EXCEPT_USAGE "(^...) ..."
#define FOR_USAGE "%var IN (set) DO ... [args]"
#define GLOBAL_USAGE "[/IQ] ..."
#define IF_USAGE "[NOT] condition ..."
#define IFF_USAGE "[NOT] condition THEN ... [ELSE[IFF] ...] ENDIFF"
#define INKEY_INPUT_USAGE "[/Wn][text] %%var"
#define KEYSTACK_USAGE "[\"text\"] [nn] [@n]"
#define MD_USAGE "~..."
#define MOVE_USAGE "[/PQR] ^[... ^]"
#define POPD_USAGE "[*]"
#define RD_USAGE "~..."
#define RENAME_USAGE "[/PQ] ^... ^"
#define SCREEN_USAGE "row col [text]"
#define SCRPUT_USAGE "row col # text"
#define TEE_USAGE "[/A] ^..."
#define TYPE_USAGE "[/LP] ^..."
#define UNSET_USAGE "name..."
#define VERIFY_USAGE BREAK_USAGE

#endif

// BATCH.C
#define ENDTEXT "ENDTEXT"
#ifdef LANG_GR
#define ECHO_IS "ECHO ist %s\n"
#define PAUSE_PROMPT "weiter mit beliebiger Taste..."
#else
#define ECHO_IS "ECHO is %s\n"
#define PAUSE_PROMPT "Press a key when ready..."
#endif
#define IN "in"
#define DO "do"
#define NOT "not"
#define EXIST "exist"
#define ISDIR "isdir"
#define ISALIAS "isalias"
#define ATTRIBUTES "attrib"
#define FILESIZE "filesize"
#define ERRORLEVEL "errorlevel"
#define DISKLABEL "disklabel"
#define DISKFREE "diskfree"
#define DOSMEM "dosmem"
#define EMS "ems"
#define EXTENDED "extended"
#define XMS "xms"
#define HMA "hma"
#define MONITOR "monitor"
  #define MONO_MONITOR "mono"
  #define COLOR_MONITOR "color"
#define VIDEO "video"
#define EQ "EQ"
#define GT "GT"
#define GE "GE"
#define LT "LT"
#define LE "LE"
#define NE "NE"
#define THEN "then"
#define IFF "iff"
#define ELSEIFF "elseiff"
#define ELSE "else"
#define ENDIFF "endiff"
#define INKEY_COMMAND "INKEY"


// DIRCMDS.C
#ifdef LANG_GR

#define DIRECTORY_OF "Verzeichnis von"
#define DIR_FILE_SIZE "KMG"
#define DIR_BYTES_IN_FILES "%12s Byte in %u Datei(en)"
#define DIR_BYTES_FREE "%12s Byte frei"
#define DIR_TOTAL "    gesamt: "
#define DIR_LABEL "<DIR>   "

#else

#define DIRECTORY_OF "Directory of"
#define DIR_FILE_SIZE "KMG"
#define DIR_BYTES_IN_FILES "%12s bytes in %u file(s)"
#define DIR_BYTES_FREE "%12s bytes free"
#define DIR_TOTAL "     Total: "
#define DIR_LABEL "<DIR>   "

#endif

// ENV.C
#define SET_COMMAND "SET"
#define UNSET_COMMAND "UNSET"


// ERROR.C
#ifdef LANG_GR

#define USAGE "Belegung : %s "
#define FILE_SPEC "[d:][pfad]dateiname"
#define PATH_SPEC "[d:]pfadname"
#define COLOR_SPEC "[bright][blink] fg ON bg"

#else

#define USAGE "Usage : %s "
#define FILE_SPEC "[d:][path]filename"
#define PATH_SPEC "[d:]pathname"
#define COLOR_SPEC "[bright][blink] fg ON bg"

#endif


// EXPAND.C
#define TEMP_DISK "TMP"
#define VAR_FG_COLOR "_fg"
#define VAR_BG_COLOR "_bg"
#define VAR_COLUMNS "_columns"
#define VAR_CPU "_cpu"
#define VAR_CWD "_cwd"
#define VAR_CWDS "_cwds"
#define VAR_CWP "_cwp"
#define VAR_CWPS "_cwps"
#define VAR_DATE "_date"
#define VAR_DOW "_dow"
#define VAR_DISK "_disk"
#define VAR_DOSVER "_dosver"
#define VAR_NDP "_ndp"
#define VAR_ROWS "_rows"
#define VAR_SHELL "_shell"
#define VAR_TIME "_time"
#define SEARCH "search"
#define NAME "name"
#define EXTENSION "ext"
#define PATH_VAR "PATH"
#define FULLNAME "full"
#define UPPER "upper"
#define LOWER "lower"
#define LENGTH "len"
#define SUBSTR "substr"
#define INDEX "index"
#define FILE_LINE "line"
#define EVAL "eval"


// FILECMDS.C
#ifdef LANG_GR

#define REPLACE " (ersetze)"
#define FILES_COPIED "%6u Datei)en) kopiert\n"
#define FILES_MOVED "%6u Datei(en) bewegt\n"
#define ARE_YOU_SURE "sind Sie sicher?"
#define DELETE_QUERY "Delete "
#define DELETING_FILE "lîsche %s\n"

#else

#define REPLACE " (Replace)"
#define FILES_COPIED "%6u file(s) copied\n"
#define FILES_MOVED "%6u file(s) moved\n"
#define ARE_YOU_SURE "Are you sure"
#define DELETE_QUERY "Delete "
#define DELETING_FILE "Deleting %s\n"

#endif


// MISC.C
#ifdef LANG_GR
#define YES_NO "%s ? (J/N) : "
#else
#define YES_NO "%s ? (Y/N) : "
#endif
#define BRIGHT "bri"
#define BLINK "bli"


// PARSER.C
#define PROGVER "1.63"

#ifdef LANG_GR

#define COPYRIGHT "BATPROC " PROGVER "\n" \
		  "   (C) Copyright 1990-96 Rex Conn & Qualitas, Inc.  Alle Rechte vorbehalten."
#define CANCEL_BATCH_JOB "\nWollen Sie die Stapelverarbeitung abbrechen ? (J/N/A) : "
#define INSERT_DISK "\nlegen Sie die Diskette ein mit \"%s\"\n"
#define CMDLINE "CMDLINE="
#define PROMPT_NAME "PROMPT"
#define WARNING "Achtung: Sie haben ein ALIAS definiert, um ein TSR zu laden.  MAXIMIZE\nkann Ihre Befehle nicht optimieren, wenn Sie diese nicht explizit laden.\n\nweiter mit beliebiger Taste... "

#else

#define COPYRIGHT "BATPROC " PROGVER "\n" \
		  "   (C) Copyright 1990-96 Rex Conn & Qualitas, Inc.  GNU General Public License version 3."
#define CANCEL_BATCH_JOB "\nCancel batch job ? (Y/N/A) : "
#define INSERT_DISK "\nInsert disk with \"%s\"\n"
#define CMDLINE "CMDLINE="
#define PROMPT_NAME "PROMPT"
#define WARNING "WARNING: You have defined an alias to load a TSR.  MAXIMIZE\nwill not be able to optimize your commands unless you load them explicitly.\n\nPress any key to continue "

#endif

// SYSCMDS.C
#ifdef LANG_GR

#define UNLABELED "hat keinen Namen"
#define VOLUME_LABEL " das Medium im Laufwerk %c hat den Namen %s"
#define NO_PATH "kein Pfad"
#define TOTAL_RAM "%12s Byte Gesamt-RAM\n"
#define BYTES_FREE "%12s Byte frei\n"
#define TOTAL_DISK "%12s Byte Gesamtspeicherplatz\n"
#define TOTAL_USED "%12s Byte belegt\n"
#define BREAK_IS "%s ist %s\n"
#define VERIFY_IS BREAK_IS
#define GLOBAL_DIR "\nGLOBAL: %s\n"
#define NEW_DATE "\nneues Datum (%s): "
#define NEW_TIME "\nneue Uhrzeit (hh:mm:ss): "
#define CODE_PAGE "Aktive Code-Seite: %u\n"
#define PREPARED_CODE_PAGES "vorbereitete System-Code-Seiten: "
#define PROCESS_ID "Die Prozess-ID ist %d\n"

#else

#define UNLABELED "unlabeled"
#define VOLUME_LABEL " Volume in drive %c is %s"
#define NO_PATH "No path"
#define TOTAL_RAM "%12s bytes total RAM\n"
#define BYTES_FREE "%12s bytes free\n"
#define TOTAL_DISK "%12s bytes total disk space\n"
#define TOTAL_USED "%12s bytes used\n"
#define BREAK_IS "%s is %s\n"
#define VERIFY_IS BREAK_IS
#define GLOBAL_DIR "\nGLOBAL: %s\n"
#define NEW_DATE "\nNew date (%s): "
#define NEW_TIME "\nNew time (hh:mm:ss): "
#define CODE_PAGE "Active code page: %u\n"
#define PREPARED_CODE_PAGES "Prepared system code pages: "
#define PROCESS_ID "The process ID is %d\n"

#endif

#define SETDOS_IS "ANSI=%d\nCOMPOUND=%c\nESCAPE=%c\nHISTORY=%u\nINPUT=%u\nMODE=%u\nNOCLOBBER=%u\nROWS=%u\nCURSOR START=%u\nCURSOR END=%u\nUPPER CASE=%u\nVERBOSE=%u\nSWITCH=%c\n"


#define SINGLE_QUOTE '`'                // quote characters
#define DOUBLE_QUOTE '"'

#ifdef LANG_GR
#define YES_CHAR 'J'                    // J for Ja
#define NO_CHAR 'N'
#else
#define YES_CHAR 'Y'
#define NO_CHAR 'N'
#endif


#ifdef DEFINE_GLOBALS

// Global string variables

char ON[] = "ON";
char OFF[] = "OFF";
char WILD_FILE[] = "*.*";
char NULLSTR[] = "";
#ifdef COMPAT_4DOS
char QUOTES[] = "`\"";
#else
char QUOTES[] = "\"";
#endif
char BACK_QUOTE[] = "`";
char DELIMS[] = "%9[^  .\"`\\+=:<>|]";

char near *executables[] = {
	".com",         // executable file extensions
	".exe",
#ifdef COMPAT_4DOS
	".btm",         // in-memory batch file
#endif
	".bat",
	NULL
};

#ifdef COMPAT_4DOS
// video type array for IF VIDEO
char near *video_type[] = {
	"mono",
	"cga",
	"ega",          // monochrome ega
	"ega",          // color ega
	"vga",          // monochrome vga
	"vga"           // color vga
};
#endif

// tables for date formatting
char near *daytbl[] = {
#ifdef LANG_GR
	"Son",
	"Mon",
	"Die",
	"Mit",
	"Don",
	"Fre",
	"Sam"
#else
	"Sun",
	"Mon",
	"Tue",
	"Wed",
	"Thu",
	"Fri",
	"Sat"
#endif
};

char near *montbl[] = {
#ifdef LANG_GR
	"Jan",
	"Feb",
	"MÑr",
	"Apr",
	"Mai",
	"Jun",
	"Jul",
	"Aug",
	"Sep",
	"Okt",
	"Nov",
	"Dez"
#else
	"Jan",
	"Feb",
	"Mar",
	"Apr",
	"May",
	"Jun",
	"Jul",
	"Aug",
	"Sep",
	"Oct",
	"Nov",
	"Dec"
#endif
};

char near *dateformat[] = {
#ifdef LANG_GR
	"MM-TT-JJ",
	"TT-MM-JJ",
	"JJ-MM-TT"
#else
	"mm-dd-yy",             // USA date format
	"dd-mm-yy",             // Europe
	"yy-mm-dd"              // Japan
#endif
};

#ifdef COMPAT_4DOS
// ANSI color sequences (for COLOR)
ANSI_COLORS colors[] = {
	"Bla",30,
	"Blu",34,
	"Gre",32,
	"Cya",36,
	"Red",31,
	"Mag",35,
	"Yel",33,
	"Whi",37
};
#endif

// BATPROC error messages
char near *int_batproc_errors[] =
{
#ifdef LANG_GR
	"Syntax-Fehler",
	"unbekannter Befehl",
	"Befehlszeile zu lang",
	"abschlie·endes Hochkomma fehlt",
	"kann nicht îffnen",
	"kann nicht anlegen",
	"kann nicht lîschen",
	"Fehler beim Lesen",
	"Fehler beim Schreiben",
	"Quell- und Zieldatei dÅrfen nicht identisch sein!",
	"Inhalt vor dem Kopieren verloren",            // 10
	"kein Alias",
	"keine Alias angelegt",
	"Alias-Schleife",
	"Variablen-Schleife",
	"ungÅltiges Datum",
	"ungÅltige Uhrzeit",
	"Verzeichnis-Stapel ist leer",
	"kann nicht in das Verzeichnis schalten",
	"Label nicht gefunden",
	"au·erhalb von Umgebungs-oder Alias-Bereich",       // 20
	"nicht in der Umgebung",
	"Stapel-Datei fehlt",
	"Stapeltiefe Åberschritten",
	"ENDTEXT-Eintrag fehlt",
	"GOSUB-Eintrag fehlt",
	"Umgebung bereits gesichert",
	"SETLOCAL-Eintrag fehlt",
	"SETLOCAL nur in Stapeldatei zulÑssig",
	"KEYSTACK.SYS nicht geladen",
	"ungÅltige MS-DOS-Version",               // 30
	"nicht im SWAP-Modus",
	"Klammerfehler",
	"kein Ausdruck",
	"durch 0(Null) geteilt"
#else
	"Syntax error",
	"Unknown command",
	"Command line too long",
	"No closing quote",
	"Can't open",
	"Can't create",
	"Can't delete",
	"Error reading",
	"Error writing",
	"Can't copy file to itself",
	"Contents lost before copy",            // 10
	"Not an alias",
	"No aliases defined",
	"Alias loop",
	"Variable loop",
	"Invalid date",
	"Invalid time",
	"Directory stack empty",
	"Can't get directory",
	"Label not found",
	"Out of environment/alias space",       // 20
	"Not in environment",
	"Batch file missing",
	"Exceeded batch nesting limit",
	"Missing ENDTEXT",
	"Missing GOSUB",
	"Environment already saved",
	"Missing SETLOCAL",
	"SETLOCAL only valid in batch file",
	"KEYSTACK.SYS not loaded",
	"Invalid MS-DOS version",               // 30
	"Not in swapping mode",
	"Unbalanced parentheses",
	"No expression",
	"Divide by zero"
#endif
};

#else

extern char ON[];
extern char OFF[];
extern char WILD_FILE[];
extern char NULLSTR[];
extern char QUOTES[];
extern char BACK_QUOTE[];
extern char DELIMS[];

extern char near *environment;
extern char near *alias_list;
extern char near *histlist;

extern char near *video_type[];
extern char near *daytbl[];
extern char near *montbl[];
extern char near *dateformat[];
extern ANSI_COLORS colors[];
extern char near *int_batproc_errors[];

extern char *executables[];

#define COM executables[0]
#define EXE executables[1]
#define BTM executables[2]
#define BAT executables[3]

#endif

