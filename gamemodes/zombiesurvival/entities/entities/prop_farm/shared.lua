ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.m_NoNailUnfreeze = true
ENT.NoNails = true
ENT.CanPackUp = true
ENT.IsBarricadeObject = true
ENT.AlwaysGhostable = true

ENT.ModelBreakAnimation = true

ENT.Model = "models/props/cs_office/computer_caseB.mdl"
ENT.MaxPoints = 35
ENT.PointPerSec = 0.28
ENT.EqWeapon = "weapon_zs_farm"

ENT.vOffset = Vector(0, 0, 24.5)

function ENT:GetObjectHealth()
	return self:GetDTFloat(0)
end

function ENT:SetObjectHealth(health)
	self:SetDTFloat(0, health)

	if health <= 0 then
		self:Remove()
	end
end

function ENT:SetMaxObjectHealth(health)
	self:SetDTFloat(1, health)
end

function ENT:GetMaxObjectHealth()
	return self:GetDTFloat(1)
end

function ENT:SetObjectOwner(ent)
	self:SetDTEntity(0, ent)
end

function ENT:GetObjectOwner()
	return self:GetDTEntity(0)
end

function ENT:ClearObjectOwner()
	self:Remove()
end
