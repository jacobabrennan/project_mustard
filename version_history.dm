

//------------------------------------------------------------------------------

system
	var/versionMotto = "DEATH PUFF"
	proc/loadVersion()
		system.versionType = "Internal"
		system.versionNumber = "0.0.6"
		system.versionHub = 0
		spawn(1)
			world << "<b>Version [versionType] [versionNumber]</b>: [versionMotto]"


//345678901234567890123456789012345678901234567890123456789012345678901234567890
//------------------------------------------------------------------------------
/*
Remember: It's the maps and bosses! COMBAT!
Features:
	World Editing
		Even if it's quick and dirty,
		but you should be able to make something nice with the new menu features
	Quest System to track what the player has done in the world, save with game.
	Title Screen
		With Animation
		Join Game in progress
		Start Own Game
		Enter map editor
	Dungeons that you can walk into
	Revive meter that fills over fainted character
		only fills if a character is reviving
		resets if reviving stops
		revives once full
	Menu for player management (single+)
	Intro Boss Fight
		Maybe no other players (not single+)
		Regressia Hero against Lorcan (legend, not true)
		Convey basic story, but make them FEEL AWESOME!
		SPECTACLE!
	Plot Backgrounds that show distant scenary,
		like you're walking on a mountain ridge looking out at the sunset

	Deferred: Savefile versions
*/
/*

Internal 0.0.6
	Added Death Puffs
	Added Map Editor, including:
		Region Editor
			Change World Dimensions (in number of plots)
			Create Region
			Delete Region
			Move Region (by number of plots)
			Resize Region (in number of plots)
			Change Plot Terrain
		Plot Editor
			Edit Tiles
			Place Furniture

Internal 0.0.5
	Added Party System
	Restructured Command / takeTurn / behavior.
	Fixed Menus so they can move around smoothly.
	Added Game Over & Respawn, including disconnected / reconnected players.

Internal 0.0.4
	Changed Project direction.
		Concept is now a "single player plus" action RPG, similar to
		the NES Secret of Mana.

Internal 0.0.3
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