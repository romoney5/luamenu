--reimplementation of part of the client connection code because.. why not?!
--this does rely on some custom native functions though, so if you don't have
--the right build, this is as good as useless

local menus, v = ...

--network stuff is always gonna involve some loading,
--the user deserves a pretty loading spinner
local function DrawSpinner()
	local bg = v.cachePatch("MENU_LOAD1")
	v.drawScaled(FU * 160, FU * 100, FU / 2, bg, V_50TRANS)
	
	local spinner = v.cachePatch("MENU_LOAD2", FixedAngle(FU * leveltime * -8))
	v.drawScaled(FU * 160, FU * 100, FU / 2, spinner, 0)
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

local FORCECLOSE = 0x8000

local asktime = 0
local joinnode = 0

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

--finds some servers
local function CL_ServerConnectionSearchTicker()
	local serverlistcount = #serverlist
-- 	print(serverlistcount, servernode)
	local i = 0
	
	if serverlistcount > 0 then
		print("count = "..serverlistcount)
		print("netgame = "..tostring(netgame))
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
			
			print("CL_ServerConnectionSearchTicker: reached CL_VIEWSERVER")
			print(info.servername)
			cl_mode = CL_VIEWSERVER
			D_ParseFileneeded(info.fileneedednum, info.fileneeded, 0) --native
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

local function CL_ConnectToServer()
	print("Contacting the server...")
	
	cl_mode = CL_SEARCHING
	asktime = 0
	
	SL_ClearServerList(servernode)
end

local function serv_connect(ip, port)
	Menu_GotoLink("Sonikm")
	
	I_NetOpenSocket() --native
	SetMultiplayer() --native
	
	servernode = I_NetMakeNodewPort(ip, port) --native
	
	CL_ConnectToServer()
end

menus.Sonikm = Menu:new{
	on_draw = function(self, v)
		v.drawString(0, 0, "Conedcting", V_ALLOWLOWERCASE)
		
		if cl_mode == CL_SEARCHING--[[self.loading]] then
			DrawSpinner()
		else
			v.drawString(0, 10, serverlist[joinnode].info.servername, V_ALLOWLOWERCASE)
			v.drawString(0, 20, serverlist[joinnode].info.maptitle, V_ALLOWLOWERCASE)
		end
		
		if v.isNewTic() then
			if cl_mode == CL_SEARCHING then
				CL_ServerConnectionSearchTicker()
			end
			
-- 			Deez()
		end
	end,
	
-- 	on_entry = function(self, old_menu)
-- 		self.loading = true
-- 	end,
	
	on_exit = function(self, new_menu)
-- 		Net_AbortConnection()
		if servernode > 0 and servernode < MAXNETNODES then
-- 			netnodes[(UINT8)servernode].ingame = false;
			Net_CloseConnection(servernode)
		end
	end,
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

COM_AddCommand("join", function(player, ip, port) serv_connect(ip, port) end, COM_LOCAL)

--for slow internet (there is a cvar for this, use NUMBER timeout)
HTTP.setDefaultTimeout(20)

menus.ServerBowser = Menu:new{
	anchor = {x = "center", y = "top"},
	width = FU * 320 - FU * 25 * 2,
	height = FU * 200 - FU * 20 * 2,
	
	on_draw = function(self, v)
		if self.loading then
			DrawSpinner()
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
			if not response then
				ShowPopup("Server Bowser", "Failed to fetch from HTTP.\nPlease try again.")
				return
			end
			
			if response.message then
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
			print("CONNECTING "..ip..", "..port)
			serv_connect(ip, port)
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
					table.insert(self.items, MenuItem_Button:new{label = ("%s (%s:%s)"):format(server.name, server.ip, server.port),
						spacing = FU * 2, action = connect, ms_server = server})
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
					print("got name "..room.name)
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
				
-- 				print(line)
			end
			
			self.items = {
				MenuItem_Header:new{label = "Select a room"},
			}
			
			for i, v in ipairs(rooms) do
				table.insert(self.items, MenuItem_Button:new{label = v.id..": "..v.name,
					spacing = FU * 2, ms_id = v.id, action = get_servers})
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