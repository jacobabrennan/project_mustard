

//------------------------------------------------------------------------------

plot
	var
		gameId
		regionId
		x
		y
		warpId // Used to move the player between regions
		terrain
		enemyLevel = 1 // Determines which enemies terrain populates
		// Nonconfigurable:
		revealed = FALSE
		active = FALSE
		plot/plotArea/area
		list/furnitureStorage // Only used in loading regions from json file
	New(_regionId)
		regionId = _regionId
		. = ..()

	//-- Saving & Loading ----------------------------
	toJSON()
		var/list/objectData = ..()
		if(warpId)
			objectData["warpId"] = warpId
		if(terrain)
			objectData["terrain"] = terrain
		if(enemyLevel != 1)
			objectData["enemyLevel"] = enemyLevel
		var/list/furnitureArray = list()
		for(var/furniture/F in area)
			furnitureArray[++furnitureArray.len] = F.toJSON()
		if(furnitureArray.len)
			objectData["furniture"] = furnitureArray
		return objectData
	fromJSON(list/objectData)
		if(objectData["warpId"])
			warpId = objectData["warpId"]
		if(objectData["terrain"])
			terrain = objectData["terrain"]
		furnitureStorage = objectData["furniture"]
		var eLevel = objectData["enemyLevel"]
		if(eLevel != null && eLevel != 1)
			enemyLevel = eLevel

	//-- Revealing & Activation ----------------------
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
		var/terrain/terrainTerrain = terrain(src)
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
		revealed = FALSE
	proc/activate(character/entrant)
		if(active) return
		active = TRUE
		// Make sure this plot is revealed
		if(!revealed) reveal()
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
		var/terrain/ownTerrain = terrain(src)
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
		for(var/actor/A in area)
			del A
	proc/populate(activationDir, level)
		// Determine enemy difficulty
		if(level == null) level = enemyLevel
		if(level <= 0) return
		//
		var /game/G = system.getGame(gameId)
		var/region/parentRegion = G.getRegion(regionId)
		var/minX = 1
		var/minY = 1
		var/maxX = PLOT_SIZE-2
		var/maxY = PLOT_SIZE-2
		switch(activationDir)
			if(NORTH) maxY -= 5
			if(SOUTH) minY += 5
			if( EAST) maxX -= 5
			if( WEST) minX += 5
		// Get enemy models
		var/terrain/terrainModel = terrain(src)
		var/infantryLevel = min(level, terrainModel.infantry.len)
		var/cavalryLevel  = min(level, terrainModel.cavalry.len )
		var/officerLevel  = min(level, terrainModel.officer.len )
		var/combatant/infantryType = infantryLevel? terrainModel.infantry[infantryLevel] : null
		var/combatant/cavalryType  = cavalryLevel?  terrainModel.cavalry[  cavalryLevel] : null
		var/combatant/officerType  = officerLevel?  terrainModel.officer[  officerLevel] : null
		// Attempt to place enemies
		var tries = 15
		for(var/I = 1 to 4)
			if(!infantryType) break
			var/combatant/E = new infantryType()
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
			var/combatant/E = new cavalryType()
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
			var combatant/E = new officerType()
			var success
			for(var/T = 1 to tries)
				var/posX = area.x + rand(minX, maxX)
				var/posY = area.y + rand(minY, maxY)
				var/tile/eLoc = locate(posX, posY, parentRegion.z())
				E.dir = activationDir
				success = E.Move(eLoc)
				if(success) break
			if(!success) del E
	proc/isHostile()
		var /enemy/E = locate() in area
		if(E) return TRUE
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


//-- Plot Area -----------------------------------------------------------------

plot/plotArea
	parent_type = /area
	var
		plot/plot
		plot/plotArea/deactivateTimer/timer
		raining
	Enter(atom/movable/entrant)
		if(istype(entrant) && entrant.transitionable)
			// Check if player is being pushed over edge
			for(var/event/push/pushEvent in aloc(entrant))
				if(pushEvent.target == entrant) return FALSE
			// Otherwise, allow
			return TRUE
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
			var activeEnemies = FALSE
			for(var/combatant/C in contents)
			// If there are players, don't deactivate
				if(C.faction & FACTION_PLAYER)
					return
			// If there are enemies, deactivate
				// Keeps the player from retreating between attacks
				// Also prevents collisions with enemies on reentry
				if(C.faction & FACTION_ENEMY)
					activeEnemies = TRUE
			if(activeEnemies)
				plot.deactivate()
				return
			// Otherwise, the player has cleared the area, let it rest.
			timer = new(plot)
	deactivateTimer
		parent_type = /datum
		New(plot/waitingPlot)
			. = ..()
			spawn(TIME_PLOT_DEACTIVATION)
				waitingPlot.deactivate()
				del src