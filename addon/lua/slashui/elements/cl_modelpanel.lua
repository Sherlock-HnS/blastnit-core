local PANEL = {}

function PANEL:Init()
    self:SetMouseInputEnabled(false)
    self.LayoutEntity = function() end
end

function PANEL:LookAtMe()
    local entity = self:GetEntity()
	local headpos = entity:GetBonePosition(entity:LookupBone("ValveBiped.Bip01_Spine1"))

	self:SetLookAt(headpos)
	self:SetCamPos(headpos-Vector(-50, 0, 0))
end

function PANEL:SidePosition(fov)
    local entity = self:GetEntity()
    local mn, mx = entity:GetRenderBounds()
    local size = 0

    size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
    size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
    size = math.max(size, math.abs(mn.z) + math.abs(mx.z))
    
    self:SetFOV(fov or 33)
    self:SetCamPos(Vector(size, size + 30, size - 30))
    self:SetLookAt((mn + mx) * 0.5)

    entity:SetAngles(entity:GetAngles())
end

function PANEL:BetterPosition()
    local entity = self:GetEntity()
    local mn, mx = entity:GetRenderBounds()
    local size = 0

    size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
    size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
    size = math.max(size, math.abs(mn.z) + math.abs(mx.z))

    self:SetFOV(45)
    self:SetCamPos(Vector(size, size, size))
    self:SetLookAt((mn + mx) * 0.5)
    
    entity:SetPos(Vector(0, 0, 0))
end
vgui.Register("SlashUI.ModelPanel", PANEL, "DModelPanel")
