--[[
	PVers - Project Versions

	Add 1.x.x upon release
	Add x.1.x when loading content and mechanics
	Add x.x.1 when fixing bugs and adding patches
]]--

-- fallback (add this in db)
PVERS = {
	type    = "a",   -- a (alpha) | b (beta) | r (release)
	version = "0.3.2",
}

PVERS.string = PVERS.type .. PVERS.version .. "v"

if SERVER then
	util.AddNetworkString("zs_pvers_sync")
	
	function PVERS:SendToClient(pl)
		net.Start("zs_pvers_sync")
			net.WriteString(self.type)
			net.WriteString(self.version)
		net.Send(pl)
	end
	
	function PVERS:LoadFromDatabase()
		-- TODO: Load from database
		-- Example structure:
		-- local data = sql.QueryRow("SELECT type, version FROM pvers WHERE id = 1")
		-- if data then
		--     self.type = data.type
		--     self.version = data.version
		--     self.string = self.type .. self.version .. "v"
		-- end
		
		ZSLogModule("PVERS", "Version loaded: " .. self.string)
	end

	hook.Add("PlayerInitialSpawn", "PVERS_SendToClient", function(pl)
		timer.Simple(1, function()
			if IsValid(pl) then
				PVERS:SendToClient(pl)
			end
		end)
	end)

	hook.Add("Initialize", "PVERS_LoadFromDB", function()
		PVERS:LoadFromDatabase()
	end)
end

if CLIENT then
	net.Receive("zs_pvers_sync", function()
		local vtype = net.ReadString()
		local vversion = net.ReadString()
		
		PVERS.type = vtype
		PVERS.version = vversion
		PVERS.string = vtype .. vversion .. "v"
		
		ZSLogModule("PVERS", "Version synced from server: " .. PVERS.string)
	end)
	
	surface.CreateFont("PVersFont", {
		font    = "BudgetLabel",
		size    = 12,
		weight  = 400,
		antialias = false,
	})

	local col = Color(255, 255, 255, 255)

	hook.Add("HUDPaint", "PVers_Draw", function()
		local x = ScrW() - 1
		local y = ScrH() - 1
		draw.SimpleText(PVERS.string, "PVersFont", x, y, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
	end)
end
