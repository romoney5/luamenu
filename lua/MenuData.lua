--the actual menu data


local function new_menu(name, data)
	menus[name] = data
	
	return name
end

local quit_msgs = {
	"Eggman's tied explosives\nto your girlfriend, and\nwill activate them if\nyou press the 'Y' key!\nPress 'N' to save her!",
	"What would Tails say if\nhe saw you quitting the game?",
	"Hey!\nWhere do ya think you're goin'?",
	"Forget your studies!\nPlay some more!",
	"You're trying to say you\nlike Sonic 2K6 better than\nthis, right?",
	"Don't leave yet -- there's a\nsuper emerald around that corner!",
	"You'd rather work than play?",
	"Go ahead and leave. See if I care...\n*sniffle*",
	
	"If you leave now,\nEggman will take over the world!",
	"Don't quit!\nThere are animals\nto save!",
	"Aw c'mon, just bop\na few more robots!",
	"Did you get all those Chaos Emeralds?", --mno
	"If you leave, I'll use\nmy spin attack on you!",
	"Don't go!\nYou might find the hidden\nlevels!",
	"Hit the 'N' key, Sonic!\nThe 'N' key!",
	
	"Are you really going to give up?\nWe certainly would never give you up.",
	"Come on, just ONE more netgame!",
	"Press 'N' to unlock\nthe Ultimate Cheat!",
	"Why don't you go back and try\njumping on that house to\nsee what happens?",
	"Every time you press 'Y', an\nSRB2 Developer cries...",
	"You'll be back to play soon, though...\n......right?",
	"Aww, is Egg Rock Zone too\ndifficult for you?",
}

local function OnQuitGame(self)
	ShowPopup("Quit Game", quit_msgs[M_RandomRange(1, #quit_msgs)], {
		{body = "Back", keys = {"n", "escape"}, action = function(self)
			return true
		end},
		{body = "Quit", keys = {"y", "enter"}, action = function(self)
			return function()
				Menu_SetActive(false)
				COM_BufInsertText(nil, "quit")
			end
		end},
	})
end

--some preset menuitem conditions
local function Cond_Singleplayer(self)
	return not multiplayer
end

local function Cond_Multiplayer(self)
	return multiplayer
end

--title screen menu

menus.MainMenu = Menu:new{
	anchor = {x = "center", y = "bottom"},
	show_version = true,
	
	on_entry = function(self, old_menu)
		--reset to 1 Player on pause and set the cursor instantly
		if old_menu then return end
		self.selection = 1
		self:updateItems()
	end,
	
	items = {
		MenuItem_Button:new{label = "1  Player", align = "center", link = "SingleplayerMenu"},
		MenuItem_Button:new{label = "Multiplayer", align = "center", link = "MultiplayerMenu"},
		MenuItem_Button:new{label = "Level Selecttwo...", align = "center", link = "LevelSelect"},
		MenuItem_Button:new{label = "Extras", align = "center", link = "ExtrasMenu"},
		MenuItem_Button:new{label = "Addons", align = "center", link = "AddonsMenu"},
		MenuItem_Button:new{label = "Options", align = "center", link = "OptionsMenu"},
		MenuItem_Button:new{label = "Quit  Game", align = "center", action = OnQuitGame},
	},
}

menus.SingleplayerMenu = Menu:new{
	anchor = {x = "center", y = "bottom"},
	
	items = {
		MenuItem_Button:new{label = "Start Game", align = "center", link = "SingleplayerMenu_StartGame"},
		MenuItem_Button:new{label = "Record Attack", align = "center", link = "SingleplayerMenu_RecordAttack"}, --TODO: fade
		MenuItem_Button:new{label = "NiGHTS Mode", align = "center", link = "SingleplayerMenu_NightsMode"},
		MenuItem_Button:new{label = "Marathon Run", align = "center", link = "SingleplayerMenu_MarathonRun"},
		MenuItem_Button:new{label = "Tutorial", align = "center", link = "SingleplayerMenu_Tutorial"}, --action
		MenuItem_Button:new{label = "Statistics", align = "center", link = "SingleplayerMenu_Statistics"},
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
		
		local x = FU * 160 - no_save.width * scale / 2 - self.save_scroll
		local y = FU * 100 - no_save.height * scale / 2
		v.drawScaled(x, y, scale, no_save)
		v.drawString(x + FU * 2, y + FU, "Yes File!", V_ALLOWLOWERCASE, "fixed")
	end,
	
	on_input = function(self, key, name)
		local scrollby = 0
		if name == "right arrow" then scrollby = 1 end
		if name == "left arrow" then scrollby = -1 end
		
		if scrollby then
			self.save_select = $ + scrollby
			self.save_scroll = $ + scrollby * FU * 100
			
			S_StartSound(nil, sfx_s3kb7)
		end
		
		--M_LoadSelect
		if name == "enter" then
			Menu_GotoLink("SingleplayerMenu_StartGame_CharSelect")
		end
		
		return true
	end,
}

menus.SingleplayerMenu_StartGame_CharSelect = Menu:new{
	anchor = {x = "center", y = "bottom"},
	
	items = {
	},
	
	on_entry = function(self, old_menu)
		S_ChangeMusic("_chsel", true)
	end,
	
	on_exit = function(self, old_menu)
		S_ChangeMusic("_title", false)
	end,
	
	char_selection = 0,
	char_scroll = 0,
	time = 0,
	
	on_draw = function(self, v)
		local skin = skins[self.char_selection]
		local color
		
		if skin.prefoppositecolor then
			color = skincolors[skin.prefoppositecolor]
		else
			color = skincolors[skincolors[skin.prefcolor].invcolor]
		end
		
		local colormap = v.getColormap(nil, #color)
		local charbg = v.cachePatch("CHARBG")
		local charfg = v.cachePatch("CHARFG")
		
		if abs(self.char_scroll) > FU / 4 then
			self.char_scroll = $ - FixedMul(self.char_scroll / 4, v.renderdeltatics())
		else
			self.char_scroll = 0
		end
		
		v.drawFill(0, 0, 320, 200, color.ramp[0 + 5])
		
		v.drawFill(0, 0, (v.width() - (320 * v.dupx())) / 2, v.height(), color.ramp[0 + 5 + 5]|V_NOSCALESTART)
		
		self.time = $ + v.renderdeltatics()
		local y = (self.time / FU) % 32
		
		for i = -1, 1 do
			v.draw(0, y + charbg.height * i, charbg, V_SNAPTOTOP, colormap)
		end
		
		for i = -1, 1 do
			v.draw(0, -y + charfg.height * i, charfg, V_SNAPTOTOP, colormap)
		end
		
		v.drawFill(charfg.width, 0, v.width(), v.height(), color.ramp[0 + 5 + 5]|V_SNAPTOTOP)
	end,
	
	on_input = function(self, key, name)
		local scrollby = 0
		if name == "down arrow" then scrollby = 1 end
		if name == "up arrow" then scrollby = -1 end
		
		if scrollby then
			self.char_selection = $ + scrollby
			
			S_StartSound(nil, sfx_s3kb7)
		end
		
		--M_LoadSelect
		
		return true
	end,
}

menus.MultiplayerMenu = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "MULTIPLAYER",
	
-- 	on_entry = ClearMultiplayer,
	
	items = {
		MenuItem_Header:new{label = "Join a game"},
		MenuItem_Button:new{label = "Server browser...", link = "ServerBowser", spacing = FU * 2},
		MenuItem_Textbox:new{label = "Specify server address:", action = function(self)
			serv_connect(self.value)
		end, spacing = FU * 2},
		MenuItem_Button:new{label = "Rejoin previous servers...", link = "MultiplayerMenu_Rejoin", spacing = FU * 2}, --srb2-edit
		
		MenuItem_Header:new{label = "Host a game"},
		MenuItem_Button:new{label = "Internet/LAN...", link = "MultiplayerMenu_HostInternet", spacing = FU * 2},
		MenuItem_Button:new{label = "Splitscreen...", link = "MultiplayerMenu_HostSplitscreen", spacing = FU * 2},
		
		MenuItem_Header:new{label = "Player setup"},
		MenuItem_Button:new{label = "Player 1...", link = "MultiplayerMenu_P1Setup", spacing = FU * 2},
		MenuItem_Button:new{label = "Player 2...", link = "MultiplayerMenu_P2Setup", spacing = FU * 2},
	},
}

menus.MultiplayerMenu_HostInternet = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "MULTIPLAYER",
	
	map_name = "MAP01",
	
	items = {
		MenuItem_Header:new{label = "Server settings"},
		MenuItem_Button:new{label = "Room...", link = "ServerBowser", spacing = FU * 2},
		MenuItem_Textbox:new{label = "Server Name", desc = "Server name as seen in the Master Server", cvar = CV_FindVar("servername"), spacing = FU * 2},
		MenuItem_Button:new{label = "Max Players", desc = "Maximum amount of players in the server", cvar = CV_FindVar("maxplayers"), spacing = FU * 2},
		MenuItem_Button:new{label = "Allow Add-on Downloading", cvar = CV_FindVar("downloading"), spacing = FU * 2 + FU * 10},
		--awkward spacing
		MenuItem_Header:new{label = "Co-op - Greenflower Zone 1"}, --on_entry
		MenuItem_Button:new{label = "Select Gametype/Level...", link = "LevelSelect",
		link_params = function(self, menu)
			--kinda convoluted but it lets me take advantage of
			--lua's ridiculously good scope features
			return {
				on_select = function(id)
					menu:back()
					
					self.parent.map_name = G_BuildMapName(id)
				end
			}
		end,
		on_draw = function(self, x, y)
			local width, height = self:getBounds()
			v.drawScaled(x + width + FU * 4, y, FU / 2, v.cachePatch(self.parent.map_name.."P"))
		end, height = FU * 8 + FU * 16, spacing = FU * 2},
		MenuItem_Button:new{label = "More Options...", link = "OptionsMenu_Server", spacing = FU * 2},
		MenuItem_Button:new{label = "Start", action = function(self)
			Banpyura.Luamenu_SetMultiplayer(true, true)
			
			--TODO: this takes weirdly long with wipes 1
			return function()
				Menu_SetActive(false)
				COM_BufInsertText(nil, "map "..self.parent.map_name)
			end
		end, spacing = FU * 2},
	},
}

menus.MultiplayerMenu_Rejoin = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "MULTIPLAYER",
	
-- 	on_entry = ClearMultiplayer,
	
	items = {
		MenuItem_Header:new{label = "Rejoin a server"},
		
		MenuItem_Box:new{width = FU * 280, height = FU * 34, spacing = FU * 4,
			align = "center",
			level_title_label = MenuItem_Text:new{scale = FU, force_lowercase = true,
				label = "Previously joined servers will show up here."},
			
			on_draw = function(box, x, y, width, height)
				local padding = FU * 8
				
				box.level_title_label.parent_width = width - padding * 2
				box.level_title_label:draw(x + padding, y + padding - FU)
			end
		},
		
		MenuItem_Button:new{label = "Server browser...", link = "ServerBowser", spacing = FU * 2},
	},
}

--this is done differently because the vanilla player setup Is A Hack
menus.MultiplayerMenu_P1Setup = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "PLAYER SETUP",
	
-- 	on_entry = ClearMultiplayer,
	
	items = {
-- 		MenuItem_Header:new{label = "Name"},
		MenuItem_Textbox:new{label = "Name", cvar = CV_FindVar("name"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Character", cvar = CV_FindVar("skin"),
		get_skin_num = function(name)
			for skin in skins.iterate do
				if skin.name:lower() == name:lower() then
					return #skin
				end
			end
		end,
		activate = function(self, increment)
			local og_skin = self.cvar.string
			local new_skin
			
			if not skins[og_skin] then
				new_skin = skins[0].name
			else
				while new_skin == nil do--or (og_skin == new_skin--[[ and R_SkinUsable(-1, new_skin)]]) do
					--r_skinusable isn't used here because Of Course They Have To Complicate Things!!
					if new_skin == nil then
						new_skin = og_skin
					end
					
					local num = (self.get_skin_num(new_skin) + increment) % #skins
					if num < 0 then num = #skins - 1 end
					
					new_skin = skins[num].name
				end
			end
			
			Banpyura.CV_ForceSet(self.cvar, new_skin)
		end, spacing = FU * 2},
	},
}


menus.OptionsMenu = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 50 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "OPTIONS",
	
	items = {
		MenuItem_Button:new{label = "Player 1 Controls...", desc = "Change controls for Player 1", link = "OptionsMenu_P1Controls", spacing = FU * 2},
		MenuItem_Button:new{label = "Player 2 Controls...", desc = "Change controls for Player 2", link = "OptionsMenu_P2Controls", spacing = FU * 2}, --no p2 controls right now
		MenuItem_Button:new{label = "Controls per key", desc = "Amount of controls that can be bound to the same key", cvar = CV_FindVar("controlperkey"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Video Options...", desc = "Change video and display settings", link = "OptionsMenu_Video", spacing = FU * 2},
		MenuItem_Button:new{label = "Sound Options...", desc = "Change audio settings", link = "OptionsMenu_Sound", spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Server Options...", desc = "Change server hosting settings", link = "OptionsMenu_Server", spacing = FU * 2 + FU * 10},
		--MenuItem_Button:new{label = "Server Options...?", condition = do return leveltime % 2 end, desc = "Change server hosting settings", link = "OptionsMenu_Server", spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Data Options...", desc = "Manage data, screenshots, etc.", link = "OptionsMenu_Data", spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Menu Options...", desc = "Luamenu-specific settings", link = "OptionsMenu_Luamenu", spacing = FU * 2},
		MenuItem_Button:new{label = "\x81".."Banpyura Options...", desc = "SRB2 Banpyura-specific settings", link = "OptionsMenu_Banpyura", spacing = FU * 2},
	},
}

local function OnOpenGLOptions(self, old_menu)
	if self.cv_renderer.value == 2 then return end
	
	ShowPopup("OpenGL Options", "You are not currently using the OpenGL renderer.\n"
		.."Switch to the OpenGL renderer for these options to take effect.")
end

menus.OptionsMenu_Banpyura = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "BANPYURA OPTIONS",
	
	items = {
		MenuItem_Header:new{label = "Heads-Up Display"},
		MenuItem_Button:new{label = "Screen Fades", desc = "Enable screen transitions", cvar = CV_FindVar("wipes"), spacing = FU * 2}, --romoney5
		MenuItem_Button:new{label = "Screen Flashes", desc = "Enable screen flashes", cvar = CV_FindVar("flashes"), spacing = FU * 2},
-- 		MenuItem_Button:new{label = "Uppercase Menus", desc = "Force uppercase text in menus", cvar = CV_FindVar("menucaps"), spacing = FU * 2}, --banpyura
-- 		MenuItem_Button:new{label = "Menu Highlight Color", desc = "Change the color of highlighted text", cvar = CV_FindVar("menucolor"), spacing = FU * 2}, --srb2-edit, romoney5
-- 		MenuItem_Button:new{label = "Menu Background Color", desc = "Change the color of backgrounds", cvar = CV_FindVar("menubgcolor"), spacing = FU * 2}, --banpyura
		
		MenuItem_Header:new{label = "Level"},
-- 		MenuItem_Button:new{label = "Pitch/Roll Object Rotation", desc = "Rotate objects on slopes", cvar = CV_FindVar("pitchroll-tation"), spacing = FU * 2}, --srb2-edit, romoney5
-- 		MenuItem_Button:new{label = "Ring Racers Screenshakes", desc = "Ring Racers-styled screen shakes", cvar = CV_FindVar("rr_quakes"), spacing = FU * 2}, --srb2-edit, romoney5
		MenuItem_Button:new{label = "Screenshake Effects", desc = "Enable screen shakes", cvar = CV_FindVar("earthquake"), spacing = FU * 2}, --srb2-edit, romoney5
		MenuItem_Slider:new{label = "Minimum Brightness", value_step = 5, desc = "Change minimum sector brightness", cvar = CV_FindVar("r_secbright"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Chat"},
		MenuItem_Button:new{label = "Horizontal Snap", desc = "Horizontal anchor for the chatbox", cvar = CV_FindVar("chatsnapx"), spacing = FU * 2},
		MenuItem_Button:new{label = "Vertical Snap", desc = "Vertical anchor for the chatbox", cvar = CV_FindVar("chatsnapy"), spacing = FU * 2},
		MenuItem_Slider:new{label = "Horizontal Position", desc = "X position for the chatbox", value_step = 2, cvar = CV_FindVar("chatx"), spacing = FU * 2},
		MenuItem_Slider:new{label = "Vertical Position", desc = "Y position for the chatbox", value_step = 2, cvar = CV_FindVar("chaty"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show Char. Limit", cvar = CV_FindVar("chat_showlimit"), spacing = FU * 2},
		MenuItem_Button:new{label = "Clear Text on Exit", cvar = CV_FindVar("chat_clearonexit"), spacing = FU * 2},
		MenuItem_Button:new{label = "Chat Cursor", desc = "Change the style of the chat cursor", cvar = CV_FindVar("chatcursor"), spacing = FU * 2},
		MenuItem_Slider:new{label = "Chat Opacity", cvar = CV_FindVar("chatopacity"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "OpenGL Options...", desc = "Special OpenGL-related settings", link = new_menu("OptionsMenu_Banpyura_OpenGL", Menu:new{
			anchor = {x = "center", y = "top"}, width = FU * 320 - FU * 30 * 2, height = FU * 200 - FU * 20 * 2,
			title = "OPENGL OPTIONS",
			
			cv_renderer = CV_FindVar("renderer"),

			on_entry = OnOpenGLOptions,
			
			items = {
				MenuItem_Header:new{label = "'''''''''''''''''''''''''''"},
				MenuItem_Button:new{label = "Light Dithering", cvar = CV_FindVar("gr_lightdithering"), spacing = FU * 2}, --gks edit
				MenuItem_Button:new{label = "Render distance", cvar = CV_FindVar("gr_renderdistance"), spacing = FU * 2}, --srb2-edit
			},
		}), spacing = FU * 2 + FU * 10},
		
		MenuItem_Header:new{label = "General"},
		MenuItem_Slider:new{label = "Minimum Delay", desc = "Minimum input delay", cvar = CV_FindVar("mindelay"), spacing = FU * 2},
		MenuItem_Button:new{label = "Gentleman's Delay", desc = "As a host, use the lowest player input delay", cvar = CV_FindVar("gentlemensdelay"), spacing = FU * 2},
		MenuItem_Slider:new{label = "Connection Timeout", desc = "Tics of lost connection before disconnecting", value_step = TICRATE, slider_min = 5, slider_max = TICRATE * 20, cvar = CV_FindVar("nettimeout"), spacing = FU * 2},
		MenuItem_Slider:new{label = "Network Buffer", desc = "Tic buffer; higher amounts increase latency but smoothen gameplay", cvar = CV_FindVar("netticbuffer"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Server Browser"},
		MenuItem_Slider:new{label = "Server Browser Timeout", slider_min = 1, slider_max = 20, cvar = CV_FindVar("masterserver_timeout"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Connection Screen"},
		MenuItem_Button:new{label = "Enable Connection Screen", desc = "Show a connection screen before joining a server", cvar = CV_FindVar("showserverinfo"), spacing = FU * 2},
		MenuItem_Button:new{label = "Return to Server Browser", desc = "Return to the Server Browser after disconnecting", cvar = CV_FindVar("returnfromconnect"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Diagnostic"},
		MenuItem_Button:new{label = "Network Statistics", desc = "Show misc. network info", cvar = CV_FindVar("netstat"), spacing = FU * 2},
	},
}

menus.OptionsMenu_Luamenu = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "MENU OPTIONS",
	
	show_version = true,
	
	items = {
		MenuItem_Header:new{label = "Visual"},
		MenuItem_Button:new{label = "Background Decorations", desc = "Show visual decorations in the background", pref = pref_luamenu_bgdecos, spacing = FU * 2},
		MenuItem_Button:new{label = "Animations", desc = "Enable animations when entering pages, scrolling, etc.", pref = pref_luamenu_anims, spacing = FU * 2},
		MenuItem_Button:new{label = "Tooltips", desc = "Show short descriptions of menu options at the bottom", pref = pref_luamenu_tooltips, spacing = FU * 2},
		MenuItem_Button:new{label = "Show Version String", desc = "Show the game version in certain menus", pref = pref_luamenu_showversion, spacing = FU * 2},
		
		MenuItem_Header:new{label = "Personalization"},
		
		MenuItem_Box:new{width = FU * 280, height = FU * 26, spacing = FU * 4,
			align = "center",
			level_title_label = MenuItem_Text:new{scale = FU, force_lowercase = false,
				colored = true, label = "Sample textbox."},
			
			on_draw = function(box, x, y, width, height)
				local padding = FU * 8
				
				box.level_title_label.parent_width = width - padding * 2
				box.level_title_label:draw(x + padding, y + padding - FU)
			end
		},
		
		MenuItem_Button:new{label = "Uppercase Menus", desc = "Force uppercase text in menus", cvar = CV_FindVar("menucaps"), spacing = FU * 2}, --srb2-edit
		MenuItem_Button:new{label = "Highlight Color", desc = "Change the color of highlighted text", cvar = CV_FindVar("menucolor"), spacing = FU * 2}, --srb2-edit, romoney5
		MenuItem_Button:new{label = "Background Color", desc = "Change the color of backgrounds", cvar = CV_FindVar("menubgcolor"), spacing = FU * 2}, --gks edit
		MenuItem_Button:new{label = "Stylized Sliders", desc = "Enable Luamenu-styled sliders", pref = pref_luamenu_sliders, spacing = FU * 2},
		MenuItem_Slider:new{label = "Rounded Corners", desc = "Change the size of rounded corners on boxes", value_step = FU / 4, pref = pref_luamenu_rounded, spacing = FU * 2},
		
		MenuItem_Header:new{label = "Layout"},
		MenuItem_Button:new{label = "Layout Mode", desc = "Choose the interface mode\n* Desktop", pref = pref_luamenu_layoutmode, spacing = FU * 2},
		
		MenuItem_Header:new{label = "Miscellaneous"},
		MenuItem_Button:new{label = "Disable Luamenu...", action = function(self)
			ShowPopup("Disable Luamenu", "Turn off Luamenu?\nYou can turn it on again by running \"luamenu on\".", {
				{body = "Back", keys = {"n", "escape"}, action = function(self)
					return true
				end},
				{body = "Disable", keys = {"y", "enter"}, width = FU * 65, action = function(self)
					CV_Set(cv_luamenu, 0)
					
					return true
				end},
			})
		end, spacing = FU * 2},
		MenuItem_Button:new{label = "Dev Tools...", link = "OptionsMenu_Luamenu_DevTools", spacing = FU * 2},
	},
}

menus.OptionsMenu_Luamenu_DevTools = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "DEV TOOLS",
	
	show_version = true,
	
	items = {
		MenuItem_Header:new{label = "Functionality"},
		MenuItem_Button:new{label = "Verify Menu Links", desc = "",
		verify_menu = function(self, menu, bad, stack)
			for i, v in ipairs(menus[menu].items) do
				if v.link then
					if menus[v.link] then
						if stack >= 32 then
							table.insert(bad, menu..">"..(v.label or ("Item "..i)).." (overflow)")
						else
							self:verify_menu(v.link, bad, stack + 1)
						end
					else
						table.insert(bad, menu..">"..(v.label or ("Item "..i)))
					end
				end
			end
		end,
		action = function(self)
			local bad = {}
			
			for i, menu in pairs(menus) do
				self:verify_menu(i, bad, 1)
			end
			
			ShowPopup("Verify Menu Links", "The following menu items have invalid links:\n\n"..table.concat(bad, "\n"))
			
			current_popup.width = FU * 300
		end, spacing = FU * 2},
		MenuItem_Button:new{label = "Xdf", desc = "Xdf", link = new_menu("OptionsMenu_Xdf", Menu:new{
			anchor = {x = "center", y = "top"},
			width = FU * 320 - FU * 30 * 2,
			height = FU * 200 - FU * 20 * 2,
			title = "XDF",
			
			items = {
				MenuItem_Header:new{label = "Xdf"},
				MenuItem_Button:new{label = "Xdf", desc = "Xdf", cvar = CV_FindVar("xdf") or CV_RegisterVar{name = "xdf", defaultvalue = "Xdf"}, spacing = FU * 2},
			},
		}), spacing = FU * 2},
		MenuItem_Textbox:new{label = "Run Lua", desc = "Run a line of Lua locally using LuainLua",
		action = function(self)
			local success, msg = LIL_Run(consoleplayer, self.value)
			
			if msg then
				ShowPopup(self.label, tostring(msg))
			end
		end, spacing = FU * 2},
		MenuItem_Button:new{label = "Go to Main Menu", desc = "", action = function(self)
			Menu_GotoLink("MainMenu") --this is an action to not trip up verify menu links
		end, spacing = FU * 2},
		
		MenuItem_Header:new{label = "Display"},
		MenuItem_Button:new{label = "Show Internal Option Names", desc = "Show internal names for cvars and prefs", pref = pref_luamenu_debugoptionnames, spacing = FU * 2},
	},
}

local function GetControls(control, secondary)
	local controls
	local control_function = input.gameControlToKeyNum
	
	if secondary then
		control_function = input.gameControl2ToKeyNum
	end
	
	controls = {control_function(control)}
	
	for i, v in ipairs(controls) do
		if v == 0 then
			controls[i] = nil
			
			continue
		end
	end
	
	return controls
end

local function ControlNumsToNames(controls)
	for i, v in ipairs(controls) do
		controls[i] = input.keyNumToName(v)
	end
end

local function ChangeControl(button)
	local popup = ShowPopup(button.label, "Input a new key for \""..button.label.."\"...",
		{{body = "Cancel", keys = {"escape"}, action = function(self) return true end}})
	
	function popup:on_input(key, name)
		if name == self.buttons[1].keys[1] then return end
		
		local secondary = button.parent and button.parent.secondary
		local controls = GetControls(constants["GC_"..button.control], secondary)
		
		function next_action()
			COM_BufInsertText(nil, ("setcontrol%s \"%s\" \"%s\" \"%s\""):format(secondary and "2" or "", button.control, controls[1] or name, name))
		end
		
		S_StartSound(nil, sfx_strpst)
		current_popup = nil
		
		return true
	end
end

local function DrawControl(self, x, y)
	local controls = GetControls(constants["GC_"..self.control], self.parent and self.parent.secondary)
	ControlNumsToNames(controls)
	
	--set the label
	self.text_label.label = table.concat(controls, " and ")
	
	if not #controls then
		self.text_label.label = "---"
	end
end

local function InputControl(self, key, name)
	if name == "backspace" then
		local secondary = self.parent and self.parent.secondary
		
		function next_action()
			COM_BufInsertText(nil, ("setcontrol%s \"%s\" \"%s\" \"%s\""):format(secondary and "2" or "", self.control, "", ""))
		end
		
		S_StartSound(nil, sfx_shldls)
	end
end

menus.OptionsMenu_P1Controls = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 50 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "CONTROL SETUP",
-- 	title = "AY BOY I JUST GOT THE NEW iPHONE\nIT EVEN GOT AN APP TO DESTROY ALL OPPS",
	
	items = {
		MenuItem_Button:new{label = "Control Configuration...", desc = "Change keyboard controls", link = new_menu("OptionsMenu_P1Controls_Keyboard", Menu:new{
			anchor = {x = "center", y = "top"}, width = FU * 320 - FU * 30 * 2, height = FU * 200 - FU * 20 * 2,
			title = "CONTROL SETUP",
			
			items = {
				MenuItem_Text:new{label = "Press Enter to change, Backspace to clear", canSelect = function() return false end, align = "center"},
				
				MenuItem_Header:new{label = "Movement"},
				MenuItem_Button:new{label = "Move Forward", desc = "Move character forward", action = ChangeControl, on_draw = DrawControl, onKeyInput = InputControl, control = "FORWARD", spacing = FU * 2},
			},
		}), spacing = FU * 2},
		MenuItem_Button:new{label = "Mouse Options...", desc = "Change mouse settings", link = new_menu("OptionsMenu_P1Controls_Mouse", Menu:new{
			anchor = {x = "center", y = "top"}, width = FU * 320 - FU * 30 * 2, height = FU * 200 - FU * 20 * 2,
			title = "CONTROL SETUP",
			
			items = {
				MenuItem_Button:new{label = "Use Mouse", desc = "Enable mouse movement", cvar = CV_FindVar("use_mouse"), spacing = FU * 2 + FU * 10},
				
				MenuItem_Button:new{label = "First-Person MouseLook", desc = "Enable looking up/down in first person", cvar = CV_FindVar("alwaysmlook"), spacing = FU * 2},
				MenuItem_Button:new{label = "Third-Person MouseLook", desc = "Enable looking up/down in third person", cvar = CV_FindVar("chasemlook"), spacing = FU * 2},
				MenuItem_Button:new{label = "Mouse Move", desc = "Use the mouse to move the character", cvar = CV_FindVar("mousemove"), spacing = FU * 2},
				MenuItem_Button:new{label = "Invert Y Axis", desc = "Invert vertical mouse movement", cvar = CV_FindVar("invertmouse"), spacing = FU * 2},
				MenuItem_Slider:new{label = "Mouse X Sensitivity", value_step = 2, desc = "Change horizontal mouse sensitivity", cvar = CV_FindVar("mousesens"), spacing = FU * 2},
				MenuItem_Slider:new{label = "Mouse Y Sensitivity", value_step = 2, desc = "Change vertical mouse sensitivity", cvar = CV_FindVar("mouseysens"), spacing = FU * 2 + FU * 10},
			},
		}), spacing = FU * 2},
		MenuItem_Button:new{label = "Gamepad Options...", desc = "Change controller settings", link = new_menu("OptionsMenu_P1Controls_Gamepad", Menu:new{
			anchor = {x = "center", y = "top"}, width = FU * 320 - FU * 50 * 2, height = FU * 200 - FU * 20 * 2,
			title = "CONTROL SETUP",
			
			items = {
				MenuItem_Button:new{label = "Select Gamepad...", desc = "Choose controller", link = new_menu("OptionsMenu_P1Controls_Gamepad_Select", Menu:new{
					--fun fact: this menu is gravely off-centered in vanilla
					anchor = {x = "center", y = "top"}, width = FU * 320 - FU * 50 * 2, height = FU * 200 - FU * 20 * 2,
					title = "CONTROL SETUP",
					
					items = {}, --No
				}), spacing = FU * 2 + FU * 10},
				MenuItem_Button:new{label = "Move \x17 Axis", desc = "Axis for forward movement", cvar = CV_FindVar("joyaxis_move"), spacing = FU * 2},
				MenuItem_Button:new{label = "Move \x18 Axis", desc = "Axis for sideway movement", cvar = CV_FindVar("joyaxis_side"), spacing = FU * 2},
				MenuItem_Button:new{label = "Camera \x17 Axis", desc = "Axis for vertical camera movement", cvar = CV_FindVar("joyaxis_look"), spacing = FU * 2},
				MenuItem_Button:new{label = "Camera \x18 Axis", desc = "Axis for horizontal camera movement", cvar = CV_FindVar("joyaxis_turn"), spacing = FU * 2},
				MenuItem_Button:new{label = "Jump Axis", desc = "Axis for jumping", cvar = CV_FindVar("joyaxis_jump"), spacing = FU * 2},
				MenuItem_Button:new{label = "Spin Axis", desc = "Axis for spinning", cvar = CV_FindVar("joyaxis_spin"), spacing = FU * 2},
				MenuItem_Button:new{label = "Fire Axis", desc = "Axis for the Fire button", cvar = CV_FindVar("joyaxis_fire"), spacing = FU * 2},
				MenuItem_Button:new{label = "Fire Normal Axis", desc = "Axis for the Fire Normal button", cvar = CV_FindVar("joyaxis_firenormal"), spacing = FU * 2 + FU * 10},
				
				MenuItem_Button:new{label = "First-Person Vert-Look", desc = "Enable vertical camera movement in first-person", cvar = CV_FindVar("alwaysmlook"), spacing = FU * 2},
				MenuItem_Button:new{label = "Third-Person Vert-Look", desc = "Enable vertical camera movement in third-person", cvar = CV_FindVar("chasemlook"), spacing = FU * 2},
				MenuItem_Slider:new{label = "Analog Deadzone", desc = "Deadzone for analog (e.g. joystick) buttons", value_step = FU * 5 / 100, cvar = CV_FindVar("joy_deadzone"), spacing = FU * 2},
				MenuItem_Slider:new{label = "Digital Deadzone", desc = "Deadzone for digital (e.g. face button) buttons", value_step = FU * 5 / 100, cvar = CV_FindVar("joy_digdeadzone"), spacing = FU * 2},
			},
		}), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Camera Options...", desc = "Change camera settings", link = new_menu("OptionsMenu_P1Controls_Camera", Menu:new{
			anchor = {x = "center", y = "top"}, width = FU * 320 - FU * 30 * 2, height = FU * 200 - FU * 20 * 2,
			title = "CONTROL SETUP",
			
			items = {
				MenuItem_Header:new{label = "General Toggles"},
				MenuItem_Button:new{label = "Third-person Camera", desc = "Enable third-person camera view", cvar = CV_FindVar("chasecam"), spacing = FU * 2},
				MenuItem_Button:new{label = "Flip Camera with Gravity", desc = "Keep the camera straight in reverse gravity", cvar = CV_FindVar("flipcam"), spacing = FU * 2},
				MenuItem_Button:new{label = "Orbital Looking", desc = "Move the camera in an arc when looking vertically", cvar = CV_FindVar("cam_orbit"), spacing = FU * 2},
				MenuItem_Button:new{label = "Downhill Slope Adjustment", desc = "Raise the camera on downhill slopes", cvar = CV_FindVar("cam_adjust"), spacing = FU * 2},
				
				MenuItem_Header:new{label = "Camera Positioning"},
				MenuItem_Button:new{label = "Camera Distance", desc = "Change the distance of third-person camera", cvar = CV_FindVar("cam_dist"), spacing = FU * 2},
				MenuItem_Button:new{label = "Camera Height", desc = "Change the height of third-person camera", cvar = CV_FindVar("cam_height"), spacing = FU * 2},
				MenuItem_Slider:new{label = "Camera Spacial Speed", desc = "Change the following speed of third-person camera", cvar = CV_FindVar("cam_speed"), spacing = FU * 2},
				MenuItem_Slider:new{label = "Rotation Speed", desc = "Change the speed of left/right arrow keys", cvar = CV_FindVar("cam_turnmultiplier"), spacing = FU * 2},
				
				MenuItem_Header:new{label = "Display Options"},
				MenuItem_Button:new{label = "Crosshair", desc = "Show a crosshair at the center in first-person", cvar = CV_FindVar("crosshair"), spacing = FU * 2},
				MenuItem_Button:new{label = "Inverted Crosshair", desc = "Invert the crosshair's color against the background", cvar = CV_FindVar("crosshair_invert"), spacing = FU * 2},
				
-- 				MenuItem_Header:new{label = "Miscellaneous"},
-- 				MenuItem_Button:new{label = "Exact Camera", desc = "Enable precise third-person camera movement", cvar = CV_FindVar("cam_exact"), spacing = FU * 2}, --romoney5
-- 				MenuItem_Button:new{label = "Clipping Style", desc = "Change third-person camera clipping behavior", cvar = CV_FindVar("cam_clipping"), spacing = FU * 2}, --romoney5
			},
		}), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Automatic braking", desc = "Skid to a stop automatically", cvar = CV_FindVar("autobrake"), spacing = FU * 2},
		MenuItem_Button:new{label = "Play Style...", desc = "Change the game's control style", link = "a", spacing = FU * 2},
	},
}

menus.OptionsMenu_Video = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "VIDEO OPTIONS",
	
	items = {
		MenuItem_Header:new{label = "Screen"},
		MenuItem_Button:new{label = "Set Resolution...", desc = "Change game resolution", link = "OptionsMenu_Video_Resolution", spacing = FU * 2},
		MenuItem_Button:new{label = "Fullscreen (F11)", desc = "Enable fullscreen mode", cvar = CV_FindVar("fullscreen"), spacing = FU * 2},
		MenuItem_Button:new{label = "Vertical Sync", desc = "Eliminate screen tearing at the cost of higher latency", cvar = CV_FindVar("vid_wait"), spacing = FU * 2},
		MenuItem_Button:new{label = "Renderer (F10)", desc = "Switch the game's renderer", cvar = CV_FindVar("renderer"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Color Profile"},
		MenuItem_Slider:new{label = "Brightness", cvar = CV_FindVar("gamma"), spacing = FU * 2},
		MenuItem_Slider:new{label = "Saturation", cvar = CV_FindVar("saturation"), spacing = FU * 2},
		MenuItem_Button:new{label = "Advanced Settings...", desc = "Advanced color settings", link = "OptionsMenu_Video_Color", spacing = FU * 2},
		
		MenuItem_Header:new{label = "Heads-Up Display"},
		MenuItem_Button:new{label = "Show HUD", cvar = CV_FindVar("showhud"), spacing = FU * 2},
		MenuItem_Slider:new{label = "HUD Transparency", cvar = CV_FindVar("translucenthud"), spacing = FU * 2},
		MenuItem_Button:new{label = "Score/Time/Rings", desc = "Change the timer's style", cvar = CV_FindVar("timerres"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show Powerups", desc = "Show active powerups at the bottom-right corner", cvar = CV_FindVar("powerupdisplay"), spacing = FU * 2},
		MenuItem_Button:new{label = "Local Ping Display", desc = "Show ping at the bottom-right corner", cvar = CV_FindVar("showping"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show Player Names", desc = "Show player names when looking at them", cvar = CV_FindVar("seenames"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Console"},
		MenuItem_Button:new{label = "Background Color", cvar = CV_FindVar("con_backcolor"), spacing = FU * 2},
		MenuItem_Button:new{label = "Text Size", cvar = CV_FindVar("con_textsize"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Chat"},
		MenuItem_Button:new{label = "Chat Mode", cvar = CV_FindVar("chatmode"), spacing = FU * 2},
		MenuItem_Slider:new{label = "Chat Box Width", value_step = 5, cvar = CV_FindVar("chatwidth"), spacing = FU * 2},
		MenuItem_Slider:new{label = "Chat Box Height", cvar = CV_FindVar("chatheight"), spacing = FU * 2},
		MenuItem_Button:new{label = "Message Fadeout Time", cvar = CV_FindVar("chattime"), spacing = FU * 2},
		MenuItem_Button:new{label = "Chat Notifications", desc = "Enable chat sounds", cvar = CV_FindVar("chatnotifications"), spacing = FU * 2},
		MenuItem_Button:new{label = "Spam Protection", desc = "Block spammed chat messages", cvar = CV_FindVar("chatspamprotection"), spacing = FU * 2},
		MenuItem_Button:new{label = "Chat background tint", cvar = CV_FindVar("chatbacktint"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Level"},
		MenuItem_Button:new{label = "Draw Distance", desc = "Change render distance of objects", cvar = CV_FindVar("drawdist"), spacing = FU * 2},
		MenuItem_Button:new{label = "Weather Draw Dist.", cvar = CV_FindVar("drawdist_precip"), spacing = FU * 2},
		MenuItem_Button:new{label = "NiGHTS Hoop Draw Dist.", cvar = CV_FindVar("drawdist_nights"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Diagnostic"},
		MenuItem_Button:new{label = "Show FPS", desc = "Show render frames per second", cvar = CV_FindVar("showfps"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show TPS", desc = "Show game tics per second", cvar = CV_FindVar("showtps"), spacing = FU * 2}, --srb2-edit
		MenuItem_Button:new{label = "Clear Before Redraw", desc = "Alleviate out-of-bounds visual glitches in Software", cvar = CV_FindVar("homremoval"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show \"FOCUS LOST\"", cvar = CV_FindVar("showfocuslost"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show Movie Info", desc = "Show info when recording movies", cvar = CV_FindVar("moviemodeinfo"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Renderer"},
		MenuItem_Button:new{label = "OpenGL Options...", link = "OptionsMenu_Video_OpenGL", spacing = FU * 2},
		MenuItem_Button:new{label = "FPS Cap", cvar = CV_FindVar("fpscap"), spacing = FU * 2},
	},
}

menus.OptionsMenu_Video_Resolution = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "VIDEO OPTIONS",
	
	items = {
		MenuItem_Button:new{label = "Do nothing", desc = "It actually does nothing", action = nil, spacing = FU * 2},
	},
}

local function ResetCvars(self)
	if not self.parent then return end
	
	for i, v in ipairs(self.parent.items) do
		if v.cvar then
			Banpyura.CV_ForceSet(v.cvar, v.cvar.defaultvalue)
			--tonumber(v.cvar.defaultvalue)?
		end
	end
end

menus.OptionsMenu_Video_Color = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "VIDEO OPTIONS",
	
	items = {
		MenuItem_Button:new{label = "Reset to defaults", action = ResetCvars, spacing = FU * 2},
		
		(function(colors)
			local out = {}
			
			for i, color in ipairs(colors) do
				table.insert(out, MenuItem_Header:new{label = color[1], color = color[2]})
				table.insert(out, MenuItem_Slider:new{label = "Hue", cvar = CV_FindVar(color[3].."hue"), spacing = FU * 2})
				table.insert(out, MenuItem_Slider:new{label = "Saturation", cvar = CV_FindVar(color[3].."saturation"), spacing = FU * 2})
				table.insert(out, MenuItem_Slider:new{label = "Brightness", cvar = CV_FindVar(color[3].."gamma"), spacing = FU * 2})
			end
			
			return unpack(out)
		end){
				--header name, header color, cvar prefix
				{"Red", V_REDMAP, "r"},
				{"Yellow", V_YELLOWMAP, "y"},
				{"Green", V_GREENMAP, "g"},
				{"Cyan", V_AQUAMAP, "c"},
				{"Blue", V_BLUEMAP, "b"},
				{"Magenta", V_MAGENTAMAP, "m"},
			},
	},
}

menus.OptionsMenu_Video_OpenGL = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "OPENGL OPTIONS", --"VIDEO OPTIONS",
	
	cv_renderer = CV_FindVar("renderer"),
	
	on_entry = OnOpenGLOptions,
	
	items = {
		MenuItem_Header:new{label = "3D Models"},
		MenuItem_Button:new{label = "Models", cvar = CV_FindVar("gr_models"), spacing = FU * 2},
		MenuItem_Button:new{label = "Frame interpolation", cvar = CV_FindVar("gr_modelinterpolation"), spacing = FU * 2},
		MenuItem_Button:new{label = "Ambient lighting", cvar = CV_FindVar("gr_modellighting"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "General"},
		MenuItem_Button:new{label = "Shaders", cvar = CV_FindVar("gr_shaders"), spacing = FU * 2},
		MenuItem_Button:new{label = "Palette rendering", cvar = CV_FindVar("gr_paletterendering"), spacing = FU * 2},
		MenuItem_Button:new{label = "Lack of perspective", cvar = CV_FindVar("gr_shearing"), spacing = FU * 2},
		MenuItem_Button:new{label = "Field of view", cvar = CV_FindVar("fov"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Miscellaneous"},
		MenuItem_Button:new{label = "Bit depth", cvar = CV_FindVar("scr_depth"), spacing = FU * 2},
		MenuItem_Button:new{label = "Texture filter", cvar = CV_FindVar("gr_filtermode"), spacing = FU * 2},
		MenuItem_Button:new{label = "Anisotropic", cvar = CV_FindVar("gr_anisotropicmode"), spacing = FU * 2},
	},
}

menus.OptionsMenu_Sound = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "SOUND OPTIONS",
	
	items = {
		MenuItem_Header:new{label = "Game Audio"},
		MenuItem_Button:new{label = "Sound Effects", cvar = CV_FindVar("sounds"), spacing = FU * 2},
		MenuItem_Slider:new{label = "Sound Volume", cvar = CV_FindVar("soundvolume"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Digital Music", cvar = CV_FindVar("digimusic"), spacing = FU * 2},
		MenuItem_Slider:new{label = "Digital Music Volume", cvar = CV_FindVar("digmusicvolume"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "MIDI Music", cvar = CV_FindVar("midimusic"), spacing = FU * 2},
		MenuItem_Slider:new{label = "MIDI Music Volume", desc = "Does not work with Windows native MIDI", cvar = CV_FindVar("midimusicvolume"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Music Preference", cvar = CV_FindVar("musicpref"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Miscellaneous"},
		MenuItem_Button:new{label = "Closed Captioning", cvar = CV_FindVar("closedcaptioning"), spacing = FU * 2},
		MenuItem_Button:new{label = "Reset Music Upon Dying", cvar = CV_FindVar("resetmusic"), spacing = FU * 2},
		MenuItem_Button:new{label = "Default 1-Up sound", cvar = CV_FindVar("1upsound"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Advanced Settings...", link = new_menu("OptionsMenu_Sound_Advanced", Menu:new{
			anchor = {x = "center", y = "top"}, width = FU * 320 - FU * 30 * 2, height = FU * 200 - FU * 20 * 2,
			title = "SOUND OPTIONS",
			
			items = {
				--ifdef HAVE_OPENMPT
				MenuItem_Header:new{label = "OpenMPT Settings"},
				MenuItem_Button:new{label = "Instrument Filter", desc = "Only available if compiled with OpenMPT", cvar = CV_FindVar("modfilter"), spacing = FU * 2},
				
				--ifdef HAVE_MIXERX
				MenuItem_Header:new{label = "MIDI Settings"},
				MenuItem_Button:new{label = "MIDI Player", desc = "Only available if compiled with SDL-Mixer-X", cvar = CV_FindVar("midiplayer"), spacing = FU * 2},
				MenuItem_Textbox:new{label = "FluidSynth Sound Font File", desc = "Only available if compiled with SDL-Mixer-X", cvar = CV_FindVar("midisoundfont"), spacing = FU * 2},
				MenuItem_Textbox:new{label = "TiMidity++ Config Folder", desc = "Only available if compiled with SDL-Mixer-X", cvar = CV_FindVar("midisoundbank"), spacing = FU * 2},
				
				MenuItem_Header:new{label = "Miscellaneous"},
				MenuItem_Button:new{label = "Play Sound Effects if Unfocused", cvar = CV_FindVar("playsoundsifunfocused"), spacing = FU * 2},
				MenuItem_Button:new{label = "Play Music if Unfocused", cvar = CV_FindVar("playmusicifunfocused"), spacing = FU * 2},
				MenuItem_Button:new{label = "Let Levels Force Reset Music", desc = "Allow some levels to reset music on restart", cvar = CV_FindVar("resetmusicbyheader"), spacing = FU * 2},
			},
		}), spacing = FU * 2},
	},
}

menus.OptionsMenu_Server = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "SERVER OPTIONS",
	
	items = {
		MenuItem_Header:new{label = "General"},
		MenuItem_Textbox:new{label = "Server name", desc = "Server name as seen in the Master Server", cvar = CV_FindVar("servername"), spacing = FU * 2},
		MenuItem_Button:new{label = "Max Players", desc = "Maximum amount of players in the server", cvar = CV_FindVar("maxplayers"), spacing = FU * 2},
		MenuItem_Button:new{label = "Allow Add-on Downloading", cvar = CV_FindVar("downloading"), spacing = FU * 2},
		MenuItem_Button:new{label = "Allow players to join", cvar = CV_FindVar("allowjoin"), spacing = FU * 2},
		MenuItem_Button:new{label = "Minutes for reconnecting", desc = "Minutes that a player is given to reconnect", cvar = CV_FindVar("rejointimeout"), spacing = FU * 2},
		MenuItem_Button:new{label = "Map progression", desc = "How levels should progress", cvar = CV_FindVar("advancemap"), spacing = FU * 2},
		MenuItem_Button:new{label = "Intermission Timer", desc = "Time spent in level end/intermission", cvar = CV_FindVar("inttime"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Characters"},
		MenuItem_Button:new{label = "Force a character", cvar = CV_FindVar("forceskin"), spacing = FU * 2},
		MenuItem_Button:new{label = "Restrict character changes", desc = "Toggle skin change restrictions in competitive gametypes", cvar = CV_FindVar("restrictskinchange"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Items"},
		MenuItem_Button:new{label = "Item respawn delay", desc = "Seconds until items (e.g. monitors) respawn", cvar = CV_FindVar("respawnitemtime"), spacing = FU * 2},
		MenuItem_Button:new{label = "Mystery Item Monitor Toggles...", desc = "Item monitor chances for competitive gametypes", link = "OptionsMenu_Server_Monitors", spacing = FU * 2}, --TODO
		
		MenuItem_Header:new{label = "Cooperative"},
		MenuItem_Button:new{label = "Players required for exit", desc = "Fraction of finished players to advance the level", cvar = CV_FindVar("playersforexit"), spacing = FU * 2},
		MenuItem_Button:new{label = "Starposts", desc = "Starpost collection type", cvar = CV_FindVar("coopstarposts"), spacing = FU * 2},
		MenuItem_Button:new{label = "Life sharing", desc = "Life sharing type", cvar = CV_FindVar("cooplives"), spacing = FU * 2},
		MenuItem_Button:new{label = "Post-goal free roaming", desc = "Allow players to move after reaching the goal", cvar = CV_FindVar("exitmove"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Race, Competition"},
		MenuItem_Button:new{label = "Level completion countdown", cvar = CV_FindVar("countdowntime"), spacing = FU * 2},
		MenuItem_Button:new{label = "Item Monitors", cvar = CV_FindVar("competitionboxes"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Ringslinger (Match, CTF, Tag, H&S)"},
		MenuItem_Button:new{label = "Time Limit", cvar = CV_FindVar("timelimit"), spacing = FU * 2},
		MenuItem_Button:new{label = "Score Limit", cvar = CV_FindVar("pointlimit"), spacing = FU * 2},
		MenuItem_Button:new{label = "Overtime on Tie", desc = "Go into overtime if players are tied", cvar = CV_FindVar("overtime"), spacing = FU * 2},
		MenuItem_Button:new{label = "Player respawn delay", cvar = CV_FindVar("respawndelay"), spacing = FU * 2},
		
		MenuItem_Button:new{label = "Item Monitors", cvar = CV_FindVar("matchboxes"), spacing = FU * 2},
		MenuItem_Button:new{label = "Weapon Rings", cvar = CV_FindVar("specialrings"), spacing = FU * 2},
		MenuItem_Button:new{label = "Power Stones", cvar = CV_FindVar("powerstones"), spacing = FU * 2},
		
		MenuItem_Button:new{label = "Flag respawn delay", cvar = CV_FindVar("flagtime"), spacing = FU * 2},
		MenuItem_Button:new{label = "Hiding time", cvar = CV_FindVar("hidetime"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Teams"},
		MenuItem_Button:new{label = "Autobalance sizes", cvar = CV_FindVar("autobalance"), spacing = FU * 2},
		MenuItem_Button:new{label = "Scramble on Map Change", cvar = CV_FindVar("scrambleonchange"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Advanced"},
		MenuItem_Textbox:new{label = "Master server", desc = "Address of Master Server", cvar = CV_FindVar("masterserver"), spacing = FU * 2},
		MenuItem_Button:new{label = "Join delay", desc = "Delay when too many players join at once", cvar = CV_FindVar("joindelay"), spacing = FU * 2},
		MenuItem_Button:new{label = "Attempts to resynchronise", desc = "Toggle resynchs (values above 1 make no difference)", cvar = CV_FindVar("resynchattempts"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show IP Address of Joiners", desc = "Print IP address of joining players", cvar = CV_FindVar("showjoinaddress"), spacing = FU * 2},
		--romoney5
		MenuItem_Button:new{label = "Download Speed", desc = "File downloading speed", cvar = CV_FindVar("downloadspeed"), spacing = FU * 2},
		MenuItem_Button:new{label = "Maximum File Size", desc = "Max. size of a file the server will send", cvar = CV_FindVar("maxsend"), spacing = FU * 2},
		
-- 		MenuItem_Button:new{label = "Advanced", desc = "", link = "OptionsMenu_Server_Advanced", spacing = FU * 2}, --romoney5
	},
}

local function MonitorDraw(self, x, y)
	if not self.cvar or not self.parent then return end
	
	local display = FixedDiv(FU * self.cvar.value, FU * self.parent.sum or 1) * 100
	display = FixedDecimal(display, display >= FU * 100 and 1 or 2).."%"

	v.drawString(x + self.parent.width + FU * 50, y, display, 0, "fixed-right")
end

menus.OptionsMenu_Server_Monitors = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 50 * 2,
	height = FU * 200 - FU * 20 * 2,
	x_offset = -FU * 20,
	title = "SERVER OPTIONS",
	
	sum = 0,
	
	on_draw = function(self, v)
		self.sum = 0
		
		for i, item in ipairs(self.items) do
			if not item.cvar then continue end
			
			self.sum = $ + item.cvar.value
		end
	end,
	
	on_entry = function(self, old_menu)
		--update the sum
		self:on_draw()
	end,
	
	items = {
		MenuItem_Button:new{label = "Reset to defaults", action = ResetCvars, spacing = FU * 2 + FU * 10},
		
		--a generator is not worth it here
		MenuItem_Slider:new{label = "Recycler", cvar = CV_FindVar("tv_recycler"), on_draw = MonitorDraw, spacing = FU * 2},
		MenuItem_Slider:new{label = "Teleport", cvar = CV_FindVar("tv_teleporter"), on_draw = MonitorDraw, spacing = FU * 2},
		MenuItem_Slider:new{label = "Super Ring", cvar = CV_FindVar("tv_superring"), on_draw = MonitorDraw, spacing = FU * 2},
		MenuItem_Slider:new{label = "Super Sneakers", cvar = CV_FindVar("tv_supersneaker"), on_draw = MonitorDraw, spacing = FU * 2},
		MenuItem_Slider:new{label = "Invincibility", cvar = CV_FindVar("tv_invincibility"), on_draw = MonitorDraw, spacing = FU * 2},
		MenuItem_Slider:new{label = "Whirlwind Shield", cvar = CV_FindVar("tv_jumpshield"), on_draw = MonitorDraw, spacing = FU * 2},
		MenuItem_Slider:new{label = "Elemental Shield", cvar = CV_FindVar("tv_watershield"), on_draw = MonitorDraw, spacing = FU * 2},
		MenuItem_Slider:new{label = "Attraction Shield", cvar = CV_FindVar("tv_ringshield"), on_draw = MonitorDraw, spacing = FU * 2},
		MenuItem_Slider:new{label = "Force Shield", cvar = CV_FindVar("tv_forceshield"), on_draw = MonitorDraw, spacing = FU * 2},
		MenuItem_Slider:new{label = "Armageddon Shield", cvar = CV_FindVar("tv_bombshield"), on_draw = MonitorDraw, spacing = FU * 2},
		--srb2 monitor names try not to be inaccurate challenge (impossible)
		MenuItem_Slider:new{label = "1 Up", cvar = CV_FindVar("tv_1up"), on_draw = MonitorDraw, spacing = FU * 2},
		MenuItem_Slider:new{label = "Eggman Box", cvar = CV_FindVar("tv_eggman"), on_draw = MonitorDraw, spacing = FU * 2},
	},
}

--singleplayer esc menu

local function OnReturnToTitle(self)
	ShowPopup("Return to Title", "Return to the title screen?", {
		{body = "Back", keys = {"n", "escape"}, action = function(self)
			return true
		end},
		{body = "OK", keys = {"y", "enter"}, action = function(self)
			return function()
				Menu_SetActive(false)
				COM_BufInsertText(nil, "exitgame")
			end
		end},
	})
end

local function OnRetry(self)
	ShowPopup("Retry", "Retry the level from the last checkpoint?", {
		{body = "Back", keys = {"n", "escape"}, action = function(self)
			return true
		end},
		{body = "Retry", keys = {"y", "enter"}, action = function(self)
			return function()
				Menu_SetActive(false)
				COM_BufInsertText(nil, "retry")
			end
		end},
	})
end

menus.SP_MainMenu = Menu:new{
	anchor = {x = "center", y = "center"},
	show_version = true,
	width = FU * 320 - FU * 40 * 2,
	height = FU * 200 - FU * 20 * 2,
	
	on_entry = function(self, old_menu)
		--reset to Continue on pause and set the cursor instantly
		if old_menu then return end
		self.selection = 5
		self:updateItems()
	end,
	
	items = {
		MenuItem_Box:new{width = FU * 262, height = FU * 54, spacing = FU * 13,
			align = "center",
			level_title_label = MenuItem_Text:new{colored = true},
			on_draw = function(self, x, y, width, height)
				local info = mapheaderinfo[gamemap]
				
				if not info then return end
				
	-- 			v.drawString(x, y, info.lvlttl, 0, "fixed")
				self.level_title_label.label = info.lvlttl.." "..(info.actnum or "")
				self.level_title_label:draw(x + FU * 8, y + FU * 8 - FU)
			end},
		
		MenuItem_Button:new{label = "Pandora's Box...", link = "SP_PandorasBox", condition = Cond_Singleplayer},
		MenuItem_Button:new{label = "Emblem Hints...", link = "SP_EmblemHints"},
		MenuItem_Button:new{label = "Level Select...", link = "LevelSelect",
		link_params = function(self, menu)
			return {
				on_select = function(id)
					--what the bigma
					function next_action()
						Menu_SetActive(false)
						COM_BufInsertText(nil, "map "..id)
					end
				end
			}
		end, spacing = FU * 8},
		
		MenuItem_Button:new{label = "Continue", link = ""},
		MenuItem_Button:new{label = "Retry", action = OnRetry, condition = Cond_Singleplayer},
		MenuItem_Button:new{label = "Player Setup", link = "MultiplayerMenu_P1Setup", condition = Cond_Multiplayer},
		MenuItem_Button:new{label = "Options", link = "OptionsMenu", spacing = FU * 8},
		
		MenuItem_Button:new{label = "Return to Title", action = OnReturnToTitle},
		MenuItem_Button:new{label = "Quit Game", action = OnQuitGame},
	},
}

local function DestroyRobots()
	local mo = consoleplayer.realmo
	
	for mobj in mobjs.iterate() do
		if mobj.health <= 0 or not (mobj.flags & (MF_ENEMY|MF_BOSS)) then
			continue
		end
		
		if mobj.type == MT_PLAYER then
			continue
		end
		
		P_KillMobj(mobj, mo, mo, 0)
	end
end

--why not use ring racers/2.3's hwr2 backend
menus.SP_PandorasBox = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 50 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "PANDORA'S BOX",
	
	on_entry = function(self, old_menu)
-- 		S_ChangeMusic("_title", false)
	end,
	
	on_exit = function(self, old_menu)
-- 		S_ChangeMusic("_title", false)
	end,
	
	items = {
		MenuItem_Button:new{label = "Mid-game add-ons...", desc = "Load add-ons mid-game", link = "AddonsMenu", spacing = FU * 2 + FU * 10},
		
		--TODO: these should use luamenu preferences
		MenuItem_Button:new{label = "Rings", desc = "Set rings", cvar = CV_FindVar("dummyrings"), spacing = FU * 2},
		MenuItem_Button:new{label = "Lives", desc = "Set lives", cvar = CV_FindVar("dummylives"), spacing = FU * 2},
		MenuItem_Button:new{label = "Continues", desc = "Set continues", cvar = CV_FindVar("dummycontinues"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Gravity", desc = "Change gravity", cvar = CV_FindVar("gravity"), spacing = FU * 2},
		MenuItem_Button:new{label = "Throw Rings", desc = "Enable ringslinger", cvar = CV_FindVar("ringslinger"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Enable Super form", desc = "", action = function(self)
			--assume consoleplayer exists
			if netgame or not consoleplayer then return end
			
			G_SetUsedCheats(false)
			consoleplayer.charflags = $ | SF_SUPER
			
			ShowPopup(self.label, "You are now capable of turning super.\nRemember to get all the emeralds!")
		end, spacing = FU * 2},
		MenuItem_Button:new{label = "Get All Emeralds", desc = "", action = function(self)
			--assume consoleplayer exists
			if netgame or not consoleplayer then return end
			
			G_SetUsedCheats(false)
			emeralds = EMERALD7 * 2 - 1
			
			ShowPopup(self.label, "You now have all 7 emeralds.\nUse them wisely.\nWith great power comes great ring drain.")
		end, spacing = FU * 2},
		MenuItem_Button:new{label = "Destroy All Robots", desc = "", action = function(self)
			--assume consoleplayer exists
			if netgame or not consoleplayer then return end
			
			ShowPopup(self.label, "Do you want to destroy all\nrobots in the current level?", {
				{body = "No", keys = {"n", "escape"}, action = function(self)
					return true
				end},
				{body = "Yes", keys = {"y", "enter"}, action = function(self)
					return function()
						G_SetUsedCheats(false)
						current_popup:close()
						
						--for some cool reason P_DestroyRobots isn't exposed, so..
						DestroyRobots()
						
						return true
					end
				end},
			})
		end, spacing = FU * 2},
		
		MenuItem_Button:new{label = "Ultimate Cheat", desc = "", action = function(self)
			Menu_SetActive(false)
			COM_BufInsertText(nil, "quit")
		end, spacing = FU * 2},
	},
}
