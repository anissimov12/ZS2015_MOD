local GM = GM or GAMEMODE

GM.Notify = GM.Notify or {}

if SERVER then
	util.AddNetworkString("zs_notify")
end

function GM:Notify_Send(pl, text, duration)
	if not IsValid(pl) then return end
	if not isstring(text) or text == "" then return end

	duration = tonumber(duration) or 3
	duration = math.Clamp(duration, 1, 10)

	net.Start("zs_notify")
		net.WriteString(text)
		net.WriteFloat(duration)
	net.Send(pl)
end
