

//------------------------------------------------------------------------------

#define PLOT_W (PLOT_SIZE-1)
#define WORLD_W (PLOT_W*DEFAULT_PLOTS)
#define WORLD_SIZE (PLOT_SIZE*DEFAULT_PLOTS)
#define WATER_TABLE 0.19


//------------------------------------------------------------------------------

plasmaGenerator
	parent_type = /datum
	var
		width
		height
		list/grid
		count = 0
		list/plots
	//
	openNode
		parent_type = /datum
		var
			x
			y
		New(_x,_y)
			x = _x
			y = _y
		proc/test(list/plots, list/adjNodes)
			var exDir = pick("x","y")
			var exAmo = pick(-1,1)
			var offsetX = x
			var offsetY = y
			if(exDir == "x")
				offsetX += exAmo
			else
				offsetY += exAmo
			var compoundIndex = offsetX + (offsetY-1)*DEFAULT_PLOTS
			var /plasmaGenerator/closedNode/CN
			if(!(offsetX <= 0 || offsetX > DEFAULT_PLOTS || offsetY <= 0 || offsetY > DEFAULT_PLOTS))
				CN = plots[compoundIndex]
				if(!istype(CN))
					return
			else
				return
			close(plots, CN.region, adjNodes)
		proc/close(list/plots, newRegion, list/adjNodes)
			var compoundIndex = plots.Find(src)
			for(var/offsetX = -1 to 1)
				for(var/offsetY = -1 to 1)
					if(!((offsetX || offsetY) && !(offsetX && offsetY))) continue
					var posX = offsetX + x
					var posY = offsetY + y
					var cI = (posX) + ((posY)-1)*DEFAULT_PLOTS
					if(posX <= 0 || posX > DEFAULT_PLOTS || posY <= 0 || posY > DEFAULT_PLOTS) continue
					var /plasmaGenerator/openNode/ON = plots[cI]
					if(!istype(ON) || adjNodes.Find(ON)) continue
					adjNodes.Add(ON)
			plots[compoundIndex] = new /plasmaGenerator/closedNode(x,y,newRegion)
			adjNodes.Remove(src)
			del src
	closedNode
		parent_type = /datum
		var
			x
			y
			region
		New(_x,_y,_region)
			x = _x
			y = _y
			region = _region
	proc/placeRegions(coord/home)
		world << "Laying out regions"
		plots = new()
		plots.len = DEFAULT_PLOTS*DEFAULT_PLOTS
		var /list/adjNodes = list()
		var regionsNum = 10
		for(var/I = 1 to plots.len)
			var posX = 1+ (I-1)%DEFAULT_PLOTS
			var posY = 1+ round((I-1)/DEFAULT_PLOTS)
			plots[I] = new /plasmaGenerator/openNode(posX, posY)
		home.x = 1+ round(home.x/PLOT_SIZE)
		home.y = 1+ round(home.y/PLOT_SIZE)
		var compoundIndex = ((home.y-1)*DEFAULT_PLOTS) + home.x
		var /plasmaGenerator/openNode/homeNode = plots[compoundIndex]
		homeNode.close(plots, "forest", adjNodes)
		for(var/I = 1 to regionsNum)
			var region = pick("desert","swamp","ruins","forest")//,"forest","forest","forest","forest")
			var /plasmaGenerator/openNode/ON = pick(plots)
			if(!istype(ON))
				I--
				continue
			ON.close(plots, region, adjNodes)
		world << "populating regions"
		while(adjNodes.len)
			var /plasmaGenerator/openNode/N = pick(adjNodes)
			N.test(plots, adjNodes)
		ASSERT(adjNodes.len == 0)
	//
	proc/displace(num)
		//Randomly displaces color value for midpoint depending on size
		//of grid piece.
		var/max = num / (width + height) * 3
		return (rand() - 0.5) * max
	proc/draw_plasma(_width as num, _height as num)
		//This is something of a "helper function" to create an initial grid
		//before the recursive function is called.
		var/c1
		var/c2
		var/c3
		var/c4
		//Assign the four corners of the intial grid random color values
		//These will end up being the colors of the four corners of the applet.
		var/list/corners_1 = list(1, pick(1,rand(50,75)/100))
		var/list/corners_2 = list(0, pick(0,rand(25,50)/100))
		var/_override = FALSE
		switch(rand(1,6))
			if(1)
				world << "Horizontal (1)"
				c1 = pick(corners_1)
				corners_1.Remove(c1)
				c2 = pick(corners_1)
				c3 = pick(corners_2)
				corners_2.Remove(c3)
				c4 = pick(corners_2)
				_override = TRUE
			if(2)
				world << "Horizontal (2)"
				c1 = pick(corners_1)
				corners_1.Remove(c1)
				c2 = pick(corners_1)
				c3 = pick(corners_2)
				corners_2.Remove(c3)
				c4 = pick(corners_2)
				_override = FALSE
			if(3,4)
				world << "Vertical"
				c1 = pick(corners_1)
				corners_1.Remove(c1)
				c2 = pick(corners_2)
				corners_2.Remove(c2)
				c3 = pick(corners_2)
				c4 = pick(corners_1)
				_override = TRUE
			if(5)
				world << "Water"
				_override = FALSE
				var/list/_water = list(0.5,0.5,1,0,0.5,0.75,0.25)
				c1 = pick(_water)
				_water.Remove(c1)
				c2 = pick(_water)
				_water.Remove(c2)
				c3 = pick(_water)
				_water.Remove(c3)
				c4 = pick(_water)
			if(6)
				world << "Rand"
				_override = FALSE
				c1 = rand()//0.5
				c2 = rand()//0.5
				c3 = rand()//0.5
				c4 = rand()//0.5
		sleep(2)
		divide_grid(0, 0, _width , _height , c1, c2, c3, c4, override = _override)
	proc/divide_grid(x as num, y as num, _width as num, _height as num, c1 as num, c2 as num, c3 as num, c4 as num, override)
		if(rand()*10000 > 9999)
			sleep(0.1)
			world << ".\..."
		//This is the recursive function that implements the random midpoint
		//displacement algorithm.  It will call itself until the grid pieces
		//become smaller than one pixel.
		var/Edge1
		var/Edge2
		var/Edge3
		var/Edge4
		var/Middle
		var/new_width = _width / 2
		var/new_height = _height / 2
		if(_width > 1 || _height > 1)
			if(override)
				Middle = 0.5
			else
				Middle = (c1 + c2 + c3 + c4) / 4 + displace(new_width + new_height)	//Randomly displace the midpoint!
			Edge1 = (c1 + c2) / 2	//Calculate the edges by averaging the two corners of each edge.
			Edge2 = (c2 + c3) / 2
			Edge3 = (c3 + c4) / 2
			Edge4 = (c4 + c1) / 2
			//Make sure that the midpoint doesn't accidentally "randomly displaced" past the boundaries!
			if(Middle < 0)
				Middle = 0
			else if(Middle > 1.0)
				Middle = 1.0
			//Do the operation over again for each of the four new grids.
			divide_grid(x, y, new_width, new_height, c1, Edge1, Middle, Edge4)
			divide_grid(x + new_width, y, new_width, new_height, Edge1, c2, Edge2, Middle)
			divide_grid(x + new_width, y + new_height, new_width, new_height, Middle, Edge2, c3, Edge3)
			divide_grid(x, y + new_height, new_width, new_height, Edge4, Middle, Edge3, c4)
		else
			//This is the "base case," where each grid piece is less than the size of a pixel.
			//The four corners of the grid piece will be averaged and drawn as a single pixel.
			var/c = (c1 + c2 + c3 + c4) / 4
			var/compound_index = ((round(y))*width) + round(x)+1
			if(compound_index <= 0 || compound_index >= grid.len)
				world << "ERROR: [compound_index], ([round(x)],[round(y)])"
			else
				var/grid_value = grid[compound_index]
				if(grid_value){ return}
				count++
				grid[compound_index] = c
	proc/init(var/map/_map, _width=WORLD_W, _height=WORLD_W)
		var waterTable = WATER_TABLE
		width = min(_width, WORLD_W)
		height = min(_height, WORLD_W)
		//var/z_level = 1
		world << "Starting (init)"
		sleep(2)
		grid = new()
		grid.len = (width+1) * (height+1)
		world << "Drawing Plasma (init)"
		sleep(2)
		draw_plasma(width, height)	//Draw the first plasma fractal.
		world << "\nNormalizing Height Map (init)"
		sleep(2)
		count = 0
		var/home_y = width+height
		for(var/y_pos = 1 to height)
			for(var/x_pos = 1 to width)
				if(rand()*10000 > 9999)
					sleep(0.1)
					world << ".\..."
				//count++
				var/compound_index = ((y_pos-1)*width) + x_pos
				var/grid_value = grid[compound_index]
				grid_value = abs(grid_value - 0.5)*2
				grid[compound_index] = grid_value
				if(x_pos == round(width/2))
					if(grid_value-waterTable > 0.19 && grid_value-waterTable < 0.21)
						if(abs(y_pos-(height/2)) < abs(home_y-(height/2)))
							home_y = y_pos
		world << "\nDrawing to Turf Grid (init)"
		var/icon/icon_map = new('plasma.dmi')
		icon_map.Scale(min(width,WORLD_W), min(height,WORLD_W))
		world << "\nPlacing Town Center"
		//Find Home
		var coord/home
		if(!home)
			for(var/posY = round(WORLD_W/2) to 1 step -1)
				var posX = round(WORLD_W/2)
				var compoundIndex = COMPOUND_INDEX(posX, posY, WORLD_W)
				var value = grid[compoundIndex]
				if(value > waterTable+0.1)
					home = new(posX, posY)
					break
		if(!home)
			for(var/posY = round(WORLD_W/2) to WORLD_W)
				var posX = round(WORLD_W/2)
				var compoundIndex = COMPOUND_INDEX(posX, posY, WORLD_W)
				var value = grid[compoundIndex]
				if(value > waterTable+0.1)
					home = new(posX, posY)
					break
		if(!home)
			for(var/posX = round(WORLD_W/2) to 1 step -1)
				var posY = round(WORLD_W/2)
				var compoundIndex = COMPOUND_INDEX(posX, posY, WORLD_W)
				var value = grid[compoundIndex]
				if(value > waterTable+0.1)
					home = new(posX, posY)
					break
		if(!home)
			for(var/posX = round(WORLD_W/2) to WORLD_W)
				var posY = round(WORLD_W/2)
				var compoundIndex = COMPOUND_INDEX(posX, posY, WORLD_W)
				var value = grid[compoundIndex]
				if(value > waterTable+0.1)
					home = new(posX, posY)
					break
		for(var/tries = 1 to 100)
			var posX = rand(PLOT_SIZE, WORLD_W-PLOT_SIZE)
			var posY = rand(PLOT_SIZE, WORLD_W-PLOT_SIZE)
			var compoundIndex = COMPOUND_INDEX(posX, posY, WORLD_W)
			var value = grid[compoundIndex]
			if(value > waterTable+0.1)
				home = new(posX, posY)
				break
		ASSERT(home)
		var/coord/homeTile = home.copy()
		placeRegions(home)


		world << "Generating Walls (this will take a while)"
		// Generate Maze Overlay
		var/plasmaText = ""
		for(var/posY = 1 to WORLD_W)
			sleep(0)
			world << ".\..."
			for(var/posX = 1 to WORLD_W)
				var/value = grid[COMPOUND_INDEX(posX, posY, WORLD_W)]
				if(value < WATER_TABLE)
					plasmaText += "~"
				else
					plasmaText += "%"
		var gridText = mapGenerator.generate(plasmaText, WORLD_W, WORLD_W, null, null, null, null, homeTile.x, homeTile.y)

		world << "Expanding Grid"
		// Expand tile grid along plot edges, copy from one edge to opposite edge of other plot
		var/list/expandGrid  = list()
		var/expandGridM = ""
		// Expand Horizontally
		for(var/posY = 1 to WORLD_W)
			// For Each line, Add 1 at start
			var compoundIndex = COMPOUND_INDEX(1, posY, WORLD_W)
			expandGrid.Add(grid[compoundIndex])
			expandGridM += copytext(gridText, compoundIndex, compoundIndex+1)
			// Add One every PLOT_W
			for(var/posX = 1 to WORLD_W)
				var compoundIndex2 = COMPOUND_INDEX(posX, posY, WORLD_W)
				var value  = grid[compoundIndex2]
				var valueM = copytext(gridText, compoundIndex2, compoundIndex2+1)
				if(1+(posX-1)%PLOT_W == PLOT_W && posX != WORLD_W)
					expandGrid.Add(value)
					expandGridM += valueM
				expandGrid.Add(value)
				expandGridM += valueM
		//
		var gridCopy  = expandGrid
		var gridCopyM = expandGridM
		expandGrid  = list()
		expandGridM = ""
		// Expand Vertically
		for(var/posX = 1 to PLOT_SIZE*DEFAULT_PLOTS)
			// Add row at bottom
			var compoundIndex = COMPOUND_INDEX(posX, 1, PLOT_SIZE*DEFAULT_PLOTS)
			var value  = gridCopy[compoundIndex]
			var valueM = copytext(gridCopyM, compoundIndex, compoundIndex+1)
			expandGrid.Add(value)
			expandGridM += valueM
		for(var/posY = 1 to WORLD_W)
			var repeats = 1
			if(1+(posY-1)%PLOT_W == PLOT_W && posY != WORLD_W)
				repeats = 2
			for(var/repeat = 1 to repeats)
				for(var/posX = 1 to PLOT_SIZE*DEFAULT_PLOTS)
					var compoundIndex = COMPOUND_INDEX(posX, posY, PLOT_SIZE*DEFAULT_PLOTS)
					var value  = gridCopy[compoundIndex]
					var valueM = copytext(gridCopyM, compoundIndex, compoundIndex+1)
					expandGrid.Add(value)
					expandGridM += valueM
		//
		grid = expandGrid
		gridText = expandGridM
		//
		for(var/y_pos = 1 to WORLD_SIZE)
			for(var/x_pos = 1 to WORLD_SIZE)
				var/compound_index = ((y_pos-1)*WORLD_SIZE) + x_pos
				var value = grid[compound_index]
				var plotX = round((x_pos-1)/PLOT_SIZE) +1
				var plotY = round((y_pos-1)/PLOT_SIZE) +1
				if(value <= waterTable)
					if(plotX == home.x && plotY == home.y)
						//icon_map.DrawBox(rgb(value/waterTable*102, 0, value/waterTable*255), x_pos, y_pos)
						icon_map.DrawBox(rgb(value/waterTable*102, 0, 128), x_pos, y_pos)
					else
						//icon_map.DrawBox(rgb(0, 0, value/(waterTable*255), x_pos, y_pos)
						icon_map.DrawBox(rgb(0, 0, 128), x_pos, y_pos)
				else
					var compoundIndex = plotX + (plotY-1)*DEFAULT_PLOTS
					var /plasmaGenerator/closedNode/node = plots[compoundIndex]
					if(plotX == home.x && plotY == home.y)
						icon_map.DrawBox(rgb(value*102, value*255, 0), x_pos, y_pos)
					else
						switch(node.region)
							if("forest")
								icon_map.DrawBox(rgb(0, value*255, 0), x_pos, y_pos)
							if("swamp")
								icon_map.DrawBox(rgb(0, value*128, value*128), x_pos, y_pos)
							if("desert")
								icon_map.DrawBox(rgb(value*204, value*102, value*64), x_pos, y_pos)
							if("ruins")
								icon_map.DrawBox(rgb(value*102, value*102, value*102), x_pos, y_pos)
		/*var/game/map/tile/natural/home_tile = locate(round(width/2), home_y, z_level)
		new /game/map/structure/house(home_tile)
		for(var/game/map/tile/natural/T in range(11, home_tile))
			T.clear_feature()
		home_tile.add_feature("arrow")
		spawn(10)
			while(TRUE)
				sleep(5)
				home_tile.dir = turn(home_tile.dir, 90)*/
		for(var/client/C)
		//	C << ftp(icon_map, "[rand(1000,9999)].png")
		//town.tileGrid = grid
		/*for(var/unit/U)
			U.place(home_tile)
		for(var/client/C)
			R.write()*/
		var/list/plasmaData = list(
			"plots" = plots,
			"grid" = grid,
			"home" = home,
			"maze" = gridText
		)
		return plasmaData


//------------------------------------------------------------------------------

#undef PLOT_W
#undef WORLD_W
#undef WORLD_SIZE
#undef WATER_TABLE