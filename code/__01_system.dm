

//------------------------------------------------------------------------------

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
	//
	New()
		. = ..()
		system = src
		loadVersion()
		spawn(10)
			startProject()
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

	//
	proc
		loadHub()
			world.version = versionHub
			world.name = gameName
			world.hub = gameHub
			world.hub_password = passwordHub
	//
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
			#warn Don't forget about me
			// Shrink Maxz if possible
		getGame(gameId) // Called by any part of the game to get the game from a gameId
			return games[gameId]
		newGame(_playerId, _saveId)
			var /game/newGame = new(_playerId, _saveId)
			registerGame(newGame)
			return newGame
		loadGame(saveId)
			game = new()
			world << game.load(saveId)
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
		//
		startProject()
			diag("<b>----- System Starting -----</b>")
			loadHub()
			loadUtilities()
			_ready = TRUE
			diag("<b>----- System Ready -----</b>")
			for(var/client/C in _waitingClients)
				registerPlayer(C)
		restartWithoutSave()
			diag("<b>---- System Restarting ----</b>")
			world << "-------------------------------------------------------------------------------------------------"
			world.Reboot()
		restart()
			//environment.deactivate()
			//saveGame()
			restartWithoutSave()
		stop()
			//environment.deactivate()
			//saveGame()
			stopWithoutSave()
		stopWithoutSave()
			diag("<b>----- System Stopping -----</b>")
			del world
		//
		loadUtilities()
			setupTerrains()

	//-- Player Handling -------------------//
	proc
		registerPlayer(client/client) // Called by /interface/clay/New()
			if(!_ready)
				_waitingClients.Add(client)
				return
			// Check games in progress for disconnected player.
				// Already done. Clay is never created if there's already another interface waiting
			// Check for saved games
			// Start a new game

			//Temp code

			// Direct Players to Edit Map
			#ifdef EDIT_MAP
			new /interface/mapEditor(client)
			return

			#else
			// Direct Players to Play Game
			var/game/newGame
				//Check if a game is in progress, add as spectator
			if(games.len)
				newGame = games[games[1]]
				newGame.addSpectator(client)
				return
			newGame = newGame(client.ckey, "test")
			newGame.createNew()
			newGame.start()
			#endif