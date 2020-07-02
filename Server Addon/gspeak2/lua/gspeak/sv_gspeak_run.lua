AddCSLuaFile( "gspeak/cl_gspeak_run.lua" )
AddCSLuaFile( "gspeak/cl_functions.lua" )
AddCSLuaFile( "gspeak/cl_net.lua" )
AddCSLuaFile( "gspeak/cl_hooks.lua" )
AddCSLuaFile( "gspeak/sh_def_swep.lua" )
AddCSLuaFile( "gspeak/sh_def_ent.lua" )
AddCSLuaFile( "vgui/gspeak_config.lua" )
AddCSLuaFile( "vgui/gspeak_hearable.lua" )
AddCSLuaFile( "vgui/gspeak_ui.lua" )

util.AddNetworkString( "ts_talking" )
util.AddNetworkString( "ts_ply_talking" )
util.AddNetworkString( "ts_talkmode" )
util.AddNetworkString( "ts_ply_talkmode" )
util.AddNetworkString( "ts_id" )
util.AddNetworkString( "ts_ply_id" )
util.AddNetworkString( "gspeak_server_settings" )
util.AddNetworkString( "gspeak_ply_disc" )
util.AddNetworkString( "gspeak_failed" )
util.AddNetworkString( "gspeak_failed_broadcast" )
util.AddNetworkString( "gspeak_init" )
util.AddNetworkString( "gspeak_request_init" )
util.AddNetworkString( "gspeak_setting_change" )
util.AddNetworkString( "gspeak_name_change" )
util.AddNetworkString( "radio_freq_change" )
util.AddNetworkString( "radio_sending_change" )
util.AddNetworkString( "radio_online_change" )
util.AddNetworkString( "radio_page_req" )
util.AddNetworkString( "radio_page_set" )
util.AddNetworkString( "radio_send_settings" )
util.AddNetworkString( "radio_init" )
util.AddNetworkString( "request_ts_id" )

//********************************************
//						FASTDL SETTINGS
//
//Uncomment the following code if you want to host the
//files all on your own FastDL.
//********************************************

--[[resource.AddFile("materials/gspeak/gspeak_off.png")
resource.AddFile("materials/gspeak/gspeak_error.png")
resource.AddFile("materials/gspeak/gspeak_loading.png")
resource.AddFile("materials/gspeak/gspeak_whisper.png")
resource.AddFile("materials/gspeak/gspeak_talk.png")
resource.AddFile("materials/gspeak/gspeak_yell.png")
resource.AddFile("materials/gspeak/gspeak_whisper_ui.png")
resource.AddFile("materials/gspeak/gspeak_talk_ui.png")
resource.AddFile("materials/gspeak/gspeak_yell_ui.png")
resource.AddFile("materials/gspeak/arrow_up.png")
resource.AddFile("materials/gspeak/arrow_down.png")
resource.AddFile("materials/gspeak/gspeak_logo_new.png")
resource.AddFile("materials/gspeak/gspeak2_logo.png")
resource.AddFile("materials/gspeak/gspeak_radio_back.png")
resource.AddFile("materials/gspeak/gspeak_logo.png")
resource.AddFile("materials/gspeak/radio/funktronics.vmt")
resource.AddFile("materials/gspeak/radio/MilitaryRadio.vmt")
resource.AddFile("materials/VGUI/entities/swep_radio.vmt")
resource.AddFile("materials/VGUI/entities/radio_cop.vmt")
resource.AddFile("materials/VGUI/entities/radio_fire.vmt")
resource.AddFile("materials/VGUI/entities/radio_taxi.vmt")
resource.AddFile("materials/VGUI/entities/radio_ems.vmt")
resource.AddFile("materials/VGUI/entities/radio_ent_station.vmt")
resource.AddFile("materials/VGUI/HUD/swep_radio.vmt")
resource.AddFile("materials/VGUI/HUD/radio_cop.vmt")
resource.AddFile("materials/VGUI/HUD/radio_fire.vmt")
resource.AddFile("materials/VGUI/HUD/radio_taxi.vmt")
resource.AddFile("materials/VGUI/HUD/radio_ems.vmt")
resource.AddFile("materials/VGUI/TTT/radio_d.vmt")
resource.AddFile("materials/VGUI/TTT/radio_t.vmt")
resource.AddFile("materials/VGUI/TTT/radio_d_s.vmt")
resource.AddFile("models/gspeak/militaryradio.mdl")
resource.AddFile("models/gspeak/funktronics.mdl")
resource.AddFile("models/gspeak/vfunktronics.mdl")
resource.AddFile("sound/gspeak/server/radio_click.mp3")
resource.AddFile("sound/gspeak/server/radio_release.mp3")
resource.AddFile("sound/gspeak/server/radio_booting.mp3")
resource.AddFile("sound/gspeak/server/radio_turnoff.mp3")
resource.AddFile("sound/gspeak/server/radio_booting_s.mp3")
resource.AddFile("sound/gspeak/server/radio_turnoff_s.mp3")
resource.AddFile("sound/gspeak/client/radio_click1.mp3")
resource.AddFile("sound/gspeak/client/radio_click2.mp3")
resource.AddFile("sound/gspeak/client/radio_beep1.mp3")
resource.AddFile("sound/gspeak/client/radio_beep2.mp3")
resource.AddFile("sound/gspeak/client/start_com.mp3")
resource.AddFile("sound/gspeak/client/end_com.mp3")
resource.AddFile("resource/fonts/capture it.ttf")]]

//********************************************
//Comment this out if you do not want to use the
//Workshop Collection.
//********************************************
resource.AddWorkshop( 533494097 )

//********************************************
//								FUNCTIONS
//********************************************

function gspeak:broadcast_talkmode( ply )
	net.Start("ts_ply_talkmode")
		net.WriteEntity( ply )
		net.WriteInt( ply.talkmode, 32 )
		net.WriteInt( gspeak.settings.distances.modes[ply.talkmode].range, 32 )
	net.Broadcast()
end

function gspeak:updateName( ply, name )
	net.Start("gspeak_name_change")
		net.WriteString( name )
	net.Send(ply)
end

function gspeak:add_file(path, file)
	local new = true
	for i, j in pairs(gspeak.sounds.default) do
		if j .. ".mp3" == file then
			new = false
		end
	end

	if new then
		gspeak.ConsolePrint( "adding: " .. path .. file)
		resource.AddFile(path .. file)
	end
end

//********************************************
//								INITIALIZE
//********************************************

gspeak:VersionCheck()
gspeak:LoadSettings( gspeak.settings )

local files = file.Find("sound/" .. gspeak.sounds.path.sv .. "*", "GAME")
for k, v in pairs(files) do
	if v == "radio_booting_s" or v == "radio_turnoff_s" or v == "radio_click" or v == "radio_release" then
		gspeak:add_sound(gspeak.sounds.path.sv .. v, CHAN_ITEM, 1.0, 20)
	else
		gspeak:add_sound(gspeak.sounds.path.sv .. v)
	end
	gspeak:add_file(gspeak.sounds.path.sv, v)
end

local files = file.Find("sound/" .. gspeak.sounds.path.cl .. "*", "GAME")
for k, v in pairs(files) do
	gspeak:add_file(gspeak.sounds.path.cl, v)
end

//********************************************
//								NETCODE
//********************************************

net.Receive("radio_online_change",function( len, ply )
	local radio = net.ReadEntity()
	local online = net.ReadBool()
	if online then
		radio:EmitSound("radio_turnoff")
		radio:SetOnline(false)
		return
	end
	radio:EmitSound("radio_booting")
	radio:SetOnline(true)
end)

net.Receive("radio_freq_change", function( len, ply )
	local radio = net.ReadEntity()
	local isSwep = net.ReadBool()
	local freq = net.ReadInt( 32 )
	if isSwep then
		radio.ent:SetFreq(freq)
		return
	end
	radio:SetFreq(freq)
end)

net.Receive("radio_sending_change", function( len, ply )
	local radio = net.ReadEntity()
	local sending = net.ReadBool()

	if !radio or !IsValid(radio) or !radio:IsRadio() then return end

	radio:SetSending( sending )

	if radio:GetParent().silent then return end

	local now = CurTime()
	if sending and radio.last_sound < now - 0.1 then
		radio:EmitSound("radio_click")
		radio.last_sound = now
	elseif radio.last_sound < now - 0.1 then
		radio:EmitSound("radio_release")
		radio.last_sound = now
	end
end)

net.Receive("radio_init", function( len, ply )
	local radio = net.ReadEntity()
	if !gspeak:radio_valid(radio) then return end
	local owner = net.ReadEntity()
	radio:SendSettings(owner)
end)

net.Receive("ts_talking", function( len, ply )
	local trigger = net.ReadBool()
	ply.talking = trigger

	net.Start("ts_ply_talking")
		net.WriteEntity( ply )
		net.WriteBool( trigger )
	net.Broadcast()
end)

net.Receive("request_ts_id", function( len, ply )
	local other = net.ReadEntity()
	local ts_id = net.ReadInt( 32 )

	if ts_id == other.ts_id or !other.ts_id then return end

	net.Start("ts_ply_id")
		net.WriteEntity( other )
		net.WriteInt( other.ts_id, 32 )
	net.Send( ply )
end)

net.Receive("ts_id", function( len, ply )
	local ts_id = net.ReadInt( 32 )

	net.Start("ts_ply_id")
		net.WriteEntity( ply )
		net.WriteInt( ts_id, 32 )
	net.Broadcast()

	ply.ts_id = ts_id
end)

net.Receive("ts_talkmode", function ( len, ply )
	ply.talkmode = net.ReadInt( 32 )
	gspeak:broadcast_talkmode(ply)
end)

net.Receive("gspeak_failed", function( len, ply )
	net.Start( "gspeak_failed_broadcast" )
		net.WriteEntity(ply)
	net.Broadcast()
end)

net.Receive("gspeak_request_init", function( len, ply )
	local all_ply_table = {}
	local all_radio_table = {}
	for k, v in pairs(ents.GetAll()) do
		if v == ply then continue end
		if v:IsPlayer() then
			local ply_table = {}
			table.insert(ply_table, 1, v)
			table.insert(ply_table, 2, v.talkmode)
			table.insert(ply_table, 3, v.ts_id)
			table.insert(ply_table, 4, v.talking or false)
			table.insert(ply_table, 5, gspeak:get_talkmode_range(v.talkmode) --[[gspeak.settings.distances.modes[v.talkmode].range]] or 0 )
			table.insert(all_ply_table, ply_table)
		elseif v:IsRadio() then
			local radio_table = {}
			table.insert(radio_table, 1, v.online)
			table.insert(radio_table, 2, v.freq)
			table.insert(radio_table, 3, v.sending)
			--table.insert(radio_table, 4, v.menu.page or 0)
			table.insert(all_radio_table, radio_table)
		end
	end

	net.Start( "gspeak_init" )
		net.WriteTable(all_ply_table)
		net.WriteTable(all_radio_table)
		net.WriteTable(gspeak.settings)
	net.Send( ply )
end)

net.Receive("gspeak_setting_change", function(len, ply)
	local setting = net.ReadTable()
	gspeak:ChangeSetting(string.Explode( ".", setting.name ), gspeak.settings, setting.name, setting.value)
end)

net.Receive("radio_page_req", function(len, ply)
	local radio = net.ReadEntity()
	local page = net.ReadInt(3)
	if !gspeak:radio_valid(radio) then return end
	radio.menu.page = page
	net.Start("radio_page_set")
		net.WriteEntity(radio)
		net.WriteInt(page, 3)
	net.Broadcast()
end)

//********************************************
//								HOOKS
//********************************************

hook.Add( "PlayerDisconnected", "gspeak_disconnect", function( ply )
	net.Start("gspeak_ply_disc")
		net.WriteInt( ply:EntIndex(), 32 )
	net.Broadcast()
end)
