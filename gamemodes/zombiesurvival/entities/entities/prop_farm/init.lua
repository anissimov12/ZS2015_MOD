AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel(self.Model or "models/props/cs_office/computer_caseB.mdl")

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(false)
	end

	self:SetMaxObjectHealth(70)
	self:SetObjectHealth(self:GetMaxObjectHealth())

	self.StoredPoints = 0
	self.NextPointTick = CurTime() + 1
end

function ENT:OnRemove()
	local owner = self:GetObjectOwner()
	if IsValid(owner) and owner.lastfarm == self then
		owner.lastfarm = nil
	end
end

function ENT:Think()
	local owner = self:GetObjectOwner()
	if not (IsValid(owner) and owner:IsPlayer() and owner:Team() == TEAM_HUMAN) then
		self:NextThink(CurTime() + 1)
		return true
	end

	if self.NextPointTick and CurTime() >= self.NextPointTick then
		self.NextPointTick = CurTime() + 1

		local maxpts = self.MaxPoints or 0
		local rate = self.PointPerSec or 0

		local oldint = math.floor(self.StoredPoints or 0)
		self.StoredPoints = (self.StoredPoints or 0) + rate
		if maxpts > 0 and self.StoredPoints > maxpts then
			self.StoredPoints = maxpts
		end
		local newint = math.floor(self.StoredPoints or 0)

		if newint > oldint and IsValid(owner) and owner.FloatingScore then
			local gained = newint - oldint
			owner:FloatingScore(self, "floatingscore_com", gained, FM_NONE)
		end

		self:SetNWInt("stpts", newint)
	end

	if IsValid(owner) and owner.lastfarm ~= self then
		owner.lastfarm = self
	end

	self:NextThink(CurTime() + 0.1)
	return true
end

function ENT:Use(activator, caller)
	if activator ~= self:GetObjectOwner() then return end
	if not (activator:IsPlayer() and activator:Team() == TEAM_HUMAN and activator:Alive()) then return end

	local amount = math.floor(self.StoredPoints or 0)
	if amount <= 0 then return end

	if activator.SetPoints and activator.GetPoints then
		activator:SetPoints(activator:GetPoints() + amount)
		if gamemode and gamemode.Call then
			gamemode.Call("PlayerPointsAdded", activator, amount)
		end
	end

	self.StoredPoints = 0
	self:SetNWInt("stpts", 0)
end

function ENT:AltUse(activator, tr)
	self:PackUp(activator)
end

function ENT:OnPackedUp(pl)
	pl:GiveEmptyWeapon("weapon_zs_farm")
	pl:GiveAmmo(1, "alyxgun")

	pl:PushPackedItem(self:GetClass(), self:GetObjectHealth())

	self:Remove()
end

function ENT:OnTakeDamage(dmginfo)
	self:TakePhysicsDamage(dmginfo)

	local attacker = dmginfo:GetAttacker()
	if not (attacker:IsValid() and attacker:IsPlayer() and attacker:Team() == TEAM_HUMAN) then
		self:ResetLastBarricadeAttacker(attacker, dmginfo)
		self:SetObjectHealth(self:GetObjectHealth() - dmginfo:GetDamage())
	end
end

hook.Add("PlayerDeath", "ZS.PropFarmOwnerDeath", function(pl)
	for _, ent in ipairs(ents.FindByClass("prop_farm")) do
		if ent:IsValid() and ent:GetObjectOwner() == pl then
			ent:Remove()
		end
	end
end)
