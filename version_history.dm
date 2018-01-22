

//-- Version History, Planned Features, Brainstorming, Notes -------------------

//------------------------------------------------

//------------------------------------------------------------------------------

//345678901234567890123456789012345678901234567890123456789012345678901234567890

// ^ Blank Dividers for easy cut/paste. 80 & 50 characters long.
system
	var/versionMotto = "Over Troubled Water"
	proc/loadVersion()
		system.versionType = "Internal"
		system.versionNumber = "0.0.20"
		system.versionHub = 0
		spawn(1)
			world << "<b>Version [versionType] [versionNumber]</b>: [versionMotto]"


//------------------------------------------------------------------------------

/*-- Feature List - Remember: It's the map and Bosses! COMBAT! -----------------

Focus - Things which must be done this version
	At least one upgrade item for each class

Upcomming - Feature candidates for the next version
	Butterflies
	Audio preferences, such as mute all, effects volume, & music volume.
	Player Profile data
		Data about the player that persists among all games
		Preferences
		Accomplishments
	Scripted Events
		Must be able to show the same thing to all players & spectators,
		even as PlayerOne advances dialogues, etc.
	Hit Animation
	More Final Enemies
	More Final Items
	Begin Final Mapping
	Event Furniture:
		Make a furniture type that when activated checks the quest system, and
		loads a configured script. Examples could include being ambushed by the
		Red Caps the first time you visit a plot.
		Maybe there's a central script manager that loads scripted events by ID?

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
	Party Editing with multiple character options for subscribers
	Red Caps
		Enemy goblin party, flies around on an airship / balloon
		Aerial Bombardment
		Sky Hooks
	Status Panes
		Game Settings
		World / Dungeon Map
			Map shows where party members are
			Also Shows Quest status. Similar to the Four Orbs in FF1.
	Goblin Town
		NPCs needed

Spectulative - Ideas for new features to make the game better.
	AI aggression setting.
	Charms that can adjust just about anything:
		alter basic stats (max hp/mp, regain hp/mp, base speed)
		alter derived stats (weapon attack, shield threshold, spell range)
		alter allowed equip flags
		allow equiping two handed weapons with one hand
		add spells to hot keys
	No treasure chests, but statues that come to life?
	Pause Game when player 1 goes to status
	Plot Backgrounds that show distant scenary,
		like you're walking on a mountain ridge looking out at the sunset
	Make the screen shake for big impacts
	Languages - Portuguese!
	Wind
	Will-o-wisps
	"Modes" learned through memories that effect the overworld
	Weapons: Flail, Spear/Lance, Instruments, Fist/Grappler?
	//
	Things in lighting plane only appear opaque when lit - when using BLEND_ADD
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
	Hidden Gnomes
	Submersion
	Airship Racing!


//------------------------------------------------------------------------------

Internal 0.0.20 : Jan 20th 2018 -- Over Troubled Water
	Added Autojoining graphics for water.
	Added Bridge tile types.
	Chests now play an opening animation (instead of opening the inventory).
	Tweaked: Transition animation; arrow range AI; furniture saving.

Internal 0.0.19 : Jan 19th 2018 -- Needs more waterfalls
	Added Basic Support for Sound Effects
	World Map:
		Made basic layout (large scale overworld plan).
		Started work on final overworld map file.

Internal 0.0.18 : Jan 18th 2018 -- Clean Cup x2; Move Down x2
	Added Chat Portraits (16px square) for each character.
	Added Dialogue menu components.
		Displays an arbitrary amount of text in sequential statements.
		Use #n in text to indicate a new line.
		Use #p to indicate a break between statements (display the cursor).
	Added Basic Audio system with support for playing songs.

Internal 0.0.17 : Jan 17th 2018 -- A picture's worth a thousand lines
	Finished Character Graphics and Portraits (for 4 main characters)

Internal 0.0.16 : Jan 16th 2018 -- Do you have to let it Linger?
	Secondary Parties - Any faction, many parties at once, fights enemies too.
	Factored partyMember back into Character
	Character attack AI is now handled by the equipped weapon.
	Added Quivers. Range, Speed, and Potency determined by bow. Type by Quiver.

Internal 0.0.15 : Jan 15th 2018 -- It's over 230 thousand
	Added stringGrid to speed up map functions accessing regions' tile grids.
	Added Equipment Overlays to characters (currently planned for only shields).
	Added (internal) story outline document.

Internal 0.0.14 : Jan 14th 2018 -- His power level is incredible!
	Added Two Handed Weapons
	Refactored Region Saving and Loading to share memory across game instances.

Internal 0.0.13 : Jan 13th 2018 -- Captain's Log...
	Basic Chests, Have a quest id and an item type
	Books can now add more than one spell.
	Cleric's AI responds to which healing spell is in their equipped book.
	Added Basic chat System with channels/tabs for game and system.

Internal 0.0.12 : Jan 12th 2018 -- Please Leave a Number
	Add Books with AoE healing spell
	Added basic Effects type
	Reviving: Party Members must now fill a meter before character is revived.

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







