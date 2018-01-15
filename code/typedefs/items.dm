

//-- Item Type Definitions - Weapons, Gear, Books ------------------------------

item
	plate
		parent_type = /item/gear
		name = "Plate"
		position = WEAR_BODY
		boostHp = 4
		price = 120
		icon = 'armor.dmi'
		icon_state = "armor"
	cloth
		parent_type = /item/gear
		name = "Cloth"
		position = WEAR_BODY
		price = 30
		boostHp = 2
		icon = 'armor.dmi'
		icon_state = "cloth"
	buckler
		parent_type = /item/gear
		name = "Buckler"
		position = WEAR_SHIELD
		price = 5
		boostHp = 0
		icon = 'armor.dmi'
		icon_state = "buckler"
	talaria
		parent_type = /item/gear
		name = "Talaria"
		position = WEAR_CHARM
		price = 60
		boostHp = 2
		boostMp = 2
		icon = 'armor.dmi'
		icon_state = "talaria"
	ring
		parent_type = /item/gear
		name = "Ring"
		position = WEAR_CHARM
		price = 255
		boostMp = 4
		icon = 'armor.dmi'
		icon_state = "charm"

	bookHealing1
		parent_type = /item/book
		icon_state = "bookHeal1"
		spells = list(/spell/heal1)

spell
	icon = 'spells.dmi'
	var
		mpCost = 1
	//
	heal
		var
			range = 48
	heal1
		parent_type = /spell/heal
		icon_state = "heal1"
		use(character/user)
			// Add some kind of flash on the hud
			if(user.mp < mpCost) return
			user.adjustMp(-mpCost)
			var radius = range - (user.bound_width/2)
			new /effect/aoeColor(user, radius, "#0f0")
			for(var/combatant/C in bounds(user, radius))
				if(!(C.faction & user.faction)) continue
				C.adjustHp(1)
				new /effect/sparkleHeal(C)