//' $Header:   P:/PVCS/MAX/STRIPMGR/MESSAGE.H_V   1.2   01 Feb 1996 10:00:58   HENRY  $

// MESSAGE.H - Various text messages for STRIPMGR
//   (put here to simplify language conversions)
//   Copyright (c) 1990-96  Rex C. Conn and Qualitas, Inc.   All rights reserved


// USAGE messages
#define CALL_USAGE "^"
#define CDD_USAGE "~"
#define FOR_USAGE "%var IN (set) DO ... [args]"
#ifdef LANG_GR
#define IF_USAGE "[NOT] bedingung ..."
#define IFF_USAGE "[NOT] bedingung THEN ^ ... [ELSE[IFF] ^ ...] ENDIFF"
#define STRIPMGR_USAGE	\
	"\nAnwendung: " PROGNAME " [lw:] [/H/R/S/T]\n"
#define STRIPMGR_USAGE_DOS6	\
	"\nAnwendung: " PROGNAME " [lw:] [/H/R/S/T] [/A Block_Name]\n"  \
	"    /A        Bearbeitet nur diesen MultiConfig-Abschnitt, wobei\n" \
	"              Block_Name den Namen des MultiConfig\n" \
	"              Konfigurationsblocks angibt.\n"
#define STRIPMGR_USAGE_2 \
	"    /H(ilfe)  zeigt diesen Hilfe-Bildschirm.\n" \
	"    /R(emove) entfernt nur Befehle zum \"Hochladen\";\n" \
	"              behÑlt Memory Manager in den Systemdateien.\n"      \
	"    /S(trip)  entfernt Memory Manager aus CONFIG.SYS,\n"          \
	"              AUTOEXEC.BAT und davon abhÑngigen Stapeldateien.\n" \
	"    /T(erse)  zeigt keine Statusmeldungen, keine Fragen.\n\n"
#else
#define IF_USAGE "[NOT] condition ..."
#define IFF_USAGE "[NOT] condition THEN ^ ... [ELSE[IFF] ^ ...] ENDIFF"
#define STRIPMGR_USAGE	\
	"\nUsage: " PROGNAME " [d:] [/H/R/S/T]\n"
#define STRIPMGR_USAGE_DOS6	\
	"\nUsage: " PROGNAME " [d:] [/H/R/S/T] [/A Header_Name]\n" \
	"    /A        Process this DOS MultiConfig section only, where\n" \
	"              Header_Name denotes the name of the MultiConfig\n" \
	"              configuration block.\n"
#define STRIPMGR_USAGE_2 \
	"    /H(elp)   Display this help list.\n"                       \
	"    /R(emove) Perform load high commands for programs loaded\n" \
	"              high but don't remove memory manager.\n" \
	"    /S(trip)  Remove memory managers from CONFIG.SYS,\n"       \
	"              AUTOEXEC.BAT, and related batch files.\n"        \
	"    /T(erse)  Remove all occurrences of memory managers and their\n" \
	"              related programs without displaying status messages\n" \
	"              or prompts.\n\n"
#endif
#define POPD_USAGE "[*]"


// BATCH.C
#define IN "in"
#define DO "do"
#define IF_NOT "not"
#define IF_OR ".OR."
#define IF_XOR ".XOR."
#define IF_AND ".AND."
#define IF_DIREXIST "direxist"
#define IF_EXIST "exist"
#define IF_ISDIR "isdir"
#define IF_ISINTERNAL "isinternal"
#define IF_ISALIAS "isalias"
#define IF_ISLABEL "islabel"
#define IF_ERRORLEVEL "errorlevel"
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


// EXPAND.C
#define TEMP_DISK "TMP"


// MISC.C
#ifdef LANG_GR
#define YES_NO		"        ? (J/N) : "
#else
#define YES_NO		"        ? (Y/N) : "
#endif
#define YES_NO_DLG	"        ?\n\n" // Y/N format for dialog boxes


// PARSER.C
#define PROGVER "1.40"

#ifdef LANG_GR

#define COPYRIGHT "\n"                  \
		  PROGNAME " " PROGVER "\n"     \
		  "   (C) Copyright 1990-96  Rex Conn & Qualitas, Inc.  Alle Rechte vorbehalten.\n"
#define CANT_OPEN "kann \"%s\" nicht îffnen\n"
#define INSERT_DISK "\nLegen Sie die Diskette mit \"%s\" ein\n"
#define SCANNING "\ndurchsuche %s nach Speicherverwaltungs-Programmen...\n"
#define CONTINUE_SCANNING "\nsetze Suche fort in %s ...\n"
#define DETECT_MESSAGE "  gefunden:  %s\n"
#define REMOVE_MESSAGE "  au·er Funktion:  %Fs"
#define MODIFY_MESSAGE "  Ñndere: %Fs" \
		       "  auf:    %Fs"
#define PROCESS_MESSAGE " Bearbeite: [%Fs]  %Fs\n"
#define CANT_MAKE_BACKUP "kann keine Sicherung anlegen fÅr %s\n"
#define STATUS_DETECT "habe %u Hinweis(e) auf Speicherverw.-Programm(e) gefunden in %s\n"
#define STATUS_REMOVE "habe %u BezÅge auf Speicherverw.-Programm(e) in %s unwirksam gemacht\n"
#define INSTALLCHNFAIL	"\n\n  Verkettung zu %s fehlgeschlagen.\n" \
			"  Weiter mit <-\n" \
			"   %s %s %s\n"

#define YES_CHAR 'J'
#define NO_CHAR 'N'

#else

#define COPYRIGHT "\n"                  \
		  PROGNAME " " PROGVER "\n"    \
		  "   (C) Copyright 1990-96  Rex Conn & Qualitas, Inc.  All rights reserved.\n"
#define CANT_OPEN "Can't open \"%s\"\n"
#define INSERT_DISK "\nInsert disk with \"%s\"\n"
#define SCANNING "\nScanning %s for memory managers ...\n"
#define CONTINUE_SCANNING "\nContinuing scan of %s ...\n"
#define DETECT_MESSAGE "  Found:  %s\n"
#define REMOVE_MESSAGE "  Remove: %Fs"
#define MODIFY_MESSAGE "  Change: %Fs\n" \
		       "  To:     %Fs"
#define PROCESS_MESSAGE " Process: [%Fs]  %Fs"
#define CANT_MAKE_BACKUP "Can't create backup for %s\n"
#define STATUS_DETECT "Found %u references to memory managers in %s\n"
#define STATUS_REMOVE "Removed %u references to memory managers in %s\n"
#define INSTALLCHNFAIL	"\n\n  Unable to chain to %s.\n" \
			"  To continue, enter\n" \
			"   %s %s %s\n"

#define YES_CHAR 'Y'
#define NO_CHAR 'N'

#endif

#define WRAP_COL	49	// Where to wrap for dialog box
#define WRAP2_COL	79	// Where to wrap for command line
#define INDENT_STR    "\n               " // Columns to indent for wrapped lines
#define INDENT_COL	(strlen(INDENT_STR)-1) // Number of spaces in indent

#define SINGLE_QUOTE '`'                // quote characters
#define DOUBLE_QUOTE '"'

#ifdef DEFINE_GLOBALS

// Global string variables

char ON[] = "ON";
char OFF[] = "OFF";
char WILD_FILE[] = "*.*";
char NULLSTR[] = "";
char QUOTES[] = "`\"";
char BACK_QUOTE[] = "`";
char DELIMS[] =  "%9[^  .\"`\\+=:<>|]"; // Template for sscanf() to get a cmd

char *executables[] = {
	".com",         // executable file extensions
	".exe",
	".btm",         // in-memory batch file
	".bat",
	NULL
};

#else

extern char ON[];
extern char OFF[];
extern char WILD_FILE[];
extern char NULLSTR[];
extern char QUOTES[];
extern char BACK_QUOTE[];
extern char DELIMS[];

extern char *environment;

extern char *executables[];

#define COM executables[0]
#define EXE executables[1]
#define BTM executables[2]
#define BAT executables[3]

#endif

