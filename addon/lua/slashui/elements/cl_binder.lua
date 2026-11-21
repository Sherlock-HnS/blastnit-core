local PANEL = {}

function PANEL:Init()
    self:SetTextColor(color_white)
    self.Paint = nil
    self.ButtonAlpha = 0
    self.OnCursorEntered = function(btn)
        btn:Lerp("ButtonAlpha", 200, .25)
    end
    self.OnCursorExited = function(btn)
        btn:Lerp("ButtonAlpha", 0, .25)
    end
    self.PaintOver = function(pnl, w, h)
        local text = string.upper(pnl:GetText())

        surface.SetFont("Slash15")
        local tx, ty = surface.GetTextSize(text) + 16
        w = math.max(tx, h)
        pnl:SetWide(w)
        
        SlashUI:DrawRoundedBox(4, 0, 0, w, h, SlashUI.Theme.GrayDark)
        SlashUI:DrawRoundedBox(4, 2, 2, w-4, h-4, Color(35, 35, 35))
        SlashUI:DrawShadowText(text, "Slash15", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, 255)
        
        SlashUI:DrawRoundedBox(4, 0, 0, w, h, ColorAlpha(color_black, pnl.ButtonAlpha))
    end
end
vgui.Register("SlashUI.Binder", PANEL, "DBinder")
