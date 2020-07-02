AddCSLuaFile()
include( "gspeak/sh_def_swep.lua" )

SWEP.Category = "Gspeak"
SWEP.Spawnable = false
SWEP.PrintName = "Detective Radio"

SWEP.Kind = WEAPON_EQUIP2
SWEP.AutoSpawnable = false
SWEP.CanBuy = { ROLE_DETECTIVE }
SWEP.InLoadoutFor = { ROLE_DETECTIVE }
SWEP.LimitedStock = false
SWEP.EquipMenuData = {
	type = "item_weapon",
	name = "Detective Radio",
	desc = "Talk!"
}
SWEP.Icon = "VGUI/ttt/radio_d"

function SWEP:IsEquipment()
	return WEPS.IsEquipment(self)
end

function SWEP:DampenDrop()
   local phys = self:GetPhysicsObject()
   if IsValid(phys) then
      phys:SetVelocityInstantaneous(Vector(0,0,-75) + phys:GetVelocity() * 0.001)
      phys:AddAngleVelocity(phys:GetAngleVelocity() * -0.99)
   end
end

function SWEP:Initialize()
	//Own Changeable Variables
	self.online = true --Online when picked up (default = true)
	self.show_hearable = true --Show the list of connected Radio in HUD (default = true)
	self.freq = 1201 --Default freqeunz (devide 10 || default = 900)
	self.locked_freq = true --Should the frequency be locked? if true you don't have to put values into freq min and max
	self.freq_min = 800 --Min frequenz (default = 800)
	self.freq_max = 1200 --Max frequenz (default = 900)
	self.draw_model = true --Should it draw the radio model or hide it
	self.animate = true --Should it animations be visible
	self.silent = false --Should it be hearable at all
	self.range = 150 --Default Range
	self.trigger_at_talk = gspeak.settings.radio.trigger_at_talk --Trigger soundeffect when player starts/stops talking. Replace gspeak.settings.radio.trigger_at_talk with true or false
	self.start_com = gspeak.settings.radio.start --Startcom soundeffect. To use custom sound replace gspeak.settings.radio.start with "sound_name" (WITHOUT file ending like ".mp3").
	self.end_com = gspeak.settings.radio.stop --Endcom soundeffect To use custom sound replace gspeak.settings.radio.start with "sound_name" (WITHOUT file ending like ".mp3").

	self:DefaultInitialize()
end
