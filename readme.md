# Project Mustard

## Table of Contents
* [Project Team - Who's Responsible for this?](#project-team)
* [BYOND - Familiarity with environment](#byond)
* [File Structure - Version Management and Code Cenventions](#file-structure)
* [Program Structure - What you're reading this doc for](#program-structure)
  * [The System](#the-system)
  * [Game Instances](#game-instances)
  * [Interfaces](#interfaces)
  * [Menu System](#menu-system)
  * [Map System](#map-system)
  * [Combat and Characters](#combat-and-characters)


# Project Team
#### And why "mustard"?

This project was created on January 2nd (if my memory's correct) by Jacob A Brennan, who uses the BYOND account IainPeregrine (IP). At this time, IP is the sole developer and the maintainer of this document.

IP names their projects using random vegetable names until they're in Beta, at least. This prevents getting attached to a bad name early in development, and allows for greater flexibility in moving the project in new directions.


# BYOND
#### Familiarity with environment

The project compiles to a multi-player video game server to be run by the BYOND software suite. The BYOND software suite consists of the following elements:
  * DreamDaemon (DD) - A utility for serving BYOND games instances to a network.
  * DreamSeeker (DS) - The client players use to access the game.
  * DreamMaker  (DM) - The IDE used to edit and compile BYOND games.
  * The Pager        - IMS program for players w/ game discovery & distribution.
  * The Hub          - BYOND's games index. Accessed through the web or pager.
  * BYOND Keys       - User accounts provided by BYOND for games & the Hub.

To use this software, you would compile it via DM, launch it via DD, sign into your Key via the Hub or Pager, and then use the Hub's searce features or the pager to open the game, which would launch DS automatically. In general, you never open DS yourself, but it is opened when you try to join a game via the hub or the pager.

Note: The BYOND installer also associates the protocol byond:// with the pager, so directing your browser to a BYOND game, such as byond://f0lak.hazordhu, will launch the pager and display that game. From there you can click links to play hosted games or download the game to host yourself.

DM uses several file extensions to organize and identify project resources. The important ones for this project are as follows:
  * .dme (DM Environment) - DM IDE project file. Open this to open a project.
  * .dm - Code Files.
  * .dmi (DM Icon) - Graphics files that are, internally, PNGs with comments. DM can also use other graphics like PNG & JPG.
  * .dmf (DM... face?) - "Interface" files to define windowing controls.
  * .dmb (DM Binary) - A compiled BYOND game to upload to the Hub or host w/ DD.
  * .rsc (Resource) - Compiled resources for the dmb. Automatically generated.


# File Structure
#### Version Management and Code Cenventions

The Project uses Git / Github for source control. Contributors should be familiar with Git; help is available if needbe.

## Directory Structure
The Directory structure is still evolving. For now:
  * Graphics, fonts, and sound go into /rsc, under a directory where appropriate.
  * Place all code into /code directory, except version_history.dm and __bugs.dm
  * Sometimes the order of compilation is important. In these cases, prefix the file with two underscores a two digit number and an underscore to define compile order. Example: "__01_defines.dm"
  * Code defining the game engine or background systems used by other player facing systems should go in its own directory, or /scaffolding.
  * Code which defines final player facing instances to be used in the game go in /typedefs. Examples: Golden Sword, Imp Archer.
  * Dummied out code can go in /unused until a final determination is made.
  * All code defining the mapping system should go in /map.
  * All code defining the combat system should go in /combat.
  * Other large systems should get their own directories.

## Special Files
There are several special files used to help maintain the project:
  * Readme.dm - This File
  * version_history.dm - Version History, Planned Features, Brainstorming, Notes
  * bugs.dm - A list of #warn directives to keep the developer informed of bugs.
  * __00_defines.dm - Global values defined as preprocessor macros.

## File Structure
File Structure goes as follows:
  * Write all new code in whatever file you want! If you get bogged down in choosing the right place, you may never write it or write it with the wrong expectations. Write the code, then refactor to uncover structure. Over time, restructure towards Object Oriented (OO) principles.
  * Each file should have a single type definition. Other type defs may be present if:
    * They are necessary to the function of the governing type def.
    * Use by other objects elsewhere is limited.
    * Ideally, they consist of few lines of code.
    * They do not properly belong in their own file.
  * Dependent types should be organized under their governing type def using the parent_type variable. See http://www.byond.com/forum/?post=36663
  * Each file should start with two blank lines, then an 80 character header.
  * Sections of the file should be grouped logically by related function. Such groupings should be marked by a blank line then a 50 char header.
  * Headers should include a brief description of the grouping function.
  * Templates of both headers can be found at the start of version_history.dm
  * Any temporary "wrapper" code should be placed at the top of the file under its own main header, to be easily identified and removed / refactored.

## Code Conventions
Other Best Practices
  * Use camelCase for variable names.
  * In objects that will be further derived, variables which cannot be configured by sub types should be grouped together and marked.
  * Sometimes it's necessary to create a variable which is used by only one method in one place. In these cases, prefix the variable with a single underscore. Where possible, refactor these cases.
  * Never use single letter variable names in type definitions.
  * It's ok not to comment your code as you write it, but as soon as you go back later to fix or edit it, then you should start to:
			* Break procs into logical segments marked by comments. Even just //
			* Move related code into marked headers. Even a single odd proc


# Program Structure
#### What you're reading this doc for

There are a handful of key concepts necessary to understand this project and how its code is structured. These are:
  * The System Object
  * Game Objects
  * Interface Objects
  * The Menu System
  * The Map System
  * Combat & Characters


## The System
At the very top level is the System Object (a singleton). The system handles all new players entering the game and routes them where they should be. It also creates and manages Game instances, generates diagnostic messages, and handles player profiles (not yet implemented). Its type def is in __02_system.dm


## Game Instances

Several game worlds can exist and be played at the same time in one project instance. As far as concerns all other objects in a game world, the Game object is the central organizational object. Games are instanced by the System, usually at the request of a player at the title screen. All games have a gameId which is used extensively by all aspects of the project, and identifies the game's save file in the file system. Most importantly, the gameId is used by regions & plots to retrieve a reference to their associated game from the System. Each game has associated Party and Quest objects.

Each game has an associated Party, which tracks and manages the characters that players play as & with.


## Interfaces

BYOND provides two objects for interaction between the player and the world: these are Mobs and Clients. The Client represents the DS instance the player uses to connect and play the game; Mob represents a "mobile" on the game map. As a rule, every client has a mob. Deleting the mob will eject a client from the game entirely. Generally, the mob is used represent the player's "character" within the game world. This presents problems when the game needs to represent game states without player control centered around a "character". For example, A title screen. For a more in-depth exporation of this, see: http://www.byond.com/forum/?post=49308

The Interface object type exists to solve these issues. Interface subtypes are defined to provide an "interface" between the player and the game world in specific game states. For example, there exists a titleScreen interface to solve above use case. Other interfaces include "clay" which is used for clients that have just connected to the world and need to be registered with the system, & "holding" which is for players between game states that the system doesn't know what do to with yet. Both of these interfaces provide no controls or output to the player so they can be safely isolated from the program while it works.

The RPG interface handles the majority of player interaction with the game, and provides control and output for the duration of play (excluding death and cutscenes).


## Menu System

The project uses a complex and powerful hierarchical menuing system. Each client has a menu variable referencing its own menu instance, which is created as soon as the client connects. The menu is used to organize, display, and control text, images, menu "chrome", and complex compound components made from simpler primitives. Common examples of uses for the system include things like RPG status screen, dialogue boxes with character portraits, and any time a cursor is used to move between text options.

This system can be found in /scaffolding/menu.dm. Common components can also be placed in that file under the appropriate heading, but most derived components should go in their own files, such as the title screen and RPG status.

The following is a brief explanation of how the menu system works:
  * Everything in the menu system is derived from /component.
  * Each component has a focus variable and a focus() method to set it.
  * Commands sent to the client are routed to the interface, most of the time interfaces will first route a command to the menu, if the menu returns false, then the interface may do something else. In general, returning TRUE means that a menu component has handled the player input, and no further routing should be done.
  * Commands sent to component are, by default, routed to the component's focus.
  * Components MUST be instanced via their parent's addComponent() method. For top level components, such as the title screen, this is client.menu.
  * Most components must then have setup() called before they can be used. Generally, setup() should be called immediately after instancing.


## Map System

The project uses a highly modified version of BYOND's atomic mapping system. Familiarity with BYOND will not automatically provide familiarity with this project. At the top level, the map is governed by Game instances, and everything that has a physical location should have an associate: Game, Region, Plot, Tile.

The Tile is the most granular level of placement, corresponding to an atomic Turf. The Plot represents one "screen" of tiles. This is a square region which the player can move around in. In the RPG interface, only one plot is displayed to the user at a time, and movement within the plot doesn't result in movement of the camera. Movement to the border of a plot will result in a "transition" to the new plot, accompanied by a visual slide.

Each Plot belongs to a region, which is a rectangular region of the map in which the user can move freely between plots. Each region also maintains a list of "warp" points for moving the user between regions, and often a WARP_START warp as a default entry to the region.

Terrains also exist to server as plot themes, providing things like graphics and enemy types. Terrains can be thought of as Biomes from Minecraft. Nothing is ever contained in a Terrain, but each Plot has an associated Terrain.

The project also provides a map editor, accessed via /interface/mapEditor. Using this tool an editor can create regions, save and load them, edit tiles, warps, terrains, and enemy difficulty.


## Combat and Characters

No centralized object exists to manage combat. Instead, combat is realized via the interactions of Actors placed in the mapping system. Actors are objects with associated AI and which act over time. The two important ones for combat Combatant and Projectile; the function of each should be clear from their name.

Combatant is further defined into subtypes Enemy and Character. Enemy is mainly a convenience container for further derived types. Character provides saving & loading and use of equipment. PartyMember is further defined to provide for player control of a Character. Note that Characters, and even Party Members, can be used as enemies by setting the faction to an appropriate value.
