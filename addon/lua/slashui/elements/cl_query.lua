local PANEL = {}

AccessorFunc(PANEL, "custom_width", "CustomWidth", FORCE_NUMBER)
AccessorFunc(PANEL, "text", "Text")

SlashUI:CreateFont("SlashUI.Query.Text", 18)
SlashUI:CreateFont("SlashUI.Query.Button", 18)
SlashUI:CreateFont("SlashUI.Query.Option", 20)

function PANEL:Init()
    self.text = ""

    self.onAccept = function() end
    self.onDecline = function() end

    self.background.Paint = function(pnl, w, h)
        local x, y = pnl:LocalToScreen(0, 0)
    
        SlashUI:DrawBlur(pnl, 4)
        draw.RoundedBox(4, 0, 0, w, h, ColorAlpha(SlashUI.Theme.Background, 150))
        
        SlashUI:DrawShadowText(self:GetText(), "Slash20", w/2, 55, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, 255)
    end

    self.background.input = self.background:Add("SlashUI.TextEntry")
    self.background.input:SetVisible(false)

    self.background.option = self.background:Add("DButton")
    self.background.option:SetVisible(false)
    self.background.option:SetText("")
    self.background.option.Paint = function(pnl, w, h)
        SlashUI:DrawRoundedBox(6, 0, 0, w, h, SlashUI.Theme.Navbar)

        local text = pnl.Text or "None Selected"
        SlashUI:DrawShadowText(text, "SlashUI.Query.Option", w / 2, h / 2, Color(184, 184, 184), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, 150)
    end
    self.background.option.DoClick = function(pnl)
        if IsValid(pnl.Dropdown) then return end

        pnl.Dropdown = vgui.Create("SlashUI.PlayerDropdown")
        pnl.Dropdown:SetParentPanel(pnl)
        pnl.Dropdown:SetData(self.optionData)
        pnl.Dropdown:SetDrawOnTop(true)
        local x, y = pnl:LocalToScreen()
        pnl.Dropdown:SetPos(x, y + pnl:GetTall())
        pnl.Dropdown:MakePopup()
        pnl.Dropdown.OnSelected = function(dropdown, sid64)

            if (!sid64) then return end
            local ply = player.GetBySteamID64(sid64)
            pnl.Text = ply:Nick()

            self.background.option.sid64 = sid64
        end
    end
    self.background.option.OnRemove = function(pnl)
        if IsValid(pnl.Dropdown) then
            pnl.Dropdown:Remove()
        end
    end

    self.background.accept = self.background:Add("DButton")
    self.background.accept:SetText("Accept")
    self.background.accept:SetFont("SlashUI.Query.Button")
    self.background.accept:SetTextColor(Color(21, 21, 21))
    self.background.accept.Paint = function(pnl, w, h)
        draw.RoundedBox(6, 0, 0, w, h, SlashUI.Theme.Green)
    end
    self.background.accept.DoClick = function(pnl)
        self:onAccept(pnl, self.background.input:GetText(), self.background.option.sid64)
        self:Remove()
    end

    self.background.decline = self.background:Add("DButton")
    self.background.decline:SetText("Decline")
    self.background.decline:SetFont("SlashUI.Query.Button")
    self.background.decline:SetTextColor(Color(145, 145, 145))
    self.background.decline.Paint = function(pnl, w, h)
        draw.RoundedBox(6, 0, 0, w, h, SlashUI.Theme.Navbar)
        draw.RoundedBox(6, 2, 2, w - 4, h - 4, SlashUI.Theme.Background)
    end
    self.background.decline.DoClick = function(pnl)
        self:onDecline(pnl, self.background.input:GetText(), self.background.option.sid64)
        self:Remove()
    end

    self.background.resizeBtn:Remove()
end

function PANEL:PerformLayout(w, h)
    if (!self:GetCustomWidth()) then
        surface.SetFont("Slash20")
        local tw = surface.GetTextSize(self:GetText())
        self:SetBackgroundWidth(tw + 32)
    else
        self:SetBackgroundWidth(self:GetCustomWidth())
    end

    self.BaseClass.PerformLayout(self, w, h)

    self.background.accept:SizeToContentsX(32)
    self.background.accept:SizeToContentsY(16)
    self.background.decline:SizeToContentsX(32)
    self.background.decline:SizeToContentsY(16)

    if self.background.input:IsVisible() then
        self.background.input:SetSize(math.max(self.background.accept:GetWide() + self.background.decline:GetWide() + 8, self.background:GetWide() * 0.75), 32)
        self.background.input:SetPos(0, 88)
        self.background.input:CenterHorizontal()
    end

    if self.background.option:IsVisible() then
        self.background.option:SetSize(math.max(self.background.accept:GetWide() + self.background.decline:GetWide() + 8, self.background:GetWide() * 0.75), 32)

        local inputVisible = self.background.input:IsVisible()
        self.background.option:SetPos(0, 88 + (inputVisible and 44 or 0))
        self.background.option:CenterHorizontal()
    end

    local y = self.background:GetTall() - self.background.accept:GetTall() - 16
    self.background.accept:SetPos(self.background:GetWide() / 2 - self.background.accept:GetWide() / 2 - self.background.decline:GetWide() / 2 - 4, y)
    self.background.decline:SetPos(self.background:GetWide() / 2 + self.background.accept:GetWide() / 2 - self.background.decline:GetWide() / 2 + 4, y)
end

function PANEL:SetInput(str, placeholder, numeric)
    self.background.input:SetVisible(true)
    self.background.input:SetText(str)
    self.background.input:SetPlaceholder(placeholder)
    self.background.input.textentry:SetNumeric(numeric)
end

function PANEL:SetOption(tbl)
    self.background.option:SetVisible(true)
    self.optionData = tbl
end

function PANEL:SetAccept(text, func)
    self.background.accept:SetText(text)
    self.onAccept = func
end

function PANEL:SetDecline(text, func)
    self.background.decline:SetText(text)
    self.onDecline = func
end

vgui.Register("SlashUI.Query", PANEL, "SlashUI.Popup")

function SlashUI:SimpleQuery(title, text, yesText, yesFunc, noText, noFunc)
    local queryMenu = vgui.Create("SlashUI.Query")
    queryMenu:SetSize(ScrW(), ScrH())
    queryMenu:SetBackgroundHeight(140)

    queryMenu:SetTitle(title or "Title")
    queryMenu:SetText(text or "Text")

    queryMenu:SetAccept(yesText or "Yes", yesFunc or (function() end))
    queryMenu:SetDecline(noText or "No", noFunc or (function() end))

    queryMenu:MakePopup()

    return queryMenu
end