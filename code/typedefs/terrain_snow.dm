

//------------------------------------------------------------------------------

/* Inspiration:

Krummholz
Ecotone
Alpine

Taiga < Tundra < Ice Sheet / Polar Desert

https://upload.wikimedia.org/wikipedia/commons/3/39/GlarusAlps.jpg

*/


//------------------------------------------------------------------------------


terrain/desert
	//ambientLight = "#00f"
	icon = 'snow.dmi'
	var
		interactOverlay
		interactMovement = MOVEMENT_FLOOR
		interaction = INTERACTION_WALK | INTERACTION_WIND
	setupTileInteraction(tile/interact/theTile)
		theTile.overlays = null
		theTile.overlays += interactOverlay
		theTile.movement = interactMovement
		theTile.interaction = interaction
		theTile.rough = 8
		theTile.deep = TRUE
	triggerTileInteraction(tile/interact/theTile, atom/interactor, interactionFlags)
		//theTile.overlays = null
		//theTile.movement = MOVEMENT_FLOOR
		//theTile.interaction = INTERACTION_NONE
		//theTile.rough = 1
		if(interactionFlags & INTERACTION_WALK)
			if(!(world.time%3))
				new /terrain/desert/print(interactor)
		/*if(interactionFlags & INTERACTION_WIND && rand() < 1/16)
			var/terrain/wind/wind = interactor
			var bearing
			var delay = rand(0,3)
			if(istype(wind))
				bearing = wind.bearing
				delay = wind.windDelay(
					(theTile.x-1)%PLOT_SIZE +1,
					(theTile.y-1)%PLOT_SIZE +1
				) + rand(0,5)
			else
				if(interactor.dir == EAST     ) bearing = 0
				if(interactor.dir == NORTHEAST) bearing = 45
				if(interactor.dir == NORTH    ) bearing = 90
				if(interactor.dir == NORTHWEST) bearing = 135
				if(interactor.dir == WEST     ) bearing = 180
				if(interactor.dir == SOUTHWEST) bearing = 225
				if(interactor.dir == SOUTH    ) bearing = 270
				if(interactor.dir == SOUTHEAST) bearing = 315
			spawn(delay)
				new /terrain/desert/sparkle(bearing, theTile)
		*/
	//
	sparkle
		parent_type = /projectile
		icon = 'snow.dmi'
		icon_state = "empty"
		faction = FACTION_PACIFY
		persistent = TRUE
		//baseSpeed = 16
		step_size = 8
		movement = MOVEMENT_ALL
		maxTime = 7
		var
			bearing
			plot/plotArea/homeArea
		New(owner, tile/snowTile)
			bearing = owner
			owner = null
			. = ..()
			pixel_x = rand(-4,4)
			pixel_y = rand(-4,4)
			forceLoc(snowTile)
			//baseSpeed = wind.baseSpeed
			//project(dir)
			step_size = 8
			vel.y = sin(bearing)*8
			vel.x = cos(bearing)*8
			flick("sparkle", src)
			spawn(10) del src
		forceLoc(newLoc)
			loc = newLoc
			// Problems with infinite loops and Del otherwise
		Move(newLoc)
			. = ..()
			if(!.) del src
			if(!homeArea)
				homeArea = aloc(loc)
			else if(homeArea != aloc(newLoc))
				del src
	print
		parent_type = /obj
		icon = 'snow.dmi'
		icon_state = "print"
		New(var/combatant/walker)
			. = ..()
			centerLoc(walker)
			pixel_x += rand(-2,2)
			pixel_y += rand(-2,2)
			var lifespan = 800
			animate(src, alpha=0, time=lifespan)
			spawn(lifespan)
				del src
	// Enemy Selection
	infantry = list(
		/enemy/ruttle1,
		/enemy/ruttle2,
		/enemy/ruttle3,
	)