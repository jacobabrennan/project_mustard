

//-- Enemy Type - For use directly ---------------------------------------------

enemy
	eyeMass
		parent_type = /enemy/ball
		icon = 'large.dmi'
		icon_state = "eye_1"
		//
		groupSize = 18
		childType = /enemy/eyeMass/groupMember
		respawnTime = 32
		rotationRate = 0
		baseHp = 8
		groupMember
			parent_type = /enemy/ball/groupMember
			icon = 'enemies.dmi'
			icon_state = "eye_1"
			baseHp = 5
	bowser
		parent_type = /enemy/snaking
		icon = 'enemies.dmi'
		icon_state = "dragon_head_1"
		bodyState = "dragon_body_1"
		tailState = "dragon_tail_1"
		length = 8
		bodyRadius = 6
		bodyHealth = 1
		baseSpeed = 3
		roughWalk = 16
	iceBerserker
		parent_type = /enemy/fixated
		icon = 'ice_berserker.dmi'
		baseHp = 6
		baseSpeed = 6
		turnDelay = 10
		roughWalk = 16
		projectileType = /projectile/axe
		shootFrequency = 1
	goblin
		parent_type = /enemy/ranged
		icon = 'goblin.dmi'
		baseSpeed = 1
		roughWalk = 4
		baseHp = 6
		projectileType = /projectile/fire1
	// Forest
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
		baseHp = 4
	ruttle3
		parent_type = /enemy/ruttle1
		icon = 'enemies.dmi'
		icon_state = "bug_3"
		baseHp = 16
	bird1
		parent_type = /enemy/diagonal
		icon = 'enemies.dmi'
		icon_state = "bird_1"
		layer = MOB_LAYER+2
		baseHp = 1
		baseSpeed = 2
	bird2
		parent_type = /enemy/bird1
		icon_state = "bird_2"
		baseHp = 2
		baseSpeed = 3
	// Ruins
	ghost1
		parent_type = /enemy/diagonal
		icon = 'enemies.dmi'
		icon_state = "ghost_1"
		layer = MOB_LAYER+2
		baseHp = 4
		baseSpeed = 1
		reflectFrequency = 2 // 1/chance to reflect when bumping
	ghost2
		parent_type = /enemy/ghost1
		icon_state = "ghost_2"
		baseHp = 8
		touchDamage = 2