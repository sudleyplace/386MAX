/*
 * MUSCROLL.H
 *
 * API Definitions for the custom control.  This file should be included
 * with all applications that use this control.
 *
 * Revision History:
 *  18 Sept., 1990  :   Kraig Brockschmidt, header comment.
 *  01 Oct., 1990   :   KB, began adding GWW defs and messages.
 *  10 Oct., 1990   :   KB, total revision after real design work was done.
 *
 * Copyright (c) 1990, 1991 Microsoft Corporation. All rights reserved.
 */


/*
 * Messages sent to the custom control.
 */

#define MSM_SETRANGE        (WM_USER+3)
#define MSM_GETRANGE        (WM_USER+4)
#define MSM_SETCURPOS       (WM_USER+5)
#define MSM_GETCURPOS       (WM_USER+6)
#define MSM_SETASSOCIATE    (WM_USER+1)
#define MSM_GETASSOCIATE    (WM_USER+2)


/*
 * Notification codes sent via WM_COMMAND from the control.
 */

#define MSN_SETASSOCIATE    1
#define MSN_KILLASSOCIATE   2
#define MSN_RANGECHANGE     3


/*
 * GetWindowWord/GetWindowLong values to access window extra bytes.
 */


/*
 * Control styles.
 */

#define MSS_VERTICAL        0x0001L
#define MSS_HORIZONTAL      0x0002L
#define MSS_NOPEGSCROLL     0x0004L
#define MSS_TEXTHASRANGE    0x0008L

