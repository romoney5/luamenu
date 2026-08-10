--menu header label

--values from banpyura
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

function MenuItem_Header:draw(x, y)
	local width, height = self:getBounds()
	local new_x = x - FU * 11
	
	self.label_label:draw(new_x, y - FU * 9)
	
	local width = FU * 320 - new_x * 2
	v.drawFixedFill(new_x, y, width + FU, FU * 1 + FU, cv_menucolor.value ~= V_INVERTMAP and 26 or 0) --shadow
	v.drawFixedFill(new_x, y, width, FU * 1, VMAPToPaletteIndex[cv_menucolor.value] - 1) --line
end