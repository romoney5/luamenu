// level platter remake by xdf
// compatible with 2.1 and 2.2 because
// ( look at the input code)

setfenv(1, luamenu)

local scroll = 0
local row = 1
local xSel = 1

--romoney5: never is luamenu gonna run in 2.1
local yellowColor = 73
local boxPatch1 = "SLCT1LVL"
local boxPatch2 = "SLCT2LVL"

local function MENUCAPS()
	return (not cv_menucaps.value) and V_ALLOWLOWERCASE or 0
end

// borrowed from lach

local function GetSelectedID(self)
	local rowIndex = 0

	for groupIndex = 1, #self.order do
		local mapList = self.groups[self.order[groupIndex]]
		local groupRowCount = ((#mapList - 1) / 3) + 1

		for localRow = 0, groupRowCount - 1 do
			rowIndex = rowIndex + 1

			if rowIndex == row then
				local mapIndex = localRow * 3 + xSel
				return mapList[mapIndex]
			end
		end
	end
end

local function draw(self, v)
	// reset rows
	local totalRows = 0

	for i = 1, #self.order do
		local list = groups[self.order[i]]
		totalRows = totalRows + ((#list + 2) / 3)
	end
	
	// wrapping
	if row < 1 then row = totalRows end
	if row > totalRows then row = 1 end

	scroll = ease.linear(v.renderdeltatics() / 3, $, FU * (row - 1) * 80)

	// drawing part
	local yCursor = 0

	for i = 1, #self.order do
		local key = self.order[i]
		local list = self.groups[key]

		// zone header
		local headerY = FU * 75 + FU * yCursor * 80 - scroll
		local selected = (yCursor+1 == row)
		v.drawString(FU * 20, headerY - FU * 14, key.." Zone", (selected and cv_menucolor.value or 0)|MENUCAPS(), "fixed")
		v.drawFixedFill(FU * 20, headerY - FU * 5, FU * 281, FU * 2, 28)
		v.drawFixedFill(FU * 20, headerY - FU * 5, FU * 280, FU * 1, selected and yellowColor or 0)

		// se
		local rows = (#list + 2) / 3

		for rowIndex = 0, rows - 1 do
			for columnIndex = 0, 2 do
				local idx = rowIndex * 3 + columnIndex + 1
				local id = list[idx]

				if id then
					local x = FU * 20 + FU * columnIndex * 100
					local y = FU * 75 + FU * yCursor * 80 - scroll
					
					local mapGraphic
					if v.patchExists(G_BuildMapName(id).."P") then
						mapGraphic = G_BuildMapName(id).."P"
					else
						mapGraphic = "BLANKLVL"
					end

					v.drawScaled(x, y, FRACUNIT/2, v.cachePatch(mapGraphic))

					local info = mapheaderinfo[id]
					v.drawFixedFill(x, y + FU * 50, FU * 80, FU * 8, cv_menubgcolor.value)
					
					local act_flags = ((yCursor + 1 == row and columnIndex + 1 == xSel) and cv_menucolor.value or 0)|MENUCAPS()
					
					if info.actnum then
						v.drawString(x, y + FU * 50, "Act "..info.actnum, act_flags, "fixed")
					else
						v.drawString(x, y + FU * 50, "The Act", act_flags, "fixed" or "thin-fixed")
					end
				end
			end

			yCursor = $ + 1
		end
	end
	
	local patch = (leveltime % 3) and boxPatch1 or boxPatch2
	v.drawScaled(FU * 20 + FU * 100 * (xSel - 1), FU * 75 + FU * 80 * (row - 1) - scroll, FU / 2, v.cachePatch(patch))
end

menus.LevelSelect = Menu:new{
	anchor = {x = "center", y = "bottom"},
	
	on_entry = function(self, old_menu)
		--reset to 1 Player on pause and set the cursor instantly
-- 		if old_menu then return end
-- 		self.selection = 1
-- 		self:updateItems()
		// rebuild level list
		self.groups = {}
		self.order = {}
		
		for i = 0, #mapheaderinfo - 1 do
			local info = mapheaderinfo[i]
			
			if not info then continue end
			
			local mapname = info.lvlttl

			if not self.groups[mapname] then
				self.groups[mapname] = {}
				self.order[#order + 1] = mapname
			end

			self.groups[mapname][#self.groups[mapname] + 1] = i
		end
	end,
	
	items = {
	},
	
	on_draw = function(self, v)
		draw(self, v)
	end,
	
	on_input = function(self, key, name)
		if name == "right arrow" then xSel = $ + 1 S_StartSound(nil, sfx_s3kb7, player) end
		if name == "left arrow" then xSel = $ - 1 S_StartSound(nil, sfx_s3kb7, player) end
		
		if name == "up arrow" then row = $ - 1 S_StartSound(nil, sfx_s3kb7, player) end
		if name == "down arrow" then row = $ + 1 S_StartSound(nil, sfx_s3kb7, player) end
		
		if xSel > 3 then xSel = 1 elseif xSel < 1 then xSel = 3 end
		
-- 		if scrollby then
-- 			self.save_select = $ + scrollby
-- 			self.save_scroll = $ + scrollby * FU * 100
-- 		end
		
-- 		--M_LoadSelect
-- 		if name == "enter" then
-- 			Menu_GotoLink("SingleplayerMenu_StartGame_CharSelect")
-- 		end
		
-- 		if (p.cmd.buttons & BT_JUMP) then
-- 			local id = GetSelectedID(self)
-- 			if id then
-- 				S_StartSound(nil, sfx_menu1, player)
-- 				G_ExitLevel(id, 1)
-- 				levelselectActive = false
-- 			else
-- 				scroll = $+8
-- 				S_StartSound(nil, sfx_s3kb2, player)
-- 			end
-- 		end
		
		return true
	end,
}
