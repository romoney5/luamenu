--preferences specific to luamenu, e.g. corner size

--a cvar is a regular srb2 console variable
--a pref is a luamenu preference; separated so that they can save and have more functionality
--an option is an abstraction of those two to reduce confusion
--(or add confusion? i don't think things out that much)

local default_float_step = FU * 625 / 10000

Prefs = {}

--list of added preferences
Prefs._List = {}

Prefs.Defaults = {
	OnOff = {[0] = "Off", [1] = "On"},
}

Prefs.Preference = MenuClass:inherit()

function Prefs.Preference:new(a)
	local a = self.super:new(a)
	setmetatable(a, self)
	
	a.id = $ or nil
	assert(a.id, "Prefs.Preference:new: Preference has no ID!")
	
	a.label = $ or a.id
	
	--e.g. {[0] = "Off", [1] = "On"}
	--values are assumed to be in order
	a.possible_value = $ or {}
	a.value = $
	
	a.is_float = $ or false
	
	--i'm done making unnecessary functions
	a.default_value = a.value
	a.defaultvalue = a.default_value
	
	table.insert(Prefs._List, a)
	
	return a
end

--get the pref's value as a string
function Prefs.Preference:getString()
	--[[
	for i, v in pairs(self.possible_value) do --i really don't want to use pairs..
		if i == self.value then
			return v
		end
	end
	]]
	--i might be smart
	local found = self.possible_value[self.value]
	
	if found then
		return found
	end
	
	
	local out = self.value
	
	--convert the number to a decimal
	if self.is_float then
		out = FixedDecimal(out, 4)
	end
	
	return out
end

--find a string in possible_value
function Prefs.Preference:findPossibleValue(value)
	for i, v in pairs(self.possible_value) do
		if value == v then
			return i
		end
	end
end

--find the highest/lowest index of a possible value set,
--used for wrapping
function Prefs.Preference:findValueBound(highest)
	local out
	for i, v in pairs(self.possible_value) do
		if out == nil or (highest and i > out) or (not highest and i < out) then
			out = i
		end
	end
	
	return out
end

--add to the pref's value
function Prefs.Preference:addValue(increment)
	local current = self.value
	local mini = self:findPossibleValue("MIN")
	local maxi = self:findPossibleValue("MAX")
	
	--convert it to .0625 scale by default
	if self.is_float and abs(increment) <= 128 then
		increment = $ * default_float_step
	end
	
	--works on min and max?
	if mini ~= nil and maxi ~= nil then
		self.value = current + increment
		
		if self.value > maxi or self.value < mini then
			self.value = self:findValueBound(increment < 0)
		end
	else --we're going by settings then
		local closest = current
		
		--look for the closest possible value starting from current + increment
		for i, v in pairs(self.possible_value) do
			if (increment > 0 and i > closest and i <= current + increment) or
				(increment < 0 and i < closest and i >= current + increment) then
				
				closest = i
			end
		end
		
		if closest == current then
			closest = self:findValueBound(increment < 0)
		end
		
		--STILL didn't find anything? oh well
		assert(closest ~= nil, "Prefs.Preference:addValue: could not find a suitable value!")
		
		self.value = closest
	end
end

--get the type of an option (cvar or pref)
function Prefs:getOptionType(option)
	if type(option) == "table" then
		--automatically assume it's a pref
		return "pref"
	elseif type(option) == "userdata" and userdataType(option) == "consvar_t" then
		return "cvar"
	end
end

--wrapper for both pref:getString() and cvar.string
--accepts both a cvar or a pref (grouped under the term "option")
function Prefs:getString(option)
	local type = self:getOptionType(option)
	
	if type == "pref" then
		return option:getString()
	elseif type == "cvar" then
		return option.string
	end
end

--wrapper for both pref.value and cvar.value
--accepts an option (you know the deal by now)
function Prefs:getValue(option)
	local type = self:getOptionType(option)
	
	if type == "pref" then
		return option.value
	elseif type == "cvar" then
		return option.value --eh i kinda just made this function to feel cooler
	end
end

--returns both MIN and MAX for an option
function Prefs:getPossibleValueBounds(option)
	local type = self:getOptionType(option)
	
	--just find the possible value strings
	if type == "pref" then
		local mini = option:findPossibleValue("MIN")
		local maxi = option:findPossibleValue("MAX")
		
		return mini, maxi
	elseif type == "cvar" then --loop through them.. (i STILL gotta make this a table in c)
		local mini, maxi = 0, 0
		local i = 0
		
		while true do
			local value, strvalue = Banpyura.CV_GetPossibleValue(option, i)
			
			if strvalue == nil then
				break
			end
			
			if strvalue == "MIN" then
				mini = value
			elseif strvalue == "MAX" then
				maxi = value
			end
			
			i = $ + 1
		end
		
		return mini, maxi
	end
end

--wrapper for both pref:addValue() and Banpyura.CV_ForceAddValue
--accepts an option
function Prefs:addValue(option, value)
	local type = self:getOptionType(option)
	
	if type == "pref" then
		option:addValue(value)
	elseif type == "cvar" then
		--floats are special in various ways
		if option.flags & CV_FLOAT then
			local new_value = option.value + value * default_float_step
			
			new_value = FixedDecimal(new_value, 4)
			
			Banpyura.CV_ForceSet(option, new_value)
		else
			Banpyura.CV_ForceAddValue(option, value)
		end
	end
end

--find a preference by id
--case-sensitive
function Prefs:findPref(id)
	assert(id, "Prefs:findPref: ID is nil!")
	
	for i, pref in ipairs(self._List) do
		if pref.id == id then
			return pref
		end
	end
end
