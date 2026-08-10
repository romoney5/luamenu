--Niebelheim.
--*laughter*
--What about you?

--Me?
print("Gongaga.")

if not takis_luamenu then return end

local menus = {}

local cv_menucaps = CV_FindVar("menucaps")
local cv_menucolor = CV_FindVar("menucolor")

local v

local current_menu = "MainMenu"

local MenuClass = MenuClass

local function SetActive(active)
	if active then
		input.setMouseGrab(false)
		menuactive = true
	else
		input.setMouseGrab(true)
		menuactive = false
	end
end

--menu page
local Menu = MenuClass:inherit()

function Menu:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.anchor = $ or {x = "center", y = "top"}
	
	a.selection = $ or 1
	
	a.scroll = $ or 0
	a.scroll_vel = $ or 0
	a.dest_scroll = $ or 0
	a.dest_scroll_origin = $ or 0 --TODO: new class
	a.dest_scroll_time = $ or 0
	--destscroll
	
	a.width = $ or FU * 320
	a.height = $ or FU * 200
	
	a.cursor_position = $ or {x = 0, y = 0}
	
	a.items = $ or {}
	a.parent = $ or nil
	
	--link the items to the menu page
	for i, item in ipairs(a.items) do
		item.parent = a
		item.index = i
	end
	
	return a
end

function Menu:getPosition()
	local anchor = self.anchor
	
	local x, y = 0, 0
	
	if anchor.x == "center" then
		x = FU * 320 / 2
	end
	
	if anchor.y == "top" then
		y = FU * 200 - self.height
	elseif anchor.y == "center" then
		local height = 0
		
		for i, item in ipairs(self.items) do
			local w, h = item:getBounds()
			
			height = $ + h
		end
		
		y = self.height / 2 - height / 2
	elseif anchor.y == "bottom" then
		local height = 0
		
		for i, item in ipairs(self.items) do
			local w, h = item:getBounds()
			
			height = $ + h
		end
		
		y = self.height - height
	end
	
	return x, y
end

function Menu:draw()
	local x, y = self:getPosition()
	y = $ - self.scroll
	
	for i, item in ipairs(self.items) do
		local py = self:getYPositionAt(i)
		local align, align_string, factor = item:getAlignment()
		item.align_string = align_string
		item:draw(x + align, y + py)
		
		local width, height = item:getBounds()
		
		--draw the cursor
		if self.selection == i then
			self.cursor_position.x = ease.linear(FU / 3, $, x + align + FixedMul(width, factor) - FU * (24 or 32)) --tied to fps
			self.cursor_position.y = ease.linear(FU / 3, $, y + py)
			v.drawScaled(self.cursor_position.x, self.cursor_position.y, FU, v.cachePatch("M_CURSOR"), 0)
		end
	end
	
	if self.on_draw then
		self:on_draw()
	end
	
	self.dest_scroll_time = min($ + FU / 20, FU)
	self.scroll = ease.outquad(self.dest_scroll_time, self.dest_scroll_origin, self.dest_scroll)
end

function Menu:getYPositionAt(index)
	local y = 0
	
	for i, item in ipairs(self.items) do
		if i > 1 then
			y = $ + item.pre_spacing
		end
		
-- 		local align, align_string, factor = item:getAlignment()
-- 		item.align_string = align_string
-- 		item:draw(x + align, y)

		if i == index then
			return y
		end
		
		local width, height = item:getBounds()
		
		--draw the cursor
-- 		if self.selection == i then
-- 			self.cursor_position.x = ease.linear(FU / 3, $, x + align + FixedMul(width, factor) - FU * (24 or 32)) --tied to fps
-- 			self.cursor_position.y = ease.linear(FU / 3, $, y)
-- 			v.drawScaled(self.cursor_position.x, self.cursor_position.y, FU, v.cachePatch("M_CURSOR"), 0)
-- 		end
		
		y = $ + height + item.spacing
	end
	
	return y
end

--generic menu item
local MenuItem = MenuClass:inherit()

function MenuItem:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.align = $ or "left"
	a.pre_spacing = $ or 0
	a.spacing = $ or 0
	
	
	a.align_string = $ or ""
	
	return a
end

function MenuItem:getFlags()
	return 0
end

function MenuItem:getBounds()
	return 0, 0
end

function MenuItem:canSelect()
	return true
end

function MenuItem:getAlignment()
	local align = self.align
	local align_string = ""
	
	local x = 0
	local factor = -FU / 2
	
	if align == "center" then
		x = 0
		align_string = "-center" --TODO: remove
		factor = -FU / 2
	elseif align == "left" then
		x = 0 - self.parent.width / 2
		align_string = ""
		factor = 0
	elseif align == "right" then
		x = 0 + self.parent.width / 2
		align_string = "-right"
		--unused?
	end
	
	return x, align_string, factor
end

function MenuItem:draw()
	return
end

function MenuItem:activate(increment)
	return
end

--menu text drawer
local MenuItem_Text = MenuItem:inherit()

function MenuItem_Text:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.label = $ or "Button"
	a.link = $ or nil
	
	return a
end

function MenuItem_Text:getFlags(selected)
	local menucaps = 0--(cv_menucaps and not cv_menucaps.value) and V_ALLOWLOWERCASE or 0
	local color = 0
	
	--use a custom highlight color if available, otherwise use yellow
	if self.parent and (self.parent.selection == self.index or selected) then
		color = V_YELLOWMAP
		
		if cv_menucolor then
			color = cv_menucolor.value
		end
	end
	
	return menucaps|color
end

function MenuItem_Text:getBounds()
	local width = self._width or 0--FU * v.stringWidth(self.label, self:getFlags(), "normal")
	local height = FU * 8 --inaccurate in some cases
	
	return width, height
end

local function ZeroNumber(str, amount)
	str = tostring($)
	
	if str:len() >= amount
		return str
	end
	
	return string.rep("0", amount - str:len())..str
end

function MenuItem_Text:draw(x, y)
	local width, height = self:getBounds()
	
-- 	v.drawString(x, y, self.label, self:getFlags(), "fixed"..self.align_string) --TODO: alignment option
	local dupy = v.dupy() * FU
	if y < -((v.height() * FU - dupy * 200) / 2) - height then
		return
	end
	
	if y > FU * 200 + (v.height() * FU - dupy * 200) / 2 then
		return
	end

	local label = self.label
	local width = 0
	local flags = self:getFlags()
	local col = v.getStringColormap(flags)
	local uppercase = not (cv_menucaps and not cv_menucaps.value)
	--run twice; once to calculate the width, once to draw
	for draw = 0, 1 do
		width = 0
		
		for i = 1, label:len() do
			local char = label:sub(i, i)
			
			if uppercase then
				char = $:upper()
			end
			
			local code = char:byte()
			
			local patchname = "STCFN"..ZeroNumber(code, 3)
			
			if v.patchExists(patchname) then
				local patch = v.cachePatch(patchname)
				
				if draw then
					v.drawScaled(x + width, y, FU, patch, 0, col)
				end
				
				width = $ + FU * patch.width
			else
				width = $ + FU * 4
			end
		end
		
		if not draw then
			local _, align_string, factor = self:getAlignment()
			x = $ + FixedMul(width, factor)
		end
	end
	
	self._width = width
end

--menu button
local MenuItem_Button = MenuItem_Text:inherit()

function MenuItem_Button:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
-- 	print(self.label)
	
	a.link = $ or nil
	
	return a
end

function MenuItem_Button:draw(x, y)
	self.super.draw(self, x, y)
	
	--only designed to be used with left alignment
	if self.cvar then
		local flags = self:getFlags(true)
		
		v.drawString(x + self.parent.width, y, self.cvar.string, flags, "fixed-right")
	end
end

function MenuItem_Button:activate(increment)
	if self.link == "" then
		SetActive(false)
		return
	end

	if self.link then
		assert(menus[self.link], ("MenuItem_Button:activate: no menu \"%s\""):format(tostring(self.link)))
		
		local old_menu = current_menu
		
		current_menu = self.link
		menus[current_menu].parent = old_menu
	end
	
	if self.cvar then
		CV_AddValue(self.cvar, increment, true)
	end
	
	if self.action then
		self:action()
	end
end

--menu header label
local MenuItem_Header = MenuItem:inherit()

function MenuItem_Header:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.label = $ or "Header"
	
	a.pre_spacing = $ or FU * 16
	a.spacing = $ or FU * 3
	
	return a
end

function MenuItem_Header:getFlags(selected)
	local menucaps = (cv_menucaps and not cv_menucaps.value) and V_ALLOWLOWERCASE or 0
	local color = 0
	
	--use a custom highlight color if available, otherwise use yellow
	color = V_YELLOWMAP
	
	if cv_menucolor then
		color = cv_menucolor.value
	end
	
	return menucaps|color
end

function MenuItem_Header:canSelect()
	return false
end

function MenuItem_Header:draw(x, y)
	local width, height = self:getBounds()
	
	v.drawString(FU * 19 or x, y - FU * 9, self.label, self:getFlags(), "fixed"..self.align_string) --TODO: alignment option
	
	v.drawFixedFill(FU * 19, y, FU * 281 + FU, FU * 1 + FU, 26) --shadow
	v.drawFixedFill(FU * 19, y, FU * 281, FU * 1, 72) --line
end

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
			function next_action()
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
	
	on_draw = function(self)
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
		MenuItem_Button:new{label = "Server browser...", link = "MainMenu", spacing = FU * 2},
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

local next_action

menus.SP_MainMenu = Menu:new{
	anchor = {x = "center", y = "center"},
	show_version = true,
	width = FU * 320 - FU * 50 * 2,
	height = FU * 200 - FU * 20 * 2,
	
	items = {
		MenuItem_Button:new{label = "Pandora's Box..."},
		MenuItem_Button:new{label = "Emblem Hints..."},
		MenuItem_Button:new{label = "Level Select...", spacing = FU * 2 + FU * 10},
		MenuItem_Button:new{label = "1  Player", align = "center", link = "SingleplayerMenu"},
		
		MenuItem_Button:new{label = "Continue", link = ""},
		MenuItem_Button:new{label = "Retry", link = ""},
		MenuItem_Button:new{label = "Options", link = "OptionsMenu", spacing = FU * 2 + FU * 10},
		
		MenuItem_Button:new{label = "Return to Title", action = function(self)
			function next_action()
				COM_BufInsertText(nil, "exitgame")
				menuactive = false
			end
		end},
		MenuItem_Button:new{label = "Quit  Game", action = function(self)
			function next_action()
				COM_BufInsertText(nil, "quit")
			end
		end},
	},
}

local function DrawSpikes(rot, ox, oy, scroll, flags)
	local bg2 = v.cachePatch("RECATKFG2")
	local bg = v.cachePatch("RECATKFG2", -rot + ANGLE_90)
	local dimension = bg2.height - 1
	
	for i = -2, FU * 400 / dimension / FU do
		local factor = FixedMul(FU * dimension, FU * i + scroll)
		local x = FixedMul(factor, cos(rot)) + ox
		local y = FixedMul(factor, sin(rot)) + oy
		v.drawScaled(x, y, FU, bg, flags)
	end
end

local mx, my = 0, 0

local function GetState()
	local state = "game"
	
	if titlemapinaction then state = "title" end
	
	return state
end

local function Input(key)
	local name = key.name:lower()
	local state = GetState()
	
	if name == "escape" then
		if state == "game" and not menuactive then
			current_menu = "SP_MainMenu"
			SetActive(true)
			
			return
		else
			if not menuactive then return end
		end
-- 		print(name)
		
		local menu = menus[current_menu]
		assert(menu, ("KeyDown: Invalid menu \"%s\"!"):format(tostring(current_menu))) --r
		
		if menu.parent then
			assert(menus[menu.parent], ("KeyDown: Invalid menu back link \"%s\""):format(tostring(menu.parent))) --r
			current_menu, menu.parent = menu.parent, nil
		else
			SetActive(false)
		end
		
		return
	elseif name == "enter" and not menuactive then
		if state == "title" then
	-- 		print(name)
			
			current_menu = "MainMenu"
			
			SetActive(true)
		end
		
		return
	end
	
	if not menuactive then return end
	
	local menu = menus[current_menu]
	assert(menu, ("KeyDown: Invalid menu \"%s\""):format(tostring(current_menu))) --r
	
	if menu.on_input and menu:on_input(key, name) then
		return
	end
	
-- 	print(name)
	local scrollby = 0
	if name == "down arrow" then
		scrollby = 1
	elseif name == "up arrow" then
		scrollby = -1
	end
	
	if scrollby then
		local selection = menu.selection
		while true do
			menu.selection = $ + scrollby
			
			if menu.selection > #menu.items then
				menu.selection = 1
			elseif menu.selection < 1 then
				menu.selection = #menu.items
			end
			
			if menu.items[menu.selection] and menu.items[menu.selection]:canSelect() then
				break
			end
			
			--reached a loop
			if menu.selection == selection then
				break
			end
		end
		
		local total_height = menu:getYPositionAt(#menu.items + 1)
		
		if not menu.scroll_vel and total_height > menu.height then --also make this a function
			local py = menu:getYPositionAt(menu.selection)
			
			menu.dest_scroll_time = 0--min($ + FU / 20, FU)
			menu.dest_scroll_origin = menu.scroll
			menu.dest_scroll = min(max(py - FU * 50, 0), total_height - FU * 150)
		end
	end
	
	if name == "enter" or name == "left arrow" or name == "right arrow" then
		for i, item in ipairs(menu.items) do
			if i == menu.selection then
				item:activate(name == "left arrow" and -1 or 1)
				
				break
			end
		end
	end
end

local mouse_pressed = false

local function Drawer(drawer, player)
	if not menuactive then return end
	
	--localize drawing functions into a table
	if v == nil then
		v = {}
		
		for i, fun in pairs(drawer) do
			v[i] = fun
		end
	end
	
	v.fadeScreen(0xFF00, 16)
	
	local menu = menus[current_menu]
	assert(menu, ("Drawer: Invalid menu \"%s\"!"):format(tostring(current_menu)))
	
	local mx, my = input.getCursorPosition() --dup
	mx, my = $ * FU, $ * FU
	local _, dupx = v.dupx()
	local _, dupy = v.dupy()
	mx, my = FixedDiv($, dupx), FixedDiv($, dupy)
-- 	v.drawString(20, 20, (mx / FU).." "..(my / FU))
	
	if (mouse.buttons & MB_BUTTON1) then
		if not mouse_pressed then--or true then
			local menux, menuy = menu:getPosition()
			menuy = $ - menu.scroll
			for i, item in ipairs(menu.items) do
				local width, height = item:getBounds()
				local y = menu:getYPositionAt(i) + menuy
-- 				print(i, y, height)
				if not (my >= y and my < y + height) then continue end
				
				if i == menu.selection then
					item:activate(1)
				else
					menu.selection = i
				end
				
				break
			end
		end
		
		mouse_pressed = true
	else
		if mouse_pressed then
			
		end
		
		mouse_pressed = false
	end
	
	if (mouse.buttons & MB_SCROLLDOWN) then
		menu.scroll_vel = $ + FU / 6
	end
	
	if (mouse.buttons & MB_SCROLLUP) then
		menu.scroll_vel = $ - FU / 6
	end
	
	--TODO:
	
	menu.scroll = $ + menu.scroll_vel
	
	if menu.scroll_vel then
		menu.dest_scroll_time = FU
		menu.dest_scroll = menu.scroll
		menu.scroll_vel = max(abs($) - FU / 32, 0) * ($ < 0 and -1 or 1)
	end
	
	local speed = FU / TICRATE / 2
	DrawSpikes(ANG1 * 10, 0, FU * 155, (leveltime * speed + menu.scroll / 64) % FU, V_SNAPTOBOTTOM|V_SNAPTOLEFT)
	DrawSpikes(ANG1 * 10 + ANGLE_180, FU * 270, FU * 40, (leveltime * speed + menu.scroll / 64) % FU, V_SNAPTOTOP|V_SNAPTORIGHT)
	
	--to differentiate the two
	if menu.show_version then
		v.drawString(0 + FU * 8, FU * 200 - FU * 8 - FU * 8, VERSIONSTRING.." newmenu", V_TRANSLUCENT|V_ALLOWLOWERCASE|V_SNAPTOLEFT|V_SNAPTOBOTTOM, "thin-fixed")
	end
	
	menu:draw()
end

addHook("MenuThinker", function()
	if not menuactive then return end
	
	if next_action then
		local action = next_action
		
		next_action = nil
		action()
	end
end)

hud.add(Drawer, "menu")

--first time i ever use this hook
addHook("KeyDown", Input)