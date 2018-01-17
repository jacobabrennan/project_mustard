

//-- Character - Combatants that can equip and use items -----------------------

character
	parent_type = /combatant
	icon = 'cq.dmi'
	baseSpeed = 2
	disposable = FALSE
	baseHp = 3
	baseMp = 0
	faction = FACTION_PLAYER
	var
		portrait = "test" // The icon_state of the portrait to show from portraits.dmi
		//
		list/equipment[4]

	//-- Movement ----------------------------------//
	proc
		go(deltaX, deltaY)
			var/tile/interact/I = locate() in locs
			if(I && I.interaction & INTERACTION_WALK)
				I.interact(src, INTERACTION_WALK)
			return translate(deltaX, deltaY)

	//-- Health and Magic --------------------------//
	var
		baseAuraRegain = 0
		// Nonconfigurable:
		_auraRegainCounter = 0
	maxHp()
		var/fullHp = ..()
		for(var/item/gear/G in equipment)
			fullHp += G.boostHp
		return fullHp
	maxMp()
		var/fullMp = ..()
		for(var/item/gear/G in equipment)
			fullMp += G.boostMp
		return fullMp
	proc/auraRegain()
		var/fullRegain = baseAuraRegain
		for(var/item/gear/G in equipment)
			fullRegain += G.boostAuraRegain
		return fullRegain
	proc/auraRegainDelay()
		var regainDegree = auraRegain()
		// (0: 544), 1:512, 2:480, 3:448 ... 15:64, 16:32
		return max(0, 17-(regainDegree))*32
	takeTurn(delay)
		. = ..()
		if(mp >= maxMp())
			_auraRegainCounter = 0
		else if(!dead)
			_auraRegainCounter += delay
			if(_auraRegainCounter > auraRegainDelay())
				_auraRegainCounter = 0
				adjustMp(1)

	//-- Equipment Management ----------------------//
	var
		equipFlags = 0
	proc
		equip(item/gear/newGear)
			if(!istype(newGear)) return
			if(!canEquip(newGear)) return
			var oldGear = equipment[newGear.position]
			if(oldGear) unequip(oldGear)
			equipment[newGear.position] = newGear
			newGear.equipped(src)
			return TRUE
		unequip(item/gear/oldGear)
			if(!istype(oldGear)) return
			equipment[oldGear.position] = null
			oldGear.unequipped(src)
			return TRUE
		use(usable/_usable)
			_usable.use(src)
		canEquip(item/gear/newGear)
			. = TRUE
			if(!istype(newGear)) return FALSE
			if(!(equipFlags & newGear.equipFlags)) return FALSE
			if(newGear.position == WEAR_SHIELD)
				var /item/weapon/W = equipment[WEAR_WEAPON]
				if(W && W.twoHanded) return FALSE

	//-- Combat Redefinitions ----------------------//
	shoot(projType)
		if(projType) return ..(projType)
		var /item/weapon/W = equipment[WEAR_WEAPON]
		if(W)
			return W.use(src)
		. = ..()
	defend(projectile/proxy, combatant/attacker, damage)
		if(dead) return
		if(proxy.omnidirectional) return
		var /item/shield/S = equipment[WEAR_SHIELD]
		if(!istype(S)) return
		if(icon_state) return // Values other than "" or null
		// Calculate the angle between src and projectile
		var /vector/vectorTo = new()
		vectorTo.from(src, proxy)
		// Change angle to src's reference (0 is direction src is facing)
		switch(dir)
			if(NORTH) vectorTo.rotate(- 90)
			if(SOUTH) vectorTo.rotate(-270)
			if( WEST) vectorTo.rotate(-180)
		switch(vectorTo.dir)
		// If the projectile hit clearly on the back or sides
			if(60 to 300) return
		// If the projectile hit clearly on the front
			// if(0 to 45, 315 to 360
		// If the projectile dit not hit clearly, check direction it was travelling
			if(46 to 60, 300 to 314)
				if(dir != turn(proxy.dir, 180))
					return
		// Success, have the shield try to defend
		return S.defend(proxy, attacker, damage)


//-- Character - Factored out of partyMember -----------------------------------

character
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


//-- Inventory, Equipment, & hotKeys -------------------------------------------

character
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
			// Special circumstances if it's a spell
			var /item/oldHotKey = hotKeys[hotKeyIndex]
			if(istype(oldHotKey, /spell))
				if(_usable != HOTKEY_REMOVE) return
				hotKeys[hotKeyIndex] = null
				party.refreshInterface("hotKeys", src)
				return TRUE
			// Unequip any old /item in hot key
			if(istype(oldHotKey)) get(oldHotKey)
			// Set hot key to /usable (also works for clearing via null)
			hotKeys[hotKeyIndex] = _usable
			// Remove /usable from inventory
			party.unget(_usable)
			// Display results in hot keys
			party.refreshInterface("hotKeys", src)
			return TRUE
		getHotKey(command)
			var/hkIndex
			switch(command)
				if(SECONDARY ) hkIndex = 1
				if(TERTIARY  ) hkIndex = 2
				if(QUATERNARY) hkIndex = 3
			return hotKeys[hkIndex]


//-- Movement ------------------------------------------------------------------

character
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


//-- Control & Behavior --------------------------------------------------------

character
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
		//manDown(var/character/member) // whenever a party member faints, everyone in the party is alerted
		shouldIRescue()
			if(!party.mainCharacter.dead) return FALSE
			var rescue = TRUE
			if(partyId == CHARACTER_GOBLIN)
				for(var/character/M in party.characters)
					if(M.partyId == CHARACTER_CLERIC && !M.dead)
						rescue = FALSE
			else if(partyId == CHARACTER_SOLDIER)
				for(var/character/M in party.characters)
					if(M != src && !M.dead)
						rescue = FALSE
			return rescue


//-- Character Fainting & Revive Assist ----------------------------------------

character
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
		/*for(var/character/member in party.characters)
			if(member == src) continue
			member.manDown(src)*/
		// Hide HUD
		if(interface && interface.client)
			interface.menu.hide()
		// Check if the entire party is down (Game Over)
		var gameOver = TRUE
		for(var/character/member in party.characters)
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
		for(var/overlay in system._metersRevive)
			overlays.Remove(overlay)
		// Show HUD
		if(interface && interface.client)
			interface.client.menu.focus(interface.menu)

sequence/fainted
	var
		faintTime = 40 // The time before the character can be revived
		reviveCount = 0
		mutable_appearance/reviveMeter // Not mutable
	init(character/char)
		char.icon_state = "down"
		flick("faint", char)
		char.overlays.Add(system._faintOverlay)
		. = ..()
	control(character/char)
		if(faintTime-- < 0)
			char.overlays.Remove(reviveMeter)
			var reviving
			for(var/character/mem in char.party.characters)
				if(!mem.dead && bounds_dist(char, mem) <= 1)
					if(++reviveCount > 80)
						char.revive()
						. = TRUE
						del src
					reviving = TRUE
					break
			if(!reviving)
				reviveCount = 0
			else
				var meter = round(reviveCount/10)+1
				if(meter >= 1 && meter <= 8)
					reviveMeter = system._metersRevive[meter]
					char.overlays.Add(reviveMeter)
		return TRUE


//-- Health & Magic Bars - Also Faiting and Revive Bars ------------------------

system
	var
		list/_metersHp = new(TILE_SIZE)
		list/_metersMp = new(TILE_SIZE)
		list/_metersRevive = new(8)
		mutable_appearance/_faintOverlay
	New()
		. = ..()
		var /obj/temp
		// Prepare HP meter overlays
		for(var/I = 1 to TILE_SIZE)
			temp = new()
			var /image/protoAppearance = image('meters.dmi', null, "hp_[I]", FLY_LAYER)
			protoAppearance.pixel_y = TILE_SIZE+1
			protoAppearance.plane = PLANE_METERS
			temp.overlays.Add(protoAppearance)
			for(var/appearance in temp.overlays)
				_metersHp[I] = appearance
			del temp
		// Prepare MP meter overlays
		for(var/I = 1 to TILE_SIZE)
			temp = new()
			var /image/protoAppearance = image('meters.dmi', null, "mp_[I]", FLY_LAYER)
			protoAppearance.pixel_y = TILE_SIZE+3
			protoAppearance.plane = PLANE_METERS
			temp.overlays.Add(protoAppearance)
			for(var/appearance in temp.overlays)
				_metersMp[I] = appearance
			del temp
		// Prepare faint overlay
		temp = new()
		var /image/faint = image('_wrapper.dmi', null, "faint", FLY_LAYER)
		faint.pixel_y += TILE_SIZE
		faint.plane = PLANE_METERS
		temp.overlays.Add(faint)
		for(var/appearance in temp.overlays)
			_faintOverlay = appearance
		del temp
		// Prepare Revive meter overlay
		for(var/I = 1 to _metersRevive.len)
			temp = new()
			var /image/protoAppearance = image('meters.dmi', null, "revive_[I]", FLY_LAYER)
			protoAppearance.pixel_y = TILE_SIZE+2
			protoAppearance.plane = PLANE_METERS
			temp.overlays.Add(protoAppearance)
			for(var/appearance in temp.overlays)
				_metersRevive[I] = appearance
			del temp


character
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
