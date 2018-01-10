

//-- Environment ---------------------------------------------------------------

// Time & Date system
// Day / Night light system
// Weather system (pressure, temperature, humidity)


//------------------------------------------------------------------------------

var/environment/environment = new()

environment // Saving and Loading ------------------------------------------------
	fromJSON(objectData)
		currentWeatherSystem = json2Object(objectData["currentWeatherSystem"])
		currentDay = json2Object(objectData["currentDay"])
		year = objectData["year"] || 0
		time = objectData["time"]
		_startTick = world.timeofday
		_timeOffset = time || 0
	toJSON()
		var /list/objectData. = ..()
		objectData["currentWeatherSystem"] = currentWeatherSystem.toJSON()
		objectData["currentDay"] = currentDay.toJSON()
		objectData["year"] = year
		objectData["time"] = time
		return objectData
	/*proc
		load()
			var/filePath = FILE_PATH_ENVIRONMENT
			if(fexists(filePath))
				var/list/saveData = json_decode(file2text(filePath))
				// TODO: check for compatible version
				fromJSON(saveData)
			if(!currentWeatherSystem)
				generateWeatherSystem()
			if(!currentDay)
				currentDay = new()
				currentDay.setDate(4*30)
		save()
			replaceFile(FILE_PATH_ENVIRONMENT, json_encode(toJSON()))*/
	//----------------------------------
	day
		parent_type = /datum
		var
			date // 1 to DAYS_PER_YEAR (360)
			baseTemperature // 0 to 110 (measured in degrees F)
			baseHumidity // 0 to 1, Relative humidity, how close the air is to being saturated
			//
		toJSON()
			var objectData = ..()
			objectData["date"] = date
			objectData["baseTemperature"] = baseTemperature
			objectData["baseHumidity"] = baseHumidity
			return objectData
		fromJSON(list/objectData)
			date = objectData["date"]
			baseTemperature = objectData["baseTemperature"]
			baseHumidity = objectData["baseHumidity"]
			ASSERT(baseHumidity)
	//----------------------------------
	weatherSystem
		parent_type = /datum
		var
			bearing = 0 // The direction the system is moving in, as an angle.
			distance = 0 // -1 to 1. How far away the system is, in the direction it is moving. A measure of influence.
			speed = 1 // 1 to 10. A measure of how quickly the system moves, log2.
				// 1 (2d 3h 12m) 2(1d 1h 36m) 3(12h 48m) 4(6h 24m) 5(3h 12m) 6(1h 36m) 7(48m) 8(24m) 9(12m) 10(6m)
				// The table above is for a system moving from -1 to 0, so a full uninterrupted system will take that value x2.
			temperature = 0 // Averages around -10 to 10, offsets current day temperature.
			humidity = 0 // 0 to 1. Relative humidity. How saturated the air is.
			precipitation = 0 // The amount of water in clouds.
			instability = 0 // A measure of how much the atmosphere has changed recently.
			//
			baseTemperature // default null. When weather systems overtake each other, they use the old system's temp as a base
			baseHumidity // default null. When base temp / humidity are null, the day's ideal temp is used
			basePrecipitation // default null. Stores "cloud cover" from previous weather system.
		toJSON()
			var objectData = ..()
			objectData["bearing"] = bearing
			objectData["distance"] = distance
			objectData["speed"] = speed
			objectData["temperature"] = temperature
			objectData["humidity"] = humidity
			objectData["precipitation"] = precipitation
			objectData["baseTemperature"] = baseTemperature
			objectData["baseHumidity"] = baseHumidity
			objectData["basePrecipitation"] = basePrecipitation
			return objectData
		fromJSON(list/objectData)
			bearing = objectData["bearing"]
			distance = objectData["distance"]
			speed = objectData["speed"]
			temperature = objectData["temperature"]
			humidity = objectData["humidity"]
			precipitation = objectData["precipitation"]
			baseTemperature = objectData["baseTemperature"]
			baseHumidity = objectData["baseHumidity"]
			basePrecipitation = objectData["basePrecipitation"]


environment // Update Cycle / Caching --------------------------------------------
	var
		active = FALSE
		cycleLock = FALSE
		paused = FALSE
		environment/cache/cache = new()
	proc
		activate()
			if(active || cycleLock) return
			active = TRUE
			updateCycle()
		deactivate()
			active = FALSE
		pause()
			if(paused || !active) return
			paused = TRUE
		unpause()
			if(!paused || !active) return
			paused = FALSE
			updateCycle()
		updateCycle()
			if(cycleLock || !active) return
			cache = new()
			cycleLock = TRUE
			//
			//var time = getTime()
			updateWeather()
			updateLight()
			var temp = getTemperature()
			var stormTemp = ((currentWeatherSystem.baseTemperature || currentDay.baseTemperature)+currentWeatherSystem.getTemperature()) - currentDay.baseTemperature
			var stormColor = "#000"
			var stormHumidity = getHumidity()
			if(stormTemp > 0)
				var I = stormTemp*255/10
				stormColor = rgb(I,0,0)
			if(stormTemp < 0)
				var I = stormTemp*255/-10
				stormColor = rgb(0,0,I)
			var waterContent = getWaterContent(temp, stormHumidity)
			var cloudContent = getPrecipitation()
			// Round stuff
			temp = round(temp)
			stormHumidity = round(stormHumidity*100)
			waterContent = round(waterContent, 0.1)
			cloudContent = round(cloudContent, 0.1)
			var /vector/wind = getWind()
			var bearing = round(wind.dir)
			var windSpeed = round(wind.mag, 0.1)
			world << {"[round(time*24)]hr - <span style="color:[stormColor];">[temp]°</span> [stormHumidity]% <b>[waterContent]</b>/<b>[cloudContent]</b>W \[[windSpeed],[bearing]\] ([round(currentWeatherSystem.distance, 0.01)])"}
			//
			for(var/plot/P in town.activePlots)
				P.updateWeather()
			//
			cycleLock = FALSE
			spawn((DAY_TICKS/TIME_DILATION_FACTOR)/UPDATES_PER_DAY)
				updateCycle()
	//-----------------------------
	proc
		cache(key, value)
			return cache.store(key, value)
		retrieve(key)
			return cache.retrieve(key)
	cache
		// System for caching data so it won't be recalculated between updates.
		parent_type = /datum
		var/list/cacheTable = new()
		proc
			store(key, value)
				cacheTable[key] = value
			retrieve(key)
				if(key in cacheTable) return cacheTable[key]
				else return null

#define CACHE_CHECK(key) var/__cache_key = key; var/__cache_value = environment.retrieve(key); if(__cache_value){ return __cache_value}
#define CACHE_STORE(value) environment.cache(__cache_key, value); return value;


environment // Date and Time -----------------------------------------------------
	var
		environment/day/currentDay
		time // 0 to 1
		year = 0
		_percentLastCheck = 0
		// The following two values needed to restore time to value it was saved at.
		_startTick // The moment the environment was created
		_timeOffset = 0 // Time of day from save file
	proc
		getTime()
			// Does not cache!
			//world.timeofday; in 1/10 seconds;
			var dayCount = world.timeofday - _startTick
			if(dayCount < 0) dayCount += DAY_TICKS
			dayCount = (dayCount * TIME_DILATION_FACTOR)
			dayCount %= DAY_TICKS
			var dayPercent = dayCount / DAY_TICKS // 0 to 1
			dayPercent += _timeOffset
			if(dayPercent >= 1) dayPercent -= 1
			if(dayPercent < _percentLastCheck)
				advanceDate()
			time = dayPercent
			_percentLastCheck = time
			return time
		getTimeString()
			// Does not cache!
			var dayPercent = getTime()
			var dayCount = dayPercent * DAY_TICKS
			var hourCount = round(dayPercent*24)
			var minuteCount = round((dayCount%(60*60*10))/(60*10))
			var /list/months = list(
				"The Deep", "Frost",
				"Spring", "Florum", "Bright",
				"Summer", "Glory", "Burn",
				"Autumn", "Fall", "Hibernum",
				"Winter"
			)
			var day = (currentDay.date-1)%30 + 1
			var month = months[round((currentDay.date-1)/30)+1]
			var timeString = "[day]\th of [month]:: [hourCount]:[minuteCount]"
			return timeString
		advanceDate()
			var date = currentDay.date+1
			if(date > DAYS_PER_YEAR)
				year++
				date = 1
			currentDay = new()
			currentDay.setDate(date)
			spawn(1)
				world << getTimeString()
	//----------------------------------
	day
		proc/setDate(newDate)
			date = newDate
			baseTemperature = environment.getTemperatureAverageYearly(date)
			baseHumidity = environment.getHumidityAverageYearly(date)
			world << "Daily Average Temp: [baseTemperature]"


//---- Lighting (ambient) -----------------------------------------------------------
terrain/interior
	ambientLight = "#ff9"
region
	var/ambientLight = null
terrain
	var/ambientLight = null
plot
	var/ambientLight = null
	proc/getLight()
		return ambientLight
environment
	proc
		updateLight()
			for(var/interface/rpg/rpg)
				if(!rpg.client || !rpg.character) continue
				var /plot/P = plot(rpg.character)
				if(!P) continue
				rpg.transitionLight(P)
		calculateLightCurrent()
			CACHE_CHECK("calculateLightCurrent")
			var dayPercent = getTime()
			var hour = dayPercent * 24
			var intensity = 0
			if(hour > 20 || hour < 4)
				intensity = 0
			else if(hour >= SUNUP-2 && hour <= SUNUP    ) intensity = (  (hour-(SUNUP-2))/2)/2
			else if(hour >= SUNDOWN && hour <= SUNDOWN+2) intensity = (1-(hour-(SUNDOWN))/2)/2
			else                             intensity = (-cos(dayPercent*360)+1)/2
			// Calculate cloud cover from waterContent precipitated out of the air.
			// Values below 1 create no cloud cover. Max value is 5. Thus, precipitation levels over 6 are clipped.
			var cloudCover = max(0, (255*(getPrecipitation()-1)/5))
			var green = intensity * (255-cloudCover)
			var red = intensity * (255-cloudCover)
			var blue = max(153, intensity * 255)-cloudCover
			if(hour > SUNDOWN-1/2 && hour < SUNDOWN+1/2)
				var goldHour = (hour - (SUNDOWN-1/2)) / 1
				var goldIntensity = (-cos(goldHour*360)+1)/2
				red = max(red, goldIntensity*255)
			CACHE_STORE(rgb(red, green, blue))
		getLight(plot/P)
			if(!P) return calculateLightCurrent()
			var light = P.getLight()
			if(!light)
				var/terrain/T = terrains[P.terrain]
				light = T.ambientLight
			if(!light)
				var/region/R = town.getRegion(P.regionId)
				light = R.ambientLight
			if(!light)
				light = calculateLightCurrent()
			return light


//---- Temperature (ambient) ---------------------------------------------------------
region
	var/ambientTemperature = null
terrain
	var/ambientTemperature = null
plot
	var/ambientTemperature = null
	proc/getTemperature()
		return ambientTemperature
environment
	proc
		getTemperatureAverageYearly(date)
			// temperature extrema: 0F* to 110F
			// Average Temp Range: roughly 25F to 75F, for a variance of 50
			var offset = TEMP_YEARLY_LOW
			var amplitude = TEMP_YEARLY_HIGH - offset
			if(!date) date = currentDay.date
			var tempPercent = (-cos(date-20)+1)/2
			return amplitude*tempPercent + offset
		getTemperature(plot/P)
			var temperature
			if(P)
				temperature = P.getTemperature()
				if(!temperature)
					var/terrain/T = terrains[P.terrain]
					temperature = T.ambientTemperature
				if(!temperature)
					var/region/R = town.getRegion(P.regionId)
					temperature = R.ambientTemperature
				if(temperature)
					return temperature
			return currentDay.calculateTemperatureCurrent()
	//----------------------------------
	weatherSystem
		proc
			getTemperature()
				CACHE_CHECK("getTemperature")
				var influence = max(0,1-abs(distance))
				var base = 0
				if(distance < 0)
					base = (1-influence)*baseTemperature
				CACHE_STORE(base + (influence * temperature))
	//----------------------------------
	day
		var
			temperatureVariance
		proc
			calculateTemperatureCurrent()
				CACHE_CHECK("calculateTemperatureCurrent")
				// Base temperature from weather system, or from yearly average.
				var currentBase = baseTemperature
				// Adjust for Time of Day
				var dayPercent = environment.getTime()
				var idealPercent = (-sin((dayPercent+3/24)*360))
				var current = currentBase + idealPercent*10
					// To Do: Account for daily cloud cover "debt"
						// Colder during, warmer at night
				// Adjust for weather conditions
				current += environment.currentWeatherSystem.getTemperature()
				CACHE_STORE(current)


//---- Humidity (ambient) ------------------------------------------------------------
region
	var/ambientHumidity = null
	var/ambientPrecipitation = null
terrain
	var/ambientHumidity = null
	var/ambientPrecipitation = null
plot
	var/ambientHumidity = null
	var/ambientPrecipitation = null
	proc/getHumidity()
		return ambientHumidity
	proc/getPrecipitation()
		return ambientPrecipitation
environment
	proc
		getHumidityAverageYearly(date)
			// From what I've seen of graphs, average relative humidity stays pretty constant at around 65%
			return 0.65
		getHumidity(plot/P)
			var humidity
			if(P)
				humidity = P.getHumidity()
				if(!humidity)
					var/terrain/T = terrains[P.terrain]
					humidity = T.ambientHumidity
				if(!humidity)
					var/region/R = town.getRegion(P.regionId)
					humidity = R.ambientHumidity
				if(humidity)
					return humidity
			return currentDay.calculateHumidityCurrent()
		getPrecipitation(plot/P)
			var precipitation
			if(P)
				precipitation = P.getPrecipitation()
				if(!precipitation)
					var/terrain/T = terrains[P.terrain]
					precipitation = T.ambientPrecipitation
				if(!precipitation)
					var/region/R = town.getRegion(P.regionId)
					precipitation = R.ambientPrecipitation
				if(precipitation)
					return precipitation
			return currentDay.calculatePrecipitationCurrent()
	//----------------------------------
	weatherSystem
		proc
			getHumidity()
				CACHE_CHECK("getHumidity")
				var influence = max(0,1-abs(distance))
				var base = 0
				if(distance < 0)
					base = (1-influence)*baseHumidity
				CACHE_STORE(base + (influence * humidity))
			getPrecipitation()
				CACHE_CHECK("getPrecipitation")
				var influence = max(0,1-abs(distance))
				var base = 0
				if(distance < 0)
					base = (1-influence)*basePrecipitation
				var amplitude = precipitation
				if(distance > 0)
					amplitude *= influence
				CACHE_STORE(base + amplitude)
	//----------------------------------
	day
		var
			humidityVariance
		proc
			calculateHumidityCurrent()
				CACHE_CHECK("calculateHumidityCurrent")
				// Base humidity from weather system, or from yearly average.
				var currentBase = baseHumidity
				// Adjust for Temperature
				var currentTemp = calculateTemperatureCurrent()
					// humidityRelativeFromTemperature(Ti, T1, HRi)
					//	   return HRi * (( (112 + (0.9 * Ti))/(112 + (0.9 * T1)) )**8)
				var HRi = currentBase + environment.currentWeatherSystem.getHumidity()
				var HR1 = getHumidityRelativeFromTemperatureChange(HRi, baseTemperature, currentTemp)
				CACHE_STORE(HR1)
			calculatePrecipitationCurrent()
				CACHE_CHECK("calculatePrecipitationCurrent")
				var value = environment.currentWeatherSystem.getPrecipitation()
				CACHE_STORE(value)


//---- Wind (ambient) ----------------------------------------------------------------
region
	var/vector/ambientWind = null
terrain
	var/vector/ambientWind = null
plot
	var/vector/ambientWind = null
	proc/getWind()
		return ambientWind
environment
	proc
		getWind(plot/P)
			var /vector/wind
			if(P)
				wind = P.getWind()
				if(!wind)
					var/terrain/T = terrains[P.terrain]
					wind = T.ambientWind
				if(!wind)
					var/region/R = town.getRegion(P.regionId)
					wind = R.ambientWind
				if(wind)
					return wind.copy()
			return currentDay.calculateWindCurrent()
	//----------------------------------
	weatherSystem
		proc
			getWind()
				CACHE_CHECK("getWind")
				var influence = max(0,1-abs(distance))
				var direction = bearing
				switch(speed)
					// speed = 1 to 10. A measure of how quickly the system moves, log2.
						// 1 (2d 3h 12m) 2(1d 1h 36m) 3(12h 48m) 4(6h 24m) 5(3h 12m) 6(1h 36m) 7(48m) 8(24m) 9(12m) 10(6m)
						// The table above is for a system moving from -1 to 0, so a full uninterrupted system will take that value x2.
					if(10) return vector(speed, direction)
					if(9)
						if(influence < 0.5)
							CACHE_STORE(vector(speed/2, direction))
						else
							CACHE_STORE(vector(speed, direction))
					if(8, 5)
						CACHE_STORE(vector(max(speed*influence, speed*0.2), direction))
					else // Calmer at center of system
						influence *= 1.5
						if(influence > 1)
							influence = 2 - influence
				CACHE_STORE(vector(speed*influence, direction))
	//----------------------------------
	day
		proc
			calculateWindCurrent()
				CACHE_CHECK("calculateWindCurrent")
				CACHE_STORE(environment.currentWeatherSystem.getWind())



//---- Weather Systems ---------------------------------------------------------------
//client/DblClick()
//	environment.generateWeatherSystem()
environment
	var
		environment/weatherSystem/currentWeatherSystem
	proc
		generateWeatherSystem(_bearing, _temp, _humidity, _speed)
			var /environment/weatherSystem/newSystem = new()
			if(currentWeatherSystem && currentWeatherSystem.distance < 1)
				newSystem.overtake(currentWeatherSystem)
			newSystem.bearing = (_bearing != null)? _bearing : rand(0,360)
			newSystem.temperature = (_temp != null)? _temp : rand(-10,10)
			newSystem.humidity = (_humidity != null)? _humidity : rand()
			newSystem.precipitation = rand(0,3)
			newSystem.speed = (_speed != null)? _speed : rand(3, 9)
			newSystem.distance = -1
			currentWeatherSystem = newSystem
			diag("New Weather System: [newSystem.temperature]x[newSystem.speed]")
		updateWeather()
			if(!currentWeatherSystem)
				generateWeatherSystem()
			else
				currentWeatherSystem.advance()
	weatherSystem
		proc
			advance()
				if(distance >= 1)
					environment.generateWeatherSystem()
					return
				distance += 1/(2**(10-speed))
				distance = min(1, distance)
				var currentHumidity = environment.getHumidity()
				var currentTemperature = environment.getTemperature()
				// Transfer Water Between Clouds and Vapor (Humidity)
				if(currentHumidity > 1) // Precipitate Water into Clouds
					// Dump all vapor over 1, or just some?
					precipitation += getWaterContent(currentTemperature, currentHumidity - 1)
					humidity -= getHumidityRelativeFromTemperatureChange(
						currentHumidity - 1,
						currentTemperature,
						environment.currentDay.baseTemperature
					)
			overtake(environment/weatherSystem/oldSystem)
				baseTemperature = oldSystem.getTemperature()
				baseHumidity = oldSystem.getHumidity()
				basePrecipitation = oldSystem.getPrecipitation()





/*
var HR1 = HRi * (
	(1 + (0.9/112)*T1)^(-8)
)
*/
/*proc
	fahrenheitToCelsius(fahrenheit)
		return (fahrenheit - 32    ) * (5/9)
	celsiusToFahrenheit(celsius)
		return (celsius    * (9/5) ) + 32
	fahrenheitToKelvin(fahrenheit)
		return (fahrenheit + 459.67) * (5/9)
	kelvinToFahrenheit(kelvin)
		return (kelvin     * (9/5) ) - 459.67*/

/*
client/DblClick()
	var Ti = rand(50,80)
	var T1 = fahrenheitToCelsius(Ti + rand(-10,10))
	Ti = fahrenheitToCelsius(Ti)
	var HRi = rand(50, 90) * 0.01
	var dewPoint = dewP(Ti, HRi)
	var HR1 = humidityRelativeFromTemperature(Ti, T1, HRi)
	Ti = round(celsiusToFahrenheit(Ti))
	T1 = round(celsiusToFahrenheit(T1))
	HRi = round(HRi*100)
	HR1 = round(HR1*100)
	world << "[HRi]% @[Ti] => [HR1]% @[T1]"//[HR1]% @[T1]"
*/

/*proc
	humidityRelativeFromTemperature(Ti, T1, HRi)
		return HRi * (( (112 + (0.9 * Ti))/(112 + (0.9 * T1)) )**8)
	temp(Hr,TD)
		var tA = (Hr)**(1/8)
		return (TD - (112*tA) + 112) / ((0.9 * tA) + 0.1)
	hRel(T,TD)
		return ((112-(0.1*T) + TD) / (112 + (0.9 * T))) ** 8
	dewP(T,Hr)
		var tA = Hr ** (1/8)
		return ((112 + (0.9 * T))) * tA + (0.1 * T) - 112*/

/*
Hr = (100%) * (E/Es)

E  = E0 * exp( (L/Rv) * ((1/T0) - (1/Td)) )
Es = E0 * exp( (L/Rv) * ((1/T0) - (1/T )) )

E  = E0 * exp( C1 * (C2 - (1/Td)) )
Es = E0 * exp( C1 * (C2 - (1/T )) )


E/Es = exp(
	C1*(
		(1/Td) + (1/T)
	)
)

Hr = exp(C1*(1/Ti - 1/Td))

hri = exp(C1/Ti) / exp(C1/Td)
hr1 = exp(C1/T1) / exp(C1/Td)

hri = exp(C1/Ti - C1/Td)
Td = 1/(1/Ti - ln(hri)/C1)

hr1 = exp(C1*(1/T1 + 1/Ti)) / hri

humidityRelative(Ti, T1, HRi) = (
	e**(
		5423K * (
			1/T1 + 1/Ti
		)
	)
)/HRi

E0 * exp(
	(L/Rv) * (
		(1/T0) - (1/Td)
	)
)

where E0 = 0.611 kPa, (L/Rv) = 5423 K (in Kelvin, over a flat surface of water), T0 = 273 K (Kelvin)

and T is temperature (in Kelvin), and Td is dew point temperature (also in Kelvin).
*/



/* Weather Notes:
	Hot air rises -> Expands on reaching top -> Causes cooling -> Dew Point lowers -> Cloud Formation & Precipitation
	Dew Point: The temp which air has to be lowered to in order to be saturated. Cooling air results in precipitation
	Hot Air over a body of water causes formation of thermals which carry water into the atmosphere to form clouds.
	Precipitation releases heat do to phase change from gas to liquid, causing air to rise and become unstable (leading to more precipitation)
	Hot air moving up will spread out and cool, leading to precipitation when the temp reaches the dew point
	High Wind speed increases rate of evapotranspiration
	What is an inversion?
	Low pressure areas generally result in precipitation.
		Guess: Low pressure areas rise, cool, and precipitate.
	Pressure causes rotation: High Pressure -> clockwise. Low Pressure -> anticlockwise
	Higher instability results in greater chances of precipitation,
		lower instability may lead to clouds that don't precipitate (fair weather clouds)
	Phase change (G -> L) releases heat, causes lift, causes cooling, causes more phase change.
		End result is a rising and growing cloud.
		Once all moisture has been converted to liquid, heating / lifting stops, and
		water falls to the ground.
	Rain can also be the result of too much water being phase changed at a given time.
		(the drops become too large to be lifted by the air current)

	https://en.wikipedia.org/wiki/Weather_front
	Cold fronts move west to east, warm fronts move poleward
	Cold fronts may feature narrow bands of thunderstorms and severe weather, and may on occasion be preceded by squall lines or dry lines.
	Warm fronts are usually preceded by stratiform precipitation and fog. The weather usually clears quickly after a front's passage.
	Cold fronts move faster than warm fronts

	https://weather-and-climate.com/average-monthly-Rainfall-Temperature-Sunshine-in-United-States-of-America
	From what I've seen, average relative humidity stays pretty constant at around 65% all year.

*/

/*
	Days of Continuous Rain
	Breif Showers
	Storms
*/



/*
Types of weather I want to simulate:
	Non-ground-reaching precipitation:
		Fog
?		Patchy clouds
*		full cloud cover
	Ground-reaching precipitation:
		summer showers (patchy clouds that rain)
		long term rain (full cloud cover)
		snow
	Lightning & Thunder!
*/


/*
Environmental Variables:
*	Date & Time
*	Ambient Light (color)
	pressure? (Scalar)
	Wind (vector)
*	Humidity? (percentage)
*		Cloud Cover (Percentage)
*		Precipitation (binary?)
*	Temperature (scalar)
*/

/*
The environment is governed by cycles that are either solar or weather, and vary in scale.

Solar cycles:
*	Year
*		Consists of 360 days that cycle through 4 or 6 seasons.
*		Determines
*			average temperature
*			time of sunrise & sunset
	Day
*		The basic unit of time.
*		Determines
*			Instantaneous temperature (should effect wind/pressure)
*			Instantaneous ambient light (should effect flora and fauna)
			behaviors of flora and fauna
	Season
		Consists of a set start and end date.
		Determines
			the general type of weather system generated
			behaviors of flora and fauna

Weather cycles
	Weather System
		Consists of:
*			A period of time longer than a day but shorter than a season.
*			Values of pressure, temperature, and humidity.
*			A location and a direction (moves relative to the map over time)
		Determines:
			Wind, temperature, precipitation, cloud cover and movement
			Storm events
	Storm
		Generated by extreme conditions in and between weather systems
		Consists of
			A period of a fraction of a day to one day
			extreme conditions of wind, temperature, or humidity that trigger special code.

Putting it all together::
*	The game world experiences a year of 360 days which determines the seasonal setting.
*	The change of seasons determines the "baseTemperature" on a given day.
*	The change of time over a day further augments the baseTemperature.

	Seasons also generate weather systems at cardinal or intercardinal directions.
*	These weather systems can move relative to a point representing the entirety of the game world,
*		they can also dissipate and be replaced by other systems.
*	Weather systems augment the baseTemperature, and determine basePressure and baseHumidity levels.
	The movement and interaction between these systems generates weather events.
	Weather events are spawned by the primary weather system (whichever controls the center point),
		and use the temperature, humidity, and pressure of adjacent systems to greatly augment
		baseTemperature, baseHumidity, and basePressure.
	Weather events can also trigger specific hard coded events, such as tornadoes or flooding.

*	baseHumidity determines cloud cover, which in turn augments baseTemperature.
	near 100%, baseHumidity causes precipitation as rain, snow, and maybe hail.
	changes in basePressure over time determine the windVector.
	changes in basePressure can also augment baseHumidity.

	The result for the player is:
*		Ambient Light
*		Ambient Temperature
		Ambient Precipitation

		Visual Cloud Cover
		windVector (spontaneous gusts)

		Seasonal changes to fauna & flora (e.g. bushes with berries)
		Weather artifacts such as snow

		Dramatic weather events, such as tornadoes

*/
/*
Brain Storm:
	Ambient Light (effected by clouds, mist, etc) effects instantaneous temp
	Temperature rises at a fractional rate determined by cloud cover?
	Wind vector effects player temperature / adds shelter seeking behavior.
	Hail? What causes it? Magnets, how do they work?
	Player temperature is shown by gauge with two pointers.
		One shows outside temperature.
		One shows felt temperature, moves with sweat/wet and wind taking away hot air (built by wearing cloths)
*/



// TO BE REFACTORED -----------------------------------------------------//

proc
	fahrenheitToCelsius(fahrenheit)
		return (fahrenheit - 32    ) * (5/9)
	celsiusToFahrenheit(celsius)
		return (celsius    * (9/5) ) + 32
	fahrenheitToKelvin(fahrenheit)
		return (fahrenheit + 459.67) * (5/9)
	kelvinToFahrenheit(kelvin)
		return (kelvin     * (9/5) ) - 459.67

proc
	getTemperature(dewP, HRi) // Get Temp from dewPoint and humidity
		var C1 = 17.625
		var C2 = 243.04
		dewP = fahrenheitToCelsius(dewP)
		var gamma = (C1 * dewP) / (C2 + dewP)
		var numer = C2 * (gamma - log(HRi))
		var denom = C1 +  log(HRi) - gamma
		return celsiusToFahrenheit(numer / denom)
	getDewPoint(Ti, HRi) // Get dewPoint from temp and humidity
		var C1 = 17.625
		var C2 = 243.04
		Ti = fahrenheitToCelsius(Ti)
		var numer = C2 * (log(HRi) + ((C1*Ti) / (Ti+C2)))
		var denom = C1 -  log(HRi) - ((C1*Ti) / (Ti+C2))
		return celsiusToFahrenheit(numer / denom)
	getHumidityRelative(Ti, dewP) // Get humidity from temp and dewpoint
		var C1 = 17.625
		var C2 = 243.04
		Ti   = fahrenheitToCelsius(Ti)
		dewP = fahrenheitToCelsius(dewP)
		var numer = exp((C1*dewP) / (dewP+C2))
		var denom = exp((C1*Ti  ) / (  Ti+C2))
		return numer / denom
	getHumidityRelativeFromTemperatureChange(HRi, Ti, T1)
		var dewP = getDewPoint(Ti, HRi)
		var HR1 = getHumidityRelative(T1, dewP)
		return HR1
	getWaterContent(T1, HR1)
		// In units where 1 is equal to the amount of water in a given volume at 100% HR at 0C
		return HR1 / getHumidityRelative(T1, 32)