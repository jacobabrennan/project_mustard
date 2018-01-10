

//-- Weather -------------------------------------------------------------------

terrain
	wind
		parent_type = /projectile
		icon = null
		//icon_state = "cloud"
		baseSpeed = 4
		persistent = TRUE
		movement = MOVEMENT_ALL
		potency = 0
		faction = FACTION_PACIFY
		interactionProperties = INTERACTION_WIND
		alpha = 64
		bound_width = TILE_SIZE
		bound_height = TILE_SIZE
		var
			bearing
			magnitude
			plot/plotArea/homeArea
		forceLoc(newLoc)
			loc = newLoc
			// Problems with infinite loops and Del otherwise
		Move(newLoc)
			. = ..()
			if(!.) del src
			if(!homeArea)
				homeArea = aloc(loc)
			else if(homeArea != aloc(newLoc))
				del src
		proc/windDelay(X, Y)
			var delay
			var radius = TILE_SIZE*PLOT_SIZE/baseSpeed
			switch(bearing)
				if(  0 to  45) delay = -cot(bearing+90)*radius*(           Y /PLOT_SIZE)
				if( 45 to  90) delay = -tan(bearing-90)*radius*(           X /PLOT_SIZE)
				if( 90 to 135) delay =  tan(bearing+90)*radius*((PLOT_SIZE-X)/PLOT_SIZE)
				if(135 to 180) delay =  cot(bearing-90)*radius*(           Y /PLOT_SIZE)
				// This took sooooo long
				if(180 to 225) delay = -cot(bearing+90)*radius*((PLOT_SIZE-Y)/PLOT_SIZE)
				if(225 to 270) delay = -tan(bearing-90)*radius*((PLOT_SIZE-X)/PLOT_SIZE)
				if(270 to 315) delay =  tan(bearing+90)*radius*(           X /PLOT_SIZE)
				if(315 to 360) delay =  cot(bearing-90)*radius*((PLOT_SIZE-Y)/PLOT_SIZE)
			delay = round(delay)
			return delay

	//
	proc/updateWeather(plot/P)
		// Update Precipitation
		if(!P.precipitationDisplay1) P.precipitationDisplay1 = new()
		if(!P.precipitationDisplay2) P.precipitationDisplay2 = new()
		var waterContentClouds = environment.getPrecipitation(P)
		var/plot/precipitationDisplay/D1 =  P.precipitationDisplay1
		var/plot/precipitationDisplay/D2 =  P.precipitationDisplay2
		P.area.overlays.Remove(D1)
		P.area.overlays.Remove(D2)
		if(waterContentClouds >= 2)
			D1.alpha = min(1, waterContentClouds-2)*255
			D2.alpha = min(1, waterContentClouds-2)*255/2
			if(environment.getTemperature(P) > 32)
				D1.icon_state = "rain2"
				switch(waterContentClouds)
					if(  0 to 3) D1.icon_state = "rain1"
					if(3 to 100) D1.icon_state = "rain2"
					//if(  4 to 100) D.icon_state = "rain2"
			else
				D1.icon_state = "snow1"
				D1.alpha = 255
			D2.icon_state = D1.icon_state
			var /vector/wind = environment.getWind(P)
			var shear = cos(wind.dir)*wind.mag
			D1.transform = matrix(1,-shear/5,0, 0,1,0)
			D2.transform = matrix(1,-shear/10,0, 0,1,0)
			D2.layer = D1.layer - 1
			D2.pixel_x = D1.pixel_y+3
			D2.pixel_y = D1.pixel_x+1
			P.area.overlays.Add(D1, D2)


	proc/plotWeather(plot/P)
		// Generate Wind
		var /vector/windVector = environment.getWind(P)
		var/terrain/wind/W = new()
		W.bearing = windVector.dir
		W.magnitude = windVector.mag
		if(W.magnitude >= 1) // Skip creating wind if it's calm
			W.baseSpeed = max(8, min(16, 4*max(1,windVector.mag)))
			var/plot/plotArea/A = P.area
			switch(W.bearing)
				if(315 to 360, 0 to 45)
					W.dir = EAST
					W.baseSpeed *= abs(cos(W.bearing))
					W.loc = locate(A.x, A.y, A.z)
					W.bound_height = TILE_SIZE*PLOT_SIZE
				if( 45 to 135)
					W.dir = NORTH
					W.baseSpeed *= abs(sin(W.bearing))
					W.loc = locate(A.x, A.y, A.z)
					W.bound_width = TILE_SIZE*PLOT_SIZE
				if(135 to 225)
					W.dir = WEST
					W.baseSpeed *= abs(cos(W.bearing))
					W.loc = locate(A.x+(PLOT_SIZE-1), A.y, A.z)
					W.bound_height = TILE_SIZE*PLOT_SIZE
				if(225 to 315)
					W.dir = SOUTH
					W.baseSpeed *= abs(sin(W.bearing))
					W.loc = locate(A.x, (A.y+PLOT_SIZE-1), A.z)
					W.bound_width = TILE_SIZE*PLOT_SIZE
			W.project()
		//
		//W.transform = matrix(W.bound_width/TILE_SIZE,0,W.bound_width/2, 0,W.bound_height/TILE_SIZE,W.bound_height/2)
		//
		var gusty = 4*rand(0,W.magnitude)
		return 10 - gusty


//------------------------------------------------------------------------------

plot
	var
		plot/precipitationDisplay/precipitationDisplay1
		plot/precipitationDisplay/precipitationDisplay2
	deactivate()
		area.overlays.Remove(precipitationDisplay1)
		area.overlays.Remove(precipitationDisplay2)
		del precipitationDisplay1
		del precipitationDisplay2
		. = ..()
	proc/updateWeather()
		var /terrain/ownTerrain = terrains[terrain]
		ownTerrain.updateWeather(src)
	//-------------------------------
	precipitationDisplay
		parent_type = /obj
		icon = 'rain.dmi'
		plane = PLANE_WEATHER
		pixel_y = -8
		icon_state = "clear"