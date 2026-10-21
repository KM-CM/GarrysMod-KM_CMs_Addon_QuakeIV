DEFINE_BASECLASS "BaseBulletWeapon"

SWEP.Category = "Shotguns"
SWEP.PrintName = "#SpaceMarineCorpsShotgunMag"
SWEP.Purpose = "Manufactured by the Space Marine Corps."

SWEP.ViewModel = "models/weapons/quake4/v_q4_shotgun.mdl"
SWEP.WorldModel = "models/weapons/quake4/w_q4_shotgun.mdl"

SWEP.Primary.ClipSize = 10
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Buckshot"
SWEP.Primary_iNum = 8
SWEP.Primary_flSpreadX = .028
SWEP.Primary_flSpreadY = .028
SWEP.Primary_flDelay = .7
SWEP.Primary_flDamage = 28
SWEP.Spawnable = true
SWEP.Weight = 1
SWEP.Slot = 3
SWEP.flRecoil = 6.8
SWEP.sAimSound = "BaseWeapon_Aim_Rifle"
SWEP.sHoldType = "AR2"
SWEP.sHoldTypeShoot = "Shotgun"
SWEP.m_bAimShootDoesntBlockNormalShoot = true

sound.Add {
	name = "SpaceMarineCorpsShotgunReload",
	channel = CHAN_ITEM,
	level = 60,
	sound = "SpaceMarineCorps/Shotgun/Reload.wav"
}

sound.Add {
	name = "SpaceMarineCorpsShotgunInsert",
	channel = CHAN_ITEM,
	level = 60,
	sound = "SpaceMarineCorps/Shotgun/Insert.wav"
}

sound.Add {
	name = "SpaceMarineCorpsShotgunPump",
	channel = CHAN_ITEM,
	level = 60,
	sound = "SpaceMarineCorps/Shotgun/Pump.wav"
}

sound.Add {
	name = "SpaceMarineCorpsShotgunShot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^SpaceMarineCorps/Shotgun/Fire.wav"
}
SWEP.sSound = "SpaceMarineCorpsShotgunShot"

local IsValid = IsValid

function SWEP:Deploy()
	local pOwner = self:GetOwner()

	local pViewModel = pOwner.GetViewModel
	if pViewModel then
		pViewModel = pViewModel( pOwner )
		if IsValid( pViewModel ) then pViewModel:SetBodygroup( 2, 1 ) end
	end

	if IsValid( pOwner ) && pOwner:IsPlayer() then self:CallOnClient "PumpSoundInternal" end

	return BaseClass.Deploy( self )
end

function SWEP:PostShootEffects()
	local pOwner = self:GetOwner()
	timer.Simple( .4, function()
		if IsValid( self ) && IsValid( pOwner ) && self:GetOwner() == pOwner && pOwner:IsPlayer() then
			self:CallOnClient "PumpSoundInternal"
		end
	end )
end

function SWEP:ReloadEffects()
	local pOwner = self:GetOwner()
	if IsValid( pOwner ) && pOwner:IsPlayer() then self:CallOnClient "ReloadSoundInternal" end
end

if SERVER then return end

SWEP.bDontDrawAmmoBars = true

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

	local iClip, iMax = self:Clip1(), self:GetMaxClip1()

	if iClip <= iMax * .2 then
		pViewModel:SetSubMaterial( 3, "models/weapons/quake4/shotgun/shotgungui2.vmt" )
	elseif iClip <= iMax * .4 then
		pViewModel:SetSubMaterial( 3, "models/weapons/quake4/shotgun/shotgungui3.vmt" )
	else
		pViewModel:SetSubMaterial( 3, nil )
	end

	local sClip = tostring( iClip )

	local vDraw = vPos + aAng:Forward() * ( .13 + ( #sClip - 1 ) * .16 ) + aAng:Right() * -1.93 + aAng:Up() * -3.5

	aAng:RotateAroundAxis( aAng:Up(), 0 )
	aAng:RotateAroundAxis( aAng:Right(), 180 )
	aAng:RotateAroundAxis( aAng:Forward(), -10 )

	cam_Start3D2D( vDraw, aAng, .012 )
		draw_DrawText( sClip, "doom3ammodisp", 0, 0, COLOR, TEXT_ALIGN_LEFT )
	cam_End3D2D()
end

function SWEP:PumpSoundInternal() self:EmitSound "SpaceMarineCorpsShotgunPump" end
function SWEP:ReloadSoundInternal() self:EmitSound "SpaceMarineCorpsShotgunReload" end
function SWEP:InsertSoundInternal() self:EmitSound "SpaceMarineCorpsShotgunInsert" end

local math_abs = math.abs
local math_sin = math.sin
local RealTime = RealTime
VIEWMODEL_CAMERA_ANIMATIONS[ "models/weapons/quake4/v_q4_shotgun.mdl" ] = {
	fire = function( pViewModel, vTarget, vTargetAngle )
		local flCycle = pViewModel:GetCycle()
		if flCycle > .4 then
			if flCycle < .7 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
			elseif flCycle < .8 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] - 1
			elseif flCycle < .9 then
				vTargetAngle[ 1 ] = vTargetAngle[ 1 ] + 2
			end
			if flCycle < .7 then
				vTargetAngle[ 3 ] = vTargetAngle[ 3 ] + math_sin( RealTime() * 8 ) * 2
			end
		end
	end
}
