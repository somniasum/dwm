/* slstatus config.h: every item is wrapped as [ info ].

const unsigned int interval = 1000;          /* ms between updates */
static const char unknown_str[] = "--";      /* for when there is no data */
#define MAXLEN 2048

static const struct arg args[] = {
	/* function     format                       argument */
	{ cpu_perc,     "[ cpu %s%% ] ",             NULL },
	{ ram_perc,     "[ ram %s%% ] ",             NULL },
	{ temp,         "[ %sC ] ",                  "@TEMP@" },
	{ datetime,     "[ %s ]",                    "%a %d %b  %H:%M" },
};
