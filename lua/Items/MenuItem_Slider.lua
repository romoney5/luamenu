--menu slider
local function get_percent(a, x, y)
	return FixedDiv(a - x, (y - x) or 1)
end

MenuItem_Slider = MenuItem_Button:inherit()

function MenuItem_Slider:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.width = $ or FU * 60
	a.slider_scale = $ or FU / 3
	
	a.slider_min = $ or nil
	a.slider_max = $ or nil
	
	return a
end

function MenuItem_Slider:getBounds()
	return self.width + FU * 4, FU * 8
end

function MenuItem_Slider:draw(x, y)
	MenuItem_Text.draw(self, x, y)
	
	--only designed to be used with left alignment
	local option = self.pref or self.cvar
	
	if option then
		do
			local side = cachePatch(pref_luamenu_sliders.value and "MENU_SLIDAR_SIDE" or "M_SLIDEL")
			local middle = cachePatch(pref_luamenu_sliders.value and "MENU_SLIDAR_MIDDLE" or "M_SLIDEM")
			local handle = cachePatch(pref_luamenu_sliders.value and "MENU_SLIDAR_HANDLE" or "M_SLIDEC")
			local scale = self.slider_scale
			local x = x + self.parent.width - self.width
			local y = y + self.scale * 8 / 2
			local true_scale = pref_luamenu_sliders.value and scale or scale * 3
			local true_x = pref_luamenu_sliders.value and x or x - FU * 3
			local true_y = pref_luamenu_sliders.value and y or y - FU * 4
			
			if pref_luamenu_sliders.value then
				v.drawScaled(true_x, true_y, true_scale, side, 0)
				v.drawStretched(true_x, true_y, self.width, true_scale, middle, 0)
				v.drawScaled(true_x + self.width, true_y, true_scale, side, V_FLIP)
			else
				v.drawScaled(true_x - FU * 2, true_y, true_scale, side, 0)
				v.drawStretched(true_x + FU, true_y, self.width / middle.width, true_scale, middle, 0)
				v.drawScaled(true_x + self.width + FU * 6, true_y, true_scale, side, V_FLIP)
			end
			
			local value = Prefs:getValue(option)
			
			if self._cvar_bounds == nil and self.slider_min == nil then
				self._cvar_bounds = true
				
				self.slider_min, self.slider_max = Prefs:getPossibleValueBounds(option)
			end
			
			local value_min = self.slider_min
			local value_max = self.slider_max
			local percent = get_percent(value, value_min, value_max)
			v.drawScaled(true_x + FixedMul(self.width, percent), true_y, true_scale, handle)
			
			local defaultvalue = option.defaultvalue
			
			if self.cvar and self.cvar.flags & CV_FLOAT then
				defaultvalue = tofixed($)
			end
				
			if value ~= defaultvalue then
				local percent = get_percent(defaultvalue, value_min, value_max)
				
				v.drawScaled(true_x + FixedMul(self.width, percent), true_y, true_scale, handle, V_60TRANS)
			end
			
			if self.parent and self.parent.selection == self.index then
				local value = value
				
				if (self.cvar and self.cvar.flags & CV_FLOAT) or (self.pref and self.pref.is_float) then
					value = FixedDecimal(value, 4)
				end
				
				v.drawString(x + FixedMul(self.width, FU / 2), y - FU * 3, value, V_TRANSLUCENT, "thin-fixed-center")
			end
		end
		
		if self.parent and self.parent.selection == self.index then
			local flags = cv_menucolor.value
			local col = v.getStringColormap(flags)
			self.font = $ or "STCFN" --hack
			MenuItem_Text.drawArrows(self, x + self.parent.width + FU * 2, y, col)
		end
	end
end
