

//-- Configure project's BYOND settings ----------------------------------------

world
	tick_lag = TICK_DELAY
	icon_size = TILE_SIZE
	view = PLOT_SIZE/2
	map_format = SIDE_MAP
	maxx = PLOT_SIZE
	maxy = PLOT_SIZE
	maxz = MAP_DEPTH
client/perspective = EYE_PERSPECTIVE

world/area = /area/border // Keep things in the map system we define
area/border
	icon = 'test.dmi'
	icon_state = "areaDefault"
	Enter(interface/entrant)
		if(!istype(entrant)) return
		. = ..()


//-- Useful client wrapper for testing -----------------------------------------

client/verb/reboot()
	system.restart()
client/verb/forceReboot()
	system.restartWithoutSave()
client/New()
	. = ..()
	spawn(10)
		world.SetMedal("Logged into the fucking game hell yeah", src)
