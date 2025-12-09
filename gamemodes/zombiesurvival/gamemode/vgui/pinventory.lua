local PANEL = {}

function PANEL:UpdateItems(items)
    self.Items = items or {}

    if not self.Categories then return end

    for _, cat in pairs(self.Categories) do
        if cat.ItemLayout and cat.ItemLayout.Clear then
            cat.ItemLayout:Clear()
        end
    end

    for _, data in ipairs(self.Items) do
        local catname = data.Category or "Items"
        local cat = self.Categories[catname]
        if cat and cat.ItemLayout and cat.ItemLayout.Add then
            local item = cat.ItemLayout:Add("ZSInventoryItem")
            item:SetSize(125, 125)
            item:Setup(data)
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
    self.Items = {}
    self.Categories = {}

    self:SetTitle("Inventory")
    self:SetSizable(false)
    self:DockPadding(8, 32, 8, 8)

    self.Scroll = vgui.Create("DScrollPanel", self)
    self.Scroll:Dock(FILL)

    local catnames = {"Equipped", "Items", "Perks", "Other"}

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

    self:UpdateItems(self.Items)
end

local ITEM = {}

function ITEM:Init()
    self.ID = nil
    self.Name = ""

    self.Icon = nil
    self.Model = nil
    self.IconMat = nil
    self.ModelPanel = nil
    self.Category = ""
    self.Count = 1

    self:SetCursor("hand")
end

function ITEM:Setup(data)
    self.ID = data.ID or data.id or nil
    self.Name = data.Name or ""
    self.Icon = data.Icon
    self.Model = data.Model
    self.Category = data.Category or "Items"
    self.Count = data.Count or 1

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

    local name = self.Name or ""
    if #name > 15 then
        local first = string.sub(name, 1, 10)
        local second = string.sub(name, 11)
        draw.SimpleText(first, "ZSHUDFontTiny", w * 0.5, h - 14, Color(230, 230, 230, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(second, "ZSHUDFontTiny", w * 0.5, h - 2, Color(230, 230, 230, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    else
        draw.SimpleText(name, "ZSHUDFontTiny", w * 0.5, h - 4, Color(230, 230, 230, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    end

    if self.Count and self.Count > 1 then
        draw.SimpleText("x" .. tostring(self.Count), "ZSHUDFontTiny", w - 4, 4, Color(230, 230, 230, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end
    return true
end

function ITEM:OnMousePressed(mc)
    if mc ~= MOUSE_LEFT and mc ~= MOUSE_RIGHT then return end

    local gm = GAMEMODE or GM
    if not gm or not gm.Inventory_RequestAction then return end
    if not self.ID then return end

    local menu = DermaMenu()

    if self.Category == "Equipped" then
        menu:AddOption("Unequip", function()
            gm:Inventory_RequestAction("unequip", tostring(self.ID))
        end)
    else
        menu:AddOption("Equip", function()
            gm:Inventory_RequestAction("equip", tostring(self.ID))
        end)
    end
    menu:AddOption("Delete", function()
        local overlay = vgui.Create("DFrame")
        if not overlay or not overlay:IsValid() then return end
        overlay:SetTitle("")
        overlay:ShowCloseButton(false)
        overlay:SetDraggable(false)
        overlay:SetSize(ScrW(), ScrH())
        overlay:SetPos(0, 0)
        overlay:MakePopup()
        overlay.Paint = function(pnl, w, h)
            surface.SetDrawColor(0, 0, 0, 180)
            surface.DrawRect(0, 0, w, h)
        end

        local box = vgui.Create("DPanel", overlay)
        if not box or not box:IsValid() then overlay:Remove() return end
        box:SetSize(320, 140)
        box:Center()
        box.Paint = function(pnl, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(15, 15, 15, 240))
            surface.SetDrawColor(80, 80, 80, 255)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        local lbl = vgui.Create("DLabel", box)
        lbl:SetText("Delete item: " .. (self.Name or tostring(self.ID)) .. "?")
        lbl:SetFont("ZSHUDFontTiny")
        lbl:SetTextColor(Color(230, 230, 230))
        lbl:SizeToContents()
        lbl:CenterHorizontal()
        lbl:SetPos(lbl.x, 35)

        local btnYes = vgui.Create("DButton", box)
        btnYes:SetText("Yes")
        btnYes:SetSize(120, 30)
        btnYes:SetPos(40, 90)
        btnYes.DoClick = function()
            if IsValid(overlay) then overlay:Remove() end
            gm:Inventory_RequestAction("delete", tostring(self.ID))
        end

        local btnNo = vgui.Create("DButton", box)
        btnNo:SetText("No")
        btnNo:SetSize(120, 30)
        btnNo:SetPos(320 - 40 - 120, 90)
        btnNo.DoClick = function()
            if IsValid(overlay) then overlay:Remove() end
        end
    end)
    menu:Open()
end

vgui.Register("ZSInventoryItem", ITEM, "DPanel")
vgui.Register("ZSInventory", PANEL, "DFrame")