/*===========================================================================
 Copyright (c) 1998-2000, The Santa Cruz Operation 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 *Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.

 *Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 *Neither name of The Santa Cruz Operation nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission. 

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS
 IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 DAMAGE. 
 =========================================================================*/

/* memory allocation functions */

#include <stdio.h>
#include <string.h>

static char const rcsid[] = "$Id: alloc.c,v 1.2 2000/04/21 00:11:02 petr Exp $";

extern	char	*argv0;	/* command name (must be set in main function) */

char	*mycalloc(int nelem, int size);
char	*mymalloc(int size);
void	*myrealloc(void *p, int size);
char	*stralloc(char *s);
static	void	*alloctest(void *p);
#ifdef __STDC__
#include <stdlib.h>
# else
char	*calloc(), *malloc(), *realloc(), *strcpy();
void	exit();
# endif

/* allocate a string */

char *
stralloc(char *s)
{
	return(strcpy(mymalloc((int) strlen(s) + 1), s));
}

/* version of malloc that only returns if successful */

char *
mymalloc(int size)
{
	return(alloctest(malloc((unsigned) size)));
}

/* version of calloc that only returns if successful */

char *
mycalloc(int nelem, int size)
{
	return(alloctest(calloc((unsigned) nelem, (unsigned) size)));
}

/* version of realloc that only returns if successful */

void *
myrealloc(void *p, int size)
{
	return(alloctest(realloc((void *) p, (unsigned) size)));
}

/* check for memory allocation failure */

static	void *
alloctest(void *p)
{
	if (p == NULL) {
		(void) fprintf(stderr, "\n%s: out of storage\n", argv0);
		exit(1);
	}
	return(p);
}
