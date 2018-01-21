

//-- Taiga - Deep Forest Terrain -----------------------------------------------

terrain/taiga
	id = "taiga"
	name = "Taiga"
	icon = 'taiga.dmi'
	var
		interactOverlay
		interactMovement = MOVEMENT_FLOOR
		interaction = INTERACTION_WALK | INTERACTION_WIND
	setupTileInteraction(tile/interact/theTile)
	triggerTileInteraction(tile/interact/theTile, atom/interactor, interactionFlags)
	// Enemy Selection
	infantry = list(
		/enemy/ruttle1,
		/enemy/ruttle2,
		/enemy/ruttle3,
	)
	officer = list(
		/enemy/iceBerserker,
	)