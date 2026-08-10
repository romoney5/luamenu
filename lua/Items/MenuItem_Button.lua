--menu button
MenuItem_Button = MenuItem_Text:inherit()

function MenuItem_Button:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.link = $ or nil
	a.cvar = $ or nil
	
	a.action = $ or nil
	
	a.text_label = $ or MenuItem_Text:new{colored = true, align = "right", label = ""}
	
	return a
end

function MenuItem_Button:draw(x, y)
	local _, align_string, factor = self:getAlignment()
	local width, height = self:getBounds()
	local align_x = FixedMul(FixedMul(width, factor), self.scale)
	width = self.parent.width
	height = $ + min(FU * 2, self.spacing)
	v.drawFixedFill(x + align_x - FU, y - FU, width + FU * 2, height + FU * 2, cv_menubgcolor.value) --top/bottom edges
	
	self.super.draw(self, x, y)
	
	--only designed to be used with left alignment
	if self.cvar then
		self.text_label.label = self.cvar.string
		
		--TODO: function
		if self.parent and self.parent.selection == self.index then
			local flags = self.text_label:getFlags(self.text_label.colored)
			local col = v.getStringColormap(flags)
			self.text_label:drawArrows(x + self.parent.width, y, col)
		end
	end
	
	self.text_label:draw(x + self.parent.width, y)
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
		--floats are special in various ways
		if self.cvar.flags & CV_FLOAT then
			local step = FU * 625 / 10000
			local value = self.cvar.value + increment * step
			
			value = FixedDecimal(value, 4)
			
			Banpyura.CV_ForceSet(self.cvar, value)
		else
			Banpyura.CV_ForceAddValue(self.cvar, increment)
		end
	end
	
	if self.action then
		next_action = self:action()
	end
end