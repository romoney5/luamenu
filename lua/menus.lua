local menus = {}
local v = ...

--title screen menu

menus.MainMenu = Menu:new{
	anchor = {x = "center", y = "bottom"},
	show_version = true,
	
	items = {
		MenuItem_Button:new{label = "1  Player", align = "center", link = "SingleplayerMenu"},
		MenuItem_Button:new{label = "Multiplayer", align = "center", link = "MultiplayerMenu"},
		MenuItem_Button:new{label = "Extras", align = "center"},
		MenuItem_Button:new{label = "Addons", align = "center"},
		MenuItem_Button:new{label = "Options", align = "center", link = "OptionsMenu"},
		MenuItem_Button:new{label = "Quit  Game", align = "center", action = function(self)
			return function()
				COM_BufInsertText(nil, "quit")
			end
		end},
	},
}

menus.SingleplayerMenu = Menu:new{
	anchor = {x = "center", y = "bottom"},
	
	items = {
		MenuItem_Button:new{label = "Start Game", align = "center", link = "SingleplayerMenu_StartGame"},
		MenuItem_Button:new{label = "Record Attack", align = "center", link = "MultiplayerMenu"},
		MenuItem_Button:new{label = "NiGHTS Mode", align = "center"},
		MenuItem_Button:new{label = "Marathon Run", align = "center"},
		MenuItem_Button:new{label = "Tutorial", align = "center", link = "OptionsMenu"},
		MenuItem_Button:new{label = "Statistics", align = "center"},
	},
}

menus.SingleplayerMenu_StartGame = Menu:new{
	anchor = {x = "center", y = "bottom"},
	
	items = {
		MenuItem_Button:new{label = "Start Game", align = "center", link = "SingleplayerMenu"},
	},
	
	on_draw = function(self, v)
		local patch = v.getSprite2Patch("sonic", SPR2_STND)
		v.draw(50, 50, patch)
		
		self.save_select = $ or 0
		self.save_scroll = $ or 0
		self.save_dest_scroll = $ or 0
		
		local scale = FU / 2
		local no_save = v.cachePatch("SAVENONE")
		v.drawScaled(FU * 160 - no_save.width * scale / 2 - self.save_scroll, FU * 100 - no_save.height * scale / 2, scale, no_save)
	end,
	
	on_input = function(self, key, name)
		local scrollby = 0
		if name == "right arrow" then scrollby = 1 end
		if name == "left arrow" then scrollby = -1 end
		
		if scrollby then
			self.save_select = $ + scrollby
			self.save_scroll = $ + scrollby * FU * 100
		end
		
		return true
	end,
}

menus.MultiplayerMenu = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	
	items = {
		MenuItem_Header:new{label = "Join a game"},
		MenuItem_Button:new{label = "Server browser...", link = "ServerBowser", spacing = FU * 2},
		MenuItem_Button:new{label = "Specify server address:", link = "MainMenu", spacing = FU * 2},
		MenuItem_Button:new{label = "Rejoin previous servers...", link = "MainMenu", spacing = FU * 2},
		
		MenuItem_Header:new{label = "Host a game"},
		MenuItem_Button:new{label = "Internet/LAN...", link = "OptionsMenu_Video", spacing = FU * 2},
		MenuItem_Button:new{label = "Splitscreen...", link = "OptionsMenu_Video", spacing = FU * 2},
		
		MenuItem_Header:new{label = "Player setup"},
		MenuItem_Button:new{label = "Player 1...", link = "MainMenu", spacing = FU * 2},
		MenuItem_Button:new{label = "Player 2...", link = "MainMenu", spacing = FU * 2},
	},
}

local masterserver = CV_FindVar("masterserver")

--thax https://gist.github.com/jaredallard/ddb152179831dd23b230
--i did have to clean up some nasty whitespace though
local function string_split(self, delimiter)
	local result = {}
	local from = 1
	local delim_from, delim_to = string.find(self, delimiter, from)
	while delim_from do
		table.insert(result, string.sub(self, from, delim_from - 1))
		from  = delim_to + 1
		delim_from, delim_to = string.find(self, delimiter, from)
	end
	table.insert(result, string.sub(self, from))
	return result
end

menus.ServerBowser = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	
	on_entry = function(self, old_menu)
		print("Contacting master server...")
		
		self.items = {
			MenuItem_Header:new{label = "Contacting master server..."},
		}
		
		self:updateItems()
		
		if not HTTP then print("Not contacting the master server.") return end
		
		local function get_rooms(response)
			if response.message then
				print("error:", response.message)
				return
			end
			
			local body = response.body
			local rooms = {}
			local state = {}
			
			for i, line in ipairs(string_split(body, "\n")) do
				if not state.in_room then
					state.in_room = true
					state.room = {}
					state.line_num = 1
					state.empty_lines = 0
				end
				
				local room = state.room
				
				if state.line_num == 1 then --room id
					room.id = tonumber(line)
				elseif state.line_num == 2 then --room name
					room.name = tostring(line)
					print("got name "..room.name)
				else --probably the description
					room.desc = ($ or "")..tostring(line).."\n"
				end
				
				if line == "" then
					state.empty_lines = $ + 1
				else
					state.empty_lines = 0
				end
				
				if state.empty_lines == 2 then
					state.in_room = false
					table.insert(rooms, state.room)
				end
				
				state.line_num = $ + 1
				
-- 				print(line)
			end
			
			self.items = {
				MenuItem_Header:new{label = "Select a room"},
			}
			
			for i, v in ipairs(rooms) do
				table.insert(self.items, MenuItem_Button:new{label = v.id..": "..v.name, link = "ServerBowser", spacing = FU * 2})
			end
			
			self:updateItems()
-- 			HTTP.get(("%s/rooms"):format(masterserver.string), get_rooms)
		end
		
		local function get_version(response)
			if response.message then
				print("error:", response.message)
				return
			end
			
			print(response.body)
			HTTP.get(("%s/rooms"):format(masterserver.string), get_rooms)
		end
		
		HTTP.get(("%s/versions/%d"):format(masterserver.string, MODID), get_version)
	end,
	
	items = {
		MenuItem_Header:new{label = "Join a game"},
		MenuItem_Button:new{label = "Server browser...", link = "ServerBowser", spacing = FU * 2},
		MenuItem_Button:new{label = "Specify server address:", link = "MainMenu", spacing = FU * 2},
		MenuItem_Button:new{label = "Rejoin previous servers...", link = "MainMenu", spacing = FU * 2},
		
		MenuItem_Header:new{label = "Host a game"},
		MenuItem_Button:new{label = "Internet/LAN...", link = "OptionsMenu_Video", spacing = FU * 2},
		MenuItem_Button:new{label = "Splitscreen...", link = "OptionsMenu_Video", spacing = FU * 2},
		
		MenuItem_Header:new{label = "Player setup"},
		MenuItem_Button:new{label = "Player 1...", link = "MainMenu", spacing = FU * 2},
		MenuItem_Button:new{label = "Player 2...", link = "MainMenu", spacing = FU * 2},
	},
}

menus.OptionsMenu = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 50 * 2,
	height = FU * 200 - FU * 20 * 2,
	
	items = {
		MenuItem_Button:new{label = "Player 1 Controls...", link = "MainMenu", spacing = FU * 2},
		MenuItem_Button:new{label = "Player 2 Controls...", link = "MainMenu", spacing = FU * 2},
		MenuItem_Button:new{label = "Controls per key", cvar = CV_FindVar("controlperkey"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Video Options...", link = "OptionsMenu_Video", spacing = FU * 2},
		MenuItem_Button:new{label = "Network Options...", link = "OptionsMenu_Network", spacing = FU * 2},
		
		MenuItem_Button:new{label = "Bakc", link = "MainMenu"},
		MenuItem_Button:new{label = "Options", link = "OptionsMenu"},
		MenuItem_Button:new{label = "Quit  Game"},
	},
}

menus.OptionsMenu_Video = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	
	items = {
		MenuItem_Header:new{label = "Screen"},
		MenuItem_Button:new{label = "Set Resolution...", spacing = FU * 2},
		MenuItem_Button:new{label = "Fullscreen (F11)", cvar = CV_FindVar("fullscreen"), spacing = FU * 2},
		MenuItem_Button:new{label = "Vertical Sync", cvar = CV_FindVar("vid_wait"), spacing = FU * 2},
		MenuItem_Button:new{label = "Renderer (F10)", cvar = CV_FindVar("renderer"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Color Profile"},
		MenuItem_Button:new{label = "Brightness", cvar = CV_FindVar("gamma"), spacing = FU * 2},
		MenuItem_Button:new{label = "Saturation", cvar = CV_FindVar("saturation"), spacing = FU * 2},
		MenuItem_Button:new{label = "Advanced Settings...", link = "OptionsMenu_Video", spacing = FU * 2},
		
		MenuItem_Header:new{label = "Heads-Up Display"},
		MenuItem_Button:new{label = "Show HUD", cvar = CV_FindVar("showhud"), spacing = FU * 2},
		MenuItem_Button:new{label = "HUD Transparency", cvar = CV_FindVar("translucenthud"), spacing = FU * 2},
		MenuItem_Button:new{label = "Score/Time/Rings", cvar = CV_FindVar("timerres"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show Powerups", cvar = CV_FindVar("powerupdisplay"), spacing = FU * 2},
		MenuItem_Button:new{label = "Local Ping Display", cvar = CV_FindVar("showping"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show Player Names", cvar = CV_FindVar("seenames"), spacing = FU * 2},
		MenuItem_Button:new{label = "Uppercase Menus", cvar = CV_FindVar("menucaps"), spacing = FU * 2},
		MenuItem_Button:new{label = "Menu Color", cvar = CV_FindVar("menucolor"), spacing = FU * 2},
		MenuItem_Button:new{label = "Screen Fades", cvar = CV_FindVar("wipes"), spacing = FU * 2}, --romoney5
		
		MenuItem_Header:new{label = "Console"},
		MenuItem_Button:new{label = "Background Color", cvar = CV_FindVar("con_backcolor"), spacing = FU * 2},
		MenuItem_Button:new{label = "Text Size", cvar = CV_FindVar("con_textsize"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Chat"},
		MenuItem_Button:new{label = "Chat Mode", cvar = CV_FindVar("chatmode"), spacing = FU * 2},
		MenuItem_Button:new{label = "Chat Box Width", cvar = CV_FindVar("chatwidth"), spacing = FU * 2},
		MenuItem_Button:new{label = "Chat Box Height", cvar = CV_FindVar("chatheight"), spacing = FU * 2},
		MenuItem_Button:new{label = "Message Fadeout Time", cvar = CV_FindVar("chattime"), spacing = FU * 2},
		MenuItem_Button:new{label = "Chat Notifications", cvar = CV_FindVar("chatnotifications"), spacing = FU * 2},
		MenuItem_Button:new{label = "Spam Protection", cvar = CV_FindVar("chatspamprotection"), spacing = FU * 2},
		MenuItem_Button:new{label = "Chat background tint", cvar = CV_FindVar("chatbacktint"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Level"},
		MenuItem_Button:new{label = "Draw Distance", cvar = CV_FindVar("drawdist"), spacing = FU * 2},
		MenuItem_Button:new{label = "Weather Draw Dist.", cvar = CV_FindVar("drawdist_precip"), spacing = FU * 2},
		MenuItem_Button:new{label = "NiGHTS Hoop Draw Dist.", cvar = CV_FindVar("drawdist_nights"), spacing = FU * 2},
		MenuItem_Button:new{label = "Pitch/Roll Object Rotation", cvar = CV_FindVar("pitchroll-tation"), spacing = FU * 2},
		MenuItem_Button:new{label = "Ring Racers Screenshakes", cvar = CV_FindVar("rr_quakes"), spacing = FU * 2},
		MenuItem_Button:new{label = "Screenshake Effects", cvar = CV_FindVar("earthquake"), spacing = FU * 2},
		MenuItem_Button:new{label = "Fullbright", cvar = CV_FindVar("fullbrite"), spacing = FU * 2},
		MenuItem_Button:new{label = "Screen Flashes", cvar = CV_FindVar("flashes"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Diagnostic"},
		MenuItem_Button:new{label = "Show FPS", cvar = CV_FindVar("showfps"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show TPS", cvar = CV_FindVar("showtps"), spacing = FU * 2}, --romoney5
		MenuItem_Button:new{label = "Clear Before Redraw", cvar = CV_FindVar("homremoval"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show \"FOCUS LOST\"", cvar = CV_FindVar("showfocuslost"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show Movie Info", cvar = CV_FindVar("moviemodeinfo"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Renderer"},
		MenuItem_Button:new{label = "OpenGL Options...", link = "OptionsMenu_Video", spacing = FU * 2},
		MenuItem_Button:new{label = "FPS Cap", cvar = CV_FindVar("fpscap"), spacing = FU * 2},
		--
	},
}

menus.OptionsMenu_Network = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	
	items = {
		MenuItem_Header:new{label = "General"},
		MenuItem_Button:new{label = "Minimum Delay", cvar = CV_FindVar("mindelay"), spacing = FU * 2},
		MenuItem_Button:new{label = "Gentleman's Delay", cvar = CV_FindVar("gentlemensdelay"), spacing = FU * 2},
		MenuItem_Button:new{label = "Connection Timeout", cvar = CV_FindVar("nettimeout"), spacing = FU * 2},
		MenuItem_Button:new{label = "Network Buffer", cvar = CV_FindVar("netticbuffer"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Server Browser"},
		MenuItem_Button:new{label = "Timeout", cvar = CV_FindVar("masterserver_timeout"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Connection Screen"},
		MenuItem_Button:new{label = "Enable Connection Screen", cvar = CV_FindVar("showserverinfo"), spacing = FU * 2},
		MenuItem_Button:new{label = "Return to Server Browser", cvar = CV_FindVar("returnfromconnect"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Diagnostic"},
		MenuItem_Button:new{label = "Network Statistics", cvar = CV_FindVar("netstat"), spacing = FU * 2},
	},
}

--singleplayer esc menu

local MenuItem_Box = MenuItem:inherit()

function MenuItem_Box:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.label = $ or "Button"
	a.width = $ or FU * 50
	a.height = $ or FU * 50
	a.color = $ or 159
	
	a.x_offset = $ or 0
	
	a.on_draw = $ or nil
	
	return a
end

function MenuItem_Box:getBounds()
	return self.width, self.height
end

function MenuItem_Box:canSelect()
	return false
end

function MenuItem_Box:draw(x, y)
	local width, height = self:getBounds()
	x = $ + self.x_offset
	
	v.drawFixedFill(x, y, width, height, self.color)
	
	if self.on_draw then
		self:on_draw(x, y, width, height)
	end
end

menus.SP_MainMenu = Menu:new{
	anchor = {x = "center", y = "center"},
	show_version = true,
	width = FU * 320 - FU * 40 * 2,
	height = FU * 200 - FU * 20 * 2,
	
	items = {
		MenuItem_Box:new{width = FU * 262, height = FU * 54, spacing = FU * 13, x_offset = FU * -8,
		level_title_label = MenuItem_Text:new{colored = true},
		on_draw = function(self, x, y, width, height)
			local info = mapheaderinfo[gamemap]
			
			if not info then return end
			
-- 			v.drawString(x, y, info.lvlttl, 0, "fixed")
			self.level_title_label.label = info.lvlttl.." "..(info.actnum or "")
			self.level_title_label:draw(x + FU * 8, y + FU * 8 - FU)
		end},
		
		MenuItem_Button:new{label = "Pandora's Box..."},
		MenuItem_Button:new{label = "Emblem Hints..."},
		MenuItem_Button:new{label = "Level Select...", spacing = FU * 8},
-- 		MenuItem_Button:new{label = "1  Player", align = "center", link = "SingleplayerMenu"},
		
		MenuItem_Button:new{label = "Continue", link = ""},
		MenuItem_Button:new{label = "Retry", link = ""},
		MenuItem_Button:new{label = "Options", link = "OptionsMenu", spacing = FU * 8},
		
		MenuItem_Button:new{label = "Return to Title", action = function(self)
			return function()
				COM_BufInsertText(nil, "exitgame")
				menuactive = false
			end
		end},
		MenuItem_Button:new{label = "Quit Game", action = function(self)
			return function()
				COM_BufInsertText(nil, "quit")
			end
		end},
	},
}

return menus