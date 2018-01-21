

//------------------------------------------------------------------------------

terrain/ruins
	id = "ruins"
	icon = 'graveyard.dmi'
	officer = list(
		/enemy/bowser,
		/enemy/ruttle3
	)
terrain/swamp
	id = "swamp"
	icon = 'swamp.dmi'
terrain/dungeon
	id = "dungeon"
	icon = 'interior_castle.dmi'
/*tile/interior
	icon = 'interior.dmi' // Not really, set by region. Just here for visibility in side bar.
	movement = MOVEMENT_WALL
	warp
		movement = MOVEMENT_FLOOR
		/*
		Entered(character/C)
			if(!istype(C)) return ..()
			var/plot/plotArea/PA = aloc(src)
			var/plot/currentPlot = PA.plot
			var/plot/overPlot
			var /game/G = system.getGame(currentPlot.gameId)
			var/region/currentRegion = G.getRegion(currentPlot.regionId)
			/*if(currentRegion == interior)
				overPlot = G.getPlot(currentPlot.x, currentPlot.y)
			else */if(istype(currentRegion))
				ASSERT(currentRegion.entrance)
				overPlot = G.getPlot(currentRegion.entrance.x, currentRegion.entrance.y)
			//var/building/B = overPlot.building
			//var/targetX = B.x + (B.exitCoords? B.exitCoords.x : 0)
			//var/targetY = B.y + (B.exitCoords? B.exitCoords.y : 0)
			//C.transition(overPlot, locate(targetX, targetY, town.z()))
		*/
	black
		icon_state = "black"
	blackTop
		icon_state = "black_south"
	blackTopLeft
		icon_state = "black_southleft"
	blackTopRight
		icon_state = "black_southright"
	blackBottomLeft
		icon_state = "black_left"
	blackBottomRight
		icon_state = "black_right"
	wallBottom
		icon_state = "wall1_bottom"
	wallBottomLeft
		icon_state = "wall1_bottomleft"
	wallBottomRight
		icon_state = "wall1_bottomright"
	wallMiddle
		icon_state = "wall1_middle"
	windowBottom
		icon_state = "window_bottom"
	windowMiddle
		icon_state = "window_middle"

terrain/interior
	id = "interior"
	icon = 'interior.dmi'*/
terrain/forest
	id = "forest"
	icon = 'plains.dmi'
	// Interactive Tile: tall grass
	var
		interactOverlay
		interactMovement = MOVEMENT_FLOOR
		interaction = INTERACTION_CUT | INTERACTION_WIND
	New()
		. = ..()
		interactOverlay = image(icon, icon_state = "tallGrass", layer = MOB_LAYER+1)

	//-- Tile Interaction -------------------
	setupTileInteraction(tile/interact/theTile)
		theTile.overlays = null
		theTile.overlays += interactOverlay
		theTile.movement = interactMovement
		theTile.interaction = interaction
		theTile.rough = 4
	triggerTileInteraction(tile/interact/theTile, atom/interactor, interactionFlags)
		if(interactionFlags & INTERACTION_CUT)
			theTile.overlays = null
			theTile.movement = MOVEMENT_FLOOR
			theTile.interaction = INTERACTION_NONE
			theTile.rough = 1
		/*
		else if(interactionFlags & INTERACTION_WIND)
			interactionFlags &= ~INTERACTION_WIND
			var/terrain/wind/wind = interactor
			var delay = 0
			var magnitude = 6
			var shakeDir = 1
			if(istype(wind))
				delay = wind.windDelay(
					(theTile.x-1)%PLOT_SIZE +1,
					(theTile.y-1)%PLOT_SIZE +1
				)
				if(wind.bearing > 90 && wind.bearing < 270)
					shakeDir = -1
				magnitude = wind.magnitude
				if(rand() < 1/wind.magnitude) return
			spawn(delay + rand(-5,5))
				var M = 0//pick(1/6, 1/4, 2/6)
				var X = rand(1, min(3, magnitude/2)) * shakeDir
				theTile.transform = matrix(1,M,X,  0,1,0)
				spawn(5)
					interactionFlags |= ~INTERACTION_WIND
					theTile.transform = null
		*/

	//-- Enemy Selection --------------------
	infantry = list(
		/enemy/ruttle1,
		/enemy/ruttle2,
		///enemy/goblin,
	)
	cavalry = list(
		/enemy/bird1,
		/enemy/bird2,
	)
	officer = list(
		/enemy/ruttle2,
		/enemy/goblin,
		/enemy/eyeMass,
	)
	/*wind
		parent = /event
		var
			tile/interact/target
			direction
			time
			speed
			matrix/shear
		// Interpolate
		/*matrix(
			1,m,
			0,1,
			0,0,*/
		New(tile/interact/_target, _direction)
			. = ..()
			target = _target
			direction = _direction
			time = _time
			speed = _speed
		takeTurn(delay)
			time -= delay
			if(!target || time < 0) del src
			var/oldDir = target.dir
			step(target, direction, speed)
			target.dir = oldDir
			. = ..()*/