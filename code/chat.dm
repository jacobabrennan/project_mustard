system
	proc
		routeChat(client/who, what)
			var sanitizedName = html_encode(who.key)
			what = html_encode(what)
			what = copytext(what, 1, findtext(what, "\n"))
			what = copytext(what, 1, 400)
			if(!length(what)) return
			world << {"<b style="color:#00f">[sanitizedName]</b>: [what]"}
		routeTraffic(client/who, message)
			var sanitizedName = html_encode(who.key)
			world << {"<i style="color:#008">[sanitizedName] [message]</i>"}
client
	New()
		. = ..()
		system.routeTraffic(src, "has joined the server.")
	Del()
		system.routeTraffic(src, "has left the server.")
	verb
		saySystem(what as text)
			if(!what) return
			system.routeChat(src, what)


game
	proc
		routeChat(interface/who, what)
			var sanitizedName = html_encode(who.key)
			what = html_encode(what)
			what = copytext(what, 1, findtext(what, "\n"))
			what = copytext(what, 1, 400)
			if(!length(what)) return
			what = {"<b style="color:#630">[sanitizedName]</b>: [what]"}
			if(istype(who, /rpg))
				var /rpg/int = who
				what = "\icon[int.character] [what]"
			spectators << output(what, "outputChannelGame")
			for(var/character/partyMember/member in party.characters)
				var /rpg/int = member.interface
				if(!istype(int)) continue
				int.client << output(what, "outputChannelGame")

		routeTraffic(client/who, what)
			var sanitizedName = html_encode(who.key)
			what = {"<i>[sanitizedName] [what]</i>"}
			spectators << output(what, "outputChannelGame")
			for(var/character/partyMember/member in party.characters)
				var /rpg/int = member.interface
				if(!istype(int)) continue
				int.client << output(what, "outputChannelGame")
	//
	addSpectator(client/client)
		. = ..()
		routeTraffic(client.interface, "is now spectating.")
	spectator
		disconnect()
			var /game/G = game(src)
			G.routeTraffic(src, "has stopped spectating.")
			. = ..()
		verb
			sayGame(what as text)
				if(!what) return
				var /game/G = game(src)
				G.routeChat(src, what)


party
	addPlayer(client/client, playerPosition)
		var /rpg/int = ..()
		var /game/G = game(plot(int.character))
		if(G)
			G.routeTraffic(int, "is now playing as [int.character.name].")
		return int
rpg
	verb
		sayGame(what as text)
			if(!what) return
			var /game/G = game(character)
			G.routeChat(src, what)

/*
client
	var/C
	New()
		. = ..()
		C = pick("red","green","blue","darkred","darkblue","darkgreen","darkgrey")
		world << {"<i style="color:grey"> - [key] has joined.</i>"}
	Del()
		world << {"<i style="color:grey"> - [key] has left.</i>"}
		. = ..()
client/verb/say(what as text)
	world << {"<b style="color:[C]">[key]</b>: [what]"}

client
	verb
		chat(what as text|null)
			what = html_encode(what)
			what = copytext(what, 1, findtext(what, "\n"))
			what = {"<b class="user_name">[html_encode(key)]</b>: [what]"}
			if(hero)
				var/image_link = hero.to_link({"<img class="icon" src="\ref[hero.icon]" icondir="EAST" iconframe="2" border="0">"})
				what = "[image_link] [what]"
			world << what




mob
	Login()
		client.skin = new(client)
		..()

client
	var
		client/skin/skin
		is_chat_visible = TRUE

		toggle_chat()
			set name = ".togglechat"
			is_chat_visible = !is_chat_visible
			winshow(src, "chat", is_chat_visible)

		focus_chat()
			set name = ".focuschat"
			var/chat = winget(src, "chat", "is-visible")
			var/visi = winget(src, "chat.input", "focus")
			if(chat != "true")
				winshow(src, "chat")

			if(visi == "true")
				winset(src, null, "main.focus='true';")

			else
				winset(src, null, "chat.input.focus='true';")*/