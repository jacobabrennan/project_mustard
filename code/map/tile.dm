

//------------------------------------------------------------------------------

//character
//	density = TRUE


//------------------------------------------------------------------------------

tile
	parent_type = /turf
	// Buiding
	var
		buildPoints = 1
		movement = MOVEMENT_NONE
		rough = 1
		deep = FALSE
	proc/buildAllow(interface/player, town/terrainModel/tileModel)
		return TRUE
	Enter(atom/movable/entrant)
		if(!(entrant.movement & movement))
			return FALSE
		for(var/furniture/F in contents)
			if(!(entrant.movement & F.movement))
				return FALSE
		. = ..()
		. = TRUE
	// Basic Types used by all plot terrains
	water
		density = TRUE
		icon_state = "water_0"
		movement = MOVEMENT_WATER
		deep = TRUE
		density = TRUE
		ocean
			buildAllow(interface/player, town/terrainModel/tileModel)
				return FALSE
	land
		icon_state = "floor"
		movement = MOVEMENT_FLOOR
	feature
		density = 1
		icon_state = "feature"
		movement = MOVEMENT_WALL
		density = TRUE
	interact
		//density = 1
		icon_state = "interact"
		movement = MOVEMENT_FLOOR
		var
			interaction = INTERACTION_NONE
		proc
			interact(var/atom/A, interactionFlags)
				var/terrain/ownTerrain = terrain(src)
				ownTerrain.triggerTileInteraction(src, A, interactionFlags)
	wall
		density = 1
		icon_state = "wall"
		movement = MOVEMENT_WALL
		density = TRUE