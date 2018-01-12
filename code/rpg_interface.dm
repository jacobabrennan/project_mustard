

//-- RPG - The main interface used while playing -------------------------------

rpg
	parent_type = /interface
	var
		rpg/menu/menu
		character/partyMember/character
		event/transition/transitionEvent
		commandsDown = 0
		// Logs commands pressed between calls to control()
		terrain/currentTerrain

	//-- Connection & Spectating ---------------------
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
		menu = client.menu.addComponent(/rpg/menu)
		menu.setup()
		menu.show(src)
		menu.refresh("inventory")
		menu.refresh("equipment", character)
		client.menu.focus(menu)
		// Transition client to plot
		var /plot/currentPlot = plot(character)
		if(currentPlot)
			transition(currentPlot)
	Logout()
		// Hide Menu
		menu.hide()
		del menu
		. = ..()
	proc/spectate()
		var /game/G = game(src)
		if(!G) G = game(character.party)
		character.interface = null
		G.addSpectator(client)

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
			var/usable/U = character.getHotKey(SECONDARY)
			if(U) _character.use(U)
		else if(commandsDown & TERTIARY)
			var/usable/U = character.getHotKey(TERTIARY)
			if(U) _character.use(U)
		else if(commandsDown & QUATERNARY)
			var/usable/U = character.getHotKey(QUATERNARY)
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

	//-- Convenience Utilities -----------------------
	proc/isMain()
		if(character == character.party.mainCharacter)
			return TRUE

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


//-- RPG Menu ------------------------------------------------------------------

rpg/menu
	parent_type = /component
	parent_type = /component
	icon = 'status_top.png'
	screen_loc = "1,1"
	//
	var
		rpg/menu/paneSelect/paneSelect
		rpg/menu/gear/gear
		rpg/menu/party/party
		list/heartSprites
		list/potionSprites
		list/slots
		paneDelay = 2
	setup()
		. = ..()
		paneSelect = addComponent(/rpg/menu/paneSelect)
		paneSelect.setup()
		gear = addComponent(/rpg/menu/gear)
		gear.setup()
		heartSprites = new()
		potionSprites = new()
		slots = list()
		slots.len = 4
		for(var/I = 1 to slots.len)
			var/component/slot/G = addComponent(/component/slot)
			slots[I] = G
			var/totalX = -16 + I*24
			var/component/slot/slot = slots[I]
			slot.screen_loc = coords2ScreenLoc(totalX, 8)
			slot.imprint(new /item/shield)
		var /rpg/int = client.interface
		if(int.isMain())
			party = addComponent(/rpg/menu/party)
			party.setup(int.character.party)
	show()
		var /rpg/int = client.interface
		refresh("hp", int.character)
		refresh("mp", int.character)
		refresh("slots", int.character)
		. = ..()

	//-- Control -------------------------------------
	commandDown(command)
		var/block = ..()
		if(block) return block
		if(command == BACK)
			lift()
			focus(gear)
			gear.translateIn(NORTH)

	//-- Menu Movement Animations --------------------
	proc
		lift()
			// Animate Lifting
			var /rpg/int = client.interface
			translate(0, 240-36, paneDelay)
			if(paneSelect && int.isMain())
				paneSelect.position = 2
				paneSelect.show()
			gear.focus(gear.inventory)
		lower()
			// Animate Lowering
			translate(0, 0, paneDelay)
			var /rpg/int = client.interface
			if(paneSelect && int.isMain()) paneSelect.hide()

	//-- Display Changes -----------------------------
	//proc/transition(terrainText)
		/*del transition
		transition = addComponent(/menu/transition)
		transition.setup(terrainText)*/
	proc/refresh(which, character/partyMember/updateChar)
		var/rpg/interface = client.interface
		switch(which)
			if("slots")
				// Does not include weapon slot. Covered in "equipment"
				if(updateChar && interface.character != updateChar) return
				for(var/I = 1 to 3)
					var/usable/U = interface.character.hotKeys[I]
					var/component/slot/slot = slots[I+1]
					slot.imprint(U)
			if("inventory")
				gear.inventory.refresh(interface.character.party.inventory)
			if("equipment")
				// Update Weapon Hot Key
				if(updateChar == interface.character)
					var/component/slot/slot = slots[1]
					var/item/weapon/W = updateChar.equipment[WEAR_WEAPON]
					slot.imprint(W)
				//
				if(!updateChar)
					updateChar = interface.character
				// Update Gear equipment list
				gear.equipment.refresh(updateChar.equipment)
				// Update Character Portrait Area
				if(gear && gear.charSelect)
					gear.charSelect.imprint()
			if("hp", "mp")
				if(updateChar && interface.character != updateChar) return
				updateChar = interface.character
				//
				var /list/sprites
				var statMax
				var baseStat
				var currentStat
				if(which == "hp")
					sprites = heartSprites
					statMax = updateChar.maxHp()
					baseStat = updateChar.baseHp
					currentStat = updateChar.hp
				else
					sprites = potionSprites
					statMax = updateChar.maxMp()
					baseStat = updateChar.baseMp
					currentStat = updateChar.mp
				//
				var/end = max(sprites.len, statMax)
				sprites.len = end
				//
				for(var/I = 1 to end)
					var /rpg/menu/counterSprite/S = sprites[I]
					if(I > statMax)
						S.hide()
						del S
						continue
					if(!S)
						S = addComponent(.counterSprite)
						S.show()
						sprites[I] = S
					if(which == "hp")
						var/overflow = (statMax > 10)? -8 : 0
						S.position(I, 12+overflow)
					else
						S.position(I, 20)
					var state = which
					if(I > baseStat   ) state += "_shield"
					if(I > currentStat) state += "_empty"
					S.icon_state = state
				sprites.len = statMax

	//-- Minor Components ----------------------------
	counterSprite
		parent_type = /component/sprite
		icon = 'menu8.dmi'
		proc/position(index, height)
			var/barNum = 10
			var/totalX = 148+((index-1)%barNum)*8
			var/totalY = height+round((index-1)/barNum)*8
			screen_loc = coords2ScreenLoc(totalX, totalY)
	pane
		parent_type = /component
		var
			_translateActive
		proc
			translateIn(direction)
				var/rpg/int = client.interface
				show()
				var restHeight = 0
				if(!int.isMain()) restHeight += 18
				switch(direction)
					if(NORTH) translate(   0, -(240-36))
					if(EAST ) translate( 240, 0)
					if(WEST ) translate(-240, 0)
				translate(0, restHeight, int.menu.paneDelay)
			translateOut(direction)
				shown = FALSE
				var/rpg/int = client.interface
				var lowerDelay = int.menu? int.menu.paneDelay : 0
				switch(direction)
					if(SOUTH) translate(   0, -(240-36), lowerDelay)
					if(EAST ) translate( 240,         0, lowerDelay)
					if(WEST ) translate(-240,         0, lowerDelay)
				spawn(lowerDelay)
					if(shown) return
					shown = TRUE
					hide()

	//-- Pane Select - Subcomponent ------------------
	paneSelect
		parent_type = /component/box
		autoShow = FALSE
		setup()
			..(85, 186, 4, 1)
			//
			var /usable/option1 = new()
			option1.icon = 'menu16.dmi'
			option1.icon_state = "paneMap"
			var /usable/option2 = new()
			option2.icon = 'menu16.dmi'
			option2.icon_state = "paneGear"
			var /usable/option3 = new()
			option3.icon = 'menu16.dmi'
			option3.icon_state = "paneParty"
			var /usable/option4 = new()
			option4.icon = 'menu16.dmi'
			option4.icon_state = "paneGame"
			//
			refresh(list(option1, option2, option3, option4))
		//
		translate(dX, dY, time, override)
			if(!override) return
			. = ..()
		show()
			var lift = !shown
			. = ..()
			if(!lift)
				return
			var /rpg/int = client.interface
			// Animate Lifting
			var liftHeight = 240-36
			var offsetX = 9 // Nudge into position, from positionCursor. (TILE_SIZE+buffer)/2
			translate(offsetX, -liftHeight, null, TRUE)
			translate(offsetX, 0, int.menu.paneDelay, TRUE)
			positionCursor()
			cursor.screen_loc = null
		hide()
			var /rpg/int = client.interface
			// Animate Lowering
			var lowerDelay = int.menu? int.menu.paneDelay : 0
			translate(0, -(240-36), lowerDelay, TRUE)
			cursor.screen_loc = null
			shown = FALSE
			spawn(lowerDelay)
				if(shown) return
				. = ..()
		//
		commandDown(command)
			. = ..()
			if(command == BACK)
				moveCursor(NORTH)
				return TRUE
		moveCursor(direction)
			var oldPosition = position
			. = ..()
			var /rpg/int = client.interface
			if(!.)
				switch(direction)
					if(NORTH)
						int.menu.lower()
						int.menu.focus()
						switch(position)
							if(2) int.menu.gear.translateOut(SOUTH)
							if(3) int.menu.party.translateOut(SOUTH)
						return TRUE
					if(SOUTH)
						blurred()
						switch(position)
							if(2)
								int.menu.gear.inventory.position = 1
								int.menu.gear.focus(int.menu.gear.inventory)
								int.menu.focus(int.menu.gear)
							if(3)
								int.menu.focus(int.menu.party)
						return TRUE
				return TRUE
			switch(oldPosition)
				if(2) int.menu.gear.translateOut( turn(direction, 180))
				if(3) int.menu.party.translateOut(turn(direction, 180))
			switch(position)
				if(2) int.menu.gear.translateIn( direction)
				if(3) int.menu.party.translateIn(direction)


		positionCursor()
			. = ..()
			var offsetX = (2.5 - position)*18
			translate(offsetX, 0, null, TRUE)