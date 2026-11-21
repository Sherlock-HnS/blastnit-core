local PANEL = {}

SlashUI:CreateFont("SlashUI.Query.Text", 18)
SlashUI:CreateFont("SlashUI.Query.Button", 18)

AccessorFunc(PANEL, "text", "Text")

function PANEL:Init()
  self.onAccept = function() end
  self.onDecline = function() end

  self.background.Paint = function(pnl, w, h)
      local x, y = pnl:LocalToScreen(0, 0)
  
      SlashUI:DrawBlur(pnl, 4)
      draw.RoundedBox(4, 0, 0, w, h, ColorAlpha(SlashUI.Theme.Background, 150))
      
      SlashUI:DrawShadowText(self:GetText(), "Slash20", w/2, 55, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, 255)
  end

  self.background.accept = self.background:Add("DButton")
  self.background.accept:SetText("Accept")
  self.background.accept:SetFont("SlashUI.Query.Button")
  self.background.accept:SetTextColor(Color(21, 21, 21))
  self.background.accept.Paint = function(pnl, w, h)
    draw.RoundedBox(6, 0, 0, w, h, self.acceptBtnColor or SlashUI.Theme.Green)
  end
  self.background.accept.DoClick = function(pnl)
    self:onAccept(pnl)
    self:Remove()
  end
end

function PANEL:PerformLayout(w, h)
  surface.SetFont("Slash20")
  local tw = surface.GetTextSize(self:GetText())
  self:SetBackgroundWidth(tw + 32)

  self.BaseClass.PerformLayout(self, w, h)

  self.background.accept:SizeToContentsX(32)
  self.background.accept:SizeToContentsY(16)

  local y = self.background:GetTall() - self.background.accept:GetTall() - 16

  self.background.accept:SetPos(self.background:GetWide() / 2 - self.background.accept:GetWide() / 2, y)
end

function PANEL:SetAccept(text, func)
  self.background.accept:SetText(text)
  self.onAccept = func
end

vgui.Register("SlashUI.QuerySingleButton", PANEL, "SlashUI.Popup")

function SlashUI:SimpleQuerySingle(title, text, yesText, yesFunc)
  local queryMenu = vgui.Create("SlashUI.QuerySingleButton")
  queryMenu:SetSize(ScrW(), ScrH())
  queryMenu:SetBackgroundHeight(140)

  queryMenu:SetTitle(title or "Title")
  queryMenu:SetText(text or "Text")

  queryMenu:SetAccept(yesText or "Yes", yesFunc or (function() end))

  queryMenu:MakePopup()

  return queryMenu
end
