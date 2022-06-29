/***
*_file.c - preprocess file and buffer data declarations
*
*Purpose:
*   file and buffer data declarations
*
*******************************************************************************/

#include <file2.h>

#define _NEAR_ near

/* Number of files */

#define _NFILE_ 30


/*
 * FILE2 descriptors; preset for stdin/out/err/aux/prn
 */

FILE2 _NEAR_ _iob2[ _NFILE_ ] = {
    /* flag2,	charbuf */
    {
    0, '\0', 0  }
    ,
    {
    0,	'\0', 0 }
    ,
    {
    0,	'\0', 0 }
    ,
    {
    0,	'\0', 0 }
    ,
    {
    0,	'\0', 0 }
    ,
};

