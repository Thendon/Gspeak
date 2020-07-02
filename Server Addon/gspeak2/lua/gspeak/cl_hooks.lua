//********************************************
//							GSPEAK HOOKS
//********************************************

hook.Add("OnEntityCreated", "ent_array", function( ent )
	if ent:IsPlayer() then
		gspeak:NoDoubleEntry( ent, gspeak.cl.players )
	end
end)

hook.Add("InitPostEntity", "gspeak_ply_fully_loaded", function()
	gspeak:request_init()

	function GAMEMODE:MouthMoveAnimation( ply )
		gspeak:MouthMoveAnimation( ply )
	end

	function GAMEMODE:GrabEarAnimation( ply )
		gspeak:GrabEarAnimation( ply )
	end
	--[[
	local old_voice = GAMEMODE.PlayerStartVoice
	function GAMEMODE.PlayerStartVoice( _, ply )
		if gspeak.settings.overrideV then return false end
		return old_voice( ply )
	end
	]]
	if GAMEMODE_NAME == "darkrp" then return end

  original_bind = GAMEMODE.PlayerBindPress
	function GAMEMODE.PlayerBindPress( _, ply, bind, pressed )
		if gspeak:PlayerBindPress( ply, bind, pressed ) then return true end
		return original_bind( _, ply, bind, pressed )
	end
end)

--in development!
local dead_dist = 150
local dead_angl = Angle(0,22.5,0)
local dead_circle = {}
local dead_vec = Vector(dead_dist, 0, 0)
local dead_slot = 1
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*8)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*4)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*8)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*2)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*8)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*4)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*8)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*8)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*4)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*8)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*2)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*8)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*4)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))
dead_vec:Rotate(dead_angl*8)
table.insert(dead_circle, Vector(dead_vec.x, dead_vec.y, dead_vec.z))

hook.Add( "RenderScreenspaceEffects", "gspeak_icon", function()
	local eye = EyeAngles()
	local ang = Angle (eye.p, eye.y, eye.r)
	local offset = Vector(0, 0, 80)
	ang:RotateAroundAxis(ang:Forward(), -90)
	ang:RotateAroundAxis(ang:Right(), 90)
	ang:RotateAroundAxis(ang:Up(), 180)
	cam.Start3D(EyePos(), eye)
	local client_alive = gspeak:player_alive(LocalPlayer())

	for k, ply in pairs(gspeak.cl.players) do
		if !gspeak:player_valid( ply ) or ply == LocalPlayer() then
			continue
		end
		local ply_pos = ply:GetPos()
		local ply_alive = gspeak:player_alive(ply)
		if gspeak.viewranges and ply_alive then
			local pos = ply_pos + gspeak:get_offset(ply)
			for i = 1, #gspeak.settings.distances.modes, 1 do
				local power = i % 3
				local col = Color(power==0 and 255 or 0, power==1 and 255 or 0, power==2 and 255 or 0)
				gspeak:draw_range(pos, gspeak.settings.distances.modes[i].range, gspeak.settings.distances.heightclamp, col)
			end
			gspeak:draw_range(pos, gspeak.settings.distances.iconview, 0, gspeak.cl.color.white)
		end

		//Thendon you need to clean this mess
		if ( LocalPlayer():GetPos():Distance(ply_pos) < tonumber(gspeak.settings.distances.iconview) and ply_alive ) or ( !client_alive and !ply_alive and gspeak.settings.dead_chat and !gspeak.cl.dead_muted) then
			if !client_alive and !ply_alive then
				local slot = ply.dead_slot or 1
				ply_pos = gspeak.clientPos + dead_circle[slot]
			end
			local talkmode = gspeak:get_talkmode( ply )
			local ts_id = gspeak:get_tsid( ply )
			if ply.talking or ts_id < 0 or ply.failed then
				local pos = ply_pos + offset
				local pos_y = -15
				if gspeak.settings.head_icon then
					if !gspeak.settings.head_name and (client_alive or ply_alive or !gspeak.settings.dead_chat) then
						pos_y = -8
					end
					local size = 16
					local pos_x = -size * 0.5
					cam.Start3D2D(pos, ang, 1)
						surface.SetDrawColor( gspeak.cl.color.white )
						if ply.failed then
							surface.SetMaterial( gspeak.cl.materials.off )
							surface.DrawTexturedRect( pos_x, pos_y, size, size )
						elseif ts_id < 0 then --loading
							gspeak:DrawLoading(pos_x, pos_y+7, 4, 4, gspeak.cl.color.white)
						else
							local _, _, mat, _ = gspeak:get_talkmode_details(talkmode) //Thendon this sucks
							surface.SetMaterial( mat or gspeak.cl.materials.default_icon )
							surface.DrawTexturedRect( pos_x, pos_y, size, size )
						end
					cam.End3D2D()
				end
				if gspeak.settings.head_name or !client_alive and !ply_alive and gspeak.settings.dead_chat then
					local ply_name = gspeak:GetName( ply )
					if !gspeak.settings.head_icon and ts_id < 0 then
						if ply.failed then
							ply_name = "(error)"
						elseif ts_id < 0 then
							ply_name = "(connecting)"
						end
					end
					cam.Start3D2D(pos, ang, 0.1)
						draw.DrawText( ply_name, "TnfBig", 0, pos_y, team.GetColor( ply:Team() ), TEXT_ALIGN_CENTER )
					cam.End3D2D()
				end
			end
		end
	end

	if gspeak.rangeEditing then
		render.SetColorMaterial()
	end
	cam.End3D()
end)

hook.Add( "HUDPaint", "gspeak_hud", function()
	gspeak:DrawStatus()
	if gspeak.cl.tmm.actice then gspeak:DrawTalkMenu() end
	gspeak:DrawHUD()
end)

hook.Add( "OnPlayerChat", "gspeak_cmd_hook", function( ply, text )
	if ply == LocalPlayer() and text == gspeak.settings.cmd then
		LocalPlayer():ConCommand( "gspeak" )
		return true
	end
end)

hook.Add("Think", "Gspeak", function()
	gspeak:UpdateLoading()
	gspeak.clientPos = LocalPlayer():GetPos() + gspeak:get_offset(LocalPlayer())
	if gspeak.cl.failed then return end

	local now = CurTime()
	gspeak.chill = gspeak.chill or now + 10
	if !gspeak.cl.running then
		if gspeak.chill > now then return end
		gspeak:request_init()
		gspeak.chill = now + 10
		return
	end

	gspeak:checkConnection()
	gspeak.cl.TS.inChannel = tslib.getInChannel()
	if !gspeak.cl.TS.connected then return end

	local ts_id = tslib.getTsID()
	if ts_id != LocalPlayer().ts_id and gspeak.chill < now then
		gspeak:set_tsid( ts_id )
		gspeak.chill = now + 10
	end

	if !gspeak.cl.TS.inChannel then return end
	gspeak.hearable = tslib.getAllID()
	--Add player entitys to C++ Struct of hearable Players
	local client_alive = gspeak:player_alive(LocalPlayer())

	if gspeak.chill < now then
		gspeak:UpdatePlayers()
		gspeak.chill = now + 10
	end

	for k, v in pairs(gspeak.cl.players) do
		if !IsValid(v) then
			table.remove(gspeak.cl.players, k)
			continue
		end
		local v_index = v:EntIndex()
		if v == LocalPlayer() then
			local playerFor = v:GetForward()
			local playerUp = v:GetUp()
			tslib.sendClientPos(playerFor.x, playerFor.y, playerFor.z, playerUp.x, playerUp.y, playerUp.z)
		else
			local ts_id_v = gspeak:get_tsid(v)
			local v_alive = gspeak:player_alive(v)
			if v.alive != v_alive then
				v.alive = v_alive
				if !v_alive then
					v.dead_slot = dead_slot
					dead_slot = dead_slot + 1
					if dead_slot > 16 then
						dead_slot = 1
					end
				end
			end
			if ts_id_v == -1 then continue end
			local talkmode = gspeak:get_talkmode( v )

			local distance, distance_max, playerPos
			if gspeak.settings.dead_chat and !client_alive and !v_alive and !gspeak.cl.dead_muted then
				distance = 100
				distance_max = 1000
				playerPos = dead_circle[v.dead_slot]
			elseif ( client_alive or gspeak.settings.dead_alive ) and v_alive then
				distance, distance_max, playerPos = gspeak:get_distances(v, talkmode)
			else
				continue
			end

			if distance < distance_max then
				tslib.sendPos(ts_id_v, gspeak:calcVolume( distance, distance_max ), v_index, playerPos.x, playerPos.y, playerPos.z, false)
			end
		end
	end
	--Check C++ Struct if hearable player must be removed
	for k, v in pairs(gspeak.hearable) do
		local v_ent = Entity(v.ent_id)
		if v_ent then
			if v.radio then
				local v_radio_ent = Entity(v.radio_id)
				if v_radio_ent and IsValid(v_radio_ent) and v_ent:IsRadio() and v_radio_ent:IsRadio() then
					if !client_alive and !gspeak.settings.dead_alive then
						tslib.delPos(v.ent_id, true, v.radio_id)
					else
						local distance, distance_max = gspeak:get_distances(v_radio_ent, 1)
						if distance > distance_max then
							tslib.delPos(v.ent_id, true, v.radio_id)
						end
					end
				else
					tslib.delPos(v.ent_id, true, v.radio_id)
				end
			elseif v_ent:IsPlayer() then
				v_ent.volume = v.volume

				//THendon ich glaube du wolltest dir die infos direkt aus dem ts ziehn, aber irgenwie ist die variable für was anderes.
        --if v_ent.talking != v.talking then v_ent.talking = v.talking end

				if gspeak:get_tsid(v_ent) == -1 then
					tslib.delPos(v.ent_id, false)
				elseif gspeak:player_alive(Entity(v.ent_id)) then
					if ( !client_alive and !gspeak.settings.dead_alive ) then
						tslib.delPos(v.ent_id, false)
					else
						local distance, distance_max = gspeak:get_distances(v_ent, gspeak:get_talkmode( v_ent ))
						if distance > distance_max then
							tslib.delPos(v.ent_id, false)
						end
					end
				else
					if !gspeak.settings.dead_chat or client_alive or gspeak.cl.dead_muted then
						tslib.delPos(v.ent_id, false)
					end
				end
			else
				tslib.delPos(v.ent_id, false)
			end
		else
			if v.radio then
				tslib.delPos(v.ent_id, true, v.radio_id)
			else
				tslib.delPos(v.ent_id, false)
			end
		end
	end

	//Thendon call those stuff from cpp
	local check = tslib.talkCheck()
	if check and !gspeak.cl.start_talking then
		gspeak:ts_talking( true )
	elseif !check and gspeak.cl.start_talking then
		gspeak:ts_talking( false )
	end

	gspeak:TalkmenuUpdate()
end)

function gspeak:TalkmenuUpdate()
	if input.IsKeyDown( gspeak.cl.settings.key ) and !gspeak.cl.tmm.actice then
		gui.EnableScreenClicker(true)
		gspeak.cl.tmm.actice = true
	end
	if !input.IsKeyDown( gspeak.cl.settings.key ) and gspeak.cl.tmm.actice then
		gui.EnableScreenClicker(false)
		gspeak.cl.tmm.actice = false
		if gspeak.cl.tmm.selected != gspeak.cl.settings.talkmode then	gspeak:change_talkmode( gspeak.cl.tmm.selected ) end
	end
end
