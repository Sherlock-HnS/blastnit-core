local PANEL = {}

AccessorFunc(PANEL, "m_bgWidth", "BackgroundWidth")
AccessorFunc(PANEL, "m_bgHeight", "BackgroundHeight")

function PANEL:Init()
  self.background = vgui.Create("SlashUI.Frame", self)
  self.background.Paint = function(pnl, w, h)
    local x, y = pnl:LocalToScreen(0, 0)

    SlashUI:DrawBlur(pnl, 4)
    draw.RoundedBox(4, 0, 0, w, h, ColorAlpha(SlashUI.Theme.Background, 150))
  end
	self.background.resizeBtn:Remove()
  self.background.closeBtn.DoClick = function(pnl)
    self:Remove()
  end
end

function PANEL:Paint(w, h)
  surface.SetDrawColor(20, 20, 20, 160)
  surface.DrawRect(0, 0, w, h)
end

function PANEL:PerformLayout(w, h)
  self.background:SetSize(self:GetBackgroundWidth(), self:GetBackgroundHeight())
  self.background:Center()
end

function PANEL:SetTitle(str)
  self.background:SetTitle(str)
end

vgui.Register("SlashUI.Popup", PANEL, "EditablePanel")
