AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName     = "Wire Turret"
ENT.WireDebugName = "Turret"

if ( CLIENT ) then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:DrawShadow( false )
	self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

	local phys = self:GetPhysicsObject()
	if ( phys:IsValid() ) then
		phys:Wake()
	end

	-- Allocating internal values on initialize
	self.NextShot     = 0
	self.Firing       = false
	self.spreadvector = Vector()
	self.effectdata   = EffectData()

	-- Not all entities have an 1 attachment
	local attachment = self:GetAttachment(1)
	self.attachmentPos = attachment and self:WorldToLocal(attachment.Pos) or vector_origin

	self.Inputs = WireLib.CreateSpecialInputs(self,
		{ "Fire", "Force", "Damage", "NumBullets", "Spread", "Delay", "Sound", "Tracer" },
		{ "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "STRING", "STRING" })

	self.Outputs = WireLib.CreateSpecialOutputs(self,
		{ "HitEntity", "Bullet" },
		{ "ENTITY", "RANGER" })
end

function ENT:FireShot()

	if ( self.NextShot > CurTime() ) then return end

	self.NextShot = CurTime() + self.delay

	-- Make a sound if you want to.
	if ( self.sound ) then
		self:EmitSound( self.sound )
	end

	local shootOrigin, shootAngles
	local parent = self:GetParent()
	if parent:IsValid() then
		shootOrigin = self:LocalToWorld(self.attachmentPos)
		shootAngles = self:GetAngles()
	else
		local phys = self:GetPhysicsObject()
		shootOrigin = phys:LocalToWorld(self.attachmentPos)
		shootAngles = phys:GetAngles()
	end

	-- Shoot a bullet
	local bullet      = {}
	bullet.Num        = self.numbullets
	bullet.Src        = shootOrigin
	bullet.Dir        = shootAngles:Forward()
	bullet.Spread     = self.spreadvector
	bullet.Tracer     = self.tracernum
	bullet.TracerName = self.tracer
	bullet.Force      = self.force
	bullet.Attacker   = self:GetPlayer()
	bullet.Callback   = function(attacker, traceres, cdamageinfo)
		WireLib.TriggerOutput(self, "Bullet", traceres)
		WireLib.TriggerOutput(self, "HitEntity", traceres.Entity)
	end

	local dps = 100 / ( ( self.damage / self.delay ) * self.numbullets )
	if dps > 1 then dps = 1 end
	bullet.Damage = self.damage * dps

	self:FireBullets( bullet )

	-- Make a muzzle flash
	self.effectdata:SetOrigin( shootOrigin )
	self.effectdata:SetAngles( shootAngles )
	self.effectdata:SetScale( 1 )
	util.Effect( "MuzzleEffect", self.effectdata )
end

function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end

function ENT:Think()
	BaseClass.Think( self )

	if ( self.Firing ) then
		self:FireShot()
	end

	self:NextThink( CurTime() )
	return true
end

local ValidTracers = {
	["Tracer"]                = true,
	["AR2Tracer"]             = true,
	["ToolTracer"]            = true,
	["LaserTracer"]           = true,
}

function ENT:SetSound( path )
	if path then
		self.sound = WireLib.SoundExists(path)
	end
end

function ENT:SetDelay( delay )
	self.delay = math.Clamp( delay, 0.05, 1 )
end

function ENT:SetNumBullets( numbullets )
	self.numbullets = math.Clamp( math.floor( numbullets ), 1, 10 )
end

function ENT:SetTracer( tracer )
	tracer = string.Trim(tracer)
	self.tracer = ValidTracers[tracer] and tracer or "Tracer"
end

function ENT:SetSpread( spread )
	self.spread = math.Clamp( spread, 0.01, 1 )
	self.spreadvector.x = self.spread
	self.spreadvector.y = self.spread
end

function ENT:SetDamage( damage )
	self.damage = math.Clamp( damage, 0, 100 )
end

function ENT:SetForce( force )
	self.force = math.Clamp( force, 0, 500 )
end

function ENT:SetTraceNum( tracernum )
	self.tracernum = math.Clamp( math.floor( tracernum ), 1, 15 )
end

function ENT:TriggerInput( iname, value )
	if (iname == "Fire") then
		self.Firing = value > 0
	elseif (iname == "Force") then
		self:SetForce( value )
	elseif (iname == "Damage") then
		self:SetDamage( value )
	elseif (iname == "NumBullets") then
		self:SetNumBullets( value )
	elseif (iname == "Spread") then
		self:SetSpread( value )
	elseif (iname == "Delay") then
		self:SetDelay( value )
	elseif (iname == "Sound") then
		self:SetSound( value )
	elseif (iname == "Tracer") then
		self:SetTracer( value )
	end
end

function ENT:Setup(delay, damage, force, sound, numbullets, spread, tracer, tracernum)
	self:SetForce(force)
	self:SetDelay(delay)
	self:SetSound(sound)
	self:SetDamage(damage)
	self:SetSpread(spread or 0.1)
	self:SetTracer(tracer)
	self:SetTraceNum(tracernum or 0)
	self:SetNumBullets(numbullets)
end

duplicator.RegisterEntityClass( "gmod_wire_turret", WireLib.MakeWireEnt, "Data", "delay", "damage", "force", "sound", "numbullets", "spread", "tracer", "tracernum" )
