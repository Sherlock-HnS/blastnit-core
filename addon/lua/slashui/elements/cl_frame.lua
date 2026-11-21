SlashUI:CreateFont("SlashUI.Frame.Title", 28)

local PANEL = {}

function PANEL:Init()
	self.inResize = false

    local color2 = ColorAlpha(SlashUI.Theme.Background, 250)

	self.top = vgui.Create("Panel", self)
	self.top:Dock(TOP)
	self.top.Paint = function(pnl, w, h)
		draw.RoundedBoxEx(4, 0, 0, w, h, color2, true, true, false, false)
		SlashUI:DrawShadowText(self.Title or "", "Slash18", 8, h/2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 0, 0)
	end

	self.closeBtn = vgui.Create("DButton", self.top)
	self.closeBtn:Dock(RIGHT)
	self.closeBtn:SetText("")
	self.closeBtn.HoverFrac = .25
	self.closeBtn.DoClick = function(pnl)
		LocalPlayer():EmitSound("UI/buttonclick.wav", 75, 150, .35)
		self:Remove()
	end
	self.closeBtn.Paint = function(pnl, w, h)
		draw.RoundedBoxEx(4, 0, 0, w, h, ColorAlpha(SlashUI.Theme.Red, 255*pnl.HoverFrac), false, true, false, false)

		SlashUI:DrawShadowText("✕", "Slash15", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0, 0)
	end
	self.closeBtn.OnCursorEntered = function(pnl)
		LocalPlayer():EmitSound("UI/buttonrollover.wav", 75, 150, .35)
		pnl:Lerp("HoverFrac", 1)
	end
	self.closeBtn.OnCursorExited = function(pnl)
		pnl:Lerp("HoverFrac", .25)
	end

	self.resizeBtn = vgui.Create("DButton", self.top)
	self.resizeBtn:Dock(RIGHT)
	self.resizeBtn:SetText("")
	self.resizeBtn.HoverFrac = .25
	self.resizeBtn.DoClick = function(pnl)
		LocalPlayer():EmitSound("UI/buttonclick.wav", 75, 150, .35)
		if self.inResize then return end

		self.inResize = true

		if self:GetWide() == ScrW() and self:GetTall() == ScrH() then
			self:LerpSize(self.OriginalSize[1], self.OriginalSize[2], .5, function()
				self.inResize = false
			end)
		else
			self.OriginalSize = {self:GetWide(), self:GetTall()}
			self:LerpSize(ScrW(), ScrH(), .5, function()
				self.inResize = false
			end)
		end
	end
	self.resizeBtn.Paint = function(pnl, w, h)
		draw.RoundedBox(0, 0, 0, w, h, ColorAlpha(SlashUI.Theme.Green, 255*pnl.HoverFrac))

		SlashUI:DrawShadowText("❏", "Slash20", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0, 0)
	end
	self.resizeBtn.OnCursorEntered = function(pnl)
		LocalPlayer():EmitSound("UI/buttonrollover.wav", 75, 150, .35)
		pnl:Lerp("HoverFrac", 1)
	end
	self.resizeBtn.OnCursorExited = function(pnl)
		pnl:Lerp("HoverFrac", .25)
	end
end

function PANEL:SetTitle(str)
	self.Title = str
end

function PANEL:PerformLayout(w, h)
	self.top:SetTall(25)

	if IsValid(self.branding) then
		self.branding:SetWide(self.top:GetTall())
	end

	if IsValid(self.closeBtn) then
		self.closeBtn:SetWide(self.top:GetTall()*2)
	end

	if IsValid(self.resizeBtn) then
		self.resizeBtn:SetWide(self.top:GetTall()*2)
	end

	if IsValid(self.pinBtn) then
		self.pinBtn:SetWide(self.top:GetTall()*2)
	end

	if self.inResize then
		self:Center()
	end
end

function PANEL:Paint(w, h)
	local x, y = self:LocalToScreen()

	SlashUI:DrawBlur(self, 4)
	draw.RoundedBox(4, 0, 0, w, h, ColorAlpha(SlashUI.Theme.Background, 250))
end

function PANEL:ShowCloseButton(show)
	self.closeBtn:SetVisible(show)
end

vgui.Register("SlashUI.Frame", PANEL, "EditablePanel")
