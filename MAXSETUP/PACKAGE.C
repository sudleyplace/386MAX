/***********************************************************
'$Header:   P:/PVCS/MAX/MAXSETUP/PACKAGE.C_V   1.0   06 Sep 1995 15:36:06   HENRY  $

Name:	 package.c


Desc:	 Qualitas 386MAX packaging utility


Author:  Bob Depelteau


  (c) Copyright 1991-92, Qualitas, Inc. All rights reserved


***********************************************************/

//define STATS

#include <dos.h>
#include <stdio.h>
#include <io.h>
#include <fcntl.h>
#include <sys\types.h>
#include <sys\stat.h>
#include <direct.h>
#include <string.h>
#include <stdlib.h>
#include <malloc.h>
#include <time.h>
#include <graph.h>
#include <bios.h>
#include "keycodes.h"
#include "implode.h"
#include "package.h"

#define VERSION 0x0102

#if VERSION < 999
static char version[] = {(((VERSION>>8)&0xf)+'0'),
			'.',
			(((VERSION>>4)&0xf)+'0'),
			((VERSION&0xf)+'0'),
			0};
#else
static char version[] = {(((VERSION>>12)&0xf)+'0'),
			(((VERSION>>8)&0xf)+'0'),
			'.',
			(((VERSION>>4)&0xf)+'0'),
			((VERSION&0xf)+'0'),
			0};
#endif

word tssb,tlsb,tmsb;
word tssb2,tlsb2,tmsb2;

static word InstallSpace;

static word fNum;	     /* compression / file IO variables */
static FDIR *fDir;
static int  inFile;
static int  outFile;
static long writeCRC;
static long writeCount;
#define WORKBUFSIZE 0xc000
static char far *workBuf;
static char *prodName="PRODUCT   ";

static word DirSpace;
static word NumOfExt;
static long extPtr[10];

static word SelectedProds;
static word NumOfProds;
static PRODUCTLIST Prods[5];  /* enough room for 5 products */
static word NumOfComProds;
static PRODUCTLIST ComProds[3];/* storage for common files */

static word SelectedDisk;
static word NumOfDisks;
static DISKTYPE Disks[8];

#ifdef STATS
static char cmpstat[255];
#endif

static char keyMsg1[] = "Use the arrow keys to highlight an item.";
static char keyMsg2[] = "Type return to select it, or ESC to abort.";
static char keyMsg3[] = "Type return to select it, or ESC to return.";

static MENU productMenu =
   {
    8,	   /* number of rows of text */
    1,	   /* starting line of menu */
    5,	   /* number of menu items */
    0,	   /* last selected menu item */
    2,28,YELLOW,"Product Menu",
    4,25,GREEN ,"                     ",
    6,25,GREEN ,"                     ",
    8,25,GREEN ,"                     ",
   10,25,GREEN ,"                     ",
   12,25,GREEN ,"                     ",
   14,18,YELLOW,keyMsg1,
   15,18,YELLOW,keyMsg3
   };

static MENU diskMenu =
   {
   10,	   /* number of rows of text */
    1,	   /* starting line of menu */
    7,	   /* number of menu items */
    0,	   /* last selected menu item */
    2,25,YELLOW,"Target Disk Type Menu",
    4,25,GREEN ,"                     ",
    6,25,GREEN ,"                     ",
    8,25,GREEN ,"                     ",
   10,25,GREEN ,"                     ",
   12,25,GREEN ,"                     ",
   14,25,GREEN ,"                     ",
   16,25,GREEN ,"                     ",
   18,18,YELLOW,keyMsg1,
   19,18,YELLOW,keyMsg3
   };

static MENU cmdHelpMenu =
   {
    8,	   /* number of rows of text */
    0,	   /* starting line of menu */
    0,	   /* number of menu items */
    0,	   /* last selected menu item */
    2,28,YELLOW,"Command Line Help",
    4,10,WHITE ,"Valid switches are;",
    6,10,WHITE ,"/p=<name> includes product <name> in the packaging.",
    8,10,WHITE ,"/d=<nn> selects diskette type <nn> to build archive files for.",
   10, 5,WHITE ,"Note:",
   11, 5,WHITE ,"The name and diskette type are determined by the configuration",
   12, 5,WHITE ,"file setup.  Please examine PAGKAGE.CFG for more information.",
   23,20,YELLOW,"Type any key to return to main menu",
   };

static MENU mainMenu =
   {
   18,	   /* number of rows of text */
    1,	   /* starting line of menu */
    4,	   /* number of menu items */
    0,	   /* last selected menu item */
    2,30,YELLOW,"Main Menu",
    4,25,GREEN ," Select products   ",
    6,25,GREEN ," Select disk type  ",
    8,25,GREEN ," Build product     ",
   10,25,GREEN ," Command line help ",
   14,18,YELLOW,keyMsg1,
   15,18,YELLOW,keyMsg2,
   18, 0,YELLOW,"컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴"
		"컴컴컴컴컴컴컴컴컴컴",
   19, 5,WHITE ,"Product group",
   19,30,WHITE ,"Destination disk",
   19,60,WHITE ,"Install space",
   20,30,GREEN ,"                    ",
   20,60,GREEN ,"           ",
   20, 5,GREEN ,"                    ",
   21, 5,GREEN ,"                    ",
   22, 5,GREEN ,"                    ",
   23, 5,GREEN ,"                    ",
   24, 5,GREEN ,"                    ",
   };

static char configpath[128];
static char altfigpath[128];
static char exedrive[_MAX_DRIVE],exepath[_MAX_DIR];
static char exename[_MAX_FNAME],exeext[_MAX_EXT];

char	*TempDir = "temp\\";	// Default temporary directory

/* function prototypes */
void set_temp(void);
static void setSpace(FILE *fd);
static void setDisk(char *str);
static void setProduct(char *str, FILE *fd);
static void setComProd(char *str, FILE *fd);
static int  readConfig (void);
static word chkey (void);
static word getkey (void);
static void qprint (int row,int col,int att,char *str);
static void bltscn (MENU *scn);
static int  menu (MENU *m);
static void cls (void);
static void setcur (word size,word pos);
static void getcur (word *size,word *pos);
static void menuDriver(void);
static void selectProduct (void);
static void selectDiskType (void);
static void buildProduct (void);
static void commandHelp (void);
static void setProdMsg(int index);
static void setMainMenu (void);
static word splitName (char *str,char *pname,char *fname);
static void getName (char *pn, char *fn);
static unsigned far pascal ReadBuff(char far *buff, unsigned short int far *size);
static unsigned far pascal WriteBuff(char far *buff, unsigned short int far *size);
static unsigned far pascal CountBuff(char far *buff, unsigned short int far *size);
static word compressFile (word dir,PRODUCTLIST *pid,word fil);
static word buildArchive(void);
static int fCompare (const void *elem1,const void *elem2);
static word setExtent (void);
static word buildDir (void);
static word parse (char *cmd);
static unsigned long gettime(void);
static void setUpTimer (void);
static void reSetTimer (void);
static void hex4 (char *str,word num);
static void expandMenus (void);

void main (int argc,char **argv)
   {
   word i;

   set_temp ();

   _splitpath (argv[0],exedrive,exepath,exename,exeext);

   sprintf (configpath,"%s.cfg",exename);
   sprintf (altfigpath,"%s%s%s.cfg",exedrive,exepath,exename);

   if (readConfig ())
      {
      printf ("Error reading configuration file %s\n",configpath);
      exit (-1);
      }
   if (argc>1)
      {
      for (i=1;i<(word)argc;++i)
	 if (parse (argv[i]))
	    {
	    printf ("Command line error; unable to parse option %d (%s)\n",i,argv[i]);
	    exit (-1);
	    }
      buildProduct ();
      }
   else
      {
      if (*BiosCRTHEIGHT==49)
	 expandMenus();
      menuDriver();
      }
   exit (0);
   }

void expandMenus (void)
   {
   int i;
   for (i=0;i<mainMenu.items;i++)
      mainMenu.msgs[i].row*=2;

   for (i=0;i<diskMenu.items;i++)
      diskMenu.msgs[i].row*=2;

   for (i=0;i<productMenu.items;i++)
      productMenu.msgs[i].row*=2;

   for (i=0;i<cmdHelpMenu.items;i++)
      cmdHelpMenu.msgs[i].row*=2;
   }

void hex4 (char *str,word num)
   {
   int i;
   sprintf (str,"%X",num);
   while (strlen(str)<4)
      {
      for (i=strlen(str)+1;i>0;--i)
	 str[i]=str[i-1];
      str[0]='0';
      }
   }

void set_temp(void)
{
 int i;
 char *t;

 if ((t = getenv ("TMP")) || (t = getenv ("TEMP"))) {
 	TempDir = t;
 }

 // Get a directory name without the trailing backslash
 i = strlen(TempDir = t) - 1;
 if (TempDir[i] == '\\')	TempDir[i] = '\0';

 // If we're using the default, it probably needs to be created
 if (!t) (void) mkdir (TempDir);

 // Now ensure we have a form with trailing backslash
 strcat (TempDir, "\\");

}

/***********************************************************

Name:	 parse

Format:  word parse (* cmd)

Desc:	 Parse a command line option

Input:	 pointer to command

Output:  none

Returns: none

Comment:

***********************************************************/
word parse (char *cmd)
   {
   word i;
   for (i=0;i<strlen(cmd);++i) /* convert command to upper case */
      {
      if (cmd[i]>='a' && cmd[i]<='z')
	 cmd[i]&=0xdf;
      }

   switch (*cmd++)
      {
   case '/':
   case '-':
      switch (*cmd++)
	 {
      case 'p':
      case 'P':
	 if (*cmd++ != '=')
	    return (1);
	 for (i=0;i<NumOfProds;++i)
	    {
	    if (strcmp (cmd,Prods[i].name)==0)
	       {
	       SelectedProds|=Prods[i].att;
	       break;
	       }
	    }
	 if (i==NumOfProds)
	    {
	    printf ("Unknown product descriptor <%s>\n",cmd);
	    return (1);
	    }
	 break;
      case 'd':
      case 'D':
	 if (*cmd++ != '=')
	    return (1);
	 SelectedDisk=atoi(cmd);
	 if (SelectedDisk>=NumOfDisks)
	    {
	    printf ("Unknown disk type; <0-%d are valid>\n",NumOfDisks-1);
	    return (1);
	    }
	 break;
      default:
	 return (1);
	 }
      break;
   default:
      return (1);
      }
   return (0);
   }

/***********************************************************

Name:	 menu

Format:  menu (MENU m)

Desc:	 Processes a menu structure and does the screen handling

Input:	 menu structure

Output:  none

Returns: the menu item selected (0-n) or -1 if ESC was typed

Comment:

***********************************************************/
menu (MENU *m)
   {
   word i,mi,cs,cp;
   getcur (&cs,&cp);
   setcur (0x2020,-1);
   cls ();
   bltscn (m);
   while (1)
      {
      mi=m->last+m->mstart;
      qprint ( m->msgs[mi].row,
	       m->msgs[mi].col,
	       INVGREEN,
	       m->msgs[mi].msg);
      i=getkey();
      qprint ( m->msgs[mi].row,
	       m->msgs[mi].col,
	       m->msgs[mi].att,
	       m->msgs[mi].msg);
      switch (i)
	 {
      case KEY_UP:
      case KEY_LEFT:
	 if (m->last)
	    m->last--;
	 else
	    m->last=m->sels-1;
	 break;
      case KEY_DN:
      case KEY_RIGHT:
	 if (++m->last >= m->sels)
	    m->last=0;
	 break;
      case KEY_CR:
	 setcur (cs,0);
	 return (m->last);
      case KEY_ESC:
	 setcur (cs,0);
	 return (-1);
      default:
	 putchar (7);
	 }
      }
   }

/***********************************************************

Name:	 menuDriver

Format:  void menuDriver(void)

Desc:	 forground menu processor (main menu)

Input:	 none

Output:  none

Returns: none

Comment:

***********************************************************/
void menuDriver(void)
   {
   setMainMenu ();
   while (1)
      {
      switch (menu (&mainMenu))
	 {
      case 0:		      /* select products */
	 selectProduct ();
	 setMainMenu ();
	 break;
      case 1:		      /* select disk type */
	 selectDiskType ();
	 setMainMenu ();
	 break;
      case 2:		      /* build a product */
	 buildProduct ();
	 printf ("\nBuild complete. Type any key to continue.\n");
	 getkey();
	 break;
      case 3:		      /* command line help */
	 commandHelp ();
	 break;
      default:
	 return;
	 }
      }
   }

void setMainMenu (void)
   {
   word i,x;
   for (i=0;i<NumOfProds;++i)
      mainMenu.msgs[i+13].msg[0]=0;
   if (SelectedProds)
      {
      for (x=13,i=0;i<NumOfProds;++i)
	 {
	 if (Prods[i].att & SelectedProds)
	    sprintf (mainMenu.msgs[x++].msg,"%s",Prods[i].name);
	 }
      }
   else
      sprintf (mainMenu.msgs[13].msg,"None selected ");
   sprintf (mainMenu.msgs[11].msg,"%s",Disks[SelectedDisk].type);
   sprintf (mainMenu.msgs[12].msg,"%d Kb",InstallSpace);
   }


/***********************************************************

Name:	 selectProduct

Format:  void selectProduct (void)

Desc:	 select products to build

Input:	 none

Output:  none

Returns: none

Comment:

***********************************************************/
void selectProduct (void)
   {
   word i;
   for (i=0;i<NumOfProds;++i)
      setProdMsg(i);
   productMenu.sels=NumOfProds;
   while ((i=menu (&productMenu))!=-1)
      {
      SelectedProds^=Prods[i].att;
      setProdMsg(i);
      }
   }

void setProdMsg(int index)
   {
   int i;
   if (Prods[index].att & SelectedProds)
      sprintf (productMenu.msgs[index+1].msg," Deselect %s",Prods[index].name);
   else
      sprintf (productMenu.msgs[index+1].msg," Select %s",Prods[index].name);

   for (i=strlen(productMenu.msgs[index+1].msg);i<20;++i)
      productMenu.msgs[index+1].msg[i]=' ';
   productMenu.msgs[index+1].msg[i]=0;
   }

/***********************************************************

Name:	 selectDiskType

Format:  void selectDiskType (void)

Desc:	 put the menu to select the types of disks available

Input:	 none

Output:  none

Returns: none

Comment:

***********************************************************/
void selectDiskType (void)
   {
   word i,x;
   diskMenu.sels=NumOfDisks;
   for (i=0;i<NumOfDisks;++i)
      {
      sprintf (diskMenu.msgs[i+1].msg," %s",Disks[i].type);
      for (x=strlen(diskMenu.msgs[i+1].msg);x<20;++x)
	 diskMenu.msgs[i+1].msg[x]=' ';
      diskMenu.msgs[i+1].msg[x]=0;
      }
   i=menu (&diskMenu);
   if (i!=-1)
      SelectedDisk=i;
   }

/***********************************************************

Name:	 buildProduct

Format:  void buildProduct (void)

Desc:	 build the desired product

Input:	 none

Output:  none

Returns: none

Comment: it is assumed all configuration is setup and
	 correct.

***********************************************************/
void buildProduct (void)
   {
#ifdef STATS
   FILE *statlog;
#endif
   word i,x,f,r,err;
   cls ();
   printf ("Qualitas product packaging utility v%s\n\n",version);

   printf ("Packaging ");
   for (i=0;i<NumOfProds;++i)
      {
      if (SelectedProds & Prods[i].att)
	 printf ("%s ",Prods[i].name);
      }
   printf ("for %s diskettes\n\n",Disks[SelectedDisk].type);

   fNum=f=err=0;

   /* determine number of files to work with */
   for (i=0;i<NumOfProds;++i)
      {
      if (Prods[i].att & SelectedProds)
	 fNum+=Prods[i].num;
      }
   for (i=0;i<NumOfComProds;++i)
      {
      if (ComProds[i].att & SelectedProds)
	 fNum+=ComProds[i].num;
      }

   /* allocate working buffers */
   if (!fDir)
      fDir = calloc (fNum+1,sizeof(FDIR));
   if (!fDir)
      {
      printf ("Unable to allocate directory work space, %l bytes requested\n",(long)(f*sizeof(FDIR)));
      exit (2);
      }
   if (!workBuf)
      workBuf = malloc (WORKBUFSIZE);
   if (!workBuf)
      {
      printf ("Unable to allocate work buffer, %u bytes requested\n",WORKBUFSIZE);
      exit (2);
      }

   printf ("Compressing %d files to %s*.*; please wait\n",fNum, TempDir);

#ifdef STATS
   statlog=fopen ("packstat.log","w");
   fprintf (statlog,"|             |  (4) |    ASCII (0)|    ASCII (1)|    Binary(2)|    Binary(3)|\n");
   fprintf (statlog,"|             | Real | 4096 Library| 2048 Library| 4096 Library| 2048 Library|\n");
   fprintf (statlog,"|             | Size | Size , Time | Size , Time | Size , Time | Size , Time |\n");
   fprintf (statlog,"|- File Name -| bytes| bytes, ms   | bytes, ms   | bytes, ms   | bytes, ms   |\n");
   fprintf (statlog,"|-------------|------|------,------|------,------|------,------|------,------|\n");
#endif

   /* compress all of the files */
   for (i=0;i<NumOfProds;++i)
      {
      if (Prods[i].att & SelectedProds)
	 {
	 for (x=0;x<Prods[i].num;++x)
	    {
	    if (r=compressFile (f,&Prods[i],x))
	       {
	       printf ("Error %d compressing file %s in product %s\n",
			r,fDir[f].fname,Prods[i].name);
	       ++err;
	       }
#ifdef STATS
   fprintf (statlog,"%s",cmpstat);
#endif
	    ++f;
	    }
	 }
      }

   /* compress all of the common files */
   for (i=0;i<NumOfComProds;++i)
      {
      if (ComProds[i].att & SelectedProds)
	 {
	 for (x=0;x<ComProds[i].num;++x)
	    {
	    if (r=compressFile (f,&ComProds[i],x))
	       {
	       printf ("Error %d compressing file %s in product %s\n",
			r,fDir[f].fname,ComProds[i].name);
	       ++err;
	       }
#ifdef STATS
   fprintf (statlog,"%s",cmpstat);
#endif
	    ++f;
	    }
	 }
      }
#ifdef STATS
   fclose (statlog);
#endif
   if (err)  /* see if compression phase worked */
      {
      printf ("\nerror %d detected; build aborted!\n",err);
      exit (3);
      }

   printf ("\nBuilding archive files; please wait\n");
   /* build archive files */
   buildArchive();

   /* free up the memory we used */
   free (fDir);
   fDir=NULL;
   free (workBuf);
   workBuf=NULL;
   }

/***********************************************************

Name:	 buildArchive

Format:  word buildArchive (void)

Desc:	 combines the file list fDir for fNum files into
	 archive files 1-n.

Input:	 none

Output:  none

Returns: 0 = no error, otherwise an error code

Comment:

***********************************************************/
word buildArchive (void)
   {
   QFHEAD qf;
   char str[128];
   int	fh[10];
   word i,x;

   /* sort the file list using size and product fields to sort on */
   qsort (fDir,fNum,sizeof(FDIR),fCompare);

   DirSpace=0;
   /* build extent directory (just for size information)*/
   DirSpace=buildDir ();

   /* determine extent for each file to go into */
   NumOfExt=setExtent ();

   /* build extent directory (it's for real this time)*/
   DirSpace=buildDir ();

   /* build the product file name */
   for (i=0;i<=NumOfProds;++i)
      if (Prods[i].att & SelectedProds)
	 break;
   sprintf (prodName,"%s%s",Prods[i].fnp,Disks[SelectedDisk].name);
   prodName[8]=0;

   /* open the archive files */
   for (i=1;i<=NumOfExt;++i)
      {
      sprintf (str,"%s.%d",prodName,i);
      remove (str);
      fh[i]=open (str,O_CREAT|O_WRONLY|O_BINARY,S_IREAD|S_IWRITE);
      if (fh[i]==-1)
	 {
	 printf ("Error opening archive %s, build aborted.\n",str);
	 exit (5);
	 }
      }

   /* write the archive file headers */
   if ((write (fh[1],workBuf,DirSpace))==-1)
      {
      printf ("Error writing archive directory header, build aborted.\n");
      exit (6);
      }
   qf.crc=0;
   qf.dir=0;
   qf.ver=(word)VERSION;
   qf.ext=(byte)NumOfExt;
   qf.fnum=0;
   for (i=2;i<=NumOfExt;++i)
      {
      qf.num=(byte)i;
      if ((write (fh[i],&qf,sizeof(QFHEAD)))==-1)
	 {
	 printf ("Error writing archive %d header, build aborted.\n",i);
	 exit (7);
	 }
      }

   /* write the archive files data */
   printf ("\nWriting %d archive files for %s\n",NumOfExt,prodName);
   for (i=0;i<fNum;++i)
      {
      if ((write (fh[fDir[i].loc],&fDir[i].crc,4))==-1)
	 {
	 printf ("\nError writing archive file, build aborted.\n");
	 exit (8);
	 }
      sprintf (str,"%s%s",TempDir,fDir[i].name);
      printf (" Archiving %s in extent %d ",fDir[i].name,fDir[i].loc);
      fh[0]=open (str,O_RDONLY|O_BINARY,S_IREAD|S_IWRITE);
      if (fh[0]==-1)
	 {
	 printf ("\nError opening file %s, build aborted.\n",fDir[i].name);
	 exit (9);
	 }
      do {
	 if ((x = read(fh[0],workBuf,WORKBUFSIZE))==-1)
	    {
	    printf ("\nError reading file %s, build aborted.\n",fDir[i].name);
	    exit (10);
	    }
	 if ((write (fh[fDir[i].loc],workBuf,x))==-1)
	    {
	    printf ("\nError writing archive %d header, build aborted.\n",i);
	    exit (11);
	    }
	 } while (x==WORKBUFSIZE);
      close (fh[0]);
      remove (str);
      printf ("\015                                            \015");
      }

   /* close the archive files */
   for (i=1;i<=NumOfExt;++i)
      close (fh[i]);
   return (SUCCESS);
   }

word buildDir (void)
   {
   word i,diroff;
   QFHEAD *fhead;
   QDIR   *dhead;
   for (i=2;i<=NumOfExt;++i)  /* init pointers/counters */
      extPtr[i]=(long)(sizeof(QFHEAD));
   extPtr[1]=(long)DirSpace;  /* add in the space needed for the
				 directory on the first disk	*/
   memset (workBuf,0,WORKBUFSIZE);/* clear scratch buffer */

   /* setup file header */
   fhead=(QFHEAD *)workBuf;   /* set up file header pointer */
   fhead->dir=sizeof(QFHEAD); /* offset of directory */
   fhead->ver=VERSION;	      /* bcd version number */
   fhead->num=1;	      /* we only do this on the first file */
   fhead->ext=(byte)NumOfExt;
   fhead->fnum=fNum;
   diroff=sizeof(QFHEAD);

   /* fill in directory information */
   for (i=0;i<fNum;++i)
      {
      dhead=(QDIR *)(&workBuf[diroff]);/* set up directory entry pointer */
      dhead->id    = fDir[i].id;
      dhead->num   = (byte)fDir[i].loc;
      dhead->start = extPtr[dhead->num];
      dhead->date  = fDir[i].date;
      dhead->time  = fDir[i].time;
      dhead->size  = fDir[i].size;
      dhead->csiz  = fDir[i].csiz+4;
      dhead->att   = fDir[i].att;
      dhead->comp  = (byte)fDir[i].comp;
      sprintf (dhead->path,"%s",fDir[i].fname);
      diroff+=sizeof(QDIR)+strlen(dhead->path)+1;
      dhead->next  = diroff;
      extPtr[dhead->num]+=dhead->csiz;
      }

   /* compute the directory crc */
   fhead->crc=~0;
   i=diroff-(word)fhead->dir;
   fhead->dlen=i;	      /* save the crc length in the header */
   fhead->crc=crc32(&workBuf[fhead->dir],&i,&fhead->crc);
   fhead->crc=~fhead->crc;
   return (diroff);	      /* return the size of the directory */
   }

word setExtent (void)
   {
   word fn;
   word frstskp=0;
   word fdone=0;
   word ext=1;
   long dksiz=((long)(Disks[SelectedDisk].size)*1000L)-
	      ((long)(InstallSpace)*1024L)-
	      (long)(DirSpace);
   /* determine extent for each file to go into */
   while (fdone<fNum)
      {
      for (fn=frstskp;fn<fNum;++fn)
	 {
	 if (!(fDir[fn].loc))
	    {
	    if ((long)(fDir[fn].csiz+4)<=dksiz)
	       {
	       dksiz-=(long)(fDir[fn].csiz+4); /* update what's left */
	       fDir[fn].loc=ext;  /* record extent to fit in */
	       ++fdone; 	  /* 1 less to do */
	       if (fn==frstskp)   /* if we used to first skiped */
		  frstskp=fNum;   /* then set to ending point point */
	       }
	    else
	       {
	       if (fn<frstskp)	  /* is this the point to skip from */
		  frstskp=fn;
	       }
	    }
	 }
      ++ext;
      dksiz=(long)(Disks[SelectedDisk].size)*1000L;
      }
   return (ext-1);
   }


int fCompare (const void *elem1,const void *elem2)
   {
   FDIR *dir1,*dir2;
   dir1=(FDIR *)elem1;
   dir2=(FDIR *)elem2;
   if (dir1->id == dir2->id)	 /* sort files in decending order */
      {
      if (dir1->csiz == dir2->csiz)
	 return (0);
      else if (dir1->csiz < dir2->csiz)
	 return (1);
      else
	 return (-1);
      }
   else if (dir1->id < dir2->id) /* sort products in assending order */
      return (-1);
   else
      return (1);
   }

/***********************************************************

Name:	 gettime

Format:  unsigned long gettime(void)

Desc:	 returns number of mili seconds since last call

Input:	 none

Output:  none

Returns: count

Comment:

***********************************************************/
unsigned long gettime(void)
   {
   static float otm=0,ttm=0;
   float f;
   word ts,tl,tm;

   _asm
      {
      cli		   ;

      push  es
      mov   ax,40h	   ; Bios segment address
      mov   es,ax	   ;
      mov   bx,6ch	   ; Offset of timer tic

retry:
      sti		   ; Allow timer interrupt to be serviced
      nop		   ;
      cli		   ; No more interrupts

      mov   al,0ah	   ; Data for interrupt controller OCW3
      out   20h,al	   ; Set controller to read IRR
      in    al,64h	   ; Purge pre-fetch queue

      mov   al,0	   ; Tell 8253 to latch channel 0
      out   43h,al	   ; Latch current contents
      in    al,64h	   ; Purge pre-fetch queue

      in    al,40h	   ; Read in low-order byte
      mov   cl,al	   ; Save
      in    al,64h	   ; Purge pre-fetch queue

      in    al,40h	   ; Read in high-order byte

      mov   ch,al	   ; Save
      neg   cx		   ; Adjust for down counter

      in    al,64h	   ; Purge pre-fetch queue
      in    al,20h	   ; Get IRR state
      cmp   al,1	   ; Is the timer interrupting ?
      je    retry	   ; Let the interrupt pass and re-read counter

      mov   ts,cx	   ; Save timer count in

      mov   ax,es:[bx]	   ; Get the time of day count lsw
      mov   tl,ax	   ;
      mov   ax,es:[bx+2]   ; Get the time of day count msw
      mov   tm,ax	   ;
      pop   es		   ;
      sti		   ;

      }
   ttm = otm;
   otm = (float)tm;
   otm*= 65536;
   otm+= (float)tl;
   otm*= 65536;
   otm+= (float)ts;

   if (!ttm)
      return (0L);

   f = (otm-ttm)*.000838;

   return ((unsigned long) (f));

   }

void reSetTimer (void)
   {
   _asm
      {
      push  es
      mov   ax,40h	; Bios segment address
      mov   es,ax	;
      mov   bx,6ch	; Offset of timer tic
      mov   ax,es:[bx]	; Get the time of day count
retest:
      sti		;
      nop		;
      cli		;
      cmp   ax,es:[bx]	;
      je    retest	;

      pop   es		;

      mov   al,36h	; Setup counter 0, mode 3
      out   43h,al	;
      in    al,64h	; Purge pre-fetch queue

      xor   al,al	; Zero gives full count of 65536
      out   40h,al	; Load low-order byte
      in    al,64h	; Purge pre-fetch queue

      xor   al,al	; Zero gives full count of 65536
      out   40h,al	; Load high-order byte
      sti
      }

   }


void setUpTimer (void)
   {
   _asm
      {
      push  es
      mov   ax,40h	; Bios segment address
      mov   es,ax	;
      mov   bx,6ch	; Offset of timer tic
      mov   ax,es:[bx]	; Get the time of day count
retest:
      sti		;
      nop		;
      cli		;
      cmp   ax,es:[bx]	;
      je    retest	;

      pop   es		;

      mov   al,34h	; Setup counter 0, mode 2
      out   43h,al	;
      in    al,64h	; Purge pre-fetch queue

      xor   al,al	; Zero gives full count of 65536
      out   40h,al	; Load low-order byte
      in    al,64h	; Purge pre-fetch queue

      xor   al,al	; Zero gives full count of 65536
      out   40h,al	; Load high-order byte
      sti

      }
   }


/***********************************************************

Name:	 compressFile

Format:  word compressFile (word dir,word pid,word fil)

Desc:	 compress a file and save it in the temp subdirectory

Input:	 dir - FDIR structure index to work on
	 pid - PRODUCTLIST structure product index
	 fil - PRODUCTLIST.file index to file name

Output:  updates FDIR[dir] structure

Returns: 0 = no error, otherwise an error code

Comment:

***********************************************************/
word compressFile (word dir,PRODUCTLIST *pid,word fil)
   {
   int fh=inFile;
   word cmp,i,cf,dlen,x;
   char pname[128],oname[32];
   unsigned long cnt[6],ct,tm[6];
   struct stat buf;

   fDir[dir].index=fil;       /* save the file index */
   fDir[dir].id=pid->att;     /* save the product attribute */
   /*
      fill in pname with path and name of source file
	      .fname with the extracted file name
   */
   splitName (pid->file[fil],
	      pname,
	      fDir[dir].fname);

   fDir[dir].csiz = 0;

   /* build compressed file name */
   sprintf (fDir[dir].name,"%s%d.tmp",pid->fnp,fil);
   sprintf (oname,"%s%s%d.tmp",TempDir,pid->fnp,fil);
   remove (oname);

   if (((inFile =open (pname,O_RDONLY|O_BINARY,S_IREAD|S_IWRITE))==-1) ||
       ((outFile=open (oname,O_CREAT|O_RDWR|O_BINARY,S_IREAD|S_IWRITE))==-1))
      {
      if (outFile != -1) close (outFile);
      if (inFile != -1) close (inFile);
      return (2);
      }

   /* fill in the file information */
   fDir[dir].size = filelength (inFile);
   _dos_getftime (inFile,&fDir[dir].date,&fDir[dir].time);
   _dos_getfileattr (pname,&fDir[dir].att);

   /* determine the best method of compression */
   printf (" Testing %s .. ",fDir[dir].fname);

#ifdef STATS
   sprintf (&cmpstat[0],"| %s        ",fDir[dir].fname);
   sprintf (&cmpstat[14],"|%6ld    ",fDir[dir].size);
#endif
   setUpTimer ();

   for (i=0;i<5;++i)		    /* initialize file length counters */
      cnt[i]=-1;

   /* set library length to max to start */
   dlen=4096;

   /* do ascii compresion 4096 library */
   cf=1;
   cmp=0;
   writeCount=0;
   lseek (inFile,0L,SEEK_SET);	    /* rewind input file */
   lseek (outFile,0L,SEEK_SET);     /* rewind output file */
   chsize (outFile,0L); 	    /* reset output file length */
   i=implode(ReadBuff,WriteBuff,workBuf,(int *)&cf,(int *)&dlen);
   if (i==0) cnt[cmp]=writeCount;

   fh=inFile;
   inFile=outFile;
   lseek (inFile,0L,SEEK_SET);	    /* rewind input file */
   gettime();
   i=explode(ReadBuff,CountBuff,workBuf); /* Extract the file	*/
   tm[cmp]=gettime();
   inFile=fh;

#ifdef STATS
   sprintf (&cmpstat[21],"|%6ld,%6ld  ",cnt[cmp],tm[cmp]);
#endif

   cmp++;

   /* do ascii compresion 2048 library */
   dlen>>=1;
   writeCount=0;
   lseek (inFile,0L,SEEK_SET);	    /* rewind input file */
   lseek (outFile,0L,SEEK_SET);     /* rewind output file */
   chsize (outFile,0L); 	    /* reset output file length */
   i=implode(ReadBuff,WriteBuff,workBuf,(int *)&cf,(int *)&dlen);
   if (i==0) cnt[cmp]=writeCount;

   fh=inFile;
   inFile=outFile;
   lseek (inFile,0L,SEEK_SET);	    /* rewind input file */
   gettime();
   i=explode(ReadBuff,CountBuff,workBuf); /* Extract the file	*/
   tm[cmp]=gettime();
   inFile=fh;

#ifdef STATS
   sprintf (&cmpstat[35],"|%6ld,%6ld  ",cnt[cmp],tm[cmp]);
#endif

   cmp++;

   /* set library length to max to start */
   dlen=4096;

   /* do binary compresion 4096 library */
   cf=0;
   writeCount=0;
   lseek (inFile,0L,SEEK_SET);	    /* rewind input file */
   lseek (outFile,0L,SEEK_SET);     /* rewind output file */
   chsize (outFile,0L); 	    /* reset output file length */
   i=implode(ReadBuff,CountBuff,workBuf,(int *)&cf,(int *)&dlen);
   if (i==0) cnt[cmp]=writeCount;

   fh=inFile;
   inFile=outFile;
   lseek (inFile,0L,SEEK_SET);	    /* rewind input file */
   tm[cmp+1]=gettime();
   i=explode(ReadBuff,CountBuff,workBuf); /* Extract the file	*/
   tm[cmp]=gettime();
   inFile=fh;

#ifdef STATS
   sprintf (&cmpstat[49],"|%6ld,%6ld  ",cnt[cmp],tm[cmp]);
#endif

   cmp++;

   /* do binary compresion 2048 library */
   dlen>>=1;
   writeCount=0;
   lseek (inFile,0L,SEEK_SET);	    /* rewind input file */
   lseek (outFile,0L,SEEK_SET);     /* rewind output file */
   chsize (outFile,0L); 	    /* reset output file length */
   i=implode(ReadBuff,CountBuff,workBuf,(int *)&cf,(int *)&dlen);
   if (i==0) cnt[cmp]=writeCount;

   fh=inFile;
   inFile=outFile;
   lseek (inFile,0L,SEEK_SET);	    /* rewind input file */
   tm[cmp+1]=gettime();
   i=explode(ReadBuff,CountBuff,workBuf); /* Extract the file	*/
   tm[cmp]=gettime();
   inFile=fh;

#ifdef STATS
   sprintf (&cmpstat[63],"|%6ld,%6ld|",cnt[cmp],tm[cmp]);
#endif

   reSetTimer ();

   cmp++;

   cnt[cmp++]=fDir[dir].size;	    /* don't forget the uncompressed size */

   lseek (inFile,0L,SEEK_SET);	    /* rewind input file */
   lseek (outFile,0L,SEEK_SET);     /* rewind output file */
   chsize (outFile,0L); 	    /* reset output file length */

   for (ct=-1,x=4,i=0;i<cmp;++i)
      {
      if ((ct > cnt[i]) ||
	  ((ct==cnt[i]) && (x<4) && (tm[x]>tm[i])))
	 {
	 ct=cnt[i];
	 x=i;
	 }
      }
#ifdef STATS
   sprintf (&cmpstat[78],"%d\n",x);
#endif

   writeCRC=~0; /* initialize CRC value for write routine */

   /* compress the file */
   if (x>=4)
      {
      printf ("copying to %s",fDir[dir].name);
      fDir[dir].comp=(byte)CMP_NONE;
      do {
	 i=WORKBUFSIZE;
	 i=ReadBuff (workBuf,&i);
	 WriteBuff (workBuf,&i);
	 } while (i==WORKBUFSIZE);
      i=0;
      }
   else
      {
      dlen=4096;
      switch (x)
	 {
      case 1:
	 dlen>>=1;
      case 0:
	 printf ("packing to %s",fDir[dir].name);
	 cf=CMP_ASCII;
	 break;
      case 3:
	 dlen>>=1;
      case 2:
	 printf ("imploding to %s",fDir[dir].name);
	 cf=CMP_BINARY;
	 break;
	 }
      fDir[dir].comp=(byte)cf;
      i=implode(ReadBuff,WriteBuff,workBuf,(int *)&cf,(int *)&dlen);
      }
   printf ("\015                                                              \015");
   close (outFile);
   close (inFile);
   if (stat(oname,&buf)==-1) /* get file stats */
      return (3);
   fDir[dir].csiz = (long)buf.st_size;
   fDir[dir].crc  = ~writeCRC;
   return (i);
   }

word splitName (char *str,char *pname,char *fname)
   {
   char buf[129],*st;
   strncpy (buf,str,128); /* make a working copy of file line */
   st=strtok(buf,";,\n"); /* terminate file name and path */
   strncpy (pname,st,128);/* copy it to callers storage */
   getName (st,fname);	  /* extract just the file name */
   return (0);
   }

void getName (char *pn, char *fn)
   {
   word i;
   for (i=strlen(pn);i>0;--i)
      {
      switch (pn[i])
	 {
      case 13:	 /* look for stuff to strip */
      case 10:
      case 32:
	 pn[i]=0;
	 break;
      case 92:	 /* look for directory deliminiters */
      case 47:
      case 58:
	 strncpy (fn,&pn[++i],14); /* copy name */
	 return;
      default:
	 break;
	 }
      }
   strncpy (fn,pn,14); /* no path extension so copy name */
   }

unsigned far pascal ReadBuff(char far *buff, unsigned short int far *size)
   {
   unsigned val;
   val = read(inFile,buff,*size);
   return(val);
   }


unsigned far pascal WriteBuff(char far *buff, unsigned short int far *size)
   {
   unsigned wrote;
   writeCount += *size;
   wrote = write (outFile,buff,*size);
   writeCRC=crc32(buff,size,&writeCRC);
   return(wrote);
   }


unsigned far pascal CountBuff(char far *buff, unsigned short int far *size)
   {
   writeCount += *size;
   return(*size);
   }


/***********************************************************

Name:	 commandHelp

Format:  void commandHelp (void)

Desc:	 display command line options

Input:	 none

Output:  none

Returns: none

Comment:

***********************************************************/
void commandHelp (void)
   {
   cls();
   bltscn (&cmdHelpMenu);
   getkey ();
   }

/***********************************************************

Name:	 readConfig ()

Format:  int readConfig (void)

Desc:	 Parse the configuration file and set global variables


Input:	 none


Output:  none

Returns: none


Comment:


***********************************************************/
int readConfig (void)
   {
   FILE  *fd;
   char  str[128];
   /* open config file */
   if (((fd=fopen (configpath,"r"))!=NULL) ||
       ((fd=fopen (altfigpath,"r"))!=NULL))
      {
      while (fgets (str,128,fd) != NULL)
	 {
	 if (str[0] != ';')
	    {
	    if (strncmp (str,"INSTALL LIST",12)==0)
	       setSpace(fd);
	    else if (strncmp (str,"DISK",4)==0)
	       setDisk(str);
	    else if (strncmp (str,"PRODUCT",7)==0)
	       setProduct(str,fd);
	    else if (strncmp (str,"COMMON",6)==0)
	       setComProd(str,fd);
	    else if (strncmp (str,"END",3)==0)
	       return(SUCCESS);
	    }
	 }
      return (2);
      }
   return (1);
   }

/***********************************************************

Name:	 setSpace()

Format:  void setSpace(char *str)

Desc:	 Parse out the field for the amount of space
	 required by the install program and data
	 files.

Input:	 none


Output:  none

Returns: none


Comment:


***********************************************************/
void setSpace(FILE *fd)
   {
   char str[128];
   int fh;
   long i;
   InstallSpace=0;
   while (fgets (str,128,fd) != NULL)
      {
      if (str[0] != ';')
	 {
	 if (strncmp (str,"ENDL",4)!=0)
	    {
	    strtok(str,"\n"); /* strip eol */
	    if (((fh=open (str,O_RDONLY,S_IREAD|S_IWRITE))==-1) ||
		((i=filelength(fh))==-1))
	       {
	       printf ("\nError opening file %s\n",str);
	       exit (-1);
	       }
	    else
	       InstallSpace+=((i+1023)/1024);
	    close (fh);
	    }
	 else
	    return;
	 }
      }
   }

/***********************************************************

Name:	 setDisk()

Format:  void setDisk(char *str)

Desc:	 Parse out the disk parameter entry and store the
	 values in the disk parameter structure.

Input:	 none


Output:  none

Returns: none


Comment:


***********************************************************/
void setDisk(char *str)
   {
   char *st;
   strtok(str,"=");
   st=strtok(NULL,",;\n");
   Disks[NumOfDisks].size=atoi(st);
   st=strtok(NULL,",;\n");
   strncpy(Disks[NumOfDisks].type,st,31);
   st=strtok(NULL,",;\n");
   strncpy(Disks[NumOfDisks].name,st,3);
   Disks[NumOfDisks++].name[4]=0;
   }

/***********************************************************

Name:	 setProduct()

Format:  void setProduct(char *str, FILE *fd)

Desc:	 Parse out the product name and continue reading
	 the file collecting the list of files contained in
	 the product.

Input:	 none

Output:  none

Returns: none


Comment:


***********************************************************/
void setProduct(char *str, FILE *fd)
   {
   char *st;
   strtok(str,"=");
   st=strtok(NULL,",;\n");
   strncpy(Prods[NumOfProds].name,st,31);
   st=strtok(NULL,",;\n");
   strncpy(Prods[NumOfProds].fnp,st,4);
   st=strtok(NULL,",;\n");
   Prods[NumOfProds].att=atoi(st);
   while (fgets (str,128,fd) != NULL)
      {
      if (str[0] != ';')
	 {
	 if (strncmp (str,"ENDP",4)!=0)
	    {
	    if (!(Prods[NumOfProds].file[Prods[NumOfProds].num]=
		calloc (strlen(str),1)))
	       {
	       printf ("Out of memory!\n");
	       exit(10);
	       }
	    strncpy(Prods[NumOfProds].file[Prods[NumOfProds].num++],
		    str,strlen(str));
	    }
	 else
	    {
	    NumOfProds++;
	    return;
	    }
	 }
      }
   }
/***********************************************************

Name:	 setComProd()

Format:  void setComProd(char *str, FILE *fd)

Desc:	 Read the list of files and the associated attributes

Input:	 none

Output:  none

Returns: none


Comment:


***********************************************************/
void setComProd(char *str, FILE *fd)
   {
   word i,id;
   char *st;
   strtok(str,"=");

   sprintf(ComProds[NumOfComProds].fnp,"CM%d",NumOfComProds);
   /* determine the common product attribute */
   id=0;
   while (st=strtok(NULL,",;\n"))
      {
      for (i=0;i<NumOfProds;++i)
	 {
	 if (strcmp (st,Prods[i].name)==0)
	    {
	    id|=Prods[i].att;
	    break;
	    }
	 }
      if (i==NumOfProds)
	 {
	 printf ("Unknown common product descriptor <%s>\n",st);
	 exit (12);
	 }
      }
   ComProds[NumOfComProds].att=id;
   while (fgets (str,128,fd) != NULL)
      {
      if (str[0] != ';')
	 {
	 if (strncmp (str,"ENDC",4)!=0)
	    {
	    if (!(ComProds[NumOfComProds].file[ComProds[NumOfComProds].num]=
		calloc (strlen(str),1)))
	       {
	       printf ("Out of memory!\n");
	       exit(13);
	       }
	    strncpy(ComProds[NumOfComProds].file[ComProds[NumOfComProds].num++],
		    str,strlen(str));
	    }
	 else
	    {
	    NumOfComProds++;
	    return;
	    }
	 }
      }
   }



/***********************************************************

Name:	 chkey

Format:  chkey()

Desc:	 Test the keyboard buffer return and key if available


Input:	 none


Output:  none

Returns: word upper 8 bits is the scan code and the lower
	 is the ascii key value of 0 if a function ke was typed

Comment:


***********************************************************/
word chkey (void)
   {
   word key=0;
   _asm
      {
      mov   ah,1  ;
      int   KBDIO ;
      jz    ck1   ;
      mov   ah,0  ;
      int   KBDIO ;
      mov   key,ax;
ck1:
      }
   return (key);
   }
/***********************************************************

Name:	 getkey

Format:  getkey()

Desc:	 returns key


Input:	 none


Output:  none

Returns: word upper 8 bits is the scan code and the lower
	 is the ascii key value of 0 if a function ke was typed

Comment:


***********************************************************/
word getkey (void)
   {
   word key=0;
   _asm
      {
      mov   ah,0  ;
      int   KBDIO ;
      mov   key,ax;
      }
   return (key);
   }


/***********************************************************

Name:	 qprint

Format:  qprint (int row,int col,int att,char *str);

Desc:	 direct console IO routine


Input:	 col - start col ( 0 relative )
	 row - start row
	 att - attribute to use
	 str - string to print ( nul terminated )

Output:  screen is update

Returns: none

Comment:


***********************************************************/
static void qprint (int row,int col,int att,char *str)
   {
   _settextcolor (att&0xf);
   _setbkcolor ((long)((att>>4)&0x7));
   _settextposition (row,col);
   _outtext (str);
   }

/***********************************************************

Name:	 cls

Format:  cls ()

Desc:	 Clear the display


Input:	 none


Output:  none

Returns: none

Comment:


***********************************************************/
void cls (void)
   {
   _asm
      {
      push  ds
      mov   bx,40h
      mov   ds,bx
      mov   bx,84h
      mov   dh,[bx]
      pop   ds
      mov   dl,4fh
      mov   ax,700h
      mov   bx,700h
      mov   cx,0
      int   10h
      }
   setcur (-1,0);
   }

/***********************************************************

Name:	 setcur

Format:  setcur ()

Desc:	 Set the cursor height and/or position


Input:	 size  - MSB = top line, LSB = bottom line of the cursor
	 pos   - MSB = row, LSB = col to position cursor to

Output:  none

Returns: none

Comment: if size or pos is -1 the size or position request (either)
	 will be ignored.


***********************************************************/
void setcur (word siz,word pos)
   {
   if (siz!=-1)
      {
      _asm
	 {
	 mov   ax,100h
	 mov   bh,0
	 mov   cx,siz
	 int   10h
	 }
      }
   if (pos!=-1)
      {
      _asm
	 {
	 mov   ax,200h
	 mov   bh,0
	 mov   dx,pos
	 int   10h
	 }
      }
   }


/***********************************************************

Name:	 getcur

Format:  getcur ()

Desc:	 Get the cursor height and position


Input:	 size  - pointer to receive current cursor size
	 pos   - pointer to receive current cursor pos

Output:  size  - MSB = top line, LSB = bottom line of the cursor
	 pos   - MSB = row, LSB = col to position cursor to

Returns: none

Comment:


***********************************************************/
void getcur (word *size,word *pos)
   {
   word sz,ps;
   _asm
      {
      mov   ax,300h
      int   10h
      mov   sz,cx
      mov   ps,dx
      }
   *size=sz;
   *pos=ps;
   }

/***********************************************************

Name:	 bltscn

Format:  void bltscn (MENU *scn)

Desc:	 print basc menu formatted data on screen

Input:	 pointer to menu structure

Output:  none

Returns: none

Comment:

***********************************************************/
void bltscn (MENU *scn)
   {
   int i;
   for (i=0;i<scn->items;++i)
      {
      qprint ( scn->msgs[i].row,
	       scn->msgs[i].col,
	       scn->msgs[i].att,
	       scn->msgs[i].msg);
      }
   }

