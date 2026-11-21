RunConsoleCommand("pk_pill_cl_hidehud", 1)
CreateClientConVar("blast_pill_overhead", "0", true)
CreateClientConVar("blast_pill_cinematic", "0", true)

local myCDs = {}
net.Receive("SlashModules.PillBind", function(len, ply)
    myCDs = net.ReadTable()
end)

NIGHTVISION = false
NIGHTFRAC = 0
hook.Add("PlayerButtonDown", "PillBinds", function(ply, button)
	if !IsFirstTimePredicted() or ply != LocalPlayer() then return end
    local pill = ply.pk_pill_ent

    if !IsValid(pill) then return end
    if vgui.CursorVisible() then return end

    local pillForm = pill:GetPillForm()
    local pillTbl = pill.formTable

    if !pillTbl.abilities then return end

    if button == KEY_F then
        myCDs[1] = myCDs[1] or {
            time = 0,
            cooldown = 1,
        }

        local cd = myCDs[1]
        local time = (cd.time or 0) + (cd.cooldown or 0) - CurTime()
        
        if time <= 0 then
            myCDs[1].time = CurTime() - .5
            NIGHTVISION = !NIGHTVISION
        end
    end

    for k, v in ipairs(pillTbl.abilities) do
        if !v.key or v.key != button then continue end

        net.Start("SlashModules.PillBind")
        net.WriteInt(k, 4)
        net.SendToServer()

        break
    end
end)

local color_red = Color(255, 0, 0, 150)

local hpFrac = 1
local cachedMats = {}
hook.Add("HUDPaint", "PillHUD", function()
    if IN_JUMPSCARE then return end

    local ply = LocalPlayer()
    local pill = ply.pk_pill_ent

    if !IsValid(pill) then
        if NIGHTVISION then
            NIGHTVISION = false
        end

        return
    end

    local pillForm = pill:GetPillForm()
    local pillTbl = pill.formTable

    local w, h = ScrW(), ScrH()
    local scale = h/1080

    if !pillTbl.abilities then return end
    do
        local abilitySize = 150*scale
        local totalSize = (abilitySize + 8)*#pillTbl.abilities
        local x, y = w - abilitySize - 24*scale, h - abilitySize - 24*scale

        local font = pillTbl.font or "Slash"
    
        for i = #pillTbl.abilities, 1, -1 do
            local v = pillTbl.abilities[i]
            local mat = v.mat

            local cd = myCDs[i] or {}
            local time = (cd.time or 0) + (cd.cooldown or 0) - CurTime()
            local timeFrac = time/(cd.cooldown or v.cooldown)
            
            if timeFrac > 0 then
                RNDX.DrawMaterial(0, x, y, abilitySize, abilitySize, color_black, mat)
    
                SlashUI:Mask(function()
                    RNDX.Draw(0, x, y + abilitySize*timeFrac, abilitySize, abilitySize, color_white)
                end, function()
                    RNDX.DrawMaterial(0, x, y, abilitySize, abilitySize, color_red, mat)
                end)
                
                draw.SimpleTextOutlined(math.ceil(time), font.."65", x + abilitySize/2, y + abilitySize/2, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 3*scale, color_red)
            elseif cd.disabled then
                RNDX.DrawMaterial(0, x, y, abilitySize, abilitySize, color_black, mat)
                RNDX.DrawMaterial(0, x, y, abilitySize, abilitySize, color_red, mat)
            else
                RNDX.DrawMaterial(0, x, y, abilitySize, abilitySize, color_white, mat)
            end
            
            local key = v.key

            if isstring(key) or v.keyText then
                draw.SimpleTextOutlined(v.keyText or key, font.."45", x + abilitySize/2, y - 16*scale, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2*scale, (timeFrac > 0 or cd.disabled) and color_red or color_white)
            else
                draw.SimpleTextOutlined(string.upper(input.GetKeyName(v.key)), font.."60", x, y, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2*scale, (timeFrac > 0 or cd.disabled) and color_red or color_white)
            end

            x = x - abilitySize
        end
    end
end)

local headOffset = Vector(0, 0, 10)
local maxDist = 800^2
hook.Add("PostPlayerDraw", "OverheadHUD", function(ply)
    if IN_JUMPSCARE or !cvars.Bool("blast_pill_overhead", 0) then return end
    if !ply:IsValidTarget() or ply == LocalPlayer() then return end
    if ply:Crouching() then return end
    if ply:GetPos():DistToSqr(LocalPlayer():GetPos()) > maxDist then return end

    local tr = util.TraceLine({
        start = LocalPlayer():EyePos(),
        endpos = ply:WorldSpaceCenter(),
        mask = MASK_SHOT,
        filter = {LocalPlayer()},
    })

    if !tr.Hit or tr.Entity != ply then return end

    local boneID = ply:LookupBone("ValveBiped.Bip01_Head1")
    local pos

    if boneID then
        pos = ply:GetBonePosition(boneID)
    else
        pos = ply:GetPos() + Vector(0, 0, ply:OBBMaxs().z)
    end
    
    local ang = LocalPlayer():EyeAngles()
    cam.Start3D2D(pos + headOffset, Angle(0, ang.y - 90, -ang.p + 90), .1)
    draw.SimpleTextOutlined(ply:Name(), "Slash75", 0, -50, team.GetColor(ply:Team()), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 5, color_black)
    draw.SimpleTextOutlined(ply:Health().."%", "Slash50", 0, 0, team.GetColor(ply:Team()), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 3, color_black)
    cam.End3D2D()
end)

hook.Add("HUDDrawTargetID", "HidePill", function()
	return false
end)

local LightingModeChanged = false
hook.Add("PreRender", "fullbright", function()
    if !NIGHTVISION then return end

	render.SetLightingMode(1)
	LightingModeChanged = true
end)

hook.Add("PostRender", "fullbright", function()
    if !LightingModeChanged then return end
    
    render.SetLightingMode(0)
    LightingModeChanged = false
end)
hook.Add("PreDrawHUD", "fullbright", function()
    if !LightingModeChanged then return end
    
    render.SetLightingMode(0)
    LightingModeChanged = false
end)

hook.Add("RenderScreenspaceEffects", "NightVision", function()
    local ply = LocalPlayer()

    if NIGHTVISION then
        NIGHTFRAC = Lerp(FrameTime()*10, NIGHTFRAC, 1)

        if NIGHTFRAC >= .99 then
            NIGHTFRAC = 1
        end
    else
        NIGHTFRAC = Lerp(FrameTime()*10, NIGHTFRAC, 0)

        if NIGHTFRAC <= .01 then
            NIGHTFRAC = 0
        end
    end

    if NIGHTFRAC <= 0 then return end
    
    DrawColorModify({
        ["$pp_colour_addr"] = 0,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = -.25*NIGHTFRAC,
        ["$pp_colour_contrast"] = 1,
        ["$pp_colour_colour"] = .01 + .99*(1 - NIGHTFRAC),
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 1*NIGHTFRAC,
        ["$pp_colour_mulb"] = 0,
    })

    DrawSharpen(3*NIGHTFRAC, 1)
end)

net.Receive("PILLSJUMPCAM", function()
    local ply = LocalPlayer()
    local ent = net.ReadEntity()
    local state = net.ReadBool()
    local hookname = "IM_GAYYYY_GAY" .. tostring(ply)

    if not state then
        hook.Remove("CalcView", hookname)
        return
    end

    local transitionStart = RealTime()

    hook.Add("CalcView", hookname, function(ply, pos, angles, fov)
        if not IsValid(ply) or not ply:Alive() or not IsValid(ent) then
            hook.Remove("CalcView", hookname)
            return
        end	
        local transitionProgress = math.Clamp((RealTime() - transitionStart) / 0.25, 0, 1)
        local cam = ent:GetAttachment(ent:LookupAttachment("camera"))

        return {
            origin = LerpVector(transitionProgress, pos, cam.Pos),
            angles = LerpAngle(transitionProgress, angles, cam.Ang),
            fov = 80,
            drawviewer = false
        }
    end)
end)

local function restoreMomo()
    hook.Add("CalcView", "momo_calcview", function(ply, pos, ang, fov, nearZ, farZ)
        local ent = pk_pills.getMappedEnt(LocalPlayer())
    
        if IsValid(ent) and ply:GetViewEntity() == ply then
            local startpos
    
            if ent.formTable.type == "phys" then
                startpos = ent:LocalToWorld(ent.formTable.camera and ent.formTable.camera.offset or Vector(0, 0, 0))
            else
                startpos = pos
            end
    
            if pk_pills.convars.cl_thirdperson:GetBool() then
                local dist

                local puppet = ent:GetPuppet()
                if ent.formTable.camera.bone and IsValid(puppet) then
                    local boneID = puppet:LookupBone(ent.formTable.camera.bone)
                    if boneID then
                        local matrix = puppet:GetBoneMatrix(boneID)
                        if matrix then
                            startpos = matrix:GetTranslation() + ent.formTable.camera.offset
                        end
                    end
                end
    
                if ent.formTable.type == "phys" and ent.formTable.camera and ent.formTable.camera.distFromSize then
                    dist = ent:BoundingRadius() * 5
                else
                    dist = ent.formTable.camera and ent.formTable.camera.dist or 100
                end
    
                local underslung = ent.formTable.camera and ent.formTable.camera.underslung
                local offset = LocalToWorld(Vector(-dist, -(ent.formTable.camera.right or 0), underslung and -dist / 5 or dist / 5), Angle(0, 0, 0), Vector(0, 0, 0), ang)
    
                local tr = util.TraceHull({
                    start = startpos,
                    endpos = startpos + offset,
                    filter = ent.camTraceFilter,
                    mins = Vector(-5, -5, -5),
                    maxs = Vector(5, 5, 5),
                    mask = MASK_VISIBLE
                })
    
                local view = {}
                view.origin = ent.formTable.noclip and (startpos + offset) or tr.HitPos
                view.angles = ang
                view.fov = fov
                view.drawviewer = true
                --[[else
                local view = {}
                view.origin = startpos
                view.angles = ang
                view.fov = fov
                return view]]
    
                return view
            end
        end
    end)
end
net.Receive("SlashModules.PillJumpscare", function()
    local ply = LocalPlayer()
    local start = net.ReadBool()
    local isPill = ply.pk_pill_ent
    
    if isPill then
        if !cvars.Bool("blast_pill_cinematic", 0) then return end
        ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0, 255), 1, 0)
    end
    
    local hookName = "SlashModules.PillJumpscare"
    if start then
        local jsInfo = net.ReadTable()
        local pill = net.ReadEntity()
    
        local transitionStart = RealTime()
        
        IN_JUMPSCARE = 0

        hook.Remove("CalcView", "momo_calcview")
        hook.Add("CalcView", hookName, function(ply, pos, angles, fov)
            if !IsValid(ply) or !ply:Alive() or !IsValid(pill) then
                restoreMomo()

                hook.Remove("CalcView", hookName)
                IN_JUMPSCARE = nil

                return
            end

            IN_JUMPSCARE = math.Clamp((RealTime() - transitionStart)/0.25, 0, 1)

            if isPill then
                local transitionProgress = math.Clamp((RealTime() - transitionStart)/jsInfo.time, 0, 1)

                local ang = pill:GetAngles()
                local orbAng = Angle(ang.p, ang.y + (-45 + 90*transitionProgress), 0)
                
                local min, max = pill:GetModelBounds()
                
                local modPos = jsInfo.pos or {}
                local basePos = pill:GetPos() + pill:GetForward()*(modPos.forward or 50) + pill:GetUp() * (modPos.up or -25) + pill:GetRight() * (modPos.right or 0)

                local pos = basePos + Vector(0, 0, max.z)*(2 + .5*transitionProgress) + orbAng:Forward()*(500 - 350*transitionProgress)
                local tr = util.TraceLine({
                    start = ply:EyePos(),
                    endpos = pos,
                    mask = MASK_SOLID_BRUSHONLY,
                })

                if tr.Hit then
                    pos = tr.HitPos + tr.HitNormal:Angle():Forward()*1
                end
        
                return {
                    origin = pos,
                    angles = (pill:GetPos() - pos):Angle() + ply:GetViewPunchAngles(),
                    fov = 80,
                    drawviewer = false
                }
            else
                local cam = pill:GetAttachment(pill:LookupAttachment("camera"))
        
                return {
                    origin = LerpVector(IN_JUMPSCARE, pos, cam.Pos),
                    angles = LerpAngle(IN_JUMPSCARE, angles, cam.Ang),
                    fov = 80,
                    drawviewer = false
                }
            end
        end)
    else
        restoreMomo()
        
        hook.Remove("CalcView", hookName)
        IN_JUMPSCARE = nil
    end
end)

hook.Add("InitPostEntity", "OverridePills", function()
    restoreMomo()
end)

concommand.Add("slash_getbones", function()
    local ply = LocalPlayer()
    local pill = ply.pk_pill_ent

    local ent
    if IsValid(pill) then
        ent = pill:GetPuppet()
    else
        ent = ply
    end

    for i = 0, ent:GetBoneCount() - 1 do
        local name = ent:GetBoneName(i)
        if !name or name == "__INVALIDBONE__" then continue end

        print(name)
    end
end)

concommand.Add("slash_getattachments", function()
    local ply = LocalPlayer()
    local pill = ply.pk_pill_ent

    local ent
    if IsValid(pill) then
        ent = pill:GetPuppet()
    else
        ent = ply
    end

    PrintTable(ent:GetAttachments())
end)