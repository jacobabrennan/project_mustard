

//-- RPG - The main interface used while playing -------------------------------

interface/rpg
	var
		character/partyMember/character
		interface/rpg/menu/menu
		event/transition/transitionEvent
		commandsDown = 0
		// Logs commands pressed between calls to control()
		terrain/currentTerrain
	New(client/newClient, character/oldCharacter)
		if(oldCharacter) character = oldCharacter
		. = ..()
	Login()
		. = ..()
		// Show the player the game
		client.eye = src
		// Reconnect to character
		ASSERT(character)
		character.interface = src
		// Create and ready menu
		menu = client.menu.addComponent(/interface/rpg/menu)
		menu.setup()
		menu.show(src)
		menu.refresh("inventory", character.party.inventory)
		menu.refresh("equipment", character.equipment)
		client.menu.focus(menu)
		// Transition client to plot
		var /plot/currentPlot = plot(character)
		if(currentPlot)
			transition(currentPlot)

	//-- Command Passing - Client to Interface -------
	proc/checkCommands()
		return client.macros.commands | commandsDown
	proc/control(character/_character)
		if(!client) return
		var/block = client.menu.control(_character)
		if(block)
			commandsDown = 0
			return
		if(commandsDown & PRIMARY)
			var/item/weapon/W = _character.equipment[WEAR_WEAPON]
			if(W) character.use(W)
		else if(commandsDown & SECONDARY)
			var/usable/U = menu.status.getHotKey(SECONDARY)
			if(U) _character.use(U)
		else if(commandsDown & TERTIARY)
			var/usable/U = menu.status.getHotKey(TERTIARY)
			if(U) _character.use(U)
		else if(commandsDown & QUATERNARY)
			var/usable/U = menu.status.getHotKey(QUATERNARY)
			if(U) _character.use(U)
		var/directions = client.macros.checkCommand(15)
		var/deltaX = 0
		var/deltaY = 0
		if(directions & NORTH) deltaY++
		if(directions & SOUTH) deltaY--
		if(directions &  EAST) deltaX++
		if(directions &  WEST) deltaX--
		if(deltaX || deltaY)
			var/speed = _character.speed()
			_character.go(deltaX*speed, deltaY*speed)
		commandsDown = 0
	commandDown(command)
		var/block = client.menu.commandDown(command)
		if(block) return
		commandsDown |= command

	//-- Transitioning Between Plots -----------------
	proc/transition(plot/newPlot)
		ASSERT(istype(newPlot))
		//var /terrain/oldTerrain = currentTerrain
		currentTerrain = terrains[newPlot.terrain]
		// Display Transition Dialogue
		//if(oldTerrain && currentTerrain.name && oldTerrain.name != currentTerrain.name)
		//	client.menu.transition(currentTerrain.name)
		//
		var/plot/plotArea/newArea = newPlot.area
		if(istype(newArea))
			// Calculate translation distance (in atomic steps)
			var /plot/currentPlot = plot(src)
			var plotDist
			if(loc && currentPlot)
				plotDist = max(
					abs(newPlot.area.x-currentPlot.area.x),
					abs(newPlot.area.y-currentPlot.area.y)
				)
			// Don't slide across entire map
			if(!loc || newArea.z != z || plotDist > PLOT_SIZE)
				forceLoc(locate(
					newArea.x + round(PLOT_SIZE/2),
					newArea.y + round(PLOT_SIZE/2),
					newArea.z
				))
			// Slide between adjacent plots
			else
				new /event/transition(src, newPlot)
		// Change Lighting
		//transitionLight(newPlot)
	//proc/transitionLight(plot/newPlot)
		//var newLight = environment.getLight(newPlot)
		//client.setLight(newLight)

	//-- HUD Refreshing ------------------------------
	proc/refresh(which, data)
		if(!client) return
		menu.refresh(which, data)


//-- RPG Menu ------------------------------------------------------------------

interface/rpg/menu
	parent_type = /component
	parent_type = /component
	icon = 'status_top.png'
	screen_loc = "1,1"
	//
	var
		interface/rpg/menu/status/status
		list/heartSprites
		list/potionSprites
		list/slots
		liftDelay = 2
	setup()
		. = ..()
		status = addComponent(/interface/rpg/menu/status)
		status.setup()
		heartSprites = new()
		potionSprites = new()
		slots = list()
		slots.len = 4
		for(var/I = 1 to slots.len)
			var/component/slot/G = addComponent(/component/slot)
			slots[I] = G
	commandDown(command)
		var/block = ..()
		if(block) return block
		if(command == BACK)
			focus(status)
	proc/transition(terrainText)
	/*	del transition
		transition = addComponent(/menu/transition)
		transition.setup(terrainText)*/
	show()
		refresh("hp")
		refresh("mp")
		refresh("slots")
		. = ..()
	proc/lift()
		// Animate Lifting
		translate(0, (240-36), liftDelay)
	proc/lower()
		// Animate Lowering
		translate(0, 0, liftDelay)
	proc/refresh(which, data)
		var/interface/rpg/interface = client.interface
		switch(which)
			if("slots")
				for(var/I = 1 to slots.len)
					var/totalX = -16 + I*24
					var/component/slot/slot = slots[I]
					slot.screen_loc = coords2ScreenLoc(totalX, 8)
				var/component/slot/slot = slots[1]
				var/item/weapon/W = interface.character.equipment[WEAR_WEAPON]
				slot.imprint(W)
				for(var/I = 1 to 3)
					var/usable/U = status.hotKeys[I]
					slot = slots[I+1]
					if(!(U in (interface.character.party.inventory + interface.character.equipment)))
						status.clearHotKey(U)
						U = null
					slot.imprint(U)
			if("hp")
				var/hpMax = interface.character.maxHp()
				var/end = max(heartSprites.len, hpMax)
				heartSprites.len = end
				for(var/I = 1 to end)
					var/interface/rpg/menu/counterSprite/heart = heartSprites[I]
					if(I > hpMax)
						heart.hide()
						del heart
						continue
					if(!heart)
						heart = addComponent(/interface/rpg/menu/counterSprite)
						heart.show()
						heartSprites[I] = heart
					var/overflow = (hpMax > 10)? -8 : 0
					heart.position(I, 12+overflow)
					var/state = "hp"
					if(I > interface.character.baseHp) state += "_shield"
					if(I > interface.character.hp      ) state += "_empty"
					heart.icon_state = state
				heartSprites.len = hpMax
			if("mp")
				var/mpMax = interface.character.maxMp()
				var/end = max(potionSprites.len, mpMax)
				potionSprites.len = end
				for(var/I = 1 to end)
					var/interface/rpg/menu/counterSprite/potion = potionSprites[I]
					if(I > mpMax)
						potion.hide()
						del potion
						continue
					if(!potion)
						potion = addComponent(/interface/rpg/menu/counterSprite)
						potion.show()
						potionSprites[I] = potion
					potion.position(I, 20)
					var/state = "mp"
					if(I > interface.character.baseMp) state += "_shield"
					if(I > interface.character.mp       ) state += "_empty"
					potion.icon_state = state
				potionSprites.len = mpMax
			if("inventory")
				status.inventory.refresh(data)
			if("equipment")
				status.equipment.refresh(data)
				if(status && status.charSelect)
					status.charSelect.imprint()
	//-- Minor Components ----------------------------
	counterSprite
		parent_type = /component/sprite
		icon = 'hud.dmi'
		proc/position(index, height)
			var/barNum = 10
			var/totalX = 148+((index-1)%barNum)*8
			var/totalY = height+round((index-1)/barNum)*8
			screen_loc = coords2ScreenLoc(totalX, totalY)


//-- Item Info ------------------------------------------------------------------

menu/itemInfo
	parent_type = /component
	autoShow = FALSE
	chrome = TRUE
	//
	var
		component/slot/slot
		component/label/itemName
		component/select/select
		list/stats
	setup(usable/usable)
		layer++
		. = ..()
		chrome(rect(3*TILE_SIZE,4*TILE_SIZE,10*TILE_SIZE,7*TILE_SIZE))
		slot = addComponent(/component/slot)
		slot.screen_loc = "4,9"
		select = addComponent(/component/select)
		itemName = addComponent(/component/label)
		itemName.screen_loc = "5:8,9:4"
		// Show Icon + Name
		slot.imprint(usable)
		itemName.imprint(usable.name)
		// Setup Options
		var /list/optionNames = list()
		optionNames["Back"] = "Back"
		if(istype(usable, /item/gear))
			var/interface/rpg/int = client.interface
			if(usable in int.menu.status.character.equipment)
				optionNames["Unequip"] = "Unequip"
			else
				optionNames["Equip"] = "Equip"
		select.setup(3*TILE_SIZE, 6*TILE_SIZE, optionNames)
		focus(select)
		// Setup Stats
		for(var/component/C in stats)
			del C
		stats = new()
		var/item/gear/G = usable
		if(istype(G))
			if(G.boostHp)
				var /component/stat/hpStat = addComponent(/component/stat)
				hpStat.imprint("hp", G.boostHp)
				stats.Add(hpStat)
			if(G.boostMp)
				var /component/stat/mpStat = addComponent(/component/stat)
				mpStat.imprint("mp", G.boostMp)
				stats.Add(mpStat)
		var/item/weapon/W = usable
		if(istype(W))
			if(W.potency)
				var /component/stat/atkStat = addComponent(/component/stat)
				atkStat.imprint("atk", W.potency)
				stats.Add(atkStat)
		var/item/shield/S = usable
		if(istype(S))
			if(S.threshold)
				var /component/stat/defStat = addComponent(/component/stat)
				defStat.imprint("def", S.threshold)
				stats.Add(defStat)
		for(var/index = 1 to stats.len)
			var /component/stat/statComponent = stats[index]
			statComponent.positionScreen(10*TILE_SIZE,  (9-index)*TILE_SIZE+4)
	hide()
		var /interface/rpg/int = client.interface
		int.menu.status.focus()
		. = ..()
		del src
	control()
		return TRUE
	commandDown(command)
		. = TRUE
		var/interface/rpg/int = client.interface
		switch(command)
			if(BACK)
				int.menu.status.focus()
				hide()
			if(NORTH, SOUTH)
				return ..()
			if(PRIMARY)
				var optionName = select.select()
				switch(optionName)
					if("Back")
						hide()
					if("Equip")
						int.menu.status.character.equip(slot.usable)
						int.menu.refresh("slots")
						hide()
					if("Unequip")
						int.menu.status.character.unequip(slot.usable)
						int.menu.refresh("slots")
						hide()


//-- Status -----------------------------------------------------------------------

interface/rpg/menu/status
	parent_type = /component
	icon = 'status_bottom.png'
	screen_loc = "1,1"
	autoShow = FALSE
	var
		component/box/equipment
		component/box/inventory
		interface/rpg/menu/status/charSelect/charSelect
		list/hotKeys[3]
		menu/itemInfo/itemInfo
		component/box/lastFocus
		//
		character/character
	setup()
		. = ..()
		equipment = addComponent(/component/box)
		inventory = addComponent(/component/box)
		charSelect = addComponent(/interface/rpg/menu/status/charSelect)
		equipment.setup( 16, 160, 4, 1)
		inventory.setup(116, 16, 6, 9)
		charSelect.setup()

	//-- Visibility Triggers -------------------------
	show()
		. = ..()
		var/interface/rpg/int = client.interface
		int.menu.lift()
		focus(inventory)
		moveCursor()
		// Setup Character
		if(int.character.party.mainCharacter == int.character)
			imprint(int.character, int.character.party)
		else
			imprint(int.character)
		// Animate Lifting
		translate(0, -(240-32))
		translate(0, 0, int.menu.liftDelay)
	hide()
		var/interface/rpg/int = client.interface
		for(var/component/box/B in list(equipment, inventory))
			B.cursor.screen_loc = null
		int.menu.lower()
		// Animate Lowering
		var lowerDelay = int.menu? int.menu.liftDelay : 0
		translate(0, -(240-32), lowerDelay)
		spawn(lowerDelay)
			. = ..()
	focus(component/box/newFocus)
		if(istype(focus, /component/box))
			lastFocus = focus
		if(!newFocus && lastFocus)
			return focus(lastFocus)
		. = ..()

	//-- Character Imprinting ------------------------
	proc/imprint(character/newChar, party/_party)
		character = newChar
		var /interface/rpg/int = client.interface
		//
		charSelect.imprint(character, _party)
		int.refresh("equipment", character.equipment)

	//-- Controls-------------------------------------
	control(_character)
		return TRUE // Block
	commandDown(command)
		var/interface/rpg/int = client.interface
		// Control box if they're focused
		if(focus in list(inventory, equipment))
			switch(command)
			// Move Cursor
				if(1 to 16)
					moveCursor(command)
					return TRUE
			// Select Item or put in hotKey
				if(PRIMARY, SECONDARY, TERTIARY, QUATERNARY)
					select(client, int.character, command)
					int.menu.refresh("hp"   , null, int)
					int.menu.refresh("mp"   , null, int)
					int.menu.refresh("slots", null, int)
					return TRUE
		// Otherwise check for blocks
		var/block = ..()
		if(block) return block
		. = TRUE
		switch(command)
			// Move out of character screen
			if(NORTH)
				equipment.position = 2
				focus(equipment)
			if(EAST)
				inventory.position = inventory.width*3+1
				focus(inventory)
			// Check for cancel / escape menu
			if(BACK)
				hide()
				int.menu.focus()
				return TRUE

	proc/select(client/client, character/character, hotKey)
		// Selects a usable from a box (inventory, equipment, skills)
		// Get usable from box
		var /component/box/activeBox = focus
		if(!istype(activeBox)) return
		var /usable/selection = activeBox.select()
		if(!selection) return
		// Inspect item if command is PRIMARY
		if(hotKey == PRIMARY)
			if(activeBox == inventory || activeBox == equipment)
				itemInfo = addComponent(/menu/itemInfo)
				itemInfo.setup(selection)
				focus(itemInfo)
				//selection.use(character)
		// Otherwise send it to a hotKey
		else
			var/hkIndex
			switch(hotKey)
				if(SECONDARY ) hkIndex = 1
				if(TERTIARY  ) hkIndex = 2
				if(QUATERNARY) hkIndex = 3
			hotKeys[hkIndex] = selection

	proc/moveCursor(direction)
		// Try to move the focus' cursor
		var /component/box/B = focus
		if(!istype(B))
			return
		var success = B.moveCursor(direction)
		if(success)
			B.positionCursor()
			return
		// If it didn't move, change focus to different box
		if(B == inventory)
			if(direction == WEST)
				if(inventory.position <= inventory.width)
					equipment.position = equipment.width
					focus(equipment)
				else
					focus(charSelect)
		else if(B == equipment)
			if(direction == SOUTH)
				focus(charSelect)
			else if(direction == EAST)
				inventory.position = 1
				focus(inventory)
		// Reposition and show box's cursor
		B = focus
		if(istype(B))
			B.positionCursor()

	//-- Hot Key Utilities ---------------------------
	proc/getHotKey(command)
		var/hkIndex
		switch(command)
			if(SECONDARY ) hkIndex = 1
			if(TERTIARY  ) hkIndex = 2
			if(QUATERNARY) hkIndex = 3
		return hotKeys[hkIndex]
	proc/clearHotKey(usable/U)
		for(var/I = 1 to 3)
			if(hotKeys[I] == U) hotKeys[I] = null

	//-- Character Select - Subcomponent -------------
	charSelect
		parent_type = /component
		var
			component/sprite/portrait
			component/label/characterName
			component/sprite/left
			component/sprite/right
			list/stats
			//
			party/party
			character/character
		setup()
			left  = addComponent(/component/sprite)
			right = addComponent(/component/sprite)
			portrait = addComponent(/component/sprite)
			characterName = addComponent(/component/label)
			left.positionScreen( 16, 90)
			right.positionScreen(74, 90)
			portrait.positionScreen(29, 74)
			characterName.positionScreen(18, 60)
			portrait.icon = 'portraits.dmi'
			left.imprint( 'specials.dmi', "pointer_left" )
			right.imprint('specials.dmi', "pointer_large")
			stats = new()
			var /list/statList = list("hp","mp","atk","def")
			for(var/index = 1 to statList.len)
				var statName = statList[index]
				var /component/stat/stati = addComponent(/component/stat)
				stati.imprint(statName, "-")
				var posY = 44 - round((index-1)/2)*12
				if(index%2)
					stati.positionScreen(22, posY)
				else
					stati.positionScreen(62, posY)
				stats[statName] = stati
		proc/imprint(character/char, party/_party)
			if(_party)
				party = _party
			if(char)
				character = char
			if(!character) return
			portrait.icon_state = character.portrait
			characterName.imprint(character.name, 9*8, null, "center")
			if(party && party.characters.len > 1)
				left.show()
				right.show()
			//
			for(var/key in stats)
				var /component/stat/stati = stats[key]
				switch(key)
					if("hp" )
						stati.imprint(key, character.maxHp())
					if("mp" )
						var max = character.maxMp()
						stati.imprint(key, max? max : "-")
					if("atk")
						var /item/weapon/W = character.equipment[WEAR_WEAPON]
						if(istype(W)) stati.imprint(key, W.potency)
						else stati.imprint(key, "-")
					if("def")
						var /item/shield/S = character.equipment[WEAR_SHIELD]
						if(istype(S)) stati.imprint(key, S.threshold)
						else stati.imprint(key, "-")
		show()
			. = ..()
			if(!party || party.characters.len <= 1)
				left.hide()
				right.hide()
			var colorList = list(0.7,0.4,0.4, 0.5,0.7,0.5, 0.1,0.1,0.1, 0,0,0)
			animate(portrait, color = colorList, 5)
		hide()
			. = ..()
			character = null
			party = null
		focused()
			animate(portrait, color = "#fff", 5)
		blurred()
			var colorList = list(0.7,0.4,0.4, 0.5,0.7,0.5, 0.1,0.1,0.1, 0,0,0)
			animate(portrait, color = colorList, 5)
		control(_character)
			return TRUE // Block
		commandDown(command)
			var/block = ..()
			if(block) return block
			. = TRUE
			//
			switch(command)
				if(BACK)
					return FALSE
				if(NORTH)
					return FALSE
				if(EAST)
					if(!party)
						return FALSE
					var partyIndex = party.characters.Find(character)
					partyIndex++
					if(partyIndex > party.characters.len)
						partyIndex = 1
					var /interface/rpg/int = client.interface
					int.menu.status.imprint(party.characters[partyIndex])
					return TRUE
				if(WEST)
					if(!party)
						return FALSE
					var partyIndex = party.characters.Find(character)
					partyIndex--
					if(partyIndex <= 0)
						partyIndex = party.characters.len
					var /interface/rpg/int = client.interface
					int.menu.status.imprint(party.characters[partyIndex])
					return TRUE

