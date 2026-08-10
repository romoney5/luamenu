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
	a.on_input = $ or nil
	
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
		
		if self.on_draw then
			self:on_draw(x, y, width, height)
		end
	end
end

function MenuItem_Popup:close()
	if current_popup == self then
		current_popup = nil
	end
end

function ShowPopup(title, message, buttons)
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
	
	return popup
end