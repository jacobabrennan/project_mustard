

//-- Enemy ---------------------------------------------------------------------

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
		if(istype(target) && hostile(target))
			attack(target, touchDamage)
		. = ..()
	proc/findTarget(maxDistance)
		var/combatant/_target
		if(!maxDistance) maxDistance = 1000
		for(var/combatant/C in aloc(src))
			if(!hostile(C))
				continue
			var/CDist = bounds_dist(src, C)
			if(CDist < maxDistance)
				_target = C
				maxDistance = CDist
		return _target
	takeTurn(delay)
		// Interact with things that are overlapping
		for(var/atom/movable/M in obounds())
			touch(M)
		. = ..()
	die()
		if(rand() < ITEM_DROP_RATE)
			var/itemType = pick(
				///item/instant/coin,
				/item/instant/berry,
				/item/instant/berry,
				/item/instant/berry,
				/item/instant/berry,
				/item/instant/plum,
				/item/instant/magicBottle,
			)
			var/item/instant/I = new itemType()
			I.centerLoc(src)
		. = ..()


//-- Archetypes ----------------------------------------------------------------

	//------------------------------------------------
	normal
	/*- Normal Enemies -------------------------------
		Optional Grid Aligned Movement
		Optional frequent Shooting
		*/
		var
			shootFrequency = 128 // Shootes every turn that rand() <= 1/shootFrequency
		behavior()
			// If atomic, change directions sometimes
			if(atomic)
				var/check = FALSE
				switch(dir)
					if(NORTH, SOUTH) if(step_y == 0) check = TRUE
					if(WEST , EAST ) if(step_x == 0) check = TRUE
				if(check && rand() < 1/4)
					dir = pick(NORTH, SOUTH, EAST, WEST)
			// Shoot Sometimes
			if(projectileType && rand() <= 1/shootFrequency)
				shoot()
			// Attempt to move
			var/success = step(src, dir , speed())
			// If movement blocked, change direction
			if(!success || (!atomic && rand() < 1/32))
				dir = pick(NORTH,SOUTH,EAST,WEST)
			. = ..()

	//------------------------------------------------
	diagonal
	/*- Diagonal Enemies -----------------------------
		By default Flying Enemies
		Optional frequent Reflection
		Optional frequent Direction Changes
		*/
		roughWalk = 200
		movement = MOVEMENT_ALL
		var
			reflectFrequency = 0 // 1/chance to reflect when bumping
			changeFrequency = 0 // 1/chance to change direction randomly
		New()
			. = ..()
			spawn()
				dir = pick(NORTH,SOUTH,EAST,WEST)
		behavior()
			var/S = speed()
			if(changeFrequency && rand() < 1/changeFrequency)
				dir = pick(NORTH, SOUTH, EAST, WEST)
			var/oldDir = dir
			var reflect
			if(reflectFrequency && rand() < 1/reflectFrequency) reflect = TRUE
			switch(dir)
				if(NORTH)
					if(!step(src, NORTH, S)) oldDir = reflect? SOUTH : WEST
					if(!step(src, WEST , S)) oldDir = reflect? SOUTH : EAST
				if(WEST )
					if(!step(src, WEST , S)) oldDir = reflect? EAST : SOUTH
					if(!step(src, SOUTH, S)) oldDir = reflect? EAST : NORTH
				if(SOUTH)
					if(!step(src, SOUTH, S)) oldDir = reflect? NORTH : EAST
					if(!step(src, EAST , S)) oldDir = reflect? NORTH : WEST
				if(EAST )
					if(!step(src, EAST , S)) oldDir = reflect? WEST : NORTH
					if(!step(src, NORTH, S)) oldDir = reflect? WEST : SOUTH
			dir = oldDir
			//step(src, EAST, 1)
			. = ..()

	//------------------------------------------------
	ranged
	/*- Cowardly Archers & Mages ---------------------
		CPU Intensive, use sparingly
		Aligns with partyMembers and shoots
		Configurable target range, proj speed, shoot freq, and # of shots
		*/
		var
			shootFrequency = 32 // How often the enemy shoots, but see below
			shootUnique = TRUE // Will only shoot one projectile at a time
			shootRange = 240 // How close a combatant has to be to get targeted
				// NOT the max range of the projectile itself
			shootSpeed = 4 // How fast a projectile moves
			fearRange = 32 // How close an enemy has to be to trigger retreat behavior
			// Nonconfigurable:
			combatant/target
		Move(newLoc, newDir, stepX, stepY)
			. = ..()
			if(.) return
			// If we couldn't move diagonally, then try moving x & y individually
			if(!(stepX && stepY)) return
			if(Move(newLoc, newDir, stepX, 0)) return TRUE
			if(Move(newLoc, newDir, 0, stepY)) return TRUE
		behavior()
			if(..()) return TRUE
			if(tryToShoot()) return TRUE
			if(amIAfraid()) return TRUE
			// Otherwise, If we have a target then align with it
			if(target)
				var /plot/plotArea/A = aloc(src)
				var deltaX = ((target.x-A.x)*TILE_SIZE + target.bound_width /2 + target.step_x) - ((x-A.x)*TILE_SIZE + bound_width /2 + step_x)
				var deltaY = ((target.y-A.y)*TILE_SIZE + target.bound_height/2 + target.step_y) - ((y-A.y)*TILE_SIZE + bound_height/2 + step_y)
				var axisHorizontal = (abs(deltaX) <= abs(deltaY))? TRUE : FALSE
				if(axisHorizontal)
					if(deltaX > 0) translate( speed(), 0)
					else           translate(-speed(), 0)
				else
					if(deltaY > 0) translate( 0, speed())
					else           translate( 0,-speed())
				return TRUE
		proc/amIAfraid()
			var closeTarget
			var closeDist = 9999
			for(var/combatant/A in obounds(src, fearRange))
				if(!A.hostile(src)) continue
				var testDist = bounds_dist(src, A)
				if(testDist < closeDist)
					closeTarget = A
					closeDist = testDist
			if(closeTarget)
				target = null
				return step_away(src, closeTarget)
			return FALSE
		proc/tryToShoot()
			// If we already have a projectile fired, return
			if((shootUnique && projectiles.len) || (rand() > 1/shootFrequency)) return
			// If there's a target, check if it's still aligned to attack
			var /plot/plotArea/A = aloc(src)
			var alignMax = 96
			if(target)
				var deltaX = ((target.x-A.x)*TILE_SIZE + target.bound_width /2 + target.step_x) - ((x-A.x)*TILE_SIZE + bound_width /2 + step_x)
				var deltaY = ((target.y-A.y)*TILE_SIZE + target.bound_height/2 + target.step_y) - ((y-A.y)*TILE_SIZE + bound_height/2 + step_y)
				if(target.dead || min(abs(deltaX), abs(deltaY)) > alignMax)
					target = null
			// Check for targets of opportunity. Shoot the one that can be hit the fastest
			var fastestDir
			var /combatant/fastestHit
			var /combatant/fastestTime = 1000
			var /list/deltasX = new()
			var /list/deltasY = new()
			for(var/combatant/E in A)
				if(!hostile(E)) continue
				var deltaX = ((E.x-A.x)*TILE_SIZE + E.bound_width /2 + E.step_x) - ((x-A.x)*TILE_SIZE + bound_width /2 + step_x)
				var deltaY = ((E.y-A.y)*TILE_SIZE + E.bound_height/2 + E.step_y) - ((y-A.y)*TILE_SIZE + bound_height/2 + step_y)
				deltasX[E] = deltaX
				deltasY[E] = deltaY
				var directX
				var directY
				var closingX
				var closingY
				if(abs(deltaY) < TILE_SIZE/2) directX = TRUE
				if(abs(deltaX) < TILE_SIZE/2) directY = TRUE
				if     (deltaX > 0 && (E.dir&WEST )) closingX = TRUE
				else if(deltaX < 0 && (E.dir&EAST )) closingX = TRUE
				if     (deltaY > 0 && (E.dir&SOUTH)) closingY = TRUE
				else if(deltaY < 0 && (E.dir&NORTH)) closingY = TRUE
				if(!(closingX || closingY || directX || directY)) continue // Target is not crossing over cardinal direction
				var testTime = fastestTime+1
				var testDir
				if(closingX || directY) // Attack Vertically
					if(abs(deltaY) > shootRange) continue
					var deltaT = abs(deltaX / E.speed())
					var arrowT = abs(deltaY / shootSpeed)
					if(directY || abs(deltaT - arrowT) <= 4)
						testTime = deltaT
						testDir = (deltaY > 0)? NORTH : SOUTH
				if(closingY || directX) // Attack Horizontally
					if(abs(deltaX) > shootRange) continue
					var deltaT = abs(deltaY / E.speed())
					var arrowT = abs(deltaX / shootSpeed)
					if((deltaT < testTime) && (directX || abs(deltaT - arrowT) <= 5))
						testTime = deltaT
						testDir = (deltaX > 0)? EAST  : WEST
				if(testTime < fastestTime)
					fastestTime = testTime
					fastestHit = E
					fastestDir = testDir
			if(fastestHit)
				dir = fastestDir
				shoot()
				target = null
				return TRUE
			// If we can't shoot anything (and there's no target), try to target the combatant that requires the least movement to align with
			if(!target)
				var closestAlignTarget
				var closestAlignDist = alignMax
				for(var/combatant/E in A)
					if(!hostile(E)) continue
					var deltaX = abs(deltasX[E])
					var deltaY = abs(deltasY[E])
					var minDelta = min(deltaX, deltaY)
					if(minDelta < closestAlignDist)
						closestAlignTarget = E
						closestAlignDist = minDelta
				if(closestAlignTarget)
					target = closestAlignTarget

	//------------------------------------------------
	fixated
	/*- Homing Missiles and Determinators ------------
		Walks directly to the closest target player
		How often they scan for closer enemies is configurable
		Based on Normal archetype
		*/
		parent_type = /enemy/normal
		var
			changeTargetFrequency = 32 // How often the enemy will select a closer target
			// Nonconfigurable:
			combatant/target
		findTarget()
			if(target && (rand()*changeTargetFrequency > 1)) return target
			. = ..()
		behavior()
			target = findTarget()
			if(target)
				stepTo(target)

	//------------------------------------------------
	pulsar
	/*- Takes action on a regular schedule -----------
		Time between pulses is configurable
		Can be stationary
		Can follow a target
		Based on Normal archetype
		*/
		parent_type = /enemy/normal
		var
			pulseTime = 80 // How often the enemy shoots takes action
			stationary = TRUE
			// Nonconfigurable:
			combatant/target
		//
		shootFrequency = 9999*9999
		behavior()
			if(--pulseTime <= 0)
				pulse()
				pulseTime = initial(pulseTime)
				return
			if(stationary) return
			. = ..()
		proc/pulse()
			shoot()

	//------------------------------------------------
	snaking
	/*- Compound enemy, long body follows head -------
		MaxHp based on body length
		Based on Normal archetype
		*/
		parent_type = /enemy/normal
		atomic = TRUE
		var
			length = 4
			bodyRadius = 8
			bodyHealth = 1
			bodyState
			tailState
			bodyInvulnerable = FALSE
			// Nonconfigurable:
			list/body = new()
			list/oldPositions
		baseSpeed = 1
		maxHp()
			return bodyHealth*body.len
		New()
			. = ..()
			layer++
			oldPositions = new()
			var /enemy/lead = src
			for(var/I = 1 to length)
				var /enemy/snaking/body/B = new()
				B.centerLoc(src)
				body.Add(B)
				if(lead != src)
					var /enemy/snaking/body/leader = lead
					leader.follower = B
				B.lead = lead
				lead = B
				B.head = src
				B.faction = faction
				B.icon = icon
				if(I == length && tailState)
					B.icon_state = tailState
				else
					B.icon_state = bodyState
				B.bound_height = bodyRadius
				B.bound_width = bodyRadius
			adjustHp(maxHp())
		behavior()
			var/atomicCoord/oldC = new(src)
			oldC.stepX += (bound_width/2  - bodyRadius)
			oldC.stepY += (bound_height/2 - bodyRadius)
			oldPositions.Insert(1, oldC)
			oldPositions[oldC] = dir
			. = ..()
			var speed = baseSpeed
			for(var/I = 1 to body.len)
				var/oldIndex
				//if(moveToggle == -1)
				//	oldIndex = round(I * bodyRadius/speed)
				//else
				oldIndex = round(I * bodyRadius*2/speed)
				if(oldIndex <= oldPositions.len)
					var /enemy/snaking/body/B = body[I]
					if(!B) continue
					var /atomicCoord/newC = oldPositions[oldIndex]
					B.dir = oldPositions[newC]
					newC.place(B)
			//if(moveToggle == -1)
			//	oldPositions.len = min(oldPositions.len, round(body.len*bodyRadius/speed))
			//else
			oldPositions.len = min(oldPositions.len, round(body.len*bodyRadius*2/speed))
		hurt(amount, attacker, proxy)
			. = ..()
			if(body.len)
				for(var/I = body.len to 1 step -1)
					if(I > body.len){ continue}
					var /enemy/E = body[I]
					if(!E) continue
					E.invincible = invincible
					if(hp < bodyHealth * I)
						E.die()
						if(tailState && body.len)
							var /enemy/EE = body[body.len]
							EE.icon_state = tailState
		die()
			for(var/enemy/E in body)
				E.die()
			. = ..()
		Del()
			for(var/enemy/E in body)
				del E
			. = ..()
		body
			parent_type = /enemy
			movement = MOVEMENT_ALL
			var
				enemy/snaking/head
				enemy/lead
				enemy/follower
			hurt(amount, attacker, proxy)
				if(head.bodyInvulnerable)
					//game.audio.play_sound("defend")
				else
					head.hurt(amount)
			die()
				head.body.Remove(src)
				. ..()

	//------------------------------------------------
	ball
	/*- Compound enemy, long body follows head -------
		MaxHp based on body length
		Based on Normal archetype
		*/
		parent_type = /enemy/normal
		bound_width = 24
		bound_height = 24
		var
			groupSize = 2
			childType = /enemy/ball/groupMember
			respawnTime = 64
			rotationRate = 0
			// Nonconfigurable:
			groupRotation = 0
			list/orbits = list(list(), list())
			spawned = FALSE
		New()
			. = ..()
			layer++
		behavior()
			. = ..()
			var /list/orbit1 = orbits[1]
			var /list/orbit2 = orbits[2]
			// Rotate a little
			groupRotation += rotationRate
			// Have we spawned our original group yet?
			if(!spawned)
				spawned = TRUE
				for(var/I = 1 to groupSize)
					var /enemy/ball/groupMember/M = new childType()
					M.centerLoc(src)
					M.leader = src
					group.Add(M)
					// Populate Inner Orbit
					if(I <= 6)
						orbits[1].Add(M)
						M.orbit = 1
					// Populate Outer Orbit
					else
						orbits[2].Add(M)
						M.orbit = 2
			// Do we need to spawn new group members?
			if(group.len < groupSize)
				if(rand()*respawnTime > respawnTime-1)
					var /enemy/ball/groupMember/M = new childType()
					M.centerLoc(src)
					M.leader = src
					group.Add(M)
					if(group.len < 6)
						M.orbit = 1
						orbit1.Add(M)
					else
						M.orbit = 2
						orbit2.Add(M)
			// Should we send group members out into the world?
			else if(rand()*respawnTime*3 > (respawnTime*3)-1)
				var /enemy/ball/groupMember/M = pick(group)
				group.Remove(M)
				M.leader = null
				for(var/list/orbit in orbits)
					orbit.Remove(M)
			// Move members of orbit2 to fill positions in orbit1
			while(orbit1.len < 6 && orbit2.len)
				var /enemy/ball/groupMember/M = pick(orbit2)
				orbit2.Remove(M)
				if(!istype(M)) continue
				orbit1.Add(M)
				M.orbit = 1
		die()
			for(var/enemy/ball/groupMember/E in group)
				group.Remove(E)
				E.leader = null
			. = ..()
		Del()
			for(var/datum/D in group)
				del D
			. = ..()
		//
		groupMember
			parent_type = /enemy/normal
			var
				enemy/ball/leader
				orbit
			baseSpeed = 1
			behavior()
				// If we're detached, go roam the world!
				if(!leader) return ..()
				// Determine ideal position
				var rotationAngle = leader.groupRotation
				if(orbit == 1) rotationAngle += (60)*leader.orbits[1].Find(src) + 30
				else rotationAngle += 360/(leader.groupSize-6) * leader.orbits[2].Find(src)
				var distance = (leader.bound_width+(orbit-1)*bound_width)/2
				var targetX = (leader.x*TILE_SIZE)+leader.step_x+leader.bound_width /2
				var targetY = (leader.y*TILE_SIZE)+leader.step_y+leader.bound_height/2
				targetX += cos(rotationAngle)*distance
				targetY += sin(rotationAngle)*distance
				// Determine Deltas
				targetX -= (x*TILE_SIZE + step_x + bound_width /2)+rand(-1,1)
				targetY -= (y*TILE_SIZE + step_y + bound_width /2)+rand(-1,1)
				var speed = leader.speed()*2
				targetX = max(-speed, min(speed, targetX))
				targetY = max(-speed, min(speed, targetY))
				// Move
				var oldDir = dir
				translate(targetX, targetY)
				if(rand()*64 > 1)
					dir = oldDir
				return
			die()
				if(leader)
					leader.group.Remove(src)
					for(var/list/orbit in leader.orbits)
						orbit.Remove(src)
				. = ..()