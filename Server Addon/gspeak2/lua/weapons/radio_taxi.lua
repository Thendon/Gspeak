AddCSLuaFile()
include( "gspeak/sh_def_swep.lua" )

SWEP.Spawnable = true
SWEP.PrintName = "Taxi Radio"
SWEP.Slot = 1
SWEP.SlotPos = 2
if CLIENT then
	SWEP.WepSelectIcon = surface.GetTextureID("VGUI/HUD/radio_taxi")
end

function SWEP:Initialize()
	//Own Changeable Variables
	self.online = true --Online when picked up (default = true)
	self.show_hearable = false --Show the list of connected Radio in HUD (default = true)
	self.freq = 275 --Default freqeunz (devide 10 || default = 900)
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
