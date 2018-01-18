

//-- Test Enemy Characters - For enemy parties, place elsewhere ----------------

character/redCap
	parent_type = /character/goblin
	faction = FACTION_REDCAP
	baseHp = 9
	New()
		. = ..()
		equip(new /item/bow1())
		equip(new /item/quiver1())
character/redCap/leader
	parent_type = /character/soldier
	icon = 'goblin.dmi'
	faction = FACTION_REDCAP
	baseHp = 9
	New()
		. = ..()
		spawn(1)
			equip(new /item/axe())
			var /game/G = game(src)
			party = new(G.gameId)
			party.addPartyMember(src)
			for(var/I = 1 to 2)
				var /character/redCap/R = new()
				party.addPartyMember(R)
				R.loc = pick(block(locate(x-3, y-3, z), locate(x+3, y+3, z)))
client/DblClick(tile/T)
	. = ..()
	if(istype(T))
		spawn(10)
			var /character/redCap/leader/L = new()
			L.loc = T


//-- Character Type Definitions ------------------------------------------------

character
	regressiaHero
		name = "Regressia"
		partyId = CHARACTER_KING
		equipFlags = EQUIP_ANY
		icon = 'regressia_hero.dmi'
		baseHp = 3
		baseMp = 4
	hero
		name = "Hero"
		partyId = CHARACTER_HERO
		equipFlags = EQUIP_ANY
		icon = 'hero.dmi'
		portrait = "Hero"
		baseHp = 3
		baseMp = 3
	cleric
		name = "Cleric"
		partyId = CHARACTER_CLERIC
		equipFlags = EQUIP_WAND|EQUIP_BOOK|EQUIP_ROBE
		icon = 'cleric.dmi'
		portrait = "Cleric"
		partyDistance = 12
		baseHp = 3
		baseMp = 3
		baseAuraRegain = 9
		behavior()
			// Heal
			var healed = attemptToHeal()
			//
			if(!healed)
				return ..()
		proc/attemptToHeal()
			// Check if we can heal
			var /spell/heal/healSpell = hotKeys[1]
			if(!istype(healSpell)) return
			if(mp < healSpell.mpCost) return
			// Check if everyone has max hp
			var heal
			var radius = healSpell.range - (bound_width/2)
			for(var/character/member in party.characters)
				if(member.dead) continue
				if(bounds_dist(src, member) < radius)
					if(member.hp < member.maxHp())
						heal = TRUE
						break
			if(heal)
			// Use heal spell
				healSpell.use(src)
			// Otherwise, just return FALSE
			return
	soldier
		name = "Soldier"
		partyId = CHARACTER_SOLDIER
		equipFlags = EQUIP_AXE|EQUIP_SHIELD|EQUIP_ARMOR
		icon = 'soldier.dmi'
		portrait = "Soldier"
		partyDistance = 0
		baseHp = 3
	goblin
		name = "Goblin"
		partyId = CHARACTER_GOBLIN
		equipFlags = EQUIP_BOW
		icon = 'hero_goblin.dmi'
		portrait = "Goblin"
		partyDistance = 24
		roughWalk = 16
		baseHp = 3