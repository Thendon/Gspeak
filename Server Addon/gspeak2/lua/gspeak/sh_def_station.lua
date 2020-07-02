AddCSLuaFile()

function ENT:Use( activator, caller, useType, value )
	self.last_use = CurTime()
	if !self.sending then
		self:SetSpeaker( activator )
		self:SetSending( true )
		self.sending = true
	end
end

function ENT:OnButton(btn)
	if btn.x < self.curser.x and btn.x + btn.width > self.curser.x and btn.y < self.curser.y and btn.y + btn.height > self.curser.y then
		surface.DrawRect( btn.x, btn.y, btn.width, btn.height )
		return true
	end
	return false
end

function ENT:Page(forward)
	local page
	if forward then
		if self.menu.page == self.menu.pages then
			page = 1
		else
			page = self.menu.page + 1
		end
	else
		if self.menu.page == 1 then
			page = self.menu.pages
		else
			page = self.menu.page - 1
		end
	end

	net.Start("radio_page_req")
		net.WriteEntity(self)
		net.WriteInt(page, 3)
	net.SendToServer()
	self.menu.page = page
end

function ENT:Freq(forward, steps)
	if forward then
		if self.freq >= self.freq_min + steps then
			self.freq = self.freq - steps
		end
	else
		if self.freq <= self.freq_max - steps then
			self.freq = self.freq + steps
		end
	end
	net.Start("radio_freq_change")
		net.WriteEntity( self )
		net.WriteBool( false ) --SWEP true ENT false
		net.WriteInt( self.freq , 32 )
	net.SendToServer()
end

function ENT:Draw()
	self:DrawModel()

	local Pos = self:GetPos()

	if gspeak.viewranges then gspeak:draw_range(Pos, gspeak.settings.distances.radio, gspeak.settings.distances.heightclamp, gspeak.cl.color.blue) end

	if LocalPlayer():GetPos():Distance(Pos) > 300 then return end
	local Ang = self:GetAngles()
	local Scale = 0.1

	Ang:RotateAroundAxis( Ang:Up(), 90 )
	Ang:RotateAroundAxis( Ang:Forward(), 90 )
	local OffSet = Pos + Ang:Forward() * (-17.3) + Ang:Up() * 15.3 + Ang:Right() * (-3.2)

	self.curser = self.curser or { x = 0, y = 0 }

	cam.Start3D2D( OffSet, Ang, Scale )
		surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
		--Initialize Player EyeTrace and prv, nxt buttons
		local trace = LocalPlayer():GetEyeTrace()
		if trace.Entity == self then
			local localVect = self:WorldToLocal( trace.HitPos ) * (1/Scale)
			localVect = localVect - Vector(0,-171,31)
			if localVect.y > (-8.3) and localVect.y < 93 and localVect.z > (-64) and localVect.z < 5 then
				self.curser.x = localVect.y
				self.curser.y = localVect.z*(-1)
				surface.DrawRect(self.curser.x,self.curser.y,2,2)
				local prv = { x = 0, y = 50, width = 45, height = 10 }
				local nxt = { x = 45, y = 50, width = 45, height = 10 }
				if self:OnButton(nxt) and LocalPlayer():KeyDown(IN_USE) and self:checkTime(0.2) then
					self:Page(true)
				end
				if self:OnButton(prv) and LocalPlayer():KeyDown(IN_USE) and self:checkTime(0.2) then
					self:Page(false)
				end
			end
		end
		draw.DrawText("PRV","BudgetLabel", 0, 50, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
		draw.DrawText("NXT","BudgetLabel", 90, 50, Color( 255, 255, 255, 255 ), TEXT_ALIGN_RIGHT )
		--Menu Pages
		local y = 0
		local x = 0
		if self.menu.page == 1 then
			draw.DrawText("RECEIVING :","BudgetLabel", x, y, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
			for k, v in pairs(self.connected_radios) do
				if k == 4 then break end
				y = y + 10
				draw.DrawText( string.sub(gspeak:GetName( Entity(v):GetSpeaker() ), 1, 13), "BudgetLabel", 0, y, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
			end
		elseif self.menu.page == 2 then
			draw.DrawText("FREQUENCY :","BudgetLabel", x, y, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
			y = y + 20
			local downk = { x = x, y = y, width = 10, height = 10 }
			x = x + 10
			local down = { x = x, y = y, width = 10, height = 10 }
			x = x + 30
			draw.DrawText(self.freq/10,"BudgetLabel", x, y, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
			x = x + 30
			local up = { x = x, y = y, width = 10, height = 10 }
			x = x + 10
			local upk = { x = x, y = y, width = 10, height = 10 }
			if !self.locked_freq then
				if self:OnButton(downk) and LocalPlayer():KeyDown(IN_USE) and self:checkTime(0.2) then
					self:Freq(true, 10)
				end
				if self:OnButton(down) and LocalPlayer():KeyDown(IN_USE) and self:checkTime(0.2) then
					self:Freq(true, 1)
				end
				if self:OnButton(up) and LocalPlayer():KeyDown(IN_USE) and self:checkTime(0.2) then
					self:Freq(false, 1)
				end
				if self:OnButton(upk) and LocalPlayer():KeyDown(IN_USE) and self:checkTime(0.2) then
					self:Freq(false, 10)
				end
			end
			if !self.locked_freq then
				draw.DrawText("-","BudgetLabel", down.x+1, down.y, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
				draw.DrawText("+","BudgetLabel", up.x+1, up.y-2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
				draw.DrawText("-","BudgetLabel", downk.x+1, downk.y, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
				draw.DrawText("+","BudgetLabel", upk.x+1, upk.y-2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
			end
		elseif self.menu.page == 3 then
			draw.DrawText("ONLINE    :","BudgetLabel", x, y, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
			y = y + 20
			x = x + 40
			local on = { x = x-25, y = y+2, width = 50, height = 10 }
			if self:OnButton(on) and LocalPlayer():KeyDown(IN_USE) and self:checkTime(0.2) then
				net.Start("radio_online_change")
					net.WriteEntity(self)
					net.WriteBool(self.online)
				net.SendToServer()
			end
			if self.online then
				draw.DrawText("online","BudgetLabel", x, y, Color( 0, 255, 0, 255 ), TEXT_ALIGN_CENTER )
			else
				draw.DrawText("offline","BudgetLabel", x, y, Color( 255, 0, 0, 255 ), TEXT_ALIGN_CENTER )
			end
		end
	cam.End3D2D()
end

function ENT:UpdateUI()
	return
end

function ENT:Think()
	if SERVER then
		if self.sending and self.last_use != 0 and self.last_use < CurTime() - 0.1 then
			self:SetSending( false )
			self.sending = false
		end
	else
		local own_sending = self:GetSending()
		local own_online = self:GetOnline()
		local own_freq = self:GetFreq()
		local own_speaker = self:GetSpeaker()
		if !self.last_freq or self.last_freq != own_freq or self.last_online != own_online or self.last_sending != own_sending then
			self:Rescan(own_freq, own_online, own_sending)
		end
		self.last_sending = own_sending
		self.last_freq = own_freq
		self.last_online = own_online

		if gspeak:player_valid(own_speaker) and own_sending and !own_speaker.ChatGesture then
			if !own_speaker.ChatStation then own_speaker.ChatStation = true end
			own_speaker.ChatGesture = true
		end
		local distance, distance_max, radio_pos = gspeak:get_distances(self, 1)
		if distance < distance_max and ( gspeak:player_alive(LocalPlayer()) or gspeak.settings.dead_alive ) then
			self:AddHearables(radio_pos, gspeak:calcVolume( distance, distance_max ))
		end
	end
end

include("gspeak/sh_def_ent.lua")
