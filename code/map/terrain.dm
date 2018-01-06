

//------------------------------------------------------------------------------

var/list/terrains
proc/setupTerrains()
	terrains = list()
	var/terrain/T
	for(var/type in typesof(/terrain))
		T = new type()
		if(T.id)
			terrains[T.id] = T
		else
			del T


//------------------------------------------------------------------------------

terrain
	var
		id
		name
		icon
		list/infantry[0]
		list/cavalry[0]
		list/officer[0]
	proc
		char2Type(tileChar)
			var/tileType
			switch(tileChar)
				if("~") tileType = /tile/water/ocean
				if(",") tileType = /tile/water
				if("%") tileType = /tile/feature
				if("&") tileType = /tile/interact
				if("#") tileType = /tile/wall
				if("."," ","+","'") tileType = /tile/land
				else
					tileType = /tile/water/ocean
					world << "Problem: [tileChar]"
			return tileType
		type2Char(tileType)
			var/tileChar
			switch(tileType)
				if(/tile/water/ocean) tileChar = "~"
				if(/tile/water) tileChar = ","
				if(/tile/feature) tileChar = "%"
				if(/tile/interact) tileChar = "&"
				if(/tile/wall) tileChar = "#"
				if(/tile/land) tileChar = "."
				else
					tileChar = "~"
					world << "Problem: [tileType]"
			return tileChar
		setupTileInteraction(tile/interact/theTile)
		triggerTileInteraction(tile/interact/theTile, atom/interactor, interactionFlags)