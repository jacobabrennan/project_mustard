

//-- RPG - The main interface used while playing -------------------------------

interface/rpg
	var
		character/partyMember/character
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
		// Transition client to plot
		var /plot/currentPlot = plot(character)
		if(currentPlot)
			transition(currentPlot)
		// Refresh and show menu
		client.menu.hud.show(src)
		client.menu.refresh("inventory", character.party.inventory)
		client.menu.refresh("equipment", character.equipment)

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
			var/usable/U = client.menu.status.getHotKey(SECONDARY)
			if(U) _character.use(U)
		else if(commandsDown & TERTIARY)
			var/usable/U = client.menu.status.getHotKey(TERTIARY)
			if(U) _character.use(U)
		else if(commandsDown & QUATERNARY)
			var/usable/U = client.menu.status.getHotKey(QUATERNARY)
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
		var /terrain/oldTerrain = currentTerrain
		currentTerrain = terrains[newPlot.terrain]
		// Display Transition Dialogue
		if(oldTerrain && currentTerrain.name && oldTerrain.name != currentTerrain.name)
			client.menu.transition(currentTerrain.name)
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
		client.menu.refresh(which, data)


//-- RPG Menu ------------------------------------------------------------------

menu
	var
		menu/hud/hud
		menu/status/status
		menu/transition/transition
		liftDelay = 2
	setup()
		hud = addComponent(/menu/hud)
		hud.setup()
		status = addComponent(/menu/status)
		status.setup()
	commandDown(command)
		var/block = ..()
		if(block) return block
		if(command == STATUS)
			ASSERT(client)
			focus(status)
	proc/refresh(which, data)
		switch(which)
			if("hp","mp","slots") hud.refresh(which)
			else status.refresh(which, data)
	proc/transition(terrainText)
		del transition
		transition = addComponent(/menu/transition)
		transition.setup(terrainText)


//-- Hud -----------------------------------------------------------------------

menu/hud
	parent_type = /component
	icon = 'status_top.png'
	screen_loc = "1,1"
	//
	var
		list/heartSprites
		list/potionSprites
		list/slots
		component/sprite/coinIcon
		component/label/coinLabel
	setup()
		. = ..()
		heartSprites = new()
		potionSprites = new()
		coinIcon = addComponent(/component/sprite)
		coinLabel = addComponent(/component/label)
		coinIcon.icon = 'hud.dmi'
		coinIcon.icon_state = "coin"
		slots = list()
		slots.len = 4
		for(var/I = 1 to slots.len)
			var/component/slot/G = addComponent(/component/slot)
			slots[I] = G
			//G.layer++
	counterSprite
		parent_type = /component/sprite
		icon = 'hud.dmi'
		proc/position(index, height)
			var/barNum = 10
			var/totalX = 148+((index-1)%barNum)*8
			var/totalY = height+round((index-1)/barNum)*8
			screen_loc = coords2ScreenLoc(totalX, totalY)
	show()
		refresh("hp")
		refresh("mp")
		refresh("slots")
		. = ..()
	proc/lift()
		// Animate Lifting
		translate(0, (240-36), client.menu.liftDelay)
	proc/lower()
		// Animate Lowering
		translate(0, 0, client.menu.liftDelay)
	proc/refresh(which)
		var/interface/rpg/interface = client.interface
		switch(which)
			if("slots")
				for(var/I = 1 to slots.len)
					var/totalX = -16 + I*24
					var/component/slot/slot = slots[I]
					slot.screen_loc = coords2ScreenLoc(totalX, 8)
				var/component/slot/slot = slots[1]
				var/item/weapon/W = client.menu.status.equipment.slots[WEAR_WEAPON]
				slot.imprint(W)
				for(var/I = 1 to 3)
					var/usable/U = client.menu.status.hotKeys[I]
					slot = slots[I+1]
					if(!(U in (interface.character.party.inventory + interface.character.equipment)))
						client.menu.status.clearHotKey(U)
						U = null
					slot.imprint(U)
			if("hp")
				var/hpMax = interface.character.maxHp()
				var/end = max(heartSprites.len, hpMax)
				heartSprites.len = end
				for(var/I = 1 to end)
					var/menu/hud/counterSprite/heart = heartSprites[I]
					if(I > hpMax)
						heart.hide()
						del heart
						continue
					if(!heart)
						heart = addComponent(/menu/hud/counterSprite)
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
					var/menu/hud/counterSprite/potion = potionSprites[I]
					if(I > mpMax)
						potion.hide()
						del potion
						continue
					if(!potion)
						potion = addComponent(/menu/hud/counterSprite)
						potion.show()
						potionSprites[I] = potion
					potion.position(I, 20)
					var/state = "mp"
					if(I > interface.character.baseMp) state += "_shield"
					if(I > interface.character.mp       ) state += "_empty"
					potion.icon_state = state
				potionSprites.len = mpMax


//-- Status -----------------------------------------------------------------------

menu/status
	parent_type = /component
	//
	icon = 'status_bottom.png'
	screen_loc = "1,1"
	autoShow = FALSE
	//
	var
		component/box/equipment
		component/box/inventory
		menu/status/character/character
		list/hotKeys[3]
		menu/itemInfo/itemInfo
		component/box/lastFocus
	setup()
		. = ..()
		equipment = addComponent(/component/box)
		inventory = addComponent(/component/box)
		character = addComponent(/menu/status/character)
		equipment.setup( 16, 160, 4, 1)
		inventory.setup(116, 16, 6, 9)
		character.setup( 16, 16)
	focus(component/box/newFocus)
		if(istype(focus, /component/box))
			lastFocus = focus
		if(!newFocus && lastFocus)
			return focus(lastFocus)
		. = ..()
	show()
		. = ..()
		if(client.menu && client.menu.hud) client.menu.hud.lift()
		focus(inventory)
		moveCursor()
		// Setup Character Display
		var /interface/rpg/int = client.interface
		if(int.character.party.mainCharacter == int.character)
			character.imprint(int.character, int.character.party)
		// Animate Lifting
		translate(0, -(240-32))
		translate(0, 0, client.menu.liftDelay)
	hide()
		for(var/component/box/B in list(equipment, inventory))
			B.cursor.screen_loc = null
		if(client.menu && client.menu.hud) client.menu.hud.lower()
		// Animate Lowering
		var lowerDelay = client.menu? client.menu.liftDelay : 0
		translate(0, -(240-32), lowerDelay)
		spawn(lowerDelay)
			. = ..()
	proc/refresh(which, list/usables)
		switch(which)
			if("inventory")
				inventory.refresh(usables)
			if("equipment")
				equipment.refresh(usables)
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
					focus(character)
		else if(B == equipment)
			if(direction == SOUTH)
				focus(character)
			else if(direction == EAST)
				inventory.position = 1
				focus(inventory)
		// Reposition and show box's cursor
		B = focus
		if(istype(B))
			B.positionCursor()
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
					client.menu.refresh("hp"   , null, int)
					client.menu.refresh("mp"   , null, int)
					client.menu.refresh("slots", null, int)
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
			if(STATUS)
				hide()
				client.menu.focus()
				return TRUE
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
	//
	character
		parent_type = /component
		var
			component/sprite/portrait
			component/label/characterName
			component/sprite/left
			component/sprite/right
			party/party
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
		proc/imprint(character/char, party/_party)
			party = _party
			portrait.icon_state = char.portrait
			characterName.imprint(char.name, 9*8, null, "center")
			blurred()
			if(party)
				left.show()
				right.show()
		show()
			. = ..()
			if(!party)
				left.hide()
				right.hide()
		hide()
			. = ..()
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
				if(STATUS)
					return FALSE
				if(NORTH)
					return FALSE
				if(EAST)
					if(!party)
						return FALSE


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
		list/statLabels
		list/statIcons
	setup(usable/usable)
		layer++
		. = ..()
		chrome(rect(3*TILE_SIZE,4*TILE_SIZE,10*TILE_SIZE,7*TILE_SIZE))
		slot = addComponent(/component/slot)
		slot.screen_loc = "4,10"
		select = addComponent(/component/select)
		itemName = addComponent(/component/label)
		itemName.screen_loc = "5:8,10:4"
		// Show Icon + Name
		slot.imprint(usable)
		itemName.imprint(usable.name)
		// Setup Options
		var /list/optionNames = list()
		optionNames["Back"] = "Back"
		if(istype(usable, /item/gear))
			var/interface/rpg/int = client.interface
			if(usable in int.character.equipment)
				optionNames["Unequip"] = "Unequip"
			else
				optionNames["Equip"] = "Equip"
		select.setup(3*TILE_SIZE, 7*TILE_SIZE, optionNames)
		focus(select)
		// Setup Stats
		for(var/component/C in statLabels+statIcons)
			del C
		statLabels = new()
		statIcons = new()
		var/item/gear/G = usable
		if(istype(G))
			if(G.boostHp)
				var/component/label/hpLabel = addComponent(/component/label)
				hpLabel.imprint(G.boostHp)
				var/component/sprite/hpIcon = addComponent(/component/sprite)
				hpIcon.icon = 'stats.dmi'
				hpIcon.icon_state = "hp"
				statLabels.Add(hpLabel)
				statIcons.Add(hpIcon)
			if(G.boostMp)
				var/component/label/mpLabel = addComponent(/component/label)
				mpLabel.imprint(G.boostMp)
				var/component/sprite/mpIcon = addComponent(/component/sprite)
				mpIcon.icon = 'stats.dmi'
				mpIcon.icon_state = "mp"
				statLabels.Add(mpLabel)
				statIcons.Add(mpIcon)
		var/item/weapon/W = usable
		if(istype(W))
			if(W.potency)
				var/component/label/_label = addComponent(/component/label)
				_label.imprint(W.potency)
				var/component/sprite/_icon = addComponent(/component/sprite)
				_icon.icon = 'stats.dmi'
				_icon.icon_state = "atk"
				statLabels.Add(_label)
				statIcons.Add(_icon)
		for(var/index = 1 to statIcons.len)
			var/component/sprite/statIcon = statIcons[index]
			var/component/label/statLabel = statLabels[index]
			statIcon.screen_loc = "11,[11-index]:4"
			statLabel.screen_loc = "12,[11-index]:4"
			#warn SCREEN_LOCS GALORE!
	hide()
		client.menu.status.focus()
		. = ..()
		del src
	control()
		return TRUE
	commandDown(command)
		. = TRUE
		var/interface/rpg/int = client.interface
		switch(command)
			if(STATUS)
				client.menu.status.focus()
				hide()
			if(NORTH, SOUTH)
				return ..()
			if(PRIMARY)
				var optionName = select.select()
				switch(optionName)
					if("Back")
						hide()
					if("Equip")
						int.character.equip(slot.usable)
						client.menu.refresh("slots")
						hide()
					if("Unequip")
						int.character.unequip(slot.usable)
						client.menu.refresh("slots")
						hide()