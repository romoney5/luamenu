--menu button
MenuItem_Button = MenuItem_Text:inherit()

function MenuItem_Button:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.link = $ or nil
	a.cvar = $ or nil
	
	a.action = $ or nil
	a.on_draw = $ or nil
	
	a.text_label = $ or MenuItem_Text:new{colored = true, align = "right", label = ""}
	
	return a
end

function MenuItem_Button:draw(x, y)
	self.super.draw(self, x, y)
	
	if self.on_draw then
		self:on_draw(x, y)
	end
	
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
		CV_AddValue(self.cvar, increment, true)
	end
	
	if self.action then
		next_action = self:action()
	end
end