

//-- Character Type Definitions ------------------------------------------------

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
			// Heal
			var healed = attemptToHeal()
			//
			if(!healed)
				return ..()
		proc/attemptToHeal()
			// Check if we can heal
			var /spell/heal/healSpell = hotKeys[1]
			if(!istype(healSpell)) return
			if(mp < healSpell.mpCost) return
			// Check if everyone has max hp
			var heal
			var radius = healSpell.range - (bound_width/2)
			for(var/character/partyMember in party.characters)
				if(bounds_dist(src, partyMember) < radius)
					if(partyMember.hp < partyMember.maxHp())
						heal = TRUE
						break
			if(heal)
			// Use heal spell
				healSpell.use(src)
			// Otherwise, just return FALSE
			return
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
			var /item/axe/axe = equipment[WEAR_WEAPON]
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
			var /item/bow/bow = equipment[WEAR_WEAPON]
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