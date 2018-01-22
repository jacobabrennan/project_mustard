

//-- Tile ----------------------------------------------------------------------

tile
	parent_type = /turf
	var
		movement = MOVEMENT_NONE
		rough = 1
		deep = FALSE
	Enter(atom/movable/entrant)
		if(!(entrant.movement & movement))
			return FALSE
		for(var/furniture/F in contents)
			if(!(entrant.movement & F.movement))
				return FALSE
		. = ..()
		. = TRUE

	//-- Basic Types used by all plot terrains -------
	land
		icon_state = "floor"
		movement = MOVEMENT_FLOOR
	wall
		density = 1
		icon_state = "wall"
		movement = MOVEMENT_WALL
		density = TRUE
	feature
		density = 1
		icon_state = "feature"
		movement = MOVEMENT_WALL
		density = TRUE
	water
		density = TRUE
		icon_state = "water_15"
		movement = MOVEMENT_WATER
		deep = TRUE
		density = TRUE
		ocean
	bridgeV
		movement = MOVEMENT_FLOOR | MOVEMENT_WATER
		icon_state = "bridge_ver"
	bridgeH
		movement = MOVEMENT_FLOOR | MOVEMENT_WATER
		icon_state = "bridge_hor"
	interact
		icon_state = "interact"
		movement = MOVEMENT_FLOOR
		var
			interaction = INTERACTION_NONE
		proc
			interact(var/atom/A, interactionFlags)
				var/terrain/ownTerrain = terrain(src)
				ownTerrain.triggerTileInteraction(src, A, interactionFlags)