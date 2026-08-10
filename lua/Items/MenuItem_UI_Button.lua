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