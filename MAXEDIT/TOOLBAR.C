//  File name: tbproc.c
//     Contains the code that maintains the toolbar for MAXEDIT

#include "maxedit.h"

TOOL   Tools[NUMTOOLS];          // Array to hold the different buttons
BOOL   ButtonState;              // Is the button to be drawn depressed 
HBRUSH hButtonBrush=NULL;        // Handle to a Brush created for painting button
HPEN   hGrayPen=NULL;            // Pen created for 

WORD   wIconHeight, wIconWidth;
int nOneUnit = 0;


//  BuildTools()
//
//  Purpose:
//      Makes the toolbar

#define MAKEBUTTONsc(Num,ResName,IDM_VALUE)                  \
  {                                                          \
  Tools[Num].hIcon     = LoadIcon ( hInst, (LPSTR)ResName );\
  Tools[Num].CommandID = IDM_VALUE;                          \
  }


void BuildTools ( void )
{
    extern HANDLE hInst;
    extern HWND hwndFrame, hwndToolbar;
    register int i;

    nOneUnit = (GetSystemMetrics(SM_CXBORDER));
    hButtonBrush = CreateSolidBrush ( RGB ( 192,192,192 ));
    hGrayPen = CreatePen ( PS_SOLID, 1, RGB(192,192,192));
    hwndToolbar = CreateWindow ("classControlBar", "ControlBar",
                       WS_CHILD, 0,0,0,0, hwndFrame, NULL, hInst, NULL) ;

    MAKEBUTTONsc ( 0, "TBNEW",   IDM_FILENEW  )
    MAKEBUTTONsc ( 1, "TBOPEN",   IDM_FILEOPEN  )
    MAKEBUTTONsc ( 2, "TBSAVE",   IDM_FILESAVE  )
    MAKEBUTTONsc ( 3, "TBPRINT",   IDM_FILEPRINT  )

    MAKEBUTTONsc ( 4, "TBUNDO",   IDM_EDITUNDO  )
    MAKEBUTTONsc ( 5, "TBCUT",   IDM_EDITCUT  )
    MAKEBUTTONsc ( 6, "TBCOPY",   IDM_EDITCOPY )
    MAKEBUTTONsc ( 7, "TBPASTE",   IDM_EDITPASTE  )

    MAKEBUTTONsc ( 8, "TBCASC",  IDM_WINDOWCASCADE )
    MAKEBUTTONsc ( 9, "TBTILE",  IDM_WINDOWTILE )
    MAKEBUTTONsc ( 10, "TBINI",  IDM_EDITINI )

    MAKEBUTTONsc ( 11, "TBEXIT",  IDM_FILEEXIT )
    MAKEBUTTONsc ( 12, "TBHELP",  IDM_HELPHELP )

    // Save dimensions for each button in toolbar
    for ( i = 0; i < NUMTOOLS; i++ ) {

        Tools[i].x  = (i * BUTTON_WIDTH) + SPACE_BETWEEN_BUTTONS + BUTTONBAR_OFFSET;

	if (i >= 4)
		Tools[i].x += 10;

	if (i >= 8)
		Tools[i].x += 10;

	if (i >= 11)
		Tools[i].x += 10;

        Tools[i].dx = BUTTON_WIDTH - (SPACE_BETWEEN_BUTTONS + (BUTTON_BORDER*2));
        Tools[i].y  = BUTTON_BORDER + TOOLBAR_BORDER;
        Tools[i].dy = BUTTON_HEIGHT; 
    }
}

void DestroyTools ( void )
{
    if ( hButtonBrush != NULL ) {
        DeleteObject( hButtonBrush );    
    }

    if ( hGrayPen != NULL ) {
        DeleteObject( hGrayPen );    
    }

}

//  DrawTools()
//
//  Purpose:
//      Draws the inidividual buttons
//
//  Parameters:
//      HDC - Toolbar DC
//      int - index in to the toolbar struct

void DrawTool ( HDC hDC, int Number )
{
    HPEN   hOldPen;
    RECT   r;

    int    dx, dy;

    dx = dy = 0;

    if (ButtonState) {
dx=dy=1;
//        dx = dy = 2;
    }

    // Setup rectangle
    r.left   = Tools[Number].x;
    r.right  = Tools[Number].x + Tools[Number].dx;
    r.top    = Tools[Number].y;
    r.bottom = Tools[Number].y + Tools[Number].dy;

    hOldPen   = SelectObject( hDC, GetStockObject( WHITE_PEN ));
    FillRect( hDC, &r, hButtonBrush );

    // Draw the top and left borders
    MoveTo( hDC, r.left-1,  r.bottom+1 );
    LineTo( hDC, r.left-1,  r.top-1    );
    LineTo( hDC, r.right+1, r.top-1    );

    // Check if the button is to be drawn depressed
    if (!dx)
        SelectObject( hDC, GetStockObject( BLACK_PEN ));
    else
        SelectObject( hDC, GetStockObject( WHITE_PEN ));

    // Draw right and bottom borders
    LineTo( hDC, r.right+1, r.bottom+1);
    LineTo( hDC, r.left-1,  r.bottom+1);

    // Repeat drawing borders for the second outline
    if (!dx)
        SelectObject( hDC, GetStockObject( WHITE_PEN ));
    else
        SelectObject( hDC, GetStockObject( BLACK_PEN ));

    MoveTo( hDC, r.left-2,  r.bottom+2 );
    LineTo( hDC, r.left-2,  r.top-2 );
    LineTo( hDC, r.right+2, r.top-2 );

    if (!dx)
        SelectObject( hDC, GetStockObject( BLACK_PEN ));
    else
        SelectObject( hDC, GetStockObject( WHITE_PEN ));

    LineTo( hDC, r.right+2, r.bottom+2);
    LineTo( hDC, r.left-2,  r.bottom+2);

    // Draw the actual bitmap/icon on to the button area
    DrawIcon( hDC, r.left+dx+2, r.top+dy+2, Tools[Number].hIcon );
    SelectObject( hDC, hOldPen );
}


//  ControlBarWndProc()
//     toolbar message handler

LONG FAR PASCAL __export ControlBarWndProc ( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
	register int i;
	WORD        x, y;
	HDC         hDC;
	PAINTSTRUCT ps;
	BOOL        bFound;
	HPEN        hOldPen;
	RECT        r;

	static      int   LastButtonPressed;
	static      WORD  mx1, mx2, my1, my2;
	static      BOOL  ClickState;

	switch ( msg ) {
        case WM_CTLCOLOR:
            // Draw everything in the chosen color
            return hButtonBrush;

        case WM_CREATE:
            LastButtonPressed = -1;
            ButtonState = FALSE;
            break;

        case WM_PAINT:

            GetClientRect( hWnd, &r );
            hDC = BeginPaint( hWnd, &ps );

            SetBkColor( hDC, RGB(192,192,192));
            ButtonState = FALSE;

            for ( i = 0; i < NUMTOOLS; i++ )
                DrawTool( hDC, i );

            // Draw the 3-D jazz for the toolbar
            hOldPen  = SelectObject( hDC, GetStockObject( BLACK_PEN ));
            MoveTo( hDC, 0, r.bottom-1 );
            LineTo( hDC, r.right, r.bottom-1 );

            MoveTo( hDC, 0, r.bottom-2 );
            SelectObject( hDC, GetStockObject( WHITE_PEN ));
            LineTo( hDC, 0, 0 );
            LineTo( hDC, r.right, 0 );

            SelectObject( hDC, hGrayPen );

            LineTo( hDC, r.right, r.bottom-2 );
            LineTo( hDC, 0, r.bottom-2 );

            SelectObject( hDC, hOldPen);

            EndPaint( hWnd, &ps );
            break;

        case WM_MOUSEMOVE:
            x = LOWORD( lParam );
            y = HIWORD( lParam );

            if (!ClickState) 
                break;
            i = LastButtonPressed;
   
            // Did we move off a depressed button ?
            if (( x >= mx1 ) && ( x <= mx2 ) && ( y >= my1 ) && ( y <= my2 )) {
                if (ButtonState) 
                    break;
                ButtonState = TRUE;
                hDC = GetDC( hWnd );
                DrawTool( hDC, i );
                ReleaseDC( hWnd, hDC );
            } else {
                if (!ButtonState) 
                    break;
                hDC = GetDC( hWnd );
                ButtonState = FALSE;
                DrawTool( hDC, i);
                ReleaseDC( hWnd, hDC );
            }
            break;

        case WM_LBUTTONDOWN:

            x = LOWORD( lParam );
            y = HIWORD( lParam );

            bFound = FALSE;
            i = 0;
            
            // Did the user click on a button?
            while ((!bFound) && (i < NUMTOOLS)) {
                if ( (x >= Tools[i].x) && ( x <= (Tools[i].x+Tools[i].dx)) &&
                     (y >= Tools[i].y) && ( y <= (Tools[i].y+Tools[i].dy)))
                    bFound = TRUE;

                if (!bFound) 
                    i++;
            }

            if (NUMTOOLS == i)
		break;

            LastButtonPressed = i;

            mx1 = Tools[i].x;
            mx2 = Tools[i].x+Tools[i].dx;
            my1 = Tools[i].y;
            my2 = Tools[i].y+Tools[i].dy;

            hDC = GetDC( hWnd );
            ButtonState = TRUE;
            DrawTool( hDC, i );
            ReleaseDC( hWnd, hDC );
            ClickState  = TRUE;
            
            // Capture mouse so that mouse can be tracked wherever the user moves the 
            // depressed mouse. 
            SetCapture( hWnd );
            break;

        case WM_LBUTTONUP:

            x = LOWORD( lParam );
            y = HIWORD( lParam );

            ClickState = FALSE;
            ReleaseCapture();
            
            // If mouse button was released outside toolbar button, the toolbar button 
            // has not been selected
            if (!( ( x >= mx1 ) && ( x <= mx2 ) && ( y >= my1 ) && ( y <= my2 ))) {
                LastButtonPressed = -1;
                break;
            }

            if (!ButtonState) {
                LastButtonPressed = -1;
                break;
            }

            hDC = GetDC( hWnd );
            i = LastButtonPressed;
            ButtonState = FALSE;
            DrawTool( hDC, i );
            ReleaseDC( hWnd, hDC );
            LastButtonPressed = -1;
            
            // Perform toolbar button function
            PostMessage( hwndFrame, WM_COMMAND, Tools[i].CommandID, 0L );
            break;
      
        default :
            return DefWindowProc(hWnd, msg, wParam, lParam) ;
	}

	return 0L ;
}

