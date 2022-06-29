/*' $Header:   P:/PVCS/MAX/INSTALL/COMPILE.H_V   1.2   02 Jan 1996 17:45:30   BOB  $ */
/******************************************************************************
 *									      *
 * (C) Copyright 1991-95 Qualitas, Inc.  All rights reserved.		      *
 *									      *
 * COMPILE.H								      *
 *									      *
 * Compiler conditional defines 					      *
 *									      *
 ******************************************************************************/

#ifndef COMPILE_INCLUDED
#define COMPILE_INCLUDED

#define QCACHE_TEST	0	// Always turned off now

#ifdef MAXIB			// Support all beta versions
    #define MAXI
#else
    #ifdef MAXUB
	#define MAXU
    #else
	#ifdef BLUIB
	    #define BLUI
	#else
	    #ifdef BLUUB
		#define BLUU
	    #else
		#ifdef MOVIB
		    #define MOVI
		#else
		    #ifdef MOVUB
			#define MOVU
		    #endif // IF MOVUB
		#endif // IF/ELSE MOVIB
	    #endif // IF/ELSE BLUUB
	#endif // IF/ELSE BLUIB
    #endif // IF/ELSE MAXUB
#endif // IF/ELSE MAXIB

#ifdef MAXI
 #define     UPDATE  0	    // This is used as a conditional compiling option.
			    //	0 tells the compiler not to include update code.
			    //	1 .... include update code.

 #define     REDUIT  1	    // This is used as a conditional compile option.
			    //	 0 tells the compiler that this is the standard
			    //	 INSTALL.
			    //	 1 .... REDUIT INSTALL

 #define     MOVEM   0	    // 1 for Move'EM INSTALL
#else
  #ifdef BLUI
   #define	UPDATE	0
   #define	REDUIT	1
   #define	MOVEM	0
  #else
    #ifdef MAXU
     #define	UPDATE	1
     #define	REDUIT	1
     #define	MOVEM	0
    #else
      #ifdef BLUU
	#define UPDATE	1
	#define REDUIT	1
	#define MOVEM	0
      #else
	#ifdef MOVI
	  #define	UPDATE	0
	  #define	REDUIT	0
	  #define	MOVEM	1
	#else
	  #ifdef MOVU
	    #define	UPDATE	1
	    #define	REDUIT	0
	    #define	MOVEM	1
	  #else
	    #ifndef PROTO
	    #error No version specified - must be {[BLU]MAX|MOV}{I|U}[B]
	    #endif	// PROTO not defined.
	  #endif // MOVU
	#endif	// MOVI
      #endif	// BLUU
    #endif	// MAXU
  #endif	// BLUI
#endif		// MAXI

#endif

