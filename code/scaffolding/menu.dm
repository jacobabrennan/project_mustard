

//-- Main Menu -----------------------------------------------------------------

client
	var/menu/menu
	New()
		menu = new(src)
		menu.setup()
		. = ..()
	Del()
		del menu
		. = ..()

menu
	parent_type = /component
	appearance_flags = PLANE_MASTER | TILE_BOUND
	icon = 'light_overlay.png'
	plane = PLANE_MENU
	screen_loc = "1,1"
	setup()
		. = ..()
		client.screen.Add(src)


//-- Component - Backbone of menuing system ------------------------------------

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
			component.transform = transform
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
			. = ..()
			/*if(chrome)
				var /component/chrome/C = locate() in components
				C.setColor("#fff", 2)*/
		blurred()
			. = ..()
			/*if(chrome)
				var /component/chrome/C = locate() in components
				C.setColor("#00f", 4)*/
		chrome(rect/rect)
			chrome = TRUE
			var/component/chrome/C = addComponent(/component/chrome)
			C.setup(rect)
		positionScreen(Xfull, Yfull, width, height)
			screen_loc = coords2ScreenLoc(Xfull, Yfull, width, height)
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


//-- Basic Components ----------------------------------------------------------

	//-- Sprite - Basic on screen graphic ------------
	sprite
		proc/imprint(_icon, _icon_state)
			icon = _icon
			icon_state = _icon_state

	//-- Label - Screen Text -------------------------
	label
		var/fontFile = 'rsc/fonts/prstartk.ttf'
		var/string
		proc/imprint(_string, width, height, align, textColor)
			string = "[_string]"
			var alignment = ""
			if(align)
				alignment = " text-align: [align];"
			var colorString = ""
			if(textColor)
				colorString = " color:[textColor];"
			maptext = {"<span style="font-family:'Press Start K'; font-size: 6pt;vertical-align:top;[alignment][colorString]">[string]</span>"}
			if(isnull(width)) width = 8*length(string)
			maptext_width = width
			if(height)
				maptext_height = height
			else
				maptext_height = 8
		commandDown(command)
			. = ..()
			if(.) return
			switch(command)
				if(BACK, PRIMARY) return FALSE
				else return TRUE


	//-- Stat - Displays a number and sprite ---------
	stat
		parent_type = /component/sprite
		var
			component/label/label
			statName
			value
		imprint(_statName, _value)
			if(_statName) statName = _statName
			if(_value) value = _value
			//
			if(!label)
				label = addComponent(/component/label)
			//
			..('stats.dmi', _statName)
			label.imprint(_value, length(_value)*8)
		positionScreen(fullX, fullY)
			..()
			label.positionScreen(fullX+16, fullY)

	//-- Slot - Represents a usable on screen --------
	slot
		var/atom/storage
		proc/imprint(atom/template, stateName)
			storage = template
			if(!storage)
				icon = null
			else
				icon = storage.icon
				icon_state = stateName || storage.icon_state
		//mouse_opacity = 2
		Click(location, control, params)
			if(!storage) return
			storage.Click(location, control, params)

	//-- Chrome - Component window background --------
	chrome
		var
			menuColor = "#fff"
		proc/setColor(newColor, time)
			if(newColor) menuColor = newColor
			for(var/component/C in components)
				if(!time) C.color = menuColor
				else animate(C, color=menuColor, time)
		setup(rect/rect)
			layer--
			var/component/sprite/S
			S = addComponent(/component/sprite)
			S.imprint('chrome.dmi', "border_nw")
			S.screen_loc = coords2ScreenLoc(rect.x-8, (rect.y+8)+(rect.height-32)) //"[rect.x]:-8,[rect.y+rect.height-2]:8"
			S = addComponent(/component/sprite)
			S.imprint('chrome.dmi', "border_ne")
			S.screen_loc = coords2ScreenLoc((rect.x+8)+(rect.width -32), (rect.y+8)+(rect.height-32)) //"[rect.x+rect.width-2]:8,[rect.y+rect.height-2]:8"
			S = addComponent(/component/sprite)
			S.imprint('chrome.dmi', "border_sw")
			S.screen_loc = coords2ScreenLoc(rect.x-8, rect.y-8) //"[rect.x]:-8,[rect.y]:-8"
			S = addComponent(/component/sprite)
			S.imprint('chrome.dmi', "border_se")
			S.screen_loc = coords2ScreenLoc((rect.x+8)+(rect.width -32), (rect.y-8)) //"[rect.x+rect.width-2]:8,[rect.y]:-8"
			if(rect.width > TILE_SIZE*2)
				S = addComponent(/component/sprite)
				S.imprint('chrome.dmi', "border_n")
				S.screen_loc = coords2ScreenLoc((rect.x+8), (rect.y+8)+(rect.height-32), (rect.width-32)) //"[rect.x+1]:-8,[rect.y+rect.height-2]:8 to [rect.x+rect.width-2]:8,[rect.y+rect.height-2]:8"
				S = addComponent(/component/sprite)
				S.imprint('chrome.dmi', "border_s")
				S.screen_loc = coords2ScreenLoc((rect.x+8), (rect.y-8), (rect.width-32)) //"[rect.x+1]:-8,[rect.y]:-8 to [rect.x+rect.width-2]:8,[rect.y]:-8"
			if(rect.height > TILE_SIZE*2)
				S = addComponent(/component/sprite)
				S.imprint('chrome.dmi', "border_w")
				S.screen_loc = coords2ScreenLoc((rect.x-8), (rect.y+8), null, (rect.height-32)) //"[rect.x]:-8,[rect.y+1]:-8 to [rect.x]:8,[rect.y+rect.height-2]:8"
				S = addComponent(/component/sprite)
				S.imprint('chrome.dmi', "border_e")
				S.screen_loc = coords2ScreenLoc((rect.x+8)+(rect.width -32), (rect.y+8), null, (rect.height-32)) //"[rect.x+rect.width-2]:8,[rect.y+1]:-8 to [rect.x+rect.width-2]:8,[rect.y+rect.height-2]:8"
			if(rect.width > TILE_SIZE*2 && rect.height > TILE_SIZE*2)
				S = addComponent(/component/sprite)
				S.imprint('chrome.dmi', "border_c")
				S.screen_loc = coords2ScreenLoc((rect.x+8), (rect.y+8), (rect.width -32), (rect.height-32)) //"[rect.x+1]:-8,[rect.y+1]:-8 to [rect.x+rect.width-2]:8,[rect.y+rect.height-2]:8"
			setColor()

	//-- Select - List of Options with cursor --------
	select
		var
			component/sprite/cursor
			list/options // Hash Table, Keys are Display text, values are returned values
			list/optionComponents
			posX
			posY
			length // How many options to display before scrolling
			//
			position = 1
			scroll = 0
		setup(_x, _y, list/_options, _length)
			posX = _x
			posY = _y
			length = _length
			options = _options
			//
			ASSERT(options || length)
			if(_options && !length)
				length = _options.len
			if(!_options && length)
				options = new(length)
			//
			optionComponents = new(length)
			for(var/I = 1 to length)
				var/component/label/option = addComponent(/component/label)
				option.positionScreen(posX+20, (4+posY)-((I-1)*16))
				optionComponents[I] = option
			cursor = addComponent(/component/sprite)
			cursor.imprint('menu16.dmi', "pointer_large")
			refresh()
		focused()
			. = ..()
			positionCursor()
		blurred()
			. = ..()
			cursor.hide()
		control()
			return TRUE
		commandDown(command)
			switch(command)
				if(NORTH)
					var oldPosition = position
					position = max(1, position-1)
					var scrollFloor = min(2, position)
					if(position-scroll < scrollFloor)
						--scroll
						scroll()
					positionCursor()
					if(position != oldPosition) return TRUE
				if(SOUTH)
					var oldPosition = position
					position = min(options.len, position+1)
					var scrollCeiling = (position < options.len)? length-1 : length
					if(position-scroll > scrollCeiling)
						++scroll
						scroll()
					positionCursor()
					if(position != oldPosition) return TRUE
				if(PRIMARY) return FALSE
				if(BACK) return FALSE
		proc
			positionCursor()
				var cursorPos = position-scroll
				cursor.positionScreen(posX, posY-((cursorPos-1)*16))
			select()
				return options[options[position]]
			scroll()
				for(var/I = 1 to length)
					var /component/label/option = optionComponents[I]
					if(scroll > 0 && I == 1)
						option.imprint("...")
					else if(I == length && scroll < options.len - length)
						option.imprint("...")
					else
						var optionValue
						if(I+scroll <= options.len)
							optionValue = options[I+scroll]
						else
							optionValue = ""
						option.imprint(optionValue)
			refresh(newOptions)
				if(newOptions) options = newOptions
				//if(options.len < length)
				//options.len = length
				scroll()
				positionCursor()

	//-- Box - Grid of usables with cursor -----------
	box
		var
			posX
			posY
			width
			height
			// Nonconfigurable:
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
			cursor.autoShow = FALSE
			//
			reposition(_x, _y)
		focused()
			. = ..()
			cursor.show()
			positionCursor()
		blurred()
			. = ..()
			cursor.hide()
		chrome(rect/rect)
			if(!rect)
				var Xloc = round(posX/TILE_SIZE)*TILE_SIZE
				var Yloc = round(posY/TILE_SIZE)*TILE_SIZE
				var buffer = 2
				var boxWidth  = ((width +1)*TILE_SIZE)+(buffer*(width -1))
				var boxHeight = ((height+1)*TILE_SIZE)+(buffer*(height-1))
				rect = new(Xloc, Yloc, boxWidth, boxHeight)
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
			var buffer = 2
			if(cursor.shown)
				positionCursor()
			for(var/I = 1 to slots.len)
				var /component/slot/S = slots[I]
				var Xfull = posX + (TILE_SIZE+buffer)*(((I-1)%width))
				var Yfull = (TILE_SIZE+buffer)*round((I-1)/width)
				Yfull = (posY+(TILE_SIZE+buffer)*(height-1)) -Yfull
				S.positionScreen(Xfull, Yfull)
		control()
			. = ..()
			return TRUE
		commandDown(command)
			. = ..()
			. = moveCursor(command)
			if(command == BACK || command == PRIMARY) return FALSE
			return
		proc/moveCursor(direction)
			var oldPosition = position
			switch(direction)
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
			if(position != oldPosition)
				return TRUE
		proc/select()
			var /component/slot/posSlot = slots[position]
			return posSlot.storage
		proc/positionCursor(newPosition)
			if(!newPosition) newPosition = position
			else position = newPosition
			var buffer = 2
			var Xfull = posX + (TILE_SIZE+buffer)*(((position-1)%width))
			var Yfull = (TILE_SIZE+buffer)*round((position-1)/width)
			Yfull = (posY+(TILE_SIZE+buffer)*(height-1)) -Yfull
			cursor.positionScreen(Xfull-2, Yfull-2)

	//-- Dialogue ------------------------------------
		// Displays multiple statements in one window.
		// Use "#n" to designate a new line.
		// Use "#p" to designate a new statement.
	dialogue
		var
			component/sprite/portrait
			component/label/label
			component/sprite/cursor
			width = 22
			height = 4
			list/statements = new()
			position
			revealing
			skip
		setup(character, string)
			// Prep supplied string into list of statements.
			var /list/wordList = splittext(string, " ")
			var currentStatement = ""
			var currentLine = ""
			var lineCount = 0
			// Add Words consecutively to Lines
			while(wordList.len)
				var currentWord = wordList[1]
				wordList.Cut(1,2)
				var lineLength = length(currentLine)
			// Handle Control Characters
				// Handle new statement commands (#p)
				if(currentWord == "#p")
					if(lineCount != 0) currentStatement += "\n"
					currentStatement += currentLine
					if(length(currentStatement))
						statements.Add(currentStatement)
						currentLine = ""
						currentStatement = ""
						lineCount = 0
					continue
				// Handle new line commands (#n)
				if(currentWord == "#n")
					if(lineCount != 0) currentStatement += "\n"
					currentStatement += currentLine
					lineCount++
					currentLine = ""
					continue
			// If the line is full add it to the statement
				if(lineLength+length(currentWord) > width)
					if(lineCount != 0) currentStatement += "\n"
					currentStatement += currentLine
					lineCount++
					currentLine = ""
			// If the statement has enough lines, add it to the statement list
					if(lineCount >= 4)
						statements.Add(currentStatement)
						currentStatement = ""
						lineCount = 0
			// Add the word to the current line
				if(length(currentLine)) currentLine += " "
				currentLine += currentWord
			// Add any remaining line or statement
			if(length(currentLine))
				if(length(currentStatement)) currentStatement += "\n"
				currentStatement += currentLine
			if(length(currentStatement))
				statements.Add(currentStatement)
			//
			cursor = addComponent(/component/sprite)
			cursor.imprint('menu16.dmi', "dialogue_cursor")
			cursor.positionScreen(200,182)
			chrome(rect(56,200,12*TILE_SIZE, 3*TILE_SIZE))
			portrait = addComponent(/component/sprite)
			portrait.imprint('portraits.dmi', character)
			portrait.positionScreen(0, 192)
			label = addComponent(/component/label)
			label.positionScreen(56, 200)
			label.show()
			revealLine(1)
		proc/revealLine(newLine)
			spawn()
				cursor.hide()
				revealing = TRUE
				position = newLine
				var fullString = statements[position]
				for(var/revealPos = 1 to length(fullString))
					if(skip)
						skip = FALSE
						label.imprint(fullString, (width+2)*8, height*8)
						break
					var revealString = copytext(fullString, 1, revealPos+1)
					label.imprint(revealString, (width+2)*8, height*8)
					sleep(1/10)
				revealing = FALSE
				if(position < statements.len)
					cursor.show()

		commandDown(command)
			. = ..()
			if(.) return
			. = TRUE
			switch(command)
				if(PRIMARY, BACK)
					if(revealing)
						skip = TRUE
					else
						if(position < statements.len)
							revealLine(position+1)
						else
							del src


rpg/Login()
	. = ..()
	spawn()
		var /component/dialogue/D = client.menu.addComponent(/component/dialogue)
		D.setup("Hero", "Bug: sword attacks not aligned properly when moving in some directions. Bug: sword attacks not #p New stuff! aligned properly when moving in some directions. Bug: sword attacks not aligned properly when moving in some directions.")
		D.show()
		client.menu.focus(D)


//-- Transition ----------------------------------------------------------------

menu/transition
	parent_type = /component
	var
		component/label/label
	setup(terrainText)
		. = ..()
		chrome(rect(5*TILE_SIZE,13*TILE_SIZE,8*TILE_SIZE,3*TILE_SIZE))
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