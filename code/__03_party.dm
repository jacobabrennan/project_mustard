

//-- Party ---------------------------------------------------------------------

party
	var
		gameId
		faction
	New(_gameId)
		. = ..()
		gameId = _gameId
	//------------------------------------------------
	var
		list/inventory[INVENTORY_MAX]
		character/mainCharacter
		list/characters = new()


//-- Saving / Loading ----------------------------------------------------------

party
	toJSON()
		var/list/objectData = ..()
		objectData["characters"] = list2JSON(characters)
		objectData["inventory"] = list2JSON(inventory)
		return objectData
	fromJSON(list/objectData)
		. = ..()
		characters = new()
		for(var/item/inventoryItem in json2List(objectData["inventory"] || list()))
			get(inventoryItem)
		for(var/list/characterData in objectData["characters"])
			addPartyMember(json2Object(characterData))
		return
	proc
		createNew()
			addPartyMember(new /character/hero())
			addPartyMember(new /character/cleric())
			var /character/soldier/soldier = addPartyMember(new /character/soldier())
			var /character/goblin/goblin   = addPartyMember(new /character/goblin())
			mainCharacter.equip(new /item/sword())
			mainCharacter.equip(new /item/shield())
			for(var/I = 1 to 24)
				mainCharacter.get(new /item/plate(   ))
			soldier.equip(      new /item/axe())
			goblin.equip(       new /item/bow())
			get(new /item/bookHealing1)
		addPartyMember(character/newMember)
			if(!mainCharacter)
			//if(newMember.partyId == CHARACTER_KING || newMember.partyId == CHARACTER_HERO)
				mainCharacter = newMember
				faction = mainCharacter.faction
			characters.Add(newMember)
			newMember.party = src
			newMember.adjustHp(0)
			newMember.adjustMp(0)
			newMember.transitionable = TRUE
			newMember.faction = faction
			return newMember


//-- Player Tracker ------------------------------------------------------------

party
	var
		list/players = new()
		list/clientStorage = new()
	proc
		addPlayer(client/client, playerPosition)
			// Find the character to be controlled - this should always be possible
			var/character/member = playerPosition
			if(!istype(member))
				for(var/character/M in characters)
					if(M.partyId == playerPosition)
						member = M
						break
			else
				playerPosition = member.partyId
			ASSERT(member)
			// Remove previous player from control
			// Give new player control
			var /rpg/R = new(client, member)
			players[R] = playerPosition
			//
			return R
		respawn()
			for(var/character/member in characters)
				member.revive()
				member.adjustHp(member.maxHp())
				member.adjustMp(member.maxMp())
				for(var/client/C in clientStorage)
					var role = clientStorage[C]
					if(member.partyId != role) continue
					new /rpg(C, member)
					break


//-- Inventory Management ------------------------------------------------------

party
	proc
		get(item/newItem)
			if(!istype(newItem)) return FALSE
			if(newItem in inventory) return FALSE
			var placed = FALSE
			for(var/I = 1 to inventory.len)
				if(!inventory[I])
					inventory.Cut(I, I+1)
					inventory.Insert(1, newItem)
					placed = TRUE
					break;
			if(placed)
				newItem.forceLoc(null)
				refreshInterface("inventory")
				return newItem
		unget(item/newItem)
			inventory.Remove(newItem)
			inventory.len = INVENTORY_MAX
			refreshInterface("inventory")
		refreshInterface(key, character/updateChar)
			for(var/character/char in characters)
				if(!char.interface) continue
				if(updateChar)
					if(char != mainCharacter && char != updateChar) continue
				var /rpg/int = char.interface
				if(istype(int))
					int.menu.refresh(key, updateChar)
		use(usable/_usable)
			_usable.use(src)


//-- Game Over handling --------------------------------------------------------

party
	proc
		gameOver() // Mostly a hook for future possibilities
			// Cleanup non-main parties (enemy parties)
			var /game/G = system.getGame(gameId)
			if(G.party != src)
				for(var/character/member in characters)
					del member
				del src
				return
			// Cleanup
			clientStorage = list()
			for(var/character/member in characters)
				// Lock Plots so game doesn't continue without players
				var/plot/P = plot(member)
				if(P)
					P.gameOverLock()
				// Remove controllers from characters (if any)
				for(var/C in member.controllers)
					del C
				// Remove characters and place players into holding
				if(member.interface && member.interface.client)
					// Fade client to grayscale
					var/N = 1/3
					var/V = -1/6
					var colorList = list(N,N,N, N,N,N, N,N,N, V,V,V)
					animate(member.interface.client, color = colorList, 20)
					clientStorage[member.interface.client] = member.partyId
					//
					var /rpg/oldInterface = member.interface
					var /interface/holding/holding = new()
					holding.forceLoc(oldInterface.loc)
					holding.client = oldInterface.client
					del oldInterface
				new /effect/puff(member)
				member.forceLoc(null)
			// Notify Game object
			spawn(60)
				for(var/client/C in clientStorage)
					C.color = null
					C.mob.loc = null
				G.gameOver()

plot
	var/_gameOverLock = FALSE
	proc
		gameOverLock()
			_gameOverLock = TRUE
		gameOverCleanUp()
			_gameOverLock = FALSE
			deactivate()
	deactivate()
		if(_gameOverLock) return
		. = ..()
	takeTurn()
		if(_gameOverLock) return
		. = ..()


//-- Movement ------------------------------------------------------------------

party
	proc/changeRegion(regionId, warpId)
		// Find the Start Plot
		var /game/G = game(src)
		var /region/R = G.getRegion(regionId)
		if(!warpId) warpId = WARP_START
		var /plot/startPlot = R.getWarp(warpId)
		if(!startPlot)
			startPlot = R.getPlot(0, 0)
		ASSERT(startPlot)
		startPlot.reveal()
		// Find the Start Tile (currently the center) of that Plot
		var /coord/startCoords = new( // Center
			round((startPlot.x+R.mapOffset.x+0.5)*PLOT_SIZE)+1,
			round((startPlot.y+R.mapOffset.y+0.5)*PLOT_SIZE)+1
		)
		var /tile/startTile = locate(startCoords.x, startCoords.y, R.z())
		// Move each character in the party to the Start Tile
		for(var/character/C in characters)
			C.forceLoc(startTile)
			C.transition(startPlot)