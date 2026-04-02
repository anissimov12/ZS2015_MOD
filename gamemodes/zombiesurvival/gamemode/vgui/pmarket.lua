local PANEL = {}

local function MarketThink(self)
	local mx, my = gui.MousePos()
	local x, y = self:GetPos()
	if mx < x - 16 or my < y - 16 or mx > x + self:GetWide() + 16 or my > y + self:GetTall() + 16 then
		self:SetVisible(false)
		surface.PlaySound("npc/dog/dog_idle3.wav")
	end
end

function PANEL:Init()
	self:SetTitle(" ")
	self:SetSizable(false)
	self:SetDeleteOnClose(false)
	self:SetDraggable(false)
	
	local wid = 480
	local hei = math.max(ScrH() * 0.5, 400)
	
	self:SetSize(wid, hei)
	
	if self.btnClose and self.btnClose:IsValid() then 
		self.btnClose:SetVisible(false) 
	end
	if self.btnMinim and self.btnMinim:IsValid() then 
		self.btnMinim:SetVisible(false) 
	end
	if self.btnMaxim and self.btnMaxim:IsValid() then 
		self.btnMaxim:SetVisible(false) 
	end
	
	self.Think = MarketThink

	self.TopSpace = vgui.Create("DPanel", self)
	self.TopSpace:SetWide(wid - 16)
	self.TopSpace.Paint = function(pnl, w, h)
		surface.SetDrawColor(30, 30, 30, 120)
		surface.DrawRect(0, 0, w, h)
	end

	local title = vgui.Create("DLabel", self.TopSpace)
	title:SetText("The Market")
	title:SetFont("ZSHUDFontSmall")
	title:SetTextColor(Color(255, 255, 255))
	title:SizeToContents()
	local tw = title:GetWide()
	title:SetPos((self.TopSpace:GetWide() - tw) / 2, 0)

	local subtitle = vgui.Create("DLabel", self.TopSpace)
	subtitle:SetText("Buy and manage your items")
	subtitle:SetFont("ZSHUDFontTiny")
	subtitle:SetTextColor(Color(255, 255, 255))
	subtitle:SizeToContents()
	local sw = subtitle:GetWide()
	subtitle:SetPos((self.TopSpace:GetWide() - sw) / 2, title:GetTall() + 4)

	local _, y = subtitle:GetPos()
	self.TopSpace:SetTall(y + subtitle:GetTall() + 4)
	self.TopSpace:SetPos(8, 8)

	self.BottomSpace = vgui.Create("DPanel", self)
	self.BottomSpace:SetWide(self.TopSpace:GetWide())
	self.BottomSpace.Paint = function(pnl, w, h)
		surface.SetDrawColor(30, 30, 30, 120)
		surface.DrawRect(0, 0, w, h)
	end

	self.CoinsIcon = vgui.Create("DImage", self.BottomSpace)
	self.CoinsIcon:SetImage("icon16/coins.png")
	self.CoinsIcon:SetSize(16, 16)
	self.CoinsIcon:SetPos(8, 4)

	self.CoinsLabel = vgui.Create("DLabel", self.BottomSpace)
	self.CoinsLabel:SetText("Loading...")
	self.CoinsLabel:SetFont("ZSHUDFontTiny")
	self.CoinsLabel:SetTextColor(Color(255, 255, 0))
	self.CoinsLabel:SetPos(28, 4)
	self.CoinsLabel:SizeToContents()

	self.BottomSpace:SetTall(self.CoinsLabel:GetTall() + 8)
	self.BottomSpace:SetPos(8, hei - 8 - self.BottomSpace:GetTall())

	local topx, topy = self.TopSpace:GetPos()
	local botx, boty = self.BottomSpace:GetPos()

	self.PropertySheet = vgui.Create("DPropertySheet", self)
	self.PropertySheet:SetSize(wid - 8, boty - topy - 8 - self.TopSpace:GetTall())
	self.PropertySheet:SetPos(4, topy + self.TopSpace:GetTall() + 4)

	self.InventoryPanel = vgui.Create("DPanel", self.PropertySheet)
	self.InventoryPanel.Paint = function() end
	self.PropertySheet:AddSheet("Inventory", self.InventoryPanel, "icon16/package.png", false, false)

	self.ShopPanel = vgui.Create("DPanel", self.PropertySheet)
	self.ShopPanel.Paint = function() end
	self.PropertySheet:AddSheet("Shop", self.ShopPanel, "icon16/cart.png", false, false)

	self:InitShop()
	self:InitInventory()
end

function PANEL:InitShop()
	self.ShopScroll = vgui.Create("DScrollPanel", self.ShopPanel)
	self.ShopScroll:Dock(FILL)

	self.ShopCategories = {}
	local catnames = {"Items", "Perks", "Other"}

	for _, name in ipairs(catnames) do
		local header = self.ShopScroll:Add("DPanel")
		header:Dock(TOP)
		header:DockMargin(0, 0, 0, 0)
		header:SetTall(35)
		header.Paint = function(pnl, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200))
			draw.SimpleText(name, "ZSHUDFontSmall", w * 0.5, h * 0.5, Color(220, 220, 220, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local layout = self.ShopScroll:Add("DPanel")
		layout:Dock(TOP)
		layout:DockMargin(8, 4, 8, 8)
		layout:DockPadding(0, 0, 0, 0)
		layout:SetTall(0)
		layout.Paint = function() end
		layout.PerformLayout = function(pnl)
			pnl:SizeToChildren(false, true)
		end

		self.ShopCategories[name] = {
			Header = header,
			ItemLayout = layout
		}
	end
end

function PANEL:InitInventory()
	self.InventoryScroll = vgui.Create("DScrollPanel", self.InventoryPanel)
	self.InventoryScroll:Dock(FILL)

	self.InventoryCategories = {}
	local catnames = {"Equipped", "Items", "Perks", "Other"}

	for _, name in ipairs(catnames) do
		local header = self.InventoryScroll:Add("DPanel")
		header:Dock(TOP)
		header:DockMargin(0, 0, 0, 0)
		header:SetTall(35)
		header.Paint = function(pnl, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200))
			draw.SimpleText(name, "ZSHUDFontSmall", w * 0.5, h * 0.5, Color(220, 220, 220, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local layout = self.InventoryScroll:Add("DPanel")
		layout:Dock(TOP)
		layout:DockMargin(8, 4, 8, 8)
		layout:DockPadding(0, 0, 0, 0)
		layout:SetTall(0)
		layout.Paint = function() end
		layout.PerformLayout = function(pnl)
			pnl:SizeToChildren(false, true)
		end

		self.InventoryCategories[name] = {
			Header = header,
			ItemLayout = layout
		}
	end
end

function PANEL:UpdateShop(catalog, coins)
	self.Catalog = catalog or {}
	self.Coins = tonumber(coins or 0) or 0

	if self.CoinsLabel and self.CoinsLabel.SetText then
		self.CoinsLabel:SetText("Coins: " .. tostring(self.Coins))
		self.CoinsLabel:SizeToContents()
	end

	if not self.ShopCategories then return end

	for _, cat in pairs(self.ShopCategories) do
		if cat.ItemLayout and cat.ItemLayout.Clear then
			cat.ItemLayout:Clear()
		end
		if cat.Header then
			cat.Header:SetVisible(false)
		end
		if cat.ItemLayout then
			cat.ItemLayout:SetVisible(false)
		end
	end

	local categoryCounts = {}
	for id, data in pairs(self.Catalog) do
		local catname = (data and (data.Category or data.DefaultCategory)) or "Items"
		categoryCounts[catname] = (categoryCounts[catname] or 0) + 1
	end

	for id, data in pairs(self.Catalog) do
		local catname = (data and (data.Category or data.DefaultCategory)) or "Items"
		local cat = self.ShopCategories[catname]
		if cat and cat.ItemLayout and cat.ItemLayout.Add then
			if cat.Header then
				cat.Header:SetVisible(true)
			end
			if cat.ItemLayout then
				cat.ItemLayout:SetVisible(true)
			end
			
			local item = cat.ItemLayout:Add("ZSShopItem")
			item:Dock(TOP)
			item:DockMargin(0, 0, 0, 4)
			item:SetTall(80)
			item:Setup(id, data, self.Coins)
		end
	end

	for _, cat in pairs(self.ShopCategories) do
		if cat.ItemLayout then
			cat.ItemLayout:SizeToChildren(false, true)
			cat.ItemLayout:InvalidateLayout(true)
		end
	end
end

function PANEL:UpdateInventory(items)
	self.Items = items or {}

	if not self.InventoryCategories then return end

	for _, cat in pairs(self.InventoryCategories) do
		if cat.ItemLayout and cat.ItemLayout.Clear then
			cat.ItemLayout:Clear()
		end
		if cat.Header then
			cat.Header:SetVisible(false)
		end
		if cat.ItemLayout then
			cat.ItemLayout:SetVisible(false)
		end
	end

	local categoryCounts = {}
	for _, data in ipairs(self.Items) do
		local catname = data.Category or "Items"
		categoryCounts[catname] = (categoryCounts[catname] or 0) + 1
	end

	for _, data in ipairs(self.Items) do
		local catname = data.Category or "Items"
		local cat = self.InventoryCategories[catname]
		if cat and cat.ItemLayout and cat.ItemLayout.Add then
			if cat.Header then
				cat.Header:SetVisible(true)
			end
			if cat.ItemLayout then
				cat.ItemLayout:SetVisible(true)
			end
			
			local item = cat.ItemLayout:Add("ZSInventoryItem")
			item:Dock(TOP)
			item:DockMargin(0, 0, 0, 4)
			item:SetTall(80)
			item:Setup(data)
		end
	end

	for _, cat in pairs(self.InventoryCategories) do
		if cat.ItemLayout then
			cat.ItemLayout:SizeToChildren(false, true)
			cat.ItemLayout:InvalidateLayout(true)
		end
	end
end

vgui.Register("ZSMarket", PANEL, "DFrame")

local SHOPITEM = {}

function SHOPITEM:Init()
	self.ItemID = nil
	self.Name = ""
	self.Description = ""
	self.Icon = nil
	self.Model = nil
	self.IconMat = nil
	self.ModelPanel = nil
	self.Category = ""
	self.Price = 10
	self.Coins = 0

	self:SetCursor("hand")
	
	self.GraphExpanded = false
	
	self.BuyButton = vgui.Create("DButton", self)
	self.BuyButton:SetText("Buy")
	self.BuyButton:SetWide(60)
	self.BuyButton.DoClick = function()
		local gm = GAMEMODE or GM
		if gm and gm.Shop_RequestBuy and self.ItemID then
			local amount = tonumber(self.AmountEntry:GetValue()) or 1
			amount = math.max(1, math.floor(amount))
			gm:Shop_RequestBuy(self.ItemID, amount)
		end
	end

	self.AmountEntry = vgui.Create("DTextEntry", self)
	self.AmountEntry:SetText("1")
	self.AmountEntry:SetWide(60)
	self.AmountEntry:SetNumeric(true)
	self.AmountEntry.OnEnter = function(pnl)
		self.BuyButton:DoClick()
	end
	
	self.GraphButton = vgui.Create("DButton", self)
	self.GraphButton:SetText("Graph")
	self.GraphButton:SetWide(60)
	self.GraphButton.DoClick = function()
		self.GraphExpanded = not self.GraphExpanded
		self:InvalidateLayout(true)
		if self:GetParent() and self:GetParent().InvalidateLayout then
			self:GetParent():InvalidateLayout(true)
		end
	end
	
	self.GraphPanel = vgui.Create("DPanel", self)
	self.GraphPanel:SetVisible(false)
	self.GraphPanel.Paint = function(pnl, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(15, 15, 15, 230))
		surface.SetDrawColor(60, 60, 60, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
		draw.SimpleText("Graph Panel (Coming Soon)", "ZSHUDFontTiny", w * 0.5, h * 0.5, Color(150, 150, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function SHOPITEM:Setup(id, data, coins)
	self.ItemID = tostring(id)
	self.Name = (data and data.Name) or tostring(id)
	self.Description = (data and data.Description) or ""
	self.Icon = data and data.Icon
	self.Model = data and data.Model
	self.Category = (data and (data.Category or data.DefaultCategory)) or "Items"
	self.Price = tonumber((data and (data.Price or data.Cost)) or 10) or 10
	self.Coins = tonumber(coins or 0) or 0

	if self.Icon then
		self.IconMat = Material(self.Icon)
	end

	if self.Model then
		if self.ModelPanel and self.ModelPanel:IsValid() then
			self.ModelPanel:Remove()
		end
		
		self.ModelPanel = vgui.Create("DModelPanel", self)
		self.ModelPanel:SetModel(self.Model)
		self.ModelPanel:SetFOV(55)
		self.ModelPanel:SetCamPos(Vector(35, 35, 35))
		self.ModelPanel:SetLookAt(Vector(0, 0, 0))
		self.ModelPanel:SetMouseInputEnabled(false)
		self.ModelPanel:SetKeyboardInputEnabled(false)
	end
end

function SHOPITEM:PerformLayout(w, h)
	local baseHeight = 80
	local iconSize = baseHeight - 8
	
	if self.ModelPanel and self.ModelPanel:IsValid() then
		self.ModelPanel:SetPos(6, 6)
		self.ModelPanel:SetSize(iconSize - 4, iconSize - 4)
	end
	
	local buttonX = w - 64
	self.BuyButton:SetPos(buttonX, 4)
	self.BuyButton:SetSize(60, 22)
	
	self.AmountEntry:SetPos(buttonX, 28)
	self.AmountEntry:SetSize(60, 22)

	self.GraphButton:SetPos(buttonX, 52)
	self.GraphButton:SetSize(60, 22)
	
	if self.GraphExpanded then
		self:SetTall(baseHeight + 120)
		self.GraphPanel:SetVisible(true)
		self.GraphPanel:SetPos(4, baseHeight + 4)
		self.GraphPanel:SetSize(w - 8, 112)
	else
		self:SetTall(baseHeight)
		self.GraphPanel:SetVisible(false)
	end
end

function SHOPITEM:Paint(w, h)
	local baseHeight = 80
	draw.RoundedBox(4, 0, 0, w, baseHeight, Color(20, 20, 20, 230))
	surface.SetDrawColor(80, 80, 80, 255)
	surface.DrawOutlinedRect(0, 0, w, baseHeight)

	local iconSize = baseHeight - 8
	
	draw.RoundedBox(4, 4, 4, iconSize, iconSize, Color(30, 30, 30, 230))
	surface.SetDrawColor(80, 80, 80, 255)
	surface.DrawOutlinedRect(4, 4, iconSize, iconSize)
	
	if self.IconMat and not self.Model then
		surface.SetMaterial(self.IconMat)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(6, 6, iconSize - 4, iconSize - 4)
	end
	
	local textX = iconSize + 8
	local nameY = 6
	draw.SimpleText(self.Name or "", "ZSHUDFontTiny", textX, nameY, Color(230, 230, 230, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	
	local dividerY = nameY + 18
	surface.SetDrawColor(80, 80, 80, 200)
	surface.DrawLine(textX, dividerY, w - 70, dividerY)
	
	local descY = dividerY + 4
	if self.Description and self.Description ~= "" then
		draw.SimpleText(self.Description, "ZSHUDFontTiny", textX, descY, Color(180, 180, 180, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
	
	local priceText = tostring(self.Price) .. " coins"
	local canAfford = (self.Coins >= (self.Price or 0))
	local priceY = baseHeight - 8
	draw.SimpleText(priceText, "ZSHUDFontTiny", w - 70, priceY, canAfford and Color(170, 255, 170, 255) or Color(255, 170, 170, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)

	return true
end

function SHOPITEM:OnMousePressed(mc)
end

vgui.Register("ZSShopItem", SHOPITEM, "DPanel")

local INVITEM = {}

function INVITEM:Init()
	self.ID = nil
	self.Name = ""
	self.Description = ""
	self.Icon = nil
	self.Model = nil
	self.IconMat = nil
	self.ModelPanel = nil
	self.Category = ""
	self.Count = 1
	self.Price = 0

	self:SetCursor("hand")
	
	self.EquipButton = vgui.Create("DButton", self)
	self.EquipButton:SetText("Equip")
	self.EquipButton:SetWide(60)
	self.EquipButton.DoClick = function()
		local gm = GAMEMODE or GM
		if gm and gm.Inventory_RequestAction and self.ID then
			if self.Category == "Equipped" then
				if self.Count and self.Count > 1 then
					Derma_StringRequest("Unequip", "Amount to unequip:", tostring(self.Count), function(text)
						local n = tonumber(text) or 0
						if n < 1 then return end
						gm:Inventory_RequestAction("unequip", tostring(self.ID), {count = n})
					end)
				else
					gm:Inventory_RequestAction("unequip", tostring(self.ID))
				end
			else
				if self.Count and self.Count > 1 then
					Derma_StringRequest("Equip", "Amount to equip:", tostring(self.Count), function(text)
						local n = tonumber(text) or 0
						if n < 1 then return end
						gm:Inventory_RequestAction("equip", tostring(self.ID), {count = n})
					end)
				else
					gm:Inventory_RequestAction("equip", tostring(self.ID))
				end
			end
		end
	end
	
	self.SellButton = vgui.Create("DButton", self)
	self.SellButton:SetText("Sell")
	self.SellButton:SetWide(60)
	self.SellButton.DoClick = function()
		Derma_StringRequest("Sell", "Amount to sell:", tostring(self.Count or 1), function(text)
			local n = tonumber(text) or 0
			if n < 1 then return end
			local gm = GAMEMODE or GM
			if gm and gm.Inventory_RequestAction and self.ID then
				gm:Inventory_RequestAction("sell", tostring(self.ID), {count = n})
			end
		end)
	end
	
	self.DropButton = vgui.Create("DButton", self)
	self.DropButton:SetText("Drop")
	self.DropButton:SetWide(60)
	self.DropButton.DoClick = function()
		Derma_StringRequest("Drop", "Amount to drop:", tostring(self.Count or 1), function(text)
			local n = tonumber(text) or 0
			if n < 1 then return end
			local gm = GAMEMODE or GM
			if gm and gm.Inventory_RequestAction and self.ID then
				gm:Inventory_RequestAction("delete", tostring(self.ID), {count = n})
			end
		end)
	end
end

function INVITEM:Setup(data)
	self.ID = data.ID or data.id or nil
	self.Name = data.Name or ""
	self.Description = data.Description or ""
	self.Icon = data.Icon
	self.Model = data.Model
	self.Category = data.Category or "Items"
	self.Count = data.Count or 1
	self.Price = data.Price or 0

	if self.Icon then
		self.IconMat = Material(self.Icon)
	end

	if self.Model then
		if self.ModelPanel and self.ModelPanel:IsValid() then
			self.ModelPanel:Remove()
		end
		
		self.ModelPanel = vgui.Create("DModelPanel", self)
		self.ModelPanel:SetModel(self.Model)
		self.ModelPanel:SetFOV(55)
		self.ModelPanel:SetCamPos(Vector(35, 35, 35))
		self.ModelPanel:SetLookAt(Vector(0, 0, 0))
		self.ModelPanel:SetMouseInputEnabled(false)
		self.ModelPanel:SetKeyboardInputEnabled(false)
	end
	
	if self.Category == "Equipped" then
		self.EquipButton:SetText("Unequip")
	else
		self.EquipButton:SetText("Equip")
	end
end

function INVITEM:PerformLayout(w, h)
	local iconSize = h - 8
	
	if self.ModelPanel and self.ModelPanel:IsValid() then
		self.ModelPanel:SetPos(6, 6)
		self.ModelPanel:SetSize(iconSize - 4, iconSize - 4)
	end
	
	local buttonX = w - 64
	self.EquipButton:SetPos(buttonX, 4)
	self.EquipButton:SetSize(60, 22)
	
	self.SellButton:SetPos(buttonX, 28)
	self.SellButton:SetSize(60, 22)
	
	self.DropButton:SetPos(buttonX, 52)
	self.DropButton:SetSize(60, 22)
end

function INVITEM:Paint(w, h)
	draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 230))
	surface.SetDrawColor(80, 80, 80, 255)
	surface.DrawOutlinedRect(0, 0, w, h)

	local iconSize = h - 8
	
	draw.RoundedBox(4, 4, 4, iconSize, iconSize, Color(30, 30, 30, 230))
	surface.SetDrawColor(80, 80, 80, 255)
	surface.DrawOutlinedRect(4, 4, iconSize, iconSize)
	
	if self.IconMat and not self.Model then
		surface.SetMaterial(self.IconMat)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(6, 6, iconSize - 4, iconSize - 4)
	end
	
	local textX = iconSize + 8
	local nameY = 6
	local nameText = self.Name or ""
	if self.Count and self.Count > 1 then
		nameText = nameText .. " x" .. tostring(self.Count)
	end
	draw.SimpleText(nameText, "ZSHUDFontTiny", textX, nameY, Color(230, 230, 230, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	
	local dividerY = nameY + 18
	surface.SetDrawColor(80, 80, 80, 200)
	surface.DrawLine(textX, dividerY, w - 70, dividerY)
	
	local descY = dividerY + 4
	if self.Description and self.Description ~= "" then
		draw.SimpleText(self.Description, "ZSHUDFontTiny", textX, descY, Color(180, 180, 180, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
	
	if self.Price and self.Price > 0 then
		local priceText = tostring(self.Price) .. " coins"
		local priceY = h - 8
		draw.SimpleText(priceText, "ZSHUDFontTiny", w - 70, priceY, Color(170, 255, 170, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
	end

	return true
end

function INVITEM:OnMousePressed(mc)
end

vgui.Register("ZSInventoryItem", INVITEM, "DPanel")
