--menu button
MenuItem_Button = MenuItem_Text:inherit()

function MenuItem_Button:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.link = $ or nil
	a.cvar = $ or nil
	a.pref = $ or nil
	
	a.value_step = $ or 1
	
	a.action = $ or nil
	
	a.text_label = $ or MenuItem_Text:new{colored = true, align = "right", label = ""}
	
	return a
end

function MenuItem_Button:drawArrowsCheck(x, y)
	if self.parent and self.parent.selection == self.index then
		local flags = self.text_label:getFlags(self.text_label.colored)
		local col = v.getStringColormap(flags)
		self.text_label:drawArrows(x + self.parent.width, y, col)
	end
end

function MenuItem_Button:draw(x, y)
	MenuItem_Text.draw(self, x, y)
	
	--only designed to be used with left alignment
	local option = self.pref or self.cvar
	
	if option then
		self.text_label.label = Prefs:getString(option)
		
		self:drawArrowsCheck(x, y)
	end
	
	self.text_label:draw(x + self.parent.width, y)
end

function MenuItem_Button:activate(increment)
	if self.link == "" then
		Menu_SetActive(false)
		return
	end

	if self.link then
		local params = self.link_params
		
		if type(params) == "function" then
			params = params(self, menus[self.link])
		end
		
		Menu_GotoLink(self.link, params)
	end
	
	local option = self.pref or self.cvar
	
	if option then
		Prefs:addValue(option, self.value_step * increment)
	end
	
	if self.action then
		next_action = self:action()
	end
end