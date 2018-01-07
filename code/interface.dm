

//-- Handle Players Entering the Server ----------------------------------------

world/mob = /interface/clay
interface/clay // Player that has just connected
	New()
		. = ..()
		spawn(1)
			system.registerPlayer(client)



//-------------------------------------------------------------------------

client
	perspective = EYE_PERSPECTIVE
	var/interface/interface
	Del()
		if(interface)
			interface.disconnect(src) // Necessary because client/key info not available in Logout
		. = ..()

interface
	parent_type = /mob
	transitionable = TRUE // Can move between plots
	icon = null
	icon_state = null
	// Connection
	New(client/_client) // don't do the default action: place interface inside of first argument
		if(_client) client = _client
	Login() // don't do the default action: place interface at (1,1,1
		if(lagoutTimer) del lagoutTimer
		if(client.interface)
			client.interface.disconnect(client)
		client.interface = src
	proc/disconnect(client/oldClient) // Necessary because client/key info not available in Logout
		// Called when:
		//	A client is deleted while still having an interface (player left server)
		//	A client logs into another interface while still owning this one (should never happen)
	proc/click(object, location, control, params){}
	// Lagout Timer
	var/interface/lagoutTimer/lagoutTimer
	Logout()
		del lagoutTimer
		if(key)
			lagoutTimer = new(src)
		else
			del src
	lagoutTimer
		parent_type = /datum
		New(interface/lagInt)
			spawn (TIME_LAG_DISCONNECT)
				if(lagInt.lagoutTimer == src)
					del lagInt

interface/holding // A way to contain the player while the world does what it needs to


//=====================================================================


interface/rpg
	var
		character/character
		event/transition/transitionEvent
		commandsDown = 0
			// Logs commands pressed between calls to control()
		terrain/currentTerrain
	New(client/newClient, character/oldCharacter)
		if(oldCharacter) character = oldCharacter
		. = ..()
	proc/unload() // When the player leaves this interface normally. May still be in the game.
		//character.unload()
	Login()
		. = ..()
		client.eye = src
		if(!character)
			var /character/newCharacter = new()
			character = newCharacter
			character.interface = src
			//character.load(client.ckey) // load comes after character.interface = src
			character.owner = client.ckey
		else
			character.interface = src
			var /plot/currentPlot = plot(character)
			if(currentPlot)
				transition(currentPlot)
		client.menu.hud.show(src)
		client.menu.refresh("inventory", character.inventory)
		client.menu.refresh("equipment", character.equipment)
	//
	proc/checkCommands()
		return client.macros.commands | commandsDown
	proc/control(character/_character)
		if(!client) return
		var/block = client.menu.control(_character)
		if(block)
			commandsDown = 0
			return
		if(commandsDown & PRIMARY)
			var/item/weapon/W = _character.equipment[WEAR_WEAPON]
			if(W) character.use(W)
		else if(commandsDown & SECONDARY)
			var/usable/U = client.menu.status.getHotKey(SECONDARY)
			if(U) _character.use(U)
		else if(commandsDown & TERTIARY)
			var/usable/U = client.menu.status.getHotKey(TERTIARY)
			if(U) _character.use(U)
		else if(commandsDown & QUATERNARY)
			var/usable/U = client.menu.status.getHotKey(QUATERNARY)
			if(U) _character.use(U)
		var/directions = client.macros.checkCommand(15)
		var/deltaX = 0
		var/deltaY = 0
		if(directions & NORTH) deltaY++
		if(directions & SOUTH) deltaY--
		if(directions &  EAST) deltaX++
		if(directions &  WEST) deltaX--
		if(deltaX || deltaY)
			var/speed = _character.speed()
			_character.go(deltaX*speed, deltaY*speed)
		commandsDown = 0
	commandDown(command)
		var/block = client.menu.commandDown(command)
		if(block) return
		commandsDown |= command
	//
	icon = 'specials.dmi'
	icon_state = "eye"
	proc/transition(plot/newPlot)
		ASSERT(istype(newPlot))
		var /terrain/oldTerrain = currentTerrain
		currentTerrain = terrains[newPlot.terrain]
		// Display Transition Dialogue
		if(oldTerrain && currentTerrain.name && oldTerrain.name != currentTerrain.name)
			client.menu.transition(currentTerrain.name)
		//
		var/plot/plotArea/newArea = newPlot.area
		if(istype(newArea))
			// Calculate translation distance (in atomic steps)
			var /plot/currentPlot = plot(src)
			var plotDist
			if(loc && currentPlot)
				plotDist = max(
					abs(newPlot.area.x-currentPlot.area.x),
					abs(newPlot.area.y-currentPlot.area.y)
				)
			// Don't slide across entire map
			if(!loc || newArea.z != z || plotDist > PLOT_SIZE)
				forceLoc(locate(
					newArea.x + round(PLOT_SIZE/2),
					newArea.y + round(PLOT_SIZE/2),
					newArea.z
				))
			// Slide between adjacent plots
			else
				new /event/transition(src, newPlot)
		// Change Lighting
		transitionLight(newPlot)
	proc/transitionLight(plot/newPlot)
		//var newLight = environment.getLight(newPlot)
		//client.setLight(newLight)
	proc/refresh(which, data)
		if(!client) return
		client.menu.refresh(which, data)