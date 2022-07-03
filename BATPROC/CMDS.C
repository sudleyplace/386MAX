// CMDS.C - Table of internal commands for BATPROC
//   (c) 1990 Rex C. Conn  GNU General Public License version 3

#include <stdio.h>
#include <string.h>

#include "batproc.h"

#ifdef COMPAT_4DOS

// Array of internal commands in 4DOS
BUILTIN commands[] = {
	"ALIAS",set,0,1,
	"ATTRIB",attrib,0,0xFF,
	"BEEP",beep,0,0xFF,
	"BREAK",setbreak,1,0xFF,
	"CALL",call,1,0,
	"CANCEL",quit,0,1,
	"CD",cd,1,0xFF,
	"CDD",cdd,0,0xFF,
	"CHCP",chcp,1,0xFF,
	"CHDIR",cd,1,0xFF,
	"CLS",cls,1,1,
	"COLOR",color,0,1,
	"COPY",copy,1,1,
	"CTTY",ctty,1,0xFF,
	"DATE",setdate,1,1,
	"DEL",del,1,1,
	"DELAY",delay,0,0xFF,
	"DESCRIBE",describe,0,0xFF,
	"DIR",dir,1,1,
	"DIRS",dirs,0,1,
	"DRAWBOX",drawbox,0,1,
	"DRAWHLINE",drawline,0,1,
	"DRAWVLINE",drawline,0,1,
	"ECHO",echo,1,1,
	"ENDLOCAL",endlocal,0,1,
	"ERASE",del,1,1,
	"ESET",eset,0,0xFF,
	"EXCEPT",except,0,0,
	"EXIT",bye,1,1,
	"FOR",forcmd,1,0,
	"FREE",df,0,0xFF,
	"GLOBAL",global,0,0,
	"GOSUB",gosub,0,0xFF,
	"GOTO",gotocmd,1,0xFF,
	"HISTORY",hist,0,0xFF,
	"IF",ifcmd,1,1,
	"IFF",ifcmd,0,1,
	"INKEY",inkey_input,0,1,
	"INPUT",inkey_input,0,1,
	"KEYSTACK",keystack,0,1,
	"LIST",list,0,0xFF,
	"LOADBTM",loadbtm,0,0xFF,
	"LOG",log,0,1,
	"MD",md,1,0xFF,
	"MEMORY",memory,0,1,
	"MKDIR",md,1,0xFF,
	"MOVE",mv,0,1,
	"PATH",path,1,1,
	"PAUSE",pause,1,1,
	"POPD",popd,0,1,
	"PROMPT",prompt,1,1,
	"PUSHD",pushd,0,0xFF,
	"QUIT",quit,0,1,
	"RD",rd,1,0xFF,
	"REM",remark,1,1,
	"REN",ren,1,1,
	"RENAME",ren,1,1,
	"RETURN",ret,0,1,
	"RMDIR",rd,1,0xFF,
	"SCREEN",scr,0,1,
	"SCRPUT",scrput,0,1,
	"SELECT",select,0,0,
	"SET",set,1,1,
	"SETDOS",setdos,0,0xFF,
	"SETLOCAL",setlocal,0,1,
	"SHIFT",shift,1,1,
	"SWAPPING",swap,0,0xFF,
	"TEE",tee,0,1,
	"TEXT",battext,0,1,
	"TIME",settime,1,1,
	"TIMER",timer,0,0xFF,
	"TYPE",type,1,1,
	"UNALIAS",unset,0,0xFF,
	"UNSET",unset,0,0xFF,
	"VER",ver,1,1,
	"VERIFY",verify,1,0xFF,
	"VOL",volume,1,0xFF,
	"Y",y,0,1
};

#else

// Array of internal commands in COMMAND.COM
BUILTIN commands[] = {
	"BREAK",setbreak,1,0xFF,
	"CALL",call,1,0,
	"CD",cd,1,0xFF,
	"CHCP",chcp,1,0xFF,
	"CHDIR",cd,1,0xFF,
	"CLS",cls,1,1,
	"COPY",copy,1,1,
	"CTTY",ctty,1,0xFF,
	"DATE",setdate,1,1,
	"DEL",del,1,1,
	"DIR",dir,1,1,
	"ECHO",echo,1,1,
	"ERASE",del,1,1,
	"EXIT",bye,1,1,
	"FOR",forcmd,1,0,
	"GOTO",gotocmd,1,0xFF,
	"IF",ifcmd,1,1,
	"MD",md,1,0xFF,
	"MKDIR",md,1,0xFF,
	"PATH",path,1,1,
	"PAUSE",pause,1,1,
	"PROMPT",prompt,1,1,
	"RD",rd,1,0xFF,
	"REM",remark,1,1,
	"REN",ren,1,1,
	"RENAME",ren,1,1,
	"RMDIR",rd,1,0xFF,
	"SET",set,1,1,
	"SHIFT",shift,1,1,
	"TIME",settime,1,1,
	"TYPE",type,1,1,
	"VER",ver,1,1,
	"VERIFY",verify,1,0xFF,
	"VOL",volume,1,0xFF,
};

#endif


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
	static char near DELIMS[] = "%9[^    \t;,.\"`\\+=<>|]";
	register unsigned int i;
	char internal_name[10];

	// set the current compound command character & switch character
	DELIMS[4] = cfgdos.compound;
	DELIMS[5] = cfgdos.switch_char;

	// extract the command name (first argument)
	//   (including nasty kludge for nasty people who do "echo:"
	//   and a minor kludge for "y:")
	DELIMS[6] = (char)((cmd[1] == ':') ? ' ' : ':');
	sscanf(cmd,DELIMS,internal_name);

	// search for the command name
	for (i = 0; (i < NUMCMDS); i++) {
		if (stricmp(internal_name,commands[i].cmdname) == 0)
			return ((commands[i].enabled || eflag) ? i : -1);
	}

	return -1;
}

