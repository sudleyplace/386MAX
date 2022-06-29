#include "mstdhdr.h" 

#define LedPCBAddr	0x378		// Base addr for lpt1

int val1 = 0;


//...LPT1 communication prototype
void WriteLPT1(int value);


//...LPT1 communication functions
void WriteLPT1(int value)
{
    outp( LedPCBAddr, value );
}        

void InitializePorts( void )
{
   sleep(1);
   outp( LedPCBAddr, 0x0);  // Clear the LPT1 port
}

main()
{
    InitializePorts();
    while ( val1 < 255 )
    {
	if ( val1 < 255 )
	{
	    val1++;
	}    
	else val1 = 0;

      WriteLPT1(val1);
      printf(" val1 = %i",val1);
      sleep(1);
    }
    InitializePorts();

}    
