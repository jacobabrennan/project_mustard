

//------------------------------------------------------------------------------

party
	var
		gameId
	New(_gameId)
		. = ..()
		gameId = _gameId
	//------------------------------------------------
	var
		list/inventory[INVENTORY_MAX]
		character/partyMember/mainCharacter
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
			addPartyMember(new /character/partyMember/hero())
			addPartyMember(new /character/partyMember/cleric())
			var /character/partyMember/soldier/soldier = addPartyMember(new /character/partyMember/soldier())
			var /character/partyMember/goblin/goblin   = addPartyMember(new /character/partyMember/goblin())
			mainCharacter.equip(new /item/weapon/sword())
			mainCharacter.equip(new /item/shield())
			for(var/I = 1 to 24)
				mainCharacter.get(new /item/gear/plate())
			soldier.equip(      new /item/weapon/axe(  ))
			goblin.equip(       new /item/weapon/bow(  ))
		addPartyMember(character/partyMember/newMember)
			if(newMember.partyId == CHARACTER_KING || newMember.partyId == CHARACTER_HERO)
				mainCharacter = newMember
			characters.Add(newMember)
			newMember.party = src
			newMember.adjustHp(0)
			newMember.adjustMp(0)
			return newMember

character/partyMember
	toJSON()
		var/list/objectData = ..()
		objectData["name"] = name
		objectData["equipment"] = list2JSON(equipment)
		objectData["hotKeys"] = list2JSON(hotKeys)
		return objectData
	fromJSON(list/objectData)
		name = objectData["name"]
		for(var/item/equipItem in json2List(objectData["equipment"] || list()))
			equip(equipItem)
		hotKeys = json2List(objectData["hotKeys"])


//-- Player Tracker ------------------------------------------------------------

party
	var
		list/players = new()
		list/clientStorage = new()
	proc
		addPlayer(client/client, playerPosition)
			// Find the character to be controlled - this should always be possible
			var/character/partyMember/member
			for(var/character/partyMember/M in characters)
				if(M.partyId == playerPosition)
					member = M
					break
			ASSERT(member)
			// Remove previous player from control
			// Give new player control
			var /rpg/R = new(client, member)
			players[R] = playerPosition
			//
			return R
		respawn()
			for(var/character/partyMember/member in characters)
				member.revive()
				member.adjustHp(member.maxHp())
				member.adjustMp(member.maxMp())
				for(var/client/C in clientStorage)
					var role = clientStorage[C]
					if(member.partyId != role) continue
					new /rpg(C, member)
					break


//-- Inventory & Equipment------------------------------------------------------

	//-- Inventory Management ------------------------
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
			for(var/character/partyMember/char in characters)
				if(!char.interface) continue
				if(updateChar)
					if(char != mainCharacter && char != updateChar) continue
				var /rpg/int = char.interface
				if(istype(int))
					int.menu.refresh(key, updateChar)
		use(usable/_usable)
			_usable.use(src)

	//-- Character Equipment -------------------------
character/partyMember
	proc
		get(item/newItem)
			if(party)
				return party.get(newItem)
	equip(item/gear/newGear)
		var success = ..()
		if(!success) return
		// Remove Item from Party Inventory
		if(party)
			if(newGear in party.inventory)
				party.unget(newGear)
		// Refresh party interface
			party.refreshInterface("equipment", src)
			party.refreshInterface("hp", src)
			party.refreshInterface("mp", src)
		//
		return success
	unequip(item/gear/oldGear)
		var success = ..()
		if(!success) return
		// Add gear to party inventory
		if(party)
			get(oldGear)
		// Refresh party interface
			party.refreshInterface("inventory")
			party.refreshInterface("equipment", src)
			party.refreshInterface("hp", src)
			party.refreshInterface("mp", src)
		//
		return success

	//-- Hot Keys-------------------------------------
	var
		list/hotKeys[3]
	proc
		setHotKey(usable/_usable, hotKey)
			// Check if character can use it
			if(istype(_usable, /item/gear))
				if(!canEquip(_usable))
					return
			// Get list index from command
			var list/hotKeyIndex = list(SECONDARY, TERTIARY, QUATERNARY).Find(hotKey)
			if(!hotKeyIndex) return
			// Unequip any old /item in hot key
			var /item/oldHotKey = hotKeys[hotKeyIndex]
			if(istype(oldHotKey)) get(oldHotKey)
			// Set hot key to /usable (also works for clearing via null)
			hotKeys[hotKeyIndex] = _usable
			// Remove /usable from inventory
			party.unget(_usable)
			// Display results in hot keys
			party.refreshInterface("hotKeys", src)
		getHotKey(command)
			var/hkIndex
			switch(command)
				if(SECONDARY ) hkIndex = 1
				if(TERTIARY  ) hkIndex = 2
				if(QUATERNARY) hkIndex = 3
			return hotKeys[hkIndex]


//-- Game Over handling --------------------------------------------------------

party
	proc
		gameOver() // Mostly a hook for future possibilities
			clientStorage = list()
			// Cleanup
			for(var/character/partyMember/member in characters)
				// Lock Plots so game doesn't continue without players
				var/plot/P = plot(member)
				if(P)
					P.gameOverLock()
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
			var /game/G = system.getGame(gameId)
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
		for(var/character/partyMember/C in characters)
			C.forceLoc(startTile)
			C.transition(startPlot)

character/partyMember
	proc
		transition(plot/newPlot, turf/newTurf)
			if(newTurf)
				var/offsetX = (dir&( EAST|WEST ))? 0 : step_x
				var/offsetY = (dir&(NORTH|SOUTH))? 0 : step_y
				var/success = Move(newTurf, 0 , offsetX, offsetY)
				if(!success)
					forceLoc(newTurf)
			if(interface)
				interface.transition(newPlot)
			newPlot.activate(src)
		warp(warpId, regionId, gameId)
			// Find Current Game
			var /plot/currentPlot = plot(src)
			if(!gameId && currentPlot)
				gameId = currentPlot.gameId
			var /game/G = system.getGame(gameId)
			ASSERT(G)
			// Find Target Region
			if(!regionId && currentPlot) // Default target region to current region
				regionId = currentPlot.regionId
			var /region/targetRegion = G.getRegion(regionId)
			ASSERT(targetRegion)
			// Find Target Plot
			var /plot/targetPlot = targetRegion.getWarp(warpId)
			for(var/plot/P in targetRegion.plots.contents())
				if(P.warpId)
					diag(P.warpId, "found")
			ASSERT(targetPlot)
			// Reveal plot, if needbe
			targetPlot.reveal()
			// Find Target Tile
			var /tile/center = locate(
				round((targetRegion.mapOffset.x+targetPlot.x+1/2)*PLOT_SIZE),
				round((targetRegion.mapOffset.y+targetPlot.y+1/2)*PLOT_SIZE),
				targetRegion.z()
			)
			//
			transition(targetPlot, center)
character/partyMember
	transitionable = TRUE // Can move between plots
	var
		partyId
		party/party
		partyDistance = 16 // The number of tiles away from the player that this character will generally stay

	//-- Interface Control -------------------------//
	var
		rpg/interface
	control()
		. = ..()
		if(.) return
		if(interface)
			interface.control(src)
			return TRUE

	//-- Default Behavior --------------------------//
	behavior()
		// Check for blocking
		var block = ..()
		if(block) return block
		// Check if the player is fainted (dead) and it's our turn to rescue
		var rescue = FALSE
		if(party.mainCharacter.dead) rescue = shouldIRescue()
		// If rescue is needed
		if(rescue)
			var success = stepTo(party.mainCharacter, -1)
			if(!success)
				movement = MOVEMENT_ALL
				//density = FALSE
				success = stepTo(party.mainCharacter, -1)
			movement = initial(movement)
			//density  = initial(density )
		// Move toward player
		var success = stepTo(party.mainCharacter, partyDistance)
		if(!success && aloc(src) != aloc(party.mainCharacter))
			forceLoc(party.mainCharacter.loc)

	//-- Decisions ---------------------------------//
	proc
		tryToAttack()
		attackWithWeapon()
			var /usable/weapon = equipment[WEAR_WEAPON]
			if(weapon)
				weapon.use(src)
		//manDown(var/character/partyMember/member) // whenever a party member faints, everyone in the party is alerted
		shouldIRescue()
			if(!party.mainCharacter.dead) return FALSE
			var rescue = TRUE
			if(partyId == CHARACTER_GOBLIN)
				for(var/character/partyMember/M in party.characters)
					if(M.partyId == CHARACTER_CLERIC && !M.dead)
						rescue = FALSE
			else if(partyId == CHARACTER_SOLDIER)
				for(var/character/partyMember/M in party.characters)
					if(M != src && !M.dead)
						rescue = FALSE
			return rescue


//-- Type Defs - Factor Out Eventually -----------------------------------------

character/partyMember
	regressiaHero
		name = "Regressia"
		partyId = CHARACTER_KING
		equipFlags = EQUIP_ANY
		icon = 'regressia_hero.dmi'
		baseHp = 6
		baseMp = 4
	hero
		name = "Hero"
		partyId = CHARACTER_HERO
		equipFlags = EQUIP_ANY
		icon = 'hero.dmi'
		portrait = "Hero"
		baseHp = 6
		baseMp = 4
	cleric
		name = "Cleric"
		partyId = CHARACTER_CLERIC
		equipFlags = EQUIP_WAND|EQUIP_BOOK|EQUIP_ROBE
		icon = 'cleric.dmi'
		portrait = "Cleric"
		partyDistance = 12
		baseHp = 4
		baseMp = 3
		baseAuraRegain = 9
		behavior()
			if(mp < 1) return ..()
			// Heal
			var healed = FALSE
			for(var/character/partyMember in party.characters)
				if(bounds_dist(src, partyMember) < 32)
					if(partyMember.hp < partyMember.maxHp())
						healed = TRUE
						partyMember.adjustHp(1)
			if(healed)
				adjustMp(-1)
				return
			else
				return ..()
	soldier
		name = "Soldier"
		partyId = CHARACTER_SOLDIER
		equipFlags = EQUIP_AXE|EQUIP_SHIELD|EQUIP_ARMOR
		icon = 'soldier.dmi'
		portrait = "Soldier"
		partyDistance = 0
		baseHp = 10
		var
			combatant/target
		behavior()
			// Check if rescue is needed
			if(party.mainCharacter.dead && shouldIRescue())	return ..()
			if(tryToAttack()) return TRUE
			// If we didn't advance on a target, seek out the player
			. = ..()
		tryToAttack()
			// Check if we have a axe equipped
			var /item/weapon/axe/axe = equipment[WEAR_WEAPON]
			if(!istype(axe)) return
			// Check which threat is the closest
			var closeDist = 49
			var closeEnemy
			for(var/combatant/E in range(4, src))
				if(!hostile(E)) continue
				var testDist = bounds_dist(src, E)
				//if(testDist >= TILE_SIZE && bounds_dist(party.mainCharacter, E) > 80) continue
				if(testDist >= closeDist) continue
				closeEnemy = E
				closeDist = testDist
			// Attack enemies that are within hitting range
			if(closeDist < TILE_SIZE-4) // Account for diagonal axes
				target = closeEnemy
				dir = get_dir(src, target)
				attackWithWeapon()
				return TRUE
			// If we have health, find and attack a target
			if(hp > 0) // Change from zero to make her shy when wounded
				// If current target is too far away, forget about it
				if(target && bounds_dist(party.mainCharacter, target) > 80)
					target = null
				// If we don't have a target, target the closest combatant
				if(!target && bounds_dist(party.mainCharacter, closeEnemy) <= 80)
					target = closeEnemy
				// If we have a target, advance towards it
				if(target)
					stepTo(target)
					return TRUE
	goblin
		name = "Goblin"
		partyId = CHARACTER_GOBLIN
		equipFlags = EQUIP_BOW
		icon = 'goblin.dmi'
		portrait = "Goblin"
		partyDistance = 24
		//baseSpeed = 4
		roughWalk = 16
		baseHp = 6
		var
			combatant/target
		behavior()
			if(shouldIRescue()) return ..()
			if(tryToAttack()) return TRUE
			. = ..()
		tryToAttack()
			// Check if we have a bow equipped
			var /item/weapon/bow/bow = equipment[WEAR_WEAPON]
			if(!istype(bow)) return
			if(!bow.ready()) return
			// If there's a target, check if it's still aligned to attack
			var alignMax = 32
			var /plot/plotArea/A = aloc(src)
			var /list/deltasX = new()
			var /list/deltasY = new()
			var toFar
			if(bounds_dist(src, party.mainCharacter) > 112) toFar = TRUE
			if(target)
				var deltaX = ((target.x-A.x)*TILE_SIZE + target.bound_width /2 + target.step_x) - ((x-A.x)*TILE_SIZE + bound_width /2 + step_x)
				var deltaY = ((target.y-A.y)*TILE_SIZE + target.bound_height/2 + target.step_y) - ((y-A.y)*TILE_SIZE + bound_height/2 + step_y)
				if(target.dead || min(abs(deltaX), abs(deltaY)) > alignMax || toFar)
					target = null
			// Check for targets of opportunity. Shoot the one that can be hit the fastest with an arrow
			var fastestDir
			var /combatant/fastestHit
			var /combatant/fastestTime = 1000
			for(var/combatant/E in A)
				if(!hostile(E)) continue
				var deltaX = ((E.x-A.x)*TILE_SIZE + E.bound_width /2 + E.step_x) - ((x-A.x)*TILE_SIZE + bound_width /2 + step_x)
				var deltaY = ((E.y-A.y)*TILE_SIZE + E.bound_height/2 + E.step_y) - ((y-A.y)*TILE_SIZE + bound_height/2 + step_y)
				deltasX[E] = deltaX
				deltasY[E] = deltaY
				if(min(abs(deltaX), abs(deltaY)) > bow.arrowRange) continue
				var directX
				var directY
				var closingX
				var closingY
				//if((abs(deltaY) < TILE_SIZE/2) && !(E.dir&(NORTH|SOUTH))) directX = TRUE
				//if((abs(deltaX) < TILE_SIZE/2) && !(E.dir&(EAST | WEST))) directY = TRUE // Doesn't target stationary targets
				if(abs(deltaY) < TILE_SIZE/2) directX = TRUE
				if(abs(deltaX) < TILE_SIZE/2) directY = TRUE
				if     (deltaX > 0 && (E.dir&WEST )) closingX = TRUE
				else if(deltaX < 0 && (E.dir&EAST )) closingX = TRUE
				if     (deltaY > 0 && (E.dir&SOUTH)) closingY = TRUE
				else if(deltaY < 0 && (E.dir&NORTH)) closingY = TRUE
				if(!(closingX || closingY || directX || directY)) continue // Enemy is not crossing over cardinal direction
				var testTime = fastestTime+1
				var testDir
				if(closingX || directY) // Attack Vertically
					if(abs(deltaY) > bow.arrowRange) continue
					var deltaT = abs(deltaX / E.speed())
					var arrowT = abs(deltaY / bow.arrowSpeed)
					if(directY || abs(deltaT - arrowT) <= 4)
						testTime = deltaT
						testDir = (deltaY > 0)? NORTH : SOUTH
				if(closingY || directX) // Attack Horizontally
					if(abs(deltaX) > bow.arrowRange) continue
					var deltaT = abs(deltaY / E.speed())
					var arrowT = abs(deltaX / bow.arrowSpeed)
					if((deltaT < testTime) && (directX || abs(deltaT - arrowT) <= 5))
						testTime = deltaT
						testDir = (deltaX > 0)? EAST  : WEST
				if(testTime < fastestTime)
					fastestTime = testTime
					fastestHit = E
					fastestDir = testDir
			if(fastestHit)
				dir = fastestDir
				attackWithWeapon()
				target = null
				return TRUE
			// If we can't shoot anything (and there's no target), try to target the combatant that requires the least movement to align with
			if(!target && !toFar)
				var closestAlignTarget
				var closestAlignDist = alignMax
				for(var/combatant/E in A)
					if(!hostile(E)) continue
					var deltaX = abs(deltasX[E])
					var deltaY = abs(deltasY[E])
					var minDelta = min(deltaX, deltaY)
					if(minDelta < closestAlignDist)
						closestAlignTarget = E
						closestAlignDist = minDelta
				if(closestAlignTarget)
					target = closestAlignTarget
			// If we have a target, move towards it and shoot it
			if(target)
				if(bounds_dist(src, target) < TILE_SIZE*2)
					target = null
					return FALSE
				else
					//if(step_to(owner, target, 2, owner.speed())) return TRUE // see stepTo()
					var axisHorizontal = (abs(deltasX[target]) <= abs(deltasY[target]))? TRUE : FALSE
					var success
					if(axisHorizontal)
						if(deltasX[target] > 0) success = go(speed(), 0)
						else success = go(-speed(), 0)
					else
						if(deltasY[target] > 0) success = go(0, speed())
						else success = go(0, -speed())
					return success
			//  Otherwise, walk toward the player
			return FALSE


//-- Character Fainting & Revive Assist ----------------------------------------

character/partyMember
	die()
		if(dead) return
		dead = TRUE
		density = FALSE
		// Remove HP / MP overlays
		overlays.Remove(meterHp)
		overlays.Remove(meterMp)
		// Add faint controller
		var /sequence/fainted/faint = new()
		faint.init(src)
		// Alert Party Memebers
		/*for(var/character/partyMember/member in party.characters)
			if(member == src) continue
			member.manDown(src)*/
		// Hide HUD
		if(interface && interface.client)
			interface.menu.hide()
		// Check if the entire party is down (Game Over)
		var gameOver = TRUE
		for(var/character/partyMember/member in party.characters)
			if(!member.dead) gameOver = FALSE
		if(gameOver)
			party.gameOver()
	proc/revive()
		if(!dead) return
		dead = FALSE
		density = initial(density)
		icon_state = null
		// Make Invulnerable temporarily
		invincible(TIME_HURT)
		// Rearrange HP / MP / Faiting overlays
		adjustHp(1)
		adjustMp(0)
		overlays.Remove(system._faintOverlay)
		// Show HUD
		if(interface && interface.client)
			interface.client.menu.focus(interface.menu)

sequence/fainted
	var
		faintTime = 40 // The time before the character can be revived
	init(character/partyMember/char)
		char.icon_state = "down"
		flick("faint", char)
		char.overlays.Add(system._faintOverlay)
		. = ..()
	control(character/partyMember/char)
		if(faintTime-- < 0)
			if(faintTime == -1)
				char.overlays.Remove(system._faintOverlay)
			for(var/character/partyMember/mem in char.party.characters)
				if(!mem.dead && bounds_dist(char, mem) <= 1)
					char.revive()
					. = TRUE
					del src
		return TRUE


//-- Health & Magic Bars -------------------------------------------------------

system
	var
		list/_metersHp = new(TILE_SIZE)
		list/_metersMp = new(TILE_SIZE)
		mutable_appearance/_faintOverlay
	New()
		. = ..()
		var /obj/temp = new()
		// Prepare faint overlay
		var /image/faint = image('_wrapper.dmi', null, "faint", FLY_LAYER)
		faint.pixel_y += TILE_SIZE
		temp.overlays.Add(faint)
		for(var/appearance in temp.overlays)
			_faintOverlay = appearance
		del temp
		// Prepare HP meter overlays
		for(var/I = 1 to TILE_SIZE)
			temp = new()
			var /image/protoAppearance = image('meters.dmi', null, "hp_[I]", FLY_LAYER)
			protoAppearance.pixel_y = TILE_SIZE+1
			temp.overlays.Add(protoAppearance)
			for(var/appearance in temp.overlays)
				_metersHp[I] = appearance
			del temp
		// Prepare MP meter overlays
		for(var/I = 1 to TILE_SIZE)
			temp = new()
			var /image/protoAppearance = image('meters.dmi', null, "mp_[I]", FLY_LAYER)
			protoAppearance.pixel_y = TILE_SIZE+3
			temp.overlays.Add(protoAppearance)
			for(var/appearance in temp.overlays)
				_metersMp[I] = appearance
			del temp

character/partyMember
	var
		mutable_appearance/meterHp
		mutable_appearance/meterMp
	adjustHp(amount)
		. = ..()
		overlays.Remove(meterHp)
		if(dead) return
		var meterIndex = round((hp/maxHp())*TILE_SIZE)
		meterIndex = max(1, min(TILE_SIZE, meterIndex))
		meterHp = system._metersHp[meterIndex]
		overlays.Add(meterHp)
		if(interface) interface.menu.refresh("hp")
	adjustMp(amount)
		. = ..()
		overlays.Remove(meterMp)
		if(dead) return
		var max = maxMp()
		if(max <= 0) return
		var meterIndex = round((mp/max)*TILE_SIZE)
		meterIndex = max(1, min(TILE_SIZE, meterIndex))
		meterMp = system._metersMp[meterIndex]
		overlays.Add(meterMp)
		if(interface) interface.menu.refresh("mp")
