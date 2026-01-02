local GM = GM or GAMEMODE

GM.Shop = GM.Shop or {}
GM.Shop.Data = GM.Shop.Data or {}
GM.Shop.Storage = GM.Shop.Storage or {}

if SERVER then
	util.AddNetworkString("zs_shop_update")
	util.AddNetworkString("zs_shop_request")
	util.AddNetworkString("zs_shop_buy")
end

local function Shop_FindPlayer(arg, caller)
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

function GM:Shop_GetCoins(pl)
	if not IsValid(pl) then return 0 end
	return tonumber(self.Shop.Data[pl] or 0) or 0
end

function GM:Shop_SetCoins(pl, coins)
	if not IsValid(pl) then return end
	coins = math.max(0, tonumber(coins) or 0)
	self.Shop.Data[pl] = coins
	self:Shop_SavePlayer(pl)
	self:Shop_SendToClient(pl)
end

function GM:Shop_AddCoins(pl, amount)
	if not IsValid(pl) then return end
	amount = tonumber(amount) or 0
	if amount == 0 then return end
	if amount > 0 and self.Notify_Send then
		self:Notify_Send(pl, "+" .. tostring(amount) .. " coins", 3)
	end
	self:Shop_SetCoins(pl, self:Shop_GetCoins(pl) + amount)
end

function GM:Shop_LoadAll()
	self.Shop.Storage = self.Shop.Storage or {}
	file.CreateDir("shop")
	if not file.Exists("shop/data.txt", "DATA") then return end
	local json = file.Read("shop/data.txt", "DATA") or "{}"
	local t = util.JSONToTable(json)
	if istable(t) then
		self.Shop.Storage = t
	end
end

function GM:Shop_SaveAll()
	self.Shop.Storage = self.Shop.Storage or {}
	file.CreateDir("shop")
	local json = util.TableToJSON(self.Shop.Storage, true)
	if not json then json = "{}" end
	file.Write("shop/data.txt", json)
end

function GM:Shop_LoadPlayer(pl)
	if not IsValid(pl) then return end

	self.Shop.Storage = self.Shop.Storage or {}
	self.Shop.Data = self.Shop.Data or {}

	local sid = pl:SteamID()
	local stored = self.Shop.Storage[sid]
	local coins = 0
	if istable(stored) then
		coins = tonumber(stored.coins or stored.money or stored.balance or 0) or 0
	end

	self.Shop.Data[pl] = coins
	self:Shop_SendToClient(pl)
end

function GM:Shop_SavePlayer(pl)
	if not IsValid(pl) then return end

	self.Shop.Storage = self.Shop.Storage or {}

	local coins = tonumber(self.Shop.Data[pl] or 0) or 0
	self.Shop.Storage[pl:SteamID()] = {
		name = pl:Nick(),
		coins = coins
	}

	self:Shop_SaveAll()
end

function GM:Shop_GetCatalog()
	local inv = self.Inventory
	if not inv or not inv.ItemsData then return {} end
	return inv.ItemsData
end

function GM:Shop_SendToClient(pl)
	if not IsValid(pl) then return end

	local coins = self:Shop_GetCoins(pl)
	local catalog = self:Shop_GetCatalog()

	net.Start("zs_shop_update")
		net.WriteUInt(math.max(0, coins), 32)
		net.WriteTable(catalog)
	net.Send(pl)
end

function GM:Shop_HandleBuy(pl, itemid, count)
	if not IsValid(pl) then return end
	itemid = tostring(itemid or "")
	if itemid == "" then return end
	count = math.max(1, tonumber(count) or 1)

	local catalog = self:Shop_GetCatalog()
	local def = catalog[itemid]
	if not def then return end

	local price = tonumber(def.Price or def.Cost or 10) or 10
	price = math.max(0, price)
	local total = price * count

	local coins = self:Shop_GetCoins(pl)
	if coins < total then
		if self.Notify_Send then
			self:Notify_Send(pl, "Not enough coins.", 3)
		end
		return
	end

	self:Shop_SetCoins(pl, coins - total)

	if self.Inventory_GiveItem then
		self:Inventory_GiveItem(pl, itemid, {count = count})
	end

	if self.Notify_Send then
		local name = def.Name or itemid
		local msg = "Bought " .. tostring(name)
		if count > 1 then
			msg = msg .. " x" .. tostring(count)
		end
		msg = msg .. " (-" .. tostring(total) .. ")"
		self:Notify_Send(pl, msg, 3)
	end
end

net.Receive("zs_shop_request", function(_, pl)
	local gm = GAMEMODE or GM
	if not gm or not gm.Shop_SendToClient then return end
	gm:Shop_SendToClient(pl)
end)

net.Receive("zs_shop_buy", function(_, pl)
	local gm = GAMEMODE or GM
	if not gm or not gm.Shop_HandleBuy then return end

	local itemid = net.ReadString() or ""
	local count = net.ReadUInt(16) or 1

	gm:Shop_HandleBuy(pl, itemid, count)
end)

hook.Add("Initialize", "ZS_Shop_LoadAll", function()
	if GAMEMODE and GAMEMODE.Shop_LoadAll then
		GAMEMODE:Shop_LoadAll()
	end
end)

hook.Add("PlayerInitialSpawn", "ZS_Shop_LoadPlayer", function(pl)
	if GAMEMODE and GAMEMODE.Shop_LoadPlayer then
		GAMEMODE:Shop_LoadPlayer(pl)
	end
end)

hook.Add("PlayerDisconnected", "ZS_Shop_SavePlayer", function(pl)
	if GAMEMODE and GAMEMODE.Shop_SavePlayer then
		GAMEMODE:Shop_SavePlayer(pl)
	end
end)

hook.Add("ShutDown", "ZS_Shop_SaveAll", function()
	if GAMEMODE and GAMEMODE.Shop_SaveAll then
		GAMEMODE:Shop_SaveAll()
	end
end)

concommand.Add("zs_shop_add", function(ply, cmd, args)
	local amount = tonumber(args[1] or 0) or 0
	if amount == 0 then return end

	local tgt = Shop_FindPlayer(args[2], ply)
	if not IsValid(tgt) then return end

	local gm = GAMEMODE or GM
	if not gm or not gm.Shop_AddCoins then return end

	gm:Shop_AddCoins(tgt, amount)
end)

concommand.Add("zs_shop_set", function(ply, cmd, args)
	local amount = tonumber(args[1] or 0) or 0

	local tgt = Shop_FindPlayer(args[2], ply)
	if not IsValid(tgt) then return end

	local gm = GAMEMODE or GM
	if not gm or not gm.Shop_SetCoins then return end

	gm:Shop_SetCoins(tgt, amount)
end)

concommand.Add("zs_shop_info", function(ply, cmd, args)
	local tgt = Shop_FindPlayer(args[1], ply)
	if not IsValid(tgt) then return end

	local gm = GAMEMODE or GM
	if not gm or not gm.Shop_GetCoins then return end

	print("[ZS Shop] Coins for", tgt:Nick(), "(", tgt:SteamID(), "):", gm:Shop_GetCoins(tgt))
end)
