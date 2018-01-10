

//-- Mirror Test ---------------------------------------------------------------

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