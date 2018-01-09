

//------------------------------------------------------------------------------

character
	parent_type = /combatant
	icon = 'cq.dmi'
	//icon_state = "clams"
	baseSpeed = 2
	disposable = FALSE
	baseHp = 3
	baseMp = 0
	faction = FACTION_PLAYER
	var
		interface/rpg/interface
		list/equipment[4]

	//-- Saving & Loading --------------------------//
	toJSON()
		var/list/jsonObject = ..()
		jsonObject["name"] = name
		jsonObject["equipment"] = list2JSON(equipment)
		return jsonObject
	fromJSON(list/objectData)
		name = objectData["name"]
		for(var/item/equipItem in json2List(objectData["equipment"] || list()))
			equip(equipItem)

	//-- Movement ----------------------------------//
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
		go(deltaX, deltaY)
			var/tile/interact/I = locate() in locs
			if(I && I.interaction & INTERACTION_WALK)
				I.interact(src, INTERACTION_WALK)
			return translate(deltaX, deltaY)
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
			#warn Calculate tile from conditions (buildings, warps at south edge, center, etc)
			var /tile/center = locate(
				round((targetRegion.mapOffset.x+targetPlot.x+1/2)*PLOT_SIZE),
				round((targetRegion.mapOffset.y+targetPlot.y+1/2)*PLOT_SIZE),
				targetRegion.z()
			)
			//diag(center.x, center.y, center.z)
			//world << "\icon [center]"
			transition(targetPlot, center)

	//-- Interface Coupling ------------------------//
	proc/refreshInterface(which, list/aList)
		if(interface) interface.refresh(which, aList)

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
	adjustHp()
		. = ..()
		if(interface) interface.refresh("hp")
	adjustMp(amount)
		. = ..()
		if(interface) interface.refresh("mp")
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
	proc
		equip(item/gear/newGear)
			if(!istype(newGear)) return
			var oldGear = equipment[newGear.position]
			if(oldGear) unequip(oldGear)
			equipment[newGear.position] = newGear
			newGear.equipped(src)
			return oldGear
		unequip(item/gear/oldGear)
			if(!istype(oldGear)) return
			equipment[oldGear.position] = null
			oldGear.unequipped(src)
			return oldGear
		use(usable/_usable)
			_usable.use(src)

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

	//-- Interface Control -------------------------//
	control()
		. = ..()
		if(.) return
		if(interface)
			interface.control(src)
			return TRUE


