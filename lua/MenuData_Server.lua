--reimplementation of part of the client connection code because.. why not?!
--this does rely on some custom native functions though, so if you don't have
--the right build, this is as good as useless

--network stuff is always gonna involve some loading,
--the user deserves a pretty loading spinner
local spinner_time = 0
local spinner_spin = 0

local function DrawSpinner(x, y)
	local bg = v.cachePatch("MENU_LOAD1")
	v.drawScaled(x, y, FU / 2, bg, V_50TRANS)
	
	local speed = sin(FixedAngle(spinner_time * 5)) * 2 / 3 + FU * 3 / 2
	spinner_time = $ + v.deltaTics()
	spinner_spin = $ - FixedAngle(FixedMul(v.deltaTics(), speed) * 8)
	local angle = spinner_spin
	local spinner = v.cachePatch("MENU_ROUND")
	
	local speed2 = cos(FixedAngle(spinner_time * 5)) * 2 / 3 + FU
	local amount = speed2 / (FU / 25)
	
	for i = -amount * 3 / 2, amount / 2 do
		local newangle = -(angle + i * ANG1 * 2)
		local dist = FU * 16 + FU / 2
		v.drawScaled(x + FixedMul(cos(newangle), dist), y + FixedMul(sin(newangle), dist), FU / 32, spinner, 0, v.getColormap(nil, nil, "Menu_Translation_"..(cv_menubgcolor.value - 6)))
	end
end

--server bowser
--w flaffy

local masterserver = CV_FindVar("masterserver")

--i'm not giving you documentation for this, sorry
--except for Command_connect
local cl_mode
local CL_SEARCHING = 0 --TODO: add documentation
local CL_CHECKFILES = 1
local CL_DOWNLOADFILES = 2
local CL_ASKJOIN = 3
local CL_LOADFILES = 4
local CL_WAITJOINRESPONSE = 5
local CL_DOWNLOADSAVEGAME = 6
local CL_CONNECTED = 7
local CL_ABORTED = 8
local CL_ASKFULLFILELIST = 9
local CL_CONFIRMCONNECT = 10
local CL_DOWNLOADHTTPFILES = 11

local CL_VIEWSERVER = 12

local MAXNETNODES = 127

local REFUSE_JOINS_DISABLED = 1
local REFUSE_SLOTS_FULL = 2
local REFUSE_BANNED = 3

local SRB2APPLICATION = "SRB2" --TODO: epose
local PACKETVERSION = 5 --TODO: epose

local SV_DEDICATED = 0x40 --dedotated server
local SV_LOTSOFADDONS = 0x20

local FORCECLOSE = 0x8000

local FILENEEDED_WAD = 0
local FILENEEDED_SAVEGAME = 1
local FILENEEDED_LUAFILE = 2

local FS_NOTCHECKED = 0
local FS_NOTFOUND = 1
local FS_FOUND = 2
local FS_REQUESTED = 3
local FS_DOWNLOADING = 4
local FS_OPEN = 5 --Is opened and used in w_wad
local FS_MD5SUMBAD = 6
local FS_FALLBACK = 7

local FDOWNLOAD_FAIL_NONE = 0
local FDOWNLOAD_FAIL_NOTFOUND = 1
local FDOWNLOAD_FAIL_MD5SUMBAD = 2
local FDOWNLOAD_FAIL_OTHER = 3

local asktime = 0
local joinnode = 0

--fileneeded
local fileneeded
local fileneedednum = 0

local cl_lastcheckedfilecount = 0

--a lot of these functions are recreateable in lua already with what we have
local function SL_SearchServer(node)
	for i = 0, #serverlist do
-- 		print(serverlist[i].node)
		if serverlist[i].node == node then
-- 			print("found "..node)
			return i
		end
	end
end

--some things are inaccessible to lua
-- local function SL_ClearServerList(node)
-- 	for i = 0, #serverlist - 1 do
-- 		if serverlist[i].node ~= node then
-- 			Net_CloseConnection(serverlist[i].node|FORCECLOSE)
-- 			serverlist[i].node = 0
-- 		end
-- 	end
-- end

local function InvalidServerReason(info)
	if info._255 ~= 255 then --math is not math
		return "Outdated server (_255 is not 255)"
	end
	
	if info.application ~= SRB2APPLICATION then
		return ("SRB2APPLICATION does not match; expected %s, got %s"):format(SRB2APPLICATION, info.application)
	end
	
	if info.packetversion ~= PACKETVERSION then return ("PACKETVERSION does not match; expected %s, got %s"):format(PACKETVERSION, info.packetversion) end
	if info.version ~= VERSION then return ("VERSION does not match; expected %s, got %s"):format(VERSION, info.version) end
	if info.subversion ~= SUBVERSION then return ("SUBVERSION does not match; expected %s, got %s"):format(PACKETVERSION, info.subversion) end
	
	if info.refusereason == REFUSE_BANNED then
		return "Banned from the server."
	elseif info.refusereason == REFUSE_JOINS_DISABLED then
		return "Joins are currently turned off."
	elseif info.refusereason == REFUSE_SLOTS_FULL then
		return "Server is currently full."
	elseif info.refusereason then
		return "No."
	end
end

local function D_ParseFileneeded(fileneedednum_parm, fileneededstr, firstfile)
	fileneedednum = firstfile + fileneedednum_parm
	fileneeded = {}
	
	local pos = 1
	
	for i = firstfile + 1, fileneedednum - 1 + 1 do
		fileneeded[i] = {}
		
		fileneeded[i].type = FILENEEDED_WAD
		fileneeded[i].status = FS_NOTCHECKED
		fileneeded[i].justdownloaded = false
		local filestatus = fileneededstr:byte(pos, pos) pos = $ + 1
		fileneeded[i].folder = fileneededstr:byte(pos, pos) pos = $ + 1
		fileneeded[i].willsend = filestatus >> 4
		fileneeded[i].totalsize = fileneededstr:byte(pos, pos + 3) pos = $ + 4
		fileneeded[i].file = nil
		fileneeded[i].failed = FDOWNLOAD_FAIL_NONE
		
		fileneeded[i].filename = ""
		
		local total_length = 0
		while total_length < 512 do
			if fileneededstr:byte(pos, pos) == 0 then
				break
			end
			
			fileneeded[i].filename = $..fileneededstr:sub(pos, pos)
			pos = $ + 1
			total_length = $ + 1
		end
		pos = $ + 1
		print(i.." "..fileneeded[i].filename)
		
		fileneeded[i].md5sum = fileneededstr:sub(pos, pos + 15) pos = $ + 16
		
		--TODO: addontype stuff added in srb2-edit
	end
end

--finds some servers
local function CL_ServerConnectionSearchTicker()
	local serverlistcount = #serverlist
-- 	print(serverlistcount, servernode)
	local i = 0
	
	if serverlistcount > 0 then
-- 		print("count = "..serverlistcount)
-- 		print("netgame = "..tostring(netgame))
		if servernode == -1 or servernode >= MAXNETNODES then
			i = 0
			
			servernode = serverlist[i].node
			print("found a LAN server(?)")
		else
			i = SL_SearchServer(servernode)
			
			if i == nil or i < 0 then
				return true
			end
		end
		
		joinnode = i --this is what viewserver will access from
		
		if --[[client]]true then --WHAT DOES HE EVEN DO?
			local info = serverlist[i].info --aw man i gotta expose this..
			--alright i exposed info
			
			if info.refusereason == REFUSE_SLOTS_FULL then
-- 				serverisfull = true --TODO
			else
				local reason = InvalidServerReason(info)
				
				if reason then
					print("CL_ServerConnectionSearchTicker: invalid server reason")
					print(reason)
					--TODO: abort function
					return false
				end
			end
			
			--[[
			if (serverlist[i].info.httpsource[0])
				strlcpy(filedownload.http_source, serverlist[i].info.httpsource, MAX_MIRROR_LENGTH);
			else
				filedownload.http_source[0] = '\0';

			D_ParseFileneeded(info->fileneedednum, info->fileneeded, 0);

			if (info->flags & SV_LOTSOFADDONS)
			{
				cl_mode = CL_ASKFULLFILELIST;
				cl_lastcheckedfilecount = 0;
				return true;
			}

			cl_mode = cv_showserverinfo.value ? CL_VIEWSERVER : CL_CHECKFILES;
			ChangeServMusic(servmus_1, true,false);
			]]
			
			D_ParseFileneeded(info.fileneedednum, info.fileneeded, 0) --NOT native
			
			if info.flags & SV_LOTSOFADDONS then --server has like 20 addons, get the full list
				cl_mode = CL_ASKFULLFILELIST
				cl_lastcheckedfilecount = 0
				
				return true
			end
			
-- 			print("CL_ServerConnectionSearchTicker: reached CL_VIEWSERVER")
-- 			print(info.servername)
			cl_mode = CL_VIEWSERVER
-- 			print("files needed: "..info.fileneedednum)
		else --server?!?!?!
			cl_mode = CL_ASKJOIN
			--*asksent = 0
		end
	end
	
	asktime = $ - 1
	if asktime <= 0 then
		SendAskInfo(servernode) --native
		asktime = TICRATE
	end
end

local function CL_FinishedFileList()
	cl_mode = CL_SEARCHING
	
	--custom build
	--only look inside DOWNLOAD for now (findfile)
	for i, v in ipairs(fileneeded) do
		print("checking file "..v.filename.."..")
-- 		local file = io.lua_open("DOWNLOAD/CL_ModernSonic-v6.pk3", "rb")
	-- 	local file = io.lua_open("addons/replacexit.lua", "rb")
		local file = io.lua_open("DOWNLOAD/"..v.filename, "rb")
		
		if not file then
			print("file does not exist")
			
			continue
		end
-- 		print(file)
	-- 	print(file:read("*a"):len())
		--c get file from lua io.file
		local md5 = GetFileMD5(file)
		print(md5:len(), v.md5sum:len(), md5 == v.md5sum)
		file:close()
		
-- 		for i = 1, 16 do
-- 			local byte = md5:byte(i, i)
-- 	-- 		byte = ($ + 128) % 128
-- 			print("md5 "..byte)
-- 			print("md5sum "..fileneeded[0].md5sum:byte(i, i))
-- 		end
	end
	
-- 	local fileneeded = serverlist[joinnode].info.fileneeded
-- 	local str = ""
	
-- 	for i = 1, 64 do
-- 		local char = fileneeded[i]
-- 		if char < 32 or char > 126 then char = 63 end
-- 		--print(string.char(fileneeded[i]))
-- 		str = $..string.char(char)
-- 	end
	
-- 	print(str)
end

local viewip = ""

local function CL_ConnectToServer()
	print("Contacting the server...")
	
	cl_mode = CL_SEARCHING
	asktime = 0
	
	SL_ClearServerList(servernode)
end

local function serv_connect(ip, port)
	_G.menuactive = true
	Menu_GotoLink("Sonikm")
	
	if port == nil then
		port = 5029
		
		for i = 1, ip:len() do
			if ip:sub(i, i) == ":" then
				port = ip:sub(i + 1, -1)
				
				ip = $:sub(1, i - 1)
			end
		end
	end
	
	print("Connecting to.. "..ip..", "..port)
	viewip = ip..":"..port
	
	I_NetOpenSocket() --native
-- 	SetMultiplayer() --native
	
	servernode = I_NetMakeNodewPort(ip, port) --native
	
	CL_ConnectToServer()
end
rawset(_G, "serv_connect", serv_connect)

--[[
// This packet is too large
typedef struct
{
	/ *
	In the old packet, 'version' is the first field. Now that field is set
	to 255 always, so older versions won't be confused with the new
	versions or vice-versa.
	* /
	UINT8 _255;
	UINT8 packetversion;
	char  application[MAXAPPLICATION];
	UINT8 version;
	UINT8 subversion;
	UINT8 numberofplayer;
	UINT8 maxplayer;
	UINT8 refusereason; // 0: joinable, REFUSE enum
	char gametypename[24];
	UINT8 modifiedgame;
	UINT8 cheatsenabled;
	UINT8 flags;
	UINT8 fileneedednum;
	tic_t time;
	tic_t leveltime;
	char servername[MAXSERVERNAME];
	char mapname[8];
	char maptitle[33];
	unsigned char mapmd5[16];
	UINT8 actnum;
	UINT8 iszone;
	char httpsource[MAX_MIRROR_LENGTH];
	UINT8 fileneeded[MAXFILENEEDED]; // is filled with writexxx (byteptr.h)
} ATTRPACK serverinfo_pak;

// Shorter player information for external use.
typedef struct
{
	UINT8 num;
	char name[MAXPLAYERNAME+1];
	UINT8 address[4]; // sending another string would run us up against MAXPACKETLENGTH
	UINT8 team;
	UINT8 skin;
	UINT8 data; // Color is first four bits, hasflag, isit and issuper have one bit each, the last is unused.
	UINT32 score;
	UINT16 timeinserver; // In seconds.
} ATTRPACK plrinfo_pak;
]]

menus.Sonikm = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320,
	
	on_draw = function(self, v)
		if cl_mode == CL_SEARCHING--[[self.loading]] then
-- 			v.drawString(160, 55, "Connecting to...", V_ALLOWLOWERCASE, "center")
-- 			v.drawString(160, 65, viewip, V_ALLOWLOWERCASE, "center")
		else
		end
		
		if v.renderisnewtic() then
			if cl_mode == CL_SEARCHING then
				CL_ServerConnectionSearchTicker()
			elseif cl_mode == CL_ASKFULLFILELIST then
				if cl_lastcheckedfilecount == UINT16_MAX then
					cl_mode = CL_VIEWSERVER
					--TODO: addon types
				elseif fileneedednum ~= cl_lastcheckedfilecount then
					asktime = $ - 1
					if asktime <= 0 then
						print("sending askfilelist, current files "..fileneedednum)
						asktime = TICRATE
						if AskFileList(fileneedednum) then --native
							cl_lastcheckedfilecount = fileneedednum
						end
					end
				end
			elseif cl_mode == CL_CHECKFILES then
				CL_FinishedFileList()
			end
			
-- 			Deez()
		end
	end,
	
	showing_addons = false,
	
-- 	on_entry = function(self, old_menu)
-- 		self.loading = true
-- 	end,
	
	on_exit = function(self, new_menu)
-- 		Net_AbortConnection()
		if servernode > 0 and servernode < MAXNETNODES then
-- 			netnodes[(UINT8)servernode].ingame = false;
			Net_CloseConnection(servernode)
			print("Network game synchronization aborted.")
		end
	end,
	
	items = {
		--top box
		MenuItem_Box:new{width = FU * 300, height = FU * 54,
			x_offset = 0, align = "center",
			title_label = MenuItem_Text:new{colored = false},
			subtitle_label = MenuItem_Text:new{colored = false, scale = FU * 3 / 4, font = "TNYFN"},
			
			on_draw = function(self, x, y, width, height)
				local menu = self.parent
				
				if cl_mode == CL_SEARCHING then
					self.title_label.label = "Connecting to..."
					self.subtitle_label.label = viewip
					
					self.title_label:draw(x + height + FU * 4, y + FU * 4)
					self.subtitle_label:draw(x + height + FU * 4, y + FU * 4 + FU * 10)
					
					DrawSpinner(x + height / 2, y + height / 2)
				elseif cl_mode == CL_ASKFULLFILELIST then
					self.title_label.label = "Fetching full addon list..."
					self.subtitle_label.label = viewip
					
					self.title_label:draw(x + height + FU * 4, y + FU * 4)
					self.subtitle_label:draw(x + height + FU * 4, y + FU * 4 + FU * 10)
					
					DrawSpinner(x + height / 2, y + height / 2)
				elseif cl_mode == CL_VIEWSERVER then
					self.title_label.label = serverlist[joinnode].info.servername
					self.subtitle_label.label = serverlist[joinnode].info.maptitle
					
					self.title_label:draw(x + FU * 4, y + FU * 4)
					self.subtitle_label:draw(x + FU * 4, y + FU * 4 + FU * 10)
				elseif cl_mode == CL_CHECKFILES then
					self.title_label.label = "Checking server addon list..."
					self.subtitle_label.label = "0/0"
					
					self.title_label:draw(x + FU * 4, y + FU * 4)
					self.subtitle_label:draw(x + FU * 4, y + FU * 4 + FU * 10)
				end
			end
		},
		
		--top box
		MenuItem_Box:new{width = FU * 300, height = FU * 100,
			x_offset = 0, y_offset = FU * 5, align = "center",
-- 			title_label = MenuItem_Text:new{colored = false},
-- 			subtitle_label = MenuItem_Text:new{colored = false, scale = FU * 2 / 3},
			visible = false,
			
			on_draw = function(self, x, y, width, height)
				local menu = self.parent
				
				if cl_mode == CL_SEARCHING then
					self.visible = false
				elseif cl_mode == CL_VIEWSERVER then
					self.visible = true
					
					local num = 0
					
					if not menu.showing_addons then
						for i = 0, #playerinfo do
							if playerinfo[i] then
								v.drawString(x + FU * 4, y + num * FU * 10 + FU * 4, i..". "..playerinfo[i].name, V_ALLOWLOWERCASE, "thin-fixed")
								v.drawString(x + width - FU * 4, y + num * FU * 10 + FU * 4, playerinfo[i].score, V_ALLOWLOWERCASE, "thin-fixed-right")
								num = $ + 1
							end
						end
					else
-- 						v.drawString(x + FU * 4, y, "addons", V_ALLOWLOWERCASE, "thin-fixed")
						for i, file in ipairs(fileneeded) do
							v.drawString(x + FU * 4, y + num * FU * 10 + FU * 4, i..". "..file.filename, V_ALLOWLOWERCASE, "thin-fixed")
-- 							v.drawString(x + width - FU * 4, y + num * FU * 10 + FU * 4, playerinfo[i].score, V_ALLOWLOWERCASE, "thin-fixed-right")
							num = $ + 1
						end
					end
				end
			end
		},
		
-- 		MenuItem_UI_Button:new{body = "Byes", align = "center"},
-- 		MenuItem_UI_Button:new{body = "Yies", align = "center"},
-- 		MenuItem_UI_Button:new{body = "Myes", align = "center"},
-- 		MenuItem_UI_Button:new{body = "Mno", align = "center"},
-- 		MenuItem_UI_Button:new{body = "Nuhuh", align = "center"},
-- 		MenuItem_UI_Button:new{body = "Rno", align = "center"},
-- 		MenuItem_UI_Button:new{body = "Noo", align = "center"},
		MenuItem_UI_Button:new{body = "Back", align = "center", action = function(button)
			ShowPopup(serverlist[joinnode] and serverlist[joinnode].info.servername or "Server", "No.")
		end},
		MenuItem_UI_Button:new{body = "Join", align = "center", action = function(button)
			cl_mode = CL_CHECKFILES
		end},
		MenuItem_UI_Button:new{body = "Addons", align = "center", action = function(button)
			local menu = button.parent
			
			menu.showing_addons = not $
		end},
	},
}

--thax https://gist.github.com/jaredallard/ddb152179831dd23b230
--i did have to clean up some nasty whitespace though
local function string_split(self, delimiter)
	local result = {}
	local from = 1
	local delim_from, delim_to = string.find(self, delimiter, from)
	while delim_from do
		table.insert(result, string.sub(self, from, delim_from - 1))
		from  = delim_to + 1
		delim_from, delim_to = string.find(self, delimiter, from)
	end
	table.insert(result, string.sub(self, from))
	return result
end

COM_AddCommand("join", function(player, ip, port) serv_connect(ip or "10.0.0.242", port or "5029") end, COM_LOCAL)
--that's my laptop's ip by the way

--for slow internet (TODO: there is a cvar for this, use NUMBER timeout)
if HTTP then
	HTTP.setDefaultTimeout(20)
end

menus.ServerBowser = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 25 * 2,
	height = FU * 200 - FU * 20 * 2,
	title = "MULTIPLAYER",
	
	on_draw = function(self, v)
		if self.loading then
			DrawSpinner(FU * 160, FU * 100)
		end
	end,
	
	on_entry = function(self, old_menu)
		if old_menu == "Sonikm" then return end --no need to recalculate from connection
		
		--TODO: menuitem free position option..?
		print("Contacting master server...")
		
		self.items = {
			MenuItem_Header:new{label = "Contacting master server..."},
		}
		
		self:updateItems()
		
		if not HTTP then
-- 			ShowPopup("LEGO Island", "Oops! You have to put the CD\nin your computer.")
			ShowPopup("Server Bowser", "You do not have a custom build\nwith HTTP request functionality.")
			
			return
		end
		
		local function handleResponseError(response)
			if not response or not response.body then
				ShowPopup("Server Bowser", "Failed to fetch from HTTP.\nPlease try again.")
				
				--does "all" combine all rooms?
				--maybe it's srb2's fault that it doesn't display all rooms sometimes
-- 				for i, v in pairs(response) do
-- 					print(i, v)
-- 				end
				return
			end
			
			if response.message then
				ShowPopup("Server Bowser", "Failed to fetch from HTTP.\n"..response.message.."\nPlease try again.")
				print("error:", response.message)
				return
			end
		end
		
		local function connect(button)
			local server = button.ms_server
-- 			COM_BufInsertText(nil, "connect "..server.ip.." "..server.port)
			local ip = server.ip
			local port = server.port
-- 			ip = "10.0.0.242"
-- 			serv_connect(ip, port)
			return function()
				COM_BufInsertText(nil, "connect "..ip.." "..port)
			end
		end
		
		local function get_servers(button)
			self.items = {
				MenuItem_Header:new{label = "Loading servers..."},
			}
			
			self:updateItems()
			self.loading = true
			
			HTTP.get(("%s/rooms/%d/servers"):format(masterserver.string, button.ms_id), function(response)
				self.loading = false
				handleResponseError(response)
				
				local body = HTTP.decodeURL(response.body)
				local servs = {}
				local lines = string_split(body, "\n")
				
				for i, line in ipairs(lines) do
					if i == 1 then continue end --room number
					if i == #lines then break end
					
					local server = {}
					local words = string_split(line, " ")
					
					for i, word in ipairs(words) do
						if i == 1 then --server ip address
							server.ip = word
						elseif i == 2 then --server port
							server.port = word
						elseif i ~= #words then --server name
							server.name = ($ or "")..word..(i ~= #words - 1 and " " or "")
						else --server game version
							server.version = word
						end
					end
					
					table.insert(servs, server)
				end
				
				self.items = {
					MenuItem_Header:new{label = "Select a server"},
				}
				
				for i, server in ipairs(servs) do
					table.insert(self.items, MenuItem_Button:new{label = server.name,
						spacing = FU * 2, action = connect, ms_server = server,
						force_lowercase = true})
				end
				
				self:updateItems()
			end)
		end
		
		local function get_rooms(response)
			self.loading = false
			handleResponseError(response)
			
			local body = HTTP.decodeURL(response.body)
			local rooms = {}
			local state = {}
			
			for i, line in ipairs(string_split(body, "\n")) do
				if not state.in_room then
					state.in_room = true
					state.room = {}
					state.line_num = 1
					state.empty_lines = 0
				end
				
				local room = state.room
				
				if state.line_num == 1 then --room id
					room.id = tonumber(line)
				elseif state.line_num == 2 then --room name
					room.name = tostring(line)
				else --probably the description
					room.desc = ($ or "")..tostring(line).."\n"
				end
				
				if line == "" then
					state.empty_lines = $ + 1
				else
					state.empty_lines = 0
				end
				
				if state.empty_lines == 2 then
					state.in_room = false
					table.insert(rooms, state.room)
				end
				
				state.line_num = $ + 1
			end
			
			self.items = {
				MenuItem_Header:new{label = "Select a room"},
				
				MenuItem_Box:new{width = FU * 280, height = FU * 54, spacing = FU * 4,
					align = "center",
					level_title_label = MenuItem_Text:new{scale = FU / 2, force_lowercase = true},
					on_draw = function(box, x, y, width, height)
						local info = self.items[self.selection]
						
						if not info then return end
						
						local padding = FU * 8
						
						box.level_title_label.parent_width = width - padding * 2
						box.level_title_label.label = info.ms_desc
						box.level_title_label:draw(x + padding, y + padding - FU)
					end},
			}
			
			for i, v in ipairs(rooms) do
				table.insert(self.items, MenuItem_Button:new{label = v.name,
					spacing = FU * 2, ms_id = v.id, ms_desc = v.desc, action = get_servers,
					desc = (v.name == "All" and "The \"All\" room may not show all servers." or "Room ID: "..v.id)})
			end
			
			self:updateItems()
-- 			HTTP.get(("%s/rooms"):format(masterserver.string), get_rooms)
		end
		
		local function get_version(response)
			handleResponseError(response)
			
			self.items = {
				MenuItem_Header:new{label = "Loading rooms..."},
			}
			
			self:updateItems()
			
			HTTP.get(("%s/rooms"):format(masterserver.string), get_rooms)
		end
		
		self.loading = true
		HTTP.get(("%s/versions/%d"):format(masterserver.string, MODID), get_version)
	end,
	
	items = {
		MenuItem_Button:new{label = "Server browser...", link = "ServerBowser", spacing = FU * 2},
	},
}