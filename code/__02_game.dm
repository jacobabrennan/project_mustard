

//-- Game ----------------------------------------------------------------------

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
		//environment.load()
		//spawn(1)
		//	environment.activate()

	//-- Saving & Loading ----------------------------
	proc
		save()
			var filePath = "[FILE_PATH_GAMES]/[ownerId]/[saveId].json"
			replaceFile(filePath, json_encode(toJSON()))
		load()
			var/filePath = "[FILE_PATH_GAMES]/[ownerId]/[saveId].json"
			ASSERT(fexists(filePath))
			var/list/saveData = json_decode(file2text(filePath))
			fromJSON(saveData)
	toJSON()
		var /list/objectData = ..()
		objectData["gameId"] = gameId
		objectData["ownerId"] = ownerId
		objectData["saveId"] = saveId
		objectData["party"] = party.toJSON()
		objectData["quest"] = party.toJSON()
		return objectData

	fromJSON(list/objectData)
		gameId = objectData["gameId"]
		ownerId = objectData["ownerId"]
		saveId = objectData["saveId"]
		party = new(gameId)
		party.fromJSON(objectData["party"])
		quest = json2Object(objectData["quest"])


	//-- Party Management ----------------------------
	var
		party/party
		quest/quest
	proc
		createNew()
			party = new(gameId)
			party.createNew()
			quest = new()
		start()
			var /client/player
			for(var/client/C)
				if(C.ckey == ckey(ownerId))
					player = C
			party.addPlayer(player, CHARACTER_HERO)
			party.changeRegion(REGION_OVERWORLD)
		respawn()
			party.respawn()
			party.changeRegion(REGION_OVERWORLD)
		gameOver()
			for(var/regionKey in regions)
				var /region/R = regions[regionKey]
				for(var/plot/P in R.activePlots)
					P.gameOverCleanUp()
			respawn()

	//-- Map Management ------------------------------
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
			// Retrieve Region Data system
			var/list/regionData = system.map.regionTemplates[regionId]
			ASSERT(regionData)
			// Create & register region
			var/region/newRegion = new(regionId)
				// Can't use json2Object() because registerRegion() must be called before fromJSON()
			registerRegion(newRegion)
			newRegion.fromJSON(regionData)
			return newRegion


//-- Spectator - Interface for users waiting to play ---------------------------

game
	var
		list/spectators = new()
	proc
		addSpectator(client/client)
			spectators.Add(new /game/spectator(client, gameId))
			///client.eye = party.mainCharacter.interface
			//
			/*spawn(1)
				var role = pick(CHARACTER_SOLDIER, CHARACTER_GOBLIN, CHARACTER_CLERIC)
				party.addPlayer(client, role)*/
game/spectator
	parent_type = /interface
	var
		gameId
	New(client/_client, _gameId)
		. = ..()
		gameId = _gameId
		viewPlayer()
	Login()
		. = ..()
		winset(client, null, "chatChannels.tabs=channelSystem,channelGame; chatChannels.current-tab=channelGame;")
	proc
		viewPlayer()
			var /game/G = system.getGame(gameId)
			var /rpg/int = G.party.mainCharacter.interface
			client.eye = int