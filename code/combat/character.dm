

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
		owner // the key of the profile that owns this character
		interface/rpg/interface
		list/equipment[4]
		list/inventory[24]
		coins = 0

	//-- Saving & Loading -------------------------------//
	toJSON()
		var/list/jsonObject = ..()
		jsonObject["owner"] = owner
		jsonObject["name"] = name
		jsonObject["equipment"] = list2JSON(equipment)
		jsonObject["inventory"] = list2JSON(inventory)
		jsonObject["coins"] = coins
		return jsonObject
	fromJSON(list/objectData)
		owner = objectData["owner"]
		name = objectData["name"]
		coins = objectData["coins"] || 0
		for(var/item/equipItem in json2List(objectData["equipment"] || list()))
			equip(equipItem)
		for(var/item/inventoryItem in json2List(objectData["inventory"] || list()))
			get(inventoryItem)
	/*proc/load(key, characterId)
		if(!characterId) characterId = key
		name = characterId
		owner = ckey(key)
		//
		var/filePath = "[FILE_PATH_CHARACTERS]/[ckey(owner)].json"
		if(fexists(filePath))
			var/list/saveData = json_decode(file2text(filePath))
			// TODO: check for compatible version
			fromJSON(saveData)
		return FALSE
	proc/unload()
		//
		var/list/saveData = toJSON()
		saveData["saveVersion"] = SAVEFILE_VERSION
		var/filePath = "[FILE_PATH_CHARACTERS]/[ckey(owner)].json"
		replaceFile( filePath, json_encode(saveData))
		//
		del src*/

	//-- Movement ---------------------------------------//
	proc/transition(plot/newPlot, turf/newTurf)
		if(newTurf)
			var/offsetX = (dir&( EAST|WEST ))? 0 : step_x
			var/offsetY = (dir&(NORTH|SOUTH))? 0 : step_y
			var/success = Move(newTurf, 0 , offsetX, offsetY)
			if(!success)
				forceLoc(newTurf)
		if(interface)
			interface.transition(newPlot)
		newPlot.activate(src)
	proc/refreshInterface(which, list/aList)
		if(interface) interface.refresh(which, aList)

	//-- Health and Magic -------------------------------//
	var
		baseAuraRegain = 0
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
	takeTurn()
		. = ..()
		if(mp >= maxMp())
			_auraRegainCounter = 0
		else if(!dead && _auraRegainCounter++ >= auraRegainDelay())
			_auraRegainCounter = 0
			adjustMp(1)


	//-- Inventory / equipment management ---------------//
	proc
		adjustCoins(amount)
			coins += amount
			refreshInterface("coins", coins)
		get(item/newItem)
			if(!istype(newItem)) return FALSE
			if(newItem in inventory) return FALSE
			var placed = FALSE
			for(var/I = 1 to inventory.len)
				if(!inventory[I])
					inventory[I] = newItem
					placed = TRUE
					break;
			if(placed)
				newItem.forceLoc(null)
				refreshInterface("inventory", inventory)
				return newItem
		unget(item/oldItem)
			if(!istype(oldItem)) return FALSE
			inventory.Remove(oldItem)
			inventory.len = 24 // MAGIC NUMBER
			oldItem.loc = null
			refreshInterface("inventory", inventory)
			refreshInterface("slots")
		drop(item/oldItem)
			if(!istype(oldItem)) return FALSE
			unget(oldItem)
			oldItem.loc = loc
		equip(item/gear/newGear)
			if(!istype(newGear)) return
			if(newGear in inventory)
				inventory.Remove(newGear)
				inventory.len = 24
				refreshInterface("inventory", inventory)
			var oldGear = equipment[newGear.position]
			if(oldGear) unequip(oldGear)
			equipment[newGear.position] = newGear
			newGear.equipped(src)
			refreshInterface("equipment", equipment)
			refreshInterface("hp")
			refreshInterface("mp")
			return oldGear
		unequip(item/gear/oldGear)
			if(!istype(oldGear)) return
			equipment[oldGear.position] = null
			oldGear.unequipped(src)
			refreshInterface("equipment", equipment)
			refreshInterface("hp")
			refreshInterface("mp")
			var/success = get(oldGear)
			if(!success)
				drop(oldGear)
			return oldGear
		use(usable/_usable)
			_usable.use(src)

	//-- Combat Redefinitions ---------------------------//
	shoot(projType)
		if(projType) return ..(projType)
		var /item/weapon/W = equipment[WEAR_WEAPON]
		if(W)
			return W.use(src)
		. = ..()


	//-- Interface Control ------------------------------//
	control()
		. = ..()
		if(.) return
		if(interface)
			interface.control(src)
			return TRUE


//-- Commonly used projectiles -----------------------------------//

projectile/bowArrow
	icon = 'projectiles.dmi'
	icon_state = "arrow"
	//max_time = 32
	bound_height = 3
	bound_width  = 3
	movement = MOVEMENT_ALL
	projecting = FALSE
	persistent = FALSE
	roughWalk = 16
	var
		long_width = 16
		short_width = 3
	New()
		. = ..()
		dir = owner.dir
		switch(dir)
			if(NORTH, SOUTH)
				bound_height = long_width
				bound_width = short_width
			if(EAST , WEST )
				bound_height = short_width
				bound_width = long_width

projectile/axe
	parent_type = /projectile/swipe
projectile/swipe
	icon = 'projectiles.dmi'
	icon_state = "axe"
	var
		time = 0
	movement = MOVEMENT_ALL
	baseSpeed = 0
	projecting = FALSE
	persistent = TRUE
	interactionProperties = INTERACTION_CUT
	New()
		. = ..()
		var/character/O = owner
		if(istype(O))
			O.addController(src)
		takeTurn()
	Del()
		owner.icon_state = ""
		. = ..()
	proc/interrupt()
		del src
	takeTurn()
		if(!owner) del src
		owner.icon_state = "attack"
		centerLoc(owner)
		dir = owner.dir
		var stage = round(time++/4)
		switch(stage)
			if(0) dir = turn(dir, -45)
			if(1) dir = turn(dir,   0)
			if(2) dir = turn(dir,  45)
			if(3) del src
		var/deltaX = 0
		var/deltaY = 0
		switch(dir)
			if(     EAST){ deltaX += bound_width                             }
			if(NORTHEAST){ deltaX += bound_width -3; deltaY += bound_height-3}
			if(NORTH    ){                           deltaY += bound_height  }
			if(NORTHWEST){ deltaX -= bound_width -3; deltaY += bound_height-3}
			if(     WEST){ deltaX -= bound_width                             }
			if(SOUTHWEST){ deltaX -= bound_width -3; deltaY -= bound_height-3}
			if(SOUTH    ){                           deltaY -= bound_height  }
			if(SOUTHEAST){ deltaX += bound_width -3; deltaY -= bound_height-3}
		var dirStorage = dir
		//step_size = offset
		translate(deltaX, deltaY)
		dir = dirStorage
		//step(src, dir)
		. = ..()
		//centerLoc(owner)

projectile/sword
	icon = 'projectiles.dmi'
	icon_state = "sword_6"
	var
		time = 0
		stage = 0
	movement = MOVEMENT_ALL
	baseSpeed = 0
	projecting = FALSE
	persistent = TRUE
	interactionProperties = INTERACTION_CUT
	New()
		. = ..()
		var/character/O = owner
		if(istype(O))
			O.addController(src)
		switch(dir)
			if(NORTH, SOUTH)
				bound_width = 8
			if(EAST,  WEST )
				bound_height = 8
	Del()
		owner.icon_state = ""
		. = ..()
	proc/interrupt()
		del src
	takeTurn()
		if(!owner) del src
		owner.icon_state = "attack"
		centerLoc(owner)
		dir = owner.dir
		var/offset = 0
		var/deltaX = 0
		var/deltaY = 0
		switch(time++)
			if(0,5)	stage = 1
			if(1,4) stage = 2
			if(2,3) stage = 3
			if(6) del src
		switch(stage)
			if(1){ icon_state = "sword_6" ; offset =  6}
			if(2){ icon_state = "sword_11"; offset = 11}
			if(3){ icon_state = "sword_16"; offset = 16}
		switch(dir)
			if(NORTH){ deltaY += offset; pixel_y =  TILE_SIZE}
			if(SOUTH){ deltaY -= offset; pixel_y = -TILE_SIZE}
			if( EAST){ deltaX += offset; pixel_x =  TILE_SIZE}
			if( WEST){ deltaX -= offset; pixel_x = -TILE_SIZE}
		step_size = offset
		step(src, dir)
		. = ..()
		centerLoc(owner)
		dir = owner.dir






/*

Town Points
	Unlock Plots
	Change Tiles
	Buy Buildings

Hero Points
	Buy Skills
	Buy Stat Upgrades

Gold
	Buy Gear
	Buy expendable Items










Level Progression
10mins
	3hearts
	Get a weapon
	Get some money
2hours
	Introduce Goals:
		Better Equipment
		Better Skills
		Better Location
4days
2weeks
2months








*/