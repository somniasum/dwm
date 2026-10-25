/* st colour table: "Holy Lulz" (DedSec / Watch Dogs 2), sampled from the wallpaper.
 *
 * Rules this palette follows, so no text ever vanishes:
 *   - colour 0 ("black") is a visible grey, never the same as the background
 *   - every other colour has at least 4.5:1 contrast against the background (colour 0: 3:1)
 *   - colours keep their usual meaning: red = error, green = success, yellow = warning,
 *     blue = directories/info, so dnf, git, ls, etc. read correctly
 *
 * Indexes 256-259 are the cursor, reverse-cursor, default foreground and default background.
 * defaultfg/defaultbg/defaultcs/defaultrcs in st's config point at them (258/259/256/257),
 * so the array MUST keep exactly 260 entries. The check at the bottom fails the build if not.
 */
static const char *colorname[] = {
	/* 8 normal colors */
	"#5c615c",	/*  0 black   : visible grey */
	"#ff2a2a",	/*  1 red     : errors (same red as the dwm accent) */
	"#44a844",	/*  2 green   : success, added */
	"#d9c84e",	/*  3 yellow  : warnings */
	"#8a9bb0",	/*  4 blue    : directories, info (steel grey-blue) */
	"#d05cbf",	/*  5 magenta */
	"#86c5bd",	/*  6 cyan */
	"#dedede",	/*  7 white   : text */

	/* 8 bright colors */
	"#8a8f8a",	/*  8 bright black : comments, dim text */
	"#ff6060",	/*  9 bright red */
	"#8ed58e",	/* 10 bright green */
	"#f6ed99",	/* 11 bright yellow */
	"#aebfd6",	/* 12 bright blue */
	"#e88ad9",	/* 13 bright magenta */
	"#b5e3dc",	/* 14 bright cyan */
	"#fefefe",	/* 15 bright white */

	[255] = 0,

	/* more colors can be added after 255 to use with DefaultXX */
	"#ff2a2a",	/* 256 cursor: red */
	"#080808",	/* 257 text under the cursor */
	"#dedede",	/* 258 default foreground */
	"#080808",	/* 259 default background */
};

/* build guard: defaultfg=258, defaultbg=259, defaultcs=256, defaultrcs=257 must exist */
typedef char colorname_must_have_260_entries[(sizeof(colorname) / sizeof(colorname[0]) == 260) ? 1 : -1];
