//' $Header:   P:/PVCS/MAX/BATPROC/BATPROC.H_V   1.1   02 Jun 1997 12:19:04   BOB  $

// BATPROC.H - Include file for BATPROC
//   Copyright (c) 1990  Rex C. Conn   GNU General Public License version 3


#ifdef COMPAT_4DOS
#define ARGMAX 128		// maximum number of arguments in line
#define CMDBUFSIZ 256		// size of command input buffer
#define MAXARGSIZ 255		// maximum size of a single argument
#else
#define ARGMAX 64		// maximum number of arguments in line
#define CMDBUFSIZ 128		// size of command input buffer
#define MAXARGSIZ 127		// maximum size of a single argument
#endif

#define STDIN 0 		// standard input, output, error, aux, & prn
#define STDOUT 1
#define STDERR 2
#define STDAUX 3
#define STDPRN 4

#define ENVMIN 256		// minimum and maximum environment size
#define ENVMAX 32000
#define ENVDEF 512

#define ALIASMIN 256		// minimum and maximum alias list size
#define ALIASMAX 32000
#define ALIASDEF 1024

#define HISTMIN 256		// minimum and maximum history list size
#define HISTMAX 8192
#define HISTDEF 1024

#define MAXFILENAME 80		// Maximum size of "d:\path\filename.ext"
#define MAXTERMLIST 256 	// Maximum elements in terminate_list

#define DIRSTACKSIZE 256	// directory stack size (for PUSHD/POPD)

#define BADQUOTES ((char *)-1)	// flag for unmatched quotes in line

#ifndef MAKEP
// make a far pointer from the segment and offset
#define MAKEP(seg,off) ((void far *)(((unsigned long)(seg) << 16) | (unsigned int)(off)))
#endif


// disable macro definitions of toupper() and tolower()
#undef toupper
#undef tolower


// BATPROC directory structure
typedef struct
{
	union {
		unsigned int f_time;
		struct {
			unsigned seconds : 5;
			unsigned minutes : 6;
			unsigned hours : 5;
		} file_time;
	} ft;
	union {
		unsigned int f_date;
		struct {
			unsigned days : 5;
			unsigned months : 4;
			unsigned years : 7;
		} file_date;
	} fd;
	long file_size;
	char attribute; 		// file attribute
	char file_name[13];
	char far *file_id;		// optional file description
	char expansion[4];		// for future expansion
} DIR_ENTRY;


// DIR flags
#define DIRFLAGS_ATTS_ONLY 1
#define DIRFLAGS_UPPER_CASE 2
#define DIRFLAGS_RECURSE 4
#define DIRFLAGS_JUSTIFY 8
#define DIRFLAGS_NO_HEADER 16
#define DIRFLAGS_SUMMARY_ONLY 32
#define DIRFLAGS_VSORT 64
#define DIRFLAGS_DIRS_ONLY 128


// array used by BATPROC for internal commands (indirect function calls)
typedef struct {
	char *cmdname;			// command name
	int (*func)(int, char**);	// pointer to function
	unsigned char enabled;		// enabled/disabled flag
	unsigned char pflag;		// command line parse control flag
} BUILTIN;

extern BUILTIN commands[];


// structure used by COLOR to set screen colors via ANSI escape sequences
typedef struct {
	char *shade;
	int ansi;
} ANSI_COLORS;


// redirection flags for STDIN, STDOUT, STDERR, and active pipes
typedef struct {
	int in;
	int out;
	int err;
	int pipe_open;
	char is_piped;
} REDIR_IO;


#define MAXBATCH 16			// maximum batch file nesting depth
#define ABORT_LINE 0x0FFF		// strange value to abort multiple cmds
#define BATCH_RETURN 0xABCD		// strange value to abort GOSUBs


// We define structures ("frames") for batch files; allowing us to nest batch
//   files without the overhead of calling a copy of the command processor
typedef struct {
	char *Batch_name;		// fully qualified filename
	char **Argv;			// pointer to argument list
	int bfd;			// file handle for batch file
	long read_offset;		// current file pointer positions
	long write_offset;
	int Argv_Offset;		// offset into Argv list
	int gsoffset;			// current gosub nesting level
	unsigned int line_number;	// current line in the batch file
	unsigned int line_length;	// length of current line
	unsigned int line_offset;	// character offset into current line
	int conditional;		// flag for IF or FOR in batch file
	char *local_dir;		// saved disk and directory
	char far *local_set;		// saved environment for SETLOCAL
	char echo_state;		// current batch echo state (0 = OFF)
	unsigned int start_line;	// Starting line_number for range
	unsigned int end_line;		// Ending line_number
} BATCHFRAME;

extern BATCHFRAME bframe[];


// BATPROC configurable parameters
typedef struct {
	unsigned int minhist;	// minimum length for history save
	int rows;		// number of screen rows
	int cursor_start;	// start line for cursor
	int cursor_end; 	// end line for cursor
	char ansi;		// use ANSI rather than BIOS
	char compound;		// command separator (default ^D)
	char escapechar;	// escape character (default ^X)
	char inputmode; 	// line input type - 0 = egets(), 1 = int 21 0Ah
	char editmode;		// line edit mode (default=overstrike)
	char noclobber; 	// noclobber (redirection) flag
	char switch_char;	// switch character
	char ucase;		// upper case filename display flag
	char batecho;		// batch file echo (default=on)
} DOS_CONFIGS;

extern DOS_CONFIGS cfgdos;


// Country information structure (international versions)
typedef struct {
	int fsDateFmt;
	char szCurrency[5];
	char szThousandsSeparator[2];
	char szDecimal[2];
	char szDateSeparator[2];
	char szTimeSeparator[2];
	char fsCurrencyFmt;
	char cDecimalPlace;
	char fsTimeFmt;
	long case_map_func;		// far pointer to function
	char szDataSeparator[2];
	int abReserved2[5];
} COUNTRYINFO;

extern COUNTRYINFO country_info;


// prototypes for BATPROC commands

int attrib(int, char **);
int battext(int, char **);
int beep(int, char **);
int bye(int, char **);
int call(int, char **);
int cd(int, char **);
int cdd(int, char **);
int chcp(int, char **);
int cls(int, char **);
int cmds(void);
int color(int, char **);
int copy(int, char **);
int ctty(int, char **);
int del(int, char **);
int delay(int, char **);
int describe(int, char **);
int df(int, char **);
int dir(int, char **);
int dirs(int, char **);
int drawbox(int, char **);
int drawline(int, char **);
int echo(int, char **);
int endlocal(int, char **);
int eset(int, char **);
int except(int, char **);
int forcmd(int, char **);
int global(int, char **);
int gosub(int, char **);
int gotocmd(int, char **);
int hist(int, char **);
int ifcmd(int, char **);
int inkey_input(int, char **);
int keystack(int, char **);
int list(int, char **);
int loadbtm(int, char **);
int log(int, char **);
int md(int, char **);
int memory(int, char **);
int mv(int, char **);
int path(int, char **);
int pause(int, char **);
int popd(int, char **);
int prompt(int, char **);
int pushd(int, char **);
int quit(int, char **);
int rd(int, char **);
int remark(int, char **);
int ren(int, char **);
int ret(int, char **);
int scr(int, char **);
int scrput(int, char **);
int set(int, char **);
int setbreak(int, char **);
int setdate(int, char **);
int select(int, char **);
int setdos(int, char **);
int setlocal(int, char **);
int settime(int, char **);
int shift(int, char **);
int swap(int, char **);
int tee(int, char **);
int timer(int, char **);
int type(int, char **);
int unset(int, char **);
int ver(int, char **);
int verify(int, char **);
int volume(int, char **);
int y(int, char **);


// EXEC.ASM, BATERRS.ASM - prototypes for miscellaneous
//   .ASM support routines

extern unsigned int previous_umb (void);
extern unsigned int new_umbs (void);
extern void init_tsr(void);
extern void deinit_tsr(void);
extern int pascal exec(char *, char far *, int, int *);
extern void set24(void);

extern int bios_key(void);
extern int get_switchar(void);
extern unsigned int pascal get_expanded(unsigned int *);
extern unsigned int get_cpu(void);
extern unsigned int get_ndp(void);
extern unsigned int get_extended(void);
extern unsigned int pascal get_xms(int *);
extern void pascal DosBeep(unsigned int, unsigned int);
extern void pascal screen(unsigned int, unsigned int);
extern void pascal window(int, int, int, int, int, int);
extern unsigned int get_video(void);
extern unsigned int pascal read_char(int, int);
extern void pascal write_char(int, int, int, int);
extern void pascal qprint(int, int, int, char *);

extern char far *pascal errmsgc(int);


// BATCH.C
extern int batch(int, char **);
extern int pascal iff_parsing(char *, char *);


// CMDS.C
extern int pascal findcmd(char *, int);


// DIRCMDS.C
extern void init_dir(void);
extern void _nxtrow(void);
extern void _page_break(void);
extern int pascal fstrcmp(char far *, char far *);
extern int pascal include_list(int, char *, DIR_ENTRY huge **, unsigned int *);
extern int pascal srch_dir(int, char *, DIR_ENTRY huge **, unsigned int *, int);


// ENV.C
extern unsigned char *pascal envget(char *, int);
extern int pascal addenv(char *, int);
extern unsigned char *pascal next_env(char *);
extern unsigned char *pascal end_of_env(char *);


// ERROR.C
extern int pascal usage(char *);
extern int pascal error(unsigned int, char *);


//EVAL.C
extern int pascal evaluate(char *);


// EXPAND.C
extern void pascal dup_handle(unsigned int, unsigned int);
extern void pascal killpipes(REDIR_IO *);
extern int pascal redir(char *, REDIR_IO *);
extern void pascal unredir(REDIR_IO *);
extern int pascal open_pipe(REDIR_IO *);
extern int pascal alias_expand(char *);
extern int pascal var_expand(char *, int);
extern void pascal escape_chars(char *);
extern void pascal addhist(char *);
extern char *pascal prev_hist(char *);
extern char *pascal next_hist(char *);
extern char *pascal first_arg(char *);
extern char *pascal ntharg(char *, int);
extern char *pascal scan(char *, char *, char *);


// FILECMDS.C
extern char *pascal show_atts(int);


// LINES.C
extern int pascal verify_row_col(unsigned int, unsigned int);


// MISC.C
extern void help(void);
extern void disk_reset(void);
extern void pascal dosfree(char far *);
extern char far *pascal dosmalloc(unsigned int *);
extern char far *pascal dosrealloc(char far *, long);
extern int pascal switch_arg(char *, char *);
extern int pascal isdelim(char);
extern char *pascal skipspace(char *);
extern void pascal collapse_whitespace(char *, char *);
extern char *pascal filecase(char *);
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
extern void getcountry(void);
extern char *pascal date_fmt(int, int, int);
extern void crlf(void);
extern void honk(void);
extern unsigned int pascal getkey(int);
extern int pascal yesno(char *);
extern char *pascal comma(unsigned long);
extern char *pascal strins(char *, char *);
extern void pascal more(char *, int);
extern char *pascal set_colors(char **, int *);


// OUTPUT.C
extern void cdecl qprintf(int, char *, ...);
extern void pascal qputs(int, char *);
extern void pascal qputslf(int, char *);
extern void pascal qputc(int, char);


// PARSER.C
extern void __cdecl break_handler(int foo);
extern int main(int, char **);
extern int batchcli(void);
extern int open_batch_file(int);
extern void close_batch_file(void);
extern int getline(int, char *, int);
extern int pascal command(char *);
extern int process_cmd(char *, char *);
extern int pascal parse_line(char *, char *, int (*)(int, char **), int);
extern int external(int, char **);
extern char *pascal searchpaths(char *);
extern char *OurStrdup(char *);


// SCREENIO.C
extern int pascal egets(char *, unsigned int, char);
extern void pascal incr_column(char, int *);
extern unsigned int screenrows(void);
extern unsigned int screencols(void);
extern void pascal setcursor(int);
extern void getcursor(void);
extern void pascal get_attribute(int *, int *);


// SYSCMDS.C
extern int pascal drive(char *);
extern int pascal __cd(char *);
extern int pascal getlabel(char *);
extern char *pascal gdate(void);
extern char *pascal gtime(void);


// constants for egets() and getkey()
#define COMMAND 0
#define DATA 1
#define ECHO 2
#define NO_ECHO 4
#define BIOS_KEY 8

#define FIND_FIRST 0x4E
#define FIND_NEXT 0x4F


// define the error return values (OS/2 defines in BSEERR.H)
#define ERROR_INVALID_FUNCTION		1
#define ERROR_FILE_NOT_FOUND		2
#define ERROR_PATH_NOT_FOUND		3
#define ERROR_TOO_MANY_OPEN_FILES	4
#define ERROR_ACCESS_DENIED		5
#define ERROR_INVALID_HANDLE		6
#define ERROR_ARENA_TRASHED		7
#define ERROR_NOT_ENOUGH_MEMORY 	8
#define ERROR_INVALID_BLOCK		9
#define ERROR_BAD_ENVIRONMENT		10
#define ERROR_BAD_FORMAT		11
#define ERROR_INVALID_ACCESS		12
#define ERROR_INVALID_DATA		13

#define ERROR_INVALID_DRIVE		15
#define ERROR_CURRENT_DIRECTORY 	16
#define ERROR_NOT_SAME_DEVICE		17
#define ERROR_NO_MORE_FILES		18
#define ERROR_WRITE_PROTECT		19
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
#define ERROR_NOT_SUPPORTED		50

#define ERROR_FILE_EXISTS		80
#define ERROR_DUP_FCB			81
#define ERROR_CANNOT_MAKE		82
#define ERROR_FAIL_I24			83
#define ERROR_OUT_OF_STRUCTURES 	84
#define ERROR_ALREADY_ASSIGNED		85
#define ERROR_INVALID_PASSWORD		86
#define ERROR_INVALID_PARAMETER 	87
#define ERROR_NET_WRITE_FAULT		88
#define ERROR_NO_PROC_SLOTS		89


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
#define ERROR_BATPROC_CONTENTS_LOST		10+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_NOT_ALIAS 		11+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_NO_ALIASES		12+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_ALIAS_LOOP		13+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_VARIABLE_LOOP		14+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_INVALID_DATE		15+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_INVALID_TIME		16+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_DIR_STACK_EMPTY		17+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_CANT_GET_DIR		18+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_LABEL_NOT_FOUND		19+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_OUT_OF_ENV		20+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_NOT_IN_ENV		21+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_MISSING_BATCH		22+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_EXCEEDED_NEST		23+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_MISSING_ENDTEXT		24+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_BAD_RETURN		25+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_ENV_SAVED 		26+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_ENV_NOT_SAVED		27+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_INVALID_SETLOCAL		28+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_NO_KEYSTACK		29+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_INVALID_DOS_VER		30+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_NOT_SWAPPING_MODE 	31+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_UNBALANCED_PARENS 	32+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_NO_EXPRESSION		33+OFFSET_BATPROC_MSG
#define ERROR_BATPROC_DIVIDE_BY_ZERO		34+OFFSET_BATPROC_MSG


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
#define F10		68+FBIT
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
#define END		79+FBIT
#define CUR_DOWN	80+FBIT
#define PgDn		81+FBIT
#define INS		82+FBIT
#define DEL		83+FBIT
#define CTL_LEFT	115+FBIT
#define CTL_RIGHT	116+FBIT
#define CTL_END 	117+FBIT
#define CTL_PgDn	118+FBIT
#define CTL_HOME	119+FBIT
#define CTL_PgUp	132+FBIT


#include "message.h"            // text message definitions for BATPROC

