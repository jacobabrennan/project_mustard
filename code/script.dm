

//-- Script - Scripted Events --------------------------------------------------

script
	var
		gameId
	New(_gameId)
		. = ..()
		gameId = _gameId

script/newGame
	New(_gameId, client/newPlayer)
		. = ..()
		var /game/G = system.getGame(gameId)
		G.party = new(gameId)
		G.party.createNew()
		G.quest = new()
		//
		G.party.addPlayer(newPlayer, CHARACTER_HERO)
		G.party.changeRegion(REGION_OVERWORLD)
		//
		new /script/alphaTest(gameId)

script/alphaTest
	New(_gameId)
		. = ..()
		var /game/G = system.getGame(gameId)
		var /character/mainChar = G.party.mainCharacter
		var /rpg/int = mainChar.interface
		//
		var /component/dialogue/D = int.menu.addComponent(/component/dialogue)
		D.setup("alpha", "Welcome to Alpha Test 2. #p Here is another longer statement to make this dialogue component break into several segments. Kupo!")
		D.show()
		int.menu.focus(D)