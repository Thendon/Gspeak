//************************************************************
//
//	Gspeak by Thendon.exe
//
//	Thanks Sanuye for teaching me c++
//	Thanks El-Marto for his artwork
//	Thanks Zigi for helping me creating the Easy-Installer
//	Thanks Kuro for his 3D-Models
//	and Thanks to all Betatesters, Servers and Nockich
//
//************************************************************

gspeak = { version = 2600 };

//************************************************************
// Change these Variables ingame by entering !gspeak if possible
//************************************************************

--Setting Default variables
gspeak.settings = {
	distances = {
		modes = {
			{	name = "Whisper",	range = 150, icon = "gspeak/gspeak_whisper.png", icon_ui = "gspeak/gspeak_whisper_ui.png" },
			{	name = "Talk", range = 450, icon = "gspeak/gspeak_talk.png", icon_ui = "gspeak/gspeak_talk_ui.png" },
			{	name = "Yell", range = 900, icon = "gspeak/gspeak_yell.png", icon_ui = "gspeak/gspeak_yell_ui.png" },
		},
		heightclamp = 0.75,
		iconview = 1000,
		radio = 150
	},
	HUD = {
		console = {	x = 0.02,	y = 0.06,	align = "tr" },
		status = { x = 0.02, y = 0.02, align = "br" }
	},
	def_mode = 2,
	cmd =  "!gspeak",
	def_key = KEY_LALT,
	head_icon = true,
	head_name = false,
	reminder = true,
	ts_ip = "0.0.0.0",
	radio = {
		down = 4,
		dist = 1500,
		volume = 1.5,
		noise = 0.01,
		start = "start_com",
		stop = "end_com",
		hearable = true,
		use_key = true,
		def_key = KEY_CAPSLOCK
	},
	password = "",
	overrideV = false,
	overrideC = false,
	dead_chat = false,
	dead_alive = false,
	auto_fastdl = true,
	trigger_at_talk = false,
	nickname = true,
	def_initialForceMove = true,
	updateName = false
}

gspeak.sounds = {
	names = {},
	path = { cl = "gspeak/client/", sv = "gspeak/server/" },
	default = { "end_com", "radio_beep1", "radio_beep2", "radio_click1",
							"radio_click2", "start_com", "radio_booting", "radio_booting_s",
							"radio_click", "radio_release", "radio_turnoff", "radio_turnoff_s" }
}

local meta = FindMetaTable("Entity")
function meta:IsRadio()
	return self.Radio and true or false
end

function gspeak:ConsolePrint( text, color )
	if color then MsgC( color, "[Gspeak] ", text, "\n")
	else print( "[Gspeak] " .. text) end
end

function gspeak:add_sound(path, channel, volume, level, pitch)
	local _, _, name = string.find(path, "/.+/(.+)[.]")
	channel = channel or CHAN_ITEM
	volume = volume or 1.0
	level = level or 60
	pitch = pitch or 100

	sound.Add( {
	  name = name,
	  channel = channel,
	  volume = volume,
	  level = level,
	  pitch = pitch,
	  sound = path
	} )

	table.insert(gspeak.sounds.names, name )
end

function gspeak:player_valid(ply)
	if ply and IsValid( ply ) and ply:IsPlayer() then	return true	end
	return false
end

function gspeak:radio_valid(radio)
	if radio and IsValid( radio ) and radio:IsRadio() then return true end
	return false
end

function gspeak:get_talkmode_range( ID )
	local mode = gspeak.settings.distances.modes[ID]
	if !mode then return 0 end
	return mode.range
end

//********************************************
//								SQL
//********************************************

function gspeak:UpdateQuery(value, name)
	local q = sql.Query( "SELECT * FROM gspeak_settings WHERE name = '"..name.."'" )
	if q == false then
		gspeak:ConsolePrint( "Database UPDATE Error: "..sql.LastError(), Color(255,0,0) )
		return false
	elseif q == nil then
		gspeak:ConsolePrint( "New variable ( "..name.." ) found", Color(0,255,0))
		gspeak:InsertQuery(value, name)
	end

	if sql.Query( "UPDATE gspeak_settings SET value = "..gspeak:ValueToDB( value ).." WHERE name = '"..name.."'" ) == false then
		gspeak:ConsolePrint( "Database UPDATE Error: "..sql.LastError(), Color(255,0,0) )
		return false
	end
	return true
end

function gspeak:InsertQuery(value, name)
	if sql.Query( "INSERT INTO gspeak_settings ( name, value ) VALUES ( '" ..name.. "', " ..gspeak:ValueToDB( value ).. ")" ) == false then
		gspeak:ConsolePrint( "Database INSERT Error: "..sql.LastError(), Color(255,0,0) )
		return false
	end
	return true
end

function gspeak:ChangeSetting(setting, table, name, value, i, original_table)
	i = i or 1
	if table[setting[i]] == nil then gspeak:ConsolePrint("Setting "..name.." not found", Color(255,0,0)) return end
	original_table = original_table or table
	if i < #setting then gspeak:ChangeSetting(setting, table[setting[i]], name, value, i+1, original_table) return end
	table[setting[i]] = value

	if !gspeak:UpdateQuery(original_table[setting[1]], setting[1]) then return end
	gspeak:ConsolePrint("Changed "..name.." to "..tostring(value), Color(0,255,0))

	if SERVER then
		net.Start("gspeak_server_settings")
			net.WriteTable( { name = setting[1], value = original_table[setting[1]] } )
		net.Broadcast()
	end
end

function gspeak:ValueToDB( value )
	if istable(value) then return "'"..util.TableToJSON( value ).."'" end
	if isstring(value) then return "'"..value.."'" end
	if isbool(value) then return value and "'true'" or "'false'" end
	return value
end

function gspeak:DBToValue( value )
	local number = tonumber( value );
	if number and isnumber( number ) then return number end
	if value == "true" then return true end
	if value == "false" then  return false end
	local result_table = util.JSONToTable( value )
	if ( result_table and table.Count(result_table) > 0 ) then return result_table end
	return value;
end

function gspeak:QueryTable( table, func )
	for name, value in pairs(table) do
		func(name, value )
	end
end

function gspeak:SaveResult( result, table )
	for k, v in pairs(result) do
		table[v.name] = gspeak:DBToValue( v.value )
	end
end

function gspeak:VersionCheck()
	if (!file.Exists("gspeak/version.txt", "DATA")) then
		file.CreateDir("gspeak")
		file.Write("gspeak/version.txt", gspeak.version)
	else
		local loaded_version = file.Read( "gspeak/settings.txt" )
		if loaded_version != version then
			if SERVER then
			else
			end
			local update_success = true
			if update_success then file.Write("gspeak/version.txt", gspeak.version) end
		end
	end
end

function gspeak:LoadSettings( table )
	if !sql.TableExists("gspeak_settings") then
		sql.Query( "CREATE TABLE gspeak_settings ( name VARCHAR(255) PRIMARY KEY, value TEXT )" )
	  if !sql.TableExists("gspeak_settings") then gspeak:ConsolePrint( "Database Error: "..sql.LastError(), Color(255,0,0) ) return end
		gspeak:ConsolePrint( "Table created successfully", Color(0,255,0) )
		if !table then return end
		gspeak:QueryTable( table, function(name, value)
			gspeak:InsertQuery( value, name)
		end )
		return
	end

	result = sql.Query( "SELECT * FROM gspeak_settings" )
	if result == false then gspeak:ConsolePrint( "Database Error: "..sql.LastError(), Color(255,0,0) ) return end
	for name, value in pairs( table ) do
		local found = false
		if result then for k, v in pairs(result) do if name == v.name then found = true end end end

		if !found then
			gspeak:InsertQuery( value, name)
		end
	end
	if !result then return end
	gspeak:SaveResult(result, table)
	gspeak:ConsolePrint( "Table loaded successfully", Color(0,255,0) )
end

if SERVER then
	include ( "gspeak/sv_gspeak_run.lua" )
else
	include( "gspeak/cl_gspeak_run.lua" )
end
