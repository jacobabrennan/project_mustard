

//-- Usable - Objects that can be "used" by combatant --------------------------

usable
	parent_type = /obj
	proc/use(combatant/user)


//-- Items - can be placed on the map. Combatants can "get" --------------------

item
	parent_type = /usable
	icon = 'weapons.dmi'
	icon_state = "potion"
	var
		price = 1
		instant = FALSE
			// Items, like Fruit, that are used as soon as picked up.
		equipFlags = EQUIP_ANY
		// Nonconfigurable:
		timeStamp
	New()
		. = ..()
		timeStamp = world.time
	use(combatant/user)
		. = ..()
		if(instant)
			del src
	Cross(character/partyMember/getChar)
		if(world.time - timeStamp < TIME_ITEM_COLLECT) return ..()
		if(!loc) return FALSE
		if(istype(getChar))
			if(instant)
				use(getChar)
			else
				getChar.get(src)
		return . = ..()
	gear
		var
			position = WEAR_BODY
			boostHp = 0
			boostMp = 0
			boostAuraRegain = 0
		proc
			equipped(character/equipper)
			unequipped(character/unequipper)

	//-- Instance definitions - factor out -----------
		plate
			name = "Plate"
			position = WEAR_BODY
			boostHp = 4
			price = 120
			icon = 'armor.dmi'
			icon_state = "armor"
		cloth
			name = "Cloth"
			position = WEAR_BODY
			price = 30
			boostHp = 2
			icon = 'armor.dmi'
			icon_state = "cloth"
		buckler
			name = "Buckler"
			position = WEAR_SHIELD
			price = 5
			boostHp = 0
			icon = 'armor.dmi'
			icon_state = "buckler"
		talaria
			name = "Talaria"
			position = WEAR_CHARM
			price = 60
			boostHp = 2
			boostMp = 2
			icon = 'armor.dmi'
			icon_state = "talaria"
			/*
			use(character/user)
				var/building/house1/D = new()
				D.build(user.x, user.y+1, plot(user))
			*/
		ring
			name = "Ring"
			position = WEAR_CHARM
			price = 255
			boostMp = 4
			icon = 'armor.dmi'
			icon_state = "charm"
			/*
			use(character/user)
				var/building/dungeon/D = new()
				D.build(user.x, user.y+1, plot(user))
			*/
	bookHealing1
		parent_type = /item/book
		icon_state = "bookHeal1"
		use(character/user)
			// Add some kind of flash on the hud
			if(user.mp < mpCost) return
			user.mp -= mpCost
				//for(var/combatant/C in bounds(src,

	//-- Item - Basic Archetypes ---------------------
	book
		parent_type = /item
		equipFlags = EQUIP_BOOK
		icon = 'items.dmi'
		icon_state = "book"
		var
			mpCost = 1
			range = 32

	//-- Gear - Basic Archetypes ---------------------
	shield
		parent_type = /item/gear
		position = WEAR_SHIELD
		equipFlags = EQUIP_SHIELD
		icon = 'armor.dmi'
		icon_state = "shield"
		var
			threshold = 1
			// Projectiles with potency <= value will be blocked
		proc
			defend(projectile/proxy, combatant/attacker, damage)
				. = TRUE
				if(damage > threshold) return FALSE
	weapon
		parent_type = /item/gear
		position = WEAR_WEAPON
		icon = 'weapons.dmi'
		icon_state = "sword"
		var
			potency = 1
			projectileType = /projectile/sword
		use(combatant/user)
			var/projectile/P = user.shoot(projectileType)
			if(!P) return
			P.potency = potency
			return P
		sword
			equipFlags = EQUIP_SWORD
			icon_state = "sword"
			projectileType = /projectile/sword
			potency = 1
		axe
			equipFlags = EQUIP_AXE
			icon_state = "axe"
			projectileType = /projectile/axe
			potency = 2
		bow
			equipFlags = EQUIP_BOW
			icon_state = "crossbow"
			projectileType = /projectile/bowArrow
			potency = 1
			var
				arrowSpeed = 6
				arrowRange = 240
				// Nonconfigurable:
				projectile/bowArrow/currentArrow
			use(combatant/user)
				del currentArrow
				var /projectile/bowArrow/A = ..()
				if(!A) return
				A.baseSpeed = arrowSpeed
				A.maxRange = arrowRange
				A.project()
				currentArrow = A
				return A
			proc/ready()
				if(!currentArrow) return TRUE
		wand // Weak Melee attack plus magic projectile
			equipFlags = EQUIP_WAND
			icon_state = "wand"
			projectileType = /projectile/wand
			potency = 1
			var
				spellCost = 1
				spellProjectileType = /projectile/fire1
				spellPotency
				spellSpeed = 6
				spellRange = 240
			use(combatant/user)
				. = ..()
				if(user.mp < spellCost) return
				user.adjustMp(-spellCost)
				var /projectile/P = user.shoot(spellProjectileType)
				if(!P) return
				P.baseSpeed = spellSpeed || P.baseSpeed
				P.maxRange = spellRange || P.maxRange
				P.project()
				return P




//-- Enemy Drops (eg: hearts) --------------------------------------------------

	instant
		instant = TRUE
		bound_width = 8
		bound_height = 8
		New()
			. = ..()
			spawn(TIME_ITEM_DISAPPEAR)
				del src
		Cross(character/getChar)
			var/projectile/P = getChar
			if(istype(P))
				if(world.time - timeStamp < 10) return ..()
				var/character/C = P.owner
				if(istype(C))
					use(C)
					return TRUE
			else
				. = ..()
		coin
			icon = 'item_drops.dmi'
			icon_state = "coin_gold"
			use(character/user)
				//user.adjustCharacterPoints(1)
				. = ..()
		berry
			icon = 'item_drops.dmi'
			icon_state = "cherry"
			use(character/user)
				var result = user.adjustHp(1)
				if(result)
					. = ..()
		plum
			icon = 'item_drops.dmi'
			icon_state = "plum"
			use(character/user)
				var result = user.adjustHp(10)
				if(result)
					. = ..()
		magicBottle
			icon = 'item_drops.dmi'
			icon_state = "bottle"
			use(character/user)
				var result = user.adjustMp(user.maxMp())
				if(result)
					. = ..()


//-- Skill - Can be hot keyed --------------------------------------------------

skill
	parent_type = /usable