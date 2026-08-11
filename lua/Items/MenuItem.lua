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
	
	a.condition = $ or nil --see Items/Menu.lua
	
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

function MenuItem:draw()
	return
end

function MenuItem:activate(increment)
	return
end