/* slstatus config.h: every item is wrapped as [ info ].
 * \001 and \002 are colour switches that dwm reads (dwm/patches/status-colors.diff):
 * \001 = bracket colour (red), \002 = info colour. Octal escapes on purpose, so a
 * letter right after them (like the c in "cpu") is never swallowed as a hex digit.
 * install.sh fills in the CPU temperature file and the volume file path below. */

const unsigned int interval = 1000;          /* ms between updates */
static const char unknown_str[] = "--";      /* for when there is no data */
#define MAXLEN 2048

static const struct arg args[] = {
	/* function     format                                      argument */
	{ cpu_perc,     "\001[\002 cpu %s%% \001] ",              NULL },
	{ ram_perc,     "\001[\002 ram %s%% \001] ",              NULL },
	{ temp,         "\001[\002 %sC \001] ",                   "@TEMP@" },
	{ cat,          "\001[\002 vol %s \001] ",                "@RUNDIR@/volume" },  /* written by bin/volume */
	{ datetime,     "\001[\002 %s \001]",                     "%a %d %b  %H:%M" },
};
