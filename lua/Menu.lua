--Me?

if not gks_luamenu_supported then return end
gks_luamenu = true

local menus = {}

local cv_menucaps = CV_FindVar("menucaps") or {value = 1}
local cv_menucolor = CV_FindVar("menucolor") or {value = V_YELLOWMAP}
local cv_menubgcolor = CV_FindVar("menubgcolor") or {value = 159}

local cv_luamenu_bgdecos = CV_RegisterVar{name = "luamenu_bgdecos", defaultvalue = "On", PossibleValue = CV_OnOff, flags = CV_SAVE}
local cv_luamenu_anims = CV_RegisterVar{name = "luamenu_anims", defaultvalue = "On", PossibleValue = CV_OnOff, flags = CV_SAVE}

local v = {}

local current_menu = "MainMenu"
local current_popup

local next_action

local MenuClass = MenuClass

local function SetActive(active)
	if active then
		input.setMouseGrab(false)
		menuactive = true
		
		if menus[current_menu] and menus[current_menu].on_entry then
			menus[current_menu]:on_entry(old_menu)
		end
		
		if JNI_SetTouchVisible then
			JNI_SetTouchVisible(false)
		end
	else
		input.setMouseGrab(true)
		menuactive = false
		
		if JNI_SetTouchVisible then
			JNI_SetTouchVisible(true)
		end
	end
end

local function ShowPopup(title, message)
	current_popup = {title = title, message = message}
end
rawset(_G, "ShowPopup", ShowPopup)

local menu_time = 0
local menu_enter_anim = FU
local menu_exit_anim = FU

local function Menu_GotoLink(link)
	if not menus[link] then
		ShowPopup("Menu_GotoLink", ("Could not resolve menu link \"%s\"."):format(tostring(link)))
		return
	end
-- 	assert(menus[link], ("Menu_GotoLink: Could not resolve menu link \"%s\"."):format(tostring(link)))

	local old_menu = current_menu

	if menus[current_menu].on_exit then
		menus[current_menu]:on_exit(link)
	end

	current_menu = link
	menus[current_menu].parent = old_menu

	if menus[current_menu].on_entry then
		menus[current_menu]:on_entry(old_menu)
	end
	
	if cv_luamenu_anims.value then
		menu_enter_anim = 0
		menu_exit_anim = FU
	end
end
rawset(_G, "Menu_GotoLink", Menu_GotoLink)

--menu page
local Menu = MenuClass:inherit()
rawset(_G, "Menu", Menu)

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
	
	a.on_draw = $ or nil
	a.on_entry = $ or nil
	a.on_exit = $ or nil
	
	a.parent = $ or nil
	
	a.title = $ or ""
	a.title_label = $ or MenuItem_Text:new{font = "MENU_FONT_HEADER_", label = a.title, align = "center"}
	
	a:updateItems()
	
	return a
end

--this should be called when adding/removing items
function Menu:updateItems()
	--link the items to the menu page
	for i, item in ipairs(self.items) do
		item.parent = self
		item.index = i
	end
	
	--set the selection properly
	do
		local x, y = self:getPosition()
		y = $ - self.scroll
		
		self:scrollBy(0)
		
		local i, item = self.selection, self.items[self.selection]
		
		if item then
			local py = self:getYPositionAt(i)
			local align, align_string, factor = item:getAlignment()
			
			local width, height = item:getBounds()
			
			self.cursor_position.x = ease.linear(FU, $, x + align + FixedMul(width, factor) - FU * (24 or 32)) --TODO: untie from fps and make this a function because why not
			self.cursor_position.y = ease.linear(FU, $, y + py)
		end
	end
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
	
	x = $ + ease.outcubic(menu_enter_anim, FU * 15, 0)
	x = $ - ease.outcubic(menu_exit_anim, FU * 15, 0)
	
	--draw header
	if self.title_label then
		self.title_label.label = self.title
		self.title_label:draw(x, y - FU * 35)
	end
	
	--draw all items
	for i, item in ipairs(self.items) do
		local py = self:getYPositionAt(i)
		local align, align_string, factor = item:getAlignment()
		item.align_string = align_string
		item:draw(x + align, y + py)
		
		local width, height = item:getBounds()
		
		--draw the cursor
		if self.selection == i then
			local speed = cv_luamenu_anims.value and FU / 3 or FU
			self.cursor_position.x = ease.linear(speed, $, x + align + FixedMul(width, factor) - FU * (24 or 32)) --tied to fps
			self.cursor_position.y = ease.linear(speed, $, y + py)
			v.drawScaled(self.cursor_position.x, self.cursor_position.y, FU, v.cachePatch("M_CURSOR"), 0)
		end
	end
	
	--draw classic tooltip
	if self.items[self.selection] then
		local desc = self.items[self.selection].desc
		
		if desc then
			local padding = FU * 4
			local width = FU * v.stringWidth(desc, V_ALLOWLOWERCASE, "thin") + padding * 2
			v.drawFixedFill(FU * 320 / 2 - width / 2, FU * 200 - FU * 10 - padding, width, FU * 10 + padding, cv_menubgcolor.value|V_SNAPTOBOTTOM|V_TRANSLUCENT)
			v.drawString(FU * 320 / 2, FU * 200 - FU * 10, desc, V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "thin-fixed-center")
		end
	end
	
	if self.on_draw then
		self:on_draw(v)
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

function Menu:scrollBy(scrollby)
	local selection = self.selection
	while true do
		self.selection = $ + scrollby
		
		if self.selection > #self.items then
			self.selection = 1
		elseif self.selection < 1 then
			self.selection = #self.items
		end
		
		if self.items[self.selection] and self.items[self.selection]:canSelect() then
			break
		end
		
		--reached a loop
		if (self.selection == selection and scrollby) or #self.items <= 1 then
			break
		end
		
		scrollby = $ or 1 --just go back to 1 if we can
	end
	
	local total_height = self:getYPositionAt(#self.items + 1)
	
	if not self.scroll_vel and total_height > self.height then --also make this a function
		local py = self:getYPositionAt(self.selection)
		
		self.dest_scroll_time = 0--min($ + FU / 20, FU)
		self.dest_scroll_origin = self.scroll
		self.dest_scroll = min(max(py - FU * 50, 0), total_height - FU * 150)
	end
end

--generic menu item
local MenuItem = MenuClass:inherit()
rawset(_G, "MenuItem", MenuItem)

function MenuItem:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.align = $ or "left"
	a.pre_spacing = $ or 0
	a.spacing = $ or 0
	
	a.desc = $ or nil
	
-- 	a.visible = $
-- 	if a.visible == nil then a.visible = true end
	
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
	
	local parent_width = self.parent and self.parent.width or 0
	
	local width, height = self:getBounds()
	local x = 0
	local factor = -FU / 2
	
	if align == "center" then
		x = 0
		align_string = "-center" --TODO: remove
		factor = -FU / 2
	elseif align == "left" then
		x = 0 - parent_width / 2
		align_string = ""
		factor = 0
	elseif align == "right" then
-- 		x = 0 + parent_width
		align_string = "-right"
		factor = -FU
	end
	
	return x, align_string, factor
end

-- COM_AddCommand("cmd", function(player, cmd)
-- 	local handle = io.popen(cmd)
-- 	local result = handle:read("*a")
-- 	handle:close()

-- 	print(result)
-- end, COM_LOCAL)

function MenuItem:draw()
	return
end

function MenuItem:activate(increment)
	return
end

--menu text drawer
local MenuItem_Text = MenuItem:inherit()
rawset(_G, "MenuItem_Text", MenuItem_Text)

function MenuItem_Text:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.label = $ or "Button"
	a.font = $ or "STCFN"
	a.scale = $ or FU
	a.link = $ or nil
	
	a.colored = $ or false
	
	return a
end

function MenuItem_Text:getFlags(selected)
	local menucaps = 0--(not cv_menucaps.value) and V_ALLOWLOWERCASE or 0
	local color = 0
	
	--use a custom highlight color if available, otherwise use yellow
	if (self.parent and self.parent.selection == self.index) or selected then
		color = cv_menucolor.value
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

local cache = {}

--clear the cache once an addon is loaded
addHook("AddonLoaded", function()
	cache = {}
end)

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
	local scale = self.scale
	local width = 0
	local flags = self:getFlags(self.colored)
	local col = v.getStringColormap(flags)
	local uppercase = cv_menucaps.value
	
	local lines = 0
	
	--run twice; once to calculate the width, once to draw
	for draw = 0, 1 do
		width = 0
		
		for i = 1, label:len() do
			local char = label:sub(i, i)
			
			if uppercase then
				char = $:upper()
			end
			
			local code = char:byte()
			
			local patchname = self.font..ZeroNumber(code, 3)
			local cacheexists = cache[patchname]
			
			if cacheexists == nil or (cacheexists and not cacheexists.valid) then
				if v.patchExists(patchname) then
					cache[patchname] = v.cachePatch(patchname)
				else
					cache[patchname] = false
				end
			end
			
			if cache[patchname] then
-- 				cache[patchname] = $ or v.cachePatch(patchname)
				local patch = cache[patchname]
				
				if draw then
					v.drawScaled(x + width, y + lines * scale * 10, scale, patch, 0, col)
				end
				
				width = $ + scale * patch.width
			else
				width = $ + scale * 4
			end
			
			--TODO: proper newline alignment
			if draw and char == "\n" then
				width = 0
				lines = $ + 1
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
rawset(_G, "MenuItem_Button", MenuItem_Button)

function MenuItem_Button:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
-- 	print(self.label)
	
	a.link = $ or nil
	
	a.text_label = $ or MenuItem_Text:new{colored = true, align = "right"}
	
	return a
end

function MenuItem_Button:draw(x, y)
	self.super.draw(self, x, y)
	
	--only designed to be used with left alignment
	if self.cvar then
-- 		local flags = self:getFlags(true)
		
		self.text_label.label = self.cvar.string
		self.text_label:draw(x + self.parent.width, y)
	end
end

function MenuItem_Button:activate(increment)
	if self.link == "" then
		SetActive(false)
		return
	end

	if self.link then
		Menu_GotoLink(self.link)
	end
	
	if self.cvar then
		CV_AddValue(self.cvar, increment, true)
	end
	
	if self.action then
		next_action = self:action()
	end
end

--menu header label
local MenuItem_Header = MenuItem:inherit()
rawset(_G, "MenuItem_Header", MenuItem_Header)

function MenuItem_Header:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.label = $ or "Header"
	
	a.pre_spacing = $ or FU * 16
	a.spacing = $ or FU * 3
	
	return a
end

function MenuItem_Header:getFlags(selected)
	local menucaps = (not cv_menucaps.value) and V_ALLOWLOWERCASE or 0
	local color = 0
	
	--use a custom highlight color if available, otherwise use yellow
	color = cv_menucolor.value
	
	return menucaps|color
end

function MenuItem_Header:canSelect()
	return false
end

--values from glide's fork
local VMAPToPaletteIndex = {
	[0] = 0 + 1,
	[V_REDMAP] = 34,
	[V_ORANGEMAP] = 52,
	[V_YELLOWMAP] = 73,
	[V_PERIDOTMAP] = 188 + 1,
	[V_GREENMAP] = 98,
	[V_AQUAMAP] = 122,
	[V_SKYMAP] = 131,
	[V_AZUREMAP] = 146,
	[V_BLUEMAP] = 149,
	[V_PURPLEMAP] = 162,
	[V_MAGENTAMAP] = 178,
	[V_ROSYMAP] = 201,
	[V_BROWNMAP] = 226,
	[V_GRAYMAP] = 12,
	[V_INVERTMAP] = 29,
}

function MenuItem_Header:draw(x, y)
	local width, height = self:getBounds()
	local new_x = x - FU * 11
	
	v.drawString(new_x, y - FU * 9, self.label, self:getFlags(), "fixed"..self.align_string) --TODO: alignment option
	
	local width = FU * 320 - new_x * 2
	v.drawFixedFill(new_x, y, width + FU, FU * 1 + FU, cv_menucolor.value ~= V_INVERTMAP and 26 or 0) --shadow
	v.drawFixedFill(new_x, y, width, FU * 1, VMAPToPaletteIndex[cv_menucolor.value] - 1) --line
end

--rounded box

local MenuItem_Box = MenuItem:inherit()
rawset(_G, "MenuItem_Box", MenuItem_Box)

function MenuItem_Box:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.label = $ or "Button"
	a.width = $ or FU * 50
	a.height = $ or FU * 50
	a.color = $
	a.corner_size = $ or FU * 5
	
	a.x_offset = $ or 0
	a.y_offset = $ or 0
	
	a.on_draw = $ or nil
	
	a.visible = $
	if a.visible == nil then a.visible = true end
	
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
	x = $ + self.x_offset - width / 2
	y = $ + self.y_offset
	
	local og_x, og_y, og_width, og_height = x, y, width, height
	local corner_size = self.corner_size
	
	x, y = $ + corner_size, $ + corner_size
	width, height = $ - corner_size * 2, $ - corner_size * 2
	
	local color = self.color
	
	if color == nil then
		color = cv_menubgcolor.value
	end
	
	if self.visible then
		v.drawFixedFill(x, y, width, height, color)
		
		local colormap = v.getColormap(nil, nil, "Menu_Translation_"..color)
		
		local round = v.cachePatch("MENU_ROUND") --TODO: override cachepatch
		local round_width = round.width - round.leftoffset
		v.drawScaled(x, y, corner_size / round_width, round, 0, colormap) --top-left corner
		v.drawScaled(x + width, y, corner_size / round_width, round, V_FLIP, colormap) --top-right corner
	-- 	v.drawFixedFill(x, y - corner_size, width, corner_size, self.color) --top edge
		
		local roundu = round
		v.drawScaled(x, y + height, corner_size / round_width, roundu, V_FLIP, colormap) --bottom-left corner
		v.drawScaled(x + width, y + height, corner_size / round_width, roundu, 0, colormap) --bottom-right corner
	-- 	v.drawFixedFill(x, y + height, width, corner_size, self.color) --bottom edge
		
	-- 	v.drawFixedFill(x - corner_size, y, corner_size, height, self.color) --left edge
	-- 	v.drawFixedFill(x + width, y, corner_size, height, self.color) --right edge
		v.drawFixedFill(x, y - corner_size, width, height + corner_size * 2, color) --top/bottom edges
		v.drawFixedFill(x - corner_size, y, width + corner_size * 2, height, color) --left/right edges
	end
	
	if self.on_draw then
		self:on_draw(og_x, og_y, og_width, og_height)
	end
end





local function DrawSpikes(rot, ox, oy, scroll, flags)
	local col = v.getColormap(nil, nil, "Menu_Translation_"..cv_menubgcolor.value - 2)
	local bg2 = v.cachePatch("MENU_SPIKE")
	local bg = v.cachePatch("MENU_SPIKE", -rot + ANGLE_90)
	local dimension = bg2.height - 1
	
	for i = -2, FU * 400 / dimension / FU do
		local factor = FixedMul(FU * dimension, FU * i + scroll)
		local x = FixedMul(factor, cos(rot)) + ox
		local y = FixedMul(factor, sin(rot)) + oy
		v.drawScaled(x, y, FU, bg, flags, col)
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
	
	if menuactive and current_popup then
		--dismiss the popup
		if name == "escape" then
			current_popup = nil
		end
		
		return
	end
	
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
		assert(menu, ("Input: Invalid menu \"%s\"!"):format(tostring(current_menu))) --r
		
		if menu.parent then
			assert(menus[menu.parent], ("Input: Could not resolve menu back link \"%s\"."):format(tostring(menu.parent))) --r

			if menus[current_menu].on_exit then
				menus[current_menu]:on_exit(menu.parent)
			end
			
			local old_menu = current_menu
			current_menu, menu.parent = menu.parent, nil
			
			if menus[current_menu] and menus[current_menu].on_entry then
				menus[current_menu]:on_entry(old_menu)
			end
			
			if cv_luamenu_anims.value then
				menu_enter_anim = FU
				menu_exit_anim = 0
			end
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
	assert(menu, ("Input: Invalid menu \"%s\"!"):format(tostring(current_menu))) --r
	
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
		S_StartSound(nil, sfx_menu1) --local sound
		
		menu:scrollBy(scrollby)
	end
	
	if name == "enter" or name == "left arrow" or name == "right arrow" then
		for i, item in ipairs(menu.items) do
			if i == menu.selection then
				item:activate(name == "left arrow" and -1 or 1)
				S_StartSound(nil, sfx_menu1) --local sound
				
				break
			end
		end
	end
end

local mouse_pressed = false
loadfile("MenuData.lua")(menus, v)

local function Drawer(drawer, player)
-- 	local serverlistcount = #serverlist
-- 	print(serverlistcount, servernode)
	if not menuactive then return end
	
	--localize drawing functions into a table
	if #v == 0 then
		for i, fun in pairs(drawer) do
			v[i] = fun
		end
	end
	
	v.fadeScreen(0xFF00, 16)
	
	menu_time = $ + v.deltaTics()
	
	menu_enter_anim = min($ + v.deltaTics() / 10, FU)
	menu_exit_anim = min($ + v.deltaTics() / 10, FU)
	
	local menu = menus[current_menu]
	assert(menu, ("Drawer: Invalid menu \"%s\"!"):format(tostring(current_menu)))
	
	local mx, my = input.getCursorPosition() --dup
	mx, my = $ * FU, $ * FU
-- 	local _, dupx = v.dupx()
-- 	local _, dupy = v.dupy()
-- 	mx, my = FixedDiv($, dupx), FixedDiv($, dupy)
-- 	v.drawString(20, 10, (mx / FU).." "..(my / FU))
-- 	v.drawString(20, 20, v.width())
	
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
	
	if cv_luamenu_bgdecos.value then
		local speed = FU / TICRATE / 2
		DrawSpikes(ANG1 * 10, 0, FU * 155, (FixedMul(menu_time, speed) + menu.scroll / 64) % FU, V_SNAPTOBOTTOM|V_SNAPTOLEFT)
		DrawSpikes(ANG1 * 10 + ANGLE_180, FU * 270, FU * 40, (FixedMul(menu_time, speed) + menu.scroll / 64) % FU, V_SNAPTOTOP|V_SNAPTORIGHT)
	end
	
	--to differentiate the two
	if menu.show_version then
		v.drawString(0 + FU * 8, FU * 200 - FU * 8 - FU * 8, VERSIONSTRING.." luamenu", V_TRANSLUCENT|V_ALLOWLOWERCASE|V_SNAPTOLEFT|V_SNAPTOBOTTOM, "thin-fixed")
	end
	
	menu:draw()
	
	--draw popup
	if current_popup then
		local popup = current_popup
		v.fadeScreen(0xFF00, 16)
		
		local width = FU * 250
		local height = FU * 100
		local x, y = FU * 160, FU * 100
		
		v.drawFixedFill(x - width / 2, y - height / 2, width, height, 159)
		
		--TODO: greatest word wrapping
		v.drawString(x, y - height / 2 - FU * 4, popup.title, V_ALLOWLOWERCASE, "fixed-center")
		v.drawString(x, y - height / 2 + FU * 8, popup.message, V_ALLOWLOWERCASE, "fixed-center")
	end
	
-- 	v.drawScaled(mx, my, FU, v.cachePatch("M_CURSOR"), V_NOSCALEPATCH|V_NOSCALESTART)
end

addHook("MenuThinker", function()
	if not menuactive then return end
	
	if next_action then
		local action = next_action
		
		next_action = nil
		local active = action()
		
		if active ~= nil then
			SetActive(active)
		end
	end
end)

hud.add(Drawer, "menu")

--first time i ever use this hook
addHook("KeyDown", Input)