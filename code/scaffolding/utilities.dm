

//-- Development Utilities -----------------------------------------------------

#define TAG #warn Unfinished
client/verb/forceReboot()
	system.restartWithoutSave()
client/New()
	. = ..()
	spawn(10)
		world.SetMedal("Logged into the fucking game hell yeah", src)


//-- Graphic Utilities ---------------------------------------------------------

proc/getAppearance(displayable)
	var /obj/base = new()
	base.overlays.Add(displayable)
	for(var/newAppearance in base.overlays)
		return newAppearance


//-- String Utilities ----------------------------------------------------------


stringGrid
	var
		list/segments
		width
		height
		segmentLength = 1000
	New(_width, _height, newString)
		. = ..()
		width = _width || 0
		height = _height || 0
		var totalLength = width*height
		if(newString)
			segments = new()
			var I = 0
			while(I*segmentLength < length(newString))
				var newSegment = copytext(newString, I*segmentLength+1, (++I)*segmentLength+1)
				segments.Add(newSegment)
		else
			segments = new(ceil(totalLength/segmentLength))
	toJSON()
		var/list/objectData = ..()
		objectData["width"]  = width
		objectData["height"] = height
		objectData["segments"] = segments
		return objectData
	fromJSON(list/objectData)
		. = ..()
		width  = objectData["width"]
		height = objectData["height"]
		segments = objectData["segments"]
	proc
		get(posX, posY)
			if(posX >= width || posY >= height || posX < 0 || posY < 0) CRASH("Grid index out of bounds")
			var compoundIndex = posX + posY*width
			var segmentIndex = round(compoundIndex/segmentLength)
			var segment = segments[segmentIndex+1] // Correct for DM's 1 index lists
			var charIndex = (compoundIndex - (segmentIndex * segmentLength)) +1 // Correct for DM's 1 index lists
			return copytext(segment, charIndex, charIndex+1)
		put(posX, posY, value)
			if(posX >= width || posY >= height || posX < 0 || posY < 0) CRASH("Grid index out of bounds")
			var compoundIndex = posX + posY*width
			var segmentIndex = round(compoundIndex/segmentLength)
			var segment = segments[segmentIndex+1] // Correct for DM's 1 index lists
			var charIndex = (compoundIndex - (segmentIndex * segmentLength)) +1 // Correct for DM's 1 index lists
			segments[segmentIndex+1] = "[copytext(segment, 1, charIndex)][value][copytext(segment, charIndex+1)]"


//-- Math Utilities ------------------------------------------------------------

proc
	exp(power)
		return e**power
	atan2(X, Y)
		if(!X && !Y) return 0
		return Y >= 0 ? arccos(X / sqrt(X * X + Y * Y)) : -arccos(X / sqrt(X * X + Y * Y))
	ceil(N)
		return -round(-N)



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
	//
	proc/copy()
		return new type(x, y, z)
	proc/place(atom/movable/M)
		return M.forceLoc(locate(x, y, z))
	// Operator Redefinition
	proc
		operator+(coord/addCoord)
			return new /coord(x + addCoord.x, y + addCoord.y, z + addCoord.z)
		operator-(coord/addCoord)
			return new /coord(x - addCoord.x, y - addCoord.y, z - addCoord.z)
		operator*(coord/addCoord)
			return new /coord(x * addCoord.x, y * addCoord.y, z * addCoord.z)
		operator/(coord/addCoord)
			return new /coord(x / addCoord.x, y / addCoord.y, z / addCoord.z)

atomicCoord
	parent_type = /coord
	var
		stepX
		stepY
	New(newX, newY, newZ, newStepX, newStepY)
		var /atom/movable/model = newX
		// Get coordinates from arguments
		if(!istype(model))
			. = ..()
		// Copy coordinates from atom
		else
			newX = model.x
			newY = model.y
			newZ = model.z
			. = ..(newX, newY, newZ)
			newStepX = model.step_x
			newStepY = model.step_y
		//
		stepX = newStepX
		stepY = newStepY
	toJSON()
		var/list/objectData = ..()
		objectData["stepX"] = stepX
		objectData["stepY"] = stepY
		return objectData
	fromJSON(list/objectData)
		. = ..()
		stepX = objectData["stepX"]
		stepY = objectData["stepY"]
	//
	copy()
		var /atomicCoord/C = ..()
		C.stepX = stepX
		C.stepY = stepY
		return C
	place(atom/movable/M)
		. = ..()
		M.step_x = stepX
		M.step_y = stepY


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
	proc/from(atom/movable/start, atom/movable/end)
		var deltaX = (end.x*TILE_SIZE + end.step_x + end.bound_width /2) - (start.x*TILE_SIZE + start.step_x + start.bound_width /2)
		var deltaY = (end.y*TILE_SIZE + end.step_y + end.bound_height/2) - (start.y*TILE_SIZE + start.step_y + start.bound_height/2)
		mag = sqrt(deltaX*deltaX + deltaY*deltaY)
		if(mag)
			dir = atan2(deltaX, deltaY)
			rotate(0)
	proc/rotate(degrees)
		dir += degrees
		while(dir < 0) dir += 360
		while(dir >= 360) dir -= 360

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
			if(posX >= width || posY >= height || posX < 0 || posY < 0) CRASH("Grid index out of bounds")
			var compoundIndex = posX + posY*width
			return array[compoundIndex]
		put(posX, posY, value)
			if(posX >= width || posY >= height || posX < 0 || posY < 0) CRASH("Grid index out of bounds")
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


//-- Atomic Conversion Utilities -----------------------------------------------

proc
	coords2ScreenLoc(x, y, width, height)
		// Default width and height to 0, and round to tile increments
		// Width & Height don't work in px increments in screen_loc
		if(!width )  width = 0
		else width  = -round(-width /TILE_SIZE) * TILE_SIZE
		if(!height) height = 0
		else height = -round(-height/TILE_SIZE) * TILE_SIZE
		// Split coordinates into atomic & pixel components
		var atomX = round(x/TILE_SIZE)+1
		var atomY = round(y/TILE_SIZE)+1
		var pixelX = x%TILE_SIZE
		var pixelY = y%TILE_SIZE
		// Construct string for SOUTHWEST corner
		var xString = "[atomX]"
		if(pixelX) xString = "[xString]:[pixelX]"
		var yString = "[atomY]"
		if(pixelY) yString = "[yString]:[pixelY]"
		var stringSW = "[xString],[yString]"
		// If we don't need to stretch anything, return the string
		if(!width && !height)
			return stringSW
		// Otherwise, compute coordinates for NORTHEAST corner
		if(width ) x = x+ (width -TILE_SIZE)
		if(height) y = y+ (height-TILE_SIZE)
		// Split coordinates into atomic & pixel components
		atomX = round(x/TILE_SIZE)+1
		atomY = round(y/TILE_SIZE)+1
		pixelX = x%TILE_SIZE
		pixelY = x%TILE_SIZE
		// Construct string for SOUTHWEST corner
		xString = "[atomX]"
		if(pixelX) xString = "[xString]:[pixelX]"
		yString = "[atomY]"
		if(pixelY) yString = "[yString]:[pixelY]"
		// Construct and return final string
		return "[stringSW] to [xString],[yString]"


//-- Saving / Loading Utilities ------------------------------------------------

proc/replaceFile(filePath, fileText)
	if(fexists(filePath)) fdel(filePath)
	return text2file(fileText, filePath)

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


//-- Key State Control (with Kaiochao.AnyMacro) --------------------------------

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
		Tab  = BACK
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
