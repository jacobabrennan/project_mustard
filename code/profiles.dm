

//------------------------------------------------------------------------------

var/profileManager/profileManager = new()
profileManager
	proc/getProfile(key)
		key = ckey(key)
		var/profileManager/profile/P = new(key)
		return P
client
	var/profileManager/profile/profile
	New()
		. = ..()
		profile = new(key)
profileManager/profile
	/*
	Represents a player's status in the game
	including permissions and character save data,
	but excluding the character object
	*/
	var
		key
	New(_key)
		key = ckey(_key)
		load()
	proc/load()
		var/filePath = "[FILE_PATH_PROFILES]/[key].json"
		if(!fexists(filePath))
			return
		var/fileText = file2text(filePath)
		world << "[filePath]: [fileText]"
	proc/save()
		var/filePath = "[FILE_PATH_PROFILES]/[key].json"
		if(fexists(filePath)) fdel(filePath)
		var/jsonObject = list()
		jsonObject["key"] = key