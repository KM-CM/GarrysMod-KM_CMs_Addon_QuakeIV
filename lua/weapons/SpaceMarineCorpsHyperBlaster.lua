// TODO: Bounce version, muzzleflash

DEFINE_BASECLASS "BaseProjectileWeapon"

SWEP.Category = "#Category.AssaultRifles"
SWEP.PrintName = "#SpaceMarineCorpsHyperBlaster"
SWEP.Purpose = "Manufactured by the Space Marine Corps."

SWEP.ViewModel = "models/weapons/quake4/v_q4_hyperblaster.mdl"
SWEP.WorldModel = "models/weapons/quake4/w_q4_hyperblaster.mdl"

SWEP.Primary.ClipSize = 60
SWEP.Primary.DefaultClip = 60
SWEP.Primary.Automatic = true
SWEP.m_bAllowOneInTheChamber = false

SWEP.Primary.Ammo = "AR2"
SWEP.Primary_flDelay = .075
SWEP.Primary_sProjectile = "SpaceMarineCorpsHyperBlasterPlasmaBolt"

SWEP.Spawnable = true

SWEP.Slot = 2

SWEP.Crosshair = "Rifle"

SWEP.flRecoil = .45

SWEP.Primary_flSpreadX = .013
SWEP.Primary_flSpreadY = .013

SWEP.flViewModelFoV = 65

SWEP.flHipSwayStabilizer = .2

SWEP.flCoverX = 6
SWEP.flCoverY = -2
SWEP.flCoverZ = 8

SWEP.bBulletLight = true
SWEP.tBulletLightColor = { 0, 128, 255, 2048 }

function SWEP:GetProjectilePositionOwner( pOwner, MyTable ) return pOwner:GetShootPos() + pOwner:GetAimVector() * 16 end

function SWEP:LaunchProjectile( pProjectile, dDirection )
	pProjectile:Spawn()
	pProjectile:Activate()
	local pPhysics = pProjectile:GetPhysicsObject()
	if IsValid( pPhysics ) then pPhysics:SetVelocity( dDirection * pProjectile.ROCKET_flSpeed ) end
end

if CLIENT then
	local math_abs = math.abs
	local math_sin = math.sin
	local RealTime = RealTime

	VIEWMODEL_CAMERA_ANIMATIONS[ "models/weapons/quake4/v_q4_hyperblaster.mdl" ] = {
		raise = function( pViewModel, vTarget, vTargetAngle )
			local flCycle = pViewModel:GetCycle()

			if flCycle < .25 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - 2
			elseif flCycle > .6 && flCycle < .7 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
			end

			if flCycle < .8 then
				vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + math_sin( RealTime() * 8 )
			end
		end,

		reload = function( pViewModel, vTarget, vTargetAngle )
			local flCycle = pViewModel:GetCycle()

			if flCycle < .25 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
			elseif flCycle < .5 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - 1
			elseif flCycle > .5 && flCycle < .8 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
			end

			if flCycle > .64 && flCycle < .74 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
			end

			if flCycle < .66 then
				vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + math_abs( math_sin( RealTime() * 6 ) ) * 2
			end
		end
	}

	function SWEP:ReloadSoundInternal() self:EmitSound "SpaceMarineCorpsHyperBlasterReload" end

	SWEP.bDontDrawAmmoBars = true

	local IsValid = IsValid
	local LocalPlayer = LocalPlayer
	local Color = Color
	local TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT

	local COLOR  = Color( 10, 10, 10, 250 )

	local tostring = tostring

	local cam_Start3D2D = cam.Start3D2D
	local draw_DrawText = draw.DrawText
	local cam_End3D2D = cam.End3D2D

	function SWEP:ViewModelDrawn()
		local pOwner = self:GetOwner()
		if !IsValid( pOwner ) then return end
		
		local pViewModel = pOwner:GetViewModel()
		if !IsValid( pViewModel ) then return end

		local iBone = pViewModel:LookupBone "body"
		if !iBone then return end

		local vPos, aAng = pViewModel:GetBonePosition( iBone )

		local sClip = tostring( self:Clip1() )

		local vDraw = vPos + aAng:Forward() * ( .11 + ( #sClip - 1 ) * .105 ) + aAng:Right() * -2.55 + aAng:Up() * .77

		aAng:RotateAroundAxis( aAng:Up(), 180 )
		aAng:RotateAroundAxis( aAng:Forward(), 165 )
	
		cam_Start3D2D( vDraw, aAng, .01 )
			draw_DrawText( sClip, "doom3ammodisp", 0, 0, COLOR, TEXT_ALIGN_LEFT )
		cam_End3D2D()
	end

	SWEP.flLastPos = 0
	SWEP.flAttackDelay = 0
	function SWEP:Initialize()
		BaseClass.Initialize( self )
		self.vGunPos = Vector()
	end

	function SWEP:Think()
		BaseClass.Think( self )

		local pOwner = self:GetOwner()
		if !IsValid( pOwner ) then return end
		
		local pViewModel = pOwner:GetViewModel()
		if !IsValid( pViewModel ) then return end

		local iBarrels = pViewModel:LookupBone "ammo_can"
		local iGun = pViewModel:LookupBone "body"

		if !iBarrels || !iGun then return end

		local bFiring = CurTime() <= ( self.flLastShot + self.Primary_flDelay )

		local flDelay = self.flAttackDelay
		if bFiring then
			flDelay = math.Clamp( flDelay - 1 / self.Primary_flDelay * FrameTime(), -3, 0 )
		else
			flDelay = math.Clamp( flDelay * math.exp( -4 * FrameTime() ), -3, 0 )
		end
		self.flAttackDelay = flDelay

		local flLastPos = self.flLastPos
		local flAttack = flLastPos + flDelay
		self.flLastPos = Lerp( 1 - math.exp( -200 * FrameTime() ), flLastPos, flAttack )
		pViewModel:ManipulateBoneAngles( iBarrels, Angle( 0, -( flAttack * 2 ) % 360, 0 ) )
		
		if bFiring then
			local f = math.sin( CurTime() * 60 )
			self.vGunPos = Vector( -.25 * f, -.25 * f, 0 )
		else
			self.vGunPos = LerpVector( 1 - math.exp( -100 * FrameTime() ), self.vGunPos, Vector( 0, 0, 0 ) )
		end
	end
end

function SWEP:ReloadEffects()
	local pOwner = self:GetOwner()
	if IsValid( pOwner ) && pOwner:IsPlayer() then self:CallOnClient "ReloadSoundInternal" end
end

sound.Add {
	name = "SpaceMarineCorpsHyperBlasterShot",
	channel = CHAN_WEAPON,
	level = 150,
	sound = { "^SpaceMarineCorps/HyperBlaster/FireA.wav", "^SpaceMarineCorps/HyperBlaster/FireB.wav" }
}

SWEP.sSound = "SpaceMarineCorpsHyperBlasterShot"

sound.Add {
	name = "SpaceMarineCorpsHyperBlasterReload",
	channel = CHAN_ITEM,
	level = 60,
	sound = "SpaceMarineCorps/HyperBlaster/Reload.wav"
}

SWEP.sHoldType = "AR2"
