--load all of orbit's files
local directory = { "/",
	"Class.lua",
	"Menu.lua",
	
	{ "Items",
		"Menu.lua",
		"MenuItem.lua",
		"MenuItem_Text.lua",
		"MenuItem_Button.lua",
		"MenuItem_Slider.lua",
		"MenuItem_Textbox.lua",
		"MenuItem_Header.lua",
		
		--modern items
		"MenuItem_Box.lua",
		"MenuItem_UI_Button.lua",
		"MenuItem_Popup.lua",
	},
	
	"MenuData.lua",
	"MenuData_Server.lua",
	"MenuData_LevelSelect.lua",
	
-- 	"TranslationTest.lua",
}

--create the luamenu table first, all scripts will operate here
rawset(_G, "luamenu", {})

luamenu._G = _G
luamenu.__index = _G
setmetatable(luamenu, luamenu)

local function load(dir, path)
	for i, v in ipairs(dir) do
		if i == 1 then continue end
		
		if type(v) == "string" then
			local chunk = loadfile(path..v)
			
			setfenv(chunk, luamenu)
			--from now globals will be set in luamenu by default
			chunk()
		elseif type(v) == "table" then
			load(v, path..v[1].."/")
		end
	end
end

load(directory, "")

print("Luamenu by romoney5")