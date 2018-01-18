

//-- Item Type Definitions - Weapons, Gear, Books ------------------------------

item
	sword1
		parent_type = /item/sword
		icon_state = "sword1"
		potency = 2
	sword2
		parent_type = /item/sword
		icon_state = "sword2"
		potency = 4
	axe1
		parent_type = /item/axe
		icon_state = "axe1"
		potency = 1
	axe2
		parent_type = /item/axe
		icon_state = "axe2"
		potency = 2
	wand1
	wand2
	bow1
		parent_type = /item/bow
		icon_state = "bow1"
	bow2
		parent_type = /item/bow
		icon_state = "bow2"
	shield1
	shield2
	quiver1
		parent_type = /item/quiver
	quiver2
		parent_type = /item/quiver
	lightArmor1
	lightArmor2
	armor1
	armor2
	robe1
	robe2
	flail1


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


//-- Spells from Books ---------------------------------------------------------

spell
	heal1
		parent_type = /spell/heal
		icon_state = "heal1"