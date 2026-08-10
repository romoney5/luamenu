--Me?
--main menu logic

--remember, the environment of all luamenu scripts is _G.luamenu

if not _G.gks_luamenu_supported then return end
_G.gks_luamenu = true

cv_luamenu = CV_RegisterVar{name = "luamenu", defaultvalue = "On", PossibleValue = CV_OnOff, flags = CV_SAVE|CV_CALL, func = function(self)
	_G.gks_luamenu = self.value and true or false
	
	--make sure everything is set back to normal
	if not self.value then
		Menu_SetActive(false)
	end
end}

menus = {}

--placeholder banpyura cvars
cv_menucaps = CV_FindVar("menucaps") or {value = 1}
cv_menucolor = CV_FindVar("menucolor") or {value = V_YELLOWMAP}
cv_menubgcolor = CV_FindVar("menubgcolor") or {value = 159}

cv_luamenu_bgdecos = CV_RegisterVar{name = "luamenu_bgdecos", defaultvalue = "On", PossibleValue = CV_OnOff, flags = CV_SAVE}
cv_luamenu_anims = CV_RegisterVar{name = "luamenu_anims", defaultvalue = "On", PossibleValue = CV_OnOff, flags = CV_SAVE}
cv_luamenu_tooltips = CV_RegisterVar{name = "luamenu_tooltips", defaultvalue = "On", PossibleValue = CV_OnOff, flags = CV_SAVE}
cv_luamenu_showversion = CV_RegisterVar{name = "luamenu_showversion", defaultvalue = "On", PossibleValue = CV_OnOff, flags = CV_SAVE}
cv_luamenu_rounded = CV_RegisterVar{name = "luamenu_rounded", defaultvalue = "1", PossibleValue = {MIN = 0, MAX = FU * 4}, flags = CV_SAVE|CV_FLOAT}
cv_luamenu_sliders = CV_RegisterVar{name = "luamenu_sliders", defaultvalue = "On", PossibleValue = CV_OnOff, flags = CV_SAVE}

v = {}

current_menu = "MainMenu"
current_popup = nil

next_action = nil

local menu_time = 0

--i hate to expose these but..
keyHold = {}
keyHold_lock = {}

local cache = {}

--clear the cache once an addon is loaded
addHook("AddonLoaded", function()
	cache = {}
end)

function cachePatch(patchname)
	local cacheexists = cache[patchname]
	
	if cacheexists == nil or (cacheexists and not cacheexists.valid) then
		if v.patchExists(patchname) then
			cache[patchname] = v.cachePatch(patchname)
		else
			cache[patchname] = false
		end
	end
	
	return cache[patchname]
end

--xorshift prng i found off of temu
local randomState = 0xBADE4404
local function __internal_prng__()
	randomState = $ ^^ ($ >> 13)
	randomState = $ ^^ ($ >> 11)
	randomState = $ ^^ ($ << 21)

	return ((randomState * 36548569) >> 4) & (FU - 1) --what the pigma
end

--range hasn't been perfectly tested
function M_RandomRange(a, b)
	return ((__internal_prng__() * (b - a + 1)) >> FRACBITS) + a
end

--screen coordinates to 320x200 coordinates
function ScreenToDisplay(x, y)
	x = FU * $
	y = FU * $

	local dupx = v.dupx()
	local dupy = v.dupy()
	local width = FU * v.width()
	local height = FU * v.height()
	local base_width = FU * 320
	local base_height = FU * 200
	local scaled_width = base_width * dupx
	local scaled_height = base_height * dupy
	
	local left = width / 2 - scaled_width / 2
-- 	local bottom = height / 2 + scaled_height / 2
-- 	local right = width / 2 + scaled_width / 2
	local top = height / 2 - scaled_height / 2
	
	return FixedMul(x - left, FixedDiv(base_width + left / 2, width)), FixedMul(y - top, FixedDiv(base_height + top / 2, height))
end

function Menu_SetActive(active)
	if active then
		input.setMouseGrab(false)
		_G.menuactive = true
		
		if menus[current_menu] and menus[current_menu].on_entry then
			menus[current_menu]:on_entry(old_menu)
		end
		
		if JNI_SetTouchVisible then
			JNI_SetTouchVisible(false)
		end
	else
		input.setMouseGrab(true)
		_G.menuactive = false
		current_menu = nil
		current_popup = nil
		
		if JNI_SetTouchVisible then
			JNI_SetTouchVisible(true)
		end
	end
	
	--clear anims when toggling the menu
	local menu = menus[current_menu]
	
	if menu then
		menu.enter_anim = FU
		menu.exit_anim = FU
	end
end

function Menu_GotoLink(link)
	if not menus[link] then
		ShowPopup("Menu_GotoLink", ("Could not find menu link \"%s\".\n\nThis menu may be unimplemented."):format(tostring(link)))
		return
	end

	local old_menu = current_menu
	local menu = menus[current_menu]

	if menu.on_exit then
		menu:on_exit(link)
	end

	current_menu = link
	menu = menus[current_menu]
	
	menu.parent = old_menu

	if menu.on_entry then
		menu:on_entry(old_menu)
	end
	
	if cv_luamenu_anims.value then
		menu.enter_anim = 0
		menu.exit_anim = FU
	end
end


local function DrawSpikes(rot, patch, ox, oy, scroll, flags)
	local col = v.getColormap(nil, nil, "Menu_Translation_"..cv_menubgcolor.value - 2)
	local bg2 = cachePatch("MENU_SPIKE")
	local bg = cachePatch(patch)
	local dimension = bg2.height - 1
	
	for i = -2, FU * 400 / dimension / FU do
		local factor = FixedMul(FU * dimension, FU * i + scroll)
		local x = FixedMul(factor, cos(rot)) + ox
		local y = FixedMul(factor, sin(rot)) + oy
		v.drawScaled(x, y, FU, bg, flags, col)
	end
end

local mx, my = 0, 0

local function GetState()
	local state = "game"
	
	if titlemapinaction then state = "title" end
	if chatactive then state = "chat" end
	
	return state
end

local function Input(key)
	if not gks_luamenu then return end
	
	local name = key.name:lower()
	local state = GetState()
	
	keyHold[name] = true
	
	if menuactive and current_popup then
		--dismiss the popup
		input.setTextInputMode(false)
		
		if current_popup.on_input and current_popup:on_input(key, name) then
			return true
		end
		
		return
	end
	
	if name == "escape" then
		if state == "game" and not menuactive then
			current_menu = "SP_MainMenu"
			Menu_SetActive(true)
			
			return
		else
			if not menuactive then return end
		end
-- 		print(name)
		
		local menu = menus[current_menu]
		assert(menu, ("Input: Invalid menu \"%s\"!"):format(tostring(current_menu))) --r
		
		if menu.parent then
			assert(menus[menu.parent], ("Input: Could not resolve menu back link \"%s\"."):format(tostring(menu.parent))) --r

			if menu.on_exit then
				menu:on_exit(menu.parent)
			end
			
			local old_menu = current_menu
			current_menu, menu.parent = menu.parent, nil
			
			if menus[current_menu] and menus[current_menu].on_entry then
				menus[current_menu]:on_entry(old_menu)
			end
			
			if cv_luamenu_anims.value then
				menus[current_menu].enter_anim = FU
				menus[current_menu].exit_anim = 0
			end
		else
			Menu_SetActive(false)
		end
		
		return
	elseif name == "enter" and not menuactive then
		if state == "title" then
			current_menu = "MainMenu"
			
			Menu_SetActive(true)
		end
		
		return
	end
	
	if not menuactive then return end
	
	local menu = menus[current_menu]
	assert(menu, ("Input: Invalid menu \"%s\"!"):format(tostring(current_menu))) --r
	
	if menu.on_input and menu:on_input(key, name) then
		return
	end
	
	if menu.items[menu.selection] and menu.items[menu.selection].onKeyInput
	and menu.items[menu.selection]:onKeyInput(key, name) then
		return
	end
	
	local scrollby = 0
	if name == "down arrow" then
		scrollby = 1
	elseif name == "up arrow" then
		scrollby = -1
	end
	
	if scrollby then
		S_StartSound(nil, sfx_menu1) --local sound
		
		menu:scrollBy(scrollby)
	end
	
	if name == "enter" or name == "left arrow" or name == "right arrow" then
		keyHold_lock[name] = true
		
		for i, item in ipairs(menu.items) do
			if i == menu.selection then
				item:activate(name == "left arrow" and -1 or 1)
				S_StartSound(nil, sfx_menu1) --local sound
				
				break
			end
		end
	end
	
	input.setTextInputMode(false)
	
	if menu.items[menu.selection] and menu.items[menu.selection].onTextInput
	and menu.items[menu.selection]:onTextInput() then
		input.setTextInputMode(true)
	end
	
	local console1, console2 = input.gameControlToKeyNum(GC_CONSOLE)
	
	if key.num == console1 or key.num == console2 then
-- 	or key.num == input.gameControl2ToKeyNum(GC_CONSOLE) then
		return
	end
	
	return true
end

--first time i've ever used this hook
addHook("KeyDown", Input)

addHook("KeyUp", function(key)
	local name = key.name:lower()
	
	keyHold[name] = nil
	keyHold_lock[name] = nil
end)

addHook("TextInput", function(text)
	if not menuactive then return end
	
	local menu = menus[current_menu]
	assert(menu, ("Input: Invalid menu \"%s\"!"):format(tostring(current_menu))) --r
	
	if menu.items[menu.selection] and menu.items[menu.selection].onTextInput
	and menu.items[menu.selection]:onTextInput(text) then
		return
	end
end)

local function Drawer(drawer, player)
	if not gks_luamenu then return end
	
	if not menuactive then return end
	
	--localize drawing functions into a table
	if #v == 0 then
		for i, fun in pairs(drawer) do
			v[i] = fun
		end
		
		v.drawFixedFill = $ or function(x, y, width, height, color)
			--v.drawFill(x / FU, y / FU, width / FU, height / FU, color)
			
			local patch = cachePatch("MENU_PIXEL")
			local colormap = v.getColormap(nil, nil, "Menu_Translation_"..(color & 255))
			
			v.drawStretched(x, y, width, height, patch, color & ~255, colormap)
		end
	end
	
	v.fadeScreen(0xFF00, 16)
	
	current_menu = $ or "MainMenu"
	
	local menu = menus[current_menu]
	assert(menu, ("Drawer: Invalid menu \"%s\"!"):format(tostring(current_menu)))
	
	menu_time = $ + v.renderdeltatics()
	
	menu:updateScroll()
	
	if cv_luamenu_bgdecos.value then
		local speed = FU / TICRATE / 2
		DrawSpikes(ANG1 * 10, "MENU_SPIKE_2", 0, FU * 155, (FixedMul(menu_time, speed) + menu.scroll / 64) % FU, V_SNAPTOBOTTOM|V_SNAPTOLEFT)
		DrawSpikes(ANG1 * 10 + ANGLE_180, "MENU_SPIKE_3", FU * 270, FU * 40, (FixedMul(menu_time, speed) + menu.scroll / 64) % FU, V_SNAPTOTOP|V_SNAPTORIGHT)
	end
	
	menu:draw()
	
	--draw popup
	if current_popup then
		current_popup:draw(FU * 320 / 2, FU * 100 / 2)
	end
	
-- 	v.drawScaled(mx, my, FU, cachePatch("M_CURSOR"))
end

addHook("MenuThinker", function()
	if not menuactive then return end
	
	if next_action then
		local action = next_action
		
		next_action = nil
		local active = action()
		
		if active ~= nil then
			Menu_SetActive(active)
		end
	end
end)

hud.add(Drawer, "menu")