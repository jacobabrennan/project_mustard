

//------------------------------------------------------------------------------

event
	parent_type = /actor


//------------------------------------------------------------------------------

event
	push
		var
			atom/movable/target
			direction
			time
			speed
		New(combatant/_target, _direction, _time, _speed)
			. = ..()
			forceLoc(_target.loc) // necessary so it can be locate()d later.
			target = _target
			direction = _direction
			time = _time
			speed = _speed
		takeTurn(delay)
			time--
			if(!target || (time < 0)) del src
			var/oldDir = target.dir
			step(target, direction, speed)
			target.dir = oldDir
			. = ..()
	transition
		var
			rpg/target
			plot/targetPlot
			tile/targetTile
			time
		New(rpg/_target, plot/_plot)
			. = ..()
			target = _target
			targetPlot = _plot
			del target.transitionEvent
			target.transitionEvent = src
			var /game/G = system.getGame(_plot.gameId)
			var/region/parentRegion = G.getRegion(_plot.regionId)
			targetTile = locate(
				_plot.area.x+round(PLOT_SIZE/2),
				_plot.area.y+round(PLOT_SIZE/2),
				parentRegion.z()
			)
			time = get_dist(target, targetTile)
		takeTurn(delay)
			time--
			if(!target || (time < 0)) del src
			target.forceLoc(get_step_towards(target, targetTile))
			. = ..()


//-- Effects -------------------------------------------------------------------

effect
	parent_type = /obj
	mouse_opacity = 0
	//layer = -1

	animate
		icon_state = ")(*&^%$#@!" // Gibberish, just so it doesn't accidentally end on the "" state.
		New(atom/center, time, _icon_state, _icon)
			. = ..()
			centerLoc(center)
			if(_icon) icon = _icon
			if(!_icon_state) _icon_state = icon_state
			icon_state = null
			flick(_icon_state, src)
			spawn(time)
				del src
		// Eventually, add an animate() movement to this,
		// so they don't have to use the movement system for effects
	puff
		parent_type = /effect/animate
		icon = '24px.dmi'
		icon_state = "puff"
		pixel_x = -4
		pixel_y = -4
		New(atom/center)
			. = ..(center, 4)