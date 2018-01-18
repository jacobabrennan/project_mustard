

//-- Usable - Objects that can be "used" by characters -------------------------

usable
	parent_type = /obj
	proc/use(character/user)

spell
	parent_type = /usable
	icon = 'spells.dmi'
	var
		mpCost = 1
	heal
		var
			range = 48
			potency = 1
		use(character/user)
			// Add some kind of flash on the hud
			if(user.mp < mpCost) return
			user.adjustMp(-mpCost)
			var radius = range - (user.bound_width/2)
			new /effect/aoeColor(user, radius, "#0f0")
			for(var/combatant/C in bounds(user, radius))
				if(C.dead) continue
				if(!(C.faction & user.faction)) continue
				C.adjustHp(potency)
				new /effect/sparkleHeal(C)


//-- Items - can be placed on the map. Characters can "get" --------------------

item
	parent_type = /usable
	icon = 'weapons.dmi'
	icon_state = "potion"
	var
		price = 1
		instant = FALSE
			// Items, like Fruit, that are used as soon as picked up.
		equipFlags = EQUIP_ANY
		// Nonconfigurable:
		timeStamp
	New()
		. = ..()
		timeStamp = world.time
	use(character/user)
		. = ..()
		if(instant)
			del src
	Cross(character/getChar)
		if(world.time - timeStamp < TIME_ITEM_COLLECT) return ..()
		if(!loc) return FALSE
		if(istype(getChar))
			if(instant)
				use(getChar)
			else
				getChar.get(src)
		return . = ..()
	gear
		var
			position = WEAR_BODY
			boostHp = 0
			boostMp = 0
			boostAuraRegain = 0
		proc
			equipped(character/equipper)
			unequipped(character/unequipper)
	weapon
		parent_type = /item/gear
		position = WEAR_WEAPON
		icon = 'weapons.dmi'
		icon_state = "sword"
		var
			twoHanded = FALSE
			potency = 1
			projectileType = /projectile/sword
		use(character/user)
			var/projectile/P = user.shoot(projectileType)
			if(!P) return
			P.potency = potency
			return P
		equipped(character/equipChar)
			. = ..()
			if(twoHanded)
				var /item/gear/secondHand = equipChar.equipment[WEAR_SHIELD]
				if(secondHand)
					equipChar.unequip(secondHand)
		proc/weaponBehavior(character/equipChar)
			return FALSE

	//-- Basic Archetypes ----------------------------
	shield
		parent_type = /item/gear
		position = WEAR_SHIELD
		equipFlags = EQUIP_SHIELD
		icon = 'armor.dmi'
		icon_state = "blue"
		var
			threshold = 1
			// Projectiles with potency <= value will be blocked
			overlay
			underlay
			fileOverlay = 'shield_blue_overlay.dmi'
			fileUnderlay = 'shield_blue_underlay.dmi'
		proc
			defend(projectile/proxy, combatant/attacker, damage)
				. = TRUE
				if(damage > threshold) return FALSE
		equipped(character/equipChar)
			. = ..()
			var /image/overImage = image(fileOverlay)
			var /image/underImage = image(fileUnderlay)
			overImage.pixel_x = -2
			underImage.pixel_x = -2
			overlay  = getAppearance(overImage)
			underlay = getAppearance(underImage)
			equipChar.overlays.Add(overlay)
			equipChar.underlays.Add(underlay)
		unequipped(character/equipChar)
			. = ..()
			equipChar.overlays.Remove(overlay)
			equipChar.underlays.Remove(underlay)
	sword
		parent_type = /item/weapon
		equipFlags = EQUIP_SWORD
		icon_state = "sword"
		projectileType = /projectile/sword
		potency = 1
	axe
		parent_type = /item/weapon
		equipFlags = EQUIP_AXE
		twoHanded = TRUE
		icon_state = "axe"
		projectileType = /projectile/axe
		potency = 1
		var
			combatant/target
		weaponBehavior(character/equipChar)
			var targetRange = 49 // How far we're willing to go to target something
			var breakRange = 80 // How far we'll go until we break off
			// Check which threat is the closest
			var closeDist = targetRange
			var closeEnemy
			for(var/combatant/E in bounds(equipChar, closeDist))
				if(!equipChar.hostile(E)) continue
				var testDist = bounds_dist(equipChar, E)
				//if(testDist >= TILE_SIZE && bounds_dist(party.mainCharacter, E) > 80) continue
				if(testDist >= closeDist) continue
				closeEnemy = E
				closeDist = testDist
			// Attack enemies that are within hitting range
			if(closeDist < TILE_SIZE-4) // Account for diagonal axes
				target = closeEnemy
				equipChar.dir = get_dir(equipChar, target)
				use(equipChar)
				return TRUE
			// Find and attack a target
			// If current target is too far away, forget about it
			if(target && bounds_dist(equipChar.party.mainCharacter, target) > breakRange)
				target = null
			// If we don't have a target, target the closest combatant
			if(!target && bounds_dist(equipChar.party.mainCharacter, closeEnemy) <= breakRange)
				target = closeEnemy
			// If we have a target, advance towards it
			if(target)
				equipChar.stepTo(target)
				return TRUE
	bow
		parent_type = /item/weapon
		equipFlags = EQUIP_BOW
		icon_state = "crossbow"
		projectileType = /projectile/bowArrow
		potency = 1
		var
			arrowSpeed = 6
			arrowRange = 240
			// Nonconfigurable:
			projectile/currentArrow
			combatant/target
		use(character/user)
			del currentArrow
			var /item/quiver/Q = user.equipment[WEAR_SHIELD]
			if(!istype(Q)) return
			var /projectile/A = Q.getArrow(user, src)
			if(!A) return
			A.baseSpeed = arrowSpeed
			A.maxRange = arrowRange
			A.potency = potency
			A.project()
			currentArrow = A
			return A
		weaponBehavior(character/equipChar)
			if(currentArrow) return FALSE
			// Check if the character has a quiver equipped
			var /item/quiver/Q = equipChar.equipment[WEAR_SHIELD]
			if(!istype(Q)) return
			// If there's a target, check if it's still aligned to attack
			var alignMax = 32
			var /plot/plotArea/A = aloc(equipChar)
			var /list/deltasX = new()
			var /list/deltasY = new()
			var toFar
			if(bounds_dist(equipChar, equipChar.party.mainCharacter) > 112) toFar = TRUE
			if(target)
				var deltaX = ((target.x-A.x)*TILE_SIZE + target.bound_width /2 + target.step_x) - ((equipChar.x-A.x)*TILE_SIZE + equipChar.bound_width /2 + equipChar.step_x)
				var deltaY = ((target.y-A.y)*TILE_SIZE + target.bound_height/2 + target.step_y) - ((equipChar.y-A.y)*TILE_SIZE + equipChar.bound_height/2 + equipChar.step_y)
				if(target.dead || min(abs(deltaX), abs(deltaY)) > alignMax || toFar)
					target = null
			// Check for targets of opportunity. Shoot the one that can be hit the fastest with an arrow
			var fastestDir
			var /combatant/fastestHit
			var /combatant/fastestTime = 1000
			for(var/combatant/E in A)
				if(!equipChar.hostile(E)) continue
				var deltaX = ((E.x-A.x)*TILE_SIZE + E.bound_width /2 + E.step_x) - ((equipChar.x-A.x)*TILE_SIZE + equipChar.bound_width /2 + equipChar.step_x)
				var deltaY = ((E.y-A.y)*TILE_SIZE + E.bound_height/2 + E.step_y) - ((equipChar.y-A.y)*TILE_SIZE + equipChar.bound_height/2 + equipChar.step_y)
				deltasX[E] = deltaX
				deltasY[E] = deltaY
				if(min(abs(deltaX), abs(deltaY)) > arrowRange) continue
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
					if(abs(deltaY) > arrowRange) continue
					var deltaT = abs(deltaX / E.speed())
					var arrowT = abs(deltaY / arrowSpeed)
					if(directY || abs(deltaT - arrowT) <= 4)
						testTime = deltaT
						testDir = (deltaY > 0)? NORTH : SOUTH
				if(closingY || directX) // Attack Horizontally
					if(abs(deltaX) > arrowRange) continue
					var deltaT = abs(deltaY / E.speed())
					var arrowT = abs(deltaX / arrowSpeed)
					if((deltaT < testTime) && (directX || abs(deltaT - arrowT) <= 5))
						testTime = deltaT
						testDir = (deltaX > 0)? EAST  : WEST
				if(testTime < fastestTime)
					fastestTime = testTime
					fastestHit = E
					fastestDir = testDir
			if(fastestHit)
				equipChar.dir = fastestDir
				use(equipChar)
				target = null
				return TRUE
			// If we can't shoot anything (and there's no target), try to target the combatant that requires the least movement to align with
			if(!target && !toFar)
				var closestAlignTarget
				var closestAlignDist = alignMax
				for(var/combatant/E in A)
					if(!equipChar.hostile(E)) continue
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
				if(bounds_dist(equipChar, target) < TILE_SIZE*2)
					target = null
					return FALSE
				else
					//if(step_to(owner, target, 2, owner.speed())) return TRUE // see stepTo()
					var axisHorizontal = (abs(deltasX[target]) <= abs(deltasY[target]))? TRUE : FALSE
					var success
					if(axisHorizontal)
						if(deltasX[target] > 0) success = equipChar.go(equipChar.speed(), 0)
						else success = equipChar.go(-equipChar.speed(), 0)
					else
						if(deltasY[target] > 0) success = equipChar.go(0, equipChar.speed())
						else success = equipChar.go(0, -equipChar.speed())
					return success
			//  Otherwise, walk toward the player
			return FALSE
	arrow
	wand // Weak Melee attack plus magic projectile
		parent_type = /item/weapon
		equipFlags = EQUIP_WAND
		icon_state = "wand"
		projectileType = /projectile/wand
		potency = 1
		var
			spellCost = 1
			spellProjectileType = /projectile/fire1
			spellPotency
			spellSpeed = 6
			spellRange = 240
		use(character/user)
			. = ..()
			if(user.mp < spellCost) return
			user.adjustMp(-spellCost)
			var /projectile/P = user.shoot(spellProjectileType)
			if(!P) return
			P.baseSpeed = spellSpeed || P.baseSpeed
			P.maxRange = spellRange || P.maxRange
			P.project()
			return P
	quiver
		parent_type = /item/gear
		position = WEAR_SHIELD
		equipFlags = EQUIP_BOW
		icon = 'weapons.dmi'
		icon_state = "quiver1"
		var
			projectileType = /projectile/bowArrow
		proc/getArrow(character/equipChar, item/bow/equipBow)
			return equipChar.shoot(projectileType)
	book
		parent_type = /item/gear
		position = WEAR_SHIELD
		equipFlags = EQUIP_BOOK
		icon = 'items.dmi'
		icon_state = "book"
		var
			list/spells
		equipped(character/equipChar)
			. = ..()
			var /list/hotKeys = list(SECONDARY, TERTIARY, QUATERNARY)
			for(var/I = 1 to spells.len)
				var typepath = spells[I]
				var /spell/S = new typepath()
				equipChar.setHotKey(S, hotKeys[I])
		unequipped(character/equipChar)
			for(var/typepath in spells)
				var /spell/S = locate(typepath) in equipChar.hotKeys
				if(!S) continue
				var index = equipChar.hotKeys.Find(S)
				var /list/hotKeys = list(SECONDARY, TERTIARY, QUATERNARY)
				equipChar.setHotKey(HOTKEY_REMOVE, hotKeys[index])
				del S


//-- Enemy Drops (eg: hearts) --------------------------------------------------

	instant
		instant = TRUE
		bound_width = 8
		bound_height = 8
		New()
			. = ..()
			spawn(TIME_ITEM_DISAPPEAR)
				del src
		Cross(character/getChar)
			var/projectile/P = getChar
			if(istype(P))
				if(world.time - timeStamp < 10) return ..()
				var/character/C = P.owner
				if(istype(C))
					use(C)
					return TRUE
			else
				. = ..()
		berry
			icon = 'item_drops.dmi'
			icon_state = "cherry"
			use(character/user)
				var result = user.adjustHp(1)
				if(result)
					new /effect/sparkleHeal(user)
					. = ..()
		plum
			icon = 'item_drops.dmi'
			icon_state = "plum"
			use(character/user)
				var result = user.adjustHp(10)
				if(result)
					new /effect/sparkleHeal(user)
					. = ..()
		magicBottle
			icon = 'item_drops.dmi'
			icon_state = "bottle"
			use(character/user)
				var result = user.adjustMp(user.maxMp())
				if(result)
					new /effect/sparkleAura(user)
					. = ..()