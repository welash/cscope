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


/*	cscope - interactive C symbol cross-reference
 *
 *	directory searching functions
 */

#include <stdlib.h>
#include <sys/types.h>	/* needed by stat.h and dirent.h */
#include <dirent.h>
#include <stdlib.h>
#include <sys/stat.h>	/* stat */
#include "global.h"
#include "vp.h"		/* vpdirs and vpndirs */

static char const rcsid[] = "$Id: dir.c,v 1.17 2002/03/16 15:20:27 broeker Exp $";

#define	DIRSEPS	" ,:"	/* directory list separators */
#define	DIRINC	10	/* directory list size increment */
#define HASHMOD	2003	/* must be a prime number */
#define	SRCINC	HASHMOD	/* source file list size increment */
			/* largest known database had 22049 files */

char	currentdir[PATHLEN + 1];/* current directory */
char	**incdirs;		/* #include directories */
char	**srcdirs;		/* source directories */
char	**srcfiles;		/* source files */
int	nincdirs;		/* number of #include directories */
int	nsrcdirs;		/* number of source directories */
int	nsrcfiles;		/* number of source files */
int	msrcfiles = SRCINC;	/* maximum number of source files */

static	char	**incnames;	/* #include directory names without view pathing */
static	int	mincdirs = DIRINC; /* maximum number of #include directories */
static	int	msrcdirs;	/* maximum number of source directories */
static	int	nvpsrcdirs;	/* number of view path source directories */

static	struct	listitem {	/* source file names without view pathing */
	char	*text;
	struct	listitem *next;
} *srcnames[HASHMOD];

/* Internal prototypes: */
static	BOOL	issrcfile(char *file);
static	void	addsrcdir(char *dir);
static	void	addincdir(char *name, char *path);
static	void	scan_dir(const char *dirfile, BOOL recurse);
static	void	makevpsrcdirs(void);


/* make the view source directory list */

static void
makevpsrcdirs(void)
{
	int	i;

	/* return if this function has already been called */
	if (nsrcdirs > 0) {
		return;
	}
	/* get the current directory name */
	if (getcwd(currentdir, PATHLEN) == NULL) {
		(void) fprintf(stderr, "cscope: warning: cannot get current directory name\n");
		(void) strcpy(currentdir, "<unknown>");
	}
	/* see if there is a view path and this directory is in it */
	vpinit(currentdir);
	if (vpndirs > 1) {
		nsrcdirs = vpndirs;
	}
	else {
		nsrcdirs = 1;
	}
	/* create the source directory list */
	msrcdirs = nsrcdirs + DIRINC;
	srcdirs = mymalloc(msrcdirs * sizeof(char *));
	*srcdirs = ".";	/* first source dir is always current dir */
	for (i = 1; i < vpndirs; ++i) {
		srcdirs[i] = vpdirs[i];
	}
	/* save the number of original source directories in the view path */
	nvpsrcdirs = nsrcdirs;
}

/* add a source directory to the list for each view path source directory */

void
sourcedir(char *dirlist)
{
	char	path[PATHLEN + 1];
	char	*dir;
	int	i;

	makevpsrcdirs();		/* make the view source directory list */
	dirlist = stralloc(dirlist);	/* don't change environment variable text */
	
	/* parse the directory list */
	dir = strtok(dirlist, DIRSEPS);
	while (dir != NULL) {
		int dir_len = strlen(dir);

		addsrcdir(dir);

		/* if it isn't a full path name and there is a 
		   multi-directory view path */
		if (*dirlist != '/' && vpndirs > 1) {
			
			/* compute its path from higher view path source dirs */
			for (i = 1; i < nvpsrcdirs; ++i) {
				(void) sprintf(path, "%.*s/%s",
					       PATHLEN - 2 - dir_len,
					       srcdirs[i], dir);
				addsrcdir(path);
			}
		}
		dir = strtok(NULL, DIRSEPS);
	}
	free(dirlist);		/* HBB 20000421: avoid memory leaks */
}

/* add a source directory to the list */

static void
addsrcdir(char *dir)
{
	struct	stat	statstruct;

	/* make sure it is a directory */
	if (lstat(compath(dir), &statstruct) == 0 && 
	    S_ISDIR(statstruct.st_mode)) {

		/* note: there already is a source directory list */
		if (nsrcdirs == msrcdirs) {
			msrcdirs += DIRINC;
			srcdirs = myrealloc(srcdirs, msrcdirs * sizeof(char *));
		}
		srcdirs[nsrcdirs++] = stralloc(dir);
	}
}

/* HBB 20000421: new function, for avoiding leaks */
/* free list of src directories */
void
freesrclist()
{
	if (!srcdirs)
		return;
	while(nsrcdirs>1)
		free(srcdirs[--nsrcdirs]);
	free(srcdirs);
}

/* add a #include directory to the list for each view path source directory */

void
includedir(char *dirlist)
{
	char	path[PATHLEN + 1];
	char	*dir;
	int	i;

	makevpsrcdirs();		/* make the view source directory list */
	dirlist = stralloc(dirlist);	/* don't change environment variable text */
	
	/* parse the directory list */
	dir = strtok(dirlist, DIRSEPS);
	while (dir != NULL) {
		int dir_len = strlen(dir);

		addincdir(dir, dir);

		/* if it isn't a full path name and there is a 
		   multi-directory view path */
		if (*dirlist != '/' && vpndirs > 1) {
			
			/* compute its path from higher view path source dirs */
			for (i = 1; i < nvpsrcdirs; ++i) {
				(void) sprintf(path, "%.*s/%s", 
					       PATHLEN - 2 - dir_len,
					       srcdirs[i], dir);
				addincdir(dir, path);
			}
		}
		dir = strtok(NULL, DIRSEPS);
	}
	free(dirlist);			/* HBB 20000421: avoid leaks */
}

/* add a #include directory to the list */

static void
addincdir(char *name, char *path)
{
	struct	stat	statstruct;

	/* make sure it is a directory */
	if (lstat(compath(path), &statstruct) == 0 && 
	    S_ISDIR(statstruct.st_mode)) {
		if (incdirs == NULL) {
			incdirs = mymalloc(mincdirs * sizeof(char *));
			incnames = mymalloc(mincdirs * sizeof(char *));
		}
		else if (nincdirs == mincdirs) {
			mincdirs += DIRINC;
			incdirs = myrealloc(incdirs, 
				mincdirs * sizeof(char *));
			incnames = myrealloc(incnames, 
				mincdirs * sizeof(char *));
		}
		incdirs[nincdirs] = stralloc(path);
		incnames[nincdirs++] = stralloc(name);
	}
}

/* HBB 2000421: new function, for avoiding memory leaks */
/* free the list of include files, if wanted */

void
freeinclist()
{
	if (!incdirs)	
		return;
	while(nincdirs>0) {
		free(incdirs[--nincdirs]);
		free(incnames[nincdirs]);
	}
	free(incdirs);
	free(incnames);
}

/* make the source file list */

void
makefilelist(void)
{
	static	BOOL	firstbuild = YES;	/* first time through */
	FILE	*names;			/* name file pointer */
	char	dir[PATHLEN + 1];
	char	path[PATHLEN + 1];
	char    line[PATHLEN * 10];
	char	*file;
	char	*s;
	int	i;

	makevpsrcdirs();	/* make the view source directory list */

	/* if -i was NOT given and there are source file arguments */
	if (namefile == NULL && fileargc > 0) {
		
		/* put them in a list that can be expanded */
		for (i = 0; i < fileargc; ++i) {
			file = fileargv[i];
			if (infilelist(file) == NO) {
				if ((s = inviewpath(file)) != NULL) {
					addsrcfile(s);
				}
				else {
					(void) fprintf(stderr, "cscope: cannot find file %s\n",
					    file);
					errorsfound = YES;
				}
			}
		}
		return;
	}
	/* see if a file name file exists */
	if (namefile == NULL && vpaccess(NAMEFILE, READ) == 0) {
		namefile = NAMEFILE;
	}
	/* if there is a file of source file names */
	if (namefile != NULL) {
		if (strcmp(namefile, "-") == 0)
		    names = stdin;
		else if ((names = vpfopen(namefile, "r")) == NULL) {
			cannotopen(namefile);
			myexit(1);
		}
		/* get the names in the file */
		while (fgets(line, 10*PATHLEN, names) != NULL) {
			char *point_in_line = line + (strlen(line) - 1);
			size_t length_of_name = 0;
			int unfinished_option = 0;
			BOOL done = NO;

			/* Kill away \n left at end of fgets()'d string: */
			if (*point_in_line == '\n')
				*point_in_line = '\0';
			
			/* Parse whitespace-terminated strings in line: */
			point_in_line = line;
			while (sscanf(point_in_line, "%s", path) == 1) {
				/* Have to store this length --- inviewpath() will
				 * modify path, later! */
				length_of_name = strlen(path);
			  
				if (*path == '-') {	/* if an option */
					if (unfinished_option) {
						/* Can't have another option directly after an
						 * -I or -p option with no name after it! */
						(void) fprintf(stderr, "\
cscope: Syntax error in namelist file %s: unfinished -I or -p option\n", 
									   namefile);
						unfinished_option = 0;
					}
						
					i = path[1];
					switch (i) {
					case 'c':	/* ASCII characters only in crossref */
						compress = NO;
						break;
					case 'k':	/* ignore DFLT_INCDIR */
						kernelmode = YES;
						break;
					case 'q':	/* quick search */
						invertedindex = YES;
						break;
					case 'T':	/* truncate symbols to 8 characters */
						trun_syms = YES;
						break;
					case 'I':	/* #include file directory */
					case 'p':	/* file path components to display */
						s = path + 2;		/* for "-Ipath" */
						if (*s == '\0') {	/* if "-I path" */
							unfinished_option = i;
							break; 
						} 

						/* this code block used several times in here
						 * --> make it a macro to avoid unnecessary
						 * duplication */
#define HANDLE_OPTION_ARGUMENT(i, s)																			   \
						switch (i) {																			   \
						case 'I':	/* #include file directory */												   \
							if (firstbuild == YES) {															   \
								/* expand $ and ~ */															   \
								shellpath(dir, sizeof(dir), (s));												   \
								includedir(dir);																   \
							}																					   \
							unfinished_option = 0;																   \
							done = YES;																			   \
							break;																				   \
						case 'p':	/* file path components to display */										   \
							if (*(s) < '0' || *(s) > '9') {														   \
								(void) fprintf(stderr,															   \
											   "cscope: -p option in file %s: missing or invalid numeric value\n", \
											   namefile);														   \
							}																					   \
							dispcomponents = atoi(s);															   \
							unfinished_option = 0;																   \
							done = YES;																			   \
							break;																				   \
						default:																				   \
							done = NO;																			   \
						}

						/* ... and now call it for the first time */
						HANDLE_OPTION_ARGUMENT(i, s)
						break;
					default:
						(void) fprintf(stderr, "cscope: only -I, -c, -k, -p, and -T options can be in file %s\n", 
									   namefile);
					}
				} else if (*path == '"') {
					/* handle quoted filenames... */
					size_t in = 1, out = 0;
					char *newpath = mymalloc(PATHLEN + 1);

					while (in < PATHLEN && point_in_line[in] != '\0') {
						if (point_in_line[in] == '"') {
							newpath[out] = '\0';
							/* Make sure we skip over the part just read */
							point_in_line += in + 1;
							/* ... to deactive step by strlen() path at end
							 * of loop */
							path[0]='\0';
							break;	/* found end of quoted string */
						}
						else if (point_in_line[in] == '\\' && in < PATHLEN - 1
								 && (point_in_line[in + 1]== '"' || point_in_line[in + 1] == '\\')) {
							/* un-escape \" or \\ sequence */
							newpath[out++] = point_in_line[in + 1];
							in += 2;
						}
						else {
							newpath[out++] = point_in_line[in++];
						}
					} /* while */ 
					if (in >= PATHLEN) { /* safeguard against almost-overflow */
						newpath[out]='\0';
					}

					/* If an -I or -p arguments was missing before,
					 * treat this name as the argument: */
					HANDLE_OPTION_ARGUMENT(unfinished_option, newpath);
					if (! done) {
						if ((s = inviewpath(newpath)) != NULL) {
							addsrcfile(s);
						} else {
							(void) fprintf(stderr,
										   "cscope: cannot find file %s\n",
										   newpath);
							errorsfound = YES;
						}
					}
				} else {
					/* ... so this is an ordinary file name, unquoted */

					/* If an -I or -p arguments was missing before,
					 * treat this name as the argument: */
					HANDLE_OPTION_ARGUMENT(unfinished_option, path);
					if (!done) {
						if ((s = inviewpath(path)) != NULL) {
							addsrcfile(s);
						} else {
							(void) fprintf(stderr, "cscope: cannot find file %s\n",
										   path);
							errorsfound = YES;
						}
					}
				}
				point_in_line += length_of_name;
				while (isspace((unsigned char) *point_in_line))
					point_in_line ++;
			}
		}
		if (names == stdin)
		    clearerr(stdin);
		else
		    (void) fclose(names);
		firstbuild = NO;
		return;
	}
	/* make a list of all the source files in the directories */
	for (i = 0; i < nsrcdirs; ++i) {
		scan_dir(srcdirs[i], recurse_dir);
	}
}

/* scan a directory (recursively?) for source files */
static void
scan_dir(const char *adir, BOOL recurse_dir)
{
	DIR	*dirfile;
	int adir_len = strlen(adir);

	/* FIXME: no guards against adir_len > PATHLEN, yet */

	if ((dirfile = opendir(adir)) != NULL) {
		struct dirent *entry;
		char	path[PATHLEN + 1];
		char	*file;

		while ((entry = readdir(dirfile)) != NULL) { 
			if ((strcmp(".",entry->d_name) != 0)
			    && (strcmp("..",entry->d_name) != 0)) {
				struct stat buf;

				sprintf(path,"%s/%.*s", adir,
					PATHLEN - 2 - adir_len,
					entry->d_name);

				if (lstat(path,&buf) == 0) {
					file = entry->d_name;
					if (recurse_dir 
                                            && S_ISDIR(buf.st_mode) ) {
						scan_dir(path, recurse_dir);
					}
					else if (
#ifdef __DJGPP__ /* FIXME: should test for feature, not platform */
						 1 /* DJGPP doesn't have this field in dirent */
#else
						 entry->d_ino != 0
#endif
						 && issrcfile(path)
						 && infilelist(path) == NO) {
					  addsrcfile(path);
					}
				}
			}
		}
		closedir(dirfile);
	}
        return;
}

/* see if this is a source file */

static BOOL
issrcfile(char *file)
{
	struct	stat	statstruct;
	char	*s;

	/* if there is a file suffix */
	if ((s = strrchr(file, '.')) != NULL && *++s != '\0') {
		
		/* if an SCCS or versioned file */
		if (file[1] == '.' && file + 2 != s) { /* 1 character prefix */
			switch (*file) {
			case 's':
			case 'S':
				return(NO);
			}
		}
		if (s[1] == '\0') {	/* 1 character suffix */
			switch (*s) {
			case 'c':
			case 'h':
			case 'l':
			case 'y':
			case 'C':
			case 'G':
			case 'H':
			case 'L':
				return(YES);
			}
		}
		else if (s[2] == '\0') {	/* 2 character suffix */
			if ((*s == 'b' && s[1] == 'p') ||	/* breakpoint listing */
			    (*s == 'q' &&
				(s[1] == 'c' || s[1] == 'h')) || /* Ingres */
			    (*s == 's' && s[1] == 'd') || /* SDL */
			    (*s == 'c' && s[1] == 'c') || /* C++ source */
			    (*s == 'h' && s[1] == 'h')) { /* C++ header */
			
				/* some directories have 2 character
				   suffixes so make sure it is a file */
				if (lstat(file, &statstruct) == 0 && 
				    S_ISREG(statstruct.st_mode)) {
					return(YES);
				}
			}
		}
		else if( s[3] == '\0' ) { /* 3 char suffix */
			if( 
			   (*s == 't' && s[1] == 'c' && s[2] == 'c' ) ||
						/* C++ template source */
			   0) {
				/* make sure it is a file */
				if (lstat(file, &statstruct) == 0 && 
					S_ISREG(statstruct.st_mode)) {
					return(YES);
				}
			}
		}
	}
	return(NO);
}

/* add an include file to the source file list */

void
incfile(char *file, char *type)
{
	char	name[PATHLEN + 1];
	char	path[PATHLEN + 1];
	char	*s;
	int	i;
	
	/* see if the file is already in the source file list */
	if (infilelist(file) == YES) {
		return;
	}
	/* look in current directory if it was #include "file" */
	if (type[0] == '"' && (s = inviewpath(file)) != NULL) {
		addsrcfile(s);
	}
	else {
		int file_len = strlen(file);

		/* search for the file in the #include directory list */
		for (i = 0; i < nincdirs; ++i) {
			
			/* don't include the file from two directories */
			(void) sprintf(name, "%.*s/%s",
				       PATHLEN - 2 - file_len, incnames[i],
				       file);
			if (infilelist(name) == YES) {
				break;
			}
			/* make sure it exists and is readable */
			(void) sprintf(path, "%.*s/%s",
				       PATHLEN - 2 - file_len, incdirs[i],
				       file);
			if (access(compath(path), READ) == 0) {
				addsrcfile(path);
				break;
			}
		}
	}
}

/* see if the file is already in the list */

BOOL
infilelist(char *path)
{
	struct	listitem *p;

	for (p = srcnames[hash(compath(path)) % HASHMOD]; p != NULL; p = p->next) {
		if (strequal(path, p->text)) {
			return(YES);
		}
	}
	return(NO);
}

/* search for the file in the view path */

char *
inviewpath(char *file)
{
	static	char	path[PATHLEN + 1];
	int	i;

	/* look for the file */
	if (access(compath(file), READ) == 0) {
		return(file);
	}
	/* if it isn't a full path name and there is a multi-directory view path */
	if (*file != '/' && vpndirs > 1) {
		int file_len = strlen(file);

		/* compute its path from higher view path source dirs */
		for (i = 1; i < nvpsrcdirs; ++i) {
			(void) sprintf(path, "%.*s/%s",
				       PATHLEN - 2 - file_len, srcdirs[i],
				       file);
			if (access(compath(path), READ) == 0) {
				return(path);
			}
		}
	}
	return(NULL);
}

/* add a source file to the list */

void
addsrcfile(char *path)
{
	struct	listitem *p;
	int	i;
	
	/* make sure there is room for the file */
	if (nsrcfiles == msrcfiles) {
		msrcfiles += SRCINC;
		srcfiles = myrealloc(srcfiles, msrcfiles * sizeof(char *));
	}
	/* add the file to the list */
	srcfiles[nsrcfiles++] = stralloc(compath(path));
	p = mymalloc(sizeof(struct listitem));
	p->text = stralloc(compath(path));
	i = hash(p->text) % HASHMOD;
	p->next = srcnames[i];
	srcnames[i] = p;
}

/* free the memory allocated for the source file list */

void
freefilelist(void)
{
	struct	listitem *p, *nextp;
	int	i;

	/* if '-d' option is used a string space block is allocated */	
	if (isuptodate == NO) {
		while (nsrcfiles > 0) {
			free (srcfiles[--nsrcfiles]);
		}
	}
	else {
		/* for '-d' option free the string space block */
	    if (nsrcfiles > 0)		/* protect against empty list */
			free (srcfiles[0]);
		nsrcfiles = 0;
	}

	free (srcfiles);     /* HBB 20000421: avoid leak */
	msrcfiles = 0;
	srcfiles=0;
	
	for (i = 0; i < HASHMOD; ++i) {
		for (p = srcnames[i]; p != NULL; p = nextp) {
			/* HBB 20000421: avoid memory leak */
			free(p->text);
			nextp = p->next;
			free(p);
		}
		srcnames[i] = NULL;
	}
}
