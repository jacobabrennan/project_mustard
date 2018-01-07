

//------------------------------------------------------------------------------

var/game/game
game
	var
		gameId // A string to uniquely identify this game. Used extensively throughout project.
		ownerId // The "player1" for this game. Game will be saved under this player's ID.
		saveId // A string to uniquely identify this game's save file among others belonging to this player.
	New(_ownerId, _saveId)
		. = ..()
		ownerId = _ownerId
		saveId = _saveId
		gameId = "[_ownerId]_[_saveId]"
		//
		//environment = json2Object(saveData["environment"])
		//diag(" -- Loading Climate & Time")
		//environment.load()
		//diag(" -- Attempting to Load Town Data")
		//town = new(OVERWORLD)
		//interior = new(INTERIOR)
		//if(!interior.load())
		//	interior.setSize(town.width, town.height, "interior")
		//if(!town.load())
		//	diag(" -- No town data. Generating New Town")
		//	town.generateOverworld(DEFAULT_PLOTS, DEFAULT_PLOTS, "forest")
		//diag(" -- Loading Characters")
		//for(var/interface/clay/waitingPlayer)
		//	new /interface/rpg(waitingPlayer.client)
		//diag(" -- Finished Loading")
		//spawn(1)
		//	environment.activate()
	proc
		save()
			var filePath = "[FILE_PATH_GAMES]/[gameId].json"
			replaceFile(filePath, json_encode(toJSON()))
			var/interface/rpg/RPG = new()
			RPG.key = ownerId
		load(saveData)
			//var/filePath = "[FILE_PATH_GAMES]/[saveId].json"
			//ASSERT(fexists(filePath))
			//var/list/saveData = json_decode(file2text(filePath))
			//
			//environment = json2Object(saveData["environment"])
			//diag("Loading World")
			//diag(" -- Loading Climate & Time")
			//environment.load()
			//diag(" -- Attempting to Load Town Data")
			//town = new(OVERWORLD)
			//interior = new(INTERIOR)
			//if(!interior.load())
			//	interior.setSize(town.width, town.height, "interior")
			//if(!town.load())
			//	diag(" -- No town data. Generating New Town")
			//	town.generateOverworld(DEFAULT_PLOTS, DEFAULT_PLOTS, "forest")
			//diag(" -- Loading Characters")
			//for(var/interface/clay/waitingPlayer)
			//	new /interface/rpg(waitingPlayer.client)
			//diag(" -- Finished Loading")
			//spawn(1)
			//	environment.activate()
	toJSON()
		var /list/objectData = ..()
		objectData["gameId"] = gameId
		objectData["ownerId"] = ownerId
		objectData["saveId"] = saveId
		objectData["party"] = party.toJSON()
		return objectData

	fromJSON(list/objectData)
		gameId = objectData["gameId"]
		ownerId = objectData["ownerId"]
		saveId = objectData["saveId"]
		party = json2Object(objectData["party"])


	//--------------------------
	var
		party/party
	proc
		createNew()
			party = new(gameId)
			party.createNew()
		start()
			spawn(10)
				diag("Game Starting")
				var /client/player
				for(var/client/C)
					if(C.ckey == ckey(ownerId))
						player = C
				party.addPlayer(player, CHARACTER_HERO)
				party.changeRegion(getRegion(REGION_TEST))
				var /region/derp = getRegion("derp")
				for(var/plot/P in derp.plots.contents())
					P.reveal()
		respawn()
			party.respawn()
			party.changeRegion(getRegion(REGION_TEST))
		gameOver()
			for(var/regionKey in regions)
				var /region/R = regions[regionKey]
				for(var/plot/P in R.activePlots)
					P.gameOverCleanUp()
			respawn()


	//-- Player Management -----
	var
		list/spectators = new()
	proc
		addSpectator(client/client)
			new /interface/holding(client)
			client.eye = party.mainCharacter.interface
			//
			spawn(10)
				var role = pick(CHARACTER_SOLDIER, CHARACTER_GOBLIN, CHARACTER_CLERIC)
				party.addPlayer(client, role)


	//-- Map Management --------
	var
		zOffset
		list/regions = new()
	proc
		getRegion(regionId)
			// Be strict about region ids
			regionId = ckey(regionId)
			// If region already exists, return it
			var /region/theRegion = regions[regionId]
			if(theRegion) return theRegion
			// otherwise load it from save system
			theRegion = loadRegion(regionId)
			return theRegion
		registerRegion(region/newRegion)
			regions[newRegion.id] = newRegion
			newRegion.gameId = gameId
			for(var/plot/P in newRegion.plots.contents())
				P.gameId = gameId
		unregisterRegion(region/newRegion)
			regions.Remove(newRegion.id)
		loadRegion(regionId)
			// Load Region Data from file
			var/filePath = "[FILE_PATH_REGIONS]/[regionId].json"
			ASSERT(fexists(filePath))
			var/list/regionData = json_decode(file2text(filePath))
			// Create & register region
			var/region/newRegion = new(regionId)
				// Can't use json2Object() because registerRegion() must be called before fromJSON()
			registerRegion(newRegion)
			newRegion.fromJSON(regionData)
			// Reveal Start Plot
			if(newRegion.startPlotCoords)
				var /plot/startPlot = newRegion.getPlot(
					newRegion.startPlotCoords.x,
					newRegion.startPlotCoords.y
				)
				startPlot.reveal()
			//
			return newRegion

