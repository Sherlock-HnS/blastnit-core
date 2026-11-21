local PANEL = {}

AccessorFunc(PANEL, "roundness", "Roundness", FORCE_NUMBER)
AccessorFunc(PANEL, "pad", "Pad", FORCE_NUMBER)
AccessorFunc(PANEL, "outcol", "OutlineColor")

function PANEL:Init()
    self.roundness = 4
    self.pad = 0
    self.outcol = color_white

    self.avatar = vgui.Create("AvatarImage", self)
    self.avatar:SetPaintedManually(true)
end

function PANEL:PerformLayout(w, h)
    local dock = self:GetDock()

    if dock == LEFT or dock == RIGHT then
        self:SetWide(h)
    elseif dock == TOP or dock == BOTTOM then
        self:SetTall(w)
    end

    self.avatar:SetSize(w, h)
end

function PANEL:SetPlayer(ply, size)
    self.avatar:SetPlayer(ply, size)
end

function PANEL:SetSteamID(sid64, size)
    self.avatar:SetSteamID(sid64, size)
end

function PANEL:Paint(w, h)
    SlashUI:DrawRoundedBox(self.roundness, 0, 0, w, h, self.outcol)

    SlashUI:Mask(function()
		SlashUI:DrawRoundedBox(self.roundness, self.pad, self.pad, w-self.pad*2, h-self.pad*2, color_white)
    end, function()
        self.avatar:PaintManual()
    end)
end
vgui.Register("SlashUI.Avatar", PANEL)
