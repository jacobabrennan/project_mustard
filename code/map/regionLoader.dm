

//------------------------------------------------------------------------------

system
	var
		system/map/map
	proc
		setupMap()
			map = new()
			map.loadRegions()


//------------------------------------------------------------------------------

system/map
	parent_type = /datum
	var
		list/gridData = new()
		list/regionTemplates = new()
	proc
		loadRegion(regionId)
			// Load Region Data from file
			var/filePath = "[FILE_PATH_REGIONS]/[regionId].json"
			ASSERT(fexists(filePath))
			var/list/regionData = json_decode(file2text(filePath))
			// Setup stringGrid
			var gridText = regionData["gridText"]
			//var tileWidth  = regionData["width" ] * PLOT_SIZE
			//var tileHeight = regionData["height"] * PLOT_SIZE
			var /stringGrid/largeString = json2Object(gridText)//new(tileWidth, tileHeight, gridText)
			// Store Data
			regionTemplates[regionId] = regionData
			gridData[regionId] = largeString
			regionData["gridText"] = null
		loadRegions()
			var /list/regionIds = list(
				REGION_OVERWORLD
			)
			for(var/regionId in regionIds)
				loadRegion(regionId)
	proc
		getChar(regionId, posX, posY)
			var /stringGrid/largeString = gridData[regionId]
			return largeString.get(posX, posY)
		putChar(regionId, posX, posY, char)
			var /stringGrid/largeString = gridData[regionId]
			return largeString.put(posX, posY, char)