#define REGION_TEST "test"
//#define EDIT_MAP
#define SAVE_TEST "savvy"

//------------------------------------------------------------------------------

// These settings can be configured
// *: In tenths of a second
#define DEFAULT_PLOTS 16
	// The width/height of the world in number of plots
#define TICK_DELAY 0.4
	// Time* between server ticks. FPS is 10/TICK_DELAY
#define TURN_SPEED_PLOT 40
	// Time between plot environment effects
#define TIME_LAG_DISCONNECT 40
	// The time* before a interface deletes after a client has logged out
#define TIME_PLOT_DEACTIVATION 600
	// The time* that a plot will stay active after all characters leave
#define TIME_HURT 10
	// The time* in which a combatant in invulnerable after being hurt
#define TIME_HEADSTONE 30
	// The time* that a headstone will remain before a character respawns
#define TIME_ITEM_COLLECT 2
	// The time that an item will sit on the ground before it can be collected. Prevents items from being collected without being seen.
#define TIME_ITEM_DISAPPEAR 250
	// The time an item will sit around before disappearing.
#define TIME_TERRAIN_NAME 18
	// The time a terrain notifier menu component stays on the screen.
#define TIME_RESOURCE_RESTORE 3000
	// The normal time after furniture has been interacted with before it restores.
#define SAVEFILE_VERSION "0.1.0"
#define FILE_PATH_GAMES "data/saved_games"
#define FILE_PATH_REGIONS "data/regions"
#define FILE_PATH_PROFILES "data/profiles"
#define SALE_MARKDOWN (1/4)
	// The amount you get back from selling items
#define ITEM_DROP_RATE (1/6)
	// How often enemies drop items when they die

//Environment Variables:
#define TIME_DILATION_FACTOR (24*60)
	// The speed of gameworld time as compared to our own.
	// MUST ENCLOSE IN PARENTHESIS!
#define UPDATES_PER_DAY 240
	// The number of times per day the environment (temperature, light, etc) will update.
	// UPDATE_PER_DAY / (864000/(10*60)) -> gives the number of minutes between updates.
#define TEMP_YEARLY_LOW 25
#define TEMP_YEARLY_HIGH 75
#define SUNDOWN 18
#define SUNUP 6
#define NOON 12

// Character IDs
#define CHARACTER_KING 0
#define CHARACTER_HERO 1
#define CHARACTER_CLERIC 2
#define CHARACTER_SOLDIER 3
#define CHARACTER_GOBLIN 4



// Nothing beneath this line can be configured
	// Drawing Planes
#define PLANE_WEATHER 15
#define PLANE_LIGHTING 20
#define PLANE_MENU 200

#define OVERWORLD "overworld"
	// The region id for the overworld
#define INTERIOR "interior"
	// The region id for plots representing the interiors of buildings
#define MAP_DEPTH 1
	// The number of z levels each game is allocated to place its regions
#define TILE_SIZE 16
	// The width/height of a Tile, like a turf or the standard size of an atom/movable
#define PLOT_SIZE 15
	// The width/height of a plot
#define WORLD_SIZE (DEFAULT_PLOTS * PLOT_SIZE)
#define PRIMARY 64
#define SECONDARY 128
#define TERTIARY 256
#define QUATERNARY 512
#define STATUS 1024
	// Movement flags. Mobs/Objs that share a movement flag with a tile can enter it.
#define MOVEMENT_NONE 0
#define MOVEMENT_FLOOR 1
#define MOVEMENT_WATER 2
#define MOVEMENT_WALL 4
#define MOVEMENT_ALL 7
	// Projectile / Tile interactions
#define INTERACTION_NONE 0
#define INTERACTION_TOUCH 1
#define INTERACTION_CUT 2
#define INTERACTION_FIRE 4
#define INTERACTION_WALK 8
#define INTERACTION_WIND 16
#define INTERACTION_0000000000100000 32
#define INTERACTION_0000000001000000 64
#define INTERACTION_0000000010000000 128
#define INTERACTION_0000000100000000 256
#define INTERACTION_0000001000000000 512
#define INTERACTION_0000010000000000 1024
#define INTERACTION_0000100000000000 2048
#define INTERACTION_0001000000000000 4096
#define INTERACTION_0010000000000000 8192
#define INTERACTION_0100000000000000 16384
#define INTERACTION_1000000000000000 32768
	// Gear positions
#define WEAR_WEAPON 1
#define WEAR_BODY 2
#define WEAR_SHIELD 3
#define WEAR_CHARM 4
	// Factions
#define FACTION_NONE 0
#define FACTION_ENEMY 1
#define FACTION_PLAYER 2
#define FACTION_PACIFY ~0

#define COMPOUND_INDEX(X,Y,WIDTH) (((Y)-1)*(WIDTH)+(X))
#define DECOMPOSE_Y(INDEX,WIDTH) (1+round(((INDEX)-1)/(WIDTH)))
#define DECOMPOSE_X(INDEX,WIDTH) (1+((INDEX)-1)%(WIDTH))
	// Crafting Ingredient Signatures
#define SIG_WOOD "woo"
#define SIG_STONE "sto"
#define SIG_IRON "iro"
#define SIG_SWORD "swo"
#define SIG_SHIELD "she"
#define SIG_ARMOR "arm"

#define DAY_TICKS 864000
	// The number of tenths of a second in a day.  10*1*60*60*24 = 864000
#define DAYS_PER_YEAR 360
	// Must remain 360 because it's used directly by trigonometric functions

#define ID_SYSTEM "system"
	// The id of the "game owner" when editing the map
#define WARP_START "start"
	// The default plot.warpId when warping to a region

#define INVENTORY_MAX 24