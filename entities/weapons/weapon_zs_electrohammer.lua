AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = "Electrohammer"

	SWEP.VElements = {
		["base2"] = { type = "Model", model = "models/props_lab/teleportring.mdl", bone = "ValveBiped.Bip01", rel = "base", pos = Vector(0, 0, 0), angle = Angle(0, 180, 0), size = Vector(0.08, 0.08, 0.08), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
		["base"] = { type = "Model", model = "models/props_lab/powerbox02d.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(6.4, 3.975, -9.412), angle = Angle(5.961, 270, 16.764), size = Vector(0.25, 0.25, 0.25), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
		["ss"] = { type = "Sprite", sprite = "sprites/grav_flare", bone = "ValveBiped.Bip01", rel = "base", pos = Vector(-1.338, 2.894, 0.125), size = { x = 5, y = 5 }, color = Color(255, 255, 255, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
		["base2+"] = { type = "Model", model = "models/props_lab/teleportring.mdl", bone = "ValveBiped.Bip01", rel = "base", pos = Vector(-0.975, -0.263, 0.232), angle = Angle(0, 270, 90), size = Vector(0.15, 0.15, 0.15), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
	}

	SWEP.WElements = {
		["base2"] = { type = "Model", model = "models/props_lab/teleportring.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(0, 0, 0), angle = Angle(0, 180, 0), size = Vector(0.08, 0.08, 0.08), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
		["ss"] = { type = "Sprite", sprite = "sprites/grav_flare", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(-1.338, 2.894, 0.125), size = { x = 5, y = 5 }, color = Color(255, 255, 255, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
		["base"] = { type = "Model", model = "models/props_lab/powerbox02d.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3, 1, -8), angle = Angle(270, 90, 90), size = Vector(0.25, 0.25, 0.25), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
		["base2+"] = { type = "Model", model = "models/props_lab/teleportring.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "base", pos = Vector(-0.975, -0.263, 0.232), angle = Angle(0, 270, 90), size = Vector(0.15, 0.15, 0.15), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} }
	}
end

SWEP.Base = "weapon_zs_hammer"

SWEP.MeleeDamage = 40
SWEP.HealStrength = 1.4

SWEP.ViewModel = "models/weapons/v_hammer/v_hammer.mdl"
SWEP.WorldModel = "models/weapons/w_hammer.mdl"

if SERVER then
	function SWEP:SecondaryAttack()
		if self:GetPrimaryAmmoCount() <= 0 or CurTime() < self:GetNextPrimaryFire() or self.Owner:GetBarricadeGhosting() then return end

		local owner = self.Owner

		if GAMEMODE:IsClassicMode() then
			owner:PrintTranslatedMessage(HUD_PRINTCENTER, "cant_do_that_in_classic_mode")
			return
		end

		local tr = owner:TraceLine(64, MASK_SOLID, owner:GetMeleeFilter())
		local trent = tr.Entity

		if not trent:IsValid()
		or not util.IsValidPhysicsObject(trent, tr.PhysicsBone)
		or tr.Fraction == 0
		or trent:GetMoveType() ~= MOVETYPE_VPHYSICS and not trent:GetNailFrozen()
		or trent.NoNails
		or trent:IsNailed() and (#trent.Nails >= 8 or trent:GetPropsInContraption() >= GAMEMODE.MaxPropsInBarricade)
		or trent:GetMaxHealth() == 1 and trent:Health() == 0 and not trent.TotalHealth
		or not trent:IsNailed() and not trent:GetPhysicsObject():IsMoveable() then return end

		if not gamemode.Call("CanPlaceNail", owner, tr) then return end

		local count = 0
		for _, nail in pairs(trent:GetNails()) do
			if nail:GetDeployer() == owner then
				count = count + 1
				if count >= 3 then
					return
				end
			end
		end

		if tr.MatType == MAT_GRATE or tr.MatType == MAT_CLIP then
			owner:PrintTranslatedMessage(HUD_PRINTCENTER, "impossible")
			return
		end
		if tr.MatType == MAT_GLASS then
			owner:PrintTranslatedMessage(HUD_PRINTCENTER, "trying_to_put_nails_in_glass")
			return
		end

		if trent:IsValid() then
			for _, nail in pairs(ents.FindByClass("prop_nail")) do
				if nail:GetParent() == trent and nail:GetActualPos():Distance(tr.HitPos) <= 16 then
					owner:PrintTranslatedMessage(HUD_PRINTCENTER, "too_close_to_another_nail")
					return
				end
			end
			for _, nail in pairs(ents.FindByClass("prop_electronail")) do
				if nail:GetParent() == trent and nail:GetActualPos():Distance(tr.HitPos) <= 16 then
					owner:PrintTranslatedMessage(HUD_PRINTCENTER, "too_close_to_another_nail")
					return
				end
			end

			if trent:GetBarricadeHealth() <= 0 and trent:GetMaxBarricadeHealth() > 0 then
				owner:PrintTranslatedMessage(HUD_PRINTCENTER, "object_too_damaged_to_be_used")
				return
			end
		end

		local aimvec = owner:GetAimVector()

		local trtwo = util.TraceLine({start = tr.HitPos, endpos = tr.HitPos + aimvec * 24, filter = {owner, trent}, mask = MASK_SOLID})

		if trtwo.HitSky then return end

		local ent = trtwo.Entity
		if trtwo.HitWorld
		or ent:IsValid() and util.IsValidPhysicsObject(ent, trtwo.PhysicsBone) and (ent:GetMoveType() == MOVETYPE_VPHYSICS or ent:GetNailFrozen()) and not ent.NoNails and not (not ent:IsNailed() and not ent:GetPhysicsObject():IsMoveable()) and not (ent:GetMaxHealth() == 1 and ent:Health() == 0 and not ent.TotalHealth) then
			if trtwo.MatType == MAT_GRATE or trtwo.MatType == MAT_CLIP then
				owner:PrintTranslatedMessage(HUD_PRINTCENTER, "impossible")
				return
			end
			if trtwo.MatType == MAT_GLASS then
				owner:PrintTranslatedMessage(HUD_PRINTCENTER, "trying_to_put_nails_in_glass")
				return
			end

			if ent and ent:IsValid() and (ent.NoNails or ent:IsNailed() and (#ent.Nails >= 8 or ent:GetPropsInContraption() >= GAMEMODE.MaxPropsInBarricade)) then return end

			if ent:GetBarricadeHealth() <= 0 and ent:GetMaxBarricadeHealth() > 0 then
				owner:PrintTranslatedMessage(HUD_PRINTCENTER, "object_too_damaged_to_be_used")
				return
			end

			if GAMEMODE:EntityWouldBlockSpawn(ent) then return end

			local cons = constraint.Weld(trent, ent, tr.PhysicsBone, trtwo.PhysicsBone, 0, true)
			if cons ~= nil then
				for _, oldcons in pairs(constraint.FindConstraints(trent, "Weld")) do
					if oldcons.Ent1 == ent or oldcons.Ent2 == ent then
						cons = oldcons.Constraint
						break
					end
				end
			end

			if not cons then return end

			self:SendWeaponAnim(self.Alternate and ACT_VM_HITCENTER or ACT_VM_MISSCENTER)
			self.Alternate = not self.Alternate

			owner:DoAnimationEvent(ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE)

			self:SetNextPrimaryFire(CurTime() + 1)
			self:TakePrimaryAmmo(1)

			trent:EmitSound("weapons/melee/crowbar/crowbar_hit-"..math.random(4)..".ogg", nil, nil, math.random(35, 50))

			local nail = ents.Create("prop_electronail")
			if nail:IsValid() then
				nail:SetActualOffset(tr.HitPos, trent)
				nail:SetPos(tr.HitPos - aimvec * 8)
				nail:SetAngles(aimvec:Angle())
				nail:AttachTo(trent, ent, tr.PhysicsBone, trtwo.PhysicsBone)
				nail:Spawn()
				nail:SetDeployer(owner)

				cons:DeleteOnRemove(nail)

				-- Звуки установки электро-гвоздя
				nail:EmitSound("ambient/energy/zap"..math.random(1, 3)..".wav", 75, math.random(95, 105))
				nail:EmitSound("npc/dog/dog_servo2.wav", 70, math.random(100, 105))

				gamemode.Call("OnNailCreated", trent, ent, nail)
			end
		end
	end
end
