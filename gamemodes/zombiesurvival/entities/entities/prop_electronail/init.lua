AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.Base = "prop_nail"
ENT.RepairInterval = 1.25  -- Repair interval in seconds
ENT.RepairStrength = 1.168 -- Repair strength multiplier

hook.Add("PlayerInitialSpawn", "ElectroNailPlayerInitialSpawn", function(pl)
	local uid = pl:UniqueID()

	for _, nail in pairs(ents.FindByClass("prop_electronail")) do
		if nail:GetOwnerUID() == uid then
			nail:SetDeployer(pl)
		end
	end
end)

function ENT:AttachTo(baseent, attachent, physbone, physbone2)
	self.BaseClass.AttachTo(self, baseent, attachent, physbone, physbone2)

	if baseent:IsValid() and not baseent:IsWorld() then
		if not baseent.m_ElectroNailNextRepair then
			local electronails = self:CountElectroNails(baseent)
			local interval = self.RepairInterval + 0.75 * math.max(electronails - 1, 0)
			baseent.m_ElectroNailNextRepair = CurTime() + interval
		end
	end
end

function ENT:CountElectroNails(ent)
	local count = 0
	if ent.Nails then
		for _, nail in pairs(ent.Nails) do
			if nail:IsValid() and nail:GetClass() == "prop_electronail" then
				count = count + 1
			end
		end
	end
	return count
end

function ENT:AutoRepair()
	local baseent = self:GetBaseEntity()
	if not baseent:IsValid() or baseent:IsWorld() then return end

	if baseent:GetBarricadeHealth() <= 0 or baseent:GetBarricadeHealth() >= baseent:GetMaxBarricadeHealth() or baseent:GetBarricadeRepairs() <= 0 then
		return
	end

	local electronails = self:CountElectroNails(baseent)
	if electronails <= 0 then return end

	local healstrength = (GAMEMODE.NailHealthPerRepair or 10) * self.RepairStrength
	local oldhealth = baseent:GetBarricadeHealth()
	
	baseent:SetBarricadeHealth(math.min(baseent:GetMaxBarricadeHealth(), baseent:GetBarricadeHealth() + math.min(baseent:GetBarricadeRepairs(), healstrength)))
	local healed = baseent:GetBarricadeHealth() - oldhealth
	
	if healed > 0 then
		baseent:SetBarricadeRepairs(math.max(baseent:GetBarricadeRepairs() - healed, 0))
		
		baseent:EmitSound("npc/dog/dog_servo"..math.random(7, 8)..".wav", 70, math.random(100, 105))
		
		local effectdata = EffectData()
		effectdata:SetOrigin(self:GetPos())
		effectdata:SetNormal(self:GetForward() * -1)
		effectdata:SetMagnitude(1)
		util.Effect("nailrepaired", effectdata, true, true)
	end
end

function ENT:Think()
	local baseent = self:GetBaseEntity()
	if not baseent:IsValid() or baseent:IsWorld() then
		self:NextThink(CurTime() + 0.5)
		return true
	end

	if not baseent.m_ElectroNailNextRepair then
		local electronails = self:CountElectroNails(baseent)
		local interval = self.RepairInterval + 0.865 * math.max(electronails - 1, 0)
		baseent.m_ElectroNailNextRepair = CurTime() + interval
	end

	if CurTime() >= baseent.m_ElectroNailNextRepair then
		if not baseent.m_ElectroNailRepairing then
			baseent.m_ElectroNailRepairing = true

			if baseent.Nails then
				for _, nail in pairs(baseent.Nails) do
					if nail:IsValid() and nail:GetClass() == "prop_electronail" then
						nail:AutoRepair()
					end
				end
			end

			local electronails = self:CountElectroNails(baseent)
			local interval = self.RepairInterval + 0.865 * math.max(electronails - 1, 0)
			baseent.m_ElectroNailNextRepair = CurTime() + interval
			baseent.m_ElectroNailRepairing = false
		end
	end

	self:NextThink(CurTime() + 0.1)
	return true
end

