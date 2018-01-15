

//-- Quest Management System ---------------------------------------------------

/*
	The /quest object is instanced by each game to track the progress of the
	player through the game quest. Examples of tracked values are chests opened
	or bosses killed.
*/


//-- Saving & Loading ----------------------------------------------------------

quest
	toJSON()
		var /list/objectData = ..()
		objectData["data"] = list2JSON(data)
	fromJSON(list/objectData)
		data = json2Object(objectData["data"]) // Confusing, eh?


//-- Checking & Setting --------------------------------------------------------

	var
		list/data = new()
	proc
		get(key)
			return data[key]
		put(key, value)
			data[key] = value