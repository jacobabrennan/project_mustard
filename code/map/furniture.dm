

//-- Furniture -----------------------------------------------------------------

furniture
	parent_type = /obj
	density = TRUE
	movement = MOVEMENT_FLOOR
	toJSON()
		var/list/objectData = ..()
		var/plot/plotArea/PA = aloc(src)
		objectData["x"] = x-PA.x
		objectData["y"] = y-PA.y
		return objectData
	// Placement is handled by plot.fromJSON(), because of variable z location
	var
		interaction = INTERACTION_TOUCH // Projectiles can burn or cut, etc., furniture
		thumbnailState // The icon_state to be shown in the town editor (small icons for large furniture)
	Cross(character/C)
		if(interaction&INTERACTION_TOUCH && istype(C))
			return interact(C, INTERACTION_TOUCH)
		else if(istype(C, /projectile))
			var /projectile/P = C
			if(P.interactionProperties & interaction)
				interact(P, P.interactionProperties&interaction)
		return TRUE
	proc/interact(atom/A, interactionFlags)
	proc/activate()
furniture/bed
	icon = 'furniture_32.dmi'
	icon_state = "bed"
	pixel_y = -2
	interact(character/character)
		character.adjustHp(character.maxHp())
		character.adjustMp(character.maxMp())
/*furniture/innNPC
	icon = 'cq.dmi'
	interact(character/character)
		character.adjustHp(character.maxHp())
		character.adjustMp(character.maxMp())
		var/menu/store/C = character.interface.client.menu.addComponent(/menu/store)
		var/list/itemList = list()
		for(var/index = 1 to 36)
			var/itemType = pick(typesof(/item/gear)-/item/gear)
			itemList.Add(new itemType())
		C.setup(itemList)
		character.interface.client.menu.focus(C)*/

furniture/deleter
	icon = 'menu16.dmi'
	icon_state = "cancel"
	thumbnailState = "cancel"
	New()
		. = ..()
		spawn(1)
			del src

furniture/chest
	icon = 'desert.dmi'
	icon_state = "chest"
	interaction = INTERACTION_TOUCH
	var
		treasureId
		treasureType
		//
		open = FALSE
	toJSON()
		var /list/objectData = ..()
		objectData["treasureId"] = treasureId
		objectData["treasureType"] = treasureType
		return objectData
	fromJSON(list/objectData)
		. = ..()
		treasureId = objectData["treasureId"]
		treasureType = objectData["treasureType"]
	_configureMapEditor()
		var temp = input("Set Treasure Id", "Treasure Chest", treasureId) as text
		if(!temp) return
		treasureId = temp
		temp = text2path(input("Set Treasure Typepath", "Treasure Chest", "[treasureType]") as text)
		if(!(ispath(temp))) return
		treasureType = temp
		alert("Treasure Set", "Treasure Chest")
	activate()
		var /plot/P = plot(src)
		var /game/G = game(P)
		var questState = G.quest.get("treasureId")
		var /terrain/T = terrains[P.terrain]
		icon = T.icon
		if(questState)
			icon_state = "chest_open"
			open = TRUE
		else
			icon_state = "chest"
			open = FALSE
	interact(character/partyMember/touchChar, interactFlags)
		// Return if already open the plot is hostile
		if(open)
			return
		var /plot/P = plot(src)
		if(P.isHostile())
			return
		// Make sure it's a player interacting
		if(!istype(touchChar) || !(touchChar.faction&FACTION_PLAYER) || !touchChar.interface)
			return
		// Set quest and close chest
		var /game/G = game(P)
		G.quest.put(treasureId, TRUE)
		icon_state = "chest_open"
		open = TRUE
		// Instantiate the item and add to party inventory
		var /item/newItem = new treasureType()
		touchChar.get(newItem)
		// Show the item to all players in the plot
		for(var/character/partyMember/member in aloc(src))
			var rpg/int = member.interface
			if(!int) continue
			int.menu.openMenu()
			int.menu.gear.showItem(newItem)



furniture/tree
	icon = 'tree1.dmi'
	icon_state = "tree1"
	pixel_x = -16
	thumbnailState = "tree1_thumb"
	interaction = INTERACTION_CUT | INTERACTION_WIND// | INTERACTION_TOUCH
	movement = MOVEMENT_WALL
	var/cut = FALSE
	/*var/warpRegion
	var/warpPlot
	toJSON()
		var /list/objectData = ..()
		objectData["warpRegion"] = warpRegion
		objectData["warpPlot"] = warpPlot
		return objectData
	fromJSON(list/objectData)
		. = ..()
		warpRegion = objectData["warpRegion"]
		warpPlot = objectData["warpPlot"]
	_configureMapEditor()
		warpPlot = input("Warp Plot?", "Set Stuff", warpPlot) as text
		warpRegion = input("Warp Region?", "Set Stuff", warpRegion) as text*/
	interact(projectile/projectile, interactFlags)
		//var/character/C = projectile
		//var /plot/P = plot(src)
		//if(!warpPlot) return
		//diag(warpPlot, warpRegion)
		//C.warp(warpPlot, warpRegion, P.gameId)
		if(cut) return
		if(interactFlags & INTERACTION_CUT)
			cut = TRUE
			//var /item/rawMaterial/wood/W = new()
			//W.forceLoc(loc)
			icon_state = "stump"
			movement = MOVEMENT_FLOOR
			density = FALSE
			spawn(TIME_RESOURCE_RESTORE)
				restore()
		//else if(interactFlags & INTERACTION_WIND)
	//activate()
	//	. = ..()
	proc/restore()
		cut = initial(cut)
		icon_state = initial(icon_state)
		movement = initial(movement)
		density = initial(density)


//------------------------------------------------------------------------------

memory
	entrance
		parent_type = /furniture
		icon = 'memory.dmi'
		icon_state = "test"
		var
			warpRegion
			// warpPlot defaults to "start"
		toJSON()
			var /list/objectData = ..()
			objectData["warpRegion"] = warpRegion
			return objectData
		fromJSON(list/objectData)
			. = ..()
			warpRegion = objectData["warpRegion"]
		_configureMapEditor()
			warpRegion = input("Enter target region for warp", "Memory Entrance", warpRegion)
		activate()
			spawn(40)
				var /game/G = game(src)
				G.party.changeRegion(warpRegion)
