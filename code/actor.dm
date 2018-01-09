

//-- Actor - Mapables that can takeTurn (have agency) ---------------------

actor
	parent_type = /mob
	var
		turnDelay = 1
			// Delay, in number of TICK_DELAYs, between calls to takeTurn()
			// Can be set to fractional values
		baseSpeed = 1
			// Number of pixels moved every turn.
			// The actual speed of a combatant is speed / turnDelay.
		roughWalk = 0
			// When determining walking speed, this value is subtracted from the tiles' roughness.
	New()
		. = ..()
		spawn(rand())
			takeTurn()
	proc/takeTurn(delay) // Delay is the number of TICKs that passed since last turn
		var _delay = turnDelay * TICK_DELAY
		spawn(_delay)
			takeTurn(turnDelay)

	//-- Faction -------------------------------------
	var
		faction = 0
			// Bit flags that determine how actors interact
	proc
		hostile(var/combatant/C)
			if(!C.dead && !(C.faction&faction))
				return TRUE

	//-- Movement ------------------------------------
	var/gridded = FALSE
		// Moving with go() will guide the actor back into alignment with the 8x8 grid
		//   ^ Not true as of version 0.0.8
	proc
		stepTo(target, minDist)
			// If we're close enough to the target and in the same plot, do nothing.
			if(bounds_dist(src, target) <= minDist)
				if(plot(src) == plot(target)) return TRUE
			// Walk to the target, factoring density
			density = TRUE
			var success = step_to(src, target, 0, speed())
			density = initial(density)
			return success
		speed()
			var tileTotal = 0
			var totalRough = 0
			for(var/tile/T in locs)
				tileTotal++
				totalRough += T.rough
			var averageRough = totalRough/max(1,tileTotal)
			averageRough -= roughWalk
			return baseSpeed / max(1,averageRough)
		/*go(amount, direction)
			if(!amount) amount = speed()
			if(!direction) direction = dir
			/*. = step(src, direction, amount)
			if(gridded)
				var/oldDir = dir
				if(dir & (NORTH|SOUTH))
					var/pxOffset = ((step_x+4)%8)-4
					if(pxOffset < 0) step(src,EAST,1)
					if(pxOffset > 0) step(src,WEST,1)
				if(dir & (EAST|WEST))
					var/pxOffset = ((step_y+4)%8)-4
					if(pxOffset < 0) step(src,NORTH,1)
					if(pxOffset > 0) step(src,SOUTH,1)
				dir = oldDir*/*/
		translate(deltaX, deltaY)
			var success = 0
			if(deltaY > 0) success += step(src, NORTH, deltaY)
			if(deltaY < 0) success += step(src, SOUTH,-deltaY)
			if(deltaX > 0) success += step(src, EAST , deltaX)
			if(deltaX < 0) success += step(src, WEST ,-deltaX)
			/*
			var/fullX = (x*TILE_SIZE)+step_x + deltaX
			var/tileX = round((fullX-1)/TILE_SIZE)
			var/offsetX = 1+ (fullX-1)%TILE_SIZE
			var/fullY = (y*TILE_SIZE)+step_y + deltaY
			var/tileY = round((fullY-1)/TILE_SIZE)
			var/offsetY = 1+ (fullY-1)%TILE_SIZE
			var success = Move(locate(tileX, tileY, z), 0, offsetX, offsetY)
			if(!success)
				if(
				success += step(src,
				success += Move(locate(tileX, y, z), 0 , offsetX, step_y)
			if(
			if(dir & (EAST|WEST)) dir &= (EAST|WEST)*/
			return success

