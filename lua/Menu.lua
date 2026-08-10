--Me?
--main menu logic

setfenv(1, luamenu)
--from now globals will be set in luamenu by default

if not _G.gks_luamenu_supported then return end
_G.gks_luamenu = true

cv_luamenu = CV_RegisterVar{name = "luamenu", defaultvalue = "On", PossibleValue = CV_OnOff, flags = CV_SAVE|CV_CALL, func = function(self)
	_G.gks_luamenu = self.value and true or false
end}

menus = {}

--placeholder banpyura cvars
cv_menucaps = CV_FindVar("menucaps") or {value = 1}
cv_menucolor = CV_FindVar("menucolor") or {value = V_YELLOWMAP}
cv_menubgcolor = CV_FindVar("menubgcolor") or {value = 159}

cv_luamenu_bgdecos = CV_RegisterVar{name = "luamenu_bgdecos", defaultvalue = "On", PossibleValue = CV_OnOff, flags = CV_SAVE}
cv_luamenu_anims = CV_RegisterVar{name = "luamenu_anims", defaultvalue = "On", PossibleValue = CV_OnOff, flags = CV_SAVE}
cv_luamenu_tooltips = CV_RegisterVar{name = "luamenu_tooltips", defaultvalue = "On", PossibleValue = CV_OnOff, flags = CV_SAVE}
cv_luamenu_rounded = CV_RegisterVar{name = "luamenu_rounded", defaultvalue = "1", PossibleValue = {MIN = 0, MAX = FU * 4}, flags = CV_SAVE|CV_FLOAT}
cv_luamenu_sliders = CV_RegisterVar{name = "luamenu_sliders", defaultvalue = "On", PossibleValue = CV_OnOff, flags = CV_SAVE}

v = {}

current_menu = "MainMenu"
current_popup = nil

local next_action

local menu_time = 0
local menu_enter_anim = FU
local menu_exit_anim = FU

local keyHold = {}
local keyHold_lock = {}

local cache = {}

--clear the cache once an addon is loaded
addHook("AddonLoaded", function()
	cache = {}
end)

local function cachePatch(patchname)
	local cacheexists = cache[patchname]
	
	if cacheexists == nil or (cacheexists and not cacheexists.valid) then
		if v.patchExists(patchname) then
			cache[patchname] = v.cachePatch(patchname)
		else
			cache[patchname] = false
		end
	end
	
	return cache[patchname]
end

--screen coordinates to 320x200 coordinates
local function ScreenToDisplay(x, y)
	x = FU * $
	y = FU * $

	local dupx = v.dupx()
	local dupy = v.dupy()
	local width = FU * v.width()
	local height = FU * v.height()
	local base_width = FU * 320
	local base_height = FU * 200
	local scaled_width = base_width * dupx
	local scaled_height = base_height * dupy
	
	local left = width / 2 - scaled_width / 2
-- 	local bottom = height / 2 + scaled_height / 2
-- 	local right = width / 2 + scaled_width / 2
	local top = height / 2 - scaled_height / 2
	
	return FixedMul(x - left, FixedDiv(base_width + left / 2, width)), FixedMul(y - top, FixedDiv(base_height + top / 2, height))
end

function Menu_SetActive(active)
	if active then
		input.setMouseGrab(false)
		_G.menuactive = true
		
		if menus[current_menu] and menus[current_menu].on_entry then
			menus[current_menu]:on_entry(old_menu)
		end
		
		if JNI_SetTouchVisible then
			JNI_SetTouchVisible(false)
		end
	else
		input.setMouseGrab(true)
		_G.menuactive = false
		current_menu = nil
		current_popup = nil
		
		if JNI_SetTouchVisible then
			JNI_SetTouchVisible(true)
		end
	end
	
	--clear anims when toggling the menu
	menu_enter_anim = FU
	menu_exit_anim = FU
end

function Menu_GotoLink(link)
	if not menus[link] then
		ShowPopup("Menu_GotoLink", ("Could not find menu link \"%s\".\n\nThis menu may be unfinished."):format(tostring(link)))
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

--menu page
Menu = MenuClass:inherit()

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
			
			self.cursor_position.x = ease.linear(FU, $, align + FixedMul(width, factor) - FU * (24 or 32)) --TODO: untie from fps and make this a function because why not
			self.cursor_position.y = ease.linear(FU, $, py)
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
	
	if cv_luamenu_anims.value then
		self.dest_scroll_time = min($ + FU / 20, FU)
	else
		self.dest_scroll_time = FU
	end
	
	self.scroll = ease.outquad(self.dest_scroll_time, self.dest_scroll_origin, self.dest_scroll)
	
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
			local speed = cv_luamenu_anims.value and v.renderdeltatics() * 3 / 4 or FU
			
			self.cursor_position.x = ease.linear(speed, $, align + FixedMul(width, factor) - FU * (24 or 32)) --tied to fps
			self.cursor_position.y = ease.linear(speed, $, py)
			
			v.drawScaled(x + self.cursor_position.x, y + self.cursor_position.y, FU, cachePatch("M_CURSOR"), 0)
		end
	end
	
	--draw classic tooltip
	if self.items[self.selection] and cv_luamenu_tooltips.value then
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
-- 			v.drawScaled(self.cursor_position.x, self.cursor_position.y, FU, cachePatch("M_CURSOR"), 0)
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
MenuItem = MenuClass:inherit()

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
-- 		x = width / 2
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
MenuItem_Text = MenuItem:inherit()

function MenuItem_Text:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.label = $ or "Button"
	a.font = $ or "STCFN"
	a.scale = $ or FU
	
	a.parent_width = $ or 0
	
	a.colored = $ or false
	a.force_lowercase = $ or false
	
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

function MenuItem_Text:recalcLayout()
	local label = self.label
	local uppercase = cv_menucaps.value and not self.force_lowercase
	local layout = {}
	self.text_layout = layout
	
	local line = {}
	
	if uppercase then
		label = $:upper()
	end
	
	local width = 0
	local parent_width = FixedDiv(self.parent_width, self.scale or 1)
	
	for i = 1, label:len() + 1 do
		local char = label:sub(i, i)
		
		local code = char:byte()
		
		if char == "\n" or i == label:len() + 1 then
			line.width = width
			table.insert(layout, line)
			width = 0
			line = {}
			
			continue
		elseif parent_width and width > parent_width then --word wrapping
			line.width = width
			width = 0
			
			local newline = {}
			local total_width = line[#line]
			
			--go through the letters from end and add stuff until we find a space
			for i = #line - 1, 1, -2 do
				if line[i] == " " then
					break
				end
				
				table.insert(newline, 1, line[i])
				table.insert(newline, 2, line[i + 1])
				
				width = $ + line.width - line[i + 1]
				line.width = line[i + 1]
				
				table.remove(line, i + 1)
				table.remove(line, i)
			end
			
			--push everything back
			local offset = newline[2]
			
			for i = 2, #newline, 2 do
				newline[i] = $ - offset
			end
			
			table.insert(layout, line)
			line = newline--{}
		end
		
		table.insert(line, char)
		table.insert(line, width)
		
		local patchname = self.font..ZeroNumber(code, 3)
		local patch = cachePatch(patchname)
		
		if patch then
			width = $ + FU * patch.width
		else
			width = $ + FU * 4
		end
	end
end

function MenuItem_Text:draw(x, y)
	local width, height = self:getBounds()
	
	local dupy = v.dupy() * FU
	if y < -((v.height() * FU - dupy * 200) / 2) - height then --TODO: support wrapping here
		return
	end
	
	if y > FU * 200 + (v.height() * FU - dupy * 200) / 2 then
		return
	end
	
	local uppercase = cv_menucaps.value and not self.force_lowercase
	
	if self._old_label ~= self.label or self._old_uppercase ~= uppercase
	or self._old_parent_width ~= self.parent_width--[[ or self._old_scale ~= self.scale]] then
		self._old_label = self.label
		self._old_uppercase = uppercase
		self._old_parent_width = self.parent_width
		self._old_scale = self.scale
		self:recalcLayout()
	end

	local label = self.label
	local scale = self.scale
	local width = 0
	local max_width = 0 --used to get text bounds
	local flags = self:getFlags(self.colored)
	local col = v.getStringColormap(flags)
	
	local lines = 0
	
	--run once: once to draw,
	for i, line in ipairs(self.text_layout) do
		local _, align_string, factor = self:getAlignment()
		local align_x = FixedMul(FixedMul(line.width, factor), self.scale)
		
		for ii = 1, #line, 2 do
			local char = line[ii]
			local char_x = x + FixedMul(line[ii + 1], scale) + align_x
			local char_y = y + (i - 1) * scale * 10
			
			local patch = cachePatch(self.font..ZeroNumber(char:byte(), 3))
			
			if patch then
				v.drawScaled(char_x, char_y, scale, patch, 0, col)
			end
		end
		
		max_width = max($, line.width)
	end
	
	self._width = max_width --this should be in recalcLayout
end

--menu button
MenuItem_Button = MenuItem_Text:inherit()

function MenuItem_Button:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.link = $ or nil
	a.cvar = $ or nil
	
	a.action = $ or nil
	
	a.text_label = $ or MenuItem_Text:new{colored = true, align = "right"}
	
	return a
end

function MenuItem_Text:drawArrows(x, y, col)
	local width, height = self:getBounds()
	local patch_left = cachePatch(self.font.."028")
	local patch_right = cachePatch(self.font.."029")
	
	--animation
	local out = FU * 2
	self.arrow_blink = (($ or 0) + v.renderdeltatics() / TICRATE * 4) % FU
	
	if self.arrow_blink >= FU / 2 then
		out = $ + FU
	end
	
	--right arrow
	v.drawScaled(x - width - FU * patch_left.width - out, y, FU, patch_left, 0, col)
	v.drawScaled(x + out, y, FU, patch_right, 0, col)
end

function MenuItem_Button:draw(x, y)
	self.super.draw(self, x, y)
	
	--only designed to be used with left alignment
	if self.cvar then
		self.text_label.label = self.cvar.string
		self.text_label:draw(x + self.parent.width, y)
		
		--TODO: function
		if self.parent and self.parent.selection == self.index then
			local flags = self.text_label:getFlags(self.text_label.colored)
			local col = v.getStringColormap(flags)
			self.text_label:drawArrows(x + self.parent.width, y, col)
		end
	end
end

function MenuItem_Button:activate(increment)
	if self.link == "" then
		Menu_SetActive(false)
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

--menu slider
MenuItem_Slider = MenuItem_Text:inherit()

function MenuItem_Slider:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.width = $ or FU * 60
	a.slider_scale = $ or FU / 3
	
	a.cvar = $ or nil
	
	a.slider_step = $ or 1
	
	a.slider_min = $ or nil
	a.slider_max = $ or nil
	
	return a
end

function MenuItem_Slider:getBounds()
	return self.width + FU * 4, FU * 8
end

local function get_percent(a, x, y)
	return FixedDiv(a - x, (y - x) or 1)
end

local function L_FixedDecimal(str, max)
	if max == nil then
		max = 2
	end
	
	return ("%."..max.."f"):format(str) --e.g. "%.4g"
end

function MenuItem_Slider:draw(x, y)
	self.super.draw(self, x, y)
	
	--only designed to be used with left alignment
	if self.cvar then
		do
			local side = cachePatch(cv_luamenu_sliders.value and "MENU_SLIDAR_SIDE" or "M_SLIDEL")
			local middle = cachePatch(cv_luamenu_sliders.value and "MENU_SLIDAR_MIDDLE" or "M_SLIDEM")
			local handle = cachePatch(cv_luamenu_sliders.value and "MENU_SLIDAR_HANDLE" or "M_SLIDEC")
			local scale = self.slider_scale
			local x = x + self.parent.width - self.width
			local y = y + self.scale * 8 / 2
			local true_scale = cv_luamenu_sliders.value and scale or scale * 3
			local true_x = cv_luamenu_sliders.value and x or x - FU * 3
			local true_y = cv_luamenu_sliders.value and y or y - FU * 4
			
			if cv_luamenu_sliders.value then
				v.drawScaled(true_x, true_y, true_scale, side, 0)
				v.drawStretched(true_x, true_y, self.width, true_scale, middle, 0)
				v.drawScaled(true_x + self.width, true_y, true_scale, side, V_FLIP)
			else
				v.drawScaled(true_x - FU * 2, true_y, true_scale, side, 0)
				v.drawStretched(true_x + FU, true_y, self.width / middle.width, true_scale, middle, 0)
				v.drawScaled(true_x + self.width + FU * 6, true_y, true_scale, side, V_FLIP)
			end
			
			local value = self.cvar.value
			
			if self._cvar_bounds == nil and self.slider_min == nil then
				self._cvar_bounds = true
				
				local i = 0
				
				while true do
					local value, strvalue = CV_GetPossibleValue(self.cvar, i)
					
					if strvalue == nil then
						break
					end
					
					if strvalue == "MIN" then
						self.slider_min = value
					elseif strvalue == "MAX" then
						self.slider_max = value
					end
					
					i = $ + 1
				end
			end
			
			local value_min = self.slider_min
			local value_max = self.slider_max
			local percent = get_percent(value, value_min, value_max)
			v.drawScaled(true_x + FixedMul(self.width, percent), true_y, true_scale, handle)
			
			local defaultvalue = self.cvar.defaultvalue
			
			if self.cvar.flags & CV_FLOAT then
				defaultvalue = tofixed($)
			end
				
			if self.cvar.value ~= self.cvar.defaultvalue then
				local percent = get_percent(defaultvalue, value_min, value_max)
				
				v.drawScaled(true_x + FixedMul(self.width, percent), true_y, true_scale, handle, V_60TRANS)
			end
			
			if self.parent and self.parent.selection == self.index then
				local value = value
				
				if self.cvar.flags & CV_FLOAT then
					value = L_FixedDecimal(value, 2)
				end
				
				v.drawString(x + FixedMul(self.width, FU / 2), y - FU * 3, value, V_TRANSLUCENT, "thin-fixed-center")
			end
		end
		
		--TODO: function
		if self.parent and self.parent.selection == self.index then
			local flags = cv_menucolor.value
			local col = v.getStringColormap(flags)
			self.font = $ or "STCFN" --hack
			MenuItem_Text.drawArrows(self, x + self.parent.width + FU * 2, y, col)
		end
	end
end

function MenuItem_Slider:activate(increment)
	if self.link == "" then
		Menu_SetActive(false)
		return
	end

	if self.link then
		Menu_GotoLink(self.link)
	end
	
	if self.cvar then
		local value = self.cvar.value + increment * self.slider_step
		
		local value_min = tonumber(self.slider_min)
		local value_max = tonumber(self.slider_max)
		
		value = min(max($, value_min), value_max)
		
-- 		local flags = self.cvar.flags
		if self.cvar.flags & CV_FLOAT then
			value = L_FixedDecimal(value, 4) --do not use 5
-- 			CV_SetFlags(self.cvar, flags & ~CV_FLOAT)
		end
		
		CV_Set(self.cvar, value, true)
		
-- 		CV_SetFlags(self.cvar, flags)
	end
	
	if self.action then
		next_action = self:action()
	end
end

--menu textbox
MenuItem_Textbox = MenuItem_Text:inherit()

function MenuItem_Textbox:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.cvar = $ or nil
	a.value = $ or (a.cvar and a.cvar.string) or ""
	
	a.cursor_blink = $ or 0
	
	a.box = $ or MenuItem_Box:new{width = FU * 250, height = FU * 15, align = "left"}
	a.box_label = $ or MenuItem_Text:new{}
	
	return a
end

function MenuItem_Textbox:getBounds()
	local width = self.box.width--self._width or 0
	local height = FU * 8 + FU * 2 + self.box.height --inaccurate in some cases
	
	return width, height
end

function MenuItem_Textbox:draw(x, y)
	self.super.draw(self, x, y)
	
	--only designed to be used with left alignment
-- 	local align, align_string, factor = self.box:getAlignment()
	self.box:draw(x + self.box.width / 2, y + FU * 8 + FU * 2)
	
	local text_padding = self.box.corner_size
	
	self.box_label.label = self.value
	self.cursor_blink = $ + v.renderdeltatics()
	
	if self.parent and self.parent.selection == self.index and (self.cursor_blink * 3 / TICRATE) % FU < FU / 2 then
		self.box_label.label = $.."|"
	end
	
	self.box_label:draw(x + text_padding, y + FU * 8 + FU * 2 + min(text_padding, self.box.height / 2 - FU * 8 / 2))
end

MenuItem_Textbox.activate = MenuItem_Button.activate

function MenuItem_Textbox:onKeyInput(key, name)
	if name == "backspace" then
		self.value = $:sub(1, $:len() - 1)
	end

-- 	if name == "enter" then
-- 		self:activate(1)
-- 	end
	
	if self.cvar then
		CV_Set(self.cvar, self.value, true)
	end
end

function MenuItem_Textbox:onTextInput(text)
	if text == nil then
		return true
	end
-- 	if not input.keyNumPrintable(key.num) then
-- 		return
-- 	end
	
-- 	print(text.text)
	self.value = $..text.text
	
	if self.cvar then
		CV_Set(self.cvar, self.value, true)
	end
end

--menu header label
MenuItem_Header = MenuItem:inherit()

function MenuItem_Header:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.label = $ or "Header"
	a.label_label = $ or MenuItem_Text:new{colored = true, label = a.label}
	
	a.pre_spacing = $ or FU * 16
	a.spacing = $ or FU * 3
	
	return a
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
	
	self.label_label:draw(new_x, y - FU * 9)
	
	local width = FU * 320 - new_x * 2
	v.drawFixedFill(new_x, y, width + FU, FU * 1 + FU, cv_menucolor.value ~= V_INVERTMAP and 26 or 0) --shadow
	v.drawFixedFill(new_x, y, width, FU * 1, VMAPToPaletteIndex[cv_menucolor.value] - 1) --line
end

--rounded box
--a lot of things inherit from this since things with backgrounds look much prettier
--than just raw text on a screen
MenuItem_Box = MenuItem:inherit()

function MenuItem_Box:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.width = $ or 0--FU * 50
	a.height = $ or 0--FU * 50
	a.scale = $ or FU
	a.color = $
	a.color_offset = $ or 0
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
	local corner_size = FixedMul(self.corner_size, cv_luamenu_rounded.value)
	corner_size = min(min($, height / 2), width / 2)
	
	width, height, corner_size = FixedMul($, self.scale), FixedMul($, self.scale), FixedMul($, self.scale)
	
	x = $ + self.x_offset - width / 2
	y = $ + self.y_offset - FixedMul(height / 2, self.scale - FU)
	
	local og_x, og_y, og_width, og_height = x, y, width, height
	
	x, y = $ + corner_size, $ + corner_size
	width, height = $ - corner_size * 2, $ - corner_size * 2
	
	local color = self.color
	
	if color == nil then
		color = cv_menubgcolor.value
	end
	
	color = $ + self.color_offset
	
	if self.visible then
		v.drawFixedFill(x, y, width, height, color)
		
		local colormap = v.getColormap(nil, nil, "Menu_Translation_"..color)
		
		local round = cachePatch("MENU_ROUND")
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

--button, but infused with what i like to call.. ui slop
MenuItem_UI_Button = MenuItem_Box:inherit()

function MenuItem_UI_Button:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.body = $ or "Body"
	a.width = $ or FU * 50
	a.height = $ or FU * 30
	
	a.on_draw = $ or nil
	
-- 	a.open_anim = $ or 0
	a.color_offset = $ or -3
	
	a.body_label = $ or MenuItem_Text:new{label = a.body, align = "center"}
	
	return a
end

function MenuItem_UI_Button:checkBounds(x, y, mx, my)
	return mx >= x - self.width / 2 and mx < x + self.width / 2
	and my >= y and my < y + self.height
end

function MenuItem_UI_Button:draw(x, y)
	local mx, my = ScreenToDisplay(input.getCursorPosition())
	local pressed = (mouse.buttons & MB_BUTTON1)
	local keyheld = false
	
	if self.keys then
		for i, key in ipairs(self.keys) do
			if keyHold[key] and not keyHold_lock[key] then
				keyheld = true
				
				break
			end
		end
	end
	
	pressed = $ or keyheld
	
	local scale_target = FU
	local scale_speed = FU / (TICRATE / 2)
	
	if self:checkBounds(x, y, mx, my) or keyheld or self._last_keyheld then
		self.color_offset = -4
-- 		self.scale = FU * 15 / 14
		scale_target = FU * 12 / 11
		
		if pressed then
			self.color_offset = -2
-- 			self.scale = FU
			scale_target = FU * 6 / 7
			scale_speed = FU / (TICRATE / 6)
		end
		
		if not pressed and self._last_pressed then
			if self.action then
				next_action = self:action()
				
				if next_action == true then
					next_action = nil
					
					current_popup = nil
				end
			end
		end
	else
		self.color_offset = -3
-- 		self.scale = FU
		scale_target = FU
	end
	
	if self.scale < scale_target then
		self.scale = min($ + FixedMul(scale_speed, v.renderdeltatics()), scale_target)
	elseif self.scale > scale_target then
		self.scale = max($ - FixedMul(scale_speed, v.renderdeltatics()), scale_target)
	end
	
	self._last_pressed = pressed
	self._last_keyheld = keyheld

	--draw box
	self.super.draw(self, x, y)
	
	self.body_label.scale = self.scale
	self.body_label:draw(x, y + self.height / 2 - self.body_label.scale * 8 / 2) --TODO: height bouns
end

function MenuItem_UI_Button:canSelect()
	return true
end

MenuItem_UI_Button.activate = MenuItem_Button.activate

--sliding popup
MenuItem_Popup = MenuItem_Box:inherit()

function MenuItem_Popup:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.title = $ or "Title"
	a.body = $ or "Body"
	a.width = $ or FU * 250
	a.height = $ or FU * 100
	
	a.on_draw = $ or nil
	
	a.open_anim = $ or 0
	
	a.buttons = $ or {}
	a.keys = $ or nil
	
	a.title_label = $ or MenuItem_Text:new{label = a.title, align = "center"}
	a.body_label = $ or MenuItem_Text:new{label = a.body, align = "center"}
	
	return a
end

function MenuItem_Popup:draw(x, y)
	if cv_luamenu_anims.value then
		self.open_anim = min($ + v.renderdeltatics() / TICRATE * 4, FU)
	else
		self.open_anim = FU
	end
	y = ease.outcubic(self.open_anim, $ + FU * 100, $)

	v.fadeScreen(0xFF00, ease.outcubic(self.open_anim, FU * 0, FU * 16) / FU)
	
	--draw box
	self.super.draw(self, x, y)
	
	local width, height = self:getBounds()
	x = $ + self.x_offset - width / 2
	y = $ + self.y_offset
	
	local og_x, og_y, og_width, og_height = x, y, width, height
	local corner_size = self.corner_size
	
	x, y = $ + corner_size, $ + corner_size
	width, height = $ - corner_size * 2, $ - corner_size * 2
	
	if self.visible then
		self.title_label:draw(x + width / 2, y - corner_size - FU * 4)
		self.body_label.parent_width = width
		self.body_label:draw(x + width / 2, y + FU * 8)
		
		local num_buttons = #self.buttons
		
		for i, v in ipairs(self.buttons) do
			local button_x = ease.linear(FU * i / (num_buttons + 1), x, x + width)
			v:draw(button_x, y + self.height - v.height / 2)
		end
	end
end

local function ShowPopup(title, message, buttons)
	local popup = MenuItem_Popup:new{title = title, body = message,
		buttons = {},
	}
	
	buttons = $ or {{body = "OK", keys = {"escape", "enter", "y"}, action = function(self) return true end}}
	
	if buttons then
		for i, v in ipairs(buttons) do
			table.insert(popup.buttons, 
				MenuItem_UI_Button:new{body = v.body, action = v.action, keys = v.keys, width = v.width}
			)
		end
	end
	
	current_popup = popup
end




local function DrawSpikes(rot, patch, ox, oy, scroll, flags)
	local col = v.getColormap(nil, nil, "Menu_Translation_"..cv_menubgcolor.value - 2)
	local bg2 = cachePatch("MENU_SPIKE")
	local bg = cachePatch(patch)
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
	if chatactive then state = "chat" end
	
	return state
end

local function Input(key)
	if not gks_luamenu then return end
	
	local name = key.name:lower()
	local state = GetState()
	
	keyHold[name] = true
	
	if menuactive and current_popup then
		--dismiss the popup
		input.setTextInputMode(false)
-- 		if name == "escape" then
-- 			current_popup = nil
-- 		end
		
		return
	end
	
	if name == "escape" then
		if state == "game" and not menuactive then
			current_menu = "SP_MainMenu"
			Menu_SetActive(true)
			
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
			Menu_SetActive(false)
		end
		
		return
	elseif name == "enter" and not menuactive then
		if state == "title" then
	-- 		print(name)
			
			current_menu = "MainMenu"
			
			Menu_SetActive(true)
		end
		
		return
	end
	
	if not menuactive then return end
	
	local menu = menus[current_menu]
	assert(menu, ("Input: Invalid menu \"%s\"!"):format(tostring(current_menu))) --r
	
	if menu.on_input and menu:on_input(key, name) then
		return
	end
	
	if menu.items[menu.selection] and menu.items[menu.selection].onKeyInput
	and menu.items[menu.selection]:onKeyInput(key, name) then
		return
	end
	
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
		keyHold_lock[name] = true
		
		for i, item in ipairs(menu.items) do
			if i == menu.selection then
				item:activate(name == "left arrow" and -1 or 1)
				S_StartSound(nil, sfx_menu1) --local sound
				
				break
			end
		end
	end
	
	input.setTextInputMode(false)
	
	if menu.items[menu.selection] and menu.items[menu.selection].onTextInput
	and menu.items[menu.selection]:onTextInput() then
		input.setTextInputMode(true)
	end
	
	if key.num == input.gameControlToKeyNum(GC_CONSOLE)
	or key.num == input.gameControl2ToKeyNum(GC_CONSOLE) then
		return
	end
	
	return true
end

--first time i've ever used this hook
addHook("KeyDown", Input)

addHook("KeyUp", function(key)
	local name = key.name:lower()
	
	keyHold[name] = nil
	keyHold_lock[name] = nil
end)

addHook("TextInput", function(text)
	if not menuactive then return end
	
	local menu = menus[current_menu]
	assert(menu, ("Input: Invalid menu \"%s\"!"):format(tostring(current_menu))) --r
	
	if menu.items[menu.selection] and menu.items[menu.selection].onTextInput
	and menu.items[menu.selection]:onTextInput(text) then
		return
	end
end)

local mouse_pressed = false
local mouse_drag = {x = 0, y = 0, dragging = false, start_scroll = 0, updates = 0, prev_x = 0, prev_y = 0}

local function Drawer(drawer, player)
	if not gks_luamenu then return end
	
-- 	local serverlistcount = #serverlist
-- 	print(serverlistcount, servernode)
	if not menuactive then return end
	
	--localize drawing functions into a table
	if #v == 0 then
		for i, fun in pairs(drawer) do
			v[i] = fun
		end
		
		v.drawFixedFill = $ or function(x, y, width, height, color)
			--v.drawFill(x / FU, y / FU, width / FU, height / FU, color)
			
			local patch = cachePatch("MENU_PIXEL")
			local colormap = v.getColormap(nil, nil, "Menu_Translation_"..(color & 255))
			
			v.drawStretched(x, y, width, height, patch, color & ~255, colormap)
		end
	end
	
	v.fadeScreen(0xFF00, 16)
	
	menu_time = $ + v.renderdeltatics()
	
	menu_enter_anim = min($ + v.renderdeltatics() / 10, FU)
	menu_exit_anim = min($ + v.renderdeltatics() / 10, FU)
	
	current_menu = $ or "MainMenu"
	
	local menu = menus[current_menu]
	assert(menu, ("Drawer: Invalid menu \"%s\"!"):format(tostring(current_menu)))
	
	local mx, my = ScreenToDisplay(input.getCursorPosition())
-- 	v.drawString(20, 10, (mx / FU).." "..(my / FU))
-- 	v.drawString(20, 20, v.width())
	
	if (mouse.buttons & MB_BUTTON1) and not current_popup then
		--hack to stop initial positions from messing up the drag
		if mouse_drag.x ~= mx or mouse_drag.y ~= my then
			mouse_drag.updates = ($ or 0) + 1
		end
		
		if v.renderisnewtic() then
			mouse_drag.dx, mouse_drag.dy = mouse_drag.prev_x - mx, mouse_drag.prev_y - my
		end
		
		if not mouse_pressed or mouse_drag.updates <= 2 then--or true then
			mouse_drag.x, mouse_drag.y = mx, my
			mouse_drag.prev_x, mouse_drag.prev_y = mx, my
			mouse_drag.start_scroll = menu.scroll
		end
		
		if abs(mouse_drag.y - my) >= FU * 3 then
			mouse_drag.dragging = true
		end
		
-- 		menu.scroll = mouse_drag.start_scroll + mouse_drag.y - my
-- 		menu.dest_scroll_time = FU
-- 		menu.dest_scroll = menu.scroll
		if v.renderisnewtic() and mouse_drag.dragging then
			menu.scroll_vel = FixedMul(-my + mouse_drag.prev_y, v.renderdeltatics())--mouse_drag.y - my
		end
		
		mouse_pressed = true
	else
		if mouse_pressed and not mouse_drag.dragging and not current_popup then
			local menux, menuy = menu:getPosition()
			menuy = $ - menu.scroll
			for i, item in ipairs(menu.items) do
				local width, height = item:getBounds()
				local y = menu:getYPositionAt(i) + menuy
				
				if not (my >= y and my < y + height) then continue end
				
				if i == menu.selection then
					item:activate(1)
				else
					menu.selection = i
				end
				
				break
			end
		end
		
		if mouse_drag.dragging then
			local total_height = menu:getYPositionAt(#menu.items + 1)
			
			if total_height > menu.height then --also make this a function
				if menu.scroll > total_height - FU * 150 then
					menu.scroll_vel = 0
					menu.dest_scroll_time = 0
					menu.dest_scroll_origin = menu.scroll
					menu.dest_scroll = total_height - FU * 150
				end
				
				if menu.scroll < 0 then
					menu.scroll_vel = 0
					menu.dest_scroll_time = 0
					menu.dest_scroll_origin = menu.scroll
					menu.dest_scroll = 0
				end
			else
				menu.scroll_vel = 0
				menu.dest_scroll_time = 0
				menu.dest_scroll_origin = menu.scroll
				menu.dest_scroll = 0
			end
		end
		
		mouse_drag.dragging = false
		mouse_pressed = false
	end
	
	if v.renderisnewtic() then
		mouse_drag.prev_x, mouse_drag.prev_y = mx, my
	end
	
	if (mouse.buttons & MB_SCROLLDOWN) then
		menu.scroll_vel = $ + FU / 6
	end
	
	if (mouse.buttons & MB_SCROLLUP) then
		menu.scroll_vel = $ - FU / 6
	end
	
	local total_height = menu:getYPositionAt(#menu.items + 1)
	
	if not mouse_drag.dragging and menu.dest_scroll_time == FU and total_height > menu.height then
		if menu.scroll > total_height - FU * 150 then
			menu.scroll_vel = 0
			menu.dest_scroll_time = 0
			menu.dest_scroll_origin = menu.scroll
			menu.dest_scroll = total_height - FU * 150
		end
		
		if menu.scroll < 0 then
			menu.scroll_vel = 0
			menu.dest_scroll_time = 0
			menu.dest_scroll_origin = menu.scroll
			menu.dest_scroll = 0
		end
	end
	
	--TODO:
	
	menu.scroll = $ + menu.scroll_vel
	
	if menu.scroll_vel then
		menu.dest_scroll_time = FU
		menu.dest_scroll = menu.scroll
		menu.scroll_vel = max(abs($) - v.renderdeltatics() / 5, 0) * ($ < 0 and -1 or 1)
	end
	
	if cv_luamenu_bgdecos.value then
		local speed = FU / TICRATE / 2
		DrawSpikes(ANG1 * 10, "MENU_SPIKE_2", 0, FU * 155, (FixedMul(menu_time, speed) + menu.scroll / 64) % FU, V_SNAPTOBOTTOM|V_SNAPTOLEFT)
		DrawSpikes(ANG1 * 10 + ANGLE_180, "MENU_SPIKE_3", FU * 270, FU * 40, (FixedMul(menu_time, speed) + menu.scroll / 64) % FU, V_SNAPTOTOP|V_SNAPTORIGHT)
	end
	
	--to differentiate the two
	if menu.show_version then
		v.drawString(0 + FU * 8, FU * 200 - FU * 8 - FU * 8, VERSIONSTRING.." luamenu", V_TRANSLUCENT|V_ALLOWLOWERCASE|V_SNAPTOLEFT|V_SNAPTOBOTTOM, "thin-fixed")
	end
	
	menu:draw()
	
	--draw popup
	if current_popup then
		current_popup:draw(FU * 320 / 2, FU * 100 / 2)
	end
	
-- 	v.drawScaled(mx, my, FU, cachePatch("M_CURSOR"))
end

addHook("MenuThinker", function()
	if not menuactive then return end
	
	if next_action then
		local action = next_action
		
		next_action = nil
		local active = action()
		
		if active ~= nil then
			Menu_SetActive(active)
		end
	end
end)

hud.add(Drawer, "menu")