
titleScreen
	Login()
		. = ..()
		playSong("goblin")

rpg
	Login()
		. = ..()
		playSong("cavern")


//-- Audio Library -------------------------------------------------------------

system
	var
		list/audioLibrarySongs = list(
			"regressiaTheme" = 'opening_theme.xm',
			"cavern" = 'cavern.xm',
			"goblin" = 'goblins.xm'
		)
		list/audioLibrarySounds = list(
			"menu" = 'menu_move_3.wav'
		)
	proc/getSound(audioId)
		return audioLibrarySounds[audioId]
	proc/getSong(audioId)
		return audioLibrarySongs[audioId]


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

interface
	proc
		playSound(audioId)
			if(client) client.audio.playSound(audioId)
		playSong(audioId)
			if(client) client.audio.playSong(audioId)


//-- Audio ---------------------------------------------------------------------

client/audio
	var
		currentSong
	proc
		playSound(audioId)
			// Get the sound from the system & play it.
			var audioFile = system.getSound(audioId)
			if(!audioFile) return
			client << sound(audioFile)
		playSong(audioId)
			// Handle "play nothing" commands
			if(!audioId)
				client << sound(null, channel=CHANNEL_MUSIC)
				return
			// Get the song from the system. Repeat it on CHANNEL_MUSIC
			var /sound/S = sound(
				system.getSong(audioId),
				repeat=TRUE,
				wait=FALSE,
				channel=CHANNEL_MUSIC
			) //,volume)
			client << S