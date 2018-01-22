

//-- Necessary Client Wrapper --------------------------------------------------

client
	/*Click(object, location, control, params)
		. = ..()
		interface.click(object, location, control, params)*/
	var
		turf/_mouseStorage
	MouseDown(object, location, control, params)
		. = ..()
		_mouseStorage = location
	MouseUp(object, turf/location, control, params)
		. = ..()
		if(!istype(location) || !istype(_mouseStorage)) return
		var /interface/mapEditor/editor = interface
		if(!istype(editor)) return
		for(var/tile/T in block(location, _mouseStorage))
			editor.click(object, T)


//-- Map Editor Interface ------------------------------------------------------

interface/mapEditor
	//-- Connect & Setup Environment
	var
		gameId
	New(client/client)
		//client.view = "[PLOT_SIZE*3]x[PLOT_SIZE*3]"
		world.maxx = PLOT_SIZE*3
		world.maxy = world.maxx
		// Connect Client
		. = ..()
		// Start Game Instance to manage the Map
		var /game/G = system.newGame(ID_SYSTEM, "edit")
		gameId = G.gameId
		G.quest = new()
		// Find starting place and display to client
		forceLoc(locate(round(world.maxx/2),round(world.maxy/2),1))

	//-- Movement & Control ----------------------
	density = FALSE
	movement = MOVEMENT_ALL
	step_size = 8
	icon = 'test.dmi'
	icon_state = "eye"
	var
		image/plotBorder
		commandsDown = 0
	Move()
		var/plot/plotArea/oldArea = aloc(src)
		. = ..()
		var/plot/plotArea/newArea = aloc(src)
		if(oldArea != newArea)
			// Move plot indicator to null (in case newLoc isn't in a plot/region)
			plotBorder.loc = null
			// Deactivate old plot
			if(istype(oldArea))
				var /plot/oldPlot = oldArea.plot
				oldPlot.deactivate()
			// Change Focus to new plot
			if(istype(newArea))
				// Activate new plot
				var /plot/newPlot = newArea.plot
				newPlot.activate()
				// Place plot indicator
				plotBorder.loc = locate(newArea.x, newArea.y, newArea.z)
				// Display new icons in tile editor
				for(var/component/slot/S in menu.basicPalette.tileEditor.slots)
					if(!S.storage) S.icon = null
					else S.icon = newArea.icon

			//if(istype(newArea)) menu.refreshTiles(newArea.plot)
			//else menu.refreshTiles()
	New()
		// Setup Plot Border
		plotBorder = image('plot_border.png')
		plotBorder.pixel_x = -2
		plotBorder.pixel_y = -2
		. = ..()
		client << plotBorder
		// Start Control Cycle
		while(src)
			sleep(TICK_DELAY)
			control()
	proc
		checkCommands()
			return client.macros.commands | commandsDown
		control()
			if(!client) return
			// Handle Movement
			var/command = checkCommands()
			if(command < 16)
				step(src, command)
			commandsDown = 0
			// Handle All other Commands
			var/block = menu.control()
			if(block)
				commandsDown = 0
				return

	//-- Click Controls --------------------------
	var
		storedCommand
	proc/click(object, tile/location, control, params)
		if(!istype(location)) return
		if(hascall(storedCommand, "handleClick"))
			storedCommand:handleClick(object, location)


//-- Utilities for help with map editing ---------------------------------------

interface/mapEditor
	regionMarker
		parent_type = /area
		icon = 'test.dmi'
		icon_state = "regionMarker"
		var
			gameId
			regionId
		New(place_holder, region/parent)
			. = ..()
			regionId = parent.id
			gameId = parent.gameId
			color = rgb(rand(0,300),rand(0,300),rand(0,300))
		Entered(interface/entrant)
			. = ..()
			if(!istype(entrant)) return
			for(var/turf/T in entrant.locs)
				if(!(T in contents)) continue
				var /game/G = system.getGame(gameId)
				var /region/R = G.getRegion(regionId)
				R.revealPlotAt(T.x, T.y)
				break
menu
	focus()
		. = ..()
region // Settings necessary to make the map editor work
	var
		interface/mapEditor/regionMarker/_regionMarker
		_defaultTerrain


//-- Map Editor Menu System ----------------------------------------------------

interface/mapEditor
	var
		interface/mapEditor/menu/menu
	Login()
		. = ..()
		menu = client.menu.addComponent(/interface/mapEditor/menu)
		menu.setup()
		client.menu.focus(menu)
	Logout()
		del menu
		. = ..()
interface/mapEditor/menu
	parent_type = /component
	var
		interface/mapEditor/menu/basicPalette/basicPalette
		interface/mapEditor/menu/furniturePalette/furniturePalette
	setup()
		basicPalette = addComponent(/interface/mapEditor/menu/basicPalette)
		basicPalette.setup()
		basicPalette.show()
	paletteOption
		parent_type = /usable
		var
			typePath
		New()
			. = ..()
			icon = initial(typePath:icon)
			icon_state = initial(typePath:icon_state)
			if(ispath(typePath, /furniture))
				var thumb = initial(typePath:thumbnailState)
				if(thumb) icon_state = thumb
				else icon_state = initial(typePath:icon_state)
		Click()
			var /interface/mapEditor/editor = usr
			ASSERT(istype(editor))
			//
			editor.storedCommand = src
			#warn Don't forget me
			/*for(var/I = 1 to editor.menu.basicPalette.tileEditor.slots.len)
				var/component/slot/S = editor.menu.basicPalette.tileEditor.slots[I]
				if(S.usable != src) continue
				editor.menu.basicPalette.tileEditor.position = I
				editor.menu.basicPalette.tileEditor.positionCursor()
				break*/

		proc/handleClick(object, tile/location)
			var /interface/mapEditor/editor = usr
			ASSERT(istype(editor))
			// Check if a region currently exists here
			var /plot/P = plot(location)
			if(!P) return
			var /game/G = system.getGame(P.gameId)
			var /region/R = G.getRegion(P.regionId)
			// If we're making tiles:
			if(ispath(typePath, /tile))
				R.changeTileAt(location.x, location.y, typePath)
				if(typePath == /tile/interact)
					var /terrain/T = terrain(P)
					T.setupTileInteraction(locate(location.x, location.y, R.z()))
			// If we're making furniture:
			else if(ispath(typePath, /furniture))
				var /furniture/F = locate() in location
				del F
				F = new typePath()
				F.forceLoc(location)
				F._configureMapEditor(editor)


//-- Basic Palette (Plot & Region Editing) -------------------------------------

interface/mapEditor/menu/basicPalette
	var
		component/box/tileEditor
		component/box/regionEditor
		component/box/furnitureEditor
	setup()
		regionEditor = addComponent(/component/box)
		regionEditor.setup(16,16,10,1)
		regionEditor.refresh(list(
			new /interface/mapEditor/menu/basicPalette/regionOption/resizeWorld(),
			new /interface/mapEditor/menu/basicPalette/regionOption/createRegion(),
			new /interface/mapEditor/menu/basicPalette/regionOption/deleteRegion(),
			new /interface/mapEditor/menu/basicPalette/regionOption/saveRegion(),
			new /interface/mapEditor/menu/basicPalette/regionOption/loadRegion(),
			new /interface/mapEditor/menu/basicPalette/regionOption/saveAllRegions(),
			new /interface/mapEditor/menu/basicPalette/regionOption/moveRegion(),
			new /interface/mapEditor/menu/basicPalette/regionOption/resizeRegion(),
			new /interface/mapEditor/menu/basicPalette/regionOption/changeTerrain(),
			new /interface/mapEditor/menu/basicPalette/regionOption/changeEnemyLevel(),
		))
		tileEditor = addComponent(/component/box)
		tileEditor.setup(16,32,10,1)
		tileEditor.refresh(list(
			new /interface/mapEditor/menu/paletteOption{ typePath=/tile/land}(),
			new /interface/mapEditor/menu/paletteOption{ typePath=/tile/wall}(),
			new /interface/mapEditor/menu/paletteOption{ typePath=/tile/feature}(),
			new /interface/mapEditor/menu/paletteOption{ typePath=/tile/interact}(),
			new /interface/mapEditor/menu/paletteOption{ typePath=/tile/water}(),
			new /interface/mapEditor/menu/paletteOption{ typePath=/tile/bridgeH}(),
			new /interface/mapEditor/menu/paletteOption{ typePath=/tile/bridgeV}(),
		))
		furnitureEditor = addComponent(/component/box)
		furnitureEditor.setup(16,48,10,1)
		furnitureEditor.refresh(list(
			new /interface/mapEditor/menu/paletteOption{ typePath=/furniture/deleter}(),
			null,
			new /interface/mapEditor/menu/paletteOption{ typePath=/memory/entrance}(),
			new /interface/mapEditor/menu/paletteOption{ typePath=/furniture/tree}(),
			new /interface/mapEditor/menu/paletteOption{ typePath=/furniture/chest}(),
			new /interface/mapEditor/menu/basicPalette/configure(),
		))

	//-- Plot Editing ------------------------------------
	configure
		parent_type = /interface/mapEditor/menu/paletteOption
		icon = 'mapEditorCommands.dmi'
		icon_state = "configure"
		New()
			. = ..()
			icon = initial(icon)
			icon_state = initial(icon_state)
		handleClick(furniture/object)
			var /interface/mapEditor/editor = usr
			if(!istype(editor)) return
			if(istype(object))
				object._configureMapEditor(editor)
			else
				var /plot/P = plot(object)
				if(!P) return
				var newId = input("Enter a warpId for this Plot.","Configure Plot", P.warpId) as text|null
				if(!newId) return
				var /game/G = system.getGame(editor.gameId)
				var /region/R = G.getRegion(P.regionId)
				R.setWarp(newId, P)

	//-- Region Editing ----------------------------------
	regionOption
		parent_type = /usable
		icon = 'mapEditorCommands.dmi'
		resizeWorld
			icon_state = "regionResizeWorld"
			Click()
				var /interface/mapEditor/editor = usr
				ASSERT(istype(editor))
				// Prompt user for new world size (in plots)
				var currentWidth  = -round(-world.maxx/PLOT_SIZE)
				var currentHeight = -round(-world.maxy/PLOT_SIZE)
				var width  = input("Set World Width (#plots)" , "Resize World", currentWidth ) as num|null
				var height = input("Set World Height (#plots)", "Resize World", currentHeight) as num|null
				width  = round(width ) || currentWidth
				height = round(height) || currentHeight
				// Remove editor from position (to prevent disconnects)
				var /turf/oldLoc = editor.loc
				var oldZ = editor.z
				editor.loc = null
				// Set world size (in plots)
				if(width  != currentWidth ) world.maxx = width *PLOT_SIZE
				if(height != currentHeight) world.maxy = height*PLOT_SIZE
				// Re-place editor
				var success = editor.Move(oldLoc)
				if(!success)
					editor.loc = locate(world.maxx, world.maxy, oldZ)
		createRegion
			icon_state = "regionCreateRegion"
			Click()
				var /interface/mapEditor/editor = usr
				ASSERT(istype(editor))
				var /game/G = system.getGame(editor.gameId)
				// Check if a region currently exists here
				var /plot/P = plot(editor)
				if(P)
					alert("There is already a region at this location.", "Create Region")
					return
				// Prompt user for region ID and default terrain
				var regionName = input("Set ID of new region", "Create Region", REGION_OVERWORLD) as text|null
				regionName = ckey(regionName)
				if(!regionName) return
				var defaultTerrain = input("Set Default Terrain","Create Region") in terrains
				// Check if region ID is already in use
				if(G.regions[regionName])
					alert("A region with that name has already been loaded.")
					return
				// Create and register region
				var /region/R = new(regionName)
				G.registerRegion(R)
				// Configure and display region
				system.map.gridData[regionName] = new /stringGrid()
				R.setLocation(
					round((editor.x-1)/PLOT_SIZE),
					round((editor.y-1)/PLOT_SIZE),
					editor.z-G.zOffset,
				)
				R.setSize(1,1, defaultTerrain)
				P = R.getPlot(0,0)
				// Reveal the current plot and trigger movement
				var oldLoc = editor.loc
				editor.loc = null
				editor.Move(oldLoc)
		deleteRegion
			icon_state = "regionDeleteRegion"
			Click()
				var /interface/mapEditor/editor = usr
				ASSERT(istype(editor))
				var /game/G = system.getGame(editor.gameId)
				// Ensure we're currently in a region
				var /plot/P = plot(editor)
				if(!P)
					alert("You are not currently in a region.", "Delete Region")
					return
				var /region/R = G.getRegion(P.regionId)
				ASSERT(R)
				// Confirm that the user really wants to delete this region
				var confirm = input("Please confirm to delete this region", "Delete Region") as null|anything in list("Confirm")
				if(!confirm)
					return
				// Cleanup and delete the region
				var /coord/editorLoc = coord(editor.x, editor.y, editor.z)
				editor.loc = null
				for(var/plot/unPlot in R.plots.contents())
					unPlot.unreveal()
				del R._regionMarker
				G.unregisterRegion(R)
				del R
				editor.forceLoc(locate(editorLoc.x, editorLoc.y, editorLoc.z))
		saveRegion
			icon_state = "regionSaveRegion"
			Click()
				var /interface/mapEditor/editor = usr
				ASSERT(istype(editor))
				var /game/G = system.getGame(editor.gameId)
				// Ensure we're currently in a region
				var /plot/P = plot(editor)
				if(!P)
					alert("You are not currently in a region.", "Save Region")
					return
				var /region/R = G.getRegion(P.regionId)
				ASSERT(R)
				// Calculate file name
				var fileName = "[FILE_PATH_REGIONS]/[R.id].json"
				// Check if that region already exists, prompt user to overwrite
				if(fexists(fileName))
					var confirm = input({"Overwrite existing region data "[R.id].json"?"}, "Save Region") as null|anything in list("Confirm")
					if(!confirm) return
				// Save the file to file system and alert player of success
				var success = replaceFile(fileName, json_encode(R.toJSON()))
				if(success) alert("Saving Complete.", "Save Region")
				else alert("Saving Failed.", "Save Region")
		loadRegion
			icon_state = "regionLoadRegion"
			Click()
				var /interface/mapEditor/editor = usr
				ASSERT(istype(editor))
				var /game/G = system.getGame(editor.gameId)
				// Prompt user for a region ID, calculate file name from id
				var /list/regionSaves = flist("[FILE_PATH_REGIONS]/")
				for(var/index = 1 to regionSaves.len) // Remove file extensions from region names
					var fileName = regionSaves[index]
					var fileExtIndex = findtext(fileName, ".")
					regionSaves[index] = copytext(fileName, 1, fileExtIndex)
				for(var/name in regionSaves) // Remove already loaded regions
					name = ckey(name)
					if(name in G.regions) regionSaves.Remove(name)
				if(!regionSaves.len)
					alert("There are no regions to load.", "Load Region")
					return
				var regionId = input("Select region to load", "Load Region") as null|anything in regionSaves
				if(!regionId) return
				// Load the region from file data
				system.map.loadRegion(regionId)
				var /list/objectData = system.map.regionTemplates[regionId]
				var /region/R = new(regionId)
				G.registerRegion(R)
				R.fromJSON(objectData)
				/*var filePath = "[FILE_PATH_REGIONS]/[regionId].json"
				ASSERT(fexists(filePath))
				var /list/objectData = json_decode(file2text(filePath))
				var /region/R = new(regionId)
				G.registerRegion(R)
				R.fromJSON(objectData)*/
				// Move editor to region
				var /plot/P = plot(editor) // Moving to null isn't working, for unknown reasons
				editor.Move(null) // so brute force it is
				editor.loc = null
				if(P) P.deactivate()
				var /plot/startPlot = R.getWarp(WARP_START)
				if(!startPlot)
					startPlot = R.getPlot(0,0)
				var /tile/startLoc = locate(
					round((R.mapOffset.x+startPlot.x+1/2)*PLOT_SIZE),
					round((R.mapOffset.y+startPlot.y+1/2)*PLOT_SIZE),
					R.z()
				)
				editor.forceLoc(startLoc)
		saveAllRegions
			icon_state = "saveAllRegions"
			Click()
				var /interface/mapEditor/editor = usr
				ASSERT(istype(editor))
				var /game/G = system.getGame(editor.gameId)
				// Save all regions, prompt for overwrites

				for(var/regionId in G.regions)
					var /region/R = G.getRegion(regionId)
					// Calculate file name
					var fileName = "[FILE_PATH_REGIONS]/[regionId].json"
					// Check if that region already exists, prompt user to overwrite
					if(fexists(fileName))
						var confirm = input({"Overwrite existing region data "[R.id].json"?"}, "Save Region") as null|anything in list("Confirm")
						if(!confirm) continue
					// Save the file to file system
					replaceFile(fileName, json_encode(R.toJSON()))
				alert("Saving Finished.", "Save All Regions")
		moveRegion
			icon_state = "regionMoveRegion"
			Click()
				var /interface/mapEditor/editor = usr
				ASSERT(istype(editor))
				var /game/G = system.getGame(editor.gameId)
				// Ensure we're currently in a region
				var /plot/P = plot(editor)
				if(!P)
					alert("You are not currently in a region.")
					return
				var /region/R = G.getRegion(P.regionId)
				ASSERT(R)
				// Prompt the player for the new region location
				var _x = input("Set Region X Position (#plots)", "Translate Region", R.mapOffset.x) as num|null
				if(_x == null) return
				var _y = input("Set Region Y Position (#plots)", "Translate Region", R.mapOffset.y) as num|null
				if(_y == null) return
				if(_x < 0 || _y < 0)
					alert("Coordinates cannot be negative")
					return
				// Move the region by unrevealing, setting new coords, and then resizing
				for(var/plot/unPlot in R.plots.contents())
					unPlot.unreveal()
				del R._regionMarker
				R.mapOffset.x = _x
				R.mapOffset.y = _y
				R.setSize(R.width, R.height)
				// If we're still in the region, reveal the current plot
				var oldLoc = editor.loc
				editor.loc = null
				editor.Move(oldLoc)
		resizeRegion
			icon_state = "regionResizeRegion"
			Click()
				var /interface/mapEditor/editor = usr
				ASSERT(istype(editor))
				var /game/G = system.getGame(editor.gameId)
				// Ensure we're currently in a region
				var /plot/P = plot(editor)
				if(!P)
					alert("You are not currently in a region.")
					return
				var /region/R = G.getRegion(P.regionId)
				ASSERT(R)
				// Prompt player for new dimensions
				var width  = input("Set Region Width (#plots)" , "Resize Region", R.width ) as num|null
				var height = input("Set Region Height (#plots)", "Resize Region", R.height) as num|null
				if(!width || !height) return
				if(width < R.width || height < R.height)
					var confirm = input(editor, "Region data will be lost in clipped plots. Continue?", "Resize Region") as null|anything in list("Continue")
					if(!confirm) return
				// Resize Region
				R.setSize(width, height)
				// If we're still in the region, reveal the current plot
				var oldLoc = editor.loc
				editor.loc = null
				editor.Move(oldLoc)
		changeTerrain
			icon_state = "regionChangeTerrain"
			Click()
				var /interface/mapEditor/editor = usr
				ASSERT(istype(editor))
				var /game/G = system.getGame(editor.gameId)
				// Ensure we're currently in a region
				var /plot/P = plot(editor)
				if(!P)
					alert("You are not currently in a region.")
					return
				var /region/R = G.getRegion(P.regionId)
				ASSERT(R)
				// Prompt user for a new terrain
				var terrainId = input("Set Terrain of this Plot", "Change Terrain", P.terrain) in terrains
				// Set terrain on plot and redisplay
				P.terrain = terrainId
				P.unreveal()
				// Reveal the current plot and trigger movement
				var oldLoc = editor.loc
				editor.loc = null
				P.reveal()
				editor.Move(oldLoc)
		changeEnemyLevel
			icon_state = "regionEnemyLevel"
			Click()
				var /interface/mapEditor/editor = usr
				ASSERT(istype(editor))
				// Ensure we're currently in a plot
				var /plot/P = plot(editor)
				if(!P)
					alert("You are not currently in a region.")
					return
				// Prompt user for a new terrain
				var enemyLevel = input("Set Enemy Level of this Plot", "Change Enemy Level", P.enemyLevel) as num|null
				if(enemyLevel == null) return
				// Set enemyLevel on plot and redisplay
				P.enemyLevel = enemyLevel
				P.unreveal()
				// Reveal the current plot and trigger movement
				var oldLoc = editor.loc
				editor.loc = null
				P.reveal()
				editor.Move(oldLoc)



	//-- Furniture Configure Hook ---------
furniture
	proc/_configureMapEditor(interface/mapEditor/editor)
		// A hook so furniture can configure itself when placed on the map