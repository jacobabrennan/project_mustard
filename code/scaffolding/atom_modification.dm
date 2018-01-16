

//-- Redefine Atomic System ----------------------------------------------------

//-- Default World Configuration -----------------
client/perspective = EYE_PERSPECTIVE
world
	tick_lag = TICK_DELAY
	map_format = SIDE_MAP
	icon_size = TILE_SIZE
	view = PLOT_SIZE/2
	maxx = PLOT_SIZE
	maxy = PLOT_SIZE
	maxz = MAP_DEPTH

//-- Map Restriction -----------------------------
world/area = /area/border
area/border
	icon = 'test.dmi'
	icon_state = "areaDefault"
	Enter(interface/entrant)
		if(!istype(entrant)) return
		. = ..()

//-- Access Utilities ----------------------------
proc/aloc(atom/contained)
	if(!contained) return null
	var/turf/locTurf = locate(contained.x, contained.y, contained.z)
	if(!locTurf) return null
	return locTurf.loc
proc/plot(atom/contained)
	var/plot/plotArea/PA = aloc(contained)
	if(istype(PA)) return PA.plot
proc/terrain(atom/contained)
	var/plot/P = contained
	if(!istype(P))
		P = plot(contained)
	var terrainId = P.terrain
	if(!terrainId)
		var /game/G = system.getGame(P.gameId)
		var /region/R = G.getRegion(P.regionId)
		terrainId = R.defaultTerrain
	var/terrain/T = terrains[terrainId]
	if(istype(T)) return T
proc/game(atom/contained)
	var gameId
	// Case: No argument
	if(!contained) return
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

//-- Movement & Density --------------------------
mob/density = FALSE
atom/movable/var/transitionable = FALSE // Most movable atoms cannot move between plots
atom/movable/step_size = 1 // Necessary for all objects to use pixel movement
atom/proc/Bumped(var/atom/movable/bumper)
atom/movable/Bump(var/atom/Obstruction)
	Obstruction.Bumped(src)
	. = ..()
atom/movable/var/movement = MOVEMENT_ALL
atom/movable
	Cross()
		return TRUE
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