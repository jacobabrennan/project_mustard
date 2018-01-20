
titleScreen
	Login()
		. = ..()
		client.audio.playSong("goblin")

rpg
	Login()
		. = ..()
		client.audio.playSong()


//-- Audio Library -------------------------------------------------------------

system
	var
		list/audioLibrarySongs = list(
			"regressiaTheme" = 'opening_theme.xm',
			"cavern" = 'cavern.xm',
			"goblin" = 'goblins.xm'
		)
	proc/getSong(songId)
		return audioLibrarySongs[songId]


//-- Audio Setup ---------------------------------------------------------------

client
	var
		client/audio/audio
	New()
		. = ..()
		audio = new(src)

client/audio
	parent_type = /datum
	var
		client/client
	New(client/_client)
		. = ..()
		client = _client


//-- Audio ---------------------------------------------------------------------

client/audio
	var
		currentSong
	proc/playSong(songId)
		if(!songId)
			client << sound(null, channel=CHANNEL_MUSIC)
			return
		var /sound/S = sound(
			system.getSong(songId),
			repeat=1,
			wait=FALSE,
			channel=CHANNEL_MUSIC
		) //,volume)
		client << S