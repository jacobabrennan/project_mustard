

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
	proc/loadRegion(regionId)
		// Load Region Data from file
		var/filePath = "[FILE_PATH_REGIONS]/[regionId].json"
		ASSERT(fexists(filePath))
		var/list/regionData = json_decode(file2text(filePath))
		// Store Data
		regionTemplates[regionId] = regionData
		gridData[regionId] = regionData["gridText"]
		regionData["gridText"] = null
	proc/loadRegions()
		var /list/regionIds = list(
			REGION_OVERWORLD
		)
		for(var/regionId in regionIds)
			loadRegion(regionId)