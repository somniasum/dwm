/* slstatus config.h: every item is wrapped as [ info ].
 * install.sh fills in the CPU temperature file and the volume file path below. */

const unsigned int interval = 1000;          /* ms between updates */
static const char unknown_str[] = "--";      /* for when there is no data */
#define MAXLEN 2048

static const struct arg args[] = {
	/* function     format                       argument */
	{ cpu_perc,     "[ cpu %s%% ] ",             NULL },
	{ ram_perc,     "[ ram %s%% ] ",             NULL },
	{ temp,         "[ %sC ] ",                  "@TEMP@" },
	{ cat,          "[ vol %s ] ",               "@RUNDIR@/volume" },  /* written by bin/volume */
	{ datetime,     "[ %s ]",                    "%a %d %b  %H:%M" },
};
