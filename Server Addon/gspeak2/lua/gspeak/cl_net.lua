//********************************************
//							GSPEAK NETCODE
//********************************************

net.Receive("ts_ply_id", function( len )
	local ply = net.ReadEntity()
	ply.ts_id = net.ReadInt( 32 )
end)

net.Receive("ts_ply_talking", function( len )
	ply = net.ReadEntity()
	ply.talking = net.ReadBool()
end)

net.Receive("ts_ply_talkmode", function ( len )
	ply = net.ReadEntity()
	ply.talkmode = net.ReadInt( 32 )
	ply.range = net.ReadInt( 32 )
end)

net.Receive("gspeak_name_change", function( len )
	local name = net.ReadString()
	if gspeak.cl.TS.connected then
		tslib.sendName( name, function( success )
			print( success and "true" or "false" )
		end )
	end
end)

net.Receive("gspeak_ply_disc", function ( len )
	index = net.ReadInt(32)
	if gspeak.cl.TS.connected then tslib.delPos(index, false, -1) end
end)

net.Receive("gspeak_server_settings", function()
	local setting = net.ReadTable()
	gspeak.settings[setting.name] = setting.value
	gspeak:RefreshIcons()
	if gspeak.cl.TS.connected then gspeak:send_settings() end
end)

net.Receive("gspeak_failed_broadcast", function(len)
	local ply = net.ReadEntity()
	ply.failed = true
end)

net.Receive("gspeak_init", function( len )
	for k, v in pairs(ents.GetAll()) do
		if !IsValid(v) then continue end
		if v:IsPlayer() then
			gspeak:NoDoubleEntry(v, gspeak.cl.players)
		elseif v:IsRadio() then
			gspeak:NoDoubleEntry(v, gspeak.cl.radios)
		end
	end

	if GAMEMODE_NAME == "terrortown" then gspeak.terrortown = true end

	local ply_var_table = net.ReadTable()
	local radio_var_table = net.ReadTable()
	gspeak.settings = net.ReadTable()

	for k, v in pairs(ply_var_table) do
		v[1].talkmode = v[2]
		v[1].ts_id = v[3]
		v[1].talking = v[4]
		v[1].range = v[5]
	end

	--[[for k, v in pairs(radio_var_table) do
		//Thendon du hast hier was vergessen..
	end]]
	--gspeak:read_server_settings()

	--cast icon picture to material and save it
	gspeak:RefreshIcons()
	gspeak:LoadSettings( gspeak.cl.settings )
	gspeak:SetDefaultVars()
	if gspeak.cl.TS.connected then gspeak:send_settings() end

	if pcall( require, "tslib" ) then
		if pcall( function() tslib.getVersion() end) then
			gspeak.cl.tslib.version = tslib.getVersion()
			MsgC( gspeak.cl.color.red, "TSlib included - ", gspeak.cl.color.white, "Version ", tostring(gspeak.cl.tslib.version), "\n")
			if gspeak.cl.tslib.version >= gspeak.cl.tslib.req and gspeak.cl.tslib.version < gspeak.cl.tslib.max then
				gspeak.cl.running = true
				gspeak:set_tsid(-1) --loading mode
				return
			else
				gspeak.cl.tslib.wrongVersion = true
				MsgC( gspeak.cl.color.red, "TSlib Wrong Version! - ", gspeak.cl.color.white, "Version ", tostring(gspeak.cl.tslib.version), "\n")
			end
		else
			gspeak.cl.tslib.wrongVersion = true
			MsgC( gspeak.cl.color.red, "TSlib - ", gspeak.cl.color.white, "No Version function!\n")
		end
	else
		MsgC( gspeak.cl.color.red, "TSlib - ", gspeak.cl.color.white, "No TSlib DLL found / require failed!\n")
	end
	gspeak.cl.failed = true
end)

net.Receive("radio_page_set", function( len )
	local radio = net.ReadEntity()
	local page = net.ReadInt(3)
	if gspeak:radio_valid(radio) then radio.menu.page = page end
end)

net.Receive("radio_send_settings",function( len )
	local radio = net.ReadEntity()
	radio.settings = net.ReadTable()
end)
