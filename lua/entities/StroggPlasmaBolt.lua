// TODO: Impact effects

AddCSLuaFile()
DEFINE_BASECLASS "BaseProjectile"

scripted_ents.Register( ENT, "StroggPlasmaBolt" )

sound.Add {
	name = "StroggPlasmaBoltImpactCrack",
	channel = CHAN_STATIC,
	level = 70,
	pitch = { 140, 160 },
	volume = .5,
	sound = "npc/sniper/echo1.wav"
}

sound.Add {
	name = "StroggPlasmaBoltImpactHiss",
	channel = CHAN_STATIC,
	level = 60,
	pitch = { 140, 160 },
	volume = .5,
	sound = "npc/sniper/sniper1.wav"
}

local cOuterColor = Color( 255, 64, 64 )
local cInnerColor = Color( 255, 255, 255 )

if CLIENT then
	function ENT:Draw() end

	local pEntity = ENT

	timer.Simple( .1, function()
		local mMaterial = CreateMaterial( "q4_energy1_fixed", "UnlitGeneric", {
			["$vertexcolor"] = 1,
			["$vertexalpha"] = 1,
			["$additive"] = 1
		} )
	
		local mOriginal = Material "sprites/quake4/energy1"
		local pTexture = mOriginal:GetTexture "$basetexture"
		if pTexture then mMaterial:SetTexture( "$basetexture", pTexture ) end
	
		local render_SetMaterial = render.SetMaterial
		local render_DrawSprite = render.DrawSprite
	
		function pEntity:Draw()
			render_SetMaterial( mMaterial )

			// Ye, I know this formula is hard to follow, not sure why I wrote it this way, too lazy to rewrite
			for i = 0, 1, .1 do
				render_DrawSprite( self:GetPos() - self:GetForward() * ( 1 - i ) * 16, 24 * i, 24 * i, cOuterColor )
				for j = 1, 4 do render_DrawSprite( self:GetPos() - self:GetForward() * ( 1 - i ) * 16, 12 * i, 12 * i, cInnerColor ) end
			end
		end
	end )

	return
end

local SOLID_VPHYSICS = SOLID_VPHYSICS

local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_SetModel = CEntity.SetModel
local CEntity_PhysicsInit = CEntity.PhysicsInit
local CEntity_SetHealth = CEntity.SetHealth
local CEntity_SetMaxHealth = CEntity.SetMaxHealth

function ENT:Initialize()
	CEntity_SetModel( self, "models/weapons/w_missile_launch.mdl" )
	CEntity_PhysicsInit( self, SOLID_VPHYSICS )
	CEntity_SetHealth( self, 55 )
	CEntity_SetMaxHealth( self, 55 )
end

ENT.__PROJECTILE_IMPACT__ = true
ENT.IMPACT_flDamage = 55

ENT.__PROJECTILE_ROCKET__ = true
ENT.ROCKET_flSpeed = 2000

local CEntity_GetPhysicsObject = CEntity.GetPhysicsObject
local CEntity_GetForward = CEntity.GetForward
local CEntity_NextThink = CEntity.NextThink
local CurTime = CurTime

function ENT:Think()
	local pPhys = CEntity_GetPhysicsObject( self )
	if !IsValid( pPhys ) then return end
	pPhys:SetVelocity( CEntity_GetForward( self ) * CEntity_GetTable( self ).ROCKET_flSpeed )
	CEntity_NextThink( self, CurTime() )
	return true
end

local util_BlastDamage = util.BlastDamage
local CEntity_GetOwner = CEntity.GetOwner
local IsValid = IsValid
local ParticleEffect = ParticleEffect

local CEntity_GetPos = CEntity.GetPos
local CEntity_OBBCenter = CEntity.OBBCenter
local CEntity_EmitSound = CEntity.EmitSound
local CEntity_GetAngles = CEntity.GetAngles
local CEntity_EmitSound = CEntity.EmitSound
local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_Remove = CEntity.Remove
local util_Effect = util.Effect

function ENT:Detonate( MyTable, pEntity )
	MyTable = MyTable || CEntity_GetTable( self )
	if MyTable.bDetonated then return end

	local vPos = CEntity_GetPos( self )
	vPos:Add( CEntity_OBBCenter( self ) )

	local pOwner = CEntity_GetOwner( self )
	if !IsValid( pOwner ) then pOwner = self end

	self:EmitSound "StroggPlasmaBoltImpactCrack"
	self:EmitSound "StroggPlasmaBoltImpactHiss"

	if IsValid( pEntity ) then
		local pDamage = DamageInfo()
		pDamage:SetAttacker( pOwner )
		pDamage:SetDamage( self.IMPACT_flDamage )
		pDamage:SetDamageType( DMG_ENERGYBEAM )
		pDamage:SetDamagePosition( self:GetPos() )
		pEntity:TakeDamageInfo( pDamage )
	end

	MyTable.bDetonated = true

	CEntity_Remove( self )
end

function ENT:PhysicsCollide( tData )
	local MyTable = CEntity_GetTable( self )
	MyTable.Detonate( self, MyTable, tData.HitEntity )
end

local CEntity_Health = CEntity.Health

function ENT:OnTakeDamage( dDamage )
	local MyTable = CEntity_GetTable( self )
	if MyTable.bDead then return 0 end
	local f = CEntity_Health( self ) - dDamage:GetDamage()
	CEntity_SetHealth( self, f )
	if f <= 0 then MyTable.bDead = true MyTable.Detonate( self, MyTable ) return 0 end
end
