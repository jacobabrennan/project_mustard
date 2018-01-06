

//------------------------------------------------------------------------------

building
	//parent_type = /obj
	//density = TRUE
	//icon = 'house.dmi'
	//icon_state = "house3"
	//bound_width = 64
	//bound_height = 80
	//pixel_y = -8
	var
		icon
		list/parts[0]
		movement = MOVEMENT_WALL
		x
		y
		gridText
		coord/exitCoords
		test = FALSE
	toJSON()
		var/list/objectData = ..()
		objectData["x"] = x
		objectData["y"] = y
		return objectData
	fromJSON(list/objectData)
		. = ..()
		x = objectData["x"]
		y = objectData["y"]
	proc/build(_x, _y, plot/_plot)
		if(_plot.building && _plot.building != src)
			return FALSE
		var/success = place(_x, _y, _plot)
		if(gridText)
			// Change Interior
			var /game/G = system.getGame(_plot.gameId)
			var /region/interior = G.getRegion(INTERIOR)
			for(var/posY = 1 to PLOT_SIZE)
				for(var/posX = 1 to PLOT_SIZE)
					var/fullX = (_plot.x-1)*PLOT_SIZE + posX
					var/fullY = (_plot.y-1)*PLOT_SIZE + posY
					var/compoundIndex = ((PLOT_SIZE-1)-(posY-1))*PLOT_SIZE + posX
					var/tileChar = copytext(gridText, compoundIndex, compoundIndex+1)
					interior.changeTileAt(fullX, fullY, interior.char2Type(tileChar))
			interior.revealPlot(_plot.x, _plot.y)
		return success
	proc
		place(_x, _y, plot/_plot)
			x = _x
			y = _y
			var/success = TRUE
			var /game/G = system.getGame(_plot.gameId)
			var/region/parentRegion = G.getRegion(_plot.regionId)
			for(var/building/part/P in parts)
				var/fullX = P.offsetX + x
				var/fullY = P.offsetY + y
				if(!P.Move(locate(fullX, fullY, parentRegion.zLevel)))
					success = FALSE
					unplace(_plot)
					return FALSE
			_plot.building = src
			ASSERT(success)
			test = TRUE
			return success
		unplace(plot/_plot)
			x = null
			y = null
			for(var/building/part/P in parts)
				P.forceLoc(null)
	proc/setPart(_x, _y, _state, _dense, _layer)
		var/building/part/P = new(src)
		P.offsetX = _x
		P.offsetY = _y
		P.icon = icon
		P.icon_state = _state
		if(_dense == 0) P.density = _dense
		else P.density = 1
		if(!isnull(_layer)) P.layer += _layer
		parts.Add(P)
		return P

	part
		parent_type = /obj
		movement = MOVEMENT_FLOOR
		var
			offsetX = 0
			offsetY = 0
			building/building
			warp = FALSE
		New(building/parent)
			building = parent
		Cross(var/atom/movable/M)
			if(warp && istype(M, /character))
				var /plot/plotArea/PA = aloc(src)
				var /plot/oldPlot = PA.plot
				var /game/G = system.getGame(oldPlot.gameId)
				var/character/C = M
				var/plot/_plot
				var/region/warpRegion = G.getRegion(warp)
				if(warp == INTERIOR)
					var /region/interior = G.getRegion(INTERIOR)
					_plot = interior.getPlot(oldPlot.x, oldPlot.y)
				else
					if(!warpRegion || !warpRegion.startPlotCoords) {world << "ASDF"; return}
					_plot = warpRegion.getPlot(warpRegion.startPlotCoords.x, warpRegion.startPlotCoords.y)
				_plot.reveal()
				var/fullX = (_plot.x-1)*PLOT_SIZE + (1+round(PLOT_SIZE/2))
				var/fullY = (_plot.y-1)*PLOT_SIZE + 3
				C.transition(_plot, locate(fullX, fullY, warpRegion.zLevel))
			if(density)
				if(M.movement & building.movement) return ..()
				return FALSE
			return TRUE


//------------------------------------------------------------------------------

building/dungeon
	icon = 'house_parts.dmi'
	var
		dungeonId
		building/part/door
	New()
		. = ..()
		setPart(0,0,"1",0)
		setPart(1,0,"0",0)
		exitCoords = new(0,1)
		door = setPart(0,1,"2",0)
		setPart(1,1,"3")
		setPart(0,2,"4")
		setPart(1,2,"5")
		setPart(0,3,"6")
		setPart(1,3,"7")
		setPart(0,4,"10",0,2)
		setPart(1,4,"11",0,2)
	toJSON()
		var/list/dataObject = ..()
		dataObject["dungeonId"] = dungeonId
		return dataObject
	fromJSON(list/dataObject)
		. = ..()
		dungeonId = dataObject["dungeonId"]
		door.warp = dungeonId
	place(_x, _y, plot/_plot)
		var /game/G = system.getGame(_plot.gameId)
		var/region/parentRegion = G.getRegion(_plot.regionId)
		var/plot/plotArea/PA = _plot.area
		_x = PA.x + 7
		_y = PA.y + 8
		for(var/posY = 2 to PLOT_SIZE-1)
			var/fullY = PA.y-1 + posY
			for(var/posX = 2 to PLOT_SIZE-1)
				var/fullX = PA.x-1 + posX
				parentRegion.createTileAt(fullX, fullY, /tile/land)
		var/success = ..()
		ASSERT(success)
		return success
	unplace(plot/_plot)
		var/placed = parts.len
		var/plot/plotArea/PA
		if(placed)
			PA = aloc(parts[1])
		. = ..()
		if(!placed || !istype(PA)) return
		var/plot/P = PA.plot
		var /game/G = system.getGame(P.gameId)
		var/region/parentRegion = G.getRegion(P.regionId)
		for(var/posY = 2 to PLOT_SIZE-1)
			var/fullY = PA.y-1 + posY
			for(var/posX = 2 to PLOT_SIZE-1)
				var/fullX = PA.x-1 + posX
				parentRegion.revealTileAt(fullX, fullY)
	build(_x, _y, plot/_plot)
		var/success = ..()
		if(!success) return
		dungeonId = "dungeon([_plot.x],[_plot.y])"
		door.warp = dungeonId
		// Generate New Dungeon
		var/dungeon/D = new()
		var/region/newR = D.generate(7,7,dungeonId)
		newR.entrance = new(_plot.x, _plot.y)
		for(var/plot/P in newR.plots)
			P.reveal()
		return success
building/house1
	icon = 'house_parts.dmi'
	gridText = {"\
000000000000000\
003330033333000\
002b2002bbb2700\
001a1761aaa1200\
00...22.....500\
00...54......00\
00...........00\
000333.......00\
006222.......00\
002111.......00\
004..........00\
00...........00\
008.........900\
0000008c9000000\
000000000000000"}
	New()
		setPart(0,0,"1",0)
		setPart(1,0,"0",0)
		exitCoords = new(0,1)
		var/building/part/door = setPart(0,1,"2",0)
		setPart(1,1,"3")
		setPart(0,2,"4")
		setPart(1,2,"5")
		setPart(0,3,"6")
		setPart(1,3,"7")
		setPart(0,4,"10",0,2)
		setPart(1,4,"11",0,2)
		door.warp = INTERIOR
	build(_x, _y, plot/_plot)
		. = ..()
		var /game/G = system.getGame(_plot.gameId)
		var /region/interior = G.getRegion(INTERIOR)
		var/furniture/bed/B = new()
		B.forceLoc(locate(_plot.area.x+2, _plot.area.y+10, interior.zLevel))
building/inn
	icon = 'house_parts.dmi'
	gridText = {"\
000000000000000\
003333333333300\
062bbb222bbb270\
021aaa111aaa120\
04...........50\
0.............0\
0.............0\
0.............0\
0.............0\
0.............0\
0.............0\
0.............0\
08...98.98...90\
0000000c0000000\
000000000000000"}
	New()
		exitCoords = new(2,1)
		setPart(0,0,"0",0)
		setPart(1,0,"0",0)
		setPart(2,0,"1",0)
		setPart(3,0,"0",0)
		setPart(4,0,"0",0)
		setPart(0,1,"3")
		setPart(1,1,"3")
		var/building/part/door = setPart(2,1,"2")
		setPart(3,1,"3")
		setPart(4,1,"3")
		setPart(0,2,"3")
		setPart(1,2,"3")
		setPart(2,2,"inn")
		setPart(3,2,"3")
		setPart(4,2,"3")
		setPart(0,3,"4")
		setPart(1,3,"5")
		setPart(2,3,"12")
		setPart(3,3,"4")
		setPart(4,3,"5")
		setPart(0,4,"6")
		setPart(1,4,"9")
		setPart(2,4,"12")
		setPart(3,4,"8")
		setPart(4,4,"7")
		setPart(0,5,"10",0,2)
		setPart(1,5,"11",0,2)
		//setPart(2,5,"")
		setPart(3,5,"10",0,2)
		setPart(4,5,"11",0,2)
		door.warp = INTERIOR
	build(_x, _y, plot/_plot)
		var/success = ..()
		if(!success) return
		var /game/G = system.getGame(_plot.gameId)
		var /region/interior = G.getRegion(INTERIOR)
		var/plot/interiorPlot = interior.getPlot(_plot.x, _plot.y)
		var/furniture/innNPC/NPC = new()
		var/plot/plotArea/plotArea = interiorPlot.area
		NPC.forceLoc(locate(plotArea.x+7, plotArea.y+10, plotArea.z))
		return success