-- поместить в market/inv/cl_init.lua 

local GM = GM or GAMEMODE

GM.Inventory = GM.Inventory or {}

GM.Inventory.Items = GM.Inventory.Items or {}

function GM:Inventory_SetItems(items)
	self.Inventory.Items = items or {}

	if self.MarketPanel and self.MarketPanel.UpdateInventory then
		self.MarketPanel:UpdateInventory(self.Inventory.Items)
	end
end

net.Receive("zs_inventory_update", function()
	local items = net.ReadTable() or {}
	local gm = GAMEMODE or GM
	if not gm or not gm.Inventory_SetItems then return end

	gm:Inventory_SetItems(items)
end)

function GM:Inventory_GetItems()
	return self.Inventory.Items or {}
end

function GM:Inventory_RequestAction(action, itemid, extra)
	if not action or not itemid or action == "" or itemid == "" then return end

	local count = 1
	if istable(extra) and extra.count then
		count = tonumber(extra.count) or 1
	end
	count = math.max(1, count)

	net.Start("zs_inventory_action")
		net.WriteString(action)
		net.WriteString(itemid)
		net.WriteUInt(count, 16)
	net.SendToServer()
end

function GM:OpenInventory()
	if not vgui or not vgui.Create then return end

	net.Start("zs_inventory_request")
		net.SendToServer()

	if self.MarketPanel and self.MarketPanel:IsValid() then
		if self.MarketPanel:IsVisible() then
			self.MarketPanel:Close()
		else
			self.MarketPanel:SetVisible(true)
			self.MarketPanel:MakePopup()
			self.MarketPanel.PropertySheet:SwitchToName("Inventory")
		end
		return
	end

	local pnl = vgui.Create("ZSMarket")
	if not pnl or not pnl:IsValid() then return end

	self.MarketPanel = pnl
	self.MarketPanel:Center()
	self.MarketPanel:SetVisible(true)
	self.MarketPanel:MakePopup()

	if self.MarketPanel.UpdateShop then
		self.MarketPanel:UpdateShop(self.Shop.Catalog or {}, self.Shop.Coins or 0)
	end
	if self.MarketPanel.UpdateInventory then
		self.MarketPanel:UpdateInventory(self:Inventory_GetItems())
	end
end

concommand.Add("zs_inventory", function()
	local gm = GAMEMODE or GM
	if not gm or not gm.OpenInventory then return end

	gm:OpenInventory()
end)
