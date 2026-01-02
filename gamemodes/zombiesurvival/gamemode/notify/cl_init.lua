local GM = GM or GAMEMODE

GM.Notify = GM.Notify or {}

function GM:Notify_Show(text, duration)
	if not isstring(text) or text == "" then return end

	duration = tonumber(duration) or 3
	duration = math.Clamp(duration, 1, 10)

	if not vgui or not vgui.Create then return end

	if not self.NotifyPanel or not self.NotifyPanel:IsValid() then
		self.NotifyPanel = vgui.Create("ZSNotifyStack")
	end

	if self.NotifyPanel and self.NotifyPanel:IsValid() then
		self.NotifyPanel:MoveToFront()
		self.NotifyPanel:AddNotice(text, duration)
	end
end

net.Receive("zs_notify", function()
	local text = net.ReadString() or ""
	local duration = net.ReadFloat() or 3

	local gm = GAMEMODE or GM
	if not gm or not gm.Notify_Show then return end
	gm:Notify_Show(text, duration)
end)
