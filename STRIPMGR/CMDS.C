// CMDS.C - Table of internal commands for STRIPMGR
//   (c) 1990 Rex C. Conn  GNU General Public License version 3

#include <stdio.h>
#include <string.h>

#include "stripmgr.h"

// Array of internal commands in 4DOS
BUILTIN commands[] = {
	"ALIAS",remark,0,1,
	"ATTRIB",remark,0,1,
	"BEEP",remark,0,1,
	"BREAK",remark,1,1,
	"CALL",call,1,0,
	"CANCEL",remark,0,1,
	"CD",cd,1,0xFF,
	"CDD",cdd,0,0xFF,
	"CHCP",remark,1,0xFF,
	"CHDIR",cd,1,0xFF,
	"CLS",remark,1,1,
	"COLOR",remark,0,1,
	"COPY",remark,1,1,
	"CTTY",remark,1,0xFF,
	"DATE",remark,1,1,
	"DEL",remark,1,1,
	"DELAY",remark,0,0xFF,
	"DESCRIBE",remark,0,0xFF,
	"DIR",remark,1,1,
	"DIRS",remark,0,1,
	"DRAWBOX",remark,0,1,
	"DRAWHLINE",remark,0,1,
	"DRAWVLINE",remark,0,1,
	"ECHO",remark,1,1,
	"ENDLOCAL",remark,0,1,
	"ERASE",remark,1,1,
	"ESET",remark,0,0xFF,
	"EXCEPT",remark,0,0,
	"EXIT",bye,1,1,
	"FOR",forcmd,1,0,
	"FREE",remark,0,0xFF,
	"GLOBAL",remark,0,0,
	"GOSUB",gosub_cmd,0,0xFF,
	"GOTO",goto_cmd,1,0xFF,
	"HISTORY",remark,0,0xFF,
	"IF",ifcmd,1,1,
	"IFF",ifcmd,0,1,
	"INKEY",remark,0,1,
	"INPUT",remark,0,1,
	"KEYSTACK",remark,0,1,
	"LIST",remark,0,0xFF,
	"LOADBTM",remark,0,0xFF,
	"LOG",remark,0,1,
	"MD",remark,1,0xFF,
	"MEMORY",remark,0,1,
	"MKDIR",remark,1,0xFF,
	"MOVE",remark,0,1,
	"PATH",path,1,1,
	"PAUSE",remark,1,1,
	"POPD",popd,0,1,
	"PROMPT",remark,1,1,
	"PUSHD",pushd,0,0xFF,
	"QUIT",remark,0,1,
	"RD",remark,1,0xFF,
	"REM",remark,1,1,
	"REN",remark,1,1,
	"RENAME",remark,1,1,
	"RETURN",remark,0,1,
	"RMDIR",remark,1,0xFF,
	"SCREEN",remark,0,1,
	"SCRPUT",remark,0,1,
	"SELECT",remark,0,0,
	"SET",remark,1,1,
	"SETDOS",setdos,0,0xFF,
	"SETLOCAL",remark,0,1,
	"SHIFT",remark,1,1,
	"SWAPPING",remark,0,0xFF,
	"TEE",remark,0,1,
	"TEXT",remark,0,1,
	"TIME",remark,1,1,
	"TIMER",remark,0,0xFF,
	"TYPE",remark,1,1,
	"UNALIAS",remark,0,0xFF,
	"UNSET",remark,0,0xFF,
	"VER",remark,1,1,
	"VERIFY",remark,1,0xFF,
	"VOL",remark,1,0xFF,
	"Y",remark,0,1
};

#define NUMCMDS (sizeof(commands)/sizeof(BUILTIN))	// # of internal cmds


// enable the 4DOS commands if 4DOS is loaded
void init_4dos_cmds(void)
{
	register unsigned int i;

	for (i = 0; (i < NUMCMDS); i++)
		commands[i].enabled = 1;
}


// do binary search to find command in internal command table & return index
int pascal findcmd(register char *cmd, int eflag)
{
	register unsigned int i;

	DELIMS[4] = cfgdos.compound;
	DELIMS[5] = cfgdos.switch_char;

	// extract the command name (first argument)
	//   (including nasty kludge for nasty people who do "echo:")
	if (eflag == 0) {
		cmd = first_arg(cmd);
		sscanf(cmd,DELIMS,cmd);
	}

	// search for the command name
	for (i = 0; (i < NUMCMDS); i++) {
		if (stricmp(cmd,commands[i].cmdname) == 0)
			return ((commands[i].enabled || eflag) ? i : -1);
	}

	return -1;
}

