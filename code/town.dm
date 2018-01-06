

//------------------------------------------------------------------------------

character/DblClick()
	new /tempClickHandler(loc, usr.client)
tempClickHandler
	parent_type = /datum
	New(tile/loc, client/client)
		var /interface/rpg/rInt = client.interface
		rInt.unload()
		var /interface/town/tInt = new(client)
		tInt.forceLoc(loc)


//

var/region/town/town
var/region/interior
region/town
	parent_type = /region
	//
	var
		buildPoints = 100000
	toJSON()
		var/list/townData = ..()
		townData["buildPoints"] = buildPoints
		return townData
	fromJSON(list/objectData)
		. = ..()
		buildPoints = objectData["buildPoints"]
	//---- Region Management --------------------------------------------------
	New()
		town = src
		. = ..()
	/*proc/saveWorld()
		for(var/regionId in regions)
			var/region/R = regions[regionId]
			R.save()*/
	//-------------------------------------------------------------------------
	buildTile(interface/player, tileType, x, y)
		var/plot/buildPlot = getPlotAt(x, y)
		var/region/parentRegion = getRegion(buildPlot.regionId)
		var/tile/T = tileType
		if(initial(T:buildPoints) > buildPoints)
			return FALSE
		if(!buildPlot.buildAllow(player, tileType, x, y))
			return FALSE
		var /tile/buildTurf = locate(x, y, player.z)
		if(!(istype(buildTurf) && buildTurf.buildAllow(player, tileType)))
			return FALSE
		var borderX
		var borderY
		if(x%PLOT_SIZE == 1 && x > 1) // west border
			borderX = x-1
			borderY = y
		if(x%PLOT_SIZE == 0 && x < width) // east border
			borderX = x+1
			borderY = y
		if(y%PLOT_SIZE == 1 && y > 1) // south border
			borderX = x
			borderY = y-1
		if(y%PLOT_SIZE == 0 && y < height) // south border
			borderX = x
			borderY = y+1
		if(borderX && borderY)
			var/plot/borderPlot = getPlotAt(borderX, borderY)
			if(!borderPlot || !borderPlot.revealed) return FALSE
		var/plot/containingPlot = getPlotAt(x, y)
		if(!containingPlot || !containingPlot.revealed)
			return FALSE
		parentRegion.changeTileAt(x, y, tileType)
		buildPoints -= initial(T:buildPoints)
	proc/buildPlot(plot/plot) // Called when the player wants to reveal a new plot
		if(!plot) return FALSE
		var/blocked = TRUE
		/*
		for(var/posY = -1 to 1)
			for(var/posX = -1 to 1)
				if(abs(posY) + abs(posX) != 1) continue
				var/plot/testPlot = getPlot(plot.x+posX, plot.y+posY)
				if(!testPlot || !testPlot.revealed) continue
				var/building/dungeon/D = testPlot.building
				if(!istype(D))
					blocked = FALSE
					break
		if(blocked){ world<< "blocked"; return FALSE}*/
		plot.reveal()
		var/building/dungeon/D = new()
		D.build(null, null, plot)
		return blocked
	proc/generateOverworld(genWidth, genHeight, defaultTerrain)
		world << "Town Generating"
		// Setup Plots
		setSize(genWidth, genHeight)
		// Generate elevation / regions / water
		var /plasmaGenerator/generator = new()
		var/list/plasmaData = generator.init()
		startPlotCoords = plasmaData["home"]
		//tileGrid = plasmaData["grid"] Elevation Map
		gridText = plasmaData["maze"]
		var/list/nodes = plasmaData["plots"]
		// Set Plot Terrain
		for(var/I = 1 to nodes.len)
			var/plasmaGenerator/closedNode/N = nodes[I]
			var/plot/P = plots[I]
			P.terrain = N.region
		// Reveal Start Area
		var cX = startPlotCoords.x
		var cY = startPlotCoords.y
		revealPlot(cX  ,cY  )
		revealPlot(cX+1,cY  )
		revealPlot(cX+1,cY+1)
		revealPlot(cX  ,cY+1)
		revealPlot(cX-1,cY+1)
		revealPlot(cX-1,cY  )
		revealPlot(cX-1,cY-1)
		revealPlot(cX  ,cY-1)
		revealPlot(cX+1,cY-1)
		// Build Start Plot
		var/plot/startPlot = getPlot(cX, cY)
		var/plot/plotArea/PA = startPlot.area
		var/building/inn/startInn = new()
			// Try to place Inn without changing anything
		var/success = startInn.build(PA.x+5, PA.y+7, startPlot)
			// Try to place Inn without changing water
		if(!success)
			diag("Changing trees to land")
			for(var/posY = 2 to PLOT_SIZE-3)
				for(var/posX = 2 to PLOT_SIZE-3)
					ASSERT(\
						ispath(\
							tileTypeAt(PA.x+posX, PA.y+posY),\
							/tile\
						)\
					)
					if(!ispath(tileTypeAt(PA.x+posX, PA.y+posY), /tile/water))
						changeTileAt(PA.x+posX, PA.y+posY, /tile/land)
					else
			success = startInn.build(PA.x+5, PA.y+7, startPlot)
			// Force placement of Inn
		if(!success)
			diag("Changing water to land")
			for(var/posY = 2 to PLOT_SIZE-3)
				for(var/posX = 2 to PLOT_SIZE-3)
					if(ispath(tileTypeAt(PA.x+posX, PA.y+posY), /tile/water))
						changeTileAt(PA.x+posX, PA.y+posY, /tile/land)
			success = startInn.build(PA.x+5, PA.y+7, startPlot)
		ASSERT(success)
		loaded = TRUE


//=============================================================================================


interface/town
	var
		interface/town/eye/eye
		interface/town/menu/menu
	// eye
	density = FALSE
	movement = MOVEMENT_ALL
	step_size = 8
	icon = 'test.dmi'
	icon_state = "eye"
	Move()
		var/area/oldArea = aloc(src)
		. = ..()
		var/plot/plotArea/newArea = aloc(src)
		if(istype(newArea) && oldArea != newArea)
			if(istype(newArea)) menu.refreshTiles(newArea.plot)
			else menu.refreshTiles()
	//
	New()
		. = ..()
		while(src)
			sleep(TICK_DELAY)
			control()
	Del()
		del menu
		. = ..()
	Login()
		. = ..()
		client.eye = src
		menu = client.menu.addComponent(/interface/town/menu)
		menu.setup()
		client.menu.focus(menu)
		forceLoc(locate(
			round((town.startPlotCoords.x+0.5)*PLOT_SIZE),
			round((town.startPlotCoords.y+0.5)*PLOT_SIZE),
			town.zLevel
		))
	disconnect(client/oldClient)
		menu.hide(oldClient)
		. = ..()
	click(object, location, control, params)
		. = ..()
		menu.click(object, location, control, params)
	//---- Control --------------------------------------------------
	var/commandsDown = 0
	proc/checkCommands()
		return client.macros.commands | commandsDown
	proc/control()
		var/command = checkCommands()
		if(command < 16)
			step(src, command)
		commandsDown = 0
	commandDown(command)
		commandsDown |= command
		if(command & STATUS)
			client.eye = new /interface/clay(client)
//================================================================
interface/town/menu/tileSelector
	parent_type = /usable
	var
		tileType
	New()
		. = ..()
		icon_state = initial(tileType:icon_state)
interface/town/menu/furnSelector
	parent_type = /usable
	var
		furnType
	New()
		. = ..()
		icon_state = initial(furnType:thumbnailState)
		icon = initial(furnType:icon)
interface/town/menu // Menu System
	parent_type = /component
	var
		image/plotBorder
		component/box/tiles
		component/box/furniture
		list/tileTypes = newlist(
			/interface/town/menu/tileSelector{ tileType = /tile/land},
			/interface/town/menu/tileSelector{ tileType = /tile/wall},
			/interface/town/menu/tileSelector{ tileType = /tile/feature},
			/interface/town/menu/tileSelector{ tileType = /tile/interact},
			/interface/town/menu/tileSelector{ tileType = /tile/water}
		)
	setup()
		tiles = addComponent(/component/box)
		tiles.setup(100, 64, 5, 1)
		tiles.chrome()
		tiles.refresh(tileTypes)
		furniture = addComponent(/component/box)
		furniture.setup(16, 13*TILE_SIZE, 2, 1)
		furniture.chrome()
		furniture.refresh(newlist(
			/interface/town/menu/furnSelector{ furnType = /furniture/deleter},
			/interface/town/menu/furnSelector{ furnType = /furniture/tree}
		))
	//
	show()
		. = ..()
		plotBorder = image('plot_border.png')
		plotBorder.pixel_x = -2
		plotBorder.pixel_y = -2
		client << plotBorder
		tiles.positionCursor()
		spawn()
			var/plot/plotArea/refreshArea = aloc(client.interface)
			if(istype(refreshArea))
				refreshTiles(refreshArea.plot)
	hide()
		. = ..()
		del plotBorder
	proc/click(object, location, control, params)
		// Handle Selecting Prototypes
		var /component/slot/clickSlot = object
		if(istype(clickSlot))
			selectTile(clickSlot)
			return
		// Handle Building Things
		var /tile/clickTile = object
		if(istype(clickTile))
			var/plot/plotArea/clickArea = aloc(clickTile.loc)
			if(!istype(clickArea)) return
			var /region/parentRegion = town.getRegion(clickArea.plot.regionId)
			// Handle Building Tiles
			if(tiles.position)
				var /interface/town/menu/tileSelector/selector = tiles.select()
				parentRegion.buildTile(usr.client.interface, selector.tileType, clickTile.x, clickTile.y)
				return
			// Handle Building Furniture
			if(furniture.position)
				var /furniture/F = locate() in clickTile
				del F
				var /interface/town/menu/furnSelector/selector = furniture.select()
				F = new selector.furnType()
				F.forceLoc(clickTile)
				return
		// Handle Revealing Plots
		var /world/border/borderTurf = object
		if(istype(borderTurf))
			var/plot/P = town.getPlotAt(borderTurf.x, borderTurf.y)
			return town.buildPlot(P)
	//
	proc/refreshTiles(plot/newPlot)
		var plot/plotArea/paletteArea = newPlot.area
		plotBorder.loc = locate(paletteArea.x, paletteArea.y, paletteArea.z)
		for(var/I = 1 to 5)
			var /component/slot/S = tiles.slots[I]
			var /interface/town/menu/tileSelector/selector = S.usable
			selector.icon = paletteArea.icon
			S.imprint(selector)
	proc/selectTile(component/slot/selectorSlot)
		// Handle Tile Selector
		var index = tiles.slots.Find(selectorSlot)
		if(index)
			furniture.position = 0
			furniture.cursor.hide()
			tiles.position = index
			tiles.positionCursor()
			tiles.cursor.show()
			return
		// Handle Furniture Selector
		index = furniture.slots.Find(selectorSlot)
		if(index)
			tiles.position = 0
			tiles.cursor.hide()
			furniture.position = index
			furniture.positionCursor()
			furniture.cursor.show()



var/matrix/identity = matrix()

character
	New()
		. = ..()
		var /mirror/M = new()
		M.imprint(src)

mirror
	parent_type = /event
	step_size = 1
	icon = 'desert.dmi'
	icon_state = "wall"
	layer = OBJ_LAYER
	var
		angle = 180
		list/blits[0]
		lightSource/light
		lightSpeed = 0
	proc/imprint(character/C)
		spawn(1)
			loc = C.loc
		/*var /mirror/blit/B = new()
		blits.Add(B)
		B.imprint(C)*/
		light = new()
		light.setState(0.5, "#ff0", 64)
	takeTurn()
		. = ..()
		//angle++
		//step_rand(src,0)
		//transform = turn(identity, -angle)
		//for(var/mirror/blit/B in blits)
		//	B.update(src)
		//transform = identity
		light.centerLoc(src)
		//light.step_x = step_x
		//light.step_y = step_y


mirror/blit
	parent_type = /mob
	var
		character/source
	proc/imprint(character/C)
		source = C
	proc/update(mirror/M)
		appearance = source.appearance
		dir = source.dir
		loc = M.loc
		transform = M.transform

		var deltaX = (source.x - M.x) * TILE_SIZE + (source.step_x - M.step_x)
		var deltaY = (source.y - M.y) * TILE_SIZE + (source.step_y - M.step_y)

		var rotateX = deltaX*cos(M.angle) - deltaY*sin(M.angle)
		var rotateY = deltaY*cos(M.angle) + deltaX*sin(M.angle)

		step_x = rotateX + M.step_x
		step_y = rotateY + M.step_y