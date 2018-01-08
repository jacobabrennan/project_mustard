

//------------------------------------------------------------------------------


//-- Development Utilities -----------------------------------------------------
#define TAG #warn Unfinished


//-- Movement Utilities --------------------------------------------------------

mob/density = FALSE
atom/movable/var/transitionable = FALSE // Most movable atoms cannot move between plots
atom/movable/step_size = 1 // Necessary for all objects to use pixel movement
atom/proc/Bumped(var/atom/movable/bumper)
atom/movable/Bump(var/atom/Obstruction)
	Obstruction.Bumped(src)
	. = ..()
atom/movable/var/movement = MOVEMENT_ALL
atom/movable
	Crossed(atom/movable/crosser)
		. = ..()
		crosser.onCross(src)
	proc/onCross(atom/movable/crosser)
atom/movable
	proc/forceLoc(atom/newLoc)
		var/success = Move(newLoc)
		if(success) return TRUE
		// Handle case where oldLoc.Exit was preventing movement
		var/area/oldLoc = loc
		var/successLeave = Move(null)
		loc = null
		// Handle the case where newLoc.Enter is preventing movement
		success = Move(newLoc)
		loc = newLoc
		if(!successLeave && oldLoc)
			oldLoc.Exited(src, newLoc)
			if(!istype(oldLoc))
				oldLoc = aloc(oldLoc)
				if(istype(oldLoc))
					oldLoc.Exited(src, newLoc)
		if(!success && newLoc)
			newLoc.Entered(src, oldLoc)
		return TRUE
	Del()
		forceLoc(null)
		. = ..()
atom/movable/proc/cardinalTo(atom/movable/target)
	var/deltaX = (target.x*TILE_SIZE+target.step_x+target.bound_width /2) - (x*TILE_SIZE+step_x+bound_width /2)
	var/deltaY = (target.y*TILE_SIZE+target.step_y+target.bound_height/2) - (y*TILE_SIZE+step_y+bound_height/2)
	if(abs(deltaX) >= abs(deltaY))
		if(deltaX >= 0) return EAST
		else return WEST
	else
		if(deltaY >= 0) return NORTH
		else return SOUTH
atom/movable/proc/centerLoc(var/atom/movable/_center)
	forceLoc(_center.loc)
	step_x = _center.step_x + (_center.bound_x) + (_center.bound_width -bound_width )/2
	step_y = _center.step_y + (_center.bound_y) + (_center.bound_height-bound_height)/2


//-- Actor Definition -----------------------------------------------------

actor
	parent_type = /mob
	var
		faction = 0
			// Bit flags that determine how actors interact
		turnDelay = TICK_DELAY
			// Delay, in 10ths of a second, between calls to takeTurn()
			// Can be set to fractional values, bounded by TICK_DELAY
		baseSpeed = 1
			// Number of pixels moved every turn.
			// The actual speed of a combatant is speed / turnDelay.
		roughWalk = 0
			// When determining walking speed, this value is subtracted from the tiles' roughness.
	New()
		. = ..()
		spawn()
			takeTurn()
	proc/takeTurn()
		spawn(turnDelay)
			takeTurn()
	// Movement
	var/gridded = FALSE
		// Moving with go() will guide the actor back into alignment with the 8x8 grid
	proc
		speed()
			var tileTotal = 0
			var totalRough = 0
			for(var/tile/T in locs)
				tileTotal++
				totalRough += T.rough
			var averageRough = totalRough/max(1,tileTotal)
			averageRough -= roughWalk
			return baseSpeed / max(1,averageRough)
		/*go(amount, direction)
			if(!amount) amount = speed()
			if(!direction) direction = dir
			/*. = step(src, direction, amount)
			if(gridded)
				var/oldDir = dir
				if(dir & (NORTH|SOUTH))
					var/pxOffset = ((step_x+4)%8)-4
					if(pxOffset < 0) step(src,EAST,1)
					if(pxOffset > 0) step(src,WEST,1)
				if(dir & (EAST|WEST))
					var/pxOffset = ((step_y+4)%8)-4
					if(pxOffset < 0) step(src,NORTH,1)
					if(pxOffset > 0) step(src,SOUTH,1)
				dir = oldDir*/*/
		translate(deltaX, deltaY)
			var success = 0
			if(deltaY > 0) success += step(src, NORTH, deltaY)
			if(deltaY < 0) success += step(src, SOUTH,-deltaY)
			if(deltaX > 0) success += step(src, EAST , deltaX)
			if(deltaX < 0) success += step(src, WEST ,-deltaX)
			/*
			var/fullX = (x*TILE_SIZE)+step_x + deltaX
			var/tileX = round((fullX-1)/TILE_SIZE)
			var/offsetX = 1+ (fullX-1)%TILE_SIZE
			var/fullY = (y*TILE_SIZE)+step_y + deltaY
			var/tileY = round((fullY-1)/TILE_SIZE)
			var/offsetY = 1+ (fullY-1)%TILE_SIZE
			var success = Move(locate(tileX, tileY, z), 0, offsetX, offsetY)
			if(!success)
				if(
				success += step(src,
				success += Move(locate(tileX, y, z), 0 , offsetX, step_y)
			if(
			if(dir & (EAST|WEST)) dir &= (EAST|WEST)*/
			return success


//-- Math Utilities -------------------------------------------------------

proc
	exp(power)
		return e**power

coord
	var
		x
		y
		z
	New(newX, newY, newZ)
		x = newX
		y = newY
		z = newZ
	toJSON()
		var/list/objectData = ..()
		objectData["x"] = x
		objectData["y"] = y
		if(z != null) objectData["z"] = z
		return objectData
	fromJSON(list/objectData)
		x = objectData["x"]
		y = objectData["y"]
		if(objectData["z"]) z = objectData["z"]
	proc/copy()
		return new /coord(x, y, z)
	proc/operator+(coord/addCoord)
		return new /coord(x + addCoord.x, y + addCoord.y, z + addCoord.z)
	proc/operator-(coord/addCoord)
		return new /coord(x - addCoord.x, y - addCoord.y, z - addCoord.z)
	proc/operator*(coord/addCoord)
		return new /coord(x * addCoord.x, y * addCoord.y, z * addCoord.z)
	proc/operator/(coord/addCoord)
		return new /coord(x / addCoord.x, y / addCoord.y, z / addCoord.z)


vector
	var
		mag
		dir
	New(newM,newD)
		mag = newM
		dir = newD
	toJSON()
		var/list/objectData = ..()
		objectData["mag"] = mag
		objectData["dir"] = dir
		return objectData
	fromJSON(list/objectData)
		mag = objectData["mag"]
		dir = objectData["dir"]
	proc/copy()
		return new /vector(mag,dir)

rect
	parent_type = /coord
	var
		width
		height
	New(newX, newY, newWidth, newHeight)
		. = ..()
		width = newWidth
		height = newHeight
	toJSON()
		var/list/objectData = ..()
		objectData["width"]  = width
		objectData["height"] = height
		return objectData
	fromJSON(list/objectData)
		. = ..()
		width  = objectData["width"]
		height = objectData["height"]
	copy()
		var/rect/copy = ..()
		copy.width = width
		copy.height = height
		return copy
proc
	coord(x, y, z) return new /coord(x, y, z)
	vector(_m, _d) return new /vector(_m, _d)
	rect(x, y, w, h) return new /rect(x, y, w, h)

proc/array()
	var/array/newArray = new()
	for(var/value in args)
		newArray.add(value)
	return newArray
array
	var
		list/_list
		length
	New(_length)
		. = ..()
		_list = new(_length)
		length = _length
	toJSON()
		var/list/objectData = ..()
		objectData["length"]  = length
		objectData["_list"] = list2JSON(_list)
		return objectData
	fromJSON(list/objectData)
		. = ..()
		setLength(objectData["length"])
		_list = json2Object(objectData["_list"])
	proc
		setLength(value)
			_list.len = value
			length = value
		//
		// Copy Cut Find Insert Join Swap
		add()
			for(var/value in args)
				_list.Add(value)
			length = _list.len
		remove()
			for(var/value in args)
				_list.Remove(value)
			length = _list.len
		find(value)
			var index = _list.Find(value)
			return index-1 // Correct for DM's index 1 lists
			// Even works for "not found" 0 => -1
		//
		operator[](index)
			ASSERT(istype(_list))
			return _list[index+1] // Correct for DM's index 1 lists
		operator[]=(index, value)
			return _list[index+1] = value

proc/grid(width, height)
	return new /grid(width, height)
grid
	var
		array/array
		width
		height
	New(_width, _height)
		. = ..()
		width = _width || 0
		height = _height || 0
		array = new(width*height)
	toJSON()
		var/list/objectData = ..()
		objectData["width"]  = width
		objectData["height"] = height
		objectData["array"] = array.toJSON()
		return objectData
	fromJSON(list/objectData)
		. = ..()
		width  = objectData["width"]
		height = objectData["height"]
		array = json2Object(objectData["array"])
	proc
		contents()
			return array._list
		get(posX, posY)
			if(posX >= width || posY >= height) CRASH("Grid index out of bounds")
			var compoundIndex = posX + posY*width
			return array[compoundIndex] // Correct for DM's index 1 lists
		put(posX, posY, value)
			if(posX >= width || posY >= height) CRASH("Grid index out of bounds")
			var compoundIndex = posX + posY*width
			array[compoundIndex] = value
		resize(newWidth, newHeight)
			var /grid/newGrid = new(newWidth, newHeight)
			for(var/posX = 0 to width-1)
				for(var/posY = 0 to height-1)
					newGrid.put(posX, posY, get(posX, posY))
			width = newWidth
			height = newHeight
			array = newGrid.array
	/*proc
		operator[](posX, posY)
			var compoundIndex = posX + posY*width
			return array[compoundIndex] // Correct for DM's index 1 lists
		operator[]=(posX, posY, value)
			world << "[posX],[posY],[value]"
	*/

//-- Mapping Utilities ----------------------------------------------------

proc/aloc(atom/contained)
	if(!contained) return null
	var/turf/locTurf = locate(contained.x, contained.y, contained.z)
	if(!locTurf) return null
	return locTurf.loc
proc/plot(atom/contained)
	var/plot/plotArea/PA = aloc(contained)
	if(istype(PA)) return PA.plot
proc/terrain(atom/contained)
	var/plot/P = plot(contained)
	var/terrain/T = terrains[P.terrain]
	if(istype(T)) return T
proc/game(atom/contained)
	var gameId
	// Case: gameId supplied
	if(istext(contained))
		gameId = contained
	if(!gameId)
	// Case: object has gameId
		if("gameId" in contained.vars)
			gameId = contained:gameId
	// Case: object is on the map
		else
			var/plot/P = plot(contained)
			if(P) gameId = P.gameId
	if(gameId)
		return system.getGame(gameId)

//-- File System Utilities ------------------------------------------------

proc/replaceFile(filePath, fileText)
	if(fexists(filePath)) fdel(filePath)
	return text2file(fileText, filePath)


//-- Saving / Loading Utilities -------------------------------------------

datum/proc/toJSON() // hook
	var/jsonObject = list()
	jsonObject["typePath"] = type
	return jsonObject

datum/proc/fromJSON(list/objectData) // hook

proc
	json2Object(list/objectData) // utility
		// Handle Primitive Types (strings, numbers, null)
		if(!istype(objectData))
			return objectData
		// Handle objects from toJSON (having entries for "typepath")
		var/typePath = text2path(objectData["typePath"])
		if(typePath)
			var/datum/D = new typePath()
			D.fromJSON(objectData)
			return D
		// Handle Lists (recursive)
		return json2List(objectData)
	json2List(list/objectData)
		var /list/objectList = new()
		for(var/data in objectData)
			var newObject = json2Object(data)
			objectList.Add(newObject)
		return objectList
	list2JSON(list/array) // utility
		var/list/jsonList = new(array.len)
		for(var/I = 1 to array.len)
			var/datum/indexed = array[I]
			if(istype(indexed))
				jsonList[I] = indexed.toJSON(indexed)
			else
				jsonList[I] = json_encode(indexed)
		return jsonList


//-- Key State Control (with Kaiochao.AnyMacro) ---------------------------

client/New()
	. = ..()
	macros.client = src
interface/proc
	commandDown()
	commandUp()
button_tracker
	var/client/client
	var/list/preferences = list(
		North=NORTH, Numpad8=NORTH, W=NORTH,
		South=SOUTH, Numpad2=SOUTH, S=SOUTH,
		East = EAST, Numpad6= EAST, D= EAST,
		West = WEST, Numpad4= WEST, A= WEST,
		Space=PRIMARY,
		Z=SECONDARY, X=TERTIARY, C=QUATERNARY,
		Tab  = STATUS
	)
	var/commands = 0
	//var/list/commandLoops = list()
	// When a button is pressed, send a message to the output target.
	Pressed(button)
		var command = preferences[button]
		if(!command) return
		commands |= command
		client.interface.commandDown(command)
		//var/button_tracker/commandLoop/oldLoop = commandLoops["[command]"]
		//del oldLoop
		//commandLoops["[command]"] = new/button_tracker/commandLoop(client, button, command)
	// When a button is released, send a message to the output target.
	Released(button)
		var command = preferences[button]
		if(!command) return
		commands &= ~command
		client.interface.commandUp(command)
	proc/checkCommand(command)
		return commands&command
	/*proc/commandLoop(key, command)
		set background = TRUE
		while(client.macros.IsPressed(key))
			client.interface.commandHold(command);
			sleep(1 * world.tick_lag)
	commandLoop
		parent_type = /datum
		New(client/client, key, command)
			spawn()
				while(client && client.macros.IsPressed(key))
					client.interface.commandHold(command);
					sleep(1 * world.tick_lag)
				del src*/
