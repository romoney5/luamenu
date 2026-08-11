--menu text drawer
local function ZeroNumber(str, amount)
	str = tostring($)
	
	if str:len() >= amount
		return str
	end
	
	return string.rep("0", amount - str:len())..str
end

MenuItem_Text = MenuItem:inherit()

function MenuItem_Text:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.label = $ or "Button"
	a.font = $ or "STCFN"
	a.scale = $ or FU
	
	a.parent_width = $ or 0
	
	a.colored = $ or false
	a.color = $ or nil
	a.force_lowercase = $ or false
	
	a.height = $ or FU * 8
	
	a.on_draw = $ or nil
	
	return a
end

function MenuItem_Text:getFlags(selected)
	local menucaps = 0--(not cv_menucaps.value) and V_ALLOWLOWERCASE or 0
	local color = self.color or 0
	
	--use a custom highlight color if available, otherwise use yellow
	if (self.parent and self.parent.selection == self.index) or selected then
		color = cv_menucolor.value
	end
	
	return menucaps|color
end

function MenuItem_Text:getBounds()
	local width = self._width or 0--FU * v.stringWidth(self.label, self:getFlags(), "normal")
	local height = self.height --inaccurate in some cases
	
	return width, height
end

function MenuItem_Text:recalcLayout(label)
	local uppercase = cv_menucaps.value and not self.force_lowercase
	local layout = {}
	self.text_layout = layout
	
	local line = {}
	
	if uppercase then
		label = $:upper()
	end
	
	local width = 0
	local parent_width = FixedDiv(self.parent_width, self.scale or 1)
	
	for i = 1, label:len() + 1 do
		local char = label:sub(i, i)
		
		local code = char:byte()
		
		if char == "\n" or i == label:len() + 1 then
			line.width = width
			table.insert(layout, line)
			width = 0
			line = {}
			
			continue
		elseif code & 0x80 then
			--color code special character
			
			table.insert(line, char)
			table.insert(line, 0)
			
			continue
		elseif parent_width and width > parent_width then --word wrapping
			line.width = width
			width = 0
			
			local newline = {}
			local total_width = line[#line]
			
			--go through the letters from end and add stuff until we find a space
			for i = #line - 1, 1, -2 do
				if line[i] == " " then
					break
				end
				
				table.insert(newline, 1, line[i])
				table.insert(newline, 2, line[i + 1])
				
				width = $ + line.width - line[i + 1]
				line.width = line[i + 1]
				
				table.remove(line, i + 1)
				table.remove(line, i)
			end
			
			--push everything back
			local offset = newline[2]
			
			for i = 2, #newline, 2 do
				newline[i] = $ - offset
			end
			
			table.insert(layout, line)
			line = newline--{}
		end
		
		table.insert(line, char)
		table.insert(line, width)
		
		local patchname = self.font..ZeroNumber(code, 3)
		local patch = cachePatch(patchname)
		
		if patch then
			width = $ + FU * patch.width
		else
			width = $ + FU * 4
		end
	end
end

function MenuItem_Text:draw(x, y)
	local width, height = self:getBounds()
	
	local dupy = v.dupy() * FU
	if y < -((v.height() * FU - dupy * 200) / 2) - height then --TODO: support wrapping here
		return
	end
	
	if y > FU * 200 + (v.height() * FU - dupy * 200) / 2 then
		return
	end
	
	local uppercase = cv_menucaps.value and not self.force_lowercase
	local label = self.label
	local scale = self.scale
	
	if pref_luamenu_debugoptionnames.value and (self.cvar or self.pref) then
		label = (self.cvar and self.cvar.name) or (self.pref and self.pref.id)
	end
	
	if self._old_label ~= label or self._old_uppercase ~= uppercase
	or self._old_parent_width ~= self.parent_width--[[ or self._old_scale ~= self.scale]] then
		self._old_label = label
		self._old_uppercase = uppercase
		self._old_parent_width = self.parent_width
		self._old_scale = scale
		self:recalcLayout(label)
	end

	local width = 0
	local max_width = 0 --used to get text bounds
	local flags = self:getFlags(self.colored)
	local col = v.getStringColormap(flags)
	
	local lines = 0
	
	--run once: once to draw,
	for i, line in ipairs(self.text_layout) do
		local _, factor = self:getAlignment()
		local align_x = FixedMul(FixedMul(line.width, factor), self.scale)
		
		for ii = 1, #line, 2 do
			local char = line[ii]
			local code = char:byte()
			
			if code & 0x80 then
				--color code
				
				if not (flags & V_CHARCOLORMASK) then
					local flags2 = ((code & 0x7f) << V_CHARCOLORSHIFT) & V_CHARCOLORMASK
					
					col = v.getStringColormap(flags2)
				end
				
				continue
			end
			
			local char_x = x + FixedMul(line[ii + 1], scale) + align_x
			local char_y = y + (i - 1) * scale * 10
			
			local patch = cachePatch(self.font..ZeroNumber(char:byte(), 3))
			
			if patch then
				v.drawScaled(char_x, char_y, scale, patch, 0, col)
			end
		end
		
		max_width = max($, line.width)
	end
	
	self._width = max_width --this should be in recalcLayout
	
	if self.on_draw then
		self:on_draw(x, y)
	end
end

function MenuItem_Text:drawArrows(x, y, col)
	local width, height = self:getBounds()
	local patch_left = cachePatch(self.font.."028")
	local patch_right = cachePatch(self.font.."029")
	
	--animation
	local out = FU * 2
	self.arrow_blink = (($ or 0) + v.renderdeltatics() / TICRATE * 4) % FU
	
	if self.arrow_blink >= FU / 2 then
		out = $ + FU
	end
	
	--right arrow
	v.drawScaled(x - width - FU * patch_left.width - out, y, FU, patch_left, 0, col)
	v.drawScaled(x + out, y, FU, patch_right, 0, col)
end