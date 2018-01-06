

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

	//-- Movement ---------------------------------//
	proc/go(deltaX, deltaY)
		var/tile/interact/I = locate() in locs
		if(I && I.interaction & INTERACTION_WALK)
			I.interact(src, INTERACTION_WALK)
		return translate(deltaX, deltaY)
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
	/*fist{
		icon_state = "fist"
		bound_height = 8
		bound_width  = 8
		persistent = TRUE
		movement = MOVEMENT_ALL
		potency = 1
		maxTime = 5
		base_speed = 4
		New(){
			. = ..()
			layer = owner.layer+1
			dir = owner.dir
			owner.icon_state = "attack"
			vel.x = 0
			vel.y = 0
			switch(dir){
				if(NORTH){
					vel.y = base_speed
					}
				if(SOUTH){
					vel.y = -base_speed
					}
				if(EAST ){
					vel.x = base_speed
					}
				if(WEST ){
					vel.x = -base_speed
					}
				}
			}
		Del(){
			owner.icon_state = initial(owner.icon_state)
			. = ..()
			}
		}
	arrow{
		maxTime = 32
		icon = 'projectiles.dmi'
		icon_state = "arrow"
		bound_height = 3
		bound_width  = 3
		persistent = FALSE
		base_speed = 6
		potency = 1
		var{
			long_bound_width = 16
			short_bound_width = 3
			unique = TRUE
			}
		New(){
			. = ..()
			if(unique){
				var/projectile/arrow/first_arrow
				for(var/projectile/arrow/A in owner.projectiles){
					if(!first_arrow){ first_arrow = A}
					else{
						del first_arrow
						break
						}
					}
				}
			dir = owner.dir
			switch(dir){
				if(NORTH,SOUTH){
					bound_height = long_bound_width
					bound_width = short_bound_width
					}
				if(EAST ,WEST ){
					bound_height = short_bound_width
					bound_width = long_bound_width
					}
				}
			centerLoc(owner)
			}
		}
	bolt{
		parent_type = /projectile/arrow
		maxRange = 60
		icon_state = "bolt"
		long_bound_width = 12
		}
	sword{
		icon = 'projectiles.dmi'
		movement = MOVEMENT_ALL
		impact(var/combatant/target){
			owner.attack(target, potency)
			}
		bound_height = 4
		bound_width  = 4
		persistent = TRUE
		potency = 2
		var{
			stage = 0
			state_name = "sword"
			}
		New(){
			. = ..()
			vel.x = 0
			vel.x = 0
			}
		behavior(event){
			stage++
			dir = owner.dir
			owner.icon_state = "attack"
			switch(stage){
				if(1,5){
					icon_state = "[state_name]_6"
					switch(dir){
						if(NORTH, SOUTH){
							bound_height = 6
							bound_width  = 4
							}
						if( EAST,  WEST){
							bound_height = 4
							bound_width  = 6
							}
						}
					}
				if(2,4){
					icon_state = "[state_name]_11"
					switch(dir){
						if(NORTH, SOUTH){
							bound_height = 11
							bound_width  = 4
							}
						if( EAST,  WEST){
							bound_height = 4
							bound_width  = 11
							}
						}
					}
				if(3){
					icon_state = "[state_name]_16"
					switch(dir){
						if(NORTH, SOUTH){
							bound_height = 16
							bound_width  = 4
							}
						if( EAST,  WEST){
							bound_height = 4
							bound_width  = 16
							}
						}
					}
				if(6){
					owner.icon_state = initial(owner.icon_state)
					del src
					}
				}
			switch(dir){
				if(NORTH){
					step_x = owner.step_x + (owner.bound_width-bound_width)/2
					step_y = owner.step_y + owner.bound_height
					pixel_x = -6
					}
				if(SOUTH){
					step_x = owner.step_x + (owner.bound_width-bound_width)/2
					step_y = owner.step_y - bound_height
					pixel_x = -6
					pixel_y = -(16-bound_height)
					}
				if( EAST){
					step_x = owner.step_x + owner.bound_width
					step_y = owner.step_y + (owner.bound_height-bound_height)/2
					pixel_y = -6
					}
				if( WEST){
					step_x = owner.step_x - bound_width
					step_y = owner.step_y + (owner.bound_height-bound_height)/2
					pixel_y = -6
					pixel_x = -(16-bound_width)
					}
				}
			for(var/atom/movable/M in obounds(src,0)){
				M.Crossed(src)
				}
			}
		}
	spear{
		icon_state = "spear"
		bound_height = 3
		bound_width  = 3
		persistent = FALSE
		base_speed = 2
		maxRange = 192
		var{
			long_bound_width = 16
			short_bound_width = 3
			}
		New(){
			. = ..()
			dir = owner.dir
			switch(dir){
				if(NORTH,SOUTH){
					bound_height = long_bound_width
					bound_width = short_bound_width
					}
				if(EAST ,WEST ){
					bound_height = short_bound_width
					bound_width = long_bound_width
					}
				}
			}
		}
	axe{
		parent_type = /projectile/sword
		interactionProperties = INTERACTION_PROPERTY_CUT
		icon_state = "axe"
		bound_height = 16
		bound_width  = 16
		persistent = TRUE
		potency = 2
		state_name = "axe"
		behavior(){
			stage++
			owner.icon_state = "attack"
			loc = owner.loc
			switch(stage){
				if(1,2){ dir = turn(owner.dir, -45)}
				if(3,4){ dir =      owner.dir      }
				if(5,6){ dir = turn(owner.dir,  45)}
				if(7){
					owner.icon_state = initial(owner.icon_state)
					del src
					}
				}
			switch(dir){
				if(EAST     ){
					step_x = owner.step_x+(16)
					step_y = owner.step_y
					}
				if(SOUTHEAST){
					step_x = owner.step_x+(16)
					step_y = owner.step_y-(16)
					}
				if(SOUTH    ){
					step_x = owner.step_x+2
					step_y = owner.step_y-(16)
					}
				if(SOUTHWEST){
					step_x = owner.step_x-(16)
					step_y = owner.step_y-(16)
					}
				if(WEST     ){
					step_x = owner.step_x-(16)
					step_y = owner.step_y
					}
				if(NORTHWEST){
					step_x = owner.step_x-(16)
					step_y = owner.step_y+ 16
					}
				if(NORTH    ){
					step_x = owner.step_x+2
					step_y = owner.step_y+(16)
					}
				if(NORTHEAST){
					step_x = owner.step_x+(16)
					step_y = owner.step_y+(16)
					}
				}
			for(var/atom/movable/M in obounds(src,0)){
				M.Crossed(src)
				}
			}
		}*/
	/*
	fire_1{
		parent_type = /projectile/magic_1
		movement = MOVEMENT_LAND | MOVEMENT_WATER
		icon_state = "fire_ball"
		bound_height = 6
		bound_width = 6
		}
	fire_2{
		parent_type = /projectile/fire_1
		icon_state = "fire_ball_2"
		potency = 2
		}
	fire_large{
		parent_type = /projectile/fire_1
		bound_height = 16
		bound_width = 16
		icon_state = "fire_large"
		potency = 2
		}
	magic_2{
		parent_type = /projectile/magic_1
		potency = 2
		icon_state = "enemy_magic_2"
		}
	magic_1{
		icon_state = "enemy_magic_1"
		bound_height = 8
		bound_width  = 8
		persistent = FALSE
		base_speed = 2
		New(){
			. = ..()
			dir = owner.dir
			switch(dir){
				if(NORTH){
					c.x = owner.c.x + round((owner.bound_width -bound_width )/2)
					c.y = owner.c.y
					vel.x = 0
					vel.y = base_speed
					}
				if(SOUTH){
					c.x = owner.c.x + round((owner.bound_width -bound_width )/2)
					c.y = owner.c.y
					vel.x = 0
					vel.y = -base_speed
					}
				if(EAST ){
					c.x = owner.c.x
					c.y = owner.c.y + round((owner.bound_height-bound_height)/2)
					vel.x = base_speed
					vel.y = 0
					}
				if(WEST ){
					c.x = owner.c.x
					c.y = owner.c.y + round((owner.bound_height-bound_height)/2)
					vel.x = -base_speed
					vel.y = 0
					}
				}
			}
		}
	bone{
		icon_state = "bone"
		bound_height = 12
		bound_width = 12
		base_speed = 2
		New(){
			. = ..()
			dir = owner.dir
			switch(dir){
				if(NORTH){
					c.x = owner.c.x + round((owner.bound_width -bound_width )/2)
					c.y = owner.c.y
					vel.x = 0
					vel.y = base_speed
					}
				if(SOUTH){
					c.x = owner.c.x + round((owner.bound_width -bound_width )/2)
					c.y = owner.c.y
					vel.x = 0
					vel.y = -base_speed
					}
				if(EAST ){
					c.x = owner.c.x
					c.y = owner.c.y + round((owner.bound_height-bound_height)/2)
					vel.x = base_speed
					vel.y = 0
					}
				if(WEST ){
					c.x = owner.c.x
					c.y = owner.c.y + round((owner.bound_height-bound_height)/2)
					vel.x = -base_speed
					vel.y = 0
					}
				}
			}
		}*/
	/*acid{
		icon = 'projectiles_large.dmi'
		icon_state = "acid"
		bound_height = 28
		bound_width = 28
		bound_x = 2
		bound_y = 2
		base_speed = 0
		var{
			life_span = 128
			}
		behavior(){
			for(var/projectile/acid/A in obounds(src, -8)){
				if(A.life_span < life_span){
					del A
					}
				}
			if(life_span-- <= 0){
				del src
				}
			}
		}*//*
	}
projectile{
	wood_sword{
		parent_type = /projectile/sword
		state_name = "wood"
		potency = 1
		}
	gold_sword{
		parent_type = /projectile/sword
		state_name = "gold"
		potency = 4
		}
	black_sword{
		parent_type = /projectile/sword
		state_name = "black"
		impact(var/combatant/target){
			if(dir_to(owner, target) == turn(target.dir,180)){
				owner.attack(target, potency*2, src)
				}
			else{
				owner.attack(target, potency, src)
				}
			}
		}
	black_knife{
		parent_type = /projectile/black_sword
		behavior(){
			stage++
			dir = owner.dir
			owner.icon_state = "attack"
			switch(stage){
				if(1,3){
					icon_state = "[state_name]_6"
					switch(dir){
						if(NORTH, SOUTH){
							bound_height = 6
							bound_width  = 4
							}
						if( EAST,  WEST){
							bound_height = 4
							bound_width  = 6
							}
						}
					}
				if(2){
					icon_state = "[state_name]_11"
					switch(dir){
						if(NORTH, SOUTH){
							bound_height = 11
							bound_width  = 4
							}
						if( EAST,  WEST){
							bound_height = 4
							bound_width  = 11
							}
						}
					}
				if(4){
					owner.icon_state = initial(owner.icon_state)
					del src
					}
				}
			switch(dir){
				if(NORTH){
					c.x = owner.c.x + (owner.bound_width-bound_width)/2
					c.y = owner.c.y + owner.bound_height
					}
				if(SOUTH){
					c.x = owner.c.x + (owner.bound_width-bound_width)/2
					c.y = owner.c.y - bound_height
					}
				if( EAST){
					c.x = owner.c.x + owner.bound_width
					c.y = owner.c.y + (owner.bound_height-bound_height)/2
					}
				if( WEST){
					c.x = owner.c.x - bound_width
					c.y = owner.c.y + (owner.bound_height-bound_height)/2
					}
				}
			}
		}
	saber{
		parent_type = /projectile/axe
		icon_state = "saber"
		potency = 1
		state_name = "saber"
		}
	wood_axe{
		parent_type = /projectile/saber
		icon_state = "wood_axe"
		potency = 1
		state_name = "axe"
		}
	gold_axe{
		parent_type = /projectile/axe
		icon_state = "gold_axe"
		potency = 4
		state_name = "axe"
		}
	wood_lance{
		parent_type = /projectile/lance
		potency = 1
		icon = 'projectiles.dmi'
		icon_state = "wood_lance"
		}
	lance{
		persistent = TRUE
		potency = 2
		icon = 'projectiles.dmi'
		icon_state = "lance"
		impact(var/combatant/target){
			owner.attack(target, potency)
			}
		var{
			stage = 0
			}
		New(){
			. = ..()
			switch(dir){
				if(NORTH){
					pixel_x = owner.pixel_x
					pixel_y = owner.pixel_y
					}
				if(SOUTH){
					pixel_x = owner.pixel_x
					pixel_y = owner.pixel_y
					}
				if( EAST){
					pixel_x = owner.pixel_x
					pixel_y = owner.pixel_y
					}
				if( WEST){
					pixel_x = owner.pixel_x
					pixel_y = owner.pixel_y
					}
				}
			}
		behavior(){
			stage++
			dir = owner.dir
			loc = owner.loc
			owner.icon_state = "attack"
			switch(stage){
				if(1 to 3){
					switch(dir){
						if(NORTH){ pixel_y += 10; c.y += 10}
						if(SOUTH){ pixel_y -= 10; c.y -= 10}
						if( EAST){ pixel_x += 10; c.x += 10}
						if( WEST){ pixel_x -= 10; c.x -= 10}
						}
					}
				if(4 to 6){
					switch(dir){
						if(NORTH){ pixel_y -= 10; c.y -= 10}
						if(SOUTH){ pixel_y += 10; c.y += 10}
						if( EAST){ pixel_x -= 10; c.x -= 10}
						if( WEST){ pixel_x += 10; c.x += 10}
						}
					}
				if(7){
					owner.icon_state = initial(owner.icon_state)
					del src
					}
				}
			}
		redraw(){}
		}
	/*ball{
		persistent = TRUE
		potency = 2
		icon = 'projectiles.dmi'
		icon_state = "ball"
		bound_width = 11
		bound_height = 11
		movement = MOVEMENT_LAND | MOVEMENT_WATER
		var{
			projectile/ball/chain/chain1
			projectile/ball/chain/chain2
			projectile/ball/chain/chain3
			}
		New(){
			. = ..()
			c.x = owner.c.x + (owner.bound_width -bound_width )/2
			c.y = owner.c.y + (owner.bound_height-bound_height)/2
			chain1 = new(owner)
			chain2 = new(owner)
			chain3 = new(owner)
			layer++
			dir = owner.dir
			switch(owner.dir){
				if(EAST ){ vel.x =  6; vel.y =  0}
				if(WEST ){ vel.x = -6; vel.y =  0}
				if(NORTH){ vel.x =  0; vel.y =  6}
				if(SOUTH){ vel.x =  0; vel.y = -6}
				}
			}
		maxRange = 2000
		behavior(){
			owner.icon_state = "attack"
			if(!reversed){ time++}
			else{          time--}
			if(!time){ del src}
			if(!reversed && currentRange >= 25 && !(currentRange%12)){
				if(owner:aura < 1){
					reverse()
					}
				else{
					owner:adjust_aura(-1)
					}
				}
			. = ..()
			var/owner_center
			var/factor
			if(dir & (EAST|WEST)){
				chain1.c.y = owner.c.y + (owner.bound_height-chain1.bound_height)/2
				chain2.c.y = chain1.c.y
				chain3.c.y = chain1.c.y
				owner_center = owner.c.x+(owner.bound_width/2)
				factor = (c.x+(bound_width /2)) - owner_center
				chain1.c.x = (owner_center + factor*1/4) - bound_width /2
				chain2.c.x = (owner_center + factor*2/4) - bound_width /2
				chain3.c.x = (owner_center + factor*3/4) - bound_width /2
				}
			if(dir & (NORTH|SOUTH)){
				chain1.c.x = owner.c.x + (owner.bound_width-chain1.bound_width)/2
				chain2.c.x = chain1.c.x
				chain3.c.x = chain1.c.x
				owner_center = owner.c.y+(owner.bound_height/2)
				factor = (c.y+(bound_height/2)) - owner_center
				chain1.c.y = (owner_center + factor*1/4) - bound_height/2
				chain2.c.y = (owner_center + factor*2/4) - bound_height/2
				chain3.c.y = (owner_center + factor*3/4) - bound_height/2
				}
			}
		chain{
			parent_type = /projectile
			icon = 'projectiles.dmi'
			icon_state = "chain"
			persistent = TRUE
			potency = 0
			bound_width = 5
			bound_height = 5
			impact(){}
			behavior(){}
			}
		impact(var/combatant/target){
			owner.attack(target, potency)
			reverse()
			}
		horizontal_stop(){
			reverse()
			}
		vertical_stop(){
			reverse()
			}
		var{
			reversed = FALSE
			time = 0
			}
		proc{
			reverse(){
				if(reversed){ return}
				reversed = TRUE
				vel.x *= -1
				vel.y *= -1
				}
			}
		Del(){
			del chain1
			del chain2
			del chain3
			owner.icon_state = null
			. = ..()
			}
		}*/
	arrow{
		maxTime = 32
		icon = 'projectiles.dmi'
		icon_state = "arrow"
		bound_height = 3
		bound_width  = 3
		persistent = FALSE
		base_speed = 6
		var{
			long_bound_width = 16
			short_bound_width = 3
			unique = TRUE
			}
		New(){
			if(unique){
				var/projectile/arrow/first_arrow
				for(var/projectile/arrow/A in owner.projectiles){
					if(!first_arrow){ first_arrow = A}
					else{
						del first_arrow
						break
						}
					}
				}
			. = ..()
			dir = owner.dir
			switch(dir){
				if(NORTH){
					c.x = owner.c.x + round((owner.bound_width -bound_width )/2)
					c.y = owner.c.y
					vel.x = 0
					vel.y = base_speed
					bound_height = long_bound_width
					bound_width = short_bound_width
					}
				if(SOUTH){
					c.x = owner.c.x + round((owner.bound_width -bound_width )/2)
					c.y = owner.c.y
					vel.x = 0
					vel.y = -base_speed
					bound_height = long_bound_width
					bound_width = short_bound_width
					}
				if(EAST ){
					c.x = owner.c.x
					c.y = owner.c.y + round((owner.bound_height-bound_height)/2)
					vel.x = base_speed
					vel.y = 0
					bound_height = short_bound_width
					bound_width = long_bound_width
					}
				if(WEST ){
					c.x = owner.c.x
					c.y = owner.c.y + round((owner.bound_height-bound_height)/2)
					vel.x = -base_speed
					vel.y = 0
					bound_height = short_bound_width
					bound_width = long_bound_width
					}
				}
			}
		}
	magic_1{
		icon = 'projectiles.dmi'
		icon_state = "fire_ball"
		bound_height = 6
		bound_width  = 6
		persistent = FALSE
		maxRange = 96
		base_speed = 6
		var{
			disable_time = 12
			}
		New(){
			. = ..()
			dir = owner.dir
			switch(dir){
				if(EAST ){
					c.x = owner.c.x
					c.y = owner.c.y + round((owner.bound_height-bound_height)/2)
					vel.x = base_speed
					vel.y = 0
					}
				if(NORTH){
					c.x = owner.c.x + round((owner.bound_width -bound_width )/2)
					c.y = owner.c.y
					vel.x = 0
					vel.y = base_speed
					}
				if(SOUTH){
					c.x = owner.c.x + round((owner.bound_width -bound_width )/2)
					c.y = owner.c.y
					vel.x = 0
					vel.y = -base_speed
					}
				if(WEST ){
					c.x = owner.c.x
					c.y = owner.c.y + round((owner.bound_height-bound_height)/2)
					vel.x = -base_speed
					vel.y = 0
					}
				}
			}
		}
	magic_2{
		parent_type = /projectile/magic_1
		maxRange = FALSE
		icon_state = "fire_large"
		bound_height = 16
		bound_width  = 16
		potency = 2
		}
	bone{
		parent_type = /projectile/magic_1
		icon_state = "bone"
		bound_height = 12
		bound_width = 12
		base_speed = 3
		}
	fire_persistent{
		parent_type = /projectile/magic_1
		icon_state = "fire_ball"
		maxTime = 12
		bound_height = 5
		bound_width = 5
		persistent = TRUE
		maxRange = FALSE
		potency = 2
		}
	healing{
		icon = 'projectiles_large.dmi'
		icon_state = "healing"
		bound_height = 30
		bound_width = 30
		maxRange = 24
		maxTime = 8
		impact(var/combatant/target){}
		}
	magic_sword{
		parent_type = /projectile/arrow
		unique = FALSE
		icon = 'projectiles.dmi'
		icon_state = "sword"
		persistent = FALSE
		potency = 2
		long_bound_width = 16
		short_bound_width = 5
		}
	/*controlled_sword{
		icon = 'projectiles.dmi'
		icon_state = "sword"
		explosive = TRUE
		potency = 2
		base_speed = 3
		var{
			long_bound_width = 16
			short_bound_width = 5
			}
		New(){
			. = ..()
			owner.intelligence = src
			dir = owner.dir
			switch(dir){
				if(NORTH){
					c.x = owner.c.x + round((owner.bound_width -bound_width )/2)
					c.y = owner.c.y
					vel.x = 0
					vel.y = base_speed
					bound_height = long_bound_width
					bound_width = short_bound_width
					}
				if(SOUTH){
					c.x = owner.c.x + round((owner.bound_width -bound_width )/2)
					c.y = owner.c.y
					vel.x = 0
					vel.y = -base_speed
					bound_height = long_bound_width
					bound_width = short_bound_width
					}
				if(EAST ){
					c.x = owner.c.x
					c.y = owner.c.y + round((owner.bound_height-bound_height)/2)
					vel.x = base_speed
					vel.y = 0
					bound_height = short_bound_width
					bound_width = long_bound_width
					}
				if(WEST ){
					c.x = owner.c.x
					c.y = owner.c.y + round((owner.bound_height-bound_height)/2)
					vel.x = -base_speed
					vel.y = 0
					bound_height = short_bound_width
					bound_width = long_bound_width
					}
				}
			}
		Del(){
			owner.icon_state = initial(owner.icon_state)
			. = ..()
			}
		explode(){
			var/old_dir = owner.dir
			for(var/_dir in list(NORTH, SOUTH, EAST, WEST)){
				owner.dir = _dir
				var/projectile/magic_sword/sword = new(owner)
				sword.maxRange = 48
				sword.persistent = TRUE
				var/coord/old_center = new(c.x+bound_width/2, c.y+bound_height/2)
				var/coord/new_center = new(sword.c.x+sword.bound_width/2, sword.c.y+sword.bound_height/2)
				if(old_center.x != new_center.x || old_center.y != new_center.y){
					sword.c.x += round(old_center.x - new_center.x)
					sword.c.y += round(old_center.y - new_center.y)
					}
				}
			owner.dir = old_dir
			. = ..()
			}
		proc{
			intelligence(){
				if(istype(owner) && istype(owner.player)){
					var/combatant/owner_hero = owner
					owner_hero.icon_state = "cast"
					var/x_translate = 0
					var/y_translate = 0
					if     (EAST  & (owner.player.key_state | owner.player.key_pressed)){ dir = EAST }
					else if(WEST  & (owner.player.key_state | owner.player.key_pressed)){ dir = WEST }
					else if(NORTH & (owner.player.key_state | owner.player.key_pressed)){ dir = NORTH}
					else if(SOUTH & (owner.player.key_state | owner.player.key_pressed)){ dir = SOUTH}
					px_move(x_translate, y_translate)
					owner.player.clear_keys()
					}
				var/coord/old_center = new(c.x+bound_width/2, c.y+bound_height/2)
				switch(dir){
					if(NORTH){
						vel.x = 0
						vel.y = base_speed
						bound_height = long_bound_width
						bound_width = short_bound_width
						}
					if(SOUTH){
						vel.x = 0
						vel.y = -base_speed
						bound_height = long_bound_width
						bound_width = short_bound_width
						}
					if(EAST ){
						vel.x = base_speed
						vel.y = 0
						bound_height = short_bound_width
						bound_width = long_bound_width
						}
					if(WEST ){
						vel.x = -base_speed
						vel.y = 0
						bound_height = short_bound_width
						bound_width = long_bound_width
						}
					}
				var/coord/new_center = new(c.x+bound_width/2, c.y+bound_height/2)
				if(old_center.x != new_center.x || old_center.y != new_center.y){
					c.x += round(old_center.x - new_center.x)
					c.y += round(old_center.y - new_center.y)
					}
				}
			}
		}*/
	seeker{
		icon = 'projectiles.dmi'
		icon_state = "magic_2"
		bound_height = 5
		bound_width  = 5
		persistent = FALSE
		potency = 2
		base_speed = 3
		New(){
			. = ..()
			vel.x = 0
			vel.y = 0
			switch(owner.dir){
				if(NORTH){
					c.x = owner.c.x + round((owner.bound_width -bound_width )/2)
					c.y = owner.c.y
					vel.y = base_speed
					}
				if(SOUTH){
					c.x = owner.c.x + round((owner.bound_width -bound_width )/2)
					c.y = owner.c.y
					vel.y = -base_speed
					}
				if(EAST ){
					c.x = owner.c.x
					c.y = owner.c.y + round((owner.bound_height-bound_height)/2)
					vel.x = base_speed
					}
				if(WEST ){
					c.x = owner.c.x
					c.y = owner.c.y + round((owner.bound_height-bound_height)/2)
					vel.x = -base_speed
					}
				}
			}
		behavior(){
			var/combatant/closest
			var/close_dist
			for(var/combatant/E in range(COLLISION_RANGE, src)){
				var/dist = (c.x+(bound_width/2)) - (E.c.x+(E.bound_width/2))
				if(!closest){
					closest = E
					close_dist = dist
					continue
					}
				if(dist < close_dist){
					closest = E
					close_dist = dist
					}
				}
			if(!closest){
				.=..()
				return
				}
			vel.x += sign((closest.c.x+(closest.bound_width /2)) - (c.x+(bound_width /2)))
			vel.y += sign((closest.c.y+(closest.bound_height/2)) - (c.y+(bound_height/2)))
			vel.x = min(base_speed, max(-base_speed, vel.x))
			vel.y = min(base_speed, max(-base_speed, vel.y))
			. = ..()
			}
		}
	/*controlled_orb{
		bound_height = 15
		bound_width = 15
		New(){
			. = ..()
			owner.intelligence = src
			}
		base_speed = 2
		impact(){}
		horizontal_stop(){}
		vertical_stop(){}
		proc{
			intelligence(){
				if(istype(owner) && istype(owner.player)){
					var/combatant/owner_hero = owner
					owner_hero.icon_state = "cast"
					var/x_translate = 0
					var/y_translate = 0
					if(EAST  & (owner.player.key_state | owner.player.key_pressed)){ x_translate += base_speed}
					if(WEST  & (owner.player.key_state | owner.player.key_pressed)){ x_translate -= base_speed}
					if(NORTH & (owner.player.key_state | owner.player.key_pressed)){ y_translate += base_speed}
					if(SOUTH & (owner.player.key_state | owner.player.key_pressed)){ y_translate -= base_speed}
					px_move(x_translate, y_translate)
					if(PRIMARY & owner.player.key_pressed){         finish()}
					else if(SECONDARY & owner.player.key_pressed){  finish()}
					else if(TERTIARY & owner.player.key_pressed){   finish()}
					else if(QUATERNARY & owner.player.key_pressed){ finish()}
					owner.player.
					s()
					}
				}
			finish(){
				Del()
				}
			}
		}
	healing_orb{
		parent_type = /projectile/controlled_orb
		icon_state = "healing"
		potency = 2
		finish(){
			var/combatant/closest
			var/close_distance = 300
			for(var/combatant/H in orange(COLLISION_RANGE, src)){
				var/h_dist = abs((H.c.x+(H.bound_width/2)) - (c.x+(bound_width/2))) + abs((H.c.y+(H.bound_height/2)) - (c.y+(bound_height/2)))
				if(!closest){
					closest = H
					close_distance = h_dist
					continue
					}
				if(h_dist < close_distance){
					closest = H
					}
				}
			if(closest){
				if(collision_check(closest)){
					var/projectile/healing/heal_flash = new(owner)
					heal_flash.c.x = (c.x+(bound_width /2)) - (heal_flash.bound_width /2)
					heal_flash.c.y = (c.y+(bound_height/2)) - (heal_flash.bound_height/2)
					closest.adjust_health(potency)
					}
				}
			if(istype(owner) && istype(owner.player)){
				owner.player.clear_keys()
				}
			owner.icon_state = initial(owner.icon_state)
			Del()
			}
		}
	fire_snake{
		parent_type = /projectile/controlled_orb
		icon = 'projectiles.dmi'
		icon_state = "fire_stationary"
		maxTime = 128
		potency = 2
		var{
			list/body = new()
			length = 3
			body_radius = 16
			list/old_positions
			body_state = "fire_2"
			tail_state
			}
		base_speed = 3
		New(){
			. = ..()
			layer++
			old_positions = new()
			var/projectile/lead = src
			for(var/I = 1 to length){
				var/projectile/fire_snake/body/B = new(owner)
				B.icon = icon
				B.potency = potency
				B.c.x = c.x+(bound_width -B.bound_width )/2
				B.c.y = c.y+(bound_height-B.bound_height)/2
				body.Add(B)
				if(lead != src){
					var/projectile/fire_snake/body/leader = lead
					leader.follower = B
					}
				B.lead = lead
				lead = B
				B.head = src
				if(I == length && tail_state){
					B.icon_state = tail_state
					}
				else{
					B.icon_state = body_state
					}
				B.bound_height = body_radius
				B.bound_width = body_radius
				}
			}
		behavior(){
			var/coord/old_c = c.Copy()
			old_c.x += (bound_width -body_radius)/2
			old_c.y += (bound_height-body_radius)/2
			old_positions.Insert(1, old_c)
			old_positions[old_c] = dir
			. = ..()
			for(var/I = 1 to body.len){
				var/old_index = round(I * body_radius/base_speed)
				if(old_index <= old_positions.len){
					var/projectile/fire_snake/body/B = body[I]
					if(!B){ continue}
					var/coord/new_c = old_positions[old_index]
					B.dir = old_positions[new_c]
					B.c.x = new_c.x
					B.c.y = new_c.y
					}
				}
			old_positions.len = min(old_positions.len, round(body.len*body_radius/base_speed))
			}
		finish(){}
		Del(){
			for(var/projectile/P in body){
				del P
				}
			owner.icon_state = initial(owner.icon_state)
			. = ..()
			}
		body{
			parent_type = /projectile
			persistent = TRUE
			var{
				projectile/fire_snake/head
				projectile/lead
				projectile/follower
				}
			}
		}*/
	fire_dance{
		base_speed = 3
		var{
			angle = 0
			}
		potency = 2
		maxTime = 120
		persistent = TRUE
		icon_state = "fire_dance"
		horizontal_stop(){
			angle += 180
			}
		vertical_stop(){
			angle += 180
			}
		behavior(){
			angle += rand(-32, 32)
			vel.x = round(cos(angle) * base_speed)
			vel.y = round(sin(angle) * base_speed)
			. = ..()
			}
		}
	}*/