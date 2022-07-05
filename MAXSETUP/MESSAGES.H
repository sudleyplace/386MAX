// $Header:   P:/PVCS/MAX/MAXSETUP/MESSAGES.H_V   1.11   06 Mar 1996 11:24:46   PETERJ  $
// Messages for MAX 8 Setup.exe
// Copyright (C) 1995 Qualitas, Inc. GNU General Public License version 3.

#ifdef EXTERN
    #undef EXTERN
#endif

#ifdef DEFVAL
    #undef DEFVAL
#endif

#ifdef SETUP_MSG_DEFVARS
    #define EXTERN
    #define DEFVAL(v) =v
#else
    #define EXTERN extern
    #define DEFVAL(v)
#endif

#define PROGNAME "MAXSetup"
#define AUTOBCF  "AUTOBCF"

//------------------------------------------------------------------
// German
//------------------------------------------------------------------
#ifdef LANG_GR
EXTERN LPSTR szMsg_Group     DEFVAL( "Setup konnte die Gruppe Qualitas MAX nicht aktivieren.");
EXTERN LPSTR szMsg_Init      DEFVAL( "Setup kann die Gruppe Qualitas MAX nicht einrichten. Mˆglicherweise sind zu viele Programmgruppen vorhanden. Reduzieren Sie die Anzahl Programmgruppen und starten Sie Setup erneut.");
EXTERN LPSTR szMsg_InitTitle DEFVAL( "Initialisierung der MAX Gruppe");

EXTERN LPSTR szMsg_DMFull    DEFVAL( "DOSMAX Vollbild" );
EXTERN LPSTR szMsg_DMWind    DEFVAL( "DOSMAX Fenster" );
EXTERN LPSTR szMsg_HelpIcon  DEFVAL( "MAX Hilfe" );

EXTERN LPSTR szMsg_Added    DEFVAL( "Hinzu" );
EXTERN LPSTR szMsg_Deleted  DEFVAL( "Lˆsch" );

EXTERN LPSTR szMsg_Sernum   DEFVAL( "Seriennr.:" );
EXTERN LPSTR szMsg_License  DEFVAL( "Lizenz fÅr" );

EXTERN LPSTR szMsg_SFFail      DEFVAL( "Setup kann Windows nicht beenden.\nSchlieﬂen Sie alle Anwendungen und starten Sie den Vorgang erneut." ); 
EXTERN LPSTR szMsg_SFFailTitle DEFVAL( "Systemabschluﬂ fehlgeschlagen" );

EXTERN LPSTR szMsg_CreaCsys DEFVAL( "Setup kann die Datei CONFIG.SYS nicht anlegen und kann den Ablauf nicht fortsetzen.");
EXTERN LPSTR szMsg_SetTitle DEFVAL( "Setup" );
EXTERN LPSTR szMsg_SetComp  DEFVAL( "Setup ist abgeschlossen." );
EXTERN LPSTR szMsg_Name     DEFVAL( "Sie m¸ssen einen Namen eingeben." );
EXTERN LPSTR szMsg_Reg      DEFVAL( "Registrierung" );
EXTERN LPSTR szMsg_Serial   DEFVAL( "Sie m¸ssen eine Seriennummer eingeben.");
EXTERN LPSTR szMsg_InvSer   DEFVAL( "Ung¸ltige Seriennummer!" );
EXTERN LPSTR szMsg_Multi    DEFVAL( "MultiConfig" );
EXTERN LPSTR szMsg_MustMult DEFVAL( "Sie m¸ssen einen MultiConfig-Block w‰hlen.");

EXTERN LPSTR szMsg_NoFile   DEFVAL( "Keine Dateien ausgew‰hlt" );
EXTERN LPSTR szMsg_MustSel  DEFVAL( "Sie haben f¸r Setup keine Komponenten zur Installation ausgew‰hlt. Mˆchten Sie Setup beenden, kehren Sie zum Datei-Dialog zur¸ck und w‰hlen dort Beenden." );

EXTERN LPSTR szMsg_Error   DEFVAL( "Fehler"; );
EXTERN LPSTR szMsg_Extract DEFVAL( "Extrahiere" );
EXTERN LPSTR szMsg_ArcRE   DEFVAL( "Lesefehler bei Archiv-Datei." );
EXTERN LPSTR szMsg_ArcDC   DEFVAL( "Archiv-Verzeichnis besch‰digt.");
EXTERN LPSTR szMsg_ArcDir  DEFVAL( "Kann Archiv-Verzeichnis nicht finden." );
EXTERN LPSTR szMsg_ArcExt  DEFVAL( "VSEEK w‰hrend Datei-Extrahieren fehlgeschlagen.");
EXTERN LPSTR szMsg_ArcBuf  DEFVAL( "Kann Archiv-Dateipuffer nicht lesen.");

EXTERN LPSTR szMsg_Target  DEFVAL( "Sogenanntes  szTarget create  fehlgeschlagen!");
EXTERN LPSTR szMsg_UncW    DEFVAL( "Schreiben dekomprimierter Daten fehlgeschlagen!");

EXTERN LPSTR szMsg_BadData DEFVAL( "Schlechte Daten" );
EXTERN LPSTR szMsg_CRC     DEFVAL( "CRC-Fehler" );

EXTERN LPSTR szMsg_Dir     DEFVAL( "Verzeichnis" );
EXTERN LPSTR szMsg_BackDir DEFVAL( "Kann Backup-Verzeichnis nicht anlegen");
EXTERN LPSTR szMsg_MustDir DEFVAL( "Sie m¸ssen einen Verzeichnisnamen eingeben.");
EXTERN LPSTR szMsg_NoDrive DEFVAL( "Das angegebene Laufwerk ist nicht vorhanden." );
EXTERN LPSTR szMsg_NDir    DEFVAL( "Kann das Verzeichnis nicht anlegen");
EXTERN LPSTR szMsg_NDir2   DEFVAL( "Kann das angegebene Verzeichnis nicht anlegen");
EXTERN LPSTR szMsg_Xist    DEFVAL( "Datei mit gleichem Namen ist bereits vorhanden.");
EXTERN LPSTR szMsg_TheDir  DEFVAL( "Das Verzeichnis");
EXTERN LPSTR szMsg_NoXst   DEFVAL( "ist nicht vorhanden - mˆchten Sie dieses anlegen?");

EXTERN LPSTR szMsg_NoSpc   DEFVAL( "Nicht gen¸gend freier Plattenspeicher" );
EXTERN LPSTR szMsg_NS      DEFVAL( "Auf dem angegebenen Laufwerk ist nicht gen¸gend Platz frei, um Qualitas MAX 8.0 zu installieren.");

EXTERN LPSTR szMsg_Xtr     DEFVAL( "Extrahiere");
EXTERN LPSTR szMsg_Copy    DEFVAL( "Kopiere");

EXTERN LPSTR szMsg_InsDsk  DEFVAL( "Setup benˆtigt die Diskette");
EXTERN LPSTR szMsg_DskLoc  DEFVAL( "Geben Sie das Laufwerk an f¸r Diskette");
EXTERN LPSTR szMsg_DskPath DEFVAL( "Geben Sie den Pfad ein f¸r");
    
    // The %s in the strings below holds the place for the directory name.
EXTERN LPSTR szFmt_BUp     DEFVAL( "Sichere das Verzeichnis %s - bitte Geduld ...");
EXTERN LPSTR szFmt_Rest    DEFVAL( "Stelle das Verzeichnis %s wieder her - bitte Geduld ...");

    // these are the WinHelp keys.
    // they MUST match the topics in the Help File.
EXTERN LPSTR szHKEY_SrcDir  DEFVAL( "Quellen-Verzeichnis" );
EXTERN LPSTR szHKEY_Welcome DEFVAL( "Willkommen bei Qualitas MAX 8" );
EXTERN LPSTR szHKEY_RegInf  DEFVAL( "Registrierungs-Information" );
EXTERN LPSTR szHKEY_RegConf DEFVAL( "Registrierungs-Best‰tigung" );
EXTERN LPSTR szHKEY_Up      DEFVAL( "Update" );
EXTERN LPSTR szHKEY_Multi   DEFVAL( "MultiConfig" );
EXTERN LPSTR szHKEY_FLoc    DEFVAL( "Pfad und Dateien" );
EXTERN LPSTR szHKEY_FMod    DEFVAL( "Datei-ƒnderungen" );
EXTERN LPSTR szHKEY_MaxNow  DEFVAL( "Mˆchten Sie jetzt Maximize starten?" );
EXTERN LPSTR szHKEY_Reboot  DEFVAL( "Mˆchten Sie den Computer jetzt neu starten?" );
EXTERN LPSTR szHKEY_Restart DEFVAL( "Mˆchten Sie den Computer jetzt neu starten?" );
EXTERN LPSTR szHKEY_Config  DEFVAL( "Qualitas MAX Einstellungen" );
EXTERN LPSTR szHKEY_RefDir  DEFVAL( "Referenzdiskette einlegen" );

	/* bcffnd_txt */
EXTERN char *MsgBcfFind
    DEFVAL( "Diese Datei wurde von %s "PROGNAME" angelegt.\r\n"
	"Passende BCF-Datei zu Ihrem System:  %s\r\n"
	"Tragen Sie im %s-Profil folgende Zeile ein,\r\n"
	"um die BIOS-Komprimierung zu aktivieren:\r\n"
	AUTOBCF "        ; lade BIOS-Komprimierungs-Datei\r\n"
	"und entfernen Sie alle USE= Zeilen aus der Profildatei.\r\n" );

	/* nobcf_txt */
EXTERN char *MsgNoBcf
	DEFVAL( PROGNAME " Kein zu Ihrem System passendes BCF auffindbar.\r\n\r\n"
	"Fragen Sie bei Qualitas nach der BCF-Datei.\r\n"
	"Geben Sie dazu folgende Information an:\r\n"
	"Der BIOS-CRC-Wert ist:  %04X\r\n" );

    /* nobcfsys_txt */
EXTERN char *MsgNoBcfSys
    DEFVAL( PROGNAME " stellte fest, dass Ihr System kein Mikrokanal-/IBM-PS/2-386\r\n"
	"ist. Deswegen ist hier keine BIOS-Komprimierung anwendbar.\r\n" );

EXTERN char *MsgAutoBcf
	DEFVAL( AUTOBCF "  ; BCF Datei ist @%04X.BCF" );

EXTERN LPSTR szMsg_Strip DEFVAL( "Entferne Memory Manager aus CONFIG.SYS und AUTOEXEC.BAT - bitte Geduld ..." );
EXTERN LPSTR szMsg_ExtTitle DEFVAL( "Extrahiere MAX Dateien" );
EXTERN LPSTR szMsg_ModCfg DEFVAL( "Bearbeite Konfigurationsdateien - bitte Geduld ..." );
EXTERN LPSTR szMsg_Mem DEFVAL( "Nicht gen¸gend Speicher!" );
EXTERN LPSTR szMsg_RefDisk DEFVAL( "Legen Sie die Mikrokanal-Referenzdiskette f¸r diesen Computer in das angegebene Laufwerk. W‰hlen Sie dann \"WEITER\"." );
EXTERN LPSTR szMsg_BadRef DEFVAL( "Dies ist keine g¸ltige Referenzdiskette! Die Adapter-Optimierung benˆtigt Dateien von der Referenzdiskette. Mˆchten Sie diese Funktion ¸berspringen?" );
EXTERN LPSTR szMsg_CopyADF DEFVAL( "Kopiere ADF-Dateien von der Referenzdiskette." );
EXTERN LPSTR szMsg_GACon DEFVAL( "Konflikt mit Ressourcen-Manager!" );
EXTERN LPSTR szFmt_GA_MM DEFVAL( "Setup hat erkannt, daﬂ %s installiert ist.\nGo Ahead kann evtl. nicht richtig funktionieren, wenn %s installiert ist.\nMˆchten Sie Go Ahead dennoch installieren?" );
EXTERN LPSTR szFmt_BCFErr DEFVAL( "Kann %s nicht nach %s kopieren" );
EXTERN LPSTR szFmt_RWErr DEFVAL( "Fehler bei Zugriff auf die Datei %s" );

EXTERN LPSTR szFmt_IDScan DEFVAL( "%*cSeriennr.:  %s Lizenz fÅr %[^-\r\n] - %[^\r\n]" );

//------------------------------------------------------------------
#else 
//------------------------------------------------------------------
// English
//------------------------------------------------------------------
EXTERN LPSTR szMsg_Group     DEFVAL( "Setup was unable to activate the Qualitas MAX group.");
EXTERN LPSTR szMsg_Init      DEFVAL( "Setup is unable to initialize the Qualitas MAX group. You may have too many groups on your desktop. Please decrease the number of groups on your desktop and re-run Setup.");
EXTERN LPSTR szMsg_InitTitle DEFVAL( "MAX Group Initialization");

EXTERN LPSTR szMsg_DMFull    DEFVAL( "DOSMAX Fullscreen" );
EXTERN LPSTR szMsg_DMWind    DEFVAL( "DOSMAX Window" );
EXTERN LPSTR szMsg_HelpIcon  DEFVAL( "MAX Help" );

EXTERN LPSTR szMsg_Added    DEFVAL( "Added" );
EXTERN LPSTR szMsg_Deleted  DEFVAL( "Deleted" );

EXTERN LPSTR szMsg_Sernum   DEFVAL( "Serial #" );
EXTERN LPSTR szMsg_License  DEFVAL( "Licensed to" );

EXTERN LPSTR szMsg_SFFail      DEFVAL( "Setup cannot exit Windows.\nClose all apps and try again." ); 
EXTERN LPSTR szMsg_SFFailTitle DEFVAL( "Shutdown Failed" );

EXTERN LPSTR szMsg_CreaCsys DEFVAL( "Setup is unable to create CONFIG.SYS, and cannot continue.");
EXTERN LPSTR szMsg_SetTitle DEFVAL( "Setup" );
EXTERN LPSTR szMsg_SetComp  DEFVAL( "Setup is complete.");
EXTERN LPSTR szMsg_Name     DEFVAL( "You must enter a name." );
EXTERN LPSTR szMsg_Reg      DEFVAL( "Registration" );
EXTERN LPSTR szMsg_Serial   DEFVAL( "You must enter a serial number.");
EXTERN LPSTR szMsg_InvSer   DEFVAL( "Invalid serial number!" );
EXTERN LPSTR szMsg_Multi    DEFVAL( "MultiConfig" );
EXTERN LPSTR szMsg_MustMult DEFVAL( "You must enter a MultiConfig section.");

EXTERN LPSTR szMsg_NoFile   DEFVAL( "No Files Selected" );
EXTERN LPSTR szMsg_MustSel  DEFVAL( "You haven't selected anything for Setup to install.  If you want to exit, return to the Files dialog and select Exit." );

EXTERN LPSTR szMsg_Error   DEFVAL( "Error"; );
EXTERN LPSTR szMsg_Extract DEFVAL( "Extract" );
EXTERN LPSTR szMsg_ArcRE   DEFVAL( "Archive file read error." );
EXTERN LPSTR szMsg_ArcDC   DEFVAL( "Archive directory corrupt.");
EXTERN LPSTR szMsg_ArcDir  DEFVAL( "Can't find archive directory." );
EXTERN LPSTR szMsg_ArcExt  DEFVAL( "VSEEK failed during extraction.");
EXTERN LPSTR szMsg_ArcBuf  DEFVAL( "Can't read archive buffer.");

EXTERN LPSTR szMsg_Target  DEFVAL( "szTarget create failed!");
EXTERN LPSTR szMsg_UncW    DEFVAL( "uncompressed write failed!");

EXTERN LPSTR szMsg_BadData DEFVAL( "bad data" );
EXTERN LPSTR szMsg_CRC     DEFVAL( "CRC failure" );

EXTERN LPSTR szMsg_Dir     DEFVAL( "Directory" );
EXTERN LPSTR szMsg_BackDir DEFVAL( "Can't create the backup directory");
EXTERN LPSTR szMsg_MustDir DEFVAL( "You must enter a directory name.");
EXTERN LPSTR szMsg_NoDrive DEFVAL( "The specified drive does not exist." );
EXTERN LPSTR szMsg_NDir    DEFVAL( "Can't create directory");
EXTERN LPSTR szMsg_NDir2   DEFVAL( "Can't create the specified directory");
EXTERN LPSTR szMsg_Xist    DEFVAL( "a file of the same name already exists.");
EXTERN LPSTR szMsg_TheDir  DEFVAL( "The directory");
EXTERN LPSTR szMsg_NoXst   DEFVAL( "does not exist - do you want to create it?");

EXTERN LPSTR szMsg_NoSpc   DEFVAL( "Insufficient disk space" );
EXTERN LPSTR szMsg_NS      DEFVAL( "The specified drive does not have enough free space to install Qualitas MAX 8.0.");

EXTERN LPSTR szMsg_Xtr     DEFVAL( "Extracting");
EXTERN LPSTR szMsg_Copy    DEFVAL( "Copying");

EXTERN LPSTR szMsg_InsDsk  DEFVAL( "Please insert Disk");
EXTERN LPSTR szMsg_DskLoc  DEFVAL( "In the box below, enter the location of Disk");
EXTERN LPSTR szMsg_DskPath DEFVAL( "Enter the path to");
    
    // The %s in the strings below holds the place for the directory name.
EXTERN LPSTR szFmt_BUp     DEFVAL( "Backing up the %s directory - please wait ...");
EXTERN LPSTR szFmt_Rest    DEFVAL( "Restoring the %s directory - please wait ...");

    // these are the WinHelp keys.
    // they MUST match the topics in the Help File.
EXTERN LPSTR szHKEY_SrcDir  DEFVAL( "Source directory" );
EXTERN LPSTR szHKEY_Welcome DEFVAL( "Welcome to Qualitas MAX 8" );
EXTERN LPSTR szHKEY_RegInf  DEFVAL( "Registration information" );
EXTERN LPSTR szHKEY_RegConf DEFVAL( "Registration confirmation" );
EXTERN LPSTR szHKEY_Up      DEFVAL( "Update" );
EXTERN LPSTR szHKEY_Multi   DEFVAL( "MultiConfig" );
EXTERN LPSTR szHKEY_FLoc    DEFVAL( "Files and locations" );
EXTERN LPSTR szHKEY_FMod    DEFVAL( "File modifications" );
EXTERN LPSTR szHKEY_MaxNow  DEFVAL( "Would you like to run Maximize now?" );
EXTERN LPSTR szHKEY_Reboot  DEFVAL( "Would you like to reboot now?" );
EXTERN LPSTR szHKEY_Restart DEFVAL( "Would you like to restart now?" );
EXTERN LPSTR szHKEY_Config  DEFVAL( "Configuring Qualitas MAX" );
EXTERN LPSTR szHKEY_RefDir  DEFVAL( "Insert Reference Disk" );

    /* bcffnd_txt */
EXTERN char *MsgBcfFind 

    DEFVAL ( "This file created by %s "PROGNAME".\r\n"
	"The matching BCF for your system is:  %s\r\n"
	"Add the following statement to your %s profile\r\n"
	"to activate BIOS Compression.\r\n"
	AUTOBCF "        ; Load BIOS Compression File\r\n\n"
	"also, remove any USE= lines from this profile.\r\n" );

	/* nobcf_txt */
EXTERN char *MsgNoBcf
    DEFVAL( PROGNAME " did not locate a matching BCF for your system.\r\n\r\n"
	"Call Qualitas with the following information to properly identify\r\n"
	"your system.\r\n"
	"The BIOS CRC value is:  %04X\r\n" );

    /* nobcfsys_txt */
EXTERN char *MsgNoBcfSys 
	DEFVAL ( PROGNAME " has determined that your system is not a Micro Channel or IBM PS/2 386.\r\n"
	"Therefore, BIOS compression support is not available for this system.\r\n" ); 

EXTERN char *MsgAutoBcf
	DEFVAL( AUTOBCF "  ; Use BCF file @%04X.BCF" );

EXTERN LPSTR szMsg_Strip DEFVAL( "Stripping memory managers from CONFIG.SYS and AUTOEXEC.BAT - please wait ..." );
EXTERN LPSTR szMsg_ExtTitle DEFVAL( "Extracting MAX files" );
EXTERN LPSTR szMsg_ModCfg DEFVAL( "Modifying configuration files - please wait ..." );
EXTERN LPSTR szMsg_Mem DEFVAL( "Out of Memory!" );
EXTERN LPSTR szMsg_RefDisk DEFVAL( "Place the Microchannel Reference disk for this computer in the drive indicated and press CONTINUE." );
EXTERN LPSTR szMsg_BadRef DEFVAL( "This is not a valid Reference Disk! Files on the reference disk are necessary for the Adapter Optimization feature. Do you want to skip this feature?" );
EXTERN LPSTR szMsg_CopyADF DEFVAL( "Copying ADF files from reference disk." );
EXTERN LPSTR szMsg_GACon DEFVAL( "Resource Manager Conflict!" );

EXTERN LPSTR szFmt_GA_MM DEFVAL( "Setup has detected that %s is already installed.\nGo Ahead may not function properly unless %s is uninstalled.\nWould you like Go Ahead installed anyway?" );
EXTERN LPSTR szFmt_BCFErr DEFVAL( "Unable to copy %s to %s" );
EXTERN LPSTR szFmt_RWErr DEFVAL( "Error accessing file %s" );
EXTERN LPSTR szFmt_IDScan DEFVAL( "%*cSerial #  %s Licensed to %[^-\r\n] - %[^\r\n]" );

//------------------------------------------------------------------
#endif


