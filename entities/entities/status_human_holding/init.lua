AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	hook.Add("Move", self, self.Move)

	self:DrawShadow(false)

	local owner = self:GetOwner()
	if owner:IsValid() and owner:IsPlayer() then
		owner.status_human_holding = self

		owner:DrawWorldModel(false)

		local info = GAMEMODE:GetHandsModel(owner)
		if info then
			self:SetModel(info.model)
			self:SetSkin(info.skin)
			self:SetBodyGroups(info.body)
		end

		local wep = owner:GetActiveWeapon()
		if wep:IsValid() then
			wep:SendWeaponAnim(ACT_VM_HOLSTER)
			if wep.SetIronsights then
				wep:SetIronsights(false)
			end
		end
	else
		self:SetModel("models/weapons/c_arms_citizen.mdl")
	end

	local object = self:GetObject()
	if object:IsValid() then
		object.IgnoreMeleeTeam = TEAM_HUMAN
		object.IgnoreTraces = true
		object.IgnoreBullets = true

		for _, ent in pairs(ents.FindByClass("logic_pickupdrop")) do
			if ent.EntityToWatch == object:GetName() and ent:IsValid() then
				ent:Input("onpickedup", owner, object, "")
			end
		end

		for _, ent in pairs(ents.FindByClass("point_propnocollide")) do
			if ent:IsValid() and ent:GetProp() == object then
				ent:Remove()
			end
		end

		local objectphys = object:GetPhysicsObject()
		if objectphys:IsValid() then
			objectphys:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
			objectphys:AddGameFlag(FVPHYSICS_NO_NPC_IMPACT_DMG)

			self:SetObjectMass(objectphys:GetMass())

			object.PreHoldCollisionGroup = object.PreHoldCollisionGroup or object:GetCollisionGroup()
			object.PreHoldAlpha = object.PreHoldAlpha or object:GetAlpha()
			object.PreHoldRenderMode = object.PreHoldRenderMode or object:GetRenderMode()

			objectphys:AddGameFlag(FVPHYSICS_PLAYER_HELD)
			object._OriginalMass = objectphys:GetMass()

			objectphys:EnableGravity(false)
			objectphys:SetMass(2)

			object:SetOwner(owner)
			object:SetCollisionGroup(COLLISION_GROUP_WEAPON)
			object:SetRenderMode(RENDERMODE_TRANSALPHA)
			object:SetAlpha(180)

			self.StartX = owner.InputMouseX or 0
			self.StartY = owner.InputMouseY or 0

			local children = object:GetChildren()
			for _, child in pairs(children) do
				if not child:IsValid() then continue end

				child.PreHoldCollisionGroup = child.PreHoldCollisionGroup or child:GetCollisionGroup()
				if child:IsPhysicsModel() then -- Stops child sprites from getting fucked up rendering
					child.PreHoldAlpha = child.PreHoldAlpha or child:GetAlpha()
					child.PreHoldRenderMode = child.PreHoldRenderMode or child:GetRenderMode()

					child:SetAlpha(180)
					child:SetRenderMode(RENDERMODE_TRANSALPHA)
				end

				child:SetCollisionGroup(COLLISION_GROUP_WEAPON)
				child:CollisionRulesChanged()
			end

			object:CollisionRulesChanged()
		end
	end
end

function ENT:OnRemove()
	local owner = self:GetOwner()
	if owner:IsValid() then
		--owner.status_human_holding = nil

		owner:DrawWorldModel(true)

		if owner:Alive() and owner:Team() == TEAM_HUMAN then
			local wep = owner:GetActiveWeapon()
			if wep:IsValid() then
				wep:SendWeaponAnim(ACT_VM_DRAW)
			end
		end
	end

	local object = self:GetObject()
	if object:IsValid() then
		local objectphys = object:GetPhysicsObject()
		if objectphys:IsValid() then
			objectphys:ClearGameFlag(FVPHYSICS_PLAYER_HELD)
			objectphys:ClearGameFlag(FVPHYSICS_NO_IMPACT_DMG)
			objectphys:ClearGameFlag(FVPHYSICS_NO_NPC_IMPACT_DMG)
			objectphys:EnableGravity(true)
			if object._OriginalMass then
				objectphys:SetMass(object._OriginalMass)
				object._OriginalMass = nil
			end

			object:SetOwner(NULL)
		end

		self:RestoreObjectState(object)

		if objectphys:IsValid() and not self:GetIsHeavy() then
			object:GhostAllPlayersInMe(2.5, true)
		end

		object._LastDroppedBy = owner
		object._LastDropped = CurTime()

		for _, ent in pairs(ents.FindByClass("logic_pickupdrop")) do
			if ent.EntityToWatch == object:GetName() and ent:IsValid() then
				ent:Input("ondropped", owner, object, "")
			end
		end
	end
end

function ENT:RestoreObjectState(object)
	if not object:IsValid() then return end

	if object.PreHoldCollisionGroup ~= nil then
		object:SetCollisionGroup(object.PreHoldCollisionGroup)
		object.PreHoldCollisionGroup = nil
	end

	if object.PreHoldRenderMode ~= nil then
		object:SetRenderMode(object.PreHoldRenderMode)
		object.PreHoldRenderMode = nil
	end

	if object.PreHoldAlpha ~= nil then
		object:SetAlpha(object.PreHoldAlpha)
		object.PreHoldAlpha = nil
	else
		object:SetAlpha(255)
	end

	object.IgnoreMeleeTeam = nil
	object.IgnoreTraces = nil
	object.IgnoreBullets = nil

	local children = object:GetChildren()
	for _, child in pairs(children) do
		if not child:IsValid() then continue end

		if child.PreHoldCollisionGroup ~= nil then
			child:SetCollisionGroup(child.PreHoldCollisionGroup)
			child.PreHoldCollisionGroup = nil
		end

		if child.PreHoldRenderMode ~= nil then
			child:SetRenderMode(child.PreHoldRenderMode)
			child.PreHoldRenderMode = nil
	end

		if child.PreHoldAlpha ~= nil then
			child:SetAlpha(child.PreHoldAlpha)
			child.PreHoldAlpha = nil
	else
			child:SetAlpha(255)
		end

		child:CollisionRulesChanged()
	end

	object:CollisionRulesChanged()
	object.IgnorePlayers = nil
end

concommand.Add("_zs_rotateang", function(sender, command, arguments)
	local x = tonumbersafe(arguments[1])
	local y = tonumbersafe(arguments[2])

	if x and y then
		sender.InputMouseX = math.Clamp(x * 0.2, -180, 180)
		sender.InputMouseY = math.Clamp(y * 0.2, -180, 180)
	end
end)

local ShadowParams = {secondstoarrive = 0.01, maxangular = 1000, maxangulardamp = 10000, maxspeed = 500, maxspeeddamp = 1000, dampfactor = 0.65, teleportdistance = 0}
function ENT:Think()
	local ct = CurTime()

	local frametime = ct - (self.LastThink or ct)
	self.LastThink = ct

	local object = self:GetObject()
	local owner = self:GetOwner()
	if not object:IsValid() or object:IsNailed() or not owner:IsValid() or not owner:Alive() or not owner:Team() == TEAM_HUMAN then
		self:Remove()
		return
	end

	local shootpos = owner:GetShootPos()
	local nearestpoint = object:NearestPoint(shootpos)

	local objectphys = object:GetPhysicsObject()
	if object:GetMoveType() ~= MOVETYPE_VPHYSICS or not objectphys:IsValid() or owner:GetGroundEntity() == object then
		self:Remove()
		return
	end

	if self:GetIsHeavy() then
		if 64 < self:GetHingePos():Distance(self:GetPullPos()) then
			self:Remove()
			return
		end
	elseif 64 < nearestpoint:Distance(shootpos) then
		self:Remove()
		return
	end

	objectphys:Wake()

	if owner:KeyPressed(IN_ATTACK) then
		object:SetPhysicsAttacker(owner)

		self:Remove()
		return
	elseif self:GetIsHeavy() then
		local pullpos = self:GetPullPos()
		local hingepos = self:GetHingePos()
		objectphys:ApplyForceOffset(objectphys:GetMass() * frametime * 450 * (pullpos - hingepos):GetNormalized(), hingepos)
	elseif owner:KeyDown(IN_ATTACK2) and not owner:GetActiveWeapon().NoPropThrowing then
		owner:ConCommand("-attack2")
		objectphys:ApplyForceCenter(objectphys:GetMass() * math.Clamp(1.25 - math.min(1, (object:OBBMins():Length() + object:OBBMaxs():Length()) / CARRY_DRAG_VOLUME), 0.25, 1) * 500 * owner:GetAimVector())
		object:SetPhysicsAttacker(owner)

		self:Remove()
		return
	else
		if not self.ObjectPosition or not owner:KeyDown(IN_SPEED) then
			local obbcenter = object:OBBCenter()
			local objectpos = shootpos + owner:GetAimVector() * 48
			objectpos = objectpos - obbcenter.z * object:GetUp()
			objectpos = objectpos - obbcenter.y * object:GetRight()
			objectpos = objectpos - obbcenter.x * object:GetForward()
			self.ObjectPosition = objectpos
			if not self.ObjectAngles then
				self.ObjectAngles = object:GetAngles()
			end
		end

		if owner:KeyDown(IN_SPEED) then
			if owner:KeyPressed(IN_SPEED) then
				self.ObjectAngles = object:GetAngles()
			end
		elseif owner:KeyDown(IN_WALK) then
			self.ObjectAngles:RotateAroundAxis(owner:EyeAngles():Up(), owner.InputMouseX or 0)
			self.ObjectAngles:RotateAroundAxis(owner:EyeAngles():Right(), owner.InputMouseY or 0)
		end

		ShadowParams.pos = self.ObjectPosition
		ShadowParams.angle = self.ObjectAngles
		ShadowParams.deltatime = frametime
		objectphys:ComputeShadowControl(ShadowParams)
	end

	object:SetPhysicsAttacker(owner)

	self:NextThink(ct)
	return true
end
