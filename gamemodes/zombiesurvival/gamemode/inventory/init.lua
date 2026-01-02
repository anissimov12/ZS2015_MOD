local GM = GM or GAMEMODE

GM.Inventory = GM.Inventory or {}
GM.Inventory.Data = GM.Inventory.Data or {}
GM.Inventory.ItemsData = GM.Inventory.ItemsData or {
	["electrohammer"] = {
		ID = "electrohammer",
		Name = "Electrohammer",
		Category = "Items",
		DefaultCategory = "Items",
        Model = "models/weapons/w_hammer.mdl",
		GiveClass = "weapon_zs_electrohammer"
	},
	["farm_standard"] = {
		ID = "farm_standard",
		Name = "Farm 'Standard'",
		Category = "Items",
		DefaultCategory = "Items",
        Model = "models/props/cs_office/computer_caseB.mdl",
		GiveClass = "weapon_zs_farm"
	}
}

function GM:Inventory_LoadPlayer(pl)
    if not IsValid(pl) then return end

    self.Inventory.Storage = self.Inventory.Storage or {}
    self.Inventory.Data = self.Inventory.Data or {}

    local sid = pl:SteamID()
    local stored = self.Inventory.Storage[sid]

    if istable(stored) then
		local itemslist = stored.items or stored
		local inv = {}
		local defs = self.Inventory.ItemsData or {}
		for _, ent in ipairs(itemslist) do
			local def = ent.id and defs[ent.id]
			if def then
				local it = table.Copy(def)
				if ent.equipped then
					it.DefaultCategory = it.DefaultCategory or it.Category or "Items"
					it.Category = "Equipped"
				else
					it.Category = it.DefaultCategory or it.Category or "Items"
				end

				if ent.count then
					it.Count = ent.count
				end
				table.insert(inv, it)
			end
		end
		self.Inventory.Data[pl] = inv
    else
        self:Inventory_GetItems(pl)
    end

    if self.Inventory_SendToClient then
        self:Inventory_SendToClient(pl)
    end
end

function GM:Inventory_SavePlayer(pl)
	if not IsValid(pl) then return end

	local inv = self.Inventory.Data[pl]
	if not inv then return end

	self.Inventory.Storage = self.Inventory.Storage or {}

	local compact = {name = pl:Nick(), items = {}}
	for _, it in ipairs(inv) do
		local id = it.ID or it.id
		if id then
			local entry = {
				id = id,
				equipped = (it.Category == "Equipped"),
				name = pl:Nick()
			}
			if it.Count and it.Count > 1 then
				entry.count = it.Count
			end
			table.insert(compact.items, entry)
		end
	end

	self.Inventory.Storage[pl:SteamID()] = compact

	if self.Inventory_SaveAll then
		self:Inventory_SaveAll()
	end
end

function GM:Inventory_GiveItem(pl, itemid, data)
	if not IsValid(pl) then return end

	itemid = tostring(itemid or "")
	if itemid == "" then return end

	local defs = self.Inventory.ItemsData or {}
	local def = defs[itemid]
	if not def then return end

	local count = 1
	if istable(data) and data.count then
		count = tonumber(data.count) or 1
	end
	count = math.max(1, count)

	local inv = self:Inventory_GetItems(pl)
	local found
	for _, it in ipairs(inv) do
		if it and tostring(it.ID or it.id) == itemid then
			it.Count = (tonumber(it.Count) or 1) + count
			found = true
			break
		end
	end

	if not found then
		local newitem = table.Copy(def)
		newitem.Count = count
		newitem.Category = newitem.DefaultCategory or newitem.Category or "Items"
		table.insert(inv, newitem)
	end

	self.Inventory.Data[pl] = inv

	if self.Inventory_SavePlayer then
		self:Inventory_SavePlayer(pl)
	end

	if self.Inventory_SendToClient then
		self:Inventory_SendToClient(pl)
	end
end

function GM:Inventory_RemoveItem(pl, itemid)
end

function GM:Inventory_GetItems(pl)
	if not IsValid(pl) then return {} end

	local data = self.Inventory.Data[pl]
	if not data then
		data = {}
		local items = self.Inventory.ItemsData or {}
		self.Inventory.Data[pl] = data
	end

	return data
end

function GM:Inventory_HandleClientRequest(pl, action, payload)
    if not IsValid(pl) then return end

    local id = payload and payload.id
    if not id or id == "" then return end

	local count = 1
	if payload and payload.count then
		count = tonumber(payload.count) or 1
	end
	count = math.max(1, count)

    local inv = self.Inventory.Data[pl]
    if not inv then
        inv = self:Inventory_GetItems(pl)
    end

    if action == "delete" then
		for i = #inv, 1, -1 do
			local it = inv[i]
			if it and tostring(it.ID or it.id) == tostring(id) then
				local cur = tonumber(it.Count) or 1
				local delcount = math.min(cur, count)
				local name = it.Name or id
				if count >= cur then
					table.remove(inv, i)
				else
					it.Count = cur - count
				end
				if self.Notify_Send then
					local msg = "Deleted " .. tostring(name)
					if delcount > 1 then
						msg = msg .. " x" .. tostring(delcount)
					end
					self:Notify_Send(pl, msg, 3)
				end
				break
			end
		end
    elseif action == "sell" then
		for i = #inv, 1, -1 do
			local it = inv[i]
			if it and tostring(it.ID or it.id) == tostring(id) then
				if it.Category == "Equipped" then
					break
				end

				local cur = tonumber(it.Count) or 1
				local sellcount = math.min(cur, count)
				local name = it.Name or id

				local defs = self.Inventory.ItemsData or {}
				local def = defs[id]
				local price = tonumber(def and (def.Price or def.Cost) or 10) or 10
				price = math.max(0, price)

				if self.Shop_AddCoins then
					self:Shop_AddCoins(pl, price * sellcount)
				end

				if sellcount >= cur then
					table.remove(inv, i)
				else
					it.Count = cur - sellcount
				end

				if self.Notify_Send then
					local msg = "Sold " .. tostring(name)
					if sellcount > 1 then
						msg = msg .. " x" .. tostring(sellcount)
					end
					msg = msg .. " (+" .. tostring(price * sellcount) .. ")"
					self:Notify_Send(pl, msg, 3)
				end
				break
			end
		end
    elseif action == "equip" then
        for _, it in ipairs(inv) do
            if it and tostring(it.ID or it.id) == tostring(id) then
                if not it.DefaultCategory then
                    it.DefaultCategory = it.Category or "Items"
                end
                it.Category = "Equipped"
				if self.Notify_Send then
					self:Notify_Send(pl, "Equipped " .. tostring(it.Name or id) .. ".", 3)
				end
                -- self:Inventory_DebugPrint("Equipped item", it.Name or it.ID, "for", pl:Nick())
            end
        end
    elseif action == "unequip" then
        for _, it in ipairs(inv) do
            if it and tostring(it.ID or it.id) == tostring(id) then
                local def = it.DefaultCategory or "Items"
                it.Category = def
				if self.Notify_Send then
					self:Notify_Send(pl, "Unequipped " .. tostring(it.Name or id) .. ".", 3)
				end
                -- self:Inventory_DebugPrint("Unequipped item", it.Name or it.ID, "for", pl:Nick())
            end
        end
    end

    self.Inventory.Data[pl] = inv

    if self.Inventory_SavePlayer then
        self:Inventory_SavePlayer(pl)
    end
end

function GM:Inventory_SendToClient(pl)
	if not IsValid(pl) then return end

	local items = self:Inventory_GetItems(pl)

	net.Start("zs_inventory_update")
		net.WriteTable(items)
	net.Send(pl)
end

net.Receive("zs_inventory_request", function(_, pl)
	local gm = GAMEMODE or GM
	if not gm or not gm.Inventory_SendToClient then return end

	gm:Inventory_SendToClient(pl)
end)

net.Receive("zs_inventory_action", function(_, pl)
	local gm = GAMEMODE or GM
	if not gm or not gm.Inventory_HandleClientRequest then return end

	local action = net.ReadString() or ""
	local itemid = net.ReadString() or ""
	local count = 1
	if net.BytesLeft() >= 2 then
		count = net.ReadUInt(16) or 1
	end

	gm:Inventory_HandleClientRequest(pl, action, {id = itemid, count = count})

	if gm.Inventory_SendToClient then
		gm:Inventory_SendToClient(pl)
	end
end)

-- Debug helper
function GM:Inventory_DebugPrint(...)
	-- print("[ZS Inventory]", ...)
end

function GM:Inventory_GiveEquippedForPlayer(pl)
	if not IsValid(pl) then return end

	local inv = self:Inventory_GetItems(pl)
	if not inv then return end

	for _, it in ipairs(inv) do
		if it and it.Category == "Equipped" then
			local basecat = it.DefaultCategory or it.Category or "Items"
			local name = it.Name or it.ID or "<no name>"

			if basecat == "Items" then
				local wepclass = it.GiveClass or it.WeaponClass or it.Weapon
				if wepclass and wepclass ~= "" then
					-- self:Inventory_DebugPrint("Give ITEM", name, "(", wepclass, ") to", pl:Nick())
					if not pl:HasWeapon(wepclass) then
						pl:Give(wepclass)
					end
				else
					-- self:Inventory_DebugPrint("ITEM has no weapon class:", name, "for", pl:Nick())
				end
			elseif basecat == "Perks" then
				-- self:Inventory_DebugPrint("Perks give:", name, "to", pl:Nick())
				-- print("Perks give:", name, pl:Nick())
			else
				local code = it.RunCode
				if isstring(code) and code ~= "" then
					-- self:Inventory_DebugPrint("RunCode for", name, "on", pl:Nick())
					local fn = CompileString(code, "InventoryRunCode_" .. tostring(it.ID or name), false)
					if isfunction(fn) then
						local env = {pl = pl}
						setmetatable(env, {__index = _G})
						setfenv(fn, env)
						local ok, err = pcall(fn)
						if not ok then
							-- self:Inventory_DebugPrint("RunCode error for", name, ":", err)
						end
					else
						-- self:Inventory_DebugPrint("RunCode compile error for", name, ":", tostring(fn))
					end
				else
					-- self:Inventory_DebugPrint("No RunCode for", name, "on", pl:Nick())
				end
			end
		end
	end
end

function GM:Inventory_GiveEquippedForAllPlayers()
	for _, pl in ipairs(player.GetAll()) do
		if IsValid(pl) and pl:Team() == TEAM_HUMAN and pl:Alive() then
			self:Inventory_GiveEquippedForPlayer(pl)
		end
	end
end

function GM:Inventory_SaveAll()
	self.Inventory.Storage = self.Inventory.Storage or {}
	file.CreateDir("inventory")
	local json = util.TableToJSON(self.Inventory.Storage, true)
	if not json then json = "{}" end
	file.Write("inventory/data.txt", json)
end

function GM:Inventory_LoadAll()
	self.Inventory.Storage = self.Inventory.Storage or {}
	file.CreateDir("inventory")
	if not file.Exists("inventory/data.txt", "DATA") then return end
	local json = file.Read("inventory/data.txt", "DATA") or "{}"
	local t = util.JSONToTable(json)
	if istable(t) then
		self.Inventory.Storage = t
	end
end

hook.Add("Initialize", "ZS_Inventory_LoadAll", function()
	if GAMEMODE and GAMEMODE.Inventory_LoadAll then
		GAMEMODE:Inventory_LoadAll()
	end
end)

hook.Add("PlayerInitialSpawn", "ZS_Inventory_LoadPlayer", function(pl)
	if GAMEMODE and GAMEMODE.Inventory_LoadPlayer then
		GAMEMODE:Inventory_LoadPlayer(pl)
	end
end)

hook.Add("PlayerDisconnected", "ZS_Inventory_SavePlayer", function(pl)
	if GAMEMODE and GAMEMODE.Inventory_SavePlayer then
		GAMEMODE:Inventory_SavePlayer(pl)
	end
end)

hook.Add("ShutDown", "ZS_Inventory_SaveAll", function()
	if GAMEMODE and GAMEMODE.Inventory_SaveAll then
		GAMEMODE:Inventory_SaveAll()
	end
end)

local function Inventory_FindPlayer(arg, caller)
	if not arg or arg == "" then
		if IsValid(caller) and caller:IsPlayer() then
			return caller
		end
		return nil
	end

	for _, pl in ipairs(player.GetAll()) do
		if string.find(string.lower(pl:Nick()), string.lower(arg), 1, true) then
			return pl
		end
		if pl:SteamID() == arg then
			return pl
	end
	end

	return nil
end

concommand.Add("zs_inv_add", function(ply, cmd, args)
	local id = args[1]
	if not id or id == "" then return end

	local tgt = Inventory_FindPlayer(args[2], ply)
	if not IsValid(tgt) then return end

	local count = tonumber(args[3] or 1) or 1
	if count < 1 then count = 1 end

	local gm = GAMEMODE or GM
	if not gm then return end

	local inv = gm:Inventory_GetItems(tgt)
	local found
	for _, it in ipairs(inv) do
		if it.ID == id then
			it.Count = (it.Count or 1) + count
			found = true
			break
		end
	end
	if not found then
		gm.Inventory.ItemsData = gm.Inventory.ItemsData or {}
		local def = gm.Inventory.ItemsData[id]
		if not def then return end
		local newitem = table.Copy(def)
		newitem.Count = count
		table.insert(inv, newitem)
	end

	gm.Inventory.Data[tgt] = inv
	if gm.Inventory_SavePlayer then
		gm:Inventory_SavePlayer(tgt)
	end
end)

concommand.Add("zs_inv_del", function(ply, cmd, args)
	local id = args[1]
	if not id or id == "" then return end

	local tgt = Inventory_FindPlayer(args[2], ply)
	if not IsValid(tgt) then return end

	local count = tonumber(args[3] or 1) or 1
	if count < 1 then count = 1 end

	local gm = GAMEMODE or GM
	if not gm then return end

	local inv = gm:Inventory_GetItems(tgt)
	for i = #inv, 1, -1 do
		local it = inv[i]
		if it.ID == id then
			local cur = it.Count or 1
			if cur <= count then
				table.remove(inv, i)
			else
				it.Count = cur - count
			end
			break
		end
	end

	gm.Inventory.Data[tgt] = inv
	if gm.Inventory_SavePlayer then
		gm:Inventory_SavePlayer(tgt)
	end
end)

concommand.Add("zs_inv_info", function(ply, cmd, args)
	local tgt = Inventory_FindPlayer(args[1], ply)
	if not IsValid(tgt) then return end

	local gm = GAMEMODE or GM
	if not gm then return end

	local inv = gm:Inventory_GetItems(tgt)
	print("[ZS Inventory] Inventory for", tgt:Nick(), "(", tgt:SteamID(), ")")
	for _, it in ipairs(inv) do
		print(" ", tostring(it.ID), "|", tostring(it.Name), "|", tostring(it.Category), "| x" .. tostring(it.Count or 1))
	end
end)
