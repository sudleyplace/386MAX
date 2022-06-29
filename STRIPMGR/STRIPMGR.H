//' $Header:   P:/PVCS/MAX/STRIPMGR/STRIPMGR.H_V   1.3   02 Jun 1997 10:46:38   BOB  $

// STRIPMGR.H - Include file for STRIPMGR
//	 Copyright (c) 1990  Rex C. Conn   All rights reserved


#define ARGMAX 128		// maximum number of arguments in line
#define CMDBUFSIZ 512		// size of command input buffer
#define MAXARGSIZ 255		// maximum size of a single argument
#define MAXFILENAME 80		// maximum filename length under DOS

#define PROGNAME "STRIPMGR"     // Until someone comes up with a better one...
#define MAXMGRS  256		// Maximum active lines in STRIPMGR.LST

#define STDIN 0 		// standard input, output, error, aux, & prn
#define STDOUT 1
#define STDERR 2
#define STDAUX 3
#define STDPRN 4

#define CALLBACK_OUTPUT 0	// ExternOutput value to display string
#define CALLBACK_YESNO	1	// Display yes/no dialog box and return result

#define DIRSTACKSIZE 256	// directory stack size (for PUSHD/POPD)

#define FARDATA _far		// Make MBPARSE data far

#define BADQUOTES ((char *)-1)	// flag for unmatched quotes in line

#ifndef MAKEP
// make a far pointer from the segment and offset
#define MAKEP(seg,off) ((void far *)(((unsigned long)(seg) << 16) | (unsigned int)(off)))
#endif


// disable macro definitions of toupper() and tolower()
#undef toupper
#undef tolower


// array used by BATPROC for internal commands (indirect function calls)
typedef struct {
	char *cmdname;			// command name
	int (*func)(int, char **);	// pointer to function
	unsigned char enabled;		// enabled/disabled flag
	unsigned char pflag;		// command line parse control flag
} BUILTIN;

extern BUILTIN commands[];


// redirection flags for STDIN, STDOUT, STDERR, and active pipes
typedef struct {
	int in;
	int out;
	int err;
	int pipe_open;
	char is_piped;
} REDIR_IO;


#define MAXBATCH 16 	// maximum batch file nesting depth
#define ABORT_LINE 0x0FFF	// strange value to abort multiple cmds
#define BATCH_RETURN 0x7ABC // strange value to abort GOSUBs
// #define IN_MEMORY_FILE 0x7FFF	// flag for .BTM file


// We define structures ("frames") for batch files; allowing us to nest batch
//	 files without the overhead of calling a copy of the command processor
typedef struct {
	char *Batch_name;		// fully qualified filename
	char **Argv;			// pointer to argument list
	int bfd;			// file handle for batch file
	long read_offset;		// current file pointer positions
	long write_offset;
	int Argv_Offset;		// offset into Argv list
	int gsoffset;				// current gosub nesting level
	unsigned int line_offset;	// offset in current line in file
	unsigned int line_length;	// length of line fragment (for IF)
	unsigned int count; 	// number of memory managers found
	char *backup;			// name of backup file (xxx.00n)
	int DOS6Flag;			// Set if we've encountered an
					// if or goto/gosub using %CONFIG%
} BATCHFRAME;

extern BATCHFRAME bframe[];


// BATPROC configurable parameters
typedef struct {
	char compound;		// command separator (default ^D)
	char escapechar;	// escape character (default ^X)
	char noclobber; 	// noclobber (redirection) flag
	char switch_char;	// switch character
} DOS_CONFIGS;

extern DOS_CONFIGS cfgdos;


// prototypes for BATPROC commands

int bye(int, char **);
int call(int, char **);
int cd(int, char **);
int cdd(int, char **);
int forcmd(int, char **);
int gosub_cmd(int, char **);
int goto_cmd(int, char **);
int ifcmd(int, char **);
int path(int, char **);
int popd(int, char **);
int pushd(int, char **);
int remark(int, char **);
int setdos(int, char **);


// BATCH.C
extern int batch(int, char **);
extern int pascal goto_label(char *, int);
extern int pascal iff_parsing(char *, char *);


// CMDS.C
extern int pascal findcmd(char *, int);


// ERROR.C
extern int pascal usage(char *);
extern int pascal error(unsigned int, char *);


// EXPAND.C
extern void pascal dup_handle(unsigned int, unsigned int);
extern void pascal killpipes(REDIR_IO *);
extern int pascal redir(char *, REDIR_IO *);
extern void pascal unredir(REDIR_IO *);
extern int pascal open_pipe(REDIR_IO *);
extern int pascal var_expand(char *, int);
extern void pascal escape_chars(char *);
extern char *pascal first_arg(char *);
extern char *pascal ntharg(char *, int);
extern char *pascal scan(char *, char *, char *);


// MISC.C
extern void pascal dosfree(char far *);
extern char far *pascal dosmalloc(unsigned int *);
extern char far *pascal dosrealloc(char far *, long);
extern int pascal switch_arg(char *, char *, int);
extern void pascal remove_switches(char *, int);
extern int pascal isdelim(char);
extern char *pascal skipdelims(char *, char *);
extern char *pascal skipspace(char *);
extern void pascal collapse_whitespace(char *, char *);
extern void pascal strip_trailing(char *, char *);
extern char *pascal gcdir(char *);
extern int pascal gcdisk(char *);
extern char *pascal path_part(char *);
extern char *pascal fname_part(char *);
extern char *pascal ext_part(char *);
extern void pascal copy_filename(char *, char *);
extern void pascal mkdirname(char *, char *);
extern char *pascal mkfname(char *);
extern void pascal insert_path(char *, char *, char *);
extern int pascal is_file(char *);
extern int pascal is_dir(char *);
extern int pascal is_dev(char *);
extern char *pascal find_file(int, char *, int, struct find_t *, char *);
extern void crlf(void);
extern unsigned int pascal getkey(int);
extern int pascal yesno(char *, long, char FARDATA *, char FARDATA *, char *);
extern char *pascal strins(char *, char *);
extern int pascal fstrcmp(char far *, char far *);
extern int pascal rewrite_file(int, char *, long, long);
extern int get_switchar(void);


// OUTPUT.C
extern void cdecl qprintf(int, char *, ...);
extern void pascal qputs(int, char *);
extern void pascal qputslf(int, char *);
extern void pascal qputc(int, char);


// PARSER.C
extern void _cdecl break_handler(int);
extern int main(int, char **);
extern int batchcli(void);
extern int open_batch_file(void);
extern void close_batch_file(void);
extern int getline(int, char *, int);
extern int pascal command(char *);
extern int process_cmd(char *, char *);
extern int pascal parse_line(char *, char *, int (*)(int, char **), int);
extern int external(int, char **);
extern char *pascal searchpaths(char *);
extern char *OurStrdup(char *);
extern char (_far *ExternOutput) (int, char _far *);


// SYSCMDS.C
extern int pascal drive(char *);
extern int pascal __cd(char *);


// constants for getkey()
#define ECHO 2
#define NO_ECHO 4
#define BIOS_KEY 8

#define FIND_FIRST 0x4E
#define FIND_NEXT 0x4F


// define the error return values
#define ERROR_INVALID_FUNCTION		1
#define ERROR_FILE_NOT_FOUND		2
#define ERROR_PATH_NOT_FOUND		3
#define ERROR_TOO_MANY_OPEN_FILES	4
#define ERROR_ACCESS_DENIED 	5
#define ERROR_INVALID_HANDLE		6
#define ERROR_ARENA_TRASHED 	7
#define ERROR_NOT_ENOUGH_MEMORY 	8
#define ERROR_INVALID_BLOCK 	9
#define ERROR_BAD_ENVIRONMENT		10
#define ERROR_BAD_FORMAT		11
#define ERROR_INVALID_ACCESS		12
#define ERROR_INVALID_DATA		13

#define ERROR_INVALID_DRIVE 	15
#define ERROR_CURRENT_DIRECTORY 	16
#define ERROR_NOT_SAME_DEVICE		17
#define ERROR_NO_MORE_FILES 	18
#define ERROR_WRITE_PROTECT 	19
#define ERROR_BAD_UNIT			20
#define ERROR_NOT_READY 		21
#define ERROR_BAD_COMMAND		22
#define ERROR_CRC			23
#define ERROR_BAD_LENGTH		24
#define ERROR_SEEK			25
#define ERROR_NOT_DOS_DISK		26
#define ERROR_SECTOR_NOT_FOUND		27
#define ERROR_OUT_OF_PAPER		28
#define ERROR_WRITE_FAULT		29
#define ERROR_READ_FAULT		30
#define ERROR_GEN_FAILURE		31
#define ERROR_SHARING_VIOLATION 	32
#define ERROR_LOCK_VIOLATION		33
#define ERROR_WRONG_DISK		34
#define ERROR_FCB_UNAVAILABLE		35
#define ERROR_SHARING_BUFFER_EXCEEDED	36
#define ERROR_NOT_SUPPORTED 	50

#define ERROR_FILE_EXISTS		80
#define ERROR_DUP_FCB			81
#define ERROR_CANNOT_MAKE		82
#define ERROR_FAIL_I24			83
#define ERROR_OUT_OF_STRUCTURES 	84
#define ERROR_ALREADY_ASSIGNED		85
#define ERROR_INVALID_PASSWORD		86
#define ERROR_INVALID_PARAMETER 	87
#define ERROR_NET_WRITE_FAULT		88
#define ERROR_NO_PROC_SLOTS 	89


// BATPROC-specific error messages

#define OFFSET_BATPROC_MSG			512

#define ERROR_BATPROC_BAD_SYNTAX		0+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_UNKNOWN_COMMAND		1+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_COMMAND_TOO_LONG		2+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_NO_CLOSE_QUOTE		3+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_CANT_OPEN 		4+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_CANT_CREATE		5+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_CANT_DELETE		6+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_READ_ERROR		7+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_WRITE_ERROR		8+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_DUP_COPY			9+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_CONTENTS_LOST 	10+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_NOT_ALIAS 		11+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_NO_ALIASES		12+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_ALIAS_LOOP		13+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_VARIABLE_LOOP 	14+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_INVALID_DATE		15+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_INVALID_TIME		16+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_DIR_STACK_EMPTY		17+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_CANT_GET_DIR		18+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_LABEL_NOT_FOUND		19+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_OUT_OF_ENV		20+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_NOT_IN_ENV		21+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_MISSING_BATCH 	22+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_EXCEEDED_NEST 	23+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_MISSING_ENDTEXT		24+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_BAD_RETURN		25+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_ENV_SAVED 		26+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_ENV_NOT_SAVED 	27+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_INVALID_SETLOCAL		28+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_NO_KEYSTACK		29+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_INVALID_DOS_VER		30+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_NOT_SWAPPING_MODE 	31+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_UNBALANCED_PARENS 	32+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_NO_EXPRESSION 	33+OFFSET_BATPROC_MSG


// BATPROC error return codes
#define USAGE_ERR 1
#define NO_FILES 2
#define CTRLC 3
#define ERROR_EXIT 4
#define SHARE_ERR 5
#define REDIR_ERROR 0xFD
#define INVALID_COMMAND 0xFE
#define INTERNAL_ERROR 0xFF


#define EOS '\0'                // standard end of string
#define FALSE 0
#define TRUE 1

#define SOH 1
#define CTRLC 3
#define EOT 4
#define ACK 6
#define BELL 7
#define BACKSPACE 8
#define BS 8
#define TAB 9
#define LF 10
#define LINEFEED 10
#define FORMFEED 12
#define FF 12
#define CR 13
#define XON 17
#define DC2 18
#define XOFF 19
#define DC4 20
#define NAK 21
#define SYN 22
#define ETB 23
#define CRC 'C'
#define CAN 24
#define EM 25
#define EoF 26
#define ESC 27
#define ESCAPE 27
#define SPACE 32
#define DELETE 127
#define CTL_BS 127


#define FBIT 256

#define F1		59+FBIT 	// function keys
#define F2		60+FBIT
#define F3		61+FBIT
#define F4		62+FBIT
#define F5		63+FBIT
#define F6		64+FBIT
#define F7		65+FBIT
#define F8		66+FBIT
#define F9		67+FBIT
#define F10 	68+FBIT
#define SHFT_F1 	84+FBIT
#define SHFT_F2 	85+FBIT
#define SHFT_F3 	86+FBIT
#define SHFT_F4 	87+FBIT
#define SHFT_F5 	88+FBIT
#define SHFT_F6 	89+FBIT
#define SHFT_F7 	90+FBIT
#define SHFT_F8 	91+FBIT
#define SHFT_F9 	92+FBIT
#define SHFT_F10	93+FBIT
#define CTL_F1		94+FBIT
#define CTL_F2		95+FBIT
#define CTL_F3		96+FBIT
#define CTL_F4		97+FBIT
#define CTL_F5		98+FBIT
#define CTL_F6		99+FBIT
#define CTL_F7		100+FBIT
#define CTL_F8		101+FBIT
#define CTL_F9		102+FBIT
#define CTL_F10 	103+FBIT
#define ALT_F1		104+FBIT
#define ALT_F2		105+FBIT
#define ALT_F3		106+FBIT
#define ALT_F4		107+FBIT
#define ALT_F5		108+FBIT
#define ALT_F6		109+FBIT
#define ALT_F7		110+FBIT
#define ALT_F8		111+FBIT
#define ALT_F9		112+FBIT
#define ALT_F10 	113+FBIT
#define HOME		71+FBIT
#define CUR_UP		72+FBIT
#define PgUp		73+FBIT
#define CUR_LEFT	75+FBIT
#define CUR_RIGHT	77+FBIT
#define END 	79+FBIT
#define CUR_DOWN	80+FBIT
#define PgDn		81+FBIT
#define INS 	82+FBIT
#define DEL 	83+FBIT
#define CTL_LEFT	115+FBIT
#define CTL_RIGHT	116+FBIT
#define CTL_END 	117+FBIT
#define CTL_PgDn	118+FBIT
#define CTL_HOME	119+FBIT
#define CTL_PgUp	132+FBIT


#include "message.h"            // text message definitions for BATPROC

