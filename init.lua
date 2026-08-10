--load all of orbit's files
local directory = { "/",
	"Class.lua",
	"me.lua",
	
// 	--libraries
// 	{ "libraries",
// 		"fixed_decimal.lua",
// 		"custom_hud.lua", --i never actually got to use it!! !
// 	},						--(i think i had it kept in a git stash that is lost media now)
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