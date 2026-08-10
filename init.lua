--load all of orbit's files
local directory = { "/",
	"Class.lua",
	"Menu.lua",
	
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

load(directory, "")

print("Luamenu by romoney5")