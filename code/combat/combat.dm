

//------------------------------------------------------------------------------

combatant
	parent_type = /actor
	density = FALSE
		// Mobs can move other each other to attack, and tile entry is determined by Movement flags
	movement = MOVEMENT_FLOOR
	step_size = 1
		// Must be set in order to turn on pixel movement, even if using step() manually
	var
		disposable = TRUE
			// If the combatant disappears after death
	New()
		. = ..()
		hp = maxHp()
		mp = maxMp()

	/*// Submersion
	appearance_flags = KEEP_TOGETHER
	var
		combatant/submersion/submerged
	translate(deltaX, deltaY)
		. = ..()
		var deep = TRUE
		for(var/tile/T in locs)
			if(!T.deep)
				//deep = FALSE
				break
		if(deep && !submerged)
			submerged = new()
			overlays.Add(submerged)
			diag("submersing")
		else if(!deep && submerged)
			diag("emerging")
			overlays.Remove(submerged)
			del submerged
	submersion
		parent_type = /obj
		layer = MOB_LAYER
		plane = 2
		blend_mode = BLEND_MULTIPLY
		/*color = list(
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 0.5,
			0, 0, 0, 0,
		)*/
		icon = 'specials.dmi'
		icon_state = "submersion"*/

	//-- Behavior ---------------------------------//
	var
		list/controllers[0]
		behaviorName
		behaviors/behaviorObject
	New()
		if(istext(behaviorName))
			behaviorObject = new()
			if(!hascall(behaviorObject, behaviorName)) del behaviorObject
		. = ..()
	takeTurn()
		if(invincible) invincible--
		. = ..()
		if(.) return // blocked
		. = control()
		if(.) return .
		if(hascall(behaviorObject, behaviorName))
			. = call(behaviorObject, behaviorName)(src)
			if(.) return
		. = behavior()
	proc
		behavior()
	proc/control()
		for(var/cIndex = controllers.len to 1 step -1)
			var/controller = controllers[cIndex]
			var/block = FALSE
			if(hascall(controller, "control"))
				block = controller:control(src)
			else if(controller) block = TRUE
			if(block) return block

	//-- Controller & Sequence --------------------//
	proc/addController(sequence/controller)
		// Insert low priority controllers at the start of the list
		if(istype(controller) && !controller.priority)
			controllers.Insert(1, controller)
			return
		// High priority controllers go on the top of "the stack"
		if(controllers.len)
			// Controllers interrupt the current top stack controller
			var/lastController = controllers[controllers.len]
			if(hascall(lastController, "interrupt"))
				lastController:interrupt(src)
		controllers.Add(controller)


//------------------------------------------------------------------------------

sequence
	var
		priority = TRUE
	proc/init(combatant/combatant)
		combatant.addController(src)
	proc/interrupt()
	proc/control(combatant/combatant)


//-- Hp, Mp, Death -------------------------------------------------------------

combatant
	var
		hp = 0
		mp = 0
		baseHp = 3
		baseMp = 0
		dead = FALSE
		invincible
	proc
		maxHp()
			return baseHp
		maxMp()
			return baseMp
		adjustHp(amount, combatant/attacker)
			var oldHp = hp
			hp += amount;
			if(hp <= 0)
				hp = 0
				die(attacker)
			var hpMax = maxHp()
			if(hp > hpMax) hp = hpMax
			var deltaHp = hp - oldHp
			return deltaHp
		adjustMp(amount, combatant/attacker)
			var oldMp = mp
			mp += amount;
			var mpMax = maxMp()
			if(mp > mpMax) mp = mpMax
			var deltaMp = mp - oldMp
			return deltaMp
		hurt(amount, combatant/attacker, projectile/proxy)
			if(invincible) return
			. = adjustHp(-amount)
			if(. < 0) invincible(TIME_HURT)
			if(!dead && (attacker || proxy))
				var/pushDir = proxy? proxy.dir : attacker.cardinalTo(src)
				new /event/push(src, pushDir, 3, 8)
			return .
		die(combatant/attacker)
			if(disposable)
				spawn()
					new /event/puff(src)
					del src
		attack(combatant/target, amount, proxy)
			return target.hurt(amount, src, proxy)
		invincible(amount)
			invincible = max(invincible, amount)

	//-- Projectiles & Shooting -------------------//
	var
		projectileType = /projectile // the kind of projectile, if any, the combatant shoots by default
		list/projectiles[0]
	proc
		shoot(typePath)
			if(!typePath) typePath = projectileType
			if(!typePath) return
			return new typePath(src)


//-- Projectiles ---------------------------------------------------------------

projectile
	parent_type = /actor
	icon = 'projectiles.dmi'
	movement = MOVEMENT_FLOOR|MOVEMENT_WATER
	density = FALSE
	baseSpeed = 4
	var
		combatant/owner
		potency = 1
		projecting = TRUE
		persistent = FALSE
		explosive = FALSE
		terminalExplosion = FALSE
		maxRange
		maxTime
		currentRange
		currentTime
		interactionProperties = INTERACTION_NONE
		coord/vel
	New(var/combatant/_owner)
		. = ..()
		vel = new(0,0)
		if(_owner)
			owner = _owner
			if(!faction) faction = owner.faction
			owner.projectiles.Add(src)
			forceLoc(owner.loc)
			centerLoc(owner)
			dir = owner.dir
			if(projecting)
				project()
	centerLoc(var/atom/movable/_center)
		if(!_center && owner) _center = owner
		. = ..()
	proc
		project()
			if(owner)
				dir = owner.dir
			switch(dir)
				if(NORTH) vel.y =  speed()
				if(SOUTH) vel.y = -speed()
				if(EAST ) vel.x =  speed()
				if(WEST ) vel.x = -speed()
	takeTurn()
		. = ..()
		if((vel.x || vel.y) && !translate(vel.x, vel.y))
			if(explosive)
				explode()
			else
				del src
		if(maxRange)
			if(currentRange >= maxRange)
				if(terminalExplosion) explode()
				else del src
			currentRange += max(abs(vel.x), abs(vel.y))
		if(maxTime)
			if(currentTime  >= maxTime )
				if(terminalExplosion) explode()
				else del src
			currentTime++
		for(var/combatant/_combatant in obounds(src))
			if(_combatant.dead) continue
			if(_combatant.invincible) continue
			if(_combatant.faction & faction) continue
			impact(_combatant)
		for(var/tile/interact/I in obounds(src))
			if(I.interaction & interactionProperties)
				I.interact(src, I.interaction & interactionProperties)

	/*behavior(event)
		. = ..()
		if(maxRange){
			if(currentRange >= maxRange){
				if(terminalExplosion){
					explode()
					}
				else{
					del src
					}
				}
			currentRange += max(abs(vel.x), abs(vel.y))
			}
		if(maxTime){
			if(currentTime  >= maxTime ){
				if(terminalExplosion){
					explode()
					}
				else{
					del src
					}
				}
			currentTime++
			}
		if((EAST |WEST )&dir){ step(src, (EAST |WEST )&dir, abs(vel.x))}
		if((NORTH|SOUTH)&dir){ step(src, (NORTH|SOUTH)&dir, abs(vel.y))}
		}*/
	/*
	Bump(var/atom/obstruction)
		. = ..()
		var/combatant/obs_u = obstruction
		if(istype(obs_u)) impact(obs_u)
		if(explosive) explode()
		else del src
	*/
	proc
		impact(combatant/target)
			if(owner) owner.attack(target, potency, src)
			else target.hurt(potency, null, src)
			if(!persistent)
				if(explosive) explode()
				else del src
		explode() del src
	/*	impactDir(atom/movable/target)
			var/deltaX = (target.x*TILE_SIZE+target.step_x+target.bound_width /2) - (x*TILE_SIZE+step_x+bound_width /2)
			var/deltaY = (target.y*TILE_SIZE+target.step_y+target.bound_height/2) - (y*TILE_SIZE+step_y+bound_height/2)
				world << "[deltaX],[deltaY]"
			if(abs(deltaX) >= abs(deltaY))
				if(deltaX >= 0) return EAST
				else return WEST
			else
				if(deltaY >= 0) return NORTH
				else return SOUTH*/