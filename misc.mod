: $Id: misc.mod,v 1.14 2005/03/25 13:16:35 billl Exp $
COMMENT
Misc. routines:
sassign() // assign a string from system
dassign()// assign a double
nokill() // chatch SIGHUP
prtime() // gives date/time
fspitchar(c,file) // sends single char to a file
spitchar(c)       // sends single char to stdout: eg c=1 => ^A
file_exist(file) // returns 1 if filename exists
hocgetc(file) // get single char from a file

  Note that with a SUFFIX equal to "nothing" these functions do not
have a suffix in hoc.  Thus to call sassign() in hoc use simply type
"sassign()" <- without the quotes.

    file_exist(filename)
        - returns 1 if filename exists

    sassign()  (string assign, written by Bill Lytton)
        - This routine is used to set a string in Hoc to something that has
          been returned by a system call.  sassign("name","shell_call ...")
          will produce a file called "sassign" in the cwd that will contain
          a hoc call that sets string 'name' to the result of shell_call 
          which should be a string.
        
    dassign()  (double assign, written and used by Bill Lytton)
        - This routine is used to set a variable in Hoc to something that has
          been returned by a system call.  sassign("name","shell_call ...")
          will produce a file called "dassign" in the cwd that will contain
          a hoc call that sets variable 'name' to the result of shell_call 
          which should be a number.

ENDCOMMENT
                           
INDEPENDENT {t FROM 0 TO 1 WITH 1 (ms)}

NEURON {
    SUFFIX nothing
}

VERBATIM
#include <unistd.h>     /* F_OK     */
#include <errno.h>      /* errno    */
#include <signal.h>
#include <sys/types.h>         /* MUST REMEMBER THIS */
#include <time.h>
#include <stdio.h>
#include <limits.h>
#ifndef NRN_VERSION_GTEQ_8_2_0
FILE* hoc_obj_file_arg(int);
#endif
ENDVERBATIM

:* FUNCTION file_exist()
FUNCTION file_exist() {
VERBATIM
    /* Returns TRUE if file exists, if file not exist the need to reset
       errno else will get a nrnoc error.  Seems to be a problem even
       if I don't include <errno.h> */

    char *filename;

    filename = gargstr(1);

    if (*filename && !access(filename, F_OK)) {
        _lfile_exist = 1;

    } else {
        /* Errno set to 2 when file not found */
        errno = 0;

        _lfile_exist = 0;
    }
ENDVERBATIM
}

:* PROCEDURE sassign()
PROCEDURE sassign() {
VERBATIM
    FILE *pipein;
    char string[BUFSIZ], **strname, *syscall;

    strname = hoc_pgargstr(1);
    syscall = gargstr(2);

    if( !(pipein = popen(syscall, "r"))) {
        fprintf(stderr,"System call failed\n");
        return 0; // TODO: ask M 
    }
    
    if (fgets(string,BUFSIZ,pipein) == NULL) {
        fprintf(stderr,"System call did not return a string\n");
        pclose(pipein); return 0; // TODO: ask M
    }

    /*  assign_hoc_str(strname, string, 0); */
    hoc_assign_str(strname, string);

    pclose(pipein);
    errno = 0;
ENDVERBATIM
}

:* PROCEDURE dassign() 
PROCEDURE dassign() {
VERBATIM
    FILE *pipein, *outfile;
    char *strname, *syscall;
    double num;

    strname = gargstr(1);
    syscall = gargstr(2);

    if ( !(outfile = fopen("dassign","w"))) {
        fprintf(stderr,"Can't open output file dassign\n");
        return 0; 
    }

    if( !(pipein = popen(syscall, "r"))) {
        fprintf(stderr,"System call failed\n");
        fclose(outfile); return 0; 
    }
    
    if (fscanf(pipein,"%lf",&num) != 1) {
        fprintf(stderr,"System call did not return a number\n");
        fclose(outfile); pclose(pipein); return 0; 
    }

    fprintf(outfile,"%s=%g\n",strname,num);
    fprintf(outfile,"system(\"rm dassign\")\n");

    fclose(outfile); pclose(pipein);
    errno = 0;
ENDVERBATIM
}

:* PROCEDURE nokill() 
: nohup
PROCEDURE nokill() {
VERBATIM
  signal(SIGHUP, SIG_IGN);
ENDVERBATIM
}

:* FUNCTION prtime()
FUNCTION prtime () {
VERBATIM
  double prt;
  static double PRTIME;
  prt = (clock()-PRTIME)/CLOCKS_PER_SEC;
  // UINT_MAX for 32 bit machine -- see 'man clock'
  if (prt<0) prt += UINT_MAX/CLOCKS_PER_SEC; 
  PRTIME=clock();
  _lprtime = prt;
ENDVERBATIM
}

:* FUNCTION now ()
FUNCTION now () {
VERBATIM
  _lnow = time((time_t*)0);
  _lnow -= (12784) * 24*60*60; // time from the Epoch to 01/01/05
ENDVERBATIM
}

:* PROCEDURE sleepfor ()
PROCEDURE sleepfor (sec) {
VERBATIM
  struct timespec ts;
  ts.tv_sec = (time_t)_lsec;
  ts.tv_nsec = (long)0;
  nanosleep(&ts,(struct timespec*)0);
ENDVERBATIM
}

:* PROCEDURE fspitchar
PROCEDURE fspitchar(c) {
VERBATIM
{	
  FILE* f;
  f = hoc_obj_file_arg(2);
  fprintf(f, "%c", (int)_lc);
}
ENDVERBATIM
}

:* PROCEDURE spitchar
PROCEDURE spitchar(c) {
VERBATIM
{	
  printf("%c", (int)_lc);
}
ENDVERBATIM
}

:* FUNCTION hocgetc
FUNCTION hocgetc() {
VERBATIM
{	
  FILE* f;
  f = hoc_obj_file_arg(1);
  _lhocgetc = (double)getc(f);
}
ENDVERBATIM
}
