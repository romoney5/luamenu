--generic class inspired by angry birds

rawset(_G, "MenuClass", {})
setmetatable(MenuClass, MenuClass)
registerMetatable(MenuClass) --Listen!

--did you know: you can use setmetatable freely
--as long as you register the metatable at script load?
--then you can use that metatable address as much as you want in multiplayer
--(i hope)

-- MenuClass.__index = function(self, k) return rawget(self, k) or self.super[k] end --I was

function MenuClass:new(a)
    local a = a or {}
    
    return a
end

function MenuClass:inherit()
    local a = {}
    a.__index = function(self, k) return rawget(a, k) or a.super[k] end
    a.super = self
    
    setmetatable(a, a)
    registerMetatable(a) --Listen!
    
    return a
end

function MenuClass:destroy()
    --the reference must be cleared manually
    return
end