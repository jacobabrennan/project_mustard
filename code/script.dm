

//-- Script - Scripted Events --------------------------------------------------

script
	var
		gameId
		stage = 0
	New(_gameId)
		gameId = _gameId
		var /game/G = game(gameId)
		for(var/character/member in G.party.characters)
			member.addController(src)
	proc
		control(character/controlChar)
			return TRUE
		commandDown(command)
			return TRUE
	//
	var
		component/dialogue/dialogue
		component/dialogue/response
	Del()
		del dialogue
		del response
		. = ..()
	proc
		dialogue(portrait, message)
			del dialogue
			var /game/G = game(gameId)
			dialogue = G.party.menu.addComponent(/component/dialogue)
			dialogue.setup(portrait, message, null, src)
			dialogue.show()
			G.party.menu.focus(dialogue)
		response(portrait, message)
			del response
			var /game/G = game(gameId)
			response = G.party.menu.addComponent(/component/dialogue)
			response.setup(portrait, message, TRUE, src)
			response.show()
			G.party.menu.focus(response)

script/newGame
	New(_gameId, client/newPlayer)
		gameId = _gameId
		var /game/G = system.getGame(gameId)
		G.party = new(gameId)
		G.party.createNew()
		G.quest = new()
		//
		G.party.addPlayer(newPlayer, CHARACTER_HERO)
		G.party.changeRegion(REGION_OVERWORLD)
		//
		. = ..()
		//
		new /script/alphaTest(gameId)
		spawn()
			del src

script/alphaTest
	New(_gameId)
		. = ..()
		dialogue("Magi", "Here here!")
	commandDown(command, combatant/controllee)
		. = TRUE
		var /game/G = system.getGame(gameId)
		switch(command)
			if(MENU_READY)
				if(!response)
					response("Hero", "Ok! #p Outta here.")
				else
					del dialogue
					del response
					del src
			else
				if(controllee != G.party.mainCharacter) return
				G.party.menu.commandDown(command)

script/addGoblin
	New(_gameId, plot/P)
		set waitfor = FALSE
		var /game/G = game(_gameId)
		if(G.quest.get("goblin"))
			return
		spawn(20)
			. = ..()
			G.quest.put("goblin", TRUE)
			dialogue("Goblin", "Can I come along?")
			var /furniture/scriptedEvent/S = locate() in P.area
			var /character/goblin/goblin = G.party.addPartyMember(new /character/goblin())
			goblin.equip( new /item/bow1())
			goblin.equip( new /item/quiver1())
			goblin.centerLoc(S)
	commandDown(command, combatant/controllee)
		. = TRUE
		var /game/G = system.getGame(gameId)
		switch(command)
			if(MENU_READY)
				switch(stage)
					if(0)
						response("Soldier", "No. #p Definitly Not.")
						stage++
					if(1)
						response("Hero", "Of Course.")
						stage++
					if(2)
						del src
			else
				if(controllee != G.party.mainCharacter) return
				G.party.menu.commandDown(command)