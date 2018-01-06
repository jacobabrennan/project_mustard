/*==============================================================================

	The level generator is a scaffold to create new proceedurally generated
	levels. It is private to the mapManager, and is only accessed through the
	method mapManager.generateLevel. Further, the only method of the generator
	accessed by the map manager is the generate method; everything else is
	private to the levelGenerator.

	The levelGenerator is a prototype. To use it, you must create a new
	instance, and call generate with the parameters for the new level:
		{
			id: 'string', // Optional. The name of this level.
			width: integer, // Optional.
			height: integer, // Optional.
			roomSideMax: integer, // Optional.
			roomSideMin: integer, // Optional.
			hallLengthMax: integer, // Optional.
			hallLengthMin: integer, // Optional.
			placeStairsUp: boolean, // Optional, true by default.
			placeStairsDown: boolean, // Optional, true by default.
		}
	It returns a new level object, ready for use.

==============================================================================*/


//------------------------------------------------------------------------------

var/mapGenerator/mapGenerator = new()
mapGenerator
	proc/generate(_baseText, _width, _height, _roomSideMax, _roomSideMin, _hallLengthMax, _hallLengthMin, _startX, _startY)
		var/mapGenerator/generator/G = new()
		return G.generate(_baseText, _width, _height, _roomSideMax, _roomSideMin, _hallLengthMax, _hallLengthMin, _startX, _startY)
	generator
		parent_type = /datum
		var
			roomSideMax= PLOT_SIZE*2
			roomSideMin= 3
			hallLengthMax= 20
			hallLengthMin= 5
			width= 64
			height= 64
			depth= null
			//
			mapText= null
			list/openings= null
			list/openingsHash= null
			list/rooms= null
			list/halls= null

		proc/generate(_baseText, _width, _height, _roomSideMax, _roomSideMin, _hallLengthMax, _hallLengthMin, _startX, _startY)
			// Configure generation options and defaults.
			roomSideMax = _roomSideMax || roomSideMax
			roomSideMin = _roomSideMin || roomSideMin
			hallLengthMax = (!isnull(_hallLengthMax))? _hallLengthMax : hallLengthMax
			hallLengthMin = _hallLengthMin || hallLengthMin
			width  = _width  || width
			height = _height || height
			var/startX = _startX || 1+round(rand()*(width -2))
			var/startY = _startY || 1+round(rand()*(height-2))
			// Generate blank map block.
			if(!_baseText)
				mapText = ""
				for(var/posY = 0; posY < width; posY++)
					for(var/posX = 0; posX < width; posX++)
						if(posY==0 || posX==0 || posY==width-1 || posX==height-1)
							mapText += "#"
						else
							mapText += "%"
						if(rand()*1000 < 1)
							world << "-\..."
							sleep(1)
			else
				mapText = _baseText
			// Prep open nodes lists.
			openings = list()
			openingsHash = list()
			rooms = list()
			// Randomly place First Room.
			var/tries = 100
			while(tries-- > 0)
				var/roomDirection = pick(NORTH,SOUTH,EAST,WEST)
				var/list/roomDimentions = placeRoom(startX, startY, roomDirection)
				if(roomDimentions)
					rooms[++rooms.len] = roomDimentions
					break
			// Place More Rooms and Halls
			halls = list()
			while(openings.len)
				var/list/opening = pick(openings)
				var/list/rotatedCoords = getCoordsRotate(opening["x"], opening["y"], 1, 0, opening["direction"])
				if(rand() < 1/2 && hallLengthMax) // Place Hall
					var/list/hallDimentions = placeHall(opening["x"], opening["y"], opening["direction"])
					if(hallDimentions)
						halls[++halls.len] = hallDimentions
					else
						closeOpening(opening["x"], opening["y"], "#")
				else // Place Room
					var/list/roomDimentions = placeRoom(rotatedCoords[1], rotatedCoords[2], opening["direction"])
					if(roomDimentions)
						rooms[++rooms.len] = roomDimentions
					else
						closeOpening(opening["x"], opening["y"], "#")
				if(rand()*100 < 2)
					world << ".\..."
					sleep(1)
			//
			/*var/mapString = ""
			for(var/I = height-1; I >= 0; I--)
				var/S = copytext(mapText, I*width+1, (I+1)*width+1)
				mapString += S+"\n"*/
			return mapText
		proc/getCoordsRotate(x1, y1, x2, y2, direction)
			switch (direction)
				if(NORTH) return list(x1-y2, y1+x2)
				if(WEST ) return list(x1-x2, y1-y2)
				if(SOUTH) return list(x1+y2, y1-x2)
				else      return list(x1+x2, y1+y2)
		proc/getDirectionRotate(oldDirection, rotateDirection)
			var rotateDegrees = 0
			switch(rotateDirection)
				if(EAST 	) rotateDegrees =   0
				if(NORTHEAST) rotateDegrees =  45
				if(NORTH	) rotateDegrees =  90
				if(NORTHWEST) rotateDegrees = 135
				if(WEST	    ) rotateDegrees = 180
				if(SOUTHWEST) rotateDegrees = 225
				if(SOUTH	) rotateDegrees = 270
				if(SOUTHEAST) rotateDegrees = 315
			return turn(oldDirection, rotateDegrees)
		proc/getTile(x, y)
			if(x < 1 || x > width || y < 1 || y > height)
				return " "
			var compoundIndex = COMPOUND_INDEX(x, y, width)
			return copytext(mapText, compoundIndex, compoundIndex+1)
		proc/setTile(x, y, newValue)
			if(x < 1 || x > width || y < 1 || y > height)
				return null
			var compoundIndex = COMPOUND_INDEX(x, y, width)
			var halfFirst  = copytext(mapText, 1, compoundIndex  )
			var halfSecond = copytext(mapText, compoundIndex+1)
			mapText = halfFirst+newValue+halfSecond
			return newValue
		proc/placeRoom(x, y, direction)
			/**
			 *  Return null if the room could not be placed, a room with the
			 *	  following structure if placement is successful:
			 *	  {
			 *		  x: integer,
			 *		  y: integer,
			 *		  width: integer,
			 *		  height: integer
			 *	  }
			 **/
			if(!direction)
				direction = pick(EAST,WEST,NORTH,SOUTH)
			var/max = roomSideMax-1
			var/min = -(roomSideMax-1)
			var/list/intervals = list()
			// Determine dimensions of room to fit within given space.
			for(var/testDepth = 0; testDepth < roomSideMax; testDepth++)
				var/list/testInterval = list(max,min)
				var/list/turnedCoords = getCoordsRotate(x, y, testDepth, 0, direction)
				var/testTile = getTile(turnedCoords[1],turnedCoords[2]);
				if(testTile != "%")
					break
				for(var/testBreadth = 0; testBreadth <= max; testBreadth++)
					turnedCoords = getCoordsRotate(x, y, testDepth, testBreadth, direction)
					testTile = getTile(turnedCoords[1],turnedCoords[2])
					if(testTile != "%")
						max = testBreadth-1
						testInterval[1] = testBreadth-1
						break
				for(var/testBreadth = -1; testBreadth >= min; testBreadth--)
					turnedCoords = getCoordsRotate(x, y, testDepth, testBreadth, direction)
					testTile = getTile(turnedCoords[1],turnedCoords[2])
					if(testTile != "%")
						min = testBreadth+1
						testInterval[2] = testBreadth+1
						break
				if(1+testInterval[1]-testInterval[2] < roomSideMin)
					break
				intervals[++intervals.len] = testInterval
			//
			if(intervals.len < roomSideMin)
				return null
			//
			var/wallIndex = rand(roomSideMin, intervals.len)
			var/wallDepth = wallIndex+1
			var/list/wallInterval = intervals[wallIndex]
			var/intervalLength = 1+wallInterval[1]-wallInterval[2]
			var/wallBreadth = rand(roomSideMin, min(roomSideMax,intervalLength))
			var/cornerMaxOffset = min(wallBreadth-1, wallInterval[1])
			var/cornerMinOffset = max(0, -1+wallBreadth+wallInterval[2])
			var/cornerBreadthOffset = rand(cornerMaxOffset, cornerMinOffset)
			var/backStep = getCoordsRotate(x, y, -1, 0, direction)
			var/doorPlaced = placeDoor(backStep[1], backStep[2])
			// Collect Info about room coordinates and size.
			var minX = 1000000000
			var maxX = -1000000000
			var minY = 1000000000
			var maxY = -1000000000
			// Place room: floor, open nodes on sides, and blocks at corners.
			for(var/posDepth = -1; posDepth < wallDepth+1; posDepth++)
				for(var/posBreadth = -1; posBreadth < wallBreadth+1; posBreadth++)
					var offsetX = posDepth
					var offsetY = cornerBreadthOffset - posBreadth
					var turnedCoords = getCoordsRotate(x, y, offsetX, offsetY, direction)
					// Skip the door, which was placed earlier.
					if(doorPlaced && turnedCoords[1] == backStep[1] && turnedCoords[2] == backStep[2]) continue
					// Place walls at corners.
					if(\
						posDepth == -1        && posBreadth == -1          ||\
						posDepth == wallDepth && posBreadth == -1          ||\
						posDepth == -1        && posBreadth == wallBreadth ||\
						posDepth == wallDepth && posBreadth == wallBreadth\
					) setTile(turnedCoords[1], turnedCoords[2], "#")
					// Place open nodes along the sides.
					else if(posDepth == -1       )
						var/turnedDirection = getDirectionRotate(direction, WEST)
						placeOpening(turnedCoords[1], turnedCoords[2], turnedDirection)
					else if(posDepth == wallDepth)
						var/turnedDirection = getDirectionRotate(direction, EAST)
						placeOpening(turnedCoords[1], turnedCoords[2], turnedDirection)
					else if(posBreadth == -1)
						var/turnedDirection = getDirectionRotate(direction, NORTH)
						placeOpening(turnedCoords[1], turnedCoords[2], turnedDirection)
					else if(posBreadth == wallBreadth)
						var/turnedDirection = getDirectionRotate(direction, SOUTH)
						placeOpening(turnedCoords[1], turnedCoords[2], turnedDirection)
					// Place floor in center. Record dimentions.
					else
						if(     turnedCoords[1] < minX) minX = turnedCoords[1]
						else if(turnedCoords[1] > maxX) maxX = turnedCoords[1]
						if(     turnedCoords[2] < minY) minY = turnedCoords[2]
						else if(turnedCoords[2] > maxY) maxY = turnedCoords[2]
						setTile(turnedCoords[1], turnedCoords[2], ".")
			// Return basic room info.
			var/list/roomInfo = list(
				"x"= minX,
				"y"= minY,
				"width"= (maxX-minX)+1,
				"height"= (maxY-minY)+1
			)
			return roomInfo
		proc/placeHall(x, y, direction)
			/**
			 *  Return null if the room could not be placed, a room with the
			 *  following structure if placement is successful:
			 *	  {
			 *		  x: integer,
			 *		  y: integer,
			 *		  width: integer,
			 *		  height: integer
			 *	  }
			 **/
			if(!direction)
				direction = pick(EAST,WEST,NORTH,SOUTH);
			var/max = hallLengthMax
			var/min = hallLengthMin
			// Go forward young @!
			// Lay out tiles in middle and on sides.pla
			// If something encountered, stop.
			var/list/currentStep = list(x,y)
			var/nextStep
			var/hallCount = rand(min, max)
			var/list/path = list()
			path[++path.len] = currentStep
			while(hallCount)
				hallCount--
				nextStep = getCoordsRotate(currentStep[1], currentStep[2], 1, 0, direction)
				currentStep = nextStep
				if(!nextStep)
					hallCount = 0
					break
				if(getTile(nextStep[1], nextStep[2]) == "%")
					path[++path.len] = nextStep
				else if(getOpening(nextStep[1], nextStep[2]))
					path[++path.len] = nextStep
					hallCount = 0
					break
				else
					hallCount = 0
					break
			if(path.len >= min+1) // Plus 1 for innitial door, which is handled in the path.
				for(var/pathI = 1; pathI <= path.len; pathI++)
					var/pathStep = path[pathI]
					var/leftDir = getDirectionRotate(direction, NORTH)
					var/leftWall = getCoordsRotate(pathStep[1], pathStep[2], 1, 0, leftDir)
					var/rightDir = getDirectionRotate(direction, SOUTH)
					var/rightWall = getCoordsRotate(pathStep[1], pathStep[2], 1, 0, rightDir)
					if(pathI == 1)
						placeOpening(pathStep[1], pathStep[2], getDirectionRotate(direction, WEST), TRUE)
						closeOpening(leftWall[1], leftWall[2], "#")
						closeOpening(rightWall[1], rightWall[2], "#")
					else if(pathI == path.len)
						placeOpening(pathStep[1], pathStep[2], direction, TRUE)
						closeOpening(leftWall[1], leftWall[2], "#")
						closeOpening(rightWall[1], rightWall[2], "#")
					else
						setTile(pathStep[1], pathStep[2], " ")
						placeOpening(leftWall[1], leftWall[2], leftDir, FALSE, TRUE)
						placeOpening(rightWall[1], rightWall[2], rightDir, FALSE, TRUE)
			else // Place Wall at innitial door location.
				var/firstStep = path[1]
				closeOpening(firstStep[1], firstStep[2],"#")
			// return roomInfo;
			return TRUE
		proc/getOpening(x, y)
			return openingsHash["[x],[y]"]
		proc/closeOpening(x, y, newValue)
			var/list/opening = getOpening(x, y)
			if(!opening)
				setTile(x, y, newValue)
				return
			openings[openings.Find(opening)] = "derp"//Remove(opening)
			openings.Remove("derp")
			openingsHash[opening["index"]] = null
			if(newValue)
				setTile(x, y, newValue)
		//
		proc/placeOpening(x, y, direction, forceDoor, hall)
			var/list/oldOpening = getOpening(x, y)
			var newDirection = direction
			if(oldOpening)
				newDirection |= oldOpening["direction"]
			var oldTile = getTile(x, y)
			if(!oldOpening)
				if(forceDoor && oldTile == "#")
					var/list/nextCoords = getCoordsRotate(x, y, 1, 0, direction)
					var/nextTile = getTile(nextCoords[1], nextCoords[2])
					if(nextTile == ".")
						placeDoor(x, y, TRUE)
						return
					else
						return
				else if(oldTile != "%")
					return
			switch(newDirection)
				if(NORTHEAST,NORTHWEST,SOUTHEAST,SOUTHWEST)
					closeOpening(x, y, "#")
					return
				if(3,12) // EAST+WEST
					if(forceDoor && oldOpening["hall"] || hall && oldOpening["forceDoor"]) // Connect Hallways
						closeOpening(x, y, " ")
						return
					var/force = forceDoor || oldOpening["forceDoor"]
					if(force || rand()*32 > 31) // TODO: MAGIC NUMBERS!
						placeDoor(x, y, TRUE)
					else
						closeOpening(x, y, "#")
					return
			var/list/opening = list(
				"x"= x,
				"y"= y,
				"direction"= newDirection,
				"index"= "[x],[y]",
				"forceDoor"= (forceDoor? forceDoor : FALSE),
				"hall"= (hall? hall : FALSE)
			)
			openings[++openings.len] = opening
			openingsHash[opening["index"]] = opening
			setTile(x, y, "[newDirection]")
		proc/placeDoor(x, y, force)
			var/list/selfOpening = getOpening(x, y)
			if(!selfOpening && !force)
				return FALSE
			//
			var tileNorth = getTile(x  , y+1)
			var tileSouth = getTile(x  , y-1)
			var tileEast  = getTile(x+1, y  )
			var tileWest  = getTile(x-1, y  )
			if(tileNorth=="+" || tileNorth=="'" ||\
			   tileSouth=="+" || tileSouth=="'" ||\
			   tileEast =="+" || tileEast =="'" ||\
			   tileWest =="+" || tileWest =="'" )
				closeOpening(x, y, "#")
				return FALSE
			//
			var/list/testOpening = getOpening(x+1, y  )
			if(testOpening) closeOpening(x+1, y  , "#")
			testOpening = getOpening(x-1, y  )
			if(testOpening) closeOpening(x-1, y  , "#")
			testOpening = getOpening(x  , y+1)
			if(testOpening) closeOpening(x  , y+1, "#")
			testOpening = getOpening(x  , y-1)
			if(testOpening) closeOpening(x  , y-1, "#")
			if(rand() > 1/3)
				closeOpening(x, y, "+")
			else
				closeOpening(x, y, "'")
			return TRUE