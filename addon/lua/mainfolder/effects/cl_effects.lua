BEAUTIFUL_GLOWMAT = CreateMaterial("glow" .. SysTime(), "VertexLitGeneric", {
	["$basetexture"] = "vgui/white_additive",
	["$bumpmap"] = "vgui/white_additive",

	["$ignorez"] = 0,
	["$model"] = 1,

	["$selfillum"] = 1,
	["$selfillumFresnel"] = 1,
	["$selfillumFresnelMinMaxExp"] = "[0 1 1]",
	["$selfillumtint"] = "[0.05 0.05 0.05]"
})

local glowVM = nil
local glowPlys = {}

hook.Add("PreDrawPlayerHands", "glow", function(hands, vm, ply)
    if ply != LocalPlayer() or !glowVM then return end

    hands:DrawModel()

	render.MaterialOverride(BEAUTIFUL_GLOWMAT)
	render.SuppressEngineLighting(true)
	render.SetColorModulation(glowVM.r/255, glowVM.g/255, glowVM.b/255)
    render.SetBlend(glowVM.a/255)
end)

hook.Add("PostDrawPlayerHands", "glow", function(hands, vm, ply)
    if ply != LocalPlayer() or !glowVM then return end

	render.SetColorModulation(1, 1, 1)
    render.SetBlend(1)
	render.SuppressEngineLighting(false)
	render.MaterialOverride(nil)

    glowVM = nil
end)

hook.Add("PrePlayerDraw", "glow", function(ply, Flags)
    local color = glowPlys[ply]

    if !color then return end
	if bit.band(Flags, STUDIO_RENDER) ~= STUDIO_RENDER then return end

	render.MaterialOverride(BEAUTIFUL_GLOWMAT)
	render.SuppressEngineLighting(true)
	render.SetColorModulation(color.r/255, color.g/255, color.b/255)
    render.SetBlend(color.a/255)
end)

hook.Add("PostPlayerDraw", "glow", function(ply, Flags)
    if !glowPlys[ply] then return end
	if bit.band(Flags, STUDIO_RENDER) ~= STUDIO_RENDER then return end

	render.SetColorModulation(1, 1, 1)
    render.SetBlend(1)
	render.SuppressEngineLighting(false)
	render.MaterialOverride(nil)

    glowPlys[ply] = nil
end)

SlashModules = SlashModules or {}
function SlashModules.GlowModel(ply, color)
    if !IsValid(ply) then return end
    glowPlys[ply] = color

    if ply == LocalPlayer() then
        glowVM = color
    end
end

local visPlys = {}

hook.Add("PostDrawTranslucentRenderables", "EffectsVisual", function(bDepth, bSkybox)
    -- Não redesenha players nas passadas de profundidade e de skybox.
    if bDepth or bSkybox then return end

    local lPly = LocalPlayer()
    local pill = lPly.pk_pill_ent

    local pillTbl = IsValid(pill) and pill.formTable

    if IN_JUMPSCARE then return end
    
	local puppet = IsValid(pill) and (pill.GetPuppet and pill:GetPuppet() or pill.GetPillAimEnt and pill:GetPillAimEnt())
    if IsValid(puppet) and pillTbl and pillTbl.noclip then
        cam.IgnoreZ(true)
        render.SetBlend(.5)
        puppet:DrawModel()
        render.SetBlend(1)
        cam.IgnoreZ(false)

        puppet:DrawModel()
    end
    
    local visionColor = SlashUI.Theme.Green
    local visionColorAlpha = ColorAlpha(visionColor, 255*NIGHTFRAC)

    for k, ply in ipairs(player.GetAll()) do
        if !IsValid(ply) or !ply:IsValidTarget() then visPlys[ply] = nil continue end

        local plyPos = ply:GetPos()

        if (NIGHTVISION or IsValid(pill)) and ply != lPly then
            if ply:HasEffect("Web Trapped") or ply:HasEffect("Hypnotized") then
                cam.IgnoreZ(true)
                SlashModules.GlowModel(ply, visionColor)
                ply:DrawModel()
                cam.IgnoreZ(false)
            elseif ply:HasEffect("Highlighted") then
                cam.IgnoreZ(true)
                SlashModules.GlowModel(ply, ply:GetEffect("Highlighted").color or color_white)
                ply:DrawModel()
                cam.IgnoreZ(false)
            elseif visionColorAlpha.a > 0 then
                -- Com alpha 0 (visão noturna desligada) o redesenho era invisível.
                SlashModules.GlowModel(ply, visionColorAlpha)
                ply:DrawModel()
            end
        end

        for k, v in pairs(ply.Effects or {}) do
            if k == "Plushtrapped" then
                cam.IgnoreZ(true)
                SlashModules.GlowModel(ply, visionColor)
                ply:DrawModel()
                cam.IgnoreZ(false)

                if IsValid(v.plushtrap) then
                    v.plushtrap:SetPos(ply:GetPos())
                end
            end
        end
    end

    local eff = lPly:GetEffect("Screaming")
    if eff then
        local frac = math.Clamp(1 - (eff.hangtime + eff.time - CurTime())/eff.time, 0, 1)

        render.SetColorMaterial()
        render.DrawSphere(lPly:WorldSpaceCenter(), 5000*frac, 30, 30, ColorAlpha(color_black, 200))
        render.DrawSphere(lPly:WorldSpaceCenter(), -5000*frac, 30, 30, ColorAlpha(color_black, 200))

        cam.Start3D2D(lPly:GetPos(), angle_zero, .1)
        cam.IgnoreZ(true)
        RNDX.DrawCircleOutlined(0, 0, 5000*frac*20, color_black, 5000*frac*2)
        cam.IgnoreZ(false)
        cam.End3D2D()
    end

    table.Empty(visPlys)
end)

local blur = Material("pp/blurscreen")
hook.Add("RenderScreenspaceEffects", "StatusEffects", function()
    local ply = LocalPlayer()
    
    local eff = ply:GetEffect("Web Trapped")
    if eff then
        local elapsed = CurTime() - eff.hangtime
        if elapsed > eff.time then return end
    
        local fade = 1
        local fadeStart = eff.time - 1
    
        if elapsed > fadeStart then
            fade = 1 - ((elapsed - fadeStart))
        end
    
       -- DrawMaterialOverlay("effects/tvscreen_noise002a", 0)
    
        DrawMotionBlur(0.75, 0.8 * fade, 0.05)
        DrawSharpen(5*fade, 3)
    
        local blur = blur
        surface.SetDrawColor(color_white)
        surface.SetMaterial(blur)
    
        local w, h = ScrW(), ScrH()
    
        -- 4 passadas com a mesma força máxima (3.3); eram 10 por frame.
        for i = 1, 4 do
            blur:SetFloat("$blur", i * 0.825*fade)
            blur:Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local barW, barH = 500, 100
        local x, y = w/2 - barW/2, h/2 + barH
        local out = 8

        eff.progress = eff.progress and Lerp(FrameTime()*15, eff.progress, IsValid(eff.trapEnt) and eff.trapEnt:Health()/eff.trapEnt:GetMaxHealth() or 0) or 0
        
        RNDX.Draw(8, x, y, barW, barH, color_white, RNDX.BLUR)
        RNDX.Draw(8, x, y, barW, barH, ColorAlpha(color_black, 100))
        RNDX.Draw(8, x + out, y + out, barW - out*2, barH - out*2, ColorAlpha(color_black, 100))
        RNDX.Draw(8, x + out, y + out, (barW - out*2)*eff.progress, barH - out*2, SlashUI:LerpColor(eff.progress, SlashUI.Theme.Red, SlashUI.Theme.Green))
        SlashUI:DrawShadowText(math.Round(eff.progress*100).."%", "Slash75", x + barW/2, y + barH/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 3)

        SlashUI:DrawShadowText("You are trapped", "Slash75", w*.5, 8, SlashUI.Theme.Red, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3)
        SlashUI:DrawShadowText("Spam SPACEBAR to get free", "Slash50", w*.5, 100, ColorAlpha(color_white, 255*math.abs(math.sin(CurTime()*15))), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3)
    end
    
    local eff = ply:GetEffect("Backaxed")
    if eff then
        local elapsed = CurTime() - eff.hangtime
        if elapsed > eff.time then return end
    
        local fade = 1
        local fadeStart = eff.time - 1
    
        if elapsed > fadeStart then
            fade = 1 - ((elapsed - fadeStart))
        end
    
        local w, h = ScrW(), ScrH()

        local barW, barH = 500, 100
        local x, y = w/2 - barW/2, h/2 + barH
        local out = 8

        eff.progress = eff.progress and Lerp(FrameTime()*15, eff.progress, IsValid(eff.axeEnt) and eff.axeEnt:Health()/eff.axeEnt:GetMaxHealth() or 0) or 0
        
        RNDX.Draw(8, x, y, barW, barH, color_white, RNDX.BLUR)
        RNDX.Draw(8, x, y, barW, barH, ColorAlpha(color_black, 100))
        RNDX.Draw(8, x + out, y + out, barW - out*2, barH - out*2, ColorAlpha(color_black, 100))
        RNDX.Draw(8, x + out, y + out, (barW - out*2)*eff.progress, barH - out*2, SlashUI:LerpColor(eff.progress, SlashUI.Theme.Red, SlashUI.Theme.Green))
        SlashUI:DrawShadowText(math.Round(eff.progress*100).."%", "Slash75", x + barW/2, y + barH/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 3)

        SlashUI:DrawShadowText("You are bleeding", "Slash75", w*.5, 8, SlashUI.Theme.Red, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3)
        SlashUI:DrawShadowText("Spam E to take the axe out", "Slash50", w*.5, 100, ColorAlpha(color_white, 255*math.abs(math.sin(CurTime()*15))), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3)
    end
    
    local eff = ply:GetEffect("Confused")
    if eff then
        local elapsed = CurTime() - eff.hangtime
        if elapsed > eff.time then return end
    
        local fade = 1
        local fadeStart = eff.time - 1
    
        if elapsed > fadeStart then
            fade = 1 - ((elapsed - fadeStart))
        end
    
       -- DrawMaterialOverlay("effects/tvscreen_noise002a", 0)
    
        DrawMotionBlur(0.75, 1 * fade, 0.05)
    
        local blur = blur
        surface.SetDrawColor(color_white)
        surface.SetMaterial(blur)
    
        local w, h = ScrW(), ScrH()
    
        for i = 1, 10 do
            blur:SetFloat("$blur", i * 0.5*fade)
            blur:Recompute()
            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(0, 0, w, h)
        end
    end
    
    local eff = ply:GetEffect("Hypnotized")
    if eff and IsValid(eff.machine) then
        local frac = math.Clamp(eff.stacks/100, 0, 1)
        
        local ang = (eff.machine:WorldSpaceCenter() - ply:EyePos()):Angle()
        ang.r = 0

        ply:SetEyeAngles(LerpAngle(FrameTime()*50, ply:EyeAngles(), ang))

        if (eff.lastTick or 0) < CurTime() then
            eff.lastTick = CurTime() + .25
            eff.alpha = math.Rand(0, 1)
        end

        SlashModules.DrawGIF("retro_chica_jumpscare", 0, 0, ScrW(), ScrH(), ColorAlpha(color_white, 150*frac*(eff.alpha or 1)))
    end
    
    local eff = ply:GetEffect("Cartoony")
    if eff then
        local elapsed = CurTime() - eff.hangtime
        if elapsed > eff.time then return end
    
        local fade = 1
        local fadeStart = eff.time - 1
    
        if elapsed > fadeStart then
            fade = 1 - ((elapsed - fadeStart))
        end

        local tab = {
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = 0,
            ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = 1 + 2*fade,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        }
        DrawColorModify(tab)
    
        DrawSobel(1 - .75*fade)
    end
    
    local eff = ply:GetEffect("Laggy")
    if eff then
        local elapsed = CurTime() - eff.hangtime
        if elapsed > eff.time then return end
    
        local fade = 1
        local fadeStart = eff.time - 1
    
        if elapsed > fadeStart then
            fade = 1 - ((elapsed - fadeStart))
        end

        if (eff.lastSound or 0) < CurTime() then
            eff.lastSound = CurTime() + math.Rand(.1, .35)

            local dir = ply:GetForward()*math.Rand(-1, 1) + ply:GetRight()*math.Rand(-1, 1)
            EmitSound("phantom_mangle_footstep2.wav", ply:EyePos() + dir*math.Rand(250, 1000))
        end
        
        DrawMotionBlur(.25, 1*fade, .15)
    end
    
    local eff = ply:GetEffect("Plushtrapped")
    if eff then
        local elapsed = CurTime() - eff.hangtime
        if elapsed > eff.time then return end
        
        local w, h = ScrW(), ScrH()
    
        local fade = 1
        local fadeStart = eff.time - 1
    
        if elapsed > fadeStart then
            fade = 1 - ((elapsed - fadeStart))
        end
    
       -- DrawMaterialOverlay("effects/tvscreen_noise002a", 0)
    
        DrawMotionBlur(.25, 0.8 * fade, 0.01)

        local x, y = w/2, h/2
        local out = 8

        SlashUI:DrawShadowText("Plushtrap is tearing your insides apart", "Slash60", w*.5, 8, SlashUI.Theme.Red, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3)
        SlashUI:DrawShadowText("Someone has to hit you with a crowbar to remove it", "Slash45", w*.5, 75, ColorAlpha(color_white, 255*math.abs(math.sin(CurTime()*10))), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 3)
    end

    if IN_JUMPSCARE and ply.pk_pill_ent then
        local w, h = ScrW(), ScrH()*.15*IN_JUMPSCARE

        RNDX.Draw(0, 0, -1, w, h, color_black)
        RNDX.Draw(0, 0, ScrH() - h + 1, w, h, color_black)
    end
end)

net.Receive("SlashModules.Effects.Sync", function()
    local ply = net.ReadEntity()

    if !IsValid(ply) then return end
    ply.Effects = net.ReadTable() or {}
end)