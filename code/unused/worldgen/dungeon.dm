

//------------------------------------------------------------------------------

dungeon
	var
		width
		height
		list/rooms
		dungeon/room/firstRoom
		//
		list/openRooms
		list/deadEnds
	room
		parent_type = /datum
		var
			x
			y
			doors = 0
			openings = NORTH|SOUTH|EAST|WEST
			depth = 0
			layedOut = FALSE
		New(dungeon/_dungeon, _x, _y, dungeon/room/parent)
			_dungeon.openRooms.Add(src)
			x = _x
			y = _y
			_dungeon.rooms[COMPOUND_INDEX(x, y, _dungeon.width)] = src
			if(!parent)
				depth = 0
				openings &= ~SOUTH
			else
				depth = parent.depth+1
				var/openDir
				if(     parent.x < x) openDir = WEST
				else if(parent.x > x) openDir = EAST
				else if(parent.y < y) openDir = SOUTH
				else if(parent.y > y) openDir = NORTH
				openings &= ~openDir
				doors |= openDir
			. = ..()
	proc/getRoom(x, y, direction)
		switch(direction)
			if(NORTH) y++
			if(SOUTH) y--
			if(EAST ) x++
			if(WEST ) x--
		if(x > width || x <= 0 || y > height || y <= 0) return
		return rooms[COMPOUND_INDEX(x, y, width)]
	proc/generate(_width, _height, _dungeonId)
		width = _width
		height = _height
		rooms     = new(width*height)
		openRooms = new()
		deadEnds  = new()
		firstRoom = new(src, rand(1,width), 1, 0)
		while(openRooms.len)
			var/dungeon/room/testRoom = pick(openRooms)
			extendPath(testRoom)
			if(rand()*32 < 1)
				world << ".\..."
				sleep(1)
		var/gridText = ""
		for(var/posY = 1 to (PLOT_SIZE-1)*height)
			for(var/posX = 1 to (PLOT_SIZE-1)*width)
				//var/dungeon/room/R = getRoom(1+round((posX-1)/(PLOT_SIZE-1)), 1+round((posY-1)/(PLOT_SIZE-1)))
				var/roomX = 1+ (posX-1)%(PLOT_SIZE-1)
				var/roomY = 1+ (posY-1)%(PLOT_SIZE-1)
				if(     roomY==((PLOT_SIZE-1))) gridText += "#"
				//else if(!(R.doors&SOUTH) && (roomY==1          )) gridText += "#"
				else if(roomX==((PLOT_SIZE-1))) gridText += "#"
				else if(roomY==((PLOT_SIZE-2))) gridText += "3"
				else if(roomY==((PLOT_SIZE-3))) gridText += "2"
				else if(roomY==((PLOT_SIZE-4))) gridText += "1"
				else if(roomY==            1  ) gridText += "#"
				//else if(!(R.doors&WEST ) && (roomX==1          )) gridText += "#"
				else gridText += "."
		/*r/mapGenerator/generator/G = new()
		gridText = G.generate(
			gridText,
			width*(PLOT_SIZE-1), height*(PLOT_SIZE-1),
			(PLOT_SIZE-1), 5,
			0, 0,
			firstRoom.x*(PLOT_SIZE-1)+7, firstRoom.y*(PLOT_SIZE-1)+7
		)*/
		// Expand tile grid along plot edges, copy from one edge to opposite edge of other plot
		var/worldW = (PLOT_SIZE-1)*width
		var/worldH = (PLOT_SIZE-1)*height
		var/expandGridM = ""
		// Expand Horizontally
		for(var/posY = 1 to worldH)
			// For Each line, Add 1 at start
			var compoundIndex = COMPOUND_INDEX(1, posY, worldW)
			expandGridM += copytext(gridText, compoundIndex, compoundIndex+1)
			// Add One every PLOT_W
			for(var/posX = 1 to worldW)
				var compoundIndex2 = COMPOUND_INDEX(posX, posY, worldW)
				var valueM = copytext(gridText, compoundIndex2, compoundIndex2+1)
				if(1+(posX-1)%(PLOT_SIZE-1) == (PLOT_SIZE-1) && posX != worldW)
					expandGridM += valueM
				expandGridM += valueM
		//
		var gridCopyM = expandGridM
		expandGridM = ""
		// Expand Vertically
		for(var/posX = 1 to PLOT_SIZE*width)
			// Add row at bottom
			var compoundIndex = COMPOUND_INDEX(posX, 1, PLOT_SIZE*width)
			var valueM = copytext(gridCopyM, compoundIndex, compoundIndex+1)
			expandGridM += valueM
		for(var/posY = 1 to worldH)
			var repeats = 1
			if(1+(posY-1)%(PLOT_SIZE-1) == (PLOT_SIZE-1) && posY != worldW)
				repeats = 2
			for(var/repeat = 1 to repeats)
				for(var/posX = 1 to PLOT_SIZE*width)
					var compoundIndex = COMPOUND_INDEX(posX, posY, PLOT_SIZE*width)
					var valueM = copytext(gridCopyM, compoundIndex, compoundIndex+1)
					expandGridM += valueM
		var/region/newR = new(_dungeonId)
		newR.setSize(width, height, "dungeon")
		newR.gridText = expandGridM
		while(deadEnds.len)
			var/dungeon/room/end = pick(deadEnds)
			if(end.layedOut) continue
			deadEnds.Remove(end)
			if(rand() < 1/2)
				continue
			var/list/directions = list(NORTH, SOUTH, EAST, WEST)
			while(directions.len)
				var/direction = pick(directions)
				directions.Remove(direction)
				if(direction & end.doors) continue
				var/dungeon/room/adjacent = getRoom(end.x, end.y, direction)
				if(!adjacent || adjacent == firstRoom) continue
				if(adjacent in deadEnds) continue
				if(adjacent.layedOut) continue
				end.doors |= direction
				adjacent.doors |= turn(direction, 180)
				var/newLayout = dungeonLayoutManager.randomExclave(turn(direction, 180))
				layoutRoom(newLayout, adjacent, newR)
				layoutRoom(dungeonLayoutManager.randomLayout(end.doors), end, newR)
				break
		// Layout Rooms
		for(var/dungeon/room/R in rooms)
			if(R.layedOut) continue
			if(R == firstRoom) continue
			var/layoutGrid = dungeonLayoutManager.randomLayout(R.doors)
			layoutRoom(layoutGrid, R, newR)
			/*for(var/posY = 1 to 9)
				var/oldLength = length(newR.gridText)
				var/linePos = (posY-1)*13 + 1
				var/line = copytext(layoutGrid, linePos, linePos+13)
				var/gridPos = ((R.y-1)*(PLOT_SIZE)+(posY+1))*(PLOT_SIZE*width) + (R.x-1)*PLOT_SIZE + 2 // This is why you don't index arrays at 1
				newR.gridText = "[copytext(newR.gridText, 1, gridPos)][line][copytext(newR.gridText, gridPos+13)]"*/
		for(var/dungeon/room/R in rooms)
			var/fullX = (R.x-1)*PLOT_SIZE
			var/fullY = (R.y-1)*PLOT_SIZE
			if(R.doors & NORTH)
				newR.changeTileAt(fullX+7, fullY+12, /tile/land)
				newR.changeTileAt(fullX+8, fullY+12, /tile/land)
				newR.changeTileAt(fullX+9, fullY+12, /tile/land)
				newR.changeTileAt(fullX+7, fullY+13, /tile/land)
				newR.changeTileAt(fullX+8, fullY+13, /tile/land)
				newR.changeTileAt(fullX+9, fullY+13, /tile/land)
				newR.changeTileAt(fullX+7, fullY+14, /tile/land)
				newR.changeTileAt(fullX+8, fullY+14, /tile/land)
				newR.changeTileAt(fullX+9, fullY+14, /tile/land)
				newR.changeTileAt(fullX+7, fullY+15, /tile/land)
				newR.changeTileAt(fullX+8, fullY+15, /tile/land)
				newR.changeTileAt(fullX+9, fullY+15, /tile/land)
			if(R.doors & SOUTH)
				newR.changeTileAt(fullX+7, fullY+1, /tile/land)
				newR.changeTileAt(fullX+8, fullY+1, /tile/land)
				newR.changeTileAt(fullX+9, fullY+1, /tile/land)
				newR.changeTileAt(fullX+7, fullY+2, /tile/land)
				newR.changeTileAt(fullX+8, fullY+2, /tile/land)
				newR.changeTileAt(fullX+9, fullY+2, /tile/land)
			if(R.doors & EAST)
				newR.changeTileAt(fullX+15, fullY+6, /tile/land)
				newR.changeTileAt(fullX+15, fullY+7, /tile/land)
				newR.changeTileAt(fullX+15, fullY+8, /tile/land)
				newR.changeTileAt(fullX+15, fullY+9, /tile/interior/wallBottom)
				newR.changeTileAt(fullX+15, fullY+10,/tile/interior/wallMiddle)
				newR.changeTileAt(fullX+15, fullY+11,/tile/interior/blackTop)
			if(R.doors & WEST)
				newR.changeTileAt(fullX+1, fullY+6, /tile/land)
				newR.changeTileAt(fullX+1, fullY+7, /tile/land)
				newR.changeTileAt(fullX+1, fullY+8, /tile/land)
				newR.changeTileAt(fullX+1, fullY+9, /tile/interior/wallBottom)
				newR.changeTileAt(fullX+1, fullY+10,/tile/interior/wallMiddle)
				newR.changeTileAt(fullX+1, fullY+11,/tile/interior/blackTop)
		var/fullX = (firstRoom.x-1)*PLOT_SIZE
		var/fullY = (firstRoom.y-1)*PLOT_SIZE
		newR.changeTileAt(fullX+7, fullY+2, /tile/interior/warp)
		newR.changeTileAt(fullX+8, fullY+2, /tile/interior/warp)
		newR.changeTileAt(fullX+9, fullY+2, /tile/interior/warp)
		newR.startPlotCoords = new(firstRoom.x, firstRoom.y)
		return newR
	proc/extendPath(dungeon/room/testRoom)
		var/list/openings = list(NORTH, SOUTH, EAST, WEST)
		var/openDir
		while(openings.len)
			openDir = pick(openings)
			openings.Remove(openDir)
			if(!(openDir&testRoom.openings)) continue
			testRoom.openings &= ~openDir
			var/nextX = testRoom.x
			var/nextY = testRoom.y
			switch(openDir)
				if(NORTH) nextY++
				if(SOUTH) nextY--
				if(EAST ) nextX++
				if(WEST ) nextX--
			if(nextX <= 0 || nextX > width || nextY <= 0 || nextY > height) continue
			var/dungeon/room/nextRoom = getRoom(testRoom.x, testRoom.y, openDir)
			if(nextRoom)
				continue
			testRoom.doors |= openDir
			nextRoom = new(src, nextX, nextY, testRoom)
			return
		openRooms.Remove(testRoom)
		var/loggy = log(2, testRoom.doors)
			// Sorry about this.
			// Directions are bit flags, so each cardinal direction is a power of 2.
			// So if "doors" contains more than one bit, it won't be a power of two,
			// So log(2, doors) won't be an integer.
		if(loggy == round(loggy) && testRoom != firstRoom) deadEnds.Add(testRoom)
	proc/layoutRoom(layout, dungeon/room/_room, region/_region)
		_room.layedOut = TRUE
		for(var/posY = 1 to 9)
			var/linePos = (posY-1)*13 + 1
			var/line = copytext(layout, linePos, linePos+13)
			var/gridPos = ((_room.y-1)*(PLOT_SIZE)+(posY+1))*(PLOT_SIZE*width) + (_room.x-1)*PLOT_SIZE + 2 // This is why you don't index arrays at 1
			_region.gridText = "[copytext(_region.gridText, 1, gridPos)][line][copytext(_region.gridText, gridPos+13)]"



//---- Room Layouts ------------------------------------------------------------

var/dungeon/layoutManager/dungeonLayoutManager = new()
dungeon/layoutManager
	parent_type = /datum
	var
		list/configs[16]
		list/exclaves[8]
	New()
		. = ..()
		for(var/I = 1 to 16)
			configs[I]  = list()
		exclaves[NORTH] = list()
		exclaves[SOUTH] = list()
		exclaves[EAST ] = list()
		exclaves[WEST ] = list()
	proc/registerLayout(gridText, list/excludeConfig, exclave)
		var/noLines = ""
		for(var/line in splittext(gridText, "\n"))
			noLines = "[line][noLines]"
		if(!exclave)
			world << "exclave"
			for(var/I = 1 to 16)
				if(!(I in excludeConfig))
					var/list/config = configs[I]
					config.Add(noLines)
		else
			world << "enclave"
			var/list/exclaveConfig = exclaves[exclave]
			exclaveConfig.Add(noLines)
	proc/randomLayout(openings)
		var/list/configList = configs[openings]
		return pick(configList)
	proc/randomExclave(direction)
		var/list/exclaveConfig = exclaves[direction]
		return pick(exclaveConfig)


//------------------------------------------------------------------------------

world/New()
	. = ..()
	dungeonLayoutManager.registerLayout({"
.............
.............
.............
.............
.............
.............
.............
.............
............."}, list())
	dungeonLayoutManager.registerLayout({"
.............
.............
..%.%...%.%..
.............
.............
.............
..%.%...%.%..
.............
............."}, list())
	dungeonLayoutManager.registerLayout({"
.............
.............
......%......
.....%.%.....
....%...%....
.....%.%.....
......%......
.............
............."}, list())
	dungeonLayoutManager.registerLayout({"
....~~~~~~~~~
....~~~~~~~~~
....~~~~~~~~~
....~........
.............
.............
....~........
....~........
....~........"}, list(1,3,5,7,9,11,13,15))
	dungeonLayoutManager.registerLayout({"
.............
.............
..~~~~~~~~~..
..~~.....~~..
..~~.....~~..
..~~.....~~..
..~~~..~~~~..
.............
............."}, list(2,3,6,7,10,11,14,15))
	dungeonLayoutManager.registerLayout({"
........~....
........~....
........~....
........~....
........~....
........~....
........~....
........~....
........~...."}, null, EAST)
	dungeonLayoutManager.registerLayout({"
.............
.............
~~~~~~~~~~~~~
.............
.............
.............
.............
.............
............."}, null, NORTH)
	dungeonLayoutManager.registerLayout({"
.............
.............
.............
.............
.............
.............
~~~~~~~~~~~~~
.............
............."}, null, SOUTH)
	dungeonLayoutManager.registerLayout({"
....~........
....~........
....~........
....~........
....~........
....~........
....~........
....~........
....~........"}, null, WEST)