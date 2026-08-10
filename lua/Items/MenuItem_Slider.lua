--menu slider
local function get_percent(a, x, y)
	return FixedDiv(a - x, (y - x) or 1)
end

MenuItem_Slider = MenuItem_Text:inherit()


function MenuItem_Slider:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.width = $ or FU * 60
	a.slider_scale = $ or FU / 3
	
	a.cvar = $ or nil
	
	a.slider_step = $ or 1
	
	a.slider_min = $ or nil
	a.slider_max = $ or nil
	
	return a
end

function MenuItem_Slider:getBounds()
	return self.width + FU * 4, FU * 8
end

function MenuItem_Slider:draw(x, y)
	self.super.draw(self, x, y)
	
	--only designed to be used with left alignment
	if self.cvar then
		do
			local side = cachePatch(cv_luamenu_sliders.value and "MENU_SLIDAR_SIDE" or "M_SLIDEL")
			local middle = cachePatch(cv_luamenu_sliders.value and "MENU_SLIDAR_MIDDLE" or "M_SLIDEM")
			local handle = cachePatch(cv_luamenu_sliders.value and "MENU_SLIDAR_HANDLE" or "M_SLIDEC")
			local scale = self.slider_scale
			local x = x + self.parent.width - self.width
			local y = y + self.scale * 8 / 2
			local true_scale = cv_luamenu_sliders.value and scale or scale * 3
			local true_x = cv_luamenu_sliders.value and x or x - FU * 3
			local true_y = cv_luamenu_sliders.value and y or y - FU * 4
			
			if cv_luamenu_sliders.value then
				v.drawScaled(true_x, true_y, true_scale, side, 0)
				v.drawStretched(true_x, true_y, self.width, true_scale, middle, 0)
				v.drawScaled(true_x + self.width, true_y, true_scale, side, V_FLIP)
			else
				v.drawScaled(true_x - FU * 2, true_y, true_scale, side, 0)
				v.drawStretched(true_x + FU, true_y, self.width / middle.width, true_scale, middle, 0)
				v.drawScaled(true_x + self.width + FU * 6, true_y, true_scale, side, V_FLIP)
			end
			
			local value = self.cvar.value
			
			if self._cvar_bounds == nil and self.slider_min == nil then
				self._cvar_bounds = true
				
				local i = 0
				
				while true do
					local value, strvalue = Banpyura.CV_GetPossibleValue(self.cvar, i)
					
					if strvalue == nil then
						break
					end
					
					if strvalue == "MIN" then
						self.slider_min = value
					elseif strvalue == "MAX" then
						self.slider_max = value
					end
					
					i = $ + 1
				end
			end
			
			local value_min = self.slider_min
			local value_max = self.slider_max
			local percent = get_percent(value, value_min, value_max)
			v.drawScaled(true_x + FixedMul(self.width, percent), true_y, true_scale, handle)
			
			local defaultvalue = self.cvar.defaultvalue
			
			if self.cvar.flags & CV_FLOAT then
				defaultvalue = tofixed($)
			end
				
			if self.cvar.value ~= self.cvar.defaultvalue then
				local percent = get_percent(defaultvalue, value_min, value_max)
				
				v.drawScaled(true_x + FixedMul(self.width, percent), true_y, true_scale, handle, V_60TRANS)
			end
			
			if self.parent and self.parent.selection == self.index then
				local value = value
				
				if self.cvar.flags & CV_FLOAT then
					value = FixedDecimal(value, 2)
				end
				
				v.drawString(x + FixedMul(self.width, FU / 2), y - FU * 3, value, V_TRANSLUCENT, "thin-fixed-center")
			end
		end
		
		--TODO: function
		if self.parent and self.parent.selection == self.index then
			local flags = cv_menucolor.value
			local col = v.getStringColormap(flags)
			self.font = $ or "STCFN" --hack
			MenuItem_Text.drawArrows(self, x + self.parent.width + FU * 2, y, col)
		end
	end
end

function MenuItem_Slider:activate(increment)
	if self.link == "" then
		Menu_SetActive(false)
		return
	end

	if self.link then
		Menu_GotoLink(self.link)
	end
	
	if self.cvar then
		local value = self.cvar.value + increment * self.slider_step
		
		local value_min = tonumber(self.slider_min)
		local value_max = tonumber(self.slider_max)
		
		value = min(max($, value_min), value_max)
		
		if self.cvar.flags & CV_FLOAT then
			value = FixedDecimal(value, 4)
		end
		
		Banpyura.CV_ForceSet(self.cvar, value)
	end
	
	if self.action then
		next_action = self:action()
	end
end