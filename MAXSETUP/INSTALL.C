#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
	printf("Running INSTALL instead!\n");
	while (*(++argv) != NULL)
		printf("  %s\n",*argv);
}

