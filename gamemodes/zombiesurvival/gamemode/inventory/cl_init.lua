local GM = GM or GAMEMODE

GM.Inventory = GM.Inventory or {}

GM.Inventory.Items = GM.Inventory.Items or {}

function GM:Inventory_SetItems(items)
	self.Inventory.Items = items or {}

	if self.InventoryPanel and self.InventoryPanel.UpdateItems then
		self.InventoryPanel:UpdateItems(self.Inventory.Items)
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

	if self.InventoryPanel and self.InventoryPanel:IsValid() then
		if self.InventoryPanel:IsVisible() then
			self.InventoryPanel:Close()
		else
			self.InventoryPanel:SetVisible(true)
			self.InventoryPanel:MakePopup()
		end

		return
	end

	local pnl = vgui.Create("ZSInventory")
	if not pnl or not pnl:IsValid() then return end

	self.InventoryPanel = pnl
	self.InventoryPanel:SetSize(ScrW() * 0.4, ScrH() * 0.5)
	self.InventoryPanel:Center()
	self.InventoryPanel:SetVisible(true)
	self.InventoryPanel:MakePopup()

	if self.InventoryPanel.UpdateItems then
		self.InventoryPanel:UpdateItems(self:Inventory_GetItems())
	end
end

concommand.Add("zs_inventory", function()
	local gm = GAMEMODE or GM
	if not gm or not gm.OpenInventory then return end

	gm:OpenInventory()
end)
