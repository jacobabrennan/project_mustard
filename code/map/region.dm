

//-- Region - Organizes movement through the game on the largest scale ---------

region
	var
		gameId // The game instance this region belongs to
		id
		loaded = FALSE
		coord/mapOffset // Used to place region on map offset from player's personal mapping area.
		width
		height
		grid/plots
		list/activePlots = list()
		coord/entrance // Mostly for use in dungeons
		defaultTerrain
	//
	New(_regionId)
		. = ..()
		plots = new()
		if(_regionId)
			id = ckey(_regionId) // This becomes the identity on the file system


//-- Saving & Loading ----------------------------------------------------------

	toJSON()
		var/list/objectData = ..()
		objectData["id"] = id
		objectData["mapOffset"] = mapOffset?.toJSON()
		objectData["width"] = width
		objectData["height"] = height
		var /stringGrid/S = system.map.gridData[id]
		objectData["gridText"] = S.toJSON()
		objectData["plots"] = plots.toJSON()
		objectData["defaultTerrain"] = defaultTerrain || "forest"
		if(entrance) objectData["entrance"] = entrance.toJSON()
		return objectData
	fromJSON(list/objectData)
		id = objectData["id"]
		mapOffset = json2Object(objectData["mapOffset"])
		width = objectData["width"]
		height = objectData["height"]
		defaultTerrain = objectData["defaultTerrain"]
		world.maxx = max(world.maxx, PLOT_SIZE*width)
		world.maxy = max(world.maxy, PLOT_SIZE*height)
		if(objectData["entrance"]) entrance = json2Object(objectData["entrance"])
		plots = json2Object(objectData["plots"])
		setLocation(mapOffset.x, mapOffset.y, mapOffset.z)
		setSize()


//-- Configuring Location & Size -----------------------------------------------

	//-- Cache & Retrieve Z level --------------------
	var/_z
	proc/z() // Calculate atomic Z level from map offset and game map allocation
		if(_z) return _z
		var/game/G = system.getGame(gameId)
		_z = G.zOffset + mapOffset.z
		return _z

	//-- Set Size & Location -------------------------
	proc/setLocation(_x, _y, _z)
		mapOffset = new(_x, _y, _z)
	proc/setSize(setWidth, setHeight, _defaultTerrain)
		if(_defaultTerrain)	defaultTerrain = _defaultTerrain
		if((setWidth && setWidth != width) || (setHeight && setHeight != height))
			return resize(setWidth, setHeight, defaultTerrain)
		//
		del _regionMarker
		_regionMarker = new(null, src)
		// Set to new metrics
		var/fullWidth  = PLOT_SIZE*width
		var/fullHeight = PLOT_SIZE*height
		// Resize world if needbe
		world.maxx = max(world.maxx, (mapOffset.x*PLOT_SIZE)+fullWidth)
		world.maxy = max(world.maxy, (mapOffset.y*PLOT_SIZE)+fullHeight)
		world.maxz = max(world.maxz, z())
		// Configure plot
		for(var/posX = 0 to width-1)
			for(var/posY = 0 to height-1)
				var /plot/P = getPlot(posX, posY)
				P.x = posX
				P.y = posY
				P.gameId = gameId
				P.regionId = id
				if(P.warpId)
					setWarp(P.warpId, P)
		// For map editor sake, add region marker to unrevealed areas
		for(var/posY = 0 to fullHeight-1)
			for(var/posX = 0 to fullWidth-1)
				var /turf/T = locate(
					(mapOffset.x*PLOT_SIZE)+posX+1,
					(mapOffset.y*PLOT_SIZE)+posY+1,
					z()
				)
				_regionMarker.contents.Add(T)
	proc/resize(setWidth, setHeight, defaultTerrain)
		del _regionMarker
		_regionMarker = new(null, src)
		// Unreveal any old plots
		for(var/plot/P in plots.contents())
			P.unreveal()
		// Save old Data
		var /grid/oldPlots = plots
		var /stringGrid/oldGridText = system.map.gridData[id]
		// Set to new metrics
		warpPlots = new()
		width  = setWidth  || DEFAULT_PLOTS
		height = setHeight || DEFAULT_PLOTS
		if(!_defaultTerrain)
			_defaultTerrain = defaultTerrain || "forest"
		var/fullWidth  = PLOT_SIZE*width
		var/fullHeight = PLOT_SIZE*height
		// Resize world if needbe
		world.maxx = max(world.maxx, (mapOffset.x*PLOT_SIZE)+fullWidth)
		world.maxy = max(world.maxy, (mapOffset.y*PLOT_SIZE)+fullHeight)
		world.maxz = max(world.maxz, z())
		// Populate Plots
		plots = new(width, height)
		for(var/posX = 0 to width-1)
			for(var/posY = 0 to height-1)
				var /plot/P
				// Try to populate from old plots
				if(posX < oldPlots.width && posY < oldPlots.height)
					P = oldPlots.get(posX, posY)
					plots.put(posX, posY, P)
				// Otherwise, create new plots
				else
					P = new(id)
					plots.put(posX, posY, P)
					P.x = posX
					P.y = posY
					//P.terrain = _defaultTerrain
				// Properly Configure Plot
				P.gameId = gameId
				if(P.warpId)
					setWarp(P.warpId, P)
		// Delete any old unused plots
		for(var/plot/P in oldPlots.contents())
			if(P in plots.contents()) continue
			del P
		// Generate Grid Text
		var newGridText = ""
		if(oldGridText)	//Try to populate from old data
			var oldFullWidth  = PLOT_SIZE*oldPlots.width
			var oldFullHeight = PLOT_SIZE*oldPlots.height
			for(var/posY = 0 to fullHeight-1)
				for(var/posX = 0 to fullWidth-1)
					if(posX >= oldFullWidth || posY >= oldFullHeight)
						newGridText += "#"
					else
						newGridText += oldGridText.get(posX, posY)
		else // Otherwise, create new data
			for(var/posY = 0 to fullHeight-1)
				for(var/posX = 0 to fullWidth-1)
					newGridText += "#"
		// For map editor sake, add region marker to unrevealed areas
		for(var/posY = 0 to fullHeight-1)
			for(var/posX = 0 to fullWidth-1)
				var /turf/T = locate(
					(mapOffset.x*PLOT_SIZE)+posX+1,
					(mapOffset.y*PLOT_SIZE)+posY+1,
					z()
				)
				_regionMarker.contents.Add(T)
		//
		system.map.gridData[id] = new /stringGrid(fullWidth, fullHeight, newGridText)


//-- Warp Points ---------------------------------------------------------------

	var
		list/warpPlots = list() // Associative: warpId => plot
	proc
		setWarp(warpId, plot/P)
			if(P.warpId)
				warpPlots.Remove(P.warpId)
			warpPlots[warpId] = P
			P.warpId = warpId
		getWarp(warpId)
			return warpPlots[warpId]


//-- Tile & Plot - Retreival, Revealing, Editing -------------------------------

	proc/tileTypeAt(x, y)
		// Change atomic coordinate into grid coordinate
			// Account for region offset
		x = x - (mapOffset.x*PLOT_SIZE +1)
		y = y - (mapOffset.y*PLOT_SIZE +1)
		// Get character at string index
		var /stringGrid/S = system.map.gridData[id]
		var tileChar = S.get(x, y)
		// Convert character into tile type and return
		var tileType = char2Type(tileChar)
		return tileType
	proc/changeTileAt(x, y, tileType) // Change tile type stored at atomic coordinates
		// Get grid coordinates from atomic coordinates
			// Account for region offset
		var gridX = x - (mapOffset.x*PLOT_SIZE +1)
		var gridY = y - (mapOffset.y*PLOT_SIZE +1)
		// Get tile character from tileType
		var tileChar = type2Char(tileType)
		// Edit the new gridText value into place
		var /stringGrid/S = system.map.gridData[id]
		S.put(gridX, gridY, tileChar)
		//
		var borderX
		var borderY
		if(x%PLOT_SIZE == 1 && x > 1) // west border
			borderX = x-1
			borderY = y
		if(x%PLOT_SIZE == 0 && x < (width*PLOT_SIZE)) // east border
			borderX = x+1
			borderY = y
		if(y%PLOT_SIZE == 1 && y > 1) // south border
			borderX = x
			borderY = y-1
		if(y%PLOT_SIZE == 0 && y < (width*PLOT_SIZE)) // south border
			borderX = x
			borderY = y+1
		if(borderX && borderY)
			//S.put(borderX+1, borderY+1, tileChar)
			var/plot/borderPlot = getPlotAt(borderX, borderY)
			if(borderPlot)
				revealTileAt(borderX, borderY)
		// Display Changes on the map
		var/plot/containerPlot = getPlotAt(x, y)
		if(containerPlot)
			revealTileAt(x, y)
	proc/revealTileAt(x, y) // Reveal tile at atomic coordinates (no plot coordinates version)
		var/tileType = tileTypeAt(x, y)
		// Corners remain solid
		//var posX = (x-1)%PLOT_SIZE+1
		//var posY = (y-1)%PLOT_SIZE+1
		/*if(posX+posY == 2 || posX+posY == PLOT_SIZE*2 || (posX+posY == PLOT_SIZE+1 && min(posX,posY) == 1))
			if(!istype(tileType, /tile/water))
				tileType = /tile/wall*/
		//
		var /tile/newTile = createTileAt(x, y, tileType)
		// Autojoin graphics for water tiles
		if(istype(newTile, /tile/water))
			var joinFlags = 0
			if((x-1)%PLOT_SIZE == 0) joinFlags |= WEST
			else if(initial(tileTypeAt(x-1, y):movement) & MOVEMENT_WATER) joinFlags |= WEST
			if((x-1)%PLOT_SIZE == PLOT_SIZE-1) joinFlags |= EAST
			else if(initial(tileTypeAt(x+1, y):movement) & MOVEMENT_WATER) joinFlags |= EAST
			if((y-1)%PLOT_SIZE == 0) joinFlags |= SOUTH
			else if(initial(tileTypeAt(x, y-1):movement) & MOVEMENT_WATER) joinFlags |= SOUTH
			if((y-1)%PLOT_SIZE == PLOT_SIZE-1) joinFlags |= NORTH
			else if(initial(tileTypeAt(x, y+1):movement) & MOVEMENT_WATER) joinFlags |= NORTH
			newTile.icon_state = "water_[joinFlags]"
		//
		return newTile
	proc/unrevealTileAt(x, y) // Reveal tile at atomic coordinates (no plot coordinates version)
		var oldTile = locate(
			x + mapOffset.x*PLOT_SIZE+1, // BYOND's map coordinates start at 1
			y + mapOffset.y*PLOT_SIZE+1,
			z()
		)
		del oldTile
	proc/createTileAt(x, y, tileType) // Creates a tile at atomic coordinates, does not change the underlying map
		var/oldTurf = locate(x, y, z())
		if(!oldTurf)
			diag("Problem([locate(x,y,z())]): [x],[y],[z()]")
		var/tile/posTile = new tileType(oldTurf)
		var/plot/containingPlot = getPlotAt(x, y)
		ASSERT(containingPlot)
		posTile.icon = containingPlot.area.icon
		containingPlot.area.contents += posTile
		return posTile
	proc/clearBorder(x, y, direction)
		var/plot/thePlot = getPlot(x, y)
		if(!thePlot) return FALSE
		switch(direction)
			if( EAST)
				for(var/posY = 1 to PLOT_SIZE)
					var compoundY = (y-1)*PLOT_SIZE + posY
					var compoundX = (x-1)*PLOT_SIZE + PLOT_SIZE
					revealTileAt(compoundX, compoundY)
			if( WEST)
				for(var/posY = 1 to PLOT_SIZE)
					var compoundY = (y-1)*PLOT_SIZE + posY
					var compoundX = (x-1)*PLOT_SIZE + 1
					revealTileAt(compoundX, compoundY)
			if(NORTH)
				for(var/posX = 1 to PLOT_SIZE)
					var compoundY = (y-1)*PLOT_SIZE + PLOT_SIZE
					var compoundX = (x-1)*PLOT_SIZE + posX
					revealTileAt(compoundX, compoundY)
			if(SOUTH)
				for(var/posX = 1 to PLOT_SIZE)
					var compoundY = (y-1)*PLOT_SIZE + 1
					var compoundX = (x-1)*PLOT_SIZE + posX
					revealTileAt(compoundX, compoundY)
		return TRUE
	proc/revealPlot(x, y) // Reveal plot at plot coordinates
		//var compoundIndex = (y-1)*width + x
		if(x < 0 || x >= width || y < 0 || y >= height) return
		var plot/thePlot = plots.get(x, y)
		thePlot.reveal()
		return thePlot
	proc/revealPlotAt(x, y) // Reveal plot containing atomic coordinates
		x = round((x-1)/PLOT_SIZE) - mapOffset.x
		y = round((y-1)/PLOT_SIZE) - mapOffset.y
		return revealPlot(x, y)
	proc/getPlot(x, y) // Plot coordinates
		if(x < 0 || x >= width || y < 0 || y >= height) return null
		//var compoundIndex = (y-1)*width + x
		var plot/thePlot = plots.get(x, y)
		return thePlot
	proc/getPlotAt(x, y) // Plot containing atomic coordinates
		x = round((x-1)/PLOT_SIZE) - mapOffset.x
		y = round((y-1)/PLOT_SIZE) - mapOffset.y
		return getPlot(x,y)


//-- Text / TileType Mapping ---------------------------------------------------

	proc
		char2Type(tileChar)
			var/tileType
			switch(tileChar)
				// Overworld Types
				if("~") tileType = /tile/water/ocean
				if(",") tileType = /tile/water
				if("%") tileType = /tile/feature
				if("&") tileType = /tile/interact
				if("#") tileType = /tile/wall
				if("-") tileType = /tile/bridgeH
				if("|") tileType = /tile/bridgeV
				if("."," ","+","'") tileType = /tile/land
				// Town Interior Types
				/*if("0") tileType = /tile/interior/black
				if("1") tileType = /tile/interior/wallBottom
				if("2") tileType = /tile/interior/wallMiddle
				if("3") tileType = /tile/interior/blackTop
				if("4") tileType = /tile/interior/wallBottomLeft
				if("5") tileType = /tile/interior/wallBottomRight
				if("6") tileType = /tile/interior/blackTopLeft
				if("7") tileType = /tile/interior/blackTopRight
				if("8") tileType = /tile/interior/blackBottomLeft
				if("9") tileType = /tile/interior/blackBottomRight
				if("a") tileType = /tile/interior/windowBottom
				if("b") tileType = /tile/interior/windowMiddle
				if("c") tileType = /tile/interior/warp*/
				//
				else
					tileType = /tile/water/ocean
					diag("Problem: [tileChar]")
			return tileType
		type2Char(tileType)
			var/tileChar
			switch(tileType)
				// Overworld Types
				if(/tile/water/ocean) tileChar = "~"
				if(/tile/water) tileChar = ","
				if(/tile/feature) tileChar = "%"
				if(/tile/interact) tileChar = "&"
				if(/tile/wall) tileChar = "#"
				if(/tile/land) tileChar = "."
				if(/tile/bridgeH) tileChar = "-"
				if(/tile/bridgeV) tileChar = "|"
				// Town Interior Types
				/*if(/tile/interior/black) tileChar = "0"
				if(/tile/interior/wallBottom) tileChar = "1"
				if(/tile/interior/wallMiddle) tileChar = "2"
				if(/tile/interior/blackTop) tileChar = "3"
				if(/tile/interior/wallBottomLeft) tileChar = "4"
				if(/tile/interior/wallBottomRight) tileChar = "5"
				if(/tile/interior/blackTopLeft) tileChar = "6"
				if(/tile/interior/blackTopRight) tileChar = "7"
				if(/tile/interior/blackBottomLeft) tileChar = "8"
				if(/tile/interior/blackBottomRight) tileChar = "9"
				if(/tile/interior/windowBottom) tileChar = "a"
				if(/tile/interior/windowMiddle) tileChar = "b"
				if(/tile/interior/warp) tileChar = "c"*/
				//
				else
					tileChar = "~"
					diag("problem: [tileType]")
			return tileChar