--load all of orbit's files
local directory = { "/",
	"Class.lua",
	"Menu.lua",
	
	"MenuData.lua",
	"MenuData_Server.lua",
	"MenuData_LevelSelect.lua",
	
-- 	"TranslationTest.lua",
}

local function load(dir, path)
	for i, v in ipairs(dir) do
		if i == 1 then continue end
		
		if type(v) == "string" then
			dofile(path..v)
		elseif type(v) == "table" then
			load(v, path..v[1].."/")
		end
	end
end

--create the luamenu table first, all scripts will operate here
rawset(_G, "luamenu", {})

luamenu._G = _G
luamenu.__index = _G
setmetatable(luamenu, luamenu)

load(directory, "")

print("Luamenu by romoney5")