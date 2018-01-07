

//------------------------------------------------------------------------------

plot
	var
		gameId
		regionId
		x
		y
		warpId // Used to move the player between regions
		revealed = FALSE
		plot/plotArea/area
		terrain
		active = FALSE
//		building/building
		list/furnitureStorage // Only used in loading regions from json file
	New(_regionId)
		regionId = _regionId
		. = ..()
	toJSON()
		var/list/objectData = ..()
		objectData["regionId"] = regionId
		objectData["x"] = x
		objectData["y"] = y
		objectData["warpId"] = warpId
		objectData["terrain"] = terrain
//		if(building) objectData["building"] = building.toJSON()
		var/list/furnitureArray = list()
		for(var/furniture/F in area)
			furnitureArray[++furnitureArray.len] = F.toJSON()
		if(furnitureArray.len)
			objectData["furniture"] = furnitureArray
		return objectData
	fromJSON(list/objectData)
		regionId = objectData["regionId"]
		x = objectData["x"]
		y = objectData["y"]
		warpId = objectData["warpId"]
		terrain = objectData["terrain"]
//		if(objectData["building"])
//			building = json2Object(objectData["building"])
		furnitureStorage = objectData["furniture"]
	proc/reveal()
		if(revealed) return
		var/game/G = system.getGame(gameId)
		var/region/parentRegion = G.getRegion(regionId)
		ASSERT(regionId)
		revealed = TRUE
		// Build Area
		area = new()
		area.plot = src
		/*var compoundIndex = (y-1)*DERP + x
		var plasmaGenerator/closedNode/plotModel = town.plotPlan[compoundIndex]
		terrain = plotModel.terrain*/
		var/terrain/terrainTerrain = terrains[terrain]
		var terrainIcon = initial(terrainTerrain:icon)
		area.icon = terrainIcon
		// Add Tiles
		for(var/posY = 1 to PLOT_SIZE)
			for(var/posX = 1 to PLOT_SIZE)
				var compoundY = (y)*PLOT_SIZE + posY
				var compoundX = (x)*PLOT_SIZE + posX
				// Account for region offset on map
				compoundY += parentRegion.mapOffset.y*PLOT_SIZE
				compoundX += parentRegion.mapOffset.x*PLOT_SIZE
				parentRegion.revealTileAt(compoundX, compoundY)
//		if(building)
//			building.place(building.x, building.y, src)
		for(var/list/furnitureObject in furnitureStorage)
			var/furniture/F = json2Object(furnitureObject)
			var/_x = furnitureObject["x"]+area.x
			var/_y = furnitureObject["y"]+area.y
			F.forceLoc(locate(_x, _y, area.z))
	proc/unreveal()
		if(!revealed) return
		deactivate()
		var/game/G = system.getGame(gameId)
		var/region/parentRegion = G.getRegion(regionId)
		ASSERT(regionId)
		// Remove Furniture
		for(var/furniture/F in area.contents)
			if(!furnitureStorage)
				furnitureStorage = list()
			var /list/furnitureObject = F.toJSON()
			furnitureStorage.Add(furnitureObject)
			del F
		// Remove Tiles
		for(var/posY = 0 to PLOT_SIZE-1)
			for(var/posX = 0 to PLOT_SIZE-1)
				var compoundY = (y)*PLOT_SIZE + posY
				var compoundX = (x)*PLOT_SIZE + posX
				parentRegion.unrevealTileAt(compoundX, compoundY)
		// Remove Area
		area.icon = null
		del area
//		if(building)
//			building.place(building.x, building.y, src)
		revealed = FALSE
	proc/buildAllow(interface/player, town/terrainModel/tileModel, buildX, buildY)
		return TRUE
	proc/activate(character/entrant)
		if(active) return
		active = TRUE
		// Reveal other Plots Nearby
		var /game/G = system.getGame(gameId)
		var /region/ownRegion = G.getRegion(regionId)
		ownRegion.revealPlot(x+1, y)
		ownRegion.revealPlot(x-1, y)
		ownRegion.revealPlot(x, y+1)
		ownRegion.revealPlot(x, y-1)
		// Determine activation direction
		var/dirs = 15
		if(entrant)
			var/posX = (entrant.x-1)%PLOT_SIZE+1
			var/posY = (entrant.y-1)%PLOT_SIZE+1
			if(posX+posY <= PLOT_SIZE) dirs &= ~NORTHEAST
			else dirs &= ~SOUTHWEST
			if((11-posX)-(11-posY) <= 0) dirs &= ~NORTHWEST
			else dirs &= ~SOUTHEAST
		populate(dirs)
		// Activate interactable tiles
		var/terrain/ownTerrain = terrains[terrain]
		for(var/tile/interact/I in area)
			ownTerrain.setupTileInteraction(I)
		// Activate furniture
		for(var/furniture/F in area)
			F.activate()
		// Update weather conditions
		//ownTerrain.updateWeather(src)
		// Add to region's active plots list
		ownRegion.activePlots.Add(src)
		// Start activity cycle
		takeTurn()
	proc/deactivate()
		// Remove from region's active plots list
		var /game/G = system.getGame(gameId)
		var /region/ownRegion = G.getRegion(regionId)
		ownRegion.activePlots.Remove(src)
		active = FALSE
		/*for(var/enemy/E in area)
			del E
		for(var/character/char in area)
			if(!(char.faction&FACTION_PLAYER))
				del char*/
		for(var/actor/A in area)
			del A
	proc/populate(activationDir)
		var /game/G = system.getGame(gameId)
		var/region/parentRegion = G.getRegion(regionId)
		var/minX = 0
		var/minY = 0
		var/maxX = PLOT_SIZE-1
		var/maxY = PLOT_SIZE-1
		switch(activationDir)
			if(NORTH) maxY -= 5
			if(SOUTH) minY += 5
			if( EAST) maxX -= 5
			if( WEST) minX += 5
		var/terrain/terrainModel = terrains[terrain]
		var/infantryLevel = min(1, terrainModel.infantry.len)
		var/cavalryLevel  = min(1, terrainModel.cavalry.len )
		var/officerLevel  = min(1, terrainModel.officer.len )
		var/enemy/infantryType = infantryLevel? terrainModel.infantry[infantryLevel] : null
		var/enemy/cavalryType  = cavalryLevel? terrainModel.cavalry[  cavalryLevel] : null
		var/enemy/officerType  = officerLevel? terrainModel.officer[  officerLevel] : null
		var/tries = 15
		for(var/I = 1 to 4)
			if(!infantryType) break
			var/enemy/E = new infantryType()
			var success
			for(var/T = 1 to tries)
				var/posX = area.x + rand(minX, maxX)
				var/posY = area.y + rand(minY, maxY)
				var/tile/eLoc = locate(posX, posY, parentRegion.z())
				E.dir = activationDir
				success = E.Move(eLoc)
				if(success) break
			if(!success) del E
		for(var/I = 1 to 2)
			if(!cavalryType) break
			var/enemy/E = new cavalryType()
			var success
			for(var/T = 1 to tries)
				var/posX = area.x + rand(minX, maxX)
				var/posY = area.y + rand(minY, maxY)
				var/tile/eLoc = locate(posX, posY, parentRegion.z())
				E.dir = activationDir
				success = E.Move(eLoc)
				if(success) break
			if(!success) del E
		for(var/I = 1 to 1)
			if(!officerType) break
			var enemy/E = new officerType()
			var success
			for(var/T = 1 to tries)
				var/posX = area.x + rand(minX, maxX)
				var/posY = area.y + rand(minY, maxY)
				var/tile/eLoc = locate(posX, posY, parentRegion.z())
				E.dir = activationDir
				success = E.Move(eLoc)
				if(success) break
			if(!success) del E
	proc/takeTurn()
		// If deactivate, stop cycle
		if(!active) return
		// Do weather
		//var/terrain/terrainModel = terrains[terrain]
		//var delay = terrainModel.plotWeather(src)
		var delay = 0
		// Iterate after delay
		spawn(TURN_SPEED_PLOT+delay)
			takeTurn()


//------------------------------------------------------------------------------

plot/plotArea
	parent_type = /area
	var
		terrain = "grass"
		plot/plot
		plot/plotArea/deactivateTimer/timer
		raining
	Enter(atom/movable/entrant)
		if(istype(entrant) && entrant.transitionable)
			return TRUE
		/*else if(istype(entryChar, /interface/town))
			return TRUE*/
		if(!entrant.loc) return ..()
		return FALSE
	Entered(atom/entrant)
		. = ..()
		var character/entryChar = entrant
		if(istype(entryChar))
			if(timer) del timer
			var transDir
			if(entryChar.y < y            ) transDir = NORTH
			if(entryChar.y > y+PLOT_SIZE-1) transDir = SOUTH
			if(entryChar.x < x            ) transDir = EAST
			if(entryChar.x > x+PLOT_SIZE-1) transDir = WEST
			var turf/entryTurf = get_step(entryChar, transDir)
			entryChar.transition(plot, entryTurf)
	Exited(character/leaver)
		. = ..()
		if(istype(leaver) && (leaver.faction&FACTION_PLAYER))
			for(var/character/remaining in contents)
				if(remaining.faction & FACTION_PLAYER) return
			timer = new(plot)
	deactivateTimer
		parent_type = /datum
		New(plot/waitingPlot)
			. = ..()
			spawn(TIME_PLOT_DEACTIVATION)
				waitingPlot.deactivate()
				del src