

//------------------------------------------------------------------------------

terrain/desert
	id = "desert"
	name = "Desert"
	//icon = 'desert.dmi'
terrain/ruins
	id = "ruins"
	icon = 'graveyard.dmi'
terrain/swamp
	id = "swamp"
	icon = 'swamp.dmi'
terrain/dungeon
	id = "dungeon"
	icon = 'interior_castle.dmi'
tile/interior
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
	icon = 'interior.dmi'
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
		takeTurn()
			if(!target || time-- <= 0) del src
			var/oldDir = target.dir
			step(target, direction, speed)
			target.dir = oldDir
			. = ..()*/
	// Enemy Selection
	infantry = list(
		/terrain/forest/enemy/goblin,
		/terrain/forest/enemy/ruttle2,
		/terrain/forest/enemy/ruttle3,
	)
	cavalry = list(
		/terrain/forest/enemy/bird1,
	)
	officer = list(
		/terrain/forest/enemy/goblin,
		/terrain/forest/enemy/ruttle3
	)
	//
	enemy
		parent_type = /enemy
		goblin
			parent_type = /character
			icon = 'goblin.dmi'
			baseSpeed = 1
			roughWalk = 4
			baseHp = 6
			behaviorName = "archer2"
			faction = FACTION_ENEMY
			disposable = TRUE
			New()
				equip(new /item/weapon/bow())
				. = ..()
			var
				shootDelay = 32
			takeTurn()
				shootDelay--
				. = ..()
			shoot(projType)
				if(!projType && shootDelay > 0) return
					// Shoot() is called twice per this enemy's shot,
					// once with an argument, once without.
					// Checking shoot delay for both breaks it.
				shootDelay = initial(shootDelay)
				. = ..()
		ruttle1
			parent_type = /enemy/normal
			icon = 'enemies.dmi'
			icon_state = "bug_1"
			baseHp = 1
			baseSpeed = 1
		ruttle2
			parent_type = /terrain/forest/enemy/ruttle1
			icon = 'enemies.dmi'
			icon_state = "bug_2"
			behaviorName = "archer2"
			baseHp = 4
			var
				arrowSpeed = 4
			projectileType = /projectile/bowArrow
			shoot()
				var /projectile/P = ..()
				P.baseSpeed = arrowSpeed
				P.project()
				return P
		ruttle3
			parent_type = /terrain/forest/enemy/ruttle1
			icon = 'enemies.dmi'
			icon_state = "bug_3"
			baseHp = 16
		bird1
			parent_type = /enemy/diagonal
			icon = 'enemies.dmi'
			icon_state = "bird_1"
			movement = MOVEMENT_ALL
			layer = MOB_LAYER+2
			roughWalk = 200
			baseHp = 1
			baseSpeed = 2
		bird2
			parent_type = /enemy/diagonal
			icon = 'enemies.dmi'
			icon_state = "bird_1"
			movement = MOVEMENT_ALL
			layer = MOB_LAYER+2
			roughWalk = 200
			baseHp = 1
			baseSpeed = 2
		bird3
			parent_type = /enemy/diagonal
			icon = 'enemies.dmi'
			icon_state = "bird_1"
			movement = MOVEMENT_ALL
			layer = MOB_LAYER+2
			roughWalk = 200
			baseHp = 1
			baseSpeed = 2