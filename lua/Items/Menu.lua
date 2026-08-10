--menu page

--scrolling vars
local mouse_pressed = false
local mouse_drag = {x = 0, y = 0, dragging = false, start_scroll = 0, updates = 0, prev_x = 0, prev_y = 0}

Menu = MenuClass:inherit()

local function hybridPadding()
	return FU * 3 / 2 + pref_luamenu_rounded.value / 2
end

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
	
	a.width = $ or FU * 320
	a.height = $ or FU * 200
	
	a.enter_anim = $ or FU
	a.exit_anim = $ or FU
	
	a.cursor_position = $ or {x = 0, y = 0}
	
	a.items = $ or {}
	
	a.on_draw = $ or nil
	a.on_entry = $ or nil
	a.on_exit = $ or nil
	
	a.parent = $ or nil
	
	a.title = $ or ""
	a.title_label = $ or MenuItem_Text:new{font = "MENU_FONT_HEADER_", label = a.title, align = "center"}
	
	a.x_offset = $ or 0
	
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
		x = $ + self.x_offset
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

function Menu:resetScroll()
	self.scroll_vel = 0
	self.dest_scroll_time = 0
	self.dest_scroll_origin = self.scroll
	self.dest_scroll = 0
end

--TODO: scrolling is tied to fps
function Menu:updateScroll()
	local mx, my = ScreenToDisplay(input.getCursorPosition())
	
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
			mouse_drag.start_scroll = self.scroll
		end
		
		if abs(mouse_drag.y - my) >= FU * 3 then
			mouse_drag.dragging = true
		end
		
		if v.renderisnewtic() and mouse_drag.dragging then
			self.scroll_vel = FixedMul(-my + mouse_drag.prev_y, v.renderdeltatics())
		end
		
		mouse_pressed = true
	else
		if mouse_pressed and not mouse_drag.dragging and not current_popup then
			local menux, menuy = self:getPosition()
			menuy = $ - self.scroll
			for i, item in ipairs(self.items) do
				local width, height = item:getBounds()
				local y = self:getYPositionAt(i) + menuy
				
				if not (my >= y and my < y + height) then continue end
				
				if i == self.selection then
					item:activate(1)
				else
					self.selection = i
				end
				
				break
			end
		end
		
		if mouse_drag.dragging then
			local total_height = self:getYPositionAt(#self.items + 1)
			
			if total_height > self.height then --also make this a function
				if self.scroll > total_height - FU * 150 then
					self:resetScroll()
					self.dest_scroll = total_height - FU * 150
				end
				
				if self.scroll < 0 then
					self:resetScroll()
				end
			else
				self:resetScroll()
			end
		end
		
		mouse_drag.dragging = false
		mouse_pressed = false
	end
	
	if v.renderisnewtic() then
		mouse_drag.prev_x, mouse_drag.prev_y = mx, my
	end
	
	if (mouse.buttons & MB_SCROLLDOWN) then
		self.scroll_vel = min(max($, 0) + FU / 3, FU * 4)
	end
	
	if (mouse.buttons & MB_SCROLLUP) then
		self.scroll_vel = max(min($, 0) - FU / 3, -FU * 4)
	end
	
	local total_height = self:getYPositionAt(#self.items + 1)
	
	if not mouse_drag.dragging and self.dest_scroll_time == FU and total_height > self.height then
		if self.scroll > total_height - FU * 150 then
			self:resetScroll()
			self.dest_scroll = total_height - FU * 150
		end
		
		if self.scroll < 0 then
			self:resetScroll()
		end
	end
	
	--TODO:
	
	self.scroll = $ + self.scroll_vel
	
	if self.scroll_vel then
		self.dest_scroll_time = FU
		self.dest_scroll = self.scroll
		self.scroll_vel = max(abs($) - v.renderdeltatics() / 5, 0) * ($ < 0 and -1 or 1)
	end
	
	if pref_luamenu_anims.value then
		self.dest_scroll_time = min($ + v.renderdeltatics() / 5, FU)
	else
		self.dest_scroll_time = FU
	end
	
	self.scroll = ease.outquad(self.dest_scroll_time, self.dest_scroll_origin, self.dest_scroll)
	
	--[[
	v.drawScaled(mx, my, FU, cachePatch("M_CURSOR"))
	v.drawString(0, 0, (mx / FU).."\n"..(my / FU), 0)
	]]
end

function Menu:getPosition()
	local anchor = self.anchor
	
	local x, y = 0, 0
	
	if anchor.x == "center" then
		x = $ + FU * 320 / 2
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
	
	--to differentiate the two
	if self.show_version and pref_luamenu_showversion.value then
		v.drawString(0 + FU * 8, FU * 200 - FU * 8 - FU * 8, VERSIONSTRING.." luamenu", V_TRANSLUCENT|V_ALLOWLOWERCASE|V_SNAPTOLEFT|V_SNAPTOBOTTOM, "thin-fixed")
	end
	
	y = $ - self.scroll
	
	self.enter_anim = min($ + v.renderdeltatics() / 10, FU)
	self.exit_anim = min($ + v.renderdeltatics() / 10, FU)
	
	x = $ + ease.outcubic(self.enter_anim, FU * 15, 0)
	x = $ - ease.outcubic(self.exit_anim, FU * 15, 0)
	
	--draw header
	if self.title_label then
		self.title_label.label = self.title
		if pref_luamenu_anims.value then
			self.title_label.scale = max(FU - self.scroll / 512, 0)
			self.title_label:draw(x, y - FU * 35 + self.scroll / 4)
		else
			self.title_label.scale = FU
			self.title_label:draw(x, y - FU * 35)
		end
	end
	
	--this needs to be separate from getPosition because of the header
	x = $ + self.x_offset
	
	--draw hybrid mode boxes
	if pref_luamenu_layoutmode.value >= 2 then
		local hybrid_box_positions = {}
		local box_index = 1
		local padding = hybridPadding() * 3 / 2
		
		for i, item in ipairs(self.items) do
			local py = self:getYPositionAt(i)
			local align, align_string, factor = item:getAlignment()
-- 			local width, height = item:getBounds()
			local height = self:getHeightOf(i)
			local spacing_threshold = FU * 2
			height = $ + min(spacing_threshold, item.spacing)
			
			if item:canSelect() then
				hybrid_box_positions[box_index] = $ or {width = self.width, height = -padding, x = align, y = py}
				
				hybrid_box_positions[box_index].height = $ + height
			end
			
			if (not item:canSelect() or item.spacing > spacing_threshold) and hybrid_box_positions[box_index] then
				box_index = $ + 1
			end
			
-- 			local align_x = FixedMul(FixedMul(width, factor), item.scale or FU)
-- 			width = self.width
-- 			v.drawFixedFill(x + align + align_x - FU, y + py - FU, width + FU * 2, height + FU * 2, cv_menubgcolor.value) --top/bottom edges
		end
		
		local corner_size = FixedMul(FU * 5, pref_luamenu_rounded.value)
		for i, box in ipairs(hybrid_box_positions) do
			local width = box.width + padding * 2
			local height = box.height + padding * 2
			local fixed_corner_size = min(min(corner_size, height / 2), width / 2)
			MenuItem_Box:drawBox(x + box.x - padding, y + box.y - padding, width, height, cv_menubgcolor.value - 1, fixed_corner_size)
		end
		
-- 		for i, v in ipairs(hybrid_box_info) do
-- 			local item = self.items[i]
-- 			local py = self:getYPositionAt(i)
-- 			local align, align_string, factor = item:getAlignment()
-- 			local width, height = item:getBounds()
-- 			local align_x = FixedMul(FixedMul(width, factor), item.scale or FU)
-- 			width = self.width
-- 			height = $ + min(FU * 2, item.spacing)
-- 			v.drawFixedFill(x + align + align_x - FU, y + py - FU, width + FU * 2, height + FU * 2, cv_menubgcolor.value) --top/bottom edges
-- 		end
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
			local speed = pref_luamenu_anims.value and v.renderdeltatics() * 3 / 4 or FU
			
			self.cursor_position.x = ease.linear(speed, $, align + FixedMul(width, factor) - FU * (24 or 32)) --tied to fps
			self.cursor_position.y = ease.linear(speed, $, py)
			
			v.drawScaled(x + self.cursor_position.x, y + self.cursor_position.y, FU, cachePatch("M_CURSOR"), 0)
		end
	end
	
	--draw classic tooltip
	if self.items[self.selection] and pref_luamenu_tooltips.value then
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

		if i == index then
			return y
		end
		
		local height = self:getHeightOf(i)
		
		y = $ + height + item.spacing
	end
	
	return y
end

function Menu:getHeightOf(index)
	local item = self.items[index]
	
	assert(item, "Menu:getHeightOf: invalid index!")
	
	local width, height = item:getBounds()
	
	if pref_luamenu_layoutmode.value >= 2 then
		height = $ + hybridPadding()
	end
	
	return height
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