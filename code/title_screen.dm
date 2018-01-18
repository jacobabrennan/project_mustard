

//-- Title Screen --------------------------------------------------------------
/*
	Handles Players between games
	Allows players to choose between save files or the map editor.
	Allows players to join other players' games.
	Wows players with audio/visual spectacle!
	Now in fresh mint!
*/
//------------------------------------------------------------------------------


//-- Menu System ---------------------------------------------------------------

titleScreen
	parent_type = /interface
	var
		titleScreen/menu/menu
	Login()
		. = ..()
		menu = client.menu.addComponent(/titleScreen/menu)
		menu.setup()
		menu.show()
		client.menu.focus(menu)
		winset(client, null, "chatChannels.tabs=channelSystem;")
	Logout()
		del menu
	commandDown(command)
		var/block = client.menu.commandDown(command)
		if(block) return
titleScreen/menu
	parent_type = /component
	icon = 'alpha_title.png'
	screen_loc = "1,1"
	var
		component/select/options
	setup()
		//chrome(rect(TILE_SIZE, TILE_SIZE, 14*TILE_SIZE, 14*TILE_SIZE))
		var /component/label/L = addComponent(/component/label)
		L.imprint("Version:&nbsp;[system.versionNumber]", textColor="#00f")
		L.positionScreen(0, 0)
		options = addComponent(/component/select)
		options.setup(68, 64, list(
			"New&nbsp;Game" = "new",
			//"Continue" = "continue",
			"Spectate" = "spectate",
			"Edit&nbsp;Map" = "map"
		))
		focus(options)
	control()
		return TRUE
	commandDown(command)
		if(..()) return
		. = TRUE
		if(command == PRIMARY)
			switch(options.select())
				if("new")
					var /game/newGame = system.newGame(client.ckey, SAVE_TEST)
					newGame.createNew()
					newGame.start()
					return
				if("continue")
					// Get list of saves
					var /list/playerSaves = flist("[FILE_PATH_GAMES]/[client.ckey]/")
					for(var/index = 1 to playerSaves.len) // Remove file extensions from region names
						var fileName = playerSaves[index]
						var fileExtIndex = findtext(fileName, ".")
						playerSaves[index] = copytext(fileName, 1, fileExtIndex)
					var saveName
					if(playerSaves.len)
						saveName = playerSaves[1]
					// Load Saved Game
					if(saveName)
						var /game/newGame = system.newGame(client.ckey, saveName)
						newGame.load()
						newGame.start()
						return
				if("spectate")
					if(!system.games.len) return
					var /game/newGame = system.games[system.games[1]]
					newGame.addSpectator(client)
					return
				if("map")
					new /interface/mapEditor(client)
					return