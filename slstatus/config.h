/* slstatus config.h: every item is wrapped as [ info ].
 * install.sh substitutes the network interface and CPU temperature file. */

const unsigned int interval = 1000;          /* ms between updates */
static const char unknown_str[] = "--";      /* shown when a value is unavailable (e.g. VPN down) */
#define MAXLEN 2048

static const struct arg args[] = {
	/* function     format                       argument */
	{ cpu_perc,     "[ ctOS ] [ cpu %s%% ] ",    NULL },
	{ ram_perc,     "[ ram %s%% ] ",             NULL },
	{ temp,         "[ %sC ] ",                  "@TEMP@" },
	{ netspeed_rx,  "[ rx %s ",                  "@IFACE@" },
	{ netspeed_tx,  "tx %s ] ",                  "@IFACE@" },
	{ ipv4,         "[ vpn %s ] ",               "tun0" },   /* HackTheBox / OpenVPN interface */
	{ uptime,       "[ up %s ] ",                NULL },
	{ datetime,     "[ %s ]",                    "%a %d %b  %H:%M" },
};
