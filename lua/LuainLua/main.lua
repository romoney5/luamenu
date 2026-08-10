local env = {}
env._G = _G

function env.__index(self, k)
	if self.self[k] ~= nil then return self.self[k]
	elseif _G[k] ~= nil then return _G[k] end
end

env.__newindex = _G

function env.__usedindex(self, k, v)
	if self.self[k] ~= nil then rawset(self.self, k, v)
	else rawset(_G, k, v) end
end

registerMetatable(env)
setmetatable(env, env) -- put the env in synced tables please

--romoney5: individual rawsets instead of "require"/"waitforchild", no "script"
-- getfenv().script = nil

local function LIL_loadstring(source, env)
	local executable
	local env = env or getfenv(2)
	local name = (env.script and env.script:GetFullName())
	local ran, failureReason = pcall(function()
		local compiledBytecode = LIL_compile(source, name)
		executable = LIL_createExecutable(compiledBytecode, env)
	end)
	
	if ran then
		return setfenv(executable, env)
	end
	return nil, failureReason
end

--player as input, lua source
function LIL_Run(player, src)
	rawset(env, "self", player) --running `print(self)` will print your player
	
    local chunk, msg = LIL_loadstring(src, env)
    
    if chunk
        local success, msg = pcall(chunk)
		
		if success then
			return true, msg
		else
			local out = "\x87".."LuainLua runtime error: ".."\x80"..msg
			print(out)
			return false, msg
		end
    else
		local out = "\x87".."LuainLua error: ".."\x80"..msg
		print(out)
		return false, msg
    end
end