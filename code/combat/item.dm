

//-- Usable - Objects that can be "used" by characters -------------------------

usable
	parent_type = /obj
	proc/use(character/user)

spell
	parent_type = /usable
	icon = 'spells.dmi'
	var
		mpCost = 1
	heal
		var
			range = 48


//-- Items - can be placed on the map. Characters can "get" --------------------

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
	use(character/user)
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
	weapon
		parent_type = /item/gear
		position = WEAR_WEAPON
		icon = 'weapons.dmi'
		icon_state = "sword"
		var
			twoHanded = FALSE
			potency = 1
			projectileType = /projectile/sword
		use(character/user)
			var/projectile/P = user.shoot(projectileType)
			if(!P) return
			P.potency = potency
			return P
		equipped(character/equipChar)
			. = ..()
			if(twoHanded)
				var /item/gear/secondHand = equipChar.equipment[WEAR_SHIELD]
				if(secondHand)
					equipChar.unequip(secondHand)

	//-- Basic Archetypes ----------------------------
	shield
		parent_type = /item/gear
		position = WEAR_SHIELD
		equipFlags = EQUIP_SHIELD
		icon = 'armor.dmi'
		icon_state = "blue"
		var
			threshold = 1
			// Projectiles with potency <= value will be blocked
			overlay
			underlay
			fileOverlay = 'shield_blue_overlay.dmi'
			fileUnderlay = 'shield_blue_underlay.dmi'
		proc
			defend(projectile/proxy, combatant/attacker, damage)
				. = TRUE
				if(damage > threshold) return FALSE
		equipped(character/equipChar)
			. = ..()
			var /image/overImage = image(fileOverlay)
			var /image/underImage = image(fileUnderlay)
			overImage.pixel_x = -2
			underImage.pixel_x = -2
			overlay  = getAppearance(overImage)
			underlay = getAppearance(underImage)
			equipChar.overlays.Add(overlay)
			equipChar.underlays.Add(underlay)
		unequipped(character/equipChar)
			. = ..()
			equipChar.overlays.Remove(overlay)
			equipChar.underlays.Remove(underlay)
	sword
		parent_type = /item/weapon
		equipFlags = EQUIP_SWORD
		icon_state = "sword"
		projectileType = /projectile/sword
		potency = 1
	axe
		parent_type = /item/weapon
		equipFlags = EQUIP_AXE
		twoHanded = TRUE
		icon_state = "axe"
		projectileType = /projectile/axe
		potency = 1
	bow
		parent_type = /item/weapon
		equipFlags = EQUIP_BOW
		icon_state = "crossbow"
		projectileType = /projectile/bowArrow
		potency = 1
		var
			arrowSpeed = 6
			arrowRange = 240
			// Nonconfigurable:
			projectile/bowArrow/currentArrow
		use(character/user)
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
	arrow
	wand // Weak Melee attack plus magic projectile
		parent_type = /item/weapon
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
		use(character/user)
			. = ..()
			if(user.mp < spellCost) return
			user.adjustMp(-spellCost)
			var /projectile/P = user.shoot(spellProjectileType)
			if(!P) return
			P.baseSpeed = spellSpeed || P.baseSpeed
			P.maxRange = spellRange || P.maxRange
			P.project()
			return P
	book
		parent_type = /item/gear
		position = WEAR_SHIELD
		equipFlags = EQUIP_BOOK
		icon = 'items.dmi'
		icon_state = "book"
		var
			list/spells
		equipped(character/equipChar)
			. = ..()
			var /list/hotKeys = list(SECONDARY, TERTIARY, QUATERNARY)
			for(var/I = 1 to spells.len)
				var typepath = spells[I]
				var /spell/S = new typepath()
				equipChar.setHotKey(S, hotKeys[I])
		unequipped(character/equipChar)
			for(var/typepath in spells)
				var /spell/S = locate(typepath) in equipChar.hotKeys
				if(!S) continue
				var index = equipChar.hotKeys.Find(S)
				var /list/hotKeys = list(SECONDARY, TERTIARY, QUATERNARY)
				equipChar.setHotKey(HOTKEY_REMOVE, hotKeys[index])
				del S


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
		berry
			icon = 'item_drops.dmi'
			icon_state = "cherry"
			use(character/user)
				var result = user.adjustHp(1)
				if(result)
					new /effect/sparkleHeal(user)
					. = ..()
		plum
			icon = 'item_drops.dmi'
			icon_state = "plum"
			use(character/user)
				var result = user.adjustHp(10)
				if(result)
					new /effect/sparkleHeal(user)
					. = ..()
		magicBottle
			icon = 'item_drops.dmi'
			icon_state = "bottle"
			use(character/user)
				var result = user.adjustMp(user.maxMp())
				if(result)
					new /effect/sparkleAura(user)
					. = ..()