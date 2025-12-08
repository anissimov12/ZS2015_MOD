include("shared.lua")

ENT.PrintName = "Farm 'Standard'"

function ENT:Draw()
	self:DrawModel()

	if not MySelf or not MySelf:IsValid() then return end

	local pos = self:LocalToWorld(self.vOffset or Vector(0, 0, 0))
	local ang = self:LocalToWorldAngles(Angle(0, 0, 0))

	local owner = self:GetObjectOwner()
	local isowner = owner:IsValid() and owner:IsPlayer() and owner == MySelf
	local ownername = owner:IsValid() and owner:IsPlayer() and owner:ClippedName() or "Unknown"

	local lines = {}

	-- Farm name
	table.insert(lines, {text = self.PrintName, font = "ZS3D2DFont2", color = COLOR_GRAY})

	-- Points
	if isowner then
		local cur = self:GetNWInt("stpts", 0)
		local max = self.MaxPoints or 0
		table.insert(lines, {text = string.format("(%u/%u)", cur, max), font = "ZS3D2DFont2", color = COLOR_GRAY})
	end

	-- Owner's name
	local ownercolor = isowner and COLOR_BLUE or COLOR_GRAY
	table.insert(lines, {text = "(" .. ownername .. ")", font = "ZS3D2DFont2Small", color = ownercolor})

	local count = #lines
	if count == 0 then return end

	local lineSpacing = 60
	local startY = -((count - 1) * lineSpacing) * 0.5

	cam.Start3D2D(pos, ang, 0.04)
		for i, line in ipairs(lines) do
			local y = startY + (i - 1) * lineSpacing
			draw.SimpleText(line.text, line.font, 0, y, line.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	cam.End3D2D()
end