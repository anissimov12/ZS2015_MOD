-- поместить в market/shp/cl_init.lua 

local GM = GM or GAMEMODE

GM.Shop = GM.Shop or {}
GM.Shop.Coins = GM.Shop.Coins or 0
GM.Shop.Catalog = GM.Shop.Catalog or {}

function GM:Shop_SetData(coins, catalog)
	self.Shop.Coins = tonumber(coins or 0) or 0
	self.Shop.Catalog = catalog or {}

	if self.MarketPanel and self.MarketPanel.UpdateShop then
		self.MarketPanel:UpdateShop(self.Shop.Catalog, self.Shop.Coins)
	end
end

net.Receive("zs_shop_update", function()
	local coins = net.ReadUInt(32) or 0
	local catalog = net.ReadTable() or {}

	local gm = GAMEMODE or GM
	if not gm or not gm.Shop_SetData then return end
	gm:Shop_SetData(coins, catalog)
end)

function GM:Shop_RequestUpdate()
	net.Start("zs_shop_request")
	net.SendToServer()
end

function GM:Shop_RequestBuy(itemid, count)
	itemid = tostring(itemid or "")
	if itemid == "" then return end
	count = math.max(1, tonumber(count) or 1)

	net.Start("zs_shop_buy")
		net.WriteString(itemid)
		net.WriteUInt(count, 16)
	net.SendToServer()
end

function GM:OpenShop()
	if not vgui or not vgui.Create then return end

	self:Shop_RequestUpdate()

	if self.MarketPanel and self.MarketPanel:IsValid() then
		if self.MarketPanel:IsVisible() then
			self.MarketPanel:Close()
		else
			self.MarketPanel:SetVisible(true)
			self.MarketPanel:MakePopup()
			self.MarketPanel.PropertySheet:SwitchToName("Shop")
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
		self.MarketPanel:UpdateInventory(self.Inventory.Items or {})
	end
end

concommand.Add("zs_shop", function()
	local gm = GAMEMODE or GM
	if not gm or not gm.OpenShop then return end
	gm:OpenShop()
end)
