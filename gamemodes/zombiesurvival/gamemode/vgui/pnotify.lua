local STACK = {}

function STACK:Init()
	self.Notices = {}
	self:SetSize(ScrW(), ScrH())
	self:SetPos(0, 0)
	self:SetMouseInputEnabled(false)
	self:SetKeyboardInputEnabled(false)
	self:ParentToHUD()
	self:SetDrawOnTop(true)
	self:SetZPos(32767)
end

function STACK:AddNotice(text, duration)
	if not isstring(text) or text == "" then return end
	if not isnumber(duration) then duration = 3 end

	local pnl = vgui.Create("ZSNotifyItem", self)
	if not pnl or not pnl:IsValid() then return end
	pnl:Setup(text, duration)

	table.insert(self.Notices, 1, pnl)

	for i = #self.Notices, 1, -1 do
		if not IsValid(self.Notices[i]) then
			table.remove(self.Notices, i)
		end
	end

	local max = 5
	for i = max + 1, #self.Notices do
		if IsValid(self.Notices[i]) then
			self.Notices[i]:Remove()
		end
	end

	self:InvalidateLayout(true)
end

function STACK:PerformLayout(w, h)
	local x = w - 320 - 20
	local y = 20

	for i, pnl in ipairs(self.Notices) do
		if IsValid(pnl) then
			pnl:SetPos(x, y)
			y = y + pnl:GetTall() + 8
		end
	end
end

function STACK:Think()
	local sw, sh = ScrW(), ScrH()
	if self:GetWide() ~= sw or self:GetTall() ~= sh then
		self:SetSize(sw, sh)
		self:InvalidateLayout(true)
	end
	self:MoveToFront()
end

function STACK:Paint(w, h)
	return true
end

local ITEM = {}

function ITEM:Init()
	self.Text = ""
	self.Born = CurTime()
	self.Expire = 0
	self.Duration = 3
	self.FadeIn = 0.2
	self.FadeOut = 0.25
	self:SetSize(320, 34)
	self:SetMouseInputEnabled(false)
	self:SetKeyboardInputEnabled(false)
end

function ITEM:Setup(text, duration)
	self.Text = tostring(text or "")
	self.Duration = tonumber(duration) or 3
	self.Born = CurTime()
	self.Expire = CurTime() + self.Duration
end

function ITEM:Think()
	if self.Expire > 0 and CurTime() >= (self.Expire + self.FadeOut) then
		self:Remove()
		return
	end
end

function ITEM:Paint(w, h)
	local now = CurTime()
	local alpha = 1

	local fin = self.FadeIn or 0
	if fin > 0 then
		alpha = math.min(alpha, math.Clamp((now - (self.Born or now)) / fin, 0, 1))
	end

	local fout = self.FadeOut or 0
	if fout > 0 and self.Expire and self.Expire > 0 then
		alpha = math.min(alpha, math.Clamp((self.Expire + fout - now) / fout, 0, 1))
	end

	local a1 = math.floor(180 * alpha)
	local a2 = math.floor(200 * alpha)
	local a3 = math.floor(255 * alpha)

	draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, a1))
	surface.SetDrawColor(80, 80, 80, a2)
	surface.DrawOutlinedRect(0, 0, w, h)
	draw.SimpleText(self.Text, "ZSHUDFontTiny", 10, h * 0.5, Color(240, 240, 240, a3), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	return true
end

vgui.Register("ZSNotifyItem", ITEM, "DPanel")
vgui.Register("ZSNotifyStack", STACK, "DPanel")
