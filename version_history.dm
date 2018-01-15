

//-- Version History, Planned Features, Brainstorming, Notes -------------------

//------------------------------------------------

//------------------------------------------------------------------------------

//345678901234567890123456789012345678901234567890123456789012345678901234567890

// ^ Blank Dividers for easy cut/paste. 80 & 50 characters long.
system
	var/versionMotto = "Captain's Log..."
	proc/loadVersion()
		system.versionType = "Internal"
		system.versionNumber = "0.0.13"
		system.versionHub = 0
		spawn(1)
			world << "<b>Version [versionType] [versionNumber]</b>: [versionMotto]"


//345678901234567890123456789012345678901234567890123456789012345678901234567890
//------------------------------------------------------------------------------

/*-- Feature List - Remember: It's the map and Bosses! COMBAT! -----------------

Alpha1 Test - Test Basic Movement & Combat Systems
	Large Map to Wander around
	Lots of enemies
		At least one boss level enemy
	At least one upgrade item for each class

Focus - Things which must be done this version
	Contact Susan

Upcomming - Feature candidates for the next version
	Hit Animation
	Problem: This game is based around "bullet hell" levels of enemy activity.
		At the scale currently planned (and allowed by networking constraints)
		what can be done to provide that level of challenge?
		As it stands, even rudimentary AI clears out tough enemies in no time,
		and pretty much all I can do is give them more hp.
	Shield - Graphic Overlay
	Status Panes
		Game Settings
		World / Dungeon Map
			Map shows where party members are
	Make Enemies smarter about "shooting" with melee only in melee range
	Player Profile data
		Data about the player that persists among all games
		Preferences
		Accomplishments
	More Final Enemies
	More Final Items
	Begin Final Mapping

Set In Stone - Features that have to be finished for 1.0
	Audio Systems - Both Music & Sound Effects
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
	Goblin Town
		NPCs needed
		Dialogue Menues needed
	Party Editing with multiple character options for subscribers

Spectulative - Ideas for new features to make the game better.
	No treasure chests, but statues that come to life?
	Hidden Gnomes
	Pause Game when player 1 goes to status
	The Khandroma (airship) - Red Caps
		File Bug report. This is necessary and won't get fixed otherwise.
		RACING!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		Aerial Bombardment
		Sky Hooks
	Refactor Character & Party
		Remove /character/partyMember
		(this seems to be the only big difference between character & combatant)
		Allow for parties not as the main game party, for enemy parties!
	Cleric behavior includes attacking
		attack with wand when enemies are close and we can't escape or heal
	Plot Backgrounds that show distant scenary,
		like you're walking on a mountain ridge looking out at the sunset
	Make the screen shake for big impacts
	Submersion
	Languages - Portuguese!
	Wind
	Will-o-wisps
	"Modes" learned through memories that effect the overworld
	Weapons: Flail, Spear/Lance, Instruments, Fist/Grappler?
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
	//
	Do you always grab things?
	Revive member who fell down holl, etc

Deferred - Low Priority Optional Features
	Savefile versions


//------------------------------------------------------------------------------

Internal 0.0.13 : Jan 13th 2018 -- Captain's Log...
	Basic Chests, Have a quest id and an item type
	Books can now add more than one spell.
	Cleric's AI responds to which healing spell is in their equipped book.
	Added Basic chat System with channels/tabs for game and system.

Internal 0.0.12 : Jan 12th 2018 -- Please Leave a Number
	Add Books with AoE healing spell
	Added basic Effects type
	Reviving: Party Members must now fill a memter before character is revived.

Internal 0.0.11 : Jan 11th 2018 -- What Test?
	Editing a character updates in real time anyone who can view that character.
	Items placed in hot keys now removes them from inventory
		this prevents multiple players from using one item at the same time.
	Items & character now have equipFlags which determine who can use what.
	Changed RPG menu system to use a new menu component, Pane, in status screen.
	Added Player / Party Management Pane

Internal 0.0.10 : Jan 10th 2018 -- Come Together Over Me
    Cleaning Up Project
        Added Readme
        Changed locations of some files

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







