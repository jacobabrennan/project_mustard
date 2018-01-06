

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
			target = _target
			direction = _direction
			time = _time
			speed = _speed
		takeTurn()
			if(!target || time-- <= 0) del src
			var/oldDir = target.dir
			step(target, direction, speed)
			target.dir = oldDir
			. = ..()
	transition
		var
			interface/rpg/target
			plot/targetPlot
			tile/targetTile
			time
		New(interface/rpg/_target, plot/_plot)
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
		takeTurn()
			if(!target || time-- <= 0) del src
			target.forceLoc(get_step_towards(target, targetTile))
			. = ..()
	animate
		icon_state = ")(*&^%$#@!" // Gibberish, just so it doesn't accidentally end on the "" state.
		layer = FLY_LAYER
		New(atom/center, time, _icon_state, _icon)
			. = ..()
			centerLoc(center)
			if(_icon) icon = _icon
			if(!_icon_state) _icon_state = icon_state
			icon_state = null
			flick(_icon_state, src)
			spawn(time)
				del src
	puff
		parent_type = /event/animate
		icon = '24px.dmi'
		icon_state = "puff"
		pixel_x = -4
		pixel_y = -4
		New(atom/center)
			. = ..(center, 4)

