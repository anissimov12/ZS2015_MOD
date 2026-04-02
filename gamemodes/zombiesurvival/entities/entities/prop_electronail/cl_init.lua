include("shared.lua")

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Base = "prop_nail"

local matOutlineWhite = Material("white_outline")
local ScaleOutline = 1.4
local colNail = Color(0, 0, 5, 220)
function ENT:DrawTranslucent()
	local drawowner = MySelf:IsValid() and MySelf:Team() == TEAM_HUMAN and (GAMEMODE.AlwaysShowNails or MySelf:KeyDown(IN_SPEED) or MySelf:TraceLine(256, MASK_SHOT).HitPos:Distance(self:GetPos()) <= 16)

	if drawowner then
		render.SuppressEngineLighting(true)
		render.SetAmbientLight(1, 1, 1)

		local health = self:GetNailHealth() / self:GetMaxNailHealth()
		render.SetColorModulation(1 - health, health, 0)

		local scale = self:GetModelScale()
		self:SetModelScale(ScaleOutline * scale, 0)
		render.ModelMaterialOverride(matOutlineWhite)

		self:DrawModel()

		render.ModelMaterialOverride()
		self:SetModelScale(scale, 0)

		render.SuppressEngineLighting(false)
		render.SetColorModulation(1, 1, 1)
	end

	self:DrawModel()

	if drawowner then
		local displayowner = self:GetDTString(0)
		local redname = false
		if displayowner == "" then
			displayowner = nil

			local deployer = self:GetOwner()
			if deployer:IsValid() then
				displayowner = deployer:Name()
				if deployer:Team() ~= TEAM_HUMAN or not deployer:Alive() then
					displayowner = "(DEAD) "..displayowner
					redname = true
				end
			end
		end

		local ang = EyeAngles()
		ang:RotateAroundAxis(ang:Up(), -90)
		ang:RotateAroundAxis(ang:Forward(), 90)

		cam.Start3D2D(self:GetPos(), ang, 0.05)
			local wid, hei = 180, 5
			local x, y = wid * -0.5 + 2, 0

			if self:GetMaxRepairs() > 0 then
				local repairs = self:GetRepairs()
				local ru = 1 - math.Clamp(repairs / self:GetMaxRepairs(), 0, 1)
				surface.SetDrawColor(76, 74, 219, 220)
				surface.DrawRect(x, y, wid, hei)
				surface.SetDrawColor(50, 55, 139, 220)
				surface.DrawOutlinedRect(x, y, wid, hei)
				surface.SetDrawColor(230, 5, 5, ru == 1 and (150 + math.abs(math.sin(RealTime() * 5)) * 105) or 220)
				surface.DrawRect(x + 1, y + 1, (wid - 2) * ru, hei - 2)

				local repairs_text_y = y - 6
				draw.SimpleText(math.ceil(repairs), "ZS3D2DFont2Smaller", x + wid, repairs_text_y, repairs <= 0 and COLOR_DARKRED or COLOR_GRAY, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
			end

			if self:GetMaxNailHealth() > 0 then
				local mu = math.Clamp(self:GetNailHealth() / self:GetMaxNailHealth(), 0, 1)
				local green = mu * 200
				colNail.r = 200 - green
				colNail.g = green

				y = y + hei + 3
				hei = 8
				x = wid * -0.5 + 2
				surface.SetDrawColor(84, 80, 174, 220)
				surface.DrawRect(x, y, wid, hei)
				surface.SetDrawColor(54, 49, 139, 220)
				surface.DrawOutlinedRect(x, y, wid, hei)
				surface.SetDrawColor(colNail)
				surface.DrawRect(x + 1, y + 1, (wid - 2) * mu, hei - 2)

				draw.SimpleText(math.ceil(self:GetNailHealth()).." / "..math.ceil(self:GetMaxNailHealth()), "ZS3D2DFont2Smaller", x + wid / 2, y + hei + 1, colNail, TEXT_ALIGN_CENTER)
			end

			if displayowner then
				draw.SimpleText(displayowner, "ZS3D2DFont2Smaller", 0, y + 38, redname and COLOR_DARKRED or COLOR_GRAY, TEXT_ALIGN_CENTER)
			end
		cam.End3D2D()
	end
end

