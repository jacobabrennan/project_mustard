

//------------------------------------------------------------------------------

client
	var
		client/lighting/lighting
	lighting
		parent_type = /obj
		screen_loc = "center"
		plane = PLANE_LIGHTING
		blend_mode = BLEND_MULTIPLY
		appearance_flags = PLANE_MASTER | NO_CLIENT_COLOR
		color = list(null, null, null, "#0000", "#ffff")
		mouse_opacity = 0    // nothing on this plane is mouse-visible
		buffer
			parent_type = /obj
			screen_loc = "1,1"
			icon = 'light_overlay.png'
			plane = PLANE_LIGHTING
			blend_mode = BLEND_ADD
			appearance_flags = NO_CLIENT_COLOR
	New()
		. = ..()
		lighting = new()
		screen.Add(new /client/lighting/buffer())
		screen.Add(lighting)
	proc/setLight(ambientColor)
		. = ..()
		if(length(ambientColor) == 7) // "#xxxxxx"
			ambientColor += "ff"
		else if(length(ambientColor) == 4) // "#xxx"
			ambientColor += "f"
		animate(
			lighting,
			color = list(null, null, null, "#0000", ambientColor),
			time = 5
		)


//------------------------------------------------------------------------------

lightSource
	parent_type = /obj
	icon = 'light_source4.png'
	plane = PLANE_LIGHTING
	blend_mode = BLEND_ADD
	var
		imageSize = 240
	//appearance_flags = NO_CLIENT_COLOR
	//appearance_flags = PLANE_MASTER
	var
		intensity = 1
		radius = 64
	proc/setState(_intensity, _color, _radius)
		pixel_x = -imageSize/2+bound_width/2
		pixel_y = -imageSize/2+bound_width/2
		intensity = _intensity
		alpha = intensity*255
		color = _color
		radius = _radius
		var /matrix/M = matrix()
		transform = M.Scale(_radius/(imageSize/2))
	//
	follower
		parent_type = /actor
		var
			obj/target
			lightSource/light
		New()
			. = ..()
			light = new()
		Del()
			del light
			. = ..()
		takeTurn(delay)
			. = ..()
			if(!target) del src
			centerLoc(target)
			light.centerLoc(src)
		proc/setState(_intensity, _color, _radius)
			return light.setState(_intensity, _color, _radius)
		proc/follow(newTarget)
			target = newTarget
			centerLoc(target)


//------------------------------------------------------------------------------

character/partyMember/New()
	. = ..()
	var /lightSource/follower/F = new()
	F.follow(src)
	F.setState(0.5, "#f40", 64)