local PANEL = {}

function PANEL:UpdateItems(catalog, coins)
	self.Catalog = catalog or {}
	self.Coins = tonumber(coins or 0) or 0

	if self.CoinsLabel and self.CoinsLabel.SetText then
		self.CoinsLabel:SetText(tostring(self.Coins))
		self.CoinsLabel:SizeToContents()
	end

	if not self.Categories then return end

	for _, cat in pairs(self.Categories) do
		if cat.ItemLayout and cat.ItemLayout.Clear then
			cat.ItemLayout:Clear()
		end
	end

	for id, data in pairs(self.Catalog) do
		local catname = (data and (data.Category or data.DefaultCategory)) or "Items"
		local cat = self.Categories[catname]
		if cat and cat.ItemLayout and cat.ItemLayout.Add then
			local item = cat.ItemLayout:Add("ZSShopItem")
			item:SetSize(125, 125)
			item:Setup(id, data, self.Coins)
		end
	end

	for _, cat in pairs(self.Categories) do
		if cat.ItemLayout then
			cat.ItemLayout:InvalidateLayout(true)
			cat.ItemLayout:SizeToChildren(true, true)
		end
	end
end

function PANEL:Init()
	self.Catalog = {}
	self.Categories = {}
	self.Coins = 0

	self:SetTitle("Shop")
	self:SetSizable(false)
	self:DockPadding(8, 32, 8, 8)

	self.TopBar = vgui.Create("DPanel", self)
	self.TopBar:Dock(TOP)
	self.TopBar:SetTall(28)
	self.TopBar.Paint = function() end

	local invbut = vgui.Create("DButton", self.TopBar)
	invbut:SetText("Inventory")
	invbut:SetWide(90)
	invbut:Dock(LEFT)
	invbut:DockMargin(0, 0, 8, 0)
	invbut.DoClick = function()
		local gm = GAMEMODE or GM
		if gm and gm.OpenInventory then
			if gm.ShopPanel and gm.ShopPanel:IsValid() then
				gm.ShopPanel:Close()
			end
			gm:OpenInventory()
		end
	end

	local shopbut = vgui.Create("DButton", self.TopBar)
	shopbut:SetText("Shop")
	shopbut:SetWide(90)
	shopbut:Dock(LEFT)
	shopbut.DoClick = function() end

	self.CoinsLabel = vgui.Create("DLabel", self.TopBar)
	self.CoinsLabel:SetText("0")
	self.CoinsLabel:SetFont("ZSHUDFontSmall")
	self.CoinsLabel:SetTextColor(Color(220, 220, 220, 230))
	self.CoinsLabel:Dock(RIGHT)
	self.CoinsLabel:DockMargin(6, 4, 4, 0)
	self.CoinsLabel:SizeToContents()

	self.CoinsIcon = vgui.Create("DImage", self.TopBar)
	self.CoinsIcon:SetImage("icon16/coins.png")
	self.CoinsIcon:SetSize(16, 16)
	self.CoinsIcon:Dock(RIGHT)
	self.CoinsIcon:DockMargin(0, 6, 4, 0)

	self.Scroll = vgui.Create("DScrollPanel", self)
	self.Scroll:Dock(FILL)

	local catnames = {"Items", "Perks", "Other"}

	for _, name in ipairs(catnames) do
		local header = self.Scroll:Add("DPanel")
		header:Dock(TOP)
		header:DockMargin(0, 0, 0, 0)
		header:SetTall(35)
		header.Paint = function(pnl, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 200))
			draw.SimpleText(name, "ZSHUDFontSmall", w * 0.5, h * 0.5, Color(220, 220, 220, 230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local layout = self.Scroll:Add("DIconLayout")
		layout:Dock(TOP)
		layout:DockMargin(8, 4, 8, 8)
		layout:SetSpaceX(6)
		layout:SetSpaceY(6)

		self.Categories[name] = {
			Header = header,
			ItemLayout = layout
		}
	end

	self:UpdateItems(self.Catalog, self.Coins)
end

local ITEM = {}

function ITEM:Init()
	self.ItemID = nil
	self.Name = ""
	self.Icon = nil
	self.Model = nil
	self.IconMat = nil
	self.ModelPanel = nil
	self.Category = ""
	self.Price = 10
	self.Coins = 0

	self:SetCursor("hand")
end

function ITEM:Setup(id, data, coins)
	self.ItemID = tostring(id)
	self.Name = (data and data.Name) or tostring(id)
	self.Icon = data and data.Icon
	self.Model = data and data.Model
	self.Category = (data and (data.Category or data.DefaultCategory)) or "Items"
	self.Price = tonumber((data and (data.Price or data.Cost)) or 10) or 10
	self.Coins = tonumber(coins or 0) or 0

	if self.Icon then
		self.IconMat = Material(self.Icon)
	end

	if self.Model then
		self.ModelPanel = vgui.Create("DModelPanel", self)
		self.ModelPanel:SetModel(self.Model)
		self.ModelPanel:SetFOV(55)
		self.ModelPanel:SetCamPos(Vector(35, 35, 35))
		self.ModelPanel:SetLookAt(Vector(0, 0, 0))

		self.ModelPanel:SetMouseInputEnabled(false)
		self.ModelPanel:SetKeyboardInputEnabled(false)
	end
end

function ITEM:PerformLayout(w, h)
	if self.ModelPanel and self.ModelPanel:IsValid() then
		self.ModelPanel:SetPos(0, 0)
		self.ModelPanel:SetSize(w, h)
	end
end

function ITEM:Paint(w, h)
	draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 230))
	surface.SetDrawColor(80, 80, 80, 255)
	surface.DrawOutlinedRect(0, 0, w, h)

	if self.IconMat and not self.Model then
		surface.SetMaterial(self.IconMat)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(8, 8, w - 16, h - 24)
	end

	draw.SimpleText(self.Name or "", "ZSHUDFontTiny", w * 0.5, h - 28, Color(230, 230, 230, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	local priceText = "Price: " .. tostring(self.Price)
	local canAfford = (self.Coins >= (self.Price or 0))
	draw.SimpleText(priceText, "ZSHUDFontTiny", w * 0.5, h - 14, canAfford and Color(170, 255, 170, 255) or Color(255, 170, 170, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

	return true
end

function ITEM:OnMousePressed(mc)
	if mc ~= MOUSE_LEFT and mc ~= MOUSE_RIGHT then return end

	local gm = GAMEMODE or GM
	if not gm or not gm.Shop_RequestBuy then return end
	if not self.ItemID then return end

	local menu = DermaMenu()
	menu:AddOption("Buy", function()
		gm:Shop_RequestBuy(self.ItemID, 1)
	end)
	menu:Open()
end

vgui.Register("ZSShopItem", ITEM, "DPanel")
vgui.Register("ZSShop", PANEL, "DFrame")
