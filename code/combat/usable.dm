

//------------------------------------------------------------------------------

usable
	parent_type = /obj
	proc/use(combatant/user)


//------------------------------------------------------------------------------

item
	parent_type = /usable
	icon = 'weapons.dmi'
	icon_state = "potion"
	var
		timeStamp
		price = 1
		instant = FALSE
			// Items, like Coins, that are used as soon as picked up.
		ingredientSignature
			// What this item counts as when crafting, such as SIG_WOOD.
	New()
		. = ..()
		timeStamp = world.time
	use(combatant/user)
		. = ..()
		if(instant)
			del src
	Cross(character/getChar)
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
		shield
			name = "Shield"
			position = WEAR_SHIELD
			price = 20
			boostHp = 1
			icon = 'armor.dmi'
			icon_state = "shield"
			ingredientSignature = SIG_SHIELD
		buckler
			name = "Buckler"
			position = WEAR_SHIELD
			price = 5
			boostHp = 0
			icon = 'armor.dmi'
			icon_state = "buckler"
			ingredientSignature = SIG_SHIELD
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
	weapon
		parent_type = /item/gear
		position = WEAR_WEAPON
		icon = 'weapons.dmi'
		icon_state = "sword"
		var
			potency = 1
			projectileType = /projectile/sword
		/*New()
			. = ..()
			icon_state = pick("sword", "axe", "crossbow")
			switch(icon_state)
				if("crossbow") potency = 1
				if("sword") potency = 2
				if("axe") potency = 4
			name = icon_state
		*/
		use(combatant/user)
			var/projectile/P = user.shoot(projectileType)
			if(!P) return
			P.potency = potency
			return P
			//user.adjustHp(user.maxHp())
		sword
			icon_state = "sword"
			projectileType = /projectile/sword
			potency = 2
		axe
			icon_state = "axe"
			projectileType = /projectile/axe
			potency = 2
		bow
			icon_state = "crossbow"
			projectileType = /projectile/bowArrow
			potency = 1
			var
				arrowSpeed = 6
				arrowRange = 240
				projectile/bowArrow/currentArrow
			use(character/partyMember/user)
				del currentArrow
				var /projectile/bowArrow/A = ..()
				if(!A) return
				A.baseSpeed = arrowSpeed
				A.maxRange = arrowRange
				A.projecting = TRUE
				A.project()
				currentArrow = A
				return A
			proc/ready()
				if(!currentArrow) return TRUE


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
			icon = 'items.dmi'
			icon_state = "coin_gold"
			use(character/user)
				//user.adjustCharacterPoints(1)
				. = ..()
		berry
			icon = 'items.dmi'
			icon_state = "cherry"
			use(character/user)
				var result = user.adjustHp(1)
				if(result)
					. = ..()
		plum
			icon = 'items.dmi'
			icon_state = "plum"
			use(character/user)
				var result = user.adjustHp(10)
				if(result)
					. = ..()


//------------------------------------------------------------------------------

skill
	parent_type = /usable