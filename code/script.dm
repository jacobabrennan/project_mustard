

//-- Script - Scripted Events --------------------------------------------------

script
	var
		gameId
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
	var
		component/dialogue/dialogue
	New(_gameId)
		. = ..()
		var /game/G = system.getGame(gameId)
		//
		/*var /component/dialogue/D = int.menu.addComponent(/component/dialogue)
		D.setup("alpha", "Welcome to Alpha Test 2. #p Here is another longer statement to make this dialogue component break into several segments. Kupo!")
		D.show()
		int.menu.focus(D)*/
		dialogue = G.party.menu.addComponent(/component/dialogue)
		dialogue.setup("Hero", "Here here! Here here! Here here! Here here! Here here! Here here! Here here! Here here! Here here! Here here! Here here! Here here!", TRUE, src)
		dialogue.show()
		G.party.menu.focus(dialogue)
		//G.party.mainCharacter.interface.client.menu.focus(G.party.menu)
	commandDown(command, combatant/controllee)
		. = TRUE
		var /game/G = system.getGame(gameId)
		switch(command)
			if(MENU_READY)
				diag("del")
				del dialogue
				del src
			else
				if(controllee != G.party.mainCharacter) return
				dialogue.commandDown(command)