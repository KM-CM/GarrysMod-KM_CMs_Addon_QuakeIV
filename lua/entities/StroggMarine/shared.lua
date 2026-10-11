AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

sound.Add {
	name = "StroggMarineDeath",
	channel = CHAN_AUTO,
	level = 80,
	sound = {
		"Strogg/Marine/Die1.wav",
		"Strogg/Marine/Die2.wav",
		"Strogg/Marine/Die3.wav",
		"Strogg/Marine/Die4.wav",
		"Strogg/Marine/Die5.wav"
	}
}

if SERVER then include "Server.lua" end

scripted_ents.Register( ENT, "StroggMarine" )
