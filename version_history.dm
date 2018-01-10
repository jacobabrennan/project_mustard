
//------------------------------------------------
//------------------------------------------------------------------------------

system
	var/versionMotto = "Single+"
	proc/loadVersion()
		system.versionType = "Internal"
		system.versionNumber = "0.0.9"
		system.versionHub = 0
		spawn(1)
			world << "<b>Version [versionType] [versionNumber]</b>: [versionMotto]"


//345678901234567890123456789012345678901234567890123456789012345678901234567890
//------------------------------------------------------------------------------

/*-- Feature List - Remember: It's the map and Bosses! COMBAT! -----------------

Focus - Things which must be done this version
	Redo player status menues
		Player1 can manage each character
		other players can manage their own character
	Menu for player management (single+)
	Setup hotKeys to "equip"
		Otherwise multiple players can use the same item

Upcomming - Feature candidates for the next version
	Finish Clearing out Bugs List
	Make Enemies smarter about "shooting" with melee only in melee range
	Certain characters can only equip certain things
	Social Systems
		Chat Within Games
		Help Newbies

Set In Stone - Features that have to be finished for 1.0
	Title Screen
		With Animation
		Join Game in progress
		Start Own Game
		Enter map editor
	Intro Boss Fight
		Maybe no other players (not single+)
		Regressia Hero against Lorcan (legend, not true)
		Convey basic story, but make them FEEL AWESOME!
		SPECTACLE!
	Player Profile data
		Data about the player that persists among all games
		Preferences
		Accomplishments
	Goblin Town
	Revive meter that fills over fainted character
		only fills if a character is reviving
		resets if reviving stops
		revives once full
	Hit Animation

Spectulative - Ideas for new features to make the game better.
	Air Ship
		RACING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		Aerial Bombardment
		Sky Hooks
	Cleric behavior includes attacking
		attack with wand when enemies are close and we can't escape or heal
	Plot Backgrounds that show distant scenary,
		like you're walking on a mountain ridge looking out at the sunset
	Languages - Portuguese!
	Submersion
	Wind
	Will-o-wisps
	The Khandroma - Red Caps
	"Modes" learned through memories that effect the overworld
	Refactor Character & Party
		Remove /character/partyMember
		(this seems to be the only big difference between character & combatant)
		Allow for parties not as the main game party, for enemy parties!
	//
	Things in lighting plane only appear opaque when lit
	differences of: kind, flavor, scale
	Enemy roles:
		fodder
		hp drain (pingers)
		treasure carrier
		blockers
		challengers
		all: slow player movement, prevent from reaching areas

Deferred - Low Priority Optional Features
	Savefile versions

*/
/*

Internal 0.0.9 -- Single+
	Refactored Menu System
		Added Stat Component: Sprite + Label
		Changed all positioning to use absolute coords instead of screen_loc.
		Factored out RPG menues into /interface/rpg/menu
	Added New Status Screen
		Primary Player can edit equipment and see stats of all party members.

Internal 0.0.8 -- Shooty McStupid-Face
	Combat:
		Combatants have a defend method.
		Defaults to checking frontProtection to block projectiles.
	Gear:
		Shields: Provide front protection with a damage threshold
		Wands: Weak melee attack Cleric, that also use MP for projectiles.
	Enemy Archetypes Added:
		Normal: Random Movement, Gridded Movement, Random Shooting
		Diagonal: With random direction changing and reflection settings
		Ranged: Represents cowardly archers and mages. Fully configurable.
		Fixated: Homing Missiles and Determinators.
		Snaking: Compound enemies of variable length
		Ball: Compound mass of enemies around a central enemy
	Map Editor:
		Set enemyLevel (difficulty) per plot

Internal 0.0.7 -- Now you're playing with Power
	Quest System: Tracks arbitrary values across maps and sessions
	Player Saving and Loading Capacity
		Saving works, but no currently no player interface
		Inventory: Unified and managed by the party
		Improved party member path finding

Internal 0.0.6 -- DEATH PUFF
	Added Death Puffs
	Warping between plots & regions
	Added Map Editor, including:
		Saving & Loading
		Region Editor
			Change World Dimensions (in number of plots)
			Create Region
			Delete Region
			Move Region (by number of plots)
			Resize Region (in number of plots)
			Load Region
			Unload Region
			Save Region / Save all Regions
			Change Plot Terrain
		Plot Editor
			Edit Tiles
			Place Furniture
			Configure Furniture

Internal 0.0.5 -- Party on Wayne!
	Added Party System
	Restructured Command / takeTurn / behavior.
	Fixed Menus so they can move around smoothly.
	Added Game Over & Respawn, including disconnected / reconnected players.

Internal 0.0.4 -- And there was darkness
	Changed Project direction.
		Concept is now a "single player plus" action RPG, similar to
		the NES Secret of Mana.

Internal 0.0.3 -- Let there be light
	Added Precipitation to weatherSystem. Weather can now produce rain and snow.
	Added Wind. Wind moves across the map at the same bearing as the associated
		weather system, and causes wind based effects to tiles and furniture.

Internal 0.0.2
	Introduced "System" object to track version, game state, saving / loading.
	Introduced environment object:
		Manages Time, Lighting, Temperature, Humidity, and Weather.
		Manages the natural cycles of days, seasons, and years.
	Introduced weatherSystems:
		weatherSystems represent weather fronts and air masses moving through
		the game world. weatherSystems manage the cycle of humidity, temperature
		precipitation, cloud cover, and wind, by varying the effect of each with
		respect to the weatherSystem over time.

Internal 0.0.1
	Introduced lighting.

Internal Not Numbered
	Version tracking began with version 0.0.0. Before that many of the
		fundamental systems were put in place, including the following.
	Mapping: Tiles, Regions, Terrains, Plots, Actors, Furniture, characters,
		events, buildings, etc.
	Map Generation: Plasma height maps, roguelike placement of walls,
		dungeon layout generation
	Map Saving / Loading
	Basic Combat
	The HUD / menuing system, including robust menuing components
	Player keyboard input (key state)
*/







