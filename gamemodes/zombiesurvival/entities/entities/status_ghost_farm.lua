AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "status_ghost_base"

ENT.GhostModel = Model("models/props/cs_office/computer_caseB.mdl")
ENT.GhostRotation = Angle(270, 180, 0)
ENT.GhostHitNormalOffset = 0
ENT.GhostEntity = "prop_farm"
ENT.GhostWeapon = "weapon_zs_farm"
ENT.GhostDistance = 0
ENT.GhostLimitedNormal = 0

function ENT:CustomValidate(tr)
	local owner = self:GetOwner()
	if owner and owner:IsValid() then
		for _, ent in ipairs(ents.FindByClass("prop_farm")) do
			if ent:IsValid() and ent.GetObjectOwner and ent:GetObjectOwner() == owner then
				return false
			end
		end
	end

	return true
end