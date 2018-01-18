

//-- System --------------------------------------------------------------------

#define diag(messages...) system.diagnostic(list(messages), __FILE__, __LINE__)
var/system/system = new()
system
	var
		// The three version variables are set in version_history.dm
		versionType = "Internal"
		versionNumber = "-.-.-"
		versionHub = -1
		//
		author = "Jacob A. Brennan"
		authorHub = "IainPeregrine"
		gameName = "Project Mustard"
		gameHub = "iainperegrine.projectcress"
		passwordHub = SECURE_HUB_PASSWORD
		//
		_ready = FALSE
		list/_waitingClients = new() // When the world boots, clients are put in here until the system is ready.
		//
		list/games = new()
		list/mapSlots = new()

	New()
		. = ..()
		system = src
		spawn()
			startProject()

	proc
		startProject()
			diag("<b>----- System Starting -----</b>")
			loadVersion()
			loadHub()
			setupTerrains()
			setupMap()
			_ready = TRUE
			diag("<b>----- System Ready -----</b>")
			for(var/client/C in _waitingClients)
				registerPlayer(C)


	//-- Development Utilities -------------//
	proc
		diagnostic(list/messages, file, line)
			var argText = ""
			var first = TRUE
			for(var/key in messages)
				if(!first)
					argText += ", "
				first = FALSE
				argText += "[key]"
			world << {"<span style="color:grey">[file]:[line]::</span> <b>[argText]</b>"}

	//-- Game Management -------------------//
	proc
		loadHub()
			world.version = versionHub
			world.name = gameName
			world.hub = gameHub
			world.hub_password = passwordHub
		registerGame(game/newGame) // Called whenever a game is created to store it allocate map space
			// Store for later retrieval
			games[newGame.gameId] = newGame
			// Allocate Space
			var slotIndex
			for(var/index = 1 to mapSlots.len)
				if(!mapSlots[index])
					slotIndex = index
					break
			if(!slotIndex)
				slotIndex = ++mapSlots.len
			mapSlots[slotIndex] = newGame
			// Inform game about its map placement (Set zOffset on game)
			newGame.zOffset = (slotIndex-1)*MAP_DEPTH+1
			return newGame
		deregisterGame(game/oldGame)
			// Remove game from games list
			games.Remove(oldGame)
			// Remove game from mapSlots
			var slotIndex
			for(var/index = 1 to mapSlots.len)
				if(mapSlots[index] == oldGame)
					slotIndex = index
					mapSlots[slotIndex] = null
					break
			// Shrink World, if possible
			if(slotIndex == mapSlots.len)
				while(!mapSlots[mapSlots.len])
					mapSlots.len--
		getGame(gameId) // Called by any part of the game to get the game from a gameId
			return games[gameId]
		newGame(_playerId, _saveId)
			var /game/newGame = new(_playerId, _saveId)
			registerGame(newGame)
			return newGame
		loadGame(saveId)
			game = new()
			diag(game.load(saveId))
		/*saveGame()
			environment.pause()
			diag("Saving World")
			for(var/client/C)
				new /interface/holding(C)
			diag(" -- Saving Characters")
			//for(var/character/C)
			//	C.unload()
			diag(" -- Saving Map")
			//town.saveWorld()
			/*for(var/regionId in regions)
				var/region/R = regions[regionId]
				R.save()*/
			diag(" -- Saving Environment")
			//environment.save()
			diag(" -- Finished Saving")
			environment.unpause()*/
		restartWithoutSave()
			diag("<b>---- System Restarting ----</b>")
			world << "<hr>"
			world.Reboot()
		stopWithoutSave()
			diag("<b>----- System Stopping -----</b>")
			del world

	//-- Player Handling -------------------//
	proc
		registerPlayer(client/client) // Called by /interface/clay/New()
			if(!_ready)
				_waitingClients.Add(client)
				spawn(1)
					diag("System is Loading")
				return
			// Check games in progress for disconnected player.
				// Already done. Clay is never created if there's already another interface waiting
			// Send player to title screen
			new /titleScreen(client)

	//-- Map Data Cache --------------------//
	var
		system/map/map
	proc
		setupMap()
			map = new()
			map.loadRegions()
	map
		parent_type = /datum
		var
			list/gridData = new()
			list/regionTemplates = new()
		proc
			loadRegion(regionId)
				// Load Region Data from file
				var/filePath = "[FILE_PATH_REGIONS]/[regionId].json"
				ASSERT(fexists(filePath))
				var/list/regionData = json_decode(file2text(filePath))
				// Setup stringGrid
				var gridText = regionData["gridText"]
				//var tileWidth  = regionData["width" ] * PLOT_SIZE
				//var tileHeight = regionData["height"] * PLOT_SIZE
				var /stringGrid/largeString = json2Object(gridText)//new(tileWidth, tileHeight, gridText)
				// Store Data
				regionTemplates[regionId] = regionData
				gridData[regionId] = largeString
				regionData["gridText"] = null
			loadRegions()
				var /list/regionIds = list(
					REGION_OVERWORLD
				)
				for(var/regionId in regionIds)
					loadRegion(regionId)
		proc
			getChar(regionId, posX, posY)
				var /stringGrid/largeString = gridData[regionId]
				return largeString.get(posX, posY)
			putChar(regionId, posX, posY, char)
				var /stringGrid/largeString = gridData[regionId]
				return largeString.put(posX, posY, char)