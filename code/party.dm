

//------------------------------------------------------------------------------

party
	var
		gameId
	New(_gameId)
		. = ..()
		gameId = _gameId
	//-------------------------
	var
		character/mainCharacter
		list/characters = new()


//-- Saving / Loading --------------------------------------------//

party
	/*proc
		load()
			var/filePath = FILE_PATH_PARTIES+"/party.json"
			if(fexists(filePath))
				var/list/saveData = json_decode(file2text(filePath))
				// TODO: check for compatible version
				fromJSON(saveData)
		save()
			var/filePath = FILE_PATH_PARTIES+"/party.json"
			replaceFile(filePath, json_encode(toJSON()))*/
	toJSON()
		var/list/dataObject = ..()
		dataObject["characters"] = list2JSON(characters)
		return dataObject
	fromJSON(list/dataObject)
		characters = new()
		for(var/list/characterData in dataObject["characters"])
			characters.Add(json2Object(characterData))
		mainCharacter = characters[1]
		return
	proc
		createNew()
			addPartyMember(new /character/partyMember/hero())
			addPartyMember(new /character/partyMember/cleric())
			var /character/partyMember/soldier/soldier = addPartyMember(new /character/partyMember/soldier())
			var /character/partyMember/goblin/goblin   = addPartyMember(new /character/partyMember/goblin())
			mainCharacter.equip(new /item/weapon/sword())
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


//-- Player Tracker ----------------------------------------------//

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
			var /interface/rpg/R = new(client, member)
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
					new /interface/rpg(C, member)
					break


//-- Game Over handling ------------------------------------------//

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
					var /interface/rpg/oldInterface = member.interface
					var /interface/holding/holding = new()
					holding.forceLoc(oldInterface.loc)
					holding.client = oldInterface.client
					del oldInterface
				new /event/puff(member)
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


//-- Movement and Behavior ---------------------------------------//


party
	proc/changeRegion(region/newRegion, plot/newPlot)
		// Find the Start Plot
		if(!newPlot)
			newPlot = newRegion.getPlot(newRegion.startPlotCoords.x, newRegion.startPlotCoords.y)
		// Find the Start Tile (currently the center) of that Plot
		var /coord/startCoords = new( // Center
			round((newPlot.x-0.5)*PLOT_SIZE)+1,
			round((newPlot.y-0.5)*PLOT_SIZE)+1
		)
		var /tile/startTile = locate(startCoords.x, startCoords.y, newRegion.z())
		// Move each character in the party to the Start Tile
		for(var/character/C in characters)
			C.forceLoc(startTile)
			C.transition(newPlot)

atom/movable/Cross()
	return TRUE
character/partyMember
	transitionable = TRUE // Can move between plots
	var
		partyId
		party/party
		partyDistance = 1 // The number of tiles away from the player that this character will generally stay
	behavior()
		// Check for blocking
		var block = ..()
		if(block) return block
		// Check if the player is fainted (dead) and it's our turn to rescue
		var rescue = FALSE
		if(party.mainCharacter.dead) rescue = shouldIRescue()
		// If rescue is needed
		if(rescue)
			var success = step_to(src, party.mainCharacter, 0, speed())
			if(!success)
				movement = MOVEMENT_ALL
				density = FALSE
				success = step_to(src, party.mainCharacter, 0, speed())
			movement = initial(movement)
			density  = initial(density )
		// Move toward player
		var success = step_to(src, party.mainCharacter, partyDistance, speed())
		if(!success && aloc(src) != aloc(party.mainCharacter))
			forceLoc(party.mainCharacter.loc)
	proc
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
						rescue = TRUE
			return rescue


	//
	regressiaHero
		icon = 'regressia_hero.dmi'
		partyId = CHARACTER_KING
		baseHp = 6
		baseMp = 4
	hero
		icon = 'hero.dmi'
		partyId = CHARACTER_HERO
		baseHp = 6
		baseMp = 4
	cleric
		icon = 'cleric.dmi'
		partyId = CHARACTER_CLERIC
		partyDistance = 0
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
		icon = 'soldier.dmi'
		partyId = CHARACTER_SOLDIER
		partyDistance = 1
		baseHp = 10
		var
			enemy/target
		behavior()
			// Check if rescue is needed
			if(party.mainCharacter.dead && shouldIRescue())
				return ..()
			// Check which threat is the closest
			var closeDist = 49
			var closeEnemy
			for(var/combatant/E in range(4, src))
				if(E.faction & faction) continue
				if(E.dead) continue
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
				return
			// If we have health, find and attack a target
			if(hp > 2)
				// If current target is too far away, forget about it
				if(target && bounds_dist(party.mainCharacter, target) > 80)
					target = null
				// If we don't have a target, target the closest enemy
				if(!target && bounds_dist(party.mainCharacter, closeEnemy) <= 80)
					target = closeEnemy
				// If we have a target, advance towards it
				if(target)
					step_to(src, target, 0, speed())
					return
			// If we didn't advance on a target, seek out the player
			. = ..()
	goblin
		icon = 'goblin.dmi'
		partyId = CHARACTER_GOBLIN
		partyDistance = 0
		//baseSpeed =
		roughWalk = 4
		baseHp = 6
		behaviorName = "archer"


//-- Combatant Behaviors (needs refactor out) --------------------//

behaviors
	var
		storage
		combatant/target
	proc
		archer2(combatant/owner)
			var /item/weapon/bow/bow = owner:equipment[WEAR_WEAPON]
			if(!istype(bow)) return
			if(!bow.ready()) return
			var /plot/plotArea/A = aloc(owner)
			var fastestDir
			var /combatant/fastestHit
			var /combatant/fastestTime = 1000
			var /list/deltasX = new()
			var /list/deltasY = new()
			var alignMax = 96
			// If there's a target, check if it's still aligned to attack
			if(target)
				var deltaX = ((target.x-A.x)*TILE_SIZE + target.bound_width /2 + target.step_x) - ((owner.x-A.x)*TILE_SIZE + owner.bound_width /2 + owner.step_x)
				var deltaY = ((target.y-A.y)*TILE_SIZE + target.bound_height/2 + target.step_y) - ((owner.y-A.y)*TILE_SIZE + owner.bound_height/2 + owner.step_y)
				if(target.dead || min(abs(deltaX), abs(deltaY)) > alignMax)
					target = null
			// Check for targets of opportunity. Shoot the one that can be hit the fastest with an arrow
			for(var/combatant/E in A)
				if(E.dead) continue
				if(E.faction & owner.faction) continue
				var deltaX = ((E.x-A.x)*TILE_SIZE + E.bound_width /2 + E.step_x) - ((owner.x-A.x)*TILE_SIZE + owner.bound_width /2 + owner.step_x)
				var deltaY = ((E.y-A.y)*TILE_SIZE + E.bound_height/2 + E.step_y) - ((owner.y-A.y)*TILE_SIZE + owner.bound_height/2 + owner.step_y)
				deltasX[E] = deltaX
				deltasY[E] = deltaY
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
				owner.dir = fastestDir
				owner.shoot()
				target = null
				return TRUE
			// If we can't shoot anything (and there's no target), try to target the enemy that requires the least movement to align with
			if(!target)
				var closestAlignTarget
				var closestAlignDist = alignMax
				for(var/combatant/E in A)
					if(E.dead) continue
					if(E.faction & owner.faction) continue
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
				if(bounds_dist(owner, target) < TILE_SIZE*2)
					target = null
					if(step_away(owner, target)) return TRUE
				else
					//if(step_to(owner, target, 2, owner.speed())) return TRUE
					var axisHorizontal = (abs(deltasX[target]) <= abs(deltasY[target]))? TRUE : FALSE
					if(axisHorizontal)
						if(deltasX[target] > 0)
							owner.go(owner.speed(), 0)
						else
							owner.go(-owner.speed(), 0)
					else
						if(deltasY[target] > 0)
							owner.go(0, owner.speed())
						else
							owner.go(0, -owner.speed())
					return FALSE
			//  Otherwise, walk toward the player
			return FALSE
		archer(combatant/owner)
			ASSERT(!owner.dead)
			// Check if rescue is needed
			if(owner:party.mainCharacter.dead && owner:shouldIRescue())
				return ..()
			var /item/weapon/bow/bow = owner:equipment[WEAR_WEAPON]
			if(!istype(bow)) return
			if(!bow.ready()) return
			var /plot/plotArea/A = aloc(owner)
			var fastestDir
			var /enemy/fastestHit
			var /enemy/fastestTime = 1000
			var /list/deltasX = new()
			var /list/deltasY = new()
			var alignMax = 32
			var toFar
			if(bounds_dist(owner, owner:party.mainCharacter) > 112) toFar = TRUE
			// If there's a target, check if it's still aligned to attack
			if(target)
				var deltaX = ((target.x-A.x)*TILE_SIZE + target.bound_width /2 + target.step_x) - ((owner.x-A.x)*TILE_SIZE + owner.bound_width /2 + owner.step_x)
				var deltaY = ((target.y-A.y)*TILE_SIZE + target.bound_height/2 + target.step_y) - ((owner.y-A.y)*TILE_SIZE + owner.bound_height/2 + owner.step_y)
				if(target.dead || min(abs(deltaX), abs(deltaY)) > alignMax || toFar)
					target = null
			// Check for targets of opportunity. Shoot the one that can be hit the fastest with an arrow
			for(var/combatant/E in A)
				if(E.dead) continue
				if(E.faction & owner.faction) continue
				var deltaX = ((E.x-A.x)*TILE_SIZE + E.bound_width /2 + E.step_x) - ((owner.x-A.x)*TILE_SIZE + owner.bound_width /2 + owner.step_x)
				var deltaY = ((E.y-A.y)*TILE_SIZE + E.bound_height/2 + E.step_y) - ((owner.y-A.y)*TILE_SIZE + owner.bound_height/2 + owner.step_y)
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
				owner.dir = fastestDir
				owner:attackWithWeapon()
				target = null
				return TRUE
			// If we can't shoot anything (and there's no target), try to target the enemy that requires the least movement to align with
			if(!target && !toFar)
				var closestAlignTarget
				var closestAlignDist = alignMax
				for(var/combatant/E in A)
					if(E.dead) continue
					if(E.faction & owner.faction) continue
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
				if(bounds_dist(owner, target) < TILE_SIZE*2)
					target = null
					return FALSE
				else
					//if(step_to(owner, target, 2, owner.speed())) return TRUE
					var axisHorizontal = (abs(deltasX[target]) <= abs(deltasY[target]))? TRUE : FALSE
					var success
					if(axisHorizontal)
						if(deltasX[target] > 0)
							success = owner.go(owner.speed(), 0)
						else
							success = owner.go(-owner.speed(), 0)
					else
						if(deltasY[target] > 0)
							success = owner.go(0, owner.speed())
						else
							success = owner.go(0, -owner.speed())
					return success
			//  Otherwise, walk toward the player
			return FALSE


//-- Character Fainting & Revive Assist --------------------------//

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
			interface.client.menu.hud.hide()
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
		// Rearrange HP / MP / Faiting overlays
		adjustHp(1)
		adjustMp(0)
		overlays.Remove(system._faintOverlay)
		// Show HUD
		if(interface && interface.client)
			interface.client.menu.hud.show()
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


//-- Health & Magic Bars -----------------------------------------//

system
	var
		list/_metersHp = new(TILE_SIZE)
		list/_metersMp = new(TILE_SIZE)
		mutable_appearance/_faintOverlay
	New()
		. = ..()
		var /obj/temp = new()
		// Prepare faint overlay
		var /image/faint = image('specials.dmi', null, "faint", FLY_LAYER)
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