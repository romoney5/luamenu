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