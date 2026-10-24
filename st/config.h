
/* DEDSEC — Holy Lulz palette */
static const char *colorname[] = {
    [0]  = "#080808", /* black: background */
    [1]  = "#ff1717", /* red: glitches */
    [2]  = "#a00000", /* green slot: dark blood red */
    [3]  = "#ff4545", /* yellow slot: bright red */
    [4]  = "#777777", /* blue slot: grey */
    [5]  = "#c00000", /* magenta slot: crimson */
    [6]  = "#aaaaaa", /* cyan slot: silver */
    [7]  = "#e5e5e5", /* white: foreground */
    [8]  = "#555555", /* bright black */
    [9]  = "#ff3333", /* bright red */
    [10] = "#d00000", /* bright green slot */
    [11] = "#ff6666", /* bright yellow slot */
    [12] = "#999999", /* bright blue slot */
    [13] = "#ff1744", /* bright magenta slot */
    [14] = "#cccccc", /* bright cyan slot */
    [15] = "#ffffff", /* bright white */

    /* Keep your existing extended colors below */
    [256] = "#e5e5e5", /* default cursor */
    [257] = "#080808", /* reverse cursor */
};

/* Default terminal colors */
static unsigned int defaultfg = 7;
static unsigned int defaultbg = 0;
static unsigned int defaultcs = 256;
static unsigned int defaultrcs = 257;

