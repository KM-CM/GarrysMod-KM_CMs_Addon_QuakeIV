AddCSLuaFile()
DEFINE_BASECLASS "StroggMarine"

list.Set( "NPC", "StroggMarineMachineGun", {
	Name = "#StroggMarineMachineGun",
	Class = "StroggMarineMachineGun",
	Category = "#Strogg"
} )

sound.Add {
	name = "StroggMarineMachineGunFire",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 95, 105 },
	sound = "^Strogg/Marine/MachineGunFire.wav"
}

ENT.Primary_flDelay = .09
ENT.Primary_flSpreadX = .05
ENT.Primary_flSpreadY = .05

function ENT:OverrideTracerOrigin() return self:GetShootPos() end
function ENT:GetMuzzleFlashPosition() return self:GetShootPos() + self:GetForward() * 24 end
function ENT:GetMuzzleFlashAngles() return self:GetAngles() end

function ENT:GetShootPos() return self:GetBonePosition( self:LookupBone "rElbo" ) end

function ENT:PlantedFireWeapon( MyTable )
	self:EmitSound "StroggMarineMachineGunFire"

	local vShoot = MyTable.GetShootPos( self )
	local dShoot = MyTable.GetAimVector( self )

	local pEffectData = EffectData()

	pEffectData:SetEntity( self )
	pEffectData:SetMaterialIndex( 0 )

	pEffectData:SetOrigin( vShoot )
	pEffectData:SetStart( vShoot )
	pEffectData:SetNormal( dShoot )
	pEffectData:SetAngles( dShoot:Angle() )
	pEffectData:SetMagnitude( 1 / ( MyTable.Primary_flDelay * math.Rand( .75, 1.25 ) ) )

	util.Effect( "MuzzleFlashGeneric", pEffectData )

	self:FireBullets {
		Attacker = self,
		Src = vShoot,
		Dir = dShoot,
		Spread = Vector( MyTable.Primary_flSpreadX, MyTable.Primary_flSpreadY ),
		Damage = 30,
		Force = 1
	}

	// TODO: Muzzleflash
	local flMuzzleFlashTime = math.Clamp( MyTable.Primary_flDelay * math.Rand( .5, 1 ), 0, .2 )
	net.Start "EphemeralLight"
		local tColor = MyTable.tBulletLightColor
		net.WriteFloat( 1024 / 255 * .2 * ViolentAssRandomInternal() ) // Brightness
		net.WriteFloat( 512 * ViolentAssRandomInternal() ) // Size
		local f = flMuzzleFlashTime * ViolentAssRandomInternal()
		net.WriteFloat( f ) // Existence length
		net.WriteFloat( f ) // Fade time
		net.WriteVector( vShoot ) // Position
		net.WriteUInt( 255, 8 ) net.WriteUInt( 48, 8 ) net.WriteUInt( 0, 8 ) // R, G, B
	net.Broadcast()
end

function ENT:Initialize()
	self:SetModel "models/meercat/quake4/strogg/stroggs/strogg_machinegun.mdl"
	BaseClass.Initialize( self )
end

scripted_ents.Register( ENT, "StroggMarineMachineGun" )
