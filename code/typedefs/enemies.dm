enemy
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
		parent_type = /enemy/ruttle1
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
		parent_type = /enemy/ruttle1
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