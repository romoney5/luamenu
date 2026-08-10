--the actual menu data
local menus, v = ...
loadfile("MenuData_Server.lua")(menus, v)

local function new_menu(name, data)
	menus[name] = data
	
	return name
end

--title screen menu

menus.MainMenu = Menu:new{
	anchor = {x = "center", y = "bottom"},
	show_version = true,
	
	items = {
		MenuItem_Button:new{label = "1  Player", align = "center", link = "SingleplayerMenu"},
		MenuItem_Button:new{label = "Multiplayer", align = "center", link = "MultiplayerMenu"},
		MenuItem_Button:new{label = "Extras", align = "center", link = "ExtrasMenu"},
		MenuItem_Button:new{label = "Addons", align = "center", link = "AddonsMenu"},
		MenuItem_Button:new{label = "Options", align = "center", link = "OptionsMenu"},
		MenuItem_Button:new{label = "Quit  Game", align = "center", action = function(self)
-- 			return function()
-- 				COM_BufInsertText(nil, "quit")
-- 			end
			ShowPopup("Sonic final dmeo", "Did you get all those Chaos Emeralds?")
		end},
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
		S_ChangeMusic("_title")
	end,
	
	char_scroll = 0,
	time = 0,
	
	on_draw = function(self, v)
		local skin = skins[0]
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
			self.char_scroll = $ - FixedMul(self.char_scroll / 4, v.deltaTics())
		else
			self.char_scroll = 0
		end
		
		v.drawFill(0, 0, 320, 200, color.ramp[0 + 5])
		
		v.drawFill(0, 0, (v.width() - (320 * v.dupx())) / 2, v.height(), color.ramp[0 + 5 + 5]|V_NOSCALESTART)
		
		self.time = $ + v.deltaTics()
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
		if name == "right arrow" then scrollby = 1 end
		if name == "left arrow" then scrollby = -1 end
		
		if scrollby then
			self.save_select = $ + scrollby
			self.save_scroll = $ + scrollby * FU * 100
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
		MenuItem_Button:new{label = "Specify server address:", link = "ServerConnection", spacing = FU * 2}, --action
		MenuItem_Button:new{label = "Rejoin previous servers...", link = "MultiplayerMenu_Rejoin", spacing = FU * 2}, --srb2-edit
		
		MenuItem_Header:new{label = "Host a game"},
		MenuItem_Button:new{label = "Internet/LAN...", link = "MultiplayerMenu_HostInternet", spacing = FU * 2},
		MenuItem_Button:new{label = "Splitscreen...", link = "MultiplayerMenu_HostSplitscreen", spacing = FU * 2},
		
		MenuItem_Header:new{label = "Player setup"},
		MenuItem_Button:new{label = "Player 1...", link = "MultiplayerMenu_P1Setup", spacing = FU * 2},
		MenuItem_Button:new{label = "Player 2...", link = "MultiplayerMenu_P2Setup", spacing = FU * 2},
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
		
		MenuItem_Button:new{label = "Server Options...", desc = "Change server hosting settings", link = "OptionsMenu_Server", spacing = FU * 2},
		MenuItem_Button:new{label = "Network Options...", desc = "Change network settings", link = "OptionsMenu_Network", spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Data Options...", desc = "Manage data, screenshots, etc.", link = "OptionsMenu_Data", spacing = FU * 2},
		MenuItem_Button:new{label = "Menu Options...", desc = "Luamenu-specific settings", link = "OptionsMenu_Luamenu", spacing = FU * 2},
	},
}

menus.OptionsMenu_Luamenu = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "MENU OPTIONS",
	
	items = {
		MenuItem_Header:new{label = "Visual"},
		MenuItem_Button:new{label = "Background Decorations", desc = "Show visual decorations in the background", cvar = CV_FindVar("luamenu_bgdecos"), spacing = FU * 2},
		MenuItem_Button:new{label = "Animations", desc = "Enable animations when entering pages, hovering, etc.", cvar = CV_FindVar("luamenu_anims"), spacing = FU * 2},
		MenuItem_Button:new{label = "Tooltips", desc = "Show short descriptions of menu options at the bottom", cvar = CV_FindVar("luamenu_tooltips"), spacing = FU * 2},
	},
}

menus.OptionsMenu_P1Controls = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 50 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "CONTROL SETUP",--"AY BOY I JUST GOT THE NEW iPHONE",--\nIT EVEN GOT AN APP TO DESTROY ALL OPPS",
	
	items = {
		MenuItem_Button:new{label = "Control Configuration...", desc = "Change keyboard controls", link = new_menu("OptionsMenu_P1Controls_Keyboard", Menu:new{
			anchor = {x = "center", y = "top"}, width = FU * 320 - FU * 30 * 2, height = FU * 200 - FU * 20 * 2,
			title = "CONTROL SETUP",
			
			items = {
				MenuItem_Header:new{label = "'''''''''''''''''''''''''''"},
				MenuItem_Header:new{label = "digo"},
				MenuItem_Header:new{label = "Movement"},
				MenuItem_Button:new{label = "Use Mouse", desc = "Enable mouse movement", cvar = CV_FindVar("use_mouse"), spacing = FU * 2 + FU * 10},
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
				MenuItem_Button:new{label = "Mouse X Sensitivity", desc = "Change horizontal mouse sensitivity", cvar = CV_FindVar("mousesens"), spacing = FU * 2},
				MenuItem_Button:new{label = "Mouse Y Sensitivity", desc = "Change vertical mouse sensitivity", cvar = CV_FindVar("mouseysens"), spacing = FU * 2 + FU * 10},
			},
		}), spacing = FU * 2},
		MenuItem_Button:new{label = "Gamepad Options...", desc = "Change controller settings", link = "a", spacing = FU * 2 + FU * 10},
		
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
				MenuItem_Button:new{label = "Camera Spacial Speed", desc = "Change the following speed of third-person camera", cvar = CV_FindVar("cam_speed"), spacing = FU * 2},
				MenuItem_Button:new{label = "Rotation Speed", desc = "Change the speed of left/right arrow keys", cvar = CV_FindVar("cam_turnmultiplier"), spacing = FU * 2},
				
				MenuItem_Header:new{label = "Display Options"},
				MenuItem_Button:new{label = "Crosshair", desc = "Show a crosshair at the center in first-person", cvar = CV_FindVar("crosshair"), spacing = FU * 2},
				MenuItem_Button:new{label = "Inverted Crosshair", desc = "Invert the crosshair's color against the background", cvar = CV_FindVar("crosshair_invert"), spacing = FU * 2},
				
				MenuItem_Header:new{label = "Miscellaneous"},
				MenuItem_Button:new{label = "Exact Camera", desc = "Enable precise third-person camera movement", cvar = CV_FindVar("cam_exact"), spacing = FU * 2}, --romoney5
				MenuItem_Button:new{label = "Clipping Style", desc = "Change third-person camera clipping behavior", cvar = CV_FindVar("cam_clipping"), spacing = FU * 2}, --romoney5
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
		MenuItem_Button:new{label = "Brightness", cvar = CV_FindVar("gamma"), spacing = FU * 2},
		MenuItem_Button:new{label = "Saturation", cvar = CV_FindVar("saturation"), spacing = FU * 2},
		MenuItem_Button:new{label = "Advanced Settings...", desc = "Advanced color settings", link = "OptionsMenu_Video_Color", spacing = FU * 2},
		
		MenuItem_Header:new{label = "Heads-Up Display"},
		MenuItem_Button:new{label = "Show HUD", cvar = CV_FindVar("showhud"), spacing = FU * 2},
		MenuItem_Button:new{label = "HUD Transparency", cvar = CV_FindVar("translucenthud"), spacing = FU * 2},
		MenuItem_Button:new{label = "Score/Time/Rings", desc = "Change the timer's style", cvar = CV_FindVar("timerres"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show Powerups", desc = "Show active powerups at the bottom-right corner", cvar = CV_FindVar("powerupdisplay"), spacing = FU * 2},
		MenuItem_Button:new{label = "Local Ping Display", desc = "Show ping at the bottom-right corner", cvar = CV_FindVar("showping"), spacing = FU * 2},
		MenuItem_Button:new{label = "Show Player Names", desc = "Show player names when looking at them", cvar = CV_FindVar("seenames"), spacing = FU * 2},
		MenuItem_Button:new{label = "Uppercase Menus", desc = "Force uppercase text in menus", cvar = CV_FindVar("menucaps"), spacing = FU * 2}, --srb2-edit
		MenuItem_Button:new{label = "Menu Highlight Color", desc = "Change the color of highlighted text", cvar = CV_FindVar("menucolor"), spacing = FU * 2}, --srb2-edit, romoney5
		MenuItem_Button:new{label = "Menu Background Color", desc = "Change the color of backgrounds", cvar = CV_FindVar("menubgcolor"), spacing = FU * 2}, --gks edit
		MenuItem_Button:new{label = "Screen Fades", desc = "Enable screen transitions", cvar = CV_FindVar("wipes"), spacing = FU * 2}, --romoney5
		
		MenuItem_Header:new{label = "Console"},
		MenuItem_Button:new{label = "Background Color", cvar = CV_FindVar("con_backcolor"), spacing = FU * 2},
		MenuItem_Button:new{label = "Text Size", cvar = CV_FindVar("con_textsize"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Chat"},
		MenuItem_Button:new{label = "Chat Mode", cvar = CV_FindVar("chatmode"), spacing = FU * 2},
		MenuItem_Button:new{label = "Chat Box Width", cvar = CV_FindVar("chatwidth"), spacing = FU * 2},
		MenuItem_Button:new{label = "Chat Box Height", cvar = CV_FindVar("chatheight"), spacing = FU * 2},
		MenuItem_Button:new{label = "Message Fadeout Time", cvar = CV_FindVar("chattime"), spacing = FU * 2},
		MenuItem_Button:new{label = "Chat Notifications", desc = "Enable chat sounds", cvar = CV_FindVar("chatnotifications"), spacing = FU * 2},
		MenuItem_Button:new{label = "Spam Protection", desc = "Block spammed chat messages", cvar = CV_FindVar("chatspamprotection"), spacing = FU * 2},
		MenuItem_Button:new{label = "Chat background tint", cvar = CV_FindVar("chatbacktint"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Level"},
		MenuItem_Button:new{label = "Draw Distance", desc = "Change render distance of objects", cvar = CV_FindVar("drawdist"), spacing = FU * 2},
		MenuItem_Button:new{label = "Weather Draw Dist.", cvar = CV_FindVar("drawdist_precip"), spacing = FU * 2},
		MenuItem_Button:new{label = "NiGHTS Hoop Draw Dist.", cvar = CV_FindVar("drawdist_nights"), spacing = FU * 2},
		MenuItem_Button:new{label = "Pitch/Roll Object Rotation", desc = "Rotate objects on slopes", cvar = CV_FindVar("pitchroll-tation"), spacing = FU * 2}, --srb2-edit, romoney5
		MenuItem_Button:new{label = "Ring Racers Screenshakes", desc = "Ring Racers-styled screen shakes", cvar = CV_FindVar("rr_quakes"), spacing = FU * 2}, --srb2-edit, romoney5
		MenuItem_Button:new{label = "Screenshake Effects", desc = "Enable screen shakes", cvar = CV_FindVar("earthquake"), spacing = FU * 2}, --srb2-edit, romoney5
		MenuItem_Button:new{label = "Minimum Brightness", desc = "Change minimum sector brightness", cvar = CV_FindVar("fullbrite"), spacing = FU * 2},
		MenuItem_Button:new{label = "Screen Flashes", desc = "Enable screen flashes", cvar = CV_FindVar("flashes"), spacing = FU * 2},
		
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

menus.OptionsMenu_Video_OpenGL = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "OPENGL OPTIONS", --"VIDEO OPTIONS",
	
	items = {
		MenuItem_Header:new{label = "3D Models"},
		MenuItem_Button:new{label = "Models", cvar = CV_FindVar("gr_models"), spacing = FU * 2},
		MenuItem_Button:new{label = "Frame interpolation", cvar = CV_FindVar("gr_modelinterpolation"), spacing = FU * 2},
		MenuItem_Button:new{label = "Ambient lighting", cvar = CV_FindVar("gr_modellighting"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "General"},
		MenuItem_Button:new{label = "Shaders", cvar = CV_FindVar("gr_shaders"), spacing = FU * 2},
		MenuItem_Button:new{label = "Palette rendering", cvar = CV_FindVar("gr_paletterendering"), spacing = FU * 2},
		MenuItem_Button:new{label = "Light Dithering", cvar = CV_FindVar("gr_lightdithering"), spacing = FU * 2}, --gks edit
		MenuItem_Button:new{label = "Lack of perspective", cvar = CV_FindVar("gr_shearing"), spacing = FU * 2},
		MenuItem_Button:new{label = "Field of view", cvar = CV_FindVar("fov"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Miscellaneous"},
		MenuItem_Button:new{label = "Bit depth", cvar = CV_FindVar("scr_depth"), spacing = FU * 2},
		MenuItem_Button:new{label = "Texture filter", cvar = CV_FindVar("gr_filtermode"), spacing = FU * 2},
		MenuItem_Button:new{label = "Anisotropic", cvar = CV_FindVar("gr_anisotropicmode"), spacing = FU * 2},
		MenuItem_Button:new{label = "Render distance", cvar = CV_FindVar("gr_renderdistance"), spacing = FU * 2}, --srb2-edit
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
		MenuItem_Button:new{label = "Sound Volume", cvar = CV_FindVar("soundvolume"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Digital Music", cvar = CV_FindVar("digimusic"), spacing = FU * 2},
		MenuItem_Button:new{label = "Digital Music Volume", cvar = CV_FindVar("digmusicvolume"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "MIDI Music", cvar = CV_FindVar("midimusic"), spacing = FU * 2},
		MenuItem_Button:new{label = "MIDI Music Volume", cvar = CV_FindVar("midimusicvolume"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Music Preference", cvar = CV_FindVar("musicpref"), spacing = FU * 2},
		
		MenuItem_Header:new{label = "Miscellaneous"},
		MenuItem_Button:new{label = "Closed Captioning", cvar = CV_FindVar("closedcaptioning"), spacing = FU * 2},
		MenuItem_Button:new{label = "Reset Music Upon Dying", cvar = CV_FindVar("resetmusic"), spacing = FU * 2},
		MenuItem_Button:new{label = "Default 1-Up sound", cvar = CV_FindVar("1upsound"), spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Advanced Settings...", link = "OptionsMenu_Sound_Advanced", spacing = FU * 2},
	},
}

menus.OptionsMenu_Network = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 30 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "NETWORK OPTIONS",
	
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
		
		MenuItem_Button:new{label = "Pandora's Box...", link = "SP_PandorasBox"},
		MenuItem_Button:new{label = "Emblem Hints...", link = "SP_EmblemHints"},
		MenuItem_Button:new{label = "Level Select...", link = "LevelSelect", spacing = FU * 8},
		
		MenuItem_Button:new{label = "Continue", link = ""},
		MenuItem_Button:new{label = "Retry", action = function(self)
			return function()
				COM_BufInsertText(nil, "retry")
				return false
			end
		end},
		MenuItem_Button:new{label = "Options", link = "OptionsMenu", spacing = FU * 8},
		
		MenuItem_Button:new{label = "Return to Title", action = function(self)
			return function()
				COM_BufInsertText(nil, "exitgame")
				return false
			end
		end},
		MenuItem_Button:new{label = "Quit Game", action = function(self)
			return function()
				COM_BufInsertText(nil, "quit")
			end
		end},
	},
}