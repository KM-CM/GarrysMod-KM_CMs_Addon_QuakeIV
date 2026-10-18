// TODO: Flinching

DEFINE_BASECLASS "BaseActor"

if !CLASS_STROGG then Add_NPC_Class "CLASS_STROGG" end
ENT.m_iDefaultClass = CLASS_STROGG

ENT.vHullMins = Vector( -13, -13 )
ENT.vHullMaxs = Vector( 13, 13, 72 )
ENT.vHullDuckMins = ENT.vHullMins
ENT.vHullDuckMaxs = ENT.vHullMaxs

ENT.bCannotCarryWeapons = true

ENT.flVisionYaw = 60
ENT.flVisionPitch = 45

ENT.m_sIdleSequence = "idle_alert"

ENT.m_sPitchPoseParameter = "body_pitch"
ENT.m_sYawPoseParameter = "body_yaw"

ENT.flJumpHeight = 64

function ENT:OnCreateRagdoll( pRagdoll ) pRagdoll:EmitSound "StroggMarineDeath" end

ENT.bPlantToShootLike = true

function ENT:IsInPlantDelta( vTarget, MyTable )
	local aPose = ( vTarget - MyTable.GetShootPos( self ) ):Angle()
	local aBody = self:GetAngles()
	return math.abs( math.AngleDifference( aBody[ 1 ], aPose[ 1 ] ) ) <= 90 && math.abs( math.AngleDifference( aBody[ 2 ], aPose[ 2 ] ) ) <= 90
end

function ENT:PlantThread( pSchedule, MyTable )
	local sPlant, sShoot, sUnplant

	local i = math.random( 3 )
	if i == 1 then
		sPlant, sShoot, sUnplant = "fire1_start", "fire1_loop", "fire1_end"
	elseif i == 2 then
		sPlant, sShoot, sUnplant = "fire3_start", "fire3_loop", "fire3_end"
	elseif i == 3 then
		sPlant, sShoot, sUnplant = "fire4_start", "fire4_loop", "fire4_end"
	end

	local bNow = math.random( 2 ) == 1

	if !pSchedule.bAimOnly && bNow && math.random( 2 ) == 1 then MyTable.PrioritySentence( self, { sSound = "StroggMarineTaunt" }, MyTable ) end

	MyTable.AnimationSystemHalt( self, MyTable )
	MyTable.PlaySequenceAndWait( self, sPlant, math.Rand( .5, 1.5 ), true, function()
		MyTable.AnimationSystemHalt( self, MyTable )
	end )

	if !pSchedule.bAimOnly && !bNow && math.random( 2 ) == 1 then MyTable.PrioritySentence( self, { sSound = "StroggMarineTaunt" }, MyTable ) end

	while !pSchedule.bDone do
		pSchedule.bPlanted = true

		if pSchedule.bAimOnly then
			MyTable.PromoteSequenceInstant( self, sShoot, 0 )
			coroutine.yield()
			continue
		end

		// Maybe add firing ahead? In Quake IV, they don't, but it'd be quite lore accurate.
		// Also, not sure if we actually want to check if the target is in our weapon cone.
		// I think lore accurate Strogg Marines would fire all over the place.
		local pEntity = pSchedule.pTarget
		if IsValid( pEntity ) then
			MyTable.vaAimTargetPose = pEntity:GetPos() + pEntity:OBBCenter()
			MyTable.PlantedFireWeapon( self, MyTable )
		else
			MyTable.vaAimTargetPose = pSchedule.vTarget
			MyTable.PlantedFireWeapon( self, MyTable )
		end

		if MyTable.vaAimTargetPose then
			local aPose = ( MyTable.vaAimTargetPose - MyTable.GetShootPos( self ) ):Angle()
			aPose[ 1 ] = math.NormalizeAngle( aPose[ 1 ] )
			aPose[ 2 ] = math.NormalizeAngle( aPose[ 2 ] )
			MyTable.vaAimTargetPose = aPose
			local aBody = self:GetAngles()
			if math.abs( math.AngleDifference( aBody[ 1 ], aPose[ 1 ] ) ) >= 90 || math.abs( math.AngleDifference( aBody[ 2 ], aPose[ 2 ] ) ) >= 90 then
				pSchedule.sReturn = "DELTA"
				break
			end
		end

		MyTable.PlaySequenceAndWait( self, sShoot,
			( self:SequenceDuration( self:LookupSequence( sShoot ) ) / MyTable.Primary_flDelay ), true, function()
			MyTable.AnimationSystemHalt( self, MyTable )
		end )
		coroutine.yield()
	end

	MyTable.AnimationSystemHalt( self, MyTable )
	MyTable.PlaySequenceAndWait( self, sUnplant, math.Rand( .5, 1.5 ), nil, function()
		MyTable.AnimationSystemHalt( self, MyTable )
	end )
end

sound.Add {
	name = "StroggMarineTaunt",
	channel = CHAN_AUTO,
	level = 130,
	sound = {
		"Strogg/Marine/Vo/Duhenkhaii.wav",
		"Strogg/Marine/Vo/Kieueh.wav",
		"Strogg/Marine/Vo/Kritaah.wav",
		"Strogg/Marine/Vo/Kunaah.wav",
		"Strogg/Marine/Vo/Kuneh.wav",
		"Strogg/Marine/Vo/Pishdaa.wav",
		"Strogg/Marine/Vo/Ukuuchu.wav",
		"Strogg/Marine/Vo/Umarazdit.wav",
		"Strogg/Marine/Vo/Yekiczuah.wav",
		"Strogg/Marine/Vo/Yekuuchu.wav",
		"Strogg/Marine/Vo/Yetmaov.wav"
	}
}

function ENT:Initialize()
	self:SetHealth( 200 )
	self:SetMaxHealth( 200 )
	self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )
	if self:PhysicsInitShadow( false, false ) then self:GetPhysicsObject():SetMass( 140 ) end
	self:SetBloodColor( BLOOD_COLOR_RED )
	BaseClass.Initialize( self )
end

ENT.flWalkSpeed = 110
ENT.flJogSpeed = 242
ENT.flTopSpeed = 242

function ENT:MoveAlongPath( pPath, flSpeed, _, tFilter )
	local pLocomotion = self.loco

	pLocomotion:SetDesiredSpeed( flSpeed )

	local flAccelDecel = self.flTopSpeed * ACCELERATION_NORMAL
	pLocomotion:SetAcceleration( flAccelDecel )
	pLocomotion:SetDeceleration( flAccelDecel )

	pLocomotion:SetJumpHeight( self.flJumpHeight )

	local flVelocity = GetVelocity( self ):Length()

	if flVelocity <= 12 || !self:IsOnGround() then
	elseif flVelocity <= ( self.flWalkSpeed * 1.1 ) then
		self:PromoteSequence( "walk_all", flVelocity / self:GetSequenceGroundSpeed( self:LookupSequence "walk_all" ) )
	else
		self:PromoteSequence( "run_all", flVelocity / self:GetSequenceGroundSpeed( self:LookupSequence "run_all" ) )
	end

	self:GroundMovement( pPath, flSpeed, tFilter )
end

function ENT:OnKilled( pDamage )
	if BaseClass.OnKilled( self, pDamage ) then return end
	self:BecomeRagdoll( pDamage )
end

ENT.Dodge = {
	DiveRoll = {
		HasDodgePart = function() return true end,

		MinimumSpeed = function() return .5 end,
		MaximumSpeed = function() return 1.5 end,

		Duration = function( self ) return self:SequenceDuration( self:LookupSequence "dive_roll" ) end,

		Point = function( self, flCycle )
			local _, v = self:GetSequenceMovement( self:LookupSequence "dive_roll", 0, flCycle )
			v:Mul( self:GetModelScale() )
			v:Rotate( self:GetAngles() )
			v:Add( self:GetPos() )
			return v
		end,

		Perform = function( self, MyTable, flMultiplier )
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.PlaySequenceAndMove( self, "dive_roll", flMultiplier, nil, function()
				local pEnemy = MyTable.Enemy
				if IsValid( pEnemy ) then MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter() end

				MyTable.Look( self, MyTable )
				MyTable.HandleTurning( self, MyTable )
			end )
		end
	},

	JumpBack = {
		HasDodgePart = function() return true end,

		MinimumSpeed = function() return .5 end,
		MaximumSpeed = function() return 1.5 end,

		Duration = function( self ) return self:SequenceDuration( self:LookupSequence "step_back" ) end,

		Point = function( self, flCycle )
			local _, v = self:GetSequenceMovement( self:LookupSequence "step_back", 0, flCycle )
			v:Mul( self:GetModelScale() )
			v:Rotate( self:GetAngles() )
			v:Add( self:GetPos() )
			return v
		end,

		Perform = function( self, MyTable, flMultiplier )
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.PlaySequenceAndMove( self, "step_back", flMultiplier, nil, function()
				local pEnemy = MyTable.Enemy
				if IsValid( pEnemy ) then MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter() end

				MyTable.Look( self, MyTable )
				MyTable.HandleTurning( self, MyTable )
			end )
		end
	},

	DodgeLeft = {
		HasDodgePart = function() return true end,

		MinimumSpeed = function() return .5 end,
		MaximumSpeed = function() return 1.5 end,

		Duration = function( self ) return self:SequenceDuration( self:LookupSequence "dodge_left2" ) end,

		Point = function( self, flCycle )
			local _, v = self:GetSequenceMovement( self:LookupSequence "dodge_left2", 0, flCycle )
			v:Mul( self:GetModelScale() )
			v:Rotate( self:GetAngles() )
			v:Add( self:GetPos() )
			return v
		end,

		Perform = function( self, MyTable, flMultiplier )
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.PlaySequenceAndMove( self, "dodge_left2", flMultiplier, nil, function()
				local pEnemy = MyTable.Enemy
				if IsValid( pEnemy ) then MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter() end

				MyTable.Look( self, MyTable )
				MyTable.HandleTurning( self, MyTable )
			end )
		end
	},

	DodgeRight = {
		HasDodgePart = function() return true end,

		MinimumSpeed = function() return .5 end,
		MaximumSpeed = function() return 1.5 end,

		Duration = function( self ) return self:SequenceDuration( self:LookupSequence "dodge_right2" ) end,

		Point = function( self, flCycle )
			local _, v = self:GetSequenceMovement( self:LookupSequence "dodge_right2", 0, flCycle )
			v:Mul( self:GetModelScale() )
			v:Rotate( self:GetAngles() )
			v:Add( self:GetPos() )
			return v
		end,

		Perform = function( self, MyTable, flMultiplier )
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.PlaySequenceAndMove( self, "dodge_right2", flMultiplier, nil, function()
				local pEnemy = MyTable.Enemy
				if IsValid( pEnemy ) then MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter() end

				MyTable.Look( self, MyTable )
				MyTable.HandleTurning( self, MyTable )
			end )
		end
	},

	StepLeft = {
		HasDodgePart = function() return true end,

		MinimumSpeed = function() return .5 end,
		MaximumSpeed = function() return 1.5 end,

		Duration = function( self ) return self:SequenceDuration( self:LookupSequence "attackpoint_left" ) end,

		Point = function( self, flCycle )
			local _, v = self:GetSequenceMovement( self:LookupSequence "attackpoint_left", 0, flCycle )
			v:Mul( self:GetModelScale() )
			v:Rotate( self:GetAngles() )
			v:Add( self:GetPos() )
			return v
		end,

		Perform = function( self, MyTable, flMultiplier )
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.PlaySequenceAndMove( self, "attackpoint_left", flMultiplier, nil, function()
				local pEnemy = MyTable.Enemy
				if IsValid( pEnemy ) then MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter() end

				MyTable.Look( self, MyTable )
				MyTable.HandleTurning( self, MyTable )
			end )
		end
	},

	StepRight = {
		HasDodgePart = function() return true end,

		MinimumSpeed = function() return .5 end,
		MaximumSpeed = function() return 1.5 end,

		Duration = function( self ) return self:SequenceDuration( self:LookupSequence "attackpoint_right" ) end,

		Point = function( self, flCycle )
			local _, v = self:GetSequenceMovement( self:LookupSequence "attackpoint_right", 0, flCycle )
			v:Mul( self:GetModelScale() )
			v:Rotate( self:GetAngles() )
			v:Add( self:GetPos() )
			return v
		end,

		Perform = function( self, MyTable, flMultiplier )
			MyTable.AnimationSystemHalt( self, MyTable )
			MyTable.PlaySequenceAndMove( self, "attackpoint_right", flMultiplier, nil, function()
				local pEnemy = MyTable.Enemy
				if IsValid( pEnemy ) then MyTable.vaAimTargetPose = pEnemy:GetPos() + pEnemy:OBBCenter() end

				MyTable.Look( self, MyTable )
				MyTable.HandleTurning( self, MyTable )
			end )
		end
	}
}
