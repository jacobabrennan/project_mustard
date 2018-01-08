

//------------------------------------------------------------------------------

client
	var/menu/menu
	New()
		menu = new(src)
		menu.setup()
		. = ..()
	Del()
		del menu
		. = ..()
	proc/character()
		var /interface/rpg/int = interface
		ASSERT(istype(int)) // client/character() used outside the context of an RPG interface
		return int.character

component
	parent_type = /obj
	//plane = PLANE_MENU
	appearance_flags = TILE_BOUND
	var
		autoShow = TRUE
		chrome = FALSE
		//
		list/components[0]
		component/focus
		component/parent
		client/client
		shown = FALSE
	New(client/newClient)
		client = newClient
	Del()
		for(var/component/C in components)
			C.hide()
			del C
		. = ..()
	proc
		setup()
		addComponent(component/component)
			ASSERT(client)
			if(ispath(component))
				component = new component()
			components.Add(component)
			component.client = client
			component.parent = src
			component.layer = layer
			if(!component.plane)
				component.plane = plane
			if(component.chrome) component.layer += 1
			return component
		show()
			shown = TRUE
			client.screen.Add(src)
			for(var/component/C in components)
				if(C.autoShow) C.show()
		hide()
			shown = FALSE
			client.screen.Remove(src)
			for(var/component/C in components)
				C.hide()
			if(parent.focus == src)
				parent.focus = null
		fade(duration)
			for(var/component/C in components)
				C.fade(duration)
			animate(src, alpha = 0, time = duration)
		focus(component/newFocus)
			if(focus)
				focus.blurred()
				if(!newFocus)
					focus = null
			if(newFocus)
				focus = newFocus
				newFocus.show()
				newFocus.focused()
		focused()
		blurred()
		chrome(rect/rect)
			chrome = TRUE
			var/component/chrome/C = addComponent(/component/chrome)
			C.setup(rect)
		positionScreen(Xfull, Yfull)
			var Xloc = round(Xfull/TILE_SIZE)
			var Xoffset = Xfull%TILE_SIZE
			var Yloc = round(Yfull/TILE_SIZE)
			var Yoffset = Yfull%TILE_SIZE
			screen_loc = "[Xloc]:[Xoffset],[Yloc]:[Yoffset]"
		translate(newX, newY, translateTime)
			var /matrix/newPosition = matrix(1,0,newX, 0,1,newY)
			if(translateTime)
				animate(src, transform=newPosition, time=translateTime)
			else
				transform = newPosition
			for(var/component/C in components)
				C.translate(newX, newY, translateTime)
	proc
		control(character/_character)
			// return TRUE to block
			if(focus) return focus.control(_character)
		commandDown(command)
			// return TRUE to block
			if(focus) return focus.commandDown(command)
	//---- Components ----------------------------------------
	sprite
		proc/imprint(_icon, _icon_state)
			icon = _icon
			icon_state = _icon_state
	label
		var/fontFile = 'rsc/fonts/prstartk.ttf'
		var/string
		proc/imprint(_string, width, height, align)
			string = "[_string]"
			var alignment = ""
			if(align)
				alignment = " text-align: [align];"
			maptext = {"<span style="font-family:'Press Start K'; font-size: 6pt;[alignment]">[string]</span>"}
			if(isnull(width)) width = 8*length(string)
			maptext_width = width
			if(height)
				maptext_height = height
	slot
		var/usable/usable
		proc/imprint(usable/template)
			usable = template
			if(!usable)
				icon = null
			else
				icon = usable.icon
				icon_state = usable.icon_state
		mouse_opacity = 2
		Click(location, control, params)
			if(!usable) return
			usable.Click(location, control, params)
	chrome
		setup(rect/rect)
			layer--
			var/component/sprite/S
			S = addComponent(/component/sprite)
			S.imprint('chrome.dmi', "border_nw")
			S.screen_loc = "[rect.x]:-8,[rect.y+rect.height-2]:8"
			S = addComponent(/component/sprite)
			S.imprint('chrome.dmi', "border_ne")
			S.screen_loc = "[rect.x+rect.width-2]:8,[rect.y+rect.height-2]:8"
			S = addComponent(/component/sprite)
			S.imprint('chrome.dmi', "border_sw")
			S.screen_loc = "[rect.x]:-8,[rect.y]:-8"
			S = addComponent(/component/sprite)
			S.imprint('chrome.dmi', "border_se")
			S.screen_loc = "[rect.x+rect.width-2]:8,[rect.y]:-8"
			if(rect.width > 2)
				S = addComponent(/component/sprite)
				S.imprint('chrome.dmi', "border_n")
				S.screen_loc = "[rect.x+1]:-8,[rect.y+rect.height-2]:8 to [rect.x+rect.width-2]:8,[rect.y+rect.height-2]:8"
				S = addComponent(/component/sprite)
				S.imprint('chrome.dmi', "border_s")
				S.screen_loc = "[rect.x+1]:-8,[rect.y]:-8 to [rect.x+rect.width-2]:8,[rect.y]:-8"
			if(rect.height > 2)
				S = addComponent(/component/sprite)
				S.imprint('chrome.dmi', "border_w")
				S.screen_loc = "[rect.x]:-8,[rect.y+1]:-8 to [rect.x]:8,[rect.y+rect.height-2]:8"
				S = addComponent(/component/sprite)
				S.imprint('chrome.dmi', "border_e")
				S.screen_loc = "[rect.x+rect.width-2]:8,[rect.y+1]:-8 to [rect.x+rect.width-2]:8,[rect.y+rect.height-2]:8"
			if(rect.width > 2 && rect.height > 2)
				S = addComponent(/component/sprite)
				S.imprint('chrome.dmi', "border_c")
				S.screen_loc = "[rect.x+1]:-8,[rect.y+1]:-8 to [rect.x+rect.width-2]:8,[rect.y+rect.height-2]:8"
	select
		var
			list/options // Hash Table, Keys are Display text, values are returned values
			posX
			posY
			position = 1
			component/sprite/cursor
		setup(_x, _y, _options)
			posX = _x
			posY = _y
			options = _options
			for(var/I = 1 to options.len)
				var/component/label/option = addComponent(/component/label)
				option.imprint(options[I])
				option.positionScreen(posX+20, (4+posY)-((I-1)*16))
			cursor = addComponent(/component/sprite)
			cursor.imprint('specials.dmi', "pointer_large")
			positionCursor()
		control()
			return TRUE
		commandDown(command)
			. = TRUE
			switch(command)
				if(NORTH)
					position = max(1, position-1)
					positionCursor()
				if(SOUTH)
					position = min(options.len, position+1)
					positionCursor()
				if(PRIMARY) return FALSE
				if(STATUS) return FALSE
		proc
			positionCursor()
				cursor.positionScreen(posX, posY-((position-1)*16))
			select()
				return options[options[position]]
	box
		var
			posX
			posY
			width
			height
			list/slots = list()
			position = 1
			component/sprite/cursor
		setup(_x, _y, _width, _height)
			. = ..()
			width = _width
			height = _height
			slots.len = width*height
			for(var/I = 1 to slots.len)
				slots[I] = addComponent(/component/slot)
			//
			cursor = addComponent(/component/sprite)
			cursor.icon = '24px.dmi'
			cursor.icon_state = "cursor"
			cursor.pixel_x = -20
			cursor.pixel_y = -20
			//
			reposition(_x, _y)
		focused()
			. = ..()
			positionCursor()
		blurred()
			. = ..()
			cursor.hide()
		chrome(rect/rect)
			if(!rect)
				var Xloc = round(posX/TILE_SIZE)
				var Yloc = round(posY/TILE_SIZE)
				var boxWidth  = round((width *18)/TILE_SIZE)+2
				var boxHeight = round((height*18)/TILE_SIZE)+1
				rect = new(Xloc+1, Yloc, boxWidth, boxHeight)
			return ..(rect)
		proc/refresh(list/usables)
			for(var/I = 1 to slots.len)
				var /component/slot/indexSlot = slots[I]
				if(I > usables.len)
					indexSlot.imprint(null)
					continue
				var /usable/indexItem = usables[I]
				indexSlot.imprint(indexItem)
		proc/reposition(_x, _y)
			posX = _x
			posY = _y
			if(cursor.shown)
				positionCursor()
			for(var/I = 1 to slots.len)
				var /component/slot/S = slots[I]
				var Xfull = posX+(TILE_SIZE+2)*(((I-1)%width)+1)
				var Yfull = posY-(TILE_SIZE+2)*round((I-1)/width)
				S.positionScreen(Xfull, Yfull)
		control()
			. = ..()
			return TRUE
		commandDown(command)
			. = ..()
			switch(command)
				if(NORTH)
					if(position > width) position -= width
					positionCursor(position)
				if(SOUTH)
					if(position <= (width*height)-width) position += width
					positionCursor(position)
				if(WEST )
					if(1+(position-1)%width != 1) position--
					positionCursor(position)
				if(EAST )
					if(1+(position-1)%width != width) position++
					positionCursor(position)
			return TRUE
		proc/select()
			var /component/slot/posSlot = slots[position]
			return posSlot.usable
		proc/positionCursor(newPosition)
			if(!newPosition) newPosition = position
			else position = newPosition
			var Xfull = posX+(TILE_SIZE+2)*(((position-1)%width)+1)
			var Yfull = posY-(TILE_SIZE+2)*round((position-1)/width)
			cursor.positionScreen(Xfull-2, Yfull-2)


//-- Main Menu -----------------------------------------------------------------

menu
	parent_type = /component
	appearance_flags = PLANE_MASTER | TILE_BOUND
	icon = 'light_overlay.png'
	plane = PLANE_MENU
	var
		menu/hud/hud
		menu/status/status
		menu/transition/transition
		liftDelay = 2
	setup()
		. = ..()
		// Add menu to screen so PLANE_MASTER will trigger
		screen_loc = "1,1"
		client.screen.Add(src)
		//
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
			if("hp","mp","slots","coins") hud.refresh(which)
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
			var/tileX = round((totalX-1)/TILE_SIZE)+1
			var/offsetX = (totalX-1)%TILE_SIZE+1
			var/totalY = height+round((index-1)/barNum)*8
			var/tileY = round((totalY-1)/TILE_SIZE)+1
			var/offsetY = (totalY-1)%TILE_SIZE+1
			screen_loc = "[tileX]:[offsetX],[tileY]:[offsetY]"
	show()
		refresh("hp")
		refresh("mp")
		refresh("slots")
		refresh("coins")
		. = ..()
	proc/lift()
		/*screen_loc = "1,13:12"
		refresh("hp")
		refresh("mp")
		refresh("slots")
		refresh("coins")*/
		// Animate Lifting
		translate(0, (240-32), client.menu.liftDelay)
	proc/lower()
		/*
		spawn(client.menu.liftDelay)
			screen_loc = "1,1"
			refresh("hp")
			refresh("mp")
			refresh("slots")
			refresh("coins")
		*/
		translate(0, 0, client.menu.liftDelay)
	proc/refresh(which)
		var/interface/rpg/interface = client.interface
		switch(which)
			if("slots")
				for(var/I = 1 to slots.len)
					var/totalX = -16 + I*24
					var/tileX = round((totalX-1)/TILE_SIZE)+1
					var/offsetX = (totalX-1)%TILE_SIZE+1
					var/component/slot/slot = slots[I]
					slot.screen_loc = "[tileX]:[offsetX],1:8"
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
			if("coins")
				coinLabel.imprint(interface.character.party.coins)
				coinIcon.screen_loc = "7:8,1:12"
				coinLabel.screen_loc = "8:1,1:12"


//-- Status -----------------------------------------------------------------------

menu/status
	parent_type = /component
	//
	icon = 'status_bottom.png'
	screen_loc = "1,1"
	autoShow = FALSE
	//
	var
		component/sprite/cursor
		component/box/equipment
		component/box/inventory
		component/box/skills
		component/box/enchantments
		component/box/activeBox
		list/hotKeys[3]
		position = 1
		menu/itemInfo/itemInfo
	setup()
		. = ..()
		inventory    = addComponent(/component/box)
		equipment    = addComponent(/component/box)
		skills       = addComponent(/component/box)
		enchantments = addComponent(/component/box)
		inventory.setup(    16, 124, 4, 6)
		equipment.setup(    18, 179, 4, 1)
		skills.setup(      116, 179, 6, 2)
		enchantments.setup(116, 106, 6, 1)
		activeBox = inventory
		cursor = addComponent(/component/sprite)
		cursor.icon = '24px.dmi'
		cursor.icon_state = "cursor"
		moveCursor()
		itemInfo = addComponent(/menu/itemInfo)
		itemInfo.setup()
	show()
		. = ..()
		if(client.menu && client.menu.hud) client.menu.hud.lift()
		// Animate Lifting
		translate(0, -(240-32))
		translate(0, 0, client.menu.liftDelay)
	hide()
		if(client.menu && client.menu.hud) client.menu.hud.lower()
		itemInfo.hide()
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
		var /component/slot/selectSlot = activeBox.slots[position]
		var /usable/selection = selectSlot.usable
		if(!selection) return
		if(hotKey == PRIMARY)
			if(activeBox == inventory || activeBox == equipment)
				itemInfo.imprint(selection)
				focus(itemInfo)
				//if(istype(selection, /item/gear))
				//	character.equip(selection)
				//selection.use(character)
			//if(activeBox == equipment)
			//	character.unequip(selection)
		else
			var/hkIndex
			switch(hotKey)
				if(SECONDARY ) hkIndex = 1
				if(TERTIARY  ) hkIndex = 2
				if(QUATERNARY) hkIndex = 3
			hotKeys[hkIndex] = selection
	proc/moveCursor(direction)
		switch(direction)
			if(NORTH)
				if(position <= activeBox.width)
					if(activeBox == inventory)
						activeBox = equipment
						position = 1+ (position-1)%activeBox.width
				else position -= activeBox.width
			if(SOUTH)
				if(position + activeBox.width > activeBox.slots.len)
					if(activeBox == equipment)
						activeBox = inventory
						position = 1+ (position-1)%activeBox.width
					else if(activeBox == skills)
						activeBox = inventory
						position = 4
				else position += activeBox.width
			if(WEST)
				if(position%activeBox.width == 1)
					if(activeBox == skills)
						activeBox = equipment
						position = 4
				else position--
			if(EAST)
				if(position%activeBox.width == 0)
					if(activeBox == equipment)
						activeBox = skills
						position = 1
					else if(activeBox == inventory)
						activeBox = skills
						position = skills.width+1
				else position++
		var Xfull = activeBox.posX+(TILE_SIZE+2)*(((position-1)%activeBox.width)+1)
		var Yfull = activeBox.posY-(TILE_SIZE+2)*round((position-1)/activeBox.width)
		cursor.positionScreen(Xfull-2, Yfull-2)
	control(_character)
		return TRUE // Block
	commandDown(command)
		var/block = ..()
		if(block) return block
		. = TRUE
		var/interface/rpg/int = client.interface
		switch(command)
			if(1 to 16)
				moveCursor(command)
			if(STATUS)
				hide()
				client.menu.focus()
			if(PRIMARY, SECONDARY, TERTIARY, QUATERNARY)
				select(client, int.character, command)
				client.menu.refresh("hp"   , null, int)
				client.menu.refresh("mp"   , null, int)
				client.menu.refresh("slots", null, int)
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


//-- Item Info ------------------------------------------------------------------

menu/itemInfo
	parent_type = /component
	//
	//icon = 'main_panel.png'
	//screen_loc = "3:11,5:8"
	autoShow = FALSE
	chrome = TRUE
	//
	var
		obj/cursor
		component/slot/slot
		component/label/itemName
		list/options[0]
		list/optionNames[0]
		position = 1
		list/statLabels
		list/statIcons
	setup()
		layer++
		. = ..()
		chrome(rect(4,5,10,7))
		slot = addComponent(/component/slot)
		slot.screen_loc = "4,10"
		cursor = addComponent(/component/sprite)
		cursor.icon = 'specials.dmi'
		cursor.icon_state = "pointer_large"
		itemName = addComponent(/component/label)
		itemName.screen_loc = "5:8,10:4"
	proc/imprint(usable/usable)
		client.menu.status.cursor.hide()
		// Show Icon + Name
		slot.imprint(usable)
		itemName.imprint(usable.name)
		// Setup Options
		optionNames = list("Back")
		if(istype(usable, /item/gear))
			var/interface/rpg/int = client.interface
			if(usable in int.character.equipment) optionNames.Add("Unequip")
			else optionNames.Add("Equip")
		//optionNames.Add("Drop")
		position = 1
		for(var/index = 1 to 4)
			var/component/label/optionLabel
			if(index > options.len)
				optionLabel = addComponent(/component/label)
				options.Add(optionLabel)
				optionLabel.screen_loc = "5:8,[9-index]:4"
			if(index > optionNames.len)
				optionLabel = options[index]
				optionLabel.imprint("")
				continue
			var/optionName = optionNames[index]
			optionLabel = options[index]
			optionLabel.imprint(optionName)
		cursor.screen_loc = "4,[9-position]"
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
	commandDown(command)
		var/interface/rpg/int = client.interface
		switch(command)
			if(STATUS)
				client.menu.status.hide()
			if(NORTH)
				position = max(1, position-1)
				cursor.screen_loc = "4,[9-position]"
			if(SOUTH)
				position = min(optionNames.len, position+1)
				cursor.screen_loc = "4,[9-position]"
			if(PRIMARY)
				var/optionName = optionNames[position]
				switch(optionName)
					if("Back")
						hide()
						client.menu.status.cursor.show()
					/*if("Drop")
						hide()
						client.menu.status.cursor.show()
						int.character.drop(slot.usable)*/
					if("Equip")
						hide()
						client.menu.status.cursor.show()
						int.character.equip(slot.usable)
						client.menu.refresh("slots")
						client.menu.refresh("hp")
						client.menu.refresh("mp")
					if("Unequip")
						hide()
						client.menu.status.cursor.show()
						int.character.unequip(slot.usable)
						client.menu.refresh("slots")
						client.menu.refresh("hp")
						client.menu.refresh("mp")
		return TRUE
	control()
		return TRUE


//-- Transition ----------------------------------------------------------------

menu/transition
	parent_type = /component
	var
		component/label/label
	setup(terrainText)
		. = ..()
		chrome(rect(5,13,8,3))
		label = addComponent(/component/label)
		var nudge = 8
		if(length(terrainText) % 2)
			nudge = 4
			terrainText = " [terrainText]"
		if(length(terrainText) % 4)
			terrainText = " [terrainText] "
		var screenX = 8-(length(terrainText)/4)
		label.screen_loc = "[screenX]:[nudge],13:12"
		label.imprint(terrainText)
		show()
		spawn(TIME_TERRAIN_NAME/2)
			fade(TIME_TERRAIN_NAME/2)
		spawn(TIME_TERRAIN_NAME)
			del src


//-- Store ---------------------------------------------------------------------
/*
menu/store
	parent_type = /component
	var
		list/itemList
		component/box/items
		menu/store/info/info
		component/label/option1
		component/label/option2
		component/label/option3
		component/sprite/cursor
		position = 1
		mode // "buy", "sell", or null
		component/label/dialogue
	setup(list/_itemList)
		. = ..()
		chrome(rect(3,5,12,8))
		items = addComponent(/component/box)
		items.setup(102, 174, 6, 6)
		itemList = _itemList.Copy()
		info = addComponent(/menu/store/info)
		info.setup()
		cursor = addComponent(/component/sprite)
		cursor.icon = 'specials.dmi'
		cursor.icon_state = "pointer_large"
		positionCursor()
		var/component/sprite/portrait = addComponent(/component/sprite)
		portrait.icon = 'portraits.dmi'
		portrait.icon_state = "knight_outside"
		portrait.screen_loc = "3,8"
		option1 = addComponent(/component/label)
		option2 = addComponent(/component/label)
		option3 = addComponent(/component/label)
		option1.screen_loc = "5,7:4"
		option2.screen_loc = "5,6:4"
		option3.screen_loc = "5,5:4"
		option1.imprint("Buy")
		option2.imprint("Sell")
		option3.imprint("Exit")
		dialogue = addComponent(/component/label)
		dialogue.autoShow = FALSE
		dialogue.screen_loc = "7:8,9"
		//dialogue.maptext_width = 11*8
		//dialogue.maptext_height = 64 // Doesn't do anything, for some reason. Completely unconfigurable.
	proc/positionCursor()
		cursor.screen_loc = "4:-4,[8-position]"
	proc/buy(var/item/item)
		if(!item) return
		var/interface/rpg/int = client.interface
		if(item.price > int.character.coins)
			dialogue("You can't\nafford that", 5*8)
			return FALSE
		var/success = int.character.get(item)
		if(success)
			int.character.adjustCoins(-item.price)
			itemList[itemList.Find(item)] = null
			items.refresh(itemList)
			dialogue("Thank you!")
			return TRUE
		else
			dialogue("You can't\ncarry anymore", 5*8)
			return FALSE
	proc/sell(var/item/item)
		if(!item) return
		var/interface/rpg/int = client.interface
		ASSERT(itemList != int.character.inventory)
		int.character.unget(item)
		int.character.adjustCoins(round(item.price*SALE_MARKDOWN))
		items.refresh(int.character.inventory)
		dialogue("Thank you!")
		return TRUE
	proc/dialogue(msgText)
		dialogue.imprint(msgText)
		option1.imprint("")
		option2.imprint("")
		option3.imprint("")
		items.hide()
		info.hide()
		focus(dialogue)
	control()
		return TRUE
	commandDown(command)
		. = TRUE
		if(command == STATUS)
			del src
			return
		if(focus == dialogue)
			if(command == PRIMARY)
				mode = null
				option1.imprint("Buy")
				option2.imprint("Sell")
				option3.imprint("Exit")
				dialogue.hide()
				items.hide()
				focus(null)
				cursor.show()
		else if(focus == items)
			switch(command)
				if(WEST)
					if(1+(items.position-1)%items.width == 1)
						focus = null
						items.position = 0
						items.cursor.hide()
						position = 1
						positionCursor()
						cursor.show()
						return
				if(PRIMARY)
					var/component/slot/S = items.slots[items.position]
					var/item/_item = S.usable
					if(!_item) return
					info.imprint(_item, mode)
					items.hide()
					cursor.show()
					if(mode == "sell")
						option1.imprint("Sell")
					else
						option1.imprint("Buy")
					option2.imprint("Back")
					option3.imprint("Exit")
					focus(info)
					return
			..()
		else
			switch(command)
				if(NORTH)
					if(focus == items) return
					position = max(1, position-1)
					positionCursor()
				if(SOUTH)
					if(focus == items) return
					position = min(3, position+1)
					positionCursor()
				if(PRIMARY)
					select()
				if(EAST)
					if(option1.string != "Back") return TRUE
					focus(items)
					items.position = 1
					items.positionCursor()
					cursor.hide()
		return TRUE
	proc/select()
		var/component/label/option
		switch(position)
			if(1) option = option1
			if(2) option = option2
			if(3) option = option3
		switch(option.string)
			if("Buy")
				if(mode == null)
					mode = "buy"
					option1.imprint("Back")
					option2.imprint("")
					option3.imprint("")
					items.refresh(itemList)
					items.position = 1
					items.positionCursor()
					cursor.hide()
					focus(items)
				else
					cursor.hide()
					info.hide()
					var/component/slot/S = items.slots[items.position]
					var/item/_item = S.usable
					buy(_item)
			if("Sell")
				if(mode == null)
					mode = "sell"
					option1.imprint("Back")
					option2.imprint("")
					option3.imprint("")
					var/interface/rpg/int = client.interface
					items.refresh(int.character.inventory)
					items.position = 1
					items.positionCursor()
					cursor.hide()
					focus(items)
				else
					cursor.hide()
					info.hide()
					var/component/slot/S = items.slots[items.position]
					var/item/_item = S.usable
					sell(_item)
			if("Back")
				if(!info.shown)
					mode = null
					option1.imprint("Buy")
					option2.imprint("Sell")
					option3.imprint("Exit")
					items.hide()
					focus(null)
					cursor.show()
				else
					cursor.hide()
					info.hide()
					focus(items)
					option1.imprint("Back")
					option2.imprint("")
					option3.imprint("")
			if("Exit")
				client.menu.focus(null)
				hide()
				del src
	info
		parent_type = /component
		autoShow = FALSE
		//
		var
			component/slot/slot
			component/label/itemName
			list/statLabels
			list/statIcons
		setup()
			. = ..()
			slot = addComponent(/component/slot)
			slot.screen_loc = "8,10:8"
			itemName = addComponent(/component/label)
			itemName.screen_loc = "9:8,10:12"
		proc/imprint(item/usable, mode)
			// Show Icon + Name
			slot.imprint(usable)
			itemName.imprint(usable.name)
			// Setup Stats
			for(var/component/C in statLabels+statIcons)
				del C
			statLabels = new()
			statIcons = new()
			if(istype(usable))
				var/component/label/_label = addComponent(/component/label)
				if(mode == "buy") _label.imprint(usable.price)
				else _label.imprint(round(usable.price*SALE_MARKDOWN))
				var/component/sprite/_icon = addComponent(/component/sprite)
				_icon.icon = 'stats.dmi'
				_icon.icon_state = "coin"
				statLabels.Add(_label)
				statIcons.Add(_icon)
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
				statIcon.screen_loc = "8:8,[10-index]:8"
				statLabel.screen_loc = "9:8,[10-index]:8"

*/