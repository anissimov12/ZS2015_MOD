-- Кастомный лейбл с зачёркиванием
local PANEL = {}

function PANEL:Init()
	self:SetText("")
end

function PANEL:Paint(w, h)
	if self.m_Text and self.m_Font and self.m_Color then
		surface.SetFont(self.m_Font)
		local tw, th = surface.GetTextSize(self.m_Text)
		
		-- Рисуем текст
		draw.SimpleText(self.m_Text, self.m_Font, 0, 0, self.m_Color)
		
		-- Рисуем линию через текст (зачёркивание)
		surface.SetDrawColor(self.m_Color)
		surface.DrawLine(0, th / 2, tw, th / 2)
	end
end

function PANEL:SetTextEx(text, font, color)
	self.m_Text = text
	self.m_Font = font
	self.m_Color = color
	
	if font then
		surface.SetFont(font)
		local w, h = surface.GetTextSize(text or "")
		self:SetSize(w, h)
	end
end

vgui.Register("StrikethroughLabel", PANEL, "DPanel")

local function pointslabelThink(self)
	local points = MySelf:GetPoints()
	if self.m_LastPoints ~= points then
		self.m_LastPoints = points

		self:SetText("Points to spend: "..points)
		self:SizeToContents()
	end
end

hook.Add("Think", "PointsShopThink", function()
	local pan = GAMEMODE.m_PointsShop
	if pan and pan:Valid() and pan:IsVisible() then
		local newstate = not GAMEMODE:GetWaveActive()
		if newstate ~= pan.m_LastNearArsenalCrate then
			pan.m_LastNearArsenalCrate = newstate

			if newstate then
				pan.m_DiscountLabel:SetText(GAMEMODE.ArsenalCrateDiscountPercentage.."% discount for buying between waves!")
				pan.m_DiscountLabel:SetTextColor(COLOR_GREEN)
			else
				pan.m_DiscountLabel:SetText("All sales are final!")
				pan.m_DiscountLabel:SetTextColor(COLOR_GRAY)
			end

			pan.m_DiscountLabel:SizeToContents()
			pan.m_DiscountLabel:AlignRight(8)
		end

		local mx, my = gui.MousePos()
		local x, y = pan:GetPos()
		if mx < x - 16 or my < y - 16 or mx > x + pan:GetWide() + 16 or my > y + pan:GetTall() + 16 then
			pan:SetVisible(false)
			surface.PlaySound("npc/dog/dog_idle3.wav")
		end
	end
end)

local function PointsShopCenterMouse(self)
	local x, y = self:GetPos()
	local w, h = self:GetSize()
	gui.SetMousePos(x + w * 0.5, y + h * 0.5)
end

local ammonames = {
	["pistol"] = "pistolammo",
	["buckshot"] = "shotgunammo",
	["smg1"] = "smgammo",
	["ar2"] = "assaultrifleammo",
	["357"] = "rifleammo",
	["XBowBolt"] = "crossbowammo"
}

local warnedaboutammo = CreateClientConVar("_zs_warnedaboutammo", "0", true, false)
local function PurchaseDoClick(self)
	if not warnedaboutammo:GetBool() then
		local itemtab = FindItem(self.ID)
		if itemtab and itemtab.SWEP then
			local weptab = weapons.GetStored(itemtab.SWEP)
			if weptab and weptab.Primary and weptab.Primary.Ammo and ammonames[weptab.Primary.Ammo] then
				RunConsoleCommand("_zs_warnedaboutammo", "1")
				Derma_Message("Be sure to buy extra ammo. Weapons purchased do not contain any extra ammo!", "Warning")
			end
		end
	end

	RunConsoleCommand("zs_pointsshopbuy", self.ID)
end

local function BuyAmmoDoClick(self)
	RunConsoleCommand("zs_pointsshopbuy", "ps_"..self.AmmoType)
end

local function worthmenuDoClick()
	MakepWorth()
	GAMEMODE.m_PointsShop:Close()
end

local function ItemPanelThink(self)
    local itemtab = FindItem(self.ID)
    if itemtab then
        local isdiscount = GAMEMODE.m_PointsShop and GAMEMODE.m_PointsShop.m_LastNearArsenalCrate
        local basecost = itemtab.Worth
        local effectivecost = math.ceil(basecost * (isdiscount and GAMEMODE.ArsenalCrateMultiplier or 1))

        -- Update displayed price when discount state changes
        if isdiscount ~= self.m_LastDiscountState or effectivecost ~= self.m_LastPriceShown then
            self.m_LastDiscountState = isdiscount
            self.m_LastPriceShown = effectivecost

            if isdiscount then
                -- Показываем зачёркнутую старую цену (только цифру) и новую цену со скидкой
                self.m_OldPriceLabel:SetTextEx(tostring(basecost), "ZSHUDFontTiny", Color(120, 120, 120))
                self.m_OldPriceLabel:SetVisible(true)

                self.m_PriceLabel:SetText(tostring(effectivecost))
                self.m_PriceLabel:SetVisible(true)
                self.m_PriceLabel:SizeToContents()
                
                -- Показываем "Points" после цен
                if not self.m_PointsLabel then
                    self.m_PointsLabel = EasyLabel(self, " Points", "ZSHUDFontTiny", COLOR_WHITE)
                end
                self.m_PointsLabel:SetVisible(true)
            else
                -- Скрываем старую цену, показываем только обычную
                self.m_OldPriceLabel:SetVisible(false)
                self.m_PriceLabel:SetText(tostring(basecost).." Points")
                self.m_PriceLabel:SetVisible(true)
                self.m_PriceLabel:SizeToContents()
                
                if self.m_PointsLabel then
                    self.m_PointsLabel:SetVisible(false)
                end
            end

            self:InvalidateLayout(true)
        end

        -- Динамическая подсветка цен в зависимости от наличия очков
        local canafford = MySelf:GetPoints() >= effectivecost and not (itemtab.NoClassicMode and GAMEMODE:IsClassicMode())
        
        if isdiscount then
            -- Со скидкой: зелёная цена если хватает, красная если нет
            if canafford then
                self.m_PriceLabel:SetTextColor(Color(50, 255, 50))
                if self.m_PointsLabel then
                    self.m_PointsLabel:SetTextColor(COLOR_WHITE)
                end
            else
                self.m_PriceLabel:SetTextColor(COLOR_RED)
                if self.m_PointsLabel then
                    self.m_PointsLabel:SetTextColor(COLOR_RED)
                end
            end
        else
            -- Без скидки: белая цена если хватает, красная если нет
            if canafford then
                self.m_PriceLabel:SetTextColor(COLOR_WHITE)
            else
                self.m_PriceLabel:SetTextColor(COLOR_RED)
            end
        end

        local newstate = canafford
        if newstate ~= self.m_LastAbleToBuy then
            self.m_LastAbleToBuy = newstate
            if newstate then
                self:AlphaTo(255, 0.75, 0)
                self.m_NameLabel:SetTextColor(COLOR_WHITE)
                self.m_NameLabel:InvalidateLayout()
                self.m_BuyButton:SetImage("icon16/accept.png")
            else
                self:AlphaTo(90, 0.75, 0)
                self.m_NameLabel:SetTextColor(COLOR_RED)
                self.m_NameLabel:InvalidateLayout()
                self.m_BuyButton:SetImage("icon16/exclamation.png")
            end

            self.m_BuyButton:SizeToContents()
        end
    end
end

local function PointsShopThink(self)
	if GAMEMODE:GetWave() ~= self.m_LastWaveWarning and not GAMEMODE:GetWaveActive() and CurTime() >= GAMEMODE:GetWaveStart() - 10 and CurTime() > (self.m_LastWaveWarningTime or 0) + 11 then
		self.m_LastWaveWarning = GAMEMODE:GetWave()
		self.m_LastWaveWarningTime = CurTime()

		surface.PlaySound("ambient/alarms/klaxon1.wav")
		timer.Simple(0.6, function() surface.PlaySound("ambient/alarms/klaxon1.wav") end)
		timer.Simple(1.2, function() surface.PlaySound("ambient/alarms/klaxon1.wav") end)
		timer.Simple(2, function() surface.PlaySound("vo/npc/Barney/ba_hurryup.wav") end)
	end
end

function GM:OpenPointsShop()
	if self.m_PointsShop and self.m_PointsShop:Valid() then
		self.m_PointsShop:SetVisible(true)
		self.m_PointsShop:CenterMouse()
		return
	end

	local wid, hei = 480, math.max(ScrH() * 0.5, 400)

	local frame = vgui.Create("DFrame")
	frame:SetSize(wid, hei)
	frame:Center()
	frame:SetDeleteOnClose(false)
	frame:SetTitle(" ")
	frame:SetDraggable(false)
	if frame.btnClose and frame.btnClose:Valid() then frame.btnClose:SetVisible(false) end
	if frame.btnMinim and frame.btnMinim:Valid() then frame.btnMinim:SetVisible(false) end
	if frame.btnMaxim and frame.btnMaxim:Valid() then frame.btnMaxim:SetVisible(false) end
	frame.CenterMouse = PointsShopCenterMouse
	frame.Think = PointsShopThink
	self.m_PointsShop = frame

	local topspace = vgui.Create("DPanel", frame)
	topspace:SetWide(wid - 16)

	local title = EasyLabel(topspace, "The Points Shop", "ZSHUDFontSmall", COLOR_WHITE)
	title:CenterHorizontal()
	local subtitle = EasyLabel(topspace, "For all of your zombie apocalypse needs!", "ZSHUDFontTiny", COLOR_WHITE)
	subtitle:CenterHorizontal()
	subtitle:MoveBelow(title, 4)

	local _, y = subtitle:GetPos()
	topspace:SetTall(y + subtitle:GetTall() + 4)
	topspace:AlignTop(8)
	topspace:CenterHorizontal()

	local tt = vgui.Create("DImage", topspace)
	tt:SetImage("gui/info")
	tt:SizeToContents()
	tt:SetPos(8, 8)
	tt:SetMouseInputEnabled(true)
	tt:SetTooltip("This shop is armed with the QUIK - Anti-zombie backstab device.\nMove your mouse outside of the shop to quickly close it!")

	local wsb = EasyButton(topspace, "Worth Menu", 8, 4)
	wsb:AlignRight(8)
	wsb:AlignTop(8)
	wsb.DoClick = worthmenuDoClick


	local bottomspace = vgui.Create("DPanel", frame)
	bottomspace:SetWide(topspace:GetWide())

	local pointslabel = EasyLabel(bottomspace, "Points to spend: 0", "ZSHUDFontTiny", COLOR_GREEN)
	pointslabel:AlignTop(4)
	pointslabel:AlignLeft(8)
	pointslabel.Think = pointslabelThink

	local lab = EasyLabel(bottomspace, " ", "ZSHUDFontTiny")
	lab:AlignTop(4)
	lab:AlignRight(4)
	frame.m_DiscountLabel = lab

	local _, y = lab:GetPos()
	bottomspace:SetTall(y + lab:GetTall() + 4)
	bottomspace:AlignBottom(8)
	bottomspace:CenterHorizontal()

	local topx, topy = topspace:GetPos()
	local botx, boty = bottomspace:GetPos()

	local propertysheet = vgui.Create("DPropertySheet", frame)
	propertysheet:SetSize(wid - 8, boty - topy - 8 - topspace:GetTall())
	propertysheet:MoveBelow(topspace, 4)
	propertysheet:CenterHorizontal()

	local isclassic = GAMEMODE:IsClassicMode()

	-- Helper function to style scrollbar
	local function StyleScrollbar(list)
		if list.VBar then
			list.VBar:SetWide(12)
			list.VBar.Paint = function(self, w, h)
				draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 80))
			end
			list.VBar.btnGrip.Paint = function(self, w, h)
				draw.RoundedBox(2, 2, 0, w - 4, h, Color(60, 60, 60, 80))
			end
			list.VBar.btnUp.Paint = function(self, w, h)
				draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 80))
			end
			list.VBar.btnDown.Paint = function(self, w, h)
				draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40, 80))
			end
		end
	end

	-- Helper function to create an item panel
	local function CreateItemPanel(tab, i, list)
		local itempan = vgui.Create("DPanel")
		itempan:SetSize(list:GetWide(), 40)
		itempan.ID = tab.Signature or i
		itempan.Think = ItemPanelThink
		list:AddItem(itempan)

		-- model frame (слева)
		local mdlframe = vgui.Create("DPanel", itempan)
		mdlframe:SetSize(32, 32)
		mdlframe:SetPos(4, 4)

		local weptab = weapons.GetStored(tab.SWEP) or tab
		local mdl = tab.Model or (weptab and weptab.WorldModel)
		if mdl then
			local mdlpanel = vgui.Create("DModelPanel", mdlframe)
			mdlpanel:SetSize(mdlframe:GetSize())
			mdlpanel:SetModel(mdl)
			local mins, maxs = mdlpanel.Entity:GetRenderBounds()
			mdlpanel:SetCamPos(mins:Distance(maxs) * Vector(0.75, 0.75, 0.5))
			mdlpanel:SetLookAt((mins + maxs) / 2)
		end

		if tab.SWEP or tab.Countables then
			local counter = vgui.Create("ItemAmountCounter", itempan)
			counter:SetItemID(i)
		end

		local name = tab.Name or ""
		local namelab = EasyLabel(itempan, name, "ZSHUDFontSmall", COLOR_WHITE)
		itempan.m_NameLabel = namelab

		-- Создаём два лейбла: старая цена (зачёркнутая) и новая цена
		local oldpricelab = vgui.Create("StrikethroughLabel", itempan)
		oldpricelab:SetTextEx(tostring(tab.Worth).." Points", "ZSHUDFontTiny", Color(120, 120, 120))
		oldpricelab:SetVisible(false)
		itempan.m_OldPriceLabel = oldpricelab

		local pricelab = EasyLabel(itempan, tostring(tab.Worth).." Points", "ZSHUDFontTiny", COLOR_WHITE)
		itempan.m_PriceLabel = pricelab

		local button = vgui.Create("DImageButton", itempan)
		button:SetImage("icon16/lorry_add.png")
		button:SizeToContents()
		button:SetTooltip("Purchase "..name)
		button.ID = itempan.ID
		button.DoClick = PurchaseDoClick
		itempan.m_BuyButton = button

		local ammobutton
		if weptab and weptab.Primary then
			local ammotype = weptab.Primary.Ammo
			if ammonames[ammotype] then
				ammobutton = vgui.Create("DImageButton", itempan)
				ammobutton:SetImage("icon16/add.png")
				ammobutton:SizeToContents()
				ammobutton:SetTooltip("Purchase ammunition")
				ammobutton.AmmoType = ammonames[ammotype]
				ammobutton.DoClick = BuyAmmoDoClick
				itempan.m_AmmoButton = ammobutton
			end
		end

		if tab.Description then
			itempan:SetTooltip(tab.Description)
		end

		if (tab.NoClassicMode and isclassic) or (tab.NoZombieEscape and GAMEMODE.ZombieEscape) then
			itempan:SetAlpha(120)
		end

		function itempan:PerformLayout()
			self:SetWide(math.max( self:GetWide(), list:GetWide() ))

			local pw, ph = self:GetWide(), self:GetTall()
			
			-- Проверяем, виден ли скроллбар
			local scrollbaroffset = 0
			if list.VBar and list.VBar:IsVisible() then
				scrollbaroffset = 15
			end

			mdlframe:SetPos(4, 4)

			namelab:SetPos(42, math.floor(ph * 0.5 - namelab:GetTall() * 0.5))

			-- Позиционируем цены: если скидка, то зачёркнутая справа, новая слева от неё
			pricelab:SizeToContents()
			oldpricelab:SizeToContents()

			if oldpricelab:IsVisible() then
				-- Скидка активна: зачёркнутая цена справа, новая цена слева от неё
				local pointslab = itempan.m_PointsLabel
				if pointslab then
					pointslab:SizeToContents()
					pointslab:SetPos(pw - 8 - scrollbaroffset - pointslab:GetWide(), 4)
					oldpricelab:SetPos(pointslab:GetX() - 2 - oldpricelab:GetWide(), 4)
					pricelab:SetPos(oldpricelab:GetX() - 4 - pricelab:GetWide(), 4)
				end
			else
				-- Обычная цена справа
				pricelab:SetPos(pw - 8 - scrollbaroffset - pricelab:GetWide(), 4)
			end

			button:SizeToContents()
			button:SetPos(pw - 8 - scrollbaroffset - button:GetWide(), ph - 4 - button:GetTall())

			if ammobutton then
				ammobutton:SizeToContents()
				ammobutton:SetPos(button:GetX() - 2 - ammobutton:GetWide(), button:GetY())
			end
		end
	end

	for catid, catname in ipairs(GAMEMODE.ItemCategories) do
		local hasitems = false
		for i, tab in ipairs(GAMEMODE.Items) do
			if tab.Category == catid and tab.PointShop then
				hasitems = true
				break
			end
		end

		if hasitems then
			-- Special handling for Guns category with tiers
			if catid == ITEMCAT_GUNS then
				-- Create a container panel for the Guns category
				local gunscontainer = vgui.Create("DPanel", propertysheet)
				gunscontainer:SetPaintBackground(false)
				gunscontainer:SetSize(propertysheet:GetWide() - 16, propertysheet:GetTall() - 40)
				
				-- Create nested property sheet for tiers
				local tierpropertysheet = vgui.Create("DPropertySheet", gunscontainer)
				tierpropertysheet:Dock(FILL)
				
				-- Create tier sub-tabs for Guns
				for tier = 1, 6 do
					local hasitemsintier = false
					for i, tab in ipairs(GAMEMODE.Items) do
						if tab.Category == catid and tab.PointShop and tab.Tier == tier then
							hasitemsintier = true
							break
						end
					end

					if hasitemsintier then
						local list = vgui.Create("DPanelList", tierpropertysheet)
						list:SetPaintBackground(false)
						tierpropertysheet:AddSheet("Tier "..tier, list, GAMEMODE.ItemCategoryIcons[catid], false, false)
						list:EnableVerticalScrollbar(true)
						list:SetWide(tierpropertysheet:GetWide() - 16)
						list:SetSpacing(2)
						list:SetPadding(2)
						StyleScrollbar(list)

						for i, tab in ipairs(GAMEMODE.Items) do
							if tab.Category == catid and tab.PointShop and tab.Tier == tier then
								CreateItemPanel(tab, i, list)
							end
						end
					end
				end
				
				-- Add the Guns container as a sheet to the main propertysheet
				propertysheet:AddSheet(catname, gunscontainer, GAMEMODE.ItemCategoryIcons[catid], false, false)
			-- Special handling for Melee category with tiers
			elseif catid == ITEMCAT_MELEE then
				-- Create a container panel for the Melee category
				local meleecontainer = vgui.Create("DPanel", propertysheet)
				meleecontainer:SetPaintBackground(false)
				meleecontainer:SetSize(propertysheet:GetWide() - 16, propertysheet:GetTall() - 40)
				
				-- Create nested property sheet for tiers
				local tierpropertysheet = vgui.Create("DPropertySheet", meleecontainer)
				tierpropertysheet:Dock(FILL)
				
				-- Create tier sub-tabs for Melee
				for tier = 1, 5 do
					local hasitemsintier = false
					for i, tab in ipairs(GAMEMODE.Items) do
						if tab.Category == catid and tab.PointShop and tab.Tier == tier then
							hasitemsintier = true
							break
						end
					end

					if hasitemsintier then
						local list = vgui.Create("DPanelList", tierpropertysheet)
						list:SetPaintBackground(false)
						tierpropertysheet:AddSheet("Tier "..tier, list, GAMEMODE.ItemCategoryIcons[catid], false, false)
						list:EnableVerticalScrollbar(true)
						list:SetWide(tierpropertysheet:GetWide() - 16)
						list:SetSpacing(2)
						list:SetPadding(2)
						StyleScrollbar(list)

						for i, tab in ipairs(GAMEMODE.Items) do
							if tab.Category == catid and tab.PointShop and tab.Tier == tier then
								CreateItemPanel(tab, i, list)
							end
						end
					end
				end
				
				-- Add the Melee container as a sheet to the main propertysheet
				propertysheet:AddSheet(catname, meleecontainer, GAMEMODE.ItemCategoryIcons[catid], false, false)
			else
				-- Normal category handling
				local list = vgui.Create("DPanelList", propertysheet)
				list:SetPaintBackground(false)
				propertysheet:AddSheet(catname, list, GAMEMODE.ItemCategoryIcons[catid], false, false)
				list:EnableVerticalScrollbar(true)
				list:SetWide(propertysheet:GetWide() - 16)
				list:SetSpacing(2)
				list:SetPadding(2)
				StyleScrollbar(list)

				for i, tab in ipairs(GAMEMODE.Items) do
					if tab.Category == catid and tab.PointShop then
						CreateItemPanel(tab, i, list)
					end
				end
			end
		end
	end

	frame:MakePopup()
	frame:CenterMouse()
end
GM.OpenPointShop = GM.OpenPointsShop
