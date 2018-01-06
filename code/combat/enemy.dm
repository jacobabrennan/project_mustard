

//------------------------------------------------------------------------------

enemy
	parent_type = /combatant
	faction = FACTION_ENEMY
	icon = 'test.dmi'
	icon_state = "clams"
	//gridded = TRUE
	baseHp = 4
	var
		touchDamage = 1
			// Damage done when touching combatants that don't share a faction
		atomic = TRUE
	Cross(var/atom/movable/M)
		touch(M)
		. = ..()
	onCross(var/atom/movable/M)
		touch(M)
		. = ..()
	proc/touch(var/atom/movable/M)
		var/combatant/target = M
		if(istype(target) && !(target.faction&faction))
			attack(target, touchDamage)
		. = ..()
	proc/findTarget()
		var/combatant/_target
		var/targetDist = 1000
		for(var/combatant/C in aloc(src))
			if(C.faction & faction)
				continue
			var/CDist = get_dist(src, C)
			if(CDist < targetDist)
				_target = C
				targetDist = CDist
		return _target
	takeTurn()
		// Interact with things that are overlapping
		for(var/atom/movable/M in obounds())
			touch(M)
		. = ..()
	die()
		if(rand() < ITEM_DROP_RATE)
			var/itemType = pick(
				/item/instant/coin,
				/item/instant/berry,
				/item/instant/berry,
				/item/instant/berry,
				/item/instant/berry,
				/item/instant/plum,
			)
			var/item/instant/I = new itemType()
			I.centerLoc(src)
		. = ..()


	// Archetypes

	normal
		takeTurn()
			// If atomic, change directions sometimes
			if(atomic)
				var/check = FALSE
				switch(dir)
					if(NORTH, SOUTH) if(step_y == 0) check = TRUE
					if(WEST , EAST ) if(step_x == 0) check = TRUE
				if(check && rand() < 1/4)
					dir = pick(NORTH, SOUTH, EAST, WEST)
			// Attempt to move
			var/success = step(src, dir , speed())
			// If movement blocked, change direction
			if(!success || (!atomic && rand() < 1/32))
				dir = pick(NORTH,SOUTH,EAST,WEST)
			. = ..()
	diagonal
		New()
			. = ..()
			dir = pick(NORTH,SOUTH,EAST,WEST)
		takeTurn()
			var/S = speed()
			var/oldDir = dir
			switch(dir)
				if(NORTH)
					if(!step(src, NORTH, S)) oldDir = WEST
					if(!step(src, WEST , S)) oldDir = EAST
				if(WEST )
					if(!step(src, WEST , S)) oldDir = SOUTH
					if(!step(src, SOUTH, S)) oldDir = NORTH
				if(SOUTH)
					if(!step(src, SOUTH, S)) oldDir = EAST
					if(!step(src, EAST , S)) oldDir = WEST
				if(EAST )
					if(!step(src, EAST , S)) oldDir = NORTH
					if(!step(src, NORTH, S)) oldDir = SOUTH
			dir = oldDir
			//step(src, EAST, 1)
			. = ..()