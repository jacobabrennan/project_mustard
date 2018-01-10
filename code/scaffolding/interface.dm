

//-- Interface - Persistent connection between players and clients --------

interface
	parent_type = /mob
	transitionable = TRUE // Can move between plots

	//- Connection -----------------------------------
	New(client/_client)
		// don't do the default action: place interface inside of first argument
		if(_client) client = _client
	Login()
		// don't do the default action: place interface at locate(1,1,1)
		if(lagoutTimer) del lagoutTimer
		if(client.interface)
			client.interface.disconnect(client)
		client.interface = src
	proc/disconnect(client/oldClient)
		// Necessary because client/key info not available in Logout
		// Called when:
		//	A client is deleted while still having an interface (player left server)
		//	A client logs into another interface while still owning this one (should never happen)

	//-- Invuluntary Disconnect Handling -------------
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


//-- Handle Players Entering the Server ----------------------------------------

client
	perspective = EYE_PERSPECTIVE
	var/interface/interface
	Del()
		// Necessary because client/key info not available in Logout
		if(interface)
			interface.disconnect(src)
		. = ..()

world/mob = /interface/clay
interface
	//-- Clay - Players that have just connected -----
	clay
	// Player that has just connected
		New()
			. = ..()
			spawn() // Necessary for reboots
				system.registerPlayer(client)
	//-- Holding - Contain player while preparing ----
	holding