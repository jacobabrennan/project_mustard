

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
