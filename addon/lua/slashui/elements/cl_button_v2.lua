local PANEL = {}

AccessorFunc(PANEL, "_cStartCol", "StartColor")
AccessorFunc(PANEL, "_cEndcol", "EndColor")
AccessorFunc(PANEL, "_iRoundness", "Roundness")
AccessorFunc(PANEL, "_iOffsetX", "XOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "_iOffsetY", "YOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "_sIcon", "Icon")
AccessorFunc(PANEL, "_cHoverColor", "HoverColor")
AccessorFunc(PANEL, "_cSolidColor", "SolidColor")
AccessorFunc(PANEL, "_cTextColor", "TextColor")
AccessorFunc(PANEL, "_iIconSize", "IconSize", FORCE_NUMBER)


SlashUI:CreateFont("SlashUI.GradientButton.Default", 24)

function PANEL:SetSolidColor(col)
	self.SolidColorStatic = col

	self._cSolidColor = col
end

function PANEL:Init()
	self:SetText("")
	self:SetSolidColor(Color(158, 53, 210))
	self:SetStartColor(Color(158, 53, 210))
	self:SetEndColor(Color(109, 77, 213))
	self:SetFont("SlashUI.GradientButton.Default")
	self:SetRoundness(self:GetTall())
	self:SetContentAlignment(5)
	self:SetXOffset(0)
	self:SetYOffset(0)
	self:SetGradient(false)
	self:SetTextColor(color_white)

	self.ButtonAlpha = 255

	self.SetText = function(self, text)
		self._sText = text
	end
	self.GetText = function(self)
		return self._sText
	end
end

function PANEL:SizeToContentsX(padding)
	if padding == nil then padding = 0
	end
	surface.SetFont(self:GetFont())
	local tw = surface.GetTextSize(self:GetText())

	self:SetWide(tw + padding)
end

function PANEL:IsGradient()
	return self._bUniform
end

function PANEL:SetGradient(bBool)
	self._bUniform = bBool
end

function PANEL:RoundFromTallness()
	self:SetRoundness(self:GetTall())
end

function PANEL:SetContentAlignment(iInteger)
	self._iHorizontalAlignment = (iInteger - 1) % 3
	self._iVerticalAlignment = (iInteger == 5 or iInteger == 6 or iInteger == 4) and 1 or (iInteger == 1 or iInteger == 2 or iInteger == 3) and 4 or 3

	self._bTopAligned = self._iVerticalAlignment == 3
	self._bBottomAligned = self._iVerticalAlignment == 4

	self._bLeftAligned = self._iHorizontalAlignment == 0
	self._bRightAligned = self._iHorizontalAlignment == 2
end

local ShadowColor = Color(0, 0, 0, 50)
function PANEL:Paint(w, h)
	local aX, aY = self:LocalToScreen()
	local cStartColor, cEndColor, cColor = ColorAlpha(self:GetStartColor(), self.ButtonAlpha), ColorAlpha(self:GetEndColor(), self.ButtonAlpha), ColorAlpha(self:GetSolidColor(), self.ButtonAlpha)

	if self:GetRoundness() > 0 then
		SlashUI:Mask(function()
			SlashUI:DrawRoundedBox(self:GetRoundness(), 0, 0, w, h, color_white)
		end, function()
			if self:IsGradient() then
				draw.SimpleLinearGradient(aX, aY, w, h, cStartColor, cEndColor, true)
			else
				surface.SetDrawColor(cColor)
				surface.DrawRect(0, 0, w, h)
			end
		end)
	else
		if self:IsGradient() then
			draw.SimpleLinearGradient(aX, aY, w, h, cStartColor, cEndColor, true)
		else
			surface.SetDrawColor(cColor)
			surface.DrawRect(0, 0, w, h)
		end
	end

	local iconID = self:GetIcon()
	local icon = iconID and SlashUI:GetIcon(iconID) or false
	local size = 0
	if icon then
		size = self:GetIconSize() or h * 0.8
		if (icon != "Loading") then
			surface.SetMaterial(icon)

			surface.SetDrawColor(ShadowColor)
			surface.DrawTexturedRect(5 + 1, h / 2 - Size / 2 + 2, Size, Size)

			surface.SetDrawColor(iconColor or Color(235, 235, 235))
			surface.DrawTexturedRect(5, h / 2 - Size / 2 + 1, Size, Size)
		else
			SlashUI:DrawLoadingCircle(h / 2, h / 2, h - 24, SlashUI.Theme.Blue)
		end
	end
	local XOffset, YOffset = self:GetXOffset() + (self._bLeftAligned and Size or 0), self:GetYOffset()

	draw.SimpleText(self:GetText(), self:GetFont(), self._bLeftAligned and XOffset or self._bRightAligned and w + XOffset or w / 2 + XOffset, self._bTopAligned and YOffset or self._bBottomAligned and (h + YOffset) or h / 2 + YOffset, self:GetTextColor(), self._iHorizontalAlignment, self._iVerticalAlignment)
end

function PANEL:OnCursorEntered()
	if (self:GetHoverColor() and !self:IsGradient()) then
		self:LerpColor("_cSolidColor", self:GetHoverColor())
	else
		self:Lerp("ButtonAlpha", 127.5)
	end
end

function PANEL:OnCursorExited()
	if (self:GetHoverColor() and !self:IsGradient()) then
		self:LerpColor("_cSolidColor", self.SolidColorStatic)
	else
		self:Lerp("ButtonAlpha", 255)
	end
end
vgui.Register("SlashUI.ButtonV2", PANEL, "DButton")

local PANEL = {}

AccessorFunc(PANEL, "_cStartCol", "StartColor")
AccessorFunc(PANEL, "_cEndcol", "EndColor")
AccessorFunc(PANEL, "_iOffsetX", "XOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "_iOffsetY", "YOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "_sIcon", "Icon")
AccessorFunc(PANEL, "_cHoverColor", "HoverColor")
AccessorFunc(PANEL, "_cSolidColor", "SolidColor")
AccessorFunc(PANEL, "_cTextColor", "TextColor")
AccessorFunc(PANEL, "_iIconSize", "IconSize", FORCE_NUMBER)
AccessorFunc(PANEL, "notifAmount", "Notif", FORCE_NUMBER)
AccessorFunc(PANEL, "iconSize", "IconSize", FORCE_NUMBER)


SlashUI:CreateFont("SlashUI.GradientButton.Default", 24)

function PANEL:SetSolidColor(col)
	self.LerpedSolidColor = SlashUI:ColorLerp(.25, col, color_black)
	self._cSolidColor = col
end

function PANEL:Init()
	self:SetText("")
	self:SetSolidColor(Color(45, 45, 45))
	self:SetFont("SlashUI.GradientButton.Default")
	self:SetContentAlignment(5)
	self:SetXOffset(0)
	self:SetYOffset(0)
	self:SetGradient(false)
	self:SetTextColor(color_white)

	self.HoverFrac = 0

	self.SetText = function(self, text)
		self._sText = text
	end
	self.GetText = function(self)
		return self._sText
	end
end

function PANEL:PerformLayout(w, h)
end

function PANEL:SizeToContentsX(padding)
	if padding == nil then padding = 0
	end
	surface.SetFont(self:GetFont())
	local tw = surface.GetTextSize(self:GetText())

	self:SetWide(tw + padding)
end

function PANEL:IsGradient()
	return self._bUniform
end

function PANEL:SetGradient(bBool)
	self._bUniform = bBool
end

function PANEL:SetContentAlignment(iInteger)
	self._iHorizontalAlignment = (iInteger - 1) % 3
	self._iVerticalAlignment = (iInteger == 5 or iInteger == 6 or iInteger == 4) and 1 or (iInteger == 1 or iInteger == 2 or iInteger == 3) and 4 or 3

	self._bTopAligned = self._iVerticalAlignment == 3
	self._bBottomAligned = self._iVerticalAlignment == 4

	self._bLeftAligned = self._iHorizontalAlignment == 0
	self._bRightAligned = self._iHorizontalAlignment == 2
end

function PANEL:SetNotif(amount)
	amount = amount or 0

	if amount <= 0 or amount > 9 then
		amount = "!"
	end

	self.notifAmount = amount
end

local ShadowColor = Color(0, 0, 0, 255)
local WhiteColor = Color(235, 235, 235)
function PANEL:Paint(w, h)
	local hasText = self:GetText()
	local hover = self.HoverFrac
	local cColor = self:GetSolidColor()

	local gX, gY = self:LocalToScreen(0, 0)

	if self:IsEnabled() then
		SlashUI:DrawBlur(self, 4)
	
		SlashUI:MaskInverse(function()
			SlashUI:DrawRoundedBox(4, 2, 2, w-4, h-4, color_white)
		end, function()
			SlashUI:DrawRoundedBox(4, 0, 0, w, h, cColor)
		end)
	
		SlashUI:Mask(function()
			SlashUI:DrawRoundedBox(4, 0, 0, w, h, color_white)
		end, function()
			draw.SimpleLinearGradient(gX, gY, w, h, ColorAlpha(cColor, 0), ColorAlpha(cColor, 125*self:GetAlpha()), false)
		end)
	end

	local iconID = self:GetIcon()
	local icon = iconID and SlashUI:GetIcon(iconID) or false
	local size = 0
	
	if icon then
		local rot = self.HoverFrac > 0 and 10*math.sin(CurTime()*5) or 0
		local posMod = hasText and .35 or .5
		size = self:GetIconSize() or h * 0.5
		size = size + size*.15*self.HoverFrac

		if (icon != "Loading") then
			surface.SetMaterial(icon)

			surface.SetDrawColor(ShadowColor)
			surface.DrawTexturedRectRotated(w/2 + 2, h*posMod + 2, size, size, rot)

			surface.SetDrawColor(iconColor or WhiteColor)
			surface.DrawTexturedRectRotated(w/2, h*posMod, size, size, rot)
		else
			SlashUI:DrawLoadingCircle(h/2, h/2, h - 24, SlashUI.Theme.Blue)
		end
	end

	if hasText then
		SlashUI:DrawShadowText(self:GetText(), self:GetFont(), w/2, h/2, self:GetTextColor(), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, 255)
	end

	if self:IsEnabled() then
		local lW, lH = w*hover, h*hover
		SlashUI:DrawRoundedBox(2, w/2-lW/2, h/2-lH/2, lW, lH, ColorAlpha(color_white, 15*hover))
	end

	if IsValid(self.notifPanel) then self.notifPanel:PaintManual(true) end
end

function PANEL:OnCursorEntered()
	if !self:IsEnabled() then return end
	LocalPlayer():EmitSound("UI/buttonrollover.wav", 75, 150, .35)
	self:Lerp("HoverFrac", 1)
end

function PANEL:DoClick()
	if !self:IsEnabled() then return end
	LocalPlayer():EmitSound("UI/buttonclick.wav", 75, 150, .35)

	if self.OnClick then self:OnClick() end
end

function PANEL:DoRightClick()
	if !self:IsEnabled() then return end
	LocalPlayer():EmitSound("UI/buttonclick.wav", 75, 150, .35)

	if self.OnRightClick then self:OnRightClick() end
end

function PANEL:OnCursorExited()
	self:Lerp("HoverFrac", 0)
end
vgui.Register("SlashUI.Button", PANEL, "DButton")

local PANEL = {}

AccessorFunc(PANEL, "_cStartCol", "StartColor")
AccessorFunc(PANEL, "_cEndcol", "EndColor")
AccessorFunc(PANEL, "_iOffsetX", "XOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "_iOffsetY", "YOffset", FORCE_NUMBER)
AccessorFunc(PANEL, "_sIcon", "Icon")
AccessorFunc(PANEL, "_cHoverColor", "HoverColor")
AccessorFunc(PANEL, "_cSolidColor", "SolidColor")
AccessorFunc(PANEL, "_cTextColor", "TextColor")
AccessorFunc(PANEL, "_iIconSize", "IconSize", FORCE_NUMBER)
AccessorFunc(PANEL, "notifAmount", "Notif", FORCE_NUMBER)
AccessorFunc(PANEL, "iconSize", "IconSize", FORCE_NUMBER)


SlashUI:CreateFont("SlashUI.GradientButton.Default", 24)

function PANEL:SetSolidColor(col)
	self.LerpedSolidColor = SlashUI:ColorLerp(.25, col, color_black)
	self._cSolidColor = col
end

function PANEL:Init()
	self:SetText("")
	self:SetSolidColor(Color(45, 45, 45))
	self:SetFont("SlashUI.GradientButton.Default")
	self:SetContentAlignment(5)
	self:SetXOffset(0)
	self:SetYOffset(0)
	self:SetGradient(false)
	self:SetTextColor(color_white)

	self.HoverFrac = 0

	self.SetText = function(self, text)
		self._sText = text
	end
	self.GetText = function(self)
		return self._sText
	end
end

function PANEL:PerformLayout(w, h)
    local dock = self:GetDock()

    if dock == LEFT or dock == RIGHT then
        self:SetWide(h)
    elseif dock == TOP or dock == BOTTOM then
        self:SetTall(w)
    end
end

function PANEL:SizeToContentsX(padding)
	if padding == nil then padding = 0
	end
	surface.SetFont(self:GetFont())
	local tw = surface.GetTextSize(self:GetText())

	self:SetWide(tw + padding)
end

function PANEL:IsGradient()
	return self._bUniform
end

function PANEL:SetGradient(bBool)
	self._bUniform = bBool
end

function PANEL:SetContentAlignment(iInteger)
	self._iHorizontalAlignment = (iInteger - 1) % 3
	self._iVerticalAlignment = (iInteger == 5 or iInteger == 6 or iInteger == 4) and 1 or (iInteger == 1 or iInteger == 2 or iInteger == 3) and 4 or 3

	self._bTopAligned = self._iVerticalAlignment == 3
	self._bBottomAligned = self._iVerticalAlignment == 4

	self._bLeftAligned = self._iHorizontalAlignment == 0
	self._bRightAligned = self._iHorizontalAlignment == 2
end

function PANEL:SetNotif(amount)
	amount = amount or 0

	if amount <= 0 or amount > 9 then
		amount = "!"
	end

	self.notifAmount = amount
end

local ShadowColor = Color(0, 0, 0, 255)
local WhiteColor = Color(235, 235, 235)
function PANEL:Paint(w, h)
	local hasText = self:GetText()
	local hover = self.HoverFrac
	local cColor = self:GetSolidColor()

	local oSize = math.max(w*.01, h*.01, 4)
	SlashUI:DrawRoundedBox(2, 0, 0, w, h, self.LerpedSolidColor)
	SlashUI:DrawRoundedBox(2, oSize, oSize, w-oSize*2, h-oSize*2, cColor)

	local iconID = self:GetIcon()
	local icon = iconID and SlashUI:GetIcon(iconID) or false
	local size = 0
	
	if icon then
		local rot = self.HoverFrac > 0 and 10*math.sin(CurTime()*5) or 0
		local posMod = hasText and .35 or .5
		size = self:GetIconSize() or h * 0.5
		size = size + size*.15*self.HoverFrac

		if (icon != "Loading") then
			surface.SetMaterial(icon)

			surface.SetDrawColor(ShadowColor)
			surface.DrawTexturedRectRotated(w/2 + 2, h*posMod + 2, size, size, rot)

			surface.SetDrawColor(iconColor or WhiteColor)
			surface.DrawTexturedRectRotated(w/2, h*posMod, size, size, rot)
		else
			SlashUI:DrawLoadingCircle(h/2, h/2, h - 24, SlashUI.Theme.Blue)
		end
	end

	if hasText then
		SlashUI:DrawShadowText(self:GetText(), self:GetFont(), w/2, h-8, self:GetTextColor(), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, 255)
	end

	if self:GetNotif() then
		local bSize = math.Round(h*.2)

		SlashUI:DrawRoundedBox(2, w-bSize, 0, bSize, bSize, SlashUI.Theme.Red)
		SlashUI:DrawShadowText(self:GetNotif(), "Slash"..bSize, w-bSize/2, bSize/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0, 0)
	end

	local s = h*hover
	SlashUI:DrawRoundedBox(2, w/2-s/2, h/2-s/2, s, s, ColorAlpha(color_white, 15*hover))

	if IsValid(self.notifPanel) then self.notifPanel:PaintManual(true) end
end

function PANEL:OnCursorEntered()
	LocalPlayer():EmitSound("UI/buttonrollover.wav", 75, 150, .35)
	self:Lerp("HoverFrac", 1)
end

function PANEL:DoClick()
	LocalPlayer():EmitSound("UI/buttonclick.wav", 75, 150, .35)

	if self.OnClick then self:OnClick() end
end

function PANEL:DoRightClick()
	LocalPlayer():EmitSound("UI/buttonclick.wav", 75, 150, .35)

	if self.OnRightClick then self:OnRightClick() end
end

function PANEL:OnCursorExited()
	self:Lerp("HoverFrac", 0)
end
vgui.Register("SlashUI.SimpleButton", PANEL, "DButton")