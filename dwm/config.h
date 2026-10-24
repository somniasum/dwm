/* dwm config.h: black, minimal, red accent. Performance-first. */
#include <X11/XF86keysym.h>

/* palette (string macros so dmenu can reuse them) */
#define FONT    "0xProto Nerd Font Mono:size=10"  /* explicit font = no fontconfig fallback scans */
#define C_BG    "#000000"
#define C_DIM   "#8a8a8a"
#define C_ACC   "#ff2a2a"   /* red accent: selected tag, focused border, launcher highlight */
#define C_BORD  "#1c1c1c"

/* appearance */
static const unsigned int borderpx  = 1;
static const unsigned int snap      = 32;
static const int showbar            = 1;
static const int topbar             = 1;
static const char *fonts[]          = { FONT };
static const char dmenufont[]       = FONT;

static const char col_bg[]     = C_BG;
static const char col_dim[]    = C_DIM;
static const char col_acc[]    = C_ACC;
static const char col_border[] = C_BORD;
static const char *colors[][3] = {
	/*               fg       bg      border     */
	[SchemeNorm] = { col_dim, col_bg, col_border },
	[SchemeSel]  = { col_acc, col_bg, col_acc    },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* class     instance  title  tags mask  isfloating  monitor */
	{ "Gimp",    NULL,     NULL,  0,         1,          -1 },
};

/* layout(s) */
static const float mfact        = 0.55;
static const int nmaster        = 1;
static const int resizehints    = 0;
static const int lockfullscreen = 1;
static const int refreshrate    = 120;

static const Layout layouts[] = {
	/* symbol  arrange function */
	{ "[]=",   tile },
	{ "[M]",   monocle },
	{ "><>",   NULL },
};

/* key definitions */
#define MODKEY Mod4Mask   /* Super */
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* launchers */
#define DMENU_ARGS "dmenu -i -fn '" FONT "' -nb '" C_BG "' -nf '" C_DIM "' -sb '" C_ACC "' -sf '" C_BG "'"

/* app launcher: every .desktop app (native, Flatpak, Steam...), most-used first */
static const char *launchcmd[] = { "/bin/sh", "-c",
	"mkdir -p \"$HOME/.cache\" && exec j4-dmenu-desktop --no-generic --term=st "
	"--usage-log=\"$HOME/.cache/j4-usage\" --dmenu=\"" DMENU_ARGS "\"", NULL };
/* raw command runner: anything in $PATH (dwm.c expects the names dmenucmd / dmenumon) */
static char dmenumon[2] = "0";
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-i", "-fn", FONT, "-nb", C_BG, "-nf", C_DIM, "-sb", C_ACC, "-sf", C_BG, NULL };
static const char *termcmd[]  = { "st", NULL };

/* helper scripts (installed to /usr/local/bin by install.sh) */
static const char *shotregion[] = { "/usr/local/bin/shot", "region", NULL };
static const char *shotfull[]   = { "/usr/local/bin/shot", "full",   NULL };
static const char *shotwindow[] = { "/usr/local/bin/shot", "window", NULL };
static const char *ledtoggle[]  = { "/usr/local/bin/kbd-led", NULL };
static const char *kbdlock[]    = { "/usr/local/bin/kbd-lock", "lock", NULL };
static const char *kbdunlock[]  = { "/usr/local/bin/kbd-lock", "unlock", NULL };

/* audio (PipeWire) and media players (MPRIS) */
static const char *volup[]    = { "wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+", NULL };
static const char *voldown[]  = { "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-", NULL };
static const char *volmute[]  = { "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle", NULL };
static const char *micmute[]  = { "wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle", NULL };
static const char *mediaplay[] = { "playerctl", "play-pause", NULL };
static const char *medianext[] = { "playerctl", "next", NULL };
static const char *mediaprev[] = { "playerctl", "previous", NULL };

static const Key keys[] = {
	/* modifier                     key                       function        argument */
	/* launch */
	{ MODKEY,                       XK_d,                     spawn,          {.v = launchcmd } },
	{ MODKEY|ShiftMask,             XK_d,                     spawn,          {.v = dmenucmd } },
	{ MODKEY,                       XK_Return,                spawn,          {.v = termcmd } },
	/* screenshots */
	{ 0,                            XK_Print,                 spawn,          {.v = shotregion } },
	{ ShiftMask,                    XK_Print,                 spawn,          {.v = shotfull } },
	{ MODKEY,                       XK_Print,                 spawn,          {.v = shotwindow } },
	{ MODKEY,                       XK_s,                     spawn,          {.v = shotregion } },
	{ MODKEY|ShiftMask,             XK_s,                     spawn,          {.v = shotfull } },
	/* volume + media: Super+F1..F7 (media keys work too) */
	{ MODKEY,                       XK_F1,                    spawn,          {.v = volmute } },
	{ MODKEY,                       XK_F2,                    spawn,          {.v = voldown } },
	{ MODKEY,                       XK_F3,                    spawn,          {.v = volup } },
	{ MODKEY,                       XK_F4,                    spawn,          {.v = micmute } },
	{ MODKEY,                       XK_F5,                    spawn,          {.v = mediaprev } },
	{ MODKEY,                       XK_F6,                    spawn,          {.v = mediaplay } },
	{ MODKEY,                       XK_F7,                    spawn,          {.v = medianext } },
	{ 0,                            XF86XK_AudioRaiseVolume,  spawn,          {.v = volup } },
	{ 0,                            XF86XK_AudioLowerVolume,  spawn,          {.v = voldown } },
	{ 0,                            XF86XK_AudioMute,         spawn,          {.v = volmute } },
	{ 0,                            XF86XK_AudioMicMute,      spawn,          {.v = micmute } },
	{ 0,                            XF86XK_AudioPrev,         spawn,          {.v = mediaprev } },
	{ 0,                            XF86XK_AudioPlay,         spawn,          {.v = mediaplay } },
	{ 0,                            XF86XK_AudioNext,         spawn,          {.v = medianext } },
	/* keyboard: LEDs on/off, and lock (disable) the keyboard */
	{ MODKEY,                       XK_F8,                    spawn,          {.v = ledtoggle } },
	{ MODKEY,                       XK_F9,                    spawn,          {.v = kbdlock } },
	/* windows */
	{ MODKEY,                       XK_q,                     killclient,     {0} },
	{ MODKEY|ShiftMask,             XK_q,                     quit,           {0} },
	{ MODKEY,                       XK_b,                     togglebar,      {0} },
	{ MODKEY,                       XK_j,                     focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,                     focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_h,                     setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,                     setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_i,                     incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_o,                     incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_space,                 zoom,           {0} },
	{ MODKEY,                       XK_Tab,                   view,           {0} },
	{ MODKEY,                       XK_t,                     setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_m,                     setlayout,      {.v = &layouts[1]} },
	{ MODKEY|ShiftMask,             XK_space,                 togglefloating, {0} },
	{ MODKEY,                       XK_0,                     view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,                     tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,                 focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period,                focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,                 tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period,                tagmon,         {.i = +1 } },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
};

/* mouse: Super+drag to move/resize, click tags to switch,
 * MIDDLE-CLICK the workspace numbers to unlock a locked keyboard */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button2,        spawn,          {.v = kbdunlock } },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
