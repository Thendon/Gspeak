AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.Author = "Thendon.exe"
ENT.Category = "Gspeak"
ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Radio = true

function ENT:Initialize()
	self:DrawShadow( false )
	self.connected_radios = {}
	self.last_sound = 0
	self.trigger_com = false
	self.settings = { trigger_at_talk = false, start_com = gspeak.settings.radio_start, end_com = gspeak.settings.radio_stop }
	if CLIENT then
		gspeak:NoDoubleEntry( self, gspeak.cl.radios )
		net.Start("radio_init")
			net.WriteEntity( self )
			net.WriteEntity( LocalPlayer() )
		net.SendToServer()
	end
end

function ENT:SendSettings(ply)
	net.Start("radio_send_settings")
		net.WriteEntity( self )
		net.WriteTable( self.settings )
	net.Send( ply )
end

function ENT:Draw()
	if (self.Owner == LocalPlayer() and !LocalPlayer():ShouldDrawLocalPlayer()) or !self:GetParent().draw_model then return end

	self:DrawModel()

	local vm_pos = self:GetPos()
	local ang = self:GetAngles()
	local x = 0
	local y = 0

	if gspeak.viewranges then gspeak:draw_range(vm_pos, gspeak.settings.distances.radio, gspeak.settings.distances.heightclamp, gspeak.cl.color.blue) end

	local offset = ang:Forward() * 0.87 + ang:Right() * 1.46 + ang:Up() * (-3)
	local white = Color(255,255,255,255)
	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), -90)
	ang:RotateAroundAxis(ang:Up(), 0)

	if LocalPlayer():GetPos():Distance(vm_pos) > 300 then return end

	cam.Start3D2D(vm_pos+offset, ang, 0.02)
		local alpha = 255
		if !self.online then alpha = 100 end
		surface.SetDrawColor(alpha,alpha,alpha,255)
		surface.SetMaterial(gspeak.cl.materials.radio_back)
		surface.DrawTexturedRect(x-15,y-37,170,170)

		if self.online then
			draw.DrawText( "Frequency", "BudgetLabel", x, y, white, TEXT_ALIGN_LEFT )
			draw.DrawText( tostring(self.freq/10), "BudgetLabel", x+140, y, white, TEXT_ALIGN_RIGHT )
			y = y + 7
			if self:GetHearable() then
				draw.DrawText( "--------------------", "BudgetLabel", x, y, white, TEXT_ALIGN_LEFT)
				y = y + 7
				for k, v in next, self.connected_radios do
					if k == 7 then break end
					if gspeak:radio_valid(Entity(v)) then
						local speaker = Entity(v):GetSpeaker()
						if gspeak:player_valid(speaker) then
							draw.DrawText( string.sub(gspeak:GetName( speaker ),1,14), "BudgetLabel", x, y, white, TEXT_ALIGN_LEFT )
							local status = "idl"
							if speaker.talking then status = "inc" end
							draw.DrawText( "| "..status, "BudgetLabel", x+140, y, white, TEXT_ALIGN_RIGHT )
							y = y + 10
						end
					end
				end
			end
		end
	cam.End3D2D()
end

function ENT:UpdateUI()
	if !IsValid(self:GetParent()) then return end
	self:GetParent().connected_radios = self.connected_radios
end

function ENT:Think()
	local own_online = self:GetOnline()
	local own_sending = self:GetSending()
	local parent = self:GetParent()

	self.range = self:GetRange()
	self:CheckTalking()

	if IsValid(self.Owner) then
		if CLIENT then
			if gspeak.cl.running and gspeak.settings.radio.use_key and LocalPlayer() == self.Owner then //Thendon may remove clrunning
				if !LocalPlayer():IsTyping() and input.IsKeyDown( gspeak.cl.settings.radio_key ) and own_online then
					if !own_sending and self:checkTime(0.1) then
						net.Start("radio_sending_change")
							net.WriteEntity( self )
							net.WriteBool( true )
						net.SendToServer()
					end
				elseif own_sending and self:checkTime(0.1) then
					net.Start("radio_sending_change")
						net.WriteEntity( self )
						net.WriteBool( false )
					net.SendToServer()
				end
			end

			if parent.animate and gspeak:player_valid(self.Owner) and own_sending and !self.Owner.ChatGesture then
				if self.Owner.ChatStation then self.Owner.ChatStation = false end
				self.Owner.ChatGesture = true
			end

			local Size = Vector(1,1,1)
			local mat = Matrix()
			mat:Scale(Size)
			self:EnableMatrix('RenderMultiply', mat)
		end

		local attachment, MAngle, MPos
		if parent.deployed == true then
			attachment = self.Owner:LookupBone("ValveBiped.Bip01_R_Hand")

			MAngle = Angle(170, 150, 30)
			MPos = Vector(5, 2, -2.597)
		else
			attachment = self.Owner:LookupBone("ValveBiped.Bip01_Pelvis")

			MAngle = Angle(-90, 0, 10)
			MPos = Vector(8, 0, 0)
		end

		if attachment then
			local pos, ang = self.Owner:GetBonePosition(attachment)
			pos = pos + (ang:Forward() * MPos.x) + (ang:Up() * MPos.z) + (ang:Right() * MPos.y)
			ang:RotateAroundAxis(ang:Forward(), MAngle.p)
			ang:RotateAroundAxis(ang:Up(), MAngle.y)
			ang:RotateAroundAxis(ang:Right(), MAngle.r)

			self:SetPos(pos)
			self:SetAngles(ang)
		end
	else
		if IsValid(parent) then
			self:SetPos(parent:GetPos())
			self:SetAngles(parent:GetAngles())
		end
	end

	if CLIENT then
		if #self.connected_radios > 0 then
			if IsValid(self.Owner) and self.Owner == LocalPlayer() then
				self:AddHearables(LocalPlayer():GetForward(), 1)
			elseif gspeak.settings.radio.hearable then
				local distance, distance_max, radio_pos = gspeak:get_distances(self, 1)

				if distance < distance_max and ( gspeak:player_alive(LocalPlayer()) or gspeak.settings.dead_alive ) then
					self:AddHearables(radio_pos, gspeak:calcVolume( distance, distance_max ))
				end
			end
		end

		local own_freq = self:GetFreq()
		if !self.last_freq or self.last_freq != own_freq or self.last_online != own_online  or self.last_sending != own_sending then
			self:Rescan(own_freq, own_online, own_sending)
		end
		self.last_sending = own_sending
		self.last_freq = own_freq
		self.last_online = own_online
	end
end

include("gspeak/sh_def_ent.lua")
