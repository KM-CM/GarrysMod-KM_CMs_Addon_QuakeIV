AddCSLuaFile()
DEFINE_BASECLASS "StroggMarine"

list.Set( "NPC", "StroggMarineBlaster", {
	Name = "#StroggMarineBlaster",
	Class = "StroggMarineBlaster",
	Category = "#Strogg"
} )

sound.Add {
	name = "StroggMarineBlasterFire",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = {
		"^Strogg/Marine/BlasterFire1.wav",
		"^Strogg/Marine/BlasterFire2.wav"
	}
}

ENT.Primary_flDelay = .16
ENT.Primary_flSpreadX = .05
ENT.Primary_flSpreadY = .05

function ENT:GetShootPos() return self:GetBonePosition( self:LookupBone "muzzle" ) end

function ENT:PlantedFireWeapon( MyTable )
	self:EmitSound "StroggMarineBlasterFire"

	local pProjectile = MyTable.CreateProjectile( self, "StroggPlasmaBolt" )
	pProjectile:SetPos( self:GetShootPos() )
	local dDirection = MyTable.GetAimVector( self )
	local flX = math.Rand( -.5, .5 ) + math.Rand( -.5, .5 )
	local flY = math.Rand( -.5, .5 ) + math.Rand( -.5, .5 )
	local aAim = dDirection:Angle()
	local v = aAim:Forward() + flX * MyTable.Primary_flSpreadX * aAim:Right() + flY * MyTable.Primary_flSpreadY * aAim:Up()
	pProjectile:SetAngles( v:Angle() )

	pProjectile:Spawn()
	pProjectile:Activate()

	local pPhysics = pProjectile:GetPhysicsObject()
	if IsValid( pPhysics ) then pPhysics:SetVelocity( v * pProjectile.ROCKET_flSpeed ) end

	// TODO: Muzzleflash
	local flMuzzleFlashTime = math.Clamp( MyTable.Primary_flDelay * math.Rand( .5, 1 ), 0, .2 )
	net.Start "EphemeralLight"
		local tColor = MyTable.tBulletLightColor
		net.WriteFloat( 2048 / 255 * .2 * ViolentAssRandomInternal() ) // Brightness
		net.WriteFloat( 512 * ViolentAssRandomInternal() ) // Size
		local f = flMuzzleFlashTime * ViolentAssRandomInternal()
		net.WriteFloat( f ) // Existence length
		net.WriteFloat( f ) // Fade time
		net.WriteVector( pProjectile:GetPos() ) // Position
		net.WriteUInt( 255, 8 ) net.WriteUInt( 154, 8 ) net.WriteUInt( 154, 8 ) // R, G, B
	net.Broadcast()
end

function ENT:Initialize()
	self:SetModel "models/meercat/quake4/strogg/stroggs/strogg_bl_blstr.mdl"
	BaseClass.Initialize( self )
end

scripted_ents.Register( ENT, "StroggMarineBlaster" )
