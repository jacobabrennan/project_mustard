

//-- Gear - Equipment & Inventory ----------------------------------------------

rpg/menu/gear
	parent_type = /rpg/menu/pane
	icon = 'menu_gear.png'
	screen_loc = "1,1"
	autoShow = FALSE
	var
		component/box/equipment
		component/box/inventory
		rpg/menu/gear/charSelect/charSelect
		rpg/menu/gear/itemInfo/itemInfo
		//component/box/lastFocus
		//
		character/character
	setup()
		. = ..()
		equipment = addComponent(/component/box)
		inventory = addComponent(/component/box)
		charSelect = addComponent(/rpg/menu/gear/charSelect)
		equipment.setup( 16, 142, 4, 1)
		inventory.setup(116, 16, 6, 8)
		charSelect.setup()

	//-- Visibility Triggers -------------------------
	show()
		. = ..()
		var/rpg/int = client.interface
		int.menu.paneSelect.position = 2
		// Setup Character
		if(int.character.party.mainCharacter == int.character)
			refreshCharacter(int.character, int.character.party)
		else
			refreshCharacter(int.character)

	//-- Refresh Display with new Data ---------------
	proc
		refreshCharacter(character/newChar, party/_party)
			character = newChar
			var /rpg/int = client.interface
			//
			charSelect.imprint(character, _party)
			int.menu.refresh("equipment", character)
		refreshInventory(list/_inventory)
			inventory.refresh(_inventory)
			if(!itemInfo) return
			var /item/viewingItem = itemInfo.slot.storage
			if(!(viewingItem in _inventory))
				focus()
				itemInfo.hide() // Handles deleting

	//-- Controls-------------------------------------
	control(_character)
		return TRUE // Block
	commandDown(command)
		var/rpg/int = client.interface
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
					int.menu.refresh("hp"   )
					int.menu.refresh("mp"   )
					int.menu.refresh("hotKeys")
					return TRUE
		// Otherwise check for blocks
		var/block = ..()
		if(block) return block
		. = TRUE
		// If in item info, just return
		if(itemInfo && focus == itemInfo)
			return
		//
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
				int.menu.lower()
				int.menu.focus()
				translateOut(SOUTH)
				return TRUE

	proc/select(client/client, character/partyMember/character, hotKey)
		// Selects a usable from a box (inventory, equipment, skills)
		// Get usable from box
		var /component/box/activeBox = focus
		if(!istype(activeBox)) return
		var /usable/selection = activeBox.select()
		// Inspect item if command is PRIMARY
		if(hotKey == PRIMARY)
			if(!selection) return
			if(activeBox == inventory || activeBox == equipment)
				showItem(selection)
			return
		// If selection is null, clear hot key
		if(!selection)
			character.setHotKey(null, hotKey)
		// Do not allow hot key items from equipment
		if(activeBox == equipment) return
		// Set Hot Key
		character.setHotKey(selection, hotKey)

	proc/moveCursor(direction)
		// Try to move the focus' cursor
		var /component/box/B = focus
		if(!istype(B))
			return
		var success = B.moveCursor(direction)
		if(success)
			B.positionCursor()
			return
		// If we're at the top, highlight the pane selector
		var /rpg/int = client.interface
		if(direction == NORTH && focus != charSelect)
			if(int.isMain())
				focus(int.menu.paneSelect)
				focus = null
				int.menu.focus(int.menu.paneSelect)
				return TRUE
		// If it didn't move, change focus to different box
		else if(B == inventory)
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

	proc/showItem(item/selection)
		itemInfo = addComponent(/rpg/menu/gear/itemInfo)
		itemInfo.setup(selection)
		focus(itemInfo)
		spawn()
			focus(itemInfo)

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
			left.positionScreen( 16, 74)
			right.positionScreen(74, 74)
			portrait.positionScreen(29, 58)
			characterName.positionScreen(18, 45)
			portrait.icon = 'portraits.dmi'
			left.imprint( 'menu16.dmi', "pointer_left" )
			right.imprint('menu16.dmi', "pointer_large")
			stats = new()
			var /list/statList = list("hp","mp","atk","def")
			for(var/index = 1 to statList.len)
				var statName = statList[index]
				var /component/stat/stati = addComponent(/component/stat)
				stati.imprint(statName, "-")
				var posY = 31 - round((index-1)/2)*12
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
					var /rpg/int = client.interface
					int.menu.gear.refreshCharacter(party.characters[partyIndex])
					return TRUE
				if(WEST)
					if(!party)
						return FALSE
					var partyIndex = party.characters.Find(character)
					partyIndex--
					if(partyIndex <= 0)
						partyIndex = party.characters.len
					var /rpg/int = client.interface
					int.menu.gear.refreshCharacter(party.characters[partyIndex])
					return TRUE

	//-- Item Info - Item inspecting subcomponent-----
	itemInfo
		parent_type = /component
		autoShow = FALSE
		chrome = TRUE
		//
		var
			component/slot/slot
			component/label/itemName
			component/select/select
			list/stats
			//
			component/box/storageFocus
		setup(usable/usable)
			var /rpg/int = client.interface
			storageFocus = int.menu.gear.focus
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
				if(usable in int.menu.gear.character.equipment)
					optionNames["Unequip"] = "Unequip"
				else if(int.menu.gear.character.canEquip(usable))
					optionNames["Equip"] = "Equip"
			select.setup(3*TILE_SIZE, 6*TILE_SIZE, optionNames)
			focus(select)
			// Setup Stats
			for(var/component/C in stats)
				del C
			stats = new()
			var /item/gear/G = usable
			if(istype(G))
				if(G.boostHp)
					var /component/stat/hpStat = addComponent(/component/stat)
					hpStat.imprint("hp", G.boostHp)
					stats.Add(hpStat)
				if(G.boostMp)
					var /component/stat/mpStat = addComponent(/component/stat)
					mpStat.imprint("mp", G.boostMp)
					stats.Add(mpStat)
			var /item/weapon/W = usable
			if(istype(W))
				if(W.potency)
					var /component/stat/atkStat = addComponent(/component/stat)
					atkStat.imprint("atk", W.potency)
					stats.Add(atkStat)
			var /item/shield/S = usable
			if(istype(S))
				if(S.threshold)
					var /component/stat/defStat = addComponent(/component/stat)
					defStat.imprint("def", S.threshold)
					stats.Add(defStat)
			for(var/index = 1 to stats.len)
				var /component/stat/statComponent = stats[index]
				statComponent.positionScreen(10*TILE_SIZE,  (9-index)*TILE_SIZE+4)
		hide()
			var /rpg/int = client.interface
			int.menu.gear.focus(storageFocus)
			. = ..()
			del src
		control()
			return TRUE
		commandDown(command)
			. = TRUE
			var /rpg/int = client.interface
			switch(command)
				if(BACK)
					int.menu.gear.focus()
					hide()
				if(NORTH, SOUTH)
					return ..()
				if(PRIMARY)
					var optionName = select.select()
					switch(optionName)
						if("Back")
							hide()
						if("Equip")
							int.menu.gear.character.equip(slot.storage)
							int.menu.refresh("equipment", int.menu.gear.character)
							hide()
						if("Unequip")
							int.menu.gear.character.unequip(slot.storage)
							int.menu.refresh("equipment", int.menu.gear.character)
							hide()

/*	|
	|
	|
	|
	|
	|
	|
	|
	|
	|*/


//-- Party - Manager Players in Party ------------------------------------------

rpg/menu/party
	parent_type = /rpg/menu/pane
	autoShow = FALSE
	var
		component/label/title
		component/box/characters
		component/select/spectators
		component/label/modal
	setup()
		. = ..()
		title = addComponent(/component/label)
		title.imprint("Edit&nbsp;Players")
		title.positionScreen(16, 165)
		characters = addComponent(/component/box)
		characters.setup(32, 102, 1, COMPANIONS_MAX)
		spectators = addComponent(/component/select)
		spectators.setup(56, 138, null, 8)
		chrome(rect(16,16,224,173))
	show()
		. = ..()
		focus(characters)
		// Show Character Options
		var /game/G = game(client.interface)
		var list/charList = G.party.characters.Copy()
		charList.Remove(G.party.mainCharacter)
		characters.refresh(charList)
		//
		showPlayers()
		characters.cursor.hide()
		spectators.cursor.hide()
	focused()
		. = ..()
		characters.cursor.show()
	blurred()
		. = ..()
		characters.cursor.hide()
		spectators.cursor.hide()
	commandDown(command)
		. = ..()
		if(.) return
		var/rpg/int = client.interface
		switch(command)
			if(BACK)
				if(focus == modal)
					showPlayers()
					del modal
					focus(characters)
					return TRUE
				else if(focus == spectators)
					showPlayers()
					focus(characters)
				else
					int.menu.lower()
					int.menu.focus()
					translateOut(SOUTH)
				return TRUE
			if(NORTH)
				if(focus == spectators) return TRUE
				int.menu.focus(int.menu.paneSelect)
				return TRUE
			if(WEST)
				if(focus == spectators)
					showPlayers()
					focus(characters)
					return TRUE
			if(EAST)
				if(focus == characters)
					var /character/partyMember/selectChar = characters.select()
					if(!istype(selectChar))
						diag(selectChar)
						return TRUE
					showSpectators(selectChar)
					return TRUE
			if(PRIMARY)
				if(focus == modal)
					showPlayers()
					del modal
					focus(characters)
					return TRUE
				else if(focus == characters)
					var /character/partyMember/selectChar = characters.select()
					if(!istype(selectChar))
						diag(selectChar)
						return TRUE
					showSpectators(selectChar)
					return TRUE
				else if(focus == spectators)
					var /character/partyMember/selectChar = characters.select()
					var /game/spectator/selectator = spectators.select()
					select(selectChar, selectator)
					return TRUE
	proc
		showPlayers()
			var list/playerList = new()
			for(var/sIndex = 1 to characters.slots.len)
				var /component/slot/S = characters.slots[sIndex]
				var /character/partyMember/member = S.storage
				var shortKey = "   "
				if(!member.interface)
					shortKey = copytext(shortKey, 1, sIndex+1)
				else
					shortKey = copytext(member.interface.key, 1, 21)
				playerList[shortKey] = null
			spectators.refresh(playerList)
		showSpectators(character/partyMember/selectChar)
			// Prepare List of Spectators, including remove option
			var list/playerOptions = list()
			var /game/G = game(client.interface)
			if(selectChar.interface)
				playerOptions["-Remove-"] = null
			for(var/game/spectator/spectator in G.spectators)
				var shortKey = copytext(spectator.ckey, 1, 21)
				playerOptions[shortKey] = spectator
			// Display options, if there were any
			if(playerOptions.len)
				spectators.refresh(playerOptions)
				spectators.show()
				focus(spectators)
			// Otherwise, Display explanation text
			else
				spectators.hide()
				modal = addComponent(/component/label)
				modal.imprint("There are no players online to add to your party.", 160, 64)
				modal.positionScreen(64, 120)
				modal.show()
				focus(modal)
		select(character/partyMember/selectChar, game/spectator/selectator)
			// Handle Removal of players to spectation
			if(!selectator && selectChar.interface)
				var /rpg/oldInt = selectChar.interface
				oldInt.spectate()
			// Handle Addition of players
			else if(selectChar)
				var /party/P = selectChar.party
				P.addPlayer(selectator.client, selectChar)
			// Handle Empty Box Slots (less than 3 characters)
			else
				return TRUE
			// Return Focus
			showPlayers()
			focus(characters)