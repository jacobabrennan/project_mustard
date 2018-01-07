

//------------------------------------------------------------------------------

system
	var/versionMotto = "Now you're playing with Power"
	proc/loadVersion()
		system.versionType = "Internal"
		system.versionNumber = "0.0.7"
		system.versionHub = 0
		spawn(1)
			world << "<b>Version [versionType] [versionNumber]</b>: [versionMotto]"


//345678901234567890123456789012345678901234567890123456789012345678901234567890
//------------------------------------------------------------------------------

/*-- Feature List - Remember: It's the map and Bosses! COMBAT! -----------------

Focus - Things which must be done this version
	Deprecate startPlotCoords
	Dungeons that you can walk into

Upcomming - Feature candidates for the next version
	Quest System to track what the player has done in the world, save with game.

Set In Stone - Features that have to be finished for 1.0
	Diagonal Enemies are cheap
		They should randomize starting direction at plot/activate()
		Maybe move slower when first activated
	Title Screen
		With Animation
		Join Game in progress
		Start Own Game
		Enter map editor
	Menu for player management (single+)
	Intro Boss Fight
		Maybe no other players (not single+)
		Regressia Hero against Lorcan (legend, not true)
		Convey basic story, but make them FEEL AWESOME!
		SPECTACLE!

Spectulative - Ideas for new features to make the game better.
	Plot Backgrounds that show distant scenary,
		like you're walking on a mountain ridge looking out at the sunset
	Revive meter that fills over fainted character
		only fills if a character is reviving
		resets if reviving stops
		revives once full

Deferred - Low Priority Optional Features
	Savefile versions

*/
/*

Internal 0.0.7 -- Now you're playing with Power

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