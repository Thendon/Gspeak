AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.Spawnable = true
ENT.PrintName = "Stational Radio"
ENT.Category = "Gspeak"
ENT.Author = "Thendon.exe & Kuro"
ENT.Instructions = "Hold E to talk"
ENT.Purpose = "Talk!"

function ENT:Initialize()
	//Own Changeable Variables
	self.online = true --Online when picked up (default = true)
	self.freq = 900 --Default freqeunz (devide 10 or default = 900)
	self.locked_freq = false --Should the frequency be locked? if true you don't have to put values into freq min and max
	self.freq_min = 800 --Min frequenz (default = 800)
	self.freq_max = 1200 --Max frequenz (default = 900)
	self.range = 150 --Default Range
	self.locked_range = true --Should the volume/range be locked? If true you don't have to put values into range min and max
	self.range_min = 100 --Min range (default = 100)
	self.range_max = 300 --Max range (default = 300)

	//Own Locked Variables
	self.last_use = 0
	self.sending = false
	self.connected_radios = {}
	self.settings = { trigger_at_talk = false, start_com = gspeak.settings.radio_start, end_com = gspeak.settings.radio_stop }
	//Thendon verwandeln in Seitennamen
	self.menu = {
		page = 1, pages = 3
	}
	self.Radio = true

	self:DrawShadow( true )

	self:SetModel( "models/gspeak/militaryradio.mdl" )
	self:UseClientSideAnimation(true)
	if SERVER then
		self:SetOnline( self.online )
		self:SetFreq( self.freq )
		self:SetUseType( CONTINUOUS_USE )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
			phys:SetMass(1)
		end
	end

	if CLIENT then
		gspeak:NoDoubleEntry( self, gspeak.cl.radios )
	end
end

include("gspeak/sh_def_station.lua")
