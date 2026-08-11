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
	
	--make the box stand out against hybrid mode's boxes
-- 	if pref_luamenu_layoutmode.value >= 2 then
-- 		self.box.color_offset = -2
-- 	else
-- 		self.box.color_offset = 0
-- 	end
	
	--only designed to be used with left alignment
-- 	local align, factor = self.box:getAlignment()
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
		Banpyura.CV_ForceSet(self.cvar, self.value)
	end
end

function MenuItem_Textbox:onTextInput(text)
	if text == nil then
		return true
	end
	
	self.value = $..text.text
	
	if self.cvar then
		Banpyura.CV_ForceSet(self.cvar, self.value)
	end
end