//********************************************
//							GSPEAK FUNCTIONS
//********************************************

function gspeak:send_settings()
	if !tslib.sendSettings(	gspeak.settings.password,
													gspeak.settings.radio.down,
													gspeak.settings.radio.dist,
													gspeak.settings.radio.volume,
													gspeak.settings.radio.noise ) then gspeak:chat_text("channel Password too long!", true) end
end
--[[
function gspeak:send_name( name )
	tslib.sendName( name )
end

function gspeak:force_move()
	tslib.forceMove()
end
]]
function gspeak:chat_text(text, error)
	--error = error or false
	chat.AddText( gspeak.cl.color.red, "[Gspeak]", error and " ERROR " or " ", gspeak.cl.color.black, text)
end

function gspeak:RefreshIcons()
	for k, v in pairs(gspeak.settings.distances.modes) do
		if v.icon then v.material = Material( v.icon, "noclamp unlitgeneric" ) end
		if v.icon_ui then v.material_ui = Material( v.icon_ui, "noclamp unlitgeneric" ) end
	end
end

function gspeak:SetDefaultVars()
	if !gspeak.cl.settings.talkmode then
		gspeak.cl.settings.talkmode = gspeak.settings.def_mode
		gspeak:ChangeSetting( { "talkmode" }, gspeak.cl.settings, "talkmode", gspeak.settings.def_mode )
	end
	if !gspeak.cl.settings.key then
		gspeak.cl.settings.key = gspeak.settings.def_key
		gspeak:ChangeSetting( { "key" }, gspeak.cl.settings, "key", gspeak.settings.def_key )
	end
	if !gspeak.cl.settings.radio_key then
		gspeak.cl.settings.radio_key = gspeak.settings.radio.def_key
		gspeak:ChangeSetting( { "radio_key" }, gspeak.cl.settings, "radio_key", gspeak.settings.radio.def_key )
	end
end

function gspeak:change_talkmode( talkmode )
	if talkmode <= #gspeak.settings.distances.modes then
		gspeak.cl.settings.talkmode = talkmode
	else
		gspeak.cl.settings.talkmode = 1
	end
	net.Start( "ts_talkmode" )
		net.WriteInt( gspeak.cl.settings.talkmode, 32 )
	net.SendToServer()
	chat.AddText( gspeak.cl.color.red, "[Gspeak]",  gspeak.cl.color.black, " mode: ", gspeak.cl.color.green, gspeak.settings.distances.modes[gspeak.cl.settings.talkmode].name )
end

function gspeak:ts_talking( trigger )
	LocalPlayer().talking = trigger
	gspeak.cl.start_talking = trigger
	net.Start("ts_talking")
		net.WriteBool( trigger )
	net.SendToServer()
end

function gspeak:get_talkmode( ply )
	if ply == LocalPlayer() then return gspeak.cl.settings.talkmode end
	if !ply:Alive() then return 2	end //Thendon make dead chat talkmode
	if ply.talkmode != nil then	return ply.talkmode	end
	//Thendon is this smart?
	--return gspeak.settings.def_mode
end

function gspeak:set_tsid( ts_id )
	if ts_id < 0 then
		gspeak.cl.TS.connected = false
	end
	net.Start("ts_id")
		net.WriteInt(ts_id, 32)
	net.SendToServer()
end

function gspeak:get_tsid(ply)
	local ts_id = ply.ts_id or -1
	ply.req_it = ply.req_it or 1
	if ts_id == -1 then ply.req_it = ply.req_it + 1 end
	if ply.req_it > 1000 then
		gspeak:request_ts_id( ply, ts_id )
		ply.req_it = 1
	end
	return ts_id
end

function gspeak:request_ts_id( ply, ts_id )
	net.Start("request_ts_id")
		net.WriteEntity( ply )
		net.WriteInt( ts_id, 32 )
	net.SendToServer()
end

--Tries to move the User into the channel until succeeds
function gspeak:forceMoveLoop()
	tslib.forceMove( function( success )
		if !success then
			gspeak:forceMoveLoop()
		end
	end)
end

local updateNameInProgress
function gspeak:updateName( name )
	if updateNameInProgress then return end
	updateNameInProgress = true
	tslib.sendName( name, function( success )
		if success then
			gspeak:chat_text("changed Teamspeak nickname to " .. name)
		else
			gspeak:chat_text("failed to update nickname (" .. name .. ")", true)
		end
		updateNameInProgress = false
	end )
end

function gspeak:checkConnection()
	if gspeak.cl.TS.connected then
		gspeak.cl.updateTick = gspeak.cl.updateTick + 1
		--update every 100th tick
		if gspeak.cl.updateTick > 100 then
			gspeak.cl.updateTick = 0
			tslib.update()
		end

		if gspeak.settings.def_initialForceMove and !gspeak.cl.movedInitially then
			gspeak.cl.movedInitially = true
			gspeak:forceMoveLoop()
		end

		if gspeak.settings.updateName then
			local name = gspeak:GetName( LocalPlayer() )
			--compareName( string ) compares the users teamspeak name with the string
			--with Teamspeaks name buffer-limits in mind
			if !tslib.compareName( name ) then
				gspeak:updateName( name )
			end
		end

		gspeak.cl.TS.version = tslib.getGspeakVersion()

		 --closed Teamspeak3
		if gspeak.cl.TS.version == -1 then
			gspeak.cl.TS.connected = false
			gspeak.cl.movedInitially = false
		end
		return
	elseif tslib.connectTS() == true then
		if !IsValid(LocalPlayer()) then return end
		gspeak.cl.TS.version = tslib.getGspeakVersion()
		if gspeak.cl.TS.version == -1 or gspeak.cl.TS.version == 0 then return end
		if gspeak.cl.TS.version < gspeak.cl.TS.req or gspeak.cl.TS.version > gspeak.cl.TS.max then gspeak.cl.TS.failed = true return end

		net.Start( "ts_talkmode" )
			net.WriteInt( gspeak.cl.settings.talkmode, 32 )
		net.SendToServer()

		tslib.delAll()
		tslib.sendClientPos( 0, 0, 0, 0, 0, 0)
		gspeak:send_settings()

		gspeak.cl.TS.failed = false
		gspeak.cl.TS.connected = true
	end
end

function gspeak:request_init()
	net.Start("gspeak_request_init")
	net.SendToServer()
end

function gspeak:UpdateLoading()
	local loadanim = gspeak.cl.loadanim
	loadanim.state[loadanim.active] = math.Approach( loadanim.state[loadanim.active], loadanim.dir, FrameTime() * 10 );
	if loadanim.state[loadanim.active] == loadanim.dir then
		if loadanim.dir == 1 then
			loadanim.dir = 0
		elseif loadanim.dir == 0 then
			loadanim.dir = 1
			loadanim.active = loadanim.active + 1
			if loadanim.active > 4 then loadanim.active = 1 end
		end
	end
end

function gspeak:VersionWord( plugin )
	if plugin.version >= plugin.max then
		return "downgrade to"
	elseif plugin.version < plugin.req then
		return "update to"
	end
	return "install"
end

function gspeak:DeadChat()
	if gspeak.settings.dead_chat then
		if gspeak.cl.dead_muted then
			gspeak.cl.dead_muted = false
			chat.AddText( gspeak.cl.color.red, "[Gspeak]",  gspeak.cl.color.black, " unmuted dead players ")
		else
			gspeak.cl.dead_muted = true
			chat.AddText( gspeak.cl.color.red, "[Gspeak]",  gspeak.cl.color.black, " muted dead players ")
		end
	end
end

function gspeak:GetName( ply )
	if gspeak.settings.nickname then return ply:Nick() end
	return ply:GetName()
end

function gspeak:PlayerBindPress( ply, bind, pressed )
	if !gspeak.terrortown then return end
	if gspeak.settings.overrideV and bind == "+voicerecord" then
		return true
	elseif gspeak.settings.overrideV and bind == "+speed" and gspeak:player_alive(LocalPlayer()) then
		return true
	elseif gspeak.settings.dead_chat and bind == "gm_showteam" and pressed and !gspeak:player_alive(LocalPlayer()) then
		gspeak:DeadChat()
		return true
	elseif !gspeak.settings.dead_chat and bind == "gm_showteam" then
		return true
	end
end

function gspeak:MouthMoveAnimation( ply )
	if !gspeak.cl.running then return end
	local FlexNum = ply:GetFlexNum() - 1
	if ( FlexNum <= 0 ) then return end

	ply.volume = ply.volume or 0
	ply.mouthweight = ply.mouthweight or 0

	local new_weight = 0
	if ply.volume != 0 and ply.hearable and ply.talking then
		new_weight = math.Approach(ply.mouthweight,math.Clamp( 1 + math.log(ply.volume, 10), 0, 1 ),FrameTime() * 7)
	end

	for i = 0, FlexNum - 1 do
		local Name = ply:GetFlexName( i )
		if ( Name == "jaw_drop" or Name == "right_part" or Name == "left_part" or Name == "right_mouth_drop" or Name == "left_mouth_drop" ) then
			ply:SetFlexWeight( i, new_weight )
		end
	end
	ply.mouthweight = new_weight
end

function gspeak:GrabEarAnimation( ply )
	ply.ChatGestureWeight = ply.ChatGestureWeight or 0
	local update = false
	if ply.ChatGesture then
		if ply.ChatStation then
			ply.ChatGestureWeight = math.Approach( ply.ChatGestureWeight, 0.5, FrameTime() * 10.0 );
		else
			ply.ChatGestureWeight = math.Approach( ply.ChatGestureWeight, 1, FrameTime() * 10.0 );
		end
		update = true
	elseif ply.ChatGestureWeight > 0 then
		ply.ChatGestureWeight = math.Approach( ply.ChatGestureWeight, 0, FrameTime()  * 10.0 );
		update = true
	end

	if update then
		ply:AnimRestartGesture( GESTURE_SLOT_CUSTOM, ACT_GMOD_IN_CHAT )
		ply:AnimSetGestureWeight( GESTURE_SLOT_CUSTOM, ply.ChatGestureWeight )
		ply.ChatGesture = false
	end
end

function gspeak:draw_range( pos, size, cut, color)
	local normal = Vector(0,0,1)
	render.DrawWireframeSphere(pos, size, 8, 8, color)
	if cut == 0 then return end
	render.DrawQuadEasy(pos + Vector(0, 0, size) * Vector(1,1,cut), normal, size, size, color, 0)
	render.DrawQuadEasy(pos + Vector(0, 0, size) * Vector(1,1,cut), -normal, size, size, color, 0)
	render.DrawQuadEasy(pos - Vector(0, 0, size) * Vector(1,1,cut), normal, size, size, color, 0)
	render.DrawQuadEasy(pos - Vector(0, 0, size) * Vector(1,1,cut), -normal, size, size, color, 0)
end

function gspeak:get_distances( ent, talkmode )
	local range = ent.range or 0

	local ent_pos = ent:GetPos()
	if ent:IsPlayer() then ent_pos = ent_pos + gspeak:get_offset(ent)	end
	local pos = gspeak.clientPos or LocalPlayer():GetPos()
	ent_pos:Sub(pos)
	ent_pos = ent_pos * Vector(1,1,1 / gspeak.settings.distances.heightclamp)
	local distance = Vector(0,0,0):Distance(ent_pos)

	return distance, range, ent_pos
end

function gspeak:get_offset(ply)
	if !gspeak:player_alive(ply) then return gspeak.cl.player.dead end
	if ply:Crouching() then	return gspeak.cl.player.crouching end
	if IsValid(ply:GetVehicle()) then return gspeak.cl.player.vehicle end
	return gspeak.cl.player.standing
end

function gspeak:player_alive(ply)
	if !ply:Alive() then return false end

	//*************************************************
	//INSERT YOUR OWN DEAD CONDITIONS HERE
	//terrortown Example:
	//*************************************************
	if gspeak.terrortown and ( ply:IsSpec() or GetRoundState() == ROUND_POST ) then return false end
	//*************************************************

	return true
end

//Thendon du hast hioer einfach aufgehört lol
//wird vom LocalPLayer getriggert?!
//Edit: Glaube das ist ein cpp test (gs_delPos)
function gspeak.setHearable(ent_id, bool)
	--print(tostring(bool))
	if gspeak:player_valid(Entity(ent_id)) then Entity(ent_id).hearable = bool end
end

function gspeak:calcVolume( distance, distance_max )
	return 1 - distance / distance_max
end

function gspeak:NoDoubleEntry(variable, Table)
	for k, v in pairs(Table) do
		if v == variable then	return	end
	end
	table.insert(Table, variable)
end

function gspeak:UpdatePlayers()
	for k, v in pairs(player.GetAll()) do
		if !v:IsPlayer() then	continue end
		gspeak:NoDoubleEntry( v, gspeak.cl.players)
	end
end
